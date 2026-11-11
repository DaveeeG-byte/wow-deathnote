-- DeathNote: Dansk (daDK). No official Danish client: words as Danish players use them (guild, dungeons).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.daDK), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Glossary: bogen, guildbogen, vennebogen, morder, guildkammerat, ven, Efterlyste, Uopklarede, Dødslog, Husregler,
-- plakat, stempel, dusør, note, observation, stryge, benåde, hævn, mistænkt, jagtlisten, udlyse jagt,
-- udlysning, afblæse jagten, nedlagt, Gem bogen, Indlæs bogen.
--
-- TOC-Notes: Dødsliste til PvP i den åbne verden: husker, hvem der dræbte dig, og advarer, når de er i nærheden.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("daDK")) then return end

Locale.Register("daDK", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Efterlyste"    -- [max 16]
L.TAB_UNSOLVED = "Uopklarede"    -- [max 16]
L.TAB_DEATHLOG = "Dødslog"       -- [max 16]
L.TAB_GUILD    = "Guild"         -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Husregler"       -- [max 24]
L.HEAD_HELP  = "Brugsanvisning"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Bog"            -- [max 14]
L.SHEET_ALERT = "Alarm"          -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "SAMFUNDSFJENDE NR. 1"    -- [max 24]
L.STAMP_REVENGE  = "HÆVNET"               -- [max 16]
L.STAMP_PARDONED = "BENÅDET"              -- [max 16]
L.STAMP_SUSPECT  = "MISTÆNKT"             -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "SAMFUNDSFJENDE NR. 1 SPOTTET"   -- [max 30]
L.ALERT_SIGHTED         = "SAMFUNDSFJENDE SPOTTET"         -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "MISTÆNKT SPOTTET"            -- [max 30]
L.ALERT_TITLE_GUILD     = "GUILDFJENDE SPOTTET"         -- [max 30]
L.ALERT_TITLE_FRIENDS   = "VENNERNES MORDER SPOTTET"    -- [max 30]
L.ALERT_TITLE_HUNT      = "MÅL PÅ JAGTLISTEN"           -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "er mistænkt"
L.ALERT_LINE_KILLED         = "har dræbt dig {times}"
L.ALERT_LINE_KILLED_ASSISTED = "har dræbt dig {times}, medvirket {assists}"
L.ALERT_LINE_ASSISTED       = "har medvirket til din død {times}"
L.ALERT_LINE_MANUAL         = "er skrevet ind i hånden"
L.ALERT_LINE_LAST    = "{text}, sidst {time}"
L.ALERT_LINE_IN      = "{text} i {zone}"
L.ALERT_LINE_REVENGE = "{text}. Hævn: {times}"
L.ALERT_HINT_CLOSE  = "Højreklik: luk"                              -- [max 44]
L.ALERT_HINT_COMBAT = "Kan først tages som mål efter kampen"        -- [max 44]
L.ALERT_HINT_TARGET = "Klik: tag som mål  ·  Højreklik: luk"        -- [max 44]
L.ALERT_MORE = "+{count} mere"           -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "står i guildbogen"
L.GUILD_LINE_IN_FRIENDS = "står i vennebogen"
L.GUILD_LINE_LISTED_BY  = "står i bogen hos {names}"
L.GUILD_LINE_KILLED_GUILD   = "har dræbt guildkammerater {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "har dræbt venner {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "har dræbt guildkammerater og venner {kills}×"
L.GUILD_LINE_LAST = "{text}, sidst {name}"
L.HUNT_LINE_BY       = "jagt udlyst af {names}"
L.HUNT_LINE_RELEASED = "på jagtlisten"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "mistænkt"
L.TALLY_MANUAL   = "skrevet ind i hånden"
L.TALLY_NONE     = "ingen ugerning endnu"
L.TALLY_KILLED   = "dræbt dig {times}"
L.TALLY_ASSISTED = "medvirket {times}"
L.PLACE_UNKNOWN  = "ukendt sted"
L.GKILLS_CAP     = "mindst {count}"
L.NAMELIST_MORE  = "{names} og {count} mere"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d.%m. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY       = "%d.%m."
L.TIME_FMT_DAY_YEAR  = "%d.%m.%y"
L.TIME_NEVER   = "aldrig"
L.TIME_JUST    = "for lidt siden"
L.TIME_MINUTES = "{count} min siden"      -- [max 14]
L.TIME_HOURS   = "{count} t siden"        -- [max 14]
L.TIME_DAYS    = "{count} {count|dag|dage} siden"  -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}k"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Hørt fra {count} {count|guildkammerat|guildkammerater} med DeathNote."
L.HEALTH_NOGUILD = "Du er ikke med i nogen guild, intet deles."
L.HEALTH_OFF     = "Deling er slået fra."
L.HEALTH_SHORT_NOGUILD = "Ingen guild"    -- [max 18]
L.HEALTH_SHORT_OFF     = "Deling fra"     -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Spærret"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Afvist"         -- [max 18]
L.HEALTH_SHORT_HOLD    = "Venter"         -- [max 18]
L.HEALTH_SHORT_ASKED   = "Forespurgt"     -- [max 18]
L.HEALTH_SHORT_FAIL    = "Virker ikke"    -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Ingen lyd"         -- [max 16]
L.SOUND_RAIDWARNING = "Raidadvarsel"      -- [max 16]
L.SOUND_BELL        = "Klokke"            -- [max 16]
L.SOUND_GONG        = "Gongong"           -- [max 16]
L.SOUND_HEARTBEAT   = "Hjerteslag"        -- [max 16]
L.SOUND_FEATHER     = "Fjerpen"           -- [max 16]
L.SOUND_SIREN       = "Sirene"            -- [max 16]
L.CHANNEL_MASTER    = "Hovedlyd"          -- [max 16]
L.CHANNEL_SFX       = "Effekter"          -- [max 16]
L.CHANNEL_DIALOG    = "Dialog"            -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} står nu i bogen."
L.CHAT_REMOVED   = "{name} er strøget fra bogen."
L.CHAT_SYNC_WAIT = "Netop synkroniseret. Prøv igen om {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Ingen navne endnu."
L.EMPTY_WANTED_SUB  = "Gå dog ud en gang imellem."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  åbn/luk bogen"
L.HELP_ADD      = "/dn add <Navn [Efternavn]>  skriv en morder ind i bogen i hånden"
L.HELP_DEL      = "/dn del <Navn [Efternavn]>  stryg en morder fra bogen"
L.HELP_QUIET    = "/dn quiet  alarm fra/til"
L.HELP_TEST     = "/dn test  vis en testalarm"
L.HELP_GUILD    = "/dn guild  guildbogen: status og hvilke guildkammerater der har DeathNote"
L.HELP_FRIENDS  = "/dn friends  vennebogen: status og hvilke venner der har DeathNote"
L.HELP_SYNC     = "/dn sync  synkroniser guildbogen og vennebogen nu"
L.HELP_HUNT     = "/dn hunt <Navn [Efternavn]>  udlys jagt (uden navn: vis jagtlisten)"
L.HELP_CALLOFF  = "/dn calloff <Navn [Efternavn]>  afblæs din egen jagt"
L.HELP_LANG     = "/dn lang <kode>  bogens sprog (enUS, deDE, daDK ...), efter /reload"
L.HELP_PROBE    = "/dn probe  fejlsøgning: hvad spillet fortæller bogen"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  fejlsøgning, test også kamploggen"
L.HELP_DEBUG    = "/dn debug  fejlsøgning: log hver død i detaljer (til/fra)"
L.HELP_HELP     = "/dn help  denne hjælp"
L.HELP_SILENT_ZONES = "I dungeons, battlegrounds og arenaer holder bogen selv mund."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "til"
L.WORD_OFF = "fra"
L.CHAT_WHO_ADD  = "Hvem? /dn add <Navn>"
L.CHAT_WHO_DEL  = "Hvem? /dn del <Navn>"
L.CHAT_WHO_CALLOFF = "Hvem? /dn calloff <Navn>"
L.CHAT_BAD_NAME = "Ugyldigt navn."
L.CHAT_NOT_IN_BOOK = "Ikke i bogen: {name}"
L.CHAT_ALARM_ON  = "Alarm til."
L.CHAT_ALARM_OFF = "Alarm fra."
L.CHAT_DEBUG = "Fejlsøgningslog {state}."
L.CHAT_UNKNOWN_CMD = "Ukendt kommando. Hjælp: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Guildbogen er ikke indlæst."
L.CHAT_NO_GUILD = "Du er ikke med i nogen guild (eller spillet ved det ikke endnu)."
L.CHAT_GUILD_STATE = "Guild {guild}: deling {share}, modtagelse {receive}."
L.CHAT_GUILD_BOOK = "Guildbogen: {enemies} mordere ({listed} kun skrevet ind i hånden), {deeds} {deeds|ugerning|ugerninger}, {foreign} af dem har dræbt andre guildkammerater. Del håndskrevne: {manual}."
L.CHAT_STATE_OK   = "Status: {text}"
L.CHAT_STATE_WARN = "OBS: {text}"
L.CHAT_NO_MATES   = "Ikke hørt fra nogen guildkammerat med DeathNote endnu."
L.CHAT_HAVE_DN      = "Har DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Har DeathNote: {names} og {count} mere"
L.CHAT_SYNC_ASKED = "Synkronisering forespurgt. Svarene kommer inden for få sekunder."
L.CHAT_SYNC_FAIL  = "Synkronisering virker ikke: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "ingen guild, eller deling er slået fra."
L.CHAT_FRIENDS_NOT_LOADED = "Vennebogen er ikke indlæst."
L.CHAT_FRIENDS_STATE = "Venner: deling {share}, {online} af {total} online."
L.CHAT_FRIENDS_BOOK  = "Vennebogen: {enemies} mordere ({listed} kun skrevet ind i hånden), {deeds} {deeds|ugerning|ugerninger}."
L.CHAT_NO_FRIENDS    = "Ikke hørt fra nogen ven med DeathNote endnu."
L.CHAT_HUNT_NOT_LOADED = "Jagtlisten er ikke indlæst."
L.CHAT_HUNT_UNKNOWN = "Ukendt: {name}. Tag efternavnet med, sådan som navnet står i spillet."
L.CHAT_HUNT_CAP     = "Kan ikke udlyse jagt: højst {own} egne udlysninger og {targets} mål pr. liste."
L.CHAT_HUNT_NOWHERE = "Kan ikke udlyse jagt lige nu: ingen guild, og deling med venner er slået fra."
L.CHAT_HUNT_BOTH    = "{name} er på jagtlisten, for guild og venner."
L.CHAT_HUNT_GUILD   = "{name} er på jagtlisten, for guilden."
L.CHAT_HUNT_FRIENDS = "{name} er på jagtlisten, for dine venner."
L.CHAT_CALLED_OFF   = "Jagten er afblæst: {name}."
L.CHAT_NO_OWN_CALL  = "Du har ingen egen udlysning på {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Sprog nu: {lang}. Skift: /dn lang <kode>"
L.CHAT_LANG_LIST    = "Koder: {codes}"
L.CHAT_LANG_BAD     = "Ukendt sprog: {code}"
L.CHAT_LANG_SET     = "Sprog: {lang}."
L.CHAT_LANG_RELOAD  = "Sprog: {lang}. Gælder efter /reload."

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Bogen ligger klar. Den, der dræber dig i den åbne verden, ender i den. Åbn den med /dn eller minimap-knappen."
L.WELCOME_PLATES = "Fjendtlige navneplader er slået fra. Uden dem ser alarmen kun dit mål."
L.WELCOME_SHARE = "Guild og venner, der har DeathNote, læser med. Noter og mistanker bliver hos dig."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "I BOGEN:"
L.TIP_HUNT      = "JAGTLISTEN:"
L.TIP_GUILDBOOK = "GUILDBOGEN:"
L.TIP_PARDONED  = "benådet"
L.TIP_RANK      = "rang {rank}"
L.TIP_REVENGE   = "hævn {times}"
L.TIP_LISTED_BY = "i bogen hos {names}"
L.TIP_NOTE      = "Note: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Klik: åbn · Højreklik: væk"
L.BANNER_NEW          = "NYT NAVN"             -- [max 24]
L.BANNER_NEW_LINE     = "står nu i bogen"
L.BANNER_AGAIN        = "IGEN"                 -- [max 24]
L.BANNER_AGAIN_LINE   = "har dræbt dig igen, {count} gange nu"
L.BANNER_SUSPECT      = "MISTÆNKT"             -- [max 24]
L.BANNER_SUSPECT_LINE = "er mistænkt, opklar det i bogen"
L.BANNER_UNCLEAR      = "UKLAR MORDER"         -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|kandidat|kandidater}"
L.BANNER_UNCLEAR_LINE = "Klik: vælg morderen under Uopklarede"
L.BANNER_REVENGE      = "GENGÆLDELSE"          -- [max 24]
L.BANNER_REVENGE_LINE = "Hævnet ({count}×)"
L.BANNER_GUILD        = "GUILD"                -- [max 24]
L.BANNER_FRIENDS      = "VENNER"               -- [max 24]
L.BANNER_KILLED_BY    = "blev dræbt af {name}"
L.BANNER_HUNT         = "JAGTLISTEN"           -- [max 24]
L.BANNER_BAGGED       = "nedlagt af {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Deling er slået fra (Husregler, fanen Guild)."
L.SYNC_FRIENDS_OFF = "Deling med venner er slået fra."
L.SYNC_NOBODY      = "Ingen guild og ingen venner at dele med."
L.SYNC_SHORT_NOBODY = "Intet delt"            -- [max 18]
L.SYNC_PREFIX      = "Spillet tillader ingen modtagelse. Det hjælper at logge ind igen."
L.SYNC_SHORT_PREFIX = "Kan ikke modtage"      -- [max 18]
L.SYNC_BLOCKED     = "Realmen blokerer afsendelse. Giv det videre med Gem bogen."
L.SYNC_SHORT_BLOCKED = "Afsendelse blokeret"  -- [max 22]
L.SYNC_FAILING     = "Afsendelse fejler lige nu, prøver igen."
L.SYNC_SHORT_FAILING = "Afsendelse hakker"    -- [max 18]
L.SYNC_HOLD        = "Afsendelsen venter, {wait}."
L.SYNC_HOLD_INSTANCE = "til du forlader instansen"
L.SYNC_HOLD_COMBAT   = "til du er ude af kamp"
L.SYNC_HOLD_LOCKDOWN = "til chatten er fri igen"
L.SYNC_HOLD_AGAIN    = "til det virker igen"
L.SYNC_HOLD_SHORT_INSTANCE = "Venter: instans"    -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Venter: kamp"       -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Venter: chat"       -- [max 18]
L.SYNC_QUIET       = "Sendt, men ikke hørt fra nogen guildkammerat med DeathNote endnu."
L.SYNC_READY       = "Klar. Ikke hørt fra nogen guildkammerat med DeathNote endnu."
L.SYNC_RUNNING     = "Kører: {count} {count|guildkammerat|guildkammerater} med DeathNote."
L.SYNC_RUNNING_ALL = "Kører: {count} med DeathNote i guild og blandt venner."
L.FRIENDS_OFF      = "Deling med venner er slået fra (Husregler, fanen Guild)."
L.FRIENDS_BLOCKED  = "Realmen blokerer hvisken. Venner får intet."
L.FRIENDS_SHORT_BLOCKED = "Hvisken blokeret"     -- [max 22]
L.FRIENDS_FAILING  = "Hvisken fejler lige nu, prøver igen."
L.FRIENDS_SHORT_FAILING = "Hvisken hakker"       -- [max 18]
L.FRIENDS_NONE_LISTED = "Ingen venner på vennelisten."
L.FRIENDS_NONE_ONLINE = "Ingen ven online lige nu."
L.FRIENDS_SHORT_NONE_ONLINE = "Ingen ven online"  -- [max 18]
L.FRIENDS_QUIET    = "Spurgt, men ikke hørt fra nogen ven med DeathNote endnu."
L.FRIENDS_READY    = "Klar. Ikke hørt fra nogen ven med DeathNote endnu."
L.FRIENDS_HOLD     = "Afsendelse til venner venter, til det virker igen."
L.FRIENDS_RUNNING  = "Kører: {count} {count|ven|venner} med DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Hentet fra guildbogen (har dræbt guildkammerater {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Databasen er ikke indlæst."
L.IMPORT_NO_TEXT    = "Ingen tekst."
L.IMPORT_NO_HEADER  = "Første linje mangler (den begynder med {header}). Kopiér hele teksten."
L.IMPORT_NOT_EXPORT = "Ikke en DeathNote-eksport (overskriftslinjen mangler eller forkert version)."
L.IMPORT_TOO_LONG   = "For mange linjer (højst {count})."
L.IMPORT_BAD_KEY    = "Linje {line}: ugyldig nøgle."
L.IMPORT_BAD_TIME   = "Linje {line}: ugyldigt tidspunkt."
L.IMPORT_BROKEN     = "Linje {line} er ufuldstændig eller ødelagt (afkortet tekst?). Intet indlæst."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "ja"
L.WORD_NO  = "nej"
L.PROBE_HEAD = "Sonde: {apis}/{apisAll} grænseflader findes, {events}/{eventsAll} hændelser kan registreres."
L.PROBE_MISSING = "Mangler: {list}"
L.PROBE_NOT_REGISTERABLE = "Kan ikke registreres: {list}"
L.PROBE_SOURCES = "Recap nu: {recap} · Meter: {meter} · Kamplog: {clog}"
L.PROBE_READABLE = "læsbar"
L.PROBE_DEAD = "død"
L.PROBE_PLATES = "Fjendtlige navneplader: {plates} · Åben verden: {open}"
L.PROBE_PLATES_OFF = "FRA (kun mål og musemarkør finder spillere)"
L.PROBE_TARGET = "Mål: navn={name} GUID={guid} klasse={class} fjendtlig={enemy} sigter på mig={me}"
L.PROBE_GUILD = "Guild: præfiks {prefix} · afsendelse {send} · sidste returværdi {result} · sendt {sent}, modtaget {received}, kasseret {dropped}"
L.PROBE_REGISTERED = "registreret"
L.PROBE_NOT_REGISTERED = "IKKE registreret ({result})"
L.PROBE_POSSIBLE = "muligt"
L.PROBE_ABSENT = "mangler"
L.PROBE_WAITS = " · venter: {why}"
L.PROBE_LISTED = "Håndskrevne (M): sendt {sent}, modtaget {received}, kasseret {dropped} · strøget (X): sendt {usent}, modtaget {ureceived}, kasseret {udropped}"
L.PROBE_GUILDBOOK = "Guildbogen: {text}"
L.PROBE_SAVED = "Gemt i DeathNoteDB.probe (i filen efter /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Nyeste"  -- [max 14]
L.SORT_NAME = "Navn"  -- [max 14]
L.SORT_SEEN = "Set"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Den, der dræber dig i den åbne verden, ender her. Helt af sig selv."
L.EMPTY_OPEN_HEAD = "Intet uopklaret."
L.EMPTY_JOURNAL_HEAD = "Aldrig død endnu."
L.EMPTY_JOURNAL_SUB = "Respekt. Eller løgn."
L.EMPTY_NOGUILD_HEAD = "Ingen guild."
L.EMPTY_NOGUILD_SUB = "Man kan også dø alene."
L.EMPTY_GUILDOFF_HEAD = "Guildbogen er lukket."
L.EMPTY_GUILDOFF_SUB = "Deling er slået fra. Husreglerne ved hvor."
L.EMPTY_GUILDNIL_HEAD = "Intet hørt fra guilden endnu."
L.EMPTY_GUILDNIL_SUB = "Din bog sendes ud, så snart en guildkammerat har DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Intet i guildbogen endnu."
L.EMPTY_GUILDQUIET_SUB = "Dine guildkammerater har haft fred indtil videre."
L.EMPTY_FRIENDSOFF_HEAD = "Vennebogen er lukket."
L.EMPTY_FRIENDSOFF_SUB = "Deling med venner er slået fra. Husreglerne ved hvor."
L.EMPTY_FRIENDSNIL_HEAD = "Ikke hørt fra nogen ven med DeathNote endnu."
L.EMPTY_FRIENDSNIL_SUB = "Din bog sendes ud, så snart en ven har DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Intet fra dine venner endnu."
L.EMPTY_FRIENDSQUIET_SUB = "Dine venner har haft fred indtil videre."
L.EMPTY_NOBODY_HEAD = "Ingen guild, ingen venner."
L.EMPTY_NOBODY_SUB = "Man kan også dø alene."
L.EMPTY_NOBODY_HINT = "Når guildkammerater eller venner fra din venneliste har DeathNote, viser denne side, hvad der sker med dem."
L.EMPTY_SHAREDNIL_HEAD = "Ikke hørt fra nogen med DeathNote endnu."
L.EMPTY_SHAREDNIL_SUB = "Din bog sendes ud, så snart guildkammerater eller venner har DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Intet her endnu."
L.EMPTY_SHAREDQUIET_SUB = "Guild og venner har haft fred indtil videre."
L.EMPTY_HUNT_HEAD = "Jagtlisten er tom."
L.EMPTY_HUNT_SUB = "På plakaten: Udlys jagt."
L.EMPTY_HUNT_HINT = "Eller i chatten: /dn hunt Navn Efternavn. Alle i din guild og dine venner ser det."
L.EMPTY_SEARCH_HEAD = "Intet fundet."
L.EMPTY_SEARCH_SUB = "Enter skriver navnet ind i bogen."
L.EMPTY_SEARCHRO_HEAD = "Intet fundet."
L.EMPTY_SEARCHRO_SUB = "Nogle gange hjælper en anden stavemåde."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "BOGEN"  -- [max 12]
L.MANUAL_BOOK = "Den, der dræber dig i den åbne verden, bliver skrevet ind af sig selv. Et klik på beskeden efter din død åbner morderens side."
L.MANUAL_WANTED_HEAD = "EFTERLYSTE"  -- [max 12]
L.MANUAL_WANTED = "Dine mordere, den værste først. Et klik viser plakaten med ugerninger og note. Benådede står overstreget til sidst."
L.MANUAL_UNSOLVED_HEAD = "UOPKLAREDE"  -- [max 13]
L.MANUAL_UNSOLVED = "Når det ikke var klart, hvem der gjorde det, venter sagen her. Et klik på et navn afgør, hvem morderen er."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Når en morder dukker op som navneplade, mål eller under musen, siger bogen til. Et klik tager dem som mål, i kamp først bagefter."
L.MANUAL_ADD_HEAD = "SKRIV IND"  -- [max 12]
L.MANUAL_ADD = "Skriv et navn i søgefeltet, Enter. Højreklik på en linje: notér hævn, benåd, stryg."
L.MANUAL_GUILD_HEAD = "GUILD"  -- [max 12]
L.MANUAL_GUILD = "Guildkammerater og venner med DeathNote ser dine bekræftede dødsfald og håndskrevne navne. Plakaten eller /dn hunt Navn: udlys jagt. Klik på dusøren: udlov din egen, et løfte I gør op indbyrdes."
L.MANUAL_SHARE_HEAD = "GIV VIDERE"  -- [max 12]
L.MANUAL_SHARE = "Husregler, Gem bogen: en tekst at kopiere, til alle uden DeathNote."
L.MANUAL_QUIET_HEAD = "STILLE"  -- [max 12]
L.MANUAL_QUIET = "I dungeons og battlegrounds holder alarmen mund. Ellers: midterklik på minimap-knappen eller /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Vil du virkelig stryge {name} fra bogen?\nAlle ugerninger og noten går tabt."
L.CONFIRM_DELETE_OK = "Stryg"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Vil du tømme guildbogen på denne computer?\nDens jagtliste forsvinder også, dine egne udlysninger bliver.\nDin egen bog forbliver, som den er."
L.CONFIRM_GUILD_CLEAR_OK = "Tøm"  -- [max 14]
L.CONFIRM_CANCEL = "Annuller"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GULD"  -- [max 14]
L.BOUNTY_SILVER = "{count} SØLV"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Bekræft"  -- [max 19]
L.ACT_DISMISS = "Afvis"  -- [max 19]
L.ACT_HUNT_AGAIN = "Jag igen"  -- [max 19]
L.ACT_REVENGE = "Notér hævn"  -- [max 19]
L.ACT_PARDON = "Benåd"  -- [max 19]
L.ACT_STRIKE = "Stryg"  -- [max 19]
L.ACT_OPEN_OWN = "Åbn i bogen"  -- [max 19]
L.ACT_ADOPT = "Til min bog"  -- [max 19]
L.ACT_CALLOFF = "Afblæs jagten"  -- [max 19]
L.ACT_RELEASE = "Udlys jagt"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "set {time}"
L.ROW_NOT_SEEN = "ikke spottet endnu"
L.ROW_PARDONED = "benådet"
L.ROW_SUSPECT = "Mistænkt"
L.MARK_REVENGE = "HÆVN {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Uklar morder"
L.MARK_CANDIDATES = "{count} {count|KANDIDAT|KANDIDATER}"  -- [max 16]
L.MARK_SUSPECT = "MISTÆNKT"  -- [max 16]
L.ROW_NO_PLAYER = "Ingen spiller"
L.ROW_UNCLEAR = "Uklart hvordan"
L.MARK_NOT_COUNTED = "TÆLLER IKKE"  -- [max 16]
L.ROW_LISTED_BY = "skrevet ind af {names}"
L.ROW_GKILLED = "dræbt {kills}×"
L.ROW_VICTIMS = "{count} {count|offer|ofre}"
L.ROW_LAST = "sidst {text}"
L.MARK_IN_BOOK = "I BOGEN"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|morder|mordere}"  -- [max 14]
L.MEMBER_DEATHS = "{count} dødsfald"  -- [max 12]
L.MEMBER_LISTED = "{count} i hånden"  -- [max 14]
L.MEMBER_ME = "det ser de andre af dig"
L.MEMBER_NOTHING = "intet delt endnu"
L.MEMBER_LAST_DIED = "døde sidst {time}"
L.MARK_YOU = "dig"  -- [max 16]
L.MARK_FRIEND = "VEN"  -- [max 16]
L.MARK_BOTH = "GUILDKAMMERAT, VEN"  -- [max 20]
L.MARK_TAKEN_DOWN = "NEDLAGT {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DØD ELLER LEVENDE"  -- [max 24]
L.POSTER_DEEDS = "UGERNINGER"  -- [max 14]
L.POSTER_NOTE = "NOTE"  -- [max 8]
L.POSTER_BOUNTY = "DUSØR"  -- [max 12]
L.ROLE_ASSIST = "medvirkede"  -- [max 14]
L.ROLE_SUSPECT = "mistænkt"  -- [max 14]
L.POSTER_LEVEL = "Niveau {level}"
L.POSTER_GUILD = "Guild: {guild}"
L.POSTER_LAST_SEEN = "Sidst set {time}"
L.POSTER_NOT_SEEN = "Ikke spottet endnu"
L.POSTER_ONLY_SUSPECT = "Kun mistænkt, ingen bevist ugerning."
L.POSTER_NO_DEEDS = "Ingen ugerninger noteret."
L.TIP_LISTED_AT = "Skrevet ind {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Dødsårsag: {spell}"
L.TIP_VICTIM = "Offer: {name}"
L.TIP_VICTIM_LEVEL = "Offer: {name} (niveau {level})"
L.TIP_KILLER_LEVEL = "Morderens niveau: {level}"
L.TIP_ASSISTS = "Medvirkede: {names}"
L.TIP_ROLE_ASSIST = "Medvirkede, gav ikke dødsstødet."
L.TIP_ROLE_SUSPECT = "Kun mistænkt, ikke bevist."
L.MORE_LINE = "… og {count} mere"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GUILDBOGEN"  -- [max 24]
L.POSTER_IN_BOOK_OF = "I bogen hos: {names}"
L.POSTER_SEEN = "Set {time}"
L.POSTER_SEEN_BY = "Set {time} af {name}"
L.TIP_IN_BOOK_OF = "I bogen hos"
L.POSTER_REMARK = "BEMÆRKNING"  -- [max 12]
L.POSTER_BY_HAND = "SKREVET IND I HÅNDEN"  -- [max 22]
L.POSTER_VICTIMS = "OFRE"  -- [max 12]
L.POSTER_LISTED = "SKREVET IND"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Skrevet ind i hånden."
L.POSTER_NO_DEEDS_SENT = "Ingen ugerninger fulgte med."
L.POSTER_NONE_KNOWN = "ingen kendte"
L.POSTER_NO_NAMES = "ingen navne fulgte med"
L.TIP_VICTIMS = "Ofre"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Udlyst {time}"
L.HUNT_REASON = "Grund: {reason}"
L.POSTER_HUNTLIST = "JAGTLISTEN"  -- [max 24]
L.POSTER_RELEASED_N = "jagt udlyst {times}"
L.POSTER_RELEASED_BY = "Udlyst af {names}"
L.POSTER_TAKEN_DOWN = "NEDLAGT"  -- [max 12]
L.POSTER_NOT_YET = "IKKE ENDNU"  -- [max 18]
L.POSTER_CALLS = "UDLYST"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Ingen længere."
L.POSTER_LAST = "SIDST"  -- [max 13]
L.POSTER_TAKEN_BY = "nedlagt af {name}, {time}"
L.POSTER_TAKEN_NOBODY = "ikke nedlagt af nogen endnu"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Dødsfald"  -- [max 20]
L.CASE_ASSISTS = "MEDVIRKEDE"  -- [max 24]
L.CASE_PICK = "AFGØR HVEM MORDEREN ER"  -- [max 24]
L.CASE_NOT_COUNTED = "Tæller ikke (instans, battleground eller duel)"
L.CASE_KILLER = "MORDER"  -- [max 24]
L.CASE_KILLER_SUSPECT = "MORDER (MISTÆNKT)"  -- [max 24]
L.CASE_CLICK_NAME = "Klik på navnet for at åbne plakaten."
L.CASE_GONE = "Står ikke længere i bogen."
L.CASE_KILLER_UNCLEAR = "UKLAR MORDER"  -- [max 24]
L.CASE_SEVERAL = "Flere kan have gjort det. Hvis navn skal i bogen?"
L.CASE_NOBODY = "Ingen kan have gjort det."
L.CASE_HOW = "HVAD DER SKETE"  -- [max 24]
L.CASE_PVE = "Et monster eller verden selv. Ingen sag for bogen."
L.CASE_UNCLEAR = "Uklart"
L.CASE_DARK = "Teknikerne famler i blinde."
L.TIP_MORE_CANDIDATES = "Flere kandidater"
L.CASE_SOURCE_SUSPECT = "Mistænkt: havde dig som mål lige før du døde."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-linje over mordere"  -- [max 44]
L.OPT_MINIMAP = "Vis minimap-knappen"  -- [max 44]
L.OPT_ALERT = "Alarm, når en morder dukker op"  -- [max 44]
L.OPT_FLASH = "Blink skærmkanten rød"  -- [max 44]
L.OPT_SUSPECTS = "Meld også mistænkte"  -- [max 44]
L.OPT_DEATHMSG = "Besked efter en PvP-død"  -- [max 44]
L.OPT_G_SHARE = "Del mine dødsfald"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Del håndskrevne navne"  -- [max 44]
L.OPT_G_RECEIVE = "Modtag guildbogen"  -- [max 44]
L.OPT_G_ALERT = "Advar om mordere fra guildbogen"  -- [max 44]
L.OPT_G_ALERTLISTED = "Advar også om håndskrevne navne"  -- [max 44]
L.OPT_G_ANNOUNCE = "Meld, når en guildkammerat bliver dræbt"  -- [max 44]
L.OPT_G_SIGHTINGS = "Del observationer"  -- [max 44]
L.OPT_F_SHARE = "Del med guilden"  -- [max 44]
L.OPT_F_FRIENDS = "Del med venner"  -- [max 44]
L.OPT_F_ALERT = "Advar om mordere fra guild og venner"  -- [max 44]
L.OPT_F_ALERTHUNT = "Advar om mål på jagtlisten"  -- [max 44]
L.OPT_F_ANNOUNCE = "Meld, når guildkammerater eller venner dør"  -- [max 44]
L.OPT_F_SIGHTINGS = "Del observationer med guild og venner"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guild"  -- [max 14]
L.SET_BOOK_SIZE = "Bogens størrelse"  -- [max 34]
L.SET_LANGUAGE = "Sprog"  -- [max 16]
L.SET_LANG_AUTO = "Automatisk"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Gælder efter genindlæsning."  -- [max 28]
L.SET_LANG_RELOAD = "Genindlæs nu"  -- [max 22]
L.SET_SEC_SHARE = "GIV VIDERE"  -- [max 24]
L.IO_EXPORT = "Gem bogen"  -- [max 17]
L.IO_IMPORT = "Indlæs bogen"  -- [max 17]
L.SET_HINT_BOOK = "Gem giver dig bogen som tekst: til at beholde eller give videre til folk uden for guilden. Indlæs fletter sammen og overskriver intet."
L.SET_SEC_SOUND = "LYD"  -- [max 24]
L.SET_SOUND = "Lyd"  -- [max 22]
L.SET_VOLUME = "Lydstyrke"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "TÆRSKEL"  -- [max 24]
L.SET_COOLDOWN = "Cooldown pr. morder"  -- [max 34]
L.SET_MINKILLS = "Alarm efter antal drab af dem"  -- [max 34]
L.SET_ALERT_SIZE = "Alarmens størrelse"  -- [max 34]
L.SET_TEST_ALERT = "Testalarm"  -- [max 17]
L.SET_G_MINKILLS = "Guildadvarsel efter antal drab"  -- [max 34]
L.SET_F_MINKILLS = "Advarsel efter antal drab"  -- [max 34]
L.SET_SEC_STATUS = "STATUS"  -- [max 24]
L.SET_SEC_SHARING = "DELING"
L.SET_SEC_WARN = "ALARM"
L.SET_MORE = "Mere"
L.SET_GUILD_CLEAR = "Tøm guildbogen"  -- [max 26]
L.SET_HINT_GUILD = "Kun din egen guild får noget. Det, der kommer derfra, holdes adskilt fra din bog, indtil du selv overtager det."
L.SET_HINT_FRIENDS = "Kun guild og venner med DeathNote får noget."
L.BTN_BACK = "Tilbage"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synkroniser"  -- [max 14]
L.SYNC_AGAIN_IN = "igen om {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Venner"
L.TIP_GUILD_NAME = "Guild {guild}"
L.TIP_MATES_WITH = "Guildkammerater med DeathNote:"
L.TIP_NO_MATE = "Ikke hørt fra nogen guildkammerat med DeathNote endnu."
L.TIP_FRIENDS_WITH = "Venner med DeathNote:"
L.TIP_SHARED = "Deles: dine bekræftede dødsfald, håndskrevne navne og dine jagtudlysninger."
L.TIP_NOT_SHARED = "Deles ikke: noter, mistanker, benådede, indlæste navne."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Indlæs"  -- [max 17]
L.IO_DONE = "Indlæst: {new} nye, {merged} flettet."
L.IO_FAILED = "Det virkede ikke."
L.IO_SMALL = "Kort version"  -- [max 17]
L.IO_ALL = "Vis alt"  -- [max 17]
L.IO_MSG_FULL = "Hele bogen med ugerninger ({size})."
L.IO_MSG_SHORT = "Kun navne og antal ({size}). Med ugerninger: {full}."
L.IO_MSG_BIG = "Stor bog ({size}): markering og kopiering tager et øjeblik."
L.IO_HELP_EXPORT = "Teksten er markeret: Ctrl+C kopierer den. Gem den, eller giv den videre til venner."
L.IO_HELP_IMPORT = "Indsæt en gemt tekst med Ctrl+V, og tryk så Indlæs. Intet bliver overskrevet."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Alle i din guild og dine venner med DeathNote ser grunden."
L.REL_HINT_GUILD = "Alle i din guild med DeathNote ser grunden."
L.REL_HINT_FRIENDS = "Dine venner med DeathNote ser grunden."
L.REL_HEAD = "Udlys jagt"  -- [max 24]
L.REL_FOR = "FOR"  -- [max 6]
L.REL_REASON = "GRUND"  -- [max 8]
L.REL_HINT2 = "Din note bliver hos dig. Kun du kan afblæse din egen udlysning."
L.REL_GO = "Udlys jagten"  -- [max 17]
L.REL_NONE = "Ingen guild, og deling med venner er slået fra."
L.REL_CAP = "Højst {own} egne udlysninger og {max} mål pr. liste."
L.REL_FAILED = "Kan ikke udlyse jagt lige nu."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Ingen lyd: alarmen vises kun."
L.SET_HINT_BUILTIN = "Lydstyrken for denne lyd følger kanalen i spillets indstillinger."
L.SET_HINT_LEVELS = "Fem trin fra svag til høj. Kanalens skyder i spillets indstillinger gælder oveni."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guild & venner"  -- [max 18]
L.TIP_HELP_BUTTON = "Sådan virker bogen"
L.VIEW_HUNT = "Jagtlisten"  -- [max 13]
L.VIEW_BY_KILLER = "Efter morder"  -- [max 13]
L.VIEW_BY_MATE = "Efter medlem"  -- [max 13]
L.SRC_ALL = "Alle"  -- [max 12]
L.SRC_GUILD = "Guild"  -- [max 12]
L.SRC_FRIENDS = "Venner"  -- [max 12]
L.SORT_HIDE_PARDONED = "Skjul benådede"  -- [max 24]
L.SORT_SHOW_PARDONED = "Vis benådede"  -- [max 24]
L.SEARCH_ADD = "Søg eller skriv ind …"  -- [max 26]
L.SEARCH_SHORT = "Søg …"  -- [max 10]
L.SEARCH_KILLER = "Find morder …"  -- [max 15]
L.SEARCH_JOURNAL = "Morder eller sted …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Fold alle sammen"
L.TIP_EXPAND_ALL = "Fold alle ud"
L.STATUS_NO_PLATES = "Fjendtlige navneplader er slået fra: alarmen ser kun mål og mus."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|efterlyst|efterlyste}"
L.MM_UNSOLVED = "{count} {count|uopklaret|uopklarede}"
L.MM_ALERT_OFF = "Alarmen er slået fra (midterklik)"
L.MM_CLICK = "Klik: bogen · Højreklik: Husregler"
L.MM_MIDDLE = "Midterklik: alarm til/fra"
L.MM_DRAG = "Træk: flyt langs minimappets kant"
L.MM_CHAT_ALERT_ON = "Alarm til."
L.MM_CHAT_ALERT_OFF = "Alarm fra."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GUILDFJENDE NR. 1"  -- [max 25]
L.STAMP_HUNT = "FRIT VILDT"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} udgav sig for at være din ven {friend}: afvist."
L.FRIENDS_SHORT_IMPOSTOR = "Fremmed afvist"  -- [max 22]
L.ALERT_LEVEL = "Niveau {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "sidst niveau {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Niveau ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · på jagtlisten ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nyt mål|nye mål}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nyt på jagtlisten"
L.OPT_F_ANNOUNCEHUNT = "Meld nyt fra jagtlisten: nye og nedlagte"  -- [max 44]
L.SET_HUNT_EXPIRE = "Udlysninger udløber efter"  -- [max 30]
L.SET_EXPIRE_NEVER = "Aldrig"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dag|dage}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Tøm vennebogen"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Vil du tømme vennebogen på denne computer?\nDens jagtliste forsvinder også, dine egne udlysninger bliver."
L.CONFIRM_CALLOFF_ALL = "Vil du afblæse alle dine udlysninger?\nGuild og venner får det at vide lidt efter lidt."
L.CONFIRM_CALLOFF_ALL_OK = "Afblæs alle"  -- [max 14]
L.ACT_CALLOFF_ALL = "Afblæs alle mine"  -- [max 24]
L.ACT_HUNT_HIDE = "Skjul for mig"  -- [max 19]
L.ACT_HUNT_SHOW = "Vis igen"  -- [max 19]
L.HUNT_ROW_HIDDEN = "skjult for dig"
L.HUNT_ROW_CALLS = "{count} {count|udlysning|udlysninger}: {names}"
L.POSTER_ON_HUNTLIST = "På jagtlisten ({names})"
L.REL_SELF = "Du kan ikke udlyse jagt på dig selv."
L.REL_MATE = "Det er en af dine egne (guild eller venner med DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Hvem er din ven {friend}: {a} eller {b}? Vælg."
L.FRIENDS_SHORT_CONFLICT = "Uklar ven"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "To spillere siger, at de er din ven {friend}: {a} og {b}. Indtil du vælger, tager bogen ikke imod noget fra nogen af dem. Guild & venner, visning Efter medlem: højreklik på navnet."
L.MEMBER_CONFLICT = "Højreklik: er det din ven?"  -- [max 40]
L.ACT_TIE_MINE = "Min ven: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Frakobl navn"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Frakobl {name} fra din venneliste?\nDet, navnet har bragt ind i vennebogen, slettes; næste besked under dette fornavn kobles på ny."
L.CHAT_FRIENDS_TIES = "Koblede fulde navne (* = første kontakt, endnu ikke bekræftet): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Navn [Efternavn]> <guld>  udlov en egen dusør (uden guld: træk den tilbage)"
L.CHAT_WHO_BOUNTY = "På hvem? /dn bounty <Navn> <guld>"
L.CHAT_BOUNTY_SET = "{name}: du har udlovet {gold} guld i dusør. Guild og venner med DeathNote ser det."
L.CHAT_BOUNTY_OFF = "{name}: din dusør er trukket tilbage."
L.CHAT_BOUNTY_NONE = "Du har ingen egen dusør på {name}."
L.CHAT_BOUNTY_BAD = "Dusør: et helt antal guld, 1 til 99999 (0 trækker den tilbage)."
L.CHAT_BOUNTY_CAP = "Ingen dusør: højst {count} egne."
L.CHAT_BOUNTY_OURS = "Ingen dusør på dig selv eller dine egne (guild eller venner med DeathNote)."
L.ACT_BOUNTY = "Udlov dusør"  -- [max 24]
L.ACT_UNDO = "Fortryd"  -- [max 19]
L.ACT_REVENGE_TAKE = "Træk én hævn fra"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, udlovet af dig"
L.POSTER_BOUNTY_BY = "{gold}, udlovet af {name}"
L.POSTER_BOUNTY_MANY = "Dusør {gold}: {names}"
L.POSTER_AVENGED = "Hævnet af {names}"
L.ROW_AVENGED = "hævnet {times}"
L.BOUNTY_TIP_HEAD = "Din egen dusør i guld"
L.BOUNTY_TIP_RULES = "Et helt tal, 1 til 99999. Tomt eller 0: tilbage til bogens værdi. Enter sætter, Esc afbryder."
L.BOUNTY_TIP_PROMISE = "Guild og venner med DeathNote ser den. Kun et løfte: I gør op indbyrdes."
L.BOUNTY_TIP_CLICK = "Klik: udlov en egen dusør"
L.CHAT_AVENGED = "{name} nedlagde {killer} for dig."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: du har udlovet {gold} guld i dusør."
L.CHAT_BOUNTY_UNKNOWN = "{name} står ikke i nogen af dine bøger. Dusør kun på et navn fra en bog, sådan som spillet viser det: fornavn og efternavn."
L.CHAT_BOUNTY_LIST = "Dine dusører ({count} af {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Du har ikke udlovet nogen dusør."
-- <<< BOOK
end)
