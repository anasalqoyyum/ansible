local M = {}

M.general = {
    n = {
        [";"] = {
            ":",
            "command mode",
            opts = {
                nowait = true
            }
        }
    },

    i = {
        ["jk"] = {"<ESC>", "escape vim"}
    }
}

M.treesitter = {
    n = {
        ["<leader>cu"] = {"<cmd> TSCaptureUnderCursor <CR>", "find media"}
    }
}

return M
