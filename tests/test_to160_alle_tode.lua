-- 1.6.0 deaths: every own death with its cause. A death by a creature or the world gets a row of its own
-- (DeathNoteDB.fates, Fates.lua), never a second row for a death by a player; caps 300 rows / 150 causes; the switch
-- fates.on; the awards for dying; the week line; probe.pve; nothing goes over the wire. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local NOW
local seq = 0
local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 5,
    timestamp = o.ts or (time() - 1), spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE",
    environmentalType = o.env }
end
-- one death with the given recap rows
local function die(events)
  seq = seq + 1
  M.recap = { id = 100 + seq, events = events }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
end
local function creature(npc, name, spell)
  return ev({ guid = ("Creature-0-3110-0-49-%d-0000AB%04d"):format(npc, seq), name = name, spell = spell or "Biss" })
end

test("Kreatur: eine eigene Zeile mit Ort, Name, NPC-ID und Zauber, keine Journalzeile", function()
  local ns = M.Load()
  NOW = time()
  die({ creature(1234, "Murlocspaeher", "Schlammwurf") })
  local f = ns.Fates.DB()
  eq(#f.rows, 1, "eine Zeile")
  local r = f.rows[1]
  eq(r.kind, "pve"); eq(r.art, "creature"); eq(r.name, "Murlocspaeher"); eq(r.npc, 1234); eq(r.spell, "Schlammwurf")
  eq(r.zone, "Schlingendorntal"); eq(r.mapID, 1434); ok(r.t and r.t >= NOW, "Zeit")
  eq(#ns.Store.Deaths(), 0, "keine Zeile im Todesjournal der Spieler")
  eq(f.foes["npc:1234"].n, 1)
  eq(ns.Store.Tally().n, 1, "der Zaehler zaehlt weiter")
  no(M.ContainsSecret(_G.DeathNoteDB), "Secret in DeathNoteDB")
end)

test("Umwelt: Sturz, Ertrinken, Lava aus dem Recap (event ENVIRONMENTAL_DAMAGE)", function()
  local ns = M.Load()
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling" }) })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Drowning" }) })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Lava" }) })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE" }) })                 -- no type: the world, unnamed
  local rows = ns.Fates.Rows()
  eq(#rows, 4)
  eq(rows[4].art, "env"); eq(rows[4].env, "fall")
  eq(rows[3].env, "drown"); eq(rows[2].env, "lava"); eq(rows[1].env, "other")
  eq(#ns.Store.Deaths(), 0, "kein 'unklar' im Journal: die Welt ist kein Spieler")
  eq(ns.Fates.Name(rows[4]), ns.L.FATE_ENV_FALL)
  ok(ns.Fates.DB().foes["env:fall"], "Ursache Sturz gezaehlt")
end)

test("Tod durch einen Spieler: keine zweite Zeile", function()
  local ns = M.Load()
  die({ ev({ guid = "Player-93-A", name = "Grimm Bart", spell = "Hinterhalt" }) })
  eq(#ns.Store.Deaths(), 1); eq(ns.Store.Deaths()[1].kind, "pvp")
  eq(#ns.Fates.Rows(), 0, "nichts bei den anderen Toden")
end)

test("Begleiter ohne bekannten Besitzer: bleibt unklar im Journal, mit der Art, keine zweite Zeile", function()
  local ns = M.Load()
  die({ ev({ guid = "Pet-0-3110-0-49-555-0000AA", name = "Reisszahn", spell = "Klaue" }) })
  local j = ns.Store.Deaths()[1]
  eq(j.kind, "unknown")
  ok(type(j.cause) == "table" and j.cause.art == "pet" and j.cause.name == "Reisszahn", "Art Begleiter mit Namen")
  eq(j.cause.guid, nil, "keine GUID im Journal")
  eq(#ns.Fates.Rows(), 0)
end)

test("Name secret (Instanz): Zeile ohne Namen, Sonde zaehlt; NPC-ID aus der GUID", function()
  local ns = M.Load()
  M.instance = { true, "party" }
  local e = creature(777, "x")
  e.sourceName = M.Secret("name")
  die({ e })
  local r = ns.Fates.Rows()[1]
  ok(r, "erfasst")
  eq(r.art, "creature"); eq(r.name, nil); eq(r.npc, 777); eq(r.counted, false, "Instanz zaehlt nicht")
  eq(ns.Fates.Name(r), ns.L.FATE_CREATURE)
  eq(ns.Fates.counts.nameSecret, 1)
  no(M.ContainsSecret(_G.DeathNoteDB), "Secret in DeathNoteDB")
  M.instance = { false, "none" }
end)

test("Kreatur ohne Namen und GUID: als unbekannt gezaehlt", function()
  local ns = M.Load()
  local r = ns.Fates.Record({ t = time(), kind = "pve", zone = "Z", cause = { art = "creature" } })
  eq(r.art, "creature"); eq(ns.Fates.FoeKey(r), "unknown")
  eq(ns.Fates.DB().foes.unknown.n, 1)
  eq(ns.Fates.counts.npcMissing, 1)
end)

test("C_CreatureInfo.GetCreatureID: genutzt wenn da, ein Fehler darin kostet nichts", function()
  local ns = M.Load()
  _G.C_CreatureInfo = { GetCreatureID = function() return 4242 end }
  eq(ns.Fates.NpcOf("Creature-0-1-2-3-99-AB"), 4242)
  _G.C_CreatureInfo = { GetCreatureID = function() error("boom") end }
  eq(ns.Fates.NpcOf("Creature-0-1-2-3-99-AB"), 99, "Ersatz aus der GUID")
  _G.C_CreatureInfo = { GetCreatureID = function() return M.Secret("id", "number") end }
  eq(ns.Fates.NpcOf("Creature-0-1-2-3-98-AB"), 98, "secret -> aus der GUID")
  _G.C_CreatureInfo = nil
  eq(ns.Fates.NpcOf("Player-93-A"), nil)
  eq(ns.Fates.NpcOf(M.Secret("guid")), nil)
end)

test("Deckel: 300 Zeilen (aelteste gehen), 150 Ursachen (die am laengsten nicht gesehene geht)", function()
  local ns = M.Load()
  local t0 = time() - 100000
  for i = 1, 320 do
    ns.Fates.Record({ t = t0 + i, kind = "pve", zone = "Z", cause = { art = "creature", name = "Wesen" .. i, npc = 10000 + i } })
  end
  local f = ns.Fates.DB()
  eq(#f.rows, 300); eq(f.rows[1].npc, 10320); eq(f.rows[300].npc, 10021)
  local n = 0
  for _ in pairs(f.foes) do n = n + 1 end
  eq(n, 150)
  ok(f.foes["npc:10320"] and not f.foes["npc:10001"], "die juengsten bleiben")
  -- a broken table is repaired at the next start (deckel too)
  _G.DeathNoteDB.fates = { rows = "x", foes = { a = { n = "zwei" }, b = { n = 2, art = "creature" } }, awards = { fall = "gestern", zzz = 1 } }
  ns = M.Load({ db = _G.DeathNoteDB })
  f = ns.Fates.DB()
  eq(#f.rows, 0); eq(f.foes.a, nil); eq(f.foes.b.n, 2); eq(next(f.awards), nil)
end)

test("Schalter aus: nichts Neues, Vorhandenes bleibt", function()
  local ns = M.Load()
  die({ creature(1, "Eber") })
  ns.Store.Setting("fates.on", false)
  die({ creature(1, "Eber") })
  eq(#ns.Fates.Rows(), 1, "nur der erste")
  eq(ns.Fates.DB().foes["npc:1"].n, 1)
  ns.Store.Setting("fates.on", true)
  die({ creature(1, "Eber") })
  eq(#ns.Fates.Rows(), 2)
end)

test("Erzfeind: dreimal dieselbe Kreatur fuehrt die Rangliste, vorher keiner", function()
  local ns = M.Load()
  die({ creature(5, "Wolf") }); die({ creature(6, "Spinne") }); die({ creature(5, "Wolf") })
  eq(ns.Fates.Nemesis(), nil, "zwei reichen nicht")
  die({ creature(5, "Wolf") })
  local top = ns.Fates.Nemesis()
  ok(top and top.name == "Wolf" and top.n == 3 and top.rank == 1, "Wolf mit 3")
  eq(ns.Fates.Ranked()[2].name, "Spinne")
end)

test("Auszeichnungen fuers Sterben: Sturz, Ertrinken, Feuer, Erschoepfung, dreimal, Pechstraehne, Tierkunde", function()
  local ns = M.Load()
  M.ClearFired()
  local got = {}
  ns:On("AWARD", function(id) got[#got + 1] = id end)
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling" }) })
  eq(got[1], "fall", "Sturz nach einem Bild spaeter")
  ok(ns.Fates.Awards().fall, "gespeichert")
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Drowning" }) })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Fire" }) })
  local A = ns.Fates.Awards()
  ok(A.drown and A.fire, "Ertrinken, Feuer")
  ok(A.streak, "drei Tode in zehn Minuten")
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Fatigue" }) })
  ok(ns.Fates.Awards().fatigue)
  for i = 1, 3 do die({ creature(9, "Raptor") }) end
  ok(ns.Fates.Awards().beast3, "dreimal derselbe")
  no(ns.Fates.Awards().zoo)
  for i = 1, 9 do die({ creature(200 + i, "Tier" .. i) }) end
  ok(ns.Fates.Awards().zoo, "zehn verschiedene")
  -- names in every language
  for _, a in ipairs(ns.Fates.AWARDS) do
    local name, cond = ns.Fates.AwardText(a.id)
    ok(type(name) == "string" and name ~= "" and type(cond) == "string" and cond ~= "", "Text " .. a.id)
  end
  eq(ns.Fates.AwardText("first_entry"), nil, "fremde ID")
end)

test("Pechstraehne nur ueber Tode durch Kreaturen und Umwelt; Spielertode bleiben aussen vor", function()
  local ns = M.Load()
  die({ ev({ guid = "Player-93-A", name = "Grimm Bart" }) })
  die({ ev({ guid = "Player-93-A", name = "Grimm Bart" }) })
  die({ creature(3, "Kobold") })
  no(ns.Fates.Awards().streak)
  M.Advance(700)
  die({ creature(3, "Kobold") }); die({ creature(3, "Kobold") })
  no(ns.Fates.Awards().streak, "der erste liegt ueber zehn Minuten zurueck")
end)

test("Woche: andere Tode und die toedlichste Kreatur, nur wenn es welche gab", function()
  local ns = M.Load()
  local files = {}
  for _, f in ipairs(M.FILES) do files[#files + 1] = f end
  -- Share.lua is not in the logic list: load it into the same namespace
  assert(loadfile(M.ADDON_DIR .. "Share.lua"))("DeathNote", ns)
  local line0 = ns.Share.WeekLine()
  no(line0:find(ns.L.SHARE_WEEK_OTHERS:gsub("{count}.*", ""), 1, true), "ohne andere Tode kein Teil: " .. line0)
  die({ creature(11, "Murlocspaeher") }); die({ creature(11, "Murlocspaeher") }); die({ creature(12, "Eber") })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling" }) })
  local line, w = ns.Share.WeekLine()
  eq(w.others, 4)
  ok(line:find("andere Tode: 4", 1, true), line)
  ok(line:find("tödlichste Kreatur: Murlocspaeher 2×", 1, true), line)
  ok(#line <= 255, "eine Chatzeile")
  -- older than a week: not counted
  ns.Fates.DB().rows[1].t = time() - 8 * 86400
  ns.Fates.version = ns.Fates.version + 1
  local _, w2 = ns.Share.WeekLine()
  eq(w2.others, 3)
end)

test("Sonde probe.pve: Zaehler je Art bleiben ueber /dn probe", function()
  local ns = M.Load()
  die({ creature(13, "Eber") })
  die({ ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling" }) })
  ns.Probe.Run(false)
  local p = _G.DeathNoteDB.probe.pve
  ok(p and p.counts, "probe.pve da")
  eq(p.counts.art_creature, 1); eq(p.counts.art_env, 1); eq(p.counts.env_fall, 1)
  eq(p.session.art_creature, 1)
  eq(p.npcApi, false)
  ns.Probe.Run(false)
  eq(_G.DeathNoteDB.probe.pve.counts.art_creature, 1, "bleibt beim zweiten Lauf")
end)

test("Nichts geht ueber die Leitung: ein Tod durch eine Kreatur sendet nichts", function()
  M.Reset()
  local W = M.NewWorld()
  local c = W.client("Anton", "Wurst", "Die Probegilde", {})
  local d = W.client("Berta", "Wurst", "Die Probegilde", {})
  c.login(); d.login(); W.run(5)
  local before = #W.sent
  M.recap = { id = 999, events = { creature(14, "Geheimwesen") } }
  c.fire("PLAYER_DEAD")
  W.run(8)
  for i = before + 1, #W.sent do
    no(tostring(W.sent[i].text):find("Geheimwesen", 1, true), "Kreatur auf der Leitung: " .. tostring(W.sent[i].text))
  end
  eq(#c.ns.Fates.Rows(), 1, "beim Sender erfasst")
  eq(#d.ns.Fates.Rows(), 0, "beim Kollegen nichts")
end)

M.done("to160 alle tode")
