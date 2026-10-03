--[[
* Level-capped zones for BluTracker (HorizonXI).
*
* zone name (exactly as written in bluemage_learnfrom.lua) -> level cap
*
* Inside a capped zone your BLU level (and so your Blue Magic skill) is held
* at the cap. A spell whose minimum learn level (data/bluemage_mrl.lua) is
* ABOVE the cap can never be learned there, so those zone entries are removed
* from every list (Zone tab, Tracker window, Learned From panel, maps).
*
* Example: Promyvion-Mea caps you at 30; Auroral Drape needs level 32 to
* learn, so Promyvion-Mea is dropped from Auroral Drape's sources.
*
* To add or correct a zone, edit this table and reload the addon.
--]]

return {
    -- Chains of Promathia
    ['Promyvion-Holla']    = 30,
    ['Promyvion-Dem']      = 30,
    ['Promyvion-Mea']      = 30,
    ['Promyvion-Vahzl']    = 50,
    ['Riverne-Site A01']   = 40,
    ['Riverne-Site B01']   = 50,
    ['Phomiuna Aqueducts'] = 40,
}
