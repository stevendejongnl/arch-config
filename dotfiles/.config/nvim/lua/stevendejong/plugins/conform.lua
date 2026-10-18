local web = { "prettierd", "prettier", stop_after_first = true }

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true }) end,
      mode = { "n", "v" },
      desc = "Format buffer/selection",
    },
    {
      "<leader>uf",
      function()
        vim.g.autoformat = not (vim.g.autoformat ~= false)
        vim.notify("Format on save: " .. (vim.g.autoformat and "on" or "off"))
      end,
      desc = "Toggle format on save",
    },
  },
  opts = {
    formatters_by_ft = {
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      javascript = web, typescript = web, javascriptreact = web, typescriptreact = web, vue = web,
      css = web, scss = web, html = web, json = web, jsonc = web, yaml = web, markdown = web,
      lua = { "stylua" },
      sh = { "shfmt" },
      bash = { "shfmt" },
    },
    format_on_save = function(bufnr)
      if vim.g.autoformat == false then
        return
      end
      -- Skip projects that lint in CI via flake8 and have no ruff config: avoid reformatting legacy code
      local root = vim.fs.root(bufnr, { "pyproject.toml", "ruff.toml", ".ruff.toml", "setup.cfg", ".flake8" })
      if vim.bo[bufnr].filetype == "python" and root then
        local has_ruff = vim.uv.fs_stat(root .. "/ruff.toml") or vim.uv.fs_stat(root .. "/.ruff.toml")
        if not has_ruff then
          local f = io.open(root .. "/pyproject.toml")
          local txt = f and f:read("*a") or ""
          if f then f:close() end
          has_ruff = txt:find("%[tool%.ruff")
        end
        if not has_ruff then
          return
        end
      end
      return { timeout_ms = 2000, lsp_format = "fallback" }
    end,
  },
}
