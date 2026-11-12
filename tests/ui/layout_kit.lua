-- Shared kit of the 1.2.2 layout proofs (tests/ui/layout_fixes.lua, tests/ui/layout_red_probes.lua): a fresh world of
-- the UI mock per language with measured widths, time, hover and checks. Not a test itself.
-- Use: local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "name of the caller")
return function(dir, name)
  local DIR = (dir or "."):gsub("/+$", "")
  package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
  arg[0] = DIR .. "/tests/ui/" .. (name or "layout_kit") .. ".lua"
  local ADDON = DIR .. "/DeathNote"
  local K = { ok = 0, bad = 0, DIR = DIR, ADDON = ADDON }
  function K.check(name, cond, info)
    if cond then K.ok = K.ok + 1
    else K.bad = K.bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
  end
  -- a fresh world in one language with one friend online ("Fritz Frei"); opts.before(AM, BM) runs before the addon
  -- loads (font factors of the mock, another friends' list)
  function K.world(code, opts)
    opts = opts or {}
    package.loaded.mock_wow, package.loaded.mock = nil, nil
    local AM = require("mock_wow")
    local BM = require("mock")
    BM.mediaDir = ADDON .. "/Media"
    BM.measure = true
    BM.trace = true
    K.AM, K.BM, K.G = AM, BM, BM.G
    AM.locale = code
    local FR = { "Fritz Frei" }
    local ns = AM.Load({ noLogin = true, before = function()
      AM.units.player.guild = "Die Wuchtwaldwallwaechter"
      _G.C_FriendList = {
        GetNumFriends = function() return #FR end,
        GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
        ShowFriends = function() end,
      }
      if opts.before then opts.before(AM, BM) end
    end })
    for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
      if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
    end
    AM.FireEvent("PLAYER_LOGIN")
    AM.FireEvent("PLAYER_ENTERING_WORLD")
    -- tooltip that keeps its lines
    local GT = BM.G.GameTooltip
    GT.SetOwner = function(self, o) self._lines = {}; self._owner = o end
    GT.SetText = function(self, t) self._lines = { t } end
    GT.AddLine = function(self, t) self._lines = self._lines or {}; self._lines[#self._lines + 1] = t end
    GT.AddDoubleLine = function(self, a, b) self._lines = self._lines or {}; self._lines[#self._lines + 1] = tostring(a) .. "  " .. tostring(b) end
    K.ns = ns
    return ns
  end
  function K.tick(s) K.AM.Advance(s or 0.1); K.BM.Advance(s or 0.1) end
  function K.settle() local BM = K.BM; BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function K.find(pred) for _, f in ipairs(K.BM.frames) do if pred(f) then return f end end end
  function K.gmsg(text, from) K.AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  function K.whisper(text, from) K.AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from) end
  function K.under(f, anc) local o = f; while o do if o == anc then return true end o = o._parent end return false end
  -- text of the tooltip while hovering owner
  function K.hover(owner)
    local GT = K.G.GameTooltip
    GT._lines = {}
    local f = owner._scripts and owner._scripts.OnEnter
    if f then f(owner) end
    local s = table.concat(GT._lines or {}, "\n")
    local g = owner._scripts and owner._scripts.OnLeave
    if g then pcall(g, owner) end
    return s
  end
  function K.plain(s) return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
  function K.done(title)
    io.write(("%s: %d green, %d red\n"):format(title, K.ok, K.bad))
    os.exit(K.bad == 0 and 0 or 1)
  end
  return K
end
