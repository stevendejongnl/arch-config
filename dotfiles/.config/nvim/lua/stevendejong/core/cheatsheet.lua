local sections = {
  { "SEARCH / FILES", {
    { "<leader>pf", "Find files" }, { "<C-p>", "Git files" }, { "<leader>pg", "Live grep" },
    { "<leader>ps", "Grep word/selection" }, { "<leader>pb", "Buffers" }, { "<leader>pr", "Recent files" },
    { "<leader>pp", "Projects" }, { "<leader>pd", "Diagnostics" }, { "<leader>pS", "Workspace symbols" },
    { "<leader>pu", "Undo history" }, { "<leader>pk", "Keymaps" }, { "<leader>/", "Search buffer lines" },
    { "<leader>e", "File tree" }, { "- / <leader>pv", "Oil (dir as buffer)" }, { "<leader>o", "Outline" },
  } },
  { "NAVIGATION", {
    { "<leader>jb / jf", "Jump back / forward" }, { "]] / [[", "Next/prev reference" },
    { "<leader>1..4", "Harpoon slot" }, { "<C-e>", "Harpoon menu" }, { "<leader>ha", "Harpoon add" },
    { "<S-h> / <S-l>", "Prev/next buffer" }, { "<C-f>", "Tmux sessionizer" }, { "<C-q>", "Dashboard" },
    { "<C-/>", "Terminal" }, { "<leader>.", "Scratch buffer" },
  } },
  { "LSP", {
    { "gd / gD", "Definition / decl." }, { "gr", "References" }, { "gi", "Implementations" },
    { "grt", "Type definition" }, { "gO", "Document symbols" }, { "K", "Hover" },
    { "grn / <leader>vrn", "Rename" }, { "gra / <leader>vca", "Code action" }, { "<leader>vo", "Organize imports" },
    { "<leader>vws", "Workspace symbol" }, { "<C-h> (i)", "Signature help" }, { "[d / ]d", "Prev/next diagnostic" },
    { "<leader>i / vd", "Line diagnostics" }, { "<leader>uh", "Toggle inlay hints" },
    { "<leader>vi / vI", "Incoming / outgoing calls" },
  } },
  { "CODE / FORMAT", {
    { "<leader>cf", "Format" }, { "<leader>uf", "Toggle format on save" }, { "<leader>cv", "Select Python venv" },
    { "<leader>cs", "Replace word (buffer)" }, { "<leader>sr", "Search/replace project" },
    { "<leader>sf", "Replace in file" }, { "<leader>cx", "chmod +x" }, { "gc", "Comment" },
  } },
  { "TEXTOBJECTS", {
    { "af / if", "Function" }, { "ac / ic", "Class" }, { "aa / ia", "Argument" },
    { "]f [f ]F [F", "Function nav" }, { "]c [c ]C [C", "Class nav" },
    { "]a / [a", "Argument next/prev" }, { "<leader>sa / sA", "Swap argument" },
  } },
  { "REFACTOR", {
    { "<leader>re (x)", "Extract function" }, { "<leader>rf (x)", "Extract to file" },
    { "<leader>rv (x)", "Extract variable" }, { "<leader>ri", "Inline variable" },
    { "<leader>rI", "Inline function" }, { "<leader>rb", "Extract block" }, { "<leader>rm", "Rename/move file" },
  } },
  { "DEBUG", {
    { "<leader>db", "Breakpoint" }, { "<leader>dB", "Conditional breakpoint" }, { "<leader>dc", "Continue / start" },
    { "<leader>di / do / dO", "Step into / over / out" }, { "<leader>dl", "Run last" }, { "<leader>dt", "Terminate" },
    { "<leader>du", "Debug view" }, { "<leader>dr", "REPL" }, { "<leader>de", "Eval under cursor" },
    { "<leader>dD", "Docker: start + attach" },
  } },
  { "TEST", {
    { "<leader>tt", "Nearest (nox in tmux / neotest)" }, { "<leader>tf", "File" }, { "<leader>ta", "All" },
    { "<leader>tl", "Run last" }, { "<leader>td", "Debug nearest" }, { "<leader>ts", "Summary" },
    { "<leader>to / tO", "Output / panel" }, { "<leader>tx", "Stop" },
  } },
  { "GIT", {
    { "<leader>gg", "Neogit" }, { "<leader>gl", "Lazygit" }, { "<leader>gd", "Diffview" },
    { "<leader>gf / gH", "File / repo history" }, { "<leader>gL / gb", "Log / branches" },
    { "]h / [h", "Next/prev hunk" }, { "<leader>ghs / ghr", "Stage / reset hunk" },
    { "<leader>ghS / ghR", "Stage / reset buffer" }, { "<leader>ghp", "Preview hunk" },
    { "<leader>ghb", "Blame line" }, { "<leader>ghd / ghD", "Diff this / ~" }, { "ih", "Select hunk" },
  } },
  { "DIAGNOSTICS / MISC", {
    { "<leader>xx / xX", "Trouble project / buffer" }, { "<leader>xr", "Trouble references" },
    { "<leader>xq", "Trouble quickfix" }, { "<leader>uu", "Undotree" }, { "<leader>ut", "Sticky context" },
    { "<leader>qs / ql", "Restore session / last" }, { "<leader>bd", "Delete buffer" },
    { "J / K (v)", "Move lines" }, { "<leader>p (x)", "Paste, keep register" }, { "<leader>?", "This cheatsheet" },
  } },
}

local function render()
  local ncols, col_w, key_w = 3, 46, 20
  local blocks = {}
  for _, s in ipairs(sections) do
    local block = { { s[1], "Title" }, { string.rep("─", #s[1]), "Comment" } }
    for _, k in ipairs(s[2]) do
      block[#block + 1] = { string.format("%-" .. key_w .. "s %s", k[1], k[2]) }
    end
    block[#block + 1] = { "" }
    blocks[#blocks + 1] = block
  end

  -- greedy: put each block in the shortest column
  local cols, heights = {}, {}
  for c = 1, ncols do cols[c], heights[c] = {}, 0 end
  for _, b in ipairs(blocks) do
    local best = 1
    for c = 2, ncols do if heights[c] < heights[best] then best = c end end
    vim.list_extend(cols[best], b)
    heights[best] = heights[best] + #b
  end

  local rows = math.max(unpack(heights))
  local lines, marks = {}, {}
  for i = 1, rows do
    local line = " "
    for c = 1, ncols do
      local cell = cols[c][i] or { "" }
      if cell[2] then marks[#marks + 1] = { i - 1, #line, #line + #cell[1], cell[2] } end
      line = line .. cell[1] .. string.rep(" ", col_w - vim.fn.strdisplaywidth(cell[1]))
    end
    lines[i] = line
  end
  return lines, marks, col_w * ncols + 2
end

local M = {}
local win

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
    return
  end
  local lines, marks, width = render()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("cheatsheet")
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  width = math.min(width, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
    style = "minimal", border = "rounded", title = " Cheatsheet ", title_pos = "center",
  })
  for _, key in ipairs({ "q", "<Esc>", "<leader>?" }) do
    vim.keymap.set("n", key, M.toggle, { buffer = buf, nowait = true })
  end
end

return M
