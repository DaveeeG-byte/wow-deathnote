-- Jagd Logik 160/03: Der Empfang eines Hilferufs prueft die eigene Lage nicht. Wer in einem Schlachtzug, Dungeon
-- oder Schlachtfeld steht, bekommt fuer den Ruf eines Gildies aus der offenen Welt den lauten Alarm (Look.Alarm
-- "alert") und den Zettel mitten in den Bosskampf. Sonst schweigt das Buch in Instanzen (Tracker.active,
-- Plate, Feud-Alarm nur offene Welt), helfen kann man von dort ohnehin nicht. Erwartet: in einer Instanz hoechstens
-- die Chatzeile, kein Ton, kein Zettel.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

-- CallUI.lua (nicht im Logik-Mock) spielt fuer JEDES HELP_CALL den Alarm und zeigt den Zettel (CallUI.OnCall, nur
-- alert.enabled wird gefragt). Gruen also nur, wenn in der Instanz kein HELP_CALL feuert oder der Satz als leise
-- markiert ist (rec.quiet) und CallUI das achtet.
for _, kind in ipairs({ "raid", "party", "pvp" }) do
  H.lauf("Empfaenger in Instanz '" .. kind .. "'", function()
    local W = H.welt({ "HELP_CALL" })
    _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
    local b = W.client("Berta", "Senf", G)
    b.login(); W.run(45)
    local text = b.ns.Call.Encode({ mapID = 1434, x = 50, y = 50, t = time() })
    M.instance = { true, kind }
    b.fire("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Anton Wurst-Forever")
    M.instance = { false, "none" }
    local loud = 0
    for _, e in ipairs(b.events) do
      if e[1] == "HELP_CALL" and not (type(e[2]) == "table" and e[2].quiet == true) then loud = loud + 1 end
    end
    H.erwartet("in der Instanz kein lauter Ruf (HELP_CALL ohne quiet)", loud == 0, loud .. " lauter Ruf")
  end)
end

H.fertig()
