return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>p", group = "Search/Files" },
      { "<leader>g", group = "Git" },
      { "<leader>gh", group = "Git Hunks" },
      { "<leader>v", group = "LSP" },
      { "<leader>c", group = "Code" },
      { "<leader>s", group = "Swap/Search" },
      { "<leader>j", group = "Jump" },
      { "<leader>h", group = "Harpoon" },
      { "<leader>d", group = "Debug" },
      { "<leader>t", group = "Test" },
      { "<leader>x", group = "Diagnostics (trouble)" },
      { "<leader>u", group = "Toggles" },
      { "<leader>q", group = "Session" },
      { "<leader>b", group = "Buffer" },
    },
  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
  },
}
