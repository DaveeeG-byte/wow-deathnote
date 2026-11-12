local ADDON, ns = ...

-- Tooltip line "WANTED" or "GUILD ENEMY" and on-screen notices after death, revenge and guild death.

local Look = ns.Look
local Extras = {}
ns.Extras = Extras
local ready = false
-- Texts (1.2.0): read L.KEY inside functions only (ns.L is filled from ADDON_LOADED on)
local L, Fmt = ns.L, ns.F

-- Head line of the notice letter-spaced: "NEW ENTRY" -> "N E W   E N T R Y" (UTF-8 aware);
-- Chinese and Korean stay unspaced
local NO_SPACING = { koKR = true, zhCN = true, zhTW = true }
local function Spaced(s)
  if type(s) ~= "string" then return "" end
  if ns.Locale and NO_SPACING[ns.Locale.code] then return s end
  local out, n = {}, 0
  for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do n = n + 1; out[n] = ch end
  return table.concat(out, " ", 1, n)
end
Extras.Spaced = Spaced

-- Stamp of the notice: German shows the images as in 1.1.0, every other language the empty frame
-- (same look) with the text from the language table on top, turned like the image (degrees, ImageMagick
-- clockwise). FontString:SetRotation is used only where it exists (as in Details/Libs/DF/fw.lua).
-- rgb: the theme's stamp ink (Look.STAMP_INK[1], filled in place by the theme)
local STAMPS = {
  nr1   = { img = "nr1",   key = "STAMP_NR1",     ang = -11, rgb = Look.STAMP_INK[1] },
  rache = { img = "rache", key = "STAMP_REVENGE", ang = 9,   rgb = Look.STAMP_INK[1] },
  hunt  = { img = "hunt",  key = "STAMP_HUNT",    ang = 8,   rgb = Look.STAMP_INK[1] },
}
Extras.STAMPS = STAMPS
local function StampImage(kind)
  local st = STAMPS[kind]
  if not st then return nil end
  -- 1.3.0: the picture with burnt-in text only where the theme has one (the black book, German)
  local baked = Look.StampTex(st.img)
  if baked and (not ns.Locale or ns.Locale.code == "deDE") then return baked, nil, st end
  return Look.StampTex(st.img, true), L[st.key], st
end

------------------------------------------------------------------------
-- Tooltip
------------------------------------------------------------------------
-- "IN THE BOOK: 2× killed · 1× involved · rank 1 · revenge 2×" (the same words as in the book)
local function TooltipText(e)
  local rank = e.status == "wanted" and ns.Store.Rank(e.key) or nil
  local rv = tonumber(e.revenge) or 0
  local s = Look.Join(e.status == "pardoned" and L.TIP_PARDONED or nil, Look.Tally(e),
                      rank and Fmt(L.TIP_RANK, { rank = rank }), rv > 0 and Fmt(L.TIP_REVENGE, { times = Look.Times(rv) }))
  return Look.HEX.tipLabel .. L.TIP_IN_BOOK .. "|r " .. Look.HEX.tipText .. s .. "|r"
end

-- Unit token of the tooltip: GetUnit, else through the GUID of the tooltip data; secrets drop out
local function TooltipUnit(tt, data)
  local ok, _, unit = pcall(tt.GetUnit, tt)
  if ok and type(unit) == "string" and not Look.Secret(unit) then return unit end
  if type(data) == "table" and not Look.Secret(data) and UnitTokenFromGUID then
    local guid = data.guid
    if type(guid) == "string" and not Look.Secret(guid) then
      local ok2, u = pcall(UnitTokenFromGUID, guid)
      if ok2 and type(u) == "string" and not Look.Secret(u) then return u end
    end
  end
end

local tipNames = {}

local function OnTooltipUnit(tt, data)
  if not ready or tt ~= GameTooltip then return end
  if tt.IsForbidden and tt:IsForbidden() then return end
  if not Look.Setting("tooltip", true) then return end
  local unit = TooltipUnit(tt, data)
  if not unit then return end
  local key = ns.Util.KeyOfUnit(unit)   -- nil for a secret or a non-player
  if not key then return end
  -- Hit list target (1.2.0): a line of its own, also when he is in the own book
  local h = Look.HasGuild() and Look.GCall("Hunt", key, "all")
  if type(h) == "table" and type(h.names) == "table" and #h.names > 0 then
    tt:AddLine(Look.HEX.tipLabel .. L.TIP_HUNT .. "|r " .. Look.HEX.tipText .. Fmt(L.HUNT_LINE_BY, { names = Look.NameList(h.names, 2) }) .. "|r")
  end
  local e = ns.Store.Get(key)
  if not e then
    -- Guild enemy (1.2.0: or a killer from the friends' book) who is not (yet) in the own book
    local g = Look.HasGuild() and Look.GCall("Get", key, "all")
    if type(g) == "table" and (g.kills or 0) > 0 then
      tt:AddLine(Look.HEX.tipLabel .. L.TIP_GUILDBOOK .. "|r " .. Look.HEX.tipText .. Fmt(L.GUILD_LINE_KILLED_GUILD, { kills = Look.GKills(g.kills) }) .. "|r")
    elseif type(g) == "table" and Look.ListedOnly(g) then
      local names = Look.ListedNames(g, tipNames)
      if #names > 0 then
        tt:AddLine(Look.HEX.tipListed .. L.TIP_GUILDBOOK .. "|r " .. Look.HEX.tipText .. Fmt(L.TIP_LISTED_BY, { names = Look.NameList(names, 2) }) .. "|r")
      end
    end
    return
  end
  tt:AddLine(TooltipText(e))
  local note = Look.NoteOf(e)
  if note ~= "" then tt:AddLine(Look.HEX.tipNote .. Fmt(L.TIP_NOTE, { note = note }) .. "|r", nil, nil, nil, true) end
end

local hooked = false
local function HookTooltip()
  if hooked then return end
  hooked = true
  local function safe(tt, data)
    local ok, err = pcall(OnTooltipUnit, tt, data)
    if not ok and Look.Setting("debug", false) and ns.Util.Print then ns.Util.Print("Tooltip: " .. tostring(err)) end
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
     and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, safe)
  elseif GameTooltip and GameTooltip.HasScript and GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", safe)
  end
end

------------------------------------------------------------------------
-- On-screen notice (a slip from the book in the middle of the screen)
------------------------------------------------------------------------
-- 1.3.0: no black strip any more. Two ways to build it, chosen by one constant:
--   "slip"  a narrow strip torn out of a page (texture "slip", tinted like the paper of the theme), ink on it
--   "bare"  no surface at all: the text with a soft shadow, the stamp on top
-- Both have the same size, place, queue, click and stamp; only the surface and the text colours differ.
Extras.BANNER_STYLE = "slip"
local banner
local BANNER_W, BANNER_H, BANNER_Y = 352, 64, -310
-- the strip of a dry remark (Humor.lua) hangs below the notice; wider than the slip: Humor fits its one line at
-- 11 or 10 pt, and the longest remark needs about 420 px at 10 pt (the ends of the slip fade, so it reads narrower)
local QUIP_GAP, QUIP_H, QUIP_W = 2, 22, 440
-- the stamp keeps its size of 1.2.2 (120 x 60: the longest stamp words of the 21 languages need its 96 px of text)
-- and sits on the right end of the slip, over its top edge (red ink on paper, readable on any ground)
local STAMP_W, STAMP_H, STAMP_X, STAMP_Y = 120, 60, 16, 14
local NAME_W, NAME_W_STAMP, NAME_X_STAMP = 300, 232, -36    -- name next to the stamp: shifted left, narrower
local NAME_Y, LINE_W = -20, 300
Extras.BANNER_SIZE = { w = BANNER_W, h = BANNER_H, quip = QUIP_GAP + QUIP_H }
local guildQueue = {}     -- waiting guild notices; the own notice always goes first
local GUILD_QUEUE_MAX = 3
local NextGuild -- forward declaration

local function Bare() return Extras.BANNER_STYLE == "bare" end

-- The class colour as ink on the slip: 30 % class colour in 70 % ink keeps a hint of the hue and stays readable
-- on paper even at 13 pt (the white of a priest becomes a dark grey; contrast guard in tests/ui/gesamtschau.lua)
Extras.SLIP_CLASS_SHARE = 0.3
function Extras.SlipInk(rgb)
  local ink = Look.INK
  if type(rgb) ~= "table" then return { ink[1], ink[2], ink[3] } end
  local a = Extras.SLIP_CLASS_SHARE
  return { rgb[1] * a + ink[1] * (1 - a), rgb[2] * a + ink[2] * (1 - a), rgb[3] * a + ink[3] * (1 - a) }
end

-- Text without a surface: soft dark shadow (theme role "shadow"), as the client's own on-screen messages
local function Shade(fs)
  local c = Look.COLOR.shadow
  fs:SetShadowColor(c[1], c[2], c[3], 1)
  fs:SetShadowOffset(1, -1)
end

-- colours of kicker, name and line for the chosen style
local function Colours()
  if Bare() then return Look.RED_ON_BLACK, Look.BONE, Look.BONE end
  return Look.RED_INK, Look.INK, Look.INK
end

-- The quip strip of Humor.lua: built here in the style of the notice (Humor.lua takes banner.dnQuip as it is)
local function BuildQuip()
  local q = CreateFrame("Frame", nil, banner)
  q:SetSize(QUIP_W, QUIP_H)
  q:SetPoint("TOP", banner, "BOTTOM", 0, -QUIP_GAP)
  local _, _, line = Colours()
  if not Bare() then
    local bg = q:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Look.Skin(bg, "slip")
    local t = Look.TINT.slip or Look.TINT.paper
    if t then bg:SetVertexColor(t[1], t[2], t[3], t[4] or 1) end
    q.bg = bg
  end
  q.text = Look.Text(q, "body", 11, line)
  q.text:SetPoint("CENTER", 0, 0)
  q.text:SetWidth(QUIP_W - 10)
  q.text:SetWordWrap(false)
  if Bare() then Shade(q.text) end
  q:Hide()
  banner.dnQuip = q
end

-- The name next to the stamp (also called by Humor.lua for its surprise stamp)
function Extras.NameBesideStamp(b, beside)
  b = b or banner
  if not (b and b.name) then return end
  b.name:ClearAllPoints()
  b.name:SetPoint("TOP", beside == false and 0 or NAME_X_STAMP, NAME_Y)
  b.name:SetWidth(beside == false and NAME_W or NAME_W_STAMP)
  -- a name fitted before (Humor's stamp comes after the notice) is fitted again to the new width
  if b.name.fit and type(b.name.full) == "string" then Look.FitText(b.name, b.name.full, Extras.FIT_NAME) end
end

-- Built once (at READY, see the end of the file): textures and fonts are set long before the first notice,
-- so the first notice looks like every later one
local function BuildBanner()
  banner = CreateFrame("Frame", "DeathNoteBanner", UIParent)
  banner:SetSize(BANNER_W, BANNER_H)
  banner:SetPoint("TOP", UIParent, "TOP", 0, BANNER_Y)   -- below the alarm popup (moves above it only when there is no room below, see further down)
  banner:SetClampedToScreen(true)
  banner:SetFrameStrata("HIGH")
  banner:EnableMouse(false)
  banner:SetAlpha(0)
  banner:Hide()
  banner.style = Extras.BANNER_STYLE
  local kickerC, nameC, lineC = Colours()
  -- Notices after the own death can be clicked (you are dead, it disturbs no fight):
  -- left click opens the killer or the case, right click closes
  -- Stop() does not fire OnFinished in the client: clean up after a click ourselves, else the click
  -- state stays and waiting guild notices never get their turn
  local function Dismiss(self)
    self.inAnim:Stop(); self.anim:Stop(); self:Hide(); self:SetAlpha(0)
    self.open, self.key, self.guild = nil, nil, false
    self:EnableMouse(false)
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
  end
  banner:SetScript("OnMouseUp", function(self, mouse)
    if not self.open then return end
    local open = self.open
    Dismiss(self)
    if mouse ~= "RightButton" then open() end
  end)
  -- hover over a clickable notice: the kicker turns full red, a tooltip says what the click does
  banner:SetScript("OnEnter", function(self)
    if not self.open then return end
    local c = Bare() and Look.COLOR.edgeHot or Look.RED
    self.kicker:SetTextColor(c[1], c[2], c[3], 1)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.BANNER_TIP)
    GameTooltip:Show()
  end)
  banner:SetScript("OnLeave", function(self)
    local c = Colours()
    self.kicker:SetTextColor(c[1], c[2], c[3], 1)
    GameTooltip:Hide()
  end)
  if not Bare() then
    -- the slip: one texture with ragged ends that fade out; no edge, no fill around it
    local bg = banner:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Look.Skin(bg, "slip")
    local t = Look.TINT.slip or Look.TINT.paper    -- a theme without its own slip tint colours it like its paper
    if t then bg:SetVertexColor(t[1], t[2], t[3], t[4] or 1) end
    banner.bg = bg
  end

  banner.kicker = Look.Text(banner, "body", 10, kickerC)
  banner.kicker:SetPoint("TOP", 0, -7)
  banner.kicker:SetWidth(LINE_W)
  banner.kicker:SetWordWrap(false)
  banner.name = Look.Text(banner, "head", 19, nameC)
  banner.name:SetPoint("TOP", 0, NAME_Y)
  banner.name:SetWidth(NAME_W)
  banner.name:SetWordWrap(false)
  banner.line = Look.Text(banner, "body", 10, lineC)
  banner.line:SetPoint("BOTTOM", 0, 7)
  banner.line:SetWidth(LINE_W)
  banner.line:SetWordWrap(false)
  if Bare() then Shade(banner.kicker); Shade(banner.name); Shade(banner.line) end

  -- the stamp hangs over the top right corner
  banner.stamp = banner:CreateTexture(nil, "OVERLAY")
  banner.stamp:SetSize(STAMP_W, STAMP_H)
  banner.stamp:SetPoint("TOPRIGHT", banner, "TOPRIGHT", STAMP_X, STAMP_Y)
  banner.stamp:SetAlpha(0.95)
  banner.stamp:Hide()
  -- stamp text for every language except German (on the empty frame)
  banner.stampText = Look.Text(banner, "title", 11, Look.STAMP_INK[1])
  banner.stampText:SetPoint("CENTER", banner.stamp, "CENTER", 0, 0)
  banner.stampText:SetWidth(STAMP_W - 24)
  banner.stampText:SetJustifyH("CENTER")
  banner.stampText:SetMaxLines(2)   -- (Extras.FitStamp sets the lines per text)
  banner.stampText:Hide()
  BuildQuip()

  -- Calm in and out, alpha only, never more opaque than the standing notice: the frame waits at alpha 0,
  -- fades in (0.3 s), then a second group stays 4.5 s and fades out (0.8 s). Each group ends on its final
  -- alpha, set by hand as well (clients without SetToFinalAlpha), so no frame flashes at full alpha.
  local gi = banner:CreateAnimationGroup()
  Look.AlphaAnim(gi, 0, 1, 0.3, 1)
  local g = banner:CreateAnimationGroup()
  Look.AlphaAnim(g, 1, 0, 0.8, 1, 4.5)   -- stay 4.5 s, then fade out
  if gi.SetToFinalAlpha then gi:SetToFinalAlpha(true) end
  if g.SetToFinalAlpha then g:SetToFinalAlpha(true) end   -- no flash at alpha 1 at the end
  gi:SetScript("OnFinished", function()
    banner:SetAlpha(1)
    g:Play()
  end)
  g:SetScript("OnFinished", function()
    banner:Hide()
    banner:SetAlpha(0)
    banner.open = nil
    banner:EnableMouse(false)
    banner.guild = false
    banner.key = nil
    if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
  end)
  banner.inAnim, banner.anim = gi, g

  -- Name: keep it invisible for a moment, then fade in (alpha jumps back to 1 afterwards)
  local ng = banner.name:CreateAnimationGroup()
  Look.AlphaAnim(ng, 0, 0, 0.2, 1)
  Look.AlphaAnim(ng, 0, 1, 0.7, 2)
  banner.nameAnim = ng

  -- the stamp follows with a soft thud (a little larger than its place, never more opaque)
  local sg = banner.stamp:CreateAnimationGroup()
  Look.AlphaAnim(sg, 0, 0, 0.6, 1)
  Look.AlphaAnim(sg, 0, 0.95, 0.1, 2)
  Look.ScaleAnim(sg, 1.25, 1, 0.14, 2)
  banner.stampAnim = sg
  local tg = banner.stampText:CreateAnimationGroup()
  Look.AlphaAnim(tg, 0, 0, 0.6, 1)
  Look.AlphaAnim(tg, 0, 0.95, 0.1, 2)
  banner.stampTextAnim = tg

  -- measure once while hidden: every size of the ladders on a sample, so the fonts are set up before the
  -- first notice (the client measures a font string the same whether shown or not)
  local sample = "Mmmmmmmm Wwwwwwww"
  for _, p in ipairs({ { banner.name, Extras.FIT_NAME }, { banner.line, Extras.FIT_LINE }, { banner.stampText, Extras.FIT_STAMP } }) do
    local fs, sizes = p[1], p[2].sizes
    for i = #sizes, 1, -1 do Look.Font(fs, fs.fontKind, sizes[i], fs.fontFlags); fs:SetText(sample); pcall(fs.GetStringWidth, fs) end
    fs:SetText("")
  end
end
Extras.BuildBanner = function() if not banner then BuildBanner() end return banner end

-- The notice never lies on the alarm popup: when they overlap (larger alarm, moved popup), the notice
-- moves below the popup, and when there is no room there, above it.
-- All in UIParent units; both hang on UIParent, so its scale (e.g. 0.6) cancels out.
local GAP, STAMP_TOP = 10, STAMP_Y
function Extras.PlaceBanner()
  if not banner then return end
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  local y = BANNER_Y
  local l, b, r, t = nil, nil, nil, nil
  if ns.Alert and ns.Alert.Rect then l, b, r, t = ns.Alert.Rect() end
  if type(W) == "number" and type(H) == "number" and not Look.Secret(W) and not Look.Secret(H) and l then
    local bl, br = W / 2 - BANNER_W / 2, W / 2 + BANNER_W / 2
    -- the strip of a dry remark hangs below the message
    local strip = (ns.Humor and ns.Humor.On and ns.Humor.On()) and (QUIP_GAP + QUIP_H) or 0
    local bt = H + BANNER_Y + STAMP_TOP
    local bb = H + BANNER_Y - BANNER_H - strip
    if l < br and r > bl and b < bt and t > bb then
      if b - GAP - STAMP_TOP - BANNER_H >= 0 then
        y = (b - GAP - STAMP_TOP) - H              -- below the popup
      else
        y = (t + GAP + BANNER_H + strip) - H       -- above it
      end
    end
  end
  if banner.y ~= y then
    banner.y = y
    banner:ClearAllPoints()
    banner:SetPoint("TOP", UIParent, "TOP", 0, y)
  end
end

-- does the notice show this player right now?
function Extras.BannerShows(key)
  return banner ~= nil and banner:IsShown() and banner.key ~= nil and banner.key == key
end

local function Silence(key)
  if type(key) == "string" and ns.Alert and ns.Alert.Silence then ns.Alert.Silence(key) end
end

-- open: function for the click (only notices after the own death), else not clickable.
-- kicker is the unspaced text (1.2.0, spacing happens here); stamp: kind from STAMPS or nil
-- 1.3.0: the name steps 19, 16, 13 pt (300 px, 232 px next to the stamp); the line steps 10, 9 pt, and a line
-- given as { full, short } falls back to the short one (zone left out) before it would be cut;
-- the stamp text steps 11, 10, 9 pt on up to two lines, then three lines at 9 pt (no tooltip on the stamp:
-- the notice may come in combat, mouse off; "JAVNI / NEPRIJATELJ / BR. 1" in hrHR)
Extras.FIT_NAME, Extras.FIT_LINE = { sizes = { 19, 16, 13 } }, { sizes = { 10, 9 } }
Extras.FIT_KICKER = { sizes = { 10, 9 } }
Extras.FIT_STAMP = { sizes = { 11, 10, 9 }, lines = 2, wrapFirst = true }
Extras.FIT_STAMP_LAST = { sizes = { 9 }, lines = 3 }
function Extras.FitStamp(fs, text)
  return Look.FitText(fs, text, Extras.FIT_STAMP) or Look.FitText(fs, text, Extras.FIT_STAMP_LAST)
end
local function Banner(kicker, name, nameRGB, line, stamp, guild, key, open)
  local stampTex, stampText, st = StampImage(stamp)
  kicker = Spaced(kicker)
  if not banner then BuildBanner() end
  -- the frame waits invisible: alpha 0 before it is shown, the fade brings it to 1
  banner.inAnim:Stop()
  banner.anim:Stop()
  banner.stampAnim:Stop()
  banner:SetAlpha(0)
  banner.guild = guild and true or false
  banner.key = key
  banner.kind = stamp
  banner.open = open
  banner:EnableMouse(open ~= nil)
  local kc = Colours()
  banner.kicker:SetTextColor(kc[1], kc[2], kc[3], 1)
  Look.FitText(banner.kicker, kicker, Extras.FIT_KICKER)
  -- with a stamp the name moves a bit to the left, so long names stay clear of it
  Extras.NameBesideStamp(banner, stampTex ~= nil)
  Look.FitText(banner.name, name, Extras.FIT_NAME)
  local c
  if Bare() then c = nameRGB or Look.BONE else c = nameRGB and nameRGB ~= Look.BONE and Extras.SlipInk(nameRGB) or Look.INK end
  banner.name:SetTextColor(c[1], c[2], c[3], 1)
  if type(line) == "table" then
    if not Look.FitText(banner.line, line[1] or "", Extras.FIT_LINE) then Look.FitText(banner.line, line[2] or "", Extras.FIT_LINE) end
  else
    Look.FitText(banner.line, line or "", Extras.FIT_LINE)
  end
  Extras.PlaceBanner()
  banner:Show()
  banner.inAnim:Play()
  banner.nameAnim:Stop(); banner.nameAnim:Play()
  banner.stampTextAnim:Stop()
  if stampTex then
    Look.StampSkin(banner.stamp, stampTex, "stampNotice")
    banner.stamp:Show()
    banner.stampAnim:Play()
  else
    banner.stamp:Hide()
  end
  if stampText then
    local fs = banner.stampText
    Extras.FitStamp(fs, stampText)
    fs:SetTextColor(st.rgb[1], st.rgb[2], st.rgb[3], 0.95)
    if fs.SetRotation then pcall(fs.SetRotation, fs, math.rad(-st.ang)) end
    fs:Show()
    banner.stampTextAnim:Play()
  else
    banner.stampText:Hide()
  end
  -- one event, one window: no alarm popup for the same player next to it
  if key then Silence(key) end
  if ns.Humor then pcall(ns.Humor.OnBanner, banner, stamp, key, guild) end -- Humor: remark and stamp for the notice
end

local function OnDeath(death, key)
  if not ready or type(death) ~= "table" then return end
  if not Look.Setting("deathMessage", true) then return end
  if death.kind ~= "pvp" then return end
  local S = ns.Store
  if key then
    local e = S.Get(key)
    if not e then return end
    local name = Look.Name(e)
    local r, g, b = Look.ClassRGB(e.class)
    local rgb = { r, g, b }
    local function open() if ns.UI and ns.UI.ShowEnemy then ns.UI.ShowEnemy(key) end end
    if death.sure == false or e.status == "suspect" then
      Banner(L.BANNER_SUSPECT, name, rgb, L.BANNER_SUSPECT_LINE, nil, false, key, open)
    elseif (e.kills or 0) <= 1 then
      Banner(L.BANNER_NEW, name, rgb, L.BANNER_NEW_LINE, nil, false, key, open)
    else
      local rank = S.Rank(key)
      Banner(L.BANNER_AGAIN, name, rgb, Fmt(L.BANNER_AGAIN_LINE, { count = e.kills }),
             rank == 1 and "nr1" or nil, false, key, open)
    end
    -- accomplices are in the book now too and mostly still in sight: no popup for them either
    local others = death.others
    if type(others) ~= "table" and type(e.deaths) == "table" and e.deaths[1] and e.deaths[1].t == death.t then
      others = e.deaths[1].others
    end
    if type(others) == "table" then
      for i = 1, #others do Silence(others[i]) end
    end
  else
    local n = type(death.candidates) == "table" and #death.candidates or 0
    if n > 0 then
      Banner(L.BANNER_UNCLEAR, Fmt(L.BANNER_CANDIDATES, { count = n }), nil, L.BANNER_UNCLEAR_LINE, nil,
             false, nil, function() if ns.UI and ns.UI.ShowCase then ns.UI.ShowCase(death) end end)
    end
  end
end

local function OnRevenge(key)
  if not ready then return end
  local e = key and ns.Store.Get(key)
  if not e then return end
  local r, g, b = Look.ClassRGB(e.class)
  Banner(L.BANNER_REVENGE, Look.Name(e), { r, g, b },
         Fmt(L.BANNER_REVENGE_LINE, { count = e.revenge or 1 }), "rache", false, key)
  Look.Alarm("revenge")
end

-- 1.2.1: a revenge noted by hand was taken back: if its notice is still up, it goes away
local function OnRevengeUndone(key)
  if not (banner and banner:IsShown() and banner.key == key and banner.kind == "rache") then return end
  banner.inAnim:Stop(); banner.anim:Stop(); banner:Hide(); banner:SetAlpha(0)
  banner.open, banner.key, banner.kind, banner.guild = nil, nil, nil, false
  banner:EnableMouse(false)
  if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
end

-- 1.2.1: a guildmate or friend took down a killer who is in the own book: a chat line and the short
-- sound of the revenge notice, no window (if he is also a hit list target, only the taken-down notice comes)
local function OnAvenged(key, char, t)
  if not ready or type(key) ~= "string" or Look.Secret(key) or type(char) ~= "string" or Look.Secret(char) then return end
  local e = ns.Store.Get(key)
  local name = e and Look.Name(e) or (key:match("^([^%-]+)") or key)
  if ns.Util and ns.Util.Print then ns.Util.Print(Fmt(L.CHAT_AVENGED, { name = Look.First(char), killer = name })) end
  Look.Alarm("revenge")
end

-- A guildmate (1.2.0: or friend) was just killed: "first name" large, below it
-- "killed by <name> · <zone>"
local function ShowGuild(tat, key, src)
  local g = Look.GCall("Get", key, "all")
  local killer = g and Look.Name(g) or (type(key) == "string" and (key:match("^([^%-]+)") or key)) or "?"
  local by = Fmt(L.BANNER_KILLED_BY, { name = killer })
  local line = { Look.Join(by, type(tat.zone) == "string" and tat.zone or nil), by }
  Banner(src == "friends" and L.BANNER_FRIENDS or L.BANNER_GUILD, Look.First(tat.victim), Look.BONE, line, nil, true,
         type(key) == "string" and key or nil)
end

-- A hit list target was taken down (1.2.0): name large, below it who and when, stamp
local function ShowBagged(key, char, t)
  local h = Look.GCall("Hunt", key, "all")
  local name = h and Look.Name(h) or (key:match("^([^%-]+)") or key)
  local rgb
  if h then local r, g, b = Look.ClassRGB(h.class); rgb = { r, g, b } end
  local line = Fmt(L.BANNER_BAGGED, { name = Look.First(char), time = Look.Ago(t) })
  Banner(L.BANNER_HUNT, name, rgb, line, "hunt", true, key)
end

-- waiting notices: { function, arguments ... }
NextGuild = function()
  if banner and banner:IsShown() then return end
  local q = table.remove(guildQueue, 1)
  if q then q[1](q[2], q[3], q[4], q[5], q[6]) end
end

local function Later(fn, a, b, c, d, e)
  if banner and banner:IsShown() then
    if #guildQueue < GUILD_QUEUE_MAX then guildQueue[#guildQueue + 1] = { fn, a, b, c, d, e } end
    return
  end
  fn(a, b, c, d, e)
end

local function OnGuildKill(tat, key, src)
  if not ready or type(tat) ~= "table" or not Look.HasGuild() then return end
  if Look.GuildSetting("announce") ~= true then return end
  if type(tat.victim) ~= "string" or Look.Secret(tat.victim) or tat.victim == "" then return end
  if tat.victim == Look.Me() then return end      -- the own death has its own notice
  Later(ShowGuild, tat, key, src)
end

-- One event, one window: the own killing blow on a killer from the own book already has the
-- revenge notice; then no second one. If the revenge notice does not show him (e.g. pardoned, 1.2.0 fix),
-- the taken-down notice comes. Own switch guild.announceHunt (1.2.0 fix: none before).
local function OnBagged(key, char, t, src)
  if not ready or type(key) ~= "string" or Look.Secret(key) or type(char) ~= "string" or type(t) ~= "number" then return end
  if Look.GuildSetting("announceHunt") == false then return end
  if src == "self" and Extras.BannerShows(key) then return end
  Later(ShowBagged, key, char, t)
end

-- New targets of others on the hit list (1.2.0): one line for several ("3 new targets").
-- 1.2.0: releases from the friends' book name the releaser with his full name (a friend listed
-- without surname is bound provisionally: the player sees who it really is)
-- 1.2.0: new releases from guild and friends come as one chat line, not as a window (the list shows
-- them, the alarm reports the target when it shows up). If the one target is in sight right now: the normal alarm.
local function ChatNew(count, key, by, src, one)
  local h = Look.GCall("Hunt", key, "all")
  local who = src == "friends" and by or Look.First(by)
  local text
  if count <= 1 and h then
    text = Look.Join(Look.Name(h), Fmt(L.HUNT_LINE_BY, { names = who }), type(h.why) == "string" and h.why ~= "" and h.why or nil)
  else
    text = Look.Join(Fmt(L.BANNER_NEW_HUNTS, { count = count }), L.BANNER_NEW_HUNTS_LINE,
                     one and Fmt(L.HUNT_LINE_BY, { names = who }) or nil)
  end
  if ns.Util and ns.Util.Print then ns.Util.Print(text) end
end

local function OnNewHunt(count, key, by, src, one, list)
  if not ready or type(count) ~= "number" or count < 1 or type(key) ~= "string" or type(by) ~= "string" then return end
  if type(list) ~= "table" or #list == 0 then list = { { key = key, by = by, src = src } } end
  -- every new target in sight gets the normal alarm (its own switch "warn"), whatever "announce" says;
  -- the rest goes into the one chat line
  local rest = {}
  local T, A = ns.Tracker, ns.Alert
  for i = 1, #list do
    local x = list[i]
    local shown = false
    if type(x) == "table" and type(x.key) == "string" and T and T.UnitFor and A and A.GuildSpotted then
      local ok, unit = pcall(T.UnitFor, x.key)
      if ok and type(unit) == "string" and not Look.Secret(unit) then
        A.GuildSpotted(x.key, unit, "other", "hunt")
        shown = A.Shows and A.Shows(x.key) or false
      end
    end
    if not shown and type(x) == "table" and type(x.key) == "string" and type(x.by) == "string" then rest[#rest + 1] = x end
  end
  if #rest == 0 or Look.GuildSetting("announceHunt") == false then return end
  local same = true
  for i = 2, #rest do if rest[i].by ~= rest[1].by then same = false; break end end
  if #rest == #list then same = one == true end
  ChatNew(#rest, rest[1].key, rest[1].by, rest[1].src, same)
end

ns:On("READY", function()
  ready = true
  HookTooltip()
  -- 1.3.0: build the notice now, hidden, so its first appearance equals every later one
  if not banner then BuildBanner() end
end)
ns:On("DEATH_RECORDED", OnDeath)
ns:On("REVENGE", OnRevenge)
ns:On("REVENGE_UNDONE", OnRevengeUndone)
ns:On("AVENGED", OnAvenged)
ns:On("GUILD_KILL", OnGuildKill)
ns:On("HUNT_BAGGED", OnBagged)
ns:On("HUNT_NEW", OnNewHunt)
