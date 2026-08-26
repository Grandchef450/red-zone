local function check()
    local multicharacters = {'esx_multicharacter', 'qb-multicharacter', 'um-multicharacter', 'vms_multichars', 'codem-multicharacter', '0r-multicharacter', 'qs-multicharacter', 'crm-multicharacter'}
    local isOtherMulticharacterRunning = false
    for _, multicharacter in ipairs(multicharacters) do
        if GetResourceState(multicharacter) == 'started' then
            isOtherMulticharacterRunning = multicharacter
            break
        end
    end
    return {
        state = isOtherMulticharacterRunning == false,
        name = isOtherMulticharacterRunning
    }
end

return check