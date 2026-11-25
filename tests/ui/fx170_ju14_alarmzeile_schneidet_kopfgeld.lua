-- Jagd 1.7.0 Fund JU-14: das Kopfgeld steht am Ende der Alarmzeile und "gibt nie nach" (Alert.lua SetLine). Wird
-- die Zeile trotz aller Stufen zu lang, setzt der Client die Auslassung ans Ende, also genau in das Kopfgeld: der
-- Teil, der nie nachgeben soll, ist der erste, der abgeschnitten wird. Fall: eigenes Buch mit Toden und
-- Beteiligungen, das Ziel steht auf der Abschussliste eines Kollegen, drei Kollegen haben ausgelobt, Namen mit
-- zwoelf Zeichen. In deDE, frFR, ruRU und ukUA ist die Zeile dann auch in der kleinsten Stufe abgeschnitten.
-- Erwartet: die Zeile passt (ein frueherer Teil gibt nach), in jeder Sprache. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
for _, code in ipairs({ "deDE", "enUS", "frFR", "ruRU", "ukUA", "esES", "plPL" }) do
  local W = X.world(code)
  local ns = W.ns
  local key
  for i = 1, 12 do key = W.kill("Maximilianus", "Donnerschlag", _G.time() - 600 * i) end
  for i = 1, 3 do
    ns.Store.ApplyKill({ name = "Maximilianus", surname = "Donnerschlag", class = "MAGE", level = 40, guid = "Player-93-MaximilianusDonnerschlag" },
      { t = _G.time() - 9000 * i, zone = "Schlingendorntal", source = "recap", role = "assist" }, false)
  end
  W.gmsg(W.P.EncodeHunt({ key = key, display = "Maximilianus Donnerschlag", by = "Bartholomaus Wurst", t = _G.time() - 50, why = "" }),
    "Bartholomaus Wurst-Forever")
  W.tick(2)
  W.bounty(key, "Bartholomaus", 99999); W.bounty(key, "Anna", 500); W.bounty(key, "Bert", 400)
  W.AM.AddEnemy("nameplate1", { name = "Maximilianus", surname = "Donnerschlag", guid = "Player-93-MaximilianusDonnerschlag", level = 63, class = "ROGUE" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); W.tick()
  local p = W.popup()
  local line = p and p:IsShown() and p.line
  check(code .. ": Vorbedingung: Alarm steht", line ~= nil)
  check(code .. ": die Alarmzeile mit Kopfgeld ist nicht abgeschnitten", line and not line.cut, line and line._text)
end
J.done()
