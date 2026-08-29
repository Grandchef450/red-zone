--[[
    rz_epaves / client/admin.lua
    Réglage du butin des épaves depuis le menu admin (F5).
]]

RegisterNUICallback('openEpaves', function(_, cb)
    cb({ ok = true })
    SetTimeout(250, function() OpenLootMenu() end)
end)


RegisterCommand('epaveloot', function()
    OpenLootMenu()
end, false)


-- ═══════════════════════════════════════════════════════════════════
--  MENU PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

function OpenLootMenu()
    local allowed = lib.callback.await('rz_epaves:isAdmin', false)

    if not allowed then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = 'Permission rz.staff requise.',
        })
    end

    local s = lib.callback.await('rz_epaves:getSettings', false)
    if not s then return end

    local options = {
        {
            title       = s.enabled and 'Fouille activée' or 'Fouille DÉSACTIVÉE',
            description = 'Basculer la possibilité de fouiller les épaves',
            icon        = s.enabled and 'fas fa-toggle-on' or 'fas fa-toggle-off',
            iconColor   = s.enabled and '#4ade80' or '#f87171',
            onSelect    = function()
                lib.callback.await('rz_epaves:setSettings', false, {
                    drawsMin = s.drawsMin, drawsMax = s.drawsMax,
                    quantityMult = s.quantityMult,
                    respawnMinutes = s.respawnMinutes,
                    enabled = not s.enabled,
                })
                OpenLootMenu()
            end,
        },
        {
            title       = 'Abondance générale',
            description = ('Tirage %d à %d items · quantités ×%.2f · respawn %d min')
                :format(s.drawsMin, s.drawsMax, s.quantityMult, s.respawnMinutes),
            icon        = 'fas fa-sliders',
            onSelect    = function() EditGlobal(s) end,
        },
        {
            title       = ('Table de butin (%d items)'):format(#s.loot),
            description = 'Régler chaque item : quantité et probabilité',
            icon        = 'fas fa-list',
            arrow       = true,
            onSelect    = function() LootList(s) end,
        },
        {
            title       = 'Ajouter un item',
            icon        = 'fas fa-plus',
            iconColor   = '#4ade80',
            onSelect    = function() AddLootItem() end,
        },
        {
            title       = 'Simuler 5000 fouilles',
            description = 'Ce que les joueurs trouveront vraiment, en moyenne',
            icon        = 'fas fa-flask',
            arrow       = true,
            onSelect    = function() Simulate() end,
        },
    }

    lib.registerContext({
        id      = 'rz_epaves_menu',
        title   = 'Loot des épaves',
        options = options,
    })

    lib.showContext('rz_epaves_menu')
end


-- ═══════════════════════════════════════════════════════════════════
--  RÉGLAGES GÉNÉRAUX
-- ═══════════════════════════════════════════════════════════════════

function EditGlobal(s)
    local input = lib.inputDialog('Abondance générale', {
        {
            type = 'slider', label = 'Items tirés au minimum',
            default = s.drawsMin, min = 0, max = 10, step = 1,
            description = 'À 0, une épave peut être totalement vide.',
        },
        {
            type = 'slider', label = 'Items tirés au maximum',
            default = s.drawsMax, min = 1, max = 10, step = 1,
        },
        {
            type = 'number', label = 'Multiplicateur de quantité',
            default = s.quantityMult, min = 0.1, max = 10, step = 0.1,
            description = 'Le bouton rapide : 2 double toutes les quantités d\'un coup, sans toucher aux items un par un.',
        },
        {
            type = 'number', label = 'Régénération (minutes)',
            default = s.respawnMinutes, min = 1, max = 1440,
            description = 'Garde cette valeur alignée sur inventory:cleartime du server.cfg.',
        },
    })

    if not input then return end

    local ok = lib.callback.await('rz_epaves:setSettings', false, {
        drawsMin       = input[1],
        drawsMax       = input[2],
        quantityMult   = input[3],
        respawnMinutes = input[4],
        enabled        = s.enabled,
    })

    lib.notify({
        type        = ok and 'success' or 'error',
        description = ok and 'Réglages appliqués immédiatement.' or 'Échec.',
    })

    if ok then OpenLootMenu() end
end


-- ═══════════════════════════════════════════════════════════════════
--  TABLE DE BUTIN
-- ═══════════════════════════════════════════════════════════════════

function LootList(s)
    local options = {}

    for _, e in ipairs(s.loot) do
        options[#options + 1] = {
            title       = ('%s%s'):format(e.enabled and '' or '✗ ', e.label),
            description = ('%d à %d exemplaires · %d %% de chance\n%s')
                :format(e.min_count, e.max_count, e.chance, e.item),
            icon        = e.enabled and 'fas fa-box' or 'fas fa-box-open',
            iconColor   = e.enabled and '#60a5fa' or '#6b7280',
            arrow       = true,
            onSelect    = function() EditLootItem(e) end,
        }
    end

    lib.registerContext({
        id      = 'rz_epaves_loot',
        title   = ('Table de butin (%d)'):format(#s.loot),
        menu    = 'rz_epaves_menu',
        options = options,
    })

    lib.showContext('rz_epaves_loot')
end


function EditLootItem(e)
    local input = lib.inputDialog(e.label, {
        { type = 'number', label = 'Quantité minimale', default = e.min_count, min = 1, max = 999 },
        { type = 'number', label = 'Quantité maximale', default = e.max_count, min = 1, max = 999 },
        {
            type = 'slider', label = 'Probabilité (%)',
            default = e.chance, min = 1, max = 100, step = 1,
            description = 'Appliquée APRÈS le tirage. Un item à 70 % n\'apparaît pas dans 70 % des épaves : utilise la simulation pour le vrai chiffre.',
        },
        { type = 'checkbox', label = 'Actif dans la table', checked = e.enabled },
        { type = 'checkbox', label = 'SUPPRIMER cet item', checked = false },
    })

    if not input then return end

    if input[5] then
        local confirm = lib.alertDialog({
            header   = 'Supprimer ?',
            content  = ('« %s » sera retiré de la table de butin.'):format(e.label),
            centered = true, cancel = true,
        })

        if confirm == 'confirm' then
            lib.callback.await('rz_epaves:removeLootEntry', false, e.item)
            lib.notify({ type = 'success', description = 'Item retiré.' })
            OpenLootMenu()
        end
        return
    end

    local ok, msg = lib.callback.await('rz_epaves:setLootEntry', false,
        e.item, input[1], input[2], input[3], input[4])

    lib.notify({
        type        = ok and 'success' or 'error',
        description = msg or 'Échec.',
    })

    if ok then OpenLootMenu() end
end


function AddLootItem()
    local items = lib.callback.await('rz_epaves:getAllItems', false) or {}

    if #items == 0 then
        return lib.notify({
            type = 'inform',
            description = 'Tous les items disponibles sont déjà dans la table.',
        })
    end

    local input = lib.inputDialog('Ajouter au butin des épaves', {
        { type = 'select', label = 'Item', options = items, required = true, searchable = true },
        { type = 'number', label = 'Quantité minimale', default = 1, min = 1, max = 999 },
        { type = 'number', label = 'Quantité maximale', default = 2, min = 1, max = 999 },
        { type = 'slider', label = 'Probabilité (%)', default = 40, min = 1, max = 100, step = 1 },
    })

    if not input then return end

    local ok, msg = lib.callback.await('rz_epaves:setLootEntry', false,
        input[1], input[2], input[3], input[4], true)

    lib.notify({
        type        = ok and 'success' or 'error',
        description = msg or 'Échec.',
    })

    if ok then OpenLootMenu() end
end


-- ═══════════════════════════════════════════════════════════════════
--  SIMULATION
-- ═══════════════════════════════════════════════════════════════════

function Simulate()
    lib.notify({ type = 'inform', description = 'Simulation en cours...' })

    local r = lib.callback.await('rz_epaves:simulate', false, 5000)
    if not r then return end

    local lines = {
        ('**%d fouilles simulées**'):format(r.runs),
        ('Épaves totalement vides : **%.1f %%**'):format(r.emptyRate),
        '',
        '| Item | Présent dans | Moyenne / épave |',
        '| --- | --- | --- |',
    }

    for i, e in ipairs(r.items) do
        if i > 20 then break end
        lines[#lines + 1] = ('| %s | %.1f %% | %.2f |')
            :format(e.item, e.rate, e.perWreck)
    end

    lib.alertDialog({
        header   = 'Simulation du butin',
        content  = table.concat(lines, '  \n'),
        centered = true,
        size     = 'lg',
    })
end
