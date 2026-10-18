return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "igorlfs/nvim-dap-view",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dap-view").toggle() end, desc = "Toggle debug view" },
      { "<leader>de", function() require("dap.ui.widgets").hover() end, desc = "Eval under cursor", mode = { "n", "v" } },
    },
    config = function()
      local dap = require("dap")
      local mason = vim.fn.stdpath("data") .. "/mason/packages"

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

      require("dap-view").setup({ auto_toggle = true })

      -- Python: debugpy from Mason, falls back to project .venv python
      require("dap-python").setup(mason .. "/debugpy/venv/bin/python")
      table.insert(dap.configurations.python, {
        type = "python",
        request = "attach",
        name = "Attach to container (localhost:5678)",
        connect = { host = "127.0.0.1", port = 5678 },
        pathMappings = {
          { localRoot = function() return vim.fn.getcwd() end, remoteRoot = "/srv" },
        },
      })

      -- JS/TS: js-debug-adapter
      for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { mason .. "/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
          },
        }
      end
      for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[ft] = {
          { type = "pwa-node", request = "launch", name = "Launch file", program = "${file}", cwd = "${workspaceFolder}" },
          { type = "pwa-node", request = "attach", name = "Attach to process", processId = require("dap.utils").pick_process, cwd = "${workspaceFolder}" },
          { type = "pwa-chrome", request = "launch", name = "Chrome (localhost:5173)", url = "http://localhost:5173", webRoot = "${workspaceFolder}" },
        }
      end
    end,
  },
}
