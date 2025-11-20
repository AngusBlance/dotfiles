-- Auto-format on save for all file types
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})

local opts = { noremap = true, silent = true }

-- File explorer
vim.keymap.set("n", "<leader>e", ":Ex<CR>", opts)

-- Quick save
vim.keymap.set("n", "<leader>w", ":w<CR>", opts)

-- Split navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)