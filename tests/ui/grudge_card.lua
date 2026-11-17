-- 1.4.0 grudge: the small notice on the right edge (GrudgeCard.lua) with the real logic (Grudge.lua, Store.lua).
-- Built hidden at READY; shows only when it asks something; tick enters, cross does not; the killing blow carries a
-- skull, who my death put into the book stands as "in the book" without buttons; 8 rows at most ("… and n more"),
-- the open ones come up as the others are answered; the time runs from the end of the fight, the mouse holds it;
-- Shift-drag moves it (kept), the House Rules put it back; right click closes it. After my death it waits for the
-- death's notice (one event, one window). In the book: core line "attacked 1×", stamp GRUDGE, the deed's role, the
-- alarm for an entry with attacks only, the section on the House Rules. No overlap in 21 languages (8 and 12 rows).
-- Use: luajit tests/ui/grudge_card.lua [project folder]
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local ns = AM.Load({ noLogin = true })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Humor.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  _G.UnitAffectingCombat = function(u) local x = AM.units[u]; return x ~= nil and x.combat ~= false end
  _G.UnitInParty = function() return false end
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.card() return rawget(BM.G, "DeathNoteGrudge") end
  function W.enemy(token, name, surname, o)
    o = o or {}
    o.name, o.surname, o.guid, o.target = name, surname, "Player-93-" .. name, "player"
    AM.AddEnemy(token, o)
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  end
  function W.fight(list)
    AM.inCombat = true; AM.FireEvent("PLAYER_REGEN_DISABLED")
    for i, x in ipairs(list) do W.enemy("nameplate" .. i, x[1], x[2], x[3]) end
    W.tick(0.5)
    AM.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 100, 1)
    W.tick(0.5)
    AM.inCombat = false; AM.FireEvent("PLAYER_REGEN_ENABLED")
  end
  function W.run(sec, step)
    step = step or 0.5
    for _ = 1, math.floor(sec / step + 0.5) do ns.GrudgeCard.Tick(step); W.tick(step) end
  end
  return W
end

local function shownRows(card)
  local out = {}
  for _, r in ipairs(card.rows) do if r:IsShown() and r.row then out[#out + 1] = r end end
  return out
end

------------------------------------------------------------------------
-- 1) Built hidden; tick and cross; the time; the mouse holds it
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns = W.ns
  local card = W.card()
  check("built at READY, hidden", card ~= nil and not card:IsShown())
  local p = card and card._points[1]
  check("default place: right edge, inward and up", p and p[1] == "RIGHT" and p[3] == "RIGHT" and p[4] < -60 and p[5] > 0,
    p and table.concat({ tostring(p[1]), tostring(p[3]), tostring(p[4]), tostring(p[5]) }, " "))
  W.fight({ { "Grimm", "Bart", { class = "ROGUE", level = 38 } }, { "Fies", "Ling", { class = "MAGE", level = 40 } } })
  check("shown after the attack", card:IsShown())
  check("head ATTACKED (spaced)", (card.head._text or ""):gsub(" ", "") == "ANGEGRIFFEN", card.head._text)
  local rows = shownRows(card)
  check("two rows", #rows == 2, #rows)
  local r1 = rows[1]
  check("row: name, level, tick and cross", r1 and r1.name._text == "Grimm Bart" and r1.level._text == "38" and r1.yes:IsShown()
    and r1.no:IsShown() and not r1.state:IsShown(), r1 and r1.name._text)
  check("no skull without a killing blow", r1 and not r1.mark:IsShown())
  -- 1.4.0 fixer (orchestrator, hunt UI 1): one layer above the open book (HIGH), the lowest level of DIALOG
  check("one layer above the book, lowest in DIALOG", card:GetFrameStrata() == "DIALOG" and card:GetFrameLevel() == 1)
  -- tick on Grimm, cross on Fies
  r1.yes._scripts.OnClick(r1.yes)
  local e = ns.Store.Get("Grimm-Bart")
  check("tick: in the book with an attack", e and e.attacks == 1 and e.manual == false and e.status == "wanted")
  check("tick: row says entered, buttons gone", r1.state:IsShown() and r1.state._text == "eingetragen" and not r1.yes:IsShown(), r1.state._text)
  rows[2].no._scripts.OnClick(rows[2].no)
  check("cross: nothing in the book", ns.Store.Get("Fies-Ling") == nil)
  check("cross: row says skipped", rows[2].state._text == "verworfen", rows[2].state._text)
  W.run(2)
  check("all answered: gone a moment later", not card:IsShown() and ns.Grudge.Current() == nil)

  -- the time: 20 s from the end of the fight; the mouse over it holds it
  W.tick(400)
  W.fight({ { "Dritter", "Mann" } })
  check("new attack: shown", card:IsShown())
  local full = card.bar:GetWidth()
  W.run(10)
  check("bar shrinks", card.bar:GetWidth() < full * 0.6, card.bar:GetWidth())
  card.IsMouseOver = function() return true end
  W.run(30)
  check("mouse over: still there after 40 s", card:IsShown())
  card.IsMouseOver = nil
  W.run(11)
  check("mouse away: gone after the rest of the 20 s", not card:IsShown())
  check("gone = not entered", ns.Store.Get("Dritter-Mann") == nil)

  -- 10 s setting
  ns.Store.Setting("grudge.seconds", 10)
  W.tick(400)
  W.fight({ { "Vierter", "Mann" } })
  W.run(9)
  check("10 s: still there at 9 s", card:IsShown())
  W.run(2)
  check("10 s: gone at 11 s", not card:IsShown())

  -- right click closes; Shift-drag moves and keeps the place; reset puts it back
  W.tick(400)
  W.fight({ { "Fuenfter", "Mann" } })
  card._scripts.OnDragStart(card)
  check("drag without Shift: no move", not card._moving)
  W.BM.shift = true
  card._scripts.OnDragStart(card)
  check("Shift-drag: moves", card._moving)
  card:ClearAllPoints(); card:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
  card._scripts.OnDragStop(card)
  W.BM.shift = false
  local pt = ns.Store.Setting("grudge.point")
  check("place kept", type(pt) == "table" and pt[1] == "TOPLEFT" and pt[3] == 300 and pt[4] == -200)
  check("not in layout-local.txt", card._userPlaced == false)
  ns.GrudgeCard.ResetPosition()
  local p2 = card._points[1]
  check("reset: default place, setting gone", ns.Store.Setting("grudge.point") == nil and p2[1] == "RIGHT" and p2[4] == -110)
  card._scripts.OnMouseUp(card, "RightButton")
  check("right click: closed, nothing entered", not card:IsShown() and ns.Store.Get("Fuenfter-Mann") == nil)
  -- nothing to ask (everybody answered lately): no notice
  W.tick(10)
  W.fight({ { "Fuenfter", "Mann" } })
  check("answered lately: no notice", not card:IsShown())
end

------------------------------------------------------------------------
-- 2) Test notice, killing blow, "in the book", many attackers
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns = W.ns
  local card = W.card()
  ns.HandleSlash("rachsucht test")
  check("test: shown", card:IsShown())
  local rows = shownRows(card)
  check("test: three made-up attackers", #rows == 3, #rows)
  check("test: killing blow first, skull, in the book, no buttons", rows[1].mark:IsShown() and rows[1].state._text == "im Buch"
    and not rows[1].yes:IsShown(), rows[1].state._text)
  rows[2].yes._scripts.OnClick(rows[2].yes)
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  check("test: a tick enters nothing", n == 0, n)
  ns.Grudge.Close("test")

  -- 12 attackers: 7 rows and "… and 5 more"; the open ones come up as the others are answered
  W.tick(400)
  local list = {}
  for i = 1, 12 do list[i] = { "Angreifer" .. string.char(64 + i), "Bande" } end
  W.fight(list)
  rows = shownRows(card)
  check("12: seven rows", #rows == 7, #rows)
  check("12: and 5 more", card.more:IsShown() and (card.more._text or ""):find("5", 1, true) ~= nil, card.more._text)
  local h = card:GetHeight()
  check("12: height for 8 lines", h == ns.GrudgeCard.HEAD_H + 8 * ns.GrudgeCard.ROW_H + ns.GrudgeCard.FOOT, h)
  -- the mouse over the notice: the rows stay where they are while it clicks (a double click must not answer the
  -- next attacker), so a second click on the same place does nothing
  card.IsMouseOver = function() return true end
  local first = rows[1].row.key
  rows[1].no._scripts.OnClick(rows[1].no)
  rows[1].no._scripts.OnClick(rows[1].no)
  check("12: rows stand still under the mouse", rows[1].row.key == first and rows[2].yes:IsShown(), rows[1].row.key)
  local answered = 0
  for _, r in ipairs(ns.Grudge.Rows()) do if r.state then answered = answered + 1 end end
  check("12: a double click answers one attacker", answered == 1, answered)
  for i = 2, 7 do rows[i].no._scripts.OnClick(rows[i].no) end
  local open = 0
  for _, r in ipairs(shownRows(card)) do if r.yes:IsShown() then open = open + 1 end end
  check("12: under the mouse the answered stay in place", open == 0, open)
  card.IsMouseOver = nil
  W.run(0.5)
  open = 0
  for _, r in ipairs(shownRows(card)) do if r.yes:IsShown() then open = open + 1 end end
  check("12: mouse away: the other five come up", open == 5, open)
  check("12: still asking", card:IsShown())
  ns.Grudge.Close("test")
end

------------------------------------------------------------------------
-- 3) After my death: first the death's notice, then this one
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns, AM = W.ns, W.AM
  local card = W.card()
  AM.inCombat = true; AM.FireEvent("PLAYER_REGEN_DISABLED")
  W.enemy("nameplate1", "Nur", "Gesehen")
  AM.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 100, 1)
  W.tick(0.2)
  check("death: the notice is up during the fight", card:IsShown())
  AM.recap = { id = 9, events = {
    { sourceGUID = "Player-93-Fies", sourceName = "Fies Ling", amount = 900, overkill = 50, timestamp = _G.time() - 1, spellName = "Hieb" } } }
  AM.FireEvent("PLAYER_DEAD"); AM.inCombat = false; AM.FireEvent("PLAYER_REGEN_ENABLED")
  W.tick(0.6)
  local banner = rawget(W.G, "DeathNoteBanner")
  check("death: the death's notice shows", banner and banner:IsShown())
  check("death: the grudge notice is not beside it", not card:IsShown())
  for _ = 1, 30 do W.tick(0.5); if not banner:IsShown() then break end end
  W.BM.FinishAnims(); W.tick(1); W.BM.FinishAnims(); W.tick(1)
  check("death: the death's notice has gone", not banner:IsShown())
  check("death: now the grudge notice", card:IsShown())
  local rows = shownRows(card)
  check("death: killer first with skull, in the book; the one only seen asks", #rows == 2 and rows[1].mark:IsShown()
    and rows[1].state._text == "im Buch" and rows[2].yes:IsShown(), #rows)
  ns.Grudge.Close("test")
end

------------------------------------------------------------------------
-- 4) The book: core line, stamp, deed role, alarm, House Rules
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns, G = W.ns, W.G
  local t = _G.time()
  local key = ns.Store.AddAttack({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 38, guid = "Player-93-Grimm" },
    { t = t - 60, zone = "Schlingendorntal", subzone = "Grom'gol", me = "Varorak Narenmar", myLevel = 40 })
  check("Look.Tally: attacked 1×", ns.Look.Tally(ns.Store.Get(key)) == "1× angegriffen", ns.Look.Tally(ns.Store.Get(key)))
  local both = ns.Store.AddManual("Hand", "Arbeit")
  ns.Store.AddAttack({ name = "Hand", surname = "Arbeit" }, { t = t - 30, zone = "Z" })
  check("Look.Tally: by hand and attacked", ns.Look.Tally(ns.Store.Get(both)) == "von Hand eingetragen · 1× angegriffen",
    ns.Look.Tally(ns.Store.Get(both)))
  -- a second entry with a kill, so Grimm is no rank 1 (the stamp No. 1 would take the place)
  ns.Store.ApplyKill({ name = "Erster", surname = "Platz" }, { t = t - 500, zone = "Z", source = "recap" }, true)
  ns:Fire("TOGGLE_UI"); W.tick()
  ns.UI.ShowEnemy(key); W.tick()
  local E
  for _, f in ipairs(W.BM.frames) do if f.enemy and f.enemy.tally then E = f.enemy end end
  check("poster: core line", E and (E.tally._text or ""):find("angegriffen", 1, true) ~= nil, E and E.tally._text)
  check("poster: stamp GRUDGE", E and E.stampOther:IsShown() and E.stampOther.label and E.stampOther.label._text == "RACHSUCHT",
    E and E.stampOther.label and E.stampOther.label._text)
  local tagged = false
  for _, b in ipairs(E and E.lines or {}) do if b.tag and b.tag._text == "angegriffen" then tagged = true end end
  check("poster: deed with role attacked", tagged)
  ns.UI.ShowEnemy(both); W.tick()
  check("poster: by hand too: no stamp GRUDGE", not (E.stampOther:IsShown() and E.stampOther.label._text == "RACHSUCHT"))
  -- alarm: an entry with attacks only warns (like one by hand)
  W.AM.AddEnemy("target", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" })
  W.AM.FireEvent("PLAYER_TARGET_CHANGED"); W.tick()
  local popup = rawget(G, "DeathNoteAlert")
  check("alarm for an entry with attacks only", popup and popup:IsShown())
  check("alarm line: attacked, not 'by hand'", popup and (popup.line._text or ""):find("1× angegriffen", 1, true) ~= nil
    and not (popup.line._text or ""):find("von Hand", 1, true), popup and popup.line._text)
  -- House Rules: sheet 4, the section and its switches
  ns.UI.OpenPanel("settings"); W.tick()
  local S
  for _, f in ipairs(W.BM.frames) do if f.settings and f.settings.tabs then S = f.settings end end
  S.tabs[4]._scripts.OnClick(S.tabs[4]); W.tick()
  local cbOn, cbBg
  for _, cb in ipairs(S.checks) do
    if cb.opt.path == "grudge.enabled" then cbOn = cb elseif cb.opt.path == "grudge.battlegrounds" then cbBg = cb end
  end
  check("House Rules: on (ticked) and battlegrounds (not ticked)", cbOn and cbOn:GetChecked() and cbBg and not cbBg:GetChecked())
  cbBg:SetChecked(true); cbBg._scripts.OnClick(cbBg)
  check("House Rules: battlegrounds switched on", ns.Store.Setting("grudge.battlegrounds") == true)
  check("House Rules: duration 20 s", S.gsec._text == "20 s", S.gsec._text)
  S.gsec.plus._scripts.OnClick(S.gsec.plus); W.tick()
  check("House Rules: duration 30 s", ns.Store.Setting("grudge.seconds") == 30 and S.gsec._text == "30 s", S.gsec._text)
  S.gsec.plus._scripts.OnClick(S.gsec.plus); S.gsec.plus._scripts.OnClick(S.gsec.plus)
  check("House Rules: 60 s at most", ns.Store.Setting("grudge.seconds") == 60)
  ns.Store.Setting("grudge.point", { "TOPLEFT", "TOPLEFT", 10, -10 })
  S.grudgeButtons[2]._scripts.OnClick(S.grudgeButtons[2])
  check("House Rules: reset position", ns.Store.Setting("grudge.point") == nil)
  S.grudgeButtons[1]._scripts.OnClick(S.grudgeButtons[1])
  check("House Rules: test notice", W.card():IsShown() and ns.Grudge.Current() and ns.Grudge.Current().test)
end

------------------------------------------------------------------------
-- 5) Nothing overlaps: 1, 3, 8, 12 rows with a killing blow, long names, 21 languages
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function overlap(a, b)
  return a[1] < b[3] - 0.5 and b[1] < a[3] - 0.5 and a[2] < b[4] - 0.5 and b[2] < a[4] - 0.5
end
for _, code in ipairs(CODES) do
  local W = world(code)
  local ns = W.ns
  local card = W.card()
  local worst
  for _, n in ipairs({ 1, 3, 8, 12 }) do
    ns.Grudge.Test(n)
    -- long names and every state on the notice
    local e = ns.Grudge.Current()
    for i, k in ipairs(e.order) do
      local r = e.rows[k]
      r.surname = "Wunderkammerlein" .. i
      if i == 2 then r.state = "yes" elseif i == 3 then r.state = "no" end
    end
    ns.GrudgeCard.Fill(e)
    local parts = {}
    for _, fr in ipairs(card.rows) do
      if fr:IsShown() then
        for _, x in ipairs({ fr.name, fr.level, fr.state, fr.yes, fr.no, fr.mark }) do
          if x:IsShown() then
            local l, b, r, t = W.BM.RectUI(x)
            if l then parts[#parts + 1] = { l, b, r, t, x == fr.name and "name" or "part" } end
          end
        end
      end
    end
    if card.more:IsShown() then
      local l, b, r, t = W.BM.RectUI(card.more); parts[#parts + 1] = { l, b, r, t, "more" }
    end
    local cl, cb, cr, ct = W.BM.RectUI(card)
    for i = 1, #parts do
      local a = parts[i]
      if a[1] < cl - 0.5 or a[3] > cr + 0.5 or a[2] < cb - 0.5 or a[4] > ct + 0.5 then worst = worst or (n .. " rows: out of the notice") end
      for j = i + 1, #parts do
        if overlap(a, parts[j]) then worst = worst or (n .. " rows: overlap " .. a[5] .. "/" .. parts[j][5]) end
      end
    end
    -- the head fits
    if ns.Look.IsCut and ns.Look.IsCut(card.head) then worst = worst or "head cut" end
    ns.Grudge.Close("test")
  end
  check(code .. ": nothing overlaps or sticks out (1, 3, 8, 12 rows)", worst == nil, worst)
end

io.write(("grudge notice UI: %d gruen, %d rot\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
