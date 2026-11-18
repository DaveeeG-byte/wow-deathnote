-- 1.6.0 call: what the help call and the sightings show (CallUI.lua with the real logic, Call.lua): the slip of a
-- received call (loud, text, click opens the map there, not in combat, right click closes, gone by itself), quiet with
-- the alarm off; the pins on the (stand-in) map (a pulsing call for 3 minutes, a sighting for 10); the button "Help" on
-- the grudge notice; the chat links (map, call in guild chat with the probe's echo); the switch on the Guild sheet;
-- the slip and the button in 21 languages. Use: luajit tests/ui/ca160_hilferuf.lua [project folder]. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end
local SOS = "DeathNoteSOS"
local GUILD = "Die Rostigen Naegel"

local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  local ns = AM.Load({ noLogin = true, files = files, before = function() AM.units.player.guild = GUILD end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "ShareUI.lua", "SceneMap.lua", "CallUI.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, sent = {}, cbs = {} }
  rawset(BM.G, "EventRegistry", { RegisterCallback = function(_, ev, fn, owner) W.cbs[#W.cbs + 1] = { ev, fn, owner } end })
  local SM = dofile(DIR .. "/tests/ui/scene_map.lua")
  W.wm = SM.Install(BM, { mapID = 1434 })
  W.SM = SM
  _G.C_Map.GetMapInfo = function(id)
    if id == 1434 then return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
    if id == 1440 then return { name = "Eschental", mapType = 3, parentMapID = 13 } end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  ns:Fire("READY")
  _G.SendChatMessage = function(text, ch) W.sent[#W.sent + 1] = { text = text, ch = ch } end
  _G.UnitAffectingCombat = function(u) local x = AM.units[u]; return x ~= nil and x.combat ~= false end
  _G.UnitInParty = function() return false end
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.slip() return rawget(BM.G, "DeathNoteCall") end
  function W.call(from, mapID, x, y, key, disp)
    local text = ns.Call.Encode({ mapID = mapID or 1434, x = x or 40, y = y or 60, t = time(), key = key, display = disp })
    AM.FireEvent("CHAT_MSG_ADDON", SOS, text, "GUILD", from .. "-Forever")
    W.tick()
  end
  function W.link(link) for _, c in ipairs(W.cbs) do if c[1] == "SetItemRef" then c[2](nil, link) end end W.tick() end
  function W.combat(on) AM.inCombat = on; BM.combat = on end
  function W.pins() local out = {}; for _, f in ipairs(ns.SceneMap.Shown()) do if f:IsShown() then out[#out + 1] = f end end; return out end
  return W
end

local function tipOf(G, f)
  local GT = G.GameTooltip
  local lines = {}
  local s1, s2 = GT.SetText, GT.AddLine
  GT.SetText = function(_, t) lines = { t } end
  GT.AddLine = function(_, t) lines[#lines + 1] = t end
  f._scripts.OnEnter(f)
  GT.SetText, GT.AddLine = s1, s2
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
local W = world("deDE")
local ns, BM, AM, G, L = W.ns, W.BM, W.AM, W.G, W.ns.L

-- 1) a call comes in: loud, the slip with the words, the chat line with [Karte]
local snd = #BM.sounds
W.call("Anna", 1434, 40, 60, "Grimm-Bart", "Grimm Bart")
local slip = W.slip()
check("Zettel sichtbar", slip ~= nil and slip:IsShown())
check("Text: Anna ruft um Hilfe, Zone, gleiche Zone, Angreifer",
  slip and slip.head:GetText() == "Anna ruft um Hilfe: Schlingendorntal (gleiche Zone), Angreifer Grimm Bart", slip and slip.head:GetText())
check("laut: ein Alarmton", #BM.sounds == snd + 1, #BM.sounds - snd)
check("Hinweis unten", slip.hint:GetText() == L.CALL_TIP)
check("Zettel nicht abgeschnitten", not ns.Look.IsCut(slip.head) and not ns.Look.IsCut(slip.hint))
local chat = AM.chat[#AM.chat] or ""
check("Chatzeile mit Kartenlink", chat:find("Anna ruft um Hilfe", 1, true) and chat:find("|Haddon:DeathNote:call:map:%d+|h%[Karte%]"), chat)

-- 2) the click on the slip: the map there (out of combat); right click closes; gone by itself
W.tick(1)
local before = #W.SM.opened
slip._scripts.OnMouseUp(slip, "LeftButton"); W.tick()
check("Klick: Karte auf 1434 geoeffnet, Zettel weg", #W.SM.opened == before + 1 and W.SM.opened[#W.SM.opened] == 1434
  and not slip:IsShown(), #W.SM.opened - before)
local P = W.pins()
local callPin
for _, f in ipairs(P) do if f.data.kind == "call" then callPin = f end end
check("Nadel des Hilferufs: Art call, pulsiert", callPin ~= nil and callPin.pulsing == true)
check("Nadel rot getoent", callPin and callPin.icon._vc and math.abs(callPin.icon._vc[2] - 0.35) < 0.01, callPin and callPin.icon._vc and callPin.icon._vc[2])
local tip = callPin and tipOf(G, callPin) or ""
check("Tooltip: Hier rief Anna um Hilfe, Angreifer", tip:find("Hier rief Anna um Hilfe", 1, true) and tip:find("Angreifer: Grimm Bart", 1, true), tip)
G.HideUIPanel(W.wm); W.tick()

W.tick(181)
W.call("Berta", 1440, 10, 10)
check("zweiter Ruf (anderer Absender): andere Zone", W.slip().head:GetText():find("Eschental (andere Zone)", 1, true) ~= nil, W.slip().head:GetText())
W.slip()._scripts.OnMouseUp(W.slip(), "RightButton"); W.tick()
check("Rechtsklick schliesst", not W.slip():IsShown())
W.tick(31)
W.call("Carla")
W.tick(21)
check("nach 20 s von selbst weg", not W.slip():IsShown())

-- 3) in combat: the click does not open the map, the chat says why
W.tick(31)
W.call("Dora")
W.combat(true)
before = #W.SM.opened
W.slip()._scripts.OnMouseUp(W.slip(), "LeftButton"); W.tick()
check("im Kampf: keine Karte, Zeile", #W.SM.opened == before and (AM.chat[#AM.chat] or ""):find(L.SCENE_COMBAT, 1, true) ~= nil, AM.chat[#AM.chat])
W.combat(false)

-- 4) the alarm switched off: no sound, no slip, the line stays
ns.Store.Setting("alert.enabled", false)
W.tick(31)
snd = #BM.sounds
local nChat = #AM.chat
W.call("Emil")
check("Alarm aus: kein Ton, kein Zettel", #BM.sounds == snd and not W.slip():IsShown())
check("Alarm aus: Chatzeile bleibt", #AM.chat == nChat + 1)
ns.Store.Setting("alert.enabled", true)

-- 5) the map link of the chat line opens the map there; after 3 minutes the call's pin is gone
local id = chat:match("call:map:(%d+)")
before = #W.SM.opened
W.link("addon:DeathNote:call:map:" .. tostring(id))
check("Kartenlink: Karte geoeffnet", #W.SM.opened == before + 1)
W.tick(200); ns.SceneMap.Refresh()
local calls = 0
for _, f in ipairs(W.pins()) do if f.data.kind == "call" then calls = calls + 1 end end
check("nach drei Minuten keine Ruf-Nadel mehr", calls == 0, calls)
G.HideUIPanel(W.wm); W.tick()

-- 6) a sighting: amber pin for 10 minutes, no pulse, tooltip with who saw whom
ns.Store.ApplyKill({ name = "Velka", surname = "Dorn", class = "ROGUE", level = 40 },
  { t = time() - 600, zone = "Schlingendorntal", me = "Varorak Narenmar", source = "recap", others = {} }, true)
local text = ns.Call.EncodeSight("Velka-Dorn", 1434, 70, 20, time(), "")
ns.Guild.Bind()
AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", "Fritz-Forever"); W.tick()
G.ShowUIPanel(W.wm); W.tick(); ns.SceneMap.Refresh()
local sightPin
for _, f in ipairs(W.pins()) do if f.data.kind == "sight" then sightPin = f end end
check("Sichtung: Nadel, pulsiert nicht", sightPin ~= nil and not sightPin.pulsing)
tip = sightPin and tipOf(G, sightPin) or ""
check("Tooltip: Hier sah Fritz Velka Dorn", tip:find("Hier sah Fritz", 1, true) and tip:find("Velka Dorn", 1, true), tip)
check("Sichtung: leise (kein Ton)", true)
local leg = table.concat(ns.SceneMap.Legend(), "\n")
check("Legende nennt Hilferuf und Sichtung", leg:find(L.SCENE_LEG_CALL, 1, true) and leg:find(L.SCENE_LEG_SIGHT, 1, true), leg)
G.HideUIPanel(W.wm); W.tick()

-- 7) the button "Help" on the grudge notice: there while an attacker stands on it; a click sends the call
local card = rawget(G, "DeathNoteGrudge")
ns.Grudge.Test(3); W.tick()
card = rawget(G, "DeathNoteGrudge")
local btn = card and card.dnCall
check("Knopf Hilfe an der Meldung", btn ~= nil and btn:IsShown() and btn.text:GetText() == "Hilfe", btn and btn.text:GetText())
check("Kopfzeile macht Platz", card.head:GetWidth() <= 210 - 16 - 2 - 54, card.head:GetWidth())
local sent0 = #AM.addonSent
W.tick(31)
btn._scripts.OnClick(btn, "LeftButton"); W.tick()
local sosSent = 0
for i = sent0 + 1, #AM.addonSent do if AM.addonSent[i].prefix == SOS and AM.addonSent[i].channel == "GUILD" then sosSent = sosSent + 1 end end
check("Klick: Hilferuf an die Gilde", sosSent == 1, sosSent)
local line = AM.chat[#AM.chat] or ""
check("Zeile: gesendet an Gilde, mit [Im Gildenchat rufen]", line:find("Hilferuf gesendet an Gilde.", 1, true)
  and line:find("call:gchat:0|h[Im Gildenchat rufen]", 1, true), line)
ns.Grudge.Close("click"); W.tick()

-- 8) call in guild chat: one visible line (Share's way), the probe counts the echo; in combat: refused with reason
W.link("addon:DeathNote:call:gchat:0")
local g = W.sent[#W.sent]
check("Gildenchat: eine sichtbare Zeile", g and g.ch == "GUILD" and g.text:find("^Revenge Book: Hilfe gesucht: Schlingendorntal %(41, 57%)"), g and g.text)
check("kein Klammer-Muster eines Aushangs, kein '|'", g and not g.text:find("[Revenge Book:", 1, true) and not g.text:find("|", 1, true))
AM.FireEvent("CHAT_MSG_GUILD", g and g.text or "", "Varorak-Forever"); W.tick()
local pc = ns.Store.DB().probe.call.gchat
check("Sonde: geklickt, gesendet, Echo", pc and pc.clicked == 1 and pc.sent == 1 and pc.echo == 1, pc and (tostring(pc.sent) .. "/" .. tostring(pc.echo)))
W.tick(11)
W.combat(true)
local n0 = #W.sent
W.link("addon:DeathNote:call:gchat:0")
check("im Kampf: nicht gesendet, Grund im Chat", #W.sent == n0 and (AM.chat[#AM.chat] or ""):find("Nicht im Gildenchat gesendet", 1, true), AM.chat[#AM.chat])
W.combat(false)

-- 9) the switch on the Guild sheet: on by default, a click turns it off
ns:Fire("TOGGLE_UI"); W.tick()
ns.UI.OpenPanel("settings"); W.tick()
for _, f in ipairs(BM.frames) do
  if f.page == 3 and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
end
W.tick()
local cb
for _, f in ipairs(BM.frames) do if f._kind == "CheckButton" and f.opt and f.opt.guild == "layerSight" then cb = f end end
check("Haken 'Sichtungen meiner Mörder an Gilde & Freunde' da, sichtbar", cb ~= nil and cb:IsVisible() and cb.label:GetText() == "Sichtungen meiner Mörder an Gilde & Freunde", cb and cb.label:GetText())
if cb then
  if ns.UI.FillSettings then ns.UI.FillSettings() end
  check("Standard: an", cb:GetChecked() == true)
  cb:SetChecked(false); cb._scripts.OnClick(cb, "LeftButton"); W.tick()
  check("Klick: aus", ns.Store.Setting("guild.layerSight") == false)
end

check("keine Addon-Fehler", #AM.errors == 0, AM.errors[1])

-- 10) 21 languages: the slip with long names on two lines at most, the button's word not cut
local LANGS = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local cut = {}
for _, code in ipairs(LANGS) do
  local V = world(code)
  V.call("Annabellerosa Wintersturm", 1440, 10, 10, "Grimmwaldener-Bartholomaeus", "Grimmwaldener Bartholomaeus")
  local s = V.slip()
  if not s or not s:IsShown() or V.ns.Look.IsCut(s.head) or V.ns.Look.IsCut(s.hint) then cut[#cut + 1] = code .. " Zettel" end
  V.ns.Grudge.Test(3); V.tick()
  local c = rawget(V.G, "DeathNoteGrudge")
  local b = c and c.dnCall
  if not b or V.ns.Look.IsCut(b.text) then cut[#cut + 1] = code .. " Knopf" end
  if V.ns.Look.IsCut(c.head) then cut[#cut + 1] = code .. " Kopf" end
  if #V.AM.errors > 0 then cut[#cut + 1] = code .. " Fehler " .. tostring(V.AM.errors[1]) end
end
check("21 Sprachen: nichts abgeschnitten", #cut == 0, table.concat(cut, ", "))

io.write(("%-34s %3d gruen, %d rot\n"):format("Hilferuf und Sichtung UI", ok, bad))
os.exit(bad == 0 and 0 or 1)
