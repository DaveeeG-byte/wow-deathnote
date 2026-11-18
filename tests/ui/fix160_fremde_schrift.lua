-- 1.6.0: a player name in another script (Cyrillic, Chinese, Korean) showed as boxes on a Latin client: the
-- ornamental Latin fonts have no such glyphs. A string whose font came from Look.Font now takes the fonts of the
-- script its text needs, and goes back when the next text is Latin. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local J = dofile(DIR .. "/tests/ui/_ju.lua")
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local Look, L = ns.Look, ns.Locale
local CYR, HAN, KOR = "\208\147\209\128\208\184\208\188\208\188", "\230\173\187\231\165\158", "\236\163\189\236\157\140"

J.check("Latein braucht nichts", L.TextScript("Grimm Bärt") == nil)
J.check("Kyrillisch erkannt", L.TextScript(CYR) == "cyrillic", L.TextScript(CYR))
J.check("Chinesisch erkannt", L.TextScript(HAN) == "hans", L.TextScript(HAN))
J.check("Koreanisch erkannt", L.TextScript(KOR) == "korean", L.TextScript(KOR))
J.check("im Satz erkannt", L.TextScript("Rache an " .. CYR .. ": 2 : 5") == "cyrillic")
J.check("russischer Client deckt Kyrillisch selbst", L.TextScript(CYR, "ruRU") == nil)
J.check("chinesischer Client deckt Chinesisch selbst", L.TextScript(HAN, "zhCN") == nil)
J.check("russischer Client braucht fuer Chinesisch die chinesische Schrift", L.TextScript(HAN, "ruRU") == "hans")

local parent = BM.G.CreateFrame("Frame", nil, BM.G.UIParent)
for _, kind in ipairs({ "hand", "body", "title", "type" }) do
  local fs = Look.Text(parent, kind, 14)
  fs:SetText("Grimm")
  local latin = fs._font
  fs:SetText(CYR)
  local want = L.FontList(Look.FONT_KIND[kind] or kind, nil, "cyrillic")[1]
  J.check(kind .. ": kyrillischer Name in kyrillischer Schrift", fs._font == want, tostring(fs._font))
  J.check(kind .. ": Text gesetzt", fs:GetText() == CYR)
  fs:SetText(HAN)
  J.check(kind .. ": chinesischer Name in chinesischer Schrift",
    fs._font == L.FontList(Look.FONT_KIND[kind] or kind, nil, "hans")[1], tostring(fs._font))
  fs:SetText(KOR)
  J.check(kind .. ": koreanischer Name in koreanischer Schrift",
    fs._font == L.FontList(Look.FONT_KIND[kind] or kind, nil, "korean")[1], tostring(fs._font))
  fs:SetText("Grimm")
  J.check(kind .. ": danach wieder die eigene Schrift", fs._font == latin, tostring(fs._font))
  J.check(kind .. ": Groesse bleibt", fs._fontSize == 14, tostring(fs._fontSize))
end
-- size steps of Look.FitText keep the script
local fit = Look.Text(parent, "hand", 19); fit:SetWidth(40)
Look.FitText(fit, CYR .. CYR .. CYR, { sizes = { 13, 16, 19 } })
J.check("FitText: bleibt in kyrillischer Schrift", fit._font == L.FontList(Look.FONT_KIND.hand or "hand", nil, "cyrillic")[1], tostring(fit._font))
-- the book: an enemy with a Cyrillic name on the poster
ns.Store.ApplyKill({ name = CYR, surname = "", guid = "Player-93-Kyr" }, { t = time() - 500, zone = "Z", source = "recap" }, true)
J.check("keine Fehler", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
J.done()
