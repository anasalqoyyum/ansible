-- import this to init.lua (this was used to debug astro-ls not returning null in the version)

-- Intercept workspace/applyEdit handler
local orig_apply_edit = vim.lsp.handlers["workspace/applyEdit"]
vim.lsp.handlers["workspace/applyEdit"] = function(err, result, ctx, config)
  vim.schedule(function()
    vim.notify("[LSP DEBUG] workspace/applyEdit:\n" .. vim.inspect(result), vim.log.levels.INFO)
  end)
  return orig_apply_edit(err, result, ctx, config)
end

-- Intercept executeCommand requests from client → server
local orig_request = vim.lsp.buf_request
vim.lsp.buf_request = function(bufnr, method, params, handler, ...)
  vim.schedule(function()
    vim.notify("[LSP DEBUG] Sending executeCommand:\n" .. vim.inspect(params), vim.log.levels.INFO)
  end)
  return orig_request(bufnr, method, params, handler, ...)
end

-- Intercept executeCommand responses server → client
local orig_execute_handler = vim.lsp.handlers["workspace/executeCommand"]
vim.lsp.handlers["workspace/executeCommand"] = function(err, result, ctx, config)
  vim.schedule(function()
    vim.notify(
      "[LSP DEBUG] workspace/executeCommand RESPONSE:\n" .. vim.inspect({ err = err, result = result, ctx = ctx }),
      vim.log.levels.INFO
    )
  end)

  if orig_execute_handler then
    return orig_execute_handler(err, result, ctx, config)
  end
end

-- Intercept text document edits
local orig_apply_text_edit = vim.lsp.util.apply_text_document_edit
vim.lsp.util.apply_text_document_edit = function(edit, index, offset_encoding)
  vim.schedule(function()
    vim.notify("[LSP DEBUG] apply_text_document_edit:\n" .. vim.inspect(edit), vim.log.levels.INFO)
  end)
  return orig_apply_text_edit(edit, index, offset_encoding)
end

-- Intercept all code actions before applying
local orig_code_action = vim.lsp.buf.code_action
vim.lsp.buf.code_action = function(opts)
  vim.notify("[LSP DEBUG] Requesting code actions...", vim.log.levels.INFO)
  return orig_code_action(opts)
end
