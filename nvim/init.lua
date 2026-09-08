-- My nvim config
-- keybinds are located in lua/config/mappings.lua

vim.g.start_time = vim.fn.reltime()
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.loader.enable()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.autocmd")
require("config.mappings")

require("lazy").setup({
	-- colorschemes
	{ "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
	{ "ellisonleao/gruvbox.nvim", name = "gruvbox", lazy = true },
	{ "uZer/pywal16.nvim", name = "pywal16", lazy = true },

	-- ui
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local theme_file = vim.fn.stdpath("config") .. "/lua/config/saved_theme"
			local lualine_theme = "catppuccin-nvim"
			local file = io.open(theme_file, "r")
			if file then
				file:read("*l") -- skip colorscheme line
				lualine_theme = file:read("*l") or "catppuccin-nvim"
				file:close()
			end
			require("plugins.lualine").setup(lualine_theme)
		end,
	},
	{
		"romgrk/barbar.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons", "lewis6991/gitsigns.nvim" },
		config = function()
			require("plugins.barbar")
		end,
	},
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.alpha")
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("plugins.which-key")
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFindFile" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.nvim-tree")
		end,
	},
	{
		"folke/twilight.nvim",
		cmd = "Twilight",
		config = function()
			require("plugins.twilight")
		end,
	},

	-- editing
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("plugins.treesitter")
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("plugins.autopairs")
		end,
	},
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		config = function()
			require("plugins.comment")
		end,
	},
	{
		"norcalli/nvim-colorizer.lua",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("plugins.colorizer")
		end,
	},
	{ "ron-rs/ron.vim", ft = "ron" },
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.render-markdown")
		end,
	},
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*",
		ft = "markdown",
		dependencies = { "ibhagwan/fzf-lua" },
		keys = {
			{ "<leader>os", "<Cmd>Obsidian search<CR>", desc = "Search vault" },
			{ "<leader>oq", "<Cmd>Obsidian quick_switch<CR>", desc = "Quick switch notes" },
			{ "<leader>of", "<Cmd>Obsidian follow_link<CR>", desc = "Follow link under cursor" },
			{ "<leader>on", "<Cmd>Obsidian new<CR>", desc = "New note" },
			{ "<leader>ob", "<Cmd>Obsidian backlinks<CR>", desc = "Show backlinks" },
			{ "<leader>ot", "<Cmd>Obsidian toggle_checkbox<CR>", desc = "Toggle checkbox" },
			{ "<leader>oo", "<Cmd>Obsidian open<CR>", desc = "Open in Obsidian app" },
		},
		config = function()
			require("plugins.obsidian").setup()
		end,
	},
	{ "emmanueltouzery/decisive.nvim", ft = "csv" },

	-- search, terminal, git
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.fzf-lua")
		end,
	},
	{
		"numToStr/FTerm.nvim",
		cmd = "FTerm",
		config = function()
			require("plugins.fterm")
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("plugins.gitsigns")
		end,
	},

	-- lsp, completion, linting, formatting
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
		config = function()
			require("plugins.mason-tool-installer")
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("plugins.lsp")
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("plugins.cmp")
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "BufNewFile" },
		config = function()
			require("plugins.nvim-lint")
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("plugins.conform")
		end,
	},

	-- debugging
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			require("plugins.dap")
		end,
	},

	-- ui enhancements
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
		config = function()
			require("plugins.indent-blankline")
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.todo-comments")
		end,
	},
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
		config = function()
			require("plugins.bqf")
		end,
	},

	-- project & sessions
	{
		"ahmedkhalf/project.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("plugins.project")
		end,
	},
	{
		"folke/persistence.nvim",
		event = "VeryLazy",
		config = function()
			require("plugins.persistence")
		end,
	},

	-- editing enhancements
	{
		"mg979/vim-visual-multi",
		event = "VeryLazy",
	},
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		config = function()
			require("plugins.undotree")
		end,
	},

	-- code runner
	{
		"stevearc/overseer.nvim",
		cmd = { "OverseerRun", "OverseerToggle" },
		config = function()
			require("plugins.overseer")
		end,
	},
}, {
	rocks = { enabled = false },
})

require("plugins.colorscheme")
require("config.theme").load()
