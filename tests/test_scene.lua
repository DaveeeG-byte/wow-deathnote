-- 1.5.0 scene: crime scenes (Scene.lua: choice, filter, bundling, old entries without a spot), the feud's chronicle
-- (Chronicle.lua: sentences per role and turning point, long feuds cut, names never from keys) and the spot of a
-- death on the wire (Sync.lua message L: guild and friends, strict checks, older clients drop it silently, attacks,
-- suspicions, notes and anything taken over never go out). All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")
local GitBase = dofile(ROOT .. "/tests/git_base.lua")
local GUILD = "Die Wurstbrüder"

local function load()
  return M.Load({ before = function() M.units.player.guild = GUILD end })
end
-- a death as Attribution writes it (journal and deed); x, y nil = no spot; mapID false = none
local function death(ns, name, surname, ago, x, y, o)
  o = o or {}
  local t = time() - ago
  local mapID = o.mapID == nil and 1434 or (o.mapID or nil)
  local rec = { t = t, zone = o.zone or "Schlingendorntal", subzone = o.sub, mapID = mapID, x = x, y = y, me = o.me,
    spell = o.spell, source = o.source or "recap", others = o.others or {}, role = o.role }
  local key = ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40,
    guid = "Player-1-" .. name .. surname }, rec, o.sure ~= false)
  local j = { t = t, zone = rec.zone, subzone = o.sub, mapID = mapID, x = x, y = y, me = o.me, kind = "pvp", sure = o.sure ~= false,
    source = rec.source, candidates = {}, spell = o.spell, counted = true, killerKey = key, killerName = ns.Util.Display(ns.Store.Get(key)) }
  ns.Store.RecordDeath(j)
  return key, j
end

---------------------------------------------------------------------------
-- Choice and bundling
---------------------------------------------------------------------------
test("Tatorte: Nadel nur mit Karten-ID und Ort; alte Eintraege ohne Ort sind nur Zone", function()
  M.Reset()
  local ns = load()
  local Sc = ns.Scene
  death(ns, "Grimm", "Bart", 100, 40, 30)
  local _, jNo = death(ns, "Osric", "Hall", 200, nil, nil)
  local _, jNoMap = death(ns, "Kael", "Dorn", 300, nil, nil, { mapID = false })
  -- an entry of an old book: no map fields at all
  ns.Store.RecordDeath({ t = time() - 400, zone = "Arathihochland", kind = "pvp", sure = true, counted = true })
  local all = Sc.All(time())
  eq(#all, 4)
  local spots = 0
  for _, it in ipairs(all) do if it.spot then spots = spots + 1 end end
  eq(spots, 1, "nur der Tod mit Ort")
  local pins = Sc.Pins(1434, time())
  eq(#pins, 1)
  eq(pins[1].lead.name, "Grimm Bart")
  ok(Sc.ValidMap(jNo.mapID) and not Sc.ValidSpot(jNo.mapID, jNo.x, jNo.y), "Karten-ID ohne Ort: Zone")
  no(Sc.ValidMap(jNoMap.mapID), "ohne Karten-ID: nur Text")
  -- broken values are never a spot
  for _, v in ipairs({ { 0, 1, 1 }, { 1.5, 1, 1 }, { 1434, -1, 5 }, { 1434, 5, 100.1 }, { 1434, 0 / 0, 1 }, { 1e9, 1, 1 }, { "1434", 1, 1 } }) do
    no(Sc.ValidSpot(v[1], v[2], v[3]), "kaputt: " .. tostring(v[1]) .. "," .. tostring(v[2]))
  end
  -- other maps: no pin here, unless the map translates (a zone on its continent)
  death(ns, "Ferne", "Zone", 500, 50, 50, { mapID = 1435 })
  eq(#Sc.Pins(1434, time()), 1)
  local p2 = Sc.Pins(1414, time(), function(id, x, y) if id == 1434 then return 10 + x / 10, 50 + y / 10 end end)
  eq(#p2, 1, "der Kontinent zeigt den Tod der Zone")
  ok(math.abs(p2[1].x - 14) < 0.01, p2[1].x)
end)

test("Buendelung: nahe Tatorte eine Nadel mit Zahl, ferne getrennt, Obergrenze je Karte", function()
  M.Reset()
  local ns = load()
  local Sc = ns.Scene
  death(ns, "Grimm", "Bart", 100, 40, 30)
  death(ns, "Grimm", "Bart", 200, 41.5, 31)      -- 1.5 % right: same pin
  death(ns, "Velka", "Dorn", 300, 40, 33.5)      -- 3.5 % of the height = 2.3 % of the width: same pin
  death(ns, "Torvik", "Stein", 400, 44, 30)      -- 4 % right: own pin
  local pins = Sc.Pins(1434, time())
  eq(#pins, 2)
  eq(pins[1].count, 3)
  eq(pins[1].items[1].name, "Grimm Bart", "der neueste zuerst")
  eq(pins[2].count, 1)
  -- 60 scenes far apart
  M.Reset()
  ns = load()
  Sc = ns.Scene
  for i = 1, 60 do death(ns, "Masse", "Nr" .. string.char(96 + (i % 26) + 1) .. i, i * 10, (i % 10) * 9 + 4, math.floor(i / 10) * 14 + 5) end
  local p, left = Sc.Pins(1434, time())
  eq(#p, Sc.MAX_PINS)
  eq(left, 60 - Sc.MAX_PINS, "die aeltesten bleiben weg und werden gezaehlt")
  for _, x in ipairs(p) do ok(x.items[1].t >= time() - 41 * 10 - 1, "die neuesten bekommen die Nadeln") end
end)

test("Filter: Zeitraum, an/aus, nur offene Schulden, Arten; der Fokus aus dem Buch geht immer durch", function()
  M.Reset()
  local ns = load()
  local Sc, S = ns.Scene, ns.Store
  local grimm = death(ns, "Grimm", "Bart", 3600, 40, 30)
  local _, jOld = death(ns, "Alt", "Wolf", 40 * 86400, 60, 60)
  local velka = death(ns, "Velka", "Dorn", 7200, 80, 20)
  eq(#Sc.Pins(1434, time()), 2, "Standard 30 Tage")
  S.Setting("scene.days", 0)
  eq(#Sc.Pins(1434, time()), 3, "alle")
  S.Setting("scene.days", 7)
  eq(#Sc.Pins(1434, time()), 2)
  eq(#Sc.Pins(1434, time(), nil, jOld), 3, "Fokus: der alte Tod aus dem Buch")
  eq(#Sc.Pins(1434, time(), nil, { t = jOld.t, mapID = 1434 }), 3, "Fokus ueber Zeit und Karte (Tat-Zeile des Plakats)")
  S.AddRevenge(velka, true); S.AddRevenge(velka, true)
  S.Setting("scene.open", true)
  local p = Sc.Pins(1434, time())
  eq(#p, 1, "nur offene Schulden")
  eq(p[1].lead.key, grimm)
  S.Setting("scene.open", false)
  S.Setting("scene.own", false)
  eq(#Sc.Pins(1434, time()), 0)
  S.Setting("scene.own", true)
  S.Setting("scene.on", false)
  eq(#Sc.Pins(1434, time()), 0)
  eq(Sc.StepDays(1), 30); eq(Sc.StepDays(1), 0); eq(Sc.StepDays(1), 7); eq(Sc.StepDays(-1), 0)
end)

test("eigene Kills aus dem Strafregister: Rache und Gebuchte im Buch; fremde Opfer ohne Buch nicht", function()
  M.Reset()
  local ns = load()
  local Sc = ns.Scene
  local key = death(ns, "Grimm", "Bart", 9000, 40, 30)
  local log = ns.Ledger.Log()
  table.insert(log, 1, { t = time() - 60, key = key, name = "Grimm Bart", f = "v", zone = "Schlingendorntal", mapID = 1434, x = 70, y = 70 })
  table.insert(log, 1, { t = time() - 30, key = "Fremd-Ling", name = "Fremd Ling", f = "", zone = "Z", mapID = 1434, x = 10, y = 10 })
  local kills = 0
  for _, it in ipairs(Sc.All(time())) do if it.kind == "kill" then kills = kills + 1; ok(it.revenge) end end
  eq(kills, 1)
  local pins = Sc.Pins(1434, time())
  eq(#pins, 2)
  local tip
  for _, p in ipairs(pins) do if p.kind == "kill" then tip = Sc.TipLines(p, time()) end end
  ok(tip and tip[1][1]:find("Hier hast du", 1, true) and tip[1][1]:find("Grimm Bart", 1, true), tip and tip[1][1])
  ok(tip and tip[3][1] == ns.L.SCENE_REVENGE)
end)

test("Tooltip: Mittaeter nur mit Namen aus dem Buch, nie ein Schluessel", function()
  M.Reset()
  local ns = load()
  local Sc = ns.Scene
  local helper = death(ns, "Hel", "Fer", 9999, 10, 10)
  death(ns, "Grimm", "Bart", 100, 40, 30, { spell = "Ausweiden", others = { helper, "Unbe-Kannt" } })
  local p = Sc.Pins(1434, time())
  local lines = {}
  for _, x in ipairs(p) do if x.lead.name == "Grimm Bart" then for _, l in ipairs(Sc.TipLines(x, time())) do lines[#lines + 1] = l[1] end end end
  local t = table.concat(lines, "\n")
  ok(t:find("Hel Fer", 1, true), t)
  no(t:find("Unbe", 1, true), "kein Name aus einem Schluessel")
  no(t:find("Grimm-Bart", 1, true))
  ok(t:find("Ausweiden", 1, true))
end)

---------------------------------------------------------------------------
-- Chronicle
---------------------------------------------------------------------------
test("Chronik: Saetze je Rolle und Wendepunkt aus festen Daten", function()
  M.Reset()
  local ns = load()
  local S, C = ns.Store, ns.Chronicle
  local t0 = time() - 10 * 86400
  local key = S.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE" }, { t = t0, zone = "Schlingendorntal",
    subzone = "Grom'gol", mapID = 1434, x = 40, y = 30, spell = "Hinterhalt", source = "recap" }, true)
  S.ApplyKill({ name = "Grimm", surname = "Bart" }, { t = t0 + 3600, zone = "Schlingendorntal", source = "recap" }, true)
  S.ApplyKill({ name = "Grimm", surname = "Bart" }, { t = t0 + 7200, zone = "Arathihochland", source = "recap", role = "assist" }, false)
  S.ApplyKill({ name = "Grimm", surname = "Bart" }, { t = t0 + 7300, zone = "Arathihochland" }, false)   -- suspicion
  S.AddAttack({ name = "Grimm", surname = "Bart" }, { t = t0 + 8000, zone = "Sümpfe des Elends" })
  local log = ns.Ledger.Log()
  table.insert(log, 1, { t = t0 + 86400, key = key, name = "Grimm Bart", f = "v", zone = "Beutebucht", mapID = 1434, x = 50, y = 80 })
  table.insert(log, 1, { t = t0 + 2 * 86400, key = key, name = "Grimm Bart", f = "v", zone = "Beutebucht" })
  local e = S.Get(key)
  e.revenge = 2
  local ch = C.Build(key)
  local txt = {}
  for i, l in ipairs(ch.lines) do txt[i] = l.text end
  local all = table.concat(txt, "\n")
  eq(ch.name, "Grimm Bart")
  ok(txt[1]:find("^Erste Begegnung: ") and txt[1]:find(", Grom'gol%.$"), txt[1])
  ok(all:find(", Grom'gol: Grimm erwischt dich mit Hinterhalt.", 1, true), all)
  ok(all:find(", Schlingendorntal: Grimm tötet dich.", 1, true), all)
  ok(all:find("Grimm hilft beim Töten.", 1, true), all)
  ok(all:find("Verdacht: Grimm hatte dich im Ziel", 1, true), "Verdacht heisst Verdacht")
  ok(all:find("Angriff: Grimm geht auf dich los, du kommst davon.", 1, true), "Angriff heisst Angriff")
  ok(all:find("Du stellst Grimm zum ersten Mal.", 1, true), all)
  ok(all:find("Jetzt quitt: 2 : 2.", 1, true), all)
  ok(txt[#txt]:find("^Stand: 2 : 2"), txt[#txt])
  no(all:find("Grimm-Bart", 1, true), "nie ein Schluessel")
  -- places carry their spot (clickable in the book)
  local withSpot = 0
  for _, l in ipairs(ch.lines) do if l.place and l.place.mapID then withSpot = withSpot + 1 end end
  ok(withSpot >= 2, withSpot)
  -- the same sentence never twice in a row
  for i = 2, #txt do
    local a, b = txt[i - 1]:gsub("^[^:]*: ", ""), txt[i]:gsub("^[^:]*: ", "")
    ok(a ~= b, "zweimal derselbe Satz: " .. b)
  end
  -- turning point ahead, bounty by hand, pardoned
  S.AddRevenge(key, true)
  S.SetStatus(key, "pardoned")
  all = {}
  for _, l in ipairs(C.Build(key).lines) do all[#all + 1] = l.text end
  all = table.concat(all, "\n")
  ok(all:find("Du notierst Rache an Grimm.", 1, true) or all:find("Jetzt vorn", 1, true), all)
  ok(all:find("Du hast Grimm begnadigt.", 1, true), all)
end)

test("Chronik: 60 Taten werden gekuerzt, keine Formel zweimal in Folge", function()
  M.Reset()
  local ns = load()
  local S, C = ns.Store, ns.Chronicle
  local t0 = time() - 30 * 86400
  local key
  for i = 1, 60 do
    key = S.ApplyKill({ name = "Viel", surname = "Taeter" }, { t = t0 + i * 3600, zone = "Ort" .. i, source = "recap" }, true)
  end
  local ch = C.Build(key)
  -- deeds keep 30 (MAX_ENEMY_DEATHS): 30 story lines -> 3 + "… and 17 more" + 10
  eq(ch.cut, 30 - C.HEAD_KEEP - C.TAIL_KEEP)
  local more
  for _, l in ipairs(ch.lines) do if l.more then more = l.text end end
  eq(more, ns.F(ns.L.MORE_LINE, { count = ch.cut }))
  -- 1.5.0 fixer: 60 killing blows counted, 30 kept: the second line says once that earlier deeds are gone
  eq(#ch.lines, 1 + 1 + C.HEAD_KEEP + 1 + C.TAIL_KEEP + 1)
  eq(ch.lines[2].text, ns.L.CHRON_EARLIER)
  for i = 2, #ch.lines do
    local a, b = ch.lines[i - 1].text:gsub("^[^:]*: ", ""), ch.lines[i].text:gsub("^[^:]*: ", "")
    ok(a ~= b, b)
  end
  -- a fresh entry without deeds: written by hand
  local k2 = S.AddManual("Neu", "Ling")
  local c2 = C.Build(k2)
  ok(c2.lines[1].text:find("Erste Begegnung", 1, true), c2.lines[1].text)
  eq(C.Build("Gibt-Esnicht"), nil)
end)

---------------------------------------------------------------------------
-- The spot on the wire (message L)
---------------------------------------------------------------------------
test("L: Kodierung streng; kaputte Werte werden verworfen", function()
  M.Reset()
  local ns = load()
  local P = ns.Guild.Proto
  local text = P.EncodePlace({ key = "Grimm-Bart", t = 1800000000, victim = "Anton Wurst", mapID = 1434, x = 40.25, y = 63.6 })
  eq(text, "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t403\t636")
  local m = P.Decode(text, 1800000000, {})
  ok(m and m.kind == "L" and m.mapID == 1434 and m.px == 403 and m.py == 636 and m.victim == "Anton Wurst")
  no(P.EncodePlace({ key = "Grimm-Bart", t = 1, victim = "A B", mapID = 1434 }), "ohne Ort keine Nachricht")
  no(P.EncodePlace({ key = "Grimm-Bart", t = 1, victim = "A B", mapID = 0, x = 1, y = 1 }))
  for _, bad in ipairs({ "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t1001\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t-1\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t4.5\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t0\t4\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t999999999\t4\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\tabc\t4\t5",
                         "1\tL\tGrimm-Bart\t1800000000\t\t1434\t4\t5",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t4",
                         "1\tL\tGrimm-Bart\t1800000000\tAnton Wurst\t1434\t4\t5\t6" }) do
    local r, why = P.Decode(bad, 1800000000, {})
    no(r, bad)
    ok(why, bad)
  end
end)

local function sentKinds(W, from, kind)
  local out = {}
  for _, m in ipairs(W.sent) do
    if (not from or m.sender == from) and m.text:match("^1\t(%u)\t") == kind then out[#out + 1] = m.text end
  end
  return out
end
local function ownDeath(c, killer, surname, opts)
  opts = opts or {}
  local t = time() - (opts.ago or 0)
  local me = c.surname and (c.name .. " " .. c.surname) or c.name
  local key = c.ns.Store.ApplyKill({ name = killer, surname = surname, class = "MAGE", level = 36 },
    { t = t, zone = "Schlingendorntal", mapID = opts.mapID or 1434, x = opts.x or 40.2, y = opts.y or 63.6, me = me,
      myLevel = 34, source = "recap", others = {} }, true)
  c.ns:Fire("DEATH_RECORDED", { t = t, zone = "Schlingendorntal", mapID = opts.mapID or 1434, x = opts.x or 40.2,
    y = opts.y or 63.6, me = me, kind = "pvp", sure = true, counted = true, killerKey = key, source = "recap" }, key)
  return key, t
end
local function deedOf(c, key, src)
  local g = c.ns.Guild.Get(key, src or "guild")
  return g and g.deeds[1]
end

test("L: eigener Tod geht mit Ort an Gilde und Freunde; Kollege und Freund setzen die Nadel", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Fritz Frei" }, fullSender = true })
  local b = W.client("Berta", "Senf", GUILD, { fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); W.run(90)
  local key = ownDeath(a, "Grimm", "Bart")
  W.run(10)
  local ls = sentKinds(W, a, "L")
  eq(#ls, 2, "ein L in die Gilde, eines an den Freund")
  local d = deedOf(b, key)
  ok(d and d.mapID == 1434 and d.x == 40.2 and d.y == 63.6, d and tostring(d.x))
  local fd = deedOf(f, key, "friends")
  ok(fd and fd.mapID == 1434 and fd.x == 40.2, "Freund")
  -- the scene on the mate's map: "Here Anton Wurst was killed by Grimm Bart"
  local pins = b.ns.Scene.Pins(1434, time())
  eq(#pins, 1)
  eq(pins[1].kind, "guild")
  ok(pins[1].fresh, "frisch")
  local head = b.ns.Scene.Head(pins[1].lead)
  ok(head:find("Hier wurde Anton Wurst von", 1, true) and head:find("Grimm Bart", 1, true), head)
  ok(b.ns.Scene.counts.placeReceived >= 1 and a.ns.Scene.counts.placeSent >= 2)
  eq(#M.errors, 0, M.errors[1])
end)

test("L: Schalter aus sendet keinen Ort; ohne K kein Ort; fremder Absender wird verworfen", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { fullSender = true })
  local b = W.client("Berta", "Senf", GUILD, { fullSender = true })
  a.login(); b.login(); W.run(90)
  a.ns.Store.Setting("guild.sendPlace", false)
  local key = ownDeath(a, "Grimm", "Bart")
  W.run(10)
  eq(#sentKinds(W, a, "K"), 1)
  eq(#sentKinds(W, a, "L"), 0, "aus: kein Ort")
  eq(deedOf(b, key).mapID, nil)
  -- an L without its K, and an L for someone else's death: dropped with a reason
  local P = a.ns.Guild.Proto
  b.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodePlace({ key = "Nie-Gesehen", t = time(), victim = "Anton Wurst", mapID = 1434, x = 1, y = 1 }),
    "GUILD", "Anton Wurst-Forever")
  b.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodePlace({ key = key, t = deedOf(b, key).t, victim = "Anton Wurst", mapID = 1434, x = 9, y = 9 }),
    "GUILD", "Carla Kraut-Forever")
  b.fire("CHAT_MSG_ADDON", "DeathNote", "1\tL\tGrimm-Bart\t1\tAnton Wurst\t1434\t1001\t5", "GUILD", "Anton Wurst-Forever")
  local r = b.ns.Scene.counts.placeReasons
  ok(r.nodeed == 1 and r.victim == 1 and (r.place == 1 or r.time == 1), tostring(r.nodeed) .. "/" .. tostring(r.victim))
  eq(deedOf(b, key).mapID, nil, "nichts gesetzt")
end)

test("L: Angriffe, Verdacht, Notizen, Hand-Eintraege und Uebernommenes gehen nie mit Ort hinaus", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Fritz Frei" }, fullSender = true })
  local b = W.client("Berta", "Senf", GUILD, { fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); W.run(90)
  local S = a.ns.Store
  local me = "Anton Wurst"
  S.AddAttack({ name = "Wut", surname = "Ling" }, { t = time() - 50, zone = "Z", mapID = 1434, x = 1, y = 1, me = me })
  S.ApplyKill({ name = "Ver", surname = "Dacht" }, { t = time() - 40, zone = "Z", mapID = 1434, x = 2, y = 2, me = me }, false)
  a.ns:Fire("DEATH_RECORDED", { t = time() - 40, zone = "Z", mapID = 1434, x = 2, y = 2, me = me, kind = "pvp", sure = false,
    counted = true, source = "suspect" }, nil)
  local k = S.AddManual("Hand", "Eintrag"); S.SetNote(k, "geheim")
  S.AddManual("Ueber", "Nommen", { fromGuild = true })
  W.run(20)
  -- a hello: the answer (R and L) holds none of it
  b.ns.Guild.SyncNow(); f.ns.Friends.SyncNow(); W.run(120)
  eq(#sentKinds(W, a, "L"), 0, "kein Ort")
  for _, m in ipairs(W.sent) do
    no(m.text:find("Wut-Ling", 1, true) or m.text:find("Ver-Dacht", 1, true) or m.text:find("geheim", 1, true), m.text)
  end
end)

test("L: Antwort auf ein Hallo bringt Orte nur fuer die neuesten Tode der letzten 7 Tage (hoechstens 10)", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { fullSender = true })
  a.login(); W.run(60)
  for i = 1, 14 do ownDeath(a, "Taeter", "Nr" .. string.char(96 + i), { ago = i * 3600 }) end
  ownDeath(a, "Alt", "Fall", { ago = 9 * 86400 })
  W.run(60)
  local b = W.client("Berta", "Senf", GUILD, { fullSender = true })
  local before = #W.sent
  b.login(); W.run(180)
  local rs, ls = 0, 0
  for i = before + 1, #W.sent do
    local m = W.sent[i]
    if m.sender == a then
      local k = m.text:match("^1\t(%u)\t")
      if k == "R" then rs = rs + 1 elseif k == "L" then ls = ls + 1 end
    end
  end
  eq(rs, 15)
  eq(ls, 10)
  local withSpot = 0
  for _, g in ipairs(b.ns.Guild.List("recent", { source = "guild" })) do
    for _, d in ipairs(g.deeds) do if d.mapID then withSpot = withSpot + 1 end end
  end
  eq(withSpot, 10)
  local old = b.ns.Guild.Get("Alt-Fall", "guild")
  ok(old and old.deeds[1].mapID == nil, "der alte Tod ohne Ort")
end)

test("L: aeltere Clients (1.1.0, 1.2.0, 1.4.0) verwerfen L still und behalten ihre Daten", function()
  M.Reset()
  local W = M.NewWorld()
  local OLD = ROOT .. "/tests/fixtures/addon-1.1.0/"
  local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
  local V120 = ROOT .. "/tests/fixtures/addon-1.2.0/"
  local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
    "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Otto Neu" }, fullSender = true })
  local o = W.client("Olaf", "Alt", GUILD, { dir = OLD, files = OLDFILES, lang = false, fullSender = true })
  local n = W.client("Otto", "Neu", GUILD, { dir = V120, files = FILES120, friends = { "Anton Wurst" }, fullSender = true, version = "1.2.0" })
  local v14
  local dir14 = GitBase.Has(ROOT, "1455a44") and GitBase.Archive(ROOT, "1455a44")
  if dir14 then
    local files = {}
    for _, f in ipairs(M.FILES) do
      local h = io.open(dir14 .. f, "r")
      if h then h:close(); files[#files + 1] = f end
    end
    v14 = W.client("Vera", "Vier", GUILD, { dir = dir14, files = files, fullSender = true, version = "1.4.0" })
  end
  a.login(); o.login(); n.login(); if v14 then v14.login() end
  W.run(120)
  local key = ownDeath(a, "Grimm", "Bart")
  W.run(20)
  ok(#sentKinds(W, a, "L") >= 1, "L ging hinaus")
  eq(#M.errors, 0, M.errors[1])
  for _, c in ipairs({ o, n, v14 }) do
    local g = c.ns.Guild.Get(key)
    ok(g and g.deeds[1] and g.deeds[1].mapID == nil, "der alte Client hat den Tod (K), ohne Ort")
    eq(c.ns.Guild.stats.lastReason, "type", "L als unbekannte Art verworfen")
  end
  -- they still listen: the next K arrives
  ownDeath(a, "Zweit", "Taeter")
  W.run(20)
  for _, c in ipairs({ o, n, v14 }) do ok(c.ns.Guild.Get("Zweit-Taeter"), "hoert weiter zu") end
  eq(#M.errors, 0, M.errors[1])
  if not dir14 then print("  (1.4.0 uebersprungen: kein Repository)") end
  GitBase.Clean()
end)

M.done("test_scene")
