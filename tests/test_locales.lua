-- Language scaffold (1.2.0): Locale.lua and every Locales/xxXX.lua.
-- Stand-alone (own tiny harness, no mock_wow): runs as `luajit tests/test_locales.lua`.
-- Untranslated keys are a hint ("faellt auf Englisch zurueck", the test output stays German); STRICT=1 turns them into errors,
-- together with a missing TOC-Notes sentence and Locale files missing in DeathNote.toc.

local ROOT = (arg and arg[0] and arg[0]:match("^(.*)/tests/")) or "."
local DIR = ROOT .. "/DeathNote/"
local STRICT = os.getenv("STRICT") == "1"

---------------------------------------------------------------------------
-- Harness
---------------------------------------------------------------------------
local pass, fail, failures, hints = 0, 0, {}, {}
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then pass = pass + 1 else fail = fail + 1; failures[#failures + 1] = name .. ": " .. tostring(err) end
end
local function eq(a, b, msg)
  if a ~= b then error((msg or "eq") .. ": erwartet " .. tostring(b) .. ", bekommen " .. tostring(a), 2) end
end
local function ok(v, msg) if not v then error((msg or "ok") .. ": erwartet wahr", 2) end end
local function hint(s) hints[#hints + 1] = s end

local function readFile(p)
  local h = io.open(p, "rb")
  if not h then return nil end
  local s = h:read("*a"); h:close()
  return s
end

---------------------------------------------------------------------------
-- Loading: a fresh namespace with Locale.lua and all language files, like the client does
---------------------------------------------------------------------------
local secrets = setmetatable({}, { __mode = "k" })
local function Secret()
  local p = newproxy(true)
  local mt = getmetatable(p)
  local function boom() error("secret value used", 2) end
  mt.__index, mt.__concat, mt.__tostring, mt.__len, mt.__lt, mt.__le = boom, boom, boom, boom, boom, boom
  secrets[p] = true
  return p
end

local CODES_FILE_ORDER   -- filled after the first load (Locale.CODES, enUS first)
local frames = {}

local function newClient(opts)
  opts = opts or {}
  frames = {}
  _G.issecretvalue = function(v) return secrets[v] == true end
  _G.GetLocale = function() return opts.client or "deDE" end
  _G.DeathNoteDB = opts.db
  _G.geterrorhandler = function() return function(e) error("addon error: " .. tostring(e)) end end
  _G.CreateFrame = function()
    local f = { events = {}, scripts = {} }
    function f:RegisterEvent(ev) self.events[ev] = true end
    function f:UnregisterEvent(ev) self.events[ev] = nil end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    frames[#frames + 1] = f
    return f
  end
  local ns = {}
  assert(loadfile(DIR .. "Locale.lua"))("DeathNote", ns)
  local order = { "enUS" }
  for _, c in ipairs(ns.Locale.CODES) do if c ~= "enUS" then order[#order + 1] = c end end
  CODES_FILE_ORDER = order
  for _, c in ipairs(order) do
    if not (opts.skip and opts.skip[c]) then
      local chunk = assert(loadfile(DIR .. "Locales/" .. c .. ".lua"))
      chunk("DeathNote", ns)
    end
  end
  return ns
end

local function fire(event, ...)
  for _, f in ipairs(frames) do
    if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
  end
end

local base = newClient()
local Locale = base.Locale
local CODES = Locale.CODES
local EN = assert(Locale.Raw("enUS"), "enUS baut")
-- (fix-2) Length limits and translator guide no longer live in the addon folder (the game never loads them)
local LIMITS = assert(loadfile(ROOT .. "/tests/sprachen/_limits.lua"))()

---------------------------------------------------------------------------
-- Text checks (shared by all languages)
---------------------------------------------------------------------------
local function validUtf8(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len, min
    if b < 0x80 then len = 1
    elseif b >= 0xC2 and b <= 0xDF then len, min = 2, 0x80
    elseif b >= 0xE0 and b <= 0xEF then len, min = 3, 0x800
    elseif b >= 0xF0 and b <= 0xF4 then len, min = 4, 0x10000
    else return false, i end
    if len > 1 then
      local cp = b % (len == 2 and 0x20 or len == 3 and 0x10 or 0x08)
      for k = 1, len - 1 do
        local c = s:byte(i + k)
        if not c or c < 0x80 or c > 0xBF then return false, i end
        cp = cp * 64 + c - 0x80
      end
      if cp < min or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF) then return false, i end
    end
    i = i + len
  end
  return true
end

-- placeholder names (sorted, joined) and plural specs of a text
local function placeholders(s)
  local names, plurals = {}, {}
  for inner in s:gmatch("{([^{}]*)}") do
    local name, rest = inner:match("^([%a_][%w_]*)(.*)$")
    if name and rest == "" then names[name] = true
    elseif name and rest:sub(1, 1) == "|" then
      names[name] = true
      local forms = {}
      for f in (rest:sub(2) .. "|"):gmatch("([^|]*)|") do forms[#forms + 1] = f end
      plurals[#plurals + 1] = { name = name, forms = forms }
    end
  end
  local list = {}
  for k in pairs(names) do list[#list + 1] = k end
  table.sort(list)
  return table.concat(list, ","), plurals
end

-- problems of one text in one language (list of strings)
local function checkText(code, key, v)
  local p = {}
  if type(v) ~= "string" then p[#p + 1] = "kein Text (" .. type(v) .. ")"; return p end
  if v == "" or v:match("^%s*$") then p[#p + 1] = "leer" end
  local good, at = validUtf8(v)
  if not good then p[#p + 1] = "kein gueltiges UTF-8 ab Byte " .. at end
  if v:find("[%z\1-\9\11-\31\127]") then p[#p + 1] = "Steuerzeichen" end
  -- braces: every { closes, nothing nested
  local depth = 0
  for ch in v:gmatch("[{}]") do
    depth = depth + (ch == "{" and 1 or -1)
    if depth < 0 or depth > 1 then break end
  end
  if depth ~= 0 then p[#p + 1] = "Klammern { } nicht paarig" end
  -- "|" only in color codes and as the separator of a plural
  local rest = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("{[%a_][%w_]*|[^{}]*}", "")
  if rest:find("|", 1, true) then p[#p + 1] = "'|' ausserhalb von Farbcode oder Mehrzahl" end
  local enText = EN[key]
  if type(enText) == "string" then
    local mine, plurals = placeholders(v)
    local theirs = placeholders(enText)
    if mine ~= theirs then p[#p + 1] = "Platzhalter {" .. mine .. "} statt {" .. theirs .. "}" end
    local need = Locale.Forms(code)
    for _, pl in ipairs(plurals) do
      if #pl.forms ~= need then
        p[#p + 1] = ("Mehrzahl {%s|...} hat %d Formen, %s braucht %d"):format(pl.name, #pl.forms, code, need)
      end
      for _, f in ipairs(pl.forms) do if f == "" then p[#p + 1] = "leere Mehrzahl-Form" end end
    end
  end
  local lim = LIMITS[key]
  if lim then
    local w = Locale.Measure(v, code)
    if w > lim.max then
      p[#p + 1] = ("zu lang: %d > %d %s (%s)"):format(w, lim.max, Locale.CELLS[code] and "Zellen" or "Zeichen", lim.field)
    end
  end
  return p
end

---------------------------------------------------------------------------
-- Files
---------------------------------------------------------------------------
test("21 Sprachen, je Kennung Datei, Mehrzahl-Regel, Name, Schrift", function()
  eq(#CODES, 21, "Zahl der Sprachen")
  local seen = {}
  for _, c in ipairs(CODES) do
    ok(not seen[c], "doppelt " .. c); seen[c] = true
    ok(readFile(DIR .. "Locales/" .. c .. ".lua"), "Datei fehlt: Locales/" .. c .. ".lua")
    ok(Locale.PLURAL_OF[c] and Locale.RULES[Locale.PLURAL_OF[c]], "Mehrzahl-Regel fehlt: " .. c)
    ok(type(Locale.NATIVE[c]) == "string" and Locale.NATIVE[c] ~= "", "Eigenname fehlt: " .. c)
    ok(Locale.Registered(c), "registriert sich nicht: " .. c)
  end
  local n = 0
  for _ in pairs(Locale.CLIENT) do n = n + 1 end
  eq(n, 10, "Client-Sprachen")
end)

test("Dateien gueltiges UTF-8 ohne BOM, Kopf prueft die Sprache", function()
  local files = { "Locale.lua", "../tests/sprachen/_limits.lua" }
  for _, c in ipairs(CODES) do files[#files + 1] = "Locales/" .. c .. ".lua" end
  for _, f in ipairs(files) do
    local s = assert(readFile(DIR .. f), f)
    ok(s:sub(1, 3) ~= "\239\187\191", "BOM in " .. f)
    local good, at = validUtf8(s)
    ok(good, f .. ": kein UTF-8 ab Byte " .. tostring(at))
  end
  for _, c in ipairs(CODES) do
    local s = readFile(DIR .. "Locales/" .. c .. ".lua")
    ok(s:find('if not %(Locale and Locale%.Wants%("' .. c .. '"%)%) then return end'), "Kopf fehlt: " .. c)
    ok(s:find('Locale%.Register%("' .. c .. '"'), "Register mit eigener Kennung fehlt: " .. c)
  end
end)

test("Sprachdatei ohne Gerüst (ns ohne Locale) bricht nicht", function()
  local chunk = assert(loadfile(DIR .. "Locales/frFR.lua"))
  chunk("DeathNote", {})
  chunk("DeathNote", nil)
end)

---------------------------------------------------------------------------
-- Every language against English
---------------------------------------------------------------------------
test("Englisch: Texte sauber, Hoechstlaengen und [max N] stimmen ueberein", function()
  local bad = {}
  for k, v in pairs(EN) do
    for _, pr in ipairs(checkText("enUS", k, v)) do bad[#bad + 1] = k .. ": " .. pr end
  end
  -- every limit belongs to an English key; every [max N] comment matches the table
  local src = readFile(DIR .. "Locales/enUS.lua")
  local commented = {}
  for line in src:gmatch("[^\n]+") do
    local key = line:match("^%s*L%.([%w_]+)%s*=")
    if key then
      local m = line:match("%-%-.-%[max (%d+)%]")
      commented[key] = m and tonumber(m) or false
    end
  end
  for k, lim in pairs(LIMITS) do
    if EN[k] == nil then bad[#bad + 1] = "_limits." .. k .. " ohne englischen Text" end
    if commented[k] ~= lim.max then
      bad[#bad + 1] = ("%s: Kommentar [max %s], _limits %d"):format(k, tostring(commented[k]), lim.max)
    end
  end
  for k, m in pairs(commented) do
    if m and not LIMITS[k] then bad[#bad + 1] = k .. ": [max] im Kommentar, fehlt in _limits.lua" end
  end
  table.sort(bad)
  ok(#bad == 0, "\n    " .. table.concat(bad, "\n    "))
end)

local fallbackOf = {}
for _, code in ipairs(CODES) do
  if code ~= "enUS" then
    test("Sprache " .. code, function()
      local t, err = Locale.Raw(code)
      ok(t, "baut nicht: " .. tostring(err))
      local bad, missing = {}, {}
      for k, v in pairs(t) do
        if EN[k] == nil then
          bad[#bad + 1] = k .. ": ueberzaehlig (nicht in enUS)"
        else
          for _, pr in ipairs(checkText(code, k, v)) do bad[#bad + 1] = k .. ": " .. pr end
        end
      end
      for k in pairs(EN) do if t[k] == nil then missing[#missing + 1] = k end end
      table.sort(missing)
      fallbackOf[code] = missing
      local soft = {}
      if #missing > 0 then
        local total = 0
        for _ in pairs(EN) do total = total + 1 end
        soft[#soft + 1] = ("fällt auf Englisch zurück (%d von %d Texten%s)"):format(#missing, total,
          #missing <= 8 and (": " .. table.concat(missing, ", ")) or "")
      end
      -- TOC-Notes sentence for client languages
      if Locale.CLIENT[code] then
        local src = readFile(DIR .. "Locales/" .. code .. ".lua")
        local notes = src:match("\n%-%- TOC%-Notes: ([^\n]*)")
        if not notes or notes:find("TODO", 1, true) or notes:match("^%s*$") then soft[#soft + 1] = "TOC-Notes-Satz fehlt" end
      end
      if #soft > 0 then
        if STRICT then
          for _, s in ipairs(soft) do bad[#bad + 1] = s end
          if #missing > 8 then bad[#bad + 1] = "fehlend: " .. table.concat(missing, ", ") end
        else
          hint(code .. ": " .. table.concat(soft, "; "))
        end
      end
      table.sort(bad)
      ok(#bad == 0, "\n    " .. table.concat(bad, "\n    "))
    end)
  end
end

-- fix-2 (finding 15 of the final hunt): date formats only with characters every C library knows
test("Datumsformate aller Sprachen: nur %d %m %y %Y %H %M und %%", function()
  local bad = {}
  for _, code in ipairs(Locale.CODES) do
    local t = Locale.Raw(code) or {}
    for _, k in ipairs({ "TIME_FMT_WHEN", "TIME_FMT_WHEN_YEAR", "TIME_FMT_DAY", "TIME_FMT_DAY_YEAR" }) do
      local f = t[k]
      if f ~= nil and (type(f) ~= "string" or f:gsub("%%[dmyYHM%%]", ""):find("%", 1, true)) then
        bad[#bad + 1] = code .. " " .. k .. " = " .. tostring(f)
      end
    end
  end
  ok(#bad == 0, table.concat(bad, "; "))
end)

test("Deutsch ist vollstaendig (Wortlaut 1.1.0)", function()
  ok(#(fallbackOf.deDE or { 1 }) == 0, "deDE fehlt: " .. table.concat(fallbackOf.deDE or {}, ", "))
  local de = Locale.Raw("deDE")
  eq(de.TAB_UNSOLVED, "Zu klären"); eq(de.HEAD_RULES, "Hausordnung")
  eq(de.STAMP_NR1, "STAATSFEIND Nr. 1"); eq(de.ALERT_SIGHTED, "STAATSFEIND GESICHTET")
end)

---------------------------------------------------------------------------
-- Plural rules (CLDR, integers), numbers from the brief
---------------------------------------------------------------------------
local NUMS = { 0, 1, 2, 3, 4, 5, 11, 12, 21, 22, 25, 101, 111 }
local TWO   = { 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 }
local TWO01 = { 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 }
local SLAV  = { 3, 1, 2, 2, 2, 3, 3, 3, 1, 2, 3, 1, 3 }
local POL   = { 3, 1, 2, 2, 2, 3, 3, 3, 3, 2, 3, 3, 3 }
local CZE   = { 3, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3 }
local ONE   = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
local EXPECT = {
  deDE = { 2, TWO }, enUS = { 2, TWO }, esES = { 2, TWO }, itIT = { 2, TWO }, svSE = { 2, TWO },
  nbNO = { 2, TWO }, daDK = { 2, TWO }, fiFI = { 2, TWO }, nlNL = { 2, TWO }, huHU = { 2, TWO }, trTR = { 2, TWO },
  frFR = { 2, TWO01 }, ptBR = { 2, TWO01 },
  ruRU = { 3, SLAV }, ukUA = { 3, SLAV }, hrHR = { 3, SLAV },
  plPL = { 3, POL }, csCZ = { 3, CZE },
  koKR = { 1, ONE }, zhCN = { 1, ONE }, zhTW = { 1, ONE },
}
for _, code in ipairs(CODES) do
  test("Mehrzahl " .. code, function()
    local e = assert(EXPECT[code], "keine Erwartung")
    eq(Locale.Forms(code), e[1], "Zahl der Formen")
    for i, n in ipairs(NUMS) do eq(Locale.Plural(n, code), e[2][i], code .. " n=" .. n) end
    -- every index is in range, also for big numbers and fractions
    for _, n in ipairs({ 1000, 1001, 1002, 1012, 2.5, 0.5 }) do
      local idx = Locale.Plural(n, code)
      ok(idx >= 1 and idx <= e[1], code .. " n=" .. n .. " Index " .. idx)
    end
  end)
end

test("Mehrzahl im Text: Deutsch, Russisch, Polnisch, Chinesisch", function()
  local F = Locale.F
  eq(F("{count} {count|Kollege|Kollegen}", { count = 1 }, "deDE"), "1 Kollege")
  eq(F("{count} {count|Kollege|Kollegen}", { count = 3 }, "deDE"), "3 Kollegen")
  eq(F("{count} {count|Kollege|Kollegen}", { count = 0 }, "deDE"), "0 Kollegen")
  local ru = "{count} {count|смерть|смерти|смертей}"
  eq(F(ru, { count = 1 }, "ruRU"), "1 смерть"); eq(F(ru, { count = 22 }, "ruRU"), "22 смерти")
  eq(F(ru, { count = 11 }, "ruRU"), "11 смертей"); eq(F(ru, { count = 101 }, "ruRU"), "101 смерть")
  local pl = "{count} {count|zabójca|zabójcy|zabójców}"
  eq(F(pl, { count = 21 }, "plPL"), "21 zabójców"); eq(F(pl, { count = 24 }, "plPL"), "24 zabójcy")
  eq(F("{count}{count|次}", { count = 5 }, "zhCN"), "5次")
  eq(F("{count} {count|a|b}", { count = 5 }, "frFR"), "5 b"); eq(F("{count} {count|a|b}", { count = 0 }, "frFR"), "0 a")
  -- too few forms from a translator: last one, no error
  eq(F("{count|x}", { count = 5 }, "ruRU"), "x")
end)

---------------------------------------------------------------------------
-- Formatter
---------------------------------------------------------------------------
test("Formatierer: benannte Platzhalter, Reihenfolge frei, Fehlendes und Secrets als ?", function()
  local F = Locale.F
  eq(F("{name} steht jetzt im Buch.", { name = "Grimm Bart" }), "Grimm Bart steht jetzt im Buch.")
  eq(F("{b} vor {a}", { a = 1, b = 2 }), "2 vor 1")
  eq(F("{a}{a}", { a = "x" }), "xx")
  eq(F("Nochmal in {seconds} Sek.", {}), "Nochmal in ? Sek.")
  eq(F("Nochmal in {seconds} Sek."), "Nochmal in ? Sek.")
  eq(F("{name}!", { name = Secret() }), "?!")
  eq(F("{count|eins|viele}", { count = Secret() }), "viele")
  eq(F("{count|eins|viele}", { count = "abc" }), "viele")
  eq(F("ohne Platzhalter"), "ohne Platzhalter")
  eq(F("{nicht gültig} und {}", {}), "{nicht gültig} und {}")
  eq(F("|cffc41e3a{name}|r", { name = "X" }), "|cffc41e3aX|r")
  eq(F(nil), "")
end)

test("Formatierer haelt die Schablone (einmal je Text gebaut)", function()
  local ns = newClient()
  local L = ns.Locale
  local before = L.CacheSize()
  local text = "{name} hat {count} {count|Tat|Taten}"
  -- the size of the cache counts the compiles: further calls must not grow it
  L.F(text, { name = "A", count = 2 }, "deDE")
  eq(L.CacheSize(), before + 1)
  for i = 1, 50 do L.F(text, { name = "A", count = i }, "deDE") end
  eq(L.CacheSize(), before + 1, "Schablone neu gebaut")
  eq(L.F(text, { name = "A", count = 1 }, "deDE"), "A hat 1 Tat")
  -- text without placeholders: the same string comes back
  local s = "Gesucht"
  ok(rawequal(L.F(s), s))
end)

---------------------------------------------------------------------------
-- Choice and activation
---------------------------------------------------------------------------
-- Language choice (addendum 3, 11.11.2026): without a choice the client's language, else English; no dialog
test("Sprachwahl: ohne Wahl die Client-Sprache, enGB/esMX/ptPT, unbekannt oder svSE: Englisch", function()
  local R = Locale.Resolve
  _G.GetLocale = function() return "deDE" end
  eq(R(nil), "deDE", "nichts gewaehlt, deutscher Client: Deutsch"); eq(R("auto"), "deDE"); eq(R("quatsch"), "deDE")
  eq(R("plPL"), "plPL"); eq(R("ukUA"), "ukUA"); eq(R("enGB"), "enUS"); eq(R("esMX"), "esES"); eq(R("ptPT"), "ptBR")
  eq(Locale.ClientCode(), "deDE")
  for client, want in pairs({ enGB = "enUS", esMX = "esES", ptPT = "ptBR", frFR = "frFR", koKR = "koKR", zhTW = "zhTW",
    svSE = "enUS", xxXX = "enUS", [""] = "enUS" }) do
    _G.GetLocale = function() return client end
    eq(R(nil), want, "Client " .. client)
  end
  _G.GetLocale = function() return Secret() end
  eq(R(nil), "enUS", "Secret als Client-Sprache")
  ok(Locale.NeedsChoice == nil and Locale.MarkAsked == nil, "kein Dialog mehr")
end)

test("Sprachwahl: Eingaben fuer /dn lang", function()
  local N = Locale.Normalize
  eq(N("plPL"), "plPL"); eq(N("plpl"), "plPL"); eq(N("pl-PL"), "plPL"); eq(N("pl_pl"), "plPL"); eq(N(" PL "), "plPL")
  eq(N("pl"), "plPL"); eq(N("de"), "deDE"); eq(N("en"), "enUS"); eq(N("enGB"), "enUS"); eq(N("esMX"), "esES")
  eq(N("zh"), nil, "zh ist mehrdeutig"); eq(N("auto"), nil, "auto ist keine Kennung"); eq(N("Automatisch"), nil)
  ok(Locale.IsAuto("auto") and Locale.IsAuto(" AUTO ") and not Locale.IsAuto("de") and not Locale.IsAuto(Secret()), "auto erkannt")
  eq(N("xxXX"), nil); eq(N(""), nil); eq(N(nil), nil); eq(N(42), nil); eq(N(Secret()), nil)
end)

test("Aktivierung erst bei ADDON_LOADED des eigenen Addons, gewaehltes Deutsch bleibt deutsch", function()
  local ns = newClient({ client = "deDE", db = { settings = { lang = "deDE" } } })
  local L, Lc = ns.L, ns.Locale
  eq(Lc.code, nil)
  fire("ADDON_LOADED", "Questie")
  eq(Lc.code, nil, "fremdes Addon aktiviert nichts")
  fire("ADDON_LOADED", Secret())
  eq(Lc.code, nil, "Secret als Name")
  fire("ADDON_LOADED", "DeathNote")
  eq(Lc.code, "deDE"); eq(Lc.choice, "deDE")
  eq(L.TAB_WANTED, "Gesucht"); eq(L.STAMP_NR1, "STAATSFEIND Nr. 1")
  eq(rawget(L, "TAB_WANTED"), "Gesucht", "flache Tabelle, kein Metatable-Weg")
  eq(Lc.fallback, false)
  ok(not Lc.Registered("frFR"), "uebrige Bauanleitungen freigegeben")
  ok(not Lc.Wants("frFR"), "nach der Aktivierung registriert sich nichts mehr")
  eq(Lc.Activate("frFR"), "deDE", "nur einmal")
  ok(not frames[1].events.ADDON_LOADED, "Ereignis abgemeldet")
end)

test("Frischer deutscher Client: Deutsch aktiv; Bestand aus 1.1.0 bleibt deutsch; gespeicherte Wahl gilt", function()
  local ns0 = newClient({ client = "deDE" })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns0.Locale.code, "deDE"); eq(ns0.Locale.choice, nil); eq(ns0.L.TAB_WANTED, "Gesucht")
  local db1 = { settings = { welcomed = true } }      -- data from 1.1.0 (German client): stays German
  local ns1 = newClient({ client = "deDE", db = db1 })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns1.Locale.code, "deDE"); eq(db1.settings.lang, nil, "keine Wahl gespeichert")
  local db1b = { settings = { langAsked = true } }    -- marker of an interim version: dead field, does no harm
  local ns1b = newClient({ client = "frFR", db = db1b })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns1b.Locale.code, "frFR"); eq(db1b.settings.langAsked, true, "bleibt lesbar stehen")
  local ns = newClient({ client = "deDE", db = { settings = { lang = "plPL" } } })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns.Locale.code, "plPL"); eq(ns.Locale.choice, "plPL")
  ok(type(ns.L.TAB_WANTED) == "string" and ns.L.TAB_WANTED ~= "", "Text da (uebersetzt oder Rueckfall Englisch)")
  eq(ns.Locale.Forms(), 3, "Mehrzahl der aktiven Sprache")
  local ns2 = newClient({ client = "frFR", db = { settings = { lang = "kaputt" } } })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns2.Locale.code, "frFR", "kaputte Wahl: Client-Sprache"); eq(ns2.Locale.choice, nil)
  local ns3 = newClient({ client = "zhTW", db = { settings = 5 } })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns3.Locale.code, "zhTW")
  local ns5 = newClient({ client = "svSE" })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns5.Locale.code, "enUS", "svSE gibt es als Client nicht: Englisch")
  local ns4 = newClient({ client = "enGB" })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns4.Locale.code, "enUS"); eq(ns4.L.TAB_UNSOLVED, "Unsolved")
end)

test("Laufzeit: leerer oder unbekannter Text einer Sprache verdraengt Englisch nicht", function()
  local ns = newClient({ client = "deDE", db = { settings = { lang = "svSE" } } })
  ns.Locale.Register("svSE", function(L)
    L.TAB_WANTED = "Efterlysta"; L.TAB_GUILD = ""; L.TAB_UNSOLVED = 5; L.GIBTS_NICHT = "x"
  end)
  fire("ADDON_LOADED", "DeathNote")
  eq(ns.L.TAB_WANTED, "Efterlysta"); eq(ns.L.TAB_GUILD, "Guild"); eq(ns.L.TAB_UNSOLVED, "Unsolved")
  eq(rawget(ns.L, "GIBTS_NICHT"), nil)
  eq(ns.Locale.own, 1); eq(ns.Locale.extra, 1)
end)

-- loads Locale.lua and the files into an own environment (like the mocks do with setfenv)
local function loadInEnv(env)
  local ns = {}
  local function run(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    chunk("DeathNote", ns)
  end
  run(DIR .. "Locale.lua")
  for _, c in ipairs(CODES_FILE_ORDER) do run(DIR .. "Locales/" .. c .. ".lua") end
  return ns
end

test("Strenge Umgebung (UI-Mock: unbekannte Globale werfen, kein _G): Laden und Activate(Wahl) gehen", function()
  local strict = setmetatable({ pairs = pairs, ipairs = ipairs, type = type, pcall = pcall, rawget = rawget,
    tostring = tostring, tonumber = tonumber, setmetatable = setmetatable, string = string, table = table,
    math = math }, { __index = function(_, k) error("unbekannte globale Variable: " .. tostring(k), 2) end })
  local ns = loadInEnv(strict)
  eq(ns.Locale.ClientCode(), nil); eq(ns.Locale.StoredChoice(), nil); eq(ns.Locale.Resolve(nil), "enUS")
  eq(ns.Locale.Activate("deDE"), "deDE"); eq(ns.L.TAB_WANTED, "Gesucht")
  local ns2 = loadInEnv(strict)
  eq(ns2.Locale.Activate(), "enUS", "ohne GetLocale: Englisch")
end)

test("Umgebung mit eigenem GetLocale und DeathNoteDB, Rest von _G geerbt (mehrere Clients)", function()
  _G.GetLocale = function() return "deDE" end
  _G.DeathNoteDB = nil
  local env = setmetatable({ GetLocale = function() return "ruRU" end, DeathNoteDB = { settings = { lang = "ruRU" } } },
    { __index = _G })
  env._G = env
  local ns = loadInEnv(env)
  eq(ns.Locale.ClientCode(), "ruRU")
  eq(ns.Locale.Activate(), "ruRU")
  local env2 = setmetatable({ DeathNoteDB = { settings = { lang = "csCZ" } } }, { __index = _G })
  env2._G = env2
  local ns2 = loadInEnv(env2)
  eq(ns2.Locale.Activate(), "csCZ")
  local ns3 = loadInEnv(env2)
  ns3.Locale.Activate()
  ns3.Locale.SetChoice("trTR")
  eq(env2.DeathNoteDB.settings.lang, "trTR", "schreibt in die eigene Umgebung")
  local env3 = setmetatable({}, { __index = _G })
  env3._G = env3
  eq(loadInEnv(env3).Locale.ClientCode(), "deDE", "GetLocale geerbt")
  eq(loadInEnv(env3).Locale.Activate(), "deDE", "ohne Wahl die Client-Sprache")
end)

test("Fehlende Sprachdatei: Englisch statt Fehler", function()
  local ns = newClient({ client = "deDE", db = { settings = { lang = "huHU" } }, skip = { huHU = true } })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns.Locale.code, "enUS"); eq(ns.L.HEAD_HELP, "How it works")
end)

test("Fehlender Schluessel: Schluessel selbst, gemerkt; Zugriff vor der Aktivierung gemerkt", function()
  local ns = newClient()
  local early = ns.L.TAB_WANTED
  eq(early, "TAB_WANTED"); ok(ns.Locale.early.TAB_WANTED, "frueher Zugriff gemerkt")
  fire("ADDON_LOADED", "DeathNote")
  eq(ns.L.GIBT_ES_NICHT, "GIBT_ES_NICHT"); ok(ns.Locale.missing.GIBT_ES_NICHT)
  eq(rawget(ns.L, "GIBT_ES_NICHT"), nil, "nichts eingetragen")
end)

test("OnActivate: vorher gemeldet laeuft bei der Aktivierung, nachher sofort", function()
  local ns = newClient({ client = "deDE", db = { settings = { lang = "ruRU" } } })
  local got = {}
  ns.Locale.OnActivate(function(c) got[#got + 1] = c end)
  eq(#got, 0)
  fire("ADDON_LOADED", "DeathNote")
  eq(got[1], "ruRU")
  ns.Locale.OnActivate(function(c) got[#got + 1] = "spaet " .. c end)
  eq(got[2], "spaet ruRU")
end)

test("SetChoice und Pending: Wechsel braucht /reload, Daten bleiben ein Kennwort", function()
  local db = { settings = {} }
  local ns = newClient({ client = "deDE", db = db })
  fire("ADDON_LOADED", "DeathNote")
  eq(ns.Locale.Pending(), false)
  eq(ns.Locale.code, "deDE")
  local c, pending = ns.Locale.SetChoice("en")
  eq(c, "enUS"); eq(pending, true); eq(db.settings.lang, "enUS"); eq(db.settings.langAsked, nil, "kein Merker mehr")
  c, pending = ns.Locale.SetChoice("de")
  eq(c, "deDE"); eq(pending, false); eq(db.settings.lang, "deDE")
  eq(ns.Locale.SetChoice("klingonisch"), nil); eq(db.settings.lang, "deDE")
  c, pending = ns.Locale.SetChoice("auto")
  eq(c, "auto"); eq(pending, false, "Automatisch ergibt Deutsch"); eq(db.settings.lang, nil, "auto loescht die Wahl")
  ns.Locale.SetChoice("fr")
  c, pending = ns.Locale.SetChoice(" Auto ")
  eq(c, "auto"); eq(db.settings.lang, nil)
  -- with Store: the write goes through Store.Setting (SETTINGS_CHANGED)
  local wrote
  ns.Store = { DB = function() return db end, Setting = function(k, v) if k == "lang" then wrote = k .. "=" .. tostring(v) end; db.settings[k] = v end }
  ns.Locale.SetChoice("ruRU")
  eq(wrote, "lang=ruRU")
  ns.Locale.SetChoice("auto")
  eq(wrote, "lang=nil", "auto ueber Store.Setting")
end)

---------------------------------------------------------------------------
-- Measuring and fonts
---------------------------------------------------------------------------
test("Breite: Zeichen UTF-8-bewusst, CJK in Zellen, Farbcodes und Platzhalter", function()
  local M = Locale.Measure
  eq(M("Zu klären", "deDE"), 9)
  eq(M("Русский", "ruRU"), 7)
  eq(M("中文", "deDE"), 2); eq(M("中文", "zhCN"), 4); eq(M("한국어", "koKR"), 6); eq(M("A中", "zhTW"), 3)
  eq(M("|cffc41e3aRot|r", "deDE"), 3)
  eq(M("{name}!", "deDE"), 4)
  eq(M("{count|Tod|Tode}", "deDE"), 4)
  eq(M("ＡＢ", "zhCN"), 4, "Vollbreite")
end)

test("Schriftwahl je Sprache: jede Art fuer jede Sprache, Schrift passt zur Schrift", function()
  for _, c in ipairs(CODES) do
    for _, kind in ipairs({ "title", "hand", "head", "body", "type" }) do
      local list = Locale.FontList(kind, c)
      ok(type(list) == "table" and #list >= 1, c .. " " .. kind)
      for _, p in ipairs(list) do ok(p:match("^Fonts\\[%w_]+%.[Tt][Tt][Ff]$"), "Pfad " .. p) end
    end
  end
  eq(Locale.FontList("hand", "deDE")[1], "Fonts\\MORPHEUS.TTF", "Latein wie 1.1.0")
  eq(Locale.FontList("body", "ruRU")[1], "Fonts\\FRIZQT___CYR.TTF")
  eq(Locale.FontList("hand", "ukUA")[1], "Fonts\\MORPHEUS_CYR.TTF")
  eq(Locale.FontList("body", "koKR")[1], "Fonts\\2002.TTF")
  eq(Locale.FontList("body", "zhCN")[1], "Fonts\\ARKai_T.ttf")
  eq(Locale.FontList("body", "zhTW")[1], "Fonts\\bLEI00D.ttf")
  eq(Locale.FontList("body", "plPL")[1], "Fonts\\ARIALN.TTF")
  for _, c in ipairs({ "plPL", "csCZ", "huHU", "hrHR", "trTR" }) do
    for _, kind in ipairs({ "title", "hand", "body" }) do
      for _, p in ipairs(Locale.FontList(kind, c)) do
        ok(not p:find("MORPHEUS") and not p:find("SKURRI") and not p:find("FRIZQT__%."),
          c .. " " .. kind .. ": Zierschrift ohne belegte Abdeckung " .. p)
      end
    end
  end
end)

---------------------------------------------------------------------------
-- 1.3.0 theme words (Locales/Themes/<id>.lua) and theme names (Themes/<id>.lua, nameKey)
---------------------------------------------------------------------------
local function listDir(rel, pattern)
  local out = {}
  local p = io.popen('ls "' .. DIR .. rel .. '" 2>/dev/null')
  if p then for f in p:lines() do if f:match(pattern) then out[#out + 1] = f end end p:close() end
  table.sort(out)
  return out
end
local WORD_FILES = listDir("Locales/Themes", "^[a-z][a-z0-9_]*%.lua$")
local THEME_FILES = listDir("Themes", "^[a-z][a-z0-9_]*%.lua$")
-- reserved show keys whose base key comes later (record system): no limit in _limits.lua yet, so a stamp gets the
-- limit of STAMP_REVENGE and the tab the one of TAB_WANTED
local RESERVED_LIMIT = { STAMP_QUITT = 16, STAMP_OVERPAID = 16, TAB_RECORD = 16 }

-- a stamp's words broken greedily into lines of at most 12 characters: at most two lines (concept 11.2)
local function stampLines(v, code)
  local lines, cur = {}, nil
  for w in v:gmatch("%S+") do
    if cur and Locale.Measure(cur .. " " .. w, code) <= 12 then cur = cur .. " " .. w
    else if cur then lines[#lines + 1] = cur end; cur = w end
  end
  if cur then lines[#lines + 1] = cur end
  local long = false
  for _, l in ipairs(lines) do if Locale.Measure(l, code) > 12 then long = true end end
  return #lines, long
end

test("Theme-Woerter: Dateien da, gueltiges UTF-8, ohne Geruest kein Bruch", function()
  ok(#WORD_FILES >= 1, "keine Datei unter Locales/Themes")
  for _, f in ipairs(WORD_FILES) do
    local s = assert(readFile(DIR .. "Locales/Themes/" .. f), f)
    ok(s:sub(1, 3) ~= "\239\187\191", "BOM in " .. f)
    local good, at = validUtf8(s)
    ok(good, f .. ": kein UTF-8 ab Byte " .. tostring(at))
    local chunk = assert(loadfile(DIR .. "Locales/Themes/" .. f))
    chunk("DeathNote", {})
    chunk("DeathNote", nil)
  end
end)

for _, f in ipairs(WORD_FILES) do
  local id = f:gsub("%.lua$", "")
  test("Theme-Woerter " .. id .. ": Schauwoerter, Grenzen des Grundschluessels, Stempel 2 x 12, deDE und enUS gleich", function()
    local ns = newClient()
    assert(loadfile(DIR .. "Locales/Themes/" .. f))("DeathNote", ns)
    local L2 = ns.Locale
    local bad, sets, absent, waiting = {}, {}, {}, {}
    for _, code in ipairs(CODES) do
      local t = L2.RawWords(id, code)
      if not t then
        if code == "enUS" or code == "deDE" then bad[#bad + 1] = code .. ": keine Woerter" end
        if code ~= "enUS" and code ~= "deDE" then absent[#absent + 1] = code end
      else
        sets[code] = t
        for k, v in pairs(t) do
          if not L2.THEME_KEYS[k] then bad[#bad + 1] = code .. " " .. k .. ": kein Schauwort (Bedienwoerter wechseln nie)"
          elseif EN[k] == nil and not RESERVED_LIMIT[k] then bad[#bad + 1] = code .. " " .. k .. ": ohne englischen Grundschluessel"
          else
            if EN[k] == nil then
              if code == "enUS" then waiting[#waiting + 1] = k end
              if type(v) ~= "string" or v == "" then bad[#bad + 1] = code .. " " .. k .. ": leer"
              elseif Locale.Measure(v, code) > RESERVED_LIMIT[k] then
                bad[#bad + 1] = ("%s %s: zu lang: %d > %d"):format(code, k, Locale.Measure(v, code), RESERVED_LIMIT[k])
              end
            else
              for _, pr in ipairs(checkText(code, k, v)) do bad[#bad + 1] = code .. " " .. k .. ": " .. pr end
            end
            if k:find("^STAMP_") and type(v) == "string" then
              local n, long = stampLines(v, code)
              if n > 2 or long then bad[#bad + 1] = ("%s %s: Stempel '%s' passt nicht in 2 Zeilen zu 12 Zeichen"):format(code, k, v) end
            end
          end
        end
      end
    end
    if #absent > 0 then hint(("%s: %d Sprachen ohne Theme-Woerter (Grundwoerter der Sprache bleiben): %s"):format(id, #absent, table.concat(absent, " "))) end
    table.sort(waiting)
    if #waiting > 0 then hint(id .. ": wartet auf den Grundschluessel (Ruf-Paket), wirkt bis dahin nicht: " .. table.concat(waiting, " ")) end
    -- German and English carry the same words (the texter writes both; the other 19 may leave words out)
    if sets.enUS and sets.deDE then
      for k in pairs(sets.enUS) do if sets.deDE[k] == nil then bad[#bad + 1] = "deDE fehlt " .. k end end
      for k in pairs(sets.deDE) do if sets.enUS[k] == nil then bad[#bad + 1] = "enUS fehlt " .. k end end
    end
    table.sort(bad)
    ok(#bad == 0, "\n    " .. table.concat(bad, "\n    "))
  end)
end

test("Themes: Name in allen 21 Sprachen, Woerter-Datei und Theme-Datei in der TOC an der richtigen Stelle", function()
  local toc = readFile(DIR .. "DeathNote.toc") or ""
  local pos, n = {}, 0
  for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^#") and line:match("%S") then n = n + 1; pos[(line:gsub("/", "\\"):gsub("%s+$", ""))] = n end
  end
  local bad = {}
  local lastLang = 0
  for _, c in ipairs(CODES) do lastLang = math.max(lastLang, pos["Locales\\" .. c .. ".lua"] or 0) end
  local pTheme, pAlert = pos["Theme.lua"], pos["Alert.lua"]
  for _, f in ipairs(WORD_FILES) do
    local p = pos["Locales\\Themes\\" .. f]
    if not p then bad[#bad + 1] = "TOC ohne Locales\\Themes\\" .. f
    elseif p < lastLang or (pTheme and p > pTheme) then bad[#bad + 1] = "Locales\\Themes\\" .. f .. ": nach den Sprachen, vor Theme.lua" end
  end
  for _, f in ipairs(THEME_FILES) do
    local p = pos["Themes\\" .. f]
    if not p then bad[#bad + 1] = "TOC ohne Themes\\" .. f
    elseif (pTheme and p < pTheme) or (pAlert and p > pAlert) then bad[#bad + 1] = "Themes\\" .. f .. ": nach Theme.lua, vor Alert.lua" end
    local src = readFile(DIR .. "Themes/" .. f) or ""
    local key = src:match('nameKey%s*=%s*"([%w_]+)"')
    if not key then bad[#bad + 1] = f .. ": kein nameKey"
    else
      if EN[key] == nil then bad[#bad + 1] = f .. ": " .. key .. " fehlt in enUS" end
      for _, c in ipairs(CODES) do
        local t = Locale.Raw(c)
        if c ~= "enUS" and not (t and type(t[key]) == "string" and t[key] ~= "") then
          local s = c .. ": " .. key .. " fehlt"
          if STRICT then bad[#bad + 1] = s else hint(s) end
        end
      end
    end
    -- a theme with words names a file that exists, and the other way round
    local words = src:match('words%s*=%s*"([%w_]+)"')
    if words and not readFile(DIR .. "Locales/Themes/" .. words .. ".lua") then bad[#bad + 1] = f .. ": Locales/Themes/" .. words .. ".lua fehlt" end
  end
  for _, f in ipairs(WORD_FILES) do
    local found = false
    for _, tf in ipairs(THEME_FILES) do
      if (readFile(DIR .. "Themes/" .. tf) or ""):find('words%s*=%s*"' .. f:gsub("%.lua$", "") .. '"') then found = true end
    end
    if not found then bad[#bad + 1] = "Locales/Themes/" .. f .. ": kein Theme nennt diese Woerter" end
  end
  table.sort(bad)
  ok(#bad == 0, "\n    " .. table.concat(bad, "\n    "))
end)

---------------------------------------------------------------------------
-- TOC (B2 wires it; a hint until then, an error under STRICT)
---------------------------------------------------------------------------
test("TOC nennt Locale.lua und alle Sprachdateien in der richtigen Reihenfolge", function()
  local toc = readFile(DIR .. "DeathNote.toc") or ""
  local lines, pos = {}, {}
  for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^#") and line:match("%S") then
      lines[#lines + 1] = line:gsub("/", "\\"); pos[lines[#lines]] = #lines
    end
  end
  local problems = {}
  local pLocale, pEn, pCore = pos["Locale.lua"], pos["Locales\\enUS.lua"], pos["Core.lua"]
  if not pLocale then problems[#problems + 1] = "Locale.lua fehlt" end
  if not pEn then problems[#problems + 1] = "Locales\\enUS.lua fehlt" end
  for _, c in ipairs(CODES) do
    local p = pos["Locales\\" .. c .. ".lua"]
    if not p then problems[#problems + 1] = "Locales\\" .. c .. ".lua fehlt"
    elseif pLocale and p < pLocale then problems[#problems + 1] = c .. " vor Locale.lua"
    elseif pEn and c ~= "enUS" and p < pEn then problems[#problems + 1] = c .. " vor enUS"
    elseif pCore and p > pCore then problems[#problems + 1] = c .. " nach Core.lua" end
  end
  if pLocale and pCore and pLocale > pCore then problems[#problems + 1] = "Locale.lua nach Core.lua" end
  if #problems > 0 then
    if STRICT then error(table.concat(problems, "; ")) end
    hint("TOC noch ohne Sprachgeruest (" .. #problems .. " Punkte, B2 haengt es ein)")
  end
end)

---------------------------------------------------------------------------
io.write(("%-18s %3d ok, %d rot%s\n"):format("locales", pass, fail, STRICT and " (STRICT)" or ""))
for _, f in ipairs(failures) do io.write("  ROT: " .. f .. "\n") end
for _, h in ipairs(hints) do io.write("  Hinweis: " .. h .. "\n") end
os.exit(fail == 0 and 0 or 1)
