-- Fixer 2 1.6.0 (jb04): the chronicle's ring, "who has the book", the avengers and the week's card belong to the guild
-- of the char (its name on every event of the guild). Old events without the name: the guild of the first char in a
-- guild that loads them; a char without a guild leaves them. Friends' events stay the account's. Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq
local function copy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = copy(v) end return c end
local function files() local f = {} for _, x in ipairs(M.Files()) do f[#f + 1] = x end f[#f + 1] = "Share.lua" return f end
local function kinds(ns)
  local out = {}
  for _, e in ipairs(ns.GuildLog.All("all")) do out[#out + 1] = e.k .. ":" .. tostring(e.src) end
  table.sort(out)
  return table.concat(out, ",")
end
local function as(db, name, guild)
  return M.Load({ files = files(), db = db, before = function()
    M.epoch = M.epoch + 600
    local p = M.units.player
    p.name, p.surname, p.guid, p.guild = name, "Char", "Player-93-0000" .. name, guild
  end })
end

local function first()
  local ns = M.Load({ files = files(), before = function() M.units.player.guild = "Gilde Eins" end })
  M.Advance(30)
  local GL = ns.GuildLog
  GL.Add("call", { key = "Grimm-Bart", name = "Grimm Bart", by = "Liora", src = "guild", zone = "Brachland" })
  GL.Add("bag", { key = "Grimm-Bart", name = "Grimm Bart", by = "Liora", src = "guild", t = time() - 5 })
  GL.Add("call", { key = "Ork-Hau", name = "Ork Hau", by = "Dora", src = "friends", zone = "Eschental" })
  eq(kinds(ns), "bag:guild,call:friends,call:guild")
  M.FireEvent("PLAYER_LOGOUT")
  return copy(_G.DeathNoteDB)
end

test("Zweitchar in anderer Gilde, ohne Gilde, zurück in der ersten", function()
  local db = first()
  local ns = as(copy(db), "Zweit", "Gilde Zwei"); M.Advance(30)
  eq(kinds(ns), "call:friends", "andere Gilde: nur die Freunde")
  eq(ns.GuildLog.Week(time(), "guild").avenged, 0, "Wochenkarte der zweiten Gilde")
  ns = as(copy(db), "Dritt", nil); M.Advance(30)
  eq(kinds(ns), "call:friends", "ohne Gilde: nur die Freunde")
  local _, head = ns.GuildLog.Holders()
  eq(head.holders, 0, "ohne Gilde: niemand hat das Buch")
  ns = as(copy(db), "Viert", "Gilde Eins"); M.Advance(30)
  eq(kinds(ns), "bag:guild,call:friends,call:guild", "zurück in der ersten Gilde: alles da")
  eq(ns.GuildLog.Week(time(), "guild").avenged, 1, "Rächer der ersten Gilde")
end)

test("Alte Einträge ohne Gilde: der erste Char in einer Gilde bekommt sie, ohne Gilde bleiben sie liegen", function()
  local db = first()
  for _, e in ipairs(db.glog.ring) do e.gn = nil end
  local ns = as(db, "Dritt", nil); M.Advance(30)
  eq(kinds(ns), "call:friends", "ohne Gilde: nicht gezeigt")
  M.FireEvent("PLAYER_LOGOUT")
  local db2 = copy(_G.DeathNoteDB)
  local n = 0
  for _, e in ipairs(db2.glog.ring) do if e.src ~= "friends" and e.gn == nil then n = n + 1 end end
  eq(n, 2, "liegen gelassen")
  ns = as(copy(db2), "Zweit", "Gilde Zwei"); M.Advance(30)
  eq(kinds(ns), "bag:guild,call:friends,call:guild", "der erste Char in einer Gilde bekommt sie")
  M.FireEvent("PLAYER_LOGOUT")
  local db3 = copy(_G.DeathNoteDB)
  for _, e in ipairs(db3.glog.ring) do if e.src ~= "friends" then eq(e.gn, "Gilde Zwei") end end
  ns = as(db3, "Viert", "Gilde Eins"); M.Advance(30)
  eq(kinds(ns), "call:friends", "danach gehören sie der zweiten Gilde")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

M.done("fix160 jb04 Chronik je Gilde")
