return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Parent directory (oil)" },
    { "<leader>pv", "<cmd>Oil<CR>", desc = "File explorer (oil)" },
  },
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = { show_hidden = true },
    keymaps = { ["<C-h>"] = false, ["<C-l>"] = false }, -- keep tmux-navigator
  },
}
