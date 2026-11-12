-- 1.1.0: names listed by hand shared in the guild (M/X), view by member, new settings, CleanName.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local GUILD = "Die Wurstbrüder"

local function loadGuild(opts)
  opts = opts or {}
  return M.Load({ before = function()
    if opts.db then _G.DeathNoteDB = opts.db end
    if opts.guild ~= false then M.units.player.guild = opts.guild or GUILD end
  end })
end

local function hear(text, sender)
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender or "Kollege-Forever")
end

local function killMsg(ns, o)
  o = o or {}
  return ns.Guild.Proto.EncodeKill({ key = o.key or "Grimm-Bart", display = o.display or "Grimm Bart",
    class = o.class or "ROGUE", level = o.level or 44, zone = o.zone or "Arathihochland",
    t = o.t or time(), victim = o.victim or "Kollege Wurst" }, o.kind or "K")
end

local function listMsg(ns, o)
  o = o or {}
  return ns.Guild.Proto.EncodeListed({ key = o.key or "Grimm-Bart", display = o.display or "Grimm Bart",
    class = o.class, level = o.level, t = o.t or (time() - 60), by = o.by or "Kollege Wurst" })
end

-- "Laa", "Lab", ... valid first names
local function alpha(i)
  local a, b, c = math.floor(i / 676) % 26, math.floor(i / 26) % 26, i % 26
  return string.char(97 + a, 97 + b, 97 + c)
end
local function keyN(prefix, i) return prefix .. alpha(i) .. "-Bart" end

local function sentOf(list, kind, from)
  local out = {}
  for _, m in ipairs(list) do
    if m.text:find("^1\t" .. kind .. "\t") and (not from or m.from == from) then out[#out + 1] = m end
  end
  return out
end

---------------------------------------------------------------------------
-- Protocol
---------------------------------------------------------------------------
test("M und X: Kodieren/Dekodieren mit Umlauten, Trennern, 255 Bytes", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local t = time() - 100
  local text = P.EncodeListed({ key = "Ärger-Möhrenkönig", display = "Ärger Möhrenkönig", class = "MAGE",
    level = 60, t = t, by = "Grüß Gott%7C" })
  ok(text and #text <= 255)
  eq(select(2, text:gsub("\t", "")), 7, "genau 7 Trenner")
  local m = P.Decode(text, time(), {})
  ok(m, "dekodiert")
  eq(m.kind, "M"); eq(m.key, "Ärger-Möhrenkönig"); eq(m.name, "Ärger"); eq(m.surname, "Möhrenkönig")
  eq(m.display, "Ärger Möhrenkönig"); eq(m.class, "MAGE"); eq(m.level, 60); eq(m.t, t); eq(m.by, "Grüß Gott%7C")
  -- unknown class/level travel as empty
  m = P.Decode(P.EncodeListed({ key = "Grimm-Bart", t = t, by = "Kollege Wurst" }), time(), {})
  eq(m.class, nil); eq(m.level, nil); eq(m.display, "Grimm Bart")
  local x = P.Decode(P.EncodeUnlisted("Ärger-Möhrenkönig", "Grüß Gott"), time(), {})
  eq(x.kind, "X"); eq(x.key, "Ärger-Möhrenkönig"); eq(x.by, "Grüß Gott")
  -- 255 bytes: a key full of '%' (3 bytes each on the wire) drops the display name first
  local key = "Grimm-" .. string.rep("%", 50)
  ok(P.ValidKey(key), "Schlüssel gültig")
  local long = P.EncodeListed({ key = key, display = "Grimm " .. string.rep("%", 50), t = t, by = "Kollege Wurst" })
  ok(long and #long <= 255, "passt, war " .. tostring(long and #long))
  local lm = P.Decode(long, time(), {})
  ok(lm); eq(lm.key, key); eq(lm.by, "Kollege Wurst")
  no(P.EncodeListed({ key = key, t = t, by = string.rep("%", 40) }), "nicht kodierbar -> nil")
  no(P.Decode(long .. string.rep("x", 256 - #long), time(), {}), "über 255 verworfen")
  -- nothing with control bytes or '|' is ever sent
  no(P.EncodeListed({ key = "Grimm-Bart", t = t, by = "Kol|lege" }))
  no(P.EncodeListed({ key = "Gri\nmm-Bart", t = t, by = "Kollege" }))
  no(P.EncodeUnlisted("Grimm-Bart", "")); no(P.EncodeUnlisted("Grimm-Bart", "a\tb"))
end)

test("M und X: kaputte Nachrichten werden verworfen, nichts wirft", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local now = time()
  local bad = {
    "1\tM\tGrimm-Bart\t\t\t0\t" .. now,                                     -- field missing
    "1\tM\tGrimm-Bart\t\t\t0\t" .. now .. "\tKollege\textra",
    "1\tM\tGrimm-Bart\t\t\t0\t" .. (now + 3600) .. "\tKollege",             -- future
    "1\tM\tGrimm-Bart\t\t\t0\t" .. (now - 6 * 365 * 86400) .. "\tKollege", -- too old
    "1\tM\tGrimm-Bart\t\t\t0\t" .. now .. "\t",                             -- no char
    "1\tM\tgrimm-bart\t\t\t0\t" .. now .. "\tKollege",                      -- not canonical
    "1\tM\tGrimm-Bart\t\trogue\t0\t" .. now .. "\tKollege",
    "1\tM\tGrimm-Bart\t\t\t999\t" .. now .. "\tKollege",
    "1\tM\tGrimm-Bart\t\t\t0\t" .. now .. "\tKol%7Clege",                   -- '|' in the char
    "1\tM\tGrimm-Bart\t\t\t0\t" .. now .. "\t" .. string.rep("k", 65),
    "1\tX\tGrimm-Bart", "1\tX\tGrimm-Bart\t", "1\tX\tGrimm-Bart\tA\tB", "1\tX\tGrimm\tKollege",
  }
  for i, b in ipairs(bad) do
    local okc, m = pcall(P.Decode, b, now, {})
    ok(okc, "wirft nicht #" .. i); no(m, "verworfen #" .. i)
  end
  local good = listMsg(ns)
  for n = 0, #good - 1 do
    local okc, m = pcall(P.Decode, good:sub(1, n), now, {})
    ok(okc, "abgeschnitten " .. n)
    if m then ok(m.by and ("Kollege Wurst"):sub(1, #m.by) == m.by, "Teil-Char " .. n) end
  end
  math.randomseed(11)
  for _ = 1, 2000 do
    local t = {}
    for j = 1, math.random(0, 120) do
      local r = math.random(1, 8)
      t[j] = r <= 2 and "\t" or (r == 3 and "%" or string.char(math.random(0, 255)))
    end
    hear((math.random() < 0.5 and "1\tM\t" or "1\tX\t") .. table.concat(t), "Troll" .. math.random(1, 30) .. "-Forever")
  end
  eq(#M.errors, 0, tostring(M.errors[1]))
  eq(ns.Guild.Count(), 0)
  ok(ns.Guild.stats.listDropped > 0 and ns.Guild.stats.unlistDropped > 0, "Probe zählt verworfene M/X")
end)

---------------------------------------------------------------------------
-- Receiving: sender check, caps, eviction
---------------------------------------------------------------------------
test("Empfang: listedBy, Absenderprüfung, X nur vom Eintragenden", function()
  local ns = loadGuild()
  local t = time() - 30
  hear(listMsg(ns, { t = t, class = "ROGUE", level = 50 }), "Kollege-Forever")
  local e = ns.Guild.Get("Grimm-Bart")
  ok(e, "angelegt"); eq(e.listedBy["Kollege Wurst"], t); eq(e.kills, 0); eq(e.listedCount, 1)
  eq(e.listedOnly, true); eq(e.class, "ROGUE"); eq(e.level, 50); eq(#e.deeds, 0)
  -- another char's name than the sender: dropped
  hear(listMsg(ns, { key = "Fremd-Ling", by = "Anna Blume" }), "Kollege-Forever")
  no(ns.Guild.Get("Fremd-Ling"), "Char passt nicht zum Absender")
  -- X for Kollege's listing from somebody else: ignored
  hear(ns.Guild.Proto.EncodeUnlisted("Grimm-Bart", "Kollege Wurst"), "Anna-Forever")
  ok(ns.Guild.Get("Grimm-Bart"), "X eines anderen wirkt nicht")
  hear(ns.Guild.Proto.EncodeUnlisted("Grimm-Bart", "Anna Blume"), "Anna-Forever")
  ok(ns.Guild.Get("Grimm-Bart"), "X ohne eigene Eintragung wirkt nicht")
  -- the same listing twice: no change
  M.Advance(1)
  M.ClearFired()
  hear(listMsg(ns, { t = t }), "Kollege-Forever")
  M.Advance(1)
  eq(#M.Fired("GUILD_UPDATED"), 0, "Duplikat ändert nichts")
  -- a kill on top: entry with both
  hear(killMsg(ns, { t = time() - 5, victim = "Anna Blume" }), "Anna-Forever")
  e = ns.Guild.Get("Grimm-Bart")
  eq(e.kills, 1); eq(e.listedCount, 1); eq(e.listedOnly, false)
  -- X: listing gone, entry stays because of the kill
  hear(ns.Guild.Proto.EncodeUnlisted("Grimm-Bart", "Kollege Wurst"), "Kollege-Forever")
  e = ns.Guild.Get("Grimm-Bart")
  ok(e); eq(e.listedBy, nil); eq(e.listedCount, 0); eq(e.kills, 1)
  -- listed only + X: entry gone
  hear(listMsg(ns, { key = "Nur-Gelistet" }), "Kollege-Forever")
  ok(ns.Guild.Get("Nur-Gelistet"))
  hear(ns.Guild.Proto.EncodeUnlisted("Nur-Gelistet", "Kollege Wurst"), "Kollege-Forever")
  no(ns.Guild.Get("Nur-Gelistet"), "weder Kills noch Eintragung: weg")
  eq(ns.Guild.Count(), 1)
  local st = ns.Guild.stats
  ok(st.listReceived >= 3 and st.unlistReceived >= 3)
  eq(#M.errors, 0)
end)

test("Deckel: 20 Eintragungen je Absender, zusammen mit Kills höchstens 40 Feinde", function()
  local ns = loadGuild()
  for i = 1, 25 do hear(listMsg(ns, { key = keyN("L", i), by = "Flut Wurst" }), "Flut-Forever") end
  local _, _, listed = ns.Guild.Count()
  eq(listed, 20, "höchstens 20 von einem Mitglied")
  -- an entry with kills of somebody else counts too, without creating an entry
  hear(killMsg(ns, { key = "Grimm-Bart", t = time() - 5, victim = "Anna Blume" }), "Anna-Forever")
  hear(listMsg(ns, { key = "Grimm-Bart", by = "Flut Wurst" }), "Flut-Forever")
  no(ns.Guild.Get("Grimm-Bart").listedBy, "21. Eintragung verworfen, auch auf vorhandenem Eintrag")
  -- kills of the same member: 40 entries in all
  for i = 1, 30 do hear(killMsg(ns, { key = keyN("K", i), t = time() - i, victim = "Flut Wurst" }), "Flut-Forever") end
  eq(ns.Guild.Count(), 41, "20 gelistet + 20 Kills von Flut + 1 von Anna")
  -- after X there is room again for one listing
  hear(ns.Guild.Proto.EncodeUnlisted(keyN("L", 1), "Flut Wurst"), "Flut-Forever")
  hear(listMsg(ns, { key = "Grimm-Bart", by = "Flut Wurst" }), "Flut-Forever")
  ok(ns.Guild.Get("Grimm-Bart").listedBy, "Platz nach X")
  -- flood guard as for K: message 151 in a minute is dropped
  M.Advance(61)
  local msg = listMsg(ns, { key = "Dup-Licat", by = "Viel Wurst" })
  for _ = 1, 150 do hear(msg, "Viel-Forever") end
  hear(listMsg(ns, { key = "Neu-Ling", by = "Viel Wurst" }), "Viel-Forever")
  no(ns.Guild.Get("Neu-Ling"), "Flutschutz")
end)

test("Verdrängung: reine Hand-Einträge fallen vor Einträgen mit Kills", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local st = { enemies = {}, count = 0 }
  local base = time() - 100000
  local function kill(key, by, t)
    local n, s = P.ValidKey(key)
    return P.Merge(st, { key = key, name = n, surname = s, t = t, victim = by .. " V" }, by)
  end
  local function list(key, by, t)
    local n, s = P.ValidKey(key)
    return P.MergeListed(st, { key = key, name = n, surname = s, t = t, by = by .. " V" }, by)
  end
  for i = 1, 385 do kill(keyN("A", i), "Anna", base + i) end
  for i = 1, 5 do list(keyN("L", i), "Anna", base + 1000 + i) end      -- Anna: top sender
  for i = 1, 10 do list(keyN("B", i), "Bert", base + 2000 + i) end
  eq(st.count, 400)
  for i = 1, 5 do kill(keyN("N", i), "Cora", base + 5000 + i) end
  eq(st.count, 400)
  for i = 1, 5 do no(st.enemies[keyN("L", i)], "Annas Hand-Einträge zuerst " .. i) end
  for i = 1, 10 do ok(st.enemies[keyN("B", i)], "Berts noch da " .. i) end
  ok(st.enemies[keyN("A", 1)], "ältester Kill bleibt, solange es Hand-Einträge gibt")
  for i = 6, 8 do kill(keyN("N", i), "Cora", base + 5000 + i) end
  no(st.enemies[keyN("B", 1)]); no(st.enemies[keyN("B", 3)]); ok(st.enemies[keyN("B", 4)], "älteste Eintragung zuerst")
  ok(st.enemies[keyN("A", 1)])
  for i = 9, 20 do kill(keyN("N", i), "Cora", base + 5000 + i) end
  for i = 1, 10 do no(st.enemies[keyN("B", i)]) end
  no(st.enemies[keyN("A", 1)], "danach wie bisher: ältester Kill des größten Absenders")
  eq(st.count, 400)
  -- counters stay right
  local n = 0
  for _ in pairs(st.enemies) do n = n + 1 end
  eq(n, 400)
  eq(st.listedBySender and st.listedBySender.bert, nil)
end)

---------------------------------------------------------------------------
-- Two clients
---------------------------------------------------------------------------
test("Zwei Clients: eintragen, löschen, begnadigen, Antwort auf Hallo, Übernahme ohne Echo", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD)
  local b = W.client("Berta", "Senf", GUILD)
  a.login(); b.login()
  W.run(30)
  -- A enters a name by hand: B sees it at once
  local key = a.ns.Store.AddManual("Grimm", "Bart")
  eq(a.ns.Store.Get(key).by, "Anton Wurst"); ok(a.ns.Store.Get(key).listedAt)
  W.run(1)
  local e = b.ns.Guild.Get("Grimm-Bart")
  ok(e, "B hat den Eintrag"); eq(e.listedBy["Anton Wurst"], a.ns.Store.Get(key).listedAt); eq(e.listedOnly, true)
  ok(a.ns.Guild.Get("Grimm-Bart").listedBy["Anton Wurst"], "A sieht seinen eigenen Beitrag")
  eq(#sentOf(W.sent, "M", "Anton-Forever"), 1)
  -- A deletes: gone at B
  a.ns.Store.Remove(key)
  W.run(1)
  no(b.ns.Guild.Get("Grimm-Bart"), "gelöscht -> bei B weg")
  no(a.ns.Guild.Get("Grimm-Bart"))
  -- A again, then pardons: gone; pardon lifted: back
  key = a.ns.Store.AddManual("Grimm", "Bart")
  W.run(1)
  ok(b.ns.Guild.Get("Grimm-Bart"))
  a.ns.Store.SetStatus(key, "pardoned")
  W.run(1)
  no(b.ns.Guild.Get("Grimm-Bart"), "begnadigt -> weg")
  a.ns.Store.SetStatus(key, "wanted")
  W.run(1)
  ok(b.ns.Guild.Get("Grimm-Bart"), "Begnadigung aufgehoben -> wieder da")
  -- never sent: suspects, imported entries
  a.ns.Store.ApplyKill({ name = "Ver", surname = "Dacht" }, { t = time(), zone = "Z", me = "Anton Wurst", source = "suspect", others = {} }, false)
  ok(a.ns.Store.Import("DEATHNOTE:1\nE|Import-Iert|wanted|1|0|0|0|||||ROGUE|||||Iert||"))
  ok(a.ns.Store.Get("Import-Iert").imported, "Import markiert")
  -- B takes A's entry over into the own book: B must not send it back
  local before = #W.sent
  local k2 = b.ns.Guild.Adopt("Grimm-Bart")
  eq(k2, "Grimm-Bart"); ok(b.ns.Store.Get(k2).fromGuild)
  W.run(1)
  eq(#sentOf({ unpack(W.sent, before + 1) }, "M"), 0, "Übernommenes geht nicht zurück")
  -- C logs in later: the answer to the hello carries A's listing
  local c = W.client("Cäsar", "Senf", GUILD)
  c.login()
  W.run(40)
  local ce = c.ns.Guild.Get("Grimm-Bart")
  ok(ce, "C hat den Eintrag aus der Antwort"); ok(ce.listedBy["Anton Wurst"])
  no(ce.listedBy["Berta Senf"], "B hat nichts zurückgesendet")
  no(c.ns.Guild.Get("Import-Iert")); no(c.ns.Guild.Get("Ver-Dacht"))
  local replyM = sentOf(W.sent, "M", "Berta-Forever")
  eq(#replyM, 0, "B sendet nie ein M für Übernommenes, auch nicht in Antworten")
  -- C is offline while A deletes: the X comes with the next answer
  c.guild = "Offline"
  a.ns.Store.Remove(key)
  W.run(1)
  ok(c.ns.Guild.Get("Grimm-Bart"), "C hat das X verpasst")
  c.guild = GUILD
  W.run(301)
  ok(c.ns.Guild.SyncNow())
  W.run(30)
  no(c.ns.Guild.Get("Grimm-Bart"), "X kam mit der Antwort")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("shareManual = false sendet nichts, Wiedereinschalten holt nach", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD)
  local b = W.client("Berta", "Senf", GUILD)
  a.login(); b.login()
  W.run(30)
  a.ns.Store.Setting("guild.shareManual", false)
  local key = a.ns.Store.AddManual("Grimm", "Bart")
  W.run(1)
  a.ns.Store.AddManual("Zweiter", "Mann")
  a.ns.Store.Remove("Zweiter-Mann")
  W.run(301)
  ok(b.ns.Guild.SyncNow())                     -- A answers, without M
  W.run(30)
  eq(#sentOf(W.sent, "M", "Anton-Forever"), 0, "kein M")
  eq(#sentOf(W.sent, "X", "Anton-Forever"), 0, "kein X")
  no(b.ns.Guild.Get("Grimm-Bart"))
  no(a.ns.Guild.Get("Grimm-Bart"), "auch nicht in der eigenen Gildenansicht")
  a.ns.Store.Setting("guild.shareManual", true)
  W.run(2)
  ok(b.ns.Guild.Get(key), "nach dem Einschalten gesendet")
  eq(#M.errors, 0)
end)

test("Alter Client (1.0.0, kennt M/X nicht): verwirft still, wirft nicht", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD)
  -- 1.0.0 emulated: the type table without M and X
  local old = W.client("Olaf", "Alt", GUILD, { version = "1.0.0", patch = function(f, src)
    if f ~= "Sync.lua" then return src end
    local s, n = src:gsub("M = 8, X = 4 ", "")
    assert(n == 1)
    return s
  end })
  local clients = { a, old }
  -- the installed 1.0.0, when it is there (read only)
  -- path of an installed copy via environment variable DEATHNOTE_INSTALLED (with trailing slash); skipped without it
  local dir = os.getenv("DEATHNOTE_INSTALLED")
  local h = dir and io.open(dir .. "DeathNote.toc")
  local real
  if h then
    local toc = h:read("*a"); h:close()
    if toc:find("## Version: 1.0.0", 1, true) then
      real = W.client("Rolf", "Echt", GUILD, { dir = dir, version = "1.0.0" })
      clients[#clients + 1] = real
    end
  end
  for _, c in ipairs(clients) do c.login() end
  W.run(30)
  a.ns.Store.AddManual("Grimm", "Bart")
  a.ns.Store.AddManual("Zwei", "Te")
  -- (fix-1) out first, then remove: a still waiting M cancels the X (only the last word counts)
  W.run(1)
  a.ns.Store.Remove("Zwei-Te")
  W.run(2)
  ok(#sentOf(W.sent, "M") >= 2 and #sentOf(W.sent, "X") >= 1, "M und X waren auf der Leitung")
  eq(#M.errors, 0, tostring(M.errors[1]))
  no(old.ns.Guild.Get("Grimm-Bart"))
  ok(old.ns.Guild.stats.dropped >= 3, "verworfen")
  eq(old.ns.Guild.stats.lastReason, "type")
  if real then
    no(real.ns.Guild.Get("Grimm-Bart")); eq(real.ns.Guild.stats.lastReason, "type")
    io.write("  (echter 1.0.0-Client aus dem Spielordner mitgetestet)\n")
  end
  -- and the other way round: kills of the old client still arrive
  local P = a.ns.Guild.Proto
  W.wire[#W.wire + 1] = { prefix = "DeathNote", channel = "GUILD", from = "Olaf-Forever", guild = GUILD,
    text = P.EncodeKill({ key = "Alt-Feind", t = time() - 5, victim = "Olaf Alt" }, "K") }
  W.run(1)
  ok(a.ns.Guild.Get("Alt-Feind"))
end)

test("Altes Eintrag ohne by: gehört dem Char, der ihn zuerst sendet; Rekey schickt X und M", function()
  local db = { version = 2, settings = {}, deaths = {}, enemies = {
    ["Alt-Hand"] = { key = "Alt-Hand", name = "Alt", realm = "Hand", surname = "Hand", manual = true, kills = 0,
      status = "wanted", deaths = {} } } }
  local ns = loadGuild({ db = db })
  M.Advance(30)
  eq(ns.Store.Get("Alt-Hand").by, nil, "nicht beim Login vereinnahmt")
  M.addonSent = {}
  hear("1\tH\t0\t1.1.0", "Kollege-Forever")
  M.Advance(30)
  local ms = sentOf(M.addonSent, "M")
  eq(#ms, 1)
  local m = ns.Guild.Proto.Decode(ms[1].text, time(), {})
  eq(m.key, "Alt-Hand"); eq(m.by, "Varorak Narenmar")
  eq(ns.Store.Get("Alt-Hand").by, "Varorak Narenmar", "beim ersten Senden vereinnahmt")
  ok(ns.Guild.Get("Alt-Hand").listedBy["Varorak Narenmar"], "in der eigenen Gildenansicht")
  -- placeholder (first name only) learns the surname: X old key, M new key
  M.addonSent = {}
  ns.Store.AddManual("Grimm")
  eq(sentOf(M.addonSent, "M")[1].text:match("^1\tM\t([^\t]+)"), "Grimm-Forever")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.Advance(2)
  ok(ns.Store.Get("Grimm-Bart"), "befördert")
  eq(sentOf(M.addonSent, "X")[1].text:match("^1\tX\t([^\t]+)"), "Grimm-Forever")
  eq(sentOf(M.addonSent, "M")[2].text:match("^1\tM\t([^\t]+)"), "Grimm-Bart")
  no(ns.Guild.Get("Grimm-Forever")); ok(ns.Guild.Get("Grimm-Bart"))
  -- an entry with control bytes is never listable
  ok(not ns.Guild.Listable("Gri|mm-Bart", { manual = true, status = "wanted", name = "Gri|mm", deaths = {} }))
  eq(#M.errors, 0)
end)

---------------------------------------------------------------------------
-- Reading API
---------------------------------------------------------------------------
test("List/Count: Hand-Einträge am Ende von rank, listedOnly, opts.only", function()
  local ns = loadGuild()
  hear(listMsg(ns, { key = "Nur-Gelistet", t = time() - 10 }))
  hear(listMsg(ns, { key = "Auch-Gelistet", t = time() - 20 }))
  hear(killMsg(ns, { key = "Eins-A", t = time() - 100 }))
  hear(killMsg(ns, { key = "Zwei-B", t = time() - 5, victim = "Kollege W2" }))
  hear(killMsg(ns, { key = "Zwei-B", t = time() - 6, victim = "Kollege W3" }))
  local r = ns.Guild.List("rank")
  eq(#r, 4, "alte Aufrufer sehen alles")
  eq(r[1].key, "Zwei-B"); eq(r[2].key, "Eins-A"); eq(r[3].key, "Nur-Gelistet"); eq(r[4].key, "Auch-Gelistet")
  ok(r[3].listedOnly); no(r[1].listedOnly)
  eq(#ns.Guild.List("rank", { only = "kills" }), 2)
  local l = ns.Guild.List("recent", { only = "listed" })
  eq(#l, 2); ok(l[1].listedOnly)
  eq(ns.Guild.Rank("Nur-Gelistet"), 3)
  local f, d, listed = ns.Guild.Count()
  eq(f, 4); eq(d, 3); eq(listed, 2)
  ok(ns.Guild.List("rank") == r, "gecacht")
end)

test("ByMember: Gruppen, Anteile, Sortierung, eigener Char zuerst, Cache", function()
  local ns = loadGuild()
  local G = ns.Guild
  local t = time()
  -- nobody calls ByMember: no work
  for i = 1, 3 do hear(killMsg(ns, { key = "Grimm-Bart", t = t - 100 - i, victim = "Kollege Wurst" }), "Kollege-Forever") end
  hear(killMsg(ns, { key = "Grimm-Bart", t = t - 50, victim = "Anna Blume" }), "Anna-Forever")
  hear(killMsg(ns, { key = "Fies-Ling", t = t - 40, victim = "Anna Blume" }), "Anna-Forever")
  hear(listMsg(ns, { key = "Nur-Gelistet", by = "Anna Blume", t = t - 30 }), "Anna-Forever")
  hear(listMsg(ns, { key = "Grimm-Bart", by = "Anna Blume", t = t - 20 }), "Anna-Forever")
  -- own death by the same killer
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart" }, { t = t - 10, zone = "Brachland",
    me = "Varorak Narenmar", source = "recap", others = {} }, true)
  ns:Fire("DEATH_RECORDED", { t = t - 10, zone = "Brachland", me = "Varorak Narenmar", kind = "pvp",
    sure = true, counted = true, killerKey = key }, key)
  eq(G.stats.byMemberBuilds, 0, "ohne Aufruf kein Aufbau")
  local bm = G.ByMember()
  eq(G.stats.byMemberBuilds, 1)
  eq(#bm, 3)
  eq(bm[1].name, "Varorak Narenmar"); eq(bm[1].me, true); eq(bm[1].deaths, 1); eq(bm[1].hasAddon, true)
  eq(bm[2].name, "Kollege Wurst"); eq(bm[2].deaths, 3); eq(bm[2].killers, 1); eq(bm[2].listed, 0)
  eq(bm[3].name, "Anna Blume"); eq(bm[3].deaths, 2); eq(bm[3].killers, 2); eq(bm[3].listed, 2)
  eq(bm[3].lastDeath, t - 40); ok(bm[3].lastHeard, "lastHeard aus den Mitgliedern"); eq(bm[3].hasAddon, true)
  no(bm[2].me)
  -- each member counts only his share of Grimm-Bart (5 deeds in all)
  eq(G.Get("Grimm-Bart").kills, 5)
  eq(bm[2].rows[1].key, "Grimm-Bart"); eq(bm[2].rows[1].kills, 3); eq(bm[2].rows[1].lastKill, t - 101)
  eq(bm[1].rows[1].kills, 1); eq(bm[1].rows[1].lastZone, "Brachland")
  local rows = bm[3].rows
  eq(#rows, 3)
  eq(rows[1].key, "Fies-Ling"); eq(rows[1].kills, 1); no(rows[1].listed)
  eq(rows[2].key, "Grimm-Bart"); eq(rows[2].kills, 1); eq(rows[2].listed, true); eq(rows[2].listedAt, t - 20)
  eq(rows[3].key, "Nur-Gelistet"); eq(rows[3].kills, 0); eq(rows[3].listed, true)
  ok(rows[2].entry == G.Get("Grimm-Bart"), "Eintrag ist der Gildeneintrag")
  ok(rows[2].entry.mine, "mine gesetzt")
  -- warm: same table, no rebuild; a duplicate message changes nothing
  ok(G.ByMember() == bm); eq(G.stats.byMemberBuilds, 1)
  hear(killMsg(ns, { key = "Fies-Ling", t = t - 40, victim = "Anna Blume" }), "Anna-Forever")
  M.Advance(1)
  ok(G.ByMember() == bm, "Duplikat: kein Neuaufbau"); eq(G.stats.byMemberBuilds, 1)
  -- a real change: rebuilt on the next call
  hear(killMsg(ns, { key = "Neu-Ling", t = t - 1, victim = "Bert Brot" }), "Bert-Forever")
  local bm2 = G.ByMember()
  ok(bm2 ~= bm); eq(G.stats.byMemberBuilds, 2); eq(#bm2, 4)
  eq(bm2[1].me, true)
  -- empty guild list: the own section is still there
  G.Clear()
  local bm3 = G.ByMember()
  eq(#bm3, 1); eq(bm3[1].me, true); eq(bm3[1].deaths, 0); eq(#bm3[1].rows, 0)
end)

test("alertListed: Alarm für reine Hand-Einträge nur mit Einstellung, ohne minKills", function()
  local ns = loadGuild()
  hear(listMsg(ns, { key = "Nur-Gelistet" }))
  ok(ns.Tracker.guildHook, "Haken gesetzt")
  M.ClearFired()
  M.AddEnemy("target", { name = "Nur", surname = "Gelistet" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#M.Fired("GUILD_ENEMY_SPOTTED"), 0, "aus")
  ok(ns.Guild.Get("Nur-Gelistet").lastSeen, "gesehen wird trotzdem notiert")
  ns.Store.Setting("guild.alertListed", true)
  ns.Store.Setting("guild.minKills", 5)
  M.Advance(1)
  M.FireEvent("PLAYER_TARGET_CHANGED")
  local s = M.Fired("GUILD_ENEMY_SPOTTED")
  eq(#s, 1, "an, ohne Schwelle"); eq(s[1][2], "Nur-Gelistet")
  -- entries with kills keep the threshold
  hear(killMsg(ns, { key = "Grimm-Bart", t = time() - 3 }))
  M.Advance(1)
  M.AddEnemy("target", { name = "Grimm", surname = "Bart" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#M.Fired("GUILD_ENEMY_SPOTTED"), 1, "minKills gilt weiter für Kills")
end)

---------------------------------------------------------------------------
-- Settings, migration, CleanName, slash, probe
---------------------------------------------------------------------------
test("Migration DB Version 2: neue Defaults, kaputte Typen repariert, keine Daten weg", function()
  local t = time() - 1000
  local db = { version = 2,
    settings = { alert = { sound = false, cooldown = 30, volume = "laut", channel = "Lautsprecher" },
      ui = { scale = 1.2, guildView = "quatsch", guildCollapsed = { ["Anna Blume"] = true, [1] = true, x = "ja" } },
      guild = { share = false, minKills = "zwei" } },
    enemies = { ["Alt-Feind"] = { key = "Alt-Feind", name = "Alt", realm = "Feind", surname = "Feind", kills = 2,
      status = "wanted", note = "böse", lastKill = t,
      deaths = { { t = t, sure = true, me = "Varorak Narenmar", zone = "Z" } } } },
    deaths = { { t = t, kind = "pvp", killerKey = "Alt-Feind" } } }
  local ns = loadGuild({ db = db })
  local s = _G.DeathNoteDB.settings
  eq(_G.DeathNoteDB.version, 3)
  eq(s.alert.sound, false, "Hauptschalter bleibt"); eq(s.alert.cooldown, 30)
  eq(s.alert.soundKey, "warnung"); eq(s.alert.volume, 3); eq(s.alert.channel, "Master")
  eq(s.ui.scale, 1.2); eq(s.ui.guildView, "enemy")
  eq(s.ui.guildCollapsed["Anna Blume"], true); eq(s.ui.guildCollapsed[1], nil); eq(s.ui.guildCollapsed.x, nil)
  eq(s.guild.share, false); eq(s.guild.minKills, 1, "kaputter Typ repariert")
  eq(s.guild.shareManual, true); eq(s.guild.alertListed, false)
  local e = ns.Store.Get("Alt-Feind")
  eq(e.kills, 2); eq(e.note, "böse"); eq(#e.deaths, 1); eq(#ns.Store.Deaths(), 1)
  -- values in range stay, out of range are clamped
  for _, c in ipairs({ { 9, 5 }, { 0, 1 }, { 2.4, 2 }, { 4, 4 } }) do
    ns = loadGuild({ db = { version = 2, settings = { alert = { volume = c[1], channel = "SFX", soundKey = "glocke" },
      ui = { guildView = "member" } } } })
    s = _G.DeathNoteDB.settings
    eq(s.alert.volume, c[2], "Lautstärke " .. c[1]); eq(s.alert.channel, "SFX"); eq(s.alert.soundKey, "glocke")
    eq(s.ui.guildView, "member")
  end
  -- Store.Setting stays a plain accessor
  ns.Store.Setting("alert.volume", 9)
  eq(ns.Store.Setting("alert.volume"), 9)
  eq(#M.errors, 0)
end)

test("CleanName entfernt / und \\ (Anvisieren-Knopf)", function()
  local ns = M.Load()
  local U = ns.Util
  eq(U.CleanName("Gr/imm\\"), "Grimm"); eq(U.CleanName("/"), nil); eq(U.CleanName("Grimm"), "Grimm")
  eq(U.KeyFor("Gri/mm", "Ba\\rt"), "Grimm-Bart")
  local key = ns.Store.AddManual("Gr/imm Ba\\rt")
  eq(key, "Grimm-Bart")
  local tn = U.TargetName(ns.Store.Get(key))
  eq(tn, "Grimm Bart"); no(tn:find("[/\\]"))
end)

test("/dn gilde zeigt Hand-Einträge und Schalter, Probe zählt M und X", function()
  local ns = loadGuild()
  hear(listMsg(ns, { key = "Nur-Gelistet" }))
  hear(killMsg(ns, { t = time() - 30 }))
  hear(ns.Guild.Proto.EncodeUnlisted("Weg-Da", "Kollege Wurst"))
  _G.SlashCmdList.DEATHNOTE("gilde")
  local txt = table.concat(M.chat, "\n")
  ok(txt:find("2 Täter (1 nur von Hand eingetragen), 1 Tat", 1, true), txt)
  ok(txt:find("Einträge von Hand teilen: an", 1, true))
  ns.Store.Setting("guild.shareManual", false)
  _G.SlashCmdList.DEATHNOTE("gilde")
  ok(table.concat(M.chat, "\n"):find("Einträge von Hand teilen: aus", 1, true))
  ns.Store.Setting("guild.shareManual", true)
  M.Advance(30)
  ns.Store.AddManual("Selbst", "Eingetragen")
  M.Advance(1)
  _G.SlashCmdList.DEATHNOTE("probe")
  local p = _G.DeathNoteDB.probe.guild
  eq(p.listReceived, 1); eq(p.unlistReceived, 1); eq(p.listSent, 1); eq(p.listDropped, 0)
  eq(p.listedOnly, 2); eq(p.shareManual, true)
  ok(table.concat(M.chat, "\n"):find("Hand-Einträge (M): gesendet 1", 1, true))
  no(M.ContainsSecret(_G.DeathNoteDB))
end)

M.done("test_listed")
