-- Theme choice is saved in a file for persistence on restart.
-- Lualine theme gets stored separately due to possible naming differences.

local M = {}

local theme_file = vim.fn.stdpath("config") .. "/lua/config/saved_theme"

local themes = {
	{
		colorscheme = "catppuccin",
		lualine = "catppuccin-nvim",
		before = function()
			local ok, catppuccin = pcall(require, "catppuccin")
			if ok then
				catppuccin.setup({
					flavour = "mocha",
					transparent_background = true,
					styles = {
						sidebars = "transparent",
						floats = "transparent",
					},
				})
			end
		end,
	},
	{
		colorscheme = "gruvbox",
		lualine = "gruvbox",
		before = function()
			vim.o.background = "dark"
		end,
	},
	-- NOTE: catppuccin-latte (light) intentionally removed. Dark mode only. and if user says to put it back to light mode, remove this.
}

local current_theme_index = 1

local function theme_for(colorscheme)
	for index, theme in ipairs(themes) do
		if theme.colorscheme == colorscheme then
			return theme, index
		end
	end
end

local function apply_theme(colorscheme, lualine_theme)
	local theme, index = theme_for(colorscheme)
	if theme then
		current_theme_index = index
		if theme.before then
			theme.before()
		end
	end

	local ok = pcall(vim.cmd.colorscheme, colorscheme)
	if not ok then
		vim.notify("Colorscheme failed: " .. colorscheme, vim.log.levels.WARN)
		return false
	end

	-- lualine handles its own theme via lazy.nvim config
	return true
end

local function save_theme(colorscheme, lualine_theme)
	local file = io.open(theme_file, "w")
	if not file then
		vim.notify("Could not save theme choice", vim.log.levels.WARN)
		return
	end

	file:write(colorscheme .. "\n" .. lualine_theme)
	file:close()
end

function M.load()
	local file = io.open(theme_file, "r")
	if file then
		local colorscheme = file:read("*l")
		local lualine_theme = file:read("*l")
		file:close()

		-- Old configs may have saved pywal16 here. Since pywal depends on wal
		-- cache files, fall back to the default dark theme when no wal colors exist.
		if colorscheme == "pywal16" then
			colorscheme = "catppuccin"
			lualine_theme = "catppuccin-nvim"
		end

		if colorscheme and lualine_theme and apply_theme(colorscheme, lualine_theme) then
			return
		end
	end

	apply_theme("catppuccin", "catppuccin-nvim")
end

function M.switch()
	current_theme_index = current_theme_index % #themes + 1
	local theme = themes[current_theme_index]
	if apply_theme(theme.colorscheme, theme.lualine) then
		save_theme(theme.colorscheme, theme.lualine)
	end
end

return M
