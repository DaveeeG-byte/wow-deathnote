-- 1.3.0: the rap sheet's own key for a namesake ("Name-Realm#<guid>") stays inside the rap sheet. The own book holds a
-- placeholder "Rolf" (first name only) with GUID A; another Rolf (GUID B, no surname on his plate) is killed twice.
--   Tracker: the guild's, friends' and hit lists get the plain key "Name-Realm" (as in 1.2.2), never the "#" key.
--   Game tooltip over B: not the book entry of A (the GUID beats the first name); the line RAP SHEET for B.
--   Game tooltip over A: his book entry as before. A book entry without a GUID (entered by hand): as before.
--   B known to the book under another key by his GUID: that entry.
-- Call from the project root: luajit tests/ui/namesake_keys.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "namesake_keys")
local check = K.check
local A, B = "Player-93-AAAA1111", "Player-93-BBBB2222"

local function tipOver(unit, info)
  local AM, BM, G = K.AM, K.BM, K.G
  AM.AddEnemy(unit, info)
  local GT = G.GameTooltip
  GT._unit, GT._lines = unit, {}
  GT.GetUnit = function() return nil, unit end
  if BM.tooltipHook then BM.tooltipHook(GT, {}) end
  return K.plain(table.concat(GT._lines or {}, "\n"))
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local ns = K.world(code)
  local AM, L = K.AM, ns.L
  AM.units.player.level = 60
  K.tick(30); K.settle()
  local me = AM.units.player.guid or "Player-93-0000AAAA"
  -- A killed me once: the book's placeholder "Rolf-Forever" with GUID A
  ns.Store.ApplyKill({ name = "Rolf", class = "WARRIOR", level = 58, guid = A }, { t = time() - 4000, zone = "Z" }, true)
  local hooked = {}
  ns.Tracker.guildHook = function(key) hooked[#hooked + 1] = key end
  for i = 1, 2 do
    AM.AddEnemy("nameplate" .. i, { name = "Rolf", level = 57, guid = B, class = "MAGE" })
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i); K.tick(1)
    AM.FireEvent("PARTY_KILL", me, B); K.tick(70); K.settle()
  end
  local vkey
  for k, v in pairs(ns.Ledger.DB().victims) do if v.guid == B then vkey = k end end
  check(code .. " the rap sheet keeps B under his own key", vkey ~= nil and vkey:find("#", 1, true) ~= nil, vkey)
  local hash = 0
  for _, k in ipairs(hooked) do if k:find("#", 1, true) then hash = hash + 1 end end
  check(code .. " guild, friends' and hit lists got the plain key only", #hooked > 0 and hash == 0, table.concat(hooked, ","))
  check(code .. " ... namely Name-Realm", hooked[#hooked] == "Rolf-Forever", hooked[#hooked])

  local tipB = tipOver("mouseover", { name = "Rolf", level = 57, guid = B, class = "MAGE" })
  check(code .. " tooltip over B: not A's book entry", not tipB:find(L.TIP_IN_BOOK, 1, true), tipB)
  check(code .. " tooltip over B: his rap sheet line", tipB:find(L.TIP_IN_RECORD, 1, true) ~= nil, tipB)
  local tipA = tipOver("mouseover", { name = "Rolf", level = 58, guid = A, class = "WARRIOR" })
  check(code .. " tooltip over A: his book entry", tipA:find(L.TIP_IN_BOOK, 1, true) ~= nil, tipA)
  check(code .. " tooltip over A: no rap sheet line of B", not tipA:find(L.TIP_IN_RECORD, 1, true), tipA)

  -- an entry without a GUID (entered by hand): the name decides as before
  ns.Store.AddManual("Gerd", nil)
  local tipG = tipOver("mouseover", { name = "Gerd", level = 50, guid = "Player-93-CCCC3333", class = "MAGE" })
  check(code .. " entry without a GUID: shown by name as before", tipG:find(L.TIP_IN_BOOK, 1, true) ~= nil, tipG)

  -- B in the book under his full name (same GUID), seen without surname: that entry
  ns.Store.ApplyKill({ name = "Rolf", surname = "Rauh", class = "MAGE", level = 57, guid = B }, { t = time() - 100, zone = "Z" }, true)
  local bk = ns.Store.ByGUID(B)
  local tipB2 = tipOver("mouseover", { name = "Rolf", level = 57, guid = B, class = "MAGE" })
  local eA = ns.Store.Get("Rolf-Forever")
  check(code .. " B in the book by GUID: the book knows him", bk ~= nil and bk ~= "Rolf-Forever", bk)
  check(code .. " B in the book by GUID: the tooltip shows his entry", tipB2:find(L.TIP_IN_BOOK, 1, true) ~= nil, tipB2)
  check(code .. " A's placeholder still has GUID A", eA and eA.guid == A, eA and eA.guid)
  check(code .. " no errors", #AM.errors == 0 and #K.BM.violations == 0, AM.errors[1] or K.BM.violations[1])
end

K.done("namesake keys outside the rap sheet")
