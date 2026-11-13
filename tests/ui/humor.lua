-- Humor.lua (1.2.0, bau-d) with UI and real logic: quip and stamp on the message, taken down from the
-- queue, switch in the house rules, paragraph in the manual, empty book, April 1st (mocked
-- time), thumbtack; in fiFI and zhCN none of this happens.
-- Usage: luajit tests/ui/humor.lua
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local root = here .. "/../.."
local DIR = root .. "/DeathNote"

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end

-- fix-2: after activation Humor.lua keeps only the texts of the active language; the tests read both
-- tables from the marked block of the file
local SRC = (function()
  local h = assert(io.open(DIR .. "/Humor.lua", "rb"))
  local s = h:read("*a"); h:close()
  return assert(loadstring("return " .. assert(s:match("local TEXTS = (%b{})"))))()
end)()

local AM, BM, G
local function world(code, opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = DIR .. "/Media"
  G = BM.G
  AM.locale = code
  if opts.guild then rawset(G, "GetGuildInfo", function(u) if u == "player" then return opts.guild end end) end
  -- the clock of the test never is the clock of the machine: without opts.date it is an ordinary afternoon
  -- (the real hour let the night quip in when the suite ran after midnight, and 1 April would do the same)
  local clock = opts.date or { year = 2026, month = 11, day = 12, hour = 14, min = 0, sec = 0, wday = 5, yday = 316, isdst = false }
  rawset(G, "date", function(f, t) if f == "*t" then return clock end return os.date(f, t) end)
  local ns = AM.Load({ noLogin = true, db = opts.db, before = function() AM.units.player.guild = "Die Wurstbrueder" end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  if ns.Humor then for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 1 end; ns.Humor.QUIET = 0 end -- fix-3: without a lock
  return ns
end
local function settle() AM.Advance(0.1); BM.Advance(0.1) end
local function clean(name, ns)
  check(name .. ": keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  check(name .. ": keine Verstoesse", #BM.violations == 0, BM.violations[#BM.violations])
  check(name .. ": keine fehlenden Schluessel", next(ns.Locale.missing) == nil, next(ns.Locale.missing))
  local unk = {}
  for k in pairs(BM.unknown or {}) do unk[#unk + 1] = k end
  check(name .. ": nur bekannte API-Methoden", #unk == 0, table.concat(unk, ", "))
end
local function kill(ns, name, surname, o)
  o = o or {}
  local S = ns.Store
  local key = S.ApplyKill({ name = name, surname = surname, guid = "Player-93-" .. name, class = "ROGUE", level = o.level or 40 },
    { t = _G.time(), zone = "Z", myLevel = 40, theirLevel = o.level or 40 }, true)
  local j = { t = _G.time(), kind = "pvp", sure = true, counted = true, killerKey = key, myLevel = 40, candidates = {} }
  S.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, key)
  settle()
  return key
end
local function banner() return rawget(G, "DeathNoteBanner") end
local function away() BM.Advance(6); BM.FinishAnims(); BM.Advance(1); settle() end
local function quip() local b = banner(); return b and b.dnQuip and b.dnQuip:IsVisible() and b.dnQuip.text:GetText() or nil end
local function stampText() local b = banner(); return b and b.stampText:IsShown() and b.stampText:GetText() or nil end
local function inPool(ns, code, pool, text)
  local T = ns.Humor.TEXTS[code]
  for _, list in ipairs({ T.POOL[pool] or {}, T.MEMBER[pool] or {} }) do
    for _, v in ipairs(list) do if v == text then return true end end
  end
  return false
end
local function emptyPage()
  for _, f in ipairs(BM.frames) do if f.big and f.small and f.tiny then return f end end
end
local function checkWith(text)
  for _, f in ipairs(BM.frames) do
    if f._kind == "CheckButton" and f.label and f.label:GetText() == text then return f end
  end
end
local function helpHas(text) return BM.texts[text] ~= nil end
local function humorChat()
  local n = 0
  for _, l in ipairs(AM.chat) do if l:find("|cffa89878", 1, true) then n = n + 1 end end
  return n
end

------------------------------------------------------------------------
-- German and English
------------------------------------------------------------------------
for _, code in ipairs({ "deDE", "enUS" }) do
  local ns = world(code)
  local T = ns.Humor.TEXTS[code]
  local n = code .. ": "
  -- empty book (probability 1): another sentence from the pool, stays when rebuilt
  ns:Fire("TOGGLE_UI"); settle()
  local X = emptyPage()
  check(n .. "leeres Buch sichtbar", X and X:IsShown())
  local s1 = X and X.small:GetText()
  check(n .. "leeres Buch: Satz aus dem Topf", inPool(ns, code, "empty", s1), s1)
  ns:Fire("ENEMY_UPDATED", "x"); settle()
  check(n .. "leeres Buch: Satz bleibt beim Neuaufbau", X.small:GetText() == s1, X.small:GetText())
  ns:Fire("TOGGLE_UI"); settle()
  -- House rules: switch on the book sheet
  ns:Fire("TOGGLE_UI"); settle()
  ns.UI.OpenPanel("settings"); settle()
  local cb = checkWith(T.OPT)
  check(n .. "Schalter da", cb ~= nil)
  check(n .. "Schalter an (Standard)", cb and cb:GetChecked() == true)
  if cb then
    cb:SetChecked(false); cb._scripts.OnClick(cb); settle()
    check(n .. "Schalter aus gespeichert", ns.Store.Setting("humor") == false)
    check(n .. "Humor aus", not ns.Humor.On())
    cb:SetChecked(true); cb._scripts.OnClick(cb); settle()
    check(n .. "Schalter wieder an", ns.Store.Setting("humor") == true and ns.Humor.On())
  end
  ns.UI.OpenPanel("help"); settle()
  -- fix-3: imprint as one line in the footer, not a paragraph
  check(n .. "Gebrauchsanweisung: Zeile am Fuss", helpHas(T.MANUAL) and ns.UI.HELP_FOOT == T.MANUAL, T.MANUAL)
  check(n .. "Gebrauchsanweisung: 9 Absaetze (1.3.0: rap sheet)", #ns.UI.HELP == 9, #ns.UI.HELP)
  ns.UI.ClosePanel(); settle()
  -- Deaths: 5th death regular customer quip (fix-3: no longer the 3rd), 10th death stamp
  local key
  for i = 1, 5 do key = kill(ns, "Grimm", "Bart"); if i == 3 then check(n .. "3. Tod: kein Spruch mehr", quip() == nil, quip()) end; if i < 5 then away() end end
  check(n .. "5. Tod: Spruch unter der Meldung", inPool(ns, code, "regular", quip()), quip())
  away()
  for i = 6, 10 do key = kill(ns, "Grimm", "Bart"); if i < 10 then away() end end
  check(n .. "10. Tod: Stempel " .. T.STAMP.regular, stampText() == T.STAMP.regular, stampText())
  -- fix-3: red frame like the other stamps (the dark one was invisible on the black strip)
  check(n .. "10. Tod: Stempelrahmen leer, rot", tostring(banner().stamp._tex):find("stamp_rache_blank.tga", 1, true)
        and banner().stampText._tc and banner().stampText._tc[1] > 0.6, banner().stamp._tex)
  check(n .. "10. Tod: Meilenstein-Zeile", quip() == T.MILESTONE.regular, quip())
  away()
  check(n .. "Meldung weg: Spruch weg", quip() == nil)
  -- a new message without a humour occasion clears the old quip
  kill(ns, "Neu", "Ling")
  check(n .. "neue Meldung ohne Anlass: kein alter Spruch", quip() == nil, quip())
  away()
  -- level well below
  kill(ns, "Klein", "Wicht", { level = 20 })
  check(n .. "niedrige Stufe: Spruch", inPool(ns, code, "lowbie", quip()), quip())
  away()
  -- Revenge: first revenge not on rank 1, then public enemy
  ns.Store.AddRevenge("Klein-Wicht"); settle()
  check(n .. "erste Rache: Stempel", stampText() == T.STAMP.revenge1, stampText())
  away()
  ns.Store.AddRevenge(key); settle()
  check(n .. "Rang 1 erledigt: Stempel", stampText() == ns.L.STAMP_NR1_DOWN, stampText())
  check(n .. "Rang 1 erledigt: Zeile", quip() == T.MILESTONE.nr1, quip())
  away()
  ns.Store.AddRevenge(key); settle()
  check(n .. "weitere Rache: normaler Stempel, Spruch", inPool(ns, code, "revenge", quip()), quip())
  check(n .. "weitere Rache: kein Humor-Stempel", stampText() ~= ns.L.STAMP_NR1_DOWN and stampText() ~= T.STAMP.revenge1, stampText())
  away()
  -- poster: thumbtack
  ns.UI.ShowEnemy(key); settle()
  local pinBtn
  for _, f in ipairs(BM.frames) do if f.fall and f.wobble then pinBtn = f end end
  check(n .. "Reisszwecke klickbar", pinBtn ~= nil)
  if pinBtn then
    pinBtn._scripts.OnClick(pinBtn); settle()
    check(n .. "1 Klick: wackelt", pinBtn.wobble:IsPlaying() and not pinBtn.fall:IsPlaying())
    AM.chat = {}
    for _ = 2, 5 do pinBtn._scripts.OnClick(pinBtn) end
    settle()
    check(n .. "5 Klicks: faellt", pinBtn.fall:IsPlaying())
    check(n .. "5 Klicks: eine Zeile", humorChat() == 1, humorChat())
  end
  -- switch off: no quips, no stamps; the hidden command stays
  ns.Store.Setting("humor", false)
  for _ = 1, 10 do kill(ns, "Stamm", "Gast"); away() end
  ns.Store.AddRevenge(key); settle()
  check(n .. "aus: kein Spruch", quip() == nil, quip())
  check(n .. "aus: kein Humor-Stempel", stampText() ~= T.STAMP.regular, stampText())
  away()
  AM.chat = {}
  _G.SlashCmdList.DEATHNOTE("42")
  check(n .. "aus: /dn 42 antwortet", humorChat() == 1)
  ns.Store.Setting("humor", true)
  ns:Fire("TOGGLE_UI"); settle()
  clean(code, ns)
end

------------------------------------------------------------------------
-- Die Fachkraefte: taken down from the queue with its own stamp
------------------------------------------------------------------------
do
  local ns = world("deDE", { guild = "Die Fachkräfte" })
  local T = ns.Humor.TEXTS.deDE
  check("Mitglied erkannt", ns.Humor.IsMember())
  kill(ns, "Grimm", "Bart")             -- message is shown
  ns:Fire("HUNT_BAGGED", "Ziel-Eins", "Hans", _G.time(), "guild"); settle()
  check("Erlegt wartet hinter der eigenen Meldung", (banner().kicker:GetText() or ""):find(ns.Extras.Spaced(ns.L.BANNER_AGAIN), 1, true)
    or (banner().kicker:GetText() or ""):find(ns.Extras.Spaced(ns.L.BANNER_NEW), 1, true), banner().kicker:GetText())
  away()
  check("Erlegt kommt dran", banner():IsShown() and banner().kicker:GetText() == ns.Extras.Spaced(ns.L.BANNER_HUNT),
    banner().kicker:GetText())
  check("Erlegt: Stempel FACHGERECHT ERLEDIGT", stampText() == T.STAMP.pro, stampText())
  check("Erlegt: Spruch (mit Gilden-Varianten)", inPool(ns, "deDE", "bagged", quip()), quip())
  away()
  -- other guild: no Fachkraefte stamp
  ns = world("deDE", { guild = "Andere Gilde" })
  ns:Fire("HUNT_BAGGED", "Ziel-Zwei", "Hans", _G.time(), "guild"); settle()
  check("fremde Gilde: Erlegt ohne Fachkraefte-Stempel", stampText() ~= T.STAMP.pro, stampText())
  check("fremde Gilde: Spruch aus dem normalen Topf", inPool(ns, "deDE", "bagged", quip()), quip())
  clean("Fachkraefte", ns)
end

------------------------------------------------------------------------
-- April 1st (mocked time): own poster in the empty book
------------------------------------------------------------------------
for _, code in ipairs({ "deDE", "enUS" }) do
  local ns = world(code, { date = { year = 2027, month = 4, day = 1, hour = 12, min = 0, sec = 0 } })
  ns:Fire("TOGGLE_UI"); settle()
  local X = emptyPage()
  local T = ns.Humor.TEXTS[code]
  check(code .. " 1. April: eigener Name", X and X.big:GetText() == (G.UnitName("player")), X and X.big:GetText())
  check(code .. " 1. April: gesucht wegen Sterbens", X and X.small:GetText() == T.APRIL_SUB, X and X.small:GetText())
  check(code .. " 1. April: Kopfgeld", X and X.tiny:GetText() == T.APRIL_HINT)
  ns = world(code, { date = { year = 2027, month = 4, day = 2, hour = 12, min = 0, sec = 0 } })
  ns:Fire("TOGGLE_UI"); settle()
  X = emptyPage()
  check(code .. " 2. April: normal", X and X.big:GetText() == ns.L.EMPTY_WANTED_HEAD, X and X.big:GetText())
  clean(code .. " April", ns)
end

------------------------------------------------------------------------
-- fiFI and zhCN: nothing
------------------------------------------------------------------------
for _, code in ipairs({ "fiFI", "zhCN" }) do
  local ns = world(code, { guild = "Die Fachkräfte", date = { year = 2027, month = 4, day = 1, hour = 3, min = 0, sec = 0 } })
  local n = code .. ": "
  check(n .. "nicht aktiv", not ns.Humor.Active() and not ns.Humor.IsMember())
  ns:Fire("TOGGLE_UI"); settle()
  local X = emptyPage()
  check(n .. "leeres Buch unveraendert", X and X.big:GetText() == ns.L.EMPTY_WANTED_HEAD and X.small:GetText() == ns.L.EMPTY_WANTED_SUB,
    X and X.small:GetText())
  ns.UI.OpenPanel("settings"); settle()
  check(n .. "kein Schalter (de)", checkWith(SRC.deDE.OPT) == nil)
  check(n .. "kein Schalter (en)", checkWith(SRC.enUS.OPT) == nil)
  check(n .. "keine Humor-Texte im Speicher (fix-2)", next(ns.Humor.TEXTS) == nil)
  ns.UI.OpenPanel("help"); settle()
  check(n .. "Gebrauchsanweisung: 9 Absaetze, keine Fusszeile", #ns.UI.HELP == 9 and ns.UI.HELP_FOOT == nil, #ns.UI.HELP)
  ns.UI.ClosePanel(); settle()
  local key
  for _ = 1, 10 do key = kill(ns, "Grimm", "Bart", { level = 10 }); check(n .. "Tod: kein Spruch", quip() == nil, quip()); away() end
  ns.Store.AddRevenge(key); settle()
  check(n .. "Rache: kein Spruch", quip() == nil)
  check(n .. "Rache: normaler Stempel", stampText() == ns.L.STAMP_REVENGE, stampText())
  away()
  ns:Fire("HUNT_BAGGED", "Ziel-Eins", "Hans", _G.time(), "guild"); settle()
  check(n .. "Erlegt: normaler Stempel", stampText() == ns.L.STAMP_HUNT, stampText())
  check(n .. "Erlegt: kein Spruch", quip() == nil)
  ns.UI.ShowEnemy(key); settle()
  local pinBtn
  for _, f in ipairs(BM.frames) do if f.fall and f.wobble then pinBtn = f end end
  check(n .. "keine klickbare Reisszwecke", pinBtn == nil)
  local seen = {}
  for t in pairs(BM.texts) do seen[#seen + 1] = t end
  local leak
  for _, lang in ipairs({ "deDE", "enUS" }) do
    local function walk(t)
      for _, v in pairs(t) do
        if type(v) == "table" then walk(v)
        elseif type(v) == "string" and #v > 8 then
          if BM.texts[v] then leak = v end
          for _, l in ipairs(AM.chat) do if l:find(v, 1, true) then leak = v end end
        end
      end
    end
    walk(SRC[lang])
  end
  check(n .. "kein Humor-Text sichtbar oder im Chat", leak == nil, leak)
  check(n .. "keine Humor-Zeile im Chat", humorChat() == 0, humorChat())
  ns:Fire("TOGGLE_UI"); settle()
  clean(code, ns)
end

print(("Humor UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
