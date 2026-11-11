-- Gegenproben der Logik-Jagd: muessen gruen bleiben (unveraendert uebernommen).
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local function recap(id, guid, name, ts) M.recap = { id = id, events = { { sourceGUID = guid, sourceName = name, amount = 500, overkill = 100, timestamp = ts or (M.epoch + M.now), spellName = "X" } } } end
local function die() M.FireEvent("PLAYER_DEAD"); M.Advance(6) end

test("Tod 1 PvP, Tod 2 PvE 20 s spaeter mit unveraendertem Recap: kein zweiter Kill", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1" }); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); die()
  M.units.nameplate1 = nil; M.Advance(20); die()
  eq(ns.Store.Get("Grimm-Blut").kills, 1); eq(ns.Store.Deaths()[1].kind, "unknown")
end)
test("Recap kommt erst beim dritten Leseversuch", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1" }); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("PLAYER_DEAD"); M.Advance(3); recap(1, "Player-93-G1", "Grimm Blut"); M.Advance(3)
  eq(ns.Store.Get("Grimm-Blut") and ns.Store.Get("Grimm-Blut").kills, 1)
end)
test("/reload zwischen Tod 1 und PvE-Tod 2 (Recap von Tod 1 liegt beim Login noch vor)", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1" }); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); die()
  local db, rc = _G.DeathNoteDB, M.recap
  ns = M.Load({ db = db, before = function() M.recap = rc end })
  M.Advance(10); die()
  eq(ns.Store.Get("Grimm-Blut").kills, 1)
end)
test("PLAYER_DEAD doppelt: eine Buchung", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Blut", guid = "Player-93-G1" }); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  recap(1, "Player-93-G1", "Grimm Blut"); M.FireEvent("PLAYER_DEAD"); M.Advance(1); M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  eq(#ns.Store.Deaths(), 1); eq(ns.Store.Get("Grimm-Blut").kills, 1)
end)
test("Sync: laengste Felder mit Umlauten und %, Rundlauf <= 255 Bytes", function()
  local ns = M.Load()
  local P = ns.Guild.Proto
  local long = ("Ä"):rep(40)
  local key = ns.Util.KeyFor("Ölaf", ("ü"):rep(28))
  local msg = P.EncodeKill({ key = key, display = "Ölaf " .. ("ü"):rep(28), class = "DEATHKNIGHT", level = 60, zone = long .. "%%%", t = M.epoch + M.now, victim = ("ö"):rep(32) }, "K")
  assert(msg and #msg <= 255, "Laenge " .. tostring(msg and #msg))
  local m = assert(P.Decode(msg, M.epoch + M.now, {}))
  eq(m.key, key); eq(m.victim, ("ö"):rep(32))
  assert(not m.zone or not m.zone:find("[\128-\191]$") or m.zone:find("[\192-\255][\128-\191]+$"), "UTF-8-Schnitt")
end)
test("Sync: 200000 Zufalls- und Mutationsnachrichten werfen nie und beschaedigen nichts ausserhalb db.guild", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  local P = ns.Guild.Proto
  local base = P.EncodeKill({ key = "Grimm-Blut", display = "Grimm Blut", class = "ROGUE", level = 40, zone = "Ort", t = M.epoch + M.now, victim = "Kollege Eins" }, "K")
  math.randomseed(7)
  local settingsBefore = ns.Store.Setting("alert.cooldown")
  for i = 1, 200000 do
    local s
    if i % 2 == 0 then
      local b = {}; for j = 1, math.random(0, 300) do b[j] = string.char(math.random(0, 255)) end; s = "1\tK\t" .. table.concat(b)
    else
      local p = math.random(1, #base); s = base:sub(1, p - 1) .. string.char(math.random(0, 255)) .. base:sub(p + math.random(0, 2))
    end
    M.FireEvent("CHAT_MSG_ADDON", "DeathNote", s, "GUILD", "S" .. (i % 500) .. "-Forever")
    if i % 5000 == 0 then M.Advance(61) end
  end
  eq(ns.Store.Setting("alert.cooldown"), settingsBefore)
  local n = 0; for _ in pairs(ns.Store.All()) do n = n + 1 end; eq(n, 0, "eigene Liste unberuehrt:")
  assert((ns.Guild.Count()) <= 400)
end)
test("Sync: ohne Gilde / share=false wird nichts gesendet", function()
  local ns = M.Load()
  ns.Store.ApplyKill({ name = "Grimm", surname = "Blut" }, { t = M.epoch + M.now, me = "Varorak Narenmar" }, true)
  M.Advance(60); eq(#M.addonSent, 0)
  ns = M.Load({ before = function() M.units.player.guild = "G" end }); ns.Store.Setting("guild.share", false)
  M.Advance(60); eq(#M.addonSent, 0)
end)
M.done("test_gegenproben")
