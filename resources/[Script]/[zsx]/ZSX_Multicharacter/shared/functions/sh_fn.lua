debugPrint = function(text)
    if not Config.Debug then return end
    print('[^1MULTICHARACTER^7] '..text)
end

debugPrint_Forced = function(text)
    print('[^1MULTICHARACTER^7] [^2INTEGRATION^7] '..text)
end

getRandomKey = function(tbl)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys[math.random(1, #keys)]
end