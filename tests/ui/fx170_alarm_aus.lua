-- Fixer 1.7.0 round 2 (JN-11): with the alarm switched off (alert.enabled false, /dn quiet) a player of the own book does
-- not ring through a bounty of others; a player known only by such a bounty still rings under the hit list's switch.
-- All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
local function sight(W, name, surname, token)
  W.AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  W.tick()
end
local function shown(W) local p = W.popup(); return p and p:IsShown() and p or nil end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(code)
  X.fake(W)
  local ns = W.ns
  local key = W.kill("Grimm", "Bart")
  W.tick(100); W.settle()
  ns.Store.Setting("alert.enabled", false)
  W.bounty(key, "Anna", 60)
  W.bounty("Kalt-Herz", "Anna", 40)
  W.tick(100); W.settle()
  sight(W, "Grimm", "Bart", "nameplate1")
  check(code .. ": Alarm aus: Gegner aus dem eigenen Buch mit Kopfgeld still", shown(W) == nil)
  sight(W, "Kalt", "Herz", "nameplate2")
  local p = shown(W)
  check(code .. ": Alarm aus: Nur-Kopfgeld-Ziel laeutet weiter (Schalter Abschussliste)", p ~= nil and p.title._text == W.L.ALERT_TITLE_BOUNTY)
  local n, e = W.errs()
  check(code .. ": keine Fehler", n == 0, e)
end
X.done("fx170 alarm aus")
