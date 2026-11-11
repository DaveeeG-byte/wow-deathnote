-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen (Aufruf aus der Projektwurzel: luajit <datei> .)
-- Kampf an den Stellen, die seit dem Fixer neu sind (Gegenprobe, erwartet gruen): Alarm mit Stufe und Warnzeile
-- fuer ein Ziel der Abschussliste, Meldungen "erlegt" und "neue Ziele", Ausblenden, Alle abblasen, beide
-- Leeren-Knoepfe, Blatt Gilde mit allen Schaltern und Stufen, Sprachwahl in der Hausordnung, Kampfbeginn und
-- Kampfende bei offenem Popup. Der strenge UI-Mock meldet jede geschuetzte Aktion im Kampf als Verstoss.
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow"); local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
local G = BM.G
local pass, fail, lines = 0, 0, {}
local function erwartet(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "") end
end
AM.locale = "enUS"
local ns = AM.Load({ noLogin = true, before = function() AM.units.player.guild = "Die Testgilde" end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local P = ns.Guild.Proto
tick(30); settle(); AM.Advance(120)
gmsg(P.EncodeHunt({ key = "Ziel-Eins", t = _G.time(), by = "Kollege Lang", why = "Grund", level = 60, class = "MAGE" }))
gmsg(P.EncodeHunt({ key = "Ziel-Zwei", t = _G.time(), by = "Kollege Lang", why = "Grund" }))
ns.Guild.Release("Mein-Ziel", { to = "all", why = "meins" })
tick(12); settle()
erwartet("Vorbedingung: drei Ziele", ns.Guild.HuntCount("all") == 3, ns.Guild.HuntCount("all"))

local function kampf(v)
  AM.inCombat, BM.combat = v, v
  AM.FireEvent(v and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED"); tick()
end
kampf(true)
BM.levels.player, BM.levels.mouseover = 40, 60
AM.AddEnemy("mouseover", { name = "Ziel", surname = "Eins", guid = "Player-1-ZE", level = 60 })
AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
local popup = rawget(G, "DeathNoteAlert")
erwartet("Alarm im Kampf fuer ein Ziel der Abschussliste, Stufe mit Abstand (fix-3)", popup and popup:IsShown()
  and (popup.level._text or ""):find("(+20)", 1, true) ~= nil)
kampf(false); kampf(true)                      -- Kampfende und neuer Kampf bei offenem Popup
ns:Fire("HUNT_BAGGED", "Ziel-Eins", "Kollege Lang", _G.time(), "guild"); tick()
ns:Fire("HUNT_NEW", 3, "Ziel-Zwei", "Kollege Lang", "guild"); tick()
ns:Fire("TOGGLE_UI"); tick()
ns.UI.ShowHunts("Ziel-Eins"); tick()
ns.Guild.HideHunt("Ziel-Eins", true); tick(1)
ns.UI.ShowHunts("Ziel-Eins"); tick()
ns.Guild.HideHunt("Ziel-Eins", false); tick(1)
for _, f in ipairs(BM.frames) do
  if f.item and f._scripts and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "RightButton"); break end
end
tick()
ns.UI.OpenPanel("settings"); tick()
for _, f in ipairs(BM.frames) do
  local fs = f.text
  local tx = type(fs) == "table" and fs._text
  if (tx == ns.L.SHEET_GUILD or tx == ns.L.SHEET_BOOK) and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); tick() end
end
-- jeden sichtbaren Haken und jeden Pfeil der Hausordnung im Kampf bedienen
local n = 0
for _, f in ipairs(BM.frames) do
  if (f._kind == "CheckButton" or (f._kind == "Button" and f.tri)) and f:IsVisible() and f._scripts.OnClick then
    local ok = pcall(f._scripts.OnClick, f, "LeftButton"); n = n + 1
    if not ok then erwartet("Klick in der Hausordnung im Kampf", false, "Fehler") end
  end
end
tick()
for _, which in ipairs({ "DEATHNOTE_CALLOFF_ALL", "DEATHNOTE_GUILD_CLEAR", "DEATHNOTE_FRIENDS_CLEAR" }) do
  local d = G.StaticPopupDialogs[which]
  erwartet("Rueckfrage " .. which .. " vorhanden", d ~= nil and type(d.OnAccept) == "function")
  if d then d.OnAccept() end
  tick(2)
end
erwartet("Alle abblasen im Kampf: bei mir sofort weg", ns.Guild.OwnReleaseCount() == 0, ns.Guild.OwnReleaseCount())
ns.UI.ClosePanel(); tick(); ns:Fire("TOGGLE_UI"); tick()
kampf(false); tick(5); settle()
erwartet(("keine Fehler (%d Klicks in der Hausordnung)"):format(n), #AM.errors == 0, AM.errors[1])
erwartet("keine geschuetzte Aktion im Kampf", #BM.violations == 0, BM.violations[1])
io.write(("beleg_f17_kampf_neue_stellen %3d gruen, %d rot\n"):format(pass, fail))
for _, l in ipairs(lines) do io.write(l .. "\n") end
os.exit(fail == 0 and 0 or 1)
