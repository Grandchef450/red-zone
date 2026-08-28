function GetPlayer(src)
    if Config.Framework == "esx" then
        return ESX.GetPlayerFromId(src)
    elseif Config.Framework == "qb" then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end

function GetPlayerGroup(source)
    if not source or source == 0 then return nil end
    local player = GetPlayer(source)
    if not player then return nil end

    if Config.Framework == "esx" and player.getGroup then
        return player.getGroup()
    end
    if Config.Framework == "qb" and QBCore and QBCore.Functions and QBCore.Functions.GetPlayerGroup then
        local group = QBCore.Functions.GetPlayerGroup(source)
        if group and tostring(group):gsub("^%s+", ""):gsub("%s+$", "") ~= "" then
            return (tostring(group)):lower()
        end
        return nil
    end
    return nil
end

function SetPlayerGroup(targetId, groupName)
    if not targetId or targetId == 0 or not groupName or tostring(groupName) == "" then return end
    local player = GetPlayer(targetId)
    if not player then return end
    if Config.Framework == "esx" and player.setGroup then
        player.setGroup(groupName)
    elseif Config.Framework == "qb" and QBCore and QBCore.Functions and QBCore.Functions.SetPlayerGroup then
        QBCore.Functions.SetPlayerGroup(targetId, groupName)
    end
end

function GetIdentifier(xPlayer)
    if Config.Framework == "esx" then
        return xPlayer.identifier
    elseif Config.Framework == "qb" then
        return xPlayer.PlayerData.citizenid
    end
    return nil
end

function SetPlayerMoney(targetId, moneyType, amount)
    if not targetId or not amount or amount < 1 then return end
    local player = GetPlayer(targetId)
    if not player then return end
    moneyType = (moneyType == "bank") and "bank" or (moneyType == "black_money") and "black_money" or "cash"
    if Config.Framework == "esx" then
        if moneyType == "cash" then
            player.addMoney(amount)
        elseif moneyType == "black_money" then
            player.addAccountMoney("black_money", amount)
        else
            player.addAccountMoney("bank", amount)
        end
    elseif Config.Framework == "qb" then
        player.Functions.AddMoney(moneyType, amount)
    end
end

function RemovePlayerMoney(targetId, moneyType, amount)
    if not targetId or targetId == 0 or not amount or amount < 1 then return end
    local player = GetPlayer(targetId)
    if not player then return end
    moneyType = (moneyType == "bank") and "bank" or (moneyType == "black_money") and "black_money" or "cash"
    if Config.Framework == "esx" then
        if moneyType == "cash" then
            player.removeMoney(amount)
        elseif moneyType == "black_money" then
            player.removeAccountMoney("black_money", amount)
        else
            player.removeAccountMoney("bank", amount)
        end
    elseif Config.Framework == "qb" then
        player.Functions.RemoveMoney(moneyType, amount)
    end
end

function SetPlayerMoneyTo(targetId, moneyType, amount)
    if not targetId or not amount or amount < 0 then return end
    local player = GetPlayer(targetId)
    if not player then return end
    moneyType = (moneyType == "bank") and "bank" or (moneyType == "black_money") and "black_money" or "cash"
    if Config.Framework == "esx" then
        if moneyType == "cash" then
            if player.setMoney then player.setMoney(amount) end
        elseif moneyType == "black_money" then
            if player.setAccountMoney then player.setAccountMoney("black_money", amount) end
        else
            if player.setAccountMoney then player.setAccountMoney("bank", amount) end
        end
    elseif Config.Framework == "qb" then
        if player.Functions and player.Functions.SetMoney then
            player.Functions.SetMoney(moneyType, amount)
        end
    end
end

function SetPlayerJob(targetId, jobName, grade)
    if not targetId or targetId == 0 or not jobName or jobName == "" then return end
    local player = GetPlayer(targetId)
    if not player then return end
    grade = tonumber(grade)
    if grade == nil or grade < 0 then grade = 0 end
    if Config.Framework == "esx" then
        if player.setJob then
            player.setJob(jobName, grade)
        end
    elseif Config.Framework == "qb" then
        if player.Functions and player.Functions.SetJob then
            player.Functions.SetJob(jobName, grade)
        end
    end
end

function GetUsersTableName()
    if Config.Framework == "esx" then return "users" end
    if Config.Framework == "qb" then return "players" end
    return nil
end

function NotifyPlayer(source, message, notifType)
    if not source or source == 0 then return end
    message = tostring(message or "")
    notifType = notifType or "inform"
    local notify = (Config.Notify and Config.Notify.Notification) or "ox_lib"
    if notify == "qb-core" then
        TriggerClientEvent("QBCore:Notify", source, message, notifType, 5000)
    elseif notify == "esx_framework" then
        TriggerClientEvent("esx:showNotification", source, message)
    else
        TriggerClientEvent("ox_lib:notify", source, { description = message, type = notifType })
    end
end

function GetFrameworkPlayerFirstname(xPlayer)
    if not xPlayer then return nil end
    if Config.Framework == "esx" then
        if xPlayer.get and xPlayer.get("firstName") then return xPlayer.get("firstName") end
        if xPlayer.firstName then return xPlayer.firstName end
        return nil
    elseif Config.Framework == "qb" then
        local info = xPlayer.PlayerData and xPlayer.PlayerData.charinfo
        return (info and info.firstname) and tostring(info.firstname) or nil
    end
    return nil
end

function GetFrameworkPlayerLastname(xPlayer)
    if not xPlayer then return nil end
    if Config.Framework == "esx" then
        if xPlayer.get and xPlayer.get("lastName") then return xPlayer.get("lastName") end
        if xPlayer.lastName then return xPlayer.lastName end
        return nil
    elseif Config.Framework == "qb" then
        local info = xPlayer.PlayerData and xPlayer.PlayerData.charinfo
        return (info and info.lastname) and tostring(info.lastname) or nil
    end
    return nil
end