if vim.g.copilot_flavor ~= "lua" then
  return {}
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality (and still experimental)
      enabled = vim.g.ai_chat ~= "sidekick",
      init = function()
        vim.g.copilot_nes_debounce = 500
        vim.keymap.set("n", "<tab>", function()
          local bufnr = vim.api.nvim_get_current_buf()
          local state = vim.b[bufnr].nes_state
          if state then
            -- Try to jump to the start of the suggestion edit.
            -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
            local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
              or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
            return nil
          else
            -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
            return "<C-i>"
          end
        end, { desc = "Accept Copilot NES suggestion", expr = true })

        -- Clear copilot suggestion with Esc if visible, otherwise preserve default Esc behavior
        vim.keymap.set("n", "<esc>", function()
          if not require("copilot-lsp.nes").clear() then
            -- fallback to other functionality
          end
        end, { desc = "Clear Copilot suggestion or fallback" })
      end,
    },
    opts = {
      server = {
        type = "binary",
      },
      suggestion = {
        enabled = false,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 300, -- debounce for reliable multi-line suggestions (in ms)
        keymap = {
          accept = false, -- handled by nvim-cmp / blink.cmp
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      nes = {
        enabled = false,
        auto_trigger = true,
        -- set manually in init above
        keymap = {
          accept_and_goto = false,
          accept = false,
          dismiss = false,
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  -- copilot-language-server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- copilot.lua only works with its own copilot lsp server
        copilot = { enabled = false },
      },
    },
  },

  -- add ai_accept action
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      LazyVim.cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          LazyVim.create_undo()
          require("copilot.suggestion").accept()
          return true
        end
      end
    end,
  },
}
