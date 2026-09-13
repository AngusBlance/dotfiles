return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		-- Plugin files each add tools; combine their lists instead of the last file's list winning.
		opts_extend = { "ensure_installed" },
	},
}
