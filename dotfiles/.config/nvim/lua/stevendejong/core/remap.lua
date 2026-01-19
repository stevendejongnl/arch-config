vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Show diagnostics
vim.keymap.set("n", "<leader>i", ":lua vim.diagnostic.open_float(0, {scope='line'})<CR>")

-- LSP
-- vim.keymap.set("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>")
-- vim.keymap.set("n", "<leader>cd", ":lua vim.lsp.buf.definition()<CR>")
-- vim.keymap.set("n", "<leader>cr", ":lua vim.lsp.buf.references()<CR>")
-- vim.keymap.set("n", "<leader>ci", ":lua vim.lsp.buf.implementation()<CR>")
-- vim.keymap.set("n", "<leader>cs", ":lua vim.lsp.buf.signature_help()<CR>")
-- vim.keymap.set("n", "<leader>ch", ":lua vim.lsp.buf.hover()<CR>")
-- vim.keymap.set("n", "<leader>cf", ":lua vim.lsp.buf.formatting()<CR>")

-- Move Lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Cursor placement
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Copy buffer (void register)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Disable Capital Q for quiting
vim.keymap.set("n", "Q", "<nop>")

-- Switch projects
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Replace on cursor position
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- vim.keymap.set("n", "<Up>", "<Nop>")
-- vim.keymap.set("n", "<Left>", "<Nop>")
-- vim.keymap.set("n", "<Right>", "<Nop>")
-- vim.keymap.set("n", "<Down>", "<Nop>")

