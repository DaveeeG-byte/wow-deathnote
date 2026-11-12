-- DeathNote: Magyar (huHU).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.huHU), not here.
-- Hungarian keeps the noun singular after a number ("3 gyilkos"), so no text needs a plural construct.
-- Fonts: latinExt (Nimrod MT, Arial Narrow) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Terms: book könyv, guild book céhkönyv, friends' book baráti könyv, killer gyilkos, guildmate céhtárs,
-- Hit List halállista, call kiírás. No suffix is attached to {name}/{zone}: colon forms instead.
--
-- TOC-Notes: Halállista nyílt világú PvP-hez: megjegyzi, ki ölt meg, és szól, ha a közelben van.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("huHU")) then return end

Locale.Register("huHU", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Körözött"  -- [max 16]
L.TAB_UNSOLVED = "Tisztázatlan"  -- [max 16]
L.TAB_DEATHLOG = "Halálnapló"  -- [max 16]
L.TAB_GUILD = "Céh"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Házirend"  -- [max 24]
L.HEAD_HELP = "Használati útmutató"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Könyv"  -- [max 14]
L.SHEET_ALERT = "Riasztás"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "1. SZÁMÚ KÖZELLENSÉG"  -- [max 24]
L.STAMP_REVENGE = "MEGBOSSZULVA"  -- [max 16]
L.STAMP_PARDONED = "KEGYELMET KAPOTT"  -- [max 16]
L.STAMP_SUSPECT = "GYANÚSÍTOTT"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "1. SZÁMÚ KÖZELLENSÉG ÉSZLELVE"  -- [max 30]
L.ALERT_SIGHTED = "KÖZELLENSÉG ÉSZLELVE"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "GYANÚSÍTOTT ÉSZLELVE"  -- [max 30]
L.ALERT_TITLE_GUILD = "CÉHELLENSÉG ÉSZLELVE"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "BARÁTOK GYILKOSA ÉSZLELVE"  -- [max 30]
L.ALERT_TITLE_HUNT = "HALÁLLISTA CÉLPONTJA"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "gyanú alatt áll"
L.ALERT_LINE_KILLED = "{times} megölt téged"
L.ALERT_LINE_KILLED_ASSISTED = "{times} megölt téged, {assists} segédkezett"
L.ALERT_LINE_ASSISTED = "{times} segédkezett a halálodban"
L.ALERT_LINE_MANUAL = "kézzel került a könyvbe"
L.ALERT_LINE_LAST = "{text}, utoljára {time}"
L.ALERT_LINE_IN = "{text}, helyszín: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Bosszú: {times}"
L.ALERT_HINT_CLOSE = "Jobb klikk: bezárás"  -- [max 44]
L.ALERT_HINT_COMBAT = "Célba venni csak a harc után lehet"  -- [max 44]
L.ALERT_HINT_TARGET = "Klikk: célba vesz  ·  Jobb klikk: bezárás"  -- [max 44]
L.ALERT_MORE = "+{count} további"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "benne van a céhkönyvben"
L.GUILD_LINE_IN_FRIENDS = "benne van a baráti könyvben"
L.GUILD_LINE_LISTED_BY = "bejegyezte: {names}"
L.GUILD_LINE_KILLED_GUILD = "{kills}× ölt céhtársat"
L.GUILD_LINE_KILLED_FRIENDS = "{kills}× ölt barátot"
L.GUILD_LINE_KILLED_BOTH = "{kills}× ölt céhtársat és barátot"
L.GUILD_LINE_LAST = "{text}, utolsó áldozat: {name}"
L.HUNT_LINE_BY = "a vadászatot kiírta: {names}"
L.HUNT_LINE_RELEASED = "a halállistán"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "gyanú alatt"
L.TALLY_MANUAL = "kézzel bejegyezve"
L.TALLY_NONE = "még nincs tett"
L.TALLY_KILLED = "{times} megölt téged"
L.TALLY_ASSISTED = "{times} segédkezett"
L.PLACE_UNKNOWN = "ismeretlen hely"
L.GKILLS_CAP = "legalább {count}"
L.NAMELIST_MORE = "{names} és még {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%m.%d. %H:%M"
L.TIME_FMT_WHEN_YEAR = "%Y.%m.%d. %H:%M"
L.TIME_FMT_DAY = "%m.%d."
L.TIME_FMT_DAY_YEAR = "%y.%m.%d."
L.TIME_NEVER = "soha"
L.TIME_JUST = "épp most"
L.TIME_MINUTES = "{count} perce"  -- [max 14]
L.TIME_HOURS = "{count} órája"  -- [max 14]
L.TIME_DAYS = "{count} napja"  -- [max 16]
L.MONEY_GOLD = "{count} arany"
L.MONEY_SILVER = "{count} ezüst"
L.MONEY_COPPER = "{count} réz"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "DeathNote-os céhtársak: {count}."
L.HEALTH_NOGUILD = "Nem vagy céhben, semmi sincs megosztva."
L.HEALTH_OFF = "A megosztás ki van kapcsolva."
L.HEALTH_SHORT_NOGUILD = "Nincs céh"  -- [max 18]
L.HEALTH_SHORT_OFF = "Megosztás ki"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Letiltva"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Elutasítva"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Várakozik"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Lekérdezve"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Nem működik"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Nincs hang"  -- [max 16]
L.SOUND_RAIDWARNING = "Raid-riasztás"  -- [max 16]
L.SOUND_BELL = "Harang"  -- [max 16]
L.SOUND_GONG = "Gong"  -- [max 16]
L.SOUND_HEARTBEAT = "Szívverés"  -- [max 16]
L.SOUND_FEATHER = "Lúdtoll"  -- [max 16]
L.SOUND_SIREN = "Sziréna"  -- [max 16]
L.CHANNEL_MASTER = "Fő hangerő"  -- [max 16]
L.CHANNEL_SFX = "Effektek"  -- [max 16]
L.CHANNEL_DIALOG = "Párbeszéd"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name} bekerült a könyvbe."
L.CHAT_REMOVED = "{name} kihúzva a könyvből."
L.CHAT_SYNC_WAIT = "Épp most volt egyeztetés. Próbáld újra {seconds} mp múlva."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Még nincs név."
L.EMPTY_WANTED_SUB = "Menj ki néha a levegőre."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  a könyv kinyitása/becsukása"
L.HELP_ADD = "/dn add <Név [Vezetéknév]>  gyilkos kézi beírása a könyvbe"
L.HELP_DEL = "/dn del <Név [Vezetéknév]>  gyilkos kihúzása a könyvből"
L.HELP_QUIET = "/dn quiet  riasztás ki/be"
L.HELP_TEST = "/dn test  próbariasztás"
L.HELP_GUILD = "/dn guild  céhkönyv: állapot, és mely céhtársaknak van DeathNote-ja"
L.HELP_FRIENDS = "/dn friends  baráti könyv: állapot, és mely barátoknak van DeathNote-ja"
L.HELP_SYNC = "/dn sync  a céhkönyv és a baráti könyv egyeztetése most"
L.HELP_HUNT = "/dn hunt <Név [Vezetéknév]>  vadászat kiírása (név nélkül: a halállista)"
L.HELP_CALLOFF = "/dn calloff <Név [Vezetéknév]>  a saját vadászatod lefújása"
L.HELP_LANG = "/dn lang <kód>  a könyv nyelve (enUS, deDE, frFR ...), /reload után"
L.HELP_THEME = "/dn theme <név>  a könyv borítója, /reload után"
L.HELP_PROBE = "/dn probe  hibakeresés: mit árul el a játék a könyvnek"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  hibakeresés, a harcnapló vizsgálatával"
L.HELP_DEBUG = "/dn debug  hibakeresés: minden halál részletes naplózása (be/ki)"
L.HELP_HELP = "/dn help  ez a súgó"
L.HELP_SILENT_ZONES = "Dungeonben, csatatéren és arénában a könyv magától hallgat."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "be"
L.WORD_OFF = "ki"
L.CHAT_WHO_ADD = "Kit? /dn add <Név>"
L.CHAT_WHO_DEL = "Kit? /dn del <Név>"
L.CHAT_WHO_CALLOFF = "Kit? /dn calloff <Név>"
L.CHAT_BAD_NAME = "Érvénytelen név."
L.CHAT_NOT_IN_BOOK = "Nincs a könyvben: {name}"
L.CHAT_ALARM_ON = "Riasztás be."
L.CHAT_ALARM_OFF = "Riasztás ki."
L.CHAT_DEBUG = "Hibakeresési napló: {state}."
L.CHAT_UNKNOWN_CMD = "Ismeretlen parancs. Súgó: /dn help"
L.CHAT_GUILD_NOT_LOADED = "A céhkönyv nincs betöltve."
L.CHAT_NO_GUILD = "Nem vagy céhben (vagy a játék még nem tud róla)."
L.CHAT_GUILD_STATE = "Céh: {guild} · megosztás {share}, fogadás {receive}."
L.CHAT_GUILD_BOOK = "Céhkönyv: {enemies} gyilkos ({listed} csak kézzel bejegyezve), {deeds} tett, {foreign} céhtársakat is érint. Kézi bejegyzések megosztása: {manual}."
L.CHAT_STATE_OK = "Állapot: {text}"
L.CHAT_STATE_WARN = "Figyelem: {text}"
L.CHAT_NO_MATES = "Még nem jelentkezett céhtárs DeathNote-tal."
L.CHAT_HAVE_DN = "DeathNote-ot használ: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote-ot használ: {names} és még {count}"
L.CHAT_SYNC_ASKED = "Egyeztetés kérve. A válaszok a következő másodpercekben jönnek."
L.CHAT_SYNC_FAIL = "Az egyeztetés nem megy: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "nincs céh, vagy ki van kapcsolva a megosztás."
L.CHAT_FRIENDS_NOT_LOADED = "A baráti könyv nincs betöltve."
L.CHAT_FRIENDS_STATE = "Barátok: megosztás {share}, online: {online}/{total}."
L.CHAT_FRIENDS_BOOK = "Baráti könyv: {enemies} gyilkos ({listed} csak kézzel bejegyezve), {deeds} tett."
L.CHAT_NO_FRIENDS = "Még nem jelentkezett barát DeathNote-tal."
L.CHAT_HUNT_NOT_LOADED = "A halállista nincs betöltve."
L.CHAT_HUNT_UNKNOWN = "Ismeretlen: {name}. Add meg a vezetéknevet is, ahogy a név a játékban látszik."
L.CHAT_HUNT_CAP = "Nem tehető halállistára: listánként legfeljebb {own} saját kiírás és {targets} célpont lehet."
L.CHAT_HUNT_NOWHERE = "Most nem tehető halállistára: nincs céh, és a megosztás a barátokkal ki van kapcsolva."
L.CHAT_HUNT_BOTH = "{name} felkerült a halállistára, a céhnek és a barátoknak."
L.CHAT_HUNT_GUILD = "{name} felkerült a halállistára, a céhnek."
L.CHAT_HUNT_FRIENDS = "{name} felkerült a halállistára, a barátaidnak."
L.CHAT_CALLED_OFF = "Vadászat lefújva: {name}"
L.CHAT_NO_OWN_CALL = "Nincs saját kiírásod rá: {name}"
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Nyelv most: {lang}. Módosítás: /dn lang <kód>"
L.CHAT_LANG_LIST = "Kódok: {codes}"
L.CHAT_LANG_BAD = "Ismeretlen nyelv: {code}"
L.CHAT_LANG_SET = "Nyelv: {lang}."
L.CHAT_LANG_RELOAD = "Nyelv: {lang}. /reload után lép életbe."
L.CHAT_THEME_CURRENT = "Borító most: {theme}. Módosítás: /dn theme <név>"
L.CHAT_THEME_LIST = "Borítók: {themes}"
L.CHAT_THEME_BAD = "Ismeretlen borító: {name}"
L.CHAT_THEME_SET = "Borító: {theme}."
L.CHAT_THEME_RELOAD = "Borító: {theme}. /reload után lép életbe."
L.THEME_NOTEBOOK = "A fekete könyv"
L.THEME_HARBOR = "Kalózkönyv"
L.THEME_TRADE = "Szakszerviz"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "A könyv készen áll. Aki megöl a nyílt világban, utána benne lesz. Kinyitás: /dn vagy a minitérkép-gomb."
L.WELCOME_PLATES = "Az ellenséges névtáblák ki vannak kapcsolva. Nélkülük a riasztás csak a célpontodat látja."
L.WELCOME_SHARE = "A DeathNote-os céhtársak és barátok is olvassák. A jegyzetek és a gyanúk nálad maradnak."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "A KÖNYVBEN:"
L.TIP_HUNT = "HALÁLLISTA:"
L.TIP_GUILDBOOK = "CÉHKÖNYV:"
L.TIP_PARDONED = "megkegyelmezve"
L.TIP_RANK = "{rank}. hely"
L.TIP_REVENGE = "bosszú {times}"
L.TIP_LISTED_BY = "bejegyezte: {names}"
L.TIP_NOTE = "Jegyzet: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Klikk: kinyit · Jobb klikk: eltüntet"
L.BANNER_NEW = "ÚJ BEJEGYZÉS"  -- [max 24]
L.BANNER_NEW_LINE = "bekerült a könyvbe"
L.BANNER_AGAIN = "MEGINT"  -- [max 24]
L.BANNER_AGAIN_LINE = "megint megölt, már {count}. alkalommal"
L.BANNER_SUSPECT = "GYANÚ"  -- [max 24]
L.BANNER_SUSPECT_LINE = "gyanú alatt áll, tisztázd a könyvben"
L.BANNER_UNCLEAR = "GYILKOS TISZTÁZATLAN"  -- [max 24]
L.BANNER_CANDIDATES = "{count} jelölt"
L.BANNER_UNCLEAR_LINE = "Klikk: válaszd ki a gyilkost a Tisztázatlan lapon"
L.BANNER_REVENGE = "TÖRLESZTVE"  -- [max 24]
L.BANNER_REVENGE_LINE = "Megbosszulva ({count}×)"
L.BANNER_GUILD = "CÉH"  -- [max 24]
L.BANNER_FRIENDS = "BARÁTOK"  -- [max 24]
L.BANNER_KILLED_BY = "megölték, a gyilkos: {name}"
L.BANNER_HUNT = "HALÁLLISTA"  -- [max 24]
L.BANNER_BAGGED = "leterítette: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "A megosztás ki van kapcsolva (Házirend, Céh lap)."
L.SYNC_FRIENDS_OFF = "A megosztás a barátokkal ki van kapcsolva."
L.SYNC_NOBODY = "Nincs céh és nincs barát, akivel megoszthatnád."
L.SYNC_SHORT_NOBODY = "Nincs megosztás"  -- [max 18]
L.SYNC_PREFIX = "A játék nem enged fogadni. Az újbóli belépés segít."
L.SYNC_SHORT_PREFIX = "Nincs fogadás"  -- [max 18]
L.SYNC_BLOCKED = "A szerver tiltja a küldést. Add tovább a Könyv mentésével."
L.SYNC_SHORT_BLOCKED = "Küldés letiltva"  -- [max 22]
L.SYNC_FAILING = "A küldés most nem sikerül, újra próbálkozik."
L.SYNC_SHORT_FAILING = "Küldés akadozik"  -- [max 18]
L.SYNC_HOLD = "A küldés vár, {wait}."
L.SYNC_HOLD_INSTANCE = "amíg el nem hagyod az instance-t"
L.SYNC_HOLD_COMBAT = "amíg ki nem lépsz a harcból"
L.SYNC_HOLD_LOCKDOWN = "amíg a chat újra szabad nem lesz"
L.SYNC_HOLD_AGAIN = "amíg újra nem megy"
L.SYNC_HOLD_SHORT_INSTANCE = "Vár: instance"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Vár: harc"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Vár: chat"  -- [max 18]
L.SYNC_QUIET = "Elküldve, de még nem jelentkezett céhtárs DeathNote-tal."
L.SYNC_READY = "Kész. Még nem jelentkezett céhtárs DeathNote-tal."
L.SYNC_RUNNING = "Működik: {count} DeathNote-os céhtárs."
L.SYNC_RUNNING_ALL = "Működik: {count} DeathNote-os a céhben és a barátok közt."
L.FRIENDS_OFF = "A megosztás a barátokkal ki van kapcsolva (Házirend, Céh lap)."
L.FRIENDS_BLOCKED = "A szerver tiltja a suttogást. A barátok semmit sem kapnak."
L.FRIENDS_SHORT_BLOCKED = "Suttogás letiltva"  -- [max 22]
L.FRIENDS_FAILING = "A suttogás most nem sikerül, újra próbálkozik."
L.FRIENDS_SHORT_FAILING = "Suttogás akadozik"  -- [max 18]
L.FRIENDS_NONE_LISTED = "Senki sincs a barátlistán."
L.FRIENDS_NONE_ONLINE = "Most egy barát sincs online."
L.FRIENDS_SHORT_NONE_ONLINE = "Nincs online barát"  -- [max 18]
L.FRIENDS_QUIET = "Megkérdezve, de még nem jelentkezett barát DeathNote-tal."
L.FRIENDS_READY = "Kész. Még nem jelentkezett barát DeathNote-tal."
L.FRIENDS_HOLD = "A küldés a barátoknak vár, amíg újra nem megy."
L.FRIENDS_RUNNING = "Működik: {count} DeathNote-os barát."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Átvéve a céhkönyvből ({kills}× ölt céhtársat)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Az adatbázis nincs betöltve."
L.IMPORT_NO_TEXT = "Nincs szöveg."
L.IMPORT_NO_HEADER = "Hiányzik az első sor (így kezdődik: {header}). Másold ki az egész szöveget."
L.IMPORT_NOT_EXPORT = "Ez nem DeathNote-export (hiányzik a fejléc, vagy rossz a verzió)."
L.IMPORT_TOO_LONG = "Túl sok sor (legfeljebb {count})."
L.IMPORT_BAD_KEY = "{line}. sor: érvénytelen kulcs."
L.IMPORT_BAD_TIME = "{line}. sor: érvénytelen idő."
L.IMPORT_BROKEN = "{line}. sor: hiányos vagy sérült (levágódott a szöveg?). Semmi sem lett betöltve."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "igen"
L.WORD_NO = "nem"
L.PROBE_HEAD = "Szonda: {apis}/{apisAll} interfész megvan, {events}/{eventsAll} esemény regisztrálható."
L.PROBE_MISSING = "Hiányzik: {list}"
L.PROBE_NOT_REGISTERABLE = "Nem regisztrálható: {list}"
L.PROBE_SOURCES = "Recap most: {recap} · Meter: {meter} · Harcnapló: {clog}"
L.PROBE_READABLE = "olvasható"
L.PROBE_DEAD = "halott"
L.PROBE_PLATES = "Ellenséges névtáblák: {plates} · Nyílt világ: {open}"
L.PROBE_PLATES_OFF = "KI (csak a célpont és az egér alatti játékos látszik)"
L.PROBE_TARGET = "Célpont: név={name} GUID={guid} kaszt={class} ellenséges={enemy} engem céloz={me}"
L.PROBE_GUILD = "Céh: előtag {prefix} · küldés {send} · utolsó visszatérési érték {result} · küldve {sent}, fogadva {received}, eldobva {dropped}"
L.PROBE_REGISTERED = "regisztrálva"
L.PROBE_NOT_REGISTERED = "NINCS regisztrálva ({result})"
L.PROBE_POSSIBLE = "lehetséges"
L.PROBE_ABSENT = "hiányzik"
L.PROBE_WAITS = " · vár: {why}"
L.PROBE_LISTED = "Kézi bejegyzések (M): küldve {sent}, fogadva {received}, eldobva {dropped} · kihúzva (X): küldve {usent}, fogadva {ureceived}, eldobva {udropped}"
L.PROBE_GUILDBOOK = "Céhkönyv: {text}"
L.PROBE_SAVED = "Mentve: DeathNoteDB.probe (/reload után a fájlban)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Legújabb"  -- [max 14]
L.SORT_NAME = "Név"  -- [max 14]
L.SORT_SEEN = "Észlelve"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Aki megöl a nyílt világban, ide kerül. Magától."
L.EMPTY_OPEN_HEAD = "Nincs tisztázatlan eset."
L.EMPTY_JOURNAL_HEAD = "Még sosem haltál meg."
L.EMPTY_JOURNAL_SUB = "Tisztelet. Vagy hazugság."
L.EMPTY_NOGUILD_HEAD = "Nincs céh."
L.EMPTY_NOGUILD_SUB = "Egyedül is meg lehet halni."
L.EMPTY_GUILDOFF_HEAD = "A céhkönyv be van csukva."
L.EMPTY_GUILDOFF_SUB = "A megosztás ki van kapcsolva. A Házirend tudja, hol."
L.EMPTY_GUILDNIL_HEAD = "Még semmi hír a céhből."
L.EMPTY_GUILDNIL_SUB = "A könyved útnak indul, amint egy céhtársnak is lesz DeathNote-ja."
L.EMPTY_GUILDQUIET_HEAD = "A céhkönyvben még nincs semmi."
L.EMPTY_GUILDQUIET_SUB = "A céhtársaidnak eddig nyugtuk volt."
L.EMPTY_FRIENDSOFF_HEAD = "A baráti könyv be van csukva."
L.EMPTY_FRIENDSOFF_SUB = "A megosztás a barátokkal ki van kapcsolva. A Házirend tudja, hol."
L.EMPTY_FRIENDSNIL_HEAD = "Még nem jelentkezett barát DeathNote-tal."
L.EMPTY_FRIENDSNIL_SUB = "A könyved útnak indul, amint egy barátodnak is lesz DeathNote-ja."
L.EMPTY_FRIENDSQUIET_HEAD = "A barátaidtól még nincs semmi."
L.EMPTY_FRIENDSQUIET_SUB = "A barátaidnak eddig nyugtuk volt."
L.EMPTY_NOBODY_HEAD = "Nincs céh, nincsenek barátok."
L.EMPTY_NOBODY_SUB = "Egyedül is meg lehet halni."
L.EMPTY_NOBODY_HINT = "Ha a céhtársaidnak vagy a barátlistádon lévő barátaidnak lesz DeathNote-juk, itt látod, mi történik velük."
L.EMPTY_SHAREDNIL_HEAD = "Még senki nem jelentkezett DeathNote-tal."
L.EMPTY_SHAREDNIL_SUB = "A könyved útnak indul, amint céhtársaknak vagy barátoknak is lesz DeathNote-juk."
L.EMPTY_SHAREDQUIET_HEAD = "Itt még nincs semmi."
L.EMPTY_SHAREDQUIET_SUB = "A céhnek és a barátoknak eddig nyugtuk volt."
L.EMPTY_HUNT_HEAD = "A halállista üres."
L.EMPTY_HUNT_SUB = "A plakáton: Vadászat kiírása."
L.EMPTY_HUNT_HINT = "Vagy a chatben: /dn hunt Név Vezetéknév. A céhedben mindenki és a barátaid is látják."
L.EMPTY_SEARCH_HEAD = "Nincs találat."
L.EMPTY_SEARCH_SUB = "Az Enter beírja a nevet a könyvbe."
L.EMPTY_SEARCHRO_HEAD = "Nincs találat."
L.EMPTY_SEARCHRO_SUB = "Néha segít egy másik írásmód."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "A KÖNYV"  -- [max 12]
L.MANUAL_BOOK = "Aki megöl a nyílt világban, magától bekerül. A halálod utáni üzenetre kattintva a gyilkos oldala nyílik meg."
L.MANUAL_WANTED_HEAD = "KÖRÖZÖTT"  -- [max 12]
L.MANUAL_WANTED = "A gyilkosaid, a legrosszabb elöl. Egy kattintás megmutatja a plakátot a tettekkel és a jegyzettel. A megkegyelmezettek áthúzva állnak a végén."
L.MANUAL_UNSOLVED_HEAD = "TISZTÁZATLAN"  -- [max 13]
L.MANUAL_UNSOLVED = "Ha nem volt egyértelmű, ki tette, az eset itt vár. Egy névre kattintva eldöntöd, ki a gyilkos."
L.MANUAL_ALERT_HEAD = "RIASZTÁS"  -- [max 12]
L.MANUAL_ALERT = "Ha egy gyilkos felbukkan névtáblaként, célpontként vagy az egér alatt, a könyv megszólal. Kattintásra célba veszed, harcban csak utána."
L.MANUAL_ADD_HEAD = "BEÍRÁS"  -- [max 12]
L.MANUAL_ADD = "Írj egy nevet a keresőbe, Enter. Jobb klikk egy soron: bosszú feljegyzése, kegyelem, kihúzás."
L.MANUAL_GUILD_HEAD = "CÉH"  -- [max 12]
L.MANUAL_GUILD = "A DeathNote-os céhtársaid és barátaid látják a tisztázott halálaidat és a kézi bejegyzéseidet. Plakát vagy /dn hunt Név: vadászat kiírása. Kattints a vérdíjra: tűzd ki a sajátod, csak ígéret."
L.MANUAL_SHARE_HEAD = "TOVÁBBADÁS"  -- [max 12]
L.MANUAL_SHARE = "Házirend, Könyv mentése: másolható szöveg mindenkinek, akinek nincs DeathNote-ja."
L.MANUAL_QUIET_HEAD = "CSEND"  -- [max 12]
L.MANUAL_QUIET = "Dungeonben és csatatéren a riasztás hallgat. Máskor: középső klikk a minitérkép-gombra vagy /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Biztosan kihúzod a könyvből: {name}?\nMinden tett és a jegyzet is elvész."
L.CONFIRM_DELETE_OK = "Kihúzás"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Kiüríted a céhkönyvet ezen a gépen?\nA halállistája is megy vele, a saját kiírásaid maradnak.\nA saját könyved marad, ahogy van."
L.CONFIRM_GUILD_CLEAR_OK = "Kiürítés"  -- [max 14]
L.CONFIRM_CANCEL = "Mégse"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ARANY"  -- [max 14]
L.BOUNTY_SILVER = "{count} EZÜST"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Megerősítés"  -- [max 19]
L.ACT_DISMISS = "Elvetés"  -- [max 19]
L.ACT_HUNT_AGAIN = "Körözés újra"  -- [max 19]
L.ACT_REVENGE = "Bosszú feljegyzése"  -- [max 19]
L.ACT_PARDON = "Kegyelem"  -- [max 19]
L.ACT_STRIKE = "Kihúzás"  -- [max 19]
L.ACT_OPEN_OWN = "Ugrás a könyvbe"  -- [max 19]
L.ACT_ADOPT = "A saját könyvembe"  -- [max 19]
L.ACT_CALLOFF = "Vadászat lefújása"  -- [max 19]
L.ACT_RELEASE = "Vadászat kiírása"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "észlelve {time}"
L.ROW_NOT_SEEN = "még nem észlelték"
L.ROW_PARDONED = "megkegyelmezve"
L.ROW_SUSPECT = "Gyanú"
L.MARK_REVENGE = "BOSSZÚ {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Gyilkos tisztázatlan"
L.MARK_CANDIDATES = "{count} JELÖLT"  -- [max 16]
L.MARK_SUSPECT = "GYANÚ"  -- [max 16]
L.ROW_NO_PLAYER = "Nem játékos"
L.ROW_UNCLEAR = "Ismeretlen ok"
L.MARK_NOT_COUNTED = "NEM SZÁMÍT"  -- [max 16]
L.ROW_LISTED_BY = "bejegyezte: {names}"
L.ROW_GKILLED = "{kills}× ölt"
L.ROW_VICTIMS = "{count} áldozat"
L.ROW_LAST = "utoljára: {text}"
L.MARK_IN_BOOK = "A KÖNYVBEN"  -- [max 16]
L.MEMBER_KILLERS = "{count} gyilkos"  -- [max 14]
L.MEMBER_DEATHS = "{count} halál"  -- [max 12]
L.MEMBER_LISTED = "{count} kézi"  -- [max 14]
L.MEMBER_ME = "ezt látják rólad a többiek"
L.MEMBER_NOTHING = "még semmi nincs megosztva"
L.MEMBER_LAST_DIED = "utoljára meghalt: {time}"
L.MARK_YOU = "te"  -- [max 16]
L.MARK_FRIEND = "BARÁT"  -- [max 16]
L.MARK_BOTH = "CÉHTÁRS, BARÁT"  -- [max 20]
L.MARK_TAKEN_DOWN = "LETERÍTVE {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ÉLVE VAGY HALVA"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "TETTEK"  -- [max 14]
L.POSTER_NOTE = "JEGYZET"  -- [max 8]
L.POSTER_BOUNTY = "VÉRDÍJ"  -- [max 12]
L.ROLE_ASSIST = "segédkezett"  -- [max 14]
L.ROLE_SUSPECT = "gyanú"  -- [max 14]
L.POSTER_LEVEL = "{level}. szint"
L.POSTER_GUILD = "Céh: {guild}"
L.POSTER_LAST_SEEN = "Utoljára észlelve: {time}"
L.POSTER_NOT_SEEN = "Még nem észlelték"
L.POSTER_ONLY_SUSPECT = "Csak gyanú, nincs bizonyított tett."
L.POSTER_NO_DEEDS = "Nincs feljegyzett tett."
L.TIP_LISTED_AT = "Bejegyezve: {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Halál oka: {spell}"
L.TIP_VICTIM = "Áldozat: {name}"
L.TIP_VICTIM_LEVEL = "Áldozat: {name} ({level}. szint)"
L.TIP_KILLER_LEVEL = "A gyilkos szintje: {level}"
L.TIP_ASSISTS = "Segédkezett: {names}"
L.TIP_ROLE_ASSIST = "Segédkezett, de nem ő mérte a halálos csapást."
L.TIP_ROLE_SUSPECT = "Csak gyanú, nem bizonyított."
L.MORE_LINE = "… és még {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "CÉHKÖNYV"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Bejegyezte: {names}"
L.POSTER_SEEN = "Észlelve: {time}"
L.POSTER_SEEN_BY = "Észlelve: {time}, észlelte: {name}"
L.TIP_IN_BOOK_OF = "Bejegyezte"
L.POSTER_REMARK = "MEGJEGYZÉS"  -- [max 12]
L.POSTER_BY_HAND = "KÉZZEL BEJEGYEZVE"  -- [max 22]
L.POSTER_VICTIMS = "ÁLDOZATOK"  -- [max 12]
L.POSTER_LISTED = "BEJEGYEZTE"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Kézzel bejegyezve."
L.POSTER_NO_DEEDS_SENT = "Nem érkezett tett."
L.POSTER_NONE_KNOWN = "nem ismert"
L.POSTER_NO_NAMES = "nem érkeztek nevek"
L.TIP_VICTIMS = "Áldozatok"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Kiírva: {time}"
L.HUNT_REASON = "Indok: {reason}"
L.POSTER_HUNTLIST = "HALÁLLISTA"  -- [max 24]
L.POSTER_RELEASED_N = "{times} halállistára téve"
L.POSTER_RELEASED_BY = "Kiírta: {names}"
L.POSTER_TAKEN_DOWN = "LETERÍTVE"  -- [max 12]
L.POSTER_NOT_YET = "MÉG NEM"  -- [max 18]
L.POSTER_CALLS = "KIÍRÁSOK"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Már senki."
L.POSTER_LAST = "UTOLJÁRA"  -- [max 13]
L.POSTER_TAKEN_BY = "leterítette: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "még senki sem terítette le"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Haláleset"  -- [max 20]
L.CASE_ASSISTS = "SEGÉDKEZTEK"  -- [max 24]
L.CASE_PICK = "A GYILKOS KIVÁLASZTÁSA"  -- [max 24]
L.CASE_NOT_COUNTED = "Nem számít (instance, csatatér vagy párbaj)"
L.CASE_KILLER = "GYILKOS"  -- [max 24]
L.CASE_KILLER_SUSPECT = "GYILKOS (GYANÚ)"  -- [max 24]
L.CASE_CLICK_NAME = "Kattints a névre, és megnyílik a plakátja."
L.CASE_GONE = "Már nincs a könyvben."
L.CASE_KILLER_UNCLEAR = "GYILKOS TISZTÁZATLAN"  -- [max 24]
L.CASE_SEVERAL = "Többen is lehettek. Kinek a neve kerüljön a könyvbe?"
L.CASE_NOBODY = "Senki sem jöhetett szóba."
L.CASE_HOW = "MI TÖRTÉNT"  -- [max 24]
L.CASE_PVE = "Egy szörny vagy maga a világ. Ez nem a könyvre tartozik."
L.CASE_UNCLEAR = "Tisztázatlan"
L.CASE_DARK = "A helyszínelők sötétben tapogatóznak."
L.TIP_MORE_CANDIDATES = "További jelöltek"
L.CASE_SOURCE_SUSPECT = "Gyanú: nem sokkal a halálod előtt célba vett téged."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-sor a gyilkosoknál"  -- [max 44]
L.OPT_MINIMAP = "Minitérkép-gomb mutatása"  -- [max 44]
L.OPT_ALERT = "Riasztás, ha felbukkan egy gyilkos"  -- [max 44]
L.OPT_FLASH = "A képernyő széle villogjon pirosan"  -- [max 44]
L.OPT_SUSPECTS = "Gyanúsítottak jelzése is"  -- [max 44]
L.OPT_DEATHMSG = "Üzenet PvP-halál után"  -- [max 44]
L.OPT_G_SHARE = "Saját halálaim megosztása"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Kézi bejegyzések megosztása"  -- [max 44]
L.OPT_G_RECEIVE = "Céhkönyv fogadása"  -- [max 44]
L.OPT_G_ALERT = "Figyelmeztetés a céhkönyv gyilkosainál"  -- [max 44]
L.OPT_G_ALERTLISTED = "Figyelmeztetés a kézi bejegyzéseknél is"  -- [max 44]
L.OPT_G_ANNOUNCE = "Jelzés, ha egy céhtársat megölnek"  -- [max 44]
L.OPT_G_SIGHTINGS = "Észlelések megosztása"  -- [max 44]
L.OPT_F_SHARE = "Megosztás a céhhel"  -- [max 44]
L.OPT_F_FRIENDS = "Megosztás a barátokkal"  -- [max 44]
L.OPT_F_ALERT = "Figyelmeztetés céh és barátok gyilkosainál"  -- [max 44]
L.OPT_F_ALERTHUNT = "Figyelmeztetés a halállista célpontjainál"  -- [max 44]
L.OPT_F_ANNOUNCE = "Jelzés, ha céhtárs vagy barát meghal"  -- [max 44]
L.OPT_F_SIGHTINGS = "Észlelések megosztása céhhel és barátokkal"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Céh"  -- [max 14]
L.SET_BOOK_SIZE = "A könyv mérete"  -- [max 34]
L.SET_LANGUAGE = "Nyelv"  -- [max 16]
L.SET_LANG_AUTO = "Automatikus"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Újratöltés után lép életbe."  -- [max 28]
L.SET_LANG_RELOAD = "Újratöltés most"  -- [max 22]
L.SET_SEC_SHARE = "TOVÁBBADÁS"  -- [max 24]
L.IO_EXPORT = "Könyv mentése"  -- [max 17]
L.IO_IMPORT = "Könyv betöltése"  -- [max 17]
L.SET_HINT_BOOK = "A mentés szövegként adja ki a könyvet: megőrzésre, vagy hogy továbbadd a céhen kívülieknek. A betöltés összefésül, és semmit sem ír felül."
L.SET_SEC_SOUND = "HANG"  -- [max 24]
L.SET_SOUND = "Hang"  -- [max 22]
L.SET_VOLUME = "Hangerő"  -- [max 22]
L.SET_CHANNEL = "Csatorna"  -- [max 12]
L.SET_SEC_THRESHOLD = "KÜSZÖB"  -- [max 24]
L.SET_COOLDOWN = "Várakozás gyilkosonként"  -- [max 34]
L.SET_MINKILLS = "Riasztás, ha ennyiszer ölt meg"  -- [max 34]
L.SET_ALERT_SIZE = "A riasztás mérete"  -- [max 34]
L.SET_TEST_ALERT = "Próbariasztás"  -- [max 17]
L.SET_G_MINKILLS = "Céhfigyelmeztetés ennyi halálnál"  -- [max 34]
L.SET_F_MINKILLS = "Figyelmeztetés ennyi halálnál"  -- [max 34]
L.SET_SEC_STATUS = "ÁLLAPOT"  -- [max 24]
L.SET_SEC_SHARING = "MEGOSZTÁS"
L.SET_SEC_WARN = "RIASZTÁS"
L.SET_MORE = "Több"
L.SET_GUILD_CLEAR = "Céhkönyv kiürítése"  -- [max 26]
L.SET_HINT_GUILD = "Csak a saját céhed kap bármit. Ami onnan jön, külön marad a könyvedtől, amíg magad át nem veszed."
L.SET_HINT_FRIENDS = "Csak a DeathNote-os céhtársak és barátok kapnak bármit."
L.BTN_BACK = "Vissza"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Egyeztetés"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds} mp múlva"  -- [max 16]
L.TIP_FRIENDS = "Barátok"
L.TIP_GUILD_NAME = "Céh: {guild}"
L.TIP_MATES_WITH = "DeathNote-os céhtársak:"
L.TIP_NO_MATE = "Még nem jelentkezett céhtárs DeathNote-tal."
L.TIP_FRIENDS_WITH = "DeathNote-os barátok:"
L.TIP_SHARED = "Megosztva: tisztázott halálaid, kézi bejegyzéseid és halállistás kiírásaid."
L.TIP_NOT_SHARED = "Nincs megosztva: jegyzetek, gyanúk, megkegyelmezettek, betöltött bejegyzések."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Betöltés"  -- [max 17]
L.IO_DONE = "Betöltve: {new} új, {merged} összefésülve."
L.IO_FAILED = "Ez nem sikerült."
L.IO_SMALL = "Csak röviden"  -- [max 17]
L.IO_ALL = "Mindent mutat"  -- [max 17]
L.IO_MSG_FULL = "Az egész könyv tettekkel ({size})."
L.IO_MSG_SHORT = "Csak nevek és számok ({size}). Tettekkel: {full}."
L.IO_MSG_BIG = "Nagy könyv ({size}): a kijelölés és a másolás eltart egy kicsit."
L.IO_HELP_EXPORT = "A szöveg ki van jelölve: a Ctrl+C kimásolja. Őrizd meg, vagy add tovább a barátaidnak."
L.IO_HELP_IMPORT = "Illeszd be a mentett szöveget a Ctrl+V-vel, aztán Betöltés. Semmi sem íródik felül."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Az indokot a céhedben és a barátaid közt mindenki látja, akinek van DeathNote-ja."
L.REL_HINT_GUILD = "Az indokot a céhedben mindenki látja, akinek van DeathNote-ja."
L.REL_HINT_FRIENDS = "Az indokot a DeathNote-os barátaid látják."
L.REL_HEAD = "Vadászat kiírása"  -- [max 24]
L.REL_FOR = "KINEK"  -- [max 6]
L.REL_REASON = "INDOK"  -- [max 8]
L.REL_HINT2 = "A jegyzeted nálad marad. A saját kiírásodat csak te fújhatod le."
L.REL_GO = "Kiírás"  -- [max 17]
L.REL_NONE = "Nincs céh, és a megosztás a barátokkal ki van kapcsolva."
L.REL_CAP = "Listánként legfeljebb {own} saját kiírás és {max} célpont."
L.REL_FAILED = "A vadászat most nem írható ki."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} mp"  -- [max 7]
L.SET_HINT_SILENT = "Nincs hang: a riasztás csak látszik."
L.SET_HINT_BUILTIN = "Ennek a hangnak a hangereje a játékbeállítások csatornáját követi."
L.SET_HINT_LEVELS = "Öt fokozat halktól hangosig. Erre jön még a csatorna csúszkája a játékbeállításokban."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Céh és barátok"  -- [max 18]
L.TIP_HELP_BUTTON = "Így működik a könyv"
L.VIEW_HUNT = "Halállista"  -- [max 13]
L.VIEW_BY_KILLER = "Gyilkosonként"  -- [max 13]
L.VIEW_BY_MATE = "Céhtársanként"  -- [max 13]
L.SRC_ALL = "Mind"  -- [max 12]
L.SRC_GUILD = "Céh"  -- [max 12]
L.SRC_FRIENDS = "Barátok"  -- [max 12]
L.SORT_HIDE_PARDONED = "Megkegyelmezettek nélkül"  -- [max 24]
L.SORT_SHOW_PARDONED = "Megkegyelmezettekkel"  -- [max 24]
L.SEARCH_ADD = "Keresés vagy beírás …"  -- [max 26]
L.SEARCH_SHORT = "Keresés …"  -- [max 10]
L.SEARCH_KILLER = "Gyilkos neve …"  -- [max 15]
L.SEARCH_JOURNAL = "Gyilkos vagy hely …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Összes összecsukása"
L.TIP_EXPAND_ALL = "Összes kinyitása"
L.STATUS_NO_PLATES = "Az ellenséges névtáblák ki vannak kapcsolva: a riasztás csak a célpontot és az egeret látja."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "Körözött: {count}"
L.MM_UNSOLVED = "Tisztázatlan: {count}"
L.MM_ALERT_OFF = "A riasztás ki van kapcsolva (középső klikk)"
L.MM_CLICK = "Klikk: könyv · Jobb klikk: Házirend"
L.MM_MIDDLE = "Középső klikk: riasztás be/ki"
L.MM_DRAG = "Húzás: mozgatás a minitérkép szélén"
L.MM_CHAT_ALERT_ON = "Riasztás be."
L.MM_CHAT_ALERT_OFF = "Riasztás ki."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "1. SZÁMÚ CÉHELLENSÉG"  -- [max 25]
L.STAMP_HUNT = "SZABAD A VADÁSZAT"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} a barátodnak adta ki magát ({friend}): elutasítva."
L.FRIENDS_SHORT_IMPOSTOR = "Idegen elutasítva"  -- [max 22]
L.ALERT_LEVEL = "{level}. szint"  -- [max 12]
L.ALERT_LEVEL_LAST = "utoljára {level}. szint"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Szint: ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · a halállistán ({names})"
L.BANNER_NEW_HUNTS = "{count} új célpont"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "új a halállistán"
L.OPT_F_ANNOUNCEHUNT = "Halállista-hírek jelzése: új, leterítve"  -- [max 44]
L.SET_HUNT_EXPIRE = "Kiírások lejárata"  -- [max 30]
L.SET_EXPIRE_NEVER = "Soha"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} nap"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Baráti könyv kiürítése"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Kiüríted a baráti könyvet ezen a gépen?\nA halállistája is megy vele, a saját kiírásaid maradnak."
L.CONFIRM_CALLOFF_ALL = "Lefújod az összes kiírásodat a halállistán?\nA céh és a barátok fokozatosan értesülnek."
L.CONFIRM_CALLOFF_ALL_OK = "Mind lefújom"  -- [max 14]
L.ACT_CALLOFF_ALL = "Minden kiírásom lefújása"  -- [max 24]
L.ACT_HUNT_HIDE = "Elrejtés nálam"  -- [max 19]
L.ACT_HUNT_SHOW = "Megjelenítés újra"  -- [max 19]
L.HUNT_ROW_HIDDEN = "nálad elrejtve"
L.HUNT_ROW_CALLS = "{count} kiírás: {names}"
L.POSTER_ON_HUNTLIST = "A halállistán ({names})"
L.REL_SELF = "Magadat nem teheted halállistára."
L.REL_MATE = "Ő a tieid közül való (céh vagy barát DeathNote-tal)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Ki a barátod, {friend}: {a} vagy {b}? Válassz."
L.FRIENDS_SHORT_CONFLICT = "Barát kétséges"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Két játékos állítja magáról, hogy ő a barátod, {friend}: {a} és {b}. Amíg nem választasz, a könyv egyiküktől sem fogad el semmit. Céh és barátok, Céhtársanként nézet: jobb klikk a névre."
L.MEMBER_CONFLICT = "Jobb klikk: ő a barátod?"  -- [max 40]
L.ACT_TIE_MINE = "A barátom: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Leválasztás"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Leválasztod ezt a nevet a barátlistádról: {name}?\nAmit ez a név a baráti könyvbe hozott, törlődik; a következő üzenet ezen a keresztnéven újra összekapcsol."
L.CHAT_FRIENDS_TIES = "Összekapcsolt teljes nevek (* = első kapcsolat, még nem igazolt): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Név [Vezetéknév]> <arany>  saját vérdíj kitűzése (összeg nélkül: visszavonás)"
L.CHAT_WHO_BOUNTY = "Kire? /dn bounty <Név> <arany>"
L.CHAT_BOUNTY_SET = "{name}: {gold} arany vérdíjat tűztél ki. A DeathNote-os céhtársak és barátok látják."
L.CHAT_BOUNTY_OFF = "{name}: a vérdíjadat visszavontad."
L.CHAT_BOUNTY_NONE = "Nincs saját vérdíjad rá: {name}"
L.CHAT_BOUNTY_BAD = "Vérdíj: egész szám aranyban, 1 és 99999 között (a 0 visszavonja)."
L.CHAT_BOUNTY_CAP = "Nincs vérdíj: legfeljebb {count} sajátod lehet."
L.CHAT_BOUNTY_OURS = "Magadra és a tieidre (DeathNote-os céhtárs vagy barát) nem tűzhetsz ki vérdíjat."
L.ACT_BOUNTY = "Vérdíj kitűzése"  -- [max 24]
L.ACT_UNDO = "Visszavonás"  -- [max 19]
L.ACT_REVENGE_TAKE = "Egy bosszú levonása"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, te tűzted ki"
L.POSTER_BOUNTY_BY = "{gold}, kitűzte: {name}"
L.POSTER_BOUNTY_MANY = "Vérdíj {gold}: {names}"
L.POSTER_AVENGED = "Megbosszulta: {names}"
L.ROW_AVENGED = "megbosszulva {times}"
L.BOUNTY_TIP_HEAD = "A saját vérdíjad aranyban"
L.BOUNTY_TIP_RULES = "Egész szám 1 és 99999 között. Üres vagy 0: vissza a könyv értékére. Enter beállítja, Esc mégse."
L.BOUNTY_TIP_PROMISE = "A DeathNote-os céhtársak és barátok látják. Csak ígéret: egymás között rendezitek."
L.BOUNTY_TIP_CLICK = "Kattintás: saját vérdíj kitűzése"
L.CHAT_AVENGED = "{name} megbosszult téged: {killer}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: {gold} arany vérdíjat tűztél ki."
L.CHAT_BOUNTY_UNKNOWN = "{name} egyik könyvedben sincs benne. Vérdíjat csak könyvben szereplő névre lehet kitűzni, ahogy a játék mutatja: keresztnév és vezetéknév."
L.CHAT_BOUNTY_LIST = "Saját vérdíjaid ({count}/{max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Nem tűztél ki vérdíjat."
-- <<< BOOK
-- >>> REPUTE (1.3.0) ------------------------------------------------------------------------------------------
L.REPUTE_LINE = "{tier}. rang · Út: {path}"  -- [max 32]
L.PATH_R = "Gyalázat"  -- [max 16]
L.PATH_E = "Becsület"  -- [max 16]
L.PATH_J = "Vadászat"  -- [max 16]
L.PATH_S = "Védelem"  -- [max 16]
L.PATH_NONE = "íratlan"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) -------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "HARAGOT TART?"  -- [max 30]
L.ALERT_LINE_VICTIM = "állás {score} · te ölted meg, utoljára {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · állás {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · {score}, kvitt"
L.ALERT_LINE_STANDING_AHEAD = "{text} · {score}, túlfizetve"
-- <<< ALARM
-- >>> START (1.3.0) -------------------------------------------------------------------------------------------
L.SET_THEME = "Borító"  -- [max 16]
L.START_HINT = "Mindkettő később is módosítható a Házirendben."  -- [max 60]
L.START_GO = "Mehet"  -- [max 16]
L.START_CLOSE_TIP = "Maradjon így"  -- [max 32]
L.CHAT_THEME_NEWS = "Újdonság: a könyvnek más borítói is vannak. Házirend, Könyv lap, vagy /dn theme."
L.HELP_START = "/dn start  az indítóablak újra (nyelv és borító)"
-- <<< START
-- >>> RECORD (1.3.0) ------------------------------------------------------------------------------------------
L.TAB_RECORD = "Priusz"  -- [max 16]
L.STAMP_QUITT = "KVITT"  -- [max 16]
L.STAMP_OVERPAID = "TÚLFIZETVE"  -- [max 16]
L.STATE_OPEN = "nyitott"  -- [max 16]
L.STATE_EVEN = "kvitt"  -- [max 16]
L.STATE_AHEAD = "túlfizetve"  -- [max 16]
L.STATE_VICTIM = "nincs a könyvben"  -- [max 24]
L.STAND_LINE = "Állás: {score}"
L.STAND_TIP = "te {mine}, ő {his}"
L.TIP_IN_RECORD = "PRIUSZ:"
L.TIP_RECORD_LINE = "{times} megölted, utoljára {time}"
L.RECORD_HEAD = "Saját akta"  -- [max 20]
L.RECORD_LOG_HEAD = "Utolsó ölések"  -- [max 20]
L.RECORD_NEXT = "még {points} pont, következik: {rank}"
L.RECORD_TOP = "Elérted a legmagasabb rangot."
L.RECORD_BAR_TIP = "{total} / {goal} pont"
L.RECORD_NEEDLE_LOW = "kíméletlen"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "becsületes"  -- [max 12]
L.RECORD_NEEDLE_TIP = "A mutató: becsület és védelem a gyalázat ellen. A vadászat nem mozdítja."
L.RECORD_KILLS = "Ölések: {kills} · Áldozatok: {victims}"
L.RECORD_BEST = "Csúcsok: {list}"
L.RECORD_BEST_GAP = "+{count} szint"
L.RECORD_BEST_STREAK = "sorozat: {count}"
L.RECORD_BEST_QUICK = "leggyorsabb bosszú: {time}"
L.DUR_SECONDS = "{count} mp"
L.DUR_MINUTES = "{count} perc"
L.DUR_HOURS = "{count} óra"
L.RECORD_AWARDS = "KITÜNTETÉSEK"  -- [max 14]
L.RECORD_AWARD_AT = "odaítélve: {time}"
L.RECORD_AWARD_OPEN = "még nincs odaítélve"
L.RECORD_MORE = "Továbbiak"  -- [max 19]
L.RECORD_BACK = "Vissza az aktához"  -- [max 19]
L.RECORD_CLEAR = "Priusz törlése"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Törlöd a priuszt?\nMinden áldozat és az utolsó ölések listája elvész. A rang, a pontok és a kitüntetések megmaradnak."
L.CONFIRM_RECORD_CLEAR_OK = "Törlés"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Kihúzás a priuszból: {name}?\nA megszerzett pontok megmaradnak."
L.ACT_VICTIM_STRIKE = "Kihúzás a priuszból"  -- [max 26]
L.VICTIM_KILLED = "{times} megölted"
L.VICTIM_POINTS = "Szerzett pontok: {points}"
L.VICTIM_SCENE = "Tetthely: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "SAJÁT ÖLÉSEK"  -- [max 14]
L.KILL_TAG_REVENGE = "bosszú"  -- [max 14]
L.KILL_TAG_KICK = "fekvőbe rúgva"  -- [max 14]
L.KILL_TAG_GROUP = "csoport"  -- [max 14]
L.BAND_GRAU = "szürke"  -- [max 12]
L.BAND_GRUEN = "zöld"  -- [max 12]
L.BAND_GELB = "sárga"  -- [max 12]
L.BAND_ORANGE = "narancssárga"  -- [max 12]
L.BAND_ROT = "piros"  -- [max 12]
L.BAND_SCHAEDEL = "koponya"  -- [max 12]
L.BAND_UNBEKANNT = "ismeretlen"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "nincs pont"
L.RECORD_BANDS = "Szintszín szerint"
L.TIP_PATH_R = "Gyalázat: szürkék és zöldek megölése."
L.TIP_PATH_E = "Becsület: a szintedhez közeli játékosok megölése, bosszú."
L.TIP_PATH_J = "Vadászat: magasabb szintűek, halállista-célpontok, vérdíjasok megölése."
L.TIP_PATH_S = "Védelem: céhtársakat vagy barátokat megölő játékosok megölése."
L.SORT_STATE = "Állás"  -- [max 14]
L.SORT_COUNT = "Ölések"  -- [max 14]
L.SORT_POINTS = "Pontok"  -- [max 14]
L.CHAT_OWN_KILL = "Priusz: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Új út: {path}. Rang: {rank}."
L.BANNER_RANK = "ÚJ RANG"  -- [max 24]
L.BANNER_AWARD = "KITÜNTETÉS"  -- [max 24]
L.OPT_LEDGER = "Priusz vezetése"  -- [max 44]
L.OPT_LEDGER_CHAT = "Saját ölések jelzése a chatben"  -- [max 44]
L.OPT_VICTIMS = "Figyelmeztetés, ha felbukkan egy áldozatod"  -- [max 44]
L.SET_SETTLED = "Riasztás kiegyenlített számlánál"  -- [max 34]
L.SET_SETTLED_ALWAYS = "mint eddig"  -- [max 10]
L.SET_SETTLED_QUIET = "halkan"  -- [max 10]
L.SET_SETTLED_OFF = "soha"  -- [max 10]
L.MANUAL_RECORD_HEAD = "PRIUSZ"  -- [max 14]
L.MANUAL_RECORD = "Saját halálos csapásaid játékosokon. A plakát és a lista az állást mutatja (te : ő): nyitott, kvitt vagy túlfizetve. Az 1. hely mindig nyitott. Az ölések pontot hoznak a rangodhoz."
L.POSTER_LAST_SEEN_IN = "Utoljára észlelve: {zone}, {time}"
L.SHEET_RECORD = "Priusz"  -- [max 14]
-- <<< RECORD
end)
