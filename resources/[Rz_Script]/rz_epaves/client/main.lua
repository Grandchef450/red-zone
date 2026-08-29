--[[
    rz_epaves / client/main.lua
    Ciblage des props d'épave et animation de fouille.
]]

local searching = false


-- ═══════════════════════════════════════════════════════════════════
--  CIBLAGE
--
--  addModel cible TOUS les objets d'un modèle donné, où qu'ils
--  soient sur la carte. C'est ce qui permet de couvrir des milliers
--  d'épaves posées en ymap sans en connaître une seule position.
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)   -- laisse ox_target s'initialiser

    if #Config.WreckModels == 0 then
        print('^3[rz_epaves]^7 aucun modèle configuré. Utilise /epavemodel pour relever les tiens.')
        return
    end

    exports.ox_target:addModel(Config.WreckModels, {
        {
            name     = 'rz_epave_fouiller',
            icon     = Config.Search.icon,
            label    = Config.Search.label,
            distance = Config.Search.distance,
            onSelect = function(data)
                SearchWreck(data.entity)
            end,
        },
    })

    if Config.Debug then
        print(('^3[rz_epaves]^7 %d modèle(s) ciblé(s)'):format(#Config.WreckModels))
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  FOUILLE
-- ═══════════════════════════════════════════════════════════════════

function SearchWreck(entity)
    if searching then return end
    if not entity or not DoesEntityExist(entity) then return end

    searching = true

    -- On envoie la position du PROP, pas celle du joueur : c'est elle
    -- qui identifie l'épave côté serveur, et elle ne bouge jamais.
    local coords = GetEntityCoords(entity)

    lib.requestAnimDict(Config.Search.animDict, 5000)
    TaskPlayAnim(cache.ped, Config.Search.animDict, Config.Search.animName,
                 8.0, -8.0, -1, 1, 0, false, false, false)

    local finished = lib.progressBar({
        duration     = Config.Search.duration,
        label        = 'Fouille de l\'épave...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not finished then
        searching = false
        return
    end

    local stashId = lib.callback.await('rz_epaves:search', false, {
        x = coords.x, y = coords.y, z = coords.z,
    })

    if stashId then
        exports.ox_inventory:openInventory('stash', stashId)
    else
        lib.notify({
            type        = 'error',
            description = 'Impossible de fouiller cette épave.',
        })
    end

    searching = false
end


-- ═══════════════════════════════════════════════════════════════════
--  RELEVÉ DE MODÈLE
--
--  Ta map est un asset pack chiffré : ses modèles d'épave sont
--  peut-être personnalisés et absents de la liste par défaut. Cette
--  commande te dit exactement quoi ajouter dans config.lua.
-- ═══════════════════════════════════════════════════════════════════

RegisterCommand('epavemodel', function()
    local ped    = cache.ped
    local coords = GetEntityCoords(ped)
    local dir    = GetEntityForwardVector(ped)

    -- Rayon partant des yeux, 8 mètres devant
    local from = vec3(coords.x, coords.y, coords.z + 0.7)
    local to   = from + (dir * 8.0)

    local handle = StartShapeTestRay(from.x, from.y, from.z,
                                     to.x, to.y, to.z, 16, ped, 0)
    local _, hit, _, _, entity = GetShapeTestResult(handle)

    if hit == 0 or not entity or entity == 0 then
        return lib.notify({
            type        = 'error',
            description = 'Aucun objet visé. Approche-toi et vise l\'épave.',
        })
    end

    local model = GetEntityModel(entity)
    local known = false

    for _, name in ipairs(Config.WreckModels) do
        if joaat(name) == model then known = true break end
    end

    -- GetEntityArchetypeName ne fonctionne que sur certains objets.
    -- Quand il échoue, le hash reste utilisable tel quel dans la
    -- config : Lua accepte les nombres comme noms de modèle.
    local archetype = GetEntityArchetypeName and GetEntityArchetypeName(entity) or nil
    local display = (archetype and archetype ~= '') and archetype or tostring(model)

    lib.setClipboard(display)

    lib.alertDialog({
        header   = known and 'Modèle déjà configuré' or 'Nouveau modèle',
        content  = ('**%s**  \n\nCopié dans le presse-papier.  \n%s')
            :format(display, known
                and 'Ce modèle est déjà dans ta liste, rien à faire.'
                or  'Ajoute-le dans Config.WreckModels, puis restart rz_epaves.'),
        centered = true,
    })

    print(('^2[rz_epaves]^7 modèle visé : %s  (hash %s)'):format(display, model))
end, false)
