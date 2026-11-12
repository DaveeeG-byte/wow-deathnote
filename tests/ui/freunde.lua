-- 1.2.0: UI for the friends' book and the hit list with the real logic (Sync.lua, Friends.lua).
-- Tab "Guild & Friends", source All | Guild | Friends, empty states, guildmate/friend markers,
-- hit list with 0, 1 and 40 targets, post sheet, stamp, alarm, taken down message, house rules.
-- All names are made up.
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
end

local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  AM.units.player.guild = "Die Wurstbrüder"
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
clean("Login")

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function tab(id) local t = frameWith(function(f) return f.id == id and f._scripts.OnClick end); t._scripts.OnClick(t); tick() end
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
local function whisper(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from or "Fritz-Forever") end
local function guildMsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end

BM.measure = true       -- text widths are estimated: check the room in the head of the left page
ns:Fire("TOGGLE_UI")
tick(30)          -- friend list read, hello to Fritz on its way
settle()
local P = ns.Guild.Proto

------------------------------------------------------------------------
-- tabs, source, views
------------------------------------------------------------------------
local gt = frameWith(function(f) return f.id == "guild" and f.text end)
check("Reiter heisst Gilde & Freunde", gt.text._text == "Gilde & Freunde", gt.text._text)
check("Reiter breiter (132), Text 128", gt._w == 132 and gt.text._w == 128, tostring(gt._w))
local help = frameWith(function(f) return f.text and f.text._text == "?" end)
check("Reiter endet vor dem ?", gt:GetRight() and help:GetLeft() and gt:GetRight() <= help:GetLeft(),
      tostring(gt:GetRight()) .. " / " .. tostring(help:GetLeft()))
tab("guild")
local SRCS = frameWith(function(f) return f.items and f.items[1] and f.items[1].src end)
local VIEWS = frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)
-- fix-3: the source switch only once both sources exist (here no friend has DeathNote yet)
check("Quellen-Umschalter verborgen, solange kein Freund DeathNote hat", SRCS and not SRCS:IsVisible())
check("Drei Quellen: Alle, Gilde, Freunde", SRCS and #SRCS.items == 3 and SRCS.items[1].text._text == "Alle"
      and SRCS.items[2].text._text == "Gilde" and SRCS.items[3].text._text == "Freunde")
check("Drei Ansichten, Abschussliste ohne Freigaben verborgen", VIEWS and #VIEWS.items == 3 and VIEWS.items[3].text._text == "Abschussliste"
      and VIEWS:IsVisible() and not VIEWS.items[3]:IsShown())
check("Alle ist voreingestellt", SRCS.items[1].mark:IsShown())
local sb = G.DeathNoteSearch
check("Suchfeld und zwei Ansichten ueberlappen nicht", sb:GetRight() and VIEWS.items[2]:GetLeft() and sb:GetRight() <= VIEWS.items[2]:GetLeft(),
      tostring(sb:GetRight()) .. " / " .. tostring(VIEWS.items[2]:GetLeft()))
local sortB = frameWith(function(f) return f.arrow and f.ul and f.text end)
check("Quellen unten links, frei von der Sortierung", SRCS.items[3]:GetRight() and sortB:GetLeft() and SRCS.items[3]:GetRight() < sortB:GetLeft(),
      tostring(SRCS.items[3]:GetRight()) .. " / " .. tostring(sortB:GetLeft()))
clean("Reiter")

------------------------------------------------------------------------
-- Empty states per source
------------------------------------------------------------------------
check("Leer Alle: noch niemand gehoert", vis("Noch niemand mit DeathNote gehört.") ~= nil)
-- fix-3: the empty states per source only exist with both sources (see below); without guild and friends
-- the calm empty state without a red line, without a switch and without sync
ns.Store.Setting("guild.friends", false); tick(1)
AM.units.player.guild = nil
ns.UI.Refresh(); tick(1)
check("Leer ohne Gilde und Freunde: klarer Satz", vis("Keine Gilde, keine Freunde.") ~= nil)
check("Statuszeile still (keine rote Zeile)", vis("Keine Gilde und keine Freunde zum Teilen.") == nil)
check("Ohne Gilde und Freunde: keine Ansichten, keine Quellen, kein Abgleichen", not VIEWS:IsVisible() and not SRCS:IsVisible()
      and word("Abgleichen") == nil)
AM.units.player.guild = "Die Wurstbrüder"
ns.Store.Setting("guild.friends", true); tick(1)
ns.UI.Refresh()
clean("Leerzustaende")

------------------------------------------------------------------------
-- Data from friend and guildmate, markers in "By guildmate"
------------------------------------------------------------------------
whisper(P.EncodeHello(0, "1.2.0"))
whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40, zone = "Ödland",
  t = time() - 60, victim = "Fritz Frei" }, "K"))
guildMsg(P.EncodeKill({ key = "Rauf-Bold", display = "Rauf Bold", class = "ROGUE", level = 44, zone = "Arathihochland",
  t = time() - 90, victim = "Kollege Wurst" }, "K"))
tick(2); settle()
clean("Daten empfangen")
check("Freund im Freundesbuch", ns.Guild.Get("Grimm-Bart", "friends") ~= nil)
check("Statuszeile Alle zaehlt beide", vis("Läuft: 2 mit DeathNote in Gilde und Freunden.") ~= nil)
-- by killer, All: both
VIEWS.items[2]._scripts.OnClick(VIEWS.items[2]); tick()
local names = {}
for _, r in ipairs(rows()) do names[#names + 1] = r.item.key end
check("Alle zeigt Gilde und Freunde", table.concat(names, ","):find("Grimm-Bart", 1, true) and table.concat(names, ","):find("Rauf-Bold", 1, true),
      table.concat(names, ","))
click(SRCS.items[3])
names = {}
for _, r in ipairs(rows()) do names[#names + 1] = r.item.key end
check("Freunde zeigt nur den Freund", table.concat(names, ",") == "Grimm-Bart", table.concat(names, ","))
click(SRCS.items[1])
-- by guildmate: markers
VIEWS.items[1]._scripts.OnClick(VIEWS.items[1]); tick()
local fritz, kollege
for _, r in ipairs(rows()) do
  if r.item.head and r.item.m.name == "Fritz Frei" then fritz = r end
  if r.item.head and r.item.m.name == "Kollege Wurst" then kollege = r end
end
check("Kopf Freund mit FREUND", fritz and fritz.mark._text == "FREUND", fritz and fritz.mark._text)
check("Kopf Kollege ohne Kennzeichen (fix-3: nur der Freund)", kollege and (kollege.mark._text or "") == "", kollege and kollege.mark._text)
clean("Nach Kollege")

------------------------------------------------------------------------
-- Hit list: empty, post through the poster, poster with stamp
------------------------------------------------------------------------
check("Ohne Freigabe keine Abschussliste-Ansicht (fix-3)", not VIEWS.items[3]:IsShown())
VIEWS.items[2]._scripts.OnClick(VIEWS.items[2]); tick()
local grimm
for _, r in ipairs(rows()) do if r.item.key == "Grimm-Bart" then grimm = r end end
click(grimm)
-- fix-3: Grimm is guild enemy No. 1, his stamp sits under the photo: no word there, the action is in the row menu
check("Kein Wort unter dem Stempel", word("Zur Jagd freigeben") == nil)
click(grimm, "RightButton")
local hw = word("Zur Jagd freigeben")
check("Zeilenmenue: Zur Jagd freigeben", hw ~= nil)
click(hw)
check("Waehrend des Anlegens: Abschussliste-Ansicht sichtbar", VIEWS.items[3]:IsShown())
check("Blatt Zur Jagd freigeben offen", vis("Den Grund sehen alle in deiner Gilde und deine Freunde mit DeathNote.") ~= nil)
check("Name auf dem Blatt", vis("Grimm Bart") ~= nil)
local R = ns.UI and frameWith(function(f) return f.edit and f.tabs and f.go end)
check("Drei Ziele, Gilde & Freunde gewaehlt", R and #R.tabs == 3 and R.tabs[1].mark:IsShown())
click(R.tabs[3])
check("Hinweis passt zur Wahl", vis("Den Grund sehen deine Freunde mit DeathNote.") ~= nil)
click(R.tabs[1])
R.edit:SetText("Campt am |cffff0000Flugpunkt|r\nimmer")
click(R.go)
clean("Freigeben")
check("Freigabe in beiden Listen", ns.Guild.Hunt("Grimm-Bart", "all") and ns.Guild.Hunt("Grimm-Bart", "all").src == "both")
check("Grund gesaeubert", ns.Guild.Hunt("Grimm-Bart", "all").why == "Campt am Flugpunkt immer", ns.Guild.Hunt("Grimm-Bart", "all").why)
check("Abschussliste aufgeschlagen", VIEWS.items[3].mark:IsShown())
check("Plakat ABSCHUSSLISTE", vis("A B S C H U S S L I S T E") ~= nil)
check("Grund auf dem Plakat", vis("Grund: Campt am Flugpunkt immer") ~= nil)
check("Erlegt: noch nicht", vis("NOCH NICHT") ~= nil and vis("noch von niemandem erlegt") ~= nil)
local stamp = frameWith(function(f) return f._kind == "Texture" and f._tex and tostring(f._tex):find("stamp_hunt", 1, true) and f:IsVisible() end)
check("Stempel ZUR JAGD FREIGEGEBEN", stamp ~= nil)
check("Knopf Jagd abblasen", word("Jagd abblasen") ~= nil)
tick(1)        -- (fix-1) the queue sends 0.3 s apart, also after an empty queue
local sent = 0
for _, m in ipairs(AM.addonSent) do if m.text:match("^1\tJ\t") then sent = sent + 1 end end
check("J an Gilde (und an Fritz per Flüstern)", sent >= 2, sent)

------------------------------------------------------------------------
-- Default: with calls the hit list is the first view
------------------------------------------------------------------------
tab("wanted"); tab("guild")
check("Abschussliste bleibt gewaehlt", VIEWS.items[3].mark:IsShown())

------------------------------------------------------------------------
-- 40 targets, long names, long reason
------------------------------------------------------------------------
for i = 1, 40 do
  local who = ({ "Kollege Wurst", "Moppel Mops", "Anna Blume", "Bert Brot" })[(i % 4) + 1]
  local key = "Langername" .. i .. "abcdefghij-Langernachname" .. i .. "abcdefgh"
  guildMsg(P.EncodeHunt({ key = key, display = key:gsub("%-", " "), class = "WARRIOR", level = 50, t = time() - i * 60,
    by = who, why = string.rep("Sehr langer Grund ", 6) }), (who:match("^(%S+)")) .. "-Forever")
end
tick(2)
ns.UI.Refresh()
clean("40 Ziele")
check("Abschussliste mit 41 Zeilen", ns.UI.DataCount() == 41 or ns.UI.DataCount() == 40 + 1, ns.UI.DataCount())
local rs = rows()
check("Zeilen gefuellt", #rs == 9 and rs[1].name._text ~= "", #rs)
click(rs[2])
check("Langes Plakat ohne Fehler", vis("A B S C H U S S L I S T E") ~= nil)
local cut = ns.Guild.Hunt(rs[2].item.key, "all").why
check("Grund auf 60 Zeichen gekuerzt", cut and select(2, cut:gsub("[^\128-\191]", "")) <= 60, cut)
clean("langes Plakat")

------------------------------------------------------------------------
-- Alarm for a hit list target, taken down message
------------------------------------------------------------------------
settle(); BM.Advance(200); AM.Advance(200)
ns.Store.Setting("guild.sightings", true)
AM.AddEnemy("mouseover", { name = "Langername3abcdefghij", surname = "Langernachname3abcdefgh", guid = "Player-1-L3" })
AM.FireEvent("UPDATE_MOUSEOVER_UNIT")
tick()
check("Popup: Ziel der Abschussliste", G.DeathNoteAlert:IsShown() and G.DeathNoteAlert.title._text == "ZIEL DER ABSCHUSSLISTE",
      G.DeathNoteAlert.title._text)
check("Popup nennt die Freigabe", (G.DeathNoteAlert.line._text or ""):find("freigegeben von", 1, true) ~= nil, G.DeathNoteAlert.line._text)
clean("Alarm")
settle()
AM.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-1-L3")
tick(1)
check("Meldung Erlegt", G.DeathNoteBanner and G.DeathNoteBanner:IsShown()
      and (G.DeathNoteBanner.line._text or ""):find("erlegt von Varorak", 1, true) ~= nil, G.DeathNoteBanner and G.DeathNoteBanner.line._text)
clean("Erlegt")

------------------------------------------------------------------------
-- House rules, guild sheet with friends
------------------------------------------------------------------------
ns.UI.OpenPanel("settings")
local sheet = frameWith(function(f) return f.page == 3 and f._scripts.OnClick end)
click(sheet)
-- fix-3: two calm groups SHARE and WARN with five checkboxes on a 24 grid; the rest behind "More"
-- (second page of the sheet, state remembered, closed by default)
local function visibleChecks()
  local out = {}
  for _, f in ipairs(BM.frames) do if f._kind == "CheckButton" and f.opt and f.opt.guild and f:IsVisible() then out[#out + 1] = f end end
  table.sort(out, function(a, b) return a._points[1][3] > b._points[1][3] end)
  return out
end
local checks = visibleChecks()
local names1 = {}
for i, c in ipairs(checks) do names1[i] = c.opt.guild end
check("Blatt Gilde: fuenf Haken", #checks == 5, #checks)
check("Die fuenf, die man braucht", table.concat(names1, ",") == "share,friends,sightings,alert,alertHunt", table.concat(names1, ","))
check("Ueberschriften TEILEN und WARNEN", vis("T E I L E N") ~= nil and vis("W A R N E N") ~= nil)
check("Raster 24 px in jeder Gruppe", checks[1]._points[1][3] - checks[2]._points[1][3] == 24
      and checks[2]._points[1][3] - checks[3]._points[1][3] == 24 and checks[4]._points[1][3] - checks[5]._points[1][3] == 24)
check("Zugeklappt: kein Stand, kein Leeren, keine Stufen-Reihe", word("Gildenbuch leeren") == nil and vis("S T A N D") == nil
      and vis("Freigaben gelten") == nil)
local more = word("Mehr")
check("Wort Mehr unten, nicht unterstrichen", more ~= nil and not more.mark:IsShown())
check("Mit Freunden teilen", vis("Mit Freunden teilen") ~= nil)
check("Schalter Abschussliste", vis("Bei Zielen der Abschussliste warnen") ~= nil)
check("Alarm-Schalter heisst fuer beide", vis("Bei Tätern von Gilde und Freunden warnen") ~= nil)
local fcb
for _, c in ipairs(checks) do if c.opt.guild == "friends" then fcb = c end end
check("Haken Freunde an", fcb and fcb:GetChecked())
local function toggle(cb) cb:SetChecked(not cb:GetChecked()); click(cb) end
toggle(fcb)
check("Haken schaltet die Einstellung", ns.Store.Setting("guild.friends") == false)
click(more)
check("Mehr: zweite Seite, gemerkt", ns.Store.Setting("ui.guildMore") == true and more.mark:IsShown())
local checks2 = visibleChecks()
local names2 = {}
for i, c in ipairs(checks2) do names2[i] = c.opt.guild end
check("Mehr: die uebrigen fuenf Haken", table.concat(names2, ",") == "shareManual,receive,alertListed,announce,announceHunt",
      table.concat(names2, ","))
local all = {}
for _, f in ipairs(BM.frames) do if f._kind == "CheckButton" and f.opt and f.opt.guild then all[f.opt.guild] = true end end
local n = 0
for _ in pairs(all) do n = n + 1 end
check("Keine Einstellung verloren: zehn Haken auf beiden Seiten", n == 10, n)
check("Stand der Freunde", vis("Freund") ~= nil)
check("Stand sagt aus", vis("Teilen mit Freunden ist aus (Hausordnung, Blatt Gilde).") ~= nil)
toggle(fcb)
check("wieder an", ns.Store.Setting("guild.friends") == true)
-- Room (anchors relative to the sheet, 490 high): buttons "Empty guild book" and "Empty friends' book" in one
-- row above the hint (bottom 44, one line) and the word More; above them two status lines (14 + 3 each)
local clear = word("Gildenbuch leeren")
local fclear = word("Freundesbuch leeren")
local cy = clear._points[1][3]
local lastY = checks2[#checks2]._points[1][3]
check("Knopf Leeren ueber dem Hinweis", 490 + cy - 22 >= 44 + 26, 490 + cy - 22)
check("Letzter Haken, Stufe, Stand und zwei Standzeilen ueber dem Knopf", lastY - 20 - 24 - 22 - 2 * 17 >= cy,
      lastY .. " / " .. cy)
check("Freundesbuch leeren neben Gildenbuch leeren, im Blatt", fclear and fclear._points[1][3] == cy
      and fclear._points[1][2] >= clear._points[1][2] + 132 and fclear._points[1][2] + 132 <= 380 - 28,
      fclear and fclear._points[1][2])
local fst = vis(ns.Friends.Health().text)
check("Stand je eine Zeile (voller Satz im Tooltip)", fst and fst._maxl == 1, fst and fst._maxl)
-- fix-2 (language hunt E7): "Calls last: always / 30 days" instead of "expire after: Never"
local exp = vis("Freigaben gelten")
check("Stufe: Freigaben gelten, Voreinstellung immer", exp ~= nil and vis("immer") ~= nil)
local expV
for _, f in ipairs(BM.frames) do if f._kind == "FontString" and f._text == "immer" and f:IsVisible() then expV = f end end
local plus = expV and expV.plus
if plus then click(plus) end
check("Pfeil rechts: 30 Tage", ns.Store.Setting("guild.huntExpire") == 30 and vis("30 Tage") ~= nil, ns.Store.Setting("guild.huntExpire"))
if plus then click(plus); click(plus); click(plus) end
check("bis 180 Tage, nicht weiter", ns.Store.Setting("guild.huntExpire") == 180, ns.Store.Setting("guild.huntExpire"))
for _ = 1, 4 do if expV and expV.minus then click(expV.minus) end end
check("zurueck auf immer", ns.Store.Setting("guild.huntExpire") == 0 and vis("immer") ~= nil)
ns.UI.ClosePanel()
ns.UI.OpenPanel("settings")
check("Mehr bleibt offen nach Schliessen und Oeffnen", word("Gildenbuch leeren") ~= nil and #visibleChecks() == 5
      and visibleChecks()[1].opt.guild == "shareManual")
click(word("Mehr"))
check("Mehr zu: wieder die fuenf", ns.Store.Setting("ui.guildMore") == false and visibleChecks()[1].opt.guild == "share")
ns.UI.ClosePanel()
clean("Hausordnung")

print(("Freunde und Abschussliste UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
