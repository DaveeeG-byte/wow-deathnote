-- 1.2.1: Rache rueckgaengig machen (nur die von Hand vermerkte). Aufruf: luajit beleg_b02_rache_abziehen.lua <Projektkopie>
-- Logik und Daten; die Oberflaeche (Knopf "Rueckgaengig", Menue, Meldung, Meilenstein) prueft beleg_ui_7.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

local function buch()
  local ns = M.Load()
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "MAGE", level = 40 },
    { t = time() - 500, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  return ns, key
end

H.lauf("(1) von Hand vermerkt: getrennt gezaehlt, genau eine zuruecknehmbar", function()
  local ns, key = buch()
  local S = ns.Store
  local e = S.Get(key)
  local wert0 = S.Bounty(e)
  S.AddRevenge(key, true)
  H.erwartet("Rache 1, davon von Hand 1", e.revenge == 1 and e.revengeHand == 1 and S.HandRevenge(e) == 1)
  H.erwartet("Kopfgeld folgt dem Zaehler (sinkt)", S.Bounty(e) < wert0)
  local t1 = e.lastRevenge
  M.Advance(30)
  S.AddRevenge(key, true)
  H.erwartet("zwei von Hand", e.revenge == 2 and e.revengeHand == 2)
  H.erwartet("rueckgaengig mit der Zeit davor", S.UndoRevenge(key, t1) and e.revenge == 1 and e.lastRevenge == t1)
  H.erwartet("noch eine", S.UndoRevenge(key) and e.revenge == 0 and e.revengeHand == nil and e.lastRevenge == nil)
  H.erwartet("Kopfgeld wieder wie vorher", S.Bounty(e) == wert0)
  H.erwartet("mehr gibt es nicht", S.UndoRevenge(key) == false and e.revenge == 0)
  local undone = 0
  ns:On("REVENGE_UNDONE", function() undone = undone + 1 end)
  S.AddRevenge(key, true); S.UndoRevenge(key)
  H.erwartet("REVENGE_UNDONE feuert", undone == 1)
end)

H.lauf("(2) vom Buch erkannt (Todesstoss, Ehre) und Bestand aus 1.2.0: bleibt", function()
  local ns, key = buch()
  local S = ns.Store
  local e = S.Get(key)
  -- erkannt: Todesstoss (PARTY_KILL mit der eigenen GUID), in der offenen Welt
  M.units.target = nil
  M.AddEnemy("target", { name = "Grimm", surname = "Bart", guid = "Player-93-0BAD0BAD" })
  e.guid = "Player-93-0BAD0BAD"
  S.Init()
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-0BAD0BAD")
  e = S.Get(key)
  H.erwartet("Vorbedingung: Todesstoss zaehlt als Rache", e.revenge == 1, e.revenge)
  H.erwartet("erkannte Rache ist nicht abziehbar", S.HandRevenge(e) == 0 and S.UndoRevenge(key) == false and e.revenge == 1)
  S.AddRevenge(key, true)
  H.erwartet("von Hand dazu: nur diese abziehbar", S.UndoRevenge(key) and e.revenge == 1 and S.UndoRevenge(key) == false)
  -- Buch aus 1.2.0: Rache ohne Merker gilt als erkannt
  local alt = H.tiefe_kopie(_G.DeathNoteDB)
  alt.enemies[key].revenge, alt.enemies[key].revengeHand = 3, nil
  local ns2 = M.Load({ db = alt })
  H.erwartet("Buch aus 1.2.0: nichts abziehbar", ns2.Store.HandRevenge(ns2.Store.Get(key)) == 0 and ns2.Store.UndoRevenge(key) == false)
end)

H.lauf("(3) kaputte oder zu grosse Merker werden repariert, nie mehr als die Rache", function()
  for _, v in ipairs({ { 5, 2 }, { "x", 1 }, { -1, 1 }, { 0 / 0, 2 }, { 2.7, 3 }, { math.huge, 1 } }) do
    local db = { version = 3, enemies = { ["Grimm-Bart"] = { name = "Grimm", surname = "Bart", kills = 1, revenge = v[2],
      revengeHand = v[1], deaths = {} } } }
    local ns = M.Load({ db = db })
    local e = ns.Store.Get("Grimm-Bart")
    local h = e.revengeHand
    H.erwartet("Merker " .. tostring(v[1]) .. " bei Rache " .. v[2] .. ": gueltig",
      (h == nil or (type(h) == "number" and h >= 1 and h <= e.revenge and h == math.floor(h))) and #M.errors == 0, tostring(h))
  end
end)

H.lauf("(4) Rueckweg: 1.2.0 liest das Buch mit Merker, 1.2.1 danach wieder", function()
  local ns, key = buch()
  ns.Store.AddRevenge(key, true); ns.Store.AddRevenge(key)
  local db = H.tiefe_kopie(_G.DeathNoteDB)
  M.Reset()
  local W = M.NewWorld()
  local old = W.client("Varorak", "Narenmar", nil, { db = db, dir = H.DIR .. "/tests/fixtures/addon-1.2.0/",
    files = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua",
      "Probe.lua", "Sync.lua", "Friends.lua" } })
  old.login(); W.run(30)
  local e = old.ns.Store.Get(key)
  H.erwartet("1.2.0: Rache 2, Merker steht noch", e.revenge == 2 and e.revengeHand == 1 and #M.errors == 0, M.errors[1])
  old.ns.Store.AddRevenge(key)    -- unter 1.2.0 vermerkt (ohne Merker)
  local db2 = H.raus(W, old)
  local neu = W.client("Varorak", "Narenmar", nil, { db = db2 })
  neu.login(); W.run(30)
  local e2 = neu.ns.Store.Get(key)
  H.erwartet("wieder 1.2.1: Rache 3, davon 1 abziehbar", e2.revenge == 3 and neu.ns.Store.HandRevenge(e2) == 1)
end)

H.fertig()
