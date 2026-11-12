-- DeathNote: Türkçe (trTR).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.trTR), not here.
-- Turkish keeps the noun singular after a number ("3 katil"), so no text needs a plural construct.
-- Fonts: latinExt (Nimrod MT, Arial Narrow) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Terms: book defter, guild book lonca defteri, friends' book arkadaş defteri, killer katil, guildmate lonca üyesi,
-- Hit List av listesi, call (av) çağrı(sı). No suffix is attached to {name}/{zone}: colon forms instead.
-- Capitals: i -> İ, ı -> I (İNTİKAM, AFFEDİLDİ, KAYIT).
--
-- TOC-Notes: Açık dünya PvP için ölüm listesi: seni kimin öldürdüğünü hatırlar ve yakındaysa uyarır.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("trTR")) then return end

Locale.Register("trTR", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
-- (the number of entries is added by the code: "Wanted  3"; the tab grows with the text)
L.TAB_WANTED = "Arananlar"  -- [max 16]
L.TAB_UNSOLVED = "Çözülmemiş"  -- [max 16]
L.TAB_DEATHLOG = "Ölüm Kaydı"  -- [max 16]
L.TAB_GUILD = "Lonca"  -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Ev Kuralları"  -- [max 24]
L.HEAD_HELP = "Nasıl Çalışır"  -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK = "Defter"  -- [max 14]
L.SHEET_ALERT = "Alarm"  -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1 = "HALK DÜŞMANI No. 1"  -- [max 24]
L.STAMP_REVENGE = "İNTİKAM ALINDI"  -- [max 16]
L.STAMP_PARDONED = "AFFEDİLDİ"  -- [max 16]
L.STAMP_SUSPECT = "ŞÜPHELİ"  -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1 = "HALK DÜŞMANI No. 1 GÖRÜLDÜ"  -- [max 30]
L.ALERT_SIGHTED = "HALK DÜŞMANI GÖRÜLDÜ"  -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "ŞÜPHELİ GÖRÜLDÜ"  -- [max 30]
L.ALERT_TITLE_GUILD = "LONCA DÜŞMANI GÖRÜLDÜ"  -- [max 30]
L.ALERT_TITLE_FRIENDS = "ARKADAŞ KATİLİ GÖRÜLDÜ"  -- [max 30]
L.ALERT_TITLE_HUNT = "AV LİSTESİ HEDEFİ"  -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT = "şüphe altında"
L.ALERT_LINE_KILLED = "seni {times} öldürdü"
L.ALERT_LINE_KILLED_ASSISTED = "seni {times} öldürdü, {assists} ölümüne karıştı"
L.ALERT_LINE_ASSISTED = "{times} ölümüne karıştı"
L.ALERT_LINE_MANUAL = "deftere elle yazıldı"
L.ALERT_LINE_LAST = "{text}, en son {time}"
L.ALERT_LINE_IN = "{text}, yer: {zone}"
L.ALERT_LINE_REVENGE = "{text}. İntikam: {times}"
L.ALERT_HINT_CLOSE = "Sağ tık: kapat"  -- [max 44]
L.ALERT_HINT_COMBAT = "Hedef alma ancak savaştan sonra"  -- [max 44]
L.ALERT_HINT_TARGET = "Tık: hedef al  ·  Sağ tık: kapat"  -- [max 44]
L.ALERT_MORE = "+{count} daha"  -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD = "lonca defterinde"
L.GUILD_LINE_IN_FRIENDS = "arkadaş defterinde"
L.GUILD_LINE_LISTED_BY = "defterine yazan: {names}"
L.GUILD_LINE_KILLED_GUILD = "lonca üyelerini {kills}× öldürdü"
L.GUILD_LINE_KILLED_FRIENDS = "arkadaşları {kills}× öldürdü"
L.GUILD_LINE_KILLED_BOTH = "lonca üyelerini ve arkadaşları {kills}× öldürdü"
L.GUILD_LINE_LAST = "{text}, son kurban: {name}"
L.HUNT_LINE_BY = "av listesine koyan: {names}"
L.HUNT_LINE_RELEASED = "av listesinde"
L.HUNT_LINE_REASON = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT = "şüphe altında"
L.TALLY_MANUAL = "elle eklendi"
L.TALLY_NONE = "henüz suç yok"
L.TALLY_KILLED = "seni {times} öldürdü"
L.TALLY_ASSISTED = "{times} ölümüne karıştı"
L.PLACE_UNKNOWN = "bilinmeyen yer"
L.GKILLS_CAP = "en az {count}"
L.NAMELIST_MORE = "{names} ve {count} kişi daha"

-- Time and money (one place for all time forms) ---------------------------------------------------
-- TIME_FMT_* are os.date formats: %d day, %m month, %Y year (4), %y year (2), %H hour, %M minute.
L.TIME_FMT_WHEN = "%d.%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H:%M"
L.TIME_FMT_DAY = "%d.%m"
L.TIME_FMT_DAY_YEAR = "%d.%m.%y"
L.TIME_NEVER = "hiç"
L.TIME_JUST = "az önce"
L.TIME_MINUTES = "{count} dk önce"  -- [max 14]
L.TIME_HOURS = "{count} sa önce"  -- [max 14]
L.TIME_DAYS = "{count} gün önce"  -- [max 16]
L.MONEY_GOLD = "{count} altın"
L.MONEY_SILVER = "{count} gümüş"
L.MONEY_COPPER = "{count} bakır"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD = "DeathNote kullanan lonca üyesi: {count}."
L.HEALTH_NOGUILD = "Bir loncada değilsin, hiçbir şey paylaşılmıyor."
L.HEALTH_OFF = "Paylaşım kapalı."
L.HEALTH_SHORT_NOGUILD = "Lonca yok"  -- [max 18]
L.HEALTH_SHORT_OFF = "Paylaşım kapalı"  -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Engellendi"  -- [max 18]
L.HEALTH_SHORT_FAILING = "Reddedildi"  -- [max 18]
L.HEALTH_SHORT_HOLD = "Bekliyor"  -- [max 18]
L.HEALTH_SHORT_ASKED = "Soruldu"  -- [max 18]
L.HEALTH_SHORT_FAIL = "Çalışmıyor"  -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE = "Ses yok"  -- [max 16]
L.SOUND_RAIDWARNING = "Raid uyarısı"  -- [max 16]
L.SOUND_BELL = "Çan"  -- [max 16]
L.SOUND_GONG = "Gong"  -- [max 16]
L.SOUND_HEARTBEAT = "Kalp atışı"  -- [max 16]
L.SOUND_FEATHER = "Tüy kalem"  -- [max 16]
L.SOUND_SIREN = "Siren"  -- [max 16]
L.CHANNEL_MASTER = "Ana ses"  -- [max 16]
L.CHANNEL_SFX = "Efektler"  -- [max 16]
L.CHANNEL_DIALOG = "Diyalog"  -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED = "{name} artık defterde."
L.CHAT_REMOVED = "{name} defterden silindi."
L.CHAT_SYNC_WAIT = "Az önce eşitlendi. {seconds} sn sonra tekrar dene."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Henüz isim yok."
L.EMPTY_WANTED_SUB = "Bir kere de dışarı çık."

-- Slash command help (/dn help), one line each, in the active language ------------------------
-- The command words stay English in every language except German (which keeps its own words);
-- two spaces separate the command from the explanation.
L.HELP_TOGGLE = "/dn  defteri aç/kapat"
L.HELP_ADD = "/dn add <İsim [Soyad]>  bir katili deftere elle yaz"
L.HELP_DEL = "/dn del <İsim [Soyad]>  bir katili defterden sil"
L.HELP_QUIET = "/dn quiet  alarmı kapat/aç"
L.HELP_TEST = "/dn test  deneme alarmı göster"
L.HELP_GUILD = "/dn guild  lonca defteri: durum ve hangi lonca üyelerinde DeathNote var"
L.HELP_FRIENDS = "/dn friends  arkadaş defteri: durum ve hangi arkadaşlarda DeathNote var"
L.HELP_SYNC = "/dn sync  lonca defterini ve arkadaş defterini şimdi eşitle"
L.HELP_HUNT = "/dn hunt <İsim [Soyad]>  av listesine koy (isimsiz: av listesini göster)"
L.HELP_CALLOFF = "/dn calloff <İsim [Soyad]>  kendi av çağrını iptal et"
L.HELP_LANG = "/dn lang <kod>  defterin dili (enUS, deDE, frFR ...), /reload sonrası"
L.HELP_THEME = "/dn theme <ad>  defterin kapağı, /reload sonrası"
L.HELP_PROBE = "/dn probe  sorun giderme: oyun deftere ne söylüyor"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  sorun giderme, savaş kaydını da test et"
L.HELP_DEBUG = "/dn debug  sorun giderme: her ölümü ayrıntılı kaydet (aç/kapat)"
L.HELP_HELP = "/dn help  bu yardım"
L.HELP_SILENT_ZONES = "Zindanlarda, savaş alanlarında ve arenalarda defter kendiliğinden susar."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON = "açık"
L.WORD_OFF = "kapalı"
L.CHAT_WHO_ADD = "Kim? /dn add <İsim>"
L.CHAT_WHO_DEL = "Kim? /dn del <İsim>"
L.CHAT_WHO_CALLOFF = "Kim? /dn calloff <İsim>"
L.CHAT_BAD_NAME = "Geçersiz isim."
L.CHAT_NOT_IN_BOOK = "Defterde yok: {name}"
L.CHAT_ALARM_ON = "Alarm açık."
L.CHAT_ALARM_OFF = "Alarm kapalı."
L.CHAT_DEBUG = "Sorun giderme kaydı {state}."
L.CHAT_UNKNOWN_CMD = "Bilinmeyen komut. Yardım: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Lonca defteri yüklenmedi."
L.CHAT_NO_GUILD = "Bir loncada değilsin (ya da oyun bunu henüz bilmiyor)."
L.CHAT_GUILD_STATE = "Lonca: {guild} · paylaşım {share}, alım {receive}."
L.CHAT_GUILD_BOOK = "Lonca defteri: {enemies} katil ({listed} tanesi sadece elle eklendi), {deeds} suç, {foreign} tanesi lonca üyelerini de ilgilendiriyor. Elle eklenenleri paylaş: {manual}."
L.CHAT_STATE_OK = "Durum: {text}"
L.CHAT_STATE_WARN = "Dikkat: {text}"
L.CHAT_NO_MATES = "Henüz DeathNote kullanan lonca üyesi yok."
L.CHAT_HAVE_DN = "DeathNote kullananlar: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote kullananlar: {names} ve {count} kişi daha"
L.CHAT_SYNC_ASKED = "Eşitleme istendi. Yanıtlar birkaç saniye içinde gelir."
L.CHAT_SYNC_FAIL = "Eşitleme çalışmıyor: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "lonca yok ya da paylaşım kapalı."
L.CHAT_FRIENDS_NOT_LOADED = "Arkadaş defteri yüklenmedi."
L.CHAT_FRIENDS_STATE = "Arkadaşlar: paylaşım {share}, çevrim içi {online}/{total}."
L.CHAT_FRIENDS_BOOK = "Arkadaş defteri: {enemies} katil ({listed} tanesi sadece elle eklendi), {deeds} suç."
L.CHAT_NO_FRIENDS = "Henüz DeathNote kullanan arkadaş yok."
L.CHAT_HUNT_NOT_LOADED = "Av listesi yüklenmedi."
L.CHAT_HUNT_UNKNOWN = "Bilinmiyor: {name}. Soyadını da yaz, isim oyunda nasıl görünüyorsa öyle."
L.CHAT_HUNT_CAP = "Av listesine konamıyor: liste başına en fazla {own} kendi çağrın ve {targets} hedef olabilir."
L.CHAT_HUNT_NOWHERE = "Şu an av listesine konamıyor: lonca yok ve arkadaşlarla paylaşım kapalı."
L.CHAT_HUNT_BOTH = "{name} av listesinde, lonca ve arkadaşlar için."
L.CHAT_HUNT_GUILD = "{name} av listesinde, lonca için."
L.CHAT_HUNT_FRIENDS = "{name} av listesinde, arkadaşların için."
L.CHAT_CALLED_OFF = "Av iptal edildi: {name}"
L.CHAT_NO_OWN_CALL = "Kendi av çağrın yok: {name}"
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Dil şimdi: {lang}. Değiştir: /dn lang <kod>"
L.CHAT_LANG_LIST = "Kodlar: {codes}"
L.CHAT_LANG_BAD = "Bilinmeyen dil: {code}"
L.CHAT_LANG_SET = "Dil: {lang}."
L.CHAT_LANG_RELOAD = "Dil: {lang}. /reload sonrası geçerli."
L.CHAT_THEME_CURRENT = "Kapak şimdi: {theme}. Değiştir: /dn theme <ad>"
L.CHAT_THEME_LIST = "Kapaklar: {themes}"
L.CHAT_THEME_BAD = "Bilinmeyen kapak: {name}"
L.CHAT_THEME_SET = "Kapak: {theme}."
L.CHAT_THEME_RELOAD = "Kapak: {theme}. /reload sonrası geçerli."
L.THEME_NOTEBOOK = "Kara Defter"
L.THEME_HARBOR = "Privateer's Ledger"  -- TODO translate (English placeholder)
L.THEME_TRADE = "The Workshop"  -- TODO translate (English placeholder)

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Defter hazır. Açık dünyada seni öldüren herkes sonra burada yazılı olur. /dn ya da mini harita düğmesiyle aç."
L.WELCOME_PLATES = "Düşman isim plakaları kapalı. Onlar olmadan alarm sadece hedefini görür."
L.WELCOME_SHARE = "DeathNote kullanan lonca üyeleri ve arkadaşlar da okur. Notlar ve şüpheler sende kalır."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
-- The labels stand in red before the line, with their colon: "IN THE BOOK: killed you 2× · rank 1"
L.TIP_IN_BOOK = "DEFTERDE:"
L.TIP_HUNT = "AV LİSTESİ:"
L.TIP_GUILDBOOK = "LONCA DEFTERİ:"
L.TIP_PARDONED = "affedildi"
L.TIP_RANK = "{rank}. sıra"
L.TIP_REVENGE = "intikam {times}"
L.TIP_LISTED_BY = "defterine yazan: {names}"
L.TIP_NOTE = "Not: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
-- BANNER_* heads are written in capitals; the code spaces the letters ("N E W   E N T R Y"),
-- except in Chinese and Korean.
L.BANNER_TIP = "Tık: aç · Sağ tık: kapat"
L.BANNER_NEW = "YENİ KAYIT"  -- [max 24]
L.BANNER_NEW_LINE = "artık defterde"
L.BANNER_AGAIN = "YİNE"  -- [max 24]
L.BANNER_AGAIN_LINE = "seni yine öldürdü, bu {count}. kez"
L.BANNER_SUSPECT = "ŞÜPHE"  -- [max 24]
L.BANNER_SUSPECT_LINE = "şüphe altında, defterde netleştir"
L.BANNER_UNCLEAR = "KATİL BELİRSİZ"  -- [max 24]
L.BANNER_CANDIDATES = "{count} aday"
L.BANNER_UNCLEAR_LINE = "Tık: katili Çözülmemiş sekmesinde seç"
L.BANNER_REVENGE = "ÖDEŞTİK"  -- [max 24]
L.BANNER_REVENGE_LINE = "İntikam alındı ({count}×)"
L.BANNER_GUILD = "LONCA"  -- [max 24]
L.BANNER_FRIENDS = "ARKADAŞLAR"  -- [max 24]
L.BANNER_KILLED_BY = "öldürüldü, katil: {name}"
L.BANNER_HUNT = "AV LİSTESİ"  -- [max 24]
L.BANNER_BAGGED = "avlayan: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
-- Sentences at most ~60 characters, no technical words; SHORT = short form in the status line.
L.SYNC_GUILD_OFF = "Paylaşım kapalı (Ev Kuralları, Lonca sayfası)."
L.SYNC_FRIENDS_OFF = "Arkadaşlarla paylaşım kapalı."
L.SYNC_NOBODY = "Paylaşacak lonca da arkadaş da yok."
L.SYNC_SHORT_NOBODY = "Paylaşım yok"  -- [max 18]
L.SYNC_PREFIX = "Oyun alıma izin vermiyor. Yeniden giriş yapmak işe yarar."
L.SYNC_SHORT_PREFIX = "Alım yok"  -- [max 18]
L.SYNC_BLOCKED = "Sunucu gönderimi engelliyor. Defteri yedekle ile aktar."
L.SYNC_SHORT_BLOCKED = "Gönderim engelli"  -- [max 22]
L.SYNC_FAILING = "Gönderim şu an başarısız, yeniden deneniyor."
L.SYNC_SHORT_FAILING = "Gönderim aksıyor"  -- [max 18]
L.SYNC_HOLD = "Gönderim bekliyor: {wait}."
L.SYNC_HOLD_INSTANCE = "instance'tan çıkana kadar"
L.SYNC_HOLD_COMBAT = "savaştan çıkana kadar"
L.SYNC_HOLD_LOCKDOWN = "sohbet yeniden serbest kalana kadar"
L.SYNC_HOLD_AGAIN = "yeniden çalışana kadar"
L.SYNC_HOLD_SHORT_INSTANCE = "Bekliyor: instance"  -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT = "Bekliyor: savaş"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Bekliyor: sohbet"  -- [max 18]
L.SYNC_QUIET = "Gönderildi, ama henüz DeathNote kullanan lonca üyesi yok."
L.SYNC_READY = "Hazır. Henüz DeathNote kullanan lonca üyesi yok."
L.SYNC_RUNNING = "Çalışıyor: {count} lonca üyesinde DeathNote var."
L.SYNC_RUNNING_ALL = "Çalışıyor: lonca ve arkadaşlarda {count} kişide DeathNote var."
L.FRIENDS_OFF = "Arkadaşlarla paylaşım kapalı (Ev Kuralları, Lonca sayfası)."
L.FRIENDS_BLOCKED = "Sunucu fısıltıları engelliyor. Arkadaşlar hiçbir şey almıyor."
L.FRIENDS_SHORT_BLOCKED = "Fısıltı engelli"  -- [max 22]
L.FRIENDS_FAILING = "Fısıltılar şu an başarısız, yeniden deneniyor."
L.FRIENDS_SHORT_FAILING = "Fısıltı aksıyor"  -- [max 18]
L.FRIENDS_NONE_LISTED = "Arkadaş listesinde kimse yok."
L.FRIENDS_NONE_ONLINE = "Şu an çevrim içi arkadaş yok."
L.FRIENDS_SHORT_NONE_ONLINE = "Çevrim içi yok"  -- [max 18]
L.FRIENDS_QUIET = "Soruldu, ama henüz DeathNote kullanan arkadaş yok."
L.FRIENDS_READY = "Hazır. Henüz DeathNote kullanan arkadaş yok."
L.FRIENDS_HOLD = "Arkadaşlara gönderim, yeniden çalışana kadar bekliyor."
L.FRIENDS_RUNNING = "Çalışıyor: {count} arkadaşta DeathNote var."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD = "Lonca defterinden alındı (lonca üyelerini {kills}× öldürdü)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
-- The export itself is language neutral ("DEATHNOTE:1", codes); a German export reads in English.
L.IMPORT_NO_DB = "Veritabanı yüklenmedi."
L.IMPORT_NO_TEXT = "Metin yok."
L.IMPORT_NO_HEADER = "İlk satır eksik ({header} ile başlar). Lütfen metnin tamamını kopyala."
L.IMPORT_NOT_EXPORT = "Bu bir DeathNote dışa aktarımı değil (başlık satırı eksik ya da sürüm yanlış)."
L.IMPORT_TOO_LONG = "Çok fazla satır (en fazla {count})."
L.IMPORT_BAD_KEY = "Satır {line}: geçersiz anahtar."
L.IMPORT_BAD_TIME = "Satır {line}: geçersiz zaman."
L.IMPORT_BROKEN = "Satır {line} eksik ya da bozuk (metin kesilmiş mi?). Hiçbir şey içe aktarılmadı."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "evet"
L.WORD_NO = "hayır"
L.PROBE_HEAD = "Tanı: {apis}/{apisAll} arayüz mevcut, {events}/{eventsAll} olay kaydedilebilir."
L.PROBE_MISSING = "Eksik: {list}"
L.PROBE_NOT_REGISTERABLE = "Kaydedilemez: {list}"
L.PROBE_SOURCES = "Recap şu an: {recap} · Meter: {meter} · Savaş kaydı: {clog}"
L.PROBE_READABLE = "okunabilir"
L.PROBE_DEAD = "ölü"
L.PROBE_PLATES = "Düşman isim plakaları: {plates} · Açık dünya: {open}"
L.PROBE_PLATES_OFF = "KAPALI (oyuncuları sadece hedef ve fare görür)"
L.PROBE_TARGET = "Hedef: isim={name} GUID={guid} sınıf={class} düşman={enemy} beni hedefliyor={me}"
L.PROBE_GUILD = "Lonca: önek {prefix} · gönderim {send} · son dönüş değeri {result} · gönderilen {sent}, alınan {received}, atılan {dropped}"
L.PROBE_REGISTERED = "kayıtlı"
L.PROBE_NOT_REGISTERED = "kayıtlı DEĞİL ({result})"
L.PROBE_POSSIBLE = "mümkün"
L.PROBE_ABSENT = "eksik"
L.PROBE_WAITS = " · bekliyor: {why}"
L.PROBE_LISTED = "Elle eklenenler (M): gönderilen {sent}, alınan {received}, atılan {dropped} · silinenler (X): gönderilen {usent}, alınan {ureceived}, atılan {udropped}"
L.PROBE_GUILDBOOK = "Lonca defteri: {text}"
L.PROBE_SAVED = "DeathNoteDB.probe içine kaydedildi (/reload sonrası dosyada)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Sıra"  -- [max 14]
L.SORT_RECENT = "En yeni"  -- [max 14]
L.SORT_NAME = "İsim"  -- [max 14]
L.SORT_SEEN = "Görülme"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Açık dünyada seni öldüren buraya yazılır. Kendiliğinden."
L.EMPTY_OPEN_HEAD = "Çözülmemiş bir şey yok."
L.EMPTY_JOURNAL_HEAD = "Hiç ölmedin."
L.EMPTY_JOURNAL_SUB = "Helal olsun. Ya da yalan."
L.EMPTY_NOGUILD_HEAD = "Lonca yok."
L.EMPTY_NOGUILD_SUB = "Yalnız ölmek de olur."
L.EMPTY_GUILDOFF_HEAD = "Lonca defteri kapalı."
L.EMPTY_GUILDOFF_SUB = "Paylaşım kapalı. Nerede açılacağını Ev Kuralları bilir."
L.EMPTY_GUILDNIL_HEAD = "Loncadan henüz ses yok."
L.EMPTY_GUILDNIL_SUB = "Bir lonca üyesinde DeathNote olur olmaz defterin gönderilir."
L.EMPTY_GUILDQUIET_HEAD = "Lonca defterinde henüz bir şey yok."
L.EMPTY_GUILDQUIET_SUB = "Lonca üyelerin şimdiye kadar rahattı."
L.EMPTY_FRIENDSOFF_HEAD = "Arkadaş defteri kapalı."
L.EMPTY_FRIENDSOFF_SUB = "Arkadaşlarla paylaşım kapalı. Nerede açılacağını Ev Kuralları bilir."
L.EMPTY_FRIENDSNIL_HEAD = "Henüz DeathNote kullanan arkadaş yok."
L.EMPTY_FRIENDSNIL_SUB = "Bir arkadaşında DeathNote olur olmaz defterin gönderilir."
L.EMPTY_FRIENDSQUIET_HEAD = "Arkadaşlarından henüz bir şey yok."
L.EMPTY_FRIENDSQUIET_SUB = "Arkadaşların şimdiye kadar rahattı."
L.EMPTY_NOBODY_HEAD = "Lonca yok, arkadaş yok."
L.EMPTY_NOBODY_SUB = "Yalnız ölmek de olur."
L.EMPTY_NOBODY_HINT = "Lonca üyelerinde ya da arkadaş listendeki arkadaşlarda DeathNote olunca, başlarına geleni burada görürsün."
L.EMPTY_SHAREDNIL_HEAD = "Henüz DeathNote kullanan kimse yok."
L.EMPTY_SHAREDNIL_SUB = "Lonca üyelerinde ya da arkadaşlarında DeathNote olur olmaz defterin gönderilir."
L.EMPTY_SHAREDQUIET_HEAD = "Burada henüz bir şey yok."
L.EMPTY_SHAREDQUIET_SUB = "Lonca ve arkadaşlar şimdiye kadar rahattı."
L.EMPTY_HUNT_HEAD = "Av listesi boş."
L.EMPTY_HUNT_SUB = "Afişte: Avı başlat."
L.EMPTY_HUNT_HINT = "Ya da sohbette: /dn hunt İsim Soyad. Loncandaki herkes ve arkadaşların görür."
L.EMPTY_SEARCH_HEAD = "Sonuç yok."
L.EMPTY_SEARCH_SUB = "Enter, ismi deftere ekler."
L.EMPTY_SEARCHRO_HEAD = "Sonuç yok."
L.EMPTY_SEARCHRO_SUB = "Bazen farklı bir yazım işe yarar."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "DEFTER"  -- [max 12]
L.MANUAL_BOOK = "Açık dünyada seni öldüren kendiliğinden yazılır. Ölümünden sonraki mesaja tıklamak katilin sayfasını açar."
L.MANUAL_WANTED_HEAD = "ARANANLAR"  -- [max 12]
L.MANUAL_WANTED = "Katillerin, en kötüsü başta. Bir tık, suçlar ve notla birlikte afişi gösterir. Affedilenler üstü çizili olarak en sonda durur."
L.MANUAL_UNSOLVED_HEAD = "ÇÖZÜLMEMİŞ"  -- [max 13]
L.MANUAL_UNSOLVED = "Kimin yaptığı belli değilse dava burada bekler. Bir isme tıklamak katili belirler."
L.MANUAL_ALERT_HEAD = "ALARM"  -- [max 12]
L.MANUAL_ALERT = "Bir katil isim plakası, hedef ya da fare altında belirince defter seslenir. Bir tık onu hedef alır, savaşta ise ancak sonra."
L.MANUAL_ADD_HEAD = "EKLEME"  -- [max 12]
L.MANUAL_ADD = "Arama kutusuna bir isim yaz, Enter. Bir satıra sağ tık: intikamı not et, affet, sil."
L.MANUAL_GUILD_HEAD = "LONCA"  -- [max 12]
L.MANUAL_GUILD = "DeathNote kullanan lonca üyeleri ve arkadaşlar katili belli ölümlerini ve elle eklenenleri görür. Afiş ya da /dn hunt İsim: av listesine koy. Kelle parasına tıkla: kendininkini koy, sadece bir söz."
L.MANUAL_SHARE_HEAD = "AKTARMA"  -- [max 12]
L.MANUAL_SHARE = "Ev Kuralları, Defteri yedekle: DeathNote kullanmayan herkes için kopyalanacak bir metin."
L.MANUAL_QUIET_HEAD = "SESSİZLİK"  -- [max 12]
L.MANUAL_QUIET = "Zindanlarda ve savaş alanlarında alarm susar. Başka yerlerde: mini harita düğmesine orta tık ya da /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "{name} defterden gerçekten silinsin mi?\nTüm suçlar ve not kaybolacak."
L.CONFIRM_DELETE_OK = "Sil"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Bu bilgisayardaki lonca defteri boşaltılsın mı?\nAv listesi de gider, kendi çağrıların kalır.\nKendi defterin olduğu gibi kalır."
L.CONFIRM_GUILD_CLEAR_OK = "Boşalt"  -- [max 14]
L.CONFIRM_CANCEL = "Vazgeç"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ALTIN"  -- [max 14]
L.BOUNTY_SILVER = "{count} GÜMÜŞ"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Onayla"  -- [max 19]
L.ACT_DISMISS = "Şüpheyi kaldır"  -- [max 19]
L.ACT_HUNT_AGAIN = "Yeniden avla"  -- [max 19]
L.ACT_REVENGE = "İntikamı not et"  -- [max 19]
L.ACT_PARDON = "Affet"  -- [max 19]
L.ACT_STRIKE = "Sil"  -- [max 19]
L.ACT_OPEN_OWN = "Defterde aç"  -- [max 19]
L.ACT_ADOPT = "Defterime al"  -- [max 19]
L.ACT_CALLOFF = "Avı iptal et"  -- [max 19]
L.ACT_RELEASE = "Avı başlat"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "{time} görüldü"
L.ROW_NOT_SEEN = "henüz görülmedi"
L.ROW_PARDONED = "affedildi"
L.ROW_SUSPECT = "Şüpheli"
L.MARK_REVENGE = "İNTİKAM {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Katil belirsiz"
L.MARK_CANDIDATES = "{count} ADAY"  -- [max 16]
L.MARK_SUSPECT = "ŞÜPHELİ"  -- [max 16]
L.ROW_NO_PLAYER = "Oyuncu değil"
L.ROW_UNCLEAR = "Nasıl olduğu belirsiz"
L.MARK_NOT_COUNTED = "SAYILMAZ"  -- [max 16]
L.ROW_LISTED_BY = "ekleyen: {names}"
L.ROW_GKILLED = "{kills}× öldürdü"
L.ROW_VICTIMS = "{count} kurban"
L.ROW_LAST = "son: {text}"
L.MARK_IN_BOOK = "DEFTERDE"  -- [max 16]
L.MEMBER_KILLERS = "{count} katil"  -- [max 14]
L.MEMBER_DEATHS = "{count} ölüm"  -- [max 12]
L.MEMBER_LISTED = "{count} elle"  -- [max 14]
L.MEMBER_ME = "diğerlerinin senin hakkında gördüğü"
L.MEMBER_NOTHING = "henüz bir şey paylaşılmadı"
L.MEMBER_LAST_DIED = "son ölüm: {time}"
L.MARK_YOU = "sen"  -- [max 16]
L.MARK_FRIEND = "ARKADAŞ"  -- [max 16]
L.MARK_BOTH = "LONCA ÜYESİ, ARKADAŞ"  -- [max 20]
L.MARK_TAKEN_DOWN = "AVLANDI {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "ÖLÜ YA DA DİRİ"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "SUÇLAR"  -- [max 14]
L.POSTER_NOTE = "NOT"  -- [max 8]
L.POSTER_BOUNTY = "KELLE PARASI"  -- [max 12]
L.ROLE_ASSIST = "suç ortağı"  -- [max 14]
L.ROLE_SUSPECT = "şüpheli"  -- [max 14]
L.POSTER_LEVEL = "Seviye {level}"
L.POSTER_GUILD = "Lonca: {guild}"
L.POSTER_LAST_SEEN = "Son görülme: {time}"
L.POSTER_NOT_SEEN = "Henüz görülmedi"
L.POSTER_ONLY_SUSPECT = "Sadece şüphe, kanıtlanmış suç yok."
L.POSTER_NO_DEEDS = "Kayıtlı suç yok."
L.TIP_LISTED_AT = "Eklendi: {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Ölüm sebebi: {spell}"
L.TIP_VICTIM = "Kurban: {name}"
L.TIP_VICTIM_LEVEL = "Kurban: {name} (seviye {level})"
L.TIP_KILLER_LEVEL = "Katilin seviyesi: {level}"
L.TIP_ASSISTS = "Suç ortakları: {names}"
L.TIP_ROLE_ASSIST = "Suç ortağı, son darbeyi vurmadı."
L.TIP_ROLE_SUSPECT = "Sadece şüphe, kanıtlanmadı."
L.MORE_LINE = "… ve {count} tane daha"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "LONCA DEFTERİ"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Defterine yazan: {names}"
L.POSTER_SEEN = "Görüldü: {time}"
L.POSTER_SEEN_BY = "Görüldü: {time}, gören: {name}"
L.TIP_IN_BOOK_OF = "Defterine yazanlar"
L.POSTER_REMARK = "AÇIKLAMA"  -- [max 12]
L.POSTER_BY_HAND = "ELLE EKLENDİ"  -- [max 22]
L.POSTER_VICTIMS = "KURBANLAR"  -- [max 12]
L.POSTER_LISTED = "EKLEYEN"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Elle eklendi."
L.POSTER_NO_DEEDS_SENT = "Hiç suç aktarılmadı."
L.POSTER_NONE_KNOWN = "bilinen yok"
L.POSTER_NO_NAMES = "isim aktarılmadı"
L.TIP_VICTIMS = "Kurbanlar"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Çağrı: {time}"
L.HUNT_REASON = "Sebep: {reason}"
L.POSTER_HUNTLIST = "AV LİSTESİ"  -- [max 24]
L.POSTER_RELEASED_N = "{times} av listesine kondu"
L.POSTER_RELEASED_BY = "Çağıran: {names}"
L.POSTER_TAKEN_DOWN = "AVLANDI"  -- [max 12]
L.POSTER_NOT_YET = "HENÜZ DEĞİL"  -- [max 18]
L.POSTER_CALLS = "ÇAĞRILAR"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Artık kimse yok."
L.POSTER_LAST = "SON"  -- [max 13]
L.POSTER_TAKEN_BY = "avlayan: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "henüz kimse avlamadı"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Ölüm Dosyası"  -- [max 20]
L.CASE_ASSISTS = "SUÇ ORTAKLARI"  -- [max 24]
L.CASE_PICK = "KATİLİ BELİRLE"  -- [max 24]
L.CASE_NOT_COUNTED = "Sayılmaz (instance, savaş alanı ya da düello)"
L.CASE_KILLER = "KATİL"  -- [max 24]
L.CASE_KILLER_SUSPECT = "KATİL (ŞÜPHELİ)"  -- [max 24]
L.CASE_CLICK_NAME = "Afişini açmak için isme tıkla."
L.CASE_GONE = "Artık defterde değil."
L.CASE_KILLER_UNCLEAR = "KATİL BELİRSİZ"  -- [max 24]
L.CASE_SEVERAL = "Birden fazla kişi olabilir. Kimin ismi deftere girsin?"
L.CASE_NOBODY = "Hiç kimse olamazdı."
L.CASE_HOW = "NE OLDU"  -- [max 24]
L.CASE_PVE = "Bir canavar ya da dünyanın kendisi. Deftere düşecek bir dava değil."
L.CASE_UNCLEAR = "Belirsiz"
L.CASE_DARK = "Olay yeri ekibi karanlıkta el yordamıyla arıyor."
L.TIP_MORE_CANDIDATES = "Diğer adaylar"
L.CASE_SOURCE_SUSPECT = "Şüpheli: ölmeden kısa süre önce seni hedef almıştı."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Katillerde tooltip satırı"  -- [max 44]
L.OPT_MINIMAP = "Mini harita düğmesini göster"  -- [max 44]
L.OPT_ALERT = "Bir katil belirince alarm"  -- [max 44]
L.OPT_FLASH = "Ekran kenarı kırmızı yanıp sönsün"  -- [max 44]
L.OPT_SUSPECTS = "Şüphelileri de bildir"  -- [max 44]
L.OPT_DEATHMSG = "PvP ölümünden sonra mesaj"  -- [max 44]
L.OPT_G_SHARE = "Ölümlerimi paylaş"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Elle eklenenleri paylaş"  -- [max 44]
L.OPT_G_RECEIVE = "Lonca defterini al"  -- [max 44]
L.OPT_G_ALERT = "Lonca defterindeki katillerde uyar"  -- [max 44]
L.OPT_G_ALERTLISTED = "Elle eklenenlerde de uyar"  -- [max 44]
L.OPT_G_ANNOUNCE = "Bir lonca üyesi öldürülünce bildir"  -- [max 44]
L.OPT_G_SIGHTINGS = "Görülmeleri paylaş"  -- [max 44]
L.OPT_F_SHARE = "Loncayla paylaş"  -- [max 44]
L.OPT_F_FRIENDS = "Arkadaşlarla paylaş"  -- [max 44]
L.OPT_F_ALERT = "Lonca ve arkadaşların katillerinde uyar"  -- [max 44]
L.OPT_F_ALERTHUNT = "Av listesindeki hedeflerde uyar"  -- [max 44]
L.OPT_F_ANNOUNCE = "Lonca üyeleri ya da arkadaşlar ölünce bildir"  -- [max 44]
L.OPT_F_SIGHTINGS = "Görülmeleri lonca ve arkadaşlarla paylaş"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Lonca"  -- [max 14]
L.SET_BOOK_SIZE = "Defter boyutu"  -- [max 34]
L.SET_LANGUAGE = "Dil"  -- [max 16]
L.SET_LANG_AUTO = "Otomatik"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Yeniden yükleyince geçerli."  -- [max 28]
L.SET_LANG_RELOAD = "Şimdi yeniden yükle"  -- [max 22]
L.SET_SEC_SHARE = "AKTARMA"  -- [max 24]
L.IO_EXPORT = "Defteri yedekle"  -- [max 17]
L.IO_IMPORT = "Defteri içe aktar"  -- [max 17]
L.SET_HINT_BOOK = "Yedekleme defteri metin olarak verir: saklamak ya da lonca dışındakilere aktarmak için. İçe aktarma birleştirir, hiçbir şeyin üzerine yazmaz."
L.SET_SEC_SOUND = "SES"  -- [max 24]
L.SET_SOUND = "Ses"  -- [max 22]
L.SET_VOLUME = "Ses düzeyi"  -- [max 22]
L.SET_CHANNEL = "Kanal"  -- [max 12]
L.SET_SEC_THRESHOLD = "EŞİK"  -- [max 24]
L.SET_COOLDOWN = "Katil başına bekleme süresi"  -- [max 34]
L.SET_MINKILLS = "Ondan kaç ölümden sonra alarm"  -- [max 34]
L.SET_ALERT_SIZE = "Alarm boyutu"  -- [max 34]
L.SET_TEST_ALERT = "Deneme alarmı"  -- [max 17]
L.SET_G_MINKILLS = "Kaç ölümden sonra lonca uyarısı"  -- [max 34]
L.SET_F_MINKILLS = "Kaç ölümden sonra uyarı"  -- [max 34]
L.SET_SEC_STATUS = "DURUM"  -- [max 24]
L.SET_SEC_SHARING = "PAYLAŞIM"
L.SET_SEC_WARN = "ALARM"
L.SET_MORE = "Daha fazla"
L.SET_GUILD_CLEAR = "Lonca defterini boşalt"  -- [max 26]
L.SET_HINT_GUILD = "Sadece kendi loncan bir şey alır. Oradan gelen, sen kendin alana kadar defterinden ayrı kalır."
L.SET_HINT_FRIENDS = "Sadece DeathNote kullanan lonca üyeleri ve arkadaşlar bir şey alır."
L.BTN_BACK = "Geri"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Eşitle"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds} sn sonra"  -- [max 16]
L.TIP_FRIENDS = "Arkadaşlar"
L.TIP_GUILD_NAME = "Lonca: {guild}"
L.TIP_MATES_WITH = "DeathNote kullanan lonca üyeleri:"
L.TIP_NO_MATE = "Henüz DeathNote kullanan lonca üyesi yok."
L.TIP_FRIENDS_WITH = "DeathNote kullanan arkadaşlar:"
L.TIP_SHARED = "Paylaşılan: katili belli ölümlerin, elle eklenenler ve av çağrıların."
L.TIP_NOT_SHARED = "Paylaşılmayan: notlar, şüpheler, affedilenler, içe aktarılanlar."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "İçe aktar"  -- [max 17]
L.IO_DONE = "İçe aktarıldı: {new} yeni, {merged} birleştirildi."
L.IO_FAILED = "Olmadı."
L.IO_SMALL = "Sadece kısa"  -- [max 17]
L.IO_ALL = "Tümünü göster"  -- [max 17]
L.IO_MSG_FULL = "Suçlarıyla bütün defter ({size})."
L.IO_MSG_SHORT = "Sadece isimler ve sayılar ({size}). Suçlarla: {full}."
L.IO_MSG_BIG = "Büyük defter ({size}): seçmek ve kopyalamak biraz sürer."
L.IO_HELP_EXPORT = "Metin seçili: Ctrl+C ile kopyala. Sakla ya da arkadaşlarına aktar."
L.IO_HELP_IMPORT = "Yedeklenmiş metni Ctrl+V ile yapıştır, sonra İçe aktar. Hiçbir şeyin üzerine yazılmaz."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Sebebi, loncanda ve arkadaşlarında DeathNote kullanan herkes görür."
L.REL_HINT_GUILD = "Sebebi, loncanda DeathNote kullanan herkes görür."
L.REL_HINT_FRIENDS = "Sebebi, DeathNote kullanan arkadaşların görür."
L.REL_HEAD = "Av listesine koy"  -- [max 24]
L.REL_FOR = "KİME"  -- [max 6]
L.REL_REASON = "SEBEP"  -- [max 8]
L.REL_HINT2 = "Notun sende kalır. Kendi çağrını sadece sen iptal edebilirsin."
L.REL_GO = "Ava çağır"  -- [max 17]
L.REL_NONE = "Lonca yok ve arkadaşlarla paylaşım kapalı."
L.REL_CAP = "Liste başına en fazla {own} kendi çağrın ve {max} hedef."
L.REL_FAILED = "Şu an ava çağrılamıyor."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} sn"  -- [max 7]
L.SET_HINT_SILENT = "Ses yok: alarm sadece görünür."
L.SET_HINT_BUILTIN = "Bu sesin düzeyi, oyun ayarlarındaki kanalı izler."
L.SET_HINT_LEVELS = "Kısıktan yükseğe beş seviye. Oyun ayarlarındaki kanal sürgüsü bunun üstüne eklenir."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Lonca & Arkadaşlar"  -- [max 18]
L.TIP_HELP_BUTTON = "Defter nasıl çalışır"
L.VIEW_HUNT = "Av Listesi"  -- [max 13]
L.VIEW_BY_KILLER = "Katile göre"  -- [max 13]
L.VIEW_BY_MATE = "Üyeye göre"  -- [max 13]
L.SRC_ALL = "Tümü"  -- [max 12]
L.SRC_GUILD = "Lonca"  -- [max 12]
L.SRC_FRIENDS = "Arkadaşlar"  -- [max 12]
L.SORT_HIDE_PARDONED = "Affedilenleri gizle"  -- [max 24]
L.SORT_SHOW_PARDONED = "Affedilenleri göster"  -- [max 24]
L.SEARCH_ADD = "Ara ya da ekle …"  -- [max 26]
L.SEARCH_SHORT = "Ara …"  -- [max 10]
L.SEARCH_KILLER = "Katil ara …"  -- [max 15]
L.SEARCH_JOURNAL = "Katil ya da yer …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Tümünü daralt"
L.TIP_EXPAND_ALL = "Tümünü genişlet"
L.STATUS_NO_PLATES = "Düşman isim plakaları kapalı: alarm sadece hedefi ve fareyi görür."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "Aranan: {count}"
L.MM_UNSOLVED = "Çözülmemiş: {count}"
L.MM_ALERT_OFF = "Alarm kapalı (orta tık)"
L.MM_CLICK = "Tık: defter · Sağ tık: Ev Kuralları"
L.MM_MIDDLE = "Orta tık: alarm aç/kapat"
L.MM_DRAG = "Sürükle: mini harita kenarında taşı"
L.MM_CHAT_ALERT_ON = "Alarm açık."
L.MM_CHAT_ALERT_OFF = "Alarm kapalı."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "LONCA DÜŞMANI No. 1"  -- [max 25]
L.STAMP_HUNT = "AV SEZONU AÇIK"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name}, kendini arkadaşın {friend} olarak tanıttı: reddedildi."
L.FRIENDS_SHORT_IMPOSTOR = "Yabancı reddedildi"  -- [max 22]
L.ALERT_LEVEL = "Seviye {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "son seviye {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Seviye ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · av listesinde ({names})"
L.BANNER_NEW_HUNTS = "{count} yeni hedef"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "av listesine yeni eklendi"
L.OPT_F_ANNOUNCEHUNT = "Av listesi haberlerini bildir: yeni, avlandı"  -- [max 44]
L.SET_HUNT_EXPIRE = "Çağrı geçerlilik süresi"  -- [max 30]
L.SET_EXPIRE_NEVER = "Süresiz"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} gün"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Arkadaş defterini boşalt"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Bu bilgisayardaki arkadaş defteri boşaltılsın mı?\nAv listesi de gider, kendi çağrıların kalır."
L.CONFIRM_CALLOFF_ALL = "Av listesindeki tüm çağrıların iptal edilsin mi?\nLonca ve arkadaşlar bunu yavaş yavaş öğrenir."
L.CONFIRM_CALLOFF_ALL_OK = "Hepsini iptal"  -- [max 14]
L.ACT_CALLOFF_ALL = "Çağrılarımı iptal et"  -- [max 24]
L.ACT_HUNT_HIDE = "Benim için gizle"  -- [max 19]
L.ACT_HUNT_SHOW = "Tekrar göster"  -- [max 19]
L.HUNT_ROW_HIDDEN = "senin için gizli"
L.HUNT_ROW_CALLS = "{count} çağrı: {names}"
L.POSTER_ON_HUNTLIST = "Av listesinde ({names})"
L.REL_SELF = "Kendini av listesine koyamazsın."
L.REL_MATE = "Bu sizden biri (DeathNote kullanan lonca üyesi ya da arkadaş)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Arkadaşın {friend} hangisi: {a} mı, {b} mi? Seç."
L.FRIENDS_SHORT_CONFLICT = "Arkadaş belirsiz"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "İki oyuncu arkadaşın {friend} olduğunu söylüyor: {a} ve {b}. Sen seçene kadar defter ikisinden de hiçbir şey kabul etmiyor. Lonca & Arkadaşlar, Üyeye göre görünümü: isme sağ tıkla."
L.MEMBER_CONFLICT = "Sağ tık: bu senin arkadaşın mı?"  -- [max 40]
L.ACT_TIE_MINE = "Arkadaşım: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Bağı kopar"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "{name} arkadaş listenden ayrılsın mı?\nBu ismin arkadaş defterine getirdikleri silinir; bu isimle gelen sonraki mesaj yeniden bağlanır."
L.CHAT_FRIENDS_TIES = "Bağlı tam isimler (* = ilk temas, henüz doğrulanmadı): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <İsim [Soyad]> <altın>  kendi kelle paranı koy (tutar yok: geri al)"
L.CHAT_WHO_BOUNTY = "Kime? /dn bounty <İsim> <altın>"
L.CHAT_BOUNTY_SET = "{name}: {gold} altın kelle parası koydun. DeathNote kullanan lonca ve arkadaşlar görür."
L.CHAT_BOUNTY_OFF = "{name}: kelle paran geri alındı."
L.CHAT_BOUNTY_NONE = "Kendi kelle paran yok: {name}"
L.CHAT_BOUNTY_BAD = "Kelle parası: 1 ile 99999 arası tam sayı altın (0 geri alır)."
L.CHAT_BOUNTY_CAP = "Kelle parası yok: en fazla {count} tane senin olabilir."
L.CHAT_BOUNTY_OURS = "Kendine ya da kendi adamlarına (DeathNote kullanan lonca üyesi ya da arkadaş) kelle parası konmaz."
L.ACT_BOUNTY = "Kelle parası koy"  -- [max 24]
L.ACT_UNDO = "Geri al"  -- [max 19]
L.ACT_REVENGE_TAKE = "Bir intikamı düş"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, sen koydun"
L.POSTER_BOUNTY_BY = "{gold}, koyan: {name}"
L.POSTER_BOUNTY_MANY = "Kelle parası {gold}: {names}"
L.POSTER_AVENGED = "İntikamını alan: {names}"
L.ROW_AVENGED = "intikam {times}"
L.BOUNTY_TIP_HEAD = "Kendi kelle paran, altın olarak"
L.BOUNTY_TIP_RULES = "1 ile 99999 arası tam sayı. Boş ya da 0: defterin değerine döner. Enter koyar, Esc vazgeçer."
L.BOUNTY_TIP_PROMISE = "DeathNote kullanan lonca ve arkadaşlar görür. Sadece bir söz: hesap aranızda görülür."
L.BOUNTY_TIP_CLICK = "Tıkla: kendi kelle paranı koy"
L.CHAT_AVENGED = "{name} senin yerine avladı: {killer}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: {gold} altın kelle parası koydun."
L.CHAT_BOUNTY_UNKNOWN = "{name} hiçbir defterinde yok. Kelle parası yalnızca defterdeki bir isme konur, oyunda göründüğü gibi: ad ve soyad."
L.CHAT_BOUNTY_LIST = "Kelle paraların ({count}/{max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Hiç kelle parası koymadın."
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
L.MANUAL_RECORD = "Your own killing blows on players. Poster and list show the score 'you : them': open, even or overpaid; rank 1 is always an open case. Each kill earns points on four accounts; they make your rank and your path. The tab appears with your first kill. House Rules, sheet Rap Sheet: switch it off."
L.POSTER_LAST_SEEN_IN = "Last seen: {zone}, {time}"
L.SHEET_RECORD = "Rap Sheet"
-- <<< RECORD
end)
