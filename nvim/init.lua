vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.clipboard = "unnamedplus"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.autocomands")
require("config.keymaps")
require("config.lazy")
