-- 1.7.0 fixer round 2 (copy of the hunt's jn07). jn07 (Nachjagd 1.7.0, Fixer-Diff Bounty.lua applyV + Claim.EndedOn / stood): die Uhren-Toleranz (CLAIM_SKEW, 300 s)
-- gilt auch am ENDE eines Kopfgelds. Berta nimmt ihr Kopfgeld zurueck, alle hoeren es sofort. Drei Minuten spaeter
-- erlegt Anton das Ziel (auf dem noch Carls Kopfgeld liegt, deshalb geht ein V hinaus). Bertas Buch legt aus dem V
-- einen Anspruch auf das zurueckgenommene Kopfgeld an: Chatzeile und Zettel "Kopfgeld faellig", 40 Gold. Anton selbst
-- hat fuer Berta keinen Eintrag (sein Buch kannte ihr Kopfgeld beim Kill nicht mehr), die Quittung "offen" laeuft bei
-- ihm ins Leere. Vor dem Fix entstand hier kein Anspruch.
-- Erwartet: ein Kill NACH dem Zuruecknehmen (gleiche Uhren, der Schuetze kannte das Kopfgeld nicht mehr) ist kein
-- Anspruch. Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Kill drei Minuten nach dem Zuruecknehmen", function()
  local W = K.welt()
  local a, b = K.paar(W)
  local c = W.client("Carl", "Kraut", K.G, { fullSender = true }); c.login(); W.run(60)
  b.ns.Guild.SetBounty(K.KEY, 40); c.ns.Guild.SetBounty(K.KEY, 5); W.run(20)
  M.Advance(3600)
  H.erwartet("Vorbedingung: Berta nimmt zurueck", b.ns.Guild.SetBounty(K.KEY, 0) == true)
  W.run(20)
  M.Advance(160)
  K.toetet(a); W.run(20)
  local fuerBerta = 0
  for _, x in ipairs(K.earned(a)) do if x.owner == "Berta Senf" then fuerBerta = fuerBerta + 1 end end
  H.erwartet("Vorbedingung: Anton hat nur Carls Kopfgeld verdient", fuerBerta == 0 and #K.earned(a) == 1, #K.earned(a))
  H.erwartet("Vorbedingung: Carl hat seinen Anspruch", #K.claims(c) == 1, #K.claims(c))
  H.erwartet("Berta: kein Anspruch auf das zurueckgenommene Kopfgeld", #K.claims(b) == 0,
    #K.claims(b) .. " Anspruch, g=" .. tostring((K.claims(b)[1] or {}).g))
  H.erwartet("Berta: kein CLAIM_NEW (Zettel 'Kopfgeld faellig')", H.zaehle(b, "CLAIM_NEW") == 0, H.zaehle(b, "CLAIM_NEW"))
end)

H.lauf("Grenze END_SKEW: 30 s nach dem Zuruecknehmen zaehlt, 90 s nicht; am Anfang bleiben 300 s", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local t0 = K.bountyT(b, K.KEY)
  M.Advance(3600)
  b.ns.Guild.SetBounty(K.KEY, 0); W.run(1)
  local e = time()
  M.Advance(120)
  local P = b.ns.Guild.Proto
  H.gilde(b, P.EncodeClaim(K.KEY, "Dora Dorn", e + 90, "Berta Senf", 40), "Dora Dorn-Forever")
  H.gilde(b, P.EncodeClaim(K.KEY, "Emil Eich", e + 30, "Berta Senf", 40), "Emil Eich-Forever")
  H.gilde(b, P.EncodeClaim(K.KEY, "Fritz Frei", t0 - 200, "Berta Senf", 40), "Fritz Frei-Forever")
  W.run(5)
  local by = {}
  for _, y in ipairs(K.claims(b)) do by[y.by] = true end
  H.erwartet("30 s danach: Anspruch", by["Emil Eich"] == true)
  H.erwartet("90 s danach: keiner", by["Dora Dorn"] == nil)
  H.erwartet("200 s vor dem Ausloben (Uhren): Anspruch", by["Fritz Frei"] == true)
end)

H.fertig()
