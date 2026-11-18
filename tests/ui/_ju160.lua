-- Jagd UI 1.6.0: gemeinsame Welt der Belegtests ju*.lua (UI-Mock mit allen Dateien des Worktrees samt den vier
-- neuen Oberflaechen). Aufruf je Test: cd <worktree> && luajit <pfad>/juNN_x.lua .   Exit 1 = Fund belegt.
local J = {}
function J.world(WT, code, opt)
  opt = opt or {}
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  rawset(BM.G, "time", function() return math.floor(AM.epoch + AM.now) end)
  local ns = AM.Load({ noLogin = true, files = files, db = opt.db,
    before = function() if opt.guild then AM.units.player.guild = opt.guild end end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua", "SceneMap.lua", "FatesUI.lua",
      "GuildLogUI.lua", "CallUI.lua", "FeudUI.lua", "Humor.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, sent = {} }
  _G.SendChatMessage = function(text, ch) W.sent[#W.sent + 1] = { text = text, ch = ch } end
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.open() if not (rawget(BM.G, "DeathNoteFrame") and BM.G.DeathNoteFrame:IsShown()) then ns:Fire("TOGGLE_UI") end; W.tick(1); W.settle() end
  function W.find(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
  function W.click(f, b) assert(f, "click ohne Frame"); f._scripts.OnClick(f, b or "LeftButton"); W.tick(1) end
  function W.tab(id) W.click(W.find(function(f) return f.id == id and f._scripts and f._scripts.OnClick and f:IsVisible() end)) end
  function W.visible(s)
    for _, f in ipairs(BM.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text:find(s, 1, true) and f:IsVisible() then return f end
    end
  end
  function W.texts()
    local out = {}
    for _, f in ipairs(BM.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text ~= "" and f:IsVisible() then out[#out + 1] = f._text end
    end
    return out
  end
  -- ein Tod durch eine Kreatur ueber den echten Weg (Store und DEATH_RECORDED wie Attribution)
  function W.creature(name, npc, spell)
    local j = { t = time(), kind = "pve", zone = "Wald von Elwynn", subzone = "Steinbruch von Jaspismine", mapID = 1429,
      x = 61, y = 53, me = "Ich Selbst", myLevel = 6, counted = true, candidates = {},
      cause = { art = "creature", name = name, npc = npc, spell = spell } }
    ns.Store.RecordDeath(j)
    ns:Fire("DEATH_RECORDED", j, nil)
    W.tick(1)
    return j
  end
  return W
end
J.pass, J.fail = 0, 0
function J.check(name, cond, detail)
  if cond then J.pass = J.pass + 1; print("ok    " .. name)
  else J.fail = J.fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
function J.done() print(("%d ok, %d rot"):format(J.pass, J.fail)); os.exit(J.fail > 0 and 1 or 0) end
return J
