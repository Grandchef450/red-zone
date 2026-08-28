Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  LES COFFRES RECONNUS
--
--  La durée par défaut est déduite du nom : coffre_securite_72h vaut
--  72 heures, coffre_boutique_104_28j vaut 28 jours. L'admin peut
--  toujours imposer une autre durée au moment de la remise.
-- ═══════════════════════════════════════════════════════════════════
Config.ChestPrefixes = {
    'coffre_securite_',
    'coffre_boutique_',
}

---Durée par défaut d'un coffre, en heures, déduite de son nom.
---@param itemName string
---@return number|nil heures
function Config.GetDefaultHours(itemName)
    -- coffre_securite_72h  →  72
    local h = itemName:match('_(%d+)h$')
    if h then return tonumber(h) end

    -- coffre_boutique_104_28j  →  28 jours = 672 heures
    local j = itemName:match('_(%d+)j$')
    if j then return tonumber(j) * 24 end

    return nil
end

---Cet item est-il un coffre de sécurité ?
---@param itemName string
---@return boolean
function Config.IsChest(itemName)
    if not itemName then return false end
    for _, prefix in ipairs(Config.ChestPrefixes) do
        if itemName:sub(1, #prefix) == prefix then return true end
    end
    return false
end


-- ═══════════════════════════════════════════════════════════════════
--  COMPORTEMENT
-- ═══════════════════════════════════════════════════════════════════
Config.Behaviour = {
    -- ─── LE RÉGLAGE STRUCTURANT ───────────────────────────────────
    -- true  : un coffre encore sous protection NE TOMBE PAS à la mort.
    --         Il reste avec son propriétaire à la réapparition.
    --         C'est la vraie garantie « ton stock n'est pas perdu ».
    --
    -- false : il tombe comme le reste, mais reste inouvrable par les
    --         autres jusqu'à expiration. Un pillard peut donc l'emporter
    --         et attendre la fin du minuteur — la garantie ne vaut alors
    --         plus grand-chose.
    keepOnDeathWhileLocked = true,

    -- Un coffre sous protection ne peut pas être transféré à un autre
    -- joueur ni rangé dans un coffre tiers. Il est lié, point.
    blockTransferWhileLocked = true,

    -- Un coffre expiré ne disparaît jamais. Il reste dans l'inventaire
    -- et devient un conteneur ordinaire, ouvrable par quiconque le
    -- détient.
    deleteOnExpiry = false,
}


-- ═══════════════════════════════════════════════════════════════════
--  INFOBULLE
--
--  ox_inventory affiche le champ metadata.description au survol de
--  l'item. On y écrit le temps restant, et on le rafraîchit
--  régulièrement pour que le décompte soit vivant.
-- ═══════════════════════════════════════════════════════════════════
Config.Tooltip = {
    -- Fréquence de rafraîchissement, en secondes. L'écriture n'a lieu
    -- que si le texte affiché change réellement : passer de « 3 j 14 h »
    -- à « 3 j 14 h » ne déclenche aucune écriture.
    refreshSeconds = 30,

    lockedIcon   = '🔒',
    unlockedIcon = '🔓',
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = {
    -- Remettre un coffre à un joueur (staff boutique)
    give = 'rz.coffres.give',

    -- Consulter et révoquer (administration)
    admin = 'rz.coffres.admin',
}

Config.AceSuper = 'rz_coffres.admin'

function Config.HasAce(source, permission)
    if IsPlayerAceAllowed(source, Config.AceSuper) then return true end
    return IsPlayerAceAllowed(source, permission)
end

--[[
    server.cfg :
        add_ace group.admin   rz_coffres.admin  allow
        add_ace group.support rz.coffres.give   allow
]]


-- ═══════════════════════════════════════════════════════════════════
--  DURÉES PROPOSÉES DANS LE MENU ADMIN
-- ═══════════════════════════════════════════════════════════════════
Config.Durations = {
    { label = '12 heures',  hours = 12 },
    { label = '24 heures',  hours = 24 },
    { label = '3 jours',    hours = 72 },
    { label = '4 jours',    hours = 96 },
    { label = '5 jours',    hours = 120 },
    { label = '6 jours',    hours = 144 },
    { label = '7 jours',    hours = 168 },
    { label = '14 jours',   hours = 336 },
    { label = '21 jours',   hours = 504 },
    { label = '28 jours',   hours = 672 },
    { label = '35 jours',   hours = 840 },
}
