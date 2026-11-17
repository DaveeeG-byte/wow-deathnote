-- 1.4.0 overview: taking over a friend's or guildmate's list (Guild.Adopt with origin, friends' book too), never shared,
-- the text book with preview, a friend's text as a taken-over list, undo of an import. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function world()
  M.Reset()
  return M.NewWorld()
end

local function kill(c, name, surname, dt, role)
  local t = time() - (dt or 0)
  local me = c.name .. " " .. c.surname
  local key = c.ns.Store.ApplyKill({ name = name, surname = surname, class = "MAGE", level = 36 },
    { t = t, zone = "Schlingendorntal", me = me, myLevel = 34, source = "recap", others = {} }, role ~= "assist")
  c.ns:Fire("DEATH_RECORDED", { t = t, zone = "Schlingendorntal", me = me, kind = "pvp",
    sure = true, counted = true, killerKey = key, source = "recap" }, key)
  return key
end

-- addon messages of a client of one kind ("M" = listed by hand) that name a key's first name
local function sentAbout(W, from, kind, first)
  local n = 0
  for _, m in ipairs(W.sent) do
    local who = m.from or (m.sender and (m.sender.name .. "-Forever"))
    if who and who:find("^" .. from) and m.text:match("^1\t(%u)\t") == kind and m.text:find(first, 1, true) then n = n + 1 end
  end
  return n
end

local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

-- Anton and Berta are friends without a guild; Anton killed Berta's... no: Anton was killed by two players, Berta sees
-- them in the friends' book
local function friends()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login()
  local k1 = kill(a, "Grimm", "Bart", 600)
  kill(a, "Grimm", "Bart", 500)
  local k2 = kill(a, "Fies", "Ling", 400)
  W.run(60)
  return W, a, b, k1, k2
end

test("Freundesbuch: ein Täter nur beim Freund lässt sich übernehmen (vorher: nichts passierte)", function()
  local W, a, b, k1 = friends()
  ok(b.ns.Guild.Get(k1, "friends"), "Täter steht im Freundesbuch")
  no(b.ns.Guild.Get(k1, "guild"), "nicht im Gildenbuch")
  local k = b.ns.Guild.Adopt(k1)
  eq(k, k1, "Übernehmen liefert den Schlüssel")
  local e = b.ns.Store.Get(k1)
  ok(e, "steht im eigenen Buch")
  eq(e.manual, true); eq(e.fromGuild, true)
  eq(e.adoptSrc, "friends"); eq(e.adoptFrom, "Anton Wurst"); eq(e.fromGuildKills, 2)
  ok(type(e.adoptAt) == "number")
  eq(e.kills, 0, "fremde Tode zählen nicht als Tode an mir")
  local note = b.ns.Util.NoteOf(e)
  ok(note:find("Anton", 1, true) and note:find("Freunde", 1, true), note)
  noErrors()
end)

test("Übernommenes wird nie weitergeteilt (Gilde, Freunde, Antwort auf Hallo)", function()
  local W, a, b, k1 = friends()
  local c = W.client("Clara", "Kraut", nil, { friends = { "Berta" } })
  b.ns.Guild.Adopt(k1)
  W.run(5)
  c.login()
  W.run(90)                         -- Clara says hello to Berta, Berta answers with her own entries
  eq(sentAbout(W, "Berta", "M", "Grimm"), 0, "kein M über den übernommenen Täter")
  no(c.ns.Guild.Get(k1, "friends") and c.ns.Guild.Get(k1, "friends").listedBy
     and c.ns.Guild.Get(k1, "friends").listedBy["Berta Senf"], "Clara hört nichts von Berta über ihn")
  -- a name entered by hand is still shared (the rule is about origin only)
  b.ns.Store.AddManual("Hand", "Arbeit")
  W.run(5)
  ok(sentAbout(W, "Berta", "M", "Hand") >= 1, "Hand-Eintrag geht weiter raus")
  noErrors()
end)

test("Gilde: Übernehmen vermerkt den Kollegen (Opfer) als Herkunft", function()
  local W = world()
  local a = W.client("Anton", "Wurst", "Die Wurstbrüder")
  local b = W.client("Berta", "Senf", "Die Wurstbrüder")
  a.login(); b.login()
  W.run(30)
  local k = kill(a, "Grimm", "Bart", 10)
  W.run(5)
  ok(b.ns.Guild.Get(k, "guild"), "im Gildenbuch")
  b.ns.Guild.Adopt(k)
  local e = b.ns.Store.Get(k)
  eq(e.adoptSrc, "guild"); eq(e.adoptFrom, "Anton Wurst")
  ok(b.ns.Util.NoteOf(e):find("Gildenbuch", 1, true), b.ns.Util.NoteOf(e))
  -- an explicit origin (the section of "By guildmate") wins
  local k2 = kill(a, "Zwei", "Fach", 5)
  W.run(5)
  b.ns.Guild.Adopt(k2, { from = "Clara Kraut", src = "guild" })
  eq(b.ns.Store.Get(k2).adoptFrom, "Clara Kraut")
  noErrors()
end)

test("Buch einlesen: Vorschau ändert nichts, erkennt fremdes Buch", function()
  local W, a, b = friends()
  local text = a.ns.Store.Export()
  local before = 0
  for _ in pairs(b.ns.Store.All and b.ns.Store.All() or {}) do before = before + 1 end
  local okp, info = b.ns.Store.ImportPreview(text)
  ok(okp, tostring(info))
  eq(info.total, 2); eq(info.new, 2); eq(info.have, 0)
  eq(info.owner, "Anton Wurst"); eq(info.ownerMine, false)
  no(b.ns.Store.Get("Grimm-Bart"), "Vorschau trägt nichts ein")
  -- the own text is recognised as own
  local okm, mine = a.ns.Store.ImportPreview(text)
  ok(okm); eq(mine.ownerMine, true); eq(mine.have, 2); eq(mine.new, 0)
  -- broken text: the same message as the import
  local bad, msg = b.ns.Store.ImportPreview("Hallo")
  eq(bad, false); ok(type(msg) == "string")
  noErrors()
end)

test("Buch eines Freundes einlesen: nur Gesuchte, als übernommen, seine Tode bleiben seine", function()
  local W, a, b, k1, k2 = friends()
  a.ns.Store.AddManual("Nur", "Gedacht")
  a.ns.Store.SetStatus(k2, "pardoned")
  b.ns.Store.AddManual("Schon", "Da")
  a.ns.Store.AddManual("Schon", "Da")
  local text = a.ns.Store.Export()
  local okp, info = b.ns.Store.ImportPreview(text)
  ok(okp); eq(info.wantedNew, 2, "Grimm und Nur"); eq(info.wantedHave, 1, "Schon Da")
  local okf, added, have = b.ns.Store.ImportFriend(text, info.owner)
  ok(okf, tostring(added))
  eq(#added, 2); eq(have, 1)
  local g = b.ns.Store.Get(k1)
  ok(g, "Grimm übernommen"); eq(g.kills, 0); eq(g.fromGuildKills, 2); eq(g.adoptSrc, "text")
  eq(g.adoptFrom, "Anton Wurst"); eq(g.class, "MAGE"); eq(g.level, 36)
  eq(#g.deaths, 0, "keine fremden Todeszeilen")
  no(b.ns.Store.Get(k2), "beim Freund Begnadigte bleiben draußen")
  ok(b.ns.Util.NoteOf(g):find("Anton", 1, true), b.ns.Util.NoteOf(g))
  eq(b.ns.Store.Get("Schon-Da").adoptSrc, nil, "Vorhandenes bleibt unberührt")
  W.run(30)
  eq(sentAbout(W, "Berta", "M", "Grimm"), 0, "nichts davon geht an Freunde")
  noErrors()
end)

test("Buch einlesen (eigenes) lässt sich einmal zurücknehmen", function()
  local W, a, b, k1 = friends()
  local backup = a.ns.Store.Export()
  -- a later state: Grimm got one more kill, Fies was struck
  kill(a, "Grimm", "Bart", 30)
  local fies = a.ns.Store.Find("Fies", "Ling")
  a.ns.Store.Remove(fies)
  eq(a.ns.Store.Get(k1).kills, 3)
  local deaths = #a.ns.Store.Get(k1).deaths
  local okp, n1, n2 = a.ns.Store.Import(backup)
  ok(okp); eq(n1, 1); eq(n2, 1)
  ok(a.ns.Store.Get(fies), "Fies wieder da")
  ok(a.ns.Store.CanUndoImport())
  local n = a.ns.Store.UndoImport()
  eq(n, 2)
  no(a.ns.Store.Get(fies), "Fies wieder weg")
  eq(a.ns.Store.Get(k1).kills, 3, "Zähler wie vorher")
  eq(#a.ns.Store.Get(k1).deaths, deaths, "Taten wie vorher")
  no(a.ns.Store.CanUndoImport(), "nur einmal")
  eq(a.ns.Store.UndoImport(), 0)
  noErrors()
end)

M.done("overview")
