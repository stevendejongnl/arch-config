local group = vim.api.nvim_create_augroup("stevendejong", { clear = true })
local function au(event, opts)
  opts.group = group
  vim.api.nvim_create_autocmd(event, opts)
end

au("TextYankPost", { callback = function() vim.hl.on_yank() end })

-- Restore cursor position (replaces vim-lastplace)
au("BufReadPost", {
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].buftype == "" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Transparent background must be re-applied after every colorscheme load
au("ColorScheme", {
  callback = function()
    for _, hl in ipairs({ "Normal", "NormalFloat", "SignColumn" }) do
      vim.api.nvim_set_hl(0, hl, { bg = "none" })
    end
  end,
})

-- Reload buffers changed on disk (git checkout, formatters)
au({ "FocusGained", "TermClose", "TermLeave" }, { command = "checktime" })

-- Per-filetype indent: 4 spaces for Python/Rust/Lua-like, 2 elsewhere (default)
au("FileType", {
  pattern = { "python", "rust", "swift" },
  callback = function()
    vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = 4, 4, 4
  end,
})
