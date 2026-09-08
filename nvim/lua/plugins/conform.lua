require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff_format" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		rust = { "rustfmt" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		-- markdown intentionally excluded: prettier rewrites vault notes on save,
		-- which creates sync churn. Format markdown manually if ever needed.
		yaml = { "prettier" },
	},
	format_on_save = function(bufnr)
		local disabled_filetypes = {
			c = true,
			cpp = true,
		}
		if disabled_filetypes[vim.bo[bufnr].filetype] then
			return nil
		end
		return {
			timeout_ms = 1000,
			lsp_format = "fallback",
		}
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>fm", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
