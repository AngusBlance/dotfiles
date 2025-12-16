return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Configure diagnostics
		vim.diagnostic.config({
			virtual_text = {
				prefix = "■",
				spacing = 2,
			},
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if ok then
			capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
		end

		vim.lsp.config("clangd", {
			capabilities = capabilities,
			keys = {
				{ "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
			},
			root_markers = {
				"compile_commands.json",
				"compile_flags.txt",
				"configure.ac",
				"Makefile",
				"configure.in",
				"config.h.in",
				"meson.build",
				"meson_options.txt",
				"build.ninja",
				".git",
			},
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--fallback-style=llvm",
			},
			init_options = {
				usePlaceholders = true,
				completeUnimported = true,
				clangdFileStatus = true,
			},
		})

		require("mason-lspconfig").setup({
			ensure_installed = { "clangd", "lua_ls", "html", "cssls", "emmet_ls" },
			automatic_installation = true,
		})

		-- Setup lua_ls
		vim.lsp.config("lua_ls", {
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

		-- Setup html
		vim.lsp.config("html", {
			capabilities = capabilities,
			filetypes = { "html", "htmldjango" },
		})

		-- Setup cssls
		vim.lsp.config("cssls", {
			capabilities = capabilities,
			filetypes = { "css", "scss", "less" },
			settings = {
				css = {
					validate = true,
					lint = {
						unknownAtRules = "ignore",
					},
				},
				scss = {
					validate = true,
					lint = {
						unknownAtRules = "ignore",
					},
				},
				less = {
					validate = true,
					lint = {
						unknownAtRules = "ignore",
					},
				},
			},
		})

		-- Setup emmet_ls
		vim.lsp.config("emmet_ls", {
			capabilities = capabilities,
			filetypes = { "html", "htmldjango", "css", "scss", "less", "javascriptreact", "typescriptreact" },
		})

		-- Auto-format on save for C/C++
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = {"*.c", "*.cpp", "*.h", "*.hpp"},
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})

		-- Auto-format on save for HTML/CSS
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = {"*.html", "*.css", "*.scss", "*.less"},
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})

		-- Enable auto-attachment for configured LSP servers
		vim.lsp.enable('clangd', 'lua_ls', 'html', 'cssls', 'emmet_ls')
 	end,
}
