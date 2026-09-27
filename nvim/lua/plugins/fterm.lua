local fterm = require("FTerm")

local M = {}

M.htop = fterm:new({
	ft = "fterm_htop",
	cmd = "htop",
})

M.claude = fterm:new({
	ft = "fterm_claude",
	cmd = "claude",
	-- Claude's TUI needs the width; the 0.8 default lands around 64 columns.
	dimensions = { width = 0.95, height = 0.95, x = 0.5, y = 0.5 },
})

return M
