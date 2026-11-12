-- DeathNote theme words "harbor" (Privateer's Ledger): the show words of the theme, one block per language.
-- Only show words (Locale.THEME_KEYS); every button and switch keeps its name. A word missing here keeps the
-- base word of the same language. Length limits: those of the base key (tests/sprachen/_limits.lua); stamps at
-- most two lines of 12 characters. No names of the game world, no guild names.
-- The other 19 languages fall back to their own base words until they are translated.
local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.RegisterWords) then return end

Locale.RegisterWords("harbor", "enUS", function(T)
  T.BOOK_TITLE          = "Privateer"
  T.TAB_WANTED          = "Marked Men"      -- not "Bounties": a tab of that name exists in another addon
  T.TAB_DEATHLOG        = "Ship's Log"
  T.TAB_GUILD           = "Crew"
  T.TAB_GUILD_FRIENDS   = "Crew & Friends"
  T.TAB_RECORD          = "Plunder Log"
  T.HEAD_RULES          = "Ship's Articles"
  T.HEAD_HELP           = "For Landlubbers"
  T.STAMP_NR1           = "HIGHEST BOUNTY"
  T.STAMP_GUILD_NR1     = "BANE OF THE CREW"
  T.STAMP_REVENGE       = "KEELHAULED"
  T.STAMP_PARDONED      = "SAFE PASSAGE"
  T.STAMP_HUNT          = "FAIR GAME"
  T.STAMP_QUITT         = "ALL SQUARE"
  T.STAMP_OVERPAID      = "RICH HAUL"
  T.POSTER_HUNTLIST     = "PRIZE LIST"
  T.BANNER_HUNT         = "PRIZE LIST"
  T.BANNER_NEW          = "NEW BOUNTY"
  T.BANNER_REVENGE      = "BROADSIDE"
  T.ALERT_SIGHTED       = "SAIL HO"
  T.ALERT_SIGHTED_NR1   = "HIGHEST BOUNTY IN SIGHT"
  T.ALERT_TITLE_GUILD   = "BANE OF THE CREW IN SIGHT"
  T.ALERT_TITLE_FRIENDS = "BANE OF FRIENDS IN SIGHT"
  T.ALERT_TITLE_HUNT    = "PRIZE IN SIGHT"
  T.BOUNTY_GOLD         = "{count} GUINEAS"   -- currency word at most 8 letters (DOUBLOONS ends in an ellipsis)
  T.BOUNTY_SILVER       = "{count} PENNIES"
  T.WELCOME             = "Signed on. The bay pays per head, the ledger keeps the list. Open it with /dn or the minimap button."
  T.EMPTY_WANTED_HEAD   = "No bounties yet."
  T.EMPTY_WANTED_SUB    = "Calm seas. Suspiciously calm."
  T.EMPTY_JOURNAL_HEAD  = "Never went overboard."
  T.EMPTY_JOURNAL_SUB   = "Seaworthy. Or a sailor's yarn."
end)

Locale.RegisterWords("harbor", "deDE", function(T)
  T.BOOK_TITLE          = "Kaperbuch"
  T.TAB_WANTED          = "Kopfgelder"
  T.TAB_DEATHLOG        = "Logbuch"
  T.TAB_GUILD           = "Mannschaft"
  T.TAB_GUILD_FRIENDS   = "Mannschaft & Co."
  T.TAB_RECORD          = "Beutebuch"
  T.HEAD_RULES          = "Bordregeln"
  T.HEAD_HELP           = "Für Landratten"
  T.STAMP_NR1           = "HÖCHSTES KOPFGELD"
  T.STAMP_GUILD_NR1     = "PLAGE DER MANNSCHAFT"
  T.STAMP_REVENGE       = "KIELGEHOLT"
  T.STAMP_PARDONED      = "FREIES GELEIT"
  T.STAMP_HUNT          = "ZUM ENTERN FREI"
  T.STAMP_QUITT         = "KLAR SCHIFF"
  T.STAMP_OVERPAID      = "FETTE BEUTE"
  T.POSTER_HUNTLIST     = "PRISENLISTE"
  T.BANNER_HUNT         = "PRISENLISTE"
  T.BANNER_NEW          = "NEUES KOPFGELD"
  T.BANNER_REVENGE      = "BREITSEITE"
  T.ALERT_SIGHTED       = "SEGEL IN SICHT"
  T.ALERT_SIGHTED_NR1   = "HÖCHSTES KOPFGELD IN SICHT"
  T.ALERT_TITLE_GUILD   = "PLAGE DER MANNSCHAFT IN SICHT"
  T.ALERT_TITLE_FRIENDS = "PLAGE DER FREUNDE IN SICHT"
  T.ALERT_TITLE_HUNT    = "PRISE IN SICHT"
  T.BOUNTY_GOLD         = "{count} DUBLONEN"
  T.BOUNTY_SILVER       = "{count} GROSCHEN"
  T.WELCOME             = "Angeheuert. Die Bucht zahlt pro Kopf, das Kaperbuch führt die Liste. Aufschlagen mit /dn oder am Minimap-Knopf."
  T.EMPTY_WANTED_HEAD   = "Noch kein Kopfgeld ausgesetzt."
  T.EMPTY_WANTED_SUB    = "Ruhige See. Verdächtig ruhig."
  T.EMPTY_JOURNAL_HEAD  = "Noch nie über Bord gegangen."
  T.EMPTY_JOURNAL_SUB   = "Seefest. Oder Seemannsgarn."
end)
