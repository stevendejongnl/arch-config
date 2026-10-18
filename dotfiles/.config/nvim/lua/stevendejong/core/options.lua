local o = vim.o

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.colorcolumn = "120"
o.termguicolors = true
o.winborder = "rounded"
o.pumheight = 12
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.confirm = true
o.mouse = "a"
o.showmode = false

o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true

o.wrap = true
o.linebreak = true
o.breakindent = true
o.textwidth = 120

o.ignorecase = true
o.smartcase = true
o.hlsearch = false
o.inccommand = "split"

o.swapfile = false
o.backup = false
o.undofile = true
o.updatetime = 200
o.timeoutlen = 300

o.completeopt = "menu,menuone,noselect,popup"
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevelstart = 99
o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds"

vim.opt.isfname:append("@-@")

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  virtual_text = { spacing = 2, source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
  float = { source = true },
})
