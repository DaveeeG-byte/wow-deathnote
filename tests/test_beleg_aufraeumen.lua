-- Finding: cleaning up removed friends (Friends.Purge) treats everyone as "removed" who was missing
-- from the last scan. (a) Battle.net friends are only in the scan while they are online and in the
-- game: when they go offline, their entries are gone. (b) The friend list belongs to the char,
-- the friends' book to the account: a login with an alt deletes the data of the main char's
-- friends. (c) A friend list that comes back empty once empties the book.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

H.lauf("Battle.net-Freund geht offline", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login(); W.run(45)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
  local key = H.tod(b, "Grimm", "Bart")
  W.run(60)
  H.erwartet("Vorbedingung: Tat des Battle.net-Freunds kam an", a.ns.Guild.Get(key, "friends") ~= nil)
  b.online = false
  a.fire("BN_FRIEND_ACCOUNT_OFFLINE")
  W.run(5)
  H.erwartet("Tat bleibt, wenn der Battle.net-Freund offline geht", a.ns.Guild.Get(key, "friends") ~= nil, "Eintrag geloescht")
end)

H.lauf("Zweit-Char mit anderer Freundesliste", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  local key = H.tod(b, "Grimm", "Bart")
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(60)
  H.erwartet("Vorbedingung: Tat und Freigabe des Freunds kamen an",
    a.ns.Guild.Get(key, "friends") ~= nil and a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  a.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(a.env.DeathNoteDB)
  -- same account, another char whose friend list does not contain Berta
  local a2 = W.client("Zweitchar", "Wurst", nil, { friends = { "Carla" }, db = db })
  a.loggedIn = false
  a2.login(); W.run(30)
  a2.fire("FRIENDLIST_UPDATE"); W.run(5)
  H.erwartet("Tat des Freunds vom Haupt-Char ueberlebt den Login mit dem Zweit-Char",
    a2.ns.Guild.Get(key, "friends") ~= nil, "Eintrag geloescht")
  H.erwartet("Freigabe des Freunds ueberlebt den Login mit dem Zweit-Char",
    a2.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil, "Freigabe geloescht")
end)

H.lauf("Freundesliste kommt einmal leer", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  local key = H.tod(b, "Grimm", "Bart")
  W.run(60)
  H.erwartet("Vorbedingung: Tat kam an", a.ns.Guild.Get(key, "friends") ~= nil)
  local keep = a.friendNames
  a.friendNames = {}                 -- the server briefly returns nothing (loading screen, reconnect)
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  a.friendNames = keep
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  H.erwartet("ein einzelner leerer Stand der Freundesliste loescht nichts", a.ns.Guild.Get(key, "friends") ~= nil,
    "Eintrag geloescht")
end)

H.fertig()
