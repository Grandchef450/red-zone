--[[
    rz_craft / server/mailbox.lua
    Boîte aux lettres personnelle.

    Une boîte physique par safe zone, mais chaque joueur n'y voit
    que son propre courrier : le filtrage se fait sur citizenid côté
    serveur, jamais côté client.

    Les colis n'expirent pas. En contrepartie, une ligne est
    SUPPRIMÉE dès qu'elle est récupérée — sinon la table gonflerait
    indéfiniment. La trace reste dans rz_craft_logs.
]]

---Dépose un colis pour un personnage.
---@param citizenid number
---@param data table { label, reason, contents = { {item, qty}, ... }, created_by? }
---@return number|nil parcelId
function SendParcel(citizenid, data)
    if not citizenid or not data or not data.contents or #data.contents == 0 then
        return nil
    end

    local id = MySQL.insert.await([[
        INSERT INTO rz_mailbox (citizenid, label, reason, contents, created_by)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        citizenid,
        data.label or 'Colis',
        data.reason or 'autre',
        json.encode(data.contents),
        data.created_by,
    })

    -- Notification si le joueur est en ligne
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if GetCharId(src) == citizenid then
            TriggerClientEvent('ox_lib:notify', src, {
                type        = 'inform',
                title       = 'Nouveau colis',
                description = 'Un colis t\'attend à la boîte aux lettres.',
                duration    = 8000,
            })
            break
        end
    end

    return id
end

exports('SendParcel', SendParcel)


---Liste les colis en attente du joueur.
lib.callback.register('rz_craft:getMail', function(source, pointId)
    local citizenid = GetCharId(source)
    if not citizenid then return {} end

    -- Vérification de proximité : on ne consulte pas son courrier
    -- depuis l'autre bout de la carte.
    local point = Cache.mailPoints[pointId]
    if not point then return {} end

    local ped = GetPlayerPed(source)
    local dist = #(GetEntityCoords(ped) - vec3(point.x, point.y, point.z))
    if dist > 3.0 then return {} end

    local rows = MySQL.query.await([[
        SELECT id, label, reason, contents, created_at
        FROM rz_mailbox
        WHERE citizenid = ? AND claimed_at IS NULL
        ORDER BY created_at ASC
        LIMIT ?
    ]], { citizenid, Config.Mailbox.maxParcelsShown }) or {}

    for _, r in ipairs(rows) do
        r.contents = json.decode(r.contents)
    end

    return rows
end)


---Récupère un colis.
lib.callback.register('rz_craft:claimParcel', function(source, parcelId, pointId)
    local citizenid = GetCharId(source)
    if not citizenid then return false, 'Personnage introuvable.' end

    local point = Cache.mailPoints[pointId]
    if not point then return false, 'Boîte introuvable.' end

    local ped = GetPlayerPed(source)
    local dist = #(GetEntityCoords(ped) - vec3(point.x, point.y, point.z))
    if dist > 3.0 then return false, 'Trop loin de la boîte aux lettres.' end

    -- Le filtre sur citizenid est ce qui empêche d'ouvrir le courrier
    -- d'un autre joueur en envoyant un id arbitraire.
    local parcel = MySQL.single.await([[
        SELECT id, label, contents FROM rz_mailbox
        WHERE id = ? AND citizenid = ? AND claimed_at IS NULL
    ]], { parcelId, citizenid })

    if not parcel then return false, 'Colis introuvable.' end

    local contents = json.decode(parcel.contents)

    -- Vérifie que tout rentre AVANT de donner quoi que ce soit
    for _, entry in ipairs(contents) do
        if not exports.ox_inventory:CanCarryItem(source, entry.item, entry.qty) then
            return false, 'Pas assez de place dans ton inventaire.'
        end
    end

    for _, entry in ipairs(contents) do
        exports.ox_inventory:AddItem(source, entry.item, entry.qty)
    end

    MySQL.prepare.await('DELETE FROM rz_mailbox WHERE id = ?', { parcel.id })

    LogAction(citizenid, 'mail_claim', { parcel = parcel.label, contents = contents })

    return true, parcel.label
end)


---Nombre de colis en attente — pour l'indicateur sur le blip.
lib.callback.register('rz_craft:getMailCount', function(source)
    local citizenid = GetCharId(source)
    if not citizenid then return 0 end

    local row = MySQL.single.await(
        'SELECT COUNT(*) AS n FROM rz_mailbox WHERE citizenid = ? AND claimed_at IS NULL',
        { citizenid })

    return row and row.n or 0
end)


-- ═══════════════════════════════════════════════════════════════════
--  COMMANDE STAFF
--  Sur rz_craft.mail, pas rz_craft.admin : le support doit pouvoir
--  compenser un joueur sans avoir accès à l'édition des recettes.
--  Déposer un colis à un joueur (compensation, événement, bug).
--  Usage : /colis <id joueur> <item> <quantité> [libellé]
-- ═══════════════════════════════════════════════════════════════════

lib.addCommand('colis', {
    help = 'Déposer un colis dans la boîte aux lettres d\'un joueur',
    params = {
        { name = 'target', type = 'playerId', help = 'ID du joueur' },
        { name = 'item',   type = 'string',   help = 'Nom technique de l\'item' },
        { name = 'qty',    type = 'number',   help = 'Quantité' },
        { name = 'label',  type = 'string',   help = 'Libellé du colis', optional = true },
    },
    restricted = Config.Ace.mail,
}, function(source, args)
    local citizenid = GetCharId(args.target)
    if not citizenid then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error', description = 'Joueur introuvable.' })
    end

    SendParcel(citizenid, {
        label      = args.label or 'Compensation du staff',
        reason     = 'compensation',
        contents   = { { item = args.item, qty = args.qty } },
        created_by = GetPlayerIdentifier(source, 0),
    })

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = ('Colis déposé : %d× %s'):format(args.qty, args.item),
    })
end)
