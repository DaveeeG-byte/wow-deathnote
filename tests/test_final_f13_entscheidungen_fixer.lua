-- Entscheidungen des Fixers gegen den Zweck geprueft.
-- (1) Fund 12 "Gildenbuch leeren leert auch die Abschussliste dieser Quelle": die fremden Freigaben kommen mit dem
--     naechsten Abgleich vollstaendig zurueck (jede Antwort traegt bis zu 10 J). Was bleibt, ist nur "Ausblenden".
-- (2) Fund 23 Weg 2: ein Freund, der in dieser Sitzung geantwortet hat und DANN in meine Gilde kommt, faellt bei
--     Freigaben "nur fuer Freunde" durch beide Zweige von Friends.Broadcast (kein Flüstern, kein GUILD).
-- (4) Fund 22 (eigene Leute nicht freigeben): ohne bekannten Nachnamen reicht der Vorname. Ein Feind, der mich
--     getoetet hat und den Vornamen eines Kollegen traegt, laesst sich nicht freigeben ("einer von euch").
-- (3) Gegenprobe: eigene Freigaben ueberstehen "Gildenbuch leeren" und "Freundesbuch leeren", Ausgeblendetes bleibt.
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
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
  -- naechster Tag, naechster Login
  H.tage(1); W.run(900)                -- Berta bleibt online, ihre Sperrfrist je Hallo-Absender ist vorbei
  local a2 = H.relog(W, a); a2.login(); W.run(120)
  H.erwartet("geleerte fremde Freigabe bleibt weg (oder das Leeren sagt, dass sie wiederkommt)",
    a2.ns.Guild.Hunt("Stoer-Enfried", "guild") == nil, "nach dem naechsten Login wieder da, Alarm inklusive")
end)

H.lauf("(2) Freund antwortet, kommt dann in meine Gilde", function()
  local W = H.welt()
  -- fix-2 (Entscheidung zu Fund 6): Kollege nur mit vollem Namen; hier nennt der Client die Nachnamen mit
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); f.login(); W.run(90)
  H.erwartet("Vorbedingung: Fritz hat in dieser Sitzung geantwortet", a.ns.Friends.PeerCount() == 1, a.ns.Friends.PeerCount())
  f.guild = G; f.fire("PLAYER_GUILD_UPDATE"); a.fire("GUILD_ROSTER_UPDATE"); f.fire("GUILD_ROSTER_UPDATE"); W.run(20)
  W.run(60); f.ns.Guild.SyncNow(); W.run(30)     -- Fritz ist gerade auf GUILD zu hoeren (Kollege mit DeathNote)
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
  local b = W.client("Berta", "Senf", G)          -- der Client nennt sie als "Berta-Forever" (nur Vorname)
  a.login(); b.login(); W.run(60)
  local key = H.tod(a, "Berta", "Meuchlerin")      -- ein Feind dieses Namens hat mich sicher getoetet
  W.run(5)
  local g, why = a.ns.Guild.Release(key, { to = "guild", why = "hat mich getoetet" })
  H.erwartet("ein Taeter aus dem eigenen Buch laesst sich freigeben, auch wenn ein Kollege so heisst", g == true,
    "abgelehnt mit Grund " .. tostring(why))
end)

H.fertig()
