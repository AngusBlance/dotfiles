-- Undo history visualizer (mbbill/undotree)
return {
  {
    "mbbill/undotree",
    config = function()
      -- use :UndotreeToggle per plugin README
      vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { desc = "Toggle UndoTree" })
    end,
  },
}
