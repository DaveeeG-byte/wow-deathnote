-- DeathNote - GuildLogUI.lua (1.6.0 guildlog)
-- The guild's chronicle in the fourth tab: a red ribbon on the book's fold (only in the guild tab) opens two pages
-- over the book. The left page is the chronicle (newest first, by day; a line opens the killer's poster, the pin in
-- the margin the place on the map), the right page has three views: who has the book, the avengers of the week, the
-- week's card (a sheet to show, with "Post" into the guild chat and a block for Discord). A small dot on the guild tab
-- says that something happened in the guild since it was last looked at (no sound, no window).
-- The data is GuildLog.lua; the building blocks are the book's (UI.Kit). Built with the book (UI.lua calls Attach);
-- the book tells every refresh (Update). No OnUpdate; a timer only while the right page counts down. An error here
-- never reaches the book: UI.lua calls in through pcall.

local ADDON, ns = ...
local Look = ns.Look
local L, Fmt = ns.L, ns.F

local GLUI = {}
ns.GuildLogUI = GLUI

local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end
local function K() return ns.UI and ns.UI.Kit end
local function D() return ns.GuildLog end

GLUI.W, GLUI.H = 380, 490          -- a page of the book
GLUI.LINES = 24                    -- line buttons of the chronicle (pool)
GLUI.LINE_X, GLUI.LINE_W = 48, 316
GLUI.TOP, GLUI.FOOT = 62, 40       -- the chronicle's lines between these (from the top, from the bottom)
GLUI.HOLD_ROWS, GLUI.ROW_H = 14, 20
GLUI.AV_ROWS, GLUI.WANTED_ROWS = 6, 4
GLUI.VIEWS = { { "holders", "GLOG_VIEW_HOLDERS" }, { "avengers", "GLOG_VIEW_AVENGERS" }, { "card", "GLOG_VIEW_CARD" } }
GLUI.FIT_HEAD = { sizes = { 22, 19, 16 } }
GLUI.FIT_TAB = { sizes = { 11, 10 } }
GLUI.FIT_ONE = { sizes = { 11, 10 } }
GLUI.FIT_TWO = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
GLUI.FIT_LINE = { sizes = { 13, 12 }, lines = 2, wrapFirst = true }
GLUI.FIT_BIG = { sizes = { 16, 14, 13 }, lines = 2, wrapFirst = true }
GLUI.FIT_CARD_HEAD = { sizes = { 26, 22, 19, 16 } }
GLUI.FIT_CARD = { sizes = { 15, 13, 12 }, lines = 2, wrapFirst = true }
GLUI.FIT_NUM = { sizes = { 24, 20, 16 } }
GLUI.PIN = 12

local B = {}            -- the book's frames (F, LP, RP)
local R, PL, PR         -- the ribbon, the left and the right page
local state = { open = false, view = "holders", offset = 0, sig = nil, openSig = nil, hoff = 0 }
GLUI.state = state       -- for tests

------------------------------------------------------------------------
-- Small parts
------------------------------------------------------------------------
local function Page(parent, mirrored)
  local p = CreateFrame("Frame", nil, parent)
  p:SetAllPoints(parent)
  p:SetFrameLevel((parent:GetFrameLevel() or 1) + 40)
  p:EnableMouse(true)
  local bg = p:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "page")
  if mirrored then bg:SetTexCoord(1, 0, 0, 1) end
  p:Hide()
  return p
end

local function Text(parent, kind, size, tone)
  local fs = Look.Text(parent, kind, size, Look.INK)
  if tone then fs:SetTextColor(C(Look.INK, tone)) end
  fs:SetJustifyH("LEFT")
  return fs
end

-- a hit area over a text that shows it whole when it is cut
local function Hit(parent, fs)
  local h = CreateFrame("Frame", nil, parent)
  h:SetAllPoints(fs)
  Look.TipIfCut(h, fs)
  return h
end

local function first(s) return type(s) == "string" and (s:match("^([^%s%-]+)") or s) or "?" end

------------------------------------------------------------------------
-- Opening a name: the own poster, else the guild's or friends', else the guest poster
------------------------------------------------------------------------
function GLUI.OpenName(e)
  if type(e) ~= "table" or type(e.key) ~= "string" then return nil end
  local UI, S = ns.UI, ns.Store
  GLUI.Close()
  if S and S.Get and S.Get(e.key) and UI and UI.ShowEnemy then UI.ShowEnemy(e.key); return "own" end
  if Look.GCall("Get", e.key, "all") and UI and UI.ShowGuildEntry and UI.ShowGuildEntry(e.key) then return "guild" end
  local SU = ns.ShareUI
  if SU and SU.Guest then
    SU.Guest({ name = e.name or e.key, sender = first(e.by or e.victim), kind = "guild",
      segs = { L.POSTER_GUILDBOOK, D().Sentence(e) } })
    return "guest"
  end
  return nil
end

local function ShowPlace(place)
  if not place then return end
  Look.Sound("click")
  local SM = ns.SceneMap
  if SM and SM.Show then SM.Show(place, place) elseif ns.Util and ns.Util.Print then ns.Util.Print(L.SCENE_NO_MAP) end
end

------------------------------------------------------------------------
-- The ribbon on the fold and the dot on the tab
------------------------------------------------------------------------
local function BuildRibbon(F)
  local r = CreateFrame("Button", nil, F)
  r:SetSize(16, 50)
  r:SetPoint("TOPLEFT", 392, -34)
  r:SetFrameLevel((F:GetFrameLevel() or 1) + 60)
  r.body = r:CreateTexture(nil, "ARTWORK")
  r.body:SetPoint("TOPLEFT", 0, 0)
  r.body:SetSize(16, 40)
  r.body:SetColorTexture(C(Look.RED, 0.95))
  r.tip = r:CreateTexture(nil, "ARTWORK")
  r.tip:SetSize(18, 18)
  r.tip:SetPoint("TOP", r.body, "BOTTOM", 0, 7)
  Look.Skin(r.tip, "tri")
  r.tip:SetRotation(-1.5708)
  r.tip:SetVertexColor(C(Look.RED, 0.95))
  r.count = Look.Text(r, "body", 9, Look.BONE)
  r.count:SetPoint("BOTTOM", r.body, "BOTTOM", 0, 3)
  r.count:SetWidth(16)
  r.count:SetJustifyH("CENTER")
  r.count:SetWordWrap(false)
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(r.body)
  hl:SetColorTexture(1, 1, 1, 0.12)
  r:SetScript("OnClick", function() Look.Sound("click"); GLUI.Toggle() end)
  r:SetScript("OnEnter", function(self)
    local n = D() and D().Unseen("seenFeed") or 0
    K().Tip(self, { L.GLOG_HEAD, state.open and L.GLOG_RIBBON_CLOSE or L.GLOG_RIBBON_TIP,
      n > 0 and Fmt(L.GLOG_NEW, { count = n }) or nil }, "ANCHOR_RIGHT")
  end)
  r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  r:Hide()
  return r
end

local function GuildTab()
  for _, t in ipairs(B.F and B.F.tabs or {}) do if t.id == "guild" then return t end end
  return nil
end

local function Dot(t)
  if t.glogDot then return t.glogDot end
  local d = t:CreateTexture(nil, "OVERLAY")
  d:SetSize(7, 7)
  d:SetPoint("CENTER", t, "TOPRIGHT", -4, 0)
  d:SetColorTexture(C(Look.RED_ON_BLACK or Look.RED, 1))
  d:Hide()
  t.glogDot = d
  return d
end

------------------------------------------------------------------------
-- Left page: the chronicle
------------------------------------------------------------------------
local function BuildLeft(LP)
  local p = Page(LP, true)
  local margin = p:CreateTexture(nil, "BORDER")
  margin:SetColorTexture(Look.RED[1], Look.RED[2], Look.RED[3], 0.35)
  margin:SetWidth(1)
  margin:SetPoint("TOPLEFT", 40, 0)
  margin:SetPoint("BOTTOMLEFT", 40, 0)
  p.head = Look.Text(p, "head", 22, Look.INK)
  p.head:SetPoint("TOP", 20, -12)
  p.head:SetWidth(300)
  p.head:SetJustifyH("CENTER")
  p.headHit = Hit(p, p.head)
  p.sub = Text(p, "body", 10, Look.TONE.sub)
  p.sub:SetPoint("TOP", 20, -38)
  p.sub:SetWidth(300)
  p.sub:SetJustifyH("CENTER")
  p.subHit = Hit(p, p.sub)
  K().Rule(p, -54, 46, 16, 0.5)
  p.lines = {}
  for i = 1, GLUI.LINES do
    local b = CreateFrame("Button", nil, p)
    b:SetSize(GLUI.LINE_W, 16)
    b.text = Text(b, "hand", 13)
    b.text:SetPoint("TOPLEFT", 0, 0)
    b.text:SetWidth(GLUI.LINE_W)
    b.text:SetSpacing(1)
    b.head = K().Label(b, "", true)
    b.head:SetPoint("TOPLEFT", 0, -2)
    b.head:SetWidth(GLUI.LINE_W)
    b.head:SetJustifyH("LEFT")
    b.head:SetWordWrap(false)
    b.pin = CreateFrame("Button", nil, p)
    b.pin:SetSize(GLUI.PIN + 4, GLUI.PIN + 4)
    b.pin:SetPoint("TOPRIGHT", b, "TOPLEFT", -2, 1)
    b.pin.tex = b.pin:CreateTexture(nil, "ARTWORK")
    b.pin.tex:SetSize(GLUI.PIN, GLUI.PIN)
    b.pin.tex:SetPoint("CENTER", 0, 0)
    Look.Tex(b.pin.tex, Look.MEDIA .. "scene_mate.tga")
    b.pin:SetScript("OnClick", function(self) ShowPlace(self.place) end)
    b.pin:SetScript("OnEnter", function(self) K().Tip(self, { L.SCENE_SHOW }) end)
    b.pin:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b.pin:Hide()
    b:SetScript("OnClick", function(self) if self.event then Look.Sound("click"); GLUI.OpenName(self.event) end end)
    b:SetScript("OnEnter", function(self)
      if not self.event then return end
      self.text:SetTextColor(C(Look.RED))
      K().Tip(self, { self.event.name or "?", self.full or "", L.GLOG_TIP_POSTER })
    end)
    b:SetScript("OnLeave", function(self)
      self.text:SetTextColor(C(Look.INK))
      if GameTooltip then GameTooltip:Hide() end
    end)
    b:Hide()
    p.lines[i] = b
  end
  p.empty = Text(p, "hand", 16, Look.TONE.sub)
  p.empty:SetPoint("TOP", 20, -110)
  p.empty:SetWidth(280)
  p.empty:SetJustifyH("CENTER")
  p.foot = Text(p, "body", 10, Look.TONE.sub)
  p.foot:SetPoint("BOTTOMLEFT", 46, 14)
  p.foot:SetWidth(300)
  p:EnableMouseWheel(true)
  p:SetScript("OnMouseWheel", function(_, delta)
    local n = #(p.rows or {})
    local o = math.max(0, math.min(math.max(0, n - 1), state.offset - delta * 3))
    if o ~= state.offset then state.offset = o; GLUI.FillLeft() end
  end)
  return p
end

function GLUI.FillLeft()
  local p = PL
  if not p then return end
  local GLd = D()
  Look.FitText(p.head, L.GLOG_HEAD, GLUI.FIT_HEAD)
  local rows = GLd.Rows("all")
  p.rows = rows
  local events = 0
  for _, r in ipairs(rows) do if r.event then events = events + 1 end end
  local g = ns.Guild and ns.Guild.Name and ns.Guild.Name()
  Look.FitText(p.sub, g and Fmt(L.GLOG_SUB, { guild = g, count = events }) or Fmt(L.GLOG_SUB_NOGUILD, { count = events }),
    GLUI.FIT_ONE)
  if state.offset >= #rows then state.offset = math.max(0, #rows - 1) end
  local y, bottom = GLUI.TOP, GLUI.H - GLUI.FOOT
  local shown, last = 0, state.offset
  for i = 1, GLUI.LINES do
    local b = p.lines[i]
    local r = rows[state.offset + i]
    b.event, b.full = nil, nil
    b.pin.place = nil
    b.pin:Hide()
    -- a day head only with room for a line below it
    if r and r.head and y + 20 + 32 > bottom then r = nil end
    if r and y < bottom - 14 then
      b:ClearAllPoints()
      if r.head then
        b.text:SetText("")
        b.head:SetText(r.head)
        b.head:Show()
        b:SetHeight(16)
        b:SetPoint("TOPLEFT", GLUI.LINE_X, -(y + (i > 1 and 4 or 0)))
        b:EnableMouse(false)
        y = y + 16 + (i > 1 and 4 or 0)
      else
        b.head:SetText("")
        b.head:Hide()
        Look.FitText(b.text, r.text, GLUI.FIT_LINE)
        local h = math.max(16, math.ceil(Look.TextH(b.text, 2) or 16))
        if y + h > bottom then b:Hide(); break end
        b:SetHeight(h)
        b:SetPoint("TOPLEFT", GLUI.LINE_X, -y)
        b:EnableMouse(true)
        b.event, b.full = r.event, r.text
        local place = r.event.place
        if place and ns.Scene and ns.Scene.ValidMap and ns.Scene.ValidMap(place.mapID) then
          b.pin.place = place
          b.pin:Show()
        end
        y = y + h + 3
      end
      b.text:SetTextColor(C(Look.INK))
      b:Show()
      shown = shown + 1
      last = state.offset + i
    else
      b:Hide()
    end
  end
  for i = shown + 1, GLUI.LINES do p.lines[i]:Hide(); p.lines[i].pin:Hide() end
  if events == 0 then
    Look.FitText(p.empty, L.GLOG_EMPTY, GLUI.FIT_BIG)
    p.empty:Show()
  else
    p.empty:Hide()
  end
  if #rows > shown then
    p.foot:SetText(Fmt(L.GLOG_FOOT_MORE, { from = state.offset + 1, to = last, count = #rows }))
  else
    p.foot:SetText("")
  end
end

------------------------------------------------------------------------
-- Right page: who has the book, avengers, the week's card
------------------------------------------------------------------------
local function Status(fs, text, red)
  fs:SetTextColor(C(red and Look.RED_INK or Look.INK, red and 1 or Look.TONE.sub))
  Look.FitText(fs, text or "", GLUI.FIT_TWO)
end

local function Reason(why)
  if why == "wait" then return Fmt(L.GLOG_REC_WAIT, { minutes = math.max(1, math.ceil(D().RecommendWait() / 60)) }) end
  if why == "noguild" then return L.GLOG_NO_GUILD_CHAT end
  local SU = ns.ShareUI
  if SU and SU.Reason then return SU.Reason(why) end
  return L.SHARE_FAILED
end

local function BuildHolders(p)
  local v = CreateFrame("Frame", nil, p)
  v:SetAllPoints()
  v.line = Text(v, "hand", 16)
  v.line:SetPoint("TOPLEFT", 24, -48)
  v.line:SetWidth(GLUI.W - 48)
  v.lineHit = Hit(v, v.line)
  v.rows = {}
  for i = 1, GLUI.HOLD_ROWS do
    local r = CreateFrame("Frame", nil, v)
    r:SetSize(GLUI.W - 48, GLUI.ROW_H)
    r:SetPoint("TOPLEFT", 24, -(96 + (i - 1) * GLUI.ROW_H))
    r.name = Text(r, "body", 11)
    r.name:SetPoint("LEFT", 0, 0)
    r.name:SetWidth(150)
    r.name:SetWordWrap(false)
    r.ver = Text(r, "type", 10, Look.TONE.sub)
    r.ver:SetPoint("LEFT", 156, 0)
    r.ver:SetWidth(96)
    r.ver:SetWordWrap(false)
    r.when = Text(r, "type", 10, Look.TONE.sub)
    r.when:SetPoint("RIGHT", 0, 0)
    r.when:SetWidth(76)
    r.when:SetJustifyH("RIGHT")
    r.when:SetWordWrap(false)
    r.hit = CreateFrame("Frame", nil, r)
    r.hit:SetAllPoints()
    r.hit:SetScript("OnEnter", function(self) if self.tip then K().Tip(self, self.tip) end end)
    r.hit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    r:Hide()
    v.rows[i] = r
  end
  v:EnableMouseWheel(true)
  v:SetScript("OnMouseWheel", function(_, delta)
    local n = #(v.list or {})
    local o = math.max(0, math.min(math.max(0, n - GLUI.HOLD_ROWS), state.hoff - delta * 2))
    if o ~= state.hoff then state.hoff = o; GLUI.FillHolders() end
  end)
  v.hint = Text(v, "body", 10, Look.TONE.sub)
  v.hint:SetPoint("TOPLEFT", 24, -(96 + GLUI.HOLD_ROWS * GLUI.ROW_H + 6))
  v.hint:SetWidth(GLUI.W - 48)
  v.hintHit = Hit(v, v.hint)
  v.rec = K().InkButton(v, "", 160, 22, function() GLUI.Recommend() end)
  v.rec:SetPoint("BOTTOMLEFT", 24, 40)
  v.status = Text(v, "body", 10, Look.TONE.sub)
  v.status:SetPoint("LEFT", v.rec, "RIGHT", 10, 0)
  v.status:SetWidth(GLUI.W - 48 - 160 - 10)
  v.statusHit = Hit(v, v.status)
  v:Hide()
  return v
end

function GLUI.FillHolders()
  local v = PR and PR.holders
  if not v then return end
  local GLd = D()
  local list, head = GLd.Holders()
  v.list = list
  local line = head.total and Fmt(L.GLOG_HAVE_ONLINE, { count = head.online, total = head.total })
    or Fmt(L.GLOG_HAVE, { count = head.holders })
  Look.FitText(v.line, line, GLUI.FIT_BIG)
  if state.hoff > math.max(0, #list - GLUI.HOLD_ROWS) then state.hoff = math.max(0, #list - GLUI.HOLD_ROWS) end
  local Util = ns.Util
  for i, r in ipairs(v.rows) do
    local x = list[state.hoff + i]
    if x then
      Look.FitText(r.name, x.me and Fmt(L.GLOG_ME, { name = x.name }) or x.name, GLUI.FIT_ONE)
      r.name:SetTextColor(C(Look.INK, x.online and 1 or Look.TONE.sub))
      local vt = x.v or L.GLOG_VERSION_UNKNOWN
      if x.old then vt = Fmt(L.GLOG_VERSION_OLD, { version = x.v }) end
      Look.FitText(r.ver, vt, GLUI.FIT_ONE)
      r.ver:SetTextColor(C(x.old and Look.RED_INK or Look.INK, x.old and 1 or Look.TONE.sub))
      Look.FitText(r.when, x.me and L.GLOG_NOW or (Util and Util.Ago and Util.Ago(x.t) or ""), GLUI.FIT_ONE)
      r.hit.tip = { x.full, vt, x.online and L.GLOG_ONLINE or Fmt(L.GLOG_HEARD, { time = Util and Util.Ago and Util.Ago(x.t) or "?" }) }
      r:Show()
    else
      r.hit.tip = nil
      r:Hide()
    end
  end
  Look.FitText(v.hint, L.GLOG_HOLDERS_HINT, GLUI.FIT_TWO)
  local w = GLd.RecommendWait()
  if w > 0 then
    v.rec:SetLabel(Fmt(L.GLOG_REC_WAIT, { minutes = math.ceil(w / 60) }))
    v.rec:SetAlpha(0.6)
  else
    v.rec:SetLabel(L.GLOG_RECOMMEND)
    v.rec:SetAlpha(1)
  end
  if not v.sent then Status(v.status, "") end
end

-- the label counts down while the right page is open (one timer per minute, no OnUpdate)
local ticking = false
local function Tick()
  ticking = false
  if not (state.open and state.view == "holders" and PR and PR:IsShown()) then return end
  GLUI.FillHolders()
  if D().RecommendWait() > 0 and C_Timer and C_Timer.After then ticking = true; C_Timer.After(30, Tick) end
end

function GLUI.Recommend()
  local v = PR and PR.holders
  local ok, why = D().Recommend()
  if v then
    v.sent = true
    if ok then Status(v.status, L.GLOG_REC_SENT) else Status(v.status, Reason(why), true) end
  end
  GLUI.FillHolders()
  if ok and not ticking and C_Timer and C_Timer.After then ticking = true; C_Timer.After(30, Tick) end
  return ok, why
end

local function BuildAvengers(p)
  local v = CreateFrame("Frame", nil, p)
  v:SetAllPoints()
  v.head = K().Label(v, "", true)
  v.head:SetPoint("TOPLEFT", 24, -50)
  v.head:SetWidth(GLUI.W - 48)
  v.head:SetJustifyH("LEFT")
  v.week = Text(v, "type", 10, Look.TONE.sub)
  v.week:SetPoint("TOPLEFT", 24, -66)
  v.week:SetWidth(GLUI.W - 48)
  v.rows = {}
  for i = 1, GLUI.AV_ROWS + 1 do
    local r = CreateFrame("Frame", nil, v)
    r:SetSize(GLUI.W - 48, 22)
    r:SetPoint("TOPLEFT", 24, -(86 + (i - 1) * 22))
    r.name = Text(r, "hand", 14)
    r.name:SetPoint("LEFT", 0, 0)
    r.name:SetWidth(GLUI.W - 48 - 50)
    r.name:SetWordWrap(false)
    r.n = Text(r, "hand", 14)
    r.n:SetPoint("RIGHT", 0, 0)
    r.n:SetWidth(46)
    r.n:SetJustifyH("RIGHT")
    r.hit = Hit(r, r.name)
    r:Hide()
    v.rows[i] = r
  end
  v.empty = Text(v, "hand", 13, Look.TONE.sub)
  v.empty:SetPoint("TOPLEFT", 24, -90)
  v.empty:SetWidth(GLUI.W - 48)
  v.whead = K().Label(v, "", true)
  v.whead:SetPoint("TOPLEFT", 24, -256)
  v.whead:SetWidth(GLUI.W - 48)
  v.whead:SetJustifyH("LEFT")
  v.wanted = {}
  for i = 1, GLUI.WANTED_ROWS do
    local b = CreateFrame("Button", nil, v)
    b:SetSize(GLUI.W - 48, 22)
    b:SetPoint("TOPLEFT", 24, -(274 + (i - 1) * 22))
    b.name = Text(b, "hand", 14)
    b.name:SetPoint("LEFT", 0, 0)
    b.name:SetWidth(GLUI.W - 48 - 80)
    b.name:SetWordWrap(false)
    b.n = Text(b, "type", 10, Look.TONE.sub)
    b.n:SetPoint("RIGHT", 0, 0)
    b.n:SetWidth(76)
    b.n:SetJustifyH("RIGHT")
    b.n:SetWordWrap(false)
    b:SetScript("OnClick", function(self) if self.event then Look.Sound("click"); GLUI.OpenName(self.event) end end)
    b:SetScript("OnEnter", function(self)
      if not self.event then return end
      self.name:SetTextColor(C(Look.RED))
      K().Tip(self, { self.event.name or "?", self.tip, L.GLOG_TIP_POSTER })
    end)
    b:SetScript("OnLeave", function(self) self.name:SetTextColor(C(Look.INK)); if GameTooltip then GameTooltip:Hide() end end)
    b:Hide()
    v.wanted[i] = b
  end
  v.wempty = Text(v, "hand", 13, Look.TONE.sub)
  v.wempty:SetPoint("TOPLEFT", 24, -278)
  v.wempty:SetWidth(GLUI.W - 48)
  v:Hide()
  return v
end

function GLUI.FillAvengers()
  local v = PR and PR.avengers
  if not v then return end
  local GLd = D()
  local w = GLd.Week()
  v.head:SetText(L.GLOG_AV_HEAD)
  Look.FitText(v.week, GLd.CardTexts(w).week, GLUI.FIT_ONE)
  local rank = GLd.OwnRank()
  local rows, meIn = {}, false
  for i = 1, math.min(#w.avengers, GLUI.AV_ROWS) do
    rows[#rows + 1] = w.avengers[i]
    if w.avengers[i].me then meIn = true end
  end
  -- the own name stands with its rank; not among the first: an own last row
  if not meIn then
    local mine
    for _, r in ipairs(w.avengers) do if r.me then mine = r end end
    local Bd = ns.Guild and ns.Guild.Bridge
    local full = Bd and Bd.myFullName and Bd.myFullName()
    if mine or full then rows[#rows + 1] = mine or { char = full, n = 0, me = true, own = true } end
  end
  for i, r in ipairs(v.rows) do
    local x = rows[i]
    if x and (x.n > 0 or x.me) then
      local nm = first(x.char)
      local label = x.me and (rank and Fmt(L.GLOG_ME_RANK, { name = nm, rank = rank }) or Fmt(L.GLOG_ME, { name = nm }))
        or nm
      local pos = x.own and "" or (i .. ".  ")
      Look.FitText(r.name, pos .. label, GLUI.FIT_ONE)
      r.name:SetTextColor(C(x.me and Look.RED_INK or Look.INK))
      r.n:SetText(tostring(x.n))
      r:Show()
    else
      r:Hide()
    end
  end
  v.empty:SetShown(#w.avengers == 0)
  if #w.avengers == 0 then Look.FitText(v.empty, L.GLOG_AV_EMPTY, GLUI.FIT_TWO) end
  -- the own row alone (nobody avenged anything): below the empty line
  if #w.avengers == 0 and v.rows[1]:IsShown() then
    v.rows[1]:ClearAllPoints()
    v.rows[1]:SetPoint("TOPLEFT", 24, -(86 + 2 * 22))
  else
    v.rows[1]:ClearAllPoints()
    v.rows[1]:SetPoint("TOPLEFT", 24, -86)
  end
  v.whead:SetText(L.GLOG_WANTED_HEAD)
  for i, b in ipairs(v.wanted) do
    local x = w.wanted[i]
    if x then
      Look.FitText(b.name, i .. ".  " .. (x.name or "?"), GLUI.FIT_ONE)
      b.tip = Fmt(L.GLOG_WANTED_N, { count = x.n })
      Look.FitText(b.n, b.tip, GLUI.FIT_ONE)
      b.event = { key = x.key, name = x.name }
      b:Show()
    else
      b.event = nil
      b:Hide()
    end
  end
  v.wempty:SetShown(#w.wanted == 0)
  if #w.wanted == 0 then Look.FitText(v.wempty, L.GLOG_WANTED_EMPTY, GLUI.FIT_TWO) end
end

local function BuildCard(p)
  local v = CreateFrame("Frame", nil, p)
  v:SetAllPoints()
  -- the sheet: a card of its own to show (no controls on it)
  local s = CreateFrame("Frame", nil, v)
  s:SetSize(GLUI.W - 56, 330)
  s:SetPoint("TOP", 0, -50)
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  K().Shadow(s, 3, 4, 0.4)
  v.sheet = s
  local function line(kind, size, y, tone)
    local fs = Look.Text(s, kind, size, Look.INK)
    fs:SetPoint("TOP", 0, -y)
    fs:SetWidth(GLUI.W - 56 - 32)
    fs:SetJustifyH("CENTER")
    if tone then fs:SetTextColor(C(Look.INK, tone)) end
    return fs
  end
  v.guild = line("head", 26, 18)
  v.week = line("type", 11, 54, Look.TONE.sub)
  K().Rule(s, -74, 24, 24, 0.5)
  v.deaths = line("hand", 24, 92)
  v.deaths:SetTextColor(C(Look.RED_INK))
  v.avenged = line("hand", 24, 130)
  K().Rule(s, -170, 60, 60, 0.35)
  v.wantedLabel = K().Label(s, "", true)
  v.wantedLabel:SetPoint("TOP", 0, -184)
  v.wanted = line("hand", 15, 200)
  v.avLabel = K().Label(s, "", true)
  v.avLabel:SetPoint("TOP", 0, -244)
  v.avenger = line("hand", 15, 260)
  v.brand = Look.Text(s, "title", 13, Look.INK)
  v.brand:SetPoint("BOTTOM", 0, 12)
  v.brand:SetTextColor(C(Look.INK, Look.TONE.sub))
  v.hits = {}
  for _, fs in ipairs({ v.guild, v.week, v.deaths, v.avenged, v.wanted, v.avenger }) do v.hits[#v.hits + 1] = Hit(s, fs) end
  -- below the sheet: post, copy for Discord, the status
  v.post = K().InkButton(v, "", 110, 22, function() GLUI.PostWeek() end)
  v.post:SetPoint("BOTTOMLEFT", 24, 40)
  v.copy = K().InkButton(v, "", 160, 22, function() GLUI.ShowDiscord() end)
  v.copy:SetPoint("LEFT", v.post, "RIGHT", 10, 0)
  v.status = Text(v, "body", 10, Look.TONE.sub)
  v.status:SetPoint("BOTTOMLEFT", 24, 14)
  v.status:SetWidth(GLUI.W - 48 - 110)
  v.statusHit = Hit(v, v.status)
  -- Discord: the block marked in a box over the sheet (a copy field, no editor)
  local box = CreateFrame("Frame", nil, v, "BackdropTemplate")
  box:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
  box:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
  box:SetFrameLevel((p:GetFrameLevel() or 1) + 20)
  box:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  box:SetBackdropColor(C(Look.COLOR.editFill))
  box:SetBackdropBorderColor(C(Look.INK, 0.6))
  box:EnableMouse(true)
  box:Hide()
  local eb = CreateFrame("EditBox", nil, box)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(0)
  eb:SetPoint("TOPLEFT", 8, -8)
  eb:SetSize(GLUI.W - 56 - 16, 230)
  Look.Font(eb, "body", 11)
  eb:SetTextColor(C(Look.INK))
  eb:SetScript("OnEscapePressed", function() GLUI.HideDiscord() end)
  eb:SetScript("OnTextChanged", function(self, user)
    if user and v.block then self:SetText(v.block); self:HighlightText() end
  end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  box.edit = eb
  box.hint = Text(box, "body", 10, Look.TONE.sub)
  box.hint:SetPoint("BOTTOMLEFT", 8, 8)
  box.hint:SetWidth(GLUI.W - 56 - 16)
  box.hintHit = Hit(box, box.hint)
  v.box = box
  v:Hide()
  return v
end

function GLUI.FillCard()
  local v = PR and PR.card
  if not v then return end
  local GLd = D()
  local c = GLd.CardTexts(GLd.Week())
  Look.FitText(v.guild, c.guild, GLUI.FIT_CARD_HEAD)
  Look.FitText(v.week, c.week, GLUI.FIT_ONE)
  Look.FitText(v.deaths, c.deaths, GLUI.FIT_NUM)
  Look.FitText(v.avenged, c.avenged, GLUI.FIT_NUM)
  v.wantedLabel:SetText(L.GLOG_CARD_WANTED_HEAD)
  Look.FitText(v.wanted, c.top and Fmt(L.GLOG_CARD_NAME_N, { name = c.top.name or "?", count = c.top.n }) or L.GLOG_CARD_NONE,
    GLUI.FIT_CARD)
  v.avLabel:SetText(L.GLOG_CARD_AVENGER_HEAD)
  Look.FitText(v.avenger, c.av and Fmt(L.GLOG_CARD_NAME_N, { name = first(c.av.char), count = c.av.n }) or L.GLOG_CARD_NONE,
    GLUI.FIT_CARD)
  v.brand:SetText((ns.Share and ns.Share.BRAND) or "Revenge Book")
  v.post:SetLabel(L.ACT_SHARE)
  v.copy:SetLabel(L.GLOG_DISCORD)
  if not v.sent then Status(v.status, "") end
end

function GLUI.PostWeek()
  local v = PR and PR.card
  local ok, why = D().PostWeek()
  if v then
    v.sent = true
    if ok then Status(v.status, Fmt(L.SHARE_SENT, { channel = L.SHARE_CH_GUILD })) else Status(v.status, Reason(why), true) end
  end
  return ok, why
end

function GLUI.ShowDiscord()
  local v = PR and PR.card
  if not v then return end
  v.block = D().WeekDiscord()
  v.sheet:Hide()
  v.box:Show()
  v.box.edit:SetText(v.block)
  v.box.edit:SetFocus()
  v.box.edit:HighlightText()
  Look.FitText(v.box.hint, L.SHARE_DISCORD_HINT, GLUI.FIT_TWO)
  D().Count("discord")
end

function GLUI.HideDiscord()
  local v = PR and PR.card
  if not v then return end
  if v.box.edit:HasFocus() then v.box.edit:ClearFocus() end
  v.box:Hide()
  v.sheet:Show()
end

local function BuildRight(RP)
  local p = Page(RP, false)
  p.tabs = {}
  local x = 24
  local room = GLUI.W - 48 - 12 * (#GLUI.VIEWS - 1)
  local ws, total = {}, 0
  for i, m in ipairs(GLUI.VIEWS) do
    local t = K().WordTab(p, L[m[2]], 90, function() GLUI.SetView(m[1]) end)
    ws[i] = math.max(48, math.ceil((Look.TextW(t.text) or 60) + 8))
    total = total + ws[i]
    t.view = m[1]
    p.tabs[i] = t
  end
  local k = total > room and room / total or 1
  for i, t in ipairs(p.tabs) do
    local w = math.floor(ws[i] * k)
    t:SetWidth(w)
    t.text:SetWidth(w - 4)
    t.text:SetWordWrap(false)
    Look.FitText(t.text, L[GLUI.VIEWS[i][2]], GLUI.FIT_TAB)
    Look.TipIfCut(t, t.text)
    t:SetPoint("TOPLEFT", x, -12)
    x = x + w + 12
  end
  K().Rule(p, -36, 24, 24, 0.5)
  p.holders = BuildHolders(p)
  p.avengers = BuildAvengers(p)
  p.card = BuildCard(p)
  p.back = K().WordButton(p, "", "hand", 13)
  p.back.text:ClearAllPoints()
  p.back.text:SetPoint("RIGHT", 0, 0)
  p.back.text:SetJustifyH("RIGHT")
  p.back:SetSize(120, 19)
  p.back.text:SetWidth(120)
  Look.FitText(p.back.text, L.GLOG_BACK, { sizes = { 13, 11 } })
  Look.TipIfCut(p.back, p.back.text)
  p.back:SetPoint("BOTTOMRIGHT", -18, 12)
  p.back:SetScript("OnClick", function() Look.Sound("click"); GLUI.Close() end)
  return p
end

function GLUI.SetView(view)
  local ok = false
  for _, m in ipairs(GLUI.VIEWS) do if m[1] == view then ok = true end end
  if not ok then return end
  if state.view ~= view then
    state.view = view
    if PR then PR.holders.sent, PR.card.sent = nil, nil end
  end
  GLUI.FillRight()
end

function GLUI.FillRight()
  local p = PR
  if not p then return end
  for _, t in ipairs(p.tabs) do t:SetOn(t.view == state.view) end
  p.holders:SetShown(state.view == "holders")
  p.avengers:SetShown(state.view == "avengers")
  p.card:SetShown(state.view == "card")
  if state.view ~= "card" then GLUI.HideDiscord() end
  if state.view == "holders" then GLUI.FillHolders()
  elseif state.view == "avengers" then GLUI.FillAvengers()
  else GLUI.FillCard() end
end

------------------------------------------------------------------------
-- Open, close, the book's refresh
------------------------------------------------------------------------
function GLUI.Fill()
  if not (state.open and PL and PR) then return end
  GLUI.FillLeft()
  GLUI.FillRight()
end

function GLUI.Open(view)
  if not (PL and PR) then return false end
  if view then state.view = view end
  state.open = true
  state.openSig = state.sig
  state.offset, state.hoff = 0, 0
  PL:Show()
  PR:Show()
  -- the poster's tape reaches over the page's edge: invisible while the chronicle lies over it
  if B.P then B.P:SetAlpha(0) end
  D().MarkSeen("seenFeed")
  D().Count("opened")
  GLUI.SetView(state.view)
  GLUI.Fill()
  GLUI.UpdateMarks()
  return true
end

function GLUI.Close()
  if not state.open then return end
  state.open = false
  GLUI.HideDiscord()
  if PL then PL:Hide() end
  if PR then PR:Hide() end
  if B.P then B.P:SetAlpha(1) end
  if GameTooltip then GameTooltip:Hide() end
  GLUI.UpdateMarks()
end

function GLUI.Toggle()
  if state.open then GLUI.Close() else GLUI.Open() end
end
function GLUI.IsOpen() return state.open end

-- the dot on the guild tab, the count on the ribbon
function GLUI.UpdateMarks()
  local GLd = D()
  if not GLd then return end
  local t = GuildTab()
  if t then
    local d = Dot(t)
    d:SetShown(state.filter ~= "guild" and t:IsShown() and GLd.Unseen("seenTab") > 0)
  end
  if R then
    local n = (R:IsShown() and not state.open) and GLd.Unseen("seenFeed") or 0
    R.count:SetText(n > 0 and (n > 99 and "99" or tostring(n)) or "")
  end
end

-- UI.lua after every refresh of the tabs: the tab, an open panel (help, house rules), the selection
function GLUI.Update(filter, panel, sig)
  state.filter, state.sig = filter, sig
  local guild = filter == "guild" and not panel
  if R then R:SetShown(guild and D() ~= nil) end
  if state.open and (not guild or (state.openSig ~= nil and sig ~= state.openSig)) then GLUI.Close() end
  if filter == "guild" and D() then D().MarkSeen("seenTab") end
  GLUI.UpdateMarks()
  if state.open then GLUI.Fill() end
end

-- UI.lua once the book is built
function GLUI.Attach(F, LP, RP, poster)
  if B.F or not (F and LP and RP and K() and D()) then return false end
  B.F, B.LP, B.RP, B.P = F, LP, RP, poster
  R = BuildRibbon(F)
  PL = BuildLeft(LP)
  PR = BuildRight(RP)
  -- the manual or the house rules opened over the right page: the chronicle steps aside
  local UI = ns.UI
  if UI and type(UI.OpenPanel) == "function" and not GLUI.wrapped then
    GLUI.wrapped = true
    local open = UI.OpenPanel
    UI.OpenPanel = function(...)
      pcall(GLUI.Close)
      if R then R:Hide() end
      return open(...)
    end
    if type(UI.ClosePanel) == "function" then
      local close = UI.ClosePanel
      UI.ClosePanel = function(...)
        local r = close(...)
        if R then R:SetShown(state.filter == "guild" and D() ~= nil) end
        return r
      end
    end
  end
  F:HookScript("OnHide", function() pcall(GLUI.Close) end)
  return true
end

function GLUI.Frames() return R, PL, PR end

-- something changed in the guild's data while the book is open: the marks and the open pages follow
ns:On("GUILDLOG_UPDATED", function()
  if B.F and B.F:IsShown() then GLUI.UpdateMarks(); if state.open then GLUI.Fill() end end
end)
