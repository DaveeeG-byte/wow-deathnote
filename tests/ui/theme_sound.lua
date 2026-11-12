-- 1.3.0: the alarm sound a cover suggests (Themes/<id>.lua, sound.alert; the workshop: "glocke") plays while the player
-- has chosen no sound himself. Only a new installation is without a stored sound: data of every older version keep
-- (or, from 1.0.x, get) "warnung", so nothing sounds different for them. The House Rules show the sound that plays;
-- picking one there stores it.
-- Call from the project root: luajit tests/ui/theme_sound.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/theme_sound.lua"
local ADDON = DIR .. "/DeathNote"
local okN, badN = 0, 0
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end
local function copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = copy(v) end
  return c
end

local function tocFiles()
  local out = {}
  for line in io.lines(ADDON .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") and line:find("%.lua$") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end

local AM, BM, G
local function world(db)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.Reset()
  AM.locale, AM.client = "deDE", "deDE"
  _G.DeathNoteDB = db
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
local function playing(ns) local s = ns.Look.SoundChoice(); return s and s.key end
local function stored() return _G.DeathNoteDB.settings.alert.soundKey end

-- 1) a new installation picks the workshop in the first-start window: its bell plays, nothing is stored; after a
-- reload the same; the House Rules show the bell; picking a sound there stores it
do
  local ns = world(nil)
  tick(3.2)
  ns.Start.Pick(nil, "trade")
  ns.Start.Go(); tick()
  check("new installation, workshop: cover active", ns.Theme.Id() == "trade", ns.Theme.Id())
  check("new installation, workshop: no sound stored", stored() == nil, stored())
  check("new installation, workshop: the bell plays", playing(ns) == "glocke", playing(ns))
  local saved = copy(_G.DeathNoteDB)
  ns = world(saved)
  tick(3.2)
  check("after a reload: still no sound stored", stored() == nil, stored())
  check("after a reload: the bell plays", playing(ns) == "glocke", playing(ns))
  ns:Fire("TOGGLE_UI"); tick()
  ns.UI.OpenPanel("settings"); tick()
  local RP
  for _, f in ipairs(BM.frames) do if f.settings and f.io then RP = f end end
  local S = RP and RP.settings
  for i = 1, 4 do
    if S and S.tabs[i] and S.tabs[i]:IsShown() then S.tabs[i]._scripts.OnClick(S.tabs[i]); tick() end
  end
  local bell = ns.Look.SOUND_BY_KEY.glocke
  local tone = S and S.tone
  check("House Rules show the sound that plays (the bell)", tone and bell and tone._text == bell.label, tone and tone._text)
  ns.Look.SetSound("gong")
  check("a sound picked in the House Rules is stored", stored() == "gong", stored())
  check("and plays", playing(ns) == "gong", playing(ns))
  check("no errors (new installation)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

-- 2) a new installation keeps the black book: the raid warning, as always
do
  local ns = world(nil)
  tick(3.2)
  ns.Start.Go(); tick()
  check("new installation, black book: no sound stored", stored() == nil, stored())
  check("new installation, black book: the raid warning plays", playing(ns) == "warnung", playing(ns))
end

-- 3) data of 1.2.2 (version 3, "warnung" stored) switched to the workshop: the raid warning stays
do
  local ns = world({ version = 3, settings = { firstRun = "done", welcomed = true, lang = "deDE",
    alert = { soundKey = "warnung" }, ui = { theme = "trade" } }, enemies = {}, deaths = {} })
  tick(3.2)
  check("1.2.2 data, workshop: cover active", ns.Theme.Id() == "trade", ns.Theme.Id())
  check("1.2.2 data, workshop: warnung stays stored", stored() == "warnung", stored())
  check("1.2.2 data, workshop: the raid warning plays", playing(ns) == "warnung", playing(ns))
end

-- 4) data of 1.0.x (version 2, no sound stored at all) with the workshop: "warnung" is stored, as every version did
do
  local ns = world({ version = 2, settings = { lang = "deDE", alert = { volume = 3 }, ui = { theme = "trade" } }, enemies = {}, deaths = {} })
  tick(3.2)
  check("1.0.x data: warnung stored", stored() == "warnung", stored())
  check("1.0.x data: the raid warning plays", playing(ns) == "warnung", playing(ns))
end

-- 5) a broken stored sound (wrong type) becomes "warnung" as before
do
  local ns = world({ version = 4, settings = { firstRun = "done", lang = "deDE", alert = { soundKey = 7 }, ui = { theme = "trade" } },
    enemies = {}, deaths = {} })
  tick(3.2)
  check("broken sound: repaired to warnung", stored() == "warnung", stored())
  check("broken sound: no errors", #AM.errors == 0, AM.errors[1])
end

io.write(("cover's alarm sound: %d green, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
