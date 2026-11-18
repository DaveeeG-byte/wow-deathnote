-- Design fixer 1.6.0 (design hunt 15): the stamp on the cause that killed you most often follows the cover like every
-- other stamp (Customer Book: REGULAR, Privateer: SEA DEVIL), in 21 languages; the black book keeps NEMESIS.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/test_fd160_einband_stempel.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok = M.test, M.ok

local CODES = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function words(code, theme)
  M.locale = code
  local ns = M.Load({ db = { settings = { ui = { theme = theme } } } })
  return ns.L
end

test("Stempel der Ursache folgt dem Einband (21 Sprachen)", function()
  local bad = {}
  for _, c in ipairs(CODES) do
    local base = words(c, "notebook").FATE_STAMP
    for _, th in ipairs({ "trade", "harbor" }) do
      local w = words(c, th).FATE_STAMP
      if type(w) ~= "string" or w == "" or w == base then bad[#bad + 1] = c .. " " .. th .. ": " .. tostring(w) end
    end
  end
  M.locale = "deDE"
  ok(#bad == 0, table.concat(bad, "; "))
end)

test("deDE: Kundenbuch STAMMKUNDE, Kaperbuch SEETEUFEL, schwarzes Buch ERZFEIND", function()
  ok(words("deDE", "trade").FATE_STAMP == "STAMMKUNDE")
  ok(words("deDE", "harbor").FATE_STAMP == "SEETEUFEL")
  ok(words("deDE", "notebook").FATE_STAMP == "ERZFEIND")
  M.locale = "deDE"
end)

M.done("fd160 einband stempel")
