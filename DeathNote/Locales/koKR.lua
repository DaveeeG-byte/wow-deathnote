-- DeathNote: 한국어 (koKR).
-- Plural: 1 form {count|other} (no plural). Rule in Locale.lua (PLURAL_OF.koKR), not here.
-- Fonts: korean (2002, 2002B) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Terms: book 수첩, guild book 길드 수첩, friends' book 친구 수첩, killer 범인, guildmate 길드원,
-- Hit List 척살 명단, call 척살령. No particle is attached to {name}/{zone}: colon forms instead.
--
-- TOC-Notes: 필드 PvP 복수 수첩: 너를 죽인 자를 기억하고, 가까이 오면 알려 준다.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("koKR")) then return end

Locale.Register("koKR", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "수배"  -- [max 16]
L.TAB_UNSOLVED = "미해결"  -- [max 16]
L.TAB_DEATHLOG = "사망 기록"  -- [max 16]
L.TAB_GUILD = "길드"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "이용 규칙"  -- [max 24]
L.HEAD_HELP = "사용법"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "수첩"  -- [max 14]
L.SHEET_ALERT = "경보"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "공공의 적 1호"  -- [max 24]
L.STAMP_REVENGE = "복수 완료"  -- [max 16]
L.STAMP_PARDONED = "사면됨"  -- [max 16]
L.STAMP_SUSPECT = "용의자"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "공공의 적 1호 발견"  -- [max 30]
L.ALERT_SIGHTED = "공공의 적 발견"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "용의자 발견"  -- [max 30]
L.ALERT_TITLE_GUILD = "길드의 적 발견"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "친구를 죽인 범인 발견"  -- [max 30]
L.ALERT_TITLE_HUNT = "척살 대상"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "혐의를 받는 중"
L.ALERT_LINE_KILLED = "너를 {times} 죽임"
L.ALERT_LINE_KILLED_ASSISTED = "너를 {times} 죽임, {assists} 가담"
L.ALERT_LINE_ASSISTED = "네 죽음에 {times} 가담"
L.ALERT_LINE_MANUAL = "수첩에 직접 기록됨"
L.ALERT_LINE_LAST = "{text}, 최근 {time}"
L.ALERT_LINE_IN = "{text}, 장소: {zone}"
L.ALERT_LINE_REVENGE = "{text}. 복수: {times}"
L.ALERT_HINT_CLOSE = "오른쪽 클릭: 닫기"  -- [max 44]
L.ALERT_HINT_COMBAT = "전투가 끝나야 대상 지정 가능"  -- [max 44]
L.ALERT_HINT_TARGET = "클릭: 대상 지정  ·  오른쪽 클릭: 닫기"  -- [max 44]
L.ALERT_MORE = "외 {count}건"  -- [max 14]
L.SAMPLE_ZONE = "가시덤불 골짜기"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "길드 수첩에 있음"
L.GUILD_LINE_IN_FRIENDS = "친구 수첩에 있음"
L.GUILD_LINE_LISTED_BY = "{names}의 수첩에 있음"
L.GUILD_LINE_KILLED_GUILD = "길드원을 {kills}회 죽임"
L.GUILD_LINE_KILLED_FRIENDS = "친구를 {kills}회 죽임"
L.GUILD_LINE_KILLED_BOTH = "길드원과 친구를 {kills}회 죽임"
L.GUILD_LINE_LAST = "{text}, 최근 피해자: {name}"
L.HUNT_LINE_BY = "척살령을 내린 사람: {names}"
L.HUNT_LINE_RELEASED = "척살 명단에 있음"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}회"
L.TALLY_SUSPECT = "혐의 있음"
L.TALLY_MANUAL = "직접 추가"
L.TALLY_NONE = "아직 범행 없음"
L.TALLY_KILLED = "너를 {times} 죽임"
L.TALLY_ASSISTED = "{times} 가담"
L.PLACE_UNKNOWN = "알 수 없는 장소"
L.GKILLS_CAP = "최소 {count}"
L.NAMELIST_MORE = "{names} 외 {count}명"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%m.%d %H:%M"
L.TIME_FMT_WHEN_YEAR = "%Y.%m.%d %H:%M"
L.TIME_FMT_DAY = "%m.%d"
L.TIME_FMT_DAY_YEAR = "%y.%m.%d"
L.TIME_NEVER = "없음"
L.TIME_JUST = "방금"
L.TIME_MINUTES = "{count}분 전"  -- [max 14]
L.TIME_HOURS = "{count}시간 전"  -- [max 14]
L.TIME_DAYS = "{count}일 전"  -- [max 16]
L.MONEY_GOLD = "{count}골드"
L.MONEY_SILVER = "{count}실버"
L.MONEY_COPPER = "{count}코퍼"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "DeathNote를 쓰는 길드원 {count}명 확인."
L.HEALTH_NOGUILD = "길드가 없어서 아무것도 공유하지 않는다."
L.HEALTH_OFF = "공유가 꺼져 있다."
L.HEALTH_SHORT_NOGUILD = "길드 없음"  -- [max 18]
L.HEALTH_SHORT_OFF = "공유 꺼짐"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "차단됨"  -- [max 18]
L.HEALTH_SHORT_FAILING = "거부됨"  -- [max 18]
L.HEALTH_SHORT_HOLD = "대기 중"  -- [max 18]
L.HEALTH_SHORT_ASKED = "요청함"  -- [max 18]
L.HEALTH_SHORT_FAIL = "작동 안 함"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "소리 없음"  -- [max 16]
L.SOUND_RAIDWARNING = "공격대 경보"  -- [max 16]
L.SOUND_BELL = "종"  -- [max 16]
L.SOUND_GONG = "징"  -- [max 16]
L.SOUND_HEARTBEAT = "심장 박동"  -- [max 16]
L.SOUND_FEATHER = "깃펜"  -- [max 16]
L.SOUND_SIREN = "사이렌"  -- [max 16]
L.CHANNEL_MASTER = "주 음량"  -- [max 16]
L.CHANNEL_SFX = "효과음"  -- [max 16]
L.CHANNEL_DIALOG = "대화"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "수첩에 기록됨: {name}"
L.CHAT_REMOVED = "수첩에서 지움: {name}"
L.CHAT_SYNC_WAIT = "방금 동기화했다. {seconds}초 뒤에 다시 해 봐."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "아직 아무 이름도 없다."
L.EMPTY_WANTED_SUB = "가끔은 밖에도 나가 봐."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  수첩 열기/닫기"
L.HELP_ADD = "/dn add <이름 [성]>  범인을 수첩에 직접 기록"
L.HELP_DEL = "/dn del <이름 [성]>  범인을 수첩에서 지우기"
L.HELP_QUIET = "/dn quiet  경보 끄기/켜기"
L.HELP_TEST = "/dn test  테스트 경보 보기"
L.HELP_GUILD = "/dn guild  길드 수첩: 상태와 DeathNote를 쓰는 길드원"
L.HELP_FRIENDS = "/dn friends  친구 수첩: 상태와 DeathNote를 쓰는 친구"
L.HELP_SYNC = "/dn sync  길드 수첩과 친구 수첩을 지금 동기화"
L.HELP_HUNT = "/dn hunt <이름 [성]>  척살 명단에 올리기 (이름 없이: 척살 명단 보기)"
L.HELP_CALLOFF = "/dn calloff <이름 [성]>  내 척살령 철회"
L.HELP_LANG = "/dn lang <코드>  수첩 언어 (enUS, deDE, frFR ...), /reload 후 적용"
L.HELP_THEME = "/dn theme <이름>  수첩 표지, /reload 후 적용"
L.HELP_PROBE = "/dn probe  문제 해결: 게임이 수첩에 알려 주는 것"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  문제 해결, 전투 기록도 검사"
L.HELP_DEBUG = "/dn debug  문제 해결: 모든 죽음을 자세히 기록 (켜기/끄기)"
L.HELP_HELP = "/dn help  이 도움말"
L.HELP_SILENT_ZONES = "던전, 전장, 투기장에서는 수첩이 알아서 조용해진다."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "켜짐"
L.WORD_OFF = "꺼짐"
L.CHAT_WHO_ADD = "누구? /dn add <이름>"
L.CHAT_WHO_DEL = "누구? /dn del <이름>"
L.CHAT_WHO_CALLOFF = "누구? /dn calloff <이름>"
L.CHAT_BAD_NAME = "잘못된 이름."
L.CHAT_NOT_IN_BOOK = "수첩에 없음: {name}"
L.CHAT_ALARM_ON = "경보 켜짐."
L.CHAT_ALARM_OFF = "경보 꺼짐."
L.CHAT_DEBUG = "문제 해결 기록: {state}."
L.CHAT_UNKNOWN_CMD = "알 수 없는 명령어. 도움말: /dn help"
L.CHAT_GUILD_NOT_LOADED = "길드 수첩을 불러오지 못했다."
L.CHAT_NO_GUILD = "길드가 없다 (또는 게임이 아직 모른다)."
L.CHAT_GUILD_STATE = "길드 {guild}: 공유 {share}, 수신 {receive}."
L.CHAT_GUILD_BOOK = "길드 수첩: 범인 {enemies}명 (그중 {listed}명은 직접 추가만), 범행 {deeds}건, 다른 길드원 관련 {foreign}명. 직접 추가 항목 공유: {manual}."
L.CHAT_STATE_OK = "상태: {text}"
L.CHAT_STATE_WARN = "주의: {text}"
L.CHAT_NO_MATES = "DeathNote를 쓰는 길드원을 아직 찾지 못했다."
L.CHAT_HAVE_DN = "DeathNote 사용 중: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote 사용 중: {names} 외 {count}명"
L.CHAT_SYNC_ASKED = "동기화를 요청했다. 몇 초 안에 답이 온다."
L.CHAT_SYNC_FAIL = "동기화 불가: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "길드가 없거나 공유가 꺼져 있다."
L.CHAT_FRIENDS_NOT_LOADED = "친구 수첩을 불러오지 못했다."
L.CHAT_FRIENDS_STATE = "친구: 공유 {share}, {total}명 중 {online}명 접속 중."
L.CHAT_FRIENDS_BOOK = "친구 수첩: 범인 {enemies}명 (그중 {listed}명은 직접 추가만), 범행 {deeds}건."
L.CHAT_NO_FRIENDS = "DeathNote를 쓰는 친구를 아직 찾지 못했다."
L.CHAT_HUNT_NOT_LOADED = "척살 명단을 불러오지 못했다."
L.CHAT_HUNT_UNKNOWN = "알 수 없음: {name}. 게임에 표시되는 대로 성까지 입력해."
L.CHAT_HUNT_CAP = "척살 명단에 올릴 수 없다: 명단마다 네 척살령은 최대 {own}개, 대상은 최대 {targets}명."
L.CHAT_HUNT_NOWHERE = "지금은 척살 명단에 올릴 수 없다: 길드가 없고 친구와 공유도 꺼져 있다."
L.CHAT_HUNT_BOTH = "척살 명단에 오름 (길드와 친구): {name}"
L.CHAT_HUNT_GUILD = "척살 명단에 오름 (길드): {name}"
L.CHAT_HUNT_FRIENDS = "척살 명단에 오름 (친구): {name}"
L.CHAT_CALLED_OFF = "척살 철회: {name}"
L.CHAT_NO_OWN_CALL = "네가 내린 척살령이 없다: {name}"
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "현재 언어: {lang}. 변경: /dn lang <코드>"
L.CHAT_LANG_LIST = "코드: {codes}"
L.CHAT_LANG_BAD = "알 수 없는 언어: {code}"
L.CHAT_LANG_SET = "언어: {lang}."
L.CHAT_LANG_RELOAD = "언어: {lang}. /reload 후 적용."
L.CHAT_THEME_CURRENT = "현재 표지: {theme}. 변경: /dn theme <이름>"
L.CHAT_THEME_LIST = "표지 목록: {themes}"
L.CHAT_THEME_BAD = "알 수 없는 표지: {name}"
L.CHAT_THEME_SET = "표지: {theme}."
L.CHAT_THEME_RELOAD = "표지: {theme}. /reload 후 적용."
L.THEME_NOTEBOOK = "검은 수첩"
L.THEME_HARBOR = "Privateer's Ledger"  -- TODO translate (English placeholder)
L.THEME_TRADE = "The Workshop"  -- TODO translate (English placeholder)

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "수첩이 준비됐다. 필드에서 너를 죽인 자는 그 뒤로 여기에 적힌다. /dn이나 미니맵 버튼으로 연다."
L.WELCOME_PLATES = "적 이름표가 꺼져 있다. 이름표가 없으면 경보는 네 대상만 본다."
L.WELCOME_SHARE = "DeathNote를 쓰는 길드원과 친구도 함께 본다. 메모와 혐의는 너만 본다."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "수첩:"
L.TIP_HUNT = "척살 명단:"
L.TIP_GUILDBOOK = "길드 수첩:"
L.TIP_PARDONED = "사면됨"
L.TIP_RANK = "{rank}위"
L.TIP_REVENGE = "복수 {times}"
L.TIP_LISTED_BY = "{names}의 수첩에 있음"
L.TIP_NOTE = "메모: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "클릭: 열기 · 오른쪽 클릭: 닫기"
L.BANNER_NEW = "새 기록"  -- [max 24]
L.BANNER_NEW_LINE = "수첩에 기록됨"
L.BANNER_AGAIN = "또 당했다"  -- [max 24]
L.BANNER_AGAIN_LINE = "또 너를 죽였다, 벌써 {count}번째"
L.BANNER_SUSPECT = "혐의"  -- [max 24]
L.BANNER_SUSPECT_LINE = "혐의를 받는 중, 수첩에서 가려내"
L.BANNER_UNCLEAR = "범인 불명"  -- [max 24]
L.BANNER_CANDIDATES = "후보 {count}명"
L.BANNER_UNCLEAR_LINE = "클릭: 미해결에서 범인 지정"
L.BANNER_REVENGE = "되갚았다"  -- [max 24]
L.BANNER_REVENGE_LINE = "복수 완료 ({count}회)"
L.BANNER_GUILD = "길드"  -- [max 24]
L.BANNER_FRIENDS = "친구"  -- [max 24]
L.BANNER_KILLED_BY = "살해됨, 범인: {name}"
L.BANNER_HUNT = "척살 명단"  -- [max 24]
L.BANNER_BAGGED = "처치한 사람: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "공유가 꺼져 있다 (이용 규칙, 길드 탭)."
L.SYNC_FRIENDS_OFF = "친구와 공유가 꺼져 있다."
L.SYNC_NOBODY = "공유할 길드도 친구도 없다."
L.SYNC_SHORT_NOBODY = "공유 없음"  -- [max 18]
L.SYNC_PREFIX = "게임이 수신을 허용하지 않는다. 다시 접속하면 해결된다."
L.SYNC_SHORT_PREFIX = "수신 불가"  -- [max 18]
L.SYNC_BLOCKED = "서버가 전송을 막고 있다. 수첩 백업으로 전달해."
L.SYNC_SHORT_BLOCKED = "서버가 전송 차단"  -- [max 22]
L.SYNC_FAILING = "지금은 전송이 안 된다. 다시 시도하는 중."
L.SYNC_SHORT_FAILING = "전송 지연"  -- [max 18]
L.SYNC_HOLD = "전송 대기: {wait}."
L.SYNC_HOLD_INSTANCE = "인스턴스를 나갈 때까지"
L.SYNC_HOLD_COMBAT = "전투가 끝날 때까지"
L.SYNC_HOLD_LOCKDOWN = "채팅이 다시 풀릴 때까지"
L.SYNC_HOLD_AGAIN = "다시 될 때까지"
L.SYNC_HOLD_SHORT_INSTANCE = "대기: 인스턴스"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "대기: 전투"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "대기: 채팅"  -- [max 18]
L.SYNC_QUIET = "보냈지만 DeathNote를 쓰는 길드원은 아직 없다."
L.SYNC_READY = "준비됨. DeathNote를 쓰는 길드원은 아직 없다."
L.SYNC_RUNNING = "작동 중: DeathNote를 쓰는 길드원 {count}명."
L.SYNC_RUNNING_ALL = "작동 중: 길드와 친구 중 DeathNote 사용자 {count}명."
L.FRIENDS_OFF = "친구와 공유가 꺼져 있다 (이용 규칙, 길드 탭)."
L.FRIENDS_BLOCKED = "서버가 귓속말을 막고 있다. 친구에게 아무것도 가지 않는다."
L.FRIENDS_SHORT_BLOCKED = "서버가 귓속말 차단"  -- [max 22]
L.FRIENDS_FAILING = "지금은 귓속말이 안 된다. 다시 시도하는 중."
L.FRIENDS_SHORT_FAILING = "귓속말 지연"  -- [max 18]
L.FRIENDS_NONE_LISTED = "친구 목록에 친구가 없다."
L.FRIENDS_NONE_ONLINE = "지금 접속한 친구가 없다."
L.FRIENDS_SHORT_NONE_ONLINE = "접속한 친구 없음"  -- [max 18]
L.FRIENDS_QUIET = "물어봤지만 DeathNote를 쓰는 친구는 아직 없다."
L.FRIENDS_READY = "준비됨. DeathNote를 쓰는 친구는 아직 없다."
L.FRIENDS_HOLD = "친구에게 보내기는 다시 될 때까지 대기한다."
L.FRIENDS_RUNNING = "작동 중: DeathNote를 쓰는 친구 {count}명."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "길드 수첩에서 가져옴 (길드원을 {kills}회 죽임)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "데이터베이스를 불러오지 못했다."
L.IMPORT_NO_TEXT = "텍스트가 없다."
L.IMPORT_NO_HEADER = "첫 줄이 없다 (시작: {header}). 텍스트 전체를 복사해."
L.IMPORT_NOT_EXPORT = "DeathNote 내보내기가 아니다 (머리줄이 없거나 버전이 다르다)."
L.IMPORT_TOO_LONG = "줄이 너무 많다 (최대 {count}줄)."
L.IMPORT_BAD_KEY = "{line}번째 줄: 잘못된 키."
L.IMPORT_BAD_TIME = "{line}번째 줄: 잘못된 시간."
L.IMPORT_BROKEN = "{line}번째 줄이 불완전하거나 깨졌다 (텍스트가 잘렸나?). 아무것도 가져오지 않았다."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "예"
L.WORD_NO = "아니요"
L.PROBE_HEAD = "점검: 인터페이스 {apis}/{apisAll}개 있음, 이벤트 {events}/{eventsAll}개 등록 가능."
L.PROBE_MISSING = "없음: {list}"
L.PROBE_NOT_REGISTERABLE = "등록 불가: {list}"
L.PROBE_SOURCES = "현재 Recap: {recap} · Meter: {meter} · 전투 기록: {clog}"
L.PROBE_READABLE = "읽기 가능"
L.PROBE_DEAD = "작동 안 함"
L.PROBE_PLATES = "적 이름표: {plates} · 필드: {open}"
L.PROBE_PLATES_OFF = "꺼짐 (대상과 마우스 오버로만 플레이어 감지)"
L.PROBE_TARGET = "대상: 이름={name} GUID={guid} 직업={class} 적대={enemy} 나를 대상={me}"
L.PROBE_GUILD = "길드: 접두어 {prefix} · 전송 {send} · 마지막 반환값 {result} · 보냄 {sent}, 받음 {received}, 버림 {dropped}"
L.PROBE_REGISTERED = "등록됨"
L.PROBE_NOT_REGISTERED = "등록 안 됨 ({result})"
L.PROBE_POSSIBLE = "가능"
L.PROBE_ABSENT = "없음"
L.PROBE_WAITS = " · 대기: {why}"
L.PROBE_LISTED = "직접 추가 (M): 보냄 {sent}, 받음 {received}, 버림 {dropped} · 지움 (X): 보냄 {usent}, 받음 {ureceived}, 버림 {udropped}"
L.PROBE_GUILDBOOK = "길드 수첩: {text}"
L.PROBE_SAVED = "DeathNoteDB.probe에 저장됨 (/reload 후 파일에 기록)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "순위"  -- [max 14]
L.SORT_RECENT = "최신"  -- [max 14]
L.SORT_NAME = "이름"  -- [max 14]
L.SORT_SEEN = "목격"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "필드에서 너를 죽인 자는 여기에 적힌다. 저절로."
L.EMPTY_OPEN_HEAD = "미해결 사건 없음."
L.EMPTY_JOURNAL_HEAD = "아직 한 번도 안 죽었다."
L.EMPTY_JOURNAL_SUB = "존경한다. 아니면 거짓말이거나."
L.EMPTY_NOGUILD_HEAD = "길드 없음."
L.EMPTY_NOGUILD_SUB = "혼자서도 잘만 죽는다."
L.EMPTY_GUILDOFF_HEAD = "길드 수첩이 닫혀 있다."
L.EMPTY_GUILDOFF_SUB = "공유가 꺼져 있다. 어디서 켜는지는 이용 규칙에 있다."
L.EMPTY_GUILDNIL_HEAD = "길드에서 아직 소식이 없다."
L.EMPTY_GUILDNIL_SUB = "길드원 중 누군가 DeathNote를 쓰면 네 수첩이 전달된다."
L.EMPTY_GUILDQUIET_HEAD = "길드 수첩에 아직 아무것도 없다."
L.EMPTY_GUILDQUIET_SUB = "길드원들은 지금까지 무사했다."
L.EMPTY_FRIENDSOFF_HEAD = "친구 수첩이 닫혀 있다."
L.EMPTY_FRIENDSOFF_SUB = "친구와 공유가 꺼져 있다. 어디서 켜는지는 이용 규칙에 있다."
L.EMPTY_FRIENDSNIL_HEAD = "DeathNote를 쓰는 친구를 아직 찾지 못했다."
L.EMPTY_FRIENDSNIL_SUB = "친구 중 누군가 DeathNote를 쓰면 네 수첩이 전달된다."
L.EMPTY_FRIENDSQUIET_HEAD = "친구들에게서 아직 아무것도 없다."
L.EMPTY_FRIENDSQUIET_SUB = "친구들은 지금까지 무사했다."
L.EMPTY_NOBODY_HEAD = "길드도, 친구도 없다."
L.EMPTY_NOBODY_SUB = "혼자서도 잘만 죽는다."
L.EMPTY_NOBODY_HINT = "길드원이나 친구 목록의 친구가 DeathNote를 쓰면, 그들에게 무슨 일이 있었는지 여기에 나온다."
L.EMPTY_SHAREDNIL_HEAD = "DeathNote를 쓰는 사람을 아직 찾지 못했다."
L.EMPTY_SHAREDNIL_SUB = "길드원이나 친구가 DeathNote를 쓰면 네 수첩이 전달된다."
L.EMPTY_SHAREDQUIET_HEAD = "아직 아무것도 없다."
L.EMPTY_SHAREDQUIET_SUB = "길드와 친구들은 지금까지 무사했다."
L.EMPTY_HUNT_HEAD = "척살 명단이 비어 있다."
L.EMPTY_HUNT_SUB = "수배서에서: 척살령 내리기."
L.EMPTY_HUNT_HINT = "또는 채팅에서: /dn hunt 이름 성. 길드 전원과 친구들이 볼 수 있다."
L.EMPTY_SEARCH_HEAD = "결과 없음."
L.EMPTY_SEARCH_SUB = "Enter를 누르면 이 이름을 수첩에 기록한다."
L.EMPTY_SEARCHRO_HEAD = "결과 없음."
L.EMPTY_SEARCHRO_SUB = "철자를 바꾸면 찾을 때도 있다."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "수첩"  -- [max 12]
L.MANUAL_BOOK = "필드에서 너를 죽인 자는 자동으로 기록된다. 죽은 뒤 뜨는 메시지를 클릭하면 범인의 페이지가 열린다."
L.MANUAL_WANTED_HEAD = "수배"  -- [max 12]
L.MANUAL_WANTED = "너를 죽인 자들, 가장 악질부터. 클릭하면 범행과 메모가 담긴 수배서가 나온다. 사면된 자는 줄이 그어진 채 맨 끝에 있다."
L.MANUAL_UNSOLVED_HEAD = "미해결"  -- [max 13]
L.MANUAL_UNSOLVED = "누가 했는지 확실하지 않으면 사건이 여기서 기다린다. 이름을 클릭하면 범인이 정해진다."
L.MANUAL_ALERT_HEAD = "경보"  -- [max 12]
L.MANUAL_ALERT = "범인이 이름표, 대상, 마우스 오버로 나타나면 수첩이 알린다. 클릭하면 대상으로 지정하고, 전투 중에는 전투가 끝난 뒤에 지정한다."
L.MANUAL_ADD_HEAD = "추가"  -- [max 12]
L.MANUAL_ADD = "검색창에 이름을 쓰고 Enter. 줄을 오른쪽 클릭: 복수 기록, 사면, 지우기."
L.MANUAL_GUILD_HEAD = "길드"  -- [max 12]
L.MANUAL_GUILD = "DeathNote를 쓰는 길드원과 친구는 범인이 확실한 네 죽음과 직접 추가한 항목을 본다. 수배서 또는 /dn hunt 이름: 척살 명단에 올리기. 현상금 클릭: 내 현상금 걸기 (약속일 뿐, 정산은 너희끼리)."
L.MANUAL_SHARE_HEAD = "전달"  -- [max 12]
L.MANUAL_SHARE = "이용 규칙, 수첩 백업: DeathNote가 없는 모두에게 줄 복사용 텍스트."
L.MANUAL_QUIET_HEAD = "조용히"  -- [max 12]
L.MANUAL_QUIET = "던전과 전장에서는 경보가 울리지 않는다. 그 밖에는 미니맵 버튼을 가운데 클릭하거나 /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "{name}: 정말 수첩에서 지울까?\n모든 범행과 메모가 사라진다."
L.CONFIRM_DELETE_OK = "지우기"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "이 컴퓨터의 길드 수첩을 비울까?\n그 척살 명단도 함께 지워지고, 네 척살령은 남는다.\n네 수첩은 그대로 남는다."
L.CONFIRM_GUILD_CLEAR_OK = "비우기"  -- [max 14]
L.CONFIRM_CANCEL = "취소"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} 골드"  -- [max 14]
L.BOUNTY_SILVER = "{count} 실버"  -- [max 14]
L.THOUSANDS_SEP = ","
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "확정"  -- [max 19]
L.ACT_DISMISS = "혐의 기각"  -- [max 19]
L.ACT_HUNT_AGAIN = "다시 수배"  -- [max 19]
L.ACT_REVENGE = "복수 기록"  -- [max 19]
L.ACT_PARDON = "사면"  -- [max 19]
L.ACT_STRIKE = "지우기"  -- [max 19]
L.ACT_OPEN_OWN = "내 수첩에서 열기"  -- [max 19]
L.ACT_ADOPT = "내 수첩으로"  -- [max 19]
L.ACT_CALLOFF = "척살 철회"  -- [max 19]
L.ACT_RELEASE = "척살령 내리기"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "목격: {time}"
L.ROW_NOT_SEEN = "아직 목격 없음"
L.ROW_PARDONED = "사면됨"
L.ROW_SUSPECT = "용의자"
L.MARK_REVENGE = "복수 {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "범인 불명"
L.MARK_CANDIDATES = "후보 {count}명"  -- [max 16]
L.MARK_SUSPECT = "용의자"  -- [max 16]
L.ROW_NO_PLAYER = "플레이어 아님"
L.ROW_UNCLEAR = "경위 불명"
L.MARK_NOT_COUNTED = "집계 안 함"  -- [max 16]
L.ROW_LISTED_BY = "추가한 사람: {names}"
L.ROW_GKILLED = "{kills}회 죽임"
L.ROW_VICTIMS = "피해자 {count}명"
L.ROW_LAST = "최근: {text}"
L.MARK_IN_BOOK = "내 수첩에 있음"  -- [max 16]
L.MEMBER_KILLERS = "범인 {count}명"  -- [max 14]
L.MEMBER_DEATHS = "사망 {count}회"  -- [max 12]
L.MEMBER_LISTED = "직접 {count}건"  -- [max 14]
L.MEMBER_ME = "다른 사람에게 보이는 너"
L.MEMBER_NOTHING = "아직 공유한 것 없음"
L.MEMBER_LAST_DIED = "마지막 사망: {time}"
L.MARK_YOU = "너"  -- [max 16]
L.MARK_FRIEND = "친구"  -- [max 16]
L.MARK_BOTH = "길드원, 친구"  -- [max 20]
L.MARK_TAKEN_DOWN = "처치 {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "생사 불문"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "범행"  -- [max 14]
L.POSTER_NOTE = "메모"  -- [max 8]
L.POSTER_BOUNTY = "현상금"  -- [max 12]
L.ROLE_ASSIST = "가담"  -- [max 14]
L.ROLE_SUSPECT = "혐의"  -- [max 14]
L.POSTER_LEVEL = "레벨 {level}"
L.POSTER_GUILD = "길드: {guild}"
L.POSTER_LAST_SEEN = "마지막 목격: {time}"
L.POSTER_NOT_SEEN = "아직 목격 없음"
L.POSTER_ONLY_SUSPECT = "혐의뿐, 입증된 범행 없음."
L.POSTER_NO_DEEDS = "기록된 범행 없음."
L.TIP_LISTED_AT = "추가: {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "사인: {spell}"
L.TIP_VICTIM = "피해자: {name}"
L.TIP_VICTIM_LEVEL = "피해자: {name} (레벨 {level})"
L.TIP_KILLER_LEVEL = "범인 레벨: {level}"
L.TIP_ASSISTS = "가담: {names}"
L.TIP_ROLE_ASSIST = "가담했지만 결정타는 아님."
L.TIP_ROLE_SUSPECT = "혐의뿐, 입증 안 됨."
L.MORE_LINE = "… 외 {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "길드 수첩"  -- [max 24]
L.POSTER_IN_BOOK_OF = "기록한 사람: {names}"
L.POSTER_SEEN = "목격: {time}"
L.POSTER_SEEN_BY = "목격: {time}, 목격자: {name}"
L.TIP_IN_BOOK_OF = "기록한 사람"
L.POSTER_REMARK = "비고"  -- [max 12]
L.POSTER_BY_HAND = "직접 추가"  -- [max 22]
L.POSTER_VICTIMS = "피해자"  -- [max 12]
L.POSTER_LISTED = "추가한 사람"  -- [max 14]
L.POSTER_LISTED_EMPTY = "직접 추가됨."
L.POSTER_NO_DEEDS_SENT = "전달된 범행 없음."
L.POSTER_NONE_KNOWN = "알려진 바 없음"
L.POSTER_NO_NAMES = "전달된 이름 없음"
L.TIP_VICTIMS = "피해자"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "척살령: {time}"
L.HUNT_REASON = "이유: {reason}"
L.POSTER_HUNTLIST = "척살 명단"  -- [max 24]
L.POSTER_RELEASED_N = "척살 명단에 {times} 오름"
L.POSTER_RELEASED_BY = "척살령을 내린 사람: {names}"
L.POSTER_TAKEN_DOWN = "처치"  -- [max 12]
L.POSTER_NOT_YET = "아직 없음"  -- [max 18]
L.POSTER_CALLS = "척살령"  -- [max 14]
L.POSTER_NOBODY_LEFT = "이제 아무도 없다."
L.POSTER_LAST = "최근"  -- [max 13]
L.POSTER_TAKEN_BY = "처치한 사람: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "아직 아무도 처치하지 못함"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "사망 사건"  -- [max 20]
L.CASE_ASSISTS = "가담자"  -- [max 24]
L.CASE_PICK = "범인 지정"  -- [max 24]
L.CASE_NOT_COUNTED = "집계 안 함 (인스턴스, 전장 또는 결투)"
L.CASE_KILLER = "범인"  -- [max 24]
L.CASE_KILLER_SUSPECT = "범인 (혐의)"  -- [max 24]
L.CASE_CLICK_NAME = "이름을 클릭하면 수배서가 열린다."
L.CASE_GONE = "더 이상 수첩에 없다."
L.CASE_KILLER_UNCLEAR = "범인 불명"  -- [max 24]
L.CASE_SEVERAL = "여러 명이 범인일 수 있다. 누구의 이름을 수첩에 적을까?"
L.CASE_NOBODY = "범인일 수 있는 사람이 없다."
L.CASE_HOW = "경위"  -- [max 24]
L.CASE_PVE = "몬스터나 환경 그 자체. 수첩이 다룰 사건이 아니다."
L.CASE_UNCLEAR = "불명"
L.CASE_DARK = "감식반도 오리무중이다."
L.TIP_MORE_CANDIDATES = "다른 후보"
L.CASE_SOURCE_SUSPECT = "혐의: 네가 죽기 직전에 너를 대상으로 잡고 있었다."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "범인의 툴팁에 한 줄 표시"  -- [max 44]
L.OPT_MINIMAP = "미니맵 버튼 표시"  -- [max 44]
L.OPT_ALERT = "범인이 나타나면 경보"  -- [max 44]
L.OPT_FLASH = "화면 가장자리를 빨갛게 깜빡임"  -- [max 44]
L.OPT_SUSPECTS = "용의자도 알림"  -- [max 44]
L.OPT_DEATHMSG = "PvP 사망 후 메시지"  -- [max 44]
L.OPT_G_SHARE = "내 죽음 공유"  -- [max 44]
L.OPT_G_SHAREMANUAL = "직접 추가한 항목 공유"  -- [max 44]
L.OPT_G_RECEIVE = "길드 수첩 받기"  -- [max 44]
L.OPT_G_ALERT = "길드 수첩의 범인 경고"  -- [max 44]
L.OPT_G_ALERTLISTED = "직접 추가한 항목도 경고"  -- [max 44]
L.OPT_G_ANNOUNCE = "길드원이 죽으면 알림"  -- [max 44]
L.OPT_G_SIGHTINGS = "목격 공유"  -- [max 44]
L.OPT_F_SHARE = "길드와 공유"  -- [max 44]
L.OPT_F_FRIENDS = "친구와 공유"  -- [max 44]
L.OPT_F_ALERT = "길드원이나 친구를 죽인 범인 경고"  -- [max 44]
L.OPT_F_ALERTHUNT = "척살 대상 경고"  -- [max 44]
L.OPT_F_ANNOUNCE = "길드원이나 친구가 죽으면 알림"  -- [max 44]
L.OPT_F_SIGHTINGS = "길드, 친구와 목격 공유"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "길드"  -- [max 14]
L.SET_BOOK_SIZE = "수첩 크기"  -- [max 34]
L.SET_LANGUAGE = "언어"  -- [max 16]
L.SET_LANG_AUTO = "자동"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "다시 불러온 뒤 적용된다."  -- [max 28]
L.SET_LANG_RELOAD = "지금 다시 불러오기"  -- [max 22]
L.SET_SEC_SHARE = "전달"  -- [max 24]
L.IO_EXPORT = "수첩 백업"  -- [max 17]
L.IO_IMPORT = "수첩 가져오기"  -- [max 17]
L.SET_HINT_BOOK = "백업하면 수첩을 텍스트로 받는다: 보관하거나 길드 밖의 사람에게 전달할 수 있다. 가져오기는 합치기만 하고 아무것도 덮어쓰지 않는다."
L.SET_SEC_SOUND = "소리"  -- [max 24]
L.SET_SOUND = "소리"  -- [max 22]
L.SET_VOLUME = "음량"  -- [max 22]
L.SET_CHANNEL = "채널"  -- [max 12]
L.SET_SEC_THRESHOLD = "기준"  -- [max 24]
L.SET_COOLDOWN = "범인별 재알림 대기 시간"  -- [max 34]
L.SET_MINKILLS = "이 범인에게 몇 번 죽으면 경보"  -- [max 34]
L.SET_ALERT_SIZE = "경보 크기"  -- [max 34]
L.SET_TEST_ALERT = "경보 테스트"  -- [max 17]
L.SET_G_MINKILLS = "길드 경고 기준 사망 횟수"  -- [max 34]
L.SET_F_MINKILLS = "경고 기준 사망 횟수"  -- [max 34]
L.SET_SEC_STATUS = "상태"  -- [max 24]
L.SET_SEC_SHARING = "공유"
L.SET_SEC_WARN = "경보"
L.SET_MORE = "더 보기"
L.SET_GUILD_CLEAR = "길드 수첩 비우기"  -- [max 26]
L.SET_HINT_GUILD = "네 길드와만 공유한다. 거기서 온 것은 네가 직접 가져올 때까지 네 수첩과 따로 보관된다."
L.SET_HINT_FRIENDS = "DeathNote를 쓰는 길드원과 친구하고만 공유한다."
L.BTN_BACK = "뒤로"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "동기화"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds}초 후 다시"  -- [max 16]
L.TIP_FRIENDS = "친구"
L.TIP_GUILD_NAME = "길드: {guild}"
L.TIP_MATES_WITH = "DeathNote를 쓰는 길드원:"
L.TIP_NO_MATE = "DeathNote를 쓰는 길드원을 아직 찾지 못했다."
L.TIP_FRIENDS_WITH = "DeathNote를 쓰는 친구:"
L.TIP_SHARED = "공유: 범인이 확실한 네 죽음, 직접 추가한 항목, 네 척살령."
L.TIP_NOT_SHARED = "공유 안 함: 메모, 혐의, 사면된 자, 가져온 항목."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "가져오기"  -- [max 17]
L.IO_DONE = "가져옴: 새 항목 {new}개, 합침 {merged}개."
L.IO_FAILED = "실패했다."
L.IO_SMALL = "간단히 보기"  -- [max 17]
L.IO_ALL = "전부 보기"  -- [max 17]
L.IO_MSG_FULL = "범행까지 포함한 수첩 전체 ({size})."
L.IO_MSG_SHORT = "이름과 횟수만 ({size}). 범행 포함: {full}."
L.IO_MSG_BIG = "큰 수첩 ({size}): 선택과 복사에 시간이 좀 걸린다."
L.IO_HELP_EXPORT = "텍스트가 선택되어 있다: Ctrl+C로 복사. 보관하거나 친구에게 전달해."
L.IO_HELP_IMPORT = "백업한 텍스트를 Ctrl+V로 붙여 넣고 가져오기를 눌러. 아무것도 덮어쓰지 않는다."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "길드원과 친구 중 DeathNote를 쓰는 사람은 모두 이유를 볼 수 있다."
L.REL_HINT_GUILD = "길드에서 DeathNote를 쓰는 사람은 모두 이유를 볼 수 있다."
L.REL_HINT_FRIENDS = "DeathNote를 쓰는 친구는 이유를 볼 수 있다."
L.REL_HEAD = "척살 명단에 올리기"  -- [max 24]
L.REL_FOR = "공개"  -- [max 6]
L.REL_REASON = "이유"  -- [max 8]
L.REL_HINT2 = "메모는 너만 본다. 네 척살령은 너만 철회할 수 있다."
L.REL_GO = "척살령 내리기"  -- [max 17]
L.REL_NONE = "길드가 없고 친구와 공유도 꺼져 있다."
L.REL_CAP = "명단마다 네 척살령은 최대 {own}개, 대상은 최대 {max}명."
L.REL_FAILED = "지금은 척살령을 내릴 수 없다."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds}초"  -- [max 7]
L.SET_HINT_SILENT = "소리 없음: 경보는 화면에만 뜬다."
L.SET_HINT_BUILTIN = "이 소리의 음량은 게임 설정의 채널을 따른다."
L.SET_HINT_LEVELS = "작은 소리부터 큰 소리까지 다섯 단계. 게임 설정의 채널 슬라이더가 그 위에 더해진다."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "길드와 친구"  -- [max 18]
L.TIP_HELP_BUTTON = "수첩 사용법"
L.VIEW_HUNT = "척살 명단"  -- [max 13]
L.VIEW_BY_KILLER = "범인별"  -- [max 13]
L.VIEW_BY_MATE = "길드원별"  -- [max 13]
L.SRC_ALL = "전체"  -- [max 12]
L.SRC_GUILD = "길드"  -- [max 12]
L.SRC_FRIENDS = "친구"  -- [max 12]
L.SORT_HIDE_PARDONED = "사면된 자 숨기기"  -- [max 24]
L.SORT_SHOW_PARDONED = "사면된 자 보이기"  -- [max 24]
L.SEARCH_ADD = "검색 또는 추가 …"  -- [max 26]
L.SEARCH_SHORT = "검색 …"  -- [max 10]
L.SEARCH_KILLER = "범인 찾기 …"  -- [max 15]
L.SEARCH_JOURNAL = "범인 또는 장소 …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "모두 접기"
L.TIP_EXPAND_ALL = "모두 펼치기"
L.STATUS_NO_PLATES = "적 이름표가 꺼져 있다: 경보는 대상과 마우스 오버만 본다."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "수배 {count}명"
L.MM_UNSOLVED = "미해결 {count}건"
L.MM_ALERT_OFF = "경보 꺼짐 (가운데 클릭)"
L.MM_CLICK = "클릭: 수첩 · 오른쪽 클릭: 이용 규칙"
L.MM_MIDDLE = "가운데 클릭: 경보 켜기/끄기"
L.MM_DRAG = "끌기: 미니맵 가장자리를 따라 이동"
L.MM_CHAT_ALERT_ON = "경보 켜짐."
L.MM_CHAT_ALERT_OFF = "경보 꺼짐."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "길드의 적 1호"  -- [max 25]
L.STAMP_HUNT = "척살령 발령"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "네 친구 {friend}인 척한 자를 거부함: {name}"
L.FRIENDS_SHORT_IMPOSTOR = "낯선 자 거부"  -- [max 22]
L.ALERT_LEVEL = "레벨 {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "마지막 레벨 {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "레벨 ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · 척살 명단에 있음 ({names})"
L.BANNER_NEW_HUNTS = "새 대상 {count}명"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "척살 명단에 새로 오름"
L.OPT_F_ANNOUNCEHUNT = "척살 명단 소식 알림: 새 대상, 처치"  -- [max 44]
L.SET_HUNT_EXPIRE = "척살령 만료 기간"  -- [max 30]
L.SET_EXPIRE_NEVER = "무기한"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count}일"  -- [max 10]
L.SET_FRIENDS_CLEAR = "친구 수첩 비우기"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "이 컴퓨터의 친구 수첩을 비울까?\n그 척살 명단도 함께 지워지고, 네 척살령은 남는다."
L.CONFIRM_CALLOFF_ALL = "척살 명단에 내린 네 척살령을 모두 철회할까?\n길드와 친구에게는 차례로 전해진다."
L.CONFIRM_CALLOFF_ALL_OK = "모두 철회"  -- [max 14]
L.ACT_CALLOFF_ALL = "내 척살령 모두 철회"  -- [max 24]
L.ACT_HUNT_HIDE = "내 화면에서 숨기기"  -- [max 19]
L.ACT_HUNT_SHOW = "다시 보이기"  -- [max 19]
L.HUNT_ROW_HIDDEN = "네 화면에서만 숨김"
L.HUNT_ROW_CALLS = "척살령 {count}건: {names}"
L.POSTER_ON_HUNTLIST = "척살 명단에 있음 ({names})"
L.REL_SELF = "자기 자신은 척살 명단에 올릴 수 없다."
L.REL_MATE = "같은 편이다 (DeathNote를 쓰는 길드원이나 친구)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "네 친구 {friend}는 누구인가: {a} 또는 {b}? 골라야 한다."
L.FRIENDS_SHORT_CONFLICT = "친구 불분명"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "두 플레이어가 네 친구 {friend}라고 한다: {a}, {b}. 네가 고르기 전까지 수첩은 둘 중 누구에게서도 아무것도 받지 않는다. 길드와 친구, 길드원별 보기: 이름을 오른쪽 클릭."
L.MEMBER_CONFLICT = "오른쪽 클릭: 네 친구인가?"  -- [max 40]
L.ACT_TIE_MINE = "내 친구: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "연결 해제"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "{name}의 연결을 친구 목록에서 해제할까?\n이 이름이 친구 수첩에 가져온 것은 지워지고, 이 이름으로 오는 다음 메시지가 새로 연결된다."
L.CHAT_FRIENDS_TIES = "연결된 전체 이름 (* = 첫 접촉, 아직 확인 안 됨): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <이름 [성]> <골드>  내 현상금 걸기 (골드 없이: 철회)"
L.CHAT_WHO_BOUNTY = "누구에게? /dn bounty <이름> <골드>"
L.CHAT_BOUNTY_SET = "{name}: 현상금 {gold}골드를 걸었다. DeathNote를 쓰는 길드원과 친구가 본다."
L.CHAT_BOUNTY_OFF = "{name}: 네 현상금을 철회했다."
L.CHAT_BOUNTY_NONE = "네가 건 현상금이 없다: {name}"
L.CHAT_BOUNTY_BAD = "현상금: 1부터 99999까지의 정수 골드 (0이면 철회)."
L.CHAT_BOUNTY_CAP = "현상금을 걸 수 없다: 내 현상금은 최대 {count}개."
L.CHAT_BOUNTY_OURS = "너 자신이나 같은 편(DeathNote를 쓰는 길드원이나 친구)에게는 현상금을 걸 수 없다."
L.ACT_BOUNTY = "현상금 걸기"  -- [max 24]
L.ACT_UNDO = "되돌리기"  -- [max 19]
L.ACT_REVENGE_TAKE = "복수 하나 빼기"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, 내가 건 현상금"
L.POSTER_BOUNTY_BY = "{gold}, 건 사람: {name}"
L.POSTER_BOUNTY_MANY = "현상금 {gold}: {names}"
L.POSTER_AVENGED = "대신 복수한 사람: {names}"
L.ROW_AVENGED = "대신 복수 {times}"
L.BOUNTY_TIP_HEAD = "내 현상금 (골드)"
L.BOUNTY_TIP_RULES = "1부터 99999까지의 정수. 비우거나 0: 수첩의 값으로. Enter는 확정, Esc는 취소."
L.BOUNTY_TIP_PROMISE = "DeathNote를 쓰는 길드원과 친구가 본다. 약속일 뿐이다: 정산은 너희끼리."
L.BOUNTY_TIP_CLICK = "클릭: 내 현상금 걸기"
L.CHAT_AVENGED = "{name}: 너 대신 {killer} 처치함"
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: 현상금 {gold}골드를 걸었다."
L.CHAT_BOUNTY_UNKNOWN = "{name}: 어느 책에도 없다. 현상금은 책에 있는 이름에만 걸 수 있다. 게임에 표시되는 대로 이름과 성까지 입력해."
L.CHAT_BOUNTY_LIST = "내 현상금 ({count}/{max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "건 현상금이 없다."
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
-- >>> RECORD (1.3.0): English placeholders, to be translated (keys as in enUS.lua) ---------------------------------
L.TAB_RECORD = "Rap Sheet"
L.STAMP_QUITT = "EVEN"
L.STAMP_OVERPAID = "OVERPAID"
L.STATE_OPEN = "open"
L.STATE_EVEN = "even"
L.STATE_AHEAD = "overpaid"
L.STATE_VICTIM = "not in the book"
L.STAND_LINE = "Score {score}"
L.STAND_TIP = "you {mine}, them {his}"
L.TIP_IN_RECORD = "RAP SHEET:"
L.TIP_RECORD_LINE = "killed by you {times}, last {time}"
L.RECORD_HEAD = "Your File"
L.RECORD_LOG_HEAD = "Latest Kills"
L.RECORD_NEXT = "{points} more to {rank}"
L.RECORD_TOP = "Top rank reached."
L.RECORD_BAR_TIP = "{total} of {goal} points"
L.RECORD_NEEDLE_LOW = "ruthless"
L.RECORD_NEEDLE_HIGH = "honourable"
L.RECORD_NEEDLE_TIP = "The needle: honour and protection against infamy. Hunt does not move it."
L.RECORD_KILLS = "Kills: {kills} · Victims: {victims}"
L.RECORD_BEST = "Best: {list}"
L.RECORD_BEST_GAP = "+{count} levels"
L.RECORD_BEST_STREAK = "streak {count}"
L.RECORD_BEST_QUICK = "fastest payback {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} h"
L.RECORD_AWARDS = "AWARDS"
L.RECORD_AWARD_AT = "awarded {time}"
L.RECORD_AWARD_OPEN = "not awarded yet"
L.RECORD_MORE = "Show more"
L.RECORD_BACK = "Back to file"
L.RECORD_CLEAR = "Clear rap sheet"
L.CONFIRM_RECORD_CLEAR = "Clear the rap sheet?\nAll victims and the list of latest kills go. Rank, points and awards stay."
L.CONFIRM_RECORD_CLEAR_OK = "Clear"
L.CONFIRM_VICTIM_STRIKE = "Strike {name} from the rap sheet?\nThe points you earned stay."
L.ACT_VICTIM_STRIKE = "Strike from rap sheet"
L.VICTIM_KILLED = "killed by you {times}"
L.VICTIM_POINTS = "Points earned: {points}"
L.VICTIM_SCENE = "Scene: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "YOUR KILLS"
L.KILL_TAG_REVENGE = "payback"
L.KILL_TAG_KICK = "while down"
L.KILL_TAG_GROUP = "group"
L.BAND_GRAU = "grey"
L.BAND_GRUEN = "green"
L.BAND_GELB = "yellow"
L.BAND_ORANGE = "orange"
L.BAND_ROT = "red"
L.BAND_SCHAEDEL = "skull"
L.BAND_UNBEKANNT = "unknown"
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "no points"
L.RECORD_BANDS = "By level colour"
L.TIP_PATH_R = "Infamy: kills of greys and greens."
L.TIP_PATH_E = "Honour: kills of players about your level, payback."
L.TIP_PATH_J = "Hunt: kills of higher levels, hit list targets, bounties."
L.TIP_PATH_S = "Protection: kills of players who killed guildmates or friends."
L.SORT_STATE = "Score"
L.SORT_COUNT = "Kills"
L.SORT_POINTS = "Points"
L.CHAT_OWN_KILL = "Rap sheet: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "New path: {path}. Rank: {rank}."
L.BANNER_RANK = "NEW RANK"
L.BANNER_AWARD = "AWARD"
L.OPT_LEDGER = "Keep a rap sheet"
L.OPT_LEDGER_CHAT = "Report own kills in the chat"
L.OPT_VICTIMS = "Warn when a victim of yours shows up"
L.SET_SETTLED = "Alarm when the score is settled"
L.SET_SETTLED_ALWAYS = "as usual"
L.SET_SETTLED_QUIET = "quiet"
L.SET_SETTLED_OFF = "never"
L.MANUAL_RECORD_HEAD = "RAP SHEET"
L.MANUAL_RECORD = "Your own killing blows on players. Poster and list show the score 'you : them': open, even or overpaid. Rank 1 is always open. Kills earn points for your rank."
L.POSTER_LAST_SEEN_IN = "Last seen: {zone}, {time}"
L.SHEET_RECORD = "Rap Sheet"
-- <<< RECORD
end)
