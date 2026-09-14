return {
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = { "black" },
        },
    },
    {
        "stevearc/conform.nvim",
        ft = { "python" },
        opts = {
            formatters_by_ft = {
                python = { "black" },
            },
            format_on_save = {
                timeout_ms = 3000,
                lsp_fallback = false,
            },
        },
    },
}
