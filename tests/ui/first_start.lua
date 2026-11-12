-- 1.3.0 first start (Start.lua): the window that asks for the language and the cover on a new installation.
-- Loads the whole addon in TOC order like the client (logic files in the logic mock, the drawing files in the UI
-- mock, one ns), sets the SavedVariables before ADDON_LOADED and then plays the login.
-- Checks: only new installations, never existing ones (one chat line instead), never twice (also across a
-- downgrade to the logic of 1.2.2 and back), not in combat (and back after it), not in an instance (and back in the
-- open world), the choice takes effect without a reload (book, alarm and notice equal a client that had the choice
-- stored from the start), Esc keeps the defaults, the cover for members of the guild Humor knows (also when the
-- guild data comes late), /dn start, the texts follow the language picked in the window, something built before
-- means a reload, 1/3/6 covers wrap and stay inside the window, existing installations hold no builders.
-- Call from the project root: luajit tests/ui/first_start.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/first_start.lua"
local ADDON = DIR .. "/DeathNote"
local okN, badN = 0, 0
local current = ""
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", current, ": ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

-- the guild name Humor knows, read from its source (no name in this file)
local GUILD
do
  local f = assert(io.open(ADDON .. "/Humor.lua"))
  GUILD = f:read("*a"):match('local GUILD_NAME = "(.-)"')
  f:close()
  assert(GUILD, "guild name not found in Humor.lua")
end

local function tocFiles()
  local out = {}
  for line in io.lines(ADDON .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") and line:find("%.lua$") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end

local AM, BM, G
-- o: db (SavedVariables before the login), client (GetLocale), guild (name or false), guildLate (in a guild whose
-- name is not readable yet), combat, instance, themes (stand-in covers until there are that many), lua (only the
-- logic: the addon without its drawing files, as 1.2.2 greets)
local function world(o)
  o = o or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.Reset()
  AM.locale = o.client or "deDE"
  AM.client = o.client or "deDE"
  _G.DeathNoteDB = o.db
  AM.inCombat, BM.combat = o.combat or false, o.combat or false
  if o.instance then AM.instance = { true, "party" } end
  if o.guild then AM.units.player.guild = o.guild end
  local name = o.guild or nil
  rawset(G, "GetGuildInfo", function(u) if u == "player" and not o.guildLate then return name end end)
  rawset(G, "IsInGuild", function() return (o.guild or o.guildLate) and true or false end)
  local LOGIC = {}
  for _, f in ipairs(AM.FILES) do LOGIC[f] = true end
  local ns, ui = {}, false
  for _, f in ipairs(tocFiles()) do
    if f == "Alert.lua" then ui = true end
    if LOGIC[f] or not ui then
      assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns)
    elseif not o.logicOnly then
      BM.Load(ADDON .. "/" .. f, ns)
    end
  end
  AM.ns = ns
  if o.themes then
    local n = 0
    while #ns.Theme.List() < o.themes do
      n = n + 1
      local key = "THEME_STANDIN_" .. n
      ns.Theme.Register("standin" .. n, { order = 20 + n, nameKey = key, tex = { cover = "g_cover.tga" },
        tint = { cover = ({ "#1f3a52", "#5a3a22", "#2a2a3a", "#24344a", "#3a2a2a" })[(n - 1) % 5 + 1], paper = "#e9d7a8" } })
    end
  end
  if o.only then local only = o.only; ns.Theme.List = function() return only end end
  AM.FireEvent("ADDON_LOADED", "DeathNote")
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function dialog() return rawget(G, "DeathNoteStart") end
local function shown() local d = dialog(); return d ~= nil and d:IsShown() end
local function plain(s) return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function said(text)
  local n = 0
  for _, l in ipairs(AM.chat) do if plain(l):find(text, 1, true) then n = n + 1 end end
  return n
end
local function clean()
  check("no addon errors", #AM.errors == 0, AM.errors[1])
  check("no UI mock violations", #BM.violations == 0, BM.violations[1])
end
local function test(name, fn)
  current = name
  local ok, err = pcall(fn)
  check("runs", ok, err)
end

local tile, cell, go
do
  local function below(f, root)
    while f do if f == root then return true end f = f._parent end
    return false
  end
  function tile(id)
    for _, f in ipairs(BM.frames) do if f.id == id and f.cover and f.paper and below(f, dialog()) then return f end end
  end
  function cell(code)
    for _, f in ipairs(BM.frames) do if f.code == code and f.mark and below(f, dialog()) then return f end end
  end
  function go() return dialog().go end
end
local function click(f) f._scripts.OnClick(f, "LeftButton"); tick() end
local function esc() dialog():Hide(); tick() end   -- UISpecialFrames: Esc hides the window
local NEW = nil                                      -- no SavedVariables at all

---------------------------------------------------------------------------
test("new installation: the window 3 s after entering the world, the greeting replaced", function()
  local ns = world({ db = NEW })
  check("fresh", ns.Start.Fresh() == true)
  check("builders held", ns.Locale.Held() == true)
  check("notice not built yet", rawget(G, "DeathNoteBanner") == nil)
  tick(2.9)
  check("not before 3 s", not shown())
  tick(0.2)
  check("shown after 3 s", shown())
  check("Esc closes it (UISpecialFrames)", (function() for _, n in ipairs(G.UISpecialFrames) do if n == "DeathNoteStart" then return true end end end)())
  tick(10)
  check("no chat greeting while it asks", said(plain(ns.L.WELCOME)) == 0 and said(plain(ns.L.WELCOME_SHARE)) == 0)
  check("marker new", _G.DeathNoteDB.settings.firstRun == "new")
  esc()
  check("asked", _G.DeathNoteDB.settings.firstRun == "done")
  check("the two lines with content follow", said(plain(ns.L.WELCOME_SHARE)) == 1, said(plain(ns.L.WELCOME_SHARE)))
  check("the first greeting line stays in the window only", said(plain(ns.L.WELCOME)) == 0)
  check("the language line is gone too", said((plain(ns.L.CHAT_LANG_CURRENT):gsub("{lang}.*", ""))) == 0)
  check("welcomed", _G.DeathNoteDB.settings.welcomed == true)
  check("builders released", ns.Locale.Held() == false)
  check("notice built now", rawget(G, "DeathNoteBanner") ~= nil)
  clean()
end)

test("never for an existing installation: one chat line instead, once", function()
  local db = { version = 4, settings = { welcomed = true, lang = "deDE" }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  check("not fresh", ns.Start.Fresh() == false)
  check("builders dropped at once", ns.Locale.Held() == false and ns.Locale.Raw("frFR") == nil)
  check("notice built at READY as before", rawget(G, "DeathNoteBanner") ~= nil)
  tick(60)
  check("no window", not shown())
  check("one line about the covers", said(plain(ns.L.CHAT_THEME_NEWS)) == 1)
  check("marker done", db.settings.firstRun == "done")
  -- /reload
  ns = world({ db = db })
  tick(60)
  check("no second line after a reload", said(plain(ns.L.CHAT_THEME_NEWS)) == 0 and not shown())
  clean()
end)

test("existing installation in combat: the line waits for the end of the fight", function()
  local db = { version = 4, settings = { welcomed = true }, enemies = {}, deaths = {} }
  local ns = world({ db = db, combat = true })
  tick(20)
  check("nothing in combat", said(plain(ns.L.CHAT_THEME_NEWS)) == 0)
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("after the fight", said(plain(ns.L.CHAT_THEME_NEWS)) == 1)
  clean()
end)

test("never twice: after Go, after a reload, after a downgrade to the logic of 1.2.2 and back", function()
  local ns = world({ db = NEW })
  tick(4)
  click(go())
  local db = _G.DeathNoteDB
  check("done", db.settings.firstRun == "done" and db.settings.welcomed == true)
  ns = world({ db = db }); tick(60)
  check("no window after a reload", not shown())
  check("no greeting after a reload", said(plain(ns.L.WELCOME_SHARE)) == 0)
  -- 1.2.2 has no Start.lua: its greeting looks at welcomed only
  ns = world({ db = db, logicOnly = true }); tick(60)
  check("1.2.2 greets nobody twice", said(plain(ns.L.WELCOME)) == 0 and said(plain(ns.L.WELCOME_SHARE)) == 0)
  ns = world({ db = db }); tick(60)
  check("back on 1.3.0: no window", not shown())
  check("back on 1.3.0: no line", said(plain(ns.L.CHAT_THEME_NEWS)) == 0 and said(plain(ns.L.WELCOME_SHARE)) == 0)
  clean()
end)

test("a reload before the window came: it is still due, and comes once", function()
  local ns = world({ db = NEW, instance = true })
  tick(10)
  check("not in the instance", not shown())
  local db = _G.DeathNoteDB
  check("still due", db.settings.firstRun == "new")
  ns = world({ db = db })
  check("fresh again after the reload", ns.Start.Fresh() == true and ns.Locale.Held() == true)
  tick(4)
  check("comes after the reload", shown())
  esc()
  ns = world({ db = db }); tick(10)
  check("then never again", not shown())
  clean()
end)

test("not in combat: waits, comes after the fight; closes when a fight starts and comes back", function()
  local ns = world({ db = NEW, combat = true })
  tick(10)
  check("not in combat", not shown())
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("after the fight", shown())
  AM.inCombat, BM.combat = true, true
  AM.FireEvent("PLAYER_REGEN_DISABLED"); tick()
  check("hidden at the start of a fight", not shown())
  check("a fight is no answer", _G.DeathNoteDB.settings.firstRun == "new" and ns.Locale.Held())
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("back after the fight", shown())
  clean()
end)

test("not in an instance: comes at the next entering of the open world", function()
  local ns = world({ db = NEW, instance = true })
  tick(10)
  check("not in the instance", not shown())
  AM.instance = { false, "none" }
  AM.FireEvent("PLAYER_ENTERING_WORLD"); tick(2.9)
  check("3 s after entering again, not before", not shown())
  tick(0.2)
  check("in the open world", shown())
  check("still due", ns.Start.Holding())
  clean()
end)

test("Esc keeps the defaults, also after clicks in the window", function()
  local ns = world({ db = NEW, client = "deDE" })
  tick(4)
  click(cell("ruRU"))
  click(tile("harbor"))
  esc()
  check("language stays automatic", _G.DeathNoteDB.settings.lang == nil and ns.Locale.code == "deDE")
  check("cover stays the default", ns.Theme.id == "notebook" and _G.DeathNoteDB.settings.ui.theme == "notebook")
  check("asked", _G.DeathNoteDB.settings.firstRun == "done")
  clean()
end)

test("the window follows the language picked in it, at once", function()
  local ns = world({ db = NEW, client = "deDE" })
  tick(4)
  local d = dialog()
  check("German first", d.go.text:GetText() == "Los", d.go.text:GetText())
  click(cell("enUS"))
  check("English at once", d.go.text:GetText() == "Go", d.go.text:GetText())
  local en = ns.Locale.Text("enUS")
  check("welcome in English", d.welcome:GetText() == en.WELCOME, d.welcome:GetText())
  check("the book itself stays German until Go", ns.Locale.code == "deDE" and ns.L.START_GO == "Los")
  click(cell("ruRU"))
  local ru = ns.Locale.Text("ruRU")
  check("Russian welcome", d.welcome:GetText() == ru.WELCOME)
  check("Cyrillic font for the welcome", tostring(d.welcome._font):find("CYR") ~= nil, d.welcome._font)
  click(tile("trade"))
  check("the cover's own title in the window", d.title:GetText() == (ns.Locale.RawWords("trade", "ruRU") or {}).BOOK_TITLE
    or d.title:GetText() == ru.BOOK_TITLE)
  clean()
end)

-- the look of the book, the alarm and the notice: per top frame, element by element (kind, text, font, colours, texture)
local COLS = { "_color", "_vc", "_tc", "_bdc", "_bdb", "_shadowc" }
local function root(f)
  local r = f
  while r._parent and r._parent ~= G.UIParent do r = r._parent end
  return r._name or "?"
end
local function key(v)
  if type(v) ~= "table" then return tostring(v) end
  local out = {}
  for i = 1, 4 do out[i] = v[i] and ("%.4f"):format(v[i]) or "-" end
  return table.concat(out, ",")
end
local function looks()
  local by = {}
  for _, f in ipairs(BM.frames) do
    local r = root(f)
    if r == "DeathNoteFrame" or r == "DeathNoteAlert" or r == "DeathNoteBanner" then
      local parts = { f._kind, tostring(f._text), tostring(f._font), tostring(f._fontSize), tostring(f._tex) }
      for _, c in ipairs(COLS) do parts[#parts + 1] = key(f[c]) end
      by[r] = by[r] or {}
      by[r][#by[r] + 1] = table.concat(parts, " | ")
    end
  end
  return by
end
local function views(ns)
  ns:Fire("TOGGLE_UI"); tick(1)
  ns.UI.OpenPanel("settings"); tick(1)
  ns:Fire("TEST_ALERT"); tick(1)
  local k = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = _G.time() - 50, zone = "Z" }, true)
  local j = { t = _G.time(), kind = "pvp", sure = true, counted = true, killerKey = k, candidates = {} }
  ns.Store.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, k); tick(2)
  return looks()
end

test("Go takes effect without a reload: book, alarm and notice equal a client with the choice stored", function()
  local ns = world({ db = NEW, client = "deDE" })
  tick(4)
  click(cell("ruRU"))
  click(tile("trade"))
  click(go())
  check("language active", ns.Locale.code == "ruRU")
  check("cover active", ns.Theme.id == "trade")
  check("stored", _G.DeathNoteDB.settings.lang == "ruRU" and _G.DeathNoteDB.settings.ui.theme == "trade")
  check("no reload line", said("/reload") == 0)
  check("the book opened in the new look", rawget(G, "DeathNoteFrame") and rawget(G, "DeathNoteFrame"):IsShown())
  ns:Fire("TOGGLE_UI"); tick()
  local a = views(ns)
  local nb = world({ db = { version = 4, settings = { welcomed = true, firstRun = "done", lang = "ruRU", ui = { theme = "trade" } },
    enemies = {}, deaths = {} }, client = "deDE" })
  check("the reference client holds nothing", nb.Locale.Held() == false)
  local b = views(nb)
  for _, r in ipairs({ "DeathNoteFrame", "DeathNoteAlert", "DeathNoteBanner" }) do
    local x, y = a[r] or {}, b[r] or {}
    check(r .. " built", #x > 0, #x)
    check(r .. " same number of elements", #x == #y, #x .. " / " .. #y)
    local diff
    for i = 1, math.max(#x, #y) do if x[i] ~= y[i] then diff = i .. ": " .. tostring(x[i]) .. "  ~=  " .. tostring(y[i]); break end end
    check(r .. " same look and texts", diff == nil, diff)
  end
  clean()
end)

test("something built before Go: the choice is stored and waits for /reload", function()
  local ns = world({ db = NEW, client = "deDE" })
  ns:Fire("TEST_ALERT"); tick(1)              -- an alarm before the window
  tick(4)
  check("window there", shown())
  click(cell("enUS"))
  check("the window says reload", dialog().hint:GetText() == ns.Locale.Text("enUS").SET_LANG_RELOAD_HINT, dialog().hint:GetText())
  click(go())
  check("language not switched", ns.Locale.code == "deDE")
  check("stored for the reload", _G.DeathNoteDB.settings.lang == "enUS")
  check("reload line in the chat", said("/reload") >= 1)
  clean()
end)

test("cover for members of the guild Humor knows", function()
  local ns = world({ db = NEW, guild = GUILD }); tick(4)
  check("trade preselected", ns.Start.Shown() and tile("trade").edge[1]._color[1] == ns.Theme.Color("accentOnCover", "trade")[1])
  click(go())
  check("member gets trade", ns.Theme.id == "trade")
  ns = world({ db = NEW, guild = "Some Other Guild" }); tick(4)
  click(go())
  check("others get the default", ns.Theme.id == "notebook")
  ns = world({ db = NEW }); tick(4)
  click(go())
  check("no guild: the default", ns.Theme.id == "notebook")
end)

test("guild name readable only later: asked once more when the guild data comes", function()
  local ns = world({ db = NEW, guild = GUILD, guildLate = true }); tick(4)
  check("window not delayed", shown())
  check("default first", ns.Theme.Resolve(nil) == "notebook")
  local guildFn = function(u) if u == "player" then return GUILD end end
  rawset(G, "GetGuildInfo", guildFn)
  AM.FireEvent("PLAYER_GUILD_UPDATE"); tick()
  click(go())
  check("trade after the guild data", ns.Theme.id == "trade")
  -- a cover the player clicked stays
  ns = world({ db = NEW, guild = GUILD, guildLate = true }); tick(4)
  click(tile("harbor"))
  rawset(G, "GetGuildInfo", guildFn)
  AM.FireEvent("PLAYER_GUILD_UPDATE"); tick()
  click(go())
  check("the player's click wins", ns.Theme.id == "harbor")
  clean()
end)

test("/dn start shows the window again, out of combat; Go then waits for /reload", function()
  local db = { version = 4, settings = { welcomed = true, firstRun = "done" }, enemies = {}, deaths = {} }
  local ns = world({ db = db }); tick(10)
  check("nothing by itself", not shown())
  _G.SlashCmdList.DEATHNOTE("start"); tick()
  check("shown by /dn start", shown())
  esc()
  AM.inCombat, BM.combat = true, true
  _G.SlashCmdList.DEATHNOTE("start"); tick()
  check("not in combat", not shown())
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("after the fight", shown())
  click(tile("harbor"))
  click(go())
  check("stored", db.settings.ui.theme == "harbor")
  check("active only after /reload", ns.Theme.id == "notebook" and said("/reload") >= 1)
  clean()
end)

-- every element of the window inside it, no two texts or controls of it on each other
local function rect(f) return BM.RectUI(f) end
local function inside(ns, n)
  local d = dialog()
  local L0, B0, R0, T0 = rect(d)
  local tiles, out = 0, {}
  for _, f in ipairs(BM.frames) do
    if f.id and f.cover and f:IsVisible() then
      tiles = tiles + 1
      local l, b, r, t = rect(f)
      if l < L0 - 0.5 or r > R0 + 0.5 or b < B0 - 0.5 or t > T0 + 0.5 then out[#out + 1] = f.id end
    end
  end
  return tiles, out
end

for _, n in ipairs({ 1, 3, 6 }) do
  test(n .. " cover(s): one tile each, wrapped after three, inside the window", function()
    local ns = world({ db = NEW, themes = n, only = n == 1 and { "notebook" } or nil })
    tick(4)
    check("shown", shown())
    local want = #ns.Theme.List()
    local tiles, out = inside(ns, n)
    check("one tile per cover", tiles == want, tiles .. " / " .. want)
    check("all inside the window", #out == 0, table.concat(out, ","))
    local d = dialog()
    local rows = math.ceil(want / 3)
    local t1, tl = tile(ns.Theme.List()[1]), tile(ns.Theme.List()[want])
    local _, _, _, top1 = rect(t1)
    local _, _, _, topL = rect(tl)
    check("rows", (rows == 1 and top1 == topL) or (rows > 1 and topL < top1), rows)
    check("window not taller than the smallest screen", d:GetHeight() <= 640, d:GetHeight())
    clean()
  end)
end

io.write(("first_start        %d ok, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
