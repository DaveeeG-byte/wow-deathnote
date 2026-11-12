-- Humor.lua (1.2.0, bau-d): occasions, switch, milestones exactly once (also after /reload), randomness with
-- a fixed seed, hidden commands vs. /dn add, guild extras (matching, foreign, none, secret),
-- German and English only (nothing happens in fiFI and zhCN), no humor text in the file or on the wire.
-- The logic runs without UI here: milestones without a message arrive as a chat line.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Humor.lua"

local DAY = 86400
local function load(code, opts)
  M.locale = code or "deDE"
  local saved = M.FILES
  M.FILES = FILES
  local ns = M.Load(opts)
  M.FILES = saved
  return ns
end
local function always(ns) for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 1 end; ns.Humor.QUIET = 0 end -- fix-3: without the lock
local function never(ns) for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 0 end end
local QUIP = "|cffa89878"
local function quips()
  local out = {}
  for _, l in ipairs(M.chat) do if l:find(QUIP, 1, true) then out[#out + 1] = l end end
  return out
end
local function said(text) for _, l in ipairs(M.chat) do if l:find(text, 1, true) then return true end end return false end

-- A certain PvP death by name/surname (like Attribution: book the deed, journal, event)
local function kill(ns, name, surname, o)
  o = o or {}
  local S = ns.Store
  local lvl, my = o.level or 40, o.myLevel or 40
  local key = S.ApplyKill({ name = name, surname = surname, guid = "Player-93-" .. name, class = "ROGUE", level = lvl },
    { t = time(), zone = "Z", myLevel = my, theirLevel = lvl }, true)
  local j = { t = time(), kind = "pvp", sure = true, counted = true, killerKey = key, myLevel = my, candidates = {} }
  S.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, key)
  return key
end
local function pve(ns)
  local j = { t = time(), kind = "pve", sure = false, counted = true, candidates = {} }
  ns.Store.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, nil)
end
local function slash(s) _G.SlashCmdList.DEATHNOTE(s) end

-- All texts (leaves) of the humor tables of both languages
local function allTexts(ns)
  local out = {}
  local function walk(t)
    for _, v in pairs(t) do
      if type(v) == "table" then walk(v) elseif type(v) == "string" and #v > 8 then out[#out + 1] = v end
    end
  end
  walk(ns.Humor.TEXTS)
  return out
end
local function dump(v, seen, out)
  out = out or {}
  seen = seen or {}
  if type(v) == "table" then
    if seen[v] then return out end
    seen[v] = true
    for k, x in pairs(v) do dump(k, seen, out); dump(x, seen, out) end
  elseif type(v) == "string" then out[#out + 1] = v end
  return out
end

---------------------------------------------------------------------------
-- fix-2: memory. After activation only the text table of the active language remains (none in the 19 others)
---------------------------------------------------------------------------
test("Speicher: nur die Texte der aktiven Sprache bleiben", function()
  local before = {}
  for _, code in ipairs({ "deDE", "enUS", "fiFI" }) do
    local ns = load(code)
    local T = ns.Humor.TEXTS
    if code == "fiFI" then
      eq(next(T), nil, "fiFI: keine Humor-Texte")
    else
      ok(T[code] and T[code].OPT, code .. ": eigene Texte da")
      local other = code == "deDE" and "enUS" or "deDE"
      eq(T[other], nil, code .. ": die andere Sprache ist verworfen")
    end
    before[code] = true
  end
end)

---------------------------------------------------------------------------
-- Every occasion fires (de/en), and not when switched off
---------------------------------------------------------------------------
for _, code in ipairs({ "deDE", "enUS" }) do
  test(code .. ": Anlaesse loesen aus (Stammkunde, Meilenstein, PvE, Begnadigen, Rache, 100 Tode, Befehle)", function()
    local ns = load(code)
    local H = ns.Humor
    always(ns)
    ok(H.Active() and H.On(), "aktiv und an")
    local T = H.TEXTS[code]
    local key
    for _ = 1, 10 do key = kill(ns, "Grimm", "Bart") end
    ok(said(T.MILESTONE.regular), "10. Tod: Meilenstein Stammkunde als Zeile (ohne Meldung)")
    ok(ns.Humor.Mem().m.regular, "Merker Stammkunde")
    M.chat = {}
    pve(ns)
    eq(#quips(), 1, "PvE-Tod: eine Zeile")
    M.chat = {}
    ns.Store.SetStatus(key, "pardoned")
    eq(#quips(), 1, "Begnadigen: eine Zeile")
    ns.Store.SetStatus(key, "wanted")
    M.chat = {}
    local k2 = kill(ns, "Zweiter", "Feind")
    ns.Store.AddRevenge(k2)      -- rank 2: first revenge
    ok(said(T.MILESTONE.revenge1), "erste Rache")
    ns.Store.AddRevenge(key)     -- rank 1: public enemy taken down
    ok(said(T.MILESTONE.nr1), "Staatsfeind Nr. 1 erledigt")
    M.chat = {}
    ns.Humor.Mem().deaths = 99
    pve(ns)
    ok(said(T.MILESTONE.d100), "100 Tode")
    for _, c in ipairs({ "fachkraft", "42", code == "deDE" and "beichte" or "confess", code == "deDE" and "danke" or "thanks" }) do
      M.chat = {}
      slash(c)
      eq(#quips(), 1, "/dn " .. c .. ": eine Zeile")
      no(said(ns.L.CHAT_UNKNOWN_CMD), "/dn " .. c .. ": nicht unbekannt")
    end
    M.chat = {}
    slash("confess")
    ok(said(code == "deDE" and "Beichte: 100 Tode, 2 Täter, 2× Rache" or "Confession: 100 deaths, 2 killers, payback 2×"),
      "Beichte mit Zahlen: " .. tostring(M.chat[1]))
  end)

  test(code .. ": Schalter aus: keine Sprueche, keine Meilensteine; versteckte Befehle bleiben", function()
    local ns = load(code)
    always(ns)
    ns.Store.Setting("humor", false)
    no(ns.Humor.On(), "aus")
    for _ = 1, 10 do kill(ns, "Grimm", "Bart") end
    pve(ns)
    ns.Store.SetStatus("Grimm-Bart", "pardoned")
    ns.Store.SetStatus("Grimm-Bart", "wanted")
    ns.Store.AddRevenge("Grimm-Bart")
    ns.Humor.Mem().deaths = 99; pve(ns)
    eq(#quips(), 0, "nichts bei aus")
    no(ns.Humor.Mem().m.regular, "kein Merker bei aus")
    no(ns.Humor.Mem().m.d100, "kein Merker 100 bei aus")
    slash("42")
    eq(#quips(), 1, "versteckter Befehl antwortet auch bei aus")
  end)
end

test("Wahrscheinlichkeit 0: Zufallsanlaesse schweigen, feste Anlaesse (3. Tod, Meilenstein) nicht", function()
  local ns = load("deDE")
  never(ns)
  pve(ns)
  ns.Store.AddManual("Ohne", "Tat")
  ns.Store.SetStatus("Ohne-Tat", "pardoned")
  eq(#quips(), 0, "pve und Begnadigen schweigen")
  for _ = 1, 10 do kill(ns, "Grimm", "Bart") end
  ok(said(ns.Humor.TEXTS.deDE.MILESTONE.regular), "Meilenstein kommt trotzdem")
end)

test("Stufe deutlich darunter: Spruch nur ab 10 Stufen Abstand (Entscheidung)", function()
  local ns = load("enUS")
  always(ns)
  ns.Humor.Clock = function() return { hour = 14, month = 6, day = 2 } end
  local H = ns.Humor
  local calls = 0
  H.random = function(n) calls = calls + 1; return n and 1 or 0 end
  kill(ns, "Klein", "Wicht", { level = 31, myLevel = 40 })   -- 9 below: nothing
  eq(calls, 0, "9 Stufen: keine Auswahl")
  kill(ns, "Winzig", "Wicht", { level = 30, myLevel = 40 })  -- 10 below: roll + pick
  eq(calls, 1, "10 Stufen: Auswahl aus dem Topf")
end)

test("Nachts (2 bis 5 Uhr): eigener Topf, tagsueber nicht", function()
  local ns = load("deDE")
  always(ns)
  local calls = 0
  ns.Humor.random = function(n) calls = calls + 1; return n and 1 or 0 end
  ns.Humor.Clock = function() return { hour = 14 } end
  kill(ns, "Tag", "Feind")
  eq(calls, 0, "tags: nichts")
  ns.Humor.Clock = function() return { hour = 3 } end
  kill(ns, "Nacht", "Feind")
  eq(calls, 1, "nachts: Auswahl aus dem Topf")
end)

---------------------------------------------------------------------------
-- Milestones exactly once, also after /reload; preset from 1.1.0
---------------------------------------------------------------------------
test("Meilensteine genau einmal, auch nach /reload", function()
  local ns = load("deDE")
  always(ns)
  local T = ns.Humor.TEXTS.deDE
  for _ = 1, 10 do kill(ns, "Grimm", "Bart") end
  ns.Store.AddRevenge("Grimm-Bart")
  ns.Humor.Mem().deaths = 99; pve(ns)
  local function count(text) local n = 0; for _, l in ipairs(M.chat) do if l:find(text, 1, true) then n = n + 1 end end return n end
  eq(count(T.MILESTONE.regular) + count(T.MILESTONE.nr1) + count(T.MILESTONE.d100), 3, "je einmal")
  local db = _G.DeathNoteDB
  ns = load("deDE", { db = db })
  always(ns)
  M.chat = {}
  for _ = 1, 10 do kill(ns, "Noch", "Einer") end
  ns.Store.AddRevenge("Noch-Einer")
  ns.Store.AddRevenge("Grimm-Bart")
  pve(ns)
  eq(count(T.MILESTONE.regular) + count(T.MILESTONE.nr1) + count(T.MILESTONE.d100) + count(T.MILESTONE.revenge1), 0,
    "nach /reload keiner mehr")
  for k, v in pairs(_G.DeathNoteDB.humor.m) do ok(type(k) == "string" and type(v) == "number", "Merker " .. k) end
end)

test("Buch aus 1.1.0 mit Rache: keine \"erste Rache\"; volle 100 im Journal: keine \"100 Tode\"", function()
  local deaths = {}
  for i = 1, 100 do deaths[i] = { t = 1700000000 - i, kind = "pve", counted = true, candidates = {} } end
  local db = { version = 3, settings = {}, deaths = deaths, enemies = {
    ["Alt-Feind"] = { key = "Alt-Feind", name = "Alt", surname = "Feind", realm = "Feind", status = "wanted", kills = 2,
      assists = 0, suspected = 0, revenge = 1, deaths = {} },
    ["Erst-Feind"] = { key = "Erst-Feind", name = "Erst", surname = "Feind", realm = "Feind", status = "wanted", kills = 5,
      assists = 0, suspected = 0, revenge = 0, deaths = {} } } }
  local ns = load("deDE", { db = db })
  always(ns)
  eq(ns.Store.Rank("Alt-Feind"), 2, "Rang 2 (kein Staatsfeind)")
  ns.Store.AddRevenge("Alt-Feind")
  pve(ns)
  local T = ns.Humor.TEXTS.deDE
  no(said(T.MILESTONE.revenge1), "keine erste Rache")
  no(said(T.MILESTONE.d100), "keine 100")
  eq(ns.Humor.Mem().deaths, 101, "Zaehler vom Journal an")
end)

test("30 Tage ohne Tod: einmal beim Login (verzoegert), dann nie wieder", function()
  local ns = load("deDE")
  pve(ns)
  local db = _G.DeathNoteDB
  db.humor.lastDeath = time() - 31 * DAY
  db.tally.last = time() - 31 * DAY      -- 1.2.0: the book's counter is the truth, the markers follow it
  ns = load("deDE", { db = db })
  M.Advance(13)
  ok(said(ns.Humor.TEXTS.deDE.MILESTONE.clean30), "Zeile nach dem Login")
  M.chat = {}
  ns = load("deDE", { db = _G.DeathNoteDB })
  M.Advance(13)
  no(said(ns.Humor.TEXTS.deDE.MILESTONE.clean30), "nicht zweimal")
  -- 29 days: nothing
  db = _G.DeathNoteDB
  db.humor.m.clean30 = nil
  db.humor.lastDeath = time() - 29 * DAY
  ns = load("deDE", { db = db })
  M.Advance(13)
  no(said(ns.Humor.TEXTS.deDE.MILESTONE.clean30), "29 Tage: nichts")
end)

---------------------------------------------------------------------------
-- Randomness with a fixed seed: repeatable, never the same one twice in a row
---------------------------------------------------------------------------
test("Zufall: fester Startwert gibt dieselbe Folge, nie zweimal dieselbe Zeile hintereinander", function()
  local function run()
    local ns = load("enUS")
    math.randomseed(4711)
    ns.Humor.random = math.random
    local out = {}
    for i = 1, 40 do out[i] = ns.Humor.Pick("revenge") end
    return out
  end
  local a, b = run(), run()
  for i = 1, 40 do
    eq(a[i], b[i], "gleiche Folge an " .. i)
    if i > 1 then ok(a[i] ~= a[i - 1], "Wiederholung an " .. i) end
  end
  local kinds = {}
  for _, v in ipairs(a) do kinds[v] = true end
  local n = 0
  for _ in pairs(kinds) do n = n + 1 end
  eq(n, 4, "alle vier Varianten kommen vor")
end)

---------------------------------------------------------------------------
-- Hidden commands: never vs. /dn add, never change data, de/en only
---------------------------------------------------------------------------
test("Versteckte Befehle gegen /dn add mit gleichem Namen, ohne Datenaenderung", function()
  local ns = load("deDE")
  for _, w in ipairs({ "Fachkraft", "Beichte", "Danke", "Thanks", "Confess" }) do
    slash("add " .. w)
    ok(ns.Store.Get(w .. "-Forever") or ns.Store.Find(w), "/dn add " .. w .. " traegt ein")
  end
  local before = table.concat(dump(_G.DeathNoteDB.enemies), "|")
  local n = #ns.Store.Deaths()
  for _, w in ipairs({ "fachkraft", "fachkräfte", "fachkraefte", "42", "beichte", "confess", "danke", "thanks" }) do slash(w) end
  eq(table.concat(dump(_G.DeathNoteDB.enemies), "|"), before, "Buch unveraendert")
  eq(#ns.Store.Deaths(), n, "Journal unveraendert")
  slash("del Fachkraft")
  no(ns.Store.Find("Fachkraft"), "/dn del Fachkraft streicht")
end)

for _, code in ipairs({ "fiFI", "zhCN" }) do
  test(code .. ": kein einziger Anlass loest aus, Schalter fehlt, Befehle sind unbekannt", function()
    local ns = load(code)
    always(ns)
    local H = ns.Humor
    no(H.Active(), "nicht aktiv")
    no(H.On(), "nicht an")
    local list = { { "tooltip" }, { "ui.minimap.hide" } }
    eq(H.BookOptions(list), list, "Schalter haengt nicht an")
    ns.Humor.Clock = function() return { hour = 3, month = 4, day = 1 } end
    _G.GetGuildInfo = function() return "Die Fachkräfte" end
    H.CheckGuild()
    for _ = 1, 10 do kill(ns, "Grimm", "Bart", { level = 20 }) end
    pve(ns)
    ns.Store.SetStatus("Grimm-Bart", "pardoned"); ns.Store.SetStatus("Grimm-Bart", "wanted")
    ns.Store.AddRevenge("Grimm-Bart")
    ns:Fire("HUNT_BAGGED", "Grimm-Bart", "Hans", time(), "guild")
    eq(#quips(), 0, "keine Zeile")
    no(_G.DeathNoteDB.humor, "keine Merker in der Datei")
    for _, c in ipairs({ "fachkraft", "42", "beichte", "confess", "danke", "thanks" }) do
      M.chat = {}
      slash(c)
      ok(said(ns.L.CHAT_UNKNOWN_CMD), "/dn " .. c .. " wie unbekannt")
    end
    no(H.EmptyWanted({}), "leeres Buch: nichts")
  end)
end

---------------------------------------------------------------------------
-- Guild extras: matching, foreign, none, secret; once at login and on guild change
---------------------------------------------------------------------------
test("Gilde: passender, fremder, fehlender und Secret-Gildenname", function()
  local ns = load("deDE", { before = function() M.units.player.guild = "Die Fachkräfte" end })
  local H = ns.Humor
  ok(H.IsMember(), "passend: Mitglied (beim Login bestimmt)")
  M.chat = {}
  math.randomseed(1); H.random = math.random
  slash("fachkraft")
  local line = M.chat[1] or ""
  local hit = false
  for _, v in ipairs(H.TEXTS.deDE.CMD.guild_member) do if line:find(v, 1, true) then hit = true end end
  ok(hit, "Mitglied: eigene Zeile")
  M.units.player.guild = "Die Wurstbrueder"
  M.FireEvent("PLAYER_GUILD_UPDATE")
  no(H.IsMember(), "fremd")
  M.units.player.guild = nil
  M.FireEvent("PLAYER_GUILD_UPDATE")
  no(H.IsMember(), "keine Gilde")
  M.units.player.guild = M.Secret("gilde")
  M.FireEvent("PLAYER_GUILD_UPDATE")
  no(H.IsMember(), "Secret: kein Mitglied, kein Fehler")
  eq(#M.errors, 0, "keine Fehler")
  M.units.player.guild = "Die Fachkräfte"
  M.FireEvent("PLAYER_GUILD_UPDATE")
  ok(H.IsMember(), "Gildenwechsel zurueck")
  -- members get their own variants in the pool
  local mine = {}
  for _, v in ipairs(H.TEXTS.deDE.MEMBER.revenge) do mine[v] = true end
  local got = false
  for i = 1, 30 do if mine[H.Pick("revenge")] then got = true end end
  ok(got, "Mitglied: Gilden-Varianten kommen vor")
end)

test("Gilde wird nicht je Ereignis bestimmt (nur Login, Gildenwechsel, /dn fachkraft)", function()
  local calls = 0
  local ns = load("deDE", { before = function() M.units.player.guild = "Die Fachkräfte" end })
  local real = _G.GetGuildInfo
  _G.GetGuildInfo = function(...) calls = calls + 1; return real(...) end
  always(ns)
  for _ = 1, 5 do kill(ns, "Grimm", "Bart") end
  ns.Store.AddRevenge("Grimm-Bart")
  pve(ns)
  eq(calls, 0, "kein GetGuildInfo bei Tod, Rache, PvE")
end)

---------------------------------------------------------------------------
-- End to end over the real death path (recap): PvE death with a line
---------------------------------------------------------------------------
test("Echter Todesweg: Tod durch ein Monster gibt (mit Wahrscheinlichkeit 1) eine Zeile", function()
  local ns = load("enUS")
  always(ns)
  M.recap = { id = 3, events = { { sourceGUID = "Creature-0-1", sourceName = "Raptor", amount = 500, overkill = 50,
    timestamp = time() - 1, spellName = "Biss" } } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(6)
  eq(#ns.Store.Deaths(), 0, "PvE ohne Journalzeile (1.2.0)")
  eq(ns.Store.DB().tally.n, 1, "PvE gezaehlt")
  eq(#quips(), 1, "eine Zeile")
  eq(ns.Humor.Mem().deaths, 1, "Zaehler")
end)

---------------------------------------------------------------------------
-- No humor text in stored or sent data
---------------------------------------------------------------------------
test("Kein Humor-Text in DeathNoteDB oder auf der Leitung, nur Zahlen in db.humor", function()
  local ns = load("deDE", { before = function() M.units.player.guild = "Die Fachkräfte" end })
  always(ns)
  for _ = 1, 10 do kill(ns, "Grimm", "Bart") end
  pve(ns)
  ns.Store.AddRevenge("Grimm-Bart")
  ns.Store.SetStatus("Grimm-Bart", "pardoned")
  for _, c in ipairs({ "fachkraft", "42", "beichte", "danke" }) do slash(c) end
  M.Advance(30)
  local stored = table.concat(dump(_G.DeathNoteDB), "\n")
  local sent = {}
  for _, m in ipairs(M.addonSent) do sent[#sent + 1] = m.text end
  sent = table.concat(sent, "\n")
  ok(#M.addonSent > 0, "es wurde gesendet (Gilde)")
  for _, t in ipairs(allTexts(ns)) do
    no(stored:find(t, 1, true), "in der Datei: " .. t)
    no(sent:find(t, 1, true), "auf der Leitung: " .. t)
  end
  local h = _G.DeathNoteDB.humor
  for k, v in pairs(h) do
    ok(type(v) == "number" or (k == "m" and type(v) == "table"), "db.humor." .. k .. " ist Zahl oder Merker")
  end
  for _, v in pairs(h.m) do eq(type(v), "number", "Merker ist Zahl") end
end)

test("Humor-Texte sind keine Schluessel der Sprachtabelle (keine Pflicht fuer die 19 Uebersetzungen)", function()
  local ns = load("deDE")
  -- own scaffold (after activation Locale releases the build instructions)
  local lns = {}
  assert(loadfile(M.ADDON_DIR .. "Locale.lua"))("DeathNote", lns)
  for _, c in ipairs({ "enUS", "deDE" }) do assert(loadfile(M.ADDON_DIR .. "Locales/" .. c .. ".lua"))("DeathNote", lns) end
  local en, de = lns.Locale.Raw("enUS"), lns.Locale.Raw("deDE")
  local values = {}
  for _, t in ipairs({ en, de }) do for _, v in pairs(t) do values[v] = true end end
  for _, t in ipairs(allTexts(ns)) do no(values[t], "steht in der Sprachtabelle: " .. t) end
  for k in pairs(en) do no(k:find("HUMOR", 1, true), "Humor-Schluessel in enUS: " .. k) end
  local n = 0
  for _ in pairs(en) do n = n + 1 end
  local m = 0
  for _ in pairs(de) do m = m + 1 end
  eq(n, m, "Deutsch und Englisch gleich viele Pflicht-Schluessel")
end)

---------------------------------------------------------------------------
-- fix-3: rarer. Probabilities lowered, the 3rd death is no occasion any more, and at most one
-- random line per 10 minutes across all occasions (milestones excepted)
---------------------------------------------------------------------------
test("fix-3: Wahrscheinlichkeiten gesenkt", function()
  local ns = load("deDE")
  local C = ns.Humor.CHANCE
  eq(C.lowbie, 0.2, "Stufe"); eq(C.night, 0.15, "Nacht"); eq(C.revenge, 0.2, "Rache"); eq(C.bagged, 0.15, "Erlegt")
  eq(C.pardon, 0.2, "Begnadigen"); eq(C.empty, 0.2, "leeres Buch")
  eq(ns.Humor.QUIET, 600, "Sperre 10 Minuten")
end)

test("fix-3: hoechstens ein Zufallsspruch je 10 Minuten, ueber alle Anlaesse", function()
  local ns = load("deDE")
  for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 1 end   -- every roll would hit; the lock stays on
  pve(ns)
  eq(#quips(), 1, "erster Spruch")
  pve(ns)
  ns.Store.AddManual("Ohne", "Tat")
  ns.Store.SetStatus("Ohne-Tat", "pardoned")
  kill(ns, "Klein", "Wicht", { level = 10, myLevel = 40 })
  eq(#quips(), 1, "innerhalb von 10 Minuten kein zweiter (Welt, Begnadigen, Stufe)")
  M.Advance(601)
  pve(ns)
  eq(#quips(), 2, "nach 10 Minuten wieder einer")
end)

M.done("test_humor")
