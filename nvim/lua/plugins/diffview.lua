return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			keymaps = {
				view = { -- active diff buffers
					["q"] = "<cmd>DiffviewClose<CR>",
					["<leader>r"] = "<cmd>DiffviewRefresh<CR>", -- refresh the current Diffview
				},
				file_panel = {
					["q"] = "<cmd>DiffviewClose<CR>",
					["<leader>r"] = "<cmd>DiffviewRefresh<CR>",
				},
				file_history_panel = {
					["q"] = "<cmd>DiffviewClose<CR>",
					["<leader>r"] = "<cmd>DiffviewRefresh<CR>",
				},
			},
		},
		keys = {
			{
				"dv",
				function()
					local lib = require("diffview.lib")
					if next(lib.views) == nil then
						vim.cmd("DiffviewOpen")
					else
						vim.cmd("DiffviewClose")
					end
				end,
				desc = "Toggle Diffview",
			},
			{ "dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
		},
	},
}
