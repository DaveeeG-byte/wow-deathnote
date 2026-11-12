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

------------------------------------------------------------------------
-- The standing in the book: row, poster with its stamps, tooltip, alarm line, revenge notice
------------------------------------------------------------------------
local function rowOf(key)
  for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == key then return f end end
end
local function stampWord(tex) return tex:IsShown() and tex.label and tex.label:IsShown() and tex.label._text or (tex:IsShown() and "(picture)") or nil end
local function hoverUnit(name, surname)
  local tt = G.GameTooltip
  tt._unitName, tt._unit, tt._lines = name, "mouseover", {}
  AM.AddEnemy("mouseover", { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  if BM.tooltipHook then BM.tooltipHook(tt, {}) end
  return table.concat(tt._lines or {}, "\n")
end
for _, code in ipairs({ "deDE", "enUS" }) do
  world(code)
  local L = ns.L
  local open1 = killsMe("Olaf", "Offen", 3); iKill("Olaf", "Offen", 1)          -- 1 : 3 open
  local even = killsMe("Erna", "Eben", 2); iKill("Erna", "Eben", 2)            -- 2 : 2 even
  local ahead = killsMe("Udo", "Ueber", 1); iKill("Udo", "Ueber", 3)           -- 3 : 1 ahead
  local plain = killsMe("Paul", "Pur", 2)                                        -- 0 : 2 open, no kill of mine
  open(); ns.UI.SetFilter("wanted"); K.tick()
  local function score(m, h) return m .. " : " .. h end
  local r = rowOf(open1)
  check(code .. ": open row shows the score, red, no 'REVENGE'", r and r.mark._text == score(1, 3), r and r.mark._text)
  r = rowOf(even)
  check(code .. ": even row: score in ink, pale, state word first", r and r.mark._text == score(2, 2) and (r.sub._text or ""):find(L.STATE_EVEN, 1, true) == 1,
    r and (r.mark._text .. " | " .. tostring(r.sub._text)))
  r = rowOf(plain)
  check(code .. ": no kill of mine: no mark (as 1.2.2 without revenge)", r and (r.mark._text or "") == "", r and r.mark._text)
  local P = poster()
  local want = { [open1] = L.STAMP_REVENGE, [even] = L.STAMP_QUITT, [ahead] = L.STAMP_OVERPAID }
  for key, word in pairs(want) do
    ns.UI.ShowEnemy(key); K.tick(); K.settle()
    local got = stampWord(P.enemy.stampRache)
    local ok = got == word or (code == "deDE" and word == L.STAMP_REVENGE and got == "(picture)")
    check(code .. ": second stamp of " .. key, ok, got)
    check(code .. ": at most two stamps on " .. key, (P.enemy.stampNr1:IsShown() and 1 or 0) + (P.enemy.stampOther:IsShown() and 1 or 0) + (P.enemy.stampRache:IsShown() and 1 or 0) <= 2)
    check(code .. ": no count next to the stamp", not P.enemy.racheCount:IsShown())
    check(code .. ": key number is the score", (P.enemy.tally._text or ""):find(L.STAND_LINE:gsub("{score}.*", ""), 1, true) ~= nil, P.enemy.tally._text)
  end
  ns.UI.ShowEnemy(plain); K.tick(); K.settle()
  check(code .. ": 0 : 2 has no second stamp", not P.enemy.stampRache:IsShown())
  -- tooltip
  local tip = hoverUnit("Erna", "Eben")
  check(code .. ": tooltip: score and state, no revenge count", tip:find(score(2, 2), 1, true) and tip:find(L.STATE_EVEN, 1, true)
    and not tip:find(L.TIP_REVENGE:gsub("{times}.*", ""), 1, true), tip)
  -- a victim not in the book
  iKill("Viktor", "Vogt", 2)
  tip = hoverUnit("Viktor", "Vogt")
  check(code .. ": tooltip of a victim", tip:find(L.TIP_IN_RECORD, 1, true) ~= nil, tip)
  -- alarm line
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  AM.AddEnemy("target", { name = "Udo", surname = "Ueber", guid = "Player-93-UdoUeber", level = 40, class = "ROGUE" })
  AM.FireEvent("PLAYER_TARGET_CHANGED"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  local line = popup and popup.line._text or ""
  check(code .. ": alarm line with the score and the state", line:find(score(3, 1), 1, true) and line:find(L.STATE_AHEAD, 1, true), line)
  K.settle(); AM.Advance(200); K.tick()
  -- revenge notice: second line is the score
  ns.Store.AddRevenge(plain); K.tick()
  local b = rawget(G, "DeathNoteBanner")
  check(code .. ": revenge notice shows the score", b and b:IsShown() and (b.line._text or ""):find(score(1, 2), 1, true), b and b.line._text)
  K.settle()
  check(code .. ": no errors (standing)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

------------------------------------------------------------------------
-- Rap sheet off: the book as in 1.2.2 (revenge mark, revenge stamp with count, old tooltip, old alarm line)
------------------------------------------------------------------------
do
  world("deDE")
  local L = ns.L
  local k = killsMe("Olaf", "Offen", 3); iKill("Olaf", "Offen", 1)
  ns.Store.Setting("ledger.enabled", false)
  open(); ns.UI.SetFilter("wanted"); K.tick()
  local r = rowOf(k)
  check("off: revenge mark as 1.2.2", r and r.mark._text == L.MARK_REVENGE:gsub("{times}", ns.Look.Times(1)), r and r.mark._text)
  ns.UI.ShowEnemy(k); K.tick(); K.settle()
  local P = poster()
  check("off: revenge stamp with its count", P.enemy.stampRache:IsShown() and P.enemy.racheCount:IsShown())
  check("off: key number is the tally", P.enemy.tally._text == ns.Look.Tally(ns.Store.Get(k)), P.enemy.tally._text)
  local tip = hoverUnit("Olaf", "Offen")
  check("off: tooltip without the score", not tip:find(L.STAND_LINE:gsub(" {score}", ""), 1, true), tip)
end

K.done("rap sheet in the book")
