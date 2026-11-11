-- 1.2.1: eigenes Kopfgeld, geteilt mit Gilde und Freunden (B und Y). Aufruf: luajit beleg_b01_kopfgeld.lua <Projektkopie>
-- Geprueft werden Daten und Nachrichten, keine Wortlaute. Alle Namen sind erfunden.
-- 1.1.0 kommt aus tests/fixtures/addon-1.1.0, 1.2.0 aus tests/fixtures/addon-1.2.0 (nur lesen).
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"
local OLD = H.DIR .. "/tests/fixtures/addon-1.1.0/"
local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
local V120 = H.DIR .. "/tests/fixtures/addon-1.2.0/"
local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }

local function gleich(a, b, pfad, out)
  out = out or {}
  if type(a) ~= type(b) then out[#out + 1] = pfad; return out end
  if type(a) ~= "table" then if a ~= b then out[#out + 1] = pfad end return out end
  for k, v in pairs(a) do gleich(v, b[k], pfad .. "." .. tostring(k), out) end
  for k in pairs(b) do if a[k] == nil then out[#out + 1] = pfad .. "." .. tostring(k) .. " (neu)" end end
  return out
end
local function zeilen(c, key)
  local rows, sum = c.ns.Guild.Bounties(key)
  local by = {}
  for _, r in ipairs(rows) do by[r.char] = r.g end
  return by, sum, #rows
end
local function typen(W, von)
  local t = {}
  for _, m in ipairs(W.sent) do if not von or m.sender == von then t[m.text:match("^1\t(%u)\t") or "?"] = true end end
  return t
end

H.lauf("(1) setzen: Kollegin und Freund sehen Betrag und Auslober, Rueckgabe nimmt es ueberall zurueck", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" }, fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); W.run(90)
  local ok, why = a.ns.Guild.SetBounty("Grimm-Bart", 500)
  H.erwartet("SetBounty nimmt 500 Gold", ok == true, why)
  W.run(10)
  local tb = typen(W, a)
  H.erwartet("ein B ging hinaus", tb.B == true)
  local bb, bs = zeilen(b, "Grimm-Bart")
  H.erwartet("Kollegin: 500 Gold von Anton Wurst", bb["Anton Wurst"] == 500 and bs == 500, tostring(bb["Anton Wurst"]))
  local fb = zeilen(f, "Grimm-Bart")
  H.erwartet("Freund: 500 Gold von Anton Wurst", fb["Anton Wurst"] == 500, tostring(fb["Anton Wurst"]))
  local ab, asum = zeilen(a, "Grimm-Bart")
  H.erwartet("eigenes Buch: als eigenes erkennbar", ab["Anton Wurst"] == 500 and asum == 500 and a.ns.Guild.Bounties("Grimm-Bart")[1].mine == true)
  H.erwartet("HasBounty bei allen", a.ns.Guild.HasBounty("Grimm-Bart") and b.ns.Guild.HasBounty("Grimm-Bart") and f.ns.Guild.HasBounty("Grimm-Bart"))
  -- unabhaengig von der Abschussliste und davon, ob der Taeter in einem Buch steht
  H.erwartet("kein Eintrag auf der Abschussliste noetig", b.ns.Guild.Hunt("Grimm-Bart", "all") == nil)
  -- erhoehen: ersetzt, nicht addiert
  a.ns.Guild.SetBounty("Grimm-Bart", 750); W.run(10)
  bb, bs = zeilen(b, "Grimm-Bart")
  H.erwartet("neuer Betrag ersetzt den alten", bb["Anton Wurst"] == 750 and bs == 750, tostring(bs))
  -- zuruecknehmen
  ok = a.ns.Guild.SetBounty("Grimm-Bart", 0); W.run(10)
  H.erwartet("0 nimmt zurueck", ok == true and a.ns.Guild.OwnBounty("Grimm-Bart") == nil)
  H.erwartet("bei Kollegin und Freund weg", not b.ns.Guild.HasBounty("Grimm-Bart") and not f.ns.Guild.HasBounty("Grimm-Bart"))
  local ok2, why2 = a.ns.Guild.SetBounty("Grimm-Bart", nil)
  H.erwartet("nichts zurueckzunehmen: none", ok2 == nil and why2 == "none", why2)
end)

H.lauf("(2) Betrag ist eine Zahl: beim Senden und beim Empfang hart geprueft", function()
  local W = H.welt()
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  b.login(); W.run(60)
  local P = b.ns.Guild.Proto
  local t = time()
  for _, g in ipairs({ 0.5, 100000, -1, 0 / 0, math.huge, "500" }) do
    H.erwartet("EncodeBounty verweigert " .. tostring(g), P.EncodeBounty("Grimm-Bart", "Anton Wurst", g, t) == nil)
  end
  H.erwartet("EncodeBounty nimmt 99999", P.EncodeBounty("Grimm-Bart", "Anton Wurst", 99999, t) ~= nil)
  local base = "1\tB\tGrimm-Bart\tAnton Wurst\t%s\t" .. t
  local schlecht = { "100000", "1.5", "-3", "abc", "", "5e3", "0x10", " 5", "1234567890123" }
  for _, g in ipairs(schlecht) do
    local m, why = P.Decode(base:format(g), t, {})
    H.erwartet("Decode verwirft Betrag " .. ("%q"):format(g), m == nil, why)
  end
  local m = P.Decode(base:format("250"), t, {})
  H.erwartet("Decode nimmt 250", m and m.kind == "B" and m.g == 250 and m.by == "Anton Wurst")
  -- eine zu lange Nachricht, fremde Felder, falsche Feldzahl
  H.erwartet("8 Felder: verworfen", P.Decode(base:format("250") .. "\tabcd1234\tx", t, {}) == nil)
  H.erwartet("V mit falschem Kennzeichen: verworfen", P.Decode("1\tV\tGrimm-Bart\tAnton Wurst\t" .. t .. "\t2", t, {}) == nil)
  -- am Empfang: nichts davon landet im Buch
  for _, g in ipairs(schlecht) do H.gilde(b, base:format(g), "Anton Wurst-Forever") end
  H.erwartet("nichts angenommen", not b.ns.Guild.HasBounty("Grimm-Bart"))
end)

H.lauf("(3) Ausweis: nur das eigene, nur der passende Absender; Rueckgabe nur des eigenen", function()
  local W = H.welt()
  W.guids = true
  local b = W.client("Berta", "Senf", G, { friends = { "Fritz" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Berta Senf" }, fullSender = true })
  b.login(); f.login(); W.run(120)
  local P = b.ns.Guild.Proto
  local t = time()
  -- Gilde: Absender Carl nennt Anton als Auslober
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 100, t), "Carl Kurz-Forever")
  H.erwartet("fremder Auslober auf GUILD verworfen", not b.ns.Guild.HasBounty("Ziel-Eins"))
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 100, t), "Anton Wurst-Forever")
  H.erwartet("eigener Auslober angenommen", b.ns.Guild.HasBounty("Ziel-Eins"))
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 0, t), "Carl Kurz-Forever")
  H.erwartet("Rueckgabe durch einen anderen: bleibt", b.ns.Guild.HasBounty("Ziel-Eins"))
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 0, t - 100), "Anton Wurst-Forever")
  H.erwartet("aeltere Rueckgabe nimmt kein neueres Kopfgeld", b.ns.Guild.HasBounty("Ziel-Eins"))
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 0, t), "Anton Wurst-Forever")
  H.erwartet("eigene Rueckgabe nimmt es", not b.ns.Guild.HasBounty("Ziel-Eins"))
  -- Freund ohne Nachnamen auf der Liste, Liste nennt die GUID: ein Fremder mit gleichem Vornamen kommt nicht herein
  H.erwartet("Vorbedingung: Fritz ueber GUID gebunden", b.env.DeathNoteDB.friends.ties["Fritz"].guid ~= nil)
  H.fluestern(b, P.EncodeBounty("Ziel-Zwei", "Fritz Falsch", 300, t), "Fritz Falsch-Forever")
  H.erwartet("Fremder mit dem Vornamen des Freunds: verworfen", not b.ns.Guild.HasBounty("Ziel-Zwei"))
  f.ns.Guild.SetBounty("Ziel-Zwei", 300); W.run(10)
  H.erwartet("der echte Freund: angenommen", (zeilen(b, "Ziel-Zwei"))["Fritz Frei"] == 300)
  -- niemand reicht weiter: Berta hat Fritz' Kopfgeld, sendet aber nur eigenes
  local weiter = false
  for _, m in ipairs(W.sent) do if m.sender == b and m.text:find("Fritz Frei", 1, true) and m.text:find("^1\tB\t") then weiter = true end end
  H.erwartet("niemand reicht fremdes Kopfgeld weiter", not weiter)
end)

H.lauf("(4) Mischbetrieb: 1.1.0 und 1.2.0 verwerfen B, Y und V still und behalten ihre Daten", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Otto Neu" }, fullSender = true })
  local o = W.client("Olaf", "Alt", G, { dir = OLD, files = OLDFILES, lang = false, fullSender = true })
  local n = W.client("Otto", "Neu", G, { dir = V120, files = FILES120, friends = { "Anton Wurst" }, fullSender = true, version = "1.2.0" })
  a.login(); o.login(); n.login(); W.run(120)
  local kt = H.tod(n, "Taeter", "Lamm"); W.run(10)
  n.ns.Guild.Release("Ziel-Lamm", { to = "all", why = "Grund" }); W.run(20)
  local vo = H.tiefe_kopie(o.env.DeathNoteDB.guild.lists[G])
  local vn, vnf = H.tiefe_kopie(n.env.DeathNoteDB.guild.lists[G]), H.tiefe_kopie(n.env.DeathNoteDB.friends)
  local st = n.ns.Guild.stats.received
  -- alles Neue: Kopfgeld setzen, zuruecknehmen, Antwort mit Y, gerächt
  a.ns.Guild.SetBounty("Taeter-Lamm", 1234); W.run(10)
  a.ns.Guild.SetBounty("Ziel-Lamm", 5); W.run(10)
  a.ns.Guild.SetBounty("Ziel-Lamm", 0); W.run(10)
  local P = a.ns.Guild.Proto
  for _, txt in ipairs({ P.EncodeBountySnapshot("Anton Wurst", 1, "abcd1234"), P.EncodeAvenged(kt, "Anton Wurst", time(), true) }) do
    H.gilde(o, txt, "Anton Wurst-Forever"); H.gilde(n, txt, "Anton Wurst-Forever"); H.fluestern(n, txt, "Anton Wurst-Forever")
  end
  o.ns.Guild.SyncNow(); n.ns.Guild.SyncNow(); n.ns.Friends.SyncNow(); W.run(120)   -- Antworten mit B und Y an beide
  local t = typen(W, a)
  H.erwartet("auf der Leitung: B und Y von 1.2.1", t.B and t.Y)
  H.erwartet("keine Fehler (alle drei)", #M.errors == 0, M.errors[1])
  local d1 = gleich(vo.enemies, o.env.DeathNoteDB.guild.lists[G].enemies, "1.1.0 enemies")
  local d2 = gleich(vn.enemies, n.env.DeathNoteDB.guild.lists[G].enemies, "1.2.0 enemies")
  local d3 = gleich(vn.hunts, n.env.DeathNoteDB.guild.lists[G].hunts, "1.2.0 hunts")
  local d4 = gleich(vnf.enemies, n.env.DeathNoteDB.friends.enemies, "1.2.0 friends")
  local alle = {}
  for _, d in ipairs({ d1, d2, d3, d4 }) do for _, x in ipairs(d) do alle[#alle + 1] = x end end
  H.erwartet("Daten von 1.1.0 und 1.2.0 unveraendert", #alle == 0, table.concat(alle, ", "))
  H.erwartet("1.2.0 hoert weiter zu (Antworten kamen an)", n.ns.Guild.stats.received > st)
  H.erwartet("1.2.0 kennt kein Kopfgeld-Feld", n.env.DeathNoteDB.guild.lists[G].bounty == nil and n.env.DeathNoteDB.bounty == nil)
  H.erwartet("1.2.0 zaehlt B als unbekannte Art (still verworfen)", n.ns.Guild.stats.dropped > 0)
end)

H.lauf("(5) Nachreichen und Ruecknahme ueber die Momentaufnahme (Y mit Buchkennung)", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); W.run(60)
  a.ns.Guild.SetBounty("Eins-Ziel", 100); a.ns.Guild.SetBounty("Zwei-Ziel", 200); W.run(10)
  b.login(); W.run(120)   -- Berta war nicht da: ihr Hallo, Antons Antwort bringt beide
  local bb = zeilen(b, "Eins-Ziel")
  local bz = zeilen(b, "Zwei-Ziel")
  H.erwartet("nachgereicht: beide Kopfgelder", bb["Anton Wurst"] == 100 and bz["Anton Wurst"] == 200)
  local bdb = H.raus(W, b); W.run(10)
  a.ns.Guild.SetBounty("Zwei-Ziel", 0); W.run(10)       -- Berta verpasst die Ruecknahme
  W.run(300)                                              -- (ein Hallo desselben Mitglieds wird hoechstens alle 5 Minuten beantwortet)
  H.tage(1)
  local b2 = W.client("Berta", "Senf", G, { db = bdb, fullSender = true })
  b2.login(); W.run(120)
  H.erwartet("verpasste Ruecknahme kommt mit der Momentaufnahme", b2.ns.Guild.HasBounty("Eins-Ziel") and not b2.ns.Guild.HasBounty("Zwei-Ziel"))
  -- ein anderes Geraet (andere Buchkennung) desselben Chars: dessen Kopfgeld nimmt Y nicht zurueck
  local P = b2.ns.Guild.Proto
  H.gilde(b2, P.EncodeBounty("Drei-Ziel", "Anton Wurst", 300, time(), "zzzz9999"), "Anton Wurst-Forever")
  b2.ns.Guild.SyncNow(); W.run(120)
  H.erwartet("Kopfgeld aus einem anderen Buch bleibt", b2.ns.Guild.HasBounty("Drei-Ziel"))
  H.erwartet("Y ging hinaus", typen(W, a).Y == true)
end)

H.lauf("(6) Deckel: je Absender 20, Tempo live 5 in 10 Minuten, je Buch 200 Ziele, Flut", function()
  local W = H.welt()
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  b.login(); W.run(90)                                    -- das Antwortfenster nach dem eigenen Hallo ist zu
  local P, C = b.ns.Guild.Proto, b.ns.Guild.C
  local function zahl()
    local n = 0
    for _, x in pairs(b.env.DeathNoteDB.guild.lists[G].bounty) do for _ in pairs(x) do n = n + 1 end end
    return n
  end
  for i = 1, 8 do H.gilde(b, P.EncodeBounty("Ziel-N" .. string.char(96 + i), "Anton Wurst", 10 * i, time()), "Anton Wurst-Forever") end
  H.erwartet("live: hoechstens 5 neue in 10 Minuten", zahl() == C.HUNT_LIVE_MAX, zahl())
  for runde = 1, 6 do
    W.run(C.HUNT_LIVE_WINDOW + 1)
    for i = 1, 5 do H.gilde(b, P.EncodeBounty("Ziel-R" .. runde .. string.char(96 + i), "Anton Wurst", 10, time()), "Anton Wurst-Forever") end
  end
  H.erwartet("je Absender hoechstens 20", zahl() == C.BOUNTY_PER_SENDER, zahl())
  -- viele Absender: hoechstens 200 Ziele je Buch
  for s = 1, 60 do
    for i = 1, 5 do
      H.gilde(b, P.EncodeBounty("Ziel-S" .. s .. "x" .. i, "Kerl" .. s .. " Wurst", 1, time()), "Kerl" .. s .. " Wurst-Forever")
    end
  end
  local keys = 0
  for _ in pairs(b.env.DeathNoteDB.guild.lists[G].bounty) do keys = keys + 1 end
  H.erwartet("hoechstens 200 Ziele", keys <= C.BOUNTY_MAX, keys)
  -- Flut: 400 Nachrichten in einer Minute von einem Absender
  local before = b.ns.Guild.stats.dropped
  for i = 1, 400 do H.gilde(b, P.EncodeBounty("Flut-Ziel", "Flut Kerl", i % 99 + 1, time()), "Flut Kerl-Forever") end
  H.erwartet("Flut gebremst (Flutwaechter und Deckel)", b.ns.Guild.stats.dropped - before >= 250, b.ns.Guild.stats.dropped - before)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(7) eigene Grenzen: 20 eigene, nicht auf eigene Leute, Verfall wie Freigaben", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  local C = a.ns.Guild.C
  for i = 1, C.BOUNTY_PER_SENDER do a.ns.Guild.SetBounty("Ziel-E" .. i, i) end
  local ok, why = a.ns.Guild.SetBounty("Ziel-Zuviel", 5)
  H.erwartet("21. eigenes: cap", ok == nil and why == "cap", why)
  ok, why = a.ns.Guild.SetBounty("Ziel-E1", 77)
  H.erwartet("vorhandenes aendern geht am Deckel", ok == true, why)
  ok, why = a.ns.Guild.SetBounty("Berta-Senf", 5)
  H.erwartet("Kollegin mit DeathNote: ours", ok == nil and why == "ours", why)
  ok, why = a.ns.Guild.SetBounty("Anton-Wurst", 5)
  H.erwartet("eigener Char: ours", ok == nil and why == "ours", why)
  ok, why = a.ns.Guild.SetBounty("kaputt", 5)
  H.erwartet("ungueltiger Schluessel: key", ok == nil and why == "key", why)
  for _, g in ipairs({ 0.5, 100000, -2 }) do
    ok, why = a.ns.Guild.SetBounty("Ziel-E2", g)
    H.erwartet("Betrag " .. g .. ": gold", ok == nil and why == "gold", why)
  end
  W.run(30)
  -- Verfall: "Freigaben gelten 30 Tage"
  a.ns.Store.Setting("guild.huntExpire", 30); b.ns.Store.Setting("guild.huntExpire", 30)
  local P = b.ns.Guild.Proto
  W.run(b.ns.Guild.C.HUNT_LIVE_WINDOW + 1)              -- der Tempo-Deckel fuer Anton ist wieder frei
  H.gilde(b, P.EncodeBounty("Alt-Ziel", "Anton Wurst", 9, time() - 31 * 86400), "Anton Wurst-Forever")
  H.gilde(b, P.EncodeBounty("Neu-Ziel", "Anton Wurst", 9, time() - 29 * 86400), "Anton Wurst-Forever")
  H.erwartet("Gegenprobe: juenger als die Frist: angenommen", b.ns.Guild.HasBounty("Neu-Ziel"))
  H.erwartet("aelter als die Frist: nicht angenommen", not b.ns.Guild.HasBounty("Alt-Ziel"))
  H.tage(31)
  local a2 = H.relog(W, a); a2.login(); W.run(30)
  H.erwartet("eigene nach der Frist zurueckgenommen", a2.ns.Guild.OwnBounty("Ziel-E3") == nil)
  H.erwartet("... und bei der Kollegin weg", not b.ns.Guild.HasBounty("Ziel-E3"))
end)

H.lauf("(8) Freunde: Bindung loesen und Aufraeumen nehmen sein Kopfgeld mit; Freundesbuch leeren", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty("Ziel-Eins", 40); W.run(10)
  H.erwartet("Vorbedingung: Kopfgeld der Freundin da", a.ns.Guild.HasBounty("Ziel-Eins"))
  a.ns.Friends.Unbind("Berta")
  H.erwartet("Bindung loesen nimmt es mit", not a.ns.Guild.HasBounty("Ziel-Eins"))
  b.ns.Guild.SetBounty("Ziel-Eins", 41); W.run(10)
  b.ns.Friends.SyncNow(); a.ns.Friends.SyncNow(); W.run(120)
  H.erwartet("naechster Kontakt bringt es wieder", a.ns.Guild.HasBounty("Ziel-Eins"))
  a.ns.Friends.Clear()
  H.erwartet("Freundesbuch leeren nimmt fremdes Kopfgeld", not a.ns.Guild.HasBounty("Ziel-Eins"))
end)

H.lauf("(9) Befehl /dn kopfgeld und /dn bounty", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  a.login(); W.run(60)
  a.ns.Store.AddManual("Grimm", "Bart")
  local chat = {}
  a.env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, s) chat[#chat + 1] = s end }
  a.ns.HandleSlash("kopfgeld Grimm Bart 500")
  H.erwartet("Name mit Nachname und Betrag", a.ns.Guild.OwnBounty("Grimm-Bart") == 500)
  a.ns.HandleSlash("bounty Grimm 750")
  H.erwartet("englisch, Vorname reicht wenn eindeutig", a.ns.Guild.OwnBounty("Grimm-Bart") == 750)
  a.ns.HandleSlash("kopfgeld Grimm Bart 1.5")
  H.erwartet("1.5: verworfen, Betrag bleibt", a.ns.Guild.OwnBounty("Grimm-Bart") == 750)
  a.ns.HandleSlash("kopfgeld Grimm Bart 100000")
  H.erwartet("100000: verworfen", a.ns.Guild.OwnBounty("Grimm-Bart") == 750)
  a.ns.HandleSlash("kopfgeld Grimm Bart")
  H.erwartet("ohne Betrag: zurueckgenommen", a.ns.Guild.OwnBounty("Grimm-Bart") == nil)
  a.ns.HandleSlash("kopfgeld Grimm Bart 0")
  a.ns.HandleSlash("kopfgeld")
  a.ns.HandleSlash("kopfgeld Niemand Da 5")
  H.erwartet("Chatzeilen kamen, keine Fehler", #chat >= 6 and #M.errors == 0, #chat)
end)

H.lauf("(10) Secrets: keine Fehler, nie ein Wert", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  a.login(); W.run(60)
  local S = M.Secret("x", "string")
  local Sn = M.Secret("n", "number")
  local G2 = a.ns.Guild
  local ok1, r1 = pcall(G2.SetBounty, S, 5)
  local ok2, r2 = pcall(G2.SetBounty, "Grimm-Bart", Sn)
  local ok3, r3 = pcall(G2.Bounties, S)
  local ok4, r4 = pcall(G2.HasBounty, S)
  local ok5, r5 = pcall(G2.Avenged, S)
  local ok6 = pcall(G2.OnPartyKill, S, S)
  local ok7 = pcall(G2.Proto.EncodeBounty, S, "A B", 1, time())
  local ok8 = pcall(G2.Proto.EncodeAvenged, "Grimm-Bart", S, time())
  H.erwartet("keine Fehler", ok1 and ok2 and ok3 and ok4 and ok5 and ok6 and ok7 and ok8 and #M.errors == 0, M.errors[1])
  H.erwartet("kein Wert", r1 == nil and r2 == nil and type(r3) == "table" and #r3 == 0 and r4 == false and #r5 == 0)
  a.fire("CHAT_MSG_ADDON", "DeathNote", S, "GUILD", "Berta Senf-Forever")
  a.fire("CHAT_MSG_ADDON", "DeathNote", "1\tB\tGrimm-Bart\tBerta Senf\t5\t" .. time(), "GUILD", S)
  H.erwartet("Secret-Text oder -Absender: verworfen", not G2.HasBounty("Grimm-Bart") and #M.errors == 0, M.errors[1])
  H.erwartet("kein Secret in der Datei", not M.ContainsSecret(a.env.DeathNoteDB))
end)

H.fertig()
