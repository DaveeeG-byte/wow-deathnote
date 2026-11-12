-- DeathNote - Locale.lua
-- Language choice, text table ns.L, formatter with named placeholders, plural rules, font choice.
-- Loads FIRST (before Locales\*.lua and Core.lua).
--
-- How it works (1.2.0):
--   * Every file Locales\xxXX.lua stays in the TOC. It does not build its table at load time, it
--     only registers a builder function: Locale.Register("xxXX", function(L) L.KEY = "..." end).
--   * The choice lives in the SavedVariables (DeathNoteDB.settings.lang: a code; absent = "Automatic" =
--     the client's language, English when DeathNote does not have it), which
--     the client hands over only after all files ran. At ADDON_LOADED (own addon) Locale.Activate()
--     runs exactly one builder (plus English as the fallback) into ns.L and drops all other
--     builders, so the 19 unused languages are garbage after login.
--   * ns.L is one flat table that keeps its identity: `local L = ns.L` at file scope is fine,
--     reading L.KEY at file scope is not (empty until ADDON_LOADED; such reads land in Locale.early).
--   * A missing key returns the key itself (no Lua error) and lands in Locale.missing.
-- Nothing translated is ever written to DeathNoteDB, the sync protocols or the export.

local ADDON, ns = ...
local Locale = {}
ns.Locale = Locale

-- Globals through one door: rawget first, then a normal read inside pcall. Works in the client, in an
-- environment table that inherits from _G (tests: several clients) and in a strict mock that raises on
-- unknown globals (then: nil, and the defaults apply).
local function global(name)
  local ok, v = pcall(function()
    local g = _G
    local r = rawget(g, name)
    if r == nil then r = g[name] end
    return r
  end)
  if ok then return v end
  return nil
end
Locale.Global = global

local issecretvalue = global("issecretvalue")
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end

---------------------------------------------------------------------------
-- Languages
---------------------------------------------------------------------------
Locale.DEFAULT = "enUS"
Locale.SETTING = "lang"          -- DeathNoteDB.settings.lang: a code; absent = automatic (the client's language)
Locale.AUTO = "auto"             -- the choice "Automatic" (/dn lang auto, first entry in the House Rules); never stored
-- (settings.langAsked of earlier 1.2.0 builds stays readable in old files; nothing sets or reads it any more)

-- All 21, in the order of the choice in the House Rules (after "Automatic").
Locale.CODES = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW",
  "svSE", "nbNO", "daDK", "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }

-- Languages the client itself can run in (GetLocale()); the others can only be picked by hand.
Locale.CLIENT = { deDE = true, enUS = true, frFR = true, esES = true, itIT = true, ptBR = true,
  ruRU = true, koKR = true, zhCN = true, zhTW = true }

-- Client codes without an own file
Locale.ALIAS = { enGB = "enUS", esMX = "esES", ptPT = "ptBR" }

-- Each language in its own writing. Shown untranslated in every language (needs the language's own
-- font: Locale.FontList("body", code)).
Locale.NATIVE = {
  deDE = "Deutsch", enUS = "English", frFR = "Français", esES = "Español", itIT = "Italiano",
  ptBR = "Português (Brasil)", ruRU = "Русский", koKR = "한국어", zhCN = "中文(简体)", zhTW = "中文(繁體)",
  svSE = "Svenska", nbNO = "Norsk bokmål", daDK = "Dansk", fiFI = "Suomi", nlNL = "Nederlands",
  plPL = "Polski", csCZ = "Čeština", huHU = "Magyar", hrHR = "Hrvatski", ukUA = "Українська", trTR = "Türkçe",
}

local KNOWN = {}
for _, c in ipairs(Locale.CODES) do KNOWN[c] = true end
Locale.KNOWN = KNOWN

-- Short forms for /dn lang: "de" -> deDE ("zh" is ambiguous and stays invalid).
local SHORT = {}
do
  local seen = {}
  for _, c in ipairs(Locale.CODES) do
    local s = c:sub(1, 2):lower()
    if seen[s] then SHORT[s] = false else SHORT[s] = c; seen[s] = true end
  end
end

-- A known code, nil for anything else. Accepts any case, "pl-PL", "pl_pl", "pl" and the aliases.
-- ("auto" is no code: Locale.SetChoice takes it and clears the stored choice.)
function Locale.Normalize(v)
  if type(v) ~= "string" or secret(v) then return nil end
  v = v:gsub("^%s+", ""):gsub("%s+$", "")
  local low = v:lower()
  local a, b = low:match("^(%a%a)[%-_]?(%a%a)$")
  if a then
    local code = a .. b:upper()
    code = Locale.ALIAS[code] or code
    if KNOWN[code] then return code end
    return nil
  end
  if low:match("^%a%a$") then return SHORT[low] or nil end
  return nil
end

-- The client's language as one of the 21 codes (aliases mapped), or nil.
function Locale.ClientCode()
  local gl = global("GetLocale")
  if type(gl) ~= "function" then return nil end
  local ok, v = pcall(gl)
  if not ok or type(v) ~= "string" or secret(v) then return nil end
  v = Locale.ALIAS[v] or v
  if Locale.CLIENT[v] then return v end
  return nil
end

-- choice (code / nil / anything) -> the code that is built: the chosen language, else the client's
-- language (enGB -> enUS, esMX -> esES, ptPT -> ptBR), else English.
function Locale.Resolve(choice)
  return Locale.Normalize(choice) or Locale.ClientCode() or Locale.DEFAULT
end

local function settings()
  local db = global("DeathNoteDB")
  if type(db) ~= "table" then return nil end
  local st = db.settings
  if type(st) ~= "table" then return nil end
  return st
end

-- The stored choice (a code) or nil (nothing chosen). Read straight from the SavedVariables,
-- because Store.Init runs later (PLAYER_LOGIN).
function Locale.StoredChoice()
  local st = settings()
  return st and Locale.Normalize(st[Locale.SETTING]) or nil
end

-- true when v means "Automatic" (any case, surrounding blanks)
function Locale.IsAuto(v)
  return type(v) == "string" and not secret(v) and v:gsub("^%s+", ""):gsub("%s+$", ""):lower() == Locale.AUTO
end

-- Stores a new choice ("auto" clears it: the client's language). Returns the normalized choice ("auto" or a
-- code) and whether a /reload is needed, or nil.
function Locale.SetChoice(v)
  if Locale.IsAuto(v) then
    local Store = ns.Store
    if Store and Store.Setting and Store.DB and Store.DB() then
      Store.Setting(Locale.SETTING, nil)
    else
      local st = settings()
      if st then st[Locale.SETTING] = nil end
    end
    return Locale.AUTO, Locale.Pending()
  end
  local c = Locale.Normalize(v)
  if not c then return nil end
  local Store = ns.Store
  if Store and Store.Setting and Store.DB and Store.DB() then
    Store.Setting(Locale.SETTING, c)
  else
    local db = global("DeathNoteDB")
    if type(db) ~= "table" then
      db = {}
      if not pcall(function() _G.DeathNoteDB = db end) then return nil end
    end
    if type(db.settings) ~= "table" then db.settings = {} end
    db.settings[Locale.SETTING] = c
  end
  return c, Locale.Pending()
end

-- true when the stored choice resolves to another language than the active one (/reload pending).
function Locale.Pending()
  if not Locale.code then return false end
  return Locale.Resolve(Locale.StoredChoice()) ~= Locale.code
end

---------------------------------------------------------------------------
-- Plural rules (CLDR cardinal rules, integers only)
-- A rule returns the index of the form: {count|form1|form2|form3}. Counts in DeathNote are whole
-- numbers >= 0, so the CLDR category for fractions ("other" in ru/uk/pl, "many" in cs) and the
-- "many" for millions (fr/es/it/pt, CLDR 42+) are left out. Non-integers take the last form.
---------------------------------------------------------------------------
local function isInt(n) return n >= 0 and n == math.floor(n) end

Locale.RULES = {
  -- one: 1 | other
  one_other = { forms = 2, names = "one|other", fn = function(n)
    if n == 1 then return 1 end
    return 2
  end },
  -- one: 0, 1 | other (CLDR fr: i = 0,1; pt: i = 0..1)
  one01_other = { forms = 2, names = "one|other", fn = function(n)
    if n == 0 or n == 1 then return 1 end
    return 2
  end },
  -- one: n%10=1, n%100!=11 | few: n%10=2..4, n%100!=12..14 | many/other: rest (ru, uk, hr)
  slavic = { forms = 3, names = "one|few|many", fn = function(n)
    if not isInt(n) then return 3 end
    local m10, m100 = n % 10, n % 100
    if m10 == 1 and m100 ~= 11 then return 1 end
    if m10 >= 2 and m10 <= 4 and (m100 < 12 or m100 > 14) then return 2 end
    return 3
  end },
  -- one: 1 | few: n%10=2..4, n%100!=12..14 | many: rest (pl)
  polish = { forms = 3, names = "one|few|many", fn = function(n)
    if n == 1 then return 1 end
    if not isInt(n) then return 3 end
    local m10, m100 = n % 10, n % 100
    if m10 >= 2 and m10 <= 4 and (m100 < 12 or m100 > 14) then return 2 end
    return 3
  end },
  -- one: 1 | few: 2..4 | other: rest (cs)
  czech = { forms = 3, names = "one|few|other", fn = function(n)
    if n == 1 then return 1 end
    if n >= 2 and n <= 4 and isInt(n) then return 2 end
    return 3
  end },
  -- no plural (ko, zh)
  none = { forms = 1, names = "other", fn = function() return 1 end },
}

Locale.PLURAL_OF = {
  deDE = "one_other", enUS = "one_other", esES = "one_other", itIT = "one_other",
  svSE = "one_other", nbNO = "one_other", daDK = "one_other", fiFI = "one_other", nlNL = "one_other",
  huHU = "one_other", trTR = "one_other",
  frFR = "one01_other", ptBR = "one01_other",
  ruRU = "slavic", ukUA = "slavic", hrHR = "slavic",
  plPL = "polish", csCZ = "czech",
  koKR = "none", zhCN = "none", zhTW = "none",
}

local function ruleOf(code)
  return Locale.RULES[Locale.PLURAL_OF[code] or "one_other"] or Locale.RULES.one_other
end
Locale.RuleOf = ruleOf

-- Index of the plural form for n in language `code` (default: the active one).
function Locale.Plural(n, code)
  if type(n) ~= "number" or secret(n) or n ~= n then n = 0 end
  if n < 0 then n = -n end
  return ruleOf(code or Locale.code or Locale.DEFAULT).fn(n)
end

-- Number of plural forms a {count|...} must have in `code`.
function Locale.Forms(code) return ruleOf(code or Locale.code or Locale.DEFAULT).forms end

---------------------------------------------------------------------------
-- Fonts per writing system (one place; Look.FONT takes them at activation)
-- Paths only as found in installed addons: LibSharedMedia's font table
-- (ForeverAuras/DBM-Core), DBM-Core/modules/objects/StandardFont.lua, OpenMap/Map/News.lua.
-- Each list is tried in order; Look.Font ends with STANDARD_TEXT_FONT / GameFontNormal.
---------------------------------------------------------------------------
Locale.SCRIPT_OF = {
  ruRU = "cyrillic", ukUA = "cyrillic",
  koKR = "korean", zhCN = "hans", zhTW = "hant",
  plPL = "latinExt", csCZ = "latinExt", huHU = "latinExt", hrHR = "latinExt", trTR = "latinExt",
}   -- everything else: "latin"

Locale.FONTS = {
  -- as in 1.1.0
  latin = {
    title = { "Fonts\\SKURRI_CYR.TTF", "Fonts\\SKURRI.TTF" },
    hand  = { "Fonts\\MORPHEUS.TTF", "Fonts\\MORPHEUS_CYR.TTF" },
    body  = { "Fonts\\FRIZQT__.TTF" },
    type  = { "Fonts\\NIM_____.ttf" },
  },
  -- the _CYR cuts the addon already knows; Friz Quadrata in its Cyrillic cut (DBM: ruRU)
  cyrillic = {
    title = { "Fonts\\SKURRI_CYR.TTF" },
    hand  = { "Fonts\\MORPHEUS_CYR.TTF" },
    body  = { "Fonts\\FRIZQT___CYR.TTF", "Fonts\\ARIALN.TTF" },
    type  = { "Fonts\\NIM_____.ttf" },
  },
  -- Latin with ł ő ř ş ğ: no ornamental font is shown to cover it; Nimrod MT and Arial Narrow
  -- cover Latin and Cyrillic (LibSharedMedia table), which points to the WGL4 set incl. Latin Ext-A.
  latinExt = {
    title = { "Fonts\\NIM_____.ttf", "Fonts\\ARIALN.TTF" },
    hand  = { "Fonts\\NIM_____.ttf", "Fonts\\ARIALN.TTF" },
    body  = { "Fonts\\ARIALN.TTF", "Fonts\\NIM_____.ttf" },
    type  = { "Fonts\\NIM_____.ttf", "Fonts\\ARIALN.TTF" },
  },
  korean = {
    title = { "Fonts\\2002B.TTF", "Fonts\\2002.TTF" },
    hand  = { "Fonts\\2002.TTF" },
    body  = { "Fonts\\2002.TTF" },
    type  = { "Fonts\\2002.TTF" },
  },
  hans = {
    title = { "Fonts\\ARKai_T.ttf", "Fonts\\ARHei.ttf" },
    hand  = { "Fonts\\ARKai_T.ttf" },
    body  = { "Fonts\\ARKai_T.ttf", "Fonts\\ARHei.ttf" },
    type  = { "Fonts\\ARHei.ttf", "Fonts\\ARKai_T.ttf" },
  },
  hant = {
    title = { "Fonts\\bKAI00M.ttf", "Fonts\\bLEI00D.ttf" },
    hand  = { "Fonts\\bLEI00D.ttf" },
    body  = { "Fonts\\bLEI00D.ttf", "Fonts\\bHEI00M.ttf" },
    type  = { "Fonts\\bHEI00M.ttf", "Fonts\\bLEI00D.ttf" },
  },
}

function Locale.ScriptOf(code) return Locale.SCRIPT_OF[code or Locale.code or Locale.DEFAULT] or "latin" end

-- Font list for a kind ("title", "hand", "head", "body", "type") in `code` (default: active).
function Locale.FontList(kind, code)
  local set = Locale.FONTS[Locale.ScriptOf(code)] or Locale.FONTS.latin
  if kind == "head" then kind = "hand" end
  return set[kind] or set.body
end

---------------------------------------------------------------------------
-- Measuring (fixed fields): code points, for zhCN/zhTW/koKR in cells (wide = 2)
---------------------------------------------------------------------------
Locale.CELLS = { koKR = true, zhCN = true, zhTW = true }

-- East Asian Wide / Fullwidth ranges (Hangul, CJK, kana, fullwidth forms)
local WIDE = {
  { 0x1100, 0x115F }, { 0x2E80, 0x303E }, { 0x3041, 0x33FF }, { 0x3400, 0x4DBF }, { 0x4E00, 0x9FFF },
  { 0xA000, 0xA4CF }, { 0xA960, 0xA97F }, { 0xAC00, 0xD7A3 }, { 0xF900, 0xFAFF }, { 0xFE30, 0xFE4F },
  { 0xFF00, 0xFF60 }, { 0xFFE0, 0xFFE6 }, { 0x20000, 0x2FFFD }, { 0x30000, 0x3FFFD },
}
local function wide(cp)
  for i = 1, #WIDE do
    local r = WIDE[i]
    if cp < r[1] then return false end
    if cp <= r[2] then return true end
  end
  return false
end

-- Iterates code points of a (valid) UTF-8 string; invalid bytes count as one point each.
local function codepoints(s)
  local i, n = 1, #s
  return function()
    if i > n then return nil end
    local b = s:byte(i)
    local len, cp
    if b < 0x80 then len, cp = 1, b
    elseif b >= 0xF0 and b < 0xF8 then len, cp = 4, b - 0xF0
    elseif b >= 0xE0 then len, cp = 3, b - 0xE0
    elseif b >= 0xC0 then len, cp = 2, b - 0xC0
    else len, cp = 1, b end
    if len > 1 then
      for k = 1, len - 1 do
        local c = s:byte(i + k)
        if not c or c < 0x80 or c > 0xBF then len, cp = 1, b; break end
        cp = cp * 64 + (c - 0x80)
      end
    end
    i = i + len
    return cp
  end
end
Locale.Codepoints = codepoints

-- Visible text: color codes and placeholders out ({name} counts as `ph` cells, default 3; a plural
-- {count|a|b} counts as its longest form).
local function visible(s)
  return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

function Locale.Measure(s, code, ph)
  if type(s) ~= "string" then return 0 end
  ph = ph or 3
  local cells = Locale.CELLS[code] == true
  local function count(t)
    local w = 0
    for cp in codepoints(t) do
      w = w + ((cells and wide(cp)) and 2 or 1)
    end
    return w
  end
  local extra = 0
  local plain = visible(s):gsub("{([^{}]*)}", function(inner)
    local name, rest = inner:match("^([%a_][%w_]*)(.*)$")
    if name and rest == "" then
      extra = extra + ph
    elseif name and rest:sub(1, 1) == "|" then
      local best = 0
      for f in (rest:sub(2) .. "|"):gmatch("([^|]*)|") do
        local w = count(f)
        if w > best then best = w end
      end
      extra = extra + best
    else
      return nil
    end
    return ""
  end)
  return count(plain) + extra
end

---------------------------------------------------------------------------
-- Formatter: named placeholders {name}, plural {count|one|other}
-- Every text is parsed once; the parts list is kept (cache by text). A text without
-- placeholders is cached as `true` and returned as it is.
---------------------------------------------------------------------------
local cache, cached = {}, 0
local CACHE_MAX = 2000      -- only a safeguard against dynamic strings; DeathNote has a few hundred texts

local function compile(text)
  if not text:find("{", 1, true) then return true end
  local parts, pos = {}, 1
  while true do
    local s, e, inner = text:find("{([^{}]*)}", pos)
    if not s then break end
    if s > pos then parts[#parts + 1] = text:sub(pos, s - 1) end
    local name, rest = inner:match("^([%a_][%w_]*)(.*)$")
    if name and rest == "" then
      parts[#parts + 1] = { name = name }
    elseif name and rest:sub(1, 1) == "|" then
      local forms = {}
      for f in (rest:sub(2) .. "|"):gmatch("([^|]*)|") do forms[#forms + 1] = f end
      parts[#parts + 1] = { name = name, forms = forms }
    else
      parts[#parts + 1] = text:sub(s, e)     -- not a placeholder: keep literally
    end
    pos = e + 1
  end
  if pos <= #text then parts[#parts + 1] = text:sub(pos) end
  if #parts == 1 and type(parts[1]) == "string" then return true end
  return parts
end
Locale.Compile = compile

local buf = {}
local depth = 0

-- Locale.F(text, args[, code]) -> string. args: { name = "Grimm Bart", count = 3 }.
-- Missing or secret values show "?". code only for tests (plural rule of another language).
function Locale.F(text, args, code)
  if type(text) ~= "string" then return "" end
  local parts = cache[text]
  if parts == nil then
    parts = compile(text)
    if cached >= CACHE_MAX then cache, cached = {}, 0 end
    cache[text] = parts
    cached = cached + 1
  end
  if parts == true then return text end
  local rule = ruleOf(code or Locale.code or Locale.DEFAULT).fn
  local out = buf
  depth = depth + 1
  if depth > 1 then out = {} end       -- re-entered through a __tostring: own buffer
  local n = 0
  for i = 1, #parts do
    local p = parts[i]
    local v
    if type(p) == "string" then
      v = p
    else
      local a = args and args[p.name]
      if a == nil or secret(a) then
        v = p.forms and p.forms[#p.forms] or "?"
      elseif p.forms then
        local num = tonumber(a)
        if num and num == num then
          if num < 0 then num = -num end
          v = p.forms[rule(num)] or p.forms[#p.forms]
        else
          v = p.forms[#p.forms]
        end
      else
        v = tostring(a)
      end
    end
    n = n + 1
    out[n] = v
  end
  local s = table.concat(out, "", 1, n)
  depth = depth - 1
  return s
end
ns.F = Locale.F

function Locale.CacheSize() return cached end

---------------------------------------------------------------------------
-- The text table and the builders
---------------------------------------------------------------------------
local L = {}
ns.L = L
Locale.missing = {}     -- key -> true: asked for after activation, but no language has it
Locale.early = {}       -- key -> true: asked for before activation (file scope, a bug)
setmetatable(L, { __index = function(_, k)
  if Locale.code then Locale.missing[k] = true else Locale.early[k] = true end
  return tostring(k)
end })

local registry = {}     -- code -> builder; nil after activation

-- True while the language file should register its builder (before activation, known code).
function Locale.Wants(code)
  return registry ~= nil and KNOWN[code] == true
end

function Locale.Register(code, fn)
  if registry == nil or not KNOWN[code] or type(fn) ~= "function" then return false end
  registry[code] = fn
  return true
end

function Locale.Registered(code) return registry ~= nil and registry[code] ~= nil end

local function report(err)
  local geh = global("geterrorhandler")
  local eh = type(geh) == "function" and geh()
  if eh then pcall(eh, err) end
end

-- The language's own table, without fallback (tests, statistics). nil, err when the builder fails.
function Locale.Raw(code)
  local fn = registry and registry[code]
  if not fn then return nil, "not registered" end
  local t = {}
  local ok, err = pcall(fn, t)
  if not ok then return nil, err end
  return t
end

local function wipe(t) for k in pairs(t) do t[k] = nil end return t end

---------------------------------------------------------------------------
-- Theme words (1.3.0): a theme may set its own SHOW words (titles, tabs, page heads, stamps, alarm titles, the
-- welcome, the currency of the book's value). Control words (buttons, menus, switches, commands) never change,
-- so every button keeps its name in every theme. A file Locales\Themes\<id>.lua registers one builder per
-- language: Locale.RegisterWords("<id>", "deDE", function(T) T.TAB_WANTED = "..." end).
-- A word the theme lacks in a language keeps the base word OF THAT LANGUAGE (never the theme's English word).
---------------------------------------------------------------------------
Locale.THEME_KEYS = {
  BOOK_TITLE = true, POSTER_HEAD = true, POSTER_DOA = true, POSTER_BOUNTY = true,
  TAB_WANTED = true, TAB_DEATHLOG = true, TAB_GUILD = true, TAB_GUILD_FRIENDS = true, TAB_RECORD = true,
  HEAD_RULES = true, HEAD_HELP = true,
  STAMP_NR1 = true, STAMP_GUILD_NR1 = true, STAMP_REVENGE = true, STAMP_PARDONED = true, STAMP_HUNT = true,
  STAMP_QUITT = true, STAMP_OVERPAID = true,
  POSTER_HUNTLIST = true, BANNER_HUNT = true, BANNER_NEW = true, BANNER_REVENGE = true,
  ALERT_SIGHTED = true, ALERT_SIGHTED_NR1 = true, ALERT_TITLE_GUILD = true, ALERT_TITLE_FRIENDS = true,
  ALERT_TITLE_HUNT = true,
  BOUNTY_GOLD = true, BOUNTY_SILVER = true,
  WELCOME = true, EMPTY_WANTED_HEAD = true, EMPTY_WANTED_SUB = true, EMPTY_JOURNAL_HEAD = true, EMPTY_JOURNAL_SUB = true,
}

local words = {}        -- theme -> code -> builder; nil after activation

function Locale.RegisterWords(theme, code, fn)
  if words == nil or type(theme) ~= "string" or not KNOWN[code] or type(fn) ~= "function" then return false end
  words[theme] = words[theme] or {}
  words[theme][code] = fn
  return true
end

-- The theme's own words in `code`, without fallback (tests). nil, err when there are none or the builder fails.
function Locale.RawWords(theme, code)
  local fn = words and words[theme] and words[theme][code]
  if not fn then return nil, "not registered" end
  local t = {}
  local ok, err = pcall(fn, t)
  if not ok then return nil, err end
  return t
end

-- Lays the words of `theme` in `code` over `into` (show keys only, only keys English has, no empty text).
-- Returns the number of words taken.
function Locale.ApplyWords(theme, code, into)
  if not theme then return 0 end
  local t, err = Locale.RawWords(theme, code)
  if not t then
    if err ~= "not registered" then report("DeathNote Locale " .. tostring(theme) .. " " .. tostring(code) .. ": " .. tostring(err)) end
    return 0
  end
  local n = 0
  for k, v in pairs(t) do
    if Locale.THEME_KEYS[k] and rawget(into, k) ~= nil and type(v) == "string" and v ~= "" then into[k] = v; n = n + 1 end
  end
  return n
end

-- Builds English plus the overlay of `code` into `into` (default a new table); 1.3.0: plus the words of `theme`.
-- Returns into, own (keys the language itself delivered), total (English keys), extra (unknown keys).
function Locale.Build(code, into, theme)
  into = wipe(into or {})
  local en, err = Locale.Raw(Locale.DEFAULT)
  -- 1.2.0: without English the chosen language stands in (below); reported only when nothing is there
  if not en then
    if code == Locale.DEFAULT or not Locale.Raw(code) then report("DeathNote Locale enUS: " .. tostring(err)) end
    en = {}
  end
  local total = 0
  for k, v in pairs(en) do
    if type(v) == "string" then into[k] = v; total = total + 1 end
  end
  if code == Locale.DEFAULT then
    Locale.themeWords = Locale.ApplyWords(theme, code, into)
    return into, total, total, 0
  end
  local own, extra = 0, 0
  local t, err2 = Locale.Raw(code)
  if not t and err2 ~= "not registered" then report("DeathNote Locale " .. tostring(code) .. ": " .. tostring(err2)) end
  -- 1.2.0: English missing or broken (incomplete zip, typo): the chosen language is taken as it is,
  -- else even a complete translation would show key names only
  local noEnglish = true
  for _ in pairs(en) do noEnglish = false; break end
  if t then
    for k, v in pairs(t) do
      if noEnglish and type(k) == "string" and type(v) == "string" and v ~= "" then
        into[k] = v
        own = own + 1
      elseif en[k] == nil then
        extra = extra + 1
      elseif type(v) == "string" and v ~= "" then
        into[k] = v
        own = own + 1
      end
    end
  end
  Locale.themeWords = Locale.ApplyWords(theme, code, into)
  return into, own, total, extra
end

local listeners = {}

-- fn(code) runs once after activation (at once, when it already happened). For hot paths: fetch
-- the texts there into locals.
function Locale.OnActivate(fn)
  if type(fn) ~= "function" then return end
  if Locale.code then
    local ok, err = pcall(fn, Locale.code)
    if not ok then report(err) end
    return
  end
  listeners[#listeners + 1] = fn
end

-- Builds the active language into ns.L. choice: nil = the stored one. Runs once (later calls
-- return the active code); a change of language takes a /reload.
function Locale.Activate(choice)
  if Locale.code then return Locale.code end
  if choice == nil then choice = Locale.StoredChoice() end
  local code = Locale.Resolve(choice)
  if not (registry and registry[code]) then code = Locale.DEFAULT end
  -- 1.3.0: the theme first (its words are the third layer; it also fills ns.Look with its look)
  local Theme, theme = ns.Theme, nil
  if Theme and Theme.Activate then
    local ok, id = pcall(Theme.Activate)
    if ok then theme = Theme.Words and Theme.Words(id) or nil else report(id) end
  end
  local _, own, total, extra = Locale.Build(code, L, theme)
  Locale.code = code
  Locale.choice = Locale.Normalize(choice)        -- nil: automatic (the client's language)
  Locale.own, Locale.total, Locale.extra = own, total, extra
  Locale.fallback = own < total      -- some texts are English
  registry = nil                     -- the other builders (and their strings) go to the GC
  words = nil                        -- likewise the words of the themes
  for i = 1, #listeners do
    local ok, err = pcall(listeners[i], code)
    if not ok then report(err) end
  end
  listeners = {}
  return code
end

-- ADDON_LOADED of this addon: the SavedVariables are there. Own small frame, because Core.lua
-- (ns:RegisterEvent) loads after this file; it unregisters itself after the one event.
do
  local CF = global("CreateFrame")
  if type(CF) == "function" then
    local ok, f = pcall(CF, "Frame")
    if ok and f and pcall(f.RegisterEvent, f, "ADDON_LOADED") then
      Locale.frame = f
      f:SetScript("OnEvent", function(self, event, name)
        if event ~= "ADDON_LOADED" or secret(name) or name ~= ADDON then return end
        pcall(self.UnregisterEvent, self, "ADDON_LOADED")
        self:SetScript("OnEvent", nil)
        Locale.Activate()
      end)
    end
  end
end
