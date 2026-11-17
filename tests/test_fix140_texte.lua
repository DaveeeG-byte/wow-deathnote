-- 1.4.0 fixer: texts after the hunts, in all 21 languages (stand-alone like test_locales.lua).
-- Hunt UI 8: the grudge tooltips do not name the Wanted tab (the covers call it otherwise: "Kopfgelder", "Crew").
-- Hunt UI language table: the corrections hold (enUS says "copy", never "take over"; frFR/esES "whose book";
-- one word per function in ruRU/koKR; trTR without a genitive on the name; frFR/esES grudge head; ruRU sort word).
local ROOT = (arg and arg[0] and arg[0]:match("^(.*)/tests/")) or "."
local DIR = ROOT .. "/DeathNote/"
local pass, fail = 0, 0
local function check(name, cond, info)
  if cond then pass = pass + 1 else fail = fail + 1; print("  ROT: " .. name .. (info ~= nil and ("  -> " .. tostring(info)) or "")) end
end
_G.GetLocale = function() return "deDE" end
_G.issecretvalue = function() return false end
_G.geterrorhandler = function() return function(e) error(e) end end
_G.CreateFrame = function() return { RegisterEvent = function() end, UnregisterEvent = function() end, SetScript = function() end } end
local ns = {}
assert(loadfile(DIR .. "Locale.lua"))("DeathNote", ns)
local order = { "enUS" }
for _, c in ipairs(ns.Locale.CODES) do if c ~= "enUS" then order[#order + 1] = c end end
for _, c in ipairs(order) do assert(loadfile(DIR .. "Locales/" .. c .. ".lua"))("DeathNote", ns) end
local function lower(s) return (s:lower()) end

for _, c in ipairs(order) do
  local T = ns.Locale.Raw(c)
  local stem = lower(T.TAB_WANTED):sub(1, 6)
  for _, k in ipairs({ "GRUDGE_TIP", "GRUDGE_TIP_YES" }) do
    check(c .. " " .. k .. " ohne Reiternamen", not lower(T[k]):find(stem, 1, true), T[k])
  end
  check(c .. " Abstellen nennt den Befehl", T.GRUDGE_TIP_OFF:find(c == "deDE" and "/dn rachsucht" or "/dn grudge", 1, true))
end

print(("fix140 texte        %d ok, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
