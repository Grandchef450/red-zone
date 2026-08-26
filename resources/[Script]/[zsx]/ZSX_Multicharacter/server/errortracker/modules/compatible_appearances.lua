local function check()
    local appearance = Config.ForceAppereance ~= false and Config.ForceAppereance or (GetResourceState('skinchanger') == 'started' and 'skinchanger' or GetResourceState('skinchanger') == 'fivem-appearance' and 'fivem-appearance' or GetResourceState('illenium-appearance') == 'started' and 'illenium-appearance' or GetResourceState('qb-clothing') == 'started' and 'qb-clothing' or GetResourceState('crm-appearance') == 'started' and 'crm-appearance' or GetResourceState('bl_appearance') == 'started' and 'bl_appearance' or GetResourceState('tgiann-clothing') == 'started' and 'tgiann-clothing'  or GetResourceState('rcore_clothing') == 'started' and 'rcore_clothing') or false
    return appearance and (GetResourceState(appearance) == 'started' and appearance) or false
end

return check