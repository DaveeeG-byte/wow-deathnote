-- Rap sheet (1.3.1): group kills. A PARTY_KILL of a group member (or his pet) on an enemy player books a kill for me
-- when a proof that I took part comes within the window (PLAYER_PVP_KILLS_CHANGED or an honour line of any form,
-- from Ledger.PROOF_BEFORE s before to Ledger.PROOF_AFTER s after it); each proof counts once per channel.
-- The first test replays the probe from the game (13.11.2026, a group of two, the mate's killing blow):
-- PARTY_KILL, PLAYER_PVP_KILLS_CHANGED +0.4 s, honour line without a name +1.0 s. All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"
local MATE = "Player-93-0000BBBB"
local PLAIN = "Ihr habt 198 Ehrenpunkte erhalten."   -- an honour line without a victim's name (30-odd characters)

local ns, own
local function load(level)
  ns = M.Load()
  M.units.player.level = level or 40
  own = {}
  ns:On("OWN_KILL", function(key, row) own[#own + 1] = { key = key, row = row } end)
  return ns
end
local function L() return ns.Ledger end
-- a group of two: me and the mate in party1 (his pet in partypet1)
local function party(pet)
  M.units.party1 = { exists = true, isPlayer = true, name = "Kumpel", surname = "Treu", guid = MATE, faction = "Horde",
    level = 40 }
  if pet then M.units.partypet1 = { exists = true, guid = "Pet-0-4242" } end
  M.FireEvent("GROUP_ROSTER_UPDATE")
end
local plate = 0
local function seen(name, surname, level, o)
  plate = plate + 1
  o = o or {}
  o.name, o.surname, o.level = name, surname, level or 40
  o.guid = o.guid or ("Player-93-" .. name .. (surname or ""))
  M.AddEnemy("nameplate" .. plate, o)
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return o.guid
end
local function pk(att, guid) M.FireEvent("PARTY_KILL", att, guid) end
local function kc() M.FireEvent("PLAYER_PVP_KILLS_CHANGED") end
local function honor(text) M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", text or PLAIN) end
local function debugOn() ns.Store.Setting("debug", true) end
local function caseOf(src)
  local k = _G.DeathNoteDB.probe and _G.DeathNoteDB.probe.kills
  for _, c in ipairs(k and k.cases or {}) do if c.src == src then return c end end
end

---------------------------------------------------------------------------
-- The probe replayed
---------------------------------------------------------------------------
test("Probe replay: mate's PARTY_KILL, kills changed +0.4 s, plain honour line +1 s = one kill, half honour", function()
  load(40); party(); debugOn()
  local g = seen("Grimm", "Bart", 41)
  pk(MATE, g)
  eq(#own, 0, "nothing before the proof")
  eq(L().Victim("Grimm-Bart"), nil)
  M.Advance(0.4); kc()
  eq(#own, 1, "booked at the proof")
  M.Advance(0.6); honor()
  M.Advance(10)
  eq(#own, 1, "the honour line of the same kill books nothing more")
  local v = L().Victim("Grimm-Bart")
  ok(v, "victim"); eq(v.n, 1); eq(v.level, 41); eq(v.guid, g)
  local row = L().Log()[1]
  eq(row.band, "gelb"); eq(row.e, 2, "honour 3 halved (rounded)"); eq(row.r, 0)
  ok(row.f:find("g", 1, true), "flag g"); ok(row.f:find("o", 1, true), "flag o")
  eq(row.state, "victim")
  local mine, his, state = L().Standing("Grimm-Bart")
  eq(mine, 1); eq(his, 0); eq(state, "victim")
  eq(L().Repute().n, 1); eq(L().Repute().acc.e, 2)
  local c = caseOf("partykill")
  eq(c.result, "group-booked"); eq(c.att, "group"); eq(c.proof.kind, "kc"); eq(c.proof.dt, 0.4)
  eq(L().probeCounts.groupBooked, 1); eq(L().probeCounts.proofKC, 1); eq(L().probeCounts.proofHonor, 1)
end)

test("The plain honour line alone is a proof too (kills changed missing)", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g); M.Advance(1); honor()
  eq(#own, 1)
  ok(L().Log()[1].f:find("o", 1, true))
end)

test("A named honour line is a proof as well; the fallback stays off", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g); M.Advance(1)
  honor("Grimm stirbt (Ehrenhafter Sieg: Gefreiter). Ihr erhaltet 12 Ehre.")
  M.Advance(5)
  eq(#own, 1, "one kill, not two")
  eq(L().Repute().n, 1)
end)

---------------------------------------------------------------------------
-- Proofs and the window
---------------------------------------------------------------------------
test("No proof: nothing is booked, a late proof (3.5 s) books nothing; probe says group-noproof", function()
  load(40); party(); debugOn()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g)
  M.Advance(3.5); kc(); honor()
  M.Advance(10)
  eq(#own, 0); eq(L().Victim("Grimm-Bart"), nil); eq(L().Repute().n, 0)
  eq(caseOf("partykill").result, "group-noproof")
end)

test("A proof without any PARTY_KILL books nothing", function()
  load(40); party()
  seen("Grimm", "Bart", 40)
  kc(); M.Advance(1); honor(); M.Advance(10)
  eq(#own, 0); eq(L().Repute().n, 0)
  kc()   -- the next proof drops the old ones
  eq(L().probeCounts.proofLoose, 2, "counted as loose proofs")
  eq(#own, 0)
end)

test("A proof up to 1 s before the PARTY_KILL counts; 1.5 s before does not", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  kc(); M.Advance(0.6); pk(MATE, g)
  eq(#own, 1, "proof 0.6 s before")
  M.Advance(20)
  local h = seen("Hanna", "Hain", 40)
  kc(); M.Advance(1.5); pk(MATE, h); M.Advance(5)
  eq(#own, 1, "proof 1.5 s before: too early")
end)

test("Two kills within 2 s with two proofs each = two kills; in order", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(0.4); kc()
  M.Advance(0.6); honor()
  M.Advance(0.6); pk(MATE, b); M.Advance(0.4); kc(); M.Advance(0.6); honor()
  M.Advance(10)
  eq(#own, 2)
  eq(own[1].key, "Anna-Ast"); eq(own[2].key, "Bernd-Bolz")
end)

test("Two PARTY_KILLs, both proofs before the second: still two (one per channel, the oldest first)", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(0.2); pk(MATE, b)
  M.Advance(0.3); kc(); M.Advance(0.1); kc()
  M.Advance(10)
  eq(#own, 2); eq(own[1].key, "Anna-Ast"); eq(own[2].key, "Bernd-Bolz")
end)

test("One proof (kills changed and its honour line) for two PARTY_KILLs = one kill, the first", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(0.5); pk(MATE, b)
  M.Advance(0.4); kc(); M.Advance(0.6); honor()
  M.Advance(10)
  eq(#own, 1); eq(own[1].key, "Anna-Ast")
  eq(L().Victim("Bernd-Bolz"), nil)
end)

test("My own kill takes its own proof: a mate's kill out of my reach right after it is not booked", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(ME, a)
  eq(#own, 1, "own kill booked at once")
  M.Advance(0.2); pk(MATE, b)
  M.Advance(0.2); kc(); M.Advance(0.6); honor()      -- the proofs of my kill
  M.Advance(10)
  eq(#own, 1, "the mate's kill got no proof of its own")
end)

---------------------------------------------------------------------------
-- What never counts
---------------------------------------------------------------------------
test("Never: a creature as target, a stranger (not in my group), myself", function()
  load(40); party()
  pk(MATE, "Creature-0-5-Raptor"); kc(); honor(); M.Advance(5)
  eq(#own, 0, "creature")
  local g = seen("Grimm", "Bart", 40)
  pk("Player-93-Fremd", g); kc(); M.Advance(5)
  eq(#own, 0, "not in my group")
  pk(MATE, ME); kc(); M.Advance(5)
  eq(#own, 0, "me")
  -- without a group the mate is nobody
  M.units.party1 = nil; M.FireEvent("GROUP_ROSTER_UPDATE")
  pk(MATE, g); kc(); M.Advance(5)
  eq(#own, 0, "no group")
end)

test("Never: my own faction", function()
  load(40); party()
  local g = seen("Hordi", "Gleich", 40, { faction = "Horde", enemy = false, canAttack = true })
  local okk, why = L().OnPartyKill(MATE, g)
  no(okk); eq(why, "faction")
  kc(); M.Advance(5)
  eq(#own, 0)
end)

test("Never: the opponent of my duel to the death", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm Bart")
  M.Advance(5)
  local okk, why = L().OnPartyKill(MATE, g)
  no(okk); eq(why, "duel")
  kc(); M.Advance(5)
  eq(#own, 0)
end)

test("Never: in an instance", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  M.instance = { true, "pvp" }
  local okk, why = L().OnPartyKill(MATE, g)
  no(okk); eq(why, "instance")
  kc(); M.Advance(5)
  eq(#own, 0)
end)

---------------------------------------------------------------------------
-- Dedupe: mate first, then me (and the other way round)
---------------------------------------------------------------------------
test("Same victim within 10 s: the mate's and my PARTY_KILL are one kill (either order)", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g); M.Advance(0.4); kc()
  M.Advance(1); pk(ME, g); M.Advance(0.4); kc()
  M.Advance(10)
  eq(#own, 1, "mate first")
  eq(L().Victim("Grimm-Bart").n, 1)
  M.Advance(700)
  local h = seen("Hanna", "Hain", 40)
  pk(ME, h); M.Advance(0.4); kc(); M.Advance(1); pk(MATE, h); M.Advance(0.4); kc()
  M.Advance(10)
  eq(#own, 2, "me first")
  eq(L().Victim("Hanna-Hain").n, 1)
  ok(not L().Log()[1].f:find("o", 1, true), "my own killing blow carries no o")
end)

test("Mate's kill waiting, then my own PARTY_KILL on him: booked once as my own blow", function()
  load(40); party(); debugOn()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g)
  local mateCase = caseOf("partykill")
  M.Advance(0.2); pk(ME, g)
  eq(#own, 1)
  M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(10)
  eq(#own, 1)
  ok(not L().Log()[1].f:find("o", 1, true))
  eq(mateCase.result, "group-own", "the probe: the mate's claim became my own kill")
end)

test("A second PARTY_KILL of the mate on the same victim takes no proof from the next kill", function()
  load(40); party()
  local g, h = seen("Grimm", "Bart", 40), seen("Hanna", "Hain", 40)
  pk(MATE, g); pk(MATE, g); M.Advance(0.3); pk(MATE, h)
  M.Advance(0.4); kc(); M.Advance(0.1); kc(); M.Advance(10)
  eq(#own, 2, "both victims")
  eq(own[2] and own[2].key, "Hanna-Hain")
end)

test("A creature kill of the mate takes no proof away from a player kill right after it", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  local okk, why = L().OnPartyKill(MATE, "Creature-0-5-Raptor")
  no(okk); eq(why, "attacker")
  M.Advance(0.4); kc()           -- the proof of the player kill comes 0.6 s before its PARTY_KILL
  M.Advance(0.6); pk(MATE, g)
  eq(#own, 1)
end)

test("A member who left the group is nobody, even right after the roster was read", function()
  load(40); party()
  local g, h = seen("Grimm", "Bart", 40), seen("Hanna", "Hain", 40)
  pk(MATE, g); M.Advance(0.4); kc()
  eq(#own, 1)
  M.units.party1 = { exists = true, isPlayer = true, name = "Neu", guid = "Player-93-0000CCCC", faction = "Horde" }
  M.FireEvent("GROUP_ROSTER_UPDATE")
  M.Advance(0.2); pk(MATE, h); M.Advance(0.4); kc(); M.Advance(5)
  eq(#own, 1, "the old member's kill is not mine")
end)

test("The group falls apart between the PARTY_KILL and its proof: still a group kill (half honour)", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g)
  M.units.party1 = nil; M.FireEvent("GROUP_ROSTER_UPDATE")
  M.Advance(0.4); kc(); M.Advance(5)
  eq(#own, 1)
  local row = L().Log()[1]
  eq(row.e, 2); ok(row.f:find("g", 1, true)); ok(row.f:find("o", 1, true))
end)

test("Two PARTY_KILLs of the mate on the same victim: one claim", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g); pk(MATE, g); M.Advance(0.4); kc(); kc(); M.Advance(10)
  eq(#own, 1)
end)

---------------------------------------------------------------------------
-- Points, marks, pet, raid
---------------------------------------------------------------------------
test("Points: honour and hunt halved, infamy and protection in full; marks gap and quick stay for own blows", function()
  load(40); party()
  -- grey victim: infamy 4, not halved
  local g = seen("Klein", "Grau", 20)
  pk(MATE, g); M.Advance(0.4); kc(); M.Advance(5)
  local row = L().Log()[1]
  eq(row.band, "grau"); eq(row.r, 4, "infamy in full")
  -- orange victim: honour 2 -> 1, hunt 3 -> 2
  local o = seen("Oskar", "Orange", 43)
  pk(MATE, o); M.Advance(0.4); kc(); M.Advance(5)
  row = L().Log()[1]
  eq(row.band, "orange"); eq(row.e, 1); eq(row.j, 2)
  -- red victim: no largest level gap from a mate's blow, no "david" award
  local r = seen("Riese", "Rot", 46)
  pk(MATE, r); M.Advance(0.4); kc(); M.Advance(5)
  eq(L().Log()[1].band, "rot")
  eq(L().Repute().best.gap, nil, "gap only for own blows")
  eq(L().Repute().awards.david, nil)
  eq(L().Repute().best.streak, 3, "the streak counts")
end)

test("The mate's pet: a group kill too", function()
  load(40); party(true)
  local g = seen("Grimm", "Bart", 40)
  pk("Pet-0-4242", g); M.Advance(0.4); kc(); M.Advance(5)
  eq(#own, 1); ok(L().Log()[1].f:find("o", 1, true))
end)

test("Raid of 40: members and pets count with a proof, a stranger never, no proof twice", function()
  load(40)
  for i = 1, 40 do
    M.units["raid" .. i] = { exists = true, isPlayer = true, name = "R" .. i, guid = (i == 1) and ME or ("Player-93-R" .. i) }
    if i % 4 == 0 then M.units["raidpet" .. i] = { exists = true, guid = "Pet-0-R" .. i } end
  end
  M.FireEvent("GROUP_ROSTER_UPDATE")
  local a, b, c, d = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40), seen("Carla", "Klee", 40), seen("Dora", "Damm", 40)
  pk("Player-93-R25", a); pk("Pet-0-R8", b); pk("Player-93-R39", c); pk("Player-93-Fremd", d)
  M.Advance(0.4); kc(); kc()            -- two proofs for three claims
  M.Advance(0.6); honor(); honor()
  M.Advance(10)
  eq(#own, 2, "two proofs, two kills")
  eq(own[1].key, "Anna-Ast"); eq(own[2].key, "Bernd-Bolz")
  eq(L().Victim("Carla-Klee"), nil); eq(L().Victim("Dora-Damm"), nil)
end)

test("Victim never seen: first name from GetPlayerInfoByGUID, level unknown", function()
  load(40); party()
  M.units.ghost = { exists = false, isPlayer = true, name = "Geist", guid = "Player-93-Geist", class = "MAGE", classLoc = "Magier" }
  pk(MATE, "Player-93-Geist"); M.Advance(0.4); kc(); M.Advance(5)
  eq(#own, 1)
  local row = L().Log()[1]
  eq(row.band, "unbekannt"); eq(row.vl, nil); ok(row.f:find("u", 1, true))
  eq(L().Victim(own[1].key).name, "Geist")
end)

---------------------------------------------------------------------------
-- Revenge on a listed enemy by a group kill
---------------------------------------------------------------------------
test("Revenge by a group kill: standing +1, bounty as with the recognised revenge, no double count", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g, level = 40 }, { t = time() - 100 }, true)
  local e = ns.Store.Get("Grimm-Bart")
  local mine0, his0 = L().Standing("Grimm-Bart")
  eq(mine0, 0); eq(his0, 1)
  local bounty0 = ns.Store.Bounty(e)
  -- I fight him (target): Attribution counts the revenge at PLAYER_PVP_KILLS_CHANGED
  M.units.target = M.units["nameplate" .. plate]; M.FireEvent("PLAYER_TARGET_CHANGED")
  pk(MATE, g); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(10)
  eq(#own, 1)
  eq(ns.Store.Get("Grimm-Bart").revenge, 1, "Attribution: one revenge")
  local mine1, his1, state1 = L().Standing("Grimm-Bart")
  eq(mine1, 1, "standing +1, not +2"); eq(his1, 1); eq(state1, "even")
  local row = L().Log()[1]
  ok(row.f:find("v", 1, true), "revenge flag"); ok(row.f:find("o", 1, true))
  -- the bounty: as in 1.3.0 with one recognised revenge (1 / 1.5 of the base), never more, never less
  local base = 250000 + 40 * 1000
  eq(ns.Store.Bounty(ns.Store.Get("Grimm-Bart")), math.max(10000, math.floor(base / 1.5 / 100 + 0.5) * 100))
  ok(ns.Store.Bounty(ns.Store.Get("Grimm-Bart")) < bounty0)
  eq(L().Repute().best.quick, nil, "quickest revenge only for own blows")
end)

test("Revenge by a group kill when Attribution does not see it (not engaged): standing +1 all the same", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g, level = 40 }, { t = time() - 100 }, true)
  pk(MATE, g); M.Advance(0.4); kc(); M.Advance(10)
  eq(ns.Store.Get("Grimm-Bart").revenge, 0)
  local mine1, his1 = L().Standing("Grimm-Bart")
  eq(mine1, 1); eq(his1, 1)
  eq(ns.Store.Bounty(ns.Store.Get("Grimm-Bart")), math.floor(290000 / 1.5 / 100 + 0.5) * 100)
end)

test("A reload keeps the group kill and changes no standing", function()
  load(40); party()
  local g = seen("Grimm", "Bart", 40)
  pk(MATE, g); M.Advance(0.4); kc(); M.Advance(5)
  local db = _G.DeathNoteDB
  ns = M.Load({ db = db })
  eq(ns.Ledger.Victim("Grimm-Bart").n, 1)
  ok(ns.Ledger.Log()[1].f:find("o", 1, true), "flag o survives the check at start")
end)

M.done("ledger_group")
