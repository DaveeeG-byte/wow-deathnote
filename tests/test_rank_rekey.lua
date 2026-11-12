-- 1.3.0: the rank store follows a key the book moves (a placeholder "Name-Realm" seen with surname, same GUID):
-- rank 1 stays with him under the new key, with the rap sheet on and switched off (the mutation run of the hunt found
-- this path untested with the rap sheet off). All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq = M.test, M.eq

for _, on in ipairs({ true, false }) do
  test("Rank follows the moved key (rap sheet " .. (on and "on" or "off") .. ")", function()
    local ns = M.Load()
    M.units.player.level = 40
    if not on then ns.Store.Setting("ledger.enabled", false) end
    for i = 1, 3 do
      ns.Store.ApplyKill({ name = "Olli", class = "ROGUE", level = 40, guid = "Player-93-OLLI" }, { t = time() - 100 * i, zone = "Z" }, true)
    end
    ns.Store.ApplyKill({ name = "Bea", surname = "Bu", class = "ROGUE", level = 40, guid = "Player-93-BEA" }, { t = time() - 50, zone = "Z" }, true)
    local old
    for k in pairs(ns.Store.All()) do if k:find("^Olli") then old = k end end
    eq(ns.Store.Rank(old), 1, "rank 1 before the move")
    M.AddEnemy("nameplate1", { name = "Olli", surname = "Ober", level = 40, guid = "Player-93-OLLI", class = "ROGUE" })
    M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); M.Advance(6)
    local new
    for k in pairs(ns.Store.All()) do if k:find("^Olli") then new = k end end
    eq(new, "Olli-Ober", "moved to the full name")
    eq(ns.Store.Rank(new), 1, "rank 1 under the new key")
    eq(ns.Store.Rank(old), nil, "nothing under the old key")
    eq(ns.Store.Rank("Bea-Bu"), 2)
  end)
end

M.done("rank_rekey")
