-- 1.6.2: the low findings of the 1.6.0 surface hunt that need no new words.
--  5  a second help call while the slip stands: the kicker counts ("+1"), the tooltip keeps the earlier call
--  9  a chronicle line under "Yesterday" or a date says the time of day, not "1 day ago" again
-- 12  "File old suspicions" stands with the book's own switches, not below the section MAP
-- 16  the dot on the guild tab is a round texture, not a flat square
-- 18  the page of an enemy guild says what a feud does before it is declared
-- 19  a single cause of death carries no rank number
-- Names made up. Call from the project root: luajit tests/ui/fix162_kleine_funde.lua .
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local FD = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fdwelt.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns, L = W.ns, W.ns.L

  -- 9: the chronicle
  FD(W, { { "Liora", "Grimm", "Bart", 1 }, { "Bertram", "Grimm", "Bart", 30 }, { "Liora", "Velka", "Dorn", 80 } })
  local rows, n, old = ns.GuildLog.Rows(), 0, 0
  local day
  for _, r in ipairs(rows) do
    if r.head then day = r.head
    elseif r.event then
      n = n + 1
      if day == L.GLOG_TODAY then
        J.check(code .. ": Chronik heute: relative Zeit", r.ago == ns.Util.Ago(r.event.t), r.ago)
      else
        old = old + 1
        J.check(code .. ": Chronik unter " .. tostring(day) .. ": Uhrzeit", r.ago == ns.Util.Clock(r.event.t) and r.ago:match("^%d%d:%d%d$") ~= nil, r.ago)
      end
    end
  end
  J.check(code .. ": Chronik hat Zeilen unter einem aelteren Tag", n >= 3 and old >= 2, n .. "/" .. old)

  -- 5: two calls in a row
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  local function call(from)
    W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(), display = "Grimwald Ashbrand" }), "GUILD", from .. "-Forever")
    W.tick(1)
  end
  call("Liora")
  local slip = rawget(W.G, "DeathNoteCall")
  local head = ns.Extras.Spaced(L.CALL_SLIP_HEAD)
  J.check(code .. ": erster Ruf: Kopf ohne Zaehler", slip and slip:IsShown() and slip.kicker:GetText() == head, slip and slip.kicker:GetText())
  local first = slip and slip.full
  call("Bertram")
  J.check(code .. ": zweiter Ruf: Zettel nennt den neuen Rufer", slip.name:GetText() == "Bertram", slip.name:GetText())
  J.check(code .. ": zweiter Ruf: Kopf zaehlt +1", slip.kicker:GetText() == head .. "   +1" and not ns.Look.IsCut(slip.kicker), slip.kicker:GetText())
  J.check(code .. ": zweiter Ruf: der erste bleibt fuer den Tooltip", slip.kept and slip.kept[1] == first and first ~= slip.full)
  -- after the slip went, the next one starts anew
  W.tick(60); W.settle()
  J.check(code .. ": Zettel ist weg", not slip:IsShown())
  call("Liora")
  J.check(code .. ": neuer Zettel nach der Pause: ohne Zaehler", slip:IsShown() and slip.kicker:GetText() == head and #slip.kept == 0, slip.kicker:GetText())

  -- 19: one cause, then two
  local Fa = ns.Fates
  Fa.Record({ kind = "pve", t = time() - 50, zone = "Brachland", cause = { art = "creature", name = "Grauer Wolf", npc = 1001 } })
  local r1 = Fa.Ranked()
  J.check(code .. ": eine Ursache: keine Rangnummer", #r1 == 1 and r1[1].solo == true and r1[1].rank == 1, #r1)
  Fa.Record({ kind = "pve", t = time() - 40, zone = "Brachland", cause = { art = "creature", name = "Sumpfkrokilisk", npc = 1002 } })
  local r2 = Fa.Ranked()
  J.check(code .. ": zwei Ursachen: Rangnummern", #r2 == 2 and r2[1].solo == nil and r2[2].solo == nil, #r2)

  -- 16: the dot
  W.open()
  local gtab
  for _, f in ipairs(W.BM.frames) do if f.id == "guild" and f.mark and f._scripts and f._scripts.OnClick then gtab = f end end
  ns.GuildLogUI.UpdateMarks()
  local d = gtab and gtab.glogDot
  J.check(code .. ": Punkt am Reiter ist eine runde Textur", d ~= nil and not d.dnFlat and tostring(d._texture or d._tex or d.file or ""):find("scene_badge", 1, true) ~= nil
    and d:GetWidth() == d:GetHeight(), d and tostring(d._texture or d._tex or d.file))

  -- 12: the switch stands above the section MAP
  local exp, map
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and f._text == L.OPT_BOOK_EXPIRE then exp = f end
    if f._kind == "FontString" and type(f._text) == "string" and f._text:gsub(" ", "") == L.SET_SEC_MAP:gsub(" ", "") then map = f end
  end
  ns.UI.OpenPanel("settings"); W.tick(); W.settle()
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and f._text == L.OPT_BOOK_EXPIRE then exp = f end
    if f._kind == "FontString" and type(f._text) == "string" and f._text:gsub(" ", "") == L.SET_SEC_MAP:gsub(" ", "") then map = f end
  end
  J.check(code .. ": Schalter Ablegen steht ueber dem Abschnitt KARTE", exp and map and exp:GetTop() and map:GetTop() and exp:GetBottom() > map:GetTop(),
    exp and map and (tostring(exp:GetBottom()) .. " / " .. tostring(map:GetTop())))
end
J.done()
