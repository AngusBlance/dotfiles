-- Inline images (snacks.image) in markdown, and image files opened as buffers
-- (e.g. `l` on a .png in mini.files). Needs a Kitty-graphics terminal
-- (Ghostty/Kitty/WezTerm), tmux `allow-passthrough on`, and ImageMagick for
-- anything that isn't a PNG. Only the image module is enabled.

-- Obsidian finds `![[name.png]]` anywhere in the vault, not just next to the
-- note. If the image isn't beside the note, look from the vault root, then
-- search the vault for the file name. Returning nil keeps snacks' own lookup.
local function resolve_obsidian(file, src)
    if src:find("^%w%w+://") or src:sub(1, 1) == "/" then
        return nil
    end
    if vim.uv.fs_stat(vim.fs.joinpath(vim.fs.dirname(file), src)) then
        return nil
    end
    local vault = vim.fs.root(file, ".obsidian")
    if not vault then
        return nil
    end
    local from_root = vim.fs.joinpath(vault, src)
    if vim.uv.fs_stat(from_root) then
        return from_root
    end
    local name = vim.fs.basename(src)
    return vim.fs.find(function(n, path)
        return n == name and not path:find("/%.git")
    end, { path = vault, type = "file", limit = 1 })[1]
end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        image = {
            enabled = true,
            resolve = resolve_obsidian,
        },
    },
}
