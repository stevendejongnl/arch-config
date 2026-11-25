-- Flat: light ink on near-black, colour only for syntax and status. Same palette as the terminal.
local c = {
  bg = "#1c1d1f", bar = "#17181a", line = "#2b2d31", sel = "#34363a", border = "#3d3f44",
  ink = "#ecebe6", sec = "#a8a9ad", dim = "#8b8c91",
  red = "#f08f87", green = "#9be3b4", yellow = "#f2c46d", blue = "#8fb4f2", purple = "#c3a6e8", cyan = "#8cc9d6",
}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
do
  vim.g.colors_name = "flat"
  vim.o.termguicolors = true
  vim.o.background = "dark"

  local groups = {
    Normal = { fg = c.ink, bg = c.bg }, NormalNC = { fg = c.ink, bg = c.bg }, NormalFloat = { fg = c.ink, bg = c.bg },
    FloatBorder = { fg = c.border, bg = c.bg }, FloatTitle = { fg = c.ink, bold = true },
    Cursor = { fg = c.bg, bg = c.ink }, CursorLine = { bg = c.sel }, CursorColumn = { bg = c.sel },
    ColorColumn = { bg = c.line }, CursorLineNr = { fg = c.ink, bold = true }, LineNr = { fg = c.dim },
    SignColumn = { fg = c.dim, bg = c.bg }, FoldColumn = { fg = c.dim }, Folded = { fg = c.sec, bg = c.line },
    VertSplit = { fg = c.sel }, WinSeparator = { fg = c.sel }, EndOfBuffer = { fg = c.red },
    Visual = { bg = c.sel }, VisualNOS = { bg = c.sel }, Search = { fg = c.bg, bg = c.yellow },
    IncSearch = { fg = c.bg, bg = c.ink }, CurSearch = { fg = c.bg, bg = c.ink }, MatchParen = { fg = c.ink, bg = c.border, bold = true },
    Pmenu = { fg = c.ink, bg = c.bg }, PmenuSel = { fg = c.bg, bg = c.ink }, PmenuSbar = { bg = c.line }, PmenuThumb = { bg = c.border },
    StatusLine = { fg = c.sec, bg = c.bar }, StatusLineNC = { fg = c.dim, bg = c.bar },
    TabLine = { fg = c.dim, bg = c.bar }, TabLineSel = { fg = c.ink, bg = c.bg, bold = true }, TabLineFill = { bg = c.bar },
    WinBar = { fg = c.sec, bg = c.bg }, WinBarNC = { fg = c.dim, bg = c.bg },
    Title = { fg = c.ink, bold = true }, Directory = { fg = c.blue }, Question = { fg = c.green }, MoreMsg = { fg = c.green },
    WarningMsg = { fg = c.yellow }, ErrorMsg = { fg = c.red }, ModeMsg = { fg = c.ink, bold = true }, NonText = { fg = c.border },
    SpecialKey = { fg = c.border }, Whitespace = { fg = c.line }, Conceal = { fg = c.dim },

    Comment = { fg = c.dim, italic = true }, Constant = { fg = c.yellow }, String = { fg = c.green }, Character = { fg = c.green },
    Number = { fg = c.yellow }, Boolean = { fg = c.yellow }, Float = { fg = c.yellow },
    Identifier = { fg = c.ink }, Function = { fg = c.blue }, Statement = { fg = c.purple }, Conditional = { fg = c.purple },
    Repeat = { fg = c.purple }, Label = { fg = c.purple }, Operator = { fg = c.sec }, Keyword = { fg = c.purple },
    Exception = { fg = c.purple }, PreProc = { fg = c.purple }, Include = { fg = c.purple }, Define = { fg = c.purple },
    Macro = { fg = c.purple }, Type = { fg = c.cyan }, StorageClass = { fg = c.purple }, Structure = { fg = c.cyan },
    Typedef = { fg = c.cyan }, Special = { fg = c.cyan }, SpecialChar = { fg = c.cyan }, Delimiter = { fg = c.sec },
    Tag = { fg = c.blue }, Debug = { fg = c.red }, Underlined = { fg = c.blue, underline = true },
    Error = { fg = c.red }, Todo = { fg = c.bg, bg = c.yellow, bold = true },

    DiffAdd = { bg = "#243329" }, DiffChange = { bg = "#38301f" }, DiffDelete = { fg = c.red, bg = "#3a2625" }, DiffText = { bg = "#4a3f23" },
    Added = { fg = c.green }, Changed = { fg = c.yellow }, Removed = { fg = c.red },
    DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.yellow }, DiagnosticInfo = { fg = c.blue }, DiagnosticHint = { fg = c.cyan },
    DiagnosticOk = { fg = c.green },
    DiagnosticUnderlineError = { undercurl = true, sp = c.red }, DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue }, DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },
    SpellBad = { undercurl = true, sp = c.red }, SpellCap = { undercurl = true, sp = c.yellow },

    ["@variable"] = { fg = c.ink }, ["@variable.builtin"] = { fg = c.red }, ["@variable.parameter"] = { fg = c.ink },
    ["@variable.member"] = { fg = c.ink }, ["@property"] = { fg = c.ink }, ["@field"] = { fg = c.ink },
    ["@constant"] = { fg = c.yellow }, ["@constant.builtin"] = { fg = c.yellow }, ["@module"] = { fg = c.cyan },
    ["@string"] = { fg = c.green }, ["@string.escape"] = { fg = c.cyan }, ["@string.regexp"] = { fg = c.cyan },
    ["@function"] = { fg = c.blue }, ["@function.call"] = { fg = c.blue }, ["@function.method"] = { fg = c.blue },
    ["@function.builtin"] = { fg = c.blue }, ["@constructor"] = { fg = c.cyan }, ["@type"] = { fg = c.cyan },
    ["@type.builtin"] = { fg = c.cyan }, ["@keyword"] = { fg = c.purple }, ["@keyword.function"] = { fg = c.purple },
    ["@keyword.return"] = { fg = c.purple }, ["@keyword.operator"] = { fg = c.purple }, ["@operator"] = { fg = c.sec },
    ["@punctuation"] = { fg = c.sec }, ["@punctuation.bracket"] = { fg = c.sec }, ["@comment"] = { fg = c.dim, italic = true },
    ["@tag"] = { fg = c.blue }, ["@tag.attribute"] = { fg = c.cyan }, ["@tag.delimiter"] = { fg = c.sec },
    ["@markup.heading"] = { fg = c.ink, bold = true }, ["@markup.link"] = { fg = c.blue, underline = true },
    ["@markup.raw"] = { fg = c.green }, ["@markup.strong"] = { bold = true }, ["@markup.italic"] = { italic = true },
    ["@lsp.type.parameter"] = { fg = c.ink }, ["@lsp.type.property"] = { fg = c.ink },

    GitSignsAdd = { fg = c.green }, GitSignsChange = { fg = c.yellow }, GitSignsDelete = { fg = c.red },
    IndentBlanklineChar = { fg = c.line }, IblIndent = { fg = c.line }, IblScope = { fg = c.border },
    TelescopeBorder = { fg = c.border }, TelescopeSelection = { bg = c.sel }, TelescopeMatching = { fg = c.yellow, bold = true },
    NvimTreeNormal = { fg = c.sec, bg = c.bar }, NeoTreeNormal = { fg = c.sec, bg = c.bar }, NeoTreeNormalNC = { fg = c.sec, bg = c.bar },
  }
  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end

  vim.g.terminal_color_0, vim.g.terminal_color_8 = c.bg, c.border
  vim.g.terminal_color_1, vim.g.terminal_color_9 = c.red, "#f6aaa4"
  vim.g.terminal_color_2, vim.g.terminal_color_10 = c.green, "#b4ebc8"
  vim.g.terminal_color_3, vim.g.terminal_color_11 = c.yellow, "#f7d58f"
  vim.g.terminal_color_4, vim.g.terminal_color_12 = c.blue, "#adc8f6"
  vim.g.terminal_color_5, vim.g.terminal_color_13 = c.purple, "#d4bff0"
  vim.g.terminal_color_6, vim.g.terminal_color_14 = c.cyan, "#a8dbe6"
  vim.g.terminal_color_7, vim.g.terminal_color_15 = c.sec, c.ink
end

