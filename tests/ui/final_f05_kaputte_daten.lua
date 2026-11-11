-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen (Aufruf aus der Projektwurzel: luajit <datei> .)
-- Verstuemmelte SavedVariables mit Logik UND Oberflaeche (Fund 16 der ersten Jagd, Gegenprobe, und neue Felder).
-- (1) gezielt: lastSeen.t eines Eintrags im Gilden- bzw. Freundesbuch ist keine Zahl (P.Sanitize prueft nur "Tabelle");
--     der Brief an den Fixer nannte genau diese Stelle.
-- (2) gezielt: settings.lang als Zahl, Tabelle, unbekannte Kennung; settings als Text; huntExpire kaputt.
-- (3) Zufall: N Runden, je 1 bis 3 zufaellig zerstoerte Felder in settings, guild, friends; danach Login, Buch auf,
--     alle Reiter, Ansichten, Quellen, Hausordnung, je eine Nachricht S/J/E/K von Kollege und Freund.
-- Aufruf: luajit beleg_f05_kaputte_daten.lua <Projektkopie> [Runden=400] [Saat=1]
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local ROUNDS, SEED = tonumber(arg[2]) or 120, tonumber(arg[3]) or 1
local ADDON = DIR .. "/DeathNote"
local AM, BM, G
local pass, fail, lines = 0, 0, {}
local function erwartet(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "") end
end
local function copy(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local o = {}; seen[t] = o
  for k, v in pairs(t) do o[copy(k, seen)] = copy(v, seen) end
  return o
end
local FR = { "Fritz Frei" }
local function world(db, lang)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.locale = "deDE"
  local ns = AM.Load({ noLogin = true, db = db, lang = lang, before = function()
    AM.units.player.guild = "Die Testgilde"
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local function fmsg(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz Frei-Forever") end

local function fill(ns)
  local P = ns.Guild.Proto
  local t = _G.time()
  ns.Store.AddManual("Grimm", "Bart")
  gmsg(P.EncodeKill({ key = "Boese-Wicht", display = "Boese Wicht", class = "MAGE", level = 40, zone = "Zone", t = t - 30, victim = "Kollege Lang" }, "K"))
  gmsg(P.EncodeHunt({ key = "Boese-Wicht", t = t - 20, by = "Kollege Lang", why = "Grund" }))
  gmsg(P.EncodeHunt({ key = "Zwei-Wicht", t = t - 20, by = "Kollege Lang", why = "Grund" }))
  gmsg(P.EncodeBagged("Zwei-Wicht", "Kollege Lang", t))
  fmsg(P.EncodeKill({ key = "Boese-Wicht", display = "Boese Wicht", class = "MAGE", level = 40, zone = "Zone", t = t - 40, victim = "Fritz Frei" }, "K"))
  fmsg(P.EncodeKill({ key = "Drei-Wicht", display = "Drei Wicht", class = "MAGE", level = 40, zone = "Zone", t = t - 45, victim = "Fritz Frei" }, "K"))
  fmsg(P.EncodeHunt({ key = "Drei-Wicht", t = t - 20, by = "Fritz Frei", why = "Grund" }))
  ns.Guild.Release("Vier-Wicht", { to = "all", why = "meins" })
  ns.Guild.HideHunt("Zwei-Wicht", true)
  ns.Store.Setting("guild.sightings", true)
  -- eine Sichtung, damit lastSeen in beiden Buechern und beiden Listen steht
  AM.AddEnemy("mouseover", { name = "Boese", surname = "Wicht", guid = "Player-1-BW", level = 40 })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick(1)
  AM.units.mouseover = nil
  tick(10)
end

-- alles einmal anfassen; liefert die Zahl der Fehler
local function drive(ns)
  local P = ns.Guild.Proto
  local t = _G.time()
  tick(40)
  pcall(function()
    gmsg(P.EncodeSight("Boese-Wicht", "Zone", t))
    fmsg(P.EncodeSight("Boese-Wicht", "Zone", t))
    fmsg(P.EncodeSight("Drei-Wicht", "Zone", t))
    gmsg(P.EncodeHunt({ key = "Neu-Wicht", t = t, by = "Kollege Lang", why = "neu" }))
    gmsg(P.EncodeBagged("Boese-Wicht", "Kollege Lang", t))
    gmsg(P.EncodeKill({ key = "Boese-Wicht", display = "Boese Wicht", zone = "Zone", t = t - 5, victim = "Kollege Lang" }, "K"))
    fmsg(P.EncodeHello(0, "1.2.0"))
    gmsg(P.EncodeHello(0, "1.2.0"))
  end)
  tick(15)
  ns:Fire("TOGGLE_UI"); tick()
  for _, id in ipairs({ "wanted", "open", "journal", "guild" }) do
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts and f._scripts.OnClick then pcall(f._scripts.OnClick, f, "LeftButton"); break end
    end
    tick()
  end
  if ns.UI and ns.UI.SetGuildView then
    for _, v in ipairs({ "hunt", "enemy", "member" }) do
      ns.UI.SetGuildView(v); tick()
      for _, src in ipairs({ "all", "guild", "friends" }) do ns.UI.SetGuildSource(src); tick() end
    end
    ns.UI.ShowHunts("Boese-Wicht"); tick()
    ns.UI.OpenPanel("settings"); tick()
    for _, f in ipairs(BM.frames) do
      local fs = f.text
      local tx = type(fs) == "table" and fs._text
      if (tx == ns.L.SHEET_BOOK or tx == ns.L.SHEET_ALERT or tx == ns.L.SHEET_GUILD) and f._scripts.OnClick then pcall(f._scripts.OnClick, f, "LeftButton"); tick() end
    end
    ns.UI.ClosePanel(); tick()
  end
  AM.AddEnemy("mouseover", { name = "Boese", surname = "Wicht", guid = "Player-1-BW", level = 40 })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick(1)
  _G.SlashCmdList.DEATHNOTE("gilde"); _G.SlashCmdList.DEATHNOTE("freunde"); _G.SlashCmdList.DEATHNOTE("lang")
  _G.SlashCmdList.DEATHNOTE("probe")
  tick(30)
  AM.FireEvent("PLAYER_LOGOUT")
  return #AM.errors + #BM.violations, AM.errors[1] or BM.violations[1]
end

-- Grundbestand einmal erzeugen
local base
do
  local ns = world(nil)
  tick(40)
  fill(ns)
  AM.FireEvent("PLAYER_LOGOUT")
  erwartet("Vorbedingung: Grundbestand ohne Fehler", #AM.errors == 0, AM.errors[1])
  base = copy(_G.DeathNoteDB)
  local l = base.guild.lists["Die Testgilde"]
  erwartet("Vorbedingung: lastSeen im Gildenbuch", l and l.enemies["Boese-Wicht"] and type(l.enemies["Boese-Wicht"].lastSeen) == "table")
end
do
  local n, err = drive(world(copy(base)))
  erwartet("Vorbedingung: unversehrter Bestand laeuft ohne Fehler", n == 0, err)
end

-- (1) gezielt
for _, bad in ipairs({ "gestern", true, {} }) do
  local db = copy(base)
  db.guild.lists["Die Testgilde"].enemies["Boese-Wicht"].lastSeen.t = bad
  local n, err = drive(world(db))
  erwartet("Gildenbuch: lastSeen.t = " .. type(bad) .. " wirft keinen Fehler", n == 0, tostring(n) .. " Fehler, erster: " .. tostring(err))
  db = copy(base)
  db.friends.enemies["Boese-Wicht"].lastSeen.t = bad
  n, err = drive(world(db))
  erwartet("Freundesbuch: lastSeen.t = " .. type(bad) .. " wirft keinen Fehler", n == 0, tostring(n) .. " Fehler, erster: " .. tostring(err))
end

-- (2) Einstellungen
local SETTINGS = {
  { "lang als Zahl", function(db) db.settings.lang = 5 end },
  { "lang als Tabelle", function(db) db.settings.lang = { "deDE" } end },
  { "lang unbekannt", function(db) db.settings.lang = "xxXX" end },
  { "lang leer", function(db) db.settings.lang = "" end },
  { "langAsked als Text", function(db) db.settings.langAsked = "ja" end },
  { "settings als Text", function(db) db.settings = "kaputt" end },
  { "settings.guild als Zahl", function(db) db.settings.guild = 7 end },
  { "huntExpire als Text", function(db) db.settings.guild.huntExpire = "nie" end },
  { "huntExpire unendlich", function(db) db.settings.guild.huntExpire = math.huge end },
  { "huntExpire negativ", function(db) db.settings.guild.huntExpire = -30 end },
  { "guildSource als Zahl", function(db) db.settings.ui.guildSource = 7 end },
  { "guildView unbekannt", function(db) db.settings.ui.guildView = "liste" end },
  { "friends als Text", function(db) db.friends = "weg" end },
  { "ties als Zahl", function(db) db.friends.ties = 3 end },
  { "huntHidden als Text", function(db) db.guild.huntHidden = "x" end },
}
for _, s in ipairs(SETTINGS) do
  local db = copy(base)
  s[2](db)
  local ok, n, err = pcall(function() return drive(world(db, false)) end)
  erwartet("Einstellung " .. s[1], ok and n == 0, ok and (tostring(n) .. " Fehler, erster: " .. tostring(err)) or n)
end

-- (3) Zufall
math.randomseed(SEED)
local JUNK = { function() return "text" end, function() return 12345 end, function() return -1 end, function() return true end,
  function() return {} end, function() return { t = "x", by = 5 } end, function() return 0 / 0 end, function() return math.huge end,
  function() return ("x"):rep(300) end, function() return "a|cffff0000b" end, function() return nil end, function() return false end,
  function() return { 1, 2, 3 } end, function() return 1e15 end }
local function paths(t, prefix, out, depth)
  for k, v in pairs(t) do
    out[#out + 1] = { t, k }
    if type(v) == "table" and depth < 7 then paths(v, prefix, out, depth + 1) end
  end
end
local crashes, kinds = 0, {}
for round = 1, ROUNDS do
  local db = copy(base)
  local all = {}
  for _, top in ipairs({ "settings", "guild", "friends" }) do if type(db[top]) == "table" then all[#all + 1] = { db, top }; paths(db[top], top, all, 0) end end
  local what = {}
  for _ = 1, math.random(1, 3) do
    local p = all[math.random(#all)]
    local j = JUNK[math.random(#JUNK)]()
    if type(p[1]) == "table" then
      if math.random() < 0.15 then
        local fk = JUNK[math.random(#JUNK)]()
        if fk == nil or fk ~= fk then fk = "x" end
        p[1][fk] = j   -- fremder Schluessel
      else p[1][p[2]] = j end
      what[#what + 1] = tostring(p[2]) .. "=" .. type(j)
    end
  end
  local ok, n, err = pcall(function() return drive(world(db)) end)
  if not ok or n > 0 then
    crashes = crashes + 1
    local e = tostring(ok and err or n):gsub("^.-([%w_]+%.lua:%d+)", "%1")
    local id = e:match("^([%w_]+%.lua:%d+)") or e:sub(1, 60)
    if not kinds[id] then kinds[id] = { n = 0, first = table.concat(what, ", "), err = e:sub(1, 150) } end
    kinds[id].n = kinds[id].n + 1
  end
end
local list = {}
for id, k in pairs(kinds) do list[#list + 1] = ("%s (%d mal; zuerst bei %s): %s"):format(id, k.n, k.first, k.err) end
table.sort(list)
erwartet(("Zufall: %d Runden ohne Fehler"):format(ROUNDS), crashes == 0, crashes .. " Runden mit Fehler, " .. #list .. " Stellen")
io.write(("beleg_f05_kaputte_daten %3d gruen, %d rot\n"):format(pass, fail))
for _, l in ipairs(lines) do io.write(l .. "\n") end
for _, l in ipairs(list) do io.write("    Stelle: " .. l .. "\n") end
os.exit(fail == 0 and 0 or 1)
