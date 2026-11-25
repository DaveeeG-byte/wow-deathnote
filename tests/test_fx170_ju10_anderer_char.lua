-- 1.7.0 fix JL-10 / JU-10 (the wire's part of the hunt's ju10): "paid" for a bounty of another own char takes it back
-- quietly in the own book and notes it; that char sends B with gold 0 at its next login, then guild and friends no
-- longer know the bounty. Claim.WouldTake and CLAIM_SETTLED name that char (later). Why it stayed before even after
-- that char's login: the answer's Y only reaches who says hello; a guildmate who is online all the time never does.
-- All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("Bianca bezahlt Bertas Kopfgeld; Berta loggt ein", function()
  local W = K.welt()
  local a, b = K.paar(W)
  local c = W.client("Carl", "Kraut", K.G, { fullSender = true }); c.login(); W.run(60)
  local f = W.client("Fritz", "Frei", nil, { friends = { "Berta Senf" }, fullSender = true }); f.login()
  b.friendNames = { "Fritz Frei" }
  b.fire("FRIENDLIST_UPDATE"); W.run(120)
  b.ns.Guild.SetBounty(K.KEY, 45); W.run(30)
  H.erwartet("Vorbedingung: Carl und Fritz kennen es", c.ns.Guild.HasBounty(K.KEY) == true and f.ns.Guild.HasBounty(K.KEY) == true)
  local z = K.weg(W, b, { name = "Bianca" }); z.login(); W.run(60)
  M.Advance(200)
  K.toetet(a); W.run(10)
  local cl = K.claims(z)[1] or {}
  local would, later = z.ns.Claim.WouldTake(cl)
  H.erwartet("WouldTake: true, spaeter von Berta", would == true and later == "Berta Senf", tostring(would) .. "/" .. tostring(later))
  H.erwartet("bezahlt", z.ns.Feud.SetClaim(cl, "paid") == true)
  local st
  for _, ev in ipairs(z.events) do if ev[1] == "CLAIM_SETTLED" then st = ev end end
  H.erwartet("CLAIM_SETTLED(c, true, 'Berta Senf')", st and st[3] == true and st[4] == "Berta Senf")
  H.erwartet("vorgemerkt", z.env.DeathNoteDB.bountyBack and z.env.DeathNoteDB.bountyBack["Berta Senf"]
    and z.env.DeathNoteDB.bountyBack["Berta Senf"][K.KEY] ~= nil)
  local b3 = K.weg(W, z, { name = "Berta" })
  M.Advance(400)
  b3.login(); W.run(300)
  H.erwartet("nach Bertas Login: Carl kennt es nicht mehr", c.ns.Guild.HasBounty(K.KEY) ~= true)
  H.erwartet("auch der Freund nicht", f.ns.Guild.HasBounty(K.KEY) ~= true)
  H.erwartet("Vormerkung erledigt", not (b3.env.DeathNoteDB.bountyBack and b3.env.DeathNoteDB.bountyBack["Berta Senf"]))
  local n0 = #K.earned(c)
  K.toetet(c); W.run(10)
  H.erwartet("Carl: kein 'verdient' mehr", #K.earned(c) == n0, #K.earned(c) - n0)
  local own = b3.ns.Claim.WouldTake(cl)
  H.erwartet("eigener Char: later nil", select(2, b3.ns.Claim.WouldTake({ key = K.KEY, char = "Berta Senf", b = 1 })) == nil and own == false)
end)

H.fertig()
