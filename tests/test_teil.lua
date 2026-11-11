-- Sharing paths under the conditions seen live on 11.11.2026 (Forever PvP realm):
-- realm flags outgoing addon messages as restricted, senders arrive as "Name-Realm", the death
-- recap names sources in full ("Brenensil Mage") while GetPlayerInfoByGUID knows the first name only.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local GUILD = "Die Fachkräfte"
local REALM = "CAMWOWEU5Realm2PvP"

local FORMS = {
  realm     = function(c) return c.name .. "-" .. REALM end,
  bare      = function(c) return c.name end,
  full      = function(c) return c.name .. " " .. c.surname end,
  fullrealm = function(c) return c.name .. " " .. c.surname .. "-" .. REALM end,
  dashsur   = function(c) return c.name .. "-" .. c.surname end,
}

-- a world whose clients see the real realm, the restricted flag and a chosen sender form
local function world(form)
  M.Reset()
  local W = M.NewWorld()
  local mk = W.client
  function W.client(name, surname, guild, opts)
    local c = mk(name, surname, guild, opts)
    local env = c.env
    env.GetNormalizedRealmName = function() return REALM end
    env.Ambiguate = function(n)
      local a, r = n:match("^(.-)%-(.+)$")
      if a and r == REALM then return a end
      return n
    end
    local send = env.C_ChatInfo.SendAddonMessage
    env.C_ChatInfo.AreOutgoingAddonChatMessagesRestricted = function() return true end
    env.C_ChatInfo.InChatMessagingLockdown = function() return false end
    env.C_ChatInfo.SendAddonMessage = function(prefix, text, channel)
      c.tried = (c.tried or 0) + 1
      if c.sendFn then return c.sendFn() end
      local r = send(prefix, text, channel)
      local m = W.wire[#W.wire]
      if m and m.text == text then m.from = FORMS[form or "realm"](c) end
      return r
    end
    return c
  end
  return W
end

local function kill(c, name, surname)
  local key = c.ns.Store.ApplyKill({ name = name, surname = surname, class = "MAGE", level = 36 },
    { t = time(), zone = "Schlingendorntal", me = c.name .. " " .. c.surname, myLevel = 34, source = "recap", others = {} }, true)
  c.ns:Fire("DEATH_RECORDED", { t = time(), zone = "Schlingendorntal", me = c.name .. " " .. c.surname, kind = "pvp",
    sure = true, counted = true, killerKey = key, source = "recap" }, key)
  return key
end

local function hasMember(G, first)
  for _, m in ipairs(G.Members()) do if m.name:match("^" .. first) then return true end end
  return false
end

test("Realm meldet 'ausgehende Addon-Nachrichten eingeschränkt': es wird trotzdem gesendet", function()
  local W = world("realm")
  local a = W.client("Varorak", "Narenmar", GUILD)
  a.login(); W.run(40)
  ok((a.tried or 0) >= 1, "Sendeversuch")
  ok(a.ns.Guild.stats.sent >= 1, "als gesendet gezählt")
  no(a.ns.Guild.HoldReason(), "kein Wartegrund")
  eq(a.ns.Guild.stats.realmRestricted, true, "für die Sonde gemerkt")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

for _, form in ipairs({ "realm", "bare", "full", "fullrealm", "dashsur" }) do
  test("Absenderform '" .. form .. "': Taten kommen an, jeder sieht den anderen, niemand sich selbst", function()
    local W = world(form)
    local a = W.client("Varorak", "Narenmar", GUILD)
    local b = W.client("Moppel", "Mogsen", GUILD)
    a.login(); b.login(); W.run(40)
    kill(a, "Brenensil", "Mage")
    W.run(3)
    local e = b.ns.Guild.Get("Brenensil-Mage")
    ok(e, "Tat von A bei B"); eq(e and e.kills, 1)
    ok(hasMember(b.ns.Guild, "Varorak"), "B sieht A"); ok(hasMember(a.ns.Guild, "Moppel"), "A sieht B")
    no(hasMember(a.ns.Guild, "Varorak"), "A sieht sich nicht selbst")
    no(hasMember(b.ns.Guild, "Moppel"), "B sieht sich nicht selbst")
    -- later login gets the kill through the hello answer
    local c = W.client("Hühnerbein", "Knack", GUILD)
    c.login(); W.run(60)
    ok(c.ns.Guild.Get("Brenensil-Mage"), "C bekommt die Tat über die Antwort")
    eq(#M.errors, 0, tostring(M.errors[1]))
  end)
end

test("Eigenes Echo: Vorname muss passen, ein genannter Nachname auch", function()
  local W = world("realm")
  local a = W.client("Varorak", "Narenmar", GUILD)
  a.login(); W.run(1)
  local isMe = a.ns.Guild.IsMe
  ok(isMe("Varorak")); ok(isMe("Varorak Narenmar"))
  no(isMe("Varorak Anders"), "anderer Nachname ist ein anderer Spieler")
  no(isMe("Moppel")); no(isMe("Moppel Narenmar")); no(isMe(nil))
end)

test("Rückgabewerte von SendAddonMessage: Sperre wird erneut versucht, Drossel klopft nicht im 1,5-s-Takt", function()
  local P
  do local W = world(); local a = W.client("A", "B", GUILD); P = a.ns.Guild.Proto end
  eq(P.SendOutcome(true, 11, 0, 3, 8, 9, 11), "retry", "AddOnMessageLockdown")
  eq(P.SendOutcome(true, 11, 0, 3, 8, 9), "drop", "ohne Enum wie bisher")
  eq(P.SendOutcome(true, 10, 0, 3, 8, 9, 11), "drop", "NotInGuild")
  eq(P.SendOutcome(true, 0, 0, 3, 8, 9, 11), "ok")
  local W = world()
  local a = W.client("Varorak", "Narenmar", GUILD)
  a.sendFn = function() return 3 end
  a.login(); W.run(1200)
  ok(a.tried < 40, "gedrosselt: " .. tostring(a.tried) .. " Versuche in 20 min")
  eq(a.ns.Guild.QueueSize(), 0, "Schlange läuft nicht voll")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Guild.Health sagt klar, wenn nichts geteilt wird", function()
  local function health(fn, guild)
    local W = world()
    local a = W.client("Varorak", "Narenmar", guild)
    a.sendFn = fn
    a.login(); W.run(120)
    return a.ns.Guild.Health(), a
  end
  local h = health(nil, GUILD)
  eq(h.ok, true); eq(h.reason, "quiet"); ok(h.text:find("Gesendet"))
  h = health(function() return 11 end, GUILD)
  eq(h.ok, false); eq(h.reason, "blocked"); ok(h.detail:find("11", 1, true), "nennt den Rückgabewert (nur im Detail)")
  no(h.text:find("11", 1, true), "Satz für Spieler ohne Technik")
  h = health(function() return 10 end, GUILD)
  eq(h.ok, false); eq(h.reason, "blocked", "endgültige Ablehnung zählt sofort")
  h = health(function() return false end, GUILD)
  eq(h.ok, false)
  h = health(nil, nil)
  eq(h.ok, false); eq(h.reason, "noguild")
  local _, a = health(nil, GUILD)
  a.ns.Store.Setting("guild.share", false)
  eq(a.ns.Guild.Health().reason, "off")
  -- two clients talking: plain ok
  local W = world()
  local x = W.client("Varorak", "Narenmar", GUILD); local y = W.client("Moppel", "Mogsen", GUILD)
  x.login(); y.login(); W.run(60)
  eq(x.ns.Guild.Health().reason, "ok")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Buch einlesen verträgt Chat-Programme (Code-Zaun, Text davor, CRLF) und meldet Abgeschnittenes klar", function()
  local ns = M.Load()
  ns.Store.ApplyKill({ name = "Yoron", surname = "Pvp", class = "PALADIN", level = 35 },
    { t = time(), zone = "Schlingendorntal", me = "Varorak Narenmar", source = "recap", others = {} }, true)
  ns.Store.AddManual("Ölmühl", "Überfäll")
  local text = ns.Store.Export()
  local function import(t)
    local n2 = M.Load()
    local okI, a = n2.Store.Import(t)
    return okI, a, n2
  end
  for label, t in pairs({
    zaun = "```\n" .. text .. "\n```", zaunText = "```text\r\n" .. text:gsub("\n", "\r\n") .. "\r\n```",
    davor = "hier meine liste:\n" .. text, leer = "\n\n  " .. text .. "  \n\n" }) do
    local okI, a, n2 = import(t)
    eq(okI, true, label .. ": " .. tostring(a)); eq(a, 2, label)
    ok(n2.Store.Get("Yoron-Pvp") and n2.Store.Get("Ölmühl-Überfäll"), label)
  end
  local okI, why = import(text:sub(1, #text - 20))
  eq(okI, false); ok(why:find("abgeschnitten"), why)
  okI, why = import((text:gsub("^[^\n]*\n", "")))
  eq(okI, false); ok(why:find("erste Zeile"), why)
  okI, why = import("hallo moppel")
  eq(okI, false)
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Einen bloßen Verdächtigen von Hand eintragen setzt ihn ins Buch und teilt ihn", function()
  local W = world()
  local a = W.client("Varorak", "Narenmar", GUILD)
  local b = W.client("Moppel", "Mogsen", GUILD)
  a.login(); b.login(); W.run(40)
  local key = a.ns.Store.ApplyKill({ name = "Brenendan", surname = "Forever", class = "ROGUE" },
    { t = time(), zone = "Z", me = "Varorak Narenmar", source = "suspect", others = {} }, false)
  eq(a.ns.Store.Get(key).status, "suspect")
  W.run(2)
  no(b.ns.Guild.Get(key), "Verdacht wird nicht geteilt")
  eq(a.ns.Store.AddManual("Brenendan", "Forever"), key)
  local e = a.ns.Store.Get(key)
  eq(e.status, "wanted"); eq(e.manual, true); eq(e.by, "Varorak Narenmar")
  W.run(2)
  local g = b.ns.Guild.Get(key)
  ok(g and g.listedBy and g.listedBy["Varorak Narenmar"], "jetzt bei B als Hand-Eintrag")
  -- a second AddManual changes nothing and sends nothing
  local n = #W.sent
  a.ns.Store.AddManual("Brenendan", "Forever"); W.run(2)
  eq(#W.sent, n)
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Recap nennt den vollen Namen, die GUID-Auskunft nur den Vornamen: der Nachname kommt aus dem Recap", function()
  local ns = M.Load()
  -- the player is known to the client by GUID (first name only), never seen by the tracker
  M.units.someone = { guid = "Player-6842-00672E27", name = "Brenensil", class = "MAGE", classLoc = "Magierin",
    race = "Skyborne", raceLoc = "Himmelsgeborene" }
  M.recap = { id = 47, events = {
    { sourceGUID = "Player-6842-00672E27", sourceName = "Brenensil Mage", amount = 385, overkill = 40,
      timestamp = time() - 0.5, spellName = "Arkanschlag", hideCaster = false },
    { sourceGUID = "Player-6948-00DDFA0A", sourceName = "Yoron Pvp", amount = 145, overkill = -1,
      timestamp = time() - 2, hideCaster = false },
  } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(6)
  local j = ns.Store.Deaths()[1]
  eq(j.killerKey, "Brenensil-Mage"); eq(j.killerName, "Brenensil Mage"); eq(j.sure, true)
  local e = ns.Store.Get("Brenensil-Mage")
  ok(e, "Eintrag unter dem vollen Schlüssel"); eq(e.surname, "Mage"); eq(e.display, "Brenensil Mage")
  eq(ns.Util.TargetName(e), "Brenensil Mage")
  eq(j.candidateInfo["Brenensil-Mage"].name, "Brenensil"); eq(j.candidateInfo["Brenensil-Mage"].surname, "Mage")
  ok(ns.Store.Get("Yoron-Pvp"), "Mittäter mit vollem Namen")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

M.done("test_teil")
