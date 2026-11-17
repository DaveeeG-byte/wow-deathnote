-- 1.4.0 fixer (hunt UI 1, hunt logic 1 with the notice): the grudge notice lies one layer above the open book and at
-- the bottom of that layer (menus and the first-start dialog stay above it); an episode whose notice is shown but
-- hidden with the whole interface (Alt+Z: the notice does not tick) still ends.
-- Use: luajit tests/ui/fix140_meldung.lua [project folder]
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local good, bad = 0, 0
local function check(name, cond, info)
  if cond then good = good + 1 else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
BM.measure = true
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Humor.lua", "Start.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
_G.UnitAffectingCombat = function(u) local x = AM.units[u]; return x ~= nil and x.combat ~= false end
_G.UnitInParty = function() return false end
local G = BM.G
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local ORDER = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

-- layers
ns:Fire("TOGGLE_UI"); tick(30)
local card, book = rawget(G, "DeathNoteGrudge"), rawget(G, "DeathNoteFrame")
check("Meldung ueber dem Buch", ORDER[card:GetFrameStrata()] > ORDER[book:GetFrameStrata()],
  card:GetFrameStrata() .. " / " .. book:GetFrameStrata())
check("Meldung unter Dialogen und Menues (DIALOG, unterste Ebene)", card:GetFrameStrata() == "DIALOG" and card:GetFrameLevel() <= 1)
local start = rawget(G, "DeathNoteStart")
if ns.Start and ns.Start.Build then pcall(ns.Start.Build) end
start = rawget(G, "DeathNoteStart") or start
check("Startfenster liegt ueber der Meldung", start == nil or (start:GetFrameStrata() == "DIALOG" and start:GetFrameLevel() > card:GetFrameLevel()),
  start and start:GetFrameLevel())
check("Menue liegt ueber der Meldung", ORDER[card:GetFrameStrata()] <= ORDER.DIALOG)

-- Alt+Z: the notice is shown but invisible, it does not tick; the episode ends anyway
ns:Fire("TOGGLE_UI"); tick(1)
AM.inCombat = true; AM.FireEvent("PLAYER_REGEN_DISABLED")
AM.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player" })
AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
tick(0.5)
AM.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 100, 1)
tick(0.5)
AM.inCombat = false; AM.FireEvent("PLAYER_REGEN_ENABLED")
local ep = ns.Grudge.Current()
check("Vorbedingung: Meldung gezeigt", ep and card:IsShown())
G.UIParent:Hide()
check("Alt+Z: unsichtbar", not card:IsVisible())
tick(ns.Grudge.Seconds() + (ns.Grudge.EXPIRE_GRACE or 15) + 2)
check("Episode endet trotzdem", ep and ep.closed == true and ns.Grudge.Current() == nil)
G.UIParent:Show()
check("Meldung weg", not card:IsShown())
check("Grimm nicht eingetragen", ns.Store.Get("Grimm-Bart") == nil)
check("keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])

io.write(("fix140 meldung UI: %d gruen, %d rot\n"):format(good, bad))
os.exit(bad == 0 and 0 or 1)
