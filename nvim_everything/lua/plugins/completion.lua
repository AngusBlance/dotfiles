-- Enhanced completion setup for AI autocomplete integration
-- LazyVim uses blink.cmp by default, so we integrate with that
return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'supermaven', 'codeium' },
        providers = {
          supermaven = {
            name = "supermaven", 
            module = "blink.compat.source",
            score_offset = 100, -- Highest priority
            opts = {}
          },
          codeium = {
            name = "codeium",
            module = "blink.compat.source", 
            score_offset = 90, -- High priority
            opts = {}
          },
        },
      },
    },
    dependencies = {
      "saghen/blink.compat", -- Needed for non-blink sources
      "supermaven-inc/supermaven-nvim",
      "Exafunction/codeium.nvim",
    },
  },
}
