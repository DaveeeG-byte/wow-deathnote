-- DeathNote: Español (esES, also used for esMX). Translated from enUS.lua (meaning from deDE.lua); neutral Spanish,
-- game terms as in the Spanish clients (hermandad, banda, mazmorra), words that work in Spain and Latin America.
-- Plural: 2 forms {count|one|other} (1 | everything else). Rule in Locale.lua (PLURAL_OF.esES), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
--
-- TOC-Notes: Lista negra para el JcJ en el mundo abierto: recuerda quién te mató y te avisa cuando anda cerca.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("esES")) then return end

Locale.Register("esES", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Se busca"        -- [max 16]
L.TAB_UNSOLVED = "Sin resolver"    -- [max 16]
L.TAB_DEATHLOG = "Obituario"       -- [max 16]
L.TAB_GUILD    = "Hermandad"       -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Normas de la casa"   -- [max 24]
L.HEAD_HELP  = "Modo de empleo"      -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Libro"          -- [max 14]
L.SHEET_ALERT = "Alarma"         -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "ENEMIGO PÚBLICO Nº 1"  -- [max 24]
L.STAMP_REVENGE  = "CUENTA SALDADA"        -- [max 16]
L.STAMP_PARDONED = "INDULTO"               -- [max 16]
L.STAMP_SUSPECT  = "SOSPECHA"              -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "ENEMIGO Nº 1 AVISTADO"       -- [max 30]
L.ALERT_SIGHTED         = "ENEMIGO PÚBLICO AVISTADO"    -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "SOSPECHOSO AVISTADO"         -- [max 30]
L.ALERT_TITLE_GUILD     = "ENEMIGO DE HERMANDAD AVISTADO" -- [max 30]
L.ALERT_TITLE_FRIENDS   = "ASESINO DE AMIGOS AVISTADO"  -- [max 30]
L.ALERT_TITLE_HUNT      = "OBJETIVO DE LA LISTA NEGRA"    -- [max 30]
L.ALERT_LINE_SUSPECT        = "está bajo sospecha"
L.ALERT_LINE_KILLED         = "te mató {times}"
L.ALERT_LINE_KILLED_ASSISTED = "te mató {times}, cómplice {assists}"
L.ALERT_LINE_ASSISTED       = "ayudó a matarte {times}"
L.ALERT_LINE_MANUAL         = "está en el libro (a mano)"
L.ALERT_LINE_LAST    = "{text}, última vez {time}"
L.ALERT_LINE_IN      = "{text} en {zone}"
L.ALERT_LINE_REVENGE = "{text}. Venganza: {times}"
L.ALERT_HINT_CLOSE  = "Clic derecho: cerrar"                        -- [max 44]
L.ALERT_HINT_COMBAT = "Fijar objetivo solo tras el combate"         -- [max 44]
L.ALERT_HINT_TARGET = "Clic: fijar objetivo · Clic derecho: cerrar" -- [max 44]
L.ALERT_MORE = "+{count} más"            -- [max 14]
L.SAMPLE_ZONE = "Vega de Tuercespina"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "está en el libro de la hermandad"
L.GUILD_LINE_IN_FRIENDS = "está en el libro de los amigos"
L.GUILD_LINE_LISTED_BY  = "está en el libro de {names}"
L.GUILD_LINE_KILLED_GUILD   = "mató a compañeros de hermandad {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "mató a amigos {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "mató a compañeros de hermandad y amigos {kills}×"
L.GUILD_LINE_LAST = "{text}, última víctima: {name}"
L.HUNT_LINE_BY       = "caza abierta por {names}"
L.HUNT_LINE_RELEASED = "en la lista negra"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "bajo sospecha"
L.TALLY_MANUAL   = "añadido a mano"
L.TALLY_NONE     = "sin fechorías aún"
L.TALLY_KILLED   = "te mató {times}"
L.TALLY_ASSISTED = "cómplice {times}"
L.PLACE_UNKNOWN  = "lugar desconocido"
L.GKILLS_CAP     = "al menos {count}"
L.NAMELIST_MORE  = "{names} y {count} más"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d/%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d/%m/%Y %H:%M"
L.TIME_FMT_DAY       = "%d/%m"
L.TIME_FMT_DAY_YEAR  = "%d/%m/%y"
L.TIME_NEVER   = "nunca"
L.TIME_JUST    = "ahora mismo"
L.TIME_MINUTES = "hace {count} min"       -- [max 14]
L.TIME_HOURS   = "hace {count} h"         -- [max 14]
L.TIME_DAYS    = "hace {count} {count|día|días}"  -- [max 16]
L.MONEY_GOLD   = "{count} o"
L.MONEY_SILVER = "{count} p"
L.MONEY_COPPER = "{count} c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Hay noticias de {count} {count|compañero|compañeros} de hermandad con DeathNote."
L.HEALTH_NOGUILD = "No estás en ninguna hermandad, no se comparte nada."
L.HEALTH_OFF     = "Compartir está desactivado."
L.HEALTH_SHORT_NOGUILD = "Sin hermandad"      -- [max 18]
L.HEALTH_SHORT_OFF     = "No se comparte"     -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Bloqueado"          -- [max 18]
L.HEALTH_SHORT_FAILING = "Rechazado"          -- [max 18]
L.HEALTH_SHORT_HOLD    = "En espera"          -- [max 18]
L.HEALTH_SHORT_ASKED   = "Solicitado"         -- [max 18]
L.HEALTH_SHORT_FAIL    = "No funciona"        -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Sin sonido"        -- [max 16]
L.SOUND_RAIDWARNING = "Aviso de banda"    -- [max 16]
L.SOUND_BELL        = "Campana"           -- [max 16]
L.SOUND_GONG        = "Gong"              -- [max 16]
L.SOUND_HEARTBEAT   = "Latido"            -- [max 16]
L.SOUND_FEATHER     = "Pluma"             -- [max 16]
L.SOUND_SIREN       = "Sirena"            -- [max 16]
L.CHANNEL_MASTER    = "General"           -- [max 16]
L.CHANNEL_SFX       = "Efectos"           -- [max 16]
L.CHANNEL_DIALOG    = "Diálogo"           -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} ya está en el libro."
L.CHAT_REMOVED   = "{name} ya no está en el libro."
L.CHAT_SYNC_WAIT = "Se acaba de sincronizar. Vuelve a intentarlo en {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Aún no hay nombres."
L.EMPTY_WANTED_SUB  = "Sal un poco, para variar."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  abrir/cerrar el libro"
L.HELP_ADD      = "/dn add <Nombre [Apellido]>  apuntar a mano a un asesino en el libro"
L.HELP_DEL      = "/dn del <Nombre [Apellido]>  tachar a un asesino del libro"
L.HELP_QUIET    = "/dn quiet  alarma desactivada/activada"
L.HELP_TEST     = "/dn test  mostrar una alarma de prueba"
L.HELP_GUILD    = "/dn guild  libro de la hermandad: estado y qué compañeros tienen DeathNote"
L.HELP_FRIENDS  = "/dn friends  libro de los amigos: estado y qué amigos tienen DeathNote"
L.HELP_SYNC     = "/dn sync  sincronizar ya el libro de la hermandad y el de los amigos"
L.HELP_HUNT     = "/dn hunt <Nombre [Apellido]>  abrir la caza (sin nombre: mostrar la lista negra)"
L.HELP_CALLOFF  = "/dn calloff <Nombre [Apellido]>  suspender tu propia caza"
L.HELP_LANG     = "/dn lang <código>  idioma del libro (enUS, deDE, frFR ...), tras /reload"
L.HELP_THEME = "/dn theme <nombre>  tapa del libro, tras /reload"
L.HELP_PROBE    = "/dn probe  diagnóstico: lo que el juego le cuenta al libro"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  diagnóstico, probando también el registro de combate"
L.HELP_DEBUG    = "/dn debug  diagnóstico: anotar cada muerte en detalle (activado/desactivado)"
L.HELP_HELP     = "/dn help  esta ayuda"
L.HELP_SILENT_ZONES = "En mazmorras, campos de batalla y arenas el libro se calla solo."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "activado"
L.WORD_OFF = "desactivado"
L.CHAT_WHO_ADD  = "¿A quién? /dn add <Nombre>"
L.CHAT_WHO_DEL  = "¿A quién? /dn del <Nombre>"
L.CHAT_WHO_CALLOFF = "¿A quién? /dn calloff <Nombre>"
L.CHAT_BAD_NAME = "Nombre no válido."
L.CHAT_NOT_IN_BOOK = "No está en el libro: {name}"
L.CHAT_ALARM_ON  = "Alarma activada."
L.CHAT_ALARM_OFF = "Alarma desactivada."
L.CHAT_DEBUG = "Registro de diagnóstico {state}."
L.CHAT_UNKNOWN_CMD = "Comando desconocido. Ayuda: /dn help"
L.CHAT_GUILD_NOT_LOADED = "El libro de la hermandad no está cargado."
L.CHAT_NO_GUILD = "No estás en ninguna hermandad (o el juego aún no lo sabe)."
L.CHAT_GUILD_STATE = "Hermandad {guild}: compartir {share}, recibir {receive}."
L.CHAT_GUILD_BOOK = "Libro de la hermandad: {enemies} asesinos ({listed} solo añadidos a mano), {deeds} {deeds|fechoría|fechorías}, {foreign} asesinos de compañeros de hermandad. Compartir entradas a mano: {manual}."
L.CHAT_STATE_OK   = "Estado: {text}"
L.CHAT_STATE_WARN = "Atención: {text}"
L.CHAT_NO_MATES   = "Aún no hay noticias de ningún compañero de hermandad con DeathNote."
L.CHAT_HAVE_DN      = "Tienen DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Tienen DeathNote: {names} y {count} más"
L.CHAT_SYNC_ASKED = "Sincronización solicitada. Las respuestas llegan en los próximos segundos."
L.CHAT_SYNC_FAIL  = "La sincronización no funciona: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "no hay hermandad o compartir está desactivado."
L.CHAT_FRIENDS_NOT_LOADED = "El libro de los amigos no está cargado."
L.CHAT_FRIENDS_STATE = "Amigos: compartir {share}, {online} de {total} conectados."
L.CHAT_FRIENDS_BOOK  = "Libro de los amigos: {enemies} asesinos ({listed} solo añadidos a mano), {deeds} {deeds|fechoría|fechorías}."
L.CHAT_NO_FRIENDS    = "Aún no hay noticias de ningún amigo con DeathNote."
L.CHAT_HUNT_NOT_LOADED = "La lista negra no está cargada."
L.CHAT_HUNT_UNKNOWN = "Nombre desconocido: {name}. Pon también el apellido, tal como aparece en el juego."
L.CHAT_HUNT_CAP     = "No se puede abrir la caza: como mucho {own} órdenes tuyas y {targets} objetivos por lista."
L.CHAT_HUNT_NOWHERE = "Ahora no se puede abrir la caza: no hay hermandad y compartir con amigos está desactivado."
L.CHAT_HUNT_BOTH    = "Caza abierta contra {name}, para la hermandad y los amigos."
L.CHAT_HUNT_GUILD   = "Caza abierta contra {name}, para la hermandad."
L.CHAT_HUNT_FRIENDS = "Caza abierta contra {name}, para tus amigos."
L.CHAT_CALLED_OFF   = "Caza contra {name} suspendida."
L.CHAT_NO_OWN_CALL  = "No tienes ninguna orden propia contra {name}."
L.CHAT_LANG_CURRENT = "Idioma actual: {lang}. Cambiar: /dn lang <código>"
L.CHAT_LANG_LIST    = "Códigos: {codes}"
L.CHAT_LANG_BAD     = "Idioma desconocido: {code}"
L.CHAT_LANG_SET     = "Idioma: {lang}."
L.CHAT_LANG_RELOAD  = "Idioma: {lang}. Se aplica tras /reload."
L.CHAT_THEME_CURRENT = "Tapa actual: {theme}. Cambiar: /dn theme <nombre>"
L.CHAT_THEME_LIST = "Tapas: {themes}"
L.CHAT_THEME_BAD = "Tapa desconocida: {name}"
L.CHAT_THEME_SET = "Tapa: {theme}."
L.CHAT_THEME_RELOAD = "Tapa: {theme}. Se aplica tras /reload."
L.THEME_NOTEBOOK = "El libro negro"
L.THEME_HARBOR = "El libro del corsario"
L.THEME_TRADE = "El taller"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "El libro está listo. Quien te mate en el mundo abierto quedará apuntado en él. Ábrelo con /dn o con el botón del minimapa."
L.WELCOME_PLATES = "Las placas de nombre enemigas están desactivadas. Sin ellas, la alarma solo ve tu objetivo."
L.WELCOME_SHARE = "La hermandad y los amigos que tengan DeathNote también lo leen. Las notas y sospechas se quedan contigo."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "EN EL LIBRO:"
L.TIP_HUNT      = "LISTA NEGRA:"
L.TIP_GUILDBOOK = "LIBRO DE HERMANDAD:"
L.TIP_PARDONED  = "indulto concedido"
L.TIP_RANK      = "puesto {rank}"
L.TIP_REVENGE   = "venganza {times}"
L.TIP_LISTED_BY = "en el libro de {names}"
L.TIP_NOTE      = "Nota: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Clic: abrir · Clic derecho: quitar"
L.BANNER_NEW          = "NUEVA ENTRADA"        -- [max 24]
L.BANNER_NEW_LINE     = "ya está en el libro"
L.BANNER_AGAIN        = "OTRA VEZ"             -- [max 24]
L.BANNER_AGAIN_LINE   = "te mató otra vez, ya van {count}"
L.BANNER_SUSPECT      = "SOSPECHA"             -- [max 24]
L.BANNER_SUSPECT_LINE = "está bajo sospecha, aclarar en el libro"
L.BANNER_UNCLEAR      = "ASESINO INCIERTO"       -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|candidato|candidatos}"
L.BANNER_UNCLEAR_LINE = "Clic: elegir al asesino en Sin resolver"
L.BANNER_REVENGE      = "DESQUITE"             -- [max 24]
L.BANNER_REVENGE_LINE = "Venganza cumplida ({count}×)"
L.BANNER_GUILD        = "HERMANDAD"            -- [max 24]
L.BANNER_FRIENDS      = "AMIGOS"               -- [max 24]
L.BANNER_KILLED_BY    = "murió a manos de {name}"
L.BANNER_HUNT         = "LISTA NEGRA"          -- [max 24]
L.BANNER_BAGGED       = "cayó ante {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "Compartir está desactivado (Normas de la casa, hoja Hermandad)."
L.SYNC_FRIENDS_OFF = "Compartir con amigos está desactivado."
L.SYNC_NOBODY      = "Ni hermandad ni amigos con quien compartir."
L.SYNC_SHORT_NOBODY = "Nada compartido"           -- [max 18]
L.SYNC_PREFIX      = "El juego no permite recibir. Volver a conectarte ayuda."
L.SYNC_SHORT_PREFIX = "No se recibe"              -- [max 18]
L.SYNC_BLOCKED     = "El reino bloquea el envío. Pásalo con Guardar copia."
L.SYNC_SHORT_BLOCKED = "El reino bloquea envío"   -- [max 22]
L.SYNC_FAILING     = "El envío falla ahora mismo, se vuelve a intentar."
L.SYNC_SHORT_FAILING = "Envío atascado"           -- [max 18]
L.SYNC_HOLD        = "El envío espera {wait}."
L.SYNC_HOLD_INSTANCE = "a que salgas de la instancia"
L.SYNC_HOLD_COMBAT   = "a que salgas de combate"
L.SYNC_HOLD_LOCKDOWN = "a que el chat vuelva a estar libre"
L.SYNC_HOLD_AGAIN    = "a que vuelva a funcionar"
L.SYNC_HOLD_SHORT_INSTANCE = "Espera: instancia" -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Espera: combate"   -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Espera: chat"      -- [max 18]
L.SYNC_QUIET       = "Enviado, pero aún no hay noticias de compañeros con DeathNote."
L.SYNC_READY       = "Listo. Aún no hay noticias de compañeros con DeathNote."
L.SYNC_RUNNING     = "En marcha: {count} {count|compañero|compañeros} de hermandad con DeathNote."
L.SYNC_RUNNING_ALL = "En marcha: {count} con DeathNote entre hermandad y amigos."
L.FRIENDS_OFF      = "Compartir con amigos está desactivado (Normas de la casa, hoja Hermandad)."
L.FRIENDS_BLOCKED  = "El reino bloquea los susurros. Los amigos no reciben nada."
L.FRIENDS_SHORT_BLOCKED = "Susurros bloqueados"   -- [max 22]
L.FRIENDS_FAILING  = "Los susurros fallan ahora mismo, se vuelve a intentar."
L.FRIENDS_SHORT_FAILING = "Susurros atascados" -- [max 18]
L.FRIENDS_NONE_LISTED = "No hay nadie en la lista de amigos."
L.FRIENDS_NONE_ONLINE = "Ahora mismo no hay amigos conectados."
L.FRIENDS_SHORT_NONE_ONLINE = "Nadie conectado"   -- [max 18]
L.FRIENDS_QUIET    = "Solicitado, pero aún no hay noticias de amigos con DeathNote."
L.FRIENDS_READY    = "Listo. Aún no hay noticias de amigos con DeathNote."
L.FRIENDS_HOLD     = "El envío a los amigos espera a que vuelva a funcionar."
L.FRIENDS_RUNNING  = "En marcha: {count} {count|amigo|amigos} con DeathNote."
L.NOTE_FROM_GUILD  = "Copiado del libro de la hermandad (mató a compañeros {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Base de datos no cargada."
L.IMPORT_NO_TEXT    = "No hay texto."
L.IMPORT_NO_HEADER  = "Falta la primera línea (empieza por {header}). Copia el texto entero."
L.IMPORT_NOT_EXPORT = "No es una exportación de DeathNote (falta la cabecera o versión incorrecta)."
L.IMPORT_TOO_LONG   = "Demasiadas líneas (como mucho {count})."
L.IMPORT_BAD_KEY    = "Línea {line}: clave no válida."
L.IMPORT_BAD_TIME   = "Línea {line}: hora no válida."
L.IMPORT_BROKEN     = "La línea {line} está incompleta o dañada (¿texto cortado?). No se ha importado nada."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "sí"
L.WORD_NO  = "no"
L.PROBE_HEAD = "Sonda: {apis}/{apisAll} interfaces presentes, {events}/{eventsAll} eventos registrables."
L.PROBE_MISSING = "Faltan: {list}"
L.PROBE_NOT_REGISTERABLE = "No registrables: {list}"
L.PROBE_SOURCES = "Recap ahora: {recap} · Medidor: {meter} · Registro de combate: {clog}"
L.PROBE_READABLE = "legible"
L.PROBE_DEAD = "muerto"
L.PROBE_PLATES = "Placas de nombre enemigas: {plates} · Mundo abierto: {open}"
L.PROBE_PLATES_OFF = "DESACTIVADAS (solo el objetivo y el cursor detectan jugadores)"
L.PROBE_TARGET = "Objetivo: nombre={name} GUID={guid} clase={class} hostil={enemy} me apunta={me}"
L.PROBE_GUILD = "Hermandad: prefijo {prefix} · envío {send} · último valor devuelto {result} · enviados {sent}, recibidos {received}, descartados {dropped}"
L.PROBE_REGISTERED = "registrado"
L.PROBE_NOT_REGISTERED = "NO registrado ({result})"
L.PROBE_POSSIBLE = "posible"
L.PROBE_ABSENT = "falta"
L.PROBE_WAITS = " · espera: {why}"
L.PROBE_LISTED = "Entradas a mano (M): enviadas {sent}, recibidas {received}, descartadas {dropped} · tachadas (X): enviadas {usent}, recibidas {ureceived}, descartadas {udropped}"
L.PROBE_GUILDBOOK = "Libro de la hermandad: {text}"
L.PROBE_SAVED = "Guardado en DeathNoteDB.probe (en el archivo tras /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Puesto"  -- [max 14]
L.SORT_RECENT = "Recientes"  -- [max 14]
L.SORT_NAME = "Nombre"  -- [max 14]
L.SORT_SEEN = "Avistados"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Quien te mate en el mundo abierto acaba aquí. Sin que hagas nada."
L.EMPTY_OPEN_HEAD = "Nada sin resolver."
L.EMPTY_JOURNAL_HEAD = "Ninguna muerte todavía."
L.EMPTY_JOURNAL_SUB = "Respeto. O mentira."
L.EMPTY_NOGUILD_HEAD = "Sin hermandad."
L.EMPTY_NOGUILD_SUB = "Morir a solas también se puede."
L.EMPTY_GUILDOFF_HEAD = "El libro de la hermandad está cerrado."
L.EMPTY_GUILDOFF_SUB = "Compartir está desactivado. Las Normas de la casa saben dónde."
L.EMPTY_GUILDNIL_HEAD = "Aún no hay noticias de la hermandad."
L.EMPTY_GUILDNIL_SUB = "Tu libro sale en cuanto un compañero tenga DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Aún no hay nada en el libro de la hermandad."
L.EMPTY_GUILDQUIET_SUB = "Tus compañeros han tenido paz hasta ahora."
L.EMPTY_FRIENDSOFF_HEAD = "El libro de los amigos está cerrado."
L.EMPTY_FRIENDSOFF_SUB = "Compartir con amigos está desactivado. Las Normas de la casa saben dónde."
L.EMPTY_FRIENDSNIL_HEAD = "Aún no hay noticias de amigos con DeathNote."
L.EMPTY_FRIENDSNIL_SUB = "Tu libro sale en cuanto un amigo tenga DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Aún nada de tus amigos."
L.EMPTY_FRIENDSQUIET_SUB = "Tus amigos han tenido paz hasta ahora."
L.EMPTY_NOBODY_HEAD = "Ni hermandad, ni amigos."
L.EMPTY_NOBODY_SUB = "Morir a solas también se puede."
L.EMPTY_NOBODY_HINT = "Cuando tus compañeros de hermandad o los amigos de tu lista de amigos tengan DeathNote, esta página mostrará lo que les pasa."
L.EMPTY_SHAREDNIL_HEAD = "Aún no hay noticias de nadie con DeathNote."
L.EMPTY_SHAREDNIL_SUB = "Tu libro sale en cuanto compañeros o amigos tengan DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Aquí aún no hay nada."
L.EMPTY_SHAREDQUIET_SUB = "La hermandad y los amigos han tenido paz hasta ahora."
L.EMPTY_HUNT_HEAD = "La lista negra está vacía."
L.EMPTY_HUNT_SUB = "En el cartel: Abrir la caza."
L.EMPTY_HUNT_HINT = "O en el chat: /dn hunt Nombre Apellido. Lo ven toda tu hermandad y tus amigos."
L.EMPTY_SEARCH_HEAD = "Sin resultados."
L.EMPTY_SEARCH_SUB = "Enter apunta el nombre en el libro."
L.EMPTY_SEARCHRO_HEAD = "Sin resultados."
L.EMPTY_SEARCHRO_SUB = "A veces ayuda escribirlo de otra forma."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "EL LIBRO"  -- [max 12]
L.MANUAL_BOOK = "Quien te mate en el mundo abierto queda apuntado solo. Un clic en el mensaje tras tu muerte abre la página del asesino."
L.MANUAL_WANTED_HEAD = "SE BUSCA"  -- [max 12]
L.MANUAL_WANTED = "Tus asesinos, el peor primero. Un clic muestra el cartel con fechorías y nota. Los indultados aparecen tachados al final."
L.MANUAL_UNSOLVED_HEAD = "SIN RESOLVER"  -- [max 13]
L.MANUAL_UNSOLVED = "Si no quedó claro quién fue, el caso espera aquí. Un clic en un nombre fija al asesino."
L.MANUAL_ALERT_HEAD = "ALARMA"  -- [max 12]
L.MANUAL_ALERT = "Cuando un asesino aparece como placa de nombre, objetivo o bajo el cursor, el libro avisa. Un clic lo fija como objetivo, en combate solo después."
L.MANUAL_ADD_HEAD = "APUNTAR"  -- [max 12]
L.MANUAL_ADD = "Escribe un nombre en el campo de búsqueda, Enter. Clic derecho en una fila: anotar venganza, indultar, tachar."
L.MANUAL_GUILD_HEAD = "HERMANDAD"  -- [max 12]
L.MANUAL_GUILD = "La hermandad y los amigos con DeathNote ven tus muertes confirmadas y tus entradas a mano. Cartel o /dn hunt Nombre: abrir la caza. Clic en la recompensa: pon la tuya, una promesa que se paga entre vosotros."
L.MANUAL_SHARE_HEAD = "PASARLO"  -- [max 12]
L.MANUAL_SHARE = "Normas de la casa, Guardar copia: un texto para copiar, para todos los que no tienen DeathNote."
L.MANUAL_QUIET_HEAD = "SILENCIO"  -- [max 12]
L.MANUAL_QUIET = "En mazmorras y campos de batalla la alarma se calla. Si no: clic central en el botón del minimapa o /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "¿Seguro que quieres tachar a {name} del libro?\nSe perderán todas las fechorías y la nota."
L.CONFIRM_DELETE_OK = "Tachar"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "¿Vaciar el libro de la hermandad en este equipo?\nSu lista negra se va con él; tus propias órdenes se quedan.\nTu propio libro se queda como está."
L.CONFIRM_GUILD_CLEAR_OK = "Vaciar"  -- [max 14]
L.CONFIRM_CANCEL = "Cancelar"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} ORO"  -- [max 14]
L.BOUNTY_SILVER = "{count} PLATA"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Confirmar"  -- [max 19]
L.ACT_DISMISS = "Descartar"  -- [max 19]
L.ACT_HUNT_AGAIN = "Revocar indulto"  -- [max 19]
L.ACT_REVENGE = "Anotar venganza"  -- [max 19]
L.ACT_PARDON = "Indultar"  -- [max 19]
L.ACT_STRIKE = "Tachar"  -- [max 19]
L.ACT_OPEN_OWN = "Abrir en el libro"  -- [max 19]
L.ACT_ADOPT = "A mi libro"  -- [max 19]
L.ACT_CALLOFF = "Suspender la caza"  -- [max 19]
L.ACT_RELEASE = "Abrir la caza"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "avistamiento: {time}"
L.ROW_NOT_SEEN = "sin avistamientos"
L.ROW_PARDONED = "indulto concedido"
L.ROW_SUSPECT = "Sospecha"
L.MARK_REVENGE = "VENGANZA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Asesino incierto"
L.MARK_CANDIDATES = "{count} {count|CANDIDATO|CANDIDATOS}"  -- [max 16]
L.MARK_SUSPECT = "SOSPECHA"  -- [max 16]
L.ROW_NO_PLAYER = "Ningún jugador"
L.ROW_UNCLEAR = "Causa incierta"
L.MARK_NOT_COUNTED = "NO CUENTA"  -- [max 16]
L.ROW_LISTED_BY = "añadido por {names}"
L.ROW_GKILLED = "mató {kills}×"
L.ROW_VICTIMS = "{count} {count|víctima|víctimas}"
L.ROW_LAST = "última: {text}"
L.MARK_IN_BOOK = "EN EL LIBRO"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|asesino|asesinos}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|muerte|muertes}"  -- [max 12]
L.MEMBER_LISTED = "{count} a mano"  -- [max 14]
L.MEMBER_ME = "lo que los demás ven de ti"
L.MEMBER_NOTHING = "aún no ha compartido nada"
L.MEMBER_LAST_DIED = "última muerte {time}"
L.MARK_YOU = "tú"  -- [max 16]
L.MARK_FRIEND = "AMIGO"  -- [max 16]
L.MARK_BOTH = "HERMANDAD, AMIGO"  -- [max 20]
L.MARK_TAKEN_DOWN = "ABATIDO {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "VIVO O MUERTO"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "FECHORÍAS"  -- [max 14]
L.POSTER_NOTE = "NOTA"  -- [max 8]
L.POSTER_BOUNTY = "RECOMPENSA"  -- [max 12]
L.ROLE_ASSIST = "cómplice"  -- [max 14]
L.ROLE_SUSPECT = "sospecha"  -- [max 14]
L.POSTER_LEVEL = "Nivel {level}"
L.POSTER_GUILD = "Hermandad: {guild}"
L.POSTER_LAST_SEEN = "Último avistamiento: {time}"
L.POSTER_NOT_SEEN = "Sin avistamientos"
L.POSTER_ONLY_SUSPECT = "Solo sospecha, ninguna fechoría probada."
L.POSTER_NO_DEEDS = "No hay fechorías anotadas."
L.TIP_LISTED_AT = "Añadido el {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Causa de la muerte: {spell}"
L.TIP_VICTIM = "Víctima: {name}"
L.TIP_VICTIM_LEVEL = "Víctima: {name} (nivel {level})"
L.TIP_KILLER_LEVEL = "Nivel del asesino: {level}"
L.TIP_ASSISTS = "Cómplices: {names}"
L.TIP_ROLE_ASSIST = "Cómplice, no dio el golpe de gracia."
L.TIP_ROLE_SUSPECT = "Solo sospecha, nada probado."
L.MORE_LINE = "… y {count} más"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "LIBRO DE LA HERMANDAD"  -- [max 24]
L.POSTER_IN_BOOK_OF = "En el libro de: {names}"
L.POSTER_SEEN = "Avistamiento: {time}"
L.POSTER_SEEN_BY = "Avistamiento: {time}, por {name}"
L.TIP_IN_BOOK_OF = "En el libro de"
L.POSTER_REMARK = "OBSERVACIÓN"  -- [max 12]
L.POSTER_BY_HAND = "AÑADIDO A MANO"  -- [max 22]
L.POSTER_VICTIMS = "VÍCTIMAS"  -- [max 12]
L.POSTER_LISTED = "AÑADIDO POR"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Añadido a mano."
L.POSTER_NO_DEEDS_SENT = "No llegó ninguna fechoría."
L.POSTER_NONE_KNOWN = "ninguna conocida"
L.POSTER_NO_NAMES = "no llegó ningún nombre"
L.TIP_VICTIMS = "Víctimas"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Orden del {time}"
L.HUNT_REASON = "Motivo: {reason}"
L.POSTER_HUNTLIST = "LISTA NEGRA"  -- [max 24]
L.POSTER_RELEASED_N = "caza abierta {times}"
L.POSTER_RELEASED_BY = "Orden de {names}"
L.POSTER_TAKEN_DOWN = "BAJAS"  -- [max 12]
L.POSTER_NOT_YET = "AÚN NO"  -- [max 18]
L.POSTER_CALLS = "ÓRDENES"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Ya no queda nadie."
L.POSTER_LAST = "ÚLTIMA"  -- [max 13]
L.POSTER_TAKEN_BY = "cayó ante {name}, {time}"
L.POSTER_TAKEN_NOBODY = "sigue en libertad"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Defunción"  -- [max 20]
L.CASE_ASSISTS = "CÓMPLICES"  -- [max 24]
L.CASE_PICK = "ELEGIR AL ASESINO"  -- [max 24]
L.CASE_NOT_COUNTED = "No cuenta (instancia, campo de batalla o duelo)"
L.CASE_KILLER = "ASESINO"  -- [max 24]
L.CASE_KILLER_SUSPECT = "ASESINO (SOSPECHA)"  -- [max 24]
L.CASE_CLICK_NAME = "Haz clic en el nombre para abrir su cartel."
L.CASE_GONE = "Ya no está en el libro."
L.CASE_KILLER_UNCLEAR = "ASESINO INCIERTO"  -- [max 24]
L.CASE_SEVERAL = "Pudieron ser varios. ¿Qué nombre va al libro?"
L.CASE_NOBODY = "No pudo ser nadie."
L.CASE_HOW = "QUÉ PASÓ"  -- [max 24]
L.CASE_PVE = "Un monstruo o el propio mundo. No es un caso para el libro."
L.CASE_UNCLEAR = "Incierto"
L.CASE_DARK = "Los forenses andan a ciegas."
L.TIP_MORE_CANDIDATES = "Más candidatos"
L.CASE_SOURCE_SUSPECT = "Sospecha: te tenía como objetivo poco antes de tu muerte."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Línea en el tooltip de los asesinos"  -- [max 44]
L.OPT_MINIMAP = "Mostrar el botón del minimapa"  -- [max 44]
L.OPT_ALERT = "Alarma cuando aparezca un asesino"  -- [max 44]
L.OPT_FLASH = "Destello rojo en el borde de la pantalla"  -- [max 44]
L.OPT_SUSPECTS = "Avisar también de sospechosos"  -- [max 44]
L.OPT_DEATHMSG = "Mensaje tras una muerte JcJ"  -- [max 44]
L.OPT_G_SHARE = "Compartir mis muertes"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Compartir entradas a mano"  -- [max 44]
L.OPT_G_RECEIVE = "Recibir el libro de la hermandad"  -- [max 44]
L.OPT_G_ALERT = "Avisar de asesinos del libro de hermandad"  -- [max 44]
L.OPT_G_ALERTLISTED = "Avisar también de entradas a mano"  -- [max 44]
L.OPT_G_ANNOUNCE = "Avisar cuando maten a un compañero"  -- [max 44]
L.OPT_G_SIGHTINGS = "Compartir avistamientos"  -- [max 44]
L.OPT_F_SHARE = "Compartir con la hermandad"  -- [max 44]
L.OPT_F_FRIENDS = "Compartir con amigos"  -- [max 44]
L.OPT_F_ALERT = "Avisar de asesinos de hermandad y amigos"  -- [max 44]
L.OPT_F_ALERTHUNT = "Avisar de objetivos de la lista negra"  -- [max 44]
L.OPT_F_ANNOUNCE = "Avisar cuando mueran compañeros o amigos"  -- [max 44]
L.OPT_F_SIGHTINGS = "Compartir avistamientos con los tuyos"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Hermandad"  -- [max 14]
L.SET_BOOK_SIZE = "Tamaño del libro"  -- [max 34]
L.SET_LANGUAGE = "Idioma"  -- [max 16]
L.SET_LANG_AUTO = "Automático"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Se aplica al recargar."  -- [max 28]
L.SET_LANG_RELOAD = "Recargar ahora"  -- [max 22]
L.SET_SEC_SHARE = "PASARLO"  -- [max 24]
L.IO_EXPORT = "Guardar copia"  -- [max 17]
L.IO_IMPORT = "Importar libro"  -- [max 17]
L.SET_HINT_BOOK = "Guardar copia te da el libro como texto: para conservarlo o pasarlo a gente de fuera de la hermandad. Importar fusiona y no sobrescribe nada."
L.SET_SEC_SOUND = "SONIDO"  -- [max 24]
L.SET_SOUND = "Sonido"  -- [max 22]
L.SET_VOLUME = "Volumen"  -- [max 22]
L.SET_CHANNEL = "Canal"  -- [max 12]
L.SET_SEC_THRESHOLD = "UMBRAL"  -- [max 24]
L.SET_COOLDOWN = "Pausa de alarma por asesino"  -- [max 34]
L.SET_MINKILLS = "Muertes por asesino para alarma"  -- [max 34]
L.SET_ALERT_SIZE = "Tamaño de la alarma"  -- [max 34]
L.SET_TEST_ALERT = "Probar alarma"  -- [max 17]
L.SET_G_MINKILLS = "Aviso de hermandad: muertes"  -- [max 34]
L.SET_F_MINKILLS = "Aviso tras tantas muertes"  -- [max 34]
L.SET_SEC_STATUS = "ESTADO"  -- [max 24]
L.SET_SEC_SHARING = "COMPARTIR"
L.SET_SEC_WARN = "ALARMA"
L.SET_MORE = "Más"
L.SET_GUILD_CLEAR = "Vaciar libro hermandad"  -- [max 26]
L.SET_HINT_GUILD = "Solo tu propia hermandad recibe algo. Lo que llega de ahí queda aparte de tu libro hasta que tú mismo lo copies."
L.SET_HINT_FRIENDS = "Solo la hermandad y los amigos con DeathNote reciben algo."
L.BTN_BACK = "Volver"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sincronizar"  -- [max 14]
L.SYNC_AGAIN_IN = "espera {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Amigos"
L.TIP_GUILD_NAME = "Hermandad {guild}"
L.TIP_MATES_WITH = "Compañeros de hermandad con DeathNote:"
L.TIP_NO_MATE = "Aún no hay noticias de compañeros con DeathNote."
L.TIP_FRIENDS_WITH = "Amigos con DeathNote:"
L.TIP_SHARED = "Se comparte: tus muertes confirmadas, tus entradas a mano y tus órdenes de caza."
L.TIP_NOT_SHARED = "No se comparte: notas, sospechas, indultados, entradas importadas."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Importar"  -- [max 17]
L.IO_DONE = "Importado: {new} nuevos, {merged} fusionados."
L.IO_FAILED = "No ha funcionado."
L.IO_SMALL = "Solo lo básico"  -- [max 17]
L.IO_ALL = "Mostrar todo"  -- [max 17]
L.IO_MSG_FULL = "Libro completo con fechorías ({size})."
L.IO_MSG_SHORT = "Solo nombres y recuentos ({size}). Con fechorías: {full}."
L.IO_MSG_BIG = "Libro grande ({size}): seleccionar y copiar tarda un momento."
L.IO_HELP_EXPORT = "El texto está seleccionado: Ctrl+C lo copia. Guárdalo o pásaselo a tus amigos."
L.IO_HELP_IMPORT = "Pega un texto guardado con Ctrl+V y luego Importar. No se sobrescribe nada."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Toda tu hermandad y tus amigos con DeathNote ven el motivo."
L.REL_HINT_GUILD = "Toda tu hermandad con DeathNote ve el motivo."
L.REL_HINT_FRIENDS = "Tus amigos con DeathNote ven el motivo."
L.REL_HEAD = "Abrir la caza"  -- [max 24]
L.REL_FOR = "PARA"  -- [max 6]
L.REL_REASON = "MOTIVO"  -- [max 8]
L.REL_HINT2 = "Tu nota se queda contigo. Solo tú puedes retirar tu propia orden."
L.REL_GO = "Dar la orden"  -- [max 17]
L.REL_NONE = "No hay hermandad y compartir con amigos está desactivado."
L.REL_CAP = "Como mucho {own} órdenes tuyas y {max} objetivos por lista."
L.REL_FAILED = "Ahora no se puede abrir la caza."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Sin sonido: la alarma solo se muestra."
L.SET_HINT_BUILTIN = "El volumen de este sonido sigue al canal en las opciones del juego."
L.SET_HINT_LEVELS = "Cinco niveles, de suave a fuerte. Encima se aplica el control del canal en las opciones del juego."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Hermandad y amigos"  -- [max 18]
L.TIP_HELP_BUTTON = "Cómo funciona el libro"
L.VIEW_HUNT = "Lista negra"  -- [max 13]
L.VIEW_BY_KILLER = "Por asesino"  -- [max 13]
L.VIEW_BY_MATE = "Por compañero"  -- [max 13]
L.SRC_ALL = "Todos"  -- [max 12]
L.SRC_GUILD = "Hermandad"  -- [max 12]
L.SRC_FRIENDS = "Amigos"  -- [max 12]
L.SORT_HIDE_PARDONED = "Ocultar indultados"  -- [max 24]
L.SORT_SHOW_PARDONED = "Mostrar indultados"  -- [max 24]
L.SEARCH_ADD = "Buscar o añadir …"  -- [max 26]
L.SEARCH_SHORT = "Buscar …"  -- [max 10]
L.SEARCH_KILLER = "Buscar asesino…"  -- [max 15]
L.SEARCH_JOURNAL = "Asesino o lugar …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Contraer todo"
L.TIP_EXPAND_ALL = "Expandir todo"
L.STATUS_NO_PLATES = "Placas de nombre enemigas desactivadas: la alarma solo ve el objetivo y el cursor."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} en busca y captura"
L.MM_UNSOLVED = "{count} sin resolver"
L.MM_ALERT_OFF = "Alarma desactivada (clic central)"
L.MM_CLICK = "Clic: libro · Clic derecho: Normas de la casa"
L.MM_MIDDLE = "Clic central: alarma sí/no"
L.MM_DRAG = "Arrastrar: mover por el borde del minimapa"
L.MM_CHAT_ALERT_ON = "Alarma activada."
L.MM_CHAT_ALERT_OFF = "Alarma desactivada."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "ENEMIGO DE HERMANDAD Nº 1"  -- [max 25]
L.STAMP_HUNT = "CAZA ABIERTA"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} se hizo pasar por tu amigo {friend}: rechazado."
L.FRIENDS_SHORT_IMPOSTOR = "Desconocido rechazado"  -- [max 22]
L.ALERT_LEVEL = "Nivel {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "último nivel {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Nivel ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · en la lista negra ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|objetivo nuevo|objetivos nuevos}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "nuevas entradas en la lista negra"
L.OPT_F_ANNOUNCEHUNT = "Avisar de la lista negra: nuevos y abatidos"  -- [max 44]
L.SET_HUNT_EXPIRE = "Las órdenes caducan tras"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nunca"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|día|días}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Vaciar libro de amigos"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "¿Vaciar el libro de los amigos en este equipo?\nSu lista negra se va con él; tus propias órdenes se quedan."
L.CONFIRM_CALLOFF_ALL = "¿Suspender todas tus órdenes en la lista negra?\nLa hermandad y los amigos se irán enterando poco a poco."
L.CONFIRM_CALLOFF_ALL_OK = "Suspender todo"  -- [max 14]
L.ACT_CALLOFF_ALL = "Suspender mis órdenes"  -- [max 24]
L.ACT_HUNT_HIDE = "Ocultar para mí"  -- [max 19]
L.ACT_HUNT_SHOW = "Mostrar de nuevo"  -- [max 19]
L.HUNT_ROW_HIDDEN = "no visible para ti"
L.HUNT_ROW_CALLS = "{count} {count|orden|órdenes}: {names}"
L.POSTER_ON_HUNTLIST = "En la lista negra ({names})"
L.REL_SELF = "No puedes abrir la caza contra ti."
L.REL_MATE = "Es de los tuyos (hermandad o amigos con DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "¿Quién es tu amigo {friend}: {a} o {b}? Elige tú."
L.FRIENDS_SHORT_CONFLICT = "Amigo dudoso"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Dos jugadores dicen ser tu amigo {friend}: {a} y {b}. Hasta que elijas, el libro no acepta nada de ninguno de los dos. Hermandad y amigos, vista Por compañero: clic derecho en el nombre."
L.MEMBER_CONFLICT = "Clic derecho: ¿es tu amigo?"  -- [max 40]
L.ACT_TIE_MINE = "Mi amigo: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Desvincular"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "¿Desvincular a {name} de tu lista de amigos?\nLo que este nombre trajo al libro de los amigos se borra; el próximo mensaje con este nombre vuelve a vincular."
L.CHAT_FRIENDS_TIES = "Nombres completos vinculados (* = primer contacto, aún sin confirmar): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Nombre [Apellido]> <oro>  poner tu propia recompensa (sin oro: retirarla)"
L.CHAT_WHO_BOUNTY = "¿Por quién? /dn bounty <Nombre> <oro>"
L.CHAT_BOUNTY_SET = "{name}: ofreces una recompensa de {gold} de oro. La hermandad y los amigos con DeathNote la ven."
L.CHAT_BOUNTY_OFF = "{name}: tu recompensa queda retirada."
L.CHAT_BOUNTY_NONE = "No tienes ninguna recompensa propia por {name}."
L.CHAT_BOUNTY_BAD = "Recompensa: un número entero de oro, de 1 a 99999 (0 la retira)."
L.CHAT_BOUNTY_CAP = "Sin recompensa: como mucho {count} tuyas."
L.CHAT_BOUNTY_OURS = "Ninguna recompensa por ti ni por los tuyos (hermandad o amigos con DeathNote)."
L.ACT_BOUNTY = "Poner recompensa"  -- [max 24]
L.ACT_UNDO = "Deshacer"  -- [max 19]
L.ACT_REVENGE_TAKE = "Quitar una venganza"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, ofrecida por ti"
L.POSTER_BOUNTY_BY = "{gold}, ofrecida por {name}"
L.POSTER_BOUNTY_MANY = "Recompensa {gold}: {names}"
L.POSTER_AVENGED = "Vengado por {names}"
L.ROW_AVENGED = "vengado {times}"
L.BOUNTY_TIP_HEAD = "Tu propia recompensa, en oro"
L.BOUNTY_TIP_RULES = "Un número entero, de 1 a 99999. Vacío o 0: vuelve al valor del libro. Intro la pone, Esc cancela."
L.BOUNTY_TIP_PROMISE = "La hermandad y los amigos con DeathNote la ven. Solo una promesa: se paga entre vosotros."
L.BOUNTY_TIP_CLICK = "Clic: poner tu propia recompensa"
L.CHAT_AVENGED = "{name} ha abatido a {killer} por ti."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: ofreces una recompensa de {gold} de oro."
L.CHAT_BOUNTY_UNKNOWN = "{name} no está en ninguno de tus libros. Solo se pone recompensa a un nombre de un libro, tal como lo muestra el juego: nombre y apellido."
L.CHAT_BOUNTY_LIST = "Tus recompensas ({count} de {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "No has puesto ninguna recompensa."
-- <<< BOOK
-- >>> REPUTE (1.3.0) -----------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Rango {tier} · Camino: {path}"  -- [max 32]
L.PATH_R = "Infamia"  -- [max 16]
L.PATH_E = "Honor"  -- [max 16]
L.PATH_J = "Caza"  -- [max 16]
L.PATH_S = "Protección"  -- [max 16]
L.PATH_NONE = "en blanco"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) -------------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "¿RENCOROSO?"  -- [max 30]
L.ALERT_LINE_VICTIM = "marcador {score} · abatido por ti, última vez {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · marcador {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · marcador {score}, en paz"
L.ALERT_LINE_STANDING_AHEAD = "{text} · marcador {score}, con intereses"
-- <<< ALARM
-- >>> START (1.3.0) -------------------------------------------------------------------------------------------------
L.SET_THEME = "Tapa"  -- [max 16]
L.START_HINT = "Puedes cambiar ambos luego en las Normas de la casa."  -- [max 60]
L.START_GO = "Adelante"  -- [max 16]
L.START_CLOSE_TIP = "Dejarlo así"  -- [max 32]
L.CHAT_THEME_NEWS = "Novedad: el libro viene con otras tapas. Normas de la casa, hoja Libro, o /dn theme."
L.HELP_START = "/dn start  volver a abrir la ventana de inicio (idioma y tapa)"
-- <<< START
-- >>> RECORD (1.3.0) -----------------------------------------------------------------------------------------------
L.TAB_RECORD = "Antecedentes"  -- [max 16]
L.STAMP_QUITT = "EN PAZ"  -- [max 16]
L.STAMP_OVERPAID = "CON INTERESES"  -- [max 16]
L.STAMP_NR1_DOWN = "ENEMIGO Nº 1 ABATIDO"  -- [max 24]
L.STATE_OPEN = "abierto"  -- [max 16]
L.STATE_EVEN = "en paz"  -- [max 16]
L.STATE_AHEAD = "con intereses"  -- [max 16]
L.STATE_VICTIM = "no está en el libro"  -- [max 24]
L.STAND_LINE = "Marcador {score}"
L.STAND_TIP = "tú {mine}, él {his}"
L.TIP_IN_RECORD = "ANTECEDENTES:"
L.TIP_RECORD_LINE = "abatido por ti {times}, última vez {time}"
L.RECORD_HEAD = "Tu expediente"  -- [max 20]
L.RECORD_LOG_HEAD = "Últimas bajas"  -- [max 20]
L.RECORD_NEXT = "faltan {points} para {rank}"
L.RECORD_TOP = "Rango máximo alcanzado."
L.RECORD_BAR_TIP = "{total} de {goal} puntos"
L.RECORD_NEEDLE_LOW = "despiadado"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "honorable"  -- [max 12]
L.RECORD_NEEDLE_TIP = "La aguja: honor y protección frente a infamia. La caza no la mueve."
L.RECORD_KILLS = "Bajas: {kills} · Víctimas: {victims}"
L.RECORD_BEST = "Récords: {list}"
L.RECORD_BEST_GAP = "+{count} {count|nivel|niveles}"
L.RECORD_BEST_STREAK = "racha de {count}"
L.RECORD_BEST_QUICK = "venganza más rápida {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} h"
L.RECORD_AWARDS = "DISTINCIONES"  -- [max 14]
L.RECORD_AWARD_AT = "otorgada el {time}"
L.RECORD_AWARD_OPEN = "aún no otorgada"
L.RECORD_MORE = "Ver más"  -- [max 19]
L.RECORD_BACK = "Al expediente"  -- [max 19]
L.RECORD_CLEAR = "Borrar antecedentes"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "¿Borrar los antecedentes?\nSe van todas las víctimas y la lista de últimas bajas. El rango, los puntos y las distinciones se quedan."
L.CONFIRM_RECORD_CLEAR_OK = "Borrar"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "¿Tachar a {name} de los antecedentes?\nLos puntos ganados se quedan."
L.ACT_VICTIM_STRIKE = "Tachar de antecedentes"  -- [max 26]
L.VICTIM_KILLED = "abatido por ti {times}"
L.VICTIM_POINTS = "Puntos ganados: {points}"
L.VICTIM_SCENE = "Lugar de los hechos: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "TUS BAJAS"  -- [max 14]
L.KILL_TAG_REVENGE = "venganza"  -- [max 14]
L.KILL_TAG_KICK = "ensañamiento"  -- [max 14]
L.KILL_TAG_GROUP = "grupo"  -- [max 14]
L.KILL_WITH_GROUP = "Con el grupo."
L.BAND_GRAU = "gris"  -- [max 12]
L.BAND_GRUEN = "verde"  -- [max 12]
L.BAND_GELB = "amarillo"  -- [max 12]
L.BAND_ORANGE = "naranja"  -- [max 12]
L.BAND_ROT = "rojo"  -- [max 12]
L.BAND_SCHAEDEL = "calavera"  -- [max 12]
L.BAND_UNBEKANNT = "desconocido"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "sin puntos"
L.RECORD_BANDS = "Por color de nivel"
L.TIP_PATH_R = "Infamia: bajas de grises y verdes."
L.TIP_PATH_E = "Honor: bajas de jugadores de tu nivel, venganza."
L.TIP_PATH_J = "Caza: bajas de niveles superiores, objetivos de la lista negra, recompensas."
L.TIP_PATH_S = "Protección: bajas de jugadores que mataron a compañeros de hermandad o amigos."
L.SORT_STATE = "Marcador"  -- [max 14]
L.SORT_COUNT = "Bajas"  -- [max 14]
L.SORT_POINTS = "Puntos"  -- [max 14]
L.CHAT_OWN_KILL = "Antecedentes: {name}, {level} ({band}). {points}."
L.CHAT_PATH = "Nuevo camino: {path}. Rango: {rank}."
L.BANNER_RANK = "NUEVO RANGO"  -- [max 24]
L.BANNER_AWARD = "DISTINCIÓN"  -- [max 24]
L.OPT_LEDGER = "Llevar registro de antecedentes"  -- [max 44]
L.OPT_LEDGER_CHAT = "Anunciar mis bajas en el chat"  -- [max 44]
L.OPT_VICTIMS = "Avisar cuando aparezca una víctima mía"  -- [max 44]
L.SET_SETTLED = "Alarma con la cuenta saldada"  -- [max 34]
L.SET_SETTLED_ALWAYS = "normal"  -- [max 10]
L.SET_SETTLED_QUIET = "silencioso"  -- [max 10]
L.SET_SETTLED_OFF = "nunca"  -- [max 10]
L.MANUAL_RECORD_HEAD = "ANTECEDENTES"  -- [max 14]
L.MANUAL_RECORD = "Tus propios golpes de gracia a jugadores. El cartel y la lista muestran el marcador «tú : él»: abierto, en paz o con intereses. El puesto 1 siempre está abierto. Las bajas dan puntos para tu rango."
L.POSTER_LAST_SEEN_IN = "Último avistamiento: {zone}, {time}"
L.SHEET_RECORD = "Antecedentes"  -- [max 14]
L.EMPTY_RECORD_HEAD = "Nadie todavía."
L.EMPTY_RECORD_SUB = "El jugador del otro bando que mates acaba aquí."
-- <<< RECORD
end)
