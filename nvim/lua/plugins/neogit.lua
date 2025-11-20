return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
	},
	config = function()
		require("neogit").setup({
			disable_hint = false,
			disable_context_highlighting = false,
			disable_signs = false,
		})
	end,
	keys = {
		{
			"<leader>gn",
			function()
				-- Use the directory of the current file; fall back to current working dir
				local cwd = vim.fn.expand("%:p:h")
				if cwd == "" then
					cwd = vim.fn.getcwd()
				end
				vim.cmd("Neogit cwd=" .. vim.fn.fnameescape(cwd))
			end,
			desc = "Open Neogit (cwd = current file dir)",
			mode = "n",
			silent = true,
		},
	},
}
