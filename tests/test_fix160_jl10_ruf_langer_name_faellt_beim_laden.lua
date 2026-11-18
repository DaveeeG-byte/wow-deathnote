-- Jagd Logik 160/10: Der Anzeigename des Angreifers im Hilferuf wird beim Empfang aus dem Schluessel neu gebaut
-- (Call.shownName: "Name Nachname" des Schluessels, ungekuerzt). Ist er laenger als C.NAME_MAX (48 Byte, z. B.
-- kyrillisch "Владислав Крестовоздвиженский" = 57 Byte), steht er so im Ring. Beim naechsten Laden verwirft
-- Call.SanitizeDB den ganzen Ruf (validRec verlangt #display <= 48): nach /reload ist der Ruf weg.
-- Erwartet: ein empfangener Ruf uebersteht das Laden (Name gekuerzt oder Grenze gleich).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

H.lauf("Ruf mit langem kyrillischem Angreifer, dann /reload", function()
  local W = H.welt({ "HELP_CALL" })
  _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
  local b = W.client("Berta", "Senf", G)
  b.login(); W.run(45)
  local Cl = b.ns.Call
  local key = b.ns.Util.KeyFor("Владислав", "Крестовоздвиженский")
  local text = Cl.Encode({ mapID = 1434, x = 50, y = 50, t = time(), key = key, display = "Владислав Крестовоздвиженский" })
  H.erwartet("Vorbedingung: kodiert", text ~= nil)
  b.fire("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Anton Wurst-Forever")
  H.erwartet("Vorbedingung: empfangen", #Cl.Calls() == 1, #Cl.Calls())
  local b2 = H.relog(W, b)
  b2.login(); W.run(5)
  H.erwartet("nach /reload noch im Ring", #b2.ns.Call.Calls() == 1, #b2.ns.Call.Calls() .. " Rufe")
end)

H.fertig()
