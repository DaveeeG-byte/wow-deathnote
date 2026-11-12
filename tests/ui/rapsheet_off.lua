-- 1.3.0 rap sheet switched off: the book looks as before the rap sheet's pages. The same scene (killers, own kills,
-- revenge by hand, a pardoned one) is built twice in the UI mock: once with the addon folder of BASE (the book of 1.2.2
-- with the theme core and the data of the rap sheet, read with git archive), once with these files and the switch
-- ledger.enabled off. Every visible text, texture and their places in the list, on every poster, in the game tooltip
-- and in the alarm popup must be the same. Only difference allowed: "Last seen" may name the zone (item 4 of the
-- package, independent of the switch). Needs the repository. All names are invented.
-- Call from the project root: luajit tests/ui/rapsheet_off.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local BASE = "135c24b"
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/rapsheet_off.lua"

local OLD = os.tmpname()
os.remove(OLD)
os.execute('mkdir -p "' .. OLD .. '" && git -C "' .. DIR .. '" archive ' .. BASE .. ' DeathNote | tar -x -C "' .. OLD .. '" 2>/dev/null')
OLD = OLD .. "/DeathNote/"
assert(io.open(OLD .. "UI.lua"), "git archive " .. BASE .. " (needs the repository)")

local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1 else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local ME = "Player-93-0000AAAA"
local function run(addon, code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = DIR .. "/DeathNote/Media"
  BM.measure = true
  local G = BM.G
  AM.locale = code
  local files = {}
  for _, f in ipairs(AM.Files()) do if io.open(addon .. f) then files[#files + 1] = f end end
  local ns = AM.Load({ noLogin = true, dir = addon, files = files, db = { settings = { ledger = { enabled = false } } } })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do BM.Load(addon .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
  local GT = G.GameTooltip
  GT.SetOwner = function(self) self._lines = {} end
  GT.SetText = function(self, t) self._lines = { t } end
  GT.AddLine = function(self, t) self._lines = self._lines or {}; self._lines[#self._lines + 1] = t end
  AM.units.player.level = 40
  local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  tick(30); settle()
  local t0 = _G.time()
  local function killsMe(name, surname, n)
    for i = 1, n do
      ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
        { t = t0 - 3000 * i, zone = "Schlingendorntal" }, true)
    end
    return ns.Util.KeyFor(name, surname)
  end
  local keys = { killsMe("Olaf", "Offen", 3), killsMe("Erna", "Eben", 2), killsMe("Udo", "Ueber", 1), killsMe("Paul", "Pur", 2) }
  ns.Store.AddRevenge(keys[1], true)
  ns.Store.AddRevenge(keys[2], true); ns.Store.AddRevenge(keys[2], true)
  ns.Store.AddRevenge(keys[3], true); ns.Store.AddRevenge(keys[3], true)
  ns.Store.SetStatus(keys[4], "pardoned")
  -- own killing blows (booked by the rap sheet's data even while... no: the switch is off, nothing is booked)
  local plate = 0
  for _, x in ipairs({ { "Olaf", "Offen" }, { "Viktor", "Vogt" } }) do
    plate = plate + 1
    local guid = "Player-93-" .. x[1] .. x[2]
    AM.AddEnemy("nameplate" .. plate, { name = x[1], surname = x[2], level = 40, guid = guid, class = "MAGE" })
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
    AM.FireEvent("PARTY_KILL", ME, guid); tick(61)
  end
  settle()
  local L = ns.L
  local seenPrefix = (L.POSTER_LAST_SEEN:match("^(.-){") or L.POSTER_LAST_SEEN)
  local seenPrefix2 = L.POSTER_LAST_SEEN_IN and (L.POSTER_LAST_SEEN_IN:match("^(.-){") or L.POSTER_LAST_SEEN_IN)
  local out = {}
  local function under(f, anc) local o = f; while o do if o == anc then return true end o = o._parent end return false end
  local function snap(view, root)
    local list = {}
    for _, f in ipairs(BM.frames) do
      if (f._kind == "FontString" or f._kind == "Texture") and under(f, root) and f:IsVisible() and (f._alpha or 1) > 0.05 then
        local l, b, r, t = BM.RectUI(f)
        local rect = l and ("%d,%d,%d,%d"):format(math.floor(l + 0.5), math.floor(b + 0.5), math.floor(r + 0.5), math.floor(t + 0.5)) or "-"
        if f._kind == "FontString" and type(f._text) == "string" and f._text ~= "" then
          local txt = f._text
          if txt:find(seenPrefix, 1, true) == 1 or (seenPrefix2 and txt:find(seenPrefix2, 1, true) == 1) then txt = "(last seen)"; rect = "-" end
          list[#list + 1] = ("T %s|%s|%s"):format(txt, rect, tostring(f._fontSize))
        elseif f._kind == "Texture" and (f._tex or f._color) then
          list[#list + 1] = ("X %s|%s"):format(tostring(f._tex), rect)
        end
      end
    end
    table.sort(list)
    out[view] = list
  end
  ns:Fire("TOGGLE_UI"); tick(); settle()
  local F = rawget(G, "DeathNoteFrame")
  snap("list", F)
  for i, k in ipairs(keys) do ns.UI.ShowEnemy(k); tick(); settle(); snap("poster " .. i, F) end
  for _, x in ipairs({ { "Olaf", "Offen" }, { "Erna", "Eben" }, { "Viktor", "Vogt" } }) do
    GT._unitName, GT._unit, GT._lines = x[1], "mouseover", {}
    AM.AddEnemy("mouseover", { name = x[1], surname = x[2], guid = "Player-93-" .. x[1] .. x[2], level = 40, class = "ROGUE" })
    if BM.tooltipHook then BM.tooltipHook(GT, {}) end
    out["tooltip " .. x[1]] = { table.concat(GT._lines or {}, "\n") }
  end
  ns:Fire("TOGGLE_UI"); tick()
  AM.AddEnemy("target", { name = "Erna", surname = "Eben", guid = "Player-93-ErnaEben", level = 40, class = "ROGUE" })
  AM.FireEvent("PLAYER_TARGET_CHANGED"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  out.alarm = { popup and popup.title._text or "-", popup and popup.line._text or "-" }
  local errs = #AM.errors + #BM.violations
  return out, errs, AM.errors[1] or BM.violations[1]
end

for _, code in ipairs({ "deDE", "enUS", "ruRU" }) do
  local A, ea, wa = run(OLD, code)
  local B, eb, wb = run(DIR .. "/DeathNote/", code)
  check(code .. ": no errors", ea == 0 and eb == 0, tostring(wa or wb))
  local views = {}
  for v in pairs(A) do views[#views + 1] = v end
  table.sort(views)
  for _, v in ipairs(views) do
    local a, b = A[v] or {}, B[v] or {}
    local diff
    for i = 1, math.max(#a, #b) do
      if a[i] ~= b[i] then diff = ("%s\n        before: %s\n        now:    %s"):format(i, tostring(a[i]), tostring(b[i])); break end
    end
    check(("%s: %s as before (%d elements)"):format(code, v, #a), diff == nil, diff)
  end
end
io.write(("rap sheet off = book as before: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
