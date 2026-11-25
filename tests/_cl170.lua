-- 1.7.0 claim: shared head of the tests test_cl170_*.lua (cashing in a bounty). All names are made up.
-- require after beleg_helfer: local K = require("_cl170")
local H = require("beleg_helfer")
local M = H.M
local K = { H = H, M = M, G = "Die Testgilde" }

K.GUID = "Player-1-7461657465"
K.GUID2 = "Player-1-7261626573"
K.KEY, K.KEY2 = "Taeter-Lamm", "Rabe-Schwarz"
K.EVENTS = { "GUILD_KILL", "GUILD_UPDATED", "AVENGED", "CLAIM_NEW", "CLAIMS_CHANGED", "CLAIM_SETTLED", "EARNED_NEW",
  "EARNED_CHANGED" }

function K.welt()
  local W = H.welt(K.EVENTS)
  M.AddEnemy("nameplate9", { name = "Taeter", surname = "Lamm", guid = K.GUID })
  M.AddEnemy("nameplate8", { name = "Rabe", surname = "Schwarz", guid = K.GUID2 })
  return W
end

-- c sees the target (tracker: the key is sure by the GUID) and kills it with his own blow
function K.toetet(c, guid, unsure)
  guid = guid or K.GUID
  if not unsure then c.fire("NAME_PLATE_UNIT_ADDED", guid == K.GUID and "nameplate9" or "nameplate8") end
  c.fire("PARTY_KILL", c.env.UnitGUID("player"), guid)
end

function K.earned(c) local d = c.env.DeathNoteDB; return d and type(d.earned) == "table" and d.earned or {} end
function K.claims(c) local d = c.env.DeathNoteDB; return d and type(d.claims) == "table" and d.claims or {} end

-- messages of one kind (optionally from one client), e.g. K.msgs(W, "Q", b)
function K.msgs(W, kind, von)
  local out = {}
  for _, m in ipairs(W.sent) do
    if (not von or m.sender == von) and m.text:find("^1\t" .. kind .. "\t") then out[#out + 1] = m end
  end
  return out
end

-- the bounty time of the own bounty of c on key (the char logged in)
function K.bountyT(c, key)
  local d = c.env.DeathNoteDB
  local x = d and d.bounty and d.bounty[key]
  local me = c.surname and (c.name .. " " .. c.surname) or c.name
  return x and x[me] and x[me].t or nil
end

-- the client goes offline (PLAYER_LOGOUT, saved data kept); returns the new, not yet logged-in client
function K.weg(W, c, opts) return H.relog(W, c, opts) end

return K
