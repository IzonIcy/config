local fterm = require("FTerm")

local M = {}

M.htop = fterm:new({
	ft = "fterm_htop",
	cmd = "htop",
})

-- FTerm ships no commands of its own. They live in config/mappings.lua so
-- they exist before FTerm lazy-loads, rather than only after first require.

return M
