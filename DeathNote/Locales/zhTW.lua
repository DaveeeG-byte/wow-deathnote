-- DeathNote: 中文(繁體) (zhTW).
-- Plural: 1 form {count|other} (no plural). Rule in Locale.lua (PLURAL_OF.zhTW), not here.
-- Fonts: hant (bLEI00D, bKAI00M, bHEI00M) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Terms: book 記仇本, guild book 公會記仇本, friends' book 好友記仇本, killer 兇手, guildmate 公會成員,
-- Hit List 追殺名單, call 追殺令. Game terms as in the official zhTW client (名條, 悄悄話, 地城).
--
-- TOC-Notes: 野外PvP記仇本：記住誰殺了你，並在他們靠近時提醒你。

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("zhTW")) then return end

Locale.Register("zhTW", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "通緝"  -- [max 16]
L.TAB_UNSOLVED = "待查"  -- [max 16]
L.TAB_DEATHLOG = "死亡紀錄"  -- [max 16]
L.TAB_GUILD = "公會"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "家規"  -- [max 24]
L.HEAD_HELP = "使用說明"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "記仇本"  -- [max 14]
L.SHEET_ALERT = "警報"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "頭號公敵"  -- [max 24]
L.STAMP_REVENGE = "已復仇"  -- [max 16]
L.STAMP_PARDONED = "已赦免"  -- [max 16]
L.STAMP_SUSPECT = "嫌疑"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "頭號公敵現身"  -- [max 30]
L.ALERT_SIGHTED = "公敵現身"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "嫌疑人現身"  -- [max 30]
L.ALERT_TITLE_GUILD = "公會仇敵現身"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "殺害好友的兇手現身"  -- [max 30]
L.ALERT_TITLE_HUNT = "追殺目標"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "有嫌疑"
L.ALERT_LINE_KILLED = "殺了你{times}"
L.ALERT_LINE_KILLED_ASSISTED = "殺了你{times}，助攻{assists}"
L.ALERT_LINE_ASSISTED = "協助殺你{times}"
L.ALERT_LINE_MANUAL = "被手動記入記仇本"
L.ALERT_LINE_LAST = "{text}，上次{time}"
L.ALERT_LINE_IN = "{text}，在{zone}"
L.ALERT_LINE_REVENGE = "{text}。復仇：{times}"
L.ALERT_HINT_CLOSE = "右鍵：關閉"  -- [max 44]
L.ALERT_HINT_COMBAT = "脫離戰鬥後才能選取"  -- [max 44]
L.ALERT_HINT_TARGET = "點擊：選取  ·  右鍵：關閉"  -- [max 44]
L.ALERT_MORE = "還有{count}條"  -- [max 14]
L.SAMPLE_ZONE = "荊棘谷"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "在公會記仇本上"
L.GUILD_LINE_IN_FRIENDS = "在好友記仇本上"
L.GUILD_LINE_LISTED_BY = "在{names}的記仇本上"
L.GUILD_LINE_KILLED_GUILD = "殺過公會成員{kills}次"
L.GUILD_LINE_KILLED_FRIENDS = "殺過好友{kills}次"
L.GUILD_LINE_KILLED_BOTH = "殺過公會成員和好友{kills}次"
L.GUILD_LINE_LAST = "{text}，最近受害者：{name}"
L.HUNT_LINE_BY = "由{names}列入追殺名單"
L.HUNT_LINE_RELEASED = "在追殺名單上"
L.HUNT_LINE_REASON = "{text}：{reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}次"
L.TALLY_SUSPECT = "有嫌疑"
L.TALLY_MANUAL = "手動新增"
L.TALLY_NONE = "尚無罪行"
L.TALLY_KILLED = "殺了你{times}"
L.TALLY_ASSISTED = "助攻{times}"
L.PLACE_UNKNOWN = "未知地點"
L.GKILLS_CAP = "至少{count}"
L.NAMELIST_MORE = "{names}及另外{count}人"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%m/%d %H:%M"
L.TIME_FMT_WHEN_YEAR = "%Y/%m/%d %H:%M"
L.TIME_FMT_DAY = "%m/%d"
L.TIME_FMT_DAY_YEAR = "%y/%m/%d"
L.TIME_NEVER = "從未"
L.TIME_JUST = "剛剛"
L.TIME_MINUTES = "{count}分鐘前"  -- [max 14]
L.TIME_HOURS = "{count}小時前"  -- [max 14]
L.TIME_DAYS = "{count}天前"  -- [max 16]
L.MONEY_GOLD = "{count}金"
L.MONEY_SILVER = "{count}銀"
L.MONEY_COPPER = "{count}銅"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "已發現{count}名裝了DeathNote的公會成員。"
L.HEALTH_NOGUILD = "你不在任何公會裡，不會分享任何內容。"
L.HEALTH_OFF = "分享已關閉。"
L.HEALTH_SHORT_NOGUILD = "無公會"  -- [max 18]
L.HEALTH_SHORT_OFF = "分享已關閉"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "被封鎖"  -- [max 18]
L.HEALTH_SHORT_FAILING = "被拒絕"  -- [max 18]
L.HEALTH_SHORT_HOLD = "等待中"  -- [max 18]
L.HEALTH_SHORT_ASKED = "已請求"  -- [max 18]
L.HEALTH_SHORT_FAIL = "無法使用"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "無聲"  -- [max 16]
L.SOUND_RAIDWARNING = "團隊警告"  -- [max 16]
L.SOUND_BELL = "鐘聲"  -- [max 16]
L.SOUND_GONG = "鑼聲"  -- [max 16]
L.SOUND_HEARTBEAT = "心跳"  -- [max 16]
L.SOUND_FEATHER = "羽毛筆"  -- [max 16]
L.SOUND_SIREN = "警笛"  -- [max 16]
L.CHANNEL_MASTER = "主音量"  -- [max 16]
L.CHANNEL_SFX = "音效"  -- [max 16]
L.CHANNEL_DIALOG = "對話"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name}已記入記仇本。"
L.CHAT_REMOVED = "{name}已從記仇本上劃掉。"
L.CHAT_SYNC_WAIT = "剛同步過。請在{seconds}秒後再試。"

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "還沒有名字。"
L.EMPTY_WANTED_SUB = "偶爾也出門走走吧。"

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  打開/闔上記仇本"
L.HELP_ADD = "/dn add <名字 [姓氏]>  手動把兇手記入記仇本"
L.HELP_DEL = "/dn del <名字 [姓氏]>  把兇手從記仇本上劃掉"
L.HELP_QUIET = "/dn quiet  關閉/開啟警報"
L.HELP_TEST = "/dn test  顯示測試警報"
L.HELP_GUILD = "/dn guild  公會記仇本：狀態，以及哪些公會成員裝了DeathNote"
L.HELP_FRIENDS = "/dn friends  好友記仇本：狀態，以及哪些好友裝了DeathNote"
L.HELP_SYNC = "/dn sync  立即同步公會記仇本和好友記仇本"
L.HELP_HUNT = "/dn hunt <名字 [姓氏]>  列入追殺名單（不帶名字：顯示追殺名單）"
L.HELP_CALLOFF = "/dn calloff <名字 [姓氏]>  撤銷你自己的追殺令"
L.HELP_LANG = "/dn lang <代碼>  記仇本的語言（enUS、deDE、frFR ...），/reload後生效"
L.HELP_THEME = "/dn theme <名稱>  記仇本的封面，/reload後生效"
L.HELP_PROBE = "/dn probe  排除問題：遊戲告訴了記仇本什麼"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  排除問題，同時檢查戰鬥紀錄"
L.HELP_DEBUG = "/dn debug  排除問題：詳細記下每一次死亡（開/關）"
L.HELP_HELP = "/dn help  本說明"
L.HELP_SILENT_ZONES = "在地城、戰場和競技場裡，記仇本會自動保持安靜。"

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "開"
L.WORD_OFF = "關"
L.CHAT_WHO_ADD = "誰？/dn add <名字>"
L.CHAT_WHO_DEL = "誰？/dn del <名字>"
L.CHAT_WHO_CALLOFF = "誰？/dn calloff <名字>"
L.CHAT_BAD_NAME = "名字無效。"
L.CHAT_NOT_IN_BOOK = "不在記仇本上：{name}"
L.CHAT_ALARM_ON = "警報已開啟。"
L.CHAT_ALARM_OFF = "警報已關閉。"
L.CHAT_DEBUG = "排除問題紀錄：{state}。"
L.CHAT_UNKNOWN_CMD = "未知指令。說明：/dn help"
L.CHAT_GUILD_NOT_LOADED = "公會記仇本未載入。"
L.CHAT_NO_GUILD = "你不在任何公會裡（或是遊戲還不知道）。"
L.CHAT_GUILD_STATE = "公會<{guild}>：分享{share}，接收{receive}。"
L.CHAT_GUILD_BOOK = "公會記仇本：{enemies}名兇手（其中{listed}名僅為手動新增），{deeds}條罪行，{foreign}名涉及其他公會成員。分享手動條目：{manual}。"
L.CHAT_STATE_OK = "狀態：{text}"
L.CHAT_STATE_WARN = "注意：{text}"
L.CHAT_NO_MATES = "尚未發現裝了DeathNote的公會成員。"
L.CHAT_HAVE_DN = "裝了DeathNote：{names}"
L.CHAT_HAVE_DN_MORE = "裝了DeathNote：{names}及另外{count}人"
L.CHAT_SYNC_ASKED = "已請求同步。幾秒內會收到回覆。"
L.CHAT_SYNC_FAIL = "無法同步：{reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "沒有公會，或分享已關閉。"
L.CHAT_FRIENDS_NOT_LOADED = "好友記仇本未載入。"
L.CHAT_FRIENDS_STATE = "好友：分享{share}，{online}/{total}在線上。"
L.CHAT_FRIENDS_BOOK = "好友記仇本：{enemies}名兇手（其中{listed}名僅為手動新增），{deeds}條罪行。"
L.CHAT_NO_FRIENDS = "尚未發現裝了DeathNote的好友。"
L.CHAT_HUNT_NOT_LOADED = "追殺名單未載入。"
L.CHAT_HUNT_UNKNOWN = "未知：{name}。請連同姓氏輸入，與遊戲中顯示的名字一致。"
L.CHAT_HUNT_CAP = "無法列入追殺名單：每份名單最多{own}道你自己的追殺令和{targets}個目標。"
L.CHAT_HUNT_NOWHERE = "現在無法列入追殺名單：沒有公會，與好友分享也已關閉。"
L.CHAT_HUNT_BOTH = "{name}已列入追殺名單，公會和好友都看得到。"
L.CHAT_HUNT_GUILD = "{name}已列入追殺名單，公會看得到。"
L.CHAT_HUNT_FRIENDS = "{name}已列入追殺名單，你的好友看得到。"
L.CHAT_CALLED_OFF = "已撤銷對{name}的追殺。"
L.CHAT_NO_OWN_CALL = "你沒有針對{name}的追殺令。"
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "目前語言：{lang}。變更：/dn lang <代碼>"
L.CHAT_LANG_LIST = "代碼：{codes}"
L.CHAT_LANG_BAD = "未知語言：{code}"
L.CHAT_LANG_SET = "語言：{lang}。"
L.CHAT_LANG_RELOAD = "語言：{lang}。/reload後生效。"
L.CHAT_THEME_CURRENT = "目前封面：{theme}。變更：/dn theme <名稱>"
L.CHAT_THEME_LIST = "封面列表：{themes}"
L.CHAT_THEME_BAD = "未知封面：{name}"
L.CHAT_THEME_SET = "封面：{theme}。"
L.CHAT_THEME_RELOAD = "封面：{theme}。/reload後生效。"
L.THEME_NOTEBOOK = "黑色記仇本"
L.THEME_HARBOR = "私掠船日誌"
L.THEME_TRADE = "專業工坊"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "記仇本已準備好。在野外殺死你的人，之後都會記在上面。用/dn或小地圖按鈕打開。"
L.WELCOME_PLATES = "敵方名條已關閉。沒有名條，警報只看得到你的目標。"
L.WELCOME_SHARE = "裝了DeathNote的公會成員和好友也能一起看。備註和嫌疑只留給你自己。"

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "記仇本："
L.TIP_HUNT = "追殺名單："
L.TIP_GUILDBOOK = "公會記仇本："
L.TIP_PARDONED = "已赦免"
L.TIP_RANK = "第{rank}名"
L.TIP_REVENGE = "復仇{times}"
L.TIP_LISTED_BY = "在{names}的記仇本上"
L.TIP_NOTE = "備註：{note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "點擊：打開 · 右鍵：關閉"
L.BANNER_NEW = "記上一筆"  -- [max 24]
L.BANNER_NEW_LINE = "已記入記仇本"
L.BANNER_AGAIN = "又來了"  -- [max 24]
L.BANNER_AGAIN_LINE = "又殺了你，已經{count}次了"
L.BANNER_SUSPECT = "嫌疑"  -- [max 24]
L.BANNER_SUSPECT_LINE = "有嫌疑，請到記仇本裡查清楚"
L.BANNER_UNCLEAR = "兇手不明"  -- [max 24]
L.BANNER_CANDIDATES = "{count}名候選人"
L.BANNER_UNCLEAR_LINE = "點擊：到待查中確定兇手"
L.BANNER_REVENGE = "血債血償"  -- [max 24]
L.BANNER_REVENGE_LINE = "已復仇（{count}次）"
L.BANNER_GUILD = "公會"  -- [max 24]
L.BANNER_FRIENDS = "好友"  -- [max 24]
L.BANNER_KILLED_BY = "被{name}殺死"
L.BANNER_HUNT = "追殺名單"  -- [max 24]
L.BANNER_BAGGED = "已被{name}擊殺，{time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "分享已關閉（家規，公會頁）。"
L.SYNC_FRIENDS_OFF = "與好友分享已關閉。"
L.SYNC_NOBODY = "沒有公會，也沒有可以分享的好友。"
L.SYNC_SHORT_NOBODY = "未分享"  -- [max 18]
L.SYNC_PREFIX = "遊戲不允許接收。重新登入就會好。"
L.SYNC_SHORT_PREFIX = "無法接收"  -- [max 18]
L.SYNC_BLOCKED = "伺服器阻擋傳送。請用「備份記仇本」交給別人。"
L.SYNC_SHORT_BLOCKED = "伺服器阻擋傳送"  -- [max 22]
L.SYNC_FAILING = "暫時無法傳送，正在重試。"
L.SYNC_SHORT_FAILING = "傳送受阻"  -- [max 18]
L.SYNC_HOLD = "傳送暫緩，{wait}。"
L.SYNC_HOLD_INSTANCE = "直到你離開副本"
L.SYNC_HOLD_COMBAT = "直到你脫離戰鬥"
L.SYNC_HOLD_LOCKDOWN = "直到聊天恢復可用"
L.SYNC_HOLD_AGAIN = "直到恢復正常"
L.SYNC_HOLD_SHORT_INSTANCE = "等待：副本"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "等待：戰鬥"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "等待：聊天"  -- [max 18]
L.SYNC_QUIET = "已傳送，但尚未發現裝了DeathNote的公會成員。"
L.SYNC_READY = "就緒。尚未發現裝了DeathNote的公會成員。"
L.SYNC_RUNNING = "運作中：{count}名公會成員裝了DeathNote。"
L.SYNC_RUNNING_ALL = "運作中：公會和好友中有{count}人裝了DeathNote。"
L.FRIENDS_OFF = "與好友分享已關閉（家規，公會頁）。"
L.FRIENDS_BLOCKED = "伺服器阻擋悄悄話。好友什麼也收不到。"
L.FRIENDS_SHORT_BLOCKED = "伺服器阻擋悄悄話"  -- [max 22]
L.FRIENDS_FAILING = "暫時無法傳送悄悄話，正在重試。"
L.FRIENDS_SHORT_FAILING = "悄悄話受阻"  -- [max 18]
L.FRIENDS_NONE_LISTED = "好友名單上沒有好友。"
L.FRIENDS_NONE_ONLINE = "現在沒有好友在線上。"
L.FRIENDS_SHORT_NONE_ONLINE = "沒有好友在線上"  -- [max 18]
L.FRIENDS_QUIET = "已詢問，但尚未發現裝了DeathNote的好友。"
L.FRIENDS_READY = "就緒。尚未發現裝了DeathNote的好友。"
L.FRIENDS_HOLD = "傳送給好友暫緩，直到恢復正常。"
L.FRIENDS_RUNNING = "運作中：{count}名好友裝了DeathNote。"
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "從公會記仇本轉入（殺過公會成員{kills}次）。"

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "資料庫未載入。"
L.IMPORT_NO_TEXT = "沒有文字。"
L.IMPORT_NO_HEADER = "缺少第一行（以{header}開頭）。請複製完整的文字。"
L.IMPORT_NOT_EXPORT = "不是DeathNote匯出的文字（缺少標題行或版本不符）。"
L.IMPORT_TOO_LONG = "行數太多（最多{count}行）。"
L.IMPORT_BAD_KEY = "第{line}行：鍵無效。"
L.IMPORT_BAD_TIME = "第{line}行：時間無效。"
L.IMPORT_BROKEN = "第{line}行不完整或已損壞（文字被截斷了？）。沒有匯入任何內容。"

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "是"
L.WORD_NO = "否"
L.PROBE_HEAD = "檢測：{apis}/{apisAll}個介面可用，{events}/{eventsAll}個事件可註冊。"
L.PROBE_MISSING = "缺少：{list}"
L.PROBE_NOT_REGISTERABLE = "無法註冊：{list}"
L.PROBE_SOURCES = "目前Recap：{recap} · Meter：{meter} · 戰鬥紀錄：{clog}"
L.PROBE_READABLE = "可讀取"
L.PROBE_DEAD = "失效"
L.PROBE_PLATES = "敵方名條：{plates} · 野外：{open}"
L.PROBE_PLATES_OFF = "關（只有目標和滑鼠指向能發現玩家）"
L.PROBE_TARGET = "目標：名字={name} GUID={guid} 職業={class} 敵對={enemy} 以我為目標={me}"
L.PROBE_GUILD = "公會：前綴{prefix} · 傳送{send} · 上次傳回值{result} · 已傳送{sent}，已接收{received}，已丟棄{dropped}"
L.PROBE_REGISTERED = "已註冊"
L.PROBE_NOT_REGISTERED = "未註冊（{result}）"
L.PROBE_POSSIBLE = "可以"
L.PROBE_ABSENT = "缺少"
L.PROBE_WAITS = " · 等待：{why}"
L.PROBE_LISTED = "手動條目（M）：已傳送{sent}，已接收{received}，已丟棄{dropped} · 劃掉（X）：已傳送{usent}，已接收{ureceived}，已丟棄{udropped}"
L.PROBE_GUILDBOOK = "公會記仇本：{text}"
L.PROBE_SAVED = "已儲存到DeathNoteDB.probe（/reload後寫入檔案）。"

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "排名"  -- [max 14]
L.SORT_RECENT = "最新"  -- [max 14]
L.SORT_NAME = "名字"  -- [max 14]
L.SORT_SEEN = "目擊"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "在野外殺死你的人會出現在這裡。自動記下，不用你動手。"
L.EMPTY_OPEN_HEAD = "沒有待查的案子。"
L.EMPTY_JOURNAL_HEAD = "還沒死過。"
L.EMPTY_JOURNAL_SUB = "佩服。不然就是在說謊。"
L.EMPTY_NOGUILD_HEAD = "沒有公會。"
L.EMPTY_NOGUILD_SUB = "一個人也照樣能死。"
L.EMPTY_GUILDOFF_HEAD = "公會記仇本已闔上。"
L.EMPTY_GUILDOFF_SUB = "分享已關閉。家規裡寫著在哪裡開。"
L.EMPTY_GUILDNIL_HEAD = "公會那邊還沒有消息。"
L.EMPTY_GUILDNIL_SUB = "只要有公會成員裝了DeathNote，你的記仇本就會送出去。"
L.EMPTY_GUILDQUIET_HEAD = "公會記仇本上還什麼都沒有。"
L.EMPTY_GUILDQUIET_SUB = "你的公會成員到現在都很太平。"
L.EMPTY_FRIENDSOFF_HEAD = "好友記仇本已闔上。"
L.EMPTY_FRIENDSOFF_SUB = "與好友分享已關閉。家規裡寫著在哪裡開。"
L.EMPTY_FRIENDSNIL_HEAD = "尚未發現裝了DeathNote的好友。"
L.EMPTY_FRIENDSNIL_SUB = "只要有好友裝了DeathNote，你的記仇本就會送出去。"
L.EMPTY_FRIENDSQUIET_HEAD = "好友那邊還什麼都沒有。"
L.EMPTY_FRIENDSQUIET_SUB = "你的好友到現在都很太平。"
L.EMPTY_NOBODY_HEAD = "沒有公會，也沒有好友。"
L.EMPTY_NOBODY_SUB = "一個人也照樣能死。"
L.EMPTY_NOBODY_HINT = "等公會成員或好友名單上的好友裝了DeathNote，這裡就會顯示他們的遭遇。"
L.EMPTY_SHAREDNIL_HEAD = "尚未發現任何裝了DeathNote的人。"
L.EMPTY_SHAREDNIL_SUB = "只要有公會成員或好友裝了DeathNote，你的記仇本就會送出去。"
L.EMPTY_SHAREDQUIET_HEAD = "這裡還什麼都沒有。"
L.EMPTY_SHAREDQUIET_SUB = "公會和好友到現在都很太平。"
L.EMPTY_HUNT_HEAD = "追殺名單是空的。"
L.EMPTY_HUNT_SUB = "在通緝令上點：發布追殺。"
L.EMPTY_HUNT_HINT = "或在聊天中輸入：/dn hunt 名字 姓氏。你公會裡的所有人和你的好友都看得到。"
L.EMPTY_SEARCH_HEAD = "沒有結果。"
L.EMPTY_SEARCH_SUB = "按Enter把這個名字記入記仇本。"
L.EMPTY_SEARCHRO_HEAD = "沒有結果。"
L.EMPTY_SEARCHRO_SUB = "換個寫法，有時就找得到。"
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "記仇本"  -- [max 12]
L.MANUAL_BOOK = "在野外殺死你的人會被自動記下。死後點擊畫面上的訊息，就會翻到兇手那一頁。"
L.MANUAL_WANTED_HEAD = "通緝"  -- [max 12]
L.MANUAL_WANTED = "殺過你的人，最狠的排最前面。點擊可查看附有罪行和備註的通緝令。已赦免的人被劃掉，排在最後。"
L.MANUAL_UNSOLVED_HEAD = "待查"  -- [max 13]
L.MANUAL_UNSOLVED = "不確定是誰下的手，案子就在這裡等著。點擊一個名字就能確定兇手。"
L.MANUAL_ALERT_HEAD = "警報"  -- [max 12]
L.MANUAL_ALERT = "兇手一出現在名條、目標或滑鼠指向中，記仇本就會發出警報。點擊即可將其選為目標，戰鬥中則要等戰鬥結束後。"
L.MANUAL_ADD_HEAD = "新增"  -- [max 12]
L.MANUAL_ADD = "在搜尋欄輸入名字，按Enter。右鍵點擊一行：記下復仇、赦免、劃掉。"
L.MANUAL_GUILD_HEAD = "公會"  -- [max 12]
L.MANUAL_GUILD = "裝了DeathNote的公會成員和好友看得到你已查明兇手的死亡和手動條目。通緝令或/dn hunt 名字：列入追殺名單。點擊賞金：懸賞你自己的（只是承諾，兌現在你們之間）。"
L.MANUAL_SHARE_HEAD = "傳閱"  -- [max 12]
L.MANUAL_SHARE = "家規，備份記仇本：產生一段可複製的文字，給所有沒裝DeathNote的人。"
L.MANUAL_QUIET_HEAD = "安靜"  -- [max 12]
L.MANUAL_QUIET = "在地城和戰場裡警報保持沉默。其他時候：用滑鼠中鍵點擊小地圖按鈕，或輸入/dn quiet。"
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "真的要把{name}從記仇本上劃掉嗎？\n所有罪行和備註都會遺失。"
L.CONFIRM_DELETE_OK = "劃掉"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "清空這台電腦上的公會記仇本？\n它的追殺名單也會一起清空，你自己的追殺令會保留。\n你自己的記仇本保持不變。"
L.CONFIRM_GUILD_CLEAR_OK = "清空"  -- [max 14]
L.CONFIRM_CANCEL = "取消"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} 金幣"  -- [max 14]
L.BOUNTY_SILVER = "{count} 銀幣"  -- [max 14]
L.THOUSANDS_SEP = ","
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "確認"  -- [max 19]
L.ACT_DISMISS = "排除"  -- [max 19]
L.ACT_HUNT_AGAIN = "重新通緝"  -- [max 19]
L.ACT_REVENGE = "記下復仇"  -- [max 19]
L.ACT_PARDON = "赦免"  -- [max 19]
L.ACT_STRIKE = "劃掉"  -- [max 19]
L.ACT_OPEN_OWN = "在記仇本中打開"  -- [max 19]
L.ACT_ADOPT = "記入我的記仇本"  -- [max 19]
L.ACT_CALLOFF = "撤銷追殺"  -- [max 19]
L.ACT_RELEASE = "發布追殺"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "目擊：{time}"
L.ROW_NOT_SEEN = "尚未目擊"
L.ROW_PARDONED = "已赦免"
L.ROW_SUSPECT = "嫌疑"
L.MARK_REVENGE = "復仇{times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "兇手不明"
L.MARK_CANDIDATES = "{count}名候選"  -- [max 16]
L.MARK_SUSPECT = "嫌疑"  -- [max 16]
L.ROW_NO_PLAYER = "非玩家"
L.ROW_UNCLEAR = "死因不明"
L.MARK_NOT_COUNTED = "不計入"  -- [max 16]
L.ROW_LISTED_BY = "由{names}新增"
L.ROW_GKILLED = "殺過{kills}次"
L.ROW_VICTIMS = "{count}名受害者"
L.ROW_LAST = "最近：{text}"
L.MARK_IN_BOOK = "在記仇本上"  -- [max 16]
L.MEMBER_KILLERS = "{count}名兇手"  -- [max 14]
L.MEMBER_DEATHS = "{count}次死亡"  -- [max 12]
L.MEMBER_LISTED = "{count}條手動"  -- [max 14]
L.MEMBER_ME = "其他人看得到的你的紀錄"
L.MEMBER_NOTHING = "尚未分享任何內容"
L.MEMBER_LAST_DIED = "上次死亡：{time}"
L.MARK_YOU = "你"  -- [max 16]
L.MARK_FRIEND = "好友"  -- [max 16]
L.MARK_BOTH = "公會成員、好友"  -- [max 20]
L.MARK_TAKEN_DOWN = "已擊殺{times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "生死不論"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "罪行"  -- [max 14]
L.POSTER_NOTE = "備註"  -- [max 8]
L.POSTER_BOUNTY = "賞金"  -- [max 12]
L.ROLE_ASSIST = "助攻"  -- [max 14]
L.ROLE_SUSPECT = "嫌疑"  -- [max 14]
L.POSTER_LEVEL = "等級{level}"
L.POSTER_GUILD = "公會：{guild}"
L.POSTER_LAST_SEEN = "最後目擊：{time}"
L.POSTER_NOT_SEEN = "尚未目擊"
L.POSTER_ONLY_SUSPECT = "只有嫌疑，沒有證實的罪行。"
L.POSTER_NO_DEEDS = "沒有記下罪行。"
L.TIP_LISTED_AT = "新增於{time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "死因：{spell}"
L.TIP_VICTIM = "受害者：{name}"
L.TIP_VICTIM_LEVEL = "受害者：{name}（等級{level}）"
L.TIP_KILLER_LEVEL = "兇手等級：{level}"
L.TIP_ASSISTS = "助攻者：{names}"
L.TIP_ROLE_ASSIST = "助攻，沒有打出致命一擊。"
L.TIP_ROLE_SUSPECT = "只有嫌疑，未經證實。"
L.MORE_LINE = "……還有{count}個"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "公會記仇本"  -- [max 24]
L.POSTER_IN_BOOK_OF = "記錄者：{names}"
L.POSTER_SEEN = "目擊：{time}"
L.POSTER_SEEN_BY = "目擊：{time}，目擊者：{name}"
L.TIP_IN_BOOK_OF = "記錄者"
L.POSTER_REMARK = "附註"  -- [max 12]
L.POSTER_BY_HAND = "手動新增"  -- [max 22]
L.POSTER_VICTIMS = "受害者"  -- [max 12]
L.POSTER_LISTED = "新增者"  -- [max 14]
L.POSTER_LISTED_EMPTY = "手動新增。"
L.POSTER_NO_DEEDS_SENT = "沒有傳來罪行。"
L.POSTER_NONE_KNOWN = "不詳"
L.POSTER_NO_NAMES = "沒有傳來名字"
L.TIP_VICTIMS = "受害者"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "發布於{time}"
L.HUNT_REASON = "理由：{reason}"
L.POSTER_HUNTLIST = "追殺名單"  -- [max 24]
L.POSTER_RELEASED_N = "被列入追殺名單{times}"
L.POSTER_RELEASED_BY = "發布者：{names}"
L.POSTER_TAKEN_DOWN = "已擊殺"  -- [max 12]
L.POSTER_NOT_YET = "尚未得手"  -- [max 18]
L.POSTER_CALLS = "追殺令"  -- [max 14]
L.POSTER_NOBODY_LEFT = "已經沒人了。"
L.POSTER_LAST = "最近"  -- [max 13]
L.POSTER_TAKEN_BY = "被{name}擊殺，{time}"
L.POSTER_TAKEN_NOBODY = "還沒有人得手"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "死亡案件"  -- [max 20]
L.CASE_ASSISTS = "助攻者"  -- [max 24]
L.CASE_PICK = "確定兇手"  -- [max 24]
L.CASE_NOT_COUNTED = "不計入（副本、戰場或決鬥）"
L.CASE_KILLER = "兇手"  -- [max 24]
L.CASE_KILLER_SUSPECT = "兇手（嫌疑）"  -- [max 24]
L.CASE_CLICK_NAME = "點擊名字，打開此人的通緝令。"
L.CASE_GONE = "已經不在記仇本上。"
L.CASE_KILLER_UNCLEAR = "兇手不明"  -- [max 24]
L.CASE_SEVERAL = "有好幾個人都可能下手。誰的名字該記進記仇本？"
L.CASE_NOBODY = "沒有人可能下手。"
L.CASE_HOW = "經過"  -- [max 24]
L.CASE_PVE = "怪物，或者環境本身。不歸記仇本管。"
L.CASE_UNCLEAR = "不明"
L.CASE_DARK = "鑑識組一頭霧水。"
L.TIP_MORE_CANDIDATES = "更多候選人"
L.CASE_SOURCE_SUSPECT = "嫌疑：你死前不久，此人曾以你為目標。"
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "在兇手的滑鼠提示中加一行"  -- [max 44]
L.OPT_MINIMAP = "顯示小地圖按鈕"  -- [max 44]
L.OPT_ALERT = "兇手出現時發出警報"  -- [max 44]
L.OPT_FLASH = "螢幕邊緣閃紅光"  -- [max 44]
L.OPT_SUSPECTS = "嫌疑人也發出警報"  -- [max 44]
L.OPT_DEATHMSG = "PvP死亡後顯示訊息"  -- [max 44]
L.OPT_G_SHARE = "分享我的死亡"  -- [max 44]
L.OPT_G_SHAREMANUAL = "分享手動新增的條目"  -- [max 44]
L.OPT_G_RECEIVE = "接收公會記仇本"  -- [max 44]
L.OPT_G_ALERT = "公會記仇本裡的兇手出現時警告"  -- [max 44]
L.OPT_G_ALERTLISTED = "手動新增的條目也警告"  -- [max 44]
L.OPT_G_ANNOUNCE = "公會成員被殺時通知"  -- [max 44]
L.OPT_G_SIGHTINGS = "分享目擊"  -- [max 44]
L.OPT_F_SHARE = "與公會分享"  -- [max 44]
L.OPT_F_FRIENDS = "與好友分享"  -- [max 44]
L.OPT_F_ALERT = "殺過公會成員或好友的兇手出現時警告"  -- [max 44]
L.OPT_F_ALERTHUNT = "追殺目標出現時警告"  -- [max 44]
L.OPT_F_ANNOUNCE = "公會成員或好友死亡時通知"  -- [max 44]
L.OPT_F_SIGHTINGS = "與公會和好友分享目擊"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "公會"  -- [max 14]
L.SET_BOOK_SIZE = "記仇本大小"  -- [max 34]
L.SET_LANGUAGE = "語言"  -- [max 16]
L.SET_LANG_AUTO = "自動"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "重新載入後生效。"  -- [max 28]
L.SET_LANG_RELOAD = "立即重新載入"  -- [max 22]
L.SET_SEC_SHARE = "傳閱"  -- [max 24]
L.IO_EXPORT = "備份記仇本"  -- [max 17]
L.IO_IMPORT = "匯入記仇本"  -- [max 17]
L.SET_HINT_BOOK = "備份會把記仇本變成文字：可以留存，也可以交給公會以外的人。匯入只會合併，不會覆蓋任何內容。"
L.SET_SEC_SOUND = "聲音"  -- [max 24]
L.SET_SOUND = "提示音"  -- [max 22]
L.SET_VOLUME = "音量"  -- [max 22]
L.SET_CHANNEL = "聲道"  -- [max 12]
L.SET_SEC_THRESHOLD = "門檻"  -- [max 24]
L.SET_COOLDOWN = "每個兇手的冷卻時間"  -- [max 34]
L.SET_MINKILLS = "被此人殺死幾次後警報"  -- [max 34]
L.SET_ALERT_SIZE = "警報大小"  -- [max 34]
L.SET_TEST_ALERT = "測試警報"  -- [max 17]
L.SET_G_MINKILLS = "公會警告所需死亡次數"  -- [max 34]
L.SET_F_MINKILLS = "警告所需死亡次數"  -- [max 34]
L.SET_SEC_STATUS = "狀態"  -- [max 24]
L.SET_SEC_SHARING = "分享"
L.SET_SEC_WARN = "警報"
L.SET_MORE = "更多"
L.SET_GUILD_CLEAR = "清空公會記仇本"  -- [max 26]
L.SET_HINT_GUILD = "只與你自己的公會分享。從那裡傳來的內容與你的記仇本分開存放，直到你親自轉入。"
L.SET_HINT_FRIENDS = "只與裝了DeathNote的公會成員和好友分享。"
L.BTN_BACK = "返回"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "同步"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds}秒後再試"  -- [max 16]
L.TIP_FRIENDS = "好友"
L.TIP_GUILD_NAME = "公會：{guild}"
L.TIP_MATES_WITH = "裝了DeathNote的公會成員："
L.TIP_NO_MATE = "尚未發現裝了DeathNote的公會成員。"
L.TIP_FRIENDS_WITH = "裝了DeathNote的好友："
L.TIP_SHARED = "會分享：你已查明兇手的死亡、手動新增的條目和你的追殺令。"
L.TIP_NOT_SHARED = "不分享：備註、嫌疑、已赦免的玩家、匯入的條目。"
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "匯入"  -- [max 17]
L.IO_DONE = "已匯入：新增{new}條，合併{merged}條。"
L.IO_FAILED = "沒有成功。"
L.IO_SMALL = "只看精簡版"  -- [max 17]
L.IO_ALL = "顯示全部"  -- [max 17]
L.IO_MSG_FULL = "整本記仇本，含罪行（{size}）。"
L.IO_MSG_SHORT = "只有名字和次數（{size}）。含罪行：{full}。"
L.IO_MSG_BIG = "記仇本很大（{size}）：選取和複製需要一點時間。"
L.IO_HELP_EXPORT = "文字已選取：按Ctrl+C複製。可以留存，也可以交給好友。"
L.IO_HELP_IMPORT = "按Ctrl+V貼上備份的文字，然後點匯入。不會覆蓋任何內容。"
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "你公會裡所有裝了DeathNote的人和你的好友都看得到理由。"
L.REL_HINT_GUILD = "你公會裡所有裝了DeathNote的人都看得到理由。"
L.REL_HINT_FRIENDS = "你裝了DeathNote的好友看得到理由。"
L.REL_HEAD = "列入追殺名單"  -- [max 24]
L.REL_FOR = "可見"  -- [max 6]
L.REL_REASON = "理由"  -- [max 8]
L.REL_HINT2 = "你的備註只留給你自己。你的追殺令只有你自己能撤銷。"
L.REL_GO = "發布追殺"  -- [max 17]
L.REL_NONE = "沒有公會，與好友分享也已關閉。"
L.REL_CAP = "每份名單最多{own}道你自己的追殺令和{max}個目標。"
L.REL_FAILED = "現在無法發布追殺。"
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds}秒"  -- [max 7]
L.SET_HINT_SILENT = "無聲：警報只顯示，不出聲。"
L.SET_HINT_BUILTIN = "這個提示音的音量跟隨遊戲設定中的聲道。"
L.SET_HINT_LEVELS = "從小聲到大聲共五段。遊戲設定中的聲道滑桿會再疊加上去。"
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "公會與好友"  -- [max 18]
L.TIP_HELP_BUTTON = "記仇本怎麼用"
L.VIEW_HUNT = "追殺名單"  -- [max 13]
L.VIEW_BY_KILLER = "依兇手"  -- [max 13]
L.VIEW_BY_MATE = "依成員"  -- [max 13]
L.SRC_ALL = "全部"  -- [max 12]
L.SRC_GUILD = "公會"  -- [max 12]
L.SRC_FRIENDS = "好友"  -- [max 12]
L.SORT_HIDE_PARDONED = "隱藏已赦免"  -- [max 24]
L.SORT_SHOW_PARDONED = "顯示已赦免"  -- [max 24]
L.SEARCH_ADD = "搜尋或新增…"  -- [max 26]
L.SEARCH_SHORT = "搜尋…"  -- [max 10]
L.SEARCH_KILLER = "尋找兇手…"  -- [max 15]
L.SEARCH_JOURNAL = "兇手或地點…"  -- [max 26]
L.TIP_COLLAPSE_ALL = "全部收合"
L.TIP_EXPAND_ALL = "全部展開"
L.STATUS_NO_PLATES = "敵方名條已關閉：警報只看得到目標和滑鼠指向。"
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count}人被通緝"
L.MM_UNSOLVED = "{count}件待查"
L.MM_ALERT_OFF = "警報已關閉（中鍵點擊）"
L.MM_CLICK = "點擊：記仇本 · 右鍵：家規"
L.MM_MIDDLE = "中鍵點擊：開/關警報"
L.MM_DRAG = "拖曳：沿小地圖邊緣移動"
L.MM_CHAT_ALERT_ON = "警報已開啟。"
L.MM_CHAT_ALERT_OFF = "警報已關閉。"
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "公會頭號公敵"  -- [max 25]
L.STAMP_HUNT = "格殺勿論"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name}冒充你的好友{friend}：已拒絕。"
L.FRIENDS_SHORT_IMPOSTOR = "已拒絕陌生人"  -- [max 22]
L.ALERT_LEVEL = "等級{level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "上次等級{level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "等級??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · 在追殺名單上（{names}）"
L.BANNER_NEW_HUNTS = "{count}個新目標"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "新列入追殺名單"
L.OPT_F_ANNOUNCEHUNT = "通知追殺名單動態：新目標、已擊殺"  -- [max 44]
L.SET_HUNT_EXPIRE = "追殺令過期時間"  -- [max 30]
L.SET_EXPIRE_NEVER = "永不"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count}天"  -- [max 10]
L.SET_FRIENDS_CLEAR = "清空好友記仇本"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "清空這台電腦上的好友記仇本？\n它的追殺名單也會一起清空，你自己的追殺令會保留。"
L.CONFIRM_CALLOFF_ALL = "撤銷你在追殺名單上的全部追殺令？\n公會和好友會陸續收到消息。"
L.CONFIRM_CALLOFF_ALL_OK = "全部撤銷"  -- [max 14]
L.ACT_CALLOFF_ALL = "撤銷我的全部追殺令"  -- [max 24]
L.ACT_HUNT_HIDE = "對我隱藏"  -- [max 19]
L.ACT_HUNT_SHOW = "重新顯示"  -- [max 19]
L.HUNT_ROW_HIDDEN = "已對你隱藏"
L.HUNT_ROW_CALLS = "{count}道追殺令：{names}"
L.POSTER_ON_HUNTLIST = "在追殺名單上（{names}）"
L.REL_SELF = "你不能把自己列入追殺名單。"
L.REL_MATE = "這是自己人（裝了DeathNote的公會成員或好友）。"
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "誰是你的好友{friend}：{a}還是{b}？請選擇。"
L.FRIENDS_SHORT_CONFLICT = "好友待確認"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "兩名玩家都自稱是你的好友{friend}：{a}和{b}。在你選擇之前，記仇本不接受他們任何一方的內容。公會與好友，依成員檢視：右鍵點擊名字。"
L.MEMBER_CONFLICT = "右鍵：這是你的好友嗎？"  -- [max 40]
L.ACT_TIE_MINE = "我的好友：{name}"  -- [max 24]
L.ACT_TIE_LOOSE = "解除綁定"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "解除{name}與好友名單的綁定？\n這個名字帶進好友記仇本的內容將被刪除；之後以這個名字傳來的下一則訊息會重新綁定。"
L.CHAT_FRIENDS_TIES = "已綁定的完整名字（* = 首次接觸，尚未確認）：{list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <名字 [姓氏]> <金幣>  懸賞你自己的賞金（不寫金額：撤回）"
L.CHAT_WHO_BOUNTY = "懸賞誰？/dn bounty <名字> <金幣>"
L.CHAT_BOUNTY_SET = "{name}：你懸賞了{gold}金幣。裝了DeathNote的公會成員和好友都看得到。"
L.CHAT_BOUNTY_OFF = "{name}：你的賞金已撤回。"
L.CHAT_BOUNTY_NONE = "你沒有給{name}懸賞。"
L.CHAT_BOUNTY_BAD = "賞金：1到99999之間的整數金幣（0為撤回）。"
L.CHAT_BOUNTY_CAP = "無法懸賞：你自己最多{count}份。"
L.CHAT_BOUNTY_OURS = "不能懸賞你自己或自己人（裝了DeathNote的公會成員或好友）。"
L.ACT_BOUNTY = "設定賞金"  -- [max 24]
L.ACT_UNDO = "撤銷"  -- [max 19]
L.ACT_REVENGE_TAKE = "減去一次復仇"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}，由你懸賞"
L.POSTER_BOUNTY_BY = "{gold}，由{name}懸賞"
L.POSTER_BOUNTY_MANY = "賞金{gold}：{names}"
L.POSTER_AVENGED = "代為復仇：{names}"
L.ROW_AVENGED = "代為復仇{times}"
L.BOUNTY_TIP_HEAD = "你自己的賞金（金幣）"
L.BOUNTY_TIP_RULES = "1到99999之間的整數。留空或0：恢復記仇本的數值。Enter確認，Esc取消。"
L.BOUNTY_TIP_PROMISE = "裝了DeathNote的公會成員和好友都看得到。只是一句承諾，兌現在你們之間。"
L.BOUNTY_TIP_CLICK = "點擊：設定你自己的賞金"
L.CHAT_AVENGED = "{name}替你擊殺了{killer}。"
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}：你懸賞了{gold}金幣。"
L.CHAT_BOUNTY_UNKNOWN = "{name}不在你的任何一本書裡。只能懸賞書中的名字，照遊戲中顯示的寫：名字和姓氏。"
L.CHAT_BOUNTY_LIST = "你的懸賞（{count}/{max}）：{list}"
L.CHAT_BOUNTY_LIST_NONE = "你沒有懸賞任何人。"
-- <<< BOOK
-- >>> REPUTE (1.3.0) -------------------------------------------------------------------------------------------
L.REPUTE_LINE = "第{tier}階 · 路線：{path}"  -- [max 32]
L.PATH_R = "惡名"  -- [max 16]
L.PATH_E = "榮譽"  -- [max 16]
L.PATH_J = "狩獵"  -- [max 16]
L.PATH_S = "守護"  -- [max 16]
L.PATH_NONE = "未定"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) --------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "懷恨在心？"  -- [max 30]
L.ALERT_LINE_VICTIM = "比分 {score} · 被你殺過，最近：{time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · 比分 {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · 比分 {score}，兩清"
L.ALERT_LINE_STANDING_AHEAD = "{text} · 比分 {score}，超額"
-- <<< ALARM
-- >>> START (1.3.0) --------------------------------------------------------------------------------------------
L.SET_THEME = "封面"  -- [max 16]
L.START_HINT = "兩項之後都可以在家規裡變更。"  -- [max 60]
L.START_GO = "開始"  -- [max 16]
L.START_CLOSE_TIP = "保持原樣"  -- [max 32]
L.CHAT_THEME_NEWS = "新內容：記仇本有了其他封面。家規的記仇本頁，或/dn theme。"
L.HELP_START = "/dn start  再次開啟首次啟動視窗（語言和封面）"
-- <<< START
-- >>> RECORD (1.3.0) -------------------------------------------------------------------------------------------
L.TAB_RECORD = "案底"  -- [max 16]
L.STAMP_QUITT = "兩清"  -- [max 16]
L.STAMP_OVERPAID = "超額償還"  -- [max 16]
L.STAMP_NR1_DOWN = "頭號公敵 已倒下"  -- [max 24]
L.STATE_OPEN = "未清"  -- [max 16]
L.STATE_EVEN = "兩清"  -- [max 16]
L.STATE_AHEAD = "超額"  -- [max 16]
L.STATE_VICTIM = "不在記仇本裡"  -- [max 24]
L.STAND_LINE = "比分 {score}"
L.STAND_TIP = "你 {mine}，他 {his}"
L.TIP_IN_RECORD = "案底："
L.TIP_RECORD_LINE = "被你殺了{times}，最近：{time}"
L.RECORD_HEAD = "我的檔案"  -- [max 20]
L.RECORD_LOG_HEAD = "最近擊殺"  -- [max 20]
L.RECORD_NEXT = "距離{rank}還差{points}點"
L.RECORD_TOP = "已達最高等階。"
L.RECORD_BAR_TIP = "{total}/{goal}點"
L.RECORD_NEEDLE_LOW = "冷酷無情"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "光明磊落"  -- [max 12]
L.RECORD_NEEDLE_TIP = "指針：榮譽與守護對抗惡名。狩獵不會讓它移動。"
L.RECORD_KILLS = "擊殺：{kills} · 受害者：{victims}"
L.RECORD_BEST = "最佳：{list}"
L.RECORD_BEST_GAP = "+{count}級"
L.RECORD_BEST_STREAK = "{count}連殺"
L.RECORD_BEST_QUICK = "最快復仇{time}"
L.DUR_SECONDS = "{count}秒"
L.DUR_MINUTES = "{count}分鐘"
L.DUR_HOURS = "{count}小時"
L.RECORD_AWARDS = "勳章"  -- [max 14]
L.RECORD_AWARD_AT = "授予於{time}"
L.RECORD_AWARD_OPEN = "尚未獲得"
L.RECORD_MORE = "顯示更多"  -- [max 19]
L.RECORD_BACK = "返回檔案"  -- [max 19]
L.RECORD_CLEAR = "清空案底"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "清空案底？\n所有受害者和最近擊殺列表都會刪除。等階、點數和勳章保留。"
L.CONFIRM_RECORD_CLEAR_OK = "清空"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "將{name}從案底中劃掉？\n已獲得的點數保留。"
L.ACT_VICTIM_STRIKE = "從案底中劃掉"  -- [max 26]
L.VICTIM_KILLED = "被你殺了{times}"
L.VICTIM_POINTS = "獲得點數：{points}"
L.VICTIM_SCENE = "案發地點：{zone}，{time}"
L.VICTIM_KILLS_LABEL = "我的擊殺"  -- [max 14]
L.KILL_TAG_REVENGE = "復仇"  -- [max 14]
L.KILL_TAG_KICK = "鞭屍"  -- [max 14]
L.KILL_TAG_GROUP = "組隊"  -- [max 14]
L.KILL_WITH_GROUP = "和隊友一起。"
L.BAND_GRAU = "灰色"  -- [max 12]
L.BAND_GRUEN = "綠色"  -- [max 12]
L.BAND_GELB = "黃色"  -- [max 12]
L.BAND_ORANGE = "橘色"  -- [max 12]
L.BAND_ROT = "紅色"  -- [max 12]
L.BAND_SCHAEDEL = "骷髏"  -- [max 12]
L.BAND_UNBEKANNT = "未知"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "無點數"
L.RECORD_BANDS = "依等級顏色"
L.TIP_PATH_R = "惡名：擊殺灰色和綠色等級的玩家。"
L.TIP_PATH_E = "榮譽：擊殺與你等級相近的玩家，復仇。"
L.TIP_PATH_J = "狩獵：擊殺等級更高者、追殺名單目標、懸賞目標。"
L.TIP_PATH_S = "守護：擊殺殺害過公會成員或好友的玩家。"
L.SORT_STATE = "比分"  -- [max 14]
L.SORT_COUNT = "擊殺數"  -- [max 14]
L.SORT_POINTS = "點數"  -- [max 14]
L.CHAT_OWN_KILL = "案底：{name}，{level}（{band}）。{points}。"
L.CHAT_KILL_WITH_GROUP = "{line}{group}"
L.CHAT_PATH = "新路線：{path}。等階：{rank}。"
L.BANNER_RANK = "等階提升"  -- [max 24]
L.BANNER_AWARD = "獲得勳章"  -- [max 24]
L.OPT_LEDGER = "記錄案底"  -- [max 44]
L.OPT_LEDGER_CHAT = "在聊天視窗通報自己的擊殺"  -- [max 44]
L.OPT_VICTIMS = "自己的受害者出現時警告"  -- [max 44]
L.SET_SETTLED = "仇已報清時的警報"  -- [max 34]
L.SET_SETTLED_ALWAYS = "照常"  -- [max 10]
L.SET_SETTLED_QUIET = "靜音"  -- [max 10]
L.SET_SETTLED_OFF = "不提醒"  -- [max 10]
L.MANUAL_RECORD_HEAD = "案底"  -- [max 14]
L.MANUAL_RECORD = "你親手對玩家打出的致命一擊。通緝令和列表顯示比分「你 : 他」：未清、兩清或超額。第一名永遠是未清的。擊殺會為你的等階贏得點數。"
L.POSTER_LAST_SEEN_IN = "最後目擊：{zone}，{time}"
L.SHEET_RECORD = "案底"  -- [max 14]
L.EMPTY_RECORD_HEAD = "還沒有人。"
L.EMPTY_RECORD_SUB = "你殺死的敵對陣營玩家會出現在這裡。"
-- <<< RECORD
end)
