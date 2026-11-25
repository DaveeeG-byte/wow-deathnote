-- 1.7.0 claim: the probe probe.claim. C and Q sent and received, dropped per reason, the queue's results per kind and
-- way, records and claims; added up over sessions at logout, kept by /dn probe. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_cl170")
local H, M, G = K.H, K.M, K.G

H.lauf("(1) Zaehler beim Schuetzen und beim Aussteller, in probe.claim beim Abmelden und nach /dn probe", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  b.ns.Guild.SetBounty(K.KEY, 50); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(100)   -- (1.7.0 fixer: the C after FRESH_WAIT finds nobody)
  M.Advance(400)
  b2.login(); W.run(90)
  local sa, sb = a.ns.Claim.Session(), b2.ns.Claim.Session()
  H.erwartet("Schuetze: Eintrag, C gesendet, Q empfangen", sa.earned == 1 and sa["sent.C"] == 2 and sa["fresh.C"] == 1 and sa["recv.Q"] == 1,
    tostring(sa.earned) .. "/" .. tostring(sa["sent.C"]) .. "/" .. tostring(sa["recv.Q"]))
  H.erwartet("Schuetze: Ergebnis der Schlange fuer C (FRESH_WAIT und Hallo)", sa["code.C.ok.guild"] == 2, sa["code.C.ok.guild"])
  H.erwartet("Aussteller: C empfangen, Anspruch neu, Q gesendet", sb["recv.C"] == 1 and sb["claim.new"] == 1
    and sb["sent.Q"] == 1 and sb["code.Q.ok.guild"] == 1)
  -- a forged C (sender is not the killer) is counted by reason
  H.gilde(b2, b2.ns.Guild.Proto.EncodeClaim(K.KEY, "Emil Eck", time() - 10, "Berta Senf", 5), "Carla Klee-Forever")
  H.erwartet("verworfen je Grund", b2.ns.Claim.Session()["drop.sender"] == 1)
  b2.ns.Probe.Run(false)
  local p = b2.env.DeathNoteDB.probe.claim
  H.erwartet("/dn probe: probe.claim", type(p) == "table" and p["recv.C"] == 1 and p["drop.sender"] == 1)
  b2.ns.Probe.Run(false)
  H.erwartet("nicht doppelt", b2.env.DeathNoteDB.probe.claim["recv.C"] == 1)
  a.fire("PLAYER_LOGOUT")
  local pa = a.env.DeathNoteDB.probe and a.env.DeathNoteDB.probe.claim
  H.erwartet("beim Abmelden geschrieben", type(pa) == "table" and pa.earned == 1)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(2) unsicherer Schluessel wird gezaehlt", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  b.ns.Guild.SetBounty(K.KEY, 50); W.run(10)
  K.toetet(a, K.GUID, true); W.run(10)
  H.erwartet("unsure", a.ns.Claim.Session().unsure == 1 and #K.earned(a) == 0)
end)

H.fertig()
