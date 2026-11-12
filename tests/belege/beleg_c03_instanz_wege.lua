-- 1.2.1 after the hunt (M3, N1, N7): in a dungeon a refusal holds only its own route (guild, whisper to
-- a friend, Battle.net to a friend); the probe reports the refusal; a chat lock that ends without an event
-- does not hold the queue forever.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M
local G = "Die Testgilde"
local function inst(c, kind) c.env.IsInInstance = function() if kind then return true, kind end return false, "none" end; c.fire("PLAYER_ENTERING_WORLD") end

H.lauf("(1) Dungeon: ein abgelehntes Fluestern haelt nur das Fluestern an diesen Freund", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei", "Gerd Gut" }, fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local g = W.client("Gerd", "Gut", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); g.login(); W.run(120)
  inst(a, "party"); W.run(5)
  local send = a.env.C_ChatInfo.SendAddonMessage
  a.env.C_ChatInfo.SendAddonMessage = function(p, text, ch, target)
    if ch == "WHISPER" and tostring(target):find("^Fritz") then return 5 end
    return send(p, text, ch, target)
  end
  H.tod(a, "Taeter", "Lamm"); W.run(5)
  a.ns.Guild.Release("Ziel-Eins", { to = "all", why = "x" }); W.run(5)
  a.ns.Guild.Release("Ziel-Zwei", { to = "guild", why = "x" }); W.run(60)
  H.erwartet("die Kollegin bekommt im Dungeon alles ueber GUILD", b.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil
    and b.ns.Guild.Hunt("Ziel-Zwei", "guild") ~= nil)
  H.erwartet("der andere Freund bekommt sein Fluestern", g.ns.Guild.Hunt("Ziel-Eins", "friends") ~= nil)
  -- two messages went to Fritz (the deed K and the call J): exactly those wait
  H.erwartet("es wartet nur das Fluestern an Fritz", a.ns.Guild.QueueSize() == 2, a.ns.Guild.QueueSize())
  local s = a.env.DeathNoteDB.probe and a.env.DeathNoteDB.probe.guild and a.env.DeathNoteDB.probe.guild.instanceSend
  H.erwartet("Sonde: die Ablehnung steht drin (Weg Fluestern)", s and s.result == "refused" and s.channel == "WHISPER",
    s and (tostring(s.result) .. "/" .. tostring(s.channel)))
  H.erwartet("Gildenstatus wartet nicht", a.ns.Guild.HoldReason() == nil, a.ns.Guild.HoldReason())
  a.env.C_ChatInfo.SendAddonMessage = send
  inst(a, nil); W.run(60)
  H.erwartet("nach dem Verlassen kommt es bei Fritz an", f.ns.Guild.Hunt("Ziel-Eins", "friends") ~= nil)
  H.erwartet("Schlange leer", a.ns.Guild.QueueSize() == 0, a.ns.Guild.QueueSize())
end)

H.lauf("(2) Dungeon: GUILD abgelehnt: wartet bis zum Zonenwechsel, Status sagt es, nichts geht verloren", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(120)
  inst(a, "party"); W.run(5)
  a.sendResult = 11
  a.ns.Guild.Release("Ziel-Eins", { to = "guild", why = "x" }); W.run(5)
  a.ns.Guild.Release("Ziel-Zwei", { to = "guild", why = "x" }); W.run(30 * 60)
  H.erwartet("Status: wartet auf die Instanz", a.ns.Guild.HoldReason() == "instance", a.ns.Guild.HoldReason())
  H.erwartet("nichts verworfen", a.ns.Guild.stats.dropped == 0 and a.ns.Guild.QueueSize() == 2, a.ns.Guild.QueueSize())
  a.sendResult = nil
  inst(a, nil); W.run(60)
  H.erwartet("danach kommt alles an", b.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil and b.ns.Guild.Hunt("Ziel-Zwei", "guild") ~= nil)
end)

H.lauf("(3) N1: Chat-Sperre 25 Minuten, endet ohne Ereignis: die Schlange geht trotzdem raus", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(120)
  local sperre = true
  a.env.C_ChatInfo.InChatMessagingLockdown = function() return sperre end
  a.ns.Guild.Release("Ziel-Eins", { to = "guild", why = "x" })
  W.run(25 * 60)
  sperre = false
  W.run(5 * 60)
  H.erwartet("5 Minuten nach dem Ende der Sperre ist die Freigabe drueben", b.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil)
end)

H.lauf("(4) N7 (hingenommen): nach 30 Minuten Schlachtfeld geht nichts verloren; was der Live-Deckel drueben haelt, bringt die naechste Antwort", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(120)
  inst(a, "pvp"); W.run(5)
  for i = 1, 10 do a.ns.Guild.Release("Ziel" .. string.char(96 + i) .. "-Lamm", { to = "guild", why = "x" }) end
  W.run(30 * 60)
  H.erwartet("nichts verworfen", a.ns.Guild.stats.dropped == 0)
  inst(a, nil); W.run(120)
  local n = 0
  for i = 1, 10 do if b.ns.Guild.Hunt("Ziel" .. string.char(96 + i) .. "-Lamm", "guild") then n = n + 1 end end
  H.erwartet("live mindestens der Deckel (5)", n >= 5, n)
  b.ns.Guild.SyncNow(); W.run(200)
  n = 0
  for i = 1, 10 do if b.ns.Guild.Hunt("Ziel" .. string.char(96 + i) .. "-Lamm", "guild") then n = n + 1 end end
  H.erwartet("mit der naechsten Antwort alle 10", n == 10, n)
end)
H.fertig()
