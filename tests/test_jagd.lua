-- 1.2.0: hunt list (hit list). Release ("Put on hit list"), call off ("Call off the hunt"),
-- "taken down" by an own killing blow, reasons, caps, channels, old clients. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local GUILD = "Die Wurstbrüder"
local DIR = arg[0]:match("^(.*)/") or "."
-- the logic files of 1.1.0, unchanged, as the old client of the mixed tests
local BASE = DIR .. "/fixtures/addon-1.1.0/"
local OLD_FILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }

local function world(watch)
  M.Reset()
  return M.NewWorld(watch)
end
local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

local function chars(s) return select(2, s:gsub("[^\128-\191]", "")) end

---------------------------------------------------------------------------
-- Pure protocol
---------------------------------------------------------------------------
local P
do local W = world(); local a = W.client("A", "B", GUILD); P = a.ns.Guild.Proto end

test("Grund: Steuerzeichen, Farbcodes, Zeilenumbrüche raus, gekürzt auf 60 Zeichen", function()
  eq(P.CleanReason("  hat\nmich\tgeganked  "), "hat mich geganked")
  eq(P.CleanReason("|cffff0000rot|r und |Hitem:1|h[Ding]|h fertig"), "rot und [Ding] fertig")
  eq(P.CleanReason("a|Tpfad:0|tb"), "ab")
  eq(P.CleanReason("x||y"), "xy")
  eq(P.CleanReason(nil), ""); eq(P.CleanReason(12), "")
  local long = string.rep("ä", 80)
  local c = P.CleanReason(long)
  eq(chars(c), 60, "60 Zeichen"); ok(#c <= 120)
  -- UTF-8 at the cut: no broken character
  local mixed = string.rep("a", 59) .. "€€€"
  local m = P.CleanReason(mixed)
  eq(m, string.rep("a", 59) .. "€")
  ok(not m:find("[\192-\255]$"), "kein halbes Zeichen am Ende")
end)

test("J/A/E: kodieren, dekodieren, Grund beim Empfang gesäubert, Überlänge gekürzt", function()
  local t = time()
  local msg = P.EncodeHunt({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40, t = t,
    by = "Anton Wurst", why = "Hat mich 3x geganked" })
  ok(#msg <= 255)
  local m = P.Decode(msg, t, {})
  eq(m.kind, "J"); eq(m.key, "Grimm-Bart"); eq(m.by, "Anton Wurst"); eq(m.why, "Hat mich 3x geganked"); eq(m.class, "MAGE")
  -- a reason with codes and line breaks written by hand into the wire: cleaned, not dropped
  local raw = "1\tJ\tGrimm-Bart\t\tMAGE\t40\t" .. t .. "\tAnton Wurst\t%7Ccffff0000Rot%7Cr%0Aweiter"
  m = P.Decode(raw, t, {})
  ok(m, "angenommen"); eq(m.why, "Rot weiter")
  -- over-long reason on the wire: cut to 60 characters
  raw = "1\tJ\tGrimm-Bart\t\t\t0\t" .. t .. "\tAnton Wurst\t" .. string.rep("x", 100)
  m = P.Decode(raw, t, {})
  eq(#m.why, 60)
  -- a long display name and a long reason still fit into 255 bytes
  local big = P.EncodeHunt({ key = "Abcdefghijklmnopqrstuvwxyzabcdefg-Abcdefghijklmnopqrstuvwxyzabcd", t = t,
    display = "Abcdefghijklmnopqrstuvwxyzabcdefg Abcdefghijklmnopqrstuvwxyzabcd",
    by = "Abcdefghijklmnopqrstuvwxyzabcdefgh Abcdefghijklmnopqrstuvwxyzab", why = string.rep("%|ü", 30) })
  ok(big and #big <= 255, "passt")
  ok(P.Decode(big, t, {}), "und ist lesbar")
  local a = P.Decode(P.EncodeCallOff("Grimm-Bart", "Anton Wurst"), t, {})
  eq(a.kind, "A"); eq(a.by, "Anton Wurst")
  local e = P.Decode(P.EncodeBagged("Grimm-Bart", "Anton Wurst", t), t, {})
  eq(e.kind, "E"); eq(e.t, t)
  no(P.Decode("1\tE\tGrimm-Bart\tAnton Wurst\tabc", t, {}), "Zeit kaputt")
end)

---------------------------------------------------------------------------
-- Two and three clients
---------------------------------------------------------------------------
local function guildOf3()
  local W = world({ "GUILD_KILL", "GUILD_UPDATED", "GUILD_ENEMY_SPOTTED", "HUNT_BAGGED" })
  local a = W.client("Anton", "Wurst", GUILD)
  local b = W.client("Berta", "Senf", GUILD)
  local c = W.client("Cäsar", "Kraut", GUILD)
  a.login(); b.login(); c.login()
  W.run(60)
  return W, a, b, c
end

test("Zwei geben dasselbe Ziel frei, einer bläst ab: Ziel bleibt; der letzte bläst ab: weg", function()
  local W, a, b, c = guildOf3()
  ok(a.ns.Guild.Release("Grimm-Bart", { why = "Camper" }))
  W.run(3)
  ok(b.ns.Guild.Release("Grimm-Bart"))
  W.run(3)
  local r = c.ns.Guild.Hunt("Grimm-Bart", "all")
  ok(r, "bei C auf der Liste"); eq(r.n, 2); eq(r.why, "Camper")
  eq(r.names[1], "Anton Wurst"); eq(r.names[2], "Berta Senf")
  -- nobody can call off a release of somebody else
  no(c.ns.Guild.CallOff("Grimm-Bart"), "C hat nichts freigegeben")
  c.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeCallOff("Grimm-Bart", "Anton Wurst"), "GUILD", "Cäsar-Forever")
  eq(b.ns.Guild.Hunt("Grimm-Bart", "all").n, 2, "fremdes Abblasen verworfen")
  ok(a.ns.Guild.CallOff("Grimm-Bart"))
  W.run(3)
  r = c.ns.Guild.Hunt("Grimm-Bart", "all")
  ok(r, "bleibt"); eq(r.n, 1); eq(r.names[1], "Berta Senf")
  ok(b.ns.Guild.CallOff("Grimm-Bart"))
  W.run(3)
  no(c.ns.Guild.Hunt("Grimm-Bart", "all"), "weg")
  no(a.ns.Guild.Hunt("Grimm-Bart", "all"))
  noErrors()
end)

test("Freigabe nur an Freunde erreicht die Gilde nicht und umgekehrt", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Fritz" } })
  local g = W.client("Gustav", "Gans", GUILD)
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton" } })
  a.login(); g.login(); f.login()
  W.run(90)
  eq(a.ns.Friends.PeerCount(), 1)
  ok(select(2, a.ns.Guild.Release("Nur-Freunde", { to = "friends" })))
  ok(a.ns.Guild.Release("Nur-Gilde", { to = "guild" }))
  W.run(5)
  ok(f.ns.Guild.Hunt("Nur-Freunde", "friends"), "Freund hat sie")
  no(f.ns.Guild.Hunt("Nur-Gilde", "all"), "Freund hat die Gilden-Freigabe nicht")
  ok(g.ns.Guild.Hunt("Nur-Gilde", "guild"), "Gilde hat sie")
  no(g.ns.Guild.Hunt("Nur-Freunde", "all"), "Gilde hat die Freunde-Freigabe nicht")
  -- "all": both
  local dg, df = a.ns.Guild.Release("Fuer-Alle")
  ok(dg and df)
  W.run(5)
  ok(f.ns.Guild.Hunt("Fuer-Alle", "all")); ok(g.ns.Guild.Hunt("Fuer-Alle", "all"))
  eq(a.ns.Guild.Hunt("Fuer-Alle", "all").src, "both")
  eq(a.ns.Guild.Hunt("Fuer-Alle", "all").n, 1, "eigene Freigabe in beiden Listen zählt einmal")
  noErrors()
end)

test("Fremder Char im Feld, Flut, Deckel je Absender und gesamt", function()
  local W, a, b = guildOf3()
  local t = time()
  -- B claims a release of somebody else
  a.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeHunt({ key = "Grimm-Bart", t = t, by = "Cäsar Kraut" }), "GUILD", "Berta-Forever")
  no(a.ns.Guild.Hunt("Grimm-Bart", "guild"), "Char passt nicht zum Absender")
  eq(a.ns.Guild.stats.lastReason, "by")
  -- per sender: at most 10 releases
  for i = 1, 25 do
    a.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeHunt({ key = "Ziel" .. i .. "-Nr", t = t, by = "Berta Senf" }), "GUILD", "Berta-Forever")
  end
  eq(a.ns.Guild.HuntCount("guild"), a.ns.Guild.C.HUNT_PER_SENDER, "Deckel je Absender")
  -- total: 100 targets per list
  local hunts = {}
  for i = 1, 150 do
    P.MergeHunt(hunts, { key = "Z" .. i .. "-X", name = "Z" .. i, surname = "X", t = t, by = "K" .. i .. " Y" },
      { maxPerSender = 10, maxTotal = 100 })
  end
  local n = 0
  for _ in pairs(hunts) do n = n + 1 end
  eq(n, 100, "Deckel gesamt")
  -- flood: more than 150 messages a minute from one member are dropped
  local before = a.ns.Guild.stats.dropped
  for i = 1, 200 do
    a.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeCallOff("Gibt-Es-Nicht", "Berta Senf"), "GUILD", "Berta-Forever")
  end
  ok(a.ns.Guild.stats.dropped - before >= 50, "Drossel")
  noErrors()
end)

test("Hallo-Antwort bringt Freigaben, verpasstes Abblasen wird nachgereicht", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD)
  a.login(); W.run(30)
  ok(a.ns.Guild.Release("Grimm-Bart", { why = "Camper" }))
  ok(a.ns.Guild.Release("Fies-Ling"))
  ok(a.ns.Guild.CallOff("Fies-Ling"))
  W.run(5)
  local b = W.client("Berta", "Senf", GUILD)
  b.login(); W.run(60)
  local r = b.ns.Guild.Hunt("Grimm-Bart", "guild")
  ok(r, "Freigabe aus der Antwort"); eq(r.why, "Camper")
  no(b.ns.Guild.Hunt("Fies-Ling", "guild"))
  -- B knew Fies-Ling from earlier (missed the call-off): the answer takes it back
  local c = W.client("Cäsar", "Kraut", GUILD)
  c.login()
  c.ns.Guild.Proto.MergeHunt(c.ns.Guild.DB().lists[GUILD].hunts, { key = "Fies-Ling", name = "Fies", surname = "Ling",
    t = time() - 100, by = "Anton Wurst" })
  W.run(60)
  no(c.ns.Guild.Hunt("Fies-Ling", "guild"), "nachgereichtes Abblasen")
  noErrors()
end)

test("Erlegt: eigener Todesstoß auf ein Ziel, Meldung bei allen genau einmal", function()
  local W = world({ "HUNT_BAGGED" })
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Fritz" } })
  local b = W.client("Berta", "Senf", GUILD)
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton" } })
  a.login(); b.login(); f.login()
  W.run(90)
  ok(b.ns.Guild.Release("Grimm-Bart"))
  local dg, df = a.ns.Guild.Release("Grimm-Bart")
  ok(dg and df)
  W.run(5)
  ok(f.ns.Guild.Hunt("Grimm-Bart", "friends"))
  -- A kills him: PARTY_KILL with A's GUID; the tracker knows the GUID
  M.units.grimm = { exists = true, isPlayer = true, name = "Grimm", surname = "Bart", guid = "Player-1-GRIMM",
    class = "MAGE", level = 40, enemy = true, canAttack = true }
  a.ns.Tracker.OnUnit("grimm", "target")
  a.fire("PARTY_KILL", "Player-1-Anton", "Player-1-GRIMM")
  a.fire("PARTY_KILL", "Player-1-Anton", "Player-1-GRIMM")       -- the same kill twice (two events)
  W.run(5)
  local function bagged(c)
    local n = 0
    for _, e in ipairs(c.events) do if e[1] == "HUNT_BAGGED" then n = n + 1 end end
    return n
  end
  eq(bagged(a), 1, "A: eine Meldung"); eq(bagged(b), 1, "B: eine Meldung"); eq(bagged(f), 1, "Freund: eine Meldung")
  local r = b.ns.Guild.Hunt("Grimm-Bart", "all")
  eq(r.bagged, 1); eq(r.lastBagged.by, "Anton Wurst")
  eq(a.ns.Guild.Hunt("Grimm-Bart", "all").bagged, 1, "eigener Kill in beiden Listen zählt einmal")
  ok(r, "bleibt auf der Liste nach dem Erlegen")
  -- a kill by somebody else (not me) is not mine to report
  a.fire("PARTY_KILL", "Player-1-Berta", "Player-1-GRIMM")
  W.run(5)
  eq(bagged(b), 1)
  -- not on the list: nothing
  M.units.other = { exists = true, isPlayer = true, name = "Andrer", surname = "Kerl", guid = "Player-1-OTHER",
    class = "MAGE", level = 40, enemy = true, canAttack = true }
  a.ns.Tracker.OnUnit("other", "target")
  a.fire("PARTY_KILL", "Player-1-Anton", "Player-1-OTHER")
  W.run(5)
  eq(bagged(a), 1)
  noErrors()
end)

test("Alarm für Ziele der Abschussliste (eigener Schalter, Standard an)", function()
  local W = world({ "GUILD_ENEMY_SPOTTED" })
  local a = W.client("Anton", "Wurst", GUILD)
  local b = W.client("Berta", "Senf", GUILD)
  a.login(); b.login(); W.run(60)
  ok(a.ns.Guild.Release("Grimm-Bart"))
  W.run(5)
  ok(b.ns.Tracker.guildHook, "Haken aktiv")
  b.ns.Guild.OnUnit("Grimm-Bart", "nameplate1", "nameplate", false)
  local last = b.events[#b.events]
  ok(last and last[1] == "GUILD_ENEMY_SPOTTED", "Alarm"); eq(last and last[5], "hunt", "als Ziel der Abschussliste")
  b.ns.Store.Setting("guild.alertHunt", false)
  M.Advance(1)
  local n = #b.events
  b.ns.Guild.OnUnit("Grimm-Bart", "nameplate1", "nameplate", false)
  eq(#b.events, n, "abgeschaltet: kein Alarm")
  noErrors()
end)

test("1.1.0 empfängt die neuen Typen und bleibt still", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD)
  local o = W.client("Olaf", "Alt", GUILD, { dir = BASE, files = OLD_FILES, version = "1.1.0" })
  a.login(); o.login(); W.run(60)
  local count0 = o.ns.Guild.Count()
  ok(a.ns.Guild.Release("Grimm-Bart", { why = "Camper" }))
  ok(a.ns.Guild.CallOff("Grimm-Bart"))
  o.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeBagged("Grimm-Bart", "Anton Wurst", time()), "GUILD", "Anton-Forever")
  W.run(5)
  eq(o.ns.Guild.Count(), count0, "nichts angelegt")
  eq(o.ns.Guild.stats.lastReason, "type")
  for _, e in ipairs(o.events) do no(e[1] == "GUILD_KILL", "keine Meldung") end
  noErrors()
end)

test("Release ohne Gilde und ohne Freunde geht nicht, /dn jagd und /dn abblasen", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil)
  a.login(); W.run(30)
  a.ns.Store.Setting("guild.friends", false)
  local r, why = a.ns.Guild.Release("Grimm-Bart")
  eq(r, nil); eq(why, "none")
  local W2 = world()
  local b = W2.client("Berta", "Senf", GUILD)
  b.login(); W2.run(30)
  b.ns.HandleSlash("jagd Grimm Bart")
  ok(b.ns.Guild.Hunt("Grimm-Bart", "guild"), "/dn jagd Name Nachname")
  b.ns.HandleSlash("jagd Grimm")
  eq(b.ns.Guild.HuntCount("guild"), 1, "Vorname reicht, wenn eindeutig")
  b.ns.HandleSlash("abblasen Grimm")
  eq(b.ns.Guild.HuntCount("guild"), 0)
  b.ns.HandleSlash("jagd Niemand")
  eq(b.ns.Guild.HuntCount("guild"), 0, "nur Vorname und unbekannt: nichts")
  noErrors()
end)

M.done("test_jagd")
