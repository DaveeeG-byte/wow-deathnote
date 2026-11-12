-- 1.3.0 package C: the victim alarm (alert.victims) and the alarm for an even or overpaid standing (alert.settled),
-- with the real logic (tests/mock_wow.lua, the rap sheet of Ledger.lua) and the UI mock (tests/ui/mock.lua).
-- Every condition has a case that fires and one that does not. Checks go through keys, data, sounds and frames,
-- never through wording. All names are made up.
-- Call from the project root: luajit tests/ui/victim_alarm.lua [project copy]
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/victim_alarm.lua"
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1 else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end
local function case(name, fn)
  local fine, err = pcall(fn)
  if not fine then bad = bad + 1; io.write("RED   ", name, " (error): ", tostring(err), "\n") end
end

local ME = "Player-93-0000AAAA"
local AM, BM, G, ns, L
local plate = 0

-- a fresh client: logic, then Alert/UI/Extras/Humor; settings before the login
local function world(settings)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  -- one clock for the logic and the UI (the UI mock alone has a fixed time())
  rawset(G, "time", function() return _G.time() end)
  local db = { settings = { alert = {} } }
  for k, v in pairs(settings or {}) do db.settings.alert[k] = v end
  ns = AM.Load({ noLogin = true, db = db })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  L = ns.L
  plate = 0
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
-- every popup and notice gone, every cooldown over (the alarm of the book 90 s, the victim alarm 600 s)
local function settle()
  for _ = 1, 3 do BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims() end
  local b = rawget(G, "DeathNoteBanner")
  if b then b:Hide() end
end
local function wait(s) settle(); tick(s or 700); settle() end
local function set(path, v) ns.Store.Setting(path, v) end

-- an enemy on a nameplate (the tracker sees him: ENEMY_SPOTTED, the victim hook)
local function see(name, surname, o)
  plate = plate + 1
  o = o or {}
  o.name, o.surname = name, surname
  o.guid = o.guid or ("Player-93-" .. name .. surname)
  AM.AddEnemy("nameplate" .. plate, o)
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  tick()
  return o.guid
end
-- my killing blow on him (seen first, so the rap sheet knows him); 11 s later the next one counts again
local function kill(name, surname)
  local g = see(name, surname)
  AM.FireEvent("PARTY_KILL", ME, g)
  tick(11)
  settle()
end
-- his killing blow on me (a book entry with one more kill)
local function dieTo(name, surname)
  ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
    { t = _G.time(), zone = "Schlingendorntal", me = "Varorak Narenmar", myLevel = 40, source = "recap", others = {} }, true)
  tick()
  settle()
end
local function key(name, surname) return ns.Util.KeyFor(name, surname) end

local function popup() return rawget(G, "DeathNoteAlert") end
local function shown() local p = popup(); return p ~= nil and p:IsShown() end
local function title() return shown() and popup().title._text or nil end
local function line() return shown() and popup().line._text or "" end
local function nameIs(n) return shown() and tostring(popup().name._text):find(n, 1, true) ~= nil end
local function waiting() local p = popup(); return p and p.more._text or "" end
local function clearSounds() BM.soundCalls = {}; local f = rawget(G, "DeathNoteFlash"); if f then f._shown = false end end
local function quietSound()
  for _, c in ipairs(BM.soundCalls) do
    if c.file and tostring(c.file):find("feder_1.ogg", 1, true) then return true end
  end
  return false
end
local function loudSound()
  for _, c in ipairs(BM.soundCalls) do
    if c.kit or (c.file and not tostring(c.file):find("feder_1.ogg", 1, true)) then return true end
  end
  return false
end
local function flashed() local f = rawget(G, "DeathNoteFlash"); return f ~= nil and f._shown == true end
local function noErrors(name)
  check(name .. ": no Lua errors", #AM.errors == 0, AM.errors[1]); AM.errors = {}
  check(name .. ": no protected-call violations", #BM.violations == 0, BM.violations[1]); BM.violations = {}
end

---------------------------------------------------------------------------
case("default: the victim alarm is off and never fires", function()
  world()
  check("default: alert.victims is false", ns.Store.Setting("alert.victims") == false, ns.Store.Setting("alert.victims"))
  kill("Opfer", "Eins")
  check("default: the victim is booked (precondition)", ns.Ledger.Victim(key("Opfer", "Eins")) ~= nil)
  check("default: no victim hook in the tracker (the nameplate path pays a nil test only)", ns.Tracker.victimHook == nil)
  wait()
  clearSounds()
  see("Opfer", "Eins")
  check("default: no popup for a victim", not shown(), title())
  check("default: no sound", #BM.soundCalls == 0)
  -- the alarm itself checks the switch too (not only the hook of the tracker)
  ns:Fire("VICTIM_SPOTTED", key("Opfer", "Eins"), "nameplate1", "nameplate")
  check("default: VICTIM_SPOTTED with the switch off shows nothing", not shown(), title())
  noErrors("default")
end)

case("switch on: a fresh victim fires, with its own head, the score, the soft sound, no edge pulse", function()
  world({ victims = true })
  kill("Opfer", "Eins")
  check("on: the victim hook is set", ns.Tracker.victimHook ~= nil)
  wait()
  clearSounds()
  see("Opfer", "Eins")
  check("on: popup for the victim", nameIs("Opfer"), title())
  check("on: the head is ALERT_TITLE_VICTIM", title() == L.ALERT_TITLE_VICTIM, title())
  check("on: the line shows the score me : him", line():find("1 : 0", 1, true) ~= nil, line())
  local ago = ns.Util.Ago(ns.Ledger.Victim(key("Opfer", "Eins")).last)
  check("on: the line shows the time of my last kill", line():find(ago, 1, true) ~= nil, line() .. " / " .. ago)
  check("on: the soft fixed sound (feder, level 1)", quietSound(), BM.soundCalls[1] and (BM.soundCalls[1].file or BM.soundCalls[1].kit))
  check("on: no loud sound", not loudSound())
  check("on: no edge pulse", not flashed())
  check("on: the head is a show word a theme may overlay (Locale.THEME_KEYS)", ns.Locale.THEME_KEYS.ALERT_TITLE_VICTIM == true)
  local p = popup()
  check("on: head and line are whole (nothing cut)", p.title.cut == false and p.line.cut == false,
    tostring(p.title.cut) .. " " .. tostring(p.line.cut))
  noErrors("on")
end)

case("the chosen alarm sound does not change the soft sound; 'no sound' silences it", function()
  world({ victims = true, soundKey = "sirene", volume = 5 })
  kill("Opfer", "Eins")
  wait(); clearSounds()
  see("Opfer", "Eins")
  check("sound: still feder level 1 with sirene at volume 5", quietSound() and not loudSound())
  wait(); clearSounds()
  ns.Look.SetSound("aus")
  see("Opfer", "Eins")
  check("sound off: the popup comes", shown())
  check("sound off: no sound at all", #BM.soundCalls == 0, BM.soundCalls[1] and BM.soundCalls[1].file)
  noErrors("sound")
end)

case("14 days: my last kill longer ago does not fire, within the window it does", function()
  world({ victims = true })
  kill("Opfer", "Eins")
  local v = ns.Ledger.Victim(key("Opfer", "Eins"))
  v.last = _G.time() - 15 * 86400
  wait()
  see("Opfer", "Eins")
  check("15 days: no popup", not shown(), title())
  v.last = _G.time() - 13 * 86400
  wait()
  see("Opfer", "Eins")
  check("13 days: popup", nameIs("Opfer"), title())
  noErrors("window")
end)

case("cooldown: 10 minutes per victim, its own (not the 90 s of the book)", function()
  world({ victims = true })
  kill("Opfer", "Eins")
  wait()
  see("Opfer", "Eins")
  check("cooldown: first sighting fires", nameIs("Opfer"))
  settle(); tick(120); settle()
  see("Opfer", "Eins")
  check("cooldown: after 2 min (past the 90 s of the book) no second popup", not shown(), title())
  tick(300); settle()
  see("Opfer", "Eins")
  check("cooldown: after 7 min still none", not shown(), title())
  tick(200); settle()
  see("Opfer", "Eins")
  check("cooldown: after 10+ min it fires again", nameIs("Opfer"), title())
  noErrors("cooldown")
end)

case("standing: only when it is in my favour (me > him); pardoned never", function()
  world({ victims = true })
  -- he killed me once, I killed him once: even, in the book; the book is off for him (minKills 2) so only the
  -- victim alarm could speak
  set("alert.minKills", 2)
  dieTo("Gleich", "Stand")
  kill("Gleich", "Stand")
  local m, h, s = ns.Ledger.Standing(key("Gleich", "Stand"))
  check("even: precondition 1 : 1 even", m == 1 and h == 1 and s == "even", tostring(m) .. ":" .. tostring(h) .. " " .. tostring(s))
  wait()
  see("Gleich", "Stand")
  check("even (me = him): no victim popup", not shown(), title())
  -- I kill him again: 2 : 1, overpaid, still under the book's threshold: the victim alarm speaks
  kill("Gleich", "Stand")
  wait()
  see("Gleich", "Stand")
  check("ahead (me > him) under the book's threshold: victim popup", shown() and title() == L.ALERT_TITLE_VICTIM, title())
  check("ahead: the line shows 2 : 1", line():find("2 : 1", 1, true) ~= nil, line())
  -- pardoned: never
  wait()
  ns.Store.SetStatus(key("Gleich", "Stand"), "pardoned")
  see("Gleich", "Stand")
  check("pardoned: no popup", not shown(), title())
  noErrors("standing")
end)

case("a case of the book: the alarm of the book speaks, never a second popup", function()
  world({ victims = true })
  -- he leads 2 : 1: an open case (me <= him)
  dieTo("Offen", "Fall"); dieTo("Offen", "Fall")
  kill("Offen", "Fall")
  wait(); clearSounds()
  see("Offen", "Fall")
  check("open case: the alarm of the book", shown() and title() ~= L.ALERT_TITLE_VICTIM, title())
  check("open case: the line shows the score 1 : 2", line():find("1 : 2", 1, true) ~= nil, line())
  check("open case: nothing waits behind it (no second popup for the same player)", waiting() == "", waiting())
  settle()
  check("open case: after it, no victim popup follows", not shown(), title())
  -- overpaid and alarm-worthy in the book (threshold 1): the alarm of the book, with the score, not the victim alarm
  wait()
  kill("Offen", "Fall"); kill("Offen", "Fall")
  wait(); clearSounds()
  see("Offen", "Fall")
  check("overpaid in the book: the alarm of the book", shown() and title() ~= L.ALERT_TITLE_VICTIM, title())
  check("overpaid in the book: line with the overpaid score",
    line():find(ns.F(L.ALERT_LINE_STANDING_AHEAD, { text = "", score = "3 : 2" }), 1, true) ~= nil, line())
  check("overpaid in the book: 'always' keeps the loud sound and the pulse", loudSound() and flashed())
  check("overpaid in the book: no second popup waits", waiting() == "", waiting())
  -- seen again within the 90 s of the book: the book is on cooldown, the victim alarm still does not step in
  BM.Advance(13); BM.FinishAnims(); BM.Advance(1); tick(5)
  check("overpaid in the book: the popup closed (precondition)", not shown(), title())
  see("Offen", "Fall")
  check("overpaid in the book, book on cooldown: no victim popup either", not shown(), title())
  noErrors("book case")
end)

case("overpaid in the book with alert.settled = off: no alarm at all, not even the victim alarm", function()
  world({ victims = true, settled = "off" })
  dieTo("Weit", "Vorn")
  kill("Weit", "Vorn"); kill("Weit", "Vorn")
  local _, _, s = ns.Ledger.Standing(key("Weit", "Vorn"))
  check("settled off + ahead: precondition overpaid", s == "ahead", s)
  wait(); clearSounds()
  see("Weit", "Vorn")
  check("settled off + ahead: no popup", not shown(), title())
  check("settled off + ahead: no sound", #BM.soundCalls == 0)
  -- a victim only in the rap sheet is no settled case: it fires
  kill("Nur", "Opfer")
  wait()
  see("Nur", "Opfer")
  check("settled off: a victim without a book entry still fires", shown() and title() == L.ALERT_TITLE_VICTIM, title())
  noErrors("settled off ahead")
end)

case("rap sheet off: no victim alarm, the alarm line as in 1.2.2", function()
  world({ victims = true, settled = "off" })
  dieTo("Alt", "Bekannt")
  kill("Alt", "Bekannt"); kill("Alt", "Bekannt")
  set("ledger.enabled", false)
  check("off: Ledger.Standing gives nil", ns.Ledger.Standing(key("Alt", "Bekannt")) == nil)
  check("off: Look.Score gives nil", ns.Look.Score(key("Alt", "Bekannt")) == nil)
  check("off: no victim hook", ns.Tracker.victimHook == nil)
  -- a victim only in the rap sheet
  kill("Nur", "Register")
  wait(); clearSounds()
  see("Nur", "Register")
  check("off: no victim popup", not shown(), title())
  ns:Fire("VICTIM_SPOTTED", key("Nur", "Register"), "nameplate1", "nameplate")
  check("off: VICTIM_SPOTTED with the rap sheet off shows nothing", not shown(), title())
  -- the book entry (overpaid while on) alarms like 1.2.2, settled = off does not apply, revenge as in 1.2.2
  wait(); clearSounds()
  see("Alt", "Bekannt")
  local e = ns.Store.Get(key("Alt", "Bekannt"))
  check("off: the alarm of the book fires (settled = off has no effect)", shown() and title() ~= L.ALERT_TITLE_VICTIM, title())
  check("off: no score in the line", not line():find(" : ", 1, true), line())
  check("off: the revenge count of 1.2.2 in the line", (e.revenge or 0) > 0 and
    line():find(ns.F(L.ALERT_LINE_REVENGE, { text = "", times = ns.Look.Times(e.revenge) }), 1, true) ~= nil, line())
  check("off: loud sound and pulse as in 1.2.2", loudSound() and flashed())
  noErrors("ledger off")
end)

case("alert.settled: always / quiet / off for an even standing; open cases never touched", function()
  for _, mode in ipairs({ "always", "quiet", "off" }) do
    world({ settled = mode })
    dieTo("Quitt", "Gegner")
    kill("Quitt", "Gegner")
    dieTo("Offen", "Gegner"); dieTo("Offen", "Gegner")
    kill("Offen", "Gegner")
    wait(); clearSounds()
    see("Quitt", "Gegner")
    local tag = "settled " .. mode .. ": "
    if mode == "off" then
      check(tag .. "no alarm for even", not shown(), title())
      check(tag .. "no sound", #BM.soundCalls == 0)
    else
      check(tag .. "alarm for even", nameIs("Quitt"), title())
      check(tag .. "the line shows the even score",
        line():find(ns.F(L.ALERT_LINE_STANDING_EVEN, { text = "", score = "1 : 1" }), 1, true) ~= nil, line())
      if mode == "always" then
        check(tag .. "loud sound and edge pulse", loudSound() and flashed() and not quietSound())
      else
        check(tag .. "the soft sound", quietSound() and not loudSound())
        check(tag .. "no edge pulse", not flashed())
      end
    end
    wait(); clearSounds()
    see("Offen", "Gegner")
    check(tag .. "the open case alarms as always (loud, pulse)", nameIs("Offen") and loudSound() and flashed(), title())
    noErrors(tag)
  end
end)

case("queue: a victim waits behind every other alarm and gives way at once", function()
  world({ victims = true })
  dieTo("Taeter", "Eins"); dieTo("Taeter", "Zwei")
  kill("Opfer", "Eins"); kill("Opfer", "Zwei")
  wait()
  -- the victim on the screen, a killer comes: the killer replaces it at once
  see("Opfer", "Eins")
  check("queue: victim shown (precondition)", nameIs("Opfer") and title() == L.ALERT_TITLE_VICTIM, title())
  see("Taeter", "Eins")
  check("queue: the killer replaces the victim at once", nameIs("Taeter") and title() ~= L.ALERT_TITLE_VICTIM, title())
  wait()
  -- the killer on the screen: a victim waits, a second killer goes in front of it
  see("Taeter", "Eins")
  see("Opfer", "Zwei")
  check("queue: the victim does not replace the killer", nameIs("Taeter Eins"), popup().name._text)
  see("Taeter", "Zwei")
  check("queue: two waiting", waiting() ~= "", waiting())
  BM.Advance(13); BM.FinishAnims(); BM.Advance(1)
  check("queue: the second killer comes first", nameIs("Taeter Zwei"), shown() and popup().name._text)
  BM.Advance(13); BM.FinishAnims(); BM.Advance(1)
  check("queue: then the victim", nameIs("Opfer Zwei") and title() == L.ALERT_TITLE_VICTIM, shown() and popup().name._text)
  noErrors("queue")
end)

case("queue full: a killer pushes the last waiting victim out, a victim never pushes anyone", function()
  world({ victims = true })
  for i = 1, 10 do kill("Opfer", "N" .. string.char(64 + i)) end
  dieTo("Taeter", "Eins"); dieTo("Taeter", "Zwei")
  wait()
  see("Taeter", "Eins")
  for i = 1, 9 do see("Opfer", "N" .. string.char(64 + i)) end
  check("full: nine waiting", waiting() == ns.F(L.ALERT_MORE, { count = 9 }), waiting())
  see("Opfer", "NJ")
  check("full: a tenth victim finds no place", waiting() == ns.F(L.ALERT_MORE, { count = 9 }), waiting())
  see("Taeter", "Zwei")
  check("full: the killer still gets a place", waiting() == ns.F(L.ALERT_MORE, { count = 9 }), waiting())
  BM.Advance(13); BM.FinishAnims(); BM.Advance(1)
  check("full: the killer comes next", nameIs("Taeter Zwei"), shown() and popup().name._text)
  -- the victim pushed out (the last one, NI) got its cooldown back: it can come at once
  settle(); for _ = 1, 10 do BM.Advance(13); BM.FinishAnims(); BM.Advance(1) end
  see("Opfer", "NI")
  check("full: the pushed-out victim may come again at once", nameIs("Opfer NI"), shown() and popup().name._text)
  noErrors("queue full")
end)

case("the victim becomes a case of the book while shown: the popup turns into the alarm of the book", function()
  world({ victims = true })
  kill("Wechsel", "Fall")
  wait()
  see("Wechsel", "Fall")
  check("turn: victim shown (precondition)", title() == L.ALERT_TITLE_VICTIM, title())
  -- he kills me twice: 1 : 2, open
  ns.Store.ApplyKill({ name = "Wechsel", surname = "Fall", class = "ROGUE", level = 40, guid = "Player-93-WechselFall" },
    { t = _G.time(), zone = "Z", me = "Varorak Narenmar", myLevel = 40, source = "recap", others = {} }, true)
  ns.Store.ApplyKill({ name = "Wechsel", surname = "Fall", class = "ROGUE", level = 40, guid = "Player-93-WechselFall" },
    { t = _G.time(), zone = "Z", me = "Varorak Narenmar", myLevel = 40, source = "recap", others = {} }, true)
  tick()
  local p = popup()
  check("turn: the popup is the alarm of the book now",
    p:IsShown() and p.title._text ~= L.ALERT_TITLE_VICTIM and tostring(p.name._text):find("Wechsel", 1, true) ~= nil,
    p.title._text)
  check("turn: the line shows 1 : 2", tostring(p.line._text):find("1 : 2", 1, true) ~= nil, p.line._text)
  noErrors("turn")
end)

case("switch off while a victim is shown: it closes; the line follows a new kill", function()
  world({ victims = true })
  kill("Opfer", "Eins")
  wait()
  see("Opfer", "Eins")
  ns:Fire("STANDING_CHANGED", key("Opfer", "Eins"))
  check("refresh: still shown with the score", line():find("1 : 0", 1, true) ~= nil, line())
  set("alert.victims", false)
  ns:Fire("STANDING_CHANGED", key("Opfer", "Eins"))
  BM.FinishAnims()
  check("refresh: closed after the switch went off", not shown(), title())
  noErrors("refresh")
end)

case("combat: no protected call, the target button is never re-pointed in combat", function()
  world({ victims = true })
  kill("Opfer", "Eins")
  dieTo("Taeter", "Eins")
  wait()
  see("Opfer", "Eins")
  local b = rawget(G, "DeathNoteAlertButton")
  check("combat: the victim popup has the target button out of combat",
    b and b:IsShown() and tostring(b._attrs and b._attrs.macrotext1 or b:GetAttribute("macrotext1")):find("Opfer", 1, true) ~= nil)
  BM.combat = true; AM.inCombat = true
  AM.FireEvent("PLAYER_REGEN_DISABLED"); tick()
  see("Taeter", "Eins")
  check("combat: the killer replaces the victim on the screen", nameIs("Taeter"), title())
  check("combat: the hint says targeting only after combat", popup().hint._text == L.ALERT_HINT_COMBAT, popup().hint._text)
  local still = rawget(G, "DeathNoteAlertButton")
  local macro = still and (still._attrs and still._attrs.macrotext1 or still:GetAttribute("macrotext1"))
  check("combat: the button was not re-pointed in combat", not (still and still:IsShown()) or tostring(macro):find("Opfer", 1, true) ~= nil
    or tostring(macro):find("Taeter", 1, true) == nil, macro)
  BM.combat = false; AM.inCombat = false
  AM.FireEvent("PLAYER_REGEN_ENABLED"); tick()
  local after = rawget(G, "DeathNoteAlertButton")
  local m2 = after and (after._attrs and after._attrs.macrotext1 or after:GetAttribute("macrotext1"))
  check("combat over: the button points at the killer", after and after:IsShown() and tostring(m2):find("Taeter", 1, true) ~= nil, m2)
  noErrors("combat")
end)

case("Look.Score: the text me : him of a key", function()
  world()
  dieTo("Zahl", "Stand")
  kill("Zahl", "Stand"); kill("Zahl", "Stand")
  local s, m, h, st = ns.Look.Score(key("Zahl", "Stand"))
  check("score: text 2 : 1", s == "2 : 1", s)
  check("score: values and state", m == 2 and h == 1 and st == "ahead", tostring(m) .. tostring(h) .. tostring(st))
  check("score: nothing for an unknown key", ns.Look.Score("Niemand-Hier") == nil)
  noErrors("score")
end)

io.write(("victim alarm: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
