-- 1.2.0 (fix-2): Oberflaeche der Fixe nach der finalen Jagd, mit der echten Logik, auf Deutsch.
-- (1) Fund 1: Freund ohne Nachnamen, zwei volle Namen -> beide Namen in "Nach Kollege" mit Hinweis, Rechtsklick:
--     "Mein Freund: ..." je Name und "Bindung loesen" (mit Rueckfrage, loescht seine Daten).
-- (2) Fund 14: uebernommene Notiz: gespeichert nur ein Merker, angezeigt der Satz, Speichern ohne Aenderung
--     schreibt nichts; alte deutsche Notiz aus 1.1.0 wird beim Laden umgestellt.
-- (3) Breiten: Knopf-Beschriftung zu lang -> 9 pt statt abgeschnitten; Stempel mit 25 Zeichen in zwei Zeilen;
--     Popup-Titel Nr. 1 mit 30 Zeichen passt; Wertfelder Ton (132) und Verfall (84).
-- (4) Rueckfrage "Gildenbuch leeren" nennt die Abschussliste.
-- Alle Namen sind erfunden.
local DIR0 = (arg[1] or "."):gsub("/+$", "")
package.path = DIR0 .. "/tests/ui/?.lua;" .. DIR0 .. "/tests/?.lua;" .. package.path
arg[0] = DIR0 .. "/tests/ui/fix2.lua"
local DIR = DIR0 .. "/DeathNote"
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

local FRIENDS = { "Berta" }
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
local P = ns.Guild.Proto

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function word(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function whisper(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from) end
local function headRow(name)
  for _, f in ipairs(BM.frames) do
    if f._kind == "Button" and f.item and f.item.wrap and f.item.head and f._shown and f.item.m and f.item.m.name == name then return f end
  end
end

tick(30); settle()

------------------------------------------------------------------------
-- (1) Fund 1: Konflikt in "Nach Kollege", Wahl und Bindung loesen
------------------------------------------------------------------------
local t = time()
whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", t = t - 30, zone = "Z", victim = "Berta Fremd" }, "K"), "Berta Fremd-Forever")
whisper(P.EncodeHunt({ key = "Falsch-Lamm", t = t, by = "Berta Fremd", why = "x" }), "Berta Fremd-Forever")
whisper(P.EncodeHunt({ key = "Echt-Lamm", t = t, by = "Berta Senf", why = "y" }), "Berta Senf-Forever")
tick(2)
check("Vorbedingung: Konflikt", ns.Friends.Health().reason == "conflict", ns.Friends.Health().reason)
ns:Fire("TOGGLE_UI"); tick(); settle()
local gt = frameWith(function(f) return f.id == "guild" and f._scripts and f._scripts.OnClick end)
click(gt)
ns.UI.SetGuildView("member"); settle()
local hf, hs = headRow("Berta Fremd"), headRow("Berta Senf")
check("Nach Kollege: beide Namen als Abschnitt", hf ~= nil and hs ~= nil)
check("Hinweis am Abschnitt: Rechtsklick, ist das dein Freund?", hs and hs.sub and hs.sub._text == L.MEMBER_CONFLICT,
  hs and hs.sub and hs.sub._text)
if hs then hs._scripts.OnClick(hs, "RightButton"); tick() end
local mine = word(ns.F(L.ACT_TIE_MINE, { name = "Berta Senf" }))
check("Menue: Mein Freund je Name und Bindung loesen", mine ~= nil and word(ns.F(L.ACT_TIE_MINE, { name = "Berta Fremd" })) ~= nil
  and word(L.ACT_TIE_LOOSE) ~= nil)
if mine then click(mine) end
settle()
check("Wahl gilt: kein Konflikt mehr, Daten des Abgewaehlten weg", ns.Friends.Health().reason ~= "conflict"
  and ns.Guild.Hunt("Falsch-Lamm", "friends") == nil and ns.Guild.Get("Grimm-Bart", "friends") == nil)
whisper(P.EncodeKill({ key = "Fies-Ling", display = "Fies Ling", t = t - 20, zone = "Z", victim = "Berta Senf" }, "K"), "Berta Senf-Forever")
tick(2); ns:Fire("GUILD_UPDATED"); settle()
hs = headRow("Berta Senf")
check("nach der Wahl: Abschnitt der Freundin mit ihren Daten", hs ~= nil and ns.Guild.Get("Fies-Ling", "friends") ~= nil)
local shown, sdata
local showPopup = G.StaticPopup_Show
G.StaticPopup_Show = function(which, a1, a2, data) shown, sdata = which, data; return showPopup(which, a1, a2, data) end
if hs then hs._scripts.OnClick(hs, "RightButton"); tick() end
local loose = word(L.ACT_TIE_LOOSE)
check("Rechtsklick auf eine gebundene Freundin: Bindung loesen", loose ~= nil)
if loose then click(loose) end
check("Rueckfrage vor dem Loesen", shown == "DEATHNOTE_TIE_LOOSE" and sdata == "Berta", tostring(shown) .. "/" .. tostring(sdata))
local dlg = G.StaticPopupDialogs.DEATHNOTE_TIE_LOOSE
check("Rueckfrage nennt Folgen, Knopf Bindung loesen", dlg and dlg.text:find("gelöscht", 1, true) ~= nil and dlg.button1 == L.ACT_TIE_LOOSE)
if dlg then dlg.OnAccept(nil, sdata) end
settle()
check("geloest: Daten weg, keine Bindung", ns.Guild.Get("Fies-Ling", "friends") == nil and #ns.Friends.Bound() == 0)
G.StaticPopup_Show = showPopup
local menuF = rawget(G, "DeathNoteMenu")
if menuF and menuF.blocker:IsShown() then menuF.blocker._scripts.OnClick(menuF.blocker) end
clean("Bindung")

------------------------------------------------------------------------
-- (2) Fund 14: uebernommene Notiz als Merker
------------------------------------------------------------------------
AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Gilden-Feind", display = "Gilden Feind", t = t - 60,
  zone = "Z", victim = "Kollege Wurst" }, "K"), "GUILD", "Kollege-Forever")
tick(1)
local k = ns.Guild.Adopt("Gilden-Feind")
local e = ns.Store.Get(k)
check("Notiz gespeichert als Merker, ohne Satz", e and e.note == "" and e.fromGuildKills == 1, e and e.note)
ns.UI.ShowEnemy(k); settle()
local noteBox = frameWith(function(f) return f._kind == "EditBox" and f.key == k end)
check("Plakat zeigt den Satz in der aktiven Sprache", noteBox and noteBox._text == ns.F(L.NOTE_FROM_GUILD, { kills = 1 }),
  noteBox and noteBox._text)
if noteBox and noteBox._scripts.OnEditFocusLost then noteBox._scripts.OnEditFocusLost(noteBox) end
check("Fokus weg ohne Aenderung: nichts gespeichert", ns.Store.Get(k).note == "")
local db = { version = 3, enemies = { ["Alt-Feind"] = { name = "Alt", surname = "Feind", manual = true, fromGuild = true,
  status = "wanted", note = "Aus dem Gildenbuch übernommen (3× getötet in der Gilde).", deaths = {} } } }
local ok = pcall(function()
  local S = ns.Store
  if S.Sanitize then S.Sanitize(db.enemies["Alt-Feind"]) end
end)
check("Sanitize wirft nicht", ok)
clean("Notiz")

------------------------------------------------------------------------
-- (3) Breiten
------------------------------------------------------------------------
BM.measure = true
ns.UI.OpenPanel("settings"); settle()
local fr = frameWith(function(f) return f._kind == "Button" and f.text and f.SetLabel and f._w == 132 end)
check("Knopf mit 132 px gefunden", fr ~= nil)
if fr then
  fr:SetLabel("Arkadaş defterini boşaltmak üzere")
  check("zu langer Text: 9 pt statt abgeschnitten", fr.text._fontSize == 9, fr.text._fontSize)
  fr:SetLabel("Kurz")
  check("kurzer Text wieder 10 pt", fr.text._fontSize == 10, fr.text._fontSize)
end
local tone = frameWith(function(f) return f._kind == "FontString" and f.label and f.minus and f._w == 132 end)
local hexp = frameWith(function(f) return f._kind == "FontString" and f.label and f.minus and f._w == 84 end)
check("Wertfeld Ton 132 px, Verfall 84 px", tone ~= nil and hexp ~= nil)
-- (4) Rueckfrage Gildenbuch leeren: nennt die Abschussliste (wie die des Freundesbuchs)
local gc = G.StaticPopupDialogs.DEATHNOTE_GUILD_CLEAR
check("Rueckfrage Gildenbuch leeren nennt die Abschussliste", gc and gc.text:find("Abschussliste", 1, true) ~= nil, gc and gc.text)
ns.UI.ClosePanel(); settle()
clean("Breiten")

print(("Fixe nach der finalen Jagd UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
