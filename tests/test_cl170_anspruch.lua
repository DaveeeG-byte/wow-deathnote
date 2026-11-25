-- 1.7.0 claim: cashing in a bounty. The killer (own killing blow, sure key) gets a record per poster of a bounty of
-- others, the poster a claim (also when he comes online later: C in the answer to his hello), the killer the receipt Q.
-- Paid takes exactly that bounty back (also in the books of others), declined frees it again, one bounty one claim.
-- Only a bounty posted on purpose counts, never the book's own value. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_cl170")
local H, M, G = K.H, K.M, K.G
local KEY = K.KEY

local function eins(W)
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  return a, b
end

H.lauf("(1) Gilde, Aussteller online: Anspruch, Eintrag, Quittung offen", function()
  local W = K.welt()
  local a, b = eins(W)
  H.erwartet("Vorbedingung: Kopfgeld", b.ns.Guild.SetBounty(KEY, 50) == true)
  W.run(10)
  H.erwartet("Vorbedingung: Anton kennt es", a.ns.Guild.HasBounty(KEY) == true)
  K.toetet(a); W.run(10)
  local c = K.claims(b)
  H.erwartet("Berta: ein Anspruch mit Zeitpunkt des Kopfgelds", #c == 1 and c[1].b == K.bountyT(b, KEY)
    and c[1].by == "Anton Wurst" and c[1].g == 50 and c[1].state == "open", #c)
  local e = K.earned(a)
  local x = e[1] or {}
  H.erwartet("Anton: ein Eintrag", #e == 1, #e)
  H.erwartet("Eintrag: Felder nach E7", x.key == KEY and x.owner == "Berta Senf" and x.char == "Anton Wurst"
    and x.g == 50 and x.via == "guild" and type(x.t) == "number" and type(x.at) == "number", x.owner)
  H.erwartet("Quittung kam: offen", x.state == "open", x.state)
  H.erwartet("ein Q von Berta", #K.msgs(W, "Q", b) == 1, #K.msgs(W, "Q", b))
  H.erwartet("EARNED_NEW einmal, EARNED_CHANGED sent -> open", H.zaehle(a, "EARNED_NEW") == 1
    and H.zaehle(a, "EARNED_CHANGED") == 1)
  local ch
  for _, ev in ipairs(a.events) do if ev[1] == "EARNED_CHANGED" then ch = ev end end
  H.erwartet("EARNED_CHANGED(x, old)", ch and ch[2] == x and ch[3] == "sent")
  H.erwartet("Schnittstelle: Earned, OpenEarned", a.ns.Claim.Earned() == e and a.ns.Claim.OpenEarned() == 1)
  H.erwartet("Berta selbst: keine Eintraege", #K.earned(b) == 0 and b.ns.Claim.OpenEarned() == 0)
  H.erwartet("Dismiss", a.ns.Claim.Dismiss(x) == true and #K.earned(a) == 0 and a.ns.Claim.Dismiss(x) == false)
end)

H.lauf("(2) Aussteller offline, kommt spaeter (auch nach Neuladen des Schuetzen): C in der Antwort", function()
  local W = K.welt()
  local a, b = eins(W)
  b.ns.Guild.SetBounty(KEY, 40); W.run(10)
  local bt = K.bountyT(b, KEY)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  local x = K.earned(a)[1] or {}
  H.erwartet("Eintrag unbestaetigt", x.state == "sent" and x.owner == "Berta Senf", x.state)
  H.erwartet("noch kein C (niemand hat gefragt)", #K.msgs(W, "C") == 0)
  -- the killer reloads
  local a2 = K.weg(W, a); a2.login(); W.run(60)
  H.erwartet("nach Neuladen: Eintrag noch da", (K.earned(a2)[1] or {}).state == "sent")
  M.Advance(400)
  b2.login(); W.run(90)
  local cs = K.msgs(W, "C", a2)
  H.erwartet("ein C von Anton nach Bertas Hallo", #cs == 1, #cs)
  local c = K.claims(b2)
  H.erwartet("Berta: Anspruch aus C", #c == 1 and c[1].by == "Anton Wurst" and c[1].b == bt and c[1].g == 40, #c)
  H.erwartet("Anton: Quittung offen", (K.earned(a2)[1] or {}).state == "open")
  -- the next hello of Berta: C again (open is not settled yet), the claim stays one
  M.Advance(700)
  b2.ns.Guild.SyncNow(); W.run(30)
  H.erwartet("wiederholtes C: kein zweiter Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(3) Bezahlt, Wieder oeffnen, Abgelehnt: Zustaende beim Schuetzen; Bezahlt nimmt das Kopfgeld zurueck", function()
  local W = K.welt()
  local a, b = eins(W)
  local c3 = W.client("Carla", "Klee", G, { fullSender = true })
  c3.login(); W.run(60)
  b.ns.Guild.SetBounty(KEY, 70); W.run(10)
  H.erwartet("Vorbedingung: Carla kennt das Kopfgeld", c3.ns.Guild.HasBounty(KEY) == true)
  K.toetet(a); W.run(10)
  local cl = K.claims(b)[1]
  local x = K.earned(a)[1] or {}
  local F = b.ns.Feud
  H.erwartet("bezahlt", F.SetClaim(cl, "paid") == true)
  W.run(10)
  H.erwartet("Anton: bezahlt", x.state == "paid", x.state)
  H.erwartet("Kopfgeld zurueckgenommen", b.ns.Bounty.Own(KEY) == nil)
  H.erwartet("auch bei Carla und Anton (B mit Gold 0)", c3.ns.Guild.HasBounty(KEY) == false and a.ns.Guild.HasBounty(KEY) == false)
  local st
  for _, ev in ipairs(b.events) do if ev[1] == "CLAIM_SETTLED" then st = ev end end
  H.erwartet("CLAIM_SETTLED(c, true)", st and st[2] == cl and st[3] == true)
  H.erwartet("wieder offen", F.SetClaim(cl, "open") == true)
  W.run(10)
  H.erwartet("Anton: offen", x.state == "open", x.state)
  H.erwartet("Wieder oeffnen lobt nichts neu aus", b.ns.Bounty.Own(KEY) == nil)
  H.erwartet("abgelehnt", F.SetClaim(cl, "declined") == true)
  W.run(10)
  H.erwartet("Anton: abgelehnt", x.state == "declined", x.state)
end)

H.lauf("(4) Neue E4: zwei offene Ansprueche auf ein Kopfgeld; Bezahlt fuer einen lehnt den anderen ab; Abgelehnt aendert nichts", function()
  local W = K.welt()
  local a, b = eins(W)
  local d = W.client("Dora", "Dorn", G, { fullSender = true })
  d.login(); W.run(60)
  b.ns.Guild.SetBounty(KEY, 30); W.run(10)
  K.toetet(a); W.run(10)
  local ca = K.claims(b)[1]
  M.Advance(200)
  K.toetet(d); W.run(10)
  local cd
  for _, y in ipairs(K.claims(b)) do if y.by == "Dora Dorn" then cd = y end end
  H.erwartet("Dora: auch offen", (K.earned(d)[1] or {}).state == "open" and cd and cd.state == "open", (K.earned(d)[1] or {}).state)
  H.erwartet("zwei offene Ansprueche", #K.claims(b) == 2, #K.claims(b))
  H.erwartet("Rivals nennt den anderen, Rival (bezahlt) keinen", #b.ns.Feud.Rivals(ca) == 1 and b.ns.Feud.Rivals(ca)[1] == cd
    and b.ns.Feud.Rival(ca) == nil)
  H.erwartet("Dora abgelehnt", b.ns.Feud.SetClaim(cd, "declined") == true)
  W.run(10)
  H.erwartet("Abgelehnt aendert fuer Anton nichts", ca.state == "open" and b.ns.Bounty.Own(KEY) == 30)
  H.erwartet("Dora wieder offen", b.ns.Feud.SetClaim(cd, "open") == true)
  local n0 = H.zaehle(b, "CLAIMS_CHANGED")
  H.erwartet("Anton bezahlt", b.ns.Feud.SetClaim(ca, "paid") == true)
  W.run(10)
  H.erwartet("Dora von selbst abgelehnt, Ereignis je Anspruch", cd.state == "declined" and H.zaehle(b, "CLAIMS_CHANGED") - n0 == 2,
    H.zaehle(b, "CLAIMS_CHANGED") - n0)
  H.erwartet("Dora: Quittung 'kein Kopfgeld'", (K.earned(d)[1] or {}).state == "gone", (K.earned(d)[1] or {}).state)
  H.erwartet("Anton: bezahlt, Kopfgeld zurueck", (K.earned(a)[1] or {}).state == "paid" and b.ns.Bounty.Own(KEY) == nil)
  H.erwartet("Doras Anspruch laesst sich nicht wieder oeffnen (ein Kopfgeld, ein bezahlter Anspruch)",
    b.ns.Feud.SetClaim(cd, "open") == false and cd.state == "declined" and b.ns.Feud.Rival(cd) == ca)
  H.erwartet("auch nicht bezahlen", b.ns.Feud.SetClaim(cd, "paid") == false)
  -- a third kill before the payment, its C comes late: no bounty (one is paid)
  local P = b.ns.Guild.Proto
  H.gilde(b, P.EncodeClaim(KEY, "Carla Klee", ca.t + 30, "Berta Senf", 30), "Carla Klee-Forever")
  W.run(5)
  H.erwartet("dritter Kill: kein Anspruch, solange einer bezahlt ist", #K.claims(b) == 2, #K.claims(b))
end)

H.lauf("(5) E1: hoher Wert des Buchs, kein ausgelobtes Kopfgeld: nichts auf beiden Seiten", function()
  local W = K.welt()
  local a, b = eins(W)
  for i = 1, 6 do H.tod(b, "Taeter", "Lamm", i * 3000) end
  W.run(20)
  local S = b.ns.Store
  local wert = S.Bounty and S.Get(KEY) and S.Bounty(S.Get(KEY)) or 0
  H.erwartet("Vorbedingung: das Buch gibt einen Wert", type(wert) == "number" and wert > 0, wert)
  H.erwartet("Vorbedingung: kein ausgelobtes Kopfgeld", b.ns.Bounty.Own(KEY) == nil and a.ns.Guild.HasBounty(KEY) == false)
  K.toetet(a); W.run(10)
  H.erwartet("V geht wie bisher (gerächt)", #K.msgs(W, "V", a) == 1)
  H.erwartet("Anton: kein Eintrag", #K.earned(a) == 0 and H.zaehle(a, "EARNED_NEW") == 0)
  H.erwartet("Berta: kein Anspruch, kein Q", #K.claims(b) == 0 and #K.msgs(W, "Q") == 0)
end)

H.lauf("(6) E3: nur der Vorname: kein Eintrag, kein C", function()
  local W = K.welt()
  local a, b = eins(W)
  b.ns.Guild.SetBounty(KEY, 25); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a, K.GUID, true); W.run(10)
  H.erwartet("Anton: kein Eintrag (Vorname reicht nicht)", #K.earned(a) == 0)
  M.Advance(400)
  b2.login(); W.run(90)
  H.erwartet("kein C", #K.msgs(W, "C") == 0)
end)

H.lauf("(7) E4 beim Aussteller: Kill vor dem Ausloben gibt Zustand 3, kein Anspruch", function()
  local W = K.welt()
  local a, b = eins(W)
  b.ns.Guild.SetBounty(KEY, 60); W.run(5)
  local P = b.ns.Guild.Proto
  local bt = K.bountyT(b, KEY)
  H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", bt - 3600, "Berta Senf", 60), "Anton Wurst-Forever")
  W.run(5)
  H.erwartet("kein Anspruch", #K.claims(b) == 0)
  local q = K.msgs(W, "Q", b)[1]
  H.erwartet("Q Zustand 3", q and q.text:find("\t3\t%d+$") ~= nil, q and q.text)
  -- inside the tolerance of two clocks (CLAIM_SKEW): counts
  H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", bt - 60, "Berta Senf", 60), "Anton Wurst-Forever")
  W.run(5)
  H.erwartet("Uhren eine Minute auseinander: Anspruch", #K.claims(b) == 1, #K.claims(b))
end)

H.lauf("(8) Zwei Aussteller auf einem Ziel: zwei Eintraege, zwei Ansprueche, getrennte Zustaende", function()
  local W = K.welt()
  local a, b = eins(W)
  local c3 = W.client("Carla", "Klee", G, { fullSender = true })
  c3.login(); W.run(60)
  b.ns.Guild.SetBounty(KEY, 50); c3.ns.Guild.SetBounty(KEY, 20); W.run(10)
  K.toetet(a); W.run(10)
  local e = K.earned(a)
  H.erwartet("zwei Eintraege", #e == 2, #e)
  H.erwartet("je ein Anspruch", #K.claims(b) == 1 and #K.claims(c3) == 1)
  b.ns.Feud.SetClaim(K.claims(b)[1], "paid")
  c3.ns.Feud.SetClaim(K.claims(c3)[1], "declined")
  W.run(10)
  local by = {}
  for _, x in ipairs(e) do by[x.owner] = x.state end
  H.erwartet("Berta bezahlt, Carla abgelehnt", by["Berta Senf"] == "paid" and by["Carla Klee"] == "declined",
    tostring(by["Berta Senf"]) .. "/" .. tostring(by["Carla Klee"]))
  H.erwartet("Carlas Kopfgeld steht noch", c3.ns.Bounty.Own(KEY) == 20 and b.ns.Bounty.Own(KEY) == nil)
end)

H.lauf("(9) Freunde (Fluestern): online und spaeter", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty(KEY, 75); W.run(20)
  K.toetet(a); W.run(10)
  local x = K.earned(a)[1] or {}
  H.erwartet("online: Anspruch und Quittung", #K.claims(b) == 1 and x.state == "open" and x.via == "friends", tostring(#K.claims(b)) .. "/" .. tostring(x.via))
  local q = K.msgs(W, "Q", b)[1]
  H.erwartet("Q als Fluestern", q and q.channel == "WHISPER" and q.to == "Anton Wurst")
  -- a second target while Berta is offline
  b.ns.Guild.SetBounty(K.KEY2, 15); W.run(20)
  local b2 = K.weg(W, b)
  W.setOnline(b, false); W.run(5)
  M.Advance(200)
  K.toetet(a, K.GUID2); W.run(10)
  local y
  for _, z in ipairs(K.earned(a)) do if z.key == K.KEY2 then y = z end end
  H.erwartet("offline: unbestaetigt", y and y.state == "sent")
  M.Advance(400)
  b2.login(); W.run(150)
  local cs = K.msgs(W, "C", a)
  H.erwartet("C als Fluestern an Berta", #cs >= 1 and cs[1].channel == "WHISPER" and cs[1].to == "Berta Senf", #cs)
  H.erwartet("Anspruch nachgereicht, Quittung offen", #K.claims(b2) == 2 and y and y.state == "open", #K.claims(b2))
end)

H.lauf("(10) Schuetze zugleich Kollege und Freund: ein Anspruch, kein doppeltes C", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty(KEY, 33); W.run(20)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(100)   -- (1.7.0 fixer: the C after FRESH_WAIT finds nobody)
  H.erwartet("ein Eintrag (Gilde)", #K.earned(a) == 1 and K.earned(a)[1].via == "guild", #K.earned(a))
  M.Advance(400)
  local n0 = #K.msgs(W, "C", a)
  b2.login(); W.run(150)
  H.erwartet("ein Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  local n = #K.msgs(W, "C", a) - n0
  H.erwartet("ein C nach Bertas Login (Gilde, nicht dazu per Fluestern)", n == 1, n)
  H.erwartet("Quittung offen", K.earned(a)[1].state == "open")
end)

H.lauf("(12) Kopfgeld auf einem anderen Char desselben Kontos: Anspruch ohne Q, Quittung kommt mit dem C an jenen Char", function()
  local W = K.welt()
  local a, b = eins(W)
  b.ns.Guild.SetBounty(KEY, 45); W.run(10)
  -- the same account comes back on another char
  local z = K.weg(W, b, { name = "Bianca" })
  z.login(); W.run(60)
  H.erwartet("Vorbedingung: Berta ist ein eigener Char", z.ns.Guild.IsOwnChar("Berta Senf") == true)
  M.Advance(200)
  K.toetet(a); W.run(10)
  local c = K.claims(z)[1] or {}
  H.erwartet("Anspruch auf Bertas Kopfgeld", c.char == "Berta Senf" and c.by == "Anton Wurst", c.char)
  H.erwartet("kein Q von Bianca (Q nennt nur den Absender als Aussteller)", #K.msgs(W, "Q", z) == 0)
  H.erwartet("Eintrag unbestaetigt", (K.earned(a)[1] or {}).state == "sent")
  H.erwartet("bezahlt", z.ns.Feud.SetClaim(c, "paid") == true)
  local st
  for _, ev in ipairs(z.events) do if ev[1] == "CLAIM_SETTLED" then st = ev end end
  H.erwartet("Kopfgeld des anderen Chars still zurueckgenommen", st and st[3] == true
    and not (z.env.DeathNoteDB.bounty[KEY] and z.env.DeathNoteDB.bounty[KEY]["Berta Senf"]))
  -- Berta again: her hello brings the C, the receipt says paid
  local b3 = K.weg(W, z, { name = "Berta" })
  M.Advance(400)
  b3.login(); W.run(90)
  H.erwartet("Quittung bezahlt", (K.earned(a)[1] or {}).state == "paid", (K.earned(a)[1] or {}).state)
  H.erwartet("ein Anspruch", #K.claims(b3) == 1)
end)

H.lauf("(11) Bounty.Others: nur Kopfgelder anderer; ohne keine neue Tabelle", function()
  local W = K.welt()
  local a, b = eins(W)
  local X = a.ns.Bounty
  local s0, r0 = X.Others(KEY)
  local s1, r1 = X.Others(K.KEY2)
  H.erwartet("ohne Kopfgeld: 0 und dieselbe leere Tabelle", s0 == 0 and #r0 == 0 and r0 == r1)
  a.ns.Guild.SetBounty(KEY, 10); W.run(5)
  local s2, r2 = X.Others(KEY)
  H.erwartet("nur eigenes: 0, leere Tabelle", s2 == 0 and r2 == r0)
  b.ns.Guild.SetBounty(KEY, 50); W.run(5)
  local s3, r3 = X.Others(KEY)
  H.erwartet("Bertas: 50, eine Zeile", s3 == 50 and #r3 == 1 and r3[1].char == "Berta Senf" and r3[1].g == 50, s3)
end)

H.fertig()
