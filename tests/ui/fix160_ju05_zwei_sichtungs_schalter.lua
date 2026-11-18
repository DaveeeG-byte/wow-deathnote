-- ju05: Hausordnung, Blatt Gilde, Gruppe TEILEN: zwei fast gleich lautende Haken untereinander,
-- "Sichtungen mit Gilde und Freunden teilen" (alt, Standard AUS) und "Sichtungen meiner Moerder teilen" (neu, Standard
-- AN). Ein Spieler, der Sichtungen nie eingeschaltet hat, sieht den ersten Haken leer und teilt nach dem Update
-- trotzdem Ort, Zeit und Layer seiner Sichtungen (T) mit Gilde und Freunden. Was der Unterschied ist, sagt das Blatt
-- nicht. Bild: hausordnung-gilde deDE (Jagdbericht). Erwartet: ein Schalter, oder der neue folgt dem alten
-- (Standard aus, solange der alte aus ist), oder Wortlaut, der den Unterschied nennt. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local W = J.world(WT, "deDE", { guild = "Die Rostigen Naegel" })
local G = W.ns.Guild
local old, new = G.Setting("sightings"), G.Setting("layerSight")
J.check("frisches Buch: alter und neuer Sichtungs-Schalter sagen dasselbe (alt " .. tostring(old) .. ", neu " .. tostring(new) .. ")",
  (old == true) == (new ~= false))
W.open(); W.ns.UI.OpenPanel("settings"); W.tick(1)
W.click(W.find(function(f) return f.page == 3 and f._scripts and f._scripts.OnClick and f:IsVisible() end))
local L = W.ns.L
J.check("nicht zwei Sichtungs-Haken auf demselben Blatt", not (W.visible(L.OPT_F_SIGHTINGS) and W.visible(L.OPT_G_LAYERSIGHT)),
  L.OPT_F_SIGHTINGS .. " / " .. L.OPT_G_LAYERSIGHT)
J.done()
