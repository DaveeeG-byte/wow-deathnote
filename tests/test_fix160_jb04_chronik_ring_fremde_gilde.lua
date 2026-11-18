-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- Jagd 2 Fehler 04: Der Ring der Gildenchronik (DeathNoteDB.glog.ring: Hilferuf, Sichtung, "von der Abschussliste
-- geholt") gehoert dem Konto, nicht der Gilde. Die Gildenbuecher selbst liegen je Gilde (guild.lists[name]). Wechselt
-- der Spieler auf einen Zweitchar in einer anderen Gilde (oder ohne Gilde), zeigt dessen Chronik die Rufe, Sichtungen
-- und Abschuesse der ersten Gilde als "Quelle Gilde", die Wochenkarte der zweiten Gilde zaehlt den Raecher der ersten,
-- und "Aushaengen" schreibt dessen Namen sichtbar in den Gildenchat der zweiten Gilde.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_04.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq
local function copy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = copy(v) end return c end
local function files() local f = {} for _, x in ipairs(M.Files()) do f[#f + 1] = x end f[#f + 1] = "Share.lua" return f end

-- Erstchar in "Gilde Eins": ein Ruf, eine Sichtung, ein Abschuss kommen an
local function ersteGilde()
  local ns = M.Load({ files = files(), before = function() M.units.player.guild = "Gilde Eins" end })
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  M.Advance(30)
  M.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(),
    display = "Grimwald Aschbrand" }), "GUILD", "Liora-Forever")
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", ns.Guild.Proto.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart",
    class = "ROGUE", level = 44, zone = "Arathihochland", t = time() - 5, victim = "Liora" }, "K"), "GUILD", "Liora-Forever")
  M.Advance(3)
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", ns.Call.EncodeSight("Grimm-Bart", 1434, 40, 40, time(), nil), "GUILD", "Bert-Forever")
  M.Advance(3)
  ns:Fire("HUNT_BAGGED", "Grimm-Bart", "Liora", time(), "guild")
  eq(#ns.GuildLog.All("all"), 4, "Erstchar: Tod, Ruf, Sichtung, Abschuss")
  M.FireEvent("PLAYER_LOGOUT")
  return copy(_G.DeathNoteDB)
end

for _, g2 in ipairs({ "Gilde Zwei", false }) do
  test("JB04: Zweitchar " .. (g2 and ("in '" .. g2 .. "'") or "ohne Gilde") .. " zehn Minuten spaeter", function()
    local db = ersteGilde()
    local ns = M.Load({ files = files(), db = db, before = function()
      M.epoch = M.epoch + 600
      local p = M.units.player
      p.name, p.surname, p.guid, p.guild = "Zweit", "Char", "Player-93-0000BBBB", g2 or nil
    end })
    M.Advance(30)
    local seen, bad = {}, {}
    for _, e in ipairs(ns.GuildLog.All("all")) do seen[#seen + 1] = e.k .. ":" .. tostring(e.by or e.victim) end
    if #seen > 0 then bad[#bad + 1] = "Chronik zeigt Ereignisse der ersten Gilde: " .. table.concat(seen, ", ") end
    local w = ns.GuildLog.Week(time(), "guild")
    if w.avenged ~= 0 then bad[#bad + 1] = "Wochenkarte zaehlt Raecher der ersten Gilde: " .. w.avenged
      .. " (Gilde der Karte: " .. tostring(w.guild) .. ")" end
    local line = ns.GuildLog.WeekLine(time())
    if type(line) == "string" and line:find("Liora", 1, true) then bad[#bad + 1] = "Wochenzeile zum Aushaengen: " .. line end
    ok(#bad == 0, table.concat(bad, " || "))
  end)
end

M.done("jb04 chronik ring fremde gilde")
