-- Guild sharing (Sync.lua): protocol, validation, merge, caps, queue, two clients.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function inGuild(name) M.units.player.guild = name end

local function loadGuild(opts)
  opts = opts or {}
  local ns = M.Load({ before = function()
    if opts.db then _G.DeathNoteDB = opts.db end
    if opts.guild ~= false then inGuild(opts.guild or "Die Wurstbrüder") end
  end })
  return ns
end

-- A sure open-world PvP death of this account, as Attribution reports it.
local function ownDeath(ns, killer, surname, t, extra)
  t = t or time()
  local info = { name = killer, surname = surname, class = "ROGUE", level = 42 }
  local rec = { t = t, zone = (extra and extra.zone) or "Schlingendorntal", me = "Varorak Narenmar",
    myLevel = 40, theirLevel = 42, source = "recap", others = {} }
  local key = ns.Store.ApplyKill(info, rec, true)
  local journal = { t = t, zone = rec.zone, me = rec.me, kind = "pvp", sure = true, counted = true,
    killerKey = key, source = "recap" }
  ns.Store.RecordDeath(journal)
  ns:Fire("DEATH_RECORDED", journal, key)
  return key
end

local function decodeOK(ns, text)
  return ns.Guild.Proto.Decode(text, time(), {})
end

-- feeds a message as if `sender` had sent it to the guild
local function hear(text, sender)
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender or "Kollege-Forever")
end

local function killMsg(ns, o)
  o = o or {}
  return ns.Guild.Proto.EncodeKill({ key = o.key or "Grimm-Bart", display = o.display or "Grimm Bart",
    class = o.class or "ROGUE", level = o.level or 44, zone = o.zone or "Arathihochland",
    t = o.t or time(), victim = o.victim or "Kollege Wurst" }, o.kind or "K")
end

---------------------------------------------------------------------------
-- Protocol
---------------------------------------------------------------------------
test("Kodieren/Dekodieren: Umlaute, Trennzeichen, Sonderzeichen", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local k = { key = "Ärger-Möhrenkönig", display = "Ärger Möhrenkönig", class = "MAGE", level = 60,
    zone = "Zul'Gurub\t100%|cffff0000rot|r\nneu", t = time() - 100, victim = "Grüß Gott%7C" }
  local text = P.EncodeKill(k, "K")
  ok(text and #text <= 255, "kodiert")
  no(text:find("\n", 1, true), "kein Zeilenumbruch im Text")
  eq(select(2, text:gsub("\t", "")), 8, "genau 8 Trenner")
  local m = decodeOK(ns, text)
  ok(m, "dekodiert")
  eq(m.kind, "K"); eq(m.key, "Ärger-Möhrenkönig"); eq(m.name, "Ärger"); eq(m.surname, "Möhrenkönig")
  eq(m.display, "Ärger Möhrenkönig"); eq(m.class, "MAGE"); eq(m.level, 60); eq(m.t, k.t)
  -- control bytes and '|' are removed on the sending side (no UI escape codes travel)
  eq(m.zone, "Zul'Gurub100%cffff0000rotrneu"); eq(m.victim, "Grüß Gott%7C")
  local h = decodeOK(ns, P.EncodeHello(123456, "1.0.0"))
  eq(h.kind, "H"); eq(h.since, 123456); eq(h.version, "1.0.0")
  local s = decodeOK(ns, P.EncodeSight("Grimm-Bart", "Dämmerwald", time()))
  eq(s.kind, "S"); eq(s.zone, "Dämmerwald")
end)

test("255-Byte-Grenze: lange Felder werden UTF-8-sicher gekürzt", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local long = string.rep("%", 60)       -- each byte becomes 3 on the wire
  local k = { key = "Grimm-Bart", display = "Grimm Bart", class = "ROGUE", level = 1,
    zone = string.rep("ö", 32), t = time(), victim = long }
  local text = P.EncodeKill(k, "R")
  ok(text, "noch kodierbar"); ok(#text <= 255, "<= 255 Bytes, war " .. #text)
  local m = decodeOK(ns, text)
  ok(m, "dekodierbar"); eq(m.victim, long)
  ok(m.zone == nil or m.zone:match("^[ö]*$"), "Zone nur ganze Zeichen")
  -- the receiver refuses anything above 255 bytes
  no(decodeOK(ns, text .. string.rep("x", 256 - #text)))
  eq(P.CutUTF8("aö", 2), "a"); eq(P.CutUTF8("aö", 3), "aö"); eq(P.CutUTF8("a€", 3), "a")
end)

test("Kaputte, abgeschnittene und bösartige Nachrichten werden verworfen, nichts wirft", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local now = time()
  local good = killMsg(ns)
  ok(decodeOK(ns, good), "Vorlage gültig")
  local bad = {
    "", "1", "1\tK", "2\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. now .. "\tOpfer",   -- falsche Version
    "1\tX\tGrimm-Bart", "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. now,          -- Feld fehlt
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. now .. "\tOpfer\textra",
    "1\tK\tgrimm-bart\t\tROGUE\t44\tZone\t" .. now .. "\tOpfer",                 -- nicht kanonisch
    "1\tK\tGrimm\t\tROGUE\t44\tZone\t" .. now .. "\tOpfer",                      -- ohne Nachname
    "1\tK\tGrimm-Bart\t\trogue\t44\tZone\t" .. now .. "\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t-1\tZone\t" .. now .. "\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t500\tZone\t" .. now .. "\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t4x\tZone\t" .. now .. "\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. (now + 3600) .. "\tOpfer",        -- Zukunft
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. (now - 200 * 86400) .. "\tOpfer", -- zu alt
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t1e9\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. now .. "\t",                      -- kein Opfer
    "1\tK\tGrimm-Bart\t\tROGUE\t44\t%G1\t" .. now .. "\tOpfer",                  -- kaputtes Escape
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone%2\t" .. now .. "\tOpfer",
    "1\tK\tGrimm-Bart\t\tROGUE\t44\t%7CTInterface\\x:999%7Ct\t" .. now .. "\tOpfer", -- Textur-Injektion
    "1\tK\tGrimm-Bart\t\tROGUE\t44\tZone\t" .. now .. "\tOp%00fer",
    "1\tK\tGrimm-Bart\t\tROGUE\t44\t" .. string.rep("z", 65) .. "\t" .. now .. "\tOpfer",
    "1\tH\tabc\t1.0", "1\tH\t" .. (now + 9999) .. "\t1.0", "1\tH\t1",
    "1\tS\tGrimm-Bart\tZone", string.rep("\t", 20), string.rep("x", 300),
  }
  for i, b in ipairs(bad) do
    local okc, m = pcall(P.Decode, b, now, {})
    ok(okc, "wirft nicht #" .. i)
    no(m, "verworfen #" .. i)
  end
  for _, v in ipairs({ nil, 5, {}, true }) do
    local okc, m = pcall(P.Decode, v, now, {})
    ok(okc); no(m)
  end
  -- every truncation of a valid message: never raises, never a wrong victim
  for n = 0, #good - 1 do
    local okc, m = pcall(P.Decode, good:sub(1, n), now, {})
    ok(okc, "abgeschnitten " .. n)
    if m then ok(m.victim and ("Kollege Wurst"):sub(1, #m.victim) == m.victim, "Teil-Opfer " .. n) end
  end
  -- random garbage through the real event handler
  math.randomseed(7)
  local before = ns.Guild.Count()
  for _ = 1, 3000 do
    local len = math.random(0, 260)
    local t = {}
    for j = 1, len do
      local r = math.random(1, 10)
      t[j] = r <= 2 and "\t" or (r == 3 and "%" or string.char(math.random(0, 255)))
    end
    hear((math.random() < 0.5 and "1\tK\t" or "") .. table.concat(t), "Troll" .. math.random(1, 50) .. "-Forever")
  end
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", M.Secret("text"), "GUILD", "X-Forever")
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", good, "GUILD", M.Secret("sender"))
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", good, "WHISPER", "X-Forever")
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", nil, "GUILD", nil)
  eq(#M.errors, 0, "keine Lua-Fehler")
  eq(ns.Guild.Count(), before, "nichts übernommen")
  -- another prefix is ignored before any work
  M.FireEvent("CHAT_MSG_ADDON", "Other", good, "GUILD", "X-Forever")
  eq(ns.Guild.Count(), 0)
end)

---------------------------------------------------------------------------
-- Merge, dedupe, caps
---------------------------------------------------------------------------
test("Dedupe: dieselbe Tat zweimal und das eigene Echo zählen nicht doppelt", function()
  local ns = loadGuild()
  local t = time() - 50
  local msg = killMsg(ns, { t = t })
  hear(msg, "Kollege-Forever")
  hear(msg, "Kollege-Forever")
  hear(killMsg(ns, { t = t, kind = "R" }), "Anderer-Forever")
  local e = ns.Guild.Get("Grimm-Bart")
  ok(e); eq(e.kills, 1); eq(#e.deeds, 1); eq(e.deeds[1].by, "Kollege")
  -- own echo: the guild channel hands my own message back
  local key = ownDeath(ns, "Rabauke", "Stank", time() - 10)
  eq(ns.Guild.Get(key).kills, 1, "eigener Kill in der Gildenliste")
  local sent = M.addonSent[#M.addonSent]
  ok(sent and sent.text:find("^1\tK\tRabauke%-Stank"), "K gesendet")
  eq(sent.channel, "GUILD")
  hear(sent.text, "Varorak-Forever")
  hear(sent.text, "Varorak")
  eq(ns.Guild.Get(key).kills, 1, "Echo ignoriert")
  -- after /reload the same deed stays single
  ns = M.Load({ keepWorld = true, db = _G.DeathNoteDB })
  hear(msg, "Kollege-Forever")
  eq(ns.Guild.Get("Grimm-Bart").kills, 1, "nach Reload")
  eq(ns.Guild.Get(key).kills, 1)
end)

test("Deckelung: 400 Feinde, 20 Taten je Feind, älteste fallen raus", function()
  local ns = loadGuild()
  local P = ns.Guild.Proto
  local st = { enemies = {}, count = 0 }
  local base = time() - 10000
  for i = 1, 405 do
    local key = "Feind" .. string.char(97 + i % 26) .. i .. "-Bart"
    local n, s = P.ValidKey(key)
    ok(n, key)
    P.Merge(st, { key = key, name = n, surname = s, t = base + i, victim = "Opfer" }, "x")
  end
  eq(st.count, 400)
  local n = 0; for _ in pairs(st.enemies) do n = n + 1 end
  eq(n, 400)
  no(st.enemies["Feindb1-Bart"], "ältester raus")
  ok(st.enemies["Feindl401-Bart"] or st.enemies["Feind" .. string.char(97 + 401 % 26) .. "401-Bart"])
  local e = { enemies = {}, count = 0 }
  for i = 1, 25 do P.Merge(e, { key = "Grimm-Bart", name = "Grimm", surname = "Bart", t = base + i, victim = "O" .. i }, "x") end
  local g = e.enemies["Grimm-Bart"]
  eq(#g.deeds, 20); eq(g.kills, 20); eq(g.deeds[1].t, base + 25); eq(g.deeds[20].t, base + 6)
  eq(P.Merge(e, { key = "Grimm-Bart", name = "Grimm", surname = "Bart", t = base + 1, victim = "Alt" }, "x"), "old")
  eq(g.victimCount, 20); eq(g.lastVictim, "O25")
  -- through the handler too
  for i = 1, 30 do hear(killMsg(ns, { t = time() - 1000 + i, victim = "Kollege Opfer" .. i }), "Kollege-Forever") end
  eq(ns.Guild.Get("Grimm-Bart").kills, 20)
end)

test("Flutschutz je Absender: 150 Nachrichten je Minute, 40 Feinde je Mitglied", function()
  local ns = loadGuild()
  for i = 1, 200 do
    hear(killMsg(ns, { key = "Grimm-Bart" .. string.char(97 + i % 26) .. i, t = time() - i, victim = "Flut V" }), "Flut-Forever")
  end
  eq(ns.Guild.Count(), 40, "höchstens 40 Feinde von einem Mitglied")
  M.Advance(61)
  hear(killMsg(ns, { key = "Spaet-Kommer", t = time() - 5, victim = "Flut V" }), "Flut-Forever")
  eq(ns.Guild.Count(), 40, "auch später nicht mehr")
  -- message count: after 150 messages in a minute even a valid new kill is dropped
  local msg = killMsg(ns, { key = "Dup-Licat", t = time() - 5, victim = "Viel V" })
  for _ = 1, 150 do hear(msg, "Viel-Forever") end
  eq(ns.Guild.Count(), 41)
  hear(killMsg(ns, { key = "Neu-Ling", t = time() - 5, victim = "Viel V" }), "Viel-Forever")
  no(ns.Guild.Get("Neu-Ling"), "151. Nachricht verworfen")
  M.Advance(61)
  hear(killMsg(ns, { key = "Neu-Ling", t = time() - 5, victim = "Viel V" }), "Viel-Forever")
  ok(ns.Guild.Get("Neu-Ling"), "neue Minute")
end)

---------------------------------------------------------------------------
-- Clients
---------------------------------------------------------------------------
-- A second, isolated client in the same Lua state: own globals, frames and SavedVariables,
-- shared clock and timers, shared guild channel.
local Client = {}
local clients = {}
local wire = {}

local function newClient(name, surname, guild)
  local c = { name = name, surname = surname, guild = guild, frames = {}, sendResult = nil, combat = false }
  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.DeathNoteDB = nil
  env.CreateFrame = function()
    local f = _G.CreateFrame()
    table.remove(M.frames)          -- keep it out of the mock's global list
    c.frames[#c.frames + 1] = f
    return f
  end
  env.UnitName = function(t) if t == "player" then return c.name, c.surname end return _G.UnitName(t) end
  env.UnitGUID = function(t) if t == "player" then return "Player-1-" .. c.name end return _G.UnitGUID(t) end
  env.GetGuildInfo = function(t) if t == "player" then return c.guild end return _G.GetGuildInfo(t) end
  env.IsInGuild = function() return c.guild ~= nil end
  env.InCombatLockdown = function() return c.combat end
  env.C_ChatInfo = {
    RegisterAddonMessagePrefix = function() return 0 end,
    SendAddonMessage = function(prefix, text, channel)
      assert(#text <= 255)
      if c.sendResult and c.sendResult ~= 0 then return c.sendResult end
      wire[#wire + 1] = { prefix = prefix, text = text, channel = channel, from = c.name .. "-Forever", guild = c.guild }
      return 0
    end,
  }
  c.env = env
  local ns = {}
  for _, f in ipairs(M.FILES) do
    local chunk = assert(loadfile(M.ADDON_DIR .. f))
    setfenv(chunk, env)
    chunk("DeathNote", ns)
  end
  M.ChooseLanguage(ns)        -- 1.2.0: the test client reads German, chosen explicitly
  c.ns = ns
  c.events = {}
  for _, ev in ipairs({ "GUILD_KILL", "GUILD_UPDATED" }) do
    ns:On(ev, function(...) c.events[#c.events + 1] = { ev, ... } end)
  end
  clients[#clients + 1] = c
  return c
end

function Client.fire(c, event, ...)
  for _, f in ipairs(c.frames) do
    if f.events[event] and f.scripts.OnEvent then
      local okc, err = pcall(f.scripts.OnEvent, f, event, ...)
      if not okc then M.errors[#M.errors + 1] = err end
    end
  end
end

-- delivers everything on the wire to every client of the same guild (sender included: echo)
local function deliver()
  local n = 0
  while #wire > 0 do
    local m = table.remove(wire, 1)
    n = n + 1
    for _, c in ipairs(clients) do
      if c.guild == m.guild then Client.fire(c, "CHAT_MSG_ADDON", m.prefix, m.text, m.channel, m.from) end
    end
  end
  return n
end

local function run(sec)
  for _ = 1, math.ceil(sec / 0.1) do M.Advance(0.1); deliver() end
end

local function snapshot(c)
  local out = {}
  for _, e in ipairs(c.ns.Guild.List("name")) do
    local d = {}
    for _, x in ipairs(e.deeds) do d[#d + 1] = x.t .. "/" .. x.victim end
    out[#out + 1] = e.key .. ":" .. e.kills .. ":" .. table.concat(d, ",")
  end
  return table.concat(out, ";")
end

test("Zwei Clients tauschen H/R/K aus und haben danach dieselbe Gildenliste", function()
  M.Reset()
  clients, wire = {}, {}
  local a = newClient("Anton", "Wurst", "Die Wurstbrüder")
  local b = newClient("Berta", "Senf", "Die Wurstbrüder")
  local outsider = newClient("Fremd", "Ling", "Andere Gilde")
  for _, c in ipairs({ a, b, outsider }) do Client.fire(c, "PLAYER_LOGIN"); Client.fire(c, "PLAYER_ENTERING_WORLD") end
  -- history before the first sync: Anton 3 deaths, Berta 2 (one by the same killer)
  local function die(c, killer, surname, ago, victim)
    local ns = c.ns
    local t = time() - ago
    local key = ns.Store.ApplyKill({ name = killer, surname = surname, class = "ROGUE", level = 50 },
      { t = t, zone = "Brachland", me = victim, theirLevel = 50, source = "recap", others = {} }, true)
    return key, t
  end
  die(a, "Grimm", "Bart", 5000, "Anton Wurst")
  die(a, "Grimm", "Bart", 4000, "Anton Wurst")
  die(a, "Böse", "Wicht", 3000, "Anton Zweitchar")   -- another character of the account: not shared
  die(b, "Grimm", "Bart", 2000, "Berta Senf")
  die(b, "Fies", "Ling", 1000, "Berta Senf")
  die(outsider, "Nur", "Fremd", 900, "Fremd Ling")
  -- an imported (foreign) deed must never be passed on
  ok(b.ns.Store.Import("DEATHNOTE:1\nE|Import-Iert|wanted|0|1|0|0|||||ROGUE|||||Iert||\nD|Import-Iert|" ..
    (time() - 500) .. "|1|recap|Zone|||||Jemand Anders||"))
  -- force a fresh bind so the backfill sees the history
  a.ns.Guild.Init(); b.ns.Guild.Init(); outsider.ns.Guild.Init()
  -- logins send H after 8 to 20 s, answers come with delay and throttling
  run(60)
  eq(#M.errors, 0, tostring(M.errors[1]))
  local sa, sb = snapshot(a), snapshot(b)
  eq(sa, sb, "gleiche Liste")
  local ga = a.ns.Guild.Get("Grimm-Bart")
  eq(ga.kills, 3); eq(ga.victimCount, 2); eq(ga.victims["Anton Wurst"], 2); eq(ga.victims["Berta Senf"], 1)
  no(a.ns.Guild.Get("Import-Iert"), "Importiertes nicht geteilt")
  no(a.ns.Guild.Get("Nur-Fremd"), "andere Gilde bleibt draußen")
  no(a.ns.Guild.Get("Böse-Wicht"), "Tod eines anderen Chars geht nicht an diese Gilde")
  eq(select(1, a.ns.Guild.Count()), 2)
  -- members with the addon
  local mem = a.ns.Guild.Members()
  eq(#mem, 1); eq(mem[1].name, "Berta"); eq(mem[1].version, "1.0.0")
  -- no GUILD_KILL for history
  for _, ev in ipairs(a.events) do no(ev[1] == "GUILD_KILL", "kein GUILD_KILL beim Nachladen") end
  -- a live kill: Berta dies now, Anton sees it at once
  local key = b.ns.Store.ApplyKill({ name = "Neu", surname = "Ling", class = "MAGE", level = 51 },
    { t = time(), zone = "Ashenvale", me = "Berta Senf", theirLevel = 51, source = "recap", others = {} }, true)
  b.ns:Fire("DEATH_RECORDED", { t = time(), zone = "Ashenvale", me = "Berta Senf", kind = "pvp", sure = true,
    counted = true, killerKey = key }, key)
  run(1)
  local gk
  for _, ev in ipairs(a.events) do if ev[1] == "GUILD_KILL" then gk = ev end end
  ok(gk, "GUILD_KILL bei frischer Tat")
  eq(gk[3], "Neu-Ling"); eq(gk[2].victim, "Berta Senf"); eq(gk[2].by, "Berta"); eq(gk[2].zone, "Ashenvale")
  eq(snapshot(a), snapshot(b), "nach K wieder gleich")
  -- the next sync within a minute is refused, after it allowed
  local okNow, wait = a.ns.Guild.SyncNow()
  no(okNow); ok(type(wait) == "number")
  run(61)
  ok(a.ns.Guild.SyncNow())
  run(30)
  eq(snapshot(a), snapshot(b), "nach erneutem Sync gleich")
  eq(#M.errors, 0)
end)

test("Gildenwechsel verwirft die alte Liste", function()
  local ns = loadGuild({ guild = "Alte Gilde" })
  hear(killMsg(ns, { t = time() - 30 }))
  eq(ns.Guild.Count(), 1); eq(ns.Guild.Name(), "Alte Gilde")
  inGuild(nil)
  M.FireEvent("PLAYER_GUILD_UPDATE", "player")
  eq(ns.Guild.Count(), 1, "nach Austritt bleibt sie liegen")
  no(ns.Guild.Enabled()); eq(ns.Guild.Name(), nil)
  inGuild("Neue Gilde")
  M.FireEvent("PLAYER_GUILD_UPDATE", "player")
  eq(ns.Guild.Count(), 0, "neue Gilde, neue Liste")
  eq(_G.DeathNoteDB.guild.name, "Neue Gilde")
  -- guild info briefly missing after login does not wipe anything
  hear(killMsg(ns, { t = time() - 30 }))
  M.units.player.guild = nil
  ns.Guild.Bind()
  inGuild("Neue Gilde")
  eq(ns.Guild.Count(), 1)
end)

test("Warteschlange: Drosselung, Kampf, Ablehnung, nie endlos", function()
  local ns = loadGuild()
  M.Advance(30)               -- the login hello is out
  M.addonSent = {}
  -- throttled first, then accepted
  local calls = 0
  M.sendResult = function() calls = calls + 1; if calls <= 2 then return 3 end return 0 end
  for i = 1, 5 do ownDeath(ns, "Täter" .. string.char(96 + i), "Bart", time() - i) end
  eq(#M.addonSent, 0, "gedrosselt: noch nichts raus")
  M.Advance(10)
  eq(#M.addonSent, 5, "alles raus nach Drosselung")
  for i = 2, #M.addonSent do
    ok(M.addonSent[i].at - M.addonSent[i - 1].at >= 0.3 - 1e-9, "Abstand >= 0,3 s")
  end
  -- combat: held, then sent on PLAYER_REGEN_ENABLED
  M.sendResult = nil; M.addonSent = {}
  M.inCombat = true
  ownDeath(ns, "Kampf", "Hahn", time())
  M.Advance(5)
  eq(#M.addonSent, 0, "im Kampf nicht")
  eq(ns.Guild.QueueSize(), 1)
  M.inCombat = false
  M.FireEvent("PLAYER_REGEN_ENABLED")
  eq(#M.addonSent, 1, "nach dem Kampf")
  -- chat lockdown of the modern engine works the same
  M.chatLockdown = true
  ownDeath(ns, "Sperr", "Zeit", time())
  M.Advance(1); eq(ns.Guild.QueueSize(), 1)
  M.chatLockdown = false
  M.FireEvent("ADDON_RESTRICTION_STATE_CHANGED")
  eq(ns.Guild.QueueSize(), 0)
  -- permanent refusal (e.g. not in guild = 5): dropped at once
  M.sendResult = 5
  ownDeath(ns, "Weg", "Damit", time())
  M.Advance(0.5)              -- (fix-1) zwei Sendungen nie enger als 0,3 s, auch nach leerer Schlange
  eq(ns.Guild.QueueSize(), 0)
  -- general error: at most 5 tries
  calls = 0
  M.sendResult = function() calls = calls + 1; return 9 end
  ownDeath(ns, "Fehl", "Schlag", time())
  M.Advance(60)
  eq(calls, 5); eq(ns.Guild.QueueSize(), 0)
  -- pcall: a throwing send never breaks anything
  M.sendResult = function() error("boom") end
  ownDeath(ns, "Wirft", "Fehler", time())
  M.Advance(60)
  eq(ns.Guild.QueueSize(), 0)
  -- held forever (combat never ends): the queue is given up, no timer remains
  M.sendResult = nil
  M.inCombat = true
  ownDeath(ns, "Ewig", "Kampf", time())
  M.Advance(3600)
  eq(ns.Guild.QueueSize(), 0, "nie endlos")
  eq(#M.timers, 0, "kein Timer läuft weiter")
  M.inCombat = false
  eq(#M.errors, 0)
end)

test("Kein Senden ohne Gilde oder bei share = false", function()
  local ns = loadGuild({ guild = false })
  M.Advance(60)
  ownDeath(ns, "Grimm", "Bart", time())
  hear("1\tH\t0\t1.0.0", "Kollege-Forever")
  M.Advance(60)
  eq(#M.addonSent, 0, "ohne Gilde nichts")
  no(ns.Guild.Enabled())
  eq(ns.Guild.Count(), 0, "ohne Gilde keine Gildenliste")
  ns = loadGuild()
  ns.Store.Setting("guild.share", false)
  M.Advance(60)
  ownDeath(ns, "Grimm", "Bart", time())
  hear("1\tH\t0\t1.0.0", "Kollege-Forever")
  M.Advance(60)
  eq(#M.addonSent, 0, "share = false: nichts")
  no(ns.Guild.Enabled())
  ns.Store.Setting("guild.share", true)
  ok(ns.Guild.SyncNow())
  eq(#M.addonSent, 1); ok(M.addonSent[1].text:find("^1\tH\t"))
  -- receive = false: incoming kills are ignored
  ns.Store.Setting("guild.receive", false)
  hear(killMsg(ns, { key = "Nicht-Da", t = time() }))
  no(ns.Guild.Get("Nicht-Da"))
end)

test("Antwort auf H: nur eigene Kills, neuer als since, neueste zuerst, höchstens 30", function()
  local ns = loadGuild()
  M.Advance(30)
  local base = time() - 100000
  for i = 1, 70 do
    ns.Store.ApplyKill({ name = "Serie" .. string.char(96 + (i % 26) + 1), surname = "T" .. string.char(96 + math.floor(i / 26) + 1) },
      { t = base + i * 10, zone = "Z", me = "Varorak Narenmar", source = "recap", others = {} }, true)
  end
  ns.Store.ApplyKill({ name = "Verdacht", surname = "Nur" },
    { t = base + 5000, zone = "Z", me = "Varorak Narenmar", source = "suspect", others = {} }, false)
  M.addonSent = {}
  hear("1\tH\t" .. (base + 50) .. "\t1.0.0", "Kollege-Forever")
  hear("1\tH\t" .. (base + 5) .. "\t1.0.0", "Dritter-Forever")   -- merged into the pending answer
  M.Advance(60)
  -- fix-2: am Ende jeder Antwort steht ein Z (Momentaufnahme der Freigaben); gezaehlt werden die Taten
  for i = #M.addonSent, 1, -1 do if M.addonSent[i].text:match("^1\tZ\t") then table.remove(M.addonSent, i) end end
  eq(#M.addonSent, 30, "höchstens 30")
  local P = ns.Guild.Proto
  local prev = math.huge
  for _, s in ipairs(M.addonSent) do
    local m = P.Decode(s.text, time(), {})
    ok(m and m.kind == "R", "R-Nachricht")
    ok(m.t > base + 5 and m.t <= prev, "neuer als since, absteigend")
    no(m.key == "Verdacht-Nur", "kein Verdacht")
    prev = m.t
  end
  -- a member logging in later did not hear that answer: answered too (B8)
  M.addonSent = {}
  hear("1\tH\t" .. (base + 500) .. "\t1.0.0", "Vierter-Forever")
  M.Advance(30)
  for i = #M.addonSent, 1, -1 do if M.addonSent[i].text:match("^1\tZ\t") then table.remove(M.addonSent, i) end end
  eq(#M.addonSent, 20, "Vierter bekommt eine Antwort (20 Taten neuer als sein since)")
  -- the same member again within 5 minutes: not answered
  M.addonSent = {}
  hear("1\tH\t" .. (base + 5) .. "\t1.0.0", "Kollege-Forever")
  M.Advance(30)
  eq(#M.addonSent, 0, "gleiches Mitglied, 5-Minuten-Sperre")
end)

test("GUILD_KILL nur bei frischen K-Taten", function()
  local ns = loadGuild()
  M.ClearFired()
  hear(killMsg(ns, { t = time() - 30, victim = "Kollege B" }))
  eq(#M.Fired("GUILD_KILL"), 1)
  local ev = M.Fired("GUILD_KILL")[1]
  eq(ev[3], "Grimm-Bart"); eq(ev[2].victim, "Kollege B"); eq(ev[2].by, "Kollege")
  hear(killMsg(ns, { t = time() - 600, victim = "Kollege D" }))
  hear(killMsg(ns, { t = time() - 5, victim = "Kollege F", kind = "R" }))
  hear(killMsg(ns, { t = time() - 30, victim = "Kollege B" }))            -- duplicate
  eq(#M.Fired("GUILD_KILL"), 1)
  ns.Store.Setting("guild.announce", false)
  hear(killMsg(ns, { t = time() - 3, victim = "Kollege H" }))
  eq(#M.Fired("GUILD_KILL"), 1, "announce aus")
  -- own kills never fire it
  ns.Store.Setting("guild.announce", true)
  ownDeath(ns, "Selbst", "Schuld", time())
  eq(#M.Fired("GUILD_KILL"), 1)
  -- GUILD_UPDATED is throttled
  M.ClearFired()
  for i = 1, 40 do hear(killMsg(ns, { key = "Masse-Sync", t = time() - 100 - i, victim = "Masse V" .. i, kind = "R" }), "Masse-Forever") end
  M.Advance(0.6)
  eq(#M.Fired("GUILD_UPDATED"), 1, "einmal je 0,5 s")
end)

test("Tracker: GUILD_ENEMY_SPOTTED nur für Gildenfeinde, die nicht auf meiner Liste stehen", function()
  local ns = loadGuild()
  no(ns.Tracker.guildHook, "leere Gildenliste: kein Haken")
  hear(killMsg(ns, { key = "Grimm-Bart", t = time() - 30 }))
  hear(killMsg(ns, { key = "Mein-Feind", t = time() - 30 }))
  ok(ns.Tracker.guildHook, "Haken gesetzt")
  ns.Store.AddManual("Mein", "Feind")
  M.ClearFired()
  M.AddEnemy("target", { name = "Grimm", surname = "Bart" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  local s = M.Fired("GUILD_ENEMY_SPOTTED")
  eq(#s, 1); eq(s[1][2], "Grimm-Bart"); eq(s[1][3], "target"); eq(s[1][4], "target")
  ok(ns.Guild.Get("Grimm-Bart").lastSeen, "lastSeen gesetzt")
  eq(ns.Guild.Get("Grimm-Bart").lastSeen.by, "Varorak")
  M.AddEnemy("target", { name = "Mein", surname = "Feind" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#M.Fired("GUILD_ENEMY_SPOTTED"), 1, "eigener Feind: nur ENEMY_SPOTTED")
  eq(#M.Fired("ENEMY_SPOTTED"), 1)
  -- friendly unit with the same name: nothing
  M.AddEnemy("target", { name = "Grimm", surname = "Bart", enemy = false, canAttack = false, faction = "Horde" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#M.Fired("GUILD_ENEMY_SPOTTED"), 1)
  -- minKills
  ns.Store.Setting("guild.minKills", 2)
  M.Advance(1)
  M.AddEnemy("target", { name = "Grimm", surname = "Bart" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  eq(#M.Fired("GUILD_ENEMY_SPOTTED"), 1, "minKills 2")
  ns.Guild.Clear()
  no(ns.Tracker.guildHook, "nach Clear kein Haken")
  eq(ns.Guild.Count(), 0)
end)

test("Sichtungen (S) nur mit Einstellung", function()
  local ns = loadGuild()
  M.Advance(30); M.addonSent = {}
  hear(killMsg(ns, { t = time() - 30 }))
  M.ClearFired()
  hear(ns.Guild.Proto.EncodeSight("Grimm-Bart", "Dämmerwald", time()))
  eq(#M.Fired("GUILD_SIGHTING"), 0, "aus: ignoriert")
  ns.Store.Setting("guild.sightings", true)
  hear(ns.Guild.Proto.EncodeSight("Grimm-Bart", "Dämmerwald", time()))
  hear(ns.Guild.Proto.EncodeSight("Unbe-Kannt", "Dämmerwald", time()))
  local s = M.Fired("GUILD_SIGHTING")
  eq(#s, 1); eq(s[1][2], "Grimm-Bart"); eq(s[1][3], "Dämmerwald"); eq(s[1][4], "Kollege")
  no(ns.Guild.Get("Unbe-Kannt"), "Sichtung legt keinen Feind an")
  -- my own sighting is sent once per 2 minutes
  M.AddEnemy("target", { name = "Grimm", surname = "Bart" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.Advance(6); M.FireEvent("PLAYER_TARGET_CHANGED")
  M.Advance(1)
  local n = 0
  for _, m in ipairs(M.addonSent) do if m.text:find("^1\tS\t") then n = n + 1 end end
  eq(n, 1)
end)

test("Liste, Rang, Count, Adopt", function()
  local ns = loadGuild()
  hear(killMsg(ns, { key = "Eins-A", t = time() - 100, victim = "Kollege V1" }))
  hear(killMsg(ns, { key = "Eins-A", t = time() - 90, victim = "Kollege V2" }))
  hear(killMsg(ns, { key = "Zwei-B", t = time() - 10, victim = "Kollege V1" }))
  hear(killMsg(ns, { key = "Drei-C", t = time() - 50, victim = "Kollege V3" }))
  local r = ns.Guild.List("rank")
  eq(r[1].key, "Eins-A"); eq(r[2].key, "Zwei-B"); eq(r[3].key, "Drei-C")
  eq(ns.Guild.List("recent")[1].key, "Zwei-B")
  eq(ns.Guild.List("name")[1].key, "Drei-C")
  eq(ns.Guild.Rank("Eins-A"), 1); eq(ns.Guild.Rank("Drei-C"), 3); eq(ns.Guild.Rank("Nix-Da"), nil)
  local f, d = ns.Guild.Count(); eq(f, 3); eq(d, 4)
  local e = ns.Guild.Get("Eins-A")
  eq(e.kills, 2); eq(e.victimCount, 2); eq(e.lastVictim, "Kollege V2"); eq(e.lastZone, "Arathihochland")
  eq(e.class, "ROGUE"); eq(e.level, 44); eq(e.deeds[1].victim, "Kollege V2"); no(e.mine)
  local key = ns.Guild.Adopt("Eins-A")
  eq(key, "Eins-A")
  local own = ns.Store.Get(key)
  -- fix-2 (Fund 14): gespeichert wird ein Merker, der Satz entsteht beim Anzeigen in der aktiven Sprache
  ok(own and own.manual); eq(own.class, "ROGUE"); eq(own.note, ""); eq(own.fromGuildKills, 2)
  ok(ns.Util.NoteOf(own):find("Gilden"), ns.Util.NoteOf(own))
  ok(ns.Guild.Get("Eins-A").mine)
  ok(ns.Guild.List("rank")[1].mine, "Cache nach Übernahme erneuert")
  eq(ns.Guild.Get("Eins-A").kills, 2, "Gildenliste unverändert")
  eq(ns.Store.Get(key).kills, 0, "eigene Liste zählt keine fremden Taten")
end)

test("Migration: alte DB ohne Gildenblock wird sauber ergänzt", function()
  local old = { version = 1, settings = { alert = { enabled = false, cooldown = 30 }, ui = { scale = 1.2 } },
    enemies = { ["Alt-Feind"] = { key = "Alt-Feind", name = "Alt", realm = "Feind", kills = 2, status = "wanted",
      deaths = { { t = time() - 100, sure = true, me = "Varorak Narenmar", zone = "Z" } } } }, deaths = {} }
  local ns = loadGuild({ db = old })
  local s = _G.DeathNoteDB.settings
  eq(s.alert.enabled, false); eq(s.alert.cooldown, 30); eq(s.ui.scale, 1.2)
  eq(s.guild.share, true); eq(s.guild.receive, true); eq(s.guild.alert, true); eq(s.guild.announce, true)
  eq(s.guild.sightings, false); eq(s.guild.minKills, 1)
  local g = _G.DeathNoteDB.guild
  ok(type(g) == "table"); eq(g.name, "Die Wurstbrüder")
  eq(ns.Guild.Get("Alt-Feind").kills, 1, "eigene Kills in die Gildenliste übernommen")
  -- broken guild blocks are repaired
  local broken = { settings = { guild = { share = false } }, guild = { name = "Die Wurstbrüder", enemies = {
    ["kaputt"] = { deeds = {} }, ["Gut-Feind"] = { deeds = { { t = time() - 10, victim = "X" }, "müll",
      { t = time() - 400 * 86400, victim = "uralt" } } }, ["Leer-Feind"] = { deeds = {} } }, members = { [1] = 2 } } }
  ns = loadGuild({ db = broken })
  eq(_G.DeathNoteDB.settings.guild.share, false, "Einstellung bleibt")
  eq(_G.DeathNoteDB.settings.guild.receive, true)
  local f = ns.Guild.Count(); eq(f, 1)
  eq(ns.Guild.Get("Gut-Feind").kills, 1)
  eq(#ns.Guild.Members(), 0)
  -- a list without a valid guild name cannot be trusted to be ours: dropped
  ns = loadGuild({ db = { guild = { name = 5, enemies = { ["Gut-Feind"] = { deeds = { { t = time() - 10, victim = "X" } } } } } } })
  eq(ns.Guild.Count(), 0)
  ns = loadGuild({ db = { guild = "Unsinn" } })
  eq(type(_G.DeathNoteDB.guild), "table")
  eq(#M.errors, 0)
  no(M.ContainsSecret(_G.DeathNoteDB))
end)

test("since: Überlappung, mindestens 3 Tage, höchstens 180 Tage", function()
  local ns = loadGuild()
  local P, C = ns.Guild.Proto, ns.Guild.C
  local t = 2000000000
  eq(P.Since(t, nil, false), t - C.MAX_AGE)
  eq(P.Since(t, t - 100, true), t - C.MAX_AGE)
  eq(P.Since(t, t - 100, false), t - C.LOOKBACK)
  eq(P.Since(t, t - 10 * 86400, false), t - 10 * 86400 - C.SINCE_OVERLAP)
  eq(P.Since(t, t - 900 * 86400, false), t - C.MAX_AGE)
end)

test("/dn gilde und /dn sync, Probe", function()
  local ns = loadGuild()
  hear("1\tH\t0\t1.2.0", "Kollege-Forever")
  hear(killMsg(ns, { t = time() - 30 }))
  _G.SlashCmdList.DEATHNOTE("gilde")
  local txt = table.concat(M.chat, "\n")
  ok(txt:find("Die Wurstbrüder"), "Gildenname")
  ok(txt:find("1 Täter (0 nur von Hand eingetragen), 1 Tat;", 1, true), "Zahlen")   -- fix-2: "; bei {foreign} davon ..."
  ok(txt:find("Kollege 1.2.0", 1, true), "Mitglied mit Version")
  _G.SlashCmdList.DEATHNOTE("sync")
  ok(M.chat[#M.chat]:find("Abgleich angefragt"))
  _G.SlashCmdList.DEATHNOTE("sync")
  ok(M.chat[#M.chat]:find("Nochmal in"))
  _G.SlashCmdList.DEATHNOTE("probe")
  local p = _G.DeathNoteDB.probe.guild
  ok(p); eq(p.canRegister, true); eq(p.canSend, true); eq(p.prefixOK, true); eq(p.inGuild, true)
  ok(M.prefixes.DeathNote, "Präfix registriert")
  eq(_G.DeathNoteDB.probe.apis["C_ChatInfo.SendAddonMessage"], true)
  M.Advance(1)
  eq(p.queue >= 0, true)
end)

M.done("test_sync")
