-- 1.2.1 nach der Abschluss-Jagd: (1) wartende Nachrichten altern nicht, solange eine lange Sperre dauert, auch wenn
-- zwischendurch Ereignisse die Schlange anstossen; (2) nach einer ueber 70 Minuten langen Sperre laeuft der Zeitgeber
-- bei einer zweiten Sperre wieder an; (3) eine vom Spieler gewaehlte Bindung verliert durch ein fremdes Hallo mit der
-- GUID der Liste nichts, auch nicht beim Aufraeumen danach; ihr eigenes Hallo klaert es.
-- Aufruf: nice -n 15 luajit beleg_d01_sperre_und_wahl.lua <Projektkopie>. Alle Namen erfunden.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M
local G = "Die Testgilde"
local function fluestern(c, text, from) c.fire("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from) end

H.lauf("(1) 40 min Chat-Sperre, alle 100 s ein Anstoss: die Freigabe vom Beginn kommt danach an", function()
  for _, takt in ipairs({ 45, 100 }) do
    local W = H.welt()
    local a = W.client("Anton", "Wurst", G, { fullSender = true })
    local b = W.client("Berta", "Senf", G, { fullSender = true })
    a.login(); b.login(); W.run(120)
    local sperre = true
    a.env.C_ChatInfo.InChatMessagingLockdown = function() return sperre end
    local d0 = a.ns.Guild.stats.dropped
    a.ns.Guild.Release("Ziel-Eins", { to = "guild", why = "x" })
    for _ = 1, 40 * 60 / takt do a.fire("PLAYER_REGEN_ENABLED"); W.run(takt) end
    sperre = false
    a.fire("PLAYER_REGEN_ENABLED"); W.run(120)
    H.erwartet("Takt " .. takt .. " s: nichts verworfen", a.ns.Guild.stats.dropped == d0, a.ns.Guild.stats.dropped - d0)
    H.erwartet("Takt " .. takt .. " s: Freigabe drueben", b.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil)
  end
end)

H.lauf("(2) nach 80 min Sperre: zweite Sperre mitten im Leeren, der Zeitgeber laeuft wieder an", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(120)
  local sperre = true
  a.env.C_ChatInfo.InChatMessagingLockdown = function() return sperre end
  for i = 1, 6 do M.epoch = M.epoch + 60; H.tod(a, "Taeter" .. string.char(96 + i), "Lamm"); W.run(5) end
  W.run(80 * 60)   -- der Zeitgeber hat aufgehoert (20 + 30 Runden)
  H.erwartet("Vorbedingung: alles wartet", a.ns.Guild.QueueSize() == 6, a.ns.Guild.QueueSize())
  sperre = false
  a.fire("PLAYER_REGEN_ENABLED"); W.run(0.2)   -- eine geht hinaus, dann wieder Sperre
  sperre = true
  W.run(120)
  local rest = a.ns.Guild.QueueSize()
  sperre = false   -- endet ohne Ereignis
  W.run(20 * 60)
  H.erwartet("Vorbedingung: beim zweiten Sperren wartete noch etwas", rest >= 1, rest)
  H.erwartet("20 min nach dem Ende der zweiten Sperre ist die Schlange leer", a.ns.Guild.QueueSize() == 0, a.ns.Guild.QueueSize())
  H.erwartet("alle 6 Taten drueben", b.ns.Guild.Count("guild") == 6, b.ns.Guild.Count("guild"))
end)

-- Lage wie ein Buch aus 1.2.0: Freundin "Berta" ohne Nachnamen auf der Liste, vom Spieler an "Berta Senf" gebunden,
-- ohne gemerkte Hallo-GUID. Die Liste nennt jetzt ihre GUID. Ein Namensvetter fluestert ein Hallo mit ihrer GUID.
H.lauf("(3) gewaehlte Bindung und ein Hallo mit gefaelschter GUID", function()
  local W = H.welt()
  W.guids = true
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, fullSender = true })
  local guids = false
  local gfi = a.env.C_FriendList.GetFriendInfoByIndex
  a.env.C_FriendList.GetFriendInfoByIndex = function(i) local f = gfi(i); if f and not guids then f.guid = nil end; return f end
  a.login(); b.login(); W.run(120)
  for i = 1, 12 do M.epoch = M.epoch + 3600; H.tod(b, "Taeter" .. string.char(96 + i), "Lamm"); W.run(5) end
  b.ns.Guild.Release("Ziel-Eins", { to = "friends", why = "x" }); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  tie.hg, tie.sure = nil, true
  local vorher = a.ns.Guild.Count("friends")
  local gb = W.guidOf(b)
  local bdb = H.raus(W, b)
  guids = true
  local b2 = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true, db = bdb })
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  fluestern(a, a.ns.Guild.Proto.EncodeHello(0, "1.2.1", gb), "Berta Fremd-Forever"); W.run(5)
  H.erwartet("Vorbedingung: 12 Taten", vorher == 12, vorher)
  H.erwartet("nach dem gefaelschten Hallo: alle Taten da", a.ns.Guild.Count("friends") == vorher, a.ns.Guild.Count("friends"))
  -- Aufraeumen beim naechsten Listen-Lauf (in 1.2.0 gingen die Daten hier)
  W.run(60); a.fire("FRIENDLIST_UPDATE"); W.run(10)
  H.erwartet("nach dem Aufraeumen: alle Taten da", a.ns.Guild.Count("friends") == vorher, a.ns.Guild.Count("friends"))
  H.erwartet("Freigabe bleibt", a.ns.Guild.Hunt("Ziel-Eins", "friends") ~= nil)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Bindung bleibt bei der Gewaehlten, der andere Name ist ein Konflikt", tie.full == "Berta Senf"
    and tie.rival == "Berta Fremd", tostring(tie.full) .. "/" .. tostring(tie.rival))
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("die Gewaehlte wird nicht als Fremde genannt", not (imp and imp.name == "Berta Senf"), imp and imp.name)
  -- ein zweites Hallo des Faelschers aendert nichts
  W.run(400); fluestern(a, a.ns.Guild.Proto.EncodeHello(0, "1.2.1", gb), "Berta Fremd-Forever"); W.run(5)
  H.erwartet("zweites gefaelschtes Hallo: alle Taten da", a.ns.Guild.Count("friends") == vorher, a.ns.Guild.Count("friends"))
  -- das eigene Hallo der echten Berta klaert es
  b2.login(); W.run(90)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("ihr Hallo beweist sie, der Konflikt ist weg", tie.full == "Berta Senf" and tie.guid == gb and tie.rival == nil,
    tostring(tie.full) .. "/" .. tostring(tie.guid) .. "/" .. tostring(tie.rival))
  H.erwartet("danach alle Taten da", a.ns.Guild.Count("friends") >= vorher, a.ns.Guild.Count("friends"))
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.fertig()
