-- Jagd Logik 160/02: Call.Send setzt die Abklingzeit (lastSend) VOR dem Senden. Nimmt der Client auf keinem Weg an
-- (Ergebniscode 3 AddonMessageThrottle, 8 ChannelThrottle, 11 Lockdown), meldet die Zeile "nicht gesendet (Code)",
-- der naechste Druck auf die Taste aber "warte 30 s". Wer im Notfall gleich nochmal drueckt, kann 30 s nicht rufen,
-- obwohl nichts rausging.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

for _, code in ipairs({ 3, 8, 11 }) do
  H.lauf("Code " .. code .. " auf allen Wegen, danach sofort nochmal", function()
    local W = H.welt({ "HELP_CALL" })
    _G.C_Map.GetMapInfo = function(id) return { name = "Zone", mapType = 3, parentMapID = 13 } end
    local a = W.client("Anton", "Wurst", G)
    local b = W.client("Berta", "Senf", G)
    a.login(); b.login(); W.run(45)
    a.sendResult = code
    local ok, why, det = a.ns.Call.Send()
    H.erwartet("Vorbedingung: abgelehnt mit Code", ok == false and why == "failed" and tostring(det) == tostring(code),
      tostring(why) .. " " .. tostring(det))
    a.sendResult = nil
    W.run(1)
    local ok2, why2 = a.ns.Call.Send()
    H.erwartet("zweiter Versuch 1 s spaeter geht raus (nichts wurde gesendet)", ok2 == true, tostring(why2))
  end)
end

H.fertig()
