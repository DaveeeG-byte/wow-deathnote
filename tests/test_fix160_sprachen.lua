-- Fixer 1.6.0: guards for the language corrections of the UI hunt (jagd-ui.md, table "Sprachkorrekturen"). Per language:
-- the chat line of filed suspicions names the real tab and view words; the House Rules line and button use the
-- cover's House Rules word; the 1.6.0 blocks of da/nb/sv/nl/cs say "guild" like the rest of their file; zh counts the
-- others right; a few single keys as corrected.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/fix160_sprachen.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok = M.test, M.ok

local CODES = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local Ls = {}
for _, c in ipairs(CODES) do M.locale = c; Ls[c] = M.Load().L end
M.locale = "deDE"

test("Abgelegt-Zeile nennt Reiter und Ansicht der Sprache", function()
  local bad = {}
  for _, c in ipairs(CODES) do
    local L = Ls[c]
    if not (L.FEUD_EXPIRED_CHAT:find(L.TAB_UNSOLVED, 1, true) and L.FEUD_EXPIRED_CHAT:find(L.VIEW_FILED, 1, true)) then
      bad[#bad + 1] = c
    end
  end
  ok(#bad == 0, "falsche Woerter: " .. table.concat(bad, " "))
end)

test("Mehrzahl in der Abgelegt-Zeile (ru, uk, pl, cs, hr)", function()
  for _, c in ipairs({ "ruRU", "ukUA", "plPL", "csCZ", "hrHR" }) do
    ok(Ls[c].FEUD_EXPIRED_CHAT:find("{count|", 1, true), c)
  end
end)

test("Hausordnung heisst ueberall wie im Buch", function()
  local bad = {}
  for _, c in ipairs({ "ruRU", "ukUA", "itIT", "fiFI", "zhCN", "zhTW", "deDE", "enUS" }) do
    local L = Ls[c]
    local stem = L.HEAD_RULES:sub(1, math.max(3, #L.HEAD_RULES - 3))   -- inflected forms (Распорядке, tavoissa)
    if not (L.OPTIONS_OPEN:find(stem, 1, true) and L.OPTIONS_LINE:find(stem, 1, true)) then bad[#bad + 1] = c end
  end
  ok(#bad == 0, table.concat(bad, " "))
end)

test("1.6.0-Bloecke sagen guild wie der Rest der Datei", function()
  local words = { daDK = { "laug", "Laug" }, nbNO = { "laug", "Laug" }, svSE = { "gille", "Gille" }, nlNL = { "gilde", "Gilde" },
    csCZ = { "cech", "Cech" } }
  for code, ws in pairs(words) do
    local h = assert(io.open(DIR .. "/DeathNote/Locales/" .. code .. ".lua"))
    local src = h:read("*a"); h:close()
    local tail = src:sub((src:find("\n%-%- 1%.6%.0") or #src))
    for _, w in ipairs(ws) do ok(not tail:find(w, 1, true), code .. ": " .. w) end
  end
end)

test("Einzelne Korrekturen", function()
  ok(Ls.zhCN.GLOG_VICTIMS_MORE:find("另外", 1, true) and Ls.zhTW.GLOG_VICTIMS_MORE:find("另外", 1, true), "zh: und n weitere")
  ok(Ls.deDE.CALL_BUTTON == "Rufen" and Ls.enUS.CALL_BUTTON == "Call", "Knopf Rufen")
  ok(Ls.enUS.CLAIM_LINE:find("gold owed", 1, true), "enUS owed")
  ok(not Ls.frFR.GLOG_EV_AVENGED_ME:find("vengé", 1, true), "frFR vengé toi")
  ok(Ls.fiFI.FEUD_DECLARE == "Julista kiista" and Ls.csCZ.FEUD_DECLARE == "Vyhlásit spor", "Fehde fi/cs")
  ok(Ls.huHU.VIEW_GUILDS == "Céhek", "huHU Céhek")
  ok(Ls.svSE.FATE_AW_STREAK == "Otursserie", "svSE Otursserie")
  ok(Ls.deDE.FATE_NOTE_FOE:find("^Rangliste"), "deDE Ursachen-Akte")
end)

M.done("fix160 sprachen")
