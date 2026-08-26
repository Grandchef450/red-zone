local equippedProps = {}  -- { key = entity }

-- Charge et attache un prop au joueur
local function equipProp(key)
    local cfg = Config.Props[key]
    if not cfg then return end

    -- Déséquipe si déjà en main
    if equippedProps[key] then
        DeleteEntity(equippedProps[key])
        equippedProps[key] = nil
        print(('[Props] %s déséquipé'):format(cfg.label))
        return
    end

    local ped  = PlayerPedId()
    local hash = GetHashKey(cfg.model)

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        print(('[Props] ⚠️ Modèle introuvable : %s'):format(cfg.model))
        return
    end

    local entity = CreateObject(hash, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(
        entity, ped,
        GetPedBoneIndex(ped, cfg.bone),
        cfg.x, cfg.y, cfg.z,
        cfg.pitch, cfg.roll, cfg.yaw,
        true, true, false, true, 1, true
    )

    equippedProps[key] = entity
    SetModelAsNoLongerNeeded(hash)
    print(('[Props] %s équipé'):format(cfg.label))
end

-- Enregistre une commande par prop
for key, cfg in pairs(Config.Props) do
    RegisterCommand(cfg.command, function()
        equipProp(key)
    end, false)

    -- Affiche la commande disponible dans le chat au spawn
    TriggerEvent('chat:addSuggestion', '/' .. cfg.command, 'Équiper/Déséquiper : ' .. cfg.label)
end

-- Nettoie les props si le joueur quitte / resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for key, entity in pairs(equippedProps) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)