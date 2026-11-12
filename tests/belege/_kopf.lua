-- Shared head of the proof tests. Usage per file:
--   nice -n 15 luajit <file> <project copy>
-- Uses tests/beleg_helfer.lua and tests/mock_wow.lua of the given copy. All names are made up.
-- Checks behaviour and data, no wording. Red means: the finding still exists.
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektkopie>"):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
H.DIR = DIR

-- older states (before fix-2) do not have these helpers yet
local M = H.M
if not H.tage then function H.tage(n) M.epoch = M.epoch + n * 86400 end end
if not H.relog then
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
end

-- Take a client out of the world (log out), return the saved data
function H.raus(W, c)
  c.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(c.env.DeathNoteDB)
  c.loggedIn = false
  W.setOnline(c, false)
  for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
  return db
end

function H.J(P, key, by, why, b) return P.EncodeHunt({ key = key, t = time(), by = by, why = why or "x", b = b }) end

-- Number of shared entries in a hunt table, optionally only those of one char
function H.freigaben(hunts, char)
  local n = 0
  for _, h in pairs(hunts or {}) do
    for c in pairs(h.by or {}) do if not char or c == char then n = n + 1 end end
  end
  return n
end

return H
