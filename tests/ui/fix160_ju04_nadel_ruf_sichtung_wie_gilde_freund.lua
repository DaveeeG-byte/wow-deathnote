-- ju04: Karte. Die Nadel des Hilferufs ist das Bild der Gilden-Nadel (scene_guild.tga, Schild mit Totenkopf) in Rot,
-- die Nadel der Sichtung das Bild der Freundes-Nadel (scene_friend.tga, Kreis mit Herz) in Bernstein. Ohne Farbe
-- (Farbsehschwaeche, Graustufen) ist ein Ruf nach dem Ende des Pulsierens (3 Min.) nicht von einem Gilden-Tod und eine
-- Sichtung nicht von einem Tod eines Freundes zu unterscheiden; beide tragen zudem den Totenkopf eines Tatorts.
-- Bild bilder/ju-karte-alle-nadeln-deDE.png. Erwartet: eigene Bilder (z. B. Horn/Ausrufezeichen, Auge).
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local W = J.world(WT, "deDE")
local TEX = W.ns.SceneMap.TEX
J.check("Hilferuf hat ein eigenes Bild (nicht das der Gilde)", TEX.call ~= TEX.guild, TEX.call)
J.check("Sichtung hat ein eigenes Bild (nicht das der Freunde)", TEX.sight ~= TEX.friend, TEX.sight)
J.done()
