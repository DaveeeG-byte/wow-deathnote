-- 1.7.0 fixer round 2 (copy of the hunt's jn02). jn02 (Nachjagd 1.7.0): "ein Kopfgeld, ein bezahlter Anspruch" haengt allein am bezahlten Eintrag in
-- DeathNoteDB.claims. Der Grabstein des bezahlten Kopfgelds weiss nicht, dass es bezahlt ist, und lebt laenger
-- (30 Tage ab ENDE) als der Anspruch (30 Tage ab KILL) bzw. ueberlebt den Deckel, an dem seit JL-9 erledigte
-- Ansprueche ZUERST fliegen.
-- (a) Alter: Kill Tag 0, bezahlt Tag 20, Anspruch faellt an Tag 31 aus der Liste. Ein zweiter Schuetze (Kill Tag 19,
--     danach offline) reicht an Tag 32 nach: neuer offener Anspruch "Kopfgeld faellig" auf ein bezahltes Kopfgeld.
-- (b) Deckel: 50 offene Ansprueche auf ein anderes Ziel schieben den bezahlten hinaus; danach dasselbe.
-- Erwartet: Zustand 3 (kein Kopfgeld), kein neuer Anspruch. Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

local function auf(c, key)
  local n = 0
  for _, y in ipairs(K.claims(c)) do if y.key == key and y.state == "open" then n = n + 1 end end
  return n
end

H.lauf("(a) der bezahlte Anspruch altert vor dem Grabstein", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  K.toetet(a); W.run(10)
  local ca = K.claims(b)[1]
  H.erwartet("Vorbedingung: Antons Anspruch", ca and ca.state == "open")
  H.tage(19)
  local tDora = time()
  H.tage(1)
  H.erwartet("Vorbedingung: bezahlt an Tag 20", b.ns.Feud.SetClaim(ca, "paid") == true)
  W.run(10)
  H.erwartet("Vorbedingung: Kopfgeld zurueckgenommen", b.ns.Bounty.Own(K.KEY) == nil)
  local P = b.ns.Guild.Proto
  -- Gegenprobe am selben Tag: der zweite Schuetze bekommt "kein Kopfgeld"
  H.gilde(b, P.EncodeClaim(K.KEY, "Emil Eich", tDora + 100, "Berta Senf", 40), "Emil Eich-Forever"); W.run(5)
  H.erwartet("Gegenprobe Tag 20: kein Anspruch fuer den zweiten", auf(b, K.KEY) == 0, auf(b, K.KEY))
  local b2 = K.weg(W, b)
  H.tage(12)
  b2.login(); W.run(120)
  H.gilde(b2, P.EncodeClaim(K.KEY, "Dora Dorn", tDora, "Berta Senf", 40), "Dora Dorn-Forever"); W.run(5)
  H.erwartet("Tag 32: kein neuer Anspruch auf das bezahlte Kopfgeld", auf(b2, K.KEY) == 0, auf(b2, K.KEY))
  local q = K.msgs(W, "Q", b2)
  local last = q[#q] and q[#q].text or ""
  H.erwartet("Tag 32: Quittung 'kein Kopfgeld' (3)", last:find("Dora") and last:find("\t3\t") ~= nil, last:gsub("\t", " | "))
end)

H.lauf("(b) der Deckel wirft den bezahlten Anspruch zuerst hinaus", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); b.ns.Guild.SetBounty(K.KEY2, 5); W.run(10)
  M.Advance(4000)
  local tKill = time()
  K.toetet(a); W.run(10)
  local ca = K.claims(b)[1]
  H.erwartet("Vorbedingung: bezahlt", ca and b.ns.Feud.SetClaim(ca, "paid") == true)
  W.run(10)
  local P = b.ns.Guild.Proto
  local n = 0
  for w = 1, 3 do
    for i = 1, 20 do
      n = n + 1
      H.gilde(b, P.EncodeClaim(K.KEY2, "Dora Dorn", tKill - n * 61, "Berta Senf", 5), "Dora Dorn-Forever")
    end
    W.run(5); M.Advance(601)
  end
  local paid = 0
  for _, y in ipairs(K.claims(b)) do if y.state == "paid" then paid = paid + 1 end end
  H.erwartet("der bezahlte Anspruch steht noch in der Liste", paid == 1, paid)
  H.gilde(b, P.EncodeClaim(K.KEY, "Dora Dorn", tKill - 30 * 61, "Berta Senf", 40), "Dora Dorn-Forever"); W.run(5)
  H.erwartet("kein neuer Anspruch auf das bezahlte Kopfgeld", auf(b, K.KEY) == 0, auf(b, K.KEY))
end)

H.lauf("(c) Grabstein traegt 'bezahlt', Wieder offen nimmt es zurueck", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  K.toetet(a); W.run(10)
  local ca = K.claims(b)[1]
  b.ns.Feud.SetClaim(ca, "paid"); W.run(5)
  local e = (b.env.DeathNoteDB.bountyEnded or {})[1] or {}
  H.erwartet("Grabstein bezahlt", e.paid == true and e.key == K.KEY)
  b.ns.Feud.SetClaim(ca, "open"); W.run(5)
  H.erwartet("nach Wieder offen nicht mehr", e.paid == nil)
end)

H.fertig()
