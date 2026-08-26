RegisterNetEvent('ZSX_Multicharacter:Listener:WelcomeScreenStateChanged')
AddEventHandler('ZSX_Multicharacter:Listener:WelcomeScreenStateChanged', function(state)
    if state then
        --Executed when welcome screen changes state to true
    elseif not state then
        --Executed when welcome screen changes state to false
    end
    --@param state [boolean]
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:MainInitialized')
AddEventHandler('ZSX_Multicharacter:Listener:MainInitialized', function()
    --Execute code whenever it's first initialization when NetworkIsPlayerActive() native returns true
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:MainFinishedWork')
AddEventHandler('ZSX_Multicharacter:Listener:MainFinishedWork', function()
    --Execute code whenever it's first initialization when NetworkIsPlayerActive() native returns true
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:MulticharacterInitialized')
AddEventHandler('ZSX_Multicharacter:Listener:MulticharacterInitialized', function(isLogout)
    --Executed code when Multicharacter content switches on
    --@param isLogout [boolean]
    --Specifice if the Multicharacter was initiliazed via logout
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:MulticharacterFinished')
AddEventHandler('ZSX_Multicharacter:Listener:MulticharacterFinished', function()
    --Execute code when Multicharacter content switches off
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:SwappedCharacter')
AddEventHandler('ZSX_Multicharacter:Listener:SwappedCharacter', function(characterData, characterId)
    --Execute code when player will swap the character
    --@param characterID [int]
    --@param characterData [object]
    --characterId is order from the gathered data from sql. First id for the specific WHERE selector to the Last id.
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:SelectedCharacter')
AddEventHandler('ZSX_Multicharacter:Listener:SelectedCharacter', function(characterId)
    --Execute code when player will select his character
    --@param characterID [int]
    --characterId is order from the gathered data from sql. First id for the specific WHERE selector to the Last id.
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
    if Config.BringMinimap then
        DisplayRadar(true)
    end
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:CharacterCreated')
AddEventHandler('ZSX_Multicharacter:Listener:CharacterCreated', function(characterData)
    --Execute code when user character is created
    --@param characterData [OBJECT]
    --Contains firstname, lastname, dateofbirth, height, gender
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
    if Config.BringMinimap then
        DisplayRadar(true)
    end
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:CharacterRemoved')
AddEventHandler('ZSX_Multicharacter:Listener:CharacterRemoved', function(characterId, characterIdentifier, haveOtherCharacters)
    --Execute code when user character is created
    --@param characterId [INT]
    --@param characterId [STRING]
    --@param haveOtherCharacters [BOOLEAN]
    --characterId is variable containg identifier (number) of the player | cid = QB | char<characterId>:<identifier> = ESX
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:LocationsInitializing')
AddEventHandler('ZSX_Multicharacter:Listener:LocationsInitializing', function()
    --Execute code when user will click on Locations button
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:LocationsDisabled')
AddEventHandler('ZSX_Multicharacter:Listener:LocationsDisabled', function()
    --Execute code when user will click use Escape to disable Locations
end)

RegisterNetEvent('ZSX_Multicharacter:Listener:ChangedLocation')
AddEventHandler('ZSX_Multicharacter:Listener:ChangedLocation', function(locationCoords)
    --Execute the code when user will click enter on specific location
    --@param locationCoords [vector3]
    --Returns location coords for user selected location
end)

RegisterNetEvent('ZSX_Multicharacter:CreateQBInstance')
AddEventHandler('ZSX_Multicharacter:CreateQBInstance', function(data)
    local Player = QBCore.Functions.GetPlayerData()
    if GetResourceState('qs-housing') == 'started' then
        local insidehouse = Player.metadata['inside']
        if insidehouse.house ~= nil then
            local houseid = insidehouse.house
            TriggerEvent('qb-houses:client:LastLocationHouse', houseid)
        end
    end

    TriggerServerEvent('qb-multicharacter:server:createCharacter', data)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

GetConfigValue = function(key)
    if not key then return false end
    return Config[key]
end

GetUserStorage = function()
    return Storage.Data
end

exports('GetConfigValue', GetConfigValue)
exports('GetUserStorage', GetUserStorage)
exports('CanSwapCoords', World.PreventSwapCoords)
exports('Logout', Logout)
exports('SetLocationsDisabled', Locations.SetLocationsDisabled)

RegisterNetEvent('ZSX_Multicharacter:LogoutPlayer')
AddEventHandler('ZSX_Multicharacter:LogoutPlayer', function()
    Logout()
end)

RegisterNetEvent('ZSX_UIV2:Storage:OnColorUpdate')
AddEventHandler('ZSX_UIV2:Storage:OnColorUpdate', function(color)
    NUI.ApplyColor(color)
end)

--[[
    DOCS: https://zsx-development.gitbook.io/docs/multicharacter/baseevents
]]