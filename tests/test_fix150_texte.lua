-- 1.5.0 fixer: texts after the UI hunt, in all 21 languages (stand-alone like test_fix140_texte.lua).
-- U10: the word that puts a line into the chat is not the word that shows a place on the map (deDE "Aushängen",
-- enUS "Post"; the switch, the section, the status and the guest card use the same verb; the window's head stays).
-- U11: one word for one thing. U14: the translators' notes say where a word stands.
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
local function read(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function lower(s) return (s:lower()) end
local Raw = ns.Locale.Raw
check("21 Sprachen", #order == 21, #order)

-- U10 -----------------------------------------------------------------------------------------------------------
local de, en = Raw("deDE"), Raw("enUS")
check("deDE Aushängen", de.ACT_SHARE == "Aushängen", de.ACT_SHARE)
check("enUS Post", en.ACT_SHARE == "Post", en.ACT_SHARE)
check("deDE Sektion AUSHÄNGEN", de.SET_SEC_SHOW == "AUSHÄNGEN", de.SET_SEC_SHOW)
check("enUS Sektion POST", en.SET_SEC_SHOW == "POST", en.SET_SEC_SHOW)
check("deDE gesendet", de.SHARE_SENT == "Ausgehängt in {channel}.", de.SHARE_SENT)
check("enUS gesendet", en.SHARE_SENT == "Posted in {channel}.", en.SHARE_SENT)
check("deDE Gast von", de.SHARE_GUEST_BY == "ausgehängt von {name}", de.SHARE_GUEST_BY)
check("enUS Gast von", en.SHARE_GUEST_BY == "posted by {name}", en.SHARE_GUEST_BY)
check("deDE Fensterkopf bleibt", de.SHARE_HEAD == "Im Chat zeigen", de.SHARE_HEAD)
check("enUS Fensterkopf bleibt", en.SHARE_HEAD == "Show in the chat", en.SHARE_HEAD)
for _, c in ipairs(order) do
  local T = Raw(c)
  local word = lower(T.ACT_SHARE)
  check(c .. " Aushaengen ist nicht das Wort der Karte", not lower(T.SCENE_SHOW):find(word, 1, true), T.ACT_SHARE .. " / " .. T.SCENE_SHOW)
  check(c .. " Schalter nennt das Wort", T.OPT_SHARE_REVENGE:find(T.ACT_SHARE, 1, true) ~= nil, T.OPT_SHARE_REVENGE)
end
-- the line after the update names the same thing with the same word
check("deDE Neuigkeit: aushängen", de.CHAT_NEWS_150:find("aushängen", 1, true) ~= nil, de.CHAT_NEWS_150)
check("enUS Neuigkeit: post", en.CHAT_NEWS_150:find("post a poster", 1, true) ~= nil or en.CHAT_NEWS_150:find("Post", 1, true) ~= nil,
  en.CHAT_NEWS_150)

-- U11: one word for one thing (the poster is "Plakat" in the window too; the map's switch and the week line say the
-- same for open debts)
check("deDE Reiter Plakat wie 'Zum Plakat'", de.SHARE_TAB_LINE == "Plakat" and de.CHRON_BACK:find(de.SHARE_TAB_LINE, 1, true) ~= nil,
  de.SHARE_TAB_LINE)
local DEBT = { deDE = "Rechnungen", nlNL = "rekeningen", plPL = "rachunki", itIT = "conti", ruRU = "сч" }
for c, w in pairs(DEBT) do
  local T = Raw(c)
  check(c .. " Kartenschalter und Woche: dasselbe Wort", T.OPT_SCENE_OPEN:find(w, 1, true) ~= nil and T.SHARE_WEEK_DEBTS:find(w, 1, true) ~= nil,
    T.OPT_SCENE_OPEN .. " / " .. T.SHARE_WEEK_DEBTS)
end

-- U14: the translators' notes in enUS say where the words stand
local ENF = read(DIR .. "Locales/enUS.lua")
local function note(key) return ENF:match("\nL%." .. key .. " = \"[^\n]-\"%s*%-%-([^\n]*)") or "" end
check("enUS Hinweis CHRON_OPEN: rechts neben DEEDS", note("CHRON_OPEN"):find("right of DEEDS", 1, true) and not note("CHRON_OPEN"):find("below the photo", 1, true),
  note("CHRON_OPEN"))
check("enUS Hinweis OPT_G_SENDPLACE: Gruppe SHARE", note("OPT_G_SENDPLACE"):find("group SHARE", 1, true) and not note("OPT_G_SENDPLACE"):find("More", 1, true),
  note("OPT_G_SENDPLACE"))

print(("fix150 texte        %d ok, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
