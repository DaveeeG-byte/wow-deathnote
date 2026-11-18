-- Fixer 2 1.6.0 (je01, je02): the open chronicle follows the guild's data bundled. A sighting or a deed never builds the
-- chronicle inside the handler of the message; the next look (at most one build per GLUI.FILL_GAP) shows the right
-- state; a burst of deeds builds at most twice per second; with the chronicle closed the dot is counted without a
-- build. Use: luajit tests/ui/fix160_je01_chronik_folgt_gebuendelt.lua [project folder]. All names are made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local GUILD = "Die Rostigen Nägel"
package.loaded.mock_wow, package.loaded.mock = nil, nil
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
BM.measure = true
AM.locale = "deDE"
local files = {}
for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
files[#files + 1] = "Share.lua"
local ns = AM.Load({ noLogin = true, files = files, before = function() AM.units.player.guild = GUILD end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua", "SceneMap.lua", "GuildLogUI.lua" }) do
  BM.Load(ADDON .. "/" .. f, ns)
end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
_G.IsInRaid, _G.IsInGroup = function() return false end, function() return false end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function msg(sender, text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender .. "-Forever") end
local P, GL, GLUI, UI = ns.Guild.Proto, ns.GuildLog, ns.GuildLogUI, ns.UI
local n = 0
local function kill(victim, ago, same)
  n = n + 1
  local k = same and 1 or n
  msg(victim:match("^(%S+)"), P.EncodeKill({ key = "Grimwald" .. k .. "-Aschbrand", display = "Grimwald" .. k .. " Aschbrand",
    class = "ROGUE", level = 60, zone = "Schlingendorntal", t = _G.time() - (ago or 0), victim = victim }, "K"))
end

ns:Fire("TOGGLE_UI"); tick(30); settle()
kill("Liora Sturmwind", 600)
tick(1); settle()
UI.SetFilter("guild"); tick(); settle()
UI.ShowGuildEntry("Grimwald1-Aschbrand"); tick(); settle()   -- a selection that the deeds below keep
GLUI.Open(); settle()
local _, PL = GLUI.Frames()
local function lineWith(needle)
  for _, b in ipairs(PL.lines) do
    if b:IsVisible() and b.event and tostring(b.text._text):find(needle, 1, true) then return b end
  end
end
check("Vorbedingung: Chronik offen mit der ersten Tat", GLUI.IsOpen() and lineWith("Grimwald1 Aschbrand") ~= nil)

-- a sighting: nothing is built in the handler, the next look shows it
local b0 = GL.stat.builds
GL.OnSighting({ key = "Grimwald1-Aschbrand", name = "Grimwald1 Aschbrand", by = "Bertram Eisenhut", zone = "Brachland",
  src = "guild", t = _G.time(), mapID = 1413, x = 40, y = 50 })
check("Sichtung: kein Bau im Handler", GL.stat.builds == b0, GL.stat.builds - b0)
tick(1); settle()
check("Sichtung: beim nächsten Anzeigen in der Chronik", lineWith("Brachland") ~= nil)
check("Sichtung: auch dann ohne Neubau (eingefügt)", GL.stat.builds == b0, GL.stat.builds - b0)

-- a burst of deeds: at most one build per FILL_GAP, the last one shown
tick(2); settle()
local b1 = GL.stat.builds
-- (deeds of the selected killer: a change of the guild tab's selection closes the chronicle, the window's rule)
for i = 1, 10 do kill("Bertram Eisenhut", 100 - i * 5, true); tick(0.1) end
tick(1); settle()
local builds = GL.stat.builds - b1
check("zehn Taten in einer Sekunde: höchstens 3 Neubauten", builds <= 3, builds)
-- the pages show the current state: the visible lines are the first rows of a fresh list
check("die Chronik bleibt offen", GLUI.IsOpen())
local rows, shown, same = GL.Rows("all"), {}, true
for _, b in ipairs(PL.lines) do if b:IsVisible() and b.event then shown[#shown + 1] = b.text._text end end
local i = 0
for _, r in ipairs(rows) do
  if r.event and i < #shown then i = i + 1; if r.text ~= shown[i] then same = false end end
end
check("die Seite zeigt den Stand nach der letzten Tat", same and #shown > 0 and #GL.All("all") >= 11, #shown)

-- a burst of events that make the lists stale (a target of the hit list taken down, ten times in a second): the open
-- chronicle is built at most once per FILL_GAP, the last one shown
tick(2); settle()
local b3 = GL.stat.builds
for i = 1, 10 do
  GL.Add("bag", { key = "Ork" .. i .. "-Hau", name = "Ork" .. i .. " Hau", by = "Liora Sturmwind", t = _G.time() + i, src = "guild" })
  tick(0.1)
end
local mid = GL.stat.builds - b3
tick(1); settle()
check("zehn Ereignisse in einer Sekunde: höchstens 3 Neubauten", mid <= 3 and GL.stat.builds - b3 <= 3, mid .. " / " .. (GL.stat.builds - b3))
check("das letzte steht oben in der Chronik", lineWith("Ork10 Hau") ~= nil)

-- the chronicle closed, another tab: the dot is counted without a build
GLUI.Close(); UI.SetFilter("wanted"); tick(); settle(); tick(5)
local b2 = GL.stat.builds
kill("Liora Sturmwind", 0)
tick(1); settle()
local t = nil
for _, f in ipairs(BM.frames) do if f.id == "guild" and f.glogDot then t = f end end
check("Punkt am Reiter brennt", t and t.glogDot:IsShown())
check("Punkt am Reiter: ohne Bau der Chronik", GL.stat.builds == b2, GL.stat.builds - b2)
check("keine Fehler", #AM.errors == 0, AM.errors[1])

io.write(("fix160 je01 Chronik folgt gebündelt: %d ok, %d rot\n"):format(ok, bad))
os.exit(bad > 0 and 1 or 0)
