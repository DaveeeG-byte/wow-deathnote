-- Jagd 1.7.0 Fund JU-13: der Zettel "Kopfgeld verdient" wartet hinter einer Meldung, die schon steht, wird aber von
-- jeder Meldung verdraengt, die nach ihm kommt und ohne Warteschlange schreibt (eigener Tod, Rache: Extras.lua
-- Banner ueberschreibt). Im PvP ist "eine halbe Sekunde nach dem Zettel sterbe ich" oder "der naechste Kill ist eine
-- Rache" der Normalfall. Der Zettel stand dann einen Augenblick und kommt nie wieder. Die Bau-Regel "der Zettel
-- geht nie unter" (bau-oberflaeche.md Abschnitt 3) haelt nur gegen Meldungen desselben Kills.
-- Erwartet: ein Zettel, der weniger als zwei Sekunden stand, kommt nach der verdraengenden Meldung noch einmal.
-- Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
local W = X.world("deDE")
X.fake(W)
local ns, L = W.ns, W.L
local function banner() return W.frameWith(function(f) return f.kicker and f.stamp and f.line and f.name and f.inAnim end) end
local function kick(b) return b and (tostring(b.kicker._text):gsub("%s", "")) end
local earned = (L.BANNER_EARNED:gsub("%s", ""))
local key = W.kill("Grimm", "Bart")          -- ein Killer aus dem eigenen Buch (fuer die Rache danach)
W.tick(1); W.settle()
W.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = _G.time(), g = 50,
  via = "guild", state = "sent" })
W.tick(1.2)
local B = banner()
check("Vorbedingung: Zettel Kopfgeld verdient steht", B and B:IsShown() and kick(B) == earned, B and B.kicker._text)
W.tick(0.5)
ns.Store.AddRevenge(key)                     -- eine halbe Sekunde spaeter: Rache an einem anderen
W.tick(0.2)
B = banner()
check("Vorbedingung: die Rache-Meldung hat den Zettel ersetzt", B and B:IsShown() and kick(B) ~= earned, B and B.kicker._text)
local again = false
for _ = 1, 400 do
  W.tick(0.1)
  if _ % 20 == 0 then W.BM.FinishAnims() end
  B = banner()
  if B and B:IsShown() and kick(B) == earned then again = true; break end
end
check("der verdraengte Zettel (stand 0,5 s) kommt nach der Rache-Meldung wieder", again, "kommt nie wieder")
J.done()
