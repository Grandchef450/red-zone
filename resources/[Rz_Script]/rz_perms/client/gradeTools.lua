--[[
    rz_perms / client/gradeTools.lua

    Onglet « Permissions du menu » : le fondateur active ou
    désactive, grade par grade, chaque bouton du F5. Ouvert depuis
    le menu Équipe (client/staff.lua).
]]

function OpenPermissionsMenu()
    local data = lib.callback.await('rz_perms:getGradeTools', false)

    if not data then
        return lib.notify({
            type        = 'error',
            title       = 'Accès refusé',
            description = 'Seuls les développeurs gèrent ces permissions.',
        })
    end

    local options = {}

    for _, grade in ipairs(data.grades) do
        local g = Config.GetGrade(grade)
        local state = data.state[grade] or {}

        local enabledCount = 0
        for _, tool in ipairs(data.tools) do
            if state[tool.id] then enabledCount = enabledCount + 1 end
        end

        options[#options + 1] = {
            title       = g and g.label or grade,
            description = ('%d/%d outil(s) activé(s)'):format(enabledCount, #data.tools),
            icon        = 'fas fa-sliders',
            arrow       = true,
            onSelect    = function() GradeToolsMenu(grade, data) end,
        }
    end

    lib.registerContext({
        id      = 'rz_perms_menu',
        title   = 'Permissions du menu F5',
        menu    = 'rz_staff_menu',
        options = options,
    })

    lib.showContext('rz_perms_menu')
end


function GradeToolsMenu(grade, data)
    local g = Config.GetGrade(grade)
    local state = data.state[grade] or {}
    local options = {}

    for _, tool in ipairs(data.tools) do
        local on = state[tool.id] or false

        options[#options + 1] = {
            title       = tool.label,
            description = on and 'Activé — visible pour ce grade'
                             or  'Désactivé — grisé pour ce grade',
            icon        = tool.icon,
            iconColor   = on and '#4ade80' or '#6b7280',
            onSelect    = function()
                local ok, msg = lib.callback.await(
                    'rz_perms:setGradeTool', false, grade, tool.id, not on)

                lib.notify({
                    type        = ok and 'success' or 'error',
                    description = msg,
                    duration    = 6000,
                })

                if ok then
                    data.state[grade][tool.id] = not on
                    Wait(200)
                    GradeToolsMenu(grade, data)
                end
            end,
        }
    end

    lib.registerContext({
        id      = 'rz_perms_grade_' .. grade,
        title   = ('Permissions — %s'):format(g and g.label or grade),
        menu    = 'rz_perms_menu',
        options = options,
    })

    lib.showContext('rz_perms_grade_' .. grade)
end
