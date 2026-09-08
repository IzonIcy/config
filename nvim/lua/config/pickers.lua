local M = {}

local function has_fzf()
	return vim.fn.executable("fzf") == 1
end

local function expand_cwd(cwd)
	return vim.fn.fnamemodify(vim.fn.expand(cwd or vim.uv.cwd()), ":p")
end

local function command_for_files()
	if vim.fn.executable("rg") == 1 then
		return { "rg", "--files", "--hidden", "--glob", "!**/.git/**" }
	end

	if vim.fn.executable("fd") == 1 then
		return { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
	end

	return { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" }
end

local function system_lines(cmd, cwd)
	local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		return {}
	end

	return vim.split(result.stdout, "\n", { trimempty = true })
end

local function open_file(cwd, file)
	file = file:gsub("^%./", "")
	vim.cmd("edit " .. vim.fn.fnameescape(vim.fs.joinpath(cwd, file)))
end

local function fallback_files(opts)
	local cwd = expand_cwd(opts and opts.cwd)
	local files = system_lines(command_for_files(), cwd)

	if #files == 0 then
		vim.notify("No files found in " .. cwd, vim.log.levels.WARN)
		return
	end

	vim.ui.select(files, { prompt = "Find file" }, function(choice)
		if choice then
			open_file(cwd, choice)
		end
	end)
end

function M.files(opts)
	if has_fzf() then
		require("fzf-lua").files(opts)
		return
	end

	fallback_files(opts)
end

function M.resume()
	if has_fzf() then
		require("fzf-lua").resume()
		return
	end

	M.files()
end

function M.grep()
	if has_fzf() then
		require("fzf-lua").grep()
		return
	end

	vim.notify("Install fzf to use grep search", vim.log.levels.WARN)
end

function M.grep_cword()
	if has_fzf() then
		require("fzf-lua").grep_cword()
		return
	end

	vim.notify("Install fzf to grep the word under cursor", vim.log.levels.WARN)
end

return M
