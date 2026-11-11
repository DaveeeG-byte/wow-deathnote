-- Funde an der gemeinsamen Sendeschlange:
-- (a) Gleichlautende Nachrichten werden in der Schlange entdoppelt. Wartet die Schlange (Kampf,
--     Instanz, Drossel) und man gibt frei, blaest ab, gibt wieder frei, blaest wieder ab, faellt das
--     zweite A weg: beim Kollegen bleibt das Ziel freigegeben, bei mir ist es weg.
-- (b) Ein Freund steht auf der Freundesliste (mit Nachnamen oder Realm) UND als Battle.net-Freund
--     (nur Vorname): er wird als zwei Freunde gefuehrt und bekommt alles doppelt.
-- (c) Kommt ein Freund online, waehrend die Schlange voll ist, geht das Hallo verloren und wird in
--     der Sitzung nicht nachgeholt (helloAt/helloSent sind schon verbucht).
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Freigeben, abblasen, freigeben, abblasen bei wartender Schlange", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  a.combat = true
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "eins" }); M.Advance(2)
  a.ns.Guild.CallOff("Opfer-Lamm"); M.Advance(2)
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "zwei" }); M.Advance(2)
  a.ns.Guild.CallOff("Opfer-Lamm"); M.Advance(2)
  a.combat = false
  a.fire("PLAYER_REGEN_ENABLED")
  W.run(60)
  local mine = a.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil
  local theirs = b.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil
  H.erwartet("beide Seiten gleich: bei mir abgeblasen, beim Kollegen auch", mine == theirs,
    "bei mir: " .. tostring(mine) .. ", beim Kollegen: " .. tostring(theirs))
end)

H.lauf("Freund auf Freundesliste und Battle.net unter zwei Namensformen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" }, bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, bn = { "Anton" } })
  a.login(); b.login(); W.run(60)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(60)
  local _, total = a.ns.Friends.OnlineCount()
  H.erwartet("ein Mensch ist ein Freund (Freundesliste zaehlt 1)", total == 1, total .. " Freunde gezaehlt")
  local n0 = #W.sent
  H.tod(a, "Grimm", "Bart"); W.run(10)
  local k = 0
  for i = n0 + 1, #W.sent do if W.sent[i].sender == a and W.sent[i].text:match("^1\tK\t") then k = k + 1 end end
  H.erwartet("eine Tat geht genau einmal an den Freund", k == 1, k .. " K-Nachrichten")
end)

H.lauf("Freund kommt online, waehrend die Schlange voll ist", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = {} })     -- Berta fragt nicht selbst (hat Anton noch nicht)
  a.login(); W.run(45)
  a.combat = true
  for i = 1, a.ns.Guild.C.QUEUE_MAX do
    H.tod(a, "Feind" .. string.char(65 + i % 26) .. string.char(65 + math.floor(i / 26)), "Bart")
  end
  H.erwartet("Vorbedingung: Schlange voll", a.ns.Guild.QueueRoom() == 0, a.ns.Guild.QueueRoom())
  b.login()                         -- Freund kommt online
  W.run(45)                         -- sein Hallo waere jetzt faellig
  a.combat = false
  a.fire("PLAYER_REGEN_ENABLED")
  W.run(120)
  b.friendNames = { "Anton" }; b.fire("FRIENDLIST_UPDATE")
  W.run(200)
  local hellos = 0
  for _, m in ipairs(W.sent) do if m.sender == a and m.channel == "WHISPER" and m.text:match("^1\tH\t") then hellos = hellos + 1 end end
  H.erwartet("das Hallo an den Freund wird nachgeholt, sobald die Schlange Platz hat", hellos >= 1, hellos .. " Hallo an Berta")
end)

H.fertig()
