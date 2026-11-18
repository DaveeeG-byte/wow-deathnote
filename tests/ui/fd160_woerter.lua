-- Design fixer 1.6.0 (design hunt 12, 18): the file of a cause shows no NPC id (technique without use for the player),
-- no sentence that explains the list, and names its date ("last 10.11. 20:58"); enUS Unsolved switches read
-- "Cases · Claims · Filed away" (not "Open" under "Unsolved", not the ambiguous "Filed"). Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local function visible(W, s)
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(s, 1, true) and f:IsVisible() then return f end
  end
end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local ns, L, F = W.ns, W.ns.L, W.ns.F
  W.AM.Advance(100)
  for _ = 1, 2 do
    local j = { t = time(), kind = "pve", zone = "Brachland", subzone = "Wegkreuz", mapID = 1413, x = 51.5, y = 30.2,
      me = "Ich Selbst", myLevel = 30, counted = true, candidates = {},
      cause = { art = "creature", name = "Stachelebermutter", npc = 3100, spell = "Rammen" } }
    ns.Store.RecordDeath(j); ns:Fire("DEATH_RECORDED", j, nil); W.tick(1)
    W.AM.Advance(600)
  end
  ns.UI.Open(); W.settle()
  for _, f in ipairs(W.BM.frames) do
    if f.fateView and f.view == "causes" then f._scripts.OnClick(f, "LeftButton") end
  end
  W.settle()
  J.check(code .. ": Ursache offen", visible(W, L.FATE_HEAD) ~= nil)
  J.check(code .. ": keine NPC-ID auf der Akte", visible(W, F(L.FATE_NPC, { id = 3100 })) == nil)
  J.check(code .. ": kein Satz zur Rangliste", visible(W, L.FATE_NOTE_FOE) == nil)
  local last = F(L.FATE_LAST, { time = "\1" }):match("^([^\1]*)")
  J.check(code .. ": Datum heisst zuletzt", last ~= "" and visible(W, last) ~= nil, last)
  if code == "enUS" then
    J.check("enUS: Umschalter Cases und Filed away", L.VIEW_OPEN == "Cases" and L.VIEW_FILED == "Filed away",
      L.VIEW_OPEN .. " / " .. L.VIEW_FILED)
  end
  J.check(code .. ": keine Addon-Fehler", #W.AM.errors == 0, W.AM.errors[1])
end
J.done()
