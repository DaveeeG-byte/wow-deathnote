-- Rap sheet (1.3.0): the pure rules of Ledger.lua against the repute concept 6.2 to 6.6.
-- Every row of the table is computed by hand from the concept, not from the code.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ns = M.Load()
local L = ns.Ledger

test("Grey level 1..70 against the fixed list (warcraft.wiki.gg, Mob experience)", function()
  local want = { 0,0,0,0,0,1,2,3,4,4,5,6,7,8,9,10,11,12,13,13,14,15,16,17,18,19,20,21,22,22,23,24,25,26,27,28,29,30,
    31,31,32,33,34,35,35,36,37,38,39,39,40,41,42,43,43,44,45,46,47,51,52,53,54,55,56,57,58,59,60,61 }
  for lv = 1, 70 do eq(L.GreyLevel(lv), want[lv], "grey level of " .. lv) end
  eq(L.GreyLevel(nil), 0); eq(L.GreyLevel(0 / 0), 0)
end)

test("Bands: every border", function()
  local rows = {
    { 40, 40, "gelb" }, { 40, 42, "gelb" }, { 40, 38, "gelb" }, { 40, 37, "gruen" }, { 40, 32, "gruen" },
    { 40, 31, "grau" }, { 40, 1, "grau" }, { 40, 43, "orange" }, { 40, 44, "orange" }, { 40, 45, "rot" },
    { 40, 49, "rot" }, { 40, 50, "schaedel" }, { 60, 51, "grau" }, { 60, 52, "gruen" }, { 5, 1, "gruen" },
    { 6, 1, "grau" }, { 60, 70, "schaedel" }, { 45, 41, "gruen" }, { 45, 35, "grau" }, { 45, 48, "orange" },
  }
  for _, r in ipairs(rows) do eq(L.Band(r[1], r[2]), r[3], r[1] .. " vs " .. r[2]) end
  eq(L.Band(40, nil), "unbekannt"); eq(L.Band(nil, 40), "unbekannt"); eq(L.Band(40, 0), "unbekannt")
  eq(L.Band(40, -1), "unbekannt", "a raw -1 is no level; the skull is its own flag")
  eq(L.Band(40, 20, true), "schaedel"); eq(L.Band(nil, nil, true), "schaedel")
  eq(L.Band(40, M.Secret("lvl", "number")), "unbekannt", "secret level")
  eq(L.Band(40, 5000), "unbekannt", "garbage level")
end)

-- band, ctx, r, e, j, s
local R, G, H, B, P = { revenge = true }, { group = true }, { hunt = true }, { bounty = true }, { protect = true }
local function c(...) local t = {} for _, x in ipairs({ ... }) do for k, v in pairs(x) do t[k] = v end end return t end
local function n(k) return { nthToday = k } end
local K = { kick = true }
local CASES = {
  -- base points of every band
  { "grau", {}, 4, 0, 0, 0 }, { "gruen", {}, 2, 0, 0, 0 }, { "gelb", {}, 0, 3, 0, 0 }, { "orange", {}, 0, 2, 3, 0 },
  { "rot", {}, 0, 1, 6, 0 }, { "schaedel", {}, 0, 0, 10, 0 }, { "unbekannt", {}, 0, 1, 0, 0 },
  -- 1 revenge: no infamy, +2 honour (a grey killer brings 2 honour instead of 4 infamy)
  { "grau", R, 0, 2, 0, 0 }, { "gelb", R, 0, 5, 0, 0 }, { "rot", R, 0, 3, 6, 0 }, { "unbekannt", R, 0, 3, 0, 0 },
  { "gruen", R, 0, 2, 0, 0 },
  -- 2 protection
  { "grau", P, 0, 0, 0, 4 }, { "gelb", P, 0, 3, 0, 4 }, { "grau", c(R, P), 0, 2, 0, 4 },
  -- 3 hit list, 4 foreign bounty; greys never earn hunt
  { "gelb", H, 0, 3, 3, 0 }, { "grau", H, 4, 0, 0, 0 }, { "gruen", H, 2, 0, 3, 0 }, { "orange", B, 0, 2, 8, 0 },
  { "grau", B, 4, 0, 0, 0 }, { "rot", c(H, B), 0, 1, 14, 0 },
  -- 5 group halves honour and hunt (rounded at the end, half up), infamy and protection stay
  { "gelb", G, 0, 2, 0, 0 }, { "orange", G, 0, 1, 2, 0 }, { "rot", G, 0, 1, 3, 0 }, { "schaedel", G, 0, 0, 5, 0 },
  { "grau", G, 4, 0, 0, 0 }, { "gelb", c(P, G), 0, 2, 0, 4 }, { "rot", c(H, G), 0, 1, 5, 0 },
  -- 6 kicking: no honour, hunt, protection; infamy at least 2, also after a revenge
  { "gelb", K, 2, 0, 0, 0 }, { "grau", K, 4, 0, 0, 0 }, { "rot", K, 2, 0, 0, 0 }, { "gelb", c(R, K), 2, 0, 0, 0 },
  { "gelb", c(P, K), 2, 0, 0, 0 }, { "gelb", c(G, K), 2, 0, 0, 0 },
  -- 7 wear: 100, 80, 60, 40, 20, 0 %, at least 1 while the factor is above 0
  { "gelb", n(1), 0, 3, 0, 0 }, { "gelb", n(2), 0, 2, 0, 0 }, { "gelb", n(3), 0, 2, 0, 0 }, { "gelb", n(4), 0, 1, 0, 0 },
  { "gelb", n(5), 0, 1, 0, 0 }, { "gelb", n(6), 0, 0, 0, 0 }, { "gelb", n(9), 0, 0, 0, 0 },
  { "schaedel", n(2), 0, 0, 8, 0 }, { "schaedel", n(3), 0, 0, 6, 0 }, { "schaedel", n(4), 0, 0, 4, 0 },
  { "schaedel", n(5), 0, 0, 2, 0 }, { "schaedel", n(6), 0, 0, 0, 0 }, { "grau", n(5), 1, 0, 0, 0 },
  { "rot", n(5), 0, 1, 1, 0 }, { "grau", c(K, n(2)), 3, 0, 0, 0 }, { "unbekannt", n(6), 0, 0, 0, 0 },
  { "rot", c(G, n(2)), 0, 1, 2, 0 }, { "unbekannt", n(0), 0, 1, 0, 0 }, { "unbekannt", {}, 0, 1, 0, 0 },
  -- order: bounty before group, revenge before group, everything before wear
  { "rot", c(B, G), 0, 1, 6, 0 }, { "gelb", c(R, G), 0, 3, 0, 0 },
  { "schaedel", c(P, H, B, G, n(2)), 0, 0, 7, 3 },
  -- an unknown band id counts as "unknown"
  { "lila", {}, 0, 1, 0, 0 },
}

test("Formula table: " .. #CASES .. " cases (every band, every surcharge, order, wear 100 to 0 %)", function()
  for i, x in ipairs(CASES) do
    local r, e, j, s = L.Points(x[1], x[2])
    local got, want = table.concat({ r, e, j, s }, ","), table.concat({ x[3], x[4], x[5], x[6] }, ",")
    eq(got, want, "case " .. i .. " " .. x[1])
  end
  eq(select("#", L.Points("gelb", nil)), 4, "no ctx")
end)

test("Tier: thresholds 0 10 25 50 100 175 300 500 800 1250, never above 10", function()
  local rows = { { 0, 1, 10 }, { 9, 1, 1 }, { 10, 2, 15 }, { 24, 2, 1 }, { 25, 3 }, { 99, 4 }, { 100, 5 }, { 157, 5 },
    { 194, 6 }, { 299, 6, 1 }, { 300, 7 }, { 799, 8 }, { 800, 9 }, { 1249, 9, 1 }, { 1250, 10 }, { 1e9, 10 } }
  for _, r in ipairs(rows) do
    local t, nx = L.Tier(r[1])
    eq(t, r[2], "tier of " .. r[1])
    if r[3] then eq(nx, r[3], "to next from " .. r[1]) end
  end
  eq(select(2, L.Tier(1250)), nil, "no next at the top"); eq(L.Tier(-5), 1); eq(L.Tier(0 / 0), 1)
end)

test("Path: from 10 counted kills, biggest account, switch only 15 % above the current", function()
  eq(L.Path({ r = 10 }, nil, 9), nil, "9 kills: unwritten")
  eq(L.Path({ r = 10, e = 5 }, nil, 10), "r")
  eq(L.Path({ r = 10, e = 11 }, "r", 50), "r", "11 is not 15 % above 10")
  eq(L.Path({ r = 10, e = 11.6 }, "r", 50), "e")
  eq(L.Path({ r = 10, e = 11.6 }, "s", 50), "e", "the current path has 0")
  eq(L.Path({}, "r", 50), nil); eq(L.Path(nil, nil, 50), nil); eq(L.Path({ r = 1 }, "x", 50), "r", "broken prev")
  eq(L.Path({ j = 5, s = 5 }, nil, 10), "j", "tie: the first in the order r e j s")
end)

test("Needle: -100..100, hunt is neutral, half away from zero", function()
  eq(L.Needle({ e = 10 }), 100); eq(L.Needle({ r = 10 }), -100); eq(L.Needle({ j = 10 }), 0); eq(L.Needle({}), 0)
  eq(L.Needle({ r = 1, e = 2 }), 33); eq(L.Needle({ r = 2, e = 1 }), -33); eq(L.Needle({ r = 1.5, e = 0.5 }), -50)
  eq(L.Needle({ r = 1, e = 1, s = 1, j = 1 }), 25); eq(L.Needle({ r = 3, e = 1 }), -50); eq(L.Needle({ r = -5, e = 1 }), 100)
  eq(L.Needle(nil), 0)
end)

test("States: open, even, ahead, victim, pardoned, suspect", function()
  local rows = { { 0, 1, nil, "wanted", "open" }, { 1, 2, nil, "wanted", "open" }, { 1, 1, nil, "wanted", "even" },
    { 3, 2, nil, "wanted", "ahead" }, { 1, 0, 1, "wanted", "ahead" }, { 0, 0, 1, "wanted", "open" },
    { 0, 0, nil, "wanted", "open" }, { 2, nil, nil, nil, "victim" }, { 5, 5, nil, "pardoned", "pardoned" },
    { 0, 1, nil, "suspect", "suspect" }, { 5, 5, nil, "wanted", "even" } }
  for _, r in ipairs(rows) do eq(L.StateOf(r[1], r[2], r[3], r[4]), r[5], table.concat({ tostring(r[1]), tostring(r[2]),
    tostring(r[4]) }, ":")) end
  eq(L.StateOf(0, 0, nil, nil), nil, "nothing at all")
end)

-- the three players of concept 6.6. Their kill order is not in the concept; these orders were found by a search over
-- the concept's counts (scratchpad of round 1.3.0) and reproduce every row of the three tables
local SEQ = {
  ganker = "grau grau grau+kick+n2 grau gruen grau grau+n3 gruen grau gelb grau gruen grau grau+kick+n2 grau gruen grau grau grau+kick+n2 gruen gelb grau grau grau+n3 grau+n3 grau grau grau+kick+n2 gelb grau gruen grau grau+kick+n2 grau grau+n3 gruen grau grau grau+kick+n2 gelb gruen gruen grau grau grau grau grau+n3 gruen gelb grau+n3",
  duel = "gelb gelb gruen+revenge gelb gelb gelb+revenge gelb gelb gelb+revenge orange+revenge gelb gelb+revenge gelb+protect gelb+revenge+protect gelb+revenge gelb+n2 gelb+n2 orange gelb gelb gelb+n2 orange gelb gelb+n2 gelb+revenge gelb gruen gelb+revenge gelb+revenge gelb gelb orange gelb gelb+revenge+protect gelb+revenge gelb+n2 gelb gruen gelb gelb+protect orange gelb gelb gelb+revenge gelb gelb orange gelb gelb gelb",
  hunter = "rot+group orange gelb+group orange orange orange orange+bounty rot orange rot rot+hunt rot+group+hunt rot+hunt rot rot orange rot rot rot orange+group orange orange orange orange orange rot orange rot gelb gelb rot+group schaedel rot+hunt gelb gelb rot+bounty schaedel rot orange+group orange rot+group schaedel orange rot schaedel+hunt rot gelb gelb gelb orange+group",
}
local function parse(s)
  local out = {}
  for tok in s:gmatch("%S+") do
    local band, ctx = tok:match("^([^+]+)"), {}
    for m in tok:gmatch("%+([%w]+)") do
      local k = m:match("^n(%d)$")
      if k then ctx.nthToday = tonumber(k) else ctx[m] = true end
    end
    out[#out + 1] = { band, ctx }
  end
  return out
end
-- R, E, J, S, sum, tier, path, needle after 10, 25, 50 kills (concept 6.6)
local WANT = {
  ganker = { [10] = { 29, 3, 0, 0, 32, 3, "r", -79 }, [25] = { 73, 6, 0, 0, 79, 4, "r", -84 },
    [50] = { 142, 15, 0, 0, 157, 5, "r", -79 } },
  duel = { [10] = { 0, 34, 3, 0, 37, 3, "e", 91 }, [25] = { 0, 81, 9, 8, 98, 4, "e", 90 },
    [50] = { 4, 156, 18, 16, 194, 6, "e", 86 } },
  hunter = { [10] = { 0, 17, 38, 0, 55, 4, "j", 30 }, [25] = { 0, 38, 111, 0, 149, 5, "j", 26 },
    [50] = { 0, 76, 223, 0, 299, 6, "j", 26 } },
}

for _, who in ipairs({ "ganker", "duel", "hunter" }) do
  test("Concept 6.6, " .. who .. ": every row of the table", function()
    local list = parse(SEQ[who])
    eq(#list, 50)
    local seen = 0
    L.Simulate(list, function(i, acc, mood, counted, path)
      local w = WANT[who][i]
      if not w then return end
      seen = seen + 1
      local sum = acc.r + acc.e + acc.j + acc.s
      eq(table.concat({ acc.r, acc.e, acc.j, acc.s, sum, (L.Tier(sum)), path, L.Needle(mood) }, " "),
        table.concat(w, " "), who .. " after " .. i)
    end)
    eq(seen, 3)
  end)
end

test("Concept 6.6: the counts of the orders match the concept's description", function()
  local function tally(who)
    local t = {}
    for _, k in ipairs(parse(SEQ[who])) do
      t[k[1]] = (t[k[1]] or 0) + 1
      for m in pairs(k[2]) do t[m] = (t[m] or 0) + 1 end
    end
    return t
  end
  local g, d, h = tally("ganker"), tally("duel"), tally("hunter")
  eq(g.grau, 35); eq(g.gruen, 10); eq(g.gelb, 5); eq(g.kick, 6)
  eq(d.gelb, 41); eq(d.orange, 6); eq(d.gruen, 3); eq(d.revenge, 13); eq(d.protect, 4); eq(d.nthToday, 5)
  eq(h.orange, 18); eq(h.rot, 20); eq(h.schaedel, 4); eq(h.gelb, 8); eq(h.group, 8); eq(h.hunt, 5); eq(h.bounty, 2)
end)

M.done("ledger_formula")
