-- Findings in mixed guild/friends use:
-- (a) A friend who left the guild still counts as a guildmate (members table, 60 days):
--     his whisper is dropped, he gets no hello. (b) After leaving the guild yourself
--     the old guild's hit list keeps alerting although the view no longer shows it.
-- (c) A single hard failure on the first whisper blocks all friends for the session.
-- (d) A full answer to a friend is larger than the room it waits for.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Freund hat die Gilde verlassen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  H.tod(b, "Alt", "Feind"); W.run(5)          -- Anton hears Berta on GUILD
  b.guild = nil
  b.fire("PLAYER_GUILD_UPDATE"); W.run(2)
  M.Advance(400)                               -- hello gap over
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
  a.ns.Guild.OnUnit("Opfer-Lamm", "nameplate1", "plate", false)   -- first sighting: views are rebuilt
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
  -- only the whisper to "Geist" is refused hard by the server (code 4, e.g. target unreachable)
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
