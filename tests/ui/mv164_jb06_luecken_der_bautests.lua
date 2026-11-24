-- jb06 (Testluecken, Fund Nr. 6): Dieser Test ist auf 4f30098 GRUEN. Er prueft, was die Tests des Bauers behaupten,
-- aber nicht pruefen: jede der unten genannten Zeilen kann man aus dem Code nehmen, und tests/ui/mv164_*.lua sowie
-- tests/test_mv164_sonde.lua bleiben gruen (Mutationsprobe des Jaegers, Liste im Bericht). Mit diesem Test wird jede
-- dieser Mutationen rot. Vorschlag: als tests/ui/mv164_luecken.lua uebernehmen.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local check = J.check
local CALL = { by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 }

-- (a) Alert.ShowSample bricht den Zeitgeber des echten Alarms ab: sonst geht das Muster nach 12 s von selbst
do
  local W = J.world("deDE", { db = J.db() })
  W.ns.Store.AddManual("Velka Thornheart")
  W.ns:Fire("TEST_ALERT"); W.tick(0.5)
  W.slash("move")
  W.tick(13); W.BM.FinishAnims(); W.tick(1)
  check("a: Alarm-Muster steht nach 14 s noch (Zeitgeber des echten Alarms)", W.ns.Place.Active() and W.frame("DeathNoteAlert"):IsShown()
    and W.frame("DeathNoteAlert").sample == true)
  W.slash("move")
end
-- (b) Card.Tick ruehrt das Muster nicht an: sonst versteckt der erste Takt die Rachsucht-Meldung (keine Episode)
do
  local W = J.world("deDE", { db = J.db() })
  W.slash("move")
  local c = W.frame("DeathNoteGrudge")
  for _ = 1, 5 do c._scripts.OnUpdate(c, 1) end
  check("b: Rachsucht-Muster steht nach fuenf Takten", c:IsShown() and c.sample == true)
  W.slash("move")
end
-- (c) CU.ShowSample loest den Zeitgeber des echten Zettels: sonst geht das Muster nach dessen Restzeit
do
  local W = J.world("deDE", { db = J.db() })
  W.ns.CallUI.Show(CALL); W.tick(0.1)
  W.slash("move")
  W.tick(25)
  check("c: Zettel-Muster steht nach 25 s noch (Zeitgeber des echten Zettels)", W.frame("DeathNoteCall"):IsShown() and W.frame("DeathNoteCall").sample == true)
  W.slash("move")
end
-- (d) Extras.EndSample nimmt der Meldung die Maus wieder, auch wenn sie versteckt ist (clean() in mv164_modus prueft
--     die Maus nur an einer SICHTBAREN Meldung und ist nach dem Modus immer wahr)
do
  local W = J.world("deDE", { db = J.db() })
  W.slash("move"); W.slash("move")
  check("d: Meldung nach dem Modus ohne Maus", W.frame("DeathNoteBanner")._mouse ~= true, tostring(W.frame("DeathNoteBanner")._mouse))
end
-- (e) Alert.ResetPosition legt den Zielknopf neu: sonst bleibt er an der alten Stelle, der Alarm springt zurueck
do
  local W = J.world("deDE", { db = J.db({ alert = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 300, 400, 1 } } }) })
  W.ns.Store.AddManual("Velka Thornheart")
  W.ns:Fire("TEST_ALERT"); W.tick(0.5)
  local l0 = W.rect(W.frame("DeathNoteAlert"))
  W.slash("move reset")
  local l1 = W.rect(W.frame("DeathNoteAlert"))
  local ok, why = W.buttonOk()
  check("e: Zuruecksetzen bei stehendem Alarm: Alarm springt, Knopf deckungsgleich", math.abs(l0 - 300) < 1 and math.abs(l1 - 300) > 100
    and W.shown("DeathNoteAlertButton") and ok, why)
end
-- (E) Extras.ShowSample haelt die Animation der echten Meldung an: sonst versteckt deren Ende das Muster
do
  local W = J.world("deDE", { db = J.db() })
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  W.slash("move")
  W.BM.FinishAnims(); W.tick(13); W.BM.FinishAnims(); W.tick(1)
  local b = W.frame("DeathNoteBanner")
  check("E: Meldungs-Muster steht, wenn die Animation der echten Meldung endet", b:IsShown() and b.sample == true and b._mouse == true)
  W.slash("move")
end
-- (l) wartende Meldungen kommen nach dem Modus (Extras.EndSample stellt NextGuild)
do
  local W = J.world("deDE", { db = J.db() })
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  W.ns.Extras.Notice("RANG", "Borin", "Zeile zwei"); W.tick(0.1)        -- wartet hinter der ersten
  W.slash("move"); W.tick(1); W.slash("move")
  W.tick(1)
  local b = W.frame("DeathNoteBanner")
  check("l: die wartende Meldung kommt nach dem Modus", b:IsShown() and not b.sample and b.name._text == "Borin", tostring(b.name._text))
end
-- (p) /dn move bei offenem Buch schliesst das Buch (der Knopf im Buch tut es selbst, der Befehl nur ueber Place.Start)
do
  local W = J.world("deDE", { db = J.db() })
  W.ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
  check("p: Vorbedingung Buch offen", W.shown("DeathNoteFrame"))
  W.slash("move")
  check("p: /dn move schliesst das Buch, Modus an", not W.shown("DeathNoteFrame") and W.ns.Place.Active())
  W.slash("move")
end
-- (q, C) Sonde gedeckelt: nur bekannte Zaehler, hoechstens 1e9
do
  local W = J.world("deDE", { db = J.db() })
  W.slash("move"); W.slash("move")
  local c = W.ns.Store.DB().probe.move.counts
  c.start = 1e9
  W.ns.Place.Count("start"); W.ns.Place.Count("frei erfunden"); W.ns.Place.Stop("auch erfunden")
  W.slash("move"); W.ns.Place.Stop("erfunden")
  check("q: Zaehler bleibt bei 1e9", c.start == 1e9, tostring(c.start))
  local n = 0
  for k in pairs(c) do n = n + 1 end
  check("C: kein unbekannter Zaehler", c["frei erfunden"] == nil and c["stop_erfunden"] == nil and n <= #W.ns.Place.COUNTS, n)
end
-- (r, s, z) Look.Point: NaN, riesige Zahl, unbrauchbare Skala im fuenften Feld
do
  local W = J.world("deDE", { db = J.db() })
  local P = W.ns.Look.Point
  local nan = 0 / 0
  check("r: NaN als Versatz -> keine Lage", P({ "TOP", "TOP", nan, 0 }) == nil and P({ "TOP", "TOP", 0, nan }) == nil)
  check("s: riesiger Versatz -> keine Lage", P({ "TOP", "TOP", 1e7, 0 }) == nil and P({ "TOP", "TOP", 0, -1e7 }) == nil and P({ "TOP", "TOP", math.huge, 0 }) == nil)
  for _, bad in ipairs({ 0, -3, nan, 1e-3, 500 }) do
    local p, _, x, _, s = P({ "TOP", "TOP", 10, -100, bad })
    check("z: Skala " .. tostring(bad) .. " im fuenften Feld zaehlt nicht", p == "TOP" and x == 10 and s == nil, tostring(s))
  end
  -- und am Alarm selbst: der Versatz wird nicht mit der kaputten Skala verrechnet
  local W2 = J.world("deDE", { db = J.db({ alert = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 300, 400, -3 } } }) })
  W2.ns.Store.AddManual("Velka Thornheart"); W2.ns:Fire("TEST_ALERT"); W2.tick(0.5)
  local l, b = W2.rect(W2.frame("DeathNoteAlert"))
  check("z: Alarm mit Skala -3 im fuenften Feld steht bei 300/400", math.abs(l - 300) < 1 and math.abs(b - 400) < 1, ("%.0f/%.0f"):format(l, b))
end
J.done("jb06")
