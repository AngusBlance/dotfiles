return {
  -- Python LSP servers
  {
    "neovim/nvim-lspconfig",
    config = function()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = {}
      if ok_cmp and cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities then
        capabilities = cmp_nvim_lsp.default_capabilities()
      end

      -- basedpyright
      if vim.lsp and vim.lsp.config then
        vim.lsp.config("basedpyright", {
          capabilities = capabilities,
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "strict",
                autoImportCompletions = true,
              },
            },
          },
        })

        -- ruff
        vim.lsp.config("ruff", {
          capabilities = capabilities,
        })
      end
    end,
  },

  -- Formatters with Conform - Fixed configuration
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "autopep8" },
        },
        formatters = {
          autopep8 = {
            command = "autopep8",
            args = { "--max-line-length", "120", "-" },
          },
        },
      })

      -- Format on save for Python
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.py",
        callback = function(args)
          require("conform").format({ bufnr = args.buf, lsp_fallback = false })
        end,
      })
    end,
  },

  -- Python linting with nvim-lint
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { python = { "ruff" } }

      if lint.linters.ruff then
        lint.linters.ruff.args = {
          "check",
          "--config",
          vim.fn.stdpath("config") .. "/ruff.toml",
          "--output-format",
          "text",
          "--stdin-filename",
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
          "-",
        }
      end

      local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}


