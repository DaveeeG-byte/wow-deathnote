-- 1.7.0 claim: shared world of the UI tests cu170_*.lua: the real logic (tests/mock_wow.lua) in a guild, the UI files
-- with FeudUI.lua through the UI mock, the width estimate of the proof tests, and a small stand-in for the wire
-- package exactly after decision E8 (ns.Claim.Earned / OpenEarned / Dismiss, ns.Bounty.Others). The tests lay the
-- data down themselves and fire the events (EARNED_NEW, EARNED_CHANGED, CLAIM_SETTLED) by hand.
-- Usage per test: luajit tests/ui/cu170_x.lua <project copy>. All names are made up.
local X = {}
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektkopie>"):gsub("/+$", "")
X.DIR = DIR
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/belege/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local K = dofile(DIR .. "/tests/belege/_kopf_ui.lua")
arg[0] = DIR .. "/tests/ui/cu170.lua"
X.K = K
X.CODES = K.CODES

local pass, fail = 0, 0
function X.check(name, cond, info)
  if cond then pass = pass + 1 else
    fail = fail + 1
    io.write("ROT ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n")
  end
end
function X.done(title)
  io.write(("%s: %d ok, %d rot\n"):format(title, pass, fail))
  os.exit(fail == 0 and 0 or 1)
end

local NONE = {}
-- the stand-in of the wire package (E8). opts.noClaim: no ns.Claim; opts.noOthers: no Bounty.Others
function X.fake(W, opts)
  opts = opts or {}
  local ns = W.ns
  local list = {}
  W.earned = list
  -- the real wire package is loaded since the merge: the stand-in replaces it (WouldTake: opts.takes, default true),
  -- noClaim and noOthers take the real ones away (an older logic)
  if opts.noClaim then ns.Claim = nil end
  if opts.noOthers and ns.Bounty then ns.Bounty.Others = nil end
  if not opts.noClaim then
    ns.Claim = {
      WouldTake = function() return opts.takes ~= false, opts.later end,   -- fixer: later = own char of the bounty
      Earned = function() return list end,
      OpenEarned = function()
        local n = 0
        for _, x in ipairs(list) do if type(x) == "table" and (x.state == "sent" or x.state == "open") then n = n + 1 end end
        return n
      end,
      Dismiss = function(x)
        for i = #list, 1, -1 do if list[i] == x then table.remove(list, i); return true end end
        return false
      end,
    }
  end
  local B = ns.Bounty
  if B and not opts.noOthers then
    W.othersCalls = 0
    B.Others = function(key)
      W.othersCalls = W.othersCalls + 1
      local rows = B.Rows(key)
      local out, sum = nil, 0
      for _, r in ipairs(rows) do
        if not r.own then out = out or {}; out[#out + 1] = r; sum = sum + r.g end
      end
      if not out then return 0, NONE end
      return sum, out
    end
  end
  if ns.Alert and ns.Alert.Watch then ns.Alert.Watch() end
  -- an entry of the shooter's list (E7), newest first, and its event
  function W.earn(x, silent)
    x.at = x.at or x.t
    table.insert(list, 1, x)
    if not silent then ns:Fire("EARNED_NEW", x) end
    return x
  end
  function W.change(x, st)
    local old = x.state
    x.state, x.at = st, _G.time()
    ns:Fire("EARNED_CHANGED", x, old)
  end
end

function X.world(code, opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = DIR .. "/DeathNote/Media"
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  local have = false
  for _, f in ipairs(files) do if f == "Share.lua" then have = true end end
  if not have then files[#files + 1] = "Share.lua" end
  local ns = AM.Load({ noLogin = true, db = opts.db, files = files, before = function()
    if opts.guild ~= false then AM.units.player.guild = "Die Testgilde" end
    _G.C_FriendList = {
      GetNumFriends = function() return 0 end,
      GetFriendInfoByIndex = function() end,
      ShowFriends = function() end,
    }
  end })
  -- one clock for logic and UI as in the client (the UI mock alone has a fixed one)
  local logicTime = _G.time
  BM.G.time = function() return logicTime() end
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "FeudUI.lua" }) do
    if io.open(DIR .. "/DeathNote/" .. f) then BM.Load(DIR .. "/DeathNote/" .. f, ns) end
  end
  local mt = getmetatable(BM.frames[1])
  local i = 1
  while true do
    local n, v = debug.getupvalue(mt.__index, i)
    if not n then break end
    if n == "methods" then v.GetStringWidth = function(self) return K.estimate(self) end end
    i = i + 1
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { ns = ns, AM = AM, BM = BM, G = BM.G, L = ns.L, P = ns.Guild and ns.Guild.Proto, F = ns.F }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
  function W.click(f, b) if f and f._scripts.OnClick then f._scripts.OnClick(f, b or "LeftButton") end; W.tick() end
  function W.gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  -- a bounty of a guildmate (first name, surname "Wurst") on key
  function W.bounty(key, first, gold, t)
    W.gmsg(W.P.EncodeBounty(key, first .. " Wurst", gold, t or (_G.time() - 60)), first .. " Wurst-Forever")
    W.tick(1)
  end
  function W.kill(name, surname, t)
    return ns.Store.ApplyKill({ name = name, surname = surname, class = "MAGE", level = 40, guid = "Player-93-" .. name .. surname },
      { t = t or (_G.time() - 600), zone = "Z", source = "recap" }, true)
  end
  function W.open() ns:Fire("TOGGLE_UI"); W.tick(); W.settle() end
  function W.kit() return ns.UI.Kit end
  function W.frames() return W.kit().Frames() end
  function W.find(text, kind)
    for _, f in ipairs(BM.frames) do
      if f.IsVisible and f:IsVisible() and (not kind or f._kind == kind) then
        if f._text == text then return f end
        if f.text and f.text._text == text and f.text:IsVisible() then return f end
      end
    end
  end
  function W.tab(id)
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts.OnClick then f._scripts.OnClick(f) end
    end
    W.tick()
  end
  function W.rows()
    local out = {}
    for _, f in ipairs(BM.frames) do
      if f._kind == "Button" and f.item ~= nil and f.rank and f.sub and f:IsVisible() then out[#out + 1] = f end
    end
    table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
    return out
  end
  function W.chatHas(s)
    for _, l in ipairs(AM.chat) do if tostring(l):find(s, 1, true) then return true end end
    return false
  end
  function W.chatCount(s)
    local n = 0
    for _, l in ipairs(AM.chat) do if tostring(l):find(s, 1, true) then n = n + 1 end end
    return n
  end
  function W.popup() return rawget(BM.G, "DeathNoteAlert") end
  function W.errs()
    local n = #AM.errors + #BM.violations
    local first = AM.errors[1] or BM.violations[1]
    return n, first
  end
  function W.spaced(s)
    local o = {}
    for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do o[#o + 1] = ch == " " and "  " or ch end
    return table.concat(o, " ")
  end
  W.tick(30); W.settle()
  return W
end

return X
