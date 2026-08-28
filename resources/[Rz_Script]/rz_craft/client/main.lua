--[[
    rz_craft / client/main.lua
    Matérialisation dans le monde : props, cibles, blips.
]]

local spawnedProps = {}
local spawnedPeds  = {}
local blips        = {}

WorldData = { tables = {}, mailPoints = {} }

local function dbg(...)
    if Config.Debug then print('^3[rz_craft]^7', ...) end
end


---Fait apparaître un prop non physique et non collisionnable par erreur.
local function spawnProp(model, x, y, z, heading)
    if not model or model == '' then return nil end

    local hash = joaat(model)
    lib.requestModel(hash, 10000)

    if not HasModelLoaded(hash) then
        dbg('modèle introuvable : ' .. model)
        return nil
    end

    local obj = CreateObject(hash, x, y, z - 1.0, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, heading or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)

    return obj
end


---Fait apparaître un ped statique, invulnérable et hors des
---événements du monde. C'est ce dernier point qui l'empêche de fuir
---quand un zombie passe ou qu'un coup de feu claque à côté.
local function spawnPed(model, x, y, z, heading, scenario, frozen)
    if not model or model == '' then return nil end

    local hash = joaat(model)
    lib.requestModel(hash, 10000)

    if not HasModelLoaded(hash) then
        dbg('modèle de ped introuvable : ' .. model)
        return nil
    end

    local ped = CreatePed(4, hash, x, y, z - 1.0, heading or 0.0, false, false)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, false)
    SetEntityCanBeDamaged(ped, false)

    if frozen ~= false then
        FreezeEntityPosition(ped, true)
    end

    if scenario and scenario ~= '' then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(hash)

    return ped
end


local function createBlip(x, y, z, sprite, color, label)
    if not sprite then return nil end

    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color or 0)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'RedZone')
    EndTextCommandSetBlipName(blip)

    return blip
end


---Nettoie tout ce qui a été créé.
local function cleanup()
    for _, obj in ipairs(spawnedProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    spawnedProps, spawnedPeds, blips = {}, {}, {}
end


---Construit tout le monde à partir des données serveur.
function BuildWorld()
    cleanup()

    local data = lib.callback.await('rz_craft:getWorldData', false)
    if not data then return end

    WorldData = data

    -- ─── ÉTABLIS ───────────────────────────────────────────────
    for _, t in ipairs(data.tables) do
        local obj = spawnProp(t.prop, t.x, t.y, t.z, t.heading)
        if obj then spawnedProps[#spawnedProps + 1] = obj end

        local blip = createBlip(t.x, t.y, t.z, t.blipSprite, t.blipColor, t.label)
        if blip then blips[#blips + 1] = blip end

        exports.ox_target:addBoxZone({
            name   = ('rz_craft_table_%d'):format(t.id),
            coords = vec3(t.x, t.y, t.z),
            size   = vec3(2.0, 2.0, 2.0),
            rotation = t.heading or 0.0,
            debug  = Config.Debug,
            options = {
                {
                    name     = ('rz_craft_open_%d'):format(t.id),
                    icon     = 'fas fa-hammer',
                    label    = ('Utiliser — %s'):format(t.label),
                    distance = Config.CraftZone.radius,
                    onSelect = function()
                        OpenCraftTable(t.id)
                    end,
                },
            },
        })
    end

    -- ─── POINTS DE RETRAIT (peds) ──────────────────────────────
    for _, p in ipairs(data.mailPoints) do
        -- Prop décoratif optionnel, à côté du ped
        if p.prop and p.prop ~= '' then
            local obj = spawnProp(p.prop, p.x, p.y, p.z, p.heading)
            if obj then spawnedProps[#spawnedProps + 1] = obj end
        end

        local ped = spawnPed(p.ped, p.x, p.y, p.z, p.heading, p.scenario, p.frozen)

        local blip = createBlip(p.x, p.y, p.z, p.blipSprite, p.blipColor, p.label)
        if blip then blips[#blips + 1] = blip end

        if ped then
            spawnedPeds[#spawnedPeds + 1] = ped

            -- Cible posée sur l'entité elle-même : le joueur vise le
            -- personnage, pas une zone au sol. Plus lisible en jeu.
            exports.ox_target:addLocalEntity(ped, {
                {
                    name     = ('rz_mailbox_open_%d'):format(p.id),
                    icon     = 'fas fa-box-open',
                    label    = ('Récupérer mes colis — %s'):format(p.label),
                    distance = 2.5,
                    onSelect = function()
                        OpenMailbox(p.id)
                    end,
                },
            })
        else
            -- Le modèle de ped n'a pas chargé : on retombe sur une
            -- zone au sol pour que le point reste utilisable.
            exports.ox_target:addBoxZone({
                name   = ('rz_mailbox_%d'):format(p.id),
                coords = vec3(p.x, p.y, p.z),
                size   = vec3(1.5, 1.5, 2.0),
                rotation = p.heading or 0.0,
                debug  = Config.Debug,
                options = {
                    {
                        name     = ('rz_mailbox_open_%d'):format(p.id),
                        icon     = 'fas fa-box-open',
                        label    = 'Récupérer mes colis',
                        distance = 2.5,
                        onSelect = function()
                            OpenMailbox(p.id)
                        end,
                    },
                },
            })
        end
    end

    dbg(('monde construit : %d établis, %d points de retrait')
        :format(#data.tables, #data.mailPoints))
end


-- Reconstruction à la demande (après une édition admin)
RegisterNetEvent('rz_craft:rebuildWorld', BuildWorld)


AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1000) -- laisse ox_target et ox_core s'initialiser
    BuildWorld()
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanup()
end)
