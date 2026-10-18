return {
  {
    "neovim/nvim-lspconfig", -- supplies default server definitions (lsp/*.lua on rtp)
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "b0o/SchemaStore.nvim",
      "davidosomething/format-ts-errors.nvim",
    },
    config = function()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
      end

      vim.lsp.enable({
        "basedpyright", "ruff", "vtsls", "vue_ls", "eslint", "lua_ls", "bashls", "cssls", "html",
        "jsonls", "yamlls", "dockerls", "docker_compose_language_service", "emmet_language_server",
        "stylelint_lsp", "jqls", "rust_analyzer", "sourcekit",
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("stevendejong_lsp", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          -- 0.12 defaults already give: grn rename, gra action, grr refs, gri impl, grt type, gO symbols, K hover
          map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
          map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace Symbol")
          map("n", "<leader>vd", vim.diagnostic.open_float, "Open Diagnostics")
          map("n", "<leader>vca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>vt", vim.lsp.buf.type_definition, "Type Definition")
          map("i", "<C-h>", vim.lsp.buf.signature_help, "Signature Help")
          map("n", "<leader>vo", function()
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
          end, "Organize Imports")

          if client and client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
            end, "Toggle Inlay Hints")
          end
          if client and client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, { bufnr = ev.buf })
          end
        end,
      })
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
  },
}
