-- Jagd 1.7.0 Fund JU-07: der Alarm "ZIEL MIT KOPFGELD" steht, da trifft eine Tat desselben Spielers ein (er hat
-- gerade einen Kollegen getoetet: GUILD_UPDATED). Alert.BountyEntry gibt jetzt nil (er steht im Gildenbuch), der
-- Alarm wird weggenommen statt zum Gilden-Alarm zu werden, und die gemeinsame Abklingzeit ist verbraucht: beim
-- naechsten Sichten laeutet 90 Sekunden lang nichts. Der Alarm verschwindet also genau dann, wenn das Ziel
-- gefaehrlicher wird. Erwartet: der Alarm bleibt (als Gilden-Alarm mit dem Kopfgeld am Ende).
-- Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
local W = X.world("deDE")
local ns, L = W.ns, W.L
local function shown() local p = W.popup(); return p and p:IsShown() and p or nil end
W.bounty("Kalt-Herz", "Anna", 50)
W.AM.AddEnemy("nameplate1", { name = "Kalt", surname = "Herz", guid = "Player-93-KaltHerz", level = 40, class = "ROGUE" })
W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); W.tick()
local p = shown()
check("Vorbedingung: Alarm Ziel mit Kopfgeld steht", p ~= nil and p.title._text == L.ALERT_TITLE_BOUNTY, p and p.title._text)
-- zwei Sekunden spaeter: er toetet Bert, die Tat kommt ueber die Gilde
W.tick(2)
W.gmsg(W.P.EncodeKill({ key = "Kalt-Herz", display = "Kalt Herz", class = "ROGUE", level = 40, zone = "Z", t = _G.time() - 1,
  victim = "Bert Wurst" }), "Bert Wurst-Forever")
W.tick(1); W.BM.FinishAnims(); W.tick(1)
check("Vorbedingung: jetzt im Gildenbuch", ns.Guild.Get("Kalt-Herz", "all") ~= nil)
p = shown()
check("der Alarm steht weiter (jetzt als Alarm des Gildenbuchs)", p ~= nil, "Alarm weg")
-- er laeuft noch einmal durchs Bild
W.AM.FireEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
W.AM.units.nameplate1 = nil
W.tick(5)
W.AM.AddEnemy("nameplate2", { name = "Kalt", surname = "Herz", guid = "Player-93-KaltHerz", level = 40, class = "ROGUE" })
W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2"); W.tick()
check("spaetestens beim naechsten Sichten laeutet es", shown() ~= nil, "kein Alarm, Abklingzeit verbraucht")
J.done()
