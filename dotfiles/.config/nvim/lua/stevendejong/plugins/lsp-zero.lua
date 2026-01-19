return {
  "VonHeikemen/lsp-zero.nvim",
  enabled = true,
  branch = "v3.x",
  event = "InsertEnter",
  dependencies = {      
    -- LSP Support
    {"neovim/nvim-lspconfig"},
    {"williamboman/mason.nvim"},
    {"williamboman/mason-lspconfig.nvim"},
    {"davidosomething/format-ts-errors.nvim"},

    -- Autocompletion
    {"hrsh7th/nvim-cmp"},
    {"hrsh7th/cmp-buffer"},
    {"hrsh7th/cmp-path"},
    {"saadparwaiz1/cmp_luasnip"},
    {"hrsh7th/cmp-nvim-lsp"},
    {"hrsh7th/cmp-nvim-lua"},

    -- Snippets
    {"L3MON4D3/LuaSnip"},
    {"rafamadriz/friendly-snippets"},
  },
  config = function()
    local lsp_zero = require("lsp-zero")

    lsp_zero.on_attach(function(client, bufnr)
      local opts = {buffer = bufnr, remap = false}

      vim.keymap.set("n", "<leader>vgd", function() vim.lsp.buf.definition() end, vim.tbl_extend("force", opts, {desc = "Go to Definition"}))
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, vim.tbl_extend("force", opts, {desc = "Hover Documentation"}))
      vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, vim.tbl_extend("force", opts, {desc = "Workspace Symbol"}))
      vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, vim.tbl_extend("force", opts, {desc = "Open Diagnostics"}))
      vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, vim.tbl_extend("force", opts, {desc = "Next Diagnostic"}))
      vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, vim.tbl_extend("force", opts, {desc = "Previous Diagnostic"}))
      vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, vim.tbl_extend("force", opts, {desc = "Code Action"}))
      vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, vim.tbl_extend("force", opts, {desc = "References"}))
      vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, vim.tbl_extend("force", opts, {desc = "Rename"}))
      vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, vim.tbl_extend("force", opts, {desc = "Signature Help"}))
    end)


    -- to learn how to use mason.nvim with lsp-zero
    -- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
    require("mason").setup({})
    require("mason-lspconfig").setup({
      ensure_installed = {
        -- "black",
        "cssls",
        "dockerls",
        "docker_compose_language_service",
        "emmet_language_server",
        "eslint",
        "html",
        "jqls",
        "jsonls",
        "lua_ls",
        "pylsp",
        "bashls",
        "stylelint_lsp",
        -- "tsserver",
        "yamlls",
      },
      handlers = {
        lsp_zero.default_setup,
        lua_ls = function()
          local lua_opts = lsp_zero.nvim_lua_ls()
          require("lspconfig").lua_ls.setup(lua_opts)
        end,
      }
    })

    local cmp = require("cmp")
    local cmp_select = {behavior = cmp.SelectBehavior.Select}

    cmp.setup({
      sources = {
        {name = "path"},
        {name = "nvim_lsp"},
        {name = "nvim_lua"},
        {name = "luasnip", keyword_length = 2},
        {name = "buffer", keyword_length = 3},
      },
      formatting = lsp_zero.cmp_format(),
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
      }),
    })

    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({})
  --   lspconfig.tsserver.setup({
  --     handlers = {
  --       ["textDocument/publishDiagnostics"] = function(
  --         _,
  --         result,
  --         ctx,
  --         config
  --       )
  --         if result.diagnostics == nil then
  --           return
  --         end
  --
  --         -- ignore some tsserver diagnostics
  --         local idx = 1
  --         while idx <= #result.diagnostics do
  --           local entry = result.diagnostics[idx]
  --
  --           local formatter = require('format-ts-errors')[entry.code]
  --           entry.message = formatter and formatter(entry.message) or entry.message
  --
  --           -- codes: https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
  --           if entry.code == 80001 then
  --             -- { message = "File is a CommonJS module; it may be converted to an ES module.", }
  --             table.remove(result.diagnostics, idx)
  --           else
  --             idx = idx + 1
  --           end
  --         end
  --
  --         vim.lsp.diagnostic.on_publish_diagnostics(
  --           _,
  --           result,
  --           ctx,
  --           config
  --         )
  --       end,
  --     },
  --   })
  end,
}
