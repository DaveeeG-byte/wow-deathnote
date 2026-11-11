-- 1.2.1: im Dungeon senden statt pauschal warten. Aufruf: luajit beleg_b04_instanz.lua <Projektkopie>
-- Dungeon/Schlachtzug: gesendet wird wie draussen; lehnt der Client ab, wartet die Schlange fuer diese Instanz (kein
-- Dauerversuch, nichts geht verloren, nichts altert) und geht beim Zonenwechsel weiter. Schlachtfeld, Arena, Kampf und
-- Chat-Sperre: warten. Empfang in Instanzen geht. Die Sonde merkt den ersten Versuch (probe.guild.instanceSend).
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

local function laden()
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde X" end })
  M.Advance(90)                      -- Hallo beim Login und die Sperre von /dn sync sind durch
  M.addonSent = {}
  return ns
end
local function zonenwechsel(kind)
  M.instance = kind and { true, kind } or { false, "none" }
  M.FireEvent("PLAYER_ENTERING_WORLD")
end
local function versuche(f)
  local n = 0
  M.sendResult = function(text) n = n + 1; return f and f(text) or 0 end
  return function() return n end
end

H.lauf("(1) Dungeon ausserhalb des Kampfes: senden wie draussen, Sonde merkt den ersten Versuch", function()
  local ns = laden()
  zonenwechsel("party")
  local P = ns.Guild.Proto
  ns.Guild.SyncNow()
  M.Advance(2)
  H.erwartet("das Hallo ging im Dungeon hinaus", #M.addonSent == 1, #M.addonSent)
  H.erwartet("kein Wartegrund", ns.Guild.HoldReason() == nil, ns.Guild.HoldReason())
  local pg = _G.DeathNoteDB.probe and _G.DeathNoteDB.probe.guild and _G.DeathNoteDB.probe.guild.instanceSend
  H.erwartet("Sonde: erster Versuch im Dungeon ok", pg and pg.kind == "party" and pg.result == "ok", pg and pg.result)
  -- Empfang im Dungeon
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40,
    zone = "Z", t = time() - 30, victim = "Kollege Wurst" }, "K"), "GUILD", "Kollege Wurst-Forever")
  H.erwartet("Empfang im Dungeon", ns.Guild.Get("Grimm-Bart") ~= nil)
  ns.Probe.Run(false)
  H.erwartet("/dn probe uebernimmt den Vermerk", _G.DeathNoteDB.probe.guild.instanceSend ~= nil)
end)

H.lauf("(2) der Client lehnt im Dungeon ab: einmal versucht, nichts verloren, weiter nach dem Verlassen", function()
  local ns = laden()
  zonenwechsel("party")
  local zahl = versuche(function() return 11 end)        -- AddOnMessageLockdown
  ns.Guild.SyncNow()
  for i = 1, 5 do ns.Store.ApplyKill({ name = "Taeter" .. string.char(96 + i), surname = "Lamm" },
    { t = time() - i, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
    ns:Fire("DEATH_RECORDED", { t = time() - i, zone = "Z", me = "Varorak Narenmar", kind = "pvp", sure = true, counted = true,
      killerKey = "Taeter" .. string.char(96 + i) .. "-Lamm" }, "Taeter" .. string.char(96 + i) .. "-Lamm") end
  local q = ns.Guild.QueueSize()
  M.Advance(40 * 60)                                       -- 40 Minuten im Dungeon
  H.erwartet("genau ein Versuch in der Instanz", zahl() == 1, zahl())
  H.erwartet("die Schlange haelt alles", ns.Guild.QueueSize() == q and q >= 2, ns.Guild.QueueSize() .. "/" .. q)
  H.erwartet("Wartegrund: Instanz", ns.Guild.HoldReason() == "instance")
  local h = ns.Guild.Health()
  H.erwartet("Statuszeile sagt es (warten, kein Fehler)", h.ok and h.reason == "hold", h.reason)
  local pg = _G.DeathNoteDB.probe.guild.instanceSend
  H.erwartet("Sonde: abgelehnt mit Kennzahl", pg and pg.result == "refused" and pg.code == "11", pg and pg.code)
  H.erwartet("kein Fehlschlag gezaehlt (der Zustand der Gilde bleibt gut)", (ns.Guild.stats.failStreak or 0) == 0 and not ns.Guild.stats.hardFail)
  -- noch ein Ereignis im Dungeon (Kampfende): kein neuer Versuch
  M.FireEvent("PLAYER_REGEN_ENABLED")
  H.erwartet("kein Dauerversuch", zahl() == 1)
  -- raus: alles geht hinaus, nichts ist in den 40 Minuten verfallen
  zahl = versuche()
  zonenwechsel(nil)
  M.Advance(30)
  H.erwartet("nach dem Verlassen ging alles hinaus", zahl() == q and ns.Guild.QueueSize() == 0, zahl() .. "/" .. q)
  H.erwartet("nichts verworfen", ns.Guild.stats.dropped == 0, ns.Guild.stats.dropped)
  -- naechster Dungeon: neuer Versuch
  zahl = versuche()
  zonenwechsel("raid")
  ns.Guild.SyncNow(); M.Advance(65); ns.Guild.SyncNow(); M.Advance(2)
  H.erwartet("neue Instanz: neuer Versuch, geht", zahl() >= 1)
end)

H.lauf("(3) Schlachtfeld und Arena warten ohne Versuch; Antworten warten mit, die Schlange laeuft nicht voll", function()
  for _, kind in ipairs({ "pvp", "arena" }) do
    local ns = laden()
    local P = ns.Guild.Proto
    for i = 1, 30 do ns.Store.ApplyKill({ name = "Feind" .. i, surname = "Lamm" },
      { t = time() - 100 - i, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true) end
    zonenwechsel(kind)
    local zahl = versuche()
    for i = 1, 12 do
      M.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(time() - 86400 * 30, "1.2.1"), "GUILD", "Kerl" .. i .. " Wurst-Forever")
      M.Advance(20)
    end
    M.Advance(25 * 60)
    H.erwartet(kind .. ": kein Versuch", zahl() == 0, zahl())
    H.erwartet(kind .. ": Antworten warten (Schlange klein)", ns.Guild.QueueSize() <= 2, ns.Guild.QueueSize())
    zonenwechsel(nil)
    M.Advance(60)
    H.erwartet(kind .. ": nach dem Verlassen eine Antwort mit den Taten", zahl() >= 30, zahl())
  end
end)

H.lauf("(4) im Kampf und bei Chat-Sperre warten, auch im Dungeon", function()
  local ns = laden()
  zonenwechsel("party")
  local zahl = versuche()
  M.inCombat = true
  ns.Guild.SyncNow(); M.Advance(5)
  H.erwartet("Kampf: kein Versuch", zahl() == 0 and ns.Guild.HoldReason() == "combat")
  M.inCombat = false
  M.chatLockdown = true
  M.FireEvent("PLAYER_REGEN_ENABLED"); M.Advance(5)
  H.erwartet("Chat-Sperre: kein Versuch", zahl() == 0 and ns.Guild.HoldReason() == "lockdown")
  M.chatLockdown = false
  M.Advance(31)
  H.erwartet("danach: gesendet", zahl() == 1, zahl())
end)

H.lauf("(5) Freunde im Dungeon: eine Ablehnung zaehlt nicht gegen den Freund", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  M.instance = { true, "party" }
  a.fire("PLAYER_ENTERING_WORLD")
  a.whisperResult = 11
  local key = H.tod(a, "Taeter", "Lamm"); W.run(30)
  H.erwartet("Freundin nicht ausgesetzt, Fluestern nicht gesperrt", not a.ns.Friends.Suspended("Berta Senf") and not a.ns.Friends.Blocked())
  a.whisperResult = nil
  M.instance = { false, "none" }
  a.fire("PLAYER_ENTERING_WORLD"); W.run(30)
  H.erwartet("nach dem Verlassen kommt die Tat bei der Freundin an", b.ns.Guild.Get(key, "friends") ~= nil)
end)

H.fertig()
