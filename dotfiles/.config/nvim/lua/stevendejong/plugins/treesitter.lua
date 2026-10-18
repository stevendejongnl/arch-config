local parsers = {
  "bash", "c", "css", "diff", "dockerfile", "html", "javascript", "json", "jsdoc", "lua", "luadoc",
  "markdown", "markdown_inline", "python", "query", "regex", "requirements", "rst", "rust", "scss",
  "svelte", "swift", "toml", "tsx", "typescript", "vim", "vimdoc", "vue", "xml", "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()
      ts.install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("stevendejong_treesitter", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select").select_textobject
      for key, query in pairs({
        af = "@function.outer", ["if"] = "@function.inner",
        ac = "@class.outer", ic = "@class.inner",
        aa = "@parameter.outer", ia = "@parameter.inner",
      }) do
        vim.keymap.set({ "x", "o" }, key, function() select(query, "textobjects") end, { desc = query })
      end

      local move = require("nvim-treesitter-textobjects.move")
      local moves = {
        { "]f", "goto_next_start", "@function.outer" }, { "]c", "goto_next_start", "@class.outer" },
        { "]a", "goto_next_start", "@parameter.inner" }, { "]F", "goto_next_end", "@function.outer" },
        { "]C", "goto_next_end", "@class.outer" }, { "[f", "goto_previous_start", "@function.outer" },
        { "[c", "goto_previous_start", "@class.outer" }, { "[a", "goto_previous_start", "@parameter.inner" },
        { "[F", "goto_previous_end", "@function.outer" }, { "[C", "goto_previous_end", "@class.outer" },
      }
      for _, m in ipairs(moves) do
        vim.keymap.set({ "n", "x", "o" }, m[1], function() move[m[2]](m[3], "textobjects") end, { desc = m[3] })
      end

      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>sa", function() swap.swap_next("@parameter.inner") end, { desc = "Swap with next argument" })
      vim.keymap.set("n", "<leader>sA", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap with previous argument" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = { max_lines = 3, multiline_threshold = 1 },
    keys = { { "<leader>ut", "<cmd>TSContext toggle<CR>", desc = "Toggle sticky context" } },
  },
}
