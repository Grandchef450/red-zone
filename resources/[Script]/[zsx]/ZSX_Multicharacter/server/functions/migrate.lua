Migrate = {}
Migrate.QSHousing = function(charData)
    if not charData then return end
    if FrameworkSelected == 'ESX' then
        local response = MySQL.query.await('SELECT `inside` FROM `users` WHERE `identifier` = ?', {Config.Prefix..''..charData.id..':'..charData.identifier})
        if response and response[1] and response[1].inside then
            local house = MySQL.prepare.await('SELECT `coords` FROM `houselocations` WHERE `name` = ?', {response[1].inside})
            if house then
                local coords = json.decode(house)
                MySQL.update.await('UPDATE `users` SET `position` = ? WHERE identifier = ?', {
                    json.encode(coords.enter),
                    Config.Prefix..''..charData.id..':'..charData.identifier
                })
            end
        end
    elseif FrameworkSelected == 'QBCore' then

    end
end

AddEventHandler('onPlayerDropped', function()
    if not Characters.ActiveUsers[tostring(source)] then return end
    if GetResourceState('qs-housing') == 'started' then
        Migrate.QSHousing(Characters.ActiveUsers[tostring(source)])
    end
    Wait(100)
    Characters.ActiveUsers[tostring(source)] = nil
end)