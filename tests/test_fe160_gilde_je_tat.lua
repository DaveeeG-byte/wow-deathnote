-- 1.6.0 feud: the guild of each deed (death, attack, revenge, own kill on the rap sheet) and the page "Which guilds kill
-- you" (Feud.Guilds): a later change of guild never moves old deeds, two killers of one guild in the same death count
-- once, the evaluation is cached until the book changes. All names are made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function kill(S, name, surname, guild, t, role)
  return S.ApplyKill({ name = name, surname = surname, guid = "Player-93-" .. name, guild = guild, class = "ROGUE" },
    { t = t, zone = "Z", source = "recap", role = role }, role ~= "assist")
end
local function guild(list, name)
  for _, g in ipairs(list) do if g.name == name then return g end end
end

test("Tod und Angriff schreiben die Gilde in die Tat", function()
  local ns = M.Load()
  local S = ns.Store
  local k = kill(S, "Grimm", "Bart", "Die Schlaechter", time() - 500)
  eq(S.Get(k).deaths[1].guild, "Die Schlaechter")
  S.AddAttack({ name = "Fies", surname = "Ling", guid = "Player-93-Fies", guild = "Rote Hand" }, { t = time() - 100, zone = "Z" })
  eq(S.Get("Fies-Ling").deaths[1].guild, "Rote Hand", "Angriff mit Gilde")
  local k2 = kill(S, "Ohne", "Gilde", nil, time() - 50)
  eq(S.Get(k2).deaths[1].guild, nil, "ohne Gilde keine Gilde")
  -- a secret guild never lands in a deed
  local k3 = S.ApplyKill({ name = "Geheim", surname = "Nis", guild = M.Secret("guild") }, { t = time() - 40, zone = "Z", source = "recap" }, true)
  eq(S.Get(k3).deaths[1].guild, nil, "secret: keine Gilde")
end)

test("Gildenwechsel bucht nichts rueckwirkend um", function()
  local ns = M.Load()
  local S = ns.Store
  local t = time() - 10000
  kill(S, "Grimm", "Bart", "Die Schlaechter", t)
  kill(S, "Grimm", "Bart", "Die Schlaechter", t + 100)
  -- he is seen in another guild now ("last seen" moves, the deeds stay)
  S.Seen("Grimm-Bart", { guild = "Neue Heimat" }, { t = time(), zone = "Z" }, true)
  eq(S.Get("Grimm-Bart").guild, "Neue Heimat")
  kill(S, "Grimm", "Bart", "Neue Heimat", t + 200)
  local list = ns.Feud.Guilds()
  eq(guild(list, "Die Schlaechter").deaths, 2, "zwei Tode bleiben bei der alten Gilde")
  eq(guild(list, "Neue Heimat").deaths, 1, "der neue Tod bei der neuen Gilde")
  eq(guild(list, "Neue Heimat").n, 1, "Mitglied im Buch: zuletzt gesehen")
  eq(guild(list, "Die Schlaechter").n, 0)
end)

test("Zwei Moerder derselben Gilde in einem Tod: ein Tod", function()
  local ns = M.Load()
  local S = ns.Store
  local t = time() - 3000
  kill(S, "Grimm", "Bart", "Rote Hand", t)
  kill(S, "Fies", "Ling", "Rote Hand", t, "assist")
  kill(S, "Fies", "Ling", "Rote Hand", t + 600)
  local g = guild(ns.Feud.Guilds(), "Rote Hand")
  eq(g.deaths, 2, "der gemeinsame Tod zaehlt einmal")
  eq(g.n, 2, "zwei Mitglieder")
  eq(g.members[1].key, "Fies-Ling", "Mitglieder nach Kills (Fies 1 Kill + 1 Beteiligt, Grimm 1 Kill)")
end)

test("Rache je Gilde: wer sie hatte, als die Rache kam", function()
  local ns = M.Load()
  local S = ns.Store
  kill(S, "Grimm", "Bart", "Die Schlaechter", time() - 9000)
  S.AddRevenge("Grimm-Bart")
  S.Seen("Grimm-Bart", { guild = "Neue Heimat" }, { t = time(), zone = "Z" }, true)
  S.AddRevenge("Grimm-Bart", true)
  local e = S.Get("Grimm-Bart")
  eq(e.revGuild["Die Schlaechter"], 1); eq(e.revGuild["Neue Heimat"], 1)
  local list = ns.Feud.Guilds()
  eq(guild(list, "Die Schlaechter").rev, 1); eq(guild(list, "Neue Heimat").rev, 1)
  S.UndoRevenge("Grimm-Bart")
  eq(e.revGuild["Neue Heimat"], nil, "zurueckgenommen: weg bei der Gilde")
  eq(guild(ns.Feud.Guilds(), "Neue Heimat").rev, 0)
  -- a book before 1.6.0: revenge without guilds counts for "last seen"
  e.revGuild = nil
  e.revenge = 3
  ns.Feud.Touched()
  eq(guild(ns.Feud.Guilds(), "Neue Heimat").rev, 3)
end)

test("Mehr Kills als Taten (Deckel 30): der Rest zaehlt fuer zuletzt gesehen", function()
  local ns = M.Load()
  local S = ns.Store
  for i = 1, 35 do kill(S, "Grimm", "Bart", "Rote Hand", time() - 100000 + i * 100) end
  eq(#S.Get("Grimm-Bart").deaths, 30)
  eq(guild(ns.Feud.Guilds(), "Rote Hand").deaths, 35)
end)

test("Auswertung gecacht: neu gerechnet nur nach einer Aenderung", function()
  local ns = M.Load()
  local S = ns.Store
  kill(S, "Grimm", "Bart", "Rote Hand", time() - 500)
  local F = ns.Feud
  F.Guilds()
  local b = F.builds
  for _ = 1, 20 do F.Guilds() end
  eq(F.builds, b, "zwanzig Abfragen, keine neue Rechnung")
  kill(S, "Fies", "Ling", "Rote Hand", time() - 400)
  F.Guilds()
  eq(F.builds, b + 1, "nach einem neuen Tod einmal")
end)

test("Strafregister: die Gilde des Opfers steht in der eigenen Tat", function()
  local ns = M.Load()
  local Lg = ns.Ledger
  local d = Lg.DB()
  ok(d, "Strafregister da")
  local row = { t = time(), key = "Opfer-Lamm", name = "Opfer Lamm", band = "gelb", r = 0, e = 0, j = 0, s = 0, f = "",
    guild = "Rote|Hand\1" }
  table.insert(d.log, 1, row)
  ns.Store.Init()
  eq(Lg.DB().log[1].guild, "RoteHand", "Steuerzeichen und | weg")
end)

test("Kaputte Gildenfelder werden repariert", function()
  local ns = M.Load({ db = { enemies = { ["Grimm-Bart"] = { kills = 1, deaths = { { t = 5, role = "kill", guild = 7 } },
    revenge = 1, revGuild = { ["Rote Hand"] = 5, [3] = 1 }, day = "x", keep = "ja" } } } })
  local e = ns.Store.Get("Grimm-Bart")
  eq(e.deaths[1].guild, nil); eq(e.revGuild, nil, "mehr Rache je Gilde als Rache: weg")
  eq(type(e.day), "number", "Spieltag neu gesetzt"); eq(e.keep, nil)
end)

M.done("fe160_gilde_je_tat")
