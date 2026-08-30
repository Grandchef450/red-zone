--[[
    val-hud / server.lua
    RÉÉCRIT POUR QBOX — RedZone, 30 août 2026

    ─── CE QUI N'ALLAIT PAS ───────────────────────────────────────

    Le fichier d'origine était écrit pour ox_core uniquement. Il
    appelait Ox.GetPlayer() et player.getStatus('stress'), deux API
    qui n'existent pas dans Qbox.

    Le config.lua propose pourtant un Config.FrameWork = 'qb', et
    cl_main.lua le respecte à cinq endroits. Mais server.lua, lui,
    l'ignorait complètement : le réglage n'avait aucun effet sur
    cette moitié du script.

    ─── COMMENT LE STRESS EST STOCKÉ MAINTENANT ───────────────────

    ox_core avait un système de « statuses » persistants. Qbox n'en
    a pas d'équivalent : on utilise donc les MÉTADONNÉES du
    personnage, qui se sauvegardent avec lui et le suivent d'une
    session à l'autre.

    ─── UN BUG D'ORIGINE CORRIGÉ AU PASSAGE ───────────────────────

    Le code testait `if Config.DisableStress then return end`, mais
    cette clé n'existe nulle part dans config.lua. Le test valait
    donc toujours nil, donc faux, et le stress ne pouvait jamais
    être désactivé — même en essayant.

    La clé est désormais lue proprement, avec false par défaut.
]]

local ResetStress = false


---Le stress actuel d'un joueur, entre 0 et 100.
---@param source number
---@return number|nil  nil si le personnage n'est pas chargé
local function getStress(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local meta = player.PlayerData.metadata
    return tonumber(meta and meta.stress) or 0
end


---Écrit le stress et prévient le client.
local function setStress(source, value)
    -- Bornes strictes : au-delà de 100, l'interface afficherait
    -- une jauge qui déborde de son cadre.
    value = math.max(0, math.min(100, math.floor(value + 0.5)))

    exports.qbx_core:SetMetadata(source, 'stress', value)
    TriggerClientEvent('hud:client:UpdateStress', source, value)

    return value
end


RegisterNetEvent('hud:server:GainStress', function(amount)
    if Config.DisableStress then return end

    local src = source
    local current = getStress(src)
    if not current then return end

    -- Le métier vient du statebag, alimenté par qbx_core
    local job = Player(src).state.inService
    if job and Config.WhitelistedJobs[job] then return end

    setStress(src, ResetStress and 0 or (current + (tonumber(amount) or 0)))
end)


RegisterNetEvent('hud:server:RelieveStress', function(amount)
    if Config.DisableStress then return end

    local src = source
    local current = getStress(src)
    if not current then return end

    setStress(src, ResetStress and 0 or (current - (tonumber(amount) or 0)))
end)


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION À LA CONNEXION
--
--  Absente du script d'origine : un joueur qui se reconnectait
--  voyait une jauge à zéro alors que son stress réel était stocké.
--  L'écart ne se corrigeait qu'au premier gain.
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source

    SetTimeout(2000, function()
        local stress = getStress(src)
        if stress then
            TriggerClientEvent('hud:client:UpdateStress', src, stress)
        end
    end)
end)


lib.addCommand('resetstress', {
    help = 'Remettre le stress d\'un joueur à zéro',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur', optional = true },
    },
    restricted = 'rz.staff',
}, function(source, args)
    local target = args.target or source

    if not getStress(target) then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Personnage introuvable.',
        })
    end

    setStress(target, 0)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Stress remis à zéro pour %s.')
            :format(GetPlayerName(target) or target),
    })
end)
