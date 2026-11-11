-- Funde im Mischbetrieb Gilde/Freunde:
-- (a) Ein Freund, der die Gilde verlassen hat, gilt weiter als Gildenkollege (members-Tabelle, 60 Tage):
--     sein Fluestern wird verworfen, er bekommt kein Hallo. (b) Nach dem eigenen Gildenaustritt
--     alarmiert die Abschussliste der alten Gilde weiter, obwohl die Ansicht sie nicht mehr zeigt.
-- (c) Ein einziger harter Fehlschlag beim ersten Fluestern sperrt alle Freunde fuer die Sitzung.
-- (d) Eine volle Antwort an einen Freund ist groesser als der Platz, auf den sie wartet.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Freund hat die Gilde verlassen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  H.tod(b, "Alt", "Feind"); W.run(5)          -- Anton hoert Berta auf GUILD
  b.guild = nil
  b.fire("PLAYER_GUILD_UPDATE"); W.run(2)
  M.Advance(400)                               -- Hallo-Abstand vorbei
  b.ns.Friends.SyncNow(); a.ns.Friends.SyncNow()
  W.run(60)
  local key = H.tod(b, "Grimm", "Bart")
  W.run(30)
  H.erwartet("Tat des Freunds (nicht mehr in der Gilde) kommt bei Anton an", a.ns.Guild.Get(key, "all") ~= nil,
    "nicht angekommen, als Gildenkollege verworfen: mates=" .. tostring(a.ns.Friends.stats.mates))
end)

H.lauf("Eigener Gildenaustritt: Abschussliste der alten Gilde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "guild" }); W.run(5)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "all") ~= nil)
  a.guild = nil
  a.fire("PLAYER_GUILD_UPDATE"); W.run(2)
  a.ns.Guild.OnUnit("Opfer-Lamm", "nameplate1", "plate", false)   -- erste Sichtung: Ansichten werden neu gebaut
  W.run(120)
  local shown = a.ns.Guild.Hunt("Opfer-Lamm", "all") ~= nil
  a.events = {}
  a.ns.Guild.OnUnit("Opfer-Lamm", "nameplate1", "plate", false)
  local alarm = H.zaehle(a, "GUILD_ENEMY_SPOTTED") > 0
  H.erwartet("Alarm und Ansicht sind sich einig (beide an oder beide aus)", shown == alarm,
    "Ansicht zeigt das Ziel: " .. tostring(shown) .. ", Alarm: " .. tostring(alarm))
end)

H.lauf("Ein harter Fehlschlag sperrt alle Freunde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Geist", "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  local g = W.client("Geist", "Fern", nil, { friends = {} })
  -- nur das Fluestern an "Geist" lehnt der Server hart ab (Code 4, z. B. Ziel nicht erreichbar)
  local CI = a.env.C_ChatInfo
  local send = CI.SendAddonMessage
  CI.SendAddonMessage = function(prefix, text, channel, target)
    if channel == "WHISPER" and target == "Geist" then return 4 end
    return send(prefix, text, channel, target)
  end
  a.login(); b.login(); g.login(); W.run(60)
  H.erwartet("ein abgelehntes Fluestern an EINEN Freund sperrt nicht alle", a.ns.Friends.Blocked() ~= true,
    "blocked nach " .. tostring(a.ns.Friends.stats.failStreak) .. " Fehlschlag")
  H.erwartet("Berta wurde trotzdem gefragt und antwortet", a.ns.Friends.PeerCount() == 1, "Peers: " .. a.ns.Friends.PeerCount())
end)

H.lauf("Volle Antwort gegen den Platz, auf den sie wartet", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local C, FC = a.ns.Guild.C, a.ns.Friends.C
  local full = C.REPLY_MAX + C.LISTED_REPLY + C.UNLISTED_REPLY + C.HUNT_REPLY + C.HUNTOFF_REPLY
  H.erwartet("REPLY_ROOM deckt eine volle Antwort (R+M+X+J+A)", FC.REPLY_ROOM >= full,
    "Antwort bis " .. full .. " Nachrichten, gewartet wird auf " .. FC.REPLY_ROOM .. " freie Plaetze")
end)

H.fertig()
