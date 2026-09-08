require("project_nvim").setup({
  detection_methods = { "pattern", "lsp" },
  patterns = { ".git", "Makefile", "Cargo.toml", "go.mod", "pyproject.toml", "package.json", "CMakeLists.txt" },
  sync_root_with_lsp = true,
})
