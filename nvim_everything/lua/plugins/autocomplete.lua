return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
        ignore_filetypes = {},
        color = {
          suggestion_color = "#ffffff",
          cterm = 244,
        },
        log_level = "info",
        disable_inline_completion = false,
        disable_keymaps = false,
        ignore_filetypes = { "cpp" },
      })
    end,
  },
  {
    "Exafunction/codeium.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    event = "BufEnter",
    config = function()
      local ok, _ = pcall(require, "cmp")
      if not ok then
        vim.notify("nvim-cmp not loaded, skipping Codeium setup", vim.log.levels.WARN)
        return
      end
      require("codeium").setup({
        enable_chat = true,
      })
    end,
  },
}



