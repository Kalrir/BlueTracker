#!/usr/bin/env python3
"""
Build data/mob_positions.lua for BluTracker from LandSandBoat's
sql/mob_spawn_points.sql.

Output shape (Lua):

  return {
    ["West Ronfaure"] = {
      zoneid = 100,
      bounds = { min_x=.., max_x=.., min_z=.., max_z=.. },  -- padded spawn extent
      mobs = {
        ["Wild Rabbit"] = { {x=..,z=..}, ... },
        ...
      },
    },
    ...
  }

Positions are FFXI world coordinates. +x = east, +z = south. The tracker maps
(x -> horizontal, z -> vertical, north up) using `bounds`.

NOTE: this only ships MOB POSITIONS (facts derived from the open-source LSB
database). It does NOT touch or embed any retail client map artwork.

Usage:
  python3 build_mob_positions.py <path/to/mob_spawn_points.sql> [zoneid ...]
Defaults to West Ronfaure (100) if no zone ids are given.
"""
import re
import sys
import os

# zoneid -> display name. Loaded from data/bluemage_zones.lua at runtime so it
# always matches the zone strings used in data/bluemage_learnfrom.lua. Falls
# back to this small built-in table if that file can't be read.
ZONE_NAMES = {
    100: "West Ronfaure",
}


def load_zone_names():
    """Parse data/bluemage_zones.lua ( [id] = "Name", ) into {id: name}."""
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "..", "data", "bluemage_zones.lua")
    names = {}
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                m = re.match(r'\s*\[(\d+)\]\s*=\s*"((?:[^"\\]|\\.)*)"', line)
                if m:
                    names[int(m.group(1))] = m.group(2).replace('\\"', '"')
    except OSError:
        return dict(ZONE_NAMES)
    names.pop(0, None)  # drop the "unknown" placeholder
    return names or dict(ZONE_NAMES)

MOBID_BASE = 0x1000000
ROW_RE = re.compile(
    r"INSERT INTO `mob_spawn_points` VALUES \("
    r"(\d+),"          # mobid
    r"(\d+),"          # spawnslotid
    r"'([^']*)',"      # mobname (underscored)
    r"'([^']*)',"      # polutils_name (spaced)
    r"(\d+),"          # groupid
    r"(\d+),"          # minLevel
    r"(\d+),"          # maxLevel
    r"([-0-9.]+),"     # pos_x
    r"([-0-9.]+),"     # pos_y
    r"([-0-9.]+),"     # pos_z
)

PLACEHOLDER_EPS = 1.001   # (1,1,1) / (0,0,0) unplaced spawns
DEDUP_EPS = 1.5           # merge spawn points closer than this (world units)
MAX_POINTS = 60           # cap per mob to keep the file small
BOUNDS_PAD = 0.06         # pad the spawn extent by 6% on each side


def safe_float(tok):
    """Parse a coordinate token; return None for the malformed/degenerate
    values a few LSB rows carry (e.g. '-464.527-320', e-less sci-notation that
    denotes ~1e-318 garbage positions on unplaced NMs)."""
    try:
        return float(tok)
    except ValueError:
        m = re.match(r'^(-?\d+(?:\.\d+)?)-(\d+)$', tok)  # mantissa '-' exp
        if m:
            try:
                v = float(m.group(1) + 'e-' + m.group(2))
                return v  # ~0; is_placed() will reject it
            except ValueError:
                return None
        return None


def zone_of(mobid: int) -> int:
    return (mobid - MOBID_BASE) >> 12


def display_name(polutils: str, mobname: str) -> str:
    n = (polutils or "").strip()
    if not n:
        n = (mobname or "").replace("_", " ").strip()
    return n


def is_placed(x, y, z) -> bool:
    if abs(x) <= PLACEHOLDER_EPS and abs(y) <= PLACEHOLDER_EPS and abs(z) <= PLACEHOLDER_EPS:
        return False
    if x == 0.0 and y == 0.0 and z == 0.0:
        return False
    return True


def dedup(points):
    out = []
    for p in points:
        keep = True
        for q in out:
            if abs(p[0] - q[0]) < DEDUP_EPS and abs(p[1] - q[1]) < DEDUP_EPS:
                keep = False
                break
        if keep:
            out.append(p)
        if len(out) >= MAX_POINTS:
            break
    return out


def lua_num(v: float) -> str:
    return ("%.2f" % v).rstrip("0").rstrip(".")


def fit_calibration(minx, maxx, minz, maxz, ref=512, margin=0.08):
    """Fit a Boussole-style *direct* calibration (world -> reference-pixel).

      texX = x * scalingX + offsetX
      texY = z * scalingY + offsetY     (north up: +z south -> larger texY)

    Uniform scale (preserves aspect), content centred inside `margin`. This
    makes the grid view accurate immediately. For overlaying a REAL client map
    image, replace scalingX/offsetX with the client's values (see README) or a
    boussole_custom_maps entry -- the transform is identical.
    """
    span_x = max(maxx - minx, 1e-6)
    span_z = max(maxz - minz, 1e-6)
    usable = ref * (1.0 - 2.0 * margin)
    s = usable / max(span_x, span_z)
    used_w = span_x * s
    used_h = span_z * s
    offx = (ref - used_w) * 0.5 - minx * s
    offy = (ref - used_h) * 0.5 - minz * s
    return s, offx, s, offy, ref


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    sql_path = sys.argv[1]

    global ZONE_NAMES
    ZONE_NAMES = load_zone_names()

    # Explicit zone ids on the command line, else every zone we have a name for.
    zone_ids = [int(z) for z in sys.argv[2:]] or sorted(ZONE_NAMES.keys())

    # zoneid -> { mobname -> [ (x,z), ... ] }, plus bounds accumulation
    zones = {z: {"mobs": {}, "minx": 1e9, "maxx": -1e9, "minz": 1e9, "maxz": -1e9}
             for z in zone_ids}

    with open(sql_path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = ROW_RE.match(line)
            if not m:
                continue
            mobid = int(m.group(1))
            z = zone_of(mobid)
            if z not in zones:
                continue
            name = display_name(m.group(4), m.group(3))
            x, y, zz = safe_float(m.group(8)), safe_float(m.group(9)), safe_float(m.group(10))
            if x is None or y is None or zz is None:
                continue
            if not is_placed(x, y, zz):
                continue
            zc = zones[z]
            zc["mobs"].setdefault(name, []).append((x, zz))
            zc["minx"] = min(zc["minx"], x); zc["maxx"] = max(zc["maxx"], x)
            zc["minz"] = min(zc["minz"], zz); zc["maxz"] = max(zc["maxz"], zz)

    # Emit Lua
    out = []
    out.append("-- Mob spawn positions for BluTracker's mini-map overlay.")
    out.append("-- Generated by tools/build_mob_positions.py from LandSandBoat's")
    out.append("-- sql/mob_spawn_points.sql. World coords: +x=east, +z=south.")
    out.append("-- Contains MOB POSITIONS ONLY (no client map artwork).")
    out.append("return {")
    for z in zone_ids:
        zc = zones[z]
        name = ZONE_NAMES.get(z, "Zone %d" % z)
        mobs = zc["mobs"]
        if not mobs:
            continue
        dx = (zc["maxx"] - zc["minx"]) or 1.0
        dz = (zc["maxz"] - zc["minz"]) or 1.0
        minx = zc["minx"] - dx * BOUNDS_PAD
        maxx = zc["maxx"] + dx * BOUNDS_PAD
        minz = zc["minz"] - dz * BOUNDS_PAD
        maxz = zc["maxz"] + dz * BOUNDS_PAD
        out.append('    ["%s"] = {' % name)
        out.append('        zoneid = %d,' % z)
        out.append('        bounds = { min_x = %s, max_x = %s, min_z = %s, max_z = %s },'
                   % (lua_num(minx), lua_num(maxx), lua_num(minz), lua_num(maxz)))
        # Fitted calibration (from the *raw* spawn extent, not the padded bounds).
        sx, ox, sy, oy, ref = fit_calibration(zc["minx"], zc["maxx"], zc["minz"], zc["maxz"])
        out.append('        -- Fitted world->map calibration (Boussole "direct" format).')
        out.append('        -- Replace with your client values / a boussole_custom_maps entry')
        out.append('        -- to align a real map image (see README). image = optional PNG in maps/.')
        out.append('        calibration = { scalingX = %s, offsetX = %s, scalingY = %s, offsetY = %s, referenceSize = %d, image = "%d_0.png" },'
                   % (lua_num(sx), lua_num(ox), lua_num(sy), lua_num(oy), ref, z))
        out.append('        mobs = {')
        for mob in sorted(mobs.keys()):
            pts = dedup(mobs[mob])
            inner = ", ".join("{x=%s,z=%s}" % (lua_num(px), lua_num(pz)) for px, pz in pts)
            # Lua string key: use ["..."] to be safe with spaces/punctuation.
            out.append('            ["%s"] = { %s },' % (mob.replace('"', '\\"'), inner))
        out.append('        },')
        out.append('    },')
        n_pts = sum(len(dedup(v)) for v in mobs.values())
        sys.stderr.write("[%s] zone %d: %d mobs, %d points, bounds x[%s,%s] z[%s,%s]\n"
                         % (name, z, len(mobs), n_pts,
                            lua_num(minx), lua_num(maxx), lua_num(minz), lua_num(maxz)))
    out.append("}")
    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
