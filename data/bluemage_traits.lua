--[[
* Blue Magic job-trait sets for BluTracker's Traits tab (HorizonXI, Era+).
*
* Source: community Era+ trait sheet (subject to change as the community learns
* more about Era+ changes).
*
* Each trait:
*   name   trait name
*   rule   short description shown in the tab
*   need   trait points needed per tier (8 = "any 2 spells" when each gives 4)
*   max    highest tier reachable (nil = keeps going, one tier per 'need' points)
*   note   optional extra note
*   spells { level, spell name, set point cost, trait points }
*
* Spell names must match data/bluemage_spells.lua (or one of its aliases).
--]]

local M = {}

M.TRAITS = {
    { name = 'Accuracy Bonus', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 28, 'Vanity Dive',       2, 4 },
        { 60, 'Dimensional Death', 5, 4 },
        { 63, 'Frenetic Rip',      3, 4 },
        { 72, 'Disseverment',      5, 4 },
      } },
    { name = 'Attack Bonus', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 12, 'Battle Dance',   3, 4 },
        { 38, 'Uppercut',       3, 4 },
        { 60, 'Death Scissors', 5, 4 },
        { 63, 'Spinal Cleave',  4, 4 },
        { 73, 'Temporal Shift', 5, 4 },
      } },
    { name = 'Auto Refresh', need = 8, max = 1,
      rule = 'Auto Refresh points must add up to at least 8 (set cost doesn\'t matter).',
      note = 'Geist Wall (4) and Blood Saber (4) are bugged high: expected to drop to 1 and 2.',
      spells = {
        { 44, 'Stinking Gas',       2, 1 },
        { 46, 'Geist Wall',         3, 4 },
        { 48, 'Blood Saber',        3, 4 },
        { 50, 'Frightful Roar',     3, 2 },
        { 50, 'Self-Destruct',      3, 2 },
        { 52, 'Cold Wave',          1, 1 },
        { 56, 'Winds of Promyvion', 4, 2 },
        { 58, 'Light of Penance',   5, 2 },
        { 64, 'Voracious Trunk',    4, 3 },
        { 74, 'Actinic Burst',      4, 4 },
        { 75, 'Plasma Charge',      5, 4 },
      } },
    { name = 'Auto Regen', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        { 16, 'Sheep Song',     2, 4 },
        { 16, 'Healing Breeze', 4, 4 },
        { 94, 'White Wind',     5, 4 },
      } },
    { name = 'Clear Mind', need = 8, max = 4,
      rule = 'Any 2 spells. Every 2 more spells adds a tier, up to Clear Mind IV.',
      spells = {
        { 22, 'Poison Breath',   1, 4 },
        { 24, 'Soporific',       4, 4 },
        { 42, 'Venom Shell',     3, 4 },
        { 46, 'Awful Eye',       2, 4 },
        { 52, 'Filamented Hold', 3, 4 },
        { 61, 'Maelstrom',       5, 4 },
        { 64, 'Feather Tickle',  3, 4 },
        { 66, 'Sandspray',       2, 4 },
        { 68, 'Warm-Up',         4, 4 },
        { 71, 'Lowing',          2, 4 },
        { 73, 'Mind Blast',      4, 4 },
      } },
    { name = 'Conserve MP', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      note = 'Frost Breath adds a tier on its own.',
      spells = {
        {  8, 'Metallic Body', 3, 4 },
        { 20, 'Blood Drain',   2, 4 },
        { 32, 'Chaotic Eye',   2, 4 },
        { 36, 'Digest',        2, 4 },
        { 65, 'Zephyr Mantle', 2, 4 },
        { 66, 'Frost Breath',  3, 8 },
        { 68, 'Firespit',      5, 4 },
      } },
    { name = 'Defense Bonus', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 30, 'Grand Slam',          2, 4 },
        { 40, 'Terror Touch',        3, 4 },
        { 54, 'Quadratic Continuum', 4, 4 },
        { 75, 'Vertical Cleave',     3, 4 },
      } },
    { name = 'Evasion Bonus', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        { 26, 'Screwdriver',      3, 4 },
        { 38, 'Occultation',      3, 4 },
        { 72, 'Hysteric Barrage', 5, 4 },
      } },
    { name = 'Magic Attack Bonus', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 18, 'Blastbomb',     2, 4 },
        { 18, 'Cursed Sphere', 2, 4 },
        { 32, 'Sound Blast',   1, 4 },
        { 38, 'Blank Gaze',    2, 4 },
        { 61, 'Eyes On Me',    4, 4 },
        { 62, 'Memento Mori',  4, 4 },
        { 71, 'Heat Breath',   4, 4 },
        { 74, 'Magic Hammer',  4, 4 },
      } },
    { name = 'Magic Defense Bonus', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 46, 'Magnetite Cloud', 3, 4 },
        { 50, 'Ice Break',       3, 4 },
        { 74, 'Reactor Cool',    5, 4 },
        { 84, 'Osmosis',         5, 4 },
      } },
    { name = 'Max HP Boost', need = 8,
      rule = 'Any 2 spells. Every 2 more spells adds a tier.',
      spells = {
        { 34, 'Empty Thrash',     3, 4 },
        { 58, 'Flying Hip Press', 3, 4 },
        { 62, 'Body Slam',        4, 4 },
        { 63, 'Frypan',           3, 4 },
      } },
    { name = 'Max MP Boost', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        { 40, 'Mysterious Light', 4, 4 },
        { 54, 'Hecatomb Wave',    3, 4 },
      } },
    { name = 'Rapid Shot', need = 8, max = 1,
      rule = 'Any 2 spells. Works with your current throwing weapon.',
      spells = {
        { 12, 'Feather Storm', 3, 4 },
        { 38, 'Jet Stream',    4, 4 },
        { 63, 'Hydro Shot',    3, 4 },
      } },
    { name = 'Resist Sleep', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        {  1, 'Pollen',      1, 4 },
        { 30, 'Wild Carrot', 3, 4 },
        { 58, 'Magic Fruit', 3, 4 },
        { 64, 'Yawn',        3, 4 },
        { 75, 'Exuviation',  4, 4 },
      } },
    { name = 'Beast Killer', need = 8, max = 1,
      rule = 'Any 2 of these spells.',
      spells = {
        {  4, 'Wild Oats',    3, 4 },
        {  4, 'Sprout Smack', 2, 4 },
        { 61, 'Seedspray',    2, 4 },
        { 62, '1000 Needles', 5, 4 },
      } },
    { name = 'Lizard Killer', need = 8, max = 1,
      rule = 'Any 2 of these spells.',
      spells = {
        {  1, 'Foot Kick',    2, 4 },
        { 20, 'Claw Cyclone', 2, 4 },
        { 73, 'Ram Charge',   4, 4 },
      } },
    { name = 'Undead Killer', need = 8, max = 1,
      rule = 'Both spells.',
      spells = {
        { 18, 'Bludgeon',      2, 4 },
        { 34, 'Smite of Rage', 3, 4 },
      } },
    { name = 'Plantoid Killer', need = 8, max = 1,
      rule = 'Both spells.',
      spells = {
        {  4, 'Power Attack',    1, 4 },
        { 44, 'Mandibular Bite', 2, 4 },
      } },
    { name = 'Magic Accuracy Bonus', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        { 28, 'Bomb Toss',   3, 4 },
        { 44, 'Blitzstrahl', 4, 4 },
        { 65, 'Infrasonics', 4, 4 },
      } },
    { name = 'Fast Cast', need = 8, max = 1,
      rule = 'Any 2 spells.',
      spells = {
        { 42, 'Auroral Drape', 4, 4 },
        { 61, 'Bad Breath',    5, 4 },
      } },
}

return M
