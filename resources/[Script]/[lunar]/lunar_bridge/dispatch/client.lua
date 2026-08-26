RegisterNetEvent('lunar_bridge:dispatch:call')
AddEventHandler('lunar_bridge:dispatch:call', function(coords, data)
    if Utils.isPolice() then
        lib.notify({
            title = data.Code,
            description = data.Message,
            position = 'top-right',
            duration = 10000,
            style = {
                width = 330,
                backgroundColor = '#0d3482',
                color = '#FFFFFF',
                padding = 20,
            },
            icon = 'shield-halved',
        })
        local blip = Utils.createBlip(coords, {
            Name = data.Title,
            Sprite = data.Sprite or 161, 
            Size = 2.0, 
            Color = 0
        })
        Citizen.SetTimeout(30000, function()
            blip.remove()
        end)
    end
end)

-- Function to get street name at coordinates
function GetStreetName(coords)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    -- cross street if available
    local crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z, 0, 0)
    if crossingHash ~= streetHash and crossingHash ~= 0 then
        local crossingName = GetStreetNameFromHashKey(crossingHash)
        return streetName .. " & " .. crossingName
    end
    
    return streetName
end

-- Event to get street name from client and send it back to server
RegisterNetEvent('lunar_bridge:requestStreetName')
AddEventHandler('lunar_bridge:requestStreetName', function(coords, callId)
    local streetName = GetStreetName(coords)
    TriggerServerEvent('lunar_bridge:returnStreetName', streetName, callId)
end)