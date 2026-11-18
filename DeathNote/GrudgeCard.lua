local ADDON, ns = ...

-- 1.4.0 grudge: the small notice on the right edge after an attack (the episode lives in Grudge.lua).
-- A head "ATTACKED", one row per attacker (class ink, name, level, tick and cross), the killing blow with a skull, who
-- my death put into the book anyway with "in the book" and no buttons; at most ROWS rows, then "… and n more". A thin
-- bar counts the time down (Grudge.Seconds after the fight or the last new attacker); the mouse over the notice holds
-- it. Gone = not entered. a drag moves it (kept in grudge.point; no Shift needed since 1.5.0), a right click closes it. No sound.
-- One event, one window: after my death the notice waits until the death's notice (Extras.lua) has gone.
-- The OnUpdate runs only while the notice is shown (the bar), never for logic.
-- 1.5.0 grip: a "probable" row (Grudge.Grade: seen targeting me at one hit only) carries a faint "?" in the skull
-- column and paler ink; the row's tooltip says why. The size (grudge.size: small, medium, large) scales the notice.

local Look = ns.Look
local L, Fmt = ns.L, ns.F
local Card = {}
ns.GrudgeCard = Card

Card.W = 210              -- width
Card.PAD = 8
Card.HEAD_H = 22          -- head line and the rule under it
Card.ROW_H = 18
Card.ROWS = 8             -- rows shown; one more becomes "… and n more"
Card.BAR_H = 2
Card.FOOT = 8             -- room under the rows for the bar
Card.BTN = 16             -- tick and cross
Card.LEVEL_W = 24
Card.STATE_W = 68         -- "in the book", "entered", "skipped" (where level and buttons stand)
Card.MARK_W = 14          -- the skull column
Card.DEFAULT = { "RIGHT", "RIGHT", -110, 80 }   -- right edge, a little inward (right action bars) and up
Card.STRATA, Card.LEVEL = "DIALOG", 1
Card.DONE_DELAY = 1.5     -- seconds the notice stays after the last answer
Card.WAIT_STEP, Card.WAIT_MAX = 0.5, 12   -- after a death: look every 0.5 s whether the death's notice has gone
Card.TICK = "Interface\\RaidFrame\\ReadyCheck-Ready"
Card.CROSS = "Interface\\RaidFrame\\ReadyCheck-NotReady"
Card.FIT_NAME = { sizes = { 11, 10, 9 } }
Card.FIT_STATE = { sizes = { 10, 9 } }
Card.FIT_HEAD = { sizes = { 10, 9 } }
Card.SCALES = { small = 0.85, medium = 1, large = 1.25 }   -- 1.5.0 grip: grudge.size
Card.SIZES = { "small", "medium", "large" }
Card.PROBABLE_ALPHA = 0.72   -- name ink of a probable row (a skipped one: 0.45)

local card
local shownId            -- id of the episode on the notice
local remaining          -- seconds left (nil while the fight runs)
local stamp              -- what the countdown last started from (end of the fight, last new attacker)
local waiting            -- the notice waits for the death's notice to go
local doneAt

local function C(c, a) return c[1], c[2], c[3], a or c[4] or 1 end
local function Setting(path, def) return Look.Setting(path, def) end

local function SavePoint()
  local p, _, rp, x, y = card:GetPoint(1)
  if p and ns.Store and ns.Store.Setting then ns.Store.Setting("grudge.point", { p, rp, x, y }) end
end

function Card.Place()
  if not card then return end
  card:ClearAllPoints()
  local pt = Setting("grudge.point")
  if type(pt) == "table" and type(pt[1]) == "string" and tonumber(pt[3]) and tonumber(pt[4]) then
    card:SetPoint(pt[1], UIParent, type(pt[2]) == "string" and pt[2] or pt[1], tonumber(pt[3]), tonumber(pt[4]))
  else
    local d = Card.DEFAULT
    card:SetPoint(d[1], UIParent, d[2], d[3], d[4])
  end
end

-- House Rules: back to the default place
function Card.ResetPosition()
  if ns.Store and ns.Store.Setting then ns.Store.Setting("grudge.point", nil) end
  Card.Place()
end

local function Tip(owner, lines)
  if not (GameTooltip and lines and lines[1]) then return end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText(lines[1], Look.BONE[1], Look.BONE[2], Look.BONE[3])
  for i = 2, #lines do GameTooltip:AddLine(lines[i], 0.82, 0.80, 0.75, true) end
  GameTooltip:Show()
end
local function TipHide() if GameTooltip then GameTooltip:Hide() end end

-- the row's tooltip: name, level and class, how he was found
local function RowTip(self)
  local r = self.row
  if not r then return end
  local t = { (ns.Util and ns.Util.Display and ns.Util.Display(r)) or r.name or "?" }
  local who = Look.Join(r.level and Fmt(L.POSTER_LEVEL, { level = r.level }) or nil, r.classLoc or nil)
  if who ~= "" then t[#t + 1] = who end
  if r.kb then t[#t + 1] = L.GRUDGE_TIP_KB end
  local p = r.proofs or {}
  if p.a then t[#t + 1] = L.GRUDGE_TIP_SEEN end
  if p.b then t[#t + 1] = L.GRUDGE_TIP_RECAP end
  if p.c then t[#t + 1] = L.GRUDGE_TIP_METER end
  -- 1.5.0 grip: the second signals, the creature, why a row is only probable
  if p.s then t[#t + 1] = L.GRUDGE_TIP_CAST end
  if p.j then t[#t + 1] = L.GRUDGE_TIP_JOIN end
  if p.r then t[#t + 1] = L.GRUDGE_TIP_REPEAT end
  if r.mob then t[#t + 1] = L.GRUDGE_TIP_MOB end
  if r.conf == "probable" then t[#t + 1] = L.GRUDGE_TIP_PROBABLE end
  Tip(self, t)
end

local function Answer(self, yes)
  local r = self:GetParent().row
  if not (r and ns.Grudge) then return end
  Look.Sound("click")
  ns.Grudge.Answer(r.key, yes)
end

local function MakeButton(parent, path, fb, yes)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(Card.BTN, Card.BTN)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  Look.Tex(b.icon, path, fb[1], fb[2], fb[3], 1)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.12))
  b:SetScript("OnClick", function(self) Answer(self, yes) end)
  b:SetScript("OnEnter", function(self) Tip(self, { yes and L.GRUDGE_TIP_YES or L.GRUDGE_TIP_NO }) end)
  b:SetScript("OnLeave", TipHide)
  return b
end

local function MakeRow(i)
  local r = CreateFrame("Frame", nil, card)
  r:SetSize(Card.W - 2 * Card.PAD, Card.ROW_H)
  r:SetPoint("TOPLEFT", Card.PAD, -(Card.HEAD_H + (i - 1) * Card.ROW_H))
  r:EnableMouse(true)
  if r.SetMouseClickEnabled then r:SetMouseClickEnabled(false) end   -- right click goes on to the notice
  r.mark = r:CreateTexture(nil, "ARTWORK")
  r.mark:SetSize(12, 12)
  r.mark:SetPoint("LEFT", 0, 0)
  Look.Skin(r.mark, "skull")
  local st = Look.COLOR.skullTint
  if st then r.mark:SetVertexColor(C(st)) end
  -- 1.5.0 grip: "?" of a probable row, in the skull column (a probable row never carries the skull)
  r.maybe = Look.Text(r, "body", 11, Look.INK)
  r.maybe:SetPoint("LEFT", 2, 0)
  r.maybe:SetWidth(Card.MARK_W - 2)
  r.maybe:SetJustifyH("LEFT")
  r.maybe:SetText("?")
  r.maybe:SetTextColor(C(Look.INK, 0.5))
  r.maybe:Hide()
  r.no = MakeButton(r, Card.CROSS, { 0.6, 0.1, 0.1 }, false)
  r.no:SetPoint("RIGHT", 0, 0)
  r.yes = MakeButton(r, Card.TICK, { 0.1, 0.5, 0.1 }, true)
  r.yes:SetPoint("RIGHT", r.no, "LEFT", -4, 0)
  r.level = Look.Text(r, "body", 10, Look.INK)
  r.level:SetPoint("RIGHT", r.yes, "LEFT", -4, 0)
  r.level:SetWidth(Card.LEVEL_W)
  r.level:SetJustifyH("RIGHT")
  r.level:SetWordWrap(false)
  r.state = Look.Text(r, "body", 10, Look.INK)
  r.state:SetPoint("RIGHT", 0, 0)
  r.state:SetWidth(Card.STATE_W)
  r.state:SetJustifyH("RIGHT")
  r.state:SetWordWrap(false)
  r.name = Look.Text(r, "body", 11, Look.INK)
  r.name:SetPoint("LEFT", Card.MARK_W, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  r:SetScript("OnEnter", RowTip)
  r:SetScript("OnLeave", TipHide)
  return r
end

local function Build()
  card = CreateFrame("Frame", "DeathNoteGrudge", UIParent)
  card:SetSize(Card.W, Card.HEAD_H + Card.ROW_H + Card.FOOT)
  -- one layer above the book (HIGH: the notice is small and must not vanish under an open book), at the bottom of its
  -- layer so that menus and dialogs (DIALOG, raised when shown) stay above it; set before the rows are made
  card:SetFrameStrata(Card.STRATA)
  card:SetFrameLevel(Card.LEVEL)
  card:SetClampedToScreen(true)
  card:SetMovable(true)
  card:EnableMouse(true)
  card:RegisterForDrag("LeftButton")
  card:Hide()
  local bg = card:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  card.bg = bg
  local edge = card:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", 0, 0); edge:SetPoint("BOTTOMLEFT", 0, 0)
  edge:SetWidth(2)
  edge:SetColorTexture(C(Look.RED_INK, 0.8))
  card.head = Look.Text(card, "body", 10, Look.RED_INK)
  card.head:SetPoint("TOPLEFT", Card.PAD + 2, -6)
  card.head:SetWidth(Card.W - 2 * Card.PAD - 2)
  card.head:SetJustifyH("LEFT")
  card.head:SetWordWrap(false)
  local rule = card:CreateTexture(nil, "ARTWORK")
  rule:SetColorTexture(C(Look.INK, 0.35))
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", Card.PAD, -(Card.HEAD_H - 3)); rule:SetPoint("TOPRIGHT", -Card.PAD, -(Card.HEAD_H - 3))
  card.rows = {}
  for i = 1, Card.ROWS do card.rows[i] = MakeRow(i) end
  card.more = Look.Text(card, "body", 10, Look.INK)
  card.more:SetWidth(Card.W - 2 * Card.PAD - Card.MARK_W)
  card.more:SetJustifyH("LEFT")
  card.more:SetWordWrap(false)
  card.bar = card:CreateTexture(nil, "ARTWORK")
  card.bar:SetHeight(Card.BAR_H)
  card.bar:SetPoint("BOTTOMLEFT", Card.PAD, 4)
  card.bar:SetColorTexture(C(Look.RED_INK, 0.7))
  card.barW = Card.W - 2 * Card.PAD

  card:SetScript("OnMouseUp", function(_, mouse)
    if mouse == "RightButton" and ns.Grudge then ns.Grudge.Close("click") end
  end)
  card:SetScript("OnDragStart", function(self)
    self.moving = true
    self:StartMoving()
  end)
  card:SetScript("OnDragStop", function(self)
    if not self.moving then return end
    self.moving = nil
    self:StopMovingOrSizing()
    if self.SetUserPlaced then pcall(self.SetUserPlaced, self, false) end
    SavePoint()
  end)
  -- 1.4.0 fixer: the last line says how to turn it off (command, House Rules and sheet in the words of the cover)
  card:SetScript("OnEnter", function(self)
    Tip(self, { L.GRUDGE_HEAD, L.GRUDGE_TIP, Fmt(L.GRUDGE_TIP_OFF, { rules = L.HEAD_RULES, sheet = L.SHEET_RECORD }) })
  end)
  card:SetScript("OnLeave", TipHide)
  card:SetScript("OnUpdate", function(self, dt) Card.Tick(dt) end)
  Card.ApplySize()
  Card.Place()
end

-- 1.5.0 grip: the size of the notice (grudge.size), the whole notice scaled alike (the layout stays as it is)
function Card.Size()
  local v = Setting("grudge.size", "medium")
  return Card.SCALES[v] and v or "medium"
end
function Card.ApplySize()
  if not card then return end
  card:SetScale(Card.SCALES[Card.Size()])
end
Card.Build = function() if not card then Build() end return card end

-- class colour as ink on paper (as on the death's notice), unknown class: plain ink
local function Ink(class)
  local r, g, b = Look.ClassRGB(class)
  if class and ns.Extras and ns.Extras.SlipInk then return ns.Extras.SlipInk({ r, g, b }) end
  return Look.INK
end

local function FillRow(fr, r)
  fr.row = r
  fr:Show()
  fr.mark:SetShown(r.kb == true)
  local probable = r.conf == "probable" and r.kb ~= true
  fr.maybe:SetShown(probable)
  local ink = Ink(r.class)
  local open = ns.Grudge.Open(r)
  local word = (r.inBook and L.GRUDGE_IN_BOOK) or (r.state == "yes" and L.GRUDGE_ADDED)
    or ((r.state == "no" or r.state == "gone") and L.GRUDGE_SKIPPED) or nil
  fr.yes:SetShown(open)
  fr.no:SetShown(open)
  fr.level:SetShown(open)
  fr.level:SetText(r.level and tostring(r.level) or (r.skull and "??" or ""))
  fr.state:SetShown(word ~= nil)
  if word then Look.FitText(fr.state, word, Card.FIT_STATE) end
  local dim = r.state == "no" or r.state == "gone"
  fr.name:SetTextColor(ink[1], ink[2], ink[3], dim and 0.45 or (probable and Card.PROBABLE_ALPHA) or 1)
  fr.state:SetTextColor(C(Look.INK, (r.state == "yes" or r.inBook) and 0.9 or 0.5))
  local right = open and (Card.BTN * 2 + 4 + 4 + Card.LEVEL_W) or Card.STATE_W
  fr.name:SetWidth(Card.W - 2 * Card.PAD - Card.MARK_W - right - 4)
  Look.FitText(fr.name, (ns.Util and ns.Util.Display and ns.Util.Display(r)) or r.name or "?", Card.FIT_NAME)
end

-- the rows on the notice: all of them while they fit; with more, the open ones come first (after the killing blow)
-- and the answered ones give way, so every attacker reaches the notice as the others are answered. Never while the
-- mouse is over the notice: a row must not slide under the pointer between two clicks (a double click would answer
-- the next attacker); the order catches up when the mouse leaves (Card.Tick)
local frozen     -- keys in the order of the rows while the mouse is over the notice
local function Over()
  if not card then return false end
  local ok, v = pcall(card.IsMouseOver, card)
  return ok and v == true
end
function Card.Visible(e)
  local rows = e and ns.Grudge.Rows(e) or {}
  if #rows <= Card.ROWS then frozen = nil; return rows, #rows end
  if frozen and Over() then
    local byKey, out, seen = {}, {}, {}
    for i = 1, #rows do byKey[rows[i].key] = rows[i] end
    for i = 1, #frozen do
      local r = byKey[frozen[i]]
      if r then out[#out + 1] = r; seen[r] = true end
    end
    for i = 1, #rows do if not seen[rows[i]] then out[#out + 1] = rows[i] end end
    return out, #rows
  end
  local out, rest = {}, {}
  for i = 1, #rows do
    local r = rows[i]
    if r.kb or ns.Grudge.Open(r) then out[#out + 1] = r else rest[#rest + 1] = r end
  end
  for i = 1, #rest do out[#out + 1] = rest[i] end
  frozen = {}
  for i = 1, math.min(#out, Card.ROWS) do frozen[i] = out[i].key end
  Card.reflow = false
  return out, #rows
end

-- the notice for the episode e
function Card.Fill(e)
  if not card then Build() end
  local rows, n = Card.Visible(e)
  local shownRows = n > Card.ROWS and Card.ROWS - 1 or n
  for i = 1, Card.ROWS do
    if i <= shownRows then FillRow(card.rows[i], rows[i]) else card.rows[i]:Hide(); card.rows[i].row = nil end
  end
  local more = n - shownRows
  card.more:SetShown(more > 0)
  card.more:ClearAllPoints()
  card.more:SetPoint("TOPLEFT", Card.PAD + Card.MARK_W, -(Card.HEAD_H + shownRows * Card.ROW_H) - 3)
  if more > 0 then
    Look.FitText(card.more, Fmt(L.MORE_LINE, { count = more }), Card.FIT_STATE)
  end
  local lines = shownRows + (more > 0 and 1 or 0)
  card:SetHeight(Card.HEAD_H + lines * Card.ROW_H + Card.FOOT)
  local spaced = ns.Extras and ns.Extras.Spaced and ns.Extras.Spaced(L.GRUDGE_HEAD) or L.GRUDGE_HEAD
  Look.FitText(card.head, spaced, Card.FIT_HEAD)
end

local function Countdown(e)
  -- from the end of the fight, or from the last new attacker when he came later
  local from = e and not e.running and math.max(e.endGT or 0, e.lastNew or 0) or nil
  if from ~= stamp then
    stamp = from
    remaining = from and ns.Grudge.Seconds() or nil
  end
end

local function Bar()
  if not card then return end
  local total = ns.Grudge.Seconds()
  local f = remaining and math.max(0, math.min(1, remaining / total)) or 1
  card.bar:SetWidth(math.max(1, card.barW * f))
  card.bar:SetAlpha(remaining and 0.7 or 0.3)
end

-- the bar, and the end of the time (only while shown)
function Card.Tick(dt)
  local e = ns.Grudge and ns.Grudge.Current()
  if not e or e.id ~= shownId then card:Hide(); return end
  if doneAt then
    doneAt = doneAt - (tonumber(dt) or 0)
    if doneAt <= 0 then doneAt = nil; ns.Grudge.Close("done") end
    return
  end
  local over = Over()
  -- the mouse left after answers: the hidden attackers come up now
  if not over and frozen and Card.dirty then Card.dirty = false; Card.Fill(e) end
  if remaining and not over then
    remaining = remaining - (tonumber(dt) or 0)
    if remaining <= 0 then
      remaining = nil
      ns.Grudge.Close("time")
      return
    end
  end
  Bar()
end

local function DeathBusy()
  local X = ns.Extras
  return X and X.BannerBusy and X.BannerBusy() or false
end

local Update
local function Wait(tries)
  waiting = true
  if C_Timer and C_Timer.After then
    C_Timer.After(Card.WAIT_STEP, function()
      waiting = false
      local e = ns.Grudge and ns.Grudge.Current()
      if not e then return end
      if DeathBusy() and tries < Card.WAIT_MAX / Card.WAIT_STEP then Wait(tries + 1) else Update(e) end
    end)
  end
end

-- the episode changed (GRUDGE_UPDATE)
Update = function(e)
  if not card then Build() end
  if not e or e.closed then card:Hide(); return end
  local mine = e.id == shownId
  -- nothing to ask (everybody in the book by my death, or answered lately): no notice
  if not mine and not ns.Grudge.Asks(e) then return end
  -- after my death: first the death's notice, then this one (never side by side)
  if e.death and DeathBusy() then
    card:Hide()
    if not waiting then Wait(0) end
    return
  end
  if waiting then return end
  -- my death: the notice steps aside at once and comes back after the death's notice (or half a second later when
  -- there is none: the death's notice comes with the evaluation, Attribution.lua)
  if e.deathPending or (e.death and not e.deathShown) then
    card:Hide()
    if e.death and not e.deathPending then e.deathShown = true end
    Wait(0)
    return
  end
  if not mine then
    shownId, stamp, remaining, doneAt = e.id, nil, nil, nil
    if not e.test and ns.Grudge.Count then ns.Grudge.Count("shown") end
  end
  Countdown(e)
  if Over() then Card.dirty = true end
  Card.Fill(e)
  -- everything answered: the notice shows the answers a moment longer, then goes
  if ns.Grudge.Asks(e) then doneAt = nil else doneAt = doneAt or Card.DONE_DELAY end
  Bar()
  card:Show()
end
Card.Update = Update

-- does the notice show the episode e right now (Grudge.lua leaves the end to the notice then)?
function Card.Holds(e)
  if not (card and e and shownId == e.id) then return false end
  local ok, v = pcall(card.IsVisible, card)
  return ok and v == true
end

ns:On("GRUDGE_UPDATE", function(e) Update(e) end)
ns:On("GRUDGE_CLOSED", function(e)
  if card and e and e.id == shownId then card:Hide(); shownId, remaining, stamp, doneAt = nil, nil, nil, nil end
end)
ns:On("SETTINGS_CHANGED", function(path)
  if path == "grudge.point" and card and not card.moving then Card.Place() end
  if path == "grudge.size" and card then Card.ApplySize(); Card.Place() end
end)
ns:On("READY", function()
  -- built hidden at once (as the death's notice), so the first appearance equals every later one
  if not card then Build() end
end)

---------------------------------------------------------------------------
-- 1.5.0 grip: the House Rules rows of this package (sheet Rap Sheet, UI.lua calls these while it builds the sheet):
-- the size of the grudge notice under GRUDGE, the section NAMEPLATE with the mark's stepper (off, small, medium, large)
---------------------------------------------------------------------------
local GripUI = {}
ns.GripUI = GripUI
GripUI.OPT_H = 24
GripUI.VALUE_W = 96
local SIZE_WORD = { small = "SIZE_SMALL", medium = "SIZE_MEDIUM", large = "SIZE_LARGE" }

local function stepIn(list, cur, d)
  local idx = 1
  for i, v in ipairs(list) do if v == cur then idx = i end end
  return list[math.max(1, math.min(#list, idx + d))]
end

-- the size row below "Notice stays for" (y = that row's y); returns the y of the new row
function GripUI.Size(S, page, y, Stepper)
  y = y - GripUI.OPT_H
  S.gsize = Stepper(page, y, L.SET_GRUDGE_SIZE, function(d)
    local v = stepIn(Card.SIZES, Card.Size(), d)
    if ns.Store and ns.Store.Setting then ns.Store.Setting("grudge.size", v) end
  end, GripUI.VALUE_W)
  return y
end

-- the section NAMEPLATE from y; returns the sheet's new bottom (positive, as RR.bottom)
function GripUI.Plate(S, page, y, section, Stepper)
  local P = ns.Plate
  if not P then return nil end
  y = section(page, y, L.SET_SEC_PLATE)
  S.plate = Stepper(page, y, L.SET_PLATE, function(d)
    P.SetChoice(stepIn(P.ORDER, P.Choice(), d))
  end, GripUI.VALUE_W)
  return -y + 22
end

function GripUI.Fill(S)
  if S.gsize then S.gsize:SetValue(L[SIZE_WORD[Card.Size()]]) end
  local P = ns.Plate
  if S.plate and P then
    local c = P.Choice()
    S.plate:SetValue(c == "off" and L.WORD_OFF or L[SIZE_WORD[c]])
  end
end
