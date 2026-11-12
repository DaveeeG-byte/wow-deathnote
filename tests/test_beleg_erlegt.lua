-- Finding: "taken down" (E) can be repeated by a single member any number of times.
-- The same message (with a t other than the newest) counts anew each time, two alternating times
-- trigger HUNT_BAGGED each time (one window per message), even with a t months old.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Erlegt per Wiederholung", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  local key = "Opfer-Lamm"
  a.ns.Guild.Release(key, { to = "guild", why = "Test" })
  W.run(5)
  local h = a.ns.Guild.Hunt(key, "guild")
  H.erwartet("Vorbedingung: Freigabe steht", h ~= nil)
  local now = time()
  -- Berta never killed anyone and reports anyway
  H.gilde(a, P.EncodeBagged(key, "Berta Senf", now), "Berta-Forever")
  for _ = 1, 40 do H.gilde(a, P.EncodeBagged(key, "Berta Senf", now - 500), "Berta-Forever") end
  h = a.ns.Guild.Hunt(key, "guild")
  H.erwartet("dieselbe E-Nachricht 40x zaehlt hoechstens einmal (Zaehler <= 2)", (h.bagged or 0) <= 2, "Zaehler " .. tostring(h.bagged))
  local before = H.zaehle(a, "HUNT_BAGGED")
  for i = 1, 20 do
    H.gilde(a, P.EncodeBagged(key, "Berta Senf", now - 1000 - (i % 2) * 400), "Berta-Forever")
  end
  local fired = H.zaehle(a, "HUNT_BAGGED") - before
  H.erwartet("20 E-Nachrichten mit zwei abwechselnden Zeiten: hoechstens 2 Meldungen", fired <= 2, fired .. " Meldungen")
end)

H.lauf("Erlegt mit altem Datum", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild" })
  W.run(5)
  local before = H.zaehle(a, "HUNT_BAGGED")
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", time() - 100 * 86400), "Berta-Forever")
  H.erwartet("E mit 100 Tage altem t loest keine Meldung aus (K hat dafuer FRESH)", H.zaehle(a, "HUNT_BAGGED") == before,
    "Meldung fuer eine 100 Tage alte Toetung")
end)

H.lauf("Flut: Zaehler bis zum Anschlag", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild" })
  W.run(5)
  local now = time()
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now), "Berta-Forever")
  for round = 1, 8 do
    for _ = 1, 140 do H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 3600), "Berta-Forever") end
    M.Advance(61)
  end
  local h = a.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("ein Mitglied treibt den Erlegt-Zaehler nicht auf 999", (h.bagged or 0) < 50, "Zaehler " .. tostring(h.bagged) .. " nach 8 Minuten")
end)

H.fertig()
