--[[
    rz_spawn / client/appearance.lua

    Ouvre la personnalisation d'apparence à la création d'un
    personnage.

    ─── POURQUOI CE FICHIER EXISTE ────────────────────────────────

    illenium-appearance contient bien une fonction
    InitializeCharacter(), mais RIEN NE L'APPELLE.

    Chez ESX ou QBCore d'origine, c'est le pont du framework qui la
    déclenche au moment de la création. Celui de Qbox ne le fait
    pas — l'événement attendu n'existe pas de son côté.

    Résultat : un nouveau personnage arrive avec l'apparence par
    défaut, sans jamais avoir pu choisir son visage ni ses habits.
    On déclenche donc l'ouverture nous-mêmes.
]]

local customizing = false

local function dbg(...)
    if Config.Debug then print('^3[rz_spawn]^7', ...) end
end


---Le genre du personnage, tel qu'illenium l'attend.
---@return string 'male' ou 'female'
local function currentGender()
    -- Le modèle du ped est la source la plus fiable : les
    -- métadonnées du personnage peuvent ne pas être encore chargées
    -- au moment où on en a besoin.
    return GetEntityModel(cache.ped) == `mp_f_freemode_01`
        and 'female' or 'male'
end


---Ouvre la personnalisation complète.
---@param isNew boolean  création, ou simple retouche
function OpenAppearance(isNew)
    if customizing then return end

    if GetResourceState('illenium-appearance') ~= 'started' then
        return lib.notify({
            type        = 'error',
            description = 'La personnalisation d\'apparence n\'est pas disponible.',
        })
    end

    customizing = true

    local ped = cache.ped

    if Config.Appearance.freezeDuring then
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
    end

    if isNew then
        lib.notify({
            type        = 'inform',
            title       = 'Crée ton personnage',
            description = 'Choisis ton visage et tes vêtements. Tu ne pourras plus les changer ensuite.',
            duration    = 10000,
        })

        Wait(1500)
    end

    -- InitializeCharacter est une fonction GLOBALE d'illenium :
    -- elle est accessible depuis n'importe quelle ressource, mais
    -- seulement une fois la sienne démarrée. D'où le pcall.
    local ok = pcall(function()
        InitializeCharacter(currentGender(), function()
            dbg('apparence enregistrée')
        end, function()
            dbg('personnalisation annulée')
        end)
    end)

    if not ok then
        -- Repli : la commande /pedmenu d'illenium ouvre le même
        -- menu, en passant par le serveur.
        dbg('InitializeCharacter inaccessible, repli sur pedmenu')
        ExecuteCommand('pedmenu')
    end

    -- On attend que le menu se referme avant de rendre la main.
    -- Sans ça, le joueur serait libéré alors qu'il choisit encore
    -- sa coupe de cheveux.
    CreateThread(function()
        Wait(5000)

        while IsPauseMenuActive() or customizing do
            Wait(1000)

            -- Le menu d'illenium est une NUI : on la détecte par
            -- l'absence de contrôle du joueur.
            if not IsPauseMenuActive() then
                Wait(3000)
                break
            end
        end

        if Config.Appearance.freezeDuring then
            FreezeEntityPosition(cache.ped, false)
            SetEntityInvincible(cache.ped, false)
        end

        customizing = false

        if isNew then
            lib.notify({
                type        = 'success',
                title       = 'Te voilà prêt',
                description = 'Descends de la montagne. Tout est à trouver.',
                duration    = 10000,
            })
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉCLENCHEMENT À LA CRÉATION
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_spawn:openAppearance', function()
    if not Config.Appearance.onFirstSpawn then return end

    -- Le délai laisse au décor le temps de se charger : ouvrir le
    -- menu sur un monde vide donne un aperçu du personnage sur
    -- fond noir.
    Wait(Config.Appearance.delaySeconds * 1000)

    OpenAppearance(true)
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDE
--
--  À désactiver avant l'ouverture publique : si chacun peut changer
--  de visage quand il veut, plus personne ne se reconnaît d'une
--  session à l'autre.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    if not Config.Appearance.allowCommand then return end

    RegisterCommand(Config.Appearance.command, function()
        OpenAppearance(false)
    end, false)
end)
