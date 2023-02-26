local overrides = require "custom.plugins.overrides"

return {

    ----------------------------------------- default plugins ------------------------------------------

    ["goolord/alpha-nvim"] = {
        disable = false,
        cmd = "Alpha",
        override_options = overrides.alpha
    },

    ["neovim/nvim-lspconfig"] = {
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.plugins.lspconfig"
        end
    },

    --------------------------------------------- custom plugins ----------------------------------------------

    -- autoclose tags in html, jsx only
    ["windwp/nvim-ts-autotag"] = {
        ft = {"html", "javascriptreact"},
        after = "nvim-treesitter",
        config = function()
            local present, autotag = pcall(require, "nvim-ts-autotag")

            if present then
                autotag.setup()
            end
        end
    },

    -- format & linting
    ["jose-elias-alvarez/null-ls.nvim"] = {
        after = "nvim-lspconfig",
        config = function()
            require "custom.plugins.null-ls"
        end
    },

    -- get highlight group under cursor
    ["nvim-treesitter/playground"] = {
        cmd = "TSCaptureUnderCursor",
        config = function()
            require("nvim-treesitter.configs").setup()
        end
    },

    ["VonHeikemen/lsp-zero.nvim"] = {
        branch = 'v1.x',
        requires = { -- LSP Support
        {'neovim/nvim-lspconfig'}, -- Required
        {'williamboman/mason.nvim'}, -- Optional
        {'williamboman/mason-lspconfig.nvim'}, -- Optional
        -- Autocompletion
        {'hrsh7th/nvim-cmp'}, -- Required
        {'hrsh7th/cmp-nvim-lsp'}, -- Required
        {'hrsh7th/cmp-buffer'}, -- Optional
        {'hrsh7th/cmp-path'}, -- Optional
        {'saadparwaiz1/cmp_luasnip'}, -- Optional
        {'hrsh7th/cmp-nvim-lua'}, -- Optional
        -- Snippets
        {'L3MON4D3/LuaSnip'}, -- Required
        {'rafamadriz/friendly-snippets'} -- Optional
        },
        config = function()
            local lsp = require('lsp-zero').preset({
                name = 'minimal',
                set_lsp_keymaps = true,
                manage_nvim_cmp = true,
                suggest_lsp_servers = false
            })

            -- (Optional) Configure lua language server for neovim
            -- lsp.nvim_workspace()

            lsp.setup()
        end
    }
}
