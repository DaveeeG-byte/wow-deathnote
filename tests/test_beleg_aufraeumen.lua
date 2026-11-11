-- Fund: Das Aufraeumen entfernter Freunde (Friends.Purge) haelt jeden fuer "entfernt", der im
-- letzten Scan nicht vorkam. (a) Battle.net-Freunde stehen nur im Scan, solange sie online und im
-- Spiel sind: gehen sie offline, sind ihre Eintraege weg. (b) Die Freundesliste gehoert dem Char,
-- das Freundesbuch dem Account: ein Login mit einem Zweit-Char loescht die Daten der Freunde des
-- Haupt-Chars. (c) Eine einmal leer gelieferte Freundesliste leert das Buch.
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
  -- derselbe Account, anderer Char, dessen Freundesliste Berta nicht enthaelt
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
  a.friendNames = {}                 -- der Server liefert kurz nichts (Ladebildschirm, Neuverbindung)
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  a.friendNames = keep
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  H.erwartet("ein einzelner leerer Stand der Freundesliste loescht nichts", a.ns.Guild.Get(key, "friends") ~= nil,
    "Eintrag geloescht")
end)

H.fertig()
