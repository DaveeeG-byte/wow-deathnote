-- 1.3.0 rap sheet in the book (repute package B): the standing "me : him" on rows, poster, tooltip and alarm line,
-- the order by open debt with the top title only for an open case, the fifth tab with the own file, the victim sheet
-- and the log, the notices after an own kill, the switches. UI mock with the real logic. All names are invented.
-- Call from the project root: luajit tests/ui/rapsheet.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "rapsheet")
local check = K.check

local ME = "Player-93-0000AAAA"
local ns, AM, BM, G
local plate = 0
local function world(code, opts)
  ns = K.world(code or "deDE", opts)
  AM, BM, G = K.AM, K.BM, K.G
  AM.units.player.level = 40
  K.tick(30); K.settle()
  return ns
end
local function seen(name, surname, level, class)
  plate = plate + 1
  local guid = "Player-93-" .. name .. surname
  AM.AddEnemy("nameplate" .. plate, { name = name, surname = surname, level = level or 40, guid = guid, class = class or "MAGE" })
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return guid
end
local function killsMe(name, surname, n)
  for i = 1, n do
    ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
      { t = time() - 3000 * i, zone = "Schlingendorntal" }, true)
  end
  return ns.Util.KeyFor(name, surname)
end
local function iKill(name, surname, n, level)
  local g = seen(name, surname, level or 40)
  for _ = 1, n do AM.FireEvent("PARTY_KILL", ME, g); K.tick(61) end
  return ns.Util.KeyFor(name, surname)
end
local function frame() return rawget(G, "DeathNoteFrame") end
local function open() if not (frame() and frame():IsShown()) then ns:Fire("TOGGLE_UI") end K.tick(); K.settle() end
local function poster()
  for _, f in ipairs(BM.frames) do if f.enemy and f.death then return f end end
end
local function visibleText(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end

------------------------------------------------------------------------
-- Order by open debt, top title only for an open case (decision 4)
------------------------------------------------------------------------
do
  world("deDE")
  local anna = killsMe("Anna", "Ast", 3)
  local grimm = killsMe("Grimm", "Bart", 1)
  iKill("Anna", "Ast", 3)
  open()
  ns.UI.ShowEnemy(anna); K.tick(); K.settle()
  local P = poster()
  check("even enemy: no public enemy stamp on his poster", not P.enemy.stampNr1:IsShown())
  check("even enemy: no rank in the alarm title", ns.Store.Rank(anna) == nil)
  ns.UI.ShowEnemy(grimm); K.tick(); K.settle()
  check("the open one is rank 1 and carries the stamp", ns.Store.Rank(grimm) == 1 and P.enemy.stampNr1:IsShown())
  -- the list: Grimm first (rank 1, red), Anna after him without a number
  ns.UI.SetFilter("wanted"); K.tick()
  local rows = {}
  for _, f in ipairs(BM.frames) do
    if f.item and f.under and f:IsVisible() then rows[#rows + 1] = f end
  end
  table.sort(rows, function(a, b) return (a.index or 0) < (b.index or 0) end)
  check("list: open debt first", rows[1] and rows[1].item.key == grimm, rows[1] and rows[1].item.key)
  check("list: the settled one without a rank number", rows[2] and rows[2].item.key == anna and (rows[2].rank._text or "") == "",
    rows[2] and rows[2].rank._text)
  -- alarm for the even one: the ordinary title, never the top title
  ns:Fire("TOGGLE_UI"); K.tick()
  AM.AddEnemy("target", { name = "Anna", surname = "Ast", guid = "Player-93-AnnaAst", level = 40, class = "ROGUE" })
  AM.FireEvent("PLAYER_TARGET_CHANGED"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  check("alarm of an even enemy: no public enemy No. 1 title", popup and popup:IsShown() and popup.title._text == ns.L.ALERT_SIGHTED,
    popup and popup.title._text)
  K.settle()
  -- everyone settled: nobody carries the title
  iKill("Grimm", "Bart", 1)
  check("all settled: no rank 1", ns.Store.Rank(grimm) == nil and ns.Store.Rank(anna) == nil)
  check("no errors (order)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("rap sheet in the book")
