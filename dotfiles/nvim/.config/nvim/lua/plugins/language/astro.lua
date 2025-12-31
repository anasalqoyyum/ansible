-- Create overrides to fix astro-ls not applying edits (because it doesn't follow the spec)
local orig_apply_text_document_edit = vim.lsp.util.apply_text_document_edit
vim.lsp.util.apply_text_document_edit = function(text_document_edit, index, position_encoding)
  local text_document = text_document_edit.textDocument
  local bufnr = vim.uri_to_bufnr(text_document.uri)

  -- Set the version to nil, so edits can be applied (astro-ls didn't follow specs properly)
  if vim.bo[bufnr].filetype == "astro" then
    text_document_edit.textDocument.version = nil
  end

  return orig_apply_text_document_edit(text_document_edit, index, position_encoding)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "astro", "css" } },
  },

  -- LSP Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
      },
    },
  },
}
