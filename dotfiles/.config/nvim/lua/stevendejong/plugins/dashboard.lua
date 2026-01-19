return {
  "nvimdev/dashboard-nvim",
  enabled = true,
  event = "VimEnter",
  config = function()
    require("dashboard").setup {
      theme = "hyper",
      config = {
        header = {
          " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
          " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
          " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
          " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
          " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
          " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
        },
        -- shortcut = {
        --   {
        --     desc = '󰊳 Update',
        --     group = 'DashboardShortcutIcons',
        --     action = 'Lazy update',
        --     key = 'u'
        --   },
        --   {
        --     desc = ' Files',
        --     group = 'DashboardShortcutIcons',
        --     action = 'Telescope find_files',
        --     key = 'f',
        --   },
        --   {
        --     desc = '  Workspace',
        --     group = 'DashboardShortcutIcons',
        --     action = 'edit ~/workspace',
        --     key = 'w',
        --   },
        --   {
        --     desc = ' dotfiles',
        --     group = 'DashboardShortcutIcons',
        --     action = 'edit ~/dotfiles',
        --     key = 'd',
        --   },
        -- }
      }
    }
    vim.keymap.set("n", "<C-q>", vim.cmd.Dashboard)
  end,
}
