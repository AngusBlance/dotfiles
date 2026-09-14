-- Auto-format on save for JS/TS
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.ts", "*.jsx", "*.tsx" },
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
})

-- Auto-format on save for HTML/CSS with code block preservation
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.html", "*.css", "*.scss", "*.less" },
    callback = function()
        -- Skip code block preservation for non-HTML files
        if vim.bo.filetype ~= "html" and vim.bo.filetype ~= "htmldjango" then
            vim.lsp.buf.format({ async = false })
            return
        end

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local code_blocks = {}
        local new_lines = {}
        local i = 1

        -- Replace code blocks with unique placeholders so formatting can't desync line numbers
        while i <= #lines do
            local line = lines[i]
            if line:match("<pre[^>]*>.*<code[^>]*>") and not line:match("</code>.*</pre>") then
                local block = { line }
                i = i + 1
                while i <= #lines and not lines[i]:match("</code>.*</pre>") do
                    table.insert(block, lines[i])
                    i = i + 1
                end
                if i <= #lines then
                    table.insert(block, lines[i])
                end
                table.insert(code_blocks, block)
                table.insert(new_lines, "@@CODEBLOCK_" .. #code_blocks .. "@@")
                i = i + 1
            else
                table.insert(new_lines, line)
                i = i + 1
            end
        end

        vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)

        -- Format buffer with SuperHTML
        vim.lsp.buf.format({ async = false })

        -- Restore preserved code blocks by matching placeholders, not line numbers
        for idx, block in ipairs(code_blocks) do
            local placeholder = "@@CODEBLOCK_" .. idx .. "@@"
            local formatted = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            for j, l in ipairs(formatted) do
                local s, e = l:find(placeholder, 1, true)
                if s then
                    -- SuperHTML can join neighbours onto the placeholder line (e.g. "@@CODEBLOCK_1@@</body>"),
                    -- so only swap the placeholder itself and keep any tags around it.
                    local restored = vim.deepcopy(block)
                    local before, after = l:sub(1, s - 1), l:sub(e + 1)
                    if before:match("%S") then
                        restored[1] = before .. restored[1]
                    end
                    if after:match("%S") then
                        table.insert(restored, vim.trim(after))
                    end
                    vim.api.nvim_buf_set_lines(0, j - 1, j, false, restored)
                    break
                end
            end
        end
    end,
})

return {
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "superhtml" },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                -- Mason installs superhtml's binary onto $PATH, so no absolute path needed.
                superhtml = {
                    cmd = { "superhtml", "lsp" },
                    filetypes = { "html", "htmldjango" },
                },
                cssls = {
                    filetypes = { "css", "scss", "less" },
                    settings = {
                        css = {
                            validate = true,
                            lint = {
                                unknownAtRules = "ignore",
                            },
                        },
                        scss = {
                            validate = true,
                            lint = {
                                unknownAtRules = "ignore",
                            },
                        },
                        less = {
                            validate = true,
                            lint = {
                                unknownAtRules = "ignore",
                            },
                        },
                    },
                },
                ts_ls = {
                    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
                },
                emmet_ls = {
                    filetypes = { "html", "htmldjango", "css", "scss", "less", "javascriptreact", "typescriptreact" },
                },
            },
        },
    },
}
