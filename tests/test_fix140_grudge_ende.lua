-- 1.4.0 fixer (hunt logic 1): every grudge episode ends for sure, also when no notice is shown, and the cast events
-- go away with it. Ways an episode can end without the notice: nothing to ask after the fight or the death, the
-- notice not loaded (logic only) or hidden with the interface, the switch turned off, a loading screen, a new zone
-- of another kind (battleground with its switch on). All names are made up.
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
local function enemy(token, name, surname)
  M.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name, target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", token)
end
local function hit() M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1) end
local function fightStart() M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED") end
local function fightEnd() M.inCombat = false; M.FireEvent("PLAYER_REGEN_ENABLED") end
local function casts(ns) return ns.Grudge.ProbeSnapshot().events.UNIT_SPELLCAST_START == true end
local function attacked(ns)
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); hit()
  local ep = ns.Grudge.Current()
  ok(ep and ep.rows["Grimm-Bart"], "Vorbedingung: Angreifer erkannt")
  ok(casts(ns), "Vorbedingung: Zauber-Ereignisse im Kampf an")
  return ep
end

test("ohne Meldung (nur Logik geladen): eine offene Frage endet nach Anzeigedauer + Puffer, Zauber-Ereignisse aus", function()
  local ns = load()
  local ep = attacked(ns)
  fightEnd()
  eq(ep.running, false); no(ep.closed)
  M.Advance(ns.Grudge.Seconds() + ns.Grudge.EXPIRE_GRACE + 1)
  eq(ep.closed, true); eq(ep.closedBy, "time"); eq(ns.Grudge.Current(), nil)
  no(casts(ns), "Zauber-Ereignisse abgemeldet")
  eq(ep.rows["Grimm-Bart"].state, "gone")
end)

test("alles schon beantwortet, Kampf vorbei, keine Meldung: sofort zu", function()
  local ns = load()
  local ep = attacked(ns)
  ns.Grudge.Answer("Grimm-Bart", false)
  fightEnd()
  eq(ep.closed, true); eq(ep.closedBy, "none"); no(casts(ns))
end)

test("ein neuer Angreifer verlaengert die Frist (Zaehler ab dem letzten neuen)", function()
  local ns = load()
  local ep = attacked(ns)
  fightEnd()
  M.Advance(ns.Grudge.Seconds())
  fightStart(); enemy("nameplate2", "Dorn", "Fels"); hit(); fightEnd()
  ok(ep.rows["Dorn-Fels"], "in derselben Episode")
  M.Advance(ns.Grudge.EXPIRE_GRACE + 2)
  no(ep.closed, "noch nicht: der zweite kam spaeter")
  M.Advance(ns.Grudge.Seconds() + 1)
  eq(ep.closed, true)
end)

test("Abschalten (/dn rachsucht) beendet die Episode", function()
  local ns = load()
  local ep = attacked(ns)
  ns.Grudge.Slash("")
  eq(ns.Store.Setting("grudge.enabled"), false)
  eq(ep.closed, true); eq(ep.closedBy, "place"); no(casts(ns))
end)

test("Ladebildschirm mitten im Kampf: der Kampf endet dort, die Episode laeuft aus", function()
  local ns = load()
  local ep = attacked(ns)
  M.FireEvent("PLAYER_ENTERING_WORLD")
  eq(ep.running, false, "Kampf beendet")
  M.Advance(ns.Grudge.Seconds() + ns.Grudge.EXPIRE_GRACE + 1)
  eq(ep.closed, true); no(casts(ns))
end)

test("Wechsel ins Schlachtfeld (Schalter an): die Episode der offenen Welt endet", function()
  local ns = load()
  ns.Store.Setting("grudge.battlegrounds", true)
  local ep = attacked(ns)
  M.instance = { true, "pvp" }
  M.FireEvent("PLAYER_ENTERING_WORLD")
  eq(ep.closed, true); eq(ep.closedBy, "place")
  ok(ns.Grudge.ProbeSnapshot().allowed, "im Schlachtfeld mit Schalter weiter erlaubt")
end)

test("Wechsel ins Schlachtfeld (Schalter aus): die Episode endet", function()
  local ns = load()
  local ep = attacked(ns)
  M.instance = { true, "pvp" }
  M.FireEvent("ZONE_CHANGED_NEW_AREA")
  eq(ep.closed, true); no(casts(ns)); no(ns.Grudge.ProbeSnapshot().events.UNIT_COMBAT)
end)

test("Tod mit Moerder im Buch, danach neuer Kampf: neue Episode, Moerder wird wieder gefragt", function()
  local ns = load()
  M.recap = { id = 4, events = { { sourceGUID = "Player-93-Fies", sourceName = "Fies Ling", amount = 900, overkill = 50,
    timestamp = time() - 1, spellName = "Hieb" } } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  eq(ns.Grudge.Current(), nil, "Todes-Episode ohne Frage ist zu")
  no(casts(ns))
  M.Advance(30)
  fightStart(); enemy("nameplate1", "Fies", "Ling"); hit()
  local ep = ns.Grudge.Current()
  ok(ep and ns.Grudge.Open(ep.rows["Fies-Ling"]))
end)

M.done("fix140 grudge ende")
