-- 1.6.0 wiring: a call for help (HELP_CALL) and a sighting (SIGHTING) of the call package go into the guild chronicle
-- (GuildLog.lua) with sentences of their own, the place as a link to the map, sightings of the same enemy within 10
-- minutes as one line with the count; a call of the group only from a guildmate; the ring keeps its cap; an error in the
-- chronicle never costs the call's or the sighting's line. And the own version in "who has the book" is the TOC's.
-- Several clients in one world (tests/mock_wow.lua). All names are made up.
-- Call: luajit tests/test_dr160_draht.lua [<project copy>]  (a copy for the red probe)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"
local WATCH = { "GUILD_KILL", "GUILD_UPDATED", "HELP_CALL", "SIGHTING", "GUILD_SIGHTING" }

local function GMI(id)
  if id == 1434 then return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
end
local function paar()
  local W = H.welt(WATCH)
  _G.C_Map.GetMapInfo = GMI
  local a = W.client("Anton", "Wurst", G, { version = "1.6.0" })
  local b = W.client("Berta", "Senf", G, { version = "1.6.0" })
  a.login(); b.login(); W.run(45)
  return W, a, b
end
local function ofKind(c, k)
  local out = {}
  for _, e in ipairs(c.ns.GuildLog.All("all")) do if e.k == k then out[#out + 1] = e end end
  return out
end
local function sieht(c, key) c.ns.Guild.OnUnit(key, "nameplate1", "plate", c.ns.Store.Get(key)) end

H.lauf("Hilferuf der Gilde: eine Zeile in der Chronik mit eigenem Satz und Ort als Kartenlink", function()
  local W, a, b = paar()
  local ok = a.ns.Call.Trigger()
  W.run(0.5)
  H.erwartet("Vorbedingung: gesendet und angekommen", ok == true and H.zaehle(b, "HELP_CALL") == 1, H.zaehle(b, "HELP_CALL"))
  local c = ofKind(b, "call")
  H.erwartet("eine Ruf-Zeile", #c == 1, #c)
  local e = c[1] or {}
  H.erwartet("aus der Gilde, nicht meins", e.src == "guild" and not e.mine, tostring(e.src))
  H.erwartet("Ort als Kartenlink (mapID, x, y)", e.place and e.place.mapID == 1434 and math.abs(e.place.x - 41.2) < 0.2
    and math.abs(e.place.y - 56.8) < 0.2, e.place and e.place.mapID)
  local GL = b.ns.GuildLog
  H.erwartet("Satz ohne Angreifer", GL.Sentence(e) == "Anton rief um Hilfe: Schlingendorntal", GL.Sentence(e))
  local line = GL.Line(e)
  local _, n = line:gsub("Schlingendorntal", "")
  H.erwartet("die Zone steht einmal in der Zeile", n == 1, line)
  H.erwartet("zählt für den Punkt am Reiter", GL.NewSince(time() - 60, "all") >= 1)
end)

H.lauf("Hilferuf mit Angreifer: Satz nennt ihn, Klick-Schlüssel ist der Angreifer", function()
  local ns = M.Load({ before = function() M.units.player.guild = G end })   -- fixer 2 (jb04): guild events need a guild
  local GL = ns.GuildLog
  local t = time()
  ns:Fire("HELP_CALL", { t = t, at = t, by = "Liora", from = "guild", mapID = 1434, x = 10, y = 20, key = "Grimm-Bart",
    display = "Grimm Bart", zone = "Schlingendorntal" })
  local e
  for _, x in ipairs(GL.All("all")) do if x.k == "call" then e = x end end
  H.erwartet("Zeile da", e ~= nil)
  H.erwartet("Satz mit Angreifer", e and GL.Sentence(e) == "Liora rief um Hilfe: Schlingendorntal, Angreifer Grimm Bart",
    e and GL.Sentence(e))
  H.erwartet("Schlüssel des Angreifers (Klick öffnet sein Plakat)", e and e.key == "Grimm-Bart")
  ns:Fire("HELP_CALL", { t = t, at = t, by = "Olaf", from = "friend", mapID = 1434, x = 1, y = 2 })
  local f
  for _, x in ipairs(GL.All("all")) do if x.k == "call" and x.by == "Olaf" then f = x end end
  H.erwartet("Ruf eines Freundes: Quelle Freunde", f and f.src == "friends", f and f.src)
end)

H.lauf("Hilferuf aus der Gruppe: nur von einem Gildenkollegen", function()
  local ns = M.Load({ before = function() M.units.player.guild = G end })
  local GL = ns.GuildLog
  local t = time()
  ns.Guild.IsGuildmate = function(n) return n == "Kollege Eins" end
  ns:Fire("HELP_CALL", { t = t, at = t, by = "Fremder", from = "group", mapID = 1434, x = 1, y = 2 })
  ns:Fire("HELP_CALL", { t = t, at = t, by = "Kollege Eins", from = "group", mapID = 1434, x = 1, y = 2 })
  local by = {}
  for _, x in ipairs(GL.All("all")) do if x.k == "call" then by[#by + 1] = x.by end end
  H.erwartet("nur der Kollege", #by == 1 and by[1] == "Kollege Eins", table.concat(by, ","))
end)

H.lauf("Sichtung: eigene Zeile mit Ort, leise (kein Punkt am Reiter)", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  local before = b.ns.GuildLog.NewSince(time() - 60, "all")
  sieht(a, key)
  W.run(7)
  H.erwartet("Vorbedingung: Berta bekam SIGHTING", H.zaehle(b, "SIGHTING") == 1, H.zaehle(b, "SIGHTING"))
  local s = ofKind(b, "sight")
  H.erwartet("eine Sichtungszeile", #s == 1, #s)
  local e = s[1] or {}
  local GL = b.ns.GuildLog
  H.erwartet("Satz", GL.Sentence(e) == "Anton hat Grimm Bart gesehen: Schlingendorntal", GL.Sentence(e))
  H.erwartet("Ort als Kartenlink", e.place and e.place.mapID == 1434)
  H.erwartet("leise: zählt nicht für den Punkt", GL.NewSince(time() - 60, "all") == before, GL.NewSince(time() - 60, "all"))
end)

H.lauf("Sichtungen desselben Feindes binnen 10 Minuten: eine Zeile mit Zahl, danach eine neue", function()
  local ns = M.Load({ before = function() M.units.player.guild = G end })
  local GL = ns.GuildLog
  local t = time()
  local function sight(dt, by, key)
    ns:Fire("SIGHTING", { key = key or "Grimm-Bart", name = "Grimm Bart", by = by, t = t + dt, at = t + dt, mapID = 1434,
      x = 30 + dt / 100, y = 40, zone = "Schlingendorntal", src = "guild" })
  end
  sight(0, "Anton"); sight(130, "Berta"); sight(400, "Cäsar")
  sight(200, "Dora", "Velka-Dorn")
  local s = {}
  for _, x in ipairs(GL.All("all")) do if x.k == "sight" and x.key == "Grimm-Bart" then s[#s + 1] = x end end
  H.erwartet("drei Sichtungen in 10 Minuten: eine Zeile", #s == 1, #s)
  local e = s[1] or {}
  H.erwartet("Zahl 3, zuletzt von Cäsar, Zeit und Ort der letzten", e.n == 3 and e.by == "Cäsar" and e.t == t + 400
    and e.place and math.abs(e.place.x - 34) < 0.01, tostring(e.n) .. " " .. tostring(e.by))
  H.erwartet("Satz mit Zahl", GL.Sentence(e) == "Grimm Bart 3× gesehen, zuletzt von Cäsar: Schlingendorntal", GL.Sentence(e))
  sight(620, "Emil")
  s = {}
  for _, x in ipairs(GL.All("all")) do if x.k == "sight" and x.key == "Grimm-Bart" then s[#s + 1] = x end end
  H.erwartet("nach 10 Minuten ab der ersten: neue Zeile", #s == 2, #s)
  H.erwartet("die neue ohne Zahl", s[1] and s[1].n == nil and GL.Sentence(s[1]) == "Emil hat Grimm Bart gesehen: Schlingendorntal",
    s[1] and GL.Sentence(s[1]))
  local v = 0
  for _, x in ipairs(GL.All("all")) do if x.k == "sight" and x.key == "Velka-Dorn" then v = v + 1 end end
  H.erwartet("ein anderer Feind: eigene Zeile", v == 1, v)
  -- a sighting of the friends' book is not merged into the guild's line
  ns:Fire("SIGHTING", { key = "Grimm-Bart", name = "Grimm Bart", by = "Olaf", t = t + 630, at = t + 630, mapID = 1434,
    x = 1, y = 1, zone = "Schlingendorntal", src = "friends" })
  local fr = 0
  for _, x in ipairs(GL.All("all")) do if x.k == "sight" and x.src == "friends" then fr = fr + 1 end end
  H.erwartet("Freunde: eigene Zeile", fr == 1, fr)
end)

H.lauf("Ring: Deckel 200 auch bei vielen Sichtungen, kaputte Felder repariert", function()
  local ns = M.Load({ before = function() M.units.player.guild = G end })
  local GL = ns.GuildLog
  local t = time()
  for i = 1, 260 do
    ns:Fire("SIGHTING", { key = "Ziel" .. i .. "-Nr", name = "Ziel " .. i, by = "Anton", t = t - i, at = t, mapID = 1434,
      x = 1, y = 1, zone = "Schlingendorntal", src = "guild" })
  end
  H.erwartet("Ring 200", #GL.DB().ring == 200, #GL.DB().ring)
  local g = GL.DB()
  g.ring[1].m, g.ring[1].x = "kaputt", nil
  g.ring[2].n = -3
  GL.Sanitize(g, t)
  H.erwartet("kaputter Ort weg", g.ring[1].m == nil and g.ring[1].x == nil and g.ring[1].y == nil)
  H.erwartet("kaputte Zahl weg", g.ring[2].n == nil)
end)

H.lauf("Ein Fehler in der Chronik kostet die Zeile der Sichtung nie", function()
  local W, a, b = paar()
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  b.ns.GuildLog.Add = function() error("kaputt") end
  local before = #M.chat
  sieht(a, key)
  W.run(7)
  local line
  for i = before + 1, #M.chat do if M.chat[i]:find("Grimm", 1, true) then line = M.chat[i] end end
  H.erwartet("Zeile der Sichtung trotzdem da", line ~= nil)
  H.erwartet("lastSeen gesetzt", b.ns.Guild.Get(key, "guild") and b.ns.Guild.Get(key, "guild").lastSeen ~= nil)
  M.errors = {}
end)

H.lauf("Wer hat das Buch: die eigene Version kommt aus der TOC", function()
  local h = io.open(H.DIR .. "/DeathNote/DeathNote.toc", "rb")
  local toc = h and h:read("*a") or ""
  if h then h:close() end
  local want = toc:match("##%s*Version:%s*([%w%.%-]+)")
  H.erwartet("TOC hat eine Version", want ~= nil)
  local ns = M.Load({ before = function() M.units.player.guild = G end })
  local B = ns.Guild.Bridge
  H.erwartet("Hallo trägt die Version der TOC", B.addonVersion() == want, B.addonVersion())
  local rows = ns.GuildLog.Holders()
  local me
  for _, r in ipairs(rows) do if r.me then me = r end end
  H.erwartet("eigene Zeile mit der Version der TOC", me and me.v == want, me and me.v)
  -- the client answers only for the addon's own folder name: another name gives nothing
  H.erwartet("fremder Ordnername: keine Version", _G.C_AddOns.GetAddOnMetadata("Staatsfeind", "Version") == nil)
end)

H.fertig()
