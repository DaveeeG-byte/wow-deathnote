-- DeathNote: Italiano (itIT). Translated from enUS.lua (meaning from deDE.lua); game terms as in the Italian client.
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.itIT), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
--
-- TOC-Notes: Lista nera per il PvP nel mondo aperto: ricorda chi ti ha ucciso e ti avvisa quando è nei paraggi.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("itIT")) then return end

Locale.Register("itIT", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Ricercati"       -- [max 16]
L.TAB_UNSOLVED = "Irrisolti"       -- [max 16]
L.TAB_DEATHLOG = "Necrologio"      -- [max 16]
L.TAB_GUILD    = "Gilda"           -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Regole della casa"     -- [max 24]
L.HEAD_HELP  = "Istruzioni per l'uso"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Libro"          -- [max 14]
L.SHEET_ALERT = "Allarme"        -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "NEMICO PUBBLICO N. 1"  -- [max 24]
L.STAMP_REVENGE  = "CONTO SALDATO"         -- [max 16]
L.STAMP_PARDONED = "GRAZIA CONCESSA"       -- [max 16]
L.STAMP_SUSPECT  = "SOSPETTO"              -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "NEMICO N. 1 AVVISTATO"         -- [max 30]
L.ALERT_SIGHTED         = "NEMICO PUBBLICO AVVISTATO"     -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "SOSPETTATO AVVISTATO"          -- [max 30]
L.ALERT_TITLE_GUILD     = "NEMICO DELLA GILDA AVVISTATO"  -- [max 30]
L.ALERT_TITLE_FRIENDS   = "ASSASSINO DI AMICI AVVISTATO"  -- [max 30]
L.ALERT_TITLE_HUNT      = "BERSAGLIO DELLA LISTA NERA"    -- [max 30]
L.ALERT_LINE_SUSPECT        = "è sotto sospetto"
L.ALERT_LINE_KILLED         = "ti ha ucciso {times}"
L.ALERT_LINE_KILLED_ASSISTED = "ti ha ucciso {times}, complice {assists}"
L.ALERT_LINE_ASSISTED       = "ha preso parte alla tua morte {times}"
L.ALERT_LINE_MANUAL         = "è nel libro (a mano)"
L.ALERT_LINE_LAST    = "{text}, l'ultima volta {time}"
L.ALERT_LINE_IN      = "{text}, zona: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Vendetta: {times}"
L.ALERT_HINT_CLOSE  = "Clic destro: chiudi"                         -- [max 44]
L.ALERT_HINT_COMBAT = "Bersaglio solo dopo il combattimento"        -- [max 44]
L.ALERT_HINT_TARGET = "Clic: bersaglio  ·  Clic destro: chiudi"     -- [max 44]
L.ALERT_MORE = "+{count} {count|altro|altri}"  -- [max 14]
L.SAMPLE_ZONE = "Valle di Rovotorto"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "è nel libro della gilda"
L.GUILD_LINE_IN_FRIENDS = "è nel libro degli amici"
L.GUILD_LINE_LISTED_BY  = "è nel libro di {names}"
L.GUILD_LINE_KILLED_GUILD   = "ha ucciso compagni di gilda {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "ha ucciso amici {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "ha ucciso compagni di gilda e amici {kills}×"
L.GUILD_LINE_LAST = "{text}, ultima vittima: {name}"
L.HUNT_LINE_BY       = "caccia aperta da {names}"
L.HUNT_LINE_RELEASED = "nella lista nera"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "sotto sospetto"
L.TALLY_MANUAL   = "aggiunto a mano"
L.TALLY_NONE     = "ancora nessun misfatto"
L.TALLY_KILLED   = "ti ha ucciso {times}"
L.TALLY_ASSISTED = "complice {times}"
L.PLACE_UNKNOWN  = "luogo sconosciuto"
L.GKILLS_CAP     = "almeno {count}"
L.NAMELIST_MORE  = "{names} e {count} {count|altro|altri}"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d/%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d/%m/%Y %H:%M"
L.TIME_FMT_DAY       = "%d/%m"
L.TIME_FMT_DAY_YEAR  = "%d/%m/%y"
L.TIME_NEVER   = "mai"
L.TIME_JUST    = "proprio ora"
L.TIME_MINUTES = "{count} min fa"         -- [max 14]
L.TIME_HOURS   = "{count} h fa"           -- [max 14]
L.TIME_DAYS    = "{count} {count|giorno|giorni} fa"  -- [max 16]
L.MONEY_GOLD   = "{count} o"
L.MONEY_SILVER = "{count} a"
L.MONEY_COPPER = "{count} r"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Notizie da {count} {count|compagno|compagni} di gilda con DeathNote."
L.HEALTH_NOGUILD = "Non sei in nessuna gilda, non si condivide nulla."
L.HEALTH_OFF     = "La condivisione è disattivata."
L.HEALTH_SHORT_NOGUILD = "Nessuna gilda"      -- [max 18]
L.HEALTH_SHORT_OFF     = "Condivisione off"   -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Bloccato"           -- [max 18]
L.HEALTH_SHORT_FAILING = "Rifiutato"          -- [max 18]
L.HEALTH_SHORT_HOLD    = "In attesa"          -- [max 18]
L.HEALTH_SHORT_ASKED   = "Richiesto"          -- [max 18]
L.HEALTH_SHORT_FAIL    = "Non funziona"       -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Nessun suono"      -- [max 16]
L.SOUND_RAIDWARNING = "Avviso raid" -- [max 16]
L.SOUND_BELL        = "Campana"           -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Battito"           -- [max 16]
L.SOUND_FEATHER     = "Penna"             -- [max 16]
L.SOUND_SIREN       = "Sirena"            -- [max 16]
L.CHANNEL_MASTER    = "Generale"          -- [max 16]
L.CHANNEL_SFX       = "Effetti"           -- [max 16]
L.CHANNEL_DIALOG    = "Dialoghi"          -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} ora è nel libro."
L.CHAT_REMOVED   = "{name} non è più nel libro."
L.CHAT_SYNC_WAIT = "Appena sincronizzato. Riprova tra {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Ancora nessun nome."
L.EMPTY_WANTED_SUB  = "Esci un po', ogni tanto."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  apri/chiudi il libro"
L.HELP_ADD      = "/dn add <Nome [Cognome]>  scrivi a mano un assassino nel libro"
L.HELP_DEL      = "/dn del <Nome [Cognome]>  depenna un assassino dal libro"
L.HELP_QUIET    = "/dn quiet  allarme off/on"
L.HELP_TEST     = "/dn test  mostra un allarme di prova"
L.HELP_GUILD    = "/dn guild  libro della gilda: stato e quali compagni hanno DeathNote"
L.HELP_FRIENDS  = "/dn friends  libro degli amici: stato e quali amici hanno DeathNote"
L.HELP_SYNC     = "/dn sync  sincronizza ora il libro della gilda e quello degli amici"
L.HELP_HUNT     = "/dn hunt <Nome [Cognome]>  apri la caccia (senza nome: mostra la lista nera)"
L.HELP_CALLOFF  = "/dn calloff <Nome [Cognome]>  ferma la tua caccia"
L.HELP_LANG     = "/dn lang <codice>  lingua del libro (enUS, deDE, frFR ...), dopo /reload"
L.HELP_THEME = "/dn theme <nome>  copertina del libro, dopo /reload"
L.HELP_PROBE    = "/dn probe  diagnostica: cosa il gioco rivela al libro"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  diagnostica, con prova del registro di combattimento"
L.HELP_DEBUG    = "/dn debug  diagnostica: annota ogni morte nei dettagli (on/off)"
L.HELP_HELP     = "/dn help  questo aiuto"
L.HELP_SILENT_ZONES = "In spedizioni, campi di battaglia e arene il libro tace da solo."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "on"
L.WORD_OFF = "off"
L.CHAT_WHO_ADD  = "Chi? /dn add <Nome>"
L.CHAT_WHO_DEL  = "Chi? /dn del <Nome>"
L.CHAT_WHO_CALLOFF = "Chi? /dn calloff <Nome>"
L.CHAT_BAD_NAME = "Nome non valido."
L.CHAT_NOT_IN_BOOK = "Non è nel libro: {name}"
L.CHAT_ALARM_ON  = "Allarme attivo."
L.CHAT_ALARM_OFF = "Allarme disattivato."
L.CHAT_DEBUG = "Registro diagnostico: {state}."
L.CHAT_UNKNOWN_CMD = "Comando sconosciuto. Aiuto: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Il libro della gilda non è caricato."
L.CHAT_NO_GUILD = "Non sei in nessuna gilda (o il gioco non lo sa ancora)."
L.CHAT_GUILD_STATE = "Gilda {guild}: condivisione {share}, ricezione {receive}."
L.CHAT_GUILD_BOOK = "Libro della gilda: {enemies} assassini ({listed} solo aggiunti a mano), {deeds} {deeds|misfatto|misfatti}, {foreign} assassini di compagni di gilda. Condividere le voci a mano: {manual}."
L.CHAT_STATE_OK   = "Stato: {text}"
L.CHAT_STATE_WARN = "Attenzione: {text}"
L.CHAT_NO_MATES   = "Ancora nessuna notizia da compagni di gilda con DeathNote."
L.CHAT_HAVE_DN      = "Hanno DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Hanno DeathNote: {names} e {count} {count|altro|altri}"
L.CHAT_SYNC_ASKED = "Sincronizzazione richiesta. Le risposte arrivano nei prossimi secondi."
L.CHAT_SYNC_FAIL  = "La sincronizzazione non funziona: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "nessuna gilda o condivisione disattivata."
L.CHAT_FRIENDS_NOT_LOADED = "Il libro degli amici non è caricato."
L.CHAT_FRIENDS_STATE = "Amici: condivisione {share}, {online} su {total} in linea."
L.CHAT_FRIENDS_BOOK  = "Libro degli amici: {enemies} assassini ({listed} solo aggiunti a mano), {deeds} {deeds|misfatto|misfatti}."
L.CHAT_NO_FRIENDS    = "Ancora nessuna notizia da amici con DeathNote."
L.CHAT_HUNT_NOT_LOADED = "La lista nera non è caricata."
L.CHAT_HUNT_UNKNOWN = "Nome sconosciuto: {name}. Aggiungi anche il cognome, come appare nel gioco."
L.CHAT_HUNT_CAP     = "Impossibile aprire la caccia: al massimo {own} ordini tuoi e {targets} bersagli per lista."
L.CHAT_HUNT_NOWHERE = "Ora non si può aprire la caccia: nessuna gilda e la condivisione con gli amici è disattivata."
L.CHAT_HUNT_BOTH    = "Caccia aperta su {name}, per gilda e amici."
L.CHAT_HUNT_GUILD   = "Caccia aperta su {name}, per la gilda."
L.CHAT_HUNT_FRIENDS = "Caccia aperta su {name}, per i tuoi amici."
L.CHAT_CALLED_OFF   = "Caccia su {name} fermata."
L.CHAT_NO_OWN_CALL  = "Non hai nessun ordine tuo su {name}."
L.CHAT_LANG_CURRENT = "Lingua attuale: {lang}. Cambia: /dn lang <codice>"
L.CHAT_LANG_LIST    = "Codici: {codes}"
L.CHAT_LANG_BAD     = "Lingua sconosciuta: {code}"
L.CHAT_LANG_SET     = "Lingua: {lang}."
L.CHAT_LANG_RELOAD  = "Lingua: {lang}. Vale dopo /reload."
L.CHAT_THEME_CURRENT = "Copertina attuale: {theme}. Cambia: /dn theme <nome>"
L.CHAT_THEME_LIST = "Copertine: {themes}"
L.CHAT_THEME_BAD = "Copertina sconosciuta: {name}"
L.CHAT_THEME_SET = "Copertina: {theme}."
L.CHAT_THEME_RELOAD = "Copertina: {theme}. Vale dopo /reload."
L.THEME_NOTEBOOK = "Il libro nero"
L.THEME_HARBOR = "Il libro del corsaro"
L.THEME_TRADE = "L'officina"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Il libro è pronto. Chi ti uccide nel mondo aperto ci finisce dentro. Aprilo con /dn o con il pulsante della minimappa."
L.WELCOME_PLATES = "Le targhette dei nemici sono disattivate. Senza di esse l'allarme vede solo il tuo bersaglio."
L.WELCOME_SHARE = "La gilda e gli amici che hanno DeathNote lo leggono con te. Note e sospetti restano a te."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "NEL LIBRO:"
L.TIP_HUNT      = "LISTA NERA:"
L.TIP_GUILDBOOK = "LIBRO DELLA GILDA:"
L.TIP_PARDONED  = "grazia concessa"
L.TIP_RANK      = "posizione {rank}"
L.TIP_REVENGE   = "vendetta {times}"
L.TIP_LISTED_BY = "nel libro di {names}"
L.TIP_NOTE      = "Nota: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Clic: apri · Clic destro: chiudi"
L.BANNER_NEW          = "NUOVA VOCE"           -- [max 24]
L.BANNER_NEW_LINE     = "ora è nel libro"
L.BANNER_AGAIN        = "DI NUOVO"             -- [max 24]
L.BANNER_AGAIN_LINE   = "ti ha ucciso ancora, già {count} volte"
L.BANNER_SUSPECT      = "SOSPETTO"             -- [max 24]
L.BANNER_SUSPECT_LINE = "è sotto sospetto, da chiarire nel libro"
L.BANNER_UNCLEAR      = "ASSASSINO INCERTO"    -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|candidato|candidati}"
L.BANNER_UNCLEAR_LINE = "Clic: scegli l'assassino in Irrisolti"
L.BANNER_REVENGE      = "VENDETTA"             -- [max 24]
L.BANNER_REVENGE_LINE = "Conto saldato ({count}×)"
L.BANNER_GUILD        = "GILDA"                -- [max 24]
L.BANNER_FRIENDS      = "AMICI"                -- [max 24]
L.BANNER_KILLED_BY    = "ha perso la vita per mano di {name}"
L.BANNER_HUNT         = "LISTA NERA"           -- [max 24]
L.BANNER_BAGGED       = "vittima di {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "La condivisione è disattivata (Regole della casa, foglio Gilda)."
L.SYNC_FRIENDS_OFF = "La condivisione con gli amici è disattivata."
L.SYNC_NOBODY      = "Nessuna gilda e nessun amico con cui condividere."
L.SYNC_SHORT_NOBODY = "Niente condiviso"          -- [max 18]
L.SYNC_PREFIX      = "Il gioco non permette di ricevere. Rientrare aiuta."
L.SYNC_SHORT_PREFIX = "Ricezione ferma"           -- [max 18]
L.SYNC_BLOCKED     = "Il reame blocca l'invio. Passalo con Salva copia."
L.SYNC_SHORT_BLOCKED = "Il reame blocca invio"    -- [max 22]
L.SYNC_FAILING     = "L'invio non riesce ora, nuovo tentativo in corso."
L.SYNC_SHORT_FAILING = "Invio bloccato"           -- [max 18]
L.SYNC_HOLD        = "L'invio aspetta {wait}."
L.SYNC_HOLD_INSTANCE = "che tu esca dall'istanza"
L.SYNC_HOLD_COMBAT   = "che tu esca dal combattimento"
L.SYNC_HOLD_LOCKDOWN = "che la chat sia di nuovo libera"
L.SYNC_HOLD_AGAIN    = "che torni a funzionare"
L.SYNC_HOLD_SHORT_INSTANCE = "Attesa: istanza"   -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "In combattimento" -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Attesa: chat"      -- [max 18]
L.SYNC_QUIET       = "Inviato, ma ancora nessuna notizia da compagni con DeathNote."
L.SYNC_READY       = "Pronto. Ancora nessuna notizia da compagni con DeathNote."
L.SYNC_RUNNING     = "Attivo: {count} {count|compagno|compagni} di gilda con DeathNote."
L.SYNC_RUNNING_ALL = "Attivo: {count} con DeathNote tra gilda e amici."
L.FRIENDS_OFF      = "La condivisione con gli amici è disattivata (Regole della casa, foglio Gilda)."
L.FRIENDS_BLOCKED  = "Il reame blocca i sussurri. Gli amici non ricevono nulla."
L.FRIENDS_SHORT_BLOCKED = "Sussurri bloccati"     -- [max 22]
L.FRIENDS_FAILING  = "I sussurri non riescono ora, nuovo tentativo in corso."
L.FRIENDS_SHORT_FAILING = "Sussurri fermi"        -- [max 18]
L.FRIENDS_NONE_LISTED = "Nessuno nella lista amici."
L.FRIENDS_NONE_ONLINE = "Al momento nessun amico in linea."
L.FRIENDS_SHORT_NONE_ONLINE = "Nessuno in linea"  -- [max 18]
L.FRIENDS_QUIET    = "Richiesto, ma ancora nessuna notizia da amici con DeathNote."
L.FRIENDS_READY    = "Pronto. Ancora nessuna notizia da amici con DeathNote."
L.FRIENDS_HOLD     = "L'invio agli amici aspetta che torni a funzionare."
L.FRIENDS_RUNNING  = "Attivo: {count} {count|amico|amici} con DeathNote."
L.NOTE_FROM_GUILD  = "Preso dal libro della gilda (ha ucciso compagni di gilda {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Database non caricato."
L.IMPORT_NO_TEXT    = "Nessun testo."
L.IMPORT_NO_HEADER  = "Manca la prima riga (inizia con {header}). Copia tutto il testo."
L.IMPORT_NOT_EXPORT = "Non è un'esportazione di DeathNote (manca l'intestazione o versione sbagliata)."
L.IMPORT_TOO_LONG   = "Troppe righe (al massimo {count})."
L.IMPORT_BAD_KEY    = "Riga {line}: chiave non valida."
L.IMPORT_BAD_TIME   = "Riga {line}: ora non valida."
L.IMPORT_BROKEN     = "La riga {line} è incompleta o rovinata (testo tagliato?). Non è stato importato nulla."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "sì"
L.WORD_NO  = "no"
L.PROBE_HEAD = "Sonda: {apis}/{apisAll} interfacce presenti, {events}/{eventsAll} eventi registrabili."
L.PROBE_MISSING = "Mancano: {list}"
L.PROBE_NOT_REGISTERABLE = "Non registrabili: {list}"
L.PROBE_SOURCES = "Recap ora: {recap} · Contatore: {meter} · Registro di combattimento: {clog}"
L.PROBE_READABLE = "leggibile"
L.PROBE_DEAD = "morto"
L.PROBE_PLATES = "Targhette dei nemici: {plates} · Mondo aperto: {open}"
L.PROBE_PLATES_OFF = "OFF (solo bersaglio e mouse rilevano i giocatori)"
L.PROBE_TARGET = "Bersaglio: nome={name} GUID={guid} classe={class} ostile={enemy} mi bersaglia={me}"
L.PROBE_GUILD = "Gilda: prefisso {prefix} · invio {send} · ultimo valore restituito {result} · inviati {sent}, ricevuti {received}, scartati {dropped}"
L.PROBE_REGISTERED = "registrato"
L.PROBE_NOT_REGISTERED = "NON registrato ({result})"
L.PROBE_POSSIBLE = "possibile"
L.PROBE_ABSENT = "manca"
L.PROBE_WAITS = " · aspetta: {why}"
L.PROBE_LISTED = "Voci a mano (M): inviate {sent}, ricevute {received}, scartate {dropped} · depennate (X): inviate {usent}, ricevute {ureceived}, scartate {udropped}"
L.PROBE_GUILDBOOK = "Libro della gilda: {text}"
L.PROBE_SAVED = "Salvato in DeathNoteDB.probe (nel file dopo /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Posizione"  -- [max 14]
L.SORT_RECENT = "Recenti"  -- [max 14]
L.SORT_NAME = "Nome"  -- [max 14]
L.SORT_SEEN = "Avvistati"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Chi ti uccide nel mondo aperto finisce qui. Da solo."
L.EMPTY_OPEN_HEAD = "Niente di irrisolto."
L.EMPTY_JOURNAL_HEAD = "Ancora nessuna morte."
L.EMPTY_JOURNAL_SUB = "Rispetto. O bugia."
L.EMPTY_NOGUILD_HEAD = "Nessuna gilda."
L.EMPTY_NOGUILD_SUB = "Si muore bene anche da soli."
L.EMPTY_GUILDOFF_HEAD = "Il libro della gilda è chiuso."
L.EMPTY_GUILDOFF_SUB = "La condivisione è disattivata. Le Regole della casa sanno dove."
L.EMPTY_GUILDNIL_HEAD = "Ancora nessuna notizia dalla gilda."
L.EMPTY_GUILDNIL_SUB = "Il tuo libro parte appena un compagno di gilda ha DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Il libro della gilda è ancora vuoto."
L.EMPTY_GUILDQUIET_SUB = "Finora i tuoi compagni di gilda sono stati in pace."
L.EMPTY_FRIENDSOFF_HEAD = "Il libro degli amici è chiuso."
L.EMPTY_FRIENDSOFF_SUB = "La condivisione con gli amici è disattivata. Le Regole della casa sanno dove."
L.EMPTY_FRIENDSNIL_HEAD = "Ancora nessuna notizia da amici con DeathNote."
L.EMPTY_FRIENDSNIL_SUB = "Il tuo libro parte appena un amico ha DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Ancora niente dai tuoi amici."
L.EMPTY_FRIENDSQUIET_SUB = "Finora i tuoi amici sono stati in pace."
L.EMPTY_NOBODY_HEAD = "Niente gilda, niente amici."
L.EMPTY_NOBODY_SUB = "Si muore bene anche da soli."
L.EMPTY_NOBODY_HINT = "Quando compagni di gilda o amici della tua lista amici avranno DeathNote, qui vedrai cosa succede loro."
L.EMPTY_SHAREDNIL_HEAD = "Ancora nessuna notizia da chi ha DeathNote."
L.EMPTY_SHAREDNIL_SUB = "Il tuo libro parte appena compagni di gilda o amici hanno DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Qui non c'è ancora niente."
L.EMPTY_SHAREDQUIET_SUB = "Finora gilda e amici sono stati in pace."
L.EMPTY_HUNT_HEAD = "La lista nera è vuota."
L.EMPTY_HUNT_SUB = "Sul manifesto: Apri la caccia."
L.EMPTY_HUNT_HINT = "Oppure in chat: /dn hunt Nome Cognome. Lo vedono tutti nella tua gilda e i tuoi amici."
L.EMPTY_SEARCH_HEAD = "Nessun risultato."
L.EMPTY_SEARCH_SUB = "Invio scrive il nome nel libro."
L.EMPTY_SEARCHRO_HEAD = "Nessun risultato."
L.EMPTY_SEARCHRO_SUB = "A volte aiuta scriverlo in un altro modo."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "IL LIBRO"  -- [max 12]
L.MANUAL_BOOK = "Chi ti uccide nel mondo aperto viene scritto da solo. Un clic sul messaggio dopo la tua morte apre la pagina dell'assassino."
L.MANUAL_WANTED_HEAD = "RICERCATI"  -- [max 12]
L.MANUAL_WANTED = "I tuoi assassini, il peggiore per primo. Un clic mostra il manifesto con misfatti e nota. I graziati stanno in fondo, depennati."
L.MANUAL_UNSOLVED_HEAD = "IRRISOLTI"  -- [max 13]
L.MANUAL_UNSOLVED = "Se non è chiaro chi sia stato, il caso aspetta qui. Un clic su un nome stabilisce l'assassino."
L.MANUAL_ALERT_HEAD = "ALLARME"  -- [max 12]
L.MANUAL_ALERT = "Quando un assassino compare come targhetta, bersaglio o sotto il mouse, il libro si fa sentire. Un clic lo prende come bersaglio, in combattimento solo dopo."
L.MANUAL_ADD_HEAD = "AGGIUNGERE"  -- [max 12]
L.MANUAL_ADD = "Scrivi un nome nel campo di ricerca, Invio. Clic destro su una riga: segna la vendetta, grazia, depenna."
L.MANUAL_GUILD_HEAD = "GILDA"  -- [max 12]
L.MANUAL_GUILD = "I compagni di gilda e gli amici con DeathNote vedono le tue morti accertate e le voci a mano. Manifesto o /dn hunt Nome: apri la caccia. Clic sulla taglia: metti la tua, una promessa che si salda tra voi."
L.MANUAL_SHARE_HEAD = "PASSARLO"  -- [max 12]
L.MANUAL_SHARE = "Regole della casa, Salva copia: un testo da copiare, per chi non ha DeathNote."
L.MANUAL_QUIET_HEAD = "SILENZIO"  -- [max 12]
L.MANUAL_QUIET = "In spedizioni e campi di battaglia l'allarme tace. Altrimenti: clic centrale sul pulsante della minimappa o /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Depennare davvero {name} dal libro?\nTutti i misfatti e la nota andranno persi."
L.CONFIRM_DELETE_OK = "Depenna"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Svuotare il libro della gilda su questo computer?\nVa via anche la sua lista nera, i tuoi ordini restano.\nIl tuo libro resta com'è."
L.CONFIRM_GUILD_CLEAR_OK = "Svuota"  -- [max 14]
L.CONFIRM_CANCEL = "Annulla"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ORO"  -- [max 14]
L.BOUNTY_SILVER = "{count} ARGENTO"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Conferma"  -- [max 19]
L.ACT_DISMISS = "Scarta"  -- [max 19]
L.ACT_HUNT_AGAIN = "Revoca la grazia"  -- [max 19]
L.ACT_REVENGE = "Segna vendetta"  -- [max 19]
L.ACT_PARDON = "Grazia"  -- [max 19]
L.ACT_STRIKE = "Depenna"  -- [max 19]
L.ACT_OPEN_OWN = "Apri nel libro"  -- [max 19]
L.ACT_ADOPT = "Nel mio libro"  -- [max 19]
L.ACT_CALLOFF = "Ferma la caccia"  -- [max 19]
L.ACT_RELEASE = "Apri la caccia"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "avvistamento: {time}"
L.ROW_NOT_SEEN = "nessun avvistamento"
L.ROW_PARDONED = "grazia concessa"
L.ROW_SUSPECT = "Sospetto"
L.MARK_REVENGE = "VENDETTA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Assassino incerto"
L.MARK_CANDIDATES = "{count} {count|CANDIDATO|CANDIDATI}"  -- [max 16]
L.MARK_SUSPECT = "SOSPETTO"  -- [max 16]
L.ROW_NO_PLAYER = "Nessun giocatore"
L.ROW_UNCLEAR = "Causa incerta"
L.MARK_NOT_COUNTED = "NON CONTA"  -- [max 16]
L.ROW_LISTED_BY = "aggiunto da {names}"
L.ROW_GKILLED = "ha ucciso {kills}×"
L.ROW_VICTIMS = "{count} {count|vittima|vittime}"
L.ROW_LAST = "ultima: {text}"
L.MARK_IN_BOOK = "NEL LIBRO"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|assassino|assassini}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|morte|morti}"  -- [max 12]
L.MEMBER_LISTED = "{count} a mano"  -- [max 14]
L.MEMBER_ME = "ciò che gli altri vedono di te"
L.MEMBER_NOTHING = "ancora niente condiviso"
L.MEMBER_LAST_DIED = "ultima morte {time}"
L.MARK_YOU = "tu"  -- [max 16]
L.MARK_FRIEND = "AMICO"  -- [max 16]
L.MARK_BOTH = "GILDA, AMICO"  -- [max 20]
L.MARK_TAKEN_DOWN = "ABBATTUTO {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "VIVO O MORTO"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "MISFATTI"  -- [max 14]
L.POSTER_NOTE = "NOTA"  -- [max 8]
L.POSTER_BOUNTY = "TAGLIA"  -- [max 12]
L.ROLE_ASSIST = "complice"  -- [max 14]
L.ROLE_SUSPECT = "sospetto"  -- [max 14]
L.POSTER_LEVEL = "Livello {level}"
L.POSTER_GUILD = "Gilda: {guild}"
L.POSTER_LAST_SEEN = "Ultimo avvistamento: {time}"
L.POSTER_NOT_SEEN = "Nessun avvistamento"
L.POSTER_ONLY_SUSPECT = "Solo un sospetto, nessun misfatto provato."
L.POSTER_NO_DEEDS = "Nessun misfatto annotato."
L.TIP_LISTED_AT = "Aggiunto il {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Causa della morte: {spell}"
L.TIP_VICTIM = "Vittima: {name}"
L.TIP_VICTIM_LEVEL = "Vittima: {name} (livello {level})"
L.TIP_KILLER_LEVEL = "Livello dell'assassino: {level}"
L.TIP_ASSISTS = "Complici: {names}"
L.TIP_ROLE_ASSIST = "Complice, non ha dato il colpo di grazia."
L.TIP_ROLE_SUSPECT = "Solo un sospetto, niente di provato."
L.MORE_LINE = "… e {count} {count|altro|altri}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "LIBRO DELLA GILDA"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Nel libro di: {names}"
L.POSTER_SEEN = "Avvistamento: {time}"
L.POSTER_SEEN_BY = "Avvistamento: {time}, da {name}"
L.TIP_IN_BOOK_OF = "Nel libro di"
L.POSTER_REMARK = "ANNOTAZIONE"  -- [max 12]
L.POSTER_BY_HAND = "AGGIUNTO A MANO"  -- [max 22]
L.POSTER_VICTIMS = "VITTIME"  -- [max 12]
L.POSTER_LISTED = "AGGIUNTO DA"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Aggiunto a mano."
L.POSTER_NO_DEEDS_SENT = "Nessun misfatto trasmesso."
L.POSTER_NONE_KNOWN = "nessuna conosciuta"
L.POSTER_NO_NAMES = "nessun nome trasmesso"
L.TIP_VICTIMS = "Vittime"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Ordine del {time}"
L.HUNT_REASON = "Motivo: {reason}"
L.POSTER_HUNTLIST = "LISTA NERA"  -- [max 24]
L.POSTER_RELEASED_N = "caccia aperta {times}"
L.POSTER_RELEASED_BY = "Ordine di {names}"
L.POSTER_TAKEN_DOWN = "ABBATTIMENTI"  -- [max 12]
L.POSTER_NOT_YET = "NON ANCORA"  -- [max 18]
L.POSTER_CALLS = "ORDINI"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Più nessuno."
L.POSTER_LAST = "ULTIMO"  -- [max 13]
L.POSTER_TAKEN_BY = "vittima di {name}, {time}"
L.POSTER_TAKEN_NOBODY = "ancora a piede libero"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Decesso"  -- [max 20]
L.CASE_ASSISTS = "COMPLICI"  -- [max 24]
L.CASE_PICK = "SCEGLI L'ASSASSINO"  -- [max 24]
L.CASE_NOT_COUNTED = "Non conta (istanza, campo di battaglia o duello)"
L.CASE_KILLER = "ASSASSINO"  -- [max 24]
L.CASE_KILLER_SUSPECT = "ASSASSINO (SOSPETTO)"  -- [max 24]
L.CASE_CLICK_NAME = "Clicca sul nome per aprire il suo manifesto."
L.CASE_GONE = "Non è più nel libro."
L.CASE_KILLER_UNCLEAR = "ASSASSINO INCERTO"  -- [max 24]
L.CASE_SEVERAL = "Potrebbero essere stati in diversi. Quale nome va nel libro?"
L.CASE_NOBODY = "Non può essere stato nessuno."
L.CASE_HOW = "COSA È SUCCESSO"  -- [max 24]
L.CASE_PVE = "Un mostro o il mondo stesso. Non è un caso per il libro."
L.CASE_UNCLEAR = "Incerto"
L.CASE_DARK = "La scientifica brancola nel buio."
L.TIP_MORE_CANDIDATES = "Altri candidati"
L.CASE_SOURCE_SUSPECT = "Sospetto: ti aveva come bersaglio poco prima della tua morte."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Riga nel tooltip degli assassini"  -- [max 44]
L.OPT_MINIMAP = "Mostra il pulsante della minimappa"  -- [max 44]
L.OPT_ALERT = "Allarme quando compare un assassino"  -- [max 44]
L.OPT_FLASH = "Bordo dello schermo lampeggia in rosso"  -- [max 44]
L.OPT_SUSPECTS = "Segnala anche i sospetti"  -- [max 44]
L.OPT_DEATHMSG = "Messaggio dopo una morte PvP"  -- [max 44]
L.OPT_G_SHARE = "Condividi le mie morti"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Condividi le voci aggiunte a mano"  -- [max 44]
L.OPT_G_RECEIVE = "Ricevi il libro della gilda"  -- [max 44]
L.OPT_G_ALERT = "Avvisa per gli assassini del libro di gilda"  -- [max 44]
L.OPT_G_ALERTLISTED = "Avvisa anche per le voci a mano"  -- [max 44]
L.OPT_G_ANNOUNCE = "Segnala quando muore un compagno di gilda"  -- [max 44]
L.OPT_G_SIGHTINGS = "Condividi gli avvistamenti"  -- [max 44]
L.OPT_F_SHARE = "Condividi con la gilda"  -- [max 44]
L.OPT_F_FRIENDS = "Condividi con gli amici"  -- [max 44]
L.OPT_F_ALERT = "Avvisa per gli assassini di gilda e amici"  -- [max 44]
L.OPT_F_ALERTHUNT = "Avvisa per i bersagli della lista nera"  -- [max 44]
L.OPT_F_ANNOUNCE = "Segnala quando muoiono compagni o amici"  -- [max 44]
L.OPT_F_SIGHTINGS = "Condividi avvistamenti con gilda e amici"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Gilda"  -- [max 14]
L.SET_BOOK_SIZE = "Dimensione del libro"  -- [max 34]
L.SET_LANGUAGE = "Lingua"  -- [max 16]
L.SET_LANG_AUTO = "Automatico"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Vale dopo il ricaricamento."  -- [max 28]
L.SET_LANG_RELOAD = "Ricarica ora"  -- [max 22]
L.SET_SEC_SHARE = "PASSARLO"  -- [max 24]
L.IO_EXPORT = "Salva copia"  -- [max 17]
L.IO_IMPORT = "Importa libro"  -- [max 17]
L.SET_HINT_BOOK = "Salva copia ti dà il libro come testo: da conservare o da passare a chi è fuori dalla gilda. Importa unisce e non sovrascrive nulla."
L.SET_SEC_SOUND = "SUONO"  -- [max 24]
L.SET_SOUND = "Suono"  -- [max 22]
L.SET_VOLUME = "Volume"  -- [max 22]
L.SET_CHANNEL = "Canale"  -- [max 12]
L.SET_SEC_THRESHOLD = "SOGLIA"  -- [max 24]
L.SET_COOLDOWN = "Tempo di recupero per assassino"  -- [max 34]
L.SET_MINKILLS = "Allarme dopo tante sue uccisioni"  -- [max 34]
L.SET_ALERT_SIZE = "Dimensione dell'allarme"  -- [max 34]
L.SET_TEST_ALERT = "Allarme di prova"  -- [max 17]
L.SET_G_MINKILLS = "Avviso di gilda dopo tante morti"  -- [max 34]
L.SET_F_MINKILLS = "Avviso dopo tante morti"  -- [max 34]
L.SET_SEC_STATUS = "STATO"  -- [max 24]
L.SET_SEC_SHARING = "CONDIVISIONE"
L.SET_SEC_WARN = "ALLARME"
L.SET_MORE = "Altro"
L.SET_GUILD_CLEAR = "Svuota libro di gilda"  -- [max 26]
L.SET_HINT_GUILD = "Riceve qualcosa solo la tua gilda. Ciò che arriva da lì resta separato dal tuo libro finché non lo prendi tu."
L.SET_HINT_FRIENDS = "Ricevono qualcosa solo gilda e amici con DeathNote."
L.BTN_BACK = "Indietro"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sincronizza"  -- [max 14]
L.SYNC_AGAIN_IN = "attendi {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Amici"
L.TIP_GUILD_NAME = "Gilda {guild}"
L.TIP_MATES_WITH = "Compagni di gilda con DeathNote:"
L.TIP_NO_MATE = "Ancora nessuna notizia da compagni con DeathNote."
L.TIP_FRIENDS_WITH = "Amici con DeathNote:"
L.TIP_SHARED = "Si condivide: le tue morti accertate, le voci a mano e i tuoi ordini di caccia."
L.TIP_NOT_SHARED = "Non si condivide: note, sospetti, graziati, voci importate."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Importa"  -- [max 17]
L.IO_DONE = "Importato: {new} nuovi, {merged} uniti."
L.IO_FAILED = "Non ha funzionato."
L.IO_SMALL = "Solo il minimo"  -- [max 17]
L.IO_ALL = "Mostra tutto"  -- [max 17]
L.IO_MSG_FULL = "Libro intero con i misfatti ({size})."
L.IO_MSG_SHORT = "Solo nomi e conteggi ({size}). Con i misfatti: {full}."
L.IO_MSG_BIG = "Libro grande ({size}): selezionare e copiare richiede un attimo."
L.IO_HELP_EXPORT = "Il testo è selezionato: Ctrl+C lo copia. Conservalo o passalo agli amici."
L.IO_HELP_IMPORT = "Incolla un testo salvato con Ctrl+V, poi Importa. Non viene sovrascritto nulla."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Il motivo lo vedono tutti nella tua gilda e i tuoi amici con DeathNote."
L.REL_HINT_GUILD = "Il motivo lo vedono tutti nella tua gilda con DeathNote."
L.REL_HINT_FRIENDS = "Il motivo lo vedono i tuoi amici con DeathNote."
L.REL_HEAD = "Apri la caccia"  -- [max 24]
L.REL_FOR = "PER"  -- [max 6]
L.REL_REASON = "MOTIVO"  -- [max 8]
L.REL_HINT2 = "La tua nota resta a te. Solo tu puoi ritirare il tuo ordine."
L.REL_GO = "Dai l'ordine"  -- [max 17]
L.REL_NONE = "Nessuna gilda e la condivisione con gli amici è disattivata."
L.REL_CAP = "Al massimo {own} ordini tuoi e {max} bersagli per lista."
L.REL_FAILED = "Ora non si può aprire la caccia."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Nessun suono: l'allarme si limita a comparire."
L.SET_HINT_BUILTIN = "Il volume di questo suono segue il canale nelle opzioni di gioco."
L.SET_HINT_LEVELS = "Cinque livelli, dal più basso al più alto. In più vale il cursore del canale nelle opzioni di gioco."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Gilda e amici"  -- [max 18]
L.TIP_HELP_BUTTON = "Come funziona il libro"
L.VIEW_HUNT = "Lista nera"  -- [max 13]
L.VIEW_BY_KILLER = "Per assassino"  -- [max 13]
L.VIEW_BY_MATE = "Per compagno"  -- [max 13]
L.SRC_ALL = "Tutti"  -- [max 12]
L.SRC_GUILD = "Gilda"  -- [max 12]
L.SRC_FRIENDS = "Amici"  -- [max 12]
L.SORT_HIDE_PARDONED = "Nascondi graziati"  -- [max 24]
L.SORT_SHOW_PARDONED = "Mostra graziati"  -- [max 24]
L.SEARCH_ADD = "Cerca o aggiungi …"  -- [max 26]
L.SEARCH_SHORT = "Cerca …"  -- [max 10]
L.SEARCH_KILLER = "Cerca assassino"  -- [max 15]
L.SEARCH_JOURNAL = "Assassino o luogo …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Comprimi tutto"
L.TIP_EXPAND_ALL = "Espandi tutto"
L.STATUS_NO_PLATES = "Targhette dei nemici disattivate: l'allarme vede solo bersaglio e mouse."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|ricercato|ricercati}"
L.MM_UNSOLVED = "{count} {count|irrisolto|irrisolti}"
L.MM_ALERT_OFF = "Allarme disattivato (clic centrale)"
L.MM_CLICK = "Clic: libro · Clic destro: Regole della casa"
L.MM_MIDDLE = "Clic centrale: allarme on/off"
L.MM_DRAG = "Trascina: sposta lungo il bordo della minimappa"
L.MM_CHAT_ALERT_ON = "Allarme attivo."
L.MM_CHAT_ALERT_OFF = "Allarme disattivato."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "NEMICO DI GILDA N. 1"  -- [max 25]
L.STAMP_HUNT = "CACCIA APERTA"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} ha finto di essere il tuo amico {friend}: respinto."
L.FRIENDS_SHORT_IMPOSTOR = "Sconosciuto respinto"  -- [max 22]
L.ALERT_LEVEL = "Livello {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "ultimo livello {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Livello ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · nella lista nera ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nuovo bersaglio|nuovi bersagli}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nuove voci nella lista nera"
L.OPT_F_ANNOUNCEHUNT = "Segnala lista nera: nuovi e abbattuti"  -- [max 44]
L.SET_HUNT_EXPIRE = "Gli ordini scadono dopo"  -- [max 30]
L.SET_EXPIRE_NEVER = "Mai"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|giorno|giorni}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Svuota libro amici"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Svuotare il libro degli amici su questo computer?\nVa via anche la sua lista nera, i tuoi ordini restano."
L.CONFIRM_CALLOFF_ALL = "Ritirare tutti i tuoi ordini dalla lista nera?\nGilda e amici lo sapranno un po' alla volta."
L.CONFIRM_CALLOFF_ALL_OK = "Ritira tutti"  -- [max 14]
L.ACT_CALLOFF_ALL = "Ritira i miei ordini"  -- [max 24]
L.ACT_HUNT_HIDE = "Nascondi per me"  -- [max 19]
L.ACT_HUNT_SHOW = "Mostra di nuovo"  -- [max 19]
L.HUNT_ROW_HIDDEN = "non visibile per te"
L.HUNT_ROW_CALLS = "{count} {count|ordine|ordini}: {names}"
L.POSTER_ON_HUNTLIST = "Nella lista nera ({names})"
L.REL_SELF = "Non puoi aprire la caccia contro di te."
L.REL_MATE = "È dei tuoi (gilda o amici con DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Chi è il tuo amico {friend}: {a} o {b}? Scegli tu."
L.FRIENDS_SHORT_CONFLICT = "Amico incerto"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Due giocatori dicono di essere il tuo amico {friend}: {a} e {b}. Finché non scegli, il libro non accetta niente da nessuno dei due. Gilda e amici, vista Per compagno: clic destro sul nome."
L.MEMBER_CONFLICT = "Clic destro: è il tuo amico?"  -- [max 40]
L.ACT_TIE_MINE = "Mio amico: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Scollega nome"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Scollegare {name} dalla tua lista amici?\nCiò che questo nome ha portato nel libro degli amici viene cancellato; il prossimo messaggio con questo nome lo ricollega."
L.CHAT_FRIENDS_TIES = "Nomi completi collegati (* = primo contatto, non ancora confermato): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Nome [Cognome]> <oro>  metti una tua taglia (senza oro: ritirala)"
L.CHAT_WHO_BOUNTY = "Su chi? /dn bounty <Nome> <oro>"
L.CHAT_BOUNTY_SET = "{name}: hai messo una taglia di {gold} oro. Gilda e amici con DeathNote la vedono."
L.CHAT_BOUNTY_OFF = "{name}: la tua taglia è ritirata."
L.CHAT_BOUNTY_NONE = "Non hai nessuna taglia tua su {name}."
L.CHAT_BOUNTY_BAD = "Taglia: un numero intero di monete d'oro, da 1 a 99999 (0 la ritira)."
L.CHAT_BOUNTY_CAP = "Nessuna taglia: al massimo {count} tue."
L.CHAT_BOUNTY_OURS = "Nessuna taglia su di te o sui tuoi (gilda o amici con DeathNote)."
L.ACT_BOUNTY = "Metti una taglia"  -- [max 24]
L.ACT_UNDO = "Annulla"  -- [max 19]
L.ACT_REVENGE_TAKE = "Togli una vendetta"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, messa da te"
L.POSTER_BOUNTY_BY = "{gold}, messa da {name}"
L.POSTER_BOUNTY_MANY = "Taglia {gold}: {names}"
L.POSTER_AVENGED = "Vendicato da {names}"
L.ROW_AVENGED = "vendicato {times}"
L.BOUNTY_TIP_HEAD = "La tua taglia, in oro"
L.BOUNTY_TIP_RULES = "Un numero intero, da 1 a 99999. Vuoto o 0: torna al valore del libro. Invio conferma, Esc annulla."
L.BOUNTY_TIP_PROMISE = "Gilda e amici con DeathNote la vedono. Solo una promessa: si salda tra voi."
L.BOUNTY_TIP_CLICK = "Clic: metti la tua taglia"
L.CHAT_AVENGED = "{name} ha abbattuto {killer} per te."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: hai messo una taglia di {gold} oro."
L.CHAT_BOUNTY_UNKNOWN = "{name} non è in nessuno dei tuoi libri. Una taglia va solo su un nome di un libro, come lo mostra il gioco: nome e cognome."
L.CHAT_BOUNTY_LIST = "Le tue taglie ({count} su {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Non hai messo nessuna taglia."
-- <<< BOOK
-- >>> REPUTE (1.3.0) -----------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Rango {tier} · Via: {path}"  -- [max 32]
L.PATH_R = "Infamia"  -- [max 16]
L.PATH_E = "Onore"  -- [max 16]
L.PATH_J = "Caccia"  -- [max 16]
L.PATH_S = "Protezione"  -- [max 16]
L.PATH_NONE = "in bianco"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) -------------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "SERBA RANCORE?"  -- [max 30]
L.ALERT_LINE_VICTIM = "punteggio {score} · ucciso da te, l'ultima volta {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · punteggio {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · punteggio {score}, pari"
L.ALERT_LINE_STANDING_AHEAD = "{text} · punteggio {score}, con interessi"
-- <<< ALARM
-- >>> START (1.3.0) -------------------------------------------------------------------------------------------------
L.SET_THEME = "Copertina"  -- [max 16]
L.START_HINT = "Puoi cambiarli entrambi più tardi nelle Regole della casa."  -- [max 60]
L.START_GO = "Via"  -- [max 16]
L.START_CLOSE_TIP = "Lascia così"  -- [max 32]
L.CHAT_THEME_NEWS = "Novità: il libro ha altre copertine. Regole della casa, foglio Libro, oppure /dn theme."
L.HELP_START = "/dn start  riapri la finestra iniziale (lingua e copertina)"
-- <<< START
-- >>> RECORD (1.3.0) -----------------------------------------------------------------------------------------------
L.TAB_RECORD = "Fedina penale"  -- [max 16]
L.STAMP_QUITT = "PARI"  -- [max 16]
L.STAMP_OVERPAID = "CON INTERESSI"  -- [max 16]
L.STAMP_NR1_DOWN = "NEMICO N. 1 ABBATTUTO"  -- [max 24]
L.STATE_OPEN = "aperto"  -- [max 16]
L.STATE_EVEN = "pari"  -- [max 16]
L.STATE_AHEAD = "con interessi"  -- [max 16]
L.STATE_VICTIM = "non è nel libro"  -- [max 24]
L.STAND_LINE = "Punteggio {score}"
L.STAND_TIP = "tu {mine}, lui {his}"
L.TIP_IN_RECORD = "IN FEDINA:"
L.TIP_RECORD_LINE = "ucciso da te {times}, l'ultima volta {time}"
L.RECORD_HEAD = "Il tuo fascicolo"  -- [max 20]
L.RECORD_LOG_HEAD = "Ultime uccisioni"  -- [max 20]
L.RECORD_NEXT = "ancora {points} per {rank}"
L.RECORD_TOP = "Rango massimo raggiunto."
L.RECORD_BAR_TIP = "{total} su {goal} punti"
L.RECORD_NEEDLE_LOW = "spietato"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "onorevole"  -- [max 12]
L.RECORD_NEEDLE_TIP = "L'ago: onore e protezione contro infamia. La caccia non lo sposta."
L.RECORD_KILLS = "Uccisioni: {kills} · Vittime: {victims}"
L.RECORD_BEST = "Record: {list}"
L.RECORD_BEST_GAP = "+{count} {count|livello|livelli}"
L.RECORD_BEST_STREAK = "serie di {count}"
L.RECORD_BEST_QUICK = "vendetta più rapida {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} h"
L.RECORD_AWARDS = "ONORIFICENZE"  -- [max 14]
L.RECORD_AWARD_AT = "conferita il {time}"
L.RECORD_AWARD_OPEN = "non ancora conferita"
L.RECORD_MORE = "Mostra altro"  -- [max 19]
L.RECORD_BACK = "Al fascicolo"  -- [max 19]
L.RECORD_CLEAR = "Ripulisci la fedina"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Ripulire la fedina penale?\nSpariscono tutte le vittime e l'elenco delle ultime uccisioni. Rango, punti e onorificenze restano."
L.CONFIRM_RECORD_CLEAR_OK = "Ripulisci"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Depennare {name} dalla fedina penale?\nI punti guadagnati restano."
L.ACT_VICTIM_STRIKE = "Depenna dalla fedina"  -- [max 26]
L.VICTIM_KILLED = "ucciso da te {times}"
L.VICTIM_POINTS = "Punti guadagnati: {points}"
L.VICTIM_SCENE = "Scena del crimine: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "TUE UCCISIONI"  -- [max 14]
L.KILL_TAG_REVENGE = "vendetta"  -- [max 14]
L.KILL_TAG_KICK = "accanimento"  -- [max 14]
L.KILL_TAG_GROUP = "gruppo"  -- [max 14]
L.BAND_GRAU = "grigio"  -- [max 12]
L.BAND_GRUEN = "verde"  -- [max 12]
L.BAND_GELB = "giallo"  -- [max 12]
L.BAND_ORANGE = "arancione"  -- [max 12]
L.BAND_ROT = "rosso"  -- [max 12]
L.BAND_SCHAEDEL = "teschio"  -- [max 12]
L.BAND_UNBEKANNT = "sconosciuto"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "nessun punto"
L.RECORD_BANDS = "Per colore del livello"
L.TIP_PATH_R = "Infamia: uccisioni di grigi e verdi."
L.TIP_PATH_E = "Onore: uccisioni di giocatori del tuo livello, vendetta."
L.TIP_PATH_J = "Caccia: uccisioni di livelli più alti, bersagli della lista nera, taglie."
L.TIP_PATH_S = "Protezione: uccisioni di giocatori che hanno ucciso compagni di gilda o amici."
L.SORT_STATE = "Punteggio"  -- [max 14]
L.SORT_COUNT = "Uccisioni"  -- [max 14]
L.SORT_POINTS = "Punti"  -- [max 14]
L.CHAT_OWN_KILL = "Fedina: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Nuova via: {path}. Rango: {rank}."
L.BANNER_RANK = "NUOVO RANGO"  -- [max 24]
L.BANNER_AWARD = "ONORIFICENZA"  -- [max 24]
L.OPT_LEDGER = "Tenere la fedina penale"  -- [max 44]
L.OPT_LEDGER_CHAT = "Segnala le mie uccisioni in chat"  -- [max 44]
L.OPT_VICTIMS = "Avvisa quando compare una mia vittima"  -- [max 44]
L.SET_SETTLED = "Allarme a conto saldato"  -- [max 34]
L.SET_SETTLED_ALWAYS = "normale"  -- [max 10]
L.SET_SETTLED_QUIET = "silenzioso"  -- [max 10]
L.SET_SETTLED_OFF = "mai"  -- [max 10]
L.MANUAL_RECORD_HEAD = "FEDINA PENALE"  -- [max 14]
L.MANUAL_RECORD = "I tuoi colpi di grazia sui giocatori. Il manifesto e la lista mostrano il punteggio «tu : lui»: aperto, pari o con interessi. La posizione 1 è sempre aperta. Le uccisioni danno punti per il tuo rango."
L.POSTER_LAST_SEEN_IN = "Ultimo avvistamento: {zone}, {time}"
L.SHEET_RECORD = "Fedina"  -- [max 14]
-- <<< RECORD
end)
