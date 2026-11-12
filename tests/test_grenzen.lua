-- Guard (1.2.0, fix-2): Lua limits per file of the addon.
-- Usage: luajit tests/test_grenzen.lua [addon folder]
-- (1) Locals at file level: Lua 5.1 allows 200 active local names at once per function; the file
--     itself is a function. Measured exactly, not estimated: k extra local names are put in front of the
--     source; the largest k with which the file still loads is the headroom. Red from 180 names used.
-- (2) Upvalues per function (limit 60): via jit.util.funcinfo of every function in the file. Red from 55.
local DIR = arg[1] or ((arg[0]:match("^(.*)/tests/") or ".") .. "/DeathNote/")
if not DIR:find("/$") then DIR = DIR .. "/" end
local LOCALS_RED, UPVAL_RED = 180, 55

local ok_jit, ju = pcall(require, "jit.util")
local pass, fail, lines, report = 0, 0, {}, {}
local function check(name, cond, detail)
  if cond then pass = pass + 1 else
    fail = fail + 1
    lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")
  end
end

local function readAll(p)
  local h = io.open(p, "rb")
  if not h then return nil end
  local s = h:read("*a"); h:close()
  return s
end

-- locals at file level (highest number active at once), exactly via the load probe
local function usedLocals(src)
  if not loadstring(src) then return nil end
  local lo, hi = 0, 201        -- lo loads, hi does not
  while hi - lo > 1 do
    local k = math.floor((lo + hi) / 2)
    local pre = {}
    for i = 1, k do pre[i] = "local _g" .. i end
    if loadstring(table.concat(pre, " ") .. "\n" .. src) then lo = k else hi = k end
  end
  return 200 - lo
end

local function maxUpvalues(fn)
  local best, at = 0, 0
  local function walk(pr)
    local info = ju.funcinfo(pr)
    if (info.upvalues or 0) > best then best, at = info.upvalues, info.linedefined or 0 end
    local i = -1
    while true do
      local k = ju.funck(pr, i)
      if k == nil then break end
      if type(k) == "proto" then walk(k) end
      i = i - 1
    end
  end
  walk(fn)
  return best, at
end

-- Files: all *.lua of the addon and of the locale files (ls, like the other tests)
local files = {}
local p = io.popen('ls "' .. DIR .. '"*.lua "' .. DIR .. 'Locales/"*.lua 2>/dev/null')
for l in p:lines() do files[#files + 1] = l end
p:close()
check("Dateien gefunden", #files >= 10, #files)

-- Self-check: the measurement detects a file just below the limit (199 names) and one above it
do
  local t = {}
  for i = 1, 199 do t[i] = "local v" .. i .. " = " .. i end
  check("Messung: 199 Namen werden als 199 erkannt", usedLocals(table.concat(t, "\n")) == 199, usedLocals(table.concat(t, "\n")))
  t[200], t[201] = "local v200 = 1", "local v201 = 1"
  check("Messung: 201 Namen laden nicht (Grenze greift im Lauf)", loadstring(table.concat(t, "\n")) == nil)
end

for _, f in ipairs(files) do
  local name = f:match("([^/]+)$")
  local src = readAll(f)
  local fn = src and loadstring(src, "@" .. name)
  check("laedt: " .. name, fn ~= nil)
  if fn then
    local n = usedLocals(src)
    check(("lokale Namen auf Dateiebene unter %d: %s"):format(LOCALS_RED, name), n and n < LOCALS_RED, n)
    if ok_jit then
      local up, at = maxUpvalues(fn)
      check(("Upvalues je Funktion unter %d: %s"):format(UPVAL_RED, name), up < UPVAL_RED, up .. " (Zeile " .. at .. ")")
      if not name:find("^%l%l%u%u") then
        report[#report + 1] = ("%s %d/%d"):format(name, n or -1, up)
      end
    end
  end
end

io.write(("%-18s %3d ok, %d rot\n"):format("grenzen", pass, fail))
if os.getenv("GRENZEN_ZEIGEN") then io.write("  lokale Namen/Upvalues: " .. table.concat(report, " · ") .. "\n") end
for _, l in ipairs(lines) do io.write(l .. "\n") end
os.exit(fail == 0 and 0 or 1)
