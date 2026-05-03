return {
  {
    "saghen/blink.pairs",
    enabled = vim.g.auto_pairs == "blink",
    event = "VeryLazy",
    -- prefer build from source
    -- dependencies = "saghen/blink.download",
    build = "cargo build --release",

    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        enabled = true,
        cmdline = true,
        disabled_filetypes = {},
        pairs = {},
        wrap = {
          -- move closing pair via motion
          ["<C-b>"] = "motion",
          -- move opening pair via motion
          ["<C-S-b>"] = "motion_reverse",
        },
      },
      highlights = {
        enabled = true,
        -- requires require('vim._extui').enable({}), otherwise has no effect
        cmdline = true,
        -- groups = {
        --   "BlinkPairsOrange",
        --   "BlinkPairsPurple",
        --   "BlinkPairsBlue",
        -- },
        groups = {
          "RainbowDelimiterRed",
          -- "RainbowDelimiterOrange",
          "RainbowDelimiterYellow",
          -- "RainbowDelimiterGreen",
          "RainbowDelimiterBlue",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
        unmatched_group = "BlinkPairsUnmatched",
        -- highlights matching pairs under the cursor
        matchparen = {
          enabled = true,
          -- known issue where typing won't update matchparen highlight, disabled by default
          cmdline = false,
          -- also include pairs not on top of the cursor, but surrounding the cursor
          include_surrounding = true,
          group = "BlinkPairsMatchParen",
          priority = 250,
        },
      },
      debug = false,
    },
  },
}
