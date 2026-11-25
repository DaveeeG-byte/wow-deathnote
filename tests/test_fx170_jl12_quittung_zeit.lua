-- 1.7.0 fix JL-12: a receipt carrying another time of the same kill (under 60 s apart, the poster's claim came from
-- the first V) reaches the record when exactly one record is that close; with two such records none (unclear).
-- All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Quittung mit der Zeit des Anspruchs", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  local x = K.earned(a)[1]
  local P = a.ns.Guild.Proto
  H.gilde(a, P.EncodeReceipt(K.KEY, "Anton Wurst", x.t - 40, "Berta Senf", 1, 40), "Berta Senf-Forever")
  W.run(2)
  H.erwartet("ein naher Eintrag: bezahlt", x.state == "paid", x.state)
  -- two records near the time: unclear, nothing changes
  local list = K.earned(a)
  table.insert(list, 1, { key = K.KEY, name = x.name, owner = "Berta Senf", char = "Anton Wurst", t = x.t + 30, g = 40,
    via = "guild", state = "sent", at = x.at })
  H.gilde(a, P.EncodeReceipt(K.KEY, "Anton Wurst", x.t + 10, "Berta Senf", 2, 40), "Berta Senf-Forever")
  W.run(2)
  H.erwartet("zwei nahe Eintraege: keiner geaendert", x.state == "paid" and list[1].state == "sent")
end)

H.fertig()
