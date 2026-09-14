local opts = { noremap = true, silent = true }

-- Go between buffers in terminal normal mode
vim.keymap.set({ "n", "t" }, "<S-h>", "<Cmd>bprevious<CR>", opts)
vim.keymap.set({ "n", "t" }, "<S-l>", "<Cmd>bnext<CR>", opts)

-- quick save
vim.keymap.set("n", "<leader>w", ":w<CR>", opts)

-- delete current buffer
vim.keymap.set("n", "<leader>bd", ":bd<CR>", opts)

-- Split navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Terminal mode mapping: Esc to Normal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)
