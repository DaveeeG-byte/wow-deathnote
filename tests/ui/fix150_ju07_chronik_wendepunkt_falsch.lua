-- ju07: Die Wendepunkte der Chronik ("Jetzt quitt: n : n") werden aus den behaltenen Taten (hoechstens 30 je Feind)
-- und dem Protokoll (60) nachgezaehlt, die Schlusszeile kommt aus dem echten Stand (Ledger.Standing). Bei einer
-- langen Fehde fehlen die aeltesten Taten: die Chronik meldet "quitt", obwohl er weiter vorn liegt, und die
-- Schlusszeile sagt im selben Blatt "offen". Erwartet: Wendepunkte nur, wenn die Zaehlung vollstaendig ist (oder vom
-- echten Stand aus rueckwaerts gerechnet). Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local W = J.world(WT, "deDE")
local ns, L = W.ns, W.ns.L
local S = ns.Store
local t0 = time() - 40 * 86400
local key
for i = 1, 35 do   -- er toetet mich 35-mal; das Buch behaelt 30 Taten
  key = S.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
    { t = t0 + i * 3600, zone = "Schlingendorntal", source = "recap" }, true)
end
local log = ns.Ledger.Log()
for i = 1, 30 do   -- ich erlege ihn danach 30-mal (Protokoll)
  table.insert(log, 1, { t = t0 + 10 * 86400 + i * 3600, key = key, name = "Grimm Bart", f = "v", zone = "Beutebucht" })
end
ns.Ledger.Standing = function(k) if k == key then return 30, 35 end end   -- echter Stand: ich 30, er 35
local ch = ns.Chronicle.Build(key)
local even, last
for _, l in ipairs(ch.lines) do
  if l.text:find(ns.F(L.CHRON_EVEN, { score = "" }):gsub("%.$", ""), 1, true) then even = l.text end
  last = l.text
end
J.check("Schlusszeile: offen (30 : 35)", last:find("30 : 35", 1, true) ~= nil, last)
J.check("keine Wende 'quitt', die es nie gab", even == nil, even)
J.done()
