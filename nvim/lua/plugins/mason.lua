return {
    {
        "mason-org/mason.nvim",
        -- lazy passes the merged opts (e.g. ui.border from luaLsp.lua) to require("mason").setup().
        opts = {},
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        -- Plugin files each add tools; combine their lists instead of the last file's list winning.
        opts_extend = { "ensure_installed" },
    },
}
