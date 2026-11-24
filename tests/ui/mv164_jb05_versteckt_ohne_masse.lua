-- jb05 (niedrig, Attrappe freundlicher als der Client; im Spiel zu messen): Extras.PlaceBanner misst die gehaltene
-- Meldung ueber Look.Rect, und Banner() ruft PlaceBanner VOR banner:Show(). Liefert der Client fuer einen versteckten
-- Frame keine Masse (GetLeft = nil), gibt HeldPlace "true" zurueck und die Meldung weicht dem Alarm nicht aus:
-- sie liegt dann auf dem Alarm. 1.6.3 rechnete nur mit Konstanten und brauchte keine Masse.
-- Nachgestellt: GetLeft/GetBottom/GetRight/GetTop der Meldung liefern nil, solange sie versteckt ist.
-- Erwartet: gehaltene Meldung auf der Stelle des Alarms + stehender Alarm -> keine Ueberdeckung.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db() })
W.ns.Store.AddManual("Velka Thornheart")
-- die Meldung im Modus auf die Standardlage des Alarms ziehen (der Alarm weicht nicht, die Meldung soll es tun)
W.slash("move")
local a, b = W.frame("DeathNoteAlert"), W.frame("DeathNoteBanner")
local al, ab = W.rect(a)
W.slash("move")
W.ns.Store.Setting("notice.point", { "BOTTOMLEFT", "BOTTOMLEFT", al + 10, ab + 10 })
local function overlap()
  local l1, b1, r1, t1 = W.rect(a)
  local l2, b2, r2, t2 = W.rect(b)
  return l1 < r2 and r1 > l2 and b1 < t2 and t1 > b2
end
-- Gegenprobe mit Massen (gruen)
W.ns:Fire("TEST_ALERT"); W.tick(0.5)
W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
J.check("Gegenprobe mit Massen: Meldung weicht dem Alarm", a:IsShown() and b:IsShown() and not overlap())
W.settle()
-- jetzt wie ein Client, der fuer versteckte Frames nichts misst
for _, m in ipairs({ "GetLeft", "GetBottom", "GetRight", "GetTop" }) do
  local real = b[m]
  b[m] = function(self, ...) if not self:IsShown() then return nil end return real(self, ...) end
end
W.ns:Fire("TEST_ALERT"); W.tick(0.5)
W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
J.check("ohne Masse im versteckten Zustand: Meldung weicht dem Alarm", a:IsShown() and b:IsShown() and not overlap())
J.done("jb05")
