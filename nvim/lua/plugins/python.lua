return {
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "black" },
        },
    },
    {
        -- format_on_save lives in luaLsp.lua; a table here would replace that function when lazy merges opts.
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                python = { "black" },
            },
        },
    },
}
