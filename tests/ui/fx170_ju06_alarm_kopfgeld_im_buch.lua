-- Jagd 1.7.0 Fund JU-06 (Notiz 5 des Briefs): ein Ziel mit dem Kopfgeld eines Kollegen bleibt ohne jeden Alarm,
-- sobald es in irgendeinem Buch steht und der Alarm jenes Buchs fuer es schweigt. Alert.BountyEntry gibt nil, weil
-- Store.Get / Guild.Get etwas finden; ob jener Alarm ueberhaupt laeutet, wird nicht gefragt. Der Schalter der
-- Abschussliste (guild.alertHunt), der den Kopfgeld-Alarm laut E9 steuert, ist in allen drei Faellen an.
--   (a) im Gildenbuch nur von Hand gelistet, Standard-Einstellungen (guild.alertListed ist ab Werk aus):
--       Anna traegt jemanden von Hand ein und lobt 50g aus -> beim Kollegen laeutet nichts
--   (b) im Gildenbuch mit Taten, Gilden-Alarm aus (genau die Notiz 5)
--   (c) im eigenen Buch als Verdacht (alert.suspects ist ab Werk aus)
-- Fuer ein Ziel der Abschussliste gibt es dieselbe Regel schon ("suspect or under the own threshold: the hit list
-- alarm", EligibleGuild); fuer das Kopfgeld fehlt sie. Erwartet: der Alarm kommt und nennt das Kopfgeld.
-- Alle Namen sind erfunden.
-- Fixer 1.7.0: copy of hunt test ju06 (case b waits for the end of the guild death notice).
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()

local function sight(W, name, surname, token)
  W.AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  W.tick()
end
local function shown(W) local p = W.popup(); return p and p:IsShown() and p or nil end
local function names(W, p, gold, who)
  return p and tostring(p.line._text):find(W.F(W.L.ALERT_BOUNTY_BY, { gold = W.ns.UI.Kit.GF.Gold(gold), name = who }), 1, true) ~= nil
end

-- Gegenprobe: ganz unbekannt -> der Alarm kommt (so ist es gebaut)
do
  local W = X.world("deDE")
  W.bounty("Kalt-Herz", "Anna", 50)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("Gegenprobe: unbekanntes Ziel mit Annas Kopfgeld laeutet", shown(W) ~= nil and names(W, shown(W), 50, "Anna"))
end
-- (a) von Hand gelistet, Standard
do
  local W = X.world("deDE")
  local ns = W.ns
  W.gmsg(W.P.EncodeListed({ key = "Kalt-Herz", display = "Kalt Herz", t = _G.time() - 30, by = "Anna Wurst" }), "Anna Wurst-Forever")
  W.tick(2)
  W.bounty("Kalt-Herz", "Anna", 50)
  check("(a) Vorbedingung: im Gildenbuch, nur gelistet", ns.Guild.Get("Kalt-Herz", "all") ~= nil)
  check("(a) Vorbedingung: Schalter Abschussliste an, Kopfgeld bekannt", ns.Store.Setting("guild.alertHunt") ~= false
    and ns.Guild.HasBounty("Kalt-Herz") == true)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("(a) von Hand gelistet (Standard): Alarm mit Kopfgeld", shown(W) ~= nil and names(W, shown(W), 50, "Anna"))
end
-- (b) Gildenbuch mit Tat, Gilden-Alarm aus
do
  local W = X.world("deDE")
  local ns = W.ns
  ns.Store.Setting("guild.alert", false)
  W.gmsg(W.P.EncodeKill({ key = "Kalt-Herz", display = "Kalt Herz", class = "MAGE", level = 40, zone = "Z", t = _G.time() - 60,
    victim = "Anna Wurst" }), "Anna Wurst-Forever")
  W.tick(2)
  W.bounty("Kalt-Herz", "Anna", 50)
  -- fixer copy: the notice of Anna's death names Kalt Herz and silences every alarm for him for the shared cooldown
  -- (one event, one window, as in 1.6.4); the sighting comes after it
  W.tick(100); W.settle()
  check("(b) Vorbedingung: im Gildenbuch", ns.Guild.Get("Kalt-Herz", "all") ~= nil)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("(b) Gilden-Alarm aus, Schalter Abschussliste an: Alarm mit Kopfgeld", shown(W) ~= nil and names(W, shown(W), 50, "Anna"))
end
-- (c) eigener Verdacht
do
  local W = X.world("deDE")
  local ns = W.ns
  local key = ns.Store.ApplyKill({ name = "Kalt", surname = "Herz", class = "MAGE", level = 40, guid = "Player-93-KaltHerz" },
    { t = _G.time() - 600, zone = "Z", source = "target", role = "suspect" }, false)
  local e = ns.Store.Get(key)
  check("(c) Vorbedingung: Verdacht im eigenen Buch", e ~= nil and e.status == "suspect", e and e.status)
  W.bounty(key, "Anna", 50)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("(c) eigener Verdacht (Standard): Alarm mit Kopfgeld", shown(W) ~= nil and names(W, shown(W), 50, "Anna"))
end
J.done()
