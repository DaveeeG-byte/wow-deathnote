-- 1.6.0 guildlog: the guild's chronicle as data (GuildLog.lua). Events from what the guild already shares (K/R deaths,
-- V revenge, E hit list, B bounty, J release), the same kill as V and E once, whom a revenge avenged (never the avenger
-- himself), own deaths only while shared, the ring (cap, dedupe, survives the call-off), who has the book (only who sent
-- something, version, older marked, cap 500, 30 days, only the current guild, the roster line), the week (avengers, most
-- wanted, the card's line within 255 bytes), "recommend" (one plain GUILD line per 30 minutes, never in combat), the
-- dot's count, the probe, and that an error in the hook never breaks the guild sync. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local GUILD = "Die Wurstbrüder"

local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Share.lua"

local function world(opts)
  opts = opts or {}
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { version = opts.version or "1.6.0", files = FILES })
  local b = W.client("Berta", "Senf", GUILD, { version = opts.bv or "1.6.0", files = FILES })
  local c = W.client("Cäsar", "Kraut", GUILD, { version = "1.5.0", files = FILES })
  a.login()
  W.run(30)
  return W, a, b, c
end

local function P(a) return a.ns.Guild.Proto end
local function now() return time() end
-- a message on GUILD to client x from sender (first name)
local function from(x, sender, text) x.fire("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender .. "-Forever") end
local function kill(x, sender, victim, key, t, zone)
  from(x, sender, P(x).EncodeKill({ key = key, display = key:gsub("%-", " "), class = "ROGUE", level = 40,
    zone = zone or "Eschental", t = t, victim = victim }, "K"))
end
local function kinds(list)
  local out = {}
  for _, e in ipairs(list) do out[e.k] = (out[e.k] or 0) + 1 end
  return out
end
local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

---------------------------------------------------------------------------
-- events from the shared data
---------------------------------------------------------------------------
test("Chronik: Tod (K), Rache (V), Kopfgeld (B), Freigabe (J), erlegt (E) aus der Leitung", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 3600, "Eschental")
  W.run(1)
  from(a, "Cäsar", P(a).EncodeAvenged("Grimm-Bart", "Cäsar Kraut", t - 60, "0"))
  from(a, "Cäsar", P(a).EncodeBounty("Grimm-Bart", "Cäsar Kraut", 50, t - 1800))
  from(a, "Berta", P(a).EncodeHunt({ key = "Ork-Hau", display = "Ork Hau", t = t - 900, by = "Berta Senf" }))
  W.run(1)
  from(a, "Cäsar", P(a).EncodeBagged("Ork-Hau", "Cäsar Kraut", t - 30))
  W.run(12)
  local list = GL.All("guild")
  local k = kinds(list)
  eq(k.death, 1, "Tod"); eq(k.avenged, 1, "Rache"); eq(k.bounty, 1, "Kopfgeld"); eq(k.release, 1, "Freigabe")
  eq(k.bag, 1, "erlegt")
  -- newest first
  for i = 2, #list do ok(list[i - 1].t >= list[i].t, "neueste zuerst") end
  local d
  for _, e in ipairs(list) do if e.k == "death" then d = e end end
  eq(d.victim, "Berta Senf"); eq(d.zone, "Eschental"); eq(d.key, "Grimm-Bart")
  -- sentences in German with the names
  local L = a.ns.L
  for _, e in ipairs(list) do
    local s = GL.Sentence(e)
    ok(type(s) == "string" and s ~= "" and not s:find("{", 1, true), "Satz ohne Platzhalter: " .. tostring(s))
    if e.k == "avenged" then eq(s, "Cäsar hat Grimm Bart erwischt und Berta gerächt") end
    if e.k == "death" then eq(s, "Berta wurde von Grimm Bart getötet") end
    if e.k == "bounty" then eq(s, "Kopfgeld von Cäsar auf Grimm Bart: 50g") end
    if e.k == "release" then eq(s, "Berta hat Ork Hau zur Jagd freigegeben") end
  end
  ok(GL.Line(d):find("Eschental", 1, true), "Ort in der Zeile")
  noErrors()
end)

test("Dieselbe Tötung als V und als E: ein Ereignis, die Rache", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 3600)
  from(a, "Berta", P(a).EncodeHunt({ key = "Grimm-Bart", display = "Grimm Bart", t = t - 900, by = "Berta Senf" }))
  W.run(12)
  from(a, "Cäsar", P(a).EncodeBagged("Grimm-Bart", "Cäsar Kraut", t - 20))
  from(a, "Cäsar", P(a).EncodeAvenged("Grimm-Bart", "Cäsar Kraut", t - 20, "1"))
  W.run(12)
  local k = kinds(GL.All("guild"))
  eq(k.avenged, 1); eq(k.bag, nil, "kein zweites Ereignis für dieselbe Tötung")
  eq(GL.Week().avenged, 1, "einmal gezählt")
end)

test("Wen eine Rache rächt: die Opfer davor, nie der Rächer selbst", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 7200)
  kill(a, "Cäsar", "Cäsar Kraut", "Grimm-Bart", t - 3600)
  W.run(1)
  from(a, "Cäsar", P(a).EncodeAvenged("Grimm-Bart", "Cäsar Kraut", t - 60, "0"))
  W.run(12)
  local av
  for _, e in ipairs(GL.All("guild")) do if e.k == "avenged" then av = e end end
  ok(av, "Rache da")
  eq(#av.victims, 1, "nur Berta"); eq(av.victims[1], "Berta Senf")
  eq(GL.Sentence(av), "Cäsar hat Grimm Bart erwischt und Berta gerächt")
end)

test("Eigene Tode nur, solange Tode geteilt werden", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  -- the own death goes into the guild list by Sync's OnDeath (addOwn), shared or not
  local S = a.ns.Store
  local key = S.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
    { t = t - 120, zone = "Eschental", source = "recap" }, true)
  a.ns:Fire("DEATH_RECORDED", { sure = true, kind = "pvp", t = t - 120, me = "Anton Wurst", zone = "Eschental" }, key)
  W.run(2)
  local function deaths() return kinds(GL.All("guild")).death or 0 end
  ok(key, "Tod im eigenen Buch")
  eq(deaths(), 1, "geteilt: eigener Tod in der Chronik")
  S.Setting("guild.share", false)
  W.run(1)
  eq(deaths(), 0, "nicht geteilt: kein eigener Tod in der Chronik")
  S.Setting("guild.share", true)
  W.run(1)
  eq(deaths(), 1)
  local d
  for _, e in ipairs(GL.All("guild")) do if e.k == "death" then d = e end end
  ok(d.mine, "als eigener markiert"); eq(GL.Sentence(d), "Du wurdest von Grimm Bart getötet")
end)

---------------------------------------------------------------------------
-- the ring
---------------------------------------------------------------------------
test("Ring: Deckel 200, doppelt einmal, Unsinn abgelehnt, Add für andere Pakete", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  for i = 1, 260 do ok(GL.Add("sight", { t = t - 1000 + i, key = "Ziel" .. i .. "-Nr", by = "Berta Senf" })) end
  eq(#GL.DB().ring, 200, "Deckel")
  eq(GL.DB().ring[1].key, "Ziel260-Nr", "die neuesten bleiben")
  no(GL.Add("sight", { t = t - 1000 + 260, key = "Ziel260-Nr", by = "Berta Senf" }), "doppelt")
  no(GL.Add(nil, {})); no(GL.Add("x|y", {})); no(GL.Add("sight", "kein Tisch"))
  no(GL.Add(string.rep("k", 40), {}), "Art zu lang")
  ok(GL.Add("call", { key = "A-B", name = "A|cff B", by = "Berta Senf" }))
  local e = GL.DB().ring[1]
  eq(e.k, "call"); eq(e.name, nil, "Name mit Steuerzeichen nicht übernommen")
  -- an unknown kind reads as a plain sentence
  local found
  for _, x in ipairs(GL.All("guild")) do if x.k == "call" then found = x end end
  ok(found, "im Feed"); ok(not GL.Sentence(found):find("{", 1, true))
  noErrors()
end)

test("Ring: ein erlegtes Ziel bleibt in der Chronik, auch nach dem Abblasen der Jagd", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  from(a, "Berta", P(a).EncodeHunt({ key = "Ork-Hau", display = "Ork Hau", t = t - 900, by = "Berta Senf" }))
  W.run(2)
  from(a, "Cäsar", P(a).EncodeBagged("Ork-Hau", "Cäsar Kraut", t - 30))
  W.run(12)
  eq(kinds(GL.All("guild")).bag, 1)
  from(a, "Berta", P(a).EncodeCallOff("Ork-Hau", "Berta Senf"))
  W.run(2)
  eq(kinds(GL.All("guild")).release, nil, "Freigabe weg")
  eq(kinds(GL.All("guild")).bag, 1, "erlegt bleibt (Ring)")
  local bag
  for _, e in ipairs(GL.All("guild")) do if e.k == "bag" then bag = e end end
  eq(bag.name, "Ork Hau", "Name aus der Zeit des Ereignisses")
end)

---------------------------------------------------------------------------
-- who has the book
---------------------------------------------------------------------------
test("Wer hat das Buch: nur wer gesendet hat, Version, älter markiert, eigene Zeile zuerst", function()
  local W, a, b, c = world()
  b.login(); c.login()
  W.run(40)
  local GL = a.ns.GuildLog
  local list, head = GL.Holders()
  local by = {}
  for _, x in ipairs(list) do by[x.name] = x end
  ok(list[1].me, "eigene Zeile zuerst"); eq(list[1].name, "Anton")
  ok(by.Berta and by["Cäsar"], "beide gehört")
  eq(by["Cäsar"].v, "1.5.0"); ok(by["Cäsar"].old, "1.5.0 ist älter als 1.6.0"); no(by.Berta.old)
  eq(head.holders, 3)
  -- the roster of the world: all three online
  eq(head.online, 3); eq(head.total, 3)
  eq(GL.HolderLine(), "3 von 3 online haben das Buch")
  noErrors()
end)

test("Wer hat das Buch: ohne Gildenliste nur die Zahl; kaputte API bricht nichts", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { version = "1.6.0", noRoster = true, files = FILES })
  local b = W.client("Berta", "Senf", GUILD, { version = "1.6.0", files = FILES })
  a.login(); b.login()
  W.run(40)
  local GL = a.ns.GuildLog
  local _, head = GL.Holders()
  eq(head.total, nil); eq(GL.HolderLine(), "2 in der Gilde haben das Buch")
  a.env.GetNumGuildMembers = function() error("kaputt") end
  a.env.GetGuildRosterInfo = function() error("kaputt") end
  local r = GL.Roster(true)
  no(r.ok); eq(r.why, "error")
  a.env.GetNumGuildMembers = function() return 2 end
  r = GL.Roster(true)
  ok(r.ok, "Zahl lesbar, Zeilen werfen"); eq(r.online, 0)
  noErrors()
end)

test("Wer hat das Buch: Deckel 500, Verfall 30 Tage, nur die aktuelle Gilde", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  for i = 1, 620 do GL.Heard("M" .. i, "M" .. i .. " Nr", "1.6.0") end
  local n = 0
  for _ in pairs(GL.DB().holders) do n = n + 1 end
  eq(n, 500, "Deckel")
  -- 30 days: old ones go at the next start
  local h = GL.DB().holders
  h["M620 Nr"].t = t - 31 * 86400
  h["M619 Nr"].g = "Andere Gilde"
  GL.Sanitize(GL.DB(), t)
  no(h["M620 Nr"], "verfallen")
  local seen = {}
  for _, x in ipairs(GL.Holders()) do seen[x.full] = true end
  no(seen["M619 Nr"], "andere Gilde nicht in der Liste")
  ok(seen["M618 Nr"])
  -- broken records are dropped, never thrown on
  h["Kaputt"] = "x"; h["X|Y"] = { t = t }; h["Ok"] = { t = t, v = "1|2" }
  GL.Sanitize(GL.DB(), t)
  no(h["Kaputt"]); no(h["X|Y"]); eq(h["Ok"].v, nil)
  noErrors()
end)

test("Ein Fehler im Haken bricht die Gilden-Leitung nie", function()
  local W, a = world()
  a.ns.GuildLog.Heard = function() error("absichtlich") end
  local t = now()
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 60)
  W.run(2)
  ok(a.ns.Guild.Get("Grimm-Bart"), "Tod trotzdem im Gildenbuch")
  noErrors()
end)

---------------------------------------------------------------------------
-- the week
---------------------------------------------------------------------------
test("Woche: Rächer und Meistgesuchter über 7 Tage, Karte, Zeile höchstens 255 Bytes", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 8 * 86400)   -- older than a week
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", t - 7200)
  kill(a, "Cäsar", "Cäsar Kraut", "Grimm-Bart", t - 3600)
  kill(a, "Cäsar", "Cäsar Kraut", "Ork-Hau", t - 3000)
  W.run(1)
  from(a, "Cäsar", P(a).EncodeAvenged("Grimm-Bart", "Cäsar Kraut", t - 60, "0"))
  W.run(12)
  local w = GL.Week()
  eq(w.deaths, 3, "nur die letzten 7 Tage"); eq(w.avenged, 1)
  eq(w.wanted[1].key, "Grimm-Bart"); eq(w.wanted[1].n, 2)
  eq(w.avengers[1].char, "Cäsar Kraut"); eq(w.avengers[1].n, 1)
  eq(w.guild, GUILD)
  local c = GL.CardTexts(w)
  eq(c.deaths, "3 Tode"); eq(c.avenged, "1 gerächt")
  local line = GL.WeekLine()
  ok(#line <= 255, "eine Chatzeile")
  ok(line:find("^%[Revenge Book: Grimm Bart%]"), "Meistgesuchter in der Klammer: " .. line)
  ok(line:find(GUILD, 1, true), "Gilde in der Zeile")
  no(line:find("|", 1, true), "kein Steuerzeichen")
  local dc = GL.WeekDiscord()
  ok(dc:find("**" .. GUILD .. "**", 1, true), "Gilde fett")
  ok(dc:find("**Grimm Bart**", 1, true), "Meistgesuchter fett, nicht maskiert: " .. dc)
  -- long names in every field still fit 255 bytes
  local long = string.rep("Ä", 30)
  a.env.GetGuildInfo = function() return long .. long end
  ok(#(GL.WeekLine() or "") <= 255)
  noErrors()
end)

test("Woche: Einzahl und Mehrzahl der Sprache (deDE)", function()
  local W, a = world()
  local L, Fmt = a.ns.L, a.ns.F
  eq(Fmt(L.GLOG_CARD_DEATHS, { count = 1 }), "1 Tod")
  eq(Fmt(L.GLOG_CARD_DEATHS, { count = 2 }), "2 Tode")
  eq(Fmt(L.GLOG_VICTIMS_MORE, { name = "Berta", count = 1 }), "Berta und 1 weiteren")
end)

---------------------------------------------------------------------------
-- sending
---------------------------------------------------------------------------
test("Der Gilde empfehlen: eine schlichte Zeile in GUILD, höchstens einmal in 30 Minuten", function()
  local W, a = world()
  local GL = a.ns.GuildLog
  local sent = {}
  a.env.SendChatMessage = function(text, ch) sent[#sent + 1] = { text = text, ch = ch } end
  a.ns.Share.last = nil
  local line = GL.RecommendLine()
  ok(line and #line <= 255); no(line:find("[|%[%]]"), "kein Link, keine Klammer")
  local okr = GL.Recommend()
  ok(okr); eq(#sent, 1); eq(sent[1].ch, "GUILD"); eq(sent[1].text, line)
  local ok2, why = GL.Recommend()
  no(ok2); eq(why, "wait"); eq(#sent, 1)
  ok(GL.RecommendWait() > 1700)
  M.epoch = M.epoch + 1801; a.ns.Share.last = nil   -- (the 10 s of Share run on GetTime)
  ok(GL.Recommend(), "nach 30 Minuten wieder"); eq(#sent, 2)
  -- in combat never
  M.epoch = M.epoch + 1801; a.ns.Share.last = nil
  a.combat = true
  local ok3, why3 = GL.Recommend()
  no(ok3); eq(why3, "combat"); eq(#sent, 2)
  a.combat = false
  -- without a guild never
  a.guild = nil
  M.epoch = M.epoch + 1801; a.ns.Share.last = nil
  local ok4, why4 = GL.Recommend()
  no(ok4); eq(why4, "noguild")
  eq(GL.DB().counts.recommend, 2)
  noErrors()
end)

test("Wochenkarte aushängen: nur GUILD, auf Klick", function()
  local W, a = world()
  local GL = a.ns.GuildLog
  local sent = {}
  a.env.SendChatMessage = function(text, ch) sent[#sent + 1] = { text = text, ch = ch } end
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", now() - 60)
  W.run(2)
  eq(#sent, 0, "nichts von selbst")
  ok(GL.PostWeek()); eq(#sent, 1); eq(sent[1].ch, "GUILD")
  ok(sent[1].text:find("1 Tod", 1, true))
end)

---------------------------------------------------------------------------
-- the dot, the probe
---------------------------------------------------------------------------
test("Neu seit dem letzten Blick: nur fremde Ereignisse, gesehen setzt zurück", function()
  local W, a = world()
  local GL, t = a.ns.GuildLog, now()
  eq(GL.Unseen("seenTab"), 0, "erster Start: kein Punkt für die Vergangenheit")
  M.epoch = M.epoch + 10
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", now())
  W.run(2)
  eq(GL.Unseen("seenTab"), 1)
  GL.MarkSeen("seenTab")
  eq(GL.Unseen("seenTab"), 0)
  eq(GL.Unseen("seenFeed"), 1, "das Band zählt für sich")
end)

test("Sonde probe.glog: Buchbesitzer, Ereignisse je Art, Gildenliste lesbar", function()
  local W, a, b = world()
  b.login(); W.run(40)
  kill(a, "Berta", "Berta Senf", "Grimm-Bart", now() - 60)
  W.run(2)
  local out = a.ns.Probe.Run(false)
  local g = out.glog
  ok(g, "probe.glog")
  eq(g.holders, 2); eq(g.events.death, 1); eq(g.roster, "ok"); eq(g.rosterOnline, 2)
  ok(a.env.DeathNoteDB.probe.glog, "gespeichert")
  noErrors()
end)

M.done("gc160 chronik")
