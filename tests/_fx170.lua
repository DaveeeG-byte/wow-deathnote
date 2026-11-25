-- 1.7.0 fixer: head of tests/test_fx170_*.lua (copied from the hunt's _jl.lua). luajit tests/test_fx170_x.lua [project]
-- Alle Namen sind erfunden.
local DIR = (arg and arg[1]) or os.getenv("DN_DIR") or "."
DIR = DIR:gsub("/+$", "")
arg[1] = DIR
package.path = DIR .. "/tests/?.lua;" .. package.path
local K = require("_cl170")
K.DIR = DIR
function K.paar(W, opts)
  local a = W.client("Anton", "Wurst", K.G, { fullSender = true })
  local b = W.client("Berta", "Senf", K.G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  return a, b
end
return K
