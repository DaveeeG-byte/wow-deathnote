-- 1.5.0 share: the shown chat line (Share.lua). Building and reading as a round trip (Latin, Cyrillic, CJK), the
-- 255-byte limit and the UTF-8 cut, nothing of "|" from foreign data, the chat filter (fuzz: never throws, changes
-- nothing outside the pattern, secret text untouched), what may never be shown (attacks, suspicion, notes, copied
-- data), the week, sending (one line per 10 s, lockdown, combat, channels), the probe. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Share.lua"

local sent
local function load(db)
  local ns = M.Load({ files = M.Files(FILES), db = db })
  sent = {}
  _G.SendChatMessage = function(text, ch) sent[#sent + 1] = { text = text, ch = ch } end
  _G.IsInRaid, _G.IsInGroup = function() return M.raid == true end, function() return M.party == true end
  M.raid, M.party = false, false
  return ns
end

local function validUTF8(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len = (b < 0x80 and 1) or (b >= 0xF0 and b < 0xF8 and 4) or (b >= 0xE0 and 3) or (b >= 0xC2 and b < 0xE0 and 2) or nil
    if not len or i + len - 1 > n then return false end
    for k = i + 1, i + len - 1 do local c = s:byte(k); if c < 0x80 or c >= 0xC0 then return false end end
    i = i + len
  end
  return true
end

local ns = load()
local S, Sh, L, Fmt = ns.Store, ns.Share, ns.L, ns.F
local now = time()

local function kill(name, surname, t, extra)
  local info = { name = name, surname = surname, class = "ROGUE", level = 40 }
  for k, v in pairs(extra or {}) do info[k] = v end
  return S.ApplyKill(info, { t = t or now - 60, zone = "Schlingendorntal", subzone = "Grom'gol", source = "recap" }, true)
end

---------------------------------------------------------------------------
-- building and reading
---------------------------------------------------------------------------
test("Rundreise: Muster bauen und lesen (Latein, Kyrillisch, CJK)", function()
  for _, name in ipairs({ "Grimwald Aschbrand", "Гримвальд Пеплов", "灰烬 格林", "Ærøn Ødegård" }) do
    local line = Sh.Build(name, { "WANTED", "Stand 2 : 5", "131g Kopfgeld", "zuletzt gesehen Тернистая долина" })
    ok(#line <= 255, "Laenge")
    ok(validUTF8(line), "UTF-8 " .. name)
    local rec = Sh.Parse(line)
    ok(rec, "gelesen " .. name)
    eq(rec.name, name, "Name")
    eq(#rec.segs, 4, "Teile")
    eq(rec.segs[3], "131g Kopfgeld")
    eq(rec.m, 2); eq(rec.h, 5)
    eq(line:sub(1, #Sh.Prefix()), "[Revenge Book: ", "Marke vorn")
  end
end)

test("Marke kommt aus einer Konstante (Share.BRAND)", function()
  local old = Sh.BRAND
  Sh.BRAND = "Probe Buch"
  local line = Sh.Build("Anna Probe", { "X" })
  Sh.BRAND = old
  eq(line, "[Probe Buch: Anna Probe] X")
end)

test("255 Bytes: Teile fallen von hinten weg, nie mitten im Zeichen", function()
  local long = string.rep("Тернистая долина ", 5)   -- 2 bytes per letter
  local line = Sh.Build("Гримвальд Пеплов", { "WANTED", "Счёт 2 : 5", long, long, long })
  ok(#line <= 255, "Laenge " .. #line)
  ok(validUTF8(line), "UTF-8")
  ok(Sh.Parse(line).m == 2, "Stand bleibt (wichtige Teile zuerst)")
end)

test("UTF-8-Schnitt: jede Laenge, nie ein halbes Zeichen", function()
  local s = "aä€𝄞Ж灰b" .. string.rep("Ж灰€", 20)
  for n = 0, #s + 2 do
    local c = Sh.Cut(s, n)
    ok(#c <= math.max(n, 0), "Laenge bei " .. n)
    ok(validUTF8(c), "gueltig bei " .. n)
    eq(s:sub(1, #c), c, "Anfang bei " .. n)
  end
end)

test("Fremde Daten: kein '|', keine Klammern, keine Steuerzeichen in der Zeile", function()
  local line = Sh.Build("Evil|cff00ff00Name|r]", { "a|Hitem:1|h[x]|h", "b\nc", "|T:icon|t" })
  no(line:find("|", 1, true), "kein |")
  no(line:find("[%c]"), "keine Steuerzeichen")
  local rec = Sh.Parse(line)
  ok(rec and rec.name == "Evilcff00ff00Namer", "Name gesaeubert")
end)

---------------------------------------------------------------------------
-- the chat filter
---------------------------------------------------------------------------
test("Filter: Muster wird Link, der Rest bleibt; derselbe Text zweimal = ein Treffer", function()
  local before = Sh.counts.filterHit or 0
  local msg = "hey look [Revenge Book: Grimwald Aschbrand] WANTED · Stand 2 : 5 and more"
  local f, out, author = Sh.Filter(nil, "CHAT_MSG_GUILD", msg, "Anna-Forever", "", "", "", "", 0, 0, "", 0, 77)
  eq(f, false)
  ok(type(out) == "string", "neuer Text")
  eq(author, "Anna-Forever")
  ok(out:find("|Haddon:DeathNote:share:%d+|h%[Revenge Book: Grimwald Aschbrand%]|h"), "Link")
  eq(out:sub(1, 9), "hey look ")
  ok(out:sub(-#" WANTED · Stand 2 : 5 and more") == " WANTED · Stand 2 : 5 and more", "Rest gleich")
  local _, out2 = Sh.Filter(nil, "CHAT_MSG_GUILD", msg, "Anna-Forever", "", "", "", "", 0, 0, "", 0, 77)
  eq(out2, out, "zweites Chatfenster: gleicher Link")
  eq((Sh.counts.filterHit or 0) - before, 1, "ein Treffer")
end)

test("Filter: schon ein Link oder kein Muster: nichts geaendert", function()
  eq(select("#", Sh.Filter(nil, "CHAT_MSG_SAY", "hallo [Revenge Book] nix", "A")), 1)
  local inLink = "x |Hitem:1|h[Revenge Book: Anna Probe]|h y"
  eq(select("#", Sh.Filter(nil, "CHAT_MSG_SAY", inLink, "A")), 1)
end)

test("Filter: secret Text oder Absender: nichts anfassen, Fall gezaehlt", function()
  local before = Sh.counts.secret or 0
  local s = M.Secret("msg", "string")
  local r = { Sh.Filter(nil, "CHAT_MSG_SAY", s, "Anna") }
  eq(#r, 1); eq(r[1], false)
  M.Advance(1)
  r = { Sh.Filter(nil, "CHAT_MSG_SAY", "[Revenge Book: A B] x", M.Secret("author", "string")) }
  eq(#r, 1)
  eq((Sh.counts.secret or 0) - before, 2)
end)

test("Fuzz: beliebiger Chattext wirft nie und bleibt ausserhalb des Musters gleich", function()
  math.randomseed(150)
  local parts = { "[Revenge Book: ", "]", "|", "|h", "|H", "[", " · ", "Ж", "灰", "\0", "\n", "Anna ", "Probe", " ", "2 : 5",
    "|cffff0000", "|r", "addon:", string.char(0xC3), string.char(0xA4), "Revenge Book" }
  for run = 1, 3000 do
    local t = {}
    for i = 1, math.random(0, 12) do
      t[i] = math.random() < 0.7 and parts[math.random(#parts)] or string.char(math.random(0, 255))
    end
    local msg = table.concat(t)
    local okc, f, out = pcall(Sh.Filter, nil, "CHAT_MSG_CHANNEL", msg, "Fuzz-Forever", "", "", "", "", 0, 0, "", 0, run)
    ok(okc, "wirft nicht: " .. ("%q"):format(msg))
    eq(f, false)
    if out ~= nil then
      local s, e = Sh.Find(msg)
      ok(s, "nur mit Muster")
      eq(out:sub(1, s - 1), msg:sub(1, s - 1), "vorn gleich")
      eq(out:sub(-(#msg - e)), #msg - e > 0 and msg:sub(e + 1) or out:sub(-(#msg - e)), "hinten gleich")
      ok(#msg - e == 0 or out:sub(#out - (#msg - e) + 1) == msg:sub(e + 1), "hinten gleich (2)")
    end
  end
end)

test("1.4.0-Client ohne Filter: liest Klartext (keine Steuerfolge, Name lesbar)", function()
  local key = kill("Klara", "Klartext")
  local line = Sh.LineFor(S.Get(key))
  ok(line, "Zeile")
  no(line:find("|", 1, true), "kein |")
  ok(line:find("[Revenge Book: Klara Klartext]", 1, true) == 1, "Name im Klartext vorn")
end)

test("Haken: alle Chat-Ereignisse beim Filter, ueber die globale Funktion", function()
  local reg = {}
  _G.ChatFrame_AddMessageEventFilter = function(ev, fn) reg[ev] = fn end
  Sh.filterVia = nil
  Sh.Hook()
  eq(Sh.filterVia, "global")
  for _, ev in ipairs({ "CHAT_MSG_GUILD", "CHAT_MSG_SAY", "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_WHISPER" }) do
    ok(reg[ev] == Sh.Filter, ev)
  end
  _G.ChatFrame_AddMessageEventFilter = nil
end)

---------------------------------------------------------------------------
-- what may be shown
---------------------------------------------------------------------------
test("Nie geteilt: Verdacht, nur Angriffe, nur Uebernommenes bieten kein Zeigen an", function()
  local sus = S.ApplyKill({ name = "Vera", surname = "Verdacht" }, { t = now - 30, zone = "Z", source = "suspect" }, false)
  eq(S.Get(sus).status, "suspect")
  no(Sh.Offer(S.Get(sus)), "Verdacht")
  no(Sh.LineFor(S.Get(sus)), "keine Zeile")
  -- a suspect stays one even with deeds the book counts (the status decides)
  local sk = kill("Sven", "Status")
  S.Get(sk).status = "suspect"
  no(Sh.Offer(S.Get(sk)), "Status Verdacht")
  S.Get(sk).status = "wanted"
  local att = S.AddAttack({ name = "Arno", surname = "Angriff", class = "MAGE" }, { t = now - 20, zone = "Z" })
  ok(att and S.Get(att), "Angriff eingetragen")
  no(Sh.Offer(S.Get(att)), "nur Angriffe")
  no(Sh.Discord(S.Get(att)), "kein Discord-Block")
  local ad = S.AddManual("Uwe Uebernommen", nil, { adopt = { from = "Fritz Frei", src = "friends", kills = 4 } })
  no(Sh.Offer(S.Get(ad)), "nur uebernommen")
  local man = S.AddManual("Hans Hand")
  ok(Sh.Offer(S.Get(man)), "von Hand eingetragen")
  eq(Sh.LineFor(S.Get(man)), "[Revenge Book: Hans Hand] " .. L.POSTER_HEAD, "nur Name und WANTED")
end)

test("Nie geteilt: Notiz, Angriffszahl und Verdacht stehen in keiner Zeile", function()
  local key = kill("Nora", "Notiz")
  S.SetNote(key, "GEHEIMNOTIZ")
  S.AddAttack({ name = "Nora", surname = "Notiz" }, { t = now - 10, zone = "Angriffszone" })
  local e = S.Get(key)
  ok((e.attacks or 0) > 0, "Angriff da")
  local line, block = Sh.LineFor(e), Sh.Discord(e, "own")
  for _, s in ipairs({ line, block }) do
    no(s:find("GEHEIMNOTIZ", 1, true), "Notiz")
    no(s:find("Angriffszone", 1, true), "Ort des Angriffs")
    no(s:find(Fmt(L.TALLY_ATTACKED, { times = "" }):gsub("%s+$", ""), 1, true), "Angriffswort")
  end
  -- suspicion does not raise the bounty of a shown line
  local a = Sh.LineFor(S.Get(key))
  S.Get(key).suspected = 5
  eq(Sh.LineFor(S.Get(key)), a, "Kopfgeld ohne Verdachtsanteil")
end)

test("Letzte Tat und Ort: nie ein Angriff", function()
  local key = kill("Otto", "Ort")
  S.AddAttack({ name = "Otto", surname = "Ort" }, { t = now + 5, zone = "Angriffsland" })
  local d = Sh.LastOwnDeed(S.Get(key))
  eq(d.zone, "Schlingendorntal")
  ok(Sh.LineFor(S.Get(key)):find("Schlingendorntal", 1, true), "Ort der eigenen Tat")
end)

test("Zeile eines Gesuchten: WANTED, Stand, Kopfgeld, Ort; Rache-Zeile mit jetzt", function()
  local key = kill("Grimm", "Bart")
  kill("Grimm", "Bart", now - 3000)
  local e = S.Get(key)
  e.lastSeen = { t = now - 100, zone = "Arathihochland" }
  local line = Sh.LineFor(e)
  local rec = Sh.Parse(line)
  eq(rec.name, "Grimm Bart")
  eq(rec.segs[1], L.POSTER_HEAD)
  ok(rec.m == 0 and rec.h == 2, "Stand 0 : 2")
  ok(line:find(Fmt(L.SHARE_SEEN, { zone = "Arathihochland" }), 1, true), "zuletzt gesehen")
  local rv = Sh.RevengeLine(e)
  ok(Sh.Parse(rv).segs[1] == L.BANNER_REVENGE, "Rache-Wort")
end)

---------------------------------------------------------------------------
-- the week
---------------------------------------------------------------------------
test("Woche: meistgesucht (Todesstoesse dieser Woche), Rache, offene Rechnungen", function()
  ns = load()
  S, Sh, L = ns.Store, ns.Share, ns.L
  now = time()
  local a = kill("Anton", "Woche", now - 3600)
  kill("Anton", "Woche", now - 7200); kill("Anton", "Woche", now - 9000)
  local b = kill("Berta", "Woche", now - 100)
  local c = kill("Carl", "Alt", now - 10 * 86400)
  for i = 1, 4 do kill("Carl", "Alt", now - (10 + i) * 86400) end
  for i = 1, 5 do S.AddAttack({ name = "Dora", surname = "Angriff" }, { t = now - 50 * i, zone = "Z" }) end
  local w = Sh.Week(now)
  eq(w.top and w.top.key, a, "Anton ist der Meistgesuchte")
  eq(w.topN, 3)
  eq(w.debts, 3, "Anton, Berta, Carl offen (Angriff zaehlt nicht)")
  local log = ns.Ledger.Log()
  log[#log + 1] = { t = now - 500, key = b, f = "v" }
  log[#log + 1] = { t = now - 9 * 86400, key = c, f = "v" }
  log[#log + 1] = { t = now - 600, key = c, f = "g" }
  eq(Sh.Week(now).revenge, 1, "eine Rache in 7 Tagen")
  local line = Sh.WeekLine(now)
  eq(Sh.Parse(line).name, "Anton Woche")
  ok(line:find(L.SHARE_WEEK_HEAD, 1, true), "Kopf")
end)

test("Woche ohne Tode: kein Name, kein Link", function()
  ns = load()
  S, Sh = ns.Store, ns.Share
  local line = Sh.WeekLine(time())
  eq(line:sub(1, 15), "[Revenge Book] ")
  no(Sh.Find(line), "kein Muster mit Name")
end)

---------------------------------------------------------------------------
-- sending
---------------------------------------------------------------------------
test("Senden: Kanal, eine Zeile je 10 s, Sperre, Kampf, kein '|'", function()
  ns = load()
  S, Sh = ns.Store, ns.Share
  local line = "[Revenge Book: Anna Probe] WANTED"
  local r, why = Sh.Send(line, "GUILD")
  no(r); eq(why, "channel", "keine Gilde")
  M.units.player.guild = "Die Probe"
  M.party = true
  local ch = Sh.Channels()
  eq(table.concat(ch, ","), "GUILD,PARTY,SAY")
  M.raid = true
  eq(table.concat(Sh.Channels(), ","), "GUILD,RAID,SAY")
  ok(Sh.Send(line, "GUILD"), "gesendet")
  eq(sent[1].text, line); eq(sent[1].ch, "GUILD")
  r, why = Sh.Send(line, "SAY")
  no(r); eq(why, "cooldown")
  M.Advance(10)
  M.chatLockdown = true
  r, why = Sh.Send(line, "SAY")
  no(r); eq(why, "lockdown")
  M.chatLockdown = false
  M.inCombat = true
  r, why = Sh.Send(line, "SAY")
  no(r); eq(why, "combat")
  M.inCombat = false
  r, why = Sh.Send("a|Hb", "SAY")
  no(r); eq(why, "empty")
  ok(Sh.Send(line, "SAY"), "nach 10 s wieder")
  eq(#sent, 2)
  eq(Sh.counts["sent.GUILD"], 1); eq(Sh.counts["sent.SAY"], 1)
  eq(Sh.counts["refused.cooldown"], 1); eq(Sh.counts["refused.lockdown"], 1); eq(Sh.counts["refused.combat"], 1)
end)

test("Sonde: probe.share mit Zaehlern, bleibt ueber Probe.Run", function()
  local db = S.DB()
  ok(db.probe.share.counts["sent.SAY"] == 1, "gespeichert")
  ns.Probe.Run(false)
  ok(db.probe.share and db.probe.share.counts["sent.SAY"] == 1, "nach Probe.Run")
  ok(db.probe.share.session and db.probe.share.send == "global", "Sitzung und Sendeweg")
end)

M.done("test_share")
