-- 1.6.0 call: sightings over layers (message T on prefix DeathNote, Call.lua). Sent for killers of me or a mate (30
-- days), hit list and bounty targets; once per enemy per 120 s after 2 to 6 s, quiet when a T for him came meanwhile;
-- received only for enemies of the own, the guild's or the friends' book; a quiet line once per enemy per 5 minutes,
-- "other layer" when both layer marks differ. Mixed use: 1.5.0 drops T and the prefix DeathNoteSOS without harm.
-- Call: luajit tests/test_ca160_sichtung.lua [<project copy>]  (a copy for the red probe)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"
local WATCH = { "GUILD_KILL", "GUILD_UPDATED", "HELP_CALL", "SIGHTING", "GUILD_SIGHTING" }

local function GMI(id)
  if id == 1434 then return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
end
local function welt()
  local W = H.welt(WATCH)
  _G.C_Map.GetMapInfo = GMI
  return W
end
local function ofType(W, kind, prefix)
  local out = {}
  for _, m in ipairs(W.sent) do
    if (prefix or "DeathNote") == m.prefix and m.text:find("^1\t" .. kind .. "\t") then out[#out + 1] = m end
  end
  return out
end
local function chatHas(s)
  for i = #M.chat, 1, -1 do if M.chat[i]:find(s, 1, true) then return M.chat[i] end end
end
local function sightLines(c) return (c.env.DeathNoteDB.probe and c.env.DeathNoteDB.probe.call.counts.sightLine) or 0 end
local function sieht(c, key) c.ns.Guild.OnUnit(key, "nameplate1", "plate", c.ns.Store.Get(key)) end

local function paar(opts)
  local W = welt()
  local a = W.client("Anton", "Wurst", G, opts)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  return W, a, b
end

H.lauf("Leitung T: Sync liest sie, eine kaputte Layer-Kennung kostet nur die Kennung", function()
  local ns = M.Load()
  local P, t = ns.Guild.Proto, time()
  local text = ns.Call.EncodeSight("Grimm-Bart", 1434, 41.23, 56.78, t, "3110-0-47")
  local m = P.Decode(text, t)
  H.erwartet("T mit Ort und Kennung", m and m.kind == "T" and m.key == "Grimm-Bart" and m.mapID == 1434 and m.px == 412
    and m.py == 568 and m.shard == "3110-0-47", text)
  local m2 = P.Decode(ns.Call.EncodeSight("Grimm-Bart", 1434, 1, 1, t, nil), t)
  H.erwartet("ohne Kennung", m2 and m2.shard == nil)
  local m3 = P.Decode("1\tT\tGrimm-Bart\t1434\t1\t1\t" .. t .. "\tKAPUTT|x", t)
  H.erwartet("kaputte Kennung: Sichtung bleibt, Kennung nicht", m3 and m3.shard == nil)
  H.erwartet("Ort kaputt: weg", P.Decode("1\tT\tGrimm-Bart\t0\t1\t1\t" .. t .. "\t", t) == nil)
  H.erwartet("ein Feld zu wenig: weg", P.Decode("1\tT\tGrimm-Bart\t1434\t1\t1\t" .. t, t) == nil)
  H.erwartet("Layer aus einer Kreatur-GUID", ns.Call.ShardOf("Creature-0-3110-0-47-1234-0000ABCDEF") == "3110-0-47"
    and ns.Call.ShardOf("Player-1-0000AAAA") == nil and ns.Call.ShardOf(M.Secret("g")) == nil)
end)

H.lauf("Mein Moerder gesehen: T nach 2 bis 6 s an die Gilde, leise Zeile mit Ort, lastSeen, Nadel", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  H.erwartet("Vorbedingung: Berta kennt Grimm aus der Gilde", b.ns.Guild.Get(key, "guild") ~= nil)
  sieht(a, key)
  W.run(1.9)
  H.erwartet("vor 2 s noch nichts", #ofType(W, "T") == 0)
  W.run(4.2)
  local ts = ofType(W, "T")
  H.erwartet("eine T an die Gilde", #ts == 1 and ts[1].channel == "GUILD", #ts)
  -- fixer 1.6.0 (ju05): one switch; the old S goes along for clients up to 1.5.0 (only for the enemies of a T)
  H.erwartet("das alte S fuer Clients bis 1.5.0 dazu", #ofType(W, "S") == 1, #ofType(W, "S"))
  H.erwartet("Berta: Ereignis SIGHTING", H.zaehle(b, "SIGHTING") == 1, H.zaehle(b, "SIGHTING"))
  local line = chatHas("Grimm Bart gesehen von Anton")
  H.erwartet("leise Zeile mit Zone und Karte", line and line:find("Schlingendorntal, gerade eben.", 1, true)
    and line:find("call:map:", 1, true), line)
  local ls = b.ns.Guild.Get(key, "guild").lastSeen
  H.erwartet("lastSeen mit Ort und Absender", ls and ls.zone == "Schlingendorntal" and ls.by == "Anton", ls and ls.zone)
  local sc = {}
  b.ns.Call.Scenes(sc, time())
  H.erwartet("eine Nadel 'sight' auf der Karte", #sc == 1 and sc[1].kind == "sight" and sc[1].spot == true and sc[1].fresh == nil)
  W.run(601)
  sc = {}
  b.ns.Call.Scenes(sc, time())
  H.erwartet("nach 10 Minuten weg", #sc == 0, #sc)
  local p = a.env.DeathNoteDB.probe.call
  H.erwartet("Sonde: T an GUILD in Ruhe, Code 0", p.codes["T.calm"] and p.codes["T.calm"].GUILD["0"] == 1)
end)

H.lauf("Hoechstens eine T je Feind je 120 s, eine Zeile je Feind je 5 Minuten", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  sieht(a, key); W.run(7)
  sieht(a, key); W.run(7)
  H.erwartet("zweimal gesehen in 14 s: eine T", #ofType(W, "T") == 1, #ofType(W, "T"))
  W.run(110)
  sieht(a, key); W.run(7)
  H.erwartet("nach 120 s die zweite", #ofType(W, "T") == 2, #ofType(W, "T"))
  H.erwartet("aber keine zweite Zeile (5 Minuten)", sightLines(b) == 1, sightLines(b))
  W.run(180)
  sieht(a, key); W.run(7)
  H.erwartet("nach 5 Minuten wieder eine Zeile", sightLines(b) == 2, sightLines(b))
end)

H.lauf("Schweigen, wenn inzwischen eine T fuer denselben Feind kam", function()
  local W, a = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  sieht(a, key)
  W.run(0.5)
  H.gilde(a, a.ns.Call.EncodeSight(key, 1434, 10, 10, time(), ""), "Carla-Forever")
  W.run(7)
  H.erwartet("Anton schweigt", #ofType(W, "T") == 0, #ofType(W, "T"))
  H.erwartet("Sonde: sightQuiet", a.env.DeathNoteDB.probe.call.counts.sightQuiet == 1)
end)

H.lauf("Wer zaehlt: 30 Tage, Abschussliste, Kopfgeld; nicht: von Hand, alt", function()
  local W, a, b = paar()
  local old = H.tod(a, "Alt", "Mord", 40 * 86400)
  a.ns.Store.AddManual("Hand", "Feind")
  W.run(5)
  sieht(a, old); sieht(a, "Hand-Feind"); W.run(7)
  H.erwartet("alter Moerder und Eintrag von Hand: keine T", #ofType(W, "T") == 0, #ofType(W, "T"))
  b.ns.Guild.Release("Opfer-Lamm", { to = "guild" }); W.run(5)
  sieht(a, "Opfer-Lamm"); W.run(7)
  H.erwartet("Ziel der Abschussliste: T", #ofType(W, "T") == 1, #ofType(W, "T"))
  local ok = a.ns.Guild.SetBounty("Gold-Fisch", 100)
  W.run(2)
  sieht(a, "Gold-Fisch"); W.run(7)
  H.erwartet("Kopfgeld: T", ok and #ofType(W, "T") == 2, #ofType(W, "T"))
  -- Berta knows Gold-Fisch only by the bounty (no book entry): no line, counted as unknown
  H.erwartet("Empfaenger ohne Eintrag: keine Zeile", chatHas("Gold Fisch gesehen") == nil)
end)

H.lauf("Im Kampf geht die T trotzdem, Code getrennt nach Kampf", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  a.combat = true
  sieht(a, key); W.run(7)
  H.erwartet("T im Kampf auf der Leitung", #ofType(W, "T") == 1)
  H.erwartet("Berta hat sie", H.zaehle(b, "SIGHTING") == 1)
  local p = a.env.DeathNoteDB.probe.call
  H.erwartet("Sonde: T.combat", p.codes["T.combat"] and p.codes["T.combat"].GUILD["0"] == 1)
end)

H.lauf("Layer: beide Kennungen bekannt und verschieden: 'anderer Layer'", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  M.units.mouseover = { exists = true, guid = "Creature-0-3110-0-47-1234-0000ABCDEF" }
  a.ns.Call.SeeUnit("mouseover")
  M.units.mouseover = { exists = true, guid = "Creature-0-3110-0-48-1234-0000ABCDEF" }
  b.ns.Call.SeeUnit("mouseover")
  sieht(a, key); W.run(7)
  local line = chatHas("Grimm Bart gesehen von Anton")
  H.erwartet("Zeile sagt anderer Layer", line and line:find("anderer Layer", 1, true), line)
  local sc = {}
  b.ns.Call.Scenes(sc, time())
  H.erwartet("Nadel weiss es auch", sc[1] and sc[1].layer == "other")
  -- the same layer: not named
  W.run(301)
  M.units.mouseover = { exists = true, guid = "Creature-0-3110-0-47-1234-0000ABCDEF" }
  W.run(16)
  b.ns.Call.SeeUnit("mouseover")
  sieht(a, key); W.run(7)
  line = chatHas("Grimm Bart gesehen von Anton")
  H.erwartet("gleicher Layer: kein Zusatz", line and not line:find("anderer Layer", 1, true), line)
end)

H.lauf("Schalter guild.layerSight: aus = kein Senden, kein Empfang, auch kein altes S; der alte Schalter zaehlt nicht mehr", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  a.ns.Store.Setting("guild.layerSight", false)
  sieht(a, key); W.run(7)
  H.erwartet("aus: keine T", #ofType(W, "T") == 0)
  H.erwartet("aus: auch kein S", #ofType(W, "S") == 0)
  a.ns.Store.Setting("guild.layerSight", true)
  b.ns.Store.Setting("guild.layerSight", false)
  W.run(121)
  sieht(a, key); W.run(7)
  H.erwartet("an beim Sender: T", #ofType(W, "T") == 1)
  H.erwartet("aus beim Empfaenger: keine Zeile", H.zaehle(b, "SIGHTING") == 0 and sightLines(b) == 0)
  H.erwartet("an beim Sender: S dazu", #ofType(W, "S") == 1, #ofType(W, "S"))
  H.erwartet("aus beim Empfaenger: auch S nicht angewandt", b.ns.Guild.Get(key, "guild").lastSeen == nil)
  -- the old key is no longer read: switched on it changes nothing while the one switch is off
  a.ns.Store.Setting("guild.sightings", true)
  a.ns.Store.Setting("guild.layerSight", false)
  W.run(121)
  sieht(a, key); W.run(7)
  H.erwartet("alter Schalter an, neuer aus: nichts", #ofType(W, "S") == 1 and #ofType(W, "T") == 1,
    #ofType(W, "S") .. "/" .. #ofType(W, "T"))
end)

H.lauf("Ohne Gilde: eigener Moerder, T an Freunde (der Tracker-Haken haengt dafuer)", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(90)
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  H.erwartet("Haken gesetzt", a.ns.Tracker.guildHook ~= nil)
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", faction = "Alliance" })
  a.ns.Tracker.active = true
  a.ns.Tracker.OnUnit("nameplate1", "plate")
  W.run(7)
  local ts = ofType(W, "T")
  H.erwartet("T per Fluestern an Berta", #ts == 1 and ts[1].channel == "WHISPER" and ts[1].to == "Berta", #ts)
  H.erwartet("Berta zeigt sie (Freundesbuch)", H.zaehle(b, "SIGHTING") == 1 and chatHas("Grimm Bart gesehen von Anton") ~= nil)
  M.units.nameplate1 = nil
end)

-- Mixed use: the parser and the receiving path of 1.5.0 (a003532) against T and the new prefix
H.lauf("Mischbetrieb: 1.5.0 verwirft T und DeathNoteSOS still und bleibt heil", function()
  local GitBase = dofile(H.DIR .. "/tests/git_base.lua")
  local OLD, why = GitBase.Archive(H.DIR, "a003532", "Sync.lua")
  if not OLD then io.write("  uebersprungen: " .. tostring(why) .. "\n"); GitBase.Clean(); return end
  local oldFiles = {}
  for _, f in ipairs(M.Files()) do
    local h = io.open(OLD .. f)
    if h then h:close(); oldFiles[#oldFiles + 1] = f end
  end
  local W = welt()
  local a = W.client("Anton", "Wurst", G)
  local o = W.client("Olaf", "Alt", G, { dir = OLD, files = oldFiles, version = "1.5.0" })
  a.login(); o.login(); W.run(45)
  H.erwartet("1.5.0 hat kein Call.lua", o.ns.Call == nil)
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  H.erwartet("1.5.0 nimmt die Tat", o.ns.Guild.Get(key, "guild") ~= nil)
  local st = o.ns.Guild.stats
  local dropped, received = st.dropped, st.received
  sieht(a, key); W.run(7)
  H.erwartet("T ging hinaus", #ofType(W, "T") == 1)
  H.erwartet("1.5.0: T als 'type' verworfen", st.dropped == dropped + 1,
    tostring(st.dropped - dropped) .. " " .. tostring(st.lastReason))
  -- fixer 1.6.0 (ju05): the old S goes along; 1.5.0 takes it only with its own (old) switch on, else ignores it
  H.erwartet("das alte S ging dazu hinaus", #ofType(W, "S") == 1, #ofType(W, "S"))
  H.erwartet("1.5.0: lastSeen unberuehrt (alter Schalter dort aus)", o.ns.Guild.Get(key, "guild").lastSeen == nil)
  dropped, received = st.dropped, st.received
  a.ns.Call.Send(); W.run(1)
  H.erwartet("Hilferuf ging hinaus", #ofType(W, "P", "DeathNoteSOS") == 1)
  H.erwartet("1.5.0: fremder Praefix zaehlt nicht einmal als verworfen", st.dropped == dropped and st.received == received,
    st.dropped .. "/" .. st.received)
  -- the answer path still works between the two (a 1.6.0 kill reaches 1.5.0 after the new messages)
  local k2 = H.tod(a, "Velka", "Dorn")
  W.run(5)
  H.erwartet("danach noch heil: neue Tat kommt an", o.ns.Guild.Get(k2, "guild") ~= nil)
  GitBase.Clean()
end)

H.fertig()
