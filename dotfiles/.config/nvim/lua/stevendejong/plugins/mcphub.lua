return {
  "ravitemer/mcphub.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  build = "source ~/.nvm/nvm.sh && nvm use --lts && npm install -g mcp-hub@latest",
  config = function()
    -- Use explicit path to mcp-hub in latest LTS Node version
    -- This bypasses nvm's lazy-loading, ensuring mcp-hub is available when Neovim starts
    require("mcphub").setup({
      cmd = vim.fn.expand("~/.npm-global/bin/mcp-hub"),
      cmdArgs = {},
    })
  end,
}
