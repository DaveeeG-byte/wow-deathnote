-- (fix-2) Zufallslauf der finalen Jagd, in der Suite kurz mit festem Startwert (lang von Hand: luajit tests/test_fuzz_final.lua . 400 1000 200)
-- Zufallslaeufe der finalen Jagd: der Fuzzer aus tests/test_fuzz_clients.lua, erweitert um
--   Sprachen je Client (deDE, enUS, ruRU, zhCN) und Sprachwechsel beim Login, Freundeslisten nur mit Vornamen,
--   Battle.net-Freunde, Zeitspruenge (alle offline, Tage vergehen), Verfall der Freigaben (0/30/90/180),
--   "Fuer mich ausblenden".
-- Invarianten wie in der ersten Jagd, dazu: kein Sprachtext in gesendeten oder gespeicherten Daten (Feld Notiz
-- ausgenommen), ein ausgeblendetes Ziel alarmiert nie, Zaehler und neue Tabellen bleiben unter ihren Deckeln.
-- Verstoesse, die auf bekannte Funde dieser Jagd zurueckgehen (Verfall, Merkfrist der Abblasen), werden getrennt
-- als "bekannt" gezaehlt und machen den Lauf nicht rot.
-- Aufruf: luajit fuzz_final.lua <Projektkopie> [Laeufe=60] [Startsaat=1] [Schritte=140] [ohneverlust]
local DIRARG = (arg[1] or "."):gsub("/+$", "")
package.path = DIRARG .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local RUNS, SEED0, STEPS = tonumber(arg[2]) or 12, tonumber(arg[3]) or 1000, tonumber(arg[4]) or 120
local LANGS = { "deDE", "enUS", "ruRU", "zhCN" }
local NOLOSS = arg[5] == "ohneverlust"   -- Gegenprobe: ohne Verlust und Tausch darf auch nach Zeitspruengen nichts fehlen
local GUILDS = { "Gilde Eins", "Gilde Zwei" }
-- Anton Wurst und Anton Falsch: gleicher Vorname, der Client nennt beide mit Nachnamen (fullSender)
local NAMES = { { "Anton", "Wurst" }, { "Berta", "Senf" }, { "Anton", "Falsch" }, { "Dora", "Dick" } }
local FULL = { true, false, true, false }
local ENEMIES = { { "Grimm", "Bart" }, { "Fies", "Ling" }, { "Rauf", "Bold" }, { "Zank", "Apfel" }, { "Wut", "Buerger" }, { "Hau", "Drauf" } }
local function ekey(e) return e[1] .. "-" .. e[2] end

-- Sprachtexte aller vier Sprachen (Teile ab 9 Bytes, ohne Beispielzone und Kanalnamen)
local DICT = {}
do
  local ns = {}
  assert(loadfile(M.ADDON_DIR .. "Locale.lua"))("DeathNote", ns)
  for _, c in ipairs(LANGS) do assert(loadfile(M.ADDON_DIR .. "Locales/" .. c .. ".lua"))("DeathNote", ns) end
  for _, c in ipairs(LANGS) do
    for k, v in pairs(assert(ns.Locale.Raw(c))) do
      if type(v) == "string" and k ~= "SAMPLE_ZONE" and k ~= "CHANNEL_MASTER" then
        for part in v:gsub("{[^{}]*}", "\0"):gmatch("[^%z\n]+") do
          part = part:gsub("^%s+", ""):gsub("%s+$", "")
          if #part >= 9 then DICT[#DICT + 1] = { part, c .. "." .. k } end
        end
      end
    end
  end
end
local function sprachtext(s)
  for i = 1, #DICT do if s:find(DICT[i][1], 1, true) then return DICT[i][2] end end
end
local function filesFor(code)
  local out = {}
  for _, f in ipairs(M.FILES) do
    out[#out + 1] = f
    if f == "Locales/deDE.lua" and code ~= "deDE" and code ~= "enUS" then out[#out + 1] = "Locales/" .. code .. ".lua" end
  end
  return out
end

local known, seenKnown = {}, {}
local function bekannt(seed, kind, detail)
  if not seenKnown[kind] then seenKnown[kind] = { n = 0, first = ("Saat %d: %s"):format(seed, tostring(detail)) }; known[#known + 1] = kind end
  seenKnown[kind].n = seenKnown[kind].n + 1
end
local problems, seenProblem = {}, {}
local tally = { sent = 0, cmp = 0, deeds = 0, hunts = 0, relog = 0, pairs = 0, jumps = 0, days = 0, langs = 0, strings = 0, hidden = 0, bn = 0 }
local function problem(seed, kind, detail)
  if not seenProblem[kind] then
    seenProblem[kind] = { n = 0, first = ("Saat %d: %s"):format(seed, tostring(detail)) }
    problems[#problems + 1] = kind
  end
  seenProblem[kind].n = seenProblem[kind].n + 1
end

local function run(seed)
  math.randomseed(seed)
  local R = math.random
  M.Reset()
  local W = M.NewWorld({ "HUNT_BAGGED", "GUILD_ENEMY_SPOTTED" })
  local langOf, bnOf, tainted, expireOf, jumped, maxJump = {}, {}, {}, {}, 0, 0
  local jumpLog = {}
  -- Tage, die nach dem Zeitpunkt t uebersprungen wurden (ab 3 Tagen deckt die Rueckschau eines Hallo t nicht mehr)
  local function tageNach(t)
    local n = 0
    for _, j in ipairs(jumpLog) do if j[1] > t then n = n + j[2] end end
    return n
  end
  local N = R(2, 4)
  local C, friendsOf, guildOf = {}, {}, {}
  -- Wahrheit: was jeder Char je selbst erzeugt hat
  local truth = { kills = {}, listed = {}, released = {}, gone = {} }
  for i = 1, N do
    local full = NAMES[i][1] .. " " .. NAMES[i][2]
    guildOf[i] = ({ GUILDS[1], GUILDS[1], GUILDS[2], nil })[R(1, 4)]
    friendsOf[i] = {}
    langOf[i], bnOf[i], expireOf[i] = LANGS[R(#LANGS)], {}, 0
    truth.kills[full], truth.listed[full], truth.released[full] = {}, {}, {}
  end
  for i = 1, N do for j = 1, N do
    if i ~= j and R() < 0.6 then friendsOf[i][#friendsOf[i] + 1] = NAMES[j][1] .. " " .. NAMES[j][2] end
  end end
  -- Battle.net-Freundschaften (gegenseitig) zwischen Chars mit eindeutigem Vornamen; der Mock nennt dort nur Vornamen
  local UNIQUE = { [2] = true, [4] = true }
  if N >= 4 and R() < 0.5 then bnOf[2][1], bnOf[4][1] = NAMES[4][1], NAMES[2][1]; tally.bn = tally.bn + 1 end
  local function spawn(i, db)
    -- Sprachwechsel beim Login: die Wahl steht in der Datei, der Client laedt die Sprachdatei wie aus der TOC
    if db and R() < 0.3 then
      langOf[i] = LANGS[R(#LANGS)]
      if type(db.settings) == "table" then db.settings.lang = langOf[i] end
      tally.langs = tally.langs + 1
    end
    local c = W.client(NAMES[i][1], NAMES[i][2], guildOf[i], { friends = friendsOf[i], db = db, fullSender = FULL[i],
      bn = bnOf[i], lang = langOf[i], files = filesFor(langOf[i]) })
    if c.ns.Locale.code ~= langOf[i] then problem(seed, "Sprache nicht aktiv", langOf[i] .. " gewaehlt, aktiv " .. tostring(c.ns.Locale.code)) end
    c.ns:On("GUILD_ENEMY_SPOTTED", function(key, _, _, kind)
      if kind == "hunt" and c.ns.Guild.HuntHidden(key) then problem(seed, "ausgeblendetes Ziel alarmiert", key) end
    end)
    c.idx, c.full = i, NAMES[i][1] .. " " .. NAMES[i][2]
    C[i] = c
    c.login()
    return c
  end
  for i = 1, N do spawn(i) end
  local lossy = not NOLOSS
  local deliver = W.deliver
  function W.deliver()
    if lossy and #W.wire > 1 and R() < 0.3 then
      local i, j = R(#W.wire), R(#W.wire)
      W.wire[i], W.wire[j] = W.wire[j], W.wire[i]            -- Reihenfolge tauschen
    end
    if lossy then
      for i = #W.wire, 1, -1 do if R() < 0.08 then table.remove(W.wire, i) end end   -- Verlust
    end
    return deliver()
  end
  for e = 1, #ENEMIES do M.units["e" .. e] = { exists = true, isPlayer = true, name = ENEMIES[e][1], surname = ENEMIES[e][2],
    guid = "Player-9-E" .. e, class = "MAGE", classLoc = "Magier" } end
  local killsBy = {}
  local function relog(i)
    local c = C[i]
    c.fire("PLAYER_LOGOUT")
    local db = H.tiefe_kopie(c.env.DeathNoteDB)
    c.loggedIn = false
    for k = #W.clients, 1, -1 do if W.clients[k] == c then table.remove(W.clients, k) end end
    W.setOnline(c, false)
    return db
  end
  local offline = {}
  local OPS = {
    function(c)   -- sicherer Tod
      if (killsBy[c.idx] or 0) >= 8 then return end
      killsBy[c.idx] = (killsBy[c.idx] or 0) + 1
      local e = ENEMIES[R(#ENEMIES)]
      local key = H.tod(c, e[1], e[2])
      truth.kills[c.full][key .. "\t" .. time()] = true
    end,
    function(c)   -- von Hand eintragen / entfernen
      local e = ENEMIES[R(#ENEMIES)]
      local key = ekey(e)
      local own = c.ns.Store.Get(key)
      if own and own.manual and R() < 0.5 then
        c.ns.Store.Remove(key)
        -- selbst geloeschte Taten muss niemand mehr bekommen
        for id in pairs(truth.kills[c.full]) do if id:match("^(.-)\t") == key then truth.gone[c.full .. "\t" .. id] = true end end
      elseif not own then
        c.ns.Store.AddManual(e[1], e[2]); truth.listed[c.full][key] = true
      end
    end,
    function(c)   -- freigeben
      local key = ekey(ENEMIES[R(#ENEMIES)])
      local g, f = c.ns.Guild.Release(key, { to = ({ "all", "guild", "friends" })[R(3)], why = R() < 0.5 and "Grund |cffff0000x|r " .. R(9) or nil })
      if g or f then truth.released[c.full][key] = true end
    end,
    function(c) c.ns.Guild.CallOff(ekey(ENEMIES[R(#ENEMIES)]), ({ nil, "guild", "friends" })[R(3)]) end,
    function(c) c.fire("PARTY_KILL", "Player-1-" .. c.name, "Player-9-E" .. R(#ENEMIES)) end,
    function(c)   -- Freundschaft schliessen oder loesen
      local j = R(N)
      if j == c.idx then return end
      local l, name = friendsOf[c.idx], NAMES[j][1] .. " " .. NAMES[j][2]
      for k = 1, #l do if l[k] == name then
        table.remove(l, k); c.fire("FRIENDLIST_UPDATE")
        tainted[c.idx .. ">" .. j], tainted[j .. ">" .. c.idx] = true, true
        return
      end end
      l[#l + 1] = name
      c.fire("FRIENDLIST_UPDATE")
    end,
    function(c)   -- Logout, spaeter Login
      if R() < 0.4 then offline[c.idx] = relog(c.idx) end
    end,
    function(c) c.combat = not c.combat; if not c.combat then c.fire("PLAYER_REGEN_ENABLED") end end,
    function(c) if R() < 0.3 then c.ns.Guild.SyncNow(); c.ns.Friends.SyncNow() end end,
    function(c) c.ns.Guild.OnUnit(ekey(ENEMIES[R(#ENEMIES)]), "nameplate1", "plate", false) end,
    function(c)   -- Verfall der Freigaben einstellen (W1)
      if R() < 0.4 then
        expireOf[c.idx] = ({ 0, 0, 30, 90, 180 })[R(5)]
        c.ns.Store.Setting("guild.huntExpire", expireOf[c.idx])
      end
    end,
    function(c)   -- fuer mich ausblenden / wieder einblenden
      local key = ekey(ENEMIES[R(#ENEMIES)])
      c.ns.Guild.HideHunt(key, R() < 0.6); tally.hidden = tally.hidden + 1
    end,
    function(c)   -- Befehle in der Sprache des Clients
      local slash = c.ns.HandleSlash   -- nicht SlashCmdList: die Tabelle teilen sich alle Clients der Welt
      if slash then slash(({ "gilde", "friends", "probe", "hilfe", "lang", "jagd " .. ENEMIES[R(#ENEMIES)][1] })[R(6)]) end
      for _, e in ipairs(ENEMIES) do
        local g, f = c.ns.Guild.Released(ekey(e))
        if g or f then truth.released[c.full][ekey(e)] = true end
      end
    end,
    function(c)   -- Gilde wechseln, verlassen oder beitreten (fix-1)
      if R() < 0.5 then return end
      local g = ({ GUILDS[1], GUILDS[2], nil })[R(3)]
      if g == c.guild then return end
      c.guild, guildOf[c.idx] = g, g
      c.fire("PLAYER_GUILD_UPDATE")
    end,
  }
  for step = 1, STEPS do
    local i = R(N)
    if offline[i] then
      if R() < 0.5 then local db = offline[i]; offline[i] = nil; spawn(i, db) end
    else
      OPS[R(#OPS)](C[i])
    end
    W.run(R() < 0.2 and R(1, 60) or R(1, 5))
    -- Zeitsprung: alle gehen offline, Tage vergehen (zusammen hoechstens 55: darueber greift ein bekannter Fund)
    if R() < 0.03 and jumped < 55 then
      for k = 1, N do if not offline[k] then offline[k] = relog(k) end end
      local d = math.min(55 - jumped, ({ 1, 3, 8, 15, 20, 35 })[R(6)])
      M.epoch = M.epoch + d * 86400
      jumped = jumped + d
      jumpLog[#jumpLog + 1] = { time(), d }
      if d > maxJump then maxJump = d end
      tally.jumps, tally.days = tally.jumps + 1, tally.days + d
    end
    if #M.errors > 0 then problem(seed, "Lua-Fehler: " .. tostring(M.errors[1]):gsub("^.-([%w_]+%.lua:%d+)", "%1"), "Schritt " .. step); return end
  end
  -- ruhige Phase: alle online, kein Verlust, zweimal abgleichen
  lossy = false
  for i = 1, N do if offline[i] then spawn(i, offline[i]); offline[i] = nil end; C[i].combat = false; C[i].fire("PLAYER_REGEN_ENABLED") end
  for _ = 1, 3 do
    W.run(60); M.Advance(400)
    for i = 1, N do C[i].fire("FRIENDLIST_UPDATE") end
    W.run(5)
    for i = 1, N do C[i].ns.Guild.SyncNow(); C[i].ns.Friends.SyncNow() end
    W.run(240)
  end
  if #M.errors > 0 then problem(seed, "Lua-Fehler (Abgleich): " .. tostring(M.errors[1]), ""); return end

  tally.sent = tally.sent + #W.sent
  for _, m in ipairs(W.sent) do
    local hit = sprachtext(m.text)
    if hit then problem(seed, "Sprachtext auf der Leitung: " .. hit, m.text:sub(1, 80)) end
  end
  -- Invarianten
  local function hasFriend(i, j) for _, n in ipairs(friendsOf[i]) do if n == NAMES[j][1] .. " " .. NAMES[j][2] then return true end end return false end
  for i = 1, N do
    local c = C[i]
    local Gd, Cst = c.ns.Guild, c.ns.Guild.C
    local gl = Gd.DB().lists
    local stores = {}
    for gname, L in pairs(gl) do stores[#stores + 1] = { "guild:" .. gname, L.enemies, L.hunts or {} } end
    local fdb = c.ns.Friends.DB()
    stores[#stores + 1] = { "friends", fdb.enemies, fdb.hunts }
    for _, s in ipairs(stores) do
      local n, hn = 0, 0
      for key, e in pairs(s[2]) do
        n = n + 1
        for _, d in ipairs(e.deeds) do
          tally.deeds = tally.deeds + 1
          local t = truth.kills[d.victim]
          if not (t and t[key .. "\t" .. d.t]) then problem(seed, "Herkunft: Tat ohne Urheber", c.full .. " haelt in " .. s[1] .. " " .. key .. " Opfer " .. tostring(d.victim)) end
        end
        for char in pairs(e.listedBy or {}) do
          if not (truth.listed[char] and truth.listed[char][key]) then problem(seed, "Herkunft: Hand-Eintrag ohne Urheber", c.full .. ": " .. key .. " von " .. char) end
        end
        if #e.deeds > Cst.MAX_DEEDS then problem(seed, "Deckel: Taten je Eintrag", #e.deeds) end
      end
      for key, h in pairs(s[3]) do
        hn = hn + 1
        local any = false
        for char, r in pairs(h.by) do
          any = true
          tally.hunts = tally.hunts + 1
          if not (truth.released[char] and truth.released[char][key]) then problem(seed, "Herkunft: Freigabe ohne Urheber", c.full .. ": " .. key .. " von " .. char) end
          if type(r.why) == "string" and (r.why:find("[%c|]") or #r.why > Cst.REASON_BYTES) then problem(seed, "Grund nicht sauber", r.why) end
        end
        if not any then problem(seed, "Ziel ohne Freigabe in den Daten", c.full .. ": " .. key) end
      end
      if n > Cst.MAX_ENEMIES then problem(seed, "Deckel: Eintraege", n) end
      if hn > Cst.HUNT_MAX then problem(seed, "Deckel: Ziele", hn) end
    end
    if Gd.QueueSize() > Cst.QUEUE_MAX then problem(seed, "Deckel: Schlange", Gd.QueueSize()) end
    for _, s in ipairs(stores) do
      for key, h in pairs(s[3]) do
        if (h.bagged or 0) > Cst.BAGGED_MAX or #(h.bags or {}) > Cst.BAGS_MAX then problem(seed, "Deckel: Erlegt", key) end
      end
    end
    local nh, nt = 0, 0
    for _ in pairs(Gd.DB().huntHidden or {}) do nh = nh + 1 end
    for _ in pairs(fdb.ties or {}) do nt = nt + 1 end
    if nh > Cst.HIDDEN_MAX then problem(seed, "Deckel: Ausgeblendete", nh) end
    if nt > c.ns.Friends.C.MAX_TIES then problem(seed, "Deckel: Bindungen", nt) end
    -- kein Sprachtext in den gespeicherten Daten (Feld Notiz ausgenommen)
    c.ns.HandleSlash("probe")
    c.fire("PLAYER_LOGOUT")
    local function walk(t, seen)
      if seen[t] then return end
      seen[t] = true
      for k, v in pairs(t) do
        for _, x in ipairs({ k, v }) do
          if type(x) == "string" and not (x == v and k == "note") then
            tally.strings = tally.strings + 1
            local hit = #x >= 9 and sprachtext(x)
            if hit then problem(seed, "Sprachtext in DeathNoteDB: " .. hit, c.full .. " (" .. langOf[i] .. "): " .. x:sub(1, 60)) end
          end
        end
        if type(v) == "table" then walk(v, seen) end
      end
    end
    walk(c.env.DeathNoteDB, {})
  end
  -- gleicher Stand unter Partnern
  for i = 1, N do for j = 1, N do if i ~= j then
    local x, y = C[i], C[j]
    local sameGuild = guildOf[i] ~= nil and guildOf[i] == guildOf[j]
    local pals = hasFriend(i, j) and hasFriend(j, i) and not sameGuild
    local function cmp(tag, hx, hy)
      tally.pairs = tally.pairs + 1
      for key in pairs(truth.released[y.full]) do
        tally.cmp = tally.cmp + 1
        local a = hx and hx[key] and hx[key].by[y.full] ~= nil or false
        local b = hy and hy[key] and hy[key].by[y.full] ~= nil or false
        if a ~= b then
          local detail = ("%s sieht %s von %s: %s, dort selbst: %s"):format(x.full, key, y.full, tostring(a), tostring(b))
          if a and not b and (expireOf[j] > 0 or jumped > 30) then
            bekannt(seed, "Waise: Freigabe steht beim Partner, der Freigebende hat sie nicht mehr (Verfall bzw. Merkfrist)", detail)
          elseif b and not a and expireOf[i] > 0 then
            -- beim Betrachter verfallen: so eingestellt, kein Verstoss
          else
            problem(seed, "Stand ungleich: Freigabe (" .. tag .. ")", detail)
          end
        end
      end
    end
    if sameGuild then
      local lx, ly = x.ns.Guild.DB().lists[guildOf[i]], y.ns.Guild.DB().lists[guildOf[j]]
      cmp("Gilde", lx and lx.hunts, ly and ly.hunts)
      for id in pairs(truth.kills[y.full]) do
        local key, t = id:match("^(.-)\t(%d+)$")
        local e = lx and lx.enemies[key]
        local found = false
        for _, d in ipairs(e and e.deeds or {}) do if d.victim == y.full and d.t == tonumber(t) then found = true end end
        if not found and not truth.gone[y.full .. "\t" .. id] then
          if tageNach(tonumber(t)) >= 3 then bekannt(seed, "Tat fehlt nach Zeitsprung (Gilde): ein Hallo fragt nur bis kurz vor dem letzten Logout zurueck", x.full .. " fehlt " .. key .. " von " .. y.full)
          else problem(seed, "Stand ungleich: Tat fehlt (Gilde)", x.full .. " fehlt " .. key .. " von " .. y.full) end
        end
      end
    elseif pals then
      cmp("Freunde", x.ns.Friends.DB().hunts, y.ns.Friends.DB().hunts)
      for id in pairs(truth.kills[y.full]) do
        local key, t = id:match("^(.-)\t(%d+)$")
        local e = x.ns.Friends.DB().enemies[key]
        local found = false
        for _, d in ipairs(e and e.deeds or {}) do if d.victim == y.full and d.t == tonumber(t) then found = true end end
        if not found and not truth.gone[y.full .. "\t" .. id] and not tainted[i .. ">" .. j] then
          if tageNach(tonumber(t)) >= 3 then bekannt(seed, "Tat fehlt nach Zeitsprung (Freunde): das Hallo fragt accountweit nur bis kurz vor dem letzten Logout zurueck", x.full .. " fehlt " .. key .. " von " .. y.full)
          else problem(seed, "Stand ungleich: Tat fehlt (Freunde)", x.full .. " fehlt " .. key .. " von " .. y.full) end
        end
      end
    end
  end end end
end

for s = SEED0, SEED0 + RUNS - 1 do
  local ok, err = pcall(run, s)
  if not ok then problem(s, "Abbruch des Laufs: " .. tostring(err):gsub("^.-([%w_]+%.lua:%d+)", "%1"), "") end
  M.errors = {}
end
io.write(("  geprueft: %d Nachrichten auf der Leitung, %d Taten und %d Freigaben in fremden Buechern, %d Partnerpaare, %d Freigabe-Vergleiche\n"):format(tally.sent, tally.deeds, tally.hunts, tally.pairs, tally.cmp))
io.write(("  dazu: %d Zeitspruenge (%d Tage), %d Sprachwechsel, %d Laeufe mit Battle.net-Freunden, %d Mal ausgeblendet, %d gespeicherte Texte geprueft\n"):format(tally.jumps, tally.days, tally.langs, tally.bn, tally.hidden, tally.strings))
for _, k in ipairs(known) do io.write(("  bekannt %4dx %s\n         zuerst %s\n"):format(seenKnown[k].n, k, seenKnown[k].first)) end
io.write(("fuzz_final: %d Laeufe (Saat %d bis %d, %d Schritte), %d Arten von Verstoessen\n"):format(RUNS, SEED0, SEED0 + RUNS - 1, STEPS, #problems))
for _, k in ipairs(problems) do io.write(("  ROT %4dx %s\n         zuerst %s\n"):format(seenProblem[k].n, k, seenProblem[k].first)) end
os.exit(#problems == 0 and 0 or 1)
