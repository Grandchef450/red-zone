-- 📢 Annonce de bannissement côté client : notification ox_lib +
--    coup de canon (zz-hunger-games-cannon.mp3, joué par html/index.html)

local Config = {
    title    = '🚨 BAN DE LA RED-ZONE',
    duration = 12000,      -- ms d'affichage de la notification
    volume   = 0.6,        -- 0.0 à 1.0
}

RegisterNetEvent('announce:ban:client', function(playerName, reason)
    if not reason or reason == '' then
        reason = 'Aucune raison spécifiée'
    end

    lib.notify({
        title       = Config.title,
        description = ('%s vient de se faire BAN !\n📝 Raison : %s'):format(playerName, reason),
        type        = 'error',
        duration    = Config.duration,
        position    = 'top',
    })

    -- 🔊 Le canon
    SendNUIMessage({ action = 'play', volume = Config.volume })
end)

-- 🧪 Test local (visible et audible uniquement par toi)
RegisterCommand('testclientban', function()
    TriggerEvent('announce:ban:client', 'TestClientJoueur', 'Cheat détecté')
end, false)
