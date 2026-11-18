-- Design fixer 1.6.0 (design hunt 7, 8): the right page of a claim, a filed entry and an enemy guild is a sheet pinned
-- with tape like the files (head left, date right, text left), not the empty page with the skull; a claim's head line
-- is how much to whom, the target below it, the buttons say what you do ("Mark as paid") and fit in every language;
-- switching to another file hides the sheet. Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J
local LANGS = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local cut = {}
for _, code in ipairs(LANGS) do
  local t0 = 1700000000 + 1000
  local db = { days = 50, dayAt = math.floor(t0 / 86400) - 1,
    enemies = { ["Alt-Ling"] = { suspected = 1, status = "suspect", day = 1, deaths = { { t = t0 - 99999, role = "suspect" } } } } }
  local W = X.world(WT, code, db)
  local ns, L, F = W.ns, W.L, W.ns.F
  W.kill("Grimm", "Bart", nil, time() - 500)
  W.open()
  W.tab("open")
  local _, _, RP, P = W.frames()
  ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Anna Alt", time(), 250, "Ich Selbst")
  W.tick(); W.settle()
  W.click(W.find(L.VIEW_CLAIMS .. "  1"))
  local S = ns.FeudUI.Sheet and ns.FeudUI.Sheet()
  local main = code == "deDE" or code == "enUS"
  if main then
    J.check(code .. ": Anspruch auf einem angehefteten Blatt", S and S:IsVisible() and P.card:IsVisible()
      and not RP.empty:IsVisible())
    J.check(code .. ": Kopf ANSPRUCH links", S and S.head._text == L.SHEET_CLAIM)
    J.check(code .. ": Schlagzeile Betrag an Empfaenger", S and S.big._text == F(L.CLAIM_HEAD,
      { gold = ns.UI.Kit.GF.Gold(250), name = "Anna" }), S and S.big._text)
    J.check(code .. ": Hinweis: das Buch zahlt nicht", W.find(L.CLAIM_NOTE) ~= nil)
    J.check(code .. ": Knopf ist eine Handlung", L.ACT_PAID ~= (code == "deDE" and "Bezahlt" or "Paid") and W.find(L.ACT_PAID) ~= nil)
  end
  local b = W.find(L.ACT_PAID)
  if not (S and S:IsVisible()) or not b or ns.Look.IsCut(b.text) or ns.Look.IsCut(S.big) or ns.Look.IsCut(S.head) then
    cut[#cut + 1] = code .. " Anspruch"
  end
  -- filed
  W.click(W.find(L.VIEW_FILED .. "  1"))
  if main then
    J.check(code .. ": Abgelegt auf dem Blatt", S and S:IsVisible() and S.head._text == L.VIEW_FILED and not RP.empty:IsVisible())
  end
  -- back to the open list: the file of a death or the poster, the sheet gone
  W.click(W.find(L.VIEW_OPEN))
  if main then
    J.check(code .. ": zurueck: Blatt weg", S and not S:IsVisible())
    local ok, err = W.errors()
    J.check(code .. ": keine Fehler", ok, err)
  end
end
J.check("21 Sprachen: Blatt und Knopf nicht abgeschnitten", #cut == 0, table.concat(cut, ", "))
J.done()
