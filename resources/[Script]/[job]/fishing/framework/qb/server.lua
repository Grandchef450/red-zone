-- ═══════════════════════════════════════════════════════════════
--  CORRIGÉ POUR QBOX — RedZone
--
--  Ce fichier ne se chargeait que si une ressource nommée
--  « qb-core » tournait. Qbox s'appelle « qbx_core » : il publie
--  bien les exports sous le nom qb-core via son pont intégré, mais
--  aucune RESSOURCE ne porte ce nom. Le test échouait donc, et tout
--  le pont se désactivait en silence.
--
--  On accepte désormais les deux noms. Le reste du fichier continue
--  d'appeler exports['qb-core'], ce qui fonctionne grâce à Qbox.
-- ═══════════════════════════════════════════════════════════════

if GetResourceState('qb-core') ~= 'started'
   and GetResourceState('qbx_core') ~= 'started' then return end

Framework = { name = 'qb-core' }
local sharedObject = exports['qb-core']:GetCoreObject()
QBCore = sharedObject
local player = {}

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getPlayerFromId(id)
    local player = setmetatable({}, { __index = player })
    player.QBPlayer = sharedObject.Functions.GetPlayer(id)
    if not player.QBPlayer then return end
    player.source = id

    return player
end

Framework.registerUsableItem = sharedObject.Functions.CreateUseableItem

Framework.getPlayers = sharedObject.Functions.GetQBPlayers

local ox_inventory = GetResourceState('ox_inventory') == 'started'
local qs_inventory = GetResourceState('qs-inventory') == 'started'

function Framework.getItemLabel(item)
    if ox_inventory then
        return exports.ox_inventory:Items()[item]?.label
    elseif qs_inventory then
        return exports['qs-inventory']:GetItemList()[item]?.label
    end
    return sharedObject.Shared.Items[item]?.label
end

function Framework.getItems()
    if ox_inventory then
        return exports.ox_inventory:Items()
    elseif qs_inventory then
        return exports['qs-inventory']:GetItemList()
    end
    return sharedObject.Shared.Items
end

function player:hasGroup(name)
    return sharedObject.Functions.HasPermission(self.source, name) == name
end

function player:hasOneOfGroups(groups)
    for k,v in pairs(groups) do
        if sharedObject.Functions.HasPermission(self.source, k) then
            return true
        end
    end

    return false
end

function player:addItem(name, count)
    self.QBPlayer.Functions.AddItem(name, count or 1)
end

function player:removeItem(name, count)
    self.QBPlayer.Functions.RemoveItem(name, count or 1)
end

function player:canCarryItem(name, count)
    return true
end

function player:getItemCount(name)
    return self.QBPlayer.Functions.GetItemByName(name)?.amount or 0
end

function player:getAccountMoney(account)
    if account == 'money' then
        return self.QBPlayer.Functions.GetMoney('cash')
    else
        return self.QBPlayer.Functions.GetMoney(account)
    end
end

function player:addAccountMoney(account, amount)
    if account == 'money' then
        self.QBPlayer.Functions.AddMoney('cash', amount)
    else
        self.QBPlayer.Functions.AddMoney(account, amount)
    end
end

function player:removeAccountMoney(account, amount)
    if account == 'money' then
        self.QBPlayer.Functions.RemoveMoney('cash', amount)
    else
        self.QBPlayer.Functions.RemoveMoney(account, amount)
    end
end

function player:getJob()
    return self.QBPlayer.PlayerData.job.name
end

function player:getIdentifier()       
    return self.QBPlayer.PlayerData.citizenid
end

function player:getFirstName()
    return self.QBPlayer.PlayerData.charinfo.firstname
end

function player:getLastName()
    return self.QBPlayer.PlayerData.charinfo.lastname
end