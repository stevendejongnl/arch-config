return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    cmd = { "MasonToolsInstall", "MasonToolsInstallSync", "MasonToolsUpdate" },
    opts = {
      ensure_installed = {
        -- LSP servers (names are mason package names)
        "basedpyright", "ruff", "vtsls", "vue-language-server", "eslint-lsp", "lua-language-server",
        "bash-language-server", "css-lsp", "html-lsp", "json-lsp", "yaml-language-server",
        "dockerfile-language-server", "docker-compose-language-service", "emmet-language-server",
        "stylelint-lsp", "jq-lsp", "rust-analyzer",
        -- formatters / linters
        "prettierd", "stylua", "shfmt", "flake8", "mypy",
        -- debuggers
        "debugpy", "js-debug-adapter",
      },
      auto_update = false,
    },
  },
}
