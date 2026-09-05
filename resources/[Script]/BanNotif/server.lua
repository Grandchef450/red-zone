-- 🛑 Détection automatique de ban par message "ban"
AddEventHandler('playerDropped', function(reason)
    local src = source
    local name = GetPlayerName(src)

    if reason and string.lower(reason):find("ban") then
        local cleanedReason = reason

        -- 🧼 Nettoyage du message automatique de txAdmin
        cleanedReason = cleanedReason:gsub("%[txAdmin%]%s*%([^%)]+%)%s*You have been banned from this server for%s*\"", "")
        cleanedReason = cleanedReason:gsub("You have been banned from this server for%s*\"", "")
        cleanedReason = cleanedReason:gsub("\"$", "") -- supprime le guillemet de fin

        -- 🧼 Supprimer le bloc indiquant la durée du ban
        cleanedReason = cleanedReason:gsub("%.%s*Your ban will expire in:%s*[%w%s]+%.?", "")

        -- 🧼 Suppression de tout ce qui est inutile
        cleanedReason = cleanedReason
            :gsub("%d+%s*[hH]?", "")      -- supprime les durées (ex: 48h)
            :gsub("sera%s*deban", "")     -- supprime "sera deban"
            :gsub("sera%s*unban", "")     -- supprime "sera unban"
            :gsub("%s+", " ")            -- retire les espaces multiples
            :gsub("%s*%-+%s*", " ")      -- retire les tirets superflus
            :gsub("^%s*(.-)%s*$", "%1")  -- retire les espaces au début et à la fin

        print("[BAN] " .. name .. " s’est fait ban (raison détectée : " .. cleanedReason .. ")")

        -- 📢 Envoie la raison propre aux joueurs connectés
        TriggerClientEvent('announce:ban:client', -1, name, cleanedReason)
    end
end)

-- 🧪 Commande de test globale — réservée aux admins (ace command.testbroadcast,
--    couverte par « add_ace group.admin command allow » dans permissions.cfg)
RegisterCommand("testbroadcast", function(source, args, rawCommand)
    print("🔧 testbroadcast lancé")
    local reason = table.concat(args, " ")
    if reason == "" then reason = "Aucune raison spécifiée" end

    local cleanedReason = reason
        :gsub("%[txAdmin%]%s*%([^%)]+%)%s*You have been banned from this server for%s*\"", "")
        :gsub("You have been banned from this server for%s*\"", "")
        :gsub("\"$", "")
        :gsub("%.%s*Your ban will expire in:%s*[%w%s]+%.?", "")
        :gsub("%d+%s*[hH]?", "")
        :gsub("sera%s*deban", "")
        :gsub("sera%s*unban", "")
        :gsub("%s+", " ")
        :gsub("%s*%-+%s*", " ")
        :gsub("^%s*(.-)%s*$", "%1")

    TriggerClientEvent('announce:ban:client', -1, "TestJoueur", cleanedReason)
end, true)
