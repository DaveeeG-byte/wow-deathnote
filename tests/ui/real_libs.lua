-- Loads the REAL embedded libraries (DeathNote/Libs, in the order of Libs/embeds.xml) into the UI mock world,
-- so the addon talks to the real LibStub, CallbackHandler, LibDataBroker and LibDBIcon instead of stand-ins.
-- The libraries run in an environment over the mock's globals in which an unknown global is nil, as in the
-- client (the mock itself raises on unknown globals to catch typos in our own files).
-- Usage (inside the "before" hook of a test world):
--   local R = dofile("tests/ui/real_libs.lua")
--   local n0 = #BM.frames + 1; R.load(BM, addonDir, opts); ...; R.libLogin(BM, n0)
local R = {}

-- the library files listed in Libs/embeds.xml, in load order
function R.files(dir)
  local list = {}
  local f = assert(io.open(dir .. "/Libs/embeds.xml", "r"))
  for line in f:lines() do
    local p = line:match('<Script%s+file="([^"]+)"')
    if p then list[#list + 1] = dir .. "/Libs/" .. p:gsub("\\", "/") end
  end
  f:close()
  return list
end

-- opts.files: other library files (e.g. an older LibDBIcon of another addon) loaded BEFORE ours
-- opts.compartment: provide AddonCompartmentFrame (it records what the library adds)
function R.load(BM, dir, opts)
  opts = opts or {}
  local G = BM.G
  R.missing = {}
  local env
  env = setmetatable({}, {
    __index = function(_, k)
      if k == "_G" then return env end
      local v = rawget(G, k)
      if v ~= nil then return v end
      if k == "strmatch" then return string.match end
      if k == "securecallfunction" then return function(f, ...) return f(...) end end
      if k == "assert" or k == "rawset" or k == "xpcall" or k == "geterrorhandler" then return _G[k] end
      R.missing[k] = true
      return nil
    end,
    __newindex = function(_, k, v) G[k] = v end,
  })
  if opts.compartment then
    rawset(G, "AddonCompartmentFrame", { registeredAddons = {},
      RegisterAddon = function(self, d) self.registeredAddons[#self.registeredAddons + 1] = d end,
      UpdateDisplay = function() end })
  end
  local function run(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    chunk()
  end
  for _, p in ipairs(opts.files or {}) do run(p) end
  for _, p in ipairs(R.files(dir)) do run(p) end
  R.env = env
  return rawget(G, "LibStub")
end

-- fire PLAYER_LOGIN at the libraries' own event frames (unnamed frames with OnEvent, made since index from)
function R.libLogin(BM, from)
  for i = from or 1, #BM.frames do
    local f = BM.frames[i]
    if f._kind == "Frame" and f._scripts.OnEvent and not f._name then f._scripts.OnEvent(f, "PLAYER_LOGIN") end
  end
end

return R
