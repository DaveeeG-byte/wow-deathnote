-- Fixer 2 1.6.0 (je03): the map's scenes come from a cache (Scene.Items); a new scale of the map reads no book. The
-- cache never goes stale: after every kind of change (an own death with and without a spot, a death assigned to
-- another killer, an entry removed, a rekey, an own kill, a guildmate's death with its spot, a friend's death, a call,
-- a sighting, time passing for "fresh", a setting) Scene.Items equals a fresh Scene.All. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok
local GUILD = "Die Wurstbrüder"
local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Share.lua"

local function sig(it)
  return table.concat({ it.kind, tostring(it.t), tostring(it.mapID), tostring(it.x), tostring(it.y), tostring(it.key),
    tostring(it.name), tostring(it.class), tostring(it.victim), tostring(it.fresh == true), tostring(it.spot),
    tostring(it.suspect), tostring(it.revenge), tostring(it.caller) }, "|")
end
local function norm(list)
  local s = {}
  for _, it in ipairs(list) do s[#s + 1] = sig(it) end
  table.sort(s)
  return table.concat(s, "\n")
end

test("Karten-Cache veraltet nie: jede Art von Änderung gegen Scene.All", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { version = "1.6.0", files = FILES })
  a.login()
  W.run(30)
  local ns = a.ns
  local Sc, St, P = ns.Scene, ns.Store, ns.Guild.Proto
  local function from(sender, text) a.fire("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender .. "-Forever") end
  local n = 0
  local function death(name, x, y)
    n = n + 1
    local t = time() - n
    local rec = { t = t, zone = "Schlingendorntal", mapID = 1434, x = x, y = y, source = "recap", others = {} }
    local key = St.ApplyKill({ name = name, surname = "Bart", class = "ROGUE", level = 40, guid = "Player-1-" .. name }, rec, true)
    St.RecordDeath({ t = t, zone = rec.zone, mapID = 1434, x = x, y = y, kind = "pvp", sure = true, source = "recap",
      candidates = {}, counted = true, killerKey = key, killerName = name .. " Bart" })
    return key
  end
  local keyA
  local ops = {
    { "eigener Tod mit Ort", function() keyA = death("Grimm", 40, 30) end },
    { "eigener Tod ohne Ort", function() death("Osric", nil, nil) end },
    { "Tod einem anderen Täter zugeordnet", function() St.AssignDeath(#St.Deaths(), keyA) end },
    { "Tod nur im Journal (RecordDeath ohne Ereignis)", function()
      St.RecordDeath({ t = time() - 50, zone = "Brachland", mapID = 1413, x = 20, y = 20, kind = "pvp", sure = true,
        counted = true, candidates = {}, killerKey = keyA, killerName = "Grimm Bart" }) end },
    { "Gilden-Tod mit Ort (K und L)", function()
      local t = time() - 30
      from("Berta", P.EncodeKill({ key = "Kalt-Herz", display = "Kalt Herz", class = "MAGE", level = 40, zone = "Eschental",
        t = t, victim = "Berta Senf" }, "K"))
      from("Berta", P.EncodePlace({ key = "Kalt-Herz", t = t, victim = "Berta Senf", mapID = 1440, x = 30, y = 40 }))
    end },
    { "Zeit vergeht (frisch endet)", function() W.run(Sc.FRESH + 5) end },
    { "Eintrag entfernt", function() St.Remove(keyA) end },
    { "Ruf", function()
      ns.Call.calls = ns.Call.calls or {}
      ns:Fire("HELP_CALL", { from = "guild", t = time(), key = "Kalt-Herz", display = "Kalt Herz", by = "Berta Senf",
        zone = "Eschental", mapID = 1440, x = 31, y = 41 })
    end },
    { "Sichtung", function()
      a.fire("CHAT_MSG_ADDON", "DeathNote", ns.Call.EncodeSight("Kalt-Herz", 1440, 33.3, 44.4, time(), "1-2-3"), "GUILD",
        "Berta-Forever")
    end },
    { "Einstellung", function() St.Setting("scene.days", 7) end },
  }
  for i, op in ipairs(ops) do
    Sc.Items(time())                -- the cache is warm before the change
    op[2]()
    W.run(1)
    local now = time()
    eq(norm(Sc.Items(now)), norm(Sc.All(now)), ("Schritt %d (%s): Karte wie frisch gelesen"):format(i, op[1]))
  end
  -- a new scale reads no book: many calls without a change, one read
  local r0 = Sc.stat.reads
  for _ = 1, 30 do Sc.Pins(1434, time()) end
  ok(Sc.stat.reads - r0 <= 1, "30 Mal Nadeln ohne Änderung: höchstens ein Lesen, " .. (Sc.stat.reads - r0))
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

M.done("fix160 je03 Karten-Cache")
