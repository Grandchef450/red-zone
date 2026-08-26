Framework = {}
Framework.RegisterServerCallback = function(callbackName, cbFunc)
    if not FrameworkSelected then
        while not FrameworkSelected do
            Wait(0)
        end
    end
    if ESX and FrameworkSelected == 'ESX' then
        ESX.RegisterServerCallback(callbackName, cbFunc)
    elseif QBCore and FrameworkSelected == 'QBCore' then
        QBCore.Functions.CreateCallback(callbackName, cbFunc)
    else
        --CUSTOM FRAMEWORK REGISTER CALLBACK
    end
end

Citizen.CreateThread(function()
    if Config.IssueHelper then
        local haveESX = ESX ~= nil
        local haveQB = QBCore ~= nil
        debugPrint('Issue Helper is ^2"ON"')
        debugPrint('Send that data to discord in new ticket.')
        debugPrint('=================DATA OUTPUT=================')
        debugPrint('Current framework: ^2'.. FrameworkSelected)
        debugPrint('Framework functions type: ')
        if haveESX then
            debugPrint(' - Return: '.. tostring(type(ESX) == 'table' and '^2OK'))
        elseif haveQB then
            debugPrint(' - Return: '.. tostring(type(QBCore) == 'table' and '^2OK'))
        end
        debugPrint('Gathering config file [/]')
        debugPrint('^3[CONFIG] [CHARACTERS] ^7Free Characters Amount: ^2'.. Config.Characters.Free)
        debugPrint('^3[CONFIG] [CHARACTERS] ^7Characters Identifier selected: ^2'.. Config.Characters.IdentifierType)
        debugPrint('^3[CONFIG] [LOGOUT] ^7Command Acitve: ^2'.. tostring(Config.Commands['logout'].use))
        debugPrint('^3[CONFIG] [LOGOUT] ^7Command Name: ^2'.. Config.Commands['logout'].commandName)
        debugPrint('^3[CONFIG] [BUCKETS] ^7Multicharacter Bucket ID: ^2'.. Config.Buckets.MulticharacterID)
        debugPrint('^3[CONFIG] [BUCKETS] ^7Use population on multicharacter bucket: ^2'.. tostring(Config.Buckets.PopulationEnabled))
        debugPrint('^3[CONFIG] [BUCKETS] ^7Default bucket that players will be redirected: ^2'.. Config.Buckets.DefaultId)
        debugPrint('^3[CONFIG] [OTHER] ^7Can swap location on logout: ^2'.. tostring(Config.CanSwapLocationOnLogout))
        print('^7')
    end
end)

exports('isInMulticharacter', isInMulticharacter)

function isInMulticharacter(src)
    return Player(src).state['isInMulticharacter']
end

debugPrint('Done loading framework events')