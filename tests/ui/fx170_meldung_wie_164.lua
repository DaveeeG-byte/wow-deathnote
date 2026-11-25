-- Fixer 1.7.0 (JU-13), comparison with 1.6.4: only a slip that is pushed away comes back. A payback notice pushed
-- away by another payback notice half a second later stays gone, as before. All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
local W = X.world("deDE")
X.fake(W)
local ns = W.ns
local function banner() return W.frameWith(function(f) return f.kicker and f.stamp and f.line and f.name and f.inAnim end) end
local k1 = W.kill("Grimm", "Bart")
local k2 = W.kill("Hart", "Holz")
W.tick(1); W.settle(); W.BM.FinishAnims(); W.tick(1)
ns.Store.AddRevenge(k1, true); W.tick(0.5)
local B = banner()
check("Vorbedingung: Rache an Grimm steht", B and B:IsShown() and B.key == k1)
ns.Store.AddRevenge(k2, true); W.tick(0.2)
B = banner()
check("Vorbedingung: Rache an Hart hat sie ersetzt", B and B:IsShown() and B.key == k2)
local back = false
for i = 1, 400 do
  W.tick(0.1)
  if i % 20 == 0 then W.BM.FinishAnims() end
  B = banner()
  if B and B:IsShown() and B.key == k1 then back = true; break end
end
check("die verdraengte Rache-Meldung kommt nicht wieder (wie 1.6.4)", not back)
local n, e = W.errs()
check("keine Fehler", n == 0, e)
X.done("fx170 meldung wie 1.6.4")
