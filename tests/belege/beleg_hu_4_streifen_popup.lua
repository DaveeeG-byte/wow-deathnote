-- Fund 4: Extras.PlaceBanner haelt die Meldung vom Alarm-Popup fern, rechnet aber nur mit der Meldung selbst
-- (92 hoch). Der Spruchstreifen haengt 4 darunter und ist 22 hoch. Liegt das (vom Spieler verschobene) Popup knapp
-- unter der Meldung, liegt der Streifen auf dem Popup.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function schnitt(a, b)   -- Rechtecke l, b, r, t
  local w = math.min(a[3], b[3]) - math.max(a[1], b[1])
  local h = math.min(a[4], b[4]) - math.max(a[2], b[2])
  return (w > 0 and h > 0) and h or 0
end
local function lage(y)
  local ns = H.welt("deDE")
  if y then ns.Store.Setting("alert.point", { "TOP", "TOP", 0, y }) end
  ns:Fire("TEST_ALERT"); H.settle()
  local popup = rawget(H.G, "DeathNoteAlert")
  H.kill(ns, "Klein", "Wicht", { level = 20 })     -- Taeter 20 Stufen darunter: Spruch (Wahrscheinlichkeit 1)
  local b = H.banner()
  local q = b and b.dnQuip
  if not (popup and popup:IsShown() and b and b:IsShown() and q and q:IsVisible()) then return nil end
  return schnitt({ H.rect(b) }, { H.rect(popup) }), schnitt({ H.rect(q) }, { H.rect(popup) })
end
local m, s = lage(nil)
H.check("Vorbedingung: Standardlage, Meldung und Streifen frei vom Popup", m == 0 and s == 0, tostring(m) .. "/" .. tostring(s))
m, s = lage(-300)
H.check("Vorbedingung: Popup auf der Meldung: Meldung weicht aus", m == 0, m)
H.check("Popup auf der Meldung: Streifen frei", s == 0, tostring(s) .. " Einheiten Ueberdeckung")
for _, y in ipairs({ -403, -407, -415, -425 }) do
  m, s = lage(y)
  H.check("Popup-Oberkante bei " .. y .. " (Meldung endet bei -402): Meldung frei", m == 0, m)
  H.check("Popup-Oberkante bei " .. y .. ": Spruchstreifen frei vom Popup", s == 0, tostring(s) .. " Einheiten Ueberdeckung")
end
H.ende("beleg_hu_4_streifen_popup")
