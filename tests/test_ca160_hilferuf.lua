-- 1.6.0 call: the help call (Call.lua, own prefix DeathNoteSOS, message P). Past the book's send queue (it goes in
-- combat), only from guild, group and friends, at most one per sender per 30 s and five per minute, a ring of 20, the
-- probe's result codes. Several clients in one world (tests/mock_wow.lua). All names are made up.
-- Call: luajit tests/test_ca160_hilferuf.lua [<project copy>]  (a copy for the red probe)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"
local SOS = "DeathNoteSOS"
local WATCH = { "GUILD_KILL", "GUILD_UPDATED", "HELP_CALL", "SIGHTING", "GUILD_SIGHTING" }

-- the map of the mock: 1434 = Schlingendorntal (a zone), 1435 = a cave in it, 1440 = another zone
local function GMI(id)
  if id == 1434 then return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  if id == 1435 then return { name = "Höhle", mapType = 5, parentMapID = 1434 } end
  if id == 1440 then return { name = "Eschental", mapType = 3, parentMapID = 13 } end
end

local function files(extra)
  local out = {}
  for _, f in ipairs(M.Files()) do out[#out + 1] = f end
  for _, f in ipairs(extra or {}) do out[#out + 1] = f end
  return out
end
local function welt()
  local W = H.welt(WATCH)
  _G.C_Map.GetMapInfo = GMI
  return W
end
local function sos(W)
  local n = 0
  for _, m in ipairs(W.sent) do if m.prefix == SOS then n = n + 1 end end
  return n
end
local function calls(c) return c.ns.Call.Calls() end

H.lauf("Leitung P: hin und zurueck, Unsinn wirft nie", function()
  local ns = M.Load()
  local Cl = ns.Call
  local t = time()
  local text = Cl.Encode({ mapID = 1434, x = 41.2, y = 56.8, t = t, key = "Grimm-Bart", display = "Grimm" })
  H.erwartet("kodiert", type(text) == "string" and text:find("^1\tP\t1434\t412\t568\t"), text)
  local m = Cl.Decode(text, t)
  H.erwartet("dekodiert mit Ort und Angreifer", m and m.mapID == 1434 and m.px == 412 and m.py == 568 and m.key == "Grimm-Bart"
    and m.display == "Grimm", m and (m.display or "?"))
  local m2 = Cl.Decode(Cl.Encode({ mapID = 1434, x = 1, y = 2, t = t }), t)
  H.erwartet("ohne Angreifer", m2 and m2.key == nil and m2.display == nil)
  local m3 = Cl.Decode(Cl.Encode({ mapID = 1434, x = 1, y = 2, t = t, display = "Velka" }), t)
  H.erwartet("Name ohne Schluessel (Ziel ohne Nachnamen)", m3 and m3.key == nil and m3.display == "Velka")
  H.erwartet("zu alt", Cl.Decode(Cl.Encode({ mapID = 1434, x = 1, y = 2, t = t - 400 }), t) == nil)
  H.erwartet("falscher Schluessel", Cl.Decode("1\tP\t1434\t1\t1\t" .. t .. "\tkaputt\t", t) == nil)
  H.erwartet("Ort ausserhalb", Cl.Decode("1\tP\t1434\t1001\t1\t" .. t .. "\t\t", t) == nil)
  H.erwartet("ohne gueltigen Ort kein Text", Cl.Encode({ mapID = 0, x = 1, y = 1, t = t }) == nil)
  local fails = 0
  math.randomseed(160)
  for _ = 1, 3000 do
    local parts = {}
    for i = 1, math.random(1, 10) do
      local s = {}
      for k = 1, math.random(0, 8) do s[k] = string.char(math.random(0, 255)) end
      parts[i] = table.concat(s)
    end
    if math.random() < 0.5 then parts[1] = "1"; parts[2] = "P" end
    local ok = pcall(Cl.Decode, table.concat(parts, "\t"), t)
    if not ok then fails = fails + 1 end
  end
  H.erwartet("3000 zufaellige Texte: kein Fehler", fails == 0, fails)
end)

H.lauf("Hilferuf im Kampf geht sofort an die Gilde, am Sendestau vorbei", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  a.combat = true
  local ok, got = a.ns.Call.Trigger()
  W.run(0.2)
  H.erwartet("gesendet, an die Gilde", ok == true and got and got.guild == true, tostring(got))
  H.erwartet("kam im Kampf an (eine Meldung bei Berta)", H.zaehle(b, "HELP_CALL") == 1, H.zaehle(b, "HELP_CALL"))
  local r = calls(b)[1]
  H.erwartet("Absender, Ort, gleiche Zone", r and r.by == "Anton" and r.mapID == 1434 and r.same == true
    and r.zone == "Schlingendorntal" and math.abs(r.x - 41.2) < 0.06, r and r.by)
  H.erwartet("Anton hoert sein eigenes Echo nicht", #calls(a) == 0)
  local p = a.env.DeathNoteDB.probe and a.env.DeathNoteDB.probe.call
  local code = p and p.codes and p.codes["P.combat"] and p.codes["P.combat"].GUILD
  H.erwartet("Sonde: Ergebniscode der Gilde im Kampf", code and code["0"] == 1, code and next(code))
  local line = M.chat[#M.chat] or ""
  H.erwartet("Zeile beim Empfaenger mit Name, Zone und Karte", line:find("Anton ruft um Hilfe: Schlingendorntal (gleiche Zone)", 1, true)
    and line:find("Haddon:DeathNote:call:map:", 1, true), line)
end)

H.lauf("Abklingzeit 30 s beim Absender", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  H.erwartet("erster Ruf", a.ns.Call.Send() == true)
  local ok, why, sec = a.ns.Call.Send()
  H.erwartet("zweiter sofort: warten", ok == false and why == "wait" and sec == 30, tostring(why) .. " " .. tostring(sec))
  W.run(31)
  H.erwartet("nach 31 s wieder", a.ns.Call.Send() == true)
  H.erwartet("zwei Rufe auf der Leitung", sos(W) == 2, sos(W))
end)

H.lauf("Empfang: einer je Absender je 30 s, fuenf je Minute", function()
  local W = welt()
  local b = W.client("Berta", "Senf", G)
  b.login(); W.run(45)
  local t = time()
  local text = b.ns.Call.Encode({ mapID = 1440, x = 50, y = 50, t = t })
  b.fire("CHAT_MSG_ADDON", SOS, text, "GUILD", "Carla-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, text, "PARTY", "Carla-Forever")    -- the same call on a second way
  H.erwartet("derselbe Absender zweimal: eine Meldung", H.zaehle(b, "HELP_CALL") == 1, H.zaehle(b, "HELP_CALL"))
  H.erwartet("andere Zone", calls(b)[1].same == false and calls(b)[1].zone == "Eschental")
  for _, n in ipairs({ "Dora", "Edda", "Fritz", "Gerd", "Hanna" }) do
    b.fire("CHAT_MSG_ADDON", SOS, text, "GUILD", n .. "-Forever")
  end
  H.erwartet("sechs Absender in einer Minute: fuenf Meldungen", H.zaehle(b, "HELP_CALL") == 5, H.zaehle(b, "HELP_CALL"))
  W.run(61)
  b.fire("CHAT_MSG_ADDON", SOS, b.ns.Call.Encode({ mapID = 1440, x = 50, y = 50, t = time() }), "GUILD", "Carla-Forever")
  H.erwartet("nach einer Minute wieder", H.zaehle(b, "HELP_CALL") == 6, H.zaehle(b, "HELP_CALL"))
  local p = b.env.DeathNoteDB.probe.call.counts
  H.erwartet("Sonde zaehlt doppelt und Flut", (p.dup or 0) == 1 and (p.flood or 0) == 1, tostring(p.dup) .. "/" .. tostring(p.flood))
end)

H.lauf("Nur Gilde, Gruppe und Freunde: Fremde und offene Kanaele bleiben draussen", function()
  local W = welt()
  local b = W.client("Berta", "Senf", G, { friends = { "Anton" } })
  b.login(); W.run(45)
  local text = b.ns.Call.Encode({ mapID = 1434, x = 50, y = 50, t = time() })
  b.fire("CHAT_MSG_ADDON", SOS, text, "WHISPER", "Fremder-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, text, "SAY", "Fremder-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, text, "CHANNEL", "Fremder-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, text, "INSTANCE_CHAT", "Fremder-Forever")
  b.fire("CHAT_MSG_ADDON", SOS, M.Secret("text"), "GUILD", "Fremder-Forever")
  H.erwartet("nichts angenommen", H.zaehle(b, "HELP_CALL") == 0, H.zaehle(b, "HELP_CALL"))
  b.fire("CHAT_MSG_ADDON", SOS, text, "WHISPER", "Anton-Forever")
  H.erwartet("Flüstern eines Freundes kommt an", H.zaehle(b, "HELP_CALL") == 1 and calls(b)[1].from == "friend")
  -- outside a guild a GUILD message is not trusted
  local c = W.client("Carla", "Ohne", nil)
  c.login(); W.run(5)
  c.fire("CHAT_MSG_ADDON", SOS, text, "GUILD", "Dora-Forever")
  H.erwartet("ohne Gilde kein Gildenruf", H.zaehle(c, "HELP_CALL") == 0)
end)

H.lauf("Nur offene Welt, nie in der Chat-Sperre, niemand da: der Grund", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  a.login(); W.run(45)
  M.instance = { true, "pvp" }
  local ok, why = a.ns.Call.Send()
  H.erwartet("Schlachtfeld: nicht", ok == false and why == "instance", why)
  M.instance = { true, "party" }
  ok, why = a.ns.Call.Send()
  H.erwartet("Dungeon: nicht", ok == false and why == "instance", why)
  M.instance = { false, "none" }
  a.env.C_ChatInfo.InChatMessagingLockdown = function() return true end
  ok, why = a.ns.Call.Send()
  H.erwartet("Chat-Sperre: nicht", ok == false and why == "lockdown", why)
  a.env.C_ChatInfo.InChatMessagingLockdown = nil
  H.erwartet("nichts auf der Leitung", sos(W) == 0, sos(W))
  local c = W.client("Carla", "Allein", nil)
  c.login(); W.run(5)
  ok, why = c.ns.Call.Send()
  H.erwartet("ohne Gilde, Gruppe, Freunde: niemand", ok == false and why == "none", why)
  c.ns.Call.Trigger()
  H.erwartet("der Grund steht im Chat", (M.chat[#M.chat] or ""):find("weder Gilde noch Gruppe", 1, true), M.chat[#M.chat])
  -- a refusing client: the code is named; nothing went out, so no cooldown (fixer 1.6.0, jl02)
  local d = W.client("Dora", "Nein", G)
  d.login(); W.run(5)
  d.sendResult = 9
  ok, why = d.ns.Call.Send()
  local _, why2, det = d.ns.Call.Send()
  H.erwartet("abgelehnt: Code 9", ok == false and why == "failed", why)
  H.erwartet("danach keine Abklingzeit (nichts ging hinaus)", why2 == "failed" and det == 9, tostring(why2) .. " " .. tostring(det))
  d.sendResult = nil
  ok = d.ns.Call.Send()
  local _, why3, det3 = d.ns.Call.Send()
  H.erwartet("nach dem gelungenen Senden die Abklingzeit", ok == true and why3 == "wait" and (det3 == 30 or det3 == 29),
    tostring(why3) .. " " .. tostring(det3))
end)

H.lauf("Angreifer: feindliches Ziel, sonst der erste der Rachsucht-Episode", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G, { files = files({ "Grip.lua" }) })
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  M.AddEnemy("target", { name = "Grimm", surname = "Bart", faction = "Alliance" })
  a.ns.Call.Trigger(); W.run(0.2)
  local r = calls(b)[1]
  H.erwartet("aus dem Ziel: Schluessel und Name", r and r.key == "Grimm-Bart" and r.display == "Grimm Bart", r and r.display)
  M.units.target = nil
  a.ns.Grudge.Current = function()
    return { order = { "Grimm-Bart", "Velka-Dorn" }, rows = {
      ["Grimm-Bart"] = { key = "Grimm-Bart", name = "Grimm", surname = "Bart", n = 2 },
      ["Velka-Dorn"] = { key = "Velka-Dorn", name = "Velka", surname = "Dorn", n = 1 } } }
  end
  W.run(31)
  a.ns.Call.Trigger(); W.run(0.2)
  r = calls(b)[2]
  H.erwartet("aus der Episode: wer zuerst kam", r and r.key == "Velka-Dorn", r and r.key)
  a.ns.Grudge.Current = function() return nil end
  W.run(31)
  a.ns.Call.Trigger(); W.run(0.2)
  r = calls(b)[3]
  H.erwartet("ohne beide: ohne Angreifer", r and r.key == nil and r.display == nil)
  H.erwartet("Text ohne Angreifer", (M.chat[#M.chat] or ""):find("Anton ruft um Hilfe: Schlingendorntal (gleiche Zone) ", 1, true), M.chat[#M.chat])
end)

H.lauf("Freunde (Fluestern, Battle.net) und Gruppe", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, bn = { "Carla" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  local c = W.client("Carla", "Netz", nil, { bn = { "Anton" } })
  a.login(); b.login(); c.login(); W.run(90)
  local ok, got = a.ns.Call.Send()
  W.run(0.2)
  H.erwartet("an zwei Freunde", ok == true and got.friends == 2 and got.guild == false and got.group == false,
    got and got.friends)
  H.erwartet("Berta per Fluestern", H.zaehle(b, "HELP_CALL") == 1 and calls(b)[1].from == "friend")
  H.erwartet("Carla per Battle.net", H.zaehle(c, "HELP_CALL") == 1 and calls(c)[1].by == "Anton")
  -- a group without guild and friendship
  local W2 = welt()
  local d = W2.client("Dora", "Grupp", nil)
  local e = W2.client("Emil", "Grupp", nil)
  d.login(); e.login(); W2.run(45)
  d.env.IsInGroup = function() return true end
  ok, got = d.ns.Call.Send()
  W2.run(0.2)
  H.erwartet("Gruppe: PARTY", ok == true and got.group == true, got and tostring(got.group))
  H.erwartet("Emil hoert die Gruppe", H.zaehle(e, "HELP_CALL") == 1 and calls(e)[1].from == "group")
  d.env.IsInRaid = function() return true end
  W2.run(31)
  d.ns.Call.Send(); W2.run(0.2)
  local raid = false
  for _, m in ipairs(W2.sent) do if m.prefix == SOS and m.channel == "RAID" then raid = true end end
  H.erwartet("Schlachtzug: RAID statt PARTY", raid)
end)

H.lauf("Ringpuffer 20, kaputte Eintraege fliegen beim Laden", function()
  local W = welt()
  local b = W.client("Berta", "Senf", G)
  b.login(); W.run(45)
  for i = 1, 25 do
    if i % 5 == 1 and i > 1 then W.run(61) end
    b.fire("CHAT_MSG_ADDON", SOS, b.ns.Call.Encode({ mapID = 1434, x = i, y = i, t = time() }), "GUILD", "S" .. i .. "-Forever")
  end
  H.erwartet("25 Rufe: 20 behalten, die neuesten", #calls(b) == 20 and calls(b)[20].by == "S25" and calls(b)[1].by == "S6",
    #calls(b))
  local db = b.env.DeathNoteDB
  db.call.calls[3] = { t = "x" }
  db.call.calls[4] = "kaputt"
  db.call.calls[5].by = "A|cffff0000B"
  db.call.fremd = 5
  for i = 1, 10 do db.call.calls[#db.call.calls + 1] = { t = 1, at = 1, by = "Z", mapID = 1434, x = 1, y = 1 } end
  local b2 = H.relog(W, b)
  b2.login(); W.run(2)
  local list = b2.ns.Call.Calls()
  H.erwartet("nach dem Laden: hoechstens 20, kaputte weg", #list == 20 and b2.env.DeathNoteDB.call.fremd == nil, #list)
  local bad = 0
  for _, r in ipairs(list) do if type(r) ~= "table" or type(r.t) ~= "number" or r.by:find("|", 1, true) then bad = bad + 1 end end
  H.erwartet("keiner kaputt", bad == 0, bad)
end)

H.lauf("Sonde: Codes gedeckelt, bleibt ueber /dn probe erhalten, kaputte Sonde wird repariert", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  a.login(); W.run(45)
  for i = 1, 30 do a.ns.Call.NoteCode("T", "GUILD", i) end
  local ch = a.env.DeathNoteDB.probe.call.codes["T.calm"].GUILD
  local n = 0
  for _ in pairs(ch) do n = n + 1 end
  H.erwartet("30 verschiedene Codes: hoechstens 12 plus 'other'", n <= 13 and ch.other == 18, n)
  a.ns.Probe.Run(false)
  local p = a.env.DeathNoteDB.probe.call
  H.erwartet("nach /dn probe noch da, mit Lage", p and p.codes and p.live and p.live.on == true, p and tostring(p.live))
  p.codes.kaputt = 5
  p.codes["T.calm"].NIRGENDS = {}
  p.counts.fremd = 3
  p.unsinn = true
  local a2 = H.relog(W, a)
  a2.login(); W.run(2)
  local q = a2.env.DeathNoteDB.probe.call
  H.erwartet("repariert", q.codes.kaputt == nil and q.codes["T.calm"].NIRGENDS == nil and q.counts.fremd == nil
    and q.unsinn == nil and q.codes["T.calm"].GUILD ~= nil)
end)

H.lauf("/dn probe net: Kanal, CHANNEL und YELL einmal, Zaehler, Kanal wieder verlassen", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  a.login(); W.run(45)
  local joined, left = {}, {}
  a.env.JoinChannelByName = function(n) joined[#joined + 1] = n; return 1, n end
  a.env.LeaveChannelByName = function(n) left[#left + 1] = n end
  a.env.GetChannelName = function(n) return n == "RBkNetProbe" and 5 or 0 end
  H.erwartet("ohne Befehl nichts", #joined == 0)
  a.ns.HandleSlash("probe net")
  W.run(3)
  local net = a.env.DeathNoteDB.probe.call.net
  local chan, yell = 0, 0
  for _, m in ipairs(W.sent) do
    if m.prefix == SOS and m.channel == "CHANNEL" then chan = chan + 1 end
    if m.prefix == SOS and m.channel == "YELL" then yell = yell + 1 end
  end
  H.erwartet("einmal beigetreten, je eine Nachricht", #joined == 1 and chan == 1 and yell == 1, chan .. "/" .. yell)
  H.erwartet("Codes gespeichert", net and net.join == "1" and net.channel == "ok:0" and net.yell == "ok:0",
    net and (tostring(net.channel) .. " " .. tostring(net.yell)))
  a.fire("CHAT_MSG_ADDON", SOS, "1\tN\t5", "CHANNEL", "Kollege-Forever")
  a.fire("CHAT_MSG_ADDON", SOS, "1\tN\t5", "YELL", "Kollege-Forever")
  a.fire("CHAT_MSG_ADDON", SOS, "1\tN\t5", "YELL", "Anton-Forever")
  H.erwartet("fremde Probe gezaehlt, eigenes Echo nicht", net.heard.CHANNEL == 1 and net.heard.YELL == 1)
  H.erwartet("keine Meldung daraus", H.zaehle(a, "HELP_CALL") == 0)
  W.run(120)
  H.erwartet("nach zwei Minuten verlassen", #left == 1 and net.left == true)
end)

H.fertig()
