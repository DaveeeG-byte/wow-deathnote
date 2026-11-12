-- Overview (overview, intuition, design): one proof test per finding that changes behaviour, the
-- scenarios a to j as runs, one guard per consistency rule and one run with old logic.
-- Usage: luajit tests/ui/gesamtschau.lua [source folder]
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local root = here .. "/../.."
local function addonDir(r)
  for _, d in ipairs({ "DeathNote", "Staatsfeind" }) do
    local f = io.open(r .. "/" .. d .. "/Alert.lua", "r")
    if f then f:close(); return r .. "/" .. d end
  end
  return r .. "/DeathNote"
end
local SRC = arg[1] or addonDir(root)
local MEDIA = addonDir(root) .. "/Media"

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end

local NOW = 1800000000
-- a fresh world: mock, stub, the UI files; opts.old = logic without the contract functions of the overview
local function world(opts)
  opts = opts or {}
  package.loaded.mock, package.loaded.stub = nil, nil
  local M = require("mock")
  M.mediaDir = MEDIA
  local ns = require("stub")(M)
  if opts.old then
    ns.oldLogic = true
    ns.Store.OpenCases, ns.Store.Weight = nil, nil
    ns.Util.When = nil
  else
    ns.Util.When = function(t) return os.date("%d.%m. %H:%M", t) end
  end
  if opts.ppu then M.ppu = opts.ppu end
  if opts.ui then M.G.UIParent._w, M.G.UIParent._h = opts.ui[1], opts.ui[2] end
  M.Load(SRC .. "/Alert.lua", ns); M.Load(SRC .. "/UI.lua", ns); M.Load(SRC .. "/Extras.lua", ns)
  ns:Fire("READY")
  local W = { M = M, ns = ns, G = M.G }
  function W.find(pred) for _, f in ipairs(M.frames) do if pred(f) then return f end end end
  function W.all(pred) local o = {} for _, f in ipairs(M.frames) do if pred(f) then o[#o + 1] = f end end return o end
  function W.under(f, r) local p = f._parent while p do if p == r then return true end p = p._parent end return false end
  function W.text(needle, vis)
    for _, f in ipairs(M.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and (not vis or f:IsVisible()) then return f end
    end
  end
  function W.settle() M.Advance(0.01); M.Advance(0.01) end
  function W.open() local Fx = rawget(M.G, "DeathNoteFrame"); if not (Fx and Fx:IsShown()) then ns:Fire("TOGGLE_UI") end; W.settle() end
  function W.tab(id) local t = W.find(function(f) return f.id == id and f._scripts.OnClick end); t._scripts.OnClick(t); W.settle(); return t end
  function W.row(pred) return W.find(function(f) return f._kind == "Button" and f.item and f._shown and f.under and pred(f.item) end) end
  function W.click(f, b) f._scripts.OnClick(f, b or "LeftButton"); W.settle() end
  function W.btn(label) return W.find(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end) end
  function W.put(e) ns.db.enemies[e.key] = e; return e end
  function W.step(name, fn)
    local before, vb = #ns.errors, #M.violations
    local ok, err = xpcall(fn, debug.traceback)
    check(name .. " (wirft nicht)", ok, err)
    check(name .. " (Bus fehlerfrei)", #ns.errors == before, ns.errors[#ns.errors])
    check(name .. " (keine Verstoesse)", #M.violations == vb, M.violations[#M.violations])
  end
  return W
end

local function enemy(i, x)
  local e = { key = "Feind" .. i .. "-Nach" .. i, name = "Feind" .. i, surname = "Nach" .. i, class = "MAGE", classLoc = "Magierin",
              status = "wanted", kills = 3, assists = 0, suspected = 0, revenge = 0, note = "", lastKill = NOW - 3600,
              lastSeen = { t = NOW - 60 }, deaths = { { t = NOW - 3600, zone = "Schlingendorntal", subzone = "Die ungezähmte Küste",
              spell = "Feuerschlag", me = "Davee", role = "kill", sure = true, source = "recap", others = {} } } }
  for k, v in pairs(x or {}) do e[k] = v end
  return e
end

------------------------------------------------------------------------
-- Structure: four tabs, "?" and gear
------------------------------------------------------------------------
local W = world()
local ns, M, G = W.ns, W.M, W.G
W.step("erstes Oeffnen, leer", W.open)
local F = G.DeathNoteFrame
local labels = {}
for _, t in ipairs(F.tabs) do labels[#labels + 1] = t.label end
check("IA vier Reiter: Gesucht, Zu klären, Todesjournal, Gilde", table.concat(labels, "|") == "Gesucht|Zu klären|Todesjournal|Gilde", table.concat(labels, "|"))
check("IA kein Reiter Verdächtig/Begnadigt", not W.text("Verdächtig") and not W.text("Begnadigt  "))
-- Scenario a / G26: the empty first tab says what the book does
check("a/G26 Leerzustand erklaert das Buch", W.text("Wer dich in der offenen Welt tötet, steht danach hier. Von selbst.", true) ~= nil)
check("a Reiter ohne Zahl, wenn leer", F.tabs[1].text._text == "Gesucht" and F.tabs[2].text._text == "Zu klären")
check("G4 Knopf ? links neben dem Zahnrad", F.help and F.help.text._text == "?" and F.help._points[1][3] == "LEFT")
W.step("G4 ? oeffnet die Gebrauchsanweisung", function() W.click(F.help) end)
local UI = ns.UI
check("G4 Gebrauchsanweisung mit 8 Absaetzen (fix-3: Jagd im Absatz Gilde)", W.text("Gebrauchsanweisung", true) ~= nil and #UI.HELP == 8)
local words = 0
for _, p in ipairs(UI.HELP) do for _ in (p[1] .. " " .. p[2]):gmatch("%S+") do words = words + 1 end end
check("G4 hoechstens 180 Woerter", words <= 180, words)
for _, p in ipairs(UI.HELP) do check("G4 Absatz sichtbar: " .. p[1], W.text(p[2], true) ~= nil) end
check("G4 Hover: Tooltip So geht das Buch", (function()
  G.GameTooltip._text = nil
  F.help._scripts.OnEnter(F.help)
  return F.help.text._tc[1] == ns.Look.RED_ON_BLACK[1]
end)())
F.help._scripts.OnLeave(F.help)
W.step("G4 nochmal ? schliesst", function() W.click(F.help) end)
check("G4 zu", not W.text("Gebrauchsanweisung", true))

------------------------------------------------------------------------
-- G5, G6, G7, G8, G27, G31: Plakat
------------------------------------------------------------------------
local yoron = W.put(enemy(1, { name = "Yoron", surname = "Pvp", key = "Yoron-Pvp", kills = 1, assists = 2, level = 35,
  raceLoc = "Zwerg", guild = "gilde34a3", deaths = {
    { t = NOW - 100, zone = "Schlingendorntal", subzone = "Die ungezähmte Küste", spell = "Siegel des Befehls", me = "Davee", role = "kill", sure = true },
    { t = NOW - 200, zone = "Schlingendorntal", subzone = "Die ungezähmte Küste", spell = "Feuerschlag", me = "Davee", role = "assist", sure = false },
    { t = NOW - 300, zone = "Schlingendorntal", subzone = "Die ungezähmte Küste", spell = "Arkanschlag", me = "Davee", sure = false, source = "recap" } } }))
local yac = W.put(enemy(2, { name = "Brenensil", surname = "Mage", key = "Brenensil-Mage", kills = 2, assists = 1 }))
local kug = W.put(enemy(3, { name = "Brenendan", surname = "Forever", key = "Brenendan-Forever", kills = 0, assists = 1 }))
W.step("Gesucht mit Mittaetern", function() ns:Fire("ENEMY_UPDATED", yoron.key); W.settle(); UI.ShowEnemy(yoron.key) end)
local rx = W.row(function(i) return i.key == yoron.key end)
check("G5 Zeile: 1× getötet · 2× beteiligt", rx and rx.sub._text:find("^1× getötet · 2× beteiligt · gesehen ") ~= nil, rx and rx.sub._text)
check("G5 nur beteiligt: Gesucht, kein Verdacht", W.row(function(i) return i.key == kug.key end).sub._text:find("^1× beteiligt") ~= nil)
check("G5 Rang nach kills, dann assists", ns.Store.Rank(yac.key) == 1 and ns.Store.Rank(yoron.key) == 2 and ns.Store.Rank(kug.key) == 3)
local tally = W.find(function(f) return f._kind == "FontString" and f._fontSize == 16 and f._text == "1× getötet · 2× beteiligt" end)
check("G6 Kernzahl in Hand 16 unter dem Balken", tally and tally:IsVisible())
local bounty = W.text(" GOLD", true)
check("G6 Kopfgeld kleiner als die Kernzahl-Zeile ist gross: 22 pt", bounty and bounty._fontSize == 22)
check("G6/G31 keine Zeile Rang x von y", not W.text("Rang 2 von", true) and not W.text("Rang 1 von", true))
check("G7 Zeile 1 Stufe und Klasse, Rasse eigene Zeile", W.text("Stufe 35 · Magierin", true) and W.text("Zwerg", true) and W.text("Gilde: gilde34a3", true))
check("G31 Gilde ohne spitze Klammern", not W.text("<gilde34a3>", true))
local function deedRow(spell) return W.find(function(f) return f.tag and f.text._text and f.text._text:find(spell, 1, true) and f:IsVisible() end) end
local d1, d2, d3 = deedRow("Siegel"), deedRow("Feuerschlag"), deedRow("Arkanschlag")
check("G8 Tat: Datum, Ursache, Ort zuletzt", d1 and d1.text._text:find("^%d%d%.%d%d%. %d%d:%d%d · Siegel des Befehls · Die ungezähmte Küste$") ~= nil, d1 and d1.text._text)
check("G5/G8 Rolle als eigene Spalte: beteiligt / Verdacht", d1.tag._text == "" and d2.tag._text == "beteiligt" and d3.tag._text == "Verdacht")
check("G5 Stempel VERDACHT nicht fuer Beteiligte", W.find(function(f) return f._kind == "Texture" and f._tex and f._tex:find("stamp_suspect") and f:IsVisible() end) == nil)
check("G14 zwei Knoepfe am Plakat, Streichen als Wort", W.btn("Rache vermerken") and W.btn("Begnadigen") and not W.find(function(f)
  return f.text and f.text._text == "Streichen" and f._bd and f:IsVisible() end) and W.text("Streichen", true))
W.step("G14 Streichen-Wort fragt nach", function()
  local s = W.find(function(f) return f.text and f.text._text == "Streichen" and not f._bd and f:IsVisible() end)
  s._scripts.OnClick(s, "LeftButton")
end)
check("G13 Rueckfrage mit Knopf Streichen", M.popups[#M.popups] and M.popups[#M.popups].which == "DEATHNOTE_DELETE"
      and G.StaticPopupDialogs.DEATHNOTE_DELETE.button1 == "Streichen")
check("G13 kein Rache +1 und kein Löschen mehr", not M.texts["Rache +1"] and not M.texts["Löschen"])
W.step("G13 Rechtsklick-Menue", function() W.click(W.row(function(i) return i.key == yac.key end), "RightButton") end)
check("G13 Menue: Rache vermerken, Begnadigen, Streichen", W.text("Rache vermerken", true) and W.find(function(f)
  return f.text and f.text._text == "Streichen" and f._bd and f:IsVisible() end) ~= nil)
G.DeathNoteMenu.blocker._scripts.OnClick(G.DeathNoteMenu.blocker)

------------------------------------------------------------------------
-- Pardoned at the end of Wanted, can be switched off (G28)
------------------------------------------------------------------------
local par = W.put(enemy(9, { name = "Gnaden", surname = "Brot", key = "Gnaden-Brot", status = "pardoned", kills = 9 }))
W.step("Begnadigte am Ende", function() ns:Fire("ENEMY_UPDATED", par.key); W.settle(); W.tab("wanted") end)
local rows = W.all(function(f) return f._kind == "Button" and f.item and f._shown and f.under end)
table.sort(rows, function(a, b) return a.index < b.index end)
check("IA begnadigt zuletzt, blass, durchgestrichen", rows[#rows].item == par and rows[#rows].strike:IsShown()
      and rows[#rows].name._tc[4] == ns.Look.TONE.hand and rows[#rows].rank._text == "")
check("IA Reiter Gesucht zaehlt nur Gesuchte", F.tabs[1].text._text == "Gesucht  3", F.tabs[1].text._text)
local sortB = W.find(function(f) return f.arrow and f._scripts.OnClick end)
check("G28 Sortierung als Wort mit Dreieck", sortB and sortB.text._text == "Rang" and sortB.arrow ~= nil)
W.step("G28 Hover unterstreicht, Klick oeffnet Liste", function() sortB._scripts.OnEnter(sortB); sortB._scripts.OnClick(sortB) end)
check("G28 Hover bewegt nichts: nur Unterstrich", sortB.ul:IsShown() and sortB._points[1][2] == -14)
check("G28 Menue mit Werten und Begnadigte ausblenden", W.text("• Rang", true) and W.text("Neueste", true) and W.text("Begnadigte ausblenden", true))
W.step("G28 Begnadigte ausblenden", function() W.click(W.btn("Begnadigte ausblenden")) end)
check("G28 ausgeblendet und gemerkt", not W.row(function(i) return i == par end) and ns.db.settings.ui.showPardoned == false)
ns.Store.Setting("ui.showPardoned", true); W.settle()
sortB._scripts.OnLeave(sortB)

------------------------------------------------------------------------
-- Unsolved (G2): cases without a killer and real suspicion cases, red count
------------------------------------------------------------------------
local sus = W.put(enemy(5, { name = "Vage", surname = "Sicht", key = "Vage-Sicht", status = "suspect", kills = 0, suspected = 1,
  deaths = { { t = NOW - 50, zone = "Brachland", role = "suspect", sure = false, source = "suspect" } } }))
ns.db.deaths = {
  { t = NOW - 10, zone = "Schlingendorntal", subzone = "Die ungezähmte Küste", kind = "pvp", me = "Davee", candidates = { yoron.key, yac.key, "Fremd-Ling" }, source = "suspect", counted = true, x = 24, y = 18 },
  { t = NOW - 20, zone = "Arathihochland", kind = "pvp", killerKey = yoron.key, killerName = "Yoron Pvp", sure = true, source = "recap", me = "Davee", counted = true },
  { t = NOW - 30, zone = "Strathholme", kind = "pvp", killerKey = yac.key, sure = true, counted = false },
}
W.step("Zu klaeren zaehlt", function() ns:Fire("DEATH_RECORDED", ns.db.deaths[1], nil); W.settle() end)
check("G2 Reiter Zu klären mit roter Zahl 2", F.tabs[2].text._text:find("Zu klären  |cff", 1, true) == 1 and F.tabs[2].text._text:find("2|r$") ~= nil, F.tabs[2].text._text)
check("G12 Meldung Täter unklar anklickbar", G.DeathNoteBanner._mouse == true and W.text("Klick: unter Zu klären den Täter festlegen", true))
-- scenario c: notice -> case -> candidate
W.step("c Klick auf die Meldung oeffnet den Fall", function() G.DeathNoteBanner._scripts.OnMouseUp(G.DeathNoteBanner, "LeftButton"); W.settle() end)
check("c Reiter Zu klären aktiv, Fall aufgeschlagen", F.tabs[2].mark:IsShown() and W.text("U N K L A R", true) and W.text("Todesfall", true))
check("G30 Karteikarte: Klebestreifen statt Reisszwecke", W.find(function(f) return f._kind == "Texture" and f._tex and f._tex:find("pin.tga") and f:IsVisible() end) == nil)
check("G19 Ort mit Koordinaten in Klammern, kein Etikett", W.text("Schlingendorntal, Die ungezähmte Küste (24, 18)", true) and not W.text("Koordinaten", true))
check("G19 Quelle nur bei Verdacht", W.text("Verdacht: hatte dich kurz vor dem Tod im Ziel.", true) and not W.text("Quelle:", true))
check("IA Zu klären: Fall und Verdacht, neueste zuerst", (function()
  local rs = W.all(function(f) return f._kind == "Button" and f.item and f._shown and f.under end)
  table.sort(rs, function(a, b) return a.index < b.index end)
  return #rs == 2 and rs[1].item == ns.db.deaths[1] and rs[1].name._text == "Täter unklar" and rs[2].item == sus and rs[2].rank._text == "?"
end)())
W.step("c Kandidat festlegen", function() W.click(W.btn("Yoron Pvp")) end)
check("c Fall geklaert, verlaesst die Liste", ns.db.deaths[1].killerKey == yoron.key and not W.row(function(i) return i == ns.db.deaths[1] end))
check("c danach der naechste offene Punkt gewaehlt", W.row(function(i) return i == sus end).under:IsShown())
check("G2 Zahl sinkt auf 1", F.tabs[2].text._text:find("1|r$") ~= nil, F.tabs[2].text._text)
check("G5 echter Verdacht: Stempel VERDACHT", W.find(function(f) return f._kind == "Texture" and f._tex and f._tex:find("stamp_suspect") and f:IsVisible() end) ~= nil)
W.step("Verdacht verwerfen", function() W.click(W.btn("Verwerfen")) end)
check("IA leer: Nichts zu klären. (ruhig, ohne Zahl)", W.text("Nichts zu klären.", true) and F.tabs[2].text._text == "Zu klären")

------------------------------------------------------------------------
-- death journal (G10, G11, G19)
------------------------------------------------------------------------
yoron.deaths[1].t = NOW - 20; yoron.deaths[1].others = { kug.key, "Weg-Weg" }
W.step("Journal", function() W.tab("journal") end)
local jr = W.row(function(i) return i == ns.db.deaths[2] end)
check("G10 Untertext: Zeitpunkt · genauester Ort", jr.sub._text:find("^%d%d%.%d%d%. %d%d:%d%d · Arathihochland$") ~= nil, jr.sub._text)
check("G10 ohne Marke reicht der Untertext bis 12 px an den Rand", jr.sub._points[2][2] == -12)
local jz = W.row(function(i) return i == ns.db.deaths[3] end)
check("G10 mit Marke Abstand nach Markenbreite", jz.mark._text == "ZÄHLT NICHT" and jz.sub._points[2][2] <= -70)
W.step("G19 Akte mit Beteiligten", function() W.click(jr) end)
check("G19 BETEILIGT mit Namen als Handschrift", W.text("B E T E I L I G T", true) and W.find(function(f) return f.key == kug.key and f.text and f:IsVisible() end))
check("G19 unbekannter Beteiligter nicht anklickbar", W.find(function(f) return f.text and f.text._text == "Weg-Weg" and f:IsVisible() end).key == nil)
W.step("G19 Klick auf Beteiligten schlaegt ihn auf", function() W.click(W.find(function(f) return f.key == kug.key and f.text and f:IsVisible() end)) end)
check("G19 Plakat Brenendan", F.tabs[1].mark:IsShown() and W.text("Brenendan Forever", true))
check("G19/G30 keine Aktennummer", not M.texts["A K T E   N r.  1"])

------------------------------------------------------------------------
-- Scenario b + G12: death -> message -> click opens the poster; the revenge message is not clickable
------------------------------------------------------------------------
F:Hide()
local neu = W.put(enemy(7, { name = "Neu", surname = "Ling", key = "Neu-Ling", kills = 1 }))
W.step("b Tod durch Neuen", function() ns:Fire("DEATH_RECORDED", { t = NOW, kind = "pvp", killerKey = neu.key, sure = true }, neu.key) end)
local B = G.DeathNoteBanner
check("b Meldung: steht jetzt im Buch, anklickbar", W.text("steht jetzt im Buch", true) and B._mouse == true)
W.step("G12 Hover: Tooltip statt Bewegung", function() B._scripts.OnEnter(B); B._scripts.OnLeave(B) end)
W.step("b Klick schlaegt auf", function() B._scripts.OnMouseUp(B, "LeftButton"); W.settle() end)
check("b Buch offen beim Plakat", F:IsShown() and W.row(function(i) return i == neu end).under:IsShown() and not B:IsShown())
W.step("G12 Rache-Meldung", function() ns:Fire("REVENGE", neu.key) end)
check("G12 Rache-Meldung nicht anklickbar (kann im Kampf kommen)", B:IsShown() and B._mouse == false)
W.step("G12 Rechtsklick ohne Wirkung bei Rache", function() B._scripts.OnMouseUp(B, "RightButton") end)
check("G12 bleibt stehen", B:IsShown())
M.FinishAnims()

------------------------------------------------------------------------
-- G15 + G32 + scenario j: minimap
------------------------------------------------------------------------
local mm = G.DeathNoteMinimapButton
W.step("G32 Tooltip", function() G.GameTooltip._lines = {}; mm._scripts.OnEnter(mm) end)
local function tipHas(s) for _, l in ipairs(G.GameTooltip._lines or {}) do if l:find(s, 1, true) then return true end end end
check("G32 Zeile gesucht", tipHas("4 gesucht"))
check("G32 Klick-Zeilen", tipHas("Klick: Buch · Rechtsklick: Hausordnung") and tipHas("Mittelklick: Alarm an/aus"))
W.step("j Mittelklick: Alarm aus", function() mm._scripts.OnClick(mm, "MiddleButton") end)
check("j alert.enabled aus, Symbol halb durchsichtig", ns.db.settings.alert.enabled == false and mm.icon._alpha == 0.45)
W.step("j Tooltip sagt es", function() G.GameTooltip._lines = {}; mm._scripts.OnEnter(mm) end)
check("j Zeile Alarm ist aus", tipHas("Alarm ist aus (Mittelklick)"))
M.Advance(300)
W.step("j kein Alarm, wenn aus", function() ns:Fire("ENEMY_SPOTTED", yac.key, nil, "nameplate") end)
check("j kein Popup", not (rawget(G, "DeathNoteAlert") and G.DeathNoteAlert:IsShown()))
W.step("j Compartment Mittelklick: wieder an", function() G.DeathNote_OnCompartmentClick("DeathNote", "MiddleButton") end)
check("j wieder an", ns.db.settings.alert.enabled == true and mm.icon._alpha == 1)
-- Scenario d + G20: killer shows up
W.step("d Taeter taucht auf", function() ns:Fire("ENEMY_SPOTTED", yac.key, nil, "nameplate") end)
local pop = G.DeathNoteAlert
check("d Popup mit Zahl und Beteiligung", pop:IsShown() and pop.line._text:find("^hat dich 2× getötet, war 1× beteiligt") ~= nil, pop.line._text)
check("G20 Kopf in hellem Rot auf Schwarz", pop.title._tc[1] == ns.Look.RED_ON_BLACK[1] and G.DeathNoteBanner.kicker._tc[1] == ns.Look.RED_ON_BLACK[1])
ns.Alert.Dismiss(); M.FinishAnims(); M.Advance(1)
-- G5: alarm threshold counts assists
ns.Store.Setting("alert.minKills", 3); M.Advance(300)
W.step("G5 Schwelle 3: Yoron (1 + 2) meldet", function() ns:Fire("ENEMY_SPOTTED", yoron.key, nil, "nameplate") end)
check("G5 Gewicht kills + assists", pop:IsShown() and pop.name._text == "Yoron Pvp")
ns.Alert.Dismiss(); M.FinishAnims(); M.Advance(300)
W.step("G5 Schwelle 3: Brenendan (0 + 1) still", function() ns:Fire("ENEMY_SPOTTED", kug.key, nil, "nameplate") end)
check("G5 unter der Schwelle kein Alarm", not pop:IsShown())
ns.Store.Setting("alert.minKills", 1)

------------------------------------------------------------------------
-- scenario e: add, note, pardon, revenge, remove
------------------------------------------------------------------------
W.step("e Eintragen ueber das Suchfeld", function()
  local sb = G.DeathNoteSearch
  sb:SetText("Zorngrimm Neuling"); sb._scripts.OnTextChanged(sb); sb._scripts.OnEnterPressed(sb); W.settle()
end)
local zk = "Zorngrimm Neuling-X"
check("e eingetragen und aufgeschlagen", ns.db.enemies[zk] and W.text("von Hand eingetragen", true))
W.step("e Rache vermerken", function() W.click(W.btn("Rache vermerken")) end)
check("e Rache gezaehlt", ns.db.enemies[zk].revenge == 1)
W.step("e Begnadigen", function() W.click(W.btn("Begnadigen")) end)
check("e begnadigt, bleibt im Reiter Gesucht", ns.db.enemies[zk].status == "pardoned" and F.tabs[1].mark:IsShown() and W.btn("Wieder jagen"))
W.step("e Streichen", function() UI.ConfirmDelete(zk); local p = M.popups[#M.popups]; G.StaticPopupDialogs[p.which].OnAccept(nil, p.data); W.settle() end)
check("e gestrichen", ns.db.enemies[zk] == nil)

------------------------------------------------------------------------
-- scenario f + G1 + G16: guild honest
------------------------------------------------------------------------
local GG = ns.MakeGuild(3, { noMembers = true })
GG.list[1].ownOnly = true; GG.list[1].victims = { Davee = 1 }; GG.list[1].lastVictim = "Davee"
W.step("f Gilde, niemand gehoert", function() ns:Fire("GUILD_UPDATED"); W.settle(); W.tab("guild") end)
check("G1 Reiterzahl: nur Eintraege mit Kollegen (Logik: Count, 4. Wert)", F.tabs[4].text._text == "Gilde  2", F.tabs[4].text._text)
check("G1 eigene Eintraege nicht als Gildenliste", not W.row(function(i) return i == GG.list[1] end))
check("G1 Statuszeile aus Health", W.text("Gesendet 4, empfangen 9.", true))
GG.list[2].ownOnly, GG.list[3].ownOnly = true, true
GG.list[2].victims, GG.list[3].victims = { Davee = 1 }, { Davee = 2 }
GG.Count = function() return 3, 6, 0, 0 end
W.step("f nur eigene Eintraege", function() ns:Fire("GUILD_UPDATED"); W.settle() end)
check("G1 Leerzustand: Noch niemand aus der Gilde gehoert", W.text("Noch niemand aus der Gilde gehört.", true)
      and W.text("Dein Buch geht raus, sobald ein Kollege DeathNote hat.", true) and F.tabs[4].text._text == "Gilde")
GG.health = { ok = false, reason = "off", text = "Teilen ist ausgeschaltet.", short = "Teilen ist aus" }
W.step("f Teilen aus: rot", function() ns:Fire("GUILD_UPDATED"); W.settle() end)
local st = W.text("Teilen ist ausgeschaltet.", true)
check("G1 rot, wenn ok == false", st and st._tc[1] == ns.Look.RED_INK[1])
W.step("G1 Abgleichen sagt die Wahrheit", function() W.click(W.btn("Abgleichen")) end)
check("G1 Knopf: Teilen ist aus statt Angefragt", W.btn("Teilen ist aus") ~= nil)
M.Advance(4)
GG.health = nil
W.step("G1 Abgleichen bei ok", function() W.click(W.btn("Abgleichen")) end)
check("G1 Knopf: Angefragt", W.btn("Angefragt") ~= nil)
M.Advance(4)
W.step("G1/G17 Hausordnung Gilde: nur Stand, kein Abgleichen", function()
  UI.OpenPanel("settings"); W.click(W.find(function(f) return f.page == 3 and f._scripts.OnClick end))
end)
check("G1 Stand in der Hausordnung aus Health, Abgleichen nur einmal (Fusszeile)", W.text("Gesendet 4, empfangen 9.", true) ~= nil
      and #W.all(function(f) return f.text and f.text._text == "Abgleichen" and f:IsVisible() end) == 1)
check("G17 Blaetter Buch, Alarm, Gilde", W.find(function(f) return f.page == 1 and f.text._text == "Buch" end)
      and W.find(function(f) return f.page == 2 and f.text._text == "Alarm" end))
check("G18 Gildenbuch leeren", W.btn("Gildenbuch leeren") ~= nil)
W.step("G17 Blatt Alarm", function() W.click(W.find(function(f) return f.page == 2 and f._scripts.OnClick end)) end)
check("G17 Meldung nach einem PvP-Tod beim Alarm", W.find(function(f) return f._kind == "CheckButton" and f.opt and f.opt.path == "deathMessage" and f:IsVisible() end))
check("G29 Abschnittswoerter als gesperrte Etiketten", W.text("T O N", true) and W.text("S C H W E L L E", true))
check("G29 Stepper ohne schwarze Kaestchen-Knoepfe", W.find(function(f) return f._bd and f.text and (f.text._text == "+" or f.text._text == "-" or f.text._text == "<") end) == nil)
-- Scenario h: quieter/other sound through the sound choice
W.step("G23 Blatt Buch", function() W.click(W.find(function(f) return f.page == 1 and f._scripts.OnClick end)) end)
check("G23 Sichern-Hinweis nennt Weitergeben", W.text("zum Weitergeben an Leute außerhalb der Gilde", true))
check("G23 Slash-Liste nicht mehr im Kleingedruckten", not W.text("/deathlist", true))
-- Scenario i: list to the outside
W.step("i Buch sichern", function() W.click(W.btn("Buch sichern")) end)
check("i Text markiert, Hinweis Weitergeben", W.text("Aufheben oder an Freunde weitergeben.", true))
UI.ClosePanel()
-- scenario g: Moppel's list
GG = ns.MakeGuild(6, { members = 3 })
W.step("g nach Kollege", function() ns:Fire("GUILD_UPDATED"); W.settle(); UI.SetGuildView("member"); W.settle() end)
check("G9 Kopf mit Vornamen, ganzer Name im Tooltip", (function()
  local r = W.row(function(i) return i.head and i.m.name == "Kollege2" end)
  return r and r.name._text == "Kollege2"
end)())
check("G18 Umschalter Nach Täter | Nach Kollege", W.text("Nach Täter", true) and W.text("Nach Kollege", true))
check("G33 Umschalter als Wort-Reiter", W.find(function(f) return f.view == "member" and f.mark and f.mark:IsShown() end))
UI.SetGuildView("enemy"); W.settle()
check("G9 Gildenzeile: zuletzt nur Vorname", (function()
  GG.list[1].lastVictim = "Varorak Narenmar"; ns:Fire("GUILD_UPDATED"); W.settle()
  local r = W.row(function(i) return i == GG.list[1] end)
  return r and r.sub._text:find("zuletzt Varorak$") ~= nil
end)())
W.step("G9 Meldung Gildentod mit Vornamen", function()
  M.FinishAnims()
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Hühnerbein Knusper" }, GG.list[1].key)
end)
check("G9 Meldung: Vorname", G.DeathNoteBanner.name._text == "Hühnerbein")
M.FinishAnims()

------------------------------------------------------------------------
-- G24/G25: size
------------------------------------------------------------------------
local W2 = world({ ui = { 1366, 768 }, ppu = 1 })
W2.ns.Store.Setting("ui.scale", 1.5)
W2.step("G24 UI 1,0: 150 % passt nicht", W2.open)
check("G24 Buch auf 130 % geklemmt (548*1,3 < 768)", W2.G.DeathNoteFrame._scale == 1.3, W2.G.DeathNoteFrame._scale)
check("G24 angebotene Stufen ohne 150 %", (function() for _, s in ipairs(W2.ns.UI.ScaleSteps()) do if s > 1.37 then return false end end return true end)())
check("G25 unter 100 % nur bei genug Bildpunkten (1 px/Einheit: keine)", W2.ns.UI.ScaleSteps()[1] == 1)
local W3 = world({ ui = { 2276, 1280 }, ppu = 1440 / 1280 })
W3.step("G25 erstes Oeffnen bei Autor (UI 0,6, 1440p)", W3.open)
check("G25 automatisch 130 % (1,125 px je Einheit)", W3.ns.db.settings.ui.scale == 1.3 and W3.G.DeathNoteFrame._scale == 1.3, W3.ns.db.settings.ui.scale)
check("G25 nur einmal", W3.ns.db.settings.ui.autoScale == true)
W3.ns.Store.Setting("ui.scale", 1); W3.G.DeathNoteFrame:Hide(); W3.open()
check("G25 eigene Wahl bleibt", W3.G.DeathNoteFrame._scale == 1)

------------------------------------------------------------------------
-- old logic without the new contract functions: nothing throws, fallbacks apply
------------------------------------------------------------------------
local O = world({ old = true })
O.ns.MakeGuild(4, { noHealth = true, noForeign = true })
O.put(enemy(1, { status = "wanted", kills = 2, assists = nil, deaths = { { t = NOW, zone = "X", sure = false, source = "recap" } } }))
O.ns.db.deaths = { { t = NOW, zone = "Ödland", kind = "pvp", candidates = { "Feind1-Nach1" } } }
local oldTag
O.step("alte Logik: alle Reiter", function()
  O.open()
  oldTag = O.find(function(f) return f.tag and f.tag._text == "Verdacht" and f:IsVisible() end) ~= nil
  for _, id in ipairs({ "wanted", "open", "journal", "guild" }) do O.tab(id) end
  O.ns.UI.SetGuildView("member"); O.settle()
  O.ns.UI.OpenPanel("settings"); for p = 1, 3 do O.click(O.find(function(f) return f.page == p and f._scripts.OnClick end)) end
  O.ns.UI.OpenPanel("help"); O.ns.UI.ClosePanel()
  O.ns:Fire("DEATH_RECORDED", O.ns.db.deaths[1], nil)
  O.G.DeathNoteMinimapButton._scripts.OnEnter(O.G.DeathNoteMinimapButton)
end)
check("alte Logik: offene Faelle selbst gezaehlt", O.G.DeathNoteFrame.tabs[2].text._text:find("1|r$") ~= nil, O.G.DeathNoteFrame.tabs[2].text._text)
check("alte Logik: Rolle aus sure (Verdacht)", oldTag)
check("alte Logik: Gildenstand ohne Health", O.text("Kollegen mit DeathNote gehört.") ~= nil)
check("alte Logik: Zeit ohne Util.When", O.text(os.date("%d.%m. %H:%M", NOW)) ~= nil)

------------------------------------------------------------------------
-- Guards: one test per rule that turns a deviation red
------------------------------------------------------------------------
local function readAll(p) local f = assert(io.open(p)); local s = f:read("*a"); f:close(); return s end
local files = { "Alert.lua", "UI.lua", "Extras.lua" }
local code = {}
for _, f in ipairs(files) do code[f] = readAll(SRC .. "/" .. f) end
-- User texts: all string literals outside comments plus everything set at run time
local literals = {}
for f, s in pairs(code) do
  for line in s:gmatch("[^\n]+") do
    local c = line:gsub("%-%-.*$", "")
    for lit in c:gmatch('"([^"]*)"') do literals[#literals + 1] = { f, lit } end
  end
end
for _, Wx in ipairs({ W, W2, W3, O }) do for t in pairs(Wx.M.texts) do literals[#literals + 1] = { "Laufzeit", t } end end
local BANNED = { "Notizbuch", "Fahndungsliste", "Gilden%-Todesliste", "Gildenliste", "Leute aus deiner Gilde", "Löschen",
                 "Rache %+1", "Gesuchte", "Mitglied", "Gildenfeind suchen", "Feind[^%a]", "Feinde", "Staatsfeind Nr", "GESUCHT:",
                 "Mittäter", "GILDENFAHNDUNG", "G I L D E N F A H N D U N G" }
local bad = {}
for _, x in ipairs(literals) do
  for _, b in ipairs(BANNED) do
    if x[2]:find(b) and not x[2]:find("^Feind%d") and not x[2]:find("Gilde%d+ Feind%d") then bad[#bad + 1] = x[1] .. ": " .. x[2] end
  end
end
check("Waechter Wortwahl (Buch, Gildenbuch, Täter, Kollege, Streichen)", #bad == 0, table.concat(bad, " | "))
-- Time: date() only in Look.When, no third time format in texts
local whenBody = code["Alert.lua"]:match("function Look%.When%(t%)(.-)\nend")
local dates = 0
for f, s in pairs(code) do
  for _ in s:gmatch("[^%w_%.]date%(") do dates = dates + 1 end
end
local inWhen = 0
for _ in (whenBody or ""):gmatch("[^%w_%.]date%(") do inWhen = inWhen + 1 end
check("Waechter Zeit: date() nur in Look.When", whenBody and dates == inWhen, dates .. " gesamt, " .. inWhen .. " in Look.When")
local oddTime = {}
for _, x in ipairs(literals) do
  if x[2]:find("%d%d%.%d%d%.%d%d, ") or x[2]:find(" Uhr") or x[2]:find("%d%d%.%d%d%.%d%d%d%d,") then oddTime[#oddTime + 1] = x[2] end
end
check("Waechter Zeit: keine Form ausser When/Ago in Texten", #oddTime == 0, table.concat(oddTime, " | "))
-- Font sizes only from the scale
local scale = {}
for _, s in ipairs(ns.Look.SIZE) do scale[s] = true end
local odd = {}
for _, Wx in ipairs({ W, W2, W3, O }) do for s in pairs(Wx.M.fontSizes or {}) do if not scale[s] then odd[#odd + 1] = s end end end
check("Waechter Schriftgrade nur aus Look.SIZE", #odd == 0, table.concat(odd, ","))
-- G33: bind functions return values, SetRow does the tones (no own alpha)
local binds = 0
-- fix-2: since the bundling (limit of 200 local names) the bind functions sit in the file as UX.BindXxx
for body in code["UI.lua"]:gmatch("\n[%w ]-function [%w%.]-Bind%w+%(.-\nend") do
  binds = binds + 1
  check("Waechter G33: kein SetAlpha in Bind-Funktion " .. (body:match("Bind%w+") or "?"), not body:find("SetAlpha%("))
end
check("Waechter G33: Bind-Funktionen gefunden", binds >= 6, binds)
check("Waechter G33: Unterzeilen mit Look.Join, kein doppelter Trenner", not code["UI.lua"]:find('"  ·  "', 1, true) and not code["Extras.lua"]:find('"  ·  "', 1, true))
-- Contrast: defined colour pairs against the averaged textures (centre of the writing area).
-- 1.3.0: for every registered theme (Theme.List): texture of the theme times its tint, colours of the theme.
local cache = {}
local function tga(file)
  if cache[file] then return cache[file] end
  local s = readAll(MEDIA .. "/" .. file)
  local w = s:byte(13) + s:byte(14) * 256
  local h = s:byte(15) + s:byte(16) * 256
  local off = 18 + s:byte(1)
  local r, g, b, n = 0, 0, 0, 0
  for y = math.floor(h * 0.25), math.floor(h * 0.75), 4 do
    for x = math.floor(w * 0.15), math.floor(w * 0.85), 4 do
      local i = off + (y * w + x) * 4
      b, g, r, n = b + s:byte(i + 1), g + s:byte(i + 2), r + s:byte(i + 3), n + 1
    end
  end
  cache[file] = { r / n / 255, g / n / 255, b / n / 255 }
  return cache[file]
end
local function lin(c) return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
local function L(c) return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3]) end
local function mix(fg, bg, a) return { fg[1] * a + bg[1] * (1 - a), fg[2] * a + bg[2] * (1 - a), fg[3] * a + bg[3] * (1 - a) } end
local function ratio(a, b) local x, y = L(a), L(b); return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05) end
local Th = ns.Theme
local themes = Th.List()
check("Waechter Kontrast: Themes registriert", #themes >= 1 and Th.Known("notebook"), table.concat(themes, ","))
for _, id in ipairs(themes) do
  local function col(role) return Th.Color(role, id) end
  local function tone(role) return Th.Pick(id, "tone", role) end
  -- texture of the theme times its tint (white = none)
  local function surface(key)
    local c, t = tga(Th.Pick(id, "tex", key)), Th.ParseColor(Th.Pick(id, "tint", key)) or { 1, 1, 1 }
    return { c[1] * t[1], c[2] * t[2], c[3] * t[3] }
  end
  local page, paper, cover = surface("page"), surface("paper"), surface("cover")
  local tf = col("tabFill")
  local tabbg = mix(tf, cover, tf[4] or 1)
  local bf = col("btnFill")
  local INK, RED, RED_INK, RED_ON_BLACK, BONE, TAB_OFF = col("ink"), col("accent"), col("accentSmall"), col("accentOnCover"), col("onCover"), col("tabOff")
  local PAIRS = {
    { "Tinte Untertext auf Seite", mix(INK, page, tone("sub")), page, 4.5 },
    { "Tinte Untertext auf Plakat", mix(INK, paper, tone("sub")), paper, 4.5 },
    { "Etikett auf Plakat", mix(INK, paper, tone("label")), paper, 4.5 },
    { "Hinweis auf Seite", mix(INK, page, tone("hint")), page, 4.5 },
    { "Rot klein auf Plakat", RED_INK, paper, 4.5 },
    { "Rot klein auf Seite", RED_INK, page, 4.5 },
    { "Rot gross auf Seite", RED, page, 3 },
    { "blasser Name (19 pt) auf Seite", mix(INK, page, tone("hand")), page, 3 },
    { "Rot auf Schwarz", RED_ON_BLACK, cover, 4.5 },
    { "Rot auf Reiter", RED_ON_BLACK, tabbg, 4.5 },
    { "Reiter inaktiv", TAB_OFF, tabbg, 4.5 },
    { "Knochenweiss auf Schwarz", BONE, cover, 4.5 },
    -- 1.3.0 (themes concept, test idea 2): text on an ink button and full ink on the page
    { "Schrift auf Knopf", BONE, mix(bf, page, bf[4] or 1), 4.5 },
    { "Tinte auf Seite", INK, page, 4.5 },
  }
  for _, p in ipairs(PAIRS) do
    local r = ratio(p[2], p[3])
    check(("Waechter Kontrast [%s] %s >= %.1f"):format(id, p[1], p[4]), r >= p[4], ("%.2f:1"):format(r))
  end
end

-- Final hunt 1.1.0: stamps sit on a layer ABOVE the wanted photo (child frames cover every region of
-- the parent frame in the client) and guild entries are named as in your own book.
do
  local W = world()
  W.put(enemy(1, { kills = 5 })); W.open(); W.ns.UI.ShowEnemy("Feind1-Nach1"); W.settle()
  local photoTex = W.find(function(f) return f._kind == "Texture" and type(f._tex) == "string" and f._tex:find("mugshot", 1, true) end)
  local n = 0
  for _, f in ipairs(W.M.frames) do
    if f._kind == "Texture" and type(f._tex) == "string" and f._tex:find("stamp_", 1, true) and photoTex
       and f._parent and f._parent._parent == photoTex._parent._parent then
      n = n + 1
      check("Stempel ueber dem Foto: " .. f._tex:match("stamp_%w+"), f._parent:GetFrameLevel() > photoTex._parent:GetFrameLevel(),
            f._parent:GetFrameLevel() .. " gegen " .. photoTex._parent:GetFrameLevel())
      check("Stempel-Ebene faengt keine Maus", not (f._parent.IsMouseEnabled and f._parent:IsMouseEnabled()))
    end
  end
  check("Stempel am Plakat gefunden", n >= 1, n)
end

-- Final hunt 1.1.0: after a click on the death message it is cleanly gone (Stop() does not fire OnFinished)
-- and a waiting guild message still gets its turn.
do
  local W = world()
  local ns, G = W.ns, W.G
  ns.MakeGuild(3)
  local e = W.put(enemy(7, { kills = 1 }))
  ns:Fire("DEATH_RECORDED", { t = NOW, kind = "pvp", sure = true, candidates = { e.key } }, e.key); W.settle()
  local b = rawget(G, "DeathNoteBanner")
  check("Todesmeldung steht", b and b:IsShown())
  ns:Fire("GUILD_KILL", { t = NOW, zone = "Ödland", victim = "Hühnerbein Knusper" }, ns.Guild.List("rank")[1].key); W.settle()
  check("Gilden-Meldung wartet", b.guild == false and b.key == e.key)
  b._scripts.OnMouseUp(b, "RightButton"); W.settle()
  check("Meldung nach Rechtsklick weg", not b:IsShown())
  check("Klick-Zustand geraeumt", b.open == nil and b.key == nil and not b:IsMouseEnabled())
  W.M.Advance(0.5); W.settle()
  check("wartende Gilden-Meldung erscheint", b:IsShown() and b.guild == true, tostring(b.guild))
  check("Gilden-Meldung faengt keine Maus", not b:IsMouseEnabled())
end

-- 1.2.0 languages: world in a given language (the stub reads DN_LANG while building)
local function worldIn(code, opts)
  local real = os.getenv
  os.getenv = function(k) if k == "DN_LANG" then return code end return real(k) end
  local ok, W = pcall(world, opts)
  os.getenv = real
  assert(ok, W)
  return W
end
local function L1(f) return f and f.GetLeft and f:GetLeft() end
local function R1(f) return f and f.GetRight and f:GetRight() end

-- Stretching tabs and switches: an artificially long language (German texts doubled) fits without overlap
do
  local W = worldIn("deDE")
  W.M.measure = true
  local Lx = W.ns.L
  for _, k in ipairs({ "TAB_WANTED", "TAB_UNSOLVED", "TAB_DEATHLOG", "TAB_GUILD", "SHEET_BOOK", "SHEET_ALERT", "SHEET_GUILD",
                       "VIEW_HUNT", "VIEW_BY_KILLER", "VIEW_BY_MATE", "SRC_ALL", "SRC_GUILD", "SRC_FRIENDS" }) do
    rawset(Lx, k, Lx[k] .. " " .. Lx[k])
  end
  W.ns.MakeGuild(3, { members = 2 })
  W.step("lange Sprache: Buch oeffnen", function() W.open() end)
  local tabs = W.all(function(f) return f._kind == "Button" and f.id and f.mark and f.text and f._parent == W.G.DeathNoteFrame end)
  table.sort(tabs, function(a, b) return L1(a) < L1(b) end)
  local Fx = W.G.DeathNoteFrame
  local ok, last = #tabs >= 4, nil
  for i, t in ipairs(tabs) do
    if last and L1(t) < R1(last) then ok = false end
    last = t
  end
  local helpBtn = W.find(function(f) return f._kind == "Button" and f.text and f.text._text == "?" end)
  check("Sprachen: lange Reiter ueberlappen sich nicht", ok, #tabs)
  check("Sprachen: lange Reiter enden vor dem \"?\"", last and helpBtn and R1(last) <= L1(helpBtn) - 4,
        last and helpBtn and (R1(last) .. " / " .. L1(helpBtn)))
  local widest = 0
  for _, t in ipairs(tabs) do widest = math.max(widest, t:GetWidth()) end
  check("Sprachen: Reiter wachsen mit dem Text", widest > 104, widest)
  W.tab("guild")
  local search = W.G.DeathNoteSearch
  local views = W.all(function(f) return f.view and f:IsVisible() end)
  local minL = 1e9
  for _, v in ipairs(views) do minL = math.min(minL, L1(v)) end
  check("Sprachen: lange Ansicht-Woerter ueberlappen das Suchfeld nicht", #views >= 2 and R1(search) <= minL,
        R1(search) .. " / " .. minL)
  check("Sprachen: Suchfeld behaelt 60 px", search:GetWidth() >= 60, search:GetWidth())
  W.ns.UI.OpenPanel("settings"); W.settle()
  local sheets = W.all(function(f) return f.page and f.text and f:IsVisible() end)
  table.sort(sheets, function(a, b) return a.page < b.page end)
  local sok, total = #sheets == 3, 0
  for i, sh in ipairs(sheets) do
    total = total + sh:GetWidth() + (i > 1 and 28 or 0)
    if sh:GetWidth() < math.min(96, sh.text:GetStringWidth() + 6) then sok = false end
    if i > 1 and not (sh._points[1][2] == sheets[i - 1] and sh._points[1][3] == "RIGHT") then sok = false end
  end
  check("Sprachen: Blaetter der Hausordnung so breit wie ihr Wort, aneinander gereiht", sok, #sheets)
  check("Sprachen: Blaetter passen auf die Seite (320 px)", total <= 320, total)
end

-- Stamps: German shows the image with burnt-in text, English the empty frame with text from the table
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = worldIn(code)
  W.put(enemy(1, { kills = 9, revenge = 2 })); W.put(enemy(2, { kills = 1 }))
  W.step(code .. " Stempel: Plakat Rang 1", function() W.open(); W.ns.UI.ShowEnemy("Feind1-Nach1"); W.settle() end)
  local nr1 = W.find(function(f) return f._kind == "Texture" and type(f._tex) == "string" and f._tex:find("stamp_nr1", 1, true) end)
  local rache = W.find(function(f) return f._kind == "Texture" and type(f._tex) == "string" and f._tex:find("stamp_rache", 1, true) end)
  if code == "deDE" then
    check("Stempel deDE: Bild mit Text", nr1 and not nr1._tex:find("_blank", 1, true) and nr1:IsVisible(), nr1 and nr1._tex)
    check("Stempel deDE: kein Schriftzug darueber", nr1 and nr1.label and not nr1.label:IsShown())
  else
    local lbl = nr1 and nr1.label
    check("Stempel enUS: leerer Rahmen", nr1 and nr1._tex:find("stamp_nr1_blank", 1, true) and nr1:IsVisible(), nr1 and nr1._tex)
    check("Stempel enUS: Text aus der Tabelle sichtbar", lbl and lbl:IsVisible() and lbl._text == W.ns.L.STAMP_NR1, lbl and lbl._text)
    check("Stempel enUS: Text gedreht wie der Rahmen", lbl and lbl._rot and math.abs(lbl._rot - math.rad(11)) < 1e-6, lbl and lbl._rot)
    check("Stempel enUS: Rache mit Text", rache and rache._tex:find("_blank", 1, true) and rache.label:IsVisible()
          and rache.label._text == W.ns.L.STAMP_REVENGE, rache and rache._tex)
    W.ns.UI.ShowEnemy("Feind2-Nach2"); W.settle()
    check("Stempel enUS: Text verschwindet mit dem Stempel", nr1 and not nr1:IsShown() and not nr1.label:IsShown())
  end
end

-- Language choice in the house rules: native name, stepping saves, hint and reload button only after a change
do
  local W = worldIn("deDE")
  rawset(W.G, "_G", W.G)           -- as in the game: Locale reads the SavedVariables through _G
  rawset(W.G, "DeathNoteDB", { settings = { lang = "deDE" } })   -- stored choice
  W.step("Sprachwahl: Hausordnung oeffnen", function() W.open(); W.ns.UI.OpenPanel("settings"); W.settle() end)
  local v = W.text("Deutsch", true)
  local reload = W.btn(W.ns.L.SET_LANG_RELOAD)
  check("Sprachwahl: zeigt die aktive Sprache in ihrem Namen", v ~= nil)
  check("Sprachwahl: ohne Wechsel kein Neuladen-Knopf", reload == nil)
  local plus = v and W.find(function(f) return f._kind == "Button" and f.tri and f._points[1] and f._points[1][2] == v end)
  W.step("Sprachwahl: weiterschalten", function() W.click(plus) end)
  check("Sprachwahl: gespeichert", W.ns.Locale.StoredChoice() == "enUS", tostring(W.ns.Locale.StoredChoice()))
  check("Sprachwahl: naechster Eigenname", W.text("English", true) ~= nil)
  check("Sprachwahl: Neuladen-Knopf bei Wechsel", W.btn(W.ns.L.SET_LANG_RELOAD) ~= nil)
end

print(("Gesamtschau UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
