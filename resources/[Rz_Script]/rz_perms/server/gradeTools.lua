--[[
    rz_perms / server/gradeTools.lua

    Permissions du menu F5, éditables par grade depuis l'onglet
    Équipe → Permissions du menu.

    COMMENT ÇA MARCHE
    rz_grade_tools (base de données) dit, pour chaque grade éditable
    (admin, modérateur, support) et chaque outil du F5, s'il est
    activé. Au démarrage, et à chaque bascule du fondateur, on
    traduit ça en add_ace / remove_ace sur le groupe du grade — les
    mêmes commandes que server.cfg, mais appliquées en direct.

    POURQUOI UN DÉLAI AU DÉMARRAGE
    server.cfg pose ses propres add_ace tout en bas du fichier, APRÈS
    tous les `ensure`. Si on réapplique nos droits trop tôt, ces
    lignes les écrasent juste après. Le délai laisse le temps à
    server.cfg de finir de se dérouler avant qu'on reprenne la main —
    après quoi c'est la base qui a le dernier mot, à chaque
    démarrage suivant.

    LE DÉVELOPPEUR N'EST JAMAIS TOUCHÉ
    Config.EditableGrades ne le contient pas : il garde tout, tel que
    server.cfg le définit, sans exception.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_perms]^7', ...) end
end


local function canManage(source)
    return IsPlayerAceAllowed(source, 'rz_perms.manage')
end


local function isEditableGrade(grade)
    for _, g in ipairs(Config.EditableGrades) do
        if g == grade then return true end
    end
    return false
end


local function toolExists(toolId)
    for _, tool in ipairs(Config.Tools) do
        if tool.id == toolId then return true end
    end
    return false
end


---Applique add_ace ou remove_ace pour CE grade et CET outil.
local function applyOne(grade, toolId, enabled)
    local perms = Config.PermsFor(toolId)
    if #perms == 0 then return end

    local group = ('group.%s'):format(grade)
    local verb  = enabled and 'add_ace' or 'remove_ace'

    for _, perm in ipairs(perms) do
        ExecuteCommand(('%s %s %s allow'):format(verb, group, perm))
    end
end


---Relit toute la table et réapplique tout. Appelé au démarrage.
local function applyAll()
    local rows = MySQL.query.await(
        'SELECT grade, tool_id, enabled FROM rz_grade_tools') or {}

    local applied = 0

    for _, row in ipairs(rows) do
        if isEditableGrade(row.grade) and toolExists(row.tool_id) then
            applyOne(row.grade, row.tool_id, row.enabled == 1)
            applied = applied + 1
        end
    end

    dbg(('%d permission(s) de grade réappliquée(s)'):format(applied))
end


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Laisse server.cfg finir de dérouler ses propres add_ace, tout
    -- en bas du fichier, avant de reprendre la main dessus.
    SetTimeout(5000, applyAll)
end)


-- ═══════════════════════════════════════════════════════════════════
--  PANNEAU DU FONDATEUR
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_perms:getGradeTools', function(source)
    if not canManage(source) then return nil end

    local rows = MySQL.query.await(
        'SELECT grade, tool_id, enabled FROM rz_grade_tools') or {}

    -- [grade][toolId] = enabled
    local state = {}
    for _, grade in ipairs(Config.EditableGrades) do
        state[grade] = {}
    end

    for _, row in ipairs(rows) do
        if state[row.grade] then
            state[row.grade][row.tool_id] = row.enabled == 1
        end
    end

    local tools = {}
    for _, tool in ipairs(Config.Tools) do
        tools[#tools + 1] = {
            id    = tool.id,
            label = tool.label,
            icon  = tool.icon,
        }
    end

    return {
        grades = Config.EditableGrades,
        tools  = tools,
        state  = state,
    }
end)


lib.callback.register('rz_perms:setGradeTool', function(source, grade, toolId, enabled)
    if not canManage(source) then
        return false, 'Permission rz_perms.manage requise.'
    end

    if not isEditableGrade(grade) then
        return false, ('Grade « %s » non éditable ici.'):format(tostring(grade))
    end

    if not toolExists(toolId) then
        return false, ('Outil « %s » inconnu.'):format(tostring(toolId))
    end

    MySQL.prepare.await([[
        INSERT INTO rz_grade_tools (grade, tool_id, enabled, updated_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            enabled = VALUES(enabled),
            updated_by = VALUES(updated_by)
    ]], { grade, toolId, enabled and 1 or 0, GetPlayerName(source) })

    applyOne(grade, toolId, enabled)

    local g = Config.GetGrade(grade)
    local toolLabel

    for _, tool in ipairs(Config.Tools) do
        if tool.id == toolId then toolLabel = tool.label break end
    end

    dbg(('%s : %s → %s pour %s'):format(
        GetPlayerName(source) or source, toolLabel or toolId,
        enabled and 'activé' or 'désactivé', g and g.label or grade))

    return true, ('%s %s pour %s.'):format(
        toolLabel or toolId,
        enabled and 'activé' or 'désactivé',
        g and g.label or grade)
end)
