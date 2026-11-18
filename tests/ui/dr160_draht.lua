-- 1.6.0 wiring: a call for help and a sighting in the guild chronicle (their lines, the pin in the margin wears the
-- map's pin of its kind and opens the place), the map's pins of a call and a sighting have pictures of their own (not
-- the guild's or the friend's), the legend shows them; in 21 languages the lines have no placeholder and stay inside
-- the page. The line after the update to 1.6.0 (news160): once, placeholders filled with the book's words, never in
-- combat, the line of 1.5.0 first for whoever missed it, never for a new installation.
-- Use: luajit tests/ui/dr160_draht.lua [project folder]. All names are made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/dr160_draht.lua"
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
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.click(b) if b then b._scripts.OnClick(b, "LeftButton") end; W.tick() end
  ns:Fire("TOGGLE_UI"); W.tick(30); W.settle()
  return W
end

-- a call with an attacker, a friend's call, three sightings of one killer (one line) and one of another
local function fill(W)
  local ns, t = W.ns, _G.time()
  ns:Fire("HELP_CALL", { t = t - 120, at = t - 120, by = "Liora", from = "guild", mapID = 1434, x = 41.2, y = 56.7,
    key = "Grimwald-Aschbrand", display = "Grimwald Aschbrand", zone = "Schlingendorntal" })
  ns:Fire("HELP_CALL", { t = t - 900, at = t - 900, by = "Olaf", from = "friend", mapID = 1434, x = 12, y = 13,
    zone = "Schlingendorntal" })
  for i, by in ipairs({ "Bertram", "Liora", "Bertram" }) do
    ns:Fire("SIGHTING", { key = "Velka-Dornherz", name = "Velka Dornherz", by = by, t = t - 400 + i * 60, at = t,
      mapID = 1434, x = 30 + i, y = 40, zone = "Schlingendorntal", src = "guild" })
  end
  ns:Fire("SIGHTING", { key = "Grimwald-Aschbrand", name = "Grimwald Aschbrand", by = "Bertram", t = t - 1800, at = t,
    mapID = 1434, x = 50, y = 50, zone = "Arathihochland", src = "guild" })
  W.tick(1); W.settle()
end

local W = world("deDE")
local ns, L = W.ns, W.ns.L
local UI, GLUI, SM = ns.UI, ns.GuildLogUI, ns.SceneMap
fill(W)
UI.SetFilter("guild"); W.tick(); W.settle()
local _, PL = GLUI.Frames()
GLUI.Open(); W.settle()
local function lineWith(needle)
  for _, b in ipairs(PL.lines) do
    if b:IsVisible() and b.event and tostring(b.text._text):find(needle, 1, true) then return b end
  end
end

------------------------------------------------------------------------
-- 1) the lines of calls and sightings, the pin of their kind in the margin
------------------------------------------------------------------------
local lCall = lineWith("Liora rief um Hilfe: Schlingendorntal, Angreifer Grimwald Aschbrand")
check("Ruf: eigener Satz mit Angreifer", lCall ~= nil)
local lFriend = lineWith("Olaf rief um Hilfe: Schlingendorntal")
check("Ruf eines Freundes", lFriend ~= nil)
local lMany = lineWith("Velka Dornherz 3× gesehen, zuletzt von Bertram: Schlingendorntal")
check("drei Sichtungen: eine Zeile mit Zahl", lMany ~= nil)
local n = 0
for _, b in ipairs(PL.lines) do
  if b:IsVisible() and b.event and tostring(b.text._text):find("Velka Dornherz", 1, true) then n = n + 1 end
end
check("Velka nur einmal", n == 1, n)
local lSight = lineWith("Bertram hat Grimwald Aschbrand gesehen: Arathihochland")
check("Sichtung: eigener Satz", lSight ~= nil)
local function texOf(b) return b and b.pin and b.pin.tex and tostring(b.pin.tex._tex or "") or "" end
check("Ruf: Nadel am Rand mit dem Bild des Rufs", lCall and lCall.pin:IsVisible() and texOf(lCall):find("scene_call", 1, true),
  texOf(lCall))
check("Sichtung: Nadel am Rand mit dem Auge", lSight and lSight.pin:IsVisible() and texOf(lSight):find("scene_sight", 1, true),
  texOf(lSight))
local tint = SM.TINT.call
local r, g
if lCall then r, g = lCall.pin.tex:GetVertexColor() end
check("Ruf: getönt wie auf der Karte", r and math.abs(r - tint[1]) < 0.01 and math.abs(g - tint[2]) < 0.01, r)
local shown
SM.Show = function(place) shown = place end
W.click(lSight and lSight.pin)
check("Nadel der Sichtung öffnet die Karte dort", shown and shown.mapID == 1434 and shown.x == 50, shown and shown.mapID)
GLUI.Close()

------------------------------------------------------------------------
-- 2) the map's pins: own pictures, the legend
------------------------------------------------------------------------
check("Ruf: eigenes Bild, nicht das der Gilde", SM.TEX.call ~= SM.TEX.guild and SM.TEX.call ~= SM.TEX.friend, SM.TEX.call)
check("Sichtung: eigenes Bild, nicht das des Freundes", SM.TEX.sight ~= SM.TEX.friend and SM.TEX.sight ~= SM.TEX.guild
  and SM.TEX.sight ~= SM.TEX.call, SM.TEX.sight)
local files = {}
for kind, f in pairs(SM.TEX) do
  local h = io.open(ADDON .. "/Media/" .. f, "rb")
  check("Bild da: " .. kind, h ~= nil, f)
  if h then
    local head = h:read(18); h:close()
    -- 32-bit uncompressed TGA, 64x64 like the other pins
    check("Bild " .. kind .. ": TGA 64x64, 32 bit", head and head:byte(3) == 2 and head:byte(13) == 64 and head:byte(15) == 64
      and head:byte(17) == 32)
  end
  files[f] = (files[f] or 0) + 1
end
local dup = 0
for _, c in pairs(files) do if c > 1 then dup = dup + 1 end end
check("jede Nadelart ein eigenes Bild", dup == 0, dup)
local leg = SM.Legend()
check("Legende: Ruf mit seinem Bild", leg[5] and leg[5]:find("scene_call", 1, true) and leg[5]:find(L.SCENE_LEG_CALL, 1, true), leg[5])
check("Legende: Sichtung mit dem Auge", leg[6] and leg[6]:find("scene_sight", 1, true) and leg[6]:find(L.SCENE_LEG_SIGHT, 1, true),
  leg[6])
check("keine Fehler (deDE)", #W.AM.errors == 0 and #W.BM.violations == 0, tostring(W.AM.errors[1] or W.BM.violations[1]))

------------------------------------------------------------------------
-- 3) 21 languages: the lines without placeholders, inside the page
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function inside(a, c) return a[1] >= c[1] - 0.5 and a[3] <= c[3] + 0.5 and a[2] >= c[2] - 0.5 and a[4] <= c[4] + 0.5 end
for _, code in ipairs(CODES) do
  W = world(code)
  fill(W)
  W.ns.UI.SetFilter("guild"); W.tick(); W.settle()
  local _, Pl = W.ns.GuildLogUI.Frames()
  W.ns.GuildLogUI.Open(); W.settle()
  local problems, seen = {}, 0
  local function rect(f) local l, bt, rt, t = W.BM.RectUI(f); return l and { l, bt, rt, t } or nil end
  local pr = rect(Pl)
  for _, ln in ipairs(Pl.lines) do
    if ln:IsVisible() and ln.event and (ln.event.k == "call" or ln.event.k == "sight") then
      seen = seen + 1
      local txt = tostring(ln.text._text)
      if txt:find("{", 1, true) then problems[#problems + 1] = "placeholder " .. txt end
      if not txt:find(ln.event.zone or "?", 1, true) then problems[#problems + 1] = "no zone " .. txt end
      local rr = rect(ln.text)
      if rr and pr and not inside(rr, pr) then problems[#problems + 1] = "outside " .. txt end
      if not ln.pin:IsVisible() then problems[#problems + 1] = "no pin " .. txt end
    end
  end
  if seen ~= 4 then problems[#problems + 1] = "lines " .. seen end
  if #W.AM.errors > 0 or #W.BM.violations > 0 then problems[#problems + 1] = tostring(W.AM.errors[1] or W.BM.violations[1]) end
  check(code .. ": Ruf und Sichtung in der Chronik", #problems == 0, table.concat(problems, "; "))
end

------------------------------------------------------------------------
-- 4) the line after the update to 1.6.0
------------------------------------------------------------------------
local AM, BM, G
local function tocFiles()
  local out = {}
  for line in io.lines(ADDON .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") and line:find("%.lua$") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end
local function whole(o)
  o = o or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.Reset()
  AM.locale = o.client or "deDE"
  AM.client = o.client or "deDE"
  _G.DeathNoteDB = o.db
  AM.inCombat, BM.combat = o.combat or false, o.combat or false
  local LOGIC = {}
  for _, f in ipairs(AM.FILES) do LOGIC[f] = true end
  local ns, ui = {}, false
  for _, f in ipairs(tocFiles()) do
    if f == "Alert.lua" then ui = true end
    if LOGIC[f] or not ui then assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns) else BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.ns = ns
  AM.FireEvent("ADDON_LOADED", "DeathNote")
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function plain(s) return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function said(text)
  local c = 0
  for _, l in ipairs(AM.chat) do if plain(l):find(text, 1, true) then c = c + 1 end end
  return c
end
local function news(ns) return plain(ns.Start.NewsLine()) end

do -- from 1.5.0: one line of 1.6.0, then never again
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true, news140 = true }, enemies = {}, deaths = {} }
  local ns = whole({ db = db })
  tick(3)
  check("news160: nicht sofort", said(news(ns)) == 0)
  tick(60)
  check("news160: eine Zeile", said(news(ns)) == 1, AM.chat[#AM.chat])
  check("news160: nicht die Zeile von 1.5.0", said(plain(ns.L.CHAT_NEWS_150)) == 0)
  local line = news(ns)
  check("news160: Platzhalter gefüllt", not line:find("{", 1, true), line)
  check("news160: nennt Todesjournal, Gilde, Hausordnung, Blatt, Schalter", line:find(ns.L.TAB_DEATHLOG, 1, true)
    and line:find(ns.L.TAB_GUILD, 1, true) and line:find(ns.L.HEAD_RULES, 1, true) and line:find(ns.L.OPT_G_LAYERSIGHT, 1, true)
    and line:find("Tastaturbelegung", 1, true), line)
  check("news160: Merker", db.settings.news160 == true)
  ns = whole({ db = db }); tick(60)
  check("news160: nach dem Neuladen keine zweite", said(news(ns)) == 0)
  check("news160: keine Fehler", #AM.errors == 0 and #BM.violations == 0, tostring(AM.errors[1] or BM.violations[1]))
end

do -- from 1.4.x (1.5.0 was never published): the line of 1.5.0 first (the new name), then the one of 1.6.0
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news140 = true }, enemies = {}, deaths = {} }
  local ns = whole({ db = db })
  tick(60)
  local i150, i160
  for i, l in ipairs(AM.chat) do
    if plain(l):find(plain(ns.L.CHAT_NEWS_150), 1, true) then i150 = i end
    if plain(l):find(news(ns), 1, true) then i160 = i end
  end
  check("aus 1.4: beide Zeilen, 1.5.0 zuerst", i150 and i160 and i150 < i160, tostring(i150) .. " " .. tostring(i160))
  check("aus 1.4: alle Merker", db.settings.news160 == true and db.settings.news150 == true and db.settings.news140 == true)
end

do -- in combat: waits for the end of the fight
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true }, enemies = {}, deaths = {} }
  local ns = whole({ db = db, combat = true })
  tick(30)
  check("news160: nichts im Kampf", said(news(ns)) == 0 and db.settings.news160 == nil)
  AM.inCombat, BM.combat = false, false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  check("news160: nach dem Kampf", said(news(ns)) == 1)
end

do -- a new installation: no line, all markers at once
  local ns = whole({ db = nil })
  tick(4)
  local d = rawget(G, "DeathNoteStart")
  if d and d.go then d.go._scripts.OnClick(d.go, "LeftButton") end
  tick(60)
  check("neu: keine Zeile", said(news(ns)) == 0 and said(plain(ns.L.CHAT_NEWS_150)) == 0)
  local st = _G.DeathNoteDB.settings
  check("neu: Merker sofort", st.news160 == true and st.news150 == true and st.news140 == true)
end

do -- English: the line in the client's words
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news150 = true, lang = "enUS" }, enemies = {}, deaths = {} }
  local ns = whole({ db = db, client = "enUS" })
  tick(60)
  local line = news(ns)
  check("enUS: eine Zeile mit Key Bindings und Revenge Book", said(line) == 1 and line:find("Key Bindings", 1, true)
    and line:find("Revenge Book", 1, true) and line:find("House Rules", 1, true), line)
end

io.write(("dr160 wiring: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
