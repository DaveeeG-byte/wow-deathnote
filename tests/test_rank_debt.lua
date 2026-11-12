-- Rap sheet (1.3.0, decision 4): the book's rank follows the open debt, and rank 1 (the top title) is always an open
-- case. Settled enemies (even, ahead) have no rank and follow the open ones. With the rap sheet off: the rank of 1.2.x.
-- All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"
local ns
local plate = 0
local function seen(name, surname, level)
  plate = plate + 1
  local guid = "Player-93-" .. name .. surname
  M.AddEnemy("nameplate" .. plate, { name = name, surname = surname, level = level or 40, guid = guid })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return guid
end
-- he kills me n times (the book's own way in, as Attribution writes it)
local function killsMe(name, surname, n)
  for i = 1, n do
    ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
      { t = time() - 1000 * i, zone = "Schlingendorntal" }, true)
  end
  return ns.Util.KeyFor(name, surname)
end
-- I kill him n times (PARTY_KILL with my GUID; a minute apart, no dedupe)
local function iKill(name, surname, n)
  local g = seen(name, surname, 40)
  for _ = 1, n do M.FireEvent("PARTY_KILL", ME, g); M.Advance(60) end
end
local function ranks()
  local out = {}
  for _, k in ipairs({ "Anna-Ast", "Grimm-Bart", "Bernd-Bolz" }) do out[#out + 1] = tostring(ns.Store.Rank(k)) end
  return table.concat(out, " ")
end

test("Rank by kills while nobody is settled (same as 1.2.x)", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 3); killsMe("Grimm", "Bart", 2); killsMe("Bernd", "Bolz", 1)
  eq(ranks(), "1 2 3")
  eq(ns.Store.RankOrder(), "debt")
end)

test("A settled enemy loses his rank; the open ones move up; the top title goes to an open case", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 3); killsMe("Grimm", "Bart", 2); killsMe("Bernd", "Bolz", 1)
  iKill("Anna", "Ast", 3)
  local _, _, st = ns.Ledger.Standing("Anna-Ast")
  eq(st, "even")
  eq(ranks(), "nil 1 2", "Anna even: no rank; Grimm is rank 1 now")
  local list = ns.Store.Ranked("wanted", "debt")
  eq(list[1].key, "Grimm-Bart"); eq(list[2].key, "Bernd-Bolz"); eq(list[3].key, "Anna-Ast")
  -- ahead: no rank either
  iKill("Grimm", "Bart", 3)
  eq(ranks(), "nil nil 1")
  -- the open debt decides before the kills: Bernd 0 : 1 is rank 1 although Anna and Grimm killed me more often
  ok(ns.Store.Rank("Bernd-Bolz") == 1)
end)

test("Everyone settled: no rank 1 anywhere", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 1); killsMe("Grimm", "Bart", 1)
  iKill("Anna", "Ast", 1); iKill("Grimm", "Bart", 2)
  eq(ranks(), "nil nil nil")
end)

test("His kill reopens the debt: the rank comes back at once (cache emptied by the standing)", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 1); killsMe("Grimm", "Bart", 2)
  iKill("Anna", "Ast", 1)
  eq(ranks(), "nil 1 nil")
  killsMe("Anna", "Ast", 2)
  eq(ranks(), "1 2 nil", "Anna 1 : 3 has the bigger debt")
end)

test("My kill settles him: the rank goes at once (the cache is emptied by STANDING_CHANGED, no ENEMY_UPDATED)", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 2); killsMe("Grimm", "Bart", 1)
  eq(ranks(), "1 2 nil")
  iKill("Anna", "Ast", 2)
  eq(ranks(), "nil 1 nil")
end)

test("Ledger.Clear reopens a debt the book never saw as revenge: rank 1 at once", function()
  ns = M.Load()
  M.units.player.level = 40
  iKill("Anna", "Ast", 2)                 -- before she is in the book
  killsMe("Anna", "Ast", 1); killsMe("Grimm", "Bart", 2)
  eq(ranks(), "nil 1 nil", "Anna 2 : 1, ahead")
  ns.Ledger.Clear()
  eq(ranks(), "2 1 nil", "Anna 0 : 1 is open again")
end)

test("The cached debt order follows a standing change without a book change (Ledger.Clear flips the order)", function()
  ns = M.Load()
  M.units.player.level = 40
  iKill("Anna", "Ast", 3)
  killsMe("Anna", "Ast", 3); killsMe("Grimm", "Bart", 1)
  eq(ranks(), "nil 1 nil", "Anna 3 : 3")
  ns.Store.Ranked("wanted", "debt")
  ns.Ledger.Clear()
  eq(ranks(), "1 2 nil", "Anna 0 : 3 leads Grimm 0 : 1")
  eq(ns.Store.Ranked("wanted", "debt")[1].key, "Anna-Ast")
end)

test("Rap sheet off: the rank of 1.2.x, settled or not; on again: the debt order", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 3); killsMe("Grimm", "Bart", 2); killsMe("Bernd", "Bolz", 1)
  iKill("Anna", "Ast", 3)
  eq(ranks(), "nil 1 2")
  ns.Store.Setting("ledger.enabled", false)
  eq(ns.Store.RankOrder(), "rank")
  eq(ranks(), "1 2 3")
  ns.Store.Setting("ledger.enabled", true)
  eq(ranks(), "nil 1 2")
end)

test("RankBefore: the revenge that settles the top enemy took down rank 1 (public enemy down)", function()
  ns = M.Load()
  M.units.player.level = 40
  local anna = killsMe("Anna", "Ast", 1)
  local grimm = killsMe("Grimm", "Bart", 3)
  ns.Store.AddRevenge(anna, true)
  eq(ns.Store.Rank(anna), nil, "Anna 1 : 1")
  eq(ns.Store.RankBefore(anna), 2, "before: Grimm 0 : 3 led")
  ns.Store.AddRevenge(grimm, true); ns.Store.AddRevenge(grimm, true); ns.Store.AddRevenge(grimm, true)
  eq(ns.Store.Rank(grimm), nil, "Grimm 3 : 3")
  eq(ns.Store.RankBefore(grimm), 1, "before: Grimm 2 : 3 was the only open case")
  ns.Store.AddRevenge(grimm, true)
  eq(ns.Store.RankBefore(grimm), nil, "4 : 3: he was even before, no rank")
  ns.Store.Setting("ledger.enabled", false)
  eq(ns.Store.RankBefore(grimm), ns.Store.Rank(grimm), "off: the rank of 1.2.x")
end)

test("Pardoned and suspects have no rank, as before", function()
  ns = M.Load()
  M.units.player.level = 40
  killsMe("Anna", "Ast", 3); killsMe("Grimm", "Bart", 2)
  ns.Store.SetStatus("Anna-Ast", "pardoned")
  eq(ns.Store.Rank("Anna-Ast"), nil)
  eq(ns.Store.Rank("Grimm-Bart"), 1)
end)

M.done("rank_debt")
