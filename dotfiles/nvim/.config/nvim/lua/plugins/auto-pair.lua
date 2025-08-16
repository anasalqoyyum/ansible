return {
  {
    "echasnovski/mini.pairs",
    enabled = false,
  },

  {
    "saghen/blink.pairs",
    event = "VeryLazy",
    -- prefer build from source
    -- dependencies = "saghen/blink.download",
    build = "cargo build --release",

    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        enabled = true,
        cmdline = false,
        disabled_filetypes = {},
        pairs = {},
      },
      highlights = {
        enabled = true,
        cmdline = false,
        groups = {
          "BlinkPairsOrange",
          "BlinkPairsPurple",
          "BlinkPairsBlue",
        },
        unmatched_group = "BlinkPairsUnmatched",
        -- highlights matching pairs under the cursor
        matchparen = {
          enabled = true,
          -- known issue where typing won't update matchparen highlight, disabled by default
          cmdline = false,
          group = "BlinkPairsMatchParen",
        },
      },
      debug = false,
    },
  },
}
