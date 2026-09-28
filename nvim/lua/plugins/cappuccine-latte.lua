return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        vim.o.background = "light"
        require("catppuccin").setup({ flavour = "latte" })
        vim.cmd("colorscheme catppuccin")
    end,
}
