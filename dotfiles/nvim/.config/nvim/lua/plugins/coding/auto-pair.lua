return {
  {
    "nvim-mini/mini.pairs",
    enabled = vim.g.auto_pairs == "mini",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
    config = function(_, opts)
      LazyVim.mini.pairs(opts)
    end,
  },

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
        pairs = {
          ["'"] = {
            {
              "'''",
              when = function(ctx)
                return ctx:text_before_cursor(2) == "''"
              end,
              languages = { "python" },
            },
            -- default behavior kinda weird it doesn't check if next char is single quote
            -- https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua#L41-L53
            {
              "'",
              enter = false,
              space = false,
              when = function(ctx)
                -- The `plaintex` filetype has no treesitter parser, so we can't disable this pair in math environments. Thus, disable this pair completely.
                if ctx.ft == "plaintex" then
                  return false
                end

                -- Allow if next char is a single quote
                if ctx:text_after_cursor(1) == "'" then
                  return true
                end

                -- Block if cursor is on a word character
                if ctx.char_under_cursor:match("%w") then
                  return false
                end

                -- Fallback: use treesitter blacklist
                -- TODO: disable inside "" strings?
                return ctx.ts:blacklist("singlequote").matches
              end,
            },
          },
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
          group = "BlinkPairsMatchParen",
        },
      },
      debug = false,
    },
  },
}
