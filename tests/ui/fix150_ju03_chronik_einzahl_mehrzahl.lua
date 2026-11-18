-- ju03: Chronik, Zeile "fuer die anderen erlegt": der Satz steht in der Mehrzahl, auch wenn nur einer gerächt hat
-- (deDE "Bertram haben Grimm fuer die anderen erlegt", frFR "ont", itIT "hanno", esES "abatieron", ptBR "abateram",
-- plPL "ubili", ruRU/ukUA "убили"/"вбили", enUS geht). Erwartet: bei einem Namen Einzahl oder ein Satz ohne Verb-Zahl.
-- Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local PLURAL = { deDE = " haben ", frFR = " ont ", itIT = " hanno ", esES = " abatieron ", ptBR = " abateram ",
  plPL = " ubili ", ruRU = " убили ", ukUA = " вбили " }
for _, code in ipairs({ "deDE", "frFR", "itIT", "esES", "ptBR", "plPL", "ruRU", "ukUA" }) do
  local W = J.world(WT, code)
  local ns = W.ns
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
    { t = time() - 600, zone = "Schlingendorntal", source = "recap" }, true)
  ns.Guild.Avenged = function() return { { char = "Bertram Hollowbrook", t = time() - 60 } } end
  local ch = ns.Chronicle.Build(key)
  local line
  for _, l in ipairs(ch.lines) do if l.text:find("Bertram", 1, true) then line = l.text end end
  J.check(code .. ": ein Raecher, Satz nicht in der Mehrzahl", line and not line:find(PLURAL[code], 1, true), line)
end
J.done()
