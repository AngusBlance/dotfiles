-- Mini tabline + statusline with git info
return {
  {
    "echasnovski/mini.nvim",
    enabled = true,
    config = function()
      require("mini.git").setup({})
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
              { hl = mode_hl,                  strings = { mode } },
              { hl = "MiniStatuslineDevinfo",  strings = { git } },
              { hl = "MiniStatuslineFilename", strings = { filename } },
              { hl = "MiniStatuslineLocation", strings = { location } },
            })
          end,
        },
      })
    end,
  },
}
