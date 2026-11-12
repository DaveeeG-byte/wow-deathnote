-- 1.2.0 multiple languages, logic side: the client's language as default (no dialog), English
-- commands, help in the active language, /dn lang, language-neutral data, export German -> import English.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function slash(msg) _G.SlashCmdList.DEATHNOTE(msg) end
local function lastChat() return M.chat[#M.chat] or "" end
local function chatHas(needle)
  for _, l in ipairs(M.chat) do if l:find(needle, 1, true) then return true end end
  return false
end

test("Frische Installation, deutscher Client: Deutsch aktiv, kein Dialog, Begruessung mit Sprachsatz", function()
  M.client = "deDE"
  local ns = M.Load({ lang = false })
  M.client = nil
  eq(ns.Locale.code, "deDE", "Sprache des Clients ist Standard")
  eq(ns.Locale.choice, nil)
  ok(ns.Locale.NeedsChoice == nil and ns.LangDialog == nil, "kein Dialog")
  eq(ns.Store.Setting("lang"), nil, "nichts gespeichert, solange nichts gewaehlt ist")
  M.Advance(4)
  no(chatHas("Das Buch liegt bereit."), "Begruessung erst nach 5 s")
  M.Advance(2)
  ok(chatHas("Das Buch liegt bereit."), "Begruessung deutsch")
  ok(lastChat():find("Deutsch (deDE)", 1, true) and lastChat():find("/dn sprache", 1, true), "am Ende: wo man die Sprache aendert: " .. lastChat())
  M.Advance(60)
  local n = 0
  for _, l in ipairs(M.chat) do if l:find("Das Buch liegt bereit.", 1, true) then n = n + 1 end end
  eq(n, 1, "einmal")
  for _, client in ipairs({ "svSE", "xxXX" }) do
    M.client = client
    local ns2 = M.Load({ lang = false })
    M.client = nil
    eq(ns2.Locale.code, "enUS", "Client " .. client .. ": Englisch")
  end
end)

test("/dn lang: speichert die Kennung, meldet /reload, lehnt Unbekanntes ab", function()
  M.client = "enUS"
  local ns = M.Load({ lang = false })
  M.client = nil
  slash("lang de")
  eq(ns.Store.Setting("lang"), "deDE"); eq(ns.Store.Setting("langAsked"), nil, "kein Merker mehr")
  ok(lastChat():find("Deutsch (deDE)", 1, true) and lastChat():find("/reload", 1, true), lastChat())
  slash("lang klingonisch")
  ok(chatHas("Unknown language: klingonisch"))
  eq(ns.Store.Setting("lang"), "deDE", "nichts ueberschrieben")
  slash("sprache en")
  eq(ns.Store.Setting("lang"), "enUS")
  ok(lastChat():find("Language: English (enUS).", 1, true), lastChat())
  slash("lang")
  ok(chatHas("Language now: English (enUS)."))
  slash("lang auto")
  eq(ns.Store.Setting("lang"), nil, "auto loescht die Wahl")
  ok(lastChat():find("(auto)", 1, true), lastChat())
  slash("lang")
  ok(lastChat():find("auto", 1, true) or chatHas("(auto)"), "Anzeige: automatisch")
end)

test("Englische Unterbefehle gelten auch auf Deutsch, deutsche auch auf Englisch", function()
  for _, lang in ipairs({ "deDE", "enUS" }) do
    local ns = M.Load({ lang = lang })
    M.ClearFired()
    slash("add grimm bart"); ok(ns.Store.Get("Grimm-Bart"), lang .. " add")
    slash("quiet"); eq(ns.Store.Setting("alert.enabled"), false, lang .. " quiet")
    slash("still"); eq(ns.Store.Setting("alert.enabled"), true, lang .. " still")
    slash("del grimm"); no(ns.Store.Get("Grimm-Bart"), lang .. " del")
    slash("test"); eq(#M.Fired("TEST_ALERT"), 1, lang .. " test")
  end
end)

test("Hilfe in der aktiven Sprache (Deutsch: deutsche Befehle, Englisch: englische)", function()
  local ns = M.Load({ lang = "deDE" })
  local n0 = #M.chat
  slash("help")
  eq(#M.chat - n0, #ns.HELP_KEYS)
  ok(chatHas("/dn still  Alarm aus/an")); ok(chatHas("/dn jagd <Name [Nachname]>"))
  M.Load({ lang = "enUS" })
  slash("hilfe")
  ok(chatHas("/dn quiet  alarm off/on")); ok(chatHas("/dn hunt <Name [Surname]>")); ok(chatHas("/dn calloff"))
  no(chatHas("Buch"), "keine deutschen Woerter in der englischen Hilfe")
  slash("gibtsnicht")
  ok(lastChat():find("Unknown command. Help: /dn help", 1, true))
end)

test("Zeitformen und Geld je Sprache", function()
  local ns = M.Load({ lang = "enUS" })
  local U = ns.Util
  local now = _G.time()
  eq(U.Ago(now - 10), "just now"); eq(U.Ago(now - 300), "5 min ago"); eq(U.Ago(now - 7200), "2 h ago")
  eq(U.Ago(now - 86400), "1 day ago"); eq(U.Ago(now - 3 * 86400), "3 days ago"); eq(U.Ago(nil), "never")
  eq(U.Money(123456), "12g 34s 56c")
  ok(U.When(now):match("^%d%d/%d%d %d%d:%d%d$"), U.When(now))
  ns = M.Load({ lang = "deDE" })
  U = ns.Util
  eq(U.Ago(now - 300), "vor 5 Min."); eq(U.Ago(now - 3600), "vor 1 Std."); eq(U.Ago(now - 86400), "vor 1 Tag")
  eq(U.Ago(now - 2 * 86400), "vor 2 Tagen"); eq(U.Money(123456), "12g 34s 56k")
  ok(U.When(now):match("^%d%d%.%d%d%. %d%d:%d%d$"), U.When(now))
end)

-- All strings of a table (recursive), keys and values
local function strings(t, out, seen)
  out, seen = out or {}, seen or {}
  if seen[t] then return out end
  seen[t] = true
  for k, v in pairs(t) do
    if type(k) == "string" then out[#out + 1] = k end
    if type(v) == "string" then out[#out + 1] = v elseif type(v) == "table" then strings(v, out, seen) end
  end
  return out
end

test("Daten bleiben sprachneutral: kein Text der deutschen Tabelle in DeathNoteDB", function()
  local en = {}
  for k, v in pairs(M.Load({ lang = "enUS" }).L) do en[k] = v end
  local ns = M.Load({ lang = "deDE" })
  -- a death, a manual entry, state and probe: everything that goes into the file while playing
  ns.Store.AddManual("Grimm", "Bart")
  slash("gilde"); slash("probe"); slash("freunde")
  M.Advance(40)
  local de = {}
  for k, v in pairs(ns.L) do
    if type(v) == "string" and #v > 3 and v ~= ns.L.TIME_FMT_WHEN then de[v] = k end
  end
  -- texts that read the same in English ("Master", "Gong") are ids and may stay
  local bad = {}
  for _, s in ipairs(strings(_G.DeathNoteDB)) do
    if de[s] and en[de[s]] ~= s then bad[#bad + 1] = de[s] .. "=" .. s end
  end
  eq(#bad, 0, table.concat(bad, ", "))
  eq(_G.DeathNoteDB.settings.lang, "deDE", "nur die Kennung")
end)

test("Export auf Deutsch, Einlesen auf Englisch: gleiche Daten, Kopfzeile sprachneutral", function()
  local ns = M.Load({ lang = "deDE" })
  ns.Store.AddManual("Grimm", "Bart")
  ns.Store.AddManual("Zwei", "Te")
  ns.Store.SetNote("Grimm-Bart", "Notiz bleibt Notiz")
  local text = ns.Store.Export()
  eq(text:match("^[^\n]+"), "DEATHNOTE:1")
  local ns2 = M.Load({ lang = "enUS" })
  local okI, added = ns2.Store.Import(text)
  ok(okI, tostring(added)); eq(added, 2)
  eq(ns2.Store.Get("Grimm-Bart").note, "Notiz bleibt Notiz", "Freitext unveraendert")
  eq(ns2.Store.Get("Grimm-Bart").status, ns.Store.Get("Grimm-Bart").status)
  -- error messages in the active language
  local bad, msg = ns2.Store.Import("Quatsch")
  eq(bad, false); ok(msg:find("Not a DeathNote export", 1, true), msg)
  local ns3 = M.Load({ lang = "deDE" })
  bad, msg = ns3.Store.Import("Quatsch")
  ok(msg:find("Kein DeathNote-Export", 1, true), msg)
  -- and back: an English export reads in German
  local okB = ns3.Store.Import(ns2.Store.Export())
  ok(okB)
  ok(ns3.Store.Get("Zwei-Te"))
end)

test("Upgrade von 1.1.0 (Fixture), deutscher Client: bleibt deutsch ohne Fenster, Daten unveraendert", function()
  local f = assert(loadfile((arg[0]:match("^(.*)/tests/") or ".") .. "/tests/fixtures/sv_1.0.1_autor.lua"))
  local env = {}
  setfenv(f, env); f()
  local db = env.DeathNoteDB
  ok(db, "Fixture laedt")
  local before = 0
  for _ in pairs(db.enemies or {}) do before = before + 1 end
  M.client = "deDE"
  local ns = M.Load({ lang = false, db = db })
  M.client = nil
  eq(ns.Locale.code, "deDE", "deutsch wie in 1.1.0")
  ok(ns.LangDialog == nil, "kein Fenster")
  local after = 0
  for _ in pairs(_G.DeathNoteDB.enemies or {}) do after = after + 1 end
  eq(after, before, "keine Eintraege verloren")
  eq(_G.DeathNoteDB.settings.lang, nil, "nichts still gesetzt")
end)

M.done("test_sprache")
