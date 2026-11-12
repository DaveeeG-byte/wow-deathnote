-- Proof tests: extended with GUID hellos, Z (forged too), conflicts, clock jumps, humor, fiFI.
-- Extra invariants: a Z never deletes what the sender did not share itself; no humor text in
-- stored or sent data; humor never active outside German and English.
-- (Template) random run of the final hunt, short with a fixed seed in the suite (long by hand: luajit tests/test_fuzz_final.lua . 400 1000 200)
-- Random runs of the final hunt: the fuzzer from tests/test_fuzz_clients.lua, extended with
--   a language per client (deDE, enUS, ruRU, zhCN) and language switches at login, friend lists with first names only,
--   Battle.net friends, time jumps (everyone offline, days pass), expiry of shared entries (0/30/90/180),
--   "Hide for me".
-- Invariants as in the first hunt, plus: no locale text in sent or stored data (note field
-- excepted), a hidden target never alerts, counters and new tables stay under their caps.
-- Violations that trace back to known findings of this hunt (expiry, how long call-offs are remembered) are counted
-- separately as "known" and do not turn the run red.
-- 1.2.1 (after the hunt): set and take back bounties (B, Y), killing blow with the own GUID also in runs
-- with GUIDs (E and V), origin and state of bounties, "avenged" never above the real kills. Exact classification:
-- every clock jump (including the "clock" operation and the reset at the end) counts with its sign for the deeds
-- created before it; senders of forged hellos count as strangers.
-- Usage: luajit fuzz_final.lua <project copy> [runs=60] [seed=1] [steps=140] [ohneverlust]
local DIRARG = (arg[1] or "."):gsub("/+$", "")
package.path = DIRARG .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local RUNS, SEED0, STEPS = tonumber(arg[2]) or 60, tonumber(arg[3]) or 1000, tonumber(arg[4]) or 120
local LANGS = { "deDE", "enUS", "ruRU", "zhCN", "fiFI" }
local NOLOSS = arg[5] == "ohneverlust"   -- counter-check: without loss and swaps nothing may be missing, even after time jumps
local GUILDS = { "Gilde Eins", "Gilde Zwei" }
-- Anton Wurst and Anton Falsch: same first name, the client names both with surname (fullSender)
local NAMES = { { "Anton", "Wurst" }, { "Berta", "Senf" }, { "Anton", "Falsch" }, { "Dora", "Dick" } }
local FULL = { true, false, true, false }
local ENEMIES = { { "Grimm", "Bart" }, { "Fies", "Ling" }, { "Rauf", "Bold" }, { "Zank", "Apfel" }, { "Wut", "Buerger" }, { "Hau", "Drauf" } }
local function ekey(e) return e[1] .. "-" .. e[2] end

-- Locale texts of all four languages (pieces of 9 bytes and more, without sample zone and channel names)
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
-- Proof tests: all texts from the HUMOR-TEXTE block of Humor.lua (pieces of 9 bytes and more)
local HUMOR = {}
do
  local h = assert(io.open(M.ADDON_DIR .. "Humor.lua", "rb")); local s = h:read("*a"); h:close()
  local a = s:find(">>> HUMOR-TEXTE", 1, true); local b = s:find("<<< HUMOR-TEXTE", 1, true)
  for lit in s:sub(a, b):gmatch('"([^"\n]+)"') do
    for part in lit:gsub("{[^{}]*}", "\0"):gsub("%%[sd]", "\0"):gmatch("[^%z]+") do
      part = part:gsub("^%s+", ""):gsub("%s+$", "")
      if #part >= 9 then HUMOR[#HUMOR + 1] = part end
    end
  end
  assert(#HUMOR > 40, "Humor-Texte nicht gefunden")
end
local function humortext(s)
  for i = 1, #HUMOR do if s:find(HUMOR[i], 1, true) then return HUMOR[i] end end
end
local function filesFor(code)
  local out = {}
  for _, f in ipairs(M.FILES) do
    out[#out + 1] = f
    if f == "Locales/deDE.lua" and code ~= "deDE" and code ~= "enUS" then out[#out + 1] = "Locales/" .. code .. ".lua" end
  end
  out[#out + 1] = "Humor.lua"
  return out
end

local known, seenKnown = {}, {}
local function bekannt(seed, kind, detail)
  if not seenKnown[kind] then seenKnown[kind] = { n = 0, first = ("Saat %d: %s"):format(seed, tostring(detail)) }; known[#known + 1] = kind end
  seenKnown[kind].n = seenKnown[kind].n + 1
end
local problems, seenProblem = {}, {}
local tally = { zs = 0, zdel = 0, forged = 0, choose = 0, clock = 0, humor = 0, guidRuns = 0, sent = 0, cmp = 0, deeds = 0, hunts = 0, relog = 0, pairs = 0, jumps = 0, days = 0, langs = 0, strings = 0, hidden = 0, bn = 0,
  bset = 0, boff = 0, bseen = 0, bcmp = 0, kills = 0, guidKills = 0, eSent = 0, vSent = 0, avenged = 0, strangerWait = 0 }
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
  local everExpire = {}   -- 1.2.1: whoever ever set an expiry (own bounties may run out then)
  W.guids = R() < 0.5
  if W.guids then tally.guidRuns = tally.guidRuns + 1 end
  local strangers = {}
  local forgedGuid = {}   -- 1.2.1: forgers and the foreign GUID they carried in the hello
  local clockBack = 0
  local FIRSTONLY = R() < 0.5     -- Berta and Dora are on the lists with first names only
  local function listName(j)
    if FIRSTONLY and (j == 2 or j == 4) then return NAMES[j][1] end
    return NAMES[j][1] .. " " .. NAMES[j][2]
  end
  local jumpLog = {}
  -- 1.2.1: every deed remembers how many jumps there were when it was created (clock operations included)
  local bornAt = {}
  -- Days the clock moved forward after deed id was created (time jumps, clock forward/back, reset at the end;
  -- from 3 days on the look-back of a hello no longer covers the deed)
  local function tageNach(id)
    local n = 0
    for k = (bornAt[id] or 0) + 1, #jumpLog do n = n + jumpLog[k][2] end
    return n
  end
  local N = R(2, 4)
  local C, friendsOf, guildOf = {}, {}, {}
  -- Truth: what each char ever created itself
  local truth = { kills = {}, listed = {}, released = {}, gone = {}, bounty = {}, bountyEver = {}, pk = {} }
  for i = 1, N do
    local full = NAMES[i][1] .. " " .. NAMES[i][2]
    guildOf[i] = ({ GUILDS[1], GUILDS[1], GUILDS[2], nil })[R(1, 4)]
    friendsOf[i] = {}
    langOf[i], bnOf[i], expireOf[i] = LANGS[R(#LANGS)], {}, 0
    truth.kills[full], truth.listed[full], truth.released[full] = {}, {}, {}
    truth.bounty[full], truth.bountyEver[full], truth.pk[full] = {}, {}, {}
  end
  for i = 1, N do for j = 1, N do
    if i ~= j and R() < 0.6 then friendsOf[i][#friendsOf[i] + 1] = listName(j) end
  end end
  -- Battle.net friendships (mutual) between chars with a unique first name; the mock gives only first names there
  local UNIQUE = { [2] = true, [4] = true }
  if N >= 4 and R() < 0.5 then bnOf[2][1], bnOf[4][1] = NAMES[4][1], NAMES[2][1]; tally.bn = tally.bn + 1 end
  local function spawn(i, db)
    -- Language switch at login: the choice is in the file, the client loads the locale file as from the TOC
    if db and R() < 0.3 then
      langOf[i] = LANGS[R(#LANGS)]
      if type(db.settings) == "table" then db.settings.lang = langOf[i] end
      tally.langs = tally.langs + 1
    end
    local c = W.client(NAMES[i][1], NAMES[i][2], guildOf[i], { friends = friendsOf[i], db = db, fullSender = FULL[i] or FIRSTONLY,   -- one name form: with lists without surnames the client names every sender in full
      bn = bnOf[i], lang = langOf[i], files = filesFor(langOf[i]) })
    if c.ns.Locale.code ~= langOf[i] then problem(seed, "Sprache nicht aktiv", langOf[i] .. " gewaehlt, aktiv " .. tostring(c.ns.Locale.code)) end
    c.ns:On("GUILD_ENEMY_SPOTTED", function(key, _, _, kind)
      if kind == "hunt" and c.ns.Guild.HuntHidden(key) then problem(seed, "ausgeblendetes Ziel alarmiert", key) end
    end)
    c.idx, c.full = i, NAMES[i][1] .. " " .. NAMES[i][2]
    if c.ns.Humor and c.ns.Humor.CHANCE then for k in pairs(c.ns.Humor.CHANCE) do c.ns.Humor.CHANCE[k] = 1 end; c.ns.Humor.QUIET = 0 end
    if (langOf[i] ~= "deDE" and langOf[i] ~= "enUS") and c.ns.Humor and c.ns.Humor.On and c.ns.Humor.On() then problem(seed, "Humor aktiv in " .. langOf[i], c.full) end
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
      W.wire[i], W.wire[j] = W.wire[j], W.wire[i]            -- swap the order
    end
    if lossy then
      for i = #W.wire, 1, -1 do if R() < 0.08 then table.remove(W.wire, i) end end   -- loss
    end
    -- Proof tests: deliver by hand so the true sender of every Z is known
    local n = 0
    while #W.wire > 0 do
      local m = table.remove(W.wire, 1)
      n = n + 1
      local targets = {}
      if m.channel == "BN" then
        for _, c in ipairs(W.clients) do if c.bnId == m.toId and c.online ~= false and c.loggedIn then targets[#targets + 1] = c end end
      elseif m.channel == "WHISPER" then
        local c = W.find(m.to or "")
        if c and c.online ~= false and c.loggedIn then targets[1] = c end
      else
        for _, c in ipairs(W.clients) do if c.guild == m.guild then targets[#targets + 1] = c end end
      end
      local isZ = m.text:find("^1\tZ\t") ~= nil
      for _, c in ipairs(targets) do
        local before
        if isZ and c.ns.Friends and c.ns.Friends.DB and c.ns.Friends.DB() then
          before = {}
          local books = { c.ns.Friends.DB().hunts }
          for _, L in pairs(c.ns.Guild.DB().lists) do books[#books + 1] = L.hunts or {} end
          for bi, hh in ipairs(books) do for key, h in pairs(hh) do for char in pairs(h.by) do before[#before + 1] = { hh, key, char } end end end
          tally.zs = tally.zs + 1
        end
        if m.channel == "BN" then c.fire("BN_CHAT_MSG_ADDON", m.prefix, m.text, "WHISPER", m.fromId)
        else c.fire("CHAT_MSG_ADDON", m.prefix, m.text, m.channel, m.from) end
        if before then
          local sfull = m.forgedAs or (m.sender and (m.sender.name .. " " .. m.sender.surname))
          for _, b in ipairs(before) do
            local h = b[1][b[2]]
            if not (h and h.by[b[3]]) then
              tally.zdel = tally.zdel + 1
              if b[3] ~= sfull then problem(seed, "eine Z loescht eine Freigabe, die nicht vom Absender stammt", c.full .. ": " .. b[2] .. " von " .. b[3] .. ", Z kam von " .. tostring(sfull) .. (m.forged and " (gefaelscht)" or "")) end
              if b[3] == c.full then problem(seed, "eine Z loescht eine EIGENE Freigabe", c.full .. ": " .. b[2]) end
            end
          end
        end
      end
    end
    return n
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
    function(c)   -- sure death
      if (killsBy[c.idx] or 0) >= 8 then return end
      killsBy[c.idx] = (killsBy[c.idx] or 0) + 1
      local e = ENEMIES[R(#ENEMIES)]
      local key = H.tod(c, e[1], e[2])
      truth.kills[c.full][key .. "\t" .. time()] = true
      bornAt[c.full .. "\t" .. key .. "\t" .. time()] = #jumpLog
    end,
    function(c)   -- add / remove by hand
      local e = ENEMIES[R(#ENEMIES)]
      local key = ekey(e)
      local own = c.ns.Store.Get(key)
      if own and own.manual and R() < 0.5 then
        c.ns.Store.Remove(key)
        -- 1.2.1: struck, and no other book shows them: the own bounty goes with it
        if truth.bounty[c.full][key] and not c.ns.Guild.OwnBounty(key) then truth.bounty[c.full][key] = nil end
        -- deeds deleted by the owner need not reach anyone any more
        for id in pairs(truth.kills[c.full]) do if id:match("^(.-)\t") == key then truth.gone[c.full .. "\t" .. id] = true end end
      elseif not own then
        c.ns.Store.AddManual(e[1], e[2]); truth.listed[c.full][key] = true
      end
    end,
    function(c)   -- release
      local key = ekey(ENEMIES[R(#ENEMIES)])
      local g, f = c.ns.Guild.Release(key, { to = ({ "all", "guild", "friends" })[R(3)], why = R() < 0.5 and "Grund |cffff0000x|r " .. R(9) or nil })
      if g or f then truth.released[c.full][key] = true end
    end,
    function(c) c.ns.Guild.CallOff(ekey(ENEMIES[R(#ENEMIES)]), ({ nil, "guild", "friends" })[R(3)]) end,
    function(c)   -- own killing blow (1.2.1: with the own GUID, also in runs with GUIDs: E and V are created)
      local n = R(#ENEMIES)
      local key = ekey(ENEMIES[n])
      local e0, v0 = 0, 0
      for _, m in ipairs(W.sent) do if m.sender == c then
        if m.text:find("^1\tE\t") then e0 = e0 + 1 elseif m.text:find("^1\tV\t") then v0 = v0 + 1 end end end
      local was = #W.sent
      c.fire("PARTY_KILL", c.env.UnitGUID("player"), "Player-9-E" .. n)
      tally.kills = tally.kills + 1
      if W.guids then tally.guidKills = tally.guidKills + 1 end
      if c.ns.Util.IsOpenWorld() then truth.pk[c.full][key] = (truth.pk[c.full][key] or 0) + 1 end
      for k = was + 1, #W.sent do local m = W.sent[k]
        if m.text:find("^1\tE\t") then tally.eSent = tally.eSent + 1 elseif m.text:find("^1\tV\t") then tally.vSent = tally.vSent + 1 end end
    end,
    function(c)   -- 1.2.1: set, change or take back an own bounty
      local key = ekey(ENEMIES[R(#ENEMIES)])
      local g = ({ 1, 50, 500, 99999 })[R(4)]
      if R() < 0.4 then   -- take back: usually an own one that exists
        g = 0
        local own = {}
        for k in pairs(truth.bounty[c.full]) do own[#own + 1] = k end
        table.sort(own)
        if #own > 0 and R() < 0.8 then key = own[R(#own)] end
      end
      if c.ns.Guild.SetBounty(key, g) then
        if g == 0 then truth.bounty[c.full][key] = nil; tally.boff = tally.boff + 1
        else truth.bounty[c.full][key] = g; truth.bountyEver[c.full][key .. "\t" .. g] = true; tally.bset = tally.bset + 1 end
      end
    end,
    function(c)   -- make or end a friendship
      local j = R(N)
      if j == c.idx then return end
      local l, name = friendsOf[c.idx], listName(j)
      for k = 1, #l do if l[k] == name then
        table.remove(l, k); c.fire("FRIENDLIST_UPDATE")
        tainted[c.idx .. ">" .. j], tainted[j .. ">" .. c.idx] = true, true
        return
      end end
      l[#l + 1] = name
      c.fire("FRIENDLIST_UPDATE")
    end,
    function(c)   -- logout, later login
      if R() < 0.4 then offline[c.idx] = relog(c.idx) end
    end,
    function(c) c.combat = not c.combat; if not c.combat then c.fire("PLAYER_REGEN_ENABLED") end end,
    function(c) if R() < 0.3 then c.ns.Guild.SyncNow(); c.ns.Friends.SyncNow() end end,
    function(c) c.ns.Guild.OnUnit(ekey(ENEMIES[R(#ENEMIES)]), "nameplate1", "plate", false) end,
    function(c)   -- set the expiry of shared entries (W1)
      if R() < 0.4 then
        expireOf[c.idx] = ({ 0, 0, 30, 90, 180 })[R(5)]
        if expireOf[c.idx] > 0 then everExpire[c.idx] = true end
        c.ns.Store.Setting("guild.huntExpire", expireOf[c.idx])
      end
    end,
    function(c)   -- hide for me / show again
      local key = ekey(ENEMIES[R(#ENEMIES)])
      c.ns.Guild.HideHunt(key, R() < 0.6); tally.hidden = tally.hidden + 1
    end,
    function(c)   -- commands in the client's language
      local slash = c.ns.HandleSlash   -- not SlashCmdList: all clients of the world share that table
      if slash then slash(({ "gilde", "friends", "probe", "hilfe", "lang", "jagd " .. ENEMIES[R(#ENEMIES)][1] })[R(6)]) end
      for _, e in ipairs(ENEMIES) do
        local g, f = c.ns.Guild.Released(ekey(e))
        if g or f then truth.released[c.full][ekey(e)] = true end
      end
    end,
    function(c)   -- forged Z and forged hello with GUID from a stranger or in someone else's name
      local j = R(N)
      local victim = NAMES[j][1] .. " " .. NAMES[j][2]
      local P = c.ns.Guild.Proto
      local liar = ({ "Fremd Ling", NAMES[j][1] .. " Fremd", NAMES[R(N)][1] .. " " .. NAMES[R(N)][2] })[R(3)]
      if liar == victim or liar == c.full then return end
      -- 1.2.1: whoever forges a hello and is no char of the run is a stranger (they can be bound)
      if not truth.kills[liar] then strangers[liar] = true end
      if C[j] then forgedGuid[liar .. "\t" .. W.guidOf(C[j])] = true end
      local z = P.EncodeSnapshot(victim, R(0, 2))
      local hello = P.EncodeHello(0, "1.2.0", C[j] and W.guidOf(C[j]) or nil)
      for _, ch in ipairs({ "GUILD", "WHISPER" }) do
        W.wire[#W.wire + 1] = { prefix = "DeathNote", text = R() < 0.3 and hello or z, channel = ch, from = liar .. "-Forever", guild = c.guild, to = c.full, forged = true, forgedAs = liar }
      end
      tally.forged = tally.forged + 1
    end,
    function(c)   -- strangers with a friend's first name whisper a shared entry (full name, two different ones)
      local j = ({ 2, 4 })[R(2)]
      if j > N or j == c.idx then return end
      local P = c.ns.Guild.Proto
      local stranger = NAMES[j][1] .. ({ " Fremd", " Anders" })[R(2)]
      local key = ekey(ENEMIES[R(#ENEMIES)])
      strangers[stranger] = true
      W.wire[#W.wire + 1] = { prefix = "DeathNote", text = P.EncodeHunt({ key = key, t = time(), by = stranger, why = "x" }), channel = "WHISPER", from = stranger .. "-Forever", to = c.full, forged = true, forgedAs = stranger }
      tally.forged = tally.forged + 1
    end,
    function(c)   -- conflict: choose or release the binding
      local F = c.ns.Friends
      if not (F and F.Conflicts) then return end
      local cf = F.Conflicts()[1]
      if cf then
        if R() < 0.5 then F.Choose(cf.list, R() < 0.5 and cf.full or cf.rival) else F.Unbind(cf.list) end
        tally.choose = tally.choose + 1
        for j = 1, N do tainted[c.idx .. ">" .. j] = true end
      elseif R() < 0.2 then
        local b = F.Bound()[1]
        if b then F.Unbind(b.list); for j = 1, N do tainted[c.idx .. ">" .. j] = true end end
      end
    end,
    function(c)   -- clock one day back or forward (everyone shares the mock's clock)
      if R() < 0.1 then
        local d = R() < 0.5 and -86400 or 86400
        M.epoch = M.epoch + d; tally.clock = tally.clock + 1
        if d < 0 then clockBack = clockBack + 1 end
        jumpLog[#jumpLog + 1] = { time(), d / 86400 }   -- 1.2.1: the clock operation counts with its sign
      end
    end,
    function(c)   -- humor occasions: revenge, pardon, hidden commands
      local e = ENEMIES[R(#ENEMIES)]
      local key = ekey(e)
      local S = c.ns.Store
      if S.Get(key) then
        if R() < 0.5 and S.AddRevenge then S.AddRevenge(key) end
        if R() < 0.3 and S.SetStatus then S.SetStatus(key, R() < 0.5 and "pardoned" or "wanted") end
      end
      c.ns.HandleSlash(({ "fachkraft", "42", "beichte", "danke", "confess", "thanks" })[R(6)])
      tally.humor = tally.humor + 1
    end,
    function(c)   -- change, leave or join a guild (fix-1)
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
    -- Time jump: everyone goes offline, days pass (at most 55 in total: above that a known finding applies)
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
  -- quiet phase: everyone online, no loss, sync twice
  lossy = false
  M.epoch = M.epoch + clockBack * 86400   -- the clock is right again (otherwise deeds would lie in the future)
  if clockBack > 0 then jumpLog[#jumpLog + 1] = { time(), clockBack } end   -- 1.2.1: this counts too
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
    local hh = humortext(m.text)
    if hh then problem(seed, "Humor-Text auf der Leitung", hh) end
  end
  -- invariants
  local function hasFriend(i, j) for _, n in ipairs(friendsOf[i]) do if n == listName(j) then return true end end return false end
  for i = 1, N do
    local c = C[i]
    local Gd, Cst = c.ns.Guild, c.ns.Guild.C
    local gl = Gd.DB().lists
    local stores = {}
    for gname, L in pairs(gl) do stores[#stores + 1] = { "guild:" .. gname, L.enemies, L.hunts or {}, L.bounty or {} } end
    local fdb = c.ns.Friends.DB()
    stores[#stores + 1] = { "friends", fdb.enemies, fdb.hunts, fdb.bounty or {} }
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
          if strangers[char] then
            tally.strangerIn = (tally.strangerIn or 0) + 1
            if W.guids then
              local ln = char:match("^(%S+)")
              local tie = fdb.ties[ln] or {}
              local fx = c.ns.Friends.FriendOf(ln)
              if fx and fx.guid and not tie.rival then
                -- 1.2.1 (decision after the hunt): nothing is deleted on suspicion. A never proven binding to the
                -- stranger stays until the real friend's hello decides; that can only fail to happen if the real
                -- friend does not have the viewer on their list (they never answer them). Otherwise it is a violation.
                local real
                for jj = 1, N do if NAMES[jj][1] == ln and listName(jj) == ln then real = jj end end
                local detail = c.full .. ": " .. key .. " von " .. char .. (" | Bindung %s/%s/%s/%s, GUID der Liste %s, auf der Liste %s"):format(tostring(tie.full), tostring(tie.rival), tostring(tie.sure), tostring(tie.guid), tostring(fx and fx.guid), tostring(fx and fx.listed))
                if tie.full == char and tie.guid and forgedGuid[char .. "\t" .. tie.guid] then
                  bekannt(seed, "Fremder mit gefaelschter GUID im Hallo gebunden (die GUID des echten Freunds; Grenze des Ausweises seit 1.2.0, im Spiel nicht pruefbar)", detail)
                elseif tie.full == char and not tie.guid and real and not hasFriend(real, i) then
                  tally.strangerWait = tally.strangerWait + 1
                  bekannt(seed, "Fremder vorlaeufig gebunden, der echte Freund hat den Betrachter nicht auf der Liste (sein Hallo kommt nie): bleibt bis zum Beweis", detail)
                else
                  problem(seed, "Fremder im Freundesbuch, obwohl die Freundesliste die GUID nennt", detail)
                end
              end
            end
          elseif not (truth.released[char] and truth.released[char][key]) then problem(seed, "Herkunft: Freigabe ohne Urheber", c.full .. ": " .. key .. " von " .. char) end
          if type(r.why) == "string" and (r.why:find("[%c|]") or #r.why > Cst.REASON_BYTES) then problem(seed, "Grund nicht sauber", r.why) end
        end
        if not any then problem(seed, "Ziel ohne Freigabe in den Daten", c.full .. ": " .. key) end
      end
      -- 1.2.1: other players' bounties: only from the char that set it, with an amount it set
      local nb = 0
      for key, x in pairs(s[4]) do
        nb = nb + 1
        local per = 0
        for char, r in pairs(x) do
          tally.bseen = tally.bseen + 1
          per = per + 1
          if char == c.full then problem(seed, "eigenes Kopfgeld in einem fremden Buch", s[1] .. " " .. key) end
          if not (truth.bountyEver[char] and truth.bountyEver[char][key .. "\t" .. tostring(r.g)]) then
            problem(seed, "Herkunft: Kopfgeld ohne Urheber", c.full .. " in " .. s[1] .. ": " .. key .. " von " .. char .. " " .. tostring(r.g))
          end
        end
        if per == 0 then problem(seed, "Ziel ohne Kopfgeld in den Daten", key) end
      end
      if nb > Cst.BOUNTY_MAX then problem(seed, "Deckel: Kopfgeld-Ziele", nb) end
      if n > Cst.MAX_ENEMIES then problem(seed, "Deckel: Eintraege", n) end
      if hn > Cst.HUNT_MAX then problem(seed, "Deckel: Ziele", hn) end
    end
    if Gd.QueueSize() > Cst.QUEUE_MAX then problem(seed, "Deckel: Schlange", Gd.QueueSize()) end
    for _, s in ipairs(stores) do
      for key, h in pairs(s[3]) do
        if (h.bagged or 0) > Cst.BAGGED_MAX or #(h.bags or {}) > Cst.BAGS_MAX then problem(seed, "Deckel: Erlegt", key) end
      end
    end
    -- 1.2.1: "avenged" never above the number of real own killing blows of this char on this target
    for key, a in pairs(c.env.DeathNoteDB.avenged or {}) do
      for char, k in pairs(a.by or {}) do
        tally.avenged = tally.avenged + k
        local real = truth.pk[char] and truth.pk[char][key] or 0
        if k > real then problem(seed, "geraecht ueber den echten Toetungen", c.full .. ": " .. key .. " von " .. char .. " " .. k .. " > " .. real) end
      end
    end
    local nh, nt = 0, 0
    for _ in pairs(Gd.DB().huntHidden or {}) do nh = nh + 1 end
    for _ in pairs(fdb.ties or {}) do nt = nt + 1 end
    if nh > Cst.HIDDEN_MAX then problem(seed, "Deckel: Ausgeblendete", nh) end
    if nt > c.ns.Friends.C.MAX_TIES then problem(seed, "Deckel: Bindungen", nt) end
    -- no locale text in the stored data (note field excepted)
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
            local hh = #x >= 9 and humortext(x)
            if hh then problem(seed, "Humor-Text in DeathNoteDB", c.full .. ": " .. hh) end
          end
        end
        if type(v) == "table" then walk(v, seen) end
      end
    end
    walk(c.env.DeathNoteDB, {})
    if langOf[i] ~= "deDE" and langOf[i] ~= "enUS" and false then end
  end
  -- same state among partners
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
            -- expired at the viewer: set up that way, no violation
          else
            local fx = x.ns.Friends
            local tie = fx.DB().ties[listName(j)] or {}
            local back = y.ns.Friends.DB().ties[listName(i)] or {}
            if back.rival or strangers[back.full or ""] then tie = back end   -- the other side's conflict blocks their answers too
            if tie.rival or strangers[tie.full or ""] then bekannt(seed, "Konflikt offen oder Fremder vorlaeufig gebunden (ohne GUID): vom Freund wird nichts angenommen (" .. tag .. ")", detail)
            else problem(seed, "Stand ungleich: Freigabe (" .. tag .. ")", detail .. (" | GUIDs %s, nurVorname %s, Bindung %s/%s/%s, letzter Grund %s"):format(tostring(W.guids), tostring(FIRSTONLY), tostring(tie.full), tostring(tie.rival), tostring(tie.sure), tostring(fx.stats.lastReason))) end
          end
        end
      end
    end
    -- 1.2.1: y's bounty as x sees it equals the one y has itself (expiry set: excepted)
    -- (compared with what y has itself; that y loses nothing is checked against the truth below)
    local function bcmp(tag, bx)
      if everExpire[i] then return end
      local seen = {}
      local mineNow = {}
      for key, xx in pairs(y.env.DeathNoteDB.bounty or {}) do if xx[y.full] then mineNow[key] = xx[y.full].g end end
      for key, g in pairs(mineNow) do
        seen[key] = true
        tally.bcmp = tally.bcmp + 1
        local r = bx and bx[key] and bx[key][y.full]
        if not r or r.g ~= g then
          local tie = x.ns.Friends.DB().ties[listName(j)] or {}
          local back = y.ns.Friends.DB().ties[listName(i)] or {}
          if tag == "Freunde" and (tie.rival or back.rival or strangers[tie.full or ""] or strangers[back.full or ""]) then
            bekannt(seed, "Konflikt offen oder Fremder vorlaeufig gebunden (ohne GUID): vom Freund wird nichts angenommen (Kopfgeld)", key)
          else
            problem(seed, "Stand ungleich: Kopfgeld (" .. tag .. ")", ("%s sieht %s von %s: %s, dort selbst %d"):format(x.full, key, y.full, tostring(r and r.g), g))
          end
        end
      end
      for key, xx in pairs(bx or {}) do
        local tie = x.ns.Friends.DB().ties[listName(j)] or {}
        local back = y.ns.Friends.DB().ties[listName(i)] or {}
        if xx[y.full] and not seen[key] and tag == "Freunde" and (tie.rival or back.rival or strangers[tie.full or ""] or strangers[back.full or ""]) then
          bekannt(seed, "Konflikt offen oder Fremder vorlaeufig gebunden (ohne GUID): vom Freund wird nichts angenommen (Kopfgeld)", key)
        elseif xx[y.full] and not seen[key] then
          problem(seed, "Stand ungleich: zurueckgenommenes Kopfgeld steht noch (" .. tag .. ")", ("%s sieht %s von %s: %d"):format(x.full, key, y.full, xx[y.full].g))
        end
      end
    end
    if i == 1 or (i == 2 and j == 1) then
      -- y's own bounties: exactly the ones set (expiry set: they may run out)
      local own = y.env.DeathNoteDB.bounty or {}
      for key, g in pairs(truth.bounty[y.full]) do
        local r = own[key] and own[key][y.full]
        if not (r and r.g == g) and not everExpire[j] then problem(seed, "eigenes Kopfgeld verloren oder falsch", y.full .. " " .. key .. " " .. g .. " -> " .. tostring(r and r.g)) end
      end
      for key, xx in pairs(own) do
        if xx[y.full] and truth.bounty[y.full][key] == nil then problem(seed, "eigenes Kopfgeld, das nicht gesetzt ist", y.full .. " " .. key) end
      end
    end
    if sameGuild then
      local lx, ly = x.ns.Guild.DB().lists[guildOf[i]], y.ns.Guild.DB().lists[guildOf[j]]
      cmp("Gilde", lx and lx.hunts, ly and ly.hunts)
      bcmp("Gilde", lx and lx.bounty)
      for id in pairs(truth.kills[y.full]) do
        local key, t = id:match("^(.-)\t(%d+)$")
        local e = lx and lx.enemies[key]
        local found = false
        for _, d in ipairs(e and e.deeds or {}) do if d.victim == y.full and d.t == tonumber(t) then found = true end end
        if not found and not truth.gone[y.full .. "\t" .. id] then
          if tageNach(y.full .. "\t" .. id) >= 3 then bekannt(seed, "Tat fehlt nach Zeitsprung (Gilde): ein Hallo fragt nur bis kurz vor dem letzten Logout zurueck", x.full .. " fehlt " .. key .. " von " .. y.full)
          else problem(seed, "Stand ungleich: Tat fehlt (Gilde)", x.full .. " fehlt " .. key .. " von " .. y.full) end
        end
      end
    elseif pals then
      cmp("Freunde", x.ns.Friends.DB().hunts, y.ns.Friends.DB().hunts)
      bcmp("Freunde", x.ns.Friends.DB().bounty)
      for id in pairs(truth.kills[y.full]) do
        local key, t = id:match("^(.-)\t(%d+)$")
        local e = x.ns.Friends.DB().enemies[key]
        local found = false
        for _, d in ipairs(e and e.deeds or {}) do if d.victim == y.full and d.t == tonumber(t) then found = true end end
        if not found and not truth.gone[y.full .. "\t" .. id] and not tainted[i .. ">" .. j] then
          if tageNach(y.full .. "\t" .. id) >= 3 then bekannt(seed, "Tat fehlt nach Zeitsprung (Freunde): das Hallo fragt accountweit nur bis kurz vor dem letzten Logout zurueck", x.full .. " fehlt " .. key .. " von " .. y.full)
          else
            local fx = x.ns.Friends
            local tie = fx.DB().ties[listName(j)] or {}
            local back = y.ns.Friends.DB().ties[listName(i)] or {}
            if back.rival or strangers[back.full or ""] then tie = back end   -- the other side's conflict blocks their answers too
            if tie.rival or strangers[tie.full or ""] then bekannt(seed, "Konflikt offen oder Fremder vorlaeufig gebunden (ohne GUID): vom Freund wird nichts angenommen (Tat)", x.full .. " fehlt " .. key .. " von " .. y.full)
            else problem(seed, "Stand ungleich: Tat fehlt (Freunde)", x.full .. " fehlt " .. key .. " von " .. y.full .. (" | GUIDs %s, nurVorname %s, Bindung %s/%s/%s, letzter Grund %s, Alter der Tat %d Tage"):format(tostring(W.guids), tostring(FIRSTONLY), tostring(tie.full), tostring(tie.rival), tostring(tie.sure), tostring(fx.stats.lastReason), math.floor((time() - tonumber(t)) / 86400))) end
          end
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
io.write(("  1.2.1: %d Kopfgelder gesetzt, %d zurueckgenommen, %d in fremden Buechern geprueft, %d Kopfgeld-Vergleiche; %d Todesstoesse (%d mit GUIDs), %d E und %d V gesendet, %d mal geraecht gezaehlt; %d Mal Fremder wartet auf Beweis\n"):format(tally.bset, tally.boff, tally.bseen, tally.bcmp, tally.kills, tally.guidKills, tally.eSent, tally.vSent, tally.avenged, tally.strangerWait))
io.write(("  Abschluss: %d Z zugestellt, %d Freigaben durch Z geloescht, %d Faelschungen, %d Wahlen/Loesungen, %d Uhr-Spruenge, %d Humor-Anlaesse, %d Laeufe mit GUID in der Freundesliste, %d Freigaben von Fremden in Buechern ohne GUID\n"):format(tally.zs, tally.zdel, tally.forged, tally.choose, tally.clock, tally.humor, tally.guidRuns, tally.strangerIn or 0))
io.write(("fuzz_abschluss: %d Laeufe (Saat %d bis %d, %d Schritte), %d Arten von Verstoessen\n"):format(RUNS, SEED0, SEED0 + RUNS - 1, STEPS, #problems))
for _, k in ipairs(problems) do io.write(("  ROT %4dx %s\n         zuerst %s\n"):format(seenProblem[k].n, k, seenProblem[k].first)) end
os.exit(#problems == 0 and 0 or 1)
