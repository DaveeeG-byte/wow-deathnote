-- Fixer 1.7.0 (JU-06, JU-19, untested point "muted friend"): the bounty's alarm asks whether another alarm rings for him,
-- not whether a book knows him. Pardoned stays silent; a muted friend's bounty never alarms; the line of the book's
-- alarm follows a bounty that comes while it stands. All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
local function sight(W, name, surname, token)
  W.AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  W.tick()
end
local function shown(W) local p = W.popup(); return p and p:IsShown() and p or nil end

-- pardoned in the own book: silent
do
  local W = X.world("deDE")
  X.fake(W)
  local key = W.kill("Kalt", "Herz")
  W.ns.Store.SetStatus(key, "pardoned")
  W.bounty(key, "Anna", 50)
  W.tick(100); W.settle()
  sight(W, "Kalt", "Herz", "nameplate1")
  check("begnadigt mit Kopfgeld: kein Alarm", shown(W) == nil)
end
-- a muted friend's bounty: no bounty-only alarm (his data stays, it does not alarm)
do
  local W = X.world("deDE")
  X.fake(W)
  local F = W.ns.Friends
  local realM, realA = F.Muted, F.AnyMuted
  F.AnyMuted = function() return true end
  F.Muted = function(c) return type(c) == "string" and c:find("^Anna") ~= nil end
  W.bounty("Kalt-Herz", "Anna", 50)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("stummer Freund: kein Nur-Kopfgeld-Alarm", shown(W) == nil)
  W.bounty("Kalt-Herz", "Dirk", 20)
  W.tick(100)
  sight(W, "Kalt", "Herz", "nameplate2")
  check("dazu ein anderer Auslober: Alarm", shown(W) ~= nil)
  F.Muted, F.AnyMuted = realM, realA
end
-- the book's alarm stands, then a bounty comes: its line names it
do
  local W = X.world("deDE")
  X.fake(W)
  local ns, L, F = W.ns, W.L, W.F
  W.kill("Grimm", "Bart")
  W.bounty("Kalt-Herz", "Dirk", 5)          -- some bounty of others exists (the hook is on)
  sight(W, "Grimm", "Bart", "nameplate1")
  local p = shown(W)
  check("Vorbedingung: eigener Alarm ohne Kopfgeld", p and not tostring(p.line._text):find("Anna", 1, true), p and p.line._text)
  W.bounty("Grimm-Bart", "Anna", 60)
  W.tick(1)
  p = shown(W)
  local want = F(L.ALERT_BOUNTY_BY, { gold = ns.UI.Kit.GF.Gold(60), name = "Anna" })
  check("eigener Alarm: Zeile folgt dem neuen Kopfgeld", p and tostring(p.line._text):find(want, 1, true) ~= nil, p and p.line._text)
  local n, e = W.errs()
  check("keine Fehler", n == 0, e)
end
-- the sighting path, measured again (JU-06 runs the hook also for players in the own book): without a bounty of others
-- not one call per plate; with one, one Bounty.Has per plate of a hostile player, in a book or not, no rows
do
  local W = X.world("deDE")
  X.fake(W)
  local B = W.ns.Bounty
  W.ns.Store.Setting("alert.enabled", false)   -- the book's own alarm (it names a bounty once per alarm) stays out
  local has, realHas = 0, B.Has
  B.Has = function(...) has = has + 1; return realHas(...) end
  for i = 1, 10 do W.kill("Buch", "Ling" .. string.char(64 + i)) end
  W.tick(100); W.settle()
  for i = 1, 10 do sight(W, "Buch", "Ling" .. string.char(64 + i), "nameplate" .. i) end
  for i = 1, 10 do sight(W, "Fremd", "Ling" .. string.char(64 + i), "nameplate" .. (10 + i)) end
  check("ohne fremdes Kopfgeld: 0 Has auf 20 Plaketten", has == 0, has)
  W.bounty("Kalt-Herz", "Anna", 80)
  W.tick(200); W.settle()
  has = 0
  local o0 = W.othersCalls
  for i = 1, 10 do W.AM.units["nameplate" .. i] = nil; sight(W, "Buch", "Ling" .. string.char(64 + i), "nameplate" .. (30 + i)) end
  for i = 1, 10 do sight(W, "Fremd", "Ling" .. string.char(64 + i), "nameplate" .. (40 + i)) end
  check("mit fremdem Kopfgeld: ein Has je Plakette, keine Zeilen", has == 20 and W.othersCalls == o0, has .. " / " .. (W.othersCalls - o0))
  io.write(("  Messung Plakette (Fixer): ohne fremdes Kopfgeld 0 Has; mit: %d Has auf 20 Plaketten (10 im Buch, 10 fremd), %d Others\n"):format(has, W.othersCalls - o0))
end
X.done("fx170 alarm")
