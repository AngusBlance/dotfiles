# NVIM Configuration Agent Guide

Neovim 0.12, lazy.nvim, Catppuccin Latte. `~/.config/nvim` is a symlink to this folder.

## Headless Debug Commands
Plain `nvim --headless +checkhealth +qa` prints nothing useful: write buffers/messages to a file.
```bash
# Startup errors + messages (lazy reports config errors via notifications, so wait a moment)
nvim --headless -c "lua vim.defer_fn(function() vim.fn.writefile(vim.split(vim.v.errmsg .. '\n' .. vim.api.nvim_exec2('messages', {output=true}).output, '\n'), '/tmp/nvim-msgs.txt'); vim.cmd('qa!') end, 5000)"

# Full checkhealth report to a file
nvim --headless -c "lua vim.defer_fn(function() vim.cmd('checkhealth'); vim.defer_fn(function() vim.cmd('w! /tmp/health.txt | qa!') end, 45000) end, 3000)"

# Startup profile
nvim --headless --startuptime /tmp/startup.log +qa

# Plugins (bang = wait until done)
nvim --headless "+Lazy! check" +qa     # fetch updates, doesn't install
nvim --headless "+Lazy! restore" +qa   # checkout lazy-lock.json commits
nvim --headless "+Lazy! clean" +qa     # remove plugins no longer in the spec
```

Inside Nvim: `:checkhealth vim.lsp`, `:Lazy health`, `:ConformInfo`, `:Mason`,
`:lua print(vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))))`.
LSP log: `~/.local/state/nvim/lsp.log`.

## Common Issues & Solutions

### 1. `attempt to call field 'install'` from treesitter.lua
**Cause:** the nvim-treesitter checkout is on `master` while the spec wants `main` (lazy doesn't switch
branches of an existing clone). Same can happen to telescope (`0.1.x` vs `master`).
**Fix:** `nvim --headless "+Lazy! restore nvim-treesitter telescope.nvim" +qa`

### 2. LSP not auto-starting
Servers go in `opts.servers` of a `neovim/nvim-lspconfig` spec (lspconfig.lua, luaLsp.lua, webdev.lua);
lspconfig.lua calls `vim.lsp.config(name, ...)` then `vim.lsp.enable({ ...names })`.
Note `vim.lsp.enable` takes a name or a list; a second argument is the enable boolean.

### 3. Format on save not happening
conform's `format_on_save` is defined once in luaLsp.lua. Other files only add `formatters_by_ft`;
a table `format_on_save` elsewhere would replace the function when lazy merges opts.

## Configuration Patterns

### Plugin Structure
```lua
-- lua/plugins/example.lua
return {
    "owner/plugin-name",
    opts = {}, -- lazy calls require("plugin-name").setup(opts)
}
```

### Keybind Style
```lua
vim.keymap.set("n", "<leader>key", function_or_command, { desc = "Description" })
```
LSP-server-specific keys go in an `LspAttach` autocmd with `buffer = args.buf` (see clangd in lspconfig.lua).

## Project Structure
```
init.lua                  # options, then config.*
lua/config/
├── autocomands.lua       # buffer/split/terminal keymaps
├── keymaps.lua           # global keymaps
└── lazy.lua              # lazy.nvim bootstrap
lua/plugins/
├── cappuccine-latte.lua  # colorscheme
├── lspconfig.lua         # diagnostics, mason-lspconfig, clangd, vim.lsp.enable
├── luaLsp.lua            # mason opts, lua_ls, stylua/selene, conform format_on_save
├── python.lua / webdev.lua  # per-language tools and servers
├── mason.lua             # mason + mason-tool-installer (ensure_installed merged across files)
├── treesitter.lua        # nvim-treesitter main branch, parsers list
├── cmp.lua, telescope.lua, mini.lua, harpoon.lua, diffview.lua, neogit.lua, ...
```

## Dependencies Required
- `ripgrep` (rg) for telescope live_grep
- `make` + C compiler for telescope-fzf-native and LuaSnip jsregexp
- `tree-sitter-cli` (installed via Mason) for nvim-treesitter main
- LSP servers/formatters are installed by Mason
