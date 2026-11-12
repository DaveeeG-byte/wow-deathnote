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

------------------------------------------------------------------------
-- The fifth tab: comes with the first own kill and stays; off with the rap sheet; round trips without new objects
------------------------------------------------------------------------
local function tab(id) for _, f in ipairs(BM.frames) do if f.id == id and f.mark and f._scripts and f._scripts.OnClick then return f end end end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); K.tick() end
local function record() return poster() and poster().record end
for _, code in ipairs({ "deDE", "enUS" }) do
  world(code)
  local L = ns.L
  killsMe("Olaf", "Offen", 2)
  open()
  check(code .. ": no own kill: no fifth tab", not tab("record"):IsShown())
  local shownBefore = 0
  for _, t in ipairs(rawget(G, "DeathNoteFrame").tabs) do if t:IsShown() then shownBefore = shownBefore + 1 end end
  iKill("Olaf", "Offen", 1)
  K.tick()
  check(code .. ": the first own kill brings the tab (book open, no rebuild)", tab("record"):IsShown())
  -- the five tabs stay inside the row (x = 184 to 704) and do not overlap
  local F = rawget(G, "DeathNoteFrame")
  local last, inside = nil, true
  for _, t in ipairs(F.tabs) do
    if t:IsShown() then
      local l, _, r = BM.RectUI(t)
      local fl = BM.RectUI(F)
      if l - fl < 183.5 or r - fl > 704.5 or (last and l < last - 0.5) then inside = false end
      last = r
    end
  end
  check(code .. ": five tabs fit the row", inside)
  click(tab("record"))
  local R = record()
  check(code .. ": the file shows", R and R:IsShown() and R.file:IsShown())
  local created = BM.created
  -- victim sheet and back, log and back, sort, other tabs, close and open
  local row
  for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == "Olaf-Offen" then row = f end end
  click(row)
  check(code .. ": click on a victim shows its sheet", R.vic:IsShown() and not R.file:IsShown())
  check(code .. ": the victim sheet names him", (R.vic.head._text or "") == "Olaf Offen", R.vic.head._text)
  click(row)
  check(code .. ": a second click goes back to the file", R.file:IsShown() and not R.vic:IsShown())
  click(R.file.word)
  check(code .. ": Show more: the latest kills", R.log:IsShown() and R.log.lines[1]:IsShown())
  click(R.log.word)
  check(code .. ": back to the file", R.file:IsShown())
  for i = 1, 500 do
    click(tab(i % 2 == 0 and "record" or "wanted"))
    if i % 50 == 0 then click(row); click(R.file:IsShown() and R.file.word or R.log.word) end
  end
  ns:Fire("TOGGLE_UI"); K.tick(); ns:Fire("TOGGLE_UI"); K.tick()
  check(code .. ": 500 tab changes and views: no new objects", BM.created == created, BM.created - created)
  -- an own kill while the tab is open: the page follows (same objects)
  click(tab("record"))
  local before = BM.created
  iKill("Grete", "Gast", 1); K.tick()
  local found = false
  for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == "Grete-Gast" then found = true end end
  check(code .. ": an own kill shows up in the open list at once", found)
  check(code .. ": ...without new objects", BM.created == before, BM.created - before)
  -- sort menu of the tab
  local sortBtn
  for _, f in ipairs(BM.frames) do if f.arrow and f.ul and f._scripts and f._scripts.OnClick then sortBtn = f end end
  click(sortBtn)
  local menu = rawget(G, "DeathNoteMenu")
  local items = {}
  for _, b in ipairs(menu.items) do if b:IsShown() then items[#items + 1] = b.text._text end end
  check(code .. ": sort menu of the rap sheet", #items == 5 and items[5]:find(L.SORT_NAME, 1, true), table.concat(items, "|"))
  menu.items[5]._scripts.OnClick(menu.items[5]); K.tick()
  check(code .. ": sorted by name", ns.Store.Setting("ui.recordSort") == "name")
  -- clear: the tab stays (the rank keeps the count), the list is empty, the file is there
  ns.Ledger.Clear(); K.tick()
  check(code .. ": after clearing, the tab stays and shows the file", tab("record"):IsShown() and R.file:IsShown())
  -- the rap sheet off: no tab, back to Wanted
  ns.Store.Setting("ledger.enabled", false); K.tick()
  check(code .. ": rap sheet off: tab gone, Wanted again", not tab("record"):IsShown() and tab("wanted").mark:IsShown())
  ns.Store.Setting("ledger.enabled", true); K.tick()
  check(code .. ": no errors (tab)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

------------------------------------------------------------------------
-- Notices: a chat line after an own kill, a notice for a new rank and an award (never in combat)
------------------------------------------------------------------------
do
  world("deDE")
  local L = ns.L
  local chat = {}
  ns.Util.Print = function(t) chat[#chat + 1] = tostring(t) end
  iKill("Fritz", "Frech", 1)
  local line
  for _, c in ipairs(chat) do if c:find("Fritz Frech", 1, true) then line = c end end
  check("chat line after an own kill", line and line:find(L.BAND_GELB, 1, true), table.concat(chat, " / "))
  local b = rawget(G, "DeathNoteBanner")
  check("first kill: the award notice (First Entry)", b and b:IsShown() and b.name._text == ns.Humor.Award("first_entry"), b and b.name._text)
  K.settle(); AM.Advance(30); K.settle()
  ns.Store.Setting("ledger.chat", false)
  local n = #chat
  iKill("Fritz", "Frech", 1, 10)   -- a grey one
  check("ledger.chat off: no chat line", #chat == n, chat[#chat])
  -- rank notice waits for the end of combat
  BM.combat = true; _G.InCombatLockdown = function() return true end; rawset(G, "InCombatLockdown", function() return true end)
  K.settle()
  ns:Fire("REPUTE_RANK", 3, "e", 2, nil); K.tick()
  check("no rank notice in combat", not b:IsShown() or b.name._text ~= ns.Ranks.Title(3, "e"))
  BM.combat = false; _G.InCombatLockdown = function() return false end; rawset(G, "InCombatLockdown", function() return false end)
  AM.FireEvent("PLAYER_REGEN_ENABLED"); K.tick()
  check("after combat: the rank notice", b:IsShown() and b.name._text == ns.Ranks.Title(3, "e"), b.name._text)
  K.settle()
  check("no errors (notices)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

------------------------------------------------------------------------
-- House Rules, sheet Rap Sheet: the switches write their settings
------------------------------------------------------------------------
do
  world("enUS")
  iKill("Fritz", "Frech", 1)
  open()
  ns.UI.OpenPanel("settings"); K.tick()
  local RPf
  for _, f in ipairs(BM.frames) do if f.settings and f.help ~= nil or (f.settings and f.io) then RPf = f end end
  local S = RPf.settings
  S.tabs[4]._scripts.OnClick(S.tabs[4]); K.tick()
  check("sheet 4 shows", S.pageR:IsShown())
  local want = { ["ledger.enabled"] = true, ["ledger.chat"] = true, ["alert.victims"] = true }
  for _, cb in ipairs(S.checks) do
    if want[cb.opt.path] then
      local before = ns.Store.Setting(cb.opt.path)
      cb:SetChecked(not cb:GetChecked()); cb._scripts.OnClick(cb); K.tick()
      check("switch writes " .. cb.opt.path, ns.Store.Setting(cb.opt.path) == not before, tostring(ns.Store.Setting(cb.opt.path)))
      cb:SetChecked(not cb:GetChecked()); cb._scripts.OnClick(cb); K.tick()
    end
  end
  S.settled.plus._scripts.OnClick(S.settled.plus); K.tick()
  check("settled: as usual -> quiet", ns.Store.Setting("alert.settled") == "quiet", ns.Store.Setting("alert.settled"))
  S.settled.plus._scripts.OnClick(S.settled.plus); S.settled.plus._scripts.OnClick(S.settled.plus); K.tick()
  check("settled: round trip", ns.Store.Setting("alert.settled") == "always")
  check("no errors (house rules)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("rap sheet in the book")
