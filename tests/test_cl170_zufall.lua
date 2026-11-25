-- 1.7.0 claim: random run. RUNS runs of STEPS random steps with three guildmates and a friend of two of them: posting
-- and taking back bounties, own killing blows on two targets, paid / declined / open again, logging out and in,
-- waiting (also past the throttles). After every step:
--   per poster: per bounty (target, own char, first posting) at most one claim paid (1.7.0 fix: the new E4);
--   per killer: every record open, paid or declined has its claim at the poster (same target, killer, kill time; two
--   kills of the same target by the same killer less than 60 s apart are one kill, as in Feud.AddClaim since 1.6.0);
--   no Lua error.
-- Usage: luajit tests/test_cl170_zufall.lua [project] ; env CL170_RUNS, CL170_STEPS, CL170_SEED
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_cl170")
local H, M, G = K.H, K.M, K.G

local RUNS = tonumber(os.getenv("CL170_RUNS")) or 6
local STEPS = tonumber(os.getenv("CL170_STEPS")) or 70
local SEED = tonumber(os.getenv("CL170_SEED")) or 1700

local PEOPLE = {
  { "Anton", "Wurst", G, { "Dora Dorn" } },
  { "Berta", "Senf", G, { "Dora Dorn" } },
  { "Carla", "Klee", G, {} },
  { "Dora", "Dorn", nil, { "Anton Wurst", "Berta Senf" } },
}
local TARGETS = { { K.KEY, K.GUID }, { K.KEY2, K.GUID2 } }

local stats = { kills = 0, posts = 0, backs = 0, sets = 0, relogs = 0, claims = 0, earned = 0, final = 0, sent = 0 }
local firstFail

local function full(p) return p[1] .. " " .. p[2] end

local function check(cl, step, seed)
  local byName = {}
  for _, p in ipairs(PEOPLE) do byName[full(p)] = cl[full(p)] end
  for name, c in pairs(byName) do
    local seen = {}
    for _, y in ipairs(K.claims(c)) do
      if y.b ~= nil and y.state == "paid" then
        local id = y.key .. "|" .. tostring(y.char) .. "|" .. y.b
        if seen[id] then return ("Saat %d Schritt %d: %s hat zwei bezahlte Ansprueche auf %s"):format(seed, step, name, id) end
        seen[id] = true
      end
    end
    for _, x in ipairs(K.earned(c)) do
      if x.state == "open" or x.state == "paid" or x.state == "declined" then
        local o = byName[x.owner]
        local found = false
        for _, y in ipairs(o and K.claims(o) or {}) do
          if y.key == x.key and y.by == x.char and math.abs(y.t - x.t) < 60 then found = true; break end
        end
        if not found then
          return ("Saat %d Schritt %d: %s hat %s (%s) ohne Anspruch bei %s"):format(seed, step, name, x.key, x.state, x.owner)
        end
      end
    end
  end
  if #M.errors > 0 then return ("Saat %d Schritt %d: Fehler %s"):format(seed, step, tostring(M.errors[1])) end
  return nil
end

for run = 1, RUNS do
  local seed = SEED + run - 1
  math.randomseed(seed)
  local W = K.welt()
  local cl, online = {}, {}
  for _, p in ipairs(PEOPLE) do
    local c = W.client(p[1], p[2], p[3], { friends = p[4], fullSender = true })
    cl[full(p)] = c
  end
  for _, p in ipairs(PEOPLE) do cl[full(p)].login(); online[full(p)] = true end
  W.run(150)
  local function pick(onlyOnline)
    local list = {}
    for _, p in ipairs(PEOPLE) do if not onlyOnline or online[full(p)] then list[#list + 1] = full(p) end end
    if #list == 0 then return nil end
    return list[math.random(#list)]
  end
  for step = 1, STEPS do
    local r = math.random(100)
    if r <= 22 then
      local n = pick(true)
      local tg = TARGETS[math.random(#TARGETS)]
      if n then
        if math.random(5) == 1 then
          if cl[n].ns.Guild.SetBounty(tg[1], 0) then stats.backs = stats.backs + 1 end
        elseif cl[n].ns.Guild.SetBounty(tg[1], math.random(1, 120)) then
          stats.posts = stats.posts + 1
        end
      end
    elseif r <= 50 then
      local n = pick(true)
      local tg = TARGETS[math.random(#TARGETS)]
      if n then K.toetet(cl[n], tg[2]); stats.kills = stats.kills + 1 end
    elseif r <= 70 then
      local n = pick(true)
      local list = n and K.claims(cl[n]) or {}
      if #list > 0 then
        local y = list[math.random(#list)]
        local st = ({ "paid", "declined", "open" })[math.random(3)]
        if cl[n].ns.Feud.SetClaim(y, st) then stats.sets = stats.sets + 1 end
      end
    elseif r <= 80 then
      local n = pick(true)
      local count = 0
      for _ in pairs(online) do count = count + 1 end
      if n and count > 2 then
        local nc = K.weg(W, cl[n])
        cl[n], online[n] = nc, nil
        W.setOnline(nc, false)
        stats.relogs = stats.relogs + 1
      end
    elseif r <= 90 then
      local off = {}
      for _, p in ipairs(PEOPLE) do if not online[full(p)] then off[#off + 1] = full(p) end end
      if #off > 0 then
        local n = off[math.random(#off)]
        cl[n].login(); online[n] = true
      end
    else
      M.Advance(math.random(200, 800))
    end
    W.run(math.random(3, 40))
    local f = check(cl, step, seed)
    if f then firstFail = firstFail or f; break end
  end
  -- everybody back: the waiting claims come with the answers, the records settle
  for _, p in ipairs(PEOPLE) do if not online[full(p)] then cl[full(p)].login(); online[full(p)] = true end end
  M.Advance(700)
  for _, p in ipairs(PEOPLE) do cl[full(p)].ns.Guild.SyncNow(); cl[full(p)].ns.Friends.SyncNow() end
  W.run(200)
  local f = check(cl, STEPS + 1, seed)
  if f then firstFail = firstFail or f end
  for _, p in ipairs(PEOPLE) do
    local c = cl[full(p)]
    stats.claims = stats.claims + #K.claims(c)
    for _, x in ipairs(K.earned(c)) do
      stats.earned = stats.earned + 1
      if x.state == "sent" then stats.sent = stats.sent + 1 elseif x.state ~= "open" then stats.final = stats.final + 1 end
    end
  end
  M.errors = {}
end

H.erwartet("Invarianten im Zufallslauf", firstFail == nil, firstFail)
H.erwartet("der Lauf hat etwas getan", stats.kills > 0 and stats.claims > 0 and stats.earned > 0,
  stats.kills .. "/" .. stats.claims .. "/" .. stats.earned)
io.write(("  cl170 Zufall: %d Laeufe x %d Schritte (Saat %d): %d Kills, %d Kopfgelder, %d zurueck, %d Zustandswechsel, "
  .. "%d Abmeldungen; am Ende %d Ansprueche, %d Eintraege (%d abgeschlossen, %d unbestaetigt)\n"):format(RUNS, STEPS, SEED,
  stats.kills, stats.posts, stats.backs, stats.sets, stats.relogs, stats.claims, stats.earned, stats.final, stats.sent))
H.fertig()
