return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = { python = { "flake8", "mypy" } }

    local function has_marker(root, file, pattern)
      local f = io.open(root .. "/" .. file)
      if not f then return false end
      local txt = f:read("*a")
      f:close()
      return pattern == nil or txt:find(pattern) ~= nil
    end

    -- Only run flake8/mypy where the project configures them (ruff LSP covers the rest)
    local function names_for(root)
      local names = {}
      if has_marker(root, ".flake8") or has_marker(root, "setup.cfg", "%[flake8%]") or has_marker(root, "tox.ini", "%[flake8%]") then
        names[#names + 1] = "flake8"
      end
      if has_marker(root, "mypy.ini") or has_marker(root, "pyproject.toml", "%[tool%.mypy%]") or has_marker(root, "setup.cfg", "%[mypy%]") then
        names[#names + 1] = "mypy"
      end
      return names
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("stevendejong_lint", { clear = true }),
      callback = function(ev)
        if vim.bo[ev.buf].filetype ~= "python" then return end
        local root = vim.fs.root(ev.buf, { ".flake8", "mypy.ini", "setup.cfg", "tox.ini", "pyproject.toml", ".git" })
        if root then
          local venv_bin = root .. "/.venv/bin"
          if vim.uv.fs_stat(venv_bin) then
            lint.linters.mypy.cmd = vim.uv.fs_stat(venv_bin .. "/mypy") and venv_bin .. "/mypy" or "mypy"
            lint.linters.flake8.cmd = vim.uv.fs_stat(venv_bin .. "/flake8") and venv_bin .. "/flake8" or "flake8"
          end
          lint.try_lint(names_for(root))
        end
      end,
    })
  end,
}
