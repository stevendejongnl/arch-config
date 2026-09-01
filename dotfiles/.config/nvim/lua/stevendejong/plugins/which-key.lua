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
      { "<leader>j", group = "Jump" },
      { "<leader>h", group = "Harpoon" },
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
        "  <leader>pf   Find files (cwd)     <leader>ha  Add file    ",
        "  <leader>pg   Live grep (rg)       <C-e>       Toggle menu ",
        "  <leader>ps   Grep string           <C-u>       Slot 1      ",
        "  <leader>pv   File explorer         <C-i>       Slot 2      ",
        "                                     <C-o>       Slot 3      ",
        "  NAVIGATION                         <C-p>       Slot 4      ",
        "  ──────────                         <C-S-P>     Prev        ",
        "  <leader>jb   Go back               <C-S-N>     Next        ",
        "  <leader>jf   Go forward                                    ",
        "  <C-d>        Page down (center)                               ",
        "  <C-u>        Page up (center)                               ",
        "  n / N        Search next/prev                               ",
        "  J            Join lines (center)                            ",
        "                                                               ",
        "  GIT (HUNKS)                                                 ",
        "  ──────────                                                  ",
        "  ]h / [h        Next/Prev hunk                              ",
        "  <leader>ghs    Stage hunk        COMPLETION (insert mode)  ",
        "  <leader>ghr    Reset hunk         ────────────────────     ",
        "  <leader>ghS    Stage buffer       <C-n>       Next item    ",
        "  <leader>ghu    Undo stage         <C-p>       Prev item    ",
        "  <leader>ghR    Reset buffer       <C-y>       Confirm      ",
        "  <leader>ghp    Preview inline     <C-Space>   Trigger      ",
        "  <leader>ghb    Blame line                                  ",
        "  <leader>ghd    Diff this         CODE / FORMAT             ",
        "  <leader>ghD    Diff this ~        ────────────             ",
        "  ih             Select hunk        <leader>cf  Format       ",
        "                                    <leader>cs  Carbon (v)   ",
        "  LSP                               gc          Comment      ",
        "  ───                               <leader>sa  Swap arg →   ",
        "  gd             Go to definition   <leader>sA  Swap arg ←   ",
        "  gD             Go to declaration                           ",
        "  gi             Go to impl.       EDITING                   ",
        "  gr             References         ───────                  ",
        "  K              Hover docs         J / K (v)   Move lines   ",
        "  <leader>vws    Workspace symbol   <leader>p   Paste (void) ",
        "  <leader>vd     Diagnostics        <leader>s   Replace word ",
        "  <leader>vca    Code action        <leader>x   chmod +x     ",
        "  <leader>vrn    Rename                                      ",
        "  <leader>vt     Type definition   TEXTOBJECTS               ",
        "  [d / ]d        Prev/Next diag.    ───────────              ",
        "  <C-h> (i)      Signature help     af / if     Function      ",
        "  grn            Rename (native)    ac / ic     Class         ",
        "  grr            Refs (native)      aa / ia     Argument      ",
        "  gra            Action (native)    ]f / [f     Next/Prev fn  ",
        "                                    ]c / [c     Next/Prev cls ",
        "  AI / AVANTE                       ]F / [F     Fn end        ",
        "  ───────────                       ]C / [C     Class end     ",
        "  :AvanteChat   Open Avante chat    ]a / [a     Next/Prev arg ",
        "  :AvanteAsk    Ask Avante                                   ",
        "",
        "  MISC                                                       ",
        "  ────                                                       ",
        "  <leader>i   Line diagnostics    <leader>u   Undotree       ",
        "  <leader>?   This cheatsheet     <C-f>       Tmux session   ",
        "  <C-q>       Dashboard           Q           (disabled)     ",
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
