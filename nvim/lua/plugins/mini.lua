-- Mini tabline + statusline with git info
return {
    {
        "nvim-mini/mini.nvim",
        enabled = true,
        config = function()
            require("mini.git").setup({})
            require("mini.files").setup({})

            -- Open PDFs in Sioyek instead of as a buffer; everything else unchanged.
            local function go_in_or_open_pdf(close_on_file)
                return function()
                    local entry = MiniFiles.get_fs_entry()
                    if entry and entry.fs_type == "file" and entry.path:lower():match("%.pdf$") then
                        if vim.fn.executable("sioyek") == 1 then
                            vim.system({ "sioyek", entry.path }, { detach = true })
                            if close_on_file then
                                MiniFiles.close()
                            end
                        else
                            vim.notify("sioyek not found, run the dotfiles install.sh", vim.log.levels.WARN)
                        end
                        return
                    end
                    for _ = 1, vim.v.count1 do
                        MiniFiles.go_in({ close_on_file = close_on_file })
                    end
                end
            end
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                callback = function(args)
                    local buf = args.data.buf_id
                    vim.keymap.set("n", "l", go_in_or_open_pdf(false), { buffer = buf, desc = "Go in / open PDF" })
                    vim.keymap.set("n", "L", go_in_or_open_pdf(true), { buffer = buf, desc = "Go in plus / open PDF" })
                end,
            })
            -- mini.tabline setup per mini-tabline.txt:42-107

            require("mini.tabline").setup({})
            -- Highlight groups from mini-tabline.txt:62-78
            vim.api.nvim_set_hl(0, "MiniTablineCurrent", { link = "TabLineSel" })
            vim.api.nvim_set_hl(0, "MiniTablineVisible", { link = "TabLine" })
            vim.api.nvim_set_hl(0, "MiniTablineHidden", { link = "TabLineFill" })
            vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", { link = "DiffText" })
            vim.api.nvim_set_hl(0, "MiniTablineModifiedVisible", { link = "DiffChange" })
            vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { link = "DiffDelete" })

            local statusline = require("mini.statusline")
            statusline.setup({
                use_icons = true,
                content = {
                    active = function()
                        local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
                        local git = statusline.section_git({ trunc_width = 75 })
                        local filename = statusline.section_filename({ trunc_width = 140 })
                        local location = statusline.section_location({ trunc_width = 75 })

                        return statusline.combine_groups({
                            { hl = mode_hl, strings = { mode } },
                            { hl = "MiniStatuslineDevinfo", strings = { git } },
                            { hl = "MiniStatuslineFilename", strings = { filename } },
                            { hl = "MiniStatuslineLocation", strings = { location } },
                        })
                    end,
                },
            })
        end,
        keys = {
            {
                "<leader>e",
                function()
                    require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
                end,
                desc = "Open mini.files (current file dir)",
            },
        },
    },
}
