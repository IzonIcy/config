require("mason-tool-installer").setup({
	ensure_installed = {
		"stylua",
		"ruff",
		"shfmt",
		"prettier",
		"shellcheck",
		"stylelint",
		"htmlhint",
	},
	auto_update = false,
	run_on_start = true,
	start_delay = 3000,
})
