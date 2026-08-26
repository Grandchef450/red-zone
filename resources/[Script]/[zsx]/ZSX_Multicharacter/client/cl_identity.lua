--[[
    This file has been created to allow you to connect your custom identity or change some other related identity things.
    Make sure you fulfill the data required to register the player and if you don't want to use Identity.Anim function make sure to add
    TriggerServerEvent('ZSX_Multicharacter:Event:SetPlayerState', 'LOG_IN_USER') to switch his bucket to the main one. Otherwise he won't see anyone there
]]

ConfigIdentity = {}
ConfigIdentity.ShowIdentity = function()
    Identity.Show()
end

ConfigIdentity.ShowAnim = function(playerName, gender, callbacksData, clothingTimer)
    Identity.Anim(playerName, gender, callbacksData, clothingTimer)
end

ConfigIdentity.PlayerRegistered = function(data, cb)
    data.charIndex = ConfigIdentity.GetAwaitingID()
    Identity.RegisterNewPlayer(data, function(received)
        Entity.Vars['currentID'] = received.id
        if Config.Identity.UseSpawnSelectionOnFinish then
            Locations.Init('identity')
            cb(true)
            while Locations.CalledViaSelect do Wait(0) end
        end
        ConfigIdentity.ShowAnim(data.firstname..' '..data.lastname, data.gender, {
            -- called when player bucket is set to 0
            onPlayerSwitchState = function()

            end,
            -- called when Welcome <username> is called
            onCameraAnimationStart = function()
                Client.BlackScreen(false, true)
                TriggerEvent('ZSX_Multicharacter:Listener:CharacterCreated', data)
                cb(true)
                Identity.AwaitingID = false
            end,
            -- called at the exact moment where clothing timer is called
            onCameraAnimationEnd = function()
                if Config.Identity.SetInBucketOnAppearance then TriggerServerEvent('ZSX_Multicharacter:Event:SetPlayerState', 'LOG_OFF_USER') end
            end,
            -- if you're not using Config.Identity.UseCameraAnimation this callback is triggered
            onIdentityFinish = function()
                Client.BlackScreen(false, true)
                TriggerEvent('ZSX_Multicharacter:Listener:CharacterCreated', data)
                cb(true)
                if Config.Identity.SetInBucketOnAppearance then TriggerServerEvent('ZSX_Multicharacter:Event:SetPlayerState', 'LOG_OFF_USER') end
                Identity.AwaitingID = false
            end
        }, Config.Identity.UseClothingTimer)
    end)
end

ConfigIdentity.GetAwaitingID = function()
    return Identity.AwaitingID
end

ConfigIdentity.Bars = function(state)
    Cinematics.Show(state)
end