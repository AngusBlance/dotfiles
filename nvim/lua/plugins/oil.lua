return {
	"stevearc/oil.nvim",
	opts = {},
	-- Optional: lazy-load on command
	cmd = "Oil",
	-- Optional: keymap to open Oil in cwd
	keys = {
		{ "<leader>e", "<cmd>Oil<cr>", desc = "Open parent dir with Oil" },
	},
}
