-- Fund: Steht ein Ziel der Abschussliste auch im eigenen Buch, entscheidet allein das eigene Buch.
-- (a) Begnadigt oder nur Verdacht im eigenen Buch: kein Alarm, obwohl die Gilde das Ziel freigegeben hat.
--     (fix-1, Entscheidung des Orchestrators: begnadigt gewinnt, kein Alarm, das Plakat nennt die Liste;
--     Verdacht ohne eigenen Alarm: Alarm der Abschussliste)
-- (b) Eigener Gesuchter, der zugleich freigegeben ist: der Alarm nennt die Abschussliste nicht.
-- (c) Eigener Todesstoss auf ein Ziel, das im eigenen Buch steht, ohne dass Rache gezaehlt wird
--     (z. B. begnadigt): gar kein Fenster, weder Rache noch Erlegt.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/../?.lua;" .. (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
package.path = H.DIR .. "/tests/ui/?.lua;" .. package.path
local AM = H.M
local BM = require("mock")
local DIR = H.DIR .. "/DeathNote"
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local ns = AM.Load({ noLogin = true, before = function() AM.units.player.guild = "Die Testgilde" end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function guildMsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
tick(30); settle()
local P = ns.Guild.Proto
local function popupFor(name)
  local p = rawget(G, "DeathNoteAlert")
  return p and p:IsShown() and (p.name._text or ""):find(name, 1, true) ~= nil
end
local function sehen(token, name, surname, guid)
  -- das vorige Popup laeuft von selbst ab (Zustand des Alarms bleibt sauber)
  for _ = 1, 4 do settle(); BM.Advance(120); AM.Advance(120) end
  local pp = rawget(G, "DeathNoteAlert")
  assert(not (pp and pp:IsShown()), "Popup steht noch")
  AM.units.mouseover = nil
  AM.AddEnemy("mouseover", { name = name, surname = surname, guid = guid })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
end

-- Kontrolle: Ziel, das nicht im eigenen Buch steht
guildMsg(P.EncodeHunt({ key = "Frei-Wild", display = "Frei Wild", t = time(), by = "Kollege Wurst", why = "x" }))
tick(1)
sehen("mouseover", "Frei", "Wild", "Player-1-FW")
H.erwartet("Kontrolle: Ziel der Abschussliste alarmiert", popupFor("Frei"))

-- (a) im eigenen Buch begnadigt: (fix-1, Entscheidung) die eigene Begnadigung gewinnt, kein Alarm;
-- das Plakat zeigt aber, dass das Ziel auf der Abschussliste steht
local k = ns.Store.AddManual("Gnade", "Vorrecht")
ns.Store.SetStatus(k, "pardoned")
guildMsg(P.EncodeHunt({ key = k, display = "Gnade Vorrecht", t = time(), by = "Kollege Wurst", why = "Gilde jagt ihn" }))
tick(1)
sehen("mouseover", "Gnade", "Vorrecht", "Player-1-GV")
H.erwartet("begnadigt im eigenen Buch: kein Alarm (die Begnadigung gewinnt)", not popupFor("Gnade"), "Alarm")
ns:Fire("TOGGLE_UI"); tick(1); settle()
ns.UI.ShowEnemy(k); tick(1)
local onPoster = false
for _, f in ipairs(BM.frames) do
  if f._kind == "FontString" and type(f._text) == "string" and f:IsVisible() and f._text:find(ns.L.POSTER_ON_HUNTLIST:match("^[^{]+"), 1, true) then onPoster = true end
end
H.erwartet("das Plakat des Begnadigten nennt die Abschussliste", onPoster)
ns:Fire("TOGGLE_UI"); tick(1); settle()

-- (a2) im eigenen Buch nur Verdacht (Verdachtsalarm aus): der Alarm der Abschussliste kommt
local ks = ns.Store.AddManual("Nur", "Verdacht")
ns.Store.SetStatus(ks, "suspect")
ns.Store.Setting("alert.suspects", false)
guildMsg(P.EncodeHunt({ key = ks, display = "Nur Verdacht", t = time(), by = "Kollege Wurst", why = "Gilde jagt ihn" }))
tick(1)
sehen("mouseover", "Nur", "Verdacht", "Player-1-NV")
H.erwartet("nur Verdacht im eigenen Buch: Alarm der Abschussliste", popupFor("Nur"), "kein Alarm")

-- (b) eigener Gesuchter und freigegeben: der Alarm nennt die Abschussliste
local k2 = ns.Store.AddManual("Beides", "Zugleich")
guildMsg(P.EncodeHunt({ key = k2, display = "Beides Zugleich", t = time(), by = "Kollege Wurst", why = "Gilde jagt ihn" }))
tick(1)
sehen("mouseover", "Beides", "Zugleich", "Player-1-BZ")
local p = rawget(G, "DeathNoteAlert")
local h = ns.Guild.Hunt(k2, "all")
local erwaehnt = false
if p and p:IsShown() and h then
  -- sprachneutral: der Text des Popups (Titel oder Zeile) gleicht dem eines reinen Abschuss-Ziels oder nennt den Freigebenden
  local line, title = tostring(p.line._text or ""), tostring(p.title._text or "")
  erwaehnt = line:find("Kollege", 1, true) ~= nil or line:find("Gilde jagt ihn", 1, true) ~= nil
end
H.erwartet("Vorbedingung: Alarm fuer den eigenen Gesuchten", popupFor("Beides"))
H.erwartet("der Alarm nennt, dass es ein Ziel der Abschussliste ist (Freigebender oder Grund im Popup)", erwaehnt,
  p and (tostring(p.title._text) .. " / " .. tostring(p.line._text)))

-- (c) eigener Todesstoss auf das begnadigte Ziel: irgendein Fenster
settle(); BM.Advance(60); AM.Advance(60)
if rawget(G, "DeathNoteBanner") then rawget(G, "DeathNoteBanner"):Hide() end
AM.units.mouseover = nil
AM.AddEnemy("mouseover", { name = "Gnade", surname = "Vorrecht", guid = "Player-1-GV" })
AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
AM.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-1-GV"); tick(1)
local hh = ns.Guild.Hunt(k, "all")
H.erwartet("Vorbedingung: der Todesstoss wurde als erlegt gezaehlt", hh and (hh.bagged or 0) == 1, hh and hh.bagged)
H.erwartet("ein Fenster je Ereignis: der eigene Todesstoss zeigt Rache ODER Erlegt", rawget(G, "DeathNoteBanner") and rawget(G, "DeathNoteBanner"):IsShown(),
  "kein Fenster")
H.erwartet("keine Lua-Fehler", #AM.errors == 0, AM.errors[1]); AM.errors = {}
H.fertig()
