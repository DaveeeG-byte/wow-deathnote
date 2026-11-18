-- Copy of the efficiency hunter's test (fixer 2 1.6.0), red on b55addb; helper tests/_je.lua.
-- Jagd 2 Effizienz 05 (niedrig): Im Kampf gegen Spieler feuert Grudge.lua consider() bei jedem Blick auf einen schon
-- gemeldeten Angreifer GRUDGE_UPDATE (jeder Treffer auf mich liest alle Plaketten, dazu jeder Zauber, Zielwechsel,
-- UNIT_TARGET), und GrudgeCard.lua fuellt die Meldung jedes Mal ganz neu, auch wenn keine Zeile sich geaendert hat.
-- Gemessen (Attrappe, luajit -joff, 30 s Kampf gegen 5 unbekannte Spieler): 845 GRUDGE_UPDATE (28 je Sekunde) fuer 5
-- gleichbleibende Zeilen, dabei 96.276 Widget-Aufrufe (3.200 je Sekunde, 114 je Fuellung), 4.240 SetText, 91 KB Muell
-- je Sekunde. In der Szene kampf von je_m1 (2 der 5 im Buch): 1.164 GRUDGE_UPDATE, 126 KB/s. Alt seit 1.4.0 (dort 903
-- und 99 KB/s), 1.5.0 und 1.6.0 gleich (1.164, 126 KB/s).
-- Erwartet: die Meldung wird nur gefuellt, wenn sich etwas an ihr aendert (hoechstens 5 je Sekunde im Schnitt).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt). Die Attrappe ist nicht der Client.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local hp = 100000
local W = J.world(DIR, { guild = "Die Testgilde", before = function()
  _G.UnitHealth = function() hp = hp - 7; return hp end
  _G.UnitAffectingCombat = function() return true end
end })
local ns, AM = W.ns, W.AM
W.tick(60)
local FOES = { { "Fremder", "Eins" }, { "Fremder", "Zwei" }, { "Fremder", "Drei" }, { "Fremder", "Vier" }, { "Fremder", "Fuenf" } }
local function hostile(token, i) AM.AddEnemy(token, { name = FOES[i][1], surname = FOES[i][2], guid = "Player-93-F00" .. i, target = "player" }) end
local updates, fills = 0, 0
ns:On("GRUDGE_UPDATE", function() updates = updates + 1 end)
J.reset(); J.start()
local k0 = collectgarbage("count")
for i = 1, 5 do hostile("nameplate" .. i, i); W.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
W.fire("PLAYER_REGEN_DISABLED")
for s = 1, 29 do
  for _ = 1, 8 do W.fire("UNIT_HEALTH", "player") end
  for _ = 1, 6 do W.fire("UNIT_COMBAT", "player", "WOUND", "", 120, 1) end
  for k = 1, 6 do W.fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate" .. ((s + k) % 5 + 1), "Cast-1", 1752) end
  for k = 1, 4 do W.fire("UNIT_TARGET", "nameplate" .. ((s + k) % 5 + 1)) end
  hostile("target", s % 5 + 1); W.fire("PLAYER_TARGET_CHANGED")
  W.tick(1)
end
local kb = collectgarbage("count") - k0
local widgets, setText = J.widgetTotal(), J.widget.SetText or 0
J.stop()
local rows = 0
local e = ns.Grudge.Current()
if e and e.rows then for _ in pairs(e.rows) do rows = rows + 1 end end
print(("  30 s Kampf gegen 5 Spieler: GRUDGE_UPDATE %d mal (%.1f je Sekunde) fuer %d Zeilen; %.0f KB Muell je Sekunde; Widget-Aufrufe %d, SetText %d")
  :format(updates, updates / 30, rows, kb / 30, widgets, setText))
J.check("Vorbedingung: die Meldung hat 5 Zeilen", rows == 5, rows)
J.check("GRUDGE_UPDATE hoechstens 5 je Sekunde im Schnitt (150 in 30 s)", updates <= 150, updates)
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
