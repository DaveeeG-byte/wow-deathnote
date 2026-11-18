-- Copy of the efficiency hunter's test (fixer 2 1.6.0), red on b55addb; helpers tests/_je.lua, tests/_je_gross.lua.
-- Jagd 2 Effizienz 02 (mittel): Der Punkt am Reiter "Gilde" und die Zahl am Band werden ueber den vollen Bau der Chronik
-- berechnet (GuildLogUI.UpdateMarks -> GL.Unseen -> GL.NewSince -> GL.All: alle Taten aller Gilden- und Freundesfeinde,
-- 14.000 Ereignisse, ein Sortierlauf). Das laeuft beim Oeffnen des Buchs und nach jeder Aenderung der Gildendaten bei
-- offenem Buch, in jedem Reiter, auch wenn die Chronik nie aufgeschlagen wird.
-- Gemessen (Attrappe, luajit -joff, volles Buch): Buch oeffnen 36 bis 39 ms, 13,1 MB, 283.000 Vergleiche (1.5.0 mit
-- demselben Buch: 5,8 ms, 1,7 MB, 17.800). Eine Gilden-Tat K bei offenem Buch (Reiter Gesucht): Auffrischung 29 bis
-- 35 ms, 11,0 MB, 240.000 Vergleiche (1.5.0: 1,9 ms, 0,5 MB, 7.500). Antwort auf ein Hallo (60 R in 30 s): je 0,5 s ein Bau.
-- Erwartet: Oeffnen und eine Tat bleiben unter 60.000 Vergleichen und 4 MB; 60 R in 30 s unter 40 MB Muell.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt). Die Attrappe ist nicht der Client.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local X = require("_je_gross")

local db = X.build(J, DIR)
local W = J.world(DIR, { db = db, guild = X.GUILD })
local ns, AM = W.ns, W.AM
local P = ns.Guild.Proto
W.tick(60)
local o = J.measure(function() ns:Fire("TOGGLE_UI"); W.tick(1); W.tick(1) end)
print(("  Buch oeffnen (erstes Mal): %.1f ms, %.1f MB, %d Sortierlaeufe, %d Vergleiche"):format(o.ms, o.kb / 1024, o.sorts, o.cmps))
J.check("Buch oeffnen: unter 60.000 Vergleiche", o.cmps < 60000, o.cmps)
J.check("Buch oeffnen: unter 4 MB Muell", o.kb < 4096, ("%.1f MB"):format(o.kb / 1024))
ns.UI.SetFilter("wanted"); W.tick(2)
local function kill(i, kind)
  local text = P.EncodeKill({ key = ("G1x%d-Ling"):format(i), display = ("G1x%d Ling"):format(i), class = "MAGE", level = 40,
    zone = "Arathihochland", t = _G.time() - (kind == "R" and i * 50 or 0), victim = ("Halter%d Wurst"):format(i) }, kind or "K")
  AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", ("Halter%d Wurst-Forever"):format(i))
end
local k = J.measure(function() kill(7); W.tick(1) end)
print(("  eine Gilden-Tat K, Buch offen (Reiter Gesucht): %.1f ms, %.1f MB, %d Vergleiche"):format(k.ms, k.kb / 1024, k.cmps))
J.check("eine Gilden-Tat bei offenem Buch: unter 60.000 Vergleiche", k.cmps < 60000, k.cmps)
J.check("eine Gilden-Tat bei offenem Buch: unter 4 MB Muell", k.kb < 4096, ("%.1f MB"):format(k.kb / 1024))
-- eine Antwort auf ein Hallo: 60 R in 30 s (2 je Sekunde), Buch offen
local v0 = ns.GuildLog.Version()
local a = J.measure(function() for i = 1, 60 do kill(100 + i, "R"); W.tick(0.5) end end)
print(("  60 R in 30 s, Buch offen: %.0f ms (%.1f ms je Sekunde), %.0f MB (%.1f MB je Sekunde), %d Vergleiche, Chronik-Version +%d")
  :format(a.ms, a.ms / 30, a.kb / 1024, a.kb / 1024 / 30, a.cmps, ns.GuildLog.Version() - v0))
J.check("60 R in 30 s bei offenem Buch: unter 40 MB Muell", a.kb < 40 * 1024, ("%.0f MB"):format(a.kb / 1024))
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
