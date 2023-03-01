local present, null_ls = pcall(require, "null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

if not present then
    return
end

local b = null_ls.builtins

local sources = { -- webdev stuff
-- b.formatting.deno_fmt, 
b.formatting.prettier, -- b.formatting.prettier.with {
--     filetypes = {"html", "markdown", "css", "tsx", "ts", "js", "jsx", "scss"}
-- }, -- Lua
b.formatting.stylua, -- Shell
b.formatting.shfmt, b.diagnostics.shellcheck.with {
    diagnostics_format = "#{m} [#{c}]"
}, -- cpp
b.formatting.clang_format, b.formatting.gofmt}

null_ls.setup {
    debug = true,
    sources = sources,
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({
                group = augroup,
                buffer = bufnr
            })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.format({
                        bufnr = bufnr
                    })
                end
            })
        end
    end
}
