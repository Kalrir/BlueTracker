--[[
* Blue Magic set-point cost ("Blue Magic Points") per spell, for BluTracker's
* Traits tab designer / Apply.
*
* Source: HorizonXI wiki, Blue_Magic_Spell_List ("B" column), Oct 2026.
* Spells on the trait sheet (data/bluemage_traits.lua) use the sheet's cost
* instead; this file covers everything else (nukes, cures, Cocoon, ...).
* Horizon-only spells missing from the wiki table (Vanity Dive, Empty Thrash,
* Occultation, Auroral Drape, Quadratic Continuum, Winds of Promyvion) are on
* the trait sheet, so they get their cost from there.
*
* key = lowercase spell name with non-alphanumerics stripped (DB.keyify).
--]]

return {
    ["sandspin"]           = 2,   -- Sandspin
    ["pollen"]             = 1,   -- Pollen
    ["footkick"]           = 2,   -- Foot Kick
    ["powerattack"]        = 1,   -- Power Attack
    ["sproutsmack"]        = 2,   -- Sprout Smack
    ["wildoats"]           = 3,   -- Wild Oats
    ["metallicbody"]       = 1,   -- Metallic Body
    ["cocoon"]             = 1,   -- Cocoon
    ["queasyshroom"]       = 2,   -- Queasyshroom
    ["battledance"]        = 3,   -- Battle Dance
    ["headbutt"]           = 3,   -- Head Butt
    ["featherstorm"]       = 3,   -- Feather Storm
    ["helldive"]           = 2,   -- Helldive
    ["healingbreeze"]      = 4,   -- Healing Breeze
    ["sheepsong"]          = 2,   -- Sheep Song
    ["bludgeon"]           = 2,   -- Bludgeon
    ["cursedsphere"]       = 2,   -- Cursed Sphere
    ["blastbomb"]          = 2,   -- Blastbomb
    ["blooddrain"]         = 2,   -- Blood Drain
    ["clawcyclone"]        = 2,   -- Claw Cyclone
    ["poisonbreath"]       = 1,   -- Poison Breath
    ["soporific"]          = 4,   -- Soporific
    ["screwdriver"]        = 3,   -- Screwdriver
    ["bombtoss"]           = 3,   -- Bomb Toss
    ["wildcarrot"]         = 3,   -- Wild Carrot
    ["grandslam"]          = 2,   -- Grand Slam
    ["soundblast"]         = 1,   -- Sound Blast
    ["chaoticeye"]         = 2,   -- Chaotic Eye
    ["deathray"]           = 2,   -- Death Ray
    ["smiteofrage"]        = 3,   -- Smite of Rage
    ["digest"]             = 2,   -- Digest
    ["pineconebomb"]       = 2,   -- Pinecone Bomb
    ["blankgaze"]          = 2,   -- Blank Gaze
    ["jetstream"]          = 4,   -- Jet Stream
    ["uppercut"]           = 3,   -- Uppercut
    ["mysteriouslight"]    = 4,   -- Mysterious Light
    ["terrortouch"]        = 3,   -- Terror Touch
    ["venomshell"]         = 3,   -- Venom Shell
    ["mpdrainkiss"]        = 4,   -- MP Drainkiss
    ["blitzstrahl"]        = 4,   -- Blitzstrahl
    ["stinkinggas"]        = 2,   -- Stinking Gas
    ["mandibularbite"]     = 2,   -- Mandibular Bite
    ["magnetitecloud"]     = 3,   -- Magnetite Cloud
    ["geistwall"]          = 3,   -- Geist Wall
    ["awfuleye"]           = 2,   -- Awful Eye
    ["refueling"]          = 4,   -- Refueling
    ["bloodsaber"]         = 2,   -- Blood Saber
    ["sickleslash"]        = 4,   -- Sickle Slash
    ["jettatura"]          = 4,   -- Jettatura
    ["icebreak"]           = 3,   -- Ice Break
    ["selfdestruct"]       = 3,   -- Self-Destruct
    ["frightfulroar"]      = 3,   -- Frightful Roar
    ["coldwave"]           = 1,   -- Cold Wave
    ["filamentedhold"]     = 3,   -- Filamented Hold
    ["hecatombwave"]       = 3,   -- Hecatomb Wave
    ["radiantbreath"]      = 4,   -- Radiant Breath
    ["featherbarrier"]     = 2,   -- Feather Barrier
    ["magicfruit"]         = 3,   -- Magic Fruit
    ["flyinghippress"]     = 3,   -- Flying Hip Press
    ["lightofpenance"]     = 5,   -- Light of Penance
    ["deathscissors"]      = 5,   -- Death Scissors
    ["dimensionaldeath"]   = 5,   -- Dimensional Death
    ["spiralspin"]         = 3,   -- Spiral Spin
    ["maelstrom"]          = 5,   -- Maelstrom
    ["eyesonme"]           = 4,   -- Eyes On Me
    ["seedspray"]          = 2,   -- Seedspray
    ["badbreath"]          = 5,   -- Bad Breath
    ["mementomori"]        = 4,   -- Memento Mori
    ["bodyslam"]           = 4,   -- Body Slam
    ["1000needles"]        = 5,   -- 1000 Needles
    ["spinalcleave"]       = 4,   -- Spinal Cleave
    ["freneticrip"]        = 3,   -- Frenetic Rip
    ["frypan"]             = 3,   -- Frypan
    ["hydroshot"]          = 3,   -- Hydro Shot
    ["feathertickle"]      = 2,   -- Feather Tickle
    ["yawn"]               = 3,   -- Yawn
    ["voracioustrunk"]     = 4,   -- Voracious Trunk
    ["infrasonics"]        = 4,   -- Infrasonics
    ["zephyrmantle"]       = 2,   -- Zephyr Mantle
    ["frostbreath"]        = 3,   -- Frost Breath
    ["sandspray"]          = 2,   -- Sandspray
    ["corrosiveooze"]      = 4,   -- Corrosive Ooze
    ["diamondhide"]        = 3,   -- Diamondhide
    ["enervation"]         = 5,   -- Enervation
    ["warmup"]             = 4,   -- Warm-Up
    ["firespit"]           = 5,   -- Firespit
    ["tailslap"]           = 4,   -- Tail Slap
    ["hystericbarrage"]    = 5,   -- Hysteric Barrage
    ["regurgitation"]      = 1,   -- Regurgitation
    ["amplification"]      = 3,   -- Amplification
    ["cannonball"]         = 3,   -- Cannonball
    ["asuranclaws"]        = 2,   -- Asuran Claws
    ["lowing"]             = 2,   -- Lowing
    ["heatbreath"]         = 4,   -- Heat Breath
    ["triumphantroar"]     = 3,   -- Triumphant Roar
    ["disseverment"]       = 5,   -- Disseverment
    ["subzerosmash"]       = 4,   -- Sub-zero Smash
    ["salinecoat"]         = 3,   -- Saline Coat
    ["ramcharge"]          = 4,   -- Ram Charge
    ["mindblast"]          = 4,   -- Mind Blast
    ["temporalshift"]      = 5,   -- Temporal Shift
    ["actinicburst"]       = 4,   -- Actinic Burst
    ["magichammer"]        = 4,   -- Magic Hammer
    ["reactorcool"]        = 5,   -- Reactor Cool
    ["exuviation"]         = 4,   -- Exuviation
    ["plasmacharge"]       = 4,   -- Plasma Charge
    ["verticalcleave"]     = 3,   -- Vertical Cleave
    ["pleniluneembrace"]   = 4,   -- Plenilune Embrace
}
