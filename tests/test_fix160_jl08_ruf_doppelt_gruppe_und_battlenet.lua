-- Jagd Logik 160/08: Ein Battle.net-Freund in derselben Gruppe bekommt den Hilferuf zweimal: einmal ueber PARTY
-- (Absender "Anton Wurst-Forever", Client mit Nachnamen), einmal ueber Battle.net (characterName "Anton"). Call.Receive entdoppelt je Absender ueber
-- (full or short):lower(); die beiden Schreibweisen sind verschieden, also zwei laute Alarme, zwei Zettel, zwei
-- Nadeln, zwei Eintraege im Ring. Friends.Peers laesst nur Gildenkollegen weg, nicht Gruppenmitglieder.
-- Erwartet: ein Ruf je Absender, egal ueber wie viele Wege.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")

H.lauf("Battle.net-Freund in der Gruppe", function()
  local W = H.welt({ "HELP_CALL" })
  _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
  local a = W.client("Anton", "Wurst", nil, { bn = { "Carla" }, fullSender = true })   -- der Client nennt den Absender mit Nachnamen
  local c = W.client("Carla", "Netz", nil, { bn = { "Anton" } })
  a.login(); c.login(); W.run(90)
  a.env.IsInGroup = function() return true end
  c.env.IsInGroup = function() return true end
  local ok, got = a.ns.Call.Send()
  W.run(0.5)
  H.erwartet("Vorbedingung: Gruppe und ein Freund", ok == true and got.group == true and got.friends == 1,
    got and (tostring(got.group) .. " " .. tostring(got.friends)))
  H.erwartet("Carla bekommt einen Ruf", H.zaehle(c, "HELP_CALL") == 1, H.zaehle(c, "HELP_CALL") .. " Rufe")
end)

H.fertig()
