-- Jagd Logik 150/05: Der Plaketten-Pool haelt hoechstens 40 Marken (Plate.MAX_POOL). Sind mehr als 40 markierte
-- Plaketten gleichzeitig sichtbar (Schlachtzug der Gegenseite, Stadtangriff, Abschussliste), gehen beim Verschwinden
-- nur 40 Marken in den Pool, der Rest wird fallen gelassen. Frames gibt das Spiel nie frei: jede solche Welle legt
-- neue Frames an (60 sichtbar, zweimal = 80 gebaute Frames, dreimal = 100 ...). Erwartet: nach der ersten Welle
-- keine neuen Frames (Pool ohne Obergrenze unter den je gebauten, oder Obergrenze fuer gleichzeitige Marken).
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/ui/jagd150.lua"
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Plate.lua", "Humor.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
local frames = {}
rawset(BM.G, "C_NamePlate", { GetNamePlateForUnit = function(unit)
  local f = frames[unit]
  if f == nil then f = BM.G.CreateFrame("Frame", nil, BM.G.UIParent); frames[unit] = f end
  return f
end })
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
_G.UnitAffectingCombat = function() return false end
_G.UnitInParty = function() return false end

local N = 60
local t = _G.time()
for i = 1, N do
  ns.Store.ApplyKill({ name = "Feind", surname = "Nr" .. string.char(64 + (i % 26) + 1) .. i, guid = "Player-93-F" .. i },
    { t = t - 500 - i, zone = "Z", source = "recap" }, true)
end
local function wave()
  for i = 1, N do
    AM.AddEnemy("nameplate" .. i, { name = "Feind", surname = "Nr" .. string.char(64 + (i % 26) + 1) .. i, guid = "Player-93-F" .. i })
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i)
  end
  local shown = ns.Plate.ProbeSnapshot().shown
  for i = 1, N do AM.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate" .. i); AM.units["nameplate" .. i] = nil end
  return shown
end
local s1 = wave()
local b1 = ns.Plate.ProbeSnapshot().counts.built
wave(); wave()
local b3 = ns.Plate.ProbeSnapshot().counts.built
io.write(("jl150-05 pool: %d Marken je Welle, gebaut nach 1 Welle %d, nach 3 Wellen %d\n"):format(s1, b1, b3))
if s1 ~= N then io.write("  Vorbedingung: nicht alle markiert\n"); os.exit(2) end
if b3 > b1 then io.write("  ROT: jede Welle legt neue Frames an (Leck)\n"); os.exit(1) end
io.write("  gruen\n"); os.exit(0)
