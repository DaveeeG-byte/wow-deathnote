-- 1.5.0 fixer: the grudge after the hunt (jl04, jl08, jl09). Rather show than keep quiet: no case that 1.4.0 showed
-- may be missing now; a shown row never goes; the creature counts for its own hit only; a player's pet is no creature
-- and supports its owner where the client says whose it is; a cast belongs to the one who cast it. Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function load()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u)
    local x = M.units[u]
    if not x then return false end
    if x.combat == nil then return true end
    return x.combat
  end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  _G.UnitThreatSituation = function(_, u) local x = M.units[u]; return x and x.threat end
  _G.UnitPlayerControlled = nil
  _G.UnitIsOwnerOrControllerOfUnit = nil
  return ns
end
local function enemy(token, name, surname, o)
  o = o or {}
  o.name, o.surname, o.guid = name, surname, o.guid or ("Player-93-" .. name)
  if o.target == nil then o.target = "player" end
  if o.target == false then o.target = nil end
  local u = M.AddEnemy(token, o)
  if token:find("^nameplate") then M.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  return u
end
local function mob(token, o)
  o = o or {}
  o.isPlayer, o.name, o.guid = false, o.name or "Wolf", o.guid or ("Creature-0-1-2-3-" .. token)
  o.target = "player"
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
  table.sort(out)
  return table.concat(out, ",")
end

-- 1.4.0 showed every enemy player that had me targeted in combat when I was hit (proof a): each of these must be
-- on the notice by the end of the fight at the latest, and asked
local CASES = {
  { "allein", function() end },
  { "Kreatur bei jedem Treffer", function() mob("nameplate5") end },
  { "Kreatur ueber Bedrohung", function() local w = mob("nameplate5"); w.target = nil; w.threat = 2 end },
  { "Begleiter eines Spielers", function() _G.UnitPlayerControlled = function(u) local x = M.units[u]; return x and (x.isPlayer ~= false or x.controlled) or false end
      mob("nameplate5", { controlled = true, guid = "Pet-0-1-2-3-4" }) end },
  { "Begleiter, Spiel kennt UnitPlayerControlled nicht", function() mob("nameplate5", { controlled = true, guid = "Pet-0-1-2-3-4" }) end },
}
for _, c in ipairs(CASES) do
  test("1.4.0-Fall bleibt sichtbar: " .. c[1], function()
    local ns = load()
    local G = ns.Grudge
    fightStart()
    c[2]()
    enemy("nameplate1", "Grimm", "Bart")
    hit(); M.Advance(0.5); M.Advance(1.2); hit(); M.Advance(0.5)
    fightEnd()
    M.Advance(0.5)
    ok(G.Current(), "Episode offen")
    eq(shown(G), "Grimm-Bart")
    ok(G.Asks(), "die Meldung fragt nach ihm")
  end)
end

test("Begleiter mit erkennbarem Besitzer stuetzt ihn: Signal p, sicher", function()
  local ns = load()
  local G = ns.Grudge
  _G.UnitPlayerControlled = function(u) local x = M.units[u]; return x and x.controlled or false end
  _G.UnitIsOwnerOrControllerOfUnit = function(owner, pet)
    return M.units[owner] and M.units[owner].name == "Jaeg" and M.units[pet] and M.units[pet].controlled or false
  end
  fightStart()
  enemy("nameplate1", "Jaeg", "Ling", { class = "HUNTER" })
  mob("nameplate2", { controlled = true, guid = "Pet-0-1-2-3-4" })
  enemy("nameplate3", "Ander", "Er")
  hit(); M.Advance(0.5)
  local ep = G.Current()
  eq(ep.rows["Jaeg-Ling"].proofs.p, true); eq(ep.rows["Jaeg-Ling"].conf, "sure")
  eq(ep.rows["Ander-Er"].proofs.p, nil, "fremdes Tier stuetzt nur seinen Besitzer")
  eq(ep.rows["Ander-Er"].conf, "probable", "ein Tier ist keine Kreatur: nicht zurueckgehalten")
  local c = G.ProbeSnapshot().counts
  eq(c.mob, 0); ok(c.mobPet >= 1); eq(c.p, 1)
  -- secret owner answer: nothing, no error
  _G.UnitIsOwnerOrControllerOfUnit = function() return M.Secret("owner", "boolean") end
  M.Advance(3); hit(); M.Advance(0.5)
  no(M.ContainsSecret(_G.DeathNoteDB))
end)

test("Gezeigt bleibt gezeigt: Kreatur nach dem ersten Treffer, viele Treffer, Kampfende", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  enemy("nameplate1", "Grimm", "Bart")
  hit(); M.Advance(0.5)
  eq(shown(G), "Grimm-Bart")
  mob("nameplate2")
  for _ = 1, 5 do M.Advance(0.7); hit(); M.Advance(0.3); eq(shown(G), "Grimm-Bart") end
  fightEnd(); M.Advance(0.5)
  eq(shown(G), "Grimm-Bart"); ok(G.Asks())
end)

test("Kreatur gilt nur fuer ihren Treffer: zurueckgehalten, dann ein sauberer Treffer -> gezeigt", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  local w = mob("nameplate2")
  enemy("nameplate1", "Grimm", "Bart")
  hit(); M.Advance(0.5)
  eq(G.Current().rows["Grimm-Bart"].conf, "held")
  M.units.nameplate2 = nil; M.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate2"); w.target = nil
  M.Advance(2.5); hit(); M.Advance(0.5)
  eq(G.Current().rows["Grimm-Bart"].conf, "probable"); eq(shown(G), "Grimm-Bart")
end)

test("Zauber gehoert dem, der ihn wirkte: derselbe Spieler ueber Fokus und Ziel behaelt s", function()
  local ns = load()
  local G = ns.Grudge
  fightStart()
  enemy("focus", "Magier", "Eins", { guid = "Player-93-M1" })
  M.FireEvent("UNIT_SPELLCAST_START", "focus")
  M.Advance(0.3)
  M.units.focus = nil
  enemy("target", "Magier", "Eins", { guid = "Player-93-M1" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  hit(); M.Advance(0.5)
  eq(G.Current().rows["Magier-Eins"].proofs.s, true)
end)

M.done("fix150 rachsucht")
