-- 1.6.4 move: how a player finds the placing mode. /dn help names it (after the test alarm), /dn test says in one chat
-- line how to move the alarm (command and the button in the book's own words), the line after the update (news164)
-- once for everybody who had the book before, after the older lines he has not seen yet (1.5.0, 1.6.0; as 1.6.3
-- did), never for a new installation, never in combat; the button "Move alarm" stands on the sheet Alert next to
-- "Test alarm" in all 21 languages, within the sheet, its word not cut.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function index(W, text)
  for i, l in ipairs(W.chat()) do if plain(l):find(plain(text), 1, true) then return i end end
end
local function count(W, text)
  local n = 0
  for _, l in ipairs(W.chat()) do if plain(l):find(plain(text), 1, true) then n = n + 1 end end
  return n
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code)
  local L = W.ns.L
  -- /dn help
  W.slash("help")
  local iTest, iMove = index(W, L.HELP_TEST), index(W, L.HELP_MOVE)
  check(code .. " /dn help nennt den Befehl", iMove ~= nil)
  check(code .. " /dn help: gleich nach dem Probealarm", iTest and iMove == iTest + 1, tostring(iTest) .. " " .. tostring(iMove))
  check(code .. " /dn help: Zeile nennt /dn move bzw. verschieben", L.HELP_MOVE:find("/dn move", 1, true) or L.HELP_MOVE:find("/dn verschieben", 1, true))
  -- /dn test
  local before = #W.chat()
  W.slash("test")
  local line = W.chat()[#W.chat()]
  check(code .. " /dn test: eine Zeile", #W.chat() == before + 1, #W.chat() - before)
  check(code .. " /dn test: Alarm steht", W.shown("DeathNoteAlert"))
  check(code .. " /dn test: Zeile nennt Befehl, Hausordnung, Blatt, Knopf", plain(line):find("/dn ", 1, true)
    and line:find(L.HEAD_RULES, 1, true) and line:find(L.SHEET_ALERT, 1, true) and line:find(L.SET_MOVE, 1, true)
    and not line:find("{", 1, true), line)
end

-- the line after the update
local function db(extra)
  local st = { welcomed = true, firstRun = "done", lang = "deDE" }
  for k, v in pairs(extra or {}) do st[k] = v end
  return { version = 5, settings = st, enemies = {}, deaths = {} }
end
do -- from 1.6.x: only the line of 1.6.4, once
  local d = db({ news160 = true, news150 = true, news140 = true })
  local W = J.world("deDE", { db = d })
  W.tick(3)
  check("news164: nicht sofort", count(W, W.ns.Start.NewsLine164()) == 0)
  W.tick(60)
  check("news164: eine Zeile", count(W, W.ns.Start.NewsLine164()) == 1)
  check("news164: nicht die von 1.6.0", count(W, W.ns.Start.NewsLine()) == 0)
  local line = W.ns.Start.NewsLine164()
  check("news164: Platzhalter gefuellt, nennt Befehl, Hausordnung, Blatt, Knopf", not line:find("{", 1, true)
    and line:find("/dn ", 1, true) and line:find(W.ns.L.HEAD_RULES, 1, true) and line:find(W.ns.L.SHEET_ALERT, 1, true)
    and line:find(W.ns.L.SET_MOVE, 1, true), line)
  check("news164: Merker", d.settings.news164 == true)
  local R = W.reload("deDE")
  R.tick(60)
  check("news164: nach dem Neuladen keine zweite", count(R, R.ns.Start.NewsLine164()) == 0)
end
do -- from 1.5.x: the line of 1.6.0 first, then the one of 1.6.4
  local d = db({ news150 = true, news140 = true })
  local W = J.world("deDE", { db = d })
  W.tick(60)
  local i160, i164 = index(W, W.ns.Start.NewsLine()), index(W, W.ns.Start.NewsLine164())
  check("aus 1.5: beide, 1.6.0 zuerst", i160 and i164 and i160 < i164, tostring(i160) .. " " .. tostring(i164))
  check("aus 1.5: nicht die von 1.5.0", count(W, W.ns.L.CHAT_NEWS_150) == 0)
  check("aus 1.5: alle Merker", d.settings.news164 and d.settings.news160 and d.settings.news150 and d.settings.news140)
end
do -- from 1.4.x: 1.5.0, 1.6.0, 1.6.4 in this order
  local d = db({ news140 = true })
  local W = J.world("deDE", { db = d })
  W.tick(60)
  local i150, i160, i164 = index(W, W.ns.L.CHAT_NEWS_150), index(W, W.ns.Start.NewsLine()), index(W, W.ns.Start.NewsLine164())
  check("aus 1.4: drei Zeilen in der Reihenfolge", i150 and i160 and i164 and i150 < i160 and i160 < i164,
    tostring(i150) .. " " .. tostring(i160) .. " " .. tostring(i164))
end
do -- in combat: waits for the end of the fight
  local d = db({ news160 = true, news150 = true, news140 = true })
  local W = J.world("deDE", { db = d })
  W.AM.inCombat, W.BM.combat = true, true
  W.tick(60)
  check("news164: nichts im Kampf", count(W, W.ns.Start.NewsLine164()) == 0 and d.settings.news164 == nil)
  W.combat(false)
  check("news164: nach dem Kampf", count(W, W.ns.Start.NewsLine164()) == 1)
end
do -- a new installation: no line, every marker at once
  local W = J.world("deDE", { db = nil, whole = true })
  W.tick(4)
  local st = _G.DeathNoteDB.settings
  check("neu: alle Merker sofort", st.news164 == true and st.news160 == true and st.news150 == true and st.news140 == true)
  local dlg = W.frame("DeathNoteStart")
  if dlg and dlg.go then dlg.go._scripts.OnClick(dlg.go, "LeftButton") end
  W.tick(60)
  check("neu: keine Zeile", count(W, W.ns.Start.NewsLine164()) == 0 and count(W, W.ns.Start.NewsLine()) == 0)
end

-- the button on the sheet Alert in all 21 languages: there, in the row of "Test alarm", within the sheet, word whole
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK", "fiFI",
  "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
for _, code in ipairs(CODES) do
  local W = J.world(code)
  W.ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
  W.ns.UI.OpenPanel("settings"); W.tick(1)
  local tab
  for _, f in ipairs(W.BM.frames) do if f.page == 2 and f._scripts and f._scripts.OnClick and f:IsVisible() then tab = f end end
  if tab then W.click(tab) end
  local test, move
  for _, f in ipairs(W.BM.frames) do
    if f.text and f._scripts and f._scripts.OnClick and f:IsVisible() then
      if f.text._text == W.ns.L.SET_TEST_ALERT then test = f end
      if f.text._text == W.ns.L.SET_MOVE then move = f end
    end
  end
  check(code .. ": Knopf sichtbar", move ~= nil)
  if move and test then
    local tl, tb, tr, tt = W.rect(test)
    local ml, mb, mr, mt = W.rect(move)
    check(code .. ": in der Zeile des Probealarms", math.abs(mb - tb) < 0.5 and math.abs(mt - tt) < 0.5)
    check(code .. ": rechts daneben, ohne Ueberlappung", ml >= tr + 4)
    local page = W.find and nil
    local AL = move:GetParent()
    local pl, pb, pr, pt = W.rect(AL)
    check(code .. ": innerhalb des Blatts", pl and ml >= pl and mr <= pr - 16, ("%.0f..%.0f in %.0f..%.0f"):format(ml, mr, pl or -1, pr or -1))
    check(code .. ": Wort nicht abgeschnitten", not move.text:IsTruncated(), move.text._text)
  end
  local n, first = W.errors()
  check(code .. ": keine Fehler", n == 0, first)
end

J.done("mv164_auffinden")
