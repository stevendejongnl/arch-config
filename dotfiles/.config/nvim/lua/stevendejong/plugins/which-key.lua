return {
  "folke/which-key.nvim",
  enabled = true,
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    spec = {
      { "<leader>p", group = "Search/Files" },
      { "<leader>g", group = "Git" },
      { "<leader>gh", group = "Git Hunks" },
      { "<leader>v", group = "LSP" },
      { "<leader>vc", group = "Code Actions" },
      { "<leader>vr", group = "Refactor" },
      { "<leader>c", group = "Code" },
      { "<leader>s", group = "Swap" },
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Cheatsheet floating window
    local cheatsheet_buf = nil

    local function show_cheatsheet()
      -- Toggle: close if already open
      if cheatsheet_buf and vim.api.nvim_buf_is_valid(cheatsheet_buf) then
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
          if vim.api.nvim_win_get_buf(win) == cheatsheet_buf then
            vim.api.nvim_win_close(win, true)
            cheatsheet_buf = nil
            return
          end
        end
      end

      local lines = {
        "                    Keybinding Cheatsheet                    ",
        "",
        "  SEARCH / FILES                    HARPOON                  ",
        "  ──────────────                    ───────                  ",
        "  <leader>pf   Find files (cwd)     <leader>a   Add file    ",
        "  <leader>pg   Live grep (rg)       <C-e>       Toggle menu ",
        "  <leader>ps   Grep string           <C-u>       Slot 1      ",
        "  <leader>pv   File explorer         <C-i>       Slot 2      ",
        "  <C-p>        Git files             <C-o>       Slot 3      ",
        "                                     <C-p>       Slot 4      ",
        "  NAVIGATION                         <C-S-P>     Prev        ",
        "  ──────────                         <C-S-N>     Next        ",
        "  <C-d>        Page down (center)                            ",
        "  <C-u>        Page up (center)    COPILOT (insert mode)     ",
        "  n / N        Search next/prev     ─────────────────────    ",
        "  J            Join lines (center)  <M-l>       Accept       ",
        "                                    <M-]>       Next suggest  ",
        "  GIT (HUNKS)                       <M-[>       Prev suggest  ",
        "  ──────────                        <C-]>       Dismiss       ",
        "  ]h / [h        Next/Prev hunk     <M-CR>      Open panel   ",
        "  <leader>ghs    Stage hunk                                  ",
        "  <leader>ghr    Reset hunk        COMPLETION (insert mode)  ",
        "  <leader>ghS    Stage buffer       ────────────────────     ",
        "  <leader>ghu    Undo stage         <C-n>       Next item    ",
        "  <leader>ghR    Reset buffer       <C-p>       Prev item    ",
        "  <leader>ghp    Preview inline     <C-y>       Confirm      ",
        "  <leader>ghb    Blame line         <C-Space>   Trigger      ",
        "  <leader>ghd    Diff this                                   ",
        "  <leader>ghD    Diff this ~       CODE / FORMAT             ",
        "                                    ────────────             ",
        "  LSP                               <leader>cf  Format       ",
        "  ───                               gc          Comment      ",
        "  gd             Go to definition   <leader>sa  Swap arg →   ",
        "  gD             Go to declaration  <leader>sA  Swap arg ←   ",
        "  gi             Go to impl.                                 ",
        "  gr             References        EDITING                   ",
        "  K              Hover docs         ───────                  ",
        "  <leader>vws    Workspace symbol   J / K (v)   Move lines   ",
        "  <leader>vd     Diagnostics        <leader>p   Paste (void) ",
        "  <leader>vca    Code action        <leader>s   Replace word ",
        "  <leader>vrn    Rename             <leader>x   chmod +x     ",
        "  <leader>vt     Type definition                             ",
        "  [d / ]d        Prev/Next diag.   TEXTOBJECTS               ",
        "  <C-h> (i)      Signature help     ───────────              ",
        "  grn            Rename (native)    af / if     Function      ",
        "  grr            Refs (native)      ac / ic     Class         ",
        "  gra            Action (native)    aa / ia     Argument      ",
        "                                    ]f / [f     Next/Prev fn  ",
        "  MISC                              ]c / [c     Next/Prev cls ",
        "  ────                                                       ",
        "  <leader>i   Line diagnostics    <leader>u   Undotree       ",
        "  <leader>?   This cheatsheet     <C-f>       Tmux session   ",
        "  Q           (disabled)                                     ",
        "",
        "                   Press q or <Esc> to close                  ",
      }

      -- Create buffer
      local buf = vim.api.nvim_create_buf(false, true)
      cheatsheet_buf = buf
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].buftype = "nofile"

      -- Calculate window size
      local width = 66
      local height = #lines
      local ui = vim.api.nvim_list_uis()[1]
      local row = math.floor((ui.height - height) / 2)
      local col = math.floor((ui.width - width) / 2)

      -- Open floating window
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Cheatsheet (<leader>?) ",
        title_pos = "center",
      })

      vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"

      -- Apply highlights
      for i, line in ipairs(lines) do
        local ln = i - 1
        if line:match("^  %u[%u%s/%(%)]+$") or line:match("^  %u[%u%s/%(%)]+%s%s") then
          -- Category headers (lines starting with uppercase words like "SEARCH / FILES")
          if line:match("^%s+%u[%u%s/%(%)]+%s*$") then
            vim.api.nvim_buf_add_highlight(buf, -1, "Title", ln, 0, -1)
          else
            -- Lines with two columns of headers
            local left_end = line:find("%s%s%s%s%s%s%s%s%s%s") or #line
            -- Find second header
            local right_start = line:find("%u[%u%s/%(%)]+", left_end)
            if right_start then
              vim.api.nvim_buf_add_highlight(buf, -1, "Title", ln, 0, left_end)
              vim.api.nvim_buf_add_highlight(buf, -1, "Title", ln, right_start - 1, -1)
            else
              vim.api.nvim_buf_add_highlight(buf, -1, "Title", ln, 0, -1)
            end
          end
        elseif line:match("──") then
          vim.api.nvim_buf_add_highlight(buf, -1, "Comment", ln, 0, -1)
        elseif line:match("Keybinding Cheatsheet") then
          vim.api.nvim_buf_add_highlight(buf, -1, "Title", ln, 0, -1)
        elseif line:match("Press q or") then
          vim.api.nvim_buf_add_highlight(buf, -1, "Comment", ln, 0, -1)
        end
      end

      -- Close keymaps
      local close_keys = { "q", "<Esc>", "<leader>?" }
      for _, key in ipairs(close_keys) do
        vim.keymap.set("n", key, function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
          cheatsheet_buf = nil
        end, { buffer = buf, nowait = true })
      end
    end

    vim.keymap.set("n", "<leader>?", show_cheatsheet, { desc = "Keybinding Cheatsheet" })
  end,
}
