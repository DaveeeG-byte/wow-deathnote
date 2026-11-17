-- Jagd Logik 01b: wie JL01, aber mit der echten Meldung (GrudgeCard.lua, UI geladen), damit klar ist, dass auch die
-- Oberflaeche die Episode nicht schliesst. Erwartet: Tod in offener Welt, nur der Todesstoss (gebucht) -> nach dem
-- Todes-Zettel und einer Minute ist keine Episode mehr offen. Heute: Grudge.Current() bleibt die alte Episode.
-- Aufruf: luajit <diese Datei> .
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Humor.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
_G.UnitAffectingCombat = function(u) local x = AM.units[u]; return x ~= nil and x.combat ~= false end
_G.UnitInParty = function() return false end
local function tick(s) AM.Advance(s); BM.Advance(s) end
AM.recap = { id = 9, events = {
  { sourceGUID = "Player-93-Fies", sourceName = "Fies Ling", amount = 900, overkill = 50, timestamp = _G.time() - 1, spellName = "Hieb" } } }
AM.FireEvent("PLAYER_DEAD")
for _ = 1, 120 do ns.GrudgeCard.Tick(0.5); tick(0.5); BM.FinishAnims() end
local ep = ns.Grudge.Current()
local bad = 0
if not (ns.Store.Get("Fies-Ling") and ns.Store.Get("Fies-Ling").kills == 1) then
  io.write("Vorbedingung fehlt: Todesstoss nicht gebucht\n"); os.exit(2)
end
if ep ~= nil and not ep.closed then
  bad = 1
  io.write("RED   eine Minute nach dem Tod ist die Episode noch offen (closed=", tostring(ep.closed), ", Karte sichtbar=",
    tostring(rawget(BM.G, "DeathNoteGrudge"):IsShown()), ")\n")
end
io.write(("jl01b karte          %d gruen, %d rot\n"):format(1 - bad, bad))
os.exit(bad == 0 and 0 or 1)
