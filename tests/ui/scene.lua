-- 1.5.0 scene: crime scenes on the world map (SceneMap.lua on the stand-in map tests/ui/scene_map.lua) and the way
-- from the book to the map; the feud's chronicle on the poster. Real logic. All names are made up.
-- Call: luajit tests/ui/scene.lua [<project root>]
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local DIR = here .. "/../../DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local SM = dofile(here .. "/scene_map.lua")
local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "SceneMap.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local L, UI, S, Scene, Map = ns.L, ns.UI, ns.Store, ns.Scene, ns.SceneMap
local G = BM.G
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local function whisper(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz-Forever") end
BM.measure = true

-- the map comes up after the book (as a load-on-demand map would): attaching once, through the event
local wm = SM.Install(BM, { mapID = 1434 })
check("die Karte ist noch nicht angebunden", Map.Map() == nil)
ns:Fire("READY")
check("angebunden: zwei Haken an der Karte, Knopf da", Map.Map() == wm and SM.hooks == 2 and Map.Button() ~= nil, SM.hooks)
check("Sonde: Karte erkannt", Scene.ProbeSnapshot().attached == true and Scene.ProbeSnapshot().openWorldMap == true)

local NOW = time()
local ME = "Davee Wurst"
-- a death as Attribution writes it: journal entry and deed (x, y percent; nil = no spot)
local function death(name, surname, ago, x, y, opts)
  opts = opts or {}
  local t = NOW - ago
  local rec = { t = t, zone = opts.zone or "Schlingendorntal", subzone = opts.sub, mapID = opts.mapID == nil and 1434 or opts.mapID or nil,
    x = x, y = y, me = ME, spell = opts.spell, source = "recap", others = opts.others or {} }
  if opts.mapID == false then rec.mapID = nil end
  local key = name and S.ApplyKill({ name = name, surname = surname, class = opts.class or "ROGUE", level = 40,
    guid = "Player-1-" .. name .. surname }, rec, true)
  local j = { t = t, zone = rec.zone, subzone = rec.subzone, mapID = rec.mapID, x = x, y = y, me = ME, kind = "pvp",
    sure = key ~= nil, source = "recap", candidates = {}, spell = opts.spell, counted = true, killerKey = key,
    killerName = key and ns.Util.Display(S.Get(key)) or opts.killerName }
  S.RecordDeath(j)
  return key, j
end
local grimm, j1 = death("Grimm", "Bart", 3600, 40.2, 30.5, { spell = "Ausweiden", sub = "Grom'gol" })
death("Grimm", "Bart", 7200, 40.9, 30.9)                     -- the same spot: a bundle
death("Grimm", "Bart", 9000, 41.3, 31.4)
local velka = death("Velka", "Dorn", 5000, 70, 60, { class = "ROGUE" })
local _, jOld = death("Torvik", "Stein", 20 * 86400, 20, 70)   -- older than 7 days
local _, jNo = death("Osric", "Hall", 4000, nil, nil)          -- map ID only (position not readable)
local _, jNoMap = death("Brannoc", "Eich", 4500, nil, nil, { mapID = false })
local _, jUnclear = death(nil, nil, 3000, 80, 20, { killerName = nil })
tick(); settle()

local function openMap(id)
  G.ShowUIPanel(wm)
  if id then wm:SetMapID(id) end
  tick()
end
local function pins() local out = {}; for _, f in ipairs(Map.Shown()) do if f:IsShown() then out[#out + 1] = f end end; return out end
local function tipOf(f)
  local GT = G.GameTooltip
  local lines = {}
  GT.SetText = function(_, t) lines = { t } end
  GT.AddLine = function(_, t) lines[#lines + 1] = t end
  f._scripts.OnEnter(f)
  return table.concat(lines, "\n")
end
local function pinWith(n) for _, f in ipairs(pins()) do if f.data.count == n then return f end end end

openMap()
local P0 = pins()
-- Grimm bundle (3), Velka, Torvik (20 days: in 30), the unclear one = 4 pins; without spot: none
check("Nadeln: Buendel, Velka, Torvik, unklarer Tod (ohne Ort keine Nadel)", #P0 == 4, #P0)
local bundle = pinWith(3)
check("Buendel aus drei nahen Tatorten mit Zahl", bundle ~= nil and bundle.count:GetText() == "3" and bundle.badge:IsShown())
local t = bundle and tipOf(bundle) or ""
check("Buendel-Tooltip: Kopf und kurze Liste", t:find(L.SCENE_BUNDLE:gsub("{count}", "3"), 1, true) ~= nil and select(2, t:gsub("\n", "")) >= 4, t)
check("Buendel-Tooltip: voller Name, nie ein Schluessel", t:find("Grimm Bart", 1, true) ~= nil and not t:find("Grimm-Bart", 1, true), t)
local single
for _, f in ipairs(pins()) do if f.data.lead.key == velka then single = f end end
local ts = single and tipOf(single) or ""
check("Einzel-Tooltip: Hier hat <Taeter> dich getoetet (Klassenfarbe)", ts:find("Hier hat |cff", 1, true) ~= nil and ts:find("Velka Dorn", 1, true) ~= nil, ts)
check("Einzel-Tooltip: Zeit und Ort, Klick-Hinweis", ts:find("Schlingendorntal", 1, true) ~= nil and ts:find(L.SCENE_TIP_CLICK, 1, true) ~= nil, ts)
local unclear
for _, f in ipairs(pins()) do if f.data.lead.ref == jUnclear then unclear = f end end
check("unklarer Taeter: eigener Satz, kein Schluessel", unclear and tipOf(unclear):find(L.SCENE_TIP_DEATH_UNCLEAR, 1, true) ~= nil)
check("Bild der Nadel: roter Kopf mit Totenkopf", single and single.icon._tex:find("scene_death", 1, true) ~= nil)

-- the period, the switch, only open debts, kinds
S.Setting("scene.days", 7); tick()
check("7 Tage: der Tod von vor 20 Tagen faellt weg", #pins() == 3, #pins())
S.Setting("scene.days", 0); tick()
check("alle: wieder da", #pins() == 4)
S.Setting("scene.on", false); tick()
check("aus: keine Nadel, Knopf blass", #pins() == 0 and Map.Button().icon._desat == true)
S.Setting("scene.on", true); tick()
S.AddRevenge(velka, true); S.AddRevenge(velka, true); tick()
S.Setting("scene.open", true); tick()
check("nur offene Schulden: Velka (ueberzahlt) faellt weg", #pins() == 3 and ns.Ledger.State(velka) ~= "open", ns.Ledger.State(velka))
S.Setting("scene.open", false); S.Setting("scene.own", false); tick()
check("eigene aus: keine eigenen Nadeln", #pins() == 0)
S.Setting("scene.own", true); S.Setting("scene.days", 30); tick()

-- the map's switch
click(Map.Button())
local menu = Map.Menu()
check("Schalter an der Karte: sechs Zeilen", menu and menu:IsShown() and #menu.rows == 6)
check("Zeile Zeitraum nennt 30 Tage", vis(L.SCENE_DAYS_LINE:gsub("{days}", "30 Tage")) ~= nil)
click(menu.rows[2])
check("Klick auf Zeitraum: alle", Scene.Setting("days") == 0 and vis(L.SCENE_DAYS_LINE:gsub("{days}", L.SCENE_DAYS_ALL)) ~= nil, Scene.Setting("days"))
click(menu.rows[2])
check("weiter: 7 Tage", Scene.Setting("days") == 7)
click(menu.rows[2])
click(menu.rows[1])
check("Klick auf Tatorte: aus, Haken weg", Scene.Setting("on") == false and not menu.rows[1].check:IsShown())
click(menu.rows[1])
click(Map.Button())
check("Schalter zu", not menu:IsShown())

-- the book -> the map: deed line on the poster
G.HideUIPanel(wm); tick()
UI.ShowEnemy(grimm); tick(); settle()
local E
for _, f in ipairs(BM.frames) do if f.lines and f.chron then E = f end end
local line = E and E.lines[1]
check("Tat-Zeile mit Ort: kleine Nadel am Rand", line and line.place ~= nil and line.mapPin:IsShown())
local book = rawget(G, "DeathNoteFrame")
local n0 = #SM.opened
if line then click(line) end
check("Klick: Karte geht auf der Karte 1434 auf, das Buch weicht", #SM.opened == n0 + 1 and SM.opened[#SM.opened] == 1434
  and wm:IsShown() and not book:IsShown())
local lit
for _, f in ipairs(pins()) do if f.pulsing then lit = f end end
check("die Nadel pulsiert (Ring, Animationsgruppe)", lit ~= nil and lit.pulse:IsPlaying() and lit.data.count == 3)
tick(3)
check("nach drei Pulsen still", lit and not lit.pulsing)
-- the pin's click: back into the book
local _, jv = nil, nil
-- 1.5.0 fixer: a bundle (count 3) first shows the list of its scenes; a click on one opens it
if lit then lit._scripts.OnMouseUp(lit, "LeftButton"); tick() end
local pk = ns.SceneMap.Pick()
check("Klick auf das Buendel: Liste der Tatorte", pk ~= nil and pk:IsShown() and pk.rows[1]:IsShown())
if pk and pk.rows[1].item then pk.rows[1]._scripts.OnClick(pk.rows[1]); tick() end
check("Klick auf die Nadel: Karte zu, Buch auf", not wm:IsShown() and book:IsShown())

-- the death file: the place is a link
UI.ShowCase(j1); tick(); settle()
local hit
for _, f in ipairs(BM.frames) do if f.placeText and f:IsVisible() then hit = f end end
check("Todesakte: Ort anklickbar mit Nadel", hit ~= nil and hit.mapPin:IsShown())
n0 = #SM.opened
if hit then click(hit) end
check("Todesakte: Klick oeffnet die Karte", #SM.opened == n0 + 1)
-- without coordinates: the zone's map and the hint
G.HideUIPanel(wm); tick()
check("ohne Koordinaten: Karte der Zone, Hinweis", Map.Show(jNo, jNo) == "zone" and wm:IsShown() and vis(L.SCENE_NO_SPOT) ~= nil)
check("ohne Karten-ID: keine Karte, Zeile im Chat", Map.Show(jNoMap, jNoMap) == "nomap" and AM.chat[#AM.chat]:find(L.SCENE_NO_MAP, 1, true) ~= nil)
-- the attack deed (no pin of its own): the ring alone
G.HideUIPanel(wm); tick()
check("Ort ohne eigene Nadel: Ring an der Stelle", Map.Show({ mapID = 1434, x = 12, y = 12, t = 1 }) == "shown"
  and Map.Marker() and Map.Marker():IsShown())

-- combat: nothing opens, nothing is touched; afterwards the pins come
G.HideUIPanel(wm); tick()
BM.combat = true
local before = #SM.opened
check("im Kampf: nur eine Zeile, keine Karte", Map.Show(j1, j1) == "combat" and #SM.opened == before and not wm:IsShown()
  and AM.chat[#AM.chat]:find(L.SCENE_COMBAT, 1, true) ~= nil)
local d0 = Scene.counts.deferred
local shown0 = #pins()
wm:Show(); tick()
death("Grimm", "Bart", 60, 55, 55); ns:Fire("DEATH_RECORDED", {}, nil); tick()
check("im Kampf: Karte auf, neuer Tod wartet (keine Nadel angefasst)", Scene.counts.deferred == d0 + 1 and #pins() == shown0,
  Scene.counts.deferred - d0)
BM.combat = false
AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
local fresh
for _, f in ipairs(pins()) do if f.data.lead.t == NOW - 60 then fresh = f end end
check("nach dem Kampf: die Nadel ist da", fresh ~= nil)
check("keine Verstoesse (Schutz, Globale)", #BM.violations == 0, BM.violations[1])

-- a friend's death with its spot (message L): a quiet pin, fresh = pulsing; the friends' book line is a link
local P = ns.Guild.Proto
whisper(P.EncodeHello(0, "1.5.0"))
tick(2)
local kt = NOW - 120
whisper(P.EncodeKill({ key = "Rau-Bold", display = "Rau Bold", class = "WARRIOR", level = 40, zone = "Schlingendorntal",
  t = kt, victim = "Fritz Frei" }, "K"))
whisper(P.EncodePlace({ key = "Rau-Bold", t = kt, victim = "Fritz Frei", mapID = 1434, x = 25.5, y = 50.1 }))
tick(2)
local mate
for _, f in ipairs(pins()) do if f.data.lead.kind == "friend" then mate = f end end
check("Freund: eigene leisere Nadel (helles Bild, blau getoent)", mate ~= nil and mate.icon._tex:find("scene_friend", 1, true) ~= nil
  and mate.icon._vc and mate.icon._vc[3] > mate.icon._vc[1])
local tm = mate and tipOf(mate) or ""
check("Freund: Hier wurde <Freund> von <Taeter> getoetet, Freund, frisch", tm:find("Hier wurde Fritz Frei von", 1, true) ~= nil
  and tm:find("Rau Bold", 1, true) ~= nil and tm:find(L.SCENE_SRC_FRIEND, 1, true) ~= nil
  and tm:find(L.SCENE_FRESH:match("^[^{]*"), 1, true) ~= nil, tm)
check("frisch: pulsiert dauernd", mate and mate.pulsing and mate.pulse:IsPlaying())
tick(Scene.FRESH); G.HideUIPanel(wm); tick(); G.ShowUIPanel(wm); tick()
for _, f in ipairs(pins()) do if f.data.lead.kind == "friend" then mate = f end end
check("nach 10 Minuten: still", mate and not mate.pulsing)
S.Setting("scene.friends", false); tick()
local anyFriend = false
for _, f in ipairs(pins()) do if f.data.lead.kind == "friend" then anyFriend = true end end
check("Freunde aus: Nadel weg", not anyFriend)
S.Setting("scene.friends", true); tick()

-- the chronicle on the poster
G.HideUIPanel(wm); tick()
UI.ShowEnemy(grimm); tick(); settle()
check("Plakat: Wort Chronik", E.chron:IsShown() and E.chron.text._text == L.CHRON_OPEN)
click(E.chron); settle()
check("Chronik: Karte statt Plakat", not E:IsShown() and vis(L.CHRON_HEAD) ~= nil)
check("Chronik: erste Begegnung", vis(L.CHRON_FIRST:match("^[^{]*")) ~= nil)
check("Chronik: Schlusszeile mit Stand", vis(L.CHRON_END:match("^[^{]*")) ~= nil)
local cl
for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.place and f:IsVisible() and f.text and f.text._text:find("Ausweiden", 1, true) then cl = f end end
check("Chronik: Ort anklickbar", cl ~= nil and cl.mapPin:IsShown())
UI.Refresh(); tick()
check("Chronik bleibt bei einer Auffrischung offen", not E:IsShown() and vis(L.CHRON_HEAD) ~= nil)
local back
for _, f in ipairs(BM.frames) do if f.text and f.text._text == L.CHRON_BACK and f:IsVisible() and f._scripts.OnClick then back = f end end
if back then click(back) end
check("Zum Plakat: Plakat wieder da", E:IsShown())
UI.ShowEnemy(velka); tick()
check("anderer Eintrag: Chronik zu", E:IsShown())

-- 60 scenes far apart on one map: at most Scene.MAX_PINS pins
for i = 1, 60 do death("Masse", "Nr" .. i, 100 + i, (i % 10) * 9 + 4, math.floor(i / 10) * 14 + 5) end
G.ShowUIPanel(wm); tick()
check("Obergrenze: hoechstens " .. Scene.MAX_PINS .. " Nadeln je Karte", #pins() == Scene.MAX_PINS, #pins())

check("keine Fehler", #AM.errors == 0, AM.errors[1])
check("keine Verstoesse", #BM.violations == 0, BM.violations[1])
print(("Tatort und Chronik UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
