return {
  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      vim.keymap.set("n", "<leader>ha", function()
        harpoon:list():add()
      end, { desc = "Harpoon add file" })
      vim.keymap.set("n", "<leader>hh", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon quick menu" })

      for i = 1, 9 do
        vim.keymap.set("n", "<leader>" .. i, function()
          harpoon:list():select(i)
        end, { desc = "Harpoon buffer " .. i })
      end
    end,
  },
}
