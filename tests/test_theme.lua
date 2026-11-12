-- 1.3.0 theme core (Theme.lua, Themes/<id>.lua): schema, choice, silent fallback, /dn theme, the theme words.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local DIR = M.ADDON_DIR

local function slash(msg) _G.SlashCmdList.DEATHNOTE(msg) end
-- a client with the test theme "probe" (tests/ui/theme_probe.lua) registered before the language is built
local function withProbe(opts)
  local saved, files = M.FILES, {}
  for _, f in ipairs(M.FILES) do
    files[#files + 1] = f
    if f == "Themes/notebook.lua" then files[#files + 1] = "../tests/ui/theme_probe.lua" end
  end
  M.FILES = files
  local ok2, ns = pcall(M.Load, opts)
  M.FILES = saved
  assert(ok2, ns)
  return ns
end
local function read(p) local f = io.open(p, "rb"); if not f then return nil end local s = f:read("*a"); f:close(); return s end

---------------------------------------------------------------------------
-- Schema: every theme has the values of the base theme, nothing unknown, files that exist
---------------------------------------------------------------------------
local function problems(T, id)
  local d, base, out = T.Get(id), T.Get(T.BASE), {}
  local function bad(s) out[#out + 1] = s end
  for k, v in pairs(d) do
    local want = T.FIELDS[k]
    if not want then bad("unknown field " .. tostring(k))
    elseif type(v) ~= want then bad(("field %s: %s instead of %s"):format(k, type(v), want)) end
  end
  local function set(list) local s = {} for _, x in ipairs(list) do s[x] = true end return s end
  local function part(name, list, kind)
    local known = set(list)
    for k, v in pairs(d[name] or {}) do
      if not known[k] then bad(name .. "." .. tostring(k) .. ": unknown") end
      if kind == "color" and not T.ParseColor(v) then bad(name .. "." .. k .. ": no colour") end
      if kind == "number" and type(v) ~= "number" then bad(name .. "." .. k .. ": no number") end
      if kind == "kind" and not T.FONT_KINDS[v] then bad(name .. "." .. k .. ": unknown font kind " .. tostring(v)) end
      if kind == "file" then
        if type(v) ~= "string" then bad(name .. "." .. k .. ": no file")
        elseif not v:find("^Interface\\") and not read(DIR .. "Media/" .. v) then bad(name .. "." .. k .. ": missing Media/" .. v) end
      end
    end
  end
  part("color", T.COLORS, "color"); part("tint", T.TINTS, "color"); part("fallback", T.FALLBACKS, "color")
  part("tex", T.TEXTURES, "file"); part("font", T.FONTS, "kind"); part("tone", T.TONES, "number")
  for _, sub in ipairs({ "baked", "blank" }) do
    if d.stamp and d.stamp[sub] ~= nil then
      local saved = d[sub]; d["stamp_" .. sub] = d.stamp[sub]
      part("stamp_" .. sub, T.STAMPS, "file")
      d["stamp_" .. sub] = nil; d[sub] = saved
    end
  end
  for k in pairs(d.stamp or {}) do if k ~= "baked" and k ~= "blank" then bad("stamp." .. tostring(k) .. ": unknown") end end
  -- the base theme is complete (every other theme may leave values out: they come from the base)
  if id == T.BASE then
    for _, pair in ipairs({ { "color", T.COLORS }, { "tex", T.TEXTURES }, { "fallback", T.FALLBACKS }, { "font", T.FONTS },
                            { "tone", T.TONES } }) do
      for _, k in ipairs(pair[2]) do if (base[pair[1]] or {})[k] == nil then bad(pair[1] .. "." .. k .. ": missing in the base theme") end end
    end
    for _, k in ipairs(T.STAMPS) do if not (base.stamp.blank or {})[k] then bad("stamp.blank." .. k .. ": missing in the base theme") end end
  end
  return out
end

test("Base theme notebook: registered, complete, no unknown value, every file there", function()
  local ns = M.Load()
  local T = ns.Theme
  ok(T.Known("notebook"))
  eq(T.List()[1], "notebook")
  local p = problems(T, "notebook")
  eq(#p, 0, table.concat(p, "; "))
end)

test("Every registered theme against the schema (also the probe of the tests)", function()
  local ns = withProbe()
  local T = ns.Theme
  for _, id in ipairs(T.List()) do
    local p = problems(T, id)
    eq(#p, 0, id .. ": " .. table.concat(p, "; "))
  end
  -- red probe of the checker: an unknown colour role and a missing file are found
  T.Register("broken", { color = { inkk = { 0, 0, 0 } }, tex = { paper = "no_such_file.tga" } })
  eq(#problems(T, "broken"), 2)
end)

test("Media: every <id>_*.tga belongs to a registered theme that names it", function()
  local ns = M.Load()
  local T = ns.Theme
  local named = {}
  for _, id in ipairs(T.List()) do
    local d = T.Get(id)
    for _, f in pairs(d.tex or {}) do named[f] = true end
    for _, sub in ipairs({ "baked", "blank" }) do for _, f in pairs((d.stamp or {})[sub] or {}) do named[f] = true end end
  end
  local p = io.popen('ls "' .. DIR .. 'Media"')
  local orphans = {}
  for f in p:lines() do
    local prefix = f:match("^(%l+)_.*%.tga$")
    if prefix and T.Known(prefix) and not named[f] then orphans[#orphans + 1] = f end
  end
  p:close()
  eq(#orphans, 0, table.concat(orphans, ", "))
end)

---------------------------------------------------------------------------
-- Choice and silent fallback
---------------------------------------------------------------------------
test("No choice, unknown, broken or missing theme: silently the black book", function()
  for _, v in ipairs({ false, "seas", "no such theme", 42, "", { "x" }, "NOTEBOOK" }) do
    local db = { settings = { ui = { theme = v ~= false and v or nil } } }
    local ns = M.Load({ db = db })
    eq(ns.Theme.id, "notebook", tostring(v))
    eq(#M.errors, 0, tostring(v) .. ": " .. tostring(M.errors[1]))
  end
  -- also without a settings table and with a broken one
  for _, db in ipairs({ {}, { settings = "x" }, { settings = { ui = "x" } } }) do
    local ns = M.Load({ db = db })
    eq(ns.Theme.id, "notebook")
  end
end)

test("Stored choice of a registered theme is activated; Look is filled in place", function()
  local ns = withProbe({ db = { settings = { ui = { theme = "probe" } } } })
  eq(ns.Theme.id, "probe")
  eq(ns.Theme.Id(), "probe")
  no(ns.Theme.Pending())
end)

test("Theme.Fill keeps every Look table (file-level references see the active theme)", function()
  local ns = withProbe()
  local T, Look = ns.Theme, {}
  T.Fill(Look)
  local ink, tex, tone, font, stamp1 = Look.INK, Look.TEX, Look.TONE, Look.FONT, Look.STAMP_INK[1]
  eq(Look.COLOR.ink, ink)
  T.active = "probe"
  T.Fill(Look)
  eq(Look.INK, ink); eq(Look.TEX, tex); eq(Look.TONE, tone); eq(Look.FONT, font); eq(Look.STAMP_INK[1], stamp1)
  eq(Look.COLOR.stampInk, stamp1)
  ok(math.abs(Look.INK[1] - 0.501) < 1e-9, "ink of the probe: " .. tostring(Look.INK[1]))
  eq(Look.FONT_KIND.head, "body")
  eq(Look.TONE.ink, 0.99)
  -- the probe has no own stamp table entries beyond baked/blank: its baked pictures are its own
  eq(Look.STAMP_BAKED.nr1, Look.MEDIA and (Look.MEDIA .. "stamp_rache.tga") or Look.STAMP_BAKED.nr1)
  -- a theme without baked pictures shows the frame plus text in German too (no German picture of another theme)
  T.Register("plain", { color = { ink = "#102030" } })
  T.active = "plain"
  T.Fill(Look)
  eq(Look.STAMP_BAKED.nr1, nil)
  ok(Look.STAMP_BLANK.nr1:find("stamp_nr1_blank.tga", 1, true))
  ok(math.abs(Look.INK[1] - 0x10 / 255) < 1e-9)
  ok(math.abs(Look.RED[1] - 0.72) < 1e-9, "missing value from the base theme")
  eq(Look.HEX.ink, "|cff102030")
end)

test("Hex: the same codes as before 1.3.0 (cut, not rounded)", function()
  local ns = M.Load()
  local H = ns.Theme.Hex
  eq(H({ 1.0, 0.40, 0.33 }), "|cffff6654")
  eq(H({ 0.93, 0.90, 0.82 }), "|cffede5d1")
  eq(H({ 1.0, 0.62, 0.18 }), "|cffff9e2d")
  eq(H(ns.Theme.ParseColor("#e03020")), "|cffe03020")
end)

---------------------------------------------------------------------------
-- /dn theme
---------------------------------------------------------------------------
test("/dn theme: shows the cover and the list; /dn theme <id> stores it, after /reload", function()
  local ns = withProbe()
  M.chat = {}
  slash("theme")
  ok(M.chat[#M.chat - 1]:find("Einband jetzt: Das schwarze Buch (notebook)", 1, true), M.chat[#M.chat - 1])
  ok(M.chat[#M.chat]:find("notebook", 1, true) and M.chat[#M.chat]:find("probe", 1, true), M.chat[#M.chat])
  slash("theme probe")
  ok(M.chat[#M.chat]:find("Gilt nach /reload", 1, true), M.chat[#M.chat])
  eq(ns.Store.DB().settings.ui.theme, "probe")
  ok(ns.Theme.Pending())
  eq(ns.Theme.id, "notebook")      -- the active one stays until /reload
  slash("einband  NOTEBOOK ")
  ok(M.chat[#M.chat]:find("Einband: Das schwarze Buch (notebook).", 1, true), M.chat[#M.chat])
  no(ns.Theme.Pending())
  slash("theme harbour")
  ok(M.chat[#M.chat - 1]:find("Unbekannter Einband: harbour", 1, true), M.chat[#M.chat - 1])
  eq(ns.Store.DB().settings.ui.theme, "notebook")
end)

test("Store: ui.theme defaults to notebook, a broken value is repaired", function()
  local ns = M.Load({ db = { settings = { ui = { theme = 7 } } } })
  eq(ns.Store.DB().settings.ui.theme, "notebook")
  eq(ns.Theme.id, "notebook")
end)

---------------------------------------------------------------------------
-- Theme words: the third layer of the text table
---------------------------------------------------------------------------
test("Theme words: show keys only, the base word of the same language as fallback, no mixing", function()
  local saved = M.locale
  -- German with the probe: every show key is the probe's, control words stay
  M.locale = "deDE"
  local ns = withProbe({ db = { settings = { ui = { theme = "probe" } } } })
  eq(ns.L.POSTER_HEAD, "ZZHEAD"); eq(ns.L.BOOK_TITLE, "ZZTITLE"); eq(ns.L.TAB_WANTED, "ZZ TAB_WANTED")
  eq(ns.L.BOUNTY_GOLD, "ZZ {count} BG")
  ok(ns.L.ACT_STRIKE ~= nil and not tostring(ns.L.ACT_STRIKE):find("ZZ"), "control word")
  ok(ns.Locale.themeWords >= 30, ns.Locale.themeWords)
  -- the builders of the theme words are gone after activation
  no(ns.Locale.RegisterWords("probe", "deDE", function() end))
  eq(ns.Locale.RawWords("probe", "deDE"), nil)
  M.locale = saved
end)

test("Theme words: a theme with words only in English leaves Polish on the Polish base words", function()
  local saved = M.locale
  M.locale = "plPL"
  local files = {}
  for _, f in ipairs(M.FILES) do files[#files + 1] = f end
  -- a tiny theme file: words in enUS and deDE only, one non-show key, one unknown key, one empty word
  local rel = "../tests/.tiny_theme_tmp.lua"           -- paths of M.FILES are relative to DeathNote/
  local tmp = DIR .. rel
  local h = assert(io.open(tmp, "w"))
  h:write([[
local _, ns = ...
ns.Theme.Register("tiny", { words = "tiny" })
ns.Locale.RegisterWords("tiny", "enUS", function(T) T.TAB_WANTED = "Bounties"; T.ACT_STRIKE = "X"; T.NO_SUCH_KEY = "Y" end)
ns.Locale.RegisterWords("tiny", "deDE", function(T) T.TAB_WANTED = "Kopfgelder"; T.HEAD_RULES = "" end)
]])
  h:close()
  local saved2 = M.FILES
  M.FILES = files
  local after = 1
  for i, f in ipairs(M.FILES) do if f == "Themes/notebook.lua" then after = i + 1 end end
  table.insert(M.FILES, after, rel)   -- after Themes/notebook.lua
  local ok2, ns = pcall(M.Load, { db = { settings = { ui = { theme = "tiny" } } } })
  M.FILES = saved2
  os.remove(tmp)
  ok(ok2, ns)
  eq(ns.Theme.id, "tiny")
  ok(ns.L.TAB_WANTED ~= "Bounties", "no English theme word in Polish: " .. tostring(ns.L.TAB_WANTED))
  local plWord = read(DIR .. "Locales/plPL.lua"):match('\nL%.TAB_WANTED%s*=%s*"([^"]*)"')
  eq(ns.L.TAB_WANTED, plWord)                   -- the Polish base word of the black book
  eq(ns.Locale.themeWords, 0)
  M.locale = "enUS"
  M.FILES = files
  h = assert(io.open(tmp, "w"))
  h:write([[
local _, ns = ...
ns.Theme.Register("tiny", { words = "tiny" })
ns.Locale.RegisterWords("tiny", "enUS", function(T) T.TAB_WANTED = "Bounties"; T.ACT_STRIKE = "X"; T.NO_SUCH_KEY = "Y"; T.HEAD_RULES = "" end)
]])
  h:close()
  table.insert(M.FILES, after, rel)
  ok2, ns = pcall(M.Load, { db = { settings = { ui = { theme = "tiny" } } } })
  M.FILES = saved2
  os.remove(tmp)
  ok(ok2, ns)
  eq(ns.L.TAB_WANTED, "Bounties")
  eq(ns.L.ACT_STRIKE, "Strike")                 -- control word: never from a theme
  eq(ns.L.HEAD_RULES, "House Rules")            -- empty word: the base word stays
  eq(rawget(ns.L, "NO_SUCH_KEY"), nil)          -- unknown key: not taken
  M.locale = saved
end)

---------------------------------------------------------------------------
-- The themes of 1.3.0: harbor (Privateer's Ledger) and trade (The Workshop)
---------------------------------------------------------------------------
test("harbor and trade: stored choice activates the theme, its files, tints and words", function()
  local saved = M.locale
  M.locale = "deDE"
  for id, want in pairs({ harbor = { "Kaperbuch", "harbor_dagger.tga", "KIELGEHOLT" }, trade = { "Kundenbuch", "trade_clamp.tga", "AUFTRAG ERLEDIGT" } }) do
    local ns = M.Load({ db = { settings = { ui = { theme = id } } } })
    eq(ns.Theme.id, id)
    eq(#M.errors, 0, tostring(M.errors[1]))
    eq(ns.L.BOOK_TITLE, want[1])
    eq(ns.L.STAMP_REVENGE, want[3])
    eq(ns.L.ACT_STRIKE, "Streichen")                        -- control word: the same in every theme
    local Look = { MEDIA = "Interface\\AddOns\\DeathNote\\Media\\" }    -- the logic world has no ns.Look
    ns.Theme.Fill(Look)
    ok(Look.TEX.pin:find(want[2], 1, true), Look.TEX.pin)
    ok(Look.TEX.cover:find("g_cover.tga", 1, true), Look.TEX.cover)
    ok(Look.TINT.cover and Look.TINT.page and Look.TINT.paper and Look.TINT.stamp, "tints")
    -- no German picture with burnt-in text: frame plus the theme's word also in German
    eq(Look.STAMP_BAKED.rache, nil)
    ok(Look.STAMP_BLANK.rache:find(id .. "_stamp_rache.tga", 1, true), Look.STAMP_BLANK.rache)
    eq(Look.THEME_SOUND, "glocke")
  end
  M.locale = saved
end)

-- every language has theme words since the translations of 1.3.0: the gap is made here, by loading without
-- the two word files (a later language, or a theme somebody adds, starts exactly like this)
test("harbor and trade in a language without theme words (frFR, ruRU, plPL): only that language's own words", function()
  local saved = M.locale
  for _, code in ipairs({ "frFR", "ruRU", "plPL" }) do
    M.locale = code
    local base = M.Load({ db = { settings = { ui = { theme = "notebook" } } } })
    local words = {}
    for k in pairs(base.Locale.THEME_KEYS) do words[k] = rawget(base.L, k) end
    local bare = {}
    for _, f in ipairs(M.Files()) do if not f:find("^Locales/Themes/") then bare[#bare + 1] = f end end
    for _, id in ipairs({ "harbor", "trade" }) do
      local ns = M.Load({ db = { settings = { ui = { theme = id } } }, files = bare })
      eq(ns.Theme.id, id, code)
      for k, w in pairs(words) do eq(rawget(ns.L, k), w, code .. " " .. id .. " " .. k) end
      eq(ns.Locale.themeWords, 0, code .. " " .. id)
    end
  end
  M.locale = saved
end)

M.done("test_theme")
