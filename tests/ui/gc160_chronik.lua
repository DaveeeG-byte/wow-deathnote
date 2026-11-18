-- 1.6.0 guildlog: the guild's chronicle in the book (GuildLogUI.lua) with the real logic. The ribbon only in the guild
-- tab (not over the manual or the house rules), two pages over the book and the poster out of sight, back, another tab
-- or another selection closes it; a line opens the poster (guild entry, else the guest poster), the pin the map; the dot
-- on the guild tab; "recommend" (one GUILD line, then the wait on the button); the card (post into GUILD, the Discord
-- block over the sheet); the mouse wheel. 21 languages: every view's texts inside its page, nothing cut without a
-- tooltip, the view words side by side. Use: luajit tests/ui/gc160_chronik.lua [project folder]. All names are made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local GUILD = "Die Rostigen Nägel"
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
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua", "SceneMap.lua", "GuildLogUI.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, sent = {}, maps = {} }
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  _G.SendChatMessage = function(text, ch) W.sent[#W.sent + 1] = { text = text, ch = ch } end
  _G.IsInRaid, _G.IsInGroup = function() return false end, function() return false end
  _G.C_AddOns = { GetAddOnMetadata = function(_, f) if f == "Version" then return "1.6.0" end end }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.msg(sender, text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender .. "-Forever") end
  function W.click(b) if b then b._scripts.OnClick(b, "LeftButton") end; W.tick() end
  function W.guest() return rawget(BM.G, "DeathNoteShareGuest") end
  ns:Fire("TOGGLE_UI"); W.tick(30); W.settle()
  return W
end

-- the usual week: two members, deaths, a revenge, a bounty, a release, one death with its spot
local function fill(W, many)
  local ns = W.ns
  local P, t = ns.Guild.Proto, _G.time()
  W.msg("Bertram", P.EncodeHello(t - 86400, "1.6.0"))
  W.msg("Liora", P.EncodeHello(t - 86400, "1.5.0"))
  local function k(victim, key, ago, zone)
    W.msg(victim:match("^(%S+)"), P.EncodeKill({ key = key, display = key:gsub("%-", " "), class = "ROGUE", level = 60,
      zone = zone or "Schlingendorntal", t = t - ago, victim = victim }, "K"))
  end
  k("Liora Sturmwind", "Grimwald-Aschbrand", 7200)
  k("Bertram Eisenhut", "Grimwald-Aschbrand", 3600, "Arathihochland")
  W.msg("Liora", P.EncodePlace({ key = "Grimwald-Aschbrand", t = t - 7200, victim = "Liora Sturmwind", mapID = 1434,
    x = 41.2, y = 56.7 }))
  k("Liora Sturmwind", "Velka-Dornherz", 1800)
  W.tick(1)
  W.msg("Bertram", P.EncodeAvenged("Grimwald-Aschbrand", "Bertram Eisenhut", t - 60, "0"))
  W.msg("Liora", P.EncodeBounty("Velka-Dornherz", "Liora Sturmwind", 75, t - 900))
  W.msg("Bertram", P.EncodeHunt({ key = "Velka-Dornherz", display = "Velka Dornherz", t = t - 600, by = "Bertram Eisenhut",
    why = "Campt am Steg" }))
  if many then
    for i = 1, 40 do ns.GuildLog.Add("sight", { t = t - 5000 - i * 60, key = "Ziel" .. i .. "-Nr", by = "Liora Sturmwind" }) end
  end
  W.tick(12); W.settle()
end

local W = world("deDE")
local ns, L, Fmt = W.ns, W.ns.L, W.ns.F
local UI, GLUI, GL = ns.UI, ns.GuildLogUI, ns.GuildLog
fill(W)
local F = rawget(W.G, "DeathNoteFrame")
local R, PL, PR = GLUI.Frames()
local poster
for _, f in ipairs(W.BM.frames) do if f.current and f.buttons and f.share then poster = f:GetParent() end end

------------------------------------------------------------------------
-- 1) the ribbon: guild tab only, never over the manual or the house rules
------------------------------------------------------------------------
check("Band gebaut", R and PL and PR)
UI.SetFilter("wanted"); W.tick(); W.settle()
check("Band nicht im Reiter Gesucht", not R:IsVisible())
UI.SetFilter("guild"); W.tick(); W.settle()
check("Band im Reiter Gilde", R:IsVisible())
UI.OpenPanel("help"); W.tick()
check("Band weg unter der Gebrauchsanweisung", not R:IsVisible())
UI.ClosePanel(); W.tick()
check("Band wieder da nach der Gebrauchsanweisung", R:IsVisible())

------------------------------------------------------------------------
-- 2) open and close
------------------------------------------------------------------------
W.click(R); W.settle()
check("Klick aufs Band: zwei Seiten offen", PL:IsVisible() and PR:IsVisible() and GLUI.IsOpen())
local P = poster
check("Plakat unsichtbar unter der Chronik", P == nil or P:GetAlpha() == 0, P and P:GetAlpha())
local back
for _, f in ipairs(W.BM.frames) do
  if f._kind == "Button" and f.text and f.text._text == L.GLOG_BACK and f:IsVisible() then back = f end
end
W.click(back); W.settle()
check("Zurück zum Buch schließt", not PL:IsVisible() and not PR:IsVisible() and not GLUI.IsOpen())
check("Plakat wieder sichtbar", P == nil or P:GetAlpha() == 1)
GLUI.Open(); W.settle()
UI.SetFilter("journal"); W.tick(); W.settle()
check("Anderer Reiter schließt", not GLUI.IsOpen() and not PL:IsVisible())
UI.SetFilter("guild"); W.tick(); W.settle()
GLUI.Open(); W.settle()
UI.ShowGuildEntry("Velka-Dornherz"); W.tick(); W.settle()
check("Andere Auswahl (Klick auf einen Link) schließt", not GLUI.IsOpen())
GLUI.Open(); W.settle()
UI.OpenPanel("settings"); W.tick()
check("Hausordnung schließt", not GLUI.IsOpen())
UI.ClosePanel(); W.tick(); W.settle()

------------------------------------------------------------------------
-- 3) the chronicle's lines: poster, guest poster, pin
------------------------------------------------------------------------
GLUI.Open(); W.settle()
local function lineWith(needle)
  for _, b in ipairs(PL.lines) do
    if b:IsVisible() and b.event and tostring(b.text._text):find(needle, 1, true) then return b end
  end
end
local lAv = lineWith("Bertram hat Grimwald Aschbrand erwischt und Liora gerächt")
check("Rache als Satz mit dem Gerächten", lAv ~= nil)
local lPlace = lineWith("Liora wurde von Grimwald Aschbrand getötet")
check("Tod mit Tatort: Nadel am Rand", lPlace and lPlace.pin:IsVisible() and lPlace.pin.place ~= nil)
local shown
ns.SceneMap.Show = function(place) shown = place end
if lPlace then W.click(lPlace.pin) end
check("Nadel öffnet die Karte an der Stelle", shown and shown.mapID == 1434)
check("Kopf HEUTE über den Zeilen", PL.lines[1].head:IsVisible() and PL.lines[1].head._text == L.GLOG_TODAY)
W.click(lAv); W.settle()
check("Zeile öffnet das Plakat und schließt die Chronik", not GLUI.IsOpen() and F:IsShown())
-- a name in no book: the guest poster
GL.Add("call", { key = "Niemand-Hier", name = "Niemand Hier", by = "Liora Sturmwind" })
UI.SetFilter("guild"); W.tick(); W.settle()
GLUI.Open(); W.settle()
local lg = lineWith("Niemand Hier")
check("Zeile eines fremden Ereignisses da", lg ~= nil)
W.click(lg); W.settle()
check("Name in keinem Buch: Gast-Plakat", W.guest() and W.guest():IsShown())
if W.guest() then W.guest():Hide() end

------------------------------------------------------------------------
-- 4) the dot on the guild tab
------------------------------------------------------------------------
local gtab
for _, t in ipairs(F.tabs) do if t.id == "guild" then gtab = t end end
UI.SetFilter("wanted"); W.tick(); W.settle()
check("kein Punkt ohne Neues", not (gtab.glogDot and gtab.glogDot:IsVisible()))
W.AM.epoch = W.AM.epoch + 30
W.msg("Liora", ns.Guild.Proto.EncodeKill({ key = "Ork-Hau", display = "Ork Hau", class = "ROGUE", level = 60,
  zone = "Eschental", t = _G.time(), victim = "Liora Sturmwind" }, "K"))
W.tick(1); W.settle()
check("Punkt am Reiter Gilde nach einem neuen Tod", gtab.glogDot and gtab.glogDot:IsVisible())
check("Reitertext unverändert", not tostring(gtab.text._text):find("•", 1, true))
UI.SetFilter("guild"); W.tick(); W.settle()
check("Punkt weg im Reiter Gilde", not gtab.glogDot:IsVisible())
check("Band zählt das Neue", R.count._text == "1", R.count._text)
UI.SetFilter("wanted"); W.tick(); W.settle()
check("Punkt bleibt weg nach dem Blick", not gtab.glogDot:IsVisible())

------------------------------------------------------------------------
-- 5) recommend, post, Discord
------------------------------------------------------------------------
UI.SetFilter("guild"); W.tick(); W.settle()
GLUI.Open("holders"); W.settle()
local v = PR.holders
check("Kopfzeile Wer hat das Buch", tostring(v.line._text):find("3 in der Gilde haben das Buch", 1, true), v.line._text)
local older
for _, r in ipairs(v.rows) do if r:IsVisible() and tostring(r.name._text) == "Liora" then older = r end end
check("ältere Version markiert", older and tostring(older.ver._text):find("älter", 1, true), older and older.ver._text)
W.sent = {}
ns.Share.last = nil
W.click(v.rec); W.settle()
check("Empfehlen: eine Zeile in GUILD", #W.sent == 1 and W.sent[1].ch == "GUILD" and W.sent[1].text == GL.RecommendLine())
check("Knopf zeigt die Sperre", tostring(v.rec.text._text):find("Wieder in", 1, true), v.rec.text._text)
W.click(v.rec); W.settle()
check("zweiter Klick sendet nicht", #W.sent == 1)
check("Status sagt warum", tostring(v.status._text):find("Wieder in", 1, true), v.status._text)
GLUI.SetView("card"); W.settle()
local c = PR.card
check("Karte: Gilde im Kopf", c.guild._text == GUILD, c.guild._text)
check("Karte: Tode und gerächt", tostring(c.deaths._text):find("Tode", 1, true) and tostring(c.avenged._text):find("gerächt", 1, true))
ns.Share.last = nil
W.sent = {}
W.click(c.post); W.settle()
check("Aushängen: eine Zeile in GUILD", #W.sent == 1 and W.sent[1].ch == "GUILD" and W.sent[1].text:find(GUILD, 1, true))
W.click(c.copy); W.settle()
check("Discord: Block über dem Blatt, Blatt weg", c.box:IsVisible() and not c.sheet:IsVisible())
check("Discord: Block markiert mit Gilde", tostring(c.box.edit._text):find("**" .. GUILD .. "**", 1, true))
GLUI.SetView("avengers"); W.settle()
check("Discord-Block weg in einer anderen Ansicht", not c.box:IsVisible())
local av = PR.avengers
check("Rächer: Bertram vorn", tostring(av.rows[1].name._text):find("Bertram", 1, true), av.rows[1].name._text)
check("Rächer: eigene Zeile mit (du", (function()
  for _, r in ipairs(av.rows) do if r:IsVisible() and tostring(r.name._text):find("(du", 1, true) then return true end end
end)())
check("Meistgesucht: Grimwald vorn", tostring(av.wanted[1].name._text):find("Grimwald", 1, true))
GLUI.Close()

------------------------------------------------------------------------
-- 6) many events: the foot and the mouse wheel
------------------------------------------------------------------------
fill(W, true)
GLUI.Open(); W.settle()
check("Fuß: 1 bis … von …", tostring(PL.foot._text):find("^1 bis"), PL.foot._text)
PL._scripts.OnMouseWheel(PL, -1); W.tick()
check("Mausrad blättert", GLUI.state.offset == 3 and tostring(PL.foot._text):find("^4 bis"), PL.foot._text)
GLUI.Close()
check("keine Fehler (deDE)", #W.AM.errors == 0 and #W.BM.violations == 0, tostring(W.AM.errors[1] or W.BM.violations[1]))

------------------------------------------------------------------------
-- 7) 21 languages
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function inside(a, b) return a[1] >= b[1] - 0.5 and a[3] <= b[3] + 0.5 and a[2] >= b[2] - 0.5 and a[4] <= b[4] + 0.5 end
local function cutNoTip(fs)
  if not fs:IsVisible() or not fs.IsTruncated then return false end
  if not fs:IsTruncated() then return false end
  local o = fs.tipOwner or fs:GetParent()
  return not (o and (o.cutHooked or (o._scripts and o._scripts.OnEnter)))
end
for _, code in ipairs(CODES) do
  W = world(code)
  ns, L, UI, GLUI = W.ns, W.ns.L, W.ns.UI, W.ns.GuildLogUI
  fill(W)
  UI.SetFilter("guild"); W.tick(); W.settle()
  local function rect(f) local l, b, r, t = W.BM.RectUI(f); return l and { l, b, r, t } or nil end
  local problems = {}
  local Rb, Pl, Pr = GLUI.Frames()
  if not Rb:IsVisible() then problems[#problems + 1] = "ribbon missing" end
  for _, view in ipairs({ "holders", "avengers", "card" }) do
    GLUI.Open(view); W.settle()
    if view == "card" then GLUI.ShowDiscord(); W.settle() end
    for _, page in ipairs({ Pl, Pr }) do
      local pr = rect(page)
      for _, f in ipairs(W.BM.frames) do
        local o, under = f, false
        while o do if o == page then under = true end o = o._parent end
        if under and f ~= page and f:IsVisible() and (f._kind == "FontString" or f._kind == "Button") then
          local r = rect(f)
          local txt = tostring(f._text or (f.text and f.text._text))
          if r and not inside(r, pr) then problems[#problems + 1] = view .. ": outside " .. txt end
          if f._kind == "FontString" and cutNoTip(f) then problems[#problems + 1] = view .. ": cut " .. txt end
          if f._kind == "FontString" and f._text and f._text:find("{", 1, true) then problems[#problems + 1] = view .. ": placeholder " .. txt end
        end
      end
    end
    -- the view words side by side, inside the page
    local prev
    for _, t in ipairs(Pr.tabs) do
      local r = rect(t)
      if prev and r[1] < prev[3] - 0.5 then problems[#problems + 1] = "view words overlap" end
      prev = r
    end
    GLUI.Close()
  end
  if #W.AM.errors > 0 or #W.BM.violations > 0 then problems[#problems + 1] = tostring(W.AM.errors[1] or W.BM.violations[1]) end
  check(code .. ": Chronik, drei Ansichten, Band", #problems == 0, table.concat(problems, "; "))
end

io.write(("gc160 guild chronicle: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
