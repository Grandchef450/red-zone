Dispatch = {}

-- Table to store pending callbacks waiting for street names
local pendingCallbacks = {}

-- Event handler to receive street names from clients
RegisterNetEvent('lunar_bridge:returnStreetName')
AddEventHandler('lunar_bridge:returnStreetName', function(streetName, callId)
    if pendingCallbacks[callId] then
        local callback = pendingCallbacks[callId]
        
        callback(streetName or "Unknown Location") -- Fallback
        
        pendingCallbacks[callId] = nil
    end
end)

-- Auto-detect dispatch system
local function detectDispatchType()
    local dispatchTypes = {
        { resource = 'cd_dispatch',    type = 'cd_dispatch' },
        { resource = 'qs-dispatch',    type = 'qs-dispatch' },
        { resource = 'ps-dispatch',    type = 'ps-dispatch' },
        { resource = 'rcore_dispatch', type = 'rcore_dispatch' },
        { resource = 'lb-tablet',      type = 'lb-tablet' },
        { resource = 'wasabi_mdt',     type = 'wasabi-mdt' },
        { resource = 'l2s-dispatch',   type = 'l2s-dispatch' },
        { resource = 'redutzu-mdt',    type = 'redutzu-mdt' },
        { resource = 'dusa_dispatch',  type = 'dusa_dispatch' },
        { resource = 'cd_dispatch3d',  type = 'cd_dispatch3d' },
    }

    for _, dispatch in ipairs(dispatchTypes) do
        if GetResourceState(dispatch.resource) == 'started' then
            print(('[lunar_bridge] Auto-detected dispatch system: %s'):format(dispatch.type))
            return dispatch.type
        end
    end

    print('No compatible dispatch system found in lunar_bridge/dispatch/server.lua, using default "normal" mode')
    return 'normal'
end

-- Initialize dispatch type
if Config.Dispatch.Type == 'auto' then
    Config.Dispatch.Type = detectDispatchType()
end

--This function dispatches all the calls
function Dispatch.call(coords, data)
    if Config.Dispatch.Type == 'normal' then
        TriggerClientEvent('lunar_bridge:dispatch:call', -1, coords, data)
    elseif Config.Dispatch.Type == 'cd_dispatch' then
        local title = string.format('%s - %s', data.Code, data.Title)

        TriggerClientEvent('cd_dispatch:AddNotification', -1, {
            job_table = Config.Dispatch.Jobs,
            coords = coords,
            title = title,
            message = data.Message,
            flash = 0,
            unique_id = tostring(math.random(0000000, 9999999)),
            sound = 1,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                flashes = false,
                text = title,
                time = (5 * 60 * 1000),
                radius = 0,
                sound = 1,
            }
        })
    elseif Config.Dispatch.Type == 'cd_dispatch3d' then
        local title = string.format('%s - %s', data.Code, data.Title)

        TriggerClientEvent('cd_dispatch3d:AddNotification', -1, {
            job_table = Config.Dispatch.Jobs,
            coords = coords,
            title = title,
            message = data.Message,
            flash = 0,
            unique_id = tostring(math.random(0000000, 9999999)),
            sound = 1,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                flashes = false,
                text = title,
                time = (5 * 60 * 1000),
                radius = 0,
                sound = 1,
            }
        })
    elseif Config.Dispatch.Type == 'qs-dispatch' then
        local title = string.format('%s - %s', data.Code, data.Title)

        TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = Config.Dispatch.Jobs,
            callLocation = coords,
            callCode = { code = data.Code, snippet = data.Title },
            message = data.Message,
            flashes = false,
            image = nil,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                flashes = true,
                text = title,
                time = (20 * 1000),
            }
        })
    elseif Config.Dispatch.Type == 'ps-dispatch' then
        TriggerEvent('ps-dispatch:server:notify', {
            message = data.Message,
            codeName = data.Title,
            code = data.Code,
            coords = coords,
            priority = 2,
            jobs = { 'leo' },
            alert = {
                displayCode = data.Code,
                description = data.Message,
                coords = coords,
                radius = 1.2,
                recipientList = Config.Dispatch.Jobs,
                sprite = 431,
                color = 3,
                scale = 1.2,
                length = 20,
                sound = "Lose_1st",
                flash = true
            }
        })
    elseif Config.Dispatch.Type == 'rcore_dispatch' then
        local title = string.format('%s - %s', data.Code, data.Title)
        local alertData = {
            code = title,
            default_priority = 'high',
            coords = coords,
            job = Config.Dispatch.Jobs,
            text = data.Message,
            type = 'alerts',
            blip_time = 5,
            blip = {
                sprite = 431,
                colour = 3,
                scale = 1.2,
                text = data.Title,
                flashes = true,
                radius = 0,
            }
        }
        TriggerEvent('rcore_dispatch:server:sendAlert', alertData)
    elseif Config.Dispatch.Type == 'lb-tablet' then
        local dispatch = {
            priority = 'high',
            code = data.Code,
            title = data.Title,
            description = data.Message,
            location = {
                label = data.Title,
                coords = { x = coords.x, y = coords.y }
            },
            time = 300, -- 5 minutes
            job = 'police',
            blip = {
                sprite = 431,
                color = 3,
                size = 1.2,
                shortRange = false,
                label = data.Title
            }
        }

        local dispatchId = exports["lb-tablet"]:AddDispatch(dispatch)
    elseif Config.Dispatch.Type == 'wasabi-mdt' then
        local mdtData = {
            type = 'robbery',
            title = data.Title,
            description = data.Message,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            location = '',
            priority = 5
        }
        TriggerEvent('wasabi_mdt:createExternalDispatch', mdtData)
    elseif Config.Dispatch.Type == 'l2s-dispatch' then
        Dispatch.getStreetName(coords, function(streetName)
            TriggerEvent('l2s-dispatch:server:AddNotification', {
                departments = Config.Dispatch.Jobs,
                title = data.Title,
                message = data.Message,
                coords = vec2(coords.x, coords.y),
                priority = 1,
                sound = 1,
                reply = false,
                anonymous = false,
                street = streetName,
                blip = {
                    sprite = 52,
                    colour = 1,
                    scale = 1.0,
                    text = data.Title,
                },
                info = {
                    { icon = 'video', text = 'Automated call' },
                }
            })
        end)
    elseif Config.Dispatch.Type == 'redutzu-mdt' then
        -- Get street name and send dispatch when received
        Dispatch.getStreetName(coords, function(streetName)
            TriggerEvent('redutzu-mdt:server:addDispatchToMDT', {
                code = data.Code,
                title = data.Title,
                street = streetName,
                duration = 60000, -- 1 minute by default
                coords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                }
            })
        end)
    elseif Config.Dispatch.Type == 'dusa_dispatch' then
        local dispatchData = {
            message = data.Message,
            codeName = 'custom',
            code = data.Code,
            coords = coords,
            priority = 2,
            alert = { 
                displayCode = data.Code,
                description = data.Message,
                coords = coords,
                radius = 1.2,
                sprite = 431,
                color = 3,
                scale = 1.2,
                length = 20,
                sound = "Lose_1st",
                flash = true
            },
            recipientJobs = { 'police' },
        }

        TriggerClientEvent('dusa_dispatch:sendCustomDispatch', -1, dispatchData)
    else
        error(('%s is not implemented, you can implement it in lunar_bridge/dispatch/server.lua'):format(Config.Dispatch
            .Type))
    end
end

-- Call Dispatch.getStreetName(coords) to return the players closest street name
function Dispatch.getStreetName(coords, callback)
    local callId = tostring(math.random(0000000, 9999999))
    
    if callback then
        pendingCallbacks[callId] = callback
    end
    
    TriggerClientEvent('lunar_bridge:requestStreetName', -1, coords, callId)
end