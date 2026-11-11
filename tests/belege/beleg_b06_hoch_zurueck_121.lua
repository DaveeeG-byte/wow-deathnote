-- 1.2.1: Upgrade-Kette mit der Fixture: 1.0.1-Datei -> 1.1.0 -> 1.2.0 -> 1.2.1 -> 1.2.0 -> 1.2.1, nichts geht verloren,
-- die neuen Felder (Kopfgeld, gerächt, Rache von Hand) ueberstehen den Rueckweg. Aufruf: luajit beleg_b06_... <Projektkopie>
-- Die Fixture wird nur geladen, nie zitiert.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"
local OLD = H.DIR .. "/tests/fixtures/addon-1.1.0/"
local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
local V120 = H.DIR .. "/tests/fixtures/addon-1.2.0/"
local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }

local function zaehle(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end return n end
local function summe(db, feld) local n = 0; for _, e in pairs(db.enemies or {}) do n = n + (tonumber(e[feld]) or 0) end return n end

H.lauf("Kette 1.0.1 -> 1.1.0 -> 1.2.0 -> 1.2.1 -> 1.2.0 -> 1.2.1", function()
  local fx = {}
  do local f = assert(loadfile(H.DIR .. "/tests/fixtures/sv_1.0.1_autor.lua")); setfenv(f, fx); f() end
  local eintraege, tode = zaehle(fx.DeathNoteDB.enemies), #(fx.DeathNoteDB.deaths or {})
  local kills, rache = summe(fx.DeathNoteDB, "kills"), summe(fx.DeathNoteDB, "revenge")
  H.erwartet("Vorbedingung: Fixture hat Eintraege und Tode", eintraege > 0 and tode > 0)
  local W = H.welt()
  local z = W.client("Zeuge", "Still", G, { fullSender = true })
  z.login(); W.run(30)
  local function stufe(dir, files, db, version)
    local c = W.client("Anton", "Wurst", G, { db = db, dir = dir, files = files, lang = dir == OLD and false or nil,
      fullSender = true, version = version })
    c.login(); W.run(60)
    return c
  end
  local c = stufe(OLD, OLDFILES, H.tiefe_kopie(fx.DeathNoteDB), "1.1.0")
  local db = H.raus(W, c)
  c = stufe(V120, FILES120, db, "1.2.0")
  c.ns.Guild.Release("Ziel-Eins", { to = "guild", why = "Grund" }); W.run(10)
  db = H.raus(W, c)
  -- 1.2.1: alles Neue benutzen
  c = stufe(nil, nil, db, "1.2.1")
  local ek
  for k, e in pairs(c.ns.Store.All()) do if (e.kills or 0) > 0 then ek = k; break end end
  c.ns.Store.AddRevenge(ek, true)
  c.ns.Guild.SetBounty(ek, 321); c.ns.Guild.SetBounty("Ziel-Eins", 50)
  z.ns.Guild.SetBounty("Zeuge-Ziel", 77); W.run(10)
  c.ns.Bounty.Record(ek, "Zeuge Still", time())
  W.run(10)
  local mitte = H.tiefe_kopie(H.raus(W, c))
  H.erwartet("1.2.1 schreibt die neuen Felder", mitte.bounty and mitte.bounty[ek] and mitte.avenged and mitte.avenged[ek]
    and mitte.enemies[ek].revengeHand == 1 and mitte.guild.lists[G].bounty and mitte.guild.lists[G].bounty["Zeuge-Ziel"])
  -- zurueck auf 1.2.0: spielt, stuerzt nicht, laesst alles Neue stehen
  c = stufe(V120, FILES120, H.tiefe_kopie(mitte), "1.2.0")
  c.ns.Store.AddRevenge(ek)
  H.tod(c, "Neu", "Wolf"); W.run(10)
  z.ns.Guild.SyncNow(); W.run(60)
  H.erwartet("1.2.0: keine Fehler", #M.errors == 0, M.errors[1])
  db = H.raus(W, c)
  H.erwartet("1.2.0 laesst Kopfgeld, gerächt und Merker stehen", db.bounty and db.bounty[ek] and db.bounty[ek]["Anton Wurst"]
    and db.bounty[ek]["Anton Wurst"].g == 321 and db.avenged and db.avenged[ek] and db.enemies[ek].revengeHand == 1
    and db.guild.lists[G].bounty and db.guild.lists[G].bounty["Zeuge-Ziel"])
  -- wieder hoch
  c = stufe(nil, nil, db, "1.2.1")
  local e = c.ns.Store.Get(ek)
  H.erwartet("wieder 1.2.1: Rache 2 mehr als vorher, davon 1 abziehbar", e.revenge == (tonumber(fx.DeathNoteDB.enemies[ek]
    and fx.DeathNoteDB.enemies[ek].revenge) or 0) + 2 and c.ns.Store.HandRevenge(e) == 1, e.revenge)
  H.erwartet("wieder 1.2.1: eigenes Kopfgeld, fremdes, gerächt", c.ns.Guild.OwnBounty(ek) == 321
    and c.ns.Guild.HasBounty("Zeuge-Ziel") and select(2, c.ns.Guild.Avenged(ek)) == 1)
  local enddb = c.env.DeathNoteDB
  H.erwartet("nichts verloren: Eintraege", zaehle(enddb.enemies) >= eintraege + 1, zaehle(enddb.enemies) .. " >= " .. eintraege + 1)
  H.erwartet("nichts verloren: Tode im Journal", #enddb.deaths >= tode, #enddb.deaths)
  H.erwartet("nichts verloren: Kills", summe(enddb, "kills") >= kills + 1)
  H.erwartet("Rache: Fixture plus zwei", summe(enddb, "revenge") == rache + 2, summe(enddb, "revenge") .. " / " .. rache + 2)
  H.erwartet("Freigabe aus 1.2.0 steht", c.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.fertig()
