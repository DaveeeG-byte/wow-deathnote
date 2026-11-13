-- 1.3.1 (hunt N7): five tabs for everybody. With 150 and 999 entries the tab "Wanted" shows a three-digit number;
-- no tab text may be cut in any language and cover (the fitted size counts, an ellipsis with tooltip does not pass).
-- Call from the project root: luajit tests/ui/tabs_five.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "tabs_five")
local LANGS = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
for _, theme in ipairs({ "notebook", "harbor", "trade" }) do
  for _, lang in ipairs(LANGS) do
    for _, n in ipairs({ 150, 999 }) do
      local ns = K.world(lang, { before = function()
        _G.DeathNoteDB = { version = 4, settings = { firstRun = "done", lang = lang, ui = { theme = theme } },
          enemies = {}, deaths = {} }
      end })
      local BM, G = K.BM, K.G
      for i = 1, n do ns.Store.AddManual("N" .. i, "Beispiel") end
      K.tick(30); K.settle()
      ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
      local F = rawget(G, "DeathNoteFrame")
      local shown, worst, what, count = 0, -999, nil, false
      for _, tb in ipairs(F and F.tabs or {}) do
        if tb:IsVisible() then
          shown = shown + 1
          local over = (BM.Unbounded(tb.text) or 0) - (tb.text._wset and tb.text._w or tb._w or 0)
          if over > worst then worst, what = over, tb.text._text end
          if (tb.text._text or ""):find(tostring(n), 1, true) then count = true end
        end
      end
      local id = ("%s %s n=%d"):format(theme, lang, n)
      K.check(id .. ": five tabs", shown == 5, shown)
      K.check(id .. ": the count is shown", count)
      K.check(id .. ": every tab text fits its field", worst <= 0.5, ("%.1f px over: %s"):format(worst, tostring(what)))
    end
  end
end
K.done("five tabs with a three-digit count, 3 covers x 21 languages")
