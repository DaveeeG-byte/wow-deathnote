-- DeathNote: Svenska (svSE). No official Swedish client: words as Swedish players use them (guild, dungeons).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.svSE), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Glossary: bok, guildboken, vänboken, mördare, guildkompis, vän, Efterlysta, Olösta fall, Dödslogg, Husregler,
-- affisch, stämpel, belöning, notering, observation, stryka, benåda, hämnd, misstänkt, jaktlistan, utlysa jakt,
-- utlysning, blåsa av jakten, fälld, Spara boken, Läs in boken.
--
-- TOC-Notes: Dödslista för PvP i öppna världen: minns vem som dödade dig och varnar när hen är nära.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("svSE")) then return end

Locale.Register("svSE", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Efterlysta"    -- [max 16]
L.TAB_UNSOLVED = "Olösta fall"   -- [max 16]
L.TAB_DEATHLOG = "Dödslogg"      -- [max 16]
L.TAB_GUILD    = "Guild"         -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Husregler"       -- [max 24]
L.HEAD_HELP  = "Bruksanvisning"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Bok"            -- [max 14]
L.SHEET_ALERT = "Larm"           -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "SAMHÄLLSFIENDE NR 1"  -- [max 24]
L.STAMP_REVENGE  = "HÄMND UTKRÄVD"        -- [max 16]
L.STAMP_PARDONED = "BENÅDAD"              -- [max 16]
L.STAMP_SUSPECT  = "MISSTÄNKT"            -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "SAMHÄLLSFIENDE NR 1 SIKTAD"  -- [max 30]
L.ALERT_SIGHTED         = "SAMHÄLLSFIENDE SIKTAD"       -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "MISSTÄNKT SIKTAD"            -- [max 30]
L.ALERT_TITLE_GUILD     = "GUILDFIENDE SIKTAD"          -- [max 30]
L.ALERT_TITLE_FRIENDS   = "VÄNNERNAS MÖRDARE SIKTAD"    -- [max 30]
L.ALERT_TITLE_HUNT      = "MÅL PÅ JAKTLISTAN"           -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "är misstänkt"
L.ALERT_LINE_KILLED         = "har dödat dig {times}"
L.ALERT_LINE_KILLED_ASSISTED = "har dödat dig {times}, medverkat {assists}"
L.ALERT_LINE_ASSISTED       = "har medverkat till din död {times}"
L.ALERT_LINE_MANUAL         = "är inskriven för hand"
L.ALERT_LINE_LAST    = "{text}, senast {time}"
L.ALERT_LINE_IN      = "{text} i {zone}"
L.ALERT_LINE_REVENGE = "{text}. Hämnd: {times}"
L.ALERT_HINT_CLOSE  = "Högerklick: stäng"                           -- [max 44]
L.ALERT_HINT_COMBAT = "Ta som mål först efter striden"              -- [max 44]
L.ALERT_HINT_TARGET = "Klick: ta som mål  ·  Högerklick: stäng"     -- [max 44]
L.ALERT_MORE = "+{count} till"           -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "står i guildboken"
L.GUILD_LINE_IN_FRIENDS = "står i vänboken"
L.GUILD_LINE_LISTED_BY  = "står i boken hos {names}"
L.GUILD_LINE_KILLED_GUILD   = "har dödat guildkompisar {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "har dödat vänner {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "har dödat guildkompisar och vänner {kills}×"
L.GUILD_LINE_LAST = "{text}, senast {name}"
L.HUNT_LINE_BY       = "jakt utlyst av {names}"
L.HUNT_LINE_RELEASED = "på jaktlistan"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "misstänkt"
L.TALLY_MANUAL   = "inskriven för hand"
L.TALLY_NONE     = "inget dåd än"
L.TALLY_KILLED   = "dödat dig {times}"
L.TALLY_ASSISTED = "medverkat {times}"
L.PLACE_UNKNOWN  = "okänd plats"
L.GKILLS_CAP     = "minst {count}"
L.NAMELIST_MORE  = "{names} och {count} till"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d/%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%Y-%m-%d %H:%M"
L.TIME_FMT_DAY       = "%d/%m"
L.TIME_FMT_DAY_YEAR  = "%y-%m-%d"
L.TIME_NEVER   = "aldrig"
L.TIME_JUST    = "nyss"
L.TIME_MINUTES = "{count} min sen"        -- [max 14]
L.TIME_HOURS   = "{count} tim sen"        -- [max 14]
L.TIME_DAYS    = "{count} {count|dag|dagar} sen"  -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}k"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Hört från {count} {count|guildkompis|guildkompisar} med DeathNote."
L.HEALTH_NOGUILD = "Du är inte med i någon guild, inget delas."
L.HEALTH_OFF     = "Delning är avstängd."
L.HEALTH_SHORT_NOGUILD = "Ingen guild"    -- [max 18]
L.HEALTH_SHORT_OFF     = "Delning av"     -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Spärrad"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Nekad"          -- [max 18]
L.HEALTH_SHORT_HOLD    = "Väntar"         -- [max 18]
L.HEALTH_SHORT_ASKED   = "Begärd"      -- [max 18]
L.HEALTH_SHORT_FAIL    = "Fungerar inte"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Inget ljud"        -- [max 16]
L.SOUND_RAIDWARNING = "Raidvarning"       -- [max 16]
L.SOUND_BELL        = "Klocka"            -- [max 16]
L.SOUND_GONG        = "Gonggong"          -- [max 16]
L.SOUND_HEARTBEAT   = "Hjärtslag"         -- [max 16]
L.SOUND_FEATHER     = "Fjäderpenna"       -- [max 16]
L.SOUND_SIREN       = "Siren"             -- [max 16]
L.CHANNEL_MASTER    = "Huvudvolym"        -- [max 16]
L.CHANNEL_SFX       = "Effekter"          -- [max 16]
L.CHANNEL_DIALOG    = "Dialog"            -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} står nu i boken."
L.CHAT_REMOVED   = "{name} är struken ur boken."
L.CHAT_SYNC_WAIT = "Synkade nyss. Försök igen om {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Inga namn än."
L.EMPTY_WANTED_SUB  = "Gå ut lite, för en gångs skull."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  öppna/stäng boken"
L.HELP_ADD      = "/dn add <Namn [Efternamn]>  skriv in en mördare för hand"
L.HELP_DEL      = "/dn del <Namn [Efternamn]>  stryk en mördare ur boken"
L.HELP_QUIET    = "/dn quiet  larm av/på"
L.HELP_TEST     = "/dn test  visa ett testlarm"
L.HELP_GUILD    = "/dn guild  guildboken: status och vilka guildkompisar som har DeathNote"
L.HELP_FRIENDS  = "/dn friends  vänboken: status och vilka vänner som har DeathNote"
L.HELP_SYNC     = "/dn sync  synka guildboken och vänboken nu"
L.HELP_HUNT     = "/dn hunt <Namn [Efternamn]>  utlys jakt (utan namn: visa jaktlistan)"
L.HELP_CALLOFF  = "/dn calloff <Namn [Efternamn]>  blås av din egen jakt"
L.HELP_LANG     = "/dn lang <kod>  bokens språk (enUS, deDE, svSE ...), efter /reload"
L.HELP_THEME = "/dn theme <namn>  bokens pärm, efter /reload"
L.HELP_PROBE    = "/dn probe  felsökning: vad spelet berättar för boken"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  felsökning, testa även stridsloggen"
L.HELP_DEBUG    = "/dn debug  felsökning: logga varje död i detalj (på/av)"
L.HELP_HELP     = "/dn help  den här hjälpen"
L.HELP_SILENT_ZONES = "I dungeons, battlegrounds och arenor håller boken tyst av sig själv."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "på"
L.WORD_OFF = "av"
L.CHAT_WHO_ADD  = "Vem då? /dn add <Namn>"
L.CHAT_WHO_DEL  = "Vem då? /dn del <Namn>"
L.CHAT_WHO_CALLOFF = "Vem då? /dn calloff <Namn>"
L.CHAT_BAD_NAME = "Ogiltigt namn."
L.CHAT_NOT_IN_BOOK = "Inte i boken: {name}"
L.CHAT_ALARM_ON  = "Larm på."
L.CHAT_ALARM_OFF = "Larm av."
L.CHAT_DEBUG = "Felsökningslogg {state}."
L.CHAT_UNKNOWN_CMD = "Okänt kommando. Hjälp: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Guildboken är inte laddad."
L.CHAT_NO_GUILD = "Du är inte med i någon guild (eller så vet spelet inte om det än)."
L.CHAT_GUILD_STATE = "Guild {guild}: dela {share}, ta emot {receive}."
L.CHAT_GUILD_BOOK = "Guildboken: {enemies} mördare ({listed} bara inskrivna för hand), {deeds} {deeds|dåd|dåd}, {foreign} av dem har dödat andra guildkompisar. Dela handinskrivna: {manual}."
L.CHAT_STATE_OK   = "Status: {text}"
L.CHAT_STATE_WARN = "Obs: {text}"
L.CHAT_NO_MATES   = "Inget svar från någon guildkompis med DeathNote än."
L.CHAT_HAVE_DN      = "Har DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Har DeathNote: {names} och {count} till"
L.CHAT_SYNC_ASKED = "Synk begärd. Svaren kommer inom några sekunder."
L.CHAT_SYNC_FAIL  = "Synken fungerar inte: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "ingen guild, eller så är delning av."
L.CHAT_FRIENDS_NOT_LOADED = "Vänboken är inte laddad."
L.CHAT_FRIENDS_STATE = "Vänner: dela {share}, {online} av {total} online."
L.CHAT_FRIENDS_BOOK  = "Vänboken: {enemies} mördare ({listed} bara inskrivna för hand), {deeds} {deeds|dåd|dåd}."
L.CHAT_NO_FRIENDS    = "Inget svar från någon vän med DeathNote än."
L.CHAT_HUNT_NOT_LOADED = "Jaktlistan är inte laddad."
L.CHAT_HUNT_UNKNOWN = "Okänd: {name}. Ta med efternamnet också, så som namnet står i spelet."
L.CHAT_HUNT_CAP     = "Kan inte utlysa jakt: högst {own} egna utlysningar och {targets} mål per lista."
L.CHAT_HUNT_NOWHERE = "Kan inte utlysa jakt just nu: ingen guild, och delning med vänner är av."
L.CHAT_HUNT_BOTH    = "{name} står på jaktlistan, för guild och vänner."
L.CHAT_HUNT_GUILD   = "{name} står på jaktlistan, för guilden."
L.CHAT_HUNT_FRIENDS = "{name} står på jaktlistan, för dina vänner."
L.CHAT_CALLED_OFF   = "Jakten är avblåst: {name}."
L.CHAT_NO_OWN_CALL  = "Du har ingen egen utlysning på {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Språk nu: {lang}. Ändra: /dn lang <kod>"
L.CHAT_LANG_LIST    = "Koder: {codes}"
L.CHAT_LANG_BAD     = "Okänt språk: {code}"
L.CHAT_LANG_SET     = "Språk: {lang}."
L.CHAT_LANG_RELOAD  = "Språk: {lang}. Gäller efter /reload."
L.CHAT_THEME_CURRENT = "Pärm nu: {theme}. Ändra: /dn theme <namn>"
L.CHAT_THEME_LIST = "Pärmar: {themes}"
L.CHAT_THEME_BAD = "Okänd pärm: {name}"
L.CHAT_THEME_SET = "Pärm: {theme}."
L.CHAT_THEME_RELOAD = "Pärm: {theme}. Gäller efter /reload."
L.THEME_NOTEBOOK = "Den svarta boken"
L.THEME_HARBOR = "Kaparboken"
L.THEME_TRADE = "Verkstaden"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Boken är redo. Den som dödar dig i öppna världen hamnar i den. Öppna den med /dn eller minimap-knappen."
L.WELCOME_PLATES = "Fiendens namnskyltar är avstängda. Utan dem ser larmet bara ditt mål."
L.WELCOME_SHARE = "Guild och vänner som har DeathNote läser med. Noteringar och misstankar stannar hos dig."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "I BOKEN:"
L.TIP_HUNT      = "JAKTLISTAN:"
L.TIP_GUILDBOOK = "GUILDBOKEN:"
L.TIP_PARDONED  = "benådad"
L.TIP_RANK      = "rang {rank}"
L.TIP_REVENGE   = "hämnd {times}"
L.TIP_LISTED_BY = "i boken hos {names}"
L.TIP_NOTE      = "Notering: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Klick: öppna · Högerklick: bort"
L.BANNER_NEW          = "NYTT NAMN"            -- [max 24]
L.BANNER_NEW_LINE     = "står nu i boken"
L.BANNER_AGAIN        = "NU IGEN"              -- [max 24]
L.BANNER_AGAIN_LINE   = "har dödat dig igen, {count} gånger nu"
L.BANNER_SUSPECT      = "MISSTÄNKT"            -- [max 24]
L.BANNER_SUSPECT_LINE = "är misstänkt, red ut det i boken"
L.BANNER_UNCLEAR      = "OKLAR MÖRDARE"        -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|kandidat|kandidater}"
L.BANNER_UNCLEAR_LINE = "Klick: välj mördaren under Olösta fall"
L.BANNER_REVENGE      = "VEDERGÄLLNING"        -- [max 24]
L.BANNER_REVENGE_LINE = "Hämnd utkrävd ({count}×)"
L.BANNER_GUILD        = "GUILD"                -- [max 24]
L.BANNER_FRIENDS      = "VÄNNER"               -- [max 24]
L.BANNER_KILLED_BY    = "dödades av {name}"
L.BANNER_HUNT         = "JAKTLISTAN"           -- [max 24]
L.BANNER_BAGGED       = "fälld av {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Delning är avstängd (Husregler, fliken Guild)."
L.SYNC_FRIENDS_OFF = "Delning med vänner är av."
L.SYNC_NOBODY      = "Ingen guild och inga vänner att dela med."
L.SYNC_SHORT_NOBODY = "Inget delas"           -- [max 18]
L.SYNC_PREFIX      = "Spelet tillåter ingen mottagning. Logga in igen, det hjälper."
L.SYNC_SHORT_PREFIX = "Tar inte emot"         -- [max 18]
L.SYNC_BLOCKED     = "Realmen spärrar sändning. Dela vidare med Spara boken."
L.SYNC_SHORT_BLOCKED = "Sändning spärrad"     -- [max 22]
L.SYNC_FAILING     = "Sändningen misslyckas just nu, försöker igen."
L.SYNC_SHORT_FAILING = "Sändning hackar"      -- [max 18]
L.SYNC_HOLD        = "Sändningen väntar {wait}."
L.SYNC_HOLD_INSTANCE = "tills du lämnar instansen"
L.SYNC_HOLD_COMBAT   = "tills du är ur strid"
L.SYNC_HOLD_LOCKDOWN = "tills chatten är fri igen"
L.SYNC_HOLD_AGAIN    = "tills det fungerar igen"
L.SYNC_HOLD_SHORT_INSTANCE = "Väntar: instans"    -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Väntar: strid"      -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Väntar: chatt"      -- [max 18]
L.SYNC_QUIET       = "Skickat, men ännu inget svar från någon guildkompis med DeathNote."
L.SYNC_READY       = "Redo. Ännu inget svar från någon guildkompis med DeathNote."
L.SYNC_RUNNING     = "Igång: {count} {count|guildkompis|guildkompisar} med DeathNote."
L.SYNC_RUNNING_ALL = "Igång: {count} med DeathNote i guild och bland vänner."
L.FRIENDS_OFF      = "Delning med vänner är av (Husregler, fliken Guild)."
L.FRIENDS_BLOCKED  = "Realmen spärrar viskningar. Vänner får inget."
L.FRIENDS_SHORT_BLOCKED = "Viskningar spärrade"  -- [max 22]
L.FRIENDS_FAILING  = "Viskningarna misslyckas just nu, försöker igen."
L.FRIENDS_SHORT_FAILING = "Viskningar hackar"    -- [max 18]
L.FRIENDS_NONE_LISTED = "Inga vänner på vänlistan."
L.FRIENDS_NONE_ONLINE = "Ingen vän online just nu."
L.FRIENDS_SHORT_NONE_ONLINE = "Ingen vän online"  -- [max 18]
L.FRIENDS_QUIET    = "Frågat, men ännu inget svar från någon vän med DeathNote."
L.FRIENDS_READY    = "Redo. Ännu inget svar från någon vän med DeathNote."
L.FRIENDS_HOLD     = "Sändning till vänner väntar tills det fungerar igen."
L.FRIENDS_RUNNING  = "Igång: {count} {count|vän|vänner} med DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Hämtad från guildboken (har dödat guildkompisar {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Databasen är inte laddad."
L.IMPORT_NO_TEXT    = "Ingen text."
L.IMPORT_NO_HEADER  = "Första raden saknas (den börjar med {header}). Kopiera hela texten."
L.IMPORT_NOT_EXPORT = "Ingen DeathNote-export (rubrikraden saknas eller fel version)."
L.IMPORT_TOO_LONG   = "För många rader (högst {count})."
L.IMPORT_BAD_KEY    = "Rad {line}: ogiltig nyckel."
L.IMPORT_BAD_TIME   = "Rad {line}: ogiltig tid."
L.IMPORT_BROKEN     = "Rad {line} är ofullständig eller trasig (avklippt text?). Inget har lästs in."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "ja"
L.WORD_NO  = "nej"
L.PROBE_HEAD = "Sond: {apis}/{apisAll} gränssnitt finns, {events}/{eventsAll} händelser kan registreras."
L.PROBE_MISSING = "Saknas: {list}"
L.PROBE_NOT_REGISTERABLE = "Kan inte registreras: {list}"
L.PROBE_SOURCES = "Recap nu: {recap} · Meter: {meter} · Stridslogg: {clog}"
L.PROBE_READABLE = "läsbar"
L.PROBE_DEAD = "död"
L.PROBE_PLATES = "Fiendens namnskyltar: {plates} · Öppen värld: {open}"
L.PROBE_PLATES_OFF = "AV (bara mål och muspekare hittar spelare)"
L.PROBE_TARGET = "Mål: namn={name} GUID={guid} klass={class} fientlig={enemy} siktar på mig={me}"
L.PROBE_GUILD = "Guild: prefix {prefix} · sändning {send} · senaste returvärde {result} · skickat {sent}, mottaget {received}, kastat {dropped}"
L.PROBE_REGISTERED = "registrerad"
L.PROBE_NOT_REGISTERED = "INTE registrerad ({result})"
L.PROBE_POSSIBLE = "möjlig"
L.PROBE_ABSENT = "saknas"
L.PROBE_WAITS = " · väntar: {why}"
L.PROBE_LISTED = "Handinskrivna (M): skickat {sent}, mottaget {received}, kastat {dropped} · strukna (X): skickat {usent}, mottaget {ureceived}, kastat {udropped}"
L.PROBE_GUILDBOOK = "Guildboken: {text}"
L.PROBE_SAVED = "Sparat i DeathNoteDB.probe (i filen efter /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Senaste"  -- [max 14]
L.SORT_NAME = "Namn"  -- [max 14]
L.SORT_SEEN = "Sedd"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Den som dödar dig i öppna världen hamnar här. Helt av sig själv."
L.EMPTY_OPEN_HEAD = "Inget olöst."
L.EMPTY_JOURNAL_HEAD = "Aldrig dött än."
L.EMPTY_JOURNAL_SUB = "Respekt. Eller lögn."
L.EMPTY_NOGUILD_HEAD = "Ingen guild."
L.EMPTY_NOGUILD_SUB = "Man kan dö ensam också."
L.EMPTY_GUILDOFF_HEAD = "Guildboken är stängd."
L.EMPTY_GUILDOFF_SUB = "Delning är av. Husreglerna vet var."
L.EMPTY_GUILDNIL_HEAD = "Inget har hörts från guilden än."
L.EMPTY_GUILDNIL_SUB = "Din bok skickas ut så fort en guildkompis har DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Inget i guildboken än."
L.EMPTY_GUILDQUIET_SUB = "Dina guildkompisar har haft lugnt hittills."
L.EMPTY_FRIENDSOFF_HEAD = "Vänboken är stängd."
L.EMPTY_FRIENDSOFF_SUB = "Delning med vänner är av. Husreglerna vet var."
L.EMPTY_FRIENDSNIL_HEAD = "Inget svar från någon vän med DeathNote än."
L.EMPTY_FRIENDSNIL_SUB = "Din bok skickas ut så fort en vän har DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Inget från dina vänner än."
L.EMPTY_FRIENDSQUIET_SUB = "Dina vänner har haft lugnt hittills."
L.EMPTY_NOBODY_HEAD = "Ingen guild, inga vänner."
L.EMPTY_NOBODY_SUB = "Man kan dö ensam också."
L.EMPTY_NOBODY_HINT = "När guildkompisar eller vänner från din vänlista har DeathNote visar den här sidan vad som händer dem."
L.EMPTY_SHAREDNIL_HEAD = "Inget svar från någon med DeathNote än."
L.EMPTY_SHAREDNIL_SUB = "Din bok skickas ut så fort guildkompisar eller vänner har DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Inget här än."
L.EMPTY_SHAREDQUIET_SUB = "Guild och vänner har haft lugnt hittills."
L.EMPTY_HUNT_HEAD = "Jaktlistan är tom."
L.EMPTY_HUNT_SUB = "På affischen: Utlys jakt."
L.EMPTY_HUNT_HINT = "Eller i chatten: /dn hunt Namn Efternamn. Alla i din guild och dina vänner ser det."
L.EMPTY_SEARCH_HEAD = "Ingen träff."
L.EMPTY_SEARCH_SUB = "Enter skriver in namnet i boken."
L.EMPTY_SEARCHRO_HEAD = "Ingen träff."
L.EMPTY_SEARCHRO_SUB = "Ibland hjälper en annan stavning."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "BOKEN"  -- [max 12]
L.MANUAL_BOOK = "Den som dödar dig i öppna världen skrivs in av sig själv. Ett klick på meddelandet efter din död öppnar mördarens sida."
L.MANUAL_WANTED_HEAD = "EFTERLYSTA"  -- [max 12]
L.MANUAL_WANTED = "Dina mördare, den värsta först. Ett klick visar affischen med dåd och notering. Benådade står överstrukna sist."
L.MANUAL_UNSOLVED_HEAD = "OLÖSTA FALL"  -- [max 13]
L.MANUAL_UNSOLVED = "När det inte var klart vem som gjorde det väntar fallet här. Ett klick på ett namn avgör vem mördaren är."
L.MANUAL_ALERT_HEAD = "LARM"  -- [max 12]
L.MANUAL_ALERT = "När en mördare dyker upp som namnskylt, mål eller under muspekaren säger boken till. Ett klick tar hen som mål, i strid först efteråt."
L.MANUAL_ADD_HEAD = "SKRIVA IN"  -- [max 12]
L.MANUAL_ADD = "Skriv ett namn i sökfältet, Enter. Högerklicka på en rad: notera hämnd, benåda, stryk."
L.MANUAL_GUILD_HEAD = "GUILD"  -- [max 12]
L.MANUAL_GUILD = "Guildkompisar och vänner med DeathNote ser dina bekräftade dödsfall och handinskrivna namn. Affischen eller /dn hunt Namn: utlys jakt. Klicka på belöningen: utlys din egen, ett löfte ni gör upp sinsemellan."
L.MANUAL_SHARE_HEAD = "DELA VIDARE"  -- [max 12]
L.MANUAL_SHARE = "Husregler, Spara boken: en text att kopiera, för alla utan DeathNote."
L.MANUAL_QUIET_HEAD = "TYST"  -- [max 12]
L.MANUAL_QUIET = "I dungeons och battlegrounds håller larmet tyst. Annars: mittenklicka på minimap-knappen eller /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Vill du verkligen stryka {name} ur boken?\nAlla dåd och noteringen försvinner."
L.CONFIRM_DELETE_OK = "Stryk"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Vill du tömma guildboken på den här datorn?\nDess jaktlista följer med, dina egna utlysningar stannar.\nDin egen bok förblir som den är."
L.CONFIRM_GUILD_CLEAR_OK = "Töm"  -- [max 14]
L.CONFIRM_CANCEL = "Avbryt"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GULD"  -- [max 14]
L.BOUNTY_SILVER = "{count} SILVER"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"  -- no-break space (a plain space counts as empty in the test)
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Bekräfta"  -- [max 19]
L.ACT_DISMISS = "Avfärda"  -- [max 19]
L.ACT_HUNT_AGAIN = "Jaga igen"  -- [max 19]
L.ACT_REVENGE = "Notera hämnd"  -- [max 19]
L.ACT_PARDON = "Benåda"  -- [max 19]
L.ACT_STRIKE = "Stryk"  -- [max 19]
L.ACT_OPEN_OWN = "Öppna i boken"  -- [max 19]
L.ACT_ADOPT = "Till min bok"  -- [max 19]
L.ACT_CALLOFF = "Blås av jakten"  -- [max 19]
L.ACT_RELEASE = "Utlys jakt"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "sedd {time}"
L.ROW_NOT_SEEN = "inte siktad än"
L.ROW_PARDONED = "benådad"
L.ROW_SUSPECT = "Misstänkt"
L.MARK_REVENGE = "HÄMND {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Oklar mördare"
L.MARK_CANDIDATES = "{count} {count|KANDIDAT|KANDIDATER}"  -- [max 16]
L.MARK_SUSPECT = "MISSTÄNKT"  -- [max 16]
L.ROW_NO_PLAYER = "Ingen spelare"
L.ROW_UNCLEAR = "Oklart hur"
L.MARK_NOT_COUNTED = "RÄKNAS INTE"  -- [max 16]
L.ROW_LISTED_BY = "inskriven av {names}"
L.ROW_GKILLED = "dödat {kills}×"
L.ROW_VICTIMS = "{count} {count|offer|offer}"
L.ROW_LAST = "senast {text}"
L.MARK_IN_BOOK = "I BOKEN"  -- [max 16]
L.MEMBER_KILLERS = "{count} mördare"  -- [max 14]
L.MEMBER_DEATHS = "{count} dödsfall"  -- [max 12]
L.MEMBER_LISTED = "{count} för hand"  -- [max 14]
L.MEMBER_ME = "det här ser de andra av dig"
L.MEMBER_NOTHING = "inget delat än"
L.MEMBER_LAST_DIED = "dog senast {time}"
L.MARK_YOU = "du"  -- [max 16]
L.MARK_FRIEND = "VÄN"  -- [max 16]
L.MARK_BOTH = "GUILDKOMPIS, VÄN"  -- [max 20]
L.MARK_TAKEN_DOWN = "FÄLLD {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DÖD ELLER LEVANDE"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "DÅD"  -- [max 14]
L.POSTER_NOTE = "NOTERING"  -- [max 8]
L.POSTER_BOUNTY = "BELÖNING"  -- [max 12]
L.ROLE_ASSIST = "medverkade"  -- [max 14]
L.ROLE_SUSPECT = "misstänkt"  -- [max 14]
L.POSTER_LEVEL = "Nivå {level}"
L.POSTER_GUILD = "Guild: {guild}"
L.POSTER_LAST_SEEN = "Senast sedd {time}"
L.POSTER_NOT_SEEN = "Inte siktad än"
L.POSTER_ONLY_SUSPECT = "Bara misstänkt, inget bevisat dåd."
L.POSTER_NO_DEEDS = "Inga dåd noterade."
L.TIP_LISTED_AT = "Inskriven {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Dödsorsak: {spell}"
L.TIP_VICTIM = "Offer: {name}"
L.TIP_VICTIM_LEVEL = "Offer: {name} (nivå {level})"
L.TIP_KILLER_LEVEL = "Mördarens nivå: {level}"
L.TIP_ASSISTS = "Medverkade: {names}"
L.TIP_ROLE_ASSIST = "Medverkade, gav inte dödsstöten."
L.TIP_ROLE_SUSPECT = "Bara misstänkt, inte bevisat."
L.MORE_LINE = "… och {count} till"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GUILDBOKEN"  -- [max 24]
L.POSTER_IN_BOOK_OF = "I boken hos: {names}"
L.POSTER_SEEN = "Sedd {time}"
L.POSTER_SEEN_BY = "Sedd {time} av {name}"
L.TIP_IN_BOOK_OF = "I boken hos"
L.POSTER_REMARK = "ANMÄRKNING"  -- [max 12]
L.POSTER_BY_HAND = "INSKRIVEN FÖR HAND"  -- [max 22]
L.POSTER_VICTIMS = "OFFER"  -- [max 12]
L.POSTER_LISTED = "INSKRIVEN"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Inskriven för hand."
L.POSTER_NO_DEEDS_SENT = "Inga dåd följde med."
L.POSTER_NONE_KNOWN = "inga kända"
L.POSTER_NO_NAMES = "inga namn följde med"
L.TIP_VICTIMS = "Offer"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Utlyst {time}"
L.HUNT_REASON = "Skäl: {reason}"
L.POSTER_HUNTLIST = "JAKTLISTAN"  -- [max 24]
L.POSTER_RELEASED_N = "jakt utlyst {times}"
L.POSTER_RELEASED_BY = "Utlyst av {names}"
L.POSTER_TAKEN_DOWN = "FÄLLD"  -- [max 12]
L.POSTER_NOT_YET = "INTE ÄN"  -- [max 18]
L.POSTER_CALLS = "UTLYST"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Ingen längre."
L.POSTER_LAST = "SENAST"  -- [max 13]
L.POSTER_TAKEN_BY = "fälld av {name}, {time}"
L.POSTER_TAKEN_NOBODY = "inte fälld av någon än"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Dödsfall"  -- [max 20]
L.CASE_ASSISTS = "MEDVERKADE"  -- [max 24]
L.CASE_PICK = "AVGÖR VEM MÖRDAREN ÄR"  -- [max 24]
L.CASE_NOT_COUNTED = "Räknas inte (instans, battleground eller duell)"
L.CASE_KILLER = "MÖRDARE"  -- [max 24]
L.CASE_KILLER_SUSPECT = "MÖRDARE (MISSTÄNKT)"  -- [max 24]
L.CASE_CLICK_NAME = "Klicka på namnet för att öppna affischen."
L.CASE_GONE = "Står inte längre i boken."
L.CASE_KILLER_UNCLEAR = "OKLAR MÖRDARE"  -- [max 24]
L.CASE_SEVERAL = "Flera kan ha gjort det. Vems namn ska in i boken?"
L.CASE_NOBODY = "Ingen kan ha gjort det."
L.CASE_HOW = "VAD SOM HÄNDE"  -- [max 24]
L.CASE_PVE = "Ett monster eller världen själv. Inget fall för boken."
L.CASE_UNCLEAR = "Oklart"
L.CASE_DARK = "Kriminalteknikerna famlar i mörkret."
L.TIP_MORE_CANDIDATES = "Fler kandidater"
L.CASE_SOURCE_SUSPECT = "Misstänkt: hade dig som mål strax innan du dog."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-rad över mördare"  -- [max 44]
L.OPT_MINIMAP = "Visa minimap-knappen"  -- [max 44]
L.OPT_ALERT = "Larm när en mördare dyker upp"  -- [max 44]
L.OPT_FLASH = "Blinka skärmkanten röd"  -- [max 44]
L.OPT_SUSPECTS = "Rapportera misstänkta också"  -- [max 44]
L.OPT_DEATHMSG = "Meddelande efter en PvP-död"  -- [max 44]
L.OPT_G_SHARE = "Dela mina dödsfall"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Dela handinskrivna namn"  -- [max 44]
L.OPT_G_RECEIVE = "Ta emot guildboken"  -- [max 44]
L.OPT_G_ALERT = "Varna för mördare från guildboken"  -- [max 44]
L.OPT_G_ALERTLISTED = "Varna även för handinskrivna namn"  -- [max 44]
L.OPT_G_ANNOUNCE = "Meddela när en guildkompis dödas"  -- [max 44]
L.OPT_G_SIGHTINGS = "Dela observationer"  -- [max 44]
L.OPT_F_SHARE = "Dela med guilden"  -- [max 44]
L.OPT_F_FRIENDS = "Dela med vänner"  -- [max 44]
L.OPT_F_ALERT = "Varna för mördare från guild och vänner"  -- [max 44]
L.OPT_F_ALERTHUNT = "Varna för mål på jaktlistan"  -- [max 44]
L.OPT_F_ANNOUNCE = "Meddela när guildkompisar eller vänner dör"  -- [max 44]
L.OPT_F_SIGHTINGS = "Dela observationer med guild och vänner"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guild"  -- [max 14]
L.SET_BOOK_SIZE = "Bokens storlek"  -- [max 34]
L.SET_LANGUAGE = "Språk"  -- [max 16]
L.SET_LANG_AUTO = "Automatiskt"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Gäller efter omladdning."  -- [max 28]
L.SET_LANG_RELOAD = "Ladda om nu"  -- [max 22]
L.SET_SEC_SHARE = "DELA VIDARE"  -- [max 24]
L.IO_EXPORT = "Spara boken"  -- [max 17]
L.IO_IMPORT = "Läs in boken"  -- [max 17]
L.SET_HINT_BOOK = "Spara ger dig boken som text: att behålla eller ge vidare till folk utanför guilden. Läs in slår ihop och skriver inte över något."
L.SET_SEC_SOUND = "LJUD"  -- [max 24]
L.SET_SOUND = "Ljud"  -- [max 22]
L.SET_VOLUME = "Volym"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "TRÖSKEL"  -- [max 24]
L.SET_COOLDOWN = "Cooldown per mördare"  -- [max 34]
L.SET_MINKILLS = "Larm när hen dödat dig så ofta"  -- [max 34]
L.SET_ALERT_SIZE = "Larmets storlek"  -- [max 34]
L.SET_TEST_ALERT = "Testlarm"  -- [max 17]
L.SET_G_MINKILLS = "Guildvarning efter antal dödsfall"  -- [max 34]
L.SET_F_MINKILLS = "Varning efter antal dödsfall"  -- [max 34]
L.SET_SEC_STATUS = "STATUS"  -- [max 24]
L.SET_SEC_SHARING = "DELNING"
L.SET_SEC_WARN = "LARM"
L.SET_MORE = "Mer"
L.SET_GUILD_CLEAR = "Töm guildboken"  -- [max 26]
L.SET_HINT_GUILD = "Bara din egen guild får något. Det som kommer därifrån hålls skilt från din bok tills du själv tar över det."
L.SET_HINT_FRIENDS = "Bara guild och vänner med DeathNote får något."
L.BTN_BACK = "Tillbaka"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synka"  -- [max 14]
L.SYNC_AGAIN_IN = "igen om {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Vänner"
L.TIP_GUILD_NAME = "Guild {guild}"
L.TIP_MATES_WITH = "Guildkompisar med DeathNote:"
L.TIP_NO_MATE = "Inget svar från någon guildkompis med DeathNote än."
L.TIP_FRIENDS_WITH = "Vänner med DeathNote:"
L.TIP_SHARED = "Delas: dina bekräftade dödsfall, handinskrivna namn och dina jaktutlysningar."
L.TIP_NOT_SHARED = "Delas inte: noteringar, misstankar, benådade, inlästa namn."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Läs in"  -- [max 17]
L.IO_DONE = "Inläst: {new} nya, {merged} sammanslagna."
L.IO_FAILED = "Det gick inte."
L.IO_SMALL = "Kortversion"  -- [max 17]
L.IO_ALL = "Visa allt"  -- [max 17]
L.IO_MSG_FULL = "Hela boken med dåd ({size})."
L.IO_MSG_SHORT = "Bara namn och antal ({size}). Med dåd: {full}."
L.IO_MSG_BIG = "Stor bok ({size}): att markera och kopiera tar en stund."
L.IO_HELP_EXPORT = "Texten är markerad: Ctrl+C kopierar den. Spara den eller ge den till vänner."
L.IO_HELP_IMPORT = "Klistra in en sparad text med Ctrl+V, sedan Läs in. Inget skrivs över."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Alla i din guild och dina vänner med DeathNote ser skälet."
L.REL_HINT_GUILD = "Alla i din guild med DeathNote ser skälet."
L.REL_HINT_FRIENDS = "Dina vänner med DeathNote ser skälet."
L.REL_HEAD = "Utlys jakt"  -- [max 24]
L.REL_FOR = "FÖR"  -- [max 6]
L.REL_REASON = "SKÄL"  -- [max 8]
L.REL_HINT2 = "Din notering stannar hos dig. Bara du kan blåsa av din egen utlysning."
L.REL_GO = "Utlys jakten"  -- [max 17]
L.REL_NONE = "Ingen guild, och delning med vänner är av."
L.REL_CAP = "Högst {own} egna utlysningar och {max} mål per lista."
L.REL_FAILED = "Kan inte utlysa jakt just nu."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Inget ljud: larmet syns bara."
L.SET_HINT_BUILTIN = "Det här ljudets volym följer kanalen i spelets inställningar."
L.SET_HINT_LEVELS = "Fem steg från tyst till högt. Kanalens reglage i spelets inställningar gäller dessutom."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guild & vänner"  -- [max 18]
L.TIP_HELP_BUTTON = "Så funkar boken"
L.VIEW_HUNT = "Jaktlistan"  -- [max 13]
L.VIEW_BY_KILLER = "Per mördare"  -- [max 13]
L.VIEW_BY_MATE = "Per medlem"  -- [max 13]
L.SRC_ALL = "Alla"  -- [max 12]
L.SRC_GUILD = "Guild"  -- [max 12]
L.SRC_FRIENDS = "Vänner"  -- [max 12]
L.SORT_HIDE_PARDONED = "Dölj benådade"  -- [max 24]
L.SORT_SHOW_PARDONED = "Visa benådade"  -- [max 24]
L.SEARCH_ADD = "Sök eller skriv in …"  -- [max 26]
L.SEARCH_SHORT = "Sök …"  -- [max 10]
L.SEARCH_KILLER = "Hitta mördare …"  -- [max 15]
L.SEARCH_JOURNAL = "Mördare eller plats …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Fäll ihop alla"
L.TIP_EXPAND_ALL = "Fäll ut alla"
L.STATUS_NO_PLATES = "Fiendens namnskyltar är av: larmet ser bara mål och mus."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|efterlyst|efterlysta}"
L.MM_UNSOLVED = "{count} {count|olöst|olösta}"
L.MM_ALERT_OFF = "Larmet är av (mittenklick)"
L.MM_CLICK = "Klick: boken · Högerklick: Husregler"
L.MM_MIDDLE = "Mittenklick: larm på/av"
L.MM_DRAG = "Dra: flytta längs minimapens kant"
L.MM_CHAT_ALERT_ON = "Larm på."
L.MM_CHAT_ALERT_OFF = "Larm av."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GUILDFIENDE NR 1"  -- [max 25]
L.STAMP_HUNT = "LOVLIGT BYTE"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} utgav sig för att vara din vän {friend}: nekad."
L.FRIENDS_SHORT_IMPOSTOR = "Främling nekad"  -- [max 22]
L.ALERT_LEVEL = "Nivå {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "senast nivå {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Nivå ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · på jaktlistan ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nytt mål|nya mål}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nytt på jaktlistan"
L.OPT_F_ANNOUNCEHUNT = "Meddela nytt på jaktlistan: nya, fällda"  -- [max 44]
L.SET_HUNT_EXPIRE = "Utlysningar upphör efter"  -- [max 30]
L.SET_EXPIRE_NEVER = "Aldrig"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dag|dagar}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Töm vänboken"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Vill du tömma vänboken på den här datorn?\nDess jaktlista följer med, dina egna utlysningar stannar."
L.CONFIRM_CALLOFF_ALL = "Vill du blåsa av alla dina utlysningar?\nGuild och vänner får veta det efter hand."
L.CONFIRM_CALLOFF_ALL_OK = "Blås av alla"  -- [max 14]
L.ACT_CALLOFF_ALL = "Blås av alla mina"  -- [max 24]
L.ACT_HUNT_HIDE = "Dölj för mig"  -- [max 19]
L.ACT_HUNT_SHOW = "Visa igen"  -- [max 19]
L.HUNT_ROW_HIDDEN = "dold för dig"
L.HUNT_ROW_CALLS = "{count} {count|utlysning|utlysningar}: {names}"
L.POSTER_ON_HUNTLIST = "På jaktlistan ({names})"
L.REL_SELF = "Du kan inte utlysa jakt på dig själv."
L.REL_MATE = "Det där är en av dina egna (guild eller vänner med DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Vem är din vän {friend}: {a} eller {b}? Välj."
L.FRIENDS_SHORT_CONFLICT = "Oklar vän"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Två spelare säger att de är din vän {friend}: {a} och {b}. Tills du väljer tar boken inte emot något från någon av dem. Guild & vänner, vy Per medlem: högerklicka på namnet."
L.MEMBER_CONFLICT = "Högerklick: är det här din vän?"  -- [max 40]
L.ACT_TIE_MINE = "Min vän: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Koppla loss"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Koppla loss {name} från din vänlista?\nDet som namnet har fört in i vänboken raderas; nästa meddelande under det här förnamnet kopplas på nytt."
L.CHAT_FRIENDS_TIES = "Kopplade fullständiga namn (* = första kontakt, ännu inte bekräftat): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Namn [Efternamn]> <guld>  utlys en egen belöning (utan guld: ta tillbaka)"
L.CHAT_WHO_BOUNTY = "På vem? /dn bounty <Namn> <guld>"
L.CHAT_BOUNTY_SET = "{name}: du har utlyst {gold} guld i belöning. Guild och vänner med DeathNote ser det."
L.CHAT_BOUNTY_OFF = "{name}: din belöning är tillbakatagen."
L.CHAT_BOUNTY_NONE = "Du har ingen egen belöning på {name}."
L.CHAT_BOUNTY_BAD = "Belöning: ett heltal guld, 1 till 99999 (0 tar tillbaka den)."
L.CHAT_BOUNTY_CAP = "Ingen belöning: högst {count} egna."
L.CHAT_BOUNTY_OURS = "Ingen belöning på dig själv eller dina egna (guild eller vänner med DeathNote)."
L.ACT_BOUNTY = "Utlys belöning"  -- [max 24]
L.ACT_UNDO = "Ångra"  -- [max 19]
L.ACT_REVENGE_TAKE = "Dra av en hämnd"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, utlyst av dig"
L.POSTER_BOUNTY_BY = "{gold}, utlyst av {name}"
L.POSTER_BOUNTY_MANY = "Belöning {gold}: {names}"
L.POSTER_AVENGED = "Hämnad av {names}"
L.ROW_AVENGED = "hämnad {times}"
L.BOUNTY_TIP_HEAD = "Din egen belöning i guld"
L.BOUNTY_TIP_RULES = "Ett heltal, 1 till 99999. Tomt eller 0: tillbaka till bokens värde. Enter sätter, Esc avbryter."
L.BOUNTY_TIP_PROMISE = "Guild och vänner med DeathNote ser den. Bara ett löfte: ni gör upp sinsemellan."
L.BOUNTY_TIP_CLICK = "Klick: utlys en egen belöning"
L.CHAT_AVENGED = "{name} fällde {killer} åt dig."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: du har utlyst {gold} guld i belöning."
L.CHAT_BOUNTY_UNKNOWN = "{name} står inte i någon av dina böcker. Belöning bara på ett namn ur en bok, så som spelet visar det: förnamn och efternamn."
L.CHAT_BOUNTY_LIST = "Dina belöningar ({count} av {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Du har inte utlyst någon belöning."
-- <<< BOOK
-- >>> REPUTE (1.3.0) ----------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Rang {tier} · Väg: {path}"  -- [max 32]
L.PATH_R = "Vanrykte"  -- [max 16]
L.PATH_E = "Ära"  -- [max 16]
L.PATH_J = "Jakt"  -- [max 16]
L.PATH_S = "Skydd"  -- [max 16]
L.PATH_NONE = "oskriven"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) -----------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "LÅNGSINT?"  -- [max 30]
L.ALERT_LINE_VICTIM = "ställning {score} · dödad av dig, senast {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · {score}, kvitt"
L.ALERT_LINE_STANDING_AHEAD = "{text} · {score}, överbetalt"
-- <<< ALARM
-- >>> START (1.3.0) -----------------------------------------------------------------------------------------------
L.SET_THEME = "Pärm"  -- [max 16]
L.START_HINT = "Båda kan ändras senare i Husreglerna."  -- [max 60]
L.START_GO = "Kör"  -- [max 16]
L.START_CLOSE_TIP = "Låt det vara som det är"  -- [max 32]
L.CHAT_THEME_NEWS = "Nytt: boken finns nu med andra pärmar. Husregler, fliken Bok, eller /dn theme."
L.HELP_START = "/dn start  startfönstret igen (språk och pärm)"
-- <<< START
-- >>> RECORD (1.3.0) ----------------------------------------------------------------------------------------------
L.TAB_RECORD = "Straffregister"  -- [max 16]
L.STAMP_QUITT = "KVITT"  -- [max 16]
L.STAMP_OVERPAID = "ÖVERBETALT"  -- [max 16]
L.STATE_OPEN = "öppen"  -- [max 16]
L.STATE_EVEN = "kvitt"  -- [max 16]
L.STATE_AHEAD = "överbetalt"  -- [max 16]
L.STATE_VICTIM = "inte i boken"  -- [max 24]
L.STAND_LINE = "Ställning {score}"
L.STAND_TIP = "du {mine}, hen {his}"
L.TIP_IN_RECORD = "I REGISTRET:"
L.TIP_RECORD_LINE = "dödad av dig {times}, senast {time}"
L.RECORD_HEAD = "Din akt"  -- [max 20]
L.RECORD_LOG_HEAD = "Senaste kills"  -- [max 20]
L.RECORD_NEXT = "{points} poäng kvar till {rank}"
L.RECORD_TOP = "Högsta rang uppnådd."
L.RECORD_BAR_TIP = "{total} av {goal} poäng"
L.RECORD_NEEDLE_LOW = "hänsynslös"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "hederlig"  -- [max 12]
L.RECORD_NEEDLE_TIP = "Nålen: ära och skydd mot vanrykte. Jakt rör den inte."
L.RECORD_KILLS = "Kills: {kills} · Offer: {victims}"
L.RECORD_BEST = "Rekord: {list}"
L.RECORD_BEST_GAP = "+{count} {count|nivå|nivåer}"
L.RECORD_BEST_STREAK = "svit {count}"
L.RECORD_BEST_QUICK = "snabbaste hämnd {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} tim"
L.RECORD_AWARDS = "MEDALJER"  -- [max 14]
L.RECORD_AWARD_AT = "tilldelad {time}"
L.RECORD_AWARD_OPEN = "inte tilldelad än"
L.RECORD_MORE = "Visa mer"  -- [max 19]
L.RECORD_BACK = "Till akten"  -- [max 19]
L.RECORD_CLEAR = "Töm registret"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Vill du tömma straffregistret?\nAlla offer och listan över senaste kills försvinner. Rang, poäng och medaljer blir kvar."
L.CONFIRM_RECORD_CLEAR_OK = "Töm"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Stryka {name} ur straffregistret?\nPoängen du har fått blir kvar."
L.ACT_VICTIM_STRIKE = "Stryk ur registret"  -- [max 26]
L.VICTIM_KILLED = "dödad av dig {times}"
L.VICTIM_POINTS = "Poäng till dig: {points}"
L.VICTIM_SCENE = "Brottsplats: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "DINA KILLS"  -- [max 14]
L.KILL_TAG_REVENGE = "hämnd"  -- [max 14]
L.KILL_TAG_KICK = "redan nere"  -- [max 14]
L.KILL_TAG_GROUP = "grupp"  -- [max 14]
L.BAND_GRAU = "grå"  -- [max 12]
L.BAND_GRUEN = "grön"  -- [max 12]
L.BAND_GELB = "gul"  -- [max 12]
L.BAND_ORANGE = "orange"  -- [max 12]
L.BAND_ROT = "röd"  -- [max 12]
L.BAND_SCHAEDEL = "dödskalle"  -- [max 12]
L.BAND_UNBEKANNT = "okänd"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "inga poäng"
L.RECORD_BANDS = "Efter nivåfärg"
L.TIP_PATH_R = "Vanrykte: kills på gråa och gröna."
L.TIP_PATH_E = "Ära: kills på spelare på din nivå, hämnd."
L.TIP_PATH_J = "Jakt: kills på högre nivåer, mål på jaktlistan, belöningar."
L.TIP_PATH_S = "Skydd: kills på spelare som har dödat guildkompisar eller vänner."
L.SORT_STATE = "Ställning"  -- [max 14]
L.SORT_COUNT = "Kills"  -- [max 14]
L.SORT_POINTS = "Poäng"  -- [max 14]
L.CHAT_OWN_KILL = "Straffregister: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Ny väg: {path}. Rang: {rank}."
L.BANNER_RANK = "NY RANG"  -- [max 24]
L.BANNER_AWARD = "UTMÄRKELSE"  -- [max 24]
L.OPT_LEDGER = "För straffregister"  -- [max 44]
L.OPT_LEDGER_CHAT = "Rapportera egna kills i chatten"  -- [max 44]
L.OPT_VICTIMS = "Varna när ett av dina offer dyker upp"  -- [max 44]
L.SET_SETTLED = "Larm när skulden är betald"  -- [max 34]
L.SET_SETTLED_ALWAYS = "som alltid"  -- [max 10]
L.SET_SETTLED_QUIET = "tyst"  -- [max 10]
L.SET_SETTLED_OFF = "aldrig"  -- [max 10]
L.MANUAL_RECORD_HEAD = "STRAFFREGISTER"  -- [max 14]
L.MANUAL_RECORD = "Dina egna dödande slag mot spelare. Affischen och listan visar ställningen ”du : hen”: öppen, kvitt eller överbetalt. Rang 1 är alltid öppen. Kills ger poäng till din rang."
L.POSTER_LAST_SEEN_IN = "Senast sedd: {zone}, {time}"
L.SHEET_RECORD = "Register"  -- [max 14]
-- <<< RECORD
end)
