-- DeathNote: Deutsch (deDE). Wording as in 1.1.0, do not rephrase.
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule: Locale.lua, PLURAL_OF.deDE.
-- [max N] = maximum length in characters (source tests/sprachen/_limits.lua). Placeholders like {name} stay.
-- The word choice guards (tests/ui/gesamtschau.lua) apply: Buch, Gildenbuch, Täter, Kollege, streichen.
--
-- TOC-Notes: Todesliste für Open-World-PvP: merkt sich, wer dich getötet hat, und warnt, wenn er in der Nähe ist.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("deDE")) then return end

Locale.Register("deDE", function(L)

-- Tabs on the black cover (the code appends the number) -------------------------------------------
L.TAB_WANTED   = "Gesucht"       -- [max 16] tab 1: who killed you, by rank
L.TAB_UNSOLVED = "Zu klären"     -- [max 16] tab 2: deaths whose killer is still open
L.TAB_DEATHLOG = "Todesjournal"  -- [max 16] tab 3: own deaths by players, newest first
L.TAB_GUILD    = "Gilde"         -- [max 16] tab 4, guild only: the shared guild book

-- Page heads (large handwriting on the right) -----------------------------------------------------
L.HEAD_RULES = "Hausordnung"         -- [max 24] settings (cog)
L.HEAD_HELP  = "Gebrauchsanweisung"  -- [max 24] help ("?")

-- Sheets of the house rules -----------------------------------------------------------------------
L.SHEET_BOOK  = "Buch"           -- [max 14] sheet with the settings of the book
L.SHEET_ALERT = "Alarm"          -- [max 14] sheet with the alarm settings

-- Stamps on the poster (WANTED always stays English and is not here) ------------------------------
L.STAMP_NR1      = "STAATSFEIND Nr. 1"  -- [max 24] poster of rank 1
L.STAMP_REVENGE  = "RACHE GENOMMEN"     -- [max 16] you killed back
L.STAMP_PARDONED = "BEGNADIGT"          -- [max 16] pardoned, no more alarm
L.STAMP_SUSPECT  = "VERDACHT"           -- [max 16] involvement not proven

-- Alarm popup (top centre, angular font) ----------------------------------------------------------
L.ALERT_SIGHTED_NR1     = "STAATSFEIND Nr. 1 GESICHTET"  -- [max 30] title when rank 1 is near
L.ALERT_SIGHTED         = "STAATSFEIND GESICHTET"        -- [max 30] title for all other wanted ones
L.ALERT_SIGHTED_SUSPECT = "VERDÄCHTIGER GESICHTET"       -- [max 30] title for a suspicion
L.ALERT_TITLE_GUILD     = "GILDENFEIND GESICHTET"        -- [max 30] killer from the guild book
L.ALERT_TITLE_FRIENDS   = "TÄTER DER FREUNDE GESICHTET"  -- [max 30] killer from the friends' book
L.ALERT_TITLE_HUNT      = "ZIEL DER ABSCHUSSLISTE"       -- [max 30] hit list target
L.ALERT_LINE_SUSPECT        = "steht unter Verdacht"
L.ALERT_LINE_KILLED         = "hat dich {times} getötet"
L.ALERT_LINE_KILLED_ASSISTED = "hat dich {times} getötet, war {assists} beteiligt"
L.ALERT_LINE_ASSISTED       = "war {times} an deinem Tod beteiligt"
L.ALERT_LINE_MANUAL         = "steht von Hand im Buch"
L.ALERT_LINE_LAST    = "{text}, zuletzt {time}"
L.ALERT_LINE_IN      = "{text} in {zone}"
L.ALERT_LINE_REVENGE = "{text}. Rache: {times}"
L.ALERT_HINT_CLOSE  = "Rechtsklick: schließen"                      -- [max 44]
L.ALERT_HINT_COMBAT = "Anvisieren erst nach dem Kampf"              -- [max 44]
L.ALERT_HINT_TARGET = "Klick: anvisieren  ·  Rechtsklick: schließen" -- [max 44]
L.ALERT_MORE = "+{count} {count|weiterer|weitere}"                  -- [max 14]
L.SAMPLE_ZONE = "Schlingendorntal"

-- Shared lines (alarm, guild book, hit list) ------------------------------------------------------
L.GUILD_LINE_IN_GUILD   = "steht im Gildenbuch"
L.GUILD_LINE_IN_FRIENDS = "steht im Freundesbuch"
L.GUILD_LINE_LISTED_BY  = "steht im Buch von {names}"
L.GUILD_LINE_KILLED_GUILD   = "hat {kills}× Kollegen getötet"
L.GUILD_LINE_KILLED_FRIENDS = "hat {kills}× Freunde getötet"
L.GUILD_LINE_KILLED_BOTH    = "hat {kills}× Kollegen und Freunde getötet"
L.GUILD_LINE_LAST = "{text}, zuletzt {name}"
L.HUNT_LINE_BY       = "freigegeben von {names}"
L.HUNT_LINE_RELEASED = "zur Jagd freigegeben"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "unter Verdacht"
L.TALLY_MANUAL   = "von Hand eingetragen"
L.TALLY_NONE     = "noch keine Tat"
L.TALLY_KILLED   = "{times} getötet"
L.TALLY_ASSISTED = "{times} beteiligt"
L.PLACE_UNKNOWN  = "unbekannter Ort"
L.GKILLS_CAP     = "mindestens {count}"
L.NAMELIST_MORE  = "{names} und {count} {count|weiterer|weitere}"

-- Time and money ----------------------------------------------------------------------------------
L.TIME_FMT_WHEN      = "%d.%m. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY       = "%d.%m."
L.TIME_FMT_DAY_YEAR  = "%d.%m.%y"
L.TIME_NEVER   = "nie"
L.TIME_JUST    = "gerade eben"
L.TIME_MINUTES = "vor {count} Min."                -- [max 14]
L.TIME_HOURS   = "vor {count} Std."                -- [max 14]
L.TIME_DAYS    = "vor {count} {count|Tag|Tagen}"   -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}k"

-- State of guild and friends ----------------------------------------------------------------------
L.GUILD_HEARD    = "{count} {count|Kollege|Kollegen} mit DeathNote gehört."
L.HEALTH_NOGUILD = "Du bist in keiner Gilde, es wird nichts geteilt."
L.HEALTH_OFF     = "Teilen ist ausgeschaltet."
L.HEALTH_SHORT_NOGUILD = "Keine Gilde"     -- [max 18]
L.HEALTH_SHORT_OFF     = "Teilen ist aus"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Gesperrt"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Abgelehnt"       -- [max 18]
L.HEALTH_SHORT_HOLD    = "Wartet"          -- [max 18]
L.HEALTH_SHORT_ASKED   = "Angefragt"       -- [max 18]
L.HEALTH_SHORT_FAIL    = "Geht nicht"      -- [max 18]

-- Alarm sounds and sound channels -----------------------------------------------------------------
L.SOUND_NONE        = "Kein Ton"       -- [max 16]
L.SOUND_RAIDWARNING = "Raid-Warnung"   -- [max 16]
L.SOUND_BELL        = "Glocke"         -- [max 16]
L.SOUND_GONG        = "Gong"           -- [max 16]
L.SOUND_HEARTBEAT   = "Herzschlag"     -- [max 16]
L.SOUND_FEATHER     = "Feder"          -- [max 16]
L.SOUND_SIREN       = "Sirene"         -- [max 16]
L.CHANNEL_MASTER    = "Master"         -- [max 16]
L.CHANNEL_SFX       = "Effekte"        -- [max 16]
L.CHANNEL_DIALOG    = "Dialog"         -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} steht jetzt im Buch."
L.CHAT_REMOVED   = "{name} ist aus dem Buch gestrichen."
L.CHAT_SYNC_WAIT = "Gerade erst abgeglichen. Nochmal in {seconds} Sek."

-- Empty book (first tab) --------------------------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Noch kein Name eingetragen."  -- large line in the middle of the empty page
L.EMPTY_WANTED_SUB  = "Geh mal vor die Tür."          -- small line below it

-- Help for the commands (/dn hilfe) ---------------------------------------------------------------
L.HELP_TOGGLE   = "/dn  Buch auf/zu"
L.HELP_ADD      = "/dn add <Name [Nachname]>  Täter von Hand ins Buch eintragen"
L.HELP_DEL      = "/dn del <Name [Nachname]>  Täter aus dem Buch streichen"
L.HELP_QUIET    = "/dn still  Alarm aus/an"
L.HELP_TEST     = "/dn test  Probe-Alarm zeigen"
L.HELP_GUILD    = "/dn gilde  Gildenbuch: Stand und welche Kollegen DeathNote haben"
L.HELP_FRIENDS  = "/dn freunde  Freundesbuch: Stand und welche Freunde DeathNote haben"
L.HELP_SYNC     = "/dn sync  Gildenbuch und Freundesbuch jetzt abgleichen"
L.HELP_HUNT     = "/dn jagd <Name [Nachname]>  zur Jagd freigeben (ohne Name: die Abschussliste)"
L.HELP_CALLOFF  = "/dn abblasen <Name [Nachname]>  eigene Freigabe zurücknehmen"
L.HELP_LANG     = "/dn sprache <Kennung>  Sprache des Buchs (deDE, enUS, frFR ...), nach /reload"
L.HELP_THEME = "/dn einband <Name>  Einband des Buchs, nach /reload"
L.HELP_PROBE    = "/dn probe  Fehlersuche: was das Spiel dem Buch verrät"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  Fehlersuche, dazu das Kampflog prüfen"
L.HELP_DEBUG    = "/dn debug  Fehlersuche: jeden Tod genau mitschreiben (an/aus)"
L.HELP_HELP     = "/dn hilfe  diese Hilfe"
L.HELP_SILENT_ZONES = "In Dungeons, Schlachtfeldern und Arenen schweigt das Buch von selbst."

-- Chat lines --------------------------------------------------------------------------------------
L.WORD_ON  = "an"
L.WORD_OFF = "aus"
L.CHAT_WHO_ADD  = "Wen denn? /dn add <Name>"
L.CHAT_WHO_DEL  = "Wen denn? /dn del <Name>"
L.CHAT_WHO_CALLOFF = "Wen denn? /dn abblasen <Name>"
L.CHAT_BAD_NAME = "Ungültiger Name."
L.CHAT_NOT_IN_BOOK = "Nicht im Buch: {name}"
L.CHAT_ALARM_ON  = "Alarm an."
L.CHAT_ALARM_OFF = "Alarm aus."
L.CHAT_DEBUG = "Mitschnitt für die Fehlersuche {state}."
L.CHAT_UNKNOWN_CMD = "Unbekannter Befehl. Hilfe: /dn hilfe"
L.CHAT_GUILD_NOT_LOADED = "Das Gildenbuch ist nicht geladen."
L.CHAT_NO_GUILD = "Du bist in keiner Gilde (oder das Spiel kennt sie noch nicht)."
L.CHAT_GUILD_STATE = "Gilde {guild}: Teilen {share}, Empfangen {receive}."
L.CHAT_GUILD_BOOK = "Gildenbuch: {enemies} Täter ({listed} nur von Hand eingetragen), {deeds} {deeds|Tat|Taten}; bei {foreign} davon sind Kollegen beteiligt. Einträge von Hand teilen: {manual}."
L.CHAT_STATE_OK   = "Stand: {text}"
L.CHAT_STATE_WARN = "Achtung: {text}"
L.CHAT_NO_MATES   = "Noch kein Kollege mit DeathNote gehört."
L.CHAT_HAVE_DN      = "DeathNote haben: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote haben: {names} und {count} weitere"
L.CHAT_SYNC_ASKED = "Abgleich angefragt. Antworten kommen in den nächsten Sekunden."
L.CHAT_SYNC_FAIL  = "Abgleich geht nicht: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "keine Gilde oder Teilen ist aus."
L.CHAT_FRIENDS_NOT_LOADED = "Das Freundesbuch ist nicht geladen."
L.CHAT_FRIENDS_STATE = "Freunde: Teilen {share}, {online} von {total} online."
L.CHAT_FRIENDS_BOOK  = "Freundesbuch: {enemies} Täter ({listed} nur von Hand eingetragen), {deeds} {deeds|Tat|Taten}."
L.CHAT_NO_FRIENDS    = "Noch kein Freund mit DeathNote gehört."
L.CHAT_HUNT_NOT_LOADED = "Die Abschussliste ist nicht geladen."
L.CHAT_HUNT_UNKNOWN = "Unbekannt: {name}. Bitte mit Nachnamen, so wie der Name im Spiel steht."
L.CHAT_HUNT_CAP     = "Freigeben geht nicht: höchstens {own} eigene Freigaben und {targets} Ziele je Liste."
L.CHAT_HUNT_NOWHERE = "Freigeben geht gerade nicht: keine Gilde und Teilen mit Freunden ist aus."
L.CHAT_HUNT_BOTH    = "{name} ist zur Jagd freigegeben, für Gilde und Freunde."
L.CHAT_HUNT_GUILD   = "{name} ist zur Jagd freigegeben, für die Gilde."
L.CHAT_HUNT_FRIENDS = "{name} ist zur Jagd freigegeben, für die Freunde."
L.CHAT_CALLED_OFF   = "Jagd auf {name} abgeblasen."
L.CHAT_NO_OWN_CALL  = "Keine eigene Freigabe für {name}."
L.CHAT_LANG_CURRENT = "Sprache jetzt: {lang}. Ändern: /dn sprache <Kennung>"
L.CHAT_LANG_LIST    = "Kennungen: {codes}"
L.CHAT_LANG_BAD     = "Unbekannte Sprache: {code}"
L.CHAT_LANG_SET     = "Sprache: {lang}."
L.CHAT_LANG_RELOAD  = "Sprache: {lang}. Gilt nach /reload."
L.CHAT_THEME_CURRENT = "Einband jetzt: {theme}. Ändern: /dn einband <Name>"
L.CHAT_THEME_LIST = "Einbände: {themes}"
L.CHAT_THEME_BAD = "Unbekannter Einband: {name}"
L.CHAT_THEME_SET = "Einband: {theme}."
L.CHAT_THEME_RELOAD = "Einband: {theme}. Gilt nach /reload."
L.THEME_NOTEBOOK = "Das schwarze Buch"
L.THEME_HARBOR = "Kaperbuch"
L.THEME_TRADE = "Fachbetrieb"

-- First contact -----------------------------------------------------------------------------------
L.WELCOME = "Das Buch liegt bereit. Wer dich in der offenen Welt tötet, steht danach drin. Aufschlagen mit /dn oder am Minimap-Knopf."
L.WELCOME_PLATES = "Feindliche Namensplaketten sind aus. Ohne sie sieht der Alarm nur dein Ziel."
L.WELCOME_SHARE = "Gilde und Freunde mit DeathNote lesen mit. Notizen und Verdacht bleiben bei dir."

-- Tooltip line ------------------------------------------------------------------------------------
L.TIP_IN_BOOK   = "IM BUCH:"
L.TIP_HUNT      = "ABSCHUSSLISTE:"
L.TIP_GUILDBOOK = "GILDENBUCH:"
L.TIP_PARDONED  = "begnadigt"
L.TIP_RANK      = "Rang {rank}"
L.TIP_REVENGE   = "Rache {times}"
L.TIP_LISTED_BY = "im Buch von {names}"
L.TIP_NOTE      = "Notiz: {note}"

-- On-screen notice (heads are letter-spaced in the code) ------------------------------------------
L.BANNER_TIP          = "Klick: aufschlagen · Rechtsklick: weg"
L.BANNER_NEW          = "NEUER EINTRAG"        -- [max 24]
L.BANNER_NEW_LINE     = "steht jetzt im Buch"
L.BANNER_AGAIN        = "SCHON WIEDER"         -- [max 24]
L.BANNER_AGAIN_LINE   = "hat dich zum {count}. Mal getötet"
L.BANNER_SUSPECT      = "VERDACHT"             -- [max 24]
L.BANNER_SUSPECT_LINE = "steht unter Verdacht, zu klären im Buch"
L.BANNER_UNCLEAR      = "TÄTER UNKLAR"         -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|Kandidat|Kandidaten}"
L.BANNER_UNCLEAR_LINE = "Klick: unter Zu klären den Täter festlegen"
L.BANNER_REVENGE      = "VERGELTUNG"           -- [max 24]
L.BANNER_REVENGE_LINE = "Rache genommen ({count}×)"
L.BANNER_GUILD        = "GILDE"                -- [max 24]
L.BANNER_FRIENDS      = "FREUNDE"              -- [max 24]
L.BANNER_KILLED_BY    = "wurde von {name} getötet"
L.BANNER_HUNT         = "ABSCHUSSLISTE"        -- [max 24]
L.BANNER_BAGGED       = "erlegt von {name}, {time}"

-- State of guild and friends (status line, house rules, /dn gilde) --------------------------------
L.SYNC_GUILD_OFF   = "Teilen ist ausgeschaltet (Hausordnung, Blatt Gilde)."
L.SYNC_FRIENDS_OFF = "Teilen mit Freunden ist aus."
L.SYNC_NOBODY      = "Keine Gilde und keine Freunde zum Teilen."
L.SYNC_SHORT_NOBODY = "Nichts geteilt"            -- [max 18]
L.SYNC_PREFIX      = "Das Spiel lässt keinen Empfang zu. Neu einloggen hilft."
L.SYNC_SHORT_PREFIX = "Empfang geht nicht"        -- [max 18]
L.SYNC_BLOCKED     = "Der Realm blockt das Senden. Weitergeben mit Buch sichern."
L.SYNC_SHORT_BLOCKED = "Realm blockt Senden"      -- [max 22]
L.SYNC_FAILING     = "Senden klappt gerade nicht, es wird erneut versucht."
L.SYNC_SHORT_FAILING = "Senden hakt"              -- [max 18]
L.SYNC_HOLD        = "Senden wartet, {wait}."
L.SYNC_HOLD_INSTANCE = "bis du die Instanz verlässt"
L.SYNC_HOLD_COMBAT   = "bis du aus dem Kampf bist"
L.SYNC_HOLD_LOCKDOWN = "bis der Chat wieder frei ist"
L.SYNC_HOLD_AGAIN    = "bis es wieder geht"
L.SYNC_HOLD_SHORT_INSTANCE = "Wartet: Instanz"    -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Wartet: im Kampf"   -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Wartet: Chat zu"    -- [max 18]
L.SYNC_QUIET       = "Gesendet, aber noch kein Kollege mit DeathNote gehört."
L.SYNC_READY       = "Bereit. Noch kein Kollege mit DeathNote gehört."
L.SYNC_RUNNING     = "Läuft: {count} {count|Kollege|Kollegen} mit DeathNote."
L.SYNC_RUNNING_ALL = "Läuft: {count} mit DeathNote in Gilde und Freunden."
L.FRIENDS_OFF      = "Teilen mit Freunden ist aus (Hausordnung, Blatt Gilde)."
L.FRIENDS_BLOCKED  = "Der Realm blockt Flüstern. Freunde bekommen nichts."
L.FRIENDS_SHORT_BLOCKED = "Realm blockt Flüstern" -- [max 22]
L.FRIENDS_FAILING  = "Flüstern klappt gerade nicht, es wird erneut versucht."
L.FRIENDS_SHORT_FAILING = "Flüstern hakt"         -- [max 18]
L.FRIENDS_NONE_LISTED = "Keine Freunde auf der Freundesliste."
L.FRIENDS_NONE_ONLINE = "Gerade ist kein Freund online."
L.FRIENDS_SHORT_NONE_ONLINE = "Kein Freund online" -- [max 18]
L.FRIENDS_QUIET    = "Gefragt, aber noch kein Freund mit DeathNote gehört."
L.FRIENDS_READY    = "Bereit. Noch kein Freund mit DeathNote gehört."
L.FRIENDS_HOLD     = "Senden an Freunde wartet, bis es wieder geht."
L.FRIENDS_RUNNING  = "Läuft: {count} {count|Freund|Freunde} mit DeathNote."
L.NOTE_FROM_GUILD  = "Aus dem Gildenbuch übernommen ({kills}× getötet in der Gilde)."

-- Importing a book: messages ----------------------------------------------------------------------
L.IMPORT_NO_DB      = "Datenbank nicht geladen."
L.IMPORT_NO_TEXT    = "Kein Text."
L.IMPORT_NO_HEADER  = "Die erste Zeile fehlt (sie beginnt mit {header}). Bitte den ganzen Text kopieren."
L.IMPORT_NOT_EXPORT = "Kein DeathNote-Export (Kopfzeile fehlt oder falsche Version)."
L.IMPORT_TOO_LONG   = "Zu viele Zeilen (höchstens {count})."
L.IMPORT_BAD_KEY    = "Zeile {line}: ungültiger Schlüssel."
L.IMPORT_BAD_TIME   = "Zeile {line}: ungültige Zeit."
L.IMPORT_BROKEN     = "Zeile {line} ist unvollständig oder kaputt (Text abgeschnitten?). Nichts eingelesen."

-- /dn probe ---------------------------------------------------------------------------------------
L.WORD_YES = "ja"
L.WORD_NO  = "nein"
L.PROBE_HEAD = "Sonde: {apis}/{apisAll} Schnittstellen da, {events}/{eventsAll} Ereignisse registrierbar."
L.PROBE_MISSING = "Fehlt: {list}"
L.PROBE_NOT_REGISTERABLE = "Nicht registrierbar: {list}"
L.PROBE_SOURCES = "Recap jetzt: {recap} · Meter: {meter} · Combat-Log: {clog}"
L.PROBE_READABLE = "lesbar"
L.PROBE_DEAD = "tot"
L.PROBE_PLATES = "Feindliche Namensplaketten: {plates} · Offene Welt: {open}"
L.PROBE_PLATES_OFF = "AUS (nur Ziel/Maus erkennen Feinde)"
L.PROBE_TARGET = "Ziel: Name={name} GUID={guid} Klasse={class} feindlich={enemy} zielt auf mich={me}"
L.PROBE_GUILD = "Gilde: Präfix {prefix} · Senden {send} · letzter Rückgabewert {result} · gesendet {sent}, empfangen {received}, verworfen {dropped}"
L.PROBE_REGISTERED = "registriert"
L.PROBE_NOT_REGISTERED = "NICHT registriert ({result})"
L.PROBE_POSSIBLE = "möglich"
L.PROBE_ABSENT = "fehlt"
L.PROBE_WAITS = " · wartet: {why}"
L.PROBE_LISTED = "Hand-Einträge (M): gesendet {sent}, empfangen {received}, verworfen {dropped} · gestrichen (X): gesendet {usent}, empfangen {ureceived}, verworfen {udropped}"
L.PROBE_GUILDBOOK = "Gildenbuch: {text}"
L.PROBE_SAVED = "Gespeichert in DeathNoteDB.probe (nach /reload in der Datei)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Neueste"  -- [max 14]
L.SORT_NAME = "Name"  -- [max 14]
L.SORT_SEEN = "Gesehen"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Wer dich in der offenen Welt tötet, steht danach hier. Von selbst."
L.EMPTY_OPEN_HEAD = "Nichts zu klären."
L.EMPTY_JOURNAL_HEAD = "Noch nie gestorben."
L.EMPTY_JOURNAL_SUB = "Respekt. Oder Lüge."
L.EMPTY_NOGUILD_HEAD = "Keine Gilde."
L.EMPTY_NOGUILD_SUB = "Allein stirbt es sich auch."
L.EMPTY_GUILDOFF_HEAD = "Das Gildenbuch ist zu."
L.EMPTY_GUILDOFF_SUB = "Teilen ist aus. Die Hausordnung weiß, wo."
L.EMPTY_GUILDNIL_HEAD = "Noch niemand aus der Gilde gehört."
L.EMPTY_GUILDNIL_SUB = "Dein Buch geht raus, sobald ein Kollege DeathNote hat."
L.EMPTY_GUILDQUIET_HEAD = "Im Gildenbuch steht noch nichts."
L.EMPTY_GUILDQUIET_SUB = "Deine Kollegen hatten bisher Ruhe."
L.EMPTY_FRIENDSOFF_HEAD = "Das Freundesbuch ist zu."
L.EMPTY_FRIENDSOFF_SUB = "Teilen mit Freunden ist aus. Die Hausordnung weiß, wo."
L.EMPTY_FRIENDSNIL_HEAD = "Noch kein Freund mit DeathNote gehört."
L.EMPTY_FRIENDSNIL_SUB = "Dein Buch geht raus, sobald ein Freund DeathNote hat."
L.EMPTY_FRIENDSQUIET_HEAD = "Bei deinen Freunden steht noch nichts."
L.EMPTY_FRIENDSQUIET_SUB = "Deine Freunde hatten bisher Ruhe."
L.EMPTY_NOBODY_HEAD = "Keine Gilde, keine Freunde."
L.EMPTY_NOBODY_SUB = "Allein stirbt es sich auch."
L.EMPTY_NOBODY_HINT = "Haben Kollegen oder Freunde von deiner Freundesliste DeathNote, steht hier, was ihnen passiert."
L.EMPTY_SHAREDNIL_HEAD = "Noch niemand mit DeathNote gehört."
L.EMPTY_SHAREDNIL_SUB = "Dein Buch geht raus, sobald Kollegen oder Freunde DeathNote haben."
L.EMPTY_SHAREDQUIET_HEAD = "Hier steht noch nichts."
L.EMPTY_SHAREDQUIET_SUB = "Gilde und Freunde hatten bisher Ruhe."
L.EMPTY_HUNT_HEAD = "Die Abschussliste ist leer."
L.EMPTY_HUNT_SUB = "Am Plakat: Zur Jagd freigeben."
L.EMPTY_HUNT_HINT = "Oder im Chat: /dn jagd Name Nachname. Alle in Gilde und bei Freunden sehen es."
L.EMPTY_SEARCH_HEAD = "Kein Treffer."
L.EMPTY_SEARCH_SUB = "Enter trägt den Namen ins Buch ein."
L.EMPTY_SEARCHRO_HEAD = "Kein Treffer."
L.EMPTY_SEARCHRO_SUB = "Anders schreiben hilft manchmal."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "DAS BUCH"  -- [max 12]
L.MANUAL_BOOK = "Wer dich in der offenen Welt tötet, wird von selbst eingetragen. Ein Klick auf die Meldung nach dem Tod schlägt den Täter auf."
L.MANUAL_WANTED_HEAD = "GESUCHT"  -- [max 12]
L.MANUAL_WANTED = "Deine Täter, der schlimmste zuerst. Ein Klick zeigt das Plakat mit Taten und Notiz. Begnadigte stehen durchgestrichen am Ende."
L.MANUAL_UNSOLVED_HEAD = "ZU KLÄREN"  -- [max 13]
L.MANUAL_UNSOLVED = "War nicht eindeutig, wer es war, wartet der Fall hier. Ein Klick auf einen Namen legt den Täter fest."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Taucht ein Täter als Namensplakette, Ziel oder unter der Maus auf, meldet sich das Buch. Ein Klick nimmt ihn ins Ziel, im Kampf erst danach."
L.MANUAL_ADD_HEAD = "EINTRAGEN"  -- [max 12]
L.MANUAL_ADD = "Namen ins Suchfeld schreiben, Enter. Rechtsklick auf eine Zeile: Rache vermerken, begnadigen, streichen."
L.MANUAL_GUILD_HEAD = "GILDE"  -- [max 12]
L.MANUAL_GUILD = "Kollegen und Freunde mit DeathNote sehen deine sicheren Tode und Einträge von Hand. Plakat oder /dn jagd Name: zur Jagd freigeben. Klick aufs Kopfgeld: eigenes ausloben, eine Ansage, eingelöst wird untereinander."
L.MANUAL_SHARE_HEAD = "WEITERGEBEN"  -- [max 12]
L.MANUAL_SHARE = "Hausordnung, Buch sichern: ein Text zum Kopieren, für alle ohne DeathNote."
L.MANUAL_QUIET_HEAD = "RUHE"  -- [max 12]
L.MANUAL_QUIET = "In Dungeons und Schlachtfeldern schweigt der Alarm. Sonst: Mittelklick auf den Minimap-Knopf oder /dn still."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "{name} wirklich aus dem Buch streichen?\nAlle Taten und die Notiz gehen verloren."
L.CONFIRM_DELETE_OK = "Streichen"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Das Gildenbuch auf diesem Rechner leeren?\nSeine Abschussliste geht mit, deine eigenen Freigaben bleiben.\nDein eigenes Buch bleibt, wie es ist."
L.CONFIRM_GUILD_CLEAR_OK = "Leeren"  -- [max 14]
L.CONFIRM_CANCEL = "Abbrechen"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GOLD"  -- [max 14]
L.BOUNTY_SILVER = "{count} SILBER"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Bestätigen"  -- [max 19]
L.ACT_DISMISS = "Verwerfen"  -- [max 19]
L.ACT_HUNT_AGAIN = "Wieder jagen"  -- [max 19]
L.ACT_REVENGE = "Rache vermerken"  -- [max 19]
L.ACT_PARDON = "Begnadigen"  -- [max 19]
L.ACT_STRIKE = "Streichen"  -- [max 19]
L.ACT_OPEN_OWN = "Im Buch aufschlagen"  -- [max 19]
L.ACT_ADOPT = "Ins eigene Buch"  -- [max 19]
L.ACT_CALLOFF = "Jagd abblasen"  -- [max 19]
L.ACT_RELEASE = "Zur Jagd freigeben"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "gesehen {time}"
L.ROW_NOT_SEEN = "noch nicht gesichtet"
L.ROW_PARDONED = "begnadigt"
L.ROW_SUSPECT = "Verdacht"
L.MARK_REVENGE = "RACHE {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Täter unklar"
L.MARK_CANDIDATES = "{count} {count|KANDIDAT|KANDIDATEN}"  -- [max 16]
L.MARK_SUSPECT = "VERDACHT"  -- [max 16]
L.ROW_NO_PLAYER = "Kein Spieler"
L.ROW_UNCLEAR = "Hergang unklar"
L.MARK_NOT_COUNTED = "ZÄHLT NICHT"  -- [max 16]
L.ROW_LISTED_BY = "eingetragen von {names}"
L.ROW_GKILLED = "{kills}× getötet"
L.ROW_VICTIMS = "{count} Opfer"
L.ROW_LAST = "zuletzt {text}"
L.MARK_IN_BOOK = "IM BUCH"  -- [max 16]
L.MEMBER_KILLERS = "{count} Täter"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|Tod|Tode}"  -- [max 12]
L.MEMBER_LISTED = "{count} von Hand"  -- [max 14]
L.MEMBER_ME = "das sehen die anderen von dir"
L.MEMBER_NOTHING = "noch nichts geteilt"
L.MEMBER_LAST_DIED = "zuletzt gestorben {time}"
L.MARK_YOU = "du"  -- [max 16]
L.MARK_FRIEND = "FREUND"  -- [max 16]
L.MARK_BOTH = "KOLLEGE, FREUND"  -- [max 20]
L.MARK_TAKEN_DOWN = "ERLEGT {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DEAD OR ALIVE"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "TATEN"  -- [max 14]
L.POSTER_NOTE = "NOTIZ"  -- [max 8]
L.POSTER_BOUNTY = "KOPFGELD"  -- [max 12]
L.ROLE_ASSIST = "beteiligt"  -- [max 14]
L.ROLE_SUSPECT = "Verdacht"  -- [max 14]
L.POSTER_LEVEL = "Stufe {level}"
L.POSTER_GUILD = "Gilde: {guild}"
L.POSTER_LAST_SEEN = "Zuletzt gesehen {time}"
L.POSTER_NOT_SEEN = "Noch nicht gesichtet"
L.POSTER_ONLY_SUSPECT = "Nur Verdacht, keine belegte Tat."
L.POSTER_NO_DEEDS = "Keine Taten vermerkt."
L.TIP_LISTED_AT = "Eingetragen {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Todesursache: {spell}"
L.TIP_VICTIM = "Opfer: {name}"
L.TIP_VICTIM_LEVEL = "Opfer: {name} (Stufe {level})"
L.TIP_KILLER_LEVEL = "Stufe des Täters: {level}"
L.TIP_ASSISTS = "Beteiligt: {names}"
L.TIP_ROLE_ASSIST = "Beteiligt, nicht den Todesstoß gesetzt."
L.TIP_ROLE_SUSPECT = "Nur Verdacht, nicht belegt."
L.MORE_LINE = "… und {count} weitere"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GILDENBUCH"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Im Buch von: {names}"
L.POSTER_SEEN = "Gesehen {time}"
L.POSTER_SEEN_BY = "Gesehen {time} von {name}"
L.TIP_IN_BOOK_OF = "Im Buch von"
L.POSTER_REMARK = "VERMERK"  -- [max 12]
L.POSTER_BY_HAND = "VON HAND EINGETRAGEN"  -- [max 22]
L.POSTER_VICTIMS = "OPFER"  -- [max 12]
L.POSTER_LISTED = "EINGETRAGEN"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Von Hand eingetragen."
L.POSTER_NO_DEEDS_SENT = "Keine Taten übermittelt."
L.POSTER_NONE_KNOWN = "keins bekannt"
L.POSTER_NO_NAMES = "keine Namen übermittelt"
L.TIP_VICTIMS = "Opfer"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Freigegeben {time}"
L.HUNT_REASON = "Grund: {reason}"
L.POSTER_HUNTLIST = "ABSCHUSSLISTE"  -- [max 24]
L.POSTER_RELEASED_N = "{times} zur Jagd freigegeben"
L.POSTER_RELEASED_BY = "Freigegeben von {names}"
L.POSTER_TAKEN_DOWN = "ERLEGT"  -- [max 12]
L.POSTER_NOT_YET = "NOCH NICHT"  -- [max 18]
L.POSTER_CALLS = "FREIGEGEBEN"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Niemand mehr."
L.POSTER_LAST = "ZULETZT"  -- [max 13]
L.POSTER_TAKEN_BY = "erlegt von {name}, {time}"
L.POSTER_TAKEN_NOBODY = "noch von niemandem erlegt"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Todesfall"  -- [max 20]
L.CASE_ASSISTS = "BETEILIGT"  -- [max 24]
L.CASE_PICK = "TÄTER FESTLEGEN"  -- [max 24]
L.CASE_NOT_COUNTED = "Zählt nicht (Instanz, Schlachtfeld oder Duell)"
L.CASE_KILLER = "TÄTER"  -- [max 24]
L.CASE_KILLER_SUSPECT = "TÄTER (VERDACHT)"  -- [max 24]
L.CASE_CLICK_NAME = "Klick auf den Namen schlägt sein Plakat auf."
L.CASE_GONE = "Steht nicht mehr im Buch."
L.CASE_KILLER_UNCLEAR = "TÄTER UNKLAR"  -- [max 24]
L.CASE_SEVERAL = "Mehrere kamen in Frage. Wessen Name gehört ins Buch?"
L.CASE_NOBODY = "Niemand kam in Frage."
L.CASE_HOW = "HERGANG"  -- [max 24]
L.CASE_PVE = "Ein Monster oder die Umwelt. Kein Fall für das Buch."
L.CASE_UNCLEAR = "Unklar"
L.CASE_DARK = "Die Spurensicherung tappt im Dunkeln."
L.TIP_MORE_CANDIDATES = "Weitere Kandidaten"
L.CASE_SOURCE_SUSPECT = "Verdacht: hatte dich kurz vor dem Tod im Ziel."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-Zeile über Tätern"  -- [max 44]
L.OPT_MINIMAP = "Minimap-Knopf zeigen"  -- [max 44]
L.OPT_ALERT = "Alarm, wenn ein Täter auftaucht"  -- [max 44]
L.OPT_FLASH = "Bildschirmrand rot blitzen"  -- [max 44]
L.OPT_SUSPECTS = "Auch Verdächtige melden"  -- [max 44]
L.OPT_DEATHMSG = "Meldung nach einem PvP-Tod"  -- [max 44]
L.OPT_G_SHARE = "Eigene Tode teilen"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Von Hand Eingetragene teilen"  -- [max 44]
L.OPT_G_RECEIVE = "Gildenbuch empfangen"  -- [max 44]
L.OPT_G_ALERT = "Bei Tätern aus dem Gildenbuch warnen"  -- [max 44]
L.OPT_G_ALERTLISTED = "Auch bei von Hand Eingetragenen warnen"  -- [max 44]
L.OPT_G_ANNOUNCE = "Melden, wenn ein Kollege getötet wird"  -- [max 44]
L.OPT_G_SIGHTINGS = "Sichtungen teilen"  -- [max 44]
L.OPT_F_SHARE = "Mit der Gilde teilen"  -- [max 44]
L.OPT_F_FRIENDS = "Mit Freunden teilen"  -- [max 44]
L.OPT_F_ALERT = "Bei Tätern von Gilde und Freunden warnen"  -- [max 44]
L.OPT_F_ALERTHUNT = "Bei Zielen der Abschussliste warnen"  -- [max 44]
L.OPT_F_ANNOUNCE = "Melden, wenn Kollegen oder Freunde sterben"  -- [max 44]
L.OPT_F_SIGHTINGS = "Sichtungen mit Gilde und Freunden teilen"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Gilde"  -- [max 14]
L.SET_BOOK_SIZE = "Größe des Buchs"  -- [max 34]
L.SET_LANGUAGE = "Sprache"  -- [max 16]
L.SET_LANG_AUTO = "Automatisch"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Gilt nach dem Neuladen."  -- [max 28]
L.SET_LANG_RELOAD = "Jetzt neu laden"  -- [max 22]
L.SET_SEC_SHARE = "WEITERGEBEN"  -- [max 24]
L.IO_EXPORT = "Buch sichern"  -- [max 17]
L.IO_IMPORT = "Buch einlesen"  -- [max 17]
L.SET_HINT_BOOK = "Sichern gibt dir das Buch als Text: zum Aufheben oder zum Weitergeben an Leute außerhalb der Gilde. Einlesen fügt zusammen und überschreibt nichts."
L.SET_SEC_SOUND = "TON"  -- [max 24]
L.SET_SOUND = "Ton"  -- [max 22]
L.SET_VOLUME = "Lautstärke"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "SCHWELLE"  -- [max 24]
L.SET_COOLDOWN = "Abklingzeit je Täter"  -- [max 34]
L.SET_MINKILLS = "Alarm ab so vielen Toden durch ihn"  -- [max 34]
L.SET_ALERT_SIZE = "Größe des Alarms"  -- [max 34]
L.SET_TEST_ALERT = "Probealarm"  -- [max 17]
L.SET_G_MINKILLS = "Gildenwarnung ab so vielen Toden"  -- [max 34]
L.SET_F_MINKILLS = "Warnung ab so vielen Toden"  -- [max 34]
L.SET_SEC_STATUS = "STAND"  -- [max 24]
L.SET_SEC_SHARING = "TEILEN"  -- [max 24]
L.SET_SEC_WARN = "WARNEN"  -- [max 24]
L.SET_MORE = "Mehr"  -- [max 12]
L.SET_GUILD_CLEAR = "Gildenbuch leeren"  -- [max 26]
L.SET_HINT_GUILD = "Geteilt wird nur mit der eigenen Gilde. Was von dort kommt, bleibt getrennt von deinem Buch, bis du es selbst übernimmst."
L.SET_HINT_FRIENDS = "Geteilt wird nur mit Gilde und Freunden mit DeathNote."
L.BTN_BACK = "Zurück"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Abgleichen"  -- [max 14]
L.SYNC_AGAIN_IN = "in {seconds} s wieder"  -- [max 16]
L.TIP_FRIENDS = "Freunde"
L.TIP_GUILD_NAME = "Gilde {guild}"
L.TIP_MATES_WITH = "Kollegen mit DeathNote:"
L.TIP_NO_MATE = "Noch kein Kollege mit DeathNote gehört."
L.TIP_FRIENDS_WITH = "Freunde mit DeathNote:"
L.TIP_SHARED = "Geteilt wird: deine sicheren Tode, von Hand Eingetragene und deine Freigaben zur Jagd."
L.TIP_NOT_SHARED = "Nicht geteilt: Notizen, Verdacht, Begnadigte, Eingelesenes."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Einlesen"  -- [max 17]
L.IO_DONE = "Eingelesen: {new} neu, {merged} zusammengeführt."
L.IO_FAILED = "Das hat nicht geklappt."
L.IO_SMALL = "Nur klein"  -- [max 17]
L.IO_ALL = "Alles zeigen"  -- [max 17]
L.IO_MSG_FULL = "Ganzes Buch mit Taten ({size})."
L.IO_MSG_SHORT = "Nur Namen und Zähler ({size}). Mit Taten: {full}."
L.IO_MSG_BIG = "Großes Buch ({size}): Markieren und Kopieren dauern kurz."
L.IO_HELP_EXPORT = "Der Text ist markiert: Strg+C kopiert ihn. Aufheben oder an Freunde weitergeben."
L.IO_HELP_IMPORT = "Gesicherten Text mit Strg+V einfügen, dann Einlesen. Nichts wird überschrieben."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Den Grund sehen alle in deiner Gilde und deine Freunde mit DeathNote."
L.REL_HINT_GUILD = "Den Grund sehen alle in deiner Gilde mit DeathNote."
L.REL_HINT_FRIENDS = "Den Grund sehen deine Freunde mit DeathNote."
L.REL_HEAD = "Zur Jagd freigeben"  -- [max 24]
L.REL_FOR = "FÜR"  -- [max 6]
L.REL_REASON = "GRUND"  -- [max 8]
L.REL_HINT2 = "Deine Notiz bleibt bei dir. Abblasen kannst nur du deine eigene Freigabe."
L.REL_GO = "Freigeben"  -- [max 17]
L.REL_NONE = "Keine Gilde und Teilen mit Freunden ist aus."
L.REL_CAP = "Höchstens {own} eigene Freigaben und {max} Ziele je Liste."
L.REL_FAILED = "Freigeben geht gerade nicht."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Kein Ton: der Alarm zeigt sich nur."
L.SET_HINT_BUILTIN = "Lautstärke dieses Tons folgt dem Kanal in den Spieloptionen."
L.SET_HINT_LEVELS = "Fünf Stufen von leise bis laut. Dazu wirkt der Regler des Kanals in den Spieloptionen."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Gilde & Freunde"  -- [max 18]
L.TIP_HELP_BUTTON = "So geht das Buch"
L.VIEW_HUNT = "Abschussliste"  -- [max 13]
L.VIEW_BY_KILLER = "Nach Täter"  -- [max 13]
L.VIEW_BY_MATE = "Nach Kollege"  -- [max 13]
L.SRC_ALL = "Alle"  -- [max 12]
L.SRC_GUILD = "Gilde"  -- [max 12]
L.SRC_FRIENDS = "Freunde"  -- [max 12]
L.SORT_HIDE_PARDONED = "Begnadigte ausblenden"  -- [max 24]
L.SORT_SHOW_PARDONED = "Begnadigte zeigen"  -- [max 24]
L.SEARCH_ADD = "Suchen oder eintragen …"  -- [max 26]
L.SEARCH_SHORT = "Suchen …"  -- [max 10]
L.SEARCH_KILLER = "Täter suchen …"  -- [max 15]
L.SEARCH_JOURNAL = "Täter oder Ort suchen …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Alle zuklappen"
L.TIP_EXPAND_ALL = "Alle aufklappen"
L.STATUS_NO_PLATES = "Namensplaketten sind aus: der Alarm sieht nur Ziel und Maus."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} gesucht"
L.MM_UNSOLVED = "{count} zu klären"
L.MM_ALERT_OFF = "Alarm ist aus (Mittelklick)"
L.MM_CLICK = "Klick: Buch · Rechtsklick: Hausordnung"
L.MM_MIDDLE = "Mittelklick: Alarm an/aus"
L.MM_DRAG = "Ziehen: am Minimap-Rand verschieben"
L.MM_CHAT_ALERT_ON = "Alarm an."
L.MM_CHAT_ALERT_OFF = "Alarm aus."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GILDENFEIND Nr. 1"  -- [max 25]
L.STAMP_HUNT = "ZUR JAGD FREIGEGEBEN"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} gab sich als dein Freund {friend} aus: abgewiesen."
L.FRIENDS_SHORT_IMPOSTOR = "Fremder abgewiesen"  -- [max 22]
L.ALERT_LEVEL = "Stufe {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "zuletzt Stufe {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Stufe ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · auf der Abschussliste ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|neues Ziel|neue Ziele}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "neu auf der Abschussliste"
L.OPT_F_ANNOUNCEHUNT = "Abschussliste melden: neu und erlegt"  -- [max 44]
L.SET_HUNT_EXPIRE = "Freigaben gelten"  -- [max 30]
L.SET_EXPIRE_NEVER = "immer"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|Tag|Tage}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Freundesbuch leeren"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Das Freundesbuch auf diesem Rechner leeren?\nSeine Abschussliste geht mit, deine eigenen Freigaben bleiben."
L.CONFIRM_CALLOFF_ALL = "Alle deine Freigaben abblasen?\nGilde und Freunde erfahren es nach und nach."
L.CONFIRM_CALLOFF_ALL_OK = "Alle abblasen"  -- [max 14]
L.ACT_CALLOFF_ALL = "Alle meine abblasen"  -- [max 24]
L.ACT_HUNT_HIDE = "Für mich ausblenden"  -- [max 19]
L.ACT_HUNT_SHOW = "Wieder einblenden"  -- [max 19]
L.HUNT_ROW_HIDDEN = "für dich ausgeblendet"
L.HUNT_ROW_CALLS = "{count} {count|Freigabe|Freigaben}: {names}"
L.POSTER_ON_HUNTLIST = "Auf der Abschussliste ({names})"
L.REL_SELF = "Dich selbst kannst du nicht freigeben."
L.REL_MATE = "Das ist einer von euch (Gilde oder Freunde mit DeathNote)."
-- Friends without a surname on the list: which full name stands behind them (1.2.0) ---------------
L.FRIENDS_CONFLICT = "Wer ist dein Freund {friend}: {a} oder {b}? Bitte wählen."
L.FRIENDS_SHORT_CONFLICT = "Freund unklar"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Zwei Spieler geben sich als dein Freund {friend} aus: {a} und {b}. Bis du wählst, nimmt das Buch von keinem etwas an. Gilde & Freunde, Ansicht Nach Kollege: Rechtsklick auf den Namen."
L.MEMBER_CONFLICT = "Rechtsklick: Ist das dein Freund?"  -- [max 40]
L.ACT_TIE_MINE = "Mein Freund: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Bindung lösen"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Die Bindung an {name} lösen?\nWas dieser Name ins Freundesbuch gebracht hat, wird gelöscht; die nächste Meldung unter diesem Vornamen bindet neu."
L.CHAT_FRIENDS_TIES = "Gebundene volle Namen (* = erster Kontakt, noch nicht belegt): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn kopfgeld <Name [Nachname]> <Gold>  eigenes Kopfgeld ausloben (ohne Gold: zurücknehmen)"
L.CHAT_WHO_BOUNTY = "Auf wen? /dn kopfgeld <Name> <Gold>"
L.CHAT_BOUNTY_SET = "{name}: {gold} Gold Kopfgeld ausgelobt. Gilde und Freunde mit DeathNote sehen es."
L.CHAT_BOUNTY_OFF = "{name}: dein Kopfgeld ist zurückgenommen."
L.CHAT_BOUNTY_NONE = "Kein eigenes Kopfgeld auf {name}."
L.CHAT_BOUNTY_BAD = "Kopfgeld: ganze Zahl Gold, 1 bis 99999 (0 nimmt es zurück)."
L.CHAT_BOUNTY_CAP = "Kein Kopfgeld: höchstens {count} eigene."
L.CHAT_BOUNTY_OURS = "Kein Kopfgeld auf dich oder deine Leute (Gilde oder Freunde mit DeathNote)."
L.ACT_BOUNTY = "Kopfgeld ausloben"  -- [max 24]
L.ACT_UNDO = "Rückgängig"  -- [max 19]
L.ACT_REVENGE_TAKE = "Eine Rache abziehen"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, ausgelobt von dir"
L.POSTER_BOUNTY_BY = "{gold}, ausgelobt von {name}"
L.POSTER_BOUNTY_MANY = "Kopfgeld {gold}: {names}"
L.POSTER_AVENGED = "Gerächt von {names}"
L.ROW_AVENGED = "gerächt {times}"
L.BOUNTY_TIP_HEAD = "Dein eigenes Kopfgeld in Gold"
L.BOUNTY_TIP_RULES = "Ganze Zahl, 1 bis 99999. Leer oder 0: zurück zum Wert des Buchs. Enter setzt, Esc bricht ab."
L.BOUNTY_TIP_PROMISE = "Gilde und Freunde mit DeathNote sehen es. Nur eine Ansage, eingelöst wird untereinander."
L.BOUNTY_TIP_CLICK = "Klick: eigenes Kopfgeld ausloben"
L.CHAT_AVENGED = "{name} hat {killer} für dich erledigt."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: {gold} Gold Kopfgeld ausgelobt."
L.CHAT_BOUNTY_UNKNOWN = "{name} steht in keinem deiner Bücher. Kopfgeld nur auf Namen aus einem Buch, so wie das Spiel sie zeigt: Vorname und Nachname."
L.CHAT_BOUNTY_LIST = "Deine Kopfgelder ({count} von {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Du hast kein Kopfgeld ausgelobt."
-- <<< BOOK
-- >>> REPUTE (Ranks.lua, Ledger.lua, 1.3.0) --------------------------------------------------------------------
L.REPUTE_LINE = "Rang {tier} · Weg: {path}"
L.PATH_R = "Verruf"
L.PATH_E = "Ehre"
L.PATH_J = "Jagd"
L.PATH_S = "Schutz"
L.PATH_NONE = "unbeschrieben"
-- <<< REPUTE
-- >>> ALARM (Alert.lua, 1.3.0) ---------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "NACHTRAGEND?"
L.ALERT_LINE_VICTIM = "Stand {score} · von dir getötet, zuletzt {time}"
L.ALERT_LINE_STANDING = "{text} · Stand {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · Stand {score}, quitt"
L.ALERT_LINE_STANDING_AHEAD = "{text} · Stand {score}, überzahlt"
-- <<< ALARM
-- >>> START (Start.lua, 1.3.0) ---------------------------------------------------------------------------------
L.SET_THEME = "Einband"
L.START_HINT = "Beides lässt sich später in der Hausordnung ändern."
L.START_GO = "Los"
L.START_CLOSE_TIP = "So lassen"
L.CHAT_THEME_NEWS = "Neu: das Buch gibt es in anderen Einbänden. Hausordnung, Blatt Buch, oder /dn einband."
L.HELP_START = "/dn start  das Startfenster noch einmal (Sprache und Einband)"
-- <<< START
-- >>> RECORD (1.3.0) -------------------------------------------------------------------------------------------
L.TAB_RECORD = "Strafregister"  -- [max 16]
L.STAMP_QUITT = "QUITT"  -- [max 16]
L.STAMP_OVERPAID = "ÜBERZAHLT"  -- [max 16]
L.STATE_OPEN = "offen"  -- [max 16]
L.STATE_EVEN = "quitt"  -- [max 16]
L.STATE_AHEAD = "überzahlt"  -- [max 16]
L.STATE_VICTIM = "nicht im Buch"  -- [max 24]
L.STAND_SCORE = "{mine} : {his}"  -- [max 9]
L.STAND_LINE = "Stand {score}"
L.STAND_TIP = "du {mine}, er {his}"
L.TIP_IN_RECORD = "IM REGISTER:"
L.TIP_RECORD_LINE = "{times} von dir getötet, zuletzt {time}"
L.RECORD_HEAD = "Eigene Akte"  -- [max 20]
L.RECORD_LOG_HEAD = "Letzte Kills"  -- [max 20]
L.RECORD_NEXT = "noch {points} bis {rank}"
L.RECORD_TOP = "Höchster Rang erreicht."
L.RECORD_BAR_TIP = "{total} von {goal} Punkten"
L.RECORD_NEEDLE_LOW = "ruchlos"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "ehrbar"  -- [max 12]
L.RECORD_NEEDLE_TIP = "Die Nadel: Ehre und Schutz gegen Verruf. Jagd bewegt sie nicht."
L.RECORD_KILLS = "Kills: {kills} · Opfer: {victims}"
L.RECORD_BEST = "Bestmarken: {list}"
L.RECORD_BEST_GAP = "+{count} Stufen"
L.RECORD_BEST_STREAK = "Serie {count}"
L.RECORD_BEST_QUICK = "schnellste Rache {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} Min."
L.DUR_HOURS = "{count} Std."
L.RECORD_AWARDS = "ORDEN"  -- [max 14]
L.RECORD_AWARD_AT = "verliehen {time}"
L.RECORD_AWARD_OPEN = "noch nicht verliehen"
L.RECORD_MORE = "Mehr anzeigen"  -- [max 19]
L.RECORD_BACK = "Zur Akte"  -- [max 19]
L.RECORD_CLEAR = "Register leeren"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Das Strafregister leeren?\nAlle Opfer und die Liste der letzten Kills gehen. Rang, Punkte und Orden bleiben."
L.CONFIRM_RECORD_CLEAR_OK = "Leeren"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "{name} aus dem Strafregister streichen?\nDie verdienten Punkte bleiben."
L.ACT_VICTIM_STRIKE = "Aus dem Register streichen"  -- [max 26]
L.VICTIM_KILLED = "{times} von dir getötet"
L.VICTIM_POINTS = "Punkte für dich: {points}"
L.VICTIM_SCENE = "Tatort: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "EIGENE KILLS"  -- [max 14]
L.KILL_TAG_REVENGE = "Rache"  -- [max 14]
L.KILL_TAG_KICK = "nachgetreten"  -- [max 14]
L.KILL_TAG_GROUP = "Gruppe"  -- [max 14]
L.BAND_GRAU = "grau"  -- [max 12]
L.BAND_GRUEN = "grün"  -- [max 12]
L.BAND_GELB = "gelb"  -- [max 12]
L.BAND_ORANGE = "orange"  -- [max 12]
L.BAND_ROT = "rot"  -- [max 12]
L.BAND_SCHAEDEL = "Schädel"  -- [max 12]
L.BAND_UNBEKANNT = "unbekannt"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "keine Punkte"
L.RECORD_BANDS = "Nach Stufenfarbe"
L.TIP_PATH_R = "Verruf: Kills an Grauen und Grünen."
L.TIP_PATH_E = "Ehre: Kills an Spielern deiner Stufe, Rache."
L.TIP_PATH_J = "Jagd: Kills an Höheren, Zielen der Abschussliste, Kopfgeldern."
L.TIP_PATH_S = "Schutz: Kills an Spielern, die Kollegen oder Freunde getötet haben."
L.SORT_STATE = "Stand"  -- [max 14]
L.SORT_COUNT = "Kills"  -- [max 14]
L.SORT_POINTS = "Punkte"  -- [max 14]
L.CHAT_OWN_KILL = "Strafregister: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Neuer Weg: {path}. Rang: {rank}."
L.BANNER_RANK = "NEUER RANG"  -- [max 24]
L.BANNER_AWARD = "AUSZEICHNUNG"  -- [max 24]
L.OPT_LEDGER = "Strafregister führen"  -- [max 44]
L.OPT_LEDGER_CHAT = "Eigene Kills im Chat melden"  -- [max 44]
L.OPT_VICTIMS = "Warnen, wenn ein eigenes Opfer auftaucht"  -- [max 44]
L.SET_SETTLED = "Alarm bei beglichener Rechnung"  -- [max 34]
L.SET_SETTLED_ALWAYS = "wie immer"  -- [max 10]
L.SET_SETTLED_QUIET = "leise"  -- [max 10]
L.SET_SETTLED_OFF = "gar nicht"  -- [max 10]
L.MANUAL_RECORD_HEAD = "STRAFREGISTER"  -- [max 14]
L.MANUAL_RECORD = "Deine eigenen Todesstöße an Spielern. Plakat und Liste zeigen den Stand „du : er“: offen, quitt oder überzahlt; Rang 1 ist immer ein offener Fall. Jeder Kill bringt Punkte auf vier Konten, daraus werden Rang und Weg. Der Reiter erscheint mit dem ersten Kill. Hausordnung, Blatt Buch: abschalten."
L.POSTER_LAST_SEEN_IN = "Zuletzt gesehen: {zone}, {time}"
-- <<< RECORD
end)
