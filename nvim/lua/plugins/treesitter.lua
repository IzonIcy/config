local ok_ts, treesitter = pcall(require, "nvim-treesitter")
if not ok_ts then
	vim.notify("nvim-treesitter not installed. Run :Lazy sync", vim.log.levels.WARN)
	return
end

local languages = {
	"bash",
	"c",
	"cpp",
	"css",
	"go",
	"html",
	"java",
	"javascript",
	"json",
	"latex",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"tsx",
	"typescript",
	"yaml",
}

treesitter.setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

treesitter.install(languages)

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
	pattern = languages,
	callback = function()
		pcall(vim.treesitter.start)
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo.foldmethod = "expr"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
