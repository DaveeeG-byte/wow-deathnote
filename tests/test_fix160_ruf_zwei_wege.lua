-- Fixer 1.6.0 (jl08, counter-check): one call over two ways counts once, but two people with the same first name and
-- their own calls both come through. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"
local SOS = "DeathNoteSOS"

H.lauf("zwei Antons, zwei eigene Rufe", function()
  local W = H.welt({ "HELP_CALL" })
  _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
  local b = W.client("Berta", "Senf", G)
  b.login(); W.run(45)
  local Cl = b.ns.Call
  b.fire("CHAT_MSG_ADDON", SOS, Cl.Encode({ mapID = 1434, x = 50, y = 50, t = time() }), "GUILD", "Anton Wurst-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, Cl.Encode({ mapID = 1434, x = 20, y = 70, t = time() }), "GUILD", "Anton Kohl-Forever")
  H.erwartet("beide Rufe kommen an", H.zaehle(b, "HELP_CALL") == 2, H.zaehle(b, "HELP_CALL"))
  local text = Cl.Encode({ mapID = 1434, x = 30, y = 30, t = time() })
  W.run(31)
  b.fire("CHAT_MSG_ADDON", SOS, text, "PARTY", "Anton Wurst-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, text, "GUILD", "Anton-Forever")
  H.erwartet("derselbe Text desselben Vornamens ueber zwei Wege: einmal", H.zaehle(b, "HELP_CALL") == 3, H.zaehle(b, "HELP_CALL"))
end)

H.fertig()
