-- Shared head of the proof tests of the bug hunt (1.2.0, taken into the suite by fix-1).
-- Without argument the project the file lives in is used; otherwise a project copy as first argument
-- or in DN_DIR (red check):  luajit tests/test_beleg_xx.lua [/path/to/project-copy]
-- The tests check behaviour and data, not German texts. All names are made up.
local a0 = arg and arg[0] or ""
local here = a0:match("^(.*)/tests/") or (a0:match("^tests/") and ".")
local DIR = (arg and arg[1]) or os.getenv("DN_DIR") or here or "."
DIR = DIR:gsub("/+$", "")
local SELF = arg[0]
-- mock_wow.lua derives the addon folder from arg[0] ("<x>/tests/...")
arg[0] = DIR .. "/tests/beleg.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")

local H = { M = M, DIR = DIR }
local pass, fail, lines = 0, 0, {}

-- erwartet(name, condition, detail): green when the expectation holds (red = the finding still exists)
function H.erwartet(name, cond, detail)
  if cond then pass = pass + 1 else
    fail = fail + 1
    lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")
  end
end

function H.lauf(name, fn)
  local ok, err = pcall(fn)
  if not ok then fail = fail + 1; lines[#lines + 1] = "  ROT (Fehler): " .. name .. ": " .. tostring(err) end
  if M.errors and #M.errors > 0 then
    fail = fail + 1
    lines[#lines + 1] = "  ROT (Addon-Fehler): " .. name .. ": " .. tostring(M.errors[1])
    M.errors = {}
  end
end

function H.fertig()
  local n = SELF:match("([^/]+)%.lua$") or SELF
  io.write(("%-34s %3d gruen, %d rot\n"):format(n, pass, fail))
  for _, l in ipairs(lines) do io.write(l .. "\n") end
  os.exit(fail == 0 and 0 or 1)
end

function H.welt(watch)
  M.Reset()
  return M.NewWorld(watch or { "GUILD_KILL", "GUILD_UPDATED", "GUILD_ENEMY_SPOTTED", "HUNT_BAGGED", "GUILD_SIGHTING" })
end

function H.zaehle(c, ev)
  local n = 0
  for _, e in ipairs(c.events) do if e[1] == ev then n = n + 1 end end
  return n
end

-- certain death of c by name/surname (as in tests/test_freunde.lua)
function H.tod(c, name, surname, dt)
  local t = time() - (dt or 0)
  local me = c.surname and (c.name .. " " .. c.surname) or c.name
  local key = c.ns.Store.ApplyKill({ name = name, surname = surname, class = "MAGE", level = 36 },
    { t = t, zone = "Schlingendorntal", me = me, myLevel = 34, source = "recap", others = {} }, true)
  c.ns:Fire("DEATH_RECORDED", { t = t, zone = "Schlingendorntal", me = me, kind = "pvp",
    sure = true, counted = true, killerKey = key, source = "recap" }, key)
  return key
end

function H.gilde(c, text, from) c.fire("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from) end
function H.fluestern(c, text, from) c.fire("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from) end

-- (fix-2, from the head of the final hunt) time jump without session time: only the clock moves on
function H.tage(n) M.epoch = M.epoch + n * 86400 end

-- the same char logs out and (later) in again: saved data stays, the session is new
function H.relog(W, c, opts)
  c.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(c.env.DeathNoteDB)
  c.loggedIn = false
  for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
  opts = opts or {}
  local o = { db = db, friends = opts.friends or c.friendNames, bn = opts.bn or c.bnNames, fullSender = c.fullSender,
    lang = opts.lang }
  return W.client(opts.name or c.name, opts.surname or c.surname, opts.noGuild and nil or (opts.guild or c.guild), o)
end

function H.tiefe_kopie(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local o = {}
  seen[t] = o
  for k, v in pairs(t) do o[H.tiefe_kopie(k, seen)] = H.tiefe_kopie(v, seen) end
  return o
end

return H
