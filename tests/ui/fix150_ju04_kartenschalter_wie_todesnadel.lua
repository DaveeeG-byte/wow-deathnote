-- ju04: Der Schalter an der Kartenecke traegt dasselbe Bild wie die Nadel "mein Tod" (scene_death.tga) und sitzt
-- unten links auf der Karte: eine Nadel daneben ist nicht vom Schalter zu unterscheiden, der Schalter sieht aus wie
-- ein Tatort. Erwartet: eigenes Zeichen (z. B. Buch, Zahnrad, Filter) und erkennbarer Rahmen. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jukarte.lua")
local W = J.map(WT)
W.death("Grimm", 3, 95)
W.show()
local btn = W.ns.SceneMap.Button()
local pin = W.pins()[1]
local bt = btn and btn.icon and (btn.icon._texture or btn.icon._tex or btn.icon.file)
local pt = pin and pin.icon and (pin.icon._texture or pin.icon._tex or pin.icon.file)
if not bt and btn and btn.icon.GetTexture then bt = btn.icon:GetTexture() end
if not pt and pin and pin.icon.GetTexture then pt = pin.icon:GetTexture() end
J.check("Nadel gezeichnet", pin ~= nil)
J.check("Schalter hat ein anderes Bild als die Todesnadel", bt ~= nil and bt ~= pt, tostring(bt) .. " = " .. tostring(pt))
J.done()
