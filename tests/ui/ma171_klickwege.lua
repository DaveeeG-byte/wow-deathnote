-- 1.7.1 manual: every way through the manual. The contents shows the way in and all 14 chapters; a row opens its
-- chapter (head = title, its paragraphs, "Contents" and "Next"); "Next" goes on, the last chapter only has
-- "Contents"; every change of page starts at the top; "?" opens the chapter of the open view (tabs, view Claims, the
-- House Rules, back up, the hit list sheet), on Wanted the page last read in this session (at first the contents);
-- "?" again closes; a /reload forgets the page (nothing stored). 1.7.1 fixer (Seite B5): "?" from Copy all and from
-- Unsolved > Filed away, the imprint only in the contents, the foot's height per face, and the change of page from a
-- rolled page in a world where every chapter really rolls (the texts made long in the test). Names made up.
-- Usage: luajit tests/ui/ma171_klickwege.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function db()
  return { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true, news170 = true, news164 = true,
    news160 = true, news150 = true, news140 = true }, enemies = {}, deaths = {} }
end
local function helpOf(W)
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then return f.help end end
end
local function visParas(Hp)
  local n = 0
  for _, p in ipairs(Hp.paras) do if p[2]:IsShown() then n = n + 1 end end
  return n
end
local function scrollDown(Hp)
  local sf = Hp.page.scroll
  for _ = 1, 20 do sf._scripts.OnMouseWheel(sf, -1) end
end
local function atTop(Hp) return Hp.page.offset == 0 end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code, { db = db() })
  local ns, L = W.ns, W.ns.L
  local UI = ns.UI
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help)
  local Hp = helpOf(W)
  local M = UI.Manual()
  check(code .. " ? oeffnet die Gebrauchsanweisung, zuerst den Inhalt", Hp and Hp:IsShown() and Hp.at == 0)
  check(code .. " Inhalt: Kopf ist der Seitenkopf", Hp.head:GetText() == L.HEAD_HELP, Hp.head:GetText())
  check(code .. " Inhalt: Einstieg sichtbar", Hp.intro[2]:IsShown() and Hp.intro[2]:GetText() == M.intro[2])
  local rows = 0
  for i, r in ipairs(Hp.rows) do if r:IsShown() and r.title:GetText() == M.chapters[i].title then rows = rows + 1 end end
  check(code .. " Inhalt: 14 Kapitel als Zeilen", #M.chapters == 14 and rows == 14, rows)
  check(code .. " Inhalt: Zurueck da, Inhalt/Weiter nicht", Hp.back:IsShown() and not Hp.toc:IsShown() and not Hp.next:IsShown())
  check(code .. " Inhalt: keine Absaetze", visParas(Hp) == 0)
  -- the foot: imprint (de/en humor) and its height only in the contents
  check(code .. " Impressum vorhanden (Humor)", Hp.foot ~= nil and Hp.footTOC > 44, Hp.footTOC)
  check(code .. " Inhalt: Impressum sichtbar, Fuss in Inhaltshoehe", Hp.foot and Hp.foot:IsShown() and Hp.page.footH == Hp.footTOC,
    Hp.page.footH)
  -- every row, every chapter
  for i, ch in ipairs(M.chapters) do
    W.click(Hp.rows[i])
    local same = Hp.at == i and Hp.head:GetText() == ch.title and visParas(Hp) == #ch.paras
    for p, x in ipairs(ch.paras) do same = same and Hp.paras[p][2]:GetText() == x[2] end
    check(code .. " Kapitel " .. i .. " aus dem Inhalt: Titel und Absaetze", same, Hp.head:GetText())
    check(code .. " Kapitel " .. i .. ": Inhalt da, Weiter " .. (i < 14 and "da" or "weg"), Hp.toc:IsShown()
      and Hp.next:IsShown() == (i < 14) and not Hp.back:IsShown() and not Hp.intro[2]:IsShown())
    check(code .. " Kapitel " .. i .. ": oben", atTop(Hp))
    check(code .. " Kapitel " .. i .. ": kein Impressum, Fuss 44", not (Hp.foot and Hp.foot:IsShown()) and Hp.page.footH == 44,
      Hp.page.footH)
    W.click(Hp.toc)
    check(code .. " Kapitel " .. i .. ": Inhalt fuehrt zurueck", Hp.at == 0 and Hp.rows[1]:IsShown())
  end
  -- Next through the whole book, each page at the top even when the one before was rolled down
  W.click(Hp.rows[1])
  for i = 2, 14 do
    scrollDown(Hp)
    W.click(Hp.next)
    check(code .. " Weiter zu Kapitel " .. i .. ", oben", Hp.at == i and atTop(Hp), Hp.at)
  end
  local _, _, _, x = Hp.toc:GetPoint(1)
  check(code .. " letztes Kapitel: nur Inhalt, in der Mitte", not Hp.next:IsShown() and Hp.toc:IsShown() and x == 0, x)
  -- "?" again closes; reopened on Wanted: the page last read
  W.click(F.help)
  check(code .. " ? schliesst", not Hp:IsShown())
  W.click(F.help)
  check(code .. " ? auf Gesucht: die zuletzt gelesene Seite (14), oben", Hp:IsShown() and Hp.at == 14 and atTop(Hp), Hp.at)
  W.click(Hp.toc); W.click(Hp.rows[7]); W.click(F.help)
  W.click(F.help)
  check(code .. " Gedaechtnis: Kapitel 7", Hp.at == 7, Hp.at)
  W.click(F.help)
  -- "?" from each view
  local id = {}
  for i, c in ipairs(M.chapters) do id[c.id] = i end
  local function tab(fid)
    for _, t in ipairs(F.tabs) do if t.id == fid then W.click(t); return true end end
  end
  local function press(name, want)
    W.click(F.help)
    check(code .. " ? aus " .. name .. " -> Kapitel " .. tostring(want), Hp:IsShown() and Hp.at == want and atTop(Hp), Hp.at)
    W.click(F.help)
  end
  tab("open"); press("Zu klaeren", id.unsolved)
  tab("open"); ns.FeudUI.oview = "claims"; press("Zu klaeren > Ansprueche", id.bounty); ns.FeudUI.oview = "open"
  tab("open"); ns.FeudUI.oview = "filed"; press("Zu klaeren > Abgelegt", id.unsolved); ns.FeudUI.oview = "open"
  tab("journal"); press("Todesjournal", id.log)
  tab("guild"); UI.JK.state.gview = "enemy"; press("Gilde", id.guild)
  tab("guild"); UI.JK.state.gview = "hunt"; press("Abschussliste", id.hunt); UI.JK.state.gview = "enemy"
  tab("guild"); UI.OV.OpenTake(); W.tick()
  check(code .. " Blatt Alle uebernehmen offen", UI.JK.state.panel == "take")
  press("Alle uebernehmen", id.guild); UI.ClosePanel()
  tab("record"); press("Strafregister", id.record)
  tab("wanted"); ns.FeudUI.view = "guilds"; press("Gesucht > Gilden", id.wanted); ns.FeudUI.view = "players"
  -- the page last read: read chapter 4 yourself first (before, the probe passed on what Wanted > Guilds left)
  tab("wanted"); W.click(F.help); W.click(Hp.toc); W.click(Hp.rows[4]); W.click(F.help)
  press("Gesucht (zuletzt gelesen)", 4)
  UI.OpenPanel("settings"); W.tick(); press("Hausordnung", id.rules)
  UI.OpenIO("export"); W.tick(); press("Buch sichern", id.post)
  UI.OpenIO("import"); W.tick(); press("Buch einlesen", id.post)
  local k = ns.Store.AddManual("Grimwald", "Ashbrand")
  UI.OpenRelease(k); W.tick()
  check(code .. " Blatt Zur Jagd freigeben offen", UI.JK.state.panel == "release")
  press("Zur Jagd freigeben", id.hunt)
  -- "?" from the help itself closes it (no chapter change)
  W.click(F.help); local was = Hp.at; W.click(F.help)
  check(code .. " ? in der Gebrauchsanweisung schliesst sie", not Hp:IsShown() and was == id.hunt)
  -- nothing stored, a /reload starts at the contents
  local stored = false
  for key in pairs(_G.DeathNoteDB.settings or {}) do if tostring(key):lower():find("manual") then stored = true end end
  check(code .. " nichts gespeichert", not stored)
  local R = J.world(code, { db = _G.DeathNoteDB })
  R.ns:Fire("TOGGLE_UI"); R.tick(); R.settle()
  local F2 = R.frame("DeathNoteFrame")
  R.click(F2.help)
  check(code .. " nach /reload: wieder der Inhalt", helpOf(R).at == 0)
  local n, e = R.errors()
  check(code .. " keine Fehler", n == 0, e)
  local n1, e1 = W.errors()
  check(code .. " keine Fehler (erste Welt)", n1 == 0, e1)
end

-- every chapter really rolls (texts four times as long): a change of page from a rolled page starts at the top
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code, { db = db() })
  local ns, L = W.ns, W.ns.L
  for _, c in ipairs(ns.UI.MANUAL_DATA.chapters) do
    for _, p in ipairs(c.paras) do L[p[2]] = (L[p[2]] .. " "):rep(4) end
  end
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help)
  local Hp = helpOf(W)
  W.click(Hp.rows[1])
  for i = 2, 14 do
    scrollDown(Hp)
    check(code .. " lang: Kapitel " .. (i - 1) .. " rollt wirklich", Hp.page.offset > 0, Hp.page.offset)
    W.click(Hp.next)
    check(code .. " lang: Weiter zu Kapitel " .. i .. " beginnt oben", Hp.at == i and atTop(Hp), Hp.page.offset)
  end
  scrollDown(Hp)
  W.click(Hp.toc)
  check(code .. " lang: aus gerolltem Kapitel zum Inhalt, oben", Hp.at == 0 and atTop(Hp), Hp.page.offset)
  W.click(Hp.rows[3])
  check(code .. " lang: Zeile oeffnet Kapitel 3 oben", Hp.at == 3 and atTop(Hp), Hp.page.offset)
  local n, e = W.errors()
  check(code .. " lang: keine Fehler", n == 0, e)
end

-- B8: the contents is tight (rows GF.HELP_ROW_H or text plus GF.HELP_ROW_PAD, gap after the way in
-- GF.HELP_INTRO_GAP); the air under the last row is measured with the image tool (fix-seite.md). In the mock the
-- contents may roll (its widths are wider than the client's): then it rolls cleanly, the last row comes fully into
-- view at the end, and back at the top the way in stands at the top.
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code, { db = db() })
  local ns = W.ns
  local GF = ns.UI.JK.GF
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help)
  local Hp = helpOf(W)
  local tight = true
  for i = 1, #Hp.rows - 1 do
    local a, b = Hp.rows[i], Hp.rows[i + 1]
    local want = math.max(GF.HELP_ROW_H, math.ceil(ns.Look.TextH(a.title)) + GF.HELP_ROW_PAD)
    local ya, yb = select(5, a:GetPoint(1)), select(5, b:GetPoint(1))
    if math.abs((ya - yb) - want) > 0.01 or want > 20 then tight = false end
  end
  -- B8: this holds the spacing (the numbers) and, elsewhere in this test, the clean scrolling; the goal "room under
  -- row 14" itself is measured only in the picture (the image tool), a longer title does not turn this red
  check(code .. " Inhalt: Zeilen eng (18 oder Text plus 4, hoechstens 20)", tight and GF.HELP_ROW_H == 18 and GF.HELP_ROW_PAD == 4
    and GF.HELP_INTRO_GAP == 6)
  local pg = Hp.page
  print(("      %s Inhalt im Kabel: Hoehe %d, Fenster %d, Rollweg %d"):format(code, pg.used or 0, pg.viewH, pg.range))
  if pg.range > 0 then
    scrollDown(Hp)
    local bottom = -select(5, Hp.rows[14]:GetPoint(1)) + ns.Look.TextH(Hp.rows[14].title)   -- in the body, from its top
    local seen = pg.offset + (pg.pin or 0) + pg.viewH
    check(code .. " Inhalt rollt sauber: am Ende steht Zeile 14 ganz im Fenster", pg.offset == pg.range and pg.bar:IsShown()
      and bottom <= seen + 0.01, ("%.1f > %.1f"):format(bottom, seen))
    W.click(Hp.rows[2]); W.click(Hp.toc)
    check(code .. " Inhalt nach dem Rollen: zurueck oben", atTop(Hp))
  end
  local n, e = W.errors()
  check(code .. " Inhalt eng: keine Fehler", n == 0, e)
end

J.done("ma171 klickwege")
