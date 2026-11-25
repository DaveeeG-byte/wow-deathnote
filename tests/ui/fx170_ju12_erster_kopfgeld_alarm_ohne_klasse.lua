-- Jagd 1.7.0 Fund JU-12: der erste Alarm "ZIEL MIT KOPFGELD" kennt Klasse und Stufe des Ziels nicht. Der Haken
-- Tracker.bountyHook laeuft in Tracker.OnUnit, bevor der Tracker den Spieler aufnimmt (buffer[key] entsteht erst
-- danach), Alert.BountyEntry liest aber Klasse und Stufe aus Tracker.Get(key). Beim ersten Sichten ist der Name
-- deshalb nicht in Klassenfarbe und das Bild ohne Klassenzeichen (kein Modell ueber die Namensplakette hinaus);
-- jeder andere Alarm (Buch, Gilde, Abschussliste) hat die Klasse aus seinem Buch.
-- Erwartet: der Eintrag des ersten Alarms traegt die Klasse, die die Einheit zeigt. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
local W = X.world("deDE")
local ns = W.ns
W.bounty("Kalt-Herz", "Anna", 50)
local first
local orig = ns.Alert.BountyEntry
ns.Alert.BountyEntry = function(key)
  local e = orig(key)
  if e and not first then first = { class = e.class, level = e.level } end
  return e
end
W.AM.AddEnemy("nameplate1", { name = "Kalt", surname = "Herz", guid = "Player-93-KaltHerz", level = 40, class = "ROGUE" })
W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); W.tick()
local p = W.popup()
check("Vorbedingung: Alarm steht", p and p:IsShown() and first ~= nil)
check("der erste Alarm kennt die Klasse des Ziels", first and first.class == "ROGUE", first and tostring(first.class))
J.done()
