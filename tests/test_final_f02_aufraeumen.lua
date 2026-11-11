-- Gegenprobe Fund 1 (Aufraeumen der Freundesdaten).
-- (1) Pause von mehr als 60 Tagen: Battle.net-Freunde gelten beim ersten Aufraeumen nach dem Login als entfernt
--     (BN_KEEP zaehlt ab dem letzten Sehen, auch wenn ICH weg war), ihre Taten und Freigaben sind weg.
-- (2) Gegenprobe gruen: wirklich entfernter Charakter-Freund verschwindet nach 14 Tagen und drei Scans.
-- (3) Gegenprobe gruen: 13 Tage reichen nicht; Zweit-Char loescht nichts; leere Liste loescht nichts.
-- (4) Der eigene Char, der den Freund hatte, loggt nie wieder ein (geloescht, umbenannt): der entfernte Freund
--     bleibt fuer immer, seine Freigaben alarmieren weiter.
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

H.lauf("(1) 61 Tage Pause, Battle.net-Freund ist noch Freund", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login(); W.run(45)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
  local key = H.tod(b, "Grimm", "Bart")
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(60)
  H.erwartet("Vorbedingung: Tat und Freigabe der Battle.net-Freundin kamen an",
    a.ns.Guild.Get(key, "friends") ~= nil and a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  -- beide sind 61 Tage nicht im Spiel; die Freundschaft besteht weiter
  b.online = false
  H.tage(61)
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  a2.fire("BN_FRIEND_INFO_CHANGED"); W.run(5)     -- Freundin offline, steht aber weiter auf der Battle.net-Liste
  H.erwartet("Freigabe der Battle.net-Freundin ueberlebt meine Pause von 61 Tagen",
    a2.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil, "Freigabe geloescht")
  H.erwartet("Tat der Battle.net-Freundin ueberlebt meine Pause von 61 Tagen",
    a2.ns.Guild.Get(key, "friends") ~= nil, "Tat geloescht")
end)

-- fix-2 (Entscheidung zu Fund 2): die Frist zaehlt in eigenen Spieltagen (Tage mit Login), nicht in Kalendertagen
H.lauf("(2) wirklich entfernter Freund verschwindet nach 14 eigenen Spieltagen (Gegenprobe)", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(30)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  a.friendNames = { "Carla" }
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  local c = a
  local function spieltag()
    H.tage(1)
    c = H.relog(W, c, { friends = { "Carla" } }); c.login(); W.run(40)
    for _ = 1, 4 do c.fire("FRIENDLIST_UPDATE"); W.run(3) end
  end
  for _ = 1, 12 do spieltag() end
  H.erwartet("12 Spieltage nach dem Entfernen steht die Freigabe noch", c.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  H.tage(60)
  c = H.relog(W, c, { friends = { "Carla" } }); c.login(); W.run(40)
  for _ = 1, 4 do c.fire("FRIENDLIST_UPDATE"); W.run(3) end
  H.erwartet("eine lange eigene Pause zaehlt nur als ein Spieltag (13)", c.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  spieltag()
  H.erwartet("14 Spieltage nach dem Entfernen ist die Freigabe weg", c.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil, "steht noch")
end)

-- fix-2: ein Battle.net-Freund, der lange nicht im Spiel ist, aber auf der Battle.net-Liste steht, bleibt (BattleTag);
-- ohne BattleTag faellt er nach 60 eigenen Spieltagen ohne Sehen (Gegenprobe)
for _, tags in ipairs({ true, false }) do
  H.lauf("(1c) Battle.net-Freund 61 Spieltage offline, " .. (tags and "mit" or "ohne") .. " BattleTag", function()
    local W = H.welt()
    W.noTags = not tags
    local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
    local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
    a.login(); b.login(); W.run(45)
    a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
    b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
    W.run(60)
    H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
    b.online = false
    for _ = 1, 61 do H.tage(1); a.fire("BN_FRIEND_INFO_CHANGED"); W.run(3) end
    if tags then
      H.erwartet("auf der Battle.net-Liste: bleibt nach 61 Spieltagen", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
    else
      H.erwartet("ohne BattleTag: nach 60 Spieltagen ohne Sehen weg", a.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil)
    end
  end)
end

-- fix-2: ohne BattleTag (falls der Client keinen liefert) haelt die Frist in Spieltagen die Pause aus
H.lauf("(1b) 61 Tage Pause, Battle.net ohne BattleTag", function()
  local W = H.welt()
  W.noTags = true
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login(); W.run(45)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(60)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  b.online = false
  H.tage(61)
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  a2.fire("BN_FRIEND_INFO_CHANGED"); W.run(5)
  H.erwartet("Freigabe ueberlebt meine Pause auch ohne BattleTag", a2.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
end)

-- Seit 1.2.0 (Entscheidung zu den Spieltagen je Char): Spieltage anderer eigener Chars zaehlen nie gegen einen Char;
-- ein Char, der nicht mehr eingeloggt wird, verliert nichts. Seine Freunde bleiben, bis der Spieler das Freundesbuch leert.
H.lauf("(4) der eigene Char, der den Freund hatte, kommt nie wieder", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(30)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  -- Anton wird geloescht; der Account spielt nur noch mit Zweitchar weiter, der Berta nie auf der Liste hatte
  H.tage(1)
  local z = H.relog(W, a, { name = "Zweitchar", surname = "Wurst", friends = { "Carla" } })
  z.login(); W.run(40)
  for i = 1, 6 do
    H.tage(60)
    z = H.relog(W, z, { friends = { "Carla" } }); z.login(); W.run(40)
    for _ = 1, 4 do z.fire("FRIENDLIST_UPDATE"); W.run(3) end
  end
  H.erwartet("ein Jahr spaeter steht die Freigabe noch (Spieltage des Zweitchars zaehlen nicht gegen den anderen Char)",
    z.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil, "geloescht")
end)

H.fertig()
