-- Global keymaps; required from init.lua before lazy.nvim loads plugins.
vim.keymap.set("n", "<leader>y", function()
    vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Yank full file path to clipboard" })
