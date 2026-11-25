-- 1.7.0 fixer round 2 (copy of the hunt's jn01). jn01 (Nachjagd 1.7.0): Zuruecknehmen und sofort neu Ausloben mit kleinerem Betrag. Der Kill faellt in die
-- Uhren-Toleranz (CLAIM_SKEW, 5 Minuten) nach dem Zuruecknehmen, also "stand" fuer judge sowohl der Grabstein (100)
-- als auch das neue Kopfgeld (20). judge sortiert nach Gold absteigend und nimmt den Grabstein: der Anspruch lautet
-- auf 100 Gold (nie mehr ausgelobt, als der Kill fiel), der Schuetze bekommt 100 quittiert, und "Bezahlt" nimmt das
-- lebende Kopfgeld nicht zurueck (b zeigt auf das alte). Kommt derselbe Kill als V (Auslober online), haengt der
-- Anspruch am lebenden Kopfgeld (20): zwei Wege, zwei Ergebnisse.
-- Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("C-Weg: Auslober offline beim Kill", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 100); W.run(10)
  M.Advance(3600)
  H.erwartet("Vorbedingung: zurueckgenommen", b.ns.Guild.SetBounty(K.KEY, 0) == true)
  W.run(5)
  H.erwartet("Vorbedingung: neu ausgelobt mit 20", b.ns.Guild.SetBounty(K.KEY, 20) == true)
  W.run(10)
  local b2 = K.weg(W, b)
  M.Advance(60)
  K.toetet(a); W.run(10)
  local x = K.earned(a)[1] or {}
  H.erwartet("Vorbedingung: Anton hat 20 Gold verdient", x.g == 20 and x.state == "sent", tostring(x.g) .. "/" .. tostring(x.state))
  M.Advance(3600)
  b2.login(); W.run(200)
  local c = K.claims(b2)[1] or {}
  H.erwartet("Vorbedingung: ein Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Anspruch lautet auf das Kopfgeld, das beim Kill stand (20)", c.g == 20, c.g)
  H.erwartet("Anton bekommt 20 quittiert", x.g == 20, x.g)
  H.erwartet("Bezahlt wuerde das lebende Kopfgeld zuruecknehmen", b2.ns.Claim.WouldTake(c) == true)
  if c.key then b2.ns.Feud.SetClaim(c, "paid"); W.run(10) end
  H.erwartet("nach Bezahlt ist das Kopfgeld weg", b2.ns.Bounty.Own(K.KEY) == nil, b2.ns.Bounty.Own(K.KEY))
end)

H.lauf("V-Weg zum Vergleich: Auslober online", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 100); W.run(10)
  M.Advance(3600)
  b.ns.Guild.SetBounty(K.KEY, 0); W.run(5)
  b.ns.Guild.SetBounty(K.KEY, 20); W.run(10)
  M.Advance(60)
  K.toetet(a); W.run(10)
  local c = K.claims(b)[1] or {}
  H.erwartet("V: Anspruch auf 20", #K.claims(b) == 1 and c.g == 20, c.g)
end)

H.fertig()
