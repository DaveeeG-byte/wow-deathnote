-- Fund 6: Mem() repariert db.humor nur grob (Tabelle, m, deaths als Zahl). lastDeath als Text oder Tabelle wirft bei
-- jedem Login einen Lua-Fehler (Rechnung in OnReady), bis zum naechsten Tod. deaths = NaN bleibt fuer immer NaN
-- (100 Tode kommt nie, die Beichte zeigt die Unzahl), negative Zahlen zaehlen von unten hoch.
-- Die echten Meldungen bleiben in allen Faellen unberuehrt (Vorbedingung).
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function fall(name, humor)
  local db = { humor = humor }
  local ns = H.welt("deDE", { db = db })
  H.vor(15)
  local loginFehler = #H.AM.errors
  local key
  for _ = 1, 2 do key = H.kill(ns, "Grimm", "Bart") end
  local b = H.banner()
  H.check(name .. ": Vorbedingung, die Todesmeldung steht", b and b:IsShown() and b.key == key)
  ns.HandleSlash("beichte")
  return ns, db, loginFehler
end
for _, f in ipairs({ { "lastDeath als Text", { deaths = 1, m = {}, lastDeath = "gestern" } },
                     { "lastDeath als Tabelle", { deaths = 1, m = {}, lastDeath = {} } } }) do
  local _, _, n = fall(f[1], f[2])
  H.check(f[1] .. ": kein Lua-Fehler beim Login", n == 0, tostring(H.AM.errors[1]):match("[^/]*$"))
end
do
  local ns, db = fall("deaths NaN", { deaths = 0 / 0, m = {} })
  H.check("deaths NaN: nach zwei Toden wieder eine Zahl", db.humor.deaths == db.humor.deaths, tostring(db.humor.deaths))
  H.check("deaths NaN: die Beichte nennt keine Unzahl", not tostring(ns.Humor.said):find(tostring(0 / 0), 1, true))
end
do
  local ns, db = fall("deaths negativ", { deaths = -50, m = {} })
  H.check("deaths negativ: nicht unter null weiterzaehlen", db.humor.deaths >= 0, db.humor.deaths)
end
H.ende("beleg_hu_6_kaputte_merker")
