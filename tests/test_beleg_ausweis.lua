-- Finding: for J/A/E (and, as in 1.1.0, for K/M/X) only the first word of sender and char is
-- compared. If the sender arrives with a surname and the message carries a DIFFERENT surname,
-- it is still accepted: calling off someone else's call, calling in someone else's name,
-- filling a namesake's ten slots, driving up a target's call count alone.
-- (fix-1: taken into the suite; run "list without surnames" adjusted after the decision "bind on the first
-- valid contact", run "first name only" new.)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Gilde: Namensvetter mit anderem Nachnamen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local z = W.client("Zeuge", "Still", G)
  a.login(); z.login(); W.run(40)
  local P = z.ns.Guild.Proto
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "echt" })
  W.run(5)
  local h = z.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("Vorbedingung: Zeuge sieht die Freigabe von Anton Wurst", h and h.n == 1)
  -- "Anton Falsch" is a different char; the sender arrives WITH a surname
  H.gilde(z, P.EncodeCallOff("Opfer-Lamm", "Anton Wurst"), "Anton Falsch-Forever")
  H.erwartet("fremde Freigabe laesst sich nicht abblasen (Absender Anton Falsch, Feld Anton Wurst)",
    z.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil, "Ziel ist weg")
  H.gilde(z, P.EncodeHunt({ key = "Zweit-Opfer", display = "Zweit Opfer", t = time(), by = "Anton Wurst", why = "gefaelscht" }),
    "Anton Falsch-Forever")
  local h2 = z.ns.Guild.Hunt("Zweit-Opfer", "guild")
  H.erwartet("Freigabe im Namen eines anderen Chars wird verworfen", h2 == nil,
    h2 and ("angenommen als Freigabe von " .. tostring(h2.names[1])))
  H.gilde(z, P.EncodeBagged("Zweit-Opfer", "Anton Wurst", time()), "Anton Falsch-Forever")
  h2 = z.ns.Guild.Hunt("Zweit-Opfer", "guild")
  H.erwartet("erlegt im Namen eines anderen Chars wird verworfen", not h2 or (h2.bagged or 0) == 0)
end)

H.lauf("Gilde: ein Mitglied, zehn Freigaben auf EIN Ziel", function()
  local W = H.welt()
  local z = W.client("Zeuge", "Still", G)
  local b = W.client("Berta", "Senf", G)
  z.login(); b.login(); W.run(40)
  local P = z.ns.Guild.Proto
  -- (fix-1) sender with surname: foreign spellings do not belong to him and are dropped right away
  for i = 1, 10 do
    H.gilde(z, P.EncodeHunt({ key = "Opfer-Lamm", display = "Opfer Lamm", t = time(), by = "Berta Senf" .. i, why = "x" }),
      "Berta Senf-Forever")
  end
  local h = z.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("ein Absender zaehlt je Ziel hoechstens als eine Freigabe", not h or h.n <= 1, h and (h.n .. " Freigaben von einem Absender"))
  -- sender with first name only: every spelling fits the first name but counts only once (the last one wins)
  for i = 1, 10 do
    H.gilde(z, P.EncodeHunt({ key = "Zwei-Lamm", display = "Zwei Lamm", t = time(), by = "Berta Senf" .. i, why = "x" .. i }),
      "Berta-Forever")
  end
  h = z.ns.Guild.Hunt("Zwei-Lamm", "guild")
  H.erwartet("Absender ohne Nachnamen: je Ziel genau eine Freigabe", h and h.n == 1, h and (h.n .. " Freigaben von einem Absender"))
  H.erwartet("die letzte Schreibweise gilt", h and h.names[1] == "Berta Senf10", h and h.names[1])
end)

H.lauf("Gilde: Namensvetter belegt meine zehn Plaetze", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local x = W.client("Xaver", "Still", G)
  a.login(); x.login(); W.run(40)
  local P = a.ns.Guild.Proto
  for i = 1, 10 do
    H.gilde(a, P.EncodeHunt({ key = "Ziel" .. string.char(64 + i) .. "-Lamm", t = time(), by = "Anton Falsch", why = "" }),
      "Anton Falsch-Forever")
  end
  local g = a.ns.Guild.Release("Opfer-Lamm", { to = "guild" })
  H.erwartet("ich (Anton Wurst) kann trotz zehn Freigaben von Anton Falsch freigeben", g == true, tostring(g))
end)

H.lauf("Freunde: Liste ohne Nachnamen, Fremder mit gleichem Vornamen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  -- the first valid contact binds the full name provisionally to the friend "Berta"
  H.fluestern(a, P.EncodeHunt({ key = "Echt-Lamm", t = time(), by = "Berta Senf", why = "echt" }), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: die echte Berta wird angenommen", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  local before = a.ns.Friends.stats.received
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Berta Fremd", why = "Fremder" }), "Berta Fremd-Forever")
  H.erwartet("Nachricht des Fremden wird nicht angenommen", a.ns.Friends.stats.received == before
    and a.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil, "Freigabe eines Fremden steht im Freundesbuch")
  -- fix-2 (finding 1 of the final hunt): provisional binding -> conflict, the player chooses
  local h = a.ns.Friends.Health()
  H.erwartet("die Statuszeile nennt beide vollen Namen", h.reason == "conflict" and h.text:find("Berta Fremd", 1, true) ~= nil
    and h.text:find("Berta Senf", 1, true) ~= nil, h.reason .. ": " .. tostring(h.text))
  H.fluestern(a, P.EncodeHunt({ key = "Zwei-Lamm", t = time(), by = "Berta Senf", why = "echt" }), "Berta Senf-Forever")
  H.erwartet("im Konflikt nimmt das Buch von keinem etwas an", a.ns.Guild.Hunt("Zwei-Lamm", "friends") == nil)
  H.erwartet("die Daten der Gebundenen bleiben stehen", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  H.erwartet("Wahl im Buch: Das ist mein Freund", a.ns.Friends.Choose("Berta", "Berta Senf") == true)
  H.fluestern(a, P.EncodeHunt({ key = "Zwei-Lamm", t = time(), by = "Berta Senf", why = "echt" }), "Berta Senf-Forever")
  H.erwartet("nach der Wahl kommt die echte Berta durch", a.ns.Guild.Hunt("Zwei-Lamm", "friends") ~= nil)
  local n = a.ns.Friends.stats.strangers
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Berta Fremd", why = "Fremder" }), "Berta Fremd-Forever")
  H.erwartet("nach der Wahl ist der Fremde ein Fremder (Statuszeile nennt ihn)", a.ns.Friends.Health().reason == "impostor"
    and a.ns.Friends.Health().text:find("Berta Fremd", 1, true) ~= nil and a.ns.Friends.stats.strangers == n + 1)
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Berta Fremd", why = "Fremder" }), "Berta Fremd-Forever")
  H.erwartet("einmal genannt: der zweite Versuch aendert den Vermerk nicht", a.ns.Friends.stats.impostor.at <= M.now
    and a.ns.Friends.stats.strangers == n + 2)
  M.Advance(700)
  H.erwartet("der Vermerk verschwindet nach zehn Minuten", a.ns.Friends.Health().reason ~= "impostor", a.ns.Friends.Health().reason)
  -- after a restart the binding stays (saved)
  a.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(a.env.DeathNoteDB)
  a.loggedIn = false
  local a2 = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, db = db })
  a2.login(); W.run(40)
  H.fluestern(a2, P.EncodeHunt({ key = "Drei-Lamm", t = time(), by = "Berta Fremd", why = "Fremder" }), "Berta Fremd-Forever")
  H.erwartet("Bindung ueberlebt den Neustart", a2.ns.Guild.Hunt("Drei-Lamm", "friends") == nil)
end)

H.lauf("Freunde: Absender nur mit Vornamen kann nichts im Namen anderer tun", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Cora Kraut", why = "x" }), "Berta-Forever")
  H.erwartet("fremder Vorname im Feld wird verworfen", a.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil)
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Berta Senf", why = "x" }), "Berta-Forever")
  H.erwartet("eigener Vorname geht (nur Vorname bindet)", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  local pr = a.ns.Friends.Probe()
  H.erwartet("die Sonde vermerkt die Namensform", pr.senderForm == "first", tostring(pr.senderForm))
end)

H.lauf("Freunde: Liste MIT Nachnamen, Absender kommt ohne Nachnamen an (Form Name-Realm)", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  -- the stranger is called "Berta Fremd", the client reports him as "Berta-Forever"; the field holds his real name
  H.fluestern(a, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Berta Fremd", why = "Fremder" }), "Berta-Forever")
  local h = a.ns.Guild.Hunt("Opfer-Lamm", "friends")
  H.erwartet("Char-Feld mit anderem Nachnamen als der Freund auf der Liste wird verworfen", h == nil,
    h and ("angenommen von " .. tostring(h.names[1])))
end)

H.fertig()
