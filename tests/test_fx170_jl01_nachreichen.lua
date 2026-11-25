-- 1.7.0 fix JL-1 (copy of the hunt's jl01, plus the wait set). jl01 (Notiz 1): Gilde. Der Auslober ist schon online, der Schuetze (Kill geschah, als der Auslober offline war)
-- loggt erst danach ein. Nur der Schuetze sagt Hallo; C geht aber nur in der Antwort auf ein Hallo des Auslobers.
-- Erwartet: der Anspruch kommt an, solange beide online sind. Ist: Eintrag bleibt "sent", kein C, kein Anspruch.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Auslober zuerst online, Schuetze danach", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)            -- Auslober offline
  K.toetet(a); W.run(10)            -- Kill, V verhallt
  H.erwartet("Vorbedingung: Eintrag sent", (K.earned(a)[1] or {}).state == "sent")
  local a2 = K.weg(W, a)            -- Schuetze offline
  M.Advance(3600)
  b2.login(); W.run(120)            -- Auslober kommt zuerst
  M.Advance(1800)
  a2.login(); W.run(300)            -- Schuetze kommt danach, sagt Hallo, Berta antwortet
  M.Advance(1800); W.run(300)       -- beide bleiben eine weitere halbe Stunde online
  H.erwartet("C ging hinaus", #K.msgs(W, "C") >= 1, #K.msgs(W, "C"))
  H.erwartet("Berta hat den Anspruch", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Anton: Eintrag nicht mehr unbestaetigt", (K.earned(a2)[1] or {}).state == "open", (K.earned(a2)[1] or {}).state)
end)

H.lauf("Gegenprobe Freunde (Fluestern): dieselbe Reihenfolge", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(20)
  local b2 = K.weg(W, b); W.setOnline(b, false); W.run(5)
  M.Advance(200)
  K.toetet(a); W.run(10)
  H.erwartet("Vorbedingung Freunde: Eintrag sent", (K.earned(a)[1] or {}).state == "sent", (K.earned(a)[1] or {}).state)
  local a2 = K.weg(W, a); W.setOnline(a, false); W.run(5)
  M.Advance(3600)
  b2.login(); W.run(150)
  M.Advance(1800)
  a2.login(); W.run(300)
  M.Advance(1800); W.run(300)
  H.erwartet("Freunde: Anspruch kam an", #K.claims(b2) == 1, #K.claims(b2))
  H.erwartet("Freunde: Eintrag open", (K.earned(a2)[1] or {}).state == "open", (K.earned(a2)[1] or {}).state)
end)

H.lauf("Wartemenge: nil ohne wartenden Eintrag (ein Tabellenblick je Nachricht), sonst der Vorname des Auslobers", function()
  local W = K.welt()
  local a, b = K.paar(W)
  H.erwartet("nichts wartet: nil", a.ns.Guild.claimWait == nil)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  H.erwartet("wartet: berta", type(a.ns.Guild.claimWait) == "table" and a.ns.Guild.claimWait.berta == true)
  a.ns.Claim.Dismiss(K.earned(a)[1])
  H.erwartet("nach Dismiss wieder nil", a.ns.Guild.claimWait == nil)
end)

H.fertig()
