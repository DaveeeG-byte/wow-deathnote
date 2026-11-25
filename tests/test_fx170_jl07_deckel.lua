-- 1.7.0 fix JL-9 (copy of the hunt's jl07, plus a run with 50 open claims). jl07: Feud.AddClaim fuegt ein, raeumt auf (sortiert nach Kill-Zeit, Deckel MAX_CLAIMS = 50) und gibt den Anspruch
-- zurueck, auch wenn das Aufraeumen ihn gerade wieder entfernt hat. Ein C fuer einen Kill, der aelter ist als 50
-- vorhandene Ansprueche: CLAIM_NEW feuert (Zettel "Kopfgeld faellig"), der Schuetze bekommt Q 0 "offen", aber der
-- Anspruch steht nicht in der Liste, Feud.SetClaim gibt false, und jedes weitere Hallo meldet ihn erneut.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("50 juengere Ansprueche, dann ein C fuer einen aelteren Kill", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  local kt = K.earned(a)[1].t
  M.Advance(86400)
  local db = b2.env.DeathNoteDB
  db.claims = db.claims or {}
  for i = 1, 50 do
    db.claims[#db.claims + 1] = { key = K.KEY2, by = "Egon Eck", t = kt + i * 100, g = 5, state = "declined", char = "Berta Senf" }
  end
  b2.login(); W.run(120)
  local gemeldet
  for _, e in ipairs(b2.events) do if e[1] == "CLAIM_NEW" then gemeldet = e[2] end end
  local drin = false
  for _, y in ipairs(K.claims(b2)) do if y == gemeldet then drin = true end end
  local x = K.earned(a)[1] or {}
  H.erwartet("gemeldeter Anspruch steht in der Liste (oder wird nicht gemeldet und nicht als offen quittiert)",
    (gemeldet == nil and x.state ~= "open") or drin, "CLAIM_NEW=" .. tostring(gemeldet ~= nil) .. " in Liste=" .. tostring(drin) .. " Schuetze=" .. tostring(x.state))
  M.Advance(700); b2.ns.Guild.SyncNow(); W.run(60)
  H.erwartet("kein zweites CLAIM_NEW fuer denselben Kill", H.zaehle(b2, "CLAIM_NEW") <= 1, H.zaehle(b2, "CLAIM_NEW"))
end)

H.lauf("50 juengere offene Ansprueche: der aeltere Kill wird nicht gemeldet und nicht als offen quittiert", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local b2 = K.weg(W, b)
  K.toetet(a); W.run(10)
  local kt = K.earned(a)[1].t
  M.Advance(86400)
  local db = b2.env.DeathNoteDB
  db.claims = db.claims or {}
  for i = 1, 50 do
    db.claims[#db.claims + 1] = { key = K.KEY2, by = "Egon Eck", t = kt + i * 100, g = 5, state = "open", char = "Berta Senf" }
  end
  b2.login(); W.run(120)
  H.erwartet("kein CLAIM_NEW", H.zaehle(b2, "CLAIM_NEW") == 0, H.zaehle(b2, "CLAIM_NEW"))
  H.erwartet("50 offene bleiben", #K.claims(b2) == 50 and K.claims(b2)[50].by == "Egon Eck", #K.claims(b2))
  H.erwartet("Schuetze nicht 'offen'", (K.earned(a)[1] or {}).state ~= "open", (K.earned(a)[1] or {}).state)
end)

H.fertig()
