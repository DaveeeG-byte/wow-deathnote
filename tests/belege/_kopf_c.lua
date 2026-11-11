-- Kopf der Belegtests nach der Jagd auf 1.2.1 (beleg_c0*). Aufruf: nice -n 15 luajit <datei> <Projektkopie>
-- Rot heisst: der Fund besteht. Alle Namen erfunden.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
-- Nachrichtentypen auf der Leitung (ab Index ab, optional nur von einem Client)
function H.typen(W, von, ab)
  local t = {}
  for i = (ab or 0) + 1, #W.sent do
    local m = W.sent[i]
    if not von or m.sender == von then local k = m.text:match("^1\t(%u)\t") or "?"; t[k] = (t[k] or 0) + 1 end
  end
  return t
end
-- Drossel wie im Client angenommen (Addon-Nachrichten: 10 auf einmal, dann 1 je Sekunde; 3 = AddonMessageThrottle)
function H.drossel(c)
  local send = c.env.C_ChatInfo.SendAddonMessage
  local tokens, last = 10, M.now
  c.env.C_ChatInfo.SendAddonMessage = function(...)
    tokens = math.min(10, tokens + (M.now - last)); last = M.now
    if tokens < 1 then return 3 end
    tokens = tokens - 1
    return send(...)
  end
end
function H.anzahl(tb) local n = 0; for _, x in pairs(tb or {}) do for _ in pairs(x) do n = n + 1 end end; return n end
return H
