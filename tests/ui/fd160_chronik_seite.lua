-- Design fixer 1.6.0 (design hunt 2): the guild chronicle is no wall of capitals any more: the sentence in the running
-- font (type, Nimrod), the time apart at the right edge (not in the sentence), 8 units between two entries, a sign in
-- the margin for every kind (death, revenge, bounty, release), not only for call and sighting. Names made up.
local WT = arg[1] or "."
local here = (arg[0]:match("^(.*)/") or ".")
local J = dofile(here .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns = W.ns
  local GL = ns.GuildLog
  -- one event of every kind, straight into the chronicle's list (GuildLog.All is what the page reads)
  local t0 = time()
  local list = {
    { k = "death", t = t0 - 60, by = "Liora-Forever", victim = "Liora-Forever", name = "Grimwald Ashbrand", key = "Grimwald-Ashbrand",
      zone = "Schlingendorntal" },
    { k = "avenged", t = t0 - 120, by = "Bertram-Forever", name = "Grimwald Ashbrand", key = "Grimwald-Ashbrand", victims = {} },
    { k = "bounty", t = t0 - 180, by = "Corwin-Forever", name = "Torvik Greyhammer", key = "Torvik-Greyhammer", g = 50 },
    { k = "release", t = t0 - 240, by = "Wendell-Forever", name = "Ysolde Nightsong", key = "Ysolde-Nightsong" },
  }
  GL.All = function() return list end
  GL.Feed = GL.All
  W.open(); W.tab("guild"); W.settle()
  ns.GuildLogUI.Open("holders"); W.settle()
  local lines = {}
  for _, f in ipairs(W.BM.frames) do
    if f.event and f.text and f.pin and f:IsVisible() then lines[#lines + 1] = f end
  end
  table.sort(lines, function(a, b) return a:GetTop() > b:GetTop() end)
  J.check(code .. ": vier Eintraege", #lines == 4, #lines)
  local kinds = {}
  for i, b in ipairs(lines) do
    local k = b.event.k
    J.check(code .. " " .. k .. ": Satz in der Fliessschrift", b.text.fontKind == "type", b.text.fontKind)
    local ago = ns.Util.Ago(b.event.t)
    J.check(code .. " " .. k .. ": Zeit rechts fuer sich, nicht im Satz", b.time and b.time:GetText() == ago
      and not tostring(b.text:GetText()):find(ago, 1, true) and b.time:GetRight() >= b.text:GetRight(),
      tostring(b.text:GetText()))
    J.check(code .. " " .. k .. ": Zeichen am Rand", b.pin:IsVisible() and b.pin.tex._tex ~= nil, b.pin.tex._tex)
    kinds[tostring(b.pin.tex._tex)] = true
    if i > 1 then
      local gap = lines[i - 1]:GetBottom() - b:GetTop()
      J.check(code .. " " .. k .. ": mindestens 8 Abstand zum vorigen Eintrag", gap >= 8, gap)
    end
  end
  local n = 0
  for _ in pairs(kinds) do n = n + 1 end
  J.check(code .. ": vier Arten, vier Zeichen", n == 4, n)
  J.check(code .. ": keine Addon-Fehler", #W.AM.errors == 0, W.AM.errors[1])
end
J.done()
