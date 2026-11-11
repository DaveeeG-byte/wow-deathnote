-- Feld 4: Fristen in Spieltagen.
-- (1) Nach einer eigenen Pause von mehr als 90 Tagen genuegen drei Spieltage auf dem Hauptchar, und alle
--     Freunde, die nur der Zweitchar auf der Liste hat, gelten als losgelassen: ihre Taten und Freigaben
--     werden geloescht (der Zweitchar war "90 Tage nicht eingeloggt, waehrend der Account weiterspielte").
--     Das ist der Fall "nach Monaten wiederkommen und es ist weg", jetzt fuer die Freunde der Zweitchars.
-- (2) Uhr zurueckgestellt: jeder Wechsel des Kalendertags (auch rueckwaerts) zaehlt als neuer Spieltag.
-- (3) Gegenproben (gruen): 400 Tage Pause und ein Login loescht nichts; 13 Spieltage nach dem Entfernen noch
--     da, nach 14 weg; mehrere Chars am selben Tag zaehlen einen Tag; Login um Mitternacht; kaputte Zaehler.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

local function fdb(c) return c.env.DeathNoteDB.friends end

H.lauf("(1) Pause ueber 90 Tage, dann drei Tage Hauptchar: Freunde des Zweitchars", function()
  local W = H.welt()
  local c = W.client("Carla", "Klein", nil, { friends = { "Zweit Wurst" }, fullSender = true })
  local z = W.client("Zweit", "Wurst", nil, { friends = { "Carla Klein" } })
  c.login(); z.login(); W.run(90)
  local key = H.tod(c, "Taeter", "Lamm"); W.run(10)
  c.ns.Guild.Release("Ziel-Lamm", { to = "friends", why = "Grund" }); W.run(10)
  H.erwartet("Vorbedingung: der Zweitchar hat Tat und Freigabe der Freundin", z.ns.Guild.Get(key, "friends") ~= nil
    and z.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil)
  local db = H.raus(W, z); H.raus(W, c); W.run(120)
  -- eigene Pause, danach drei Abende auf dem Hauptchar (anderer Char, eigene Freundesliste, gleicher Account)
  H.tage(100)
  for tag = 1, 3 do
    local h = W.client("Haupt", "Wurst", nil, { db = db, friends = { "Dora Gross" } })
    h.login(); W.run(60)
    h.fire("FRIENDLIST_UPDATE"); W.run(60)   -- die Freundesliste meldet sich im Lauf der Sitzung (Aufraeumen)
    db = H.raus(W, h); W.run(120)
    H.tage(1)
  end
  local z2 = W.client("Zweit", "Wurst", nil, { db = db, friends = { "Carla Klein" } })
  z2.login(); W.run(60)
  H.erwartet("nach der Pause und drei Abenden auf dem Hauptchar hat der Zweitchar die Tat seiner Freundin noch",
    z2.ns.Guild.Get(key, "friends") ~= nil, "geloescht")
  H.erwartet("... und ihre Freigabe", z2.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil, "geloescht")
end)

H.lauf("(2) Uhr zurueck und wieder vor: Spieltage", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Carla Klein" } })
  a.login(); W.run(30)
  local d0 = fdb(a).days
  local db = H.raus(W, a)
  for i = 1, 6 do
    H.tage(i % 2 == 1 and -1 or 1)   -- einen Tag zurueck, einen Tag vor: am Ende derselbe Kalendertag
    local x = W.client("Anton", "Wurst", nil, { db = db, friends = { "Carla Klein" } })
    x.login(); W.run(30)
    db = H.raus(W, x)
  end
  H.erwartet("Hin und Her der Uhr ueber zwei Kalendertage zaehlt hoechstens zwei Spieltage", db.friends.days - d0 <= 1,
    "gezaehlt: " .. (db.friends.days - d0) .. " weitere Spieltage in 6 Logins an zwei Kalendertagen")
end)

H.lauf("(3) Gegenproben", function()
  -- lange Pause: nichts weg
  local W = H.welt()
  local c = W.client("Carla", "Klein", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Carla Klein" } })
  c.login(); a.login(); W.run(90)
  local key = H.tod(c, "Taeter", "Lamm"); W.run(10)
  local db = H.raus(W, a); H.raus(W, c); W.run(120)
  H.tage(160)
  local a2 = W.client("Anton", "Wurst", nil, { db = db, friends = { "Carla Klein" } })
  a2.login(); W.run(120)
  H.erwartet("160 Tage Pause, ein Login: Tat der Freundin noch da", a2.ns.Guild.Get(key, "friends") ~= nil)
  -- entfernt: 13 Spieltage noch da, nach 14 weg; drei Chars am selben Tag zaehlen einen Tag
  db = H.raus(W, a2)
  local d0 = db.friends.days
  for _, n in ipairs({ "Anton", "Zweit", "Dritt" }) do
    local x = W.client(n, "Wurst", nil, { db = db, friends = n == "Anton" and { "Carla Klein" } or { "Emil Kurz" } })
    x.login(); W.run(30); db = H.raus(W, x)
  end
  H.erwartet("drei Chars am selben Tag: kein weiterer Spieltag", db.friends.days == d0, db.friends.days - d0)
  local da13
  for tag = 1, 15 do
    H.tage(1)
    local x = W.client("Anton", "Wurst", nil, { db = db, friends = { "Emil Kurz" } })   -- Carla entfernt
    x.login(); W.run(40); x.fire("FRIENDLIST_UPDATE"); W.run(5); x.fire("FRIENDLIST_UPDATE"); W.run(5)
    if tag == 13 then da13 = x.ns.Guild.Get(key, "friends") ~= nil end
    if tag == 15 then H.erwartet("entfernt: nach 15 Spieltagen weg", x.ns.Guild.Get(key, "friends") == nil) end
    db = H.raus(W, x)
  end
  H.erwartet("entfernt: nach 13 Spieltagen noch da", da13 == true)
  -- kaputte Zaehler in der Datei
  for _, v in ipairs({ -5, 1 / 0, 0 / 0, "x", true, {}, 2 ^ 60 }) do
    local d2 = H.tiefe_kopie(db)
    d2.friends.days, d2.friends.dayAt = v, v
    for _, tie in pairs(d2.friends.ties) do tie.seenDay, tie.bnDay = v, v end
    local x = W.client("Anton", "Wurst", nil, { db = d2, friends = { "Emil Kurz" } })
    x.login(); W.run(40)
    local dd = x.env.DeathNoteDB.friends.days
    H.erwartet("kaputter Zaehler " .. tostring(v) .. ": kein Fehler, Zaehler brauchbar", type(dd) == "number" and dd == dd and dd >= 0, dd)
    H.raus(W, x)
  end
end)

H.fertig()
