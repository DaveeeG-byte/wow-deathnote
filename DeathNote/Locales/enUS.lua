-- DeathNote: English (enUS, also enGB). The source for every translation and the fallback for every
-- key a language does not have yet.
--
-- For translators: copy the keys, never rename them. Each line says where the text shows and what
-- the placeholders mean. [max N] = the text must fit a fixed field (characters; zhCN/zhTW/koKR count
-- in cells, a CJK sign = 2). The limits themselves live in tests/sprachen/_limits.lua (not shipped);
-- the test checks both agree.
-- Placeholders: {name} etc. stay as they are, order is free. Plural: {count|form1|form2...} with
-- exactly as many forms as your language's rule (file head of your language). Check: see
-- TRANSLATING.md.
-- Words that never change: DeathNote, WANTED, the /dn commands. Class, race and zone names come from
-- the game. Tone: dry, a little grim, a notebook full of enemies; speak to the player informally.
--
-- TOC-Notes: Death list for open-world PvP: remembers who killed you and warns you when they are near.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("enUS")) then return end

Locale.Register("enUS", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED   = "Wanted"        -- [max 16] tab 1: everyone who killed you, ranked
L.TAB_UNSOLVED = "Unsolved"      -- [max 16] tab 2: deaths where the killer is not clear yet
L.TAB_DEATHLOG = "Death Log"     -- [max 16] tab 3: your deaths by players (not monsters), newest first
L.TAB_GUILD    = "Guild"         -- [max 16] tab 4 when only the guild is shared: the shared guild book

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "House Rules"     -- [max 24] the settings page (gear button)
L.HEAD_HELP  = "How it works"    -- [max 24] the help page ("?" button)

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Book"           -- [max 14] sheet with the book's own settings
L.SHEET_ALERT = "Alert"          -- [max 14] sheet with the alarm settings (sound, flash)

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "PUBLIC ENEMY No. 1"  -- [max 24] on the poster of rank 1
L.STAMP_REVENGE  = "REVENGE TAKEN"       -- [max 16] you killed that player back
L.STAMP_PARDONED = "PARDONED"            -- [max 16] the player was pardoned (no more alarm)
L.STAMP_SUSPECT  = "SUSPECT"             -- [max 16] involvement not proven (heuristic only)

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "PUBLIC ENEMY No. 1 SIGHTED"  -- [max 30] title when rank 1 is near
L.ALERT_SIGHTED         = "PUBLIC ENEMY SIGHTED"        -- [max 30] title for every other wanted player
L.ALERT_SIGHTED_SUSPECT = "SUSPECT SIGHTED"             -- [max 30] title for a suspect (not proven)
L.ALERT_TITLE_GUILD     = "GUILD ENEMY SIGHTED"         -- [max 30] title: killer from the guild book
L.ALERT_TITLE_FRIENDS   = "FRIENDS' KILLER SIGHTED"  -- [max 30] title: a killer from the friends' book (killed one of your friends)
L.ALERT_TITLE_HUNT      = "HIT LIST TARGET"             -- [max 30] title: target of the hit list
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "is under suspicion"
L.ALERT_LINE_KILLED         = "killed you {times}"
L.ALERT_LINE_KILLED_ASSISTED = "killed you {times}, assisted {assists}"  -- "assisted" = took part in killing YOU without the killing blow (not: helped you); {times}/{assists} = how often
L.ALERT_LINE_ASSISTED       = "assisted in your death {times}"
L.ALERT_LINE_MANUAL         = "is in the book by hand"
L.ALERT_LINE_LAST    = "{text}, last {time}"       -- {text} = the line so far, {time} = "2 days ago"
L.ALERT_LINE_IN      = "{text} in {zone}"          -- {zone} = zone or subzone name from the game
L.ALERT_LINE_REVENGE = "{text}. Revenge: {times}"  -- you killed them back {times}
L.ALERT_HINT_CLOSE  = "Right-click: close"                          -- [max 44] hint at the bottom, no name to target
L.ALERT_HINT_COMBAT = "Targeting only after combat"                 -- [max 44] hint while in combat
L.ALERT_HINT_TARGET = "Click: target  ·  Right-click: close"        -- [max 44] hint, normal case
L.ALERT_MORE = "+{count} more"           -- [max 14] bottom right: more alarms waiting; {count} = number
L.SAMPLE_ZONE = "Stranglethorn Vale"     -- test alarm (/dn test) without a real entry: the zone shown

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "is in the guild book"
L.GUILD_LINE_IN_FRIENDS = "is in the friends' book"
L.GUILD_LINE_LISTED_BY  = "is in the book of {names}"          -- {names} = "Anna, Bert and 2 more"
L.GUILD_LINE_KILLED_GUILD   = "killed guildmates {kills}×"     -- {kills} = number or "at least 20"
L.GUILD_LINE_KILLED_FRIENDS = "killed friends {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "killed guildmates and friends {kills}×"
L.GUILD_LINE_LAST = "{text}, last {name}"                      -- {name} = first name of the last victim
L.HUNT_LINE_BY       = "put on the hit list by {names}"  -- {names} = "Anna, Bert and 2 more"; often a single name
L.HUNT_LINE_RELEASED = "on the hit list"
L.HUNT_LINE_REASON   = "{text}: {reason}"                      -- {reason} = free text of the player, never translated

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"                               -- "3×": how often (kills, revenge)
L.TALLY_SUSPECT  = "under suspicion"               -- entry summary in lists
L.TALLY_MANUAL   = "added by hand"
L.TALLY_NONE     = "no deed yet"
L.TALLY_KILLED   = "killed you {times}"            -- {times} = "3×"
L.TALLY_ASSISTED = "assisted {times}"  -- "assisted" = took part in killing YOU without the killing blow (not: helped you); {times}/{assists} = how often
L.PLACE_UNKNOWN  = "unknown place"
L.GKILLS_CAP     = "at least {count}"              -- guild kills are capped: "at least 20"
L.NAMELIST_MORE  = "{names} and {count} more"      -- {names} = "Anna, Bert", {count} = the rest

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN      = "%m/%d %H:%M"      -- point in time, this year ("11/11 01:01")
L.TIME_FMT_WHEN_YEAR = "%m/%d/%Y %H:%M"   -- point in time, another year
L.TIME_FMT_DAY       = "%m/%d"            -- a day, from 7 days ago on (lists)
L.TIME_FMT_DAY_YEAR  = "%m/%d/%y"         -- a day of another year
L.TIME_NEVER   = "never"
L.TIME_JUST    = "just now"  -- a moment ago (under 60 s), not "exactly now"
L.TIME_MINUTES = "{count} min ago"        -- [max 14] {count} = minutes (1-59)
L.TIME_HOURS   = "{count} h ago"          -- [max 14] {count} = hours (1-23)
L.TIME_DAYS    = "{count} {count|day|days} ago"  -- [max 16] {count} = days (1-6)
L.MONEY_GOLD   = "{count}g"               -- bounty in gold
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Heard from {count} {count|guildmate|guildmates} with DeathNote." -- guild status; {count} = members
L.HEALTH_NOGUILD = "You are in no guild, nothing is shared."
L.HEALTH_OFF     = "Sharing is switched off."
L.HEALTH_SHORT_NOGUILD = "No guild"       -- [max 18] short status in the status line
L.HEALTH_SHORT_OFF     = "Sharing off"    -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Blocked"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Refused"        -- [max 18]
L.HEALTH_SHORT_HOLD    = "Waiting"        -- [max 18]
L.HEALTH_SHORT_ASKED   = "Asked"  -- [max 18] short status and button text: a sync was asked for (hello sent), answers may follow
L.HEALTH_SHORT_FAIL    = "Not working"    -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "No sound"          -- [max 16]
L.SOUND_RAIDWARNING = "Raid warning"      -- [max 16]
L.SOUND_BELL        = "Bell"              -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Heartbeat"         -- [max 16]
L.SOUND_FEATHER     = "Quill"             -- [max 16] soft scratch of a quill
L.SOUND_SIREN       = "Siren"             -- [max 16]
L.CHANNEL_MASTER    = "Master"            -- [max 16] the game's sound channels
L.CHANNEL_SFX       = "Effects"           -- [max 16]
L.CHANNEL_DIALOG    = "Dialog"            -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} is in the book now."            -- /dn add; {name} = "First Last" of the player
L.CHAT_REMOVED   = "{name} is struck from the book."       -- /dn del; {name} = "First Last" of the player
L.CHAT_SYNC_WAIT = "Just synced. Try again in {seconds} s." -- /dn sync too soon; {seconds} = whole seconds left

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "No names yet."         -- big line in the middle of the empty page
L.EMPTY_WANTED_SUB  = "Go outside for once."  -- small line under it, dry joke

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE   = "/dn  open/close the book"
L.HELP_ADD      = "/dn add <Name [Surname]>  write a killer into the book by hand"
L.HELP_DEL      = "/dn del <Name [Surname]>  strike a killer from the book"
L.HELP_QUIET    = "/dn quiet  alarm off/on"
L.HELP_TEST     = "/dn test  show a test alarm"
L.HELP_GUILD    = "/dn guild  guild book: status and which guildmates have DeathNote"
L.HELP_FRIENDS  = "/dn friends  friends' book: status and which friends have DeathNote"
L.HELP_SYNC     = "/dn sync  sync guild book and friends' book now"
L.HELP_HUNT     = "/dn hunt <Name [Surname]>  put on the hit list (no name: show the hit list)"
L.HELP_CALLOFF  = "/dn calloff <Name [Surname]>  call off your own hunt"
L.HELP_LANG     = "/dn lang <code>  language of the book (enUS, deDE, frFR ...), after /reload"
L.HELP_THEME = "/dn theme <name>  cover of the book, after /reload"  -- 1.3.0: /dn theme, the cover (theme) of the book; the ids stay English
L.HELP_PROBE    = "/dn probe  troubleshooting: what the game tells the book"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  troubleshooting, also test the combat log"
L.HELP_DEBUG    = "/dn debug  troubleshooting: log every death in detail (on/off)"
L.HELP_HELP     = "/dn help  this help"
L.HELP_SILENT_ZONES = "In dungeons, battlegrounds and arenas the book keeps quiet by itself."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "on"  -- state word in chat lines: "Sharing on"; it may end a sentence, so no abbreviation with a dot
L.WORD_OFF = "off"  -- state word, see WORD_ON (may end a sentence: no abbreviation with a dot)
L.CHAT_WHO_ADD  = "Who? /dn add <Name>"            -- /dn add without a name
L.CHAT_WHO_DEL  = "Who? /dn del <Name>"
L.CHAT_WHO_CALLOFF = "Who? /dn calloff <Name>"
L.CHAT_BAD_NAME = "Invalid name."
L.CHAT_NOT_IN_BOOK = "Not in the book: {name}"     -- {name} = what the player typed
L.CHAT_ALARM_ON  = "Alarm on."                     -- /dn quiet
L.CHAT_ALARM_OFF = "Alarm off."
L.CHAT_DEBUG = "Troubleshooting log {state}."      -- /dn debug; {state} = WORD_ON / WORD_OFF
L.CHAT_UNKNOWN_CMD = "Unknown command. Help: /dn help"
L.CHAT_GUILD_NOT_LOADED = "The guild book is not loaded."
L.CHAT_NO_GUILD = "You are in no guild (or the game does not know it yet)."
L.CHAT_GUILD_STATE = "Guild {guild}: sharing {share}, receiving {receive}."   -- {guild} = guild name; {share}/{receive} = on/off
L.CHAT_GUILD_BOOK = "Guild book: {enemies} killers ({listed} only added by hand), {deeds} {deeds|deed|deeds}; guildmates are involved with {foreign} of them. Share hand entries: {manual}."  -- /dn guild; {foreign} = killers in whose entry another char than yours takes part (as victim or as the one who added them); {manual} = WORD_ON / WORD_OFF
L.CHAT_STATE_OK   = "Status: {text}"               -- {text} = a sentence about sharing (HEALTH_* or SYNC_HEALTH_*)
L.CHAT_STATE_WARN = "Heads up: {text}"
L.CHAT_NO_MATES   = "No guildmate with DeathNote heard yet."
L.CHAT_HAVE_DN      = "Have DeathNote: {names}"                 -- {names} = "Anna 1.2.0, Bert 1.1.0"
L.CHAT_HAVE_DN_MORE = "Have DeathNote: {names} and {count} more"
L.CHAT_SYNC_ASKED = "Sync requested. Answers come in the next few seconds."
L.CHAT_SYNC_FAIL  = "Sync does not work: {reason}"            -- {reason} = a sentence from the status
L.CHAT_SYNC_FAIL_DEFAULT = "no guild or sharing is off."
L.CHAT_FRIENDS_NOT_LOADED = "The friends' book is not loaded."
L.CHAT_FRIENDS_STATE = "Friends: sharing {share}, {online} of {total} online."
L.CHAT_FRIENDS_BOOK  = "Friends' book: {enemies} killers ({listed} only added by hand), {deeds} {deeds|deed|deeds}."
L.CHAT_NO_FRIENDS    = "No friend with DeathNote heard yet."
L.CHAT_HUNT_NOT_LOADED = "The hit list is not loaded."
L.CHAT_HUNT_UNKNOWN = "Unknown: {name}. Use the surname too, as the name shows in the game."
L.CHAT_HUNT_CAP     = "Can't put on the hit list: at most {own} of your own calls and {targets} targets per list."
L.CHAT_HUNT_NOWHERE = "Can't put on the hit list right now: no guild, and sharing with friends is off."
L.CHAT_HUNT_BOTH    = "{name} is on the hit list, for guild and friends."
L.CHAT_HUNT_GUILD   = "{name} is on the hit list, for the guild."
L.CHAT_HUNT_FRIENDS = "{name} is on the hit list, for your friends."
L.CHAT_CALLED_OFF   = "Hunt on {name} called off."
L.CHAT_NO_OWN_CALL  = "You have no call of your own on {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Language now: {lang}. Change: /dn lang <code>"
L.CHAT_LANG_LIST    = "Codes: {codes}"
L.CHAT_LANG_BAD     = "Unknown language: {code}"
L.CHAT_LANG_SET     = "Language: {lang}."
L.CHAT_LANG_RELOAD  = "Language: {lang}. Takes effect after /reload."
L.CHAT_THEME_CURRENT = "Cover now: {theme}. Change: /dn theme <name>"  -- 1.3.0: /dn theme; {theme} = name of the cover and its id, e.g. "The Black Book (notebook)"
L.CHAT_THEME_LIST = "Covers: {themes}"  -- 1.3.0: /dn theme; {themes} = "The Black Book (notebook), ..."
L.CHAT_THEME_BAD = "Unknown cover: {name}"  -- 1.3.0: /dn theme with an unknown id; {name} = what the player typed
L.CHAT_THEME_SET = "Cover: {theme}."  -- 1.3.0: /dn theme <id>, already active
L.CHAT_THEME_RELOAD = "Cover: {theme}. Takes effect after /reload."  -- 1.3.0: /dn theme <id>, active after /reload (as CHAT_LANG_RELOAD)
L.THEME_NOTEBOOK = "The Black Book"  -- 1.3.0: name of the first cover (theme "notebook", the black book as it always was)

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "The book is ready. Whoever kills you in the open world is in it afterwards. Open it with /dn or the minimap button."
L.WELCOME_PLATES = "Enemy nameplates are off. Without them the alarm only sees your target."
L.WELCOME_SHARE = "Guild and friends who have DeathNote read along. Notes and suspicions stay with you."  -- chat, first start; "read along" = they see what the book shares

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK   = "IN THE BOOK:"       -- label: the player is in your own book
L.TIP_HUNT      = "HIT LIST:"          -- label: the player is on the hit list (then HUNT_LINE_BY)
L.TIP_GUILDBOOK = "GUILD BOOK:"        -- label: the player is in the guild book (then GUILD_LINE_KILLED_GUILD)
L.TIP_PARDONED  = "pardoned"
L.TIP_RANK      = "rank {rank}"        -- {rank} = 1, 2, 3 ...
L.TIP_REVENGE   = "revenge {times}"    -- {times} = "2×"
L.TIP_LISTED_BY = "in the book of {names}"   -- {names} = "Anna, Bert and 2 more"
L.TIP_NOTE      = "Note: {note}"       -- {note} = your own note, free text

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP          = "Click: open · Right-click: dismiss"   -- tooltip over a clickable message
L.BANNER_NEW          = "NEW ENTRY"            -- [max 24] first death by this killer
L.BANNER_NEW_LINE     = "is in the book now"   -- under the killer's name
L.BANNER_AGAIN        = "AGAIN"                -- [max 24] the killer got you again
L.BANNER_AGAIN_LINE   = "killed you again, {count} times now"   -- {count} = all kills by them (2 or more)
L.BANNER_SUSPECT      = "SUSPECT"              -- [max 24] not proven who it was
L.BANNER_SUSPECT_LINE = "is under suspicion, sort it out in the book"
L.BANNER_UNCLEAR      = "KILLER UNCLEAR"       -- [max 24] several candidates
L.BANNER_CANDIDATES   = "{count} {count|candidate|candidates}"  -- big line instead of a name
L.BANNER_UNCLEAR_LINE = "Click: pick the killer under Unsolved"
L.BANNER_REVENGE      = "PAYBACK"              -- [max 24] you killed one of your killers
L.BANNER_REVENGE_LINE = "Revenge taken ({count}×)"   -- {count} = revenge count
L.BANNER_GUILD        = "GUILD"                -- [max 24] a guildmate died (name of the guildmate below)
L.BANNER_FRIENDS      = "FRIENDS"              -- [max 24] a friend died
L.BANNER_KILLED_BY    = "was killed by {name}" -- {name} = killer; the zone follows after " · "
L.BANNER_HUNT         = "HIT LIST"             -- [max 24] a hit list target was taken down
L.BANNER_BAGGED       = "taken down by {name}, {time}"   -- {name} = first name of the hunter, {time} = "2 min ago"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF   = "Sharing is switched off (House Rules, sheet Guild)."
L.SYNC_FRIENDS_OFF = "Sharing with friends is off."
L.SYNC_NOBODY      = "No guild and no friends to share with."
L.SYNC_SHORT_NOBODY = "Nothing shared"            -- [max 18]
L.SYNC_PREFIX      = "The game allows no receiving. Logging in again helps."
L.SYNC_SHORT_PREFIX = "Can't receive"             -- [max 18]
L.SYNC_BLOCKED     = "The realm blocks sending. Pass it on with Back up book."
L.SYNC_SHORT_BLOCKED = "Realm blocks sending"     -- [max 22]
L.SYNC_FAILING     = "Sending fails right now, trying again."
L.SYNC_SHORT_FAILING = "Sending stalls"           -- [max 18]
L.SYNC_HOLD        = "Sending waits {wait}."      -- {wait} = one of SYNC_HOLD_*
L.SYNC_HOLD_INSTANCE = "until you leave the instance"
L.SYNC_HOLD_COMBAT   = "until you are out of combat"
L.SYNC_HOLD_LOCKDOWN = "until the chat is free again"
L.SYNC_HOLD_AGAIN    = "until it works again"
L.SYNC_HOLD_SHORT_INSTANCE = "Waiting: instance"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Waiting: combat"    -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Waiting: chat"      -- [max 18]
L.SYNC_QUIET       = "Sent, but no guildmate with DeathNote heard yet."
L.SYNC_READY       = "Ready. No guildmate with DeathNote heard yet."
L.SYNC_RUNNING     = "Running: {count} {count|guildmate|guildmates} with DeathNote."
L.SYNC_RUNNING_ALL = "Running: {count} with DeathNote in guild and friends."
L.FRIENDS_OFF      = "Sharing with friends is off (House Rules, sheet Guild)."
L.FRIENDS_BLOCKED  = "The realm blocks whispers. Friends get nothing."
L.FRIENDS_SHORT_BLOCKED = "Realm blocks whispers" -- [max 22]
L.FRIENDS_FAILING  = "Whispers fail right now, trying again."
L.FRIENDS_SHORT_FAILING = "Whispers stall"        -- [max 18]
L.FRIENDS_NONE_LISTED = "No friends on the friend list."
L.FRIENDS_NONE_ONLINE = "No friend online right now."
L.FRIENDS_SHORT_NONE_ONLINE = "No friend online"  -- [max 18]
L.FRIENDS_QUIET    = "Asked, but no friend with DeathNote heard yet."
L.FRIENDS_READY    = "Ready. No friend with DeathNote heard yet."
L.FRIENDS_HOLD     = "Sending to friends waits until it works again."
L.FRIENDS_RUNNING  = "Running: {count} {count|friend|friends} with DeathNote."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Taken over from the guild book (killed guildmates {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB      = "Database not loaded."
L.IMPORT_NO_TEXT    = "No text."
L.IMPORT_NO_HEADER  = "The first line is missing (it starts with {header}). Please copy the whole text."  -- {header} = "DEATHNOTE:1", never translated
L.IMPORT_NOT_EXPORT = "Not a DeathNote export (header line missing or wrong version)."
L.IMPORT_TOO_LONG   = "Too many lines (at most {count})."
L.IMPORT_BAD_KEY    = "Line {line}: invalid key."           -- {line} = line number
L.IMPORT_BAD_TIME   = "Line {line}: invalid time."
L.IMPORT_BROKEN     = "Line {line} is incomplete or broken (text cut off?). Nothing imported."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "yes"
L.WORD_NO  = "no"
L.PROBE_HEAD = "Probe: {apis}/{apisAll} interfaces present, {events}/{eventsAll} events registerable."
L.PROBE_MISSING = "Missing: {list}"                       -- {list} = API names
L.PROBE_NOT_REGISTERABLE = "Not registerable: {list}"     -- {list} = event names
L.PROBE_SOURCES = "Recap now: {recap} · Meter: {meter} · Combat log: {clog}"
L.PROBE_READABLE = "readable"
L.PROBE_DEAD = "dead"  -- /dn probe: the combat log gives nothing (that source is dead), not a person
L.PROBE_PLATES = "Enemy nameplates: {plates} · Open world: {open}"
L.PROBE_PLATES_OFF = "OFF (only target and mouseover spot hostile players)"
L.PROBE_TARGET = "Target: name={name} GUID={guid} class={class} hostile={enemy} targets me={me}"
L.PROBE_GUILD = "Guild: prefix {prefix} · sending {send} · last return value {result} · sent {sent}, received {received}, dropped {dropped}"
L.PROBE_REGISTERED = "registered"
L.PROBE_NOT_REGISTERED = "NOT registered ({result})"
L.PROBE_POSSIBLE = "possible"
L.PROBE_ABSENT = "missing"
L.PROBE_WAITS = " · waits: {why}"                         -- {why} = technical code
L.PROBE_LISTED = "Hand entries (M): sent {sent}, received {received}, dropped {dropped} · struck (X): sent {usent}, received {ureceived}, dropped {udropped}"
L.PROBE_GUILDBOOK = "Guild book: {text}"
L.PROBE_SAVED = "Saved in DeathNoteDB.probe (in the file after /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rank"  -- [max 14] sort by rank (worst first)
L.SORT_RECENT = "Newest"  -- [max 14] sort by the newest deed
L.SORT_NAME = "Name"  -- [max 14] sort by name
L.SORT_SEEN = "Seen"  -- [max 14] sort by last sighting
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Whoever kills you in the open world ends up here. All by itself."  -- tab Wanted, empty: third line explains what the book does
L.EMPTY_OPEN_HEAD = "Nothing unsolved."  -- tab Unsolved, empty
L.EMPTY_JOURNAL_HEAD = "Never died yet."  -- tab Death Log, empty
L.EMPTY_JOURNAL_SUB = "Respect. Or a lie."  -- under it, dry joke
L.EMPTY_NOGUILD_HEAD = "No guild."  -- fourth tab, you are in no guild
L.EMPTY_NOGUILD_SUB = "Dying alone works too."  -- under it, dry joke
L.EMPTY_GUILDOFF_HEAD = "The guild book is closed."  -- fourth tab, sharing with the guild is off
L.EMPTY_GUILDOFF_SUB = "Sharing is off. The House Rules know where."  -- under it
L.EMPTY_GUILDNIL_HEAD = "No word from the guild yet."  -- fourth tab, no guildmate with DeathNote heard yet
L.EMPTY_GUILDNIL_SUB = "Your book is shared as soon as a guildmate has DeathNote."  -- under it; "is shared" = sent to them (not: goes away)
L.EMPTY_GUILDQUIET_HEAD = "Nothing in the guild book yet."  -- fourth tab, guildmates heard, nothing shared yet
L.EMPTY_GUILDQUIET_SUB = "Your guildmates have had peace so far."  -- under it
L.EMPTY_FRIENDSOFF_HEAD = "The friends' book is closed."  -- fourth tab, source Friends, sharing with friends is off
L.EMPTY_FRIENDSOFF_SUB = "Sharing with friends is off. The House Rules know where."  -- under it
L.EMPTY_FRIENDSNIL_HEAD = "No friend with DeathNote heard yet."  -- fourth tab, source Friends, nobody heard
L.EMPTY_FRIENDSNIL_SUB = "Your book is shared as soon as a friend has DeathNote."  -- under it; "is shared" = sent to them (not: goes away)
L.EMPTY_FRIENDSQUIET_HEAD = "Nothing from your friends yet."  -- fourth tab, source Friends, nothing shared yet
L.EMPTY_FRIENDSQUIET_SUB = "Your friends have had peace so far."  -- under it
L.EMPTY_NOBODY_HEAD = "No guild, no friends."  -- fourth tab, neither a guild nor sharing with friends
L.EMPTY_NOBODY_SUB = "Dying alone works too."  -- under it, dry joke
L.EMPTY_NOBODY_HINT = "Once guildmates or friends from your friend list have DeathNote, this page shows what happens to them."  -- third line
L.EMPTY_SHAREDNIL_HEAD = "No one with DeathNote heard yet."  -- fourth tab, source All, nobody heard
L.EMPTY_SHAREDNIL_SUB = "Your book is shared as soon as guildmates or friends have DeathNote."  -- under it; "is shared" = sent to them (not: goes away)
L.EMPTY_SHAREDQUIET_HEAD = "Nothing here yet."  -- fourth tab, source All, nothing shared yet
L.EMPTY_SHAREDQUIET_SUB = "Guild and friends have had peace so far."  -- under it
L.EMPTY_HUNT_HEAD = "The hit list is empty."  -- view Hit List, empty
L.EMPTY_HUNT_SUB = "On the poster: Put on hit list."  -- under it; names the button on the poster (ACT_RELEASE), same words
L.EMPTY_HUNT_HINT = "Or in chat: /dn hunt Name Surname. Everyone in your guild and your friends see it."  -- third line; keep the command /dn hunt as it is
L.EMPTY_SEARCH_HEAD = "No match."  -- search found nothing
L.EMPTY_SEARCH_SUB = "Enter adds the name to the book."  -- under it (tab Wanted: Enter adds by hand)
L.EMPTY_SEARCHRO_HEAD = "No match."  -- search found nothing (tabs where Enter adds nothing)
L.EMPTY_SEARCHRO_SUB = "Sometimes a different spelling helps."  -- under it
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "THE BOOK"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_BOOK = "Whoever kills you in the open world gets written in by itself. A click on the message after your death opens the killer's page."  -- help paragraph, 232 px wide, wraps
L.MANUAL_WANTED_HEAD = "WANTED"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_WANTED = "Your killers, the worst first. A click shows the poster with deeds and note. Pardoned players stand struck through at the end."  -- help paragraph, 232 px wide, wraps
L.MANUAL_UNSOLVED_HEAD = "UNSOLVED"  -- [max 13] help label, capitals, letter-spaced
L.MANUAL_UNSOLVED = "When it was not clear who did it, the case waits here. A click on a name settles the killer."  -- help paragraph, 232 px wide, wraps
L.MANUAL_ALERT_HEAD = "ALERT"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_ALERT = "When a killer shows up as a nameplate, target or under the mouse, the book speaks up. A click targets them, in combat only afterwards."  -- help paragraph, 232 px wide, wraps
L.MANUAL_ADD_HEAD = "ADDING"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_ADD = "Type a name into the search field, Enter. Right-click a row: note revenge, pardon, strike."  -- help paragraph, 232 px wide, wraps
L.MANUAL_GUILD_HEAD = "GUILD"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_GUILD = "Guildmates and friends with DeathNote see your confirmed deaths and entries by hand. Poster or /dn hunt Name: put on the hit list. Click the bounty to post your own: a promise, settled among yourselves."  -- help paragraph, 232 px wide, wraps; "confirmed deaths" = deaths with a known killer (not: a certain death)
L.MANUAL_SHARE_HEAD = "PASS ON"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_SHARE = "House Rules, Back up book: a text to copy, for everyone without DeathNote."  -- help paragraph, 232 px wide, wraps
L.MANUAL_QUIET_HEAD = "QUIET"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_QUIET = "In dungeons and battlegrounds the alarm stays silent. Otherwise: middle-click the minimap button or /dn quiet."  -- help paragraph, 232 px wide, wraps
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Really strike {name} from the book?\nAll deeds and the note will be lost."  -- dialog; {name} = the player; \n = line break
L.CONFIRM_DELETE_OK = "Strike"  -- [max 14] dialog button
L.CONFIRM_GUILD_CLEAR = "Empty the guild book on this computer?\nIts hit list goes too, your own calls stay.\nYour own book stays as it is."  -- dialog; \n = line break
L.CONFIRM_GUILD_CLEAR_OK = "Empty"  -- [max 14] dialog button
L.CONFIRM_CANCEL = "Cancel"  -- [max 14] dialog button; also in the dialog CONFIRM_CALLOFF_ALL, so it must differ from "call off"
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} GOLD"  -- [max 14] bounty on the poster, big; {count} = gold pieces with thousands separator
L.BOUNTY_SILVER = "{count} SILVER"  -- [max 14] bounty under 1 gold; {count} = silver pieces
L.THOUSANDS_SEP = ","  -- thousands separator in the bounty (2.875 / 2,875); a single sign, a space is fine too
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Confirm"  -- [max 19] button: suspect: make it a sure killer
L.ACT_DISMISS = "Dismiss"  -- [max 19] button: suspect: drop the suspicion
L.ACT_HUNT_AGAIN = "Hunt again"  -- [max 19] button: pardoned: back to Wanted
L.ACT_REVENGE = "Note revenge"  -- [max 19] button: count one revenge (you killed them)
L.ACT_PARDON = "Pardon"  -- [max 19] button: pardon: no more alarm
L.ACT_STRIKE = "Strike"  -- [max 19] button: strike from the book (asks first)
L.ACT_OPEN_OWN = "Open in book"  -- [max 19] button: guild entry that is in your own book too
L.ACT_ADOPT = "Into my book"  -- [max 19] button: copy a guild entry into your own book
L.ACT_CALLOFF = "Call off the hunt"  -- [max 19] button: take back your own hit list call
L.ACT_RELEASE = "Put on hit list"  -- [max 19] button: put on the hit list (opens the sheet REL_HEAD with target and reason); the same action as REL_HEAD, REL_GO and /dn hunt, use one wording for all
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "seen {time}"  -- sub line; {time} = "2 days ago"
L.ROW_NOT_SEEN = "not sighted yet"  -- sub line
L.ROW_PARDONED = "pardoned"  -- sub line of a pardoned player
L.ROW_SUSPECT = "Suspect"  -- sub line of a suspect
L.MARK_REVENGE = "REVENGE {times}"  -- [max 16] mark at the right; {times} = "2×"
L.ROW_KILLER_UNCLEAR = "Killer unclear"  -- name line of a death without a clear killer
L.MARK_CANDIDATES = "{count} {count|CANDIDATE|CANDIDATES}"  -- [max 16] mark at the right; {count} = number of candidates
L.MARK_SUSPECT = "SUSPECT"  -- [max 16] mark at the right: killer only suspected
L.ROW_NO_PLAYER = "No player"  -- Death Log name line: died to a monster or the world
L.ROW_UNCLEAR = "Unclear how"  -- Death Log name line: no idea what happened
L.MARK_NOT_COUNTED = "DOESN'T COUNT"  -- [max 16] mark at the right: death not counted (duel, instance)
L.ROW_LISTED_BY = "added by {names}"  -- guild book row; {names} = "Anna, Bert and 2 more"; often a single name
L.ROW_GKILLED = "killed {kills}×"  -- guild book row; {kills} = number or "at least 20"
L.ROW_VICTIMS = "{count} {count|victim|victims}"  -- guild book row; {count} = how many different victims
L.ROW_LAST = "last {text}"  -- sub line; {text} is either the first name of the last victim or a time ("2 days ago"): choose a word that fits both
L.MARK_IN_BOOK = "IN BOOK"  -- [max 16] mark at the right: also in your own book
L.MEMBER_KILLERS = "{count} {count|killer|killers}"  -- [max 14] By guildmate, head row, right: number of killers
L.MEMBER_DEATHS = "{count} {count|death|deaths}"  -- [max 12] By guildmate, head row, right: number of deaths
L.MEMBER_LISTED = "{count} by hand"  -- [max 14] By guildmate, head row, right: entries added by hand
L.MEMBER_ME = "what the others see of you"  -- By guildmate: your own head row
L.MEMBER_NOTHING = "nothing shared yet"  -- By guildmate: head row of someone without entries
L.MEMBER_LAST_DIED = "last died {time}"  -- By guildmate: {time} = "2 days ago"
L.MARK_YOU = "you"  -- [max 16] mark at the right of your own head row (lower case)
L.MARK_FRIEND = "FRIEND"  -- [max 16] mark at the right: a friend from the friend list
L.MARK_BOTH = "GUILDMATE, FRIEND"  -- [max 20] mark at the right: both at once
L.MARK_TAKEN_DOWN = "TAKEN DOWN {times}"  -- [max 18] Hit List row, right: killed by one of you; {times} = "2×"
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "DEAD OR ALIVE"  -- [max 24] line under WANTED (POSTER_HEAD) on the poster; may stay English like WANTED
L.BOOK_TITLE = "DeathNote"  -- [max 10] 1.3.0: title on the cover of the book; a theme may set its own (theme word)
L.POSTER_HEAD = "WANTED"  -- [max 7] 1.3.0: head of the poster, in no language translated; a theme may set its own (theme word)
L.POSTER_DEEDS = "DEEDS"  -- [max 14] label above the deeds list
L.POSTER_NOTE = "NOTE"  -- [max 8] label left of the note field (the field takes the rest of the line)
L.POSTER_BOUNTY = "BOUNTY"  -- [max 12] label above the bounty
L.ROLE_ASSIST = "assisted"  -- [max 14] right of a deed line: took part in killing you, no killing blow (not: helped you)
L.ROLE_SUSPECT = "suspect"  -- [max 14] right of a deed line: only suspected
L.POSTER_LEVEL = "Level {level}"  -- fact line on the poster, before the class: "Level 36 · Mage"
L.POSTER_GUILD = "Guild: {guild}"  -- fact line; {guild} = the player's guild name
L.POSTER_LAST_SEEN = "Last seen {time}"  -- fact line; {time} = "2 days ago"
L.POSTER_NOT_SEEN = "Not sighted yet"  -- fact line
L.POSTER_ONLY_SUSPECT = "Only suspected, no proven deed."  -- deeds list, empty, suspect
L.POSTER_NO_DEEDS = "No deeds noted."  -- deeds list, empty
L.TIP_LISTED_AT = "Added {time}"  -- tooltip of an entry by hand; {time} = date and time
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Cause of death: {spell}"  -- deed tooltip; {spell} = spell name from the game
L.TIP_VICTIM = "Victim: {name}"  -- deed tooltip and death file; {name} = character
L.TIP_VICTIM_LEVEL = "Victim: {name} (level {level})"  -- as above with the level
L.TIP_KILLER_LEVEL = "Killer's level: {level}"  -- deed tooltip
L.TIP_ASSISTS = "Assisted: {names}"  -- deed tooltip; who else took part in killing you (not: who helped you); {names} = list of names
L.TIP_ROLE_ASSIST = "Assisted, did not land the killing blow."  -- deed tooltip: took part in killing you, but not the killing blow (not: helped you)
L.TIP_ROLE_SUSPECT = "Only suspected, not proven."  -- deed tooltip
L.MORE_LINE = "… and {count} more"  -- last line of a cut list (deeds, candidates, assists, also members); {count} = how many more; use a neutral word where your language counts with measure words
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "GUILD BOOK"  -- [max 24] line under WANTED on a guild book poster
L.POSTER_IN_BOOK_OF = "In the book of: {names}"  -- fact line; {names} = "Anna, Bert and 2 more"
L.POSTER_SEEN = "Seen {time}"  -- fact line; {time} = "2 h ago"
L.POSTER_SEEN_BY = "Seen {time} by {name}"  -- fact line; {name} = first name of who saw them
L.TIP_IN_BOOK_OF = "In the book of"  -- tooltip head over the full list of names
L.POSTER_REMARK = "REMARK"  -- [max 12] label above the bounty place, entry by hand
L.POSTER_BY_HAND = "ADDED BY HAND"  -- [max 22] in the bounty place, Morpheus 19
L.POSTER_VICTIMS = "VICTIMS"  -- [max 12] label above the victim count; also the label before the victim names
L.POSTER_LISTED = "ADDED"  -- [max 14] label above the list of who added the entry by hand
L.POSTER_LISTED_EMPTY = "Added by hand."  -- list empty
L.POSTER_NO_DEEDS_SENT = "No deeds passed on."  -- guild poster, no deeds came along
L.POSTER_NONE_KNOWN = "none known"  -- victims field, entry by hand
L.POSTER_NO_NAMES = "no names passed on"  -- victims field
L.TIP_VICTIMS = "Victims"  -- tooltip head over all victims
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Called {time}"  -- tooltip of one hit list call; {time} = date and time
L.HUNT_REASON = "Reason: {reason}"  -- {reason} = free text of the player, never translated
L.POSTER_HUNTLIST = "HIT LIST"  -- [max 24] line under WANTED on a hit list poster
L.POSTER_RELEASED_N = "put on the hit list {times}"  -- line under the name; {times} = "3×"
L.POSTER_RELEASED_BY = "Called by {names}"  -- fact line; {names} = "Anna, Bert and 1 more"; often a single name
L.POSTER_TAKEN_DOWN = "TAKEN DOWN"  -- [max 12] label above the kill count of a hit list target
L.POSTER_NOT_YET = "NOT YET"  -- [max 18] in the bounty place: nobody took them down yet
L.POSTER_CALLS = "CALLED"  -- [max 14] label above the list of calls (who, when, reason)
L.POSTER_NOBODY_LEFT = "Nobody anymore."  -- list of calls, empty
L.POSTER_LAST = "LAST"  -- [max 13] label before the last kill line
L.POSTER_TAKEN_BY = "taken down by {name}, {time}"  -- {name} = first name, {time} = "2 days ago"
L.POSTER_TAKEN_NOBODY = "not taken down by anyone yet"  -- line after LAST
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Death"  -- [max 20] big head of a death file
L.CASE_ASSISTS = "ASSISTED"  -- [max 24] label above the players who took part in killing you without the killing blow (not: helpers)
L.CASE_PICK = "SETTLE THE KILLER"  -- [max 24] label above the candidate buttons
L.CASE_NOT_COUNTED = "Doesn't count (instance, battleground or duel)"  -- fact line
L.CASE_KILLER = "KILLER"  -- [max 24] label above the killer's name
L.CASE_KILLER_SUSPECT = "KILLER (SUSPECT)"  -- [max 24] label above the killer's name, only suspected
L.CASE_CLICK_NAME = "Click the name to open their poster."  -- note under the killer
L.CASE_GONE = "No longer in the book."  -- note under the killer: entry was struck
L.CASE_KILLER_UNCLEAR = "KILLER UNCLEAR"  -- [max 24] label
L.CASE_SEVERAL = "Several could have done it. Whose name goes in the book?"  -- note
L.CASE_NOBODY = "Nobody could have done it."  -- note
L.CASE_HOW = "WHAT HAPPENED"  -- [max 24] label
L.CASE_PVE = "A monster or the world itself. No case for the book."  -- note
L.CASE_UNCLEAR = "Unclear"  -- big line where the killer would be
L.CASE_DARK = "Forensics are groping in the dark."  -- note, dry joke
L.TIP_MORE_CANDIDATES = "More candidates"  -- tooltip head
L.CASE_SOURCE_SUSPECT = "Suspect: had you targeted shortly before you died."  -- bottom line of the file
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip line on killers"  -- [max 44] check box on the House Rules: an extra line in the game tooltip when you hover a killer
L.OPT_MINIMAP = "Show minimap button"  -- [max 44] check box on the House Rules
L.OPT_ALERT = "Alarm when a killer shows up"  -- [max 44] check box on the House Rules
L.OPT_FLASH = "Flash the screen edge red"  -- [max 44] check box on the House Rules
L.OPT_SUSPECTS = "Report suspects too"  -- [max 44] check box on the House Rules
L.OPT_DEATHMSG = "Message after a PvP death"  -- [max 44] check box on the House Rules
L.OPT_G_SHARE = "Share my deaths"  -- [max 44] check box on the House Rules
L.OPT_G_SHAREMANUAL = "Share entries added by hand"  -- [max 44] check box on the House Rules
L.OPT_G_RECEIVE = "Receive the guild book"  -- [max 44] check box on the House Rules
L.OPT_G_ALERT = "Warn about killers from the guild book"  -- [max 44] check box on the House Rules
L.OPT_G_ALERTLISTED = "Also warn about entries added by hand"  -- [max 44] check box on the House Rules
L.OPT_G_ANNOUNCE = "Report when a guildmate gets killed"  -- [max 44] check box on the House Rules
L.OPT_G_SIGHTINGS = "Share sightings"  -- [max 44] check box on the House Rules
L.OPT_F_SHARE = "Share with the guild"  -- [max 44] check box on the House Rules
L.OPT_F_FRIENDS = "Share with friends"  -- [max 44] check box on the House Rules
L.OPT_F_ALERT = "Warn about killers in the shared books"  -- [max 44] check box on the House Rules: alarm for killers from the guild book and the friends' book
L.OPT_F_ALERTHUNT = "Warn about hit list targets"  -- [max 44] check box on the House Rules
L.OPT_F_ANNOUNCE = "Report when guildmates or friends die"  -- [max 44] check box on the House Rules
L.OPT_F_SIGHTINGS = "Share sightings with guild and friends"  -- [max 44] check box on the House Rules
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guild"  -- [max 14] word tab: sheet with the guild and friends settings
L.SET_BOOK_SIZE = "Book size"  -- [max 34] stepper label (value: "100 %")
L.SET_LANGUAGE = "Language"  -- [max 16] stepper label; the values are the languages in their own names
L.SET_LANG_AUTO = "Automatic"  -- [max 16] first value of the language stepper and /dn lang auto: no own choice, the game's language (English when DeathNote lacks it)
L.SET_LANG_RELOAD_HINT = "Takes effect after a reload."  -- [max 28] hint under the language when a change waits for /reload
L.SET_LANG_RELOAD = "Reload now"  -- [max 22] button next to it (reloads the interface)
L.SET_SEC_SHARE = "PASS ON"  -- [max 24] section label
L.IO_EXPORT = "Back up book"  -- [max 17] button and page head
L.IO_IMPORT = "Import book"  -- [max 17] button and page head
L.SET_HINT_BOOK = "Back up gives you the book as text: to keep, or to pass on to people outside the guild. Import merges and overwrites nothing."  -- hint at the bottom of the sheet Book, wraps
L.SET_SEC_SOUND = "SOUND"  -- [max 24] section label
L.SET_SOUND = "Sound"  -- [max 22] stepper label (value: sound name)
L.SET_VOLUME = "Volume"  -- [max 22] stepper label (value: five bars)
L.SET_CHANNEL = "Channel"  -- [max 12] label before the three sound channel words
L.SET_SEC_THRESHOLD = "THRESHOLD"  -- [max 24] section label
L.SET_COOLDOWN = "Cooldown per killer"  -- [max 34] stepper label (value: "90 s")
L.SET_MINKILLS = "Alarm at this many deaths by them"  -- [max 34] stepper label (value: a number); from that many deaths on
L.SET_ALERT_SIZE = "Alarm size"  -- [max 34] stepper label (value: "100 %")
L.SET_TEST_ALERT = "Test alarm"  -- [max 17] button
L.SET_G_MINKILLS = "Guild warning at this many deaths"  -- [max 34] stepper label (value: a number); from that many deaths on
L.SET_F_MINKILLS = "Warning at this many deaths"  -- [max 34] stepper label with friends (value: a number); from that many deaths on
L.SET_SEC_STATUS = "STATUS"  -- [max 24] section label
L.SET_SEC_SHARING = "SHARING"  -- [max 24] section label, House Rules sheet Guild: the sharing switches (with guild, with friends, sightings)
L.SET_SEC_WARN = "ALERTS"  -- [max 24] section label, House Rules sheet Guild: the alarm switches
L.SET_MORE = "More"  -- [max 12] word tab at the foot of the House Rules sheet Guild: shows the remaining, rarely needed settings
L.SET_GUILD_CLEAR = "Empty guild book"  -- [max 26] button
L.SET_HINT_GUILD = "Only your own guild gets anything. What comes from there stays apart from your book until you take it over yourself."  -- hint at the bottom of the sheet Guild, wraps
L.SET_HINT_FRIENDS = "Only guild and friends with DeathNote get anything."  -- hint at the bottom of the sheet Guild with friends
L.BTN_BACK = "Back"  -- [max 17] button at the bottom of the side pages
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sync"  -- [max 14] button bottom left: ask guild and friends for their books now
L.SYNC_AGAIN_IN = "again in {seconds} s"  -- [max 16] same button after a too early click; {seconds} = seconds left
L.TIP_FRIENDS = "Friends"  -- tooltip head over the friends with DeathNote
L.TIP_GUILD_NAME = "Guild {guild}"  -- tooltip head; {guild} = guild name
L.TIP_MATES_WITH = "Guildmates with DeathNote:"  -- tooltip, above the list of guildmates
L.TIP_NO_MATE = "No guildmate with DeathNote heard yet."  -- tooltip
L.TIP_FRIENDS_WITH = "Friends with DeathNote:"  -- tooltip, above the list of friends
L.TIP_SHARED = "Shared: your confirmed deaths, entries added by hand and your hit list calls."  -- tooltip, wraps; "confirmed deaths" = deaths with a known killer; "call" = a target put on the hit list (noun)
L.TIP_NOT_SHARED = "Not shared: notes, suspicions, pardoned players, imported entries."  -- tooltip, wraps
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Import"  -- [max 17] button on the import page
L.IO_DONE = "Imported: {new} new, {merged} merged."  -- result line; {new}, {merged} = numbers of entries
L.IO_FAILED = "That didn't work."  -- result line when the import failed without a reason
L.IO_SMALL = "Small only"  -- [max 17] button: show the small version (names and counts)
L.IO_ALL = "Show all"  -- [max 17] button: show the whole book with deeds
L.IO_MSG_FULL = "Whole book with deeds ({size})."  -- {size} = "42 KB"
L.IO_MSG_SHORT = "Only names and counts ({size}). With deeds: {full}."  -- {size}, {full} = "42 KB"
L.IO_MSG_BIG = "Big book ({size}): selecting and copying take a moment."  -- {size} = "120 KB"
L.IO_HELP_EXPORT = "The text is selected: Ctrl+C copies it. Keep it or pass it on to friends."  -- help line under the head; name the copy keys of your keyboard
L.IO_HELP_IMPORT = "Paste a backed up text with Ctrl+V, then Import. Nothing is overwritten."  -- help line under the head
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Everyone in your guild and your friends with DeathNote see the reason."  -- hint under the reason field
L.REL_HINT_GUILD = "Everyone in your guild with DeathNote sees the reason."  -- hint under the reason field
L.REL_HINT_FRIENDS = "Your friends with DeathNote see the reason."  -- hint under the reason field
L.REL_HEAD = "Put on the hit list"  -- [max 24] page head of the sheet the button ACT_RELEASE opens; same wording as ACT_RELEASE
L.REL_FOR = "FOR"  -- [max 6] label before the three choices: for whom (who sees the call), not the target
L.REL_REASON = "REASON"  -- [max 8] label before the reason field (the field takes the rest)
L.REL_HINT2 = "Your note stays with you. Only you can call off your own call."  -- second hint
L.REL_GO = "Put on hit list"  -- [max 17] button on that sheet: put the target on the hit list (same action and wording as ACT_RELEASE)
L.REL_NONE = "No guild, and sharing with friends is off."  -- message when nobody could see the call
L.REL_CAP = "At most {own} calls of your own and {max} targets per list."  -- {own} = 10, {max} = 100
L.REL_FAILED = "Can't put them on the hit list right now."  -- message
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7] stepper value: seconds
L.SET_HINT_SILENT = "No sound: the alarm only shows itself."  -- hint at the bottom of the sheet Alert
L.SET_HINT_BUILTIN = "This sound's volume follows the channel in the game options."  -- hint
L.SET_HINT_LEVELS = "Five levels from soft to loud. The channel slider in the game options applies on top."  -- hint
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guild & Friends"  -- [max 18] tab 4 when friends are shared too; also the first choice on the sheet Put on the hit list
L.TIP_HELP_BUTTON = "How the book works"  -- tooltip of the "?" button
L.VIEW_HUNT = "Hit List"  -- [max 13] word toggle at the top of the fourth tab (first view)
L.VIEW_BY_KILLER = "By killer"  -- [max 13] word toggle: list by killer
L.VIEW_BY_MATE = "By guildmate"  -- [max 13] word toggle: list by guildmate (and friend)
L.SRC_ALL = "All"  -- [max 12] word toggle bottom left of the fourth tab: guild and friends
L.SRC_GUILD = "Guild"  -- [max 12] word toggle: only the guild; also a choice on the sheet Put on the hit list
L.SRC_FRIENDS = "Friends"  -- [max 12] word toggle: only friends; also a choice on the sheet Put on the hit list
L.SORT_HIDE_PARDONED = "Hide pardoned"  -- [max 24] sort menu entry
L.SORT_SHOW_PARDONED = "Show pardoned"  -- [max 24] sort menu entry
L.SEARCH_ADD = "Search or add …"  -- [max 26] placeholder in the search field, tab Wanted (Enter adds)
L.SEARCH_SHORT = "Search …"  -- [max 10] placeholder in a narrow search field
L.SEARCH_KILLER = "Find killer …"  -- [max 15] placeholder, fourth tab without views
L.SEARCH_JOURNAL = "Killer or place …"  -- [max 26] placeholder, Death Log
L.TIP_COLLAPSE_ALL = "Collapse all"  -- tooltip of the double triangle (By guildmate)
L.TIP_EXPAND_ALL = "Expand all"  -- tooltip of the double triangle (By guildmate)
L.STATUS_NO_PLATES = "Enemy nameplates are off: the alarm only sees target and mouse."  -- status line at the bottom of the left page, up to two lines
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} wanted"  -- minimap tooltip; {count} = number of wanted players
L.MM_UNSOLVED = "{count} unsolved"  -- minimap tooltip; {count} = open cases and suspects
L.MM_ALERT_OFF = "Alarm is off (middle-click)"  -- minimap tooltip, red
L.MM_CLICK = "Click: book · Right-click: House Rules"  -- minimap tooltip
L.MM_MIDDLE = "Middle-click: alarm on/off"  -- minimap tooltip
L.MM_DRAG = "Drag: move along the minimap edge"  -- minimap tooltip
L.MM_CHAT_ALERT_ON = "Alarm on."  -- chat line after a middle-click on the minimap button
L.MM_CHAT_ALERT_OFF = "Alarm off."  -- chat line after a middle-click on the minimap button
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "GUILD ENEMY No. 1"  -- [max 25] stamp on the guild book poster of rank 1
L.STAMP_HUNT = "OPEN SEASON"  -- [max 20] stamp on a hit list target's poster
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} posed as your friend {friend}: refused."  -- friends status line (one line on the House Rules, full in the tooltip); {name} = the stranger's full name, {friend} = the friend's name on your list
L.FRIENDS_SHORT_IMPOSTOR = "Stranger refused"  -- [max 22] short status: a second full name with a friend's first name was refused
L.ALERT_LEVEL = "Level {level}"  -- [max 12] alarm popup, at the front of the text line under the name: level seen just now; {level} = number
L.ALERT_LEVEL_LAST = "last level {level}"  -- [max 20] alarm popup, at the front of the text line under the name: no live level, the one stored last; {level} = number
L.ALERT_LEVEL_UNKNOWN = "Level ??"  -- [max 12] alarm popup, at the front of the text line under the name: the game shows a skull (far above you)
L.ALERT_LINE_HUNT = "{text} · on the hit list ({names})"  -- alarm popup for your own wanted player who is also on the hit list; {text} = the line so far, {names} = who put him on it
L.BANNER_NEW_HUNTS = "{count} new {count|target|targets}"  -- [max 24] message: several targets put on the hit list by others at once; {count} = number
L.BANNER_NEW_HUNTS_LINE = "new on the hit list"  -- message, line under BANNER_NEW_HUNTS
L.OPT_F_ANNOUNCEHUNT = "Report hit list news: new, taken down"  -- [max 44] check box on the House Rules: message when others put a target on the hit list or one is taken down
L.SET_HUNT_EXPIRE = "Calls last"  -- [max 30] House Rules, sheet Guild: how long calls (own and received) stay on the hit list; read together with its value: "Calls last: forever" / "Calls last: 30 days"
L.SET_EXPIRE_NEVER = "forever"  -- [max 8] value of SET_HUNT_EXPIRE: calls never expire (default)
L.SET_EXPIRE_DAYS = "{count} {count|day|days}"  -- [max 10] value of SET_HUNT_EXPIRE; {count} = 30, 90 or 180
L.SET_FRIENDS_CLEAR = "Empty friends' book"  -- [max 26] button next to SET_GUILD_CLEAR
L.CONFIRM_FRIENDS_CLEAR = "Empty the friends' book on this computer?\nIts hit list goes too, your own calls stay."  -- dialog; \n = line break
L.CONFIRM_CALLOFF_ALL = "Call off all your calls on the hit list?\nGuild and friends hear it bit by bit."  -- dialog; \n = line break
L.CONFIRM_CALLOFF_ALL_OK = "Call off all"  -- [max 14] dialog button
L.ACT_CALLOFF_ALL = "Call off all mine"  -- [max 24] menu of the hit list (sort button): take back all your own calls
L.ACT_HUNT_HIDE = "Hide for me"  -- [max 19] poster word and row menu on the hit list: no alarm for this target, pale at the end of the list, nothing is sent
L.ACT_HUNT_SHOW = "Show again"  -- [max 19] undoes ACT_HUNT_HIDE
L.HUNT_ROW_HIDDEN = "hidden for you"  -- hit list row, second line, first: the target is hidden for you
L.HUNT_ROW_CALLS = "{count} {count|call|calls}: {names}"  -- hit list row, second line, and its tooltip; "call" = one player's putting a target on the hit list (noun, not a phone call); {count} = number of calls, {names} = "Anna, Bert and 1 more", often a single name
L.POSTER_ON_HUNTLIST = "On the hit list ({names})"  -- fact line on your own poster when the player is pardoned, a suspect or rank 1 and on the hit list; {names} = who put him on it
L.REL_SELF = "You can't put yourself on the hit list."  -- message on the sheet and in the chat
L.REL_MATE = "That is one of yours (guild or friends with DeathNote)."  -- message on the sheet and in the chat: guildmates and friends with DeathNote can't be put on the hit list
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Who is your friend {friend}: {a} or {b}? Please choose."  -- friends status line (one line on the House Rules, full in the tooltip); two players with the first name of a friend on your list (listed without surname) claim to be him; {friend} = the name on your list, {a} and {b} = the two full names
L.FRIENDS_SHORT_CONFLICT = "Friend unclear"  -- [max 22] short status for FRIENDS_CONFLICT
L.CHAT_FRIENDS_CONFLICT = "Two players claim to be your friend {friend}: {a} and {b}. Until you choose, the book takes nothing from either. Guild & Friends, view By guildmate: right-click the name."  -- chat, once per case; {friend} = the name on your friend list, {a} and {b} = the two full names
L.MEMBER_CONFLICT = "Right-click: is this your friend?"  -- [max 40] By guildmate: second line of a name in FRIENDS_CONFLICT
L.ACT_TIE_MINE = "My friend: {name}"  -- [max 24] row menu By guildmate: this full name is my friend; {name} = full name
L.ACT_TIE_LOOSE = "Unlink name"  -- [max 14] row menu By guildmate and dialog button: the friend list entry forgets this full name, the next message under the first name links anew
L.CONFIRM_TIE_LOOSE = "Unlink {name} from your friend list?\nWhat this name brought into the friends' book is deleted; the next message under this first name links anew."  -- dialog; {name} = full name; \n = line break
L.CHAT_FRIENDS_TIES = "Linked full names (* = first contact, not proven yet): {list}"  -- chat, /dn friends; {list} = "Berta = Berta Senf, Carla = Carla Klee*"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Name [Surname]> <gold>  post your own bounty (no gold: take it back)"  -- help line (/dn help); bounty = an amount of gold the player promises for the killer's death
L.CHAT_WHO_BOUNTY = "On whom? /dn bounty <Name> <gold>"  -- chat: /dn bounty without a name
L.CHAT_BOUNTY_SET = "{name}: you posted a bounty of {gold} gold. Guild and friends with DeathNote see it."  -- chat: own bounty set; {name} = the target, {gold} = whole gold pieces (number)
L.CHAT_BOUNTY_OFF = "{name}: your bounty is taken back."  -- chat: own bounty taken back; {name} = the target
L.CHAT_BOUNTY_NONE = "You have no bounty of your own on {name}."  -- chat: nothing to take back; {name} = what the player typed or the target
L.CHAT_BOUNTY_BAD = "Bounty: a whole number of gold, 1 to 99999 (0 takes it back)."  -- chat: the amount is no whole number in range
L.CHAT_BOUNTY_CAP = "No bounty: at most {count} of your own."  -- chat: too many own bounties; {count} = the limit (20)
L.CHAT_BOUNTY_OURS = "No bounty on yourself or your own people (guild or friends with DeathNote)."  -- chat: no bounty on an own char, guildmates or friends with DeathNote (like REL_MATE)
L.ACT_BOUNTY = "Post a bounty"  -- [max 24] row menu and right-click on the poster: type in your own bounty
L.ACT_UNDO = "Undo"  -- [max 19] poster button for a few seconds after ACT_REVENGE: takes exactly that revenge back
L.ACT_REVENGE_TAKE = "Take back one revenge"  -- [max 24] row menu: take back one revenge you noted by hand (the book's own stay)
L.POSTER_BOUNTY_MINE = "{gold}, posted by you"  -- fact line on the poster; {gold} = "500g" (MONEY_GOLD); the only bounty is yours
L.POSTER_BOUNTY_BY = "{gold}, posted by {name}"  -- fact line on the poster; {gold} = "500g", {name} = first name of whoever posted it
L.POSTER_BOUNTY_MANY = "Bounty {gold}: {names}"  -- fact line on the poster, several bounties; {gold} = the sum, {names} = NAMES_PLUS: "Anna +2" (all with their amounts in the tooltip)
L.POSTER_AVENGED = "Avenged by {names}"  -- fact line on the poster: guildmates or friends killed this killer for others; {names} = "Anna 2×" or NAMES_PLUS "Anna +2" (all with their counts in the tooltip)
L.ROW_AVENGED = "avenged {times}"  -- guild/friends book row, second line: how often guildmates or friends killed him for others; {times} = "3×"
L.BOUNTY_TIP_HEAD = "Your own bounty, in gold"  -- tooltip title at the input field on the poster
L.BOUNTY_TIP_RULES = "A whole number, 1 to 99999. Empty or 0: back to the book's value. Enter sets, Esc cancels."  -- tooltip at the input field: the rules (Enter, Esc are key names)
L.BOUNTY_TIP_PROMISE = "Guild and friends with DeathNote see it. A promise only: you settle it among yourselves."  -- tooltip at the input field: who sees it, the addon pays nothing
L.BOUNTY_TIP_CLICK = "Click: post your own bounty"  -- tooltip on the bounty of the poster (last line)
L.CHAT_AVENGED = "{name} took down {killer} for you."  -- chat with the short revenge sound: a guildmate or friend killed a killer of yours; {name} = his first name, {killer} = the killer
L.NAMES_PLUS = "{name} +{count}"  -- fact line on the poster: the first name and how many more (all of them are in the tooltip); {name} = first name (maybe with "2×"), {count} = how many more. Keep it this short
L.CHAT_BOUNTY_SET_ALONE = "{name}: you posted a bounty of {gold} gold."  -- chat: own bounty set while nobody can see it (no guild, no friends with DeathNote); first sentence of CHAT_BOUNTY_SET
L.CHAT_BOUNTY_UNKNOWN = "{name} is in none of your books. A bounty goes only on a name from a book, as the game shows it: first name and surname."  -- chat: /dn bounty on a name that is in no book (typo); {name} = what the player typed
L.CHAT_BOUNTY_LIST = "Your bounties ({count} of {max}): {list}"  -- chat: /dn bounty without anything: the own bounties of this char; {count} = how many, {max} = the limit (20), {list} = "Grimm Bart 500g, Fies Ling 50g"
L.CHAT_BOUNTY_LIST_NONE = "You have posted no bounty."  -- chat: /dn bounty without anything and no own bounty (the next line shows how to post one)
-- <<< BOOK
end)
