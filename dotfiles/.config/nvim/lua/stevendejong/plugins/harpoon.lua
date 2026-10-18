return {
  "theprimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  keys = function()
    local function h() return require("harpoon") end
    local keys = {
      { "<leader>ha", function() h():list():add() end, desc = "Harpoon: Add File" },
      { "<C-e>", function() h().ui:toggle_quick_menu(h():list()) end, desc = "Harpoon: Menu" },
      { "<leader>hn", function() h():list():next() end, desc = "Harpoon: Next" },
      { "<leader>hp", function() h():list():prev() end, desc = "Harpoon: Prev" },
    }
    for i = 1, 4 do
      keys[#keys + 1] = { "<leader>" .. i, function() h():list():select(i) end, desc = "Harpoon: Slot " .. i }
    end
    return keys
  end,
}
