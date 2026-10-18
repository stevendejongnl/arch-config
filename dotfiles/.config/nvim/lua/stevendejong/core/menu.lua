-- Right-click menu: replaces the 0.12 default so every entry shows its shortcut.
pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")
vim.cmd.aunmenu("PopUp")

local function esc(s)
  return (s:gsub(" ", "\\ "):gsub("%.", "\\."))
end

local function item(modes, label, shortcut, rhs)
  local name = esc(label) .. (shortcut and ("<Tab>" .. esc(shortcut)) or "")
  vim.cmd(string.format("%snoremenu PopUp.%s %s", modes, name, rhs))
end

local lsp_items = {}
local function lsp(label, shortcut, cmd)
  item("n", label, shortcut, "<Cmd>" .. cmd .. "<CR>")
  lsp_items[#lsp_items + 1] = esc(label)
end

lsp("Go to Definition", "gd", "lua vim.lsp.buf.definition()")
lsp("Go to Declaration", "gD", "lua vim.lsp.buf.declaration()")
lsp("Type Definition", "grt", "lua vim.lsp.buf.type_definition()")
lsp("Implementations", "gi", "lua Snacks.picker.lsp_implementations()")
lsp("References", "gr", "lua Snacks.picker.lsp_references()")
lsp("Hover Docs", "K", "lua vim.lsp.buf.hover()")
lsp("Rename", "grn", "lua vim.lsp.buf.rename()")
lsp("Code Action", "gra", "lua vim.lsp.buf.code_action()")
lsp("Incoming Calls", "Space vi", "Trouble lsp_incoming_calls toggle")
lsp("Outgoing Calls", "Space vI", "Trouble lsp_outgoing_calls toggle")
lsp("Organize Imports", "Space vo", "lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })")
item("n", "Format", "Space cf", "<Cmd>lua require('conform').format({ async = true })<CR>")
vim.cmd("anoremenu PopUp.-1- <Nop>")

item("n", "Line Diagnostics", "Space i", "<Cmd>lua vim.diagnostic.open_float({ scope = 'line' })<CR>")
item("n", "Project Diagnostics", "Space xx", "<Cmd>Trouble diagnostics toggle<CR>")
vim.cmd("anoremenu PopUp.-2- <Nop>")

item("n", "Toggle Breakpoint", "Space db", "<Cmd>lua require('dap').toggle_breakpoint()<CR>")
item("n", "Run Nearest Test", "Space tt", "<Cmd>lua require('stevendejong.runner').nearest()<CR>")
item("n", "Debug in Docker", "Space dD", "<Cmd>lua require('stevendejong.runner').debug_docker()<CR>")
item("n", "Debug Nearest Test", "Space td", "<Cmd>lua require('neotest').run.run({ strategy = 'dap' })<CR>")
vim.cmd("anoremenu PopUp.-3- <Nop>")

item("v", "Cut", nil, '"+x')
item("v", "Copy", nil, '"+y')
item("n", "Paste", nil, '"+gP')
item("v", "Paste", nil, '"+P')
item("v", "Delete", nil, '"_x')
item("n", "Select All", nil, "ggVG")
item("v", "Select All", nil, "gg0oG$")

-- Grey out LSP entries when no server is attached
vim.api.nvim_create_autocmd("MenuPopup", {
  group = vim.api.nvim_create_augroup("stevendejong_menu", { clear = true }),
  callback = function()
    local attached = vim.lsp.get_clients({ bufnr = 0 })[1] ~= nil
    for _, name in ipairs(lsp_items) do
      vim.cmd(string.format("nmenu %s PopUp.%s", attached and "enable" or "disable", name))
    end
  end,
})
