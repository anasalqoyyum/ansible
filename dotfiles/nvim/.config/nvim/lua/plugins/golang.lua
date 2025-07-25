return {
  {
    "ray-x/go.nvim",
    enabled = false,
    dependencies = {
      "ray-x/guihua.lua", -- optional
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
    },
    opts = {}, -- by default lsp_cfg = false
    -- opts = { lsp_cfg = true } -- use go.nvim will setup gopls
    config = function(_, opts)
      require("go").setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          require("go.format").goimports()
        end,
        group = format_sync_grp,
      })

      local gopls_cfg = require("go.lsp").config()
      vim.lsp.config.gopls = gopls_cfg
      vim.lsp.enable("gopls")
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
  },
}
