local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
  languages = { "vue" },
  configNamespace = "typescript",
}

local inlay = {
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  variableTypes = { enabled = false },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

return {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      tsserver = { globalPlugins = { vue_plugin } },
      experimental = { completion = { enableServerSideFuzzyMatch = true } },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      inlayHints = inlay,
      tsserver = { maxTsServerMemory = 8192 },
    },
    javascript = { updateImportsOnFileMove = { enabled = "always" }, inlayHints = inlay },
  },
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx)
      if result and result.diagnostics then
        local formatters = require("format-ts-errors")
        local kept = {}
        for _, d in ipairs(result.diagnostics) do
          if d.code ~= 80001 then -- "File is a CommonJS module" hint
            local fmt = formatters[d.code]
            d.message = fmt and fmt(d.message) or d.message
            kept[#kept + 1] = d
          end
        end
        result.diagnostics = kept
      end
      vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
    end,
  },
}
