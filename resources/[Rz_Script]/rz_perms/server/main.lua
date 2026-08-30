--[[
    rz_perms / server/main.lua

    Décide quels boutons du menu admin un joueur peut voir.

    CE QUE CE SCRIPT NE FAIT PAS
    Il ne protège rien. Chaque ressource rz_ vérifie déjà sa propre
    permission côté serveur, et c'est cette vérification-là qui
    compte. Ici on ne fait que masquer ce qui serait de toute façon
    refusé : un bouton qu'on clique pour lire « accès refusé » est
    simplement désagréable.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_perms]^7', ...) end
end


---Le joueur a-t-il au moins un des droits listés ?
local function hasAny(source, perms)
    for _, p in ipairs(perms or {}) do
        if IsPlayerAceAllowed(source, p) then return true end
    end
    return false
end


---Outils du menu, avec pour chacun le droit du joueur.
---
---On renvoie TOUS les outils, pas seulement les autorisés : le
---menu les affiche grisés. Le joueur voit ainsi ce qui existe et
---comprend qu'il lui manque un grade, sans qu'on ait à le lui dire.
local function toolsFor(source)
    local out = {}

    for _, tool in ipairs(Config.Tools) do
        -- Un outil dont la ressource ne tourne pas n'existe pas :
        -- l'afficher grisé laisserait croire à un manque de droits.
        if GetResourceState(tool.resource) == 'started' then
            out[#out + 1] = {
                id       = tool.id,
                resource = tool.resource,
                callback = tool.callback,
                label    = tool.label,
                icon     = tool.icon,
                allowed  = hasAny(source, tool.perms),
            }
        end
    end

    return out
end


---Nombre d'outils réellement accessibles.
local function countAllowed(tools)
    local n = 0
    for _, t in ipairs(tools) do
        if t.allowed then n = n + 1 end
    end
    return n
end


lib.callback.register('rz_perms:getTools', function(source)
    local tools = toolsFor(source)
    local allowed = countAllowed(tools)

    dbg(('%s : %d/%d outil(s) accessible(s)')
        :format(GetPlayerName(source) or source, allowed, #tools))

    return {
        tools     = tools,
        style     = Config.UnauthorizedStyle or 'grise',
        -- Pas de titre « REDZONE » pour un joueur qui n'a rien :
        -- inutile de lui montrer une section entièrement grise.
        separator = Config.ShowSeparator and allowed > 0,
    }
end)


---Grade estimé d'un joueur, d'après ses droits réels.
lib.callback.register('rz_perms:getMyGrade', function(source)
    local found

    -- On teste dans l'ordre du fichier, du plus élevé au plus bas :
    -- le premier grade dont TOUS les droits sont accordés est le sien.
    for _, g in ipairs(Config.Grades) do
        local complete = true

        for _, p in ipairs(g.perms) do
            if not IsPlayerAceAllowed(source, p) then
                complete = false
                break
            end
        end

        if complete then
            found = g
            break
        end
    end

    local granted = {}
    for _, tool in ipairs(Config.Tools) do
        for _, p in ipairs(tool.perms) do
            if IsPlayerAceAllowed(source, p) then
                granted[#granted + 1] = tool.label
                break
            end
        end
    end

    return {
        grade   = found and found.label or nil,
        note    = found and found.note or nil,
        granted = granted,
    }
end)


-- ═══════════════════════════════════════════════════════════════════
--  DIAGNOSTIC
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('grade', {
    help = 'Afficher ton grade et tes accès RedZone',
}, function(source)
    local all = toolsFor(source)
    local tools = {}

    for _, t in ipairs(all) do
        if t.allowed then tools[#tools + 1] = t end
    end

    if #tools == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type        = 'inform',
            title       = 'Aucun accès',
            description = 'Tu n\'as aucune permission RedZone.',
        })
    end

    local names = {}
    for _, t in ipairs(tools) do names[#names + 1] = t.label end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header   = 'Tes accès RedZone',
        content  = ('**%d outil(s)**  \n\n%s'):format(#tools, table.concat(names, '  \n')),
        centered = true,
    })
end)


---Compare un joueur aux grades prévus. Sert à repérer un écart
---entre ce qui est écrit dans server.cfg et ce qui est réellement
---accordé — la source d'erreur la plus fréquente avec les ACE.
lib.addCommand('gradecheck', {
    help = 'Comparer un joueur aux grades prévus',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
    },
    restricted = 'rz.staff',
}, function(source, args)
    local lines = {}

    for _, g in ipairs(Config.Grades) do
        local ok, total = 0, #g.perms

        for _, p in ipairs(g.perms) do
            if IsPlayerAceAllowed(args.target, p) then ok = ok + 1 end
        end

        local mark = ok == total and '✓' or (ok == 0 and '·' or '~')
        lines[#lines + 1] = ('%s **%s** — %d/%d droits')
            :format(mark, g.label, ok, total)
    end

    TriggerClientEvent('ox_lib:alertDialog', source, {
        header  = ('Grades de %s'):format(GetPlayerName(args.target) or '?'),
        content = table.concat(lines, '  \n')
            .. '  \n\n`✓` complet · `~` partiel · `·` aucun',
        centered = true,
    })
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Un outil déclaré dont la ressource n'existe pas est une faute
    -- de frappe. Autant le dire au démarrage plutôt que de laisser
    -- un bouton disparaître sans explication.
    for _, tool in ipairs(Config.Tools) do
        if GetResourceState(tool.resource) == 'missing' then
            print(('^3[rz_perms]^7 outil « %s » : ressource « %s » introuvable')
                :format(tool.label, tool.resource))
        end
    end
end)
