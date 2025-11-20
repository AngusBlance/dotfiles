return {
  "NeogitOrg/neogit",
  dependancies = {
    "nvim-lua/plenary.nvim",
    "sindrets.diffview.nvim",
  },
  config = function()
    local neogit = require("neogit")
    neogit.setup({
      disable_hint = false,
      disable_context_highlighting = false,
      diable_sighns = false,
    })
  end,
  keys = {
    { "<leader>gn", "<cmd>Neogit<cr>", desc = "Open neogit" },
  },
}
