-- Jagd Logik 01: eine Episode, in der alle Angreifer durch meinen Tod schon im Buch stehen, wird nie geschlossen.
-- Erwartet: nach dem Tod (offene Welt, Todesstoss gebucht, also keine Frage, keine Meldung) ist die Episode beendet
-- (Grudge.Current() == nil oder geschlossen) bzw. ein spaeterer, neuer Angriff (10 Minuten spaeter, anderer Ort)
-- oeffnet eine NEUE Episode, deren Zeit und Ort die des neuen Angriffs sind, und der Moerder von damals wird bei
-- einem neuen Angriff (nach Ablauf der 5 Minuten) wieder gefragt.
-- Heute: die Meldung (GrudgeCard.lua Update, Zeile 360) zeigt sich nicht, weil nichts zu fragen ist, und niemand ruft
-- Grudge.Close. Die Episode bleibt bis /reload offen: der Moerder steht dort als "im Buch" und wird nie wieder gefragt,
-- jeder neue Angreifer landet in der alten Episode (Zeit/Ort des alten Todes in der Angriffs-Tat), die Zauber-Ereignisse
-- bleiben dauerhaft registriert.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function load()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u) local x = M.units[u]; if not x then return false end
    if x.combat == nil then return true end; return x.combat end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  return ns
end
local function enemy(token, name, surname, o)
  o = o or {}; o.name, o.surname = name, surname
  o.guid = o.guid or ("Player-93-" .. name)
  if o.target == nil then o.target = "player" end
  local u = M.AddEnemy(token, o)
  if token:find("^nameplate") then M.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  return u
end
local function hit() M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1) end
local function recapEv(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or -1,
    timestamp = time() - 1, spellName = "Hieb" }
end

test("JL01: Tod mit gebuchtem Moerder schliesst die Episode; spaeterer Angriff = neue Episode, Moerder wird gefragt", function()
  local ns = load()
  local G = ns.Grudge
  -- (Fixer: die Episode des Todes wird ueber GRUDGE_UPDATE festgehalten; nach dem Fix ist sie schon zu)
  local old
  ns:On("GRUDGE_UPDATE", function(e) if e and not old then old = e end end)
  M.recap = { id = 4, events = { recapEv({ guid = "Player-93-Fies", name = "Fies Ling", amount = 900, overkill = 50 }) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  ok(old, "Vorbedingung: Episode des Todes"); no(G.Asks(old), "Vorbedingung: nichts zu fragen")
  ok(G.Current() == nil or G.Current().closed, "nach der Todesauswertung ist die Episode beendet")
  no(ns.Grudge.ProbeSnapshot().events.UNIT_SPELLCAST_START, "Zauber-Ereignisse nach dem Ende abgemeldet")
  -- zehn Minuten spaeter, wiederbelebt: derselbe Moerder greift an, ohne mich zu toeten
  M.Advance(600)
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  enemy("nameplate1", "Fies", "Ling")
  hit()
  local ep = G.Current()
  ok(ep, "Episode")
  ok(ep ~= old, "neue Episode statt der haengenden alten")
  local row = ep and ep.rows["Fies-Ling"]
  ok(row and G.Open(row), "der Moerder wird fuer den neuen Angriff gefragt")
  ok(ep and ep.gt >= M.now - 2, "Zeit der Episode ist die des neuen Angriffs")
end)

M.done("jl01 episode haengt")
