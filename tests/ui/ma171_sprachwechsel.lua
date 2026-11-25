-- 1.7.1 manual: a change of language or cover (House Rules, then /reload) brings the whole manual along. The book
-- reads in German with chapter 5 open; English and the cover Harbor are chosen; after the /reload the manual opens
-- at the contents, its head, way in, row titles and paragraphs are the English texts of that cover, the chapter
-- titles that are tab words follow the cover. Then back to German and the notebook. Names made up.
-- Usage: luajit tests/ui/ma171_sprachwechsel.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function helpOf(W)
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then return f.help end end
end
local function open(W)
  W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help)
  return helpOf(W), F
end
-- the manual as the page shows it, compared with UI.Manual() of the world and the language table
local function shows(W, Hp, code, label)
  local L, M = W.ns.L, W.ns.UI.Manual()
  check(label .. ": Sprache aktiv " .. code, W.ns.Locale.code == code, W.ns.Locale.code)
  check(label .. ": Inhalt, Kopf " .. tostring(L.HEAD_HELP), Hp.at == 0 and Hp.head:GetText() == L.HEAD_HELP, Hp.head:GetText())
  check(label .. ": Einstieg in dieser Sprache", Hp.intro[2]:GetText() == M.intro[2], Hp.intro[2]:GetText())
  local rows = 0
  for i, r in ipairs(Hp.rows) do if r.title:GetText() == M.chapters[i].title then rows = rows + 1 end end
  check(label .. ": 14 Zeilen in dieser Sprache", rows == 14, rows)
  W.click(Hp.rows[6])
  check(label .. ": Kapitel 6 in dieser Sprache", Hp.head:GetText() == M.chapters[6].title
    and Hp.paras[1][2]:GetText() == M.chapters[6].paras[1][2], Hp.head:GetText())
  W.click(Hp.toc)
  return M
end

local db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true, news170 = true, news164 = true,
  news160 = true, news150 = true, news140 = true, lang = "deDE" }, enemies = {}, deaths = {} }
local W = J.world("deDE", { db = db, whole = true })
local Hp = open(W)
local de = shows(W, Hp, "deDE", "deDE")
local DE = {}   -- the raw German titles (the table of this world, before the /reload)
for _, c in ipairs(W.ns.UI.MANUAL_DATA.chapters) do DE[c.title] = W.ns.L[c.title] end
W.click(Hp.rows[5])
check("deDE: Kapitel 5 offen", Hp.at == 5, Hp.at)
local _, reload = W.ns.Locale.SetChoice("enUS")
check("Sprache Englisch gewaehlt, /reload noetig", reload == true, tostring(reload))
local tid = W.ns.Theme.SetChoice("harbor")
check("Einband Hafen gewaehlt", tid == "harbor", tid)
local n0, e0 = W.errors()
check("deDE: keine Fehler", n0 == 0, e0)

local R = J.world("deDE", { db = _G.DeathNoteDB, whole = true })   -- whole: the client starts, the stored choice wins
local Hp2 = open(R)
local en = shows(R, Hp2, "enUS", "nach /reload enUS/harbor")
check("enUS/harbor: Einband aktiv", R.ns.Theme.id == "harbor", R.ns.Theme.id)
check("enUS/harbor: anderer Einstieg als deDE", en.intro[2] ~= de.intro[2])
local byId = {}
for _, ch in ipairs(en.chapters) do byId[ch.id] = ch.title end
local L = R.ns.L
check("enUS/harbor: Titel folgen dem Einband", byId.log == L.TAB_DEATHLOG and byId.record == L.TAB_RECORD
  and byId.unsolved == L.TAB_UNSOLVED, byId.log .. " / " .. byId.record)
-- every title and paragraph is English now, none stayed German (texts fill from the active table, not a remembered one)
-- (a title that is the same word in both tables, as Alarm, does not count)
local same = {}
local KEYS = R.ns.UI.MANUAL_DATA.chapters
for i, ch in ipairs(en.chapters) do
  local d = de.chapters[i]
  if ch.title == d.title and DE[KEYS[i].title] ~= L[KEYS[i].title] then same[#same + 1] = "Titel " .. ch.id end
  for p, x in ipairs(ch.paras) do if x[2] == d.paras[p][2] then same[#same + 1] = ch.id .. " " .. p end end
end
check("enUS/harbor: kein Titel und kein Absatz blieb deutsch", #same == 0, table.concat(same, ", "))
check("enUS/harbor: Titel Erste Schritte aus der englischen Tabelle", en.chapters[1].title == R.ns.F(L.MANUAL_START_TITLE, {}),
  en.chapters[1].title)
local n1, e1 = R.errors()
check("enUS/harbor: keine Fehler", n1 == 0, e1)

R.ns.Locale.SetChoice("deDE"); R.ns.Theme.SetChoice("notebook")
local B = J.world("enUS", { db = _G.DeathNoteDB, whole = true })
local Hp3 = open(B)
local back = shows(B, Hp3, "deDE", "zurueck deDE/notebook")
check("zurueck: dieselben Texte wie vorher", back.intro[2] == de.intro[2] and back.chapters[6].title == de.chapters[6].title)
local n2, e2 = B.errors()
check("zurueck: keine Fehler", n2 == 0, e2)

J.done("ma171 sprachwechsel")
