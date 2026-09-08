-- catppuccin + gruvbox colorscheme configuration

local ok_catppuccin, catppuccin = pcall(require, "catppuccin")
if ok_catppuccin then
	catppuccin.setup({
		flavour = "mocha",
		transparent_background = true,
		styles = {
			sidebars = "transparent",
			floats = "transparent",
		},
	})
end

local ok_gruvbox, gruvbox = pcall(require, "gruvbox")
if ok_gruvbox then
	gruvbox.setup({
		terminal_colors = true,
		undercurl = true,
		underline = true,
		bold = true,
		italic = {
			strings = true,
			emphasis = true,
			comments = true,
			operators = false,
			folds = true,
		},
		strikethrough = true,
		invert_selection = false,
		invert_signs = false,
		invert_tabline = false,
		inverse = true,
		contrast = "",
		palette_overrides = {},
		overrides = {},
		dim_inactive = false,
		transparent_mode = true,
	})
end
