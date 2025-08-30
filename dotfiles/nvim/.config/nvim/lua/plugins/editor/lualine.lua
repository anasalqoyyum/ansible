-- Helper function to check if a plugin is available
local function is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

-- Check plugin availability once during setup
local integrations = {
  conform = is_available("conform.nvim"),
  lint = is_available("nvim-lint"),
}

-- A simple LSP status component for lualine that shows active LSPs, linters, and formatters
local function lsp_status_simple()
  return function()
    local bufnr = 0
    local all_tools = {}
    local seen_tools = {}

    -- Helper to normalize ruff variants
    local function normalize_name(name)
      return name:match("^ruff") and "ruff" or name
    end

    -- Add LSPs
    for _, server in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      local normalized = normalize_name(server.name)
      if not seen_tools[normalized] then
        table.insert(all_tools, normalized)
        seen_tools[normalized] = true
      end
    end

    -- Add linters (only if available and loaded)
    if integrations.lint and package.loaded["lint"] then
      local lint = require("lint")
      local ft = vim.bo[bufnr].filetype
      if lint.linters_by_ft[ft] then
        for _, linter in ipairs(lint.linters_by_ft[ft]) do
          local normalized = normalize_name(linter)
          if not seen_tools[normalized] then
            table.insert(all_tools, normalized)
            seen_tools[normalized] = true
          end
        end
      end
    end

    -- Add formatters (only if available and loaded)
    if integrations.conform and package.loaded["conform"] then
      local conform = require("conform")
      local formatters = conform.list_formatters(0)
      for _, formatter in ipairs(formatters) do
        local normalized = normalize_name(formatter.name)
        if not seen_tools[normalized] then
          table.insert(all_tools, normalized)
          seen_tools[normalized] = true
        end
      end
    end

    return #all_tools > 0 and table.concat(all_tools, " ") or ""
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      -- PERF: we don't need this lualine require madness 🤷
      -- local icons = LazyVim.config.icons
      local lualine_require = require("lualine_require")
      lualine_require.require = require

      vim.o.laststatus = vim.g.lualine_laststatus

      local opts = {
        options = {
          theme = "auto",
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
          component_separators = { left = "|", right = "|" },
          section_separators = "",
          -- section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            -- LazyVim.lualine.root_dir({ icon = "󱉭" }),
            {
              "diagnostics",
              symbols = {
                error = " ",
                warn = " ",
                info = " ",
                hint = " ",
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { LazyVim.lualine.pretty_path({ modified_sign = " ●" }), padding = { left = 0, right = 0 } },
          },

          lualine_x = {
            Snacks.profiler.status(),
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = function() return { fg = Snacks.util.color("Statement") } end,
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = function() return { fg = Snacks.util.color("Constant") } end,
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = function() return { fg = Snacks.util.color("Debug") } end,
            },
            -- stylua: ignore
            -- {
            --   require("lazy.status").updates,
            --   cond = require("lazy.status").has_updates,
            --   color = function() return { fg = Snacks.util.color("Special") } end,
            -- },
            {
              "diff",
              symbols = {
                removed = " ",
                modified = " ",
                added = " ",
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            -- this one is missing formatter
            -- { "lsp_status" },
            { lsp_status_simple() },
          },
          lualine_z = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
        },
        extensions = { "lazy", "avante", "oil", "aerial", "quickfix", "trouble" },
      }

      return opts
    end,
  },
}
