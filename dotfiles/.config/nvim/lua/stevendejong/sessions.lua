--- Agent sessions from the worklog index (`wl sessions`): sessions on this machine and sessions
--- logged on other machines. Enter opens the session directory, <C-r> resumes it in a tmux window.
local M = {}

local COLUMNS = { "session", "when", "host", "area", "repo", "branch", "tickets", "dir", "title", "start" }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "sessions" })
end

---@param line string
---@return table<string, string>
local function parse_row(line)
  local fields = vim.split(line, "\t", { plain = true })
  local row = {}
  for index, name in ipairs(COLUMNS) do
    row[name] = fields[index] or ""
  end
  return row
end

---@param row table<string, string>
local function to_item(row)
  local text = table.concat({ row.when, row.host, row.repo, row.branch, row.tickets, row.title }, " ")
  return vim.tbl_extend("force", row, { text = text, directory = vim.fn.expand(row.dir) })
end

---@return table[]
local function load_items()
  local result = vim.system({ "wl", "sessions" }, { text = true }):wait()
  if result.code ~= 0 then
    notify("wl sessions failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
    return {}
  end
  local lines = vim.split(vim.trim(result.stdout), "\n", { plain = true, trimempty = true })
  return vim.tbl_map(function(line) return to_item(parse_row(line)) end, lines)
end

local function format_item(item)
  return {
    { item.when, "SnacksPickerComment" },
    { "  " },
    { ("%-14.14s"):format(item.host), "SnacksPickerDir" },
    { ("%-18.18s"):format(item.repo) },
    { ("%-10.10s"):format(item.tickets), "SnacksPickerSpecial" },
    { item.title },
  }
end

local function preview_item(ctx)
  local item = ctx.item
  local lines = {}
  for _, name in ipairs(COLUMNS) do
    lines[#lines + 1] = ("%-8s %s"):format(name, item[name])
  end
  ctx.preview:set_lines(lines)
end

local function open_directory(picker, item)
  picker:close()
  if not item or vim.fn.isdirectory(item.directory) == 0 then
    return notify("Directory is not on this machine", vim.log.levels.WARN)
  end
  vim.cmd.tcd(vim.fn.fnameescape(item.directory))
  Snacks.picker.files({ cwd = item.directory })
end

local function resume_session(picker, item)
  picker:close()
  if not item then
    return
  end
  if not vim.env.TMUX then
    return notify("Not inside tmux", vim.log.levels.WARN)
  end
  vim.system({ vim.fn.expand("~/.config/tmux/scripts/session-resume"), item.session }, { text = true })
end

function M.pick()
  Snacks.picker({
    title = "Agent sessions",
    finder = load_items,
    format = format_item,
    preview = preview_item,
    confirm = open_directory,
    actions = { resume_session = resume_session },
    win = { input = { keys = { ["<C-r>"] = { "resume_session", mode = { "n", "i" } } } } },
  })
end

return M
