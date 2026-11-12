-- Smoke test for Alert.lua, UI.lua, Extras.lua against the mini mock and the contract stub.
-- Usage: luajit tests/ui/smoke.lua [source folder]   (default: DeathNote/ in the project root)
-- Note 1.2.0: this test finds buttons and texts by their GERMAN labels and therefore runs
-- with deDE (the mock selects the language). Left that way on purpose (moving all checks to keys would be
-- a project of its own); the full run in English and in all languages is tests/ui/sprachen.lua.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local root = here .. "/../.."

-- Addon folder: DeathNote/ (after the rename) or still Staatsfeind/
local function addonDir(root)
  for _, d in ipairs({ "DeathNote", "Staatsfeind" }) do
    local f = io.open(root .. "/" .. d .. "/Alert.lua", "r")
    if f then f:close(); return root .. "/" .. d end
  end
  return root .. "/DeathNote"
end
local M = require("mock")
local makeNs = require("stub")
local src = arg[1] or addonDir(root)
M.mediaDir = addonDir(root) .. "/Media"
local G = M.G

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail and ("  -> " .. detail) or "")) end
end
local ns = makeNs(M)

local function step(name, fn)
  local before = #ns.errors
  local vb = #M.violations
  local ok, err = xpcall(fn, debug.traceback)
  check(name .. " (wirft nicht)", ok, err)
  check(name .. " (Bus-Handler fehlerfrei)", #ns.errors == before, ns.errors[#ns.errors])
  check(name .. " (keine Verstoesse)", #M.violations == vb, M.violations[#M.violations])
end

local function find(pred)
  for _, f in ipairs(M.frames) do if pred(f) then return f end end
end
local function findAll(pred)
  local out = {}
  for _, f in ipairs(M.frames) do if pred(f) then out[#out + 1] = f end end
  return out
end
local function under(f, root)
  local p = f._parent
  while p do if p == root then return true end p = p._parent end
  return false
end
local function anyText(root, needle)
  for _, f in ipairs(M.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true)
       and (not root or under(f, root)) then return f end
  end
end
local function settle() M.Advance(0.01); M.Advance(0.01) end
-- buttons of a stepper row in the house rules by their label (same sheet, same height)
local function stepperButtons(label)
  local lbl = find(function(f) return f._kind == "FontString" and f._text == label end)
  if not lbl then return nil end
  local y = lbl._points[1][3] + 4
  local minus = find(function(f) return f.tri and f._parent == lbl._parent and f._points[1]
    and f._points[1][1] == "TOPLEFT" and f._points[1][3] == y end)
  local plus = minus and find(function(f)
    local a = f.tri and f._points[1] and f._points[1][2]
    return type(a) == "table" and a._points and a._points[1] and a._points[1][2] == minus end)
  return minus, plus
end

local NOW = 1800000000
local function enemy(i, extra)
  local e = { key = "Feind" .. i .. "-Nach" .. i, name = "Feind" .. i, surname = "Nach" .. i, realm = "Nach" .. i,
              class = (i % 2 == 0) and "ROGUE" or "MAGE", status = "wanted", kills = 41 - i, suspected = 0,
              revenge = 0, note = "", firstKill = NOW - 900000, lastKill = NOW - 3600 * i,
              lastSeen = { t = NOW - 60 * i, zone = "Schlingendorntal", subzone = "Grom'gol" }, sightings = i,
              deaths = { { t = NOW - 3600 * i, zone = "Schlingendorntal", subzone = "Grom'gol", me = "Davee",
                           myLevel = 34, theirLevel = 40, spell = "Hinterhalt", source = "recap", sure = true,
                           others = { "Helfer-Eins" } } } }
  if extra then for k, v in pairs(extra) do e[k] = v end end
  return e
end
local function put(e) ns.db.enemies[e.key] = e; return e end

------------------------------------------------------------------------
-- Loading: before READY nothing may be read from the DB and no window built
------------------------------------------------------------------------
local realStore = ns.Store
ns.Store = setmetatable({}, { __index = function(_, k) error("DB vor READY gelesen: Store." .. tostring(k)) end })
local createdBefore = M.created
step("Laden Alert/UI/Extras", function()
  M.Load(src .. "/Alert.lua", ns)
  M.Load(src .. "/UI.lua", ns)
  M.Load(src .. "/Extras.lua", ns)
end)
check("beim Laden keine Frames gebaut (lazy)", M.created == createdBefore, "Frames: " .. (M.created - createdBefore))
ns.Store = realStore

step("READY", function() ns:Fire("READY") end)
check("Minimap-Knopf nach READY da", G.DeathNoteMinimapButton ~= nil)
check("Hauptfenster noch nicht gebaut", rawget(G, "DeathNoteFrame") == nil)

------------------------------------------------------------------------
-- empty list
------------------------------------------------------------------------
step("TOGGLE_UI leer", function() ns:Fire("TOGGLE_UI") end)
local F = rawget(G, "DeathNoteFrame")
check("Fenster gebaut und offen", F and F:IsShown())
check("Leerzustand-Text", anyText(F, "Noch kein Name eingetragen.") ~= nil)
check("ESC-Liste", G.UISpecialFrames[1] == "DeathNoteFrame")
step("TOGGLE_UI schliesst", function() ns:Fire("TOGGLE_UI") end)
check("Fenster zu", not F:IsShown())

-- very first alarm in the middle of combat: popup yes, the secure button must not exist yet
step("erster Alarm im Kampf (Beispiel)", function() M.combat = true; ns:Fire("TEST_ALERT") end)
local popup = rawget(G, "DeathNoteAlert")
check("Popup sichtbar", popup and popup:IsShown())
check("Secure-Knopf im Kampf nicht gebaut", rawget(G, "DeathNoteAlertButton") == nil)
check("Hinweis: nach dem Kampf", anyText(popup, "Anvisieren erst nach dem Kampf") ~= nil)
check("Alarm-Popup unter dem Fehlertext", popup._points[1] and popup._points[1][1] == "TOP" and popup._points[1][5] == -190)
step("Kampfende baut und richtet Knopf ein", function() M.combat = false; ns:FireWow("PLAYER_REGEN_ENABLED") end)
local button = rawget(G, "DeathNoteAlertButton")
check("Secure-Knopf mit Makro", button and (button:GetAttribute("macrotext") or ""):find("/targetexact Grimmzahn Probe", 1, true) ~= nil,
      button and button:GetAttribute("macrotext"))
check("Ton gespielt", #M.sounds > 0)
step("Popup laeuft ab", function() M.Advance(13); M.FinishAnims() end)
check("Popup weg", not popup:IsShown())
check("Secure-Knopf weg", not button:IsShown())

------------------------------------------------------------------------
-- One enemy
------------------------------------------------------------------------
local one = put(enemy(1, { kills = 3, revenge = 2, guild = "Die Bösen", level = 40, raceLoc = "Ork", classLoc = "Magier" }))
step("ENEMY_UPDATED bei geschlossenem Fenster", function() ns:Fire("ENEMY_UPDATED", one.key) end)
step("Fenster oeffnen mit 1 Feind", function() ns:Fire("TOGGLE_UI"); settle() end)
check("Name auf der Liste", anyText(F, "Feind1 Nach1") ~= nil)
check("WANTED auf dem Plakat", anyText(F, "WANTED") ~= nil)
local deedLine = anyText(F, " · Hinterhalt")
check("Tatzeile kurz (Datum · Ort · Zauber)", deedLine and deedLine._text:find("^%d%d%.%d%d%. %d%d:%d%d · Hinterhalt · Grom'gol$") ~= nil,
      deedLine and deedLine._text)
step("Tatzeile Tooltip mit Mittaeter", function()
  local b = deedLine._parent
  G.GameTooltip._lines = {}
  b._scripts.OnEnter(b)
end)
check("Tooltip nennt Mittaeter", (function()
  for _, l in ipairs(G.GameTooltip._lines or {}) do if l:find("Beteiligt: Helfer-Eins", 1, true) then return true end end
end)())
check("Kopfgeld in ganzen Gold", anyText(F, "17 GOLD") ~= nil)
check("Rang 1: Stempel und kein Durchstreichen trotz Rache", (function()
  local r = find(function(f) return f.item == one and f.strike end)
  return r and not r.strike:IsShown() and r.mark._text == "RACHE 2×"
end)())

ns.units.nameplate3 = one.key
local sounds = #M.sounds
step("ENEMY_SPOTTED", function() ns:Fire("ENEMY_SPOTTED", one.key, "nameplate3", "nameplate") end)
check("Popup zeigt Feind", popup:IsShown() and anyText(popup, "Feind1 Nach1") ~= nil)
check("Kopfzeile Nr. 1", anyText(popup, "STAATSFEIND Nr. 1 GESICHTET") ~= nil)
local model = find(function(f) return f._kind == "PlayerModel" end)
check("Modell auf Unit gesetzt", model and model._modelUnit == "nameplate3")
check("Makro auf Vor- und Nachname", (button:GetAttribute("macrotext") or ""):find("/targetexact Feind1 Nach1", 1, true) ~= nil)
check("Ton beim Alarm", #M.sounds == sounds + 1)
local flash = rawget(G, "DeathNoteFlash")
check("Randblitz", flash and flash:IsShown())
step("gleicher Feind in der Abklingzeit", function() ns:Fire("ENEMY_SPOTTED", one.key, "nameplate3", "nameplate") end)
check("kein zweiter Ton", #M.sounds == sounds + 1)
step("Rechtsklick schliesst", function()
  button._scripts.PostClick(button, "RightButton", false)
  M.FinishAnims()
end)
check("Popup nach Rechtsklick zu", not popup:IsShown())

------------------------------------------------------------------------
-- 40 enemies, pool reuse, scrolling
------------------------------------------------------------------------
for i = 2, 40 do put(enemy(i)) end
step("40 Feinde Refresh", function() ns:Fire("ENEMY_UPDATED", "Feind2-Nach2"); settle() end)
local framesAfterFirst = M.created
step("5 weitere Refreshes", function()
  for i = 1, 5 do ns:Fire("ENEMY_UPDATED", "Feind" .. (i + 2) .. "-Nach" .. (i + 2)) end
  settle()
  for i = 1, 5 do ns:Fire("DEATH_RECORDED", { kind = "pve", t = NOW }, nil); settle() end
end)
check("keine neuen Frames beim Refresh (Pool)", M.created == framesAfterFirst, "neu: " .. (M.created - framesAfterFirst))
local slider = find(function(f) return f._kind == "Slider" end)
step("Scrollen per Leiste und Mausrad", function()
  slider:SetValue(25)
  local wheel = find(function(f) return f._scripts.OnMouseWheel ~= nil end)
  wheel._scripts.OnMouseWheel(wheel, -1)
  wheel._scripts.OnMouseWheel(wheel, 50)
end)
check("Rang 40 erreichbar", (function() slider:SetValue(31); return anyText(F, "Feind40 Nach40") ~= nil end)())

------------------------------------------------------------------------
-- Special cases: without class/lastSeen/deeds, suspicion only, pardoned
------------------------------------------------------------------------
local bare = put({ key = "Nackt-X", name = "Nackt", status = "wanted", kills = 1, deaths = {} })
local sus = put({ key = "Vage-Y", name = "Vage", status = "suspect", kills = 0, suspected = 1 })
local par = put(enemy(50, { status = "pardoned", kills = 1 }))
step("Plakat ohne Klasse/lastSeen", function() ns.UI.ShowEnemy(bare.key) end)
check("Noch nicht gesichtet", anyText(F, "Noch nicht gesichtet") ~= nil)
step("Plakat Verdacht", function() ns.UI.ShowEnemy(sus.key) end)
check("Knopf Bestaetigen", anyText(F, "Bestätigen") ~= nil)
step("Verdacht bestaetigen per Knopf", function()
  local b = find(function(f) return f.text and f.text._text == "Bestätigen" and f:IsShown() end)
  b._scripts.OnClick(b, "LeftButton")
  settle()
end)
check("Verdacht ist jetzt gesucht", ns.db.enemies[sus.key].status == "wanted")
step("Plakat begnadigt", function() ns.UI.ShowEnemy(par.key) end)
check("Knopf Wieder jagen", anyText(F, "Wieder jagen") ~= nil)
step("Verdaechtige melden aus: kein Alarm", function()
  put({ key = "Nur-Verdacht", name = "Nur", status = "suspect", suspected = 2 })
  ns:Fire("ENEMY_SPOTTED", "Nur-Verdacht", nil, "mouseover")
end)
check("kein Popup fuer Verdacht", not popup:IsShown())
step("unbekannter/geloeschter Schluessel", function() ns:Fire("ENEMY_SPOTTED", "Gibts-Nicht", nil, "other") end)

------------------------------------------------------------------------
-- queue
------------------------------------------------------------------------
M.Advance(200)
step("drei gleichzeitig", function()
  ns:Fire("ENEMY_SPOTTED", "Feind5-Nach5", nil, "nameplate")
  ns:Fire("ENEMY_SPOTTED", "Feind6-Nach6", nil, "nameplate")
  ns:Fire("ENEMY_SPOTTED", "Feind7-Nach7", nil, "target")
end)
check("+2 weitere", anyText(popup, "+2 weitere") ~= nil)
check("erster zuerst", anyText(popup, "Feind5 Nach5") ~= nil)
step("naechster nach Ablauf", function() M.Advance(12.5); M.FinishAnims(); M.Advance(0.5) end)
check("zweiter sichtbar", popup:IsShown() and anyText(popup, "Feind6 Nach6") ~= nil)
check("+1 weiterer", anyText(popup, "+1 weiterer") ~= nil)
step("Schlange leeren", function()
  for _ = 1, 3 do M.Advance(12.5); M.FinishAnims(); M.Advance(0.5) end
end)
check("Popup am Ende zu", not popup:IsShown())

------------------------------------------------------------------------
-- Combat: popup yes, secure button only after combat
------------------------------------------------------------------------
M.Advance(200)
step("Alarm im Kampf", function()
  M.combat = true
  ns:Fire("ENEMY_SPOTTED", "Feind8-Nach8", nil, "nameplate")
end)
check("Popup im Kampf sichtbar", popup:IsShown())
check("Knopf im Kampf nicht angefasst", not button:IsShown())
check("Hinweis ohne Fehlerton", anyText(popup, "Anvisieren erst nach dem Kampf") ~= nil)
step("Kampfende zieht Ziel nach", function()
  M.combat = false
  ns:FireWow("PLAYER_REGEN_ENABLED")
end)
check("Knopf jetzt aktiv", button:IsShown() and (button:GetAttribute("macrotext") or ""):find("Feind8 Nach8", 1, true) ~= nil)
step("Kampfbeginn nimmt Knopf weg", function()
  ns:FireWow("PLAYER_REGEN_DISABLED")
  M.combat = true
end)
check("Knopf vor dem Lockdown versteckt", not button:IsShown())
step("Popup im Kampf schliessen", function() popup._scripts.OnMouseUp(popup, "RightButton"); M.FinishAnims() end)
M.combat = false
ns:FireWow("PLAYER_REGEN_ENABLED")

------------------------------------------------------------------------
-- death, revenge, journal
------------------------------------------------------------------------
ns.db.deaths = {
  { t = NOW, zone = "Schlingendorntal", kind = "pvp", killerKey = one.key, sure = true, source = "recap", me = "Davee",
    myLevel = 34, spell = "Hinterhalt", counted = true },
  { t = NOW - 10, zone = "Brachland", kind = "pvp", killerKey = nil, candidates = { "Feind2-Nach2", "Feind3-Nach3" },
    sure = false, source = "suspect" },
  { t = NOW - 20, zone = "Arathibecken", kind = "pvp", killerKey = "Feind4-Nach4", sure = true, counted = false },
  { t = NOW - 30, kind = "pve" },
  { kind = "unknown" },
}
local banner
step("DEATH_RECORDED erster Kill", function()
  local e = put(enemy(60, { kills = 1 }))
  ns:Fire("DEATH_RECORDED", ns.db.deaths[1], e.key)
end)
banner = rawget(G, "DeathNoteBanner")
check("Banner neu", banner and banner:IsShown() and anyText(banner, "steht jetzt im Buch") ~= nil)
check("Meldung unter dem Popup", banner._points[1] and banner._points[1][5] == -310)
step("DEATH_RECORDED schon wieder", function() ns:Fire("DEATH_RECORDED", ns.db.deaths[1], one.key) end)
check("Banner schon wieder", anyText(banner, "hat dich zum 3. Mal getötet") ~= nil)
step("DEATH_RECORDED unklar", function() ns:Fire("DEATH_RECORDED", ns.db.deaths[2], nil) end)
check("Banner Kandidaten", anyText(banner, "2 Kandidaten") ~= nil)
step("DEATH_RECORDED PvE", function() ns:Fire("DEATH_RECORDED", ns.db.deaths[4], nil) end)
step("REVENGE", function() ns:Fire("REVENGE", one.key) end)
check("Banner Rache", anyText(banner, "Rache genommen") ~= nil)

step("Journal-Reiter", function()
  local tab = find(function(f) return f.id == "journal" and f._scripts.OnClick end)
  tab._scripts.OnClick(tab)
end)
check("Taeter unklar markiert", anyText(F, "Täter unklar") ~= nil)
check("zaehlt nicht markiert", anyText(F, "ZÄHLT NICHT") ~= nil)
step("Journal-Zeilen anklicken und Taeter festlegen", function()
  local rowsList = findAll(function(f) return f._kind == "Button" and f.item ~= nil and f._shown end)
  for _, r in ipairs(rowsList) do r._scripts.OnClick(r) end
  local r2 = find(function(f) return f.index == 2 and f.item and f._scripts.OnClick end)
  r2._scripts.OnClick(r2)
  local cand = find(function(f) return f.text and f.text._text == "Feind2 Nach2" and f._shown and f.fn end)
  cand._scripts.OnClick(cand, "LeftButton")
  settle()
end)
check("AssignDeath gesetzt", ns.db.deaths[2].killerKey == "Feind2-Nach2")

------------------------------------------------------------------------
-- Tooltip
------------------------------------------------------------------------
check("Tooltip-Hook registriert", type(M.tooltipHook) == "function")
local tt = G.GameTooltip
step("Tooltip ueber Gelisteten", function()
  ns.units.mouseover = one.key
  tt._unitName, tt._unit, tt._lines = "Feind1", "mouseover", {}
  M.tooltipHook(tt, { guid = "Player-1" })
end)
check("Tooltip-Zeile IM BUCH", tt._lines[1] and tt._lines[1]:find("IM BUCH:", 1, true) ~= nil
      and tt._lines[1]:find("3× getötet · Rang %d+ · Rache 2×") ~= nil, tt._lines[1])
step("Tooltip mit Secrets", function()
  tt._unitName, tt._unit, tt._lines = "SECRET_NAME", "SECRET_UNIT", {}
  M.tooltipHook(tt, { guid = "SECRET_GUID" })
end)
check("keine Zeile bei Secret", #tt._lines == 0)

------------------------------------------------------------------------
-- Settings, save/load, note, delete, minimap, compartment
------------------------------------------------------------------------
-- really run the fallbacks: fonts and textures of the house rules cannot be loaded
M.fontFails, M.textureFails = true, true
step("Einstellungen", function()
  ns.UI.OpenPanel("settings")
  for _, cb in ipairs(findAll(function(f) return f._kind == "CheckButton" end)) do
    cb:SetChecked(not cb:GetChecked()); cb._scripts.OnClick(cb)
  end
  local _, plus = stepperButtons("Abklingzeit je Täter")
  plus._scripts.OnClick(plus, "LeftButton")
end)
M.fontFails, M.textureFails = false, false
check("Mock: SetFont=false -> GameFontNormal", (function()
  local h = anyText(F, "Hausordnung")
  return h and h._fontObject == G.GameFontNormal and h._font == nil
end)())
check("Mock: SetTexture=false -> Ersatzfarbe", (function()
  local h = anyText(F, "Hausordnung")
  local t = h and find(function(f) return f._kind == "Texture" and f._parent == h._parent and f._color and not f._tex end)
  return t ~= nil
end)())
check("Minimap-Knopf ausgeblendet per Haken", not G.DeathNoteMinimapButton:IsShown())
check("Abklingzeit erhoeht", ns.db.settings.alert.cooldown == 120)
step("Sichern und Einlesen", function()
  ns.UI.OpenIO("export")
  ns.UI.OpenIO("import")
  local eb = find(function(f) return f._kind == "EditBox" and f._focus end)
  eb:SetText("DEATHNOTE1\nx")
  local go = find(function(f) return f.text and f.text._text == "Einlesen" end)
  go._scripts.OnClick(go, "LeftButton")
end)
check("Import-Meldung", anyText(F, "Eingelesen: 2 neu, 1 zusammengeführt.") ~= nil)
step("Panel zu, Notiz speichern", function()
  ns.UI.ClosePanel()
  ns.UI.ShowEnemy(one.key)
  local note = find(function(f) return f._kind == "EditBox" and f.key == one.key end)
  note:SetText("campt am Flugpunkt")
  note._focus = true
  note._scripts.OnEnterPressed(note)
end)
check("Notiz gespeichert", ns.db.enemies[one.key].note == "campt am Flugpunkt")
step("Loeschen mit Rueckfrage", function()
  ns.UI.ConfirmDelete(bare.key)
  local p = M.popups[#M.popups]
  G.StaticPopupDialogs[p.which].OnAccept(nil, p.data)
  settle()
end)
check("Eintrag geloescht", ns.db.enemies[bare.key] == nil)
step("Minimap einschalten und ziehen", function()
  ns.Store.Setting("ui.minimap.hide", false)
  local mm = G.DeathNoteMinimapButton
  mm._scripts.OnDragStart(mm)
  check("OnUpdate nur beim Ziehen gesetzt", mm._scripts.OnUpdate ~= nil)
  mm._scripts.OnUpdate(mm, 0.016)
  mm._scripts.OnDragStop(mm)
  check("OnUpdate nach dem Ziehen weg", mm._scripts.OnUpdate == nil)
end)
check("Winkel gespeichert", type(ns.db.settings.ui.minimap.angle) == "number")
step("Compartment", function()
  G.DeathNote_OnCompartmentEnter("DeathNote", G.UIParent)
  G.DeathNote_OnCompartmentLeave("DeathNote", G.UIParent)
  G.DeathNote_OnCompartmentClick("DeathNote", "LeftButton")
  G.DeathNote_OnCompartmentClick("DeathNote", "RightButton")
end)
step("Namensplaketten aus", function()
  ns.nameplates = false
  ns.UI.ClosePanel()
  ns.UI.Refresh()
end)
check("Hinweis Namensplaketten", anyText(F, "Namensplaketten sind aus") ~= nil)

------------------------------------------------------------------------
-- Design findings: search, size, right click menu, shift click, tooltip on a shortened name
------------------------------------------------------------------------
ns.nameplates = true
local search = G.DeathNoteSearch
local function tabClick(id)
  local tab = find(function(f) return f.id == id and f._scripts.OnClick end)
  tab._scripts.OnClick(tab)
end
local function type_(text)
  search:SetText(text)
  search._scripts.OnTextChanged(search, true)
end
local function visibleRows()
  return findAll(function(f) return f._kind == "Button" and f.item ~= nil and f._shown and f.under end)
end
step("Suche filtert", function() tabClick("wanted"); type_("Feind3") end)
check("Suchfeld da", search ~= nil)
local vr = visibleRows()
check("Suche: nur Treffer sichtbar (Feind3, Feind30..39)", #vr == 9 and (function()
  for _, r in ipairs(vr) do if not r.item.name:find("Feind3", 1, true) then return false end end
  return true end)(), #vr .. " Zeilen")
check("G16 keine Bereichsanzeige mehr (Reiterzahl und Rollbalken sagen es)", anyText(F, "1–9 von") == nil)
step("Enter mit Treffer waehlt den ersten", function() search._scripts.OnEnterPressed(search) end)
check("erster Treffer gewaehlt", anyText(F, "Feind3 Nach3") ~= nil)
step("Suche ohne Treffer", function() type_("Zorngrimm Neuling") end)
check("Leerzustand der Suche", anyText(F, "Kein Treffer.") ~= nil and anyText(F, "Enter trägt den Namen ins Buch ein.") ~= nil)
step("Enter ohne Treffer traegt ein", function() search._scripts.OnEnterPressed(search); settle() end)
local newKey = "Zorngrimm Neuling-X"
check("AddManual ueber das Suchfeld", ns.db.enemies[newKey] ~= nil and ns.db.enemies[newKey].manual == true)
check("Suche danach leer", search._text == "" and search.ph:IsShown())
check("neuer Eintrag aufgeschlagen", anyText(F, "Zorngrimm Neuling") ~= nil and anyText(F, "von Hand") ~= nil)
step("Escape leert die Suche", function() type_("xyz"); search._scripts.OnEscapePressed(search) end)
check("Liste wieder voll", #visibleRows() == 9)

local scaleSet
local Fs = F.SetScale
F.SetScale = function(self, v) scaleSet = v end
step("Buchgroesse per +", function()
  local _, plus = stepperButtons("Größe des Buchs")
  plus._scripts.OnClick(plus, "LeftButton")
end)
check("ui.scale 1.15 gespeichert", ns.db.settings.ui.scale == 1.15, tostring(ns.db.settings.ui.scale))
check("Fenster sofort skaliert", scaleSet == 1.15, tostring(scaleSet))
check("Anzeige 115 %", anyText(F, "115 %") ~= nil)
F.SetScale = Fs
step("Alarmgroesse", function() ns.Store.Setting("alert.scale", 1.3) end)
check("Alarm-Skala gesetzt", ns.db.settings.alert.scale == 1.3)
check("U8 Abstand oben bleibt 190 Bildschirmeinheiten bei 130 %", popup:GetScale() == 1.3 and popup._points[1]
      and math.abs(popup._points[1][5] * 1.3 + 190) < 1e-9, popup._points[1] and tostring(popup._points[1][5]))
step("Haken mit eigener Optik", function()
  local cb = find(function(f) return f._kind == "CheckButton" and f.opt and f.opt.path == "alert.flash" end)
  cb:SetChecked(false); cb._scripts.OnClick(cb)
  check("Kreuz aus bei abgewaehlt", not cb.cross:IsShown())
  check("Blitz aus gespeichert", ns.db.settings.alert.flash == false)
  cb:SetChecked(true); cb._scripts.OnClick(cb)
  check("Kreuz sichtbar", cb.cross:IsShown())
end)
-- G22: one way to silence: no "sound on alarm" checkbox, "No sound" first in the sound choice
check("G22 kein Haken Ton beim Alarm", find(function(f) return f._kind == "CheckButton" and f.opt and f.opt.path == "alert.sound" end) == nil
      and not M.texts["Ton beim Alarm"])
check("G22 Kein Ton ist der erste Ton", ns.Look.SOUNDS[1].key == "aus")
step("G22 Tonwahl: Kein Ton schaltet alert.sound aus, ein Ton wieder an", function()
  local minus, plus = stepperButtons("Ton")
  ns.Look.SetSound("warnung"); ns.UI.FillSettings()
  minus._scripts.OnClick(minus, "LeftButton")
  check("G22 links von Raid-Warnung: Kein Ton", ns.db.settings.alert.soundKey == "aus" and ns.db.settings.alert.sound == false)
  plus._scripts.OnClick(plus, "LeftButton")
  check("G22 wieder Raid-Warnung, Ton an", ns.db.settings.alert.soundKey == "warnung" and ns.db.settings.alert.sound == true)
  ns.db.settings.alert.sound = false; ns.db.settings.alert.soundKey = "gong"; ns.UI.FillSettings()
  check("G22 alter Hauptschalter aus zeigt Kein Ton", anyText(F, "Kein Ton") ~= nil)
  plus._scripts.OnClick(plus, "LeftButton")
  check("G22 von Kein Ton weiter zu Raid-Warnung", ns.db.settings.alert.soundKey == "warnung" and ns.db.settings.alert.sound == true)
end)
check("keine Standard-Haken mehr", find(function(f) return f._template == "UICheckButtonTemplate" end) == nil)
check("kein Standard-Schliessen-Knopf", find(function(f) return f._template == "UIPanelCloseButton" end) == nil)
ns.UI.ClosePanel()

ns.Store.Setting("ui.scale", 1.3)
step("Rechtsklick-Menue", function()
  ns.UI.ShowEnemy("Feind5-Nach5")
  local r = find(function(f) return f.item and f.item.key == "Feind5-Nach5" and f.under end)
  r._scripts.OnClick(r, "RightButton")
end)
local menu = G.DeathNoteMenu
check("Menue offen", menu and menu:IsShown())
check("Menue am Mauszeiger bei Buchgroesse 130 %", (function()
  local pt = menu._points[1]   -- GetCursorPosition = 100, 200 (screen), menu units = / 1.3
  return pt and pt[2] == G.UIParent and math.abs(pt[4] - (100 / 1.3 + 2)) < 1e-9 and math.abs(pt[5] - (200 / 1.3 - 2)) < 1e-9
end)(), menu._points[1] and (tostring(menu._points[1][4]) .. "," .. tostring(menu._points[1][5])))
check("Menue zeigt Begnadigen", anyText(menu, "Begnadigen") ~= nil and anyText(menu, "Rache vermerken") ~= nil
      and anyText(menu, "Streichen") ~= nil)
step("Menue: Begnadigen", function()
  local b = find(function(f) return f.text and f.text._text == "Begnadigen" and under(f, menu) end)
  b._scripts.OnClick(b, "LeftButton"); settle()
end)
check("per Menue begnadigt", ns.db.enemies["Feind5-Nach5"].status == "pardoned")
check("Menue danach zu", not menu:IsShown())
step("Begnadigt: durchgestrichen am Ende von Gesucht", function() tabClick("wanted"); ns.UI.ShowEnemy("Feind5-Nach5") end)
check("Durchstreichen nur bei begnadigt", (function()
  local r = find(function(f) return f.item and f.item.key == "Feind5-Nach5" and f.strike and f._shown end)
  return r and r.strike:IsShown() and r.sub._text:find("^begnadigt · ") ~= nil and r.name._tc[4] == ns.Look.TONE.hand
end)())
tabClick("wanted")
ns.UI.ShowEnemy("Feind6-Nach6")
step("Umschalt-Klick ohne offene Chat-Eingabe", function()
  M.shift = true
  local r = find(function(f) return f.item and f.item.key == "Feind6-Nach6" and f.under end)
  r._scripts.OnClick(r, "LeftButton")
end)
check("ohne Chat-Eingabe nichts eingefuegt", #M.chatInserted == 0)
step("Umschalt-Klick mit offener Chat-Eingabe", function()
  M.chatOpen = true
  local r = find(function(f) return f.item and f.item.key == "Feind6-Nach6" and f.under end)
  r._scripts.OnClick(r, "LeftButton")
  M.shift, M.chatOpen = false, false
end)
check("Name in die Chat-Eingabe", M.chatInserted[1] == "Feind6 Nach6", tostring(M.chatInserted[1]))
step("Tooltip bei gekuerztem Namen", function()
  local r = find(function(f) return f.item and f.item.key == "Feind6-Nach6" and f.under end)
  r.name.IsTruncated = function() return true end
  G.GameTooltip._lines = {}
  r._scripts.OnEnter(r)
  r.name.IsTruncated = function() return "SECRET_NAME" end
  r._scripts.OnEnter(r)
end)

------------------------------------------------------------------------
-- guild
------------------------------------------------------------------------
local guildTab = find(function(f) return f.id == "guild" and f._scripts.OnClick end)
step("ohne ns.Guild", function() ns.Guild = nil; ns.UI.Refresh() end)
check("Gilden-Reiter versteckt ohne Sync.lua", not guildTab:IsShown())
step("Reiter-Klick ohne ns.Guild faellt zurueck", function() guildTab._scripts.OnClick(guildTab) end)
check("ohne Gilde zurueck auf Gesucht", find(function(f) return f.id == "wanted" and f.mark end).mark:IsShown())

-- the earlier settings step flipped all checkboxes: reset
for k, v in pairs({ enabled = true, sound = true, flash = true, suspects = false }) do ns.db.settings.alert[k] = v end
ns.db.settings.tooltip, ns.db.settings.deathMessage, ns.db.settings.guild = true, true, nil
local GG = ns.MakeGuild(0, { noguild = true })
step("Gilde: nicht in einer Gilde", function() tabClick("wanted"); ns.UI.Refresh(); guildTab._scripts.OnClick(guildTab) end)
check("Gilden-Reiter sichtbar", guildTab:IsShown())
check("Leer: keine Gilde", anyText(F, "Keine Gilde.") ~= nil)
GG.name = "Die Schlächter von Sturmwind"; GG.enabled = false
step("Gilde: Teilen aus", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("Leer: Gildenbuch zu", anyText(F, "Das Gildenbuch ist zu.") ~= nil)
GG.enabled = true
step("Gilde: nichts eingegangen", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("Leer: noch nichts", anyText(F, "Im Gildenbuch steht noch nichts.") ~= nil)
check("G1 Fusszeile Gilde aus Health", anyText(F, "Gesendet 4, empfangen 9.") ~= nil)
step("Mitglieder-Tooltip", function()
  local hit = find(function(f) return f._scripts.OnEnter and f._shown and f._w == 232 end)
  G.GameTooltip._lines = {}
  hit._scripts.OnEnter(hit)
end)
check("G1 Tooltip: was geteilt wird", (function()
  local a, b
  for _, l in ipairs(G.GameTooltip._lines or {}) do
    if l:find("Geteilt wird: deine sicheren Tode", 1, true) then a = true end
    if l:find("Nicht geteilt: Notizen, Verdacht", 1, true) then b = true end
  end
  return a and b end)())

GG = ns.MakeGuild(1)
step("Gilde: 1 Eintrag", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("Gildenfeind in der Liste", anyText(F, "Gilde1 Feind1") ~= nil)
check("Untertext mit Opfern und mindestens 20", anyText(F, "mindestens 20× getötet · ") ~= nil and anyText(F, " Opfer · zuletzt ") ~= nil)
check("Plakat: Gildenfahndung", anyText(F, "G I L D E N B U C H") ~= nil and anyText(F, "WANTED") ~= nil)
-- fix-3: victim count without a role (guildmate or friend), the VICTIMS label only once (before the names)
check("Opferzahl statt Kopfgeld", anyText(F, "O P F E R") ~= nil and anyText(F, "2 Opfer") ~= nil and anyText(F, "2 KOLLEGEN") == nil)
check("Tat: Datum · Ort · Opfer", anyText(F, " · Nesingwarys Expedition · ") ~= nil)
check("Knopf Ins eigene Buch", anyText(F, "Ins eigene Buch") ~= nil)
check("nichts Zerstoerendes", (function()
  for _, f in ipairs(M.frames) do
    if f.text and f._shown and f.fn and under(f, F) and (f.text._text == "Streichen" or f.text._text == "Begnadigen") then
      if f:IsVisible() then return false end
    end
  end
  return true end)())
local gstampShown = find(function(f) return f._kind == "Texture" and f._tex and f._tex:find("stamp_guild", 1, true) and f._shown end)
check("Stempel GILDENFEIND Nr. 1", gstampShown ~= nil)
check("Gildenliste nicht veraendert", #GG.list == 1 and GG.list[1].key == "Gilde1-Feind1")
step("Ins eigene Buch (Adopt)", function()
  local b = find(function(f) return f.text and f.text._text == "Ins eigene Buch" and f.fn and f:IsVisible() end)
  b._scripts.OnClick(b, "LeftButton"); settle()
end)
check("Adopt aufgerufen", GG.adopted[1] == "Gilde1-Feind1")
check("eigenes Plakat aufgeschlagen", ns.db.enemies["Gilde1-Feind1"] ~= nil and anyText(F, "D E A D    O R    A L I V E") ~= nil)
step("zurueck zur Gilde: IM BUCH", function() guildTab._scripts.OnClick(guildTab) end)
check("Zeichen IM BUCH", anyText(F, "IM BUCH") ~= nil)
check("Knopf Im Buch aufschlagen", anyText(F, "Im Buch aufschlagen") ~= nil)

GG = ns.MakeGuild(40)
step("Gilde: 40 Eintraege", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("40: Rollbalken", slider:IsShown() and #visibleRows() == 9)
local function sortPick(label)
  local sortB = find(function(f) return f.arrow and f._scripts.OnClick end)
  sortB._scripts.OnClick(sortB)
  local b = find(function(f) return f.text and f.fn and f:IsVisible() and under(f, G.DeathNoteMenu)
    and (f.text._text == label or f.text._text == "• " .. label) end)
  b._scripts.OnClick(b, "LeftButton")
end
step("Gilde scrollen, sortieren, suchen", function()
  slider:SetValue(31)
  sortPick("Neueste"); sortPick("Name"); sortPick("Rang")
  type_("Gilde4")
  search._scripts.OnEnterPressed(search)
end)
check("Gilde: Sortierung zurueck auf Rang", find(function(f) return f.arrow and f.text and f.text._text == "Rang" and f:IsVisible() end) ~= nil)
check("Gilde: Suche ohne Eintragen", ns.db.enemies["Gilde4-X"] == nil and anyText(F, "Gilde40 Feind40") ~= nil)
type_("")
step("Abgleichen", function()
  local b = find(function(f) return f.text and f.text._text == "Abgleichen" and f.fn and f:IsVisible() end)
  GG.cooldown = 42
  b._scripts.OnClick(b, "LeftButton")
  check("Sperre: in 42 s wieder", b.text._text == "in 42 s wieder", b.text._text)
  M.Advance(3.5)
  check("Beschriftung zurueck", b.text._text == "Abgleichen")
end)
check("SyncNow gerufen", GG.synced == 1)
step("Rechtsklick in der Gilde", function()
  local r = find(function(f) return f.item and f.item.key == "Gilde2-Feind2" and f.under end)
  r._scripts.OnClick(r, "RightButton")
end)
check("Gilden-Menue: nur uebernehmen", anyText(menu, "Ins eigene Buch") ~= nil and menu.items[2]:IsShown() == false)
step("Menue schliessen", function() menu.blocker._scripts.OnClick(menu.blocker) end)
check("Menue zu", not menu:IsShown())
GG.noguildNow = true
GG.name = nil
step("nach Gildenaustritt", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("alte Liste nicht gezeigt", anyText(F, "Keine Gilde.") ~= nil)
GG.name = "Die Schlächter von Sturmwind"
ns:Fire("GUILD_UPDATED"); settle()

-- guild settings
step("Hausordnung Blatt Gilde", function()
  ns.UI.OpenPanel("settings")
  local t = find(function(f) return f.page == 3 and f._scripts.OnClick end)
  t._scripts.OnClick(t)
end)
check("Abschnitt Gilde sichtbar", anyText(F, "Eigene Tode teilen") ~= nil and anyText(F, "Sichtungen teilen") ~= nil)
check("G1 Statuszeile Gilde aus Health", (function()
  local t = anyText(nil, "Gesendet 4, empfangen 9."); return t ~= nil end)())
step("Haken Gilde: Melden aus", function()
  local cb = find(function(f) return f._kind == "CheckButton" and f.opt and f.opt.guild == "announce" end)
  check("Melden ist an (Standard)", cb:GetChecked() == true)
  cb:SetChecked(false); cb._scripts.OnClick(cb)
end)
check("guild.announce aus", ns.db.settings.guild and ns.db.settings.guild.announce == false)
step("Gildenwarnung ab 2", function()
  local _, plus = stepperButtons("Gildenwarnung ab so vielen Toden")
  plus._scripts.OnClick(plus, "LeftButton")
end)
check("guild.minKills 2", ns.db.settings.guild.minKills == 2)
step("Gildenliste leeren mit Rueckfrage", function()
  local b = find(function(f) return f.text and f.text._text == "Gildenbuch leeren" and f.fn end)
  b._scripts.OnClick(b, "LeftButton")
  local p = M.popups[#M.popups]
  check("Rueckfrage gezeigt", p.which == "DEATHNOTE_GUILD_CLEAR")
  G.StaticPopupDialogs[p.which].OnAccept(nil, p.data)
  settle()
end)
check("Clear aufgerufen", GG.cleared == 1)
ns.UI.ClosePanel()

-- alarm for guild enemies
GG = ns.MakeGuild(3)
M.Advance(300)
local snd = #M.sounds
step("GUILD_ENEMY_SPOTTED", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde2-Feind2", "nameplate3", "nameplate") end)
check("Popup Gildenfeind", popup:IsShown() and anyText(popup, "GILDENFEIND GESICHTET") ~= nil)
check("Text Gildenfeind", anyText(popup, "hat 19× Kollegen getötet, zuletzt ") ~= nil)
check("Ton", #M.sounds == snd + 1)
step("gleicher Gildenfeind in der Abklingzeit", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde2-Feind2", nil, "nameplate") end)
check("kein zweiter Ton", #M.sounds == snd + 1)
step("Gildenfeind in die Warteschlange", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde3-Feind3", nil, "target") end)
check("+1 weiterer", anyText(popup, "+1 weiterer") ~= nil)
step("naechster Gildenfeind", function() M.Advance(12.5); M.FinishAnims(); M.Advance(0.5) end)
check("zweiter Gildenfeind sichtbar", popup:IsShown() and anyText(popup, "Gilde3 Feind3") ~= nil)
step("Gilden-Alarm schliessen", function() M.Advance(12.5); M.FinishAnims(); M.Advance(0.5) end)
ns.Store.Setting("guild.minKills", 25)
M.Advance(300)
step("unter guild.minKills", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde1-Feind1", nil, "nameplate") end)
check("kein Alarm unter Mindestzahl", not popup:IsShown())
ns.Store.Setting("guild.minKills", 1)
ns.Store.Setting("guild.alert", false)
step("guild.alert aus", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde3-Feind3", nil, "nameplate") end)
check("kein Alarm wenn aus", not popup:IsShown())
ns.Store.Setting("guild.alert", true)

-- tooltip for a guild enemy
step("Tooltip Gildenfeind", function()
  ns.units.mouseover = "Gilde2-Feind2"
  tt._unitName, tt._unit, tt._lines = "Gilde2", "mouseover", {}
  M.tooltipHook(tt, {})
end)
check("Tooltip GILDENFEIND", tt._lines[1] and tt._lines[1]:find("GILDENBUCH:", 1, true) ~= nil and tt._lines[1]:find("hat 19× Kollegen getötet", 1, true) ~= nil, tt._lines[1])

-- message when a guildmate is killed
ns.Store.Setting("guild.announce", true)
M.FinishAnims()
step("GUILD_KILL", function()
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Schlingendorntal", victim = "Varorak", level = 33 }, "Gilde2-Feind2")
end)
check("Gildenmeldung", banner:IsShown() and anyText(banner, "Varorak") ~= nil
      and anyText(banner, "wurde von Gilde2 Feind2 getötet · Schlingendorntal") ~= nil)
step("eigene Meldung hat Vorrang", function() ns:Fire("DEATH_RECORDED", ns.db.deaths[1], one.key) end)
check("eigene Meldung ersetzt", anyText(banner, "hat dich zum") ~= nil and banner.guild == false)
step("Gildenmeldung waehrend der eigenen wartet", function()
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Bohnenjockel" }, "Gilde3-Feind3")
end)
check("eigene bleibt stehen", anyText(banner, "hat dich zum") ~= nil and banner.kicker._text == "S C H O N   W I E D E R")
step("danach die Gildenmeldung", function() M.FinishAnims(); M.Advance(0.5) end)
check("Gildenmeldung nachgereicht", banner:IsShown() and anyText(banner, "wurde von Gilde3 Feind3 getötet · Ödland") ~= nil)
ns.Store.Setting("guild.announce", false)
M.FinishAnims()
step("guild.announce aus", function()
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Knäckebrot" }, "Gilde3-Feind3")
end)
check("keine Gildenmeldung wenn aus", not banner:IsShown())
step("eigener Tod nicht als Gildenmeldung", function()
  ns.Store.Setting("guild.announce", true)
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Davee" }, "Gilde3-Feind3")
end)
check("eigener Name keine Gildenmeldung", not banner:IsShown())
step("ohne ns.Guild: Gilden-Ereignisse still", function()
  ns.Guild = nil
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Knäckebrot" }, "Gilde3-Feind3")
  ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde3-Feind3", nil, "nameplate")
  ns:Fire("GUILD_UPDATED")
  settle()
end)
check("ohne ns.Guild kein Popup und keine Meldung", not popup:IsShown() and not banner:IsShown())

------------------------------------------------------------------------
-- Findings of the UI hunt (U1 to U16, F4, F7): one proof test each
------------------------------------------------------------------------
local function spot(key, unit) ns:Fire("ENEMY_SPOTTED", key, unit, "other") end
local function closePopup() if popup:IsShown() then ns.Alert.Dismiss(); M.FinishAnims() end; M.Advance(0.5) end
local function clickTarget()
  -- whom does a left click on the popup target? (button and popup lie exactly on top of each other)
  local top = M.TopFrame(popup, button)
  if top == button then return (button:GetAttribute("macrotext") or ""):match("/targetexact ([^\n]+)") end
  return nil
end
M.Advance(300); closePopup()

-- U1: a line break in the name does not arm the button (and removes an old button)
put(enemy(70, { kills = 3, surname = "Bube\n/run BOESE()" }))
step("U1 Probe-Feind scharf", function() spot("Feind30-Nach30") end)
check("U1 Vorbedingung: Knopf scharf fuer Feind30", button:IsShown() and (button:GetAttribute("macrotext") or ""):find("Feind30 Nach30", 1, true) ~= nil)
closePopup()
step("U1 Name mit Zeilenumbruch", function() spot("Feind70-Nach70") end)
check("U1 Popup trotzdem da", popup:IsShown())
check("U1 Knopf nicht scharf", not button:IsShown())
check("U1 kein /run im Makro", not (button:GetAttribute("macrotext") or ""):find("/run", 1, true))
check("U1 Hinweis ohne Anvisieren", anyText(popup, "Rechtsklick: schließen") ~= nil and anyText(popup, "Klick: anvisieren") == nil)
check("U1 TargetName lehnt | und Ueberlaenge ab", ns.Look.TargetName({ name = "A|cffff0000B" }) == nil
      and ns.Look.TargetName({ name = string.rep("x", 61) }) == nil and ns.Look.TargetName({ name = "Grimm" }) == "Grimm")
closePopup()
ns.db.enemies["Feind70-Nach70"] = nil

-- scale 1.3: button exactly over the popup (popup units * 1.3 = UIParent units)
popup._cx, popup._cy = 500, 400
step("Knopf bei Alarmgroesse 130 %", function() spot("Feind31-Nach31") end)
check("Knopf-Mitte und -Groesse bei 130 %", (function()
  local pt = button._points[1]
  return pt and pt[1] == "CENTER" and pt[2] == G.UIParent and pt[3] == "BOTTOMLEFT"
     and math.abs(pt[4] - 650) < 1e-9 and math.abs(pt[5] - 520) < 1e-9
     and math.abs(button._w - 384 * 1.3) < 1e-9 and math.abs(button._h - 108 * 1.3) < 1e-9
end)(), button._points[1] and (tostring(button._points[1][4]) .. "," .. tostring(button._points[1][5]) .. " " .. tostring(button._w)))
popup._cx, popup._cy = nil, nil

-- U13 + U15: combat starts while dragging the button; dragged frames not in layout-local.txt
step("U13 Kampfbeginn waehrend des Ziehens", function()
  button._scripts.OnDragStart(button)
  ns:FireWow("PLAYER_REGEN_DISABLED")
  M.combat = true
end)
check("U13 Popup wieder an UIParent", popup._points[1] and popup._points[1][2] == G.UIParent, popup._points[1] and tostring(popup._points[1][2]))
check("U13 Ziehen beendet und Position gespeichert", not button._moving and type(ns.db.settings.alert.point) == "table")
check("U15 Knopf nicht user-placed", button._userPlaced == false)
step("U13 Loslassen im Kampf", function() button._scripts.OnDragStop(button); popup._scripts.OnMouseUp(popup, "RightButton"); M.FinishAnims() end)
M.combat = false; ns:FireWow("PLAYER_REGEN_ENABLED")
ns.db.settings.alert.point = nil
M.Advance(300)
step("U15 Popup und Buch ziehen", function()
  spot("Feind32-Nach32")
  popup._scripts.OnDragStart(popup); popup._scripts.OnDragStop(popup)
  F._scripts.OnDragStart(F); F._scripts.OnDragStop(F)
end)
check("U15 Popup nicht user-placed", popup._userPlaced == false)
check("U15 Buch nicht user-placed", F._userPlaced == false)
ns.db.settings.alert.point = nil
closePopup()

-- U14: fading out ends at alpha 0 (no flash)
check("U14 SetToFinalAlpha an Popup und Meldung", popup.outAnim._toFinal == true and banner.anim._toFinal == true)

-- U4: an alarm shown in the follow-up gap is not overwritten by the follower
M.Advance(300)
step("U4 Luecke", function()
  spot("Feind33-Nach33"); spot("Feind34-Nach34")
  ns.Alert.Dismiss(); M.FinishAnims()           -- 33 gone, 34 would come in 0.4 s
  M.Advance(0.1)
  spot("Feind35-Nach35")                        -- 35 in the gap: shown at once
  M.Advance(0.5)
end)
check("U4 35 bleibt stehen", popup:IsShown() and popup.name._text == "Feind35 Nach35", popup.name._text)
step("U4 danach 34", function() closePopup() end)
check("U4 34 kommt danach", popup:IsShown() and popup.name._text == "Feind34 Nach34", popup.name._text)
closePopup()

-- U5: a full queue does not use up the cooldown
M.Advance(300)
step("U5 elf auf einmal", function()
  for i = 1, 11 do spot("Feind" .. (i + 10) .. "-Nach" .. (i + 10)) end
  for _ = 1, 12 do closePopup() end
  spot("Feind21-Nach21")                        -- the pushed out eleventh, seen again right away
end)
check("U5 verdraengter Feind wird gemeldet", popup:IsShown() and popup.name._text == "Feind21 Nach21", popup:IsShown() and popup.name._text or "nichts")
closePopup()

-- U6: SetUnit returns false -> class icon instead of an empty photo
M.Advance(300)
ns.units.target = "Feind22-Nach22"
M.setUnitResult = false
step("U6 SetUnit=false", function() spot("Feind22-Nach22", "target") end)
M.setUnitResult = true
check("U6 Klassensymbol statt Modell", popup.icon:IsShown() and not popup.model:IsShown())
ns.units.target = nil
closePopup()

-- U16: a click on the popup never targets anyone other than the popup shows
M.Advance(300)
step("U16a Verstecken gelingt", function()
  spot("Feind23-Nach23")
  ns:FireWow("PLAYER_REGEN_DISABLED"); M.combat = true
  popup._scripts.OnMouseUp(popup, "RightButton"); M.FinishAnims()
  spot("Feind24-Nach24")
end)
check("U16a Knopf versteckt", not button:IsShown())
check("U16a Klick visiert niemand Falschen an", popup.name._text == "Feind24 Nach24" and clickTarget() == nil, tostring(clickTarget()))
step("U16a Kampfende", function() M.combat = false; ns:FireWow("PLAYER_REGEN_ENABLED") end)
check("U16a nach dem Kampf: Klick visiert den Gezeigten an", clickTarget() == "Feind24 Nach24" and popup:GetFrameStrata() == "HIGH", tostring(clickTarget()))
closePopup()
M.Advance(300)
step("U16b Verstecken scheitert", function()
  spot("Feind25-Nach25")
  M.secureHideFails = true
  ns:FireWow("PLAYER_REGEN_DISABLED"); M.combat = true
end)
check("U16b Vorbedingung: Knopf noch da", button:IsShown())
check("U16b gleicher Feind: Klick visiert ihn an", clickTarget() == "Feind25 Nach25" and anyText(popup, "Klick: anvisieren") ~= nil, tostring(clickTarget()))
step("U16b neuer Feind im Kampf", function()
  popup._scripts.OnMouseUp(popup, "RightButton"); M.FinishAnims()
  spot("Feind26-Nach26")
end)
check("U16b Popup zeigt den Neuen", popup:IsShown() and popup.name._text == "Feind26 Nach26")
check("U16b Klick faengt das Popup ab (nicht der alte Knopf)", clickTarget() == nil and popup:GetFrameStrata() == "DIALOG", tostring(clickTarget()))
check("U16b Hinweis: nach dem Kampf", anyText(popup, "Anvisieren erst nach dem Kampf") ~= nil)
step("U16b Kampfende", function()
  M.secureHideFails = false
  M.combat = false; ns:FireWow("PLAYER_REGEN_ENABLED")
end)
check("U16b nach dem Kampf: Klick visiert den Neuen an", clickTarget() == "Feind26 Nach26" and popup:GetFrameStrata() == "HIGH", tostring(clickTarget()))
closePopup()

-- U9: move to a new key: selection, note field, popup and cooldown move along
M.Advance(300)
put({ key = "Umzug-X", name = "Umzug", status = "wanted", kills = 2, deaths = {}, note = "" })
local noteBox
step("U9 Umzug", function()
  ns.UI.ShowEnemy("Umzug-X"); settle()
  noteBox = find(function(f) return f._kind == "EditBox" and f.key == "Umzug-X" end)
  noteBox:SetFocus(); noteBox:SetText("zieht mit")
  spot("Umzug-X")
  ns.Store.Rekey("Umzug-X", "Umzug-Neu", "Neu")
  settle()
end)
check("U9 Popup bleibt offen", popup:IsShown() and not popup.outAnim:IsPlaying())
check("U9 Knopf zeigt auf den neuen Namen", (button:GetAttribute("macrotext") or ""):find("/targetexact Umzug Neu", 1, true) ~= nil, button:GetAttribute("macrotext"))
check("U9 Auswahl folgt", (function()
  local r = find(function(f) return f.item and f.item.key == "Umzug-Neu" and f.under end)
  return r and r.under:IsShown()
end)())
check("U9 Notizfeld folgt", noteBox.key == "Umzug-Neu")
noteBox:ClearFocus()
check("U9 Notiz beim neuen Schluessel", ns.db.enemies["Umzug-Neu"].note == "zieht mit")
closePopup()
local snd9 = #M.sounds
step("U9 Abklingzeit folgt", function() spot("Umzug-Neu") end)
check("U9 kein zweiter Alarm", #M.sounds == snd9 and not popup:IsShown())

-- U2: the note ends up with the right entry when the selection changes while focused
step("U2 Auswahl wechselt bei Fokus", function()
  ns.UI.ShowEnemy("Feind2-Nach2"); settle()
  noteBox:SetFocus(); noteBox:SetText("campt am Zeppelin")
  local r = find(function(f) return f.item and f.item.key == "Feind3-Nach3" and f.under end)
  r._scripts.OnClick(r, "LeftButton")
  noteBox:ClearFocus(); settle()
end)
check("U2 Notiz bei Feind2", ns.db.enemies["Feind2-Nach2"].note == "campt am Zeppelin", ns.db.enemies["Feind2-Nach2"].note)
check("U2 Feind3 ohne fremde Notiz", (ns.db.enemies["Feind3-Nach3"].note or "") == "")

-- F4: rebuild without new button closures; deed tooltip only when shown
local rache = find(function(f) return f.fn and f.text and f.text._text == "Rache vermerken" and f:IsVisible() and under(f, F) end)
local fn1 = rache and rache.fn
step("F4 Refresh", function() ns.UI.Refresh(); ns.UI.Refresh() end)
check("F4 Knoepfe nicht neu gebaut", rache and rache.fn == fn1)
check("F4 Tooltip-Tabellen nicht vorgebaut", find(function(f) return f.tipItem ~= nil and f.tip ~= nil end) == nil
      and find(function(f) return f.tipItem ~= nil end) ~= nil)
step("F4 Statuswechsel baut Knoepfe neu", function()
  ns.Store.SetStatus("Feind3-Nach3", "pardoned"); settle(); ns.UI.ShowEnemy("Feind3-Nach3")
end)
check("F4 neue Knoepfe nach Statuswechsel", (function()
  local b = find(function(f) return f.fn and f.text and f.text._text == "Wieder jagen" and f:IsVisible() and under(f, F) end)
  return b ~= nil and b == rache
end)())
ns.Store.SetStatus("Feind3-Nach3", "wanted"); settle(); ns.UI.ShowEnemy("Feind3-Nach3")

-- U10: a click on the active tab closes the house rules
step("U10 aktiver Reiter", function()
  ns.UI.OpenPanel("settings")
  tabClick("wanted")
end)
check("U10 Hausordnung zu", not anyText(F, "Hausordnung"):IsVisible() and anyText(F, "WANTED"):IsVisible())

-- U3 + U7 + U11: death journal
ns.db.deaths = {
  { t = NOW - 100, zone = "Alt", kind = "pve", me = "Davee" },
  { t = NOW - 50, zone = "Brachland", kind = "pvp", sure = false, source = "suspect",
    candidates = { "Feind12-Nach12", "Feind13-Nach13", "Feind14-Nach14", "Feind15-Nach15", "Feind16-Nach16",
                   "Feind17-Nach17", "Feind18-Nach18", "Feind19-Nach19" } },
}
local nBefore = 0
for _ in pairs(ns.db.enemies) do nBefore = nBefore + 1 end
step("U3 Journal-Suche ohne Treffer, Enter", function()
  tabClick("journal")
  type_("Ödland")
  search._scripts.OnEnterPressed(search)
  settle()
end)
local nAfter = 0
for _ in pairs(ns.db.enemies) do nAfter = nAfter + 1 end
check("U3 nichts eingetragen", nAfter == nBefore and ns.db.enemies["Ödland-X"] == nil, nBefore .. " -> " .. nAfter)
check("U3 Leertext ohne Eintragen", anyText(F, "Anders schreiben hilft manchmal.") ~= nil and search.ph._text == "Täter oder Ort suchen …")
type_("")
step("U7 Auswahl Fall Alt, dann neuer Tod", function()
  local r = find(function(f) return f.item and f.item.zone == "Alt" and f.under end)
  r._scripts.OnClick(r, "LeftButton")
  table.insert(ns.db.deaths, 1, { t = NOW, zone = "Ganzneu", kind = "pve" })
  ns:Fire("DEATH_RECORDED", ns.db.deaths[1], nil)
  settle()
end)
check("U7 Akte zeigt weiter Fall Alt", (function()
  local f = find(function(x) return x._kind == "FontString" and type(x._text) == "string" and x._text:find("\n", 1, true) and x:IsVisible() end)
  return f and f._text:find("Alt", 1, true) ~= nil
end)())
step("U11 acht Kandidaten", function()
  local r = find(function(f) return f.item and f.item.zone == "Brachland" and f.under end)
  r._scripts.OnClick(r, "LeftButton")
end)
local more = find(function(f) return f.fn == nil and f.text and f.text._text == "… und 3 weitere" and f:IsVisible() end)
check("U11 letzter Knopf nennt den Rest", more ~= nil)
step("U11 Tooltip mit den Namen", function() G.GameTooltip._lines = {}; more._scripts.OnEnter(more) end)
check("U11 Tooltip nennt Kandidat 8", (function()
  for _, l in ipairs(G.GameTooltip._lines or {}) do if l == "Feind19 Nach19" then return true end end
end)())
step("U7 Taeter festlegen nach Verschieben", function()
  table.insert(ns.db.deaths, 1, { t = NOW + 1, zone = "Nochneuer", kind = "pve" })
  local b = find(function(f) return f.fn and f.text and f.text._text == "Feind12 Nach12" and f:IsVisible() end)
  b._scripts.OnClick(b, "LeftButton")
  settle()
end)
check("U7 AssignDeath trifft den gezeigten Fall", ns.db.deaths[4].zone == "Brachland" and ns.db.deaths[4].killerKey == "Feind12-Nach12"
      and ns.db.deaths[3].killerKey == nil)
tabClick("wanted")

-- U12: import throws
step("U12 Import wirft", function()
  ns.UI.OpenIO("import")
  local eb = find(function(f) return f._kind == "EditBox" and f._focus end)
  eb:SetText("BOOM")
  local go = find(function(f) return f.text and f.text._text == "Einlesen" end)
  go._scripts.OnClick(go, "LeftButton")
end)
check("U12 Meldung statt leer", anyText(F, "Das hat nicht geklappt.") ~= nil)

-- F7: large book small first
local function ioText() return find(function(f) return f._kind == "EditBox" and f._focus end)._text or "" end
ns.bigExport = true
step("F7 Buch sichern gross", function() ns.UI.OpenIO("export") end)
check("F7 zuerst die kleine Fassung", not ioText():find("\nD|", 1, true) and #ioText() < 10000, #ioText() .. " Bytes")
local sizeB = find(function(f) return f.fn and f.text and f.text._text == "Alles zeigen" and f:IsVisible() end)
check("F7 Wahl Alles zeigen", sizeB ~= nil and anyText(F, "Nur Namen und Zähler") ~= nil)
step("F7 Alles zeigen", function() sizeB._scripts.OnClick(sizeB, "LeftButton") end)
check("F7 ganzes Buch", ioText():find("\nD|", 1, true) ~= nil and #ioText() > 100 * 1024 and sizeB.text._text == "Nur klein")
ns.exportShort = false
step("F7 alte Store-Fassung ohne Kurzform", function() ns.UI.OpenIO("export") end)
check("F7 Warnung statt Wahl", anyText(F, "Großes Buch (") ~= nil and not sizeB:IsShown())
ns.bigExport, ns.exportShort = nil, nil
ns.UI.ClosePanel()

-- Design: a four-digit bounty one size smaller (19 instead of 22), otherwise it hits the revenge stamp
put(enemy(80, { kills = 250, revenge = 1 }))
step("Kopfgeld vierstellig", function() ns.UI.ShowEnemy("Feind80-Nach80") end)
check("Kopfgeld 1.251 GOLD in 19", (function() local f = anyText(F, "1.251 GOLD"); return f and f._fontSize == 19 end)())
step("Kopfgeld dreistellig", function() ns.UI.ShowEnemy(one.key) end)
check("G6 Kopfgeld 17 GOLD wieder in 22 (Beiwerk, kleiner als bisher)", (function() local f = anyText(F, "17 GOLD"); return f and f._fontSize == 22 end)())
ns.db.enemies["Feind80-Nach80"] = nil
settle()

------------------------------------------------------------------------
-- 1.1.0: guild by member, manual entries, sound, one window per event
------------------------------------------------------------------------
local Look = ns.Look
local function rowsShown() return findAll(function(f) return f._kind == "Button" and f.item ~= nil and f._shown and f.under end) end
local function views() return find(function(f) return f.items and f.items[1] and f.items[1].view end) end
local function rowOf(pred) for _, r in ipairs(rowsShown()) do if pred(r.item) then return r end end end
local function collapsedCopy()
  local t, c = ns.db.settings.ui.guildCollapsed, {}
  if type(t) == "table" then for k, v in pairs(t) do c[k] = v end end
  return c
end
local function sameTable(a, b)
  for k, v in pairs(a) do if b[k] ~= v then return false end end
  for k, v in pairs(b) do if a[k] ~= v then return false end end
  return true
end
local function flatCount() return ns.UI.DataCount() end
ns.UI.ClosePanel()
type_("")

-- without ByMember (old logic): no switch
GG = ns.MakeGuild(40)
step("1.1 alte Logik ohne ByMember", function() tabClick("wanted"); guildTab._scripts.OnClick(guildTab); settle() end)
local VW = views()
check("1.1 Umschalter-Frame gebaut", VW ~= nil)
check("1.1 ohne ByMember kein Umschalter", VW and not VW:IsShown())
check("1.1 Sortierung unten rechts", find(function(f) return f.arrow and f.text._text == "Rang" and f:IsVisible() and f._points[1][1] == "BOTTOMRIGHT" end) ~= nil)

-- 0 members (ByMember empty)
GG = ns.MakeGuild(0, { members = 0 })
GG.ByMember = function() return {} end
step("1.1 nach Mitglied, leer", function() ns:Fire("GUILD_UPDATED"); settle(); VW.items[1]._scripts.OnClick(VW.items[1]); settle() end)
check("1.1 Umschalter sichtbar mit ByMember", VW:IsShown())
check("1.1 Zustand ui.guildView gemerkt", ns.db.settings.ui.guildView == "member")
check("1.1 Leerzustand nach Mitglied", anyText(F, "Im Gildenbuch steht noch nichts.") ~= nil and anyText(F, "Deine Kollegen hatten bisher Ruhe.") ~= nil)
check("1.1 Nach Mitglied unterstrichen", VW.items[1].mark:IsShown() and not VW.items[2].mark:IsShown())

-- own character without entries: still on top
GG = ns.MakeGuild(0, { members = 1 })
step("1.1 nur ich, leer", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("1.1 eigener Kopf auch leer", (function() local r = rowOf(function(i) return i.head and i.m.me end); return r and r.sub._text == "das sehen die anderen von dir" and not r.tri:IsShown() end)())
check("1.1 rechts Leerzustand", anyText(F, "Im Gildenbuch steht noch nichts.") ~= nil and anyText(F, "Im Gildenbuch steht noch nichts."):IsVisible())

-- 1 member (me) with 5 enemies: own section open
GG = ns.MakeGuild(5, { members = 1 })
step("1.1 ein Mitglied", function() ns:Fire("GUILD_UPDATED"); settle() end)
check("1.1 ein Mitglied: Kopf + 5 Zeilen", #rowsShown() == 6, #rowsShown())
check("1.1 Kopfzeile du, Taeter und Tode", (function()
  local r = rowOf(function(i) return i.head end)
  return r and r.mark._text == "du" and r.right._text:find("5 Täter · ", 1, true) == 1 and r.name._fontSize == 22
end)())
check("1.1 Kindzeile eingerueckt mit Kills", (function()
  local r = rowOf(function(i) return not i.head end)
  return r and r.name._points[1][2] == 58 and r.sub._text:find("× getötet · zuletzt vor 2 Tagen in ", 1, true) ~= nil
end)())

-- 30 members, 400 enemies
GG = ns.MakeGuild(400, { members = 30 })
ns.db.settings.ui.guildCollapsed = nil
step("1.1 dreissig Mitglieder", function() ns:Fire("GUILD_UPDATED"); settle() end)
local mine = GG.ByMember()[1]
local nflat = 1 + #mine.rows + 29
check("1.1 Standard: nur eigener Abschnitt offen", flatCount() == nflat, flatCount())
local created = M.created
local builds = ns.UI.mv.builds
step("1.1 Blaettern mit Rollbalken und Mausrad", function()
  for v = 0, nflat - 9, 3 do slider:SetValue(v) end
  local wheel = find(function(f) return f._scripts.OnMouseWheel ~= nil end)
  for _ = 1, 30 do wheel._scripts.OnMouseWheel(wheel, -1) end
  for _ = 1, 30 do wheel._scripts.OnMouseWheel(wheel, 1) end
end)
check("1.1 Pool: keine neuen Frames beim Blaettern", M.created == created, M.created - created)
step("1.1 Refresh ohne Aenderung", function() for _ = 1, 5 do ns.UI.Refresh() end end)
check("1.1 flache Liste nicht neu gebaut", ns.UI.mv.builds == builds, ns.UI.mv.builds - builds)
check("1.1 kein Neuaufbau, keine neuen Frames", M.created == created)
step("1.1 Kopf Kollege2 aufklappen", function()
  slider:SetValue(0)
  slider:SetValue(#mine.rows)        -- Kollege2 comes right after my rows
  local r = rowOf(function(i) return i.head and i.m.name == "Kollege2" end)
  r._scripts.OnClick(r, "LeftButton"); settle()
end)
local k2 = GG.ByMember()[2]
check("1.1 Zustand gemerkt (abweichend vom Standard)", ns.db.settings.ui.guildCollapsed and ns.db.settings.ui.guildCollapsed.Kollege2 == true)
check("1.1 Abschnitt offen", flatCount() == (nflat + #k2.rows), flatCount())
check("1.1 Dreieck zeigt nach unten", (function() local r = rowOf(function(i) return i.head and i.m.name == "Kollege2" end); return r and r.item.open end)())
check("1.1 Aufklappen: keine neuen Frames", M.created == created)
step("1.1 Kopf ist nicht als Feind waehlbar", function()
  local r = rowOf(function(i) return i.head and i.m.name == "Kollege2" end)
  r._scripts.OnClick(r, "RightButton"); settle()
end)
check("1.1 Rechtsklick auf Kopf: kein Menue, wieder zu", not menu:IsShown() and (ns.db.settings.ui.guildCollapsed.Kollege2 == nil))
step("1.1 Kindzeile anklicken", function()
  slider:SetValue(0)
  local r = rowOf(function(i) return not i.head and i.m.me end)
  r._scripts.OnClick(r, "LeftButton")
end)
local chosen = rowOf(function(i) return not i.head and i.m.me end).item.r.entry
check("1.1 Plakat zeigt den gewaehlten Gildenfeind", anyText(F, Look.Name(chosen)) ~= nil and anyText(F, "G I L D E N B U C H") ~= nil)
check("1.1 Kindzeile unterstrichen", rowOf(function(i) return not i.head and i.m.me end).under:IsShown())
step("1.1 Kopf klicken aendert die Auswahl nicht", function()
  local r = rowOf(function(i) return i.head and i.m.me end)
  r._scripts.OnClick(r, "LeftButton"); settle()
  r = rowOf(function(i) return i.head and i.m.me end)
  r._scripts.OnClick(r, "LeftButton"); settle()
end)
check("1.1 Auswahl bleibt", anyText(F, Look.Name(chosen)) ~= nil)
step("1.1 Alle auf", function()
  local b = find(function(f) return f.a and f.b and f._scripts.OnClick end)
  check("G16 Alle auf: Doppeldreieck links neben dem Suchfeld", b:IsVisible() and b._points[1][2] == 14 and b.open == false)
  b._scripts.OnClick(b); settle()
end)
check("1.1 Alle auf: 430 Zeilen", flatCount() == 430, flatCount())
check("1.1 Doppeldreieck wechselt auf Alle zu", find(function(f) return f.a and f.b end).open == true)
step("1.1 Alle zu", function()
  local b = find(function(f) return f.a and f.b and f._scripts.OnClick end)
  b._scripts.OnClick(b); settle()
end)
check("1.1 Alle zu: 30 Koepfe", flatCount() == 30, flatCount())
check("1.1 Alle zu gemerkt (eigener Abschnitt markiert)", ns.db.settings.ui.guildCollapsed.Davee == true and ns.db.settings.ui.guildCollapsed.Kollege3 == nil)
local saved = collapsedCopy()
local target = GG.ByMember()[5].rows[1].entry
step("1.1 Suche nach Taeter", function() type_(target.name); settle() end)
check("1.1 Suche klappt den Abschnitt auf", rowOf(function(i) return not i.head and i.r.entry == target end) ~= nil)
check("1.1 Suche aendert den Zustand nicht", sameTable(saved, collapsedCopy()))
step("1.1 Suche nach Mitglied", function() type_("Kollege7"); settle() end)
check("1.1 Mitglied gefunden mit allen Zeilen", flatCount() == 1 + #GG.ByMember()[7].rows, flatCount())
step("1.1 Enter waehlt den ersten Feind", function() search._scripts.OnEnterPressed(search); settle() end)
check("1.1 Enter: Plakat des ersten Feinds", anyText(F, Look.Name(GG.ByMember()[7].rows[1].entry)) ~= nil)
step("1.1 Suche leeren", function() type_(""); settle() end)
check("1.1 danach wieder zu", flatCount() == 30 and sameTable(saved, collapsedCopy()))
builds = ns.UI.mv.builds
step("1.1 Fenster zu, 100x GUILD_UPDATED", function() F:Hide(); for _ = 1, 100 do ns:Fire("GUILD_UPDATED") end; settle() end)
check("1.1 geschlossen: kein Neuaufbau", ns.UI.mv.builds == builds)
step("1.1 wieder auf", function() F:Show(); settle() end)
check("1.1 beim Oeffnen einmal neu", ns.UI.mv.builds == builds + 1, ns.UI.mv.builds - builds)
step("1.1 zurueck nach Feind", function() VW.items[2]._scripts.OnClick(VW.items[2]); settle() end)
check("1.1 Nach Feind: Sortierung unten", find(function(f) return f.arrow and f.text._text == "Rang" and f:IsVisible() end) ~= nil and flatCount() == 400)

-- manual entries in both views and on the poster
GG = ns.MakeGuild(10, { listed = 3, listedFirst = true, members = 3, mixedListed = true })
step("1.1 Hand-Eintraege nach Feind", function() ns:Fire("GUILD_UPDATED"); settle(); slider:SetValue(4) end)
check("1.1 Hand-Eintraege am Ende", (function()
  local rs = rowsShown()
  local last = rs[#rs]
  return #rs == 9 and last.item.listedOnly and rs[#rs - 2].item.listedOnly and not rs[#rs - 3].item.listedOnly
end)())
check("1.1 Untertext eingetragen von, blasser", (function()
  local r = rowOf(function(i) return i.key == "Hand2-Eintrag2" end)
  return r and r.sub._text == "eingetragen von Moppel" and r.name._tc[4] < 0.8 and r.rank._text == ""
end)())
check("1.1 Gildenliste nicht veraendert", GG.list[1].listedOnly == true)
step("1.1 Plakat Hand-Eintrag", function()
  local r = rowOf(function(i) return i.key == "Hand1-Eintrag1" end)
  r._scripts.OnClick(r, "LeftButton")
end)
check("1.1 VON HAND EINGETRAGEN statt Opferzahl", anyText(F, "VON HAND EINGETRAGEN") ~= nil and anyText(F, "V E R M E R K") ~= nil)
check("1.1 kein Stempel Nr. 1", find(function(f) return f._kind == "Texture" and f._tex and f._tex:find("stamp_guild", 1, true) and f._shown end) == nil)
check("1.1 statt Taten: wer, wann", anyText(F, "EINGETRAGEN") ~= nil and anyText(F, "Moppel · ") ~= nil and anyText(F, "Knäckebrot · ") ~= nil)
check("1.1 Im Buch von gekuerzt", anyText(F, "Im Buch von: Moppel, Hühnerbein und 1 weiterer") ~= nil)
local hit = find(function(f) return f.tip and f.tip[1] == "Im Buch von" end)
check("1.1 Tooltip mit allen Namen", hit and hit:IsShown() and hit.tip[2] == "Moppel, Hühnerbein, Knäckebrot")
step("1.1 Tooltip zeigen", function() G.GameTooltip._lines = {}; hit._scripts.OnEnter(hit) end)
step("1.1 Plakat mit Tat und Hand-Eintrag", function()
  local r = rowOf(function(i) return i.key == GG.list[5].key end) or rowsShown()[1]
  slider:SetValue(0)
  r = rowOf(function(i) return i.key == "Gilde1-Feind1" end)
  r._scripts.OnClick(r, "LeftButton")
end)
check("1.1 gemischt: Opfer und Im Buch von", anyText(F, "Im Buch von: Moppel") ~= nil and anyText(F, "O P F E R") ~= nil and anyText(F, "T A T E N") ~= nil)
step("1.1 Hand-Eintraege nach Mitglied", function() VW.items[1]._scripts.OnClick(VW.items[1]); settle()
  local b = find(function(f) return f.a and f.b and f._scripts.OnClick end)
  if b and not b.open then b._scripts.OnClick(b); settle() end
end)
check("1.1 Kindzeile von Hand eingetragen, blass", (function()
  for v = 0, 20 do
    slider:SetValue(v)
    local r = rowOf(function(i) return not i.head and i.r.listed and i.r.kills == 0 end)
    if r then return r.sub._text == "von Hand eingetragen · vor 2 Tagen" and r.name._tc[4] < 0.8 end
  end
end)())
check("1.1 Kopf: von Hand gezaehlt", (function()
  slider:SetValue(0)
  for _, r in ipairs(findAll(function(f) return f.item and f.item.head and f.right end)) do
    if r.right._text and r.right._text:find("Täter", 1, true) then return true end
  end
end)())

-- tooltip line and alarm for pure manual entries
step("1.1 Tooltip Hand-Eintrag", function()
  ns.units.mouseover = "Hand1-Eintrag1"
  tt._unitName, tt._unit, tt._lines = "Hand1", "mouseover", {}
  M.tooltipHook(tt, {})
end)
check("1.1 Tooltip GILDE: im Buch von", tt._lines[1] and tt._lines[1]:find("GILDENBUCH:|r |cffd8c8a8im Buch von Moppel, Hühnerbein und 1 weiterer", 1, true) ~= nil, tt._lines[1])
M.Advance(300); closePopup()
step("1.1 Hand-Eintrag gesichtet, alertListed aus", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Hand2-Eintrag2", nil, "nameplate") end)
check("1.1 kein Alarm ohne alertListed", not popup:IsShown())
ns.Store.Setting("guild.alertListed", true)
step("1.1 Hand-Eintrag gesichtet, alertListed an", function() ns:Fire("GUILD_ENEMY_SPOTTED", "Hand3-Eintrag3", nil, "nameplate") end)
check("1.1 Alarm mit Hand-Text", popup:IsShown() and popup.line._text == "steht im Buch von Moppel", popup.line._text)
closePopup()

-- house rules: new checkboxes, three sheets
step("1.1 Hausordnung Gilde", function()
  ns.UI.OpenPanel("settings")
  local t = find(function(f) return f.page == 3 and f._scripts.OnClick end)
  t._scripts.OnClick(t)
end)
for _, o in ipairs({ { "shareManual", "Von Hand Eingetragene teilen", true }, { "alertListed", "Auch bei von Hand Eingetragenen warnen", true } }) do
  local cb = find(function(f) return f._kind == "CheckButton" and f.opt and f.opt.guild == o[1] end)
  check("1.1 Haken " .. o[1], cb and cb:IsVisible() and cb.label._text == o[2] and cb:GetChecked() == o[3])
  if cb then cb:SetChecked(false); cb._scripts.OnClick(cb) end
  check("1.1 Haken " .. o[1] .. " gespeichert", ns.db.settings.guild[o[1]] == false)
end
check("1.1 Blatt Gilde: sieben Haken", #findAll(function(f) return f._kind == "CheckButton" and f.opt and f.opt.guild and f:IsVisible() end) == 7)

------------------------------------------------------------------------
-- sound
------------------------------------------------------------------------
local SND = M.mediaDir .. "/Sounds"
local listing = {}
do
  local p = io.popen('ls "' .. SND .. '"')
  for l in p:lines() do listing[l] = true end
  p:close()
end
local nfiles = 0
for _ in pairs(listing) do nfiles = nfiles + 1 end
check("Ton: 25 Dateien im Ordner", nfiles == 25, nfiles)
local combos, okc = 0, 0
for _, s in ipairs(Look.SOUNDS) do
  if not s.builtin and not s.silent then
    for lv = 1, Look.VOLUMES do
      combos = combos + 1
      local path = Look.SoundFile(s.key, lv)
      local file = path:match("Sounds\\([^\\]+)$")
      -- exact spelling: the name must be in the folder like this (Linux is case sensitive)
      if path:find("^Interface\\AddOns\\DeathNote\\Media\\Sounds\\") and file and listing[file] then okc = okc + 1 end
    end
  end
end
check("Ton: jede Kombination Ton x Stufe hat ihre Datei", combos == 25 and okc == 25, okc .. "/" .. combos)
check("Ton: Standard ist der bisherige Raid-Warnton", Look.SoundChoice().key == "warnung")
ns.Store.Setting("alert.sound", true)
local calls0 = #M.soundCalls
M.Advance(10)
step("Ton: Standard spielt SOUNDKIT", function() Look.Alarm("alert") end)
check("Ton: Raid-Warnung ueber PlaySound", M.soundCalls[#M.soundCalls].kit == 8959 and M.soundCalls[#M.soundCalls].channel == "Master")
ns.Store.Setting("alert.soundKey", "glocke"); ns.Store.Setting("alert.volume", 4)
M.Advance(10)
calls0 = #M.soundCalls
step("Ton: fuenf Alarme in einer Sekunde", function()
  for _ = 1, 5 do Look.Alarm("alert"); M.Advance(0.2) end
end)
check("Ton: Drossel, ein Ton", #M.soundCalls == calls0 + 1, #M.soundCalls - calls0)
check("Ton: eigene Datei Stufe 4", M.soundCalls[#M.soundCalls].file == "Interface\\AddOns\\DeathNote\\Media\\Sounds\\glocke_4.ogg")
M.Advance(0.6)
step("Ton: nach 1,5 s wieder", function() Look.Alarm("alert") end)
check("Ton: zweiter Ton nach der Drossel", #M.soundCalls == calls0 + 2)
M.Advance(2)
M.soundFileResult = false
step("Ton: Datei spielt nicht", function() check("Ton: Rueckfall meldet warnung", Look.Alarm("alert") == "warnung") end)
M.soundFileResult = nil
check("Ton: Rueckfall auf Raid-Warnung", M.soundCalls[#M.soundCalls].kit == 8959)
M.Advance(2)
ns.Store.Setting("alert.channel", "Dialog")
step("Ton: Kanal Dialog", function() Look.Alarm("alert") end)
check("Ton: Kanal weitergereicht", M.soundCalls[#M.soundCalls].channel == "Dialog")
M.Advance(2)
ns.Store.Setting("alert.channel", "Music")
step("Ton: Kanal Music (nicht im Umschalter) wirft nicht", function() Look.Alarm("alert") end)
check("Ton: Music wird gespielt", M.soundCalls[#M.soundCalls].channel == "Music")
ns.Store.Setting("alert.channel", "Master")
M.Advance(2)
ns.Store.Setting("alert.soundKey", "gibtsnicht"); ns.Store.Setting("alert.volume", 9)
step("Ton: unbekannter Ton", function() check("Ton: unbekannt = Raid-Warnung", Look.Alarm("alert") == "warnung") end)
ns.Store.Setting("alert.soundKey", "aus")
M.Advance(2)
calls0 = #M.soundCalls
step("Ton: Kein Ton", function() Look.Alarm("alert"); M.Advance(2); Look.Alarm("revenge") end)
check("Ton: Kein Ton spielt nichts", #M.soundCalls == calls0)
ns.Store.Setting("alert.soundKey", "sirene"); ns.Store.Setting("alert.volume", 2)
ns.Store.Setting("alert.sound", false)
M.Advance(2)
calls0 = #M.soundCalls
step("Ton: Hauptschalter aus", function()
  Look.Alarm("alert"); M.Advance(2); Look.Alarm("revenge"); M.Advance(200)
  ns:Fire("ENEMY_SPOTTED", "Feind9-Nach9", nil, "nameplate")
end)
check("Ton: Hauptschalter aus = kein Aufruf", #M.soundCalls == calls0, #M.soundCalls - calls0)
closePopup()
ns.Store.Setting("alert.sound", true)

-- house rules, sheet Alarm
step("Ton: Blatt Alarm", function()
  local t = find(function(f) return f.page == 2 and f._scripts.OnClick end)
  t._scripts.OnClick(t)
end)
check("Ton: Zeile Ton zeigt Sirene", anyText(F, "Sirene") ~= nil and anyText(F, "Sirene"):IsVisible())
local tminus, tplus = stepperButtons("Ton")
local vminus, vplus = stepperButtons("Lautstärke")
local function alarmCalls() local n = 0; for _, c in ipairs(M.soundCalls) do if c.kit ~= 856 then n = n + 1 end end; return n end
calls0 = alarmCalls()
step("Ton: weiterklicken spielt Probe", function() tplus._scripts.OnClick(tplus, "LeftButton") end)
check("Ton: naechster ist Kein Ton", ns.db.settings.alert.soundKey == "aus" and anyText(F, "Kein Ton") ~= nil)
step("Ton: nochmal weiter (rundum)", function() tplus._scripts.OnClick(tplus, "LeftButton") end)
check("Ton: rundum zur Raid-Warnung, Probe gespielt", ns.db.settings.alert.soundKey == "warnung" and alarmCalls() == calls0 + 1
      and M.soundCalls[#M.soundCalls].kit == 8959, alarmCalls() - calls0)
check("Ton: Regler ausgegraut bei eingebautem Ton", vminus.off == true and vplus.off == true and vplus.tri._vc[4] == Look.TONE.off
      and anyText(F, "Lautstärke dieses Tons folgt dem Kanal in den Spieloptionen.") ~= nil)
step("Ton: + bei ausgegrautem Regler", function() vplus._scripts.OnClick(vplus, "LeftButton") end)
check("Ton: Lautstaerke unveraendert", ns.db.settings.alert.volume == 2)
step("Ton: zurueck zu Sirene", function() tminus._scripts.OnClick(tminus, "LeftButton"); tminus._scripts.OnClick(tminus, "LeftButton") end)
check("Ton: Regler wieder aktiv", vplus.off == false and ns.db.settings.alert.soundKey == "sirene")
calls0 = #M.soundCalls
step("Ton: lauter", function() vplus._scripts.OnClick(vplus, "LeftButton") end)
check("Ton: Stufe 3 mit Probe", ns.db.settings.alert.volume == 3 and M.soundCalls[#M.soundCalls].file:find("sirene_3.ogg", 1, true) ~= nil)
check("Ton: drei Balken voll", (function()
  local n = 0
  for _, f in ipairs(M.frames) do if f._kind == "Texture" and f._w == 9 and f._h == 12 and (f._alpha or 1) > 0.5 then n = n + 1 end end
  return n == 3
end)())
step("Ton: Kanal Effekte", function()
  local b = find(function(f) return f.channel == "SFX" end)
  b._scripts.OnClick(b)
end)
check("Ton: Kanal SFX gespeichert und Probe", ns.db.settings.alert.channel == "SFX" and M.soundCalls[#M.soundCalls].channel == "SFX")
check("Ton: Kanal markiert", find(function(f) return f.channel == "SFX" end).mark:IsShown() and not find(function(f) return f.channel == "Master" end).mark:IsShown())
step("Ton: Kein Ton graut Lautstaerke und Kanal aus", function() Look.SetSound("aus"); ns.UI.FillSettings() end)
check("Ton: Kein Ton: Regler und Kanal aus, Tonwahl bleibt bedienbar", tplus.off == false and vplus.off == true
      and find(function(f) return f.channel == "SFX" end).off == true and ns.db.settings.alert.sound == false)
Look.SetSound("warnung")
ns.Store.Setting("alert.sound", true)
ns.Store.Setting("alert.channel", "Master")
ns.UI.ClosePanel()

------------------------------------------------------------------------
-- D: one window per event and player
------------------------------------------------------------------------
M.FinishAnims(); M.Advance(300); closePopup()
put(enemy(90, { kills = 2 })); put(enemy(91, { kills = 2 })); put(enemy(92, { kills = 2 }))
local K90, K91, K92 = "Feind90-Nach90", "Feind91-Nach91", "Feind92-Nach92"
step("D1 Popup fuer Taeter, dann Tod", function()
  spot(K90)
  ns:Fire("DEATH_RECORDED", { t = NOW, kind = "pvp", killerKey = K90, sure = true, others = { K91 } }, K90)
  -- only finish fading out the popup, the message keeps running
  if popup.outAnim._playing then popup.outAnim._playing = false; popup.outAnim._scripts.OnFinished(popup.outAnim) end
end)
check("D1 Banner zeigt den Taeter", banner:IsShown() and anyText(banner, "Feind90 Nach90") ~= nil,
      tostring(banner:IsShown()) .. " " .. tostring(banner.name._text) .. " " .. tostring(ns.db.settings.deathMessage))
check("D1 Popup fuer ihn geschlossen", not popup:IsShown())
step("D1 Taeter weiter in Sicht", function() spot(K90); spot(K91) end)
check("D1 kein Popup fuer Taeter und Mittaeter", not popup:IsShown())
M.FinishAnims()
step("D2 Banner aktiv: Rache", function() M.Advance(300); ns:Fire("REVENGE", K92); spot(K92) end)
check("D2 kein Popup fuer den Spieler der Meldung", banner:IsShown() and not popup:IsShown())
check("D2 Abklingzeit verbraucht", (function() M.FinishAnims(); spot(K92); return not popup:IsShown() end)())
-- different players: both, not on top of each other (UI scale 0.6, alarm 150 %)
local function overlap(a, b)
  local l1, b1, r1, t1 = Look.Rect(a)
  local l2, b2, r2, t2 = Look.Rect(b)
  if not (l1 and l2) then return "keine Geometrie" end
  t2 = t2 + 18 -- stamp sticks out above the message
  return l1 < r2 and r1 > l2 and b1 < t2 and t1 > b2
end
for _, cfg in ipairs({ { 1, 1 }, { 0.6, 1 }, { 0.6, 1.5 }, { 1, 1.5 }, { 0.6, 0.8 } }) do
  M.SetUIScale(cfg[1]); ns.Store.Setting("alert.scale", cfg[2])
  M.Advance(300); closePopup(); M.FinishAnims()
  step("D2 Banner X, Popup Y bei " .. cfg[1] .. "/" .. cfg[2], function()
    ns:Fire("DEATH_RECORDED", { t = NOW, kind = "pvp", killerKey = K90, sure = true }, K90)
    spot(K91)
  end)
  check("D2 beide sichtbar " .. cfg[1] .. "/" .. cfg[2], banner:IsShown() and popup:IsShown())
  check("D2 nicht uebereinander " .. cfg[1] .. "/" .. cfg[2], overlap(popup, banner) == false, tostring(overlap(popup, banner)))
  M.FinishAnims(); closePopup()
  step("D2 erst Popup, dann Banner " .. cfg[1] .. "/" .. cfg[2], function()
    M.Advance(300); spot(K91)
    ns:Fire("REVENGE", K92)
  end)
  check("D2 Banner nicht auf dem Popup " .. cfg[1] .. "/" .. cfg[2], overlap(popup, banner) == false, tostring(overlap(popup, banner)))
  M.FinishAnims(); closePopup()
end
-- stored popup position in the middle of the message
M.SetUIScale(0.6); ns.Store.Setting("alert.scale", 1.3)
ns.db.settings.alert.point = { "TOP", "TOP", 0, -260 }
step("D2 Popup auf die Meldung gezogen", function()
  ns.Alert.ApplyScale()
  M.Advance(300); spot(K91); ns:Fire("REVENGE", K92)
end)
check("D2 Meldung weicht aus", overlap(popup, banner) == false, tostring(overlap(popup, banner)))
M.FinishAnims(); closePopup()

-- D3a button exactly on top at UI scale 0.6 and alarm 100 % / 130 %, also with a stored position
for _, cfg in ipairs({ { 0.6, 1 }, { 0.6, 1.3 }, { 1, 1.3 }, { 0.6, 1.3, true } }) do
  M.SetUIScale(cfg[1]); ns.Store.Setting("alert.scale", cfg[2])
  ns.db.settings.alert.point = cfg[3] and { "CENTER", "CENTER", 120, -80 } or nil
  ns.Alert.ApplyScale()
  M.Advance(300)
  step("D3a Knopf " .. table.concat({ cfg[1], cfg[2], tostring(cfg[3]) }, "/"), function() spot(K90) end)
  local l1, b1, r1, t1 = Look.Rect(popup)
  local l2, b2, r2, t2 = Look.Rect(button)
  check("D3a deckungsgleich " .. table.concat({ cfg[1], cfg[2], tostring(cfg[3]) }, "/"), l1 and l2 and button:IsShown()
        and math.abs(l1 - l2) < 1e-6 and math.abs(b1 - b2) < 1e-6 and math.abs(r1 - r2) < 1e-6 and math.abs(t1 - t2) < 1e-6,
        l1 and l2 and (("%.2f,%.2f,%.2f,%.2f vs %.2f,%.2f,%.2f,%.2f"):format(l1, b1, r1, t1, l2, b2, r2, t2)) or "nil")
  closePopup()
end
check("D3a Knopf ohne eigene Texturen", (function()
  for _, f in ipairs(M.frames) do if f._parent == button and (f._kind == "Texture" or f._kind == "FontString") then return false end end
  return button._template == "SecureActionButtonTemplate"
end)())
ns.db.settings.alert.point = nil; M.SetUIScale(1); ns.Store.Setting("alert.scale", 1); ns.Alert.ApplyScale()
check("Look.Rect: Frame ohne Anker liefert nil statt zu werfen", (function()
  local f = G.CreateFrame("Frame", nil, G.UIParent)
  local ok, l = pcall(Look.Rect, f)
  return ok and l == nil
end)())
check("Look.Rect: Teilwerte nil", (function()
  local f = G.CreateFrame("Frame", nil, G.UIParent)
  f.GetRight = function() return nil end
  f.GetLeft, f.GetTop, f.GetBottom = function() return 1 end, function() return 2 end, function() return 0 end
  local ok, l = pcall(Look.Rect, f)
  return ok and l == nil
end)())

-- D3b own and guild hit: one popup, own list takes precedence
GG = ns.MakeGuild(3)
M.Advance(300); closePopup()
local snd = #M.sounds
step("D3b Gildenalarm, dann derselbe als eigener", function()
  ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde2-Feind2", nil, "nameplate")
  put({ key = "Gilde2-Feind2", name = "Gilde2", surname = "Feind2", status = "wanted", kills = 1, deaths = {} })
  ns:Fire("ENEMY_SPOTTED", "Gilde2-Feind2", nil, "nameplate")
  ns:Fire("GUILD_ENEMY_SPOTTED", "Gilde2-Feind2", nil, "nameplate")
end)
check("D3b ein Popup, jetzt als eigener Feind", popup:IsShown() and popup.title._text ~= "GILDENFEIND GESICHTET" and anyText(popup, "+1") == nil, popup.title._text)
check("D3b nur ein Ton", #M.sounds == snd + 1)
closePopup()
check("D3b nichts rueckt nach", not popup:IsShown())
ns.db.enemies["Gilde2-Feind2"] = nil

-- D3d queue: old and new key of the same player
M.Advance(300)
put(enemy(93, { kills = 2 })); put({ key = "Feind93-Neu", name = "Feind93", surname = "Neu", status = "wanted", kills = 2, deaths = {} })
step("D3d beide Schluessel in der Schlange, dann Umzug", function()
  spot(K90); spot("Feind93-Nach93"); spot("Feind93-Neu")
  ns:Fire("ENEMY_REKEYED", "Feind93-Nach93", "Feind93-Neu")
end)
check("D3d nur noch einer wartet", anyText(popup, "+1 weiterer") ~= nil)
local shown = {}
step("D3d Schlange abarbeiten", function()
  for _ = 1, 4 do if popup:IsShown() then shown[#shown + 1] = popup.name._text end; closePopup() end
end)
check("D3d Spieler genau einmal", #shown == 2 and shown[2] == "Feind93 Neu", table.concat(shown, ","))
step("D3d Umzug des gezeigten, Doppel in der Schlange", function()
  M.Advance(300)
  spot("Feind93-Neu"); spot(K91)
  put(enemy(94, { kills = 2 }))
  spot("Feind94-Nach94")
  ns:Fire("ENEMY_REKEYED", "Feind94-Nach94", "Feind93-Neu")
end)
check("D3d gezeigter nicht nochmal in der Schlange", anyText(popup, "+1 weiterer") ~= nil)
closePopup(); closePopup(); closePopup()

-- D3e test alarm plus a real one for the same player
M.Advance(300)
snd = #M.sounds
step("D3e Probe, dann echter", function()
  ns:Fire("TEST_ALERT")
  local k = popup.name._text
  for key, e in pairs(ns.db.enemies) do if Look.Name(e) == k then spot(key) end end
end)
check("D3e ein Popup, ein Ton", popup:IsShown() and anyText(popup, "+1") == nil and #M.sounds == snd + 1)
closePopup()
-- D3c edge flash leaves no visible area
check("D3c Blitz ohne Maus, nach dem Puls versteckt", (function()
  M.FinishAnims()
  return flash._mouse == false and not flash:IsShown()
end)())

-- Mock: only listed widget methods; the whole run used no other, typos show up
local unk = {}
for k in pairs(M.unknown or {}) do unk[#unk + 1] = k end
check("Mock: nur Methoden aus der Liste benutzt", #unk == 0, table.concat(unk, ", "))
check("Mock: Tippfehler ist nil und wirft beim Aufruf", popup.SetTextt == nil and not pcall(function() popup:Shwo() end)
      and not pcall(function() return popup.title.SetBackdrop end) and not pcall(function() popup.icon:SetText("x") end))

-- no OnUpdate logic except while dragging
local onupd = findAll(function(f) return f._scripts.OnUpdate ~= nil end)
check("kein dauerhaftes OnUpdate", #onupd == 0, #onupd .. " Frames")
local leaked = {}
for k in pairs(M.newGlobals) do if not tostring(k):find("^DeathNote") then leaked[#leaked + 1] = k end end
check("keine fremden Globals", #leaked == 0, table.concat(leaked, ", "))

print(("Rauchtest UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
