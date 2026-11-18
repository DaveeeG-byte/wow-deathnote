-- 1.6.0 feud: play days in DeathNoteDB.days (lifted from the friends' book), the expiry of old suspicions and attacks
-- after 30 play days without a deed or a sighting (archive "Filed", at most 200, back with Take back), what never
-- expires, the hard cap of 3000 entries and the probe's death records only with /dn debug. All names are made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function relogin(ns, days)
  -- a later calendar day with a login: the start counts one play day and expires
  local db = ns.Store.DB()
  for _ = 1, days or 1 do
    M.epoch = M.epoch + 86400
    ns.Store.Init()
  end
  return db
end
local function suspect(S, name, t)
  return S.ApplyKill({ name = name, surname = "Ling", guid = "Player-93-" .. name }, { t = t or time() - 50, zone = "Z" }, false)
end

test("Spieltage: aus dem Freundesbuch gehoben, ein Tag zaehlt einmal, Kopie fuer 1.5.0", function()
  -- the mock's clock after M.Reset: epoch 1700000000, now 1000
  local ns = M.Load({ db = { friends = { days = 12, dayAt = math.floor((1700000000 + 1000) / 86400) } } })
  local db = ns.Store.DB()
  eq(db.days, 12, "derselbe Kalendertag: nicht doppelt")
  ns.Store.Init(); ns.Store.Init()
  eq(db.days, 12)
  relogin(ns, 1)
  eq(db.days, 13); eq(db.friends.days, 13, "Kopie im Freundesbuch")
  -- the friends' book reads the same counter
  ns.Friends.Init()
  eq(db.friends.days, 13)
end)

test("Nach 30 Spieltagen ohne Neues: Verdacht und reine Angriffe abgelegt, mit Zeile", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Alt")
  S.AddAttack({ name = "Hau", surname = "Drauf", guid = "Player-93-Hau" }, { t = time() - 40, zone = "Z" })
  local db = relogin(ns, 29)
  ok(S.Get("Alt-Ling") and S.Get("Hau-Drauf"), "nach 29 Tagen noch da")
  -- the 30th play day: a real login (start, then READY with the chat line a few seconds later)
  M.chat = {}
  M.epoch = M.epoch + 86400
  M.FireEvent("PLAYER_LOGIN"); M.Advance(7)
  eq(S.Get("Alt-Ling"), nil); eq(S.Get("Hau-Drauf"), nil)
  ok(db.expired["Alt-Ling"] and db.expired["Hau-Drauf"], "im Archiv")
  eq(ns.Feud.lastExpired, 2)
  local want = ns.F(ns.L.FEUD_EXPIRED_CHAT, { count = 2 })
  local said = false
  for _, l in ipairs(M.chat) do if tostring(l):find(want, 1, true) then said = true end end
  ok(said, "Zeile im Chat: " .. tostring(M.chat[#M.chat]))
end)

test("Eine Sichtung oder neue Tat haelt den Eintrag", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Alt")
  relogin(ns, 20)
  S.Seen("Alt-Ling", {}, { t = time(), zone = "Z" }, true)
  relogin(ns, 20)
  ok(S.Get("Alt-Ling"), "Sichtung vor 20 Tagen: bleibt")
  relogin(ns, 10)
  eq(S.Get("Alt-Ling"), nil, "30 Tage nach der Sichtung: abgelegt")
end)

test("Nie abgelegt: getoetet, Hand, Abschussliste, Kopfgeld, Fehde-Gilde, behalten, Rache", function()
  local ns = M.Load()
  local S = ns.Store
  local db = S.DB()
  S.ApplyKill({ name = "Moerder", surname = "Ling" }, { t = time() - 50, zone = "Z", source = "recap" }, true)
  S.AddManual("Hand", "Ling")
  suspect(S, "Liste"); suspect(S, "Preis"); suspect(S, "Fehde"); suspect(S, "Bleib"); suspect(S, "Rache")
  S.Get("Fehde-Ling").guild = "Rote Hand"
  db.feuds = { ["Rote Hand"] = { t = time() } }
  db.bounty = { ["Preis-Ling"] = { ["Ich Selbst"] = { g = 5, t = time() } } }
  db.guild = { lists = { [ "Die Testgilde" ] = { hunts = { ["Liste-Ling"] = { key = "Liste-Ling" } } } } }
  ns.Feud.SetKeep("Bleib-Ling", true)
  S.AddRevenge("Rache-Ling")
  relogin(ns, 40)
  for _, k in ipairs({ "Moerder-Ling", "Hand-Ling", "Liste-Ling", "Preis-Ling", "Fehde-Ling", "Bleib-Ling", "Rache-Ling" }) do
    ok(S.Get(k), k .. " bleibt")
  end
end)

test("Zurueckholen: wieder im Buch, behalten, faellt nicht gleich wieder", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Alt")
  local db = relogin(ns, 30)
  eq(S.Get("Alt-Ling"), nil)
  ok(ns.Feud.Restore("Alt-Ling"))
  local e = S.Get("Alt-Ling")
  ok(e and e.keep == true, "behalten"); eq(db.expired["Alt-Ling"], nil); eq(e.expiredAt, nil)
  eq(S.Find("Alt Ling"), "Alt-Ling", "Index stimmt")
  relogin(ns, 40)
  ok(S.Get("Alt-Ling"), "bleibt")
  -- a key taken meanwhile: the archived one goes, the book keeps its entry
  suspect(S, "Zwei")
  relogin(ns, 30)
  suspect(S, "Zwei")
  eq(ns.Feud.Restore("Zwei-Ling"), false)
  eq(db.expired["Zwei-Ling"], nil)
end)

test("Schalter aus: nichts abgelegt", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Alt")
  S.Setting("book.expire", false)
  relogin(ns, 40)
  ok(S.Get("Alt-Ling"))
  no(ns.Feud.ExpireOn())
end)

test("Archiv hoechstens 200, die aeltesten gehen", function()
  local ns = M.Load()
  local S = ns.Store
  for i = 1, 150 do suspect(S, "A" .. i) end
  relogin(ns, 30)
  for i = 1, 100 do suspect(S, "B" .. i) end
  relogin(ns, 30)
  local db = S.DB()
  eq(ns.Feud.ExpiredCount(), 200)
  eq(db.expired["B1-Ling"] ~= nil, true, "neue da")
  local a = 0
  for k in pairs(db.expired) do if k:find("^A") then a = a + 1 end end
  eq(a, 100, "50 der ersten Welle gingen")
end)

test("Harter Deckel 3000: erst das Archiv, dann die aeltesten Verdachtsfaelle, Tode nie", function()
  local enemies, expired = {}, {}
  local t0 = 1700000000
  for i = 1, 2990 do
    enemies["Tod" .. i .. "-Ling"] = { kills = 1, deaths = { { t = t0 + i, role = "kill", sure = true } }, day = 0 }
  end
  for i = 1, 30 do
    enemies["Verd" .. i .. "-Ling"] = { suspected = 1, status = "suspect", deaths = { { t = t0 + i, role = "suspect" } }, day = 0 }
  end
  for i = 1, 20 do expired["Alt" .. i .. "-Ling"] = { suspected = 1, expiredAt = t0 + i, deaths = {} } end
  local ns = M.Load({ db = { enemies = enemies, expired = expired, days = 0, dayAt = 0, settings = { book = { expire = false } } } })
  local n, v = 0, 0
  for k in pairs(ns.Store.All()) do n = n + 1; if k:find("^Verd") then v = v + 1 end end
  eq(ns.Feud.ExpiredCount(), 0, "Archiv zuerst leer")
  eq(n, 3000, "Buch auf 3000")
  eq(v, 10, "die 20 aeltesten Verdachtsfaelle gingen")
  ok(ns.Store.Get("Verd30-Ling") and not ns.Store.Get("Verd1-Ling"), "die neuesten bleiben")
  for i = 1, 2990 do if not ns.Store.Get("Tod" .. i .. "-Ling") then error("Tod" .. i .. " fehlt") end end
end)

test("Sonde: Todesprotokolle nur mit /dn debug", function()
  local ns = M.Load({ db = { probe = { deaths = { { t = 1 }, { t = 2 } }, apis = { x = 1 } }, settings = { debug = false } } })
  local db = ns.Store.DB()
  eq(#db.probe.deaths, 0, "ohne debug geleert")
  eq(db.probe.apis.x, 1, "der Rest bleibt")
  local ns2 = M.Load({ db = { probe = { deaths = { { t = 1 } } }, settings = { debug = true } } })
  eq(#ns2.Store.DB().probe.deaths, 1, "mit debug bleibt es")
end)

test("Kaputtes Archiv repariert", function()
  local ns = M.Load({ db = { expired = { ["Gut-Ling"] = { expiredAt = 5 }, ["Ohne-Zeit"] = {}, [7] = { expiredAt = 1 }, ["X-Y"] = "z" } } })
  eq(ns.Feud.ExpiredCount(), 1)
  local ns2 = M.Load({ db = { expired = "kaputt" } })
  eq(ns2.Feud.ExpiredCount(), 0)
end)

M.done("fe160_verfall")
