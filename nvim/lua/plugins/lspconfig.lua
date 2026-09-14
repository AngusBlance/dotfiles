-- Auto-format on save for C/C++
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
})

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason-lspconfig.nvim",
    },
    -- Language files (luaLsp.lua, webdev.lua, ...) extend opts.servers with their own entries.
    opts = {
        servers = {
            clangd = {
                root_markers = {
                    "compile_commands.json",
                    "compile_flags.txt",
                    "configure.ac",
                    "Makefile",
                    "configure.in",
                    "config.h.in",
                    "meson.build",
                    "meson_options.txt",
                    "build.ninja",
                    ".git",
                },
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    -- Named style with 4-space indent for projects without a .clang-format
                    -- (clangd only accepts style names here, not inline {IndentWidth: 4}).
                    "--fallback-style=webkit",
                },
                init_options = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    clangdFileStatus = true,
                },
            },
        },
    },
    config = function(_, opts)
        -- Configure diagnostics
        vim.diagnostic.config({
            virtual_text = {
                prefix = "■",
                spacing = 2,
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
        if ok then
            capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
        end

        require("mason-lspconfig").setup({
            ensure_installed = vim.tbl_keys(opts.servers),
        })

        for name, server_opts in pairs(opts.servers) do
            vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, server_opts))
        end
        vim.lsp.enable(vim.tbl_keys(opts.servers))

        -- nvim-lspconfig's clangd config creates :LspClangdSwitchSourceHeader per buffer on attach.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.name == "clangd" then
                    vim.keymap.set(
                        "n",
                        "<leader>ch",
                        "<cmd>LspClangdSwitchSourceHeader<cr>",
                        { buffer = args.buf, desc = "Switch Source/Header (C/C++)" }
                    )
                end
            end,
        })
    end,
}
