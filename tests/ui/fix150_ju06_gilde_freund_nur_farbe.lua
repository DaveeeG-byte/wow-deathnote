-- ju06: Gilden- und Freundesnadel unterscheiden sich nur durch die Toenung (gruen / blau) derselben Textur
-- scene_mate.tga; bei Tritanopie sind beide tuerkis und gleich (Bild ju-farbsicht-nadeln.png: je Gruppe Freund, Tod,
-- Gilde, Kill, Buendel; Gruppen: normal, Deuteranopie, Protanopie, Tritanopie). Der Brief verlangte ein kleines
-- Freund-Zeichen. Erwartet: Form oder Zeichen unterscheidet die Arten auch ohne Farbe.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jukarte.lua")
local W = J.map(WT)
local src = io.open(WT .. "/DeathNote/SceneMap.lua"):read("*a")
local g = src:match('guild%s*=%s*"([^"]+)"')
local fr = src:match('friend%s*=%s*"([^"]+)"')
J.check("Gilde und Freund haben verschiedene Zeichen (nicht nur Farbe)", g and fr and g ~= fr, tostring(g) .. " = " .. tostring(fr))
J.done()
