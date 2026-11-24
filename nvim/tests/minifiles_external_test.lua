package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local routing = require("config.minifiles_external")

local whitelisted = {
    "image.png", "image.jpg", "image.jpeg", "image.gif", "image.webp",
    "image.bmp", "image.tif", "image.tiff", "image.heic", "document.pdf",
    "UPPER.JPEG", "scan.PDF",
}

for _, name in ipairs(whitelisted) do
    assert(routing.should_open_externally({ fs_type = "file", name = name }), name .. " should open externally")
end

local fallback_entries = {
    nil,
    { fs_type = "directory", name = "photo.png" },
    { fs_type = "file", name = "notes.txt" },
    { fs_type = "file", name = "archive.tar.gz" },
    { fs_type = "file", name = "no-extension" },
    { fs_type = "file", name = ".pdf" },
}

for _, entry in ipairs(fallback_entries) do
    assert(not routing.should_open_externally(entry), "entry should use MiniFiles go_in fallback")
end

print("MiniFiles routing: 12 external cases and 6 go_in fallback cases passed")
