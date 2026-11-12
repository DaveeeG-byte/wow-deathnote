-- DeathNote - Ranks.lua (1.3.0)
-- Repute ranks as data: thresholds of the sum of the four accounts, path ids, and rank names per theme,
-- language, path and tier: Ranks.NAMES[theme][lang][path][tier]. Pure data plus three small readers.
--
-- Paths: "r" infamy (greys and greens), "e" honour (same level), "j" hunt (higher levels, hit list, bounty),
-- "s" protection (kills of players who killed guildmates or friends). Tiers 1 and 2 are the same for every path.
-- Only German and English carry names; every other language (and a missing name) shows the line
-- "Rank 6 · Path: Honour" built from the language table (REPUTE_LINE, PATH_*). A theme without a name falls back
-- to the base theme "notebook". None of these names is a PvP rank title of the game (tests/test_ledger_ranks.lua
-- holds the list it is checked against).

local ADDON, ns = ...
local Ranks = {}
ns.Ranks = Ranks

-- Sum of the accounts needed for tier 1..10. The same for every path and every theme; one line to scale.
Ranks.THRESHOLDS = { 0, 10, 25, 50, 100, 175, 300, 500, 800, 1250 }
Ranks.MAX_TIER = #Ranks.THRESHOLDS
Ranks.PATHS = { "r", "e", "j", "s" }
Ranks.PATH_KEY = { r = "PATH_R", e = "PATH_E", j = "PATH_J", s = "PATH_S" }
Ranks.BASE_THEME = "notebook"

-- names of tiers 3..10 in order
local function T(...)
  local t = {}
  for i = 1, select("#", ...) do t[i + 2] = (select(i, ...)) end
  return t
end

-- Names of tiers 3..10 per path, then tiers 1 and 2 ("common"). Words from the concepts (repute concept 6.4,
-- decision 3: proposal A, infamy from proposal B; themes concept 11.3 for harbor and trade).
-- The block RANK-NAMES is data in two languages by design (repute concept 14: rank names are not keys of the
-- language table); tests/test_locale_waechter.lua skips this block only.
-- >>> RANK-NAMES
Ranks.NAMES = {
  notebook = {
    deDE = {
      common = { "Unbeschriebenes Blatt", "Aktenkundig" },
      r = T("Sandkastenschreck", "Taschengelddieb", "Friedhofsstammgast", "Stufenzähler",
        "Held der leichten Siege", "Albtraum der Stufe 20", "Größter unter Kleinen", "Unbesiegt (gegen Wehrlose)" ),
      e = T("Raufbold mit Manieren", "Fairer Gegner", "Ehrenhafter Kämpfer", "Duellant", "Streiter", "Ehrenmann",
        "Vorbild", "Legende der Arena ohne Arena" ),
      j = T("Fährtenleser", "Menschenjäger", "Kopfgeldjäger", "Großwildjäger", "Vollstrecker", "Scharfrichter",
        "Riesentöter", "Der, den man ruft" ),
      s = T("Aufpasser", "Leibwächter", "Beschützer", "Schildbruder", "Rächer der Gilde", "Edler Ritter",
        "Schutzpatron", "Der, hinter dem man steht" ),
    },
    enUS = {
      common = { "Blank Page", "On File" },
      r = T("Sandbox Menace", "Pocket Money Thief", "Graveyard Regular", "Level Counter", "Hero of Easy Wins",
        "Nightmare of Level 20", "Biggest Among the Small", "Undefeated (by the Defenceless)" ),
      e = T("Mannered Brawler", "Fair Opponent", "Honourable Fighter", "Duellist", "Stalwart", "Person of Honour",
        "Paragon", "Legend Without an Arena" ),
      j = T("Tracker", "Manhunter", "Bounty Hunter", "Big Game Hunter", "Enforcer", "Executioner", "Giant Slayer",
        "The One They Send For" ),
      s = T("Minder", "Bodyguard", "Protector", "Shield Brother", "Avenger of the Guild", "Noble Knight",
        "Patron Guardian", "The One You Stand Behind" ),
    },
  },
  -- Pirate theme (themes concept 11.3): ship ranks on the honour path
  harbor = {
    deDE = {
      common = { "Landratte", "Angeheuert" },
      r = T("Bilgenratte", "Strandräuber", "Beutelschneider", "Küstenplage", "Meuterer", "Schrecken der Jollen",
        "Geißel der Küste", "Fluch der Bucht" ),
      e = T("Schiffsjunge", "Leichtmatrose", "Matrose", "Bootsmann", "Steuermann", "Erster Maat", "Kapitän",
        "Admiral der Bucht" ),
      j = T("Ausguck", "Enterer", "Prisenjäger", "Kopfgeldjäger", "Kaperfahrer", "Harpunier", "Freibeuter",
        "Schrecken der Flaggschiffe" ),
      s = T("Wachgänger", "Deckswache", "Geleitschutz", "Kanonier", "Waffenmeister", "Quartiermeister",
        "Hafenmeister", "Schutzherr der Bucht" ),
    },
    enUS = {
      common = { "Landlubber", "Signed On" },
      r = T("Bilge Rat", "Wrecker", "Cutpurse", "Coast Pest", "Mutineer", "Terror of Dinghies",
        "Scourge of the Coast", "Curse of the Bay" ),
      e = T("Cabin Boy", "Deckhand", "Sailor", "Bosun", "Helmsman", "First Mate", "Captain", "Admiral of the Bay" ),
      j = T("Lookout", "Boarder", "Prize Hunter", "Bounty Hunter", "Privateer", "Harpooner", "Freebooter",
        "Terror of Flagships" ),
      s = T("Watchman", "Deck Guard", "Escort", "Gunner", "Master-at-Arms", "Quartermaster", "Harbour Master",
        "Warden of the Bay" ),
    },
  },
  -- Workshop theme (themes concept 11.3): apprentice to master on the honour path
  trade = {
    deDE = {
      common = { "Probezeit", "Eingearbeitet" },
      r = T("Pfuscher", "Schwarzarbeiter", "Abzocker", "Kostentreiber", "Mängelexemplar", "Schrecken der Lehrlinge",
        "Fall für die Innung", "Betriebsverbot" ),
      e = T("Lehrling", "Geselle", "Altgeselle", "Vorarbeiter", "Meister", "Obermeister", "Innungsmeister",
        "Meister aller Klassen" ),
      j = T("Außendienst", "Monteur", "Spezialist", "Störungsdienst", "Gutachter", "Sachverständiger",
        "Großkundenbetreuer", "Chefsache" ),
      s = T("Hausmeister", "Werkschutz", "Ersthelfer", "Sicherheitsbeauftragter", "Vertrauensmann", "Betriebsrat",
        "Arbeitsschutz", "Berufsgenossenschaft" ),
    },
    enUS = {
      common = { "On Probation", "Trained Up" },
      r = T("Botcher", "Moonlighter", "Rip-off Artist", "Cost Driver", "Factory Second", "Terror of Apprentices",
        "Case for the Board", "Barred from Trade" ),
      e = T("Apprentice", "Journeyman", "Senior Journeyman", "Foreman", "Master", "Head Master",
        "Master of the Trade", "Master of All Classes" ),
      j = T("Field Service", "Fitter", "Specialist", "Fault Service", "Assessor", "Expert Witness",
        "Key Account Manager", "Matter for the Boss" ),
      s = T("Caretaker", "Site Security", "First Aider", "Safety Officer", "Shop Steward", "Works Council",
        "Health and Safety", "The Insurer" ),
    },
  },
}
-- <<< RANK-NAMES

-- tiers 1 and 2 stand under every path too, so that NAMES[theme][lang][path][tier] answers for every tier
for _, langs in pairs(Ranks.NAMES) do
  for _, t in pairs(langs) do
    local c = t.common
    if type(c) == "table" then
      for _, p in ipairs(Ranks.PATHS) do
        if type(t[p]) == "table" then t[p][1], t[p][2] = c[1], c[2] end
      end
    end
  end
end

local function themeId()
  local T = ns.Theme
  local id = type(T) == "table" and T.id or nil
  return type(id) == "string" and id or Ranks.BASE_THEME
end

local function langCode()
  local Lc = ns.Locale
  local c = type(Lc) == "table" and Lc.code or nil
  return type(c) == "string" and c or "enUS"
end

-- The name of a tier on a path, or nil (other language, tier 3+ without a path, unknown tier).
-- theme and lang default to the active ones; a theme without that name falls back to the base theme.
function Ranks.Name(tier, path, theme, lang)
  if type(tier) ~= "number" or tier ~= tier then return nil end
  tier = math.floor(tier)
  if tier < 1 or tier > Ranks.MAX_TIER then return nil end
  theme, lang = theme or themeId(), lang or langCode()
  for pass = 1, 2 do
    local t = Ranks.NAMES[pass == 1 and theme or Ranks.BASE_THEME]
    t = type(t) == "table" and t[lang] or nil
    if type(t) == "table" then
      if tier <= 2 and type(t.common) == "table" and t.common[tier] then return t.common[tier] end
      local p = type(path) == "string" and t[path] or nil
      if type(p) == "table" and p[tier] then return p[tier] end
    end
    if theme == Ranks.BASE_THEME then break end
  end
  return nil
end

-- The word of a path in the active language ("Honour"), or the word for "no path yet".
function Ranks.PathWord(path)
  local L = ns.L
  if not L then return tostring(path) end
  local k = Ranks.PATH_KEY[path] or "PATH_NONE"
  return L[k]
end

-- What the book shows as the rank: the name, else "Rank 6 · Path: Honour" (REPUTE_LINE).
function Ranks.Title(tier, path, theme, lang)
  local name = Ranks.Name(tier, path, theme, lang)
  if name then return name end
  local L, F = ns.L, ns.F
  if not (L and F) then return tostring(tier) end
  return F(L.REPUTE_LINE, { tier = tier, path = Ranks.PathWord(path) })
end
