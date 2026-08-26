local function check()
    if FrameworkSelected == 'ESX' then
        local filePath = "/server/functions.lua"
        local fileContent = LoadResourceFile("es_extended", filePath)
    
        if not fileContent then
            return {}
        end
    
        local identifiers = {}
    
        for match in fileContent:gmatch('GetPlayerIdentifierByType%s*%b()%s*') do
            local arg = match:match('%(%s*[^,]+%s*,%s*"([^"]+)"%s*%)')
            if arg then
                table.insert(identifiers, arg)
            end
        end
        return identifiers and identifiers[1] and (identifiers[1] == Config.Characters.IdentifierType)
    end
end
