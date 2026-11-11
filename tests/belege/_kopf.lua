-- Gemeinsamer Kopf der Belegtests. Aufruf je Datei:
--   nice -n 15 luajit <datei> <Projektkopie>
-- Nutzt tests/beleg_helfer.lua und tests/mock_wow.lua der angegebenen Kopie. Alle Namen sind erfunden.
-- Geprueft werden Verhalten und Daten, keine Wortlaute. Rot heisst: der Fund besteht.
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektkopie>"):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
H.DIR = DIR

-- aeltere Staende (vor fix-2) haben diese Helfer noch nicht
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

-- Client aus der Welt nehmen (ausloggen), gespeicherte Daten zurueckgeben
function H.raus(W, c)
  c.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(c.env.DeathNoteDB)
  c.loggedIn = false
  W.setOnline(c, false)
  for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
  return db
end

function H.J(P, key, by, why, b) return P.EncodeHunt({ key = key, t = time(), by = by, why = why or "x", b = b }) end

-- Zahl der Freigaben in einer Hunt-Tabelle, optional nur die eines Chars
function H.freigaben(hunts, char)
  local n = 0
  for _, h in pairs(hunts or {}) do
    for c in pairs(h.by or {}) do if not char or c == char then n = n + 1 end end
  end
  return n
end

return H
