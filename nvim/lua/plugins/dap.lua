local dap = require("dap")
local dapui = require("dapui")

require("mason-nvim-dap").setup({
  ensure_installed = { "debugpy", "codelldb", "delve" },
})

dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
  controls = {
    icons = {
      pause = "⏸",
      play = "▶",
      step_into = "⏎",
      step_over = "⏭",
      step_out = "⏮",
      step_back = "b",
      run_last = "▶▶",
      terminate = "⏹",
    },
  },
})

require("nvim-dap-virtual-text").setup()

dap.listeners.before.attach.dapui = dapui.open
dap.listeners.before.launch.dapui = dapui.open
dap.listeners.before.event_terminated.dapui = dapui.close
dap.listeners.before.event_exited.dapui = dapui.close

dap.adapters.python = {
  type = "executable",
  command = "python3",
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
  },
}

dap.configurations.rust = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.c = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.cpp = dap.configurations.c

dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
}
