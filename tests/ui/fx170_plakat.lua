-- Fixer 1.7.0 (JU-17): the book's value has its tooltip on a pardoned one's poster too (without the click line, a click
-- does nothing). All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(code)
  local ns, L = W.ns, W.L
  local key = W.kill("Grimm", "Bart")
  ns.Store.SetStatus(key, "pardoned")
  W.tick(1); W.open()
  ns.UI.ShowEnemy(key); W.tick()
  local E = W.frameWith(function(f) return f.stampNr1 and f.hunt and f.bountyLabel end)
  local tip = E.bountyHit.tip
  check(code .. ": begnadigt: Wort BUCHWERT", E.bountyLabel._text == W.spaced(L.POSTER_BOOK_VALUE), E.bountyLabel._text)
  check(code .. ": begnadigt: Tooltip am Buchwert", E.bountyHit:IsShown() and type(tip) == "table" and tip[2] == L.BOOK_VALUE_TIP)
  check(code .. ": begnadigt: ohne Klick-Zeile", type(tip) == "table" and tip[#tip] ~= L.BOUNTY_TIP_CLICK)
  W.click(E.bountyHit)
  check(code .. ": begnadigt: Klick oeffnet keine Eingabe", not E.bountyEdit:IsShown())
  local n, e = W.errs()
  check(code .. ": keine Fehler", n == 0, e)
end
X.done("fx170 plakat")
