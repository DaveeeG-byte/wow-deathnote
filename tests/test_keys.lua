package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ns = M.Load()
local U = ns.Util

test("KeyFor: Name + Nachname (Forever: zweites Glied von UnitName)", function()
  local key, n, s, had = U.KeyFor("Varorak", "Narenmar")
  eq(key, "Varorak-Narenmar"); eq(n, "Varorak"); eq(s, "Narenmar"); eq(had, true)
end)

test("KeyFor: 'Name Nachname' und 'Name-Nachname' ergeben denselben Schlüssel", function()
  eq(U.KeyFor("Varorak Narenmar"), "Varorak-Narenmar")
  eq(U.KeyFor("Varorak-Narenmar"), "Varorak-Narenmar")
  eq(U.KeyFor("  varorak   narenmar  "), "Varorak-Narenmar")
end)

test("KeyFor: ohne zweites Glied wird der eigene Realm ergänzt", function()
  local key, _, _, had = U.KeyFor("Grimmbart")
  eq(key, "Grimmbart-Forever"); eq(had, false)
  eq(U.KeyFor("Grimmbart", ""), "Grimmbart-Forever")
end)

test("KeyFor: Umlaute (UTF-8) werden groß geschrieben, Rest bleibt", function()
  eq(U.KeyFor("ärger", "öde"), "Ärger-Öde")
  eq(U.KeyFor("Ärger", "Öde"), "Ärger-Öde")
  eq(U.KeyFor("élise ßmith"), "Élise-ßmith")   -- ß hat keinen Großbuchstaben: bleibt
  eq(U.KeyFor("McDonald", "vanHelsing"), "McDonald-VanHelsing")
end)

test("KeyFor: ungültig, secret oder unbekannt -> nil", function()
  no(U.KeyFor(nil)); no(U.KeyFor("")); no(U.KeyFor("   "))
  no(U.KeyFor(M.Secret("name")))
  no(U.KeyFor("Unbekannt"))
  eq(U.KeyFor("Ok", M.Secret("surname")), "Ok-Forever")  -- secret second part is ignored
end)

test("SplitKey", function()
  local n, s = U.SplitKey("Varorak-Narenmar")
  eq(n, "Varorak"); eq(s, "Narenmar")
  n, s = U.SplitKey("A-B-C")
  eq(n, "A"); eq(s, "B-C")
end)

test("KeyOfUnit: Spieler ja, NPC nein, Secret nein", function()
  M.AddEnemy("target", { name = "Grimmbart", surname = "Eisenfaust" })
  eq(U.KeyOfUnit("target"), "Grimmbart-Eisenfaust")
  M.units.target.isPlayer = false
  no(U.KeyOfUnit("target"))
  M.AddEnemy("target", { name = M.Secret("n"), surname = "X" })
  no(U.KeyOfUnit("target"))
  M.AddEnemy("target", { name = "Grimmbart", isPlayer = M.Secret("bool") })
  no(U.KeyOfUnit("target"))
  no(U.KeyOfUnit("nichts"))
end)

test("Display und TargetName", function()
  eq(U.Display({ name = "A", surname = "B" }), "A B")
  eq(U.Display({ name = "A", realm = "Forever" }), "A")
  eq(U.TargetName({ name = "A", surname = "B" }), "A B")
  eq(U.TargetName({ name = "A" }), "A")
end)

test("Safe/IsSecret/Str", function()
  local s = M.Secret("x")
  ok(U.IsSecret(s)); eq(U.Safe(s, "alt"), "alt"); eq(U.Safe(5, 0), 5); no(U.Str(s)); no(U.Str(""))
  ok(U.IsSecret(M.SecretTable()))
  no(U.True(M.Secret("true")))
end)

test("Ago und Money", function()
  eq(U.Ago(nil), "nie")
  eq(U.Ago(time() - 10), "gerade eben")
  eq(U.Ago(time() - 180), "vor 3 Min.")
  eq(U.Ago(time() - 2 * 86400), "vor 2 Tagen")
  eq(U.Money(1234567), "123g 45s 67k")
  eq(U.Money(0), "0k")
end)

test("NameplatesOn liest nur die CVar", function()
  eq(U.NameplatesOn(), true)
  M.cvars.nameplateShowEnemies = false
  eq(U.NameplatesOn(), false)
end)

M.done("test_keys")
