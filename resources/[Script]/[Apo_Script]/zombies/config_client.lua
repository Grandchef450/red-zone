-------------------------------------- FIVECORE --------------------------------------
-- Thank you very much for being a Fivecore customer, we really appreciate it, if you
-- have any doubts please consult the documentation or contact us through our discord.
-- Documentation: https://fivecore.gitbook.io/
-- Discord: https://discord.gg/GU6DqpcHYx
--------------------------------------------------------------------------------------

Config = {
    ZombieSounds = true, -- Enable zombie sounds (true/false)
    DisableTakedowns = true, -- Disable takedowns on zombies (special attacks with melee weapons that kills with one hit) (true/false)
    UseBloodSplatter = true, -- Enable blood splatter on screen when receive zombie hit (true/false)

    ZombieCanAttack = function () -- Here you can put a additional check to zombie can attack the player, like check if the player is dead and return false
        return true
    end,

    ZombieCanAggro = function () -- Here you can put a additional check to zombie can aggro the player, like check if the player is dead and return false
        return true
    end,

    AlertDistanceModifier = { -- Distance modifier for the alert distance of zombies (in meters)
        running = 3.0, -- modifier when running (in meters)
        crouched = -2.0, -- modifier when crouched (in meters)
        prone = -4.0, -- modifier when prone (in meters)
    },

    ChanceToRagdollOnFootAttack = 20, -- Chance to ragdoll the player when a zombie attacks the player while on foot 0 to 100%
    ChanceToRagdollOnBikeAttack = 35, -- Chance to ragdoll the player when a zombie attacks the player while on a bike 0 to 100%

    GetCurrentHours = function () -- Used if BoostDensityByTime is enabled
        return GetClockHours()
    end,

    GetIsCrouched = function () -- Used with AlertDistanceModifier
        return GetPedStealthMovement(cache.ped)
    end,

    GetIsProned = function () -- Used with AlertDistanceModifier
        return false -- Add your prone script check here (if you have one)
    end,

    onReceiveAttack = function (zombieData, damage, damageType) -- Function that will be called when the player receives damage from a zombie
        AnimpostfxPlay('BeastIntroScene', 1000, false)
        ApplyDamageToPed(cache.ped, damage, true)
        -- print('Received ' .. damageType ..' damage with ' .. damage.. ' health loss from zombie '..zombieData.label)
    end,

    NotifyHordeZone = function (entered, zoneData) -- Function that will be called when the player enters a horde zone
        if entered then
            lib.notify({
                description = 'Vous entrez dans une zone infestée, soyez prudent !',
                duration = 5000,
                type = 'error',
                position = 'center-right'
            })
        else
            lib.notify({
                description = 'Vous avez quitté la zone infestée, vous êtes en sécurité.',
                duration = 5000,
                type = 'success',
                position = 'center-right'
            })
        end
    end,

    WaitForClientLoadEvent = false, -- Wait for server calling the event 'fivecore_zombies:client:load' to start handling zombies (true/false)
}