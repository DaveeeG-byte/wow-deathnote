-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen (Aufruf aus der Projektwurzel: luajit <datei> .)
-- Upgrade und Zurueck mit Logik UND Oberflaeche: Fixture 1.0.1 -> neuer Stand (alles Neue benutzt) -> 1.1.0 ->
-- wieder neuer Stand. Dazu Mischbetrieb 1.1.0 gegen neu mit allen Nachrichtentypen auf GUILD und WHISPER.
-- Aufruf: luajit beleg_f06_hoch_zurueck_hoch.lua <Projektkopie> [Ordner mit dem ganzen Addon 1.1.0]
-- Ohne zweiten Ordner laeuft 1.1.0 nur mit der Logik aus tests/fixtures/addon-1.1.0 (ohne dessen Oberflaeche).
local DIR = (arg[1] or "."):gsub("/+$", "")
local OLDUI = arg[2] and arg[2]:gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local ADDON = DIR .. "/DeathNote"
local OLD = OLDUI or (DIR .. "/tests/fixtures/addon-1.1.0")
local AM, BM, G
local pass, fail, lines = 0, 0, {}
local function erwartet(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "") end
end
local function copy(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local o = {}; seen[t] = o
  for k, v in pairs(t) do o[copy(k, seen)] = copy(v, seen) end
  return o
end
local FR = { "Fritz Frei" }
local function fresh()
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow"); BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"; G = BM.G
  AM.locale = "deDE"
end
local function before()
  AM.units.player.guild = "Die Testgilde"
  _G.C_FriendList = {
    GetNumFriends = function() return #FR end,
    GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end
-- lang = Kennung: der Mock waehlt sie ausdruecklich; lang = false: nichts gewaehlt, es gilt allein die Datei
-- (datei = Kennung der Sprachdatei, die wie in der TOC mitgeladen wird)
local function neu(db, lang, datei)
  fresh()
  if datei then AM.locale = datei end
  local ns = AM.Load({ noLogin = true, db = db, lang = lang, before = before })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function alt(db)
  fresh()
  AM.Reset()
  _G.DeathNoteDB = db
  before()
  local ns = {}
  for _, f in ipairs({ "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }) do
    assert(loadfile(OLD .. "/" .. f))("DeathNote", ns)
  end
  if OLDUI then for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(OLDUI .. "/" .. f, ns) end end
  AM.ns = ns
  AM.FireEvent("ADDON_LOADED", "DeathNote")
  AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local function fmsg(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz Frei-Forever") end
local function ui(ns)
  ns:Fire("TOGGLE_UI"); tick()
  for _, id in ipairs({ "wanted", "open", "journal", "guild", "wanted" }) do
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
    end
    tick()
  end
  if ns.UI and ns.UI.OpenPanel then ns.UI.OpenPanel("settings"); tick(); ns.UI.ClosePanel(); tick() end
  _G.SlashCmdList.DEATHNOTE("gilde"); _G.SlashCmdList.DEATHNOTE("hilfe"); _G.SlashCmdList.DEATHNOTE("sync")
  tick(5)
end
local function sauber(name)
  erwartet(name .. ": keine Fehler", #AM.errors == 0, AM.errors[1])
  erwartet(name .. ": keine Verstoesse im UI-Mock", #BM.violations == 0, BM.violations[1])
end
local function zaehle(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end return n end

-- 1) Fixture in den neuen Stand, alles Neue benutzen
local fx = {}
do local f = assert(loadfile(DIR .. "/tests/fixtures/sv_1.0.1_autor.lua")); setfenv(f, fx); f() end
local eigeneVorher, todeVorher = zaehle(fx.DeathNoteDB.enemies), #(fx.DeathNoteDB.deaths or {})
local ns = neu(copy(fx.DeathNoteDB), "ruRU")
tick(40)
local P = ns.Guild.Proto
local t = _G.time()
gmsg(P.EncodeKill({ key = "Boese-Wicht", display = "Boese Wicht", class = "MAGE", level = 40, zone = "Zone", t = t - 30, victim = "Kollege Lang" }, "K"))
gmsg(P.EncodeHunt({ key = "Zwei-Wicht", t = t - 20, by = "Kollege Lang", why = "Grund" }))
gmsg(P.EncodeBagged("Zwei-Wicht", "Kollege Lang", t))
fmsg(P.EncodeKill({ key = "Drei-Wicht", display = "Drei Wicht", class = "MAGE", level = 40, zone = "Zone", t = t - 45, victim = "Fritz Frei" }, "K"))
fmsg(P.EncodeHunt({ key = "Drei-Wicht", t = t - 20, by = "Fritz Frei", why = "Grund" }))
ns.Guild.Release("Vier-Wicht", { to = "all", why = "meins" })
ns.Guild.HideHunt("Zwei-Wicht", true)
ns.Store.Setting("guild.huntExpire", 90)
ns.Store.Setting("guild.announceHunt", false)
ns.UI.SetGuildView("hunt"); ns.UI.SetGuildSource("friends")
ui(ns)
AM.FireEvent("PLAYER_LOGOUT")
sauber("neuer Stand mit der Fixture")
local db1 = copy(_G.DeathNoteDB)
erwartet("Upgrade: eigenes Buch vollstaendig", zaehle(db1.enemies) >= eigeneVorher and #db1.deaths >= todeVorher,
  zaehle(db1.enemies) .. "/" .. eigeneVorher)
erwartet("Upgrade: DB-Version unveraendert 3", db1.version == 3, db1.version)
local gl1 = db1.guild.lists["Die Testgilde"]
erwartet("neuer Stand: Freigaben in beiden Listen, Bindung, Ausgeblendetes gespeichert",
  gl1 and gl1.hunts["Vier-Wicht"] and gl1.hunts["Zwei-Wicht"] and db1.friends.hunts["Drei-Wicht"] and db1.friends.hunts["Vier-Wicht"]
  and db1.friends.ties["Fritz Frei"] and db1.guild.huntHidden["Zwei-Wicht"] and true)

-- 2) zurueck auf 1.1.0, dort spielen
local o = alt(copy(db1))
tick(40)
gmsg(P.EncodeKill({ key = "Alt-Wicht", display = "Alt Wicht", class = "MAGE", level = 40, zone = "Zone", t = _G.time() - 5, victim = "Kollege Lang" }, "K"))
for _, m in ipairs({ P.EncodeHunt({ key = "Fuenf-Wicht", t = _G.time(), by = "Kollege Lang", why = "x" }), P.EncodeCallOff("Zwei-Wicht", "Kollege Lang"),
    P.EncodeBagged("Zwei-Wicht", "Kollege Lang", _G.time()) }) do
  gmsg(m); fmsg(m)
end
fmsg(P.EncodeHello(0, "1.2.0"))
local kOld = o.Store.AddManual("Unter", "Elfnull")
ui(o)
AM.FireEvent("PLAYER_LOGOUT")
sauber("1.1.0 mit der Datei des neuen Stands" .. (OLDUI and " (mit Oberflaeche)" or " (nur Logik)"))
local db2 = copy(_G.DeathNoteDB)
local gl2 = db2.guild and db2.guild.lists and db2.guild.lists["Die Testgilde"]
erwartet("1.1.0 laesst die Freigaben der Gilde stehen", gl2 and gl2.hunts and gl2.hunts["Vier-Wicht"] and gl2.hunts["Zwei-Wicht"] and true)
erwartet("1.1.0 nimmt J/A/E nicht an (Zwei-Wicht unveraendert, Fuenf-Wicht fehlt)",
  gl2 and gl2.hunts and gl2.hunts["Zwei-Wicht"] and gl2.hunts["Zwei-Wicht"].bagged == gl1.hunts["Zwei-Wicht"].bagged and gl2.hunts["Fuenf-Wicht"] == nil)
erwartet("1.1.0 laesst das Freundesbuch stehen", type(db2.friends) == "table" and db2.friends.hunts["Drei-Wicht"] and db2.friends.enemies["Drei-Wicht"]
  and db2.friends.ties["Fritz Frei"] and true)
erwartet("1.1.0 laesst Sprache und neue Schalter stehen", db2.settings.lang == "ruRU" and db2.settings.guild.huntExpire == 90
  and db2.settings.guild.announceHunt == false and db2.settings.ui.guildSource == "friends",
  tostring(db2.settings.lang) .. " " .. tostring(db2.settings.guild.huntExpire) .. " " .. tostring(db2.settings.ui.guildSource))
erwartet("1.1.0 laesst Ausgeblendetes stehen", db2.guild.huntHidden and db2.guild.huntHidden["Zwei-Wicht"] ~= nil)
io.write("  Hinweis: Ansicht des vierten Reiters nach 1.1.0: " .. tostring(db2.settings.ui.guildView) .. " (vorher hunt)\n")

-- 3) wieder hoch
ns = neu(copy(db2), false, "ruRU")
tick(40)
ui(ns)
sauber("wieder neuer Stand")
erwartet("Sprache nach dem Rundweg: Russisch aktiv, kein Dialog", ns.Locale.code == "ruRU" and ns.LangDialog == nil, ns.Locale.code)
erwartet("eigene Freigabe nach dem Rundweg in beiden Listen", (function() local g, f = ns.Guild.Released("Vier-Wicht"); return g and f end)())
erwartet("fremde Freigaben nach dem Rundweg da", ns.Guild.Hunt("Zwei-Wicht", "guild") ~= nil and ns.Guild.Hunt("Drei-Wicht", "friends") ~= nil)
erwartet("ausgeblendet bleibt ausgeblendet", ns.Guild.HuntHidden("Zwei-Wicht") == true)
erwartet("Eintrag aus der Zeit unter 1.1.0 ist im Buch", ns.Store.Get(kOld) ~= nil)
erwartet("Tat aus der Zeit unter 1.1.0 ist im Gildenbuch", ns.Guild.Get("Alt-Wicht", "guild") ~= nil)
erwartet("eigenes Buch vollstaendig", zaehle(_G.DeathNoteDB.enemies) >= eigeneVorher + 1)
erwartet("Verfall-Einstellung blieb 90", ns.Store.Setting("guild.huntExpire") == 90, ns.Store.Setting("guild.huntExpire"))

io.write(("beleg_f06_hoch_zurueck_hoch %3d gruen, %d rot\n"):format(pass, fail))
for _, l in ipairs(lines) do io.write(l .. "\n") end
os.exit(fail == 0 and 0 or 1)
