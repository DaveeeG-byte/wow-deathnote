-- 1.6.4 move: the kept places. Over a /reload (a new world on the same saved data) the real alarm, the real notice,
-- the real help call slip and the grudge notice stand where they were dropped; reset in the mode and by
-- /dn move reset; broken saved places (no table, missing fields, text instead of numbers, unknown anchors, off the
-- screen) break nothing and fall back to the default; the alarm's size (alert.scale) and the UI scale (0.6 to 1.0)
-- do not move a kept place; a change of language in the mode breaks nothing. Names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function near(a, b, tol) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 0.5) end
local function same(r1, r2, tol)
  for i = 1, 4 do if not near(r1[i], r2[i], tol) then return false end end
  return true
end
local function fmt(r) return r[1] and ("%.1f %.1f %.1f %.1f"):format(r[1], r[2], r[3], r[4]) or "nil" end

local function realAlarm(W)
  W.ns:Fire("TEST_ALERT"); W.tick(0.5)
  return W.frame("DeathNoteAlert")
end
local function realNotice(W)
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  return W.frame("DeathNoteBanner")
end
local function realCall(W)
  W.ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 })
  W.tick(0.1)
  return W.frame("DeathNoteCall")
end

-- each world installs its own globals (chat, combat): a world is only used until the next one is made
for _, ui in ipairs({ 1, 0.6 }) do
  local tag = "UI " .. ui
  -- the defaults of 1.6.3 (unmoved) in this UI scale
  local D = J.world("deDE", { ui = ui })
  D.ns.Store.AddManual("Velka Thornheart")
  local def = {}
  def.a = { D.rect(realAlarm(D)) }; D.settle()
  def.b = { D.rect(realNotice(D)) }; D.settle()
  def.s = { D.rect(realCall(D)) }; D.tick(21)
  -- (1) drop all four, end the mode, /reload: the real ones stand there
  local W = J.world("deDE", { ui = ui })
  W.ns.Store.AddManual("Velka Thornheart")
  W.slash("move")
  local want = {}
  for name, d in pairs({ DeathNoteAlert = { -500, -100 }, DeathNoteBanner = { 400, -300 }, DeathNoteCall = { -300, -500 },
      DeathNoteGrudge = { -900, 200 } }) do
    W.drag(W.frame(name), d[1], d[2])
    want[name] = { W.rect(W.frame(name)) }
  end
  W.slash("move")
  local R = W.reload("deDE", { ui = ui })
  R.ns.Store.AddManual("Velka Thornheart")
  local a = realAlarm(R)
  check(tag .. " neu geladen: Alarm an seiner Lage", same({ R.rect(a) }, want.DeathNoteAlert), fmt({ R.rect(a) }) .. " / " .. fmt(want.DeathNoteAlert))
  local ok, why = R.buttonOk()
  check(tag .. " neu geladen: Zielknopf deckungsgleich", ok and R.shown("DeathNoteAlertButton"), why)
  R.settle()
  local b = realNotice(R)
  check(tag .. " neu geladen: Meldung an ihrer Lage", same({ R.rect(b) }, want.DeathNoteBanner), fmt({ R.rect(b) }) .. " / " .. fmt(want.DeathNoteBanner))
  R.settle()
  local s = realCall(R)
  local sr = { R.rect(s) }
  -- the slip's height follows its text: compare its top edge and its sides
  check(tag .. " neu geladen: Zettel an seiner Lage", near(sr[1], want.DeathNoteCall[1]) and near(sr[3], want.DeathNoteCall[3])
    and near(sr[4], want.DeathNoteCall[4]), fmt(sr) .. " / " .. fmt(want.DeathNoteCall))
  R.tick(21)
  R.ns.Grudge.Test(); R.tick(0.6)
  local c = R.frame("DeathNoteGrudge")
  local cr = { R.rect(c) }
  check(tag .. " neu geladen: Rachsucht an ihrer Lage", near(cr[1], want.DeathNoteGrudge[1]) and near(cr[2], want.DeathNoteGrudge[2]),
    fmt(cr) .. " / " .. fmt(want.DeathNoteGrudge))
  check(tag .. " neu geladen: kein Modus", not R.ns.Place.Active() and #R.samples() == 0)
  local n, first = R.errors()
  check(tag .. " neu geladen: keine Fehler", n == 0, first)

  -- (2) reset: the button on the bar, then /dn move reset outside the mode; the defaults of 1.6.3
  R.slash("move")
  R.click(R.ns.Place.Bar().reset)
  check(tag .. " Zuruecksetzen: Lagen leer", R.ns.Store.Setting("alert.point") == nil and R.ns.Store.Setting("notice.point") == nil
    and R.ns.Store.Setting("call.point") == nil and R.ns.Store.Setting("grudge.point") == nil)
  check(tag .. " Zuruecksetzen: Modus bleibt", R.ns.Place.Active() and #R.samples() >= 3)
  check(tag .. " Zuruecksetzen: Zeile", R.said(R.ns.L.MOVE_RESET_DONE) == 1)
  R.slash("move")
  R.settle()
  local a2 = realAlarm(R)
  check(tag .. " Zuruecksetzen: Alarm auf der Standardlage", same({ R.rect(a2) }, def.a), fmt({ R.rect(a2) }) .. " / " .. fmt(def.a))
  R.settle()
  check(tag .. " Zuruecksetzen: Meldung auf der Standardlage", same({ R.rect(realNotice(R)) }, def.b))
  R.settle()
  check(tag .. " Zuruecksetzen: Zettel auf der Standardlage", same({ R.rect(realCall(R)) }, def.s))
  R.tick(21)
  -- /dn move reset outside the mode
  R.slash("move"); R.drag(R.frame("DeathNoteAlert"), 300, 300); R.slash("move")
  check(tag .. " gezogen", R.ns.Store.Setting("alert.point") ~= nil)
  R.slash("move reset")
  check(tag .. " /dn move reset: Lage leer, kein Modus", R.ns.Store.Setting("alert.point") == nil and not R.ns.Place.Active())
  R.combat(true)
  R.slash("move reset")
  check(tag .. " /dn move reset im Kampf: nur die Zeile", R.said(R.ns.L.MOVE_COMBAT) == 1)
  R.combat(false)
  local n2, first2 = R.errors()
  check(tag .. " Zuruecksetzen: keine Fehler", n2 == 0, first2)
end

-- (3) broken saved places: nothing breaks, the default place is used
local BROKEN = {
  { "Text", "kaputt" }, { "leer", {} }, { "ohne Zahlen", { "TOP", "TOP" } }, { "Text statt Zahl", { "TOP", "TOP", "a", "b" } },
  { "unbekannter Anker", { "MITTE", "TOP", 0, -100 } }, { "Zahl als Anker", { 5, "TOP", 0, -100 } },
  { "riesig", { "TOP", "TOP", 1e9, 0 } }, { "NaN", { "TOP", "TOP", 0 / 0, 0 } }, { "ausserhalb", { "TOP", "TOP", 0, 3000 } },
  { "ausserhalb links", { "LEFT", "LEFT", -4000, 0 } }, { "Skala kaputt", { "TOP", "TOP", 0, -150, "x" } },
}
local D = J.world("enUS")
D.ns.Store.AddManual("Velka Thornheart")
local def = {}
def.a = { D.rect(realAlarm(D)) }; D.settle()
def.b = { D.rect(realNotice(D)) }; D.settle()
def.s = { D.rect(realCall(D)) }; D.tick(21)
D.ns.Grudge.Test(); D.tick(0.6)
def.c = { D.rect(D.frame("DeathNoteGrudge")) }
-- each key gets its own copy (the addon may write into a kept point: the size of 1.6.4 in its fifth field)
local function cp(v)
  if type(v) ~= "table" then return v end
  local o = {}
  for k, x in pairs(v) do o[k] = x end
  return o
end
for _, case in ipairs(BROKEN) do
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = "enUS", alert = { point = cp(case[2]) }, notice = { point = cp(case[2]) }, call = { point = cp(case[2]) },
    grudge = { point = cp(case[2]) } }, enemies = {}, deaths = {} }
  local W = J.world("enUS", { db = db })
  W.ns.Store.AddManual("Velka Thornheart")
  local tag = "kaputt (" .. case[1] .. ")"
  local scale = type(case[2]) == "table" and case[2][5] ~= nil
  local a = realAlarm(W)
  if not scale then
    check(tag .. ": Alarm auf der Standardlage", same({ W.rect(a) }, def.a), fmt({ W.rect(a) }))
  else
    check(tag .. ": Alarm gesetzt wie ohne Skala", a:IsShown() and W.rect(a) ~= nil)
  end
  W.settle()
  if not scale then
    check(tag .. ": Meldung auf der Standardlage", same({ W.rect(realNotice(W)) }, def.b))
    W.settle()
    check(tag .. ": Zettel auf der Standardlage", same({ W.rect(realCall(W)) }, def.s))
    W.tick(21)
    W.ns.Grudge.Test(); W.tick(0.6)
    check(tag .. ": Rachsucht auf der Standardlage", same({ W.rect(W.frame("DeathNoteGrudge")) }, def.c))
  end
  W.ns.Grudge.Close("click"); W.tick(0.1)
  W.slash("move"); W.slash("move")
  local n, first = W.errors()
  check(tag .. ": keine Fehler", n == 0, first)
end

-- (4) the alarm's size: a kept place stays where it is (its anchor corner) when alert.scale changes; also a place
-- kept by 1.6.3 (without the scale), whose place is taken at the size it is shown with
for _, start in ipairs({ { "1.6.4", nil }, { "1.6.3", { "BOTTOMLEFT", "BOTTOMLEFT", 600, 700 } } }) do
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = "deDE", alert = { scale = 1.25, point = start[2] } }, enemies = {}, deaths = {} }
  local W = J.world("deDE", { db = db })
  W.ns.Store.AddManual("Velka Thornheart")
  if not start[2] then
    W.slash("move"); W.drag(W.frame("DeathNoteAlert"), -300, -200); W.slash("move")
  end
  local a = realAlarm(W)
  local l0, b0 = W.rect(a)
  for _, sc in ipairs({ 1.5, 0.8, 1 }) do
    W.ns.Store.Setting("alert.scale", sc); W.tick(0.1)
    local l, b = W.rect(a)
    check(start[1] .. " Skala " .. sc .. ": Ecke bleibt", near(l, l0) and near(b, b0), ("%.1f %.1f / %.1f %.1f"):format(l or -1, b or -1, l0, b0))
    local ok, why = W.buttonOk()
    check(start[1] .. " Skala " .. sc .. ": Zielknopf deckungsgleich", ok, why)
  end
  -- and over a /reload at the last size
  W.settle()
  local R = W.reload("deDE")
  R.ns.Store.AddManual("Velka Thornheart")
  local l, b = R.rect(realAlarm(R))
  check(start[1] .. " Skala nach dem Neuladen: Ecke bleibt", near(l, l0) and near(b, b0), ("%.1f %.1f / %.1f %.1f"):format(l or -1, b or -1, l0, b0))
end

-- (4b) the size changed after a /reload before any alarm was shown (the alarm is built later, at the new size): the
-- place dropped at 125 % stays where it was dropped
do
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = "deDE", alert = { scale = 1.25 } }, enemies = {}, deaths = {} }
  local W = J.world("deDE", { db = db })
  W.slash("move"); W.drag(W.frame("DeathNoteAlert"), -300, -200)
  local l0, b0 = W.rect(W.frame("DeathNoteAlert"))
  W.slash("move")
  local R = W.reload("deDE")
  check("Skala vor dem ersten Alarm: noch kein Alarm gebaut", R.frame("DeathNoteAlert") == nil)
  R.ns.Store.Setting("alert.scale", 1.5); R.tick(0.1)
  R.ns.Store.AddManual("Velka Thornheart")
  local l, b = R.rect(realAlarm(R))
  check("Skala vor dem ersten Alarm: Ecke bleibt", near(l, l0) and near(b, b0), ("%.1f %.1f / %.1f %.1f"):format(l or -1, b or -1, l0, b0))
end

-- (5) UI scale: a place kept at 0.6 stands at the same place in UIParent units at 0.8 and 1.0 (the anchor offset)
do
  local W = J.world("deDE", { ui = 0.6 })
  W.ns.Store.AddManual("Velka Thornheart")
  -- to the lower left, where the place lies on the screen at every UI scale
  W.slash("move"); W.dragTo(W.frame("DeathNoteAlert"), 300, 250); W.dragTo(W.frame("DeathNoteBanner"), 700, 420); W.slash("move")
  local pa = W.ns.Store.Setting("alert.point")
  local pb = W.ns.Store.Setting("notice.point")
  for _, ui in ipairs({ 0.8, 1 }) do
    local R = W.reload("deDE", { ui = ui })
    R.ns.Store.AddManual("Velka Thornheart")
    local a = realAlarm(R)
    local p, _, rp, x, y = a:GetPoint(1)
    check("UI " .. ui .. ": Alarm am selben Anker", p == pa[1] and rp == pa[2] and near(x, pa[3]) and near(y, pa[4]))
    R.settle()
    local b = realNotice(R)
    local bl, _, br, bt = R.rect(b)
    -- the kept anchor (BOTTOMLEFT x, y) is the notice's bottom left corner
    check("UI " .. ui .. ": Meldung am selben Anker", near(bl, pb[3]) and near(bt - 64, pb[4]), ("%.1f %.1f"):format(bl or -1, (bt or 0) - 64))
    local n, first = R.errors()
    check("UI " .. ui .. ": keine Fehler", n == 0, first)
  end
end

-- (6) a change of language in the mode: the choice is kept for the next /reload, the mode goes on unharmed
do
  local W = J.world("deDE")
  W.slash("move")
  W.slash("lang enUS")
  check("Sprache im Modus: Modus laeuft", W.ns.Place.Active() and #W.samples() == 4)
  W.drag(W.frame("DeathNoteAlert"), 100, 100)
  W.slash("move")
  local R = W.reload("enUS")
  R.slash("move")
  check("Sprache nach dem Neuladen: Muster sagt es englisch", R.frame("DeathNoteAlert").hint:GetText() == "Drag to move",
    R.frame("DeathNoteAlert").hint:GetText())
  check("Sprache nach dem Neuladen: Leiste englisch", R.ns.Place.Bar().done.text._text == "Done")
  R.slash("move")
  local n, first = R.errors()
  check("Sprache: keine Fehler", n == 0, first)
end

J.done("mv164_lage")
