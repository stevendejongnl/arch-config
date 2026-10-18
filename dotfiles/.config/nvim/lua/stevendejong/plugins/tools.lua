return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (project)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
      { "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", desc = "References" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix" },
    },
  },
  {
    "stevearc/aerial.nvim",
    cmd = "AerialToggle",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = { layout = { default_direction = "right", min_width = 30 } },
    keys = { { "<leader>o", "<cmd>AerialToggle<CR>", desc = "Outline (structure)" } },
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      { "<leader>sr", function() require("grug-far").open() end, desc = "Search & replace (project)" },
      { "<leader>sr", function() require("grug-far").with_visual_selection() end, mode = "x", desc = "Replace selection" },
      { "<leader>sf", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end, desc = "Replace in file" },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    branch = "main",
    cmd = "VenvSelect",
    ft = "python",
    dependencies = { "neovim/nvim-lspconfig", "mfussenegger/nvim-dap-python" },
    opts = {},
    keys = { { "<leader>cv", "<cmd>VenvSelect<CR>", desc = "Select Python venv" } },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save session" },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    keys = {
      { "<leader>re", function() return require("refactoring").refactor("Extract Function") end, mode = "x", expr = true, desc = "Extract function" },
      { "<leader>rf", function() return require("refactoring").refactor("Extract Function To File") end, mode = "x", expr = true, desc = "Extract function to file" },
      { "<leader>rv", function() return require("refactoring").refactor("Extract Variable") end, mode = "x", expr = true, desc = "Extract variable" },
      { "<leader>ri", function() return require("refactoring").refactor("Inline Variable") end, mode = { "n", "x" }, expr = true, desc = "Inline variable" },
      { "<leader>rI", function() return require("refactoring").refactor("Inline Function") end, mode = "n", expr = true, desc = "Inline function" },
      { "<leader>rb", function() return require("refactoring").refactor("Extract Block") end, mode = "n", expr = true, desc = "Extract block" },
      { "<leader>rm", function() Snacks.rename.rename_file() end, desc = "Rename/move file (updates imports)" },
    },
  },
}
