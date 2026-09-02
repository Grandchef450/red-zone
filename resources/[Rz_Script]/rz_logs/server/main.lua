--[[
    rz_logs / server/main.lua

    Émetteur unique vers Discord.

    POURQUOI UNE FILE D'ATTENTE
    Discord limite chaque webhook à 5 requêtes par 2 secondes, et
    30 par minute. Un serveur actif produit largement plus
    d'événements que ça. Sans file, les messages seraient rejetés
    en silence — et on perdrait des logs sans jamais le savoir.

    On regroupe donc jusqu'à 10 messages par envoi, le maximum
    qu'accepte Discord, et on espace les envois par catégorie.
]]

-- [category] = liste d'embeds en attente
local queues = {}

-- [category] = horodatage du dernier envoi
local lastSent = {}

-- Compteurs, pour la commande de diagnostic
Stats = { sent = 0, dropped = 0, failed = 0, queued = 0 }

local function dbg(...)
    if Config.Debug then print('^3[rz_logs]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  CONSTRUCTION DES MESSAGES
-- ═══════════════════════════════════════════════════════════════════

---Échappe ce qui casserait le rendu Markdown de Discord.
---@param text any
---@param maxLen number?  1000 par défaut. Les champs (`fields[].value`)
---   doivent rester sous la limite Discord de 1024 — n'agrandis ce
---   paramètre QUE pour une description, qui accepte jusqu'à 4096.
local function clean(text, maxLen)
    if not text then return '—' end

    maxLen = maxLen or 1000
    text = tostring(text)

    -- Les codes couleur de FiveM (^1, ^#FF0000) n'ont aucun sens ici
    text = text:gsub('%^%d', ''):gsub('%^#%x+', '')

    -- @everyone et @here dans un log, c'est l'accident garanti
    text = text:gsub('@everyone', '@\226\128\139everyone')
    text = text:gsub('@here', '@\226\128\139here')

    if #text > maxLen then
        text = text:sub(1, maxLen - 3) .. '...'
    end

    return text
end


---Nom lisible d'un joueur, avec son identifiant si demandé.
---@param source number|string|nil
---@return string
function DescribePlayer(source)
    local src = tonumber(source)
    if not src or not GetPlayerName(src) then
        return source and ('`%s`'):format(tostring(source)) or 'Système'
    end

    local name = GetPlayerName(src)
    local license = GetPlayerIdentifierByType(src, 'license') or 'inconnu'

    -- Le nom du personnage est plus parlant que le pseudo Steam
    local char = ''
    if GetResourceState('qbx_core') == 'started' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)

        if ok and player and player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            char = (' — %s %s'):format(c.firstname or '', c.lastname or '')
        end
    end

    return ('**%s**%s\n`[%d]` `%s`'):format(name, char, src, license)
end


-- ═══════════════════════════════════════════════════════════════════
--  MISE EN FILE
-- ═══════════════════════════════════════════════════════════════════

---Ajoute un message à la file d'une catégorie.
---@param category string  clé de Config.Webhooks
---@param data table
---   title       string
---   description string?
---   fields      table?   { { name, value, inline? }, ... }
---   source      number?  joueur concerné
---   color       number?  surcharge de couleur
function Log(category, data)
    if not Config.IsEnabled(category) then return end
    if type(data) ~= 'table' then return end

    local fields = {}

    if data.source then
        fields[#fields + 1] = {
            name   = 'Joueur',
            value  = DescribePlayer(data.source),
            inline = false,
        }
    end

    for _, f in ipairs(data.fields or {}) do
        if f.name and f.value then
            fields[#fields + 1] = {
                name   = clean(f.name),
                value  = clean(f.value),
                inline = f.inline ~= false,
            }
        end
    end

    local embed = {
        title       = clean(data.title),
        -- 3900 et non 1000 : la description Discord accepte jusqu'à
        -- 4096 caractères, contrairement à un field (1024 max). Utile
        -- pour un transcript de conversation complet (rz_reports).
        description = data.description and clean(data.description, 3900) or nil,
        color       = data.color or Config.ColorOf(category),
        fields      = #fields > 0 and fields or nil,
        footer      = { text = Config.Appearance.footer },
        timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    local q = queues[category]
    if not q then
        q = {}
        queues[category] = q
    end

    -- File pleine : on abandonne le PLUS ANCIEN, pas le nouveau.
    -- Sur un incident, ce sont les événements récents qui comptent.
    if #q >= Config.Rate.maxQueue then
        table.remove(q, 1)
        Stats.dropped = Stats.dropped + 1
    end

    q[#q + 1] = embed
    Stats.queued = Stats.queued + 1
end

exports('Log', Log)


---Raccourci pour un message d'une ligne.
exports('Simple', function(category, title, description, source)
    Log(category, { title = title, description = description, source = source })
end)


-- ═══════════════════════════════════════════════════════════════════
--  ENVOI
-- ═══════════════════════════════════════════════════════════════════

local function post(url, payload, attempt)
    attempt = attempt or 1

    PerformHttpRequest(url, function(status, _, _)
        if status == 204 or status == 200 then
            Stats.sent = Stats.sent + 1
            return
        end

        -- 429 : on a dépassé le débit. Discord nous demande
        -- d'attendre ; on remet en file plutôt que de perdre.
        if status == 429 and attempt <= Config.Rate.retries then
            dbg('429 reçu, nouvelle tentative dans 3 s')
            SetTimeout(3000, function()
                post(url, payload, attempt + 1)
            end)
            return
        end

        if attempt <= Config.Rate.retries then
            SetTimeout(2000, function()
                post(url, payload, attempt + 1)
            end)
            return
        end

        Stats.failed = Stats.failed + 1
        print(('^1[rz_logs]^7 échec webhook (HTTP %s) après %d tentatives')
            :format(tostring(status), attempt))
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end


local function flush(category)
    local q = queues[category]
    if not q or #q == 0 then return end

    local url = Config.Webhooks[category]
    if not url or url == '' then
        queues[category] = nil
        return
    end

    local batch = {}
    for _ = 1, math.min(Config.Rate.batchSize, #q) do
        batch[#batch + 1] = table.remove(q, 1)
    end

    local payload = json.encode({
        username   = Config.Appearance.username,
        avatar_url = Config.Appearance.avatar,
        embeds     = batch,
    })

    post(url, payload)
    lastSent[category] = GetGameTimer()

    dbg(('%s : %d message(s) envoyé(s), %d en attente')
        :format(category, #batch, #q))
end


CreateThread(function()
    while true do
        Wait(500)

        local now = GetGameTimer()

        for category, q in pairs(queues) do
            if #q > 0 then
                local last = lastSent[category] or 0

                if (now - last) >= Config.Rate.interval then
                    flush(category)
                end
            end
        end
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  VIDAGE À L'ARRÊT
--
--  Sans ça, un redémarrage planifié perdrait tout ce qui reste en
--  file — exactement les logs qu'on voudrait relire après coup.
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for category in pairs(queues) do
        for _ = 1, 5 do
            flush(category)
        end
    end
end)


AddEventHandler('txAdmin:events:serverShuttingDown', function()
    Log('erreurs', {
        title = 'Arrêt du serveur',
        description = 'Redémarrage ou extinction en cours.',
    })

    for category in pairs(queues) do
        flush(category)
    end
end)


-- ═══════════════════════════════════════════════════════════════════
--  CONNEXIONS
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('playerJoining', function()
    if not Config.Connections.enabled then return end

    Log('connexions', {
        title  = 'Connexion',
        source = source,
    })
end)


AddEventHandler('playerDropped', function(reason)
    if not Config.Connections.enabled then return end

    Log('connexions', {
        title  = 'Déconnexion',
        source = source,
        fields = { { name = 'Raison', value = reason or 'inconnue' } },
    })
end)


-- ═══════════════════════════════════════════════════════════════════
--  DIAGNOSTIC
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('logstats', {
    help = 'État de la journalisation Discord',
    restricted = 'rz.staff',
}, function(source)
    local pending = 0
    local detail = {}

    for cat, q in pairs(queues) do
        pending = pending + #q
        if #q > 0 then
            detail[#detail + 1] = ('%s : %d'):format(cat, #q)
        end
    end

    local actives = {}
    for cat in pairs(Config.Webhooks) do
        if Config.IsEnabled(cat) then actives[#actives + 1] = cat end
    end

    table.sort(actives)

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header = 'Journalisation Discord',
        content = ([[
**Catégories actives** : %s

Envoyés : **%d**
En attente : **%d**
Abandonnés (file pleine) : **%d**
Échecs : **%d**

%s]]):format(
            #actives > 0 and table.concat(actives, ', ') or 'aucune',
            Stats.sent, pending, Stats.dropped, Stats.failed,
            #detail > 0 and ('Détail : ' .. table.concat(detail, ' · ')) or ''),
        centered = true,
    })
end)


lib.addCommand('logtest', {
    help = 'Envoyer un message de test dans une catégorie',
    params = {
        { name = 'categorie', type = 'string', help = 'mort, inventaire, craft...' },
    },
    restricted = 'rz.staff',
}, function(source, args)
    local cat = args.categorie

    if not Config.Webhooks[cat] then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = ('Catégorie « %s » inconnue.'):format(cat),
        })
    end

    if not Config.IsEnabled(cat) then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = ('Aucun webhook configuré pour « %s ».'):format(cat),
        })
    end

    Log(cat, {
        title       = 'Test de journalisation',
        description = 'Si tu lis ceci sur Discord, le webhook fonctionne.',
        source      = source,
    })

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Test envoyé vers « %s ».'):format(cat),
    })
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local n = 0
    for cat in pairs(Config.Webhooks) do
        if Config.IsEnabled(cat) then n = n + 1 end
    end

    if n == 0 then
        print('^3[rz_logs]^7 aucun webhook configuré : la journalisation est inactive.')
    else
        print(('^2[rz_logs]^7 %d catégorie(s) active(s)'):format(n))
    end
end)
