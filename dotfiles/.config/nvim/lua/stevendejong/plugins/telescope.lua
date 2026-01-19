return {
  "nvim-telescope/telescope.nvim",
  enabled = true,
  tag = "0.1.5",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim"
  },
  event = "VeryLazy",
  config = function()
    require("telescope").load_extension("live_grep_args")
    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Fuzzy find files in cwd" })
    vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Fuzzy find files in git project" })
    vim.keymap.set("n", "<leader>pg", require("telescope").extensions.live_grep_args.live_grep_args, { desc = "Use ripgrep search with args", noremap = true })
    vim.keymap.set("n", "<leader>ps", function()
      builtin.grep_string({ search = vim.fn.input("Grep > ") });
    end, { desc = "Grep string in file" })
  end,
}
