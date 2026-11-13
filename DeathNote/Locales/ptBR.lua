-- DeathNote: Português (Brasil) (ptBR, also used for ptPT). Translated from enUS.lua (meaning from deDE.lua);
-- game terms as in the Brazilian client, informal "você".
-- Plural: 2 forms {count|one|other} (0 and 1 | everything else). Rule in Locale.lua (PLURAL_OF.ptBR), not here.
-- Fonts: latin (as 1.1.0: Skurri, Morpheus, Friz Quadrata, Nimrod) (Locale.lua, FONTS). Copy the keys of enUS.lua, keep the order and the [max N].
--
-- TOC-Notes: Lista de caça para PvP no mundo aberto: lembra quem matou você e avisa quando essa pessoa está por perto.

local _, ns = ...
local Locale = ns and ns.Locale
if not (Locale and Locale.Wants("ptBR")) then return end

Locale.Register("ptBR", function(L)

-- Tabs on the black cover ------------------------------------------------------------------------
L.TAB_WANTED   = "Procurados"      -- [max 16]
L.TAB_UNSOLVED = "Não resolvidos"  -- [max 16]
L.TAB_DEATHLOG = "Obituário"       -- [max 16]
L.TAB_GUILD    = "Guilda"          -- [max 16]

-- Page heads (big handwriting on the right page) ---------------------------------------------------
L.HEAD_RULES = "Regras da casa"      -- [max 24]
L.HEAD_HELP  = "Modo de usar"        -- [max 24]

-- Sheets of the House Rules (small word tabs under the head) --------------------------------------
L.SHEET_BOOK  = "Livro"          -- [max 14]
L.SHEET_ALERT = "Alarme"         -- [max 14]

-- Stamps on the wanted poster (capitals, short; WANTED itself is never translated) ----------------
L.STAMP_NR1      = "INIMIGO PÚBLICO Nº 1"  -- [max 24]
L.STAMP_REVENGE  = "CONTA ACERTADA"        -- [max 16]
L.STAMP_PARDONED = "PERDÃO"                -- [max 16]
L.STAMP_SUSPECT  = "SUSPEITA"              -- [max 16]

-- Alarm popup (top of the screen, angular font, capitals) -----------------------------------------
L.ALERT_SIGHTED_NR1     = "INIMIGO Nº 1 AVISTADO"         -- [max 30]
L.ALERT_SIGHTED         = "INIMIGO PÚBLICO AVISTADO"      -- [max 30]
L.ALERT_SIGHTED_SUSPECT = "SUSPEITO AVISTADO"             -- [max 30]
L.ALERT_TITLE_GUILD     = "INIMIGO DA GUILDA AVISTADO"    -- [max 30]
L.ALERT_TITLE_FRIENDS   = "ASSASSINO DE AMIGOS AVISTADO"  -- [max 30]
L.ALERT_TITLE_HUNT      = "ALVO DA LISTA DE CAÇA"           -- [max 30]
L.ALERT_LINE_SUSPECT        = "está sob suspeita"
L.ALERT_LINE_KILLED         = "matou você {times}"
L.ALERT_LINE_KILLED_ASSISTED = "matou você {times}, cúmplice {assists}"
L.ALERT_LINE_ASSISTED       = "ajudou a matar você {times}"
L.ALERT_LINE_MANUAL         = "está no livro (à mão)"
L.ALERT_LINE_LAST    = "{text}, última vez {time}"
L.ALERT_LINE_IN      = "{text}, zona: {zone}"
L.ALERT_LINE_REVENGE = "{text}. Vingança: {times}"
L.ALERT_HINT_CLOSE  = "Botão direito: fechar"                       -- [max 44]
L.ALERT_HINT_COMBAT = "Selecionar alvo só depois do combate"        -- [max 44]
L.ALERT_HINT_TARGET = "Clique: alvo  ·  Botão direito: fechar"      -- [max 44]
L.ALERT_MORE = "+{count} {count|outro|outros}"  -- [max 14]
L.SAMPLE_ZONE = "Selva do Espinhaço"

-- Shared lines in the alarm, the guild book and the hit list --------------------------------------
L.GUILD_LINE_IN_GUILD   = "está no livro da guilda"
L.GUILD_LINE_IN_FRIENDS = "está no livro dos amigos"
L.GUILD_LINE_LISTED_BY  = "está no livro de {names}"
L.GUILD_LINE_KILLED_GUILD   = "matou membros da guilda {kills}×"
L.GUILD_LINE_KILLED_FRIENDS = "matou amigos {kills}×"
L.GUILD_LINE_KILLED_BOTH    = "matou membros da guilda e amigos {kills}×"
L.GUILD_LINE_LAST = "{text}, última vítima: {name}"
L.HUNT_LINE_BY       = "caçada aberta por {names}"
L.HUNT_LINE_RELEASED = "na lista de caça"
L.HUNT_LINE_REASON   = "{text}: {reason}"

-- Small building blocks ---------------------------------------------------------------------------
L.TIMES = "{count}×"
L.TALLY_SUSPECT  = "sob suspeita"
L.TALLY_MANUAL   = "incluído à mão"
L.TALLY_NONE     = "nenhum crime ainda"
L.TALLY_KILLED   = "matou você {times}"
L.TALLY_ASSISTED = "cúmplice {times}"
L.PLACE_UNKNOWN  = "lugar desconhecido"
L.GKILLS_CAP     = "pelo menos {count}"
L.NAMELIST_MORE  = "{names} e mais {count}"

-- Time and money (one place for all time forms) ---------------------------------------------------
L.TIME_FMT_WHEN      = "%d/%m %H:%M"
L.TIME_FMT_WHEN_YEAR = "%d/%m/%Y %H:%M"
L.TIME_FMT_DAY       = "%d/%m"
L.TIME_FMT_DAY_YEAR  = "%d/%m/%y"
L.TIME_NEVER   = "nunca"
L.TIME_JUST    = "agora mesmo"
L.TIME_MINUTES = "há {count} min"         -- [max 14]
L.TIME_HOURS   = "há {count} h"           -- [max 14]
L.TIME_DAYS    = "há {count} {count|dia|dias}"  -- [max 16]
L.MONEY_GOLD   = "{count} o"
L.MONEY_SILVER = "{count} p"
L.MONEY_COPPER = "{count} c"

-- Guild and friends status (House Rules, /dn guild, /dn friends) ----------------------------------
L.GUILD_HEARD    = "Sinal de {count} {count|membro|membros} da guilda com DeathNote."
L.HEALTH_NOGUILD = "Você não está em nenhuma guilda, nada é compartilhado."
L.HEALTH_OFF     = "O compartilhamento está desligado."
L.HEALTH_SHORT_NOGUILD = "Sem guilda"         -- [max 18]
L.HEALTH_SHORT_OFF     = "Não compartilha"    -- [max 18]
L.HEALTH_SHORT_BLOCKED = "Bloqueado"          -- [max 18]
L.HEALTH_SHORT_FAILING = "Recusado"           -- [max 18]
L.HEALTH_SHORT_HOLD    = "Aguardando"         -- [max 18]
L.HEALTH_SHORT_ASKED   = "Solicitado"         -- [max 18]
L.HEALTH_SHORT_FAIL    = "Não funciona"       -- [max 18]

-- Alarm sounds and sound channels (House Rules, sheet Alert) --------------------------------------
L.SOUND_NONE        = "Sem som"           -- [max 16]
L.SOUND_RAIDWARNING = "Aviso de raide"    -- [max 16]
L.SOUND_BELL        = "Sino"              -- [max 16]
L.SOUND_GONG        = "Gongo"             -- [max 16]
L.SOUND_HEARTBEAT   = "Batimento"         -- [max 16]
L.SOUND_FEATHER     = "Pena"              -- [max 16]
L.SOUND_SIREN       = "Sirene"            -- [max 16]
L.CHANNEL_MASTER    = "Geral"             -- [max 16]
L.CHANNEL_SFX       = "Efeitos"           -- [max 16]
L.CHANNEL_DIALOG    = "Diálogo"           -- [max 16]

-- Chat lines after /dn commands -------------------------------------------------------------------
L.CHAT_ADDED     = "{name} agora está no livro."
L.CHAT_REMOVED   = "{name} não está mais no livro."
L.CHAT_SYNC_WAIT = "Acabou de sincronizar. Tente de novo em {seconds} s."

-- Empty book (first tab, nothing in it yet) -------------------------------------------------------
L.EMPTY_WANTED_HEAD = "Nenhum nome ainda."
L.EMPTY_WANTED_SUB  = "Saia de casa, pra variar."

-- Slash command help (/dn help), one line each, in the active language ------------------------
L.HELP_TOGGLE   = "/dn  abrir/fechar o livro"
L.HELP_ADD      = "/dn add <Nome [Sobrenome]>  incluir um assassino no livro à mão"
L.HELP_DEL      = "/dn del <Nome [Sobrenome]>  riscar um assassino do livro"
L.HELP_QUIET    = "/dn quiet  alarme desligado/ligado"
L.HELP_TEST     = "/dn test  mostrar um alarme de teste"
L.HELP_GUILD    = "/dn guild  livro da guilda: estado e quais membros têm DeathNote"
L.HELP_FRIENDS  = "/dn friends  livro dos amigos: estado e quais amigos têm DeathNote"
L.HELP_SYNC     = "/dn sync  sincronizar agora o livro da guilda e o dos amigos"
L.HELP_HUNT     = "/dn hunt <Nome [Sobrenome]>  abrir a caçada (sem nome: mostrar a lista de caça)"
L.HELP_CALLOFF  = "/dn calloff <Nome [Sobrenome]>  suspender a sua caçada"
L.HELP_LANG     = "/dn lang <código>  idioma do livro (enUS, deDE, frFR ...), depois de /reload"
L.HELP_THEME = "/dn theme <nome>  capa do livro, depois de /reload"
L.HELP_PROBE    = "/dn probe  diagnóstico: o que o jogo conta ao livro"
L.HELP_PROBE_COMBATLOG = "/dn probe combatlog  diagnóstico, testando também o registro de combate"
L.HELP_DEBUG    = "/dn debug  diagnóstico: anotar cada morte em detalhe (ligado/desligado)"
L.HELP_HELP     = "/dn help  esta ajuda"
L.HELP_SILENT_ZONES = "Em masmorras, campos de batalha e arenas o livro fica quieto por conta própria."

-- Chat lines (all start with the red "DeathNote: ") -----------------------------------------------
L.WORD_ON  = "ligado"
L.WORD_OFF = "desligado"
L.CHAT_WHO_ADD  = "Quem? /dn add <Nome>"
L.CHAT_WHO_DEL  = "Quem? /dn del <Nome>"
L.CHAT_WHO_CALLOFF = "Quem? /dn calloff <Nome>"
L.CHAT_BAD_NAME = "Nome inválido."
L.CHAT_NOT_IN_BOOK = "Não está no livro: {name}"
L.CHAT_ALARM_ON  = "Alarme ligado."
L.CHAT_ALARM_OFF = "Alarme desligado."
L.CHAT_DEBUG = "Registro de diagnóstico {state}."
L.CHAT_UNKNOWN_CMD = "Comando desconhecido. Ajuda: /dn help"
L.CHAT_GUILD_NOT_LOADED = "O livro da guilda não está carregado."
L.CHAT_NO_GUILD = "Você não está em nenhuma guilda (ou o jogo ainda não sabe)."
L.CHAT_GUILD_STATE = "Guilda {guild}: envio {share}, recebimento {receive}."
L.CHAT_GUILD_BOOK = "Livro da guilda: {enemies} assassinos ({listed} só incluídos à mão), {deeds} {deeds|crime|crimes}, {foreign} assassinos de membros da guilda. Compartilhar entradas à mão: {manual}."
L.CHAT_STATE_OK   = "Estado: {text}"
L.CHAT_STATE_WARN = "Atenção: {text}"
L.CHAT_NO_MATES   = "Nenhum sinal de membros da guilda com DeathNote ainda."
L.CHAT_HAVE_DN      = "Têm DeathNote: {names}"
L.CHAT_HAVE_DN_MORE = "Têm DeathNote: {names} e mais {count}"
L.CHAT_SYNC_ASKED = "Sincronização solicitada. As respostas chegam nos próximos segundos."
L.CHAT_SYNC_FAIL  = "A sincronização não funciona: {reason}"
L.CHAT_SYNC_FAIL_DEFAULT = "sem guilda ou o compartilhamento está desligado."
L.CHAT_FRIENDS_NOT_LOADED = "O livro dos amigos não está carregado."
L.CHAT_FRIENDS_STATE = "Amigos: envio {share}, {online} de {total} online."
L.CHAT_FRIENDS_BOOK  = "Livro dos amigos: {enemies} assassinos ({listed} só incluídos à mão), {deeds} {deeds|crime|crimes}."
L.CHAT_NO_FRIENDS    = "Nenhum sinal de amigos com DeathNote ainda."
L.CHAT_HUNT_NOT_LOADED = "A lista de caça não está carregada."
L.CHAT_HUNT_UNKNOWN = "Nome desconhecido: {name}. Use também o sobrenome, como aparece no jogo."
L.CHAT_HUNT_CAP     = "Não dá para abrir a caçada: no máximo {own} ordens suas e {targets} alvos por lista."
L.CHAT_HUNT_NOWHERE = "Não dá para abrir a caçada agora: sem guilda, e o compartilhamento com amigos está desligado."
L.CHAT_HUNT_BOTH    = "Caçada aberta contra {name}, para a guilda e os amigos."
L.CHAT_HUNT_GUILD   = "Caçada aberta contra {name}, para a guilda."
L.CHAT_HUNT_FRIENDS = "Caçada aberta contra {name}, para os seus amigos."
L.CHAT_CALLED_OFF   = "Caçada contra {name} suspensa."
L.CHAT_NO_OWN_CALL  = "Você não tem nenhuma ordem sua contra {name}."
L.CHAT_LANG_CURRENT = "Idioma atual: {lang}. Mudar: /dn lang <código>"
L.CHAT_LANG_LIST    = "Códigos: {codes}"
L.CHAT_LANG_BAD     = "Idioma desconhecido: {code}"
L.CHAT_LANG_SET     = "Idioma: {lang}."
L.CHAT_LANG_RELOAD  = "Idioma: {lang}. Vale depois de /reload."
L.CHAT_THEME_CURRENT = "Capa atual: {theme}. Mudar: /dn theme <nome>"
L.CHAT_THEME_LIST = "Capas: {themes}"
L.CHAT_THEME_BAD = "Capa desconhecida: {name}"
L.CHAT_THEME_SET = "Capa: {theme}."
L.CHAT_THEME_RELOAD = "Capa: {theme}. Vale depois de /reload."
L.THEME_NOTEBOOK = "O Livro Negro"
L.THEME_HARBOR = "O Livro do Corsário"
L.THEME_TRADE = "A Oficina"

-- First contact: three chat lines, once per account, 5 s after the first login --------------------
L.WELCOME = "O livro está pronto. Quem matar você no mundo aberto vai parar nele. Abra com /dn ou no botão do minimapa."
L.WELCOME_PLATES = "As placas de identificação inimigas estão desligadas. Sem elas, o alarme só vê o seu alvo."
L.WELCOME_SHARE = "A guilda e os amigos que têm DeathNote também o leem. Notas e suspeitas ficam com você."

-- Unit tooltip (one line under the player's tooltip) ---------------------------------------------
L.TIP_IN_BOOK   = "NO LIVRO:"
L.TIP_HUNT      = "LISTA DE CAÇA:"
L.TIP_GUILDBOOK = "LIVRO DA GUILDA:"
L.TIP_PARDONED  = "perdão concedido"
L.TIP_RANK      = "posição {rank}"
L.TIP_REVENGE   = "vingança {times}"
L.TIP_LISTED_BY = "no livro de {names}"
L.TIP_NOTE      = "Nota: {note}"

-- Screen message after a death, revenge, a guild or friend death (black strip in the middle) -------
L.BANNER_TIP          = "Clique: abrir · Botão direito: fechar"
L.BANNER_NEW          = "NOVA ENTRADA"         -- [max 24]
L.BANNER_NEW_LINE     = "agora está no livro"
L.BANNER_AGAIN        = "DE NOVO"              -- [max 24]
L.BANNER_AGAIN_LINE   = "matou você de novo, já são {count} vezes"
L.BANNER_SUSPECT      = "SUSPEITA"             -- [max 24]
L.BANNER_SUSPECT_LINE = "está sob suspeita, resolva no livro"
L.BANNER_UNCLEAR      = "ASSASSINO INCERTO"    -- [max 24]
L.BANNER_CANDIDATES   = "{count} {count|candidato|candidatos}"
L.BANNER_UNCLEAR_LINE = "Clique: escolha o assassino em Não resolvidos"
L.BANNER_REVENGE      = "TROCO DADO"           -- [max 24]
L.BANNER_REVENGE_LINE = "Vingança feita ({count}×)"
L.BANNER_GUILD        = "GUILDA"               -- [max 24]
L.BANNER_FRIENDS      = "AMIGOS"               -- [max 24]
L.BANNER_KILLED_BY    = "morreu nas mãos de {name}"
L.BANNER_HUNT         = "LISTA DE CAÇA"          -- [max 24]
L.BANNER_BAGGED       = "vítima de {name}, {time}"

-- Sharing status of guild and friends (status line of the fourth tab, House Rules, /dn guild) ------
L.SYNC_GUILD_OFF   = "O compartilhamento está desligado (Regras da casa, folha Guilda)."
L.SYNC_FRIENDS_OFF = "O compartilhamento com amigos está desligado."
L.SYNC_NOBODY      = "Sem guilda e sem amigos para compartilhar."
L.SYNC_SHORT_NOBODY = "Nada compartilhado"        -- [max 18]
L.SYNC_PREFIX      = "O jogo não permite receber. Entrar de novo ajuda."
L.SYNC_SHORT_PREFIX = "Não recebe"                -- [max 18]
L.SYNC_BLOCKED     = "O reino bloqueia o envio. Passe adiante com Salvar cópia."
L.SYNC_SHORT_BLOCKED = "Reino bloqueia envio"     -- [max 22]
L.SYNC_FAILING     = "O envio está falhando agora, tentando de novo."
L.SYNC_SHORT_FAILING = "Envio travado"            -- [max 18]
L.SYNC_HOLD        = "O envio aguarda {wait}."
L.SYNC_HOLD_INSTANCE = "você sair da instância"
L.SYNC_HOLD_COMBAT   = "você sair de combate"
L.SYNC_HOLD_LOCKDOWN = "o chat ficar livre de novo"
L.SYNC_HOLD_AGAIN    = "voltar a funcionar"
L.SYNC_HOLD_SHORT_INSTANCE = "Aguarda: instância" -- [max 18]
L.SYNC_HOLD_SHORT_COMBAT   = "Aguarda: combate"   -- [max 18]
L.SYNC_HOLD_SHORT_LOCKDOWN = "Aguarda: chat"      -- [max 18]
L.SYNC_QUIET       = "Enviado, mas nenhum sinal de membros com DeathNote ainda."
L.SYNC_READY       = "Pronto. Nenhum sinal de membros com DeathNote ainda."
L.SYNC_RUNNING     = "Funcionando: {count} {count|membro|membros} da guilda com DeathNote."
L.SYNC_RUNNING_ALL = "Funcionando: {count} com DeathNote entre guilda e amigos."
L.FRIENDS_OFF      = "O compartilhamento com amigos está desligado (Regras da casa, folha Guilda)."
L.FRIENDS_BLOCKED  = "O reino bloqueia sussurros. Os amigos não recebem nada."
L.FRIENDS_SHORT_BLOCKED = "Sussurros bloqueados"  -- [max 22]
L.FRIENDS_FAILING  = "Os sussurros estão falhando agora, tentando de novo."
L.FRIENDS_SHORT_FAILING = "Sussurros travados" -- [max 18]
L.FRIENDS_NONE_LISTED = "Ninguém na lista de amigos."
L.FRIENDS_NONE_ONLINE = "Nenhum amigo online agora."
L.FRIENDS_SHORT_NONE_ONLINE = "Ninguém online"    -- [max 18]
L.FRIENDS_QUIET    = "Solicitado, mas nenhum sinal de amigos com DeathNote ainda."
L.FRIENDS_READY    = "Pronto. Nenhum sinal de amigos com DeathNote ainda."
L.FRIENDS_HOLD     = "O envio aos amigos aguarda voltar a funcionar."
L.FRIENDS_RUNNING  = "Funcionando: {count} {count|amigo|amigos} com DeathNote."
L.NOTE_FROM_GUILD  = "Copiado do livro da guilda (matou membros da guilda {kills}×)."

-- Import book (House Rules, Import book): messages under the text field ---------------------------
L.IMPORT_NO_DB      = "Banco de dados não carregado."
L.IMPORT_NO_TEXT    = "Nenhum texto."
L.IMPORT_NO_HEADER  = "Falta a primeira linha (ela começa com {header}). Copie o texto inteiro."
L.IMPORT_NOT_EXPORT = "Não é uma exportação do DeathNote (falta o cabeçalho ou versão errada)."
L.IMPORT_TOO_LONG   = "Linhas demais (no máximo {count})."
L.IMPORT_BAD_KEY    = "Linha {line}: chave inválida."
L.IMPORT_BAD_TIME   = "Linha {line}: hora inválida."
L.IMPORT_BROKEN     = "A linha {line} está incompleta ou quebrada (texto cortado?). Nada foi importado."

-- /dn probe (troubleshooting output; the values themselves stay technical) ------------------------
L.WORD_YES = "sim"
L.WORD_NO  = "não"
L.PROBE_HEAD = "Sonda: {apis}/{apisAll} interfaces presentes, {events}/{eventsAll} eventos registráveis."
L.PROBE_MISSING = "Faltando: {list}"
L.PROBE_NOT_REGISTERABLE = "Não registráveis: {list}"
L.PROBE_SOURCES = "Recap agora: {recap} · Medidor: {meter} · Registro de combate: {clog}"
L.PROBE_READABLE = "legível"
L.PROBE_DEAD = "morto"
L.PROBE_PLATES = "Placas de identificação inimigas: {plates} · Mundo aberto: {open}"
L.PROBE_PLATES_OFF = "DESLIGADAS (só o alvo e o mouse detectam jogadores)"
L.PROBE_TARGET = "Alvo: nome={name} GUID={guid} classe={class} hostil={enemy} mira em mim={me}"
L.PROBE_GUILD = "Guilda: prefixo {prefix} · envio {send} · último valor de retorno {result} · enviados {sent}, recebidos {received}, descartados {dropped}"
L.PROBE_REGISTERED = "registrado"
L.PROBE_NOT_REGISTERED = "NÃO registrado ({result})"
L.PROBE_POSSIBLE = "possível"
L.PROBE_ABSENT = "faltando"
L.PROBE_WAITS = " · aguarda: {why}"
L.PROBE_LISTED = "Entradas à mão (M): enviadas {sent}, recebidas {received}, descartadas {dropped} · riscadas (X): enviadas {usent}, recebidas {ureceived}, descartadas {udropped}"
L.PROBE_GUILDBOOK = "Livro da guilda: {text}"
L.PROBE_SAVED = "Salvo em DeathNoteDB.probe (no arquivo depois de /reload)."

-- >>> BOOK (UI.lua) -------------------------------------------------------------------------------
-- Sorting (word button top right of the list, and the sort menu) ----------------------------------
L.SORT_RANK = "Posição"  -- [max 14]
L.SORT_RECENT = "Recentes"  -- [max 14]
L.SORT_NAME = "Nome"  -- [max 14]
L.SORT_SEEN = "Avistados"  -- [max 14]
-- Empty pages (right page when there is nothing to show: big line, small line, tiny hint) ---------
L.EMPTY_WANTED_HINT = "Quem matar você no mundo aberto vem parar aqui. Sem você mexer um dedo."
L.EMPTY_OPEN_HEAD = "Nada a resolver."
L.EMPTY_JOURNAL_HEAD = "Nenhuma morte ainda."
L.EMPTY_JOURNAL_SUB = "Respeito. Ou mentira."
L.EMPTY_NOGUILD_HEAD = "Sem guilda."
L.EMPTY_NOGUILD_SUB = "Dá para morrer sozinho também."
L.EMPTY_GUILDOFF_HEAD = "O livro da guilda está fechado."
L.EMPTY_GUILDOFF_SUB = "O compartilhamento está desligado. As Regras da casa sabem onde."
L.EMPTY_GUILDNIL_HEAD = "Nenhum sinal da guilda ainda."
L.EMPTY_GUILDNIL_SUB = "O seu livro sai assim que um membro da guilda tiver DeathNote."
L.EMPTY_GUILDQUIET_HEAD = "Nada no livro da guilda ainda."
L.EMPTY_GUILDQUIET_SUB = "A sua guilda teve paz até agora."
L.EMPTY_FRIENDSOFF_HEAD = "O livro dos amigos está fechado."
L.EMPTY_FRIENDSOFF_SUB = "O compartilhamento com amigos está desligado. As Regras da casa sabem onde."
L.EMPTY_FRIENDSNIL_HEAD = "Nenhum sinal de amigos com DeathNote ainda."
L.EMPTY_FRIENDSNIL_SUB = "O seu livro sai assim que um amigo tiver DeathNote."
L.EMPTY_FRIENDSQUIET_HEAD = "Nada dos seus amigos ainda."
L.EMPTY_FRIENDSQUIET_SUB = "Os seus amigos tiveram paz até agora."
L.EMPTY_NOBODY_HEAD = "Sem guilda, sem amigos."
L.EMPTY_NOBODY_SUB = "Dá para morrer sozinho também."
L.EMPTY_NOBODY_HINT = "Quando membros da sua guilda ou amigos da sua lista de amigos tiverem DeathNote, esta página mostra o que acontece com eles."
L.EMPTY_SHAREDNIL_HEAD = "Nenhum sinal de ninguém com DeathNote ainda."
L.EMPTY_SHAREDNIL_SUB = "O seu livro sai assim que membros da guilda ou amigos tiverem DeathNote."
L.EMPTY_SHAREDQUIET_HEAD = "Nada aqui ainda."
L.EMPTY_SHAREDQUIET_SUB = "Guilda e amigos tiveram paz até agora."
L.EMPTY_HUNT_HEAD = "A lista de caça está vazia."
L.EMPTY_HUNT_SUB = "No cartaz: Abrir a caçada."
L.EMPTY_HUNT_HINT = "Ou no chat: /dn hunt Nome Sobrenome. Todos da sua guilda e os seus amigos veem."
L.EMPTY_SEARCH_HEAD = "Nenhum resultado."
L.EMPTY_SEARCH_SUB = "Enter inclui o nome no livro."
L.EMPTY_SEARCHRO_HEAD = "Nenhum resultado."
L.EMPTY_SEARCHRO_SUB = "Às vezes ajuda escrever de outro jeito."
-- How it works (help page, "?" button): label left (spaced capitals), paragraph right -------------
L.MANUAL_BOOK_HEAD = "O LIVRO"  -- [max 12]
L.MANUAL_BOOK = "Quem matar você no mundo aberto é anotado automaticamente. Um clique na mensagem depois da sua morte abre a página do assassino."
L.MANUAL_WANTED_HEAD = "PROCURADOS"  -- [max 12]
L.MANUAL_WANTED = "Os seus assassinos, o pior primeiro. Um clique mostra o cartaz com crimes e nota. Os perdoados ficam riscados no fim."
L.MANUAL_UNSOLVED_HEAD = "A RESOLVER"  -- [max 13]
L.MANUAL_UNSOLVED = "Quando não ficou claro quem foi, o caso espera aqui. Um clique num nome define o assassino."
L.MANUAL_ALERT_HEAD = "ALARME"  -- [max 12]
L.MANUAL_ALERT = "Quando um assassino aparece como placa de identificação, alvo ou sob o mouse, o livro avisa. Um clique o seleciona como alvo, em combate só depois."
L.MANUAL_ADD_HEAD = "INCLUIR"  -- [max 12]
L.MANUAL_ADD = "Digite um nome no campo de busca, Enter. Botão direito numa linha: anotar vingança, perdoar, riscar."
L.MANUAL_GUILD_HEAD = "GUILDA"  -- [max 12]
L.MANUAL_GUILD = "Membros da guilda e amigos com DeathNote veem as suas mortes confirmadas e entradas à mão. Cartaz ou /dn hunt Nome: abrir a caçada. Clique na recompensa: ofereça a sua, uma promessa acertada entre vocês."
L.MANUAL_SHARE_HEAD = "PASSAR"  -- [max 12]
L.MANUAL_SHARE = "Regras da casa, Salvar cópia: um texto para copiar, para todos sem DeathNote."
L.MANUAL_QUIET_HEAD = "SILÊNCIO"  -- [max 12]
L.MANUAL_QUIET = "Em masmorras e campos de batalha o alarme fica quieto. Fora isso: clique do meio no botão do minimapa ou /dn quiet."
-- Questions before something is destroyed (game dialog) -------------------------------------------
L.CONFIRM_DELETE = "Riscar mesmo {name} do livro?\nTodos os crimes e a nota serão perdidos."
L.CONFIRM_DELETE_OK = "Riscar"  -- [max 14]
L.CONFIRM_GUILD_CLEAR = "Limpar o livro da guilda neste computador?\nA lista de caça dele vai junto, as suas próprias ordens ficam.\nO seu próprio livro fica como está."
L.CONFIRM_GUILD_CLEAR_OK = "Limpar"  -- [max 14]
L.CONFIRM_CANCEL = "Cancelar"  -- [max 14]
-- Poster: bounty (number with GOLD/SILVER) and number format --------------------------------------
L.BOUNTY_GOLD = "{count} OURO"  -- [max 14]
L.BOUNTY_SILVER = "{count} PRATA"  -- [max 14]
L.THOUSANDS_SEP = "."
-- Actions on a poster and in the right-click menu (black buttons, 104 px / menu 148 px) -----------
L.ACT_CONFIRM = "Confirmar"  -- [max 19]
L.ACT_DISMISS = "Descartar"  -- [max 19]
L.ACT_HUNT_AGAIN = "Revogar perdão"  -- [max 19]
L.ACT_REVENGE = "Anotar vingança"  -- [max 19]
L.ACT_PARDON = "Perdoar"  -- [max 19]
L.ACT_STRIKE = "Riscar"  -- [max 19]
L.ACT_OPEN_OWN = "Abrir no livro"  -- [max 19]
L.ACT_ADOPT = "Para o meu livro"  -- [max 19]
L.ACT_CALLOFF = "Suspender caçada"  -- [max 19]
L.ACT_RELEASE = "Abrir a caçada"  -- [max 19]
-- Rows of the list (left page): sub line under the name and the mark at the right -----------------
L.ROW_SEEN = "avistamento: {time}"
L.ROW_NOT_SEEN = "nenhum avistamento"
L.ROW_PARDONED = "perdão concedido"
L.ROW_SUSPECT = "Suspeita"
L.MARK_REVENGE = "VINGANÇA {times}"  -- [max 16]
L.ROW_KILLER_UNCLEAR = "Assassino incerto"
L.MARK_CANDIDATES = "{count} {count|CANDIDATO|CANDIDATOS}"  -- [max 16]
L.MARK_SUSPECT = "SUSPEITA"  -- [max 16]
L.ROW_NO_PLAYER = "Nenhum jogador"
L.ROW_UNCLEAR = "Causa incerta"
L.MARK_NOT_COUNTED = "NÃO CONTA"  -- [max 16]
L.ROW_LISTED_BY = "incluído por {names}"
L.ROW_GKILLED = "matou {kills}×"
L.ROW_VICTIMS = "{count} {count|vítima|vítimas}"
L.ROW_LAST = "última: {text}"
L.MARK_IN_BOOK = "NO LIVRO"  -- [max 16]
L.MEMBER_KILLERS = "{count} {count|assassino|assassinos}"  -- [max 14]
L.MEMBER_DEATHS = "{count} {count|morte|mortes}"  -- [max 12]
L.MEMBER_LISTED = "{count} à mão"  -- [max 14]
L.MEMBER_ME = "o que os outros veem de você"
L.MEMBER_NOTHING = "nada compartilhado ainda"
L.MEMBER_LAST_DIED = "última morte {time}"
L.MARK_YOU = "você"  -- [max 16]
L.MARK_FRIEND = "AMIGO"  -- [max 16]
L.MARK_BOTH = "GUILDA, AMIGO"  -- [max 20]
L.MARK_TAKEN_DOWN = "ABATIDO {times}"  -- [max 18]
-- Wanted poster (right page): labels in letter-spaced capitals, fact lines, bounty ----------------
L.POSTER_DOA = "VIVO OU MORTO"  -- [max 24]
L.BOOK_TITLE = "DeathNote"
L.POSTER_HEAD = "WANTED"
L.POSTER_DEEDS = "CRIMES"  -- [max 14]
L.POSTER_NOTE = "NOTA"  -- [max 8]
L.POSTER_BOUNTY = "RECOMPENSA"  -- [max 12]
L.ROLE_ASSIST = "cúmplice"  -- [max 14]
L.ROLE_SUSPECT = "suspeita"  -- [max 14]
L.POSTER_LEVEL = "Nível {level}"
L.POSTER_GUILD = "Guilda: {guild}"
L.POSTER_LAST_SEEN = "Último avistamento: {time}"
L.POSTER_NOT_SEEN = "Nenhum avistamento"
L.POSTER_ONLY_SUSPECT = "Só suspeita, nenhum crime comprovado."
L.POSTER_NO_DEEDS = "Nenhum crime anotado."
L.TIP_LISTED_AT = "Incluído em {time}"
-- Tooltips of deeds and cases ---------------------------------------------------------------------
L.TIP_CAUSE = "Causa da morte: {spell}"
L.TIP_VICTIM = "Vítima: {name}"
L.TIP_VICTIM_LEVEL = "Vítima: {name} (nível {level})"
L.TIP_KILLER_LEVEL = "Nível do assassino: {level}"
L.TIP_ASSISTS = "Cúmplices: {names}"
L.TIP_ROLE_ASSIST = "Cúmplice, não deu o golpe fatal."
L.TIP_ROLE_SUSPECT = "Só suspeita, nada comprovado."
L.MORE_LINE = "… e mais {count}"
-- Guild book poster -------------------------------------------------------------------------------
L.POSTER_GUILDBOOK = "LIVRO DA GUILDA"  -- [max 24]
L.POSTER_IN_BOOK_OF = "No livro de: {names}"
L.POSTER_SEEN = "Avistamento: {time}"
L.POSTER_SEEN_BY = "Avistamento: {time}, por {name}"
L.TIP_IN_BOOK_OF = "No livro de"
L.POSTER_REMARK = "OBSERVAÇÃO"  -- [max 12]
L.POSTER_BY_HAND = "INCLUÍDO À MÃO"  -- [max 22]
L.POSTER_VICTIMS = "VÍTIMAS"  -- [max 12]
L.POSTER_LISTED = "INCLUÍDO POR"  -- [max 14]
L.POSTER_LISTED_EMPTY = "Incluído à mão."
L.POSTER_NO_DEEDS_SENT = "Nenhum crime repassado."
L.POSTER_NONE_KNOWN = "nenhuma conhecida"
L.POSTER_NO_NAMES = "nenhum nome repassado"
L.TIP_VICTIMS = "Vítimas"
-- Hit List poster ---------------------------------------------------------------------------------
L.TIP_RELEASED_AT = "Ordem de {time}"
L.HUNT_REASON = "Motivo: {reason}"
L.POSTER_HUNTLIST = "LISTA DE CAÇA"  -- [max 24]
L.POSTER_RELEASED_N = "caçada aberta {times}"
L.POSTER_RELEASED_BY = "Ordem de {names}"
L.POSTER_TAKEN_DOWN = "ABATES"  -- [max 12]
L.POSTER_NOT_YET = "AINDA NÃO"  -- [max 18]
L.POSTER_CALLS = "ORDENS"  -- [max 14]
L.POSTER_NOBODY_LEFT = "Mais ninguém."
L.POSTER_LAST = "ÚLTIMO"  -- [max 13]
L.POSTER_TAKEN_BY = "vítima de {name}, {time}"
L.POSTER_TAKEN_NOBODY = "ainda à solta"
-- Death file (Death Log and Unsolved, right page) -------------------------------------------------
L.CASE_HEAD = "Óbito"  -- [max 20]
L.CASE_ASSISTS = "CÚMPLICES"  -- [max 24]
L.CASE_PICK = "DEFINIR O ASSASSINO"  -- [max 24]
L.CASE_NOT_COUNTED = "Não conta (instância, campo de batalha ou duelo)"
L.CASE_KILLER = "ASSASSINO"  -- [max 24]
L.CASE_KILLER_SUSPECT = "ASSASSINO (SUSPEITA)"  -- [max 24]
L.CASE_CLICK_NAME = "Clique no nome para abrir o cartaz."
L.CASE_GONE = "Não está mais no livro."
L.CASE_KILLER_UNCLEAR = "ASSASSINO INCERTO"  -- [max 24]
L.CASE_SEVERAL = "Vários podem ter sido. Qual nome vai para o livro?"
L.CASE_NOBODY = "Ninguém pode ter sido."
L.CASE_HOW = "O QUE ACONTECEU"  -- [max 24]
L.CASE_PVE = "Um monstro ou o próprio mundo. Não é caso para o livro."
L.CASE_UNCLEAR = "Incerto"
L.CASE_DARK = "A perícia está tateando no escuro."
L.TIP_MORE_CANDIDATES = "Mais candidatos"
L.CASE_SOURCE_SUSPECT = "Suspeita: tinha você como alvo pouco antes da sua morte."
-- House Rules, check boxes (label 280 px, Friz 11, one line) --------------------------------------
L.OPT_TOOLTIP = "Linha no tooltip dos assassinos"  -- [max 44]
L.OPT_MINIMAP = "Mostrar o botão do minimapa"  -- [max 44]
L.OPT_ALERT = "Alarme quando um assassino aparecer"  -- [max 44]
L.OPT_FLASH = "Piscar a borda da tela em vermelho"  -- [max 44]
L.OPT_SUSPECTS = "Avisar também sobre suspeitos"  -- [max 44]
L.OPT_DEATHMSG = "Mensagem depois de uma morte PvP"  -- [max 44]
L.OPT_G_SHARE = "Compartilhar as minhas mortes"  -- [max 44]
L.OPT_G_SHAREMANUAL = "Compartilhar entradas à mão"  -- [max 44]
L.OPT_G_RECEIVE = "Receber o livro da guilda"  -- [max 44]
L.OPT_G_ALERT = "Avisar sobre assassinos do livro da guilda"  -- [max 44]
L.OPT_G_ALERTLISTED = "Avisar também sobre entradas à mão"  -- [max 44]
L.OPT_G_ANNOUNCE = "Avisar quando matarem um membro da guilda"  -- [max 44]
L.OPT_G_SIGHTINGS = "Compartilhar avistamentos"  -- [max 44]
L.OPT_F_SHARE = "Compartilhar com a guilda"  -- [max 44]
L.OPT_F_FRIENDS = "Compartilhar com amigos"  -- [max 44]
L.OPT_F_ALERT = "Avisar sobre assassinos de guilda e amigos"  -- [max 44]
L.OPT_F_ALERTHUNT = "Avisar sobre alvos da lista de caça"  -- [max 44]
L.OPT_F_ANNOUNCE = "Avisar quando morrerem membros ou amigos"  -- [max 44]
L.OPT_F_SIGHTINGS = "Avistamentos para guilda e amigos"  -- [max 44]
-- House Rules: sheets, steppers, sections, buttons, hints -----------------------------------------
L.SHEET_GUILD = "Guilda"  -- [max 14]
L.SET_BOOK_SIZE = "Tamanho do livro"  -- [max 34]
L.SET_LANGUAGE = "Idioma"  -- [max 16]
L.SET_LANG_AUTO = "Automático"  -- [max 16]
L.SET_LANG_RELOAD_HINT = "Vale depois de recarregar."  -- [max 28]
L.SET_LANG_RELOAD = "Recarregar agora"  -- [max 22]
L.SET_SEC_SHARE = "PASSAR ADIANTE"  -- [max 24]
L.IO_EXPORT = "Salvar cópia"  -- [max 17]
L.IO_IMPORT = "Importar livro"  -- [max 17]
L.SET_HINT_BOOK = "Salvar cópia dá o livro como texto: para guardar ou passar para gente de fora da guilda. Importar mescla e não sobrescreve nada."
L.SET_SEC_SOUND = "SOM"  -- [max 24]
L.SET_SOUND = "Som"  -- [max 22]
L.SET_VOLUME = "Volume"  -- [max 22]
L.SET_CHANNEL = "Canal"  -- [max 12]
L.SET_SEC_THRESHOLD = "LIMITE"  -- [max 24]
L.SET_COOLDOWN = "Recarga por assassino"  -- [max 34]
L.SET_MINKILLS = "Alarme após tantas mortes por ele"  -- [max 34]
L.SET_ALERT_SIZE = "Tamanho do alarme"  -- [max 34]
L.SET_TEST_ALERT = "Testar alarme"  -- [max 17]
L.SET_G_MINKILLS = "Aviso da guilda após tantas mortes"  -- [max 34]
L.SET_F_MINKILLS = "Aviso após tantas mortes"  -- [max 34]
L.SET_SEC_STATUS = "ESTADO"  -- [max 24]
L.SET_SEC_SHARING = "COMPARTILHAR"
L.SET_SEC_WARN = "ALARME"
L.SET_MORE = "Mais"
L.SET_GUILD_CLEAR = "Limpar livro da guilda"  -- [max 26]
L.SET_HINT_GUILD = "Só a sua própria guilda recebe algo. O que vem de lá fica separado do seu livro até você mesmo copiar."
L.SET_HINT_FRIENDS = "Só guilda e amigos com DeathNote recebem algo."
L.BTN_BACK = "Voltar"  -- [max 17]
-- Sync button and guild tooltip (left page, bottom) -----------------------------------------------
L.SYNC_BUTTON = "Sincronizar"  -- [max 14]
L.SYNC_AGAIN_IN = "aguarde {seconds} s"  -- [max 16]
L.TIP_FRIENDS = "Amigos"
L.TIP_GUILD_NAME = "Guilda {guild}"
L.TIP_MATES_WITH = "Membros da guilda com DeathNote:"
L.TIP_NO_MATE = "Nenhum sinal de membros com DeathNote ainda."
L.TIP_FRIENDS_WITH = "Amigos com DeathNote:"
L.TIP_SHARED = "Compartilhado: as suas mortes confirmadas, entradas à mão e as suas ordens de caçada."
L.TIP_NOT_SHARED = "Não compartilhado: notas, suspeitas, perdoados, entradas importadas."
-- Back up / import page ---------------------------------------------------------------------------
L.IO_GO = "Importar"  -- [max 17]
L.IO_DONE = "Importado: {new} novos, {merged} mesclados."
L.IO_FAILED = "Não deu certo."
L.IO_SMALL = "Só o básico"  -- [max 17]
L.IO_ALL = "Mostrar tudo"  -- [max 17]
L.IO_MSG_FULL = "Livro inteiro com crimes ({size})."
L.IO_MSG_SHORT = "Só nomes e contagens ({size}). Com crimes: {full}."
L.IO_MSG_BIG = "Livro grande ({size}): selecionar e copiar demora um pouco."
L.IO_HELP_EXPORT = "O texto está selecionado: Ctrl+C copia. Guarde ou passe para os amigos."
L.IO_HELP_IMPORT = "Cole um texto salvo com Ctrl+V, depois Importar. Nada é sobrescrito."
-- Sheet Put on the hit list (right page) ----------------------------------------------------------
L.REL_HINT_ALL = "Todos da sua guilda e os seus amigos com DeathNote veem o motivo."
L.REL_HINT_GUILD = "Todos da sua guilda com DeathNote veem o motivo."
L.REL_HINT_FRIENDS = "Os seus amigos com DeathNote veem o motivo."
L.REL_HEAD = "Abrir a caçada"  -- [max 24]
L.REL_FOR = "PARA"  -- [max 6]
L.REL_REASON = "MOTIVO"  -- [max 8]
L.REL_HINT2 = "A sua nota fica com você. Só você pode retirar a sua própria ordem."
L.REL_GO = "Dar a ordem"  -- [max 17]
L.REL_NONE = "Sem guilda, e o compartilhamento com amigos está desligado."
L.REL_CAP = "No máximo {own} ordens suas e {max} alvos por lista."
L.REL_FAILED = "Não dá para abrir a caçada agora."
-- House Rules: values and hints filled at runtime -------------------------------------------------
L.SET_SECONDS = "{seconds} s"  -- [max 7]
L.SET_HINT_SILENT = "Sem som: o alarme só aparece."
L.SET_HINT_BUILTIN = "O volume deste som segue o canal nas opções do jogo."
L.SET_HINT_LEVELS = "Cinco níveis, do baixo ao alto. Além disso vale o controle do canal nas opções do jogo."
-- Cover tabs and the left page head (search, views, source, sort) ---------------------------------
L.TAB_GUILD_FRIENDS = "Guilda e amigos"  -- [max 18]
L.TIP_HELP_BUTTON = "Como o livro funciona"
L.VIEW_HUNT = "Lista de caça"  -- [max 13]
L.VIEW_BY_KILLER = "Por assassino"  -- [max 13]
L.VIEW_BY_MATE = "Por membro"  -- [max 13]
L.SRC_ALL = "Todos"  -- [max 12]
L.SRC_GUILD = "Guilda"  -- [max 12]
L.SRC_FRIENDS = "Amigos"  -- [max 12]
L.SORT_HIDE_PARDONED = "Ocultar perdoados"  -- [max 24]
L.SORT_SHOW_PARDONED = "Mostrar perdoados"  -- [max 24]
L.SEARCH_ADD = "Buscar ou incluir …"  -- [max 26]
L.SEARCH_SHORT = "Buscar …"  -- [max 10]
L.SEARCH_KILLER = "Achar assassino"  -- [max 15]
L.SEARCH_JOURNAL = "Assassino ou lugar …"  -- [max 26]
L.TIP_COLLAPSE_ALL = "Recolher tudo"
L.TIP_EXPAND_ALL = "Expandir tudo"
L.STATUS_NO_PLATES = "Placas de identificação inimigas desligadas: o alarme só vê alvo e mouse."
-- Minimap button (tooltip and chat line) ----------------------------------------------------------
L.MM_WANTED = "{count} {count|procurado|procurados}"
L.MM_UNSOLVED = "{count} a resolver"
L.MM_ALERT_OFF = "Alarme desligado (clique do meio)"
L.MM_CLICK = "Clique: livro · Botão direito: Regras da casa"
L.MM_MIDDLE = "Clique do meio: alarme liga/desliga"
L.MM_DRAG = "Arrastar: mover pela borda do minimapa"
L.MM_CHAT_ALERT_ON = "Alarme ligado."
L.MM_CHAT_ALERT_OFF = "Alarme desligado."
-- Stamps without burnt-in text (all languages but German; German keeps the pictures) --------------
L.STAMP_GUILD_NR1 = "INIMIGO Nº 1 DA GUILDA"  -- [max 25]
L.STAMP_HUNT = "CAÇADA ABERTA"  -- [max 20]
-- Identity, hit list, alarm level, expiry (1.2.0) -----------------------------------------------
L.FRIENDS_IMPOSTOR = "{name} se passou pelo seu amigo {friend}: recusado."
L.FRIENDS_SHORT_IMPOSTOR = "Estranho recusado"  -- [max 22]
L.ALERT_LEVEL = "Nível {level}"  -- [max 12]
L.ALERT_LEVEL_LAST = "último nível {level}"  -- [max 20]
L.ALERT_LEVEL_UNKNOWN = "Nível ??"  -- [max 12]
L.ALERT_LINE_HUNT = "{text} · na lista de caça ({names})"
L.BANNER_NEW_HUNTS = "{count} {count|novo alvo|novos alvos}"  -- [max 24]
L.BANNER_NEW_HUNTS_LINE = "novas entradas na lista de caça"
L.OPT_F_ANNOUNCEHUNT = "Avisar da lista de caça: novos e abatidos"  -- [max 44]
L.SET_HUNT_EXPIRE = "As ordens expiram após"  -- [max 30]
L.SET_EXPIRE_NEVER = "Nunca"  -- [max 8]
L.SET_EXPIRE_DAYS = "{count} {count|dia|dias}"  -- [max 10]
L.SET_FRIENDS_CLEAR = "Limpar livro de amigos"  -- [max 26]
L.CONFIRM_FRIENDS_CLEAR = "Limpar o livro dos amigos neste computador?\nA lista de caça dele vai junto, as suas próprias ordens ficam."
L.CONFIRM_CALLOFF_ALL = "Suspender todas as suas ordens na lista de caça?\nGuilda e amigos vão sabendo aos poucos."
L.CONFIRM_CALLOFF_ALL_OK = "Suspender tudo"  -- [max 14]
L.ACT_CALLOFF_ALL = "Suspender minhas ordens"  -- [max 24]
L.ACT_HUNT_HIDE = "Ocultar para mim"  -- [max 19]
L.ACT_HUNT_SHOW = "Mostrar de novo"  -- [max 19]
L.HUNT_ROW_HIDDEN = "invisível para você"
L.HUNT_ROW_CALLS = "{count} {count|ordem|ordens}: {names}"
L.POSTER_ON_HUNTLIST = "Na lista de caça ({names})"
L.REL_SELF = "Você não pode se colocar na lista de caça."
L.REL_MATE = "É gente sua (guilda ou amigos com DeathNote)."
-- Friends listed without surname: which full name is behind the entry (1.2.0) ------------------------
L.FRIENDS_CONFLICT = "Quem é seu amigo {friend}: {a} ou {b}? Escolha."
L.FRIENDS_SHORT_CONFLICT = "Amigo incerto"  -- [max 22]
L.CHAT_FRIENDS_CONFLICT = "Dois jogadores dizem ser seu amigo {friend}: {a} e {b}. Até você escolher, o livro não aceita nada de nenhum dos dois. Guilda e amigos, visão Por membro: botão direito no nome."
L.MEMBER_CONFLICT = "Botão direito: é seu amigo?"  -- [max 40]
L.ACT_TIE_MINE = "Meu amigo: {name}"  -- [max 24]
L.ACT_TIE_LOOSE = "Desvincular"  -- [max 14]
L.CONFIRM_TIE_LOOSE = "Desvincular {name} da sua lista de amigos?\nO que esse nome trouxe para o livro dos amigos será apagado; a próxima mensagem com esse nome vincula de novo."
L.CHAT_FRIENDS_TIES = "Nomes completos vinculados (* = primeiro contato, ainda não confirmado): {list}"
-- Bounty, revenge taken back, avenged for you (1.2.1) ---------------------------------------------
L.HELP_BOUNTY = "/dn bounty <Nome [Sobrenome]> <ouro>  oferecer sua própria recompensa (sem ouro: retirar)"
L.CHAT_WHO_BOUNTY = "Por quem? /dn bounty <Nome> <ouro>"
L.CHAT_BOUNTY_SET = "{name}: você ofereceu {gold} de ouro de recompensa. Guilda e amigos com DeathNote veem."
L.CHAT_BOUNTY_OFF = "{name}: sua recompensa foi retirada."
L.CHAT_BOUNTY_NONE = "Você não ofereceu nenhuma recompensa por {name}."
L.CHAT_BOUNTY_BAD = "Recompensa: um número inteiro de ouro, de 1 a 99999 (0 retira)."
L.CHAT_BOUNTY_CAP = "Sem recompensa: no máximo {count} suas."
L.CHAT_BOUNTY_OURS = "Nenhuma recompensa por você ou pelos seus (guilda ou amigos com DeathNote)."
L.ACT_BOUNTY = "Oferecer recompensa"  -- [max 24]
L.ACT_UNDO = "Desfazer"  -- [max 19]
L.ACT_REVENGE_TAKE = "Tirar uma vingança"  -- [max 24]
L.POSTER_BOUNTY_MINE = "{gold}, oferecida por você"
L.POSTER_BOUNTY_BY = "{gold}, oferecida por {name}"
L.POSTER_BOUNTY_MANY = "Recompensa {gold}: {names}"
L.POSTER_AVENGED = "Vingado por {names}"
L.ROW_AVENGED = "vingado {times}"
L.BOUNTY_TIP_HEAD = "Sua própria recompensa, em ouro"
L.BOUNTY_TIP_RULES = "Um número inteiro, de 1 a 99999. Vazio ou 0: volta ao valor do livro. Enter confirma, Esc cancela."
L.BOUNTY_TIP_PROMISE = "Guilda e amigos com DeathNote veem. É só uma promessa: o acerto é entre vocês."
L.BOUNTY_TIP_CLICK = "Clique: oferecer sua recompensa"
L.CHAT_AVENGED = "{name} abateu {killer} por você."
L.NAMES_PLUS = "{name} +{count}"
L.CHAT_BOUNTY_SET_ALONE = "{name}: você ofereceu {gold} de ouro de recompensa."
L.CHAT_BOUNTY_UNKNOWN = "{name} não está em nenhum dos seus livros. Recompensa só vale para um nome de um livro, como o jogo mostra: nome e sobrenome."
L.CHAT_BOUNTY_LIST = "Suas recompensas ({count} de {max}): {list}"
L.CHAT_BOUNTY_LIST_NONE = "Você não ofereceu nenhuma recompensa."
-- <<< BOOK
-- >>> REPUTE (1.3.0) -----------------------------------------------------------------------------------------------
L.REPUTE_LINE = "Patente {tier} · Caminho: {path}"  -- [max 32]
L.PATH_R = "Infâmia"  -- [max 16]
L.PATH_E = "Honra"  -- [max 16]
L.PATH_J = "Caça"  -- [max 16]
L.PATH_S = "Proteção"  -- [max 16]
L.PATH_NONE = "em branco"  -- [max 16]
-- <<< REPUTE
-- >>> ALARM (1.3.0) -------------------------------------------------------------------------------------------------
L.ALERT_TITLE_VICTIM = "GUARDA RANCOR?"  -- [max 30]
L.ALERT_LINE_VICTIM = "placar {score} · morto por você, última vez {time}"  -- [max 56]
L.ALERT_LINE_STANDING = "{text} · placar {score}"
L.ALERT_LINE_STANDING_EVEN = "{text} · placar {score}, quites"
L.ALERT_LINE_STANDING_AHEAD = "{text} · placar {score}, com juros"
-- <<< ALARM
-- >>> START (1.3.0) -------------------------------------------------------------------------------------------------
L.SET_THEME = "Capa"  -- [max 16]
L.START_HINT = "Dá para mudar os dois depois nas Regras da casa."  -- [max 60]
L.START_GO = "Vamos"  -- [max 16]
L.START_CLOSE_TIP = "Deixar como está"  -- [max 32]
L.CHAT_THEME_NEWS = "Novidade: o livro agora tem outras capas. Regras da casa, folha Livro, ou /dn theme."
L.HELP_START = "/dn start  abrir de novo a janela inicial (idioma e capa)"
-- <<< START
-- >>> RECORD (1.3.0) -----------------------------------------------------------------------------------------------
L.TAB_RECORD = "Ficha criminal"  -- [max 16]
L.STAMP_QUITT = "QUITES"  -- [max 16]
L.STAMP_OVERPAID = "COM JUROS"  -- [max 16]
L.STAMP_NR1_DOWN = "INIMIGO Nº 1 ABATIDO"  -- [max 24]
L.STATE_OPEN = "aberto"  -- [max 16]
L.STATE_EVEN = "quites"  -- [max 16]
L.STATE_AHEAD = "com juros"  -- [max 16]
L.STATE_VICTIM = "fora do livro"  -- [max 24]
L.STAND_LINE = "Placar {score}"
L.STAND_TIP = "você {mine}, ele {his}"
L.TIP_IN_RECORD = "NA FICHA:"
L.TIP_RECORD_LINE = "morto por você {times}, última vez {time}"
L.RECORD_HEAD = "Sua ficha"  -- [max 20]
L.RECORD_LOG_HEAD = "Últimos abates"  -- [max 20]
L.RECORD_NEXT = "faltam {points} para {rank}"
L.RECORD_TOP = "Patente máxima alcançada."
L.RECORD_BAR_TIP = "{total} de {goal} pontos"
L.RECORD_NEEDLE_LOW = "impiedoso"  -- [max 12]
L.RECORD_NEEDLE_HIGH = "honrado"  -- [max 12]
L.RECORD_NEEDLE_TIP = "A agulha: honra e proteção contra infâmia. A caça não a move."
L.RECORD_KILLS = "Abates: {kills} · Vítimas: {victims}"
L.RECORD_BEST = "Recordes: {list}"
L.RECORD_BEST_GAP = "+{count} {count|nível|níveis}"
L.RECORD_BEST_STREAK = "sequência de {count}"
L.RECORD_BEST_QUICK = "vingança mais rápida {time}"
L.DUR_SECONDS = "{count} s"
L.DUR_MINUTES = "{count} min"
L.DUR_HOURS = "{count} h"
L.RECORD_AWARDS = "CONDECORAÇÕES"  -- [max 14]
L.RECORD_AWARD_AT = "concedida em {time}"
L.RECORD_AWARD_OPEN = "ainda não concedida"
L.RECORD_MORE = "Ver mais"  -- [max 19]
L.RECORD_BACK = "Voltar à ficha"  -- [max 19]
L.RECORD_CLEAR = "Limpar a ficha"  -- [max 26]
L.CONFIRM_RECORD_CLEAR = "Limpar a ficha criminal?\nTodas as vítimas e a lista dos últimos abates somem. Patente, pontos e condecorações ficam."
L.CONFIRM_RECORD_CLEAR_OK = "Limpar"  -- [max 14]
L.CONFIRM_VICTIM_STRIKE = "Riscar {name} da ficha criminal?\nOs pontos ganhos ficam."
L.ACT_VICTIM_STRIKE = "Riscar da ficha"  -- [max 26]
L.VICTIM_KILLED = "morto por você {times}"
L.VICTIM_POINTS = "Pontos ganhos: {points}"
L.VICTIM_SCENE = "Cena do crime: {zone}, {time}"
L.VICTIM_KILLS_LABEL = "SEUS ABATES"  -- [max 14]
L.KILL_TAG_REVENGE = "vingança"  -- [max 14]
L.KILL_TAG_KICK = "chute no caído"  -- [max 14]
L.KILL_TAG_GROUP = "grupo"  -- [max 14]
L.KILL_WITH_GROUP = "Com o grupo."
L.BAND_GRAU = "cinza"  -- [max 12]
L.BAND_GRUEN = "verde"  -- [max 12]
L.BAND_GELB = "amarelo"  -- [max 12]
L.BAND_ORANGE = "laranja"  -- [max 12]
L.BAND_ROT = "vermelho"  -- [max 12]
L.BAND_SCHAEDEL = "caveira"  -- [max 12]
L.BAND_UNBEKANNT = "desconhecido"  -- [max 12]
L.RECORD_POINTS = "+{points} {path}"
L.RECORD_NO_POINTS = "nenhum ponto"
L.RECORD_BANDS = "Por cor de nível"
L.TIP_PATH_R = "Infâmia: abates de cinzas e verdes."
L.TIP_PATH_E = "Honra: abates de jogadores do seu nível, vingança."
L.TIP_PATH_J = "Caça: abates de níveis mais altos, alvos da lista de caça, recompensas."
L.TIP_PATH_S = "Proteção: abates de jogadores que mataram membros da guilda ou amigos."
L.SORT_STATE = "Placar"  -- [max 14]
L.SORT_COUNT = "Abates"  -- [max 14]
L.SORT_POINTS = "Pontos"  -- [max 14]
L.CHAT_OWN_KILL = "Ficha: {name}, {level} ({band}). {points}."
L.CHAT_KILL_WITH_GROUP = "{line} {group}"
L.CHAT_PATH = "Novo caminho: {path}. Patente: {rank}."
L.BANNER_RANK = "NOVA PATENTE"  -- [max 24]
L.BANNER_AWARD = "CONDECORAÇÃO"  -- [max 24]
L.OPT_LEDGER = "Manter ficha criminal"  -- [max 44]
L.OPT_LEDGER_CHAT = "Avisar meus abates no chat"  -- [max 44]
L.OPT_VICTIMS = "Avisar quando uma vítima minha aparecer"  -- [max 44]
L.SET_SETTLED = "Alarme com a conta acertada"  -- [max 34]
L.SET_SETTLED_ALWAYS = "normal"  -- [max 10]
L.SET_SETTLED_QUIET = "silencioso"  -- [max 10]
L.SET_SETTLED_OFF = "nunca"  -- [max 10]
L.MANUAL_RECORD_HEAD = "FICHA CRIMINAL"  -- [max 14]
L.MANUAL_RECORD = "Seus próprios golpes finais em jogadores. O cartaz e a lista mostram o placar “você : ele”: aberto, quites ou com juros. A posição 1 está sempre em aberto. Abates rendem pontos para a sua patente."
L.POSTER_LAST_SEEN_IN = "Último avistamento: {zone}, {time}"
L.SHEET_RECORD = "Ficha"  -- [max 14]
L.EMPTY_RECORD_HEAD = "Ninguém ainda."
L.EMPTY_RECORD_SUB = "O jogador do outro lado que você matar vem parar aqui."
-- <<< RECORD
end)
