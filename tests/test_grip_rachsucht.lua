-- 1.5.0 grip: the sharper grudge detection. The second signals (s = cast beside a hit, j = into combat with my hit,
-- r = targeted me at two hits without a creature on me), the creature cross-check (a hostile creature that has me
-- targeted or me on its threat table lowers the certainty by one step; "held" rows are neither shown nor asked), the
-- certainty per row, the cases kept without /dn probe (no names, at most 20). All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

local function load(opts)
  local ns = M.Load(opts)
  _G.UnitAffectingCombat = function(u)
    local x = M.units[u]
    if not x then return false end
    if x.combat == nil then return true end
    return x.combat
  end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  _G.UnitThreatSituation = function(_, u) local x = M.units[u]; return x and x.threat end
  return ns
end

local function enemy(token, name, surname, o)
  o = o or {}
  o.name, o.surname = name, surname
  o.guid = o.guid or ("Player-93-" .. name)
  if o.target == nil then o.target = "player" end
  if o.target == false then o.target = nil end
  local u = M.AddEnemy(token, o)
  if token:find("^nameplate") then M.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  return u
end

-- a hostile creature (no player); target "player" = it has me targeted
local function mob(token, o)
  o = o or {}
  o.isPlayer, o.name, o.guid = false, "Wolf", "Creature-0-1-2-3-" .. token
  if o.target == nil then o.target = "player" end
  if o.target == false then o.target = nil end
  local u = M.AddEnemy(token, o)
  if token:find("^nameplate") then M.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  return u
end

local function hit() M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1) end
local function fightStart() M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED") end
local function fightEnd() M.inCombat = false; M.FireEvent("PLAYER_REGEN_ENABLED") end
local function shown(G)
  local out = {}
  for _, r in ipairs(G.Rows()) do out[#out + 1] = r.key end
  return table.concat(out, ",")
end

---------------------------------------------------------------------------
-- Certainty
---------------------------------------------------------------------------
test("Sicherheit: b oder c sicher; a allein wahrscheinlich; a plus zweites Signal sicher; Kreatur eine Stufe tiefer", function()
  local ns = load()
  local G = ns.Grudge
  local function g(p, m)
    local row = { proofs = {}, mob = m }
    for l in p:gmatch(".") do row.proofs[l] = true end
    return G.Grade(row)
  end
  eq(g("b"), "sure"); eq(g("c"), "sure"); eq(g("ab", true), "sure", "der Tod nennt ihn: sicher auch mit Kreatur")
  eq(g("a"), "probable"); eq(g("aj"), "sure"); eq(g("ar"), "sure"); eq(g("as"), "sure")
  eq(g("a", true), "held"); eq(g("aj", true), "probable"); eq(g("ajr", true), "sure")
end)

test("Ohne Kreatur: ein Treffer bei Ziel auf mir zeigt die Zeile als wahrscheinlich (nichts geht verloren)", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  enemy("nameplate1", "Grimm", "Bart")
  hit()
  local ep = G.Current()
  ok(ep); eq(ep.rows["Grimm-Bart"].conf, "probable")
  eq(shown(G), "Grimm-Bart"); ok(G.Asks(ep))
  noErrors()
end)

test("Signal r: zweiter Treffer mindestens 1 s spaeter ohne Kreatur -> sicher; sichere Zeilen vor wahrscheinlichen", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  enemy("nameplate1", "Erst", "Gesehen")
  enemy("nameplate2", "Grimm", "Bart")
  hit()
  -- the first one looks away after the first hit: he stays at one hit
  M.units.nameplate1.target = nil
  M.Advance(0.5); hit()
  eq(G.Current().rows["Grimm-Bart"].proofs.r, nil, "zu kurz nach dem ersten Treffer")
  eq(shown(G), "Erst-Gesehen,Grimm-Bart", "beide wahrscheinlich: in der Reihenfolge des Kommens")
  M.Advance(0.7); hit()
  local ep = G.Current()
  eq(ep.rows["Grimm-Bart"].proofs.r, true); eq(ep.rows["Grimm-Bart"].conf, "sure")
  eq(ep.rows["Erst-Gesehen"].conf, "probable")
  eq(shown(G), "Grimm-Bart,Erst-Gesehen", "die erste Zeile soll stimmen")
  noErrors()
end)

test("Signal j: ausser Kampf mit Ziel auf mir, mit meinem Treffer im Kampf -> j", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  local u = enemy("nameplate1", "Grimm", "Bart", { combat = false })
  M.FireEvent("UNIT_TARGET", "nameplate1")
  M.Advance(0.8)
  u.combat = true
  hit()
  local r = G.Current().rows["Grimm-Bart"]
  eq(r.proofs.j, true); eq(r.conf, "sure")
  -- long out of combat before the hit: no j
  G.Close("test")
  M.Advance(400)
  local w = enemy("nameplate2", "Spaet", "Dran", { combat = false })
  M.FireEvent("UNIT_TARGET", "nameplate2")
  M.Advance(5)
  w.combat = true
  hit()
  eq(G.Current().rows["Spaet-Dran"].proofs.j, nil)
  noErrors()
end)

---------------------------------------------------------------------------
-- The creature cross-check
---------------------------------------------------------------------------
test("Gegenprobe: eine Kreatur hat mich im Ziel -> Spieler mit Ziel auf mir wird zurueckgehalten, keine Meldung", function()
  local ns = load()
  local G = ns.Grudge
  local seen = 0
  ns:On("GRUDGE_UPDATE", function(e) if G.Asks(e) then seen = seen + 1 end end)
  fightStart()
  mob("nameplate1")
  enemy("nameplate2", "Grimm", "Bart")
  hit()
  local ep = G.Current()
  ok(ep, "die Episode haelt ihn fest")
  eq(ep.rows["Grimm-Bart"].conf, "held"); eq(ep.rows["Grimm-Bart"].mob, true)
  eq(shown(G), ""); no(G.Asks(ep), "nichts zu fragen"); eq(seen, 0)
  eq(G.Answer("Grimm-Bart", true), false, "zurueckgehalten: kein Haken moeglich")
  fightEnd()
  no(G.Current(), "ohne Frage endet die Episode")
  no(ns.Store.Get("Grimm-Bart"))
  local c = G.ProbeSnapshot().counts
  eq(c.mob, 1); eq(c.held, 1); eq(c.heldEnd, 1); eq(c.promoted, 0)
  noErrors()
end)

test("Gegenprobe: Kreatur hat mich auf der Bedrohungsliste (ohne Ziel) zaehlt auch; secret zaehlt nicht", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  mob("nameplate1", { target = false, threat = 3 })
  enemy("nameplate2", "Grimm", "Bart")
  hit()
  eq(G.Current().rows["Grimm-Bart"].conf, "held")
  eq(G.ProbeSnapshot().counts.threatOk, 1)
  G.Close("test")
  M.Advance(400)
  M.units.nameplate1.threat = M.Secret("threat", "number")
  hit()
  eq(G.Current().rows["Grimm-Bart"].conf, "probable", "secret: keine Gegenprobe")
  ok(G.ProbeSnapshot().counts.threatSecret >= 1)
  no(M.ContainsSecret(_G.DeathNoteDB))
  noErrors()
end)

test("Gegenprobe plus zweites Signal: er geht mit meinem Treffer in den Kampf -> wahrscheinlich, gezeigt", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  mob("nameplate1")
  local u = enemy("nameplate2", "Grimm", "Bart", { combat = false })
  M.FireEvent("UNIT_TARGET", "nameplate2")
  M.Advance(0.5)
  u.combat = true
  hit()
  local r = G.Current().rows["Grimm-Bart"]
  eq(r.proofs.j, true); eq(r.mob, true); eq(r.conf, "probable")
  eq(shown(G), "Grimm-Bart"); ok(G.Asks())
  noErrors()
end)

test("Gegenprobe: wiederholte Treffer zaehlen nur ohne Kreatur auf mir; danach wird der Zurueckgehaltene gezeigt", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  local w = mob("nameplate1")
  enemy("nameplate2", "Grimm", "Bart")
  hit(); M.Advance(1.2); hit(); M.Advance(1.2); hit()
  local r = G.Current().rows["Grimm-Bart"]
  eq(r.proofs.r, nil, "die Kreatur trifft mich: keine Wiederholung"); eq(r.conf, "held")
  -- the creature is dead (its plate goes): two clean hits
  w.target = nil
  M.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1"); M.units.nameplate1 = nil
  M.Advance(2.5); hit(); M.Advance(1.2); hit()
  eq(r.proofs.r, true); eq(r.conf, "probable")
  eq(shown(G), "Grimm-Bart")
  eq(G.ProbeSnapshot().counts.promoted, 1)
  noErrors()
end)

test("Gegenprobe: ein Zauber mit Treffer bei Kreatur auf mir hebt ihn auf wahrscheinlich, ohne Treffer nichts", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  mob("nameplate1")
  enemy("nameplate2", "Grimm", "Bart")
  M.FireEvent("UNIT_SPELLCAST_SUCCEEDED", "nameplate2", "x", 1)
  no(G.Current())
  M.Advance(0.5); hit()
  local r = G.Current().rows["Grimm-Bart"]
  eq(r.proofs.s, true); eq(r.conf, "probable")
end)

test("Der Tod nennt ihn: sicher, auch wenn eine Kreatur dabei war", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  mob("nameplate1")
  enemy("nameplate2", "Grimm", "Bart")
  hit()
  eq(G.Current().rows["Grimm-Bart"].conf, "held")
  M.recap = { id = 3, events = {
    { sourceGUID = "Player-93-Grimm", sourceName = "Grimm Bart", amount = 900, overkill = 50, timestamp = time() - 1, spellName = "Hieb" },
  } }
  M.FireEvent("PLAYER_DEAD"); M.inCombat = false; M.FireEvent("PLAYER_REGEN_ENABLED")
  M.Advance(5)
  -- the death put him into the book (open world): the episode had nothing to ask and is over
  ok(ns.Store.Get("Grimm-Bart")); eq(ns.Store.Get("Grimm-Bart").kills, 1)
  local case = _G.DeathNoteDB.probe.grudge.cases[1]
  eq(case.list[1].c, "sure"); eq(case.list[1].p, "ab"); eq(case.list[1].m, true); eq(case.list[1].st, "book")
end)

---------------------------------------------------------------------------
-- Cases without /dn probe
---------------------------------------------------------------------------
test("Faelle: ohne /dn debug festgehalten, je Zeile Belege, Sicherheit, Gegenprobe, Antwort; keine Namen; hoechstens 20", function()
  local ns = load()
  local G = ns.Grudge
  no(ns.Store.Setting("debug"), "debug aus")
  fightStart()
  mob("nameplate1")
  enemy("nameplate2", "Grimm", "Bart")
  local u = enemy("nameplate3", "Fies", "Ling", { combat = false })
  M.FireEvent("UNIT_TARGET", "nameplate3")
  M.Advance(0.3); u.combat = true
  hit(); fightEnd()
  G.Answer("Fies-Ling", false)
  G.Close("done")
  local cs = _G.DeathNoteDB.probe.grudge.cases
  eq(#cs, 1)
  local c = cs[1]
  eq(c.mob, true); eq(c.proofs, "aj"); eq(c.no, 1)
  eq(#c.list, 2)
  local byP = {}
  for _, x in ipairs(c.list) do byP[x.p] = x end
  eq(byP.a.c, "held"); eq(byP.a.st, "held"); eq(byP.a.m, true)
  eq(byP.aj.c, "probable"); eq(byP.aj.st, "no")
  -- no names anywhere in the case
  local function scan(t)
    for k, v in pairs(t) do
      if type(k) == "string" then no(k:find("Grimm") or k:find("Fies"), k) end
      if type(v) == "string" then no(v:find("Grimm") or v:find("Fies") or v:find("Bart"), v) end
      if type(v) == "table" then scan(v) end
    end
  end
  scan(c)
  -- /dn probe keeps them
  ns.Probe.Run(false)
  eq(#_G.DeathNoteDB.probe.grudge.cases, 1)
  -- at most 20
  M.units.nameplate1 = nil; M.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
  for i = 1, 25 do
    M.Advance(400)
    fightStart(); hit(); fightEnd()
    if G.Current() then G.Close("time") end
  end
  eq(#_G.DeathNoteDB.probe.grudge.cases, 20)
  no(M.ContainsSecret(_G.DeathNoteDB))
  noErrors()
end)

test("Sonde: die Zeile von /dn probe nennt die neuen Zaehler", function()
  local ns = load()
  ns.Probe.Run(true)
  local line
  for _, l in ipairs(M.chat) do if l:find("grudge ", 1, true) and l:find("held", 1, true) then line = l end end
  ok(line, "Zeile mit held")
  ok(line:find("s 0", 1, true) and line:find("mob 0", 1, true), line)
end)

M.done("test_grip_rachsucht")
