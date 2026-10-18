--- Run tests / debug targets in a tmux pane for Docker-based projects (nox + compose),
--- fall back to neotest everywhere else.
local M = {}

local last ---@type { root: string, cmd: string }?

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "runner" })
end

local function tmux(args)
  return vim.system(vim.list_extend({ "tmux" }, args), { text = true }):wait()
end

---@param root string
---@return string pane id of the (re)used runner pane
local function runner_pane(root)
  local own = vim.env.TMUX_PANE
  local id = vim.trim(tmux({ "show-options", "-wqv", "-t", own, "@runner" }).stdout or "")
  if id ~= "" and tmux({ "display-message", "-p", "-t", id, "#{pane_id}" }).code == 0 then
    return id
  end
  id = vim.trim(tmux({ "split-window", "-d", "-v", "-t", own, "-l", "35%", "-c", root, "-P", "-F", "#{pane_id}" }).stdout or "")
  tmux({ "set-option", "-w", "-t", own, "@runner", id })
  return id
end

---@param root string
---@param cmd string
function M.send(root, cmd)
  if not (vim.env.TMUX and vim.env.TMUX_PANE) then
    return notify("Not inside tmux", vim.log.levels.WARN)
  end
  local pane = runner_pane(root)
  last = { root = root, cmd = cmd }
  tmux({ "send-keys", "-t", pane, "-l", "clear; cd " .. vim.fn.shellescape(root) .. " && " .. cmd })
  tmux({ "send-keys", "-t", pane, "Enter" })
end

-- nox sessions that run inside Docker: dir -> { session, style }
-- style "unittest": dotted module path relative to <dir>; "nose": path relative to <dir>
local sessions = {
  webshop = { "webshop", "unittest" },
  interfacing = { "interfacing", "unittest" },
  trytond = { "trytond", "nose" },
  lib = { "lib", "nose" },
  eventhandler = { "eventhandler", "nose" },
}

local function nox_root(buf)
  local root = vim.fs.root(buf, { "noxfile.py" })
  if not root then return end
  local f = io.open(root .. "/noxfile.py")
  local txt = f and f:read("*a") or ""
  if f then f:close() end
  return txt:find("_run_docker_test", 1, true) and root or nil
end

--- Innermost test class and outermost function around the cursor (python, treesitter).
local function python_scope()
  local node = vim.treesitter.get_node()
  local fn, cls
  while node do
    local t = node:type()
    if t == "function_definition" then
      fn = vim.treesitter.get_node_text(node:field("name")[1], 0)
    elseif t == "class_definition" and not cls then
      cls = vim.treesitter.get_node_text(node:field("name")[1], 0)
    end
    node = node:parent()
  end
  return cls, fn
end

---@param scope "nearest"|"file"|"all"
---@return { root: string, cmd: string }?
local function nox_command(scope)
  local buf = vim.api.nvim_get_current_buf()
  local root = nox_root(buf)
  if not root or vim.bo[buf].filetype ~= "python" then return end
  local rel = vim.fs.relpath(root, vim.api.nvim_buf_get_name(buf))
  local dir, inner
  if rel then
    dir, inner = rel:match("^([^/]+)/(.+)$")
  end
  local spec = dir and sessions[dir]
  if not spec then return end

  local args = ""
  if scope ~= "all" then
    local cls, fn = python_scope()
    if spec[2] == "unittest" then
      args = inner:gsub("%.py$", ""):gsub("/", ".")
      if scope == "nearest" and cls and fn then args = args .. "." .. cls .. "." .. fn end
    else
      args = inner
      if scope == "nearest" and fn then args = args .. ":" .. (cls and (cls .. ".") or "") .. fn end
    end
    args = " -- " .. vim.fn.shellescape(args)
  end
  return { root = root, cmd = "nox -s " .. spec[1] .. args }
end

local function run(scope, neotest_fn)
  local c = nox_command(scope)
  if c then
    M.send(c.root, c.cmd)
  else
    neotest_fn(require("neotest"))
  end
end

function M.nearest() run("nearest", function(n) n.run.run() end) end
function M.file() run("file", function(n) n.run.run(vim.fn.expand("%")) end) end
function M.all() run("all", function(n) n.run.run(vim.fn.getcwd()) end) end
function M.last()
  if last then
    M.send(last.root, last.cmd)
  else
    require("neotest").run.run_last()
  end
end

-- Docker debugging -----------------------------------------------------------

---@return string?
local function compose_root(buf)
  return vim.fs.root(buf or 0, { "docker-compose.yml", "compose.yml", ".git" })
end

--- Map `./dir:/srv/dir` volumes from docker-compose.yml to debugpy path mappings.
function M.path_mappings()
  local root = compose_root()
  local maps, seen = {}, {}
  local f = root and io.open(root .. "/docker-compose.yml")
  if not f then
    return { { localRoot = vim.fn.getcwd(), remoteRoot = "/srv" } }
  end
  for line in f:lines() do
    local l, r = line:match('^%s*%-%s*"?%./([^:"]+):(/srv[^:"]*)')
    if l then
      l, r = l:gsub("/$", ""), r:gsub("/$", "")
      local abs = root .. "/" .. l
      if not seen[abs] and vim.uv.fs_stat(abs) and vim.fn.isdirectory(abs) == 1 then
        seen[abs] = true
        maps[#maps + 1] = { localRoot = abs, remoteRoot = r }
      end
    end
  end
  f:close()
  return maps
end

local function wait_for_port(port, timeout_ms, cb)
  local started = vim.uv.now()
  local timer = assert(vim.uv.new_timer())
  timer:start(500, 1000, vim.schedule_wrap(function()
    local tcp = assert(vim.uv.new_tcp())
    tcp:connect("127.0.0.1", port, function(err)
      tcp:close()
      vim.schedule(function()
        if not err then
          timer:stop(); timer:close()
          cb(true)
        elseif vim.uv.now() - started > timeout_ms then
          timer:stop(); timer:close()
          cb(false)
        end
      end)
    end)
  end))
end

--- Start the webshop container with debugpy listening and attach nvim-dap once it is up.
function M.debug_docker()
  local root = compose_root()
  if not (root and vim.uv.fs_stat(root .. "/dockers/webshop/entrypoint.sh")) then
    return notify("No debuggable compose service here; use <leader>dc and pick the attach config")
  end
  M.send(root, "docker compose stop webshop; docker compose run --rm --use-aliases -p 127.0.0.1:5678:5678 webshop --debug true")
  notify("Starting webshop with debugpy on :5678 ...")
  wait_for_port(5678, 180000, function(ok)
    if not ok then return notify("debugpy did not come up within 3 minutes", vim.log.levels.ERROR) end
    require("dap").run({
      type = "python", request = "attach", name = "webshop (docker)",
      connect = { host = "127.0.0.1", port = 5678 },
      pathMappings = M.path_mappings(),
    })
  end)
end

return M
