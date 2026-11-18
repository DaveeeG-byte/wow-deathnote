-- 1.6.0 feud: the probe probe.feud. How often the guild of an enemy was readable, empty or secret, how many entries were
-- filed away, the measured time of Store.Init; kept by /dn probe, added up over sessions at logout. Names made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function seen(token, name, guild)
  M.AddEnemy(token, { name = name, surname = "Ling", guid = "Player-93-" .. name, guild = guild })
  M.FireEvent("PLAYER_TARGET_CHANGED")
end

test("Gilde lesbar, leer, secret gezaehlt; beim Abmelden in probe.feud", function()
  local ns = M.Load()
  seen("target", "Eins", "Rote Hand")
  seen("target", "Zwei", nil)
  seen("target", "Drei", M.Secret("guild"))
  local c = ns.Feud.Session()
  eq(c.guildOk, 1); eq(c.guildEmpty, 1); eq(c.guildSecret, 1)
  eq(ns.Store.DB().probe, nil, "waehrend der Sitzung nichts in der Datei")
  M.FireEvent("PLAYER_LOGOUT")
  local p = ns.Store.DB().probe.feud
  eq(p.guildOk, 1); eq(p.guildEmpty, 1); eq(p.guildSecret, 1)
  ok(type(p.initMs) == "number" and type(p.initMaxMs) == "number", "Startzeit")
  -- the next session adds up
  seen("target", "Vier", "Rote Hand")
  M.FireEvent("PLAYER_LOGOUT")
  eq(ns.Store.DB().probe.feud.guildOk, 2)
end)

test("/dn probe behaelt probe.feud", function()
  local ns = M.Load()
  seen("target", "Eins", "Rote Hand")
  ns.Probe.Run(false)
  local p = ns.Store.DB().probe.feud
  ok(p and p.guildOk == 1, "nach dem Sondenlauf da")
  ns.Probe.Run(false)
  eq(ns.Store.DB().probe.feud.guildOk, 1, "nicht doppelt")
end)

test("Abgelegte Eintraege gezaehlt", function()
  local enemies = {}
  for i = 1, 3 do enemies["Alt" .. i .. "-Ling"] = { suspected = 1, status = "suspect", deaths = { { t = 5, role = "suspect" } }, day = 0 } end
  local ns = M.Load({ db = { enemies = enemies, days = 40, dayAt = 0 } })
  M.FireEvent("PLAYER_LOGOUT")
  eq(ns.Store.DB().probe.feud.expired, 3)
end)

M.done("fe160_sonde")
