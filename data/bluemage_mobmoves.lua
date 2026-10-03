--[[
* Extra monster-ability names for BluTracker's "seen in chat" counter.
*
* The counter already matches each Blue Magic spell's own name (plus the
* shortened in-game aliases in bluemage_spells.lua), which covers the monster
* TP moves that share the spell's name -- the large majority of them.
*
* If a monster's move appears in chat under a DIFFERENT name than the Blue
* Magic spell it teaches, add it here so it counts toward that spell:
*
*     key (lowercase spell name, letters/digits only) = { 'Name In Chat', ... },
*
* Example (illustrative only):
*     -- headbutt = { 'Head Butt', 'Some Other Name' },
--]]

return {
}
