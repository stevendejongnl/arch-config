return {
  "tpope/vim-fugitive",
  enabled = false,
  event = "VeryLazy",
  config = function()
    vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
  end,
}
