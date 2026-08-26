-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

local bagEquipped, bagObj
local hash = `p_michael_backpack_s`
local ox_inventory = exports.ox_inventory
local ped = cache.ped
local justConnect = true



local function PutOnBag()
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(ped,0.0,3.0,0.5))
    lib.requestModel(hash, 100)
    bagObj = CreateObjectNoOffset(hash, x, y, z, true, false)
    AttachEntityToEntity(bagObj, ped, GetPedBoneIndex(ped, 24818), 0.07, -0.11, -0.05, 0.0, 90.0, 175.0, true, true, false, true, 1, true)
    bagEquipped = true
end

local function RemoveBag()
    if DoesEntityExist(bagObj) then
        DeleteObject(bagObj)
    end
    SetModelAsNoLongerNeeded(hash)
    bagObj = nil
    bagEquipped = nil
end

AddEventHandler('ox_inventory:updateInventory', function(changes)
    if justConnect then
        Wait(4500)
        justConnect = nil
    end
    for k, v in pairs(changes) do
        if type(v) == 'table' then
            local count = ox_inventory:Search('count', 'backpack')
	        if count > 0 and (not bagEquipped or not bagObj) then
                PutOnBag()
            elseif count < 1 and bagEquipped then
                RemoveBag()
            end
        end
        if type(v) == 'boolean' then
            local count = ox_inventory:Search('count', 'backpack')
            if count < 1 and bagEquipped then
                RemoveBag()
            end
        end
    end
end)

lib.onCache('ped', function(value)
    ped = value
end)

lib.onCache('vehicle', function(value)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    if value then
        RemoveBag()
    else
        local count = ox_inventory:Search('count', 'backpack')
        if count and count >= 1 then
            PutOnBag()
        end
    end
end)

exports('openBackpack', function(data, slot)
    if not slot or not slot.metadata or not slot.metadata.identifier then
        local identifier = lib.callback.await('wasabi_backpack:getNewIdentifier', 5000, data and data.slot)
        if identifier then
            ox_inventory:openInventory('stash', 'bag_' .. identifier)
        end
    else
        local identifier = slot.metadata.identifier
        -- Prompt for PIN (if any). If the user leaves blank and there's no pin, verification will pass.
        local pin = nil
        if lib and lib.inputDialog then
            local ok = lib.inputDialog('Entrez le PIN du sac', {{type = 'password', label = 'PIN (4-10 chiffres)', required = false}})
            if ok and ok[1] then pin = ok[1] end
        else
            -- fallback simple prompt
            pin = nil
        end
        local verified = lib.callback.await('wasabi_backpack:verifyPin', 10000, identifier, pin)
        if verified then
            TriggerServerEvent('wasabi_backpack:openBackpack', identifier)
            ox_inventory:openInventory('stash', 'bag_' .. identifier)
        else
            if lib and lib.notify then
                lib.notify({ title = 'Backpack', description = 'Code PIN incorrect', type = 'error' })
            else
                print('Backpack: PIN incorrect')
            end
        end
    end
end)

-- Command to create a backpack with level and PIN (quick creation helper)
RegisterCommand('createbackpack', function()
    if not lib or not lib.inputDialog then
        print('CreateBackpack: lib.inputDialog not available')
        return
    end
    local result = lib.inputDialog('Créer un sac', {
        { type = 'input', label = 'Niveau (1-3)', description = '1 = petit, 2 = moyen, 3 = grand' },
        { type = 'password', label = 'PIN (4-10 chiffres)', required = false }
    })
    if not result then return end
    local level = tonumber(result[1]) or 1
    local pin = result[2]
    local success, id_or_err = lib.callback.await('wasabi_backpack:createBackpack', 5000, level, pin)
    if success then
        lib.notify({ title = 'Backpack', description = 'Sac créé: ' .. id_or_err, type = 'success' })
    else
        lib.notify({ title = 'Backpack', description = 'Échec de création: ' .. (id_or_err or 'unknown'), type = 'error' })
    end
end)
