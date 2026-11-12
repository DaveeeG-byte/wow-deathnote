-- Field 4: deadlines in play days.
-- (1) After an own break of more than 90 days, three play days on the main character are enough and all
--     friends only the alt has on its list count as let go: their deeds and calls
--     are deleted (the alt was "not logged in for 90 days while the account kept playing").
--     This is the case "come back after months and it is gone", now for the alts' friends.
-- (2) Clock set back: every change of the calendar day (also backwards) counts as a new play day.
-- (3) Counter-checks (green): a 400-day break and one login deletes nothing; 13 play days after removal still
--     there, gone after 14; several characters on the same day count one day; login at midnight; broken counters.
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
  -- own break, then three evenings on the main character (other character, own friend list, same account)
  H.tage(100)
  for tag = 1, 3 do
    local h = W.client("Haupt", "Wurst", nil, { db = db, friends = { "Dora Gross" } })
    h.login(); W.run(60)
    h.fire("FRIENDLIST_UPDATE"); W.run(60)   -- the friend list reports during the session (cleanup)
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
    H.tage(i % 2 == 1 and -1 or 1)   -- one day back, one day forward: ends on the same calendar day
    local x = W.client("Anton", "Wurst", nil, { db = db, friends = { "Carla Klein" } })
    x.login(); W.run(30)
    db = H.raus(W, x)
  end
  H.erwartet("Hin und Her der Uhr ueber zwei Kalendertage zaehlt hoechstens zwei Spieltage", db.friends.days - d0 <= 1,
    "gezaehlt: " .. (db.friends.days - d0) .. " weitere Spieltage in 6 Logins an zwei Kalendertagen")
end)

H.lauf("(3) Gegenproben", function()
  -- long break: nothing gone
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
  -- removed: still there after 13 play days, gone after 14; three characters on the same day count one day
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
    local x = W.client("Anton", "Wurst", nil, { db = db, friends = { "Emil Kurz" } })   -- Carla removed
    x.login(); W.run(40); x.fire("FRIENDLIST_UPDATE"); W.run(5); x.fire("FRIENDLIST_UPDATE"); W.run(5)
    if tag == 13 then da13 = x.ns.Guild.Get(key, "friends") ~= nil end
    if tag == 15 then H.erwartet("entfernt: nach 15 Spieltagen weg", x.ns.Guild.Get(key, "friends") == nil) end
    db = H.raus(W, x)
  end
  H.erwartet("entfernt: nach 13 Spieltagen noch da", da13 == true)
  -- broken counters in the file
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
