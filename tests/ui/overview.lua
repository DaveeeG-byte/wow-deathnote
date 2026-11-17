-- 1.4.0 overview: taking over a friend's list in the book (row word, poster, "Take over all" with preview, result,
-- undo), the import with preview (own book, a friend's book), filter and sorts of Wanted with the hint "12 of 48",
-- section heads, the folded name search, what is remembered, and the cost of sorting 400 entries. Real logic.
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
local L, UI, OV = ns.L, ns.UI, ns.UI.OV

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function button(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function rows()
  local out = {}
  for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under then out[#out + 1] = f end end
  table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
  return out
end
local function whisper(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz-Forever") end
local function className(tok) local t = rawget(G, "LOCALIZED_CLASS_NAMES_MALE"); return type(t) == "table" and t[tok] or tok end
local function menuItems()
  local m = rawget(G, "DeathNoteMenu")
  local out = {}
  if m and m:IsShown() then for _, b in ipairs(m.items) do if b:IsShown() then out[#out + 1] = b end end end
  return out
end
local function pick(label)
  for _, b in ipairs(menuItems()) do
    if b.text._text == label or b.text._text == "• " .. label then b._scripts.OnClick(b, "LeftButton"); tick(); return true end
  end
  return false
end

BM.measure = true
ns:Fire("TOGGLE_UI")
tick(30)
settle()
local P = ns.Guild.Proto
local t = time()

------------------------------------------------------------------------
-- (1) Fritz (friend, no guild) has three killers; one of them is in my book already
------------------------------------------------------------------------
whisper(P.EncodeHello(0, "1.4.0"))
for i, x in ipairs({ { "Grimm-Bart", "Grimm Bart", "MAGE" }, { "Fies-Ling", "Fies Ling", "ROGUE" }, { "Olle-Kamelle", "Olle Kamelle", "WARRIOR" } }) do
  whisper(P.EncodeKill({ key = x[1], display = x[2], class = x[3], level = 40, zone = "Ödland", t = t - 60 * i, victim = "Fritz Frei" }, "K"))
end
ns.Store.AddManual("Olle", "Kamelle")
tick(2); settle()
clean("Freundesdaten")
check("drei Täter im Freundesbuch", ns.Guild.Get("Grimm-Bart", "friends") and ns.Guild.Get("Fies-Ling", "friends") and true)

UI.SetFilter("guild"); tick()
UI.SetGuildView("enemy"); tick()
local function rowOf(key) for _, r in ipairs(rows()) do if r.item.key == key then return r end end end
local grimm = rowOf("Grimm-Bart")
check("Zeile Grimm mit Wort übernehmen", grimm and grimm.take:IsVisible() and grimm.take.text._text == L.ROW_TAKE)
check("Zeile Olle: IM BUCH, kein übernehmen", rowOf("Olle-Kamelle") and not rowOf("Olle-Kamelle").take:IsShown()
  and rowOf("Olle-Kamelle").mark._text == L.MARK_IN_BOOK)
check("Plakat eines Freundes-Täters: FREUNDESBUCH", vis("F R E U N D E S B U C H") ~= nil)

-- one row: one click, no jump, result in the foot line, undo on the poster
click(grimm.take)
check("Grimm im eigenen Buch, als übernommen von Fritz", ns.Store.Get("Grimm-Bart") and ns.Store.Get("Grimm-Bart").adoptFrom == "Fritz Frei"
  and ns.Store.Get("Grimm-Bart").adoptSrc == "friends")
check("bleibt im Reiter", vis("F R E U N D E S B U C H") ~= nil and button(L.ACT_UNDO) ~= nil)
check("Ergebnis in der Fusszeile", vis(ns.F(L.TAKE_ONE_DONE, { name = "Grimm Bart" })) ~= nil)
check("Zeile sagt jetzt IM BUCH", rowOf("Grimm-Bart").mark._text == L.MARK_IN_BOOK and not rowOf("Grimm-Bart").take:IsShown())
tick(1)
click(button(L.ACT_UNDO))
check("Rückgängig: Grimm wieder weg", ns.Store.Get("Grimm-Bart") == nil)
check("Rückgängig gemeldet", vis(ns.F(L.TAKE_UNDONE, { count = 1 })) ~= nil)
clean("eine Zeile")

-- all: preview (2 new, 1 already there), result, undo once
check("Plakat: Alle übernehmen", button(L.ACT_TAKE_ALL) ~= nil)
click(button(L.ACT_TAKE_ALL))
check("Vorschau: Zahlen", vis(ns.F(L.TAKE_COUNT, { new = 2, have = 1 })) ~= nil)
check("Vorschau: neue Namen", vis("Grimm Bart") and vis("Fies Ling, ") ~= nil or vis("Grimm Bart, Fies Ling") ~= nil)
check("Vorschau: was von Freunden kommt", vis(L.TAKE_HINT_FRIENDS) ~= nil)
check("Vorschau: nichts eingetragen", ns.Store.Get("Grimm-Bart") == nil and ns.Store.Get("Fies-Ling") == nil)
click(button(L.ACT_TAKE))
check("alle neu im Buch", ns.Store.Get("Grimm-Bart") and ns.Store.Get("Fies-Ling") and true)
check("Ergebnis", vis(ns.F(L.TAKE_DONE, { count = 2 })) ~= nil)
check("Fertig-Knopf", button(L.BTN_DONE) ~= nil)
click(button(L.ACT_UNDO))     -- the second click of a double click: locked
check("Doppelklick nimmt nicht gleich zurück", ns.Store.Get("Grimm-Bart") ~= nil)
tick(1)
click(button(L.ACT_UNDO))
check("Rückgängig nimmt beide zurück", ns.Store.Get("Grimm-Bart") == nil and ns.Store.Get("Fies-Ling") == nil)
check("Olle bleibt (war vorher da)", ns.Store.Get("Olle-Kamelle") ~= nil)
check("nur einmal", button(L.ACT_UNDO) == nil)
click(button(L.BTN_DONE))
clean("alle")

-- "only new" in the sort menu, the hint, one click back
local sortB = frameWith(function(f) return f.arrow and f.ul and f:IsVisible() end)
click(sortB)
check("Gilde: Nur, was mir fehlt", pick(L.SORT_ONLY_NEW))
check("nur neue Zeilen", #rows() == 2 and not rowOf("Olle-Kamelle"))
check("Hinweis 2 von 3", vis(ns.F(L.FILTER_HINT, { shown = 2, total = 3 })) ~= nil)
check("gemerkt", ns.Store.Setting("ui.guildNew") == true)
click(frameWith(function(f) return f.ovPart and f.text and f:IsVisible() and f._scripts.OnClick and not f.tri end))
check("ein Klick: wieder alle", #rows() == 3 and ns.Store.Setting("ui.guildNew") == false)
clean("nur neue")

-- by guildmate: right click on Fritz's head, take over all of his section
UI.SetGuildView("member"); tick()
local head
for _, r in ipairs(rows()) do if r.item.head and r.item.m.name == "Fritz Frei" then head = r end end
check("Kopf Fritz", head ~= nil)
if head then click(head, "RightButton") end
check("Menü: Alle von Fritz übernehmen", pick(ns.F(L.ACT_TAKE_ALL_OF, { name = "Fritz" })))
check("Vorschau von Fritz", vis(ns.F(L.TAKE_FROM_MATE, { name = "Fritz" })) ~= nil and vis(ns.F(L.TAKE_COUNT, { new = 2, have = 1 })) ~= nil)
click(button(L.ACT_TAKE))
local g = ns.Store.Get("Fies-Ling")
check("aus dem Abschnitt: Herkunft Fritz", g and g.adoptFrom == "Fritz Frei" and g.manual == true and g.fromGuild == true)
click(button(L.BTN_DONE))
UI.SetGuildView("enemy"); tick()
clean("Abschnitt")

------------------------------------------------------------------------
-- (2) Wanted: filter, sorts, section heads, search
------------------------------------------------------------------------
local S = ns.Store
local function killed(name, surname, n, level, class, assist)
  local k
  for i = 1, n do
    k = S.ApplyKill({ name = name, surname = surname, class = class or "PALADIN", level = level or 40 },
      { t = t - 3600 * i - level, zone = "Arathihochland", me = "Hagen Wurst", source = "recap", others = {} }, not assist)
  end
  return k
end
killed("Anton", "Axt", 3, 30, "WARRIOR")
killed("Berta", "Beil", 1, 55, "MAGE")
killed("Cäsar", "Ärger", 2, 44, "ROGUE")
killed("Dora", "Dolch", 1, 20, "MAGE", true)          -- only an assist
local pard = killed("Emil", "Elend", 1, 33, "PRIEST")
S.SetStatus(pard, "pardoned")
UI.SetFilter("wanted"); tick(); settle()
clean("Gesucht")

local function names()
  local out = {}
  for _, r in ipairs(rows()) do if not r.item.ovHead then out[#out + 1] = r.item.name end end
  return table.concat(out, ",")
end
local function heads()
  local out = {}
  for _, r in ipairs(rows()) do if r.item.ovHead then out[#out + 1] = r.item.kind .. r.item.n end end
  return table.concat(out, ",")
end
check("Abschnittskopf vor den Begnadigten", heads():find("pardoned1", 1, true) ~= nil, heads())
local hrow
for _, r in ipairs(rows()) do if r.item.ovHead then hrow = r end end
check("Kopf: Wort und Zahl", hrow and hrow.name._text == L.SECTION_PARDONED and hrow.right._text == "1")
if hrow then click(hrow); click(hrow, "RightButton") end
check("Kopf ist nicht wählbar, kein Menü", #menuItems() == 0)

local filterB = frameWith(function(f) return f.ovPart and f.tri and f:IsVisible() end)
check("Filter-Wort sichtbar", filterB ~= nil and filterB.text._text == L.FILTER_WORD)
local search = G.DeathNoteSearch
check("Kopfzeile: Suche, Filter, Sortierung ohne Überlappung", search:GetRight() <= filterB:GetLeft() and filterB:GetRight() <= sortB:GetLeft(),
  tostring(search:GetRight()) .. "/" .. tostring(filterB:GetLeft()) .. "/" .. tostring(filterB:GetRight()) .. "/" .. tostring(sortB:GetLeft()))
local total = #rows()

click(filterB)
check("Filtermenü: Rollen und Klasse", #menuItems() == 7, #menuItems())
check("Filter: Hat mich getötet", pick(L.FILTER_KILL))
check("nur Getötete (Dora fehlt)", not names():find("Dora", 1, true) and names():find("Anton", 1, true) ~= nil, names())
check("Filter-Wort zeigt den Filter", filterB.text._text == L.FILTER_KILL)
check("Hinweis x von y", vis(ns.F(L.FILTER_HINT, { shown = OV.shown, total = OV.total })) ~= nil and OV.shown < OV.total, OV.shown .. "/" .. OV.total)
click(filterB); pick(L.FILTER_ASSIST)
check("Filter: Beteiligt (nur Dora)", names() == "Dora", names())
click(filterB); pick(L.FILTER_ATTACK)
-- package Grudge brings the role "attack"; without it in this branch the filter finds nobody (as named in the brief)
check("Filter: Rachsucht findet ohne Rolle niemanden", names() == "", names())
click(filterB); pick(L.FILTER_ADOPTED)
check("Filter: Übernommen (Grimm und Fies, nicht Olle)", names():find("Fies", 1, true) and names():find("Grimm", 1, true) and not names():find("Olle", 1, true), names())
click(filterB); pick(L.FILTER_MANUAL)
check("Filter: Von Hand (Olle, nicht Fies)", names() == "Olle", names())
click(filterB); pick(L.FILTER_CLASS)
check("Klassenmenü: zurück und Klassen", menuItems()[1] and menuItems()[1].text._text == L.FILTER_BACK and #menuItems() >= 5, #menuItems())
pick(className("MAGE"))
check("Klasse Magier und von Hand: niemand", names() == "", names())
check("gemerkt: Rolle und Klasse", S.Setting("ui.filterRole") == "manual" and S.Setting("ui.filterClass") == "MAGE")
click(filterB); pick(L.FILTER_ALL)
check("Alle: Klasse bleibt aus", S.Setting("ui.filterClass") == "" and #rows() == total, #rows())
click(filterB); pick(L.FILTER_CLASS); pick(className("MAGE"))
check("nur Magier (Berta, Dora, Grimm)", names():find("Berta", 1, true) and names():find("Dora", 1, true) and names():find("Grimm", 1, true) and not names():find("Anton", 1, true), names())
local hint = frameWith(function(f) return f.ovPart and not f.tri and f:IsVisible() end)
check("Hinweis sichtbar und anklickbar", hint ~= nil)
if hint then click(hint) end
check("ein Klick: alles wieder da", #rows() == total and S.Setting("ui.filterClass") == "" and S.Setting("ui.filterRole") == "all")
clean("Filter")

-- sorts (each saved), rank stays the default order
local function sortBy(label) click(sortB); return pick(label) end
check("Sortiermenü: acht Sortierungen und Begnadigte", (function() click(sortB); local n = #menuItems(); rawget(G, "DeathNoteMenu").blocker._scripts.OnClick(rawget(G, "DeathNoteMenu").blocker); return n end)() == 9)
sortBy(L.SORT_KILLS)
check("Kills an mir: Anton (3) vor Cäsar (2)", names():find("^Anton,Cäsar") ~= nil, names())
check("gemerkt", S.Setting("ui.sort") == "kills")
sortBy(L.SORT_LEVEL)
check("Stufe: Berta (55) zuerst", names():find("^Berta") ~= nil, names())
sortBy(L.SORT_NAME)
check("Name: Anton zuerst", names():find("^Anton,") ~= nil, names())
sortBy(L.SORT_BOUNTY)
check("Kopfgeld: Anton zuerst", names():find("^Anton") ~= nil, names())
sortBy(L.SORT_CLASS)
check("Klasse: Begnadigte bleiben am Ende", rows()[#rows()].item.name == "Emil", rows()[#rows()].item.name)
sortBy(L.SORT_RANK)
check("Rang: Anton auf 1", rows()[1].item.name == "Anton" and S.Setting("ui.sort") == "rank")

-- search: first or last name, any case, also umlauts
search:SetText("ärger"); search._scripts.OnTextChanged(search, true); tick()
check("Suche ärger findet Cäsar Ärger", names() == "Cäsar", names())
search:SetText("BEIL"); search._scripts.OnTextChanged(search, true); tick()
check("Suche BEIL findet Berta Beil", names() == "Berta", names())
check("Suche: Hinweis 1 von", vis(ns.F(L.FILTER_HINT, { shown = 1, total = OV.total })) ~= nil)
search:SetText(""); search._scripts.OnTextChanged(search, true); tick()
clean("Sortieren und Suchen")

------------------------------------------------------------------------
-- (3) Import with preview: a friend's text (Fritz's own book) and the own text
------------------------------------------------------------------------
local friendText = table.concat({ "DEATHNOTE:1",
  "E|Zorn-Zahn|wanted|0|4|0|0|||||ROGUE||50|||Zahn||",
  "D|Zorn-Zahn|" .. (t - 500) .. "|1|recap|Ödland|||||Fritz Frei|40||kill",
  "E|Anton-Axt|wanted|0|1|0|0|||||WARRIOR||30|||Axt||",
  "D|Anton-Axt|" .. (t - 400) .. "|1|recap|Ödland|||||Fritz Frei|40||kill",
  "E|Milde-Mann|pardoned|0|1|0|0|||||MAGE||30|||Mann||" }, "\n")
UI.OpenIO("import"); tick()
local IO = frameWith(function(f) return f.owner and f.edit end)
IO.edit:SetText(friendText); IO.edit._scripts.OnTextChanged(IO.edit, true)
click(button(L.IO_GO))
check("Vorschau: Buch von Fritz erkannt", IO.owner:IsVisible() and IO.owner.tabs[2].mark:IsShown()
  and IO.owner.tabs[2].text._text == ns.F(L.IO_THEIRS, { name = "Fritz" }))
check("Vorschau: Zahlen des Freundes", vis(ns.F(L.IO_PREVIEW_FRIEND, { new = 1, have = 1 })) ~= nil)
check("Vorschau: nichts eingelesen", S.Get("Zorn-Zahn") == nil)
click(button(L.IO_GO_NOW))
local z = S.Get("Zorn-Zahn")
check("Zorn übernommen, Tode bleiben beim Freund", z and z.kills == 0 and z.fromGuildKills == 4 and z.adoptSrc == "text")
check("Anton unverändert (3 Kills)", S.Get("Anton-Axt").kills == 3)
check("Begnadigter des Freundes bleibt draußen", S.Get("Milde-Mann") == nil)
check("Ergebnis", vis(ns.F(L.IO_TAKEN, { new = 1, have = 1 })) ~= nil)
tick(1)
click(button(L.ACT_UNDO))
check("Rückgängig: Zorn weg", S.Get("Zorn-Zahn") == nil)
-- the same text read as the own book (choice "mine"): merged like a backup, undo restores
IO.edit:SetText(friendText); IO.edit._scripts.OnTextChanged(IO.edit, true)
click(button(L.IO_GO))
click(IO.owner.tabs[1])
check("Wahl: mein Buch", IO.owner.tabs[1].mark:IsShown() and vis(ns.F(L.IO_PREVIEW, { total = 3, new = 2, have = 1 })) ~= nil)
click(button(L.IO_GO_NOW))
check("als eigenes eingelesen: Zorn mit 4 Kills (wie eine Sicherung)", S.Get("Zorn-Zahn") and S.Get("Zorn-Zahn").kills == 4)
tick(1)
click(button(L.ACT_UNDO))
check("Rückgängig: Zorn wieder weg, Anton wie vorher", S.Get("Zorn-Zahn") == nil and S.Get("Anton-Axt").kills == 3)
UI.ClosePanel()
clean("Einlesen")

------------------------------------------------------------------------
-- (4) 400 entries: sorting does not cost noticeably (with the rap sheet on: Store.Bounty reads the standing)
------------------------------------------------------------------------
for i = 1, 400 do
  S.ApplyKill({ name = "Feind" .. i, surname = "Nr" .. i, class = ({ "MAGE", "ROGUE", "WARRIOR", "PRIEST" })[i % 4 + 1], level = i % 60 + 1 },
    { t = t - i * 60, zone = "Arathihochland", me = "Hagen Wurst", source = "recap", others = {} }, true)
end
UI.SetFilter("wanted"); tick(); settle()
local worst, worstSort = 0, nil
for _, k in ipairs({ "rank", "kills", "seen", "recent", "name", "level", "class", "bounty" }) do
  sortBy(L[({ rank = "SORT_RANK", kills = "SORT_KILLS", seen = "SORT_SEEN", recent = "SORT_RECENT", name = "SORT_NAME",
    level = "SORT_LEVEL", class = "SORT_CLASS", bounty = "SORT_BOUNTY" })[k]])
  local c0 = os.clock()
  for _ = 1, 5 do UI.Refresh() end
  local ms = (os.clock() - c0) / 5 * 1000
  if ms > worst then worst, worstSort = ms, k end
end
io.write(("  Neuaufbau Gesucht mit %d Einträgen, teuerste Sortierung %s: %.2f ms (Mock, luajit)\n"):format(OV.total, worstSort, worst))
check("400 Einträge: Neuaufbau unter 25 ms in jeder Sortierung", worst < 25, ("%.2f ms (%s)"):format(worst, worstSort))
sortBy(L.SORT_RANK)
clean("400")

io.write(("Übersicht und Übernehmen UI: %d gruen, %d rot\n"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
