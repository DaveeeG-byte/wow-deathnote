-- Fixer 1.7.0: copy of the head of the hunt tests ju*.lua (dev/berichte/170/jagd-tests/_ju.lua), for the tests fx170_*.lua.
-- Aufruf je Test: luajit ju01_x.lua <Projektpfad>. Exit 1, solange der Fund besteht. Alle Namen sind erfunden.
-- Zwei Welten:
--   J.welt(code)        eine Welt mit mehreren Clients und der ECHTEN Leitung (Claim.lua, Sync.lua, Bounty.lua);
--                       J.client(W, name, nachname, gilde, { ui = true }) laedt bei genau einem Client je Welt
--                       zusaetzlich die Oberflaeche (Alert, UI, Extras, FeudUI) ueber die UI-Attrappe.
--   J.X                 der Kopf tests/ui/_cu170.lua (eine Welt, ein Client), fuer reine Oberflaechen-Funde.
local J = {}
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektpfad>"):gsub("/+$", "")
J.DIR = DIR
local SELF = arg[0]
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/belege/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ju.lua"

local pass, fail = 0, 0
function J.check(name, cond, info)
  if cond then pass = pass + 1 else
    fail = fail + 1
    io.write("ROT ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n")
  end
end
function J.done()
  io.write(("%s: %d ok, %d rot\n"):format(SELF:match("([^/]+)%.lua$") or SELF, pass, fail))
  os.exit(fail == 0 and 0 or 1)
end

J.GUID, J.KEY = "Player-1-7461657465", "Taeter-Lamm"
J.GUID2, J.KEY2 = "Player-1-7261626573", "Rabe-Schwarz"
J.GILDE = "Die Testgilde"

function J.welt(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = DIR .. "/DeathNote/Media"
  AM.locale = code or "deDE"
  AM.Reset()
  local W = AM.NewWorld({ "EARNED_NEW", "EARNED_CHANGED", "CLAIM_NEW", "CLAIMS_CHANGED", "CLAIM_SETTLED", "GUILD_UPDATED" })
  W.AM, W.BM = AM, BM
  AM.AddEnemy("nameplate9", { name = "Taeter", surname = "Lamm", guid = J.GUID })
  AM.AddEnemy("nameplate8", { name = "Rabe", surname = "Schwarz", guid = J.GUID2 })
  local logicTime = _G.time
  BM.G.time = function() return logicTime() end
  function W.lauf(sec)
    for _ = 1, math.ceil(sec / 0.1) do AM.Advance(0.1); BM.Advance(0.1); W.deliver() end
  end
  function W.ruhe() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end

-- opts.ui: dieser Client bekommt die Oberflaeche (hoechstens einer je Welt); opts.db: gespeicherte Daten
function J.client(W, name, surname, guild, opts)
  opts = opts or {}
  local AM, BM = W.AM, W.BM
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  local have = false
  for _, f in ipairs(files) do if f == "Share.lua" then have = true end end
  if not have then files[#files + 1] = "Share.lua" end
  local c = W.client(name, surname, guild, { fullSender = true, files = files, db = opts.db, friends = opts.friends,
    lang = AM.locale })
  c.chat = {}
  c.env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) c.chat[#c.chat + 1] = tostring(m) end }
  function c.chatHas(s) for _, l in ipairs(c.chat) do if l:find(s, 1, true) then return true end end return false end
  function c.chatIndex(s) for i, l in ipairs(c.chat) do if l:find(s, 1, true) then return i end end return nil end
  if opts.ui then
    for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "FeudUI.lua" }) do BM.Load(DIR .. "/DeathNote/" .. f, c.ns) end
    c.ui = true
    c.slips = {}
    local orig = c.ns.Extras.Slip
    c.ns.Extras.Slip = function(kicker, nm, rgb, line, key, open)
      c.slips[#c.slips + 1] = { kicker = kicker, name = nm, line = line, key = key, open = open, at = _G.GetTime(),
        chatAt = #c.chat }
      return orig(kicker, nm, rgb, line, key, open)
    end
    function c.banner()
      for _, f in ipairs(BM.frames) do if f.kicker and f.stamp and f.line and f.name and f.inAnim then return f end end
    end
    function c.kit() return c.ns.UI.Kit end
    function c.open() c.ns:Fire("TOGGLE_UI"); W.lauf(0.2); W.ruhe() end
    function c.rows()
      local out = {}
      for _, f in ipairs(BM.frames) do
        if f._kind == "Button" and f.item ~= nil and f.rank and f.sub and f:IsVisible() then out[#out + 1] = f end
      end
      table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
      return out
    end
    function c.sheet() local S = c.ns.FeudUI.Sheet(); return S end
    function c.click(b) if b and b._scripts.OnClick then b._scripts.OnClick(b, "LeftButton") end end
  end
  return c
end

function J.sieht(c, guid) c.fire("NAME_PLATE_UNIT_ADDED", (guid or J.GUID) == J.GUID and "nameplate9" or "nameplate8") end
function J.toetet(c, guid)
  J.sieht(c, guid)
  c.fire("PARTY_KILL", c.env.UnitGUID("player"), guid or J.GUID)
end
function J.earned(c) local d = c.env.DeathNoteDB; return d and type(d.earned) == "table" and d.earned or {} end
function J.claims(c) local d = c.env.DeathNoteDB; return d and type(d.claims) == "table" and d.claims or {} end
function J.relog(W, c, opts)
  c.fire("PLAYER_LOGOUT")
  local function copy(t, seen)
    if type(t) ~= "table" then return t end
    seen = seen or {}
    if seen[t] then return seen[t] end
    local o = {}; seen[t] = o
    for k, v in pairs(t) do o[copy(k, seen)] = copy(v, seen) end
    return o
  end
  local db = copy(c.env.DeathNoteDB)
  c.loggedIn = false
  for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
  opts = opts or {}
  opts.db = db
  return J.client(W, opts.name or c.name, c.surname, c.guild, opts)
end
function J.nospace(s) return (tostring(s):gsub("%s", "")) end

-- der Kopf der UI-Tests des Bauers (eine Welt, ein Client, Attrappe der Leitung nach Wunsch)
function J.cu()
  local a0 = arg[0]
  local X = dofile(DIR .. "/tests/ui/_cu170.lua")
  arg[0] = a0
  return X
end

return J
