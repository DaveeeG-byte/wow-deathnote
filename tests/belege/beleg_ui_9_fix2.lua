-- 1.2.1 nach der Abschluss-Jagd, Oberflaeche: der Kopf des Tooltips "gerächt" endet in keiner Sprache mit einem
-- Doppelpunkt (auch nicht mit dem vollbreiten in zhCN und zhTW) oder Leerraum.
-- Aufruf: nice -n 15 luajit beleg_ui_9_fix2.lua <Projektkopie>. Alle Namen erfunden.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

for _, code in ipairs(K.CODES) do
  local W = K.world(code)
  local ns, t = W.ns, _G.time()
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "MAGE", level = 40 },
    { t = t - 100, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  W.tick(40); W.settle()
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local E = W.frameWith(function(f) return f.stampNr1 and f.hunt end)
  local db = ns.Store.DB()
  db.avenged = { [key] = { by = { ["Bertram Wurst"] = 2, ["Cordula Wurst"] = 1 }, log = {}, t = t } }
  W.tick(1); ns.UI.ShowEnemy(key); W.tick()
  local tip = E and E.avengedHit and E.avengedHit.tip
  local head = tip and tip[1] or ""
  K.check(code .. " Tooltip gerächt da", tip ~= nil and #tip >= 3)
  K.check(code .. " Kopf ohne Doppelpunkt am Ende", head ~= "" and not head:find("[%s:]$") and not head:find("\239\188\154$"), head)
  local n, e = W.errs(); K.check(code .. " keine Fehler", n == 0, e)
end
K.done("beleg_ui_9 fix2")
