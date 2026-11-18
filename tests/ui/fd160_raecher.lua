-- Design fixer 1.6.0 (design hunt 13): the avengers' page is one page, not two islands: the most wanted hang about 20
-- below the last shown line above them; the rows in the book's list font (Friz 11 like "who has the book"); the heads
-- one style (letter-spaced ink, one line). Names made up.
local WT = arg[1] or "."
local here = (arg[0]:match("^(.*)/") or ".")
local J = dofile(here .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  dofile(here .. "/_fdwelt.lua")(W, { { "Liora", "Grimm", "Aschgrau", 2 }, { "Bertram", "Velka", "Dorn", 5 } })
  W.open(); W.tab("guild"); W.settle()
  W.ns.GuildLogUI.Open("avengers"); W.settle()
  local L, JK = W.ns.L, W.ns.UI.JK
  local wh = W.visible(JK.Spaced(L.GLOG_WANTED_HEAD))
  J.check(code .. ": Kopf Meistgesucht da, einzeilig", wh ~= nil and wh._wrap == false, wh and tostring(wh._wrap))
  -- the lowest shown text above the head
  local above
  for _, f in ipairs(W.BM.frames) do
    local v = wh and wh:GetParent()
    local par = f.GetParent and f:GetParent()
    local mine = v and (par == v or (par and par.GetParent and par:GetParent() == v))
    if mine and f._kind == "FontString" and f:IsVisible() and type(f._text) == "string" and f._text ~= "" and f ~= wh
      and f:GetBottom() and f:GetBottom() > wh:GetTop() then
      if not above or f:GetBottom() < above:GetBottom() then above = f end
    end
  end
  local gap = wh and above and (above:GetBottom() - wh:GetTop())
  J.check(code .. ": Meistgesucht haengt etwa 20 unter der letzten Zeile", gap and gap >= 12 and gap <= 40,
    tostring(gap) .. " unter " .. tostring(above and above._text))
  local row = W.visible("1.  ")
  J.check(code .. ": Zeilen in der Listenschrift", row and row.fontKind == "body" and row.fontSize == 11,
    row and (tostring(row.fontKind) .. " " .. tostring(row.fontSize)))
end
J.done()
