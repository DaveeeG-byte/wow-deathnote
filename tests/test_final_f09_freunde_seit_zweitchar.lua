-- Zusammenspiel mehrere eigene Chars und Freundes-Abgleich: "Sende mir, was neuer ist als ..." rechnet bei den
-- Freunden mit EINEM accountweiten Zeitpunkt (friends.lastOnline, bei jedem Logout jedes Chars gesetzt). Die
-- Freundesliste gehoert aber dem Char. Spielt man einige Tage einen Zweit-Char, fragt der Haupt-Char danach nur
-- noch drei Tage zurueck: Taten seiner Freunde aus der Zeit davor kommen nie mehr an. (In der Gilde hat jede
-- Gildenliste ihren eigenen Zeitpunkt, dort stimmt es.)
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

local function ablauf(mitZweitchar)
  local W = H.welt()
  -- ein Tag vergeht: Uhr plus ein Stueck Sitzungszeit (Fritz bleibt online, seine Sperrfristen laufen ab)
  local function tag() H.tage(1); W.run(900) end
  local a = W.client("Anton", "Wurst", nil, { friends = { "Fritz Frei" } })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" } })
  a.login(); f.login(); W.run(60)
  local k0 = H.tod(f, "Alt", "Bekannt"); W.run(30)
  H.erwartet("Vorbedingung: Tat des Freunds kommt live an", a.ns.Guild.Get(k0, "friends") ~= nil)
  -- Anton geht; Fritz stirbt am naechsten Tag (Anton ist nicht online)
  a.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(a.env.DeathNoteDB)
  a.loggedIn = false
  for i = #W.clients, 1, -1 do if W.clients[i] == a then table.remove(W.clients, i) end end
  W.setOnline(a, false)
  tag()
  local key = H.tod(f, "Grimm", "Bart"); W.run(30)
  if mitZweitchar then
    -- derselbe Account spielt vier Tage lang einen Zweit-Char, der Fritz nicht kennt
    for _ = 1, 4 do
      tag()
      local z = W.client("Zweitchar", "Wurst", nil, { friends = { "Carla" }, db = db })
      z.login(); W.run(60)
      z.fire("PLAYER_LOGOUT")
      db = H.tiefe_kopie(z.env.DeathNoteDB)
      z.loggedIn = false
      for i = #W.clients, 1, -1 do if W.clients[i] == z then table.remove(W.clients, i) end end
    end
  else
    for _ = 1, 4 do tag() end
  end
  tag()
  local a2 = W.client("Anton", "Wurst", nil, { friends = { "Fritz Frei" }, db = db })
  a2.login(); W.run(120)
  a2.ns.Friends.SyncNow(); W.run(400)
  return a2.ns.Guild.Get(key, "friends") ~= nil
end

H.lauf("sechs Tage weg, ohne Zweit-Char (Gegenprobe)", function()
  H.erwartet("die verpasste Tat des Freunds kommt nach der Rueckkehr an", ablauf(false) == true)
end)
H.lauf("sechs Tage weg, dazwischen vier Tage Zweit-Char", function()
  H.erwartet("die verpasste Tat des Freunds kommt auch dann an, wenn dazwischen ein Zweit-Char gespielt wurde", ablauf(true) == true,
    "fehlt dauerhaft")
end)

H.fertig()
