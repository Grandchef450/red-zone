--[[
    rz_signal_urgences / client/main.lua
    Réception des signaux et affichage du bandeau LCD.
]]

local lastSignal = 0


---Vibration de la manette et léger retour visuel.
local function haptic()
    if not Config.Display.haptic then return end

    SetControlShakeParameters(0, 'GRAB_L', 60, 100, false)
    Citizen.InvokeNative(0x748D3AD3, 0, 200, 100, 100)  -- SetPadShake
end


RegisterNetEvent('rz_signal:receive', function(data)
    if not data or not data.message then return end

    -- Anti-spam : plusieurs signaux dans la même seconde seraient
    -- illisibles et se recouvriraient à l'écran.
    local now = GetGameTimer()
    if (now - lastSignal) < (Config.Display.cooldown * 1000) then
        -- On ne jette pas le message : on le décale.
        SetTimeout(Config.Display.cooldown * 1000, function()
            TriggerEvent('rz_signal:receive', data)
        end)
        return
    end
    lastSignal = now

    if data.sound then
        PlaySoundFrontend(-1, data.sound, 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    haptic()

    if Config.Display.mode == 'notify' then
        lib.notify({
            type        = data.priority == 'critique' and 'error'
                       or data.priority == 'staff' and 'inform'
                       or 'warning',
            title       = data.label or 'SIGNAL',
            description = data.message,
            duration    = data.duration or 10000,
        })
        return
    end

    SendNUIMessage({
        action   = 'signal',
        message  = data.message,
        label    = data.label or 'SIGNAL',
        sender   = data.sender,
        color    = data.color or '#4ade80',
        duration = data.duration or 10000,
        time     = GetClockHours() and
                   ('%02d:%02d'):format(GetClockHours(), GetClockMinutes()) or '',
    })
end)


-- ═══════════════════════════════════════════════════════════════════
--  RAPPEL DU DERNIER SIGNAL
--
--  Le bandeau disparaît au bout de quelques secondes. Un joueur qui
--  conduisait ou se battait à ce moment-là doit pouvoir le relire.
-- ═══════════════════════════════════════════════════════════════════

RegisterCommand('dernier', function()
    SendNUIMessage({ action = 'replay' })
end, false)


AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'hide' })
end)
