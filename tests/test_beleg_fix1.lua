-- 1.2.0 (fix-1): Pruefungen zu den Entscheidungen nach der Fehlerjagd, die die Belege nicht abdecken.
-- W1 Verfall der Freigaben (Nie als Voreinstellung, 200 Tage, Deckel, alle abblasen), Erlegt (eindeutig,
-- 10 Minuten, Deckel je Absender, Zaehler), Ausweis ueber den Gilden-Roster, Kollege ohne Roster-API,
-- Ablehnung je Freund, Hallo-Fenster, Schlange (M/X), Sanitize. Alle Namen sind erfunden.
-- Aufruf: luajit tests/test_beleg_fix1.lua [Projektkopie]
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"
local DAY = 86400

local function eigeneDB(c)
  c.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(c.env.DeathNoteDB)
  c.loggedIn = false
  return db
end

------------------------------------------------------------------------
-- W1: Verfall einstellbar, Voreinstellung Nie
------------------------------------------------------------------------
for _, case in ipairs({ { days = 0, keep = true }, { days = 90, keep = false } }) do
  H.lauf("W1: 200 Tage Abwesenheit bei " .. (case.days == 0 and "Nie" or (case.days .. " Tagen")), function()
    local W = H.welt()
    local a = W.client("Anton", "Wurst", G, { friends = { "Fritz" } })
    local b = W.client("Berta", "Senf", G)
    local f = W.client("Fritz", "Frei", nil, { friends = { "Anton" } })
    a.login(); b.login(); f.login(); W.run(60)
    H.erwartet("Voreinstellung Nie", a.ns.Guild.Setting("huntExpire") == 0, a.ns.Guild.Setting("huntExpire"))
    if case.days > 0 then a.ns.Store.Setting("guild.huntExpire", case.days) end
    a.ns.Guild.Release("Eigen-Ziel", { to = "all", why = "meins" })
    b.ns.Guild.Release("Fremd-Ziel", { to = "guild", why = "ihres" })
    f.ns.Guild.Release("Freund-Ziel", { to = "friends", why = "seins" })
    W.run(30)
    H.erwartet("Vorbedingung: drei Ziele bei Anton", a.ns.Guild.HuntCount("all") == 3, a.ns.Guild.HuntCount("all"))
    local db = eigeneDB(a)
    b.loggedIn, f.loggedIn = false, false
    W.setOnline(b, false); W.setOnline(f, false)
    M.Advance(200 * DAY)
    local a2 = W.client("Anton", "Wurst", G, { friends = { "Fritz" }, db = db })
    a2.login(); W.run(30)
    local n = a2.ns.Guild.HuntCount("all")
    if case.keep then
      H.erwartet("Nie: alles steht noch (eigene und empfangene, Gilde und Freunde)", n == 3, n)
      H.erwartet("Nie: eigene Freigabe bleibt abblasbar", a2.ns.Guild.CallOff("Eigen-Ziel") == true)
    else
      H.erwartet("90 Tage: alles verfallen", n == 0, n)
    end
  end)
end

H.lauf("Aufraeumen: eine leere Freundesliste zaehlt nie als Fehlen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  local key = H.tod(b, "Grimm", "Bart"); W.run(30)
  H.erwartet("Vorbedingung: Tat kam an", a.ns.Guild.Get(key, "friends") ~= nil)
  b.loggedIn = false; W.setOnline(b, false)
  local keep = a.friendNames
  a.friendNames = {}
  for _ = 1, 4 do a.fire("FRIENDLIST_UPDATE"); W.run(3) end
  M.Advance(15 * DAY)
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  H.erwartet("vier leere Listen und 15 Tage: nichts geloescht", a.ns.Guild.Get(key, "friends") ~= nil)
  a.friendNames = keep
end)

H.lauf("W1: kuerzerer Verfall wirkt sofort, empfangene alte Freigaben werden nicht angenommen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.gilde(a, P.EncodeHunt({ key = "Alt-Ziel", t = time() - 120 * DAY, by = "Berta Senf", why = "alt" }), "Berta-Forever")
  H.erwartet("Nie: eine 120 Tage alte Freigabe wird angenommen", a.ns.Guild.Hunt("Alt-Ziel", "guild") ~= nil)
  a.ns.Store.Setting("guild.huntExpire", 90)
  H.erwartet("auf 90 Tage gestellt: sofort weg", a.ns.Guild.Hunt("Alt-Ziel", "guild") == nil)
  H.gilde(a, P.EncodeHunt({ key = "Alt-Zwei", t = time() - 100 * DAY, by = "Berta Senf", why = "alt" }), "Berta-Forever")
  H.erwartet("90 Tage: eine 100 Tage alte Freigabe wird nicht angenommen", a.ns.Guild.Hunt("Alt-Zwei", "guild") == nil)
  H.gilde(a, P.EncodeHunt({ key = "Neu-Zwei", t = time() - 10 * DAY, by = "Berta Senf", why = "neu" }), "Berta-Forever")
  H.erwartet("90 Tage: eine 10 Tage alte wird angenommen", a.ns.Guild.Hunt("Neu-Zwei", "guild") ~= nil)
end)

H.lauf("W1: Deckel bei Nie: die aelteste fremde Freigabe fliegt, nie eine eigene", function()
  local P = (function() local W = H.welt(); return W.client("X", "Y", G).ns.Guild.Proto end)()
  local hunts, t = {}, 1000000
  local mine = function(c) return c == "Ich Selbst" end
  P.MergeHunt(hunts, { key = "Mein-Ziel", name = "Mein", surname = "Ziel", t = t - 500, by = "Ich Selbst" }, { maxTotal = 3, protect = mine })
  P.MergeHunt(hunts, { key = "Alt-Ziel", name = "Alt", surname = "Ziel", t = t - 400, by = "Kai Kalt" }, { maxTotal = 3, protect = mine })
  P.MergeHunt(hunts, { key = "Mitt-Ziel", name = "Mitt", surname = "Ziel", t = t - 300, by = "Lea Lau" }, { maxTotal = 3, protect = mine })
  local res = P.MergeHunt(hunts, { key = "Neu-Ziel", name = "Neu", surname = "Ziel", t = t, by = "Mo Mau" }, { maxTotal = 3, protect = mine })
  H.erwartet("neues Ziel kommt trotz vollem Deckel", res == "new", res)
  H.erwartet("die aelteste fremde Freigabe ist weg", hunts["Alt-Ziel"] == nil)
  H.erwartet("die eigene (noch aeltere) bleibt", hunts["Mein-Ziel"] ~= nil)
  local only = {}
  P.MergeHunt(only, { key = "Mein-Ziel", name = "Mein", surname = "Ziel", t = t, by = "Ich Selbst" }, { maxTotal = 1, protect = mine })
  res = P.MergeHunt(only, { key = "Neu-Ziel", name = "Neu", surname = "Ziel", t = t, by = "Mo Mau" }, { maxTotal = 1, protect = mine })
  H.erwartet("nur eigene im Deckel: das neue fremde wird abgelehnt", res == "cap" and only["Mein-Ziel"] ~= nil, res)
end)

H.lauf("W1: Alle meine Freigaben abblasen, gedrosselt ueber die Schlange", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz" } })
  local b = W.client("Berta", "Senf", G)
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton" } })
  a.login(); b.login(); f.login(); W.run(60)
  for i = 1, 6 do a.ns.Guild.Release("Ziel" .. string.char(64 + i) .. "-Lamm", { to = "all" }) end
  W.run(30)
  H.erwartet("Vorbedingung: Berta und Fritz sehen sechs Ziele", b.ns.Guild.HuntCount("guild") == 6 and f.ns.Guild.HuntCount("friends") == 6,
    b.ns.Guild.HuntCount("guild") .. "/" .. f.ns.Guild.HuntCount("friends"))
  local n0 = #W.sent
  H.erwartet("sechs abgeblasen", a.ns.Guild.CallOffAll() == 6)
  local at = {}
  for i = n0 + 1, #W.sent do if W.sent[i].sender == a and W.sent[i].text:match("^1\tA\t") then at[#at + 1] = M.now end end
  H.erwartet("nicht alles auf einmal: die Schlange sendet mit Abstand", #at < 12, #at)
  W.run(30)
  H.erwartet("Berta und Fritz: alles abgeblasen", b.ns.Guild.HuntCount("guild") == 0 and f.ns.Guild.HuntCount("friends") == 0,
    b.ns.Guild.HuntCount("guild") .. "/" .. f.ns.Guild.HuntCount("friends"))
end)

------------------------------------------------------------------------
-- Erlegt: eindeutig, Zeitfenster, Deckel je Absender, Zaehler klein
------------------------------------------------------------------------
H.lauf("Erlegt: jede Toetung zaehlt einmal, Deckel je Absender, Zukunft verworfen", function()
  local W = H.welt({ "HUNT_BAGGED" })
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild" }); W.run(5)
  local now = time()
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 500), "Berta-Forever")
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 350), "Berta-Forever")
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 500), "Berta-Forever")   -- dieselbe noch einmal
  local h = a.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("zwei verschiedene Toetungen zaehlen zwei", h.bagged == 2, h.bagged)
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 200), "Berta-Forever")
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now - 50), "Berta-Forever")
  h = a.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("Deckel je Absender: hoechstens drei in zehn Minuten", h.bagged == 3, h.bagged)
  H.gilde(a, P.EncodeBagged("Opfer-Lamm", "Berta Senf", now + 1000), "Berta-Forever")
  H.erwartet("aus der Zukunft: verworfen", a.ns.Guild.Hunt("Opfer-Lamm", "guild").bagged == 3)
  -- Zaehler mit kleinem Deckel (99), auch in den Daten
  local hunts = a.ns.Guild.DB().lists[G].hunts
  hunts["Opfer-Lamm"].bagged = 5000
  P.SanitizeHunts(hunts, time())
  H.erwartet("gespeicherter Zaehler wird auf 99 gekappt", hunts["Opfer-Lamm"].bagged == 99, hunts["Opfer-Lamm"].bagged)
  hunts["Opfer-Lamm"].bagged = 0 / 0
  P.SanitizeHunts(hunts, time())
  H.erwartet("NaN als Zaehler faellt weg", hunts["Opfer-Lamm"].bagged == nil)
end)

------------------------------------------------------------------------
-- Ausweis in der Gilde ueber den Roster (wo der Client den Nachnamen dort fuehrt)
------------------------------------------------------------------------
H.lauf("Gilde: der Roster nennt den Nachnamen, das Feld muss passen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local z = W.client("Zeuge", "Still", G)
  a.login(); z.login(); W.run(40)
  -- der Roster dieses Clients fuehrt volle Namen (Absender kommen trotzdem nur mit Vornamen)
  z.env.GetNumGuildMembers = function() return 2 end
  z.env.GetGuildRosterInfo = function(i) return ({ "Anton Wurst-Forever", "Zeuge Still-Forever" })[i] end
  z.ns.Guild.ReadRoster()
  local P = z.ns.Guild.Proto
  H.gilde(z, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Anton Falsch", why = "x" }), "Anton-Forever")
  H.erwartet("Feld 'Anton Falsch' von 'Anton' (Roster: Anton Wurst): verworfen", z.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil)
  H.gilde(z, P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Anton Wurst", why = "x" }), "Anton-Forever")
  H.erwartet("Feld 'Anton Wurst': angenommen", z.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil)
  local pr = z.ns.Guild.stats.senderForm
  H.erwartet("die Sonde vermerkt die Namensform des Absenders", pr == "first", pr)
end)

-- fix-2 (Fund 6 der finalen Jagd): Kollege nur mit vollem Namen; der Client nennt hier den Nachnamen mit
H.lauf("Kollege ohne Roster-API: nur wer kuerzlich auf GUILD zu hoeren war", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta Senf" }, noRoster = true, fullSender = true })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton Wurst" }, noRoster = true, fullSender = true })
  a.login(); b.login(); W.run(45)
  H.tod(b, "Alt", "Feind"); W.run(5)
  H.erwartet("eben gehoert: Kollegin", a.ns.Guild.IsGuildmate("Berta Senf") == true)
  H.erwartet("Vorname allein ist kein Beleg (fix-2)", a.ns.Guild.IsGuildmate("Berta") == false)
  M.Advance(400)
  H.erwartet("seit fuenf Minuten still: kein Kollege mehr (Fluestern geht wieder)", a.ns.Guild.IsGuildmate("Berta Senf") == false)
end)

H.lauf("Kollege: Roster nur mit Vornamen, Namensvetter hat die Gilde verlassen", function()
  -- (a) nur ich heisse Anton in der Gilde: der eigene Char zaehlt im Roster nicht mit
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local f = W.client("Anton", "Falsch", G, { fullSender = true })
  a.login(); f.login(); W.run(45)
  H.tod(f, "Alt", "Feind"); W.run(5)
  H.erwartet("Vorbedingung: Anton Falsch ist Kollege", a.ns.Guild.IsGuildmate("Anton Falsch") == true)
  f.guild = nil; f.fire("PLAYER_GUILD_UPDATE")
  a.fire("GUILD_ROSTER_UPDATE")
  H.erwartet("ausgetreten: der Roster hat nur noch mich als Anton", a.ns.Guild.IsGuildmate("Anton Falsch") == false)
  -- (b) ein zweiter Anton ist noch drin: der Ausgetretene zaehlt nur, solange er kuerzlich gehoert wurde
  W = H.welt()
  a = W.client("Anton", "Wurst", G, { fullSender = true })
  f = W.client("Anton", "Falsch", G, { fullSender = true })
  local d = W.client("Anton", "Dritter", G, { fullSender = true })
  a.login(); f.login(); d.login(); W.run(45)
  H.tod(f, "Alt", "Feind"); W.run(5)
  f.guild = nil; f.fire("PLAYER_GUILD_UPDATE")
  M.Advance(400)
  a.fire("GUILD_ROSTER_UPDATE")
  H.erwartet("Namensvetter seit Minuten nicht gehoert: kein Kollege mehr", a.ns.Guild.IsGuildmate("Anton Falsch") == false)
  H.erwartet("der andere Anton (eben gehoert) bleibt Kollege", (function() H.tod(d, "Neu", "Feind"); W.run(5)
    return a.ns.Guild.IsGuildmate("Anton Dritter") end)() == true)
end)

H.lauf("Freund verlaesst die Gilde: beim naechsten Roster-Ereignis sofort per Fluestern bedient", function()
  local W = H.welt()
  -- fix-2: mit vollen Namen (nur so sind beide sicher Kollegen; mit Vornamen allein flüstern sie ohnehin)
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(60)
  a.fire("FRIENDLIST_UPDATE"); b.fire("FRIENDLIST_UPDATE"); W.run(5)
  local n0 = #W.sent
  b.guild = nil
  b.fire("PLAYER_GUILD_UPDATE"); a.fire("GUILD_ROSTER_UPDATE")
  W.run(30)
  local hello = 0
  for i = n0 + 1, #W.sent do
    local m = W.sent[i]
    if m.channel == "WHISPER" and m.text:match("^1\tH\t") then hello = hello + 1 end
  end
  H.erwartet("beide gruessen einander sofort per Fluestern", hello >= 2, hello)
  local key = H.tod(b, "Grimm", "Bart"); W.run(5)
  H.erwartet("die naechste Tat kommt live an (ohne /dn sync)", a.ns.Guild.Get(key, "friends") ~= nil)
end)

------------------------------------------------------------------------
-- Ablehnung je Freund, Battle.net als Ausweg, Hallo im gleitenden Fenster
------------------------------------------------------------------------
H.lauf("Drei Ablehnungen an einen Freund: nur er ruht, die anderen nicht", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Geist", "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  local g = W.client("Geist", "Fern", nil, { friends = { "Anton" } })
  local CI = a.env.C_ChatInfo
  local send = CI.SendAddonMessage
  CI.SendAddonMessage = function(prefix, text, channel, target)
    if channel == "WHISPER" and target == "Geist" then return 4 end
    return send(prefix, text, channel, target)
  end
  a.login(); b.login(); g.login(); W.run(60)
  H.erwartet("Vorbedingung: Berta ist Partner", a.ns.Friends.PeerCount() >= 1)
  for _ = 1, 3 do a.ns.Guild.Proto.EncodeHello(0, "1.2.0"); a.ns.Guild.Bridge.enqueue("1\tH\t0\t1.2.0", "H", "WHISPER", "Geist"); W.run(5) end
  H.erwartet("Geist ruht nach drei Ablehnungen", a.ns.Friends.Suspended("Geist") == true)
  H.erwartet("nicht alle gesperrt", a.ns.Friends.Blocked() == false)
  local h = a.ns.Friends.Health()
  H.erwartet("Statuszeile sagt: geht nicht durch", h.reason == "failing", h.reason)
  local key = H.tod(a, "Grimm", "Bart"); W.run(5)
  H.erwartet("Berta bekommt weiter Live-Taten", b.ns.Guild.Get(key, "friends") ~= nil)
end)

H.lauf("Hallo: gleitendes Fenster statt fester Zahl je Sitzung", function()
  local W = H.welt()
  local names = {}
  for i = 1, 35 do names[i] = "Freund" .. string.char(64 + (i % 26) + 1) .. string.char(64 + math.floor(i / 26) + 1) end
  local a = W.client("Anton", "Wurst", nil, { friends = names })
  for i = 1, 35 do W.client(names[i], "Nach", nil, { friends = {} }).login() end
  a.login(); W.run(60)
  local function hellos()
    local n = 0
    for _, m in ipairs(W.sent) do if m.sender == a and m.channel == "WHISPER" and m.text:match("^1\tH\t") then n = n + 1 end end
    return n
  end
  local h1 = hellos()
  H.erwartet("hoechstens 30 Hallo im Fenster", h1 <= 30, h1)
  M.Advance(700)
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  -- neue Freunde kommen spaeter online: nach dem Fenster werden sie wieder gegruesst
  local late = W.client("Spaet", "Kommer", nil, { friends = {} })
  a.friendNames[#a.friendNames + 1] = "Spaet"
  late.login(); W.run(60)
  local toLate = 0
  for _, m in ipairs(W.sent) do if m.sender == a and m.to == "Spaet" and m.text:match("^1\tH\t") then toLate = toLate + 1 end end
  H.erwartet("ein spaeter Freund wird nach 10 Minuten gegruesst", toLate == 1, toLate)
end)

------------------------------------------------------------------------
-- Schlange: Eintragen und Austragen (M/X) nehmen einander zurueck wie J/A
------------------------------------------------------------------------
H.lauf("Schlange: M und X desselben Eintrags, nur das letzte Wort geht raus", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  a.combat = true
  local k = a.ns.Store.AddManual("Hand", "Eintrag"); M.Advance(2)
  a.ns.Store.SetStatus(k, "pardoned"); M.Advance(2)
  a.ns.Store.SetStatus(k, "wanted"); M.Advance(2)
  a.ns.Store.SetStatus(k, "pardoned"); M.Advance(2)
  a.combat = false
  a.fire("PLAYER_REGEN_ENABLED")
  W.run(60)
  local e = b.ns.Guild.Get(k, "guild")
  H.erwartet("beim Kollegen nicht eingetragen (bei mir begnadigt)", e == nil, e and "steht bei Berta")
end)

------------------------------------------------------------------------
-- Schlange: eine Nachricht fuer die Gilde geht nur in diese Gilde (Zufallslauf mit Gildenwechsel)
------------------------------------------------------------------------
H.lauf("Schlange: wartende Gilden-Nachricht nach Gildenwechsel nicht in die neue Gilde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", "Andere Gilde")
  a.login(); b.login(); W.run(40)
  a.combat = true
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild" }); M.Advance(2)
  a.guild = "Andere Gilde"
  a.fire("PLAYER_GUILD_UPDATE")
  a.combat = false
  a.fire("PLAYER_REGEN_ENABLED")
  W.run(30)
  H.erwartet("die Freigabe fuer die alte Gilde landet nicht in der neuen", b.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil)
end)

------------------------------------------------------------------------
-- Daten: verstuemmelte Freundes-Bindungen und Ausgeblendete laden ohne Fehler
------------------------------------------------------------------------
H.lauf("Verstuemmelte ties und huntHidden in den SavedVariables", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
  a.login(); W.run(30)
  local db = eigeneDB(a)
  db.friends.ties = { Berta = { chars = { ["Anton Wurst"] = "x", [5] = 1 }, bn = "gestern", seen = 0 / 0, full = "kein" },
    [7] = {}, Kaputt = "nein" }
  db.guild.huntHidden = { ["Opfer-Lamm"] = "nie", ["kein key"] = 1, ["Gut-Ziel"] = time() }
  local a2 = W.client("Anton", "Wurst", G, { friends = { "Berta" }, db = db })
  a2.login(); W.run(30)
  a2.fire("FRIENDLIST_UPDATE"); W.run(5)
  local t = a2.ns.Friends.DB().ties
  H.erwartet("kaputte Bindungen repariert", type(t.Berta) == "table" and t.Kaputt == nil and t[7] == nil
    and t.Berta.full == nil and t.Berta.bn == nil)
  local hh = a2.ns.Guild.DB().huntHidden
  H.erwartet("kaputte Ausgeblendete raus, gute bleiben", hh["Opfer-Lamm"] == nil and hh["kein key"] == nil and hh["Gut-Ziel"] ~= nil)
end)

H.fertig()
