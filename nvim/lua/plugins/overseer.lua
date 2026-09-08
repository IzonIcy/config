require("overseer").setup({
  templates = { "builtin", "user" },
  task_list = {
    direction = "bottom",
    min_height = 10,
    max_height = 15,
    default_detail = 1,
  },
})
