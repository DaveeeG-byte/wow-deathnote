-- DeathNote: Nederlands (nlNL). No official Dutch client: words as Dutch players use them (guild, level, dungeons).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.nlNL), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Glossary: boek, guildboek, vriendenboek, dader, guildgenoot, vriend, Gezocht, Onopgelost, Sterfregister, Huisregels,
-- affiche, stempel, premie, notitie, waarneming, schrappen, begenadigen, wraak, verdachte, dodenlijst, jacht openen,
-- oproep, jacht afblazen, geveld, Boek bewaren, Boek inlezen.
--
-- TOC-Notes: Dodenlijst voor open-world-PvP: onthoudt wie je heeft gedood en waarschuwt je als die in de buurt is.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("nlNL")) then return end

Locale.Register("nlNL", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Gezocht"       -- [max 16]
L.TAB_UNSOLVED = "Onopgelost"    -- [max 16]
L.TAB_DEATHLOG = "Sterfregister" -- [max 16]
L.TAB_GUILD    = "Guild"         -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Huisregels"          -- [max 24]
L.HEAD_HELP  = "Gebruiksaanwijzing"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Boek"           -- [max 14]
L.SHEET_ALERT = "Alarm"          -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "STAATSVIJAND NR. 1"   -- [max 24]
L.STAMP_REVENGE  = "WRAAK GENOMEN"        -- [max 16]
L.STAMP_PARDONED = "BEGENADIGD"           -- [max 16]
L.STAMP_SUSPECT  = "VERDACHT"             -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "STAATSVIJAND NR. 1 GESPOT"   -- [max 30]
L.ALERT_SIGHTED         = "STAATSVIJAND GESPOT"         -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "VERDACHTE GESPOT"            -- [max 30]
L.ALERT_TITLE_GUILD     = "GUILDVIJAND GESPOT"          -- [max 30]
L.ALERT_TITLE_FRIENDS   = "DADER VAN VRIENDEN GESPOT"   -- [max 30]
L.ALERT_TITLE_HUNT      = "DOELWIT OP DE DODENLIJST"    -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "staat onder verdenking"
L.ALERT_LINE_KILLED         = "heeft je {times} gedood"
L.ALERT_LINE_KILLED_ASSISTED = "heeft je {times} gedood, {assists} meegeholpen"
L.ALERT_LINE_ASSISTED       = "hielp {times} mee aan je dood"
L.ALERT_LINE_MANUAL         = "staat met de hand in het boek"
L.ALERT_LINE_LAST    = "{text}, laatst {time}"
L.ALERT_LINE_IN      = "{text} in {zone}"
L.ALERT_LINE_REVENGE = "{text}. Wraak: {times}"
L.ALERT_HINT_CLOSE  = "Rechtsklik: sluiten"                         -- [max 44]
L.ALERT_HINT_COMBAT = "Als doelwit pas na het gevecht"              -- [max 44]
L.ALERT_HINT_TARGET = "Klik: als doelwit  ·  Rechtsklik: sluiten"   -- [max 44]
L.ALERT_MORE = "+{count} meer"           -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "staat in het guildboek"
L.GUILD_LINE_IN_FRIENDS = "staat in het vriendenboek"
L.GUILD_LINE_LISTED_BY  = "staat in het boek van {names}"
L.GUILD_LINE_KILLED_GUILD   = "heeft guildgenoten {kills}× gedood"
L.GUILD_LINE_KILLED_FRIENDS = "heeft vrienden {kills}× gedood"
L.GUILD_LINE_KILLED_BOTH    = "heeft guildgenoten en vrienden {kills}× gedood"
L.GUILD_LINE_LAST = "{text}, laatst {name}"
L.HUNT_LINE_BY       = "op de dodenlijst gezet door {names}"
L.HUNT_LINE_RELEASED = "op de dodenlijst"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "onder verdenking"
L.TALLY_MANUAL   = "met de hand toegevoegd"
L.TALLY_NONE     = "nog geen daad"
L.TALLY_KILLED   = "{times} gedood"
L.TALLY_ASSISTED = "{times} meegeholpen"
L.PLACE_UNKNOWN  = "onbekende plek"
L.GKILLS_CAP     = "minstens {count}"
L.NAMELIST_MORE  = "{names} en nog {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d-%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d-%m-%Y %H:%M"
L.TIME_FMT_DAY       = "%d-%m"
L.TIME_FMT_DAY_YEAR  = "%d-%m-%y"
L.TIME_NEVER   = "nooit"
L.TIME_JUST    = "zojuist"
L.TIME_MINUTES = "{count} min terug"      -- [max 14]
L.TIME_HOURS   = "{count} uur terug"      -- [max 14]
L.TIME_DAYS    = "{count} {count|dag|dagen} terug"  -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}z"
L.MONEY_COPPER = "{count}k"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "{count} {count|guildgenoot|guildgenoten} met DeathNote gehoord."
L.HEALTH_NOGUILD = "Je zit in geen guild, er wordt niets gedeeld."
L.HEALTH_OFF     = "Delen staat uit."
L.HEALTH_SHORT_NOGUILD = "Geen guild"     -- [max 18]
L.HEALTH_SHORT_OFF     = "Delen uit"      -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Geblokkeerd"    -- [max 18]
L.HEALTH_SHORT_FAILING = "Geweigerd"      -- [max 18]
L.HEALTH_SHORT_HOLD    = "Wacht"          -- [max 18]
L.HEALTH_SHORT_ASKED   = "Aangevraagd"       -- [max 18]
L.HEALTH_SHORT_FAIL    = "Werkt niet"     -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Geen geluid"       -- [max 16]
L.SOUND_RAIDWARNING = "Raidwaarschuwing"  -- [max 16]
L.SOUND_BELL        = "Bel"               -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Hartslag"          -- [max 16]
L.SOUND_FEATHER     = "Ganzenveer"        -- [max 16]
L.SOUND_SIREN       = "Sirene"            -- [max 16]
L.CHANNEL_MASTER    = "Hoofdvolume"       -- [max 16]
L.CHANNEL_SFX       = "Effecten"          -- [max 16]
L.CHANNEL_DIALOG    = "Dialoog"           -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} staat nu in het boek."
L.CHAT_REMOVED   = "{name} is uit het boek geschrapt."
L.CHAT_SYNC_WAIT = "Net gesynchroniseerd. Probeer het over {seconds} s opnieuw."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Nog geen namen."
L.EMPTY_WANTED_SUB  = "Ga eens naar buiten."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  boek open/dicht"
L.HELP_ADD      = "/dn add <Naam [Achternaam]>  een dader met de hand in het boek zetten"
L.HELP_DEL      = "/dn del <Naam [Achternaam]>  een dader uit het boek schrappen"
L.HELP_QUIET    = "/dn quiet  alarm uit/aan"
L.HELP_TEST     = "/dn test  testalarm tonen"
L.HELP_GUILD    = "/dn guild  guildboek: status en welke guildgenoten DeathNote hebben"
L.HELP_FRIENDS  = "/dn friends  vriendenboek: status en welke vrienden DeathNote hebben"
L.HELP_SYNC     = "/dn sync  guildboek en vriendenboek nu synchroniseren"
L.HELP_HUNT     = "/dn hunt <Naam [Achternaam]>  op de dodenlijst zetten (zonder naam: dodenlijst tonen)"
L.HELP_CALLOFF  = "/dn calloff <Naam [Achternaam]>  je eigen jacht afblazen"
L.HELP_LANG     = "/dn lang <code>  taal van het boek (enUS, deDE, nlNL ...), na /reload"
L.HELP_THEME = "/dn theme <naam>  kaft van het boek, na /reload"
L.HELP_PROBE    = "/dn probe  probleemoplossing: wat het spel het boek vertelt"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  probleemoplossing, ook de combatlog testen"
L.HELP_DEBUG    = "/dn debug  probleemoplossing: elke dood uitgebreid loggen (aan/uit)"
L.HELP_HELP     = "/dn help  deze hulp"
L.HELP_SILENT_ZONES = "In dungeons, battlegrounds en arena's houdt het boek vanzelf zijn mond."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "aan"
L.WORD_OFF = "uit"
L.CHAT_WHO_ADD  = "Wie dan? /dn add <Naam>"
L.CHAT_WHO_DEL  = "Wie dan? /dn del <Naam>"
L.CHAT_WHO_CALLOFF = "Wie dan? /dn calloff <Naam>"
L.CHAT_BAD_NAME = "Ongeldige naam."
L.CHAT_NOT_IN_BOOK = "Niet in het boek: {name}"
L.CHAT_ALARM_ON  = "Alarm aan."
L.CHAT_ALARM_OFF = "Alarm uit."
L.CHAT_DEBUG = "Foutopsporingslog {state}."
L.CHAT_UNKNOWN_CMD = "Onbekend commando. Hulp: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Het guildboek is niet geladen."
L.CHAT_NO_GUILD = "Je zit in geen guild (of het spel weet het nog niet)."
L.CHAT_GUILD_STATE = "Guild {guild}: delen {share}, ontvangen {receive}."
L.CHAT_GUILD_BOOK = "Guildboek: {enemies} daders ({listed} alleen met de hand), {deeds} {deeds|daad|daden}, {foreign} daarvan doodden andere guildgenoten. Handmatige namen delen: {manual}."
L.CHAT_STATE_OK   = "Status: {text}"
L.CHAT_STATE_WARN = "Let op: {text}"
L.CHAT_NO_MATES   = "Nog geen guildgenoot met DeathNote gehoord."
L.CHAT_HAVE_DN      = "Met DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Met DeathNote: {names} en nog {count}"
L.CHAT_SYNC_ASKED = "Sync aangevraagd. Antwoorden komen binnen een paar seconden."
L.CHAT_SYNC_FAIL  = "Sync werkt niet: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "geen guild, of delen staat uit."
L.CHAT_FRIENDS_NOT_LOADED = "Het vriendenboek is niet geladen."
L.CHAT_FRIENDS_STATE = "Vrienden: delen {share}, {online} van {total} online."
L.CHAT_FRIENDS_BOOK  = "Vriendenboek: {enemies} daders ({listed} alleen met de hand), {deeds} {deeds|daad|daden}."
L.CHAT_NO_FRIENDS    = "Nog geen vriend met DeathNote gehoord."
L.CHAT_HUNT_NOT_LOADED = "De dodenlijst is niet geladen."
L.CHAT_HUNT_UNKNOWN = "Onbekend: {name}. Gebruik ook de achternaam, zoals de naam in het spel staat."
L.CHAT_HUNT_CAP     = "Kan niet op de dodenlijst: hoogstens {own} eigen oproepen en {targets} doelwitten per lijst."
L.CHAT_HUNT_NOWHERE = "Kan nu niet op de dodenlijst: geen guild, en delen met vrienden staat uit."
L.CHAT_HUNT_BOTH    = "{name} staat op de dodenlijst, voor guild en vrienden."
L.CHAT_HUNT_GUILD   = "{name} staat op de dodenlijst, voor de guild."
L.CHAT_HUNT_FRIENDS = "{name} staat op de dodenlijst, voor je vrienden."
L.CHAT_CALLED_OFF   = "Jacht op {name} afgeblazen."
L.CHAT_NO_OWN_CALL  = "Je hebt geen eigen oproep voor {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Taal nu: {lang}. Wijzigen: /dn lang <code>"
L.CHAT_LANG_LIST    = "Codes: {codes}"
L.CHAT_LANG_BAD     = "Onbekende taal: {code}"
L.CHAT_LANG_SET     = "Taal: {lang}."
L.CHAT_LANG_RELOAD  = "Taal: {lang}. Werkt na /reload."
L.CHAT_THEME_CURRENT = "Kaft nu: {theme}. Wijzigen: /dn theme <naam>"
L.CHAT_THEME_LIST = "Kaften: {themes}"
L.CHAT_THEME_BAD = "Onbekende kaft: {name}"
L.CHAT_THEME_SET = "Kaft: {theme}."
L.CHAT_THEME_RELOAD = "Kaft: {theme}. Werkt na /reload."
L.THEME_NOTEBOOK = "Het zwarte boek"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Het boek ligt klaar. Wie je in de open wereld doodt, staat er daarna in. Open het met /dn of de minimapknop."
L.WELCOME_PLATES = "Naamplaatjes van vijanden staan uit. Zonder die ziet het alarm alleen je doelwit."
L.WELCOME_SHARE = "Guild en vrienden die DeathNote hebben, lezen mee. Notities en verdenkingen blijven bij jou."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "IN HET BOEK:"
L.TIP_HUNT      = "DODENLIJST:"
L.TIP_GUILDBOOK = "GUILDBOEK:"
L.TIP_PARDONED  = "begenadigd"
L.TIP_RANK      = "rang {rank}"
L.TIP_REVENGE   = "wraak {times}"
L.TIP_LISTED_BY = "in het boek van {names}"
L.TIP_NOTE      = "Notitie: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Klik: openen · Rechtsklik: weg"
L.BANNER_NEW          = "NIEUWE NAAM"          -- [max 24]
L.BANNER_NEW_LINE     = "staat nu in het boek"
L.BANNER_AGAIN        = "ALWEER"               -- [max 24]
L.BANNER_AGAIN_LINE   = "heeft je weer gedood, nu al {count} keer"
L.BANNER_SUSPECT      = "VERDACHT"             -- [max 24]
L.BANNER_SUSPECT_LINE = "staat onder verdenking, zoek het uit in het boek"
L.BANNER_UNCLEAR      = "DADER ONDUIDELIJK"    -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|kandidaat|kandidaten}"
L.BANNER_UNCLEAR_LINE = "Klik: kies de dader onder Onopgelost"
L.BANNER_REVENGE      = "VERGELDING"           -- [max 24]
L.BANNER_REVENGE_LINE = "Wraak genomen ({count}×)"
L.BANNER_GUILD        = "GUILD"                -- [max 24]
L.BANNER_FRIENDS      = "VRIENDEN"             -- [max 24]
L.BANNER_KILLED_BY    = "is gedood door {name}"
L.BANNER_HUNT         = "DODENLIJST"           -- [max 24]
L.BANNER_BAGGED       = "geveld door {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Delen staat uit (Huisregels, blad Guild)."
L.SYNC_FRIENDS_OFF = "Delen met vrienden staat uit."
L.SYNC_NOBODY      = "Geen guild en geen vrienden om mee te delen."
L.SYNC_SHORT_NOBODY = "Niets gedeeld"         -- [max 18]
L.SYNC_PREFIX      = "Het spel staat geen ontvangst toe. Opnieuw inloggen helpt."
L.SYNC_SHORT_PREFIX = "Geen ontvangst"        -- [max 18]
L.SYNC_BLOCKED     = "De realm blokkeert verzenden. Geef het door met Boek bewaren."
L.SYNC_SHORT_BLOCKED = "Verzenden geblokkeerd" -- [max 22]
L.SYNC_FAILING     = "Verzenden lukt nu niet, we proberen het opnieuw."
L.SYNC_SHORT_FAILING = "Verzenden hapert"     -- [max 18]
L.SYNC_HOLD        = "Verzenden wacht {wait}."
L.SYNC_HOLD_INSTANCE = "tot je de instance verlaat"
L.SYNC_HOLD_COMBAT   = "tot je uit het gevecht bent"
L.SYNC_HOLD_LOCKDOWN = "tot de chat weer vrij is"
L.SYNC_HOLD_AGAIN    = "tot het weer werkt"
L.SYNC_HOLD_SHORT_INSTANCE = "Wacht: instance"    -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Wacht: gevecht"     -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Wacht: chat"        -- [max 18]
L.SYNC_QUIET       = "Verzonden, maar nog geen guildgenoot met DeathNote gehoord."
L.SYNC_READY       = "Klaar. Nog geen guildgenoot met DeathNote gehoord."
L.SYNC_RUNNING     = "Actief: {count} {count|guildgenoot|guildgenoten} met DeathNote."
L.SYNC_RUNNING_ALL = "Actief: {count} met DeathNote bij guild en vrienden."
L.FRIENDS_OFF      = "Delen met vrienden staat uit (Huisregels, blad Guild)."
L.FRIENDS_BLOCKED  = "De realm blokkeert whispers. Vrienden krijgen niets."
L.FRIENDS_SHORT_BLOCKED = "Whispers geblokkeerd" -- [max 22]
L.FRIENDS_FAILING  = "Whispers lukken nu niet, we proberen het opnieuw."
L.FRIENDS_SHORT_FAILING = "Whispers haperen"     -- [max 18]
L.FRIENDS_NONE_LISTED = "Geen vrienden op de vriendenlijst."
L.FRIENDS_NONE_ONLINE = "Er is nu geen vriend online."
L.FRIENDS_SHORT_NONE_ONLINE = "Geen vriend online" -- [max 18]
L.FRIENDS_QUIET    = "Gevraagd, maar nog geen vriend met DeathNote gehoord."
L.FRIENDS_READY    = "Klaar. Nog geen vriend met DeathNote gehoord."
L.FRIENDS_HOLD     = "Verzenden naar vrienden wacht tot het weer werkt."
L.FRIENDS_RUNNING  = "Actief: {count} {count|vriend|vrienden} met DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Overgenomen uit het guildboek (heeft guildgenoten {kills}× gedood)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Database niet geladen."
L.IMPORT_NO_TEXT    = "Geen tekst."
L.IMPORT_NO_HEADER  = "De eerste regel ontbreekt (die begint met {header}). Kopieer de hele tekst."
L.IMPORT_NOT_EXPORT = "Geen DeathNote-export (kopregel ontbreekt of verkeerde versie)."
L.IMPORT_TOO_LONG   = "Te veel regels (hoogstens {count})."
L.IMPORT_BAD_KEY    = "Regel {line}: ongeldige sleutel."
L.IMPORT_BAD_TIME   = "Regel {line}: ongeldige tijd."
L.IMPORT_BROKEN     = "Regel {line} is onvolledig of kapot (tekst afgekapt?). Niets ingelezen."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "ja"
L.WORD_NO  = "nee"
L.PROBE_HEAD = "Sonde: {apis}/{apisAll} interfaces aanwezig, {events}/{eventsAll} events registreerbaar."
L.PROBE_MISSING = "Ontbreekt: {list}"
L.PROBE_NOT_REGISTERABLE = "Niet registreerbaar: {list}"
L.PROBE_SOURCES = "Recap nu: {recap} · Meter: {meter} · Combatlog: {clog}"
L.PROBE_READABLE = "leesbaar"
L.PROBE_DEAD = "dood"
L.PROBE_PLATES = "Naamplaatjes van vijanden: {plates} · Open wereld: {open}"
L.PROBE_PLATES_OFF = "UIT (alleen doelwit en muis vinden spelers)"
L.PROBE_TARGET = "Doelwit: naam={name} GUID={guid} klasse={class} vijandig={enemy} richt op mij={me}"
L.PROBE_GUILD = "Guild: prefix {prefix} · verzenden {send} · laatste returnwaarde {result} · verzonden {sent}, ontvangen {received}, verworpen {dropped}"
L.PROBE_REGISTERED = "geregistreerd"
L.PROBE_NOT_REGISTERED = "NIET geregistreerd ({result})"
L.PROBE_POSSIBLE = "mogelijk"
L.PROBE_ABSENT = "ontbreekt"
L.PROBE_WAITS = " · wacht: {why}"
L.PROBE_LISTED = "Handmatig (M): verzonden {sent}, ontvangen {received}, verworpen {dropped} · geschrapt (X): verzonden {usent}, ontvangen {ureceived}, verworpen {udropped}"
L.PROBE_GUILDBOOK = "Guildboek: {text}"
L.PROBE_SAVED = "Opgeslagen in DeathNoteDB.probe (na /reload in het bestand)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Nieuwste"  -- [max 14]
L.SORT_NAME = "Naam"  -- [max 14]
L.SORT_SEEN = "Gezien"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Wie je in de open wereld doodt, komt hier terecht. Helemaal vanzelf."
L.EMPTY_OPEN_HEAD = "Niets onopgelost."
L.EMPTY_JOURNAL_HEAD = "Nog nooit doodgegaan."
L.EMPTY_JOURNAL_SUB = "Respect. Of gelogen."
L.EMPTY_NOGUILD_HEAD = "Geen guild."
L.EMPTY_NOGUILD_SUB = "Alleen doodgaan kan ook."
L.EMPTY_GUILDOFF_HEAD = "Het guildboek is dicht."
L.EMPTY_GUILDOFF_SUB = "Delen staat uit. De Huisregels weten waar."
L.EMPTY_GUILDNIL_HEAD = "Nog niets van de guild gehoord."
L.EMPTY_GUILDNIL_SUB = "Je boek gaat de deur uit zodra een guildgenoot DeathNote heeft."
L.EMPTY_GUILDQUIET_HEAD = "Nog niets in het guildboek."
L.EMPTY_GUILDQUIET_SUB = "Je guildgenoten hadden tot nu toe rust."
L.EMPTY_FRIENDSOFF_HEAD = "Het vriendenboek is dicht."
L.EMPTY_FRIENDSOFF_SUB = "Delen met vrienden staat uit. De Huisregels weten waar."
L.EMPTY_FRIENDSNIL_HEAD = "Nog geen vriend met DeathNote gehoord."
L.EMPTY_FRIENDSNIL_SUB = "Je boek gaat de deur uit zodra een vriend DeathNote heeft."
L.EMPTY_FRIENDSQUIET_HEAD = "Nog niets van je vrienden."
L.EMPTY_FRIENDSQUIET_SUB = "Je vrienden hadden tot nu toe rust."
L.EMPTY_NOBODY_HEAD = "Geen guild, geen vrienden."
L.EMPTY_NOBODY_SUB = "Alleen doodgaan kan ook."
L.EMPTY_NOBODY_HINT = "Zodra guildgenoten of vrienden van je vriendenlijst DeathNote hebben, laat deze pagina zien wat hun overkomt."
L.EMPTY_SHAREDNIL_HEAD = "Nog niemand met DeathNote gehoord."
L.EMPTY_SHAREDNIL_SUB = "Je boek gaat de deur uit zodra guildgenoten of vrienden DeathNote hebben."
L.EMPTY_SHAREDQUIET_HEAD = "Hier staat nog niets."
L.EMPTY_SHAREDQUIET_SUB = "Guild en vrienden hadden tot nu toe rust."
L.EMPTY_HUNT_HEAD = "De dodenlijst is leeg."
L.EMPTY_HUNT_SUB = "Op de affiche: Jacht openen."
L.EMPTY_HUNT_HINT = "Of in de chat: /dn hunt Naam Achternaam. Iedereen in je guild en je vrienden zien het."
L.EMPTY_SEARCH_HEAD = "Geen treffer."
L.EMPTY_SEARCH_SUB = "Enter zet de naam in het boek."
L.EMPTY_SEARCHRO_HEAD = "Geen treffer."
L.EMPTY_SEARCHRO_SUB = "Soms helpt een andere spelling."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "HET BOEK"  -- [max 12]
L.MANUAL_BOOK = "Wie je in de open wereld doodt, wordt vanzelf ingeschreven. Een klik op de melding na je dood slaat de pagina van de dader open."
L.MANUAL_WANTED_HEAD = "GEZOCHT"  -- [max 12]
L.MANUAL_WANTED = "Je daders, de ergste eerst. Een klik toont de affiche met daden en notitie. Begenadigden staan doorgestreept onderaan."
L.MANUAL_UNSOLVED_HEAD = "ONOPGELOST"  -- [max 13]
L.MANUAL_UNSOLVED = "Was niet duidelijk wie het deed, dan wacht de zaak hier. Een klik op een naam legt de dader vast."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Duikt een dader op als naamplaatje, doelwit of onder de muis, dan slaat het boek alarm. Een klik maakt de dader je doelwit, in een gevecht pas daarna."
L.MANUAL_ADD_HEAD = "TOEVOEGEN"  -- [max 12]
L.MANUAL_ADD = "Typ een naam in het zoekveld, Enter. Rechtsklik op een regel: wraak noteren, begenadigen, schrappen."
L.MANUAL_GUILD_HEAD = "GUILD"  -- [max 12]
L.MANUAL_GUILD = "Guildgenoten en vrienden met DeathNote zien je bevestigde sterfgevallen en handmatige namen. Affiche of /dn hunt Naam: op de dodenlijst zetten. Klik op de premie: loof je eigen uit, een belofte die je onderling regelt."
L.MANUAL_SHARE_HEAD = "DOORGEVEN"  -- [max 12]
L.MANUAL_SHARE = "Huisregels, Boek bewaren: een tekst om te kopiëren, voor iedereen zonder DeathNote."
L.MANUAL_QUIET_HEAD = "STILTE"  -- [max 12]
L.MANUAL_QUIET = "In dungeons en battlegrounds zwijgt het alarm. Anders: middelklik op de minimapknop of /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "{name} echt uit het boek schrappen?\nAlle daden en de notitie gaan verloren."
L.CONFIRM_DELETE_OK = "Schrappen"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Het guildboek op deze computer leegmaken?\nDe dodenlijst ervan gaat mee, je eigen oproepen blijven.\nJe eigen boek blijft zoals het is."
L.CONFIRM_GUILD_CLEAR_OK = "Leegmaken"  -- [max 14]
L.CONFIRM_CANCEL = "Annuleren"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GOUD"  -- [max 14]
L.BOUNTY_SILVER = "{count} ZILVER"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Bevestigen"  -- [max 19]
L.ACT_DISMISS = "Verwerpen"  -- [max 19]
L.ACT_HUNT_AGAIN = "Weer jagen"  -- [max 19]
L.ACT_REVENGE = "Wraak noteren"  -- [max 19]
L.ACT_PARDON = "Begenadigen"  -- [max 19]
L.ACT_STRIKE = "Schrappen"  -- [max 19]
L.ACT_OPEN_OWN = "Open in boek"  -- [max 19]
L.ACT_ADOPT = "Naar mijn boek"  -- [max 19]
L.ACT_CALLOFF = "Jacht afblazen"  -- [max 19]
L.ACT_RELEASE = "Jacht openen"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "gezien {time}"
L.ROW_NOT_SEEN = "nog niet gespot"
L.ROW_PARDONED = "begenadigd"
L.ROW_SUSPECT = "Verdacht"
L.MARK_REVENGE = "WRAAK {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Dader onduidelijk"
L.MARK_CANDIDATES = "{count} {count|KANDIDAAT|KANDIDATEN}"  -- [max 16]
L.MARK_SUSPECT = "VERDACHT"  -- [max 16]
L.ROW_NO_PLAYER = "Geen speler"
L.ROW_UNCLEAR = "Onduidelijk hoe"
L.MARK_NOT_COUNTED = "TELT NIET"  -- [max 16]
L.ROW_LISTED_BY = "toegevoegd door {names}"
L.ROW_GKILLED = "{kills}× gedood"
L.ROW_VICTIMS = "{count} {count|slachtoffer|slachtoffers}"
L.ROW_LAST = "laatst {text}"
L.MARK_IN_BOOK = "IN BOEK"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|dader|daders}"  -- [max 14]
L.MEMBER_DEATHS = "{count}× dood"  -- [max 12]
L.MEMBER_LISTED = "{count} handmatig"  -- [max 14]
L.MEMBER_ME = "dit zien de anderen van jou"
L.MEMBER_NOTHING = "nog niets gedeeld"
L.MEMBER_LAST_DIED = "laatst gestorven {time}"
L.MARK_YOU = "jij"  -- [max 16]
L.MARK_FRIEND = "VRIEND"  -- [max 16]
L.MARK_BOTH = "GUILDGENOOT, VRIEND"  -- [max 20]
L.MARK_TAKEN_DOWN = "GEVELD {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DOOD OF LEVEND"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "DADEN"  -- [max 14]
L.POSTER_NOTE = "NOTITIE"  -- [max 8]
L.POSTER_BOUNTY = "PREMIE"  -- [max 12]
L.ROLE_ASSIST = "meegeholpen"  -- [max 14]
L.ROLE_SUSPECT = "verdacht"  -- [max 14]
L.POSTER_LEVEL = "Level {level}"
L.POSTER_GUILD = "Guild: {guild}"
L.POSTER_LAST_SEEN = "Laatst gezien {time}"
L.POSTER_NOT_SEEN = "Nog niet gespot"
L.POSTER_ONLY_SUSPECT = "Alleen verdacht, geen bewezen daad."
L.POSTER_NO_DEEDS = "Geen daden genoteerd."
L.TIP_LISTED_AT = "Toegevoegd {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Doodsoorzaak: {spell}"
L.TIP_VICTIM = "Slachtoffer: {name}"
L.TIP_VICTIM_LEVEL = "Slachtoffer: {name} (level {level})"
L.TIP_KILLER_LEVEL = "Level van de dader: {level}"
L.TIP_ASSISTS = "Meegeholpen: {names}"
L.TIP_ROLE_ASSIST = "Hielp mee, gaf niet de genadeklap."
L.TIP_ROLE_SUSPECT = "Alleen verdacht, niet bewezen."
L.MORE_LINE = "… en nog {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GUILDBOEK"  -- [max 24]
L.POSTER_IN_BOOK_OF = "In het boek van: {names}"
L.POSTER_SEEN = "Gezien {time}"
L.POSTER_SEEN_BY = "Gezien {time} door {name}"
L.TIP_IN_BOOK_OF = "In het boek van"
L.POSTER_REMARK = "OPMERKING"  -- [max 12]
L.POSTER_BY_HAND = "MET DE HAND TOEGEVOEGD"  -- [max 22]
L.POSTER_VICTIMS = "SLACHTOFFERS"  -- [max 12]
L.POSTER_LISTED = "TOEGEVOEGD"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Met de hand toegevoegd."
L.POSTER_NO_DEEDS_SENT = "Geen daden doorgegeven."
L.POSTER_NONE_KNOWN = "geen bekend"
L.POSTER_NO_NAMES = "geen namen doorgegeven"
L.TIP_VICTIMS = "Slachtoffers"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Jacht geopend {time}"
L.HUNT_REASON = "Reden: {reason}"
L.POSTER_HUNTLIST = "DODENLIJST"  -- [max 24]
L.POSTER_RELEASED_N = "{times} op de dodenlijst gezet"
L.POSTER_RELEASED_BY = "Jacht geopend door {names}"
L.POSTER_TAKEN_DOWN = "GEVELD"  -- [max 12]
L.POSTER_NOT_YET = "NOG NIET"  -- [max 18]
L.POSTER_CALLS = "OPROEPEN"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Niemand meer."
L.POSTER_LAST = "LAATST"  -- [max 13]
L.POSTER_TAKEN_BY = "geveld door {name}, {time}"
L.POSTER_TAKEN_NOBODY = "nog door niemand geveld"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Sterfgeval"  -- [max 20]
L.CASE_ASSISTS = "MEEGEHOLPEN"  -- [max 24]
L.CASE_PICK = "DADER VASTLEGGEN"  -- [max 24]
L.CASE_NOT_COUNTED = "Telt niet (instance, battleground of duel)"
L.CASE_KILLER = "DADER"  -- [max 24]
L.CASE_KILLER_SUSPECT = "DADER (VERDACHT)"  -- [max 24]
L.CASE_CLICK_NAME = "Klik op de naam om de affiche te openen."
L.CASE_GONE = "Staat niet meer in het boek."
L.CASE_KILLER_UNCLEAR = "DADER ONDUIDELIJK"  -- [max 24]
L.CASE_SEVERAL = "Meerdere kunnen het gedaan hebben. Wiens naam komt in het boek?"
L.CASE_NOBODY = "Niemand kan het gedaan hebben."
L.CASE_HOW = "WAT ER GEBEURDE"  -- [max 24]
L.CASE_PVE = "Een monster of de wereld zelf. Geen zaak voor het boek."
L.CASE_UNCLEAR = "Onduidelijk"
L.CASE_DARK = "De recherche tast in het duister."
L.TIP_MORE_CANDIDATES = "Meer kandidaten"
L.CASE_SOURCE_SUSPECT = "Verdacht: had jou vlak voor je dood als doelwit."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltipregel bij daders"  -- [max 44]
L.OPT_MINIMAP = "Minimapknop tonen"  -- [max 44]
L.OPT_ALERT = "Alarm als een dader opduikt"  -- [max 44]
L.OPT_FLASH = "Schermrand rood laten flitsen"  -- [max 44]
L.OPT_SUSPECTS = "Ook verdachten melden"  -- [max 44]
L.OPT_DEATHMSG = "Melding na een PvP-dood"  -- [max 44]
L.OPT_G_SHARE = "Eigen sterfgevallen delen"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Handmatige namen delen"  -- [max 44]
L.OPT_G_RECEIVE = "Guildboek ontvangen"  -- [max 44]
L.OPT_G_ALERT = "Waarschuwen bij daders uit het guildboek"  -- [max 44]
L.OPT_G_ALERTLISTED = "Ook waarschuwen bij handmatige namen"  -- [max 44]
L.OPT_G_ANNOUNCE = "Melden als een guildgenoot wordt gedood"  -- [max 44]
L.OPT_G_SIGHTINGS = "Waarnemingen delen"  -- [max 44]
L.OPT_F_SHARE = "Met de guild delen"  -- [max 44]
L.OPT_F_FRIENDS = "Met vrienden delen"  -- [max 44]
L.OPT_F_ALERT = "Waarschuwen bij daders van guild en vrienden"  -- [max 44]
L.OPT_F_ALERTHUNT = "Waarschuwen bij doelwitten op de dodenlijst"  -- [max 44]
L.OPT_F_ANNOUNCE = "Melden als guildgenoten of vrienden sterven"  -- [max 44]
L.OPT_F_SIGHTINGS = "Waarnemingen delen met guild en vrienden"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guild"  -- [max 14]
L.SET_BOOK_SIZE = "Grootte van het boek"  -- [max 34]
L.SET_LANGUAGE = "Taal"  -- [max 16]
L.SET_LANG_AUTO = "Automatisch"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Werkt na herladen."  -- [max 28]
L.SET_LANG_RELOAD = "Nu herladen"  -- [max 22]
L.SET_SEC_SHARE = "DOORGEVEN"  -- [max 24]
L.IO_EXPORT = "Boek bewaren"  -- [max 17]
L.IO_IMPORT = "Boek inlezen"  -- [max 17]
L.SET_HINT_BOOK = "Bewaren geeft je het boek als tekst: om te houden of door te geven aan mensen buiten de guild. Inlezen voegt samen en overschrijft niets."
L.SET_SEC_SOUND = "GELUID"  -- [max 24]
L.SET_SOUND = "Geluid"  -- [max 22]
L.SET_VOLUME = "Volume"  -- [max 22]
L.SET_CHANNEL = "Kanaal"  -- [max 12]
L.SET_SEC_THRESHOLD = "DREMPEL"  -- [max 24]
L.SET_COOLDOWN = "Cooldown per dader"  -- [max 34]
L.SET_MINKILLS = "Alarm na zoveel keer gedood"  -- [max 34]
L.SET_ALERT_SIZE = "Grootte van het alarm"  -- [max 34]
L.SET_TEST_ALERT = "Testalarm"  -- [max 17]
L.SET_G_MINKILLS = "Guildwaarschuwing na zoveel doden"  -- [max 34]
L.SET_F_MINKILLS = "Waarschuwing na zoveel doden"  -- [max 34]
L.SET_SEC_STATUS = "STATUS"  -- [max 24]
L.SET_SEC_SHARING = "DELEN"
L.SET_SEC_WARN = "ALARM"
L.SET_MORE = "Meer"
L.SET_GUILD_CLEAR = "Guildboek leegmaken"  -- [max 26]
L.SET_HINT_GUILD = "Alleen je eigen guild krijgt iets. Wat daarvandaan komt, blijft los van je boek tot je het zelf overneemt."
L.SET_HINT_FRIENDS = "Alleen guild en vrienden met DeathNote krijgen iets."
L.BTN_BACK = "Terug"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sync"  -- [max 14]
L.SYNC_AGAIN_IN = "weer over {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Vrienden"
L.TIP_GUILD_NAME = "Guild {guild}"
L.TIP_MATES_WITH = "Guildgenoten met DeathNote:"
L.TIP_NO_MATE = "Nog geen guildgenoot met DeathNote gehoord."
L.TIP_FRIENDS_WITH = "Vrienden met DeathNote:"
L.TIP_SHARED = "Gedeeld: je bevestigde sterfgevallen, handmatige namen en je jachtoproepen."
L.TIP_NOT_SHARED = "Niet gedeeld: notities, verdenkingen, begenadigden, ingelezen namen."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Inlezen"  -- [max 17]
L.IO_DONE = "Ingelezen: {new} nieuw, {merged} samengevoegd."
L.IO_FAILED = "Dat is niet gelukt."
L.IO_SMALL = "Korte versie"  -- [max 17]
L.IO_ALL = "Alles tonen"  -- [max 17]
L.IO_MSG_FULL = "Het hele boek met daden ({size})."
L.IO_MSG_SHORT = "Alleen namen en tellers ({size}). Met daden: {full}."
L.IO_MSG_BIG = "Groot boek ({size}): selecteren en kopiëren duren even."
L.IO_HELP_EXPORT = "De tekst is geselecteerd: Ctrl+C kopieert hem. Bewaar hem of geef hem aan vrienden."
L.IO_HELP_IMPORT = "Plak een bewaarde tekst met Ctrl+V, dan Inlezen. Er wordt niets overschreven."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Iedereen in je guild en je vrienden met DeathNote zien de reden."
L.REL_HINT_GUILD = "Iedereen in je guild met DeathNote ziet de reden."
L.REL_HINT_FRIENDS = "Je vrienden met DeathNote zien de reden."
L.REL_HEAD = "Op de dodenlijst zetten"  -- [max 24]
L.REL_FOR = "VOOR"  -- [max 6]
L.REL_REASON = "REDEN"  -- [max 8]
L.REL_HINT2 = "Je notitie blijft bij jou. Alleen jij kunt je eigen oproep afblazen."
L.REL_GO = "Jacht openen"  -- [max 17]
L.REL_NONE = "Geen guild, en delen met vrienden staat uit."
L.REL_CAP = "Hoogstens {own} eigen oproepen en {max} doelwitten per lijst."
L.REL_FAILED = "De jacht kan nu niet worden geopend."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Geen geluid: het alarm laat zich alleen zien."
L.SET_HINT_BUILTIN = "Het volume van dit geluid volgt het kanaal in de spelopties."
L.SET_HINT_LEVELS = "Vijf standen van zacht tot hard. De schuifregelaar van het kanaal in de spelopties werkt daarbovenop."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guild & vrienden"  -- [max 18]
L.TIP_HELP_BUTTON = "Zo werkt het boek"
L.VIEW_HUNT = "Dodenlijst"  -- [max 13]
L.VIEW_BY_KILLER = "Per dader"  -- [max 13]
L.VIEW_BY_MATE = "Per lid"  -- [max 13]
L.SRC_ALL = "Alle"  -- [max 12]
L.SRC_GUILD = "Guild"  -- [max 12]
L.SRC_FRIENDS = "Vrienden"  -- [max 12]
L.SORT_HIDE_PARDONED = "Begenadigden verbergen"  -- [max 24]
L.SORT_SHOW_PARDONED = "Begenadigden tonen"  -- [max 24]
L.SEARCH_ADD = "Zoeken of toevoegen …"  -- [max 26]
L.SEARCH_SHORT = "Zoeken …"  -- [max 10]
L.SEARCH_KILLER = "Dader zoeken …"  -- [max 15]
L.SEARCH_JOURNAL = "Dader of plek zoeken …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Alles inklappen"
L.TIP_EXPAND_ALL = "Alles uitklappen"
L.STATUS_NO_PLATES = "Naamplaatjes van vijanden staan uit: het alarm ziet alleen doelwit en muis."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} gezocht"
L.MM_UNSOLVED = "{count} onopgelost"
L.MM_ALERT_OFF = "Alarm staat uit (middelklik)"
L.MM_CLICK = "Klik: boek · Rechtsklik: Huisregels"
L.MM_MIDDLE = "Middelklik: alarm aan/uit"
L.MM_DRAG = "Slepen: langs de rand van de minimap verplaatsen"
L.MM_CHAT_ALERT_ON = "Alarm aan."
L.MM_CHAT_ALERT_OFF = "Alarm uit."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GUILDVIJAND NR. 1"  -- [max 25]
L.STAMP_HUNT = "VOGELVRIJ"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} deed zich voor als je vriend {friend}: geweigerd."
L.FRIENDS_SHORT_IMPOSTOR = "Vreemde geweigerd"  -- [max 22]
L.ALERT_LEVEL = "Level {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "laatst level {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Level ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · op de dodenlijst ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nieuw doelwit|nieuwe doelwitten}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nieuw op de dodenlijst"
L.OPT_F_ANNOUNCEHUNT = "Dodenlijst melden: nieuw en geveld"  -- [max 44]
L.SET_HUNT_EXPIRE = "Oproepen verlopen na"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nooit"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dag|dagen}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Vriendenboek leegmaken"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Het vriendenboek op deze computer leegmaken?\nDe dodenlijst ervan gaat mee, je eigen oproepen blijven."
L.CONFIRM_CALLOFF_ALL = "Al je oproepen afblazen?\nGuild en vrienden horen het beetje bij beetje."
L.CONFIRM_CALLOFF_ALL_OK = "Alles afblazen"  -- [max 14]
L.ACT_CALLOFF_ALL = "Al de mijne afblazen"  -- [max 24]
L.ACT_HUNT_HIDE = "Voor mij verbergen"  -- [max 19]
L.ACT_HUNT_SHOW = "Weer tonen"  -- [max 19]
L.HUNT_ROW_HIDDEN = "verborgen voor jou"
L.HUNT_ROW_CALLS = "{count} {count|oproep|oproepen}: {names}"
L.POSTER_ON_HUNTLIST = "Op de dodenlijst ({names})"
L.REL_SELF = "Jezelf kun je niet op de dodenlijst zetten."
L.REL_MATE = "Dat is een van jullie (guild of vrienden met DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Wie is je vriend {friend}: {a} of {b}? Kies zelf."
L.FRIENDS_SHORT_CONFLICT = "Vriend onzeker"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Twee spelers zeggen dat ze je vriend {friend} zijn: {a} en {b}. Tot je kiest, neemt het boek van geen van beiden iets aan. Guild & vrienden, weergave Per lid: rechtsklik op de naam."
L.MEMBER_CONFLICT = "Rechtsklik: is dit je vriend?"  -- [max 40]
L.ACT_TIE_MINE = "Mijn vriend: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Loskoppelen"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "{name} loskoppelen van je vriendenlijst?\nWat deze naam in het vriendenboek heeft gebracht, wordt gewist; het volgende bericht onder deze voornaam koppelt opnieuw."
L.CHAT_FRIENDS_TIES = "Gekoppelde volledige namen (* = eerste contact, nog niet bevestigd): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Naam [Achternaam]> <goud>  eigen premie uitloven (zonder goud: intrekken)"
L.CHAT_WHO_BOUNTY = "Op wie? /dn bounty <Naam> <goud>"
L.CHAT_BOUNTY_SET = "{name}: je hebt {gold} goud premie uitgeloofd. Guild en vrienden met DeathNote zien het."
L.CHAT_BOUNTY_OFF = "{name}: je premie is ingetrokken."
L.CHAT_BOUNTY_NONE = "Je hebt geen eigen premie op {name}."
L.CHAT_BOUNTY_BAD = "Premie: een heel getal goud, 1 tot 99999 (0 trekt hem in)."
L.CHAT_BOUNTY_CAP = "Geen premie: hoogstens {count} eigen."
L.CHAT_BOUNTY_OURS = "Geen premie op jezelf of je eigen mensen (guild of vrienden met DeathNote)."
L.ACT_BOUNTY = "Premie uitloven"  -- [max 24]
L.ACT_UNDO = "Ongedaan maken"  -- [max 19]
L.ACT_REVENGE_TAKE = "Eén wraak aftrekken"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, uitgeloofd door jou"
L.POSTER_BOUNTY_BY = "{gold}, uitgeloofd door {name}"
L.POSTER_BOUNTY_MANY = "Premie {gold}: {names}"
L.POSTER_AVENGED = "Gewroken door {names}"
L.ROW_AVENGED = "gewroken {times}"
L.BOUNTY_TIP_HEAD = "Je eigen premie in goud"
L.BOUNTY_TIP_RULES = "Een heel getal, 1 tot 99999. Leeg of 0: terug naar de waarde van het boek. Enter zet, Esc breekt af."
L.BOUNTY_TIP_PROMISE = "Guild en vrienden met DeathNote zien het. Alleen een belofte: jullie regelen het onderling."
L.BOUNTY_TIP_CLICK = "Klik: eigen premie uitloven"
L.CHAT_AVENGED = "{name} heeft {killer} voor je geveld."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: je hebt {gold} goud premie uitgeloofd."
L.CHAT_BOUNTY_UNKNOWN = "{name} staat in geen van je boeken. Een premie alleen op een naam uit een boek, zoals het spel hem toont: voornaam en achternaam."
L.CHAT_BOUNTY_LIST = "Je premies ({count} van {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Je hebt geen premie uitgeloofd."
-- <<< BOOK
-- >>> REPUTE (1.3.0): English placeholders, to be translated (keys as in enUS.lua) ---------------------------------
L.REPUTE_LINE = "Rank {tier} · Path: {path}"
L.PATH_R = "Infamy"
L.PATH_E = "Honour"
L.PATH_J = "Hunt"
L.PATH_S = "Protection"
L.PATH_NONE = "unwritten"
-- <<< REPUTE
-- >>> ALARM (1.3.0): English placeholders, to be translated (keys as in enUS.lua) -----------------------------------
L.ALERT_TITLE_VICTIM = "HOLDS A GRUDGE?"
L.ALERT_LINE_VICTIM = "score {score} · killed by you, last {time}"
L.ALERT_LINE_STANDING = "{text} · score {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · score {score}, even"
L.ALERT_LINE_STANDING_AHEAD = "{text} · score {score}, overpaid"
-- <<< ALARM
end)
