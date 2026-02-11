return {
  "theprimeagen/harpoon",
  enable = true,
  branch = "harpoon2",
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
