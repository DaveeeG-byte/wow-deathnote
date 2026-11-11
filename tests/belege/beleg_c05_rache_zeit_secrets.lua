-- 1.2.1 nach der Jagd (N5 und jagd-b N3, N6): "letzte Rache" nach dem Abziehen ist die Zeit der neuesten Rache, die
-- bleibt; Bounty.Record und Store.HandRevenge vertragen Secret-Values.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M

H.lauf("(1) Menue-Abziehen: 'letzte Rache' zeigt die verbliebene (erkannte) Rache", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { fullSender = true })
  a.login(); W.run(30)
  local key = H.tod(a, "Taeter", "Lamm")
  local S = a.ns.Store
  S.AddRevenge(key); local t1 = S.Get(key).lastRevenge
  M.Advance(3600)
  S.AddRevenge(key, true)
  M.Advance(60)
  H.erwartet("abziehen geht", S.UndoRevenge(key) == true)
  local e = S.Get(key)
  H.erwartet("Zaehler 1, Merker weg", e.revenge == 1 and e.revengeHand == nil)
  H.erwartet("letzte Rache = die erkannte", e.lastRevenge == t1, (e.lastRevenge or 0) - t1)
  H.erwartet("erkannte nicht abziehbar", S.UndoRevenge(key) == false)
end)

H.lauf("(2) von Hand, 3 s spaeter erkannt, dann Rueckgaengig: letzte Rache = die erkannte", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { fullSender = true })
  a.login(); W.run(30)
  local key = H.tod(a, "Taeter", "Lamm")
  local S = a.ns.Store
  S.AddRevenge(key); M.Advance(120)
  local prev = S.Get(key).lastRevenge
  S.AddRevenge(key, true); M.Advance(3)
  S.AddRevenge(key); local t3 = S.Get(key).lastRevenge
  M.Advance(1)
  S.UndoRevenge(key, prev)            -- wie der Knopf "Rueckgaengig" (kennt die Zeit davor)
  local e = S.Get(key)
  H.erwartet("Rache 2, keine von Hand", e.revenge == 2 and e.revengeHand == nil)
  H.erwartet("letzte Rache = die erkannte 3 s danach", e.lastRevenge == t3, (e.lastRevenge or 0) - t3)
end)

H.lauf("(3) zwei von Hand, eine abgezogen: letzte Rache = die erste von Hand; alles weg: keine Zeit", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { fullSender = true })
  a.login(); W.run(30)
  local key = H.tod(a, "Taeter", "Lamm")
  local S = a.ns.Store
  S.AddRevenge(key, true); local h1 = S.Get(key).lastRevenge
  M.Advance(500)
  S.AddRevenge(key, true)
  S.UndoRevenge(key)
  H.erwartet("letzte Rache = erste von Hand", S.Get(key).lastRevenge == h1)
  S.UndoRevenge(key)
  H.erwartet("keine Rache, keine Zeit", S.Get(key).revenge == 0 and S.Get(key).lastRevenge == nil)
  -- kaputte Zeitliste aus der Datei: wird repariert, Abziehen geht weiter
  S.AddRevenge(key, true); S.Get(key).revengeHandAt = { "x", 1 / 0 }
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  H.erwartet("kaputte Liste repariert, Abziehen geht", a2.ns.Store.Get(key).revengeHandAt == nil and a2.ns.Store.UndoRevenge(key) == true)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(4) N6: Secret-Values an Bounty.Record und Store.HandRevenge", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", "Die Testgilde", { fullSender = true })
  a.login(); W.run(30)
  local key = H.tod(a, "Taeter", "Lamm")
  local ok1 = pcall(a.ns.Bounty.Record, key, M.Secret("s"), time())
  local ok2 = pcall(a.ns.Bounty.Record, M.Secret("s"), "Anton Wurst", time())
  local ok3 = pcall(a.ns.Bounty.Record, key, "Anton Wurst", M.Secret("n", "number"))
  local ok4 = pcall(a.ns.Store.HandRevenge, M.SecretTable())
  H.erwartet("Record mit Secret wirft nicht", ok1 and ok2 and ok3)
  H.erwartet("HandRevenge mit Secret-Tabelle wirft nicht", ok4)
  H.erwartet("nichts Geheimes gespeichert", next(a.env.DeathNoteDB.avenged or {}) == nil)
end)
H.fertig()
