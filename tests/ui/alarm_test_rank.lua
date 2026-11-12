-- 1.3.0: the test alarm (/dn test, the test button) shows rank 1 of Wanted. With the rap sheet on rank 1 follows the
-- open debt: a settled enemy with the most kills (3 : 3) is not the one, the open case (0 : 1) is. With the rap sheet
-- off the kill order of 1.2.x stays.
-- Call from the project root: luajit tests/ui/alarm_test_rank.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "alarm_test_rank")
local check = K.check

for _, on in ipairs({ true, false }) do
  local ns = K.world("deDE")
  local AM, BM, G = K.AM, K.BM, K.G
  AM.units.player.level = 40
  K.tick(30); K.settle()
  if not on then ns.Store.Setting("ledger.enabled", false) end
  local me = AM.units.player.guid or "Player-93-0000AAAA"
  local function killsMe(name, surname, n)
    for i = 1, n do
      ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
        { t = time() - 3000 * i, zone = "Z" }, true)
    end
    return ns.Util.KeyFor(name, surname)
  end
  local even = killsMe("Egon", "Eben", 3)
  AM.AddEnemy("nameplate1", { name = "Egon", surname = "Eben", level = 40, guid = "Player-93-EgonEben", class = "MAGE" })
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  for _ = 1, 3 do AM.FireEvent("PARTY_KILL", me, "Player-93-EgonEben"); K.tick(61) end
  local open = killsMe("Olga", "Offen", 1)
  K.settle()
  ns.Alert.Test(); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  local shown = popup and popup:IsShown() and popup.name and popup.name._text or "?"
  if on then
    check("rap sheet on: rank 1 is the open case", ns.Store.Rank(open) == 1, ns.Store.Rank(open))
    check("rap sheet on: the test alarm shows rank 1", tostring(shown):find("Olga", 1, true) ~= nil, shown)
  else
    check("rap sheet off: rank 1 by kills", ns.Store.Rank(even) == 1, ns.Store.Rank(even))
    check("rap sheet off: the test alarm shows the one with the most kills", tostring(shown):find("Egon", 1, true) ~= nil, shown)
  end
  check((on and "on" or "off") .. ": no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("test alarm shows rank 1")
