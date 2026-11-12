-- DeathNote - Start.lua (1.3.0)
-- The first start: one small window that asks two things, the language and the cover (theme), and one button.
--
-- Who: only a new installation (no saved data before this login, read at ADDON_LOADED: Start.Fresh). Everybody who
-- has data from before gets one chat line instead (the book now has other covers, where to change it), once.
-- When: 3 s after the first entering of the world, never in combat (closes when a fight starts and comes back after
-- it), never in an instance, battleground or arena (comes back at the next entering of the open world). No timer
-- runs on its own: one C_Timer.After per entering of the world, the rest are events.
-- No reload as the first impression: the book, the alarm and the notice are built when they are first shown, so
-- "Go" switches language and cover at once (Locale.Reactivate, which refuses once something is built: then the
-- choice is stored and takes effect after /reload, as in the House Rules). The notice would be built at READY
-- (Extras.lua): on a new installation it waits for the dialog (Start.Holding) and is built when the dialog has asked.
-- The texts of the dialog are in the language picked in it, at once: the language builders stay in memory until the
-- dialog has asked (only on a new installation, Locale.Held), Locale.Text builds the table of a language on a click.
-- Esc or the cross: the defaults stay (the client's language, the default cover) and the question counts as asked.
-- /dn start shows the window again at any time out of combat.
-- Markers in DeathNoteDB.settings: firstRun = "new" (the dialog is due) or "done" (asked, or the chat line was
-- given); absent = data from before 1.3.0. welcomed (1.1.0) is set as before, so 1.2.2 after a downgrade greets
-- nobody twice, and 1.3.0 after an upgrade back asks nobody twice.
-- Colours only as roles of the themes, fonts only the client's (Locale.FONTS), no OnUpdate.

local ADDON, ns = ...
local Start = {}
ns.Start = Start
local Look = ns.Look
local L, Fmt = ns.L, ns.F

Start.DELAY = 3                 -- seconds after entering the world
Start.SETTING = "firstRun"
Start.W = 580                   -- width of the window
Start.COLS = 5                  -- languages per row
Start.TILE_COLS = 3             -- covers per row (more wrap into the next row)
Start.TILE_H = 96
Start.MAX_H = 640               -- taller content scrolls (Look.Page)

local TOP, FOOT, PAD, GAP = 48, 52, 20, 12
local CELL_H = 20

local frame                     -- the window, built on the first show
local sel = {}                  -- lang (code), theme (id), touched (the player clicked a cover)
local state = { armed = nil, waitWorld = false, waitCombat = false, combatHidden = false, events = {},
  guildAsk = false, going = false, hint = false }

local function G(name) return ns.Locale and ns.Locale.Global and ns.Locale.Global(name) end
-- the frames of the book, the alarm and the notice live where this file draws (Locale.Built asks here)
if ns.Locale then ns.Locale.FrameLookup = function(name) return rawget(_G, name) end end
local function Util() return ns.Util end
local function InCombat()
  local fn = G("InCombatLockdown")
  if type(fn) ~= "function" then return false end
  local ok, v = pcall(fn)
  return ok and v == true
end
local function OpenWorld()
  local U = Util()
  if U and U.IsOpenWorld then return U.IsOpenWorld() end
  return true
end
local function Settings()
  local S = ns.Store
  local db = S and S.DB and S.DB()
  return db and type(db.settings) == "table" and db.settings or nil
end
local function Set(key, v)
  local S = ns.Store
  if S and S.Setting and S.DB and S.DB() then S.Setting(key, v) end
end
local function Print(text)
  local U = Util()
  if U and U.Print and type(text) == "string" then U.Print(text) end
end
-- one handler per event, registered only when it is needed (an existing installation registers none)
local function Listen(event, fn)
  if state.events[event] then return end
  state.events[event] = true
  ns:RegisterEvent(event, fn)
end

---------------------------------------------------------------------------
-- Who and when
---------------------------------------------------------------------------
-- true on a new installation (no saved data before this login) or when the dialog is still due from an earlier
-- session of one (firstRun = "new"). Locale.Activate asks this at ADDON_LOADED, the answer stays for the session.
function Start.Fresh()
  if Start.fresh ~= nil then return Start.fresh end
  local db = G("DeathNoteDB")
  local fresh
  if type(db) ~= "table" or next(db) == nil then
    fresh = true
  else
    local st = db.settings
    fresh = type(st) == "table" and st[Start.SETTING] == "new" or false
  end
  Start.fresh = fresh
  return fresh
end

-- true while the dialog of a new installation has not asked yet (the greeting and the notice wait for it)
function Start.Holding() return Start.fresh == true and not Start.asked end

-- the remaining two lines of the greeting (the dialog says what the first two said), once, as 1.2.2 counts it
local function Greet()
  local st = Settings()
  if not st or st.welcomed ~= false then return end
  local U = Util()
  if U and U.NameplatesOn and U.NameplatesOn() == false then Print(ns.WELCOME_PLATES) end
  Print(ns.WELCOME_SHARE)
  Set("welcomed", true)
end

-- the dialog has asked (Go, Esc, the cross): from now on as for everybody
local function Asked()
  local first = Start.Holding()
  Start.asked = true
  local st = Settings()
  if st and st[Start.SETTING] ~= "done" then Set(Start.SETTING, "done") end
  if ns.Locale and ns.Locale.Release then ns.Locale.Release() end
  if first then
    -- the notice in the chosen look, built now so its first appearance equals every later one
    if ns.Extras and ns.Extras.BuildBanner then pcall(ns.Extras.BuildBanner) end
    Greet()
  end
end

-- existing installations: one chat line that the book has other covers now, once (only when there are others)
local function Hint()
  local st = Settings()
  if not st or st[Start.SETTING] ~= nil then return end
  local T = ns.Theme
  if not (T and T.List) or #T.List() < 2 then return end
  if InCombat() then
    state.hint = true
    Listen("PLAYER_REGEN_ENABLED", Start.OnCombatEnd)
    return
  end
  state.hint = false
  Print(L.CHAT_THEME_NEWS)
  Set(Start.SETTING, "done")
end

local function Try()
  if not Start.Holding() or (frame and frame:IsShown()) then return end
  if InCombat() then
    state.waitCombat = true
    Listen("PLAYER_REGEN_ENABLED", Start.OnCombatEnd)
    return
  end
  if not OpenWorld() then state.waitWorld = true; return end
  Start.Show("first")
end

local function After(sec, fn)
  local T = G("C_Timer")
  if type(T) == "table" and T.After then T.After(sec, fn) else fn() end
end

function Start.OnWorld()
  if state.armed == "dialog" then
    if not Start.Holding() then state.armed = nil; return end
    After(Start.DELAY, Try)
  elseif state.armed == "hint" then
    state.armed = nil
    After((ns.WELCOME_DELAY or 5) + 1, Hint)
  end
end

function Start.OnCombatStart()
  if frame and frame:IsShown() then
    state.combatHidden = true
    frame:Hide()
  end
end

function Start.OnCombatEnd()
  if InCombat() then return end
  if state.hint then Hint() end
  if state.combatHidden then
    state.combatHidden = false
    if frame then frame:Show() end
  elseif state.waitCombat then
    state.waitCombat = false
    if state.slash then state.slash = nil; Start.Show("slash") else Try() end
  end
end

ns:On("READY", function()
  local st = Settings()
  if not st then return end
  if Start.Fresh() then
    if st[Start.SETTING] ~= "new" then st[Start.SETTING] = "new" end
    state.armed = "dialog"
  elseif st[Start.SETTING] == nil then
    state.armed = "hint"
  end
  if state.armed then Listen("PLAYER_ENTERING_WORLD", Start.OnWorld) end
end)

---------------------------------------------------------------------------
-- Look of a theme that is not (yet) the active one: read straight from its data
---------------------------------------------------------------------------
local function Color(id, role)
  return ns.Theme.Color(role, id) or { 1, 1, 1, 1 }
end
local function RGB(c, a) return c[1], c[2], c[3], a or c[4] or 1 end
local function Path(file)
  if type(file) ~= "string" or file == "" then return nil end
  if file:find("^Interface\\") then return file end
  return (Look.MEDIA or ("Interface\\AddOns\\" .. ADDON .. "\\Media\\")) .. file
end
-- texture `key` of theme `id` with its fallback colour and tint
local function Skin(tex, id, key)
  local T = ns.Theme
  local fb = T.ParseColor(T.Pick(id, "fallback", key)) or { 0.5, 0.4, 0.3, 1 }
  Look.Tex(tex, Path(T.Pick(id, "tex", key)), fb[1], fb[2], fb[3], fb[4] or 1)
  local tint = T.ParseColor(T.Pick(id, "tint", key))
  -- a fallback colour is the finished colour (Look.Tint): never tinted a second time
  Look.Tint(tex, tint or { 1, 1, 1, 1 })
end
-- the fonts of role `role` of theme `id` for the writing of language `code`
local function Fonts(id, role, code)
  local kind = ns.Theme.Pick(id, "font", role)
  if not ns.Theme.FONT_KINDS[kind] then kind = "body" end
  return ns.Locale.FontList(kind, code)
end
local function Font(fs, id, role, size, code, flags)
  fs.dnRole, fs.dnSize = role, size
  Look.Font(fs, role, size, flags, Fonts(id, role, code))
end
-- the largest size of `sizes` in which text fits into width w on one line (the last one else)
local function Fit(fs, text, w, id, role, sizes, code)
  for i, s in ipairs(sizes) do
    Font(fs, id, role, s, code)
    fs:SetText(text)
    local tw = Look.TextW(fs)
    if not tw or tw <= w - 1.5 or i == #sizes then return end
  end
end
local function Height(fs)
  local ok, h = pcall(fs.GetStringHeight, fs)
  if ok and type(h) == "number" and not Look.Secret(h) and h > 0 then return h end
  return (fs.dnSize or 12) + 2
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local function Text(parent, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  fs:SetShadowOffset(0, 0)
  fs:SetJustifyH("LEFT")
  return fs
end

local function Line(parent)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetHeight(1)
  return t
end

local function Build()
  frame = CreateFrame("Frame", "DeathNoteStart", UIParent, "BackdropTemplate")
  frame:SetSize(Start.W, 400)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:Hide()
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if self.SetUserPlaced then pcall(self.SetUserPlaced, self, false) end
  end)
  -- Esc (UISpecialFrames) and the cross both hide it: that is "leave it as it is"; a hide for a fight or by Go is not.
  -- 1.3.0: neither is a hide of the whole interface (Alt+Z, a cinematic): then UIParent is hidden, and the window
  -- itself still counts as shown (IsShown is its own flag); it comes back with the interface
  frame:SetScript("OnHide", function(self)
    if state.combatHidden or state.going then return end
    if self:IsShown() or (UIParent and UIParent.IsShown and not UIParent:IsShown()) then return end
    Asked()
  end)
  tinsert(UISpecialFrames, "DeathNoteStart")
  frame:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  frame.cover = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  frame.cover:SetPoint("TOPLEFT", 1, -1)
  frame.cover:SetPoint("BOTTOMRIGHT", -1, 1)

  frame.title = Text(frame)
  frame.title:SetPoint("TOPLEFT", PAD, -12)
  frame.title:SetWidth(Start.W - 2 * PAD - 40)
  frame.title:SetWordWrap(false)
  frame.title:SetShadowOffset(1, -1)

  local close = CreateFrame("Button", nil, frame)
  close:SetSize(26, 26)
  close:SetPoint("TOPRIGHT", -8, -9)
  close.text = Text(close)
  close.text:SetPoint("CENTER", 0, 1)
  close.text:SetJustifyH("CENTER")
  close:SetScript("OnEnter", function(self)
    self.text:SetTextColor(RGB(Color(sel.theme, "accentOnCover")))
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(frame.closeTip or "", 1, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  close:SetScript("OnLeave", function(self)
    self.text:SetTextColor(RGB(Color(sel.theme, "onCover")))
    GameTooltip:Hide()
  end)
  close:SetScript("OnClick", function() Look.Sound("click"); frame:Hide() end)
  frame.close = close

  frame.page = Look.Page(frame, { top = TOP, foot = FOOT, w = Start.W, h = 400, paper = "cover" })
  local B = frame.page.body
  frame.welcome = Text(B)
  frame.welcome:SetWidth(Start.W - 2 * PAD)
  frame.welcome:SetWordWrap(true)
  frame.langHead = Text(B)
  frame.langHead:SetWidth(Start.W - 2 * PAD)
  frame.langHead:SetWordWrap(false)
  frame.langRule = Line(B)
  frame.themeHead = Text(B)
  frame.themeHead:SetWidth(Start.W - 2 * PAD)
  frame.themeHead:SetWordWrap(false)
  frame.themeRule = Line(B)

  -- 21 languages, each in its own name and in a font of its writing
  frame.cells = {}
  local cw = math.floor((Start.W - 2 * PAD) / Start.COLS)
  for i, code in ipairs(ns.Locale.CODES) do
    local b = CreateFrame("Button", nil, B)
    b:SetSize(cw - 6, CELL_H)
    b.code = code
    b.text = Text(b)
    b.text:SetPoint("LEFT", 2, 1)
    b.text:SetWidth(cw - 10)
    b.text:SetWordWrap(false)
    b.mark = Line(b)
    b.mark:SetHeight(2)
    b.mark:SetPoint("BOTTOMLEFT", 2, 0)
    b.mark:SetPoint("BOTTOMRIGHT", -4, 0)
    b:SetScript("OnEnter", function(self) if sel.lang ~= self.code then self.text:SetTextColor(RGB(Color(sel.theme, "accentOnCover"))) end end)
    b:SetScript("OnLeave", function(self) if sel.lang ~= self.code then self.text:SetTextColor(RGB(Color(sel.theme, "onCover"), 0.8)) end end)
    b:SetScript("OnClick", function(self) Look.Sound("click"); Start.Pick(self.code, nil) end)
    b.col, b.row = (i - 1) % Start.COLS, math.floor((i - 1) / Start.COLS)
    frame.cells[i] = b
  end
  frame.tiles = {}

  frame.hint = Text(frame.page.foot)
  frame.hint:SetWordWrap(true)
  frame.hint:SetMaxLines(2)
  local go = CreateFrame("Button", nil, frame.page.foot, "BackdropTemplate")
  go:SetSize(112, 24)
  go:SetPoint("RIGHT", frame.page.foot, "RIGHT", -PAD, 0)
  go:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  go.text = Text(go)
  go.text:SetPoint("CENTER", 0, 0)
  go.text:SetJustifyH("CENTER")
  go.text:SetWordWrap(false)
  go:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(RGB(Color(sel.theme, "btnEdgeHot"))) end)
  go:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(RGB(Color(sel.theme, "btnEdge"))) end)
  go:SetScript("OnClick", function() Look.Sound("click"); Start.Go() end)
  frame.go = go
end

-- one cover: a piece of the real theme (its cover with the book title, its paper with the poster head)
local function Tile(i)
  local t = frame.tiles[i]
  if t then return t end
  local B = frame.page.body
  t = CreateFrame("Button", nil, B)
  t.otherTheme = true          -- shows its own theme, not the active one (the theme guard skips it)
  t.cover = t:CreateTexture(nil, "BACKGROUND")
  t.cover:SetPoint("TOPLEFT", 2, -2)
  t.cover:SetPoint("BOTTOMRIGHT", -2, 22)
  t.edge = {}
  for k = 1, 4 do t.edge[k] = t:CreateTexture(nil, "BORDER") end
  t.edge[1]:SetPoint("TOPLEFT"); t.edge[1]:SetPoint("TOPRIGHT"); t.edge[1]:SetHeight(2)
  t.edge[2]:SetPoint("TOPLEFT", 0, -2); t.edge[2]:SetPoint("BOTTOMLEFT", 0, 20); t.edge[2]:SetWidth(2)
  t.edge[3]:SetPoint("TOPRIGHT", 0, -2); t.edge[3]:SetPoint("BOTTOMRIGHT", 0, 20); t.edge[3]:SetWidth(2)
  t.edge[4]:SetPoint("BOTTOMLEFT", 0, 20); t.edge[4]:SetPoint("BOTTOMRIGHT", 0, 20); t.edge[4]:SetHeight(2)
  t.title = Text(t)
  t.title:SetPoint("TOPLEFT", 10, -8)
  t.title:SetWordWrap(false)
  t.title:SetShadowOffset(1, -1)
  t.paper = t:CreateTexture(nil, "ARTWORK")
  t.paper:SetPoint("BOTTOMLEFT", 14, 30)
  t.paper:SetPoint("BOTTOMRIGHT", -14, 30)
  t.paper:SetHeight(38)
  t.head = Text(t, "OVERLAY")
  t.head:SetPoint("CENTER", t.paper, "CENTER", 0, 0)
  t.head:SetJustifyH("CENTER")
  t.head:SetWordWrap(false)
  t.name = Text(t)
  t.name:SetPoint("BOTTOMLEFT", 2, 3)
  t.name:SetWordWrap(false)
  t:SetScript("OnClick", function(self) Look.Sound("click"); Start.Pick(nil, self.id) end)
  frame.tiles[i] = t
  return t
end

-- the words of the dialog: the language picked in it (while the builders are held), else the active one
local function Words()
  local Lc = ns.Locale
  local T = ns.Theme
  if Lc.Text then
    local t, code = Lc.Text(sel.lang, T.Words(sel.theme))
    if t then return t, code end
  end
  return L, Lc.code or Lc.DEFAULT
end

-- the show word `key` of theme `id` in `code` (the theme's own word, else the base word of that language)
local function ThemeWord(id, key, base, code)
  local w = ns.Theme.Words(id)
  local own = w and ns.Locale.RawWords and ns.Locale.RawWords(w, code)
  local v = own and own[key]
  if type(v) == "string" and v ~= "" then return v end
  return base[key]
end

-- does the choice in the window take effect now, or only after a /reload?
local function Later()
  local Lc, T = ns.Locale, ns.Theme
  local changes = sel.lang ~= Lc.code or sel.theme ~= T.id
  if not changes then return false end
  return not (Lc.Held and Lc.Held()) or Lc.Built()
end

function Start.Fill()
  if not frame then return end
  local id = sel.theme
  local W, code = Words()
  local inner = Start.W - 2 * PAD
  local on, accent, hint = Color(id, "onCover"), Color(id, "accentOnCover"), Color(id, "tabOff")
  -- frame in the colours of the cover picked
  frame:SetBackdropColor(RGB(Color(id, "black")))
  frame:SetBackdropBorderColor(RGB(Color(id, "btnEdge")))
  Skin(frame.cover, id, "cover")
  Fit(frame.title, ThemeWord(id, "BOOK_TITLE", W, code) or "", inner - 40, id, "title", { 22, 19, 16 }, code)
  frame.title:SetTextColor(RGB(on))
  frame.title:SetShadowColor(RGB(Color(id, "titleShadow")))
  Font(frame.close.text, id, "body", 19, code)
  frame.close.text:SetText("\195\151")
  frame.close.text:SetTextColor(RGB(on))
  frame.closeTip = W.START_CLOSE_TIP

  -- body, stacked from the top
  local y = -2
  Font(frame.welcome, id, "body", 11, code)
  frame.welcome:SetText(ThemeWord(id, "WELCOME", W, code) or "")
  frame.welcome:SetTextColor(RGB(on))
  frame.welcome:ClearAllPoints()
  frame.welcome:SetPoint("TOPLEFT", PAD, y)
  y = y - math.ceil(Height(frame.welcome)) - GAP - 2
  local function head(fs, rule, text)
    Fit(fs, text or "", inner, id, "head", { 16, 13, 11 }, code)
    fs:SetTextColor(RGB(accent))
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", PAD, y)
    y = y - math.ceil(Height(fs)) - 3
    rule:SetColorTexture(RGB(on, 0.25))
    rule:ClearAllPoints()
    rule:SetPoint("TOPLEFT", PAD, y)
    rule:SetWidth(inner)
    y = y - 6
  end
  head(frame.langHead, frame.langRule, W.SET_LANGUAGE)
  local cw = math.floor(inner / Start.COLS)
  local Lc = ns.Locale
  for _, b in ipairs(frame.cells) do
    local list = Fonts(id, "body", b.code)
    local name = Lc.NATIVE[b.code] or b.code
    for k, s in ipairs({ 11, 10, 9 }) do
      Look.Font(b.text, "body", s, nil, list)
      b.text:SetText(name)
      local tw = Look.TextW(b.text)
      if not tw or tw <= cw - 11.5 or k == 3 then break end
    end
    local on1 = b.code == sel.lang
    b.text:SetTextColor(RGB(on1 and accent or on, on1 and 1 or 0.8))
    b.mark:SetColorTexture(RGB(accent))
    b.mark:SetShown(on1)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", PAD + b.col * cw, y - b.row * CELL_H)
  end
  y = y - math.ceil(#frame.cells / Start.COLS) * CELL_H - GAP
  head(frame.themeHead, frame.themeRule, W.SET_THEME)
  -- covers: one tile per registered theme, Start.TILE_COLS per row
  local ids = ns.Theme.List()
  local tg = 14
  local tw = math.floor((inner - (Start.TILE_COLS - 1) * tg) / Start.TILE_COLS)
  for i, tid in ipairs(ids) do
    local t = Tile(i)
    t.id = tid
    t:SetSize(tw, Start.TILE_H)
    t:ClearAllPoints()
    local col, row = (i - 1) % Start.TILE_COLS, math.floor((i - 1) / Start.TILE_COLS)
    t:SetPoint("TOPLEFT", PAD + col * (tw + tg), y - row * (Start.TILE_H + 10))
    Skin(t.cover, tid, "cover")
    Skin(t.paper, tid, "paper")
    Fit(t.title, ThemeWord(tid, "BOOK_TITLE", W, code) or "", tw - 20, tid, "title", { 19, 16, 13 }, code)
    t.title:SetTextColor(RGB(Color(tid, "onCover")))
    t.title:SetShadowColor(RGB(Color(tid, "titleShadow")))
    Fit(t.head, ThemeWord(tid, "POSTER_HEAD", W, code) or "", tw - 40, tid, "head", { 19, 16, 13 }, code)
    t.head:SetTextColor(RGB(Color(tid, "ink")))
    local d = ns.Theme.Get(tid)
    local nm = d and type(d.nameKey) == "string" and (W[d.nameKey] or rawget(L, d.nameKey)) or tid
    local picked = tid == id
    Fit(t.name, nm, tw - 4, id, "body", { 11, 10, 9 }, code)
    t.name:SetTextColor(RGB(picked and accent or on, picked and 1 or 0.8))
    for _, e in ipairs(t.edge) do
      if picked then e:SetColorTexture(RGB(accent)) else e:SetColorTexture(RGB(Color(tid, "frameEdge"))) end
    end
    t:Show()
  end
  for i = #ids + 1, #frame.tiles do frame.tiles[i]:Hide() end
  y = y - math.ceil(#ids / Start.TILE_COLS) * (Start.TILE_H + 10) + 10

  -- foot: one hint (where to change it later, or that it takes effect after a reload), the button
  local later = Later()
  Fit(frame.go.text, W.START_GO or "", 200, id, "body", { 11, 10 }, code)
  local bw = math.max(112, math.ceil(Look.TextW(frame.go.text) or 0) + 28)
  frame.go:SetWidth(bw)
  frame.go.text:SetWidth(bw - 8)
  frame.go.text:SetTextColor(RGB(on))
  frame.go:SetBackdropColor(RGB(Color(id, "btnFill")))
  frame.go:SetBackdropBorderColor(RGB(Color(id, "btnEdge")))
  local hw = inner - bw - GAP
  Font(frame.hint, id, "type", 11, code)
  frame.hint:SetWidth(hw)
  frame.hint:SetText((later and W.SET_LANG_RELOAD_HINT or W.START_HINT) or "")
  frame.hint:SetTextColor(RGB(hint))
  frame.hint:ClearAllPoints()
  frame.hint:SetPoint("LEFT", frame.page.foot, "LEFT", PAD, 0)

  -- height: the content, at most Start.MAX_H (and the screen); more scrolls
  local used = -y + 4
  local screen = UIParent and UIParent.GetHeight and UIParent:GetHeight()
  local maxH = Start.MAX_H
  if type(screen) == "number" and not Look.Secret(screen) then maxH = math.min(maxH, screen - 60) end
  local h = math.min(TOP + used + FOOT, maxH)
  frame:SetHeight(h)
  -- the page keeps its foot; only the window between head and foot changes with the content
  local page = frame.page
  page.h = h
  page.viewH = h - TOP - FOOT
  page.scroll:SetHeight(page.viewH)
  page.bar:SetHeight(page.viewH - 8)
  page:Layout(used)
end

---------------------------------------------------------------------------
-- Choice
---------------------------------------------------------------------------
-- the cover picked in advance on the first start: the default; the trade theme for members of the guild Humor
-- knows, when the client can tell already (else asked once more when the guild data comes)
local function Preselect()
  local T = ns.Theme
  sel.theme = T.Resolve(T.StoredChoice())
  local H = ns.Humor
  if not (H and H.GuildMember) or not T.Known("trade") then return end
  local ok, member = pcall(H.GuildMember)
  if not ok then return end
  if member == nil then
    state.guildAsk = true
    Listen("PLAYER_GUILD_UPDATE", Start.OnGuild)
  elseif member then
    sel.theme = "trade"
  end
end

function Start.OnGuild()
  if not state.guildAsk then return end
  local H = ns.Humor
  local ok, member = pcall(H.GuildMember)
  if not ok or member == nil then return end
  state.guildAsk = false
  if member and not sel.touched and ns.Theme.Known("trade") and Start.Holding() then
    sel.theme = "trade"
    if frame and frame:IsShown() then Start.Fill() end
  end
end

-- a click: lang (a code) or theme (an id)
function Start.Pick(lang, theme)
  if lang and ns.Locale.KNOWN[lang] then sel.lang = lang end
  if theme and ns.Theme.Known(theme) then sel.theme = theme; sel.touched = true end
  Start.Fill()
end

-- Shows the window. why: "first" (the first start) or "slash" (/dn start). In combat it waits for the end.
function Start.Show(why)
  if InCombat() then
    state.waitCombat = true
    state.slash = why ~= "first" or nil
    Listen("PLAYER_REGEN_ENABLED", Start.OnCombatEnd)
    return false
  end
  if not frame then Build() end
  Listen("PLAYER_REGEN_DISABLED", Start.OnCombatStart)
  Listen("PLAYER_REGEN_ENABLED", Start.OnCombatEnd)
  local Lc = ns.Locale
  sel.lang = Lc.code or Lc.Resolve(Lc.StoredChoice())
  sel.touched = false
  if why == "first" and Start.Holding() then
    Preselect()
  else
    sel.theme = ns.Theme.Resolve(ns.Theme.StoredChoice())
    sel.lang = Lc.Resolve(Lc.StoredChoice())
  end
  Start.Fill()
  frame:Show()
  return true
end

function Start.Shown() return frame ~= nil and frame:IsShown() end

-- Go: store both; at once when nothing is built yet, else after /reload (said in the chat)
function Start.Go()
  local Lc, T = ns.Locale, ns.Theme
  local lang, theme = sel.lang, sel.theme
  -- the client's language stays "Automatic" (nothing stored), any other is stored
  local auto = Lc.ClientCode() or Lc.DEFAULT
  if lang == auto then
    if Lc.StoredChoice() then Lc.SetChoice(Lc.AUTO) end
  else
    Lc.SetChoice(lang)
  end
  T.SetChoice(theme)
  local now = false
  if Lc.Pending() or T.Pending() then
    now = Lc.Reactivate(Lc.StoredChoice(), theme) ~= nil
  end
  local first = Start.Holding()
  state.going = true
  frame:Hide()
  state.going = false
  Asked()
  if Lc.Pending() then Print(Fmt(L.CHAT_LANG_RELOAD, { lang = (Lc.NATIVE[lang] or lang) .. " (" .. lang .. ")" })) end
  if T.Pending() then
    local d = T.Get(theme)
    local nm = d and type(d.nameKey) == "string" and rawget(L, d.nameKey) or theme
    Print(Fmt(L.CHAT_THEME_RELOAD, { theme = tostring(nm) .. " (" .. theme .. ")" }))
  end
  -- the first impression is the book in the chosen look
  if first then
    local F = G("DeathNoteFrame")
    if not (F and F:IsShown()) then ns:Fire("TOGGLE_UI") end
  end
  return now
end
