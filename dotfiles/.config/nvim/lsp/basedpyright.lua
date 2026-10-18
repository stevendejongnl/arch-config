--- Resolve the interpreter of the project's virtualenv (.venv, VIRTUAL_ENV, poetry).
---@param root string
---@return string?
local function find_python(root)
  local venv = root .. "/.venv/bin/python"
  if vim.uv.fs_stat(venv) then
    return venv
  end
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  if vim.uv.fs_stat(root .. "/poetry.lock") and vim.fn.executable("poetry") == 1 then
    local out = vim.system({ "poetry", "env", "info", "-e" }, { cwd = root, text = true }):wait()
    local path = vim.trim(out.stdout or "")
    if out.code == 0 and path ~= "" then
      return path
    end
  end
end

--- Docker-based projects put source roots on PYTHONPATH (Makefile: PYTHONPATH=/srv/a:/srv/b).
--- Map each /srv/<dir> to <root>/<dir> so imports resolve locally.
---@param root string
---@return string[]
local function find_extra_paths(root)
  local f = io.open(root .. "/Makefile")
  if not f then
    return {}
  end
  local txt = f:read("*a")
  f:close()
  local paths = {}
  local list = txt:match('PYTHONPATH=([^"\n]+)')
  for entry in (list or ""):gmatch("[^:]+") do
    local dir = root .. "/" .. entry:gsub("^/srv/?", "")
    if vim.uv.fs_stat(dir) then
      paths[#paths + 1] = dir
    end
  end
  return paths
end

return {
  before_init = function(_, config)
    local root = config.root_dir or vim.uv.cwd()
    local python = find_python(root)
    if python then
      config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = python })
    end
    local extra = find_extra_paths(root)
    if #extra > 0 then
      config.settings.basedpyright.analysis.extraPaths = extra
    end
  end,
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff owns import sorting
      analysis = {
        typeCheckingMode = "standard",
        diagnosticMode = "openFilesOnly",
        autoImportCompletions = true,
        diagnosticSeverityOverrides = {
          reportMissingImports = "warning", -- deps often live only in Docker
          reportMissingModuleSource = "none",
        },
      },
    },
  },
}
