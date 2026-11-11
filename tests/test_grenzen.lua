-- Waechter (1.2.0, fix-2): Lua-Grenzen je Datei des Addons.
-- Aufruf: luajit tests/test_grenzen.lua [addon-ordner]
-- (1) Lokale Namen auf Dateiebene: Lua 5.1 erlaubt 200 gleichzeitig aktive lokale Namen je Funktion; die Datei
--     selbst ist eine Funktion. Gemessen wird genau, nicht geschaetzt: vor den Quelltext werden k zusaetzliche
--     lokale Namen gesetzt; das groesste k, mit dem die Datei noch laedt, ist die Luft. Rot ab 180 benutzten Namen.
-- (2) Upvalues je Funktion (Grenze 60): ueber jit.util.funcinfo jeder Funktion der Datei. Rot ab 55.
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

-- lokale Namen auf Dateiebene (hoechste Zahl gleichzeitig aktiver), genau ueber die Ladeprobe
local function usedLocals(src)
  if not loadstring(src) then return nil end
  local lo, hi = 0, 201        -- lo laedt, hi laedt nicht
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

-- Dateien: alle *.lua des Addons und der Sprachdateien (ls, wie die anderen Tests)
local files = {}
local p = io.popen('ls "' .. DIR .. '"*.lua "' .. DIR .. 'Locales/"*.lua 2>/dev/null')
for l in p:lines() do files[#files + 1] = l end
p:close()
check("Dateien gefunden", #files >= 10, #files)

-- Selbstprobe: die Messung erkennt eine Datei kurz vor der Grenze (199 Namen) und eine darueber
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
