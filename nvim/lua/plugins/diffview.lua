return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            keymaps = {
                view = { -- active diff buffers
                    ["q"] = "<cmd>DiffviewClose<CR>",
                    ["<leader>r"] = "<cmd>DiffviewRefresh<CR>", -- refresh the current Diffview
                },
                file_panel = {
                    ["q"] = "<cmd>DiffviewClose<CR>",
                    ["<leader>r"] = "<cmd>DiffviewRefresh<CR>",
                },
                file_history_panel = {
                    ["q"] = "<cmd>DiffviewClose<CR>",
                    ["<leader>r"] = "<cmd>DiffviewRefresh<CR>",
                },
            },
        },
        keys = {
            {
                "dv",
                function()
                    local lib = require("diffview.lib")
                    if lib.get_current_view() then
                        vim.cmd("DiffviewClose")
                        return
                    end
                    -- gf leaves the Diffview tab open, so jump back to it instead of opening another.
                    local view = lib.views[1]
                    if view and vim.api.nvim_tabpage_is_valid(view.tabpage) then
                        vim.api.nvim_set_current_tabpage(view.tabpage)
                    else
                        vim.cmd("DiffviewOpen")
                    end
                end,
                desc = "Toggle Diffview",
            },
            { "dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
        },
    },
}
