-- Copy of the efficiency hunter's test (fixer 2 1.6.0), red on b55addb; helpers tests/_je.lua, tests/_je_gross.lua.
-- Jagd 2 Effizienz 01 (hoch): Eine eingehende Sichtung T baut bei offenem Buch die ganze Gildenchronik neu, sofort im
-- Handler von CHAT_MSG_ADDON, in jedem Reiter. Weg: Call.ApplySight -> ns:Fire("SIGHTING") -> GuildLog.lua GL.OnSighting
-- -> GL.Add("sight") -> bump() + GUILDLOG_UPDATED -> GuildLogUI.UpdateMarks -> GL.Unseen -> GL.All (voller Bau).
-- Die Sichtung ist "quiet" (zaehlt nie fuer den Punkt am Reiter), der Bau ist also umsonst. Der Fix jl07 (reason "seen")
-- wird damit umgangen; die Zeile kam mit 5ce8ca9 (nach der ersten Jagd).
-- Gemessen (Attrappe, luajit -joff, 5 volle Gildenlisten + Freundesbuch, Chronik 14.000 Ereignisse, drei Laeufe): je Sichtung
-- 28,6 bis 33,8 ms, 10,9 MB Muell, 236.000 bis 245.000 Sortier-Vergleiche; Buch zu: 0,06 ms, 5 KB. 1.5.0 (S): 0,02 ms.
-- Szene Ganker mit 30 Zuschauern (je_m4): 29 empfangene T je Client in 5 Minuten.
-- Erwartet: eine Sichtung kostet bei offenem Buch keinen Neubau (unter 2.000 Vergleiche, unter 512 KB).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt). Die Attrappe ist nicht der Client.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local X = require("_je_gross")

local db = X.build(J, DIR)
local W = J.world(DIR, { db = db, guild = X.GUILD })
local ns, AM = W.ns, W.AM
W.tick(60)
W.open()
ns.UI.SetFilter("wanted"); W.tick(2)
local GL = ns.GuildLog
J.check("Vorbedingung: Chronik voll", #GL.All("all") >= 10000, #GL.All("all"))
local function sight(i)
  local text = ns.Call.EncodeSight(("G1x%d-Ling"):format(i), 1434, 41.2, 56.7, _G.time(), "4444-0-77")
  AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", ("Halter%d Wurst-Forever"):format(i))
end
local r = J.measure(function() sight(11) end)
print(("  eine Sichtung, Buch offen (Reiter Gesucht): %.2f ms, %.0f KB, %d Sortierlaeufe, %d Vergleiche"):format(r.ms, r.kb, r.sorts, r.cmps))
J.check("Sichtung bei offenem Buch: kein Neubau der Chronik (Vergleiche < 2000)", r.cmps < 2000, r.cmps)
J.check("Sichtung bei offenem Buch: unter 512 KB Muell", r.kb < 512, ("%.0f KB"):format(r.kb))
local unseen = GL.Unseen("seenTab")
J.check("Gegenprobe: die Sichtung zaehlt nicht fuer den Punkt am Reiter (der Bau war umsonst)", unseen == 0, unseen)
-- zehn Sichtungen in zehn Sekunden (ein Ganker, zehn Gildies sehen ihn)
local total = J.measure(function() for i = 1, 10 do sight(20 + i); W.tick(1) end end)
print(("  zehn Sichtungen in 10 s: %.1f ms, %.1f MB, %d Vergleiche"):format(total.ms, total.kb / 1024, total.cmps))
J.check("zehn Sichtungen: zusammen unter 20.000 Vergleiche", total.cmps < 20000, total.cmps)
ns:Fire("TOGGLE_UI"); W.tick(2)
local z = J.measure(function() sight(40) end)
print(("  Gegenprobe Buch zu: %.2f ms, %.0f KB, %d Vergleiche"):format(z.ms, z.kb, z.cmps))
J.check("Gegenprobe: Buch zu kostet nichts", z.cmps < 2000 and z.kb < 512, z.cmps)
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
