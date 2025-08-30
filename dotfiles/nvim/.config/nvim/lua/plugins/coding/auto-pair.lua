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
        cmdline = true,
        disabled_filetypes = {},
        pairs = {
          ["'"] = {
            {
              "'''",
              when = function(ctx)
                return ctx:text_before_cursor(2) == "''"
              end,
              languages = { "python" },
            },
            -- I always need this, so overwrite the default
            -- https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua#L41-L53
            {
              "'",
              enter = false,
              space = false,
            },
          },
        },
      },
      highlights = {
        enabled = true,
        -- requires require('vim._extui').enable({}), otherwise has no effect
        cmdline = true,
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
