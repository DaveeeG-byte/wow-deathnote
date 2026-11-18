-- 1.5.0 name: what players see of the new name in the drawn interface (book title in the covers, first-start window)
-- and the one chat line after the update: once per account, never in combat, never on a new installation (that one
-- gets the first-start window, not both), and in place of the line of 1.4.0 (who never saw that one gets only this).
-- Whole addon in TOC order (helpers as in fix140_news.lua). Call from the project root: luajit tests/ui/name150.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/name150.lua"
local ADDON = DIR .. "/DeathNote"
local okN, badN = 0, 0
local current = ""
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", current, ": ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
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


local NAME = "Revenge Book"
local function news(ns) return plain(ns.L.CHAT_NEWS_150) end
local OLD140 = { deDE = "Neu in 1.4.0", enUS = "New in 1.4.0" }
local function old140()
  local n = 0
  for _, l in ipairs(AM.chat) do for _, w in pairs(OLD140) do if plain(l):find(w, 1, true) then n = n + 1 end end end
  return n
end

test("book title: Revenge Book in the black book, left of the first tab", function()
  for _, code in ipairs({ "deDE", "enUS", "ruRU", "zhCN" }) do
    local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true, lang = code }, enemies = {}, deaths = {} }
    local ns = world({ db = db, client = code })
    ns:Fire("TOGGLE_UI"); tick()
    local F = rawget(G, "DeathNoteFrame")
    local t = F and F.bookTitle
    check(code .. " title text", t and t:GetText() == NAME, t and t:GetText())
    local _, _, r = BM.RectUI(t)
    local l0 = BM.RectUI(F)
    check(code .. " title ends before the first tab", r and l0 and (r - l0) <= 184 - 8 + 0.5, r and l0 and (r - l0))
    check(code .. " title whole (no ellipsis)", t and not t.cut)
    clean()
  end
end)

test("covers keep their own title (Privateer, Workshop)", function()
  for theme, want in pairs({ harbor = "Kaperbuch", trade = "Kundenbuch" }) do
    local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true, ui = { theme = theme } },
      enemies = {}, deaths = {} }
    local ns = world({ db = db })
    ns:Fire("TOGGLE_UI"); tick()
    local t = rawget(G, "DeathNoteFrame").bookTitle
    check(theme .. " title", t and t:GetText() == want, t and t:GetText())
    clean()
  end
end)

test("first-start window: the black book is called Revenge Book", function()
  world({ db = nil })
  tick(4)
  local d = dialog()
  check("window shown", shown())
  local found = false
  for s in pairs(BM.texts or {}) do if s == NAME then found = true end end
  if not found and d and d.title then found = d.title:GetText() == NAME end
  check("title or tile names Revenge Book", found)
  clean()
end)

test("saw the line of 1.4.0: the line of 1.5.0 once", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news140 = true }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(60)
  check("one line", said(news(ns)) == 1)
  check("names the new name, the old one and /dn", news(ns):find(NAME, 1, true) and news(ns):find("DeathNote", 1, true)
    and news(ns):find("/dn", 1, true), news(ns))
  check("marker", db.settings.news150 == true)
  ns = world({ db = db }); tick(60)
  check("not again after a reload", said(news(ns)) == 0)
  clean()
end)

test("never saw the line of 1.4.0: only the line of 1.5.0, then neither", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done" }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(60)
  check("the line of 1.5.0", said(news(ns)) == 1)
  check("not the line of 1.4.0", old140() == 0)
  check("both markers (a 1.4.0 client after a downgrade stays quiet)", db.settings.news150 == true
    and db.settings.news140 == true)
  clean()
end)

test("English: the line in English", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", lang = "enUS" }, enemies = {}, deaths = {} }
  local ns = world({ db = db, client = "enUS" })
  tick(60)
  check("one line", said(news(ns)) == 1 and news(ns):find("is now Revenge Book", 1, true), news(ns))
  clean()
end)

test("in combat: waits; new installation: the window, no line", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done" }, enemies = {}, deaths = {} }
  local ns = world({ db = db, combat = true })
  tick(30)
  check("nothing in combat", said(news(ns)) == 0 and db.settings.news150 == nil)
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("after the fight, once", said(news(ns)) == 1)
  clean()
  ns = world({ db = nil })
  tick(4)
  check("new installation: the first-start window", shown())
  if dialog() and dialog().go then dialog().go._scripts.OnClick(dialog().go, "LeftButton") end
  tick(60)
  check("new installation: no news line", said(news(ns)) == 0 and old140() == 0)
  check("new installation: markers at once", _G.DeathNoteDB.settings.news150 == true and _G.DeathNoteDB.settings.news140 == true)
  clean()
end)

test("minimap tooltip and broker text: Revenge Book; the object keeps its name", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(10)
  local mm = rawget(G, "DeathNoteMinimapButton")
  if mm and mm._scripts and mm._scripts.OnEnter then
    G.GameTooltip._text = nil
    mm._scripts.OnEnter(mm)
    check("tooltip head", G.GameTooltip._text == NAME or (G.GameTooltip._lines and G.GameTooltip._lines[1] == NAME),
      G.GameTooltip._text)
  else
    check("own minimap button or library button exists", rawget(G, "LibDBIcon10_DeathNote") ~= nil)
  end
  check("TITLE", ns.TITLE == NAME and ns.Share and ns.Share.BRAND == NAME)
  clean()
end)

io.write(("name 1.5.0 UI: %d gruen, %d rot\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
