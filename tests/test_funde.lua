-- Fund-Belege der Logik-Jagd (B1..B16 unveraendert uebernommen), dazu B11/B6/B8/B17-B19 und Zusaetze.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local function die() M.FireEvent("PLAYER_DEAD"); M.Advance(6) end
local function recap(id, guid, name, ts, overkill)
  M.recap = { id = id, events = { { sourceGUID = guid, sourceName = name, amount = 500, overkill = overkill or 100, timestamp = ts or (M.epoch + M.now), spellName = "Hinterhalt" } } }
end

test("B1 Fehler im Leseversuch blockiert alle spaeteren Tode (pending bleibt haengen)", function()
  local ns = M.Load()
  -- ein Recap-Ereignis, dessen Feldzugriff wirft (steht fuer jeden unerwarteten Fehler im Timer)
  M.recap = { id = 1, events = { setmetatable({}, { __index = function() error("unerwartet") end }) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(6)
  M.errors = {}
  M.Advance(30)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(2, "Player-93-Grimm", "Grimm Blut")
  M.ClearFired(); die()
  M.errors = {}
  eq(#M.Fired("DEATH_RECORDED"), 1, "zweiter Tod wird gebucht:")
end)

test("B2 Von Hand nur mit Vornamen eingetragen: wird nie erkannt", function()
  local ns = M.Load()
  ns.Store.AddManual("Grimm")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut" })
  M.ClearFired(); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  eq(#M.Fired("ENEMY_SPOTTED"), 1, "ENEMY_SPOTTED:")
end)

test("B3 Taeter nur per GUID+Vorname bekannt (nie gesehen): spaetere Sichtung mit Nachnamen wird nicht erkannt", function()
  local ns = M.Load()
  M.units.fern = { exists = true, isPlayer = true, name = "Grimm", guid = "Player-93-G1", class = "ROGUE", classLoc = "Schurke" } -- nur fuer GetPlayerInfoByGUID
  recap(5, "Player-93-G1", nil)
  die()
  local d = M.Fired("DEATH_RECORDED")[1]; ok(d and d[3], "Kill gebucht:")
  M.units.fern = nil
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1" })
  M.ClearFired(); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  eq(#M.Fired("ENEMY_SPOTTED"), 1, "Schluessel war " .. tostring(d[3]) .. ", ENEMY_SPOTTED:")
end)

test("B4 Fremder mit gleichem Vornamen (andere GUID) wird dem Gelisteten angelastet", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); die()
  eq(ns.Store.Get("Grimm-Blut").kills, 1)
  M.units.nameplate1 = nil; M.Advance(300)
  M.units.fern = { exists = true, isPlayer = true, name = "Grimm", guid = "Player-93-G2", class = "MAGE", classLoc = "Magier" }
  recap(2, "Player-93-G2", nil); die()
  eq(ns.Store.Get("Grimm-Blut").kills, 1, "Kills von Grimm Blut (G1) nach Tod durch G2:")
  eq(ns.Store.Get("Grimm-Blut").guid, "Player-93-G1", "GUID von Grimm Blut:")
end)

test("B5 ConfirmSuspect ohne offenen Verdacht erhoeht kills trotzdem", function()
  local ns = M.Load()
  local k = ns.Store.AddManual("Grimm", "Blut")
  ns.Store.ConfirmSuspect(k); ns.Store.ConfirmSuspect(k)
  local e = ns.Store.Get(k); local sure = 0
  for _, d in ipairs(e.deaths) do if d.sure then sure = sure + 1 end end
  eq(e.kills, sure, "kills gegen Zahl sicherer Taten (" .. sure .. "):")
end)

test("B6 Zwei Chars in zwei Gilden loeschen sich gegenseitig die Gildenliste", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local G = ns.Guild
  local text = G.Proto.EncodeKill({ key = "Grimm-Blut", display = "Grimm Blut", class = "ROGUE", level = 40, zone = "Ort", t = M.epoch + M.now - 10, victim = "Kollege Eins" }, "K")
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", "Kollege-Forever")
  eq((G.Count()), 1)
  local db = _G.DeathNoteDB
  M.FireEvent("PLAYER_LOGOUT")
  ns = M.Load({ db = db, before = function() M.units.player.name = "Bohnenjockel"; M.units.player.guild = "Gilde Y" end })
  M.FireEvent("PLAYER_LOGOUT")
  ns = M.Load({ db = db, before = function() M.units.player.guild = "Gilde X" end })
  eq((ns.Guild.Count()), 1, "Gildenfeinde von Gilde X nach Twink-Login in Gilde Y:")
end)

test("B7 Tode eines anderen Chars des Accounts gehen an die Gilde des aktuellen Chars", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Blut" }, { t = M.epoch + M.now - 100, zone = "Ort", me = "Andererchar Twink", source = "recap" }, true)
  local got = {}
  for _, k in ipairs(ns.Guild.OwnKills(0)) do got[#got + 1] = k.victim end
  eq(#got, 0, "geteilte Tode fremder Chars (" .. table.concat(got, ",") .. "):")
end)

test("B8 Hallo eines zweiten Mitglieds innerhalb 60 s wird nicht beantwortet", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  ns.Store.ApplyKill({ name = "Grimm", surname = "Blut" }, { t = M.epoch + M.now - 100, zone = "Ort", me = "Varorak Narenmar", source = "recap" }, true)
  M.Advance(30); M.addonSent = {}
  local P = ns.Guild.Proto
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(M.epoch + M.now - 3 * 86400, "1.0.0"), "GUILD", "Anna-Forever")
  M.Advance(15)
  local first = #M.addonSent; ok(first >= 1, "Antwort an Anna:")
  M.addonSent = {}
  M.Advance(20) -- Berta loggt 20 s spaeter ein, hat Annas Antworten nicht gehoert
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(M.epoch + M.now - 3 * 86400, "1.0.0"), "GUILD", "Berta-Forever")
  M.Advance(15)
  ok(#M.addonSent >= 1, "Antwort an Berta (gesendet " .. #M.addonSent .. "):")
end)

test("B9 Import mit nan/inf als Zahl verdirbt Zaehler und Rangliste", function()
  local ns = M.Load()
  ns.Store.AddManual("Alt", "Feind")
  local txt = "DEATHNOTE:1\nE|Grimm-Blut|wanted|0|nan|0|0||||0||||||Blut||\nE|Zorn-Tal|wanted|0|inf|0|0||||0||||||Tal||"
  local okk = ns.Store.Import(txt)
  local a, b = ns.Store.Get("Grimm-Blut"), ns.Store.Get("Zorn-Tal")
  ok(not okk or (a.kills == a.kills and b.kills < 1e9), "Import angenommen, kills = " .. tostring(a and a.kills) .. " / " .. tostring(b and b.kills) .. ":")
end)

test("B10 AssignDeath auf einen Kandidaten, der nicht im Buch steht: Nachname/Anzeige/Klasse fehlen", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", class = "ROGUE", target = "player" })
  M.AddEnemy("nameplate2", { name = "Zorn", surname = "Tal", class = "MAGE", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  die()
  local j = ns.Store.Deaths()[1]; eq(#j.candidates, 2, "Kandidaten:")
  ok(ns.Store.AssignDeath(1, "Grimm-Blut"))
  local e = ns.Store.Get("Grimm-Blut")
  eq(ns.Util.TargetName(e), "Grimm Blut", "Name zum Anvisieren:")
  eq(e.class, "ROGUE", "Klasse:")
end)

test("B11 Ein Gildenmitglied kann mit frischen K-Nachrichten die Liste verdraengen und Meldungen fluten", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local G, P = ns.Guild, ns.Guild.Proto
  local t0 = M.epoch + M.now
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Echt-Feind", display = "Echt Feind", level = 40, zone = "Ort", t = t0 - 86400, victim = "Kollege Eins" }, "R"), "GUILD", "Kollege-Forever")
  M.ClearFired()
  for minute = 1, 4 do
    for i = 1, 150 do
      local n = (minute - 1) * 150 + i
      M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = ("Fake%s-Muell"):format(string.char(97 + n % 26, 97 + math.floor(n / 26) % 26, 97 + math.floor(n / 676) % 26)), level = 1, zone = "x", t = M.epoch + M.now, victim = "Irgendwer" }, "K"), "GUILD", "Stoerer-Forever")
    end
    M.Advance(61)
  end
  local kills = #M.Fired("GUILD_KILL")
  ok(G.Get("Echt-Feind") ~= nil and kills <= 10, ("echter Eintrag noch da: %s, GUILD_KILL-Meldungen von einem Absender in 4 Min.: %d;"):format(tostring(G.Get("Echt-Feind") ~= nil), kills))
end)

test("B12 Abgelehnte Duell-Anfrage (kein DUEL_FINISHED): PvP-Tod 5 Min. spaeter zaehlt nicht", function()
  local ns = M.Load()
  M.FireEvent("DUEL_REQUESTED", "Kumpel")
  M.Advance(300)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); die()
  local e = ns.Store.Get("Grimm-Blut")
  eq(e and e.kills or 0, 1, "Kill gebucht:")
end)

test("B13 Rache ueber 'X stirbt.' geht verloren, wenn ich ihn laenger als 15 s im Ziel habe", function()
  local ns = M.Load()
  local k = ns.Store.AddManual("Grimm", "Blut")
  M.AddEnemy("target", { name = "Grimm", surname = "Blut" }); M.FireEvent("PLAYER_TARGET_CHANGED")
  M.Advance(40)  -- langer Kampf, Ziel unveraendert
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "Grimm Blut stirbt.")
  eq(ns.Store.Get(k).revenge, 1, "Rache:")
end)

test("B14 Todesstoss durch feindlichen Begleiter (GUID Pet-...) ohne erkennbaren Besitzer wird PvE, Zielende werden ignoriert", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Jaeger", surname = "Wald", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Pet-0-93-1-2-3-0000", "Wolf"); die()
  local j = ns.Store.Deaths()[1]
  ok(j.kind ~= "pve" and #j.candidates >= 1, ("kind=%s, Kandidaten=%d;"):format(tostring(j.kind), #j.candidates))
end)

test("B15 Adopt eines Gildenfeinds ohne Nachnamen macht den Realm zum Nachnamen", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local P = ns.Guild.Proto
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Grimm-Forever", display = "Grimm", level = 40, zone = "Ort", t = M.epoch + M.now - 10, victim = "Kollege Eins" }, "R"), "GUILD", "Kollege-Forever")
  local k = ns.Guild.Adopt("Grimm-Forever"); ok(k)
  eq(ns.Util.TargetName(ns.Store.Get(k)), "Grimm", "Name zum Anvisieren:")
end)

test("B16 Umzug auf vollen Schluessel laesst Journal-Verweise haengen", function()
  local ns = M.Load()
  M.units.fern = { exists = true, isPlayer = true, name = "Grimm", guid = "Player-93-G1", class = "ROGUE", classLoc = "Schurke" }
  recap(5, "Player-93-G1", nil); die()
  local old = ns.Store.Deaths()[1].killerKey
  M.units.fern = nil; M.Advance(120)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(6, "Player-93-G1", "Grimm Blut"); die()
  local j = ns.Store.Deaths()[2]
  ok(ns.Store.Get(j.killerKey) ~= nil, ("Journal zeigt auf %s, Eintrag heisst jetzt %s;"):format(tostring(j.killerKey), tostring(ns.Store.Deaths()[1].killerKey)))
end)


---------------------------------------------------------------------------
-- Zusaetze zu den Funden (Testluecken laut Funde-Datei)
---------------------------------------------------------------------------
test("B1b Haengende Auswertung (Timer kam nie) wird nach 10 s verworfen", function()
  local ns = M.Load()
  local After = _G.C_Timer.After
  _G.C_Timer.After = function() end          -- the first evaluation never runs
  M.FireEvent("PLAYER_DEAD")
  ok(ns.Attribution.Pending(), "haengt")
  _G.C_Timer.After = After
  M.Advance(11)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(2, "Player-93-Grimm", "Grimm Blut")
  M.ClearFired(); die()
  eq(#M.Fired("DEATH_RECORDED"), 1)
end)

test("B1c Fehler in einer Stufe: Tod trotzdem gebucht (Verdacht), Fehler einmal gemeldet", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.recap = { id = 1, events = { setmetatable({}, { __index = function() error("unerwartet") end }) } }
  M.ClearFired(); die()
  eq(#M.Fired("DEATH_RECORDED"), 1)
  eq(ns.Store.Deaths()[1].source, "suspect")
  eq(#M.errors, 1, "einmal gemeldet")
  M.errors = {}
end)

test("B2b Freundlicher Spieler gleichen Vornamens uebernimmt den Platzhalter nicht", function()
  local ns = M.Load()
  ns.Store.AddManual("Grimm")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Freund", enemy = false, canAttack = false, faction = "Horde" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  ok(ns.Store.Get("Grimm-Forever")); no(ns.Store.Get("Grimm-Freund"))
end)

test("B2c Zwei Platzhalter gleichen Vornamens ohne GUID: keiner wird geraten", function()
  local ns = M.Load()
  local S = ns.Store
  S.AddManual("Grimm")
  S.ApplyKill({ name = "Grimm", guid = "Player-93-X" }, { t = 1 }, true) -- same key: GUID lands on the manual one
  eq(S.Get("Grimm-Forever").guid, "Player-93-X")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Anders", guid = "Player-93-Y" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  ok(S.Get("Grimm-Forever"), "GUID passt nicht: bleibt Platzhalter"); no(S.Get("Grimm-Anders"))
end)

test("B4b Rache per PARTY_KILL: Fremder gleichen Vornamens (andere GUID) ist nicht der Gelistete", function()
  local ns = M.Load()
  local S = ns.Store
  S.ApplyKill({ name = "Grimm", surname = "Blut", guid = "Player-93-G1" }, { t = 1 }, true)
  M.units.fern = { exists = true, isPlayer = true, name = "Grimm", guid = "Player-93-G2" }
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-G2")
  eq(S.Get("Grimm-Blut").revenge, 0)
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-G1")
  eq(S.Get("Grimm-Blut").revenge, 1)
end)

test("B6b Hoechstens 5 Gildenlisten, die am laengsten ungenutzte faellt raus; alte Form wird migriert", function()
  local old = { guild = { name = "Alt", enemies = { ["Gut-Feind"] = { deeds = { { t = M.epoch + 900, victim = "X Y", by = "X" } } } },
    members = { ["X-Forever"] = { name = "X", lastHeard = M.epoch + 900 } }, lastOnline = M.epoch + 500 } }
  local ns = M.Load({ db = old, before = function() M.units.player.guild = "Alt" end })
  eq((ns.Guild.Count()), 1, "alte Liste uebernommen")
  eq(#ns.Guild.Members(), 1)
  local db = _G.DeathNoteDB
  ok(db.guild.lists.Alt); eq(db.guild.lists.Alt.lastOnline, M.epoch + 500)
  for i = 1, 5 do
    M.Advance(10); M.FireEvent("PLAYER_LOGOUT")
    ns = M.Load({ db = db, keepWorld = true, before = function() M.units.player.guild = "Gilde" .. i end })
  end
  M.FireEvent("PLAYER_LOGOUT")
  eq(#ns.Guild.Lists(), 5); no(db.guild.lists.Alt, "aelteste raus")
  no(db.guild.enemies, "keine Doppelkopie in den SavedVariables")
end)

test("B8b Mehrere Hallos kurz hintereinander: eine Antwort je 10 s, keine geht verloren", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  ns.Store.ApplyKill({ name = "Grimm", surname = "Blut" }, { t = M.epoch + M.now - 100, zone = "Ort", me = "Varorak Narenmar", source = "recap" }, true)
  M.Advance(30); M.addonSent = {}
  local P = ns.Guild.Proto
  for i = 1, 5 do
    M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(M.epoch + M.now - 3 * 86400, "1.0.0"), "GUILD", "M" .. string.char(96 + i) .. "-Forever")
    M.Advance(3)
  end
  M.Advance(30)
  -- fix-2: jede Antwort endet mit einem Z (Momentaufnahme der Freigaben); gezaehlt werden die Taten
  -- (1.2.1: und mit einem Y, der Momentaufnahme der Kopfgelder)
  local n = 0
  for _, m in ipairs(M.addonSent) do if not m.text:match("^1\t[ZY]\t") then n = n + 1 end end
  ok(n >= 2 and n <= 3, "Antworten gebuendelt: " .. n)
end)

test("B11b Gleicher Absender, passende Opfer: GUILD_KILL hoechstens 3/min, hoechstens 40 Feinde, Verdraengen trifft den Groessten", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local G, P = ns.Guild, ns.Guild.Proto
  local t0 = M.epoch + M.now
  local function key(n) return ("Fake%s-Muell"):format(string.char(97 + n % 26, 97 + math.floor(n / 26) % 26, 97 + math.floor(n / 676) % 26)) end
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Echt-Feind", level = 40, zone = "Ort", t = t0 - 86400, victim = "Kollege Eins" }, "R"), "GUILD", "Kollege-Forever")
  M.ClearFired()
  for minute = 1, 4 do
    for i = 1, 100 do
      M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = key((minute - 1) * 100 + i), level = 1, zone = "x", t = M.epoch + M.now, victim = "Stoerer Eins" }, "K"), "GUILD", "Stoerer-Forever")
    end
    M.Advance(61)
  end
  ok(#M.Fired("GUILD_KILL") <= 12, "GUILD_KILL: " .. #M.Fired("GUILD_KILL"))
  eq((G.Count()), 41)
  -- 10 more members with 40 each: the list is full, the echt entry of the small member stays
  for s = 1, 10 do
    for i = 1, 40 do
      local nm = "S" .. string.char(96 + s)
      M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = key(1000 + s * 50 + i), level = 1, zone = "x", t = M.epoch + M.now - 500, victim = nm .. " X" }, "R"), "GUILD", nm .. "-Forever")
    end
    M.Advance(61)
  end
  eq((G.Count()), 400); ok(G.Get("Echt-Feind"), "echter Eintrag bleibt")
end)

test("B12b Tod 10 s nach einer Duell-Anfrage zaehlt nicht (Fenster 30 s)", function()
  local ns = M.Load()
  M.FireEvent("DUEL_REQUESTED", "Kumpel"); M.Advance(10)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); die()
  no(ns.Store.Get("Grimm-Blut")); eq(ns.Store.Deaths()[1].counted, false)
end)

test("B18 Mitglieder, von denen 60 Tage nichts kam, fallen beim Laden raus", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local db = _G.DeathNoteDB
  local L = db.guild.lists["Gilde X"]
  L.members["Alt-Forever"] = { name = "Alt", lastHeard = M.epoch + M.now - 61 * 86400 }
  L.members["Neu-Forever"] = { name = "Neu", lastHeard = M.epoch + M.now - 59 * 86400 }
  M.FireEvent("PLAYER_LOGOUT")
  ns = M.Load({ db = db, before = function() M.units.player.guild = "Gilde X" end })
  local m = ns.Guild.Members()
  eq(#m, 1); eq(m[1].name, "Neu")
end)

test("B19 Kampflog: Standard aus, alte DB wird umgestellt, beim Login keine Registrierung", function()
  M.Reset(); M.closedEvents = {}
  local ns = M.Load({ keepWorld = true, db = { version = 1, settings = { attribution = { combatlog = true } } } })
  _G.CombatLogGetCurrentEventInfo = function() end
  eq(ns.Store.Setting("attribution.combatlog"), false); eq(_G.DeathNoteDB.version, 3)
  ns.Attribution.Setup()
  for _, f in ipairs(M.frames) do no(f.events.COMBAT_LOG_EVENT_UNFILTERED, "nicht registriert") end
  ns.Probe.Run(false)
  for _, f in ipairs(M.frames) do no(f.events.COMBAT_LOG_EVENT_UNFILTERED, "Sonde registriert nicht") end
end)

test("B9b Import: Hex/Exponent/Zukunft/zu viele Zeilen abgelehnt, Schluessel kanonisch", function()
  local ns = M.Load(); local S = ns.Store
  ok(S.Import("DEATHNOTE:1\nE|grimm-blut|wanted|0|0x10|1e9|99999||||0||||||Blut||"))
  local e = S.Get("Grimm-Blut"); ok(e, "kanonischer Schluessel")
  eq(e.kills, 0); eq(e.suspected, 0); eq(e.revenge, 9999)
  no(S.Import("DEATHNOTE:1\nD|Grimm-Blut|" .. (time() + 3600) .. "|1|recap|||||||||"), "Zeit in der Zukunft")
  no(S.Import("DEATHNOTE:1\nE|Gr%7Cimm-Blut|wanted|0|1|0|0||||0||||||Blut||"), "| im Schluessel")
  no(S.Import("DEATHNOTE:1\n" .. ("\n"):rep(2001)), "zu viele Zeilen")
end)

test("Zusatz ENEMY_REKEYED: alter und neuer Schluessel, vor ENEMY_UPDATED", function()
  local ns = M.Load()
  ns.Store.AddManual("Grimm")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut" })
  M.ClearFired(); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  local r = M.Fired("ENEMY_REKEYED")
  eq(#r, 1); eq(r[1][2], "Grimm-Forever"); eq(r[1][3], "Grimm-Blut")
  local first
  for i, f in ipairs(M.fired) do if f[1] == "ENEMY_REKEYED" or f[1] == "ENEMY_UPDATED" then first = first or f[1] end end
  eq(first, "ENEMY_REKEYED")
end)

test("Zusatz Export(kurz): keine Tatenzeilen, Import liest beide Formen", function()
  local ns = M.Load(); local S = ns.Store
  for i = 1, 3 do S.ApplyKill({ name = "Grimm", surname = "Blut" }, { t = M.epoch + i, zone = "Z", source = "recap" }, true) end
  local short, full = S.Export(true), S.Export()
  no(short:find("\nD|", 1, true)); ok(full:find("\nD|", 1, true)); ok(#short < #full)
  local ns2 = M.Load(); local S2 = ns2.Store
  ok(S2.Import(short)); eq(S2.Get("Grimm-Blut").kills, 3); eq(#S2.Get("Grimm-Blut").deaths, 0)
  ok(S2.Import(full)); eq(#S2.Get("Grimm-Blut").deaths, 3)
end)

test("Zusatz Name ohne Steuerzeichen und | (Makro /targetexact), egal ueber welchen Weg", function()
  local ns = M.Load(); local S, U = ns.Store, ns.Util
  local k1 = S.AddManual("Gr|cffimm", "Bl\nut")
  local k2 = S.ApplyKill({ name = "Zo|Hrn", surname = "T|Tal" }, { t = 1 }, true)
  M.AddEnemy("nameplate1", { name = "Wi|rr", surname = "Ko\001pf" })
  S.AddManual("Wirr", "Kopf")
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  S.Import("DEATHNOTE:1\nE|Imp-Ort|wanted|0|1|0|0||||0||||||O%7Crt%0A||")
  for k, e in pairs(S.All()) do
    for _, f in ipairs({ e.name, e.surname, e.display, U.TargetName(e), k }) do
      no(tostring(f):find("[%c|]"), "sauber: " .. k)
    end
  end
  ok(k1 and k2)
end)

test("Zusatz E7/E8: Sichtung behaelt Rang-Cache, Gildenliste bleibt sortiert gecacht", function()
  local ns = M.Load({ before = function() M.units.player.guild = "G" end })
  local P = ns.Guild.Proto
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Grimm-Blut", level = 1, zone = "x", t = M.epoch + M.now - 9, victim = "Kollege A" }, "R"), "GUILD", "Kollege-Forever")
  -- 1.1.0: a hand entry with shareManual on is a real change of the guild list (listedBy);
  -- this test is about the personal list only, so sharing of hand entries is off here
  ns.Store.Setting("guild.shareManual", false)
  local list = ns.Guild.List("rank")
  no(list[1].mine)
  ns.Store.AddManual("Grimm", "Blut")
  ok(ns.Guild.List("rank") == list, "Cache bleibt"); ok(list[1].mine, "mine nachgezogen")
  ns.Store.Remove("Grimm-Blut")
  no(list[1].mine)
  eq(ns.Store.Rank("x"), nil)
end)

M.done("test_funde")
