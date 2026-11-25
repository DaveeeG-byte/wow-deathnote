-- 1.7.0 fix JL-6 (copy of the hunt's jl05, adapted to the new E4: both kills stand open, the poster chooses; "paid"
-- for the earlier one declines the later one).
-- jl05 (E4 "der erste gueltige Kill gewinnt"): zwei Schuetzen toeten nacheinander, der Auslober ist offline. Beim
-- Einloggen gewinnt, wessen C zuerst ankommt, nicht wer zuerst getoetet hat. Hier ist der erste Schuetze beim Hallo
-- des Auslobers offline; sein C kommt spaeter und wird mit "kein Kopfgeld" quittiert, obwohl der Anspruch des
-- zweiten noch offen (nicht bezahlt) ist.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Anton toetet zuerst, Dora spaeter, Doras C kommt zuerst an", function()
  local W = K.welt()
  local a, b = K.paar(W)
  local d = W.client("Dora", "Dorn", K.G, { fullSender = true }); d.login(); W.run(60)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  M.Advance(1000)
  K.toetet(d); W.run(10)
  local a2 = K.weg(W, a)
  M.Advance(3600)
  b2.login(); W.run(120)
  H.erwartet("Vorbedingung: Doras Anspruch offen", #K.claims(b2) == 1 and K.claims(b2)[1].by == "Dora Dorn" and K.claims(b2)[1].state == "open")
  a2.login(); W.run(60)
  local b3 = K.weg(W, b2); M.Advance(400); b3.login(); W.run(120)
  local xa, xd = K.earned(a2)[1] or {}, K.earned(d)[1] or {}
  local ca, cd
  for _, y in ipairs(K.claims(b3)) do if y.by == "Anton Wurst" then ca = y elseif y.by == "Dora Dorn" then cd = y end end
  H.erwartet("beide Kills offen", ca and cd and ca.state == "open" and cd.state == "open")
  H.erwartet("Anton: offen", xa.state == "open", xa.state)
  H.erwartet("Dora: offen", xd.state == "open", xd.state)
  H.erwartet("der Auslober bezahlt den frueheren", b3.ns.Feud.SetClaim(ca, "paid") == true)
  W.run(30)
  H.erwartet("Dora: von selbst abgelehnt, 'kein Kopfgeld'", cd.state == "declined" and xd.state == "gone", xd.state)
  H.erwartet("Anton: bezahlt", xa.state == "paid", xa.state)
end)

H.fertig()
