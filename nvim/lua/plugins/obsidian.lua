local M = {}

local function resolve_workspace_path()
	local env_vault = vim.env.OBSIDIAN_VAULT
	if env_vault and env_vault ~= "" then
		return vim.fn.expand(env_vault)
	end

	local current_file = vim.api.nvim_buf_get_name(0)
	local start_path = current_file ~= "" and vim.fs.dirname(current_file) or vim.fn.getcwd()
	local obsidian_dir = vim.fs.find(".obsidian", { path = start_path, upward = true, type = "directory" })[1]
	if obsidian_dir then
		return vim.fs.dirname(obsidian_dir)
	end

	-- Fall back to the main vault instead of cwd so Obsidian commands always
	-- operate on real notes, even when nvim was started outside a vault.
	local main_vault = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents")
	if vim.fn.isdirectory(main_vault .. "/.obsidian") == 1 then
		return main_vault
	end

	return vim.fn.getcwd()
end

function M.setup()
	local vault_path = resolve_workspace_path()

	require("obsidian").setup({
		legacy_commands = false,
		workspaces = {
			{
				name = "personal",
				path = vault_path,
			},
		},
		picker = {
			name = "fzf-lua",
		},
	})
end

return M
