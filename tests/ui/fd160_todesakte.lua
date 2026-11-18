-- Design fixer 1.6.0 (design hunt 4): the file of a death by a creature (and of a cause in the ranking) fills its sheet
-- with what the book knows of that cause: the label "deaths by this cause" with the count, the latest deaths with date
-- and place, first and last; the negation ("no player, no alarm, nothing is shared") stands small in the foot.
-- Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local function visible(W, s)
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(s, 1, true) and f:IsVisible() then return f end
  end
end
local function viewWord(W, view)
  for _, f in ipairs(W.BM.frames) do if f.fateView and f.view == view then return f end end
end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local ns, L, F = W.ns, W.ns.L, W.ns.F
  W.AM.Advance(100)
  local zones = { "Wegkreuz", "Klingenhuegel", "Wegkreuz" }
  local last
  for i = 1, 3 do
    local j = { t = time(), kind = "pve", zone = "Brachland", subzone = zones[i], mapID = 1413, x = 51.5, y = 30.2,
      me = "Ich Selbst", myLevel = 30, counted = true, candidates = {},
      cause = { art = "creature", name = "Stachelebermutter", npc = 3100, spell = "Rammen" } }
    ns.Store.RecordDeath(j); ns:Fire("DEATH_RECORDED", j, nil); W.tick(1)
    last = j
    W.AM.Advance(3600)
  end
  ns.UI.Open(); W.settle()
  ns.UI.ShowCase(last); W.settle()
  local function checks(where)
    local head = visible(W, ns.UI.JK.Spaced(L.FATE_LIST_HEAD))
    J.check(code .. " " .. where .. ": Abschnitt Tode durch diese Ursache", head ~= nil)
    J.check(code .. " " .. where .. ": Zahl rechts", visible(W, ns.Look.Times(3)) ~= nil)
    local rows = 0
    for _, f in ipairs(W.BM.frames) do
      if f._kind == "FontString" and f.fatePart and f:IsVisible() and type(f._text) == "string"
        and f._text:find("Rammen", 1, true) and (f._text:find("Wegkreuz", 1, true) or f._text:find("Klingenhuegel", 1, true)) then
        rows = rows + 1
      end
    end
    J.check(code .. " " .. where .. ": drei Tode mit Datum, Ort und Zauber", rows == 3, rows)
    J.check(code .. " " .. where .. ": erster und letzter Tod", visible(W, (F(L.FATE_FIRST_LAST, { first = "\1", last = "\1" })
      :match("^([^\1]*)"))) ~= nil)
    local foot = visible(W, L.FATE_NOTE)
    J.check(code .. " " .. where .. ": Verneinung klein im Fuss", foot ~= nil and foot.fontSize <= 10, foot and foot.fontSize)
  end
  checks("Todesakte")
  local causes = viewWord(W, "causes")
  causes._scripts.OnClick(causes, "LeftButton"); W.settle()
  checks("Ursache")
  J.check(code .. ": keine Addon-Fehler", #W.AM.errors == 0, W.AM.errors[1])
end
J.done()
