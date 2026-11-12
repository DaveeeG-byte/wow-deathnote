-- 1.3.0: /dn theme (einband, cover) takes the id, the cover's name and its book title, in the active language and in
-- English, in any case (the help line says "/dn theme <name>"). Unknown words store nothing.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq = M.test, M.eq

local CASES = {
  { "deDE", "harbor" }, { "deDE", "HARBOR" },
  { "deDE", "Kaperbuch" }, { "deDE", "kaperbuch" }, { "deDE", "Privateer's Ledger" }, { "deDE", "privateer" },
  { "deDE", "Fachbetrieb" }, { "deDE", "the workshop" }, { "deDE", "Kundenbuch" }, { "deDE", "Job Book" },
  { "deDE", "Das schwarze Buch" }, { "deDE", "the black book" }, { "deDE", "DeathNote" },
  { "enUS", "Privateer's Ledger" }, { "enUS", "  privateer's ledger  " }, { "enUS", "The Workshop" }, { "enUS", "job book" },
  { "enUS", "The Black Book" },
  { "ruRU", "Книга капера" }, { "ruRU", "Privateer's Ledger" }, { "ruRU", "Мастерская" }, { "ruRU", "The Workshop" },
}
local WANT = {
  harbor = "harbor", HARBOR = "harbor", Kaperbuch = "harbor", kaperbuch = "harbor", ["Privateer's Ledger"] = "harbor",
  privateer = "harbor", Fachbetrieb = "trade", ["the workshop"] = "trade", Kundenbuch = "trade", ["Job Book"] = "trade",
  ["Das schwarze Buch"] = "notebook", ["the black book"] = "notebook", DeathNote = "notebook",
  ["  privateer's ledger  "] = "harbor", ["The Workshop"] = "trade", ["job book"] = "trade", ["The Black Book"] = "notebook",
  ["Книга капера"] = "harbor", ["Мастерская"] = "trade",
}

for _, c in ipairs(CASES) do
  test(("/dn theme %s (%s) -> %s"):format(c[2], c[1], WANT[c[2]]), function()
    -- start from another cover, so the choice is visible
    M.locale = c[1]
    local ns = M.Load({})
    local start = WANT[c[2]] == "trade" and "harbor" or "trade"
    _G.SlashCmdList.DEATHNOTE("theme " .. start)
    eq(ns.Theme.StoredChoice(), start)
    _G.SlashCmdList.DEATHNOTE("theme " .. c[2])
    eq(ns.Theme.StoredChoice(), WANT[c[2]])
    M.locale = os.getenv("DN_LANG") or "deDE"
  end)
end

test("an unknown word stores nothing", function()
  M.locale = "deDE"
  local ns = M.Load({})
  _G.SlashCmdList.DEATHNOTE("theme trade")
  _G.SlashCmdList.DEATHNOTE("theme Quatschbuch")
  eq(ns.Theme.StoredChoice(), "trade")
  M.locale = os.getenv("DN_LANG") or "deDE"
end)

M.done("theme_names")
