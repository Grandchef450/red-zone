--[[
    rz_sacs / client/main.lua
    Réparation d'un sac depuis l'inventaire.

    Le serveur fait tout le travail : ce fichier n'offre qu'un point
    d'entrée confortable au joueur.
]]

---Réparer le sac qui se trouve dans un slot donné.
---@param slot number
local function repairSlot(slot)
    local ok, msg = lib.callback.await('rz_sacs:repair', false, slot)

    lib.notify({
        type        = ok and 'success' or 'error',
        title       = 'Réparation de sac',
        description = msg,
        duration    = 8000,
    })
end


-- Commande de secours : /repairsac <slot>
-- Le numéro de slot se lit dans /sacinfo.
RegisterCommand('repairsac', function(_, args)
    local slot = tonumber(args[1])

    if not slot then
        return lib.notify({
            type        = 'error',
            description = 'Usage : /repairsac <numéro de slot>. Fais /sacinfo pour le connaître.',
            duration    = 7000,
        })
    end

    repairSlot(slot)
end, false)


exports('RepairSlot', repairSlot)
