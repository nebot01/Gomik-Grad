-- "addons\\homigrad-core\\lua\\homigrad\\sh_urlmaterial.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg = hg or {}
hg.URLMaterialCache = hg.URLMaterialCache or {}

if CLIENT then
    local function NormalizeUrl(url)
        if not url or url == "" then return "" end
        if string.sub(url, 1, 7) == "http://" or string.sub(url, 1, 8) == "https://" then
            return url
        end
        return ""
    end

    function hg.GetURLMaterial(url, folder, defaultExt)
        url = NormalizeUrl(url)
        if url == "" then return nil end
        folder = folder or "gomigrad_url"
        if not file.IsDir(folder, "DATA") then
            file.CreateDir(folder)
        end
        local ext = string.match(url, "%.([%a%d]+)$") or defaultExt or "png"
        if #ext > 4 then ext = defaultExt or "png" end
        local hash = util.CRC(url)
        local filename = folder .. "/" .. hash .. "." .. ext
        local downloadingKey = filename .. ":downloading"
        if not file.Exists(filename, "DATA") and not hg.URLMaterialCache[downloadingKey] then
            hg.URLMaterialCache[downloadingKey] = true
            http.Fetch(url, function(body)
                file.Write(filename, body)
                hg.URLMaterialCache[downloadingKey] = nil
            end, function()
                hg.URLMaterialCache[downloadingKey] = nil
            end)
        end
        local matKey = url .. ":" .. filename
        if not hg.URLMaterialCache[matKey] and file.Exists(filename, "DATA") then
            local mat = Material("data/" .. filename, "smooth")
            if mat and not mat:IsError() then
                hg.URLMaterialCache[matKey] = mat
            end
        end
        return hg.URLMaterialCache[matKey]
    end
end
