# BluTracker — Code Map

Blue Magic tracker addon for **Ashita v4 / HorizonXI** (75-era, LSB server).
Install path: `<Ashita>/addons/blutracker/` — load with `/addon load blutracker`.
Current version: **1.44** (Presets tab: Save / Load / Apply, search, No Traits).

> Keep this file up to date after every change and re-upload it to the
> "FFXI BlueTracker" project.

---

## Files

| File | Role |
|---|---|
| `blutracker.lua` | Addon host. Owns settings (`default_config`), the `vt` view-table, the title-bar gear helper, and all Ashita events. Drives `tracker.lua`. |
| `tracker.lua` | The whole UI + logic module (`M`). ~5200 lines. Main window tabs: Spells, Zones, Presets (was Traits), Counter, Settings; plus the separate mini Tracker window. |
| `BlueLearn.lua` | "Action Learned!" splash (gdifonts). Optional — pcall-required. |
| `gdifonts/` | Thorny's gdifonts library (native DLL + Lua wrappers) used by BlueLearn. |
| `src/gamemap.lua` | Reads the live client zone map (sig-scan + DAT decode) for the map views. Optional/guarded. |
| `sounds/blu_action_learned.wav` | Splash sound. |
| `tools/build_mob_positions.py` | Generates `data/mob_positions.lua` from the LSB DB. |

### data/

| File | Contents |
|---|---|
| `bluemage_spells.lua` | Spell DB (`DB.SPELLS`, `DB.BY_KEY`, `DB.keyify`, ROLES/FAMILIES/TRAITS lists). key = lowercase name, non-alnum stripped. Level, kind, trait, family and MP **verified against the in-game spell cards** (`cards/` folder, 106 cards) in 1.43. |
| `bluemage_spellids.lua` (`SID`) | spell key -> FFXI spell id (512+). `id - 0x200` is the byte used in packets 0x102/0x044. |
| `bluemage_setpoints.lua` (`BP`) | spell key -> set-point cost, from the HorizonXI wiki spell list "B" column. Used for spells not on the trait sheet (sheet cost wins). All 14 no-trait spells' values match the in-game cards. |
| `cards/` | User's in-game spell tooltip screenshots (one per spell, png/webp) — the source of truth for level / MP / set points / trait / trait points / family. Not loaded by the addon. |
| `bluemage_traits.lua` (`TRD.TRAITS`) | Era+ trait sheet (set cost / trait points / level verified against the in-game cards in 1.43; Store TP, Counter, Resist Gravity, Resist Slow added): `{ name, need, max, rule, note, spells = { {lvl, name, setCost, traitPts}, ... } }`. Only remaining `note`: "Frost Breath adds a tier on its own." (the Geist Wall / Blood Saber "bugged high" note was removed in 1.36 at the user's request — they are still bugged). |
| `bluemage_learnfrom.lua` (`LF.DATA`) | key -> list of `{ mob, level, zone, isNM }`. |
| `bluemage_mrl.lua` / `bluemage_reqskill.lua` | Min level / skill to learn each spell. |
| `bluemage_zones.lua` / `bluemage_zonecaps.lua` | Zone id -> name; level-capped zones (filters learn-from rows). |
| `bluemage_mobmoves.lua` | Extra monster-move names for the "seen" counter. |
| `mob_positions.lua` | Spawn points per zone/mob (big, generated). |
| `zone_map_index.lua` | Zone -> client map table index. |

---

## blutracker.lua (host)

- `default_config` — every persisted key (per character via Ashita `settings`).
  Spells-tab filter keys: `bluemage_hide_learned`, **`bluemage_only_my_skill`**, `bluemage_only_my_level`.
  Traits-tab keys: `bluemage_trait_manual`, `_points`, `_last_level`,
  `_only_learned`, `_only_level`, `_can_combo`, `_design` (spell id -> true; sheet id or DB key),
  **`_sets`** (saved set-ups), **`_loaded`** (name of last saved/loaded set-up).
- Events:
  - `load` → `BlueMage.init(host)`
  - `command` → `BlueMage.command`
  - `text_in` → `BlueMage.text_in`
  - `packet_in`: `0x00A` reload settings + re-init; `0x00B` save; `0x028` → seen counter;
    **`0x044` → `BlueMage.packet_in` (current set Blue Magic spells, for Apply)**
  - `d3d_present` → `BlueMage.render`

## tracker.lua (module `M`) — approximate line numbers

| Lines | Section |
|---|---|
| 1–130 | Requires (DB, LF, SID, MRL, REQSK, ZONES, caps filter, POS, gamemap, BlueLearn, MOBMOVES), `SORTED`, zone maps |
| 380–400 | Main-chunk state: `cfg`, `vt`, `settings`, `learned`, `tracked`, `seen`, `BLU_JOB_ID = 16` |
| 500–915 | `UIK` UI kit (panels `section_begin/end`, `rows_begin/row`, `check`, `button`, `slider`, `note`, `block_begin`, `frame_begin`, headings, tab bar styling) |
| 923–960 | Window theme push/pop |
| 964–1250 | Helpers: `GetBluLevel`, `GetBlueSkill`, zone/pos, floor caches, `SpellsInZone`, `CountLearned`, `SyncFromSpellbook` |
| 1280–1530 | Spells-tab rows/filters/progress bar. `PassesFilter(r, needle, bluLvl, skill)` — Hide learned, **<= Skill level** (`REQSK[key] <= skill`, only when BLU is main job and skill is readable), <= my level, role/trait/family combos, search. `LearnStatus` = green/yellow/dim colouring |
| 1530–2210 | Map drawing (mini-map hover, zone map) |
| 2210–2270 | `SeenBy` per-monster counts |
| 2272 | `M.init(host)` |
| 2360–2990 | "Seen" counter: chat parsing, action packet (0x028) parsing, `M.packet_in` (also dispatches 0x044 → `M._trt_packet`) |
| ~2880 | `MinLvl` / `MaxLvl` (level-string parsing), `TrackerEntry` — one spell in the mini tracker; its mob list is sorted **lowest level first** (min level, then max level, then mob name, then area) |
| ~2995 | `RenderTracker()` — mini tracker window (Specific / Zone mode) |
| 3093 | `RenderZoneTab()` |
| 3334–4500 | **Presets tab** closure (`RenderTraitsTab`; tab label "Presets", formerly "Traits") — see below |
| 4345 | `RenderCounterTab` closure |
| 4526 | `RenderConfigTab()` (Settings tab) |
| ~4700 | `M.render()` — per-frame: splash, seen flush, **`M._trt_tick()`**, spellbook sync, tracker window, main window + tabs, then **`M._trt_windows()`** |
| 4981+ | `M.command`, `M.seen_command`, `M.debug_floors`, `M.text_in`, `M.splash_preview`, `M.unload`, `M.reset_settings` |

> The main chunk is near Lua's 200-local limit — new features go inside a
> closure (like the Traits/Counter tabs) or hang off `M`.

### Ashita ImGui binding gotchas

- `imgui.BeginChild(id, size)` — the 3rd arg is **child flags (number)**, not a
  `border` boolean. Passing `true` raises a Lua error mid-frame and leaves the
  ImGui stack unbalanced ("Missing End()/EndChild()/PopStyleColor()" popup).
- Any code between Begin*/End* or Push*/Pop* that could error should be wrapped
  (see `Guard` in the Traits tab) so the closing call always runs.

### Presets tab (inside `RenderTraitsTab` closure; internal names still say "trait")

- `TRAITS` — trait sheet resolved to DB records; each spell `s = { lvl, name, cost, pts, rec, id, idx }`
  (`s.id` = sheet key, `s.idx` = spell id − 0x200).
- `ALL_BY_ID` / `EXTRAS` — every spell the designer can hold: sheet entries + every other DB
  spell (no job trait, `extra = true`, `pts = 0`, cost from `BP`). `IdOfIdx(idx)` (in the
  Saved set-ups block) maps an in-game spell index to a designer id and adds unknown spells
  on the fly (name from the client resource manager).
- `TierOf`, `TraitSpellBlock/Hidden`, `TraitCombos` (subset enumeration, cached),
  `Design()` (= `cfg.bluemage_trait_design`), `UseCombo`, `DesignTotals` (trait spells + `EXTRAS`).
- Spell details (Spells-tab info) for every Presets spell: `SpellInfo(s)` → type
  ("Magical - Enfeeble" / "Physical - Damage", `ROLE_COLORS`), element (`ELEM_COLORS`), effect
  (`rec.prop`), MP. Shown **only in the hover card** `SpellTooltip(s, block, isL, trait_line)`
  (Trait Sets, No Traits and the Spells Set list) — rows stay one line (user preference: less
  clutter; a second info line was tried in 1.29 and removed in 1.30).
- Left pane (a group: search row, then scrolling child
  `##bm_traits_ref`, whose height is the pane height minus the measured controls height):
  - `RenderSpellSearch(w)` — InputText (`trt_search`, no label) + X clear button, no tooltips;
    lined up with the **Trait Sets card** below it: `RenderTraitReference` records the card's
    screen x / width each frame in `trt_card`, and the search row uses it (one-frame lag). `SearchNeedle()`,
    `NameHit(name, needle)` (case-insensitive substring).
  - `RenderTypeFilters()` — Magic / Physical / Ranged checkboxes on the **"Spell type" row at the
    bottom of the Blue Points & Filters panel**, right after the Element dropdown
    (`trt_kind`; none ticked = all types; ticked = any of; Physical excludes Ranged; Ranged =
    `elem == 'Ranged'`).
  - `RenderElementFilter(w)` — "Element: X" combo, **first item on the "Spell type" row**
    (width from `ElementComboWidth()` = longest label + arrow) (`TRT_ELEMENTS`: None +
    Fire/Ice/Wind/Earth/Thunder/Water/Light/Dark; None = no element filter). Session-only state. `KindHit(s)` applies them; `FiltersActive(needle)`
    = search or any of these in use.
  - Expand state while filtering: matching traits start **collapsed**; clicking a header opens
    it (`filter_open[name]`). `FilterSig(needle)` — when the search/element/type combination
    changes, `filter_open` is cleared (all collapsed again). With no filter active, the user's
    own `trait_open` state is used (also collapsed by default).
  - `RenderTraitReference` — "Trait Sets": a search hit on the trait name keeps all its spells,
    otherwise only matching spells; element/type filters always apply; traits are collapsed
    by default.
    `RenderTraitBody` draws one trait's body: optional orange `t.note`, spell table, the
    clickable cheapest-per-tier lines (no heading; text is only `Tier N  cost X` — no spell
    names; click = `UseCombo` with that cheapest set). The "All valid / tier I combinations"
    list was removed in 1.41 (`TraitCombos` still computes `minimal` — it feeds `used` for the
    Can Combo filter). The
    trait sheet's `rule` text is no longer shown (still in the data file).
  - `RenderNoTraits(myLvl, pw)` — "No Traits (N)": every `EXTRAS` spell (no job trait), table
    Set | Lv | Spell | Cost with a checkbox into the designer; honours the level/learned filters
    and the search / element / type filters; hover card shows the spell details.
- `BlueJobLevel`, `MaxBluePoints` (10 +5 per 10 levels, +5 Assimilation at 90+ spells).
- **Saved set-ups + Apply** (`-- ---------- Saved set-ups + Apply to the game ----------`):
  - Storage: `SavedSets()` → `cfg.bluemage_trait_sets` = array of `{ name, ids = {spell ids} }`
    (older saves may still carry an ignored `reserved` field).
    `SaveSetup(name)`, `LoadSetup(entry)` (replaces designer), `DeleteSetup(i)`, `MatchesSaved`.
  - Applier state `AP` (`current` = slot 1..20 → spell idx from 0x044, `running`, `status`).
  - `StartApply()` — needs BLU main or sub; skips spells above level / not learned.
  - `M._trt_packet(e)` — parses 0x044 (byte 0x04 = job 16; bytes 0x08..0x1B = 20 slots).
  - `M._trt_tick()` — one change per server reply, `SET_SPEED` 0.65 s after each 0x044,
    `REPLY_WAIT` 2.5 s timeout (2 timeouts → stop). Order: refresh → remove **every** set
    spell not in the set-up → add missing set-up spells into first empty slot. The game ends
    up exactly matching Your Set-up (BLUSets-style).
  - `SendBlu(add_idx, slot, slot_val)` — outgoing 0x102 (0xA4 bytes, header `02 53`):
    0x04 = spell idx to add (0 = remove), 0x08 = 16, 0x0C+slot−1 = non-zero target slot
    (when removing: idx of the spell in that slot). All-zero = server just replies 0x044.
  - `ActiveInGame()` — "Active in game." / "Not applied yet." indicator.
  - **Load Current Set** (button in the **Spells Set** section, right of Clear set-up; shown
    alone under the "Tick spells..." note when the set-up is empty):
    `LoadCurrentSetClicked()` sends the all-zero 0x102 refresh, sets `AP.show_until`; the 0x044
    reply (`M._trt_packet`) calls `LoadCurrentSet(cur)` → replaces the designer with **all** set
    spells (`IdOfIdx`), clears
    `_loaded`. Silent on success (no status message); errors still show in the status line.
    Timeout in `M._trt_tick` falls back to the last known `AP.current`.
  - Save / Load windows: small **non-modal** floating windows (`FloatWindow(key, title, body)`,
    state in `WIN = { save, load, focus }`), opened under the buttons and drawn from
    `M.render` after the main window via **`M._trt_windows()`**. Not modal popups — modals dim
    the screen and capture all input (locks the game chat log).
    `SavePopupBody` (name box, Replace if exists), `LoadPopupBody` / `LoadListRows`
    (2-column table in a child: selectable name — click selects, double-click loads — and a
    per-row Delete → "Sure?" button; bottom Load | Close).
  - `Guard(where, fn)` — pcall wrapper used inside popups/child/table so a Lua error can't
    skip the matching End*/Pop* calls (that unbalances the whole window → "Missing End()"
    ImGui error). Reports each distinct error to chat once.
  - `RenderSetupButtons(used, budget)` — Save | Load | Apply (Apply→Cancel while running;
    Apply tooltip: "Equip Currently Selected Spells"),
    "Loaded: name (modified)", status line.
- `RenderTraitDesigner` — right pane: **Your Set-up** (`Set points: X / Y - Z Left`,
  over-budget warning, Save/Load/Apply), Traits Gained, Spells Set (no-trait spells too;
  buttons: Clear set-up | Load Current Set).
- `RenderTraitsTab` — controls panel "Blue Points & Filters" (rows: Blue points [Set manually],
  Max points (manual only), Assimilation, Filters [Only learned, At/below my
  level, Can Combo], Spell type [Element dropdown, Magic, Physical, Ranged]) + two panes.

---

## Packets used

| Dir | Id | Use |
|---|---|---|
| in | 0x00A / 0x00B | Zone in (reload per-char settings) / zone out (save) |
| in | 0x028 | Action packet → seen counter |
| in | 0x044 | Job extra data → current BLU set spells (Presets Apply / Load Current Set) |
| out | 0x102 | Set / unset one Blue Magic spell (Traits Apply); all-zero = refresh request |

## Commands

`/blutracker` (`/blut`) toggle · `config|settings` · `test [spell]` · `floors` · `seen [reset [spell]|debug]`

## Change log

- **1.44** — Presets: Load Current Set moved from Blue Points & Filters to the Spells Set
  section, next to Clear set-up.
- 1.43 — Full data check against the 106 in-game spell cards (`cards/`): fixed 32 spells.
  MP: Actinic Burst 24, Auroral Drape 71, Blood Saber 48, Disseverment 74, Empty Thrash 45,
  Exuviation 40, Feather Barrier 56, Heat Breath 169, Ice Break 98, Light of Penance 38, Lowing 66,
  Maelstrom 115, Mind Blast 82, Occultation 28, Plasma Charge 24, Pollen 5, Quad. Continuum 55,
  Ram Charge 79, Reactor Cool 28, Saline Coat 66, Temporal Shift 48, Vertical Cleave 86, Winds 108.
  Families filled/fixed (Luminians, Empty, Beasts, Demons, Vermin; Cannonball Vermin, Heat Breath
  Beasts, Disseverment/Plasma Charge Luminians). Traits: Frenetic Rip → Accuracy Bonus, Refueling →
  Resist Slow. Trait sheet: Frost Breath cost 4, Voracious Trunk cost 3, Light of Penance 3 pts,
  Hysteric Barrage Lv69, Saline Coat added to Defense Bonus; new traits Store TP (Sickle Slash, Tail
  Slap), Counter (Enervation), Resist Gravity (Feather Barrier), Resist Slow (Refueling).
  'Luminians' added to `DB.FAMILIES`. Spell list columns re-aligned.
- 1.42 — Data (from in-game tooltip): Vanity Dive set cost 4 (was 2), MP 29, family Empty,
  effect "Dmg varies with TP". Added 'Empty' to `DB.FAMILIES` (Spells-tab family filter).
- 1.41 — Presets: removed the "All valid / tier I combinations" list under each trait.
- 1.40 — Presets: tier lines show only the overall cost per tier (no spell names).
- 1.39 — Presets: Element dropdown moved onto the Spell type row, before the three boxes.
- 1.38 — Presets: Element dropdown moved into Blue Points & Filters (row under Spell type);
  search box now spans exactly the Trait Sets card width.
- 1.37 — Presets: Magic / Physical / Ranged moved into Blue Points & Filters as a "Spell type"
  row at the bottom.
- 1.36 — Presets: Magic / Physical / Ranged boxes moved above the search box (Element
  dropdown stays under it). Removed the Geist Wall / Blood Saber "bugged" note from the data.
- 1.35 — Presets: traits stay collapsed by default while filtering; removed the trait rule
  text ("Any 2 spells...") and the "Cheapest per tier" heading (tier lines kept).
- 1.34 — Fix: traits can be collapsed while a search / element / type filter is active.
- 1.33 — Presets: element dropdown (None + 8 elements) and Magic / Physical / Ranged
  checkboxes under the search box; filter Trait Sets and No Traits.
- 1.32 — Spells tab: new **<= Skill level** filter (between Hide learned and <= my level) —
  hides spells your current Blue Magic skill can't learn yet.
- 1.31 — Search box: removed the "Search" label (box spans the pane).
- 1.30 — Removed the second info line (details now only in the hover card) and the search
  box / clear-button tooltips.
- 1.29 — Presets: every spell shows Type | Element | Effect | MP under its name (Trait Sets
  and No Traits), plus a full hover card (also on the Spells Set list).
- 1.28 — Traits tab renamed **Presets** (saved last-tab "Traits" migrates). New **No Traits**
  section under Trait Sets (tick no-trait spells into Your Set-up). **Search** bar above both.
- 1.27 — Apply button tooltip simplified to "Equip Currently Selected Spells".
- 1.26 — Mini tracker: each spell's mob list sorted lowest level → highest (was area/name).
- 1.25 — Designer holds every spell (no-trait spells counted with costs from
  `data/bluemage_setpoints.lua`); Load Current Set loads everything; Apply makes the game match
  exactly; Reserved slider removed. Trait-sheet vs wiki cost differences (sheet kept):
  Metallic Body 3 vs 1, Blood Saber 3 vs 2, Feather Tickle 3 vs 2, Plasma Charge 5 vs 4.
- 1.24 — Renamed to Load Current Set, moved right of Set manually, no success message.
- 1.23 — Traits tab: Show Current Set button (loads the spells set in game into Your Set-up).
- 1.22 — Save / Load are now normal floating windows (no screen dimming, chat not locked).
  Data: Magic Hammer has no job trait (removed from Magic Attack Bonus), MP 30.
  Designer ignores selections no longer on the trait sheet.
  Fixed Load window crash (BeginChild boolean arg → ImGui "Missing End()" error).
  Load window: per-row Delete (click twice), popups guarded against errors.
- 1.21 — Traits tab: Save / Load / Apply set-ups (BLUSets-style). "Set points: X / Y - Z Left" on one line.
- 1.20 — baseline when this code map was created.
