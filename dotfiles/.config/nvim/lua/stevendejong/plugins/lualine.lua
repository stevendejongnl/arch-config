local function lsp_clients()
  local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
  return #names > 0 and (" " .. table.concat(names, ",")) or ""
end

local function venv()
  local v = vim.env.VIRTUAL_ENV
  return v and (" " .. vim.fn.fnamemodify(v, ":h:t")) or ""
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = { globalstatus = true, component_separators = "", section_separators = "" },
    sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { venv, lsp_clients, "diagnostics", "filetype" },
    },
  },
}
