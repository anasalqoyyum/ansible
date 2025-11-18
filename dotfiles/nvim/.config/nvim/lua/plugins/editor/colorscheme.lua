return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },

  -- add and setup onedark theme
  {
    "olimorris/onedarkpro.nvim",
    lazy = true,
    enabled = false,
    opts = {
      highlights = {
        DiagnosticUnderlineError = { undercurl = true },
        DiagnosticUnderlineWarn = { undercurl = true },
        DiagnosticUnderlineInfo = { undercurl = true },
        DiagnosticUnderlineHint = { undercurl = true },
      },
      options = {
        transparency = vim.g.theme_transparency,
      },
    },
  },

  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    enabled = false,
    opts = {},
  },

  {
    "sainnhe/gruvbox-material",
    lazy = true,
    enabled = false,
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_transparent_background = false
      vim.g.gruvbox_material_enable_bold = true
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_float_style = "dim"
    end,
    opts = {},
  },

  {
    "catppuccin/nvim",
    lazy = true,
    enabled = false,
  },

  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = vim.g.theme_transparency,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      plugins = {
        rainbow = true, -- for blink.pairs
      },
      on_colors = function(c)
        -- blue borders instead of teal
        c.border_highlight = c.blue

        -- brighten up the git colors, used for gitsigns (column and lualine)
        c.git.add = c.teal
        c.git.change = c.blue
        c.git.delete = c.red1

        -- Brighten changes within a line
        c.diff.text = "#204b23"
        -- Make changed lines more green instead of blue
        c.diff.add = "#182f23"
        -- Make deletes more saturated
        c.diff.delete = "#4d1919"
        -- Darken the statusline a bit
        c.bg_statusline = "#080A11"
      end,
      on_highlights = function(hl, c)
        -- slightly brighter visual selection
        -- hl.Visual.bg = "#2d3f6f"
        -- similar to VSCode Tokyo Night Dark
        -- hl.Visual.bg = "#2a2f41"
        -- Use a darker visual to contrast with the lighter cursor line
        hl.Visual.bg = "#121621"

        -- Use bg.dark from storm (not night) for the cursor line background to make it more subtle
        -- hl.CursorLine = { bg = "#1f2335" }
        -- Use dimmer for transparent background
        hl.CursorLine = { bg = "#10131D" }

        -- Keep visual for popup/picker highlights
        hl.PmenuSel = { bg = hl.Visual.bg }
        hl.SnacksPickerCursorLine = { bg = hl.Visual.bg }
        hl.SnacksPickerListCursorLine = hl.SnacksPickerCursorLine
        hl.SnacksPickerPreviewCursorLine = hl.SnacksPickerCursorLine

        -- Make TS context dimmer and color line numbers
        hl.TreesitterContext = { bg = "#1e202e" }
        hl.TreesitterContextLineNumber = { fg = c.fg_gutter, bg = "#1e202e" }

        -- Super Subtle snacks indent colors
        hl.SnacksIndent = { fg = "#1f2233" }
        hl.SnacksIndentScope = { fg = "#2e3248" }

        hl.BlinkIndent = { fg = "#1f2233" }
        hl.BlinkIndentScope = { fg = "#2e3248" }

        -- brighter blue for search, washes out txt less
        hl.Search.bg = "#2c52b3"

        -- Less nuclear flash
        if hl.FlashLabel then
          hl.FlashLabel.bg = "#c2357a"
        end

        -- Snacks
        -- Make bufnr gray instead of orange
        hl.SnacksPickerBufNr = hl.NonText
        -- Highlight matches in orange instead of cyan
        hl.SnacksPickerMatch = { fg = hl.IncSearch.bg }

        -- Blinks
        -- Highlight matches in orange instead of cyan
        hl.BlinkCmpLabelMatch = { fg = hl.IncSearch.bg }

        -- Make folds less prominent (especially important for DiffView)
        hl.Folded = { fg = c.fg, italic = true }

        -- clean up gitsigns inline diff colors
        hl.GitSignsChangeInLine = { fg = c.git.change, reverse = true }
        hl.GitSignsAddInLine = { fg = c.git.add, reverse = true }
        hl.GitSignsDeleteInLine = { fg = c.git.delete, reverse = true }

        -- Make diff* transparent for DiffView file panel
        hl.diffAdded = { fg = c.git.add }
        hl.diffRemoved = { fg = c.git.delete }
        hl.diffChanged = { fg = c.git.change }

        -- Make diffview deleted areas dimmer
        hl.DiffviewDiffDeleteDim = { fg = c.fg_gutter }

        -- Make lsp cursor word highlights dimmer
        hl.LspReferenceWrite = { bg = c.bg_highlight }
        hl.LspReferenceText = { bg = c.bg_highlight }
        hl.LspReferenceRead = { bg = c.bg_highlight }
      end,
    },
  },

  {
    "vague2k/vague.nvim",
    lazy = true,
    enabled = false,
    opts = {
      transparent = vim.g.theme_transparency, -- enable transparency
      italic = false,
      on_highlights = function(hl, c)
        hl.SnacksIndentScope = { fg = c.string }
      end,
    },
  },

  {
    "rose-pine/neovim",
    lazy = true,
    enabled = false,
    name = "rose-pine",
    opts = {
      styles = {
        bold = true,
        italic = false,
        transparency = vim.g.theme_transparency,
      },
    },
  },
}
