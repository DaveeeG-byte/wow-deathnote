-- 1.7.1 manual: the words of the surface come from the language table. For all 21 languages and the three covers:
-- no placeholder stays open in any text of the manual, every placeholder a text uses is a known one, every word it
-- names is a word the surface really shows (its key is read by the code of the book, not only by the manual) and
-- equals the word of that language and cover (a cover's tab word follows by itself; {guild} is the label the fourth
-- tab really carries). German and English: at most 150 words and 7 paragraphs per chapter (keywords not counted), at most 60 for the
-- way in, at most three sentences per paragraph, every page head and row title not empty. Every other language: each
-- chapter and the way in at most LEN_MAX times the characters of English (the length guard in 21 languages: a
-- translation that says much more than enUS is caught here, before the page grows long), and at least LEN_MIN.
-- Usage: luajit tests/ui/ma171_platzhalter.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local WT = J.WT

local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local COVERS = { "notebook", "harbor", "trade" }

-- the code of the book (every .lua of the addon but the language files and the manual's own table)
local code = {}
for line in io.lines(WT .. "/DeathNote/DeathNote.toc") do
  line = line:gsub("\r", ""):gsub("%s+$", "")
  if line:find("%.lua$") and not line:find("^#") and not line:find("Locales") then
    local h = io.open(WT .. "/DeathNote/" .. line:gsub("\\", "/"), "r")
    if h then code[#code + 1] = h:read("*a"); h:close() end
  end
end
local src = table.concat(code, "\n")
-- the manual's word table itself does not count as a use: cut UX.MANUAL_WORDS out
src = src:gsub("UX%.MANUAL_WORDS = %b{}", "")
local function used(key)
  return src:find("L%." .. key .. "%f[^%w_]") ~= nil or src:find('"' .. key .. '"', 1, true) ~= nil
    or src:find("L%[\"" .. key .. "\"%]", 1, false) ~= nil
end

-- measured on 26.11.2026 (characters of the paragraphs, keywords not counted): 0.33 (zhCN) to 1.21 (frFR, itIT)
local LEN_MAX, LEN_MIN = 1.35, 0.25
local function ulen(s) local n = 0; for _ in s:gmatch("[^\128-\191]") do n = n + 1 end return n end
local EN = nil   -- characters per chapter in enUS (first world of the run), [0] = the way in

local function nwords(s) local n = 0; for _ in s:gmatch("%S+") do n = n + 1 end return n end
local function sentences(s)
  local n = 0
  for _ in (s .. " "):gmatch("[%.!%?:;]?[%.!%?][\"“”»]?%s") do n = n + 1 end
  return n
end

local firstWorld = true
for _, cover in ipairs(COVERS) do
  for _, lang in ipairs(CODES) do
    local W = J.world(lang, { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
      ["ui.theme"] = cover, ui = { theme = cover } }, enemies = {}, deaths = {} } })
    local ns, L = W.ns, W.ns.L
    local UI = ns.UI
    local words = UI.MANUAL_DATA.words
    local name = lang .. "/" .. cover
    check(name .. " Einband wirklich aktiv", cover == "notebook" or (ns.Locale.themeWords or 0) > 0, ns.Locale.themeWords)
    if firstWorld then
      firstWorld = false
      local bad = {}
      for ph, key in pairs(words) do if not used(key) then bad[#bad + 1] = ph .. "=" .. key end end
      table.sort(bad)
      check("jedes Platzhalter-Wort steht wirklich an der Oberflaeche (vom Buch gelesen)", #bad == 0, table.concat(bad, ", "))
    end
    -- every placeholder a raw text uses is a known one
    local unknown = {}
    for _, c in ipairs(UI.MANUAL_DATA.chapters) do
      local keys = { c.title }
      for _, p in ipairs(c.paras) do keys[#keys + 1] = p[1]; keys[#keys + 1] = p[2] end
      for _, k in ipairs(keys) do
        for ph in tostring(L[k]):gmatch("{([%w_]+)}") do
          if not (words[ph] or ph == "guild" or UI.MANUAL_DATA.chapterWords[ph]) then unknown[#unknown + 1] = k .. ":" .. ph end
        end
      end
    end
    for ph in tostring(L.MANUAL_INTRO):gmatch("{([%w_]+)}") do
      if not words[ph] then unknown[#unknown + 1] = "MANUAL_INTRO:" .. ph end
    end
    check(name .. " nur bekannte Platzhalter", #unknown == 0, table.concat(unknown, ", "))
    -- filled: nothing open, and the words are those of this language and cover
    local M = UI.Manual()
    local open = {}
    local all = { M.intro[1], M.intro[2] }
    for _, ch in ipairs(M.chapters) do
      all[#all + 1] = ch.title
      if ch.title == "" then open[#open + 1] = "leerer Titel " .. ch.id end
      for _, p in ipairs(ch.paras) do
        all[#all + 1] = p[1]; all[#all + 1] = p[2]
        if p[1] == "" or p[2] == "" then open[#open + 1] = "leer in " .. ch.id end
      end
    end
    for _, t in ipairs(all) do if t:find("[{}]") then open[#open + 1] = t:sub(1, 60) end end
    check(name .. " kein Platzhalter offen", #open == 0, table.concat(open, " | "))
    -- the word of the cover follows: the chapter titles that are a tab word are that tab's word now
    local byId = {}
    for _, ch in ipairs(M.chapters) do byId[ch.id] = ch.title end
    local guildWord = (ns.Friends and L.TAB_GUILD_FRIENDS) or L.TAB_GUILD
    check(name .. " Titel folgen Sprache und Einband", byId.log == L.TAB_DEATHLOG and byId.record == L.TAB_RECORD
      and byId.rules == L.HEAD_RULES and byId.unsolved == L.TAB_UNSOLVED and byId.wanted:find(L.TAB_WANTED, 1, true) ~= nil,
      byId.log .. " / " .. byId.rules)
    local start3 = M.chapters[1].paras[3][2]
    check(name .. " {guild} ist das Wort des vierten Reiters", start3:find(guildWord, 1, true) ~= nil, start3)
    if lang == "deDE" or lang == "enUS" then
      check(name .. " Einstieg hoechstens 60 Woerter", nwords(M.intro[2]) <= 60, nwords(M.intro[2]))
      for _, ch in ipairs(M.chapters) do
        local n, long = 0, nil
        for _, p in ipairs(ch.paras) do
          n = n + nwords(p[2])
          if sentences(p[2]) > 3 then long = p[2] end
        end
        check(name .. " Kapitel " .. ch.id .. ": hoechstens 150 Woerter, 7 Absaetze", n <= 150 and #ch.paras <= 7, n)
        check(name .. " Kapitel " .. ch.id .. ": Absatz hoechstens drei Saetze", long == nil, long)
      end
    end
    -- length guard per chapter, every language against English
    local len = { [0] = ulen(M.intro[2]) }
    for i, ch in ipairs(M.chapters) do
      local n = 0
      for _, p in ipairs(ch.paras) do n = n + ulen(p[2]) end
      len[i] = n
    end
    if lang == "enUS" and not EN then EN = len end
    if EN and lang ~= "enUS" and cover == "notebook" then
      local over = {}
      for i = 0, #M.chapters do
        local r = len[i] / math.max(1, EN[i])
        if r > LEN_MAX or r < LEN_MIN then
          over[#over + 1] = ("%s %.2f"):format(i == 0 and "Einstieg" or M.chapters[i].id, r)
        end
      end
      check(name .. " Laenge je Kapitel zwischen " .. LEN_MIN .. " und " .. LEN_MAX .. " mal Englisch", #over == 0,
        table.concat(over, ", "))
    end
    -- the book shows them: open the manual and one chapter, no error
    ns:Fire("TOGGLE_UI"); W.tick()
    UI.OpenPanel("help"); W.tick()
    local n, e = W.errors()
    check(name .. " keine Fehler", n == 0, e)
  end
end

J.done("ma171 platzhalter")
