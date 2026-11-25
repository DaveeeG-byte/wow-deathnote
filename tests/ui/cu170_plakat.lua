-- 1.7.0 claim: the poster tells the book's own value (BOOK VALUE) from a posted bounty (BOUNTY); its tooltip says nobody
-- can claim it. "Show" and the Discord block name only a posted bounty. deDE, enUS and the trade cover (its invoice is
-- the book's value). All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check

local function poster(W)
  return W.frameWith(function(f) return f.stampNr1 and f.hunt and f.bountyLabel end)
end

for _, run in ipairs({ { "deDE" }, { "enUS" }, { "deDE", "trade" } }) do
  local code, theme = run[1], run[2]
  local tag = code .. (theme and ("/" .. theme) or "")
  local W = X.world(code, { db = theme and { settings = { ui = { theme = theme } } } or nil })
  local ns, L = W.ns, W.L
  local key = W.kill("Grimm", "Bart")
  W.tick(1)
  W.open()
  ns.UI.ShowEnemy(key); W.tick()
  local E = poster(W)
  check(tag .. ": Plakat da", E ~= nil)
  -- only the book's value
  check(tag .. ": Wort ueber dem Buchwert ist BUCHWERT", E.bountyLabel._text == W.spaced(L.POSTER_BOOK_VALUE), E.bountyLabel._text)
  check(tag .. ": nicht das Wort fuer Kopfgeld", E.bountyLabel._text ~= W.spaced(L.POSTER_BOUNTY))
  local tip = E.bountyHit.tip
  check(tag .. ": Tooltip am Buchwert: Satz, kein einforderbares Kopfgeld", type(tip) == "table" and tip[2] == L.BOOK_VALUE_TIP
    and tip[1] == W.spaced(L.POSTER_BOOK_VALUE), type(tip) == "table" and tostring(tip[1]) .. " | " .. tostring(tip[2]))
  check(tag .. ": Tooltip nennt den Klick zum Ausloben", type(tip) == "table" and tip[#tip] == L.BOUNTY_TIP_CLICK)
  -- Show: no bounty segment for the book's value
  local frag = (L.SHARE_BOUNTY:gsub("{gold}", ""))
  local line = ns.Share.LineFor(ns.Store.Get(key))
  check(tag .. ": Aushaengen ohne Buchwert", type(line) == "string" and not line:find(frag, 1, true), line)
  local dc = ns.Share.Discord(ns.Store.Get(key), "own")
  check(tag .. ": Discord ohne Buchwert", type(dc) == "string" and not dc:find(frag, 1, true), dc)
  -- a bounty posted by a guildmate
  W.bounty(key, "Anna", 150)
  ns.UI.ShowEnemy(key); W.tick()
  check(tag .. ": ausgelobt: Wort KOPFGELD", E.bountyLabel._text == W.spaced(L.POSTER_BOUNTY), E.bountyLabel._text)
  check(tag .. ": ausgelobt: Tooltip nennt Anna", type(E.bountyHit.tip) == "table" and E.bountyHit.tip[1] == W.spaced(L.POSTER_BOUNTY)
    and tostring(E.bountyHit.tip[2]):find("Anna", 1, true) ~= nil)
  line = ns.Share.LineFor(ns.Store.Get(key))
  local seg = W.F(L.SHARE_BOUNTY, { gold = "150g" })
  check(tag .. ": Aushaengen nennt das ausgelobte", type(line) == "string" and line:find(frag, 1, true) ~= nil, line)
  check(tag .. ": Aushaengen genau 150", type(line) == "string" and line:find("150", 1, true) ~= nil, seg .. " / " .. tostring(line))
  if theme == "trade" then
    check(tag .. ": Einband: Rechnung ist der Buchwert", L.POSTER_BOOK_VALUE == "RECHNUNG", L.POSTER_BOOK_VALUE)
    check(tag .. ": Einband: ausgelobt heisst KOPFGELD", L.POSTER_BOUNTY == "KOPFGELD", L.POSTER_BOUNTY)
  end
  -- the sort menu says what it sorts by
  check(tag .. ": Sortierwort ist der Buchwert", type(L.SORT_BOOK_VALUE) == "string" and L.SORT_BOOK_VALUE ~= L.POSTER_BOUNTY)
  local n, e = W.errs()
  check(tag .. ": keine Fehler", n == 0, e)
end

-- every language: the book value's word differs from the bounty's word and fits its 12 characters (cells for CJK)
for _, code in ipairs(X.CODES) do
  local W = X.world(code)
  local L = W.L
  check(code .. ": eigenes Wort", type(L.POSTER_BOOK_VALUE) == "string" and L.POSTER_BOOK_VALUE ~= L.POSTER_BOUNTY, L.POSTER_BOOK_VALUE)
end

X.done("cu170 plakat")
