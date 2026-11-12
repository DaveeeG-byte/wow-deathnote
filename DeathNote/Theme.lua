-- DeathNote - Theme.lua (1.3.0)
-- Themes: the look of the book as data. Loads after Locale.lua and before every file that draws.
--
-- How it works:
--   * Every file Themes\<id>.lua only registers a data table: Theme.Register("<id>", { ... }). Nothing is drawn
--     there and nothing is read from the client.
--   * The choice lives in the SavedVariables (DeathNoteDB.settings.ui.theme: an id; absent or unknown = the base
--     theme "notebook"). Locale.Activate() activates the theme at ADDON_LOADED right before it builds the texts,
--     because the theme words are the third layer of the text table. A change takes a /reload (like the language).
--   * ns.Look keeps its tables and names (Look.INK, Look.TEX, Look.FONT, Look.TONE ...). Theme.Fill writes the
--     values of the active theme INTO these tables (the tables keep their identity), so a table remembered at file
--     scope (GF.STAMP_INK, Extras.STAMPS) shows the active theme as well. Alert.lua fills them once at load (the
--     base theme, the language is not known yet) and Theme.Activate fills them again with the chosen one.
--   * A theme may leave out any value: it then comes from the base theme (one fallback, never a hole).
--     Unknown values are ignored at run time; tests/test_theme.lua reports them as errors.
-- Nothing of a theme is ever written to DeathNoteDB except its id.

local ADDON, ns = ...
local Theme = {}
ns.Theme = Theme

Theme.BASE = "notebook"          -- the theme every other theme falls back to (also for missing values)
Theme.DEFAULT = "notebook"       -- the theme without a (valid) choice
Theme.id = Theme.DEFAULT         -- the active theme; Ranks.lua reads it (ns.Theme.id), Theme.Id() is the same

-- Globals through one door (as Locale.Global): works in the client, in tests and in a strict mock
local function global(name)
  if ns.Locale and ns.Locale.Global then return ns.Locale.Global(name) end
  local ok, v = pcall(function() return _G[name] end)
  if ok then return v end
  return nil
end
local issecretvalue = global("issecretvalue")
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end

---------------------------------------------------------------------------
-- The schema: every field a theme can set (tests/test_theme.lua checks every theme against it)
---------------------------------------------------------------------------
-- colour roles; value { r, g, b [, a] } with 0..1 or "#rrggbb" / "#rrggbbaa"
Theme.COLORS = {
  -- text and ink (the old names in ns.Look in brackets)
  "ink",           -- ink on paper (Look.INK)
  "accent",        -- red for large text (16 pt and up) and areas on paper (Look.RED)
  "accentSmall",   -- small red text on paper, 4.5:1 (Look.RED_INK)
  "accentOnCover", -- red text on the cover, popup and notice (Look.RED_ON_BLACK)
  "onCover",       -- text on the cover, popup and notice (Look.BONE, Look.CREAM)
  "faded",         -- (Look.FADED)
  "black",         -- (Look.BLACK)
  "tabOff",        -- inactive tabs on the cover (Look.TAB_OFF)
  "warn",          -- warning in the popup (target above your level) (Look.WARN)
  "hint",          -- hint line at the bottom of the alarm popup
  -- areas and lines
  "btnFill", "btnEdge", "btnEdgeHot",  -- ink button: fill, edge, edge under the mouse
  "menuFill",      -- menu (right click, sorting)
  "boxFill",       -- inside of a check box
  "editFill",      -- text box of "Back up the book" / "Read in a book"
  "rule",          -- lines of the left page (alpha per line in the code)
  "frameEdge",     -- outer edge of the book
  "fold",          -- dark strip between the pages
  "shadow",        -- drop shadow of the poster (alpha in the code)
  "titleShadow",   -- shadow of the book title on the cover
  "tabFill", "tabHi",                  -- tab on the cover: glaze and highlight
  "quipFill",      -- strip under the notice with a remark (humor)
  "edgeIdle", "edgeHot", "edgeNr1",    -- edge of the alarm popup: idle, under the mouse, rank 1
  -- tints of pictures
  "mugTint",       -- class icon in the photo (desaturated)
  "skullTint", "skullFaint",           -- skull in a row / on the empty page
  "coinTint",      -- coin on a row with a bounty
  "classUnknown",  -- class bar and name colour of a player without a class
  "classOther",    -- the same for a class the game has no colour for (entries added by hand)
  -- stamps
  "stampInk", "stampDark", "stampDarker",  -- ink of the stamp text (red, dark, darker)
  "stampCount",    -- the "2x" next to the revenge stamp
  -- tooltip and chat lines (|cff colours)
  "tipLabel", "tipText", "tipListed", "tipNote",
}
-- old names in ns.Look for the roles that had one (same table)
Theme.LOOK_NAMES = { ink = "INK", accent = "RED", accentSmall = "RED_INK", accentOnCover = "RED_ON_BLACK",
  onCover = "BONE", faded = "FADED", black = "BLACK", tabOff = "TAB_OFF", warn = "WARN" }
-- textures of the theme; value: file in Media\ ("paper.tga") or a client path ("Interface\\...")
Theme.TEXTURES = { "paper", "page", "cover", "ink", "mugshot", "edge", "check", "pin", "skull", "tape", "tri",
  "border", "coin", "gear", "slip" }
-- tints (SetVertexColor after the texture): every texture key plus "stamp" (all stamp pictures); absent = none
Theme.TINTS = { "stamp" }
for _, k in ipairs(Theme.TEXTURES) do Theme.TINTS[#Theme.TINTS + 1] = k end
-- stamps: per stamp a frame without text (blank) and, optional, the picture with burnt-in German text (baked)
Theme.STAMPS = { "nr1", "rache", "pardon", "suspect", "guild", "hunt" }
-- fallback colours: shown instead of a texture whose file is missing (name = texture key or a variant)
Theme.FALLBACKS = { "paper", "page", "cover", "coverDark", "ink", "inkRed", "mugshot", "mugshotDark", "edge",
  "check", "pin", "skull", "tape", "tri", "gear", "stamp", "stampNotice", "white", "classes", "icon", "slip" }
-- font roles -> kind in Locale.FONTS (title, hand, body, type)
Theme.FONTS = { "title", "head", "hand", "body", "type" }
Theme.FONT_KINDS = { title = true, hand = true, body = true, type = true }
-- opacity of ink on paper per role
Theme.TONES = { "ink", "label", "sub", "hint", "hand", "off" }
-- fields of a theme table
Theme.FIELDS = { order = "number", nameKey = "string", color = "table", tex = "table", tint = "table",
  stamp = "table", fallback = "table", font = "table", tone = "table", sound = "table", words = "string",
  size = "nil", page = "nil" }    -- size, page: reserved (font scale, measures), not read in 1.3.0

---------------------------------------------------------------------------
-- Registry
---------------------------------------------------------------------------
local registry = {}      -- id -> data table as registered
local order = {}         -- ids in order of registration

-- "#rrggbb" or "#rrggbbaa" -> { r, g, b [, a] }; a table is copied; anything else nil
local function parseColor(v)
  if type(v) == "table" then
    local r, g, b, a = v[1], v[2], v[3], v[4]
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then return { r, g, b, a } end
    return nil
  end
  if type(v) ~= "string" then return nil end
  local hex = v:match("^#(%x+)$")
  if not hex or (#hex ~= 6 and #hex ~= 8) then return nil end
  local c = {}
  for i = 1, #hex / 2 do c[i] = tonumber(hex:sub(i * 2 - 1, i * 2), 16) / 255 end
  return c
end
Theme.ParseColor = parseColor

-- Registers a theme (from Themes\<id>.lua). id: lower case letters, digits, "_". false for anything else.
function Theme.Register(id, data)
  if type(id) ~= "string" or secret(id) or not id:match("^[a-z][a-z0-9_]*$") or type(data) ~= "table" then return false end
  if not registry[id] then order[#order + 1] = id end
  registry[id] = data
  return true
end

function Theme.Get(id) return registry[id] end
function Theme.Known(id) return type(id) == "string" and registry[id] ~= nil end

-- ids of the registered themes, sorted by data.order (then id)
function Theme.List()
  local out = {}
  for _, id in ipairs(order) do out[#out + 1] = id end
  table.sort(out, function(a, b)
    local oa, ob = tonumber(registry[a].order) or 99, tonumber(registry[b].order) or 99
    if oa ~= ob then return oa < ob end
    return a < b
  end)
  return out
end

---------------------------------------------------------------------------
-- Choice (DeathNoteDB.settings.ui.theme), read straight from the SavedVariables (Store.Init runs later)
---------------------------------------------------------------------------
local function settingsUI()
  local db = global("DeathNoteDB")
  if type(db) ~= "table" or type(db.settings) ~= "table" then return nil end
  local ui = db.settings.ui
  return type(ui) == "table" and ui or nil
end

-- an id for anything that names a theme (any case, blanks around), else nil
function Theme.Normalize(v)
  if type(v) ~= "string" or secret(v) then return nil end
  v = v:gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if registry[v] then return v end
  return nil
end

-- the stored choice if it is a registered theme, else nil
function Theme.StoredChoice()
  local ui = settingsUI()
  return ui and Theme.Normalize(ui.theme) or nil
end

-- choice -> the theme that is used: a registered one, else the default (silent fallback)
function Theme.Resolve(choice)
  local id = Theme.Normalize(choice)
  if id then return id end
  if registry[Theme.DEFAULT] then return Theme.DEFAULT end
  return Theme.BASE
end

function Theme.Id() return Theme.id end

-- true when the stored choice differs from the active theme (a /reload is pending)
function Theme.Pending()
  if not Theme.active then return false end
  return Theme.Resolve(Theme.StoredChoice()) ~= Theme.id
end

-- Stores a choice. Returns the id and whether a /reload is needed, or nil (unknown theme).
function Theme.SetChoice(v)
  local id = Theme.Normalize(v)
  if not id then return nil end
  local Store = ns.Store
  if Store and Store.Setting and Store.DB and Store.DB() then
    Store.Setting("ui.theme", id)
  else
    local db = global("DeathNoteDB")
    if type(db) ~= "table" then return nil end
    if type(db.settings) ~= "table" then db.settings = {} end
    if type(db.settings.ui) ~= "table" then db.settings.ui = {} end
    db.settings.ui.theme = id
  end
  return id, Theme.Pending()
end

---------------------------------------------------------------------------
-- Values of the active theme with the fallback to the base theme
---------------------------------------------------------------------------
local function pick(id, part, key)
  local t = registry[id]
  local p = t and t[part]
  local v = type(p) == "table" and p[key] or nil
  if v == nil and id ~= Theme.BASE then
    t = registry[Theme.BASE]
    p = t and t[part]
    v = type(p) == "table" and p[key] or nil
  end
  return v
end
Theme.Pick = pick

local function current() return Theme.active or (registry[Theme.DEFAULT] and Theme.DEFAULT) or Theme.BASE end

-- a colour of the active theme as a new table, or nil
function Theme.Color(role, id) return parseColor(pick(id or current(), "color", role)) end

-- "|cffrrggbb" of a colour table (tooltip and chat lines); cut like string.format("%x") cut a fraction before 1.3.0
function Theme.Hex(c)
  local function b(x) return math.floor(math.max(0, math.min(1, x)) * 255 + 1e-6) end
  return ("|cff%02x%02x%02x"):format(b(c[1]), b(c[2]), b(c[3]))
end

-- "|cffrrggbb" of a colour role of the active theme, or nil
function Theme.HexOf(role)
  local c = Theme.Color(role)
  return c and Theme.Hex(c) or nil
end

-- writes c into the table t (keeps the table); a missing alpha stays absent
local function setColor(t, c)
  t[1], t[2], t[3], t[4] = c[1], c[2], c[3], c[4]
end

-- Fills ns.Look (or any look table with the same shape) with the active theme, in place.
-- Media paths are built with Look.MEDIA; fonts come from Locale.FontList for the active language.
function Theme.Fill(Look)
  if type(Look) ~= "table" then return end
  local id = current()
  local MEDIA = Look.MEDIA or ("Interface\\AddOns\\" .. tostring(ADDON) .. "\\Media\\")
  local function path(file)
    if type(file) ~= "string" or file == "" then return nil end
    if file:find("^Interface\\") then return file end
    return MEDIA .. file
  end
  -- colours: Look.COLOR[role], plus the old name for the roles that had one
  Look.COLOR = Look.COLOR or {}
  for _, role in ipairs(Theme.COLORS) do
    local c = parseColor(pick(id, "color", role)) or { 1, 0, 1 }
    local t = Look.COLOR[role]
    if not t then
      local old = Theme.LOOK_NAMES[role]
      t = old and Look[old] or {}
      Look.COLOR[role] = t
    end
    setColor(t, c)
    local old = Theme.LOOK_NAMES[role]
    if old then Look[old] = t end
  end
  Look.CREAM = Look.BONE
  -- the same colours as "|cffrrggbb" for tooltip and chat lines (built once here, not per tooltip)
  Look.HEX = Look.HEX or {}
  for role, t in pairs(Look.COLOR) do Look.HEX[role] = Theme.Hex(t) end
  Look.STAMP_INK = Look.STAMP_INK or {}
  Look.STAMP_INK[1], Look.STAMP_INK[2], Look.STAMP_INK[3] = Look.COLOR.stampInk, Look.COLOR.stampDark, Look.COLOR.stampDarker
  -- tints of textures (nil = none, the texture keeps its own colours)
  Look.TINT = Look.TINT or {}
  for _, key in ipairs(Theme.TINTS) do
    local c = parseColor(pick(id, "tint", key))
    if c then
      Look.TINT[key] = Look.TINT[key] or {}
      setColor(Look.TINT[key], c)
    else
      Look.TINT[key] = nil
    end
  end
  -- fallback colours
  Look.FALLBACK = Look.FALLBACK or {}
  for _, key in ipairs(Theme.FALLBACKS) do
    local c = parseColor(pick(id, "fallback", key)) or { 0.5, 0.4, 0.3, 1 }
    Look.FALLBACK[key] = Look.FALLBACK[key] or {}
    setColor(Look.FALLBACK[key], c)
  end
  -- textures and stamps
  Look.TEX = Look.TEX or {}
  for _, key in ipairs(Theme.TEXTURES) do Look.TEX[key] = path(pick(id, "tex", key)) end
  Look.STAMP_BLANK, Look.STAMP_BAKED = Look.STAMP_BLANK or {}, Look.STAMP_BAKED or {}
  local own, base = registry[id] and registry[id].stamp, registry[Theme.BASE] and registry[Theme.BASE].stamp
  own = type(own) == "table" and own or {}
  base = type(base) == "table" and base or {}
  local blank = type(own.blank) == "table" and own.blank or {}
  local baseBlank = type(base.blank) == "table" and base.blank or {}
  -- baked pictures only when the theme names them itself (absent: frame plus text in every language)
  local baked = type(own.baked) == "table" and own.baked or {}
  for _, key in ipairs(Theme.STAMPS) do
    Look.STAMP_BLANK[key] = path(blank[key] or baseBlank[key])
    Look.STAMP_BAKED[key] = path(baked[key])
    -- Look.TEX[<stamp>] as before: the picture of the German stamp, else the frame
    Look.TEX[key] = Look.STAMP_BAKED[key] or Look.STAMP_BLANK[key]
  end
  -- opacity per role (Look.TONE keeps its identity)
  Look.TONE = Look.TONE or {}
  for _, role in ipairs(Theme.TONES) do
    local v = pick(id, "tone", role)
    Look.TONE[role] = type(v) == "number" and v or 1
  end
  Theme.FillFonts(Look)
  -- sound suggested by the theme (only while the player has not chosen one)
  Look.THEME_SOUND = pick(id, "sound", "alert")
end

-- Fonts only: role -> kind -> the list of the active language's writing system (again after the language is
-- active, Alert.lua). Without the language system the lists stay as they are.
function Theme.FillFonts(Look)
  local id = current()
  Look.FONT = Look.FONT or {}
  Look.FONT_KIND = Look.FONT_KIND or {}
  local FL = ns.Locale and ns.Locale.FontList
  for _, role in ipairs(Theme.FONTS) do
    local kind = pick(id, "font", role)
    if not Theme.FONT_KINDS[kind] then kind = pick(Theme.BASE, "font", role) or "body" end
    Look.FONT_KIND[role] = kind
    Look.FONT[role] = FL and FL(kind) or Look.FONT[role] or {}
  end
end

-- Activates the chosen theme (choice: nil = the stored one). Runs once; a change takes a /reload.
-- Called by Locale.Activate before the texts are built. Returns the id.
function Theme.Activate(choice)
  if Theme.active then return Theme.active end
  if choice == nil then choice = Theme.StoredChoice() end
  local id = Theme.Resolve(choice)
  Theme.active, Theme.id = id, id
  Theme.choice = Theme.Normalize(choice)
  if ns.Look then Theme.Fill(ns.Look) end
  return id
end

-- The words of the active theme: the id of its overlay in Locales\Themes\<id>.lua, or nil
function Theme.Words(id)
  id = id or current()
  local w = registry[id] and registry[id].words
  if type(w) == "string" and w ~= "" then return w end
  return nil
end
