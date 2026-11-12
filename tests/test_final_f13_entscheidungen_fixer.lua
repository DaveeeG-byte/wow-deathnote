-- The fixer's decisions checked against their purpose.
-- (1) Finding 12 "emptying the guild book also empties this source's hit list": the foreign calls come back
--     in full with the next sync (every answer carries up to 10 J). All that remains is "Hide".
-- (2) Finding 23 way 2: a friend who answered in this session and THEN joins my guild falls through both
--     branches of Friends.Broadcast for "friends only" calls (no whisper, no GUILD).
-- (4) Finding 22 (do not call your own people): without a known surname the first name is enough. An enemy who
--     killed me and has a guildmate's first name cannot be called ("one of you").
-- (3) Counter-check: own calls survive "Empty guild book" and "Empty friends' book", hidden entries stay.
-- (fix-2) Proof test of the final hunt, taken into the suite; head: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("(1) Leeren und der naechste Abgleich", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(60)
  b.ns.Guild.Release("Stoer-Enfried", { to = "guild", why = "stoerender Grund" })
  a.ns.Guild.Release("Mein-Ziel", { to = "guild" })
  W.run(10)
  H.erwartet("Vorbedingung: fremde Freigabe da", a.ns.Guild.Hunt("Stoer-Enfried", "guild") ~= nil)
  a.ns.Guild.Clear(); W.run(2)
  H.erwartet("nach dem Leeren: fremde Freigabe weg, eigene bleibt (Gegenprobe)",
    a.ns.Guild.Hunt("Stoer-Enfried", "guild") == nil and a.ns.Guild.Hunt("Mein-Ziel", "guild") ~= nil)
  -- next day, next login
  H.tage(1); W.run(900)                -- Berta stays online, her lock period per hello sender is over
  local a2 = H.relog(W, a); a2.login(); W.run(120)
  H.erwartet("geleerte fremde Freigabe bleibt weg (oder das Leeren sagt, dass sie wiederkommt)",
    a2.ns.Guild.Hunt("Stoer-Enfried", "guild") == nil, "nach dem naechsten Login wieder da, Alarm inklusive")
end)

H.lauf("(2) Freund antwortet, kommt dann in meine Gilde", function()
  local W = H.welt()
  -- fix-2 (decision on finding 6): guildmate only with full name; here the client gives the surnames
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); f.login(); W.run(90)
  H.erwartet("Vorbedingung: Fritz hat in dieser Sitzung geantwortet", a.ns.Friends.PeerCount() == 1, a.ns.Friends.PeerCount())
  f.guild = G; f.fire("PLAYER_GUILD_UPDATE"); a.fire("GUILD_ROSTER_UPDATE"); f.fire("GUILD_ROSTER_UPDATE"); W.run(20)
  W.run(60); f.ns.Guild.SyncNow(); W.run(30)     -- Fritz can be heard on GUILD right now (guildmate with DeathNote)
  H.erwartet("Vorbedingung: Fritz gilt als Kollege", a.ns.Guild.IsGuildmate("Fritz Frei") == true)
  a.ns.Guild.Release("Nur-Freunde", { to = "friends", why = "nur fuer Freunde" })
  W.run(60)
  H.erwartet("Freigabe nur fuer Freunde erreicht den Freund, der inzwischen Kollege ist",
    f.ns.Guild.Hunt("Nur-Freunde", "friends") ~= nil, "kam nicht an")
end)

H.lauf("(3) eigene Freigaben und Ausgeblendetes ueberstehen beide Leeren-Knoepfe", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" } })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" } })
  a.login(); f.login(); W.run(90)
  a.ns.Guild.Release("Mein-Ziel", { to = "all" })
  f.ns.Guild.Release("Fremd-Ziel", { to = "friends" })
  W.run(20)
  a.ns.Guild.HideHunt("Fremd-Ziel", true)
  a.ns.Guild.Clear(); a.ns.Friends.Clear(); W.run(2)
  local g, fr = a.ns.Guild.Released("Mein-Ziel")
  H.erwartet("eigene Freigabe in beiden Listen noch da", g and fr)
  H.erwartet("fremde Freigabe der Freunde weg", a.ns.Guild.Hunt("Fremd-Ziel", "friends") == nil)
  H.erwartet("ausgeblendet bleibt gemerkt", a.ns.Guild.HuntHidden("Fremd-Ziel") == true)
end)

H.lauf("(4) Feind mit dem Vornamen eines Kollegen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)          -- the client names her "Berta-Forever" (first name only)
  a.login(); b.login(); W.run(60)
  local key = H.tod(a, "Berta", "Meuchlerin")      -- an enemy of this name surely killed me
  W.run(5)
  local g, why = a.ns.Guild.Release(key, { to = "guild", why = "hat mich getoetet" })
  H.erwartet("ein Taeter aus dem eigenen Buch laesst sich freigeben, auch wenn ein Kollege so heisst", g == true,
    "abgelehnt mit Grund " .. tostring(why))
end)

H.fertig()
