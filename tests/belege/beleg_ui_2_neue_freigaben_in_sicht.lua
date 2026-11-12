-- Proof UI 2: "new calls as a chat line, unless the target is in sight: then the alert" (Extras.lua, fix-3).
-- Usage: nice -n 15 luajit beleg_ui_2_neue_freigaben_in_sicht.lua <project copy>
-- Part 1 (counter-check): a new target in sight -> alert, no chat line; not in sight -> one chat line.
-- Part 2: three new targets arrive together (summary message), one of them is in sight -> expected: alert for
--         that one. (The summary names only the first target, the sight check runs only for exactly one.)
-- Part 3: switch "Report hit list" off, "Warn for hit list targets" on, a new target in sight
--         -> expected: the alert comes (it has its own switch), no chat line.
-- Part 4 (counter-checks): warn off -> chat line instead of alert; hidden target -> nothing; target comes into
--         sight shortly after the chat line -> exactly one alert; pipe characters in name and reason do not reach the chat.
-- All names are made up. Language does not matter (checks whether lines and windows come, not their wording).
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function fresh()
  local W = K.world("deDE")
  W.whisper(W.P.EncodeHello(0, "1.2.0")); W.tick(2)
  W.c0 = #W.AM.chat
  function W.lines() local t = {} for i = W.c0 + 1, #W.AM.chat do t[#t + 1] = W.AM.chat[i] end return t end
  function W.popup() local p = rawget(W.BM.G, "DeathNoteAlert"); return p and p:IsShown() and p or nil end
  function W.hunt(key, disp, why, by, from)
    W.gmsg(W.P.EncodeHunt({ key = key, display = disp, t = _G.time(), by = by or "Kollege Wurst", why = why or "x", level = 40, class = "MAGE" }), from)
  end
  function W.sicht(name, surname) W.AM.AddEnemy("mouseover", { name = name, surname = surname, guid = "Player-1-" .. name .. surname, level = 40 }) end
  return W
end
local function sauber(W, name) local n, e = W.errs(); K.check(name .. ": keine Fehler", n == 0, e) end

-- Part 1
do
  local W = fresh()
  W.sicht("Neu", "Eins"); W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  K.check("1 ein neues Ziel in Sicht: Alarm", W.ns.Alert.Shows("Neu-Eins") and W.popup() ~= nil)
  K.check("1 ein neues Ziel in Sicht: keine Chatzeile", #W.lines() == 0, #W.lines())
  sauber(W, "1")
  W = fresh()
  W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  K.check("1 nicht in Sicht: eine Chatzeile, kein Fenster", #W.lines() == 1 and W.popup() == nil, #W.lines())
  sauber(W, "1b")
end

-- Part 2
for _, pos in ipairs({ 1, 2, 3 }) do
  local W = fresh()
  local names = { "Eins", "Zwei", "Drei" }
  W.sicht("Neu", names[pos])
  for i = 1, 3 do W.hunt("Neu-" .. names[i], "Neu " .. names[i]) end
  W.tick(10)
  K.info(("2 drei neue, das %d. in Sicht: Chatzeilen %d, Alarm %s"):format(pos, #W.lines(), tostring(W.ns.Alert.Shows("Neu-" .. names[pos]))))
  K.check(("2 drei neue Ziele, das %d. steht in Sicht: Alarm fuer dieses Ziel"):format(pos), W.ns.Alert.Shows("Neu-" .. names[pos]))
  sauber(W, "2." .. pos)
end

-- Part 3
do
  local W = fresh()
  W.ns.Store.Setting("guild.announceHunt", false)
  K.check("3 Vorbedingung: Warnen bei Zielen der Abschussliste ist an", W.ns.Store.Setting("guild.alertHunt") == true)
  W.sicht("Neu", "Eins"); W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  K.check("3 Melden aus: keine Chatzeile", #W.lines() == 0, #W.lines())
  K.check("3 Melden aus, Warnen an, Ziel in Sicht: Alarm", W.ns.Alert.Shows("Neu-Eins"))
  sauber(W, "3")
end

-- Part 4
do
  local W = fresh()
  W.ns.Store.Setting("guild.alertHunt", false)
  W.sicht("Neu", "Eins"); W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  K.check("4 Warnen aus, in Sicht: Chatzeile statt Alarm", #W.lines() == 1 and not W.ns.Alert.Shows("Neu-Eins"))
  sauber(W, "4a")
  W = fresh()
  W.hunt("Neu-Eins", "Neu Eins"); W.tick(10); W.ns.Guild.HideHunt("Neu-Eins", true); W.c0 = #W.AM.chat
  W.sicht("Neu", "Eins"); W.hunt("Neu-Eins", "Neu Eins", "y", "Anna Blume", "Anna-Forever"); W.tick(10)
  K.check("4 ausgeblendetes Ziel: weder Zeile noch Alarm", #W.lines() == 0 and W.popup() == nil)
  sauber(W, "4b")
  W = fresh()
  W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  W.sicht("Neu", "Eins"); W.AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); W.tick(1)
  K.check("4 kommt nach der Chatzeile in Sicht: Alarm, weiter nur eine Zeile", W.ns.Alert.Shows("Neu-Eins") and #W.lines() == 1)
  sauber(W, "4c")
  W = fresh()
  W.hunt("Neu-Eins", "|cffff0000Neu|r |TInterface\\Icons\\x:64|t Eins|", "ein |cffff0000roter|r Grund |Hunit:1|h[klick]|h |")
  W.tick(10)
  local l = W.lines()[1] or ""
  local rest = l:gsub("^|c%x%x%x%x%x%x%x%x[^|]*|r", "")     -- the chat line's own coloured prefix
  K.check("4 Pipe-Zeichen aus Name und Grund kommen nicht in den Chat", #W.lines() == 1 and not rest:find("|", 1, true), rest)
  sauber(W, "4d")
  W = fresh()
  W.BM.combat = true; W.AM.combat = true
  W.sicht("Neu", "Eins"); W.hunt("Neu-Eins", "Neu Eins"); W.tick(10)
  K.check("4 im Kampf, in Sicht: Alarm ohne Verstoss", W.ns.Alert.Shows("Neu-Eins"))
  sauber(W, "4e")
end

K.done("beleg_ui_2 neue Freigaben in Sicht")
