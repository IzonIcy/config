local ok_mason, mason = pcall(require, "mason")
if not ok_mason then
	vim.notify("mason.nvim not installed. Run :PlugInstall", vim.log.levels.WARN)
	return
end

local ok_mason_lsp, mason_lspconfig = pcall(require, "mason-lspconfig")
if not ok_mason_lsp then
	vim.notify("mason-lspconfig not installed. Run :PlugInstall", vim.log.levels.WARN)
	return
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
	capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

local function on_attach(_, bufnr)
	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
	end

	map("n", "gd", vim.lsp.buf.definition, "LSP definition")
	map("n", "gD", vim.lsp.buf.declaration, "LSP declaration")
	map("n", "gi", vim.lsp.buf.implementation, "LSP implementation")
	map("n", "gr", vim.lsp.buf.references, "LSP references")
	map("n", "K", vim.lsp.buf.hover, "LSP hover")
	map("n", "<leader>rn", vim.lsp.buf.rename, "LSP rename")
	map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
	map("n", "<leader>ld", vim.diagnostic.open_float, "LSP diagnostics")
	map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
	map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
	map("n", "<leader>ih", function()
		local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
		vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
	end, "Toggle inlay hints")
end

mason.setup()

local servers = {
	"lua_ls",
	"pyright",
	"bashls",
	"clangd",
	"rust_analyzer",
	"gopls",
	"jdtls",
	"cssls",
	"html",
	"jsonls",
}

mason_lspconfig.setup({
	ensure_installed = servers,
})

local function server_config(server_name)
	local config = {
		on_attach = on_attach,
		capabilities = capabilities,
	}

	if server_name == "lua_ls" then
		config.settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = { enable = false },
			},
		}
	end

	if server_name == "jdtls" then
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
		local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name
		vim.fn.mkdir(workspace_dir, "p")
		config.settings = {
			java = {},
		}
		config.init_options = {
			bundles = {},
		}
	end

	return config
end

if vim.lsp.config and vim.lsp.enable then
	if not vim.lsp.config[servers[1]] then
		vim.notify("nvim-lspconfig configs not found. Run :PlugInstall", vim.log.levels.WARN)
		return
	end

	for _, server_name in ipairs(servers) do
		vim.lsp.config(server_name, server_config(server_name))
		vim.lsp.enable(server_name)
	end
	return
end

if vim.fn.has("nvim-0.11") == 1 then
	vim.notify("vim.lsp.config not available. Update Neovim or nvim-lspconfig.", vim.log.levels.WARN)
	return
end

local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
	vim.notify("nvim-lspconfig not installed. Run :PlugInstall", vim.log.levels.WARN)
	return
end

for _, server_name in ipairs(servers) do
	lspconfig[server_name].setup(server_config(server_name))
end
