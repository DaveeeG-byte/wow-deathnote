-- Design fixer 1.6.0 (design hunt 11): a guild row in Wanted > Guilds says deaths and score whole, without an ellipsis;
-- "seen ..." stays in the row's tooltip and on the guild's sheet (with its word). Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(WT, code)
  local ns, L, F = W.ns, W.L, W.ns.F
  W.kill("Grimwald", "Ashbrand", "Die Schlaechter von Sturmwind", time() - 9000)
  W.kill("Grimwald", "Ashbrand", "Die Schlaechter von Sturmwind", time() - 8000)
  local k = W.kill("Velka", "Thornheart", "Die Schlaechter von Sturmwind", time() - 1200)
  -- a sighting of a member (the book's own field; Feud reads the newest of the guild)
  local e = ns.Store.Get(k or "Velka-Thornheart")
  if e then e.lastSeen = { t = time() - 600, zone = "Schlingendorntal" } end
  W.open()
  W.click(W.find(L.VIEW_GUILDS))
  local r1 = W.rows()[1]
  local sub = r1 and r1.sub._text or ""
  J.check(code .. ": Gildenzeile ohne Ellipse", r1 ~= nil and not sub:find("…", 1, true) and not sub:find("...", 1, true)
    and not ns.Look.IsCut(r1.sub), sub)
  local seen = F(L.ROW_SEEN, { time = "\1" }):match("^([^\1]*)")
  J.check(code .. ": gesehen nicht in der Zeile", not sub:find(seen, 1, true), sub)
  local tip = r1 and r1.tipFn and table.concat(r1.tipFn(r1.item), " | ") or ""
  J.check(code .. ": gesehen im Tooltip", tip:find(seen, 1, true) ~= nil, tip)
  local S = ns.FeudUI.Sheet and ns.FeudUI.Sheet()
  J.check(code .. ": gesehen auf dem Blatt", S and S:IsVisible() and tostring(S.when._text):find(seen, 1, true) ~= nil,
    S and S.when._text)
end
J.done()
