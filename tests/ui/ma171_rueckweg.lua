-- 1.7.1 fixer (Seite B3, B4, B7): the ways back out of the manual.
-- B3: "?" from a sheet and closing the manual again ("?" or "Back" in the contents) leads back into that sheet, with
-- what was typed: Put on hit list (the reason), Copy all, the House Rules on their sheet, Back up book, Import book
-- (the pasted text), the guild chronicle. A tab or another button drops the way back.
-- B4: only turning pages yourself (a row, "Next", "Contents") sets the page "?" opens on Wanted; a call by "?" from
-- a view does not. B7: back in the contents, every row title stands in ink (also the row clicked last, which lost
-- the mouse without OnLeave). Names made up. Usage: luajit tests/ui/ma171_rueckweg.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function db()
  return { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true, news170 = true, news164 = true,
    news160 = true, news150 = true, news140 = true }, enemies = {}, deaths = {} }
end
local function pagesOf(W)
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then return f end end
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code, { db = db() })
  local ns = W.ns
  local UI, st = ns.UI, ns.UI.JK.state
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help); W.click(F.help)
  local RP = pagesOf(W)
  local Hp = RP.help
  local id = {}
  for i, c in ipairs(UI.MANUAL_DATA.chapters) do id[c.id] = i end
  local function tab(fid) for _, t in ipairs(F.tabs) do if t.id == fid then W.click(t); return end end end

  -- B3: Put on hit list, back by "?" and by "Back" in the contents, the reason stays
  local key = ns.Store.AddManual("Grimwald", "Ashbrand")
  UI.OpenRelease(key); W.tick()
  RP.release.edit:SetText("hat mich dreimal erwischt")
  W.click(F.help)
  check(code .. " Freigeben: ? zeigt Kapitel 9", Hp:IsShown() and Hp.at == id.hunt, Hp.at)
  W.click(F.help)
  check(code .. " Freigeben: ? zurueck ins Blatt", st.panel == "release" and RP.release:IsShown() and not Hp:IsShown(),
    tostring(st.panel))
  check(code .. " Freigeben: Grund steht noch", RP.release.edit:GetText() == "hat mich dreimal erwischt", RP.release.edit:GetText())
  W.click(F.help); W.click(Hp.toc); W.click(Hp.back)
  check(code .. " Freigeben: Inhalt > Zurueck fuehrt ins Blatt", st.panel == "release" and RP.release:IsShown(), tostring(st.panel))
  check(code .. " Freigeben: Grund steht noch (ueber Zurueck)", RP.release.edit:GetText() == "hat mich dreimal erwischt")
  local poster = ns.GuildLogUI and ns.GuildLogUI.Poster and ns.GuildLogUI.Poster()
  check(code .. " Freigeben: das Plakat liegt nicht darueber", poster ~= nil and not poster:IsShown())
  UI.ClosePanel()

  -- Copy all
  tab("guild")
  UI.OV.OpenTake(); W.tick()
  check(code .. " Alle uebernehmen offen", st.panel == "take" and RP.take:IsShown())
  W.click(F.help)
  check(code .. " Alle uebernehmen: ? zeigt Kapitel 8", Hp.at == id.guild, Hp.at)
  W.click(F.help)
  check(code .. " Alle uebernehmen: zurueck ins Blatt", st.panel == "take" and RP.take:IsShown() and not Hp:IsShown(), tostring(st.panel))
  UI.ClosePanel()

  -- the guild chronicle (red ribbon)
  local GL = ns.GuildLogUI
  local opened = GL and GL.Open and GL.Open()
  check(code .. " Gildenchronik offen", opened == true and GL.IsOpen())
  W.click(F.help)
  check(code .. " Gildenchronik: ? zeigt Kapitel 8, die Chronik tritt zur Seite", Hp.at == id.guild and not GL.IsOpen(), Hp.at)
  W.click(F.help)
  check(code .. " Gildenchronik: zurueck in die Chronik", GL.IsOpen() and st.panel == nil and not Hp:IsShown())
  GL.Close()
  tab("wanted")

  -- the House Rules on their sheet (the second, Alert)
  UI.OpenPanel("settings"); W.tick()
  st.spage = 2; UI.FillSettings(); W.tick()
  W.click(F.help)
  check(code .. " Hausordnung: ? zeigt Kapitel 13", Hp.at == id.rules, Hp.at)
  W.click(F.help)
  check(code .. " Hausordnung: zurueck, samt Blatt", st.panel == "settings" and RP.settings:IsShown() and st.spage == 2
    and RP.settings.pageL:IsShown(), tostring(st.panel) .. " " .. tostring(st.spage))
  UI.ClosePanel()

  -- Back up book and Import book (the pasted text stays)
  UI.OpenIO("export"); W.tick()
  W.click(F.help)
  check(code .. " Buch sichern: ? zeigt Kapitel 12", Hp.at == id.post, Hp.at)
  W.click(F.help)
  check(code .. " Buch sichern: zurueck", st.panel == "export" and RP.io:IsShown() and not Hp:IsShown(), tostring(st.panel))
  UI.ClosePanel()
  UI.OpenIO("import"); W.tick()
  RP.io.edit:SetText("eingefuegter Text")
  W.click(F.help)
  W.click(F.help)
  check(code .. " Buch einlesen: zurueck, der Text steht noch", st.panel == "import" and RP.io:IsShown()
    and RP.io.edit:GetText() == "eingefuegter Text", tostring(st.panel) .. " '" .. tostring(RP.io.edit:GetText()) .. "'")
  UI.ClosePanel()

  -- a tab or another button drops the way back
  UI.OpenRelease(key); W.tick()
  W.click(F.help)
  tab("open")
  check(code .. " Reiterwechsel schliesst die Anleitung", not Hp:IsShown() and st.panel == nil)
  W.click(F.help); W.click(F.help)
  check(code .. " nach dem Reiterwechsel kein Rueckweg ins Blatt", st.panel == nil and not RP.release:IsShown(), tostring(st.panel))
  UI.OpenRelease(key); W.tick()
  W.click(F.help)
  UI.OpenPanel("settings"); W.tick()
  check(code .. " anderer Knopf (Zahnrad): Hausordnung", st.panel == "settings")
  UI.ClosePanel()
  check(code .. " danach kein Rueckweg", st.panel == nil and not RP.release:IsShown())
  -- without a sheet: "?" closes to the tab as before
  tab("wanted")
  W.click(F.help); W.click(F.help)
  check(code .. " ohne Blatt: ? schliesst in den Reiter", st.panel == nil and not Hp:IsShown())

  -- B4: a call by "?" from a view is not remembered
  tab("open"); W.click(F.help)
  check(code .. " ? in Zu klaeren -> Kapitel 3", Hp.at == id.unsolved, Hp.at)
  W.click(F.help)
  tab("wanted"); W.click(F.help)
  check(code .. " danach ? in Gesucht: der Inhalt (nichts selbst gelesen)", Hp.at == 0, Hp.at)
  W.click(Hp.rows[5])
  W.click(F.help)
  tab("journal"); W.click(F.help); W.click(F.help)
  tab("wanted"); W.click(F.help)
  check(code .. " ? in Gesucht: das selbst gelesene Kapitel 5, nicht das Todesjournal", Hp.at == 5, Hp.at)
  W.click(Hp.next)
  W.click(F.help)
  tab("record"); W.click(F.help); W.click(F.help)
  tab("wanted"); W.click(F.help)
  check(code .. " Weiter merkt sich die Seite (6)", Hp.at == 6, Hp.at)
  W.click(Hp.toc)
  W.click(F.help)
  tab("open"); W.click(F.help); W.click(F.help)
  tab("wanted"); W.click(F.help)
  check(code .. " Inhalt merkt sich die Seite (0)", Hp.at == 0, Hp.at)

  -- B7: the row clicked last stands in ink again
  local ink = ns.Look.INK
  local r = Hp.rows[3]
  r._scripts.OnEnter(r)
  W.click(r)   -- the row hides under the mouse; no OnLeave
  W.click(Hp.toc)
  local same = true
  for i, row in ipairs(Hp.rows) do
    local c = row.title._tc or {}
    if math.abs((c[1] or -1) - ink[1]) > 0.001 or math.abs((c[2] or -1) - ink[2]) > 0.001
      or math.abs((c[3] or -1) - ink[3]) > 0.001 then same = false; print("      Zeile " .. i .. " nicht in Tinte") end
  end
  check(code .. " Inhalt: jede Zeile in Tinte, auch die zuletzt geklickte", same)
  W.click(F.help)

  local n, e = W.errors()
  check(code .. " keine Fehler", n == 0, e)
end

J.done("ma171 rueckweg")
