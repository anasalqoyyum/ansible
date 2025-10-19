local inlay_hints_settings = {
  includeInlayEnumMemberValueHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayParameterNameHints = "literals",
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayVariableTypeHints = false,
  includeInlayVariableTypeHintsWhenTypeMatchesName = false,
}

local typescript_keys = {
  {
    "gD",
    function()
      local win = vim.api.nvim_get_current_win()
      local params = vim.lsp.util.make_position_params(win, "utf-16")
      LazyVim.lsp.execute({
        command = "typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
        open = true,
      })
    end,
    desc = "Goto Source Definition",
  },
  {
    "gR",
    function()
      LazyVim.lsp.execute({
        command = "typescript.findAllFileReferences",
        arguments = { vim.uri_from_bufnr(0) },
        open = true,
      })
    end,
    desc = "File References",
  },
  {
    "<leader>co",
    LazyVim.lsp.action["source.organizeImports"],
    desc = "Organize Imports",
  },
  {
    "<leader>cM",
    LazyVim.lsp.action["source.addMissingImports.ts"],
    desc = "Add missing imports",
  },
  {
    "<leader>cu",
    LazyVim.lsp.action["source.removeUnused.ts"],
    desc = "Remove unused imports",
  },
  {
    "<leader>cD",
    LazyVim.lsp.action["source.fixAll.ts"],
    desc = "Fix all diagnostics",
  },
  {
    "<leader>cV",
    function()
      LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
    end,
    desc = "Select TS workspace version",
  },
}

local filetypes = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "vue",
}

local tsPlugins = {
  {
    name = "@astrojs/ts-plugin",
    location = LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin"),
    enableForWorkspaceTypeScriptVersions = true,
  },
  {
    name = "@vue/typescript-plugin",
    location = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
    languages = { "vue" },
    configNamespace = "typescript",
    enableForWorkspaceTypeScriptVersions = true,
  },
  {
    name = "typescript-svelte-plugin",
    location = LazyVim.get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
    enableForWorkspaceTypeScriptVersions = true,
  },
  {
    name = "@angular/language-server",
    location = LazyVim.get_pkg_path("angular-language-server", "/node_modules/@angular/language-server"),
    enableForWorkspaceTypeScriptVersions = false,
  },
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsgo = {
          enabled = vim.g.typescript_lsp == "tsgo",
          filetypes = filetypes,
          keys = typescript_keys,
          settings = {
            typescript = {
              inlayHints = inlay_hints_settings,
            },
            javascript = {
              inlayHints = inlay_hints_settings,
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
          init_options = {
            plugins = tsPlugins,
          },
        },
        ts_ls = {
          enabled = vim.g.typescript_lsp == "ts_ls",
          filetypes = filetypes,
          keys = typescript_keys,
          settings = {
            typescript = {
              inlayHints = inlay_hints_settings,
            },
            javascript = {
              inlayHints = inlay_hints_settings,
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
          init_options = {
            plugins = tsPlugins,
          },
        },
        vtsls = {
          enabled = vim.g.typescript_lsp == "vtsls",
          filetypes = filetypes,
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
              tsserver = {
                globalPlugins = tsPlugins,
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          keys = typescript_keys,
        },
      },
      setup = {
        vtsls = function(_, opts)
          LazyVim.lsp.on_attach(function(client, buffer)
            client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
              ---@type string, string, lsp.Range
              local action, uri, range = unpack(command.arguments)

              local function move(newf)
                client:request("workspace/executeCommand", {
                  command = command.command,
                  arguments = { action, uri, range, newf },
                })
              end

              local fname = vim.uri_to_fname(uri)
              client:request("workspace/executeCommand", {
                command = "typescript.tsserverRequest",
                arguments = {
                  "getMoveToRefactoringFileSuggestions",
                  {
                    file = fname,
                    startLine = range.start.line + 1,
                    startOffset = range.start.character + 1,
                    endLine = range["end"].line + 1,
                    endOffset = range["end"].character + 1,
                  },
                },
              }, function(_, result)
                ---@type string[]
                local files = result.body.files
                table.insert(files, 1, "Enter new path...")
                vim.ui.select(files, {
                  prompt = "Select move destination:",
                  format_item = function(f)
                    return vim.fn.fnamemodify(f, ":~:.")
                  end,
                }, function(f)
                  if f and f:find("^Enter new path") then
                    vim.ui.input({
                      prompt = "Enter move destination:",
                      default = vim.fn.fnamemodify(fname, ":h") .. "/",
                      completion = "file",
                    }, function(newf)
                      return newf and move(newf)
                    end)
                  elseif f then
                    move(f)
                  end
                end)
              end)
            end
          end, "vtsls")
          -- copy typescript settings to javascript
          opts.settings.javascript =
            vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
        end,
      },
    },
  },

  -- if vtsls use nvim-vtsls, if ts_ls use typescript-tools.nvim (choose one either ts_ls or typescript-tools)
  {
    "yioneko/nvim-vtsls",
    enabled = vim.g.typescript_lsp == "vtsls",
    ft = {
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    enabled = vim.g.typescript_lsp == "typescript-tools",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        expose_as_code_action = "all",
        tsserver_plugin = {
          "@astrojs/ts-plugin",
          "@vue/typescript-plugin",
          "typescript-svelte-plugin",
        },
        tsserver_file_preferences = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = "literals",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        },
      },
    },
  },

  -- broken on yarn berry without node-linker lol
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {
          -- Filter directories when searching for test files. Useful in large projects (see Filter directories notes).
          filter_dir = function(name, rel_path, root)
            return name ~= "node_modules"
          end,
        },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "js-debug-adapter")
        end,
      },
    },
    opts = function()
      local dap = require("dap")
      if not dap.adapters["pwa-node"] then
        require("dap").adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            -- 💀 Make sure to update this path to point to your installation
            args = {
              LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
              "${port}",
            },
          },
        }
      end
      if not dap.adapters["node"] then
        dap.adapters["node"] = function(cb, config)
          if config.type == "node" then
            config.type = "pwa-node"
          end
          local nativeAdapter = dap.adapters["pwa-node"]
          if type(nativeAdapter) == "function" then
            nativeAdapter(cb, config)
          else
            cb(nativeAdapter)
          end
        end
      end

      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          dap.configurations[language] = {
            {
              type = "pwa-node",
              request = "launch",
              name = "Node: Debug Current File",
              program = "${file}",
              cwd = "${workspaceFolder}",
            },
            {
              type = "pwa-node",
              request = "attach",
              name = "Node: Attach",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
            },
          }
        end
      end
    end,
  },
}
