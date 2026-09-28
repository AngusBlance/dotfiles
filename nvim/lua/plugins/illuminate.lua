return {
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            delay = 100,
            filetypes_denylist = { "help", "markdown", "alpha", "dashboard" },
            under_cursor = true,
            providers = { "lsp", "treesitter", "regex" },
            filetype_overrides = {
                terraform = { providers = { "regex" } },
                tf = { providers = { "regex" } },
                hcl = { providers = { "regex" } },
            },
        },
        -- Highlight colours come from catppuccin's illuminate integration.
        config = function(_, opts)
            require("illuminate").configure(opts)
        end,
    },
}
