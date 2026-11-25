-- 1.7.0 fix JL-3, JL-4 (copy of the hunt's jl03; run (b) adapted to the new E4: two open, paid declines the other). jl03: Der Auslober aendert den Betrag seines Kopfgelds. X.Set schreibt dabei einen neuen Zeitpunkt (r.t = jetzt),
-- und der Zeitpunkt ist die Identitaet des Kopfgelds (E4).
-- (a) Kill geschah, als der Auslober offline war; er kommt, erhoeht den Betrag, bevor das C da ist: judge sagt
--     "early" (Kill vor dem Ausloben), der Schuetze bekommt Zustand 3 "kein Kopfgeld". Anspruch verloren.
-- (b) Anspruch ist offen, der Auslober erhoeht: "Bezahlt" nimmt das Kopfgeld nicht mehr zurueck, und ein zweiter
--     Schuetze bekommt einen zweiten Anspruch auf dasselbe Ziel.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("(a) erhoeht, bevor das C ankommt", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  M.Advance(3600)
  b2.login(); W.run(1)
  H.erwartet("Vorbedingung: Betrag erhoeht", b2.ns.Guild.SetBounty(K.KEY, 80) == true)
  W.run(120)
  local x = K.earned(a)[1] or {}
  H.erwartet("Berta hat den Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Anton: nicht 'kein Kopfgeld'", x.state ~= "gone", x.state)
end)

H.lauf("(b) erhoeht bei offenem Anspruch", function()
  local W = K.welt()
  local a, b = K.paar(W)
  local d = W.client("Dora", "Dorn", K.G, { fullSender = true }); d.login(); W.run(60)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  K.toetet(a); W.run(10)
  local ca = K.claims(b)[1]
  H.erwartet("Vorbedingung: Antons Anspruch offen", ca and ca.state == "open")
  M.Advance(1000)
  b.ns.Guild.SetBounty(K.KEY, 80); W.run(10)
  M.Advance(1000)
  K.toetet(d); W.run(10)
  -- 1.7.0 fixer, new E4: Dora's later kill is a second open claim on the SAME bounty (same b despite the new amount);
  -- "paid" for Anton declines it
  local n, cd = 0, nil
  for _, y in ipairs(K.claims(b)) do if y.state == "open" then n = n + 1 end; if y.by == "Dora Dorn" then cd = y end end
  H.erwartet("zwei offene Ansprueche auf dasselbe Kopfgeld", n == 2 and cd and cd.b == ca.b, n)
  H.erwartet("bezahlt", b.ns.Feud.SetClaim(ca, "paid") == true)
  W.run(10)
  H.erwartet("Doras Anspruch abgelehnt", cd and cd.state == "declined")
  H.erwartet("Bezahlt nimmt das Kopfgeld zurueck", b.ns.Bounty.Own(K.KEY) == nil, b.ns.Bounty.Own(K.KEY))
end)

H.fertig()
