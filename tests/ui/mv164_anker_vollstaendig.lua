-- 1.6.4 move (wish of the owner, 24.11.2026: "all anchors of all windows that can pop up"): every frame of the addon that hangs on
-- UIParent is listed here with its kind. Rule: what appears by itself has an anchor in the placing mode; what the
-- player opens is dragged directly and keeps its place over a /reload (never in layout-local.txt); everything else
-- is an exception with its reason. A new free-standing frame without an entry is red (static over the source, and at
-- run time over every frame on UIParent after a session that shows them all). Names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check

local RULES = {
  DeathNoteAlert = { "anchor" },          -- the alarm (by itself)
  DeathNoteBanner = { "anchor" },         -- the notice after a death, a revenge, a guild death, a rank (by itself)
  DeathNoteCall = { "anchor" },           -- the slip of a help call (by itself)
  DeathNoteGrudge = { "anchor" },         -- the grudge notice on the right after an attack (by itself)
  DeathNoteFrame = { "player", "ui.point" },                -- the book (/dn, the minimap button)
  DeathNoteShare = { "player", "share.point" },             -- the window "Show" (from the book, the payback notice)
  DeathNoteShareGuest = { "player", "share.guestPoint" },   -- the guest poster (a click on a link in the chat)
  DeathNoteAlertButton = { "exception", "the alarm's invisible target button: always over the alarm, never on its own" },
  DeathNoteFlash = { "exception", "the red pulse at the screen's edge: the whole screen, no mouse" },
  DeathNoteMove = { "exception", "the bar of the placing mode itself" },
  DeathNoteMoveEsc = { "exception", "one invisible pixel of the placing mode: Esc ends it even without the bar" },
  DeathNoteStart = { "exception", "the first-start window: once on a new installation (or /dn start), in the middle, dragged but not kept; it asks once and goes" },
}

-- (1) static: every CreateFrame( call in the addon's files (also over several lines), by its arguments: on UIParent it
-- needs a name from RULES; a frame without a parent is an invisible helper (events, measuring) listed in PARENTLESS;
-- a named frame on another parent is listed in CHILDREN; and no file may hand UIParent to a variable (a parent the
-- scan could not see). Anything else is red.
local PARENTLESS = {   -- file -> count of CreateFrame without a parent (never shown on the screen)
  ["Core.lua"] = 1,     -- the event frame
  ["FeudUI.lua"] = 1,   -- the page in the game's options (Settings takes it as its canvas)
  ["Plate.lua"] = 1,    -- the event frame of the nameplate mark
  ["Probe.lua"] = 1,    -- a scratch frame to test event registration
}
local CHILDREN = { DeathNoteMenu = "the row menu, child of the book", DeathNoteSearch = "the search field, in the book",
  DeathNoteMinimapButton = "the own minimap button, on the minimap edge" }
local found, problems, parentless = {}, {}, {}
local dir = J.WT .. "/DeathNote"
local p = io.popen('ls "' .. dir .. '"/*.lua')
for file in p:lines() do
  local base = file:match("[^/]+$")
  local h = io.open(file, "rb"); local src = h:read("*a"); h:close()
  for args in src:gmatch("CreateFrame%s*(%b())") do
    local inner = args:sub(2, -2)
    local parts = {}
    for part in (inner .. ","):gmatch("%s*(.-)%s*,") do parts[#parts + 1] = part end
    local name = parts[2] and parts[2]:match('^"([%w_]+)"$') or nil
    local parent = parts[3]
    if not parent or parent == "" or parent == "nil" then
      parentless[base] = (parentless[base] or 0) + 1
      if name then problems[#problems + 1] = base .. ": named frame without parent " .. name end
    elseif parent == "UIParent" then
      if name then found[name] = true else problems[#problems + 1] = base .. ": nameless frame on UIParent" end
    elseif name and name:find("^DeathNote") and not CHILDREN[name] then
      problems[#problems + 1] = base .. ": named frame " .. name .. " on " .. parent .. " not in the list"
    end
  end
  local n = 0
  for line in src:gmatch("[^\n]*") do
    n = n + 1
    local code = line:gsub("%-%-.*$", "")
    if code:find("=%s*UIParent%s*$") or code:find("=%s*UIParent%s*[,;]") then problems[#problems + 1] = base .. ": UIParent in a variable: " .. code end
  end
end
p:close()
for name in pairs(found) do check("Quelle: " .. name .. " steht in der Liste", RULES[name] ~= nil) end
for name in pairs(RULES) do check("Liste: " .. name .. " gibt es noch", found[name] == true) end
for file, c in pairs(parentless) do check("Quelle: ohne Elternteil in " .. file .. " (" .. c .. ") steht in der Liste", PARENTLESS[file] == c, c) end
for file, c in pairs(PARENTLESS) do check("Liste ohne Elternteil: " .. file .. " gibt es noch", parentless[file] == c) end
check("Quelle: keine weiteren Funde", #problems == 0, table.concat(problems, "; "))

-- (2) at run time: a session that shows them all, then every frame on UIParent
local W = J.world("deDE")
local ns = W.ns
local key = ns.Store.AddManual("Velka Thornheart")
ns:Fire("TEST_ALERT"); W.tick(0.5)
ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 })
ns.Grudge.Test(); W.tick(0.6)
W.settle(); W.settle()
ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
ns.ShareUI.Open({ item = ns.Store.Get(key), kind = "own" }); W.tick(0.1)
ns.ShareUI.Guest({ name = "Grimwald", sender = "Liora", segs = { "GESUCHT", "2x getoetet" } }); W.tick(0.1)
if ns.Grudge.Current() then ns.Grudge.Close("click") end
W.slash("move"); W.tick(0.1)
local seen = {}
for _, f in ipairs(W.BM.frames) do
  if f._parent == W.G.UIParent and (f._kind == "Frame" or f._kind == "Button") then
    local n = f._name or "?"
    seen[n] = true
    check("Laufzeit: " .. n .. " steht in der Liste", RULES[n] ~= nil)
  end
end
-- every anchor shows its sample in the mode
local samples = {}
for _, n in ipairs(W.samples()) do samples[n] = true end
for name, r in pairs(RULES) do
  if r[1] == "anchor" then check("Anker im Modus: " .. name, samples[name] == true) end
end
W.slash("move")

-- (3) what the player opens: dragged directly, its place kept over a /reload, not in layout-local.txt
local open = {
  DeathNoteFrame = function(V) V.ns:Fire("TOGGLE_UI"); V.tick(1); V.settle() end,
  DeathNoteShare = function(V)
    local k = V.ns.Store.AddManual("Velka Thornheart")
    V.ns.ShareUI.Open({ item = V.ns.Store.Get(k), kind = "own" }); V.tick(0.1)
  end,
  DeathNoteShareGuest = function(V) V.ns.ShareUI.Guest({ name = "Grimwald", sender = "Liora", segs = { "GESUCHT" } }); V.tick(0.1) end,
}
for name, r in pairs(RULES) do
  if r[1] == "player" then
    local A = J.world("deDE")
    open[name](A)
    local f = A.frame(name)
    check(name .. ": offen", f and f:IsShown())
    local l0, b0 = A.rect(f)
    check(name .. ": direkt ziehbar", A.drag(f, -137, -61))
    local l1, b1 = A.rect(f)
    check(name .. ": nicht in layout-local.txt", not f._userPlaced)
    check(name .. ": Lage gehalten in " .. r[2], A.ns.Store.Setting(r[2]) ~= nil)
    local R = A.reload("deDE")
    open[name](R)
    local g = R.frame(name)
    local l2, b2 = R.rect(g)
    check(name .. ": nach dem Neuladen an der gezogenen Stelle", math.abs(l2 - l1) < 0.5 and math.abs(b2 - b1) < 0.5,
      ("%.1f/%.1f statt %.1f/%.1f (vorher %.1f/%.1f)"):format(l2, b2, l1, b1, l0, b0))
    -- /dn move reset puts it back to the default place (the book keeps its own place: it is not one of the placing mode)
    if name ~= "DeathNoteFrame" then
      R.slash("move reset")
      local l3, b3 = R.rect(g)
      check(name .. ": /dn move reset setzt zurueck", R.ns.Store.Setting(r[2]) == nil and math.abs(l3 - l0) < 0.5 and math.abs(b3 - b0) < 0.5,
        ("%.1f/%.1f statt %.1f/%.1f"):format(l3, b3, l0, b0))
      check(name .. ": beim Bau nicht in layout-local.txt", not g._userPlaced)
    end
    local n, first = R.errors()
    check(name .. ": keine Fehler", n == 0, first)
  end
end

J.done("mv164_anker_vollstaendig")
