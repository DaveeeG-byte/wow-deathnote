-- 1.7.0 fix JL-5 (copy of the hunt's jl04, plus taking back after the kill). jl04: Kopfgeld mit Verfall (guild.huntExpire = 30 Tage). Der Kill faellt in die Laufzeit (Tag 29), der Auslober ist
-- offline und kommt an Tag 31. Sein Start raeumt das verfallene Kopfgeld weg (Bounty.lua expire), danach kommt das C:
-- judge findet kein Kopfgeld und quittiert Zustand 3. Der Schuetze hat innerhalb der Laufzeit getoetet und verliert
-- den Anspruch. (Dasselbe ohne Aufraeumen: judge prueft den Verfall gegen jetzt statt gegen die Kill-Zeit.)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Kill an Tag 29, Auslober kommt an Tag 31", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.env.DeathNoteDB.settings.guild.huntExpire = 30
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  H.tage(29)
  local a2 = K.weg(W, a); a2.login(); W.run(60)
  H.erwartet("Vorbedingung: Anton kennt das Kopfgeld noch", a2.ns.Guild.HasBounty(K.KEY) == true)
  K.toetet(a2); W.run(10)
  H.erwartet("Vorbedingung: Eintrag sent", (K.earned(a2)[1] or {}).state == "sent")
  H.tage(2)
  b2.login(); W.run(120)
  H.erwartet("Vorbedingung: C kam", #K.msgs(W, "C", a2) == 1, #K.msgs(W, "C", a2))
  H.erwartet("Berta hat den Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Anton: nicht 'kein Kopfgeld'", (K.earned(a2)[1] or {}).state ~= "gone", (K.earned(a2)[1] or {}).state)
end)

H.lauf("Zurueckgenommen nach dem Kill, bevor das C kommt (Entscheidung: zaehlt wie der Verfall)", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  M.Advance(3600)
  b2.login(); W.run(1)
  H.erwartet("Vorbedingung: zurueckgenommen", b2.ns.Guild.SetBounty(K.KEY, 0) == true)
  W.run(120)
  local c = K.claims(b2)[1] or {}
  H.erwartet("Anspruch auf das Kopfgeld, das beim Kill stand", #K.claims(b2) == 1 and c.g == 40 and c.state == "open", #K.claims(b2))
  H.erwartet("Anton: offen", (K.earned(a)[1] or {}).state == "open", (K.earned(a)[1] or {}).state)
  H.erwartet("Bezahlt nimmt nichts mehr zurueck", b2.ns.Claim.WouldTake(c) == false)
  -- a kill after the taking back is no claim
  local P = b2.ns.Guild.Proto
  M.Advance(600)
  H.gilde(b2, P.EncodeClaim(K.KEY, "Dora Dorn", time() - 10, "Berta Senf", 40), "Dora Dorn-Forever")
  W.run(5)
  H.erwartet("Kill nach dem Zuruecknehmen: kein Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Grabstein liegt", #(b2.env.DeathNoteDB.bountyEnded or {}) == 1)
end)

H.fertig()
