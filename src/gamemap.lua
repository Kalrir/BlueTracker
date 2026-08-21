--[[
* gamemap.lua - read the live FFXI map for any zone straight from the running
* client (no bundled artwork). This is the same approach Boussole/atom0s use:
*   1. signature-scan FFXiMain.dll for the global map table,
*   2. read the per-zone entry (Scale, OffsetX, OffsetY, DAT index),
*   3. resolve the DAT path via Ashita's ResourceManager and decode the map
*      texture (SE's A8R8G8B8 / DXT1-5 image format) into a D3D texture.
*
* Because the entry carries the real Scale/OffsetX/OffsetY, the map image and
* the plotted markers line up automatically for whatever zone we ask about --
* not just the one the player is standing in.
*
* EVERYTHING here is best-effort and guarded: if the client memory, d3d device,
* ffi, or DAT read isn't available (e.g. running outside the game, or a future
* client that moved the signature), every entry point returns nil and the
* caller falls back to the coordinate grid. Nothing bundled, nothing fatal.
*
* Memory signatures & DAT format are community reverse-engineering credited to
* atom0s & Thorny (see the Boussole project). Zone->table-index values are
* facts about the client's global map table, listed per supported zone below.
--]]

local gamemap = {}

-- Zone/floor -> index into the client's global map table. Loaded from
-- data/zone_map_index.lua (facts about the client, covers all zones). The small
-- built-in table is a fallback if that file is missing.
local ZONE_INDEX = { [100] = { [0] = 0 } }   -- West Ronfaure
do
    local ok, full = pcall(require, 'data/zone_map_index')
    if ok and type(full) == 'table' then ZONE_INDEX = full end
end

-- Community-published signature for the map table pointer (FFXiMain.dll).
local MAP_TABLE_SIG = '8A0D????????5333C05684C95774??8A5424188B7424148B7C2410B9'
local ENTRY_SIZE    = 0x0E

local ok_ffi, ffi = pcall(require, 'ffi')
local mem = (type(ashita) == 'table') and ashita.memory or nil

-- One-time ffi type setup (guarded; harmless if it runs without d3d present).
local cdef_ok = false
local function ensure_cdef()
    if cdef_ok or not ok_ffi then return cdef_ok end
    cdef_ok = pcall(function()
        ffi.cdef[[
            typedef struct {
                uint32_t structLength;
                int32_t  width;
                int32_t  height;
                uint16_t planes;
                uint16_t bitCount;
                uint32_t compression;
                uint32_t imageSize;
                uint32_t horizontalResolution;
                uint32_t verticalResolution;
                uint32_t usedColors;
                uint32_t importantColors;
                uint32_t type;
            } bt_ImageHeader;
            typedef struct FILE FILE;
            int fopen_s(FILE** pFile, const char* filename, const char* mode);
            int fclose(FILE* stream);
            int fseek(FILE* stream, long offset, int origin);
            long ftell(FILE* stream);
            size_t fread(void* buffer, size_t size, size_t count, FILE* stream);
        ]]
    end)
    return cdef_ok
end

local table_ptr = 0
local scanned   = false

local function find_table()
    if scanned then return table_ptr ~= 0 end
    scanned = true
    if not mem or not mem.find then return false end
    local ok = pcall(function()
        local addr = mem.find('FFXiMain.dll', 0, MAP_TABLE_SIG, 0, 0)
        if not addr or addr == 0 then return end
        local ptr = mem.read_uint32(addr + 0x1C)
        if ptr and ptr ~= 0 then table_ptr = ptr end
    end)
    return ok and table_ptr ~= 0
end

local function s8(v)  return (v >= 0x80)   and (v - 0x100)   or v end
local function s16(v) return (v >= 0x8000) and (v - 0x10000) or v end

local function read_entry(index)
    if table_ptr == 0 then return nil end
    local base = table_ptr + (index * ENTRY_SIZE)
    local e
    local ok = pcall(function()
        e = {
            ZoneId       = mem.read_uint16(base + 0x00),
            FloorId      = mem.read_uint8(base + 0x02),
            Flags        = mem.read_uint8(base + 0x04),
            Scale        = s8(mem.read_uint8(base + 0x05)),
            MapDatOffset = mem.read_uint16(base + 0x08),
            OffsetX      = s16(mem.read_uint16(base + 0x0A)),
            OffsetY      = s16(mem.read_uint16(base + 0x0C)),
        }
    end)
    return ok and e or nil
end

local function dat_index(entry)
    local low = bit.band(entry.Flags, 0x0F)
    if low == 0 then return entry.MapDatOffset + 5312 end
    if low == 1 then return entry.MapDatOffset + 53295 end
    if low == 2 then return entry.MapDatOffset + 54295 end
    return 5522
end

-- Read the DAT bytes for a map entry via Ashita's ResourceManager path.
local function read_dat(entry)
    if not ensure_cdef() then return nil end
    local data
    local ok = pcall(function()
        local rm = AshitaCore and AshitaCore:GetResourceManager()
        if not rm then return end
        local path = rm:GetFilePath(dat_index(entry))
        if not path or path == '' then return end
        local fp = ffi.new('FILE*[1]')
        if ffi.C.fopen_s(fp, path, 'rb') ~= 0 or fp[0] == nil then return end
        local file = fp[0]
        ffi.C.fseek(file, 0, 2)            -- SEEK_END
        local size = ffi.C.ftell(file)
        if size <= 0 then ffi.C.fclose(file); return end
        ffi.C.fseek(file, 0, 0)            -- SEEK_SET
        local buf = ffi.new('uint8_t[?]', size)
        local n = ffi.C.fread(buf, 1, size, file)
        ffi.C.fclose(file)
        if n == size then data = ffi.string(buf, size) end
    end)
    return ok and data or nil
end

-- Decode the SE map image (A8R8G8B8 bitmap or DXT1-5) into a managed texture.
-- Returns gcTexture, width, height  (or nil on any failure).
local function decode_texture(datData)
    local tex, w, h
    local ok = pcall(function()
        local d3d8 = require('d3d8')
        local dev  = d3d8.get_device()
        if not dev then return end
        local C = ffi.C
        local HDR = 0x41
        local hdr = ffi.cast('bt_ImageHeader*',
            ffi.cast('uint8_t*', ffi.cast('const char*', datData)) + HDR)[0]
        local width, height, itype = hdr.width, hdr.height, hdr.type
        if width <= 0 or height <= 0 then return end

        local BITMAP = 0x0000000A
        local DXT1, DXT2, DXT3, DXT4, DXT5 =
            0x44585431, 0x44585432, 0x44585433, 0x44585434, 0x44585435

        if itype == BITMAP then
            local res, dxt = dev:CreateTexture(width, height, 1, 0, C.D3DFMT_A8R8G8B8, C.D3DPOOL_MANAGED)
            if res ~= C.S_OK or not dxt then return end
            local lr, rect = dxt:LockRect(0, nil, 0)
            if lr ~= C.S_OK or not rect or rect.pBits == nil then
                if dxt then dxt:Release() end; return
            end
            local dest  = ffi.cast('uint8_t*', rect.pBits)
            local pitch = rect.Pitch
            local off   = HDR + ffi.sizeof('bt_ImageHeader')
            local bpp   = hdr.bitCount
            local function u8(o) return string.byte(datData, o + 1) end
            local palette
            if bpp == 8 then
                palette = {}
                for i = 0, 255 do
                    local b, g, r, a = u8(off), u8(off+1), u8(off+2), u8(off+3)
                    palette[i] = { r = r, g = g, b = b, a = (a > 0) and 255 or 0 }
                    off = off + 4
                end
            end
            for idx = 0, width * height - 1 do
                local r, g, b, a
                if bpp == 8 then
                    local c = palette[u8(off)]; off = off + 1
                    r, g, b, a = c.r, c.g, c.b, c.a
                elseif bpp == 24 then
                    b, g, r, a = u8(off), u8(off+1), u8(off+2), 255; off = off + 3
                elseif bpp == 32 then
                    b, g, r = u8(off), u8(off+1), u8(off+2)
                    a = (u8(off+3) > 0) and 255 or 0; off = off + 4
                else
                    r, g, b, a = 255, 0, 255, 255; off = off + 1
                end
                local x = idx % width
                local y = math.floor(idx / width)
                local so = (height - 1 - y) * pitch + x * 4  -- bitmaps stored bottom-up
                dest[so + 0] = b; dest[so + 1] = g; dest[so + 2] = r; dest[so + 3] = a
            end
            dxt:UnlockRect(0)
            tex = d3d8.gc_safe_release(ffi.cast('IDirect3DBaseTexture8*', dxt))
            w, h = width, height
        else
            local fmt
            if     itype == DXT1 then fmt = C.D3DFMT_DXT1
            elseif itype == DXT2 then fmt = C.D3DFMT_DXT2
            elseif itype == DXT3 then fmt = C.D3DFMT_DXT3
            elseif itype == DXT4 then fmt = C.D3DFMT_DXT4
            elseif itype == DXT5 then fmt = C.D3DFMT_DXT5
            else return end
            local res, dxt = dev:CreateTexture(width, height, 1, 0, fmt, C.D3DPOOL_MANAGED)
            if res ~= C.S_OK or not dxt then return end
            local lr, rect = dxt:LockRect(0, nil, 0)
            if lr ~= C.S_OK or not rect or rect.pBits == nil then
                if dxt then dxt:Release() end; return
            end
            local blocks = math.max(1, width / 4) * math.max(1, height / 4)
            local csize  = (itype == DXT1) and (blocks * 8) or (blocks * 16)
            local off    = HDR + ffi.sizeof('bt_ImageHeader') + 8  -- 8 unknown bytes
            local src    = ffi.cast('const uint8_t*', ffi.cast('const char*', datData)) + off
            ffi.copy(ffi.cast('uint8_t*', rect.pBits), src, csize)
            dxt:UnlockRect(0)
            tex = d3d8.gc_safe_release(ffi.cast('IDirect3DBaseTexture8*', dxt))
            w, h = width, height
        end
    end)
    if ok and tex then return tex, w, h end
    return nil
end

-- Boussole-exact world -> 512-reference-space transform for a live entry.
-- Pass horizontal world coords: wx = pos_x, wy = pos_z (client Y == server Z).
function gamemap.world_to_ref(entry, wx, wy)
    local f = math.abs(entry.Scale) / 5.0        -- (1/(2560/scale)) * 512
    local mapX = wx * f
    local mapY = -(wy * f)
    return mapX - entry.OffsetX, mapY - entry.OffsetY
end

-- World rectangle a map floor actually covers (inverse of world_to_ref over the
-- 0..512 reference square). Used to pick the right floor for a mob position.
local function entry_world_bounds(entry)
    local f = math.abs(entry.Scale) / 5.0
    if f == 0 then return nil end
    local x0 = (0   + entry.OffsetX) / f
    local x1 = (512 + entry.OffsetX) / f
    -- texY = -(z*f) - OffsetY ; texY in [0,512]  ->  z in [-(512+OffsetY)/f, -OffsetY/f]
    local z0 = -(512 + entry.OffsetY) / f
    local z1 = -(0   + entry.OffsetY) / f
    return { minX = math.min(x0, x1), maxX = math.max(x0, x1),
             minZ = math.min(z0, z1), maxZ = math.max(z0, z1) }
end

-- Load + decode a specific (zone, floor, table index) into a cached texture.
local cache = {}
local function load_floor(zoneid, floorid, index)
    local key = zoneid .. '_' .. floorid
    if cache[key] ~= nil then return cache[key] or nil end
    local result = nil
    local ok = pcall(function()
        if not ok_ffi then return end
        if not find_table() then return end
        local entry = read_entry(index)
        if not entry or math.abs(entry.Scale or 0) == 0 then return end
        local datData = read_dat(entry)
        if not datData then return end
        local tex, w, h = decode_texture(datData)
        if not tex then return end
        result = {
            id     = tonumber(ffi.cast('uint32_t', tex)),
            tex    = tex,   -- keep a ref so the gc handle isn't collected
            entry  = entry,
            width  = w,
            height = h,
        }
    end)
    cache[key] = (ok and result) or false
    return cache[key] or nil
end

-- Public: get the live map for an exact (zoneid, floorid).
function gamemap.get(zoneid, floorid)
    floorid = floorid or 0
    local zi = ZONE_INDEX[zoneid]
    local index = zi and zi[floorid]
    if not index then return nil end
    return load_floor(zoneid, floorid, index)
end

-- Public: get the best live map for a world position. Reads each of the zone's
-- floors, computes its world coverage, and returns the floor that contains
-- (wx, wz) -- tie-broken by smallest area, falling back to the nearest, then to
-- any loadable floor. Fixes zones with no floor 0 (e.g. Carpenter's Landing)
-- and multi-floor zones where the mob isn't on floor 0.
function gamemap.get_best(zoneid, wx, wz)
    local zi = ZONE_INDEX[zoneid]
    if not zi then return nil end
    local ok, res = pcall(function()
        if not ok_ffi or not find_table() then return nil end

        -- Gather candidate floors with their world bounds.
        local cands = {}
        for floorid, index in pairs(zi) do
            local entry = read_entry(index)
            if entry and math.abs(entry.Scale or 0) ~= 0 then
                local b = entry_world_bounds(entry)
                if b then
                    cands[#cands + 1] = { floorid = floorid, index = index, b = b }
                end
            end
        end
        if #cands == 0 then return nil end

        -- Prefer a floor whose rectangle contains the point (smallest area wins).
        local best, bestArea
        for _, c in ipairs(cands) do
            local b = c.b
            if wx >= b.minX and wx <= b.maxX and wz >= b.minZ and wz <= b.maxZ then
                local area = (b.maxX - b.minX) * (b.maxZ - b.minZ)
                if not bestArea or area < bestArea then best, bestArea = c, area end
            end
        end

        -- Else the floor whose centre is nearest the point.
        if not best then
            local bestD
            for _, c in ipairs(cands) do
                local b = c.b
                local mx = (b.minX + b.maxX) * 0.5
                local mz = (b.minZ + b.maxZ) * 0.5
                local d = (mx - wx) * (mx - wx) + (mz - wz) * (mz - wz)
                if not bestD or d < bestD then best, bestD = c, d end
            end
        end

        if not best then return nil end
        return load_floor(zoneid, best.floorid, best.index)
    end)
    return (ok and res) or nil
end

function gamemap.available()
    return ok_ffi and mem ~= nil
end

return gamemap
