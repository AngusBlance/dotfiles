return {
  -- C/C++ LSP servers
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "p00f/clangd_extensions.nvim",
    },
    config = function()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local clangd_ext = require("clangd_extensions")
      local capabilities = {}
      if ok_cmp and cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities then
        capabilities = cmp_nvim_lsp.default_capabilities()
      end

      -- clangd with extensions (minimal, rely on project compile_commands.json or .clangd)
      local cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never",
        "--all-scopes-completion",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      }

      -- If a build directory has compile_commands.json, point clangd to it
      local build_db = vim.fn.getcwd() .. "/build/compile_commands.json"
      if vim.fn.filereadable(build_db) == 1 then
        table.insert(cmd, "--compile-commands-dir=build")
      end

      local opts = {
        capabilities = capabilities,
        cmd = cmd,
        init_options = {
          clangdFileStatus = true,
        },
      }

      clangd_ext.setup({
        server = opts,
        extensions = {
          inlay_hints = {
            inline = true,
            only_current_line = false,
          },
          ast = {
            role_icons = {
              type = "T",
              declaration = "D",
              expression = "E",
              statement = "S",
              ["template argument"] = "t",
            },
            kind_icons = {},
          },
        },
      })
    end,
  },

  -- Formatters with Conform
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
        },
        formatters = {
          clang_format = {
            command = "clang-format",
            args = { 
              "--style=file:.clang-format",
              "--fallback-style=llvm",
              "-" 
            },
          },
        },
      })

      -- Format on save for C/C++
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.c", "*.cpp", "*.cc", "*.cxx", "*.h", "*.hpp" },
        callback = function(args)
          require("conform").format({ bufnr = args.buf, lsp_fallback = false })
        end,
      })
    end,
  },

  -- Disable all diagnostics for C/C++ files
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Override diagnostic config for C/C++ files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp", "cc", "cxx", "h", "hpp" },
        callback = function()
          vim.diagnostic.disable()
          vim.diagnostic.config({
            virtual_text = false,
            signs = false,
            underline = false,
            update_in_insert = false,
            severity_sort = false,
          })
        end,
      })
    end,
  },
}