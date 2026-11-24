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
-- Words that never change: Revenge Book (the name, 1.5.0), WANTED, the /dn commands. Class, race and zone names come from
-- the game. Tone: dry, a little grim, a notebook full of enemies; speak to the player informally.
--
-- TOC-Notes: World PvP revenge book: remembers who killed you and warns you when they are near.

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
L.GUILD_HEARD    = "Heard from {count} {count|guildmate|guildmates} with Revenge Book." -- guild status; {count} = members
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
L.HELP_GUILD    = "/dn guild  guild book: status and which guildmates have Revenge Book"
L.HELP_FRIENDS  = "/dn friends  friends' book: status and which friends have Revenge Book"
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

-- Chat lines (all start with the red "Revenge Book: ") -----------------------------------------------
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
L.CHAT_NO_MATES   = "No guildmate with Revenge Book heard yet."
L.CHAT_HAVE_DN      = "Have Revenge Book: {names}"                 -- {names} = "Anna 1.2.0, Bert 1.1.0"
L.CHAT_HAVE_DN_MORE = "Have Revenge Book: {names} and {count} more"
L.CHAT_SYNC_ASKED = "Sync requested. Answers come in the next few seconds."
L.CHAT_SYNC_FAIL  = "Sync does not work: {reason}"            -- {reason} = a sentence from the status
L.CHAT_SYNC_FAIL_DEFAULT = "no guild or sharing is off."
L.CHAT_FRIENDS_NOT_LOADED = "The friends' book is not loaded."
L.CHAT_FRIENDS_STATE = "Friends: sharing {share}, {online} of {total} online."
L.CHAT_FRIENDS_BOOK  = "Friends' book: {enemies} killers ({listed} only added by hand), {deeds} {deeds|deed|deeds}."
L.CHAT_NO_FRIENDS    = "No friend with Revenge Book heard yet."
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
L.THEME_HARBOR = "Privateer's Ledger"  -- 1.3.0: name of the cover "harbor" (a privateer's log book: sea blue, brass, oxblood)
L.THEME_TRADE = "The Workshop"  -- 1.3.0: name of the cover "trade" (the customer file of a trade business: clipboard, carbon paper)

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "The book is ready. Whoever kills you in the open world is in it afterwards. Open it with /dn or the minimap button."
L.WELCOME_PLATES = "Enemy nameplates are off. Without them the alarm only sees your target."
L.WELCOME_SHARE = "Guild and friends who have Revenge Book read along. Notes and suspicions stay with you."  -- chat, first start; "read along" = they see what the book shares

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
L.SYNC_QUIET       = "Sent, but no guildmate with Revenge Book heard yet."
L.SYNC_READY       = "Ready. No guildmate with Revenge Book heard yet."
L.SYNC_RUNNING     = "Running: {count} {count|guildmate|guildmates} with Revenge Book."
L.SYNC_RUNNING_ALL = "Running: {count} with Revenge Book in guild and friends."
L.FRIENDS_OFF      = "Sharing with friends is off (House Rules, sheet Guild)."
L.FRIENDS_BLOCKED  = "The realm blocks whispers. Friends get nothing."
L.FRIENDS_SHORT_BLOCKED = "Realm blocks whispers" -- [max 22]
L.FRIENDS_FAILING  = "Whispers fail right now, trying again."
L.FRIENDS_SHORT_FAILING = "Whispers stall"        -- [max 18]
L.FRIENDS_NONE_LISTED = "No friends on the friend list."
L.FRIENDS_NONE_ONLINE = "No friend online right now."
L.FRIENDS_SHORT_NONE_ONLINE = "No friend online"  -- [max 18]
L.FRIENDS_QUIET    = "Asked, but no friend with Revenge Book heard yet."
L.FRIENDS_READY    = "Ready. No friend with Revenge Book heard yet."
L.FRIENDS_HOLD     = "Sending to friends waits until it works again."
L.FRIENDS_RUNNING  = "Running: {count} {count|friend|friends} with Revenge Book."
-- A killer copied from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Copied from the guild book (killed guildmates {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB      = "Database not loaded."
L.IMPORT_NO_TEXT    = "No text."
L.IMPORT_NO_HEADER  = "The first line is missing (it starts with {header}). Please copy the whole text."  -- {header} = "DEATHNOTE:1", never translated
L.IMPORT_NOT_EXPORT = "Not a Revenge Book export (header line missing or wrong version)."
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
L.EMPTY_GUILDNIL_HEAD = "No word from the guild yet."  -- fourth tab, no guildmate with Revenge Book heard yet
L.EMPTY_GUILDNIL_SUB = "Your book is shared as soon as a guildmate has Revenge Book."  -- under it; "is shared" = sent to them (not: goes away)
L.EMPTY_GUILDQUIET_HEAD = "Nothing in the guild book yet."  -- fourth tab, guildmates heard, nothing shared yet
L.EMPTY_GUILDQUIET_SUB = "Your guildmates have had peace so far."  -- under it
L.EMPTY_FRIENDSOFF_HEAD = "The friends' book is closed."  -- fourth tab, source Friends, sharing with friends is off
L.EMPTY_FRIENDSOFF_SUB = "Sharing with friends is off. The House Rules know where."  -- under it
L.EMPTY_FRIENDSNIL_HEAD = "No friend with Revenge Book heard yet."  -- fourth tab, source Friends, nobody heard
L.EMPTY_FRIENDSNIL_SUB = "Your book is shared as soon as a friend has Revenge Book."  -- under it; "is shared" = sent to them (not: goes away)
L.EMPTY_FRIENDSQUIET_HEAD = "Nothing from your friends yet."  -- fourth tab, source Friends, nothing shared yet
L.EMPTY_FRIENDSQUIET_SUB = "Your friends have had peace so far."  -- under it
L.EMPTY_NOBODY_HEAD = "No guild, no friends."  -- fourth tab, neither a guild nor sharing with friends
L.EMPTY_NOBODY_SUB = "Dying alone works too."  -- under it, dry joke
L.EMPTY_NOBODY_HINT = "Once guildmates or friends from your friend list have Revenge Book, this page shows what happens to them."  -- third line
L.EMPTY_SHAREDNIL_HEAD = "No one with Revenge Book heard yet."  -- fourth tab, source All, nobody heard
L.EMPTY_SHAREDNIL_SUB = "Your book is shared as soon as guildmates or friends have Revenge Book."  -- under it; "is shared" = sent to them (not: goes away)
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
L.MANUAL_GUILD = "Guildmates and friends with Revenge Book see your confirmed deaths and entries by hand. Poster or /dn hunt Name: put on the hit list. Click the bounty to post your own: a promise, settled among yourselves."  -- help paragraph, 232 px wide, wraps; "confirmed deaths" = deaths with a known killer (not: a certain death)
L.MANUAL_SHARE_HEAD = "PASS ON"  -- [max 12] help label, capitals, letter-spaced
L.MANUAL_SHARE = "House Rules, Back up book: a text to copy, for everyone without Revenge Book."  -- help paragraph, 232 px wide, wraps
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
L.ACT_ADOPT = "Copy to my book"  -- [max 19] button: copy a guild entry into your own book
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
L.BOOK_TITLE = "Revenge Book"  -- [max 12] 1.3.0: title on the cover of the book (1.5.0: the name Revenge Book, English in every language); a theme may set its own (theme word)
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
L.BTN_BACK = "Back"  -- [max 17] button at the bottom of the side pages
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sync"  -- [max 14] button bottom left: ask guild and friends for their books now
L.SYNC_AGAIN_IN = "again in {seconds} s"  -- [max 16] same button after a too early click; {seconds} = seconds left
L.TIP_FRIENDS = "Friends"  -- tooltip head over the friends with Revenge Book
L.TIP_GUILD_NAME = "Guild {guild}"  -- tooltip head; {guild} = guild name
L.TIP_MATES_WITH = "Guildmates with Revenge Book:"  -- tooltip, above the list of guildmates
L.TIP_NO_MATE = "No guildmate with Revenge Book heard yet."  -- tooltip
L.TIP_FRIENDS_WITH = "Friends with Revenge Book:"  -- tooltip, above the list of friends
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
L.REL_HINT_ALL = "Everyone in your guild and your friends with Revenge Book see the reason."  -- hint under the reason field
L.REL_HINT_GUILD = "Everyone in your guild with Revenge Book sees the reason."  -- hint under the reason field
L.REL_HINT_FRIENDS = "Your friends with Revenge Book see the reason."  -- hint under the reason field
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
L.REL_MATE = "That is one of yours (guild or friends with Revenge Book)."  -- message on the sheet and in the chat: guildmates and friends with Revenge Book can't be put on the hit list
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
L.CHAT_BOUNTY_SET = "{name}: you posted a bounty of {gold} gold. Guild and friends with Revenge Book see it."  -- chat: own bounty set; {name} = the target, {gold} = whole gold pieces (number)
L.CHAT_BOUNTY_OFF = "{name}: your bounty is taken back."  -- chat: own bounty taken back; {name} = the target
L.CHAT_BOUNTY_NONE = "You have no bounty of your own on {name}."  -- chat: nothing to take back; {name} = what the player typed or the target
L.CHAT_BOUNTY_BAD = "Bounty: a whole number of gold, 1 to 99999 (0 takes it back)."  -- chat: the amount is no whole number in range
L.CHAT_BOUNTY_CAP = "No bounty: at most {count} of your own."  -- chat: too many own bounties; {count} = the limit (20)
L.CHAT_BOUNTY_OURS = "No bounty on yourself or your own people (guild or friends with Revenge Book)."  -- chat: no bounty on an own char, guildmates or friends with Revenge Book (like REL_MATE)
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
L.BOUNTY_TIP_PROMISE = "Guild and friends with Revenge Book see it. A promise only: you settle it among yourselves."  -- tooltip at the input field: who sees it, the addon pays nothing
L.BOUNTY_TIP_CLICK = "Click: post your own bounty"  -- tooltip on the bounty of the poster (last line)
L.CHAT_AVENGED = "{name} took down {killer} for you."  -- chat with the short revenge sound: a guildmate or friend killed a killer of yours; {name} = his first name, {killer} = the killer
L.NAMES_PLUS = "{name} +{count}"  -- fact line on the poster: the first name and how many more (all of them are in the tooltip); {name} = first name (maybe with "2×"), {count} = how many more. Keep it this short
L.CHAT_BOUNTY_SET_ALONE = "{name}: you posted a bounty of {gold} gold."  -- chat: own bounty set while nobody can see it (no guild, no friends with Revenge Book); first sentence of CHAT_BOUNTY_SET
L.CHAT_BOUNTY_UNKNOWN = "{name} is in none of your books. A bounty goes only on a name from a book, as the game shows it: first name and surname."  -- chat: /dn bounty on a name that is in no book (typo); {name} = what the player typed
L.CHAT_BOUNTY_LIST = "Your bounties ({count} of {max}): {list}"  -- chat: /dn bounty without anything: the own bounties of this char; {count} = how many, {max} = the limit (20), {list} = "Grimm Bart 500g, Fies Ling 50g"
L.CHAT_BOUNTY_LIST_NONE = "You have posted no bounty."  -- chat: /dn bounty without anything and no own bounty (the next line shows how to post one)
-- <<< BOOK
-- >>> REPUTE (Ranks.lua, Ledger.lua, 1.3.0) --------------------------------------------------------------------
L.REPUTE_LINE = "Rank {tier} · Path: {path}"  -- [max 32] the rank where no rank name exists (languages without names in Ranks.lua); {tier} = 1..10, {path} = PATH_* below
L.PATH_R = "Infamy"  -- [max 16] path word: kills of greys and greens (the ruthless path)
L.PATH_E = "Honour"  -- [max 16] path word: kills of players of about the same level (the honourable path)
L.PATH_J = "Hunt"  -- [max 16] path word: kills of higher levels, hit list targets, bounties (the bounty hunter's path)
L.PATH_S = "Protection"  -- [max 16] path word: kills of players who killed guildmates or friends (the protector's path)
L.PATH_NONE = "unwritten"  -- [max 16] path word: below tier 3 and fewer than 10 counted kills, no path yet
-- <<< REPUTE
-- >>> ALARM (Alert.lua, 1.3.0: rap sheet standing in the alarm line, victim alarm) ----------------------------------
L.ALERT_TITLE_VICTIM = "HOLDS A GRUDGE?"  -- [max 30] title of the victim alarm: someone you killed (and who has a reason for revenge) is near; a question, not a warning
L.ALERT_LINE_VICTIM = "score {score} · killed by you, last {time}"  -- [max 56] line of the victim alarm; {score} = "3 : 0" (you : him), {time} = "2 days ago" (your last kill on him)
L.ALERT_LINE_STANDING = "{text} · score {score}"  -- alarm line of a wanted player you have killed back, still open; {text} = the line so far, {score} = "1 : 2" (you : him). Replaces ALERT_LINE_REVENGE while the rap sheet is kept
L.ALERT_LINE_STANDING_EVEN = "{text} · score {score}, settled"  -- like ALERT_LINE_STANDING, the score is level ("2 : 2"): the debt is settled
L.ALERT_LINE_STANDING_AHEAD = "{text} · score {score}, overpaid"  -- like ALERT_LINE_STANDING, you lead ("3 : 2"): you have taken more than he took
-- <<< ALARM
-- >>> START (Start.lua, House Rules row, 1.3.0) -----------------------------------------------------------------
L.SET_THEME = "Cover"  -- [max 16] the cover (theme) of the book: stepper label in the House Rules, sheet Book, under "Language"; also the head over the covers in the first-start window
L.START_HINT = "You can change both later in the House Rules."  -- [max 60] first-start window, foot line left of the button; "both" = language and cover; may wrap to two lines
L.START_GO = "Go"  -- [max 16] first-start window, the one button: take language and cover and open the book
L.START_CLOSE_TIP = "Leave it as it is"  -- [max 32] tooltip of the cross of the first-start window: closing keeps the game's language and the default cover
L.CHAT_THEME_NEWS = "New: the book comes in other covers. House Rules, sheet Book, or /dn theme."  -- chat, once after the update for players who had the book before (they get no window)
L.HELP_START = "/dn start  the first-start window again (language and cover)"  -- /dn help line
-- <<< START
-- >>> RECORD (UI.lua, Extras.lua: the rap sheet in the book, 1.3.0) ---------------------------------------------------
L.TAB_RECORD = "Rap Sheet"  -- [max 16] tab 5 (appears with your first own kill): your own killing blows on players and your repute
L.STAMP_QUITT = "SETTLED"  -- [max 16] stamp on the poster: the score is settled (you killed them as often as they killed you)
L.STAMP_OVERPAID = "OVERPAID"  -- [max 16] stamp on the poster: you killed them more often than they killed you
L.STAMP_NR1_DOWN = "PUBLIC ENEMY DOWN"  -- [max 24] stamp on the notice when you pay back your rank 1 enemy (dry remarks, German and English); two lines of 12 characters at most
L.STATE_OPEN = "open"  -- [max 16] state of the score: they killed you more often (or nothing settled yet)
L.STATE_EVEN = "settled"  -- [max 16] state of the score: both sides equal
L.STATE_AHEAD = "overpaid"  -- [max 16] state of the score: you lead
L.STATE_VICTIM = "not in the book"  -- [max 24] victim sheet: a victim of yours who never killed you
L.STAND_LINE = "Score {score}"  -- poster, tooltip, notice; {score} = '1 : 2' (you : them, the same notation as the alarm)
L.STAND_TIP = "you {mine}, them {his}"  -- tooltip that explains the score
L.TIP_IN_RECORD = "RAP SHEET:"  -- game tooltip label over a player you killed (not in the book)
L.TIP_RECORD_LINE = "killed by you {times}, last {time}"  -- game tooltip; {times} = '3×', {time} = '2 days ago'
L.RECORD_HEAD = "Your File"  -- [max 20] head of the index card with your rank (big handwriting, 26 pt)
L.RECORD_LOG_HEAD = "Latest Kills"  -- [max 20] head of the list of your latest kills
L.RECORD_NEXT = "{points} more to {rank}"  -- under the rank bar; {points} = number, {rank} = name or line of the next rank
L.RECORD_TOP = "Top rank reached."  -- under the rank bar at rank 10
L.RECORD_BAR_TIP = "{total} of {goal} points"  -- tooltip of the rank bar
L.RECORD_NEEDLE_LOW = "ruthless"  -- [max 12] left end of the needle scale
L.RECORD_NEEDLE_HIGH = "honourable"  -- [max 12] right end of the needle scale
L.RECORD_NEEDLE_TIP = "The needle: honour and protection against infamy. Hunt does not move it."  -- tooltip of the needle
L.RECORD_KILLS = "Kills: {kills} · Victims: {victims}"  -- number line on your file
L.RECORD_BEST = "Best: {list}"  -- line on your file; {list} = the parts below joined with ' · '
L.RECORD_BEST_GAP = "+{count} levels"  -- best mark: the biggest level gap of a kill
L.RECORD_BEST_STREAK = "streak {count}"  -- best mark: kills in a row without dying
L.RECORD_BEST_QUICK = "fastest payback {time}"  -- best mark; {time} = DUR_* below
L.DUR_SECONDS = "{count} s"  -- a duration in seconds
L.DUR_MINUTES = "{count} min"  -- a duration in minutes
L.DUR_HOURS = "{count} h"  -- a duration in hours
L.RECORD_AWARDS = "AWARDS"  -- [max 14] small label over the row of awards (letter-spaced)
L.RECORD_AWARD_AT = "awarded {time}"  -- award tooltip; {time} = date
L.RECORD_AWARD_OPEN = "not awarded yet"  -- award tooltip
L.RECORD_MORE = "Show more"  -- [max 19] word at the bottom right of your file: opens the list of your latest kills
L.RECORD_BACK = "Back to file"  -- [max 19] word at the bottom right of a victim or the kill list: back to your file
L.RECORD_CLEAR = "Clear rap sheet"  -- [max 26] button on the House Rules' sheet Rap Sheet (asks first)
L.CONFIRM_RECORD_CLEAR = "Clear the rap sheet?\nAll victims and the list of latest kills go. Rank, points and awards stay."  -- dialog; \n = line break
L.CONFIRM_RECORD_CLEAR_OK = "Clear"  -- [max 14] dialog button
L.CONFIRM_VICTIM_STRIKE = "Strike {name} from the rap sheet?\nThe points you earned stay."  -- dialog; {name} = the victim
L.ACT_VICTIM_STRIKE = "Strike from rap sheet"  -- [max 26] button on the victim sheet (asks first)
L.VICTIM_KILLED = "killed by you {times}"  -- victim sheet; {times} = '3×'
L.VICTIM_POINTS = "Points earned: {points}"  -- victim sheet
L.VICTIM_SCENE = "Scene: {zone}, {time}"  -- victim sheet: where and when you last killed them; {zone} from the game, {time} = '2 hrs ago'
L.VICTIM_KILLS_LABEL = "YOUR KILLS"  -- [max 14] small label over the kill lines of a victim (letter-spaced)
L.KILL_TAG_REVENGE = "payback"  -- [max 14] tag at the right of a kill line: they had killed you more often
L.KILL_TAG_KICK = "while down"  -- [max 14] tag at the right of a kill line: the same player again within 10 minutes (no points)
L.KILL_TAG_GROUP = "group"  -- [max 14] tag at the right of a kill line: killed in a group (half honour and hunt)
L.KILL_WITH_GROUP = "With your group."  -- 1.3.1: added to the chat line after a kill your group member's killing blow made (you took part), and a line in the kill's tooltip
L.BAND_GRAU = "grey"  -- [max 12] level colour of a victim as the game shows it: far below you
L.BAND_GRUEN = "green"  -- [max 12] level colour: below you
L.BAND_GELB = "yellow"  -- [max 12] level colour: about your level
L.BAND_ORANGE = "orange"  -- [max 12] level colour: above you
L.BAND_ROT = "red"  -- [max 12] level colour: far above you
L.BAND_SCHAEDEL = "skull"  -- [max 12] level colour: skull, unknown level far above you
L.BAND_UNBEKANNT = "unknown"  -- [max 12] level colour not known (killed without seeing the level)
L.RECORD_POINTS = "+{points} {path}"  -- points of one kill; {path} = PATH_* word
L.RECORD_NO_POINTS = "no points"  -- a kill that earned nothing
L.RECORD_BANDS = "By level colour"  -- tooltip head over the kills per level colour
L.TIP_PATH_R = "Infamy: kills of greys and greens."  -- tooltip of the accounts line
L.TIP_PATH_E = "Honour: kills of players about your level, payback."  -- tooltip of the accounts line
L.TIP_PATH_J = "Hunt: kills of higher levels, hit list targets, bounties."  -- tooltip of the accounts line
L.TIP_PATH_S = "Protection: kills of players who killed guildmates or friends."  -- tooltip of the accounts line
L.SORT_STATE = "Score"  -- [max 14] sort of the rap sheet: open scores first
L.SORT_COUNT = "Kills"  -- [max 14] sort of the rap sheet: most killed first
L.SORT_POINTS = "Points"  -- [max 14] sort of the rap sheet: most points first
L.CHAT_OWN_KILL = "Rap sheet: {name}, {level} ({band}). {points}."  -- chat after your own killing blow; {level} = 'Level 34', {band} = BAND_*, {points} = '+3 Honour' or RECORD_NO_POINTS
L.CHAT_KILL_WITH_GROUP = "{line} {group}"  -- 1.3.1: the chat line of a group kill; {line} = CHAT_OWN_KILL, {group} = KILL_WITH_GROUP. Write the gap your script puts after a full stop (none after a full-width one)
L.CHAT_PATH = "New path: {path}. Rank: {rank}."  -- chat when your path changes; {rank} = name or line of the rank
L.BANNER_RANK = "NEW RANK"  -- [max 24] head of the notice when your rank rises
L.BANNER_AWARD = "AWARD"  -- [max 24] head of the notice for an award
L.OPT_LEDGER = "Keep a rap sheet"  -- [max 44] check box: book your own kills (off: nothing is booked, tab and score disappear, the data stays)
L.OPT_LEDGER_CHAT = "Report own kills in the chat"  -- [max 44] check box
L.OPT_VICTIMS = "Warn when a victim of yours shows up"  -- [max 44] check box (off by default)
L.SET_SETTLED = "Alarm when the score is settled"  -- [max 34] stepper label: alarm for killers you are even with or lead
L.SET_SETTLED_ALWAYS = "as usual"  -- [max 10] stepper value: alarm as for everyone
L.SET_SETTLED_QUIET = "quiet"  -- [max 10] stepper value: the popup with the soft sound, no edge pulse
L.SET_SETTLED_OFF = "never"  -- [max 10] stepper value: no alarm
L.MANUAL_RECORD_HEAD = "RAP SHEET"  -- [max 14] keyword of the help paragraph
L.MANUAL_RECORD = "Your kills on players, your group's too when you took part. Poster and list show the score 'you : them': open, settled or overpaid. Rank 1 is always open. Kills earn points for your rank."  -- help paragraph, 232 px wide, wraps
L.POSTER_LAST_SEEN_IN = "Last seen: {zone}, {time}"  -- fact line; {zone} = zone from the game, {time} = '2 hrs ago' (shorter POSTER_LAST_SEEN when it does not fit)
L.SHEET_RECORD = "Rap Sheet"  -- [max 14] fourth sheet of the House Rules: the rap sheet's switches
L.EMPTY_RECORD_HEAD = "Nobody yet."  -- 1.3.1: rap sheet tab, no victim yet: big line on the left page
L.EMPTY_RECORD_SUB = "Your kill on a player of the other faction ends up here."  -- 1.3.1: under it; what puts a name here
-- <<< RECORD
-- 1.4.0 grudge
L.GRUDGE_HEAD = "ATTACKED"  -- head of the grudge notice on the right edge (after an attack; capitals, letter-spaced, 194 px, 10/9 pt)
L.GRUDGE_IN_BOOK = "in the book"  -- grudge notice, right end of a row (68 px, 10/9 pt): your death put this attacker into the book already
L.GRUDGE_ADDED = "entered"  -- grudge notice, right end of a row (68 px): ticked, now in the book
L.GRUDGE_SKIPPED = "skipped"  -- grudge notice, right end of a row (68 px): crossed out or let go, not entered
L.GRUDGE_TIP = "Tick: into the book (grudge). Cross, or let it run out: not entered. The mouse over it holds the time; dragging moves it, right-click closes it."  -- tooltip over the grudge notice: what tick and cross do, how to move and close it
L.GRUDGE_TIP_YES = "Into the book: the alarm warns you about them."  -- tooltip of the tick button
L.GRUDGE_TIP_NO = "Do not enter."  -- tooltip of the cross button
L.GRUDGE_TIP_KB = "Killing blow"  -- row tooltip: this one landed the killing blow on you
L.GRUDGE_TIP_SEEN = "Had you targeted while you were hit"  -- row tooltip: how he was found (had you as target while you took hits)
L.GRUDGE_TIP_RECAP = "In your death recap"  -- row tooltip: how he was found (the game's death recap names him)
L.GRUDGE_TIP_METER = "In the damage meter after the fight"  -- row tooltip: how he was found (the game's damage meter names him)
L.ROLE_ATTACK = "attacked"  -- [max 14] right of a deed line on the poster: attacked you without killing you, entered by you
L.TIP_ROLE_ATTACK = "Attacked you, entered by you (grudge)."  -- deed tooltip of an attack
L.TALLY_ATTACKED = "attacked {times}"  -- core line of an entry: how often he attacked you (entered by you); {times} = '3×'
L.STAMP_GRUDGE = "GRUDGE"  -- [max 16] stamp on the poster of an entry with attacks only (grudge); two lines possible
L.SET_SEC_GRUDGE = "GRUDGE"  -- [max 24] section label on the House Rules, sheet Rap Sheet (4th): the grudge notice
L.OPT_GRUDGE = "Ask after an attack (grudge)"  -- [max 44] check box: the small notice after an attack (open world)
L.OPT_GRUDGE_BG = "Also in battlegrounds and arenas"  -- [max 44] check box: the notice in battlegrounds and arenas too (off by default)
L.SET_GRUDGE_SECONDS = "Notice stays for"  -- [max 34] stepper label (value: '20 s'): how long the notice stays after the fight
L.SET_GRUDGE_TEST = "Test notice"  -- [max 17] button: shows a test notice with made-up names
L.SET_GRUDGE_RESET = "Reset position"  -- [max 24] button (132 to 180 px): the notice goes back to its default place
L.CHAT_GRUDGE_ON = "Grudge on: after an attack a small notice asks whether the attacker goes into the book."  -- chat line after /dn grudge
L.CHAT_GRUDGE_OFF = "Grudge off: no notice after attacks."  -- chat line after /dn grudge
L.CHAT_GRUDGE_TEST = "Test notice with made-up names: tick and cross enter nothing."  -- chat line after /dn grudge test
L.HELP_GRUDGE = "/dn grudge  notice after attacks on/off (/dn grudge test: test notice)"  -- line of /dn help

-- >>> OVERVIEW (UI.lua, Store.lua, Core.lua: copying, sorting, filter, section heads) ---------------------------
-- 1.4.0 overview
L.SORT_KILLS = "Kills on me"  -- sort menu: how often he killed you
L.SORT_LEVEL = "Level"  -- sort menu
L.SORT_CLASS = "Class"  -- sort menu
L.SORT_BOUNTY = "Bounty"  -- sort menu
L.SORT_ONLY_NEW = "Only what I lack"  -- guild sort menu: show only killers not yet in your own book
L.SORT_ALL_ROWS = "Show all"  -- guild sort menu: show all again
L.FILTER_WORD = "Filter"  -- word left of the sorting in Wanted (opens the filter menu)
L.FILTER_TIP = "Show only:"  -- tooltip of the filter word, the active filter follows
L.FILTER_ALL = "Everyone"  -- filter menu: no filter
L.FILTER_KILL = "Killed me"  -- filter menu: killed you at least once
L.FILTER_ASSIST = "Assisted"  -- filter menu: took part in a death of yours
L.FILTER_ATTACK = "Grudge"  -- filter menu: noted when he attacked you (Grudge)
L.FILTER_MANUAL = "Added by hand"  -- filter menu: added by hand
L.FILTER_ADOPTED = "Copied"  -- filter menu: copied from guild, friends or a text
L.FILTER_CLASS = "Class …"  -- filter menu: opens the list of classes
L.FILTER_BACK = "‹ Back"  -- class menu: back to the filter menu
L.FILTER_HINT = "{shown} of {total} · show all"  -- foot of the list while a filter or search narrows it; a click shows all
L.SECTION_SETTLED = "Settled"  -- head row in Wanted before the settled ones
L.SECTION_SETTLED_SUB = "you are even or ahead"  -- under it
L.SECTION_PARDONED = "Pardoned"  -- head row in Wanted before the pardoned
L.SECTION_PARDONED_SUB = "no alarm, they do not count"  -- under it
L.ACT_TAKE = "Copy to my book"  -- poster button: into your own book
L.ACT_TAKE_ALL = "Copy all"  -- poster button: opens the preview of copying all
L.ACT_TAKE_ALL_OF = "Copy all from {name}"  -- menu on a guildmate's or friend's head row
L.ROW_TAKE = "copy"  -- small word at the right of a guild or friends' row not yet in your book
L.TIP_ROW_TAKE = "Copy to your own book (where it came from is noted)."  -- its tooltip
L.TAKE_HEAD = "Copy all"  -- page head of the copy sheet
L.TAKE_FROM_MATE = "From {name}"  -- under it: whose list
L.TAKE_FROM_GUILD = "From the guild book"  -- under it
L.TAKE_FROM_FRIENDS = "From the friends' book"  -- under it
L.TAKE_FROM_ALL = "From guild and friends"  -- under it
L.TAKE_COUNT = "New: {new} · already in your book: {have}"  -- the numbers of the preview
L.TAKE_NEW_LABEL = "New"  -- letter-spaced label above the new names
L.TAKE_MORE = "and {count} more"  -- after the names shown
L.TAKE_HINT = "They go into your book marked as copied, with their origin. Their deaths do not count as yours, and nothing of it is passed on."  -- what copying means
L.TAKE_HINT_FRIENDS = "Friends send only their sure deaths (the last 30) and names added by hand, and only while you are both online. A whole book: Back up book at your friend's, Import book at yours."  -- what comes from friends at all
L.TAKE_NONE = "Everything is in your book already."  -- nothing new
L.TAKE_DONE = "Copied: {count}."  -- result
L.TAKE_UNDONE = "Undone: {count} struck again."  -- after Undo
L.TAKE_ONE_DONE = "Copied: {name}."  -- foot line after one row
L.BTN_DONE = "Done"  -- button after copying
L.IO_OWNER = "Whose book"  -- import: letter-spaced label before the choice
L.IO_MINE = "mine"  -- choice: your own backup
L.IO_THEIRS = "{name}'s"  -- choice: the friend's book (his first name)
L.IO_THEIRS_ANON = "someone else's"  -- choice without a name
L.IO_PREVIEW = "In the text: {total} · new: {new} · already in your book: {have}"  -- preview of your own text
L.IO_PREVIEW_FRIEND = "Wanted there and new to you: {new} · already in your book: {have}"  -- preview of a friend's text
L.IO_HINT_MINE = "Like a backup: everything is merged, its deaths count as yours."  -- what reading your own text does
L.IO_HINT_FRIEND = "Only new names, marked as copied; your friend's deaths do not count as yours."  -- what reading a friend's text does
L.IO_GO_NOW = "Import now"  -- button after the preview
L.IO_TAKEN = "Copied: {new}. Already in your book: {have}."  -- result of a friend's text
L.NOTE_ADOPTED_GUILD = "Copied from the guild book, from {name} (killed guildmates {kills}×)."  -- poster note of an entry copied from the guild
L.NOTE_ADOPTED_FRIEND = "Copied from {name} (killed friends {kills}×)."  -- ... from a friend
L.NOTE_ADOPTED_TEXT = "Read in from {name}'s book (killed there {kills}×)."  -- ... read in from a friend's text
L.NOTE_ADOPTED_TEXT_ANON = "Read in from someone else's book (killed there {kills}×)."  -- ... without a name
L.TALLY_ADOPTED = "copied from {name}"  -- row line of a taken-over entry
L.TALLY_ADOPTED_ANON = "copied"  -- the same without a name
L.POSTER_FRIENDSBOOK = "FRIENDS' BOOK"  -- line under WANTED on a friends' book poster
L.EMPTY_FILTERED_HEAD = "No match."  -- right page: the filter hides every entry
L.EMPTY_FILTERED_SUB = "The filter hides everyone. At the bottom: show all."  -- under it
L.EMPTY_ALLTAKEN_HEAD = "All of it is in your book."  -- right page: 'only what I lack' and nothing is left
L.EMPTY_ALLTAKEN_SUB = "Nothing left to copy. At the bottom: show all."  -- under it
-- <<< OVERVIEW
-- 1.4.0 fixer
L.TAKE_UNDONE_KEPT = "Undone: {count} struck again. {kept} stay: they got your own entries since."  -- after Undo when some entries got your own data since (a kill, a death, an attack, a note, a pardon): those stay
L.FILTER_HIDDEN = "{count} {count|match|matches} hidden by the filter · show all"  -- foot of Wanted while the search finds entries the filter hides; a click drops the filter (the search stays)
L.EMPTY_HIDDEN_HEAD = "Hidden by the filter."  -- right page: the search finds only entries the filter hides (Enter adds nothing then)
L.EMPTY_HIDDEN_SUB = "Enter or the line at the bottom shows them."  -- under it
L.EMPTY_SEARCHHAS_HEAD = "In your book already."  -- right page: the search finds a name of your book that is not on this page (pardoned while hidden, a suspect)
L.EMPTY_SEARCHHAS_SUB = "Just not on this page. Enter opens it."  -- under it
L.FILTER_TWO = "{count} filters"  -- filter word when role and class are both on and the two words do not fit (the tooltip names both)
L.GRUDGE_TIP_OFF = "Turn it off: /dn grudge or {rules}, sheet {sheet}."  -- last line of the grudge notice's tooltip: how to turn it off; {rules} {sheet} = names of the House Rules and the sheet in the active cover
-- 1.5.0 grip
L.GRUDGE_TIP_PROBABLE = "Not sure: little points at him. Tick only if you saw him."  -- row tooltip of the grudge notice: why the row is pale and carries a "?" (one sign only, or a creature attacked you too); second sentence: tick only if you saw him yourself
L.GRUDGE_TIP_MOB = "A creature was attacking you at the same time"  -- row tooltip: a hostile creature had you targeted (or was fighting you) at the same moment, so the hit may have been its
L.GRUDGE_TIP_CAST = "Cast a spell while you were hit"  -- row tooltip: he cast a spell within two seconds of a hit on you
L.GRUDGE_TIP_JOIN = "Went into combat with your hit"  -- row tooltip: he went from out of combat into combat right at a hit on you
L.GRUDGE_TIP_REPEAT = "Had you targeted at several hits"  -- row tooltip: he had you targeted at two or more hits, seconds apart
L.SET_GRUDGE_SIZE = "Notice size"  -- [max 34] stepper label under GRUDGE (value: SIZE_SMALL, SIZE_MEDIUM, SIZE_LARGE): size of the grudge notice
L.SIZE_SMALL = "small"  -- [max 10] stepper value: small
L.SIZE_MEDIUM = "medium"  -- [max 10] stepper value: medium (the default)
L.SIZE_LARGE = "large"  -- [max 10] stepper value: large
L.SET_SEC_PLATE = "NAMEPLATES"  -- [max 24] section label on the House Rules, sheet Rap Sheet: the mark on nameplates
L.SET_PLATE = "Mark over names in the book"  -- [max 34] stepper label (value: WORD_OFF or a size word): the small mark over the nameplate of somebody in your book
L.BIND_TOGGLE = "Open or close the book"  -- the game's key bindings window, under the addon's title: open or close the book
L.BIND_ADD = "Target into the book"  -- key binding: write the current target into the book (as /dn add)
L.BIND_HUNT = "Target on the hit list"  -- key binding: put the current target on the hit list (as /dn hunt), with the standard reason GRIP_HUNT_WHY
L.BIND_ALARM = "Alarm off / on"  -- key binding: alarm off and on again (as /dn quiet)
L.GRIP_NO_TARGET = "No target: target an enemy player first."  -- chat and screen line after a key binding without a target
L.GRIP_NOT_ENEMY = "Your target is no enemy player."  -- ... when the target is a creature, a friendly player, a group member or yourself
L.GRIP_ALREADY = "{name} is in the book already."  -- after the key binding 'Target into the book' when he is in the book already (class, level, guild follow in brackets)
L.GRIP_HUNT_WHY = "Marked in a fight"  -- [max 40] the standard reason of a hit list call made by key in a fight; shared with guild and friends as the reason
L.GRIP_HUNT_CHANGE = "Reason: \"{why}\". To change it: \"{action}\" in the book."  -- after the key binding 'Target on the hit list'; {why} = GRIP_HUNT_WHY, {action} = ACT_RELEASE (the button on the poster)
-- 1.5.0 share
L.ACT_SHARE = "Post"  -- word at the top right of the poster and entry of the row menu: opens the window that posts this enemy in the chat (a public notice, like a poster on a board; not the same word as SCENE_SHOW 'show on the map')
L.SHARE_HEAD = "Show in the chat"  -- head of that window
L.SHARE_TAB_LINE = "Poster"  -- word tab: the poster as one chat line
L.SHARE_TAB_WEEK = "My week"  -- word tab: the week as one chat line (most wanted, payback, open debts)
L.SHARE_TAB_DISCORD = "Discord"  -- word tab: a block to copy for Discord
L.SHARE_PREVIEW = "This line goes out"  -- small letter-spaced label above the preview of the line
L.SHARE_CH_GUILD = "Guild"  -- button: send the line to the guild chat
L.SHARE_CH_PARTY = "Party"  -- button: ... to the party
L.SHARE_CH_RAID = "Raid"  -- button: ... to the raid
L.SHARE_CH_INSTANCE = "Instance"  -- button: ... to the instance group
L.SHARE_CH_SAY = "Say"  -- button: ... say (players nearby)
L.SHARE_SENT = "Posted in {channel}."  -- status after sending; {channel} = the button's word; same verb as ACT_SHARE
L.SHARE_WAIT = "One line every 10 seconds. Again in {seconds} s."  -- status: at most one line every 10 s; {seconds} = how long still
L.SHARE_LOCKED = "The chat is locked here right now."  -- status: the game locks the chat (boss fight, arena, battleground)
L.SHARE_COMBAT = "Not in combat. Click again after the fight."  -- status: nothing is sent in combat
L.SHARE_FAILED = "The game did not send the line."  -- status: sending failed
L.SHARE_HINT = "Plain text for everybody; with the addon the name is a link."  -- status before sending: what readers see
L.SHARE_DISCORD_HINT = "Marked: Ctrl+C copies it. Notes never go along."  -- under the Discord block
L.SHARE_CLOSE = "Close"  -- word: close the window
L.SHARE_KILLED_ME = "killed me {times}"  -- part of the chat line (sender's language); {times} = '3x'
L.SHARE_BOUNTY = "{gold} bounty"  -- part of the chat line; {gold} = '131g'
L.SHARE_SEEN = "last seen {zone}"  -- part of the chat line; {zone} = zone from the game
L.SHARE_DEED_AT = "last deed {place}"  -- part of the chat line; {place} = zone, subzone of his last kill on you
L.SHARE_REVENGE_NOW = "now {score}"  -- part of the payback line; {score} = '3 : 5' (you : them)
L.SHARE_KIND_PARDONED = "PARDONED"  -- first part of the line of a pardoned enemy, in capitals like WANTED
L.SHARE_WEEK_HEAD = "MY WEEK"  -- first part of the week line, in capitals
L.SHARE_WEEK_TOP = "most wanted, killed me {times}"  -- week line, after the name of the most wanted; {times} = '3x' this week
L.SHARE_WEEK_NONE = "nobody killed me"  -- week line when nobody killed you this week
L.SHARE_WEEK_REVENGE = "payback taken: {count}"  -- week line: own kills on your killers this week
L.SHARE_WEEK_DEBTS = "open debts: {count}"  -- week line: enemies who still lead the score
L.SHARE_DC_LAST = "Last deed: {place}, {time}"  -- Discord block; {place} = zone, subzone, {time} = date and time
L.SHARE_GUEST_BY = "posted by {name}"  -- guest poster (a line whose name is in none of your books): who posted it; {name} = first name; same verb as ACT_SHARE
L.SHARE_GUEST_SAYS = "The line says"  -- small letter-spaced label above the parts of the line on the guest poster
L.SHARE_GUEST_HINT = "Only what the line says. Not in any of your books."  -- guest poster, above the buttons
L.SET_SEC_SHOW = "POST"  -- section head on the House Rules sheet Guild, capitals like the others; same verb as ACT_SHARE
L.OPT_SHARE_REVENGE = "Button \"Post\" on the payback notice"  -- switch (off by default): a small button with the word of ACT_SHARE on the payback notice
-- 1.5.0 scene
L.SET_SEC_MAP = "MAP"  -- [max 24] section label on the House Rules, sheet Book: the crime scenes on the world map
L.OPT_SCENE = "Crime scenes on the world map"  -- [max 44] check box (House Rules, sheet Book, and the map's own switch): pins of the book on the world map
L.OPT_SCENE_OPEN = "Only open debts"  -- [max 32] the map's switch: only scenes of enemies who still lead against you
L.SCENE_DAYS_ALL = "all"  -- [max 10] the period in the map's switch: every scene, however old
L.SCENE_DAYS_LINE = "Period: {days}"  -- [max 32] the map's switch: the period; a click steps 7 days, 30 days, all; {days} = "30 days" or SCENE_DAYS_ALL
L.SCENE_KIND_OWN = "My deaths and kills"  -- [max 32] the map's switch: your own deaths and kills
L.OPT_G_SENDPLACE = "Send the spot of my death"  -- [max 44] check box (House Rules, sheet Guild, group SHARE): the exact spot of your death goes to guild and friends with it
L.SCENE_MAP_TIP = "Crime scenes of your book"  -- tooltip head of the small button at the world map's corner
L.SCENE_MAP_CLICK = "Click: filter the crime scenes"  -- tooltip line of that button: what a click does
L.SCENE_SOMEONE = "someone"  -- name for a killer nobody knows (map tooltip)
L.SCENE_TIP_DEATH = "Here {killer} killed you"  -- map pin tooltip, your death; {killer} = full name in class colour
L.SCENE_TIP_DEATH_UNCLEAR = "Here you were killed; the killer is unclear"  -- map pin tooltip, your death without a known killer
L.SCENE_TIP_KILL = "Here you took {name} down"  -- map pin tooltip, your kill; {name} = full name in class colour
L.SCENE_TIP_MATE = "Here {victim} was killed by {killer}"  -- map pin tooltip, a guildmate's or friend's death; {victim} = their name, {killer} = full name in class colour
L.SCENE_REVENGE = "Revenge taken"  -- map pin tooltip: this kill was revenge
L.SCENE_SRC_GUILD = "Guildmate"  -- map pin tooltip: the dead one is in your guild
L.SCENE_SRC_FRIEND = "Friend"  -- map pin tooltip: the dead one is your friend
L.SCENE_FRESH = "{ago}: still close, go and help"  -- map pin tooltip of a death younger than 10 minutes; {ago} = "3 min ago"
L.SCENE_BUNDLE = "Crime scenes here: {count}"  -- map pin tooltip head when several scenes lie on one spot; {count} = how many
L.SCENE_TIP_CLICK = "Click: open the book there"  -- last line of a map pin tooltip
L.SCENE_SHOW = "Click: show on the map"  -- tooltip line over a place in the book (deed line, death file, chronicle): the click opens the world map there
L.SCENE_NO_SPOT = "Exact spot unknown: this is the zone."  -- hint on the map after a click in the book when the entry has no coordinates
L.SCENE_NO_MAP = "No map known for this place."  -- chat line after a click in the book when the place has no map
L.SCENE_COMBAT = "In combat the map stays shut. Click again afterwards."  -- chat line after a click in the book during combat
L.CHRON_OPEN = "Chronicle"  -- [max 14] word right of DEEDS on the poster: opens the chronicle of the feud
L.CHRON_HEAD = "Chronicle"  -- [max 20] head of the chronicle card (big handwriting, 26 pt)
L.CHRON_BACK = "Back to poster"  -- [max 19] word at the bottom right of the chronicle: back to the poster
L.CHRON_EMPTY = "Nothing written yet."  -- chronicle without any event
L.CHRON_AT = "{date}, {place}:"  -- chronicle: in front of each sentence; {date} = day (11/10), {place} = subzone or zone
L.CHRON_AT_DAY = "{date}:"  -- chronicle: the same without a known place
L.CHRON_FIRST = "First encounter: {date}, {place}."  -- chronicle, first line; {date} = day, {place} = place
L.CHRON_FIRST_DAY = "First encounter: {date}."  -- chronicle, first line without a place
L.CHRON_KILL_SPELL = "{name} gets you with {spell}."  -- chronicle sentence: he killed you; {name} = his first name, {spell} = spell name from the game
L.CHRON_KILL = "{name} kills you."  -- chronicle sentence: he killed you (no spell known)
L.CHRON_KILL_AGAIN = "{name} strikes again. Of course."  -- chronicle sentence: he killed you, second wording (never the same sentence twice in a row)
L.CHRON_ASSIST = "{name} helps kill you."  -- chronicle sentence: he took part in killing you (not the killing blow)
L.CHRON_ASSIST_AGAIN = "{name} is in on it again."  -- chronicle sentence: the same, second wording
L.CHRON_SUSPECT = "Suspicion: {name} had you targeted when you died."  -- chronicle sentence: a suspicion only (he had you targeted)
L.CHRON_SUSPECT_AGAIN = "Suspicion on {name} again."  -- chronicle sentence: the same, second wording
L.CHRON_ATTACK = "Attack: {name} goes for you, you get away."  -- chronicle sentence: he attacked you and you survived (Grudge)
L.CHRON_ATTACK_AGAIN = "{name} attacks you again. You live."  -- chronicle sentence: the same, second wording
L.CHRON_MINE_FIRST = "You get {name} for the first time."  -- chronicle sentence: your first kill on him
L.CHRON_MINE = "You take {name} down."  -- chronicle sentence: you killed him
L.CHRON_MINE_AGAIN = "{name} falls to you again."  -- chronicle sentence: the same, second wording
L.CHRON_HAND = "You note revenge on {name}."  -- chronicle sentence: revenge noted by hand
L.CHRON_HAND_AGAIN = "Revenge on {name} noted once more."  -- chronicle sentence: the same, second wording
L.CHRON_LISTED = "You write {name} into the book by hand."  -- chronicle sentence: entered by hand
L.CHRON_COPIED = "Copied from {from}."  -- chronicle sentence: copied from someone's book; {from} = that character
L.CHRON_COPIED_ANON = "Copied from someone else's book."  -- chronicle sentence: copied, nobody named
L.CHRON_BOUNTY = "{by} puts {gold} on {name}."  -- chronicle sentence: a bounty; {by} = first name of the poster, {gold} = "500 g"
L.CHRON_BOUNTY_MINE = "You put {gold} on {name}."  -- chronicle sentence: your own bounty
L.CHRON_EVEN = "Even now: {score}."  -- chronicle line: turning point, the score is even; {score} = '2 : 2' (you : them)
L.CHRON_AHEAD = "Overpaid now: {score}."  -- chronicle line: turning point, you lead; {score} = '3 : 2'
L.CHRON_AVENGED = "{names} took {name} down for the others."  -- chronicle line: guildmates or friends killed him for the others; {names} = first names (one or several: no verb that counts them)
L.CHRON_PARDONED = "You pardoned {name}."  -- chronicle line: you pardoned him
L.CHRON_END = "Now: {score} · {state}"  -- chronicle, last line; {score} = '1 : 2', {state} = STATE_OPEN / STATE_EVEN / STATE_AHEAD
L.CHRON_END_NONE = "So far: {name} killed you {times}."  -- chronicle, last line while the rap sheet is off; {name} = his first name, {times} = '3×'
-- 1.5.0 name
L.HELP_ALIASES = "/rb, /revengebook  the same as /dn"  -- /dn help line: the two new commands of 1.5.0
L.CHAT_NEWS_150 = "DeathNote is now Revenge Book. Your book and /dn stay. New in 1.5.0: Post (top right of a poster) puts it in the chat; a click on a place in the book shows the crime scene on the world map; Chronicle next to DEEDS; keys under Esc > Options > Key Bindings; a mark on your killers' nameplates (House Rules, Rap Sheet)."  -- chat, once per account after the update to 1.5.0 for players who had the book before: the new name, what stays, what is new and where it is (Post at the top right of the poster, a place in the book shows the map, the chronicle next to DEEDS, the key bindings menu, the nameplate mark on the House Rules sheet Rap Sheet); the old name DeathNote and Revenge Book stay in English; words as the book shows them
-- 1.5.0 fix
L.SCENE_TIP_SUSPECT = "Here you died; suspicion: {name}"  -- map pin tooltip, your death without a sure killing blow (the book holds a suspicion); {name} = full name in class colour; never say he killed you
L.CHRON_EARLIER = "Earlier deeds are no longer in the book."  -- chronicle, second line of a long feud whose oldest deeds the book no longer keeps (it keeps 30 per enemy); the last line still gives the full standing
L.GRUDGE_TIP_PET = "His pet attacked you too"  -- grudge notice, row tooltip: a unit he controls (hunter pet, demon, elemental) had you targeted at the same hit
L.SHARE_GUEST_WEEK = "{name}'s week"  -- [max 24] head of the card a click on a received week line opens (no wanted poster); {name} = the sender's first name
L.SCENE_TIP_PICK = "Click: pick a crime scene"  -- last line of a map pin's tooltip when the pin holds several crime scenes: a click opens a list of them
L.SCENE_LEG_DEATH = "your death"  -- [max 32] legend in the tooltip of the map's switch: the red pin = a place where you died
L.SCENE_LEG_KILL = "your kill"  -- [max 32] legend in the tooltip of the map's switch: the black pin with blades = a player of your book you killed there
L.SCENE_LEG_BUNDLE = "several crime scenes"  -- [max 32] legend in the tooltip of the map's switch: the number badge on a pin = several crime scenes close together
L.SET_HINT_FRIENDS_POST = "Sharing and alerts go only to guild and friends with Revenge Book. A post is for everyone in the chat."  -- hint at the bottom of the sheet Guild with friends: sharing and alerts go only to addon users; a post (ACT_SHARE) is read by everyone in the chat
L.SET_HINT_GUILD_POST = "Sharing and alerts go only to your own guild. What comes from there stays apart from your book until you take it over yourself. A post is for everyone in the chat."  -- hint at the bottom of the sheet Guild without friends, wraps; same rule as SET_HINT_FRIENDS_POST
L.PLATE_TIP_WANTED = "Red pin with the score 'you : them': wanted"  -- nameplate stepper tooltip (House Rules, Rap Sheet): the red thumbtack with the standing 'you : them' (your kills on him : his on you) = wanted
L.PLATE_TIP_GRUDGE = "Grey pin: only attacked you"  -- same tooltip: the grey thumbtack = he only attacked you (grudge, no kill)
L.PLATE_TIP_HUNT = "Crosshair: on the hit list"  -- same tooltip: the crosshair stamp = on the hit list
L.CHRON_OPEN_TIP = "Click: the feud told as a story"  -- tooltip of the word CHRON_OPEN on the poster (head: CHRON_HEAD): what its click opens
L.GRIP_KEYS_WHERE = "Keys: Esc > Options > Key Bindings > {title}"  -- last line of the nameplate stepper tooltip: where the key bindings are set; the client's own menu words ({title} = the addon's title); languages without a client of their own keep the English menu words
L.GRIP_KEY_HINT = "Tip: a key does this with your target. Set it: Esc > Options > Key Bindings > {title}."  -- chat, once per account after a typed '/dn add <name>' while no key is set for BIND_ADD: such a key exists and where to set it
L.GRIP_KEY_HAVE = "Tip: your key {key} does this with your target."  -- chat, once per account after a typed '/dn add <name>' when a key is set for BIND_ADD; {key} = that key as the game writes it
-- 1.6.0 guildlog
L.GLOG_HEAD = "Guild chronicle"  -- head of the chronicle's left page and of the ribbon's tooltip: what happened to the guild
L.GLOG_SUB = "{guild} · {count} {count|event|events}"  -- under the head: the guild's name and how many events the page holds
L.GLOG_SUB_NOGUILD = "Friends · {count} {count|event|events}"  -- the same without a guild (only the friends' book)
L.GLOG_EMPTY = "Nothing has happened yet. Deaths, revenge, bounties and calls of the guild show up here."  -- empty chronicle
L.GLOG_FOOT_MORE = "{from} to {to} of {count} · mouse wheel turns the page"  -- foot of the chronicle while it holds more lines than fit
L.GLOG_TIP_POSTER = "Click: open the poster"  -- tooltip of a chronicle line: its click opens the killer's poster
L.GLOG_RIBBON_TIP = "Click: what happened to the guild, who has the book, the week"  -- tooltip of the red ribbon on the book's fold
L.GLOG_RIBBON_CLOSE = "Click: back to the book"  -- the same while the chronicle is open
L.GLOG_NEW = "{count} new since you last looked"  -- tooltip line of the ribbon: events of others since the chronicle was last open
L.GLOG_BACK = "Back to the book"  -- word at the bottom right of the right page: closes the chronicle
L.GLOG_VIEW_HOLDERS = "Who has the book"  -- word tab of the right page: guildmates heard with Revenge Book
L.GLOG_VIEW_AVENGERS = "Avengers"  -- word tab: avengers of the week
L.GLOG_VIEW_CARD = "Week card"  -- word tab: the week's card of the guild
L.GLOG_TODAY = "TODAY"  -- day head in the chronicle (red, letter-spaced)
L.GLOG_YESTERDAY = "YESTERDAY"  -- day head in the chronicle
L.GLOG_LINE = "{text}, {time}"  -- a chronicle line: the sentence and how long ago ({time} = "3 min ago")
L.GLOG_LINE_PLACE = "{text}, {place}, {time}"  -- the same with the zone
L.GLOG_EV_DEATH = "{victim} was killed by {name}"  -- {victim} = a guildmate's first name, {name} = the killer
L.GLOG_EV_DEATH_ME = "You were killed by {name}"
L.GLOG_EV_AVENGED = "{by} took {name} down and avenged {victims}"  -- {by} = guildmate, {victims} = whom the killer had killed
L.GLOG_EV_AVENGED_ME = "You took {name} down and avenged {victims}"
L.GLOG_EV_TOOK = "{by} took {name} down"  -- a killer of the guild taken down (whom he killed is not in this book)
L.GLOG_EV_TOOK_ME = "You took {name} down"
L.GLOG_EV_BAG = "{by} took {name} off the hit list"  -- a target of the hit list killed
L.GLOG_EV_BAG_ME = "You took {name} off the hit list"
L.GLOG_EV_BOUNTY = "Bounty from {by} on {name}: {gold}"  -- {gold} = "50g"
L.GLOG_EV_BOUNTY_ME = "Your bounty on {name}: {gold}"
L.GLOG_EV_RELEASE = "{by} put {name} on the hit list"
L.GLOG_EV_RELEASE_ME = "You put {name} on the hit list"
L.GLOG_EV_OTHER = "{by}: {name}"  -- an event without words of its own (another part of the addon)
L.GLOG_VICTIMS_MORE = "{name} and {count} {count|other|others}"  -- several avenged: the newest and how many more
L.GLOG_VICTIM_YOU = "you"  -- an avenged victim that is the player ("Bertram took Grimm down and avenged you")
L.GLOG_HAVE = "{count} in the guild {count|has|have} the book"  -- head of "Who has the book" without the guild roster
L.GLOG_HAVE_ONLINE = "{count} of {total} online {count|has|have} the book"  -- head with the roster: online guildmates with the book of all online
L.GLOG_ME = "{name} (you)"  -- the own row
L.GLOG_ME_RANK = "{name} (you, {rank})"  -- the own row among the avengers, with the own rank of the rap sheet
L.GLOG_NOW = "now"  -- last heard: the own char
L.GLOG_ONLINE = "online now"  -- tooltip of a row
L.GLOG_HEARD = "last heard {time}"  -- tooltip of a row ({time} = "3 h ago")
L.GLOG_VERSION_OLD = "{version} · older"  -- a guildmate with an older version of the addon
L.GLOG_VERSION_UNKNOWN = "version ?"  -- no version heard yet
L.GLOG_HOLDERS_HINT = "Only those who sent something with Revenge Book are listed. Nobody is listed for not having it."  -- under the list
L.GLOG_RECOMMEND = "Recommend to the guild"  -- button: one line into the guild chat
L.GLOG_RECOMMEND_LINE = "I keep a Revenge Book: whoever kills one of us is written in, and the guild sees it. Free on CurseForge: Revenge Book."  -- the line the button sends to the guild chat (plain text, no link, no brackets)
L.GLOG_REC_WAIT = "Again in {minutes} min"  -- the button while it waits (once per 30 minutes)
L.GLOG_REC_SENT = "Sent to the guild chat."
L.GLOG_NO_GUILD_CHAT = "The guild chat is not available right now."
L.GLOG_AV_HEAD = "AVENGERS OF THE WEEK"  -- head (ink, letter-spaced): who took the most killers of the guild down in 7 days
L.GLOG_AV_EMPTY = "Nobody has taken a killer of the guild down this week."
L.GLOG_WANTED_HEAD = "MOST WANTED OF THE WEEK"  -- head: who killed the most guildmates in 7 days
L.GLOG_WANTED_N = "{count} {count|death|deaths}"  -- right of a most wanted on the avengers' page: how many deaths of guildmates he caused this week (deaths, not people: one guildmate killed three times is 3)
L.GLOG_WANTED_EMPTY = "No guildmate died this week."
L.GLOG_CARD_GUILD = "{guild}"  -- head of the week card: the guild's name (add a word only if your language needs one)
L.GLOG_CARD_NOGUILD = "Our guild"  -- the head without a guild name
L.GLOG_CARD_WEEK = "Week of {from} to {to}"  -- {from}, {to} = dates
L.GLOG_CARD_DEATHS = "{count} {count|death|deaths}"  -- big number on the card
L.GLOG_CARD_AVENGED = "{count} avenged"  -- big number on the card: killers taken down
L.GLOG_CARD_WANTED = "Most wanted {name} ({count})"  -- chat line and Discord block
L.GLOG_CARD_WANTED_NONE = "No most wanted"
L.GLOG_CARD_AVENGER = "Avenger of the week {name} ({count})"  -- chat line and Discord block
L.GLOG_CARD_AVENGER_NONE = "No avenger yet"
L.GLOG_CARD_WANTED_HEAD = "MOST WANTED"  -- label on the card
L.GLOG_CARD_AVENGER_HEAD = "AVENGER OF THE WEEK"  -- label on the card
L.GLOG_CARD_NAME_N = "{name} ({count})"  -- under a label of the card
L.GLOG_CARD_NONE = "nobody yet"  -- under a label when nobody is there
L.GLOG_LINE_WANTED = "most wanted ({count})"  -- segment of the chat line: the most wanted stands in the bracket before it
L.GLOG_DISCORD = "Copy for Discord"  -- button under the card: marks a block to copy
-- 1.6.0 call
L.BIND_HELP = "Call for help (guild, group, friends)"  -- key binding (1.6.0 call): send a help call with your position to guild, group and friends who use the addon
L.CALL_SENT = "Call for help sent to {list}."  -- chat and screen line after a help call went out; {list} = CALL_TO_GUILD, CALL_TO_GROUP, CALL_TO_FRIENDS joined by commas
L.CALL_TO_GUILD = "guild"  -- part of CALL_SENT: the guild got the call
L.CALL_TO_GROUP = "group"  -- part of CALL_SENT: the party or raid got the call
L.CALL_TO_FRIENDS = "friends ({count})"  -- part of CALL_SENT: {count} friends with the addon got the call
L.CALL_WAIT = "Next call for help in {seconds} s."  -- help call refused: one call per 30 seconds; {seconds} = seconds left
L.CALL_NO_LOCKDOWN = "No call for help: the chat is locked right now."  -- help call refused: the client blocks addon messages right now (chat lockdown)
L.CALL_NO_INSTANCE = "No call for help in dungeons, raids and battlegrounds."  -- help call refused: only in the open world
L.CALL_NO_PLACE = "No call for help: your position cannot be read here."  -- help call refused: the client gives no map position here
L.CALL_NO_ONE = "No call for help: no guild, group or friend with Revenge Book to reach."  -- help call refused: nobody to send it to (no guild, no group, no friend online with the addon)
L.CALL_FAILED = "Call for help not sent (code {code})."  -- help call: the client refused every way; {code} = technical result code
L.CALL_GCHAT_LINK = "Call in guild chat"  -- clickable word after CALL_SENT in the chat: posts a visible line in guild chat
L.CALL_GCHAT = "Help needed: {zone} ({x}, {y})"  -- the visible guild chat line (plain words, read by players without the addon); {zone} = zone name, {x} {y} = map coordinates in percent
L.CALL_GCHAT_BY = "Help needed: {zone} ({x}, {y}), attacker {name}"  -- as CALL_GCHAT with the attacker; {name} = his name
L.CALL_GCHAT_NO = "Not sent to guild chat: {reason}"  -- chat: the guild chat line was not sent; {reason} = why (combat, lockdown, wait)
L.CALL_IN = "{name} calls for help: {zone}"  -- a help call came in (chat line and the notice at the top of the screen); {name} = who calls, {zone} = zone name and CALL_SAME_ZONE or CALL_OTHER_ZONE in brackets
L.CALL_IN_BY = "{name} calls for help: {zone}, attacker {attacker}"  -- as CALL_IN with the attacker; {attacker} = his name
L.CALL_SAME_ZONE = "same zone"  -- in brackets after the zone of a help call: you are in the same zone
L.CALL_OTHER_ZONE = "other zone"  -- in brackets after the zone of a help call: you are elsewhere
L.CALL_SOMEWHERE = "unknown place"  -- zone name when the map ID has no name in this client
L.CALL_MAP = "Map"  -- clickable word in the chat after a help call or sighting: opens the world map there
L.CALL_TIP = "Click: open the map there · Right-click: close"  -- tooltip and last line of the help call notice: what the clicks do
L.CALL_BUTTON = "Call"  -- [max 8] small button on the grudge notice (after an attack): sends a help call; one short word
L.CALL_BUTTON_TIP = "Sends your position to guild, group and friends with Revenge Book."  -- tooltip of CALL_BUTTON (head: BIND_HELP)
L.SIGHT_LINE = "{name} seen by {by}: {zone}, {ago}."  -- quiet chat line: a guildmate or friend saw one of your killers; {name} = the killer, {by} = who saw him, {zone} = zone, {ago} = '3 min ago'
L.SIGHT_LINE_LAYER = "{name} seen by {by}: {zone}, {ago}, other layer."  -- as SIGHT_LINE when he is on another layer (shard) of the zone than you
L.SIGHT_OTHER_LAYER = "Other layer than yours"  -- map pin tooltip of a sighting: it was on another layer (shard) than yours
L.SCENE_TIP_CALL = "{caller} called for help here"  -- map pin tooltip head of a help call; {caller} = who called
L.SCENE_TIP_SIGHT = "{name} seen here by {by}"  -- map pin tooltip head of a sighting; {name} = the killer in class colour, {by} = who saw him
L.SCENE_TIP_ATTACKER = "Attacker: {name}"  -- map pin tooltip line of a help call: the attacker; {name} = his name
L.SCENE_LEG_CALL = "call for help"  -- [max 32] legend in the tooltip of the map's switch: the red pulsing pin = a help call
L.SCENE_LEG_SIGHT = "sighting"  -- [max 32] legend in the tooltip of the map's switch: the amber pin = a sighting of a killer by a guildmate or friend
L.OPT_G_LAYERSIGHT = "Sightings of my killers to guild & friends"  -- [max 44] check box (House Rules, sheet Guild, group SHARE): sightings of my killers go to guild and friends with place and layer, and theirs come in
L.PROBE_NET = "Net probe: own channel and yell tried once; results in two minutes (/dn probe)."  -- chat after '/dn probe net': the one-time test of an own chat channel and of yell has started
-- 1.6.0 deaths
L.FATE_VIEW_PLAYERS = "Players"  -- [max 12] Death Log, view word at the top right: only deaths by players (as before)
L.FATE_VIEW_ALL = "All"  -- [max 12] Death Log, view word: all deaths (players, creatures, the world) mixed by time; the default
L.FATE_VIEW_CAUSES = "Causes"  -- [max 12] Death Log, view word: the ranking of the creatures and the world that killed you
L.FATE_HEAD = "What else kills you"  -- [max 24] head of the right page in the view Causes (big handwriting)
L.FATE_CREATURE = "Unknown creature"  -- a creature whose name the game did not give
L.FATE_PET = "Pet without owner"  -- a pet (hunter pet, demon) whose owner is unknown, when the game gave no name
L.FATE_UNKNOWN = "Unknown"  -- a cause nobody can tell
L.FATE_ENV_FALL = "Falling"  -- cause of death: falling (environmental damage)
L.FATE_ENV_DROWN = "Drowning"  -- cause of death: drowning
L.FATE_ENV_FIRE = "Fire"  -- cause of death: fire on the ground
L.FATE_ENV_LAVA = "Lava"  -- cause of death: lava
L.FATE_ENV_FATIGUE = "Fatigue"  -- cause of death: fatigue (swimming too far out into deep water)
L.FATE_ENV_SLIME = "Slime"  -- cause of death: slime
L.FATE_ENV_OTHER = "The world"  -- cause of death: something of the world the game does not name
L.FATE_ART_CREATURE = "Creature"  -- [max 14] kind of cause (row mark, label above the name): a creature
L.FATE_ART_PET = "Pet"  -- [max 14] kind of cause: a pet without a known owner
L.FATE_ART_ENV = "Environment"  -- [max 14] kind of cause: the world (falling, drowning, fire ...)
L.FATE_SPELL = "last: {spell}"  -- row of the view Causes, after the place: the last spell; {spell} = spell name from the game
L.FATE_KILLED = "Killed you {times}"  -- file of a cause: how often it killed you; {times} = '3x'
L.FATE_NPC = "NPC ID {id}"  -- file of a creature: its NPC id; {id} = a number
L.FATE_NOTE = "No player. No alarm, nothing is shared."  -- file of a death by a creature or the world, under the name: what the book does with it
L.FATE_NOTE_FOE = "Creatures and the world, ranked. No alarm, no hunt."  -- file of a cause in the view Causes, under the name
L.FATE_NOTE_PET = "Killing blow by a pet whose owner is unknown: {name}."  -- file of an unclear death: a pet without a known owner dealt the killing blow; {name} = the pet's name
L.FATE_STAMP = "NEMESIS"  -- [max 18] stamp on the cause that killed you most often (from 3 deaths on), capitals
L.FATE_AWARDS = "FOR DYING"  -- [max 14] small label over the row of awards for dying on the rap sheet (letter-spaced, capitals)
L.FATE_AW_FALL = "Gravity Check"  -- award name: died from a fall
L.FATE_AW_FALL_COND = "Died from a fall."  -- award condition
L.FATE_AW_DROWN = "Deep End"  -- award name: drowned
L.FATE_AW_DROWN_COND = "Drowned."  -- award condition
L.FATE_AW_FIRE = "Well Done"  -- award name: burned (fire or lava)
L.FATE_AW_FIRE_COND = "Burned to death by fire or lava."  -- award condition
L.FATE_AW_FATIGUE = "Too Far Out"  -- award name: fatigue in deep water
L.FATE_AW_FATIGUE_COND = "Swam out too far and died of fatigue."  -- award condition
L.FATE_AW_BEAST3 = "Favourite Snack"  -- award name: the same creature killed you 3 times
L.FATE_AW_BEAST3_COND = "Killed three times by the same creature."  -- award condition
L.FATE_AW_BEAST10 = "On the Menu"  -- award name: the same creature killed you 10 times
L.FATE_AW_BEAST10_COND = "Killed ten times by the same creature."  -- award condition
L.FATE_AW_STREAK = "Bad Streak"  -- award name: three deaths in ten minutes
L.FATE_AW_STREAK_COND = "Three deaths by creatures or the world within ten minutes."  -- award condition
L.FATE_AW_ZOO = "Field Guide"  -- award name: killed by ten different creatures
L.FATE_AW_ZOO_COND = "Killed by ten different creatures."  -- award condition
L.OPT_FATES = "Also record deaths by creatures and the world"  -- check box in the foot of the file of a death by a creature or the world (Death Log): also record deaths by creatures and the world (default on; off = nothing new, what is there stays)
L.SHARE_WEEK_OTHERS = "other deaths: {count}"  -- week line: deaths by creatures and the world this week
L.SHARE_WEEK_BEAST = "deadliest creature: {name} {times}"  -- week line: the creature that killed you most this week; {name} = its name, {times} = '3x'
-- 1.6.0 feud
L.FEUD_EXPIRED_CHAT = "{count} old suspicions filed away (Unsolved, Filed away)."  -- chat, once after login: entries with only suspicions or only attacks and no news for 30 play days were filed away; {count} = how many; where to find them (tab Unsolved, view Filed away = VIEW_FILED)
L.VIEW_PLAYERS = "Players"  -- word switch at the bottom left of Wanted: the list of players (as before)
L.VIEW_GUILDS = "Guilds"  -- word switch at the bottom left of Wanted: the page 'Which guilds kill you'
L.VIEW_OPEN = "Cases"  -- word switch at the bottom left of Unsolved: open cases and suspects (as before)
L.VIEW_CLAIMS = "Claims"  -- word switch at the bottom left of Unsolved: claims on your own bounties (a number may follow)
L.VIEW_FILED = "Filed away"  -- word switch at the bottom left of Unsolved: old suspicions filed away (a number may follow)
L.FEUD_MEMBERS = "{count} in book"  -- guild row, right, and tooltip: how many of this guild are in your book; {count} = number
L.FEUD_KILLED_YOU = "killed you {times}"  -- guild row sub line: how often players of this guild killed you; {times} = '3×'
L.FEUD_DECLARE = "Declare feud"  -- small word on a guild row and button: declare a feud on this guild (quiet alarm when its members show up)
L.FEUD_END = "End feud"  -- small word on a guild row and button: end the feud with this guild
L.FEUD_TIP_ON = "Feud: one of them in sight sounds a quiet alarm, once in 5 minutes."  -- tooltip of a guild row with a feud: what the feud does
L.FEUD_TIP_CLICK = "Click: show or hide its members"  -- tooltip of a guild row: what a click does
L.FEUD_ALARM = "Guild {guild}: feud. {name} in sight."  -- chat line with the quiet alarm: a member of a feud guild who is not in your book is in sight; {guild} = guild name, {name} = player name
L.FEUD_CAP = "No more feuds: at most {count}."  -- chat: no more feuds possible; {count} = the limit (50)
L.EMPTY_FGUILDS_HEAD = "No guild known yet."  -- right page, guild page of Wanted with no guild known
L.EMPTY_FGUILDS_SUB = "The book notes the guild of every killer it sees."  -- under it
L.EMPTY_FCLAIMS_HEAD = "No claims."  -- right page, Unsolved > Claims without any claim
L.EMPTY_FCLAIMS_SUB = "When guild or friends take down a target of your bounty, the claim stands here."  -- under it: what a claim is
L.EMPTY_FFILED_HEAD = "Nothing filed."  -- right page, Unsolved > Filed without any entry
L.EMPTY_FFILED_SUB = "Suspicions and attacks with no news for 30 play days are filed here."  -- under it: what is filed
L.CLAIM_LINE = "{name} got your target {target}: {gold} gold owed"  -- notice, chat and claim page: a guildmate or friend killed a target of your own bounty; {name} = his first name, {target} = the target, {gold} = whole gold (number); the addon pays nothing
L.CLAIM_BY = "by {name}"  -- claim row, sub line: who claims it; {name} = first name
L.CLAIM_OPEN = "open"  -- mark of a claim: not settled yet
L.CLAIM_PAID = "paid"  -- mark of a claim: you paid it (by trade, yourself)
L.CLAIM_DECLINED = "declined"  -- mark of a claim: you declined it
L.ACT_PAID = "Mark as paid"  -- button on a claim: you paid it yourself (by trade or mail) and tick it off; the book pays nothing
L.ACT_DECLINE = "Decline"  -- button on a claim: decline it
L.ACT_REOPEN = "Open again"  -- button on a settled claim: open again
L.BANNER_CLAIM = "Bounty due"  -- kicker of the notice (letter-spaced): a bounty of yours was earned and is due
L.FILED_SINCE = "filed {time}"  -- row of a filed entry, sub line; {time} = '3 days ago'
L.FILED_TINY = "Filed on {time} after 30 play days without news. Take it back and it stays."  -- page of a filed entry: why it is there and what taking it back does; {time} = date
L.ACT_RESTORE = "Take back"  -- word and button: take a filed entry back into the book
L.ACT_KEEP = "Keep"  -- row menu and poster menu: never file this entry away
L.ACT_UNKEEP = "Keep no longer"  -- row menu and poster menu: may be filed away again
L.OPT_BOOK_EXPIRE = "File away old suspicions"  -- check box, House Rules, sheet Book: suspicions and attacks without news for 30 play days go to Unsolved > Filed
L.SET_SEC_ORDER = "ORDER"  -- section label on the House Rules, sheet Book (capitals like the other sections)
L.OPTIONS_LINE = "Remembers who killed you and warns you when they come near. All settings are in the book's House Rules."  -- the addon's page in the game's options (Esc > Options > AddOns): one line
L.OPTIONS_OPEN = "Open House Rules"  -- button on that page: opens the book on the House Rules
-- 1.6.0 wiring
L.GLOG_EV_CALL = "{by} called for help: {zone}"  -- guild chronicle line: a guildmate or friend called for help; {by} = who called, {zone} = the zone (a link to the map in the margin)
L.GLOG_EV_CALL_BY = "{by} called for help: {zone}, attacker {name}"  -- as GLOG_EV_CALL with the attacker the caller named; {name} = the attacker
L.GLOG_EV_SIGHT = "{by} saw {name}: {zone}"  -- guild chronicle line: a guildmate or friend saw one of the killers; {by} = who saw him, {name} = the killer, {zone} = the zone
L.GLOG_EV_SIGHT_N = "{name} seen {count}×, last by {by}: {zone}"  -- sightings of the same killer within 10 minutes are one line: {count} = how often, {by} = who saw him last
L.CHAT_NEWS_160 = "New in 1.6.0: the {log} tab keeps every death now, also by creatures and the world. The guild chronicle is behind the red ribbon in the {guild} tab; a call for help brings guild and friends to you (set a key: Esc > Options > Key Bindings > Revenge Book). Sightings of your killers now go to guild and friends (turn off: {rules}, {sheet}: {switch})."  -- chat, once per account after the update to 1.6.0 for players who had the book before: every death in the Death Log, the guild chronicle behind the red ribbon, the call for help (key bindings menu, the client's own words), sightings of your killers go to guild and friends now and where the switch is; {log}, {guild} = tab words, {rules} = House Rules, {sheet} = the sheet Guild, {switch} = the check box
-- 1.6.0 fixer
L.FATE_NOTE_ENV = "Killing blow by the world: {name}."  -- file of an unclear death: a player hurt you, the world dealt the killing blow (a fall after a knockback, lava, drowning); {name} = the cause word (Falling, Lava ...)
L.OPT_G_LAYERSIGHT_TIP = "When you see a player who killed you, a guildmate or a friend in the last 30 days, is on the hit list or carries a bounty, his name, your place with its layer and the time go to guild and friends with Revenge Book. Their sightings come to you. Nothing else goes out."  -- tooltip of the check box OPT_G_LAYERSIGHT: exactly what goes out, when and to whom; 30 days = Call.lua SIGHT_DAYS
L.EMPTY_WANTED_FATES = "Deaths by creatures and the world are in the {log}."  -- tab Wanted, empty, once the Death Log holds deaths by creatures or the world: where they are; {log} = the tab's name
L.EMPTY_JPLAYERS_HEAD = "No death by a player yet."  -- Death Log, view Players, empty while other deaths (creatures, the world) are there: big line
L.EMPTY_JPLAYERS_SUB = "So far creatures and the world see to that (view {all})."  -- under it, dry joke; {all} = the view word All (FATE_VIEW_ALL), where the other deaths are
-- 1.6.0 design
L.CALL_SLIP_HEAD = "Call for help"  -- kicker of the help call's slip (letter-spaced, red, like the bounty notice's kicker): a guildmate or friend calls for help
L.CALL_SLIP_BY = "{zone} · attacker {attacker}"  -- third line of the help call's slip (under the caller's name): the place and the attacker; {zone} = 'Ashenvale (same zone)', {attacker} = his name
L.GLOG_LINE_AT = "{text}, {place}"  -- guild chronicle line with the zone, without the time (the time stands apart at the right edge); {text} = the sentence, {place} = the zone
L.FATE_LIST_HEAD = "Deaths by this cause"  -- section label on the file of a creature or the world (letter-spaced, like DEEDS on the poster): the list of your deaths by this same cause follows; the count stands on the right
L.FATE_FIRST_LAST = "First {first}, last {last}"  -- under that list: the first and the latest death by this cause; {first}, {last} = date and time
L.GLOG_OLD_N = "Older version: {count}"  -- guild chronicle, who has the book: one quiet line under the list, how many have an older version of the addon (the rows say it in faint ink); {count} = a number
L.SHEET_CLAIM = "Claim"  -- head of the sheet on the right page for one claim on your bounty (tab Unsolved, view Claims)
L.CLAIM_HEAD = "{gold} to {name}"  -- big line of a claim's sheet: what you owe to whom; {gold} = '250g' (the book's money word), {name} = the hunter's first name
L.CLAIM_FOR = "for {target}"  -- under it: for which of your targets; {target} = the target's name
L.CLAIM_NOTE = "The book pays nothing itself: by trade or mail."  -- small line on an open claim's sheet: the book moves no money
L.FEUD_SHEET_HEAD = "Guild"  -- head of the sheet on the right page for an enemy guild (tab Wanted, view Guilds), big like CASE_HEAD
L.FATE_LAST = "last {time}"  -- date at the top right of a cause's file: the latest death by it; {time} = date and time
-- 1.6.1 deeds
L.VICTIM_DEEDS_LABEL = "THEIR DEEDS"  -- [max 14] small label on the sheet of one of your victims (rap sheet), over the list of what HE did: whom he killed and when (you, your other characters, guildmates, friends); letter-spaced, below the label VICTIM_KILLS_LABEL
L.VICTIM_DEED_TIP = "Their last victim: {name}, {time}"  -- tooltip line of a victim's row in the rap sheet: his newest killing blow; {name} = first name of the one he killed, {time} = date and time
-- 1.6.3 keep
L.OPT_BOOK_EXPIRE_TIP = "Suspicions and attacks with no news for 30 play days move to Unsolved, \"Filed away\". Right-click an entry and choose \"Keep\": it is never filed away."  -- tooltip of the check box OPT_BOOK_EXPIRE (House Rules, sheet Book): what is filed away and where it goes (tab Unsolved, view VIEW_FILED), and how to hold an entry back: the menu word ACT_KEEP; quote both words exactly as your language file has them
-- 1.6.4 move
L.HELP_MOVE = "/dn move  move the alarm and the notices (/dn move reset: default places)"  -- /dn help line after HELP_TEST: the placing mode; "/dn move reset" puts every place back
L.SET_MOVE = "Move alarm"  -- [max 24] button on the House Rules, sheet Alert, next to SET_TEST_ALERT (132 to 180 px): starts the placing mode, the book closes
L.MOVE_HEAD = "Move mode"  -- [max 24] letter-spaced head of the bar above the action bars while the placing mode runs (320 px, 10/9 pt)
L.MOVE_HOW = "Drag the alarm and the notices with the left mouse button. Right-click, Esc or /dn move: done."  -- line of that bar (up to two lines, 320 px, 11/10 pt): how to move and how to finish; name the left mouse button, right-click, Esc and the command
L.MOVE_DRAG = "Drag to move"  -- [max 24] on each sample of the placing mode (alarm hint, notice line, help call slip, grudge notice): what to do with it
L.MOVE_RESET = "Reset positions"  -- [max 24] button on that bar (132 to 180 px): every place back to its default
L.MOVE_DONE = "Done"  -- [max 17] button on that bar (96 to 140 px): ends the placing mode
L.MOVE_COMBAT = "Not in combat: the alarm and the notices can be moved after the fight."  -- chat: /dn move (or the button) in combat; nothing else happens
L.MOVE_RESET_DONE = "The alarm and the notices are back in their default places."  -- chat after Reset positions or /dn move reset
L.CHAT_TEST_MOVE = "To move the alarm: /dn move (or {rules} > {sheet} > {button})."  -- chat after /dn test: how to move the alarm; {rules} = House Rules, {sheet} = the sheet Alert, {button} = SET_MOVE
L.CHAT_NEWS_164 = "New in 1.6.4: /dn move shows the alarm and the notices, drag them where you want them (also {rules} > {sheet} > {button})."  -- chat, once per account after the update to 1.6.4 for players who had the book before; {rules}, {sheet}, {button} as in CHAT_TEST_MOVE
L.MOVE_ENDED = "Move mode ended. /dn move starts it again."  -- chat when something ended the placing mode by itself (a new alarm, a notice, a help call, a grudge notice, combat, death, a loading screen): only that it ended and how to start it again, no list of causes
L.MOVE_NAME_NOTICE = "Notice"  -- [max 24] name on the sample of the notice in the placing mode (its letter-spaced red head, 300 px, 10/9 pt): the notice after a death, a revenge, a guild death; the alarm's sample is named SHEET_ALERT, the help call's CALL_SLIP_HEAD
L.MOVE_NAME_GRUDGE = "Grudge notice"  -- [max 24] name on the sample of the grudge notice in the placing mode (its letter-spaced head, 194 px, 10/9 pt): the small notice on the right after an attack; take the word of SET_SEC_GRUDGE
end)
