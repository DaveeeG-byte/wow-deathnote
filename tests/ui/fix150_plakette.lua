-- 1.5.0 fixer (U13): the grey thumbtack ("attacks only") on the nameplate carries a light rim, so it reads on dark
-- ground: a bone-white disc where its head is (plate_rim.tga), 2 x Plate.RIM bigger, one layer below. The other marks have no rim, and a
-- mark taken from the pool for another kind loses it. Stand-in plates as in tests/ui/grip.lua. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local J = dofile(DIR .. "/tests/ui/_ju.lua")
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Plate.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
local frames = {}
rawset(BM.G, "C_NamePlate", { GetNamePlateForUnit = function(unit)
  local f = frames[unit]
  if f == nil then
    f = BM.G.CreateFrame("Frame", nil, BM.G.UIParent); f:SetSize(110, 40)
    f:SetPoint("CENTER", BM.G.UIParent, "CENTER", 0, 0); frames[unit] = f
  end
  return f
end })
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local function plate(token, name, surname)
  AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name })
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
end
local function gone(token) AM.FireEvent("NAME_PLATE_UNIT_REMOVED", token); AM.units[token] = nil end
local function tex(t) return tostring(t and (t._tex or t._texture or (t.GetTexture and t:GetTexture())) or "") end
local function bright(t) local c = t and t._vc or { 0, 0, 0 }; return (c[1] + c[2] + c[3]) / 3 end

local P = ns.Plate
local t = time()
ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t - 500, zone = "Z", source = "recap" }, true)
ns.Store.AddAttack({ name = "Nur", surname = "Angriff", guid = "Player-93-Nur" }, { t = t - 60, zone = "Z" })
plate("nameplate1", "Grimm", "Bart")
plate("nameplate2", "Nur", "Angriff")
local mw, mg = P.Active("nameplate1"), P.Active("nameplate2")
J.check("zwei Marken", mw and mg and mg.kind == "grudge" and mw.kind == "wanted", mg and mg.kind)
local rim = mg and mg.rim
J.check("graue Marke: Rand da und sichtbar", rim ~= nil and rim:IsShown())
J.check("Rand: eigenes helles Bild (Scheibe unter dem Nadelkopf)", rim and tex(rim):find("plate_rim", 1, true)
  and io.open(ADDON .. "/Media/plate_rim.tga", "rb") ~= nil, rim and tex(rim))
local RIM = P.RIM or 0
J.check("Rand: ringsum groesser", rim and RIM >= 1 and rim:GetWidth() == mg.icon:GetWidth() + 2 * RIM
  and rim:GetHeight() == mg.icon:GetHeight() + 2 * RIM, rim and rim:GetWidth())
J.check("Rand: unter der Marke (Ebene)", rim and rim._layer == "BACKGROUND" and mg.icon._layer == "ARTWORK", rim and rim._layer)
J.check("Rand: mittig auf der Marke", rim and rim._points and rim._points[1] and rim._points[1][1] == "CENTER"
  and rim._points[1][2] == mg.icon)
J.check("Rand: heller als die graue Marke", rim and bright(rim) > bright(mg.icon) and bright(rim) >= 0.9, rim and bright(rim))
J.check("gesuchte Marke: kein Rand", not (mw.rim and mw.rim:IsShown()))
-- the pool: the grey mark goes, a wanted one takes its frame and must not keep the rim
gone("nameplate2")
ns.Store.ApplyKill({ name = "Neu", surname = "Ling", guid = "Player-93-Neu" }, { t = t - 30, zone = "Z", source = "recap" }, true)
plate("nameplate3", "Neu", "Ling")
local m3 = P.Active("nameplate3")
J.check("aus dem Pool: dieselbe Marke wiederverwendet", m3 == mg, tostring(m3))
J.check("aus dem Pool: gesucht ohne Rand", m3 and not (m3.rim and m3.rim:IsShown()))
J.check("keine Fehler", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
J.done()
