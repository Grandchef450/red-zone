local function check()
    local configPathOptions = {
        "/config.lua",
        "/shared/config/main.lua"
    }

    local wasChunkedChecked = false
    local isConfigMulticharEnabled = false

    for _, path in ipairs(configPathOptions) do
        local file = LoadResourceFile('es_extended', path)
        if file then
            wasChunkedChecked = true
            isConfigMulticharEnabled = string.find(file, 'Config.Multichar = true') or string.find(file, 'Config.Multichar=true') or string.find(file, 'Config.Multichar =true') or string.find(file, 'Config.Multichar= true')
            break
        end
    end

    return isConfigMulticharEnabled
end

return check