--[[
    rz_perms / server/staff.lua

    Grades gérés en base, attribués depuis le menu F5.

    POURQUOI CETTE VOIE PLUTÔT QUE DISCORD
    Aucun jeton à protéger, aucune dépendance externe. Si Discord
    tombe ou qu'un bot est révoqué, ton staff garde ses accès.

    COMMENT ÇA MARCHE
    À la connexion, on lit le grade du joueur en base et on lui
    accorde le groupe correspondant avec add_principal. Ce groupe
    n'existe que le temps de la session : rien n'est écrit dans le
    server.cfg, donc rien à nettoyer.

    Les deux voies cohabitent : si la synchronisation Discord est
    active, elle s'applique aussi. La base a le dernier mot, parce
    qu'elle est appliquée après.
]]

-- [license] = grade actuellement accordé en session
local applied = {}

local function dbg(...)
    if Config.Debug then print('^3[rz_perms]^7', ...) end
end


local function licenseOf(source)
    return GetPlayerIdentifierByType(source, 'license')
end


---Accorde ou retire un groupe pour la session en cours.
local function setPrincipal(license, grade)
    local identifier = 'identifier.' .. license
    local previous = applied[license]

    -- On retire l'ancien avant de poser le nouveau, sinon un
    -- rétrogradé cumulerait ses deux grades.
    if previous and previous ~= grade then
        local g = Config.GetGrade(previous)
        if g then
            ExecuteCommand(('remove_principal %s %s'):format(identifier, g.group))
        end
    end

    if not grade then
        applied[license] = nil
        return
    end

    local g = Config.GetGrade(grade)
    if not g then
        print(('^1[rz_perms]^7 grade « %s » inconnu dans Config.Grades'):format(grade))
        return
    end

    ExecuteCommand(('add_principal %s %s'):format(identifier, g.group))
    applied[license] = grade
end


---Applique le grade enregistré en base pour un joueur.
function ApplyStaffGrade(source)
    local license = licenseOf(source)
    if not license then return end

    local row = MySQL.single.await(
        'SELECT grade FROM rz_staff WHERE license = ?', { license })

    setPrincipal(license, row and row.grade or nil)

    if row then
        dbg(('%s : grade %s appliqué depuis la base')
            :format(GetPlayerName(source) or source, row.grade))
    end
end


AddEventHandler('playerJoining', function()
    local src = source
    -- Un léger délai : les identifiants ne sont pas tous disponibles
    -- à l'instant précis de la connexion.
    SetTimeout(2000, function()
        if GetPlayerName(src) then ApplyStaffGrade(src) end
    end)
end)


-- ═══════════════════════════════════════════════════════════════════
--  JOURNAL
-- ═══════════════════════════════════════════════════════════════════

local function logChange(action, target, oldGrade, newGrade, byLicense, byName)
    MySQL.prepare([[
        INSERT INTO rz_staff_logs
            (license, name, action, old_grade, new_grade, by_license, by_name)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { target.license, target.name, action, oldGrade, newGrade, byLicense, byName })

    if GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log('admin', {
                title  = ('Grade %s — %s'):format(action, target.name or '?'),
                fields = {
                    { name = 'Avant',  value = oldGrade or 'aucun' },
                    { name = 'Après',  value = newGrade or 'aucun' },
                    { name = 'Par',    value = byName or '?' },
                    { name = 'Licence', value = ('`%s`'):format(target.license) },
                },
            })
        end)
    end
end


-- ═══════════════════════════════════════════════════════════════════
--  DROIT DE GÉRER LES GRADES
--
--  Volontairement réservé au droit le plus élevé : accorder un
--  grade, c'est pouvoir s'accorder tous les autres. Un modérateur
--  qui pourrait promouvoir contournerait toute la hiérarchie.
-- ═══════════════════════════════════════════════════════════════════

-- ⚠️  Uniquement rz_perms.manage. Le repli sur rz_craft.admin
-- contredisait le commentaire ci-dessus : server.cfg accorde
-- rz_craft.admin à group.admin, donc n'importe quel admin pouvait
-- accorder n'importe quel grade — y compris développeur — à
-- n'importe qui. C'est exactement ce que ce droit doit empêcher.
local function canManage(source)
    return IsPlayerAceAllowed(source, 'rz_perms.manage')
end


lib.callback.register('rz_perms:canManage', function(source)
    return canManage(source)
end)


-- ═══════════════════════════════════════════════════════════════════
--  LECTURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_perms:getStaff', function(source)
    if not canManage(source) then return {} end

    local rows = MySQL.query.await([[
        SELECT license, name, grade, granted_by, note, granted_at
        FROM rz_staff ORDER BY grade ASC, name ASC
    ]]) or {}

    -- Qui est connecté en ce moment : pratique pour agir tout de suite
    local online = {}
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local lic = licenseOf(src)
        if lic then online[lic] = src end
    end

    for _, r in ipairs(rows) do
        r.online = online[r.license] or nil
        local g = Config.GetGrade(r.grade)
        r.gradeLabel = g and g.label or r.grade
    end

    return rows
end)


---Joueurs connectés, pour en promouvoir un sans saisir sa licence.
lib.callback.register('rz_perms:getOnline', function(source)
    if not canManage(source) then return {} end

    local out = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local lic = licenseOf(src)

        if lic then
            out[#out + 1] = {
                value = lic,
                label = ('[%d] %s'):format(src, GetPlayerName(src) or '?'),
                name  = GetPlayerName(src),
                id    = src,
            }
        end
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)


lib.callback.register('rz_perms:getGrades', function(source)
    if not canManage(source) then return {} end

    local out = {}
    for _, g in ipairs(Config.Grades) do
        out[#out + 1] = { value = g.key, label = g.label }
    end
    return out
end)


-- ═══════════════════════════════════════════════════════════════════
--  ÉCRITURE
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_perms:setGrade', function(source, license, name, grade, note)
    if not canManage(source) then
        return false, 'Permission rz_perms.manage requise.'
    end

    if not license or license == '' then
        return false, 'Licence manquante.'
    end

    if not Config.GetGrade(grade) then
        return false, ('Grade « %s » inconnu.'):format(tostring(grade))
    end

    local byLicense = licenseOf(source)
    local byName = GetPlayerName(source)

    -- On ne se rétrograde pas soi-même par accident : c'est le genre
    -- d'erreur qui verrouille tout le monde dehors.
    if license == byLicense then
        return false, 'Tu ne peux pas modifier ton propre grade.'
    end

    local existing = MySQL.single.await(
        'SELECT grade, name FROM rz_staff WHERE license = ?', { license })

    MySQL.prepare.await([[
        INSERT INTO rz_staff (license, name, grade, granted_by, note)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            grade = VALUES(grade),
            granted_by = VALUES(granted_by),
            note = VALUES(note)
    ]], { license, name, grade, byLicense, note })

    logChange(existing and 'modifie' or 'accorde',
        { license = license, name = name },
        existing and existing.grade or nil, grade, byLicense, byName)

    -- Application immédiate si la personne est en jeu : inutile de
    -- lui demander de se reconnecter.
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if licenseOf(src) == license then
            setPrincipal(license, grade)

            TriggerClientEvent('ox_lib:notify', src, {
                type        = 'inform',
                title       = 'Grade mis à jour',
                description = ('Tu es désormais %s.')
                    :format(Config.GetGrade(grade).label),
                duration    = 10000,
            })
            break
        end
    end

    return true, ('Grade %s accordé à %s.')
        :format(Config.GetGrade(grade).label, name or license)
end)


lib.callback.register('rz_perms:removeGrade', function(source, license)
    if not canManage(source) then
        return false, 'Permission rz_perms.manage requise.'
    end

    if license == licenseOf(source) then
        return false, 'Tu ne peux pas retirer ton propre grade.'
    end

    local existing = MySQL.single.await(
        'SELECT grade, name FROM rz_staff WHERE license = ?', { license })

    if not existing then return false, 'Ce joueur n\'a aucun grade.' end

    MySQL.prepare.await('DELETE FROM rz_staff WHERE license = ?', { license })

    logChange('retire', { license = license, name = existing.name },
        existing.grade, nil, licenseOf(source), GetPlayerName(source))

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if licenseOf(src) == license then
            setPrincipal(license, nil)

            TriggerClientEvent('ox_lib:notify', src, {
                type        = 'error',
                title       = 'Grade retiré',
                description = 'Tes accès staff ont été révoqués.',
                duration    = 10000,
            })
            break
        end
    end

    return true, ('Grade retiré à %s.'):format(existing.name or license)
end)


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(2000)

    -- Les joueurs déjà connectés au moment d'un restart de la
    -- ressource doivent retrouver leurs droits sans se reconnecter.
    for _, playerId in ipairs(GetPlayers()) do
        ApplyStaffGrade(tonumber(playerId))
    end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM rz_staff')

    if not count or count == 0 then
        print('^3[rz_perms]^7 aucun membre du staff en base.')
        print('^3[rz_perms]^7 Insère au moins un développeur : voir rz_perms_schema.sql')
    else
        print(('^2[rz_perms]^7 %d membre(s) du staff en base'):format(count))
    end
end)
