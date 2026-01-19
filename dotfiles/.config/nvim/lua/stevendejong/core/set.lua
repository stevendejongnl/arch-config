-- vim.opt.mouse = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.colorcolumn = "120"

vim.opt.smartindent = true

vim.opt.textwidth = 120
vim.opt.wrap = true
vim.opt.wrapmargin = 0

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- _G.delete_directory = function()
--     local cursor_pos = vim.api.nvim_win_get_cursor(0)
--     local line = vim.api.nvim_buf_get_lines(0, cursor_pos[1]-1, cursor_pos[1], false)[1]
--     local path = vim.fn.fnamemodify(line, ':p:h')
--     local file = path .. '/' .. line
--     local choice = vim.fn.input('Delete ' .. file .. '? (y/n): ')
--     if choice == 'y' then
--         vim.fn.delete(file, 'rf')
--         vim.cmd('e .')
--     end
--     print(file)
-- end
--
-- vim.cmd([[
--     autocmd FileType netrw nnoremap <buffer> D :lua delete_directory()<CR>
-- ]])

-- Transparent background
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
