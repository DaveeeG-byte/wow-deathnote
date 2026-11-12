-- Older versions read from the git repository for comparison tests (test_ledger_diff, test_ledger_migration,
-- tests/ui/rapsheet_off.lua). Without the repository (a "Source code" archive, a copy without .git) or without the
-- commit or tag, these tests are skipped with one clear line instead of turning the suite red; the pipeline checks out
-- with fetch-depth 0, so they run there. Temporary folders are removed again (GitBase.Clean, also at a skip).
-- Use: local GitBase = dofile(root .. "/tests/git_base.lua")
local GitBase = {}
local made = {}

local function q(s) return "'" .. tostring(s):gsub("'", "'\\''") .. "'" end

-- does the repository at root know ref (commit or tag)?
function GitBase.Has(root, ref)
  local p = io.popen("git -C " .. q(root) .. " rev-parse --verify --quiet " .. q(ref .. "^{commit}") .. " 2>/dev/null")
  if not p then return false end
  local out = p:read("*a") or ""
  p:close()
  return out:match("^%x+") ~= nil
end

-- a new temporary folder (removed by GitBase.Clean)
function GitBase.TempDir()
  local dir = os.tmpname()
  os.remove(dir)
  os.execute("mkdir -p " .. q(dir))
  made[#made + 1] = dir
  return dir
end

-- the folder DeathNote of ref in a temporary folder; returns its path with a trailing slash, or nil and a reason
function GitBase.Archive(root, ref, check)
  if not GitBase.Has(root, ref) then return nil, "needs the git repository with " .. ref end
  local dir = GitBase.TempDir()
  os.execute("git -C " .. q(root) .. " archive " .. q(ref) .. " DeathNote | tar -x -C " .. q(dir) .. " 2>/dev/null")
  local path = dir .. "/DeathNote/"
  local h = io.open(path .. (check or "Core.lua"))
  if not h then return nil, "git archive " .. ref .. " gave no DeathNote folder" end
  h:close()
  return path
end

-- one file of ref (git show), or nil and a reason
function GitBase.Show(root, ref, file)
  if not GitBase.Has(root, ref) then return nil, "needs the git repository with " .. ref end
  local p = io.popen("git -C " .. q(root) .. " show " .. q(ref .. ":" .. file) .. " 2>/dev/null")
  if not p then return nil, "git show failed" end
  local src = p:read("*a")
  p:close()
  if not src or #src == 0 then return nil, "git show " .. ref .. ":" .. file .. " is empty" end
  return src
end

-- removes every temporary folder made here
function GitBase.Clean()
  for i = #made, 1, -1 do
    os.execute("rm -rf " .. q(made[i]))
    made[i] = nil
  end
end

-- the line of a skipped test (exit code 0 follows at the caller)
function GitBase.Skip(name, why)
  io.write(("%-18s skipped: %s\n"):format(name, why))
end

return GitBase
