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
