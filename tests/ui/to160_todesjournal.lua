-- 1.6.0 deaths (UI): the death log's views "Players | All | Causes" (default All), deaths by creatures and the world
-- mixed with the deaths by players and told apart by a small sign, the place as a link to the map, the view Causes with
-- the stamp on number one, the switch in the foot of such a file, the awards for dying on the rap sheet, the dry
-- remark per kind (German and English only). Still five tabs. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
function J.world(WT, code)
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  -- one clock for both mocks (as tests/belege/_kopf_hu.lua): the remarks' quiet time runs on time()
  rawset(BM.G, "time", function() return math.floor(AM.epoch + AM.now) end)
  local ns = AM.Load({ noLogin = true, files = files })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua", "SceneMap.lua", "FatesUI.lua", "Humor.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end

local function visibleText(W, s)
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(s, 1, true) and f:IsVisible() then return f end
  end
end
local function rowsShown(W)
  local out = {}
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "Button" and f.item ~= nil and f.under and f:IsVisible() then out[#out + 1] = f end
  end
  table.sort(out, function(a, b) return (a._points[1][5] or 0) > (b._points[1][5] or 0) end)
  return out
end
local function viewWord(W, view)
  for _, f in ipairs(W.BM.frames) do if f.fateView and f.view == view then return f end end
end
local function click(f) f._scripts.OnClick(f, "LeftButton") end
local function creature(W, npc, name, spell)
  local ns = W.ns
  local j = { t = time(), kind = "pve", zone = "Brachland", subzone = "Wegkreuz", mapID = 1413, x = 51.5, y = 30.2,
    me = "Ich Selbst", myLevel = 30, counted = true, candidates = {}, cause = { art = "creature", name = name, npc = npc, spell = spell } }
  ns.Store.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, nil)
  W.tick(1)
  return j
end

for _, code in ipairs({ "deDE", "enUS", "frFR" }) do
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  W.AM.Advance(100)
  -- a death by a player, then two by creatures, one fall
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", class = "ROGUE", level = 30 },
    { t = time() - 50, zone = "Brachland", source = "recap" }, true)
  local pj = { t = time() - 50, zone = "Brachland", kind = "pvp", sure = true, counted = true, killerKey = key,
    killerName = "Grimm Bart", me = "Ich Selbst", candidates = {} }
  ns.Store.RecordDeath(pj)
  creature(W, 3100, "Stachelebermutter", "Rammen")
  creature(W, 3100, "Stachelebermutter", "Rammen")
  local fj = { t = time(), kind = "pve", zone = "Tausend Nadeln", mapID = 1441, counted = true, candidates = {},
    cause = { art = "env", env = "fall" } }
  ns.Store.RecordDeath(fj); ns:Fire("DEATH_RECORDED", fj, nil); W.tick(1)
  ns.UI.Open(); W.settle()
  ns.UI.SetFilter("journal"); W.settle()

  -- the view words
  local all, players, causes = viewWord(W, "all"), viewWord(W, "players"), viewWord(W, "causes")
  J.check(code .. ": drei Ansichtswoerter sichtbar", all and players and causes and all:IsVisible() and causes:IsVisible())
  J.check(code .. ": Woerter aus der Sprachdatei", all and all.text._text == L.FATE_VIEW_ALL and causes.text._text == L.FATE_VIEW_CAUSES,
    all and all.text._text)
  J.check(code .. ": Standard ist Alles", ns.FatesUI.Mode() == "all" and all.mark:IsShown())
  local rows = rowsShown(W)
  J.check(code .. ": Alles zeigt vier Tode", #rows == 4, #rows)
  J.check(code .. ": neuester zuerst (Sturz)", rows[1] and rows[1].name._text == L.FATE_ENV_FALL, rows[1] and rows[1].name._text)
  J.check(code .. ": Kreatur mit Namen", rows[2] and rows[2].name._text == "Stachelebermutter")
  J.check(code .. ": Spielertod unten, mit Totenkopf", rows[4] and rows[4].item == pj and rows[4].skull:IsShown()
    and not (rows[4].fateSign and rows[4].fateSign:IsShown()))
  J.check(code .. ": Kreatur mit eigenem Zeichen statt Totenkopf", rows[2] and rows[2].fateSign and rows[2].fateSign:IsShown()
    and not rows[2].skull:IsShown())
  local c1 = rows[1] and rows[1].fateSign and rows[1].fateSign._tcoord
  local c2 = rows[2] and rows[2].fateSign and rows[2].fateSign._tcoord
  J.check(code .. ": Sturz und Kreatur haben verschiedene Zeichen", c1 and c2 and c1[1] ~= c2[1], c1 and c1[1])
  J.check(code .. ": Art als Vermerk rechts", rows[2] and rows[2].mark._text == L.FATE_ART_CREATURE, rows[2] and rows[2].mark._text)
  J.check(code .. ": Reiter zaehlt alle Tode", visibleText(W, L.TAB_DEATHLOG) and visibleText(W, L.TAB_DEATHLOG)._text:find("4", 1, true))

  -- the file of a creature's death: place as a link, the name, the note
  click(rows[2]); W.settle()
  J.check(code .. ": Akte nennt die Kreatur", visibleText(W, "Stachelebermutter") ~= nil)
  J.check(code .. ": Akte sagt kein Alarm", visibleText(W, L.FATE_NOTE) ~= nil)
  local D = ns.UI.JK and W.BM.frames and nil
  local placeHit
  for _, f in ipairs(W.BM.frames) do if f.placeText and f.place and f:IsVisible() then placeHit = f end end
  J.check(code .. ": Ort ist ein Link zur Karte", placeHit ~= nil and placeHit.place.mapID == 1413)
  if placeHit then
    local shown
    local orig = ns.SceneMap and ns.SceneMap.Show
    if ns.SceneMap then ns.SceneMap.Show = function(p) shown = p end end
    placeHit._scripts.OnClick(placeHit, "LeftButton")
    if ns.SceneMap then ns.SceneMap.Show = orig end
    J.check(code .. ": Klick zeigt den Ort", shown and shown.mapID == 1413 and shown.x == 51.5)
  end

  -- Players: as before
  click(players); W.settle()
  rows = rowsShown(W)
  J.check(code .. ": Spieler zeigt nur den Spielertod", #rows == 1 and rows[1].item == pj, #rows)
  J.check(code .. ": Wahl bleibt gespeichert", ns.Store.Setting("ui.journalView") == "players")

  -- Causes: the ranking, no stamp below three deaths
  click(causes); W.settle()
  rows = rowsShown(W)
  J.check(code .. ": Ursachen: zwei Ursachen", #rows == 2, #rows)
  J.check(code .. ": Ursachen: Eber vorn mit 2", rows[1] and rows[1].item.name == "Stachelebermutter" and rows[1].item.n == 2)
  J.check(code .. ": Ursachen: Zeichen rechts", rows[1] and rows[1].fateSign and rows[1].fateSign:IsShown()
    and rows[1].fateSign._points[1][1] == "TOPRIGHT")
  J.check(code .. ": Kopf der Seite", visibleText(W, L.FATE_HEAD) ~= nil)
  local stamp = visibleText(W, L.FATE_STAMP)
  J.check(code .. ": kein Stempel unter drei Toden", stamp == nil)
  creature(W, 3100, "Stachelebermutter", "Rammen"); W.settle()
  J.check(code .. ": Stempel auf der Nummer eins ab drei Toden", visibleText(W, L.FATE_STAMP) ~= nil)
  J.check(code .. ": Akte nennt die Zahl", visibleText(W, (Fmt or ns.F)(L.FATE_KILLED, { times = ns.Look.Times(3) })) ~= nil)
  -- a death asked for from outside (map pin) while the view shows causes: the view All, the death selected
  ns.UI.ShowCase(pj); W.settle()
  J.check(code .. ": Tatort aus der Karte zeigt die Ansicht Alles", ns.FatesUI.Mode() == "all" and ns.UI.JK.state.deathRef == pj)
  J.check(code .. ": und die Akte des Spielertods", visibleText(W, "Grimm Bart") ~= nil and visibleText(W, L.FATE_HEAD) == nil)
  ns.FatesUI.SetMode("causes"); W.settle()
  -- another tab and back: the head is the death file's again, no stamp, no sign on other rows
  ns.UI.SetFilter("wanted"); W.settle()
  local stray = false
  for _, r in ipairs(rowsShown(W)) do if r.fateSign and r.fateSign:IsShown() then stray = true end end
  J.check(code .. ": Gesucht ohne Zeichen der Ursachen", not stray)
  J.check(code .. ": Woerter nur im Todesjournal", not all:IsVisible())
  ns.FatesUI.SetMode("all"); ns.UI.SetFilter("journal"); W.settle()
  click(rowsShown(W)[4] or rowsShown(W)[1]); W.settle()
  J.check(code .. ": Kopf wieder der Fall", visibleText(W, L.CASE_HEAD) ~= nil and visibleText(W, L.FATE_HEAD) == nil)
  J.check(code .. ": kein Stempel in einer anderen Akte", visibleText(W, L.FATE_STAMP) == nil)

  -- search finds a creature by name
  ns.FatesUI.SetMode("all"); W.settle()
  local search = W.G.DeathNoteSearch
  search:SetText("stachel"); search._scripts.OnTextChanged(search); W.settle()
  rows = rowsShown(W)
  J.check(code .. ": Suche findet die Kreatur", #rows == 3 and rows[1].item.art == "creature", #rows)
  search:SetText(""); search._scripts.OnTextChanged(search); W.settle()

  -- the switch: in the foot of the file of a death by a creature (every sheet of the House Rules is full)
  local function fateSwitch()
    for _, f in ipairs(W.BM.frames) do
      if f._kind == "CheckButton" and f.opt and f.opt.path == "fates.on" and f:IsVisible() then return f end
    end
  end
  click(rowsShown(W)[1]); W.settle()
  local cb = fateSwitch()
  J.check(code .. ": Schalter in der Akte eines Kreaturentods", cb ~= nil and cb.label._text == L.OPT_FATES)
  J.check(code .. ": Schalter steht an", cb and cb:GetChecked() and cb.cross:IsShown())
  if cb then
    cb:SetChecked(false); cb._scripts.OnClick(cb, "LeftButton")
    J.check(code .. ": aus gespeichert", ns.Store.Setting("fates.on") == false and not cb.cross:IsShown())
  end
  ns.FatesUI.SetMode("players"); W.settle()
  click(rowsShown(W)[1]); W.settle()
  J.check(code .. ": kein Schalter in der Akte eines Spielertods", fateSwitch() == nil)
  ns.FatesUI.SetMode("all"); W.settle()
  ns.UI.OpenPanel("settings"); W.settle()
  local SS
  for _, f in ipairs(W.BM.frames) do if f.pageA and f.pageR then SS = f end end
  for i = 1, 4 do
    if SS and SS.tabs[i] and SS.tabs[i]:IsShown() then
      SS.tabs[i]._scripts.OnClick(SS.tabs[i]); W.settle()
      J.check(code .. ": Blatt " .. i .. " rollt nicht", (SS.page.range or 0) == 0, SS.page.range)
    end
  end
  ns.UI.ClosePanel()

  -- the rap sheet: the awards for dying (fall is won)
  ns.UI.SetFilter("record"); W.settle()
  local coins, won = 0, 0
  for _, f in ipairs(W.BM.frames) do
    if f.fatePart and f._kind == "Button" and f:IsVisible() then
      coins = coins + 1
      if f.tip and f.tip[1] == L.FATE_AW_FALL and f.tip[3] ~= L.RECORD_AWARD_OPEN then won = won + 1 end
    end
  end
  J.check(code .. ": acht Muenzen fuers Sterben", coins == #ns.Fates.AWARDS, coins)
  J.check(code .. ": Sturz gewonnen", won == 1)
  J.check(code .. ": Ueberschrift der Muenzen", visibleText(W, ns.UI.JK.Spaced(L.FATE_AWARDS)) ~= nil)

  -- still five tabs
  local tabs = 0
  for _, t in ipairs(W.G.DeathNoteFrame and W.G.DeathNoteFrame.tabs or {}) do if t:IsShown() then tabs = tabs + 1 end end
  J.check(code .. ": fuenf Reiter", tabs == 5, tabs)

  -- the dry remark per kind: German and English only
  for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 1 end
  ns.Store.Setting("fates.on", true)
  local said
  ns.Humor.said = nil
  W.tick(2000)
  local wj = { t = time(), kind = "pve", zone = "Z", counted = true, candidates = {}, cause = { art = "env", env = "drown" } }
  ns.Store.RecordDeath(wj); ns:Fire("DEATH_RECORDED", wj, nil)
  said = ns.Humor.said          -- (one frame later the award "drowned" may add its own remark)
  W.tick(1)
  if code == "frFR" then
    J.check(code .. ": kein Spruch in anderen Sprachen", said == nil)
  else
    local pool = ns.Humor.TEXTS[code].POOL.pve_drown
    local hit = false
    for _, s in ipairs(pool) do if s == said then hit = true end end
    J.check(code .. ": Spruch aus dem Topf Ertrinken", hit, said)
  end
  J.check(code .. ": keine Fehler", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])
end
J.done()
