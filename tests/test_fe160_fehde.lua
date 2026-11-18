-- 1.6.0 feud: a guild as a feud. A member of a feud guild who is not in the own book (nor in the guild's or friends'
-- book) and comes into sight by the usual ways (target, mouseover, plate) gives the quiet alarm once per guild per 5
-- minutes, never in instances; somebody in the book keeps his own alarm; nothing is stored but the guild's "last
-- seen", nothing goes over the wire; at most 50 feuds. All names are made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function load()
  local ns = M.Load()
  local spotted = {}
  ns:On("FEUD_SPOTTED", function(g, key) spotted[#spotted + 1] = { g, key } end)
  return ns, spotted
end
local function see(token, name, guild, how)
  M.AddEnemy(token, { name = name, surname = "Rot", guid = "Player-93-" .. name, guild = guild })
  M.FireEvent(how or "PLAYER_TARGET_CHANGED")
end

test("Fehde erklaeren und beenden, Deckel 50", function()
  local ns = load()
  local F = ns.Feud
  eq(F.Declare("Rote Hand"), true)
  ok(F.Is("Rote Hand"))
  ok(ns.Tracker.feudHook ~= nil, "Haken nur mit Fehde")
  eq(F.End("Rote Hand"), true)
  no(F.Is("Rote Hand")); eq(ns.Tracker.feudHook, nil, "ohne Fehde kein Haken")
  for i = 1, 50 do eq(F.Declare("Gilde " .. i), true) end
  local r, why = F.Declare("Gilde 51")
  eq(r, nil); eq(why, "cap")
  eq(F.FeudCount(), 50)
  eq(F.Declare(M.Secret("g")), nil, "secret: nichts")
  eq(F.Declare("Bad|Name"), nil, "kein | im Namen")
end)

test("Mitglied in Sicht: leiser Alarm einmal je Gilde je 5 Minuten", function()
  local ns, spotted = load()
  ns.Feud.Declare("Rote Hand")
  see("target", "Anon", "Rote Hand")
  eq(#spotted, 1, "erste Sichtung")
  eq(spotted[1][1], "Rote Hand")
  see("target", "Zweiter", "Rote Hand")
  eq(#spotted, 1, "zweites Mitglied derselben Gilde: noch still")
  M.Advance(301)
  ns.Tracker.Reset()
  see("mouseover", "Dritter", "Rote Hand", "UPDATE_MOUSEOVER_UNIT")
  eq(#spotted, 2, "nach 5 Minuten wieder, auch per Mouseover")
  ok(ns.Store.DB().feuds["Rote Hand"].seen, "zuletzt gesehen der Gilde")
  eq(next(ns.Store.All()), nil, "niemand ins Buch geschrieben")
  -- a plate
  M.Advance(301)
  M.AddEnemy("nameplate3", { name = "Vierter", surname = "Rot", guid = "Player-93-Vierter", guild = "Rote Hand" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate3")
  eq(#spotted, 3, "Plakette")
end)

test("Wer im Buch steht, behaelt seinen eigenen Alarm", function()
  local ns, spotted = load()
  ns.Feud.Declare("Rote Hand")
  ns.Store.ApplyKill({ name = "Grimm", surname = "Rot", guid = "Player-93-Grimm", guild = "Rote Hand" },
    { t = time() - 50, zone = "Z", source = "recap" }, true)
  M.ClearFired()
  see("target", "Grimm", "Rote Hand")
  eq(#spotted, 0, "kein Fehde-Alarm")
  eq(#M.Fired("ENEMY_SPOTTED"), 1, "der eigene Alarm kommt")
end)

test("In Instanzen nie, andere Gilde nie, ohne Gilde nie", function()
  local ns, spotted = load()
  ns.Feud.Declare("Rote Hand")
  see("target", "Fremd", "Blaue Hand")
  eq(#spotted, 0)
  see("target", "Ohne", nil)
  eq(#spotted, 0)
  M.instance = { true, "party" }
  M.FireEvent("ZONE_CHANGED_NEW_AREA")
  see("target", "Anon", "Rote Hand")
  eq(#spotted, 0, "Instanz")
  M.instance = { false, "none" }
  M.FireEvent("ZONE_CHANGED_NEW_AREA")
  see("target", "Anon", "Rote Hand")
  eq(#spotted, 1, "draussen wieder")
end)

test("Secret-Gilde: kein Alarm, gezaehlt", function()
  local ns, spotted = load()
  ns.Feud.Declare("Rote Hand")
  M.AddEnemy("target", { name = "Geheim", surname = "Rot", guid = "Player-93-Geheim", guild = M.Secret("guild") })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#spotted, 0)
  local c = ns.Feud.Session()
  ok((c.guildSecret or 0) >= 1, "secret gezaehlt")
end)

test("Nichts davon geht ueber die Leitung", function()
  local ns, spotted = load()
  M.addonSent = {}
  ns.Feud.Declare("Rote Hand")
  see("target", "Anon", "Rote Hand")
  ns.Feud.End("Rote Hand")
  eq(#spotted, 1)
  eq(#M.addonSent, 0, "keine Addon-Nachricht")
end)

test("Kaputte Fehdeliste wird repariert, mehr als 50: die neuesten bleiben", function()
  local feuds = { ["Bad|X"] = { t = 1 }, Leer = "x" }
  for i = 1, 55 do feuds["Gilde " .. i] = { t = 1000 + i, seen = "gestern" } end
  local ns = M.Load({ db = { feuds = feuds } })
  local n = 0
  for name, f in pairs(ns.Store.DB().feuds) do n = n + 1; eq(f.seen, nil) end
  eq(n, 50)
  ok(ns.Store.DB().feuds["Gilde 55"]); eq(ns.Store.DB().feuds["Gilde 1"], nil)
end)

M.done("fe160_fehde")
