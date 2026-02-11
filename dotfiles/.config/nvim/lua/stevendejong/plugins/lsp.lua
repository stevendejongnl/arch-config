return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    { "mason-org/mason-lspconfig.nvim" },
    { "davidosomething/format-ts-errors.nvim" },
  },
  config = function()
    local lspconfig = require("lspconfig")

    -- Shared on_attach: custom keybindings (Neovim 0.11 provides K, grn, grr, gra natively)
    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, remap = false }

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to Definition" }))
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to Declaration" }))
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to Implementation" }))
      vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
      vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))
      vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, vim.tbl_extend("force", opts, { desc = "Workspace Symbol" }))
      vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Open Diagnostics" }))
      vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, vim.tbl_extend("force", opts, { desc = "Previous Diagnostic" }))
      vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, vim.tbl_extend("force", opts, { desc = "Next Diagnostic" }))
      vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code Action" }))
      vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
      vim.keymap.set("n", "<leader>vt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type Definition" }))
      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature Help" }))
    end

    -- Shared capabilities (extended by blink.cmp if available)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
      capabilities = blink.get_lsp_capabilities(capabilities)
    end

    -- mason-lspconfig: install servers + auto-enable with defaults
    require("mason-lspconfig").setup({
      ensure_installed = {
        "bashls",
        "cssls",
        "dockerls",
        "docker_compose_language_service",
        "emmet_language_server",
        "eslint",
        "html",
        "jqls",
        "jsonls",
        "lua_ls",
        "basedpyright",
        "stylelint_lsp",
        "vtsls",
        "yamlls",
      },
      automatic_enable = true,
    })

    -- Apply on_attach and capabilities to all servers via LspAttach
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          on_attach(client, args.buf)
        end
      end,
    })

    -- Server-specific overrides

    -- Lua: add Neovim runtime paths
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME },
          },
        },
      },
    })

    -- Python: basedpyright with standard type checking
    lspconfig.basedpyright.setup({
      capabilities = capabilities,
      settings = {
        basedpyright = {
          typeCheckingMode = "standard",
        },
      },
    })

    -- TypeScript: vtsls with format-ts-errors diagnostics handler
    lspconfig.vtsls.setup({
      capabilities = capabilities,
      handlers = {
        ["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
          if result.diagnostics == nil then
            return
          end

          local idx = 1
          while idx <= #result.diagnostics do
            local entry = result.diagnostics[idx]

            local formatter = require("format-ts-errors")[entry.code]
            entry.message = formatter and formatter(entry.message) or entry.message

            if entry.code == 80001 then
              table.remove(result.diagnostics, idx)
            else
              idx = idx + 1
            end
          end

          vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
        end,
      },
    })
  end,
}
