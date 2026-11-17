-- 1.4.0 fixer (hunt UI 4): players who had the book before get one chat line after the update to 1.4.0 (what is
-- new and where: /dn rachsucht, the House Rules, "Copy all" under Guild & Friends, the filter under Wanted), once per
-- account, never in combat; a new installation never gets it. The grudge notice's tooltip says how to turn it off,
-- in the words of the active cover. Whole addon in TOC order (helpers as in first_start.lua).
-- Call from the project root: luajit tests/ui/fix140_news.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/fix140_news.lua"
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


local function news(ns)
  local L = ns.L
  return plain(ns.F(L.CHAT_NEWS_140, { rules = L.HEAD_RULES, sheet = L.SHEET_RECORD, guild = L.TAB_GUILD_FRIENDS,
    wanted = L.TAB_WANTED, takeall = L.ACT_TAKE_ALL }))
end

test("existing installation: one line after the update, then never again", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done" }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(3)
  check("not at once", said(news(ns)) == 0)
  tick(60)
  check("one line", said(news(ns)) == 1, AM.chat[#AM.chat])
  local line = news(ns)
  check("placeholders filled", not line:find("{", 1, true))
  check("names the command, the House Rules, the button and both tabs", line:find("/dn rachsucht", 1, true)
    and line:find(ns.L.HEAD_RULES, 1, true) and line:find(ns.L.ACT_TAKE_ALL, 1, true)
    and line:find(ns.L.TAB_GUILD_FRIENDS, 1, true) and line:find(ns.L.TAB_WANTED, 1, true), line)
  check("marker", db.settings.news140 == true)
  ns = world({ db = db }); tick(60)
  check("no second line after a reload", said(news(ns)) == 0)
  clean()
end)

test("existing installation from before 1.3.0: the cover line and the news line", function()
  local db = { version = 4, settings = { welcomed = true }, enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(60)
  check("cover line", said(plain(ns.L.CHAT_THEME_NEWS)) == 1)
  check("news line", said(news(ns)) == 1)
  clean()
end)

test("in combat: the line waits for the end of the fight", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done" }, enemies = {}, deaths = {} }
  local ns = world({ db = db, combat = true })
  tick(30)
  check("nothing in combat", said(news(ns)) == 0 and db.settings.news140 == nil)
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("after the fight", said(news(ns)) == 1)
  clean()
end)

test("new installation: no news line, not even after a reload", function()
  local ns = world({ db = nil })
  tick(4)
  if dialog() and dialog().go then dialog().go._scripts.OnClick(dialog().go, "LeftButton") end
  tick(60)
  check("no line", said(news(ns)) == 0)
  local db = _G.DeathNoteDB
  check("marker set at once", db.settings.news140 == true)
  ns = world({ db = db }); tick(60)
  check("no line after a reload", said(news(ns)) == 0)
  clean()
end)

test("English: the line names /dn grudge", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", lang = "enUS" }, enemies = {}, deaths = {} }
  local ns = world({ db = db, client = "enUS" })
  tick(60)
  check("one line with /dn grudge", said(news(ns)) == 1 and news(ns):find("/dn grudge", 1, true))
  clean()
end)

test("the notice's tooltip: how to turn it off, in the words of the cover", function()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news140 = true, ui = { theme = "harbor" } },
    enemies = {}, deaths = {} }
  local ns = world({ db = db })
  tick(10)
  local card = ns.GrudgeCard.Build()
  local lines = {}
  local tip = G.GameTooltip
  local oldSet, oldAdd = tip.SetText, tip.AddLine
  tip.SetText = function(self, t, ...) lines[#lines + 1] = t; return oldSet(self, t, ...) end
  tip.AddLine = function(self, t, ...) lines[#lines + 1] = t; return oldAdd(self, t, ...) end
  card._scripts.OnEnter(card)
  tip.SetText, tip.AddLine = oldSet, oldAdd
  local last = lines[#lines] or ""
  check("last line: turn it off", last:find("/dn rachsucht", 1, true) and last:find(ns.L.HEAD_RULES, 1, true)
    and last:find(ns.L.SHEET_RECORD, 1, true), last)
  check("the cover's word for the House Rules", ns.L.HEAD_RULES ~= "Hausordnung", ns.L.HEAD_RULES)
  clean()
end)

io.write(("fix140 news UI: %d gruen, %d rot\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
