return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
    "thenbe/neotest-playwright",
  },
  keys = {
    { "<leader>tt", function() require("stevendejong.runner").nearest() end, desc = "Run nearest" },
    { "<leader>tf", function() require("stevendejong.runner").file() end, desc = "Run file" },
    { "<leader>ta", function() require("stevendejong.runner").all() end, desc = "Run all" },
    { "<leader>tl", function() require("stevendejong.runner").last() end, desc = "Run last" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, short = true }) end, desc = "Output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Output panel" },
    { "<leader>tx", function() require("neotest").run.stop() end, desc = "Stop" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          runner = "pytest",
          python = function()
            local root = vim.fs.root(0, { ".venv", "pyproject.toml", "setup.cfg", ".git" }) or vim.uv.cwd()
            local py = root .. "/.venv/bin/python"
            return vim.uv.fs_stat(py) and py or "python3"
          end,
        }),
        require("neotest-vitest"),
        require("neotest-jest")({ jestCommand = "npx jest" }),
        require("neotest-playwright").adapter({ options = { persist_project_selection = true } }),
      },
    })
  end,
}
