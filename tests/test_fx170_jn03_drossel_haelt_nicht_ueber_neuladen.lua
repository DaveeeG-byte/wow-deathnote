-- 1.7.0 fixer round 2 (copy of the hunt's jn03). jn03 (Nachjagd 1.7.0): die Drossel des selbst nachgereichten C (CLAIM_RESEND 600 s je Eintrag, RESEND_MAX 12 je
-- Sitzung, "offen nur einmal je Sitzung", "bestaetigt: gar nicht") liegt nur in Tabellen der Sitzung (Claim.lua
-- resent, confirmed, heardAt). Jedes Neuladen (/reload, Zonen-Absturz, Relog) setzt sie zurueck: jeder wartende
-- Eintrag geht beim ersten Lebenszeichen des Auslobers sofort wieder auf den Gildenkanal.
-- Auslober mit 1.6.4 (quittiert nie; hier: seine Nachrichten werden eingespielt, er antwortet nie): der Eintrag
-- bleibt 30 Tage "unbestaetigt".
-- Erwartet: ein Eintrag geht in 10 Minuten hoechstens zweimal (1x nach 90 s, 1x Drossel), auch ueber Neuladen.
-- Zweiter Lauf: Zaehlung fuer eine Stunde ohne Neuladen (nur Ausgabe, Grenze 6 je Eintrag und Stunde plus das eine
-- nach 90 s). Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

local function hoert(a, t)
  local P = a.ns.Guild.Proto
  H.gilde(a, P.EncodeBounty(K.KEY, "Berta Senf", 40, t, nil), "Berta Senf-Forever")
end

H.lauf("fuenfmal neu geladen in zehn Minuten", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", K.G, { fullSender = true })
  local o = W.client("Otto", "Ohr", K.G, { fullSender = true })
  a.login(); o.login(); W.run(90)
  local t0 = time()
  hoert(a, t0); W.run(5)
  H.erwartet("Vorbedingung: Anton kennt das Kopfgeld", a.ns.Guild.HasBounty(K.KEY) == true)
  K.toetet(a); W.run(100)
  hoert(a, t0); W.run(5)
  local n0 = #K.msgs(W, "C")
  H.erwartet("Vorbedingung: unbestaetigt, C ging", (K.earned(a)[1] or {}).state == "sent" and n0 >= 1, n0)
  local start = time()
  for _ = 1, 5 do
    a = K.weg(W, a); a.login(); W.run(95)
    hoert(a, t0); W.run(5)
  end
  local n = #K.msgs(W, "C")
  io.write(("  gemessen: %d C fuer EINEN Eintrag in %d s (vor dem Neuladen %d, danach %d)\n"):format(n, time() - start + 105, n0, n - n0))
  H.erwartet("ein Eintrag: hoechstens 2 C in zehn Minuten", n <= 2, n)
end)

H.lauf("Zaehlung: eine Stunde, Auslober meldet sich alle 30 s, zwei Eintraege", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", K.G, { fullSender = true })
  local o = W.client("Otto", "Ohr", K.G, { fullSender = true })
  a.login(); o.login(); W.run(90)
  local t0 = time()
  local P = a.ns.Guild.Proto
  hoert(a, t0)
  H.gilde(a, P.EncodeBounty(K.KEY2, "Berta Senf", 40, t0, nil), "Berta Senf-Forever"); W.run(5)
  K.toetet(a); K.toetet(a, K.GUID2); W.run(5)
  H.erwartet("Vorbedingung: zwei Eintraege", #K.earned(a) == 2, #K.earned(a))
  for _ = 1, 120 do hoert(a, t0); W.run(30) end
  local n = #K.msgs(W, "C")
  io.write(("  gemessen: %d C fuer zwei Eintraege in einer Stunde ohne Neuladen\n"):format(n))
  H.erwartet("Grenze ohne Neuladen: 2 x (6 + 1)", n <= 14, n)
end)

H.lauf("(fixer) Eintrag aelter als ein Tag: hoechstens alle 4 Stunden, auch mit Neuladen jede Stunde", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", K.G, { fullSender = true })
  local o = W.client("Otto", "Ohr", K.G, { fullSender = true })
  a.login(); o.login(); W.run(90)
  local t0 = time()
  hoert(a, t0); W.run(5)
  K.toetet(a); W.run(100)
  H.tage(2)
  local n0 = #K.msgs(W, "C")
  for h = 1, 10 do
    a = K.weg(W, a); a.login(); W.run(60)
    for _ = 1, 10 do hoert(a, t0); W.run(30); M.Advance(300) end
  end
  local n = #K.msgs(W, "C") - n0
  io.write(("  gemessen: %d C in 10 Stunden fuer einen zwei Tage alten Eintrag\n"):format(n))
  H.erwartet("hoechstens 3 C in 10 Stunden (0, 4, 8 h)", n >= 1 and n <= 3, n)
  local x = K.earned(a)[1] or {}
  H.erwartet("Drossel am Eintrag gespeichert", type(x.c) == "number" and type(x.cn) == "number" and type(x.cd) == "number")
end)

H.fertig()
