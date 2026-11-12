-- Field 8: upgrade and downgrade with the NEW fields (binding with GUID, conflict, play days,
-- empty memory, humor markers, page "More"), interim build (stand-nach-fix1) -> final build, and
-- mixed versions with the new messages (hello with GUID, Z) against 1.1.0 and against the interim build.
-- Usage: luajit beleg_a05_hoch_zurueck_mischbetrieb.lua <project copy> [addon folder of the interim build]
-- 1.1.0 comes from <project copy>/tests/fixtures/addon-1.1.0 (logic only).
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"
local OLD = H.DIR .. "/tests/fixtures/addon-1.1.0/"
local MID = (arg[2] or (H.DIR .. "/../stand-nach-fix1/DeathNote")):gsub("/+$", "") .. "/"
local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
local hatMid = io.open(MID .. "Friends.lua", "rb") ~= nil

local function gleich(a, b, pfad, out)
  out = out or {}
  if type(a) ~= type(b) then out[#out + 1] = pfad; return out end
  if type(a) ~= "table" then if a ~= b then out[#out + 1] = pfad end return out end
  for k, v in pairs(a) do gleich(v, b[k], pfad .. "." .. tostring(k), out) end
  return out
end

H.lauf("(1) neue Felder: 1.2.0 -> 1.1.0 -> 1.2.0", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta", "Carla" }, fullSender = true })
  local z = W.client("Zeuge", "Still", G, { fullSender = true })
  a.login(); z.login(); W.run(60)
  local P = a.ns.Guild.Proto
  -- conflict for Berta, choice for Carla, calls, emptying, hiding, humor markers, page More
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.fluestern(a, H.J(P, "C1-Lamm", "Carla Eins"), "Carla Eins-Forever")
  H.fluestern(a, H.J(P, "C2-Lamm", "Carla Zwei"), "Carla Zwei-Forever")
  a.ns.Friends.Choose("Carla", "Carla Eins")
  z.ns.Guild.Release("Z1-Lamm", { to = "guild", why = "Grund" }); W.run(20)
  a.ns.Guild.Release("A1-Lamm", { to = "all", why = "Grund" }); W.run(20)
  a.ns.Guild.Clear(); a.ns.Guild.HideHunt("A1-Lamm", true)
  local db = a.env.DeathNoteDB
  db.humor = { m = { stamm = true, rache = true }, deaths = 123 }
  db.settings.ui = db.settings.ui or {}; db.settings.ui.guildMore = true
  db.friends.ties["Berta"].guid = "Player-1-ABCDEF01"
  local vorher = H.tiefe_kopie(H.raus(W, a))
  H.erwartet("Vorbedingung: Konflikt, Wahl, Leeren-Gedaechtnis in der Datei", vorher.friends.ties["Berta"].rival ~= nil
    and vorher.friends.ties["Carla"].sure == true and vorher.guild.lists[G].huntCleared ~= nil and vorher.friends.days ~= nil)
  -- back to 1.1.0: play one evening, die, hear all new messages
  H.tage(1)
  local o = W.client("Anton", "Wurst", G, { db = H.tiefe_kopie(vorher), dir = OLD, files = OLDFILES, lang = false })
  o.login(); W.run(60)
  local key = H.tod(o, "Neu", "Wolf"); W.run(10)
  for _, t in ipairs({ P.EncodeSnapshot("Zeuge Still", 0), P.EncodeHello(0, "1.2.0", "Player-1-ABCDEF01"),
    H.J(P, "X-Lamm", "Zeuge Still"), P.EncodeCallOff("Z1-Lamm", "Zeuge Still"), P.EncodeBagged("Z1-Lamm", "Zeuge Still", time()) }) do
    H.gilde(o, t, "Zeuge Still-Forever"); H.fluestern(o, t, "Berta Senf-Forever")
  end
  z.ns.Guild.SyncNow(); W.run(60)
  local mitte = H.raus(W, o)
  local diff = gleich(vorher.friends, mitte.friends, "friends")
  H.erwartet("1.1.0 laesst das Freundesbuch samt Bindungen, Spieltagen und Leeren-Gedaechtnis stehen", #diff == 0, table.concat(diff, ", "))
  H.erwartet("1.1.0 laesst Humor-Merker und Seite Mehr stehen", mitte.humor and mitte.humor.m and mitte.humor.m.stamm == true
    and mitte.humor.deaths == 123 and mitte.settings.ui.guildMore == true)
  local gl = mitte.guild.lists[G]
  H.erwartet("1.1.0 laesst Leeren-Gedaechtnis, Ausgeblendetes und eigene Freigabe der Gilde stehen",
    gl.huntCleared ~= nil and mitte.guild.huntHidden["A1-Lamm"] ~= nil and gl.hunts["A1-Lamm"] ~= nil and gl.hunts["X-Lamm"] == nil)
  -- up again
  H.tage(1)
  local n = W.client("Anton", "Wurst", G, { db = mitte, friends = { "Berta", "Carla" }, fullSender = true })
  n.login(); W.run(90)
  local nf = n.env.DeathNoteDB.friends
  H.erwartet("wieder 1.2.0: Konflikt und Wahl stehen", nf.ties["Berta"] and nf.ties["Berta"].rival == "Berta Senf"
    and nf.ties["Carla"] and nf.ties["Carla"].sure == true and n.ns.Friends.Health().reason == "conflict",
    n.ns.Friends.Health().reason)
  H.erwartet("wieder 1.2.0: Tod aus der Zeit unter 1.1.0 ist im Buch und beim Zeugen", n.ns.Store.Get(key) ~= nil
    and z.ns.Guild.Get(key, "guild") ~= nil)
  H.erwartet("wieder 1.2.0: Spieltage zaehlen weiter (zwei Tage spaeter, einer davon unter 1.1.0)",
    nf.days == vorher.friends.days + 1, tostring(nf.days) .. " statt " .. tostring(vorher.friends.days + 1))
end)

H.lauf("(2) Mischbetrieb: 1.1.0 neben zwei 1.2.0 in der Gilde, alle Typen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local o = W.client("Otto", "Alt", G, { dir = OLD, files = OLDFILES, lang = false, fullSender = true })
  a.login(); b.login(); W.run(90)
  local ka = H.tod(a, "Taeter", "Lamm"); W.run(20)
  a.ns.Guild.Release("Ziel-Lamm", { to = "guild", why = "Grund mit Umlaut äöü" }); W.run(10)
  a.ns.Guild.CallOff("Ziel-Lamm"); a.ns.Guild.Release("Zwei-Lamm", { to = "guild", why = "x" }); W.run(10)
  o.login(); W.run(120)   -- hello from 1.1.0: both 1.2.0 answer with R, J, A and Z
  local ko = H.tod(o, "Alter", "Wolf"); W.run(20)
  local typen = {}
  for _, m in ipairs(W.sent) do typen[m.text:match("^1\t(%u)\t") or "?"] = true end
  H.erwartet("auf der Leitung waren H K R J A Z", typen.H and typen.K and typen.R and typen.J and typen.A and typen.Z,
    (function() local t = {} for k in pairs(typen) do t[#t + 1] = k end table.sort(t) return table.concat(t) end)())
  H.erwartet("1.1.0 hat die Tat von 1.2.0, 1.2.0 die von 1.1.0", o.ns.Guild.Get(ka) ~= nil and a.ns.Guild.Get(ko, "guild") ~= nil
    and b.ns.Guild.Get(ko, "guild") ~= nil)
  H.erwartet("1.2.0 untereinander: Freigabe da, abgeblasene weg", b.ns.Guild.Hunt("Zwei-Lamm", "guild") ~= nil
    and b.ns.Guild.Hunt("Ziel-Lamm", "guild") == nil)
end)

if hatMid then
H.lauf("(3) Zwischenstand: Datei weiterfuehren, und als Freund neben dem fertigen Stand", function()
  local W = H.welt()
  local c = W.client("Carla", "Klein", nil, { friends = { "Anton Wurst" }, fullSender = true, dir = MID })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Carla Klein" }, fullSender = true, dir = MID })
  c.login(); a.login(); W.run(90)
  local key = H.tod(c, "Taeter", "Lamm"); W.run(10)
  c.ns.Guild.Release("Ziel-Lamm", { to = "friends", why = "Grund" }); W.run(10)
  H.erwartet("Vorbedingung (Zwischenstand): Tat und Freigabe beim Freund", a.ns.Guild.Get(key, "friends") ~= nil
    and a.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil)
  local adb = H.raus(W, a); W.run(60)
  -- Anton upgrades; Carla is away this evening; one login every day for 20 days
  local cdb = H.raus(W, c); W.run(60)
  for tag = 1, 20 do
    H.tage(1)
    local x = W.client("Anton", "Wurst", nil, { db = adb, friends = { "Carla Klein" }, fullSender = true })
    x.login(); W.run(40); x.fire("FRIENDLIST_UPDATE"); W.run(10)
    if tag == 20 then
      H.erwartet("Datei des Zwischenstands unter 1.2.0, 20 Spieltage: Tat und Freigabe der Freundin noch da",
        x.ns.Guild.Get(key, "friends") ~= nil and x.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil)
    end
    adb = H.raus(W, x)
  end
  -- Carla stays on the interim build, Anton is final: mixed versions among friends
  local c2 = W.client("Carla", "Klein", nil, { db = cdb, friends = { "Anton Wurst" }, fullSender = true, dir = MID })
  local a2 = W.client("Anton", "Wurst", nil, { db = adb, friends = { "Carla Klein" }, fullSender = true })
  c2.login(); W.run(60)
  local kc0 = H.tod(c2, "Frueher", "Wolf"); W.run(20)   -- Anton is not there yet
  a2.login(); W.run(180)
  H.erwartet("fertiger Stand fragt den Zwischenstand per Hallo: dessen Tat aus der Abwesenheit kommt an",
    a2.ns.Guild.Get(kc0, "friends") ~= nil, "kommt nicht: der Zwischenstand verwirft das Hallo mit fuenf Feldern ("
    .. tostring(c2.ns.Friends.stats.lastReason) .. ")")
  local ka = H.tod(a2, "Neu", "Wolf"); W.run(20)
  local kc = H.tod(c2, "Neu2", "Wolf"); W.run(20)
  H.erwartet("Zwischenstand und fertiger Stand als Freunde: Live-Taten kommen in beide Richtungen an",
    c2.ns.Guild.Get(ka, "friends") ~= nil and a2.ns.Guild.Get(kc, "friends") ~= nil,
    "bei Carla: " .. tostring(c2.ns.Guild.Get(ka, "friends") ~= nil) .. ", bei Anton: " .. tostring(a2.ns.Guild.Get(kc, "friends") ~= nil)
    .. " (der Zwischenstand verwirft das Hallo mit fuenf Feldern: " .. tostring(c2.ns.Friends.stats.lastReason) .. ")")
end)
else
  io.write("  (3) uebersprungen: kein Zwischenstand unter " .. MID .. "\n")
end

H.fertig()
