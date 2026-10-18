local map = vim.keymap.set

-- Move lines up and down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Line(s) Down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Line(s) Up" })

-- Cursor placement
map("n", "J", "mzJ`z", { desc = "Join Lines (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Page Down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Page Up (centered)" })
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Paste over selection without clobbering the register
map("x", "<leader>p", [["_dP]], { desc = "Paste (void register)" })

-- Disable Ex mode
map("n", "Q", "<nop>")

-- Switch projects
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Tmux sessionizer" })

-- Replace word under cursor in buffer
map("n", "<leader>cs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word (buffer)" })

-- Make file executable
map("n", "<leader>cx", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make File Executable" })

-- Jumplist (<C-o>/<C-i> stay native)
map("n", "<leader>jb", "<C-o>", { desc = "Go Back" })
map("n", "<leader>jf", "<C-i>", { desc = "Go Forward" })

-- Diagnostics
map("n", "<leader>i", function() vim.diagnostic.open_float({ scope = "line" }) end, { desc = "Line Diagnostics" })

-- Buffers
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next Buffer" })

-- Clear search highlight / escape terminal
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
