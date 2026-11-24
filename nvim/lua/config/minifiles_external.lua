local M = {}

local external_extensions = {
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    webp = true,
    bmp = true,
    tif = true,
    tiff = true,
    heic = true,
    pdf = true,
}

function M.should_open_externally(entry)
    if not entry or entry.fs_type ~= "file" or type(entry.name) ~= "string" then
        return false
    end

    local extension = entry.name:match("%.([^.]+)$")
    return extension ~= nil and external_extensions[extension:lower()] == true
end

return M
