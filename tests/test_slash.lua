package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function slash(msg) _G.SlashCmdList.DEATHNOTE(msg) end

test("Slash-Namen registriert", function()
  M.Load()
  eq(_G.SLASH_DEATHNOTE1, "/dn"); eq(_G.SLASH_DEATHNOTE2, "/deathnote")
  eq(_G.SLASH_DEATHNOTE3, "/todesliste"); eq(_G.SLASH_DEATHNOTE4, "/deathlist")
  ok(_G.DeathNote and _G.DeathNote.Store, "globale Debug-Tabelle")
end)

test("/dn ohne Argument -> TOGGLE_UI", function()
  M.Load(); M.ClearFired()
  slash("")
  eq(#M.Fired("TOGGLE_UI"), 1)
end)

test("/dn add und /dn del", function()
  local ns = M.Load()
  slash("add grimm bart")
  ok(ns.Store.Get("Grimm-Bart"))
  ok(M.chat[#M.chat]:find("Grimm Bart"))
  slash("add")
  slash("del grimm")
  no(ns.Store.Get("Grimm-Bart"))
  slash("del niemand")
  ok(M.chat[#M.chat]:find("Nicht im Buch"))
end)

test("/dn debug schaltet um", function()
  local ns = M.Load()
  slash("debug"); eq(ns.Store.Setting("debug"), true)
  slash("DEBUG"); eq(ns.Store.Setting("debug"), false)
end)

test("/dn test -> TEST_ALERT, /dn hilfe, Unbekanntes", function()
  M.Load(); M.ClearFired()
  slash("test"); eq(#M.Fired("TEST_ALERT"), 1)
  local n = #M.chat
  slash("hilfe"); ok(#M.chat >= n + 5)
  slash("quatsch"); ok(M.chat[#M.chat]:find("Unbekannt"))
end)

test("/dn probe schreibt DeathNoteDB.probe ohne Secrets", function()
  local ns = M.Load()
  M.AddEnemy("target", { name = M.Secret("n"), guid = M.Secret("g"), class = M.Secret("c"), target = "player" })
  M.recap = { id = 1, events = { { sourceGUID = M.Secret("g"), sourceName = "Klar", amount = 5, overkill = 1, timestamp = time() } } }
  slash("probe")
  local p = _G.DeathNoteDB.probe
  ok(p); eq(p.apis["C_DeathRecap.GetRecapEvents"], true); eq(p.apis["CombatLogGetCurrentEventInfo"], false)
  eq(p.events.COMBAT_LOG_EVENT_UNFILTERED, nil, "ohne 'combatlog' wird das Kampflog nicht angefasst")
  eq(p.events.PLAYER_DEAD, true)
  _G.SlashCmdList.DEATHNOTE("probe combatlog")
  eq(_G.DeathNoteDB.probe.events.COMBAT_LOG_EVENT_UNFILTERED, false, "auf Wunsch geprüft (geschlossen)")
  eq(p.target.name, "<secret>"); eq(p.target.guid, "<secret>")
  eq(p.recapNow.raw[1].sourceGUID, "<secret>")
  eq(p.player.key, "Varorak-Narenmar")
  no(M.ContainsSecret(_G.DeathNoteDB))
  ok(M.chat[#M.chat]:find("DeathNoteDB.probe"))
end)

M.done("test_slash")
