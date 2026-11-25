-- 1.7.0 fixer round 2 (addition of the orchestrator): a record still waiting ("sent", e.g. at a 1.6.x poster who
-- never answers) covered every later kill of the same target for the same poster, also on a bounty posted anew after
-- it. Now it covers only kills on the bounty as the killer knows it: when the poster's bounty changed after that kill
-- (taken back and posted anew, or a new amount: the killer cannot tell the two apart), a later kill gets its own
-- record. The poster (new E4) holds both open at most; "paid" for one declines the other. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

local function b(a, g, t)
  local P = a.ns.Guild.Proto
  H.gilde(a, P.EncodeBounty(K.KEY, "Berta Senf", g, t, nil), "Berta Senf-Forever")
end

H.lauf("neu ausgelobt nach einem wartenden Eintrag", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", K.G, { fullSender = true })
  local o = W.client("Otto", "Ohr", K.G, { fullSender = true })
  a.login(); o.login(); W.run(90)
  b(a, 40, time()); W.run(5)
  K.toetet(a); W.run(100)
  H.erwartet("Vorbedingung: ein Eintrag sent", #K.earned(a) == 1 and K.earned(a)[1].state == "sent")
  M.Advance(600)
  b(a, 0, time()); W.run(5)
  M.Advance(60)
  b(a, 30, time()); W.run(5)
  M.Advance(600)
  K.toetet(a); W.run(10)
  H.erwartet("neues Kopfgeld: zweiter Eintrag", #K.earned(a) == 2 and K.earned(a)[1].g == 30, #K.earned(a))
  -- the same bounty unchanged: a further kill is covered by the waiting record
  M.Advance(600)
  K.toetet(a); W.run(10)
  H.erwartet("unveraendertes Kopfgeld: kein dritter", #K.earned(a) == 2, #K.earned(a))
end)

H.fertig()
