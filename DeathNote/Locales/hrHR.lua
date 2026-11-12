-- DeathNote: Hrvatski (hrHR). Translation of enUS.lua by DaveeeG.
-- Plural: 3 forms {count|one|few|other} (1, 21, 31 .. not 11 | 2-4, 22-24 .. not 12-14 | 0, 5-20, 25 ..). Rule in Locale.lua (PLURAL_OF.hrHR), not here.
-- Fonts: latinExt (Nimrod MT, Arial Narrow) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- No Croatian game client: zone, class and race names come in the client's language (SAMPLE_ZONE stays English).
--
-- TOC-Notes: Popis smrti za PvP u otvorenom svijetu: pamti tko te je ubio i upozorava kad je ubojica blizu.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("hrHR")) then return end

Locale.Register("hrHR", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Tjeralice"  -- [max 16]
L.TAB_UNSOLVED = "Neriješeno"  -- [max 16]
L.TAB_DEATHLOG = "Dnevnik smrti"  -- [max 16]
L.TAB_GUILD = "Ceh"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Kućni red"  -- [max 24]
L.HEAD_HELP = "Kako to radi"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Knjiga"  -- [max 14]
L.SHEET_ALERT = "Uzbuna"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "JAVNI NEPRIJATELJ BR. 1"  -- [max 24]
L.STAMP_REVENGE = "OSVETA IZVRŠENA"  -- [max 16]
L.STAMP_PARDONED = "POMILOVANJE"  -- [max 16]
L.STAMP_SUSPECT = "SUMNJA"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "JAVNI NEPRIJATELJ BR. 1 BLIZU"  -- [max 30]
L.ALERT_SIGHTED = "JAVNI NEPRIJATELJ BLIZU"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "OSUMNJIČENI BLIZU"  -- [max 30]
L.ALERT_TITLE_GUILD = "NEPRIJATELJ CEHA BLIZU"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "UBOJICA PRIJATELJA BLIZU"  -- [max 30]
L.ALERT_TITLE_HUNT = "META S POPISA ZA ODSTREL"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "pod sumnjom"
L.ALERT_LINE_KILLED = "tvoje smrti: {times}"
L.ALERT_LINE_KILLED_ASSISTED = "tvoje smrti: {times}, asistencija: {assists}"
L.ALERT_LINE_ASSISTED = "udio u tvojoj smrti: {times}"
L.ALERT_LINE_MANUAL = "ručno upisano u knjigu"
L.ALERT_LINE_LAST = "{text}, zadnji put {time}"
L.ALERT_LINE_IN = "{text}, mjesto: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Osveta: {times}"
L.ALERT_HINT_CLOSE = "Desni klik: zatvori"  -- [max 44]
L.ALERT_HINT_COMBAT = "Ciljanje tek nakon borbe"  -- [max 44]
L.ALERT_HINT_TARGET = "Klik: naciljaj  ·  Desni klik: zatvori"  -- [max 44]
L.ALERT_MORE = "još +{count}"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "u knjizi ceha"
L.GUILD_LINE_IN_FRIENDS = "u knjizi prijatelja"
L.GUILD_LINE_LISTED_BY = "u knjigama: {names}"
L.GUILD_LINE_KILLED_GUILD = "ubijeno članova ceha: {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "ubijeno prijatelja: {kills}×"
L.GUILD_LINE_KILLED_BOTH = "ubijeno članova ceha i prijatelja: {kills}×"
L.GUILD_LINE_LAST = "{text}, zadnja žrtva: {name}"
L.HUNT_LINE_BY = "tko je raspisao lov: {names}"
L.HUNT_LINE_RELEASED = "na popisu za odstrel"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "pod sumnjom"
L.TALLY_MANUAL = "ručno upisano"
L.TALLY_NONE = "još bez nedjela"
L.TALLY_KILLED = "tvoje smrti: {times}"
L.TALLY_ASSISTED = "asistencija: {times}"
L.PLACE_UNKNOWN = "nepoznato mjesto"
L.GKILLS_CAP = "najmanje {count}"
L.NAMELIST_MORE = "{names} i još {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y. %H:%M"
L.TIME_FMT_DAY = "%d.%m."
L.TIME_FMT_DAY_YEAR = "%d.%m.%y."
L.TIME_NEVER = "nikad"
L.TIME_JUST = "upravo sad"
L.TIME_MINUTES = "prije {count} min"  -- [max 14]
L.TIME_HOURS = "prije {count} h"  -- [max 14]
L.TIME_DAYS = "prije {count} {count|dana|dana|dana}"  -- [max 16]
L.MONEY_GOLD = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "Članova ceha s DeathNoteom na vezi: {count}."
L.HEALTH_NOGUILD = "Nisi ni u jednom cehu, ništa se ne dijeli."
L.HEALTH_OFF = "Dijeljenje je isključeno."
L.HEALTH_SHORT_NOGUILD = "Nema ceha"  -- [max 18]
L.HEALTH_SHORT_OFF = "Dijeljenje isklj."  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Blokirano"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Odbijeno"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Čeka"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Upitano"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Ne radi"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Bez zvuka"  -- [max 16]
L.SOUND_RAIDWARNING = "Upozorenje raida"  -- [max 16]
L.SOUND_BELL = "Zvono"  -- [max 16]
L.SOUND_GONG = "Gong"  -- [max 16]
L.SOUND_HEARTBEAT = "Otkucaji srca"  -- [max 16]
L.SOUND_FEATHER = "Pero"  -- [max 16]
L.SOUND_SIREN = "Sirena"  -- [max 16]
L.CHANNEL_MASTER = "Glavni"  -- [max 16]
L.CHANNEL_SFX = "Efekti"  -- [max 16]
L.CHANNEL_DIALOG = "Dijalozi"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name}: sada u knjizi."
L.CHAT_REMOVED = "{name}: precrtano iz knjige."
L.CHAT_SYNC_WAIT = "Usklađivanje je upravo bilo. Pokušaj ponovno za {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Još nema imena."
L.EMPTY_WANTED_SUB = "Izađi već jednom van."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  otvori/zatvori knjigu"
L.HELP_ADD = "/dn add <Ime [Prezime]>  ručno upiši ubojicu u knjigu"
L.HELP_DEL = "/dn del <Ime [Prezime]>  precrtaj ubojicu iz knjige"
L.HELP_QUIET = "/dn quiet  uzbuna isklj./uklj."
L.HELP_TEST = "/dn test  prikaži probnu uzbunu"
L.HELP_GUILD = "/dn guild  knjiga ceha: stanje i tko iz ceha ima DeathNote"
L.HELP_FRIENDS = "/dn friends  knjiga prijatelja: stanje i tko od prijatelja ima DeathNote"
L.HELP_SYNC = "/dn sync  odmah uskladi knjigu ceha i knjigu prijatelja"
L.HELP_HUNT = "/dn hunt <Ime [Prezime]>  raspiši lov (bez imena: prikaži popis za odstrel)"
L.HELP_CALLOFF = "/dn calloff <Ime [Prezime]>  otkaži vlastiti poziv na lov"
L.HELP_LANG = "/dn lang <kod>  jezik knjige (enUS, deDE, hrHR ...), nakon /reload"
L.HELP_PROBE = "/dn probe  traženje grešaka: što igra govori knjizi"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  traženje grešaka, uz to provjera dnevnika borbe"
L.HELP_DEBUG = "/dn debug  traženje grešaka: detaljno bilježi svaku smrt (uklj./isklj.)"
L.HELP_HELP = "/dn help  ova pomoć"
L.HELP_SILENT_ZONES = "U tamnicama, na bojištima i u arenama knjiga sama šuti."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "uklj."
L.WORD_OFF = "isklj."
L.CHAT_WHO_ADD = "Koga? /dn add <Ime>"
L.CHAT_WHO_DEL = "Koga? /dn del <Ime>"
L.CHAT_WHO_CALLOFF = "Koga? /dn calloff <Ime>"
L.CHAT_BAD_NAME = "Neispravno ime."
L.CHAT_NOT_IN_BOOK = "Nije u knjizi: {name}"
L.CHAT_ALARM_ON = "Uzbuna uključena."
L.CHAT_ALARM_OFF = "Uzbuna isključena."
L.CHAT_DEBUG = "Zapis za traženje grešaka: {state}"
L.CHAT_UNKNOWN_CMD = "Nepoznata naredba. Pomoć: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Knjiga ceha nije učitana."
L.CHAT_NO_GUILD = "Nisi ni u jednom cehu (ili igra to još ne zna)."
L.CHAT_GUILD_STATE = "Ceh {guild}: dijeljenje {share}, primanje {receive}"
L.CHAT_GUILD_BOOK = "Knjiga ceha. Ubojice: {enemies} (samo ručno: {listed}), nedjela: {deeds}, sa žrtvama u cehu: {foreign}. Dijeljenje ručnih upisa: {manual}"
L.CHAT_STATE_OK = "Stanje: {text}"
L.CHAT_STATE_WARN = "Pažnja: {text}"
L.CHAT_NO_MATES = "Još se nitko iz ceha s DeathNoteom nije javio."
L.CHAT_HAVE_DN = "DeathNote imaju: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote imaju: {names} i još {count}"
L.CHAT_SYNC_ASKED = "Usklađivanje zatraženo. Odgovori stižu u idućih nekoliko sekundi."
L.CHAT_SYNC_FAIL = "Usklađivanje ne radi: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "nema ceha ili je dijeljenje isključeno."
L.CHAT_FRIENDS_NOT_LOADED = "Knjiga prijatelja nije učitana."
L.CHAT_FRIENDS_STATE = "Prijatelji: dijeljenje {share}, online {online} od {total}."
L.CHAT_FRIENDS_BOOK = "Knjiga prijatelja. Ubojice: {enemies} (samo ručno: {listed}), nedjela: {deeds}."
L.CHAT_NO_FRIENDS = "Još se nitko od prijatelja s DeathNoteom nije javio."
L.CHAT_HUNT_NOT_LOADED = "Popis za odstrel nije učitan."
L.CHAT_HUNT_UNKNOWN = "Nepoznato: {name}. Navedi i prezime, onako kako piše u igri."
L.CHAT_HUNT_CAP = "Lov se ne može raspisati: najviše {own} vlastitih poziva i {targets} meta po popisu."
L.CHAT_HUNT_NOWHERE = "Lov se sada ne može raspisati: nema ceha, a dijeljenje s prijateljima je isključeno."
L.CHAT_HUNT_BOTH = "{name}: lov raspisan za ceh i prijatelje."
L.CHAT_HUNT_GUILD = "{name}: lov raspisan za ceh."
L.CHAT_HUNT_FRIENDS = "{name}: lov raspisan za tvoje prijatelje."
L.CHAT_CALLED_OFF = "{name}: lov otkazan."
L.CHAT_NO_OWN_CALL = "{name}: nemaš vlastiti poziv na lov."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Jezik sada: {lang}. Promjena: /dn lang <kod>"
L.CHAT_LANG_LIST = "Kodovi: {codes}"
L.CHAT_LANG_BAD = "Nepoznat jezik: {code}"
L.CHAT_LANG_SET = "Jezik: {lang}."
L.CHAT_LANG_RELOAD = "Jezik: {lang}. Vrijedi nakon /reload."

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Knjiga je spremna. Tko te ubije u otvorenom svijetu, bit će u njoj. Otvori je s /dn ili gumbom uz minikartu."
L.WELCOME_PLATES = "Pločice neprijatelja su isključene. Bez njih uzbuna vidi samo tvoju metu."
L.WELCOME_SHARE = "Ceh i prijatelji koji imaju DeathNote čitaju s tobom. Bilješke i sumnje ostaju kod tebe."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "U KNJIZI:"
L.TIP_HUNT = "ZA ODSTREL:"
L.TIP_GUILDBOOK = "KNJIGA CEHA:"
L.TIP_PARDONED = "pomilovanje"
L.TIP_RANK = "{rank}. mjesto"
L.TIP_REVENGE = "osveta {times}"
L.TIP_LISTED_BY = "u knjigama: {names}"
L.TIP_NOTE = "Bilješka: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Klik: otvori · Desni klik: makni"
L.BANNER_NEW = "NOVI UPIS"  -- [max 24]
L.BANNER_NEW_LINE = "sada u knjizi"
L.BANNER_AGAIN = "OPET"  -- [max 24]
L.BANNER_AGAIN_LINE = "opet tvoja smrt, ukupno već {count}"
L.BANNER_SUSPECT = "SUMNJA"  -- [max 24]
L.BANNER_SUSPECT_LINE = "pod sumnjom, razjasni u knjizi"
L.BANNER_UNCLEAR = "UBOJICA NEPOZNAT"  -- [max 24]
L.BANNER_CANDIDATES = "{count} {count|kandidat|kandidata|kandidata}"
L.BANNER_UNCLEAR_LINE = "Klik: odredi ubojicu pod Neriješeno"
L.BANNER_REVENGE = "ODMAZDA"  -- [max 24]
L.BANNER_REVENGE_LINE = "Osveta izvršena ({count}×)"
L.BANNER_GUILD = "CEH"  -- [max 24]
L.BANNER_FRIENDS = "PRIJATELJI"  -- [max 24]
L.BANNER_KILLED_BY = "ubojica: {name}"
L.BANNER_HUNT = "POPIS ZA ODSTREL"  -- [max 24]
L.BANNER_BAGGED = "smrtni udarac: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Dijeljenje je isključeno (Kućni red, list Ceh)."
L.SYNC_FRIENDS_OFF = "Dijeljenje s prijateljima je isključeno."
L.SYNC_NOBODY = "Nema ni ceha ni prijatelja za dijeljenje."
L.SYNC_SHORT_NOBODY = "Ništa se ne dijeli"  -- [max 18]
L.SYNC_PREFIX = "Igra ne dopušta primanje. Pomaže ponovna prijava."
L.SYNC_SHORT_PREFIX = "Primanje ne ide"  -- [max 18]
L.SYNC_BLOCKED = "Server blokira slanje. Proslijedi knjigu preko Spremi knjigu."
L.SYNC_SHORT_BLOCKED = "Server blokira slanje"  -- [max 22]
L.SYNC_FAILING = "Slanje trenutno ne ide, pokušava se ponovno."
L.SYNC_SHORT_FAILING = "Slanje zapinje"  -- [max 18]
L.SYNC_HOLD = "Slanje čeka {wait}."
L.SYNC_HOLD_INSTANCE = "dok ne napustiš instancu"
L.SYNC_HOLD_COMBAT = "dok ne izađeš iz borbe"
L.SYNC_HOLD_LOCKDOWN = "dok chat opet ne bude slobodan"
L.SYNC_HOLD_AGAIN = "dok opet ne proradi"
L.SYNC_HOLD_SHORT_INSTANCE = "Čeka: instanca"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Čeka: borba"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Čeka: chat"  -- [max 18]
L.SYNC_QUIET = "Poslano, ali još se nitko iz ceha s DeathNoteom nije javio."
L.SYNC_READY = "Spremno. Još se nitko iz ceha s DeathNoteom nije javio."
L.SYNC_RUNNING = "Radi: {count} {count|osoba|osobe|osoba} iz ceha s DeathNoteom."
L.SYNC_RUNNING_ALL = "Radi. S DeathNoteom u cehu i među prijateljima: {count}."
L.FRIENDS_OFF = "Dijeljenje s prijateljima je isključeno (Kućni red, list Ceh)."
L.FRIENDS_BLOCKED = "Server blokira šapat. Prijatelji ne dobivaju ništa."
L.FRIENDS_SHORT_BLOCKED = "Server blokira šapat"  -- [max 22]
L.FRIENDS_FAILING = "Šapat trenutno ne ide, pokušava se ponovno."
L.FRIENDS_SHORT_FAILING = "Šapat zapinje"  -- [max 18]
L.FRIENDS_NONE_LISTED = "Na popisu prijatelja nema nikoga."
L.FRIENDS_NONE_ONLINE = "Trenutno nijedan prijatelj nije online."
L.FRIENDS_SHORT_NONE_ONLINE = "Prijatelji offline"  -- [max 18]
L.FRIENDS_QUIET = "Upitano, ali još se nitko od prijatelja s DeathNoteom nije javio."
L.FRIENDS_READY = "Spremno. Još se nitko od prijatelja s DeathNoteom nije javio."
L.FRIENDS_HOLD = "Slanje prijateljima čeka dok opet ne proradi."
L.FRIENDS_RUNNING = "Radi: {count} {count|prijatelj|prijatelja|prijatelja} s DeathNoteom."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Preuzeto iz knjige ceha (ubijeno članova ceha: {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Baza podataka nije učitana."
L.IMPORT_NO_TEXT = "Nema teksta."
L.IMPORT_NO_HEADER = "Nedostaje prvi redak (počinje s {header}). Kopiraj cijeli tekst."
L.IMPORT_NOT_EXPORT = "Ovo nije DeathNote izvoz (nema zaglavlja ili kriva verzija)."
L.IMPORT_TOO_LONG = "Previše redaka (najviše {count})."
L.IMPORT_BAD_KEY = "Redak {line}: neispravan ključ."
L.IMPORT_BAD_TIME = "Redak {line}: neispravno vrijeme."
L.IMPORT_BROKEN = "Redak {line} je nepotpun ili oštećen (odrezan tekst?). Ništa nije učitano."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "da"
L.WORD_NO = "ne"
L.PROBE_HEAD = "Sonda: sučelja {apis}/{apisAll} dostupna, događaja za registraciju {events}/{eventsAll}."
L.PROBE_MISSING = "Nedostaje: {list}"
L.PROBE_NOT_REGISTERABLE = "Ne može se registrirati: {list}"
L.PROBE_SOURCES = "Recap sada: {recap} · Meter: {meter} · Dnevnik borbe: {clog}"
L.PROBE_READABLE = "čitljivo"
L.PROBE_DEAD = "mrtvo"
L.PROBE_PLATES = "Pločice neprijatelja: {plates} · Otvoreni svijet: {open}"
L.PROBE_PLATES_OFF = "ISKLJ. (igrače otkrivaju samo meta i miš)"
L.PROBE_TARGET = "Meta: ime={name} GUID={guid} klasa={class} neprijateljski={enemy} cilja mene={me}"
L.PROBE_GUILD = "Ceh: prefiks {prefix} · slanje {send} · zadnja povratna vrijednost {result} · poslano {sent}, primljeno {received}, odbačeno {dropped}"
L.PROBE_REGISTERED = "registrirano"
L.PROBE_NOT_REGISTERED = "NIJE registrirano ({result})"
L.PROBE_POSSIBLE = "moguće"
L.PROBE_ABSENT = "nedostaje"
L.PROBE_WAITS = " · čeka: {why}"
L.PROBE_LISTED = "Ručni upisi (M): poslano {sent}, primljeno {received}, odbačeno {dropped} · precrtani (X): poslano {usent}, primljeno {ureceived}, odbačeno {udropped}"
L.PROBE_GUILDBOOK = "Knjiga ceha: {text}"
L.PROBE_SAVED = "Spremljeno u DeathNoteDB.probe (u datoteci nakon /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Poredak"  -- [max 14]
L.SORT_RECENT = "Najnovije"  -- [max 14]
L.SORT_NAME = "Ime"  -- [max 14]
L.SORT_SEEN = "Viđenja"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Tko te ubije u otvorenom svijetu, završava ovdje. Samo od sebe."
L.EMPTY_OPEN_HEAD = "Ništa za razjasniti."
L.EMPTY_JOURNAL_HEAD = "Još nijedna smrt."
L.EMPTY_JOURNAL_SUB = "Respekt. Ili laž."
L.EMPTY_NOGUILD_HEAD = "Nema ceha."
L.EMPTY_NOGUILD_SUB = "Umire se i u samoći."
L.EMPTY_GUILDOFF_HEAD = "Knjiga ceha je zatvorena."
L.EMPTY_GUILDOFF_SUB = "Dijeljenje je isključeno. Kućni red zna gdje."
L.EMPTY_GUILDNIL_HEAD = "Iz ceha još ni riječi."
L.EMPTY_GUILDNIL_SUB = "Tvoja knjiga kreće čim netko iz ceha ima DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "U knjizi ceha još nema ničega."
L.EMPTY_GUILDQUIET_SUB = "Tvoj ceh je dosad imao mira."
L.EMPTY_FRIENDSOFF_HEAD = "Knjiga prijatelja je zatvorena."
L.EMPTY_FRIENDSOFF_SUB = "Dijeljenje s prijateljima je isključeno. Kućni red zna gdje."
L.EMPTY_FRIENDSNIL_HEAD = "Još se nitko od prijatelja s DeathNoteom nije javio."
L.EMPTY_FRIENDSNIL_SUB = "Tvoja knjiga kreće čim netko od prijatelja ima DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Od prijatelja još ništa."
L.EMPTY_FRIENDSQUIET_SUB = "Tvoji prijatelji su dosad imali mira."
L.EMPTY_NOBODY_HEAD = "Nema ceha, nema prijatelja."
L.EMPTY_NOBODY_SUB = "Umire se i u samoći."
L.EMPTY_NOBODY_HINT = "Kad članovi ceha ili prijatelji s popisa prijatelja imaju DeathNote, ovdje piše što im se događa."
L.EMPTY_SHAREDNIL_HEAD = "Još se nitko s DeathNoteom nije javio."
L.EMPTY_SHAREDNIL_SUB = "Tvoja knjiga kreće čim članovi ceha ili prijatelji imaju DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Ovdje još nema ničega."
L.EMPTY_SHAREDQUIET_SUB = "Ceh i prijatelji su dosad imali mira."
L.EMPTY_HUNT_HEAD = "Popis za odstrel je prazan."
L.EMPTY_HUNT_SUB = "Na tjeralici: Raspiši lov."
L.EMPTY_HUNT_HINT = "Ili u chatu: /dn hunt Ime Prezime. To vide svi u tvom cehu i tvoji prijatelji."
L.EMPTY_SEARCH_HEAD = "Nema pogotka."
L.EMPTY_SEARCH_SUB = "Enter upisuje ime u knjigu."
L.EMPTY_SEARCHRO_HEAD = "Nema pogotka."
L.EMPTY_SEARCHRO_SUB = "Ponekad pomaže drukčiji zapis."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "KNJIGA"  -- [max 12]
L.MANUAL_BOOK = "Tko te ubije u otvorenom svijetu, automatski se upisuje. Klik na poruku nakon smrti otvara stranicu ubojice."
L.MANUAL_WANTED_HEAD = "TJERALICE"  -- [max 12]
L.MANUAL_WANTED = "Tvoje ubojice, najgore prve. Klik pokazuje tjeralicu s nedjelima i bilješkom. Pomilovani su precrtani na kraju."
L.MANUAL_UNSOLVED_HEAD = "NERIJEŠENO"  -- [max 13]
L.MANUAL_UNSOLVED = "Kad nije jasno tko je to bio, slučaj čeka ovdje. Klik na ime određuje ubojicu."
L.MANUAL_ALERT_HEAD = "UZBUNA"  -- [max 12]
L.MANUAL_ALERT = "Kad se ubojica pojavi kao pločica, meta ili pod mišem, knjiga se javi. Klik ga uzima za metu, u borbi tek nakon nje."
L.MANUAL_ADD_HEAD = "UPIS"  -- [max 12]
L.MANUAL_ADD = "Upiši ime u polje za pretragu, Enter. Desni klik na redak: zabilježi osvetu, pomiluj, precrtaj."
L.MANUAL_GUILD_HEAD = "CEH"  -- [max 12]
L.MANUAL_GUILD = "Članovi ceha i prijatelji koji imaju DeathNote vide tvoje potvrđene smrti i ručne upise. Tjeralica ili /dn hunt Ime: raspiši lov. Klik na ucjenu: raspiši svoju, samo obećanje, namirujete se međusobno."
L.MANUAL_SHARE_HEAD = "PROSLIJEDI"  -- [max 12]
L.MANUAL_SHARE = "Kućni red, Spremi knjigu: tekst za kopiranje, za sve bez DeathNotea."
L.MANUAL_QUIET_HEAD = "TIŠINA"  -- [max 12]
L.MANUAL_QUIET = "U tamnicama i na bojištima uzbuna šuti. Inače: srednji klik na gumb uz minikartu ili /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Stvarno precrtati iz knjige: {name}?\nSva nedjela i bilješka bit će izgubljeni."
L.CONFIRM_DELETE_OK = "Precrtaj"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Isprazniti knjigu ceha na ovom računalu?\nNjezin popis za odstrel ide s njom, tvoji vlastiti pozivi ostaju.\nTvoja vlastita knjiga ostaje kakva jest."
L.CONFIRM_GUILD_CLEAR_OK = "Isprazni"  -- [max 14]
L.CONFIRM_CANCEL = "Odustani"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ZLATA"  -- [max 14]
L.BOUNTY_SILVER = "{count} SREBRA"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Potvrdi"  -- [max 19]
L.ACT_DISMISS = "Odbaci"  -- [max 19]
L.ACT_HUNT_AGAIN = "Opet u potjeru"  -- [max 19]
L.ACT_REVENGE = "Zabilježi osvetu"  -- [max 19]
L.ACT_PARDON = "Pomiluj"  -- [max 19]
L.ACT_STRIKE = "Precrtaj"  -- [max 19]
L.ACT_OPEN_OWN = "Otvori u knjizi"  -- [max 19]
L.ACT_ADOPT = "U moju knjigu"  -- [max 19]
L.ACT_CALLOFF = "Otkaži lov"  -- [max 19]
L.ACT_RELEASE = "Raspiši lov"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "viđenje {time}"
L.ROW_NOT_SEEN = "još bez viđenja"
L.ROW_PARDONED = "pomilovanje"
L.ROW_SUSPECT = "Sumnja"
L.MARK_REVENGE = "OSVETA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Ubojica nepoznat"
L.MARK_CANDIDATES = "{count} {count|KANDIDAT|KANDIDATA|KANDIDATA}"  -- [max 16]
L.MARK_SUSPECT = "SUMNJA"  -- [max 16]
L.ROW_NO_PLAYER = "Nije igrač"
L.ROW_UNCLEAR = "Nejasno kako"
L.MARK_NOT_COUNTED = "NE BROJI SE"  -- [max 16]
L.ROW_LISTED_BY = "tko je upisao: {names}"
L.ROW_GKILLED = "ubojstava: {kills}×"
L.ROW_VICTIMS = "{count} {count|žrtva|žrtve|žrtava}"
L.ROW_LAST = "zadnje: {text}"
L.MARK_IN_BOOK = "U KNJIZI"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|ubojica|ubojice|ubojica}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|smrt|smrti|smrti}"  -- [max 12]
L.MEMBER_LISTED = "{count} ručno"  -- [max 14]
L.MEMBER_ME = "što drugi vide o tebi"
L.MEMBER_NOTHING = "još ništa podijeljeno"
L.MEMBER_LAST_DIED = "zadnja smrt {time}"
L.MARK_YOU = "ti"  -- [max 16]
L.MARK_FRIEND = "PRIJATELJ"  -- [max 16]
L.MARK_BOTH = "IZ CEHA, PRIJATELJ"  -- [max 20]
L.MARK_TAKEN_DOWN = "ULOV {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ŽIV ILI MRTAV"  -- [max 24]
L.POSTER_DEEDS = "NEDJELA"  -- [max 14]
L.POSTER_NOTE = "BILJEŠKA"  -- [max 8]
L.POSTER_BOUNTY = "UCJENA"  -- [max 12]
L.ROLE_ASSIST = "asistencija"  -- [max 14]
L.ROLE_SUSPECT = "sumnja"  -- [max 14]
L.POSTER_LEVEL = "Razina {level}"
L.POSTER_GUILD = "Ceh: {guild}"
L.POSTER_LAST_SEEN = "Zadnje viđenje {time}"
L.POSTER_NOT_SEEN = "Još bez viđenja"
L.POSTER_ONLY_SUSPECT = "Samo sumnja, nijedno dokazano nedjelo."
L.POSTER_NO_DEEDS = "Nema zabilježenih nedjela."
L.TIP_LISTED_AT = "Upisano {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Uzrok smrti: {spell}"
L.TIP_VICTIM = "Žrtva: {name}"
L.TIP_VICTIM_LEVEL = "Žrtva: {name} (razina {level})"
L.TIP_KILLER_LEVEL = "Razina ubojice: {level}"
L.TIP_ASSISTS = "Asistencija: {names}"
L.TIP_ROLE_ASSIST = "Asistencija bez smrtnog udarca."
L.TIP_ROLE_SUSPECT = "Samo sumnja, nije dokazano."
L.MORE_LINE = "… i još {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "KNJIGA CEHA"  -- [max 24]
L.POSTER_IN_BOOK_OF = "U knjigama: {names}"
L.POSTER_SEEN = "Viđenje {time}"
L.POSTER_SEEN_BY = "Viđenje {time}, javlja: {name}"
L.TIP_IN_BOOK_OF = "U knjigama"
L.POSTER_REMARK = "NAPOMENA"  -- [max 12]
L.POSTER_BY_HAND = "RUČNO UPISANO"  -- [max 22]
L.POSTER_VICTIMS = "ŽRTVE"  -- [max 12]
L.POSTER_LISTED = "UPISALI"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Ručno upisano."
L.POSTER_NO_DEEDS_SENT = "Nedjela nisu proslijeđena."
L.POSTER_NONE_KNOWN = "nijedna poznata"
L.POSTER_NO_NAMES = "imena nisu proslijeđena"
L.TIP_VICTIMS = "Žrtve"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Raspisano {time}"
L.HUNT_REASON = "Razlog: {reason}"
L.POSTER_HUNTLIST = "POPIS ZA ODSTREL"  -- [max 24]
L.POSTER_RELEASED_N = "lov raspisan {times}"
L.POSTER_RELEASED_BY = "Tko je raspisao: {names}"
L.POSTER_TAKEN_DOWN = "ULOV"  -- [max 12]
L.POSTER_NOT_YET = "JOŠ NE"  -- [max 18]
L.POSTER_CALLS = "POZIVI NA LOV"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Više nitko."
L.POSTER_LAST = "ZADNJE"  -- [max 13]
L.POSTER_TAKEN_BY = "smrtni udarac: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "još nema ulova"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Smrt"  -- [max 20]
L.CASE_ASSISTS = "ASISTENCIJA"  -- [max 24]
L.CASE_PICK = "ODREDI UBOJICU"  -- [max 24]
L.CASE_NOT_COUNTED = "Ne broji se (instanca, bojište ili dvoboj)"
L.CASE_KILLER = "UBOJICA"  -- [max 24]
L.CASE_KILLER_SUSPECT = "UBOJICA (SUMNJA)"  -- [max 24]
L.CASE_CLICK_NAME = "Klik na ime otvara tjeralicu."
L.CASE_GONE = "Više nije u knjizi."
L.CASE_KILLER_UNCLEAR = "UBOJICA NEPOZNAT"  -- [max 24]
L.CASE_SEVERAL = "Više njih dolazi u obzir. Čije ime ide u knjigu?"
L.CASE_NOBODY = "Nitko ne dolazi u obzir."
L.CASE_HOW = "ŠTO SE DOGODILO"  -- [max 24]
L.CASE_PVE = "Čudovište ili sam svijet. Nije slučaj za knjigu."
L.CASE_UNCLEAR = "Nejasno"
L.CASE_DARK = "Istraga tapka u mraku."
L.TIP_MORE_CANDIDATES = "Ostali kandidati"
L.CASE_SOURCE_SUSPECT = "Sumnja: taj igrač te je imao na meti malo prije smrti."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Redak u tooltipu kod ubojica"  -- [max 44]
L.OPT_MINIMAP = "Gumb uz minikartu"  -- [max 44]
L.OPT_ALERT = "Uzbuna kad se pojavi ubojica"  -- [max 44]
L.OPT_FLASH = "Crveni bljesak na rubu zaslona"  -- [max 44]
L.OPT_SUSPECTS = "Javljaj i osumnjičene"  -- [max 44]
L.OPT_DEATHMSG = "Poruka nakon smrti u PvP-u"  -- [max 44]
L.OPT_G_SHARE = "Dijeli moje smrti"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Dijeli ručne upise"  -- [max 44]
L.OPT_G_RECEIVE = "Primaj knjigu ceha"  -- [max 44]
L.OPT_G_ALERT = "Upozori na ubojice iz knjige ceha"  -- [max 44]
L.OPT_G_ALERTLISTED = "Upozori i na ručne upise"  -- [max 44]
L.OPT_G_ANNOUNCE = "Javi kad netko iz ceha pogine"  -- [max 44]
L.OPT_G_SIGHTINGS = "Dijeli viđenja"  -- [max 44]
L.OPT_F_SHARE = "Dijeli s cehom"  -- [max 44]
L.OPT_F_FRIENDS = "Dijeli s prijateljima"  -- [max 44]
L.OPT_F_ALERT = "Upozori na ubojice ceha i prijatelja"  -- [max 44]
L.OPT_F_ALERTHUNT = "Upozori na mete s popisa za odstrel"  -- [max 44]
L.OPT_F_ANNOUNCE = "Javi kad pogine netko iz ceha ili prijatelj"  -- [max 44]
L.OPT_F_SIGHTINGS = "Dijeli viđenja s cehom i prijateljima"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Ceh"  -- [max 14]
L.SET_BOOK_SIZE = "Veličina knjige"  -- [max 34]
L.SET_LANGUAGE = "Jezik"  -- [max 16]
L.SET_LANG_AUTO = "Automatski"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Treba ponovno učitati."  -- [max 28]
L.SET_LANG_RELOAD = "Učitaj ponovno"  -- [max 22]
L.SET_SEC_SHARE = "PROSLIJEDI"  -- [max 24]
L.IO_EXPORT = "Spremi knjigu"  -- [max 17]
L.IO_IMPORT = "Učitaj knjigu"  -- [max 17]
L.SET_HINT_BOOK = "Spremanje ti daje knjigu kao tekst: za čuvanje ili za ljude izvan ceha. Učitavanje spaja i ništa ne prepisuje."
L.SET_SEC_SOUND = "ZVUK"  -- [max 24]
L.SET_SOUND = "Zvuk"  -- [max 22]
L.SET_VOLUME = "Glasnoća"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "PRAG"  -- [max 24]
L.SET_COOLDOWN = "Stanka po ubojici"  -- [max 34]
L.SET_MINKILLS = "Uzbuna nakon toliko smrti od njega"  -- [max 34]
L.SET_ALERT_SIZE = "Veličina uzbune"  -- [max 34]
L.SET_TEST_ALERT = "Probna uzbuna"  -- [max 17]
L.SET_G_MINKILLS = "Upozorenje ceha od toliko smrti"  -- [max 34]
L.SET_F_MINKILLS = "Upozorenje od toliko smrti"  -- [max 34]
L.SET_SEC_STATUS = "STANJE"  -- [max 24]
L.SET_SEC_SHARING = "DIJELJENJE"
L.SET_SEC_WARN = "UZBUNA"
L.SET_MORE = "Više"
L.SET_GUILD_CLEAR = "Isprazni knjigu ceha"  -- [max 26]
L.SET_HINT_GUILD = "Podatke dobiva samo tvoj ceh. Ono što dođe odande ostaje odvojeno od tvoje knjige dok to ne preuzmeš."
L.SET_HINT_FRIENDS = "Podatke dobivaju samo ceh i prijatelji s DeathNoteom."
L.BTN_BACK = "Natrag"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Uskladi"  -- [max 14]
L.SYNC_AGAIN_IN = "opet za {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Prijatelji"
L.TIP_GUILD_NAME = "Ceh {guild}"
L.TIP_MATES_WITH = "Iz ceha s DeathNoteom:"
L.TIP_NO_MATE = "Još se nitko iz ceha s DeathNoteom nije javio."
L.TIP_FRIENDS_WITH = "Prijatelji s DeathNoteom:"
L.TIP_SHARED = "Dijeli se: tvoje potvrđene smrti, ručni upisi i tvoji pozivi na lov."
L.TIP_NOT_SHARED = "Ne dijeli se: bilješke, sumnje, pomilovani, učitani upisi."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Učitaj"  -- [max 17]
L.IO_DONE = "Učitano. Novih: {new}, spojenih: {merged}."
L.IO_FAILED = "To nije uspjelo."
L.IO_SMALL = "Samo sažetak"  -- [max 17]
L.IO_ALL = "Prikaži sve"  -- [max 17]
L.IO_MSG_FULL = "Cijela knjiga s nedjelima ({size})."
L.IO_MSG_SHORT = "Samo imena i brojevi ({size}). S nedjelima: {full}."
L.IO_MSG_BIG = "Velika knjiga ({size}): označavanje i kopiranje malo traju."
L.IO_HELP_EXPORT = "Tekst je označen: Ctrl+C ga kopira. Sačuvaj ga ili proslijedi prijateljima."
L.IO_HELP_IMPORT = "Zalijepi spremljeni tekst s Ctrl+V, zatim Učitaj. Ništa se ne prepisuje."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Razlog vide svi u tvom cehu i tvoji prijatelji s DeathNoteom."
L.REL_HINT_GUILD = "Razlog vide svi u tvom cehu s DeathNoteom."
L.REL_HINT_FRIENDS = "Razlog vide tvoji prijatelji s DeathNoteom."
L.REL_HEAD = "Raspiši lov"  -- [max 24]
L.REL_FOR = "ZA"  -- [max 6]
L.REL_REASON = "RAZLOG"  -- [max 8]
L.REL_HINT2 = "Tvoja bilješka ostaje kod tebe. Vlastiti poziv možeš otkazati samo ti."
L.REL_GO = "Raspiši lov"  -- [max 17]
L.REL_NONE = "Nema ceha, a dijeljenje s prijateljima je isključeno."
L.REL_CAP = "Najviše {own} vlastitih poziva i {max} meta po popisu."
L.REL_FAILED = "Lov se sada ne može raspisati."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Bez zvuka: uzbuna se samo prikazuje."
L.SET_HINT_BUILTIN = "Glasnoća ovog zvuka prati kanal u postavkama igre."
L.SET_HINT_LEVELS = "Pet razina, od tiho do glasno. Uz to djeluje klizač kanala u postavkama igre."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Ceh i prijatelji"  -- [max 18]
L.TIP_HELP_BUTTON = "Kako radi knjiga"
L.VIEW_HUNT = "Za odstrel"  -- [max 13]
L.VIEW_BY_KILLER = "Po ubojicama"  -- [max 13]
L.VIEW_BY_MATE = "Po žrtvama"  -- [max 13]
L.SRC_ALL = "Svi"  -- [max 12]
L.SRC_GUILD = "Ceh"  -- [max 12]
L.SRC_FRIENDS = "Prijatelji"  -- [max 12]
L.SORT_HIDE_PARDONED = "Sakrij pomilovane"  -- [max 24]
L.SORT_SHOW_PARDONED = "Prikaži pomilovane"  -- [max 24]
L.SEARCH_ADD = "Traži ili upiši …"  -- [max 26]
L.SEARCH_SHORT = "Traži …"  -- [max 10]
L.SEARCH_KILLER = "Traži ubojicu …"  -- [max 15]
L.SEARCH_JOURNAL = "Ubojica ili mjesto …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Sklopi sve"
L.TIP_EXPAND_ALL = "Rasklopi sve"
L.STATUS_NO_PLATES = "Pločice neprijatelja su isključene: uzbuna vidi samo metu i miš."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "Traženih: {count}"
L.MM_UNSOLVED = "Neriješeno: {count}"
L.MM_ALERT_OFF = "Uzbuna je isključena (srednji klik)"
L.MM_CLICK = "Klik: knjiga · Desni klik: Kućni red"
L.MM_MIDDLE = "Srednji klik: uzbuna uklj./isklj."
L.MM_DRAG = "Povuci: pomakni uz rub minikarte"
L.MM_CHAT_ALERT_ON = "Uzbuna uključena."
L.MM_CHAT_ALERT_OFF = "Uzbuna isključena."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "NEPRIJATELJ CEHA BR. 1"  -- [max 25]
L.STAMP_HUNT = "LOV JE OTVOREN"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} se predstavlja kao tvoj prijatelj {friend}: odbijeno."
L.FRIENDS_SHORT_IMPOSTOR = "Odbijeno: stranac"  -- [max 22]
L.ALERT_LEVEL = "Razina {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "zadnja razina {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Razina ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · na popisu za odstrel ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nova meta|nove mete|novih meta}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "novo na popisu za odstrel"
L.OPT_F_ANNOUNCEHUNT = "Javljaj nove i ulovljene mete s popisa"  -- [max 44]
L.SET_HUNT_EXPIRE = "Pozivi na lov istječu nakon"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nikad"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dan|dana|dana}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Isprazni knjigu prijatelja"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Isprazniti knjigu prijatelja na ovom računalu?\nNjezin popis za odstrel ide s njom, tvoji vlastiti pozivi ostaju."
L.CONFIRM_CALLOFF_ALL = "Otkazati sve svoje pozive na lov?\nCeh i prijatelji saznat će to postupno."
L.CONFIRM_CALLOFF_ALL_OK = "Otkaži sve"  -- [max 14]
L.ACT_CALLOFF_ALL = "Otkaži sve moje pozive"  -- [max 24]
L.ACT_HUNT_HIDE = "Sakrij za mene"  -- [max 19]
L.ACT_HUNT_SHOW = "Opet prikaži"  -- [max 19]
L.HUNT_ROW_HIDDEN = "skriveno za tebe"
L.HUNT_ROW_CALLS = "{count} {count|poziv|poziva|poziva}: {names}"
L.POSTER_ON_HUNTLIST = "Na popisu za odstrel ({names})"
L.REL_SELF = "Ne možeš raspisati lov na sebe."
L.REL_MATE = "To je netko vaš (ceh ili prijatelji s DeathNoteom)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Tko je tvoj prijatelj {friend}: {a} ili {b}? Odaberi."
L.FRIENDS_SHORT_CONFLICT = "Prijatelj nejasan"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Dva igrača tvrde da su tvoj prijatelj {friend}: {a} i {b}. Dok ne odabereš, knjiga ne prima ništa ni od jednog od njih. Ceh i prijatelji, prikaz Po žrtvama: desni klik na ime."
L.MEMBER_CONFLICT = "Desni klik: je li to tvoj prijatelj?"  -- [max 40]
L.ACT_TIE_MINE = "Moj prijatelj: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Odvoji ime"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Odvojiti {name} od popisa prijatelja?\nŠto je to ime unijelo u knjigu prijatelja, bit će obrisano; sljedeća poruka pod tim imenom ponovno povezuje."
L.CHAT_FRIENDS_TIES = "Povezana puna imena (* = prvi kontakt, još nije potvrđeno): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Ime [Prezime]> <zlato>  raspiši vlastitu ucjenu (bez iznosa: povuci)"
L.CHAT_WHO_BOUNTY = "Na koga? /dn bounty <Ime> <zlato>"
L.CHAT_BOUNTY_SET = "{name}: tvoja ucjena od {gold}g je raspisana. Ceh i prijatelji s DeathNoteom je vide."
L.CHAT_BOUNTY_OFF = "{name}: tvoja ucjena je povučena."
L.CHAT_BOUNTY_NONE = "{name}: nemaš vlastitu ucjenu."
L.CHAT_BOUNTY_BAD = "Ucjena: cijeli broj zlatnika, od 1 do 99999 (0 je povlači)."
L.CHAT_BOUNTY_CAP = "Nema ucjene: najviše {count} vlastitih."
L.CHAT_BOUNTY_OURS = "Nema ucjene na sebe ni na svoje (ceh ili prijatelji s DeathNoteom)."
L.ACT_BOUNTY = "Raspiši ucjenu"  -- [max 24]
L.ACT_UNDO = "Poništi"  -- [max 19]
L.ACT_REVENGE_TAKE = "Oduzmi jednu osvetu"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, tvoja ucjena"
L.POSTER_BOUNTY_BY = "{gold}, raspisuje: {name}"
L.POSTER_BOUNTY_MANY = "Ucjena {gold}: {names}"
L.POSTER_AVENGED = "Osvetili: {names}"
L.ROW_AVENGED = "osvećeno {times}"
L.BOUNTY_TIP_HEAD = "Tvoja vlastita ucjena u zlatu"
L.BOUNTY_TIP_RULES = "Cijeli broj od 1 do 99999. Prazno ili 0: natrag na vrijednost knjige. Enter postavlja, Esc odustaje."
L.BOUNTY_TIP_PROMISE = "Ceh i prijatelji s DeathNoteom je vide. Samo obećanje: namirujete se međusobno."
L.BOUNTY_TIP_CLICK = "Klik: raspiši vlastitu ucjenu"
L.CHAT_AVENGED = "Osveta za tebe: {killer}, od {name}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: tvoja ucjena od {gold}g je raspisana."
L.CHAT_BOUNTY_UNKNOWN = "{name}: nema u tvojim knjigama. Ucjena samo na ime iz knjige, onako kako ga igra prikazuje: ime i prezime."
L.CHAT_BOUNTY_LIST = "Tvoje ucjene ({count} od {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Nemaš vlastitu ucjenu."
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
