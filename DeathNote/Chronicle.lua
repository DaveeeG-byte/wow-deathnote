-- DeathNote - Chronicle.lua (1.5.0 scene)
-- The feud's chronicle: one page of the file per enemy that tells the story in sentences, built only from what the book
-- already keeps: his deeds (kills, assists, suspicions, attacks: each called by its own name), my own kills on him from
-- the rap sheet's log, revenge noted by hand, the day he was written in or copied, bounties, who took him down for the
-- others, the turning points of the standing (even, ahead) and a closing line with the standing.
-- Data and words only (no frames): the book (UI.lua) shows the lines; a line with a place carries it (`place`) so the
-- book can show it on the map (SceneMap.lua). Sentences come from building blocks per language (Locales, block
-- "-- 1.5.0 scene"); the same sentence never stands twice in a row (each kind has a second wording); long feuds are cut
-- in the middle ("… and 9 more"). Names come from the entry (first name), never from a key.

local ADDON, ns = ...
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local IsSecret = Util.IsSecret

local Chronicle = {}
ns.Chronicle = Chronicle

Chronicle.HEAD_KEEP = 3   -- the oldest lines kept when a feud is long ...
Chronicle.TAIL_KEEP = 10  -- ... and the newest; the ones between become "… and n more"
Chronicle.MAX = Chronicle.HEAD_KEEP + Chronicle.TAIL_KEEP + 1   -- story lines (without first and last) before cutting
Chronicle.SAME = 60       -- seconds: a revenge noted by hand this close to an own kill of the log is that kill

local function num(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge and not IsSecret(v) end
local function str(v) return type(v) == "string" and not IsSecret(v) and v ~= "" and v or nil end

-- first name of a full name ("Grimwald Eisenbart" -> "Grimwald")
local function first(name)
  name = str(name)
  return name and (name:match("^(%S+)") or name) or "?"
end

-- the day: "11/10" (year when it is not the current one)
function Chronicle.Day(t)
  if not num(t) then return "?" end
  local d, now = rawget(_G, "date") or (os and os.date), rawget(_G, "time") or (os and os.time)
  local other = false
  if d and now then
    local ok, a, b = pcall(function() return d("%Y", t), d("%Y", now()) end)
    other = ok and a ~= b
  end
  local key = other and "TIME_FMT_DAY_YEAR" or "TIME_FMT_DAY"
  if Util.FmtDate then return Util.FmtDate(key, t) end
  return "?"
end

-- the place of a deed as a table the map understands (nil without any place)
local function placeOf(d)
  if type(d) ~= "table" then return nil end
  local z, sz = str(d.zone), str(d.subzone)
  if not z and not sz and not num(d.mapID) then return nil end
  return { zone = z, subzone = sz, mapID = num(d.mapID) and d.mapID or nil, x = num(d.x) and d.x or nil,
    y = num(d.y) and d.y or nil, t = d.t }
end
local function placeWord(p)
  return p and (p.subzone or p.zone) or nil
end

-- "11/10, Grom'gol:" in front of a sentence
local function at(t, p)
  local w = placeWord(p)
  if w then return Fmt(L.CHRON_AT, { date = Chronicle.Day(t), place = w }) end
  return Fmt(L.CHRON_AT_DAY, { date = Chronicle.Day(t) })
end

-- the sentence keys per kind: first wording, second wording (never the same twice in a row)
local WORDS = {
  kill = { "CHRON_KILL", "CHRON_KILL_AGAIN" }, assist = { "CHRON_ASSIST", "CHRON_ASSIST_AGAIN" },
  suspect = { "CHRON_SUSPECT", "CHRON_SUSPECT_AGAIN" }, attack = { "CHRON_ATTACK", "CHRON_ATTACK_AGAIN" },
  mine = { "CHRON_MINE", "CHRON_MINE_AGAIN" }, hand = { "CHRON_HAND", "CHRON_HAND_AGAIN" },
}

-- the role of a deed as the book reads it (older deeds without role: sure = kill)
local function roleOf(d)
  local r = d.role
  if r == "kill" or r == "assist" or r == "suspect" or r == "attack" then return r end
  return d.sure == true and "kill" or "suspect"
end

-- all events of the feud, oldest first: { t, kind, d (deed or log row), place }
local function events(key, e)
  local out = {}
  for i = 1, #(type(e.deaths) == "table" and e.deaths or {}) do
    local d = e.deaths[i]
    if type(d) == "table" and num(d.t) then out[#out + 1] = { t = d.t, kind = roleOf(d), d = d, place = placeOf(d) } end
  end
  local Lg = ns.Ledger
  local mineT = {}
  if Lg and Lg.Log then
    local ok, log = pcall(Lg.Log)
    if ok and type(log) == "table" then
      for i = 1, #log do
        local row = log[i]
        if type(row) == "table" and row.key == key and num(row.t) then
          out[#out + 1] = { t = row.t, kind = "mine", d = row, place = placeOf(row) }
          mineT[#mineT + 1] = row.t
        end
      end
    end
  end
  if type(e.revengeHandAt) == "table" then
    for i = 1, #e.revengeHandAt do
      local t = e.revengeHandAt[i]
      local same = false
      for k = 1, #mineT do if num(t) and math.abs(mineT[k] - t) <= Chronicle.SAME then same = true end end
      if num(t) and not same then out[#out + 1] = { t = t, kind = "hand" } end
    end
  end
  if e.manual == true and num(e.listedAt) then out[#out + 1] = { t = e.listedAt, kind = "listed" } end
  if num(e.adoptAt) then out[#out + 1] = { t = e.adoptAt, kind = "copied" } end
  local G = ns.Guild
  if G and G.Bounties then
    local ok, rows = pcall(G.Bounties, key)
    if ok and type(rows) == "table" then
      for i = 1, #rows do
        local r = rows[i]
        if type(r) == "table" and num(r.t) and num(r.g) and r.g > 0 then out[#out + 1] = { t = r.t, kind = "bounty", d = r } end
      end
    end
  end
  -- oldest first; the same second: deeds on me before my answer
  local ORDER = { listed = 1, copied = 1, kill = 2, assist = 2, suspect = 2, attack = 2, mine = 3, hand = 3, bounty = 4 }
  table.sort(out, function(a, b)
    if a.t ~= b.t then return a.t < b.t end
    return (ORDER[a.kind] or 9) < (ORDER[b.kind] or 9)
  end)
  return out
end

-- the standing state for the turning points
local function stateOf(m, h)
  if m > h then return "ahead" end
  if m == h and m > 0 then return "even" end
  return "open"
end

-- Builds the chronicle of a book entry. Returns { name = full name, lines = { { text, place } }, cut = n } or nil.
-- The first line is the first encounter, the last one the standing now.
function Chronicle.Build(key)
  local S = ns.Store
  local e = S and type(key) == "string" and not IsSecret(key) and S.Get(key)
  if type(e) ~= "table" then return nil end
  local full = Util.Display(e)
  local name = first(full)
  local list = events(key, e)
  local lines = {}
  local Lg = ns.Ledger
  local standing
  if Lg and Lg.Standing then
    local ok, sm, sh = pcall(Lg.Standing, key)
    if ok and num(sm) and num(sh) then standing = { sm, sh } end
  end

  -- first encounter
  if #list > 0 then
    local f = list[1]
    local w = placeWord(f.place)
    lines[1] = { text = w and Fmt(L.CHRON_FIRST, { date = Chronicle.Day(f.t), place = w })
      or Fmt(L.CHRON_FIRST_DAY, { date = Chronicle.Day(f.t) }), place = f.place }
  end

  -- 1.5.0 fixer: the book keeps at most 30 deeds of an enemy and 60 rows of the log, the counters go on. The turning
  -- points are only told when the kept deeds add up to the standing (else they would claim an "even" that never was);
  -- a shortened story says so once and takes the standing from the counters (the last line).
  local hc, mc = 0, 0
  for _, ev in ipairs(list) do
    if ev.kind == "kill" then hc = hc + 1 elseif ev.kind == "mine" or ev.kind == "hand" then mc = mc + 1 end
  end
  local whole = true
  if standing then
    whole = hc == standing[2] and mc == standing[1]
  end
  local shortened = hc < (tonumber(e.kills) or 0) or (standing ~= nil and mc < standing[1])
  if shortened and lines[1] then
    -- the first encounter from the entry's counter when it is older than the oldest deed kept, then the honest note
    local fk = e.firstKill
    if num(fk) and list[1] and fk < list[1].t then
      lines[1] = { text = Fmt(L.CHRON_FIRST_DAY, { date = Chronicle.Day(fk) }) }
    end
    lines[#lines + 1] = { text = L.CHRON_EARLIER }
  end

  local story = {}
  local lastWord = nil
  local m, h, st = 0, 0, "open"
  local firstMine = true
  for _, ev in ipairs(list) do
    local k = ev.kind
    local text
    if WORDS[k] then
      local words = WORDS[k]
      local key1 = (lastWord == words[1]) and words[2] or words[1]
      if k == "mine" and firstMine then key1 = "CHRON_MINE_FIRST"
      elseif k == "kill" and str(ev.d and ev.d.spell) and lastWord ~= "CHRON_KILL_SPELL" then key1 = "CHRON_KILL_SPELL" end
      if k == "mine" then firstMine = false end
      text = Fmt(L[key1], { name = name, spell = str(ev.d and ev.d.spell) or "" })
      lastWord = key1
    elseif k == "listed" then
      text = Fmt(L.CHRON_LISTED, { name = name }); lastWord = "CHRON_LISTED"
    elseif k == "copied" then
      local from = str(e.adoptFrom)
      text = from and Fmt(L.CHRON_COPIED, { from = from }) or L.CHRON_COPIED_ANON; lastWord = "CHRON_COPIED"
    elseif k == "bounty" then
      local r = ev.d
      local gold = Util.Money and Util.Money(r.g * 10000) or tostring(r.g)
      if r.mine then text = Fmt(L.CHRON_BOUNTY_MINE, { name = name, gold = gold })
      else text = Fmt(L.CHRON_BOUNTY, { name = name, gold = gold, by = first(r.char) }) end
      lastWord = "CHRON_BOUNTY"
    end
    if text then
      story[#story + 1] = { text = at(ev.t, ev.place) .. " " .. text, place = ev.place }
      -- turning points: only while the rap sheet counts (the book's standing)
      if standing and whole then
        if k == "kill" then h = h + 1 elseif k == "mine" or k == "hand" then m = m + 1 end
        local now = stateOf(m, h)
        if now ~= st and (k == "kill" or k == "mine" or k == "hand") then
          st = now
          if now == "even" or now == "ahead" then
            story[#story + 1] = { text = Fmt(now == "even" and L.CHRON_EVEN or L.CHRON_AHEAD, { score = m .. " : " .. h }) }
          end
        end
      end
    end
  end
  local cut = 0
  if #story > Chronicle.MAX then
    cut = #story - Chronicle.HEAD_KEEP - Chronicle.TAIL_KEEP
    local short = {}
    for i = 1, Chronicle.HEAD_KEEP do short[#short + 1] = story[i] end
    short[#short + 1] = { text = Fmt(L.MORE_LINE, { count = cut }), more = true }
    for i = #story - Chronicle.TAIL_KEEP + 1, #story do short[#short + 1] = story[i] end
    story = short
  end
  for i = 1, #story do lines[#lines + 1] = story[i] end

  -- who took him down for the others (Bounty.lua), pardoned, the standing now
  local G = ns.Guild
  if G and G.Avenged then
    local ok, rows = pcall(G.Avenged, key)
    if ok and type(rows) == "table" and #rows > 0 then
      local names = {}
      for i = 1, math.min(#rows, 3) do names[i] = first(rows[i].char) end
      local s = table.concat(names, ", ")
      if #rows > 3 then s = s .. " " .. Fmt(L.MORE_LINE, { count = #rows - 3 }) end
      -- 1.5.0 fixer: one avenger or several (the sentence of each language has no verb that counts them)
      lines[#lines + 1] = { text = Fmt(L.CHRON_AVENGED, { name = name, names = s, count = #rows }) }
    end
  end
  if e.status == "pardoned" then lines[#lines + 1] = { text = Fmt(L.CHRON_PARDONED, { name = name }) } end
  if standing then
    local m2, h2 = standing[1], standing[2]
    local stw = ({ open = "STATE_OPEN", even = "STATE_EVEN", ahead = "STATE_AHEAD" })[stateOf(m2, h2)]
    lines[#lines + 1] = { text = Fmt(L.CHRON_END, { score = m2 .. " : " .. h2, state = L[stw] or "" }), last = true }
  else
    lines[#lines + 1] = { text = Fmt(L.CHRON_END_NONE, { name = name, times = Fmt(L.TIMES, { count = tonumber(e.kills) or 0 }) }),
      last = true }
  end
  if #lines == 1 then table.insert(lines, 1, { text = L.CHRON_EMPTY }) end
  return { name = full, lines = lines, cut = cut }
end
