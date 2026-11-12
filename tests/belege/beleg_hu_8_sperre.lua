-- Finding 8: lock "at most one random quip per Humor.QUIET seconds". (a) It lives only in session memory:
-- after /reload the next random quip comes at once (GetTime keeps running in the client across /reload).
-- (b) A rolled quip that is never shown (death messages off) still uses up the lock.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function welt(db, t)
  local ns = H.welt("deDE", { db = db, keep = true, epoch = 1700000000 + (t or 0) })
  for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = 1 end     -- every roll hits, the lock stays as shipped
  return ns
end
local db = {}
local ns = welt(db)
H.check("Vorbedingung: Sperre wie ausgeliefert", ns.Humor.QUIET == 600, ns.Humor.QUIET)
local k = H.kill(ns, "Klein", "Wicht", { level = 20 })
H.check("Vorbedingung: erster Zufallsspruch (Taeter 20 Stufen darunter)", H.quip() ~= nil)
H.away()
ns.Store.AddRevenge(k); H.away()                 -- first revenge: milestone, does not count
ns.Store.AddRevenge(k); H.settle()
H.check("Vorbedingung: in derselben Sitzung sperrt sie den zweiten Zufallsspruch", H.quip() == nil)
H.away()
local vergangen = H.AM.now - 1000
-- (a) /reload
ns = welt(db, vergangen)
ns.Store.AddRevenge(k); H.settle()
H.check("(a) nach /reload, " .. math.floor(vergangen) .. " s nach dem ersten Spruch: kein zweiter Zufallsspruch", H.quip() == nil,
  "Spruch aus dem Topf revenge")
-- (b) remark that fizzles out
db = {}
ns = welt(db)
ns.Store.Setting("deathMessage", false)
k = H.kill(ns, "Klein", "Wicht", { level = 20 })
local b = H.banner()
H.check("Vorbedingung: Todesmeldungen aus, nichts gezeigt", not (b and b:IsShown()) and H.humorChat() == 0)
H.kill(ns, "Ober", "Schurke"); H.kill(ns, "Ober", "Schurke")     -- rank 1 is someone else
ns.Store.AddRevenge(k); H.away()                 -- first revenge (milestone)
ns.Store.AddRevenge(k); H.settle()
H.check("(b) ein nie gezeigter Spruch sperrt den naechsten nicht", H.quip() ~= nil, "Rache-Spruch faellt aus")
H.ende("beleg_hu_8_sperre")
