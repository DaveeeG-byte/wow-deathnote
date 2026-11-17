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

-- the language table of the UI hunt
local EN = ns.Locale.Raw("enUS")
for k, v in pairs(EN) do
  if type(v) == "string" then
    local l = v:lower()
    check("enUS " .. k .. " sagt copy, nicht take over", not (l:find("take over", 1, true) or l:find("taken over", 1, true)
      or l:find("taking over", 1, true)), v)
  end
end
local WANT = {
  enUS = { ACT_TAKE = "Copy to my book", ACT_TAKE_ALL = "Copy all", ROW_TAKE = "copy", TALLY_ADOPTED = "copied from {name}" },
  frFR = { IO_OWNER = "À qui", IO_MINE = "à moi", IO_THEIRS = "à {name}", IO_THEIRS_ANON = "à quelqu’un d’autre", GRUDGE_HEAD = "ATTAQUE" },
  esES = { IO_OWNER = "De quién", IO_MINE = "mío", IO_THEIRS = "de {name}", IO_THEIRS_ANON = "de otra persona", GRUDGE_HEAD = "ATAQUE" },
  ruRU = { FILTER_ATTACK = "Злопамятство", SORT_KILLS = "Убил меня" },
  koKR = { FILTER_ATTACK = "앙심" },
  trTR = { ACT_TAKE_ALL_OF = "Hepsini al: {name}", TALLY_ADOPTED = "alındı · kaynak: {name}",
    NOTE_ADOPTED_FRIEND = "Alındı, kaynak: {name} (arkadaşları {kills}× öldürdü)." },
}
for c, keys in pairs(WANT) do
  local T = ns.Locale.Raw(c)
  for k, v in pairs(keys) do check(c .. " " .. k, T[k] == v, T[k]) end
end
-- one word per function: the grudge filter says what the stamp and the switch say
for _, c in ipairs({ "ruRU", "koKR" }) do
  local T = ns.Locale.Raw(c)
  -- the switch writes the word in lower case, the filter starts with a capital: compare from the second letter on
  local tail = T.FILTER_ATTACK:gsub("^[%z\1-\127\194-\244][\128-\191]*", "")
  check(c .. " Filter und Schalter ein Wort", T.OPT_GRUDGE:find(c == "koKR" and T.FILTER_ATTACK or tail, 1, true) ~= nil,
    T.FILTER_ATTACK .. " / " .. T.OPT_GRUDGE)
end

print(("fix140 texte        %d ok, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
