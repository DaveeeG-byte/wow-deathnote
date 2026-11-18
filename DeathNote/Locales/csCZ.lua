-- DeathNote: Čeština (csCZ). Translation of enUS.lua by DaveeeG.
-- Plural: 3 forms {count|one|few|other} (1 | 2-4 | 0, 5 and more). Rule in Locale.lua (PLURAL_OF.csCZ), not here.
-- Fonts: latinExt (Nimrod MT, Arial Narrow) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- No Czech game client: zone, class and race names come in the client's language (SAMPLE_ZONE stays English).
--
-- TOC-Notes: Kniha pomsty pro světové PvP: pamatuje si, kdo tě zabil, a varuje, když je vrah poblíž.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("csCZ")) then return end

Locale.Register("csCZ", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Hledaní"  -- [max 16]
L.TAB_UNSOLVED = "Nevyřešené"  -- [max 16]
L.TAB_DEATHLOG = "Deník smrtí"  -- [max 16]
L.TAB_GUILD = "Guilda"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Domácí řád"  -- [max 24]
L.HEAD_HELP = "Jak to funguje"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Kniha"  -- [max 14]
L.SHEET_ALERT = "Poplach"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "VEŘEJNÝ NEPŘÍTEL Č. 1"  -- [max 24]
L.STAMP_REVENGE = "POMSTA VYKONÁNA"  -- [max 16]
L.STAMP_PARDONED = "OMILOSTNĚNÍ"  -- [max 16]
L.STAMP_SUSPECT = "PODEZŘENÍ"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "VEŘEJNÝ NEPŘÍTEL Č. 1 POBLÍŽ"  -- [max 30]
L.ALERT_SIGHTED = "VEŘEJNÝ NEPŘÍTEL POBLÍŽ"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "PODEZŘELÝ POBLÍŽ"  -- [max 30]
L.ALERT_TITLE_GUILD = "NEPŘÍTEL GUILDY POBLÍŽ"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "VRAH PŘÁTEL POBLÍŽ"  -- [max 30]
L.ALERT_TITLE_HUNT = "CÍL ZE SEZNAMU NA ODSTŘEL"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "pod podezřením"
L.ALERT_LINE_KILLED = "tvoje smrti: {times}"
L.ALERT_LINE_KILLED_ASSISTED = "tvoje smrti: {times}, asistence: {assists}"
L.ALERT_LINE_ASSISTED = "podíl na tvé smrti: {times}"
L.ALERT_LINE_MANUAL = "zapsáno v knize ručně"
L.ALERT_LINE_LAST = "{text}, naposledy {time}"
L.ALERT_LINE_IN = "{text}, místo: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Pomsta: {times}"
L.ALERT_HINT_CLOSE = "Pravý klik: zavřít"  -- [max 44]
L.ALERT_HINT_COMBAT = "Zaměřit lze až po boji"  -- [max 44]
L.ALERT_HINT_TARGET = "Klik: zaměřit  ·  Pravý klik: zavřít"  -- [max 44]
L.ALERT_MORE = "ještě +{count}"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "v knize guildy"
L.GUILD_LINE_IN_FRIENDS = "v knize přátel"
L.GUILD_LINE_LISTED_BY = "v knihách: {names}"
L.GUILD_LINE_KILLED_GUILD = "zabití členů guildy: {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "zabití přátel: {kills}×"
L.GUILD_LINE_KILLED_BOTH = "zabití členů guildy a přátel: {kills}×"
L.GUILD_LINE_LAST = "{text}, poslední oběť: {name}"
L.HUNT_LINE_BY = "kdo vyhlásil hon: {names}"
L.HUNT_LINE_RELEASED = "na seznamu na odstřel"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "podezření"
L.TALLY_MANUAL = "zapsáno ručně"
L.TALLY_NONE = "zatím bez činu"
L.TALLY_KILLED = "tvoje smrti: {times}"
L.TALLY_ASSISTED = "asistence: {times}"
L.PLACE_UNKNOWN = "neznámé místo"
L.GKILLS_CAP = "nejméně {count}"
L.NAMELIST_MORE = "{names} a ještě {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY = "%d.%m."
L.TIME_FMT_DAY_YEAR = "%d.%m.%y"
L.TIME_NEVER = "nikdy"
L.TIME_JUST = "před chvílí"
L.TIME_MINUTES = "před {count} min"  -- [max 14]
L.TIME_HOURS = "před {count} h"  -- [max 14]
L.TIME_DAYS = "před {count} {count|dnem|dny|dny}"  -- [max 16]
L.MONEY_GOLD = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "Členové guildy s Revenge Book, kteří se ozvali: {count}."
L.HEALTH_NOGUILD = "Nejsi v žádné guildě, nic se nesdílí."
L.HEALTH_OFF = "Sdílení je vypnuté."
L.HEALTH_SHORT_NOGUILD = "Žádná guilda"  -- [max 18]
L.HEALTH_SHORT_OFF = "Sdílení vypnuto"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Zablokováno"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Odmítnuto"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Čeká"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Dotázáno"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Nefunguje"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Bez zvuku"  -- [max 16]
L.SOUND_RAIDWARNING = "Varování raidu"  -- [max 16]
L.SOUND_BELL = "Zvon"  -- [max 16]
L.SOUND_GONG = "Gong"  -- [max 16]
L.SOUND_HEARTBEAT = "Tlukot srdce"  -- [max 16]
L.SOUND_FEATHER = "Brk"  -- [max 16]
L.SOUND_SIREN = "Siréna"  -- [max 16]
L.CHANNEL_MASTER = "Hlavní"  -- [max 16]
L.CHANNEL_SFX = "Efekty"  -- [max 16]
L.CHANNEL_DIALOG = "Dialogy"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name}: nyní v knize."
L.CHAT_REMOVED = "{name}: vyškrtnuto z knihy."
L.CHAT_SYNC_WAIT = "Synchronizace právě proběhla. Zkus to znovu za {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Zatím žádná jména."
L.EMPTY_WANTED_SUB = "Zkus jít aspoň jednou ven."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  otevřít/zavřít knihu"
L.HELP_ADD = "/dn add <Jméno [Příjmení]>  ručně zapsat vraha do knihy"
L.HELP_DEL = "/dn del <Jméno [Příjmení]>  vyškrtnout vraha z knihy"
L.HELP_QUIET = "/dn quiet  poplach vyp./zap."
L.HELP_TEST = "/dn test  ukázat zkušební poplach"
L.HELP_GUILD = "/dn guild  kniha guildy: stav a kdo z guildy má Revenge Book"
L.HELP_FRIENDS = "/dn friends  kniha přátel: stav a kdo z přátel má Revenge Book"
L.HELP_SYNC = "/dn sync  hned synchronizovat knihu guildy a knihu přátel"
L.HELP_HUNT = "/dn hunt <Jméno [Příjmení]>  vyhlásit hon (bez jména: ukázat seznam na odstřel)"
L.HELP_CALLOFF = "/dn calloff <Jméno [Příjmení]>  odvolat vlastní vyhlášení honu"
L.HELP_LANG = "/dn lang <kód>  jazyk knihy (enUS, deDE, csCZ ...), po /reload"
L.HELP_THEME = "/dn theme <název>  vazba knihy, po /reload"
L.HELP_PROBE = "/dn probe  hledání chyb: co hra prozrazuje knize"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  hledání chyb, navíc test záznamu boje"
L.HELP_DEBUG = "/dn debug  hledání chyb: podrobně zapisovat každou smrt (zap./vyp.)"
L.HELP_HELP = "/dn help  tato nápověda"
L.HELP_SILENT_ZONES = "V dungeonech, na bojištích a v arénách kniha sama mlčí."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "zap."
L.WORD_OFF = "vyp."
L.CHAT_WHO_ADD = "Koho? /dn add <Jméno>"
L.CHAT_WHO_DEL = "Koho? /dn del <Jméno>"
L.CHAT_WHO_CALLOFF = "Koho? /dn calloff <Jméno>"
L.CHAT_BAD_NAME = "Neplatné jméno."
L.CHAT_NOT_IN_BOOK = "Není v knize: {name}"
L.CHAT_ALARM_ON = "Poplach zapnut."
L.CHAT_ALARM_OFF = "Poplach vypnut."
L.CHAT_DEBUG = "Záznam pro hledání chyb: {state}"
L.CHAT_UNKNOWN_CMD = "Neznámý příkaz. Nápověda: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Kniha guildy není načtená."
L.CHAT_NO_GUILD = "Nejsi v žádné guildě (nebo o ní hra ještě neví)."
L.CHAT_GUILD_STATE = "Guilda {guild}: sdílení {share}, příjem {receive}"
L.CHAT_GUILD_BOOK = "Kniha guildy. Vrazi: {enemies} (jen ručně: {listed}), činy: {deeds}, s oběťmi v guildě: {foreign}. Sdílet ruční zápisy: {manual}"
L.CHAT_STATE_OK = "Stav: {text}"
L.CHAT_STATE_WARN = "Pozor: {text}"
L.CHAT_NO_MATES = "Zatím se neozval nikdo z guildy s Revenge Book."
L.CHAT_HAVE_DN = "Revenge Book mají: {names}"
L.CHAT_HAVE_DN_MORE = "Revenge Book mají: {names} a ještě {count}"
L.CHAT_SYNC_ASKED = "Synchronizace vyžádána. Odpovědi dorazí během pár sekund."
L.CHAT_SYNC_FAIL = "Synchronizace nefunguje: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "žádná guilda nebo je sdílení vypnuté."
L.CHAT_FRIENDS_NOT_LOADED = "Kniha přátel není načtená."
L.CHAT_FRIENDS_STATE = "Přátelé: sdílení {share}, online {online} z {total}."
L.CHAT_FRIENDS_BOOK = "Kniha přátel. Vrazi: {enemies} (jen ručně: {listed}), činy: {deeds}."
L.CHAT_NO_FRIENDS = "Zatím se neozval nikdo z přátel s Revenge Book."
L.CHAT_HUNT_NOT_LOADED = "Seznam na odstřel není načtený."
L.CHAT_HUNT_UNKNOWN = "Neznámé jméno: {name}. Uveď i příjmení, tak jak je jméno ve hře."
L.CHAT_HUNT_CAP = "Hon nelze vyhlásit: nejvýš {own} vlastních vyhlášení a {targets} cílů na seznam."
L.CHAT_HUNT_NOWHERE = "Hon teď nelze vyhlásit: žádná guilda a sdílení s přáteli je vypnuté."
L.CHAT_HUNT_BOTH = "{name}: hon vyhlášen pro guildu i přátele."
L.CHAT_HUNT_GUILD = "{name}: hon vyhlášen pro guildu."
L.CHAT_HUNT_FRIENDS = "{name}: hon vyhlášen pro tvé přátele."
L.CHAT_CALLED_OFF = "{name}: hon odvolán."
L.CHAT_NO_OWN_CALL = "{name}: nemáš tu vlastní vyhlášení."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Jazyk teď: {lang}. Změna: /dn lang <kód>"
L.CHAT_LANG_LIST = "Kódy: {codes}"
L.CHAT_LANG_BAD = "Neznámý jazyk: {code}"
L.CHAT_LANG_SET = "Jazyk: {lang}."
L.CHAT_LANG_RELOAD = "Jazyk: {lang}. Platí po /reload."
L.CHAT_THEME_CURRENT = "Vazba teď: {theme}. Změna: /dn theme <název>"
L.CHAT_THEME_LIST = "Vazby: {themes}"
L.CHAT_THEME_BAD = "Neznámá vazba: {name}"
L.CHAT_THEME_SET = "Vazba: {theme}."
L.CHAT_THEME_RELOAD = "Vazba: {theme}. Platí po /reload."
L.THEME_NOTEBOOK = "Černá kniha"
L.THEME_HARBOR = "Korzárská kniha"
L.THEME_TRADE = "Dílna"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Kniha je připravená. Kdo tě zabije v otevřeném světě, bude pak v ní. Otevřeš ji přes /dn nebo tlačítkem u minimapy."
L.WELCOME_PLATES = "Jmenovky nepřátel jsou vypnuté. Bez nich poplach vidí jen tvůj cíl."
L.WELCOME_SHARE = "Guilda a přátelé, kteří mají Revenge Book, čtou s tebou. Poznámky a podezření zůstávají u tebe."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "V KNIZE:"
L.TIP_HUNT = "NA ODSTŘEL:"
L.TIP_GUILDBOOK = "KNIHA GUILDY:"
L.TIP_PARDONED = "omilostnění"
L.TIP_RANK = "{rank}. místo"
L.TIP_REVENGE = "pomsta {times}"
L.TIP_LISTED_BY = "v knihách: {names}"
L.TIP_NOTE = "Poznámka: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Klik: otevřít · Pravý klik: pryč"
L.BANNER_NEW = "NOVÝ ZÁPIS"  -- [max 24]
L.BANNER_NEW_LINE = "je teď v knize"
L.BANNER_AGAIN = "ZASE"  -- [max 24]
L.BANNER_AGAIN_LINE = "zase tvoje smrt, celkem už {count}"
L.BANNER_SUSPECT = "PODEZŘENÍ"  -- [max 24]
L.BANNER_SUSPECT_LINE = "pod podezřením, vyřeš to v knize"
L.BANNER_UNCLEAR = "PACHATEL NEJASNÝ"  -- [max 24]
L.BANNER_CANDIDATES = "{count} {count|kandidát|kandidáti|kandidátů}"
L.BANNER_UNCLEAR_LINE = "Klik: urči vraha v Nevyřešených"
L.BANNER_REVENGE = "ODPLATA"  -- [max 24]
L.BANNER_REVENGE_LINE = "Pomsta vykonána ({count}×)"
L.BANNER_GUILD = "GUILDA"  -- [max 24]
L.BANNER_FRIENDS = "PŘÁTELÉ"  -- [max 24]
L.BANNER_KILLED_BY = "vrah: {name}"
L.BANNER_HUNT = "SEZNAM NA ODSTŘEL"  -- [max 24]
L.BANNER_BAGGED = "smrtící úder: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Sdílení je vypnuté (Domácí řád, list Guilda)."
L.SYNC_FRIENDS_OFF = "Sdílení s přáteli je vypnuté."
L.SYNC_NOBODY = "Žádná guilda ani přátelé ke sdílení."
L.SYNC_SHORT_NOBODY = "Nic se nesdílí"  -- [max 18]
L.SYNC_PREFIX = "Hra nedovolí příjem. Pomůže nové přihlášení."
L.SYNC_SHORT_PREFIX = "Příjem nejde"  -- [max 18]
L.SYNC_BLOCKED = "Realm blokuje odesílání. Předej knihu přes Zálohovat knihu."
L.SYNC_SHORT_BLOCKED = "Realm blokuje odeslání"  -- [max 22]
L.SYNC_FAILING = "Odesílání teď nejde, zkusí se znovu."
L.SYNC_SHORT_FAILING = "Odesílání vázne"  -- [max 18]
L.SYNC_HOLD = "Odesílání čeká, {wait}."
L.SYNC_HOLD_INSTANCE = "dokud neopustíš instanci"
L.SYNC_HOLD_COMBAT = "dokud neskončí boj"
L.SYNC_HOLD_LOCKDOWN = "dokud nebude chat zase volný"
L.SYNC_HOLD_AGAIN = "dokud to zase nepůjde"
L.SYNC_HOLD_SHORT_INSTANCE = "Čeká: instance"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Čeká: boj"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Čeká: chat"  -- [max 18]
L.SYNC_QUIET = "Odesláno, ale zatím se neozval nikdo z guildy s Revenge Book."
L.SYNC_READY = "Připraveno. Zatím se neozval nikdo z guildy s Revenge Book."
L.SYNC_RUNNING = "Běží: {count} {count|člen|členové|členů} guildy s Revenge Book."
L.SYNC_RUNNING_ALL = "Běží. S Revenge Book v guildě a mezi přáteli: {count}."
L.FRIENDS_OFF = "Sdílení s přáteli je vypnuté (Domácí řád, list Guilda)."
L.FRIENDS_BLOCKED = "Realm blokuje šepot. Přátelé nedostanou nic."
L.FRIENDS_SHORT_BLOCKED = "Realm blokuje šepot"  -- [max 22]
L.FRIENDS_FAILING = "Šepot teď nejde, zkusí se znovu."
L.FRIENDS_SHORT_FAILING = "Šepot vázne"  -- [max 18]
L.FRIENDS_NONE_LISTED = "Na seznamu přátel nikdo není."
L.FRIENDS_NONE_ONLINE = "Teď není online nikdo z přátel."
L.FRIENDS_SHORT_NONE_ONLINE = "Přátelé offline"  -- [max 18]
L.FRIENDS_QUIET = "Dotázáno, ale zatím se neozval nikdo z přátel s Revenge Book."
L.FRIENDS_READY = "Připraveno. Zatím se neozval nikdo z přátel s Revenge Book."
L.FRIENDS_HOLD = "Odesílání přátelům čeká, dokud to zase nepůjde."
L.FRIENDS_RUNNING = "Běží: {count} {count|přítel|přátelé|přátel} s Revenge Book."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Převzato z knihy guildy (zabití členů guildy: {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Databáze není načtená."
L.IMPORT_NO_TEXT = "Žádný text."
L.IMPORT_NO_HEADER = "Chybí první řádek (začíná na {header}). Zkopíruj prosím celý text."
L.IMPORT_NOT_EXPORT = "Tohle není export Revenge Book (chybí hlavička nebo špatná verze)."
L.IMPORT_TOO_LONG = "Příliš mnoho řádků (nejvýš {count})."
L.IMPORT_BAD_KEY = "Řádek {line}: neplatný klíč."
L.IMPORT_BAD_TIME = "Řádek {line}: neplatný čas."
L.IMPORT_BROKEN = "Řádek {line} je neúplný nebo poškozený (useknutý text?). Nic se nenačetlo."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "ano"
L.WORD_NO = "ne"
L.PROBE_HEAD = "Sonda: rozhraní {apis}/{apisAll} k dispozici, událostí k registraci {events}/{eventsAll}."
L.PROBE_MISSING = "Chybí: {list}"
L.PROBE_NOT_REGISTERABLE = "Nelze registrovat: {list}"
L.PROBE_SOURCES = "Recap teď: {recap} · Meter: {meter} · Záznam boje: {clog}"
L.PROBE_READABLE = "čitelný"
L.PROBE_DEAD = "mrtvý"
L.PROBE_PLATES = "Jmenovky nepřátel: {plates} · Otevřený svět: {open}"
L.PROBE_PLATES_OFF = "VYP. (hráče odhalí jen cíl a myš)"
L.PROBE_TARGET = "Cíl: jméno={name} GUID={guid} třída={class} nepřátelský={enemy} míří na mě={me}"
L.PROBE_GUILD = "Guilda: prefix {prefix} · odesílání {send} · poslední návratová hodnota {result} · odesláno {sent}, přijato {received}, zahozeno {dropped}"
L.PROBE_REGISTERED = "registrováno"
L.PROBE_NOT_REGISTERED = "NEregistrováno ({result})"
L.PROBE_POSSIBLE = "možné"
L.PROBE_ABSENT = "chybí"
L.PROBE_WAITS = " · čeká: {why}"
L.PROBE_LISTED = "Ruční zápisy (M): odesláno {sent}, přijato {received}, zahozeno {dropped} · vyškrtnuté (X): odesláno {usent}, přijato {ureceived}, zahozeno {udropped}"
L.PROBE_GUILDBOOK = "Kniha guildy: {text}"
L.PROBE_SAVED = "Uloženo v DeathNoteDB.probe (v souboru po /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Pořadí"  -- [max 14]
L.SORT_RECENT = "Nejnovější"  -- [max 14]
L.SORT_NAME = "Jméno"  -- [max 14]
L.SORT_SEEN = "Spatření"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Kdo tě zabije v otevřeném světě, skončí tady. Samo od sebe."
L.EMPTY_OPEN_HEAD = "Nic k vyřešení."
L.EMPTY_JOURNAL_HEAD = "Ještě ani jedna smrt."
L.EMPTY_JOURNAL_SUB = "Respekt. Nebo lež."
L.EMPTY_NOGUILD_HEAD = "Žádná guilda."
L.EMPTY_NOGUILD_SUB = "Umírat se dá i o samotě."
L.EMPTY_GUILDOFF_HEAD = "Kniha guildy je zavřená."
L.EMPTY_GUILDOFF_SUB = "Sdílení je vypnuté. Domácí řád ví, kde."
L.EMPTY_GUILDNIL_HEAD = "Z guildy zatím ani slovo."
L.EMPTY_GUILDNIL_SUB = "Tvoje kniha se odešle, jakmile bude mít někdo z guildy Revenge Book."
L.EMPTY_GUILDQUIET_HEAD = "V knize guildy zatím nic není."
L.EMPTY_GUILDQUIET_SUB = "Tvoje guilda měla zatím klid."
L.EMPTY_FRIENDSOFF_HEAD = "Kniha přátel je zavřená."
L.EMPTY_FRIENDSOFF_SUB = "Sdílení s přáteli je vypnuté. Domácí řád ví, kde."
L.EMPTY_FRIENDSNIL_HEAD = "Zatím se neozval nikdo z přátel s Revenge Book."
L.EMPTY_FRIENDSNIL_SUB = "Tvoje kniha se odešle, jakmile bude mít někdo z přátel Revenge Book."
L.EMPTY_FRIENDSQUIET_HEAD = "Od přátel zatím nic."
L.EMPTY_FRIENDSQUIET_SUB = "Tvoji přátelé měli zatím klid."
L.EMPTY_NOBODY_HEAD = "Žádná guilda, žádní přátelé."
L.EMPTY_NOBODY_SUB = "Umírat se dá i o samotě."
L.EMPTY_NOBODY_HINT = "Až budou mít lidé z guildy nebo přátelé ze seznamu přátel Revenge Book, uvidíš tady, co se jim děje."
L.EMPTY_SHAREDNIL_HEAD = "Zatím se neozval nikdo s Revenge Book."
L.EMPTY_SHAREDNIL_SUB = "Tvoje kniha se odešle, jakmile budou mít lidé z guildy nebo přátelé Revenge Book."
L.EMPTY_SHAREDQUIET_HEAD = "Zatím tu nic není."
L.EMPTY_SHAREDQUIET_SUB = "Guilda i přátelé měli zatím klid."
L.EMPTY_HUNT_HEAD = "Seznam na odstřel je prázdný."
L.EMPTY_HUNT_SUB = "Na plakátu: Vyhlásit hon."
L.EMPTY_HUNT_HINT = "Nebo v chatu: /dn hunt Jméno Příjmení. Uvidí to celá tvoje guilda i tvoji přátelé."
L.EMPTY_SEARCH_HEAD = "Nic nenalezeno."
L.EMPTY_SEARCH_SUB = "Enter zapíše jméno do knihy."
L.EMPTY_SEARCHRO_HEAD = "Nic nenalezeno."
L.EMPTY_SEARCHRO_SUB = "Někdy pomůže jiný zápis jména."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "KNIHA"  -- [max 12]
L.MANUAL_BOOK = "Kdo tě zabije v otevřeném světě, zapíše se automaticky. Klik na zprávu po smrti otevře stránku vraha."
L.MANUAL_WANTED_HEAD = "HLEDANÍ"  -- [max 12]
L.MANUAL_WANTED = "Tvoji vrazi, nejhorší nahoře. Klik ukáže plakát s činy a poznámkou. Omilostnění jsou přeškrtnutí na konci."
L.MANUAL_UNSOLVED_HEAD = "NEVYŘEŠENÉ"  -- [max 13]
L.MANUAL_UNSOLVED = "Když není jasné, kdo to byl, případ čeká tady. Klik na jméno určí vraha."
L.MANUAL_ALERT_HEAD = "POPLACH"  -- [max 12]
L.MANUAL_ALERT = "Když se vrah objeví jako jmenovka, cíl nebo pod myší, kniha se ozve. Klik ho zaměří, v boji až potom."
L.MANUAL_ADD_HEAD = "ZÁPIS"  -- [max 12]
L.MANUAL_ADD = "Napiš jméno do vyhledávání, Enter. Pravý klik na řádek: zapsat pomstu, omilostnit, vyškrtnout."
L.MANUAL_GUILD_HEAD = "GUILDA"  -- [max 12]
L.MANUAL_GUILD = "Lidé z guildy a přátelé s Revenge Book vidí tvoje potvrzené smrti a ruční zápisy. Plakát nebo /dn hunt Jméno: vyhlásit hon. Klik na odměnu: vypsat vlastní, jen slib, vyrovnáte se mezi sebou."
L.MANUAL_SHARE_HEAD = "PŘEDAT"  -- [max 12]
L.MANUAL_SHARE = "Domácí řád, Zálohovat knihu: text ke zkopírování, pro všechny bez Revenge Book."
L.MANUAL_QUIET_HEAD = "KLID"  -- [max 12]
L.MANUAL_QUIET = "V dungeonech a na bojištích poplach mlčí. Jinak: prostřední klik na tlačítko u minimapy nebo /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Opravdu vyškrtnout z knihy: {name}?\nVšechny činy i poznámka se ztratí."
L.CONFIRM_DELETE_OK = "Vyškrtnout"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Vyčistit knihu guildy na tomto počítači?\nJejí seznam na odstřel zmizí taky, tvoje vyhlášení zůstanou.\nTvoje vlastní kniha zůstane, jak je."
L.CONFIRM_GUILD_CLEAR_OK = "Vyčistit"  -- [max 14]
L.CONFIRM_CANCEL = "Zrušit"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ZLATA"  -- [max 14]
L.BOUNTY_SILVER = "{count} STŘÍBRA"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Potvrdit"  -- [max 19]
L.ACT_DISMISS = "Zamítnout"  -- [max 19]
L.ACT_HUNT_AGAIN = "Znovu hledat"  -- [max 19]
L.ACT_REVENGE = "Zapsat pomstu"  -- [max 19]
L.ACT_PARDON = "Omilostnit"  -- [max 19]
L.ACT_STRIKE = "Vyškrtnout"  -- [max 19]
L.ACT_OPEN_OWN = "Otevřít v knize"  -- [max 19]
L.ACT_ADOPT = "Do mé knihy"  -- [max 19]
L.ACT_CALLOFF = "Odvolat hon"  -- [max 19]
L.ACT_RELEASE = "Vyhlásit hon"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "spatření {time}"
L.ROW_NOT_SEEN = "zatím bez spatření"
L.ROW_PARDONED = "omilostnění"
L.ROW_SUSPECT = "Podezření"
L.MARK_REVENGE = "POMSTA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Pachatel nejasný"
L.MARK_CANDIDATES = "{count} {count|KANDIDÁT|KANDIDÁTI|KANDIDÁTŮ}"  -- [max 16]
L.MARK_SUSPECT = "PODEZŘENÍ"  -- [max 16]
L.ROW_NO_PLAYER = "Žádný hráč"
L.ROW_UNCLEAR = "Nejasné jak"
L.MARK_NOT_COUNTED = "NEPOČÍTÁ SE"  -- [max 16]
L.ROW_LISTED_BY = "kdo zapsal: {names}"
L.ROW_GKILLED = "zabití: {kills}×"
L.ROW_VICTIMS = "{count} {count|oběť|oběti|obětí}"
L.ROW_LAST = "naposledy: {text}"
L.MARK_IN_BOOK = "V KNIZE"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|vrah|vrazi|vrahů}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|smrt|smrti|smrtí}"  -- [max 12]
L.MEMBER_LISTED = "{count} ručně"  -- [max 14]
L.MEMBER_ME = "co o tobě vidí ostatní"
L.MEMBER_NOTHING = "zatím nic nesdíleno"
L.MEMBER_LAST_DIED = "poslední smrt {time}"
L.MARK_YOU = "ty"  -- [max 16]
L.MARK_FRIEND = "PŘÍTEL"  -- [max 16]
L.MARK_BOTH = "Z GUILDY, PŘÍTEL"  -- [max 20]
L.MARK_TAKEN_DOWN = "ULOVENO {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ŽIVÝ NEBO MRTVÝ"  -- [max 24]
L.BOOK_TITLE = "Revenge Book"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "ČINY"  -- [max 14]
L.POSTER_NOTE = "POZNÁMKA"  -- [max 8]
L.POSTER_BOUNTY = "ODMĚNA"  -- [max 12]
L.ROLE_ASSIST = "asistence"  -- [max 14]
L.ROLE_SUSPECT = "podezření"  -- [max 14]
L.POSTER_LEVEL = "Úroveň {level}"
L.POSTER_GUILD = "Guilda: {guild}"
L.POSTER_LAST_SEEN = "Poslední spatření {time}"
L.POSTER_NOT_SEEN = "Zatím bez spatření"
L.POSTER_ONLY_SUSPECT = "Jen podezření, žádný prokázaný čin."
L.POSTER_NO_DEEDS = "Žádné činy nezapsány."
L.TIP_LISTED_AT = "Zapsáno {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Příčina smrti: {spell}"
L.TIP_VICTIM = "Oběť: {name}"
L.TIP_VICTIM_LEVEL = "Oběť: {name} (úroveň {level})"
L.TIP_KILLER_LEVEL = "Úroveň vraha: {level}"
L.TIP_ASSISTS = "Asistence: {names}"
L.TIP_ROLE_ASSIST = "Asistence bez smrtícího úderu."
L.TIP_ROLE_SUSPECT = "Jen podezření, neprokázáno."
L.MORE_LINE = "… a ještě {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "KNIHA GUILDY"  -- [max 24]
L.POSTER_IN_BOOK_OF = "V knihách: {names}"
L.POSTER_SEEN = "Spatření {time}"
L.POSTER_SEEN_BY = "Spatření {time}, hlásí: {name}"
L.TIP_IN_BOOK_OF = "V knihách"
L.POSTER_REMARK = "ZÁZNAM"  -- [max 12]
L.POSTER_BY_HAND = "ZAPSÁNO RUČNĚ"  -- [max 22]
L.POSTER_VICTIMS = "OBĚTI"  -- [max 12]
L.POSTER_LISTED = "ZAPSALI"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Zapsáno ručně."
L.POSTER_NO_DEEDS_SENT = "Žádné činy nepředány."
L.POSTER_NONE_KNOWN = "žádné známé"
L.POSTER_NO_NAMES = "jména nepředána"
L.TIP_VICTIMS = "Oběti"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Vyhlášeno {time}"
L.HUNT_REASON = "Důvod: {reason}"
L.POSTER_HUNTLIST = "SEZNAM NA ODSTŘEL"  -- [max 24]
L.POSTER_RELEASED_N = "hon vyhlášen {times}"
L.POSTER_RELEASED_BY = "Kdo vyhlásil: {names}"
L.POSTER_TAKEN_DOWN = "ULOVENO"  -- [max 12]
L.POSTER_NOT_YET = "ZATÍM NE"  -- [max 18]
L.POSTER_CALLS = "VYHLÁŠENÍ"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Už nikdo."
L.POSTER_LAST = "NAPOSLED"  -- [max 13]
L.POSTER_TAKEN_BY = "smrtící úder: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "zatím neuloveno"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Smrt"  -- [max 20]
L.CASE_ASSISTS = "ASISTENCE"  -- [max 24]
L.CASE_PICK = "URČI VRAHA"  -- [max 24]
L.CASE_NOT_COUNTED = "Nepočítá se (instance, bojiště nebo duel)"
L.CASE_KILLER = "VRAH"  -- [max 24]
L.CASE_KILLER_SUSPECT = "VRAH (PODEZŘENÍ)"  -- [max 24]
L.CASE_CLICK_NAME = "Klik na jméno otevře plakát."
L.CASE_GONE = "Už není v knize."
L.CASE_KILLER_UNCLEAR = "PACHATEL NEJASNÝ"  -- [max 24]
L.CASE_SEVERAL = "Připadá v úvahu víc hráčů. Čí jméno patří do knihy?"
L.CASE_NOBODY = "Nikdo nepřipadá v úvahu."
L.CASE_HOW = "CO SE STALO"  -- [max 24]
L.CASE_PVE = "Příšera nebo svět sám. Žádný případ pro knihu."
L.CASE_UNCLEAR = "Nejasné"
L.CASE_DARK = "Vyšetřování tápe ve tmě."
L.TIP_MORE_CANDIDATES = "Další kandidáti"
L.CASE_SOURCE_SUSPECT = "Podezření: tento hráč si tě krátce před smrtí zaměřil."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Řádek v tooltipu u vrahů"  -- [max 44]
L.OPT_MINIMAP = "Tlačítko u minimapy"  -- [max 44]
L.OPT_ALERT = "Poplach, když se objeví vrah"  -- [max 44]
L.OPT_FLASH = "Blikat červeně okrajem obrazovky"  -- [max 44]
L.OPT_SUSPECTS = "Hlásit i podezřelé"  -- [max 44]
L.OPT_DEATHMSG = "Zpráva po smrti v PvP"  -- [max 44]
L.OPT_G_SHARE = "Sdílet moje smrti"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Sdílet ruční zápisy"  -- [max 44]
L.OPT_G_RECEIVE = "Přijímat knihu guildy"  -- [max 44]
L.OPT_G_ALERT = "Varovat před vrahy z knihy guildy"  -- [max 44]
L.OPT_G_ALERTLISTED = "Varovat i před ručními zápisy"  -- [max 44]
L.OPT_G_ANNOUNCE = "Hlásit, když zemře někdo z guildy"  -- [max 44]
L.OPT_G_SIGHTINGS = "Sdílet spatření"  -- [max 44]
L.OPT_F_SHARE = "Sdílet s guildou"  -- [max 44]
L.OPT_F_FRIENDS = "Sdílet s přáteli"  -- [max 44]
L.OPT_F_ALERT = "Varovat před vrahy guildy a přátel"  -- [max 44]
L.OPT_F_ALERTHUNT = "Varovat před cíli ze seznamu na odstřel"  -- [max 44]
L.OPT_F_ANNOUNCE = "Hlásit smrti v guildě a mezi přáteli"  -- [max 44]
L.OPT_F_SIGHTINGS = "Sdílet spatření s guildou a přáteli"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guilda"  -- [max 14]
L.SET_BOOK_SIZE = "Velikost knihy"  -- [max 34]
L.SET_LANGUAGE = "Jazyk"  -- [max 16]
L.SET_LANG_AUTO = "Automaticky"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Platí po znovunačtení."  -- [max 28]
L.SET_LANG_RELOAD = "Načíst znovu"  -- [max 22]
L.SET_SEC_SHARE = "PŘEDAT"  -- [max 24]
L.IO_EXPORT = "Zálohovat knihu"  -- [max 17]
L.IO_IMPORT = "Načíst knihu"  -- [max 17]
L.SET_HINT_BOOK = "Záloha ti dá knihu jako text: na uschování nebo k předání lidem mimo guildu. Načtení slučuje a nic nepřepisuje."
L.SET_SEC_SOUND = "ZVUK"  -- [max 24]
L.SET_SOUND = "Zvuk"  -- [max 22]
L.SET_VOLUME = "Hlasitost"  -- [max 22]
L.SET_CHANNEL = "Kanál"  -- [max 12]
L.SET_SEC_THRESHOLD = "PRÁH"  -- [max 24]
L.SET_COOLDOWN = "Odmlka pro každého vraha"  -- [max 34]
L.SET_MINKILLS = "Poplach po tolika smrtích od něj"  -- [max 34]
L.SET_ALERT_SIZE = "Velikost poplachu"  -- [max 34]
L.SET_TEST_ALERT = "Zkušební poplach"  -- [max 17]
L.SET_G_MINKILLS = "Varování guildy po tolika smrtích"  -- [max 34]
L.SET_F_MINKILLS = "Varování po tolika smrtích"  -- [max 34]
L.SET_SEC_STATUS = "STAV"  -- [max 24]
L.SET_SEC_SHARING = "SDÍLENÍ"
L.SET_SEC_WARN = "POPLACH"
L.SET_MORE = "Více"
L.SET_GUILD_CLEAR = "Vyčistit knihu guildy"  -- [max 26]
L.BTN_BACK = "Zpět"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synchronizovat"  -- [max 14]
L.SYNC_AGAIN_IN = "znovu za {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Přátelé"
L.TIP_GUILD_NAME = "Guilda {guild}"
L.TIP_MATES_WITH = "Z guildy s Revenge Book:"
L.TIP_NO_MATE = "Zatím se neozval nikdo z guildy s Revenge Book."
L.TIP_FRIENDS_WITH = "Přátelé s Revenge Book:"
L.TIP_SHARED = "Sdílí se: tvoje potvrzené smrti, ruční zápisy a tvoje vyhlášení honu."
L.TIP_NOT_SHARED = "Nesdílí se: poznámky, podezření, omilostnění, načtené zápisy."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Načíst"  -- [max 17]
L.IO_DONE = "Načteno. Nové: {new}, sloučené: {merged}."
L.IO_FAILED = "To nevyšlo."
L.IO_SMALL = "Jen stručně"  -- [max 17]
L.IO_ALL = "Ukázat vše"  -- [max 17]
L.IO_MSG_FULL = "Celá kniha s činy ({size})."
L.IO_MSG_SHORT = "Jen jména a počty ({size}). S činy: {full}."
L.IO_MSG_BIG = "Velká kniha ({size}): označení a kopírování chvíli trvá."
L.IO_HELP_EXPORT = "Text je označený: Ctrl+C ho zkopíruje. Uschovej ho nebo ho předej přátelům."
L.IO_HELP_IMPORT = "Vlož zálohovaný text přes Ctrl+V, pak Načíst. Nic se nepřepíše."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Důvod uvidí všichni v tvé guildě a tvoji přátelé s Revenge Book."
L.REL_HINT_GUILD = "Důvod uvidí všichni v tvé guildě s Revenge Book."
L.REL_HINT_FRIENDS = "Důvod uvidí tvoji přátelé s Revenge Book."
L.REL_HEAD = "Vyhlásit hon"  -- [max 24]
L.REL_FOR = "PRO"  -- [max 6]
L.REL_REASON = "DŮVOD"  -- [max 8]
L.REL_HINT2 = "Tvoje poznámka zůstává u tebe. Vlastní vyhlášení můžeš odvolat jen ty."
L.REL_GO = "Vyhlásit hon"  -- [max 17]
L.REL_NONE = "Žádná guilda a sdílení s přáteli je vypnuté."
L.REL_CAP = "Nejvýš {own} vlastních vyhlášení a {max} cílů na seznam."
L.REL_FAILED = "Hon teď nelze vyhlásit."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Bez zvuku: poplach se jen ukáže."
L.SET_HINT_BUILTIN = "Hlasitost tohoto zvuku se řídí kanálem v nastavení hry."
L.SET_HINT_LEVELS = "Pět stupňů od tichého po hlasitý. Navíc platí posuvník kanálu v nastavení hry."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guilda a přátelé"  -- [max 18]
L.TIP_HELP_BUTTON = "Jak kniha funguje"
L.VIEW_HUNT = "Na odstřel"  -- [max 13]
L.VIEW_BY_KILLER = "Podle vrahů"  -- [max 13]
L.VIEW_BY_MATE = "Podle obětí"  -- [max 13]
L.SRC_ALL = "Všichni"  -- [max 12]
L.SRC_GUILD = "Guilda"  -- [max 12]
L.SRC_FRIENDS = "Přátelé"  -- [max 12]
L.SORT_HIDE_PARDONED = "Skrýt omilostněné"  -- [max 24]
L.SORT_SHOW_PARDONED = "Ukázat omilostněné"  -- [max 24]
L.SEARCH_ADD = "Hledat nebo zapsat …"  -- [max 26]
L.SEARCH_SHORT = "Hledat …"  -- [max 10]
L.SEARCH_KILLER = "Hledat vraha …"  -- [max 15]
L.SEARCH_JOURNAL = "Vrah nebo místo …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Sbalit vše"
L.TIP_EXPAND_ALL = "Rozbalit vše"
L.STATUS_NO_PLATES = "Jmenovky nepřátel jsou vypnuté: poplach vidí jen cíl a myš."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "Hledaní: {count}"
L.MM_UNSOLVED = "Nevyřešené: {count}"
L.MM_ALERT_OFF = "Poplach je vypnutý (prostřední klik)"
L.MM_CLICK = "Klik: kniha · Pravý klik: Domácí řád"
L.MM_MIDDLE = "Prostřední klik: poplach zap./vyp."
L.MM_DRAG = "Tažení: posunout po okraji minimapy"
L.MM_CHAT_ALERT_ON = "Poplach zapnut."
L.MM_CHAT_ALERT_OFF = "Poplach vypnut."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "NEPŘÍTEL GUILDY Č.1"  -- [max 25]
L.STAMP_HUNT = "HON ZAHÁJEN"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} se vydává za tvého přítele {friend}: odmítnuto."
L.FRIENDS_SHORT_IMPOSTOR = "Cizí jméno odmítnuto"  -- [max 22]
L.ALERT_LEVEL = "Úroveň {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "naposledy úroveň {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Úroveň ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · na seznamu na odstřel ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nový cíl|nové cíle|nových cílů}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nově na seznamu na odstřel"
L.OPT_F_ANNOUNCEHUNT = "Hlásit nové a ulovené cíle ze seznamu"  -- [max 44]
L.SET_HUNT_EXPIRE = "Vyhlášení vyprší po"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nikdy"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|den|dny|dní}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Vyčistit knihu přátel"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Vyčistit knihu přátel na tomto počítači?\nJejí seznam na odstřel zmizí taky, tvoje vyhlášení zůstanou."
L.CONFIRM_CALLOFF_ALL = "Odvolat všechna tvoje vyhlášení?\nGuilda a přátelé se to dozví postupně."
L.CONFIRM_CALLOFF_ALL_OK = "Odvolat vše"  -- [max 14]
L.ACT_CALLOFF_ALL = "Odvolat všechna moje"  -- [max 24]
L.ACT_HUNT_HIDE = "Skrýt pro mě"  -- [max 19]
L.ACT_HUNT_SHOW = "Znovu ukázat"  -- [max 19]
L.HUNT_ROW_HIDDEN = "skryto pro tebe"
L.HUNT_ROW_CALLS = "{count} vyhlášení: {names}"
L.POSTER_ON_HUNTLIST = "Na seznamu na odstřel ({names})"
L.REL_SELF = "Na sebe hon vyhlásit nemůžeš."
L.REL_MATE = "To je někdo z vašich (guilda nebo přátelé s Revenge Book)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Kdo je tvůj přítel {friend}: {a}, nebo {b}? Vyber."
L.FRIENDS_SHORT_CONFLICT = "Přítel nejasný"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Dva hráči se vydávají za tvého přítele {friend}: {a} a {b}. Dokud nevybereš, kniha od žádného z nich nic nepřijme. Guilda a přátelé, zobrazení Podle obětí: pravý klik na jméno."
L.MEMBER_CONFLICT = "Pravý klik: je to tvůj přítel?"  -- [max 40]
L.ACT_TIE_MINE = "Můj přítel: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Odpojit jméno"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Odpojit {name} od seznamu přátel?\nCo toto jméno přineslo do knihy přátel, se smaže; další zpráva pod tímto jménem se propojí znovu."
L.CHAT_FRIENDS_TIES = "Propojená celá jména (* = první kontakt, zatím nepotvrzeno): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Jméno [Příjmení]> <zlato>  vypsat vlastní odměnu (bez částky: stáhnout)"
L.CHAT_WHO_BOUNTY = "Na koho? /dn bounty <Jméno> <zlato>"
L.CHAT_BOUNTY_SET = "{name}: tvoje odměna {gold}g je vypsaná. Guilda a přátelé s Revenge Book ji vidí."
L.CHAT_BOUNTY_OFF = "{name}: tvoje odměna je stažena."
L.CHAT_BOUNTY_NONE = "{name}: nemáš tu vlastní odměnu."
L.CHAT_BOUNTY_BAD = "Odměna: celé číslo ve zlatě, od 1 do 99999 (0 ji stáhne)."
L.CHAT_BOUNTY_CAP = "Bez odměny: nejvýš {count} vlastních."
L.CHAT_BOUNTY_OURS = "Žádná odměna na sebe ani na své (guilda nebo přátelé s Revenge Book)."
L.ACT_BOUNTY = "Vypsat odměnu"  -- [max 24]
L.ACT_UNDO = "Vrátit zpět"  -- [max 19]
L.ACT_REVENGE_TAKE = "Odečíst jednu pomstu"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, tvoje odměna"
L.POSTER_BOUNTY_BY = "{gold}, vypisuje: {name}"
L.POSTER_BOUNTY_MANY = "Odměna {gold}: {names}"
L.POSTER_AVENGED = "Pomstili: {names}"
L.ROW_AVENGED = "pomstěno {times}"
L.BOUNTY_TIP_HEAD = "Tvoje vlastní odměna ve zlatě"
L.BOUNTY_TIP_RULES = "Celé číslo od 1 do 99999. Prázdné nebo 0: zpět na hodnotu knihy. Enter nastaví, Esc zruší."
L.BOUNTY_TIP_PROMISE = "Guilda a přátelé s Revenge Book ji vidí. Jen slib: vyrovnáte se mezi sebou."
L.BOUNTY_TIP_CLICK = "Klik: vypsat vlastní odměnu"
L.CHAT_AVENGED = "Pomsta za tebe: {killer}, od {name}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: tvoje odměna {gold}g je vypsaná."
L.CHAT_BOUNTY_UNKNOWN = "{name}: není v žádné z tvých knih. Odměna jen na jméno z knihy, tak jak ho ukazuje hra: jméno a příjmení."
L.CHAT_BOUNTY_LIST = "Tvoje odměny ({count} z {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Nemáš žádnou vlastní odměnu."
-- <<< BOOK
-- >>> REPUTE (1.3.0) --------------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Hodnost {tier} · Cesta: {path}"  -- [max 32]
L.PATH_R = "Zlá pověst"  -- [max 16]
L.PATH_E = "Čest"  -- [max 16]
L.PATH_J = "Hon"  -- [max 16]
L.PATH_S = "Ochrana"  -- [max 16]
L.PATH_NONE = "nepopsaná"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) ---------------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "MSTIVÝ?"  -- [max 30]
L.ALERT_LINE_VICTIM = "skóre {score} · tvoje oběť, naposledy {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · skóre {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · {score}, vyrovnáno"
L.ALERT_LINE_STANDING_AHEAD = "{text} · {score}, přeplaceno"
-- <<< ALARM
-- >>> START (1.3.0) ---------------------------------------------------------------------------------------------------
L.SET_THEME = "Vazba"  -- [max 16]
L.START_HINT = "Obojí můžeš později změnit v Domácím řádu."  -- [max 60]
L.START_GO = "Začít"  -- [max 16]
L.START_CLOSE_TIP = "Nechat, jak to je"  -- [max 32]
L.CHAT_THEME_NEWS = "Novinka: kniha je teď i v jiných vazbách. Domácí řád, list Kniha, nebo /dn theme."
L.HELP_START = "/dn start  úvodní okno ještě jednou (jazyk a vazba)"
-- <<< START
-- >>> RECORD (1.3.0) --------------------------------------------------------------------------------------------------
L.TAB_RECORD = "Rejstřík"  -- [max 16]
L.STAMP_QUITT = "VYROVNÁNO"  -- [max 16]
L.STAMP_OVERPAID = "PŘEPLACENO"  -- [max 16]
L.STAMP_NR1_DOWN = "NEPŘÍTEL Č.1 PADL"  -- [max 24]
L.STATE_OPEN = "otevřeno"  -- [max 16]
L.STATE_EVEN = "vyrovnáno"  -- [max 16]
L.STATE_AHEAD = "přeplaceno"  -- [max 16]
L.STATE_VICTIM = "není v knize"  -- [max 24]
L.STAND_LINE = "Skóre {score}"
L.STAND_TIP = "ty {mine}, on {his}"
L.TIP_IN_RECORD = "V REJSTŘÍKU:"
L.TIP_RECORD_LINE = "tvoje zabití: {times}, naposledy {time}"
L.RECORD_HEAD = "Tvůj spis"  -- [max 20]
L.RECORD_LOG_HEAD = "Poslední zabití"  -- [max 20]
L.RECORD_NEXT = "ještě {points} {points|bod|body|bodů} do: {rank}"
L.RECORD_TOP = "Nejvyšší hodnost dosažena."
L.RECORD_BAR_TIP = "{total} z {goal} bodů"
L.RECORD_NEEDLE_LOW = "bezohledný"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "čestný"  -- [max 12]
L.RECORD_NEEDLE_TIP = "Ručička: čest a ochrana proti zlé pověsti. Hon s ní nehne."
L.RECORD_KILLS = "Zabití: {kills} · Oběti: {victims}"
L.RECORD_BEST = "Rekordy: {list}"
L.RECORD_BEST_GAP = "+{count} {count|úroveň|úrovně|úrovní}"
L.RECORD_BEST_STREAK = "série {count}"
L.RECORD_BEST_QUICK = "nejrychlejší pomsta {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} h"
L.RECORD_AWARDS = "VYZNAMENÁNÍ"  -- [max 14]
L.RECORD_AWARD_AT = "uděleno {time}"
L.RECORD_AWARD_OPEN = "zatím neuděleno"
L.RECORD_MORE = "Ukázat víc"  -- [max 19]
L.RECORD_BACK = "Zpět ke spisu"  -- [max 19]
L.RECORD_CLEAR = "Vyčistit rejstřík"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Vyčistit rejstřík?\nVšechny oběti i seznam posledních zabití zmizí. Hodnost, body a vyznamenání zůstanou."
L.CONFIRM_RECORD_CLEAR_OK = "Vyčistit"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Vyškrtnout {name} z rejstříku?\nZískané body zůstanou."
L.ACT_VICTIM_STRIKE = "Vyškrtnout z rejstříku"  -- [max 26]
L.VICTIM_KILLED = "tvoje zabití: {times}"
L.VICTIM_POINTS = "Tvoje body: {points}"
L.VICTIM_SCENE = "Místo činu: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "ZABITÍ"  -- [max 14]
L.KILL_TAG_REVENGE = "pomsta"  -- [max 14]
L.KILL_TAG_KICK = "do ležícího"  -- [max 14]
L.KILL_TAG_GROUP = "skupina"  -- [max 14]
L.KILL_WITH_GROUP = "Se skupinou."
L.BAND_GRAU = "šedá"  -- [max 12]
L.BAND_GRUEN = "zelená"  -- [max 12]
L.BAND_GELB = "žlutá"  -- [max 12]
L.BAND_ORANGE = "oranžová"  -- [max 12]
L.BAND_ROT = "červená"  -- [max 12]
L.BAND_SCHAEDEL = "lebka"  -- [max 12]
L.BAND_UNBEKANNT = "neznámá"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "žádné body"
L.RECORD_BANDS = "Podle barvy úrovně"
L.TIP_PATH_R = "Zlá pověst: zabití šedých a zelených."
L.TIP_PATH_E = "Čest: zabití hráčů tvé úrovně, pomsta."
L.TIP_PATH_J = "Hon: zabití hráčů vyšší úrovně, cílů ze seznamu na odstřel a s odměnou."
L.TIP_PATH_S = "Ochrana: zabití hráčů, kteří zabili někoho z guildy nebo přátel."
L.SORT_STATE = "Skóre"  -- [max 14]
L.SORT_COUNT = "Zabití"  -- [max 14]
L.SORT_POINTS = "Body"  -- [max 14]
L.CHAT_OWN_KILL = "Rejstřík: {name}, {level} ({band}). {points}."
L.CHAT_KILL_WITH_GROUP = "{line} {group}"
L.CHAT_PATH = "Nová cesta: {path}. Hodnost: {rank}."
L.BANNER_RANK = "NOVÁ HODNOST"  -- [max 24]
L.BANNER_AWARD = "VYZNAMENÁNÍ"  -- [max 24]
L.OPT_LEDGER = "Vést rejstřík"  -- [max 44]
L.OPT_LEDGER_CHAT = "Hlásit vlastní zabití v chatu"  -- [max 44]
L.OPT_VICTIMS = "Varovat, když se objeví tvoje oběť"  -- [max 44]
L.SET_SETTLED = "Poplach při vyrovnaném účtu"  -- [max 34]
L.SET_SETTLED_ALWAYS = "jako vždy"  -- [max 10]
L.SET_SETTLED_QUIET = "potichu"  -- [max 10]
L.SET_SETTLED_OFF = "nikdy"  -- [max 10]
L.MANUAL_RECORD_HEAD = "REJSTŘÍK"  -- [max 14]
L.MANUAL_RECORD = "Tvoje zabití hráčů, i ta tvé skupiny s tvou účastí. Plakát a seznam ukazují skóre „ty : on“: otevřeno, vyrovnáno nebo přeplaceno. První místo je vždy otevřené. Zabití dávají body pro tvou hodnost."
L.POSTER_LAST_SEEN_IN = "Poslední spatření: {zone}, {time}"
L.SHEET_RECORD = "Rejstřík"  -- [max 14]
L.EMPTY_RECORD_HEAD = "Zatím nikdo."
L.EMPTY_RECORD_SUB = "Hráč druhé strany, kterého zabiješ, skončí tady."
-- <<< RECORD
-- 1.4.0 grudge
L.GRUDGE_HEAD = "ÚTOK"
L.GRUDGE_IN_BOOK = "v knize"
L.GRUDGE_ADDED = "zapsán"
L.GRUDGE_SKIPPED = "vynechán"
L.GRUDGE_TIP = "Fajfka: do knihy (zášť). Křížek nebo vypršení času: nezapsat. Myš nad oknem zastaví čas; tažení přesune, pravé tlačítko zavře."
L.GRUDGE_TIP_YES = "Do knihy: poplach na něj upozorní."
L.GRUDGE_TIP_NO = "Nezapisovat."
L.GRUDGE_TIP_KB = "Smrtící úder"
L.GRUDGE_TIP_SEEN = "Měl tě v cíli, zatímco tě zasahovali"
L.GRUDGE_TIP_RECAP = "V přehledu tvé smrti"
L.GRUDGE_TIP_METER = "V měřiči poškození po boji"
L.ROLE_ATTACK = "útok"  -- [max 14]
L.TIP_ROLE_ATTACK = "Napadl tě, zapsal jsi ho ty (zášť)."
L.TALLY_ATTACKED = "útoky: {times}"
L.STAMP_GRUDGE = "ZÁŠŤ"  -- [max 16]
L.SET_SEC_GRUDGE = "ZÁŠŤ"  -- [max 24]
L.OPT_GRUDGE = "Zeptat se po útoku (zášť)"  -- [max 44]
L.OPT_GRUDGE_BG = "Také na bojištích a v arénách"  -- [max 44]
L.SET_GRUDGE_SECONDS = "Doba zobrazení"  -- [max 34]
L.SET_GRUDGE_TEST = "Zkušební zpráva"  -- [max 17]
L.SET_GRUDGE_RESET = "Obnovit pozici"  -- [max 24]
L.CHAT_GRUDGE_ON = "Zášť zapnuta: po útoku se malá zpráva zeptá, zda útočníka zapsat do knihy."
L.CHAT_GRUDGE_OFF = "Zášť vypnuta: po útocích žádná zpráva."
L.CHAT_GRUDGE_TEST = "Zkušební zpráva s vymyšlenými jmény: fajfka ani křížek nic nezapíšou."
L.HELP_GRUDGE = "/dn grudge  zpráva po útocích zap./vyp. (test: zkušební zpráva)"

-- >>> OVERVIEW (UI.lua, Store.lua, Core.lua: taking over, sorting, filter, section heads) ---------------------------
-- 1.4.0 overview
L.SORT_KILLS = "Zabití mě"
L.SORT_LEVEL = "Úroveň"
L.SORT_CLASS = "Povolání"
L.SORT_BOUNTY = "Odměna"
L.SORT_ONLY_NEW = "Jen co mi chybí"
L.SORT_ALL_ROWS = "Ukázat vše"
L.FILTER_WORD = "Filtr"
L.FILTER_TIP = "Ukázat jen:"
L.FILTER_ALL = "Všichni"
L.FILTER_KILL = "Zabil mě"
L.FILTER_ASSIST = "Podílel se"
L.FILTER_ATTACK = "Zášť"
L.FILTER_MANUAL = "Zapsáno ručně"
L.FILTER_ADOPTED = "Převzato"
L.FILTER_CLASS = "Povolání …"
L.FILTER_BACK = "‹ Zpět"
L.FILTER_HINT = "{shown} z {total} · ukázat vše"
L.SECTION_SETTLED = "Vyrovnáno"
L.SECTION_SETTLED_SUB = "jsi vyrovnaný nebo napřed"
L.SECTION_PARDONED = "Omilostnění"
L.SECTION_PARDONED_SUB = "žádný poplach, nepočítají se"
L.ACT_TAKE = "Převzít"
L.ACT_TAKE_ALL = "Převzít vše"
L.ACT_TAKE_ALL_OF = "Převzít vše od {name}"
L.ROW_TAKE = "převzít"
L.TIP_ROW_TAKE = "Do tvé knihy (původ se poznamená)."
L.TAKE_HEAD = "Převzít vše"
L.TAKE_FROM_MATE = "Od {name}"
L.TAKE_FROM_GUILD = "Z knihy guildy"
L.TAKE_FROM_FRIENDS = "Z knihy přátel"
L.TAKE_FROM_ALL = "Z guildy a od přátel"
L.TAKE_COUNT = "Nové: {new} · už v tvé knize: {have}"
L.TAKE_NEW_LABEL = "Nové"
L.TAKE_MORE = "a další: {count}"
L.TAKE_HINT = "Přijdou do tvé knihy jako převzaté, s původem. Jejich smrti se nepočítají jako tvoje a nic z toho se nesdílí dál."
L.TAKE_HINT_FRIENDS = "Od přátel přijdou jen jejich jisté smrti (posledních 30) a ručně zapsaná jména, a jen když jste oba online. Celá kniha: u přítele Zálohovat knihu, u tebe Načíst knihu."
L.TAKE_NONE = "Všechno už je v tvé knize."
L.TAKE_DONE = "Převzato: {count}."
L.TAKE_UNDONE = "Vráceno: {count} opět škrtnuto."
L.TAKE_ONE_DONE = "Převzato: {name}."
L.BTN_DONE = "Hotovo"
L.IO_OWNER = "Čí kniha"
L.IO_MINE = "moje"
L.IO_THEIRS = "{name}"
L.IO_THEIRS_ANON = "někoho jiného"
L.IO_PREVIEW = "V textu: {total} · nové: {new} · už v tvé knize: {have}"
L.IO_PREVIEW_FRIEND = "Hledaní tam a pro tebe noví: {new} · už v tvé knize: {have}"
L.IO_HINT_MINE = "Jako záloha: vše se sloučí, smrti se počítají jako tvoje."
L.IO_HINT_FRIEND = "Jen nová jména, označená jako převzatá; smrti přítele se nepočítají jako tvoje."
L.IO_GO_NOW = "Načíst teď"
L.IO_TAKEN = "Převzato: {new}. Už v tvé knize: {have}."
L.NOTE_ADOPTED_GUILD = "Převzato z knihy guildy, od {name} (zabití členů guildy: {kills}×)."
L.NOTE_ADOPTED_FRIEND = "Převzato od {name} (zabití přátel: {kills}×)."
L.NOTE_ADOPTED_TEXT = "Načteno z knihy hráče {name} (zabití tam: {kills}×)."
L.NOTE_ADOPTED_TEXT_ANON = "Načteno z cizí knihy (zabití tam: {kills}×)."
L.TALLY_ADOPTED = "převzato od {name}"
L.TALLY_ADOPTED_ANON = "převzato"
L.POSTER_FRIENDSBOOK = "KNIHA PŘÁTEL"
L.EMPTY_FILTERED_HEAD = "Nic nenalezeno."
L.EMPTY_FILTERED_SUB = "Filtr skryl všechny. Dole: ukázat vše."
L.EMPTY_ALLTAKEN_HEAD = "Všechno už je v tvé knize."
L.EMPTY_ALLTAKEN_SUB = "Nic dalšího k převzetí. Dole: ukázat vše."
-- <<< OVERVIEW
-- 1.4.0 fixer
L.TAKE_UNDONE_KEPT = "Vráceno: {count} opět škrtnuto. {kept} zůstává: mezitím přibyla vlastní data."
L.FILTER_HIDDEN = "Skryto filtrem: {count} · ukázat vše"
L.EMPTY_HIDDEN_HEAD = "Skryto filtrem."
L.EMPTY_HIDDEN_SUB = "Enter nebo řádek dole je ukáže."
L.EMPTY_SEARCHHAS_HEAD = "Už je ve tvé knize."
L.EMPTY_SEARCHHAS_SUB = "Jen ne na této stránce. Enter ho otevře."
L.FILTER_TWO = "Filtry: {count}"
L.GRUDGE_TIP_OFF = "Vypnutí: /dn grudge nebo {rules}, list {sheet}."
-- 1.5.0 grip
L.GRUDGE_TIP_PROBABLE = "Nejisté: málo stop. Zaškrtni, jen když jsi ho viděl."
L.GRUDGE_TIP_MOB = "Současně na tebe útočil tvor"
L.GRUDGE_TIP_CAST = "Sesílal kouzlo, když tě zasahovali"
L.GRUDGE_TIP_JOIN = "Vstoupil do boje s tvým zásahem"
L.GRUDGE_TIP_REPEAT = "Měl tě v cíli při více zásazích"
L.SET_GRUDGE_SIZE = "Velikost hlášení"  -- [max 34]
L.SIZE_SMALL = "malé"  -- [max 10]
L.SIZE_MEDIUM = "střední"  -- [max 10]
L.SIZE_LARGE = "velké"  -- [max 10]
L.SET_SEC_PLATE = "JMENOVKY"  -- [max 24]
L.SET_PLATE = "Značka nad nepřáteli z knihy"  -- [max 34]
L.BIND_TOGGLE = "Otevřít nebo zavřít knihu"
L.BIND_ADD = "Cíl do knihy"
L.BIND_HUNT = "Cíl na seznam honu"
L.BIND_ALARM = "Poplach vyp. / zap."
L.GRIP_NO_TARGET = "Žádný cíl: nejdřív zaměř nepřátelského hráče."
L.GRIP_NOT_ENEMY = "Tvůj cíl není nepřátelský hráč."
L.GRIP_ALREADY = "{name}: už je v knize."
L.GRIP_HUNT_WHY = "Označen v boji"  -- [max 40]
L.GRIP_HUNT_CHANGE = "Důvod: „{why}“. Změna: „{action}“ v knize."
-- 1.5.0 share
L.ACT_SHARE = "Vyvěsit"
L.SHARE_HEAD = "Ukázat v chatu"
L.SHARE_TAB_LINE = "Plakát"
L.SHARE_TAB_WEEK = "Můj týden"
L.SHARE_TAB_DISCORD = "Discord"
L.SHARE_PREVIEW = "Tento řádek odejde"
L.SHARE_CH_GUILD = "Cech"
L.SHARE_CH_PARTY = "Skupina"
L.SHARE_CH_RAID = "Raid"
L.SHARE_CH_INSTANCE = "Instance"
L.SHARE_CH_SAY = "Říct"
L.SHARE_SENT = "Vyvěšeno v: {channel}."
L.SHARE_WAIT = "Jeden řádek za 10 sekund. Znovu za {seconds} s."
L.SHARE_LOCKED = "Chat je tu teď zablokovaný."
L.SHARE_COMBAT = "Ne v boji. Klikni znovu po boji."
L.SHARE_FAILED = "Hra řádek neodeslala."
L.SHARE_HINT = "Prostý text pro všechny; s addonem je jméno odkaz."
L.SHARE_DISCORD_HINT = "Označeno: Ctrl+C kopíruje. Poznámky nikdy nejdou."
L.SHARE_CLOSE = "Zavřít"
L.SHARE_KILLED_ME = "zabil mě {times}"
L.SHARE_BOUNTY = "odměna {gold}"
L.SHARE_SEEN = "naposledy viděn: {zone}"
L.SHARE_DEED_AT = "poslední čin: {place}"
L.SHARE_REVENGE_NOW = "teď {score}"
L.SHARE_KIND_PARDONED = "OMILOSTNĚN"
L.SHARE_WEEK_HEAD = "MŮJ TÝDEN"
L.SHARE_WEEK_TOP = "nejhledanější, zabil mě {times}"
L.SHARE_WEEK_NONE = "nikdo mě nezabil"
L.SHARE_WEEK_REVENGE = "pomsty: {count}"
L.SHARE_WEEK_DEBTS = "otevřené účty: {count}"
L.SHARE_DC_LAST = "Poslední čin: {place}, {time}"
L.SHARE_GUEST_BY = "vyvěsil {name}"
L.SHARE_GUEST_SAYS = "Řádek říká"
L.SHARE_GUEST_HINT = "Jen to, co říká řádek. V žádné z tvých knih."
L.SET_SEC_SHOW = "VYVĚSIT"
L.OPT_SHARE_REVENGE = "Tlačítko „Vyvěsit“ u zprávy o pomstě"
-- 1.5.0 scene
L.SET_SEC_MAP = "MAPA"  -- [max 24]
L.OPT_SCENE = "Místa činu na mapě světa"  -- [max 44]
L.OPT_SCENE_OPEN = "Jen otevřené dluhy"  -- [max 32]
L.SCENE_DAYS_ALL = "vše"  -- [max 10]
L.SCENE_DAYS_LINE = "Období: {days}"  -- [max 32]
L.SCENE_KIND_OWN = "Moje smrti a zabití"  -- [max 32]
L.OPT_G_SENDPLACE = "Posílat místo mé smrti"  -- [max 44]
L.SCENE_MAP_TIP = "Místa činu z tvé knihy"
L.SCENE_MAP_CLICK = "Klik: filtrovat místa činu"
L.SCENE_SOMEONE = "někdo"
L.SCENE_TIP_DEATH = "Tady tě zabil {killer}"
L.SCENE_TIP_DEATH_UNCLEAR = "Tady jsi zemřel; vrah je nejasný"
L.SCENE_TIP_KILL = "Tady jsi skolil: {name}"
L.SCENE_TIP_MATE = "Tady zemřel {victim}. Vrah: {killer}"
L.SCENE_REVENGE = "Pomsta vykonána"
L.SCENE_SRC_GUILD = "Cech"
L.SCENE_SRC_FRIEND = "Přítel"
L.SCENE_FRESH = "{ago}: ještě blízko, běž pomoct"
L.SCENE_BUNDLE = "Míst činu zde: {count}"
L.SCENE_TIP_CLICK = "Klik: otevřít tu knihu"
L.SCENE_SHOW = "Klik: ukázat na mapě"
L.SCENE_NO_SPOT = "Přesné místo neznámé: tady je zóna."
L.SCENE_NO_MAP = "Pro toto místo není známa mapa."
L.SCENE_COMBAT = "V boji zůstává mapa zavřená. Klikni znovu po boji."
L.CHRON_OPEN = "Kronika"  -- [max 14]
L.CHRON_HEAD = "Kronika"  -- [max 20]
L.CHRON_BACK = "Zpět na plakát"  -- [max 19]
L.CHRON_EMPTY = "Zatím nic nezapsáno."
L.CHRON_AT = "{date}, {place}:"
L.CHRON_AT_DAY = "{date}:"
L.CHRON_FIRST = "První setkání: {date}, {place}."
L.CHRON_FIRST_DAY = "První setkání: {date}."
L.CHRON_KILL_SPELL = "{name} tě dostane: {spell}."
L.CHRON_KILL = "{name} tě zabije."
L.CHRON_KILL_AGAIN = "{name} udeří znovu."
L.CHRON_ASSIST = "{name} pomáhá tě zabít."
L.CHRON_ASSIST_AGAIN = "{name} je v tom zase."
L.CHRON_SUSPECT = "Podezření: {name} tě měl v cíli, když jsi zemřel."
L.CHRON_SUSPECT_AGAIN = "Znovu podezření: {name}."
L.CHRON_ATTACK = "Útok: {name} se na tebe vrhne, unikneš."
L.CHRON_ATTACK_AGAIN = "{name} tě znovu napadne."
L.CHRON_MINE_FIRST = "Poprvé dostaneš: {name}."
L.CHRON_MINE = "Skolíš: {name}."
L.CHRON_MINE_AGAIN = "{name} znovu padne tvou rukou."
L.CHRON_HAND = "Zapíšeš pomstu: {name}."
L.CHRON_HAND_AGAIN = "Další pomsta zapsána: {name}."
L.CHRON_LISTED = "Zapíšeš ručně do knihy: {name}."
L.CHRON_COPIED = "Zkopírováno od: {from}."
L.CHRON_COPIED_ANON = "Zkopírováno z cizí knihy."
L.CHRON_BOUNTY = "{by} vypíše odměnu {gold}: {name}."
L.CHRON_BOUNTY_MINE = "Vypíšeš odměnu {gold}: {name}."
L.CHRON_EVEN = "Teď nastejno: {score}."
L.CHRON_AHEAD = "Teď vedeš: {score}."
L.CHRON_AVENGED = "{names} skolili {name} za ostatní."
L.CHRON_PARDONED = "Omilostnil jsi: {name}."
L.CHRON_END = "Teď: {score} · {state}"
L.CHRON_END_NONE = "Zatím: {name} tě zabil {times}."
-- 1.5.0 name
L.HELP_ALIASES = "/rb, /revengebook  totéž co /dn"
L.CHAT_NEWS_150 = "DeathNote se teď jmenuje Revenge Book. Tvoje kniha i /dn zůstávají. Novinky v 1.5.0: ukázat plakát v chatu, místa činu na mapě světa, klávesové zkratky, značka na jmenovkách tvých vrahů."
-- 1.5.0 fix
L.SCENE_TIP_SUSPECT = "Tady jsi zemřel; podezření: {name}"
L.CHRON_EARLIER = "Starší činy už v knize nejsou."
L.GRUDGE_TIP_PET = "Jeho mazlíček tě taky napadl"
L.SHARE_GUEST_WEEK = "Týden: {name}"
L.SCENE_TIP_PICK = "Klik: vybrat místo činu"
L.SCENE_LEG_DEATH = "tvoje smrt"
L.SCENE_LEG_KILL = "tvůj úlovek"
L.SCENE_LEG_BUNDLE = "více míst činu"
L.SET_HINT_FRIENDS_POST = "Sdílení a poplach jen pro guildu a přátele s Revenge Book. Co vyvěsíš, čte v chatu každý."
L.SET_HINT_GUILD_POST = "Sdílení a poplach jen pro tvoji guildu. Co přijde odtamtud, zůstává odděleně od tvé knihy, dokud si to nepřevezmeš. Co vyvěsíš, čte v chatu každý."
end)
