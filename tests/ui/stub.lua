-- Vertrags-Stub: ns mit Bus, ns.Store, ns.Util, ns.Tracker so wie in regeln-staatsfeind.md beschrieben.
-- Bewusst einfach; die echte Logik testet Bauer A. Fehler in Bus-Handlern werden gesammelt.

return function(M)
  local ns = {}
  local handlers, wow = {}, {}
  ns.errors = {}

  function ns:On(ev, fn) handlers[ev] = handlers[ev] or {}; table.insert(handlers[ev], fn) end
  function ns:Fire(ev, ...)
    for _, fn in ipairs(handlers[ev] or {}) do
      local ok, err = xpcall(fn, debug.traceback, ...)
      if not ok then table.insert(ns.errors, ev .. ": " .. tostring(err)) end
    end
  end
  function ns:RegisterEvent(ev, fn) wow[ev] = wow[ev] or {}; table.insert(wow[ev], fn); return true end
  function ns:FireWow(ev, ...)
    for _, fn in ipairs(wow[ev] or {}) do
      local ok, err = xpcall(fn, debug.traceback, ev, ...)
      if not ok then table.insert(ns.errors, ev .. ": " .. tostring(err)) end
    end
  end

  local db = {
    settings = {
      alert = { enabled = true, sound = true, cooldown = 90, flash = true, minKills = 1, suspects = false },
      ui = { scale = 1, sort = "rank", minimap = { hide = false, angle = 215 } },
      deathMessage = true, tooltip = true, debug = false,
    },
    enemies = {}, deaths = {},
  }
  ns.db = db

  ------------------------------------------------------------------ Util
  local U = {}
  ns.Util = U
  ns.units = {}      -- unit -> key (oder "SECRET_NAME" fuer ein Secret)
  function U.KeyFor(n, r) return n .. "-" .. (r or "X") end
  function U.SplitKey(k) return k:match("^([^%-]+)%-(.*)$") end
  function U.KeyOfUnit(unit)
    local k = ns.units[unit]
    if not k or M.secrets[k] then return nil end
    return k
  end
  function U.IsSecret(v) return M.secrets[v] == true end
  function U.Safe(v, alt) if M.secrets[v] then return alt end return v end
  function U.ClassColor(c) if c == "ROGUE" then return 1, 0.96, 0.41 end return 0.75, 0.75, 0.75 end
  function U.Ago(t) if type(t) ~= "number" then return "nie" end return "vor 2 Tagen" end
  function U.Money(c) return math.floor((c or 0) / 10000) .. "g" end
  function U.Zone() return "Schlingendorntal", "Grom'gol", 1434, 30.1, 40.2 end
  function U.Print() end
  function U.Display(e) if e.surname then return e.name .. " " .. e.surname end return e.display or e.name end
  function U.TargetName(e) if e.surname then return e.name .. " " .. e.surname end return e.name end
  ns.nameplates = true
  function U.NameplatesOn() return ns.nameplates end

  ------------------------------------------------------------------ Tracker
  ns.Tracker = { UnitFor = function(key)
    for u, k in pairs(ns.units) do if k == key then return u end end
  end }

  ------------------------------------------------------------------ Store
  local S = {}
  ns.Store = S
  local function changed(key) ns:Fire("ENEMY_UPDATED", key) end
  function S.Get(k) return db.enemies[k] end
  function S.All() return db.enemies end
  -- Vertrag 1.1.0 (Gesamtschau): Count mit offenen Faellen, OpenCases, Weight; ns.oldLogic = true
  -- schaltet die neuen Funktionen ab (aeltere Logik ohne Vertrag darf nichts werfen)
  local function isOpen(j)
    return type(j) == "table" and j.kind == "pvp" and j.killerKey == nil and j.counted ~= false
      and type(j.candidates) == "table" and #j.candidates > 0
  end
  function S.Count()
    local w, s, p = 0, 0, 0
    for _, e in pairs(db.enemies) do
      if e.status == "wanted" then w = w + 1 elseif e.status == "suspect" then s = s + 1 else p = p + 1 end
    end
    if ns.oldLogic then return w, s, p end
    local o = 0
    for _, j in ipairs(db.deaths) do if isOpen(j) then o = o + 1 end end
    return w, s, p, o
  end
  S.openCalls = 0
  function S.OpenCases()
    if ns.oldLogic then error("OpenCases gibt es in der alten Logik nicht") end
    S.openCalls = S.openCalls + 1
    local out = {}
    for _, j in ipairs(db.deaths) do if isOpen(j) then out[#out + 1] = j end end
    return #out, out
  end
  function S.Weight(e) return (e.kills or 0) + (e.assists or 0) end
  function S.Ranked(filter, sort)
    local out = {}
    for _, e in pairs(db.enemies) do
      if filter == "all" or e.status == filter then out[#out + 1] = e end
    end
    table.sort(out, function(a, b)
      if sort == "name" then return a.name < b.name end
      if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
      if (a.assists or 0) ~= (b.assists or 0) then return (a.assists or 0) > (b.assists or 0) end
      return a.key < b.key
    end)
    return out
  end
  function S.Rank(key)
    local list = S.Ranked("wanted", "rank")
    for i, e in ipairs(list) do if e.key == key then return i end end
  end
  function S.Bounty(e) return ((e.kills or 0) * 5 + (e.revenge or 0)) * 10000 end
  function S.AddManual(name, realm)
    local k = U.KeyFor(name, realm)
    db.enemies[k] = { key = k, name = name, realm = realm, status = "wanted", kills = 0, manual = true, deaths = {} }
    changed(k); return k
  end
  function S.Remove(k) db.enemies[k] = nil; changed(k) end
  function S.SetNote(k, t) local e = db.enemies[k]; if e then e.note = t; changed(k) end end
  function S.SetStatus(k, st) local e = db.enemies[k]; if e then e.status = st; changed(k) end end
  function S.ConfirmSuspect(k) local e = db.enemies[k]; if e then e.status = "wanted"; e.kills = (e.kills or 0) + 1; changed(k) end end
  function S.DismissSuspect(k) db.enemies[k] = nil; changed(k) end
  function S.AddRevenge(k)
    local e = db.enemies[k]
    if e then e.revenge = (e.revenge or 0) + 1; ns:Fire("REVENGE", k); changed(k) end
  end
  function S.Deaths() return db.deaths end
  function S.AssignDeath(i, k) local d = db.deaths[i]; if d then d.killerKey = k; d.sure = true; changed(k) end; return true end
  -- ns.bigExport: grosses Buch (ueber 100 KB mit Taten); ns.exportShort = false: alte Store-Fassung,
  -- die das Argument "kurz" nicht kennt
  function S.Export(short)
    if not ns.bigExport then return "DEATHNOTE1\nGrimmzahn-Probe;3" end
    local t = { "DEATHNOTE:1" }
    local kurz = short == true and ns.exportShort ~= false
    for i = 1, 200 do
      t[#t + 1] = "E|Feind" .. i .. "-X|wanted|0|3"
      if not kurz then
        for d = 1, 20 do t[#t + 1] = "D|Feind" .. i .. "-X|" .. (1800000000 - d) .. "|1|recap|Schlingendorntal|Grom'gol" end
      end
    end
    return table.concat(t, "\n")
  end
  function S.Import(text)
    if text == "BOOM" then error("Importfehler") end
    if text == "" then return false, "Kein Text." end
    return true, 2, 1
  end
  -- wie Store.lua: Eintrag zieht auf einen neuen Schluessel um (gleiche GUID, vollerer Name)
  function S.Rekey(old, new, surname)
    local e = db.enemies[old]
    if not e or db.enemies[new] then return end
    db.enemies[old] = nil
    db.enemies[new] = e
    e.key = new
    if surname then e.surname = surname end
    ns:Fire("ENEMY_REKEYED", old, new)
    changed(old); changed(new)
  end
  function S.Find() return nil end
  function S.Setting(path, ...)
    local t = db.settings
    local parts = {}
    for p in path:gmatch("[^%.]+") do parts[#parts + 1] = p end
    for i = 1, #parts - 1 do
      if type(t[parts[i]]) ~= "table" then
        if select("#", ...) == 0 then return nil end
        t[parts[i]] = {}
      end
      t = t[parts[i]]
    end
    if select("#", ...) == 0 then return t[parts[#parts]] end
    t[parts[#parts]] = (...)
    ns:Fire("SETTINGS_CHANGED", path)
  end

  ------------------------------------------------------------------ Guild (Schnittstelle aus Sync.lua)
  -- ns.MakeGuild(n[, opts]) legt ns.Guild mit n Beispiel-Gildenfeinden an; ns.Guild = nil = ohne Sync.lua
  function ns.MakeGuild(n, opts)
    opts = opts or {}
    local G = { calls = {}, synced = 0, cleared = 0, adopted = {} }
    G.name = opts.name == nil and "Die Schlächter von Sturmwind" or opts.name or nil
    if opts.noguild then G.name = nil end
    G.enabled = opts.enabled ~= false
    G.cooldown = opts.cooldown
    local victimsPool = { "Varorak", "Bohnenjockel", "Narenmarsen", "Hühnerbein", "Knäckebrot" }
    local list = {}
    for i = 1, n do
      local deeds = {}
      for d = 1, (i % 7) + 1 do
        deeds[d] = { t = 1800000000 - d * 3600 - i, zone = (d % 2 == 0) and "Schlingendorntal" or "Nesingwarys Expedition",
                     victim = victimsPool[(d + i) % #victimsPool + 1], level = 30 + d }
      end
      local victims, vc = {}, 0
      for _, d in ipairs(deeds) do
        if not victims[d.victim] then vc = vc + 1 end
        victims[d.victim] = (victims[d.victim] or 0) + 1
      end
      list[i] = { key = "Gilde" .. i .. "-Feind" .. i, name = "Gilde" .. i, surname = "Feind" .. i,
                  display = "Gilde" .. i .. " Feind" .. i, class = (i % 2 == 0) and "WARRIOR" or "PRIEST",
                  level = 40, kills = (i == 1 and 23) or math.max(1, 21 - i), victims = victims, victimCount = vc,
                  lastKill = deeds[1].t, lastZone = deeds[1].zone, lastVictim = deeds[1].victim, deeds = deeds,
                  lastSeen = (i % 3 == 0) and { t = 1800000000 - 120, zone = "Schlingendorntal", by = "Bohnenjockel" } or nil,
                  mine = false }
    end
    -- reine Hand-Eintraege (Schnittstelle 1.1.0): kills = 0, listedBy, listedOnly
    for k = 1, (opts.listed or 0) do
      local e = { key = "Hand" .. k .. "-Eintrag" .. k, name = "Hand" .. k, surname = "Eintrag" .. k,
                  display = "Hand" .. k .. " Eintrag" .. k, class = "MAGE", kills = 0, deeds = {}, victims = {},
                  victimCount = 0, listedBy = { Moppel = 1800000000 - 3 * 86400 }, listedCount = 1,
                  lastListed = 1800000000 - 3 * 86400, listedOnly = true, mine = false }
      if k == 1 then
        e.listedBy["Hühnerbein"] = 1800000000 - 86400
        e.listedBy["Knäckebrot"] = 1800000000 - 3600
        e.listedCount = 3
      end
      if opts.listedFirst then table.insert(list, 1, e) else list[#list + 1] = e end
    end
    if opts.mixedListed then
      for _, e in ipairs(list) do
        if e.key == "Gilde1-Feind1" then e.listedBy = { Moppel = 1800000000 - 7200 }; e.listedCount = 1 end
      end
    end
    G.list = list
    -- ByMember: eigener Char zuerst (auch leer), dann nach Toden; Zeilen aus der Liste verteilt
    G.byMemberCalls = 0
    if opts.members ~= nil then
      function G.Touch() G._bym = nil end
      function G.ByMember()
        G.byMemberCalls = G.byMemberCalls + 1
        if G._bym then return G._bym end
        local out = {}
        local nm = opts.members
        out[1] = { name = "Davee", me = true, deaths = 0, killers = 0, listed = 0, rows = {}, hasAddon = true }
        for j = 2, nm do
          out[j] = { name = "Kollege" .. j, me = false, deaths = 0, killers = 0, listed = 0, rows = {}, hasAddon = true,
                     lastHeard = 1800000000 - j * 60 }
        end
        if opts.noAddon then out[#out + 1] = { name = "Ohneaddon", me = false, deaths = 0, killers = 0, rows = {}, hasAddon = false } end
        if nm > 0 then
          for i, e in ipairs(list) do
            if e.listedOnly then
              local m = out[1]
              if nm > 1 then m = out[2] end
              m.rows[#m.rows + 1] = { key = e.key, entry = e, kills = 0, listed = true, listedAt = e.lastListed }
              m.listed = m.listed + 1
            else
              local j = ((i - 1) % nm) + 1
              if opts.meEmpty and j == 1 and nm > 1 then j = 2 end
              local m = out[j]
              local kills = (i % 3) + 1
              m.rows[#m.rows + 1] = { key = e.key, entry = e, kills = kills, lastKill = e.lastKill, lastZone = e.lastZone, listed = false }
              m.killers, m.deaths = m.killers + 1, m.deaths + kills
              m.lastDeath = math.max(m.lastDeath or 0, e.lastKill or 0)
            end
          end
        end
        G._bym = out
        return out
      end
    end
    local function find(key) for _, e in ipairs(list) do if e.key == key then return e end end end
    function G.Enabled() return G.enabled end
    function G.Name() return G.name end
    function G.List(sort, opts)
      G.calls[#G.calls + 1] = "List:" .. tostring(sort)
      for _, e in ipairs(list) do e.mine = db.enemies[e.key] ~= nil end
      if type(opts) == "table" and opts.foreign and not opts.noForeign then
        G._flist = G._flist or {}
        local f = G._flist
        for i = #f, 1, -1 do f[i] = nil end
        for _, e in ipairs(list) do if not e.ownOnly then f[#f + 1] = e end end
        return f
      end
      return list   -- wie Sync.lua: gecachte Liste, die Oberflaeche darf sie nicht veraendern
    end
    -- Teilen-Zustand; G.health = Tabelle ueberschreibt ihn, opts.noHealth = alte Logik ohne Health
    if not opts.noHealth then
      function G.Health()
        if G.health then return G.health end
        if not G.name then return { ok = false, reason = "noguild", text = "Du bist in keiner Gilde, es wird nichts geteilt.", short = "Keine Gilde" } end
        if not G.enabled then return { ok = false, reason = "off", text = "Teilen ist ausgeschaltet.", short = "Teilen ist aus" } end
        return { ok = true, reason = "ok", text = "Gesendet 4, empfangen 9.", short = "Angefragt" }
      end
    end
    function G.Get(key) local e = find(key); if e then e.mine = db.enemies[key] ~= nil end; return e end
    function G.Rank(key) for i, e in ipairs(list) do if e.key == key then return i end end end
    function G.Count()
      local d, l = 0, 0
      for _, e in ipairs(list) do d = d + #e.deeds; if e.listedOnly then l = l + 1 end end
      local f = 0
      for _, e in ipairs(list) do if not e.ownOnly then f = f + 1 end end
      if opts.noForeign then return #list, d, l end
      return #list, d, l, f
    end
    function G.Members()
      if opts.noMembers then return {} end
      return { { name = "Bohnenjockel", full = "Bohnenjockel-Forever", version = "1.0.0", lastHeard = 1800000000 - 60 },
               { name = "Varorak", full = "Varorak-Forever", version = "1.0.0", lastHeard = 1800000000 - 3600 },
               { name = "Narenmarsen", full = "Narenmarsen-Forever", version = "0.9.0", lastHeard = 1800000000 - 7200 },
               { name = "Hühnerbein", full = "Hühnerbein-Forever", version = "1.0.0", lastHeard = 1800000000 - 9000 },
               { name = "Knäckebrot", full = "Knäckebrot-Forever", version = "1.0.0", lastHeard = 1800000000 - 99000 } }
    end
    function G.SyncNow()
      G.synced = G.synced + 1
      if not G.enabled then return false, "aus" end
      if G.cooldown then return false, G.cooldown end
      return true, "gesendet"
    end
    function G.Clear() G.cleared = G.cleared + 1; for i = #list, 1, -1 do list[i] = nil end; G._bym = nil; ns:Fire("GUILD_UPDATED") end
    function G.Adopt(key)
      local e = find(key)
      if not e then return nil end
      G.adopted[#G.adopted + 1] = key
      local k = e.key
      db.enemies[k] = { key = k, name = e.name, surname = e.surname, status = "wanted", kills = 0, manual = true,
                        class = e.class, deaths = {} }
      ns:Fire("ENEMY_UPDATED", k)
      return k
    end
    function G.Setting(name)
      local v = S.Setting("guild." .. name)
      if v == nil then
        local d = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
                    shareManual = true, alertListed = false }
        return d[name]
      end
      return v
    end
    function G.QueueSize() return G.queue or 0 end
    function G.HoldReason() return G.hold end
    ns.Guild = G
    return G
  end

  ------------------------------------------------------------------ Sprache (1.2.0)
  -- Locale.lua und die Sprachdateien wie im Spiel vor Alert/UI laden, dann eine ausdrueckliche
  -- Wahl aktivieren (DN_LANG, Standard deDE: die bestehenden Pruefungen lesen deutsche Texte).
  M.LoadLocale(ns, os.getenv("DN_LANG") or "deDE")
  -- Zeitform aus der Sprachtabelle (Deutsch: "vor 2 Tagen", "nie" wie bisher)
  if ns.L and ns.F then
    function U.Ago(t) if type(t) ~= "number" then return ns.L.TIME_NEVER end return ns.F(ns.L.TIME_DAYS, { count = 2 }) end
  end

  return ns
end
