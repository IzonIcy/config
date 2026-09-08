require("persistence").setup({
  dir = vim.fn.stdpath("state") .. "/sessions/",
  options = { "buffers", "curdir", "tabpages", "winsize", "help" },
  pre_save = nil,
  save_empty = false,
})

vim.keymap.set("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore session" })

vim.keymap.set("n", "<leader>qS", function()
  require("persistence").select()
end, { desc = "Select session" })

vim.keymap.set("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore last session" })

vim.keymap.set("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't save current session" })
