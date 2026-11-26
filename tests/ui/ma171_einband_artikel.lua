-- 1.7.1 manual (fixer after the hunt): German sentences never put an article in front of a word that a cover
-- changes. "in der {rules}" reads "in der Hausordnung" in the notebook but "in der Bordregeln" in the harbor (a plural),
-- "im {record}" reads "im Leistungen" in the trade cover. A word of the surface that follows the cover stands without
-- an article (as a name: "unter {rules}", "Reiter {record}"). Which placeholders follow a cover is read from the covers
-- themselves (German, notebook against harbor and trade), so a new cover word is checked by itself.
-- Usage: luajit tests/ui/ma171_einband_artikel.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local function world(cover)
  return J.world("deDE", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
    ["ui.theme"] = cover, ui = { theme = cover } }, enemies = {}, deaths = {} } })
end
local base = world("notebook")
local words = base.ns.UI.MANUAL_DATA.words
local plain = {}
for ph, key in pairs(words) do plain[ph] = base.ns.L[key] end
plain.guild = base.ns.L.TAB_GUILD_FRIENDS
local themed, nThemed = {}, 0
for _, cover in ipairs({ "harbor", "trade" }) do
  local W = world(cover)
  check("Einband " .. cover .. " aktiv", (W.ns.Locale.themeWords or 0) > 0, W.ns.Locale.themeWords)
  for ph, key in pairs(words) do
    if W.ns.L[key] ~= plain[ph] and not themed[ph] then themed[ph] = true; nThemed = nThemed + 1 end
  end
  if W.ns.L.TAB_GUILD_FRIENDS ~= plain.guild and not themed.guild then themed.guild = true; nThemed = nThemed + 1 end
end
check("es gibt Platzhalter, die einem Einband folgen", nThemed >= 5, nThemed)

-- the raw German texts of the manual (way in, titles, keywords, paragraphs)
local h = assert(io.open(J.WT .. "/DeathNote/Locales/deDE.lua", "r"))
local src = h:read("*a"); h:close()
local ARTICLES = { "der", "die", "das", "den", "dem", "des", "ein", "eine", "einen", "einem", "einer", "eines",
  "im", "am", "zum", "zur", "vom", "beim", "ins", "ans", "aufs" }
local isArt = {}
for _, a in ipairs(ARTICLES) do isArt[a] = true end
local function scan(s)
  local bad, seen = {}, 0
  for key, text in s:gmatch('\nL%.(MANUAL_[%w_]+)%s*=%s*"(.-)"') do
    seen = seen + 1
    for before, ph in text:gmatch("([%wäöüÄÖÜß]+)%s+{([%w_]+)}") do
      if themed[ph] and isArt[before:lower()] then bad[#bad + 1] = key .. ": " .. before .. " {" .. ph .. "}" end
    end
  end
  return bad, seen
end
local bad, seen = scan(src)
check("deutsche Texte der Anleitung gelesen", seen > 100, seen)
check("kein Artikel vor einem Wort, das dem Einband folgt", #bad == 0, table.concat(bad, "; "))
-- 1.7.1 fixer 2 (JN-4): this test, not the hunter's ja02 (blind since the words carry colour), holds A14/A15. Its own
-- red probe: the old sentence of the way in ("in der {rules}") put back into a copy of the text must be found.
do
  local old = "und unter {rules} schlägt"
  local i, j = src:find(old, 1, true)
  check("Rot-Probe: der Einstieg hat die Stelle 'unter {rules}'", i ~= nil)
  if i then
    local mutated = src:sub(1, i - 1) .. "und in der {rules} schlägt" .. src:sub(j + 1)
    local mb = scan(mutated)
    check("Rot-Probe: 'in der {rules}' im Einstieg wird gefunden", #mb == 1 and mb[1] == "MANUAL_INTRO: der {rules}", table.concat(mb, "; "))
  end
end
J.done("ma171 einband artikel")
