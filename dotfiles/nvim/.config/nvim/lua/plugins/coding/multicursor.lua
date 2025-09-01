return {
  -- multi-cursor
  -- {
  --   "mg979/vim-visual-multi",
  --   event = "VeryLazy",
  --   init = function()
  --     vim.g.VM_mouse_mappings = 1
  --     vim.g.VM_default_mappings = 0
  --   end,
  -- },

  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      local set = vim.keymap.set

      -- stylua: ignore start
      -- Add or skip cursor above/below the main cursor.
      set({ "n", "v" }, "<leader>mk", function() mc.lineAddCursor(-1) end, { desc = "Add Cursor Above" })
      set({ "n", "v" }, "<leader>mj", function() mc.lineAddCursor(1) end, { desc = "Add Cursor Below" })
      set({ "n", "v" }, "<leader>m<up>", function() mc.lineSkipCursor(-1) end, { desc = "Skip Cursor Above" })
      set({ "n", "v" }, "<leader>m<down>", function() mc.lineSkipCursor(1) end, { desc = "Skip Cursor Below" })

      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "v" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Add Next Selection" })
      set({ "n", "v" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Add Next Selection" })

      set({ "n", "v" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Skip Next Selection" })
      set({ "n", "v" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "Add Previous Selection" })
      set({ "n", "v" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "Skip Previous Selection" })

      -- Add all matches in the document
      set({ "n", "v" }, "<leader>mA", mc.matchAllAddCursors, { desc = "Add All Selections" })

      -- Rotate the main cursor.
      set({ "n", "v" }, "<leader>m<left>", mc.nextCursor, { desc = "Next Cursor" })
      set({ "n", "v" }, "<leader>m<right>", mc.prevCursor, { desc = "Previous Cursor" })

      -- Delete the main cursor.
      set({ "n", "v" }, "<leader>mx", mc.deleteCursor, { desc = "Delete Cursor" })
      set({ "n", "v" }, "<leader>md", mc.clearCursors, { desc = "Clear Cursor" })

      -- Add and remove cursors with control + left click.
      set("n", "<c-leftmouse>", mc.handleMouse, { desc = "Add Cursor" })
      set("n", "<c-leftdrag>", mc.handleMouseDrag, { desc = "Drag Cursor" })
      set("n", "<c-leftrelease>", mc.handleMouseRelease, { desc = "Release Cursor" })

      -- Align cursor columns.
      set("n", "<leader>ma", mc.alignCursors, { desc = "Align Cursors" })

      -- Split visual selections by regex.
      set("v", "S", mc.splitCursors, { desc = "Split Selections" })

      -- Append/insert for each line of visual selections.
      set("v", "I", mc.insertVisual, { desc = "Insert Selections" })
      set("v", "A", mc.appendVisual, { desc = "Append Selections" })

      -- match new cursors within visual selections by regex.
      set("v", "M", mc.matchCursors, { desc = "Match Selections" })

      -- Rotate visual selection contents.
      set("v", "<leader>mt", function() mc.transposeCursors(1) end, { desc = "Transpose Selections Forward" })
      set("v", "<leader>mT", function() mc.transposeCursors(-1) end, { desc = "Transpose Selections Backward" })
      -- stylua: ignore end

      -- Jumplist support
      set({ "v", "n" }, "<c-i>", mc.jumpForward)
      set({ "v", "n" }, "<c-o>", mc.jumpBackward)

      mc.addKeymapLayer(function(layerSet)
        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { link = "Cursor" })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
  },
}
