local fterm = require("FTerm")

local M = {}

M.htop = fterm:new({
	ft = "fterm_htop",
	cmd = "htop",
})

return M
