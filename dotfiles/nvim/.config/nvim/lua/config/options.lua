-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false
vim.g.lazyvim_prettier_needs_config = true -- need this due to biome support parent config
vim.g.lazyvim_eslint_auto_format = false -- kinda not needed since already explicitly disabled
vim.g.lazyvim_picker = "snacks"

vim.g.lazyvim_blink_main = true -- this set blink to use main branch
vim.g.lazyvim_python_lsp = "basedpyright" -- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_rust_diagnostics = "bacon-ls" -- Set to "bacon-ls" to use bacon-ls instead of rust-analyzer.
vim.g.auto_pairs = "mini" -- set to "mini" or "blink"
vim.g.typescript_lsp = "vtsls" -- set to "vtsls" or "ts_ls" or "typescript-tools"
vim.g.typescript_linter = "biome" -- set to "biome" or "oxlint"
vim.g.theme_transparency = false -- set to true if you want transparency
vim.g.copilot_flavor = "lua" -- set to "native" or "lua", prefer lua since native needs node 22.x
vim.g.ai_chat = "sidekick" -- set to "avante" or "opencode"

vim.g.astro_typescript = "enable" -- this needed for vim-astro for ts capabilities

vim.opt.swapfile = false -- disable swap files
vim.opt.clipboard = "unnamedplus"

-- kinda broke whichkey (but nice rounded)
-- vim.o.winborder = "rounded"

-- Clipboard (from https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim)
-- pretty much placeholder for now, as it is working as expected currently
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
