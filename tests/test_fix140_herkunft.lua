-- 1.4.0 fixer (hunt logic 6): "Back up book" carries where a copied entry came from (field 22 of the E line), the own
-- backup brings it back (copied from whom, the guild's or friends' count), and the entry is still never shared. A real
-- 1.3.1 client (ce84dd4) reads such a text without an error, and its own export reads back in 1.4.0.
-- All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")
local GitBase = dofile(ROOT .. "/tests/git_base.lua")

test("Sichern und Einlesen: Herkunft, Zaehler und Zeit kommen zurueck, Eigenes bleibt eigen", function()
  local ns = M.Load()
  local S = ns.Store
  local k = S.AddManual("Grimm", "Bart", { fromGuild = true, adopt = { from = "Wendell Probe", src = "guild", kills = 3 } })
  S.Get(k).fromGuildKills = 3
  local at = S.Get(k).adoptAt
  S.AddManual("Eigen", "Hand")
  local text = S.Export()
  ok(text:find("guild;3;" .. at .. ";Wendell Probe", 1, true), "Feld 22 im Text")
  local ns2 = M.Load()
  ok(ns2.Store.Import(text))
  local e = ns2.Store.Get("Grimm-Bart")
  eq(e.fromGuild, true); eq(e.adoptFrom, "Wendell Probe"); eq(e.adoptSrc, "guild"); eq(e.fromGuildKills, 3)
  eq(e.adoptAt, at)
  ok(ns2.Util.NoteOf(e):find("Wendell", 1, true), ns2.Util.NoteOf(e))
  local own = ns2.Store.Get("Eigen-Hand")
  eq(own.fromGuild, nil); eq(own.adoptFrom, nil)
end)

test("Fremdtext mit kaputtem Feld 22: kein Fehler, nichts Falsches", function()
  local ns = M.Load()
  local line = table.concat({ "E", "Grimm-Bart", "wanted", "1", "0", "0", "0", "", "", "", "0", "ROGUE", "", "40", "", "",
    "Bart", "", "", "0", "0", "quatsch|mehr" }, "|")
  ok(ns.Store.Import("DEATHNOTE:1\n" .. line))
  eq(ns.Store.Get("Grimm-Bart").adoptFrom, nil)
  local line2 = table.concat({ "E", "Fies-Ling", "wanted", "1", "0", "0", "0", "", "", "", "0", "ROGUE", "", "40", "", "",
    "Ling", "", "", "0", "0", "evil;99999999999;9999999999999;" .. ("x"):rep(300) }, "|")
  ok(ns.Store.Import("DEATHNOTE:1\n" .. line2))
  local e = ns.Store.Get("Fies-Ling")
  eq(e.adoptAt, nil, "Zeit in der Zukunft faellt weg"); eq(e.adoptSrc, nil); eq(#e.adoptFrom, 64)
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Ein echter 1.3.1-Client (ce84dd4) liest den Text mit Feld 22 fehlerfrei, sein Export liest zurueck", function()
  local dir, why = GitBase.Archive(ROOT, "ce84dd4")
  if not dir then GitBase.Skip("fix140 herkunft", "1.3.1 client (" .. tostring(why) .. ")"); return end
  M.Reset()
  local W = M.NewWorld()
  local c = W.client("Anton", "Wurst", nil, {})
  c.login(); W.run(2)
  c.ns.Store.AddManual("Grimm", "Bart", { fromGuild = true, adopt = { from = "Wendell Probe", src = "friends", kills = 2 } })
  c.ns.Store.ApplyKill({ name = "Fies", surname = "Ling", guid = "Player-93-Fies" }, { t = time() - 50, zone = "Z", source = "recap" }, true)
  local text = c.ns.Store.Export()
  local oldFiles = {}
  -- (1.5.0: newer files than the tag are left out too: Scene.lua, Chronicle.lua)
  for _, f in ipairs(M.FILES) do
    local h = io.open(dir .. f, "r")
    if h then h:close() end
    if f ~= "Grudge.lua" and h then oldFiles[#oldFiles + 1] = f end
  end
  local o = W.client("Otto", "Alt", nil, { dir = dir, files = oldFiles, version = "1.3.1" })
  o.login(); W.run(2)
  local okI, a = o.ns.Store.Import(text)
  ok(okI, "alter Client liest den Text"); eq(a, 2)
  ok(o.ns.Store.Get("Grimm-Bart") and o.ns.Store.Get("Fies-Ling"), "beide Eintraege da")
  eq(o.ns.Store.Get("Fies-Ling").kills, 1)
  eq(#M.errors, 0, tostring(M.errors[1]))
  local back = o.ns.Store.Export()
  local n = W.client("Neu", "Leser", nil, {})
  n.login(); W.run(2)
  ok(n.ns.Store.Import(back), "1.4.0 liest den Export des alten Clients")
  ok(n.ns.Store.Get("Grimm-Bart"))
  eq(#M.errors, 0, tostring(M.errors[1]))
  GitBase.Clean()
end)

M.done("fix140 herkunft")
