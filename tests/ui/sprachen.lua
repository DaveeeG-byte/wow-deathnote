-- 1.2.0 multiple languages, UI with real logic (like integration.lua):
--  A) Language on first start: the client's (no dialog), combat, second login, aliases, stored
--     choice, /dn lang auto, upgrade from 1.1.0 with the fixture.
--  B) Build the book once in each of the 21 languages (all tabs, poster, house rules with all
--     sheets, manual, save/load, hit list, alarm, messages): red on
--     Lua errors, violations of the strict mock, missing keys or keys read too early.
--  C) Full run in English: no German word in any text set, English wording.
-- Usage: luajit tests/ui/sprachen.lua [only-this-code]
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local root = here .. "/../.."
local DIR = root .. "/DeathNote"
local ONLY = arg[1]

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end

-- fresh world: logic mock plus strict UI mock (Alert/UI/Extras), shared ns
local AM, BM, G
local function world(opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = DIR .. "/Media"
  G = BM.G
  AM.locale = opts.locale or "deDE"
  AM.client = opts.client
  local ns = AM.Load({ noLogin = true, lang = opts.lang, db = opts.db, before = function()
    AM.units.player.guild = opts.guild ~= false and "Die Wurstbrueder" or nil
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
  -- 1.2.0 (bau-d): Humor.lua is part of the addon; it only acts in German and English
  local hf = io.open(DIR .. "/Humor.lua", "r")
  if hf then hf:close(); BM.Load(DIR .. "/Humor.lua", ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function settle() AM.Advance(0.1); BM.Advance(0.1) end
local function clean(name, ns)
  check(name .. ": keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  check(name .. ": keine Verstoesse", #BM.violations == 0, BM.violations[#BM.violations])
  if ns and ns.Locale then
    check(name .. ": keine fehlenden Schluessel", next(ns.Locale.missing) == nil, next(ns.Locale.missing))
    check(name .. ": nichts vor der Aktivierung gelesen", next(ns.Locale.early) == nil, next(ns.Locale.early))
  end
end
local function chatHas(needle)
  for _, l in ipairs(AM.chat) do if l:find(needle, 1, true) then return true end end
  return false
end
local function dialog() return rawget(G, "DeathNoteLangDialog") end

------------------------------------------------------------------------
-- A) Language on first start: the client's, no dialog (addendum 3)
------------------------------------------------------------------------
do
  local ns = world({ lang = false, client = "deDE" })
  check("frisch, deutscher Client: Deutsch aktiv", ns.Locale.code == "deDE", ns.Locale.code)
  check("frisch: nichts gespeichert", ns.Store.Setting("lang") == nil)
  AM.Advance(4); settle()
  check("frisch: Begruessung erst nach 5 s", not chatHas("Das Buch liegt bereit."))
  AM.Advance(2); settle()
  check("frisch: Begruessung deutsch", chatHas("Das Buch liegt bereit."))
  check("frisch: am Ende der Satz zur Sprache", chatHas("Deutsch (deDE)") and chatHas("/dn sprache"))
  check("frisch: kein Dialog-Fenster", dialog() == nil and ns.LangDialog == nil)
  clean("frisch deutsch", ns)
  local saved = _G.DeathNoteDB
  AM.chat = {}
  ns = world({ lang = false, client = "deDE", db = saved })
  AM.Advance(6); settle()
  check("zweiter Login: Deutsch, keine zweite Begruessung", ns.Locale.code == "deDE" and not chatHas("Das Buch liegt bereit."))
end

do -- combat at login: the greeting waits for the end of combat
  local ns = world({ lang = false, client = "frFR", locale = "frFR" })
  check("frFR-Client: Franzoesisch", ns.Locale.code == "frFR", ns.Locale.code)
  AM.inCombat, BM.combat = true, true
  AM.Advance(6); settle()
  local n0 = #AM.chat
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); settle()
  check("Kampfende: Begruessung kommt", #AM.chat > n0)
  check("Kampf: kein Dialog-Fenster", dialog() == nil)
  clean("Kampf", ns)
end

for client, want in pairs({ enGB = "enUS", esMX = "esES", ptPT = "ptBR", svSE = "enUS", xxXX = "enUS" }) do
  local ns = world({ lang = false, client = client, locale = want ~= "enUS" and want or nil })
  check("Client " .. client .. ": " .. want, ns.Locale.code == want, ns.Locale.code)
end

do -- the stored choice wins; Automatic clears it
  local ns = world({ lang = false, client = "deDE", locale = "plPL", db = { settings = { lang = "plPL" } } })
  check("gespeicherte Wahl gewinnt gegen die Client-Sprache", ns.Locale.code == "plPL", ns.Locale.code)
  ns.HandleSlash("lang auto"); settle()
  check("/dn lang auto: Wahl geloescht, Deutsch nach dem Neuladen", ns.Store.Setting("lang") == nil and ns.Locale.Pending() == true)
  clean("Wahl", ns)
end

do -- upgrade from 1.1.0 (fixture), German client: stays German, no window, no second greeting
  local f = assert(loadfile(root .. "/tests/fixtures/sv_1.0.1_autor.lua"))
  local env = {}
  setfenv(f, env); f()
  local ns = world({ lang = false, client = "deDE", db = env.DeathNoteDB })
  AM.chat = {}
  AM.Advance(6); settle()
  check("Upgrade: Deutsch", ns.Locale.code == "deDE", ns.Locale.code)
  check("Upgrade: kein Fenster", dialog() == nil)
  check("Upgrade: nichts gespeichert", ns.Store.Setting("lang") == nil)
  clean("Upgrade", ns)
end

------------------------------------------------------------------------
-- B) The book in every language
------------------------------------------------------------------------
local function drive(ns, code)
  local name = "Buch " .. code
  ns:Fire("TOGGLE_UI"); settle()
  check(name .. ": Fenster offen", G.DeathNoteFrame and G.DeathNoteFrame:IsShown())
  local key = ns.Store.AddManual("Grimm", "Bart")
  ns.Store.AddManual("Zweiter", "Feind")
  ns.Store.SetNote(key, "x")
  ns.Store.AddRevenge(key)
  settle()
  ns.UI.ShowEnemy(key); settle()
  for _, id in ipairs({ "wanted", "open", "journal", "guild", "wanted" }) do
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
    end
    settle()
  end
  if ns.UI.SetGuildView then
    for _, v in ipairs({ "hunt", "enemy", "member" }) do pcall(ns.UI.SetGuildView, v); settle() end
  end
  -- right click menu of a row, search, sources, post sheet, confirmation
  for _, f in ipairs(BM.frames) do
    if f.item and f._scripts and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "RightButton"); break end
  end
  settle()
  if ns.UI.SetGuildSource then for _, src in ipairs({ "guild", "friends", "all" }) do ns.UI.SetGuildSource(src); settle() end end
  local box = rawget(G, "DeathNoteFrame") and nil
  for _, f in ipairs(BM.frames) do
    if f._kind == "EditBox" and f._scripts and f._scripts.OnEnterPressed and f.ph then box = f; break end
  end
  if box then box:SetText("Niemand"); box._scripts.OnEnterPressed(box); settle(); ns.UI.ClearSearch(); settle() end
  if ns.UI.OpenRelease then ns.UI.OpenRelease(key); settle(); ns.UI.ClosePanel(); settle() end
  if ns.UI.ConfirmDelete then ns.UI.ConfirmDelete(key); settle() end
  -- every mouse-over spot once (tooltips of all buttons, rows, poster fields, minimap button)
  for _, f in ipairs(BM.frames) do
    if f._scripts and f._scripts.OnEnter and f:IsVisible() and f ~= rawget(G, "DeathNoteLangDialog") then
      pcall(f._scripts.OnEnter, f)
      if f._scripts.OnLeave then pcall(f._scripts.OnLeave, f) end
    end
  end
  settle()
  ns.UI.OpenPanel("settings"); settle()
  -- click every sheet of the house rules once (word tabs under the head)
  local sheets = {}
  for _, k in ipairs({ "SHEET_BOOK", "SHEET_ALERT", "SHEET_GUILD" }) do sheets[rawget(ns.L, k) or ""] = true end
  for _, f in ipairs(BM.frames) do
    local fs = f.text or f.label
    local t = fs and fs.GetText and fs:GetText()
    if t and sheets[t] and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); settle() end
  end
  ns.UI.OpenPanel("help"); settle()
  ns.UI.OpenIO("export"); settle()
  ns.UI.OpenIO("import"); settle()
  ns.UI.ClosePanel(); settle()
  if ns.UI.ShowHunts then pcall(ns.UI.ShowHunts); settle() end
  ns:Fire("TEST_ALERT"); settle()
  BM.Advance(13); BM.FinishAnims()
  ns:Fire("DEATH_RECORDED", { t = _G.time(), kind = "pvp", sure = true, candidates = { key } }, key); settle()
  ns:Fire("REVENGE", key); settle()
  BM.Advance(6); BM.FinishAnims()
  local gk = ns.Guild and ns.Guild.List and ns.Guild.List("rank")
  ns:Fire("GUILD_KILL", { t = _G.time(), zone = "Zone", victim = "Hans Wurst" }, "Grimm-Bart"); settle()
  BM.Advance(6); BM.FinishAnims()
  ns:Fire("REVENGE", key); settle()
  do -- stamp of the revenge message: German as an image, otherwise an empty frame plus text in the language
    local b = rawget(G, "DeathNoteBanner")
    local tex = b and b.stamp and tostring(b.stamp._tex or "")
    if code == "deDE" then
      check(name .. ": Stempel als Bild", tex:find("stamp_rache.tga", 1, true) and not b.stampText:IsShown(), tex)
    else
      check(name .. ": Stempel leer plus Text", tex:find("stamp_rache_blank.tga", 1, true) and b.stampText:IsShown()
        and b.stampText:GetText() == ns.L.STAMP_REVENGE, tex)
    end
    check(name .. ": Meldungskopf gesperrt", b and (b.kicker:GetText() or ""):find(" ", 1, true) ~= nil
      or code == "koKR" or code == "zhCN" or code == "zhTW", b and b.kicker:GetText())
  end
  ns:Fire("DEATH_RECORDED", { t = _G.time(), kind = "pvp", sure = false, candidates = { key, "Zweiter-Feind" } }); settle()
  BM.Advance(6); BM.FinishAnims()
  local tt = G.GameTooltip
  tt._unitName, tt._unit, tt._lines = "Grimm", "target", {}
  if BM.tooltipHook then BM.tooltipHook(tt, {}) end
  _G.SlashCmdList.DEATHNOTE("help")
  _G.SlashCmdList.DEATHNOTE("gilde")
  _G.SlashCmdList.DEATHNOTE("freunde")
  ns:Fire("TOGGLE_UI"); settle()
  clean(name, ns)
end

local codes = {}
do
  local probe = world({ lang = "enUS" })
  for _, c in ipairs(probe.Locale.CODES) do if not ONLY or ONLY == c then codes[#codes + 1] = c end end
end
for _, code in ipairs(codes) do
  local ns = world({ locale = code })
  check("Sprache aktiv: " .. code, ns.Locale.code == code, ns.Locale.code)
  for _, kind in ipairs({ "title", "hand", "body", "type" }) do
    check(code .. ": Schrift " .. kind .. " je Schriftsystem", ns.Look.FONT[kind][1] == ns.Locale.FontList(kind, code)[1],
      ns.Look.FONT[kind][1])
  end
  drive(ns, code)
  -- C) English: no German word, English wording
  if code == "enUS" then
    local german, banned = {}, {}
    local GERMAN = { "Buch", "Gilde", "Täter", "Kollege", "Freunde", "Hausordnung", "Abschussliste", "Rache", "Notiz",
      "gesehen", "getötet", "nicht", "und", "keine", "vor ", "Klick", "Rechtsklick", "Stempel" }
    local BANNED_EN = { "Notebook", "Murderer", "Member", "Delete", "Enemies", "Enemy list", "Wanted list",
      "Kill list", "Accomplice" }
    local function scan(t)
      t = t:gsub("Die Fachkräfte", "")   -- guild name (Humor.lua), stays German in every language
      for _, u in ipairs({ "Ä", "Ö", "Ü", "ä", "ö", "ü", "ß" }) do
        if t:find(u, 1, true) then german[#german + 1] = t; break end
      end
      for _, w in ipairs(GERMAN) do
        if t:find("%f[%a]" .. w .. "%f[%A]") and not t:find("Die Wurstbrueder", 1, true) then german[#german + 1] = t; break end
      end
      local low = t:gsub("{[^{}]*}", ""):lower()      -- placeholder names do not count
      for _, w in ipairs(BANNED_EN) do
        if low:find("%f[%a]" .. w:lower() .. "%f[%A]") then banned[#banned + 1] = t end
      end
    end
    for t in pairs(BM.texts) do scan(t) end
    for _, v in pairs(ns.L) do if type(v) == "string" then scan(v) end end   -- also texts the run does not show
    for _, l in ipairs(AM.chat) do scan(l) end
    check("Englisch: kein deutsches Wort in gesetzten Texten und Chat", #german == 0, table.concat(german, " | "))
    check("Englisch: Wortwahl (Verbotsliste)", #banned == 0, table.concat(banned, " | "))
    local n = 0
    for _ in pairs(BM.texts) do n = n + 1 end
    check("Englisch: viele Texte gesehen", n > 120, n)
  end
end

print(("Sprachen UI (%d Sprachen): %d gruen, %d rot"):format(#codes, pass, fail))
os.exit(fail == 0 and 0 or 1)
