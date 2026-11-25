-- The colourscheme is local: colors/flat.lua. Nothing to download. Lazy needs the file to return a spec.
return {
  {
    "folke/lazy.nvim",
    optional = true,
    init = function()
      vim.cmd.colorscheme("flat")
    end,
  },
}
