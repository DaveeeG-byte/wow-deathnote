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
local MATE2 = "Player-93-0000CCCC"
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
-- a group of three: the second mate in party2
local function party3()
  party()
  M.units.party2 = { exists = true, isPlayer = true, name = "Zweiter", surname = "Mann", guid = MATE2, faction = "Horde",
    level = 40 }
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
  load(40); party(); M.Advance(L().QUIET)     -- away from the login
  local g = seen("Grimm", "Bart", 40)
  kc(); M.Advance(0.6); pk(MATE, g)
  eq(#own, 1, "proof 0.6 s before")
  M.Advance(20)
  local h = seen("Hanna", "Hain", 40)
  kc(); M.Advance(1.5); pk(MATE, h); M.Advance(5)
  eq(#own, 1, "proof 1.5 s before: too early")
end)

-- 1.3.1 hunt N5: a counter or honour line right after login or a loading screen is no kill
test("A proof right after PLAYER_ENTERING_WORLD is dropped, not kept for the next PARTY_KILL", function()
  load(40); party(); M.Advance(30)
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  M.FireEvent("PLAYER_ENTERING_WORLD"); kc(); M.Advance(0.8); pk(MATE, a); M.Advance(15)
  eq(#own, 0, "the counter of the login")
  M.FireEvent("PLAYER_ENTERING_WORLD"); M.Advance(L().QUIET + 0.1)
  kc(); M.Advance(0.6); pk(MATE, b); M.Advance(15)
  eq(#own, 1, "after the quiet seconds a proof before the PARTY_KILL counts again")
end)

test("A mate's kill waiting for its proof ends at a loading screen", function()
  load(40); party(); M.Advance(30)
  local a = seen("Anna", "Ast", 40)
  pk(MATE, a); M.Advance(0.2); M.FireEvent("PLAYER_ENTERING_WORLD"); M.Advance(0.3); kc(); M.Advance(15)
  eq(#own, 0)
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

test("One proof (kills changed and its honour line) for two PARTY_KILLs, both victims seen = one kill, the older", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(0.5); pk(MATE, b)
  M.Advance(0.4); kc(); M.Advance(0.6); honor()
  M.Advance(10)
  eq(#own, 1); eq(own[1].key, "Anna-Ast")
  eq(L().Victim("Bernd-Bolz"), nil)
end)

-- 1.3.1 hunt H3: two mates' kills within 3 s, I took part only in the second; the proof goes to the near victim
test("One proof for two mates' kills: my target wins over a victim I never saw, though that one is older", function()
  load(40); party3()
  M.units.far = { exists = false, isPlayer = true, name = "Anna", guid = "Player-93-AnnaFern" }
  local b = seen("Bernd", "Bolz", 40)
  M.units.target = M.units["nameplate" .. plate]; M.FireEvent("PLAYER_TARGET_CHANGED")
  pk(MATE, "Player-93-AnnaFern"); M.Advance(1); pk(MATE2, b); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
  eq(#own, 1); eq(own[1].key, "Bernd-Bolz")
end)

test("One proof for two mates' kills: a victim fresh in the tracker wins over one seen too long ago", function()
  load(40); party3()
  local a = seen("Anna", "Ast", 40)
  M.Advance(30)
  local b = seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(1); pk(MATE2, b); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
  eq(#own, 1); eq(own[1].key, "Bernd-Bolz")
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

-- 1.3.1 hunt H1: the mate's kill is the older one, mine comes 0.5 to 2.6 s later; the proofs are those of my kill
for _, d in ipairs({ 0.5, 1, 2, 2.3, 2.6 }) do
  test("My own kill " .. d .. " s after a mate's kill out of my reach: its proofs book only mine", function()
    load(40); party()
    local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
    pk(MATE, a); M.Advance(d); pk(ME, b); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
    eq(#own, 1); eq(own[1].key, "Bernd-Bolz")
    eq(L().Victim("Anna-Ast"), nil, "the mate's victim was never mine")
  end)
end

-- 1.3.1 hunt H2: two mates' kills 2.1 to 2.6 s apart, I took part only in the second (one pair of proofs). The
-- counter came while the first claim was still open; the honour line of the same kill must not book the second.
for _, d in ipairs({ 2.1, 2.3, 2.6 }) do
  test("Two mates' kills " .. d .. " s apart, one pair of proofs: one kill, never two", function()
    load(40); party3()
    local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
    pk(MATE, a); M.Advance(d); pk(MATE2, b); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
    eq(#own, 1)
    eq(L().Repute().n, 1)
  end)
end

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

-- 1.3.1 hunt N1: my own PARTY_KILL that is dropped brings no proof and takes none from a group kill next to it
test("My own kill that is dropped (duel to the death, my faction, instance) takes no proof from a group kill", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Anna Ast"); M.Advance(5)
  local okk, why = L().OnPartyKill(ME, a)
  no(okk); eq(why, "duel")
  M.Advance(1); pk(MATE, b); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
  eq(#own, 1, "duel"); eq(own[1].key, "Bernd-Bolz")
  local h = seen("Hordi", "Gleich", 40, { faction = "Horde", enemy = false, canAttack = true })
  local g = seen("Grimm", "Bart", 40)
  okk, why = L().OnPartyKill(ME, h)
  no(okk); eq(why, "faction")
  M.Advance(0.5); pk(MATE, g); M.Advance(0.4); kc(); M.Advance(0.6); honor(); M.Advance(15)
  eq(#own, 2, "my own faction"); eq(own[2].key, "Grimm-Bart")
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
  load(40); party(); M.Advance(L().QUIET)     -- away from the login
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

-- 1.3.1 hunt N3: no GROUP_ROSTER_UPDATE at all; his token shows somebody else at the next PARTY_KILL
test("A former member counts no more at his next PARTY_KILL, even without a roster event", function()
  load(40); party()
  local a, b = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40)
  pk(MATE, a); M.Advance(0.4); kc(); M.Advance(60)
  eq(#own, 1)
  M.units.party1 = { exists = true, isPlayer = true, name = "Neu", guid = MATE2, faction = "Horde" }
  pk(MATE, b); M.Advance(0.4); kc(); M.Advance(15)
  eq(#own, 1, "the former member's kill is not mine")
end)

-- 1.3.1 hunt N4: a read of the roster that meets a secret GUID keeps the members it knew
test("A roster read with a secret GUID keeps the known members until a whole read succeeds", function()
  load(40); party()
  local a, b, c = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40), seen("Carla", "Klee", 40)
  pk(MATE, a); M.Advance(0.4); kc(); M.Advance(30)
  eq(#own, 1)
  M.units.party1.guid = M.Secret("guid", "string")
  M.FireEvent("UNIT_PET", "party1")
  pk(MATE, b); M.Advance(0.4); kc(); M.Advance(15)
  eq(#own, 2, "still a member while his GUID is secret")
  -- a whole read: he is somebody else now
  M.units.party1 = { exists = true, isPlayer = true, name = "Neu", guid = MATE2, faction = "Horde" }
  M.FireEvent("GROUP_ROSTER_UPDATE")
  pk(MATE, c); M.Advance(0.4); kc(); M.Advance(15)
  eq(#own, 2, "gone after a whole read")
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

-- 1.3.1 hunt N2: no name at the PARTY_KILL, the name is there at the proof
test("Victim without a name at the PARTY_KILL: looked up again at the proof and booked", function()
  load(40); party()
  pk(MATE, "Player-93-Spaet")
  M.units.late = { exists = false, isPlayer = true, name = "Spaet", guid = "Player-93-Spaet" }
  M.Advance(0.4); kc(); M.Advance(15)
  eq(#own, 1); eq(L().Victim(own[1].key).name, "Spaet")
end)

test("Victim still without a name at the proof: the proof is not used up, it books the next kill", function()
  load(40); party(); debugOn()
  local g = seen("Grimm", "Bart", 40)
  M.Advance(30)                       -- not near any more: only the name decides
  pk(MATE, "Player-93-Niemand")
  local nobody = caseOf("partykill")
  M.Advance(0.2); pk(MATE, g); M.Advance(0.4); kc(); M.Advance(15)
  eq(#own, 1); eq(own[1].key, "Grimm-Bart")
  eq(nobody.result, "name", "the probe: no name")
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
