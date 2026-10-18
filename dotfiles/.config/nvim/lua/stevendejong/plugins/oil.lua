return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Parent directory (oil)" },
    { "<leader>pv", "<cmd>Oil<CR>", desc = "File explorer (oil)" },
  },
  init = function()
    -- let LSP servers update imports when files are moved/renamed in oil
    vim.api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      callback = function(ev)
        local action = ev.data.actions[1]
        if action and action.type == "move" then
          Snacks.rename.on_rename_file((action.src_url:gsub("^oil://", "")), (action.dest_url:gsub("^oil://", "")))
        end
      end,
    })
  end,
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = { show_hidden = true },
    keymaps = { ["<C-h>"] = false, ["<C-l>"] = false }, -- keep tmux-navigator
  },
}
