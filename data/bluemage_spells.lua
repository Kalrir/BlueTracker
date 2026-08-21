--[[
* Blue Magic spell database for Codex's Blue Mage module (HorizonXI).
*
* Source of truth: the HorizonXI wiki, which is a 75-era + "Era+" server
* and differs from retail in a number of places:
*   - https://horizonffxi.wiki/Blue_Magic            (spell list, level, type, trait, property)
*   - https://horizonffxi.wiki/Blue_Magic_Spell_List (MP, learn-from family, cast/recast)
*   - https://horizonffxi.wiki/Blue_Mage/Job_Traits  (trait set costs / weights)
*
* This is the set of spells learnable at level 75 and below on HorizonXI.
* Spells the wiki flags with the "HorizonXI specific changes" marker have
* hz=true, and their trait/behaviour here follows Horizon, NOT retail.
*
* Each record:
*   lvl   number  -- level the spell becomes usable / its skill req tier
*   name  string  -- exact in-game spell name (case-sensitive; matched
*                     against the "learns" chat message for auto-tracking)
*   kind  string  -- 'Phys' (physical, uses the SC property column) or
*                     'Mag' (magical/breath/heal/support)
*   elem  string  -- physical damage type (Slashing/Blunt/Piercing/H2H/Ranged)
*                     or magic element (Fire/Ice/Wind/Earth/Thunder/Water/Light/Dark)
*   role  string  -- rough purpose tag for filtering:
*                     Damage / Heal / Buff / Enfeeble / Drain / Dispel
*   trait string  -- job trait this spell contributes to when set ('None' if none)
*   prop  string  -- skillchain property (physical) or damage/effect note (magical)
*   fam   string  -- monster family the spell is learned from ('—' = not yet
*                     catalogued on the Horizon wiki at time of writing)
*   mp    number|nil -- MP cost ('?' shown when nil / not yet listed)
*   hz    bool|nil -- true if HorizonXI changes this spell vs retail
*
* NOTE on completeness: family/MP for a handful of Lv71-75 spells and the
* Horizon-only additions (Vanity Dive, Empty Thrash, Occultation, Auroral
* Drape, Quadratic Continuum, Winds of Promyvion) were not present in the
* wiki's rendered tables at time of writing and are marked '—' / nil rather
* than guessed. Everything else is taken directly from the Horizon wiki.
--]]

local M = {}

-- lvl, name, kind, elem, role, trait, prop, fam, mp, hz
M.LIST = {
    { 1,  'Sandspin',           'Mag',  'Earth',    'Damage',   'None',                'Magical dmg (Earth)',  'Amorphs',  10 },
    { 1,  'Pollen',             'Mag',  'Light',    'Heal',     'Resist Sleep',        'Restores HP',          'Vermin',   8 },
    { 1,  'Foot Kick',          'Phys', 'Slashing', 'Damage',   'Lizard Killer',       'Detonation',           'Beasts',   5 },
    { 4,  'Power Attack',       'Phys', 'Blunt',    'Damage',   'Plantoid Killer',     'Reverberation',        'Vermin',   5 },
    { 4,  'Sprout Smack',       'Phys', 'Blunt',    'Damage',   'Beast Killer',        'Reverberation',        'Plantoids',6 },
    { 4,  'Wild Oats',          'Phys', 'Piercing', 'Damage',   'Beast Killer',        'Transfixion',          'Plantoids',9 },
    { 8,  'Cocoon',             'Mag',  'Earth',    'Buff',     'None',                'Defense +50%',         'Vermin',   10,  true },
    { 8,  'Metallic Body',      'Mag',  'Earth',    'Buff',     'Conserve MP',         'Stoneskin',            'Aquans',   19,  true },
    { 8,  'Queasyshroom',       'Phys', 'Ranged',   'Damage',   'None',                'Compression',          'Plantoids',20 },
    { 12, 'Battle Dance',       'Phys', 'Slashing', 'Damage',   'Attack Bonus',        'Impaction',            'Beastmen', 12 },
    { 12, 'Feather Storm',      'Phys', 'Ranged',   'Damage',   'Rapid Shot',          'Transfixion',          'Beastmen', 12 },
    { 12, 'Head Butt',          'Phys', 'Blunt',    'Damage',   'None',                'Impaction (Stun)',     'Beastmen', 12 },
    { 16, 'Healing Breeze',     'Mag',  'Wind',     'Heal',     'Auto Regen',          'AoE cure',             'Beasts',   55 },
    { 16, 'Helldive',           'Phys', 'Blunt',    'Damage',   'None',                'Transfixion',          'Birds',    16 },
    { 16, 'Sheep Song',         'Mag',  'Light',    'Enfeeble', 'Auto Regen',          'AoE Sleep',            'Beasts',   22 },
    { 18, 'Blastbomb',          'Mag',  'Fire',     'Damage',   'Magic Attack Bonus',  'Fire dmg (Bind)',      'Beastmen', 36,  true },
    { 18, 'Bludgeon',           'Phys', 'Blunt',    'Damage',   'Undead Killer',       'Liquefaction',         'Arcana',   16 },
    { 18, 'Cursed Sphere',      'Mag',  'Water',    'Damage',   'Magic Attack Bonus',  'Water dmg',            'Vermin',   36 },
    { 20, 'Blood Drain',        'Mag',  'Dark',     'Drain',    'Conserve MP',         'HP drain',             'Birds',    10,  true },
    { 20, 'Claw Cyclone',       'Phys', 'Slashing', 'Damage',   'Lizard Killer',       'Scission',             'Beasts',   24 },
    { 22, 'Poison Breath',      'Mag',  'Water',    'Damage',   'Clear Mind',          'Breath (Water/Poison)','Undead',   22 },
    { 24, 'Soporific',          'Mag',  'Dark',     'Enfeeble', 'Clear Mind',          'AoE Sleep',            'Plantoids',38 },
    { 26, 'Screwdriver',        'Phys', 'Piercing', 'Damage',   'Evasion Bonus',       'Transfixion/Scission', 'Aquans',   21 },
    { 28, 'Vanity Dive',        'Phys', 'Slashing', 'Damage',   'Accuracy Bonus',      'Unconfirmed',          '—',        nil, true },
    { 28, 'Bomb Toss',          'Mag',  'Fire',     'Damage',   'Magic Accuracy Bonus','Fire dmg',             'Beastmen', 42,  true },
    { 30, 'Grand Slam',         'Phys', 'Blunt',    'Damage',   'Defense Bonus',       'Induration',           'Beastmen', 24 },
    { 30, 'Wild Carrot',        'Mag',  'Light',    'Heal',     'Resist Sleep',        'Restores HP',          'Beasts',   37 },
    { 34, 'Empty Thrash',       'Phys', 'Slashing', 'Damage',   'Max HP Boost',        'Unconfirmed',          '—',        nil, true },
    { 32, 'Chaotic Eye',        'Mag',  'Wind',     'Enfeeble', 'Conserve MP',         'Silence',              'Beasts',   13 },
    { 32, 'Sound Blast',        'Mag',  'Fire',     'Enfeeble', 'Magic Attack Bonus',  'INT down',             'Birds',    25 },
    { 34, 'Death Ray',          'Mag',  'Dark',     'Damage',   'None',                'Dark dmg',             'Amorphs',  49 },
    { 34, 'Smite of Rage',      'Phys', 'Slashing', 'Damage',   'Undead Killer',       'Detonation',           'Arcana',   28 },
    { 36, 'Digest',             'Mag',  'Dark',     'Drain',    'Conserve MP',         'HP drain',             'Amorphs',  20,  true },
    { 36, 'Pinecone Bomb',      'Phys', 'Ranged',   'Damage',   'None',                'Liquefaction (Sleep)', 'Plantoids',48 },
    { 38, 'Occultation',        'Mag',  'Wind',     'Buff',     'Evasion Bonus',       'None',                 '—',        nil, true },
    { 38, 'Blank Gaze',         'Mag',  'Light',    'Dispel',   'Magic Attack Bonus',  'Dispel',               'Beasts',   25,  true },
    { 38, 'Jet Stream',         'Phys', 'Blunt',    'Damage',   'Rapid Shot',          'Impaction',            'Birds',    47 },
    { 38, 'Uppercut',           'Phys', 'Blunt',    'Damage',   'Attack Bonus',        'Liquefaction/Impaction','Plantoids',31 },
    { 40, 'Mysterious Light',   'Mag',  'Wind',     'Damage',   'Max MP Boost',        'Wind dmg (Weight)',    'Arcana',   73 },
    { 40, 'Terror Touch',       'Phys', 'H2H',      'Damage',   'Defense Bonus',       'Compression/Reverb.',  'Undead',   31,  true },
    { 42, 'Auroral Drape',      'Mag',  'Wind',     'Enfeeble', 'Fast Cast',           'None',                 '—',        nil, true },
    { 42, 'MP Drainkiss',       'Mag',  'Dark',     'Drain',    'None',                'MP drain',             'Amorphs',  20 },
    { 42, 'Venom Shell',        'Mag',  'Water',    'Enfeeble', 'Clear Mind',          'AoE Poison',           'Aquans',   86 },
    { 44, 'Blitzstrahl',        'Mag',  'Thunder',  'Damage',   'Magic Accuracy Bonus','Thunder dmg (Stun)',   'Arcana',   70,  true },
    { 44, 'Mandibular Bite',    'Phys', 'Slashing', 'Damage',   'Plantoid Killer',     'Induration',           'Vermin',   38 },
    { 44, 'Stinking Gas',       'Mag',  'Wind',     'Enfeeble', 'Auto Refresh',        'VIT down',             'Undead',   37 },
    { 46, 'Awful Eye',          'Mag',  'Water',    'Enfeeble', 'Clear Mind',          'STR down',             'Lizards',  32 },
    { 46, 'Geist Wall',         'Mag',  'Dark',     'Dispel',   'Auto Refresh',        'AoE Dispel',           'Lizards',  35,  true },
    { 46, 'Magnetite Cloud',    'Mag',  'Earth',    'Damage',   'Magic Defense Bonus', 'Breath (Earth/Weight)','Beastmen', 86 },
    { 48, 'Blood Saber',        'Mag',  'Dark',     'Drain',    'Auto Refresh',        'AoE HP drain',         'Undead',   25,  true },
    { 48, 'Jettatura',          'Mag',  'Dark',     'Enfeeble', 'None',                'Terror',               'Birds',    37 },
    { 48, 'Refueling',          'Mag',  'Wind',     'Buff',     'None',                'Haste +15%',           'Arcana',   29,  true },
    { 48, 'Sickle Slash',       'Phys', 'H2H',      'Damage',   'Store TP',            'Compression',          'Vermin',   41 },
    { 50, 'Frightful Roar',     'Mag',  'Wind',     'Enfeeble', 'Auto Refresh',        'Defense down',         'Demons',   32 },
    { 50, 'Ice Break',          'Mag',  'Ice',      'Damage',   'Magic Defense Bonus', 'Ice dmg (Bind)',       'Arcana',   142, true },
    { 50, 'Self-Destruct',      'Mag',  'Fire',     'Damage',   'Auto Refresh',        'Fire dmg (self KO)',   'Arcana',   100 },
    { 52, 'Cold Wave',          'Mag',  'Ice',      'Damage',   'Auto Refresh',        'Ice dmg (AGI down)',   'Arcana',   37 },
    { 52, 'Filamented Hold',    'Mag',  'Earth',    'Enfeeble', 'Clear Mind',          'AoE Slow',             'Vermin',   38 },
    { 54, 'Quadratic Continuum','Phys', 'Piercing', 'Damage',   'Defense Bonus',       'Unconfirmed',          '—',        nil, true },
    { 54, 'Hecatomb Wave',      'Mag',  'Wind',     'Damage',   'Max MP Boost',        'Breath (Wind)',        'Demons',   116 },
    { 54, 'Radiant Breath',     'Mag',  'Light',    'Damage',   'None',                'Breath (Light)',       'Dragons',  116 },
    { 56, 'Winds of Promyvion', 'Mag',  'Light',    'Enfeeble', 'Auto Refresh',        'None',                 '—',        nil, true },
    { 56, 'Feather Barrier',    'Mag',  'Wind',     'Buff',     'Resist Gravity',      'Evasion +20',          'Birds',    29,  true },
    { 58, 'Flying Hip Press',   'Mag',  'Wind',     'Damage',   'Max HP Boost',        'Breath (Wind)',        'Beastmen', 125 },
    { 58, 'Light of Penance',   'Mag',  'Light',    'Enfeeble', 'Auto Refresh',        'TP down / Blind',      'Beastmen', 53,  true },
    { 58, 'Magic Fruit',        'Mag',  'Light',    'Heal',     'Resist Sleep',        'Restores HP',          'Beasts',   72 },
    { 60, 'Death Scissors',     'Phys', 'Slashing', 'Damage',   'Attack Bonus',        'Compression/Reverb.',  'Vermin',   51 },
    { 60, 'Dimensional Death',  'Phys', 'H2H',      'Damage',   'Accuracy Bonus',      'Transfixion/Impaction','Undead',   48 },
    { 61, 'Maelstrom',          'Mag',  'Water',    'Damage',   'Clear Mind',          'Water dmg (STR down)', 'Aquans',   162, true },
    { 61, 'Eyes On Me',         'Mag',  'Dark',     'Damage',   'Magic Attack Bonus',  'Dark dmg',             'Demons',   112 },
    { 61, 'Seedspray',          'Phys', 'Slashing', 'Damage',   'Beast Killer',        'Induration/Detonation','Plantoids',61 },
    { 61, 'Bad Breath',         'Mag',  'Earth',    'Enfeeble', 'Fast Cast',           'Breath (multi-ail.)',  'Plantoids',212 },
    { 62, '1000 Needles',       'Mag',  'Light',    'Damage',   'Beast Killer',        'Light dmg (fixed)',    'Plantoids',350 },
    { 62, 'Body Slam',          'Phys', 'Blunt',    'Damage',   'Max HP Boost',        'Impaction',            'Dragons',  74 },
    { 62, 'Memento Mori',       'Mag',  'Ice',      'Buff',     'Magic Attack Bonus',  'Magic Atk +20',        'Undead',   46 },
    { 63, 'Frenetic Rip',       'Phys', 'Blunt',    'Damage',   'Accuracy Bonus',      'Induration',           'Demons',   61 },
    { 63, 'Frypan',             'Phys', 'Blunt',    'Damage',   'Max HP Boost',        'Impaction (Stun)',     'Beastmen', 65 },
    { 63, 'Hydro Shot',         'Phys', 'H2H',      'Damage',   'Rapid Shot',          'Reverb./Fragmentation','Beastmen', 55 },
    { 63, 'Spinal Cleave',      'Phys', 'Slashing', 'Damage',   'Attack Bonus',        'Scission/Detonation',  'Undead',   61 },
    { 64, 'Feather Tickle',     'Mag',  'Wind',     'Enfeeble', 'Clear Mind',          'TP down',              'Birds',    48 },
    { 64, 'Voracious Trunk',    'Mag',  'Wind',     'Dispel',   'Auto Refresh',        'Steal buff',           'Beasts',   72 },
    { 64, 'Yawn',               'Mag',  'Light',    'Enfeeble', 'Resist Sleep',        'AoE Sleep',            'Birds',    55 },
    { 65, 'Infrasonics',        'Mag',  'Ice',      'Enfeeble', 'Magic Accuracy Bonus','Evasion down',         'Lizards',  42,  true },
    { 65, 'Zephyr Mantle',      'Mag',  'Wind',     'Buff',     'Conserve MP',         'Blink (4 shadows)',    'Dragons',  31 },
    { 66, 'Frost Breath',       'Mag',  'Ice',      'Damage',   'Conserve MP',         'Breath (Ice/Para.)',   'Lizards',  136, true },
    { 66, 'Sandspray',          'Mag',  'Dark',     'Enfeeble', 'Clear Mind',          'AoE Blind',            'Beastmen', 43 },
    { 67, 'Diamondhide',        'Mag',  'Earth',    'Buff',     'None',                'AoE Stoneskin',        'Beastmen', 99 },
    { 67, 'Enervation',         'Mag',  'Dark',     'Enfeeble', 'Counter',             'Def / M.Def down',     'Beastmen', 48 },
    { 68, 'Warm-Up',            'Mag',  'Earth',    'Buff',     'Clear Mind',          'Acc/Eva +10',          'Beastmen', 59 },
    { 68, 'Firespit',           'Mag',  'Fire',     'Damage',   'Conserve MP',         'Fire dmg',             'Beastmen', 121 },
    { 69, 'Hysteric Barrage',   'Phys', 'H2H',      'Damage',   'Evasion Bonus',       'Detonation',           'Beastmen', 61 },
    { 69, 'Tail Slap',          'Phys', 'H2H',      'Damage',   'Store TP',            'Reverb./Fragmentation','Beastmen', 77 },
    { 70, 'Amplification',      'Mag',  'Water',    'Buff',     'None',                'M.Atk/M.Def +10',      'Amorphs',  48 },
    { 70, 'Cannonball',         'Phys', 'H2H',      'Damage',   'None',                'Fusion',               'Arcana',   66 },
    { 71, 'Heat Breath',        'Mag',  'Fire',     'Damage',   'Magic Attack Bonus',  'Breath (Fire)',        'Dragons',  nil },
    { 71, 'Lowing',             'Mag',  'Fire',     'Enfeeble', 'Clear Mind',          'None',                 '—',        nil },
    { 72, 'Disseverment',       'Phys', 'Piercing', 'Damage',   'Accuracy Bonus',      'Distortion',           'Plantoids',nil },
    { 72, 'Saline Coat',        'Mag',  'Light',    'Buff',     'Defense Bonus',       'Magic dmg taken down', '—',        nil },
    { 73, 'Mind Blast',         'Mag',  'Thunder',  'Damage',   'Clear Mind',          'Thunder dmg (Para.)',  '—',        nil },
    { 73, 'Ram Charge',         'Phys', 'Blunt',    'Damage',   'Lizard Killer',       'Fragmentation',        'Beasts',   nil },
    { 73, 'Temporal Shift',     'Mag',  'Thunder',  'Damage',   'Attack Bonus',        'Thunder dmg (Stun)',   '—',        nil },
    { 74, 'Actinic Burst',      'Mag',  'Light',    'Enfeeble', 'Auto Refresh',        'AoE Flash',            '—',        nil },
    { 74, 'Magic Hammer',       'Mag',  'Light',    'Damage',   'Magic Attack Bonus',  'Light dmg (MP drain)', 'Beastmen', nil, true },
    { 74, 'Reactor Cool',       'Mag',  'Ice',      'Enfeeble', 'Magic Defense Bonus', 'None',                 '—',        nil, true },
    { 75, 'Exuviation',         'Mag',  'Fire',     'Heal',     'Resist Sleep',        'Cure + remove ail.',   '—',        nil },
    { 75, 'Plasma Charge',      'Mag',  'Thunder',  'Damage',   'Auto Refresh',        'Thunder dmg',          'Arcana',   nil },
    { 75, 'Vertical Cleave',    'Phys', 'Slashing', 'Damage',   'Defense Bonus',       'Gravitation',          '—',        nil },
}

-- Normalize into keyed records the module can index by a stable key.
-- key = lowercase name with non-alphanumerics stripped.
local function keyify(name)
    return (name:lower():gsub('[^%w]', ''))
end

M.SPELLS = {}       -- array of { key, lvl, name, kind, elem, role, trait, prop, fam, mp, hz }
M.BY_KEY = {}       -- key -> record
M.BY_NAME = {}      -- exact name -> record

for _, r in ipairs(M.LIST) do
    local rec = {
        lvl   = r[1],
        name  = r[2],
        kind  = r[3],
        elem  = r[4],
        role  = r[5],
        trait = r[6],
        prop  = r[7],
        fam   = r[8],
        mp    = r[9],
        hz    = r[10] or false,
        key   = keyify(r[2]),
    }
    M.SPELLS[#M.SPELLS + 1] = rec
    M.BY_KEY[rec.key]  = rec
    M.BY_NAME[rec.name] = rec
end

M.COUNT = #M.SPELLS
M.keyify = keyify

-- Distinct value lists for filters (kept in a friendly order).
M.TRAITS = {}
do
    local seen = {}
    for _, r in ipairs(M.SPELLS) do
        if r.trait and r.trait ~= 'None' and not seen[r.trait] then
            seen[r.trait] = true
            M.TRAITS[#M.TRAITS + 1] = r.trait
        end
    end
    table.sort(M.TRAITS)
end

M.FAMILIES = { 'Beasts', 'Beastmen', 'Plantoids', 'Vermin', 'Aquans', 'Birds',
               'Lizards', 'Amorphs', 'Arcana', 'Undead', 'Demons', 'Dragons' }

M.ROLES = { 'Damage', 'Heal', 'Buff', 'Enfeeble', 'Drain', 'Dispel' }

return M
