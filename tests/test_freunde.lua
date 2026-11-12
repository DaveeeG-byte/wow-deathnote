-- 1.2.0: friends' book. The guild protocol over WHISPER to friends of the friend list: who gets
-- what, trust (only friends, dropped before decoding), no doubles with the guild, removed friends,
-- friends coming online later, a realm refusing whispers, floods, mixed versions, upgrade/downgrade.
-- All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local DIR = arg[0]:match("^(.*)/") or "."
local GUILD = "Die Wurstbrüder"
-- the logic files of 1.1.0, unchanged, as the old client of the mixed tests
local BASE = DIR .. "/fixtures/addon-1.1.0/"
local OLD_FILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }

local function world()
  M.Reset()
  return M.NewWorld()
end

local function kill(c, name, surname, dt)
  local t = time() - (dt or 0)
  local me = c.name .. " " .. c.surname
  local key = c.ns.Store.ApplyKill({ name = name, surname = surname, class = "MAGE", level = 36 },
    { t = t, zone = "Schlingendorntal", me = me, myLevel = 34, source = "recap", others = {} }, true)
  c.ns:Fire("DEATH_RECORDED", { t = t, zone = "Schlingendorntal", me = me, kind = "pvp",
    sure = true, counted = true, killerKey = key, source = "recap" }, key)
  return key
end

local function whispers(W, kind)
  local n = 0
  for _, m in ipairs(W.sent) do
    if m.channel == "WHISPER" and (not kind or m.text:match("^1\t(%u)\t") == kind) then n = n + 1 end
  end
  return n
end

local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

---------------------------------------------------------------------------
test("Zwei Freunde ohne Gilde: Hallo, Antwort, Live-Tat, beide sehen einander", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login()
  local early = kill(a, "Grimm", "Bart", 600)        -- before the hello: comes with the answer
  W.run(60)
  ok(whispers(W, "H") >= 2, "Hallo an den Freund")
  ok(b.ns.Guild.Get(early, "friends"), "Antwort bringt die frühere Tat")
  no(b.ns.Guild.Get(early), "nicht im Gildenbuch")
  eq(b.ns.Friends.PeerCount(), 1); eq(a.ns.Friends.PeerCount(), 1)
  local key = kill(a, "Fies", "Ling")
  W.run(3)
  local e = b.ns.Guild.Get(key, "friends")
  ok(e, "Live-Tat beim Freund"); eq(e.kills, 1); eq(e.lastVictim, "Anton Wurst")
  ok(b.ns.Guild.Get(key, "all"), "auch in Alle")
  -- "By guildmate" for friends: the section of the friend says it is a friend
  local bm = b.ns.Guild.ByMember("friends")
  local found
  for _, g in ipairs(bm) do if g.name == "Anton Wurst" then found = g end end
  ok(found, "Abschnitt des Freundes"); eq(found.src, "friends"); eq(found.hasAddon, true)
  eq(b.ns.Friends.Health().reason, "ok")
  ok(b.ns.Friends.Health().text:find("1 Freund", 1, true), b.ns.Friends.Health().text)
  -- the guild side knows nothing
  eq(b.ns.Guild.Count(), 0)
  noErrors()
end)

-- fix-2 (finding 6 of the final hunt): guildmate only with full name (list and sender with surname)
test("Freund zugleich in der Gilde: nichts per Flüstern, keine Doppel", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", GUILD, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login()
  W.run(60)
  local key = kill(a, "Grimm", "Bart")
  W.run(5)
  eq(whispers(W), 0, "kein einziges Flüstern")
  ok(b.ns.Guild.Get(key), "über die Gilde")
  no(b.ns.Guild.Get(key, "friends"), "nicht doppelt im Freundesbuch")
  eq(b.ns.Guild.Get(key, "all").kills, 1, "in Alle genau einmal")
  noErrors()
end)

test("Freund in der Gilde, aber noch nicht gehört: späteres Flüstern wird nicht doppelt gezählt", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", GUILD, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login()
  W.run(60)
  -- a whisper from a guild member that slipped through (e.g. an older 1.2.0 timing): ignored
  local P = a.ns.Guild.Proto
  local k = P.EncodeKill({ key = "Zack-Bumm", display = "Zack Bumm", t = time() - 5, zone = "Z", victim = "Anton Wurst" }, "K")
  b.fire("CHAT_MSG_ADDON", "DeathNote", k, "WHISPER", "Anton Wurst-Forever")
  no(b.ns.Guild.Get("Zack-Bumm", "friends"), "Gildenkollege per Flüstern: verworfen")
  ok(b.ns.Friends.stats.mates >= 1)
  noErrors()
end)

test("Einseitige Freundschaft: B hat A nicht auf der Liste und nimmt nichts an", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = {} })
  a.login(); b.login()
  W.run(60)
  ok(whispers(W, "H") >= 1, "A fragt B")
  eq(a.ns.Friends.PeerCount(), 0, "B antwortet nicht")
  ok(b.ns.Friends.stats.strangers >= 1, "B verwirft als Fremden")
  -- live data would not go out (no peer), and forced data is refused by B
  local key = kill(a, "Grimm", "Bart")
  W.run(3)
  eq(whispers(W, "K"), 0, "keine Live-Tat ohne Antwort")
  local P = a.ns.Guild.Proto
  b.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = key, display = "Grimm Bart", t = time(), zone = "Z",
    victim = "Anton Wurst" }, "K"), "WHISPER", "Anton-Forever")
  no(b.ns.Guild.Get(key, "all"), "B nimmt nichts an")
  noErrors()
end)

test("Fremder flüstert gültige Nachrichten: verworfen, ohne zu dekodieren", function()
  local W = world()
  -- the friend list names the friend with surname: another surname is somebody else
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" } })
  b.login(); W.run(40)
  local P = b.ns.Guild.Proto
  local decode, calls = P.Decode, 0
  P.Decode = function(...) calls = calls + 1; return decode(...) end
  local msgs = {
    P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", t = time(), zone = "Z", victim = "Fremd Ling" }, "K"),
    P.EncodeHello(0, "1.2.0"),
    P.EncodeListed({ key = "Grimm-Bart", display = "Grimm Bart", t = time(), by = "Fremd Ling" }),
    P.EncodeHunt({ key = "Grimm-Bart", display = "Grimm Bart", t = time(), by = "Fremd Ling", why = "weil" }),
  }
  for _, text in ipairs(msgs) do
    b.fire("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fremd-Forever")
    -- same first name as nobody, but a friend's first name with another surname: also a stranger
    b.fire("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Anton Falsch-Forever")
  end
  eq(calls, 0, "nichts dekodiert")
  eq(b.ns.Friends.stats.strangers, 8)
  eq(b.ns.Friends.stats.received, 0)
  no(b.ns.Guild.Get("Grimm-Bart", "all"))
  eq(whispers(W, "R"), 0, "keine Antwort an Fremde")
  P.Decode = decode
  noErrors()
end)

-- fix-2 (finding 2 of the final hunt): 14 own play days (days with a login), not 14 calendar days
test("Freund wird entfernt: seine Einträge gehen erst nach drei Scans ohne ihn und 14 Spieltagen", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  local key = kill(a, "Grimm", "Bart")
  W.run(5)
  ok(b.ns.Guild.Get(key, "friends"))
  local own = kill(b, "Eigen", "Feind")
  W.run(5)
  -- B removes A (fix-1, Fund 1: an empty list never removes anybody, so another friend stays on it);
  -- three scans without A are not enough while A was seen in the last 14 days
  b.friendNames = { "Cäsar" }
  for _ = 1, 3 do b.fire("FRIENDLIST_UPDATE"); W.run(3) end
  ok(b.ns.Guild.Get(key, "friends"), "nach drei Scans noch da (keine 14 Tage)")
  M.Advance(15 * 86400)
  b.fire("FRIENDLIST_UPDATE")
  W.run(3)
  ok(b.ns.Guild.Get(key, "friends"), "15 Kalendertage, aber nur 2 Spieltage: noch da")
  -- 13 more days with play time (the session runs past midnight, one scan per day)
  for _ = 1, 12 do M.Advance(86400); b.fire("FRIENDLIST_UPDATE"); W.run(3) end
  ok(b.ns.Guild.Get(key, "friends"), "14 Spieltage nach dem letzten Sehen: noch da")
  M.Advance(86400); b.fire("FRIENDLIST_UPDATE"); W.run(3)
  no(b.ns.Guild.Get(key, "friends"), "Eintrag des Entfernten weg")
  ok(b.ns.Guild.Get(own, "friends"), "eigene Einträge bleiben")
  eq(#b.ns.Friends.MemberList(), 0, "nicht mehr unter den Freunden mit DeathNote")
  eq(b.ns.Friends.PeerCount(), 0)
  noErrors()
end)

test("Freund kommt später online: Hallo nach dem Einloggen, danach Live-Taten", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login()
  local early = kill(a, "Grimm", "Bart", 100)
  W.run(60)
  eq(whispers(W, "H"), 0, "B ist offline: kein Hallo")
  b.login()
  W.run(60)
  ok(b.ns.Guild.Get(early, "friends"), "B bekommt die frühere Tat")
  eq(a.ns.Friends.PeerCount(), 1, "A kennt B")
  local toB = 0
  for _, m in ipairs(W.sent) do
    if m.sender == a and m.channel == "WHISPER" and m.to == "Berta" and m.text:match("^1\tH\t") then toB = toB + 1 end
  end
  -- fix-2: an answer to a friend starts with the own hello (GUID as identity): greeting plus head of the answer
  ok(toB >= 1 and toB <= 2, "A grüßt B, als B online kommt: " .. toB)
  local key = kill(b, "Fies", "Ling")
  W.run(3)
  ok(a.ns.Guild.Get(key, "friends"), "Live-Tat von B bei A")
  -- B goes offline: no whisper to an offline friend (and none raises)
  W.setOnline(b, false)
  W.run(3)
  local before = a.whispers or 0
  kill(a, "Noch", "Einer")
  W.run(3)
  eq((a.whispers or 0) - before, 0, "nichts an einen Offline-Freund")
  noErrors()
end)

test("Flüstern an einen, der gerade offline ging: kein Fehler", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  -- the friend list still says online, the send raises (as a client might for an unknown target)
  a.env.C_ChatInfo.SendAddonMessage = function(_, _, channel) if channel == "WHISPER" then error("Spieler nicht gefunden") end return 0 end
  kill(a, "Fies", "Ling")
  W.run(30)
  eq(a.ns.Guild.QueueSize(), 0, "Schlange leer")
  noErrors()
end)

test("Realm lehnt WHISPER ab: nach wenigen Versuchen still, Statuszeile sagt es, Gilde läuft weiter", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Berta", "Cäsar", "Dora" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  local c = W.client("Cäsar", "Kraut", nil, { friends = { "Anton" } })
  local d = W.client("Dora", "Rübe", nil, { friends = { "Anton" } })
  local g = W.client("Gustav", "Gans", GUILD)
  a.whisperResult = 11
  a.login(); b.login(); c.login(); d.login(); g.login()
  W.run(120)
  for i = 1, 5 do kill(a, "Fies" .. i, "Ling") end
  W.run(600)
  local h = a.ns.Friends.Health()
  eq(h.reason, "blocked"); eq(h.ok, false)
  ok(h.text:find("Flüstern", 1, true), h.text)
  ok((a.whispers or 0) <= 6, "wenige Versuche: " .. tostring(a.whispers))
  -- given up: a later /dn sync and a friend coming online whisper nothing
  local w0 = a.whispers or 0
  a.ns.Friends.SyncNow()
  W.setOnline(b, false); W.run(5); W.setOnline(b, true)
  W.run(120)
  eq((a.whispers or 0) - w0, 0, "nach der Ablehnung still")
  eq(a.ns.Guild.QueueSize(), 0, "Schlange nicht voll")
  ok(g.ns.Guild.Get("Fies1-Ling"), "Gilde unberührt")
  eq(a.ns.Guild.Health().ok, true, "Gildenstand bleibt ok")
  noErrors()
end)

test("Flut von einem Freund: Drossel und Deckel je Absender", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  local P = b.ns.Guild.Proto
  local r0 = a.ns.Friends.stats.received
  for i = 1, 300 do
    a.fire("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Flut" .. i .. "-Welle", display = "Flut" .. i .. " Welle",
      t = time() - i, zone = "Z", victim = "Berta Senf" }, "K"), "WHISPER", "Berta-Forever")
  end
  local n = a.ns.Guild.Count("friends")
  ok(n <= a.ns.Guild.C.MAX_PER_SENDER + 1, "Deckel je Absender: " .. n)
  ok(a.ns.Friends.stats.received - r0 <= a.ns.Guild.C.FLOOD_MAX, "Drossel: höchstens 150 je Minute gelesen: "
    .. (a.ns.Friends.stats.received - r0))
  eq(a.ns.Friends.stats.lastReason, "flood")
  noErrors()
end)

test("Deckel: höchstens 10 Freunde gleichzeitig bedient", function()
  local W = world()
  local names = {}
  for i = 1, 14 do names[i] = "Freund" .. i end
  local a = W.client("Anton", "Wurst", nil, { friends = names })
  local fs = {}
  for i = 1, 14 do fs[i] = W.client("Freund" .. i, "Gut", nil, { friends = { "Anton" } }) end
  for i = 1, 14 do fs[i].login() end
  a.login()
  W.run(120)
  eq(a.ns.Friends.PeerCount(), a.ns.Friends.C.PEERS_MAX)
  local before = a.whispers or 0
  kill(a, "Fies", "Ling")
  W.run(10)
  eq((a.whispers or 0) - before, 10, "eine Live-Tat geht an höchstens 10 Freunde")
  noErrors()
end)

test("Mischbetrieb: 1.1.0 in der Gilde bleibt grün; 1.1.0 als Freund bekommt Flüstern und bleibt still", function()
  local W = world()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Olaf", "Otto" } })
  local o = W.client("Olaf", "Alt", GUILD, { dir = BASE, files = OLD_FILES, version = "1.1.0" })
  local o2 = W.client("Otto", "Alt", nil, { dir = BASE, files = OLD_FILES, version = "1.1.0" })
  a.login(); o.login(); o2.login()
  W.run(60)
  local key = kill(a, "Grimm", "Bart")
  local okey = kill(o, "Fies", "Ling")
  W.run(5)
  ok(o.ns.Guild.Get(key), "1.1.0 bekommt die Tat über die Gilde")
  ok(a.ns.Guild.Get(okey), "1.2.0 bekommt die Tat von 1.1.0")
  ok(whispers(W, "H") >= 1, "Hallo an den Freund mit 1.1.0")
  eq(o2.ns.Guild.stats.received, 0, "1.1.0 wertet Flüstern nicht aus")
  eq(o2.ns.Guild.stats.dropped, 0, "nicht einmal als verworfen gezählt")
  eq(a.ns.Friends.PeerCount(), 0, "1.1.0 antwortet nicht")
  -- the new hunt types on GUILD: 1.1.0 drops them silently
  a.ns.Guild.Release(key, { to = "guild", why = "Rache" })
  W.run(3)
  local bagged = a.ns.Guild.Proto.EncodeBagged(key, "Anton Wurst", time())
  o.fire("CHAT_MSG_ADDON", "DeathNote", bagged, "GUILD", "Anton-Forever")
  o.fire("CHAT_MSG_ADDON", "DeathNote", a.ns.Guild.Proto.EncodeCallOff(key, "Anton Wurst"), "GUILD", "Anton-Forever")
  eq(o.ns.Guild.stats.lastReason, "type", "unbekannter Typ, still verworfen")
  eq(o.ns.Guild.Get(key).kills, 1, "Gildenbuch von 1.1.0 unverändert")
  noErrors()
end)

---------------------------------------------------------------------------
-- Upgrade with real-shaped data and back to 1.1.0 with the new fields in the DB
---------------------------------------------------------------------------
local function fixtureDB()
  local chunk = assert(loadfile(DIR .. "/fixtures/sv_1.0.1_autor.lua"))
  local env = {}
  setfenv(chunk, env)
  chunk()
  return env.DeathNoteDB
end

test("Upgrade mit der Fixture, dann zurück auf 1.1.0 mit Freundesbuch und Abschussliste in der DB", function()
  local W = world()
  local db = fixtureDB()
  local n0 = 0
  for _ in pairs(db.enemies) do n0 = n0 + 1 end
  local a = W.client("Anton", "Wurst", GUILD, { db = db, friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  local saved = a.env.DeathNoteDB
  eq(type(saved.friends), "table", "Freundesbuch angelegt")
  eq(saved.version, 4, "no newer DB version than 4 (1.3.0: rap sheet)")
  local n1 = 0
  for _ in pairs(saved.enemies) do n1 = n1 + 1 end
  eq(n1, n0, "kein Eintrag verloren")
  local key = kill(b, "Grimm", "Bart")
  W.run(5)
  ok(a.ns.Guild.Get(key, "friends"))
  ok(a.ns.Guild.Release(key, { why = "Weil er es verdient" }))
  a.fire("PLAYER_LOGOUT")
  ok(next(saved.friends.enemies), "Freundesbuch gespeichert")
  ok(next(saved.friends.hunts), "Abschussliste der Freunde gespeichert")
  ok(next(saved.guild.lists[GUILD].hunts), "Abschussliste der Gilde gespeichert")
  -- back to 1.1.0 with this DB: loads, keeps everything, no error
  local W2 = world()
  local o = W2.client("Anton", "Wurst", GUILD, { db = saved, dir = BASE, files = OLD_FILES, version = "1.1.0" })
  o.login(); W2.run(60)
  eq(#M.errors, 0, tostring(M.errors[1]))
  local back = o.env.DeathNoteDB
  ok(back.friends and next(back.friends.enemies), "1.1.0 lässt das Freundesbuch liegen")
  ok(back.guild.lists[GUILD].hunts and next(back.guild.lists[GUILD].hunts), "und die Abschussliste")
  local n2 = 0
  for _ in pairs(back.enemies) do n2 = n2 + 1 end
  eq(n2, n1)
  -- and forward again: still there
  local W3 = world()
  local a2 = W3.client("Anton", "Wurst", GUILD, { db = back, friends = { "Berta" } })
  a2.login(); W3.run(5)
  ok(a2.ns.Guild.Get(key, "friends"), "wieder da nach dem Hin und Her")
  eq(a2.ns.Guild.HuntCount("all"), 1)
  eq(a2.ns.Guild.HuntCount("guild"), 1, "Abschussliste der Gilde überlebt das Hin und Her")
  eq(a2.ns.Guild.HuntCount("friends"), 1, "die der Freunde auch")
  noErrors()
end)

---------------------------------------------------------------------------
-- Sync, probe, switch
---------------------------------------------------------------------------
test("/dn sync fragt auch Freunde, /dn probe schreibt probe.friends, Schalter aus = Ruhe", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  local h0 = whispers(W, "H")
  a.ns.HandleSlash("sync")
  W.run(10)
  ok(whispers(W, "H") > h0, "neues Hallo an Freunde")
  a.ns.HandleSlash("probe")
  local pf = a.env.DeathNoteDB.probe and a.env.DeathNoteDB.probe.friends
  ok(pf, "probe.friends")
  for _, f in ipairs({ "sent", "received", "health", "online", "withAddon" }) do ok(pf[f] ~= nil, "Feld " .. f) end
  ok(pf.lastSendResult ~= nil, "lastSendResult")
  eq(pf.withAddon, 1); eq(pf.online, 1)
  -- switched off: nothing goes out, nothing is taken in
  a.ns.Store.Setting("guild.friends", false)
  local w0 = whispers(W)
  kill(a, "Fies", "Ling")
  W.run(5)
  eq(whispers(W), w0, "aus: kein Flüstern")
  local key = kill(b, "Noch", "Einer")
  W.run(5)
  no(a.ns.Guild.Get(key, "friends"), "aus: nichts angenommen")
  eq(a.ns.Friends.Health().reason, "off")
  noErrors()
end)

test("Statussätze für Freunde: kurz, ohne Technikwörter; /dn freunde läuft", function()
  local TECH = { "Präfix", "Prefix", "Addon", "Nachricht", "Rückgabe", "API", "Kanal", "Schlange", "Enum", "nil" }
  local seen = {}
  local function take(h)
    local n = select(2, h.text:gsub("[^\128-\191]", ""))
    ok(n <= 60, h.reason .. ": " .. h.text)
    ok(select(2, h.short:gsub("[^\128-\191]", "")) <= 24, h.short)
    for _, w in ipairs(TECH) do no(h.text:find(w, 1, true), h.reason .. ": " .. w) end
    seen[h.reason] = true
  end
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { friends = {} })
  a.login(); W.run(40)
  take(a.ns.Friends.Health())                                 -- nofriends
  a.ns.Store.Setting("guild.friends", false); take(a.ns.Friends.Health()); a.ns.Store.Setting("guild.friends", true)
  take(a.ns.Guild.Health("all"))                               -- nobody
  W = world()
  a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = {} })
  a.login(); b.login(); W.run(60)
  take(a.ns.Friends.Health())                                 -- quiet
  b.friendNames = { "Anton" }
  b.fire("FRIENDLIST_UPDATE"); W.run(2)
  -- B greets A 25 to 40 s after A came onto his list (wait for the latest)
  a.ns.HandleSlash("sync"); W.run(45)
  take(a.ns.Friends.Health())                                 -- ok
  a.whisperResult = 10
  a.ns.Friends.SyncNow(); W.run(70); a.ns.Friends.SyncNow(); W.run(70)
  take(a.ns.Friends.Health())                                 -- blocked or failing
  for _, r in ipairs({ "nofriends", "off", "nobody", "quiet", "ok" }) do ok(seen[r], "Grund geprüft: " .. r) end
  ok(seen.blocked or seen.failing, "Ablehnung geprüft")
  a.ns.HandleSlash("freunde")
  local said = false
  for _, line in ipairs(M.chat) do if line:find("Freundesbuch:", 1, true) then said = true end end
  ok(said, "/dn freunde gibt den Stand aus")
  noErrors()
end)

---------------------------------------------------------------------------
-- Battle.net friends (same game): game data instead of whispers
---------------------------------------------------------------------------
test("Battle.net-Freunde: Hallo, Antwort und Live-Tat über Spieldaten, Fremde bleiben draußen", function()
  local W = world()
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login()
  local early = kill(a, "Grimm", "Bart", 300)
  W.run(80)
  ok((a.bnSends or 0) >= 1 and (b.bnSends or 0) >= 1, "Spieldaten in beide Richtungen")
  eq(whispers(W), 0, "kein Flüstern, wenn Battle.net geht")
  ok(b.ns.Guild.Get(early, "friends"), "Antwort über Battle.net")
  local key = kill(b, "Fies", "Ling")
  W.run(3)
  ok(a.ns.Guild.Get(key, "friends"), "Live-Tat über Battle.net")
  -- a foreign addon's game data and a broken id: dropped without error
  a.fire("BN_CHAT_MSG_ADDON", "AnderesAddon", "x", "WHISPER", b.bnId)
  a.fire("BN_CHAT_MSG_ADDON", "DeathNote", "1\tH\t0\t1.2.0", "WHISPER", 99999)
  -- sending raises (friend gone): no error, the queue moves on
  a.bnResult = true
  kill(a, "Noch", "Einer")
  W.run(30)
  eq(a.ns.Guild.QueueSize(), 0)
  noErrors()
end)

M.done("test_freunde")
