-- Random runs: two to four simulated clients, random sequences of deaths, manual entries,
-- calls, call-offs, taken down, friendships, login/logout, guild changes, message loss and
-- reordering. Invariants: no Lua errors; nobody holds foreign data the named char did not create
-- itself; caps hold; after a quiet phase without loss (syncs) partners have
-- the same state. Taken over from the bug hunt (fix-1) and extended: two chars with the same first name
-- (the client names them with surname), friend lists with full names, changing guilds.
-- In the suite: fixed seed, short run time. Longer by hand:
--   luajit tests/test_fuzz_clients.lua [project copy] [runs=24] [seed=4242] [steps=110]
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local RUNS, SEED0, STEPS = tonumber(arg[2]) or 24, tonumber(arg[3]) or 4242, tonumber(arg[4]) or 110
local GUILDS = { "Gilde Eins", "Gilde Zwei" }
-- Anton Wurst and Anton Falsch: same first name, the client names both with surname (fullSender)
local NAMES = { { "Anton", "Wurst" }, { "Berta", "Senf" }, { "Anton", "Falsch" }, { "Dora", "Dick" } }
local FULL = { true, false, true, false }
local ENEMIES = { { "Grimm", "Bart" }, { "Fies", "Ling" }, { "Rauf", "Bold" }, { "Zank", "Apfel" }, { "Wut", "Buerger" }, { "Hau", "Drauf" } }
local function ekey(e) return e[1] .. "-" .. e[2] end

local problems, seenProblem = {}, {}
local tally = { sent = 0, cmp = 0, deeds = 0, hunts = 0, relog = 0, pairs = 0 }
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
  local W = M.NewWorld({ "HUNT_BAGGED" })
  local N = R(2, 4)
  local C, friendsOf, guildOf = {}, {}, {}
  -- Truth: what each char ever created itself
  local truth = { kills = {}, listed = {}, released = {}, gone = {} }
  for i = 1, N do
    local full = NAMES[i][1] .. " " .. NAMES[i][2]
    guildOf[i] = ({ GUILDS[1], GUILDS[1], GUILDS[2], nil })[R(1, 4)]
    friendsOf[i] = {}
    truth.kills[full], truth.listed[full], truth.released[full] = {}, {}, {}
  end
  for i = 1, N do for j = 1, N do
    if i ~= j and R() < 0.6 then friendsOf[i][#friendsOf[i] + 1] = NAMES[j][1] .. " " .. NAMES[j][2] end
  end end
  local function spawn(i, db)
    local c = W.client(NAMES[i][1], NAMES[i][2], guildOf[i], { friends = friendsOf[i], db = db, fullSender = FULL[i] })
    c.idx, c.full = i, NAMES[i][1] .. " " .. NAMES[i][2]
    C[i] = c
    c.login()
    return c
  end
  for i = 1, N do spawn(i) end
  local lossy = true
  local deliver = W.deliver
  function W.deliver()
    if lossy and #W.wire > 1 and R() < 0.3 then
      local i, j = R(#W.wire), R(#W.wire)
      W.wire[i], W.wire[j] = W.wire[j], W.wire[i]            -- swap the order
    end
    if lossy then
      for i = #W.wire, 1, -1 do if R() < 0.08 then table.remove(W.wire, i) end end   -- loss
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
    function(c)   -- sure death
      if (killsBy[c.idx] or 0) >= 8 then return end
      killsBy[c.idx] = (killsBy[c.idx] or 0) + 1
      local e = ENEMIES[R(#ENEMIES)]
      local key = H.tod(c, e[1], e[2])
      truth.kills[c.full][key .. "\t" .. time()] = true
    end,
    function(c)   -- add / remove by hand
      local e = ENEMIES[R(#ENEMIES)]
      local key = ekey(e)
      local own = c.ns.Store.Get(key)
      if own and own.manual and R() < 0.5 then
        c.ns.Store.Remove(key)
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
    function(c) c.fire("PARTY_KILL", "Player-1-" .. c.name, "Player-9-E" .. R(#ENEMIES)) end,
    function(c)   -- make or end a friendship
      local j = R(N)
      if j == c.idx then return end
      local l, name = friendsOf[c.idx], NAMES[j][1] .. " " .. NAMES[j][2]
      for k = 1, #l do if l[k] == name then table.remove(l, k); c.fire("FRIENDLIST_UPDATE"); return end end
      l[#l + 1] = name
      c.fire("FRIENDLIST_UPDATE")
    end,
    function(c)   -- logout, later login
      if R() < 0.4 then offline[c.idx] = relog(c.idx) end
    end,
    function(c) c.combat = not c.combat; if not c.combat then c.fire("PLAYER_REGEN_ENABLED") end end,
    function(c) if R() < 0.3 then c.ns.Guild.SyncNow(); c.ns.Friends.SyncNow() end end,
    function(c) c.ns.Guild.OnUnit(ekey(ENEMIES[R(#ENEMIES)]), "nameplate1", "plate", false) end,
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
    if #M.errors > 0 then problem(seed, "Lua-Fehler: " .. tostring(M.errors[1]):gsub("^.-([%w_]+%.lua:%d+)", "%1"), "Schritt " .. step); return end
  end
  -- quiet phase: everyone online, no loss, sync twice
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
  -- invariants
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
        if a ~= b then problem(seed, "Stand ungleich: Freigabe (" .. tag .. ")", ("%s sieht %s von %s: %s, dort selbst: %s"):format(x.full, key, y.full, tostring(a), tostring(b))) end
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
        if not found and not truth.gone[y.full .. "\t" .. id] then problem(seed, "Stand ungleich: Tat fehlt (Gilde)", x.full .. " fehlt " .. key .. " von " .. y.full) end
      end
    elseif pals then
      cmp("Freunde", x.ns.Friends.DB().hunts, y.ns.Friends.DB().hunts)
      for id in pairs(truth.kills[y.full]) do
        local key, t = id:match("^(.-)\t(%d+)$")
        local e = x.ns.Friends.DB().enemies[key]
        local found = false
        for _, d in ipairs(e and e.deeds or {}) do if d.victim == y.full and d.t == tonumber(t) then found = true end end
        if not found and not truth.gone[y.full .. "\t" .. id] then problem(seed, "Stand ungleich: Tat fehlt (Freunde)", x.full .. " fehlt " .. key .. " von " .. y.full) end
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
io.write(("fuzz_clients: %d Laeufe (Saat %d bis %d, %d Schritte), %d Arten von Verstoessen\n"):format(RUNS, SEED0, SEED0 + RUNS - 1, STEPS, #problems))
for _, k in ipairs(problems) do io.write(("  ROT %4dx %s\n         zuerst %s\n"):format(seenProblem[k].n, k, seenProblem[k].first)) end
os.exit(#problems == 0 and 0 or 1)
