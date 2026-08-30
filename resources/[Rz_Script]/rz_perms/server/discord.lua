--[[
    rz_perms / server/discord.lua

    Attribue les grades d'après les rôles Discord, à la connexion.

    POURQUOI C'EST UTILE
    Sans ça, chaque changement de grade demande d'éditer le
    server.cfg et de redémarrer. Ici tu déplaces un rôle sur
    Discord, la personne se reconnecte, c'est appliqué.

    COMMENT ÇA MARCHE
    À la connexion, on lit l'identifiant Discord du joueur, on
    demande à l'API la liste de ses rôles dans ton serveur, et on
    lui accorde le groupe correspondant avec add_principal.

    LES TROIS RAISONS POUR LESQUELLES ÇA NE MARCHE PAS
    1. Le joueur n'avait pas Discord ouvert : FiveM ne transmet
       alors aucun identifiant discord.
    2. Le « Server Members Intent » n'est pas activé sur le bot :
       l'API renvoie 403 sans autre explication.
    3. Le bot n'est pas dans le serveur : l'API renvoie 404.
]]

-- [discordId] = { grade = string|nil, at = timestamp }
local cache = {}

-- [identifier] = grade actuellement accordé, pour pouvoir le retirer
local granted = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_perms]^7', ...) end
end


---Identifiant Discord d'un joueur, sans le préfixe.
local function discordIdOf(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
    return nil
end


---Interroge l'API Discord pour les rôles d'un membre.
---@param discordId string
---@param cb fun(roles: table|nil, err: string|nil)
local function fetchRoles(discordId, cb)
    local url = ('https://discord.com/api/v10/guilds/%s/members/%s')
        :format(Config.Discord.guildId, discordId)

    PerformHttpRequest(url, function(status, body)
        if status == 200 and body then
            local ok, data = pcall(json.decode, body)

            if ok and type(data) == 'table' and data.roles then
                return cb(data.roles)
            end

            return cb(nil, 'réponse illisible')
        end

        -- Messages explicites : ces trois cas représentent la quasi-
        -- totalité des échecs, et le code seul n'aide personne.
        local reason =
            status == 401 and 'jeton du bot invalide'
            or status == 403 and 'Server Members Intent non activé sur le bot'
            or status == 404 and 'bot absent du serveur, ou joueur non membre'
            or status == 429 and 'trop de requêtes, Discord temporise'
            or ('HTTP ' .. tostring(status))

        cb(nil, reason)
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. Config.Discord.token,
        ['Content-Type']  = 'application/json',
    })
end


---Grade correspondant à une liste de rôles.
---Le PREMIER rôle configuré qui correspond l'emporte : c'est ce qui
---évite qu'un développeur portant aussi le rôle support soit traité
---comme un support.
local function gradeFromRoles(roles)
    local set = {}
    for _, r in ipairs(roles) do set[tostring(r)] = true end

    for _, entry in ipairs(Config.Discord.roles) do
        if entry.roleId ~= '' and set[entry.roleId] then
            return entry.grade
        end
    end

    return nil
end


---Applique un grade à un joueur.
local function applyGrade(source, grade)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return end

    local identifier = 'identifier.' .. license
    local previous = granted[license]

    -- On retire l'ancien avant de poser le nouveau, sinon un
    -- rétrogradé cumulerait ses deux grades.
    if previous and previous ~= grade and Config.Discord.revokeWhenRemoved then
        local g = Config.GetGrade(previous)
        if g then
            ExecuteCommand(('remove_principal %s %s'):format(identifier, g.group))
            dbg(('%s : grade %s retiré'):format(GetPlayerName(source), previous))
        end
    end

    if not grade then
        granted[license] = nil
        return
    end

    local g = Config.GetGrade(grade)
    if not g then
        print(('^1[rz_perms]^7 grade « %s » inconnu dans Config.Grades'):format(grade))
        return
    end

    ExecuteCommand(('add_principal %s %s'):format(identifier, g.group))
    granted[license] = grade

    dbg(('%s : grade %s accordé'):format(GetPlayerName(source), grade))

    if Config.Discord.logChanges and GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('admin', {
                title  = ('Grade accordé — %s'):format(g.label),
                source = source,
                fields = {
                    { name = 'Origine', value = 'Rôle Discord' },
                    { name = 'Groupe',  value = g.group },
                },
            })
        end)
    end
end


---Synchronise un joueur.
function SyncPlayer(source, force)
    if not Config.Discord.enabled then return end

    if Config.Discord.token == '' or Config.Discord.guildId == '' then
        return
    end

    local discordId = discordIdOf(source)

    if not discordId then
        dbg(('%s : aucun identifiant Discord (application fermée ?)')
            :format(GetPlayerName(source) or source))
        return
    end

    -- Cache : évite d'appeler l'API à chaque reconnexion d'un même
    -- joueur, ce qui finirait par déclencher la limite de débit.
    local entry = cache[discordId]
    local ttl = Config.Discord.cacheMinutes * 60

    if not force and entry and (os.time() - entry.at) < ttl then
        applyGrade(source, entry.grade)
        return
    end

    fetchRoles(discordId, function(roles, err)
        if err then
            print(('^3[rz_perms]^7 Discord — %s : %s')
                :format(GetPlayerName(source) or source, err))
            return
        end

        local grade = gradeFromRoles(roles)
        cache[discordId] = { grade = grade, at = os.time() }

        -- Le joueur a pu se déconnecter pendant la requête
        if GetPlayerName(source) then
            applyGrade(source, grade)
        end
    end)
end


AddEventHandler('playerJoining', function()
    local src = source
    -- Un léger délai : les identifiants ne sont pas tous disponibles
    -- à l'instant précis de la connexion.
    SetTimeout(3000, function()
        if GetPlayerName(src) then SyncPlayer(src) end
    end)
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDES
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('syncgrades', {
    help = 'Resynchroniser les grades Discord de tous les joueurs',
    restricted = 'rz.staff',
}, function(source)
    if not Config.Discord.enabled then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'La synchronisation Discord est désactivée.',
        })
    end

    cache = {}
    local n = 0

    for _, playerId in ipairs(GetPlayers()) do
        SyncPlayer(tonumber(playerId), true)
        n = n + 1
        Wait(250)   -- on espace : Discord limite le débit
    end

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('%d joueur(s) resynchronisé(s).'):format(n),
    })
end)


lib.addCommand('syncme', {
    help = 'Resynchroniser ton propre grade depuis Discord',
}, function(source)
    if not Config.Discord.enabled then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'La synchronisation Discord est désactivée.',
        })
    end

    SyncPlayer(source, true)

    TriggerClientEvent('ox_lib:notify', source, {
        type        = 'inform',
        description = 'Synchronisation lancée. Fais /grade dans quelques secondes.',
    })
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if not Config.Discord.enabled then
        print('^3[rz_perms]^7 synchronisation Discord désactivée')
        return
    end

    local problems = {}

    if Config.Discord.token == ''   then problems[#problems+1] = 'jeton du bot' end
    if Config.Discord.guildId == '' then problems[#problems+1] = 'identifiant du serveur' end

    local configured = 0
    for _, r in ipairs(Config.Discord.roles) do
        if r.roleId ~= '' then configured = configured + 1 end
    end

    if configured == 0 then problems[#problems+1] = 'aucun rôle renseigné' end

    if #problems > 0 then
        print(('^1[rz_perms]^7 Discord incomplet : %s')
            :format(table.concat(problems, ', ')))
    else
        print(('^2[rz_perms]^7 synchronisation Discord active — %d rôle(s)')
            :format(configured))
    end
end)
