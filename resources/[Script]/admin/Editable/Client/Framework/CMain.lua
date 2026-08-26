function ShowNotification(message, notifType)
    notifType = notifType or "inform"
    local notify = (Config.Notify and Config.Notify.Notification) or "ox_lib"
    if notify == "ox_lib" then
        if lib and lib.notify then
            lib.notify({ description = message, type = notifType })
        end
    elseif notify == "esx_framework" then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(message)
        end
    elseif notify == "qb-core" then
        if QBCore and QBCore.Functions and QBCore.Functions.Notify then
            QBCore.Functions.Notify(message, notifType, 5000)
        else
            TriggerEvent("QBCore:Notify", message, notifType, 5000)
        end
    end
end

function GetPlayerData()
    if Config.Framework == "esx" then
        return ESX.GetPlayerData()
    elseif Config.Framework == "qb" then
        return QBCore.Functions.GetPlayerData()
    end
    return nil
end
