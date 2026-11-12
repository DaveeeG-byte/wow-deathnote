-- Counter-check finding 1 (cleaning up friends' data).
-- (1) Break of more than 60 days: Battle.net friends count as removed at the first cleanup after login
--     (BN_KEEP counts from the last sighting, even if I was away), their deeds and calls are gone.
-- (2) Counter-check green: a char friend really removed disappears after 14 days and three scans.
-- (3) Counter-check green: 13 days are not enough; an alt deletes nothing; an empty list deletes nothing.
-- (4) The own char that had the friend never logs in again (deleted, renamed): the removed friend
--     stays forever, his calls keep alerting.
-- (fix-2) Proof test of the final hunt, taken into the suite; head: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

H.lauf("(1) 61 Tage Pause, Battle.net-Freund ist noch Freund", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login(); W.run(45)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
  local key = H.tod(b, "Grimm", "Bart")
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(60)
  H.erwartet("Vorbedingung: Tat und Freigabe der Battle.net-Freundin kamen an",
    a.ns.Guild.Get(key, "friends") ~= nil and a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  -- both are out of the game for 61 days; the friendship still exists
  b.online = false
  H.tage(61)
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  a2.fire("BN_FRIEND_INFO_CHANGED"); W.run(5)     -- friend offline, but still on the Battle.net list
  H.erwartet("Freigabe der Battle.net-Freundin ueberlebt meine Pause von 61 Tagen",
    a2.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil, "Freigabe geloescht")
  H.erwartet("Tat der Battle.net-Freundin ueberlebt meine Pause von 61 Tagen",
    a2.ns.Guild.Get(key, "friends") ~= nil, "Tat geloescht")
end)

-- fix-2 (decision on finding 2): the period counts in own play days (days with a login), not calendar days
H.lauf("(2) wirklich entfernter Freund verschwindet nach 14 eigenen Spieltagen (Gegenprobe)", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(30)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  a.friendNames = { "Carla" }
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  local c = a
  local function spieltag()
    H.tage(1)
    c = H.relog(W, c, { friends = { "Carla" } }); c.login(); W.run(40)
    for _ = 1, 4 do c.fire("FRIENDLIST_UPDATE"); W.run(3) end
  end
  for _ = 1, 12 do spieltag() end
  H.erwartet("12 Spieltage nach dem Entfernen steht die Freigabe noch", c.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  H.tage(60)
  c = H.relog(W, c, { friends = { "Carla" } }); c.login(); W.run(40)
  for _ = 1, 4 do c.fire("FRIENDLIST_UPDATE"); W.run(3) end
  H.erwartet("eine lange eigene Pause zaehlt nur als ein Spieltag (13)", c.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  spieltag()
  H.erwartet("14 Spieltage nach dem Entfernen ist die Freigabe weg", c.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil, "steht noch")
end)

-- fix-2: a Battle.net friend who has not played for long but is on the Battle.net list stays (BattleTag);
-- without BattleTag he is dropped after 60 own play days without a sighting (counter-check)
for _, tags in ipairs({ true, false }) do
  H.lauf("(1c) Battle.net-Freund 61 Spieltage offline, " .. (tags and "mit" or "ohne") .. " BattleTag", function()
    local W = H.welt()
    W.noTags = not tags
    local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
    local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
    a.login(); b.login(); W.run(45)
    a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
    b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
    W.run(60)
    H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
    b.online = false
    for _ = 1, 61 do H.tage(1); a.fire("BN_FRIEND_INFO_CHANGED"); W.run(3) end
    if tags then
      H.erwartet("auf der Battle.net-Liste: bleibt nach 61 Spieltagen", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
    else
      H.erwartet("ohne BattleTag: nach 60 Spieltagen ohne Sehen weg", a.ns.Guild.Hunt("Opfer-Lamm", "friends") == nil)
    end
  end)
end

-- fix-2: without BattleTag (if the client gives none) the period in play days survives the break
H.lauf("(1b) 61 Tage Pause, Battle.net ohne BattleTag", function()
  local W = H.welt()
  W.noTags = true
  local a = W.client("Anton", "Wurst", nil, { bn = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { bn = { "Anton" } })
  a.login(); b.login(); W.run(45)
  a.fire("BN_FRIEND_INFO_CHANGED"); b.fire("BN_FRIEND_INFO_CHANGED"); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(60)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  b.online = false
  H.tage(61)
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  a2.fire("BN_FRIEND_INFO_CHANGED"); W.run(5)
  H.erwartet("Freigabe ueberlebt meine Pause auch ohne BattleTag", a2.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
end)

-- Since 1.2.0 (decision on play days per char): play days of other own chars never count against a char;
-- a char that is no longer logged in loses nothing. Its friends stay until the player empties the friends' book.
H.lauf("(4) der eigene Char, der den Freund hatte, kommt nie wieder", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(45)
  b.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "Grund" })
  W.run(30)
  H.erwartet("Vorbedingung: Freigabe kam an", a.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil)
  -- Anton is deleted; the account only plays the alt, which never had Berta on its list
  H.tage(1)
  local z = H.relog(W, a, { name = "Zweitchar", surname = "Wurst", friends = { "Carla" } })
  z.login(); W.run(40)
  for i = 1, 6 do
    H.tage(60)
    z = H.relog(W, z, { friends = { "Carla" } }); z.login(); W.run(40)
    for _ = 1, 4 do z.fire("FRIENDLIST_UPDATE"); W.run(3) end
  end
  H.erwartet("ein Jahr spaeter steht die Freigabe noch (Spieltage des Zweitchars zaehlen nicht gegen den anderen Char)",
    z.ns.Guild.Hunt("Opfer-Lamm", "friends") ~= nil, "geloescht")
end)

H.fertig()
