-- Rap sheet (1.3.0): fixes after the bug hunt on the rap sheet (rule "me", import, detection, duel, keys, caps,
-- clock, ranks). One block per finding; every test was red before its fix. All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"
local LINE = " stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre."

local ns, plate = nil, 0
local function fresh(level, opts)
  _G.DeathNoteDB = nil
  ns = M.Load(opts); plate = 0
  M.units.player.level = level or 40
  return ns
end
local function load(db, level)
  ns = M.Load({ db = db }); plate = 0
  M.units.player.level = level or 40
  return ns
end
local function reload(level) return load(_G.DeathNoteDB, level) end
local function seen(name, surname, level, o)
  plate = plate + 1
  o = o or {}
  o.name, o.surname, o.level = name, surname, level or 40
  o.guid = o.guid or ("Player-93-" .. name .. (surname or ""))
  M.AddEnemy("nameplate" .. plate, o)
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return o.guid
end
local function kill(guid, attacker) M.FireEvent("PARTY_KILL", attacker or ME, guid) end
local function dieBy(guid, name)
  M.recap = { id = math.random(1, 1e6), events = { { sourceGUID = guid, sourceName = name, amount = 900, overkill = 120,
    timestamp = time() - 1, spellName = "Hieb" } } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
end
-- a book entry of version 3 as 1.2.x writes it
local function entry(name, surname, kills, revenge, extra)
  local e = { name = name, surname = surname, display = surname and (name .. " " .. surname) or nil, kills = kills,
    assists = 0, suspected = 0, revenge = revenge, status = "wanted", manual = false, note = "", sightings = 1,
    deaths = {}, lastRevenge = 1700000000 }
  for k, v in pairs(extra or {}) do e[k] = v end
  return e
end
-- the bounty of 1.2.x: the same function with the rap sheet switched off (it then reads revenge)
local function oldBounty(e)
  local Lg = ns.Ledger
  ns.Ledger = nil
  local x = ns.Store.Bounty(e)
  ns.Ledger = Lg
  return x
end
local function standing(key)
  local m, h, s = ns.Ledger.Standing(key)
  return tostring(m) .. ":" .. tostring(h) .. " " .. tostring(s)
end

---------------------------------------------------------------------------
-- "me" = max(own kills, recognised revenge + kills before he was listed) + by hand (findings 2, 7, 8, 9, E11)
---------------------------------------------------------------------------
test("Revenge without an own killing blow (pvpkills): standing and bounty at once, nothing jumps at a reload", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g }, { t = time() - 100 }, true)
  M.units.target = M.units.nameplate1; M.FireEvent("PLAYER_TARGET_CHANGED")
  kill(g, "Player-93-Kollege")                     -- a guildmate has the killing blow
  M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
  local e = ns.Store.Get("Grimm-Bart")
  eq(e.revenge, 1, "the book counts it as before"); eq(ns.Attribution.lastRevengeHow, "pvpkills")
  eq(standing("Grimm-Bart"), "1:1 even", "the book's revenge counts for the standing")
  eq(ns.Store.Bounty(e), oldBounty(e), "bounty as in 1.2.x")
  eq(ns.Ledger.Victim("Grimm-Bart"), nil, "no own kill booked")
  reload()
  eq(standing("Grimm-Bart"), "1:1 even", "the same after a reload")
  eq(ns.Ledger.Repute().total, 0, "no repute for a kill that was not mine")
  eq(ns.Ledger.Repute().n, 0)
end)

test("Up, back, up: the book entry moved under 1.2.x; the victim follows by GUID, nothing is booked twice", function()
  fresh()
  M.units.x1 = { exists = false, guid = "Player-93-G1", name = "Grimm", class = "ROGUE", classLoc = "Schurke" }
  ns.Store.ApplyKill({ name = "Grimm", guid = "Player-93-G1" }, { t = time() - 100 }, true)
  kill("Player-93-G1"); M.Advance(700); kill("Player-93-G1")
  local key = next(ns.Store.All())
  eq((ns.Ledger.Standing(key)), 2)
  local before = ns.Ledger.Repute().total
  -- what 1.2.x writes when it moves the entry (Store.Promote there): new key, surname, nothing else
  local db = _G.DeathNoteDB
  local e = db.enemies[key]; db.enemies[key] = nil
  e.surname, e.display = "Bart", "Grimm Bart"; db.enemies["Grimm-Bart"] = e
  reload()
  eq((ns.Ledger.Standing("Grimm-Bart")), 2, "own kills after up, back, up")
  eq(ns.Ledger.Repute().total, before, "accounts unchanged")
  eq(ns.Ledger.Repute().n, 2)
  local v = ns.Ledger.Victim("Grimm-Bart")
  ok(v, "the victim moved to the book's key"); eq(v and v.n, 2); eq(ns.Ledger.Victim(key), nil)
  local snap = ns.Ledger.Repute().total
  for _ = 1, 5 do ns.Store.Init() end
  eq(ns.Ledger.Repute().total, snap)
end)

test("Up, back, up: revenge 1.2.x recognised on top of kills before he was listed reaches the standing", function()
  fresh()
  local a = seen("Anna", "Ast", 40)
  kill(a); M.Advance(700); seen("Anna", "Ast", 40, { guid = a }); kill(a)
  for i = 1, 3 do ns.Store.ApplyKill({ name = "Anna", surname = "Ast", guid = a }, { t = time() + i }, true) end
  eq(standing("Anna-Ast"), "2:3 open")
  local e = _G.DeathNoteDB.enemies["Anna-Ast"]   -- 1.2.x recognises one revenge
  e.revenge = e.revenge + 1; e.revengeAutoAt = time(); e.lastRevenge = time()
  reload()
  eq(standing("Anna-Ast"), "3:3 even")
end)

test("Striking a victim from the rap sheet never raises the bounty of a listed enemy", function()
  fresh()
  local a = seen("Anna", "Ast", 40)
  ns.Store.ApplyKill({ name = "Anna", surname = "Ast", guid = a }, { t = time() - 50 }, true)
  kill(a)
  local e = ns.Store.Get("Anna-Ast")
  eq(e.revenge, 1)
  local b = oldBounty(e)
  eq(ns.Store.Bounty(e), b)
  ok(ns.Ledger.RemoveVictim("Anna-Ast"))
  eq(ns.Store.Bounty(e), b, "after striking")
  eq(standing("Anna-Ast"), "1:1 even")
end)

test("The book's revenge never turns into repute at the start (30 enemies with 4 revenges: rank 1)", function()
  local db = { version = 3, settings = {}, deaths = {}, enemies = {} }
  for i = 1, 30 do
    local n = "R" .. string.char(97 + math.floor(i / 26)) .. string.char(97 + i % 26)
    db.enemies[n .. "-Alt"] = entry(n, "Alt", 5, 4, { guid = "Player-93-" .. n })
  end
  load(db)
  local r = ns.Ledger.Repute()
  eq(r.total, 0); eq(r.tier, 1); eq(r.n, 0); eq(ns.Ledger.VictimCount(), 0)
  eq((ns.Ledger.Standing("Rab-Alt")), 4, "me = the book's revenge")
  local e = _G.DeathNoteDB.enemies["Rab-Alt"]; e.revenge = 7         -- 1.2.x recognises three more
  reload()
  eq(ns.Ledger.Repute().total, 0); eq((ns.Ledger.Standing("Rab-Alt")), 7, "me = the book's revenge")
end)

---------------------------------------------------------------------------
-- Import (finding 1)
---------------------------------------------------------------------------
local function text(n, revenge)
  local lines = { "DEATHNOTE:1" }
  for i = 1, n do
    local key = "Fremd-Nr" .. string.char(65 + math.floor(i / 26)) .. string.char(65 + i % 26)
    lines[#lines + 1] = table.concat({ "E", key, "wanted", "0", "1", "0", tostring(revenge), "1700000000", "1700000000",
      "1700000000", "1", "ROGUE", "", "40", "", "", "", "", "", "0" }, "|")
  end
  return table.concat(lines, "\n")
end

test("Imported revenge never becomes repute, also after a reload (50 lines with revenge 10: rank 1)", function()
  fresh()
  ok(ns.Store.Import(text(50, 10)))
  reload()
  local r = ns.Ledger.Repute()
  eq(r.total, 0); eq(r.tier, 1); eq(r.n, 0)
end)

test("An imported entry has no 'me' from the file; the bounty reads it as 1.2.x, before and after a reload", function()
  fresh()
  ok(ns.Store.Import(text(1, 4)))
  local key = next(ns.Store.All())
  local e = ns.Store.Get(key)
  ok(e.imported)
  eq(e.revengeForeign, 4)
  eq((ns.Ledger.Standing(key)), 0, "me right after the import")
  eq(ns.Store.Bounty(e), oldBounty(e), "bounty right after the import")
  reload()
  e = ns.Store.Get(key)
  eq((ns.Ledger.Standing(key)), 0, "me after the reload")
  eq(ns.Store.Bounty(e), oldBounty(e), "bounty after the reload")
end)

test("Own revenge on an imported entry counts above the imported part; a merge only marks what the text added", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g }, { t = time() - 100 }, true)
  kill(g)
  eq(ns.Store.Get("Grimm-Bart").revenge, 1)
  ok(ns.Store.Import("DEATHNOTE:1\n" .. table.concat({ "E", "Grimm-Bart", "wanted", "0", "3", "0", "3", "1700000000",
    "1700000000", "1700000000", "1", "ROGUE", "", "40", "", "", "Bart", "", "", "0" }, "|")))
  local e = ns.Store.Get("Grimm-Bart")
  eq(e.revenge, 3); eq(e.revengeForeign, 2, "the text added two")
  eq(standing("Grimm-Bart"), "1:3 open", "me = my one kill")
  eq(ns.Store.Bounty(e), oldBounty(e))
  M.Advance(700); seen("Grimm", "Bart", 40, { guid = g }); kill(g)
  eq(e.revenge, 4); eq(standing("Grimm-Bart"), "2:3 open")
end)

test("Counts from a broken file are capped in the standing and never become own kills", function()
  local db = { version = 3, settings = {}, deaths = {}, enemies = { ["Viel-Zuviel"] = entry("Viel", "Zuviel", 2, 1e15) } }
  load(db)
  local m = ns.Ledger.Standing("Viel-Zuviel")
  eq(m, 9999); eq(ns.Ledger.Repute().n, 0); eq(ns.Ledger.Victim("Viel-Zuviel"), nil)
  reload()
  eq(ns.Ledger.Repute().n, 0)
end)

---------------------------------------------------------------------------
-- Honour line fallback off until measured (finding 3)
---------------------------------------------------------------------------
test("A stranger outside the group has the killing blow: the honour line alone books nothing, the probe counts it", function()
  fresh()
  eq(ns.Ledger.HONOR_FALLBACK, false, "off by default")
  ns.Store.Setting("debug", true)
  seen("Opfer", "Fremd", 40)
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Opfer Fremd" .. LINE); M.Advance(3)
  eq(ns.Ledger.Victim("Opfer-Fremd"), nil); eq(ns.Ledger.Repute().n, 0)
  local c = ns.Ledger.probeCounts
  eq(c.honorAlone, 1, "the probe still counts the line"); eq(c.rejected["fallback-off"], 1)
  eq(_G.DeathNoteDB.probe.kills.cases[1].result, "fallback-off")
end)

test("A raid member kills a never seen enemy: the honour line books nothing", function()
  fresh()
  M.units.raid1 = { exists = true, isPlayer = true, name = "Kollege" }
  kill("Player-93-NieGesehen", "Player-93-Kollege")
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Weit Weg" .. LINE); M.Advance(3)
  eq(ns.Ledger.Repute().n, 0)
end)

---------------------------------------------------------------------------
-- Duel to the death: request expires, ends on finish, zone, death; GUID or full name only (finding 4)
---------------------------------------------------------------------------
test("A challenge to the death nobody answers is let go after 60 s: his kill on me 5 min later is in the book", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  _G.GetDuelerInfo = function() return g end
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
  _G.GetDuelerInfo = nil
  ok(ns.Attribution.DuelFoe(g), "held out right after the challenge")
  M.Advance(300)                                    -- nothing asks in between: the death itself must let go
  seen("Grimm", "Bart", 40, { guid = g })
  dieBy(g, "Grimm Bart")
  local e = ns.Store.Get("Grimm-Bart")
  ok(e, "book entry after the death"); eq(e and e.kills, 1)
end)

test("Without a GUID only the full name is the opponent; a first name alone holds nobody out", function()
  fresh()
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
  local other = seen("Grimm", "Anders", 40, { guid = "Player-93-ANDERER" })
  no(ns.Attribution.DuelFoe(other, "Grimm"), "a namesake")
  no(ns.Attribution.DuelFoe(nil, "Grimm"), "the first name alone")
  ok(ns.Ledger.OnPartyKill(ME, other), "my kill on the namesake counts")
  M.Advance(70)
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm Bart")
  local g = seen("Grimm", "Bart", 40)
  ok(ns.Attribution.DuelFoe(g, "Grimm Bart"), "the full name")
  ok(ns.Attribution.DuelFoe(g), "his GUID, the full name from the tracker")
  no(ns.Attribution.DuelFoe(other, "Grimm Anders"), "the namesake with his full name")
  no(ns.Attribution.DuelFoe(other), "the namesake by GUID")
  M.Advance(59); ok(ns.Attribution.DuelFoe(g), "not started, 59 s: still held")
  M.Advance(2); no(ns.Attribution.DuelFoe(g), "not started, 61 s: let go")
end)

test("An accepted duel holds for 15 min at most; DUEL_FINISHED, a loading screen and a death end it (30 s grace)", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  local function challenge()
    _G.GetDuelerInfo = function() return g end
    M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
    _G.GetDuelerInfo = nil
  end
  challenge(); M.FireEvent("DUEL_INBOUNDS")
  M.Advance(120); ok(ns.Attribution.DuelFoe(g), "started: held beyond 60 s")
  M.Advance(781); no(ns.Attribution.DuelFoe(g), "let go after 15 min")
  for _, ending in ipairs({ "DUEL_FINISHED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_DEAD" }) do
    challenge()
    M.FireEvent(ending)
    M.Advance(29); ok(ns.Attribution.DuelFoe(g), ending .. ": grace")
    M.Advance(2); no(ns.Attribution.DuelFoe(g), ending .. ": ended")
  end
  challenge()
  kill(g)                                           -- he dies: the duel's death, the duel is over
  eq(ns.Ledger.Victim("Grimm-Bart"), nil, "no rap sheet kill")
  M.Advance(31)
  no(ns.Attribution.DuelFoe(g), "over after his death")
end)

---------------------------------------------------------------------------
-- Placeholders per GUID, a complete move (findings 5 and 14)
---------------------------------------------------------------------------
test("Two GUIDs, one first name, both never seen: two victims; each moves to his own full name", function()
  fresh()
  M.units.x1 = { exists = false, guid = "Player-93-G1", name = "Grimm", class = "ROGUE", classLoc = "Schurke" }
  M.units.x2 = { exists = false, guid = "Player-93-G2", name = "Grimm", class = "MAGE", classLoc = "Magier" }
  ok(ns.Ledger.OnPartyKill(ME, "Player-93-G1")); M.Advance(60)
  ok(ns.Ledger.OnPartyKill(ME, "Player-93-G2")); M.Advance(60)
  eq(ns.Ledger.VictimCount(), 2, "two placeholders")
  ok(ns.Ledger.OnPartyKill(ME, "Player-93-G2"), "the second again: his own placeholder")
  M.units.x1, M.units.x2 = nil, nil
  seen("Grimm", "Eins", 40, { guid = "Player-93-G1" }); M.Advance(20)
  local v = ns.Ledger.Victim("Grimm-Eins")
  ok(v, "Grimm Eins under his full name"); eq(v.n, 1); eq(v.class, "ROGUE")
  seen("Grimm", "Zwei", 40, { guid = "Player-93-G2" }); M.Advance(20)
  local w = ns.Ledger.Victim("Grimm-Zwei")
  ok(w, "Grimm Zwei under his full name"); eq(w.n, 2); eq(w.class, "MAGE"); eq(w.realm, "Zwei")
  eq(ns.Ledger.VictimCount(), 2)
  eq(ns.Tracker.ledgerHook, nil, "no placeholder left")
end)

test("A book placeholder with another GUID does not take a namesake's kill", function()
  fresh()
  M.units.x1 = { exists = false, guid = "Player-93-G1", name = "Grimm", class = "ROGUE" }
  ns.Store.ApplyKill({ name = "Grimm", guid = "Player-93-G0" }, { t = time() - 100 }, true)
  local bookKey = next(ns.Store.All())
  ok(ns.Ledger.OnPartyKill(ME, "Player-93-G1"))
  eq(ns.Ledger.Victim(bookKey), nil, "not under the book's placeholder of another GUID")
  eq(standing(bookKey), "0:1 open")
end)

test("The book's placeholder moves: the victim takes the surname, stops being a placeholder, the hook is free", function()
  -- a victim without GUID under the book's placeholder without GUID (an honour line naming the first name only)
  local db = { version = 4, settings = {}, deaths = {}, enemies = { ["Grimm-Forever"] = entry("Grimm", nil, 1, 0) },
    ledger = { victims = { ["Grimm-Forever"] = { name = "Grimm", n = 1, last = 1700000000 } } } }
  load(db)
  ok(ns.Ledger.Victim("Grimm-Forever"), "victim under the book's placeholder")
  ok(ns.Tracker.ledgerHook, "hook set while a placeholder is there")
  M.Advance(20)
  seen("Grimm", "Bart", 40)
  ok(ns.Store.Get("Grimm-Bart"), "the book moved the entry")
  local v = ns.Ledger.Victim("Grimm-Bart")
  ok(v, "the victim moved along"); eq(v.surname, "Bart"); eq(ns.Util.Display(v), "Grimm Bart")
  eq(ns.Tracker.ledgerHook, nil, "no placeholder left")
end)

---------------------------------------------------------------------------
-- Revenge only on a real debt (finding 6)
---------------------------------------------------------------------------
test("A grey entered by hand before the kill (he never killed me): infamy as without the entry", function()
  fresh(60)
  local a = seen("Klein", "Eins", 20)
  ns.Store.Upsert({ name = "Klein", surname = "Eins" }, true)
  eq(ns.Store.Get("Klein-Eins").kills, 0)
  eq(standing("Klein-Eins"), "0:0 open")
  kill(a)
  local row = ns.Ledger.Log()[1]
  eq(row.band, "grau"); no(row.f:find("v"), "no revenge flag"); eq(row.r, 4); eq(row.e, 0)
  local b = seen("Gross", "Zwei", 60)
  ns.Store.ApplyKill({ name = "Gross", surname = "Zwei", guid = b }, { t = time() - 50 }, true)
  M.Advance(20); kill(b)
  ok(ns.Ledger.Log()[1].f:find("v"), "with a debt: revenge")
end)

---------------------------------------------------------------------------
-- The cap of 200 victims (finding 10, capVictims without a quadratic search)
---------------------------------------------------------------------------
local function fullLedger(n, inBook)
  local db = { version = 4, settings = {}, deaths = {}, enemies = {}, ledger = { victims = {} } }
  for i = 1, n do
    local nm = "N" .. i
    db.ledger.victims[nm .. "-Alt"] = { name = nm, surname = "Alt", n = 1, last = 1600000000 + i, guid = "Player-93-" .. nm }
    if inBook then db.enemies[nm .. "-Alt"] = entry(nm, "Alt", 2, 1, { guid = "Player-93-" .. nm }) end
  end
  return db
end

test("Register full, every victim in the book: the new victim stays, kicking and wear work", function()
  load(fullLedger(200, true))
  eq(ns.Ledger.VictimCount(), 200)
  local g = seen("Frei", "Wild", 40)
  local rec
  ns:On("OWN_KILL", function(_, row) rec = row end)
  kill(g)
  ok(ns.Ledger.Victim("Frei-Wild"), "the victim just booked stays")
  eq(rec and rec.state, "victim", "OWN_KILL carries his state")
  eq(ns.Ledger.Victim("N1-Alt"), nil, "the oldest last kill went (all are in the book)")
  eq(ns.Ledger.VictimCount(), 200)
  M.Advance(15); seen("Frei", "Wild", 40, { guid = g }); kill(g)
  local row = ns.Ledger.Log()[1]
  ok(row.f:find("n"), "second kill after 15 s is kicking"); eq(row.e, 0); eq(ns.Ledger.Victim("Frei-Wild").n, 2)
end)

test("Register full: victims outside the book go first, the oldest first", function()
  local db = fullLedger(200, true)
  db.enemies["N1-Alt"] = nil; db.enemies["N7-Alt"] = nil
  load(db)
  kill(seen("Frei", "Wild", 40)); M.Advance(11)
  eq(ns.Ledger.Victim("N1-Alt"), nil, "outside the book, oldest")
  ok(ns.Ledger.Victim("N2-Alt"), "in the book, older than N7")
  kill(seen("Frei", "Zwei", 40))
  eq(ns.Ledger.Victim("N7-Alt"), nil, "the next outside the book")
  ok(ns.Ledger.Victim("N2-Alt"))
end)

test("A broken file with 5000 victims is cut to the 200 newest in one pass", function()
  load(fullLedger(5000, false))
  eq(ns.Ledger.VictimCount(), 200)
  ok(ns.Ledger.Victim("N5000-Alt")); ok(ns.Ledger.Victim("N4801-Alt")); eq(ns.Ledger.Victim("N4800-Alt"), nil)
end)

---------------------------------------------------------------------------
-- A clock set back gives no fresh points (finding 11)
---------------------------------------------------------------------------
test("Six kills on the same enemy, the clock set back a day before each: no fresh honour, the window goes on", function()
  fresh()
  local c = seen("Freund", "Feind", 40)
  for _ = 1, 6 do
    kill(c)
    M.epoch = M.epoch - 100000; M.Advance(15); seen("Freund", "Feind", 40, { guid = c })
  end
  local v = ns.Ledger.Victim("Freund-Feind")
  eq(v.n, 6, "all six count for the standing")
  eq(ns.Ledger.Repute().acc.e, 3, "only the first earns honour"); eq(v.dn, 6, "one window")
  ok(v.last >= v.first, "last kill never before the first")
  M.epoch = M.epoch + 700000                         -- the clock is right again, a day after the first kill
  seen("Freund", "Feind", 40, { guid = c }); kill(c)
  eq(ns.Ledger.Log()[1].e, 3, "a new day: full honour again"); eq(v.dn, 1)
end)

---------------------------------------------------------------------------
-- Tier 3 and above always has a path and a name (finding 12)
---------------------------------------------------------------------------
test("Tier 3 before the tenth counted kill: a path, a rank name, REPUTE_RANK with the path", function()
  fresh(20)
  local ranks, paths = {}, {}
  ns:On("REPUTE_RANK", function(...) ranks[#ranks + 1] = { ... } end)
  ns:On("REPUTE_PATH", function(...) paths[#paths + 1] = { ... } end)
  for i = 1, 4 do kill(seen("Hoch" .. string.char(64 + i), "Tier", 35)); M.Advance(20) end
  local r = ns.Ledger.Repute()
  eq(r.tier, 3); eq(r.total, 40); eq(r.path, "j"); eq(r.counted, 4)
  ok(ns.Ranks.Name(r.tier, r.path), "a rank name")
  for _, x in ipairs(ranks) do
    if x[1] >= 3 then ok(x[2] ~= nil, "REPUTE_RANK(" .. x[1] .. ") with a path") end
  end
  eq(#ranks, 2, "tier 2, 3"); eq(ranks[2][2], "j"); eq(#paths, 1, "the path once"); eq(paths[1][1], "j"); eq(paths[1][3], 3)
end)

test("Ranks.Title reads a broken tier as the nearest real one", function()
  fresh()
  eq(ns.Ranks.Title(11, "e", "notebook", "enUS"), ns.Ranks.Title(10, "e", "notebook", "enUS"))
  eq(ns.Ranks.Title(nil, nil, "notebook", "enUS"), "Blank Page")
  eq(ns.Ranks.Title(0 / 0, nil, "notebook", "enUS"), "Blank Page")
end)

test("Simulate: from tier 3 on there is always a path (any mix of bands, 2000 random lists)", function()
  fresh()
  local L = ns.Ledger
  math.randomseed(1312)
  for _ = 1, 2000 do
    local list = {}
    for i = 1, math.random(1, 14) do
      list[i] = { L.BANDS[math.random(#L.BANDS)], { revenge = math.random(4) == 1, group = math.random(3) == 1,
        nthToday = math.random(1, 6), kick = math.random(6) == 1 } }
    end
    local bad
    L.Simulate(list, function(i, acc, mood, counted, path)
      local t = L.Tier(acc.r + acc.e + acc.j + acc.s)
      if t >= 3 and not path then bad = i end
    end)
    if bad then ok(false, "no path at tier 3+ after kill " .. bad); break end
  end
end)

---------------------------------------------------------------------------
-- Bonuses against the real guild book, hit list and bounties (finding 13)
---------------------------------------------------------------------------
local function grimmWorld()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", "Die Testgilde")
  local b = W.client("Berta", "Senf", "Die Testgilde")
  a.login(); b.login(); W.run(90)
  M.units.grimm = { exists = true, isPlayer = true, name = "Grimm", surname = "Bart", guid = "Player-1-GRIMM",
    class = "MAGE", level = 43, enemy = true, canAttack = true, faction = "Alliance" }
  return W, a, b
end
local function grimmKills(c, W)
  c.ns.Tracker.OnUnit("grimm", "target")
  M.recap = { id = math.random(1, 1e6), events = { { sourceGUID = "Player-1-GRIMM", sourceName = "Grimm Bart",
    amount = 900, overkill = 100, timestamp = time() - 1, spellName = "Hieb" } } }
  c.fire("PLAYER_DEAD"); W.run(10)
end

test("Real guild book, hit list and bounty of a guildmate: protection, hit list and bounty (flags s, h, b)", function()
  local W, a, b = grimmWorld()
  grimmKills(b, W)                                   -- he killed my guildmate: a deed in the guild book
  ok(b.ns.Guild.SetBounty("Grimm-Bart", 300)); ok(b.ns.Guild.Release("Grimm-Bart")); W.run(10)
  a.ns.Tracker.OnUnit("grimm", "target")
  a.fire("PARTY_KILL", W.guidOf(a), "Player-1-GRIMM"); W.run(5)
  local row = a.ns.Ledger.Log()[1]
  eq(row.band, "orange"); eq(row.f, "shb"); eq(row.s, 4); eq(row.j, 3 + 3 + 5); eq(row.r, 0)
  eq(#M.errors, 0, M.errors[1])
end)

test("Own release, own bounty and my own death by him: no hit list, no bounty, no protection", function()
  local W, a = grimmWorld()
  grimmKills(a, W)                                   -- he killed me: revenge, but no protection
  ok(a.ns.Guild.SetBounty("Grimm-Bart", 300)); ok(a.ns.Guild.Release("Grimm-Bart")); W.run(10)
  ok(a.ns.Guild.Hunt("Grimm-Bart", "all"), "my release stands on the list")
  W.run(30)
  a.ns.Tracker.OnUnit("grimm", "target")
  a.fire("PARTY_KILL", W.guidOf(a), "Player-1-GRIMM"); W.run(5)
  local row = a.ns.Ledger.Log()[1]
  eq(row.band, "orange"); eq(row.f, "v", "revenge only"); eq(row.j, 3); eq(row.s, 0); eq(row.e, 2 + 2)
  eq(#M.errors, 0, M.errors[1])
end)

M.done("ledger_fixes")
