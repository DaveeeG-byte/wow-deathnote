-- 1.7.1 fixer (Seite B1): a keyword of the manual never breaks inside a word. For every chapter in 21 languages and
-- the three covers, every keyword the page shows: it says the whole keyword (letter-spacing taken off, the lines
-- joined at a gap: the same words), a line break stands only at a gap between two words, every line fits its
-- column on its own (the client never has to break one, so it cannot break inside a word), and a keyword that had to
-- be cut has its tooltip. Widths are the UI mock's (wider than the client's); the image tool measures with the real
-- fonts (dev/berichte/171/fix-seite.md). Usage: luajit tests/ui/ma171_stichwort.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local COVERS = { "notebook", "harbor", "trade" }

-- a line as the page writes it, back to the plain words ("A F T E R    A" -> "AFTER A"; a plain line stays)
local function plain(line, Spaced)
  local x = line:gsub("    ", "\0"):gsub(" ", ""):gsub("%z", " ")
  if Spaced(x) == line then return x end
  return line
end
local function lines(s)
  local out = {}
  for l in (s .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
  return out
end

local steps = { spaced1 = 0, spaced2 = 0, plain = 0, cut = 0 }
for _, cover in ipairs(COVERS) do
  for _, lang in ipairs(CODES) do
    local W = J.world(lang, { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
      news170 = true, ["ui.theme"] = cover, ui = { theme = cover } }, enemies = {}, deaths = {} } })
    local ns = W.ns
    local UI, Spaced = ns.UI, ns.UI.JK.Spaced
    ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
    UI.OpenPanel("help"); W.tick()
    local RP
    for _, f in ipairs(W.BM.frames) do if f.help and f.settings then RP = f end end
    local Hp = RP.help
    local M = UI.Manual()
    local bad, n = {}, 0
    for i, ch in ipairs(M.chapters) do
      W.click(Hp.rows[i])
      for p, x in ipairs(ch.paras) do
        local fs, pair = Hp.paras[p][1], Hp.paras[p]
        local head, text = x[1], fs:GetText() or ""
        n = n + 1
        local ls = lines(text)
        local words = {}
        for _, l in ipairs(ls) do words[#words + 1] = plain(l, Spaced) end
        local where = ch.id .. "." .. p .. " '" .. head .. "'"
        if table.concat(words, " ") ~= head then bad[#bad + 1] = where .. ": sagt '" .. table.concat(words, "|") .. "'" end
        if #ls > 2 then bad[#bad + 1] = where .. ": " .. #ls .. " Zeilen" end
        -- the ladder in its order: plain only when letter-spaced 9 does not fit, cut only when plain 9 does not fit
        local GFx, small = ns.UI.JK.GF, ns.UI.JK.GF.HELP_LABEL.sizes[#ns.UI.JK.GF.HELP_LABEL.sizes]
        local function wideAt(str)
          local keep, ks = fs:GetText(), fs.fontSize
          ns.Look.Font(fs, fs.fontKind, small, fs.fontFlags)
          fs:SetText(str)
          local w = ns.Look.TextW(fs) or 0
          ns.Look.Font(fs, fs.fontKind, ks, fs.fontFlags)
          fs:SetText(keep)
          return w
        end
        if (fs.cut or (#ls == 1 and text == head and Spaced(head) ~= head)) and wideAt(Spaced(head)) <= GFx.HELP_LABEL_W - 1.5 then
          bad[#bad + 1] = where .. ": gesperrt haette gepasst"
        end
        if fs.cut and wideAt(head) <= GFx.HELP_LABEL_W - 1.5 then bad[#bad + 1] = where .. ": ungesperrt haette gepasst" end
        if fs.cut then
          steps.cut = steps.cut + 1
          if not (pair.tip:IsShown() and fs.full == head and fs.tipOwner == pair.tip) then
            bad[#bad + 1] = where .. ": geschnitten ohne Tooltip"
          end
        else
          if #ls == 2 then steps.spaced2 = steps.spaced2 + 1
          elseif text == head and Spaced(head) ~= head then steps.plain = steps.plain + 1
          else steps.spaced1 = steps.spaced1 + 1 end
          -- every line on its own fits the column
          local size = fs.fontSize
          for _, l in ipairs(ls) do
            fs:SetText(l)
            local w = ns.Look.TextW(fs) or 0
            if w > ns.UI.JK.GF.HELP_LABEL_W - 1.5 then bad[#bad + 1] = ("%s: Zeile '%s' %.1f breit"):format(where, l, w) end
          end
          fs:SetText(text)
          -- the client does not break further: as many lines as the text has
          local h = ns.Look.TextH(fs)
          if h > #ls * size * 1.1 + (#ls - 1) * 2 + 0.01 then bad[#bad + 1] = ("%s: %.1f hoch fuer %d Zeilen"):format(where, h, #ls) end
          if pair.tip:IsShown() then bad[#bad + 1] = where .. ": Tooltip ohne Schnitt" end
        end
      end
      W.click(Hp.toc)
    end
    check(lang .. "/" .. cover .. ": " .. n .. " Stichwoerter, keines bricht im Wort", #bad == 0 and n > 0, table.concat(bad, "; "))
    local e, msg = W.errors()
    check(lang .. "/" .. cover .. ": keine Fehler", e == 0, msg)
  end
end
-- the last step: a keyword too long even plain is cut by the client and has its tooltip (made up, deDE)
do
  local W = J.world("deDE", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
    news170 = true }, enemies = {}, deaths = {} } })
  local ns = W.ns
  ns.L.MANUAL_START_1_HEAD = "UNTERSCHRIFTENSAMMLUNGSVERFAHREN"
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  ns.UI.OpenPanel("help"); W.tick()
  local RP
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then RP = f end end
  local Hp = RP.help
  W.click(Hp.rows[1])
  local fs, pair = Hp.paras[1][1], Hp.paras[1]
  check("zu langes Stichwort: geschnitten, ungesperrt, mit Tooltip ueber dem Stichwort", fs.cut == true
    and fs:GetText() == "UNTERSCHRIFTENSAMMLUNGSVERFAHREN" and fs.full == fs:GetText() and pair.tip:IsShown()
    and fs.tipOwner == pair.tip, tostring(fs.cut) .. " " .. tostring(pair.tip:IsShown()))
  W.click(Hp.toc)
  W.click(Hp.rows[2])
  check("im naechsten Kapitel kein Tooltip mehr an dieser Stelle", not pair.tip:IsShown() and not fs.cut)
end
-- B11: the field texts of tests/sprachen/_limits.lua say what the code builds (widths, sizes, lines)
do
  local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true,
    news170 = true }, enemies = {}, deaths = {} } })
  local ns = W.ns
  local GF = ns.UI.JK.GF
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  ns.UI.OpenPanel("help"); W.tick()
  local RP
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then RP = f end end
  local Hp = RP.help
  local LIM = dofile(J.WT .. "/tests/sprachen/_limits.lua")
  local function has(k, ...)
    local f = LIM[k] and LIM[k].field or ""
    for _, part in ipairs({ ... }) do if not f:find(part, 1, true) then return false, k .. ": '" .. part .. "' fehlt in '" .. f .. "'" end end
    return true
  end
  local iw = math.floor(Hp.intro[1]:GetWidth() + 0.5)
  check("_limits MANUAL_INTRO_HEAD: Breite und Zeilen wie im Code", has("MANUAL_INTRO_HEAD", iw .. " px",
    GF.HELP_INTRO_HEAD.lines == 1 and "one line" or "two lines", "Friz " .. GF.HELP_INTRO_HEAD.sizes[1]))
  local rs = GF.HELP_ROW.sizes
  local bad = {}
  for _, c in ipairs(ns.UI.MANUAL_DATA.chapters) do
    local ok, why = has(c.title, "Morpheus " .. rs[1] .. ", then " .. rs[2], GF.HELP_TEXT_W .. " px",
      "Morpheus " .. table.concat(GF.FIT_NAME26.sizes, "/"))
    if not ok then bad[#bad + 1] = why end
    for _, p in ipairs(c.paras) do
      local ok2, why2 = has(p[1], GF.HELP_LABEL_W .. " px", "never broken inside a word", "letter-spaced " .. GF.HELP_LABEL.sizes[1])
      if not ok2 then bad[#bad + 1] = why2 end
    end
  end
  check("_limits: Titel und Stichwoerter beschrieben wie im Code", #bad == 0, bad[1])
end
print(("      Leiter: gesperrt einzeilig %d, zwei Zeilen an der Wortluecke %d, ungesperrt %d, geschnitten mit Tooltip %d")
  :format(steps.spaced1, steps.spaced2, steps.plain, steps.cut))
J.done("ma171 stichwort")
