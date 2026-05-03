local function on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = fn,
  })
end

local function setup_ai()
  local ai = require("mini.ai")
  local opts = {
    n_lines = 500,
    custom_textobjects = {
      o = ai.gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
      c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      d = { "%f[%d]%d+" },
      e = {
        { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
        "^().*()$",
      },
      g = LazyVim.mini.ai_buffer,
      u = ai.gen_spec.function_call(),
      U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
    },
  }

  require("mini.ai").setup(opts)
  LazyVim.on_load("which-key.nvim", function()
    vim.schedule(function()
      LazyVim.mini.ai_whichkey(opts)
    end)
  end)
end

local function setup_icons()
  require("mini.icons").setup({
    file = {
      [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
      [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
      [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
      [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
      [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
      ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
      ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      ["mdx"] = { glyph = "󰍔", hl = "MiniIconsYellow" },
    },
    filetype = {
      dotenv = { glyph = "", hl = "MiniIconsYellow" },
      gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
      ["markdown.mdx"] = { glyph = "󰍔", hl = "MiniIconsYellow" },
    },
    lsp = {
      copilot = { glyph = "", hl = "MiniIconsRed" },
    },
  })
end

local function setup_surround()
  local opts = {
    mappings = {
      add = "gsa",
      delete = "gsd",
      find = "gsf",
      find_left = "gsF",
      highlight = "gsh",
      replace = "gsr",
      update_n_lines = "gsn",
    },
  }
  require("mini.surround").setup(opts)
end

return {
  { "nvim-mini/mini.ai", enabled = false },
  { "nvim-mini/mini.icons", enabled = false },
  { "nvim-mini/mini.pairs", enabled = false },
  {
    "nvim-mini/mini.nvim",
    version = false,
    lazy = false,
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    config = function()
      -- mini.icons
      setup_icons()

      on_very_lazy(function()
        -- mini.ai
        setup_ai()

        -- mini.comment
        require("mini.comment").setup({
          options = {
            custom_commentstring = function()
              return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
            end,
          },
        })

        -- mini.move
        require("mini.move").setup({})

        -- mini.surround
        setup_surround()

        -- mini.bracketed
        require("mini.bracketed").setup({
          comment = { suffix = "r", options = {} },
        })

        -- mini.cmdline
        require("mini.cmdline").setup({
          autocomplete = {
            enable = false,
          },
        })

        -- mini.cursorword
        require("mini.cursorword").setup({})

        -- mini.pairs
        if vim.g.auto_pairs == "mini" then
          LazyVim.mini.pairs({
            modes = { insert = true, command = true, terminal = false },
            skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
            skip_ts = { "string" },
            skip_unbalanced = true,
            markdown = true,
          })
        end
      end)

      -- mini.hipatterns
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyFile",
        once = true,
        callback = function()
          local hipatterns = require("custom.mini_hipatterns")
          hipatterns.setup(hipatterns.opts())
        end,
      })
    end,
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
}
