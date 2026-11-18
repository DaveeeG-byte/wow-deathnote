-- Fixer 1.6.0 (UI hunt 19): the place line of a death's file keeps its coordinates together ("(61, 53)" with a
-- no-break space, never "(61," / "53)" on two lines). Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local j = W.creature("Grauer Wolf", 299, "Biss")
  W.open()
  W.ns.UI.ShowCase(j); W.settle()
  J.check(code .. ": Koordinaten mit festem Leerzeichen", W.visible("(61,\194\16053)") ~= nil)
  J.check(code .. ": kein gewoehnliches Leerzeichen darin", W.visible("(61, 53)") == nil)
end
J.done()
