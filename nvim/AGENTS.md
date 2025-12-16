# NVIM Configuration Agent Guide

## Quick Debug Commands
```bash
# Health checks
nvim --headless +checkhealth +qa
:Lazy health
:LspInfo

# Colorscheme
:colorscheme                    # Check current theme
nvim --headless +"lua print('Colorscheme:', vim.g.colors_name)" +qa

# LSP status
:lua vim.lsp.get_active_clients({bufnr=0})  # Current buffer LSP
:lua print(#vim.lsp.get_active_clients())   # Total LSP clients
```

## Common Issues & Solutions

### 1. LSP Not Auto-Starting
**Problem:** "No active clients" in :LspInfo
**Solution:** Add `vim.lsp.enable('server1', 'server2')` after LSP configs
**File:** `lua/plugins/lspconfig.lua`

### 2. Colorscheme Not Automatic
**Problem:** Need to manually run `:colorscheme gruvbox`
**Solution:** Add `vim.cmd('colorscheme gruvbox')` to plugin config
**File:** `lua/plugins/gruvbox.lua`

### 3. Invalid LSP Arguments
**Problem:** LSP server exits with code 1
**Check:** `tail /home/angus/.local/state/nvim/lsp.log`
**Common fix:** Remove deprecated arguments like `--function-arg-placeholders`

## Configuration Patterns

### Plugin Structure
```lua
-- lua/plugins/example.lua
return {
  "plugin-name",
  config = function()
    require("plugin").setup({})
    -- Auto-load commands here
  end,
}
```

### Modern LSP Setup
```lua
-- Configure servers
vim.lsp.config("server_name", {
  cmd = { "server-executable" },
  filetypes = { "filetype1", "filetype2" },
  -- ... config
})

-- Enable auto-attachment (CRITICAL)
vim.lsp.enable("server_name", "other_server")
```

### Keybind Style
```lua
vim.keymap.set("n", "<leader>key", function_or_command, { desc = "Description" })
```

## Project Structure
```
lua/
├── config/
│   ├── autocomands.lua    # File events, formatting on save
│   ├── keymaps.lua        # Global keybindings
│   └── lazy.lua          # Plugin manager setup
└── plugins/
    ├── gruvbox.lua        # Colorscheme
    ├── lspconfig.lua      # LSP server configs
    ├── telescope.lua      # File finder
    ├── treesitter.lua     # Syntax highlighting
    └── cmp.lua           # Autocompletion
```

## Dependencies Required
- `ripgrep` (rg) for telescope file search
- `clangd` for C++ LSP (via mason)
- `lua-language-server` for Lua LSP (via mason)

## Testing Process Used
1. Start with `:checkhealth` to identify missing tools
2. Install missing dependencies (ripgrep, luarocks)
3. Test colorscheme loading with headless nvim
4. Fix LSP configuration issues by checking logs
5. Verify auto-attachment with file type tests
6. Confirm both C++ and Lua LSP work independently

## Key Fixes Applied
- Added `vim.cmd('colorscheme gruvbox')` for automatic theme loading
- Added `vim.lsp.enable('clangd', 'lua_ls')` for LSP auto-attachment
- Removed invalid `--function-arg-placeholders` from clangd config
- Used modern `vim.lsp.config()` API instead of deprecated lspconfig.setup()