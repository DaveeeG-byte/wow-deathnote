-- 1.2.1 nach der Abschluss-Jagd: die Felder des Fix-Stands (tie.hg, revengeHandAt, revengeAutoAt) auf dem Weg
-- 1.2.1 -> 1.1.0 -> 1.2.0 -> 1.2.1: keine Lua-Fehler, nichts verloren, Abziehen geht danach weiter, und eine auf 1.2.0
-- erkannte Rache bleibt nach dem Abziehen die letzte (nicht die aeltere Zeit von vor dem Rueckweg).
-- Dazu die Fixture 1.0.1 direkt in diesen Stand und von dort zurueck nach 1.1.0 (nie zitiert, nur gezaehlt).
-- Aufruf: nice -n 15 luajit beleg_d02_rache_rueckweg.lua <Projektkopie>. Alle Namen erfunden.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M
local G = "Die Testgilde"
local OLD = H.DIR .. "/tests/fixtures/addon-1.1.0/"
local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
local V120 = H.DIR .. "/tests/fixtures/addon-1.2.0/"
local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }
local function zaehle(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end return n end
H.lauf("Fix-Felder auf dem Rueckweg", function()
  local W = H.welt(); W.guids = true
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local function stufe(dir, files, db, version)
    local c = W.client("Anton", "Wurst", G, { db = db, dir = dir, files = files, lang = dir == OLD and false or nil,
      fullSender = true, version = version, friends = { "Berta" } })
    c.login(); W.run(90)
    return c
  end
  local a = stufe(nil, nil, nil, "1.2.1")
  local gfi = a.env.C_FriendList.GetFriendInfoByIndex
  a.env.C_FriendList.GetFriendInfoByIndex = function(i) local f = gfi(i); if f then f.guid = nil end; return f end
  b.login(); W.run(120)
  a.ns.Friends.SyncNow(); W.run(120)
  local k = H.tod(a, "Taeter", "Lamm"); W.run(5)
  a.ns.Store.AddRevenge(k); W.run(1); M.epoch = M.epoch + 50
  a.ns.Store.AddRevenge(k, true); M.epoch = M.epoch + 50; a.ns.Store.AddRevenge(k, true)
  H.tod(b, "Boese", "Wicht"); b.ns.Guild.SetBounty("Boese-Wicht", 99); W.run(20)
  local db = H.raus(W, a)
  local tie = db.friends.ties["Berta"]
  local e = db.enemies[k]
  H.erwartet("Vorbedingung: Fix-Felder geschrieben (tie.hg, revengeHandAt, revengeAutoAt)", tie and tie.hg and type(e.revengeHandAt) == "table"
    and #e.revengeHandAt == 2 and e.revengeAutoAt, tostring(tie and tie.hg) .. "/" .. tostring(e.revengeHandAt and #e.revengeHandAt))
  local fb = zaehle(db.friends.bounty)
  -- 1.1.0
  a = stufe(OLD, OLDFILES, db, "1.1.0")
  H.tod(a, "Neu", "Wolf"); W.run(30)
  H.erwartet("1.1.0: keine Fehler", #M.errors == 0, M.errors[1])
  db = H.raus(W, a)
  -- 1.2.0
  a = stufe(V120, FILES120, db, "1.2.0")
  a.ns.Store.AddRevenge(k); W.run(30)
  if a.ns.Friends and a.ns.Friends.SyncNow then a.ns.Friends.SyncNow() end; W.run(60)
  H.erwartet("1.2.0: keine Fehler", #M.errors == 0, M.errors[1])
  db = H.raus(W, a)
  e = db.enemies[k]
  H.erwartet("alte Staende lassen die Felder stehen", type(e.revengeHandAt) == "table" and #e.revengeHandAt == 2 and e.revengeHand == 2 and e.revenge == 4,
    tostring(e.revenge) .. "/" .. tostring(e.revengeHand))
  H.erwartet("Kopfgeld der Freundin steht noch im Freundesbuch", zaehle(db.friends.bounty) == fb, zaehle(db.friends.bounty))
  -- wieder 1.2.1
  a = stufe(nil, nil, db, "1.2.1"); W.run(60)
  H.erwartet("1.2.1: keine Fehler", #M.errors == 0, M.errors[1])
  local x = a.ns.Store.Get(k)
  local last120 = x.lastRevenge
  H.erwartet("zwei Hand-Rachen weiter abziehbar", a.ns.Store.HandRevenge(x) == 2)
  a.ns.Store.UndoRevenge(k); a.ns.Store.UndoRevenge(k)
  H.erwartet("nach zweimal Abziehen: 2 erkannte bleiben", x.revenge == 2 and x.revengeHand == nil, tostring(x.revenge))
  -- die auf 1.2.0 erkannte Rache ist die neueste; revengeAutoAt stammt aber von vor dem Rueckweg
  print(("   lastRevenge nach dem Abziehen: %s, Zeit der auf 1.2.0 erkannten Rache: %s, revengeAutoAt: %s"):format(tostring(x.lastRevenge), tostring(last120), tostring(x.revengeAutoAt)))
  H.erwartet("'letzte Rache' zeigt die auf 1.2.0 erkannte (neueste), nicht eine aeltere", x.lastRevenge == last120, (last120 or 0) - (x.lastRevenge or 0) .. " s zu alt")
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Bindung samt Hallo-GUID noch da", tie and tie.full == "Berta Senf" and tie.hg ~= nil, tostring(tie and tie.full))
end)
H.lauf("Fixture 1.0.1 direkt in den Fix-Stand, dann 1.1.0, dann wieder Fix", function()
  local fx = {}
  do local f = assert(loadfile(H.DIR .. "/tests/fixtures/sv_1.0.1_autor.lua")); setfenv(f, fx); f() end
  local n0, t0 = zaehle(fx.DeathNoteDB.enemies), #(fx.DeathNoteDB.deaths or {})
  local W = H.welt()
  local function stufe(dir, files, db, version)
    local c = W.client("Anton", "Wurst", G, { db = db, dir = dir, files = files, lang = dir == OLD and false or nil, fullSender = true, version = version })
    c.login(); W.run(60); return c
  end
  local a = stufe(nil, nil, H.tiefe_kopie(fx.DeathNoteDB), "1.2.1")
  H.erwartet("Fix: keine Fehler", #M.errors == 0)
  local db = H.raus(W, a)
  a = stufe(OLD, OLDFILES, db, "1.1.0"); H.erwartet("1.1.0: keine Fehler", #M.errors == 0)
  db = H.raus(W, a)
  a = stufe(nil, nil, db, "1.2.1"); H.erwartet("Fix wieder: keine Fehler", #M.errors == 0)
  db = H.raus(W, a)
  H.erwartet("Eintraege und Tode vollzaehlig", zaehle(db.enemies) == n0 and #(db.deaths or {}) == t0, zaehle(db.enemies) .. "/" .. n0)
end)
H.fertig()
