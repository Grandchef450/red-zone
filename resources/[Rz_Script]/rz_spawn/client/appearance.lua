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


-- ═══════════════════════════════════════════════════════════════
--  REMISE À ZÉRO DE L'APPARENCE
--
--  ⚠️  LA CAUSE DU PLANTAGE « pennsylvania-oranges-vermont »
--
--  Le rapport de crash désigne le natif 0x00a1cadd00108836, soit
--  SetPedComponentVariation : la fonction qui habille un ped.
--
--  Elle plante quand on lui demande un vêtement qui n'existe pas —
--  typiquement après le retrait d'un pack de vêtements dont des
--  joueurs portaient encore les pièces. Leur apparence enregistrée
--  pointe alors dans le vide.
--
--  On repart donc systématiquement d'une tenue vanilla connue avant
--  d'ouvrir le menu. Le joueur choisira la sienne ensuite ; on ne
--  risque plus de charger une référence morte.
-- ═══════════════════════════════════════════════════════════════

---Remet le ped dans une tenue de base garantie valide.
function resetToSafeAppearance()
    local ped = cache.ped
    local female = GetEntityModel(ped) == `mp_f_freemode_01`

    -- Composants sûrs : ces valeurs existent dans le jeu de base,
    -- quels que soient les packs installés ou retirés.
    -- { slot, drawable, texture }
    local safe = female and {
        { 1, 0, 0 },    -- masque
        { 3, 15, 0 },   -- torse nu
        { 4, 15, 0 },   -- jambes
        { 6, 35, 0 },   -- chaussures
        { 8, 15, 0 },   -- sous-vêtement
        { 11, 15, 0 },  -- veste
    } or {
        { 1, 0, 0 },
        { 3, 15, 0 },
        { 4, 21, 0 },
        { 6, 34, 0 },
        { 8, 15, 0 },
        { 11, 15, 0 },
    }

    for _, c in ipairs(safe) do
        -- pcall : même une valeur vanilla peut échouer si un pack
        -- a écrasé le composant. Mieux vaut ignorer que planter.
        pcall(function()
            SetPedComponentVariation(ped, c[1], c[2], c[3], 0)
        end)
    end

    -- Les accessoires posent le même problème : on les retire tous.
    for prop = 0, 7 do
        pcall(function() ClearPedProp(ped, prop) end)
    end

    dbg('apparence remise à une base sûre')
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

    -- Toujours repartir d'une base saine, création ou retouche :
    -- c'est ce qui évite de charger une référence vers un vêtement
    -- supprimé, et donc de planter le joueur.
    resetToSafeAppearance()
    Wait(300)

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

-- ═══════════════════════════════════════════════════════════════════
--  RÉPARER UNE APPARENCE CASSÉE
--
--  Quand un joueur plante à chaque connexion sans qu'on sache
--  pourquoi, c'est presque toujours son apparence : elle référence
--  un vêtement d'un pack retiré depuis.
--
--  Cette commande le remet en tenue vanilla, ce qui le débloque
--  immédiatement. Il refait ensuite son personnage.
-- ═══════════════════════════════════════════════════════════════════

RegisterCommand('resetapparence', function()
    resetToSafeAppearance()

    lib.notify({
        type        = 'success',
        title       = 'Apparence réinitialisée',
        description = 'Tenue de base restaurée. Fais /apparence pour te rhabiller.',
        duration    = 10000,
    })
end, false)


---Réinitialisation forcée par le staff, à distance.
RegisterNetEvent('rz_spawn:forceResetAppearance', function()
    resetToSafeAppearance()

    lib.notify({
        type        = 'inform',
        title       = 'Le staff est intervenu',
        description = 'Ton apparence a été réinitialisée.',
        duration    = 8000,
    })
end)
