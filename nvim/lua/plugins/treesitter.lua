-- lua/plugins/treesitter.lua
local parsers = {
    "c",
    "cpp",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "python",
    "javascript",
    "typescript",
    "tsx",
    "html",
    "css",
}
local max_filesize = 100 * 1024 -- 100 KB

return {
    {
        -- The main branch is the rewrite that supports Neovim 0.12; master is frozen at 0.11.
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install(parsers)

            local filetypes = {}
            for _, lang in ipairs(parsers) do
                vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang))
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = filetypes,
                callback = function(args)
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
                    if ok and stats and stats.size > max_filesize then
                        -- Neovim's own ftplugins (lua, markdown, help, query) start highlighting after this runs.
                        vim.schedule(function()
                            if vim.api.nvim_buf_is_valid(args.buf) then
                                vim.treesitter.stop(args.buf)
                            end
                        end)
                        return
                    end
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },
    {
        -- nvim-treesitter's main branch compiles parsers with the tree-sitter CLI.
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "tree-sitter-cli" },
        },
    },
}
