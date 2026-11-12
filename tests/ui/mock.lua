-- Mini mock of the WoW UI for the smoke test of Alert/UI/Extras (luajit, Lua 5.1).
-- Widget methods only as listed per object type (WHITELIST below): an unlisted method is nil as in the
-- game (calling it throws, "if f.X then" falls back). Unknown GLOBAL names throw an error,
-- so typos in API names show up. The mock also checks:
--  * secure frames: Show/Hide/SetAttribute/SetPoint/... in combat  -> violation
--  * frame types and templates against a list
--  * backdrop methods only with BackdropTemplate
--  * own texture paths must exist as files, fonts must be client fonts
--  * new global variables only from an allowed list

local M = {}
M.violations = {}
M.created = 0
M.frames = {}
M.timers = {}
M.sounds = {}
M.popups = {}
M.anims = {}
M.combat = false
M.now = 1000
M.mediaDir = nil          -- set by the run
M.addon = "DeathNote"     -- folder name as the client passes it
M.secrets = { SECRET_NAME = true, SECRET_UNIT = true, SECRET_GUID = true }
-- switches for fallback tests
M.fontFails = false       -- SetFont returns false (font cannot be loaded)
M.textureFails = false    -- SetTexture returns false (file missing)
M.setUnitResult = true    -- return value of PlayerModel:SetUnit (client: false if there is no model)
M.secureHideFails = false -- Hide on secure frames has no effect (blocked action)
M.uiScale = 1             -- scale of UIParent (GetEffectiveScale)

local function violation(msg)
  M.violations[#M.violations + 1] = msg
end

local FRAME_TYPES = { Frame = true, Button = true, CheckButton = true, EditBox = true, ScrollFrame = true,
  Slider = true, PlayerModel = true, GameTooltip = true, StatusBar = true, Cooldown = true }
local TEMPLATES = { BackdropTemplate = true, SecureActionButtonTemplate = true, UIPanelCloseButton = true,
  UICheckButtonTemplate = true, UIPanelScrollFrameTemplate = true, UIPanelButtonTemplate = true,
  InputBoxTemplate = true, GameTooltipTemplate = true }
-- client fonts that are attested in installed addons (OpenMap, ElvUI-LibSharedMedia)
local FONTS = { ["Fonts\\MORPHEUS.TTF"] = true, ["Fonts\\MORPHEUS_CYR.TTF"] = true, ["Fonts\\FRIZQT__.TTF"] = true,
  ["Fonts\\NIM_____.ttf"] = true, ["Fonts\\SKURRI.TTF"] = true, ["Fonts\\SKURRI_CYR.TTF"] = true,
  ["Fonts\\ARIALN.TTF"] = true,
  -- 1.2.0: fonts per script system (Locale.FONTS), attested in the installed addons
  -- (DBM-Core StandardFont.lua, LibSharedMedia-3.0 in ForeverAuras)
  ["Fonts\\FRIZQT___CYR.TTF"] = true, ["Fonts\\2002.TTF"] = true, ["Fonts\\2002B.TTF"] = true,
  ["Fonts\\ARKai_T.ttf"] = true, ["Fonts\\ARHei.ttf"] = true, ["Fonts\\bKAI00M.ttf"] = true,
  ["Fonts\\bLEI00D.ttf"] = true, ["Fonts\\bHEI00M.ttf"] = true }
local BACKDROP = { SetBackdrop = true, SetBackdropColor = true, SetBackdropBorderColor = true }
local SECURE_GUARDED = { Show = true, Hide = true, SetShown = true, SetAttribute = true, SetPoint = true,
  ClearAllPoints = true, SetSize = true, SetWidth = true, SetHeight = true, SetAllPoints = true,
  StartMoving = true, SetParent = true, EnableMouse = true }

-- Methods per object type (with inheritance), following the WoW widget API. Add new methods here
-- once they are attested in an installed addon.
local function set(list, base)
  local t = {}
  if base then for k in pairs(base) do t[k] = true end end
  for k in list:gmatch("%S+") do t[k] = true end
  return t
end
local REGION = set([[Show Hide SetShown IsShown IsVisible SetPoint ClearAllPoints GetPoint SetAllPoints SetSize
  SetWidth SetHeight GetWidth GetHeight GetSize GetCenter GetLeft GetRight GetTop GetBottom SetAlpha GetAlpha
  GetParent GetName CreateAnimationGroup GetEffectiveScale IsForbidden GetObjectType IsObjectType]])
local FRAME = set([[SetScript GetScript HookScript HasScript CreateTexture CreateMaskTexture CreateFontString
  SetFrameStrata GetFrameStrata SetFrameLevel GetFrameLevel EnableMouse IsMouseEnabled EnableMouseWheel SetMovable
  RegisterForDrag StartMoving StopMovingOrSizing SetUserPlaced SetClampedToScreen SetScale GetScale Raise Lower
  SetAttribute GetAttribute IsProtected RegisterEvent UnregisterEvent SetParent SetToplevel IsMouseOver
  SetMouseClickEnabled]], REGION)   -- SetMouseClickEnabled: ForeverAuras RegionTypes/Text.lua:203, WhatsTraining Forever/Settings.lua:86
local BUTTON = set([[RegisterForClicks SetHighlightTexture SetNormalTexture SetPushedTexture Click Enable Disable
  SetEnabled IsEnabled]], FRAME)
local WHITELIST = {
  Texture = set([[SetTexture GetTexture SetColorTexture SetTexCoord SetVertexColor SetDesaturated SetBlendMode
    SetRotation SetDrawLayer SetAtlas]], REGION),
  FontString = set([[SetFont SetFontObject SetText GetText SetFormattedText SetTextColor SetShadowOffset
    SetShadowColor SetJustifyH SetJustifyV SetWordWrap SetMaxLines SetSpacing GetStringWidth GetStringHeight
    IsTruncated SetRotation SetNonSpaceWrap GetUnboundedStringWidth]], REGION),
  Frame = FRAME,
  Button = BUTTON,
  CheckButton = set("SetChecked GetChecked", BUTTON),
  EditBox = set([[SetText GetText SetFocus ClearFocus HasFocus SetAutoFocus SetMaxLetters SetMultiLine
    HighlightText SetFont SetFontObject SetTextColor SetTextInsets SetJustifyH SetCursorPosition Insert]], FRAME),
  Slider = set([[SetOrientation SetMinMaxValues GetMinMaxValues SetValue GetValue SetValueStep SetObeyStepOnDrag
    SetThumbTexture]], FRAME),
  ScrollFrame = set("SetScrollChild SetVerticalScroll GetVerticalScroll GetVerticalScrollRange", FRAME),
  PlayerModel = set("SetUnit ClearModel SetCamDistanceScale SetPortraitZoom SetPosition SetFacing", FRAME),
  GameTooltip = set("SetOwner SetText AddLine AddDoubleLine GetUnit ClearLines NumLines", FRAME),
  StatusBar = set("SetMinMaxValues SetValue GetValue SetStatusBarTexture SetStatusBarColor", FRAME),
  Cooldown = set("SetCooldown Clear", FRAME),
  AnimationGroup = set([[Play Stop Pause Finish IsPlaying CreateAnimation SetScript GetScript HookScript SetLooping
    SetToFinalAlpha GetParent]]),
  Animation = set([[SetDuration SetFromAlpha SetToAlpha SetOrder SetSmoothing SetStartDelay SetScaleFrom SetScaleTo
    SetTarget SetScript SetDegrees SetOrigin SetOffset]]),   -- Humor (1.2.0): Rotation/Translation, ForeverAuras/BlizzardAuraDisplay.lua:1825-1828
}
M.WHITELIST = WHITELIST
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6,
  FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
M.STRATA = STRATA

local function noop() end
local Obj = {}

local function fileExists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

local function new(kind, name, parent, template)
  M.created = M.created + 1
  local o = { _kind = kind, _name = name, _parent = parent, _shown = true, _scripts = {}, _attr = {},
              _points = {}, _w = 100, _h = 20, _text = nil, _template = template or "",
              _mouse = (kind == "Button" or kind == "CheckButton" or kind == "EditBox" or kind == "Slider") }
  if kind ~= "Texture" and kind ~= "FontString" and kind ~= "AnimationGroup" and kind ~= "Animation" then
    o._shown = (kind == "Frame" or kind == "Button") and true or true
  end
  -- 1.2.2: where the object was made (only for the layout guard, M.trace): first addon file in the stack
  if M.trace then
    for lvl = 3, 10 do
      local info = debug.getinfo(lvl, "Sln")
      if not info then break end
      local src = info.source or ""
      local helper = ({ Text = true, Label = true, InkButton = true, WordButton = true, WordTab = true, Stepper = true })[info.name or ""]
      if src:find("DeathNote/[%w]+%.lua$") and not helper then o._src = src:match("([%w]+%.lua)$") .. ":" .. tostring(info.currentline); break end
    end
  end
  o._secure = (template or ""):find("Secure") ~= nil
  o._backdrop = (template or ""):find("BackdropTemplate") ~= nil
  setmetatable(o, Obj)
  M.frames[#M.frames + 1] = o
  return o
end
M.new = new

local methods = {}
Obj.__index = function(o, k)
  -- API methods (capitalised) only as listed for the type; own fields are nil unless set
  if type(k) ~= "string" or not k:find("^%u") then return nil end
  local wl = WHITELIST[o._kind]
  if not (wl and wl[k]) and not (BACKDROP[k] and o._backdrop) then
    if BACKDROP[k] then error("Backdrop-Methode ohne BackdropTemplate: " .. k, 2) end
    M.unknown = M.unknown or {}
    M.unknown[o._kind .. ":" .. k] = true
    return nil
  end
  local m = methods[k]
  if m then
    if o._secure and SECURE_GUARDED[k] and M.combat then
      return function(...)
        violation("Geschuetzte Aktion im Kampf: " .. tostring(o._name) .. ":" .. k)
        return m(...)
      end
    end
    if BACKDROP[k] and not o._backdrop then
      error("Backdrop-Methode ohne BackdropTemplate: " .. k, 2)
    end
    return m
  end
  if o._secure and SECURE_GUARDED[k] and M.combat then
    return function() violation("Geschuetzte Aktion im Kampf: " .. tostring(o._name) .. ":" .. k) end
  end
  return noop
end

-- remember layer and sublayer (for the still image from the mock, tests/ui/render)
function methods.CreateTexture(self, _, layer, _, sub)
  local t = new("Texture", nil, self); t._layer, t._sub = layer or "ARTWORK", sub or 0; return t
end
function methods.CreateMaskTexture(self) return new("Texture", nil, self) end
function methods.CreateFontString(self, _, layer, _, sub)
  local t = new("FontString", nil, self); t._layer, t._sub = layer or "ARTWORK", sub or 0; return t
end
function methods.CreateAnimationGroup(self)
  local g = new("AnimationGroup", nil, self)
  g._target = self
  g._playing = false
  M.anims[#M.anims + 1] = g
  return g
end
function methods.CreateAnimation(self, typ)
  if typ ~= "Alpha" and typ ~= "Scale" and typ ~= "Rotation" and typ ~= "Translate" and typ ~= "Translation" then
    error("unbekannter Animationstyp " .. tostring(typ), 2)
  end
  local a = new("Animation", nil, self)
  if typ == "Scale" then a.SetScaleFrom = noop; a.SetScaleTo = noop end
  return a
end
function methods.Play(self) self._playing = true end
function methods.Stop(self) self._playing = false end
function methods.IsPlaying(self) return self._playing end
function methods.SetToFinalAlpha(self, v) self._toFinal = v and true or false end

function methods.Show(self) self._shown = true; local f = self._scripts.OnShow; if f then f(self) end end
function methods.Hide(self)
  if self._secure and M.secureHideFails then return end   -- blocked: the frame stays visible
  local was = self._shown
  self._shown = false
  local f = self._scripts.OnHide
  if f and was then f(self) end
end
function methods.SetShown(self, v) if v then methods.Show(self) else methods.Hide(self) end end
function methods.IsShown(self) return self._shown end
function methods.IsVisible(self)
  local o = self
  while o do
    if not o._shown then return false end
    o = o._parent
  end
  return true
end

function methods.SetScript(self, k, f) self._scripts[k] = f end
function methods.GetScript(self, k) return self._scripts[k] end
function methods.HookScript(self, k, f)
  local old = self._scripts[k]
  self._scripts[k] = old and function(...) old(...); f(...) end or f
end
function methods.HasScript() return true end

M.texts = {}               -- every text ever set (guards for wording and time formats)
function methods.SetText(self, t)
  if t ~= nil and type(t) ~= "string" and type(t) ~= "number" then
    error("SetText mit " .. type(t), 2)
  end
  self._text = t
  if type(t) == "string" and t ~= "" and self._kind ~= "EditBox" then M.texts[t] = true end
end
function methods.GetText(self) return self._text end
function methods.SetFormattedText(self, fmt, ...) self._text = string.format(fmt, ...) end

function methods.SetAttribute(self, k, v) self._attr[k] = v end
function methods.GetAttribute(self, k) return self._attr[k] end
function methods.IsProtected(self) return self._secure end

function methods.SetSize(self, w, h) self._w, self._h = w, h; self._wset, self._hset = true, true end
function methods.SetWidth(self, w) self._w = w; self._wset = true end
function methods.SetHeight(self, h) self._h = h; self._hset = true end
function methods.SetAllPoints(self, rel)
  self._points = { { "TOPLEFT", rel or self._parent, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", rel or self._parent, "BOTTOMRIGHT", 0, 0 } }
end
function methods.SetVertexColor(self, r, g, b, a) self._vc = { r, g, b, a or 1 } end
function methods.SetTextColor(self, r, g, b, a) self._tc = { r, g, b, a or 1 } end
function methods.SetDesaturated(self, v) self._desat = v and true or false end
function methods.SetRotation(self, r) self._rot = r end
function methods.SetJustifyH(self, j) self._jh = j end
function methods.SetJustifyV(self, j) self._jv = j end
function methods.SetWordWrap(self, v) self._wrap = v and true or false end
function methods.SetMaxLines(self, n) self._maxl = n end
function methods.SetSpacing(self, n) self._spacing = n end
function methods.SetShadowOffset(self, x, y) self._shadow = { x, y } end
function methods.SetBackdrop(self, b) self._bd = b end
function methods.SetBackdropColor(self, r, g, b, a) self._bdc = { r, g, b, a or 1 } end
function methods.SetBackdropBorderColor(self, r, g, b, a) self._bdb = { r, g, b, a or 1 } end
function methods.SetBlendMode(self, m) self._blend = m end
function methods.GetWidth(self) return self._w end
function methods.GetHeight(self) return self._h end
-- Geometry as in the client: rectangle from the single anchor point and the size, computed in UIParent
-- units (offset and size in the frame's scale), returned in the frame's scale.
-- Frames without an anchor, with several anchors or outside UIParent: nil (like a frame not laid out yet).
local ANCH = { TOPLEFT = { 0, 1 }, TOP = { 0.5, 1 }, TOPRIGHT = { 1, 1 }, LEFT = { 0, 0.5 }, CENTER = { 0.5, 0.5 },
  RIGHT = { 1, 0.5 }, BOTTOMLEFT = { 0, 0 }, BOTTOM = { 0.5, 0 }, BOTTOMRIGHT = { 1, 0 } }
local function relScale(f)
  local s, o = 1, f
  while o and o ~= M.G.UIParent do s = s * (o._scale or 1); o = o._parent end
  return s, o == M.G.UIParent
end
local function rectUI(f, depth)
  if f == M.G.UIParent then return 0, 0, f._w, f._h end
  depth = (depth or 0) + 1
  -- scroll child (1.2.2): sits at the top left of its ScrollFrame, moved up by the offset
  local pt
  if f._parent and f._parent._child == f then
    pt = { "TOPLEFT", f._parent, "TOPLEFT", 0, f._parent._vscroll or 0 }
  end
  if depth > 20 then return nil end
  -- 1.2.2 (only with M.measure, older tests expect nil): several anchors like the client, edges first per axis
  if not pt and M.measure and f._points and #f._points >= 2 then
    local s, ok = relScale(f)
    if not ok then return nil end
    local xs, ys = {}, {}
    for _, q0 in ipairs(f._points) do
      local p, rel, rp, x, y = q0[1], q0[2], q0[3], q0[4], q0[5]
      if type(rel) == "number" then rel, rp, x, y = f._parent, p, q0[2], q0[3]
      elseif type(rel) == "string" then rel, rp, x, y = f._parent, rel, q0[3], q0[4] end
      rel, rp, x, y = rel or f._parent, rp or p, x or 0, y or 0
      if not ANCH[rp] or not ANCH[p] or not rel then return nil end
      local l, b, r, t = rectUI(rel, depth)
      if not l then return nil end
      local a, q = ANCH[rp], ANCH[p]
      xs[q[1]] = l + (r - l) * a[1] + x * s
      ys[q[2]] = b + (t - b) * a[2] + y * s
    end
    local fw, fh = f._w * s, f._h * s
    if M.measure and f._kind == "FontString" and not f._hset then fh = (methods.GetStringHeight(f) or f._h) * s end
    local L, R, B, T
    if xs[0] and xs[1] then L, R = xs[0], xs[1]
    elseif xs[0] then L, R = xs[0], xs[0] + fw elseif xs[1] then L, R = xs[1] - fw, xs[1]
    elseif xs[0.5] then L, R = xs[0.5] - fw / 2, xs[0.5] + fw / 2 else return nil end
    if ys[0] and ys[1] then B, T = ys[0], ys[1]
    elseif ys[1] then B, T = ys[1] - fh, ys[1] elseif ys[0] then B, T = ys[0], ys[0] + fh
    elseif ys[0.5] then B, T = ys[0.5] - fh / 2, ys[0.5] + fh / 2 else return nil end
    return L, B, R, T
  end
  if not pt and (not f._points or #f._points ~= 1) then return nil end
  pt = pt or f._points[1]
  local p, rel, rp, x, y = pt[1], pt[2], pt[3], pt[4], pt[5]
  if type(rel) == "number" then rel, rp, x, y = f._parent, p, pt[2], pt[3]
  elseif type(rel) == "string" then rel, rp, x, y = f._parent, rel, pt[3], pt[4] end
  rel, rp, x, y = rel or f._parent, rp or p, x or 0, y or 0
  local s, ok = relScale(f)
  if not ok or not rel or not ANCH[rp] or not ANCH[p] then return nil end
  local l, b, r, t = rectUI(rel, depth)
  if not l then return nil end
  local a, q = ANCH[rp], ANCH[p]
  local px, py = l + (r - l) * a[1] + x * s, b + (t - b) * a[2] + y * s
  local fw, fh = f._w, f._h
  -- 1.2.2: with M.measure a text without its own width is as wide and high as its text (like the client)
  if M.measure and f._kind == "FontString" then
    if not f._wset then fw = M.Unbounded(f) or 0 end
    if not f._hset then fh = methods.GetStringHeight(f) or fh end
  end
  local w, h = fw * s, fh * s
  local L, B = px - w * q[1], py - h * q[2]
  return L, B, L + w, B + h
end
M.RectUI = rectUI
local function edge(i)
  return function(self)
    local r = { rectUI(self) }
    if not r[1] then return nil end
    return r[i] / (relScale(self))
  end
end
methods.GetLeft, methods.GetBottom, methods.GetRight, methods.GetTop = edge(1), edge(2), edge(3), edge(4)
function methods.GetCenter(self)
  if self._cx then return self._cx, self._cy end
  local l, b, r, t = rectUI(self)
  if not l then return 640, 600 end
  local s = relScale(self)
  return (l + r) / 2 / s, (b + t) / 2 / s
end
function methods.SetScale(self, s) self._scale = s end
function methods.SetAlpha(self, a) self._alpha = a end
function methods.GetAlpha(self) return self._alpha or 1 end
function methods.GetScale(self) return self._scale or 1 end
function methods.GetEffectiveScale(self)
  local s, o = 1, self
  while o do
    s = s * (o._scale or 1)
    if o == M.G.UIParent then s = s * M.uiScale end
    o = o._parent
  end
  return s
end
function methods.SetFrameStrata(self, s)
  if not STRATA[s] then error("unbekannte Schicht " .. tostring(s), 2) end
  self._strata = s
end
function methods.GetFrameStrata(self)
  local o = self
  while o do if o._strata then return o._strata end o = o._parent end
  return "MEDIUM"
end
function methods.SetFrameLevel(self, l) self._level = l end
function methods.GetFrameLevel(self) return self._level or 5 end
-- _mouse: the frame takes clicks; _motion: it takes the hover (EnableMouse sets both, SetMouseClickEnabled only clicks)
function methods.EnableMouse(self, v) self._mouse = v and true or false; self._motion = self._mouse end
function methods.SetMouseClickEnabled(self, v) self._mouse = v and true or false end
function methods.IsMouseEnabled(self) return self._mouse or self._motion or false end
-- like the client: a dragged, named frame ends up in layout-local.txt until SetUserPlaced(false)
function methods.StartMoving(self) self._moving = true; self._userPlaced = true end
function methods.StopMovingOrSizing(self) self._moving = false end
function methods.SetUserPlaced(self, v) self._userPlaced = v and true or false end
function methods.SetFontObject(self, o) self._fontObject = o end
-- Text width: measured in the client; in the mock only with M.measure an estimate, otherwise nil like a
-- text that is not laid out yet (the fallbacks of the UI then run too).
-- 1.2.2: factors at the wide end of the real fonts (calibrated against the client screenshot of round 1.2.2):
-- em width per character for mixed case; text that is mostly capitals counts 0.70 per letter (stamps, labels),
-- CJK and Hangul 1.07 em, spaces 0.30 em in capitals text. Line height 1.10 x size (plus SetSpacing).
local WIDTH = { ["Fonts\\MORPHEUS.TTF"] = 0.56, ["Fonts\\MORPHEUS_CYR.TTF"] = 0.60, ["Fonts\\FRIZQT__.TTF"] = 0.56,
  ["Fonts\\FRIZQT___CYR.TTF"] = 0.58, ["Fonts\\NIM_____.ttf"] = 0.60, ["Fonts\\SKURRI.TTF"] = 0.70,
  ["Fonts\\SKURRI_CYR.TTF"] = 0.70, ["Fonts\\ARIALN.TTF"] = 0.45 }
M.WIDTH, M.CAPS, M.CJK, M.LINE = WIDTH, 0.70, 1.07, 1.10
local function wideCp(cp)
  return (cp >= 0x1100 and cp <= 0x115F) or (cp >= 0x2E80 and cp <= 0xA4CF) or (cp >= 0xAC00 and cp <= 0xD7A3)
    or (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0xFE30 and cp <= 0xFE4F) or (cp >= 0xFF00 and cp <= 0xFF60)
end
-- characters of a string: { width in em, is a space } (colour codes removed)
local function glyphs(text, font)
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  local f = WIDTH[font] or 0.56
  local up, low = 0, 0
  for c in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local b1, b2 = c:byte(1), c:byte(2)
    if (b1 >= 65 and b1 <= 90) or (b1 == 0xC3 and b2 and b2 >= 0x80 and b2 <= 0x9E) or (b1 == 0xD0 and b2 and b2 >= 0x80 and b2 <= 0xAF) then up = up + 1
    elseif (b1 >= 97 and b1 <= 122) or (b1 == 0xC3 and b2 and b2 >= 0x9F) or (b1 == 0xD0 and b2 and b2 >= 0xB0) or b1 == 0xD1 then low = low + 1 end
  end
  local caps = up > 0 and up >= low
  local out = {}
  for c in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local b = c:byte(1)
    local cp = b
    if #c == 3 then cp = (b - 0xE0) * 4096 + (c:byte(2) - 128) * 64 + (c:byte(3) - 128) end
    if c == " " then out[#out + 1] = { caps and 0.30 or f, true }
    elseif c == "\n" then out[#out + 1] = { 0, "\n" }
    elseif #c == 3 and wideCp(cp) then out[#out + 1] = { M.CJK, false, true }
    else out[#out + 1] = { caps and math.max(f, M.CAPS) or f, false } end
  end
  return out
end
-- width of the text on one line (widest line when the text has line breaks)
function M.Unbounded(self)
  if type(self._text) ~= "string" then return nil end
  local size, best, w = self._fontSize or 12, 0, 0
  for _, g in ipairs(glyphs(self._text, self._font)) do
    if g[2] == "\n" then w = 0 else w = w + g[1] * size end
    if w > best then best = w end
  end
  return best
end
-- width a text gets from its frame: SetWidth, or two horizontal anchors (left edge of the first, right of the second)
function M.EffWidth(self)
  if self._wset then return self._w end
  local pts = self._points
  if #pts == 2 then
    local a, b = pts[1], pts[2]
    local function xOf(pt)
      local p, rel, rp, x = pt[1], pt[2], pt[3], pt[4]
      if type(rel) == "number" then rel, rp, x = self._parent, p, rel
      elseif type(rel) == "string" then rel, rp, x = self._parent, rel, pt[3] end
      rel, rp, x = rel or self._parent, rp or p, x or 0
      local l, _, r = M.RectUI(rel)
      if not l then return nil end
      local ax = rp:find("LEFT") and 0 or rp:find("RIGHT") and 1 or 0.5
      return l + (r - l) * ax + x
    end
    local l, r = xOf(a), xOf(b)
    if l and r and r > l then return r - l end
  end
  return nil
end
-- greedy word wrap like the client: lines needed and whether a single word is wider than the line
function M.Lines(self)
  if type(self._text) ~= "string" or self._text == "" then return 0, false end
  local width = M.EffWidth(self)
  local size = self._fontSize or 12
  if self._wrap == false or not width then return 1, false end
  local lines, w, word, wide = 1, 0, 0, false
  local function flushWord()
    if w > 0 and w + word > width + 0.5 then lines = lines + 1; w = 0 end
    if word > width + 0.5 then wide = true end
    w = w + word; word = 0
  end
  for _, g in ipairs(glyphs(self._text, self._font)) do
    if g[2] == "\n" then flushWord(); lines = lines + 1; w = 0
    elseif g[2] then flushWord(); w = w + g[1] * size
    elseif g[3] then flushWord(); word = g[1] * size; flushWord()   -- CJK breaks between characters
    else word = word + g[1] * size end
  end
  flushWord()
  return lines, wide
end
function methods.GetStringWidth(self)
  if not M.measure then return nil end
  return M.Unbounded(self)
end
function methods.GetUnboundedStringWidth(self)
  if not M.measure then return nil end
  return M.Unbounded(self)
end
function methods.GetStringHeight(self)
  if not M.measure or type(self._text) ~= "string" then return nil end
  local n = M.Lines(self)
  if self._maxl and self._maxl > 0 and n > self._maxl then n = self._maxl end
  local size = self._fontSize or 12
  return n * size * M.LINE + math.max(0, n - 1) * (self._spacing or 0)
end
function methods.IsTruncated(self)
  if not M.measure or type(self._text) ~= "string" then return nil end
  local width = M.EffWidth(self)
  if not width then return false end
  if self._wrap == false then return (M.Unbounded(self) or 0) > width + 0.5 end
  local n, wide = M.Lines(self)
  return wide or (self._maxl and self._maxl > 0 and n > self._maxl) or false
end
function methods.SetClampedToScreen(self, v) self._clamped = v and true or false end
-- ScrollFrame: child, offset, range (child height minus own height)
function methods.SetScrollChild(self, c) self._child = c end
function methods.SetVerticalScroll(self, v) self._vscroll = v end
function methods.GetVerticalScroll(self) return self._vscroll or 0 end
function methods.GetVerticalScrollRange(self)
  local c = self._child
  return c and math.max(0, (c._h or 0) - (self._h or 0)) or 0
end
function methods.EnableMouseWheel(self, v) self._wheel = v and true or false end
function methods.SetColorTexture(self, r, g, b, a) self._color = { r, g, b, a }; self._tex = nil end
function methods.GetName(self) return self._name end
function methods.GetParent(self) return self._parent end
function methods.SetParent(self, p) self._parent = p end
function methods.SetPoint(self, ...)
  local p = select(1, ...)
  if type(p) ~= "string" then error("SetPoint ohne Ankerpunkt", 2) end
  self._points[#self._points + 1] = { ... }
end
function methods.ClearAllPoints(self) self._points = {} end
function methods.GetPoint(self, i)
  local pt = self._points[i or 1]
  if not pt then return nil end
  -- WoW: point, relativeTo, relativePoint, x, y
  local p, a, b, c, d = pt[1], pt[2], pt[3], pt[4], pt[5]
  if type(a) == "number" then return p, nil, p, a, b end
  if type(a) == "string" then return p, nil, a, b, c end
  return p, a, b or p, c or 0, d or 0
end

function methods.SetFont(self, path, size, flags)
  if not FONTS[path] then error("Schrift nicht belegt: " .. tostring(path), 2) end
  if type(size) ~= "number" then error("Schriftgroesse fehlt", 2) end
  M.fontSizes = M.fontSizes or {}
  M.fontSizes[size] = true
  if M.fontFails then return false end
  self._font, self._fontSize, self._fontFlags = path, size, flags
  return true
end
function methods.SetTexture(self, path)
  if type(path) == "string" and M.mediaDir and path:find("^Interface\\AddOns\\" .. M.addon .. "\\Media\\") then
    local file = path:sub(#("Interface\\AddOns\\" .. M.addon .. "\\Media\\") + 1)
    if not fileExists(M.mediaDir .. "/" .. file) then error("Textur fehlt: " .. path, 2) end
  end
  if M.textureFails then return false end
  self._tex = path
  return true
end
function methods.SetTexCoord(self, ...)
  local n = select("#", ...)
  if n ~= 4 and n ~= 8 then error("SetTexCoord mit " .. n .. " Werten", 2) end
  self._tcoord = { ... }
end

function methods.SetChecked(self, v) self._checked = v and true or false end
function methods.GetChecked(self) return self._checked end
function methods.HasFocus(self) return self._focus or false end
function methods.SetFocus(self) self._focus = true end
function methods.ClearFocus(self)
  local had = self._focus
  self._focus = false
  if had and self._scripts.OnEditFocusLost then self._scripts.OnEditFocusLost(self) end
end
function methods.IsForbidden() return false end
function methods.SetMinMaxValues(self, a, b) self._min, self._max = a, b end
function methods.SetValue(self, v)
  self._value = v
  if self._scripts.OnValueChanged then self._scripts.OnValueChanged(self, v) end
end
function methods.GetValue(self) return self._value end

-- GameTooltip
function methods.SetOwner() end
function methods.AddLine(self, t)
  self._lines = self._lines or {}
  self._lines[#self._lines + 1] = t
end
function methods.GetUnit(self) return self._unitName, self._unit end

------------------------------------------------------------------------
-- global environment
------------------------------------------------------------------------
local G = {}
M.G = G
M.newGlobals = {}

G.CreateFrame = function(typ, name, parent, template)
  if not FRAME_TYPES[typ] then error("CreateFrame: unbekannter Typ " .. tostring(typ), 2) end
  if template then
    for t in template:gmatch("[^,%s]+") do
      if not TEMPLATES[t] then error("CreateFrame: unbekanntes Template " .. t, 2) end
    end
  end
  local f = new(typ, name, parent, template)
  if typ == "PlayerModel" then
    f.SetUnit = function(self, unit)
      if M.secrets[unit] then error("SetUnit mit Secret") end
      if M.setUnitResult == false then self._modelUnit = nil; return false end
      self._modelUnit = unit
      return true
    end
  end
  if name then G[name] = f end
  return f
end

G.UIParent = new("Frame", "UIParent")
-- screen 2560x1440; UIParent units = pixels / UI scale (author under ElvUI: 0.6)
function M.SetUIScale(sc)
  M.uiScale = sc
  G.UIParent._w, G.UIParent._h = 2560 / sc, 1440 / sc
end
M.SetUIScale(1)
G.Minimap = new("Frame", "Minimap")
G._G = G   -- 1.2.2: optional globals (LibStub) are looked up with rawget(_G, name)
G.GameTooltip = new("GameTooltip", "GameTooltip")
G.GameFontNormal = {}
G.UISpecialFrames = {}
G.StaticPopupDialogs = {}
G.CANCEL = "Abbrechen"
G.StaticPopup_Show = function(which, a1, a2, data)
  if not G.StaticPopupDialogs[which] then error("StaticPopup ohne Dialog " .. tostring(which), 2) end
  M.popups[#M.popups + 1] = { which = which, text = a1, data = data }
end
G.GameTooltip_Hide = function() end
G.InCombatLockdown = function() return M.combat end
G.GetTime = function() return M.now end
G.time = function() return 1800000000 end
G.date = os.date
G.GetCursorPosition = function() return 100, 200 end
-- screen in pixels (OpenMap/Map/Stitch.lua:1858); M.ppu = pixels per UI unit
M.ppu = 1.5
G.GetPhysicalScreenSize = function() return G.UIParent._w * M.ppu, G.UIParent._h * M.ppu end
G.SetPortraitTexture = function(tex, unit)
  if M.secrets[unit] then error("SetPortraitTexture mit Secret") end
end
G.UnitTokenFromGUID = function(guid)
  if M.secrets[guid] then error("UnitTokenFromGUID mit Secret") end
  return nil
end
G.issecretvalue = function(v) return M.secrets[v] == true end
-- chat input (shift click): only insert when an input is open; never send
M.chatOpen = false
M.chatInserted = {}
M.shift = false
G.ChatFrameUtil = {
  GetActiveWindow = function() return M.chatOpen and G.UIParent or nil end,
  InsertLink = function(t) M.chatInserted[#M.chatInserted + 1] = t; return true end,
}
G.ChatEdit_GetActiveWindow = G.ChatFrameUtil.GetActiveWindow
G.ChatEdit_InsertLink = G.ChatFrameUtil.InsertLink
G.IsShiftKeyDown = function() return M.shift end
M.playerName = "Davee"
G.UnitName = function(unit)
  if unit == "player" then return M.playerName, M.playerSurname end
  return nil
end
-- 1.2.0 (fix-1, W2): level of a unit for the alarm. M.levels[unit] (number, nil or a secret through
-- M.levelFn); without an entry 40 like your own character (so no level difference).
M.levels = {}
M.levelFn = nil
G.UnitLevel = function(unit)
  if M.levelFn then return M.levelFn(unit) end
  local v = M.levels[unit]
  if v == false then return nil end
  return v or 40
end
G.LOCALIZED_CLASS_NAMES_MALE = { ROGUE = "Schurke", MAGE = "Magier", WARRIOR = "Krieger", PRIEST = "Priester" }
G.PlaySound = function(kit, ch)
  if type(kit) ~= "number" then error("PlaySound ohne SoundKit-ID", 2) end
  if ch ~= nil and ch ~= "Master" and ch ~= "SFX" and ch ~= "Dialog" and ch ~= "Music" and ch ~= "Ambience" then
    error("PlaySound: unbekannter Kanal " .. tostring(ch), 2)
  end
  M.sounds[#M.sounds + 1] = "kit:" .. kit
  M.soundCalls[#M.soundCalls + 1] = { kit = kit, channel = ch }
  return true, #M.sounds
end
-- like the client: willPlay, handle. Own files must be in the Media folder with exactly this case.
M.soundFileResult = nil   -- false forces "does not play"
M.soundCalls = {}
M.stopped = {}
G.PlaySoundFile = function(f, ch)
  M.soundCalls[#M.soundCalls + 1] = { file = f, channel = ch }
  if type(f) == "string" and M.mediaDir and f:find("^Interface\\AddOns\\" .. M.addon .. "\\Media\\") then
    local file = f:sub(#("Interface\\AddOns\\" .. M.addon .. "\\Media\\") + 1):gsub("\\", "/")
    if not fileExists(M.mediaDir .. "/" .. file) then return false end
  end
  if M.soundFileResult == false then return false end
  M.sounds[#M.sounds + 1] = "file:" .. tostring(f)
  return true, #M.sounds
end
G.StopSound = function(h) M.stopped[#M.stopped + 1] = h end
G.SOUNDKIT = { RAID_WARNING = 8959, LFG_REWARDS = 17316, IG_MAINMENU_OPTION_CHECKBOX_ON = 856,
               IG_MAINMENU_OPEN = 850 }
G.CLASS_ICON_TCOORDS = { WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 },
                         ROGUE = { 0.5, 0.73, 0, 0.25 }, PRIEST = { 0.5, 0.73, 0.25, 0.5 } }
G.TooltipDataProcessor = { AddTooltipPostCall = function(typ, fn) M.tooltipHook = fn end }
G.Enum = { TooltipDataType = { Unit = 2 } }
G.C_Timer = {
  After = function(sec, fn)
    if type(fn) ~= "function" then error("C_Timer.After ohne Funktion", 2) end
    M.timers[#M.timers + 1] = { at = M.now + sec, fn = fn }
  end,
  NewTimer = function(sec, fn)
    local t = { at = M.now + sec, fn = fn }
    t.Cancel = function(self) self.cancelled = true end
    M.timers[#M.timers + 1] = t
    return t
  end,
}
G.tinsert = table.insert
G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
G.math, G.string, G.table = math, string, table
G.pairs, G.ipairs, G.type, G.tostring, G.tonumber = pairs, ipairs, type, tostring, tonumber
G.select, G.pcall, G.error, G.unpack, G.next = select, pcall, error, unpack, next
G.setmetatable, G.getmetatable, G.rawget = setmetatable, getmetatable, rawget
G.print = function() end

-- allowed new globals from the UI files
local ALLOWED_NEW = { DeathNote_OnCompartmentClick = true, DeathNote_OnCompartmentEnter = true,
                      DeathNote_OnCompartmentLeave = true }

-- 1.2.2: what the real embedded LibDBIcon-1.0 (DeathNote/Libs) needs beyond the above, checked against
-- LibDBIcon-1.0.lua (tests/ui/minimap_real_libs.lua loads the real libraries into this mock)
for _, kind in ipairs({ "Frame", "Button", "CheckButton" }) do
  WHITELIST[kind].SetFixedFrameStrata = true
  WHITELIST[kind].SetFixedFrameLevel = true
end
WHITELIST.Button.LockHighlight, WHITELIST.Button.UnlockHighlight = true, true
WHITELIST.Texture.GetVertexColor = true
WHITELIST.GameTooltip.GetOwner = true
function methods.GetVertexColor(self)
  local c = self._vc or { 1, 1, 1, 1 }
  return c[1], c[2], c[3], c[4]
end
-- the tooltip remembers its owner (LibDBIcon's tooltip and our OnTooltipShow ask for it)
function methods.SetOwner(self, owner) self._owner = owner end
function methods.GetOwner(self) return self._owner end
-- the libraries' own globals (LibStub, the LibDBIcon tooltip and our button through LibDBIcon)
ALLOWED_NEW.LibStub, ALLOWED_NEW.LibDBIconTooltip, ALLOWED_NEW.LibDBIcon10_DeathNote = true, true, true

setmetatable(G, {
  __index = function(_, k) error("unbekannte globale Variable: " .. tostring(k), 2) end,
  __newindex = function(t, k, v)
    if not ALLOWED_NEW[k] and not tostring(k):find("^DeathNote") then
      violation("neue globale Variable: " .. tostring(k))
    end
    M.newGlobals[k] = true
    rawset(t, k, v)
  end,
})

-- Which of the frames would get a mouse click at the same spot? (visible, mouse on, highest strata,
-- then highest level; on a tie the last one named). The frames must overlap.
function M.TopFrame(...)
  local best, bs, bl
  for i = 1, select("#", ...) do
    local f = select(i, ...)
    if f and methods.IsVisible(f) and f._mouse then
      local s, l = STRATA[methods.GetFrameStrata(f)], f._level or 5
      if not best or s > bs or (s == bs and l >= bl) then best, bs, bl = f, s, l end
    end
  end
  return best
end

-- advance time and run due timers
function M.Advance(sec)
  M.now = M.now + sec
  local guard = 0
  local ran = true
  while ran and guard < 1000 do
    ran = false
    guard = guard + 1
    for i, t in ipairs(M.timers) do
      if t.at <= M.now then
        table.remove(M.timers, i)
        if not t.cancelled then t.fn() end
        ran = true
        break
      end
    end
  end
end

-- finish all running animation groups (fire OnFinished)
function M.FinishAnims()
  for _, g in ipairs(M.anims) do
    if g._playing then
      g._playing = false
      local f = g._scripts.OnFinished
      if f then f(g) end
    end
  end
end

function M.Load(path, ns)
  local chunk, err = loadfile(path)
  if not chunk then error(err) end
  setfenv(chunk, G)
  chunk(M.addon, ns)
end

-- 1.2.0: load the language framework into ns (Locale.lua, English, German, the chosen language) and
-- activate the language explicitly. dir: addon folder (default: the mock's). An old state without
-- Locale.lua stays without the framework.
local here = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$")) or "."
function M.LoadLocale(ns, code, dir)
  dir = dir or (here .. "/../../DeathNote")
  local f = io.open(dir .. "/Locale.lua", "r")
  if not f then return nil end
  f:close()
  M.Load(dir .. "/Locale.lua", ns)
  local files = { "enUS", "deDE" }
  if code ~= "enUS" and code ~= "deDE" then files[#files + 1] = code end
  for _, c in ipairs(files) do M.Load(dir .. "/Locales/" .. c .. ".lua", ns) end
  M.lang = ns.Locale.Activate(code)
  return M.lang
end

return M
