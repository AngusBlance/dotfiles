return {
    ---------------------------------------------------------------------
    -- Mason: install external tools (LSPs, linters, formatters)
    ---------------------------------------------------------------------
    {
        "mason-org/mason.nvim",
        build = ":MasonUpdate",
        opts = {
            ui = {
                border = "rounded",
            },
        },
    },

    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                lua_ls = {
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
                },
            },
        },
    },

    -- Install formatters/linters via Mason
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "stylua", "selene" },
            auto_update = false,
            run_on_start = true,
        },
    },

    -- Default linting/formatting plugins without extra config
    { "mfussenegger/nvim-lint" },

    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = "ConformInfo",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
            },
            formatters = {
                stylua = {
                    -- stylua defaults to tabs; use 4 spaces unless the project ships its own stylua config.
                    prepend_args = function(_, ctx)
                        local config = vim.fs.find(
                            { "stylua.toml", ".stylua.toml" },
                            { upward = true, path = ctx.dirname }
                        )
                        if #config > 0 then
                            return {}
                        end
                        return { "--indent-type", "Spaces", "--indent-width", "4" }
                    end,
                },
            },
            -- Single format_on_save for every conform filetype (python.lua only adds formatters).
            format_on_save = function(bufnr)
                local ft = vim.bo[bufnr].filetype
                if ft == "lua" then
                    return { lsp_format = "fallback", timeout_ms = 500 }
                elseif ft == "python" then
                    return { lsp_format = "never", timeout_ms = 3000 }
                end
            end,
            notify_on_error = false,
        },
    },
}
