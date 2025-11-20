return {
  {
    "hat0uma/csvview.nvim",
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    -- auto-load on CSV/TSV open
    ft = { "csv", "tsv" },
    -- minimal setup; tweak as you like
    opts = {
      parser = { comments = { "#", "//" } }, -- treat these as comment lines
      view = { display_mode = "border" }, -- or "highlight"
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<CR>", mode = { "n", "v" } },
        jump_prev_row = { "<S-CR>", mode = { "n", "v" } },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>CsvViewToggle<cr>", desc = "CSV: Toggle view" },
      { "<leader>cV", "<cmd>CsvViewToggle display_mode=highlight<cr>", desc = "CSV: Toggle (highlight)" },
    },
    init = function()
      -- Auto-enable when opening CSV/TSV
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function()
          vim.cmd("silent! CsvViewEnable")
        end,
      })
    end,
  },
}
