-- Fixer 1.7.0 round 2: copy of the hunt test jn05 (unchanged).
-- jn05 (Nachjagd 1.7.0, Fixer-Diff Alert.lua AlarmGold): das Kopfgeld eines stummgeschalteten Freunds "zaehlt fuer
-- den Alarm nicht". Das gilt nur fuer die Frage OB der Alarm laeutet:
-- (a) liegt daneben ein kleines Kopfgeld eines anderen, laeutet der Alarm und die Zeile nennt den Stummen als
--     groessten Auslober mit seiner Summe ("520g Kopfgeld von Anna +1"): SetLine nimmt Look.OthersBountyText ohne
--     den Filter.
-- (b) liegt NUR sein Kopfgeld auf dem Ziel, baut jede Sichtung (Plakette, Ziel, Mouseover) die Zeilen neu
--     (Bounty.Others), weil nie ein Alarm kommt und also nie eine Abklingzeit laeuft: der heisse Pfad zahlt je
--     Plakette neue Tabellen, solange so ein Ziel in Sicht ist.
-- Erwartet: (a) Zeile ohne den Stummen (20g von Dirk); (b) keine Zeilen je Sichtung. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
local function sight(W, name, surname, token)
  W.AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  W.tick()
end
local function stumm(W)
  local F = W.ns.Friends
  F.AnyMuted = function() return true end
  F.Muted = function(c) return type(c) == "string" and c:find("^Anna") ~= nil end
end
do
  local W = X.world("deDE")
  X.fake(W); stumm(W)
  W.bounty("Kalt-Herz", "Anna", 500)
  W.bounty("Kalt-Herz", "Dirk", 20)
  sight(W, "Kalt", "Herz", "nameplate2")
  local p = W.popup()
  local line = p and p:IsShown() and tostring(p.line._text) or ""
  check("Vorbedingung: Alarm (Dirks Kopfgeld)", line ~= "")
  check("(a) die Alarmzeile nennt den stummgeschalteten Freund nicht", not line:find("Anna", 1, true), line)
  check("(a) die Alarmzeile nennt nicht seine Summe", not line:find("520", 1, true), line)
end
do
  local W = X.world("deDE")
  X.fake(W); stumm(W)
  W.bounty("Kalt-Herz", "Anna", 500)
  local o0 = W.othersCalls
  for i = 1, 20 do
    W.AM.units["nameplate" .. (i - 1)] = nil
    sight(W, "Kalt", "Herz", "nameplate" .. i)
  end
  local p = W.popup()
  check("Vorbedingung: kein Alarm", not (p and p:IsShown()))
  local n = W.othersCalls - o0
  io.write(("  gemessen: %d Aufrufe Bounty.Others (je einer baut die Zeilen) auf 20 Sichtungen desselben Ziels\n"):format(n))
  check("(b) keine Zeilen je Sichtung", n <= 1, n)
end
J.done()
