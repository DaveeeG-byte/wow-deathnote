-- Fund 10: Die Einhaengepunkte in UI.lua rufen Humor ohne pcall. Wirft Humor.EmptyWanted (hier: der Zufall wirft,
-- stellvertretend fuer jeden Fehler in Humor.lua), bricht ShowEmpty vor "P:Hide(); RP.empty:Show()" ab: die leere
-- Seite "Gesucht" bleibt weg. Ein Humor-Fehler darf die echte Anzeige nicht verhindern.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function leereSeite()
  for _, f in ipairs(H.BM.frames) do if f.big and f.small and f.tiny then return f end end
end
local ns = H.welt("deDE", { chance = 0.5, quiet = 600 })
ns:Fire("TOGGLE_UI"); H.settle()
local X = leereSeite()
H.check("Vorbedingung: leeres Buch zeigt die leere Seite", X and X:IsVisible())
ns:Fire("TOGGLE_UI"); H.settle()

ns = H.welt("deDE", { chance = 0.5, quiet = 600 })
ns.Humor.random = function() error("Humor kaputt") end
pcall(function() ns:Fire("TOGGLE_UI"); H.settle() end)
X = leereSeite()
H.check("Humor wirft: die leere Seite steht trotzdem", X and X:IsVisible(), "leere Seite unsichtbar, Fehler: " .. #H.AM.errors)
H.ende("beleg_hu_10_haken_ungeschuetzt")
