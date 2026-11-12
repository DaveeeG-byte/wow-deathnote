-- 1.3.0: a pardoned enemy who leads the score (he killed me 3 times, I killed him once) is pardoned on the rap sheet
-- too, as everywhere else (Ledger.State): his victim sheet names him pardoned in ink, his row is not red. A wanted one
-- with the same score stays an open case (red), as before.
-- Call from the project root: luajit tests/ui/rapsheet_pardoned.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "rapsheet_pardoned")
local check = K.check

for _, code in ipairs({ "deDE", "enUS" }) do
  local ns = K.world(code)
  local AM, BM, L = K.AM, K.BM, ns.L
  AM.units.player.level = 40
  K.tick(30); K.settle()
  local me = AM.units.player.guid or "Player-93-0000AAAA"
  local plate = 0
  local function setup(name, surname)
    local guid = "Player-93-" .. name .. surname
    for i = 1, 3 do
      ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = guid }, { t = time() - 3000 * i, zone = "Z" }, true)
    end
    plate = plate + 1
    AM.AddEnemy("nameplate" .. plate, { name = name, surname = surname, level = 40, guid = guid, class = "MAGE" })
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
    AM.FireEvent("PARTY_KILL", me, guid); K.tick(61)
    return ns.Util.KeyFor(name, surname)
  end
  local pk = setup("Paula", "Pardon")
  local ok = setup("Otto", "Offen")
  ns.Store.SetStatus(pk, "pardoned"); K.tick()
  check(code .. " Ledger.State: pardoned and open", ns.Ledger.State(pk) == "pardoned" and ns.Ledger.State(ok) == "open",
    tostring(ns.Ledger.State(pk)) .. "/" .. tostring(ns.Ledger.State(ok)))
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local tabBtn
  for _, f in ipairs(BM.frames) do if f.id == "record" and f.mark and f._scripts and f._scripts.OnClick then tabBtn = f end end
  tabBtn._scripts.OnClick(tabBtn, "LeftButton"); K.tick()
  local P
  for _, f in ipairs(BM.frames) do if f.enemy and f.death then P = f end end
  local function row(key) for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == key then return f end end end
  local function sheet(key)
    local r = row(key)
    r._scripts.OnClick(r, "LeftButton"); K.tick()
    local V = P.record.vic
    return (V.state._text or ""):gsub(" ", ""), V.score._tc
  end
  local rp, ro = row(pk), row(ok)
  check(code .. " both rows shown", rp ~= nil and ro ~= nil)
  -- red ink of any shade (Look.RED, Look.RED_INK), never the ink or a pale one
  local function isRed(c) return c ~= nil and c[1] > 0.4 and c[2] < 0.2 and c[3] < 0.2 end
  if rp and ro then
    check(code .. " the open one's row mark is red", isRed(ro.mark._tc), ro.mark._tc and table.concat(ro.mark._tc, ","))
    check(code .. " the pardoned one's row mark is not red", not isRed(rp.mark._tc), rp.mark._tc and table.concat(rp.mark._tc, ","))
    local w, c = sheet(pk)
    check(code .. " sheet of the pardoned one: pardoned", w:upper() == L.TIP_PARDONED:gsub(" ", ""):upper(), w)
    check(code .. " sheet of the pardoned one: score in ink", not isRed(c), c and table.concat(c, ","))
    w, c = sheet(ok)
    check(code .. " sheet of the open one: open, red", w:upper() == L.STATE_OPEN:gsub(" ", ""):upper() and isRed(c), w)
  end
  check(code .. " no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("rap sheet: a pardoned enemy")
