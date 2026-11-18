-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- Jagd 2 Fehler 05: Der Hilferuf an Freunde haengt an zwei Dingen, die nur in der Sitzung leben und nach /reload
-- erst durch die ANTWORT des Freundes auf das eigene Hallo wiederkommen: `peers` (Friends.Peers, wer bekommt den Ruf)
-- und `proven` (Friends.Vouch, wessen Ruf wird angenommen, wenn die Freundesliste eine GUID gibt und der Client den
-- Absender ohne Nachnamen nennt). Der Freund beantwortet ein Hallo desselben Absenders aber hoechstens alle 5 Minuten
-- (HELLO_PER_SENDER 300 s). Wer binnen 5 Minuten nach seinem letzten Hallo /reload macht, bekommt keine Antwort:
--  a) Absender nach /reload: Call.Send meldet "none" (ohne Gilde und Gruppe) bzw. laesst die Freunde still weg.
--  b) Empfaenger nach /reload (Liste mit GUID, Absender ohne Nachnamen): der Freund liest "gesendet", an kommt nichts.
-- Gemessen bis 1900 s nach dem /reload (kein neues Hallo kommt von selbst). Gegenprobe: /reload spaeter als 5 Minuten.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_05.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")

-- zwei Freunde ohne Gilde; `wer` macht nach `vorher` Sekunden /reload; danach ruft Berta zu den Zeiten `wann`
local function lauf(guids, wer, vorher)
  local W = H.welt({ "HELP_CALL" })
  _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
  W.guids = guids
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(vorher)
  if wer == "a" then a = H.relog(W, a); a.login() else b = H.relog(W, b); b.login() end
  local out, t = {}, 0
  for _, at in ipairs({ 60, 400, 1900 }) do
    W.run(at - t - 2); t = at
    local before = H.zaehle(a, "HELP_CALL")
    local ok, why = b.ns.Call.Send()
    W.run(2)
    out[#out + 1] = { at = at, sent = ok == true, why = ok ~= true and why or nil, got = H.zaehle(a, "HELP_CALL") - before }
  end
  return out
end
local function text(out)
  local s = {}
  for _, r in ipairs(out) do s[#s + 1] = r.at .. " s: " .. (r.sent and "gesendet" or ("nicht gesendet (" .. tostring(r.why) .. ")")) .. ", angekommen " .. r.got end
  return table.concat(s, " | ")
end
local function alle(out) for _, r in ipairs(out) do if not (r.sent and r.got == 1) then return false end end return true end

H.lauf("a) Absenderin Berta macht 100 s nach dem Login /reload: ihr Ruf erreicht den Freund", function()
  local out = lauf(false, "b", 100)
  H.erwartet("Ruf geht an den Freund und kommt an", alle(out), text(out))
end)
H.lauf("b) Empfaenger Anton macht 100 s nach dem Login /reload (Liste mit GUID): der Ruf der Freundin kommt an", function()
  local out = lauf(true, "a", 100)
  H.erwartet("Ruf kommt an", alle(out), text(out))
end)
H.lauf("Gegenprobe: /reload erst 400 s nach dem Login", function()
  local o1, o2 = lauf(false, "b", 400), lauf(true, "a", 400)
  H.erwartet("Absenderin: geht und kommt an", alle(o1), text(o1))
  H.erwartet("Empfaenger: kommt an", alle(o2), text(o2))
end)

H.fertig()
