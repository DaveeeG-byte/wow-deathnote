-- DeathNote: Norsk bokmål (nbNO). No official Norwegian client: words as Norwegian players use them (guild, dungeons).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.nbNO), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Glossary: boken, guildboken, venneboken, morder, guildmedlem, venn, Ettersøkte, Uløste saker, Dødslogg, Husregler,
-- plakat, stempel, dusør, notat, observasjon, stryke, benåde, hevn, mistenkt, jaktlisten, lyse ut jakt,
-- utlysning, blåse av jakten, felt, Lagre boken, Les inn boken.
--
-- TOC-Notes: Dødsliste for PvP i den åpne verdenen: husker hvem som drepte deg og varsler når de er i nærheten.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("nbNO")) then return end

Locale.Register("nbNO", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Ettersøkte"    -- [max 16]
L.TAB_UNSOLVED = "Uløste saker"  -- [max 16]
L.TAB_DEATHLOG = "Dødslogg"      -- [max 16]
L.TAB_GUILD    = "Guild"         -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Husregler"       -- [max 24]
L.HEAD_HELP  = "Bruksanvisning"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Bok"            -- [max 14]
L.SHEET_ALERT = "Alarm"          -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "SAMFUNNSFIENDE NR. 1"    -- [max 24]
L.STAMP_REVENGE  = "HEVNET"               -- [max 16]
L.STAMP_PARDONED = "BENÅDET"              -- [max 16]
L.STAMP_SUSPECT  = "MISTENKT"             -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "SAMFUNNSFIENDE NR. 1 OBSERVERT" -- [max 30]
L.ALERT_SIGHTED         = "SAMFUNNSFIENDE OBSERVERT"       -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "MISTENKT OBSERVERT"          -- [max 30]
L.ALERT_TITLE_GUILD     = "GUILDFIENDE OBSERVERT"       -- [max 30]
L.ALERT_TITLE_FRIENDS   = "VENNENES MORDER OBSERVERT"   -- [max 30]
L.ALERT_TITLE_HUNT      = "MÅL PÅ JAKTLISTEN"           -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "er mistenkt"
L.ALERT_LINE_KILLED         = "har drept deg {times}"
L.ALERT_LINE_KILLED_ASSISTED = "har drept deg {times}, medvirket {assists}"
L.ALERT_LINE_ASSISTED       = "har medvirket til din død {times}"
L.ALERT_LINE_MANUAL         = "er skrevet inn for hånd"
L.ALERT_LINE_LAST    = "{text}, sist {time}"
L.ALERT_LINE_IN      = "{text} i {zone}"
L.ALERT_LINE_REVENGE = "{text}. Hevn: {times}"
L.ALERT_HINT_CLOSE  = "Høyreklikk: lukk"                            -- [max 44]
L.ALERT_HINT_COMBAT = "Kan tas som mål først etter kampen"          -- [max 44]
L.ALERT_HINT_TARGET = "Klikk: ta som mål  ·  Høyreklikk: lukk"      -- [max 44]
L.ALERT_MORE = "+{count} til"            -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "står i guildboken"
L.GUILD_LINE_IN_FRIENDS = "står i venneboken"
L.GUILD_LINE_LISTED_BY  = "står i boken til {names}"
L.GUILD_LINE_KILLED_GUILD   = "har drept guildmedlemmer {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "har drept venner {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "har drept guildmedlemmer og venner {kills}×"
L.GUILD_LINE_LAST = "{text}, sist {name}"
L.HUNT_LINE_BY       = "jakt lyst ut av {names}"
L.HUNT_LINE_RELEASED = "på jaktlisten"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "mistenkt"
L.TALLY_MANUAL   = "skrevet inn for hånd"
L.TALLY_NONE     = "ingen udåd ennå"
L.TALLY_KILLED   = "drept deg {times}"
L.TALLY_ASSISTED = "medvirket {times}"
L.PLACE_UNKNOWN  = "ukjent sted"
L.GKILLS_CAP     = "minst {count}"
L.NAMELIST_MORE  = "{names} og {count} til"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d.%m. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY       = "%d.%m."
L.TIME_FMT_DAY_YEAR  = "%d.%m.%y"
L.TIME_NEVER   = "aldri"
L.TIME_JUST    = "nettopp"
L.TIME_MINUTES = "{count} min siden"      -- [max 14]
L.TIME_HOURS   = "{count} t siden"        -- [max 14]
L.TIME_DAYS    = "{count} d siden"        -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}k"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Hørt fra {count} {count|guildmedlem|guildmedlemmer} med DeathNote."
L.HEALTH_NOGUILD = "Du er ikke med i noen guild, ingenting deles."
L.HEALTH_OFF     = "Deling er slått av."
L.HEALTH_SHORT_NOGUILD = "Ingen guild"    -- [max 18]
L.HEALTH_SHORT_OFF     = "Deling av"      -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Sperret"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Avvist"         -- [max 18]
L.HEALTH_SHORT_HOLD    = "Venter"         -- [max 18]
L.HEALTH_SHORT_ASKED   = "Forespurt"          -- [max 18]
L.HEALTH_SHORT_FAIL    = "Virker ikke"    -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Ingen lyd"         -- [max 16]
L.SOUND_RAIDWARNING = "Raidvarsel"        -- [max 16]
L.SOUND_BELL        = "Klokke"            -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Hjerteslag"        -- [max 16]
L.SOUND_FEATHER     = "Fjærpenn"          -- [max 16]
L.SOUND_SIREN       = "Sirene"            -- [max 16]
L.CHANNEL_MASTER    = "Hovedvolum"        -- [max 16]
L.CHANNEL_SFX       = "Effekter"          -- [max 16]
L.CHANNEL_DIALOG    = "Dialog"            -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} står nå i boken."
L.CHAT_REMOVED   = "{name} er strøket fra boken."
L.CHAT_SYNC_WAIT = "Nettopp synkronisert. Prøv igjen om {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Ingen navn ennå."
L.EMPTY_WANTED_SUB  = "Gå ut en tur, for en gangs skyld."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  åpne/lukke boken"
L.HELP_ADD      = "/dn add <Navn [Etternavn]>  skriv inn en morder for hånd"
L.HELP_DEL      = "/dn del <Navn [Etternavn]>  stryk en morder fra boken"
L.HELP_QUIET    = "/dn quiet  alarm av/på"
L.HELP_TEST     = "/dn test  vis en testalarm"
L.HELP_GUILD    = "/dn guild  guildboken: status og hvilke guildmedlemmer som har DeathNote"
L.HELP_FRIENDS  = "/dn friends  venneboken: status og hvilke venner som har DeathNote"
L.HELP_SYNC     = "/dn sync  synkroniser guildboken og venneboken nå"
L.HELP_HUNT     = "/dn hunt <Navn [Etternavn]>  lys ut jakt (uten navn: vis jaktlisten)"
L.HELP_CALLOFF  = "/dn calloff <Navn [Etternavn]>  blås av din egen jakt"
L.HELP_LANG     = "/dn lang <kode>  språket i boken (enUS, deDE, nbNO ...), etter /reload"
L.HELP_THEME = "/dn theme <navn>  permen på boken, etter /reload"
L.HELP_PROBE    = "/dn probe  feilsøking: hva spillet forteller boken"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  feilsøking, test også kamploggen"
L.HELP_DEBUG    = "/dn debug  feilsøking: loggfør hver død i detalj (på/av)"
L.HELP_HELP     = "/dn help  denne hjelpen"
L.HELP_SILENT_ZONES = "I dungeons, battlegrounds og arenaer holder boken seg stille av seg selv."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "på"
L.WORD_OFF = "av"
L.CHAT_WHO_ADD  = "Hvem da? /dn add <Navn>"
L.CHAT_WHO_DEL  = "Hvem da? /dn del <Navn>"
L.CHAT_WHO_CALLOFF = "Hvem da? /dn calloff <Navn>"
L.CHAT_BAD_NAME = "Ugyldig navn."
L.CHAT_NOT_IN_BOOK = "Ikke i boken: {name}"
L.CHAT_ALARM_ON  = "Alarm på."
L.CHAT_ALARM_OFF = "Alarm av."
L.CHAT_DEBUG = "Feilsøkingslogg {state}."
L.CHAT_UNKNOWN_CMD = "Ukjent kommando. Hjelp: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Guildboken er ikke lastet."
L.CHAT_NO_GUILD = "Du er ikke med i noen guild (eller spillet vet det ikke ennå)."
L.CHAT_GUILD_STATE = "Guild {guild}: deling {share}, mottak {receive}."
L.CHAT_GUILD_BOOK = "Guildboken: {enemies} mordere ({listed} bare skrevet inn for hånd), {deeds} {deeds|udåd|udåder}, {foreign} av dem har drept andre guildmedlemmer. Del innføringer for hånd: {manual}."
L.CHAT_STATE_OK   = "Status: {text}"
L.CHAT_STATE_WARN = "Obs: {text}"
L.CHAT_NO_MATES   = "Ikke hørt fra noe guildmedlem med DeathNote ennå."
L.CHAT_HAVE_DN      = "Har DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Har DeathNote: {names} og {count} til"
L.CHAT_SYNC_ASKED = "Synkronisering etterspurt. Svarene kommer i løpet av noen sekunder."
L.CHAT_SYNC_FAIL  = "Synkronisering virker ikke: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "ingen guild, eller deling er av."
L.CHAT_FRIENDS_NOT_LOADED = "Venneboken er ikke lastet."
L.CHAT_FRIENDS_STATE = "Venner: deling {share}, {online} av {total} pålogget."
L.CHAT_FRIENDS_BOOK  = "Venneboken: {enemies} mordere ({listed} bare skrevet inn for hånd), {deeds} {deeds|udåd|udåder}."
L.CHAT_NO_FRIENDS    = "Ikke hørt fra noen venn med DeathNote ennå."
L.CHAT_HUNT_NOT_LOADED = "Jaktlisten er ikke lastet."
L.CHAT_HUNT_UNKNOWN = "Ukjent: {name}. Ta med etternavnet også, slik navnet står i spillet."
L.CHAT_HUNT_CAP     = "Kan ikke lyse ut jakt: maks {own} egne utlysninger og {targets} mål per liste."
L.CHAT_HUNT_NOWHERE = "Kan ikke lyse ut jakt nå: ingen guild, og deling med venner er av."
L.CHAT_HUNT_BOTH    = "{name} står på jaktlisten, for guild og venner."
L.CHAT_HUNT_GUILD   = "{name} står på jaktlisten, for guilden."
L.CHAT_HUNT_FRIENDS = "{name} står på jaktlisten, for vennene dine."
L.CHAT_CALLED_OFF   = "Jakten er blåst av: {name}."
L.CHAT_NO_OWN_CALL  = "Du har ingen egen utlysning på {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Språk nå: {lang}. Endre: /dn lang <kode>"
L.CHAT_LANG_LIST    = "Koder: {codes}"
L.CHAT_LANG_BAD     = "Ukjent språk: {code}"
L.CHAT_LANG_SET     = "Språk: {lang}."
L.CHAT_LANG_RELOAD  = "Språk: {lang}. Gjelder etter /reload."
L.CHAT_THEME_CURRENT = "Perm nå: {theme}. Endre: /dn theme <navn>"
L.CHAT_THEME_LIST = "Permer: {themes}"
L.CHAT_THEME_BAD = "Ukjent perm: {name}"
L.CHAT_THEME_SET = "Perm: {theme}."
L.CHAT_THEME_RELOAD = "Perm: {theme}. Gjelder etter /reload."
L.THEME_NOTEBOOK = "Den svarte boken"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Boken ligger klar. Den som dreper deg i den åpne verdenen, havner i den. Åpne den med /dn eller minimap-knappen."
L.WELCOME_PLATES = "Fiendtlige navneskilt er slått av. Uten dem ser alarmen bare målet ditt."
L.WELCOME_SHARE = "Guild og venner som har DeathNote, leser med. Notater og mistanker blir hos deg."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "I BOKEN:"
L.TIP_HUNT      = "JAKTLISTEN:"
L.TIP_GUILDBOOK = "GUILDBOKEN:"
L.TIP_PARDONED  = "benådet"
L.TIP_RANK      = "rang {rank}"
L.TIP_REVENGE   = "hevn {times}"
L.TIP_LISTED_BY = "i boken til {names}"
L.TIP_NOTE      = "Notat: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Klikk: åpne · Høyreklikk: bort"
L.BANNER_NEW          = "NYTT NAVN"            -- [max 24]
L.BANNER_NEW_LINE     = "står nå i boken"
L.BANNER_AGAIN        = "IGJEN"                -- [max 24]
L.BANNER_AGAIN_LINE   = "har drept deg igjen, {count} ganger nå"
L.BANNER_SUSPECT      = "MISTENKT"             -- [max 24]
L.BANNER_SUSPECT_LINE = "er mistenkt, avklar det i boken"
L.BANNER_UNCLEAR      = "UKLAR MORDER"         -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|kandidat|kandidater}"
L.BANNER_UNCLEAR_LINE = "Klikk: velg morderen under Uløste saker"
L.BANNER_REVENGE      = "GJENGJELDELSE"        -- [max 24]
L.BANNER_REVENGE_LINE = "Hevnet ({count}×)"
L.BANNER_GUILD        = "GUILD"                -- [max 24]
L.BANNER_FRIENDS      = "VENNER"               -- [max 24]
L.BANNER_KILLED_BY    = "ble drept av {name}"
L.BANNER_HUNT         = "JAKTLISTEN"           -- [max 24]
L.BANNER_BAGGED       = "felt av {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Deling er slått av (Husregler, arket Guild)."
L.SYNC_FRIENDS_OFF = "Deling med venner er av."
L.SYNC_NOBODY      = "Ingen guild og ingen venner å dele med."
L.SYNC_SHORT_NOBODY = "Ingenting delt"        -- [max 18]
L.SYNC_PREFIX      = "Spillet tillater ikke mottak. Det hjelper å logge inn på nytt."
L.SYNC_SHORT_PREFIX = "Mottak virker ikke"    -- [max 18]
L.SYNC_BLOCKED     = "Realmen sperrer sending. Del videre med Lagre boken."
L.SYNC_SHORT_BLOCKED = "Sending sperret"      -- [max 22]
L.SYNC_FAILING     = "Sending feiler akkurat nå, prøver igjen."
L.SYNC_SHORT_FAILING = "Sending hakker"       -- [max 18]
L.SYNC_HOLD        = "Sendingen venter {wait}."
L.SYNC_HOLD_INSTANCE = "til du forlater instansen"
L.SYNC_HOLD_COMBAT   = "til du er ute av kamp"
L.SYNC_HOLD_LOCKDOWN = "til chatten er ledig igjen"
L.SYNC_HOLD_AGAIN    = "til det virker igjen"
L.SYNC_HOLD_SHORT_INSTANCE = "Venter: instans"    -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Venter: kamp"       -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Venter: chat"       -- [max 18]
L.SYNC_QUIET       = "Sendt, men ikke hørt fra noe guildmedlem med DeathNote ennå."
L.SYNC_READY       = "Klar. Ikke hørt fra noe guildmedlem med DeathNote ennå."
L.SYNC_RUNNING     = "I gang: {count} {count|guildmedlem|guildmedlemmer} med DeathNote."
L.SYNC_RUNNING_ALL = "I gang: {count} med DeathNote i guild og blant venner."
L.FRIENDS_OFF      = "Deling med venner er av (Husregler, arket Guild)."
L.FRIENDS_BLOCKED  = "Realmen sperrer hvisking. Venner får ingenting."
L.FRIENDS_SHORT_BLOCKED = "Hvisking sperret"     -- [max 22]
L.FRIENDS_FAILING  = "Hvisking feiler akkurat nå, prøver igjen."
L.FRIENDS_SHORT_FAILING = "Hvisking hakker"      -- [max 18]
L.FRIENDS_NONE_LISTED = "Ingen venner på vennelisten."
L.FRIENDS_NONE_ONLINE = "Ingen venner pålogget akkurat nå."
L.FRIENDS_SHORT_NONE_ONLINE = "Ingen pålogget"    -- [max 18]
L.FRIENDS_QUIET    = "Spurt, men ikke hørt fra noen venn med DeathNote ennå."
L.FRIENDS_READY    = "Klar. Ikke hørt fra noen venn med DeathNote ennå."
L.FRIENDS_HOLD     = "Sending til venner venter til det virker igjen."
L.FRIENDS_RUNNING  = "I gang: {count} {count|venn|venner} med DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Hentet fra guildboken (har drept guildmedlemmer {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Databasen er ikke lastet."
L.IMPORT_NO_TEXT    = "Ingen tekst."
L.IMPORT_NO_HEADER  = "Første linje mangler (den begynner med {header}). Kopier hele teksten."
L.IMPORT_NOT_EXPORT = "Ikke en DeathNote-eksport (overskriftslinjen mangler eller feil versjon)."
L.IMPORT_TOO_LONG   = "For mange linjer (maks {count})."
L.IMPORT_BAD_KEY    = "Linje {line}: ugyldig nøkkel."
L.IMPORT_BAD_TIME   = "Linje {line}: ugyldig tid."
L.IMPORT_BROKEN     = "Linje {line} er ufullstendig eller ødelagt (avkuttet tekst?). Ingenting lest inn."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "ja"
L.WORD_NO  = "nei"
L.PROBE_HEAD = "Sonde: {apis}/{apisAll} grensesnitt finnes, {events}/{eventsAll} hendelser kan registreres."
L.PROBE_MISSING = "Mangler: {list}"
L.PROBE_NOT_REGISTERABLE = "Kan ikke registreres: {list}"
L.PROBE_SOURCES = "Recap nå: {recap} · Meter: {meter} · Kamplogg: {clog}"
L.PROBE_READABLE = "lesbar"
L.PROBE_DEAD = "død"
L.PROBE_PLATES = "Fiendtlige navneskilt: {plates} · Åpen verden: {open}"
L.PROBE_PLATES_OFF = "AV (bare mål og musepeker finner spillere)"
L.PROBE_TARGET = "Mål: navn={name} GUID={guid} klasse={class} fiendtlig={enemy} sikter på meg={me}"
L.PROBE_GUILD = "Guild: prefiks {prefix} · sending {send} · siste returverdi {result} · sendt {sent}, mottatt {received}, forkastet {dropped}"
L.PROBE_REGISTERED = "registrert"
L.PROBE_NOT_REGISTERED = "IKKE registrert ({result})"
L.PROBE_POSSIBLE = "mulig"
L.PROBE_ABSENT = "mangler"
L.PROBE_WAITS = " · venter: {why}"
L.PROBE_LISTED = "For hånd (M): sendt {sent}, mottatt {received}, forkastet {dropped} · strøket (X): sendt {usent}, mottatt {ureceived}, forkastet {udropped}"
L.PROBE_GUILDBOOK = "Guildboken: {text}"
L.PROBE_SAVED = "Lagret i DeathNoteDB.probe (i filen etter /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Nyeste"  -- [max 14]
L.SORT_NAME = "Navn"  -- [max 14]
L.SORT_SEEN = "Sett"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Den som dreper deg i den åpne verdenen, havner her. Helt av seg selv."
L.EMPTY_OPEN_HEAD = "Ingenting uløst."
L.EMPTY_JOURNAL_HEAD = "Aldri dødd ennå."
L.EMPTY_JOURNAL_SUB = "Respekt. Eller løgn."
L.EMPTY_NOGUILD_HEAD = "Ingen guild."
L.EMPTY_NOGUILD_SUB = "Man kan dø alene også."
L.EMPTY_GUILDOFF_HEAD = "Guildboken er lukket."
L.EMPTY_GUILDOFF_SUB = "Deling er av. Husreglene vet hvor."
L.EMPTY_GUILDNIL_HEAD = "Ikke hørt noe fra guilden ennå."
L.EMPTY_GUILDNIL_SUB = "Boken din sendes ut så snart et guildmedlem har DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Ingenting i guildboken ennå."
L.EMPTY_GUILDQUIET_SUB = "Guildmedlemmene dine har hatt fred så langt."
L.EMPTY_FRIENDSOFF_HEAD = "Venneboken er lukket."
L.EMPTY_FRIENDSOFF_SUB = "Deling med venner er av. Husreglene vet hvor."
L.EMPTY_FRIENDSNIL_HEAD = "Ikke hørt fra noen venn med DeathNote ennå."
L.EMPTY_FRIENDSNIL_SUB = "Boken din sendes ut så snart en venn har DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Ingenting fra vennene dine ennå."
L.EMPTY_FRIENDSQUIET_SUB = "Vennene dine har hatt fred så langt."
L.EMPTY_NOBODY_HEAD = "Ingen guild, ingen venner."
L.EMPTY_NOBODY_SUB = "Man kan dø alene også."
L.EMPTY_NOBODY_HINT = "Når guildmedlemmer eller venner fra vennelisten din har DeathNote, viser denne siden hva som skjer med dem."
L.EMPTY_SHAREDNIL_HEAD = "Ikke hørt fra noen med DeathNote ennå."
L.EMPTY_SHAREDNIL_SUB = "Boken din sendes ut så snart guildmedlemmer eller venner har DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Ingenting her ennå."
L.EMPTY_SHAREDQUIET_SUB = "Guild og venner har hatt fred så langt."
L.EMPTY_HUNT_HEAD = "Jaktlisten er tom."
L.EMPTY_HUNT_SUB = "På plakaten: Lys ut jakt."
L.EMPTY_HUNT_HINT = "Eller i chatten: /dn hunt Navn Etternavn. Alle i guilden din og vennene dine ser det."
L.EMPTY_SEARCH_HEAD = "Ingen treff."
L.EMPTY_SEARCH_SUB = "Enter skriver navnet inn i boken."
L.EMPTY_SEARCHRO_HEAD = "Ingen treff."
L.EMPTY_SEARCHRO_SUB = "Noen ganger hjelper en annen stavemåte."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "BOKEN"  -- [max 12]
L.MANUAL_BOOK = "Den som dreper deg i den åpne verdenen, skrives inn av seg selv. Et klikk på meldingen etter at du døde, åpner morderens side."
L.MANUAL_WANTED_HEAD = "ETTERSØKTE"  -- [max 12]
L.MANUAL_WANTED = "Morderne dine, den verste først. Et klikk viser plakaten med udåder og notat. Benådede står overstreket til slutt."
L.MANUAL_UNSOLVED_HEAD = "ULØSTE SAKER"  -- [max 13]
L.MANUAL_UNSOLVED = "Når det ikke var klart hvem som gjorde det, venter saken her. Et klikk på et navn avgjør hvem morderen er."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Når en morder dukker opp som navneskilt, mål eller under musepekeren, sier boken fra. Et klikk tar dem som mål, i kamp først etterpå."
L.MANUAL_ADD_HEAD = "SKRIVE INN"  -- [max 12]
L.MANUAL_ADD = "Skriv et navn i søkefeltet, Enter. Høyreklikk på en linje: noter hevn, benåd, stryk."
L.MANUAL_GUILD_HEAD = "GUILD"  -- [max 12]
L.MANUAL_GUILD = "Guildmedlemmer og venner med DeathNote ser dine bekreftede dødsfall og innføringer for hånd. Plakaten eller /dn hunt Navn: lys ut jakt. Klikk på dusøren: lys ut din egen, et løfte dere gjør opp seg imellom."
L.MANUAL_SHARE_HEAD = "DEL VIDERE"  -- [max 12]
L.MANUAL_SHARE = "Husregler, Lagre boken: en tekst å kopiere, for alle uten DeathNote."
L.MANUAL_QUIET_HEAD = "STILLE"  -- [max 12]
L.MANUAL_QUIET = "I dungeons og battlegrounds holder alarmen seg stille. Ellers: midtklikk på minimap-knappen eller /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Vil du virkelig stryke {name} fra boken?\nAlle udåder og notatet går tapt."
L.CONFIRM_DELETE_OK = "Stryk"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Vil du tømme guildboken på denne maskinen?\nJaktlisten i den forsvinner også, dine egne utlysninger blir.\nDin egen bok forblir som den er."
L.CONFIRM_GUILD_CLEAR_OK = "Tøm"  -- [max 14]
L.CONFIRM_CANCEL = "Avbryt"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GULL"  -- [max 14]
L.BOUNTY_SILVER = "{count} SØLV"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"  -- no-break space (a plain space counts as empty in the test)
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Bekreft"  -- [max 19]
L.ACT_DISMISS = "Avvis"  -- [max 19]
L.ACT_HUNT_AGAIN = "Jakt igjen"  -- [max 19]
L.ACT_REVENGE = "Noter hevn"  -- [max 19]
L.ACT_PARDON = "Benåd"  -- [max 19]
L.ACT_STRIKE = "Stryk"  -- [max 19]
L.ACT_OPEN_OWN = "Åpne i boken"  -- [max 19]
L.ACT_ADOPT = "Til min bok"  -- [max 19]
L.ACT_CALLOFF = "Blås av jakten"  -- [max 19]
L.ACT_RELEASE = "Lys ut jakt"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "sett {time}"
L.ROW_NOT_SEEN = "ikke observert ennå"
L.ROW_PARDONED = "benådet"
L.ROW_SUSPECT = "Mistenkt"
L.MARK_REVENGE = "HEVN {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Uklar morder"
L.MARK_CANDIDATES = "{count} {count|KANDIDAT|KANDIDATER}"  -- [max 16]
L.MARK_SUSPECT = "MISTENKT"  -- [max 16]
L.ROW_NO_PLAYER = "Ingen spiller"
L.ROW_UNCLEAR = "Uklart hvordan"
L.MARK_NOT_COUNTED = "TELLER IKKE"  -- [max 16]
L.ROW_LISTED_BY = "skrevet inn av {names}"
L.ROW_GKILLED = "drept {kills}×"
L.ROW_VICTIMS = "{count} {count|offer|offer}"
L.ROW_LAST = "sist {text}"
L.MARK_IN_BOOK = "I BOKEN"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|morder|mordere}"  -- [max 14]
L.MEMBER_DEATHS = "{count} dødsfall"  -- [max 12]
L.MEMBER_LISTED = "{count} for hånd"  -- [max 14]
L.MEMBER_ME = "dette ser de andre av deg"
L.MEMBER_NOTHING = "ingenting delt ennå"
L.MEMBER_LAST_DIED = "døde sist {time}"
L.MARK_YOU = "du"  -- [max 16]
L.MARK_FRIEND = "VENN"  -- [max 16]
L.MARK_BOTH = "GUILDMEDLEM, VENN"  -- [max 20]
L.MARK_TAKEN_DOWN = "FELT {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DØD ELLER LEVENDE"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "UDÅDER"  -- [max 14]
L.POSTER_NOTE = "NOTAT"  -- [max 8]
L.POSTER_BOUNTY = "DUSØR"  -- [max 12]
L.ROLE_ASSIST = "medvirket"  -- [max 14]
L.ROLE_SUSPECT = "mistenkt"  -- [max 14]
L.POSTER_LEVEL = "Nivå {level}"
L.POSTER_GUILD = "Guild: {guild}"
L.POSTER_LAST_SEEN = "Sist sett {time}"
L.POSTER_NOT_SEEN = "Ikke observert ennå"
L.POSTER_ONLY_SUSPECT = "Bare mistenkt, ingen bevist udåd."
L.POSTER_NO_DEEDS = "Ingen udåder notert."
L.TIP_LISTED_AT = "Skrevet inn {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Dødsårsak: {spell}"
L.TIP_VICTIM = "Offer: {name}"
L.TIP_VICTIM_LEVEL = "Offer: {name} (nivå {level})"
L.TIP_KILLER_LEVEL = "Morderens nivå: {level}"
L.TIP_ASSISTS = "Medvirket: {names}"
L.TIP_ROLE_ASSIST = "Medvirket, ga ikke dødsstøtet."
L.TIP_ROLE_SUSPECT = "Bare mistenkt, ikke bevist."
L.MORE_LINE = "… og {count} til"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GUILDBOKEN"  -- [max 24]
L.POSTER_IN_BOOK_OF = "I boken til: {names}"
L.POSTER_SEEN = "Sett {time}"
L.POSTER_SEEN_BY = "Sett {time} av {name}"
L.TIP_IN_BOOK_OF = "I boken til"
L.POSTER_REMARK = "MERKNAD"  -- [max 12]
L.POSTER_BY_HAND = "SKREVET INN FOR HÅND"  -- [max 22]
L.POSTER_VICTIMS = "OFRE"  -- [max 12]
L.POSTER_LISTED = "SKREVET INN"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Skrevet inn for hånd."
L.POSTER_NO_DEEDS_SENT = "Ingen udåder fulgte med."
L.POSTER_NONE_KNOWN = "ingen kjente"
L.POSTER_NO_NAMES = "ingen navn fulgte med"
L.TIP_VICTIMS = "Ofre"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Lyst ut {time}"
L.HUNT_REASON = "Grunn: {reason}"
L.POSTER_HUNTLIST = "JAKTLISTEN"  -- [max 24]
L.POSTER_RELEASED_N = "jakt lyst ut {times}"
L.POSTER_RELEASED_BY = "Lyst ut av {names}"
L.POSTER_TAKEN_DOWN = "FELT"  -- [max 12]
L.POSTER_NOT_YET = "IKKE ENNÅ"  -- [max 18]
L.POSTER_CALLS = "LYST UT"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Ingen lenger."
L.POSTER_LAST = "SIST"  -- [max 13]
L.POSTER_TAKEN_BY = "felt av {name}, {time}"
L.POSTER_TAKEN_NOBODY = "ikke felt av noen ennå"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Dødsfall"  -- [max 20]
L.CASE_ASSISTS = "MEDVIRKET"  -- [max 24]
L.CASE_PICK = "AVGJØR HVEM MORDEREN ER"  -- [max 24]
L.CASE_NOT_COUNTED = "Teller ikke (instans, battleground eller duell)"
L.CASE_KILLER = "MORDER"  -- [max 24]
L.CASE_KILLER_SUSPECT = "MORDER (MISTENKT)"  -- [max 24]
L.CASE_CLICK_NAME = "Klikk på navnet for å åpne plakaten."
L.CASE_GONE = "Står ikke lenger i boken."
L.CASE_KILLER_UNCLEAR = "UKLAR MORDER"  -- [max 24]
L.CASE_SEVERAL = "Flere kan ha gjort det. Hvem sitt navn skal inn i boken?"
L.CASE_NOBODY = "Ingen kan ha gjort det."
L.CASE_HOW = "HVA SOM SKJEDDE"  -- [max 24]
L.CASE_PVE = "Et monster eller verden selv. Ingen sak for boken."
L.CASE_UNCLEAR = "Uklart"
L.CASE_DARK = "Krimteknikerne famler i mørket."
L.TIP_MORE_CANDIDATES = "Flere kandidater"
L.CASE_SOURCE_SUSPECT = "Mistenkt: hadde deg som mål rett før du døde."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-linje over mordere"  -- [max 44]
L.OPT_MINIMAP = "Vis minimap-knappen"  -- [max 44]
L.OPT_ALERT = "Alarm når en morder dukker opp"  -- [max 44]
L.OPT_FLASH = "Blink skjermkanten rødt"  -- [max 44]
L.OPT_SUSPECTS = "Meld fra om mistenkte også"  -- [max 44]
L.OPT_DEATHMSG = "Melding etter en PvP-død"  -- [max 44]
L.OPT_G_SHARE = "Del mine dødsfall"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Del innføringer for hånd"  -- [max 44]
L.OPT_G_RECEIVE = "Motta guildboken"  -- [max 44]
L.OPT_G_ALERT = "Varsle om mordere fra guildboken"  -- [max 44]
L.OPT_G_ALERTLISTED = "Varsle også om innføringer for hånd"  -- [max 44]
L.OPT_G_ANNOUNCE = "Meld fra når et guildmedlem blir drept"  -- [max 44]
L.OPT_G_SIGHTINGS = "Del observasjoner"  -- [max 44]
L.OPT_F_SHARE = "Del med guilden"  -- [max 44]
L.OPT_F_FRIENDS = "Del med venner"  -- [max 44]
L.OPT_F_ALERT = "Varsle om mordere fra guild og venner"  -- [max 44]
L.OPT_F_ALERTHUNT = "Varsle om mål på jaktlisten"  -- [max 44]
L.OPT_F_ANNOUNCE = "Meld fra når guildmedlemmer eller venner dør"  -- [max 44]
L.OPT_F_SIGHTINGS = "Del observasjoner med guild og venner"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guild"  -- [max 14]
L.SET_BOOK_SIZE = "Størrelse på boken"  -- [max 34]
L.SET_LANGUAGE = "Språk"  -- [max 16]
L.SET_LANG_AUTO = "Automatisk"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Gjelder etter ny innlasting."  -- [max 28]
L.SET_LANG_RELOAD = "Last inn på nytt"  -- [max 22]
L.SET_SEC_SHARE = "DEL VIDERE"  -- [max 24]
L.IO_EXPORT = "Lagre boken"  -- [max 17]
L.IO_IMPORT = "Les inn boken"  -- [max 17]
L.SET_HINT_BOOK = "Lagre gir deg boken som tekst: til å ta vare på, eller til å gi videre til folk utenfor guilden. Les inn slår sammen og overskriver ingenting."
L.SET_SEC_SOUND = "LYD"  -- [max 24]
L.SET_SOUND = "Lyd"  -- [max 22]
L.SET_VOLUME = "Volum"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "TERSKEL"  -- [max 24]
L.SET_COOLDOWN = "Cooldown per morder"  -- [max 34]
L.SET_MINKILLS = "Alarm etter antall drap av dem"  -- [max 34]
L.SET_ALERT_SIZE = "Størrelse på alarmen"  -- [max 34]
L.SET_TEST_ALERT = "Testalarm"  -- [max 17]
L.SET_G_MINKILLS = "Guildvarsel etter antall drap"  -- [max 34]
L.SET_F_MINKILLS = "Varsel etter antall drap"  -- [max 34]
L.SET_SEC_STATUS = "STATUS"  -- [max 24]
L.SET_SEC_SHARING = "DELING"
L.SET_SEC_WARN = "ALARM"
L.SET_MORE = "Mer"
L.SET_GUILD_CLEAR = "Tøm guildboken"  -- [max 26]
L.SET_HINT_GUILD = "Bare din egen guild får noe. Det som kommer derfra, holdes atskilt fra boken din til du selv tar det over."
L.SET_HINT_FRIENDS = "Bare guild og venner med DeathNote får noe."
L.BTN_BACK = "Tilbake"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synkroniser"  -- [max 14]
L.SYNC_AGAIN_IN = "igjen om {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Venner"
L.TIP_GUILD_NAME = "Guild {guild}"
L.TIP_MATES_WITH = "Guildmedlemmer med DeathNote:"
L.TIP_NO_MATE = "Ikke hørt fra noe guildmedlem med DeathNote ennå."
L.TIP_FRIENDS_WITH = "Venner med DeathNote:"
L.TIP_SHARED = "Deles: dine bekreftede dødsfall, innføringer for hånd og jaktutlysningene dine."
L.TIP_NOT_SHARED = "Deles ikke: notater, mistanker, benådede, innleste navn."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Les inn"  -- [max 17]
L.IO_DONE = "Lest inn: {new} nye, {merged} slått sammen."
L.IO_FAILED = "Det gikk ikke."
L.IO_SMALL = "Kortversjon"  -- [max 17]
L.IO_ALL = "Vis alt"  -- [max 17]
L.IO_MSG_FULL = "Hele boken med udåder ({size})."
L.IO_MSG_SHORT = "Bare navn og antall ({size}). Med udåder: {full}."
L.IO_MSG_BIG = "Stor bok ({size}): merking og kopiering tar litt tid."
L.IO_HELP_EXPORT = "Teksten er merket: Ctrl+C kopierer den. Ta vare på den eller gi den til venner."
L.IO_HELP_IMPORT = "Lim inn en lagret tekst med Ctrl+V, deretter Les inn. Ingenting blir overskrevet."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Alle i guilden din og vennene dine med DeathNote ser grunnen."
L.REL_HINT_GUILD = "Alle i guilden din med DeathNote ser grunnen."
L.REL_HINT_FRIENDS = "Vennene dine med DeathNote ser grunnen."
L.REL_HEAD = "Lys ut jakt"  -- [max 24]
L.REL_FOR = "FOR"  -- [max 6]
L.REL_REASON = "GRUNN"  -- [max 8]
L.REL_HINT2 = "Notatet ditt blir hos deg. Bare du kan blåse av din egen utlysning."
L.REL_GO = "Lys ut jakten"  -- [max 17]
L.REL_NONE = "Ingen guild, og deling med venner er av."
L.REL_CAP = "Maks {own} egne utlysninger og {max} mål per liste."
L.REL_FAILED = "Kan ikke lyse ut jakt akkurat nå."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Ingen lyd: alarmen vises bare."
L.SET_HINT_BUILTIN = "Volumet på denne lyden følger kanalen i spillinnstillingene."
L.SET_HINT_LEVELS = "Fem trinn fra svak til høy. Kanalens glidebryter i spillinnstillingene virker i tillegg."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guild og venner"  -- [max 18]
L.TIP_HELP_BUTTON = "Slik virker boken"
L.VIEW_HUNT = "Jaktlisten"  -- [max 13]
L.VIEW_BY_KILLER = "Per morder"  -- [max 13]
L.VIEW_BY_MATE = "Per medlem"  -- [max 13]
L.SRC_ALL = "Alle"  -- [max 12]
L.SRC_GUILD = "Guild"  -- [max 12]
L.SRC_FRIENDS = "Venner"  -- [max 12]
L.SORT_HIDE_PARDONED = "Skjul benådede"  -- [max 24]
L.SORT_SHOW_PARDONED = "Vis benådede"  -- [max 24]
L.SEARCH_ADD = "Søk eller skriv inn …"  -- [max 26]
L.SEARCH_SHORT = "Søk …"  -- [max 10]
L.SEARCH_KILLER = "Finn morder …"  -- [max 15]
L.SEARCH_JOURNAL = "Morder eller sted …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Lukk alle"
L.TIP_EXPAND_ALL = "Åpne alle"
L.STATUS_NO_PLATES = "Fiendtlige navneskilt er av: alarmen ser bare mål og mus."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|ettersøkt|ettersøkte}"
L.MM_UNSOLVED = "{count} {count|uløst|uløste}"
L.MM_ALERT_OFF = "Alarmen er av (midtklikk)"
L.MM_CLICK = "Klikk: boken · Høyreklikk: Husregler"
L.MM_MIDDLE = "Midtklikk: alarm på/av"
L.MM_DRAG = "Dra: flytt langs kanten av minimapet"
L.MM_CHAT_ALERT_ON = "Alarm på."
L.MM_CHAT_ALERT_OFF = "Alarm av."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GUILDFIENDE NR. 1"  -- [max 25]
L.STAMP_HUNT = "FRITT VILT"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} ga seg ut for å være vennen din {friend}: avvist."
L.FRIENDS_SHORT_IMPOSTOR = "Fremmed avvist"  -- [max 22]
L.ALERT_LEVEL = "Nivå {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "sist nivå {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Nivå ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · på jaktlisten ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nytt mål|nye mål}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nytt på jaktlisten"
L.OPT_F_ANNOUNCEHUNT = "Meld fra om jaktlisten: nye og felte"  -- [max 44]
L.SET_HUNT_EXPIRE = "Utlysninger utløper etter"  -- [max 30]
L.SET_EXPIRE_NEVER = "Aldri"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dag|dager}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Tøm venneboken"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Vil du tømme venneboken på denne maskinen?\nJaktlisten i den forsvinner også, dine egne utlysninger blir."
L.CONFIRM_CALLOFF_ALL = "Vil du blåse av alle utlysningene dine?\nGuild og venner får vite det litt etter litt."
L.CONFIRM_CALLOFF_ALL_OK = "Blås av alle"  -- [max 14]
L.ACT_CALLOFF_ALL = "Blås av alle mine"  -- [max 24]
L.ACT_HUNT_HIDE = "Skjul for meg"  -- [max 19]
L.ACT_HUNT_SHOW = "Vis igjen"  -- [max 19]
L.HUNT_ROW_HIDDEN = "skjult for deg"
L.HUNT_ROW_CALLS = "{count} {count|utlysning|utlysninger}: {names}"
L.POSTER_ON_HUNTLIST = "På jaktlisten ({names})"
L.REL_SELF = "Du kan ikke lyse ut jakt på deg selv."
L.REL_MATE = "Det er en av dine egne (guild eller venner med DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Hvem er vennen din {friend}: {a} eller {b}? Velg."
L.FRIENDS_SHORT_CONFLICT = "Uklar venn"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "To spillere sier at de er vennen din {friend}: {a} og {b}. Til du velger, tar boken ikke imot noe fra noen av dem. Guild og venner, visning Per medlem: høyreklikk på navnet."
L.MEMBER_CONFLICT = "Høyreklikk: er dette vennen din?"  -- [max 40]
L.ACT_TIE_MINE = "Min venn: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Koble fra"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Koble {name} fra vennelisten din?\nDet navnet har ført inn i venneboken, slettes; neste melding under dette fornavnet kobles på nytt."
L.CHAT_FRIENDS_TIES = "Koblede fulle navn (* = første kontakt, ikke bekreftet ennå): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Navn [Etternavn]> <gull>  lys ut en egen dusør (uten gull: trekk den tilbake)"
L.CHAT_WHO_BOUNTY = "På hvem? /dn bounty <Navn> <gull>"
L.CHAT_BOUNTY_SET = "{name}: du har lyst ut {gold} gull i dusør. Guild og venner med DeathNote ser det."
L.CHAT_BOUNTY_OFF = "{name}: dusøren din er trukket tilbake."
L.CHAT_BOUNTY_NONE = "Du har ingen egen dusør på {name}."
L.CHAT_BOUNTY_BAD = "Dusør: et helt antall gull, 1 til 99999 (0 trekker den tilbake)."
L.CHAT_BOUNTY_CAP = "Ingen dusør: maks {count} egne."
L.CHAT_BOUNTY_OURS = "Ingen dusør på deg selv eller dine egne (guild eller venner med DeathNote)."
L.ACT_BOUNTY = "Lys ut dusør"  -- [max 24]
L.ACT_UNDO = "Angre"  -- [max 19]
L.ACT_REVENGE_TAKE = "Trekk fra én hevn"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, lyst ut av deg"
L.POSTER_BOUNTY_BY = "{gold}, lyst ut av {name}"
L.POSTER_BOUNTY_MANY = "Dusør {gold}: {names}"
L.POSTER_AVENGED = "Hevnet av {names}"
L.ROW_AVENGED = "hevnet {times}"
L.BOUNTY_TIP_HEAD = "Din egen dusør i gull"
L.BOUNTY_TIP_RULES = "Et helt tall, 1 til 99999. Tomt eller 0: tilbake til bokens verdi. Enter setter, Esc avbryter."
L.BOUNTY_TIP_PROMISE = "Guild og venner med DeathNote ser den. Bare et løfte: dere gjør opp seg imellom."
L.BOUNTY_TIP_CLICK = "Klikk: lys ut en egen dusør"
L.CHAT_AVENGED = "{name} felte {killer} for deg."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: du har lyst ut {gold} gull i dusør."
L.CHAT_BOUNTY_UNKNOWN = "{name} står ikke i noen av bøkene dine. Dusør bare på et navn fra en bok, slik spillet viser det: fornavn og etternavn."
L.CHAT_BOUNTY_LIST = "Dusørene dine ({count} av {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Du har ikke lyst ut noen dusør."
-- <<< BOOK
-- >>> REPUTE (1.3.0): English placeholders, to be translated (keys as in enUS.lua) ---------------------------------
L.REPUTE_LINE = "Rank {tier} · Path: {path}"
L.PATH_R = "Infamy"
L.PATH_E = "Honour"
L.PATH_J = "Hunt"
L.PATH_S = "Protection"
L.PATH_NONE = "unwritten"
-- <<< REPUTE
end)
