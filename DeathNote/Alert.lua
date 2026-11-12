local ADDON, ns = ...

-- Proximity alarm: wanted popup at the top centre, sound, red edge flash, a click targets.
-- Also ns.Look: shared look helpers for Alert, UI and Extras (fonts, textures, colours).

local Look = {}
ns.Look = Look
-- Texts (1.2.0): ns.L is filled from ADDON_LOADED on; read L.KEY inside functions only, never at file level
local L, Fmt = ns.L, ns.F

-- Media path always through the folder name (ADDON), never hard-wired
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
Look.MEDIA = MEDIA
-- 1.3.0: colours (Look.INK, Look.RED ... and Look.COLOR), textures (Look.TEX), tints, fallback colours, font roles
-- (Look.FONT) and tones (Look.TONE) come from the active theme (Theme.lua, Themes\<id>.lua). Theme.Fill writes
-- them into these tables in place; here: the base theme, the chosen one follows at ADDON_LOADED.
-- Fixed in every theme: the addon icon (minimap, addon list) and the client's technical textures.
Look.TEX = {
  icon    = MEDIA .. "icon.tga",
  white   = "Interface\\Buttons\\WHITE8X8",
  classes = "Interface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
}
Look.FONT = {}
Look.TONE = {}
if ns.Theme and ns.Theme.Fill then ns.Theme.Fill(Look) end
-- 1.2.0: fonts per script of the active language (Locale.FONTS); 1.3.0: role -> kind from the theme
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    if ns.Theme and ns.Theme.FillFonts then ns.Theme.FillFonts(Look) end
  end)
end

local issecret = issecretvalue or function() return false end
function Look.Secret(v) return issecret(v) and true or false end
-- Truth value that treats a secret as false (never a boolean test on secrets)
function Look.True(v)
  if issecret(v) then return false end
  return v and true or false
end

-- list (1.2.0, optional): own font list instead of Look.FONT[kind], e.g. for a language's own name
function Look.Font(fs, kind, size, flags, list)
  -- 1.2.2: kind, size and flags stay on the string (Look.FitText steps through the sizes of the same font)
  if not list then fs.fontKind, fs.fontSize, fs.fontFlags = kind, size, flags end
  list = list or Look.FONT[kind] or Look.FONT.body
  for i = 1, #list do
    if fs:SetFont(list[i], size or 12, flags or "") then return fs end
  end
  -- the client's standard font (covers its language), then the font object
  local std = ns.Locale and ns.Locale.Global and ns.Locale.Global("STANDARD_TEXT_FONT")
  if type(std) == "string" and fs:SetFont(std, size or 12, flags or "") then return fs end
  fs:SetFontObject(GameFontNormal)
  return fs
end

-- Font list for a text in a given language (language list of the house rules); kind is a role of the theme
function Look.FontOf(code, kind)
  kind = kind or "body"
  if ns.Locale and ns.Locale.FontList then return ns.Locale.FontList((Look.FONT_KIND and Look.FONT_KIND[kind]) or kind, code) end
  return Look.FONT[kind]
end

-- FontString in one go
function Look.Text(parent, kind, size, color, flags, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  Look.Font(fs, kind, size, flags)
  local c = color or Look.INK
  fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
  fs:SetShadowOffset(0, 0)
  return fs
end

-- Texture with a fallback colour (no green error square if the file is missing). 1.3.0: marks the texture while it
-- shows the fallback colour (dnFlat), so Look.Tint leaves that colour as it is
function Look.Tex(tex, path, r, g, b, a)
  local ok = tex:SetTexture(path)
  if ok == false then
    tex:SetColorTexture(r or 0.5, g or 0.4, b or 0.3, a or 1)
    tex.dnFlat = true
  else
    tex.dnFlat = nil
  end
  return tex
end

-- 1.3.0: the theme's tint on a texture. A fallback colour is already the finished colour (the themes write it as the
-- mean of the tinted picture): it is not tinted a second time
function Look.Tint(tex, t)
  if not t then return tex end
  if tex.dnFlat then tex:SetVertexColor(1, 1, 1, 1) else tex:SetVertexColor(t[1], t[2], t[3], t[4] or 1) end
  return tex
end

-- 1.3.0: the fallback colour `name` of the theme as r, g, b, a (Look.Tex(tex, path, Look.FB("stamp")))
function Look.FB(name)
  local c = Look.FALLBACK[name]
  if not c then return nil end
  return c[1], c[2], c[3], c[4] or 1
end

-- 1.3.0: texture `key` of the theme with its fallback colour (fb: another fallback name) and its tint
function Look.Skin(tex, key, fb)
  Look.Tex(tex, Look.TEX[key], Look.FB(fb or key))
  return Look.Tint(tex, Look.TINT[key])
end

-- 1.3.0: the stamp picture: blank = the frame without text, else the picture with burnt-in German text (nil when
-- the theme has none: then the frame plus the text in every language)
function Look.StampTex(id, blank)
  if blank then return Look.STAMP_BLANK[id] end
  return Look.STAMP_BAKED[id]
end

-- 1.3.0: a stamp picture (path from Look.StampTex) with a fallback colour and the theme's stamp tint (a white frame
-- takes the ink of the theme; the black book's pictures carry their own colour, no tint)
function Look.StampSkin(tex, path, fb)
  Look.Tex(tex, path, Look.FB(fb or "stamp"))
  return Look.Tint(tex, Look.TINT.stamp)
end

-- 1.3.0: "|cffrrggbb" of a colour table; the theme's colours stand ready in Look.HEX[role]
Look.Hex = ns.Theme.Hex

function Look.ClassIcon(tex, class)
  local tc = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
  if tc then
    Look.Tex(tex, Look.TEX.classes, Look.FB("classes"))
    tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
  else
    -- no theme tint here: the icon keeps the vertex colour its builder gave it (MugIcon)
    Look.Tex(tex, Look.TEX.skull, Look.FB("skull"))
    tex:SetTexCoord(0, 1, 0, 1)
  end
end

-- class colour of the game; without a class the theme's classUnknown, with a class the game has no colour for
-- (manual entries) the theme's classOther
function Look.ClassRGB(class)
  local c = Look.COLOR.classUnknown
  if class and ns.Util and ns.Util.ClassColor then
    local r, g, b = ns.Util.ClassColor(class)
    if r then return r, g, b end
    c = Look.COLOR.classOther
  end
  return c[1], c[2], c[3]
end

function Look.Name(e)
  if not e then return "?" end
  if ns.Util and ns.Util.Display then return ns.Util.Display(e) end
  return e.display or e.name or e.key or "?"
end

-- Name for /targetexact and the chat input. nil when it holds control characters, "|" or "/" or is too
-- long: a line break would add another command line to the macro of the target button.
local TARGET_MAX = 60
local function SafeTargetName(n)
  if type(n) ~= "string" or Look.Secret(n) or n == "" or #n > TARGET_MAX then return nil end
  if n:find("[%c|/\\]") then return nil end
  return n
end
function Look.TargetName(e)
  if type(e) ~= "table" then return nil end
  if ns.Util and ns.Util.TargetName then
    local ok, n = pcall(ns.Util.TargetName, e)
    if ok and type(n) == "string" and not Look.Secret(n) and n ~= "" then return SafeTargetName(n) end
  end
  return SafeTargetName(e.name)
end

------------------------------------------------------------------------
-- Text building blocks: every recurring form exactly once (guards in tests/ui check this)
------------------------------------------------------------------------
-- Time: two forms only. Ago = how long ago ("2 days ago"), When = point in time ("11/11 01:01").
-- Both come from the logic (ns.Util); here is only the fallback for an older logic.
function Look.Ago(t)
  if type(t) ~= "number" or Look.Secret(t) then return nil end
  if ns.Util and ns.Util.Ago then return ns.Util.Ago(t) end
  return Look.When(t)
end

-- Note as shown (1.2.0): own text, else the sentence for an entry taken from the guild book in the
-- active language (only a marker is stored, Util.NoteOf)
function Look.NoteOf(e)
  if ns.Util and ns.Util.NoteOf then return ns.Util.NoteOf(e) end
  return type(e) == "table" and type(e.note) == "string" and e.note or ""
end

function Look.When(t)
  if type(t) ~= "number" or Look.Secret(t) then return "?" end
  if ns.Util and ns.Util.When then
    local ok, s = pcall(ns.Util.When, t)
    if ok and type(s) == "string" then return s end
  end
  -- year only when it is not the current one; format lines from the language file, checked (Util.FmtDate)
  local key = date("%Y", t) ~= date("%Y", time()) and "TIME_FMT_WHEN_YEAR" or "TIME_FMT_WHEN"
  if ns.Util and ns.Util.FmtDate then return ns.Util.FmtDate(key, t) end
  local fmt = L[key]
  if type(fmt) ~= "string" or fmt:gsub("%%[dmyYHM%%]", ""):find("%", 1, true) then fmt = "%m/%d %H:%M" end
  return date(fmt, t)
end

-- Join the parts of a sub line with " · "; empty and nil parts drop out
local joinScratch = {}
function Look.Join(...)
  local n = 0
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v ~= nil and v ~= "" and v ~= false then n = n + 1; joinScratch[n] = tostring(v) end
  end
  local s = table.concat(joinScratch, " · ", 1, n)
  for i = 1, n do joinScratch[i] = nil end
  return s
end

-- Number with a times sign: "3×"
function Look.Times(n) return Fmt(L.TIMES, { count = tonumber(n) or 0 }) end

-- Count word: "1 victim", "3 candidates". 1.2.0: text is a language text with {count} and
-- {count|one|other}; the old form Look.Count(n, one, other) stays for older callers.
function Look.Count(n, text, many)
  n = tonumber(n) or 0
  if many == nil and type(text) == "string" and text:find("{", 1, true) then return Fmt(text, { count = n }) end
  return n .. " " .. (n == 1 and text or (many or text))
end

-- Guildmates appear in rows, notices and tooltip lines with their first name only
function Look.First(name)
  if type(name) ~= "string" or Look.Secret(name) then return "?" end
  return name:match("^(%S+)") or name
end

-- Role of a deed: "kill" (killing blow), "assist" (proven involvement), "suspect" (only suspected).
-- Older logic without a role: sure = killing blow, else suspicion.
function Look.Role(d)
  if type(d) ~= "table" then return "suspect" end
  local r = d.role
  if r == "kill" or r == "assist" or r == "suspect" then return r end
  return d.sure == true and "kill" or "suspect"
end

function Look.Assists(e)
  if type(e) ~= "table" then return 0 end
  return tonumber(e.assists) or 0
end

-- Weight for thresholds (alarm from n deaths on): killing blows plus assists
function Look.Weight(e)
  if type(e) ~= "table" then return 0 end
  local S = ns.Store
  if S and S.Weight then
    local ok, w = pcall(S.Weight, e)
    if ok and type(w) == "number" then return w end
  end
  return (tonumber(e.kills) or 0) + Look.Assists(e)
end

-- Core number of an entry in words: "2× killed · 1× involved", "under suspicion", "added by hand"
function Look.Tally(e)
  if type(e) ~= "table" then return "" end
  if e.status == "suspect" then return L.TALLY_SUSPECT end
  local k, a = tonumber(e.kills) or 0, Look.Assists(e)
  if k == 0 and a == 0 then return e.manual and L.TALLY_MANUAL or L.TALLY_NONE end
  return Look.Join(k > 0 and Fmt(L.TALLY_KILLED, { times = Look.Times(k) }),
    a > 0 and Fmt(L.TALLY_ASSISTED, { times = Look.Times(a) }))
end

-- newest deed of an entry (deaths, newest first)
function Look.LastDeed(e)
  return type(e) == "table" and type(e.deaths) == "table" and e.deaths[1] or nil
end

-- most exact place: subzone, else zone
function Look.Place(z, sz)
  if type(sz) == "string" and sz ~= "" then return sz end
  if type(z) == "string" and z ~= "" then return z end
  return L.PLACE_UNKNOWN
end

function Look.Setting(path, default)
  if not (ns.Store and ns.Store.Setting) then return default end
  local v = ns.Store.Setting(path)
  if v == nil then return default end
  return v
end

-- Scale animation (new API SetScaleFrom/To, old SetFromScale/ToScale)
function Look.ScaleAnim(group, from, to, dur, order)
  local a = group:CreateAnimation("Scale")
  if a.SetScaleFrom then
    a:SetScaleFrom(from, from); a:SetScaleTo(to, to)
  elseif a.SetFromScale then
    a:SetFromScale(from, from); a:SetToScale(to, to)
  end
  a:SetDuration(dur); a:SetOrder(order or 1); a:SetSmoothing("OUT")
  return a
end

function Look.AlphaAnim(group, from, to, dur, order, delay)
  local a = group:CreateAnimation("Alpha")
  a:SetFromAlpha(from); a:SetToAlpha(to); a:SetDuration(dur); a:SetOrder(order or 1)
  if delay then a:SetStartDelay(delay) end
  return a
end

-- Click and open sound of the interface (short, not throttled)
function Look.Sound(kind)
  if kind == "alert" or kind == "revenge" then return Look.Alarm(kind) end
  local kit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  if kit then pcall(PlaySound, kit, "Master") end
end

------------------------------------------------------------------------
-- Alarm sound: every alarm and notice goes through Look.Alarm
------------------------------------------------------------------------
-- The API knows no volume per sound, only the channel. So every own sound exists as a file in five
-- levels (<key>_1..5.ogg, Look.SoundFile; the idea comes from RareScanner), made by tests/ui/make_sounds.sh.
-- File names lower case and without umlauts; on Linux the client tells upper and lower case apart.
-- "No sound" comes first: the only way to silence (alert.sound follows the choice, see Look.SetSound)
-- key is stored (language neutral), lkey is the text in the language table; activation fills label
Look.SOUNDS = {
  { key = "aus",        lkey = "SOUND_NONE", silent = true },
  { key = "warnung",    lkey = "SOUND_RAIDWARNING", builtin = true },
  { key = "glocke",     lkey = "SOUND_BELL" },
  { key = "gong",       lkey = "SOUND_GONG" },
  { key = "herzschlag", lkey = "SOUND_HEARTBEAT" },
  { key = "feder",      lkey = "SOUND_FEATHER" },
  { key = "sirene",     lkey = "SOUND_SIREN" },
}
Look.SOUND_BY_KEY = {}
for _, s in ipairs(Look.SOUNDS) do Look.SOUND_BY_KEY[s.key] = s end
Look.CHANNELS = { { key = "Master", lkey = "CHANNEL_MASTER" }, { key = "SFX", lkey = "CHANNEL_SFX" },
  { key = "Dialog", lkey = "CHANNEL_DIALOG" } }
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    for _, s in ipairs(Look.SOUNDS) do s.label = L[s.lkey] end
    for _, c in ipairs(Look.CHANNELS) do c.label = L[c.lkey] end
  end)
end
local CHANNEL_OK = { Master = true, SFX = true, Dialog = true, Music = true, Ambience = true }
Look.VOLUMES = 5
Look.SOUND_GAP = 1.5          -- at most one alarm sound per 1.5 s

-- Choosing a sound writes both: the sound and the old main switch alert.sound (no sound = off)
function Look.SetSound(key)
  local s = Look.SOUND_BY_KEY[key]
  if not (s and ns.Store and ns.Store.Setting) then return end
  if Look.Setting("alert.soundKey") ~= key then ns.Store.Setting("alert.soundKey", key) end
  local on = not s.silent
  if Look.Setting("alert.sound", true) ~= on then ns.Store.Setting("alert.sound", on) end
end

function Look.SoundFile(key, level)
  return MEDIA .. "Sounds\\" .. key .. "_" .. level .. ".ogg"
end

function Look.SoundChoice()
  -- 1.3.0: without a choice the theme's suggestion (Store fills alert.soundKey at login, so this is the first moments)
  local key = Look.Setting("alert.soundKey", Look.THEME_SOUND or "warnung")
  local s = Look.SOUND_BY_KEY[key] or Look.SOUND_BY_KEY[Look.THEME_SOUND] or Look.SOUND_BY_KEY.warnung
  -- older setting "sound on alarm" off: counts as "no sound"
  if Look.Setting("alert.sound", true) == false then s = Look.SOUND_BY_KEY.aus end
  local vol = math.floor(tonumber(Look.Setting("alert.volume", 3)) or 3)
  if vol < 1 then vol = 1 elseif vol > Look.VOLUMES then vol = Look.VOLUMES end
  local ch = Look.Setting("alert.channel", "Master")
  if not CHANNEL_OK[ch] then ch = "Master" end
  return s, vol, ch
end

-- built-in sound through SOUNDKIT, else a file ID as DBM does
local function PlayBuiltin(kind, ch)
  local kit = SOUNDKIT and (kind == "revenge" and SOUNDKIT.LFG_REWARDS or SOUNDKIT.RAID_WARNING)
  if kit then
    local ok, will = pcall(PlaySound, kit, ch)
    if ok and will ~= false then return true end
  end
  if kind ~= "revenge" then
    local ok, will = pcall(PlaySoundFile, 567478, ch)
    return ok and will ~= false
  end
  return false
end

local lastPlay, previewHandle

-- 1.3.0: the soft sound of the victim alarm and of "quiet" for an even or overpaid standing (alert.settled): this
-- file at level 1 on the chosen channel, whatever sound and volume the player chose for the alarm
Look.QUIET_SOUND, Look.QUIET_LEVEL = "feder", 1

-- kind: "alert" (alarm, guild alarm), "revenge" (own sound of the revenge notice), "preview" (sample in the
-- house rules, not throttled, also with the main switch off), "quiet" (1.3.0: Look.QUIET_SOUND; never the loud
-- built-in sound instead). Returns what was played.
function Look.Alarm(kind)
  local preview = kind == "preview"
  if not preview then
    if not Look.Setting("alert.sound", true) then return nil end
    local now = GetTime()
    if lastPlay and now - lastPlay < Look.SOUND_GAP and now >= lastPlay then return nil end
    lastPlay = now
  end
  local s, vol, ch = Look.SoundChoice()
  if s.silent then return nil end                 -- "no sound" applies to the revenge notice too
  if kind == "revenge" then
    return PlayBuiltin("revenge", ch) and "revenge" or nil
  end
  if kind == "quiet" then
    local ok, will = pcall(PlaySoundFile, Look.SoundFile(Look.QUIET_SOUND, Look.QUIET_LEVEL), ch)
    if ok and not Look.Secret(will) and will ~= false then return Look.QUIET_SOUND end
    return nil
  end
  if not s.builtin then
    local ok, will, handle = pcall(PlaySoundFile, Look.SoundFile(s.key, vol), ch)
    if ok and not Look.Secret(will) and will ~= false then
      if preview then
        if previewHandle and StopSound then pcall(StopSound, previewHandle) end
        previewHandle = (type(handle) == "number") and handle or nil
      end
      return s.key
    end
    -- file does not play (missing, wrong name, format): fall back to the built-in sound
  end
  return PlayBuiltin("alert", ch) and "warnung" or nil
end

-- Font sizes: these steps only (design rule). 1.2.2: 9 is the emergency step for buttons, stamps and menus
-- when a word of a language does not fit otherwise (already so in the code before, now in the scale).
Look.SIZE = { 9, 10, 11, 13, 16, 19, 22, 26, 46 }
-- Scale steps for book and alarm
Look.SCALES = { 0.8, 0.9, 1.0, 1.15, 1.3, 1.5 }

------------------------------------------------------------------------
-- 1.2.2 layout building blocks: one line that shrinks, wraps and shows the whole text in a tooltip,
-- a tooltip only when cut, menus kept on the screen, and a page with standing head and foot and a body
-- that scrolls when its content is taller than the room.
------------------------------------------------------------------------
-- real width of a text on one line (GetUnboundedStringWidth; GetStringWidth can stop at the set width)
function Look.TextW(fs)
  local f = fs.GetUnboundedStringWidth
  if f then
    local ok, w = pcall(f, fs)
    if ok and type(w) == "number" and not Look.Secret(w) then return w end
  end
  f = fs.GetStringWidth
  if not f then return nil end
  local ok, w = pcall(f, fs)
  if ok and type(w) == "number" and not Look.Secret(w) then return w end
  return nil
end

-- is the shown text cut (ellipsis or lines missing)? Secret-safe like Details; nil when the client cannot say
function Look.IsCut(fs)
  if not fs.IsTruncated then return nil end
  local ok, v = pcall(fs.IsTruncated, fs)
  if not ok or Look.Secret(v) or v == nil then return nil end
  return v and true or false
end

-- height of a text in UI units (GetStringHeight; fallback: number of lines x size)
function Look.TextH(fs, lines)
  local ok, h = pcall(fs.GetStringHeight, fs)
  if ok and type(h) == "number" and not Look.Secret(h) and h > 0 then return h end
  local t = fs.GetText and fs:GetText()
  if type(t) ~= "string" or t == "" then return 0 end
  return (lines or 1) * ((fs.fontSize or 12) + 2)
end

-- Look.FitText(fs, text, opts): set text so that it is never cut silently. Order of round 1.2.2:
-- it fits: done; else the next smaller size of opts.sizes (default: the current one only); then wrap up to
-- opts.lines lines in the smallest size; last an ellipsis by the client and fs.full = text for the tooltip
-- (Look.TipIfCut). opts.must = true (no tooltip possible there, the alarm popup): before the ellipsis the text
-- goes on down the scale (Look.SIZE) to its smallest size, wrapped in opts.lines lines; more lines are not
-- allowed (the popup has a fixed height under a secure button, a third line would lie on the hint), so the
-- caller lets content give way when even that returns false (SetLine). opts.kind/flags: font (default: what
-- Look.Font set last). Returns true when the whole text shows.
-- Costs: one SetText per tried size; same text, width and font as last time: nothing.
-- State (1.2.2): every call starts from the same state (no wrap, opts.lines lines, the first size of the ladder) and
-- ends in the state of the field: wrap on when opts.lines > 1, so nothing of a short text that fitted on one
-- line sticks. Whoever writes a fitted field again goes through Look.FitText too, never plain SetText.
function Look.FitText(fs, text, opts)
  opts = opts or {}
  text = text or ""
  local width = opts.width or (fs.GetWidth and fs:GetWidth()) or 0
  if fs.fitText == text and fs.fitW == width and fs.fitOpts == opts and fs:GetText() == text
     and fs.fontSize == fs.fitSize and fs.fontKind == fs.fitKind then return not fs.cut end
  fs.fitText, fs.fitW, fs.fitOpts = text, width, opts
  fs.fit, fs.full = true, text
  local kind, flags = opts.kind or fs.fontKind or "body", opts.flags or fs.fontFlags
  local sizes = opts.sizes or { fs.fontSize or 11 }
  local lines = opts.lines or 1
  local function size(s)
    if fs.fontSize ~= s or fs.fontKind ~= kind then Look.Font(fs, kind, s, flags) end
  end
  local wrapped = false
  -- the longest word (by characters) on its own: wider than the line means cut even when the client wraps.
  -- Chinese and Japanese have no spaces and the client breaks between any two of their characters (U+3000 to
  -- U+9FFF: punctuation, kana, ideographs; U+FF00 to U+FFEF: full-width forms): each of them ends a word, only
  -- runs of other characters (a Latin name in a Chinese line) count. By character, not by language: the reason
  -- is free text and names are Latin in every language. Hangul stays a word (Korean separates words by spaces).
  local function wordTooWide()
    local long, n = nil, 0
    local words = text:gsub("[\227-\233][\128-\191][\128-\191]", " "):gsub("\239[\188-\191][\128-\191]", " ")
    for word in words:gmatch("%S+") do
      local c = #word:gsub("[\128-\191]", "")
      if c > n then long, n = word, c end
    end
    if not long then return false end
    if long == text then
      local w = Look.TextW(fs)
      return w ~= nil and width > 0 and w > width + 0.5
    end
    fs:SetText(long)
    local w = Look.TextW(fs)
    fs:SetText(text)
    return w ~= nil and width > 0 and w > width + 0.5
  end
  local function cut()
    local c = Look.IsCut(fs)
    if c == nil then
      local w = Look.TextW(fs)
      if w == nil or width <= 0 then c = false
      elseif wrapped then c = math.ceil(w / width - 0.001) > lines
      else c = w > width + 0.5 end
    end
    if not c and wrapped then c = wordTooWide() end
    -- 1.5 px margin on one line: the client rounds glyphs to pixels, a text that just fits may still get "…"
    if not c and not wrapped then
      local w = Look.TextW(fs)
      if w and width > 0 and w > width - 1.5 then c = true end
    end
    return c
  end
  -- the end state: the size reached, wrap on for a field of more than one line (also when the text took one)
  local function done(whole)
    fs.cut = not whole
    fs.fitSize, fs.fitKind = fs.fontSize, fs.fontKind
    if lines > 1 and not wrapped then fs:SetWordWrap(true) end
    return whole
  end
  if fs.SetMaxLines then fs:SetMaxLines(lines) end
  fs:SetWordWrap(false)
  for i = 1, #sizes do
    size(sizes[i])
    fs:SetText(text)
    if not cut() then return done(true) end
    -- opts.wrapFirst: running text wraps in this size before it gets smaller (a number: from that step of the ladder on)
    if lines > 1 and opts.wrapFirst and i >= (opts.wrapFirst == true and 1 or opts.wrapFirst) then
      fs:SetWordWrap(true); wrapped = true
      fs:SetText(text)
      if not cut() then return done(true) end
      fs:SetWordWrap(false); wrapped = false
    end
  end
  if lines > 1 then
    fs:SetWordWrap(true); wrapped = true
    fs:SetText(text)
    if not cut() then return done(true) end
  end
  if opts.must then
    for i = #Look.SIZE, 1, -1 do
      local s = Look.SIZE[i]
      if s < sizes[#sizes] then
        size(s)
        fs:SetText(text)
        if not cut() then return done(true) end
      end
    end
  end
  return done(false)
end

-- tooltip with the whole text over owner, only while fs is cut (fs.full from Look.FitText, else its text)
local function TipEnter(self)
  local fs = self.cutFs
  if not fs or not (fs.cut or Look.IsCut(fs)) then return end
  local t = fs.full or (fs.GetText and fs:GetText())
  if type(t) ~= "string" or t == "" or Look.Secret(t) then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(t, Look.BONE[1], Look.BONE[2], Look.BONE[3], 1, true)
  GameTooltip:Show()
  self.cutTip = true
end
local function TipLeave(self)
  if self.cutTip then self.cutTip = nil; GameTooltip:Hide() end
end
function Look.TipIfCut(owner, fs)
  if not owner.cutHooked then
    owner.cutHooked = true
    if owner:GetScript("OnEnter") then owner:HookScript("OnEnter", TipEnter) else owner:SetScript("OnEnter", TipEnter) end
    if owner:GetScript("OnLeave") then owner:HookScript("OnLeave", TipLeave) else owner:SetScript("OnLeave", TipLeave) end
    if owner.EnableMouse and not owner:IsMouseEnabled() then
      -- a hit area made only for the tooltip: it takes the hover, clicks go on to what lies below (right click on
      -- the poster opens its menu). Attested in Forever addons: ForeverAuras RegionTypes/Text.lua:203 (its
      -- tooltipFrame), WhatsTraining Forever/Settings.lua:86
      owner:EnableMouse(true)
      if owner.SetMouseClickEnabled then owner:SetMouseClickEnabled(false) end
    end
  end
  owner.cutFs = fs
  fs.tipOwner = owner
  return owner
end

-- the own tooltip of owner shows fs whole (list rows, deeds, victims): the same mark as Look.TipIfCut sets
-- (fs.tipOwner), without a hook; the layout guard hovers owner and checks it
function Look.TipShows(owner, fs)
  fs.tipOwner = owner
  return owner
end

-- frame opened at the cursor: clamped to the screen and opening away from the nearer edges
-- (cursor right of the middle: grows to the left; in the lower half: grows upwards)
function Look.KeepOnScreen(frame, x, y)
  frame:SetClampedToScreen(true)
  if type(x) ~= "number" or type(y) ~= "number" or Look.Secret(x) or Look.Secret(y) then return end
  -- screen size in the units of the frame (x, y are given in them, like cursor / effective scale)
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  local us, fs = UIParent:GetEffectiveScale(), frame:GetEffectiveScale()
  if type(w) ~= "number" or type(h) ~= "number" or Look.Secret(w) or Look.Secret(h) or type(us) ~= "number"
     or type(fs) ~= "number" or Look.Secret(us) or Look.Secret(fs) or fs <= 0 then
    w, h = nil, nil
  else
    w, h = w * us / fs, h * us / fs
  end
  local right = w and x > w / 2
  local low = h and y < h / 2
  local p = (low and "BOTTOM" or "TOP") .. (right and "RIGHT" or "LEFT")
  frame:ClearAllPoints()
  frame:SetPoint(p, UIParent, "BOTTOMLEFT", x, y)
  frame.openPoint = p
end

-- Look.Page(parent, opts): standing head (above opts.top), body that scrolls (only stacked from the top,
-- nothing hangs at its bottom), standing foot (opts.foot high, buttons and foot lines).
-- opts: top (px from the top of parent), foot (px), w, h (size of parent), bar (px from the right edge for the
-- scroll bar), step (px per mouse wheel step), paper (key in Look.TEX of the texture that fills parent; default
-- "page"; 1.3.0: a key, so the fade takes the theme's tint as well). Fields: page.body (scroll child), page.foot, page.scroll, page.bar.
-- page:Layout(height) sets the height of the content, shows the bar only when needed, keeps the offset in range;
-- page:Top() goes back to the start. No OnUpdate: the bar and the wheel move it, nothing else.
-- 1.2.2: content up to PAGE_SLACK px taller than the window does not scroll (the line box of the last line has room
-- below its descenders; a bar for 2 px looked like the old fault). Callers do not count the gap after their last
-- element (GF.LayoutHelp).
Look.PAGE_SLACK = 3
Look.PAGE_FADE = 20        -- height of the soft paper fade at the bottom of the window while content goes on below
local function PageFade(page)
  if page.fade then page.fade:SetShown(page.range > 0 and page.offset < page.range) end
end
local function PageSet(page, v)
  v = math.max(0, math.min(page.range or 0, math.floor((v or 0) + 0.5)))
  page.offset = v
  page.scroll:SetVerticalScroll(v + (page.pin or 0))
  if page.bar:GetValue() ~= v then page.bar:SetValue(v) end
  PageFade(page)
end
local function PageLayout(page, height)
  height = math.max(1, math.ceil(height or page.used or 1))
  page.used = height
  page.body:SetHeight(height)
  page.range = math.max(0, height - page.viewH)
  -- a small overhang gets no bar, but the content is pinned up by it (the top of a page has more room than that),
  -- so the descenders of the last line are never cut off out of reach
  page.pin = 0
  if page.range <= Look.PAGE_SLACK then page.pin, page.range = page.range, 0 end
  page.bar:SetMinMaxValues(0, page.range)
  page.bar:SetShown(page.range > 0)
  PageSet(page, page.offset or 0)
  return page.range > 0
end
-- the fade: the paper of the page itself (opts.paper, the texture that fills parent) over the bottom strip of the
-- window, opaque at the bottom and clear at the top (SetGradient with CreateColor as in Leatrix_Maps.lua:997 and
-- WhatsTraining Forever/Widgets.lua:103), on a frame above the scroll window that takes no mouse
local function PageFadeAt(page)
  local f = page.fade
  if not f then return end
  local h, w, fh, foot = page.h, page.w, Look.PAGE_FADE, page.footH
  f:SetTexCoord(0, (w - page.fadeInset) / w, (h - foot - fh) / h, (h - foot) / h)
  f:ClearAllPoints()
  f:SetPoint("BOTTOMLEFT", page.parent, "BOTTOMLEFT", 0, foot)
  f:SetSize(w - page.fadeInset, fh)
end
function Look.Page(parent, opts)
  local top, foot = opts.top or 0, opts.foot or 0
  local w, h = opts.w or parent:GetWidth(), opts.h or parent:GetHeight()
  local page = { viewH = h - top - foot, offset = 0, range = 0, step = opts.step or 40 }
  local sf = CreateFrame("ScrollFrame", nil, parent)
  sf:SetPoint("TOPLEFT", 0, -top)
  sf:SetSize(w, page.viewH)
  local body = CreateFrame("Frame", nil, sf)
  body:SetPoint("TOPLEFT")      -- like AceGUI's ScrollFrame container: anchored, then made the scroll child
  body:SetSize(w, 1)
  sf:SetScrollChild(body)
  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function(_, delta) PageSet(page, page.offset - delta * page.step) end)
  local ft = CreateFrame("Frame", nil, parent)
  ft:SetPoint("BOTTOMLEFT", 0, 0)
  ft:SetSize(w, math.max(1, foot))
  -- scroll bar in the style of the list: 14 px grip, 5 px visible
  local bar = CreateFrame("Slider", nil, parent)
  bar:SetOrientation("VERTICAL")
  bar:SetSize(14, page.viewH - 8)
  bar:SetPoint("TOPRIGHT", -(opts.bar or 6), -top - 4)
  local track = bar:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.12)
  track:SetWidth(5)
  track:SetPoint("TOP"); track:SetPoint("BOTTOM")
  local thumb = bar:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0, 0, 0, 0)
  thumb:SetSize(14, 34)
  bar:SetThumbTexture(thumb)
  local tv = bar:CreateTexture(nil, "OVERLAY", nil, 1)
  tv:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.75)
  tv:SetWidth(5)
  tv:SetPoint("TOP", thumb, "TOP"); tv:SetPoint("BOTTOM", thumb, "BOTTOM")
  bar:SetMinMaxValues(0, 0)
  bar:SetValueStep(1)
  if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end
  bar:SetScript("OnValueChanged", function(_, v)
    v = math.floor((v or 0) + 0.5)
    if v ~= page.offset then page.offset = v; sf:SetVerticalScroll(v + (page.pin or 0)); PageFade(page) end
  end)
  bar:Hide()
  page.scroll, page.body, page.foot, page.bar = sf, body, ft, bar
  page.parent, page.w, page.h, page.footH, page.fadeInset = parent, w, h, foot, (opts.bar or 6) + 14
  if CreateColor then
    local over = CreateFrame("Frame", nil, parent)
    over:SetAllPoints(parent)
    over:SetFrameLevel(sf:GetFrameLevel() + 3)
    local fade = over:CreateTexture(nil, "OVERLAY")
    local key = opts.paper or "page"
    Look.Tex(fade, Look.TEX[key] or key)
    local tc = Look.TINT[key]
    local r, g, b = tc and tc[1] or 1, tc and tc[2] or 1, tc and tc[3] or 1
    fade:Hide()
    -- without a working gradient there is no fade at all: an opaque strip of paper would hide the last lines
    local ok = fade.SetGradient and pcall(fade.SetGradient, fade, "VERTICAL", CreateColor(r, g, b, 1), CreateColor(r, g, b, 0))
    if ok then
      page.fade = fade
      PageFadeAt(page)
    end
  end
  page.Layout = PageLayout
  page.Set = PageSet
  function page:Top() PageSet(self, 0) end
  -- foot height after its content is known (e.g. a foot line that needs two lines)
  function page:SetFoot(fh)
    self.viewH = h - top - fh
    self.footH = fh
    ft:SetHeight(math.max(1, fh))
    sf:SetHeight(self.viewH)
    bar:SetHeight(self.viewH - 8)
    PageFadeAt(self)
    PageLayout(self)
  end
  return page
end

------------------------------------------------------------------------
-- Guild: every access to ns.Guild goes through these helpers only (Sync.lua may be missing)
------------------------------------------------------------------------
local GUILD_DEFAULTS = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
                         shareManual = true, alertListed = false, friends = true, alertHunt = true,
                         announceHunt = true, huntExpire = 0 }

function Look.HasGuild() return type(ns.Guild) == "table" end

-- calls ns.Guild[fn](...) protected; nil when the function does not exist or throws
function Look.GCall(fn, ...)
  local G = ns.Guild
  local f = type(G) == "table" and G[fn]
  if type(f) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(f, ...)
  if ok then return a, b, c, d end
  return nil
end

-- Guild entry that involves a char other than me (victim or lister)?
-- The logic sets g.foreign; older logic: derive it from victims/listedBy.
function Look.Foreign(g)
  if type(g) ~= "table" then return false end
  if g.foreign ~= nil then return g.foreign == true end
  local me = Look.Me()
  if type(g.victims) == "table" then
    for v in pairs(g.victims) do if v ~= me then return true end end
  end
  if type(g.listedBy) == "table" then
    for v in pairs(g.listedBy) do if v ~= me then return true end end
  end
  return false
end

-- Sharing state: { ok, reason, text, short } from ns.Guild.Health, else from the old functions
local HEALTH_SHORT = { noguild = "HEALTH_SHORT_NOGUILD", off = "HEALTH_SHORT_OFF", prefix = "HEALTH_SHORT_BLOCKED",
                       blocked = "HEALTH_SHORT_BLOCKED", failing = "HEALTH_SHORT_FAILING", hold = "HEALTH_SHORT_HOLD",
                       quiet = "HEALTH_SHORT_ASKED", ok = "HEALTH_SHORT_ASKED" }
-- src (1.2.0): nil/"guild", "friends" or "all" (the logic sums both up in one sentence)
function Look.GuildHealth(src)
  local h = Look.GCall("Health", src)
  if type(h) == "table" and type(h.text) == "string" then
    -- 1.2.0: no friend on the list or nobody to share with is no error: muted instead of red
    if h.reason == "nofriends" or h.reason == "nobody" then h.calm = true end
    if type(h.short) ~= "string" or h.short == "" then
      local k = HEALTH_SHORT[h.reason]
      h.short = k and L[k] or (h.ok and L.HEALTH_SHORT_ASKED or L.HEALTH_SHORT_FAIL)
    end
    return h
  end
  local name = Look.GCall("Name")
  if not name then
    return { ok = false, reason = "noguild", text = L.HEALTH_NOGUILD, short = L.HEALTH_SHORT_NOGUILD }
  end
  if Look.GCall("Enabled") == false or Look.GuildSetting("share") ~= true then
    return { ok = false, reason = "off", text = L.HEALTH_OFF, short = L.HEALTH_SHORT_OFF }
  end
  local m = Look.GCall("Members")
  local n = type(m) == "table" and #m or 0
  return { ok = true, reason = "ok", text = Fmt(L.GUILD_HEARD, { count = n }), short = L.HEALTH_SHORT_ASKED }
end

-- Guild kills are capped at 20 in Sync.lua: 20 means "20 or more"
function Look.GKills(n)
  n = tonumber(n) or 0
  if n >= 20 then return Fmt(L.GKILLS_CAP, { count = 20 }) end
  return tostring(n)
end

function Look.GuildSetting(name)
  local v = Look.GCall("Setting", name)
  if v ~= nil then return v end
  return Look.Setting("guild." .. name, GUILD_DEFAULTS[name])
end

-- Guild entry only added by hand (no deed)?
function Look.ListedOnly(g)
  if type(g) ~= "table" then return false end
  if g.listedOnly ~= nil then return g.listedOnly == true end
  return (tonumber(g.kills) or 0) == 0 and type(g.listedBy) == "table" and next(g.listedBy) ~= nil
end

-- Names from listedBy, oldest listing first; out is reused
function Look.ListedNames(g, out)
  out = out or {}
  for i = #out, 1, -1 do out[i] = nil end
  if type(g) ~= "table" or type(g.listedBy) ~= "table" then return out end
  for name, t in pairs(g.listedBy) do
    if type(name) == "string" and not Look.Secret(name) then out[#out + 1] = name end
  end
  local lb = g.listedBy
  table.sort(out, function(a, b)
    local ta, tb = tonumber(lb[a]) or 0, tonumber(lb[b]) or 0
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return out
end

-- Guildmates by first name: "Anna, Bert" or "Anna, Bert and 3 more"
local nameHead = {}
function Look.NameList(names, max)
  local n = #names
  if n == 0 then return "" end
  max = max or 2
  local k = math.min(n, max)
  for i = 1, k do nameHead[i] = Look.First(names[i]) end
  local s = table.concat(nameHead, ", ", 1, k)
  for i = 1, k do nameHead[i] = nil end
  if n <= max then return s end
  return Fmt(L.NAMELIST_MORE, { names = s, count = n - max })
end

-- Rectangle of a frame in UIParent units (left, bottom, right, top) or nil
function Look.Rect(f)
  if not (f and f.GetLeft and f.GetTop) then return nil end
  local ok1, l = pcall(f.GetLeft, f)
  local ok2, b = pcall(f.GetBottom, f)
  local ok3, r = pcall(f.GetRight, f)
  local ok4, t = pcall(f.GetTop, f)
  if not (ok1 and ok2 and ok3 and ok4) then return nil end
  -- check every value on its own: without an anchor or before layout the client returns nil
  if type(l) ~= "number" or type(b) ~= "number" or type(r) ~= "number" or type(t) ~= "number" then return nil end
  if Look.Secret(l) or Look.Secret(b) or Look.Secret(r) or Look.Secret(t) then return nil end
  local s = f:GetScale()
  if type(s) ~= "number" or Look.Secret(s) or s <= 0 then s = 1 end
  return l * s, b * s, r * s, t * s
end

-- own name ("Name Surname"), nil for a secret
local myName
function Look.Me()
  if myName then return myName end
  if not UnitName then return nil end
  local ok, n, s = pcall(UnitName, "player")
  if not ok or type(n) ~= "string" or Look.Secret(n) or n == "" then return nil end
  if type(s) == "string" and not Look.Secret(s) and s ~= "" then n = n .. " " .. s end
  myName = n
  return n
end

-- Zone of the last death by this enemy
function Look.LastPlace(e)
  local d = Look.LastDeed(e)
  if d then return Look.Place(d.zone, d.subzone) end
end

-- 1.3.0: the standing of a key as text, "me : him" ("2 : 1", the same notation in every language), followed by
-- mine, his and the state of Ledger.Standing. nil while the rap sheet is off or holds nothing for the key.
function Look.Score(key)
  local Lg = ns.Ledger
  if not (Lg and Lg.Standing) or type(key) ~= "string" or Look.Secret(key) then return nil end
  local mine, his, state = Lg.Standing(key)
  if type(mine) ~= "number" or type(his) ~= "number" then return nil end
  return mine .. " : " .. his, mine, his, state
end

------------------------------------------------------------------------
-- Alarm
------------------------------------------------------------------------
local Alert = {}
ns.Alert = Alert


local HOLD = 12           -- seconds shown
local W, H = 384, 108
local QUEUE_MAX = 9

local ready = false
local lastAlert = {}      -- key -> GetTime()
local lastVictim = {}     -- 1.3.0: key -> GetTime() of the last victim alarm (own cooldown, Alert.VICTIM_COOLDOWN)
-- { { key = k, guild = bool, hunt = bool, victim = bool }, ... }; victim alarms always wait behind all others
local queue = {}
local current             -- key shown right now
local currentEntry
local currentGuild        -- true when the popup shows a guild enemy
local currentVictim = false -- 1.3.0: true when the popup shows an own victim (victim alarm)
local popup, button, flash
local hideTimer
local armedFor            -- target name the secure button points at while it is shown

-- 1.3.0 victim alarm (alert.victims, off by default): someone I killed, who has a reason for revenge, shows up
Alert.VICTIM_COOLDOWN = 600          -- seconds per victim (the alarm of the book: alert.cooldown, 90)
Alert.VICTIM_WINDOW = 14 * 86400     -- my last kill on him at most this long ago

local function InCombat() return InCombatLockdown() and true or false end

-- 1.3.0: alert.settled for an even or overpaid standing: "always" | "quiet" (no edge pulse, the soft sound) | "off"
-- (no alarm). nil for every other state, so open cases are never touched; nil too while the rap sheet is off.
local SETTLED_STATE = { even = true, ahead = true }
local function SettledMode(e)
  local Lg = ns.Ledger
  if not (Lg and Lg.State) or type(e) ~= "table" or type(e.key) ~= "string" then return nil end
  if not SETTLED_STATE[Lg.State(e.key)] then return nil end
  local m = Look.Setting("alert.settled", "always")
  if m ~= "quiet" and m ~= "off" then m = "always" end
  return m
end

-- true (and the settled mode, nil for an open case) when the alarm of the book is due for e
local function Eligible(e)
  if not e or e.status == "pardoned" then return false end
  if not Look.Setting("alert.enabled", true) then return false end
  if e.status == "suspect" then return Look.Setting("alert.suspects", false) and true or false end
  -- entries added by hand alert without a kill too (else /dn add would never warn);
  -- the threshold counts killing blows and assists
  if not e.manual and Look.Weight(e) < (tonumber(Look.Setting("alert.minKills", 1)) or 1) then return false end
  local mode = SettledMode(e)
  if mode == "off" then return false end
  return true, mode
end

-- 1.3.0: is the victim alarm due for key (cooldown aside)? Only with the switch on, a standing in my favour
-- (me > him), my last kill on him within Alert.VICTIM_WINDOW, not pardoned, and not a case the alarm of the book
-- takes (that one has precedence, never a second popup). An overpaid entry of the book under alert.settled = "off"
-- stays silent here too. Returns the victim's table of the rap sheet.
local function VictimEligible(key)
  if Look.Setting("alert.victims", false) ~= true or not Look.Setting("alert.enabled", true) then return nil end
  local Lg = ns.Ledger
  if not (Lg and Lg.Standing and Lg.Victim) then return nil end
  local mine, his, state = Lg.Standing(key)
  if type(mine) ~= "number" or type(his) ~= "number" or mine <= his or state == "pardoned" then return nil end
  local e = ns.Store and ns.Store.Get and ns.Store.Get(key)
  if e then
    if Eligible(e) then return nil end
    if state == "ahead" and SettledMode(e) == "off" then return nil end
  end
  local v = Lg.Victim(key)
  local last = type(v) == "table" and v.last
  if type(last) ~= "number" or time() - last > Alert.VICTIM_WINDOW then return nil end
  return v
end

-- Guild enemy (not on the own list): own switches guild.alert / guild.minKills;
-- entries only added by hand (no deed) additionally need guild.alertListed.
-- 1.2.0: applies to guild and friends; hit list targets (hunt) have their own switch guild.alertHunt
local function EligibleGuild(g, hunt)
  if type(g) ~= "table" or type(g.key) ~= "string" then return false end
  local own = ns.Store and ns.Store.Get and ns.Store.Get(g.key)
  if hunt then
    -- 1.2.0 fix: in the own book too. Pardoned there wins (no alarm); an own alarm that fires names the
    -- hit list (OwnLine); suspect or under the own threshold: the hit list alarm
    if own and (own.status == "pardoned" or Eligible(own)) then return false end
    if Look.GCall("HuntHidden", g.key) then return false end
    return Look.GuildSetting("alertHunt") == true
  end
  if own then return false end
  if Look.GuildSetting("alert") ~= true then return false end
  if Look.ListedOnly(g) then return Look.GuildSetting("alertListed") == true end
  return (g.kills or 0) >= (tonumber(Look.GuildSetting("minKills")) or 1)
end

local function SavePoint()
  local p, _, rp, x, y = popup:GetPoint(1)
  if p and ns.Store and ns.Store.Setting then
    ns.Store.Setting("alert.point", { p, rp, x, y })
  end
end

local function Scale()
  local s = popup and popup:GetScale()
  if type(s) ~= "number" or Look.Secret(s) or s <= 0 then return 1 end
  return s
end

local function PlacePopup()
  popup:ClearAllPoints()
  local pt = Look.Setting("alert.point")
  if type(pt) == "table" and pt[1] then
    popup:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
  else
    -- below the client's red error text; offset in screen units, independent of alert.scale
    popup:SetPoint("TOP", UIParent, "TOP", 0, -190 / Scale())
  end
end

-- Positions never also in layout-local.txt (the client remembers dragged, named frames)
local function NotUserPlaced(f)
  if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
end

-- Put the secure button exactly over the popup and set the target (only out of combat)
local EnsureButton -- forward declaration

-- Does the (shown) secure button point at someone other than the popup? That can only happen in combat,
-- when the button could not be hidden. Then the popup lies one layer above the button and catches
-- every click itself: a click never targets anyone other than the one the popup shows.
-- (The popup is no protected frame, SetFrameStrata is allowed in combat.)
local function Guard()
  if not popup then return end
  local stale = button and button:IsShown() and (not currentEntry or armedFor ~= Look.TargetName(currentEntry))
  local want = stale and "DIALOG" or "HIGH"
  if popup.strata ~= want then
    popup.strata = want
    popup:SetFrameStrata(want)
  end
end

local function DisarmButton()
  if not button or InCombat() then return end
  button:Hide()
  if not button:IsShown() then armedFor = nil end
  Guard()
end

local function ArmButton()
  if not (popup and popup:IsShown() and currentEntry) or InCombat() then return end
  local name = Look.TargetName(currentEntry)
  -- without a safe name do not arm (and take an old button away)
  if not name then DisarmButton(); return end
  if not EnsureButton() then return end
  local cx, cy = popup:GetCenter()
  if type(cx) ~= "number" or type(cy) ~= "number" or Look.Secret(cx) or Look.Secret(cy) then return end
  -- GetCenter returns values in the popup's scale; the button hangs on UIParent
  local s = Scale()
  local macro = "/cleartarget\n/targetexact " .. name
  button:SetAttribute("type1", "macro")
  button:SetAttribute("macrotext1", macro)
  button:SetAttribute("macrotext", macro)
  button:ClearAllPoints()
  button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx * s, cy * s)
  button:SetSize(popup:GetWidth() * s, popup:GetHeight() * s)
  button:Show()
  armedFor = name
  Guard()
end

local function SetHint()
  if not popup or not currentEntry then return end
  local name = Look.TargetName(currentEntry)
  if not name then
    popup.hint:SetText(L.ALERT_HINT_CLOSE)
  elseif armedFor ~= name or not (button and button:IsShown()) then
    popup.hint:SetText(L.ALERT_HINT_COMBAT)
  else
    popup.hint:SetText(L.ALERT_HINT_TARGET)
  end
end

local function UpdateMore()
  if not popup then return end
  local n = #queue
  if n == 0 then popup.more:SetText("")
  else popup.more:SetText(Fmt(L.ALERT_MORE, { count = n })) end
end

local function BuildFlash()
  flash = CreateFrame("Frame", "DeathNoteFlash", UIParent)
  flash:SetAllPoints(UIParent)
  flash:SetFrameStrata("BACKGROUND")
  flash:EnableMouse(false)
  local t = flash:CreateTexture(nil, "BACKGROUND")
  t:SetAllPoints()
  Look.Skin(t, "edge")
  t:SetBlendMode("ADD")
  flash:SetAlpha(0)
  flash:Hide()
  -- a calm pulse; for rank 1 a second, weaker one
  local function done() flash:SetAlpha(0); flash:Hide() end
  local g1 = flash:CreateAnimationGroup()
  Look.AlphaAnim(g1, 0, 0.55, 0.25, 1)
  Look.AlphaAnim(g1, 0.55, 0, 0.9, 2)
  g1:SetScript("OnFinished", done)
  local g2 = flash:CreateAnimationGroup()
  Look.AlphaAnim(g2, 0, 0.55, 0.25, 1)
  Look.AlphaAnim(g2, 0.55, 0, 0.9, 2)
  Look.AlphaAnim(g2, 0, 0.35, 0.25, 3)
  Look.AlphaAnim(g2, 0.35, 0, 0.9, 4)
  g2:SetScript("OnFinished", done)
  flash.single, flash.double = g1, g2
end

local function Flash(strong)
  if not flash then BuildFlash() end
  flash.single:Stop(); flash.double:Stop()
  flash:SetAlpha(0)
  flash:Show()
  if strong then flash.double:Play() else flash.single:Play() end
end

local Finish -- forward declaration

local function Dismiss()
  if not popup or not popup:IsShown() then return end
  if hideTimer then hideTimer:Cancel(); hideTimer = nil end
  if popup.outAnim:IsPlaying() then return end
  popup.inAnim:Stop()
  popup.outAnim:Play()
end
Alert.Dismiss = Dismiss


local function EdgeColor(c) popup:SetBackdropBorderColor(c[1], c[2], c[3], 1) end
local function EdgeIdle() EdgeColor(popup.nr1 and Look.COLOR.edgeNr1 or Look.COLOR.edgeIdle) end

-- Edge: 2 px, for public enemy no. 1 3 px in light red
local function SetEdge(nr1)
  popup.nr1 = nr1 and true or false
  popup:SetBackdrop({ edgeFile = Look.TEX.white, edgeSize = nr1 and 3 or 2 })
  EdgeIdle()
end

function Alert.ApplyScale()
  if not popup then return end
  local s = tonumber(Look.Setting("alert.scale", 1)) or 1
  popup:SetScale(s)
  if type(Look.Setting("alert.point")) ~= "table" then PlacePopup() end
  if popup:IsShown() and not InCombat() then ArmButton() end
end

-- Black strip with a blood red edge, the mugshot on the left, the freshly written name on the right
local function Build()
  popup = CreateFrame("Frame", "DeathNoteAlert", UIParent, "BackdropTemplate")
  popup:SetSize(W, H)
  popup:SetFrameStrata("HIGH")
  popup.strata = "HIGH"
  popup:SetClampedToScreen(true)
  popup:SetMovable(true)
  popup:EnableMouse(true)
  popup:RegisterForDrag("LeftButton")
  popup:Hide()
  SetEdge(false)

  local bg = popup:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", 2, -2); bg:SetPoint("BOTTOMRIGHT", -2, 2)
  Look.Skin(bg, "cover", "coverDark")
  bg:SetTexCoord(0, 1, 0.2, 0.5)
  -- thin red line under the head
  local rule = popup:CreateTexture(nil, "BORDER")
  rule:SetColorTexture(Look.RED[1], Look.RED[2], Look.RED[3], 0.8)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", 86, -27); rule:SetPoint("TOPRIGHT", -10, -27)

  popup.title = Look.Text(popup, "title", 13, Look.RED_ON_BLACK)
  popup.title:SetPoint("TOPLEFT", 86, -9)
  popup.title:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
  popup.title:SetJustifyH("LEFT")
  popup.title:SetWordWrap(false)
  popup.more = Look.Text(popup, "body", 10, Look.BONE)
  popup.more:SetPoint("BOTTOMRIGHT", -10, 8)
  popup.more:SetWordWrap(false)

  -- mugshot
  local photo = CreateFrame("Frame", nil, popup)
  photo:SetSize(66, 66)
  photo:SetPoint("LEFT", 10, 0)
  photo:SetFrameLevel(popup:GetFrameLevel() + 3)
  local frame = photo:CreateTexture(nil, "BACKGROUND")
  frame:SetPoint("TOPLEFT", -2, 2); frame:SetPoint("BOTTOMRIGHT", 2, -2)
  frame:SetColorTexture(Look.BONE[1], Look.BONE[2], Look.BONE[3], 0.9)
  local mug = photo:CreateTexture(nil, "BORDER")
  mug:SetAllPoints()
  Look.Skin(mug, "mugshot", "mugshotDark")
  mug:SetDesaturated(true)
  popup.icon = photo:CreateTexture(nil, "ARTWORK")
  popup.icon:SetSize(44, 44)
  popup.icon:SetPoint("CENTER", 0, -2)
  popup.icon:SetDesaturated(true)
  local mt = Look.COLOR.mugTint
  popup.icon:SetVertexColor(mt[1], mt[2], mt[3], mt[4] or 1)
  popup.model = CreateFrame("PlayerModel", nil, photo)
  popup.model:SetAllPoints(mug)
  popup.model:Hide()
  local tape = photo:CreateTexture(nil, "OVERLAY")
  tape:SetSize(34, 14)
  tape:SetPoint("TOP", photo, "TOP", 0, 6)
  Look.Skin(tape, "tape")
  tape:SetRotation(0.12)

  -- Name in quill handwriting, class colour; appears with a short delay as if freshly written.
  -- 1.2.2: the full width (286 px) for the name; the level stands at the front of the text line. No tooltip
  -- possible (the secure button lies above): rather smaller (22, 19, 16, 13 pt) than cut.
  popup.name = Look.Text(popup, "head", 22, nil, nil)
  popup.name:SetPoint("TOPLEFT", 86, -30)
  popup.name:SetWidth(W - 86 - 12)
  popup.name:SetJustifyH("LEFT")
  popup.name:SetWordWrap(false)
  popup.stroke = popup:CreateTexture(nil, "ARTWORK")
  popup.stroke:SetHeight(8)
  popup.stroke:SetPoint("TOPLEFT", popup.name, "BOTTOMLEFT", -2, 3)
  popup.stroke:SetWidth(170)
  Look.Skin(popup.stroke, "ink", "inkRed")
  popup.stroke:SetVertexColor(Look.RED[1], Look.RED[2], Look.RED[3], 0.9)

  popup.line = Look.Text(popup, "body", 11, Look.BONE)
  popup.line:SetPoint("TOPLEFT", popup.name, "BOTTOMLEFT", 0, -6)
  popup.line:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
  popup.line:SetJustifyH("LEFT")
  popup.line:SetWidth(W - 86 - 12)
  popup.line:SetMaxLines(2)

  popup.hint = Look.Text(popup, "body", 10, Look.COLOR.hint)
  popup.hint:SetPoint("BOTTOMLEFT", 86, 8)
  -- 1.2.2: the hint ends before "+n more" (before: a fixed gap, two- and three-digit numbers ran into it)
  popup.hint:SetPoint("RIGHT", popup.more, "LEFT", -8, 0)
  popup.hint:SetJustifyH("LEFT")
  popup.hint:SetWordWrap(false)

  -- Fade in: a short pop; the name follows "in ink" with a delay
  local ia = popup:CreateAnimationGroup()
  Look.AlphaAnim(ia, 0, 1, 0.15, 1)
  Look.ScaleAnim(ia, 1.12, 1, 0.22, 1)
  popup.inAnim = ia
  -- (alpha animations jump back to the own alpha afterwards: so first hold 0->0, then fade in)
  local na = popup.name:CreateAnimationGroup()
  Look.AlphaAnim(na, 0, 0, 0.12, 1)
  Look.AlphaAnim(na, 0, 1, 0.6, 2)
  popup.nameAnim = na
  local sa = popup.stroke:CreateAnimationGroup()
  Look.AlphaAnim(sa, 0, 0, 0.6, 1)
  Look.AlphaAnim(sa, 0, 1, 0.3, 2)
  popup.strokeAnim = sa
  local oa = popup:CreateAnimationGroup()
  Look.AlphaAnim(oa, 1, 0, 0.35, 1)
  if oa.SetToFinalAlpha then oa:SetToFinalAlpha(true) end   -- no flash at alpha 1 at the end
  oa:SetScript("OnFinished", function() Finish() end)
  popup.outAnim = oa

  popup:SetScript("OnMouseUp", function(_, mouse)
    if mouse == "RightButton" then Dismiss() end
  end)
  popup:SetScript("OnDragStart", function(self)
    if InCombat() then return end
    self.moving = true
    self:StartMoving()
  end)
  popup:SetScript("OnDragStop", function(self)
    if not self.moving then return end
    self.moving = nil
    self:StopMovingOrSizing()
    NotUserPlaced(self)
    SavePoint()
    ArmButton()
  end)
  popup:SetScript("OnEnter", function() EdgeColor(Look.COLOR.edgeHot) end)
  popup:SetScript("OnLeave", EdgeIdle)

  PlacePopup()
  Alert.ApplyScale()
end

-- Invisible secure button, built only when it is needed out of combat
-- (creating and setting up a protected frame in combat would be blocked).
EnsureButton = function()
  if button then return button end
  if InCombat() then return nil end
  -- Invisible secure button: lies exactly over the popup out of combat.
  -- Not anchored to the popup, so the popup itself stays unprotected (can be shown/hidden in combat).
  button = CreateFrame("Button", "DeathNoteAlertButton", UIParent, "SecureActionButtonTemplate")
  button:SetFrameStrata("HIGH")
  button:SetFrameLevel(popup:GetFrameLevel() + 20)
  button:RegisterForClicks("AnyUp", "AnyDown")
  button:RegisterForDrag("LeftButton")
  button:SetMovable(true)
  button:Hide()
  button:SetScript("PostClick", function(_, mouse, down)
    if mouse == "RightButton" and not down then Dismiss() end
  end)
  button:SetScript("OnEnter", function() EdgeColor(Look.COLOR.edgeHot) end)
  button:SetScript("OnLeave", function() EdgeIdle() end)
  button:SetScript("OnDragStart", function(self)
    if InCombat() then return end
    self.moving = true
    popup:ClearAllPoints()
    popup:SetPoint("CENTER", self, "CENTER", 0, 0)
    self:StartMoving()
  end)
  button:SetScript("OnDragStop", function(self)
    if not self.moving or InCombat() then return end
    Alert.EndButtonDrag()
  end)

  return button
end

-- Stop dragging the button: hang the popup on UIParent again (never leave it anchored to the secure button)
function Alert.EndButtonDrag()
  if not (button and button.moving) then return end
  button.moving = nil
  button:StopMovingOrSizing()
  NotUserPlaced(button)
  local cx, cy = button:GetCenter()
  local s = Scale()
  popup:ClearAllPoints()
  if type(cx) == "number" and type(cy) == "number" and not Look.Secret(cx) and not Look.Secret(cy) then
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / s, cy / s)
    SavePoint()
  else
    PlacePopup()
  end
end

local function HeaderFor(e, rank)
  if e.status == "suspect" then return L.ALERT_SIGHTED_SUSPECT end
  if rank == 1 then return L.ALERT_SIGHTED_NR1 end
  return L.ALERT_SIGHTED
end

-- level of the target for the alarm. Live from the unit when there is one (only now, never on the
-- nameplate path), else the stored level ("last level"). Returns text and true when the target is above
-- you (1.2.0: the text then carries the gap, "Level 63 (+3)"; shown in the warning colour).
-- No value from a live unit or the skull (UnitLevel < 1): "Level ??", also a warning. Secret: as unknown.
function Look.LevelLine(unit, stored)
  local lvl, last, skull
  if type(unit) == "string" and not Look.Secret(unit) and UnitLevel then
    local ok, v = pcall(UnitLevel, unit)
    if ok and not Look.Secret(v) then
      if type(v) == "number" and v == v then
        if v < 1 then skull = true else lvl = math.floor(v) end
      elseif v == nil then
        skull = true
      end
    end
  end
  if not lvl and not skull and type(stored) == "number" and not Look.Secret(stored) and stored >= 1 then
    lvl, last = math.floor(stored), true
  end
  if skull then return L.ALERT_LEVEL_UNKNOWN, true end
  if not lvl then return nil, nil end
  local text = last and Fmt(L.ALERT_LEVEL_LAST, { level = lvl }) or Fmt(L.ALERT_LEVEL, { level = lvl })
  local mine
  if UnitLevel then
    local ok, v = pcall(UnitLevel, "player")
    if ok and not Look.Secret(v) and type(v) == "number" and v == v and v >= 1 then mine = v end
  end
  if mine and lvl > mine then return text .. " (+" .. (lvl - mine) .. ")", true end
  return text, nil
end

-- 1.3.0: text key of the standing in the line of the book, per state (suspects keep the line of 1.2.2)
local SCORE_LINE = { open = "ALERT_LINE_STANDING", even = "ALERT_LINE_STANDING_EVEN", ahead = "ALERT_LINE_STANDING_AHEAD" }

-- drop (1.2.2): what gives way first when the line does not fit in two lines: 1 = the zone, 2 = also "last ...",
-- 3 (1.3.0) = also the word for an even or overpaid standing (the score itself stays)
local function LineFor(e, drop)
  drop = drop or 0
  local place = drop < 1 and Look.LastPlace(e)
  local d = Look.LastDeed(e)
  local ago = Look.Ago(e.lastKill or (d and d.t))
  local k, a = tonumber(e.kills) or 0, Look.Assists(e)
  local s
  if e.status == "suspect" then
    s = L.ALERT_LINE_SUSPECT
  elseif k > 0 and a > 0 then
    s = Fmt(L.ALERT_LINE_KILLED_ASSISTED, { times = Look.Times(k), assists = Look.Times(a) })
  elseif k > 0 then
    s = Fmt(L.ALERT_LINE_KILLED, { times = Look.Times(k) })
  elseif a > 0 then
    s = Fmt(L.ALERT_LINE_ASSISTED, { times = Look.Times(a) })
  else
    s = L.ALERT_LINE_MANUAL
  end
  if ago and drop < 2 then s = Fmt(L.ALERT_LINE_LAST, { text = s, time = ago }) end
  if place and place ~= L.PLACE_UNKNOWN then s = Fmt(L.ALERT_LINE_IN, { text = s, zone = place }) end
  -- 1.3.0: with the rap sheet the standing takes the place of "Revenge: n×" (it never gives way); without it, or for
  -- a suspect, the line of 1.2.2
  local score, mine, _, state = Look.Score(e.key)
  if score and SCORE_LINE[state] then
    if mine > 0 then s = Fmt(L[drop < 3 and SCORE_LINE[state] or SCORE_LINE.open], { text = s, score = score }) end
  elseif (e.revenge or 0) > 0 then
    s = Fmt(L.ALERT_LINE_REVENGE, { text = s, times = Look.Times(e.revenge) })
  end
  return s
end

-- 1.3.0: the line of the victim alarm: "score 3 : 0 · killed by you, last 2 days ago"
local function VictimLineFor(e)
  local score = Look.Score(e.key) or "?"
  return Fmt(L.ALERT_LINE_VICTIM, { score = score, time = Look.Ago(e.last) or L.TIME_NEVER })
end

-- Model only when the unit token really belongs to this enemy now;
-- without a token passed in, the tracker is asked for a valid one.
local function UnitFor(key, unit)
  if type(unit) == "string" and not Look.Secret(unit) and ns.Util and ns.Util.KeyOfUnit then
    local ok, k = pcall(ns.Util.KeyOfUnit, unit)
    if ok and k == key then return unit end
  end
  if ns.Tracker and ns.Tracker.UnitFor then
    local ok, u = pcall(ns.Tracker.UnitFor, key)
    if ok and type(u) == "string" and not Look.Secret(u) then return u end
  end
end

-- "killed guildmates 7×, last Anna"; hand entry: "is in Bert's book"
local listedScratch = {}
-- Where a shared entry comes from (1.2.0): "guild", "friends", "both"
local function SourceOf(key) return Look.GCall("Source", key) end

local function GuildLineFor(g)
  local src = SourceOf(g.key)
  if Look.ListedOnly(g) then
    local names = Look.ListedNames(g, listedScratch)
    if #names == 0 then return src == "friends" and L.GUILD_LINE_IN_FRIENDS or L.GUILD_LINE_IN_GUILD end
    return Fmt(L.GUILD_LINE_LISTED_BY, { names = Look.NameList(names, 2) })
  end
  local s
  if src == "friends" then s = Fmt(L.GUILD_LINE_KILLED_FRIENDS, { kills = Look.GKills(g.kills) })
  elseif src == "both" then s = Fmt(L.GUILD_LINE_KILLED_BOTH, { kills = Look.GKills(g.kills) })
  else s = Fmt(L.GUILD_LINE_KILLED_GUILD, { kills = Look.GKills(g.kills) }) end
  if type(g.lastVictim) == "string" and g.lastVictim ~= "" then
    s = Fmt(L.GUILD_LINE_LAST, { text = s, name = Look.First(g.lastVictim) })
  end
  return s
end

-- Hit list target: who released it, plus the reason
-- 1.2.2: drop >= 1: the reason as in the list (at most Look.WHY_SHORT characters, then "…"), 2: one name only
Look.WHY_SHORT = 24
function Look.ShortWhy(why, n)
  local count, cut = 0, nil
  for pos in why:gmatch("()[%z\1-\127\194-\244]") do
    count = count + 1
    if count == n + 1 then cut = pos; break end
  end
  if not cut then return why end
  return why:sub(1, cut - 1):gsub("%s+$", "") .. "…"
end
local function HuntLineFor(h, drop)
  drop = drop or 0
  local names = type(h.names) == "table" and h.names or {}
  local s = #names > 0 and Fmt(L.HUNT_LINE_BY, { names = Look.NameList(names, drop >= 2 and 1 or 2) }) or L.HUNT_LINE_RELEASED
  -- the reason is the player's free text and is never translated
  if type(h.why) == "string" and h.why ~= "" and not Look.Secret(h.why) then
    s = Fmt(L.HUNT_LINE_REASON, { text = s, reason = drop >= 1 and Look.ShortWhy(h.why, Look.WHY_SHORT) or h.why })
  end
  return s
end

-- Own book: when the wanted one is also on the hit list, the alarm says so (1.2.0)
local function OwnLine(e, drop)
  local s = LineFor(e, drop)
  local h = Look.HasGuild() and Look.GCall("Hunt", e.key, "all")
  if type(h) == "table" and not h.hidden then
    -- 1.2.0: only when someone else released it; the own name never appears in it
    local names, others = type(h.names) == "table" and h.names or {}, {}
    for i = 1, #names do
      if not Look.GCall("IsOwnChar", names[i]) then others[#others + 1] = names[i] end
    end
    if #others > 0 then s = Fmt(L.ALERT_LINE_HUNT, { text = s, names = Look.NameList(others, 1) }) end
  end
  return s
end

-- guild: false (own book), true (guild/friends), "hunt" (hit list target) or "victim" (1.3.0: own victim)
local function GuildTitle(e, guild)
  if guild == "victim" then return L.ALERT_TITLE_VICTIM end
  if guild == "hunt" then return L.ALERT_TITLE_HUNT end
  local src = SourceOf(e.key)
  if src == "friends" then return L.ALERT_TITLE_FRIENDS end
  return L.ALERT_TITLE_GUILD
end

Look.FIT_TITLE, Look.FIT_TITLE_NR1 = { sizes = { 13, 11 } }, { sizes = { 16, 13, 11 } }
Look.FIT_NAME = { sizes = { 22, 19, 16, 13 } }
Look.FIT_LINE = { sizes = { 11 }, lines = 2, wrapFirst = true }
Look.FIT_LINE_LAST = { sizes = { 11, 10 }, lines = 2, wrapFirst = true, must = true }
local SetName, SetLine
-- The only ways to write popup.name and popup.line (1.2.2): every refresh (ENEMY_UPDATED, GUILD_UPDATED,
-- ENEMY_REKEYED) goes through them, so the name keeps shrinking instead of being cut and the line keeps the
-- level in front (from popup.levelText/levelWarn, set by Fill), the order of what gives way and the fitting.
SetName = function(e)
  Look.FitText(popup.name, Look.Name(e), Look.FIT_NAME)
end
SetLine = function(e, guild)
  local lt, warn = popup.levelText, popup.levelWarn
  local lead = ""
  if lt then
    lead = Look.HEX[warn and "warn" or "onCover"] .. lt .. "|r · "
  end
  -- Text line in two lines at most; if it does not fit, first the place gives way, then "last" (own book)
  -- or the long reason, then the second name (hit list); last of all 10 pt
  -- (the guild line has nothing that gives way: it takes the last step, 10 pt and below, at once)
  -- 1.3.0: the line of the own book has a fourth step (drop 3), the others end at 2
  local top = guild and 2 or 3
  for drop = 0, top do
    local s = (guild == "victim" and VictimLineFor(e)) or (guild == "hunt" and HuntLineFor(e, drop))
      or (guild and GuildLineFor(e)) or OwnLine(e, drop)
    local last = drop == top or (guild and guild ~= "hunt")
    if Look.FitText(popup.line, lead .. s, last and Look.FIT_LINE_LAST or Look.FIT_LINE) or last then break end
  end
end
local function Fill(e, unit, how, guild)
  local rank = (not guild and e.status == "wanted" and ns.Store.Rank) and ns.Store.Rank(e.key) or nil
  local nr1 = rank == 1
  -- 1.2.2: a long title in another language shrinks step by step instead of being cut (288 px)
  popup.title:SetWidth(W - 86 - 10)
  Look.FitText(popup.title, guild and GuildTitle(e, guild) or HeaderFor(e, rank), nr1 and Look.FIT_TITLE_NR1 or Look.FIT_TITLE)
  -- 1.3.0: the victim alarm is a calmer note: its head in the cover's writing colour instead of red
  local tc = guild == "victim" and Look.COLOR.onCover or Look.COLOR.accentOnCover
  popup.title:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
  SetName(e)
  popup.name:SetTextColor(Look.ClassRGB(e.class))
  -- Level at the front of the text line (1.2.2; before: right of the name, it took up to 132 px from it),
  -- above your level in the warning colour with the gap ("Level 63 (+3)")
  local lt, warn = Look.LevelLine(unit, e.level)
  popup.levelText, popup.levelWarn = lt, warn or nil
  SetLine(e, guild)
  popup.how = how
  SetEdge(nr1)

  -- SetUnit does not always throw, it also reports a model that cannot load with false
  local shown = false
  if unit then
    popup.model:ClearModel()
    local ok, res = pcall(popup.model.SetUnit, popup.model, unit)
    shown = ok and (Look.Secret(res) or res ~= false)
  end
  if shown then
    popup.model:Show(); popup.icon:Hide()
  else
    popup.model:Hide(); popup.icon:Show()
    Look.ClassIcon(popup.icon, e.class)
  end
  return nr1
end

local currentHunt = false   -- 1.2.0: the popup shows a hit list target
-- quiet (1.3.0): no edge pulse and the soft sound (Look.Alarm("quiet")); always so for a victim (guild = "victim")
local function Show(e, unit, how, silent, guild, quiet)
  if not popup then Build() end
  currentVictim = guild == "victim"
  if currentVictim then quiet = true end
  current, currentEntry, currentGuild = e.key, e, (guild and not currentVictim) and true or false
  currentHunt = guild == "hunt"
  local nr1 = Fill(e, unit, how, guild)
  popup.outAnim:Stop()
  popup:SetAlpha(1)
  popup:Show()
  popup.inAnim:Stop()
  popup.inAnim:Play()
  popup.nameAnim:Stop(); popup.nameAnim:Play()
  popup.strokeAnim:Stop(); popup.strokeAnim:Play()
  UpdateMore()
  ArmButton()
  Guard()
  SetHint()
  if not silent then
    if quiet then
      Look.Alarm("quiet")
    else
      Look.Alarm("alert")
      if Look.Setting("alert.flash", true) then Flash(nr1) end
    end
  end
  if hideTimer then hideTimer:Cancel() end
  hideTimer = C_Timer.NewTimer(HOLD, function() hideTimer = nil; Dismiss() end)
  -- a running notice (other player) moves below or above the popup, never hidden under it
  if ns.Extras and ns.Extras.PlaceBanner then ns.Extras.PlaceBanner() end
end

-- shown popup in UIParent units (for the notice), else nil
function Alert.Rect()
  if not (popup and popup:IsShown()) then return nil end
  return Look.Rect(popup)
end

local function ShowNext()
  -- if a new alarm is shown by now, the queue waits for its end (Finish)
  if current then UpdateMore(); return end
  while #queue > 0 do
    local q = table.remove(queue, 1)
    if q.guild then
      local g = q.hunt and Look.GCall("Hunt", q.key, "all") or Look.GCall("Get", q.key, "all")
      if EligibleGuild(g, q.hunt) then
        Show(g, UnitFor(q.key, nil), "other", false, q.hunt and "hunt" or true)
        return
      end
    elseif q.victim then
      local e = VictimEligible(q.key) and ns.Ledger.AsEntry(q.key)
      if e then
        Show(e, UnitFor(q.key, nil), "other", false, "victim")
        return
      end
    else
      local e = ns.Store.Get(q.key)
      local ok, mode = Eligible(e)
      if ok then
        Show(e, UnitFor(q.key, nil), "other", false, nil, mode == "quiet")
        return
      end
    end
  end
  UpdateMore()
end

Finish = function()
  popup:Hide()
  popup:SetAlpha(1)
  popup.model:ClearModel()
  current, currentEntry, currentGuild, currentHunt, currentVictim = nil, nil, false, false, false
  DisarmButton()
  if #queue > 0 then C_Timer.After(0.4, ShowNext) end
end

local function QueueIndex(key)
  for i = 1, #queue do if queue[i].key == key then return i end end
  return nil
end
local function Queued(key) return QueueIndex(key) ~= nil end

-- shared cooldown per key; true = an alarm would be due now
local function Due(key)
  local cd = Look.Setting("alert.cooldown", 90) or 90
  local last = lastAlert[key]
  return not (last and GetTime() - last < cd)
end

-- set the cooldown only once the alarm was shown or really queued
local function Mark(key) lastAlert[key] = GetTime() end

-- Does an on-screen notice (death, revenge, guild death) show exactly this player right now?
local function OnBanner(key)
  local X = ns.Extras
  return X and X.BannerShows and X.BannerShows(key) and true or false
end

-- One event, one window: the notice already shows the player. The cooldown counts as used,
-- a running popup for him closes, a waiting one drops out of the queue.
function Alert.Silence(key)
  if type(key) ~= "string" or Look.Secret(key) then return end
  Mark(key)
  lastVictim[key] = GetTime()
  for i = #queue, 1, -1 do if queue[i].key == key then table.remove(queue, i) end end
  if current == key then Dismiss() else UpdateMore() end
end

-- 1.3.0: victim alarms wait behind every other alarm. Another alarm goes in front of the first waiting victim and,
-- when the queue is full, pushes the last waiting victim out (its cooldown is given back); a victim alarm only
-- takes a free place at the end.
local function Enqueue(key, guild, hunt, victim)
  if #queue >= QUEUE_MAX then
    if victim then return false end
    local last
    for i = #queue, 1, -1 do if queue[i].victim then last = i; break end end
    if not last then return false end
    lastVictim[queue[last].key] = nil
    table.remove(queue, last)
  end
  local at = #queue + 1
  if not victim then
    for i = 1, #queue do if queue[i].victim then at = i; break end end
  end
  table.insert(queue, at, { key = key, guild = guild, hunt = hunt, victim = victim })
  UpdateMore()
  return true
end

-- 1.3.0: the popup shows a victim, now another alarm takes the same player: the popup turns into that alarm
-- (silently, like the guild alarm that becomes the alarm of the book)
local function TakeOver(e, unit, how, guild)
  currentVictim, currentGuild, currentHunt, currentEntry = false, guild and true or false, guild == "hunt", e
  Fill(e, UnitFor(e.key, unit), how, guild)
  ArmButton(); Guard(); SetHint()
end

function Alert.Spotted(key, unit, how)
  if not ready or type(key) ~= "string" or Look.Secret(key) then return end
  local e = ns.Store.Get(key)
  local ok, mode = Eligible(e)
  if not ok then return end
  -- one key, one popup; the own list goes before the guild list (and before the victim alarm)
  if current == key then
    if currentGuild or currentVictim then TakeOver(e, unit, how, false) end
    return
  end
  local qi = QueueIndex(key)
  if qi then
    if not queue[qi].victim then queue[qi].guild = false; return end
    table.remove(queue, qi)       -- a waiting victim alarm gives way to the alarm of the book
  end
  if not Due(key) then return end
  if OnBanner(key) then Mark(key); return end
  -- a victim alarm on the screen gives way at once (never the other way round)
  if current and not currentVictim then
    if Enqueue(key, false) then Mark(key) end
    return
  end
  Mark(key)
  Show(e, UnitFor(key, unit), how, false, nil, mode == "quiet")
end

-- Guild enemy (1.2.0: or a killer from the friends' book) who is not on my list;
-- kind = "hunt": a hit list target
function Alert.GuildSpotted(key, unit, how, kind)
  if not ready or type(key) ~= "string" or Look.Secret(key) or not Look.HasGuild() then return end
  local hunt = kind == "hunt"
  local g = hunt and Look.GCall("Hunt", key, "all") or Look.GCall("Get", key, "all")
  if not EligibleGuild(g, hunt) then return end
  if current == key then
    if currentVictim then TakeOver(g, unit, how, hunt and "hunt" or true) end
    return
  end
  local qi = QueueIndex(key)
  if qi then
    if not queue[qi].victim then return end
    table.remove(queue, qi)
  end
  if not Due(key) then return end
  if OnBanner(key) then Mark(key); return end
  if current and not currentVictim then
    if Enqueue(key, true, hunt) then Mark(key) end
    return
  end
  Mark(key)
  Show(g, UnitFor(key, unit), how, false, hunt and "hunt" or true)
end

-- 1.3.0: an own victim in sight (VICTIM_SPOTTED of Ledger.lua; only while alert.victims is on and there are
-- victims). Own cooldown of Alert.VICTIM_COOLDOWN per victim; never in front of another alarm.
function Alert.VictimSpotted(key, unit, how)
  if not ready or type(key) ~= "string" or Look.Secret(key) then return end
  if current == key or Queued(key) then return end
  local now = GetTime()
  local last = lastVictim[key]
  if last and now - last < Alert.VICTIM_COOLDOWN and now >= last then return end
  if not VictimEligible(key) then return end
  if OnBanner(key) then lastVictim[key] = now; return end
  if current then
    if Enqueue(key, false, false, true) then lastVictim[key] = now end
    return
  end
  local e = ns.Ledger.AsEntry(key)
  if not e then return end
  lastVictim[key] = now
  Show(e, UnitFor(key, unit), how, false, "victim")
end

-- 1.2.0: does the popup show or hold this player right now? (new release in sight: alarm instead of a chat line)
function Alert.Shows(key) return type(key) == "string" and (current == key or Queued(key)) and true or false end

local SAMPLE = {
  key = "Grimmzahn-Probe", name = "Grimmzahn", surname = "Probe", display = "Grimmzahn Probe", realm = "Probe",
  class = "ROGUE", kills = 3, revenge = 1, status = "wanted", suspected = 0,
  lastKill = nil, deaths = { { zone = "Schlingendorntal", subzone = "Grom'gol" } },
}

function Alert.Test()
  local e
  if ready and ns.Store and ns.Store.Ranked then
    -- 1.3.0: in the order of Wanted (open debt first while the rap sheet is on), so the test shows rank 1
    local list = ns.Store.Ranked("wanted", ns.Store.RankOrder and ns.Store.RankOrder() or "rank")
    e = list and list[1]
  end
  if not e then
    SAMPLE.lastKill = time() - 2 * 86400
    SAMPLE.deaths[1].zone = L.SAMPLE_ZONE      -- sample zone in the language of the book
    e = SAMPLE
  end
  Show(e, UnitFor(e.key, "target"), "test")
end

------------------------------------------------------------------------
-- Bus and combat changes
------------------------------------------------------------------------
ns:On("READY", function()
  ready = true
  wipe(lastAlert)
  wipe(lastVictim)
end)

ns:On("ENEMY_SPOTTED", function(key, unit, how) Alert.Spotted(key, unit, how) end)
ns:On("GUILD_ENEMY_SPOTTED", function(key, unit, how, kind) Alert.GuildSpotted(key, unit, how, kind) end)
ns:On("VICTIM_SPOTTED", function(key, unit, how) Alert.VictimSpotted(key, unit, how) end)
ns:On("TEST_ALERT", function() Alert.Test() end)

-- 1.3.0: the victim on the screen changed (his kill, a book entry, the standing): when the book takes him now, the
-- popup becomes its alarm; when the victim alarm no longer holds, it closes; else the line follows
local function RefreshVictim()
  local e = ns.Store.Get(current)
  if e and Eligible(e) then TakeOver(e, nil, popup.how, false); return end
  local v = VictimEligible(current) and ns.Ledger.AsEntry(current)
  if not v then Dismiss(); return end
  currentEntry = v
  SetLine(v, "victim")
end

ns:On("ENEMY_UPDATED", function(key)
  if not current or key ~= current or currentGuild then return end
  if currentVictim then RefreshVictim(); return end
  local e = ns.Store.Get(key)
  if not e then Dismiss(); return end
  currentEntry = e
  SetLine(e, false)
end)

-- 1.3.0 (Ledger.lua): my kill on him, his kill on me, a hand revenge: the standing in the line follows
ns:On("STANDING_CHANGED", function(key)
  if not current or key ~= current or currentGuild then return end
  if currentVictim then RefreshVictim(); return end
  local e = ns.Store.Get(key)
  if e then currentEntry = e; SetLine(e, false) end
end)

ns:On("GUILD_UPDATED", function()
  if not current or not currentGuild then return end
  local g = currentHunt and Look.GCall("Hunt", current, "all") or Look.GCall("Get", current, "all")
  if not g then Dismiss(); return end
  currentEntry = g
  SetLine(g, currentHunt and "hunt" or true)
end)

-- The store moves an entry to a new key (same GUID, fuller name):
-- popup, queue and cooldown move along
ns:On("ENEMY_REKEYED", function(old, new)
  if type(old) ~= "string" or type(new) ~= "string" or old == new then return end
  if lastAlert[old] then lastAlert[new] = lastAlert[old]; lastAlert[old] = nil end
  if lastVictim[old] then lastVictim[new] = lastVictim[old]; lastVictim[old] = nil end
  for i = 1, #queue do if queue[i].key == old and not queue[i].guild then queue[i].key = new end end
  if current == old and not currentGuild then current = new end
  -- the same player at most once: take doubles out of the queue (old and new key) and the
  -- one shown right now
  for i = #queue, 1, -1 do
    local k = queue[i].key
    local dup = k == current
    for j = 1, i - 1 do if queue[j].key == k then dup = true; break end end
    if dup then table.remove(queue, i) end
  end
  UpdateMore()
  if current == new and not currentGuild then
    local e
    if currentVictim then e = ns.Ledger and ns.Ledger.AsEntry(new) else e = ns.Store.Get(new) end
    if e then currentEntry = e end
    if popup and popup:IsShown() then
      SetName(currentEntry)
      ArmButton()
      Guard()
      SetHint()
    end
  end
end)

ns:On("SETTINGS_CHANGED", function(path)
  if path == "alert.scale" then Alert.ApplyScale() end
end)

-- Take the button away before the combat lockdown (else it would stay in combat as an invisible click area).
-- Whether hiding still goes through here is unproven in the game: so armedFor stays set while
-- the button is shown, and Guard() puts the popup over it if need be.
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  if popup and popup.moving then
    popup.moving = nil
    popup:StopMovingOrSizing()
    NotUserPlaced(popup)
    SavePoint()
  end
  if button and not InCombatLockdown() then
    Alert.EndButtonDrag()
    if button:IsShown() then
      pcall(button.Hide, button)
      if not button:IsShown() then armedFor = nil end
    end
  end
  Guard()
  SetHint()
end)

-- After combat: update the click target or clear away a button left behind
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if popup and popup:IsShown() and currentEntry then
    ArmButton()
  elseif button and button:IsShown() then
    DisarmButton()
  end
  Guard()
  SetHint()
end)
