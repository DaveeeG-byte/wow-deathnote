-- 1.2.0 (fix-1): Oberflaeche der Funde und Wuensche nach der Fehlerjagd, mit der echten Logik.
-- W2 Stufe im Alarm (hoeher, gleich, niedriger, unbekannt, Totenkopf, Secret, Popup-Masse, kein Aufruf im
-- heissen Pfad); Zeile der Abschussliste (Fund 13: Stufe, Freigebende, Grund, seit, gesehen, Erlegt,
-- Tooltip, 0/1/40 Ziele, lange Namen); Fuer mich ausblenden (Fund 12); Alle meine abblasen (W1);
-- Meldung neuer Ziele (Fund 6); Freundesbuch leeren (Fund 12); Abgleichen-Knopf waechst (Rest Sprach-Bau).
-- Laeuft auf Deutsch (der Mock waehlt deDE). Alle Namen sind erfunden.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local DIR = here .. "/../../DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
local function clean(name)
  check(name .. ": keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  check(name .. ": keine Verstoesse", #BM.violations == 0, BM.violations[#BM.violations])
  AM.errors = {}; for i = #BM.violations, 1, -1 do BM.violations[i] = nil end
end

local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  AM.units.player.guild = "Die Testgilde"
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
local L = ns.L

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function quiet() for _ = 1, 4 do settle(); BM.Advance(120); AM.Advance(120) end end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function word(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function rows()
  local out = {}
  for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under then out[#out + 1] = f end end
  table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
  return out
end
local function guildMsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local P = ns.Guild.Proto
tick(30); settle()
-- nach dem eigenen Hallo: die Antwort-Minute ist vorbei, Freigaben sind ab jetzt "live"
AM.Advance(120)

------------------------------------------------------------------------
-- W2: Stufe im Alarm
------------------------------------------------------------------------
local popup
local function sehen(name, surname, guid, lvl)
  quiet()
  AM.units.mouseover = nil
  BM.levels.mouseover = lvl
  AM.AddEnemy("mouseover", { name = name, surname = surname, guid = guid, level = type(lvl) == "number" and lvl or 40 })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  popup = rawget(G, "DeathNoteAlert")
  return popup and popup:IsShown() and (popup.name._text or ""):find(name, 1, true) ~= nil
end
BM.levels.player = 40
local k1 = ns.Store.AddManual("Hoch", "Drueber")
check("Alarm fuer den eigenen Gesuchten (hoeher)", sehen("Hoch", "Drueber", "Player-1-HD", 43))
-- fix-3: keine eigene Warnzeile mehr; die Stufe selbst traegt den Abstand und steht in Warnfarbe
local function warnInk(fs) return fs._tc and fs._tc[1] == 1 and fs._tc[3] < 0.3 end
-- 1.2.2: the level leads the text line (in its colour) instead of standing right of the name; Lvl() reads it back
local function Lvl()
  local t = popup.levelText or ""
  local lead = (popup.line._text or ""):match("^|cff%x%x%x%x%x%x(.-)|r · ")
  return { _text = (lead == t) and t or ("<line: " .. tostring(lead) .. ">"), _tc = popup.levelWarn and { 1, 0.62, 0.18 } or { 0.93, 0.9, 0.82 } }
end
check("Stufe rechts neben dem Namen, mit Abstand", Lvl()._text == "Stufe 43 (+3)", Lvl()._text)
check("Stufe in Warnfarbe", warnInk(Lvl()))
check("keine Warnzeile", popup.warn == nil)
check("Popup so hoch wie vorher (108), Zeile zweizeilig", popup:GetHeight() == 108 and popup.line._maxl == 2,
      tostring(popup:GetHeight()) .. " / " .. tostring(popup.line._maxl))
check("Name has the whole width (level moved into the text line)", #popup.name._points == 1 and popup.name._w == 384 - 86 - 12)
ns.Store.Remove(k1)

local k2 = ns.Store.AddManual("Eins", "Mehr")
check("Alarm (eine Stufe hoeher)", sehen("Eins", "Mehr", "Player-1-EM", 41))
check("eine hoeher: Stufe 41 (+1) in Warnfarbe", Lvl()._text == "Stufe 41 (+1)" and warnInk(Lvl()), Lvl()._text)
ns.Store.Remove(k2)

local k3 = ns.Store.AddManual("Gleich", "Auf")
check("Alarm (gleich)", sehen("Gleich", "Auf", "Player-1-GA", 40))
check("gleich: Stufe ohne Abstand, nicht in Warnfarbe, Zeile zweizeilig", Lvl()._text == "Stufe 40" and not warnInk(Lvl())
      and popup.line._maxl == 2, tostring(Lvl()._text))
ns.Store.Remove(k3)

local k4 = ns.Store.AddManual("Klein", "Drunter")
check("Alarm (niedriger)", sehen("Klein", "Drunter", "Player-1-KD", 22))
check("niedriger: nicht in Warnfarbe", Lvl()._text == "Stufe 22" and not warnInk(Lvl()))
ns.Store.Remove(k4)

local k5 = ns.Store.AddManual("Toten", "Kopf")
check("Alarm (Totenkopf)", sehen("Toten", "Kopf", "Player-1-TK", -1))
check("Totenkopf: Stufe ?? in Warnfarbe", Lvl()._text == "Stufe ??" and warnInk(Lvl()), tostring(Lvl()._text))
ns.Store.Remove(k5)

local k6 = ns.Store.AddManual("Kein", "Wert")
check("Alarm (keine Stufe vom Client)", sehen("Kein", "Wert", "Player-1-KW", false))
check("kein Wert: Stufe ?? in Warnfarbe", Lvl()._text == "Stufe ??" and warnInk(Lvl()), Lvl()._text)
ns.Store.Remove(k6)

-- Secret: erst pruefen, dann vergleichen; ersatzweise die gespeicherte Stufe ("zuletzt")
local k7 = ns.Store.AddManual("Geheim", "Wert")
-- wie im Client: type() meldet "number", jeder Vergleich wirft; beide Mocks kennen ihn als Secret
local secretLevel = AM.Secret("level", "number")
BM.secrets[secretLevel] = true
BM.levelFn = function(u) if u == "player" then return 40 end return secretLevel end
quiet()
AM.units.mouseover = nil
AM.AddEnemy("mouseover", { name = "Geheim", surname = "Wert", guid = "Player-1-GW", level = 47 })
local e7 = ns.Store.Get(k7)
AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
popup = rawget(G, "DeathNoteAlert")
check("Secret: Alarm ohne Fehler", popup:IsShown() and #AM.errors == 0, AM.errors[1])
check("Secret: gespeicherte Stufe als zuletzt", e7.level == nil or (Lvl()._text or ""):find("^zuletzt Stufe " .. tostring(e7.level)) ~= nil,
      tostring(Lvl()._text) .. " / " .. tostring(e7.level))
BM.levelFn = nil
AM.errors = {}
ns.Store.Remove(k7)

-- unbekannt: Ziel der Abschussliste ohne Stufe und ohne Einheit
guildMsg(P.EncodeHunt({ key = "Ohne-Stufe", display = "Ohne Stufe", t = time(), by = "Kollege Wurst", why = "x" }))
tick(1); quiet()
ns:Fire("GUILD_ENEMY_SPOTTED", "Ohne-Stufe", nil, "other", "hunt"); tick()
popup = rawget(G, "DeathNoteAlert")
check("unbekannt: Alarm ohne Stufe", popup:IsShown() and popup.levelText == nil and not (popup.line._text or ""):find("^|c"), tostring(popup.levelText))
-- gespeicherte Stufe ohne Einheit: "zuletzt"
guildMsg(P.EncodeHunt({ key = "Mit-Stufe", display = "Mit Stufe", level = 44, t = time(), by = "Kollege Wurst", why = "x" }))
tick(1); quiet()
ns:Fire("GUILD_ENEMY_SPOTTED", "Mit-Stufe", nil, "other", "hunt"); tick()
check("ohne Einheit: zuletzt Stufe 44 (+4) in Warnfarbe", Lvl()._text == "zuletzt Stufe 44 (+4)" and warnInk(Lvl()),
      tostring(Lvl()._text))
clean("W2 Stufe im Alarm")

-- kein Aufruf im heissen Pfad: Namensplakette eines Feindes ohne Alarm fragt keine Stufe
quiet()
local calls = 0
BM.levelFn = function(u) calls = calls + 1; return 40 end
AM.units.nameplate1 = nil
AM.AddEnemy("nameplate1", { name = "Fremd", surname = "Niemand", guid = "Player-1-FN" })
for _ = 1, 50 do ns.Tracker.OnUnit("nameplate1", "nameplate") end
check("Plakette ohne Alarm: kein UnitLevel aus dem Alarm", calls == 0, calls)
BM.levelFn = nil

------------------------------------------------------------------------
-- Fund 13: Zeile der Abschussliste
------------------------------------------------------------------------
quiet()
ns:Fire("TOGGLE_UI"); tick(1); settle()
local tab = frameWith(function(f) return f.id == "guild" and f._scripts.OnClick end)
click(tab)
local VIEWS = frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)
local SRCS = frameWith(function(f) return f.items and f.items[1] and f.items[1].src end)
VIEWS.items[3]._scripts.OnClick(VIEWS.items[3]); tick()
ns.Guild.Hunt("Mit-Stufe", "all").lastSeen = { t = time() - 300, zone = "Z", by = "Kollege" }
ns.Guild.DB().lists["Die Testgilde"].hunts["Mit-Stufe"].lastSeen = { t = time() - 300, zone = "Z", by = "Kollege" }
ns.Guild.Proto.BagHunt(ns.Guild.DB().lists["Die Testgilde"].hunts, "Mit-Stufe", "Kollege Wurst", time() - 60)
ns.Guild.Bridge.updated(); tick(1); ns.UI.Refresh()
local row
for _, r in ipairs(rows()) do if r.item.key == "Mit-Stufe" then row = r end end
check("Zeile Mit Stufe da", row ~= nil)
if row then
  local sub = row.sub._text or ""
  -- fix-3: drei Angaben: wer, Grund, gesehen bzw. seit wann (Stufe und Zahl am Plakat und im Tooltip)
  check("Zeile: drei Angaben, wer zuerst", sub:find("^Kollege · x · gesehen ") ~= nil, sub)
  check("Zeile: keine Stufe, kein Wort Freigabe", sub:find("Stufe", 1, true) == nil and sub:find("Freigabe", 1, true) == nil, sub)
  check("Zeile: Erlegt rechts", (row.mark._text or ""):find("ERLEGT", 1, true) ~= nil, row.mark._text)
  check("Zeile zweizeilig: Name oben, Rest unten, ohne Umbruch", row.sub._wrap == false and row.name._wrap == false)
  local tip = row.tipFn and row.tipFn(row.item)
  check("Tooltip mit allem (erst beim Zeigen gebaut)", type(tip) == "table" and #tip >= 5 and row.full == nil, type(tip) == "table" and #tip)
end
-- langer Grund: in der Zeile gekuerzt, im Tooltip ganz
local long = string.rep("Lang ", 12)
guildMsg(P.EncodeHunt({ key = "Lang-Grund", display = "Lang Grund", level = 30, t = time(), by = "Kollege Wurst", why = long }))
tick(1); ns.UI.Refresh()
for _, r in ipairs(rows()) do if r.item.key == "Lang-Grund" then row = r end end
local fullWhy = ns.Guild.Hunt("Lang-Grund", "all").why
local inTip = false
for _, l in ipairs(row.tipFn and row.tipFn(row.item) or {}) do if l:find(fullWhy, 1, true) then inTip = true end end
check("langer Grund ganz im Tooltip", inTip)
check("langer Grund in der Zeile gekuerzt (…)", (row.sub._text or ""):find("Lang Lang Lang Lang Lang…", 1, true) ~= nil
      and not (row.sub._text or ""):find(fullWhy, 1, true), row.sub._text)
check("Untertext endet vor der Marke bzw. dem Rand", row.sub._points[2] and row.sub._points[2][1] == "RIGHT"
      and row.sub._points[2][2] <= -12, row.sub._points[2] and row.sub._points[2][2])
clean("Zeile der Abschussliste")

------------------------------------------------------------------------
-- Fund 12: Fuer mich ausblenden (Plakat), blass am Ende, kein Alarm, rueckholbar
------------------------------------------------------------------------
for _, r in ipairs(rows()) do if r.item.key == "Mit-Stufe" then row = r end end
click(row)
-- fix-3: am Plakat der Abschussliste steht der Stempel auf dem Foto, darunter kein Wort; die Aktion im Zeilenmenue
check("kein Wort unter dem Stempel", word("Für mich ausblenden") == nil)
click(row, "RightButton")
local hide = word("Für mich ausblenden")
check("Zeilenmenue: Fuer mich ausblenden", hide ~= nil)
if hide then click(hide) end
check("ausgeblendet", ns.Guild.HuntHidden("Mit-Stufe") == true)
ns.UI.Refresh()
local rs = rows()
check("blass am Ende der Liste", rs[#rs].item.key == "Mit-Stufe" and (rs[#rs].sub._text or ""):find("ausgeblendet", 1, true) ~= nil,
      rs[#rs].item.key)
quiet()
local before = #AM.Fired("GUILD_ENEMY_SPOTTED")
ns.Guild.OnUnit("Mit-Stufe", "nameplate1", "nameplate", false)
check("ausgeblendet: kein Alarm", #AM.Fired("GUILD_ENEMY_SPOTTED") == before)
for _, r in ipairs(rows()) do if r.item.key == "Mit-Stufe" then row = r end end
click(row, "RightButton")
local show = word("Wieder einblenden")
check("Zeilenmenue jetzt: Wieder einblenden", show ~= nil)
if show then click(show) end
check("wieder da", ns.Guild.HuntHidden("Mit-Stufe") == false)
local sentBefore = #AM.addonSent
check("nichts gesendet", #AM.addonSent == sentBefore)
clean("Ausblenden")

------------------------------------------------------------------------
-- W1: Alle meine Freigaben abblasen (Menue der Abschussliste, mit Rueckfrage, ueber die Schlange)
------------------------------------------------------------------------
ns.Guild.Release("Frei-Eins", { to = "all", why = "a" })
ns.Guild.Release("Frei-Zwei", { to = "guild" })
tick(5); ns.UI.Refresh()
check("zwei eigene Freigaben", ns.Guild.OwnReleaseCount() == 2, ns.Guild.OwnReleaseCount())
-- fix-3: im Zeilenmenue einer eigenen Freigabe (der Sortierknopf ist in der Abschussliste nicht zu sehen)
local sortB = frameWith(function(f) return f.arrow and f.ul and f.text and f._scripts.OnClick end)
check("kein Sortierknopf in der Abschussliste", not sortB:IsVisible())
local own
for _, r in ipairs(rows()) do if r.item.key == "Frei-Eins" then own = r end end
check("eigene Freigabe in der Liste", own ~= nil)
click(own, "RightButton")
local menuItem = word("Alle meine abblasen")
check("Zeilenmenue der eigenen Freigabe: Alle meine abblasen", menuItem ~= nil)
local shown
local showPopup = G.StaticPopup_Show
G.StaticPopup_Show = function(which, ...) shown = which; return showPopup(which, ...) end
if menuItem then click(menuItem) end
check("Rueckfrage", shown == "DEATHNOTE_CALLOFF_ALL", shown)
local dlg = G.StaticPopupDialogs.DEATHNOTE_CALLOFF_ALL
check("Rueckfrage-Text", dlg and dlg.text:find("Alle deine Freigaben abblasen", 1, true) ~= nil and dlg.button1 == "Alle abblasen")
local a0 = #AM.addonSent
if dlg then dlg.OnAccept() end
tick(10)
check("alle eigenen abgeblasen", ns.Guild.OwnReleaseCount() == 0 and not ns.Guild.Hunt("Frei-Eins", "all"))
local aMsgs = 0
for i = a0 + 1, #AM.addonSent do if AM.addonSent[i].text:match("^1\tA\t") then aMsgs = aMsgs + 1 end end
check("Abblasen gesendet (Gilde)", aMsgs >= 2, aMsgs)
G.StaticPopup_Show = showPopup
local other
for _, r in ipairs(rows()) do if not ns.Guild.Released(r.item.key) then other = r end end
if other then click(other, "RightButton") end
check("ohne eigene Freigaben kein Menuepunkt", other ~= nil and word("Alle meine abblasen") == nil)
-- eine einzige eigene Freigabe: der Punkt fehlt (Jagd abblasen reicht)
ns.Guild.Release("Frei-Eins", { to = "guild" }); tick(5); ns.UI.Refresh()
for _, r in ipairs(rows()) do if r.item.key == "Frei-Eins" then own = r end end
click(own, "RightButton")
check("eine eigene Freigabe: kein Alle abblasen", word("Jagd abblasen") ~= nil and word("Alle meine abblasen") == nil)
ns.Guild.CallOff("Frei-Eins"); tick(5)
tick(); settle()
clean("Alle abblasen")

------------------------------------------------------------------------
-- Fund 6: neue Ziele anderer, eine Meldung fuer mehrere
------------------------------------------------------------------------
-- fix-3: eine Chatzeile statt eines Fensters; ist das Ziel gerade in Sicht, der normale Alarm
quiet()
if rawget(G, "DeathNoteBanner") then rawget(G, "DeathNoteBanner"):Hide() end
local function chatSince(n) local t = {} for i = n + 1, #AM.chat do t[#t + 1] = AM.chat[i] end return t end
local c0 = #AM.chat
guildMsg(P.EncodeHunt({ key = "Neu-Eins", display = "Neu Eins", t = time(), by = "Kollege Wurst", why = "Grund eins" }))
tick(10)
local bn = rawget(G, "DeathNoteBanner")
local lines = chatSince(c0)
check("ein neues Ziel: kein Fenster", not (bn and bn:IsShown()))
check("ein neues Ziel: eine Chatzeile mit Name, wer, Grund", #lines == 1 and lines[1]:find("Neu Eins · freigegeben von Kollege · Grund eins", 1, true) ~= nil,
      lines[1])
c0 = #AM.chat
for i, k in ipairs({ "Neu-Zwei", "Neu-Drei", "Neu-Vier" }) do
  guildMsg(P.EncodeHunt({ key = k, t = time(), by = "Anna Blume", why = "x" }), "Anna-Forever")
end
tick(10)
lines = chatSince(c0)
check("drei neue Ziele: eine Chatzeile", #lines == 1 and lines[1]:find("3 neue Ziele · neu auf der Abschussliste", 1, true) ~= nil, lines[1])
check("drei neue Ziele: kein Fenster", not (bn and bn:IsShown()))
-- in Sicht: der normale Alarm, keine Chatzeile
quiet()
AM.units.mouseover = nil
AM.AddEnemy("mouseover", { name = "Neu", surname = "Sicht", guid = "Player-1-NS", level = 40 })
c0 = #AM.chat
guildMsg(P.EncodeHunt({ key = "Neu-Sicht", display = "Neu Sicht", t = time(), by = "Kollege Wurst", why = "da" }))
tick(10)
popup = rawget(G, "DeathNoteAlert")
check("in Sicht: Alarm fuer das neue Ziel (gezeigt oder wartend)", ns.Alert.Shows("Neu-Sicht"))
check("in Sicht: keine Chatzeile", #chatSince(c0) == 0, chatSince(c0)[1])
quiet()
c0 = #AM.chat
ns.Store.Setting("guild.announceHunt", false)
guildMsg(P.EncodeHunt({ key = "Neu-Fuenf", t = time(), by = "Anna Blume", why = "x" }), "Anna-Forever")
tick(10)
check("Schalter aus: keine Meldung", not (bn and bn:IsShown()) and #chatSince(c0) == 0)
ns.Store.Setting("guild.announceHunt", true)
clean("Neue Ziele")

------------------------------------------------------------------------
-- Fund 12: Freundesbuch leeren (mit Rueckfrage), eigene Freigaben bleiben
------------------------------------------------------------------------
AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHunt({ key = "Freund-Ziel", t = time(), by = "Fritz Frei", why = "f" }),
  "WHISPER", "Fritz-Forever")
ns.Guild.Release("Mein-Ziel", { to = "friends" })
tick(2)
check("Vorbedingung: zwei Ziele im Freundesbuch", ns.Guild.HuntCount("friends") == 2, ns.Guild.HuntCount("friends"))
ns.UI.OpenPanel("settings")
local sheet = frameWith(function(f) return f.page == 3 and f._scripts.OnClick end)
click(sheet)
local more = word("Mehr")             -- fix-3: Leeren steht hinter "Mehr"
if more and not ns.Store.Setting("ui.guildMore") then click(more) end
local fc = word("Freundesbuch leeren")
check("Knopf Freundesbuch leeren", fc ~= nil)
shown = nil
G.StaticPopup_Show = function(which, ...) shown = which; return showPopup(which, ...) end
if fc then click(fc) end
check("Rueckfrage Freundesbuch", shown == "DEATHNOTE_FRIENDS_CLEAR", shown)
G.StaticPopupDialogs.DEATHNOTE_FRIENDS_CLEAR.OnAccept()
G.StaticPopup_Show = showPopup
tick(1)
check("fremde Freigabe weg, eigene bleibt", ns.Guild.Hunt("Freund-Ziel", "friends") == nil and ns.Guild.Hunt("Mein-Ziel", "friends") ~= nil)
ns.UI.ClosePanel()
clean("Freundesbuch leeren")

------------------------------------------------------------------------
-- Rest aus dem Sprach-Bau: der Abgleichen-Knopf waechst mit dem Text
------------------------------------------------------------------------
BM.measure = true
local sync = frameWith(function(f) return f.text and f.text._text == "Abgleichen" and f._scripts.OnClick end)
check("Abgleichen-Knopf da", sync ~= nil)
if sync then
  check("kurzer Text: 84 px", sync:GetWidth() == 84, sync:GetWidth())
  sync:SetLabel("Realm blockt Flüstern")
  local w = sync:GetWidth()
  check("langer Kurzstand: Knopf breiter, hoechstens 150", w > 84 and w <= 150, w)
  check("Text passt in den Knopf", sync.text:GetStringWidth() <= sync.text:GetWidth(), sync.text:GetStringWidth())
  sync:SetLabel("Abgleichen")
  check("wieder 84 px", sync:GetWidth() == 84, sync:GetWidth())
end
BM.measure = false
clean("Abgleichen-Knopf")

print(("Fixe nach der Jagd UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
