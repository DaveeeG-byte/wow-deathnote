-- DeathNote: Українська (ukUA). Translation of enUS.lua by DaveeeG.
-- Plural: 3 forms {count|one|few|many} (1, 21, 31 .. not 11 | 2-4, 22-24 .. not 12-14 | 0, 5-20, 25 ..). Rule in Locale.lua (PLURAL_OF.ukUA), not here.
-- Fonts: cyrillic (Skurri/Morpheus/Friz _CYR cuts) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- No Ukrainian game client: zone, class and race names come in the client's language (SAMPLE_ZONE stays English).
--
-- TOC-Notes: Список смертей для PvP у відкритому світі: пам'ятає, хто тебе вбив, і попереджає, коли вбивця поруч.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("ukUA")) then return end

Locale.Register("ukUA", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Розшук"  -- [max 16]
L.TAB_UNSOLVED = "Нерозкрите"  -- [max 16]
L.TAB_DEATHLOG = "Журнал смертей"  -- [max 16]
L.TAB_GUILD = "Гільдія"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Розпорядок"  -- [max 24]
L.HEAD_HELP = "Як це працює"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Книга"  -- [max 14]
L.SHEET_ALERT = "Тривога"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "ВОРОГ СУСПІЛЬСТВА № 1"  -- [max 24]
L.STAMP_REVENGE = "ПОМСТУ ЗДІЙСНЕНО"  -- [max 16]
L.STAMP_PARDONED = "ПОМИЛУВАНО"  -- [max 16]
L.STAMP_SUSPECT = "ПІДОЗРА"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "ВОРОГ СУСПІЛЬСТВА № 1 ПОРУЧ"  -- [max 30]
L.ALERT_SIGHTED = "ВОРОГ СУСПІЛЬСТВА ПОРУЧ"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "ПІДОЗРЮВАНИЙ ПОРУЧ"  -- [max 30]
L.ALERT_TITLE_GUILD = "ВОРОГ ГІЛЬДІЇ ПОРУЧ"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "ВБИВЦЯ ДРУЗІВ ПОРУЧ"  -- [max 30]
L.ALERT_TITLE_HUNT = "ЦІЛЬ ЗІ СПИСКУ НА ВІДСТРІЛ"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "під підозрою"
L.ALERT_LINE_KILLED = "твоїх смертей: {times}"
L.ALERT_LINE_KILLED_ASSISTED = "твоїх смертей: {times}, співучасть: {assists}"
L.ALERT_LINE_ASSISTED = "участь у твоїй смерті: {times}"
L.ALERT_LINE_MANUAL = "вписано в книгу вручну"
L.ALERT_LINE_LAST = "{text}, востаннє {time}"
L.ALERT_LINE_IN = "{text}, місце: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Помста: {times}"
L.ALERT_HINT_CLOSE = "Правий клік: закрити"  -- [max 44]
L.ALERT_HINT_COMBAT = "Взяти в ціль можна лише після бою"  -- [max 44]
L.ALERT_HINT_TARGET = "Клік: у ціль  ·  Правий клік: закрити"  -- [max 44]
L.ALERT_MORE = "ще +{count}"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "у книзі гільдії"
L.GUILD_LINE_IN_FRIENDS = "у книзі друзів"
L.GUILD_LINE_LISTED_BY = "у книгах: {names}"
L.GUILD_LINE_KILLED_GUILD = "вбито гільдійців: {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "вбито друзів: {kills}×"
L.GUILD_LINE_KILLED_BOTH = "вбито гільдійців і друзів: {kills}×"
L.GUILD_LINE_LAST = "{text}, остання жертва: {name}"
L.HUNT_LINE_BY = "полювання за заявкою: {names}"
L.HUNT_LINE_RELEASED = "у списку на відстріл"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "під підозрою"
L.TALLY_MANUAL = "вписано вручну"
L.TALLY_NONE = "злочинів поки що немає"
L.TALLY_KILLED = "твоїх смертей: {times}"
L.TALLY_ASSISTED = "співучасть: {times}"
L.PLACE_UNKNOWN = "невідоме місце"
L.GKILLS_CAP = "щонайменше {count}"
L.NAMELIST_MORE = "{names} і ще {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY = "%d.%m"
L.TIME_FMT_DAY_YEAR = "%d.%m.%y"
L.TIME_NEVER = "ніколи"
L.TIME_JUST = "щойно"
L.TIME_MINUTES = "{count} хв тому"  -- [max 14]
L.TIME_HOURS = "{count} год тому"  -- [max 14]
L.TIME_DAYS = "{count} {count|день|дні|днів} тому"  -- [max 16]
L.MONEY_GOLD = "{count}з"
L.MONEY_SILVER = "{count}с"
L.MONEY_COPPER = "{count}м"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "Гільдійців з DeathNote на зв'язку: {count}."
L.HEALTH_NOGUILD = "Ти не в гільдії, обміну немає."
L.HEALTH_OFF = "Обмін вимкнено."
L.HEALTH_SHORT_NOGUILD = "Немає гільдії"  -- [max 18]
L.HEALTH_SHORT_OFF = "Обмін вимкнено"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Заблоковано"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Відмова"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Очікування"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Запит надіслано"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Не працює"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Без звуку"  -- [max 16]
L.SOUND_RAIDWARNING = "Оголошення рейду"  -- [max 16]
L.SOUND_BELL = "Дзвін"  -- [max 16]
L.SOUND_GONG = "Гонг"  -- [max 16]
L.SOUND_HEARTBEAT = "Серцебиття"  -- [max 16]
L.SOUND_FEATHER = "Перо"  -- [max 16]
L.SOUND_SIREN = "Сирена"  -- [max 16]
L.CHANNEL_MASTER = "Загальний"  -- [max 16]
L.CHANNEL_SFX = "Ефекти"  -- [max 16]
L.CHANNEL_DIALOG = "Діалоги"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name} тепер у книзі."
L.CHAT_REMOVED = "{name}: викреслено з книги."
L.CHAT_SYNC_WAIT = "Синхронізація щойно була. Спробуй ще раз за {seconds} с."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Імен поки що немає."
L.EMPTY_WANTED_SUB = "Вийди нарешті з дому."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  відкрити/закрити книгу"
L.HELP_ADD = "/dn add <Ім'я [Прізвище]>  вписати вбивцю в книгу вручну"
L.HELP_DEL = "/dn del <Ім'я [Прізвище]>  викреслити вбивцю з книги"
L.HELP_QUIET = "/dn quiet  тривога вимк./увімк."
L.HELP_TEST = "/dn test  показати пробну тривогу"
L.HELP_GUILD = "/dn guild  книга гільдії: стан і хто з гільдійців має DeathNote"
L.HELP_FRIENDS = "/dn friends  книга друзів: стан і хто з друзів має DeathNote"
L.HELP_SYNC = "/dn sync  синхронізувати книгу гільдії та книгу друзів зараз"
L.HELP_HUNT = "/dn hunt <Ім'я [Прізвище]>  оголосити полювання (без імені: показати список на відстріл)"
L.HELP_CALLOFF = "/dn calloff <Ім'я [Прізвище]>  скасувати свою заявку на полювання"
L.HELP_LANG = "/dn lang <код>  мова книги (enUS, deDE, ukUA ...), після /reload"
L.HELP_THEME = "/dn theme <назва>  обкладинка книги, після /reload"
L.HELP_PROBE = "/dn probe  діагностика: що гра повідомляє книзі"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  діагностика, разом із перевіркою журналу бою"
L.HELP_DEBUG = "/dn debug  діагностика: докладно записувати кожну смерть (увімк./вимк.)"
L.HELP_HELP = "/dn help  ця довідка"
L.HELP_SILENT_ZONES = "У підземеллях, на полях бою та на аренах книга сама мовчить."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "увімк."
L.WORD_OFF = "вимк."
L.CHAT_WHO_ADD = "Кого? /dn add <Ім'я>"
L.CHAT_WHO_DEL = "Кого? /dn del <Ім'я>"
L.CHAT_WHO_CALLOFF = "Кого? /dn calloff <Ім'я>"
L.CHAT_BAD_NAME = "Неприпустиме ім'я."
L.CHAT_NOT_IN_BOOK = "Немає в книзі: {name}"
L.CHAT_ALARM_ON = "Тривогу увімкнено."
L.CHAT_ALARM_OFF = "Тривогу вимкнено."
L.CHAT_DEBUG = "Журнал діагностики: {state}"
L.CHAT_UNKNOWN_CMD = "Невідома команда. Довідка: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Книгу гільдії не завантажено."
L.CHAT_NO_GUILD = "Ти не в гільдії (або гра ще про це не знає)."
L.CHAT_GUILD_STATE = "Гільдія {guild}: надсилання {share}, отримання {receive}"
L.CHAT_GUILD_BOOK = "Книга гільдії. Вбивць: {enemies} (лише вручну: {listed}), злочинів: {deeds}, з жертвами серед гільдійців: {foreign}. Ділитися ручними записами: {manual}"
L.CHAT_STATE_OK = "Стан: {text}"
L.CHAT_STATE_WARN = "Увага: {text}"
L.CHAT_NO_MATES = "Гільдійців з DeathNote поки що не чути."
L.CHAT_HAVE_DN = "З DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "З DeathNote: {names} і ще {count}"
L.CHAT_SYNC_ASKED = "Запит надіслано. Відповіді прийдуть за кілька секунд."
L.CHAT_SYNC_FAIL = "Синхронізація не працює: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "немає гільдії або обмін вимкнено."
L.CHAT_FRIENDS_NOT_LOADED = "Книгу друзів не завантажено."
L.CHAT_FRIENDS_STATE = "Друзі: обмін {share}, у мережі {online} з {total}."
L.CHAT_FRIENDS_BOOK = "Книга друзів. Вбивць: {enemies} (лише вручну: {listed}), злочинів: {deeds}."
L.CHAT_NO_FRIENDS = "Друзів з DeathNote поки що не чути."
L.CHAT_HUNT_NOT_LOADED = "Список на відстріл не завантажено."
L.CHAT_HUNT_UNKNOWN = "Невідомо: {name}. Додай і прізвище, як ім'я написано в грі."
L.CHAT_HUNT_CAP = "Оголосити полювання не можна: щонайбільше {own} своїх заявок і {targets} цілей у списку."
L.CHAT_HUNT_NOWHERE = "Зараз оголосити полювання не можна: гільдії немає, а обмін із друзями вимкнено."
L.CHAT_HUNT_BOTH = "{name}: полювання оголошено для гільдії та друзів."
L.CHAT_HUNT_GUILD = "{name}: полювання оголошено для гільдії."
L.CHAT_HUNT_FRIENDS = "{name}: полювання оголошено для твоїх друзів."
L.CHAT_CALLED_OFF = "{name}: полювання скасовано."
L.CHAT_NO_OWN_CALL = "{name}: твоєї заявки немає."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Мова зараз: {lang}. Змінити: /dn lang <код>"
L.CHAT_LANG_LIST = "Коди: {codes}"
L.CHAT_LANG_BAD = "Невідома мова: {code}"
L.CHAT_LANG_SET = "Мова: {lang}."
L.CHAT_LANG_RELOAD = "Мова: {lang}. Діятиме після /reload."
L.CHAT_THEME_CURRENT = "Обкладинка зараз: {theme}. Змінити: /dn theme <назва>"
L.CHAT_THEME_LIST = "Обкладинки: {themes}"
L.CHAT_THEME_BAD = "Невідома обкладинка: {name}"
L.CHAT_THEME_SET = "Обкладинка: {theme}."
L.CHAT_THEME_RELOAD = "Обкладинка: {theme}. Діятиме після /reload."
L.THEME_NOTEBOOK = "Чорна книга"
L.THEME_HARBOR = "Книга капера"
L.THEME_TRADE = "Майстерня"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Книга готова. Хто вб'є тебе у відкритому світі, потрапить до неї. Відкрити: /dn або кнопка біля мінікарти."
L.WELCOME_PLATES = "Таблички імен ворогів вимкнено. Без них тривога бачить лише твою ціль."
L.WELCOME_SHARE = "Гільдія та друзі, які мають DeathNote, читають її разом з тобою. Нотатки та підозри лишаються в тебе."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "У КНИЗІ:"
L.TIP_HUNT = "НА ВІДСТРІЛ:"
L.TIP_GUILDBOOK = "КНИГА ГІЛЬДІЇ:"
L.TIP_PARDONED = "помилувано"
L.TIP_RANK = "ранг {rank}"
L.TIP_REVENGE = "помста {times}"
L.TIP_LISTED_BY = "у книгах: {names}"
L.TIP_NOTE = "Нотатка: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Клік: відкрити · Правий клік: прибрати"
L.BANNER_NEW = "НОВИЙ ЗАПИС"  -- [max 24]
L.BANNER_NEW_LINE = "тепер у книзі"
L.BANNER_AGAIN = "ЗНОВУ"  -- [max 24]
L.BANNER_AGAIN_LINE = "знову твоя смерть, усього вже {count}"
L.BANNER_SUSPECT = "ПІДОЗРА"  -- [max 24]
L.BANNER_SUSPECT_LINE = "під підозрою, розберися в книзі"
L.BANNER_UNCLEAR = "ХТО ВБИВ: НЕЯСНО"  -- [max 24]
L.BANNER_CANDIDATES = "{count} {count|кандидат|кандидати|кандидатів}"
L.BANNER_UNCLEAR_LINE = "Клік: обрати вбивцю в «Нерозкрите»"
L.BANNER_REVENGE = "РОЗПЛАТА"  -- [max 24]
L.BANNER_REVENGE_LINE = "Помсту здійснено ({count}×)"
L.BANNER_GUILD = "ГІЛЬДІЯ"  -- [max 24]
L.BANNER_FRIENDS = "ДРУЗІ"  -- [max 24]
L.BANNER_KILLED_BY = "вбивця: {name}"
L.BANNER_HUNT = "СПИСОК НА ВІДСТРІЛ"  -- [max 24]
L.BANNER_BAGGED = "смертельний удар: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Обмін вимкнено (Розпорядок, аркуш «Гільдія»)."
L.SYNC_FRIENDS_OFF = "Обмін із друзями вимкнено."
L.SYNC_NOBODY = "Ні гільдії, ні друзів для обміну."
L.SYNC_SHORT_NOBODY = "Обміну немає"  -- [max 18]
L.SYNC_PREFIX = "Гра не дає отримувати дані. Допоможе повторний вхід."
L.SYNC_SHORT_PREFIX = "Дані не надходять"  -- [max 18]
L.SYNC_BLOCKED = "Сервер блокує надсилання. Передай книгу через «Зберегти книгу»."
L.SYNC_SHORT_BLOCKED = "Надсилання заблоковано"  -- [max 22]
L.SYNC_FAILING = "Надсилання зараз не проходить, пробуємо ще."
L.SYNC_SHORT_FAILING = "Надсилання буксує"  -- [max 18]
L.SYNC_HOLD = "Надсилання чекає, {wait}."
L.SYNC_HOLD_INSTANCE = "поки ти не вийдеш з підземелля"
L.SYNC_HOLD_COMBAT = "поки ти не вийдеш з бою"
L.SYNC_HOLD_LOCKDOWN = "поки чат знову не звільниться"
L.SYNC_HOLD_AGAIN = "поки знову не запрацює"
L.SYNC_HOLD_SHORT_INSTANCE = "Чекає: підземелля"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Чекає: бій"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Чекає: чат"  -- [max 18]
L.SYNC_QUIET = "Надіслано, але гільдійців з DeathNote поки що не чути."
L.SYNC_READY = "Готово. Гільдійців з DeathNote поки що не чути."
L.SYNC_RUNNING = "Працює: {count} {count|гільдієць|гільдійці|гільдійців} з DeathNote."
L.SYNC_RUNNING_ALL = "Працює. З DeathNote у гільдії та серед друзів: {count}."
L.FRIENDS_OFF = "Обмін із друзями вимкнено (Розпорядок, аркуш «Гільдія»)."
L.FRIENDS_BLOCKED = "Сервер блокує шепіт. Друзі нічого не отримають."
L.FRIENDS_SHORT_BLOCKED = "Шепіт заблоковано"  -- [max 22]
L.FRIENDS_FAILING = "Шепіт зараз не проходить, пробуємо ще."
L.FRIENDS_SHORT_FAILING = "Шепіт буксує"  -- [max 18]
L.FRIENDS_NONE_LISTED = "У списку друзів нікого немає."
L.FRIENDS_NONE_ONLINE = "Зараз нікого з друзів немає в мережі."
L.FRIENDS_SHORT_NONE_ONLINE = "Друзі не в мережі"  -- [max 18]
L.FRIENDS_QUIET = "Запит надіслано, але друзів з DeathNote поки що не чути."
L.FRIENDS_READY = "Готово. Друзів з DeathNote поки що не чути."
L.FRIENDS_HOLD = "Надсилання друзям чекає, поки знову не запрацює."
L.FRIENDS_RUNNING = "Працює: {count} {count|друг|друзі|друзів} з DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Перенесено з книги гільдії (вбито гільдійців: {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Базу даних не завантажено."
L.IMPORT_NO_TEXT = "Немає тексту."
L.IMPORT_NO_HEADER = "Бракує першого рядка (він починається з {header}). Скопіюй текст повністю."
L.IMPORT_NOT_EXPORT = "Це не експорт DeathNote (немає рядка заголовка або не та версія)."
L.IMPORT_TOO_LONG = "Забагато рядків (щонайбільше {count})."
L.IMPORT_BAD_KEY = "Рядок {line}: хибний ключ."
L.IMPORT_BAD_TIME = "Рядок {line}: хибний час."
L.IMPORT_BROKEN = "Рядок {line} неповний або пошкоджений (текст обрізано?). Нічого не завантажено."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "так"
L.WORD_NO = "ні"
L.PROBE_HEAD = "Перевірка: інтерфейсів {apis}/{apisAll}, подій для реєстрації {events}/{eventsAll}."
L.PROBE_MISSING = "Бракує: {list}"
L.PROBE_NOT_REGISTERABLE = "Не реєструються: {list}"
L.PROBE_SOURCES = "Recap зараз: {recap} · Meter: {meter} · Журнал бою: {clog}"
L.PROBE_READABLE = "читається"
L.PROBE_DEAD = "не працює"
L.PROBE_PLATES = "Таблички імен ворогів: {plates} · Відкритий світ: {open}"
L.PROBE_PLATES_OFF = "ВИМК. (гравців видно лише через ціль і курсор)"
L.PROBE_TARGET = "Ціль: ім'я={name} GUID={guid} клас={class} ворожий={enemy} цілиться в мене={me}"
L.PROBE_GUILD = "Гільдія: префікс {prefix} · надсилання {send} · останній код повернення {result} · надіслано {sent}, отримано {received}, відкинуто {dropped}"
L.PROBE_REGISTERED = "зареєстровано"
L.PROBE_NOT_REGISTERED = "НЕ зареєстровано ({result})"
L.PROBE_POSSIBLE = "можливо"
L.PROBE_ABSENT = "немає"
L.PROBE_WAITS = " · чекає: {why}"
L.PROBE_LISTED = "Ручні записи (M): надіслано {sent}, отримано {received}, відкинуто {dropped} · викреслені (X): надіслано {usent}, отримано {ureceived}, відкинуто {udropped}"
L.PROBE_GUILDBOOK = "Книга гільдії: {text}"
L.PROBE_SAVED = "Збережено в DeathNoteDB.probe (у файлі після /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Ранг"  -- [max 14]
L.SORT_RECENT = "Нові"  -- [max 14]
L.SORT_NAME = "Ім'я"  -- [max 14]
L.SORT_SEEN = "Помічено"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Хто вб'є тебе у відкритому світі, опиниться тут. Книга запише сама."
L.EMPTY_OPEN_HEAD = "Нерозкритих справ немає."
L.EMPTY_JOURNAL_HEAD = "Жодної смерті."
L.EMPTY_JOURNAL_SUB = "Повага. Або брехня."
L.EMPTY_NOGUILD_HEAD = "Немає гільдії."
L.EMPTY_NOGUILD_SUB = "Помирати можна й наодинці."
L.EMPTY_GUILDOFF_HEAD = "Книгу гільдії закрито."
L.EMPTY_GUILDOFF_SUB = "Обмін вимкнено. Де ввімкнути, знає Розпорядок."
L.EMPTY_GUILDNIL_HEAD = "З гільдії поки що ні слова."
L.EMPTY_GUILDNIL_SUB = "Твою книгу буде надіслано, щойно хтось із гільдійців матиме DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "У книзі гільдії поки що порожньо."
L.EMPTY_GUILDQUIET_SUB = "Твоїх гільдійців поки що не чіпали."
L.EMPTY_FRIENDSOFF_HEAD = "Книгу друзів закрито."
L.EMPTY_FRIENDSOFF_SUB = "Обмін із друзями вимкнено. Де ввімкнути, знає Розпорядок."
L.EMPTY_FRIENDSNIL_HEAD = "Друзів з DeathNote поки що не чути."
L.EMPTY_FRIENDSNIL_SUB = "Твою книгу буде надіслано, щойно хтось із друзів матиме DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Від друзів поки що нічого."
L.EMPTY_FRIENDSQUIET_SUB = "Твоїх друзів поки що не чіпали."
L.EMPTY_NOBODY_HEAD = "Ні гільдії, ні друзів."
L.EMPTY_NOBODY_SUB = "Помирати можна й наодинці."
L.EMPTY_NOBODY_HINT = "Щойно гільдійці або друзі зі списку друзів матимуть DeathNote, тут буде видно, що з ними відбувається."
L.EMPTY_SHAREDNIL_HEAD = "Поки що нікого з DeathNote не чути."
L.EMPTY_SHAREDNIL_SUB = "Твою книгу буде надіслано, щойно гільдійці або друзі матимуть DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Тут поки що порожньо."
L.EMPTY_SHAREDQUIET_SUB = "Гільдію та друзів поки що не чіпали."
L.EMPTY_HUNT_HEAD = "Список на відстріл порожній."
L.EMPTY_HUNT_SUB = "На плакаті: «Оголосити полювання»."
L.EMPTY_HUNT_HINT = "Або в чаті: /dn hunt Ім'я Прізвище. Це побачать усі у твоїй гільдії та твої друзі."
L.EMPTY_SEARCH_HEAD = "Збігів немає."
L.EMPTY_SEARCH_SUB = "Enter впише ім'я в книгу."
L.EMPTY_SEARCHRO_HEAD = "Збігів немає."
L.EMPTY_SEARCHRO_SUB = "Іноді допомагає інше написання."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "КНИГА"  -- [max 12]
L.MANUAL_BOOK = "Хто вб'є тебе у відкритому світі, автоматично потрапить до книги. Клік на повідомлення після смерті відкриває сторінку вбивці."
L.MANUAL_WANTED_HEAD = "РОЗШУК"  -- [max 12]
L.MANUAL_WANTED = "Твої вбивці, найгірші першими. Клік показує плакат зі злочинами й нотаткою. Помилувані стоять закреслені в кінці."
L.MANUAL_UNSOLVED_HEAD = "НЕРОЗКРИТЕ"  -- [max 13]
L.MANUAL_UNSOLVED = "Якщо неясно, хто це зробив, справа чекає тут. Клік на ім'я визначає вбивцю."
L.MANUAL_ALERT_HEAD = "ТРИВОГА"  -- [max 12]
L.MANUAL_ALERT = "Коли з'являється табличка вбивці або вбивця опиняється в цілі чи під курсором, книга подає голос. Клік бере в ціль, а в бою лише після нього."
L.MANUAL_ADD_HEAD = "ЗАПИС"  -- [max 12]
L.MANUAL_ADD = "Впиши ім'я в поле пошуку, Enter. Правий клік на рядку: позначити помсту, помилувати, викреслити."
L.MANUAL_GUILD_HEAD = "ГІЛЬДІЯ"  -- [max 12]
L.MANUAL_GUILD = "Гільдійці та друзі з DeathNote бачать твої підтверджені смерті й ручні записи. Плакат або /dn hunt Ім'я: оголосити полювання. Клік по нагороді: призначити свою, лише обіцянка, розрахунок між собою."
L.MANUAL_SHARE_HEAD = "ПЕРЕДАТИ"  -- [max 12]
L.MANUAL_SHARE = "Розпорядок, «Зберегти книгу»: текст для копіювання, для всіх без DeathNote."
L.MANUAL_QUIET_HEAD = "ТИША"  -- [max 12]
L.MANUAL_QUIET = "У підземеллях і на полях бою тривога мовчить. В інших місцях: середній клік на кнопку біля мінікарти або /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Викреслити з книги: {name}?\nУсі злочини й нотатку буде втрачено."
L.CONFIRM_DELETE_OK = "Викреслити"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Очистити книгу гільдії на цьому комп'ютері?\nЇї список на відстріл теж зникне, твої заявки лишаться.\nТвоя власна книга лишиться як є."
L.CONFIRM_GUILD_CLEAR_OK = "Очистити"  -- [max 14]
L.CONFIRM_CANCEL = "Скасувати"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ЗОЛОТА"  -- [max 14]
L.BOUNTY_SILVER = "{count} СРІБЛА"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Підтвердити"  -- [max 19]
L.ACT_DISMISS = "Відхилити"  -- [max 19]
L.ACT_HUNT_AGAIN = "Знову в розшук"  -- [max 19]
L.ACT_REVENGE = "Позначити помсту"  -- [max 19]
L.ACT_PARDON = "Помилувати"  -- [max 19]
L.ACT_STRIKE = "Викреслити"  -- [max 19]
L.ACT_OPEN_OWN = "Відкрити в книзі"  -- [max 19]
L.ACT_ADOPT = "До моєї книги"  -- [max 19]
L.ACT_CALLOFF = "Скасувати полювання"  -- [max 19]
L.ACT_RELEASE = "Оголосити полювання"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "помічено {time}"
L.ROW_NOT_SEEN = "ще не помічено"
L.ROW_PARDONED = "помилувано"
L.ROW_SUSPECT = "Підозра"
L.MARK_REVENGE = "ПОМСТА {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Хто вбив, неясно"
L.MARK_CANDIDATES = "{count} {count|КАНДИДАТ|КАНДИДАТИ|КАНДИДАТІВ}"  -- [max 16]
L.MARK_SUSPECT = "ПІДОЗРА"  -- [max 16]
L.ROW_NO_PLAYER = "Не гравець"
L.ROW_UNCLEAR = "Неясно як"
L.MARK_NOT_COUNTED = "НЕ РАХУЄТЬСЯ"  -- [max 16]
L.ROW_LISTED_BY = "вписали: {names}"
L.ROW_GKILLED = "вбивств: {kills}×"
L.ROW_VICTIMS = "{count} {count|жертва|жертви|жертв}"
L.ROW_LAST = "востаннє: {text}"
L.MARK_IN_BOOK = "У КНИЗІ"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|вбивця|вбивці|вбивць}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|смерть|смерті|смертей}"  -- [max 12]
L.MEMBER_LISTED = "{count} вручну"  -- [max 14]
L.MEMBER_ME = "що бачать про тебе інші"
L.MEMBER_NOTHING = "поки що нічим не поділилися"
L.MEMBER_LAST_DIED = "остання смерть {time}"
L.MARK_YOU = "ти"  -- [max 16]
L.MARK_FRIEND = "ДРУГ"  -- [max 16]
L.MARK_BOTH = "ГІЛЬДІЄЦЬ, ДРУГ"  -- [max 20]
L.MARK_TAKEN_DOWN = "ВПОЛЮВАНО {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ЖИВИМ АБО МЕРТВИМ"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "ЗЛОЧИНИ"  -- [max 14]
L.POSTER_NOTE = "НОТАТКА"  -- [max 8]
L.POSTER_BOUNTY = "НАГОРОДА"  -- [max 12]
L.ROLE_ASSIST = "співучасть"  -- [max 14]
L.ROLE_SUSPECT = "підозра"  -- [max 14]
L.POSTER_LEVEL = "Рівень {level}"
L.POSTER_GUILD = "Гільдія: {guild}"
L.POSTER_LAST_SEEN = "Востаннє помічено {time}"
L.POSTER_NOT_SEEN = "Ще не помічено"
L.POSTER_ONLY_SUSPECT = "Лише підозра, доведених злочинів немає."
L.POSTER_NO_DEEDS = "Злочинів не записано."
L.TIP_LISTED_AT = "Вписано {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Причина смерті: {spell}"
L.TIP_VICTIM = "Жертва: {name}"
L.TIP_VICTIM_LEVEL = "Жертва: {name} (рівень {level})"
L.TIP_KILLER_LEVEL = "Рівень вбивці: {level}"
L.TIP_ASSISTS = "Співучасники: {names}"
L.TIP_ROLE_ASSIST = "Участь без смертельного удару."
L.TIP_ROLE_SUSPECT = "Лише підозра, не доведено."
L.MORE_LINE = "… і ще {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "КНИГА ГІЛЬДІЇ"  -- [max 24]
L.POSTER_IN_BOOK_OF = "У книгах: {names}"
L.POSTER_SEEN = "Помічено {time}"
L.POSTER_SEEN_BY = "Помічено {time}, джерело: {name}"
L.TIP_IN_BOOK_OF = "У книгах"
L.POSTER_REMARK = "ПОМІТКА"  -- [max 12]
L.POSTER_BY_HAND = "ВПИСАНО ВРУЧНУ"  -- [max 22]
L.POSTER_VICTIMS = "ЖЕРТВИ"  -- [max 12]
L.POSTER_LISTED = "ВПИСАЛИ"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Вписано вручну."
L.POSTER_NO_DEEDS_SENT = "Злочинів не передано."
L.POSTER_NONE_KNOWN = "невідомо"
L.POSTER_NO_NAMES = "імен не передано"
L.TIP_VICTIMS = "Жертви"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Заявка: {time}"
L.HUNT_REASON = "Причина: {reason}"
L.POSTER_HUNTLIST = "СПИСОК НА ВІДСТРІЛ"  -- [max 24]
L.POSTER_RELEASED_N = "полювання оголошено {times}"
L.POSTER_RELEASED_BY = "Заявки: {names}"
L.POSTER_TAKEN_DOWN = "ВПОЛЮВАНО"  -- [max 12]
L.POSTER_NOT_YET = "ЩЕ НІ"  -- [max 18]
L.POSTER_CALLS = "ЗАЯВКИ"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Більше нікого."
L.POSTER_LAST = "ВОСТАННЄ"  -- [max 13]
L.POSTER_TAKEN_BY = "смертельний удар: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "ще ніким не вполювано"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Смерть"  -- [max 20]
L.CASE_ASSISTS = "СПІВУЧАСНИКИ"  -- [max 24]
L.CASE_PICK = "ВИЗНАЧИТИ ВБИВЦЮ"  -- [max 24]
L.CASE_NOT_COUNTED = "Не рахується (підземелля, поле бою або дуель)"
L.CASE_KILLER = "ВБИВЦЯ"  -- [max 24]
L.CASE_KILLER_SUSPECT = "ВБИВЦЯ (ПІДОЗРА)"  -- [max 24]
L.CASE_CLICK_NAME = "Клік на ім'я відкриває плакат."
L.CASE_GONE = "Більше немає в книзі."
L.CASE_KILLER_UNCLEAR = "ХТО ВБИВ: НЕЯСНО"  -- [max 24]
L.CASE_SEVERAL = "Під підозрою кілька гравців. Чиє ім'я вписати в книгу?"
L.CASE_NOBODY = "Під підозрою нікого."
L.CASE_HOW = "ЩО СТАЛОСЯ"  -- [max 24]
L.CASE_PVE = "Монстр або сам світ. Не справа для книги."
L.CASE_UNCLEAR = "Неясно"
L.CASE_DARK = "Слідство блукає в темряві."
L.TIP_MORE_CANDIDATES = "Інші кандидати"
L.CASE_SOURCE_SUSPECT = "Підозра: незадовго до смерті цей гравець тримав тебе в цілі."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Рядок у підказці при наведенні на вбивцю"  -- [max 44]
L.OPT_MINIMAP = "Кнопка біля мінікарти"  -- [max 44]
L.OPT_ALERT = "Тривога, коли з'являється вбивця"  -- [max 44]
L.OPT_FLASH = "Блимати червоним краєм екрана"  -- [max 44]
L.OPT_SUSPECTS = "Повідомляти й про підозрюваних"  -- [max 44]
L.OPT_DEATHMSG = "Повідомлення після смерті в PvP"  -- [max 44]
L.OPT_G_SHARE = "Ділитися своїми смертями"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Ділитися ручними записами"  -- [max 44]
L.OPT_G_RECEIVE = "Отримувати книгу гільдії"  -- [max 44]
L.OPT_G_ALERT = "Попереджати про вбивць із книги гільдії"  -- [max 44]
L.OPT_G_ALERTLISTED = "Попереджати й про ручні записи"  -- [max 44]
L.OPT_G_ANNOUNCE = "Повідомляти, коли вбито гільдійця"  -- [max 44]
L.OPT_G_SIGHTINGS = "Ділитися спостереженнями"  -- [max 44]
L.OPT_F_SHARE = "Ділитися з гільдією"  -- [max 44]
L.OPT_F_FRIENDS = "Ділитися з друзями"  -- [max 44]
L.OPT_F_ALERT = "Попереджати про вбивць гільдії та друзів"  -- [max 44]
L.OPT_F_ALERTHUNT = "Попереджати про цілі зі списку на відстріл"  -- [max 44]
L.OPT_F_ANNOUNCE = "Повідомляти про смерті гільдійців і друзів"  -- [max 44]
L.OPT_F_SIGHTINGS = "Спостереження: ділитися з гільдією й друзями"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Гільдія"  -- [max 14]
L.SET_BOOK_SIZE = "Розмір книги"  -- [max 34]
L.SET_LANGUAGE = "Мова"  -- [max 16]
L.SET_LANG_AUTO = "Автоматично"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Потрібне перезавантаження."  -- [max 28]
L.SET_LANG_RELOAD = "Перезавантажити"  -- [max 22]
L.SET_SEC_SHARE = "ПЕРЕДАТИ"  -- [max 24]
L.IO_EXPORT = "Зберегти книгу"  -- [max 17]
L.IO_IMPORT = "Завантажити книгу"  -- [max 17]
L.SET_HINT_BOOK = "«Зберегти» видає книгу текстом: щоб тримати в себе або передати тим, хто не в гільдії. «Завантажити» об'єднує й нічого не перезаписує."
L.SET_SEC_SOUND = "ЗВУК"  -- [max 24]
L.SET_SOUND = "Звук"  -- [max 22]
L.SET_VOLUME = "Гучність"  -- [max 22]
L.SET_CHANNEL = "Канал"  -- [max 12]
L.SET_SEC_THRESHOLD = "ПОРІГ"  -- [max 24]
L.SET_COOLDOWN = "Пауза для кожного вбивці"  -- [max 34]
L.SET_MINKILLS = "Смертей від вбивці до тривоги"  -- [max 34]
L.SET_ALERT_SIZE = "Розмір тривоги"  -- [max 34]
L.SET_TEST_ALERT = "Пробна тривога"  -- [max 17]
L.SET_G_MINKILLS = "Смертей до тривоги гільдії"  -- [max 34]
L.SET_F_MINKILLS = "Смертей до тривоги"  -- [max 34]
L.SET_SEC_STATUS = "СТАН"  -- [max 24]
L.SET_SEC_SHARING = "ОБМІН"
L.SET_SEC_WARN = "ТРИВОГА"
L.SET_MORE = "Ще"
L.SET_GUILD_CLEAR = "Очистити книгу гільдії"  -- [max 26]
L.SET_HINT_GUILD = "Отримує лише твоя гільдія. Те, що приходить звідти, зберігається окремо від твоєї книги, доки ти не перенесеш це до себе."
L.SET_HINT_FRIENDS = "Отримують лише гільдія та друзі з DeathNote."
L.BTN_BACK = "Назад"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Синхронізація"  -- [max 14]
L.SYNC_AGAIN_IN = "через {seconds} с"  -- [max 16]
L.TIP_FRIENDS = "Друзі"
L.TIP_GUILD_NAME = "Гільдія {guild}"
L.TIP_MATES_WITH = "Гільдійці з DeathNote:"
L.TIP_NO_MATE = "Гільдійців з DeathNote поки що не чути."
L.TIP_FRIENDS_WITH = "Друзі з DeathNote:"
L.TIP_SHARED = "Передається: твої підтверджені смерті, ручні записи й твої заявки на полювання."
L.TIP_NOT_SHARED = "Не передається: нотатки, підозри, помилувані, завантажені записи."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Завантажити"  -- [max 17]
L.IO_DONE = "Завантажено. Нових: {new}, об'єднано: {merged}."
L.IO_FAILED = "Не вийшло."
L.IO_SMALL = "Коротко"  -- [max 17]
L.IO_ALL = "Показати все"  -- [max 17]
L.IO_MSG_FULL = "Уся книга зі злочинами ({size})."
L.IO_MSG_SHORT = "Лише імена й лічильники ({size}). Зі злочинами: {full}."
L.IO_MSG_BIG = "Велика книга ({size}): виділення й копіювання займуть трохи часу."
L.IO_HELP_EXPORT = "Текст виділено: Ctrl+C копіює його. Збережи його або передай друзям."
L.IO_HELP_IMPORT = "Встав збережений текст через Ctrl+V, потім «Завантажити». Нічого не буде перезаписано."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Причину побачать усі у твоїй гільдії та твої друзі з DeathNote."
L.REL_HINT_GUILD = "Причину побачать усі у твоїй гільдії з DeathNote."
L.REL_HINT_FRIENDS = "Причину побачать твої друзі з DeathNote."
L.REL_HEAD = "Оголосити полювання"  -- [max 24]
L.REL_FOR = "ДЛЯ"  -- [max 6]
L.REL_REASON = "ПРИЧИНА"  -- [max 8]
L.REL_HINT2 = "Твоя нотатка лишається в тебе. Скасувати свою заявку можеш лише ти."
L.REL_GO = "Оголосити"  -- [max 17]
L.REL_NONE = "Гільдії немає, а обмін із друзями вимкнено."
L.REL_CAP = "Щонайбільше {own} своїх заявок і {max} цілей у списку."
L.REL_FAILED = "Зараз оголосити полювання не можна."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} с"  -- [max 7]
L.SET_HINT_SILENT = "Без звуку: тривога лише показується."
L.SET_HINT_BUILTIN = "Гучність цього звуку залежить від каналу в налаштуваннях гри."
L.SET_HINT_LEVELS = "П'ять рівнів, від тихо до гучно. Поверх діє повзунок каналу в налаштуваннях гри."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Гільдія й друзі"  -- [max 18]
L.TIP_HELP_BUTTON = "Як працює книга"
L.VIEW_HUNT = "На відстріл"  -- [max 13]
L.VIEW_BY_KILLER = "За вбивцями"  -- [max 13]
L.VIEW_BY_MATE = "За жертвами"  -- [max 13]
L.SRC_ALL = "Усі"  -- [max 12]
L.SRC_GUILD = "Гільдія"  -- [max 12]
L.SRC_FRIENDS = "Друзі"  -- [max 12]
L.SORT_HIDE_PARDONED = "Приховати помилуваних"  -- [max 24]
L.SORT_SHOW_PARDONED = "Показати помилуваних"  -- [max 24]
L.SEARCH_ADD = "Знайти або вписати …"  -- [max 26]
L.SEARCH_SHORT = "Пошук …"  -- [max 10]
L.SEARCH_KILLER = "Знайти вбивцю …"  -- [max 15]
L.SEARCH_JOURNAL = "Вбивця або місце …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Згорнути все"
L.TIP_EXPAND_ALL = "Розгорнути все"
L.STATUS_NO_PLATES = "Таблички імен ворогів вимкнено: тривога бачить лише ціль і курсор."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "У розшуку: {count}"
L.MM_UNSOLVED = "Нерозкрито: {count}"
L.MM_ALERT_OFF = "Тривогу вимкнено (середній клік)"
L.MM_CLICK = "Клік: книга · Правий клік: Розпорядок"
L.MM_MIDDLE = "Середній клік: тривога увімк./вимк."
L.MM_DRAG = "Перетягування: рухати по краю мінікарти"
L.MM_CHAT_ALERT_ON = "Тривогу увімкнено."
L.MM_CHAT_ALERT_OFF = "Тривогу вимкнено."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "ВОРОГ ГІЛЬДІЇ №1"  -- [max 25]
L.STAMP_HUNT = "ПОЛЮВАННЯ ВІДКРИТО"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} видає себе за твого друга {friend}: відхилено."
L.FRIENDS_SHORT_IMPOSTOR = "Чужака відхилено"  -- [max 22]
L.ALERT_LEVEL = "Рівень {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "був рівень {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Рівень ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · у списку на відстріл ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|нова ціль|нові цілі|нових цілей}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "нове у списку на відстріл"
L.OPT_F_ANNOUNCEHUNT = "Новини списку на відстріл: нові, вполювані"  -- [max 44]
L.SET_HUNT_EXPIRE = "Заявки спливають через"  -- [max 30]
L.SET_EXPIRE_NEVER = "Ніколи"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|день|дні|днів}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Очистити книгу друзів"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Очистити книгу друзів на цьому комп'ютері?\nЇї список на відстріл теж зникне, твої заявки лишаться."
L.CONFIRM_CALLOFF_ALL = "Скасувати всі свої заявки на полювання?\nГільдія та друзі дізнаються про це поступово."
L.CONFIRM_CALLOFF_ALL_OK = "Скасувати всі"  -- [max 14]
L.ACT_CALLOFF_ALL = "Скасувати всі мої заявки"  -- [max 24]
L.ACT_HUNT_HIDE = "Приховати для мене"  -- [max 19]
L.ACT_HUNT_SHOW = "Показати знову"  -- [max 19]
L.HUNT_ROW_HIDDEN = "приховано для тебе"
L.HUNT_ROW_CALLS = "{count} {count|заявка|заявки|заявок}: {names}"
L.POSTER_ON_HUNTLIST = "У списку на відстріл ({names})"
L.REL_SELF = "На себе полювання не оголосиш."
L.REL_MATE = "Це хтось зі своїх (гільдія або друзі з DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Хто твій друг {friend}: {a} чи {b}? Обери."
L.FRIENDS_SHORT_CONFLICT = "Друг під питанням"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Двоє гравців називають себе твоїм другом {friend}: {a} і {b}. Поки ти не обереш, книга нічого не приймає від жодного з них. Гільдія й друзі, вигляд За жертвами: правий клік по імені."
L.MEMBER_CONFLICT = "Правий клік: це твій друг?"  -- [max 40]
L.ACT_TIE_MINE = "Мій друг: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Відв'язати"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Відв'язати {name} від твого списку друзів?\nУсе, що це ім'я принесло в книгу друзів, буде видалено; наступне повідомлення під цим ім'ям прив'яже наново."
L.CHAT_FRIENDS_TIES = "Прив'язані повні імена (* = перший контакт, ще не підтверджено): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Ім'я [Прізвище]> <золото>  призначити свою нагороду (без суми: відкликати)"
L.CHAT_WHO_BOUNTY = "За кого? /dn bounty <Ім'я> <золото>"
L.CHAT_BOUNTY_SET = "{name}: твою нагороду {gold} з призначено. Гільдія та друзі з DeathNote її бачать."
L.CHAT_BOUNTY_OFF = "{name}: твою нагороду відкликано."
L.CHAT_BOUNTY_NONE = "{name}: твоєї нагороди немає."
L.CHAT_BOUNTY_BAD = "Нагорода: ціле число золотих, від 1 до 99999 (0 відкликає)."
L.CHAT_BOUNTY_CAP = "Нагороду не призначити: своїх щонайбільше {count}."
L.CHAT_BOUNTY_OURS = "Не можна призначити нагороду за себе й своїх (гільдія або друзі з DeathNote)."
L.ACT_BOUNTY = "Призначити нагороду"  -- [max 24]
L.ACT_UNDO = "Скасувати"  -- [max 19]
L.ACT_REVENGE_TAKE = "Зняти одну помсту"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, твоя нагорода"
L.POSTER_BOUNTY_BY = "{gold}, призначає: {name}"
L.POSTER_BOUNTY_MANY = "Нагорода {gold}: {names}"
L.POSTER_AVENGED = "Помстилися: {names}"
L.ROW_AVENGED = "помщено {times}"
L.BOUNTY_TIP_HEAD = "Твоя нагорода в золоті"
L.BOUNTY_TIP_RULES = "Ціле число від 1 до 99999. Порожньо або 0: знову значення книги. Enter призначає, Esc скасовує."
L.BOUNTY_TIP_PROMISE = "Гільдія та друзі з DeathNote її бачать. Це лише обіцянка: розрахунок між собою."
L.BOUNTY_TIP_CLICK = "Клік: призначити свою нагороду"
L.CHAT_AVENGED = "Помста за тебе: {killer}, від {name}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: твою нагороду {gold} з призначено."
L.CHAT_BOUNTY_UNKNOWN = "{name}: немає у твоїх книгах. Нагорода лише на ім'я з книги, як його показує гра: ім'я та прізвище."
L.CHAT_BOUNTY_LIST = "Твої нагороди ({count} з {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Твоїх нагород немає."
-- <<< BOOK
-- >>> REPUTE (1.3.0) -------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Ранг {tier} · Шлях: {path}"  -- [max 32]
L.PATH_R = "Лиха слава"  -- [max 16]
L.PATH_E = "Честь"  -- [max 16]
L.PATH_J = "Полювання"  -- [max 16]
L.PATH_S = "Захист"  -- [max 16]
L.PATH_NONE = "чистий аркуш"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) --------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "ТАЇТЬ ОБРАЗУ?"  -- [max 30]
L.ALERT_LINE_VICTIM = "рахунок {score} · твоя жертва, востаннє {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · рахунок {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · рахунок {score}, квити"
L.ALERT_LINE_STANDING_AHEAD = "{text} · рахунок {score}, переплачено"
-- <<< ALARM
-- >>> START (1.3.0) --------------------------------------------------------------------------------------------
L.SET_THEME = "Обкладинка"  -- [max 16]
L.START_HINT = "І те, і те можна змінити пізніше в Розпорядку."  -- [max 60]
L.START_GO = "Уперед"  -- [max 16]
L.START_CLOSE_TIP = "Залишити як є"  -- [max 32]
L.CHAT_THEME_NEWS = "Нове: книга тепер має інші обкладинки. Розпорядок, аркуш «Книга», або /dn theme."
L.HELP_START = "/dn start  вікно першого запуску ще раз (мова й обкладинка)"
-- <<< START
-- >>> RECORD (1.3.0) -------------------------------------------------------------------------------------------
L.TAB_RECORD = "Картотека"  -- [max 16]
L.STAMP_QUITT = "КВИТИ"  -- [max 16]
L.STAMP_OVERPAID = "ПЕРЕПЛАЧЕНО"  -- [max 16]
L.STAMP_NR1_DOWN = "ВОРОГ № 1 ПОВАЛЕНИЙ"  -- [max 24]
L.STATE_OPEN = "відкритий"  -- [max 16]
L.STATE_EVEN = "квити"  -- [max 16]
L.STATE_AHEAD = "переплачено"  -- [max 16]
L.STATE_VICTIM = "немає в книзі"  -- [max 24]
L.STAND_LINE = "Рахунок {score}"
L.STAND_TIP = "ти {mine}, він {his}"
L.TIP_IN_RECORD = "У КАРТОТЕЦІ:"
L.TIP_RECORD_LINE = "{times} від твоєї руки, востаннє {time}"
L.RECORD_HEAD = "Твоє досьє"  -- [max 20]
L.RECORD_LOG_HEAD = "Останні вбивства"  -- [max 20]
L.RECORD_NEXT = "Наступний ранг: {rank}, ще {points}"
L.RECORD_TOP = "Найвищий ранг досягнуто."
L.RECORD_BAR_TIP = "Очки: {total} з {goal}"
L.RECORD_NEEDLE_LOW = "безжальний"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "шляхетний"  -- [max 12]
L.RECORD_NEEDLE_TIP = "Стрілка: честь і захист проти лихої слави. Полювання її не рухає."
L.RECORD_KILLS = "Вбивств: {kills} · Жертв: {victims}"
L.RECORD_BEST = "Рекорди: {list}"
L.RECORD_BEST_GAP = "+{count} {count|рівень|рівні|рівнів}"
L.RECORD_BEST_STREAK = "серія {count}"
L.RECORD_BEST_QUICK = "найшвидша помста {time}"
L.DUR_SECONDS = "{count} с"
L.DUR_MINUTES = "{count} хв"
L.DUR_HOURS = "{count} год"
L.RECORD_AWARDS = "ОРДЕНИ"  -- [max 14]
L.RECORD_AWARD_AT = "вручено {time}"
L.RECORD_AWARD_OPEN = "ще не вручено"
L.RECORD_MORE = "Показати більше"  -- [max 19]
L.RECORD_BACK = "До досьє"  -- [max 19]
L.RECORD_CLEAR = "Очистити картотеку"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Очистити картотеку?\nУсі жертви та список останніх вбивств зникнуть. Ранг, очки й ордени залишаться."
L.CONFIRM_RECORD_CLEAR_OK = "Очистити"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Викреслити {name} з картотеки?\nЗароблені очки залишаться."
L.ACT_VICTIM_STRIKE = "Викреслити з картотеки"  -- [max 26]
L.VICTIM_KILLED = "{times} від твоєї руки"
L.VICTIM_POINTS = "Очки для тебе: {points}"
L.VICTIM_SCENE = "Місце: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "ТВОЇ ВБИВСТВА"  -- [max 14]
L.KILL_TAG_REVENGE = "помста"  -- [max 14]
L.KILL_TAG_KICK = "по лежачому"  -- [max 14]
L.KILL_TAG_GROUP = "група"  -- [max 14]
L.BAND_GRAU = "сірий"  -- [max 12]
L.BAND_GRUEN = "зелений"  -- [max 12]
L.BAND_GELB = "жовтий"  -- [max 12]
L.BAND_ORANGE = "оранжевий"  -- [max 12]
L.BAND_ROT = "червоний"  -- [max 12]
L.BAND_SCHAEDEL = "череп"  -- [max 12]
L.BAND_UNBEKANNT = "невідомо"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "без очок"
L.RECORD_BANDS = "За кольором рівня"
L.TIP_PATH_R = "Лиха слава: вбивства сірих і зелених."
L.TIP_PATH_E = "Честь: вбивства гравців твого рівня, помста."
L.TIP_PATH_J = "Полювання: вбивства вищих за рівнем, цілей зі списку на відстріл і за нагороду."
L.TIP_PATH_S = "Захист: вбивства гравців, які вбивали гільдійців або друзів."
L.SORT_STATE = "Рахунок"  -- [max 14]
L.SORT_COUNT = "Вбивства"  -- [max 14]
L.SORT_POINTS = "Очки"  -- [max 14]
L.CHAT_OWN_KILL = "Картотека: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Новий шлях: {path}. Ранг: {rank}."
L.BANNER_RANK = "НОВИЙ РАНГ"  -- [max 24]
L.BANNER_AWARD = "ОРДЕН"  -- [max 24]
L.OPT_LEDGER = "Вести картотеку"  -- [max 44]
L.OPT_LEDGER_CHAT = "Повідомляти про свої вбивства в чат"  -- [max 44]
L.OPT_VICTIMS = "Попереджати, коли поруч твоя жертва"  -- [max 44]
L.SET_SETTLED = "Тривога, коли рахунок зведено"  -- [max 34]
L.SET_SETTLED_ALWAYS = "як завжди"  -- [max 10]
L.SET_SETTLED_QUIET = "тихо"  -- [max 10]
L.SET_SETTLED_OFF = "ніколи"  -- [max 10]
L.MANUAL_RECORD_HEAD = "КАРТОТЕКА"  -- [max 14]
L.MANUAL_RECORD = "Твої власні смертельні удари по гравцях. Плакат і список показують рахунок «ти : він»: відкритий, квити або переплачено. Перше місце завжди за відкритим рахунком. Вбивства приносять очки для твого рангу."
L.POSTER_LAST_SEEN_IN = "Востаннє помічено: {zone}, {time}"
L.SHEET_RECORD = "Картотека"  -- [max 14]
-- <<< RECORD
end)
