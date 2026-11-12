-- Rap sheet (1.3.0): rank names as data (Ranks.lua), the fallback line, and no PvP rank title of the game.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ns = M.Load()
local R = ns.Ranks

-- The 14 PvP rank titles per faction of the Classic honour system (German and English client), from memory of the
-- Classic clients: the mocks carry no PVP_RANK_* strings, and Forever's own rank track is unproven in game.
-- A rank name of the book must never be one of them, alone.
local GAME_TITLES = {
  -- Alliance, English / German
  "Private", "Corporal", "Sergeant", "Master Sergeant", "Sergeant Major", "Knight", "Knight-Lieutenant",
  "Knight-Captain", "Knight-Champion", "Lieutenant Commander", "Commander", "Marshal", "Field Marshal",
  "Grand Marshal", "Gefreiter", "Fußknecht", "Landsknecht", "Feldwebel", "Fähnrich", "Leutnant", "Hauptmann",
  "Kürassier", "Ritter der Allianz", "Feldkommandant", "Rittmeister", "Marschall", "Feldmarschall", "Großmarschall",
  -- Horde, English / German
  "Scout", "Grunt", "Senior Sergeant", "First Sergeant", "Stone Guard", "Blood Guard", "Legionnaire", "Centurion",
  "Champion", "Lieutenant General", "General", "Warlord", "High Warlord", "Späher", "Grunzer", "Waffenträger",
  "Schlachtrufer", "Rottenmeister", "Steingardist", "Blutgardist", "Zornbringer", "Klinge der Horde", "Feldherr",
  "Sturmreiter", "Kriegsherr", "Kriegsfürst", "Oberster Kriegsfürst",
  -- the bare word the concept forbids alone
  "Ritter",
}

test("Themes notebook, harbor, trade: German and English, tiers 1..10 on every path", function()
  for _, theme in ipairs({ "notebook", "harbor", "trade" }) do
    for _, lang in ipairs({ "deDE", "enUS" }) do
      local t = R.NAMES[theme][lang]
      ok(t, theme .. " " .. lang)
      for _, p in ipairs(R.PATHS) do
        for tier = 1, 10 do
          local n = t[p][tier]
          ok(type(n) == "string" and n ~= "" and not n:find("[|%c]"), ("%s %s %s %d"):format(theme, lang, p, tier))
          eq(R.Name(tier, p, theme, lang), n)
        end
        eq(t[p][11], nil)
      end
    end
  end
end)

test("Decision 3: proposal A, infamy from proposal B", function()
  eq(R.Name(5, "r", "notebook", "deDE"), "Friedhofsstammgast"); eq(R.Name(5, "r", "notebook", "enUS"), "Graveyard Regular")
  eq(R.Name(10, "r", "notebook", "deDE"), "Unbesiegt (gegen Wehrlose)")
  eq(R.Name(6, "e", "notebook", "deDE"), "Duellant"); eq(R.Name(5, "e", "notebook", "deDE"), "Ehrenhafter Kämpfer")
  eq(R.Name(6, "j", "notebook", "enUS"), "Big Game Hunter"); eq(R.Name(8, "s", "notebook", "deDE"), "Edler Ritter")
  eq(R.Name(1, "e", "notebook", "deDE"), "Unbeschriebenes Blatt"); eq(R.Name(2, nil, "notebook", "enUS"), "On File")
  eq(R.Name(9, "e", "harbor", "deDE"), "Kapitän"); eq(R.Name(1, nil, "trade", "enUS"), "On Probation")
  eq(R.Name(10, "e", "trade", "deDE"), "Meister aller Klassen")
end)

test("Thresholds 0 10 25 50 100 175 300 500 800 1250", function()
  eq(table.concat(R.THRESHOLDS, " "), "0 10 25 50 100 175 300 500 800 1250"); eq(R.MAX_TIER, 10)
end)

test("No rank name is a PvP rank title of the game", function()
  local bad = {}
  local title = {}
  for _, t in ipairs(GAME_TITLES) do title[t:lower()] = true end
  for theme, langs in pairs(R.NAMES) do
    for lang, t in pairs(langs) do
      for _, p in ipairs(R.PATHS) do
        for tier = 1, 10 do
          if title[t[p][tier]:lower()] then bad[#bad + 1] = theme .. "/" .. lang .. "/" .. p .. tier .. ": " .. t[p][tier] end
        end
      end
    end
  end
  eq(#bad, 0, table.concat(bad, ", "))
end)

test("Fallback: other languages, unknown theme, tier 3+ without a path", function()
  eq(R.Name(6, "e", "notebook", "frFR"), nil)
  eq(R.Title(6, "e", "notebook", "frFR"), "Rang 6 · Weg: Ehre", "the line in the active language (deDE here)")
  eq(R.Title(3, nil, "notebook", "frFR"), "Rang 3 · Weg: unbeschrieben")
  eq(R.Name(6, "e", "seas", "deDE"), "Duellant", "unknown theme: the base theme")
  eq(R.Name(3, nil, "notebook", "deDE"), nil); eq(R.Name(0, "e"), nil); eq(R.Name(11, "e"), nil); eq(R.Name(0 / 0, "e"), nil)
  eq(R.Title(6, "e"), "Duellant", "active theme and language")
  ns.Theme = { id = "harbor" }
  eq(R.Title(6, "e"), "Bootsmann"); ns.Theme = nil
  local en = M.Load({ lang = "enUS" })
  eq(en.Ranks.Title(6, "e", nil, "plPL"), "Rank 6 · Path: Honour")
  eq(en.Ranks.Title(4, "s"), "Bodyguard")
end)

M.done("ledger_ranks")
