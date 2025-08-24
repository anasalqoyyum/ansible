-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false
vim.g.lazyvim_prettier_needs_config = true
vim.g.lazyvim_eslint_auto_format = false
vim.g.lazyvim_picker = "snacks"

vim.g.lazyvim_blink_main = true -- this set blink to use main branch
vim.g.lazyvim_python_lsp = "basedpyright" -- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.astro_typescript = "enable" -- this need vim-astro
vim.g.theme_transparency = false -- set to true if you want transparency

vim.opt.swapfile = false -- disable swap files

-- kinda broke whichkey
-- vim.o.winborder = "rounded"

-- Clipboard (from https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim)
-- pretty much placeholder for now, as it is working as expected currently
-- opt.clipboard = "unnamedplus"
--
-- if vim.fn.has("wsl") == 1 then
--     local win32yank = "win32yank.exe"
--     if vim.fn.getftype(vim.fn.exepath(win32yank)) == "link" then
--         win32yank = vim.fn.resolve(vim.fn.exepath(win32yank))
--     end
--
--     vim.g.clipboard = {
--         name = "win32yank",
--         copy = {
--             ["+"] = { win32yank, "-i", "--crlf" },
--             ["*"] = { win32yank, "-i", "--crlf" },
--         },
--         paste = {
--             ["+"] = { win32yank, "-o", "--lf" },
--             ["*"] = { win32yank, "-o", "--lf" },
--         },
--         cache_enabled = 1, -- cache fixes del lag
--     }
-- end
