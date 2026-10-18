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

return {
  before_init = function(_, config)
    local python = find_python(config.root_dir or vim.uv.cwd())
    if python then
      config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = python })
    end
  end,
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff owns import sorting
      analysis = {
        typeCheckingMode = "standard",
        diagnosticMode = "openFilesOnly",
        autoImportCompletions = true,
      },
    },
  },
}
