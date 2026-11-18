-- Fixer 1.6.0 (ju05): one switch for sightings. The old S goes only for the enemies a T goes out for: a killer of 40
-- days ago (no recent kill, no hit list, no bounty) gets neither T nor S, a fresh killer both. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

local function ofType(W, kind)
  local out = {}
  for _, m in ipairs(W.sent) do
    if m.prefix == "DeathNote" and m.text:find("^1\t" .. kind .. "\t") then out[#out + 1] = m end
  end
  return out
end
local function sieht(c, key) c.ns.Guild.OnUnit(key, "nameplate1", "plate", c.ns.Store.Get(key)) end

H.lauf("altes S nur fuer die Feinde einer T", function()
  local W = H.welt({ "SIGHTING" })
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  local old = H.tod(a, "Alt", "Feind", 40 * 86400)
  W.run(5)
  a.ns.Call.RefreshKillers()
  sieht(a, old); W.run(7)
  H.erwartet("Moerder von vor 40 Tagen: keine T", #ofType(W, "T") == 0, #ofType(W, "T"))
  H.erwartet("und kein S", #ofType(W, "S") == 0, #ofType(W, "S"))
  local fresh = H.tod(a, "Neu", "Feind")
  W.run(5)
  sieht(a, fresh); W.run(7)
  H.erwartet("frischer Moerder: eine T", #ofType(W, "T") == 1, #ofType(W, "T"))
  H.erwartet("und ein S", #ofType(W, "S") == 1, #ofType(W, "S"))
  H.erwartet("Guild.Setting('sightings') folgt dem einen Schalter", a.ns.Guild.Setting("sightings") == true)
  a.ns.Store.Setting("guild.layerSight", false)
  H.erwartet("aus: auch die Frage nach dem alten Schluessel sagt aus", a.ns.Guild.Setting("sightings") == false)
end)

H.fertig()
