-- 1.6.4 move, follow-up hunt N1 for the victim alarm (alert.victims, own cooldown of 600 s): a victim alarm on the
-- screen when the mode starts is put aside; after more than 600 s in the mode the same victim rings again (a real
-- alarm, the mode ends); that alarm keeps its 600 s: the victim in sight right after it does not ring again. And a
-- victim alarm put aside gets its cooldown back when the player ends the mode himself. Names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function world()
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = "deDE", alert = { victims = true } }, enemies = {}, deaths = {} }
  local W = J.world("deDE", { db = db })
  -- my killing blow on him (the rap sheet books him as a victim)
  W.AM.AddEnemy("nameplate1", { name = "Opfer", surname = "Eins", guid = "Player-93-OpferEins" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); W.tick(0.1)
  W.AM.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-OpferEins"); W.tick(11); W.settle()
  return W, W.ns.Util.KeyFor("Opfer", "Eins")
end

local W, key = world()
local a = function() return W.frame("DeathNoteAlert") end
check("Voraussetzung: Opfer gebucht", W.ns.Ledger.Victim(key) ~= nil)
W.tick(700)
W.ns.Alert.VictimSpotted(key, nil, "x"); W.tick(0.2)
check("Voraussetzung: Opfer-Alarm steht", a() and a():IsShown() and not a().sample)
W.slash("move")
check("Modus an", W.ns.Place.Active())
W.ns.Alert.VictimSpotted(key, nil, "x"); W.tick(0.2)
check("Opfer in Sicht in seiner Abklingzeit beendet den Modus nicht", W.ns.Place.Active())
W.tick(610)
W.ns.Alert.VictimSpotted(key, nil, "x"); W.tick(0.2)
check("nach 610 s: echter Opfer-Alarm, Modus aus", not W.ns.Place.Active() and a():IsShown() and not a().sample)
W.settle()
check("Voraussetzung: Alarm abgelaufen", not a():IsShown())
W.ns.Alert.VictimSpotted(key, nil, "x"); W.tick(0.2)
check("das Opfer klingelt nicht gleich noch einmal (600 s)", not a():IsShown())

-- the player ends the mode himself: the victim alarm put aside rings at the next sighting
local W2, key2 = world()
W = W2
W2.tick(700)
W2.ns.Alert.VictimSpotted(key2, nil, "x"); W2.tick(0.2)
W2.slash("move"); W2.tick(1); W2.slash("move")
W2.ns.Alert.VictimSpotted(key2, nil, "x"); W2.tick(0.2)
check("vom Spieler beendet: das Opfer klingelt bei der naechsten Sichtung", W2.frame("DeathNoteAlert"):IsShown())
local n, first = W2.errors()
check("keine Fehler", n == 0, first)
J.done("mv164_n1_opfer")
