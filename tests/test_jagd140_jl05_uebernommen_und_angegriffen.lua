-- Jagd Logik 05 (Zusammenspiel A x B): ein uebernommener Eintrag, der mich spaeter angreift (Haken), zeigt in der
-- Zeile von Gesucht weiter nur "uebernommen von Wendell" (OV.Tally prueft Kills und Beteiligungen, nicht Angriffe);
-- der Filter "Rachsucht" findet ihn, die Zeile sagt aber nicht warum.
-- Erwartet: die Zeile nennt den Angriff ("1x angegriffen"), wie bei jedem anderen Eintrag mit Angriffen (Look.Tally).
-- Aufruf: luajit <diese Datei> .
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = ADDON .. "/Media"
AM.locale = "deDE"
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Humor.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local bad, good = 0, 0
local function check(name, c, info)
  if c then good = good + 1 else bad = bad + 1; io.write("RED   ", name, "  -> ", tostring(info), "\n") end
end
local S = ns.Store
local k = S.AddManual("Grimm", "Bart", { fromGuild = true, adopt = { from = "Wendell Probe", src = "friends", kills = 2 } })
S.AddAttack({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = time(), zone = "Z", me = "Ich Selbst" })
local e = S.Get(k)
check("Vorbedingung: Angriff gezaehlt", S.Attacks(e) == 1, S.Attacks(e))
local line = ns.UI.OV.Tally(e)
check("Zeile eines uebernommenen Eintrags mit Angriff nennt den Angriff", type(line) == "string" and line:find("angegriffen", 1, true),
  line)
io.write(("jl05 a x b           %d gruen, %d rot\n"):format(good, bad))
os.exit(bad == 0 and 0 or 1)
