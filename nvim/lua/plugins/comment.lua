return {
  "numToStr/Comment.nvim",
  config = function()
    require("Comment").setup()

    local api = require("Comment.api")
    local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

    -- Use ? in visual mode to toggle comments on the selection
    vim.keymap.set("x", "?", function()
      vim.api.nvim_feedkeys(esc, "nx", false)
      api.toggle.linewise(vim.fn.visualmode())
    end, { desc = "Toggle comment for selection" })
  end,
}
