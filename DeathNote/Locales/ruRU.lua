-- DeathNote: Русский (ruRU). Translation of enUS.lua by DaveeeG.
-- Plural: 3 forms {count|one|few|many} (1, 21, 31 .. not 11 | 2-4, 22-24 .. not 12-14 | 0, 5-20, 25 ..). Rule in Locale.lua (PLURAL_OF.ruRU), not here.
-- Fonts: cyrillic (Skurri/Morpheus/Friz _CYR cuts) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
--
-- TOC-Notes: Список смертей для PvP в открытом мире: запоминает, кто тебя убил, и предупреждает, когда убийца рядом.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("ruRU")) then return end

Locale.Register("ruRU", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "В розыске"  -- [max 16]
L.TAB_UNSOLVED = "Не раскрыто"  -- [max 16]
L.TAB_DEATHLOG = "Журнал смертей"  -- [max 16]
L.TAB_GUILD = "Гильдия"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Распорядок"  -- [max 24]
L.HEAD_HELP = "Как это работает"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Книга"  -- [max 14]
L.SHEET_ALERT = "Тревога"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "ВРАГ ОБЩЕСТВА № 1"  -- [max 24]
L.STAMP_REVENGE = "МЕСТЬ СВЕРШИЛАСЬ"  -- [max 16]
L.STAMP_PARDONED = "ПОМИЛОВАНИЕ"  -- [max 16]
L.STAMP_SUSPECT = "ПОДОЗРЕНИЕ"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "ВРАГ ОБЩЕСТВА № 1 РЯДОМ"  -- [max 30]
L.ALERT_SIGHTED = "ВРАГ ОБЩЕСТВА РЯДОМ"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "ПОДОЗРЕВАЕМЫЙ РЯДОМ"  -- [max 30]
L.ALERT_TITLE_GUILD = "ВРАГ ГИЛЬДИИ РЯДОМ"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "УБИЙЦА ДРУЗЕЙ РЯДОМ"  -- [max 30]
L.ALERT_TITLE_HUNT = "ЦЕЛЬ ИЗ СПИСКА НА ОТСТРЕЛ"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "под подозрением"
L.ALERT_LINE_KILLED = "твоих смертей: {times}"
L.ALERT_LINE_KILLED_ASSISTED = "твоих смертей: {times}, соучастие: {assists}"
L.ALERT_LINE_ASSISTED = "участие в твоей смерти: {times}"
L.ALERT_LINE_MANUAL = "в книге, запись вручную"
L.ALERT_LINE_LAST = "{text}, последний раз {time}"
L.ALERT_LINE_IN = "{text}, место: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Месть: {times}"
L.ALERT_HINT_CLOSE = "Правый клик: закрыть"  -- [max 44]
L.ALERT_HINT_COMBAT = "Взять в цель можно только после боя"  -- [max 44]
L.ALERT_HINT_TARGET = "Клик: в цель  ·  Правый клик: закрыть"  -- [max 44]
L.ALERT_MORE = "ещё +{count}"  -- [max 14]
L.SAMPLE_ZONE = "Тернистая долина"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "в книге гильдии"
L.GUILD_LINE_IN_FRIENDS = "в книге друзей"
L.GUILD_LINE_LISTED_BY = "в книгах: {names}"
L.GUILD_LINE_KILLED_GUILD = "убийств согильдийцев: {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "убийств друзей: {kills}×"
L.GUILD_LINE_KILLED_BOTH = "убийств согильдийцев и друзей: {kills}×"
L.GUILD_LINE_LAST = "{text}, последняя жертва: {name}"
L.HUNT_LINE_BY = "охота по заявке: {names}"
L.HUNT_LINE_RELEASED = "в списке на отстрел"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "под подозрением"
L.TALLY_MANUAL = "запись вручную"
L.TALLY_NONE = "злодеяний пока нет"
L.TALLY_KILLED = "твоих смертей: {times}"
L.TALLY_ASSISTED = "соучастие: {times}"
L.PLACE_UNKNOWN = "неизвестное место"
L.GKILLS_CAP = "не меньше {count}"
L.NAMELIST_MORE = "{names} и ещё {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY = "%d.%m"
L.TIME_FMT_DAY_YEAR = "%d.%m.%y"
L.TIME_NEVER = "никогда"
L.TIME_JUST = "только что"
L.TIME_MINUTES = "{count} мин назад"  -- [max 14]
L.TIME_HOURS = "{count} ч назад"  -- [max 14]
L.TIME_DAYS = "{count} {count|день|дня|дней} назад"  -- [max 16]
L.MONEY_GOLD = "{count}з"
L.MONEY_SILVER = "{count}с"
L.MONEY_COPPER = "{count}м"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "Согильдийцев с DeathNote на связи: {count}."
L.HEALTH_NOGUILD = "Ты не в гильдии, обмена нет."
L.HEALTH_OFF = "Обмен выключен."
L.HEALTH_SHORT_NOGUILD = "Нет гильдии"  -- [max 18]
L.HEALTH_SHORT_OFF = "Обмен выключен"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Заблокировано"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Отказ"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Ожидание"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Запрос отправлен"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Не работает"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Без звука"  -- [max 16]
L.SOUND_RAIDWARNING = "Объявление рейду"  -- [max 16]
L.SOUND_BELL = "Колокол"  -- [max 16]
L.SOUND_GONG = "Гонг"  -- [max 16]
L.SOUND_HEARTBEAT = "Сердцебиение"  -- [max 16]
L.SOUND_FEATHER = "Перо"  -- [max 16]
L.SOUND_SIREN = "Сирена"  -- [max 16]
L.CHANNEL_MASTER = "Общий"  -- [max 16]
L.CHANNEL_SFX = "Эффекты"  -- [max 16]
L.CHANNEL_DIALOG = "Диалоги"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name} теперь в книге."
L.CHAT_REMOVED = "{name}: вычеркнуто из книги."
L.CHAT_SYNC_WAIT = "Синхронизация только что была. Ещё раз через {seconds} с."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Имён пока нет."
L.EMPTY_WANTED_SUB = "Выйди хоть раз из дома."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  открыть/закрыть книгу"
L.HELP_ADD = "/dn add <Имя [Фамилия]>  вписать убийцу в книгу вручную"
L.HELP_DEL = "/dn del <Имя [Фамилия]>  вычеркнуть убийцу из книги"
L.HELP_QUIET = "/dn quiet  тревога выкл./вкл."
L.HELP_TEST = "/dn test  показать пробную тревогу"
L.HELP_GUILD = "/dn guild  книга гильдии: состояние и у кого из согильдийцев есть DeathNote"
L.HELP_FRIENDS = "/dn friends  книга друзей: состояние и у кого из друзей есть DeathNote"
L.HELP_SYNC = "/dn sync  синхронизировать книгу гильдии и книгу друзей сейчас"
L.HELP_HUNT = "/dn hunt <Имя [Фамилия]>  объявить охоту (без имени: показать список на отстрел)"
L.HELP_CALLOFF = "/dn calloff <Имя [Фамилия]>  отменить свою заявку на охоту"
L.HELP_LANG = "/dn lang <код>  язык книги (enUS, deDE, ruRU ...), после /reload"
L.HELP_THEME = "/dn theme <имя>  обложка книги, после /reload"
L.HELP_PROBE = "/dn probe  диагностика: что игра сообщает книге"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  диагностика, заодно проверить журнал боя"
L.HELP_DEBUG = "/dn debug  диагностика: подробно записывать каждую смерть (вкл./выкл.)"
L.HELP_HELP = "/dn help  эта справка"
L.HELP_SILENT_ZONES = "В подземельях, на полях боя и на аренах книга молчит сама."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "вкл."
L.WORD_OFF = "выкл."
L.CHAT_WHO_ADD = "Кого? /dn add <Имя>"
L.CHAT_WHO_DEL = "Кого? /dn del <Имя>"
L.CHAT_WHO_CALLOFF = "Кого? /dn calloff <Имя>"
L.CHAT_BAD_NAME = "Недопустимое имя."
L.CHAT_NOT_IN_BOOK = "Нет в книге: {name}"
L.CHAT_ALARM_ON = "Тревога включена."
L.CHAT_ALARM_OFF = "Тревога выключена."
L.CHAT_DEBUG = "Журнал диагностики: {state}"
L.CHAT_UNKNOWN_CMD = "Неизвестная команда. Справка: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Книга гильдии не загружена."
L.CHAT_NO_GUILD = "Ты не в гильдии (или игра этого ещё не знает)."
L.CHAT_GUILD_STATE = "Гильдия {guild}: отправка {share}, приём {receive}"
L.CHAT_GUILD_BOOK = "Книга гильдии. Убийц: {enemies} (только вручную: {listed}), злодеяний: {deeds}, с жертвами среди согильдийцев: {foreign}. Делиться ручными записями: {manual}"
L.CHAT_STATE_OK = "Состояние: {text}"
L.CHAT_STATE_WARN = "Внимание: {text}"
L.CHAT_NO_MATES = "Согильдийцев с DeathNote пока не слышно."
L.CHAT_HAVE_DN = "С DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "С DeathNote: {names} и ещё {count}"
L.CHAT_SYNC_ASKED = "Запрос отправлен. Ответы придут в ближайшие секунды."
L.CHAT_SYNC_FAIL = "Синхронизация не работает: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "нет гильдии или обмен выключен."
L.CHAT_FRIENDS_NOT_LOADED = "Книга друзей не загружена."
L.CHAT_FRIENDS_STATE = "Друзья: обмен {share}, в сети {online} из {total}."
L.CHAT_FRIENDS_BOOK = "Книга друзей. Убийц: {enemies} (только вручную: {listed}), злодеяний: {deeds}."
L.CHAT_NO_FRIENDS = "Друзей с DeathNote пока не слышно."
L.CHAT_HUNT_NOT_LOADED = "Список на отстрел не загружен."
L.CHAT_HUNT_UNKNOWN = "Неизвестно: {name}. Укажи и фамилию, как имя написано в игре."
L.CHAT_HUNT_CAP = "Охоту объявить нельзя: не больше {own} своих заявок и {targets} целей в списке."
L.CHAT_HUNT_NOWHERE = "Сейчас охоту объявить нельзя: гильдии нет, а обмен с друзьями выключен."
L.CHAT_HUNT_BOTH = "{name}: охота объявлена для гильдии и друзей."
L.CHAT_HUNT_GUILD = "{name}: охота объявлена для гильдии."
L.CHAT_HUNT_FRIENDS = "{name}: охота объявлена для твоих друзей."
L.CHAT_CALLED_OFF = "{name}: охота отменена."
L.CHAT_NO_OWN_CALL = "{name}: твоей заявки нет."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Язык сейчас: {lang}. Сменить: /dn lang <код>"
L.CHAT_LANG_LIST = "Коды: {codes}"
L.CHAT_LANG_BAD = "Неизвестный язык: {code}"
L.CHAT_LANG_SET = "Язык: {lang}."
L.CHAT_LANG_RELOAD = "Язык: {lang}. Вступит в силу после /reload."
L.CHAT_THEME_CURRENT = "Обложка сейчас: {theme}. Сменить: /dn theme <имя>"
L.CHAT_THEME_LIST = "Обложки: {themes}"
L.CHAT_THEME_BAD = "Неизвестная обложка: {name}"
L.CHAT_THEME_SET = "Обложка: {theme}."
L.CHAT_THEME_RELOAD = "Обложка: {theme}. Вступит в силу после /reload."
L.THEME_NOTEBOOK = "Чёрная книга"
L.THEME_HARBOR = "Книга капера"
L.THEME_TRADE = "Мастерская"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Книга готова. Кто убьёт тебя в открытом мире, окажется в ней. Открыть: /dn или кнопка у миникарты."
L.WELCOME_PLATES = "Индикаторы здоровья противников выключены. Без них тревога видит только твою цель."
L.WELCOME_SHARE = "Гильдия и друзья, у которых есть DeathNote, читают её вместе с тобой. Заметки и подозрения остаются у тебя."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "В КНИГЕ:"
L.TIP_HUNT = "НА ОТСТРЕЛ:"
L.TIP_GUILDBOOK = "КНИГА ГИЛЬДИИ:"
L.TIP_PARDONED = "помилование"
L.TIP_RANK = "ранг {rank}"
L.TIP_REVENGE = "месть {times}"
L.TIP_LISTED_BY = "в книгах: {names}"
L.TIP_NOTE = "Заметка: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Клик: открыть · Правый клик: убрать"
L.BANNER_NEW = "НОВАЯ ЗАПИСЬ"  -- [max 24]
L.BANNER_NEW_LINE = "теперь в книге"
L.BANNER_AGAIN = "СНОВА"  -- [max 24]
L.BANNER_AGAIN_LINE = "снова твоя смерть, всего уже {count}"
L.BANNER_SUSPECT = "ПОДОЗРЕНИЕ"  -- [max 24]
L.BANNER_SUSPECT_LINE = "под подозрением, разберись в книге"
L.BANNER_UNCLEAR = "КТО УБИЛ: НЕЯСНО"  -- [max 24]
L.BANNER_CANDIDATES = "{count} {count|кандидат|кандидата|кандидатов}"
L.BANNER_UNCLEAR_LINE = "Клик: выбрать убийцу в «Не раскрыто»"
L.BANNER_REVENGE = "РАСПЛАТА"  -- [max 24]
L.BANNER_REVENGE_LINE = "Месть свершилась ({count}×)"
L.BANNER_GUILD = "ГИЛЬДИЯ"  -- [max 24]
L.BANNER_FRIENDS = "ДРУЗЬЯ"  -- [max 24]
L.BANNER_KILLED_BY = "убийца: {name}"
L.BANNER_HUNT = "СПИСОК НА ОТСТРЕЛ"  -- [max 24]
L.BANNER_BAGGED = "смертельный удар: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Обмен выключен (Распорядок, лист «Гильдия»)."
L.SYNC_FRIENDS_OFF = "Обмен с друзьями выключен."
L.SYNC_NOBODY = "Ни гильдии, ни друзей для обмена."
L.SYNC_SHORT_NOBODY = "Обмена нет"  -- [max 18]
L.SYNC_PREFIX = "Игра не даёт принимать данные. Помогает перезаход."
L.SYNC_SHORT_PREFIX = "Приём не работает"  -- [max 18]
L.SYNC_BLOCKED = "Сервер блокирует отправку. Передай книгу через «Сохранить книгу»."
L.SYNC_SHORT_BLOCKED = "Отправка заблокирована"  -- [max 22]
L.SYNC_FAILING = "Отправка сейчас не проходит, пробуем снова."
L.SYNC_SHORT_FAILING = "Отправка буксует"  -- [max 18]
L.SYNC_HOLD = "Отправка ждёт, {wait}."
L.SYNC_HOLD_INSTANCE = "пока ты не выйдешь из подземелья"
L.SYNC_HOLD_COMBAT = "пока ты не выйдешь из боя"
L.SYNC_HOLD_LOCKDOWN = "пока чат снова не освободится"
L.SYNC_HOLD_AGAIN = "пока снова не заработает"
L.SYNC_HOLD_SHORT_INSTANCE = "Ждёт: подземелье"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Ждёт: бой"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Ждёт: чат"  -- [max 18]
L.SYNC_QUIET = "Отправлено, но согильдийцев с DeathNote пока не слышно."
L.SYNC_READY = "Готово. Согильдийцев с DeathNote пока не слышно."
L.SYNC_RUNNING = "Работает: {count} {count|согильдиец|согильдийца|согильдийцев} с DeathNote."
L.SYNC_RUNNING_ALL = "Работает. С DeathNote в гильдии и среди друзей: {count}."
L.FRIENDS_OFF = "Обмен с друзьями выключен (Распорядок, лист «Гильдия»)."
L.FRIENDS_BLOCKED = "Сервер блокирует шёпот. Друзья ничего не получат."
L.FRIENDS_SHORT_BLOCKED = "Шёпот заблокирован"  -- [max 22]
L.FRIENDS_FAILING = "Шёпот сейчас не проходит, пробуем снова."
L.FRIENDS_SHORT_FAILING = "Шёпот буксует"  -- [max 18]
L.FRIENDS_NONE_LISTED = "В списке друзей никого нет."
L.FRIENDS_NONE_ONLINE = "Сейчас никого из друзей нет в сети."
L.FRIENDS_SHORT_NONE_ONLINE = "Друзей нет в сети"  -- [max 18]
L.FRIENDS_QUIET = "Запрос отправлен, но друзей с DeathNote пока не слышно."
L.FRIENDS_READY = "Готово. Друзей с DeathNote пока не слышно."
L.FRIENDS_HOLD = "Отправка друзьям ждёт, пока снова не заработает."
L.FRIENDS_RUNNING = "Работает: {count} {count|друг|друга|друзей} с DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Взято из книги гильдии (убийств согильдийцев: {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "База данных не загружена."
L.IMPORT_NO_TEXT = "Нет текста."
L.IMPORT_NO_HEADER = "Нет первой строки (она начинается с {header}). Скопируй текст целиком."
L.IMPORT_NOT_EXPORT = "Это не экспорт DeathNote (нет строки заголовка или не та версия)."
L.IMPORT_TOO_LONG = "Слишком много строк (не больше {count})."
L.IMPORT_BAD_KEY = "Строка {line}: неверный ключ."
L.IMPORT_BAD_TIME = "Строка {line}: неверное время."
L.IMPORT_BROKEN = "Строка {line} неполная или повреждена (текст обрезан?). Ничего не загружено."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "да"
L.WORD_NO = "нет"
L.PROBE_HEAD = "Проверка: интерфейсов {apis}/{apisAll}, регистрируемых событий {events}/{eventsAll}."
L.PROBE_MISSING = "Нет: {list}"
L.PROBE_NOT_REGISTERABLE = "Не регистрируются: {list}"
L.PROBE_SOURCES = "Recap сейчас: {recap} · Meter: {meter} · Журнал боя: {clog}"
L.PROBE_READABLE = "читается"
L.PROBE_DEAD = "не работает"
L.PROBE_PLATES = "Индикаторы здоровья противников: {plates} · Открытый мир: {open}"
L.PROBE_PLATES_OFF = "ВЫКЛ. (игроков видно только по цели и курсору)"
L.PROBE_TARGET = "Цель: имя={name} GUID={guid} класс={class} враждебен={enemy} целится в меня={me}"
L.PROBE_GUILD = "Гильдия: префикс {prefix} · отправка {send} · последний код возврата {result} · отправлено {sent}, получено {received}, отброшено {dropped}"
L.PROBE_REGISTERED = "зарегистрирован"
L.PROBE_NOT_REGISTERED = "НЕ зарегистрирован ({result})"
L.PROBE_POSSIBLE = "возможно"
L.PROBE_ABSENT = "нет"
L.PROBE_WAITS = " · ждёт: {why}"
L.PROBE_LISTED = "Ручные записи (M): отправлено {sent}, получено {received}, отброшено {dropped} · вычеркнутые (X): отправлено {usent}, получено {ureceived}, отброшено {udropped}"
L.PROBE_GUILDBOOK = "Книга гильдии: {text}"
L.PROBE_SAVED = "Сохранено в DeathNoteDB.probe (в файле после /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Ранг"  -- [max 14]
L.SORT_RECENT = "Новые"  -- [max 14]
L.SORT_NAME = "Имя"  -- [max 14]
L.SORT_SEEN = "Встречи"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Кто убьёт тебя в открытом мире, окажется здесь. Книга запишет сама."
L.EMPTY_OPEN_HEAD = "Нераскрытых дел нет."
L.EMPTY_JOURNAL_HEAD = "Ни одной смерти."
L.EMPTY_JOURNAL_SUB = "Уважение. Или враньё."
L.EMPTY_NOGUILD_HEAD = "Нет гильдии."
L.EMPTY_NOGUILD_SUB = "Умирать можно и в одиночку."
L.EMPTY_GUILDOFF_HEAD = "Книга гильдии закрыта."
L.EMPTY_GUILDOFF_SUB = "Обмен выключен. Где включить, знает Распорядок."
L.EMPTY_GUILDNIL_HEAD = "Из гильдии пока ни слова."
L.EMPTY_GUILDNIL_SUB = "Твоя книга отправится, как только у кого-то из согильдийцев будет DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "В книге гильдии пока пусто."
L.EMPTY_GUILDQUIET_SUB = "Твоих согильдийцев пока не трогали."
L.EMPTY_FRIENDSOFF_HEAD = "Книга друзей закрыта."
L.EMPTY_FRIENDSOFF_SUB = "Обмен с друзьями выключен. Где включить, знает Распорядок."
L.EMPTY_FRIENDSNIL_HEAD = "Друзей с DeathNote пока не слышно."
L.EMPTY_FRIENDSNIL_SUB = "Твоя книга отправится, как только у кого-то из друзей будет DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "От друзей пока ничего."
L.EMPTY_FRIENDSQUIET_SUB = "Твоих друзей пока не трогали."
L.EMPTY_NOBODY_HEAD = "Ни гильдии, ни друзей."
L.EMPTY_NOBODY_SUB = "Умирать можно и в одиночку."
L.EMPTY_NOBODY_HINT = "Когда у согильдийцев или друзей из списка друзей появится DeathNote, здесь будет видно, что с ними происходит."
L.EMPTY_SHAREDNIL_HEAD = "Пока никого с DeathNote не слышно."
L.EMPTY_SHAREDNIL_SUB = "Твоя книга отправится, как только у согильдийцев или друзей будет DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Здесь пока пусто."
L.EMPTY_SHAREDQUIET_SUB = "Гильдию и друзей пока не трогали."
L.EMPTY_HUNT_HEAD = "Список на отстрел пуст."
L.EMPTY_HUNT_SUB = "На плакате: «Объявить охоту»."
L.EMPTY_HUNT_HINT = "Или в чате: /dn hunt Имя Фамилия. Это увидят все в твоей гильдии и твои друзья."
L.EMPTY_SEARCH_HEAD = "Совпадений нет."
L.EMPTY_SEARCH_SUB = "Enter впишет имя в книгу."
L.EMPTY_SEARCHRO_HEAD = "Совпадений нет."
L.EMPTY_SEARCHRO_SUB = "Иногда помогает другое написание."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "КНИГА"  -- [max 12]
L.MANUAL_BOOK = "Кто убьёт тебя в открытом мире, попадёт в книгу сам. Клик по сообщению после смерти открывает страницу убийцы."
L.MANUAL_WANTED_HEAD = "В РОЗЫСКЕ"  -- [max 12]
L.MANUAL_WANTED = "Твои убийцы, худшие первыми. Клик покажет плакат со злодеяниями и заметкой. Помилованные стоят зачёркнутыми в конце."
L.MANUAL_UNSOLVED_HEAD = "НЕ РАСКРЫТО"  -- [max 13]
L.MANUAL_UNSOLVED = "Если неясно, кто это сделал, дело ждёт здесь. Клик по имени назначает убийцу."
L.MANUAL_ALERT_HEAD = "ТРЕВОГА"  -- [max 12]
L.MANUAL_ALERT = "Когда появляется индикатор здоровья убийцы или убийца оказывается в цели либо под курсором, книга подаёт голос. Клик берёт в цель, а в бою только после него."
L.MANUAL_ADD_HEAD = "ЗАПИСЬ"  -- [max 12]
L.MANUAL_ADD = "Впиши имя в поле поиска, Enter. Правый клик по строке: отметить месть, помиловать, вычеркнуть."
L.MANUAL_GUILD_HEAD = "ГИЛЬДИЯ"  -- [max 12]
L.MANUAL_GUILD = "Согильдийцы и друзья с DeathNote видят твои подтверждённые смерти и ручные записи. Плакат или /dn hunt Имя: объявить охоту. Щелчок по награде: назначить свою, лишь обещание, расчёт между собой."
L.MANUAL_SHARE_HEAD = "ПЕРЕДАЧА"  -- [max 12]
L.MANUAL_SHARE = "Распорядок, «Сохранить книгу»: текст для копирования, для всех без DeathNote."
L.MANUAL_QUIET_HEAD = "ТИШИНА"  -- [max 12]
L.MANUAL_QUIET = "В подземельях и на полях боя тревога молчит. В остальном: средний клик по кнопке у миникарты или /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Вычеркнуть из книги: {name}?\nВсе злодеяния и заметка пропадут."
L.CONFIRM_DELETE_OK = "Вычеркнуть"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Очистить книгу гильдии на этом компьютере?\nЕё список на отстрел тоже пропадёт, твои заявки останутся.\nТвоя собственная книга останется как есть."
L.CONFIRM_GUILD_CLEAR_OK = "Очистить"  -- [max 14]
L.CONFIRM_CANCEL = "Отмена"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ЗОЛОТА"  -- [max 14]
L.BOUNTY_SILVER = "{count} СЕРЕБРА"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Подтвердить"  -- [max 19]
L.ACT_DISMISS = "Отклонить"  -- [max 19]
L.ACT_HUNT_AGAIN = "Снова в розыск"  -- [max 19]
L.ACT_REVENGE = "Отметить месть"  -- [max 19]
L.ACT_PARDON = "Помиловать"  -- [max 19]
L.ACT_STRIKE = "Вычеркнуть"  -- [max 19]
L.ACT_OPEN_OWN = "Открыть в книге"  -- [max 19]
L.ACT_ADOPT = "В мою книгу"  -- [max 19]
L.ACT_CALLOFF = "Отменить охоту"  -- [max 19]
L.ACT_RELEASE = "Объявить охоту"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "встреча {time}"
L.ROW_NOT_SEEN = "встреч пока не было"
L.ROW_PARDONED = "помилование"
L.ROW_SUSPECT = "Подозрение"
L.MARK_REVENGE = "МЕСТЬ {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Кто убил, неясно"
L.MARK_CANDIDATES = "{count} {count|КАНДИДАТ|КАНДИДАТА|КАНДИДАТОВ}"  -- [max 16]
L.MARK_SUSPECT = "ПОДОЗРЕНИЕ"  -- [max 16]
L.ROW_NO_PLAYER = "Не игрок"
L.ROW_UNCLEAR = "Неясно как"
L.MARK_NOT_COUNTED = "НЕ В СЧЁТ"  -- [max 16]
L.ROW_LISTED_BY = "вписали: {names}"
L.ROW_GKILLED = "убийств: {kills}×"
L.ROW_VICTIMS = "{count} {count|жертва|жертвы|жертв}"
L.ROW_LAST = "последний раз: {text}"
L.MARK_IN_BOOK = "В КНИГЕ"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|убийца|убийцы|убийц}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|смерть|смерти|смертей}"  -- [max 12]
L.MEMBER_LISTED = "{count} вручную"  -- [max 14]
L.MEMBER_ME = "что видят о тебе другие"
L.MEMBER_NOTHING = "пока ничем не поделились"
L.MEMBER_LAST_DIED = "последняя смерть {time}"
L.MARK_YOU = "ты"  -- [max 16]
L.MARK_FRIEND = "ДРУГ"  -- [max 16]
L.MARK_BOTH = "СОГИЛЬДИЕЦ, ДРУГ"  -- [max 20]
L.MARK_TAKEN_DOWN = "ЦЕЛЬ УБИТА {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ЖИВЫМ ИЛИ МЁРТВЫМ"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "ЗЛОДЕЯНИЯ"  -- [max 14]
L.POSTER_NOTE = "ЗАМЕТКА"  -- [max 8]
L.POSTER_BOUNTY = "НАГРАДА"  -- [max 12]
L.ROLE_ASSIST = "соучастие"  -- [max 14]
L.ROLE_SUSPECT = "подозрение"  -- [max 14]
L.POSTER_LEVEL = "Уровень {level}"
L.POSTER_GUILD = "Гильдия: {guild}"
L.POSTER_LAST_SEEN = "Последняя встреча: {time}"
L.POSTER_NOT_SEEN = "Встреч пока не было"
L.POSTER_ONLY_SUSPECT = "Только подозрение, доказанных злодеяний нет."
L.POSTER_NO_DEEDS = "Злодеяния не записаны."
L.TIP_LISTED_AT = "Запись: {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Причина смерти: {spell}"
L.TIP_VICTIM = "Жертва: {name}"
L.TIP_VICTIM_LEVEL = "Жертва: {name} (уровень {level})"
L.TIP_KILLER_LEVEL = "Уровень убийцы: {level}"
L.TIP_ASSISTS = "Соучастники: {names}"
L.TIP_ROLE_ASSIST = "Участие без смертельного удара."
L.TIP_ROLE_SUSPECT = "Только подозрение, не доказано."
L.MORE_LINE = "… и ещё {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "КНИГА ГИЛЬДИИ"  -- [max 24]
L.POSTER_IN_BOOK_OF = "В книгах: {names}"
L.POSTER_SEEN = "Встреча {time}"
L.POSTER_SEEN_BY = "Встреча {time}, источник: {name}"
L.TIP_IN_BOOK_OF = "В книгах"
L.POSTER_REMARK = "ПОМЕТКА"  -- [max 12]
L.POSTER_BY_HAND = "ВПИСАНО ВРУЧНУЮ"  -- [max 22]
L.POSTER_VICTIMS = "ЖЕРТВЫ"  -- [max 12]
L.POSTER_LISTED = "ВПИСАЛИ"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Вписано вручную."
L.POSTER_NO_DEEDS_SENT = "Злодеяния не переданы."
L.POSTER_NONE_KNOWN = "неизвестны"
L.POSTER_NO_NAMES = "имена не переданы"
L.TIP_VICTIMS = "Жертвы"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Заявка: {time}"
L.HUNT_REASON = "Причина: {reason}"
L.POSTER_HUNTLIST = "СПИСОК НА ОТСТРЕЛ"  -- [max 24]
L.POSTER_RELEASED_N = "охота объявлена {times}"
L.POSTER_RELEASED_BY = "Заявки: {names}"
L.POSTER_TAKEN_DOWN = "ЦЕЛЬ УБИТА"  -- [max 12]
L.POSTER_NOT_YET = "ПОКА НЕТ"  -- [max 18]
L.POSTER_CALLS = "ЗАЯВКИ"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Больше никого."
L.POSTER_LAST = "ПОСЛЕДНИЙ РАЗ"  -- [max 13]
L.POSTER_TAKEN_BY = "смертельный удар: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "цель пока никто не убил"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Смерть"  -- [max 20]
L.CASE_ASSISTS = "СОУЧАСТНИКИ"  -- [max 24]
L.CASE_PICK = "НАЗНАЧИТЬ УБИЙЦУ"  -- [max 24]
L.CASE_NOT_COUNTED = "Не в счёт (подземелье, поле боя или дуэль)"
L.CASE_KILLER = "УБИЙЦА"  -- [max 24]
L.CASE_KILLER_SUSPECT = "УБИЙЦА (ПОДОЗРЕНИЕ)"  -- [max 24]
L.CASE_CLICK_NAME = "Клик по имени открывает плакат."
L.CASE_GONE = "Больше нет в книге."
L.CASE_KILLER_UNCLEAR = "КТО УБИЛ: НЕЯСНО"  -- [max 24]
L.CASE_SEVERAL = "Под подозрением несколько игроков. Чьё имя вписать в книгу?"
L.CASE_NOBODY = "Под подозрением никого."
L.CASE_HOW = "ЧТО СЛУЧИЛОСЬ"  -- [max 24]
L.CASE_PVE = "Монстр или сам мир. Не дело для книги."
L.CASE_UNCLEAR = "Неясно"
L.CASE_DARK = "Следствие блуждает в потёмках."
L.TIP_MORE_CANDIDATES = "Другие кандидаты"
L.CASE_SOURCE_SUSPECT = "Подозрение: незадолго до смерти этот игрок держал тебя в цели."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Строка в подсказке при наведении на убийцу"  -- [max 44]
L.OPT_MINIMAP = "Кнопка у миникарты"  -- [max 44]
L.OPT_ALERT = "Тревога, когда появляется убийца"  -- [max 44]
L.OPT_FLASH = "Мигать красным краем экрана"  -- [max 44]
L.OPT_SUSPECTS = "Сообщать и о подозреваемых"  -- [max 44]
L.OPT_DEATHMSG = "Сообщение после смерти в PvP"  -- [max 44]
L.OPT_G_SHARE = "Делиться своими смертями"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Делиться ручными записями"  -- [max 44]
L.OPT_G_RECEIVE = "Получать книгу гильдии"  -- [max 44]
L.OPT_G_ALERT = "Предупреждать об убийцах из книги гильдии"  -- [max 44]
L.OPT_G_ALERTLISTED = "Предупреждать и о ручных записях"  -- [max 44]
L.OPT_G_ANNOUNCE = "Сообщать, когда убивают согильдийца"  -- [max 44]
L.OPT_G_SIGHTINGS = "Делиться встречами"  -- [max 44]
L.OPT_F_SHARE = "Делиться с гильдией"  -- [max 44]
L.OPT_F_FRIENDS = "Делиться с друзьями"  -- [max 44]
L.OPT_F_ALERT = "Предупреждать об убийцах гильдии и друзей"  -- [max 44]
L.OPT_F_ALERTHUNT = "Предупреждать о целях из списка на отстрел"  -- [max 44]
L.OPT_F_ANNOUNCE = "Сообщать о смертях согильдийцев и друзей"  -- [max 44]
L.OPT_F_SIGHTINGS = "Делиться встречами с гильдией и друзьями"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Гильдия"  -- [max 14]
L.SET_BOOK_SIZE = "Размер книги"  -- [max 34]
L.SET_LANGUAGE = "Язык"  -- [max 16]
L.SET_LANG_AUTO = "Автоматически"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Нужна перезагрузка."  -- [max 28]
L.SET_LANG_RELOAD = "Перезагрузить"  -- [max 22]
L.SET_SEC_SHARE = "ПЕРЕДАЧА"  -- [max 24]
L.IO_EXPORT = "Сохранить книгу"  -- [max 17]
L.IO_IMPORT = "Загрузить книгу"  -- [max 17]
L.SET_HINT_BOOK = "«Сохранить» выдаёт книгу текстом: чтобы хранить или передать тем, кто не в гильдии. «Загрузить» объединяет и ничего не перезаписывает."
L.SET_SEC_SOUND = "ЗВУК"  -- [max 24]
L.SET_SOUND = "Звук"  -- [max 22]
L.SET_VOLUME = "Громкость"  -- [max 22]
L.SET_CHANNEL = "Канал"  -- [max 12]
L.SET_SEC_THRESHOLD = "ПОРОГ"  -- [max 24]
L.SET_COOLDOWN = "Пауза для каждого убийцы"  -- [max 34]
L.SET_MINKILLS = "Смертей от убийцы до тревоги"  -- [max 34]
L.SET_ALERT_SIZE = "Размер тревоги"  -- [max 34]
L.SET_TEST_ALERT = "Пробная тревога"  -- [max 17]
L.SET_G_MINKILLS = "Смертей до тревоги гильдии"  -- [max 34]
L.SET_F_MINKILLS = "Смертей до тревоги"  -- [max 34]
L.SET_SEC_STATUS = "СОСТОЯНИЕ"  -- [max 24]
L.SET_SEC_SHARING = "ОБМЕН"
L.SET_SEC_WARN = "ТРЕВОГА"
L.SET_MORE = "Ещё"
L.SET_GUILD_CLEAR = "Очистить книгу гильдии"  -- [max 26]
L.SET_HINT_GUILD = "Получает только твоя гильдия. Что приходит оттуда, хранится отдельно от твоей книги, пока ты не перенесёшь это к себе."
L.SET_HINT_FRIENDS = "Получают только гильдия и друзья с DeathNote."
L.BTN_BACK = "Назад"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Синхронизация"  -- [max 14]
L.SYNC_AGAIN_IN = "через {seconds} с"  -- [max 16]
L.TIP_FRIENDS = "Друзья"
L.TIP_GUILD_NAME = "Гильдия {guild}"
L.TIP_MATES_WITH = "Согильдийцы с DeathNote:"
L.TIP_NO_MATE = "Согильдийцев с DeathNote пока не слышно."
L.TIP_FRIENDS_WITH = "Друзья с DeathNote:"
L.TIP_SHARED = "Передаётся: твои подтверждённые смерти, ручные записи и твои заявки на охоту."
L.TIP_NOT_SHARED = "Не передаётся: заметки, подозрения, помилованные, загруженные записи."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Загрузить"  -- [max 17]
L.IO_DONE = "Загружено. Новых: {new}, объединено: {merged}."
L.IO_FAILED = "Не получилось."
L.IO_SMALL = "Кратко"  -- [max 17]
L.IO_ALL = "Показать всё"  -- [max 17]
L.IO_MSG_FULL = "Вся книга со злодеяниями ({size})."
L.IO_MSG_SHORT = "Только имена и счётчики ({size}). Со злодеяниями: {full}."
L.IO_MSG_BIG = "Большая книга ({size}): выделение и копирование займут немного времени."
L.IO_HELP_EXPORT = "Текст выделен: Ctrl+C копирует его. Сохрани его или передай друзьям."
L.IO_HELP_IMPORT = "Вставь сохранённый текст через Ctrl+V, затем «Загрузить». Ничего не перезапишется."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Причину увидят все в твоей гильдии и твои друзья с DeathNote."
L.REL_HINT_GUILD = "Причину увидят все в твоей гильдии с DeathNote."
L.REL_HINT_FRIENDS = "Причину увидят твои друзья с DeathNote."
L.REL_HEAD = "Объявить охоту"  -- [max 24]
L.REL_FOR = "ДЛЯ"  -- [max 6]
L.REL_REASON = "ПРИЧИНА"  -- [max 8]
L.REL_HINT2 = "Твоя заметка остаётся у тебя. Отменить свою заявку можешь только ты."
L.REL_GO = "Объявить охоту"  -- [max 17]
L.REL_NONE = "Гильдии нет, а обмен с друзьями выключен."
L.REL_CAP = "Не больше {own} своих заявок и {max} целей в списке."
L.REL_FAILED = "Сейчас охоту объявить нельзя."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} с"  -- [max 7]
L.SET_HINT_SILENT = "Без звука: тревога только показывается."
L.SET_HINT_BUILTIN = "Громкость этого звука зависит от канала в настройках игры."
L.SET_HINT_LEVELS = "Пять ступеней, от тихо до громко. Поверх действует ползунок канала в настройках игры."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Гильдия и друзья"  -- [max 18]
L.TIP_HELP_BUTTON = "Как работает книга"
L.VIEW_HUNT = "На отстрел"  -- [max 13]
L.VIEW_BY_KILLER = "По убийцам"  -- [max 13]
L.VIEW_BY_MATE = "По жертвам"  -- [max 13]
L.SRC_ALL = "Все"  -- [max 12]
L.SRC_GUILD = "Гильдия"  -- [max 12]
L.SRC_FRIENDS = "Друзья"  -- [max 12]
L.SORT_HIDE_PARDONED = "Скрыть помилованных"  -- [max 24]
L.SORT_SHOW_PARDONED = "Показать помилованных"  -- [max 24]
L.SEARCH_ADD = "Найти или вписать …"  -- [max 26]
L.SEARCH_SHORT = "Поиск …"  -- [max 10]
L.SEARCH_KILLER = "Найти убийцу …"  -- [max 15]
L.SEARCH_JOURNAL = "Убийца или место …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Свернуть все"
L.TIP_EXPAND_ALL = "Развернуть все"
L.STATUS_NO_PLATES = "Индикаторы здоровья противников выключены: тревога видит только цель и курсор."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "В розыске: {count}"
L.MM_UNSOLVED = "Не раскрыто: {count}"
L.MM_ALERT_OFF = "Тревога выключена (средний клик)"
L.MM_CLICK = "Клик: книга · Правый клик: Распорядок"
L.MM_MIDDLE = "Средний клик: тревога вкл./выкл."
L.MM_DRAG = "Перетаскивание: двигать по краю миникарты"
L.MM_CHAT_ALERT_ON = "Тревога включена."
L.MM_CHAT_ALERT_OFF = "Тревога выключена."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "ВРАГ ГИЛЬДИИ № 1"  -- [max 25]
L.STAMP_HUNT = "ОХОТА ОТКРЫТА"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} выдаёт себя за твоего друга {friend}: отказано."
L.FRIENDS_SHORT_IMPOSTOR = "Отказ чужаку"  -- [max 22]
L.ALERT_LEVEL = "Уровень {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "был уровень {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Уровень ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · в списке на отстрел ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|новая цель|новые цели|новых целей}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "новое в списке на отстрел"
L.OPT_F_ANNOUNCEHUNT = "Сообщать о списке на отстрел: новые, убитые"  -- [max 44]
L.SET_HUNT_EXPIRE = "Заявки истекают через"  -- [max 30]
L.SET_EXPIRE_NEVER = "Никогда"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|день|дня|дней}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Очистить книгу друзей"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Очистить книгу друзей на этом компьютере?\nЕё список на отстрел тоже пропадёт, твои заявки останутся."
L.CONFIRM_CALLOFF_ALL = "Отменить все свои заявки на охоту?\nГильдия и друзья узнают об этом постепенно."
L.CONFIRM_CALLOFF_ALL_OK = "Отменить все"  -- [max 14]
L.ACT_CALLOFF_ALL = "Отменить все мои заявки"  -- [max 24]
L.ACT_HUNT_HIDE = "Скрыть для меня"  -- [max 19]
L.ACT_HUNT_SHOW = "Показать снова"  -- [max 19]
L.HUNT_ROW_HIDDEN = "скрыто для тебя"
L.HUNT_ROW_CALLS = "{count} {count|заявка|заявки|заявок}: {names}"
L.POSTER_ON_HUNTLIST = "В списке на отстрел ({names})"
L.REL_SELF = "На себя охоту не объявить."
L.REL_MATE = "Это кто-то из своих (гильдия или друзья с DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Кто твой друг {friend}: {a} или {b}? Выбери."
L.FRIENDS_SHORT_CONFLICT = "Друг под вопросом"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Два игрока называют себя твоим другом {friend}: {a} и {b}. Пока ты не выберешь, книга ничего не принимает ни от одного из них. Гильдия и друзья, вид По жертвам: правый клик по имени."
L.MEMBER_CONFLICT = "Правый клик: это твой друг?"  -- [max 40]
L.ACT_TIE_MINE = "Мой друг: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Отвязать имя"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Отвязать {name} от твоего списка друзей?\nВсё, что это имя принесло в книгу друзей, будет удалено; следующее сообщение под этим именем привяжет заново."
L.CHAT_FRIENDS_TIES = "Привязанные полные имена (* = первый контакт, ещё не подтверждено): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Имя [Фамилия]> <золото>  назначить свою награду (без суммы: отозвать)"
L.CHAT_WHO_BOUNTY = "За кого? /dn bounty <Имя> <золото>"
L.CHAT_BOUNTY_SET = "{name}: назначена твоя награда {gold} з. Гильдия и друзья с DeathNote её видят."
L.CHAT_BOUNTY_OFF = "{name}: твоя награда отозвана."
L.CHAT_BOUNTY_NONE = "{name}: твоей награды нет."
L.CHAT_BOUNTY_BAD = "Награда: целое число золотых, от 1 до 99999 (0 отзывает)."
L.CHAT_BOUNTY_CAP = "Награду не назначить: своих не больше {count}."
L.CHAT_BOUNTY_OURS = "Нельзя назначить награду за себя и своих (гильдия или друзья с DeathNote)."
L.ACT_BOUNTY = "Назначить награду"  -- [max 24]
L.ACT_UNDO = "Отменить"  -- [max 19]
L.ACT_REVENGE_TAKE = "Снять одну месть"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, твоя награда"
L.POSTER_BOUNTY_BY = "{gold}, назначает: {name}"
L.POSTER_BOUNTY_MANY = "Награда {gold}: {names}"
L.POSTER_AVENGED = "Отомстили: {names}"
L.ROW_AVENGED = "отомщено {times}"
L.BOUNTY_TIP_HEAD = "Твоя награда в золоте"
L.BOUNTY_TIP_RULES = "Целое число от 1 до 99999. Пусто или 0: снова значение книги. Enter назначает, Esc отменяет."
L.BOUNTY_TIP_PROMISE = "Гильдия и друзья с DeathNote её видят. Это лишь обещание: расчёт между собой."
L.BOUNTY_TIP_CLICK = "Щелчок: назначить свою награду"
L.CHAT_AVENGED = "Месть за тебя: {killer}, от {name}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: назначена твоя награда {gold} з."
L.CHAT_BOUNTY_UNKNOWN = "{name}: нет в твоих книгах. Награда только на имя из книги, как его показывает игра: имя и фамилия."
L.CHAT_BOUNTY_LIST = "Твои награды ({count} из {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Твоих наград нет."
-- <<< BOOK
-- >>> REPUTE (1.3.0) -------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Ранг {tier} · Путь: {path}"  -- [max 32]
L.PATH_R = "Дурная слава"  -- [max 16]
L.PATH_E = "Честь"  -- [max 16]
L.PATH_J = "Охота"  -- [max 16]
L.PATH_S = "Защита"  -- [max 16]
L.PATH_NONE = "чистый лист"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) --------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "ТАИТ ОБИДУ?"  -- [max 30]
L.ALERT_LINE_VICTIM = "счёт {score} · твоя жертва, последний раз {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · счёт {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · счёт {score}, квиты"
L.ALERT_LINE_STANDING_AHEAD = "{text} · счёт {score}, переплачено"
-- <<< ALARM
-- >>> START (1.3.0) --------------------------------------------------------------------------------------------
L.SET_THEME = "Обложка"  -- [max 16]
L.START_HINT = "И то и другое можно сменить позже в Распорядке."  -- [max 60]
L.START_GO = "Вперёд"  -- [max 16]
L.START_CLOSE_TIP = "Оставить как есть"  -- [max 32]
L.CHAT_THEME_NEWS = "Новое: у книги теперь есть другие обложки. Распорядок, лист «Книга», или /dn theme."
L.HELP_START = "/dn start  окно первого запуска ещё раз (язык и обложка)"
-- <<< START
-- >>> RECORD (1.3.0) -------------------------------------------------------------------------------------------
L.TAB_RECORD = "Картотека"  -- [max 16]
L.STAMP_QUITT = "КВИТЫ"  -- [max 16]
L.STAMP_OVERPAID = "ПЕРЕПЛАЧЕНО"  -- [max 16]
L.STAMP_NR1_DOWN = "ВРАГ № 1 ПОВЕРЖЕН"  -- [max 24]
L.STATE_OPEN = "открыт"  -- [max 16]
L.STATE_EVEN = "квиты"  -- [max 16]
L.STATE_AHEAD = "переплачено"  -- [max 16]
L.STATE_VICTIM = "нет в книге"  -- [max 24]
L.STAND_LINE = "Счёт {score}"
L.STAND_TIP = "ты {mine}, он {his}"
L.TIP_IN_RECORD = "В КАРТОТЕКЕ:"
L.TIP_RECORD_LINE = "{times} от твоей руки, последний раз {time}"
L.RECORD_HEAD = "Твоё досье"  -- [max 20]
L.RECORD_LOG_HEAD = "Последние убийства"  -- [max 20]
L.RECORD_NEXT = "Следующий ранг: {rank}, ещё {points}"
L.RECORD_TOP = "Высший ранг достигнут."
L.RECORD_BAR_TIP = "Очки: {total} из {goal}"
L.RECORD_NEEDLE_LOW = "беспощадный"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "благородный"  -- [max 12]
L.RECORD_NEEDLE_TIP = "Стрелка: честь и защита против дурной славы. Охота её не двигает."
L.RECORD_KILLS = "Убийств: {kills} · Жертв: {victims}"
L.RECORD_BEST = "Рекорды: {list}"
L.RECORD_BEST_GAP = "+{count} {count|уровень|уровня|уровней}"
L.RECORD_BEST_STREAK = "серия {count}"
L.RECORD_BEST_QUICK = "быстрейшая месть {time}"
L.DUR_SECONDS = "{count} с"
L.DUR_MINUTES = "{count} мин"
L.DUR_HOURS = "{count} ч"
L.RECORD_AWARDS = "ОРДЕНА"  -- [max 14]
L.RECORD_AWARD_AT = "вручён {time}"
L.RECORD_AWARD_OPEN = "ещё не вручён"
L.RECORD_MORE = "Показать ещё"  -- [max 19]
L.RECORD_BACK = "К досье"  -- [max 19]
L.RECORD_CLEAR = "Очистить картотеку"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Очистить картотеку?\nВсе жертвы и список последних убийств пропадут. Ранг, очки и ордена останутся."
L.CONFIRM_RECORD_CLEAR_OK = "Очистить"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Вычеркнуть {name} из картотеки?\nЗаработанные очки останутся."
L.ACT_VICTIM_STRIKE = "Вычеркнуть из картотеки"  -- [max 26]
L.VICTIM_KILLED = "{times} от твоей руки"
L.VICTIM_POINTS = "Очки для тебя: {points}"
L.VICTIM_SCENE = "Место: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "ТВОИ УБИЙСТВА"  -- [max 14]
L.KILL_TAG_REVENGE = "месть"  -- [max 14]
L.KILL_TAG_KICK = "по лежачему"  -- [max 14]
L.KILL_TAG_GROUP = "группа"  -- [max 14]
L.KILL_WITH_GROUP = "С группой."
L.BAND_GRAU = "серый"  -- [max 12]
L.BAND_GRUEN = "зелёный"  -- [max 12]
L.BAND_GELB = "жёлтый"  -- [max 12]
L.BAND_ORANGE = "оранжевый"  -- [max 12]
L.BAND_ROT = "красный"  -- [max 12]
L.BAND_SCHAEDEL = "череп"  -- [max 12]
L.BAND_UNBEKANNT = "неизвестно"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "без очков"
L.RECORD_BANDS = "По цвету уровня"
L.TIP_PATH_R = "Дурная слава: убийства серых и зелёных."
L.TIP_PATH_E = "Честь: убийства игроков твоего уровня, месть."
L.TIP_PATH_J = "Охота: убийства тех, кто выше уровнем, целей из списка на отстрел и за награду."
L.TIP_PATH_S = "Защита: убийства игроков, которые убивали согильдийцев или друзей."
L.SORT_STATE = "Счёт"  -- [max 14]
L.SORT_COUNT = "Убийства"  -- [max 14]
L.SORT_POINTS = "Очки"  -- [max 14]
L.CHAT_OWN_KILL = "Картотека: {name}, {level} ({band}). {points}."
L.CHAT_KILL_WITH_GROUP = "{line} {group}"
L.CHAT_PATH = "Новый путь: {path}. Ранг: {rank}."
L.BANNER_RANK = "НОВЫЙ РАНГ"  -- [max 24]
L.BANNER_AWARD = "ОРДЕН"  -- [max 24]
L.OPT_LEDGER = "Вести картотеку"  -- [max 44]
L.OPT_LEDGER_CHAT = "Сообщать о своих убийствах в чат"  -- [max 44]
L.OPT_VICTIMS = "Предупреждать, когда рядом твоя жертва"  -- [max 44]
L.SET_SETTLED = "Тревога, когда счёт сведён"  -- [max 34]
L.SET_SETTLED_ALWAYS = "как всегда"  -- [max 10]
L.SET_SETTLED_QUIET = "тихо"  -- [max 10]
L.SET_SETTLED_OFF = "никогда"  -- [max 10]
L.MANUAL_RECORD_HEAD = "КАРТОТЕКА"  -- [max 14]
L.MANUAL_RECORD = "Твои убийства игроков, а также убийства твоей группы с твоим участием. Плакат и список показывают счёт «ты : он»: открыт, квиты или переплачено. Первое место всегда за открытым счётом. Убийства приносят очки для твоего ранга."
L.POSTER_LAST_SEEN_IN = "Последняя встреча: {zone}, {time}"
L.SHEET_RECORD = "Картотека"  -- [max 14]
L.EMPTY_RECORD_HEAD = "Пока никого."
L.EMPTY_RECORD_SUB = "Игрок другой стороны, которого ты убьёшь, окажется здесь."
-- <<< RECORD
end)
