-- Finding 1: counters and markers in db.humor only keep up while Humor is active. After a phase in another
-- language (likewise: back to 1.1.0 and up again, 1.1.0 leaves db.humor alone) last death,
-- total deaths and "first revenge" are stale: a wrong "30 days without death" the day after a death, "first revenge"
-- on the second one, 100 deaths counts too few. The journal (db.deaths) and e.revenge know better.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local T0 = 1700000000
local db = {}
-- session 1, German: 7 deaths
local ns = H.welt("deDE", { db = db, epoch = T0 })
local key
for _ = 1, 4 do H.kill(ns, "Ober", "Schurke"); H.away() end       -- rank 1 stays someone else
for _ = 1, 3 do key = H.kill(ns, "Grimm", "Bart"); H.away() end
H.check("Vorbedingung: Merker angelegt, 7 Tode", db.humor and db.humor.deaths == 7, db.humor and db.humor.deaths)
-- session 2, 40 days later, Finnish: 5 deaths, one revenge
db.settings.lang = "fiFI"
ns = H.welt("fiFI", { db = db, epoch = T0 + 40 * 86400 })
for _ = 1, 5 do H.kill(ns, "Ober", "Schurke"); H.away() end
ns.Store.AddRevenge(key); H.away()
local newest = db.deaths[1].t
H.check("Vorbedingung: Journal hat 12 Tode, Rache steht im Eintrag", #db.deaths == 12 and ns.Store.Get(key).revenge == 1)
-- session 3, one day later, German again
db.settings.lang = "deDE"
ns = H.welt("deDE", { db = db, epoch = T0 + 41 * 86400 })
local T = H.SRC.deDE
H.vor(15)
local tage = (_G.time() - newest) / 86400
H.check("kein '30 Tage ohne Tod' " .. string.format("%.1f", tage) .. " Tage nach dem letzten Tod",
  ns.Humor.said ~= T.MILESTONE.clean30 and db.humor.m.clean30 == nil, "Merker clean30 = " .. tostring(db.humor.m.clean30))
H.check("letzter Tod der Merker = juengster Tod im Journal", db.humor.lastDeath == newest,
  tostring(db.humor.lastDeath) .. " statt " .. tostring(newest))
H.check("Tode gesamt = 12 (Journal)", db.humor.deaths == #db.deaths, db.humor.deaths)
ns.Store.AddRevenge(key); H.settle()
H.check("zweite Rache bekommt keinen Stempel 'erste Rache'",
  H.stampText() ~= T.STAMP.revenge1, "revenge=" .. ns.Store.Get(key).revenge .. ", Rang " .. tostring(ns.Store.Rank(key)))
H.ende("beleg_hu_1_merker_veralten")
