-- Gegenprobe Fund 6 (Tempo-Deckel fuer Freigaben) und Fund 2 (Erlegt).
-- (1) Der Live-Deckel (5 neue Freigaben je Absender in 10 Minuten) gilt nicht im "Antwortfenster" von 60 s nach
--     einem Hallo auf GUILD. Das Fenster oeffnet JEDES Hallo, auch das des Absenders selbst: Hallo, zehn Freigaben,
--     zehn Abblasen, Hallo, zehn neue ... So laufen wieder Dutzende Ziele in einer Minute ueber die Liste aller,
--     jedes loest in Sichtweite den Alarm aus.
-- (2) Erlegt: ein Absender kann ohne jede Toetung dauerhaft 3 Fenster je 10 Minuten bei allen ausloesen und den
--     Zaehler eines Ziels in einigen Stunden auf den Deckel treiben (Pruefung, was der Deckel wirklich haelt).
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("(1) eigenes Hallo oeffnet das Antwortfenster", function()
  local W = H.welt({ "GUILD_ENEMY_SPOTTED", "HUNT_NEW", "GUILD_UPDATED" })
  local z = W.client("Zeuge", "Still", G)
  local b = W.client("Berta", "Senf", G)
  z.login(); b.login(); W.run(120)        -- das Fenster nach den Login-Hallos ist vorbei
  local P = z.ns.Guild.Proto
  local from = "Berta-Forever"
  local gesehen, max = {}, 0
  local function zaehle()
    local n = 0
    for _, r in ipairs(z.ns.Guild.Hunts("guild")) do n = n + 1; gesehen[r.key] = true end
    if n > max then max = n end
  end
  -- Gegenprobe ohne Hallo: der Live-Deckel haelt
  for i = 1, 10 do
    H.gilde(z, P.EncodeHunt({ key = "Vor" .. string.char(64 + i) .. "-Lamm", t = time(), by = "Berta Senf", why = "" }), from)
  end
  zaehle()
  local ohne = 0
  for _ in pairs(gesehen) do ohne = ohne + 1 end
  H.erwartet("Gegenprobe: ohne Hallo nimmt der Zeuge hoechstens 5 neue Freigaben live", ohne <= 5, ohne)
  for i = 1, 10 do H.gilde(z, P.EncodeCallOff("Vor" .. string.char(64 + i) .. "-Lamm", "Berta Senf"), from) end
  -- jetzt mit eigenem Hallo vor jedem Schub, 7 Schuebe in 35 Sekunden
  gesehen = {}
  for runde = 1, 7 do
    H.gilde(z, P.EncodeHello(0, "1.2.0"), from)
    for i = 1, 10 do
      local key = "Ziel" .. string.char(64 + runde) .. string.char(64 + i) .. "-Lamm"
      H.gilde(z, P.EncodeHunt({ key = key, t = time(), by = "Berta Senf", why = "" }), from)
    end
    zaehle()
    for i = 1, 10 do
      local key = "Ziel" .. string.char(64 + runde) .. string.char(64 + i) .. "-Lamm"
      H.gilde(z, P.EncodeCallOff(key, "Berta Senf"), from)
    end
    W.run(5)
  end
  local n = 0
  for _ in pairs(gesehen) do n = n + 1 end
  H.erwartet("in 35 Sekunden laufen hoechstens 5 (Live-Deckel) plus 10 (eine Antwort) neue Ziele eines Absenders ueber die Liste",
    n <= 15, n .. " verschiedene Ziele von einem Absender in 35 s")
end)

H.lauf("(2) Erlegt ohne Toetung: was haelt der Deckel", function()
  local W = H.welt({ "HUNT_BAGGED" })
  local z = W.client("Zeuge", "Still", G)
  local b = W.client("Berta", "Senf", G)
  z.login(); b.login(); W.run(60)
  local P = z.ns.Guild.Proto
  z.ns.Guild.Release("Opfer-Lamm", { to = "guild" })
  W.run(5)
  local from = "Berta-Forever"
  -- eine Stunde lang, alle 20 Sekunden eine erfundene Toetung mit frischer Zeit
  for _ = 1, 180 do
    H.gilde(z, P.EncodeBagged("Opfer-Lamm", "Berta Senf", time()), from)
    W.run(20)
  end
  local fenster = H.zaehle(z, "HUNT_BAGGED")
  local h = z.ns.Guild.Hunt("Opfer-Lamm", "guild")
  io.write(("  gemessen: %d Erlegt-Meldungen in einer Stunde von einem Absender, Zaehler %d\n"):format(fenster, h and h.bagged or -1))
  H.erwartet("der Deckel haelt: hoechstens 3 je 10 Minuten", fenster <= 18 + 3, fenster)
end)

H.fertig()
