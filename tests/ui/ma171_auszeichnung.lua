-- 1.7.1 fixer (Seite B2): the words of the surface set into the manual's paragraphs and its way in stand out in the
-- small red ink of the cover (GF.ManualMark, one place: GF.ManualArgs). For deDE and enUS in the three covers, on
-- the page itself: every word filled into a paragraph or the way in is wrapped in exactly one colour code of the
-- cover's red ink (Look.RED_INK), nothing else is coloured, no code is nested; titles, the rows of the contents, the
-- keywords and the head carry no colour; UI.Manual(true) gives the same texts without any colour code; a word that
-- brings its own colour along is marked without nesting. Contrast of the mark on the page of each cover (texture
-- times tint, as tests/ui/gesamtschau.lua measures) at least 4.5:1. Names made up.
-- Usage: luajit tests/ui/ma171_auszeichnung.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local WT = J.WT:gsub("/+$", "")

local function strip(s) return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
-- the coloured runs of a text: list of { colour, text }; nil and a reason when codes are nested or open
local function runs(s)
  local out, i = {}, 1
  while true do
    local a, b, col = s:find("|c(%x%x%x%x%x%x%x%x)", i)
    if not a then break end
    local c, d = s:find("|r", b + 1, true)
    if not c then return nil, "offener Farbcode" end
    local inner = s:sub(b + 1, c - 1)
    if inner:find("|c", 1, true) then return nil, "verschachtelt" end
    out[#out + 1] = { col:lower(), inner }
    i = d + 1
  end
  if s:sub(i):find("|r", 1, true) then return nil, "|r ohne Anfang" end
  return out
end
local function hex(c)
  local function h(x) return math.max(0, math.min(255, math.floor(x * 255 + 0.5))) end
  return ("ff%02x%02x%02x"):format(h(c[1]), h(c[2]), h(c[3]))
end

-- contrast as gesamtschau.lua measures it: mean of the texture's writing area times the cover's tint
local function readAll(p) local h = assert(io.open(p, "rb")); local s = h:read("*a"); h:close(); return s end
local function tga(file)
  local s = readAll(WT .. "/DeathNote/Media/" .. file)
  local w, h = s:byte(13) + s:byte(14) * 256, s:byte(15) + s:byte(16) * 256
  local off = 18 + s:byte(1)
  local r, g, b, n = 0, 0, 0, 0
  for y = math.floor(h * 0.25), math.floor(h * 0.75), 4 do
    for x = math.floor(w * 0.15), math.floor(w * 0.85), 4 do
      local i = off + (y * w + x) * 4
      b, g, r, n = b + s:byte(i + 1), g + s:byte(i + 2), r + s:byte(i + 3), n + 1
    end
  end
  return { r / n / 255, g / n / 255, b / n / 255 }
end
local function lin(c) return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
local function lum(c) return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3]) end
local function ratio(a, b) local x, y = lum(a), lum(b); return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05) end

for _, cover in ipairs({ "notebook", "harbor", "trade" }) do
  for _, lang in ipairs({ "deDE", "enUS" }) do
    local W = J.world(lang, { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
      news170 = true, ["ui.theme"] = cover, ui = { theme = cover } }, enemies = {}, deaths = {} } })
    local ns, L = W.ns, W.ns.L
    local UI, Look = ns.UI, ns.Look
    local name = lang .. "/" .. cover
    local mark = hex(Look.RED_INK)
    check(name .. " Farbe der Auszeichnung ist das kleine Rot des Einbands", mark == hex(ns.Theme.Color("accentSmall", cover)), mark)
    -- contrast on the page of this cover, and how far it stands from the ink around it
    local Th = ns.Theme
    local c, t = tga(Th.Pick(cover, "tex", "page")), Th.ParseColor(Th.Pick(cover, "tint", "page")) or { 1, 1, 1 }
    local page = { c[1] * t[1], c[2] * t[2], c[3] * t[3] }
    local rp, ri = ratio(Look.RED_INK, page), ratio(Look.INK, page)
    print(("      %s: Auszeichnung %s auf Seite %.2f:1, Tinte auf Seite %.2f:1"):format(name, mark, rp, ri))
    check(name .. " Auszeichnung auf der Seite mindestens 4.5:1", rp >= 4.5, ("%.2f"):format(rp))

    ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
    UI.OpenPanel("help"); W.tick()
    local RP
    for _, f in ipairs(W.BM.frames) do if f.help and f.settings then RP = f end end
    local Hp = RP.help
    local M, P = UI.Manual(), UI.Manual(true)
    -- the words a text uses, filled plain (the same table the page fills from)
    local a = UI.JK.GF.ManualArgs()
    local function expected(raw)
      local want = {}
      for ph in raw:gmatch("{([%w_]+)}") do want[#want + 1] = strip(a[ph] or "") end
      return want
    end
    local bad = {}
    local function para(where, raw, shown, plain)
      local r, why = runs(shown)
      if not r then bad[#bad + 1] = where .. ": " .. why; return end
      local want = expected(raw)
      if #r ~= #want then bad[#bad + 1] = ("%s: %d ausgezeichnet, %d eingesetzt"):format(where, #r, #want); return end
      for i, x in ipairs(r) do
        if x[1] ~= mark then bad[#bad + 1] = where .. ": Farbe " .. x[1] end
        if x[2] ~= want[i] then bad[#bad + 1] = where .. ": '" .. x[2] .. "' statt '" .. want[i] .. "'" end
      end
      if strip(shown) ~= plain then bad[#bad + 1] = where .. ": ohne Farbe nicht gleich UI.Manual(true)" end
      if plain:find("|", 1, true) then bad[#bad + 1] = where .. ": UI.Manual(true) mit Farbcode" end
    end
    -- the way in, on the page
    para("Einstieg", L.MANUAL_INTRO, Hp.intro[2]:GetText(), P.intro[2])
    local plainTexts = { Hp.head:GetText(), Hp.intro[1]:GetText() }
    for _, r in ipairs(Hp.rows) do plainTexts[#plainTexts + 1] = r.title:GetText() end
    for i, ch in ipairs(UI.MANUAL_DATA.chapters) do
      W.click(Hp.rows[i])
      plainTexts[#plainTexts + 1] = Hp.head:GetText()
      for p, k in ipairs(ch.paras) do
        local shown = Hp.paras[p][2]:GetText()
        if shown ~= M.chapters[i].paras[p][2] then bad[#bad + 1] = ch.id .. "." .. p .. ": Seite ungleich UI.Manual()" end
        para(ch.id .. "." .. p, L[k[2]], shown, P.chapters[i].paras[p][2])
        plainTexts[#plainTexts + 1] = Hp.paras[p][1]:GetText()
      end
      W.click(Hp.toc)
    end
    check(name .. " jedes eingesetzte Wort in Absatz und Einstieg ausgezeichnet, sonst nichts", #bad == 0, table.concat(bad, "; "))
    local coloured = {}
    for _, s in ipairs(plainTexts) do if tostring(s):find("|c", 1, true) then coloured[#coloured + 1] = s end end
    check(name .. " Titel, Zeilen des Inhalts, Stichwoerter und Kopf ohne Farbe", #coloured == 0, table.concat(coloured, " | "))
    local n, e = W.errors()
    check(name .. " keine Fehler", n == 0, e)
  end
end

-- a word that brings its own colour: marked once, no nested code
do
  local W = J.world("deDE", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
    news170 = true }, enemies = {}, deaths = {} } })
  local ns = W.ns
  for ph, key in pairs(ns.UI.MANUAL_DATA.words) do
    if ph == "unsolved" then ns.L[key] = "|cff20a020" .. ns.L[key] .. "|r" end
  end
  local M = ns.UI.Manual()
  local all = { M.intro[2] }
  for _, ch in ipairs(M.chapters) do for _, p in ipairs(ch.paras) do all[#all + 1] = p[2] end end
  local bad = {}
  for _, s in ipairs(all) do
    local r, why = runs(s)
    if not r then bad[#bad + 1] = why .. ": " .. s:sub(1, 50) end
    if s:find("20a020", 1, true) then bad[#bad + 1] = "eigene Farbe blieb: " .. s:sub(1, 50) end
  end
  check("Wort mit eigener Farbe: einmal ausgezeichnet, nichts verschachtelt", #bad == 0, table.concat(bad, "; "))
end

J.done("ma171 auszeichnung")
