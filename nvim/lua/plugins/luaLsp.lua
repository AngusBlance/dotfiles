return {
	---------------------------------------------------------------------
	-- Mason: install external tools (LSPs, linters, formatters)
	---------------------------------------------------------------------
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		opts = {
			ui = {
				border = "rounded",
			},
		},
	},

	-- Automatically install LSP servers through Mason
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
			},
			automatic_installation = true,
		},
	},

	-- Install formatters/linters via Mason
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "stylua", "selene" },
      auto_update = false,
      run_on_start = true,
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      local cfg = vim.lsp.config
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      cfg.lua_ls = vim.tbl_deep_extend("force", cfg.lua_ls or {}, {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
          },
        },
      })

      local group = vim.api.nvim_create_augroup("user-lua-lsp", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "lua",
        callback = function(event)
          if not vim.lsp.get_clients({ bufnr = event.buf, name = "lua_ls" })[1] then
            vim.lsp.start(cfg.lua_ls)
          end
        end,
      })
    end,
  },

  -- Default linting/formatting plugins without extra config
  { "mfussenegger/nvim-lint" },

	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = function(bufnr)
				-- Format Lua files automatically; fallback to LSP when needed.
				if vim.bo[bufnr].filetype == "lua" then
					return { lsp_fallback = true, timeout_ms = 500 }
				end
			end,
			notify_on_error = false,
		},
	},
}
