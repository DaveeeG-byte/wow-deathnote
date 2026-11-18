-- Fixer 2 1.6.0 (jb02): at the first start with 1.6.0 (the book has no play days of its own yet) the entries of an
-- older book whose standing may have been set by hand count as set by hand and never expire: pardoned, wanted with only
-- suspicions or attacks, made by hand, with a note. A plain suspicion still expires; the marking runs only once.
-- Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq

local T0 = 1700000000
local function entry(name, o)
  local e = { name = name, surname = "Ling", class = "MAGE", level = 40, kills = 0, assists = 0, suspected = 1,
    status = "suspect", deaths = { { t = T0 - 100, zone = "Z", role = "suspect", source = "recap" } } }
  for k, v in pairs(o or {}) do e[k] = v end
  return e
end
local function book150()
  return { enemies = {
    ["Vergeben-Ling"] = entry("Vergeben", { status = "pardoned" }),
    ["Gesucht-Ling"] = entry("Gesucht", { status = "wanted" }),
    ["Hand-Ling"] = entry("Hand", { manual = true, suspected = 0, deaths = {} }),
    ["Notiz-Ling"] = entry("Notiz", { note = "der mit dem Hut" }),
    ["Verdacht-Ling"] = entry("Verdacht"),
    ["Moerder-Ling"] = entry("Moerder", { kills = 1, suspected = 0, status = "wanted",
      deaths = { { t = T0 - 100, zone = "Z", role = "kill", sure = true, source = "recap" } } }),
  } }
end

test("Erster Start mit 1.6.0: von Hand Gesetztes verfällt nie, ein bloßer Verdacht schon", function()
  local ns = M.Load({ db = book150() })
  local S = ns.Store
  for _, k in ipairs({ "Vergeben-Ling", "Gesucht-Ling", "Hand-Ling", "Notiz-Ling" }) do
    eq(S.Get(k) and S.Get(k).statusHand, true, k .. " gilt als von Hand")
  end
  ok(not S.Get("Verdacht-Ling").statusHand, "der bloße Verdacht nicht")
  ok(not S.Get("Moerder-Ling").statusHand, "der Mörder nicht (er verfällt ohnehin nie)")
  for _ = 1, 31 do M.epoch = M.epoch + 86400; S.Init() end
  for _, k in ipairs({ "Vergeben-Ling", "Gesucht-Ling", "Hand-Ling", "Notiz-Ling", "Moerder-Ling" }) do
    ok(S.Get(k) ~= nil, k .. " nach 31 Spieltagen noch im Buch")
  end
  ok(S.Get("Verdacht-Ling") == nil and S.DB().expired["Verdacht-Ling"] ~= nil, "der bloße Verdacht ist abgelegt")
  eq(S.Get("Vergeben-Ling").status, "pardoned")
end)

test("Nur einmal: ein später vergebener Verdacht wird nicht nachträglich markiert", function()
  local ns = M.Load({ db = book150() })
  local S = ns.Store
  local e = S.Get("Verdacht-Ling")
  e.status = "pardoned"              -- not through SetStatus: no mark, as from a later automatic path
  S.Init()
  ok(not S.Get("Verdacht-Ling").statusHand, "der zweite Start markiert nichts")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

M.done("fix160 jb02 Hand aus altem Buch")
