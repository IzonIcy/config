require("bqf").setup({
  auto_enable = true,
  preview = {
    win_height = 12,
    show_title = true,
    should_preview = function(bufnr)
      return vim.api.nvim_buf_line_count(bufnr) > 1
    end,
  },
  func_map = {
    open = "o",
    openc = "O",
    drop = "<CR>",
    split = "<C-s>",
    vsplit = "<C-v>",
    tab = "<C-t>",
    prevfile = "<C-p>",
    nextfile = "<C-n>",
  },
})
