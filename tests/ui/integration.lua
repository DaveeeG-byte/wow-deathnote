-- Extra run: the UI files together with the real Core/Store/Tracker/Attribution/Probe.
-- The logic files run in the logic mock (tests/mock_wow.lua, global environment), the UI files in the
-- strict UI mock. Only ns is shared, as in the game.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local root = here .. "/../.."
-- Addon folder: DeathNote/ (after the rename) or still Staatsfeind/
local function addonDir(root)
  for _, d in ipairs({ "DeathNote", "Staatsfeind" }) do
    local f = io.open(root .. "/" .. d .. "/Alert.lua", "r")
    if f then f:close(); return root .. "/" .. d end
  end
  return root .. "/DeathNote"
end
local DIR = addonDir(root)
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail and ("  -> " .. tostring(detail)) or "")) end
end
local function clean(name)
  check(name .. ": keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  check(name .. ": keine Verstoesse", #BM.violations == 0, BM.violations[#BM.violations])
end

local ns = AM.Load({ noLogin = true, before = function() AM.units.player.guild = "Die Wurstbrüder" end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
clean("Login")
check("READY erreicht B", G.DeathNoteMinimapButton ~= nil)

ns:Fire("TOGGLE_UI")
clean("Fenster leer")
check("Fenster offen", G.DeathNoteFrame and G.DeathNoteFrame:IsShown())

local key = ns.Store.AddManual("Grimm", "Bart")
check("AddManual liefert Schluessel", key == "Grimm-Bart", key)
AM.Advance(0.1); BM.Advance(0.1)
clean("nach AddManual")

ns:Fire("TEST_ALERT")
clean("Probealarm mit echtem Store")
check("Popup sichtbar", G.DeathNoteAlert and G.DeathNoteAlert:IsShown())
BM.Advance(13); BM.FinishAnims()

AM.AddEnemy("target", { name = "Grimm", surname = "Bart" })
AM.FireEvent("PLAYER_TARGET_CHANGED")
AM.Advance(0.1); BM.Advance(0.1)
clean("Sichtung ueber den Tracker")
check("Alarm fuer Gelisteten", G.DeathNoteAlert:IsShown())
check("Makro Vor- und Nachname", (G.DeathNoteAlertButton:GetAttribute("macrotext") or ""):find("/targetexact Grimm Bart", 1, true) ~= nil,
      G.DeathNoteAlertButton:GetAttribute("macrotext"))

ns.UI.ShowEnemy(key)
ns.Store.AddRevenge(key)
ns.Store.SetNote(key, "Notiz")
AM.Advance(0.1); BM.Advance(0.1)
clean("Plakat, Rache, Notiz")

ns.UI.OpenIO("export")
local exported = ns.Store.Export()
check("Export liefert Text", type(exported) == "string" and #exported > 0)
local ok, a, b = ns.Store.Import(exported)
check("Import des eigenen Exports", ok, a)
ns.UI.ClosePanel()
ns.UI.Refresh()
clean("Sichern/Einlesen")

local tt = G.GameTooltip
tt._unitName, tt._unit, tt._lines = "Grimm", "target", {}
if BM.tooltipHook then BM.tooltipHook(tt, {}) end
check("Tooltip-Zeile mit echtem Util", tt._lines[1] and tt._lines[1]:find("IM BUCH:", 1, true) ~= nil, tt._lines[1])

ns.Store.Remove(key)
AM.Advance(0.1); BM.Advance(0.1)
clean("Loeschen")

------------------------------------------------------------------------
-- Guild with the real Sync.lua (if present)
------------------------------------------------------------------------
if ns.Guild and ns.Guild.Proto and ns.Guild.Proto.EncodeKill then
  check("Gilden-Reiter sichtbar", (function()
    for _, f in ipairs(BM.frames) do if f.id == "guild" and f._scripts.OnClick then return f:IsShown() end end
  end)())
  local function hear(o)
    local text = ns.Guild.Proto.EncodeKill({ key = "Rauf-Bold", display = "Rauf Bold", class = "ROGUE", level = 44,
      zone = "Arathihochland", t = time() - 60, victim = o.victim or "Kollege Wurst" }, "K")
    AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", o.sender or "Kollege-Forever")
  end
  BM.Advance(10); BM.FinishAnims()     -- the revenge message from above is done
  hear({})
  AM.Advance(2); BM.Advance(2)
  clean("Gildenmeldung empfangen")
  check("GUILD_KILL zeigt Meldung", G.DeathNoteBanner and G.DeathNoteBanner:IsShown()
        and (G.DeathNoteBanner.line._text or ""):find("wurde von Rauf Bold getötet", 1, true) ~= nil,
        G.DeathNoteBanner and G.DeathNoteBanner.line._text)
  local list = ns.Guild.List("rank")
  check("Gildenliste hat den Feind", list[1] and list[1].key == "Rauf-Bold")
  for _, f in ipairs(BM.frames) do if f.id == "guild" and f._scripts.OnClick then f._scripts.OnClick(f) end end
  AM.Advance(0.1); BM.Advance(0.1)
  clean("Gilden-Reiter")
  local function anyText(needle)
    for _, f in ipairs(BM.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) then return f end
    end
  end
  check("Zeile Rauf Bold", anyText("Rauf Bold") ~= nil)
  check("Untertext Opfer", anyText("1× getötet · 1 Opfer · zuletzt Kollege") ~= nil)
  check("Liste unveraendert (Sync-Cache)", ns.Guild.List("rank") == list)

  BM.Advance(200); BM.FinishAnims()
  AM.AddEnemy("mouseover", { name = "Rauf", surname = "Bold" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT")
  AM.Advance(0.1); BM.Advance(0.1)
  clean("Gildenfeind gesichtet")
  check("Popup GILDENFEIND", G.DeathNoteAlert:IsShown() and (G.DeathNoteAlert.title._text or "") == "GILDENFEIND GESICHTET",
        G.DeathNoteAlert.title._text)

  local tt = G.GameTooltip
  tt._unitName, tt._unit, tt._lines = "Rauf", "mouseover", {}
  if BM.tooltipHook then BM.tooltipHook(tt, {}) end
  check("Tooltip GILDENBUCH", tt._lines[1] and tt._lines[1]:find("GILDENBUCH:", 1, true) and tt._lines[1]:find("hat 1× Kollegen getötet", 1, true) ~= nil, tt._lines[1])

  local adopt
  for _, f in ipairs(BM.frames) do if f.text and f.text._text == "Ins eigene Buch" and f.fn then adopt = f end end
  if adopt then adopt._scripts.OnClick(adopt, "LeftButton") end
  AM.Advance(0.1); BM.Advance(0.1)
  clean("Ins eigene Buch")
  check("Adopt landet im eigenen Buch", ns.Store.Get("Rauf-Bold") ~= nil)
else
  print("Hinweis: Sync.lua fehlt, Gildenteil uebersprungen")
end

------------------------------------------------------------------------
-- Findings of the UI hunt with the real Store (proof tests U1 to U7, F7)
------------------------------------------------------------------------
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function tab(id) local t = frameWith(function(f) return f.id == id and f._scripts.OnClick end); t._scripts.OnClick(t) end
settle(); BM.Advance(300); AM.Advance(300)
tab("wanted")

-- U1: a line break in the surname gives no extra macro line
do
  local k = ns.Store.AddManual("Boese", "Bube")
  local e = ns.Store.Get(k)
  e.surname = "Bube\n/run BOESE()"; e.display = nil
  tick()
  ns:Fire("TEST_ALERT"); tick()
  local bt = rawget(G, "DeathNoteAlertButton")
  local macro = bt and bt:GetAttribute("macrotext") or ""
  check("U1 Vorbedingung: Popup zeigt Boese", G.DeathNoteAlert:IsShown() and (G.DeathNoteAlert.name._text or ""):find("Boese", 1, true) ~= nil, G.DeathNoteAlert.name._text)
  check("U1 Knopf nicht scharf", not (bt and bt:IsShown()))
  check("U1 keine dritte Makrozeile", not macro:find("/run", 1, true), macro)
  ns.Store.Remove(k); settle()
  clean("U1")
end

-- U2: the note stays with its entry when the selection changes while focused
do
  local a = ns.Store.AddManual("Anton", "Alpha")
  local b = ns.Store.AddManual("Berta", "Beta")
  tick()
  ns.UI.ShowEnemy(a)
  local note = frameWith(function(f) return f._kind == "EditBox" and f.key == a end)
  check("U2 Vorbedingung: Notizfeld auf Anton", note ~= nil)
  note:SetFocus(); note:SetText("campt am Zeppelin")
  local row = frameWith(function(f) return f._kind == "Button" and f.item and f.item.key == b and f._scripts.OnClick end)
  row._scripts.OnClick(row, "LeftButton")
  note:ClearFocus(); tick()
  check("U2 Notiz steht bei Anton", ns.Store.Get(a).note == "campt am Zeppelin", ns.Store.Get(a).note)
  check("U2 Berta ohne fremde Notiz", (ns.Store.Get(b).note or "") == "", ns.Store.Get(b).note)
  ns.Store.Remove(a); ns.Store.Remove(b); tick()
  clean("U2")
end

-- U3: Enter in the search field of the death log enters nothing
do
  local before = ns.Store.Count()
  tab("journal")
  local sb = G.DeathNoteSearch
  sb:SetText("Ödland"); sb._scripts.OnTextChanged(sb)
  sb._scripts.OnEnterPressed(sb); tick()
  check("U3 Journal-Suche legt keinen Feind an", ns.Store.Count() == before, ns.Store.Count())
  sb:SetText(""); sb._scripts.OnTextChanged(sb)
  tab("wanted"); tick()
  clean("U3")
end

-- U4 + U5: queue
do
  settle()
  local a, b, c = ns.Store.AddManual("Eins", "Erster"), ns.Store.AddManual("Zwei", "Zweiter"), ns.Store.AddManual("Drei", "Dritter")
  tick()
  ns.Alert.Spotted(a, nil, "other"); ns.Alert.Spotted(b, nil, "other")
  ns.Alert.Dismiss(); BM.FinishAnims()
  BM.Advance(0.1)
  ns.Alert.Spotted(c, nil, "other")
  BM.Advance(0.5)
  check("U4 C bleibt stehen", G.DeathNoteAlert.name._text == "Drei Dritter", G.DeathNoteAlert.name._text)
  settle(); settle()
  ns.Store.Remove(a); ns.Store.Remove(b); ns.Store.Remove(c); tick()

  local keys = {}
  for i = 1, 11 do keys[i] = ns.Store.AddManual("Feind" .. string.char(64 + i), "Masse") end
  tick()
  for i = 1, 11 do ns.Alert.Spotted(keys[i], nil, "other") end
  for _ = 1, 14 do ns.Alert.Dismiss(); BM.FinishAnims(); BM.Advance(0.5) end
  ns.Alert.Spotted(keys[11], nil, "other")
  local want = ns.Util.Display(ns.Store.Get(keys[11]))
  check("U5 verdraengter Feind wird gemeldet", G.DeathNoteAlert:IsShown() and G.DeathNoteAlert.name._text == want,
        G.DeathNoteAlert:IsShown() and G.DeathNoteAlert.name._text or "nichts")
  settle()
  for i = 1, 11 do ns.Store.Remove(keys[i]) end; tick()
  clean("U4/U5")
end

-- U6: SetUnit returns false
do
  settle()
  local a = ns.Store.AddManual("Modell", "Leer")
  tick()
  AM.AddEnemy("target", { name = "Modell", surname = "Leer" })
  BM.setUnitResult = false
  AM.FireEvent("PLAYER_TARGET_CHANGED"); tick()
  BM.setUnitResult = true
  check("U6 Vorbedingung: Popup zeigt Modell Leer", G.DeathNoteAlert.name._text == "Modell Leer", G.DeathNoteAlert.name._text)
  check("U6 Klassensymbol statt leerem Modell", G.DeathNoteAlert.icon:IsShown() and not G.DeathNoteAlert.model:IsShown())
  AM.units.target = nil
  settle(); ns.Store.Remove(a); tick()
  clean("U6")
end

-- U7: the log selection follows the entry, not the position (deaths with unclear killer; pve is not in the log since 1.2.0)
do
  local list = ns.Store.Deaths()
  table.insert(list, 1, { t = 1000, zone = "Alt", kind = "unknown", me = "X" })
  table.insert(list, 1, { t = 2000, zone = "Neu", kind = "unknown", me = "X" })
  tab("journal"); tick()
  local row = frameWith(function(f) return f._kind == "Button" and f.item and f.item.zone == "Alt" and f._scripts.OnClick end)
  row._scripts.OnClick(row, "LeftButton")
  table.insert(list, 1, { t = 3000, zone = "Ganzneu", kind = "unknown", me = "X" })
  ns:Fire("DEATH_RECORDED", list[1], nil); tick()
  local akte = frameWith(function(f) return f._kind == "FontString" and type(f._text) == "string" and f._text:find("\n", 1, true) and f:IsVisible() end)
  check("U7 Akte zeigt weiter den Fall Alt", akte and akte._text:find("Alt", 1, true) ~= nil, akte and (akte._text:gsub("\n", " / ")))
  tab("wanted"); tick()
  clean("U7")
end

-- F7: the real short form of the Store in the "Save the book" dialog
do
  local k = ns.Store.AddManual("Sicher", "Kopie")
  local e = ns.Store.Get(k)
  e.deaths[1] = { t = time() - 60, zone = "Schlingendorntal", subzone = "Grom'gol", me = "Davee", source = "manual", sure = true }
  tick()
  ns.UI.OpenIO("export")
  local eb = frameWith(function(f) return f._kind == "EditBox" and f._focus end)
  check("F7 kleines Buch: ganzer Text", eb and eb._text == ns.Store.Export())
  local sz = frameWith(function(f) return f.fn and f.text and f.text._text == "Nur klein" and f:IsVisible() end)
  check("F7 Wahl Nur klein (Store kennt die Kurzform)", sz ~= nil)
  if sz then sz._scripts.OnClick(sz, "LeftButton") end
  check("F7 Kurzform ohne Taten", eb and eb._text == ns.Store.Export(true) and #eb._text < #ns.Store.Export())
  ns.UI.ClosePanel()
  ns.Store.Remove(k); tick()
  clean("F7")
end

------------------------------------------------------------------------
-- 1.1.0 with the real Sync.lua: guild by member, manual entries, sound
------------------------------------------------------------------------
local function anyTextI(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local VW = frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)
if ns.Guild and type(ns.Guild.ByMember) == "function" and ns.Guild.Proto and ns.Guild.Proto.EncodeListed then
  settle(); BM.Advance(300); AM.Advance(300)
  local P = ns.Guild.Proto
  -- two kills on two guildmates, one pure manual entry from Moppel
  for i, v in ipairs({ "Kollege Wurst", "Moppel Mops" }) do
    local text = P.EncodeKill({ key = "Fiesling" .. i .. "-Gemein", display = "Fiesling" .. i .. " Gemein", class = "WARRIOR",
      level = 50, zone = "Ödland", t = time() - 600 * i, victim = v }, "K")
    AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", (v:match("^(%S+)")) .. "-Forever")
  end
  local lt = P.EncodeListed({ key = "Handfeind-Nur", display = "Handfeind Nur", class = "MAGE", level = 40, t = time() - 3 * 86400, by = "Moppel Mops" })
  AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", lt, "GUILD", "Moppel-Forever")
  tick(2)
  clean("1.1 Gildendaten empfangen")
  local hand = ns.Guild.Get("Handfeind-Nur")
  check("1.1 echter Hand-Eintrag empfangen", hand and hand.listedOnly == true and hand.listedBy and hand.listedBy["Moppel Mops"] ~= nil,
        hand and tostring(hand.listedOnly))
  tab("guild"); tick()
  check("1.1 Umschalter sichtbar mit echter ByMember", VW and VW:IsShown())
  -- by enemy: manual entry at the end, dimmed
  local rowsI = {}
  for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under then rowsI[#rowsI + 1] = f end end
  table.sort(rowsI, function(a, b) return (a.index or 0) < (b.index or 0) end)
  local last = rowsI[#rowsI]
  check("1.1 nach Feind: Hand-Eintrag zuletzt", last and last.item.key == "Handfeind-Nur" and last.sub._text == "eingetragen von Moppel",
        last and (tostring(last.item.key) .. " / " .. tostring(last.sub._text)))
  last._scripts.OnClick(last, "LeftButton"); tick()
  check("1.1 Plakat: VON HAND EINGETRAGEN", anyTextI("VON HAND EINGETRAGEN") ~= nil and anyTextI("Im Buch von: Moppel") ~= nil)
  clean("1.1 nach Feind")
  -- by member
  VW.items[1]._scripts.OnClick(VW.items[1]); tick()
  clean("1.1 nach Mitglied")
  local heads, kids = {}, {}
  for _, f in ipairs(BM.frames) do
    if f._kind == "Button" and f.item and f._shown and f.under then
      if f.item.head then heads[#heads + 1] = f else kids[#kids + 1] = f end
    end
  end
  check("1.1 Koepfe fuer Kollegen", #heads >= 2, #heads)
  local first = ns.Guild.ByMember()[1]
  check("1.1 eigener Char zuerst", first and first.me == true)
  local moppel
  for _, h in ipairs(heads) do if h.item.m.name == "Moppel Mops" then moppel = h end end
  check("1.1 Moppel hat einen Kopf", moppel ~= nil)
  if moppel then
    moppel._scripts.OnClick(moppel, "LeftButton"); tick()
    local coll = ns.Store.Setting("ui.guildCollapsed")
    check("1.1 Aufklappen im echten Store gemerkt", type(coll) == "table" and coll["Moppel Mops"] == true)
    local kid
    for _, f in ipairs(BM.frames) do
      if f._kind == "Button" and f.item and f._shown and f.under and not f.item.head and f.item.r.key == "Handfeind-Nur" then kid = f end
    end
    check("1.1 Kindzeile Hand-Eintrag", kid and kid.sub._text:find("von Hand eingetragen", 1, true) == 1, kid and kid.sub._text)
    if kid then kid._scripts.OnClick(kid, "LeftButton"); tick() end
    check("1.1 Klick zeigt das Gildenplakat", anyTextI("Handfeind Nur") ~= nil and anyTextI("G I L D E N B U C H") ~= nil)
    moppel = nil
    for _, f in ipairs(BM.frames) do if f.item and f.item.head and f._shown and f.item.m.name == "Moppel Mops" then moppel = f end end
    moppel._scripts.OnClick(moppel, "LeftButton"); tick()
    coll = ns.Store.Setting("ui.guildCollapsed")
    check("1.1 Zuklappen im echten Store", type(coll) == "table" and coll["Moppel Mops"] == nil)
  end
  check("1.1 ui.guildView im echten Store", ns.Store.Setting("ui.guildView") == "member")
  clean("1.1 Klappen")
  -- tooltip for the pure manual entry
  AM.AddEnemy("mouseover", { name = "Handfeind", surname = "Nur" })
  local tt = G.GameTooltip
  tt._unitName, tt._unit, tt._lines = "Handfeind", "mouseover", {}
  if BM.tooltipHook then BM.tooltipHook(tt, {}) end
  check("1.1 Tooltip GILDE: im Buch von", tt._lines[1] and tt._lines[1]:find("im Buch von Moppel", 1, true) ~= nil, tt._lines[1])
  AM.units.mouseover = nil
  -- house rules with the real Store: three sheets, sound
  ns.UI.OpenPanel("settings"); tick()
  for _, page in ipairs({ 2, 3, 1 }) do
    local t = frameWith(function(f) return f.page == page and f._scripts.OnClick end)
    t._scripts.OnClick(t); tick()
  end
  clean("1.1 Hausordnung")
  ns.Store.Setting("alert.soundKey", "gong"); ns.Store.Setting("alert.volume", 5)
  local before = #BM.soundCalls
  BM.Advance(5)
  ns.Look.Alarm("alert")
  local c = BM.soundCalls[#BM.soundCalls]
  check("1.1 Ton aus echtem Store: gong_5.ogg auf Master", #BM.soundCalls == before + 1 and c.file == "Interface\\AddOns\\DeathNote\\Media\\Sounds\\gong_5.ogg"
        and c.channel == "Master", c and tostring(c.file))
  ns.Store.Setting("alert.soundKey", "warnung")
  ns.UI.ClosePanel()
  VW.items[2]._scripts.OnClick(VW.items[2]); tick()
  tab("wanted"); tick()
  clean("1.1 Ende")
else
  check("1.1 ohne ByMember kein Umschalter", VW == nil or not VW:IsShown())
  print("Hinweis: ns.Guild.ByMember fehlt, 1.1-Gildenteil uebersprungen")
end

------------------------------------------------------------------------
-- Overview against the real contract functions (roles, open cases, Health, foreign guild entries)
------------------------------------------------------------------------
do
  local S = ns.Store
  check("GS Vertrag vorhanden: OpenCases, Weight, Count mit 4 Werten", type(S.OpenCases) == "function" and type(S.Weight) == "function"
        and select("#", S.Count()) == 4)
  -- accomplice with a real role
  local k = S.AddManual("Mit", "Laeufer"); local e = S.Get(k)
  e.manual = false
  S.ApplyKill({ name = "Mit", surname = "Laeufer" }, { t = time() - 30, zone = "Ödland", source = "recap", role = "assist" }, false)
  tick()
  ns.UI.ShowEnemy(k); tick()
  check("GS echte Rolle assist: Zeile 1× beteiligt", anyTextI("1× beteiligt") ~= nil, e.assists)
  check("GS Tat endet auf beteiligt", frameWith(function(f) return f.tag and f.tag._text == "beteiligt" and f:IsVisible() end) ~= nil)
  -- open case in the real log
  local J = S.Deaths()
  table.insert(J, 1, { t = time() - 5, zone = "Ödland", kind = "pvp", candidates = { k }, counted = true, me = "Varorak Narenmar" })
  if S.TouchJournal then S.TouchJournal() end
  ns:Fire("DEATH_RECORDED", J[1], nil); tick()
  local openTab = frameWith(function(f) return f.id == "open" and f.text end)
  check("GS Reiter Zu klären zaehlt den echten offenen Fall", openTab.text._text:find("|r$") ~= nil, openTab.text._text)
  tab("open"); tick()
  local cand = frameWith(function(f) return f.fn and f.text and f.text._text == "Mit Laeufer" and f:IsVisible() end)
  if cand then cand._scripts.OnClick(cand, "LeftButton"); tick() end
  check("GS Taeter festgelegt ueber Zu klären", J[1].killerKey == k and (S.OpenCases()) == 0)
  -- Guild: status line is Health().text, tab count is the fourth value of Count
  if ns.Guild and ns.Guild.Health then
    tab("guild"); tick()
    local h = ns.Guild.Health()
    check("GS Gilden-Statuszeile = Health().text", anyTextI(h.text) ~= nil, h.text)
    local _, _, _, foreign = ns.Guild.Count()
    local gt = frameWith(function(f) return f.id == "guild" and f.text end)
    -- 1.2.0: with the friends' book the tab is called "Guild & Friends" (it counts the selected source)
    local _, _, _, foreignAll = ns.Guild.Count("all")
    local label = ns.Friends and "Gilde & Freunde" or "Gilde"
    local n = ns.Friends and foreignAll or foreign
    check("GS Reiter Gilde zaehlt fremde", (n > 0 and gt.text._text == label .. "  " .. n) or (n == 0 and gt.text._text == label), gt.text._text .. " / " .. tostring(n))
  end
  tab("wanted"); S.Remove(k); tick()
  clean("GS echte Logik")
end

do
  local unk = {}
  for k in pairs(BM.unknown or {}) do unk[#unk + 1] = k end
  check("Mock: nur Methoden aus der Liste benutzt", #unk == 0, table.concat(unk, ", "))
end
print(("Zusammenspiel mit A: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
