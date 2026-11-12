-- DeathNote: 中文(简体) (zhCN).
-- Plural: 1 form {count|other} (no plural). Rule in Locale.lua (PLURAL_OF.zhCN), not here.
-- Fonts: hans (ARKai_T, ARHei) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Terms: book 记仇本, guild book 公会记仇本, friends' book 好友记仇本, killer 凶手, guildmate 公会成员,
-- Hit List 追杀名单, call 追杀令. Game terms as in the official zhCN client (姓名板, 密语, 地下城).
--
-- TOC-Notes: 野外PvP记仇本：记住谁杀了你，并在他们靠近时提醒你。

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("zhCN")) then return end

Locale.Register("zhCN", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "通缉"  -- [max 16]
L.TAB_UNSOLVED = "待查"  -- [max 16]
L.TAB_DEATHLOG = "死亡记录"  -- [max 16]
L.TAB_GUILD = "公会"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "家规"  -- [max 24]
L.HEAD_HELP = "使用说明"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "记仇本"  -- [max 14]
L.SHEET_ALERT = "警报"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "头号公敌"  -- [max 24]
L.STAMP_REVENGE = "已复仇"  -- [max 16]
L.STAMP_PARDONED = "已赦免"  -- [max 16]
L.STAMP_SUSPECT = "嫌疑"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "头号公敌现身"  -- [max 30]
L.ALERT_SIGHTED = "公敌现身"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "嫌疑人现身"  -- [max 30]
L.ALERT_TITLE_GUILD = "公会仇敌现身"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "杀害好友的凶手现身"  -- [max 30]
L.ALERT_TITLE_HUNT = "追杀目标"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "有嫌疑"
L.ALERT_LINE_KILLED = "杀了你{times}"
L.ALERT_LINE_KILLED_ASSISTED = "杀了你{times}，助攻{assists}"
L.ALERT_LINE_ASSISTED = "协助杀你{times}"
L.ALERT_LINE_MANUAL = "被手动记入记仇本"
L.ALERT_LINE_LAST = "{text}，上次{time}"
L.ALERT_LINE_IN = "{text}，在{zone}"
L.ALERT_LINE_REVENGE = "{text}。复仇：{times}"
L.ALERT_HINT_CLOSE = "右键：关闭"  -- [max 44]
L.ALERT_HINT_COMBAT = "脱离战斗后才能选中"  -- [max 44]
L.ALERT_HINT_TARGET = "点击：选中  ·  右键：关闭"  -- [max 44]
L.ALERT_MORE = "另有{count}条"  -- [max 14]
L.SAMPLE_ZONE = "荆棘谷"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "在公会记仇本上"
L.GUILD_LINE_IN_FRIENDS = "在好友记仇本上"
L.GUILD_LINE_LISTED_BY = "在{names}的记仇本上"
L.GUILD_LINE_KILLED_GUILD = "杀过公会成员{kills}次"
L.GUILD_LINE_KILLED_FRIENDS = "杀过好友{kills}次"
L.GUILD_LINE_KILLED_BOTH = "杀过公会成员和好友{kills}次"
L.GUILD_LINE_LAST = "{text}，最近受害者：{name}"
L.HUNT_LINE_BY = "由{names}列入追杀名单"
L.HUNT_LINE_RELEASED = "在追杀名单上"
L.HUNT_LINE_REASON = "{text}：{reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}次"
L.TALLY_SUSPECT = "有嫌疑"
L.TALLY_MANUAL = "手动添加"
L.TALLY_NONE = "尚无罪行"
L.TALLY_KILLED = "杀了你{times}"
L.TALLY_ASSISTED = "助攻{times}"
L.PLACE_UNKNOWN = "未知地点"
L.GKILLS_CAP = "至少{count}"
L.NAMELIST_MORE = "{names}及另外{count}人"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%m-%d %H:%M"
L.TIME_FMT_WHEN_YEAR = "%Y-%m-%d %H:%M"
L.TIME_FMT_DAY = "%m-%d"
L.TIME_FMT_DAY_YEAR = "%y-%m-%d"
L.TIME_NEVER = "从未"
L.TIME_JUST = "刚刚"
L.TIME_MINUTES = "{count}分钟前"  -- [max 14]
L.TIME_HOURS = "{count}小时前"  -- [max 14]
L.TIME_DAYS = "{count}天前"  -- [max 16]
L.MONEY_GOLD = "{count}金"
L.MONEY_SILVER = "{count}银"
L.MONEY_COPPER = "{count}铜"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "已发现{count}名装有DeathNote的公会成员。"
L.HEALTH_NOGUILD = "你不在任何公会中，不会共享任何内容。"
L.HEALTH_OFF = "共享已关闭。"
L.HEALTH_SHORT_NOGUILD = "无公会"  -- [max 18]
L.HEALTH_SHORT_OFF = "共享已关闭"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "被封锁"  -- [max 18]
L.HEALTH_SHORT_FAILING = "被拒绝"  -- [max 18]
L.HEALTH_SHORT_HOLD = "等待中"  -- [max 18]
L.HEALTH_SHORT_ASKED = "已请求"  -- [max 18]
L.HEALTH_SHORT_FAIL = "不可用"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "无声"  -- [max 16]
L.SOUND_RAIDWARNING = "团队警告"  -- [max 16]
L.SOUND_BELL = "钟声"  -- [max 16]
L.SOUND_GONG = "锣声"  -- [max 16]
L.SOUND_HEARTBEAT = "心跳"  -- [max 16]
L.SOUND_FEATHER = "羽毛笔"  -- [max 16]
L.SOUND_SIREN = "警笛"  -- [max 16]
L.CHANNEL_MASTER = "主音量"  -- [max 16]
L.CHANNEL_SFX = "音效"  -- [max 16]
L.CHANNEL_DIALOG = "对话"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name}已记入记仇本。"
L.CHAT_REMOVED = "{name}已从记仇本上划掉。"
L.CHAT_SYNC_WAIT = "刚同步过。请{seconds}秒后再试。"

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "还没有名字。"
L.EMPTY_WANTED_SUB = "偶尔也出门走走吧。"

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  打开/合上记仇本"
L.HELP_ADD = "/dn add <名字 [姓氏]>  手动把凶手记入记仇本"
L.HELP_DEL = "/dn del <名字 [姓氏]>  把凶手从记仇本上划掉"
L.HELP_QUIET = "/dn quiet  关闭/开启警报"
L.HELP_TEST = "/dn test  显示测试警报"
L.HELP_GUILD = "/dn guild  公会记仇本：状态，以及哪些公会成员装了DeathNote"
L.HELP_FRIENDS = "/dn friends  好友记仇本：状态，以及哪些好友装了DeathNote"
L.HELP_SYNC = "/dn sync  立即同步公会记仇本和好友记仇本"
L.HELP_HUNT = "/dn hunt <名字 [姓氏]>  列入追杀名单（不带名字：显示追杀名单）"
L.HELP_CALLOFF = "/dn calloff <名字 [姓氏]>  撤销你自己的追杀令"
L.HELP_LANG = "/dn lang <代码>  记仇本的语言（enUS、deDE、frFR ...），/reload后生效"
L.HELP_PROBE = "/dn probe  排查问题：游戏告诉了记仇本什么"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  排查问题，同时检测战斗记录"
L.HELP_DEBUG = "/dn debug  排查问题：详细记录每一次死亡（开/关）"
L.HELP_HELP = "/dn help  本帮助"
L.HELP_SILENT_ZONES = "在地下城、战场和竞技场中，记仇本会自动保持安静。"

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "开"
L.WORD_OFF = "关"
L.CHAT_WHO_ADD = "谁？/dn add <名字>"
L.CHAT_WHO_DEL = "谁？/dn del <名字>"
L.CHAT_WHO_CALLOFF = "谁？/dn calloff <名字>"
L.CHAT_BAD_NAME = "名字无效。"
L.CHAT_NOT_IN_BOOK = "不在记仇本上：{name}"
L.CHAT_ALARM_ON = "警报已开启。"
L.CHAT_ALARM_OFF = "警报已关闭。"
L.CHAT_DEBUG = "排查日志：{state}。"
L.CHAT_UNKNOWN_CMD = "未知命令。帮助：/dn help"
L.CHAT_GUILD_NOT_LOADED = "公会记仇本未加载。"
L.CHAT_NO_GUILD = "你不在任何公会中（或者游戏还不知道）。"
L.CHAT_GUILD_STATE = "公会<{guild}>：共享{share}，接收{receive}。"
L.CHAT_GUILD_BOOK = "公会记仇本：{enemies}名凶手（其中{listed}名仅为手动添加），{deeds}条罪行，{foreign}名涉及其他公会成员。共享手动条目：{manual}。"
L.CHAT_STATE_OK = "状态：{text}"
L.CHAT_STATE_WARN = "注意：{text}"
L.CHAT_NO_MATES = "尚未发现装有DeathNote的公会成员。"
L.CHAT_HAVE_DN = "装有DeathNote：{names}"
L.CHAT_HAVE_DN_MORE = "装有DeathNote：{names}及另外{count}人"
L.CHAT_SYNC_ASKED = "已请求同步。几秒内会收到回复。"
L.CHAT_SYNC_FAIL = "无法同步：{reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "没有公会，或共享已关闭。"
L.CHAT_FRIENDS_NOT_LOADED = "好友记仇本未加载。"
L.CHAT_FRIENDS_STATE = "好友：共享{share}，{online}/{total}在线。"
L.CHAT_FRIENDS_BOOK = "好友记仇本：{enemies}名凶手（其中{listed}名仅为手动添加），{deeds}条罪行。"
L.CHAT_NO_FRIENDS = "尚未发现装有DeathNote的好友。"
L.CHAT_HUNT_NOT_LOADED = "追杀名单未加载。"
L.CHAT_HUNT_UNKNOWN = "未知：{name}。请连姓氏一起输入，和游戏中显示的名字一致。"
L.CHAT_HUNT_CAP = "无法列入追杀名单：每份名单最多{own}道你自己的追杀令和{targets}个目标。"
L.CHAT_HUNT_NOWHERE = "现在无法列入追杀名单：没有公会，与好友共享也已关闭。"
L.CHAT_HUNT_BOTH = "{name}已列入追杀名单，公会和好友可见。"
L.CHAT_HUNT_GUILD = "{name}已列入追杀名单，公会可见。"
L.CHAT_HUNT_FRIENDS = "{name}已列入追杀名单，你的好友可见。"
L.CHAT_CALLED_OFF = "已撤销对{name}的追杀。"
L.CHAT_NO_OWN_CALL = "你没有针对{name}的追杀令。"
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "当前语言：{lang}。更改：/dn lang <代码>"
L.CHAT_LANG_LIST = "代码：{codes}"
L.CHAT_LANG_BAD = "未知语言：{code}"
L.CHAT_LANG_SET = "语言：{lang}。"
L.CHAT_LANG_RELOAD = "语言：{lang}。/reload后生效。"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "记仇本已准备好。在野外杀死你的人，之后都会记在上面。用/dn或小地图按钮打开。"
L.WELCOME_PLATES = "敌方姓名板已关闭。没有姓名板，警报只能看到你的目标。"
L.WELCOME_SHARE = "装有DeathNote的公会成员和好友也能一起看。备注和嫌疑只留给你自己。"

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "记仇本："
L.TIP_HUNT = "追杀名单："
L.TIP_GUILDBOOK = "公会记仇本："
L.TIP_PARDONED = "已赦免"
L.TIP_RANK = "第{rank}名"
L.TIP_REVENGE = "复仇{times}"
L.TIP_LISTED_BY = "在{names}的记仇本上"
L.TIP_NOTE = "备注：{note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "点击：打开 · 右键：关闭"
L.BANNER_NEW = "新记录"  -- [max 24]
L.BANNER_NEW_LINE = "已记入记仇本"
L.BANNER_AGAIN = "又来了"  -- [max 24]
L.BANNER_AGAIN_LINE = "又杀了你，已经{count}次了"
L.BANNER_SUSPECT = "嫌疑"  -- [max 24]
L.BANNER_SUSPECT_LINE = "有嫌疑，请到记仇本里查清"
L.BANNER_UNCLEAR = "凶手不明"  -- [max 24]
L.BANNER_CANDIDATES = "{count}名候选人"
L.BANNER_UNCLEAR_LINE = "点击：到待查中确定凶手"
L.BANNER_REVENGE = "血债血偿"  -- [max 24]
L.BANNER_REVENGE_LINE = "已复仇（{count}次）"
L.BANNER_GUILD = "公会"  -- [max 24]
L.BANNER_FRIENDS = "好友"  -- [max 24]
L.BANNER_KILLED_BY = "被{name}杀死"
L.BANNER_HUNT = "追杀名单"  -- [max 24]
L.BANNER_BAGGED = "已被{name}击杀，{time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "共享已关闭（家规，公会页）。"
L.SYNC_FRIENDS_OFF = "与好友共享已关闭。"
L.SYNC_NOBODY = "没有公会，也没有可以共享的好友。"
L.SYNC_SHORT_NOBODY = "未共享"  -- [max 18]
L.SYNC_PREFIX = "游戏不允许接收。重新登录即可。"
L.SYNC_SHORT_PREFIX = "无法接收"  -- [max 18]
L.SYNC_BLOCKED = "服务器阻止发送。请用“备份记仇本”传给别人。"
L.SYNC_SHORT_BLOCKED = "服务器阻止发送"  -- [max 22]
L.SYNC_FAILING = "暂时无法发送，正在重试。"
L.SYNC_SHORT_FAILING = "发送受阻"  -- [max 18]
L.SYNC_HOLD = "发送暂缓，{wait}。"
L.SYNC_HOLD_INSTANCE = "直到你离开副本"
L.SYNC_HOLD_COMBAT = "直到你脱离战斗"
L.SYNC_HOLD_LOCKDOWN = "直到聊天恢复可用"
L.SYNC_HOLD_AGAIN = "直到恢复正常"
L.SYNC_HOLD_SHORT_INSTANCE = "等待：副本"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "等待：战斗"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "等待：聊天"  -- [max 18]
L.SYNC_QUIET = "已发送，但尚未发现装有DeathNote的公会成员。"
L.SYNC_READY = "就绪。尚未发现装有DeathNote的公会成员。"
L.SYNC_RUNNING = "运行中：{count}名公会成员装有DeathNote。"
L.SYNC_RUNNING_ALL = "运行中：公会和好友中有{count}人装有DeathNote。"
L.FRIENDS_OFF = "与好友共享已关闭（家规，公会页）。"
L.FRIENDS_BLOCKED = "服务器阻止密语。好友什么也收不到。"
L.FRIENDS_SHORT_BLOCKED = "服务器阻止密语"  -- [max 22]
L.FRIENDS_FAILING = "暂时无法发送密语，正在重试。"
L.FRIENDS_SHORT_FAILING = "密语受阻"  -- [max 18]
L.FRIENDS_NONE_LISTED = "好友名单上没有好友。"
L.FRIENDS_NONE_ONLINE = "现在没有好友在线。"
L.FRIENDS_SHORT_NONE_ONLINE = "没有好友在线"  -- [max 18]
L.FRIENDS_QUIET = "已询问，但尚未发现装有DeathNote的好友。"
L.FRIENDS_READY = "就绪。尚未发现装有DeathNote的好友。"
L.FRIENDS_HOLD = "向好友发送暂缓，直到恢复正常。"
L.FRIENDS_RUNNING = "运行中：{count}名好友装有DeathNote。"
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "从公会记仇本转入（杀过公会成员{kills}次）。"

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "数据库未加载。"
L.IMPORT_NO_TEXT = "没有文本。"
L.IMPORT_NO_HEADER = "缺少第一行（以{header}开头）。请复制完整的文本。"
L.IMPORT_NOT_EXPORT = "不是DeathNote导出的文本（缺少标题行或版本不对）。"
L.IMPORT_TOO_LONG = "行数过多（最多{count}行）。"
L.IMPORT_BAD_KEY = "第{line}行：键无效。"
L.IMPORT_BAD_TIME = "第{line}行：时间无效。"
L.IMPORT_BROKEN = "第{line}行不完整或已损坏（文本被截断了？）。没有导入任何内容。"

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "是"
L.WORD_NO = "否"
L.PROBE_HEAD = "检测：{apis}/{apisAll}个接口可用，{events}/{eventsAll}个事件可注册。"
L.PROBE_MISSING = "缺少：{list}"
L.PROBE_NOT_REGISTERABLE = "无法注册：{list}"
L.PROBE_SOURCES = "当前Recap：{recap} · Meter：{meter} · 战斗记录：{clog}"
L.PROBE_READABLE = "可读"
L.PROBE_DEAD = "失效"
L.PROBE_PLATES = "敌方姓名板：{plates} · 野外：{open}"
L.PROBE_PLATES_OFF = "关（只有目标和鼠标指向能发现玩家）"
L.PROBE_TARGET = "目标：名字={name} GUID={guid} 职业={class} 敌对={enemy} 以我为目标={me}"
L.PROBE_GUILD = "公会：前缀{prefix} · 发送{send} · 上次返回值{result} · 已发送{sent}，已接收{received}，已丢弃{dropped}"
L.PROBE_REGISTERED = "已注册"
L.PROBE_NOT_REGISTERED = "未注册（{result}）"
L.PROBE_POSSIBLE = "可以"
L.PROBE_ABSENT = "缺少"
L.PROBE_WAITS = " · 等待：{why}"
L.PROBE_LISTED = "手动条目（M）：已发送{sent}，已接收{received}，已丢弃{dropped} · 划掉（X）：已发送{usent}，已接收{ureceived}，已丢弃{udropped}"
L.PROBE_GUILDBOOK = "公会记仇本：{text}"
L.PROBE_SAVED = "已保存到DeathNoteDB.probe（/reload后写入文件）。"

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "排名"  -- [max 14]
L.SORT_RECENT = "最新"  -- [max 14]
L.SORT_NAME = "名字"  -- [max 14]
L.SORT_SEEN = "目击"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "在野外杀死你的人会出现在这里。自动记下，不用你动手。"
L.EMPTY_OPEN_HEAD = "没有待查的案子。"
L.EMPTY_JOURNAL_HEAD = "还从没死过。"
L.EMPTY_JOURNAL_SUB = "佩服。要么就是在撒谎。"
L.EMPTY_NOGUILD_HEAD = "没有公会。"
L.EMPTY_NOGUILD_SUB = "一个人也照样能死。"
L.EMPTY_GUILDOFF_HEAD = "公会记仇本已合上。"
L.EMPTY_GUILDOFF_SUB = "共享已关闭。家规里写着在哪儿开。"
L.EMPTY_GUILDNIL_HEAD = "公会那边还没有消息。"
L.EMPTY_GUILDNIL_SUB = "一旦有公会成员装了DeathNote，你的记仇本就会发出去。"
L.EMPTY_GUILDQUIET_HEAD = "公会记仇本上还什么都没有。"
L.EMPTY_GUILDQUIET_SUB = "你的公会成员至今都很太平。"
L.EMPTY_FRIENDSOFF_HEAD = "好友记仇本已合上。"
L.EMPTY_FRIENDSOFF_SUB = "与好友共享已关闭。家规里写着在哪儿开。"
L.EMPTY_FRIENDSNIL_HEAD = "尚未发现装有DeathNote的好友。"
L.EMPTY_FRIENDSNIL_SUB = "一旦有好友装了DeathNote，你的记仇本就会发出去。"
L.EMPTY_FRIENDSQUIET_HEAD = "好友那边还什么都没有。"
L.EMPTY_FRIENDSQUIET_SUB = "你的好友至今都很太平。"
L.EMPTY_NOBODY_HEAD = "没有公会，也没有好友。"
L.EMPTY_NOBODY_SUB = "一个人也照样能死。"
L.EMPTY_NOBODY_HINT = "等公会成员或好友名单上的好友装了DeathNote，这里就会显示他们的遭遇。"
L.EMPTY_SHAREDNIL_HEAD = "尚未发现任何装有DeathNote的人。"
L.EMPTY_SHAREDNIL_SUB = "一旦有公会成员或好友装了DeathNote，你的记仇本就会发出去。"
L.EMPTY_SHAREDQUIET_HEAD = "这里还什么都没有。"
L.EMPTY_SHAREDQUIET_SUB = "公会和好友至今都很太平。"
L.EMPTY_HUNT_HEAD = "追杀名单是空的。"
L.EMPTY_HUNT_SUB = "在通缉令上点：发布追杀。"
L.EMPTY_HUNT_HINT = "或在聊天中输入：/dn hunt 名字 姓氏。你公会里的所有人和你的好友都能看到。"
L.EMPTY_SEARCH_HEAD = "没有结果。"
L.EMPTY_SEARCH_SUB = "按回车键把这个名字记入记仇本。"
L.EMPTY_SEARCHRO_HEAD = "没有结果。"
L.EMPTY_SEARCHRO_SUB = "换个写法，有时就能找到。"
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "记仇本"  -- [max 12]
L.MANUAL_BOOK = "在野外杀死你的人会被自动记下。死后点击屏幕上的提示，即可翻到凶手那一页。"
L.MANUAL_WANTED_HEAD = "通缉"  -- [max 12]
L.MANUAL_WANTED = "杀过你的人，最狠的排在最前。点击可查看带有罪行和备注的通缉令。已赦免的人被划掉，排在最后。"
L.MANUAL_UNSOLVED_HEAD = "待查"  -- [max 13]
L.MANUAL_UNSOLVED = "不确定是谁下的手，案子就在这里等着。点击一个名字即可确定凶手。"
L.MANUAL_ALERT_HEAD = "警报"  -- [max 12]
L.MANUAL_ALERT = "凶手一出现在姓名板、目标或鼠标指向中，记仇本就会报警。点击即可将其选为目标，战斗中则要等战斗结束后。"
L.MANUAL_ADD_HEAD = "添加"  -- [max 12]
L.MANUAL_ADD = "在搜索框输入名字，按回车。右键点击一行：记下复仇、赦免、划掉。"
L.MANUAL_GUILD_HEAD = "公会"  -- [max 12]
L.MANUAL_GUILD = "装有DeathNote的公会成员和好友能看到你已查明凶手的死亡和手动条目。通缉令或/dn hunt 名字：列入追杀名单。点击赏金：悬赏你自己的（只是承诺，兑现在你们之间）。"
L.MANUAL_SHARE_HEAD = "传阅"  -- [max 12]
L.MANUAL_SHARE = "家规，备份记仇本：生成一段可复制的文本，给所有没装DeathNote的人。"
L.MANUAL_QUIET_HEAD = "安静"  -- [max 12]
L.MANUAL_QUIET = "在地下城和战场中警报保持沉默。其他时候：中键点击小地图按钮，或输入/dn quiet。"
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "真的要把{name}从记仇本上划掉吗？\n所有罪行和备注都会丢失。"
L.CONFIRM_DELETE_OK = "划掉"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "清空这台电脑上的公会记仇本？\n它的追杀名单也会一起清空，你自己的追杀令保留。\n你自己的记仇本保持不变。"
L.CONFIRM_GUILD_CLEAR_OK = "清空"  -- [max 14]
L.CONFIRM_CANCEL = "取消"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} 金币"  -- [max 14]
L.BOUNTY_SILVER = "{count} 银币"  -- [max 14]
L.THOUSANDS_SEP = ","
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "确认"  -- [max 19]
L.ACT_DISMISS = "排除"  -- [max 19]
L.ACT_HUNT_AGAIN = "重新通缉"  -- [max 19]
L.ACT_REVENGE = "记下复仇"  -- [max 19]
L.ACT_PARDON = "赦免"  -- [max 19]
L.ACT_STRIKE = "划掉"  -- [max 19]
L.ACT_OPEN_OWN = "在记仇本中打开"  -- [max 19]
L.ACT_ADOPT = "记入我的记仇本"  -- [max 19]
L.ACT_CALLOFF = "撤销追杀"  -- [max 19]
L.ACT_RELEASE = "发布追杀"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "目击：{time}"
L.ROW_NOT_SEEN = "尚未目击"
L.ROW_PARDONED = "已赦免"
L.ROW_SUSPECT = "嫌疑"
L.MARK_REVENGE = "复仇{times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "凶手不明"
L.MARK_CANDIDATES = "{count}名候选"  -- [max 16]
L.MARK_SUSPECT = "嫌疑"  -- [max 16]
L.ROW_NO_PLAYER = "非玩家"
L.ROW_UNCLEAR = "死因不明"
L.MARK_NOT_COUNTED = "不计入"  -- [max 16]
L.ROW_LISTED_BY = "由{names}添加"
L.ROW_GKILLED = "杀过{kills}次"
L.ROW_VICTIMS = "{count}名受害者"
L.ROW_LAST = "最近：{text}"
L.MARK_IN_BOOK = "在记仇本上"  -- [max 16]
L.MEMBER_KILLERS = "{count}名凶手"  -- [max 14]
L.MEMBER_DEATHS = "{count}次死亡"  -- [max 12]
L.MEMBER_LISTED = "{count}条手动"  -- [max 14]
L.MEMBER_ME = "其他人看到的你的记录"
L.MEMBER_NOTHING = "尚未共享任何内容"
L.MEMBER_LAST_DIED = "上次死亡：{time}"
L.MARK_YOU = "你"  -- [max 16]
L.MARK_FRIEND = "好友"  -- [max 16]
L.MARK_BOTH = "公会成员、好友"  -- [max 20]
L.MARK_TAKEN_DOWN = "已击杀{times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "生死不论"  -- [max 24]
L.POSTER_DEEDS = "罪行"  -- [max 14]
L.POSTER_NOTE = "备注"  -- [max 8]
L.POSTER_BOUNTY = "赏金"  -- [max 12]
L.ROLE_ASSIST = "助攻"  -- [max 14]
L.ROLE_SUSPECT = "嫌疑"  -- [max 14]
L.POSTER_LEVEL = "等级{level}"
L.POSTER_GUILD = "公会：{guild}"
L.POSTER_LAST_SEEN = "最后目击：{time}"
L.POSTER_NOT_SEEN = "尚未目击"
L.POSTER_ONLY_SUSPECT = "仅有嫌疑，没有证实的罪行。"
L.POSTER_NO_DEEDS = "没有记下罪行。"
L.TIP_LISTED_AT = "添加于{time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "死因：{spell}"
L.TIP_VICTIM = "受害者：{name}"
L.TIP_VICTIM_LEVEL = "受害者：{name}（等级{level}）"
L.TIP_KILLER_LEVEL = "凶手等级：{level}"
L.TIP_ASSISTS = "助攻者：{names}"
L.TIP_ROLE_ASSIST = "助攻，没有打出致命一击。"
L.TIP_ROLE_SUSPECT = "仅有嫌疑，未经证实。"
L.MORE_LINE = "……另有{count}个"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "公会记仇本"  -- [max 24]
L.POSTER_IN_BOOK_OF = "记录者：{names}"
L.POSTER_SEEN = "目击：{time}"
L.POSTER_SEEN_BY = "目击：{time}，目击者：{name}"
L.TIP_IN_BOOK_OF = "记录者"
L.POSTER_REMARK = "附注"  -- [max 12]
L.POSTER_BY_HAND = "手动添加"  -- [max 22]
L.POSTER_VICTIMS = "受害者"  -- [max 12]
L.POSTER_LISTED = "添加者"  -- [max 14]
L.POSTER_LISTED_EMPTY = "手动添加。"
L.POSTER_NO_DEEDS_SENT = "没有传来罪行。"
L.POSTER_NONE_KNOWN = "不详"
L.POSTER_NO_NAMES = "没有传来名字"
L.TIP_VICTIMS = "受害者"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "发布于{time}"
L.HUNT_REASON = "理由：{reason}"
L.POSTER_HUNTLIST = "追杀名单"  -- [max 24]
L.POSTER_RELEASED_N = "被列入追杀名单{times}"
L.POSTER_RELEASED_BY = "发布者：{names}"
L.POSTER_TAKEN_DOWN = "已击杀"  -- [max 12]
L.POSTER_NOT_YET = "尚未得手"  -- [max 18]
L.POSTER_CALLS = "追杀令"  -- [max 14]
L.POSTER_NOBODY_LEFT = "已经没人了。"
L.POSTER_LAST = "最近"  -- [max 13]
L.POSTER_TAKEN_BY = "被{name}击杀，{time}"
L.POSTER_TAKEN_NOBODY = "还没有人得手"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "死亡案件"  -- [max 20]
L.CASE_ASSISTS = "助攻者"  -- [max 24]
L.CASE_PICK = "确定凶手"  -- [max 24]
L.CASE_NOT_COUNTED = "不计入（副本、战场或决斗）"
L.CASE_KILLER = "凶手"  -- [max 24]
L.CASE_KILLER_SUSPECT = "凶手（嫌疑）"  -- [max 24]
L.CASE_CLICK_NAME = "点击名字，打开此人的通缉令。"
L.CASE_GONE = "已不在记仇本上。"
L.CASE_KILLER_UNCLEAR = "凶手不明"  -- [max 24]
L.CASE_SEVERAL = "有好几个人都可能下手。谁的名字该记进记仇本？"
L.CASE_NOBODY = "没有人可能下手。"
L.CASE_HOW = "经过"  -- [max 24]
L.CASE_PVE = "怪物，或者环境本身。不归记仇本管。"
L.CASE_UNCLEAR = "不明"
L.CASE_DARK = "鉴证科一头雾水。"
L.TIP_MORE_CANDIDATES = "更多候选人"
L.CASE_SOURCE_SUSPECT = "嫌疑：你死前不久，此人曾以你为目标。"
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "在凶手的鼠标提示中加一行"  -- [max 44]
L.OPT_MINIMAP = "显示小地图按钮"  -- [max 44]
L.OPT_ALERT = "凶手出现时报警"  -- [max 44]
L.OPT_FLASH = "屏幕边缘闪红光"  -- [max 44]
L.OPT_SUSPECTS = "嫌疑人也报警"  -- [max 44]
L.OPT_DEATHMSG = "PvP死亡后显示提示"  -- [max 44]
L.OPT_G_SHARE = "共享我的死亡"  -- [max 44]
L.OPT_G_SHAREMANUAL = "共享手动添加的条目"  -- [max 44]
L.OPT_G_RECEIVE = "接收公会记仇本"  -- [max 44]
L.OPT_G_ALERT = "公会记仇本里的凶手出现时警告"  -- [max 44]
L.OPT_G_ALERTLISTED = "手动添加的条目也警告"  -- [max 44]
L.OPT_G_ANNOUNCE = "公会成员被杀时提示"  -- [max 44]
L.OPT_G_SIGHTINGS = "共享目击"  -- [max 44]
L.OPT_F_SHARE = "与公会共享"  -- [max 44]
L.OPT_F_FRIENDS = "与好友共享"  -- [max 44]
L.OPT_F_ALERT = "杀过公会成员或好友的凶手出现时警告"  -- [max 44]
L.OPT_F_ALERTHUNT = "追杀目标出现时警告"  -- [max 44]
L.OPT_F_ANNOUNCE = "公会成员或好友死亡时提示"  -- [max 44]
L.OPT_F_SIGHTINGS = "与公会和好友共享目击"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "公会"  -- [max 14]
L.SET_BOOK_SIZE = "记仇本大小"  -- [max 34]
L.SET_LANGUAGE = "语言"  -- [max 16]
L.SET_LANG_AUTO = "自动"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "重新载入后生效。"  -- [max 28]
L.SET_LANG_RELOAD = "立即重新载入"  -- [max 22]
L.SET_SEC_SHARE = "传阅"  -- [max 24]
L.IO_EXPORT = "备份记仇本"  -- [max 17]
L.IO_IMPORT = "导入记仇本"  -- [max 17]
L.SET_HINT_BOOK = "备份会把记仇本变成文本：可以留存，也可以传给公会以外的人。导入只会合并，不会覆盖任何内容。"
L.SET_SEC_SOUND = "声音"  -- [max 24]
L.SET_SOUND = "提示音"  -- [max 22]
L.SET_VOLUME = "音量"  -- [max 22]
L.SET_CHANNEL = "声道"  -- [max 12]
L.SET_SEC_THRESHOLD = "门槛"  -- [max 24]
L.SET_COOLDOWN = "每个凶手的冷却时间"  -- [max 34]
L.SET_MINKILLS = "被此人杀死几次后报警"  -- [max 34]
L.SET_ALERT_SIZE = "警报大小"  -- [max 34]
L.SET_TEST_ALERT = "测试警报"  -- [max 17]
L.SET_G_MINKILLS = "公会警告所需死亡次数"  -- [max 34]
L.SET_F_MINKILLS = "警告所需死亡次数"  -- [max 34]
L.SET_SEC_STATUS = "状态"  -- [max 24]
L.SET_SEC_SHARING = "共享"
L.SET_SEC_WARN = "警报"
L.SET_MORE = "更多"
L.SET_GUILD_CLEAR = "清空公会记仇本"  -- [max 26]
L.SET_HINT_GUILD = "只与你自己的公会共享。从那里传来的内容与你的记仇本分开存放，直到你亲自转入。"
L.SET_HINT_FRIENDS = "只与装有DeathNote的公会成员和好友共享。"
L.BTN_BACK = "返回"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "同步"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds}秒后再试"  -- [max 16]
L.TIP_FRIENDS = "好友"
L.TIP_GUILD_NAME = "公会：{guild}"
L.TIP_MATES_WITH = "装有DeathNote的公会成员："
L.TIP_NO_MATE = "尚未发现装有DeathNote的公会成员。"
L.TIP_FRIENDS_WITH = "装有DeathNote的好友："
L.TIP_SHARED = "共享：你已查明凶手的死亡、手动添加的条目和你的追杀令。"
L.TIP_NOT_SHARED = "不共享：备注、嫌疑、已赦免的玩家、导入的条目。"
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "导入"  -- [max 17]
L.IO_DONE = "已导入：新增{new}条，合并{merged}条。"
L.IO_FAILED = "没成功。"
L.IO_SMALL = "只看精简版"  -- [max 17]
L.IO_ALL = "显示全部"  -- [max 17]
L.IO_MSG_FULL = "整本记仇本，含罪行（{size}）。"
L.IO_MSG_SHORT = "只有名字和计数（{size}）。含罪行：{full}。"
L.IO_MSG_BIG = "记仇本很大（{size}）：选中和复制需要一点时间。"
L.IO_HELP_EXPORT = "文本已选中：按Ctrl+C复制。可以留存，也可以传给好友。"
L.IO_HELP_IMPORT = "按Ctrl+V粘贴备份的文本，然后点导入。不会覆盖任何内容。"
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "你公会里所有装有DeathNote的人和你的好友都能看到理由。"
L.REL_HINT_GUILD = "你公会里所有装有DeathNote的人都能看到理由。"
L.REL_HINT_FRIENDS = "你装有DeathNote的好友能看到理由。"
L.REL_HEAD = "列入追杀名单"  -- [max 24]
L.REL_FOR = "可见"  -- [max 6]
L.REL_REASON = "理由"  -- [max 8]
L.REL_HINT2 = "你的备注只留给你自己。你的追杀令只有你自己能撤销。"
L.REL_GO = "发布追杀"  -- [max 17]
L.REL_NONE = "没有公会，与好友共享也已关闭。"
L.REL_CAP = "每份名单最多{own}道你自己的追杀令和{max}个目标。"
L.REL_FAILED = "现在无法发布追杀。"
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds}秒"  -- [max 7]
L.SET_HINT_SILENT = "无声：警报只显示，不出声。"
L.SET_HINT_BUILTIN = "这个提示音的音量跟随游戏设置中的声道。"
L.SET_HINT_LEVELS = "从轻到响共五档。游戏设置中的声道滑块会叠加生效。"
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "公会与好友"  -- [max 18]
L.TIP_HELP_BUTTON = "记仇本怎么用"
L.VIEW_HUNT = "追杀名单"  -- [max 13]
L.VIEW_BY_KILLER = "按凶手"  -- [max 13]
L.VIEW_BY_MATE = "按成员"  -- [max 13]
L.SRC_ALL = "全部"  -- [max 12]
L.SRC_GUILD = "公会"  -- [max 12]
L.SRC_FRIENDS = "好友"  -- [max 12]
L.SORT_HIDE_PARDONED = "隐藏已赦免"  -- [max 24]
L.SORT_SHOW_PARDONED = "显示已赦免"  -- [max 24]
L.SEARCH_ADD = "搜索或添加…"  -- [max 26]
L.SEARCH_SHORT = "搜索…"  -- [max 10]
L.SEARCH_KILLER = "查找凶手…"  -- [max 15]
L.SEARCH_JOURNAL = "凶手或地点…"  -- [max 26]
L.TIP_COLLAPSE_ALL = "全部折叠"
L.TIP_EXPAND_ALL = "全部展开"
L.STATUS_NO_PLATES = "敌方姓名板已关闭：警报只能看到目标和鼠标指向。"
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count}人被通缉"
L.MM_UNSOLVED = "{count}件待查"
L.MM_ALERT_OFF = "警报已关闭（中键点击）"
L.MM_CLICK = "点击：记仇本 · 右键：家规"
L.MM_MIDDLE = "中键点击：开/关警报"
L.MM_DRAG = "拖动：沿小地图边缘移动"
L.MM_CHAT_ALERT_ON = "警报已开启。"
L.MM_CHAT_ALERT_OFF = "警报已关闭。"
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "公会头号公敌"  -- [max 25]
L.STAMP_HUNT = "格杀勿论"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name}冒充你的好友{friend}：已拒绝。"
L.FRIENDS_SHORT_IMPOSTOR = "已拒绝陌生人"  -- [max 22]
L.ALERT_LEVEL = "等级{level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "上次等级{level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "等级??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · 在追杀名单上（{names}）"
L.BANNER_NEW_HUNTS = "{count}个新目标"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "新列入追杀名单"
L.OPT_F_ANNOUNCEHUNT = "提示追杀名单动态：新目标、已击杀"  -- [max 44]
L.SET_HUNT_EXPIRE = "追杀令过期时间"  -- [max 30]
L.SET_EXPIRE_NEVER = "永不"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count}天"  -- [max 10]
L.SET_FRIENDS_CLEAR = "清空好友记仇本"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "清空这台电脑上的好友记仇本？\n它的追杀名单也会一起清空，你自己的追杀令保留。"
L.CONFIRM_CALLOFF_ALL = "撤销你在追杀名单上的全部追杀令？\n公会和好友会陆续收到消息。"
L.CONFIRM_CALLOFF_ALL_OK = "全部撤销"  -- [max 14]
L.ACT_CALLOFF_ALL = "撤销我的全部追杀令"  -- [max 24]
L.ACT_HUNT_HIDE = "对我隐藏"  -- [max 19]
L.ACT_HUNT_SHOW = "重新显示"  -- [max 19]
L.HUNT_ROW_HIDDEN = "已对你隐藏"
L.HUNT_ROW_CALLS = "{count}道追杀令：{names}"
L.POSTER_ON_HUNTLIST = "在追杀名单上（{names}）"
L.REL_SELF = "你不能把自己列入追杀名单。"
L.REL_MATE = "这是自己人（装有DeathNote的公会成员或好友）。"
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "谁是你的好友{friend}：{a}还是{b}？请选择。"
L.FRIENDS_SHORT_CONFLICT = "好友待确认"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "两名玩家都自称是你的好友{friend}：{a}和{b}。在你选择之前，记仇本不接受他们任何一方的内容。公会与好友，按成员视图：右键点击名字。"
L.MEMBER_CONFLICT = "右键：这是你的好友吗？"  -- [max 40]
L.ACT_TIE_MINE = "我的好友：{name}"  -- [max 24]
L.ACT_TIE_LOOSE = "解除绑定"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "解除{name}与好友名单的绑定？\n这个名字带进好友记仇本的内容将被删除；之后以这个名字发来的下一条消息会重新绑定。"
L.CHAT_FRIENDS_TIES = "已绑定的完整名字（* = 首次接触，尚未确认）：{list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <名字 [姓氏]> <金币>  悬赏你自己的赏金（不写金额：撤回）"
L.CHAT_WHO_BOUNTY = "悬赏谁？/dn bounty <名字> <金币>"
L.CHAT_BOUNTY_SET = "{name}：你悬赏了{gold}金币。装有DeathNote的公会成员和好友都能看到。"
L.CHAT_BOUNTY_OFF = "{name}：你的赏金已撤回。"
L.CHAT_BOUNTY_NONE = "你没有给{name}悬赏。"
L.CHAT_BOUNTY_BAD = "赏金：1到99999之间的整数金币（0为撤回）。"
L.CHAT_BOUNTY_CAP = "无法悬赏：你自己最多{count}份。"
L.CHAT_BOUNTY_OURS = "不能悬赏你自己或自己人（装有DeathNote的公会成员或好友）。"
L.ACT_BOUNTY = "设置赏金"  -- [max 24]
L.ACT_UNDO = "撤销"  -- [max 19]
L.ACT_REVENGE_TAKE = "减去一次复仇"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}，由你悬赏"
L.POSTER_BOUNTY_BY = "{gold}，由{name}悬赏"
L.POSTER_BOUNTY_MANY = "赏金{gold}：{names}"
L.POSTER_AVENGED = "代为复仇：{names}"
L.ROW_AVENGED = "代为复仇{times}"
L.BOUNTY_TIP_HEAD = "你自己的赏金（金币）"
L.BOUNTY_TIP_RULES = "1到99999之间的整数。留空或0：恢复记仇本的数值。回车确认，Esc取消。"
L.BOUNTY_TIP_PROMISE = "装有DeathNote的公会成员和好友都能看到。只是一句承诺，兑现在你们之间。"
L.BOUNTY_TIP_CLICK = "点击：设置你自己的赏金"
L.CHAT_AVENGED = "{name}替你击杀了{killer}。"
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}：你悬赏了{gold}金币。"
L.CHAT_BOUNTY_UNKNOWN = "{name}不在你的任何一本书里。只能悬赏书中的名字，按游戏中显示的写：名字和姓氏。"
L.CHAT_BOUNTY_LIST = "你的悬赏（{count}/{max}）：{list}"
L.CHAT_BOUNTY_LIST_NONE = "你没有悬赏任何人。"
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
