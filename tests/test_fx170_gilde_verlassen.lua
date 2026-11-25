-- 1.7.0 fixer (point "not checked" of the hunt): the killer leaves the guild after the kill. The receipt of "paid"
-- went only the way the claim came (GUILD) and was not heard; a friend now gets it by whisper too. And the test head:
-- H.relog with noGuild = true really comes back without a guild. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Schuetze verlaesst die Gilde nach dem Kill, ist aber Freund", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", K.G, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", K.G, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(20)
  K.toetet(a); W.run(10)
  local cl = K.claims(b)[1] or {}
  H.erwartet("Vorbedingung: Anspruch ueber die Gilde, Eintrag offen", cl.state == "open" and (K.earned(a)[1] or {}).state == "open")
  local a2 = K.H.relog(W, a, { noGuild = true })
  H.erwartet("relog ohne Gilde", a2.guild == nil)
  a2.login(); W.run(120)
  M.Advance(400); b.ns.Friends.SyncNow(); W.run(120)
  -- the bounty was taken back meanwhile: "paid" sends no B, only the receipt can tell Anton
  b.ns.Guild.SetBounty(K.KEY, 0); W.run(20)
  M.Advance(700); W.run(5)
  H.erwartet("Vorbedingung: noch offen", (K.earned(a2)[1] or {}).state == "open")
  H.erwartet("bezahlt", b.ns.Feud.SetClaim(cl, "paid") == true)
  W.run(20)
  H.erwartet("Anton hoert die Quittung per Fluestern", (K.earned(a2)[1] or {}).state == "paid", (K.earned(a2)[1] or {}).state)
end)

H.fertig()
