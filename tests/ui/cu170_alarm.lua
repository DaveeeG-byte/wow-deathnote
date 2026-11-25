-- 1.7.0 claim: the alarm names a bounty of others ("50g bounty from Anna"; several: the sum and "Bert +1"); a target known
-- only by such a bounty alarms under the switch of the hit list alarm (guild.alertHunt), never for an own char or a
-- guildmate, never for an own bounty alone, not in an instance, with the shared cooldown; without Bounty.Others (an
-- older logic) everything as in 1.6.4; the sighting path does not get dearer while nobody else posted a bounty.
-- All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check

local function sight(W, name, surname, token)
  token = token or "target"
  W.AM.AddEnemy(token, { name = name, surname = surname, guid = "Player-93-" .. name .. surname, level = 40, class = "ROGUE" })
  if token == "target" then W.AM.FireEvent("PLAYER_TARGET_CHANGED") else W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  W.tick()
end
local function shown(W)
  local p = W.popup()
  return p and p:IsShown() and p or nil
end
local function closeAlarm(W)
  W.tick(20); W.settle()
end

for _, code in ipairs({ "deDE", "enUS" }) do
  -- (1) an own killer with one bounty of others: the line names it at the end
  do
    local W = X.world(code)
    X.fake(W)
    local ns, L, F = W.ns, W.L, W.F
    local key = W.kill("Grimm", "Bart")
    W.bounty(key, "Anna", 50)
    sight(W, "Grimm", "Bart")
    local p = shown(W)
    local want = F(L.ALERT_BOUNTY_BY, { gold = ns.UI.Kit.GF.Gold(50), name = "Anna" })
    check(code .. ": eigener Alarm nennt Annas Kopfgeld", p and tostring(p.line._text):find(want, 1, true) ~= nil,
      p and p.line._text)
    check(code .. ": Titel wie immer (eigenes Buch)", p and p.title._text ~= L.ALERT_TITLE_BOUNTY)
    -- two posters: the sum and the biggest one "+1"
    closeAlarm(W)
    W.bounty(key, "Bert", 300)
    W.tick(200)
    sight(W, "Grimm", "Bart")
    p = shown(W)
    local two = F(L.ALERT_BOUNTY_BY, { gold = ns.UI.Kit.GF.Gold(350), name = F(L.NAMES_PLUS, { name = "Bert", count = 1 }) })
    check(code .. ": mehrere: Summe und groesster Auslober", p and tostring(p.line._text):find(two, 1, true) ~= nil,
      p and p.line._text)
    local n, e = W.errs()
    check(code .. ": (1) keine Fehler", n == 0, e)
  end

  -- (2) known only by a bounty of others: own title, the bounty as the line; under the switch of the hit list alarm
  do
    local W = X.world(code)
    X.fake(W)
    local ns, L, F = W.ns, W.L, W.F
    W.bounty("Kalt-Herz", "Anna", 80)
    check(code .. ": Haken gesetzt", ns.Tracker.bountyHook ~= nil)
    sight(W, "Kalt", "Herz")
    local p = shown(W)
    check(code .. ": Nur-Kopfgeld-Ziel: Alarm", p ~= nil)
    check(code .. ": eigener Titel", p and p.title._text == L.ALERT_TITLE_BOUNTY, p and p.title._text)
    local want = F(L.ALERT_BOUNTY_BY, { gold = ns.UI.Kit.GF.Gold(80), name = "Anna" })
    check(code .. ": Zeile ist das Kopfgeld", p and tostring(p.line._text):find(want, 1, true) ~= nil, p and p.line._text)
    -- the shared cooldown: no second popup right away
    closeAlarm(W)
    sight(W, "Kalt", "Herz", "nameplate1")
    check(code .. ": Abklingzeit wie jeder Alarm", shown(W) == nil)
    W.tick(100)
    W.AM.units.nameplate1 = nil
    sight(W, "Kalt", "Herz", "nameplate2")
    check(code .. ": nach der Abklingzeit wieder", shown(W) ~= nil)
    closeAlarm(W)
    -- the switch of the hit list alarm off: nothing
    ns.Store.Setting("guild.alertHunt", false)
    W.tick(100)
    check(code .. ": Schalter aus: Haken weg", ns.Tracker.bountyHook == nil)
    sight(W, "Kalt", "Herz", "nameplate3")
    check(code .. ": Schalter aus: kein Alarm", shown(W) == nil)
    ns.Store.Setting("guild.alertHunt", true)
    W.tick(100)
    check(code .. ": Schalter an: Haken wieder", ns.Tracker.bountyHook ~= nil)
    -- in an instance the tracker looks at nobody: nothing
    W.AM.instance = { true, "pvp" }
    W.AM.FireEvent("PLAYER_ENTERING_WORLD"); W.tick()
    sight(W, "Kalt", "Herz", "nameplate4")
    check(code .. ": Schlachtfeld: kein Alarm", shown(W) == nil)
    W.AM.instance = { false, "none" }
    W.AM.FireEvent("PLAYER_ENTERING_WORLD"); W.tick(100)
    local n, e = W.errs()
    check(code .. ": (2) keine Fehler", n == 0, e)
  end
end

-- (3) never for a guildmate (heard on the guild channel) nor an own char; an own bounty alone raises nothing new
do
  local W = X.world("deDE")
  X.fake(W)
  local ns = W.ns
  W.bounty("Dirk-Wurst", "Anna", 40)             -- Dirk Wurst is heard on the guild channel himself:
  W.bounty("Kalt-Herz", "Dirk", 10)
  sight(W, "Dirk", "Wurst")
  check("Kollege mit Kopfgeld: kein Alarm", shown(W) == nil)
  _G.DeathNoteDB.friends = _G.DeathNoteDB.friends or {}
  _G.DeathNoteDB.friends.mine = { ["Zweit Ich"] = true }
  W.bounty("Zweit-Ich", "Anna", 40)
  sight(W, "Zweit", "Ich", "nameplate5")
  check("eigener Char mit Kopfgeld: kein Alarm", shown(W) == nil)
  -- an own bounty only (on a target of the guild's book, guild alarm switched off): no new alarm
  ns.Store.Setting("guild.alert", false)
  local P, t = W.P, _G.time()
  W.gmsg(P.EncodeKill({ key = "Gilde-Feind", display = "Gilde Feind", class = "MAGE", level = 40, zone = "Z", t = t - 60,
    victim = "Anna Wurst" }), "Anna Wurst-Forever")
  W.tick(2)
  ns.Guild.SetBounty("Gilde-Feind", 25)
  W.tick(2)
  sight(W, "Gilde", "Feind", "nameplate6")
  check("nur eigenes Kopfgeld: kein Alarm", shown(W) == nil)
  local n, e = W.errs()
  check("(3) keine Fehler", n == 0, e)
end

-- (4) without Bounty.Others (an older logic): no hook, the line as in 1.6.4, no alarm for a bounty-only target
do
  local W = X.world("deDE")
  X.fake(W, { noOthers = true, noClaim = true })
  local ns, L = W.ns, W.L
  local key = W.kill("Grimm", "Bart")
  W.bounty(key, "Anna", 50)
  W.bounty("Kalt-Herz", "Anna", 80)
  check("ohne Others: kein Haken", ns.Tracker.bountyHook == nil)
  sight(W, "Grimm", "Bart")
  local p = shown(W)
  local frag = (L.ALERT_BOUNTY_BY:gsub("{gold}", ""):gsub("{name}", ""))
  check("ohne Others: Zeile wie 1.6.4", p and not tostring(p.line._text):find("Anna", 1, true), p and p.line._text)
  closeAlarm(W)
  sight(W, "Kalt", "Herz", "nameplate1")
  check("ohne Others: kein Nur-Kopfgeld-Alarm", shown(W) == nil)
  local n, e = W.errs()
  check("(4) keine Fehler", n == 0, e)
end

-- (5) the sighting path: while nobody else posted a bounty the hook stays away (not one call more per plate); with a
-- bounty of others one cheap look per hostile stranger (Bounty.Has), the rows only for a target that has one
do
  local W = X.world("deDE")
  X.fake(W)
  local ns = W.ns
  local B = ns.Bounty
  local has, others0 = 0, W.othersCalls
  local realHas = B.Has
  B.Has = function(...) has = has + 1; return realHas(...) end
  check("ohne fremde Kopfgelder: kein Haken", ns.Tracker.bountyHook == nil)
  for i = 1, 20 do sight(W, "Fremd", "Ling" .. string.char(64 + i), "nameplate" .. i) end
  check("ohne fremde Kopfgelder: kein Aufruf je Plakette", has == 0 and W.othersCalls == others0, has)
  W.bounty("Kalt-Herz", "Anna", 80)
  has = 0
  for i = 1, 20 do sight(W, "Neu", "Ling" .. string.char(64 + i), "nameplate" .. (20 + i)) end
  check("mit fremdem Kopfgeld: ein Has je fremder Plakette, keine Zeilen", has == 20 and W.othersCalls == others0,
    has .. " / " .. (W.othersCalls - others0))
  io.write(("  Messung Plakette: ohne fremde Kopfgelder 0 Aufrufe, mit: %d Has auf 20 Fremde, %d Others\n"):format(has,
    W.othersCalls - others0))
end

-- (6) secret values at the new places: a secret key never reaches the bounty look; a secret answer counts as none
do
  local W = X.world("deDE")
  X.fake(W)
  local ns = W.ns
  local sv = "SECRET_NAME"   -- a hidden value of the UI mock (issecretvalue answers true)
  if sv then
    check("geheimer Schluessel: kein Alarm, kein Fehler", pcall(ns.Alert.BountySpotted, sv, "target", "target"))
    local B = ns.Bounty
    local real = B.Others
    B.Others = function() return sv, { { char = sv, g = sv } } end
    check("geheime Antwort: kein Kopfgeld", ns.Look.OthersBounty("Kalt-Herz") == 0)
    B.Others = real
  else
    check("Mock kennt Geheimwerte", false)
  end
  local n, e = W.errs()
  check("(6) keine Fehler", n == 0, e)
end

X.done("cu170 alarm")
