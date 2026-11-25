-- 1.7.0 fix JL-11: a paid claim of 1.6.x carries no b (the bounty's first posting). It holds the bounty when its kill came
-- after that posting: a later C gets "no bounty", an open claim on the bounty cannot be paid or reopened. All names are
-- made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("bezahlter Anspruch ohne b haelt das Kopfgeld", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local bt = K.bountyT(b, K.KEY)
  local cl = b.env.DeathNoteDB.claims or {}
  b.env.DeathNoteDB.claims = cl
  table.insert(cl, 1, { key = K.KEY, by = "Egon Eck", t = bt + 100, g = 40, state = "paid", char = "Berta Senf" })
  local P = b.ns.Guild.Proto
  H.gilde(b, P.EncodeClaim(K.KEY, "Anton Wurst", bt + 200, "Berta Senf", 40), "Anton Wurst-Forever")
  W.run(5)
  H.erwartet("kein neuer Anspruch", #K.claims(b) == 1, #K.claims(b))
  local q = K.msgs(W, "Q", b)[1]
  H.erwartet("Q Zustand 3", q and q.text:find("\t3\t%d+$") ~= nil, q and q.text)
  -- a claim with b on the same bounty (made before the update) cannot be paid
  local open = { key = K.KEY, by = "Dora Dorn", t = bt + 50, g = 40, state = "open", char = "Berta Senf", b = bt }
  table.insert(cl, open)
  H.erwartet("Rival ist der alte bezahlte", b.ns.Feud.Rival(open) == cl[1] and cl[1].by == "Egon Eck")
  H.erwartet("nicht bezahlbar", b.ns.Feud.SetClaim(open, "paid") == false)
  -- a 1.6.x claim whose kill was before the posting is no rival
  cl[1].t = bt - 1000
  H.erwartet("Kill vor dem Ausloben: kein Rival", b.ns.Feud.Rival(open) == nil)
end)

H.fertig()
