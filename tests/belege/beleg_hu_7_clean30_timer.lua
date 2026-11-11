-- Fund 7: "30 Tage ohne Tod" wird beim Login sofort als erledigt vermerkt (m.clean30), die Zeile kommt aber erst
-- 12 Sekunden spaeter. Wer in diesen 12 Sekunden /reload macht oder ausloggt, sieht den Meilenstein nie.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local T0 = 1700000000
local db = {}
local ns = H.welt("deDE", { db = db, epoch = T0 })
H.kill(ns, "Grimm", "Bart"); H.away()
local T = H.SRC.deDE
-- 31 Tage spaeter: Login, nach 5 Sekunden /reload
ns = H.welt("deDE", { db = db, epoch = T0 + 31 * 86400 })
H.vor(5)
local gezeigt = ns.Humor.said == T.MILESTONE.clean30
H.check("Vorbedingung: nach 5 Sekunden ist die Zeile noch nicht da", not gezeigt)
H.check("Merker erst setzen, wenn die Zeile gezeigt ist", db.humor.m.clean30 == nil, "m.clean30 = " .. tostring(db.humor.m.clean30))
ns = H.welt("deDE", { db = db, epoch = T0 + 31 * 86400 + 60 })
H.vor(30)
gezeigt = gezeigt or ns.Humor.said == T.MILESTONE.clean30
H.check("nach dem /reload kommt die Zeile (genau einmal, nicht keinmal)", gezeigt, "nie gezeigt, Merker steht")
H.ende("beleg_hu_7_clean30_timer")
