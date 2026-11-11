-- Secret values (B17): guard order and behaviour with the stricter mock.
-- 1) static: on every line of the logic files, a value checked with IsSecret/issecretvalue/
--    issecrettable must not be compared, measured, concatenated or indexed EARLIER on that line
--    (the client raises on these before the guard is reached). Runtime traps cannot catch
--    `==`/`~=` against plain values in Lua 5.1, so this is checked in the source.
-- 2) dynamic: secrets everywhere an API hands them in; type(secret) reports the hidden type.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local FILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }

local function escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

-- returns a list of "file:line: text" where a guarded value is used before its guard
local function scan(src, file)
  local bad = {}
  local n, prev = 0, ""
  for line in (src .. "\n"):gmatch("([^\n]*)\n") do
    n = n + 1
    local code = line:gsub("%-%-.*$", "")
    for pos, var in code:gmatch("()[%w_%.]*[Ii]s[Ss]ecret[%w_]*%(([%w_%.%[%]\"]+)%)") do
      -- the line before counts too (a guard split over two statements)
      local before = prev .. "\n" .. code:sub(1, pos - 1)
      local v = escape(var)
      local hits = {
        v .. "%s*[=~<>]=", v .. "%s*[<>][^=]", "#%s*" .. v .. "[^%w_%.]", "#%s*" .. v .. "$",
        v .. "%s*%.%.", v .. ":", "[=~<>]=%s*" .. v .. "[^%w_%.%(]", "[=~<>]=%s*" .. v .. "$",
      }
      for _, h in ipairs(hits) do
        if before:find(h) then bad[#bad + 1] = ("%s:%d: %s"):format(file, n, line); break end
      end
    end
    prev = code
  end
  return bad
end

test("Statisch: IsSecret vor jedem Vergleich/Länge/Verkettung (alle Logikdateien)", function()
  local all = {}
  for _, f in ipairs(FILES) do
    local h = assert(io.open(M.ADDON_DIR .. f))
    local src = h:read("*a"); h:close()
    for _, b in ipairs(scan(src, f)) do all[#all + 1] = b end
  end
  eq(#all, 0, "Vergleich vor Guard:\n  " .. table.concat(all, "\n  "))
end)

test("Statisch: der Prüfer erkennt die alten Muster (Selbsttest)", function()
  local old = table.concat({
    'if v == nil then return false end',
    'if issecretvalue and issecretvalue(v) then end',
    'if type(v) == "string" and v ~= "" and not IsSecret(v) then return v end',
    'return v == true and not IsSecret(v)',
    'if (type(events) ~= "table" or #events == 0) then end if IsSecret(events) then end',
    'local hide = e.hideCaster == true and not IsSecret(e.hideCaster)',
    'if channel ~= "GUILD" or IsSecret(text) or IsSecret(channel) then return end',
  }, "\n")
  local bad = scan(old, "alt")
  eq(#bad, 6, "alle sechs alten Muster erkannt")
  eq(#scan('if IsSecret(v) then return nil end if type(v) == "string" and v ~= "" then return v end', "neu"), 0)
  eq(#scan('return Util.True(e.hideCaster)', "neu"), 0)
end)

test("Mock: type(secret) meldet den verborgenen Typ, Zugriffe werfen", function()
  local s = M.Secret("name", "string")
  eq(type(s), "string"); eq(type(M.Secret("b", "boolean")), "boolean"); eq(type(M.SecretTable()), "table")
  no(pcall(function() return #s end), "Länge")
  no(pcall(function() return s:lower() end), "Methode")
  no(pcall(function() return s .. "x" end), "Verkettung")
  no(pcall(function() return s < "a" end), "Vergleich <")
end)

test("Util-Guards mit Secrets aller Typen: nie ein Fehler, nie ein Wert", function()
  local ns = M.Load()
  local U = ns.Util
  for _, kind in ipairs({ "string", "boolean", "number", "table" }) do
    local s = M.Secret("x", kind)
    ok(U.IsSecret(s)); eq(U.Str(s), nil); eq(U.Num(s), nil); eq(U.True(s), false); eq(U.False(s), false)
    eq(U.Safe(s, "alt"), "alt"); eq(U.KeyFor(s), nil); eq(U.SplitFull(s), nil); eq(U.CleanName(s), nil)
    eq(U.KeyFor("Ok", s), "Ok-Forever")
  end
  eq(U.Safe(nil, 1), 1); eq(U.Num(0 / 0), nil); eq(U.False(false), true)
end)

test("Secrets aus allen Quellen: Plaketten, Ziel, Recap, Meter, Gildenkanal, Tod", function()
  local ns = M.Load({ before = function() M.units.player.guild = "G" end })
  ns.Store.AddManual("Grimm")               -- placeholder: the GUID path in the tracker is active
  M.AddEnemy("nameplate1", { name = "Grimm", surname = M.Secret("s"), guid = M.Secret("g"),
    enemy = M.Secret("b", "boolean"), canAttack = M.Secret("b", "boolean"), friend = M.Secret("f", "boolean"),
    faction = M.Secret("f"), level = M.Secret("l", "number"), class = M.Secret("c"), target = "player" })
  M.AddEnemy("nameplate2", { name = "Zorn", surname = "Tal", guid = M.Secret("g"), class = M.Secret("c"),
    race = M.Secret("r"), level = M.Secret("l", "number"), guild = M.Secret("gu"), faction = M.Secret("f"),
    isUnitOverride = M.Secret("u", "boolean"), target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  M.FireEvent("NAME_PLATE_UNIT_ADDED", M.Secret("unit"))
  M.FireEvent("UNIT_TARGET", M.Secret("unit"))
  M.FireEvent("NAME_PLATE_UNIT_REMOVED", M.Secret("unit"))
  M.recap = { id = 1, events = M.Secret("events", "table") }
  M.FireEvent("PLAYER_DEAD"); M.Advance(6)
  M.recap = { id = 2, events = { { sourceGUID = M.Secret("g"), sourceName = M.Secret("n"), amount = M.Secret("a", "number"),
    overkill = M.Secret("o"), timestamp = M.Secret("t"), hideCaster = M.Secret("h"), spellName = M.Secret("s") } } }
  M.meter = { combatSpells = { { totalAmount = M.Secret("n", "number"), isDeadly = M.Secret("b", "boolean"),
    combatSpellDetails = { { unitName = M.Secret("n"), isMob = M.Secret("b", "boolean"), isPet = M.Secret("b", "boolean") } } } } }
  M.Advance(10); M.FireEvent("PLAYER_DEAD"); M.Advance(6)
  M.FireEvent("CHAT_MSG_ADDON", M.Secret("p"), "x", "GUILD", "A-Forever")
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", "1\tH\t0\t1.0", M.Secret("c"), "A-Forever")
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", M.Secret("text"))
  M.FireEvent("PARTY_KILL", M.Secret("a"), M.Secret("b"))
  eq(#M.errors, 0, tostring(M.errors[1]))
  no(M.ContainsSecret(_G.DeathNoteDB), "keine Secrets in der DB")
  eq(#ns.Store.Deaths(), 2)
end)

M.done("test_secrets")
