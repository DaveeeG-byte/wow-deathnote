-- DeathNote: Français (frFR). Translated from enUS.lua (meaning from deDE.lua); game terms as in the French client.
-- Plural: 2 forms {count|one|other} (0 and 1 | everything else). Rule in Locale.lua (PLURAL_OF.frFR), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
--
-- TOC-Notes: Liste noire pour le JcJ en monde ouvert : retient tes tueurs et te prévient quand ils rôdent près de toi.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("frFR")) then return end

Locale.Register("frFR", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Recherchés"      -- [max 16]
L.TAB_UNSOLVED = "Non élucidés"    -- [max 16]
L.TAB_DEATHLOG = "Nécrologie"      -- [max 16]
L.TAB_GUILD    = "Guilde"          -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Règlement intérieur"  -- [max 24]
L.HEAD_HELP  = "Mode d'emploi"        -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Carnet"         -- [max 14]
L.SHEET_ALERT = "Alerte"         -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "ENNEMI PUBLIC N° 1"  -- [max 24]
L.STAMP_REVENGE  = "COMPTE RÉGLÉ"        -- [max 16]
L.STAMP_PARDONED = "GRÂCE ACCORDÉE"      -- [max 16]
L.STAMP_SUSPECT  = "SUSPECT"             -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "ENNEMI PUBLIC N° 1 REPÉRÉ"   -- [max 30]
L.ALERT_SIGHTED         = "ENNEMI PUBLIC REPÉRÉ"        -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "SUSPECT REPÉRÉ"              -- [max 30]
L.ALERT_TITLE_GUILD     = "ENNEMI DE LA GUILDE REPÉRÉ"  -- [max 30]
L.ALERT_TITLE_FRIENDS   = "TUEUR D'AMIS REPÉRÉ"         -- [max 30]
L.ALERT_TITLE_HUNT      = "CIBLE DE LA LISTE DE CHASSE" -- [max 30]
L.ALERT_LINE_SUSPECT        = "fait l'objet de soupçons"
L.ALERT_LINE_KILLED         = "a causé ta mort {times}"
L.ALERT_LINE_KILLED_ASSISTED = "a causé ta mort {times}, complice {assists}"
L.ALERT_LINE_ASSISTED       = "a pris part à ta mort {times}"
L.ALERT_LINE_MANUAL         = "figure dans le carnet (ajout manuel)"
L.ALERT_LINE_LAST    = "{text}, dernière fois {time}"
L.ALERT_LINE_IN      = "{text}, zone : {zone}"
L.ALERT_LINE_REVENGE = "{text}. Vengeance : {times}"
L.ALERT_HINT_CLOSE  = "Clic droit : fermer"                         -- [max 44]
L.ALERT_HINT_COMBAT = "Ciblage seulement après le combat"           -- [max 44]
L.ALERT_HINT_TARGET = "Clic : cibler  ·  Clic droit : fermer"       -- [max 44]
L.ALERT_MORE = "+{count} {count|autre|autres}"         -- [max 14]
L.SAMPLE_ZONE = "Vallée de Strangleronce"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "figure dans le carnet de guilde"
L.GUILD_LINE_IN_FRIENDS = "figure dans le carnet des amis"
L.GUILD_LINE_LISTED_BY  = "figure dans le carnet de : {names}"
L.GUILD_LINE_KILLED_GUILD   = "a tué des membres de la guilde {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "a tué des amis {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "a tué des membres de la guilde et des amis {kills}×"
L.GUILD_LINE_LAST = "{text}, dernière victime : {name}"
L.HUNT_LINE_BY       = "chasse ouverte par {names}"
L.HUNT_LINE_RELEASED = "sur la liste de chasse"
L.HUNT_LINE_REASON   = "{text} : {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "sous soupçon"
L.TALLY_MANUAL   = "ajout manuel"
L.TALLY_NONE     = "aucun méfait pour l'instant"
L.TALLY_KILLED   = "a causé ta mort {times}"
L.TALLY_ASSISTED = "complice {times}"
L.PLACE_UNKNOWN  = "lieu inconnu"
L.GKILLS_CAP     = "au moins {count}"
L.NAMELIST_MORE  = "{names} et {count} {count|autre|autres}"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d/%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d/%m/%Y %H:%M"
L.TIME_FMT_DAY       = "%d/%m"
L.TIME_FMT_DAY_YEAR  = "%d/%m/%y"
L.TIME_NEVER   = "jamais"
L.TIME_JUST    = "à l'instant"
L.TIME_MINUTES = "il y a {count} min"     -- [max 14]
L.TIME_HOURS   = "il y a {count} h"       -- [max 14]
L.TIME_DAYS    = "il y a {count} {count|jour|jours}"       -- [max 16]
L.MONEY_GOLD   = "{count} po"
L.MONEY_SILVER = "{count} pa"
L.MONEY_COPPER = "{count} pc"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Nouvelles reçues de {count} {count|membre|membres} de la guilde avec DeathNote."
L.HEALTH_NOGUILD = "Tu n'es dans aucune guilde, rien n'est partagé."
L.HEALTH_OFF     = "Le partage est désactivé."
L.HEALTH_SHORT_NOGUILD = "Pas de guilde"     -- [max 18]
L.HEALTH_SHORT_OFF     = "Partage désactivé" -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Bloqué"            -- [max 18]
L.HEALTH_SHORT_FAILING = "Refusé"            -- [max 18]
L.HEALTH_SHORT_HOLD    = "En attente"        -- [max 18]
L.HEALTH_SHORT_ASKED   = "Demandé"           -- [max 18]
L.HEALTH_SHORT_FAIL    = "Ne marche pas"     -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Aucun son"         -- [max 16]
L.SOUND_RAIDWARNING = "Alerte de raid"    -- [max 16]
L.SOUND_BELL        = "Cloche"            -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Cœur battant" -- [max 16]
L.SOUND_FEATHER     = "Plume"             -- [max 16]
L.SOUND_SIREN       = "Sirène"            -- [max 16]
L.CHANNEL_MASTER    = "Principal"         -- [max 16]
L.CHANNEL_SFX       = "Effets"            -- [max 16]
L.CHANNEL_DIALOG    = "Dialogues"         -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} figure désormais dans le carnet."
L.CHAT_REMOVED   = "{name} ne figure plus dans le carnet."
L.CHAT_SYNC_WAIT = "Synchro faite à l'instant. Réessaie dans {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Aucun nom pour l'instant."
L.EMPTY_WANTED_SUB  = "Sors un peu, pour changer."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  ouvrir/fermer le carnet"
L.HELP_ADD      = "/dn add <Prénom [Nom]>  inscrire un tueur à la main"
L.HELP_DEL      = "/dn del <Prénom [Nom]>  rayer un tueur du carnet"
L.HELP_QUIET    = "/dn quiet  alerte désactivée/activée"
L.HELP_TEST     = "/dn test  afficher une alerte de test"
L.HELP_GUILD    = "/dn guild  carnet de guilde : état et membres qui ont DeathNote"
L.HELP_FRIENDS  = "/dn friends  carnet des amis : état et amis qui ont DeathNote"
L.HELP_SYNC     = "/dn sync  synchroniser maintenant le carnet de guilde et celui des amis"
L.HELP_HUNT     = "/dn hunt <Prénom [Nom]>  ouvrir la chasse (sans nom : afficher la liste de chasse)"
L.HELP_CALLOFF  = "/dn calloff <Prénom [Nom]>  arrêter ta propre chasse"
L.HELP_LANG     = "/dn lang <code>  langue du carnet (enUS, deDE, frFR ...), après /reload"
L.HELP_THEME = "/dn theme <nom>  couverture du carnet, après /reload"
L.HELP_PROBE    = "/dn probe  dépannage : ce que le jeu révèle au carnet"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  dépannage, avec test du journal de combat"
L.HELP_DEBUG    = "/dn debug  dépannage : noter chaque mort en détail (activé/désactivé)"
L.HELP_HELP     = "/dn help  cette aide"
L.HELP_SILENT_ZONES = "Dans les donjons, champs de bataille et arènes, le carnet se tait de lui-même."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "oui"
L.WORD_OFF = "non"
L.CHAT_WHO_ADD  = "Qui ça ? /dn add <Nom>"
L.CHAT_WHO_DEL  = "Qui ça ? /dn del <Nom>"
L.CHAT_WHO_CALLOFF = "Qui ça ? /dn calloff <Nom>"
L.CHAT_BAD_NAME = "Nom invalide."
L.CHAT_NOT_IN_BOOK = "Absent du carnet : {name}"
L.CHAT_ALARM_ON  = "Alerte activée."
L.CHAT_ALARM_OFF = "Alerte désactivée."
L.CHAT_DEBUG = "Journal de dépannage : {state}."
L.CHAT_UNKNOWN_CMD = "Commande inconnue. Aide : /dn help"
L.CHAT_GUILD_NOT_LOADED = "Le carnet de guilde n'est pas chargé."
L.CHAT_NO_GUILD = "Tu n'es dans aucune guilde (ou le jeu ne le sait pas encore)."
L.CHAT_GUILD_STATE = "Guilde {guild} · partage : {share}, réception : {receive}."
L.CHAT_GUILD_BOOK = "Carnet de guilde : {enemies} tueurs ({listed} seulement ajoutés à la main), {deeds} {deeds|méfait|méfaits}, {foreign} tueurs de membres de la guilde. Partager les ajouts manuels : {manual}."
L.CHAT_STATE_OK   = "État : {text}"
L.CHAT_STATE_WARN = "Attention : {text}"
L.CHAT_NO_MATES   = "Aucune nouvelle d'un membre de la guilde avec DeathNote pour l'instant."
L.CHAT_HAVE_DN      = "Ont DeathNote : {names}"
L.CHAT_HAVE_DN_MORE = "Ont DeathNote : {names} et {count} {count|autre|autres}"
L.CHAT_SYNC_ASKED = "Synchronisation demandée. Les réponses arrivent dans les secondes qui viennent."
L.CHAT_SYNC_FAIL  = "La synchronisation ne marche pas : {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "pas de guilde ou partage désactivé."
L.CHAT_FRIENDS_NOT_LOADED = "Le carnet des amis n'est pas chargé."
L.CHAT_FRIENDS_STATE = "Amis · partage : {share}, {online} sur {total} en ligne."
L.CHAT_FRIENDS_BOOK  = "Carnet des amis : {enemies} tueurs ({listed} seulement ajoutés à la main), {deeds} {deeds|méfait|méfaits}."
L.CHAT_NO_FRIENDS    = "Aucune nouvelle d'un ami avec DeathNote pour l'instant."
L.CHAT_HUNT_NOT_LOADED = "La liste de chasse n'est pas chargée."
L.CHAT_HUNT_UNKNOWN = "Nom inconnu : {name}. Ajoute aussi le nom de famille, comme il s'affiche en jeu."
L.CHAT_HUNT_CAP     = "Impossible d'ouvrir la chasse : au plus {own} appels de ta part et {targets} cibles par liste."
L.CHAT_HUNT_NOWHERE = "Impossible d'ouvrir la chasse pour l'instant : pas de guilde, et le partage avec les amis est désactivé."
L.CHAT_HUNT_BOTH    = "Chasse ouverte sur {name}, pour la guilde et les amis."
L.CHAT_HUNT_GUILD   = "Chasse ouverte sur {name}, pour la guilde."
L.CHAT_HUNT_FRIENDS = "Chasse ouverte sur {name}, pour tes amis."
L.CHAT_CALLED_OFF   = "Chasse sur {name} arrêtée."
L.CHAT_NO_OWN_CALL  = "Tu n'as lancé aucun appel sur {name}."
L.CHAT_LANG_CURRENT = "Langue actuelle : {lang}. Changer : /dn lang <code>"
L.CHAT_LANG_LIST    = "Codes : {codes}"
L.CHAT_LANG_BAD     = "Langue inconnue : {code}"
L.CHAT_LANG_SET     = "Langue : {lang}."
L.CHAT_LANG_RELOAD  = "Langue : {lang}. Effective après /reload."
L.CHAT_THEME_CURRENT = "Couverture actuelle : {theme}. Changer : /dn theme <nom>"
L.CHAT_THEME_LIST = "Couvertures : {themes}"
L.CHAT_THEME_BAD = "Couverture inconnue : {name}"
L.CHAT_THEME_SET = "Couverture : {theme}."
L.CHAT_THEME_RELOAD = "Couverture : {theme}. Effective après /reload."
L.THEME_NOTEBOOK = "Le Carnet noir"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "Le carnet est prêt. Qui te tue en monde ouvert y figure ensuite. Ouvre-le avec /dn ou le bouton de la minicarte."
L.WELCOME_PLATES = "Les barres d'info ennemies sont désactivées. Sans elles, l'alerte ne voit que ta cible."
L.WELCOME_SHARE = "La guilde et les amis qui ont DeathNote le lisent aussi. Notes et soupçons restent chez toi."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "DANS LE CARNET :"
L.TIP_HUNT      = "LISTE DE CHASSE :"
L.TIP_GUILDBOOK = "CARNET DE GUILDE :"
L.TIP_PARDONED  = "grâce accordée"
L.TIP_RANK      = "rang {rank}"
L.TIP_REVENGE   = "vengeance {times}"
L.TIP_LISTED_BY = "dans le carnet de : {names}"
L.TIP_NOTE      = "Note : {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Clic : ouvrir · Clic droit : fermer"
L.BANNER_NEW          = "NOUVELLE ENTRÉE"      -- [max 24]
L.BANNER_NEW_LINE     = "figure désormais dans le carnet"
L.BANNER_AGAIN        = "ENCORE"               -- [max 24]
L.BANNER_AGAIN_LINE   = "récidive : déjà {count} fois"
L.BANNER_SUSPECT      = "SOUPÇON"              -- [max 24]
L.BANNER_SUSPECT_LINE = "fait l'objet de soupçons, à trancher dans le carnet"
L.BANNER_UNCLEAR      = "TUEUR INCERTAIN"      -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|piste|pistes}"
L.BANNER_UNCLEAR_LINE = "Clic : désigner le tueur dans Non élucidés"
L.BANNER_REVENGE      = "VENGEANCE"            -- [max 24]
L.BANNER_REVENGE_LINE = "Compte réglé ({count}×)"
L.BANNER_GUILD        = "GUILDE"               -- [max 24]
L.BANNER_FRIENDS      = "AMIS"                 -- [max 24]
L.BANNER_KILLED_BY    = "a péri sous les coups de {name}"
L.BANNER_HUNT         = "LISTE DE CHASSE"      -- [max 24]
L.BANNER_BAGGED       = "victime de {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Le partage est désactivé (Règlement intérieur, feuille Guilde)."
L.SYNC_FRIENDS_OFF = "Le partage avec les amis est désactivé."
L.SYNC_NOBODY      = "Ni guilde ni amis avec qui partager."
L.SYNC_SHORT_NOBODY = "Rien de partagé"           -- [max 18]
L.SYNC_PREFIX      = "Le jeu n'autorise aucune réception. Se reconnecter aide."
L.SYNC_SHORT_PREFIX = "Réception bloquée"         -- [max 18]
L.SYNC_BLOCKED     = "Le royaume bloque l'envoi. Fais passer le carnet avec Sauvegarder."
L.SYNC_SHORT_BLOCKED = "Royaume bloque l'envoi"   -- [max 22]
L.SYNC_FAILING     = "L'envoi échoue en ce moment, nouvel essai en cours."
L.SYNC_SHORT_FAILING = "L'envoi coince"         -- [max 18]
L.SYNC_HOLD        = "L'envoi attend {wait}."
L.SYNC_HOLD_INSTANCE = "que tu quittes l'instance"
L.SYNC_HOLD_COMBAT   = "la fin du combat"
L.SYNC_HOLD_LOCKDOWN = "que le chat soit libre"
L.SYNC_HOLD_AGAIN    = "que ça remarche"
L.SYNC_HOLD_SHORT_INSTANCE = "Attente : instance" -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Attente : combat"   -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Attente : chat"   -- [max 18]
L.SYNC_QUIET       = "Envoyé, mais aucune nouvelle d'un membre de la guilde avec DeathNote."
L.SYNC_READY       = "Prêt. Aucune nouvelle d'un membre de la guilde avec DeathNote."
L.SYNC_RUNNING     = "En marche : {count} {count|membre|membres} de la guilde avec DeathNote."
L.SYNC_RUNNING_ALL = "En marche : {count} avec DeathNote dans la guilde et chez les amis."
L.FRIENDS_OFF      = "Le partage avec les amis est désactivé (Règlement intérieur, feuille Guilde)."
L.FRIENDS_BLOCKED  = "Le royaume bloque les chuchotements. Les amis ne reçoivent rien."
L.FRIENDS_SHORT_BLOCKED = "Chuchotements bloqués"      -- [max 22]
L.FRIENDS_FAILING  = "Les chuchotements échouent en ce moment, nouvel essai en cours."
L.FRIENDS_SHORT_FAILING = "Amis : ça coince"     -- [max 18]
L.FRIENDS_NONE_LISTED = "Aucun ami dans la liste d'amis."
L.FRIENDS_NONE_ONLINE = "Aucun ami en ligne en ce moment."
L.FRIENDS_SHORT_NONE_ONLINE = "Aucun ami en ligne" -- [max 18]
L.FRIENDS_QUIET    = "Demandé, mais aucune nouvelle d'un ami avec DeathNote."
L.FRIENDS_READY    = "Prêt. Aucune nouvelle d'un ami avec DeathNote."
L.FRIENDS_HOLD     = "L'envoi aux amis attend que ça remarche."
L.FRIENDS_RUNNING  = "En marche : {count} {count|ami|amis} avec DeathNote."
L.NOTE_FROM_GUILD  = "Repris du carnet de guilde (a tué des membres de la guilde {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Base de données non chargée."
L.IMPORT_NO_TEXT    = "Aucun texte."
L.IMPORT_NO_HEADER  = "La première ligne manque (elle commence par {header}). Copie tout le texte."
L.IMPORT_NOT_EXPORT = "Ce n'est pas un export DeathNote (ligne d'en-tête absente ou mauvaise version)."
L.IMPORT_TOO_LONG   = "Trop de lignes (au plus {count})."
L.IMPORT_BAD_KEY    = "Ligne {line} : clé invalide."
L.IMPORT_BAD_TIME   = "Ligne {line} : heure invalide."
L.IMPORT_BROKEN     = "La ligne {line} est incomplète ou abîmée (texte tronqué ?). Rien n'a été importé."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "oui"
L.WORD_NO  = "non"
L.PROBE_HEAD = "Sonde : {apis}/{apisAll} interfaces présentes, {events}/{eventsAll} événements enregistrables."
L.PROBE_MISSING = "Manquant : {list}"
L.PROBE_NOT_REGISTERABLE = "Non enregistrables : {list}"
L.PROBE_SOURCES = "Récap maintenant : {recap} · Compteur : {meter} · Journal de combat : {clog}"
L.PROBE_READABLE = "lisible"
L.PROBE_DEAD = "mort"
L.PROBE_PLATES = "Barres d'info ennemies : {plates} · Monde ouvert : {open}"
L.PROBE_PLATES_OFF = "DÉSACTIVÉES (seuls la cible et le survol repèrent les joueurs)"
L.PROBE_TARGET = "Cible : nom={name} GUID={guid} classe={class} hostile={enemy} me cible={me}"
L.PROBE_GUILD = "Guilde : préfixe {prefix} · envoi {send} · dernière valeur de retour {result} · envoyés {sent}, reçus {received}, rejetés {dropped}"
L.PROBE_REGISTERED = "enregistré"
L.PROBE_NOT_REGISTERED = "NON enregistré ({result})"
L.PROBE_POSSIBLE = "possible"
L.PROBE_ABSENT = "absent"
L.PROBE_WAITS = " · attend : {why}"
L.PROBE_LISTED = "Ajouts manuels (M) : envoyés {sent}, reçus {received}, rejetés {dropped} · rayés (X) : envoyés {usent}, reçus {ureceived}, rejetés {udropped}"
L.PROBE_GUILDBOOK = "Carnet de guilde : {text}"
L.PROBE_SAVED = "Enregistré dans DeathNoteDB.probe (dans le fichier après /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Rang"  -- [max 14]
L.SORT_RECENT = "Récents"  -- [max 14]
L.SORT_NAME = "Nom"  -- [max 14]
L.SORT_SEEN = "Repérage"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Qui te tue en monde ouvert atterrit ici. Tout seul."
L.EMPTY_OPEN_HEAD = "Rien à élucider."
L.EMPTY_JOURNAL_HEAD = "Zéro mort au compteur."
L.EMPTY_JOURNAL_SUB = "Respect. Ou mensonge."
L.EMPTY_NOGUILD_HEAD = "Pas de guilde."
L.EMPTY_NOGUILD_SUB = "On meurt très bien seul aussi."
L.EMPTY_GUILDOFF_HEAD = "Le carnet de guilde est fermé."
L.EMPTY_GUILDOFF_SUB = "Le partage est désactivé. Le Règlement intérieur sait où."
L.EMPTY_GUILDNIL_HEAD = "Aucune nouvelle de la guilde."
L.EMPTY_GUILDNIL_SUB = "Ton carnet part dès qu'un membre de la guilde a DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Rien dans le carnet de guilde pour l'instant."
L.EMPTY_GUILDQUIET_SUB = "Ta guilde a eu la paix jusqu'ici."
L.EMPTY_FRIENDSOFF_HEAD = "Le carnet des amis est fermé."
L.EMPTY_FRIENDSOFF_SUB = "Le partage avec les amis est désactivé. Le Règlement intérieur sait où."
L.EMPTY_FRIENDSNIL_HEAD = "Aucune nouvelle d'un ami avec DeathNote."
L.EMPTY_FRIENDSNIL_SUB = "Ton carnet part dès qu'un ami a DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Rien de tes amis pour l'instant."
L.EMPTY_FRIENDSQUIET_SUB = "Tes amis ont eu la paix jusqu'ici."
L.EMPTY_NOBODY_HEAD = "Ni guilde, ni amis."
L.EMPTY_NOBODY_SUB = "On meurt très bien seul aussi."
L.EMPTY_NOBODY_HINT = "Dès que des membres de ta guilde ou des amis de ta liste d'amis ont DeathNote, cette page montre ce qui leur arrive."
L.EMPTY_SHAREDNIL_HEAD = "Personne avec DeathNote ne s'est encore manifesté."
L.EMPTY_SHAREDNIL_SUB = "Ton carnet part dès que des membres de la guilde ou des amis ont DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Rien ici pour l'instant."
L.EMPTY_SHAREDQUIET_SUB = "La guilde et les amis ont eu la paix jusqu'ici."
L.EMPTY_HUNT_HEAD = "La liste de chasse est vide."
L.EMPTY_HUNT_SUB = "Sur l'affiche : Ouvrir la chasse."
L.EMPTY_HUNT_HINT = "Ou dans le chat : /dn hunt Prénom Nom. Toute ta guilde et tes amis le voient."
L.EMPTY_SEARCH_HEAD = "Aucun résultat."
L.EMPTY_SEARCH_SUB = "Entrée inscrit le nom dans le carnet."
L.EMPTY_SEARCHRO_HEAD = "Aucun résultat."
L.EMPTY_SEARCHRO_SUB = "Une autre orthographe aide parfois."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "LE CARNET"  -- [max 12]
L.MANUAL_BOOK = "Qui te tue en monde ouvert y est inscrit tout seul. Un clic sur le message après ta mort ouvre la page du tueur."
L.MANUAL_WANTED_HEAD = "RECHERCHÉS"  -- [max 12]
L.MANUAL_WANTED = "Tes tueurs, le pire en premier. Un clic montre l'affiche avec méfaits et note. Les graciés sont rayés, en fin de liste."
L.MANUAL_UNSOLVED_HEAD = "À ÉLUCIDER"  -- [max 13]
L.MANUAL_UNSOLVED = "Quand on ne sait pas qui a fait le coup, l'affaire attend ici. Un clic sur un nom désigne le tueur."
L.MANUAL_ALERT_HEAD = "ALERTE"  -- [max 12]
L.MANUAL_ALERT = "Quand un tueur apparaît en barre d'info, en cible ou sous la souris, le carnet donne l'alerte. Un clic le cible, en combat seulement après."
L.MANUAL_ADD_HEAD = "AJOUTER"  -- [max 12]
L.MANUAL_ADD = "Tape un nom dans le champ de recherche, Entrée. Clic droit sur une ligne : noter une vengeance, gracier, rayer."
L.MANUAL_GUILD_HEAD = "GUILDE"  -- [max 12]
L.MANUAL_GUILD = "Ta guilde et tes amis qui ont DeathNote voient tes morts avérées et tes ajouts manuels. Affiche ou /dn hunt Nom : ouvrir la chasse. Clic sur la prime : mettre la tienne, une promesse réglée entre vous."
L.MANUAL_SHARE_HEAD = "TRANSMETTRE"  -- [max 12]
L.MANUAL_SHARE = "Règlement intérieur, Sauvegarder : un texte à copier, pour tous ceux qui n'ont pas DeathNote."
L.MANUAL_QUIET_HEAD = "SILENCE"  -- [max 12]
L.MANUAL_QUIET = "Dans les donjons et les champs de bataille, l'alerte se tait. Sinon : clic milieu sur le bouton de la minicarte ou /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Vraiment rayer {name} du carnet ?\nTous les méfaits et la note seront perdus."
L.CONFIRM_DELETE_OK = "Rayer"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Vider le carnet de guilde sur cet ordinateur ?\nSa liste de chasse part avec, tes propres appels restent.\nTon propre carnet reste tel quel."
L.CONFIRM_GUILD_CLEAR_OK = "Vider"  -- [max 14]
L.CONFIRM_CANCEL = "Annuler"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} OR"  -- [max 14]
L.BOUNTY_SILVER = "{count} ARGENT"  -- [max 14]
L.THOUSANDS_SEP = " "
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Confirmer"  -- [max 19]
L.ACT_DISMISS = "Écarter"  -- [max 19]
L.ACT_HUNT_AGAIN = "Révoquer la grâce"  -- [max 19]
L.ACT_REVENGE = "Noter la vengeance"  -- [max 19]
L.ACT_PARDON = "Gracier"  -- [max 19]
L.ACT_STRIKE = "Rayer"  -- [max 19]
L.ACT_OPEN_OWN = "Voir dans le carnet"  -- [max 19]
L.ACT_ADOPT = "Dans mon carnet"  -- [max 19]
L.ACT_CALLOFF = "Arrêter la chasse"  -- [max 19]
L.ACT_RELEASE = "Ouvrir la chasse"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "repérage {time}"
L.ROW_NOT_SEEN = "aucun repérage"
L.ROW_PARDONED = "grâce accordée"
L.ROW_SUSPECT = "Soupçon"
L.MARK_REVENGE = "VENGEANCE {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Tueur incertain"
L.MARK_CANDIDATES = "{count} {count|PISTE|PISTES}"  -- [max 16]
L.MARK_SUSPECT = "SOUPÇON"  -- [max 16]
L.ROW_NO_PLAYER = "Aucun joueur"
L.ROW_UNCLEAR = "Cause incertaine"
L.MARK_NOT_COUNTED = "NE COMPTE PAS"  -- [max 16]
L.ROW_LISTED_BY = "ajouté par {names}"
L.ROW_GKILLED = "a tué {kills}×"
L.ROW_VICTIMS = "{count} {count|victime|victimes}"
L.ROW_LAST = "dernière : {text}"
L.MARK_IN_BOOK = "AU CARNET"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|tueur|tueurs}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|mort|morts}"  -- [max 12]
L.MEMBER_LISTED = "{count} à la main"  -- [max 14]
L.MEMBER_ME = "ce que les autres voient de toi"
L.MEMBER_NOTHING = "rien de partagé pour l'instant"
L.MEMBER_LAST_DIED = "dernière mort {time}"
L.MARK_YOU = "toi"  -- [max 16]
L.MARK_FRIEND = "AMI"  -- [max 16]
L.MARK_BOTH = "GUILDE, AMI"  -- [max 20]
L.MARK_TAKEN_DOWN = "ABATTU {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "MORT OU VIF"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "MÉFAITS"  -- [max 14]
L.POSTER_NOTE = "NOTE"  -- [max 8]
L.POSTER_BOUNTY = "PRIME"  -- [max 12]
L.ROLE_ASSIST = "complice"  -- [max 14]
L.ROLE_SUSPECT = "soupçon"  -- [max 14]
L.POSTER_LEVEL = "Niveau {level}"
L.POSTER_GUILD = "Guilde : {guild}"
L.POSTER_LAST_SEEN = "Dernier repérage {time}"
L.POSTER_NOT_SEEN = "Aucun repérage"
L.POSTER_ONLY_SUSPECT = "Simple soupçon, aucun méfait avéré."
L.POSTER_NO_DEEDS = "Aucun méfait noté."
L.TIP_LISTED_AT = "Ajouté le {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Cause de la mort : {spell}"
L.TIP_VICTIM = "Victime : {name}"
L.TIP_VICTIM_LEVEL = "Victime : {name} (niveau {level})"
L.TIP_KILLER_LEVEL = "Niveau du tueur : {level}"
L.TIP_ASSISTS = "Complices : {names}"
L.TIP_ROLE_ASSIST = "Complice, n'a pas porté le coup fatal."
L.TIP_ROLE_SUSPECT = "Simple soupçon, rien d'avéré."
L.MORE_LINE = "… et {count} {count|autre|autres}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "CARNET DE GUILDE"  -- [max 24]
L.POSTER_IN_BOOK_OF = "Dans le carnet de : {names}"
L.POSTER_SEEN = "Repérage {time}"
L.POSTER_SEEN_BY = "Repérage {time}, par {name}"
L.TIP_IN_BOOK_OF = "Dans le carnet de"
L.POSTER_REMARK = "REMARQUE"  -- [max 12]
L.POSTER_BY_HAND = "AJOUT MANUEL"  -- [max 22]
L.POSTER_VICTIMS = "VICTIMES"  -- [max 12]
L.POSTER_LISTED = "AJOUTÉ PAR"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Ajouté à la main."
L.POSTER_NO_DEEDS_SENT = "Aucun méfait transmis."
L.POSTER_NONE_KNOWN = "aucune connue"
L.POSTER_NO_NAMES = "aucun nom transmis"
L.TIP_VICTIMS = "Victimes"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Appel du {time}"
L.HUNT_REASON = "Motif : {reason}"
L.POSTER_HUNTLIST = "LISTE DE CHASSE"  -- [max 24]
L.POSTER_RELEASED_N = "chasse ouverte {times}"
L.POSTER_RELEASED_BY = "Appel lancé par {names}"
L.POSTER_TAKEN_DOWN = "MISES À MORT"  -- [max 12]
L.POSTER_NOT_YET = "PAS ENCORE"  -- [max 18]
L.POSTER_CALLS = "APPELS"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Plus personne."
L.POSTER_LAST = "DERNIER"  -- [max 13]
L.POSTER_TAKEN_BY = "victime de {name}, {time}"
L.POSTER_TAKEN_NOBODY = "toujours en liberté"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Décès"  -- [max 20]
L.CASE_ASSISTS = "COMPLICES"  -- [max 24]
L.CASE_PICK = "DÉSIGNER LE TUEUR"  -- [max 24]
L.CASE_NOT_COUNTED = "Ne compte pas (instance, champ de bataille ou duel)"
L.CASE_KILLER = "TUEUR"  -- [max 24]
L.CASE_KILLER_SUSPECT = "TUEUR (SOUPÇON)"  -- [max 24]
L.CASE_CLICK_NAME = "Clique sur le nom pour ouvrir son affiche."
L.CASE_GONE = "Ne figure plus dans le carnet."
L.CASE_KILLER_UNCLEAR = "TUEUR INCERTAIN"  -- [max 24]
L.CASE_SEVERAL = "Plusieurs auraient pu faire le coup. Quel nom va au carnet ?"
L.CASE_NOBODY = "Personne n'a pu faire le coup."
L.CASE_HOW = "CE QUI S'EST PASSÉ"  -- [max 24]
L.CASE_PVE = "Un monstre ou le monde lui-même. Pas une affaire pour le carnet."
L.CASE_UNCLEAR = "Incertain"
L.CASE_DARK = "La police scientifique nage en plein brouillard."
L.TIP_MORE_CANDIDATES = "Autres pistes"
L.CASE_SOURCE_SUSPECT = "Soupçon : t'avait en cible peu avant ta mort."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Ligne d'infobulle sur les tueurs"  -- [max 44]
L.OPT_MINIMAP = "Afficher le bouton de la minicarte"  -- [max 44]
L.OPT_ALERT = "Alerte quand un tueur apparaît"  -- [max 44]
L.OPT_FLASH = "Faire clignoter le bord de l'écran en rouge"  -- [max 44]
L.OPT_SUSPECTS = "Signaler aussi les suspects"  -- [max 44]
L.OPT_DEATHMSG = "Message après une mort en JcJ"  -- [max 44]
L.OPT_G_SHARE = "Partager mes morts"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Partager les ajouts manuels"  -- [max 44]
L.OPT_G_RECEIVE = "Recevoir le carnet de guilde"  -- [max 44]
L.OPT_G_ALERT = "Alerter pour les tueurs du carnet de guilde"  -- [max 44]
L.OPT_G_ALERTLISTED = "Alerter aussi pour les ajouts manuels"  -- [max 44]
L.OPT_G_ANNOUNCE = "Signaler la mort d'un membre de la guilde"  -- [max 44]
L.OPT_G_SIGHTINGS = "Partager les repérages"  -- [max 44]
L.OPT_F_SHARE = "Partager avec la guilde"  -- [max 44]
L.OPT_F_FRIENDS = "Partager avec les amis"  -- [max 44]
L.OPT_F_ALERT = "Alerter pour les tueurs de guilde et amis"  -- [max 44]
L.OPT_F_ALERTHUNT = "Alerter pour les cibles à abattre"  -- [max 44]
L.OPT_F_ANNOUNCE = "Signaler la mort de membres ou d'amis"  -- [max 44]
L.OPT_F_SIGHTINGS = "Partager les repérages avec guilde et amis"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guilde"  -- [max 14]
L.SET_BOOK_SIZE = "Taille du carnet"  -- [max 34]
L.SET_LANGUAGE = "Langue"  -- [max 16]
L.SET_LANG_AUTO = "Automatique"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Active après rechargement."  -- [max 28]
L.SET_LANG_RELOAD = "Recharger maintenant"  -- [max 22]
L.SET_SEC_SHARE = "TRANSMETTRE"  -- [max 24]
L.IO_EXPORT = "Sauvegarder"  -- [max 17]
L.IO_IMPORT = "Importer"  -- [max 17]
L.SET_HINT_BOOK = "Sauvegarder te donne le carnet sous forme de texte : à garder, ou à transmettre à des gens hors de la guilde. Importer fusionne et n'écrase rien."
L.SET_SEC_SOUND = "SON"  -- [max 24]
L.SET_SOUND = "Son"  -- [max 22]
L.SET_VOLUME = "Volume"  -- [max 22]
L.SET_CHANNEL = "Canal"  -- [max 12]
L.SET_SEC_THRESHOLD = "SEUIL"  -- [max 24]
L.SET_COOLDOWN = "Temps de recharge par tueur"  -- [max 34]
L.SET_MINKILLS = "Alerte dès tant de morts par tueur"  -- [max 34]
L.SET_ALERT_SIZE = "Taille de l'alerte"  -- [max 34]
L.SET_TEST_ALERT = "Alerte de test"  -- [max 17]
L.SET_G_MINKILLS = "Alerte de guilde dès tant de morts"  -- [max 34]
L.SET_F_MINKILLS = "Alerte dès tant de morts"  -- [max 34]
L.SET_SEC_STATUS = "ÉTAT"  -- [max 24]
L.SET_SEC_SHARING = "PARTAGE"
L.SET_SEC_WARN = "ALERTE"
L.SET_MORE = "Plus"
L.SET_GUILD_CLEAR = "Vider carnet de guilde"  -- [max 26]
L.SET_HINT_GUILD = "Seule ta guilde reçoit quelque chose. Ce qui en vient reste à part de ton carnet jusqu'à ce que tu le reprennes toi-même."
L.SET_HINT_FRIENDS = "Seuls la guilde et les amis qui ont DeathNote reçoivent quelque chose."
L.BTN_BACK = "Retour"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Synchroniser"  -- [max 14]
L.SYNC_AGAIN_IN = "encore {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Amis"
L.TIP_GUILD_NAME = "Guilde {guild}"
L.TIP_MATES_WITH = "Membres de la guilde avec DeathNote :"
L.TIP_NO_MATE = "Aucune nouvelle d'un membre de la guilde avec DeathNote."
L.TIP_FRIENDS_WITH = "Amis avec DeathNote :"
L.TIP_SHARED = "Partagé : tes morts avérées, tes ajouts manuels et tes appels à la chasse."
L.TIP_NOT_SHARED = "Non partagé : notes, soupçons, joueurs graciés, entrées importées."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Importer"  -- [max 17]
L.IO_DONE = "Importé : {new} nouveaux, {merged} fusionnés."
L.IO_FAILED = "Ça n'a pas marché."
L.IO_SMALL = "Version courte"  -- [max 17]
L.IO_ALL = "Tout afficher"  -- [max 17]
L.IO_MSG_FULL = "Carnet complet avec méfaits ({size})."
L.IO_MSG_SHORT = "Seulement noms et compteurs ({size}). Avec méfaits : {full}."
L.IO_MSG_BIG = "Gros carnet ({size}) : sélectionner et copier prend un moment."
L.IO_HELP_EXPORT = "Le texte est sélectionné : Ctrl+C le copie. Garde-le ou transmets-le à des amis."
L.IO_HELP_IMPORT = "Colle un texte sauvegardé avec Ctrl+V, puis Importer. Rien n'est écrasé."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Toute ta guilde et tes amis qui ont DeathNote voient le motif."
L.REL_HINT_GUILD = "Toute ta guilde qui a DeathNote voit le motif."
L.REL_HINT_FRIENDS = "Tes amis qui ont DeathNote voient le motif."
L.REL_HEAD = "Ouvrir la chasse"  -- [max 24]
L.REL_FOR = "POUR"  -- [max 6]
L.REL_REASON = "MOTIF"  -- [max 8]
L.REL_HINT2 = "Ta note reste chez toi. Personne d'autre que toi ne peut retirer ton appel."
L.REL_GO = "Lancer l'appel"  -- [max 17]
L.REL_NONE = "Pas de guilde, et le partage avec les amis est désactivé."
L.REL_CAP = "Au plus {own} appels de ta part et {max} cibles par liste."
L.REL_FAILED = "Impossible d'ouvrir la chasse pour l'instant."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Aucun son : l'alerte se contente de s'afficher."
L.SET_HINT_BUILTIN = "Le volume de ce son suit le canal dans les options du jeu."
L.SET_HINT_LEVELS = "Cinq niveaux, du plus doux au plus fort. Le curseur du canal dans les options du jeu s'applique en plus."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guilde & amis"  -- [max 18]
L.TIP_HELP_BUTTON = "Comment marche le carnet"
L.VIEW_HUNT = "À abattre"  -- [max 13]
L.VIEW_BY_KILLER = "Par tueur"  -- [max 13]
L.VIEW_BY_MATE = "Par membre"  -- [max 13]
L.SRC_ALL = "Tous"  -- [max 12]
L.SRC_GUILD = "Guilde"  -- [max 12]
L.SRC_FRIENDS = "Amis"  -- [max 12]
L.SORT_HIDE_PARDONED = "Masquer les graciés"  -- [max 24]
L.SORT_SHOW_PARDONED = "Afficher les graciés"  -- [max 24]
L.SEARCH_ADD = "Chercher ou ajouter …"  -- [max 26]
L.SEARCH_SHORT = "Chercher …"  -- [max 10]
L.SEARCH_KILLER = "Trouver tueur …"  -- [max 15]
L.SEARCH_JOURNAL = "Tueur ou lieu …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Tout replier"
L.TIP_EXPAND_ALL = "Tout déplier"
L.STATUS_NO_PLATES = "Barres d'info ennemies désactivées : l'alerte ne voit que la cible et la souris."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|recherché|recherchés}"
L.MM_UNSOLVED = "{count} non {count|élucidé|élucidés}"
L.MM_ALERT_OFF = "Alerte désactivée (clic milieu)"
L.MM_CLICK = "Clic : carnet · Clic droit : Règlement intérieur"
L.MM_MIDDLE = "Clic milieu : alerte activée/désactivée"
L.MM_DRAG = "Glisser : déplacer le long de la minicarte"
L.MM_CHAT_ALERT_ON = "Alerte activée."
L.MM_CHAT_ALERT_OFF = "Alerte désactivée."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "ENNEMI DE GUILDE N°1"  -- [max 25]
L.STAMP_HUNT = "CHASSE OUVERTE"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} s'est fait passer pour ton ami {friend} : rejeté."
L.FRIENDS_SHORT_IMPOSTOR = "Inconnu rejeté"  -- [max 22]
L.ALERT_LEVEL = "Niveau {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "dernier niveau {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Niveau ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · sur la liste de chasse ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|nouvelle cible|nouvelles cibles}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nouvelles entrées sur la liste de chasse"
L.OPT_F_ANNOUNCEHUNT = "Signaler ajouts et abattus (liste de chasse)"  -- [max 44]
L.SET_HUNT_EXPIRE = "Les appels expirent après"  -- [max 30]
L.SET_EXPIRE_NEVER = "Jamais"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|jour|jours}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Vider carnet des amis"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Vider le carnet des amis sur cet ordinateur ?\nSa liste de chasse part avec, tes propres appels restent."
L.CONFIRM_CALLOFF_ALL = "Retirer tous tes appels de la liste de chasse ?\nLa guilde et les amis l'apprendront peu à peu."
L.CONFIRM_CALLOFF_ALL_OK = "Tout retirer"  -- [max 14]
L.ACT_CALLOFF_ALL = "Retirer tous mes appels"  -- [max 24]
L.ACT_HUNT_HIDE = "Masquer pour moi"  -- [max 19]
L.ACT_HUNT_SHOW = "Réafficher"  -- [max 19]
L.HUNT_ROW_HIDDEN = "invisible pour toi"
L.HUNT_ROW_CALLS = "{count} {count|appel|appels} : {names}"
L.POSTER_ON_HUNTLIST = "Sur la liste de chasse ({names})"
L.REL_SELF = "Impossible de t'inscrire toi-même sur la liste de chasse."
L.REL_MATE = "C'est quelqu'un de chez toi (guilde ou amis avec DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Qui est ton ami {friend} : {a} ou {b} ? À toi de choisir."
L.FRIENDS_SHORT_CONFLICT = "Ami incertain"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Deux joueurs se présentent comme ton ami {friend} : {a} et {b}. Tant que tu n'as pas choisi, le carnet n'accepte rien ni de l'un ni de l'autre. Guilde & amis, vue Par membre : clic droit sur le nom."
L.MEMBER_CONFLICT = "Clic droit : est-ce ton ami ?"  -- [max 40]
L.ACT_TIE_MINE = "Mon ami : {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Délier le nom"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Délier {name} de ta liste d'amis ?\nCe que ce nom a apporté au carnet des amis est effacé ; le prochain message sous ce prénom crée un nouveau lien."
L.CHAT_FRIENDS_TIES = "Noms complets liés (* = premier contact, pas encore prouvé) : {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Prénom [Nom]> <or>  mettre ta propre prime (sans montant : la retirer)"
L.CHAT_WHO_BOUNTY = "Sur qui ? /dn bounty <Nom> <or>"
L.CHAT_BOUNTY_SET = "{name} : tu offres une prime de {gold} po. Ta guilde et tes amis avec DeathNote la voient."
L.CHAT_BOUNTY_OFF = "{name} : ta prime est retirée."
L.CHAT_BOUNTY_NONE = "Tu n'as mis aucune prime sur {name}."
L.CHAT_BOUNTY_BAD = "Prime : un nombre entier de pièces d'or, de 1 à 99999 (0 la retire)."
L.CHAT_BOUNTY_CAP = "Pas de prime : au plus {count} de ta part."
L.CHAT_BOUNTY_OURS = "Pas de prime sur toi ni sur les tiens (guilde ou amis avec DeathNote)."
L.ACT_BOUNTY = "Mettre une prime"  -- [max 24]
L.ACT_UNDO = "Annuler"  -- [max 19]
L.ACT_REVENGE_TAKE = "Retirer une vengeance"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, offerte par toi"
L.POSTER_BOUNTY_BY = "{gold}, offerte par {name}"
L.POSTER_BOUNTY_MANY = "Prime {gold} : {names}"
L.POSTER_AVENGED = "Vengé par {names}"
L.ROW_AVENGED = "vengé {times}"
L.BOUNTY_TIP_HEAD = "Ta propre prime, en or"
L.BOUNTY_TIP_RULES = "Un nombre entier, de 1 à 99999. Vide ou 0 : retour à la valeur du carnet. Entrée valide, Échap annule."
L.BOUNTY_TIP_PROMISE = "Ta guilde et tes amis avec DeathNote la voient. Simple promesse : ça se règle entre vous."
L.BOUNTY_TIP_CLICK = "Clic : mettre ta propre prime"
L.CHAT_AVENGED = "{name} a abattu {killer} pour toi."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name} : tu offres une prime de {gold} po."
L.CHAT_BOUNTY_UNKNOWN = "{name} n'est dans aucun de tes carnets. Une prime ne se met que sur un nom d'un carnet, tel que le jeu l'affiche : prénom et nom."
L.CHAT_BOUNTY_LIST = "Tes primes ({count} sur {max}) : {list}"
L.CHAT_BOUNTY_LIST_NONE = "Tu n'as mis aucune prime."
-- <<< BOOK
end)
