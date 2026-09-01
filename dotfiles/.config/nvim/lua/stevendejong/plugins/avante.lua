return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "ravitemer/mcphub.nvim",
  },
  opts = {
    provider = "claude-code",
    acp_providers = {
      ["claude-code"] = {
        command = "npx",
        args = { "-y", "-g", "@zed-industries/claude-code-acp" },
        env = {
          NODE_NO_WARNINGS = "1",
          CLAUDE_CONFIG_DIR = vim.fn.expand("~/.claude/accounts/work"),
          ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
          ACP_PERMISSION_MODE = "bypassPermissions",
        },
      },
    },
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      return hub and hub:get_active_servers_prompt() or ""
    end,
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
      }
    end,
  },
}
