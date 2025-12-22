-- when running `nvim my/folder` sets cwd to be my/folder
IS_OPENED_TO_DIR = vim.fn.isdirectory(vim.v.argv[3]) == 1
if IS_OPENED_TO_DIR then
  vim.api.nvim_set_current_dir(vim.v.argv[3])
end
-- Watch directory for changes if opened to a directory
if IS_OPENED_TO_DIR then
  require("custom.directory-watcher").setup({
    path = vim.fn.getcwd(),
    debounce = 100,
  })
end
require("custom.hotreload")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
