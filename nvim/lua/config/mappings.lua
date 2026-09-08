-- mappings, including plugins

local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

local pickers = require("config.pickers")
local theme = require("config.theme")

-- set leader
map({ "n", "v" }, "<Space>", "<Nop>", "Disable space default behavior")

-- buffers
map("n", "<S-l>", "<Cmd>bnext<CR>", "Next buffer")
map("n", "<S-h>", "<Cmd>bprevious<CR>", "Previous buffer")
map("n", "<leader>q", "<Cmd>BufferClose<CR>", "Close buffer")
map("n", "<leader>Q", "<Cmd>BufferClose!<CR>", "Force close buffer")
map("n", "<leader>U", "<Cmd>bufdo bd<CR>", "Close all buffers")
map("n", "<leader>vs", "<Cmd>vsplit<CR><Cmd>bnext<CR>", "Vertical split next buffer")

-- buffer position nav + reorder
map("n", "<A-S-h>", "<Cmd>BufferMovePrevious<CR>", "Move buffer left")
map("n", "<A-S-l>", "<Cmd>BufferMoveNext<CR>", "Move buffer right")
map("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", "Go to buffer 1")
map("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", "Go to buffer 2")
map("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", "Go to buffer 3")
map("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", "Go to buffer 4")
map("n", "<A-5>", "<Cmd>BufferGoto 5<CR>", "Go to buffer 5")
map("n", "<A-6>", "<Cmd>BufferGoto 6<CR>", "Go to buffer 6")
map("n", "<A-7>", "<Cmd>BufferGoto 7<CR>", "Go to buffer 7")
map("n", "<A-8>", "<Cmd>BufferGoto 8<CR>", "Go to buffer 8")
map("n", "<A-9>", "<Cmd>BufferGoto 9<CR>", "Go to buffer 9")
map("n", "<A-0>", "<Cmd>BufferLast<CR>", "Go to last buffer")
map("n", "<A-p>", "<Cmd>BufferPin<CR>", "Pin buffer")

-- windows - ctrl nav, and fn resize
map("n", "<C-h>", "<C-w>h", "Focus left window")
map("n", "<C-j>", "<C-w>j", "Focus lower window")
map("n", "<C-k>", "<C-w>k", "Focus upper window")
map("n", "<C-l>", "<C-w>l", "Focus right window")
map("n", "<F5>", "<Cmd>resize +2<CR>", "Increase window height")
map("n", "<F6>", "<Cmd>resize -2<CR>", "Decrease window height")
map("n", "<F7>", "<Cmd>vertical resize +2<CR>", "Increase window width")
map("n", "<F8>", "<Cmd>vertical resize -2<CR>", "Decrease window width")

-- fzf and grep
map("n", "<leader>f", pickers.files, "Find files")
map("n", "<leader>Fh", function()
	pickers.files({ cwd = "~/" })
end, "Find files in home")
map("n", "<leader>Fc", function()
	pickers.files({ cwd = "~/.config" })
end, "Find files in config")
map("n", "<leader>Fl", function()
	pickers.files({ cwd = "~/.local/src" })
end, "Find files in local src")
map("n", "<leader>Ff", function()
	pickers.files({ cwd = ".." })
end, "Find files above cwd")
map("n", "<leader>Fr", pickers.resume, "Resume picker")
map("n", "<leader>g", pickers.grep, "Live grep")
map("n", "<leader>G", pickers.grep_cword, "Grep word under cursor")

-- project
map("n", "<leader>pf", function()
	local project_root = require("project_nvim").get_project_root()
	if project_root then
		pickers.files({ cwd = project_root })
	else
		pickers.files()
	end
end, "Find project files")
map("n", "<leader>pl", function()
	require("project_nvim").select_project()
end, "List projects")

-- misc
map("n", "<leader>s", ":%s//g<Left><Left>", "Substitute in file")
map("n", "<leader>t", "<Cmd>NvimTreeToggle<CR>", "Toggle file tree")
map("n", "<leader>p", theme.switch, "Cycle theme")
map("n", "<leader>P", "<Cmd>Lazy<CR>", "Open plugin manager")
map("n", "<leader>z", function()
	require("FTerm").open()
end, "Floating terminal")
map("t", "<Esc>", [[<C-\><C-n><Cmd>lua require("FTerm").close()<CR>]], "Close floating terminal")
map("n", "<leader>w", "<Cmd>w<CR>", "Write file")
map("n", "<leader>d", function()
	vim.ui.input({ prompt = "Write copy to: ", completion = "file" }, function(path)
		if path and path ~= "" then
			vim.cmd.write(vim.fn.fnameescape(path))
		end
	end)
end, "Write copy to path")
map("n", "<leader>x", function()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("No file for current buffer", vim.log.levels.WARN)
		return
	end
	vim.fn.jobstart({ "chmod", "+x", file }, {
		detach = true,
		on_exit = function(_, code)
			vim.schedule(function()
				if code == 0 then
					vim.notify("Made executable: " .. file)
				else
					vim.notify("chmod failed for: " .. file, vim.log.levels.ERROR)
				end
			end)
		end,
	})
end, "Make file executable")
map("n", "<leader>mv", function()
	local current = vim.fn.expand("%:p")
	if current == "" then
		vim.notify("No file for current buffer", vim.log.levels.WARN)
		return
	end
	vim.ui.input({ prompt = "Move file to: ", completion = "file" }, function(destination)
		if not destination or destination == "" then
			return
		end
		local ok, err = os.rename(current, vim.fn.expand(destination))
		if not ok then
			vim.notify("Move failed: " .. tostring(err), vim.log.levels.ERROR)
			return
		end
		vim.cmd.edit(vim.fn.fnameescape(destination))
		vim.notify("Moved file to: " .. destination)
	end)
end, "Move current file")
map("n", "<leader>R", function()
	vim.cmd.source(vim.fn.expand("%:p"))
end, "Source current file")
map("n", "<leader>u", function()
	local url = vim.fn.expand("<cWORD>")
	local cmd
	if vim.fn.has("mac") == 1 then
		cmd = { "open", url }
	elseif vim.fn.has("unix") == 1 then
		cmd = { "xdg-open", url }
	else
		vim.notify("No opener available", vim.log.levels.WARN)
		return
	end
	vim.fn.jobstart(cmd, { detach = true })
end, "Open URL under cursor")
map("v", "<leader>i", "=gv", "Indent selection")
map("n", "<leader>W", "<Cmd>set wrap!<CR>", "Toggle wrap")
map("n", "<leader>l", "<Cmd>Twilight<CR>", "Toggle Twilight")

-- decisive csv
map("n", "<leader>csa", function()
	require("decisive").align_csv({})
end, "Align CSV")
map("n", "<leader>csA", function()
	require("decisive").align_csv_clear({})
end, "Clear CSV alignment")
map("n", "[c", function()
	require("decisive").align_csv_prev_col()
end, "Previous CSV column")
map("n", "]c", function()
	require("decisive").align_csv_next_col()
end, "Next CSV column")

map("n", "<leader>H", function()
	require("plugins.fterm").htop:toggle()
end, "Toggle htop terminal")

map("n", "<leader>ma", function()
	local file = vim.fn.expand("%:p")
	local bufdir = vim.fn.expand("%:p:h")
	if file == "" or bufdir == "" then
		vim.notify("No file for current buffer", vim.log.levels.WARN)
		return
	end
	vim.cmd.lcd(vim.fn.fnameescape(bufdir))
	vim.cmd("!sudo make uninstall && sudo make clean install " .. vim.fn.shellescape(file))
end, "Make install current project")

map("n", "<leader>nn", function()
	if vim.wo.relativenumber then
		vim.wo.relativenumber = false
		vim.wo.number = true
	else
		vim.wo.relativenumber = true
	end
end, "Toggle relative numbers")

-- debugging
map("n", "<leader>db", function()
	require("dap").toggle_breakpoint()
end, "Toggle breakpoint")
map("n", "<leader>dB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, "Conditional breakpoint")
map("n", "<leader>dc", function()
	require("dap").continue()
end, "Continue")
map("n", "<leader>do", function()
	require("dap").step_over()
end, "Step over")
map("n", "<leader>di", function()
	require("dap").step_into()
end, "Step into")
map("n", "<leader>dO", function()
	require("dap").step_out()
end, "Step out")
map("n", "<leader>du", function()
	require("dapui").toggle()
end, "Toggle DAP UI")
map("n", "<leader>dt", function()
	require("dap").terminate()
end, "Terminate session")
map("n", "<leader>dr", function()
	require("dap").run_to_cursor()
end, "Run to cursor")

-- code runner
map("n", "<leader>rr", function()
	require("overseer").run_template()
end, "Run task")
map("n", "<leader>rb", function()
	require("overseer").run_template({ name = "build" })
end, "Run build")
map("n", "<leader>rt", function()
	require("overseer").toggle()
end, "Toggle overseer")

-- todo comments
map("n", "<leader>td", function()
	require("todo-comments").toggle()
end, "Toggle todo comments")
map("n", "<leader>tD", function()
	require("todo-comments").search()
end, "Search todo comments")
