-- 1.1.0 final hunt: findings Z1 to Z3 (one death = one kill, reassigning, importing an empty book).
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function killsAt(S, t)
  local n = 0
  for _, e in pairs(S.All()) do
    for _, d in ipairs(e.deaths) do if d.t == t and d.role == "kill" then n = n + 1 end end
  end
  return n
end

test("Z1: Bestätigen eines Beteiligten nimmt dem bisherigen Täter den Kill (ein Tod, ein Kill)", function()
  local ns = M.Load(); local S = ns.Store
  local a = S.ApplyKill({ name = "Anton", surname = "A" }, { t = 500, source = "recap", others = { "Berta-B" } }, true)
  local b = S.ApplyKill({ name = "Berta", surname = "B" }, { t = 500, source = "recap" }, false)
  S.RecordDeath({ t = 500, kind = "pvp", killerKey = a, sure = true, source = "recap", candidates = { a, b } })
  eq(S.Get(b).assists, 1)
  ok(S.ConfirmSuspect(b))
  eq(killsAt(S, 500), 1, "genau ein Kill für diesen Tod")
  eq(S.Get(b).kills, 1); eq(S.Get(b).assists, 0)
  -- the recap proved Anton's damage: he stays involved
  eq(S.Get(a).kills, 0); eq(S.Get(a).assists, 1); eq(S.Get(a).deaths[1].role, "assist")
  eq(S.Get(a).status, "wanted")
  eq(S.Deaths()[1].killerKey, b)
  no(S.ConfirmSuspect(b), "zweiter Klick ändert nichts")
  eq(S.Get(b).kills, 1)
end)

test("Z2: Umhängen lässt niemanden mit 0 als Gesuchten zurück und rückt lastKill nach", function()
  local ns = M.Load(); local S = ns.Store
  S.ApplyKill({ name = "Carl", surname = "C" }, { t = 100, source = "recap" }, true)
  S.RecordDeath({ t = 100, kind = "pvp", killerKey = "Carl-C", sure = true, source = "recap", candidates = { "Carl-C" } })
  S.RecordDeath({ t = 900, kind = "pvp", candidates = { "Carl-C", "Dora-D" }, zone = "Z", me = "Ich" })
  ok(S.AssignDeath(1, "Carl-C"))
  eq(S.Get("Carl-C").kills, 2); eq(S.Get("Carl-C").lastKill, 900)
  ok(S.AssignDeath(1, "Dora-D"))
  eq(S.Get("Carl-C").kills, 1); eq(S.Get("Carl-C").lastKill, 100, "lastKill zeigt wieder auf den älteren Kill")
  eq(S.Get("Dora-D").kills, 1)
  -- only suspicion left: back to "Unsolved"
  S.ApplyKill({ name = "Emil", surname = "E" }, { t = 950, source = "suspect" }, false)
  S.RecordDeath({ t = 960, kind = "pvp", candidates = { "Emil-E", "Dora-D" } })
  ok(S.AssignDeath(1, "Emil-E")); eq(S.Get("Emil-E").status, "wanted")
  ok(S.AssignDeath(1, "Dora-D"))
  eq(S.Get("Emil-E").kills, 0); eq(S.Get("Emil-E").status, "suspect")
end)

test("Z3: Der Text eines leeren Buchs lässt sich einlesen", function()
  local ns = M.Load(); local S = ns.Store
  local text = S.Export()
  local good, added, merged = S.Import(text)
  ok(good, added); eq(added, 0); eq(merged, 0)
  ok(S.Import("```\n" .. text .. "\n```"))
  local bad = S.Import("irgendwas")
  no(bad)
end)

M.done("test_abschluss")
