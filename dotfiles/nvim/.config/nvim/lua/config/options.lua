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
vim.g.typescript_lsp = "tsgo" -- set to "vtsls" or "ts_ls" or "typescript-tools"
vim.g.typescript_linter = "biome" -- set to "biome" or "oxlint"
vim.g.eslint_flavor = "eslint_d" -- set to "eslint_d" or "eslint"
vim.g.theme_transparency = true -- set to true if you want transparency
vim.g.copilot_flavor = "lua" -- set to "native" or "lua", prefer lua since native needs node 22.x
vim.g.ai_chat = "sidekick" -- set to "avante" or "sidekick"
vim.g.sidekick_nes = false -- set to false stupidly distracting
vim.g.use_builtin_lsp_diagnostics = false -- set to true to use built-in LSP diagnostics instead of tiny-inline-diagnostic.nvim
vim.g.use_completion_ai_source = false -- set to true to enable AI source in completion (Blink, Copilot, etc.) otherwise inline copilot
vim.g.use_blink_indent = true -- set to true to enable blink indent guides
vim.g.use_oil = true -- set to true to use oil.nvim for file browsing (otherwise, fyler)
vim.g.use_ai_to_lookup_rulebook = false -- set to true to use AI to lookup rules in the code (for rulebook)

vim.opt.swapfile = false -- disable swap files
vim.opt.list = false -- disable whitespace characters
vim.opt.clipboard = "unnamedplus"
vim.opt.background = "dark" -- always prefer dark mode

-- kinda broke lazy package manager and flash.nvim border (but nice rounded)
-- vim.o.winborder = "rounded"

-- Clipboard (from https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim)
-- pretty much placeholder for now, as it is working as expected currently
-- can also use https://github.com/bkoropoff/clipipe (but slow startup)
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
