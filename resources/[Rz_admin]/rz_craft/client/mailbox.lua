--[[
    rz_craft / client/mailbox.lua
    Boîte aux lettres : consultation et retrait des colis.

    Le client n'affiche que ce que le serveur lui envoie, et le
    serveur ne renvoie que le courrier du personnage connecté.
]]

local REASON_LABELS = {
    craft_annule       = 'Craft annulé',
    craft_crash        = 'Redémarrage serveur',
    craft_deconnexion  = 'Déconnexion',
    compensation       = 'Compensation',
    evenement          = 'Événement',
    autre              = 'Colis',
}

local REASON_ICONS = {
    craft_annule       = 'fas fa-ban',
    craft_crash        = 'fas fa-server',
    craft_deconnexion  = 'fas fa-plug',
    compensation       = 'fas fa-gift',
    evenement          = 'fas fa-star',
    autre              = 'fas fa-box',
}


local function describeContents(contents)
    local lines = {}
    for _, entry in ipairs(contents) do
        lines[#lines + 1] = ('· %s ×%d'):format(entry.item, entry.qty)
    end
    return table.concat(lines, '  \n')
end


function OpenMailbox(pointId)
    local parcels = lib.callback.await('rz_craft:getMail', false, pointId)

    if not parcels or #parcels == 0 then
        return lib.notify({
            type        = 'inform',
            title       = 'Boîte aux lettres',
            description = 'Aucun colis en attente.',
        })
    end

    local options = {}

    for _, parcel in ipairs(parcels) do
        options[#options + 1] = {
            title       = parcel.label,
            description = ('%s\n%s')
                :format(REASON_LABELS[parcel.reason] or 'Colis',
                        describeContents(parcel.contents)),
            icon        = REASON_ICONS[parcel.reason] or 'fas fa-box',
            onSelect    = function()
                ClaimParcel(parcel.id, pointId)
            end,
        }
    end

    -- Retrait groupé, pratique après un redémarrage serveur
    if #parcels > 1 then
        table.insert(options, 1, {
            title       = ('Tout récupérer (%d colis)'):format(#parcels),
            icon        = 'fas fa-boxes-stacked',
            iconColor   = '#4ade80',
            onSelect    = function()
                ClaimAll(parcels, pointId)
            end,
        })
    end

    lib.registerContext({
        id      = 'rz_mailbox',
        title   = ('Courrier (%d)'):format(#parcels),
        options = options,
    })

    lib.showContext('rz_mailbox')
end


function ClaimParcel(parcelId, pointId)
    local ok, result = lib.callback.await('rz_craft:claimParcel', false, parcelId, pointId)

    lib.notify({
        type        = ok and 'success' or 'error',
        title       = ok and 'Colis récupéré' or 'Impossible',
        description = result,
        duration    = 5000,
    })

    if ok then
        Wait(300)
        OpenMailbox(pointId)   -- rafraîchit la liste
    end
end


function ClaimAll(parcels, pointId)
    local claimed, failed = 0, 0

    for _, parcel in ipairs(parcels) do
        local ok = lib.callback.await('rz_craft:claimParcel', false, parcel.id, pointId)
        if ok then
            claimed = claimed + 1
        else
            failed = failed + 1
            break   -- inventaire plein : inutile d'insister
        end
        Wait(120)   -- laisse respirer le serveur
    end

    local desc = ('%d colis récupéré(s).'):format(claimed)
    if failed > 0 then
        desc = desc .. '\nLes autres attendent : ton inventaire est plein.'
    end

    lib.notify({
        type        = claimed > 0 and 'success' or 'error',
        title       = 'Boîte aux lettres',
        description = desc,
        duration    = 6000,
    })
end


-- Indicateur de courrier en attente à la connexion
CreateThread(function()
    Wait(15000)

    local count = lib.callback.await('rz_craft:getMailCount', false)
    if count and count > 0 then
        lib.notify({
            type        = 'inform',
            title       = 'Courrier en attente',
            description = ('%d colis t\'attend%s à la boîte aux lettres.')
                :format(count, count > 1 and 'ent' or ''),
            duration    = 10000,
        })
    end
end)
