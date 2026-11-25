-- 1.7.0 fix JL-13: in the answer to the poster's hello the C come first (before the kills, the releases and the B: a
-- full queue drops the end of an answer), and the poster takes two answers' worth of C in 10 minutes (CLAIM_IN 20).
-- All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("C vor den B der Antwort", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  a.ns.Guild.SetBounty(K.KEY2, 10); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  M.Advance(400)
  local n0 = #W.sent
  b2.login(); W.run(90)
  local iC, iB
  for i = n0 + 1, #W.sent do
    local m = W.sent[i]
    if m.sender == a then
      if not iC and m.text:find("^1\tC\t") then iC = i end
      if not iB and m.text:find("^1\tB\t") then iB = i end
    end
  end
  H.erwartet("C und B in Antons Antwort", iC ~= nil and iB ~= nil)
  H.erwartet("C zuerst", iC and iB and iC < iB, tostring(iC) .. "/" .. tostring(iB))
  H.erwartet("CLAIM_IN = 2 x CLAIM_REPLY", a.ns.Guild.C.CLAIM_IN == 2 * a.ns.Guild.C.CLAIM_REPLY)
end)

H.fertig()
