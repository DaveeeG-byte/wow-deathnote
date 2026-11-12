-- DeathNote: Polski (plPL). Translation of enUS.lua by DaveeeG.
-- Plural: 3 forms {count|one|few|many} (1 only | 2-4, 22-24 .. not 12-14 | 0, 5-21, 25 ..). Rule in Locale.lua (PLURAL_OF.plPL), not here.
-- Fonts: latinExt (Nimrod MT, Arial Narrow) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- No Polish game client: zone, class and race names come in the client's language (SAMPLE_ZONE stays English).
--
-- TOC-Notes: Lista zgonów do PvP w otwartym świecie: pamięta, kto cię zabił, i ostrzega, gdy zabójca jest blisko.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("plPL")) then return end

Locale.Register("plPL", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Poszukiwani"  -- [max 16]
L.TAB_UNSOLVED = "Niewyjaśnione"  -- [max 16]
L.TAB_DEATHLOG = "Dziennik zgonów"  -- [max 16]
L.TAB_GUILD = "Gildia"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Regulamin"  -- [max 24]
L.HEAD_HELP = "Jak to działa"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Księga"  -- [max 14]
L.SHEET_ALERT = "Alarm"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "WRÓG PUBLICZNY NR 1"  -- [max 24]
L.STAMP_REVENGE = "ZEMSTA DOKONANA"  -- [max 16]
L.STAMP_PARDONED = "UŁASKAWIONO"  -- [max 16]
L.STAMP_SUSPECT = "PODEJRZENIE"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "WRÓG PUBLICZNY NR 1 BLISKO"  -- [max 30]
L.ALERT_SIGHTED = "WRÓG PUBLICZNY BLISKO"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "PODEJRZANY BLISKO"  -- [max 30]
L.ALERT_TITLE_GUILD = "WRÓG GILDII BLISKO"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "ZABÓJCA ZNAJOMYCH BLISKO"  -- [max 30]
L.ALERT_TITLE_HUNT = "CEL Z LISTY DO ODSTRZAŁU"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "pod podejrzeniem"
L.ALERT_LINE_KILLED = "twoje zgony: {times}"
L.ALERT_LINE_KILLED_ASSISTED = "twoje zgony: {times}, udział: {assists}"
L.ALERT_LINE_ASSISTED = "udział w twoim zgonie: {times}"
L.ALERT_LINE_MANUAL = "wpisano do księgi ręcznie"
L.ALERT_LINE_LAST = "{text}, ostatnio {time}"
L.ALERT_LINE_IN = "{text}, miejsce: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Zemsta: {times}"
L.ALERT_HINT_CLOSE = "Prawy klik: zamknij"  -- [max 44]
L.ALERT_HINT_COMBAT = "Namierzanie dopiero po walce"  -- [max 44]
L.ALERT_HINT_TARGET = "Klik: namierz  ·  Prawy klik: zamknij"  -- [max 44]
L.ALERT_MORE = "jeszcze +{count}"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "w księdze gildii"
L.GUILD_LINE_IN_FRIENDS = "w księdze znajomych"
L.GUILD_LINE_LISTED_BY = "w księgach: {names}"
L.GUILD_LINE_KILLED_GUILD = "ofiary w gildii: {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "ofiary wśród znajomych: {kills}×"
L.GUILD_LINE_KILLED_BOTH = "ofiary w gildii i wśród znajomych: {kills}×"
L.GUILD_LINE_LAST = "{text}, ostatnia ofiara: {name}"
L.HUNT_LINE_BY = "kto ogłosił polowanie: {names}"
L.HUNT_LINE_RELEASED = "na liście do odstrzału"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "pod podejrzeniem"
L.TALLY_MANUAL = "wpisano ręcznie"
L.TALLY_NONE = "na razie bez czynów"
L.TALLY_KILLED = "twoje zgony: {times}"
L.TALLY_ASSISTED = "udział: {times}"
L.PLACE_UNKNOWN = "nieznane miejsce"
L.GKILLS_CAP = "co najmniej {count}"
L.NAMELIST_MORE = "{names} i jeszcze {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY = "%d.%m"
L.TIME_FMT_DAY_YEAR = "%d.%m.%y"
L.TIME_NEVER = "nigdy"
L.TIME_JUST = "przed chwilą"
L.TIME_MINUTES = "{count} min temu"  -- [max 14]
L.TIME_HOURS = "{count} godz. temu"  -- [max 14]
L.TIME_DAYS = "{count} {count|dzień|dni|dni} temu"  -- [max 16]
L.MONEY_GOLD = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "Słychać DeathNote u {count} {count|osoby|osób|osób} z gildii."
L.HEALTH_NOGUILD = "Nie masz gildii, nic nie jest udostępniane."
L.HEALTH_OFF = "Udostępnianie jest wyłączone."
L.HEALTH_SHORT_NOGUILD = "Brak gildii"  -- [max 18]
L.HEALTH_SHORT_OFF = "Udostępnianie wył."  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Zablokowane"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Odrzucone"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Czeka"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Zapytano"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Nie działa"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Bez dźwięku"  -- [max 16]
L.SOUND_RAIDWARNING = "Alarm rajdowy"  -- [max 16]
L.SOUND_BELL = "Dzwon"  -- [max 16]
L.SOUND_GONG = "Gong"  -- [max 16]
L.SOUND_HEARTBEAT = "Bicie serca"  -- [max 16]
L.SOUND_FEATHER = "Pióro"  -- [max 16]
L.SOUND_SIREN = "Syrena"  -- [max 16]
L.CHANNEL_MASTER = "Główny"  -- [max 16]
L.CHANNEL_SFX = "Efekty"  -- [max 16]
L.CHANNEL_DIALOG = "Dialogi"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name}: teraz w księdze."
L.CHAT_REMOVED = "{name}: wykreślono z księgi."
L.CHAT_SYNC_WAIT = "Synchronizacja była przed chwilą. Spróbuj za {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Na razie żadnych imion."
L.EMPTY_WANTED_SUB = "Wyjdź w końcu z domu."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  otwórz/zamknij księgę"
L.HELP_ADD = "/dn add <Imię [Nazwisko]>  wpisz zabójcę do księgi ręcznie"
L.HELP_DEL = "/dn del <Imię [Nazwisko]>  wykreśl zabójcę z księgi"
L.HELP_QUIET = "/dn quiet  alarm wył./wł."
L.HELP_TEST = "/dn test  pokaż próbny alarm"
L.HELP_GUILD = "/dn guild  księga gildii: stan i kto z gildii ma DeathNote"
L.HELP_FRIENDS = "/dn friends  księga znajomych: stan i którzy znajomi mają DeathNote"
L.HELP_SYNC = "/dn sync  zsynchronizuj teraz księgę gildii i księgę znajomych"
L.HELP_HUNT = "/dn hunt <Imię [Nazwisko]>  ogłoś polowanie (bez imienia: pokaż listę do odstrzału)"
L.HELP_CALLOFF = "/dn calloff <Imię [Nazwisko]>  odwołaj własne zgłoszenie"
L.HELP_LANG = "/dn lang <kod>  język księgi (enUS, deDE, plPL ...), po /reload"
L.HELP_THEME = "/dn theme <nazwa>  okładka księgi, po /reload"
L.HELP_PROBE = "/dn probe  diagnostyka: co gra mówi księdze"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  diagnostyka, do tego test dziennika walki"
L.HELP_DEBUG = "/dn debug  diagnostyka: zapisuj szczegółowo każdy zgon (wł./wył.)"
L.HELP_HELP = "/dn help  ta pomoc"
L.HELP_SILENT_ZONES = "W lochach, na polach bitew i na arenach księga sama milczy."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "wł."
L.WORD_OFF = "wył."
L.CHAT_WHO_ADD = "Kogo? /dn add <Imię>"
L.CHAT_WHO_DEL = "Kogo? /dn del <Imię>"
L.CHAT_WHO_CALLOFF = "Kogo? /dn calloff <Imię>"
L.CHAT_BAD_NAME = "Nieprawidłowe imię."
L.CHAT_NOT_IN_BOOK = "Nie ma w księdze: {name}"
L.CHAT_ALARM_ON = "Alarm włączony."
L.CHAT_ALARM_OFF = "Alarm wyłączony."
L.CHAT_DEBUG = "Zapis diagnostyczny: {state}"
L.CHAT_UNKNOWN_CMD = "Nieznane polecenie. Pomoc: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Księga gildii nie jest wczytana."
L.CHAT_NO_GUILD = "Nie masz gildii (albo gra jeszcze o niej nie wie)."
L.CHAT_GUILD_STATE = "Gildia {guild}: udostępnianie {share}, odbiór {receive}"
L.CHAT_GUILD_BOOK = "Księga gildii. Zabójcy: {enemies} (tylko ręcznie: {listed}), czyny: {deeds}, z ofiarami w gildii: {foreign}. Udostępnianie wpisów ręcznych: {manual}"
L.CHAT_STATE_OK = "Stan: {text}"
L.CHAT_STATE_WARN = "Uwaga: {text}"
L.CHAT_NO_MATES = "Na razie nikt z gildii z DeathNote się nie odezwał."
L.CHAT_HAVE_DN = "Mają DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Mają DeathNote: {names} i jeszcze {count}"
L.CHAT_SYNC_ASKED = "Wysłano prośbę o synchronizację. Odpowiedzi przyjdą w ciągu kilku sekund."
L.CHAT_SYNC_FAIL = "Synchronizacja nie działa: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "brak gildii albo udostępnianie wyłączone."
L.CHAT_FRIENDS_NOT_LOADED = "Księga znajomych nie jest wczytana."
L.CHAT_FRIENDS_STATE = "Znajomi: udostępnianie {share}, online {online} z {total}."
L.CHAT_FRIENDS_BOOK = "Księga znajomych. Zabójcy: {enemies} (tylko ręcznie: {listed}), czyny: {deeds}."
L.CHAT_NO_FRIENDS = "Na razie żaden znajomy z DeathNote się nie odezwał."
L.CHAT_HUNT_NOT_LOADED = "Lista do odstrzału nie jest wczytana."
L.CHAT_HUNT_UNKNOWN = "Nieznany gracz: {name}. Podaj też nazwisko, tak jak imię wygląda w grze."
L.CHAT_HUNT_CAP = "Nie można ogłosić polowania: najwyżej {own} własnych zgłoszeń i {targets} celów na listę."
L.CHAT_HUNT_NOWHERE = "Teraz nie można ogłosić polowania: brak gildii, a udostępnianie znajomym jest wyłączone."
L.CHAT_HUNT_BOTH = "{name}: polowanie ogłoszone dla gildii i znajomych."
L.CHAT_HUNT_GUILD = "{name}: polowanie ogłoszone dla gildii."
L.CHAT_HUNT_FRIENDS = "{name}: polowanie ogłoszone dla twoich znajomych."
L.CHAT_CALLED_OFF = "{name}: polowanie odwołane."
L.CHAT_NO_OWN_CALL = "{name}: nie masz tu własnego zgłoszenia."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Język teraz: {lang}. Zmiana: /dn lang <kod>"
L.CHAT_LANG_LIST = "Kody: {codes}"
L.CHAT_LANG_BAD = "Nieznany język: {code}"
L.CHAT_LANG_SET = "Język: {lang}."
L.CHAT_LANG_RELOAD = "Język: {lang}. Zadziała po /reload."
L.CHAT_THEME_CURRENT = "Okładka teraz: {theme}. Zmiana: /dn theme <nazwa>"
L.CHAT_THEME_LIST = "Okładki: {themes}"
L.CHAT_THEME_BAD = "Nieznana okładka: {name}"
L.CHAT_THEME_SET = "Okładka: {theme}."
L.CHAT_THEME_RELOAD = "Okładka: {theme}. Zadziała po /reload."
L.THEME_NOTEBOOK = "Czarna księga"
L.THEME_HARBOR = "Privateer's Ledger"  -- TODO translate (English placeholder)
L.THEME_TRADE = "The Workshop"  -- TODO translate (English placeholder)

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Księga gotowa. Kto zabije cię w otwartym świecie, trafi do niej. Otwórz ją przez /dn albo przycisk przy minimapie."
L.WELCOME_PLATES = "Plakietki wrogów są wyłączone. Bez nich alarm widzi tylko twój cel."
L.WELCOME_SHARE = "Gildia i znajomi, którzy mają DeathNote, czytają razem z tobą. Notatki i podejrzenia zostają u ciebie."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "W KSIĘDZE:"
L.TIP_HUNT = "DO ODSTRZAŁU:"
L.TIP_GUILDBOOK = "KSIĘGA GILDII:"
L.TIP_PARDONED = "ułaskawiono"
L.TIP_RANK = "miejsce {rank}"
L.TIP_REVENGE = "zemsta {times}"
L.TIP_LISTED_BY = "w księgach: {names}"
L.TIP_NOTE = "Notatka: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Klik: otwórz · Prawy klik: schowaj"
L.BANNER_NEW = "NOWY WPIS"  -- [max 24]
L.BANNER_NEW_LINE = "teraz w księdze"
L.BANNER_AGAIN = "ZNOWU"  -- [max 24]
L.BANNER_AGAIN_LINE = "znowu twój zgon, już {count}. raz"
L.BANNER_SUSPECT = "PODEJRZENIE"  -- [max 24]
L.BANNER_SUSPECT_LINE = "pod podejrzeniem, wyjaśnij w księdze"
L.BANNER_UNCLEAR = "SPRAWCA NIEZNANY"  -- [max 24]
L.BANNER_CANDIDATES = "{count} {count|kandydat|kandydatów|kandydatów}"
L.BANNER_UNCLEAR_LINE = "Klik: wskaż zabójcę w Niejasnych"
L.BANNER_REVENGE = "ODWET"  -- [max 24]
L.BANNER_REVENGE_LINE = "Zemsta dokonana ({count}×)"
L.BANNER_GUILD = "GILDIA"  -- [max 24]
L.BANNER_FRIENDS = "ZNAJOMI"  -- [max 24]
L.BANNER_KILLED_BY = "zabójca: {name}"
L.BANNER_HUNT = "LISTA DO ODSTRZAŁU"  -- [max 24]
L.BANNER_BAGGED = "ostatni cios: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Udostępnianie jest wyłączone (Regulamin, karta Gildia)."
L.SYNC_FRIENDS_OFF = "Udostępnianie znajomym jest wyłączone."
L.SYNC_NOBODY = "Ani gildii, ani znajomych do udostępniania."
L.SYNC_SHORT_NOBODY = "Bez udostępniania"  -- [max 18]
L.SYNC_PREFIX = "Gra nie pozwala na odbiór. Pomoże ponowne zalogowanie."
L.SYNC_SHORT_PREFIX = "Odbiór nie działa"  -- [max 18]
L.SYNC_BLOCKED = "Serwer blokuje wysyłanie. Przekaż księgę przez Zapisz księgę."
L.SYNC_SHORT_BLOCKED = "Serwer blokuje wysyłkę"  -- [max 22]
L.SYNC_FAILING = "Wysyłanie teraz nie działa, próbujemy ponownie."
L.SYNC_SHORT_FAILING = "Wysyłanie się tnie"  -- [max 18]
L.SYNC_HOLD = "Wysyłanie czeka, {wait}."
L.SYNC_HOLD_INSTANCE = "aż opuścisz instancję"
L.SYNC_HOLD_COMBAT = "aż skończysz walkę"
L.SYNC_HOLD_LOCKDOWN = "aż czat znów będzie wolny"
L.SYNC_HOLD_AGAIN = "aż znów zadziała"
L.SYNC_HOLD_SHORT_INSTANCE = "Czeka: instancja"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Czeka: walka"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Czeka: czat"  -- [max 18]
L.SYNC_QUIET = "Wysłano, ale nikt z gildii z DeathNote się jeszcze nie odezwał."
L.SYNC_READY = "Gotowe. Nikt z gildii z DeathNote się jeszcze nie odezwał."
L.SYNC_RUNNING = "Działa: DeathNote u {count} {count|osoby|osób|osób} z gildii."
L.SYNC_RUNNING_ALL = "Działa. Z DeathNote w gildii i wśród znajomych: {count}."
L.FRIENDS_OFF = "Udostępnianie znajomym jest wyłączone (Regulamin, karta Gildia)."
L.FRIENDS_BLOCKED = "Serwer blokuje szepty. Znajomi nic nie dostaną."
L.FRIENDS_SHORT_BLOCKED = "Serwer blokuje szepty"  -- [max 22]
L.FRIENDS_FAILING = "Szepty teraz nie przechodzą, próbujemy ponownie."
L.FRIENDS_SHORT_FAILING = "Szepty się tną"  -- [max 18]
L.FRIENDS_NONE_LISTED = "Brak znajomych na liście znajomych."
L.FRIENDS_NONE_ONLINE = "Żadnego znajomego nie ma teraz online."
L.FRIENDS_SHORT_NONE_ONLINE = "Znajomi offline"  -- [max 18]
L.FRIENDS_QUIET = "Zapytano, ale żaden znajomy z DeathNote się jeszcze nie odezwał."
L.FRIENDS_READY = "Gotowe. Żaden znajomy z DeathNote się jeszcze nie odezwał."
L.FRIENDS_HOLD = "Wysyłanie do znajomych czeka, aż znów zadziała."
L.FRIENDS_RUNNING = "Działa: {count} {count|znajomy|znajomych|znajomych} z DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Przejęte z księgi gildii (ofiary w gildii: {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Baza danych nie jest wczytana."
L.IMPORT_NO_TEXT = "Brak tekstu."
L.IMPORT_NO_HEADER = "Brakuje pierwszej linii (zaczyna się od {header}). Skopiuj cały tekst."
L.IMPORT_NOT_EXPORT = "To nie jest eksport DeathNote (brak linii nagłówka albo zła wersja)."
L.IMPORT_TOO_LONG = "Za dużo linii (najwyżej {count})."
L.IMPORT_BAD_KEY = "Linia {line}: nieprawidłowy klucz."
L.IMPORT_BAD_TIME = "Linia {line}: nieprawidłowy czas."
L.IMPORT_BROKEN = "Linia {line} jest niepełna albo uszkodzona (ucięty tekst?). Nic nie wczytano."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "tak"
L.WORD_NO = "nie"
L.PROBE_HEAD = "Sonda: interfejsy {apis}/{apisAll} dostępne, zdarzenia {events}/{eventsAll} do zarejestrowania."
L.PROBE_MISSING = "Brakuje: {list}"
L.PROBE_NOT_REGISTERABLE = "Nie do zarejestrowania: {list}"
L.PROBE_SOURCES = "Recap teraz: {recap} · Meter: {meter} · Dziennik walki: {clog}"
L.PROBE_READABLE = "czytelny"
L.PROBE_DEAD = "martwy"
L.PROBE_PLATES = "Plakietki wrogów: {plates} · Otwarty świat: {open}"
L.PROBE_PLATES_OFF = "WYŁ. (graczy widać tylko przez cel i kursor)"
L.PROBE_TARGET = "Cel: imię={name} GUID={guid} klasa={class} wrogi={enemy} celuje we mnie={me}"
L.PROBE_GUILD = "Gildia: prefiks {prefix} · wysyłanie {send} · ostatni kod zwrotny {result} · wysłano {sent}, odebrano {received}, odrzucono {dropped}"
L.PROBE_REGISTERED = "zarejestrowany"
L.PROBE_NOT_REGISTERED = "NIE zarejestrowany ({result})"
L.PROBE_POSSIBLE = "możliwe"
L.PROBE_ABSENT = "brak"
L.PROBE_WAITS = " · czeka: {why}"
L.PROBE_LISTED = "Wpisy ręczne (M): wysłano {sent}, odebrano {received}, odrzucono {dropped} · wykreślone (X): wysłano {usent}, odebrano {ureceived}, odrzucono {udropped}"
L.PROBE_GUILDBOOK = "Księga gildii: {text}"
L.PROBE_SAVED = "Zapisano w DeathNoteDB.probe (w pliku po /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Ranking"  -- [max 14]
L.SORT_RECENT = "Najnowsze"  -- [max 14]
L.SORT_NAME = "Imię"  -- [max 14]
L.SORT_SEEN = "Widziano"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Kto zabije cię w otwartym świecie, trafi tutaj. Samo z siebie."
L.EMPTY_OPEN_HEAD = "Nic do wyjaśnienia."
L.EMPTY_JOURNAL_HEAD = "Ani jednego zgonu."
L.EMPTY_JOURNAL_SUB = "Szacunek. Albo kłamstwo."
L.EMPTY_NOGUILD_HEAD = "Brak gildii."
L.EMPTY_NOGUILD_SUB = "W pojedynkę też da się umierać."
L.EMPTY_GUILDOFF_HEAD = "Księga gildii jest zamknięta."
L.EMPTY_GUILDOFF_SUB = "Udostępnianie jest wyłączone. Regulamin wie, gdzie."
L.EMPTY_GUILDNIL_HEAD = "Z gildii na razie cisza."
L.EMPTY_GUILDNIL_SUB = "Twoja księga pójdzie dalej, gdy ktoś z gildii będzie miał DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "W księdze gildii jeszcze nic nie ma."
L.EMPTY_GUILDQUIET_SUB = "Twoja gildia miała dotąd spokój."
L.EMPTY_FRIENDSOFF_HEAD = "Księga znajomych jest zamknięta."
L.EMPTY_FRIENDSOFF_SUB = "Udostępnianie znajomym jest wyłączone. Regulamin wie, gdzie."
L.EMPTY_FRIENDSNIL_HEAD = "Żaden znajomy z DeathNote się jeszcze nie odezwał."
L.EMPTY_FRIENDSNIL_SUB = "Twoja księga pójdzie dalej, gdy któryś znajomy będzie miał DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Od znajomych jeszcze nic."
L.EMPTY_FRIENDSQUIET_SUB = "Twoi znajomi mieli dotąd spokój."
L.EMPTY_NOBODY_HEAD = "Ani gildii, ani znajomych."
L.EMPTY_NOBODY_SUB = "W pojedynkę też da się umierać."
L.EMPTY_NOBODY_HINT = "Gdy ludzie z gildii albo znajomi z listy znajomych będą mieli DeathNote, zobaczysz tu, co się z nimi dzieje."
L.EMPTY_SHAREDNIL_HEAD = "Na razie nikt z DeathNote się nie odezwał."
L.EMPTY_SHAREDNIL_SUB = "Twoja księga pójdzie dalej, gdy ktoś z gildii albo znajomych będzie miał DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Tu jeszcze nic nie ma."
L.EMPTY_SHAREDQUIET_SUB = "Gildia i znajomi mieli dotąd spokój."
L.EMPTY_HUNT_HEAD = "Lista do odstrzału jest pusta."
L.EMPTY_HUNT_SUB = "Na liście gończym: Ogłoś polowanie."
L.EMPTY_HUNT_HINT = "Albo na czacie: /dn hunt Imię Nazwisko. Zobaczy to cała twoja gildia i twoi znajomi."
L.EMPTY_SEARCH_HEAD = "Brak wyników."
L.EMPTY_SEARCH_SUB = "Enter wpisuje imię do księgi."
L.EMPTY_SEARCHRO_HEAD = "Brak wyników."
L.EMPTY_SEARCHRO_SUB = "Czasem pomaga inna pisownia."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "KSIĘGA"  -- [max 12]
L.MANUAL_BOOK = "Kto zabije cię w otwartym świecie, trafia do księgi automatycznie. Klik w komunikat po zgonie otwiera stronę zabójcy."
L.MANUAL_WANTED_HEAD = "POSZUKIWANI"  -- [max 12]
L.MANUAL_WANTED = "Twoi zabójcy, najgorsi na górze. Klik pokazuje list gończy z czynami i notatką. Ułaskawieni są na końcu, przekreśleni."
L.MANUAL_UNSOLVED_HEAD = "NIEWYJAŚNIONE"  -- [max 13]
L.MANUAL_UNSOLVED = "Gdy nie wiadomo, kto to zrobił, sprawa czeka tutaj. Klik w imię wskazuje zabójcę."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Gdy zabójca pojawi się jako plakietka, cel albo pod kursorem, księga daje znać. Klik bierze go na cel, w walce dopiero po niej."
L.MANUAL_ADD_HEAD = "WPISYWANIE"  -- [max 12]
L.MANUAL_ADD = "Wpisz imię w pole wyszukiwania, Enter. Prawy klik na wierszu: zanotuj zemstę, ułaskaw, wykreśl."
L.MANUAL_GUILD_HEAD = "GILDIA"  -- [max 12]
L.MANUAL_GUILD = "Ludzie z gildii i znajomi, którzy mają DeathNote, widzą twoje potwierdzone zgony i wpisy ręczne. List gończy albo /dn hunt Imię: ogłoś polowanie. Klik w nagrodę: wyznacz własną, to obietnica rozliczana między wami."
L.MANUAL_SHARE_HEAD = "PRZEKAŻ"  -- [max 12]
L.MANUAL_SHARE = "Regulamin, Zapisz księgę: tekst do skopiowania, dla wszystkich bez DeathNote."
L.MANUAL_QUIET_HEAD = "CISZA"  -- [max 12]
L.MANUAL_QUIET = "W lochach i na polach bitew alarm milczy. Poza tym: środkowy klik na przycisk przy minimapie albo /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Na pewno wykreślić z księgi: {name}?\nWszystkie czyny i notatka przepadną."
L.CONFIRM_DELETE_OK = "Wykreśl"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Wyczyścić księgę gildii na tym komputerze?\nJej lista do odstrzału też zniknie, twoje zgłoszenia zostaną.\nTwoja własna księga zostanie bez zmian."
L.CONFIRM_GUILD_CLEAR_OK = "Wyczyść"  -- [max 14]
L.CONFIRM_CANCEL = "Anuluj"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ZŁOTA"  -- [max 14]
L.BOUNTY_SILVER = "{count} SREBRA"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Potwierdź"  -- [max 19]
L.ACT_DISMISS = "Odrzuć"  -- [max 19]
L.ACT_HUNT_AGAIN = "Znów ścigaj"  -- [max 19]
L.ACT_REVENGE = "Zanotuj zemstę"  -- [max 19]
L.ACT_PARDON = "Ułaskaw"  -- [max 19]
L.ACT_STRIKE = "Wykreśl"  -- [max 19]
L.ACT_OPEN_OWN = "Otwórz w księdze"  -- [max 19]
L.ACT_ADOPT = "Do mojej księgi"  -- [max 19]
L.ACT_CALLOFF = "Odwołaj polowanie"  -- [max 19]
L.ACT_RELEASE = "Ogłoś polowanie"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "widziano {time}"
L.ROW_NOT_SEEN = "jeszcze nie widziano"
L.ROW_PARDONED = "ułaskawiono"
L.ROW_SUSPECT = "Podejrzenie"
L.MARK_REVENGE = "ZEMSTA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Sprawca nieznany"
L.MARK_CANDIDATES = "{count} {count|KANDYDAT|KANDYDATÓW|KANDYDATÓW}"  -- [max 16]
L.MARK_SUSPECT = "PODEJRZENIE"  -- [max 16]
L.ROW_NO_PLAYER = "Nie gracz"
L.ROW_UNCLEAR = "Nie wiadomo jak"
L.MARK_NOT_COUNTED = "NIE LICZY SIĘ"  -- [max 16]
L.ROW_LISTED_BY = "kto wpisał: {names}"
L.ROW_GKILLED = "zabójstwa: {kills}×"
L.ROW_VICTIMS = "{count} {count|ofiara|ofiary|ofiar}"
L.ROW_LAST = "ostatnio: {text}"
L.MARK_IN_BOOK = "W KSIĘDZE"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|zabójca|zabójców|zabójców}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|zgon|zgony|zgonów}"  -- [max 12]
L.MEMBER_LISTED = "{count} ręcznie"  -- [max 14]
L.MEMBER_ME = "co inni widzą o tobie"
L.MEMBER_NOTHING = "jeszcze nic nie udostępniono"
L.MEMBER_LAST_DIED = "ostatni zgon {time}"
L.MARK_YOU = "ty"  -- [max 16]
L.MARK_FRIEND = "ZNAJOMY"  -- [max 16]
L.MARK_BOTH = "Z GILDII, ZNAJOMY"  -- [max 20]
L.MARK_TAKEN_DOWN = "UPOLOWANO {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ŻYWY LUB MARTWY"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "CZYNY"  -- [max 14]
L.POSTER_NOTE = "NOTATKA"  -- [max 8]
L.POSTER_BOUNTY = "NAGRODA"  -- [max 12]
L.ROLE_ASSIST = "udział"  -- [max 14]
L.ROLE_SUSPECT = "podejrzenie"  -- [max 14]
L.POSTER_LEVEL = "Poziom {level}"
L.POSTER_GUILD = "Gildia: {guild}"
L.POSTER_LAST_SEEN = "Ostatnio widziano {time}"
L.POSTER_NOT_SEEN = "Jeszcze nie widziano"
L.POSTER_ONLY_SUSPECT = "Tylko podejrzenie, żadnego udowodnionego czynu."
L.POSTER_NO_DEEDS = "Brak zapisanych czynów."
L.TIP_LISTED_AT = "Wpisano {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Przyczyna zgonu: {spell}"
L.TIP_VICTIM = "Ofiara: {name}"
L.TIP_VICTIM_LEVEL = "Ofiara: {name} (poziom {level})"
L.TIP_KILLER_LEVEL = "Poziom zabójcy: {level}"
L.TIP_ASSISTS = "Udział: {names}"
L.TIP_ROLE_ASSIST = "Udział bez ostatniego ciosu."
L.TIP_ROLE_SUSPECT = "Tylko podejrzenie, bez dowodu."
L.MORE_LINE = "… i jeszcze {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "KSIĘGA GILDII"  -- [max 24]
L.POSTER_IN_BOOK_OF = "W księgach: {names}"
L.POSTER_SEEN = "Widziano {time}"
L.POSTER_SEEN_BY = "Widziano {time}, zgłasza: {name}"
L.TIP_IN_BOOK_OF = "W księgach"
L.POSTER_REMARK = "ADNOTACJA"  -- [max 12]
L.POSTER_BY_HAND = "WPISANO RĘCZNIE"  -- [max 22]
L.POSTER_VICTIMS = "OFIARY"  -- [max 12]
L.POSTER_LISTED = "WPISALI"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Wpisano ręcznie."
L.POSTER_NO_DEEDS_SENT = "Nie przekazano czynów."
L.POSTER_NONE_KNOWN = "brak znanych"
L.POSTER_NO_NAMES = "nie przekazano imion"
L.TIP_VICTIMS = "Ofiary"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Zgłoszono {time}"
L.HUNT_REASON = "Powód: {reason}"
L.POSTER_HUNTLIST = "LISTA DO ODSTRZAŁU"  -- [max 24]
L.POSTER_RELEASED_N = "polowanie ogłoszone {times}"
L.POSTER_RELEASED_BY = "Kto zgłosił: {names}"
L.POSTER_TAKEN_DOWN = "UPOLOWANO"  -- [max 12]
L.POSTER_NOT_YET = "JESZCZE NIE"  -- [max 18]
L.POSTER_CALLS = "ZGŁOSZENIA"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Już nikt."
L.POSTER_LAST = "OSTATNIO"  -- [max 13]
L.POSTER_TAKEN_BY = "ostatni cios: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "jeszcze nikt nie upolował"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Zgon"  -- [max 20]
L.CASE_ASSISTS = "UDZIAŁ"  -- [max 24]
L.CASE_PICK = "WSKAŻ ZABÓJCĘ"  -- [max 24]
L.CASE_NOT_COUNTED = "Nie liczy się (instancja, pole bitwy albo pojedynek)"
L.CASE_KILLER = "ZABÓJCA"  -- [max 24]
L.CASE_KILLER_SUSPECT = "ZABÓJCA (PODEJRZENIE)"  -- [max 24]
L.CASE_CLICK_NAME = "Klik w imię otwiera list gończy."
L.CASE_GONE = "Nie ma już w księdze."
L.CASE_KILLER_UNCLEAR = "SPRAWCA NIEZNANY"  -- [max 24]
L.CASE_SEVERAL = "Podejrzanych jest kilku. Czyje imię trafi do księgi?"
L.CASE_NOBODY = "Nikt nie wchodzi w grę."
L.CASE_HOW = "CO SIĘ STAŁO"  -- [max 24]
L.CASE_PVE = "Potwór albo sam świat. To nie sprawa dla księgi."
L.CASE_UNCLEAR = "Niejasne"
L.CASE_DARK = "Śledczy błądzą po omacku."
L.TIP_MORE_CANDIDATES = "Pozostali kandydaci"
L.CASE_SOURCE_SUSPECT = "Podejrzenie: ten gracz miał cię na celowniku tuż przed zgonem."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Wiersz w podpowiedzi przy zabójcach"  -- [max 44]
L.OPT_MINIMAP = "Przycisk przy minimapie"  -- [max 44]
L.OPT_ALERT = "Alarm, gdy pojawi się zabójca"  -- [max 44]
L.OPT_FLASH = "Błysk czerwonej krawędzi ekranu"  -- [max 44]
L.OPT_SUSPECTS = "Zgłaszaj też podejrzanych"  -- [max 44]
L.OPT_DEATHMSG = "Komunikat po zgonie w PvP"  -- [max 44]
L.OPT_G_SHARE = "Udostępniaj moje zgony"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Udostępniaj wpisy ręczne"  -- [max 44]
L.OPT_G_RECEIVE = "Odbieraj księgę gildii"  -- [max 44]
L.OPT_G_ALERT = "Ostrzegaj przed zabójcami z księgi gildii"  -- [max 44]
L.OPT_G_ALERTLISTED = "Ostrzegaj też przed wpisami ręcznymi"  -- [max 44]
L.OPT_G_ANNOUNCE = "Zgłaszaj, gdy zginie ktoś z gildii"  -- [max 44]
L.OPT_G_SIGHTINGS = "Udostępniaj obserwacje"  -- [max 44]
L.OPT_F_SHARE = "Udostępniaj gildii"  -- [max 44]
L.OPT_F_FRIENDS = "Udostępniaj znajomym"  -- [max 44]
L.OPT_F_ALERT = "Ostrzegaj przed zabójcami gildii i znajomych"  -- [max 44]
L.OPT_F_ALERTHUNT = "Ostrzegaj przed celami z listy do odstrzału"  -- [max 44]
L.OPT_F_ANNOUNCE = "Zgłaszaj zgony w gildii i wśród znajomych"  -- [max 44]
L.OPT_F_SIGHTINGS = "Udostępniaj obserwacje gildii i znajomym"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Gildia"  -- [max 14]
L.SET_BOOK_SIZE = "Rozmiar księgi"  -- [max 34]
L.SET_LANGUAGE = "Język"  -- [max 16]
L.SET_LANG_AUTO = "Automatycznie"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Zadziała po przeładowaniu."  -- [max 28]
L.SET_LANG_RELOAD = "Przeładuj teraz"  -- [max 22]
L.SET_SEC_SHARE = "PRZEKAŻ"  -- [max 24]
L.IO_EXPORT = "Zapisz księgę"  -- [max 17]
L.IO_IMPORT = "Wczytaj księgę"  -- [max 17]
L.SET_HINT_BOOK = "Zapis daje ci księgę jako tekst: do przechowania albo przekazania osobom spoza gildii. Wczytanie scala i niczego nie nadpisuje."
L.SET_SEC_SOUND = "DŹWIĘK"  -- [max 24]
L.SET_SOUND = "Dźwięk"  -- [max 22]
L.SET_VOLUME = "Głośność"  -- [max 22]
L.SET_CHANNEL = "Kanał"  -- [max 12]
L.SET_SEC_THRESHOLD = "PRÓG"  -- [max 24]
L.SET_COOLDOWN = "Przerwa dla każdego zabójcy"  -- [max 34]
L.SET_MINKILLS = "Alarm od tylu zgonów z jego ręki"  -- [max 34]
L.SET_ALERT_SIZE = "Rozmiar alarmu"  -- [max 34]
L.SET_TEST_ALERT = "Próbny alarm"  -- [max 17]
L.SET_G_MINKILLS = "Ostrzeżenie gildii od tylu zgonów"  -- [max 34]
L.SET_F_MINKILLS = "Ostrzeżenie od tylu zgonów"  -- [max 34]
L.SET_SEC_STATUS = "STAN"  -- [max 24]
L.SET_SEC_SHARING = "UDOSTĘPNIANIE"
L.SET_SEC_WARN = "ALARM"
L.SET_MORE = "Więcej"
L.SET_GUILD_CLEAR = "Wyczyść księgę gildii"  -- [max 26]
L.SET_HINT_GUILD = "Dostaje to tylko twoja gildia. To, co stamtąd przychodzi, jest trzymane osobno od twojej księgi, dopóki tego nie przejmiesz."
L.SET_HINT_FRIENDS = "Dostają to tylko gildia i znajomi z DeathNote."
L.BTN_BACK = "Wstecz"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synchronizuj"  -- [max 14]
L.SYNC_AGAIN_IN = "znów za {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Znajomi"
L.TIP_GUILD_NAME = "Gildia {guild}"
L.TIP_MATES_WITH = "Z gildii z DeathNote:"
L.TIP_NO_MATE = "Na razie nikt z gildii z DeathNote się nie odezwał."
L.TIP_FRIENDS_WITH = "Znajomi z DeathNote:"
L.TIP_SHARED = "Udostępniane: twoje potwierdzone zgony, wpisy ręczne i twoje zgłoszenia polowań."
L.TIP_NOT_SHARED = "Nieudostępniane: notatki, podejrzenia, ułaskawieni, wpisy wczytane."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Wczytaj"  -- [max 17]
L.IO_DONE = "Wczytano. Nowe: {new}, scalone: {merged}."
L.IO_FAILED = "Nie udało się."
L.IO_SMALL = "Tylko skrót"  -- [max 17]
L.IO_ALL = "Pokaż wszystko"  -- [max 17]
L.IO_MSG_FULL = "Cała księga z czynami ({size})."
L.IO_MSG_SHORT = "Tylko imiona i liczniki ({size}). Z czynami: {full}."
L.IO_MSG_BIG = "Duża księga ({size}): zaznaczanie i kopiowanie chwilę potrwają."
L.IO_HELP_EXPORT = "Tekst jest zaznaczony: Ctrl+C go kopiuje. Zachowaj go albo przekaż znajomym."
L.IO_HELP_IMPORT = "Wklej zapisany tekst przez Ctrl+V, potem Wczytaj. Nic nie zostanie nadpisane."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Powód zobaczy cała twoja gildia i twoi znajomi z DeathNote."
L.REL_HINT_GUILD = "Powód zobaczy cała twoja gildia z DeathNote."
L.REL_HINT_FRIENDS = "Powód zobaczą twoi znajomi z DeathNote."
L.REL_HEAD = "Ogłoś polowanie"  -- [max 24]
L.REL_FOR = "DLA"  -- [max 6]
L.REL_REASON = "POWÓD"  -- [max 8]
L.REL_HINT2 = "Twoja notatka zostaje u ciebie. Własne zgłoszenie możesz odwołać tylko ty."
L.REL_GO = "Ogłoś polowanie"  -- [max 17]
L.REL_NONE = "Brak gildii, a udostępnianie znajomym jest wyłączone."
L.REL_CAP = "Najwyżej {own} własnych zgłoszeń i {max} celów na listę."
L.REL_FAILED = "Teraz nie można ogłosić polowania."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Bez dźwięku: alarm tylko się pokazuje."
L.SET_HINT_BUILTIN = "Głośność tego dźwięku zależy od kanału w ustawieniach gry."
L.SET_HINT_LEVELS = "Pięć poziomów, od cicho do głośno. Do tego działa suwak kanału w ustawieniach gry."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Gildia i znajomi"  -- [max 18]
L.TIP_HELP_BUTTON = "Jak działa księga"
L.VIEW_HUNT = "Do odstrzału"  -- [max 13]
L.VIEW_BY_KILLER = "Wg zabójców"  -- [max 13]
L.VIEW_BY_MATE = "Wg ofiar"  -- [max 13]
L.SRC_ALL = "Wszyscy"  -- [max 12]
L.SRC_GUILD = "Gildia"  -- [max 12]
L.SRC_FRIENDS = "Znajomi"  -- [max 12]
L.SORT_HIDE_PARDONED = "Ukryj ułaskawionych"  -- [max 24]
L.SORT_SHOW_PARDONED = "Pokaż ułaskawionych"  -- [max 24]
L.SEARCH_ADD = "Szukaj lub wpisz …"  -- [max 26]
L.SEARCH_SHORT = "Szukaj …"  -- [max 10]
L.SEARCH_KILLER = "Zabójca …"  -- [max 15]
L.SEARCH_JOURNAL = "Zabójca lub miejsce …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Zwiń wszystko"
L.TIP_EXPAND_ALL = "Rozwiń wszystko"
L.STATUS_NO_PLATES = "Plakietki wrogów są wyłączone: alarm widzi tylko cel i kursor."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "Poszukiwani: {count}"
L.MM_UNSOLVED = "Niejasne: {count}"
L.MM_ALERT_OFF = "Alarm wyłączony (środkowy klik)"
L.MM_CLICK = "Klik: księga · Prawy klik: Regulamin"
L.MM_MIDDLE = "Środkowy klik: alarm wł./wył."
L.MM_DRAG = "Przeciągnij: przesuń po krawędzi minimapy"
L.MM_CHAT_ALERT_ON = "Alarm włączony."
L.MM_CHAT_ALERT_OFF = "Alarm wyłączony."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "WRÓG GILDII NR 1"  -- [max 25]
L.STAMP_HUNT = "POLOWANIE OTWARTE"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} podaje się za twojego znajomego {friend}: odrzucono."
L.FRIENDS_SHORT_IMPOSTOR = "Obcego odrzucono"  -- [max 22]
L.ALERT_LEVEL = "Poziom {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "ostatnio poziom {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Poziom ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · na liście do odstrzału ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nowy cel|nowe cele|nowych celów}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nowe na liście do odstrzału"
L.OPT_F_ANNOUNCEHUNT = "Zgłaszaj nowe i upolowane cele z listy"  -- [max 44]
L.SET_HUNT_EXPIRE = "Zgłoszenia wygasają po"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nigdy"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dzień|dni|dni}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Wyczyść księgę znajomych"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Wyczyścić księgę znajomych na tym komputerze?\nJej lista do odstrzału też zniknie, twoje zgłoszenia zostaną."
L.CONFIRM_CALLOFF_ALL = "Odwołać wszystkie twoje zgłoszenia?\nGildia i znajomi dowiedzą się o tym stopniowo."
L.CONFIRM_CALLOFF_ALL_OK = "Odwołaj je"  -- [max 14]
L.ACT_CALLOFF_ALL = "Odwołaj wszystkie moje"  -- [max 24]
L.ACT_HUNT_HIDE = "Ukryj u mnie"  -- [max 19]
L.ACT_HUNT_SHOW = "Pokaż ponownie"  -- [max 19]
L.HUNT_ROW_HIDDEN = "ukryte dla ciebie"
L.HUNT_ROW_CALLS = "{count} {count|zgłoszenie|zgłoszenia|zgłoszeń}: {names}"
L.POSTER_ON_HUNTLIST = "Na liście do odstrzału ({names})"
L.REL_SELF = "Nie możesz ogłosić polowania na siebie."
L.REL_MATE = "To ktoś swój (gildia albo znajomi z DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Kto jest twoim znajomym {friend}: {a} czy {b}? Wybierz."
L.FRIENDS_SHORT_CONFLICT = "Znajomy niepewny"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Dwóch graczy podaje się za twojego znajomego {friend}: {a} i {b}. Dopóki nie wybierzesz, księga nie przyjmuje niczego od żadnego z nich. Gildia i znajomi, widok Wg ofiar: prawy klik na nazwie."
L.MEMBER_CONFLICT = "Prawy klik: czy to twój znajomy?"  -- [max 40]
L.ACT_TIE_MINE = "Mój znajomy: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Odłącz imię"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Odłączyć {name} od listy znajomych?\nTo, co ta postać wniosła do księgi znajomych, zostanie usunięte; następna wiadomość pod tym imieniem połączy na nowo."
L.CHAT_FRIENDS_TIES = "Połączone pełne nazwy (* = pierwszy kontakt, jeszcze niepotwierdzone): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Imię [Nazwisko]> <złoto>  wyznacz własną nagrodę (bez kwoty: wycofaj)"
L.CHAT_WHO_BOUNTY = "Za kogo? /dn bounty <Imię> <złoto>"
L.CHAT_BOUNTY_SET = "{name}: wyznaczasz nagrodę {gold}g. Gildia i znajomi z DeathNote ją widzą."
L.CHAT_BOUNTY_OFF = "{name}: twoja nagroda wycofana."
L.CHAT_BOUNTY_NONE = "{name}: nie masz tu własnej nagrody."
L.CHAT_BOUNTY_BAD = "Nagroda: liczba całkowita złota, od 1 do 99999 (0 wycofuje)."
L.CHAT_BOUNTY_CAP = "Bez nagrody: najwyżej {count} własnych."
L.CHAT_BOUNTY_OURS = "Nie wyznaczysz nagrody za siebie ani za swoich (gildia albo znajomi z DeathNote)."
L.ACT_BOUNTY = "Wyznacz nagrodę"  -- [max 24]
L.ACT_UNDO = "Cofnij"  -- [max 19]
L.ACT_REVENGE_TAKE = "Odejmij jedną zemstę"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, wyznaczona przez ciebie"
L.POSTER_BOUNTY_BY = "{gold}, wyznacza: {name}"
L.POSTER_BOUNTY_MANY = "Nagroda {gold}: {names}"
L.POSTER_AVENGED = "Pomścili: {names}"
L.ROW_AVENGED = "pomszczono {times}"
L.BOUNTY_TIP_HEAD = "Twoja własna nagroda w złocie"
L.BOUNTY_TIP_RULES = "Liczba całkowita od 1 do 99999. Puste lub 0: wraca wartość księgi. Enter ustawia, Esc anuluje."
L.BOUNTY_TIP_PROMISE = "Gildia i znajomi z DeathNote ją widzą. To tylko obietnica: rozliczacie się między sobą."
L.BOUNTY_TIP_CLICK = "Klik: wyznacz własną nagrodę"
L.CHAT_AVENGED = "Zemsta za ciebie: {killer}, od {name}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: wyznaczasz nagrodę {gold}g."
L.CHAT_BOUNTY_UNKNOWN = "{name}: brak w twoich księgach. Nagroda tylko na imię z księgi, tak jak pokazuje je gra: imię i nazwisko."
L.CHAT_BOUNTY_LIST = "Twoje nagrody ({count} z {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Nie masz żadnej własnej nagrody."
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
-- >>> START (1.3.0): English placeholders, to be translated (keys as in enUS.lua) -----------------------------------
L.SET_THEME = "Cover"
L.START_HINT = "You can change both later in the House Rules."
L.START_GO = "Go"
L.START_CLOSE_TIP = "Leave it as it is"
L.CHAT_THEME_NEWS = "New: the book comes in other covers. House Rules, sheet Book, or /dn theme."
L.HELP_START = "/dn start  the first-start window again (language and cover)"
-- <<< START
end)
