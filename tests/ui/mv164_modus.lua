-- 1.6.4 move: the placing mode on and off by every way (command and its words, right click on each sample and on the
-- bar, Esc, Done, the button on the House Rules), what a real alarm, a real notice, a help call, a grudge notice, a
-- death, combat and the book do to it, the mode started in combat. After every way: no sample left, the bar gone, the
-- notice click-through again, the secure button hidden or exactly over the alarm, no error, no protected action.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local PIECES = { "DeathNoteAlert", "DeathNoteBanner", "DeathNoteCall", "DeathNoteGrudge" }

local function clean(W, label)
  check(label .. ": kein Muster mehr", #W.samples() == 0, table.concat(W.samples(), ","))
  check(label .. ": Leiste weg", not W.shown("DeathNoteMove"))
  local bn = W.frame("DeathNoteBanner")
  check(label .. ": Muster-Stempel weg", not (bn and not bn:IsShown() and bn.stamp:IsShown() and bn.stamp:GetAlpha() < 0.5))
  check(label .. ": Modus aus", not W.ns.Place.Active())
  -- also while hidden (hunt B1: checked only on a shown notice, the check was always true after the mode)
  local b = W.frame("DeathNoteBanner")
  check(label .. ": Meldung klickdurchlaessig", not (b and b._mouse and not b.open), b and tostring(b._mouse))
  local ok, why = W.buttonOk()
  check(label .. ": Zielknopf weg oder deckungsgleich", ok, why)
  local n, first = W.errors()
  check(label .. ": keine Fehler", n == 0, first)
end

local function on(W, label)
  W.slash("move")
  check(label .. ": vier Muster", #W.samples() == 4, table.concat(W.samples(), ","))
  check(label .. ": Leiste da", W.shown("DeathNoteMove"))
  local ok, why = W.buttonOk()
  check(label .. ": Zielknopf weg", ok and not W.shown("DeathNoteAlertButton"), why)
end

for _, code in ipairs({ "deDE", "enUS" }) do
  -- (1) the command and its words; the command again ends it
  for _, word in ipairs({ "move", "unlock", "verschieben", "anchors", "anchor", "anker" }) do
    local W = J.world(code)
    W.ns.HandleSlash(word); W.tick(0.1)
    check(code .. " /dn " .. word .. ": Modus an", W.ns.Place.Active() and #W.samples() == 4)
    -- every sample says what to do with it
    local hint = W.ns.L.MOVE_DRAG
    check(code .. " /dn " .. word .. ": Alarm sagt es", W.frame("DeathNoteAlert").hint:GetText() == hint)
    check(code .. " /dn " .. word .. ": Meldung sagt es", W.frame("DeathNoteBanner").line:GetText() == hint)
    check(code .. " /dn " .. word .. ": Meldung zeigt den Platz des Stempels", W.frame("DeathNoteBanner").stamp:IsShown())
    -- the name on every anchor (wish of the owner, 24.11.2026: as in ElvUI), each one different
    local Sp = W.ns.Extras.Spaced
    check(code .. " /dn " .. word .. ": Name am Alarm", W.frame("DeathNoteAlert").title:GetText() == W.ns.L.SHEET_ALERT)
    check(code .. " /dn " .. word .. ": Name an der Meldung", W.frame("DeathNoteBanner").kicker:GetText() == Sp(W.ns.L.MOVE_NAME_NOTICE))
    check(code .. " /dn " .. word .. ": Name am Zettel", W.frame("DeathNoteCall").kicker:GetText() == Sp(W.ns.L.CALL_SLIP_HEAD))
    check(code .. " /dn " .. word .. ": Name an der Rachsucht", W.frame("DeathNoteGrudge").head:GetText() == Sp(W.ns.L.MOVE_NAME_GRUDGE))
    check(code .. " /dn " .. word .. ": Zettel sagt es", W.frame("DeathNoteCall").hint:GetText() == hint)
    check(code .. " /dn " .. word .. ": Rachsucht sagt es", W.frame("DeathNoteGrudge").more:GetText() == hint)
    W.ns.HandleSlash(word); W.tick(0.1)
    clean(W, code .. " /dn " .. word .. " zweimal")
  end

  -- (1b) the words after the command: on/an start, off/aus/done/fertig end, an unknown word changes nothing
  do
    local W = J.world(code)
    W.slash("move off"); check(code .. " move off bei aus: bleibt aus", not W.ns.Place.Active())
    W.slash("move on"); check(code .. " move on: an", W.ns.Place.Active())
    W.slash("move an"); check(code .. " move an bei an: bleibt an", W.ns.Place.Active())
    W.slash("move blah"); check(code .. " unbekanntes Wort: bleibt an, Hilfezeile", W.ns.Place.Active() and W.said(W.ns.L.HELP_MOVE) == 1)
    W.slash("move fertig"); check(code .. " move fertig: aus", not W.ns.Place.Active())
    W.slash("move on"); W.slash("move aus"); check(code .. " move aus: aus", not W.ns.Place.Active())
    W.slash("move on"); W.slash("move done"); check(code .. " move done: aus", not W.ns.Place.Active())
    W.slash("move blah"); check(code .. " unbekanntes Wort bei aus: bleibt aus", not W.ns.Place.Active())
    clean(W, code .. " Woerter")
  end

  -- (2) right click on each sample and on the bar
  for _, name in ipairs({ "DeathNoteAlert", "DeathNoteBanner", "DeathNoteCall", "DeathNoteGrudge", "DeathNoteMove" }) do
    local W = J.world(code)
    on(W, code .. " " .. name)
    W.rclick(W.frame(name))
    clean(W, code .. " Rechtsklick " .. name)
  end
  -- a left click on a sample does nothing (no targeting, no map, no book)
  do
    local W = J.world(code)
    on(W, code .. " Linksklick")
    for _, name in ipairs(PIECES) do
      local f = W.frame(name)
      f._scripts.OnMouseUp(f, "LeftButton"); W.tick(0.1)
    end
    check(code .. " Linksklick: Modus bleibt, vier Muster", W.ns.Place.Active() and #W.samples() == 4)
    check(code .. " Linksklick: Buch zu", not W.shown("DeathNoteFrame"))
  end

  -- (3) Esc and Done
  do
    local W = J.world(code)
    on(W, code .. " Esc")
    W.esc()
    clean(W, code .. " Esc")
    on(W, code .. " Fertig")
    W.click(W.ns.Place.Bar().done)
    clean(W, code .. " Fertig")
    on(W, code .. " noch einmal")
    W.slash("move")
    clean(W, code .. " noch einmal")
  end

  -- (4) the button on the House Rules, sheet Alert: the book closes, the mode runs; opening the book ends it
  do
    local W = J.world(code)
    W.ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
    W.ns.UI.OpenPanel("settings"); W.tick(1)
    local S = W.find and nil
    local btn
    for _, f in ipairs(W.BM.frames) do
      if f.text and f.text._text == W.ns.L.SET_MOVE and f._scripts and f._scripts.OnClick then btn = f end
    end
    check(code .. " Knopf auf dem Blatt Alarm da", btn ~= nil)
    if btn then
      W.click(btn)
      check(code .. " Knopf: Buch zu", not W.shown("DeathNoteFrame"))
      check(code .. " Knopf: Modus an", W.ns.Place.Active() and #W.samples() == 4)
      W.ns:Fire("TOGGLE_UI"); W.tick(1)
      check(code .. " Buch auf: Buch da", W.shown("DeathNoteFrame"))
      clean(W, code .. " Buch auf")
    end
  end

  -- (5) real events during the mode: the mode ends first, the event runs as always
  do
    -- a real alarm (the test alarm of an entry in the book: the button is armed over it)
    local W = J.world(code)
    local key = W.ns.Store.AddManual("Velka Thornheart")
    on(W, code .. " echter Alarm")
    W.ns:Fire("TEST_ALERT"); W.tick(0.5)
    check(code .. " echter Alarm: Modus aus", not W.ns.Place.Active() and #W.samples() == 0)
    check(code .. " echter Alarm: Alarm steht", W.shown("DeathNoteAlert") and not W.frame("DeathNoteAlert").sample)
    check(code .. " echter Alarm: Zielknopf da und deckungsgleich", W.shown("DeathNoteAlertButton") and W.buttonOk())
    check(code .. " echter Alarm: Hinweis des Alarms", W.frame("DeathNoteAlert").hint:GetText() ~= W.ns.L.MOVE_DRAG)
    check(code .. " echter Alarm: Leiste weg", not W.shown("DeathNoteMove"))
    W.settle()
    check(code .. " echter Alarm: geht nach der Zeit", not W.shown("DeathNoteAlert"))
    clean(W, code .. " echter Alarm danach")
    assert(key)
  end
  do
    -- a real notice (a rank notice of the rap sheet)
    local W = J.world(code)
    on(W, code .. " echte Meldung")
    W.ns.Extras.Notice("RANG", "Grimwald", "Zeile")
    W.tick(0.1)
    local b = W.frame("DeathNoteBanner")
    check(code .. " echte Meldung: Modus aus", not W.ns.Place.Active() and #W.samples() == 0)
    check(code .. " echte Meldung: steht", b:IsShown() and not b.sample and b.name._text == "Grimwald")
    check(code .. " echte Meldung: Maus aus", not b._mouse)
    W.settle()
    clean(W, code .. " echte Meldung danach")
  end
  do
    -- a real help call
    local W = J.world(code)
    on(W, code .. " Hilferuf")
    W.ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 })
    W.tick(0.1)
    local s = W.frame("DeathNoteCall")
    check(code .. " Hilferuf: Modus aus", not W.ns.Place.Active() and #W.samples() == 0)
    check(code .. " Hilferuf: Zettel steht mit dem Ruf", s:IsShown() and not s.sample and s.rec ~= nil)
    W.tick(21)
    check(code .. " Hilferuf: geht nach seiner Zeit", not s:IsShown())
    clean(W, code .. " Hilferuf danach")
  end
  do
    -- a real grudge notice (the test notice of /dn grudge test)
    local W = J.world(code)
    on(W, code .. " Rachsucht")
    W.ns.Grudge.Test(); W.tick(0.6)
    local c = W.frame("DeathNoteGrudge")
    check(code .. " Rachsucht: Modus aus", not W.ns.Place.Active() and #W.samples() == 0)
    check(code .. " Rachsucht: echte Meldung steht", c:IsShown() and not c.sample)
    clean(W, code .. " Rachsucht")
  end
  do
    -- the player dies
    local W = J.world(code)
    on(W, code .. " Tod")
    W.AM.FireEvent("PLAYER_DEAD"); W.tick(0.1)
    clean(W, code .. " Tod")
  end
  do
    -- combat starts (also in the middle of a drag: the place is kept where the drag ended)
    local W = J.world(code)
    on(W, code .. " Kampf")
    local a = W.frame("DeathNoteAlert")
    a._scripts.OnDragStart(a, "LeftButton")
    check(code .. " Kampf: Ziehen begonnen", a._moving == true)
    W.combat(true)
    check(code .. " Kampf: Ziehen beendet", not a._moving and not a.moving)
    check(code .. " Kampf: Lage gehalten", type(W.ns.Store.Setting("alert.point")) == "table")
    clean(W, code .. " Kampf")
    -- in combat: the command says why and does nothing else
    local before = #W.chat()
    W.slash("move")
    check(code .. " im Kampf: eine Zeile", #W.chat() == before + 1 and W.said(W.ns.L.MOVE_COMBAT) == 1)
    clean(W, code .. " im Kampf gestartet")
    -- a real alarm in combat after the mode: no button (as in 1.6.3), no violation
    W.ns:Fire("TEST_ALERT"); W.tick(0.5)
    clean(W, code .. " Alarm im Kampf")
    W.combat(false)
    local ok, why = W.buttonOk()
    check(code .. " nach dem Kampf: Knopf deckungsgleich", ok, why)
  end
  do
    -- the button on the House Rules in combat (the real button): the chat line, the book stays open
    local W = J.world(code)
    W.ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
    W.ns.UI.OpenPanel("settings"); W.tick(1)
    local btn
    for _, f in ipairs(W.BM.frames) do
      if f.text and f.text._text == W.ns.L.SET_MOVE and f._scripts and f._scripts.OnClick then btn = f end
    end
    W.combat(true)
    local before = #W.chat()
    W.click(btn)
    check(code .. " Knopf im Kampf: nichts", not W.ns.Place.Active() and #W.samples() == 0 and not W.shown("DeathNoteMove"))
    check(code .. " Knopf im Kampf: Buch bleibt offen", W.shown("DeathNoteFrame"))
    check(code .. " Knopf im Kampf: eine Zeile", #W.chat() == before + 1 and W.said(W.ns.L.MOVE_COMBAT) == 1)
    W.combat(false)
  end
  do
    -- a real alarm on the screen when the mode starts gives way; the mode then runs with its sample
    local W = J.world(code)
    W.ns.Store.AddManual("Velka Thornheart")
    W.ns:Fire("TEST_ALERT"); W.tick(0.5)
    check(code .. " Alarm vorher: Knopf da", W.shown("DeathNoteAlertButton"))
    on(W, code .. " Alarm vorher")
    check(code .. " Alarm vorher: Muster statt Alarm", W.frame("DeathNoteAlert").sample == true)
    W.slash("move")
    clean(W, code .. " Alarm vorher")
  end
end

-- (6) dragging every sample keeps its place; dragging the alarm makes the slip and the notice make room
do
  local W = J.world("deDE")
  on(W, "Ziehen")
  for _, name in ipairs(PIECES) do
    check("Ziehen: " .. name .. " bewegt sich", W.drag(W.frame(name), -200, -150))
  end
  local st = W.ns.Store
  check("Ziehen: vier Lagen gehalten", type(st.Setting("alert.point")) == "table" and type(st.Setting("notice.point")) == "table"
    and type(st.Setting("call.point")) == "table" and type(st.Setting("grudge.point")) == "table")
  local ok, why = W.buttonOk()
  check("Ziehen: Zielknopf weg", ok and not W.shown("DeathNoteAlertButton"), why)
  check("Ziehen: nichts in layout-local.txt", not W.frame("DeathNoteAlert")._userPlaced and not W.frame("DeathNoteBanner")._userPlaced
    and not W.frame("DeathNoteCall")._userPlaced and not W.frame("DeathNoteGrudge")._userPlaced)
  -- the notice and the alarm never cover each other: the alarm dropped on the notice, the notice moves
  local b = W.frame("DeathNoteBanner")
  local bl, bb, br, bt = W.rect(b)
  local a = W.frame("DeathNoteAlert")
  local al, ab = W.rect(a)
  W.drag(a, bl - al, bb - ab)
  local l1, b1, r1, t1 = W.rect(a)
  local l2, b2, r2, t2 = W.rect(b)
  check("Ziehen: Meldung weicht dem Alarm", not (l1 < r2 and r1 > l2 and b1 < t2 + 14 and t1 > b2), ("%d %d %d %d / %d %d %d %d"):format(l1, b1, r1, t1, l2, b2, r2, t2))
  W.slash("move")
  clean(W, "Ziehen")
  check("Ziehen: Sonde zaehlt", type(W.ns.Store.DB().probe.move) == "table" and W.ns.Store.DB().probe.move.counts.drag_alert == 2)
  -- the notice outside the mode cannot be dragged (click-through, no drag)
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  check("Ziehen: echte Meldung nicht ziehbar", not W.drag(b, 50, 50))
end

-- (7) the bar never covers a sample: default places on a large and a small screen (1366x768 UI units), the alarm
-- dragged down onto the bar, the alarm at 150 %
local function overlaps(W)
  local bl, bb, br, bt = W.rect(W.frame("DeathNoteMove"))
  for _, name in ipairs(PIECES) do
    local f = W.frame(name)
    if f and f:IsShown() then
      local l, b, r, t = W.rect(f)
      if l < br and r > bl and b < bt and t > bb then return name end
    end
  end
  return nil
end
for _, ui in ipairs({ 1, 2560 / 1366 }) do
  for _, scale in ipairs({ 1, 1.5 }) do
    local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
      news140 = true, lang = "deDE", alert = { scale = scale } }, enemies = {}, deaths = {} }
    local W = J.world("deDE", { ui = ui, db = db })
    local tag = ("Leiste UI %.2f Alarm %d %%"):format(ui, scale * 100)
    W.slash("move")
    check(tag .. ": deckt kein Muster", overlaps(W) == nil, overlaps(W))
    local bar = W.frame("DeathNoteMove")
    local _, _, _, bt = W.rect(bar)
    local a = W.frame("DeathNoteAlert")
    local _, ab = W.rect(a)
    W.drag(a, 0, bt - 20 - ab - 108 * scale)
    check(tag .. ": Alarm auf die Leiste gezogen, Leiste weicht", overlaps(W) == nil, overlaps(W))
    local sw = W.G.UIParent:GetHeight()
    local _, b2, _, t2 = W.rect(bar)
    check(tag .. ": Leiste auf dem Schirm", b2 >= 0 and t2 <= sw, ("%.0f %.0f"):format(b2, t2))
    W.slash("move")
  end
end

-- (8) alarms on the screen and waiting when the mode starts: the mode stays; their cooldowns are given back at the end,
-- so the next sighting of the same player rings again; a new alarm in the mode ends it with one chat line
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code)
  local k1 = W.ns.Store.AddManual("Velka Thornheart")
  local k2 = W.ns.Store.AddManual("Borin Ashfall")
  local k3 = W.ns.Store.AddManual("Torvik Greyhammer")
  W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
  W.ns.Alert.Spotted(k2, nil, "x"); W.tick(0.2)
  check(code .. " Abklingzeit: einer steht, einer wartet", W.ns.Alert.Shows(k1) and W.ns.Alert.Shows(k2))
  W.slash("move"); W.tick(1)
  check(code .. " Abklingzeit: Modus bleibt", W.ns.Place.Active() and #W.samples() == 4)
  check(code .. " Abklingzeit: Schlange leer", not W.ns.Alert.Shows(k2))
  -- the same players again during the mode: their cooldown still runs, the mode stays
  W.ns.Alert.Spotted(k1, nil, "x"); W.ns.Alert.Spotted(k2, nil, "x"); W.tick(0.2)
  check(code .. " Abklingzeit: dieselben im Modus beenden ihn nicht", W.ns.Place.Active())
  W.slash("move")
  check(code .. " vom Spieler beendet: keine Zeile MOVE_ENDED", W.said(W.ns.L.MOVE_ENDED) == 0)
  W.ns.Alert.Spotted(k2, nil, "x"); W.tick(0.2)
  check(code .. " Abklingzeit zurueckgegeben: naechste Sichtung klingelt", W.shown("DeathNoteAlert") and W.ns.Alert.Shows(k2))
  W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
  check(code .. " Abklingzeit zurueckgegeben: auch der zweite", W.ns.Alert.Shows(k1))
  W.settle(); W.settle(); W.settle()
  -- a new alarm in the mode: ends it, one line says why
  W.slash("move")
  W.ns.Alert.Spotted(k3, nil, "x"); W.tick(0.2)
  check(code .. " neuer Alarm: Modus aus, Alarm steht", not W.ns.Place.Active() and W.ns.Alert.Shows(k3))
  check(code .. " neuer Alarm: eine Zeile MOVE_ENDED", W.said(W.ns.L.MOVE_ENDED) == 1)
  W.settle()
  W.slash("move"); W.combat(true)
  check(code .. " Kampf: zweite Zeile MOVE_ENDED", W.said(W.ns.L.MOVE_ENDED) == 2)
  W.combat(false)
  clean(W, code .. " Abklingzeit")
end

J.done("mv164_modus")
