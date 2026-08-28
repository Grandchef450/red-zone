function _L(key, ...)
    local locale = Config.Locale or 'en'
    local entry = Locales[locale] and Locales[locale][key]

    if not entry then
        return key
    end

    if select("#", ...) > 0 then
        return string.format(entry, ...)
    end

    return entry
end
