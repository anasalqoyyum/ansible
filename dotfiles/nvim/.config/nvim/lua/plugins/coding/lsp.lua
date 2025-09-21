return {
  -- prefer to use the newer one (and more maintaned source)
  { "giuxtaposition/blink-cmp-copilot", enabled = false },
  {
    "saghen/blink.cmp",
    dependencies = {
      "fang2hou/blink-copilot",
      opts = {
        max_completions = 1, -- Global default for max completions
        max_attempts = 2, -- Global default for max attempts
      },
    },
    opts = {
      -- let's use builtin blink snippets (if want luasnip then enable lazy extras)
      -- snippets = { preset = "luasnip" },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "item_idx", "kind_icon", gap = 1 },
              { "label", "label_description", "kind", gap = 1 },
            },
            -- honestly, the highlight is kinda useless if using theme that have blink.cmp support
            components = {
              kind_icon = {
                text = function(ctx)
                  -- fix tailwindcss not showing icon with color
                  if ctx.kind == "Color" then
                    return ctx.kind_icon .. " "
                  end

                  local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                  return kind_icon .. " "
                end,
                highlight = function(ctx)
                  -- fix tailwindcss not showing icon with color
                  if ctx.kind == "Color" then
                    return { { group = ctx.kind_hl, priority = 20000 } }
                  end

                  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                  -- Set the highlight priority to 20000 to beat the cursorline's default priority of 10000
                  return { { group = hl, priority = 20000 } }
                end,
              },
              kind = {
                highlight = function(ctx)
                  -- fix tailwindcss not showing icon with color
                  if ctx.kind == "Color" then
                    return { { group = ctx.kind_hl, priority = 20000 } }
                  end

                  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                  return { { group = hl, priority = 20000 } }
                end,
              },
              item_idx = {
                text = function(ctx)
                  return ctx.idx == 10 and "0" or ctx.idx >= 10 and " " or tostring(ctx.idx)
                end,
                highlight = function(ctx)
                  -- fix tailwindcss not showing icon with color
                  if ctx.kind == "Color" then
                    return { { group = ctx.kind_hl, priority = 20000 } }
                  end

                  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                  return { { group = hl, priority = 20000 } }
                end,
              },
            },
          },
          border = "rounded",
          scrollbar = true,
          -- Avoid multi-line completion ghost text
          direction_priority = function()
            local ctx = require("blink.cmp").get_context()
            local item = require("blink.cmp").get_selected_item()
            if ctx == nil or item == nil then
              return { "s", "n" }
            end

            local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
            local is_multi_line = item_text:find("\n") ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id
              return { "n", "s" }
            end
            return { "s", "n" }
          end,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded", scrollbar = true },
        },
        ghost_text = {
          enabled = true,
        },
        list = {
          selection = {
            -- preselect = function(_)
            --   return not require("blink.cmp").snippet_active({ direction = 1 })
            -- end,

            -- absolutely faster with this disabled
            preselect = false,
            auto_insert = true,
          },
        },
      },

      -- experimental signature help support
      signature = { enabled = true, window = { border = "rounded", show_documentation = true } },

      sources = {
        -- adding any nvim-cmp sources here will enable them
        -- with blink.compat
        compat = {},
        default = { "copilot", "lsp", "path", "snippets", "buffer" },
        -- this is the newer copilot source
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
          snippets = {
            should_show_items = function(ctx)
              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
          },
        },
      },

      -- let's try enabling it
      -- cmdline = {
      --   enabled = false,
      -- },

      fuzzy = { implementation = "prefer_rust_with_warning" },

      keymap = {
        preset = "none",

        -- this is basically super-tab and enter to accept similar to vscode
        -- disable input sources shortcut in macos for this to work
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },

        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },

        -- manually set some due to it's not being picked up on macos lol
        ["<C-y>"] = { "select_and_accept", "fallback" },

        -- stylua: ignore start
        ['<A-1>'] = { function(cmp) cmp.accept({ index = 1 }) end },
        ['<A-2>'] = { function(cmp) cmp.accept({ index = 2 }) end },
        ['<A-3>'] = { function(cmp) cmp.accept({ index = 3 }) end },
        ['<A-4>'] = { function(cmp) cmp.accept({ index = 4 }) end },
        ['<A-5>'] = { function(cmp) cmp.accept({ index = 5 }) end },
        ['<A-6>'] = { function(cmp) cmp.accept({ index = 6 }) end },
        ['<A-7>'] = { function(cmp) cmp.accept({ index = 7 }) end },
        ['<A-8>'] = { function(cmp) cmp.accept({ index = 8 }) end },
        ['<A-9>'] = { function(cmp) cmp.accept({ index = 9 }) end },
        ['<A-0>'] = { function(cmp) cmp.accept({ index = 10 }) end },
        -- stylua: ignore end
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "",
          -- only shows virtual text for the current line
          -- current_line = true,

          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
          -- prefix = ""
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },

  {
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    event = "BufEnter",
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    opts = {
      default_mappings = true,
      vim_ui_input = false,
      references = {
        provider = "snacks",
      },
    },
  },

  {
    "chrisgrieser/nvim-rulebook",
    enabled = false,
    branch = "dev",
    event = "LspAttach",
    opts = {
      suppressFormatter = {
        javascript = {
          ignoreBlock = "// prettier-ignore",
          location = "prevLine",
        },
      },
    },
    keys = {
      {
        "<leader>ri",
        function()
          require("rulebook").ignoreRule()
        end,
        desc = "Rulebook: Ignore diagnostic rule",
      },
      {
        "<leader>rl",
        function()
          require("rulebook").lookupRule()
        end,
        desc = "Rulebook: Lookup diagnostic rule",
      },
      {
        "<leader>ry",
        function()
          require("rulebook").yankDiagnosticCode()
        end,
        desc = "Rulebook: Yank diagnostic code",
      },
      {
        "<leader>rf",
        function()
          require("rulebook").suppressFormatter()
        end,
        mode = { "n", "x" },
        desc = "Rulebook: Suppress formatter",
      },
    },
  },
}
