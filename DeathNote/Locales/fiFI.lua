-- DeathNote: Suomi (fiFI). No official Finnish client: words as Finnish players use them (kilta, kohde, luolasto).
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.fiFI), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
-- Glossary: kirja, kiltakirja, kaverikirja, tappaja, kiltalainen, kaveri, Etsityt, Avoimet, Kuolinloki, Talon tavat,
-- juliste, leima, palkkio, muistiinpano, havainto, poistaa, armahtaa, kosto, epäilty, tappolista, julistaa jahti,
-- julistus, perua jahti, kaadettu, Varmuuskopioi, Tuo kirja.
-- Placeholders never carry a case ending: names stand after a colon or as plain subjects.
--
-- TOC-Notes: Kuolinlista avoimen maailman PvP:hen: muistaa, kuka sinut tappoi, ja varoittaa, kun hän on lähellä.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("fiFI")) then return end

Locale.Register("fiFI", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Etsityt"       -- [max 16]
L.TAB_UNSOLVED = "Avoimet"       -- [max 16]
L.TAB_DEATHLOG = "Kuolinloki"    -- [max 16]
L.TAB_GUILD    = "Kilta"         -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Talon tavat"     -- [max 24]
L.HEAD_HELP  = "Käyttöohje"      -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Kirja"          -- [max 14]
L.SHEET_ALERT = "Hälytys"        -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "YLEINEN VIHOLLINEN NRO 1"  -- [max 24]
L.STAMP_REVENGE  = "KOSTETTU"             -- [max 16]
L.STAMP_PARDONED = "ARMAHDETTU"           -- [max 16]
L.STAMP_SUSPECT  = "EPÄILTY"              -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "YLEINEN VIHOLLINEN LÄHELLÄ" -- [max 30]
L.ALERT_SIGHTED         = "KANSANVIHOLLINEN LÄHELLÄ"    -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "EPÄILTY LÄHELLÄ"             -- [max 30]
L.ALERT_TITLE_GUILD     = "KILLAN VIHOLLINEN LÄHELLÄ"   -- [max 30]
L.ALERT_TITLE_FRIENDS   = "KAVEREIDEN TAPPAJA LÄHELLÄ"  -- [max 30]
L.ALERT_TITLE_HUNT      = "TAPPOLISTAN KOHDE"           -- [max 30]
-- the line under the name; {times} = "3×" (see TIMES), {assists} = "1×"
L.ALERT_LINE_SUSPECT        = "on epäiltynä"
L.ALERT_LINE_KILLED         = "on tappanut sinut {times}"
L.ALERT_LINE_KILLED_ASSISTED = "on tappanut sinut {times}, avustanut {assists}"
L.ALERT_LINE_ASSISTED       = "on osallistunut kuolemaasi {times}"
L.ALERT_LINE_MANUAL         = "on kirjattu käsin"
L.ALERT_LINE_LAST    = "{text}, viimeksi {time}"
L.ALERT_LINE_IN      = "{text}, alue: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Kosto: {times}"
L.ALERT_HINT_CLOSE  = "Oikea klikkaus: sulje"                       -- [max 44]
L.ALERT_HINT_COMBAT = "Kohteeksi vasta taistelun jälkeen"           -- [max 44]
L.ALERT_HINT_TARGET = "Klikkaus: kohteeksi  ·  Oikea: sulje"        -- [max 44]
L.ALERT_MORE = "+{count} lisää"          -- [max 14]
L.SAMPLE_ZONE = "Stranglethorn Vale"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "on kiltakirjassa"
L.GUILD_LINE_IN_FRIENDS = "on kaverikirjassa"
L.GUILD_LINE_LISTED_BY  = "on kirjoissa: {names}"
L.GUILD_LINE_KILLED_GUILD   = "on tappanut kiltalaisia {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "on tappanut kavereita {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "on tappanut kiltalaisia ja kavereita {kills}×"
L.GUILD_LINE_LAST = "{text}, viimeksi {name}"
L.HUNT_LINE_BY       = "jahdin julistivat: {names}"
L.HUNT_LINE_RELEASED = "tappolistalla"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "epäiltynä"
L.TALLY_MANUAL   = "kirjattu käsin"
L.TALLY_NONE     = "ei vielä tekoja"
L.TALLY_KILLED   = "tappanut sinut {times}"
L.TALLY_ASSISTED = "avustanut {times}"
L.PLACE_UNKNOWN  = "tuntematon paikka"
L.GKILLS_CAP     = "vähintään {count}"
L.NAMELIST_MORE  = "{names} ja {count} muuta"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d.%m. %H.%M"
L.TIME_FMT_WHEN_YEAR = "%d.%m.%Y %H.%M"
L.TIME_FMT_DAY       = "%d.%m."
L.TIME_FMT_DAY_YEAR  = "%d.%m.%y"
L.TIME_NEVER   = "ei koskaan"
L.TIME_JUST    = "äsken"
L.TIME_MINUTES = "{count} min sitten"     -- [max 14]
L.TIME_HOURS   = "{count} t sitten"       -- [max 14]
L.TIME_DAYS    = "{count} pv sitten"      -- [max 16]
L.MONEY_GOLD   = "{count}g"
L.MONEY_SILVER = "{count}s"
L.MONEY_COPPER = "{count}c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Kiltalaisia, joilla on DeathNote: {count}."
L.HEALTH_NOGUILD = "Et ole missään killassa, mitään ei jaeta."
L.HEALTH_OFF     = "Jakaminen on pois päältä."
L.HEALTH_SHORT_NOGUILD = "Ei kiltaa"      -- [max 18]
L.HEALTH_SHORT_OFF     = "Jako pois"      -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Estetty"        -- [max 18]
L.HEALTH_SHORT_FAILING = "Hylätty"        -- [max 18]
L.HEALTH_SHORT_HOLD    = "Odottaa"        -- [max 18]
L.HEALTH_SHORT_ASKED   = "Pyydetty"        -- [max 18]
L.HEALTH_SHORT_FAIL    = "Ei toimi"       -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Ei ääntä"          -- [max 16]
L.SOUND_RAIDWARNING = "Raid-varoitus"     -- [max 16]
L.SOUND_BELL        = "Kello"             -- [max 16]
L.SOUND_GONG        = "Gongi"             -- [max 16]
L.SOUND_HEARTBEAT   = "Sydämenlyönti"     -- [max 16]
L.SOUND_FEATHER     = "Sulkakynä"         -- [max 16]
L.SOUND_SIREN       = "Sireeni"           -- [max 16]
L.CHANNEL_MASTER    = "Päävoimakkuus"     -- [max 16]
L.CHANNEL_SFX       = "Tehosteet"         -- [max 16]
L.CHANNEL_DIALOG    = "Dialogi"           -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} on nyt kirjassa."
L.CHAT_REMOVED   = "{name} on poistettu kirjasta."
L.CHAT_SYNC_WAIT = "Juuri synkronoitu. Yritä uudelleen {seconds} s päästä."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Ei vielä nimiä."
L.EMPTY_WANTED_SUB  = "Käy edes kerran ulkona."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  avaa/sulje kirja"
L.HELP_ADD      = "/dn add <Nimi [Sukunimi]>  kirjaa tappaja käsin kirjaan"
L.HELP_DEL      = "/dn del <Nimi [Sukunimi]>  poista tappaja kirjasta"
L.HELP_QUIET    = "/dn quiet  hälytys pois/päälle"
L.HELP_TEST     = "/dn test  näytä testihälytys"
L.HELP_GUILD    = "/dn guild  kiltakirja: tila ja kenellä kiltalaisista on DeathNote"
L.HELP_FRIENDS  = "/dn friends  kaverikirja: tila ja kenellä kavereista on DeathNote"
L.HELP_SYNC     = "/dn sync  synkronoi kiltakirja ja kaverikirja nyt"
L.HELP_HUNT     = "/dn hunt <Nimi [Sukunimi]>  julista jahti (ilman nimeä: näytä tappolista)"
L.HELP_CALLOFF  = "/dn calloff <Nimi [Sukunimi]>  peru oma jahtisi"
L.HELP_LANG     = "/dn lang <koodi>  kirjan kieli (enUS, deDE, fiFI ...), voimaan /reload-komennon jälkeen"
L.HELP_PROBE    = "/dn probe  vianetsintä: mitä peli kertoo kirjalle"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  vianetsintä, testaa myös taisteluloki"
L.HELP_DEBUG    = "/dn debug  vianetsintä: kirjaa jokainen kuolema tarkasti (päälle/pois)"
L.HELP_HELP     = "/dn help  tämä ohje"
L.HELP_SILENT_ZONES = "Luolastoissa, taistelukentillä ja areenoilla kirja pysyy itsestään hiljaa."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "päällä"
L.WORD_OFF = "pois"
L.CHAT_WHO_ADD  = "Kenet? /dn add <Nimi>"
L.CHAT_WHO_DEL  = "Kenet? /dn del <Nimi>"
L.CHAT_WHO_CALLOFF = "Kuka? /dn calloff <Nimi>"
L.CHAT_BAD_NAME = "Virheellinen nimi."
L.CHAT_NOT_IN_BOOK = "Ei kirjassa: {name}"
L.CHAT_ALARM_ON  = "Hälytys päällä."
L.CHAT_ALARM_OFF = "Hälytys pois."
L.CHAT_DEBUG = "Vianetsintäloki: {state}."
L.CHAT_UNKNOWN_CMD = "Tuntematon komento. Ohje: /dn help"
L.CHAT_GUILD_NOT_LOADED = "Kiltakirjaa ei ole ladattu."
L.CHAT_NO_GUILD = "Et ole missään killassa (tai peli ei vielä tiedä sitä)."
L.CHAT_GUILD_STATE = "Kilta {guild}: jakaminen {share}, vastaanotto {receive}."
L.CHAT_GUILD_BOOK = "Kiltakirja: tappajia {enemies} (vain käsin kirjattuja {listed}), tekoja {deeds}, muita kiltalaisia tappaneita {foreign}. Käsin kirjattujen jakaminen: {manual}."
L.CHAT_STATE_OK   = "Tila: {text}"
L.CHAT_STATE_WARN = "Huomio: {text}"
L.CHAT_NO_MATES   = "Ei vielä yhteyttä yhteenkään kiltalaiseen, jolla on DeathNote."
L.CHAT_HAVE_DN      = "DeathNote käytössä: {names}"
L.CHAT_HAVE_DN_MORE = "DeathNote käytössä: {names} ja {count} muuta"
L.CHAT_SYNC_ASKED = "Synkronointia pyydetty. Vastaukset tulevat muutamassa sekunnissa."
L.CHAT_SYNC_FAIL  = "Synkronointi ei toimi: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "ei kiltaa, tai jakaminen on pois päältä."
L.CHAT_FRIENDS_NOT_LOADED = "Kaverikirjaa ei ole ladattu."
L.CHAT_FRIENDS_STATE = "Kaverit: jakaminen {share}, paikalla {online}/{total}."
L.CHAT_FRIENDS_BOOK  = "Kaverikirja: tappajia {enemies} (vain käsin kirjattuja {listed}), tekoja {deeds}."
L.CHAT_NO_FRIENDS    = "Ei vielä yhteyttä yhteenkään kaveriin, jolla on DeathNote."
L.CHAT_HUNT_NOT_LOADED = "Tappolistaa ei ole ladattu."
L.CHAT_HUNT_UNKNOWN = "Tuntematon: {name}. Lisää myös sukunimi, niin kuin nimi näkyy pelissä."
L.CHAT_HUNT_CAP     = "Jahtia ei voi julistaa: enintään {own} omaa julistusta ja {targets} kohdetta listaa kohden."
L.CHAT_HUNT_NOWHERE = "Jahtia ei voi julistaa nyt: ei kiltaa, ja jakaminen kavereille on pois päältä."
L.CHAT_HUNT_BOTH    = "{name} on tappolistalla, killalle ja kavereille."
L.CHAT_HUNT_GUILD   = "{name} on tappolistalla, killalle."
L.CHAT_HUNT_FRIENDS = "{name} on tappolistalla, kavereillesi."
L.CHAT_CALLED_OFF   = "Jahti peruttu: {name}."
L.CHAT_NO_OWN_CALL  = "Sinulla ei ole omaa julistusta: {name}."
-- /dn lang; {lang} = language in its own name plus code, e.g. "Deutsch (deDE)"
L.CHAT_LANG_CURRENT = "Kieli nyt: {lang}. Vaihda: /dn lang <koodi>"
L.CHAT_LANG_LIST    = "Koodit: {codes}"
L.CHAT_LANG_BAD     = "Tuntematon kieli: {code}"
L.CHAT_LANG_SET     = "Kieli: {lang}."
L.CHAT_LANG_RELOAD  = "Kieli: {lang}. Voimaan /reload-komennon jälkeen."

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Kirja on valmiina. Jokainen, joka tappaa sinut avoimessa maailmassa, päätyy siihen. Avaa se komennolla /dn tai minikartan napista."
L.WELCOME_PLATES = "Vihollisten nimikyltit ovat pois päältä. Ilman niitä hälytys näkee vain kohteesi."
L.WELCOME_SHARE = "Kilta ja kaverit, joilla on DeathNote, lukevat mukana. Muistiinpanot ja epäilyt jäävät sinulle."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "KIRJASSA:"
L.TIP_HUNT      = "TAPPOLISTALLA:"
L.TIP_GUILDBOOK = "KILTAKIRJASSA:"
L.TIP_PARDONED  = "armahdettu"
L.TIP_RANK      = "sija {rank}"
L.TIP_REVENGE   = "kosto {times}"
L.TIP_LISTED_BY = "kirjoissa: {names}"
L.TIP_NOTE      = "Muistiinpano: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Klikkaus: avaa · Oikea klikkaus: pois"
L.BANNER_NEW          = "UUSI NIMI"            -- [max 24]
L.BANNER_NEW_LINE     = "on nyt kirjassa"
L.BANNER_AGAIN        = "JÄLLEEN"              -- [max 24]
L.BANNER_AGAIN_LINE   = "tappoi sinut taas, yhteensä {count} kertaa"
L.BANNER_SUSPECT      = "EPÄILTY"              -- [max 24]
L.BANNER_SUSPECT_LINE = "on epäiltynä, selvitä asia kirjassa"
L.BANNER_UNCLEAR      = "TAPPAJA EPÄSELVÄ"     -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|ehdokas|ehdokasta}"
L.BANNER_UNCLEAR_LINE = "Klikkaus: valitse tappaja kohdassa Avoimet"
L.BANNER_REVENGE      = "KOSTO"                -- [max 24]
L.BANNER_REVENGE_LINE = "Kosto otettu ({count}×)"
L.BANNER_GUILD        = "KILTA"                -- [max 24]
L.BANNER_FRIENDS      = "KAVERIT"              -- [max 24]
L.BANNER_KILLED_BY    = "kuoli, tappaja: {name}"
L.BANNER_HUNT         = "TAPPOLISTA"           -- [max 24]
L.BANNER_BAGGED       = "kaataja: {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Jakaminen on pois päältä (Talon tavat, välilehti Kilta)."
L.SYNC_FRIENDS_OFF = "Jakaminen kavereille on pois päältä."
L.SYNC_NOBODY      = "Ei kiltaa eikä kavereita, joille jakaa."
L.SYNC_SHORT_NOBODY = "Mitään ei jaeta"       -- [max 18]
L.SYNC_PREFIX      = "Peli ei salli vastaanottoa. Uudelleen kirjautuminen auttaa."
L.SYNC_SHORT_PREFIX = "Ei vastaanottoa"       -- [max 18]
L.SYNC_BLOCKED     = "Realm estää lähettämisen. Jaa eteenpäin toiminnolla Varmuuskopioi."
L.SYNC_SHORT_BLOCKED = "Realm estää lähetyksen" -- [max 22]
L.SYNC_FAILING     = "Lähetys ei juuri nyt onnistu, yritetään uudelleen."
L.SYNC_SHORT_FAILING = "Lähetys takkuaa"      -- [max 18]
L.SYNC_HOLD        = "Lähetys odottaa, {wait}."
L.SYNC_HOLD_INSTANCE = "kunnes poistut instanssista"
L.SYNC_HOLD_COMBAT   = "kunnes et ole enää taistelussa"
L.SYNC_HOLD_LOCKDOWN = "kunnes chat on taas vapaa"
L.SYNC_HOLD_AGAIN    = "kunnes se taas toimii"
L.SYNC_HOLD_SHORT_INSTANCE = "Odottaa: instanssi" -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Odottaa: taistelu"  -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Odottaa: chat"      -- [max 18]
L.SYNC_QUIET       = "Lähetetty, mutta ei vielä yhteyttä yhteenkään kiltalaiseen, jolla on DeathNote."
L.SYNC_READY       = "Valmis. Ei vielä yhteyttä yhteenkään kiltalaiseen, jolla on DeathNote."
L.SYNC_RUNNING     = "Käynnissä. Kiltalaisia, joilla on DeathNote: {count}."
L.SYNC_RUNNING_ALL = "Käynnissä. DeathNote-käyttäjiä killassa ja kaverilistalla: {count}."
L.FRIENDS_OFF      = "Jakaminen kavereille on pois päältä (Talon tavat, välilehti Kilta)."
L.FRIENDS_BLOCKED  = "Realm estää kuiskaukset. Kaverit eivät saa mitään."
L.FRIENDS_SHORT_BLOCKED = "Kuiskaukset estetty" -- [max 22]
L.FRIENDS_FAILING  = "Kuiskaukset eivät juuri nyt mene perille, yritetään uudelleen."
L.FRIENDS_SHORT_FAILING = "Kuiskaus takkuaa"    -- [max 18]
L.FRIENDS_NONE_LISTED = "Kaverilistalla ei ole ketään."
L.FRIENDS_NONE_ONLINE = "Yksikään kaveri ei ole juuri nyt paikalla."
L.FRIENDS_SHORT_NONE_ONLINE = "Kaverit offline"   -- [max 18]
L.FRIENDS_QUIET    = "Kysytty, mutta ei vielä yhteyttä yhteenkään kaveriin, jolla on DeathNote."
L.FRIENDS_READY    = "Valmis. Ei vielä yhteyttä yhteenkään kaveriin, jolla on DeathNote."
L.FRIENDS_HOLD     = "Lähetys kavereille odottaa, kunnes se taas toimii."
L.FRIENDS_RUNNING  = "Käynnissä. Kavereita, joilla on DeathNote: {count}."
-- A killer taken over from the guild book into your own book gets this note (your note from then on)
L.NOTE_FROM_GUILD  = "Otettu kiltakirjasta (tappanut kiltalaisia {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Tietokantaa ei ole ladattu."
L.IMPORT_NO_TEXT    = "Ei tekstiä."
L.IMPORT_NO_HEADER  = "Ensimmäinen rivi puuttuu (sen alku: {header}). Kopioi koko teksti."
L.IMPORT_NOT_EXPORT = "Ei DeathNote-vienti (otsikkorivi puuttuu tai versio on väärä)."
L.IMPORT_TOO_LONG   = "Liian monta riviä (enintään {count})."
L.IMPORT_BAD_KEY    = "Rivi {line}: virheellinen avain."
L.IMPORT_BAD_TIME   = "Rivi {line}: virheellinen aika."
L.IMPORT_BROKEN     = "Rivi {line} on vajaa tai rikki (katkennut teksti?). Mitään ei tuotu."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "kyllä"
L.WORD_NO  = "ei"
L.PROBE_HEAD = "Luotain: rajapintoja {apis}/{apisAll}, rekisteröitäviä tapahtumia {events}/{eventsAll}."
L.PROBE_MISSING = "Puuttuu: {list}"
L.PROBE_NOT_REGISTERABLE = "Ei rekisteröitävissä: {list}"
L.PROBE_SOURCES = "Recap nyt: {recap} · Meter: {meter} · Taisteluloki: {clog}"
L.PROBE_READABLE = "luettavissa"
L.PROBE_DEAD = "kuollut"
L.PROBE_PLATES = "Vihollisten nimikyltit: {plates} · Avoin maailma: {open}"
L.PROBE_PLATES_OFF = "POIS (vain kohde ja hiiri löytävät pelaajia)"
L.PROBE_TARGET = "Kohde: nimi={name} GUID={guid} luokka={class} vihamielinen={enemy} tähtää minuun={me}"
L.PROBE_GUILD = "Kilta: etuliite {prefix} · lähetys {send} · viimeisin paluuarvo {result} · lähetetty {sent}, vastaanotettu {received}, hylätty {dropped}"
L.PROBE_REGISTERED = "rekisteröity"
L.PROBE_NOT_REGISTERED = "EI rekisteröity ({result})"
L.PROBE_POSSIBLE = "mahdollinen"
L.PROBE_ABSENT = "puuttuu"
L.PROBE_WAITS = " · odottaa: {why}"
L.PROBE_LISTED = "Käsin kirjatut (M): lähetetty {sent}, vastaanotettu {received}, hylätty {dropped} · poistetut (X): lähetetty {usent}, vastaanotettu {ureceived}, hylätty {udropped}"
L.PROBE_GUILDBOOK = "Kiltakirja: {text}"
L.PROBE_SAVED = "Tallennettu: DeathNoteDB.probe (tiedostossa /reload-komennon jälkeen)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Sija"  -- [max 14]
L.SORT_RECENT = "Uusimmat"  -- [max 14]
L.SORT_NAME = "Nimi"  -- [max 14]
L.SORT_SEEN = "Nähty"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Jokainen, joka tappaa sinut avoimessa maailmassa, päätyy tänne. Ihan itsestään."
L.EMPTY_OPEN_HEAD = "Ei mitään selvitettävää."
L.EMPTY_JOURNAL_HEAD = "Et ole vielä kuollut."
L.EMPTY_JOURNAL_SUB = "Kunnioitettavaa. Tai valhetta."
L.EMPTY_NOGUILD_HEAD = "Ei kiltaa."
L.EMPTY_NOGUILD_SUB = "Yksinkin voi kuolla."
L.EMPTY_GUILDOFF_HEAD = "Kiltakirja on kiinni."
L.EMPTY_GUILDOFF_SUB = "Jakaminen on pois päältä. Talon tavat kertovat, mistä."
L.EMPTY_GUILDNIL_HEAD = "Killasta ei ole vielä kuulunut mitään."
L.EMPTY_GUILDNIL_SUB = "Kirjasi lähtee liikkeelle heti, kun jollakin kiltalaisella on DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Kiltakirjassa ei ole vielä mitään."
L.EMPTY_GUILDQUIET_SUB = "Kiltalaisillasi on ollut tähän asti rauhallista."
L.EMPTY_FRIENDSOFF_HEAD = "Kaverikirja on kiinni."
L.EMPTY_FRIENDSOFF_SUB = "Jakaminen kavereille on pois päältä. Talon tavat kertovat, mistä."
L.EMPTY_FRIENDSNIL_HEAD = "Ei vielä yhteyttä yhteenkään kaveriin, jolla on DeathNote."
L.EMPTY_FRIENDSNIL_SUB = "Kirjasi lähtee liikkeelle heti, kun jollakin kaverilla on DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Kavereiltasi ei ole vielä mitään."
L.EMPTY_FRIENDSQUIET_SUB = "Kavereillasi on ollut tähän asti rauhallista."
L.EMPTY_NOBODY_HEAD = "Ei kiltaa, ei kavereita."
L.EMPTY_NOBODY_SUB = "Yksinkin voi kuolla."
L.EMPTY_NOBODY_HINT = "Kun kiltalaisilla tai kaverilistasi kavereilla on DeathNote, tällä sivulla näkyy, mitä heille tapahtuu."
L.EMPTY_SHAREDNIL_HEAD = "Ei vielä yhteyttä kehenkään, jolla on DeathNote."
L.EMPTY_SHAREDNIL_SUB = "Kirjasi lähtee liikkeelle heti, kun kiltalaisilla tai kavereilla on DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Täällä ei ole vielä mitään."
L.EMPTY_SHAREDQUIET_SUB = "Killalla ja kavereilla on ollut tähän asti rauhallista."
L.EMPTY_HUNT_HEAD = "Tappolista on tyhjä."
L.EMPTY_HUNT_SUB = "Julisteessa: Julista jahti."
L.EMPTY_HUNT_HINT = "Tai chatissa: /dn hunt Nimi Sukunimi. Kaikki killassasi ja kaverisi näkevät sen."
L.EMPTY_SEARCH_HEAD = "Ei osumia."
L.EMPTY_SEARCH_SUB = "Enter kirjaa nimen kirjaan."
L.EMPTY_SEARCHRO_HEAD = "Ei osumia."
L.EMPTY_SEARCHRO_SUB = "Joskus toinen kirjoitusasu auttaa."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "KIRJA"  -- [max 12]
L.MANUAL_BOOK = "Jokainen, joka tappaa sinut avoimessa maailmassa, kirjataan itsestään. Kun klikkaat kuoleman jälkeistä ilmoitusta, tappajan sivu aukeaa."
L.MANUAL_WANTED_HEAD = "ETSITYT"  -- [max 12]
L.MANUAL_WANTED = "Tappajasi, pahin ensin. Klikkaus näyttää julisteen tekoineen ja muistiinpanoineen. Armahdetut ovat yliviivattuina lopussa."
L.MANUAL_UNSOLVED_HEAD = "AVOIMET"  -- [max 13]
L.MANUAL_UNSOLVED = "Kun ei ollut selvää, kuka sen teki, tapaus odottaa täällä. Nimen klikkaus ratkaisee, kuka on tappaja."
L.MANUAL_ALERT_HEAD = "HÄLYTYS"  -- [max 12]
L.MANUAL_ALERT = "Kun tappaja ilmestyy nimikylttinä, kohteena tai hiiren alle, kirja hälyttää. Klikkaus ottaa hänet kohteeksi, taistelussa vasta jälkeenpäin."
L.MANUAL_ADD_HEAD = "KIRJAAMINEN"  -- [max 12]
L.MANUAL_ADD = "Kirjoita nimi hakukenttään, Enter. Oikea klikkaus riviin: merkitse kosto, armahda, poista."
L.MANUAL_GUILD_HEAD = "KILTA"  -- [max 12]
L.MANUAL_GUILD = "Kiltalaiset ja kaverit, joilla on DeathNote, näkevät varmistetut kuolemasi ja käsin kirjatut nimet. Juliste tai /dn hunt Nimi: julista jahti. Napsauta palkkiota: aseta oma, se on vain lupaus."
L.MANUAL_SHARE_HEAD = "ETEENPÄIN"  -- [max 12]
L.MANUAL_SHARE = "Talon tavat, Varmuuskopioi: kopioitava teksti kaikille, joilta DeathNote puuttuu."
L.MANUAL_QUIET_HEAD = "HILJAA"  -- [max 12]
L.MANUAL_QUIET = "Luolastoissa ja taistelukentillä hälytys on hiljaa. Muuten: keskiklikkaus minikartan nappiin tai /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Poistetaanko {name} varmasti kirjasta?\nKaikki teot ja muistiinpano katoavat."
L.CONFIRM_DELETE_OK = "Poista"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Tyhjennetäänkö kiltakirja tältä koneelta?\nSen tappolista lähtee mukana, omat julistuksesi jäävät.\nOma kirjasi pysyy ennallaan."
L.CONFIRM_GUILD_CLEAR_OK = "Tyhjennä"  -- [max 14]
L.CONFIRM_CANCEL = "Peruuta"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} {count|KULTA|KULTAA}"  -- [max 14]
L.BOUNTY_SILVER = "{count} {count|HOPEA|HOPEAA}"  -- [max 14]
L.THOUSANDS_SEP = "\194\160"  -- no-break space (a plain space counts as empty in the test)
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Vahvista"  -- [max 19]
L.ACT_DISMISS = "Hylkää"  -- [max 19]
L.ACT_HUNT_AGAIN = "Jahtaa taas"  -- [max 19]
L.ACT_REVENGE = "Merkitse kosto"  -- [max 19]
L.ACT_PARDON = "Armahda"  -- [max 19]
L.ACT_STRIKE = "Poista"  -- [max 19]
L.ACT_OPEN_OWN = "Avaa kirjassa"  -- [max 19]
L.ACT_ADOPT = "Omaan kirjaan"  -- [max 19]
L.ACT_CALLOFF = "Peru jahti"  -- [max 19]
L.ACT_RELEASE = "Julista jahti"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "nähty {time}"
L.ROW_NOT_SEEN = "ei vielä havaittu"
L.ROW_PARDONED = "armahdettu"
L.ROW_SUSPECT = "Epäilty"
L.MARK_REVENGE = "KOSTO {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Tappaja epäselvä"
L.MARK_CANDIDATES = "{count} {count|EHDOKAS|EHDOKASTA}"  -- [max 16]
L.MARK_SUSPECT = "EPÄILTY"  -- [max 16]
L.ROW_NO_PLAYER = "Ei pelaaja"
L.ROW_UNCLEAR = "Kulku epäselvä"
L.MARK_NOT_COUNTED = "EI LASKETA"  -- [max 16]
L.ROW_LISTED_BY = "lisänneet: {names}"
L.ROW_GKILLED = "tappanut {kills}×"
L.ROW_VICTIMS = "{count} {count|uhri|uhria}"
L.ROW_LAST = "viimeksi {text}"
L.MARK_IN_BOOK = "KIRJASSA"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|tappaja|tappajaa}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|kuolema|kuolemaa}"  -- [max 12]
L.MEMBER_LISTED = "{count} käsin"  -- [max 14]
L.MEMBER_ME = "tämän muut näkevät sinusta"
L.MEMBER_NOTHING = "mitään ei ole vielä jaettu"
L.MEMBER_LAST_DIED = "kuoli viimeksi {time}"
L.MARK_YOU = "sinä"  -- [max 16]
L.MARK_FRIEND = "KAVERI"  -- [max 16]
L.MARK_BOTH = "KILTALAINEN, KAVERI"  -- [max 20]
L.MARK_TAKEN_DOWN = "KAADETTU {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "KUOLLEENA TAI ELÄVÄNÄ"  -- [max 24]
L.POSTER_DEEDS = "TEOT"  -- [max 14]
L.POSTER_NOTE = "MUISTIO"  -- [max 8]
L.POSTER_BOUNTY = "PALKKIO"  -- [max 12]
L.ROLE_ASSIST = "avusti"  -- [max 14]
L.ROLE_SUSPECT = "epäilty"  -- [max 14]
L.POSTER_LEVEL = "Taso {level}"
L.POSTER_GUILD = "Kilta: {guild}"
L.POSTER_LAST_SEEN = "Viimeksi nähty {time}"
L.POSTER_NOT_SEEN = "Ei vielä havaittu"
L.POSTER_ONLY_SUSPECT = "Vain epäilty, ei todistettua tekoa."
L.POSTER_NO_DEEDS = "Ei kirjattuja tekoja."
L.TIP_LISTED_AT = "Kirjattu {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Kuolinsyy: {spell}"
L.TIP_VICTIM = "Uhri: {name}"
L.TIP_VICTIM_LEVEL = "Uhri: {name} (taso {level})"
L.TIP_KILLER_LEVEL = "Tappajan taso: {level}"
L.TIP_ASSISTS = "Avustivat: {names}"
L.TIP_ROLE_ASSIST = "Avusti, ei antanut kuoliniskua."
L.TIP_ROLE_SUSPECT = "Vain epäilty, ei todistettu."
L.MORE_LINE = "… ja {count} muuta"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "KILTAKIRJA"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Kirjoissa: {names}"
L.POSTER_SEEN = "Nähty {time}"
L.POSTER_SEEN_BY = "Nähty {time} · havaitsija: {name}"
L.TIP_IN_BOOK_OF = "Kenen kirjoissa"
L.POSTER_REMARK = "HUOMAUTUS"  -- [max 12]
L.POSTER_BY_HAND = "KIRJATTU KÄSIN"  -- [max 22]
L.POSTER_VICTIMS = "UHRIT"  -- [max 12]
L.POSTER_LISTED = "KIRJANNEET"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Kirjattu käsin."
L.POSTER_NO_DEEDS_SENT = "Tekoja ei välitetty."
L.POSTER_NONE_KNOWN = "ei tunnettuja"
L.POSTER_NO_NAMES = "nimiä ei välitetty"
L.TIP_VICTIMS = "Uhrit"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Julistettu {time}"
L.HUNT_REASON = "Syy: {reason}"
L.POSTER_HUNTLIST = "TAPPOLISTA"  -- [max 24]
L.POSTER_RELEASED_N = "jahti julistettu {times}"
L.POSTER_RELEASED_BY = "Julistajat: {names}"
L.POSTER_TAKEN_DOWN = "KAADETTU"  -- [max 12]
L.POSTER_NOT_YET = "EI VIELÄ"  -- [max 18]
L.POSTER_CALLS = "JULISTUKSET"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Ei enää ketään."
L.POSTER_LAST = "VIIMEKSI"  -- [max 13]
L.POSTER_TAKEN_BY = "kaataja: {name}, {time}"
L.POSTER_TAKEN_NOBODY = "kukaan ei ole vielä kaatanut"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Kuolema"  -- [max 20]
L.CASE_ASSISTS = "AVUSTIVAT"  -- [max 24]
L.CASE_PICK = "VALITSE TAPPAJA"  -- [max 24]
L.CASE_NOT_COUNTED = "Ei lasketa (instanssi, taistelukenttä tai kaksintaistelu)"
L.CASE_KILLER = "TAPPAJA"  -- [max 24]
L.CASE_KILLER_SUSPECT = "TAPPAJA (EPÄILTY)"  -- [max 24]
L.CASE_CLICK_NAME = "Klikkaa nimeä, niin juliste aukeaa."
L.CASE_GONE = "Ei enää kirjassa."
L.CASE_KILLER_UNCLEAR = "TAPPAJA EPÄSELVÄ"  -- [max 24]
L.CASE_SEVERAL = "Useampi olisi voinut tehdä sen. Kenen nimi kirjaan?"
L.CASE_NOBODY = "Kukaan ei olisi voinut tehdä sitä."
L.CASE_HOW = "MITÄ TAPAHTUI"  -- [max 24]
L.CASE_PVE = "Hirviö tai maailma itse. Ei kirjan asia."
L.CASE_UNCLEAR = "Epäselvä"
L.CASE_DARK = "Rikostutkijat hapuilevat pimeässä."
L.TIP_MORE_CANDIDATES = "Lisää ehdokkaita"
L.CASE_SOURCE_SUSPECT = "Epäilty: piti sinua kohteenaan juuri ennen kuolemaasi."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Tooltip-rivi tappajien päällä"  -- [max 44]
L.OPT_MINIMAP = "Näytä minikartan nappi"  -- [max 44]
L.OPT_ALERT = "Hälytys, kun tappaja ilmestyy"  -- [max 44]
L.OPT_FLASH = "Välkytä ruudun reunaa punaisena"  -- [max 44]
L.OPT_SUSPECTS = "Ilmoita myös epäillyt"  -- [max 44]
L.OPT_DEATHMSG = "Ilmoitus PvP-kuoleman jälkeen"  -- [max 44]
L.OPT_G_SHARE = "Jaa omat kuolemani"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Jaa käsin kirjatut"  -- [max 44]
L.OPT_G_RECEIVE = "Vastaanota kiltakirja"  -- [max 44]
L.OPT_G_ALERT = "Varoita kiltakirjan tappajista"  -- [max 44]
L.OPT_G_ALERTLISTED = "Varoita myös käsin kirjatuista"  -- [max 44]
L.OPT_G_ANNOUNCE = "Ilmoita, kun kiltalainen tapetaan"  -- [max 44]
L.OPT_G_SIGHTINGS = "Jaa havainnot"  -- [max 44]
L.OPT_F_SHARE = "Jaa killalle"  -- [max 44]
L.OPT_F_FRIENDS = "Jaa kavereille"  -- [max 44]
L.OPT_F_ALERT = "Varoita killan ja kavereiden tappajista"  -- [max 44]
L.OPT_F_ALERTHUNT = "Varoita tappolistan kohteista"  -- [max 44]
L.OPT_F_ANNOUNCE = "Ilmoita, kun kiltalainen tai kaveri kuolee"  -- [max 44]
L.OPT_F_SIGHTINGS = "Jaa havainnot killalle ja kavereille"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Kilta"  -- [max 14]
L.SET_BOOK_SIZE = "Kirjan koko"  -- [max 34]
L.SET_LANGUAGE = "Kieli"  -- [max 16]
L.SET_LANG_AUTO = "Automaattinen"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Voimaan latauksen jälkeen."  -- [max 28]
L.SET_LANG_RELOAD = "Lataa uudelleen"  -- [max 22]
L.SET_SEC_SHARE = "ETEENPÄIN"  -- [max 24]
L.IO_EXPORT = "Varmuuskopioi"  -- [max 17]
L.IO_IMPORT = "Tuo kirja"  -- [max 17]
L.SET_HINT_BOOK = "Varmuuskopio antaa kirjan tekstinä: talteen tai annettavaksi killan ulkopuolisille. Tuonti yhdistää eikä korvaa mitään."
L.SET_SEC_SOUND = "ÄÄNI"  -- [max 24]
L.SET_SOUND = "Ääni"  -- [max 22]
L.SET_VOLUME = "Äänenvoimakkuus"  -- [max 22]
L.SET_CHANNEL = "Kanava"  -- [max 12]
L.SET_SEC_THRESHOLD = "KYNNYS"  -- [max 24]
L.SET_COOLDOWN = "Jäähy tappajaa kohden"  -- [max 34]
L.SET_MINKILLS = "Hälytysraja: tappoja"  -- [max 34]
L.SET_ALERT_SIZE = "Hälytyksen koko"  -- [max 34]
L.SET_TEST_ALERT = "Testihälytys"  -- [max 17]
L.SET_G_MINKILLS = "Kiltavaroituksen raja: tappoja"  -- [max 34]
L.SET_F_MINKILLS = "Varoitusraja: tappoja"  -- [max 34]
L.SET_SEC_STATUS = "TILA"  -- [max 24]
L.SET_SEC_SHARING = "JAKAMINEN"
L.SET_SEC_WARN = "HÄLYTYS"
L.SET_MORE = "Lisää"
L.SET_GUILD_CLEAR = "Tyhjennä kiltakirja"  -- [max 26]
L.SET_HINT_GUILD = "Vain oma kilta saa mitään. Sieltä tuleva pysyy erillään kirjastasi, kunnes otat sen itse."
L.SET_HINT_FRIENDS = "Vain kilta ja kaverit, joilla on DeathNote, saavat mitään."
L.BTN_BACK = "Takaisin"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synkronoi"  -- [max 14]
L.SYNC_AGAIN_IN = "{seconds} s päästä"  -- [max 16]
L.TIP_FRIENDS = "Kaverit"
L.TIP_GUILD_NAME = "Kilta: {guild}"
L.TIP_MATES_WITH = "Kiltalaiset, joilla on DeathNote:"
L.TIP_NO_MATE = "Ei vielä yhteyttä yhteenkään kiltalaiseen, jolla on DeathNote."
L.TIP_FRIENDS_WITH = "Kaverit, joilla on DeathNote:"
L.TIP_SHARED = "Jaetaan: varmistetut kuolemasi, käsin kirjatut nimet ja jahtijulistuksesi."
L.TIP_NOT_SHARED = "Ei jaeta: muistiinpanot, epäilyt, armahdetut, tuodut nimet."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Tuo"  -- [max 17]
L.IO_DONE = "Tuotu: uusia {new}, yhdistetty {merged}."
L.IO_FAILED = "Se ei onnistunut."
L.IO_SMALL = "Suppea versio"  -- [max 17]
L.IO_ALL = "Näytä kaikki"  -- [max 17]
L.IO_MSG_FULL = "Koko kirja tekoineen ({size})."
L.IO_MSG_SHORT = "Vain nimet ja määrät ({size}). Tekoineen: {full}."
L.IO_MSG_BIG = "Iso kirja ({size}): valinta ja kopiointi vievät hetken."
L.IO_HELP_EXPORT = "Teksti on valittu: Ctrl+C kopioi sen. Pidä tallessa tai anna kavereille."
L.IO_HELP_IMPORT = "Liitä varmuuskopioitu teksti näppäimillä Ctrl+V, sitten Tuo. Mitään ei korvata."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Kaikki killassasi ja kaverisi, joilla on DeathNote, näkevät syyn."
L.REL_HINT_GUILD = "Kaikki killassasi, joilla on DeathNote, näkevät syyn."
L.REL_HINT_FRIENDS = "Kaverisi, joilla on DeathNote, näkevät syyn."
L.REL_HEAD = "Julista jahti"  -- [max 24]
L.REL_FOR = "JAKO"  -- [max 6]
L.REL_REASON = "SYY"  -- [max 8]
L.REL_HINT2 = "Muistiinpanosi jää sinulle. Vain sinä voit perua oman julistuksesi."
L.REL_GO = "Julista"  -- [max 17]
L.REL_NONE = "Ei kiltaa, ja jakaminen kavereille on pois päältä."
L.REL_CAP = "Enintään {own} omaa julistusta ja {max} kohdetta listaa kohden."
L.REL_FAILED = "Jahtia ei voi julistaa juuri nyt."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Ei ääntä: hälytys vain näkyy."
L.SET_HINT_BUILTIN = "Tämän äänen voimakkuus seuraa kanavaa pelin asetuksissa."
L.SET_HINT_LEVELS = "Viisi tasoa hiljaisesta kovaan. Kanavan liukusäädin pelin asetuksissa vaikuttaa lisäksi."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Kilta & kaverit"  -- [max 18]
L.TIP_HELP_BUTTON = "Näin kirja toimii"
L.VIEW_HUNT = "Tappolista"  -- [max 13]
L.VIEW_BY_KILLER = "Tappajittain"  -- [max 13]
L.VIEW_BY_MATE = "Jäsenittäin"  -- [max 13]
L.SRC_ALL = "Kaikki"  -- [max 12]
L.SRC_GUILD = "Kilta"  -- [max 12]
L.SRC_FRIENDS = "Kaverit"  -- [max 12]
L.SORT_HIDE_PARDONED = "Piilota armahdetut"  -- [max 24]
L.SORT_SHOW_PARDONED = "Näytä armahdetut"  -- [max 24]
L.SEARCH_ADD = "Hae tai lisää …"  -- [max 26]
L.SEARCH_SHORT = "Hae …"  -- [max 10]
L.SEARCH_KILLER = "Etsi tappaja …"  -- [max 15]
L.SEARCH_JOURNAL = "Tappaja tai paikka …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Supista kaikki"
L.TIP_EXPAND_ALL = "Laajenna kaikki"
L.STATUS_NO_PLATES = "Vihollisten nimikyltit ovat pois: hälytys näkee vain kohteen ja hiiren."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|etsitty|etsittyä}"
L.MM_UNSOLVED = "{count} {count|avoin|avointa}"
L.MM_ALERT_OFF = "Hälytys on pois (keskiklikkaus)"
L.MM_CLICK = "Klikkaus: kirja · Oikea klikkaus: Talon tavat"
L.MM_MIDDLE = "Keskiklikkaus: hälytys päälle/pois"
L.MM_DRAG = "Vedä: siirrä minikartan reunaa pitkin"
L.MM_CHAT_ALERT_ON = "Hälytys päällä."
L.MM_CHAT_ALERT_OFF = "Hälytys pois."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "KILLAN VIHOLLINEN #1"  -- [max 25]
L.STAMP_HUNT = "VAPAATA RIISTAA"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "Hylätty: {name} yritti esiintyä kaverinasi (kaveri: {friend})."
L.FRIENDS_SHORT_IMPOSTOR = "Tuntematon hylätty"  -- [max 22]
L.ALERT_LEVEL = "Taso {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "viimeksi taso {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Taso ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · tappolistalla ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|uusi kohde|uutta kohdetta}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "uutta tappolistalla"
L.OPT_F_ANNOUNCEHUNT = "Ilmoita tappolistan uutiset: uudet, kaadetut"  -- [max 44]
L.SET_HUNT_EXPIRE = "Julistusten voimassaolo"  -- [max 30]
L.SET_EXPIRE_NEVER = "Aina"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} pv"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Tyhjennä kaverikirja"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Tyhjennetäänkö kaverikirja tältä koneelta?\nSen tappolista lähtee mukana, omat julistuksesi jäävät."
L.CONFIRM_CALLOFF_ALL = "Perutaanko kaikki julistuksesi?\nKilta ja kaverit saavat tiedon vähitellen."
L.CONFIRM_CALLOFF_ALL_OK = "Peru kaikki"  -- [max 14]
L.ACT_CALLOFF_ALL = "Peru kaikki omani"  -- [max 24]
L.ACT_HUNT_HIDE = "Piilota minulta"  -- [max 19]
L.ACT_HUNT_SHOW = "Näytä taas"  -- [max 19]
L.HUNT_ROW_HIDDEN = "piilotettu sinulta"
L.HUNT_ROW_CALLS = "{count} {count|julistus|julistusta}: {names}"
L.POSTER_ON_HUNTLIST = "Tappolistalla ({names})"
L.REL_SELF = "Et voi julistaa jahtia itseäsi vastaan."
L.REL_MATE = "Tämä on omiasi (kiltalainen tai kaveri, jolla on DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Kuka on kaverisi {friend}: {a} vai {b}? Valitse."
L.FRIENDS_SHORT_CONFLICT = "Kaveri epäselvä"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Kaksi pelaajaa väittää olevansa kaverisi {friend}: {a} ja {b}. Ennen kuin valitset, kirja ei ota keneltäkään heistä mitään vastaan. Kilta & kaverit, näkymä Jäsenittäin: oikea klikkaus nimeen."
L.MEMBER_CONFLICT = "Oikea klikkaus: onko tämä kaverisi?"  -- [max 40]
L.ACT_TIE_MINE = "Kaverini: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Irrota nimi"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Irrotetaanko {name} kaverilistastasi?\nKaikki, mitä tämä nimi toi kaverikirjaan, poistetaan; seuraava viesti tällä etunimellä yhdistetään uudelleen."
L.CHAT_FRIENDS_TIES = "Yhdistetyt koko nimet (* = ensimmäinen yhteys, ei vielä vahvistettu): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Nimi [Sukunimi]> <kulta>  aseta oma palkkio (ilman summaa: peru se)"
L.CHAT_WHO_BOUNTY = "Kenestä? /dn bounty <Nimi> <kulta>"
L.CHAT_BOUNTY_SET = "{name}: asetit {gold} kullan palkkion. Kiltalaiset ja kaverit, joilla on DeathNote, näkevät sen."
L.CHAT_BOUNTY_OFF = "{name}: palkkiosi on peruttu."
L.CHAT_BOUNTY_NONE = "Sinulla ei ole omaa palkkiota: {name}."
L.CHAT_BOUNTY_BAD = "Palkkio: kokonaisluku kultaa 1:stä 99999:ään (0 peruu sen)."
L.CHAT_BOUNTY_CAP = "Ei palkkiota: enintään {count} omaa."
L.CHAT_BOUNTY_OURS = "Ei palkkiota itsestäsi eikä omistasi (kiltalaiset tai kaverit, joilla on DeathNote)."
L.ACT_BOUNTY = "Aseta palkkio"  -- [max 24]
L.ACT_UNDO = "Kumoa"  -- [max 19]
L.ACT_REVENGE_TAKE = "Vähennä yksi kosto"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, asettanut sinä"
L.POSTER_BOUNTY_BY = "{gold}, asettanut {name}"
L.POSTER_BOUNTY_MANY = "Palkkio {gold}: {names}"
L.POSTER_AVENGED = "Kostajat: {names}"
L.ROW_AVENGED = "kostettu {times}"
L.BOUNTY_TIP_HEAD = "Oma palkkiosi kultana"
L.BOUNTY_TIP_RULES = "Kokonaisluku 1:stä 99999:ään. Tyhjä tai 0: takaisin kirjan arvoon. Enter asettaa, Esc peruu."
L.BOUNTY_TIP_PROMISE = "Kiltalaiset ja kaverit, joilla on DeathNote, näkevät sen. Vain lupaus: sovitte keskenänne."
L.BOUNTY_TIP_CLICK = "Napsautus: aseta oma palkkio"
L.CHAT_AVENGED = "{name} kaatoi puolestasi: {killer}."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: asetit {gold} kullan palkkion."
L.CHAT_BOUNTY_UNKNOWN = "{name} ei ole missään kirjassasi. Palkkion voi asettaa vain kirjassa olevalle nimelle, niin kuin peli sen näyttää: etunimi ja sukunimi."
L.CHAT_BOUNTY_LIST = "Omat palkkiosi ({count}/{max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Et ole asettanut palkkiota."
-- <<< BOOK
end)
