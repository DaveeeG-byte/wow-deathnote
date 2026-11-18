-- DeathNote - ShareUI.lua (1.5.0 share)
-- The window "Show": the line as it goes out, the channels that work right now (one click = one line, the click is
-- the hardware event), the week, and a block to copy for Discord. The guest poster of a line whose name is in no book
-- of mine, the click on the link in the chat, the button on the payback notice. Lines come from Share.lua.
-- Built on first use; no OnUpdate. An error here never reaches the book, the alarm or the death detection (every
-- entry from outside goes through pcall at its caller).

local ADDON, ns = ...
local Look = ns.Look
local L, Fmt = ns.L, ns.F
local Share = ns.Share
local ShareUI = {}
ns.ShareUI = ShareUI

local function G(n) return rawget(_G, n) end
local function K() return ns.UI and ns.UI.Kit end
local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end

ShareUI.W, ShareUI.H = 360, 252
ShareUI.GW, ShareUI.GH = 300, 312
ShareUI.FIT_HEAD = { sizes = { 22, 19, 16 } }
ShareUI.FIT_NAME = { sizes = { 22, 19, 16 }, lines = 2, wrapFirst = true }
ShareUI.FIT_LINE = { sizes = { 11, 10 }, lines = 4, wrapFirst = true }
ShareUI.FIT_ONE = { sizes = { 11, 10 } }
ShareUI.FIT_TWO = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
ShareUI.FIT_WORD = { sizes = { 13, 11 } }
ShareUI.FIT_GUEST_HEAD = { sizes = { 36, 30, 26, 22, 19 } }   -- 1.5.0 fixer: long heads (huHU, itIT week) step down further
ShareUI.MODES = { { "line", "SHARE_TAB_LINE" }, { "week", "SHARE_TAB_WEEK" }, { "discord", "SHARE_TAB_DISCORD" } }
ShareUI.CH_W, ShareUI.CH_GAP = 100, 8
ShareUI.GUEST_LINES = 5

-- may this item be shown? kind: "own" (own book), "guild" (guild or friends' book), "hunt" (hit list)
function ShareUI.Offer(item, kind)
  if not Share then return false end
  if kind == "guild" then return Share.OfferGuild(item) end
  if kind == "hunt" then return Share.OfferHunt(item) end
  return Share.Offer(item)
end

------------------------------------------------------------------------
-- The window
------------------------------------------------------------------------
local W

local function Status(text, red)
  W.status:SetTextColor(C(red and Look.RED_INK or Look.INK, red and 1 or 0.75))
  Look.FitText(W.status, text or "", ShareUI.FIT_TWO)
end

-- the sentence for a reason Share.Send or Share.Hold gave
function ShareUI.Reason(why)
  if why == "cooldown" then return Fmt(L.SHARE_WAIT, { seconds = math.max(1, Share.Wait()) }) end
  if why == "lockdown" then return L.SHARE_LOCKED end
  if why == "combat" then return L.SHARE_COMBAT end
  return L.SHARE_FAILED
end

local function ShowHold()
  if not (W and W:IsShown()) or W.mode == "discord" then return end
  local why = Share.Hold()
  if why then
    Status(ShareUI.Reason(why), true)
    -- the wait ends by itself: one timer, no OnUpdate
    if why == "cooldown" and C_Timer and C_Timer.After then C_Timer.After(Share.Wait(), ShowHold) end
  elseif W.sentText then
    Status(W.sentText)
  else
    Status(L.SHARE_HINT)
  end
end
ShareUI.ShowHold = ShowHold

local function SendTo(ch)
  local ok, why = Share.Send(W.text, ch)
  if ok then
    W.sentText = Fmt(L.SHARE_SENT, { channel = L[Share.CHANNEL_WORD[ch]] or ch })
    Status(W.sentText)
    if C_Timer and C_Timer.After then C_Timer.After(Share.COOLDOWN, ShowHold) end
  else
    Status(ShareUI.Reason(why), true)
    if why == "cooldown" and C_Timer and C_Timer.After then C_Timer.After(Share.Wait(), ShowHold) end
  end
end

local function Build()
  local Kit = K()
  W = CreateFrame("Frame", "DeathNoteShare", UIParent)
  W:SetSize(ShareUI.W, ShareUI.H)
  W:SetPoint("CENTER", 0, 140)
  W:SetFrameStrata("DIALOG")
  W:SetClampedToScreen(true)
  W:EnableMouse(true)
  W:SetMovable(true)
  W:RegisterForDrag("LeftButton")
  W:SetScript("OnDragStart", function(self) self:StartMoving() end)
  W:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  W:Hide()
  local bg = W:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  Kit.Shadow(W, 4, 5, 0.5)
  W.head = Look.Text(W, "head", 22, Look.INK)
  W.head:SetPoint("TOP", 0, -12)
  W.head:SetWidth(ShareUI.W - 40)
  Look.FitText(W.head, L.SHARE_HEAD, ShareUI.FIT_HEAD)
  Kit.Rule(W, -42, 20, 20, 0.7)
  -- three word tabs: the line, the week, Discord
  W.tabs = {}
  local x = 20
  for i, m in ipairs(ShareUI.MODES) do
    local t = Kit.WordTab(W, L[m[2]], 60, function() ShareUI.SetMode(m[1]) end)
    local tw = math.max(48, math.min(104, math.ceil((Look.TextW(t.text) or 50) + 8)))
    t:SetWidth(tw)
    t.text:SetWidth(tw - 4)
    Look.FitText(t.text, L[m[2]], ShareUI.FIT_ONE)
    Look.TipIfCut(t, t.text)
    t:SetPoint("TOPLEFT", x, -48)
    x = x + tw + 12
    t.mode = m[1]
    W.tabs[i] = t
  end
  W.label = Kit.Label(W, L.SHARE_PREVIEW)
  W.label:SetPoint("TOPLEFT", 22, -80)
  W.label:SetWidth(ShareUI.W - 44)
  W.label:SetJustifyH("LEFT")
  W.label:SetWordWrap(false)
  W.preview = Look.Text(W, "type", 11, Look.INK)
  W.preview:SetPoint("TOPLEFT", 22, -96)
  W.preview:SetWidth(ShareUI.W - 44)
  W.preview:SetJustifyH("LEFT")
  W.preview:SetSpacing(2)
  W.previewHit = CreateFrame("Frame", nil, W)
  W.previewHit:SetAllPoints(W.preview)
  Look.TipIfCut(W.previewHit, W.preview)
  -- channels: at most three buttons in one row (guild, the group, say), only those that work right now
  W.chans = {}
  for i = 1, 3 do
    local b = Kit.InkButton(W, "", ShareUI.CH_W, 22)
    b:SetPoint("BOTTOMLEFT", 20 + (i - 1) * (ShareUI.CH_W + ShareUI.CH_GAP), 44)
    b:Hide()
    W.chans[i] = b
  end
  W.status = Look.Text(W, "type", 11, Look.INK)
  W.status:SetPoint("BOTTOMLEFT", 22, 12)
  W.status:SetWidth(ShareUI.W - 44 - 80)
  W.status:SetJustifyH("LEFT")
  W.statusHit = CreateFrame("Frame", nil, W)
  W.statusHit:SetAllPoints(W.status)
  Look.TipIfCut(W.statusHit, W.status)
  W.close = Kit.WordButton(W, "", "hand", 13)
  W.close.text:ClearAllPoints()
  W.close.text:SetPoint("RIGHT", 0, 0)
  W.close.text:SetJustifyH("RIGHT")
  W.close:SetSize(72, 19)
  W.close.text:SetWidth(72)
  Look.FitText(W.close.text, L.SHARE_CLOSE, ShareUI.FIT_WORD)
  Look.TipIfCut(W.close, W.close.text)
  W.close:SetPoint("BOTTOMRIGHT", -18, 10)
  W.close:SetScript("OnClick", function() Look.Sound("click"); W:Hide() end)
  -- Discord: the block, marked, in a box; a typed change goes back to the block (a copy field, no editor)
  local box = CreateFrame("Frame", nil, W, "BackdropTemplate")
  box:SetPoint("TOPLEFT", 20, -76)
  box:SetSize(ShareUI.W - 40, 112)
  box:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  box:SetBackdropColor(C(Look.COLOR.editFill))
  box:SetBackdropBorderColor(C(Look.INK, 0.6))
  box:Hide()
  W.box = box
  local eb = CreateFrame("EditBox", nil, box)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(0)
  eb:SetPoint("TOPLEFT", 6, -6)
  eb:SetSize(ShareUI.W - 52, 100)
  Look.Font(eb, "body", 11)
  eb:SetTextColor(C(Look.INK))
  eb:SetScript("OnEscapePressed", function() W:Hide() end)
  eb:SetScript("OnTextChanged", function(self, user)
    if user and W.block then self:SetText(W.block); self:HighlightText() end
  end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  W.edit = eb
  W.dhint = Look.Text(W, "type", 11, Look.INK)
  W.dhint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 2, -4)
  W.dhint:SetWidth(ShareUI.W - 44)
  W.dhint:SetJustifyH("LEFT")
  W.dhint:SetTextColor(C(Look.INK, Look.TONE.hint or 0.7))
  W.dhintHit = CreateFrame("Frame", nil, W)
  W.dhintHit:SetAllPoints(W.dhint)
  Look.TipIfCut(W.dhintHit, W.dhint)
  W.dhint:Hide()
  local special = G("UISpecialFrames")
  if type(special) == "table" then special[#special + 1] = "DeathNoteShare" end
  W:SetScript("OnHide", function() if W.edit:HasFocus() then W.edit:ClearFocus() end end)
end

-- the text of the line (or nil) for the window's subject
local function LineOf(ctx)
  if ctx.mode == "week" then return (Share.WeekLine()) end
  local it = ctx.item
  if ctx.kind == "guild" then return Share.GuildLine(it, ctx.src) end
  if ctx.kind == "hunt" then return Share.HuntLine(it) end
  if ctx.revenge then return Share.RevengeLine(it) end
  return Share.LineFor(it)
end

-- fill the window for its mode ("line", "week", "discord")
function ShareUI.Fill()
  local ctx = W.ctx
  local mode = W.mode
  for _, t in ipairs(W.tabs) do t:SetOn(t.mode == mode) end
  local disc = mode == "discord"
  W.box:SetShown(disc)
  W.dhint:SetShown(disc)
  W.label:SetShown(not disc)
  W.preview:SetShown(not disc)
  W.previewHit:SetShown(not disc)
  if disc then
    W.block = Share.Discord(ctx.item, ctx.kind, ctx.src) or ""
    W.edit:SetText(W.block)
    W.edit:SetFocus()
    W.edit:HighlightText()
    Look.FitText(W.dhint, L.SHARE_DISCORD_HINT, ShareUI.FIT_TWO)
    for _, b in ipairs(W.chans) do b:Hide() end
    Status("")
    return
  end
  if W.edit:HasFocus() then W.edit:ClearFocus() end
  ctx.mode = mode
  W.text = LineOf(ctx)
  Look.FitText(W.preview, W.text or "", ShareUI.FIT_LINE)
  local list = W.text and Share.Channels() or {}
  for i, b in ipairs(W.chans) do
    local ch = list[i]
    if ch then
      b:SetLabel(L[Share.CHANNEL_WORD[ch]] or ch)
      b.fn = function() SendTo(ch) end
      b.channel = ch
      b:Show()
    else
      b.channel = nil
      b:Hide()
    end
  end
  ShowHold()
end

function ShareUI.SetMode(mode)
  if not W then return end
  W.mode = mode
  ShareUI.Fill()
end

-- ctx = { item = entry, kind = "own" | "guild" | "hunt", src = guild source, revenge = true, mode = "line" }
function ShareUI.Open(ctx)
  if type(ctx) ~= "table" or not K() then return false end
  if not ShareUI.Offer(ctx.item, ctx.kind) then return false end
  if not W then Build() end
  W.ctx, W.mode, W.sentText = ctx, ctx.mode or "line", nil
  W:Show()
  W:Raise()
  ShareUI.Fill()
  Share.Count("opened." .. (ctx.revenge and "revenge" or ctx.kind or "own"))
  return true
end

function ShareUI.Frame() return W end

------------------------------------------------------------------------
-- The guest poster: a line whose name is in none of my books, only from what it says
------------------------------------------------------------------------
local GP

local function BuildGuest()
  local Kit = K()
  GP = CreateFrame("Frame", "DeathNoteShareGuest", UIParent)
  GP:SetSize(ShareUI.GW, ShareUI.GH)
  GP:SetPoint("CENTER", 0, 60)
  GP:SetFrameStrata("DIALOG")
  GP:SetClampedToScreen(true)
  GP:EnableMouse(true)
  GP:SetMovable(true)
  GP:RegisterForDrag("LeftButton")
  GP:SetScript("OnDragStart", function(self) self:StartMoving() end)
  GP:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  GP:Hide()
  local bg = GP:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  Kit.Shadow(GP, 4, 5, 0.5)
  GP.head = Look.Text(GP, "head", 36, Look.INK)
  GP.head:SetPoint("TOP", 0, -10)
  GP.head:SetWidth(ShareUI.GW - 40)
  Kit.Rule(GP, -50, 20, 20, 0.7)
  GP.by = Look.Text(GP, "body", 11, Look.INK)
  GP.by:SetPoint("TOP", 0, -55)
  GP.by:SetWidth(ShareUI.GW - 40)
  GP.byHit = CreateFrame("Frame", nil, GP)
  GP.byHit:SetAllPoints(GP.by)
  Look.TipIfCut(GP.byHit, GP.by)
  Kit.Rule(GP, -71, 20, 20, 0.7)
  GP.name = Look.Text(GP, "hand", 22, Look.INK)
  GP.name:SetPoint("TOP", 0, -80)
  GP.name:SetWidth(ShareUI.GW - 40)
  GP.nameHit = CreateFrame("Frame", nil, GP)
  GP.nameHit:SetAllPoints(GP.name)
  Look.TipIfCut(GP.nameHit, GP.name)
  GP.label = Kit.Label(GP, L.SHARE_GUEST_SAYS)
  GP.label:SetPoint("TOPLEFT", 24, -136)
  GP.label:SetWidth(ShareUI.GW - 48)
  GP.label:SetJustifyH("LEFT")
  GP.label:SetWordWrap(false)
  GP.lines = {}
  for i = 1, ShareUI.GUEST_LINES do
    local l = Look.Text(GP, "hand", 13, Look.INK)
    l:SetPoint("TOPLEFT", 24, -152 - (i - 1) * 18)
    l:SetWidth(ShareUI.GW - 48)
    l:SetJustifyH("LEFT")
    l:SetWordWrap(false)
    local hit = CreateFrame("Frame", nil, GP)
    hit:SetAllPoints(l)
    Look.TipIfCut(hit, l)
    l.hit = hit
    GP.lines[i] = l
  end
  GP.hint = Look.Text(GP, "type", 11, Look.INK)
  GP.hint:SetPoint("BOTTOMLEFT", 24, 42)
  GP.hint:SetWidth(ShareUI.GW - 48)
  GP.hint:SetJustifyH("LEFT")
  GP.hint:SetTextColor(C(Look.INK, Look.TONE.hint or 0.7))
  GP.hintHit = CreateFrame("Frame", nil, GP)
  GP.hintHit:SetAllPoints(GP.hint)
  Look.TipIfCut(GP.hintHit, GP.hint)
  GP.add = Kit.InkButton(GP, "", 132, 22)
  GP.add:SetPoint("BOTTOMLEFT", 24, 12)
  GP.close = Kit.InkButton(GP, "", 100, 22, function() GP:Hide() end)
  GP.close:SetPoint("BOTTOMRIGHT", -24, 12)
  local special = G("UISpecialFrames")
  if type(special) == "table" then special[#special + 1] = "DeathNoteShareGuest" end
end

-- 1.5.0 fixer: the head follows the kind of the line (in the receiver's cover); a week line is no poster but a plain
-- card "<sender>'s week"; "Copy to my book" only for a line about somebody wanted (or one in another language)
local GUEST_HEAD = { wanted = "POSTER_HEAD", pardoned = "SHARE_KIND_PARDONED", revenge = "BANNER_REVENGE",
  guild = "POSTER_GUILDBOOK", friends = "POSTER_FRIENDSBOOK", hunt = "POSTER_HUNTLIST" }
function ShareUI.GuestHead(rec)
  local kind = rec.kind
  if kind == "week" then return Fmt(L.SHARE_GUEST_WEEK, { name = rec.sender or "?" }) end
  if GUEST_HEAD[kind] then return L[GUEST_HEAD[kind]] end
  local first = type(rec.segs) == "table" and rec.segs[1]
  return type(first) == "string" and first or L.POSTER_HEAD
end
function ShareUI.MayAdopt(rec) return type(rec) == "table" and (rec.kind == "wanted" or rec.kind == nil) end

-- rec = Share.Parse(...) plus sender
function ShareUI.Guest(rec)
  if type(rec) ~= "table" or type(rec.name) ~= "string" or not K() then return false end
  if not GP then BuildGuest() end
  GP.rec = rec
  Look.FitText(GP.head, ShareUI.GuestHead(rec), ShareUI.FIT_GUEST_HEAD)
  local week = rec.kind == "week"
  Look.FitText(GP.by, week and "" or Fmt(L.SHARE_GUEST_BY, { name = rec.sender or "?" }), ShareUI.FIT_ONE)
  Look.FitText(GP.name, rec.name, ShareUI.FIT_NAME)
  -- the head word stands in the head, not again as a line
  local all = type(rec.segs) == "table" and rec.segs or {}
  local segs = {}
  for i = 2, #all do segs[#segs + 1] = all[i] end
  for i, l in ipairs(GP.lines) do
    local s = segs[i]
    l:SetShown(s ~= nil)
    l.hit:SetShown(s ~= nil)
    Look.FitText(l, s or "", ShareUI.FIT_ONE)
  end
  GP.label:SetShown(#segs > 0)
  Look.FitText(GP.hint, L.SHARE_GUEST_HINT, ShareUI.FIT_TWO)
  GP.add:SetLabel(L.ACT_TAKE)
  GP.add.fn = function() ShareUI.Adopt(GP.rec) end
  GP.add:SetShown(ShareUI.MayAdopt(rec))
  GP.close:SetLabel(L.SHARE_CLOSE)
  GP:Show()
  GP:Raise()
  Share.Count("guest")
  return true
end

function ShareUI.GuestFrame() return GP end

-- "Copy to my book": a hand entry marked as copied from the sender (never shared on, like every copied entry)
function ShareUI.Adopt(rec)
  local S = ns.Store
  if type(rec) ~= "table" or not (S and S.AddManual) or not ShareUI.MayAdopt(rec) then return nil end
  local key = S.AddManual(rec.name, nil, { adopt = { from = rec.sender, src = "text", kills = rec.h or 0 } })
  if type(key) ~= "string" then return nil end
  Share.Count("guestAdd")
  if GP then GP:Hide() end
  if ns.UI and ns.UI.ShowEnemy then ns.UI.ShowEnemy(key) end
  return key
end

------------------------------------------------------------------------
-- The click on a link in the chat: own book, else guild or friends' book, else the guest poster
------------------------------------------------------------------------
function ShareUI.OpenRecord(rec)
  if type(rec) ~= "table" or type(rec.name) ~= "string" then return nil end
  -- 1.5.0 fixer: a week line tells about the sender, not about the name in it: always the week card
  if rec.kind == "week" then ShareUI.Guest(rec); return "guest" end
  local S = ns.Store
  local key = S and S.Find and S.Find(rec.name)
  if key and S.Get(key) and ns.UI and ns.UI.ShowEnemy then
    ns.UI.ShowEnemy(key)
    Share.Count("clickOwn")
    return "own"
  end
  local gk = ns.Util.KeyFor(rec.name)
  if gk and Look.GCall("Get", gk, "all") and ns.UI and ns.UI.ShowGuildEntry and ns.UI.ShowGuildEntry(gk) then
    Share.Count("clickGuild")
    return "guild"
  end
  ShareUI.Guest(rec)
  return "guest"
end

-- link = "addon:DeathNote:share:<n>"
function ShareUI.OnLink(link)
  if type(link) ~= "string" or Look.Secret(link) then return false end
  local id = link:match("^addon:" .. ADDON .. ":share:(%d+)$")
  if not id then return false end
  Share.Count("click")
  local rec = Share.links[tonumber(id)]
  if not rec then return false end
  ShareUI.OpenRecord(rec)
  return true
end

function ShareUI.HookClicks()
  if Share.clickVia then return end
  local ER = G("EventRegistry")
  if type(ER) == "table" and type(ER.RegisterCallback) == "function" then
    local ok = pcall(ER.RegisterCallback, ER, "SetItemRef", function(_, link) pcall(ShareUI.OnLink, link) end, ShareUI)
    if ok then Share.clickVia = "EventRegistry"; return end
  end
  local hook = G("hooksecurefunc")
  if type(hook) == "function" and type(G("SetItemRef")) == "function" then
    if pcall(hook, "SetItemRef", function(link) pcall(ShareUI.OnLink, link) end) then Share.clickVia = "hook"; return end
  end
  Share.clickVia = "none"
end

------------------------------------------------------------------------
-- The payback notice (Extras.lua): a small button "Show" while the switch is on (off by default)
------------------------------------------------------------------------
ShareUI.BTN_W, ShareUI.BTN_H, ShareUI.BTN_X = 64, 16, 10
function ShareUI.OnRevenge(banner, key, lineText, fitLine)
  if type(banner) ~= "table" or Look.Setting("share.revengeButton", false) ~= true then return false end
  local S = ns.Store
  local e = S and S.Get(key)
  if not e or e.status ~= "wanted" or not Share.Offer(e) then return false end
  local Kit = K()
  if not Kit then return false end
  local b = banner.dnShare
  if not b then
    b = Kit.InkButton(banner, "", ShareUI.BTN_W, ShareUI.BTN_H)
    b:SetPoint("BOTTOMLEFT", ShareUI.BTN_X, 5)
    -- while the mouse is on it, the notice stays
    b:HookScript("OnEnter", function()
      if banner.anim and banner.anim:IsPlaying() then banner.anim:Stop(); banner:SetAlpha(1); b.paused = true end
    end)
    b:HookScript("OnLeave", function()
      if b.paused then b.paused = nil; if banner.anim then banner.anim:Play() end end
    end)
    banner.dnShare = b
  end
  b:SetLabel(L.ACT_SHARE)
  b.fn = function() ShareUI.Open({ item = S.Get(key), kind = "own", revenge = true }) end
  -- the line moves right of the button
  local x = ShareUI.BTN_X + ShareUI.BTN_W + 6
  banner.line:ClearAllPoints()
  banner.line:SetPoint("BOTTOMLEFT", x, 7)
  banner.line:SetWidth(banner:GetWidth() - x - ShareUI.BTN_X)
  if type(lineText) == "string" then Look.FitText(banner.line, lineText, fitLine or ShareUI.FIT_ONE) end
  b:Show()
  return true
end

-- the chat link and the window refresh after combat
ns:On("READY", function() pcall(ShareUI.HookClicks) end)
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() pcall(ShowHold) end)
