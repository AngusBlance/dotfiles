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
        config = function(_, opts)
            require("illuminate").configure(opts)

            local DEBUG_LOG = "/Users/angusblance/code/opal/.cursor/debug-581a37.log"

            -- #region agent log
            local function debug_log(hypothesis_id, message, data)
                local f = io.open(DEBUG_LOG, "a")
                if not f then
                    return
                end
                f:write(vim.json.encode({
                    sessionId = "581a37",
                    runId = os.getenv("DEBUG_RUN_ID") or "post-fix-2",
                    hypothesisId = hypothesis_id,
                    location = "illuminate.lua",
                    message = message,
                    data = data,
                    timestamp = os.time() * 1000,
                }) .. "\n")
                f:close()
            end
            -- #endregion

            local function set_illuminate_hl()
                local bg = "#665c54"
                local fg = "#ebdbb2"
                vim.api.nvim_set_hl(0, "IlluminatedWordText", { fg = fg, bg = bg, bold = true, underline = false })
                vim.api.nvim_set_hl(0, "IlluminatedWordRead", { fg = fg, bg = bg, bold = true, underline = false })
                vim.api.nvim_set_hl(
                    0,
                    "IlluminatedWordWrite",
                    { fg = fg, bg = "#7c6f64", bold = true, underline = false }
                )

                -- #region agent log
                local hl = vim.api.nvim_get_hl(0, { name = "IlluminatedWordText", link = false })
                debug_log("H7", "illuminate_hl_applied", { bg = hl.bg, underline = hl.underline })
                -- #endregion
            end

            set_illuminate_hl()
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = set_illuminate_hl,
            })

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                callback = function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local ns = vim.api.nvim_get_namespaces()["illuminate.highlight"]
                    local count = 0
                    if ns then
                        count = #vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
                    end
                    -- #region agent log
                    debug_log("H8", "illuminate_extmarks", {
                        ft = vim.bo.filetype,
                        bufnr = bufnr,
                        extmark_count = count,
                    })
                    -- #endregion
                end,
            })
        end,
    },
}
