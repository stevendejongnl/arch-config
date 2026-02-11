return {
  "theprimeagen/harpoon",
  enabled = true,
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>a", desc = "Harpoon: Add File" },
    { "<C-e>", desc = "Harpoon: Toggle Menu" },
    { "<C-u>", desc = "Harpoon: Slot 1" },
    { "<C-i>", desc = "Harpoon: Slot 2" },
    { "<C-o>", desc = "Harpoon: Slot 3" },
    { "<C-p>", desc = "Harpoon: Slot 4" },
    { "<C-S-P>", desc = "Harpoon: Prev" },
    { "<C-S-N>", desc = "Harpoon: Next" },
  },
  config = function()
    local harpoon = require("harpoon")

    harpoon:setup()

    vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: Add File" })
    vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon: Toggle Menu" })

    vim.keymap.set("n", "<C-u>", function() harpoon:list():select(1) end, { desc = "Harpoon: Slot 1" })
    vim.keymap.set("n", "<C-i>", function() harpoon:list():select(2) end, { desc = "Harpoon: Slot 2" })
    vim.keymap.set("n", "<C-o>", function() harpoon:list():select(3) end, { desc = "Harpoon: Slot 3" })
    vim.keymap.set("n", "<C-p>", function() harpoon:list():select(4) end, { desc = "Harpoon: Slot 4" })

    vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Harpoon: Prev" })
    vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Harpoon: Next" })
  end,
}
