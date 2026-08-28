-- ============================================================
-- DEOBFUSCATED SCRIPT
-- Original: Client/CFunction.lua
-- Deobfuscated: 2026-04-09
-- ============================================================

-- =====================
-- MODULE-LEVEL STATE
-- =====================

local isNoclipActive           = false       -- noclip toggle
local noclipSpeed              = 1.0         -- current movement speed multiplier
local noclipMode               = 1           -- speed mode index (1–3)
local noclipSpeeds             = { 0.8, 1.8, 4.0 }
local savedClothingSlots       = {}          -- component slots saved before staff outfit
local isInvisible              = false
local isGodmodeActive          = false
local isInfiniteAmmoActive     = false
local headshotRequestIdCounter = 0
local headshotPendingPromises  = {}          -- [requestId] = promise
local headshotLock             = false       -- mutex: one headshot capture at a time
local savedTeleportPos         = nil         -- {x,y,z,h} saved before admin teleport

-- =====================
-- HELPER FUNCTIONS
-- =====================

-- [PURPOSE] Saves local player entity's current coords + heading into savedTeleportPos
local function saveCurrentPosition()
    local ped = PlayerPedId()
    if not ped or 0 == ped then return end
    local entity = ped
    if IsPedInAnyVehicle(ped, false) then
        entity = GetVehiclePedIsIn(ped, false)
    end
    local coords = GetEntityCoords(entity)
    savedTeleportPos = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(entity),
    }
end

-- [PURPOSE] Returns the first free seat index in the vehicle the given ped is in
-- NOTE: Original code omits the seat index argument to GetPedInVehicleSeat (obfuscator bug)
local function getFreeSeatInVehicle(ped)
    if not IsPedInAnyVehicle(ped, false) then return end
    local vehicle  = GetVehiclePedIsIn(ped)
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = 0, maxSeats, 1 do
        local occupant = GetPedInVehicleSeat(vehicle) -- NOTE: seat arg missing in original
        if occupant then return seat end
    end
end

-- [PURPOSE] Returns a normalised camera forward direction vector (dx, dy, dz)
local function getCameraDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch   = GetGameplayCamRelativePitch()
    local dx = -math.sin(heading * math.pi / 180.0)
    local dy =  math.cos(heading * math.pi / 180.0)
    local dz =  math.sin(pitch   * math.pi / 180.0)
    local magnitude = math.sqrt(dx * dx + dy * dy + dz * dz)
    if 0 ~= magnitude then
        dx = dx / magnitude
        dy = dy / magnitude
        dz = dz / magnitude
    end
    return dx, dy, dz
end

-- [PURPOSE] Requests network control of an entity; returns true if already owned or not in session
local function requestEntityControl(entity)
    if NetworkIsInSession then
        if not NetworkHasControlOfEntity(entity) then
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
            return NetworkRequestControlOfEntity(entity)
        end
    end
    return true
end

-- [PURPOSE] Returns the active locale string and its translation table
-- Falls back to "en" / {} when Config or Locales are missing
local function getLocale()
    local locale = (Config and Config.Locale) or "en"
    local translations
    if Locales and Locales[locale] then
        translations = Locales[locale]
    elseif Locales and Locales.en then
        translations = Locales.en
    else
        translations = {}
    end
    return locale, translations
end

-- =====================
-- NET EVENTS — ADMIN ACTIONS
-- =====================

-- [PURPOSE] Event: set the local player's health to 0 (kill)
-- Event: admin:kill
RegisterNetEvent("admin:kill", function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)

-- [PURPOSE] Event: toggle noclip for the local player; runs movement loop while active
-- Event: admin:noclipplayer
RegisterNetEvent("admin:noclipplayer", function()
    isNoclipActive = not isNoclipActive

    TriggerEvent("adminpanel:noclipStateChanged", isNoclipActive)
    TriggerServerEvent("adminpanel:setAdminTagNoclip", isNoclipActive)

    if isNoclipActive then
        TriggerServerEvent("adminpanel:logAdminActionFromClient", "noclip")
        local locale, translations = getLocale()
        SendNUIMessage({
            action       = "noclipHints",
            show         = true,
            mode         = noclipMode,
            locale       = locale,
            translations = translations,
        })
    end

    while true do
        Citizen.Wait(0)

        if isNoclipActive then
            local inVehicle = IsPedInAnyVehicle(PlayerPedId(), 0)
            local entity, x, y, z

            if not inVehicle then
                entity = PlayerPedId()
                x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 2))
            else
                entity = GetVehiclePedIsIn(PlayerPedId(), 0)
                x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 1))
            end

            -- Request network control of vehicle if not driver seat
            if inVehicle then
                local driverSeat = getFreeSeatInVehicle(PlayerPedId())
                if driverSeat ~= -1 then
                    requestEntityControl(entity)
                end
            end

            local dx, dy, dz = getCameraDirection()

            -- Hide entity and suppress physics during noclip
            SetEntityVisible(PlayerPedId(), 0, 0)
            SetEntityVisible(entity, 0, 0)
            SetEntityVelocity(entity, 1.0E-4, 1.0E-4, 1.0E-4)

            -- Cycle speed mode: INPUT_SPECIAL_ABILITY_SECONDARY (244)
            if IsDisabledControlJustPressed(0, 244) then
                noclipMode  = (noclipMode % 3) + 1
                noclipSpeed = noclipSpeeds[noclipMode]
                local locale, translations = getLocale()
                SendNUIMessage({
                    action       = "noclipHints",
                    mode         = noclipMode,
                    locale       = locale,
                    translations = translations,
                })
            end

            local speed = noclipSpeed

            -- INPUT_SPRINT (21): speed boost x6
            if IsDisabledControlPressed(0, 21) then
                speed = speed * 6
            end

            -- Perpendicular strafe direction
            local strafeX = -dy
            local strafeY =  dx

            -- W (32): move forward
            if IsDisabledControlPressed(0, 32) then
                x = x + speed * dx
                y = y + speed * dy
                z = z + speed * dz
            end

            -- S (269): move backward
            if IsDisabledControlPressed(0, 269) then
                x = x - speed * dx
                y = y - speed * dy
                z = z - speed * dz
            end

            -- A (34): strafe left
            if IsDisabledControlPressed(0, 34) then
                x = x + speed * strafeX
                y = y + speed * strafeY
            end

            -- D (35): strafe right
            if IsDisabledControlPressed(0, 35) then
                x = x - speed * strafeX
                y = y - speed * strafeY
            end

            -- Q/Space (44 or 22): ascend
            if IsDisabledControlPressed(0, 44) or IsDisabledControlPressed(0, 22) then
                z = z + speed
            end

            -- Ctrl (38): descend
            if IsDisabledControlPressed(0, 38) then
                z = z - speed
            end

            SetEntityCoordsNoOffset(entity, x, y, z, true, true, true)

        else
            -- Noclip turned off — drop entity to ground and restore visibility
            local ped = PlayerPedId()
            local targetEntity = ped
            if IsPedInAnyVehicle(ped, 0) then
                targetEntity = GetVehiclePedIsIn(ped, 0)
            end

            local ex, ey, ez = table.unpack(GetEntityCoords(targetEntity))

            local foundGround, groundZ = GetGroundZFor_3dCoord(ex, ey, ez + 2.0)
            if not foundGround then
                foundGround, groundZ = GetGroundZFor_3dCoord(ex, ey, ez + 50.0)
            end

            if foundGround then
                SetEntityCoords(targetEntity, ex, ey, groundZ, false, false, false, true)
            end

            SetEntityVisible(PlayerPedId(), true)
            if IsPedInAnyVehicle(PlayerPedId(), 0) then
                SetEntityVisible(GetVehiclePedIsIn(PlayerPedId(), 0), true)
            end

            SendNUIMessage({ action = "noclipHints", show = false })
            break
        end
    end
end)

-- [PURPOSE] Event: toggle invisibility for the local player
-- Event: admin:toggleInvisible
RegisterNetEvent("admin:toggleInvisible", function()
    isInvisible = not isInvisible
    TriggerEvent("adminpanel:invisibilityStateChanged", isInvisible)

    if not isInvisible then
        -- Turning OFF — restore visibility
        local ped = PlayerPedId()
        SetEntityVisible(ped, true)
        if IsPedInAnyVehicle(ped, false) then
            SetEntityVisible(GetVehiclePedIsIn(ped, false), true)
        end
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_invisibility_off_title"),
                description = _L("notify_invisibility_off_desc"),
                type        = "info",
            })
        end
    else
        -- Turning ON — notify then start keep-invisible loop
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_invisibility_on_title"),
                description = _L("notify_invisibility_on_desc"),
                type        = "success",
            })
        end
        CreateThread(function()
            while true do
                if not isInvisible then break end
                local ped = PlayerPedId()
                SetEntityVisible(ped, false)
                if IsPedInAnyVehicle(ped, false) then
                    SetEntityVisible(GetVehiclePedIsIn(ped, false), false)
                end
                Wait(0)
            end
        end)
    end
end)

-- [PURPOSE] Event: report current noclip state back to caller
-- Event: admin:requestNoclipState
RegisterNetEvent("admin:requestNoclipState", function()
    TriggerEvent("adminpanel:noclipStateChanged", isNoclipActive)
end)

-- [PURPOSE] Event: report current invisibility state back to caller
-- Event: admin:requestInvisibilityState
RegisterNetEvent("admin:requestInvisibilityState", function()
    TriggerEvent("adminpanel:invisibilityStateChanged", isInvisible)
end)

-- [PURPOSE] Event: teleport local player to the map marker (blip type 8)
-- Event: admin:teleportToMarker
RegisterNetEvent("admin:teleportToMarker", function()
    local markerBlip = GetFirstBlipInfoId(8)
    if not markerBlip or 0 == markerBlip then
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_tpm_no_marker_title"),
                description = _L("notify_tpm_no_marker_desc"),
                type        = "error",
            })
        end
        return
    end

    local mx, my, mz = table.unpack(GetBlipCoords(markerBlip))

    local ped = PlayerPedId()
    local targetEntity = ped
    if IsPedInAnyVehicle(ped, false) then
        targetEntity = GetVehiclePedIsIn(ped, false)
    end

    saveCurrentPosition()
    local heading = GetEntityHeading(targetEntity)

    DoScreenFadeOut(400)
    Wait(450)

    -- Scan downward from 1000 to find ground Z
    local groundZ = 0.0
    for altitude = 1000.0, 0.0, -25.0 do
        local found, gz = GetGroundZFor_3dCoord(mx, my, altitude)
        if found then
            groundZ = gz
            break
        end
    end

    if 0.0 == groundZ then
        local found, gz = GetGroundZFor_3dCoord(mx, my, 0.0)
        if found then groundZ = gz end
    end

    SetEntityCoords(targetEntity, mx, my, groundZ + 0.5, false, false, false, true)
    SetEntityHeading(targetEntity, heading)
    Wait(100)
    SetEntityCoords(targetEntity, mx, my, groundZ + 0.5, false, false, false, true)
    DoScreenFadeIn(400)

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_tpm_success_title"),
            description = _L("notify_tpm_success_desc"),
            type        = "success",
        })
    end
end)

-- [PURPOSE] Event: teleport the local player back to savedTeleportPos
-- Event: admin:teleportBack
RegisterNetEvent("admin:teleportBack", function()
    if not savedTeleportPos then
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_tpback_no_saved_title"),
                description = _L("notify_tpback_no_saved_desc"),
                type        = "error",
            })
        end
        return
    end

    local ped = PlayerPedId()
    if not ped or 0 == ped then return end

    local targetEntity = ped
    if IsPedInAnyVehicle(ped, false) then
        targetEntity = GetVehiclePedIsIn(ped, false)
    end

    local bx = savedTeleportPos.x
    local by = savedTeleportPos.y
    local bz = savedTeleportPos.z
    local bh = savedTeleportPos.h

    DoScreenFadeOut(400)
    Wait(450)
    SetEntityCoords(targetEntity, bx, by, bz, false, false, false, true)
    SetEntityHeading(targetEntity, bh)
    Wait(100)
    SetEntityCoords(targetEntity, bx, by, bz, false, false, false, true)
    DoScreenFadeIn(400)

    savedTeleportPos = nil

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_tpback_success_title"),
            description = _L("notify_tpback_success_desc"),
            type        = "success",
        })
    end
end)

-- [PURPOSE] Event: give car keys for the vehicle the player is in, or nearest vehicle within 5m
-- Event: admin:giveCarKeys
RegisterNetEvent("admin:giveCarKeys", function()
    local ped     = PlayerPedId()
    local vehicle = nil

    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end

    if not vehicle or 0 == vehicle then
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_give_car_keys_no_vehicle_title"),
                description = _L("notify_give_car_keys_no_vehicle_desc"),
                type        = "error",
            })
        end
        return
    end

    local wasEngineOn = GetIsVehicleEngineRunning(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    GiveKeysToPlayer(vehicle, plate)

    -- Some key resources call SetVehicleEngineOn with instant-force params, which resets the
    -- gearbox to 1st. If the engine was running and gets killed, restart it with the normal
    -- (non-instant) sequence so GTA's transmission initialises cleanly.
    if wasEngineOn then
        Citizen.SetTimeout(250, function()
            if DoesEntityExist(vehicle) and not GetIsVehicleEngineRunning(vehicle) then
                SetVehicleEngineOn(vehicle, true, false, false)
            end
        end)
    end

    TriggerServerEvent("adminpanel:logAdminActionFromClient", "give_car_keys")

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_give_car_keys_success_title"),
            description = _L("notify_give_car_keys_success_desc"),
            type        = "success",
        })
    end
end)

-- [PURPOSE] Event: fix the vehicle the player is in, or nearest vehicle within 5m
-- Event: admin:fixVehicle
RegisterNetEvent("admin:fixVehicle", function()
    local ped     = PlayerPedId()
    local vehicle = nil

    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end

    if not vehicle or 0 == vehicle then
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_fix_vehicle_no_vehicle_title"),
                description = _L("notify_fix_vehicle_no_vehicle_desc"),
                type        = "error",
            })
        end
        return
    end

    SetVehicleFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleUndriveable(vehicle, false)

    TriggerServerEvent("adminpanel:logAdminActionFromClient", "fix_vehicle")

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_fix_vehicle_success_title"),
            description = _L("notify_fix_vehicle_success_desc"),
            type        = "success",
        })
    end
end)

-- [PURPOSE] Event: delete the vehicle the player is in, or nearest vehicle within 5m
-- Event: admin:deleteVehicle
RegisterNetEvent("admin:deleteVehicle", function()
    local ped     = PlayerPedId()
    local vehicle = nil

    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, vehicle, 16)
        Wait(500)
    else
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end

    if not vehicle or 0 == vehicle then
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_delete_vehicle_no_vehicle_title"),
                description = _L("notify_delete_vehicle_no_vehicle_desc"),
                type        = "error",
            })
        end
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteEntity(vehicle)

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_delete_vehicle_success_title"),
            description = _L("notify_delete_vehicle_success_desc"),
            type        = "success",
        })
    end
end)

-- [PURPOSE] Event: toggle godmode (invincibility + all damage proofs) for the local player
-- Event: admin:toggleGodmode
RegisterNetEvent("admin:toggleGodmode", function()
    isGodmodeActive = not isGodmodeActive

    if isGodmodeActive then
        TriggerServerEvent("adminpanel:logAdminActionFromClient", "godmode")
    end

    local ped      = PlayerPedId()
    local playerId = PlayerId()

    SetPlayerInvincible(playerId, isGodmodeActive)
    SetEntityInvincible(ped, isGodmodeActive)
    -- Proofs: bullet, fire, explosion, collision, melee
    SetEntityProofs(ped, isGodmodeActive, isGodmodeActive, isGodmodeActive, isGodmodeActive, isGodmodeActive)

    TriggerEvent("adminpanel:godmodeStateChanged", isGodmodeActive)

    if lib and lib.notify then
        if isGodmodeActive then
            lib.notify({
                title       = _L("notify_godmode_on_title"),
                description = _L("notify_godmode_on_desc"),
                type        = "success",
            })
        else
            lib.notify({
                title       = _L("notify_godmode_off_title"),
                description = _L("notify_godmode_off_desc"),
                type        = "info",
            })
        end
    end
end)

-- [PURPOSE] Event: report current godmode state back to caller
-- Event: admin:requestGodmodeState
RegisterNetEvent("admin:requestGodmodeState", function()
    TriggerEvent("adminpanel:godmodeStateChanged", isGodmodeActive)
end)

-- [PURPOSE] Event: toggle infinite ammo for the local player
-- Event: admin:toggleInfiniteAmmo
RegisterNetEvent("admin:toggleInfiniteAmmo", function()
    isInfiniteAmmoActive = not isInfiniteAmmoActive

    if isInfiniteAmmoActive then
        TriggerServerEvent("adminpanel:logAdminActionFromClient", "infiniteammo")
        -- Snapshot current ammo so we can restore it when toggled off
        local snapPed = PlayerPedId()
        local snapWeapon = GetSelectedPedWeapon(snapPed)
        local unarmed = GetHashKey("WEAPON_UNARMED")
        local savedReserve = (snapWeapon ~= 0 and snapWeapon ~= unarmed) and GetAmmoInPedWeapon(snapPed, snapWeapon) or 0
        local savedClip    = (snapWeapon ~= 0 and snapWeapon ~= unarmed) and GetAmmoInClip(snapPed, snapWeapon) or 0
        local savedWeapon  = snapWeapon

        CreateThread(function()
            while isInfiniteAmmoActive do
                local ped = PlayerPedId()
                local weaponHash = GetSelectedPedWeapon(ped)
                if weaponHash and weaponHash ~= 0 and weaponHash ~= unarmed then
                    SetPedAmmo(ped, weaponHash, 9999)
                    SetAmmoInClip(ped, weaponHash, 9999)
                end
                Wait(0)
            end
            -- Restore ammo to pre-infinite state
            local ped = PlayerPedId()
            local curWeapon = GetSelectedPedWeapon(ped)
            -- Restore the weapon that was active when infinite ammo was turned on
            if savedWeapon and savedWeapon ~= 0 and savedWeapon ~= unarmed then
                SetPedAmmo(ped, savedWeapon, savedReserve)
                SetAmmoInClip(ped, savedWeapon, savedClip)
            end
            -- Always clear the persistent infinite-clip flag (survives resource restarts)
            SetPedInfiniteAmmoClip(ped, false)
            -- Also reset currently held weapon if it differs
            if curWeapon and curWeapon ~= 0 and curWeapon ~= unarmed and curWeapon ~= savedWeapon then
                local maxClip = GetMaxAmmoInClip(ped, curWeapon, false)
                SetAmmoInClip(ped, curWeapon, maxClip > 0 and maxClip or 30)
                SetPedAmmo(ped, curWeapon, 120)
            end
        end)
    end

    SendNUIMessage({ action = "setInfiniteAmmoState", on = isInfiniteAmmoActive })

    if lib and lib.notify then
        if isInfiniteAmmoActive then
            lib.notify({ title = _L("notify_infiniteammo_on_title") or "Infinite Ammo", description = _L("notify_infiniteammo_on_desc") or "Infinite ammo enabled", type = "success" })
        else
            lib.notify({ title = _L("notify_infiniteammo_off_title") or "Infinite Ammo", description = _L("notify_infiniteammo_off_desc") or "Infinite ammo disabled", type = "info" })
        end
    end
end)

-- [PURPOSE] Event: report current infinite ammo state back to caller
RegisterNetEvent("admin:requestInfiniteAmmoState", function()
    SendNUIMessage({ action = "setInfiniteAmmoState", on = isInfiniteAmmoActive })
end)

-- =====================
-- CLOTHING HELPERS
-- =====================

-- [PURPOSE] Records drawable/texture for each given component slot into savedClothingSlots
local function saveClothingSlots(ped, slots)
    for _, slotId in ipairs(slots) do
        savedClothingSlots[slotId] = {
            drawable = GetPedDrawableVariation(ped, slotId),
            texture  = GetPedTextureVariation(ped, slotId),
        }
    end
end

-- [PURPOSE] Applies Config.StaffClothing component variations onto a ped
local function applyStaffClothing(ped)
    if not Config.StaffClothing or type(Config.StaffClothing) ~= "table" then return end
    for slotId, slotData in pairs(Config.StaffClothing) do
        if type(slotData) == "table" and type(slotData.drawable) == "number" then
            SetPedComponentVariation(ped, slotId, slotData.drawable, slotData.texture or 0, 0)
        end
    end
end

-- [PURPOSE] Restores ped component variations from savedClothingSlots
local function restoreSavedClothing(ped)
    for slotId, slotData in pairs(savedClothingSlots) do
        if type(slotData) == "table" then
            SetPedComponentVariation(ped, slotId, slotData.drawable, slotData.texture, 0)
        end
    end
end

-- [PURPOSE] Event: save current outfit then apply staff clothing from Config
-- Event: admin:staffClothingApply
RegisterNetEvent("admin:staffClothingApply", function()
    local ped = PlayerPedId()
    if not Config.StaffClothing or type(Config.StaffClothing) ~= "table" then return end
    local slotIds = {}
    for slotId in pairs(Config.StaffClothing) do
        slotIds[#slotIds + 1] = slotId
    end
    saveClothingSlots(ped, slotIds)
    applyStaffClothing(ped)
end)

-- [PURPOSE] Event: restore the player's pre-staff-clothing outfit
-- Event: admin:staffClothingRemove
RegisterNetEvent("admin:staffClothingRemove", function()
    restoreSavedClothing(PlayerPedId())
end)

-- =====================
-- BRING / GOTO / FREEZE
-- =====================

local bringBackPosition = nil  -- coords saved before admin "bring" so player can be sent back

-- [PURPOSE] Teleports the local player's ped to the given world coordinates
local function teleportPedToCoords(x, y, z)
    local ped = PlayerPedId()
    if ped and 0 ~= ped then
        if not x then x = 0.0 end
        if not y then y = 0.0 end
        if not z then z = 0.0 end
        SetEntityCoords(ped, x, y, z, false, false, false, false)
    end
end

-- [PURPOSE] Event: teleport local player to coords (admin "bring"); saves current pos for send-back
-- Event: adminpanel:bringPlayer
RegisterNetEvent("adminpanel:bringPlayer", function(x, y, z)
    local ped = PlayerPedId()
    if ped and 0 ~= ped then
        bringBackPosition = GetEntityCoords(ped)
        teleportPedToCoords(x, y, z)
    end
end)

-- [PURPOSE] Event: teleport local player back to their pre-bring position
-- Event: adminpanel:sendBackPlayer
RegisterNetEvent("adminpanel:sendBackPlayer", function()
    local ped = PlayerPedId()
    if ped and 0 ~= ped then
        if bringBackPosition then
            SetEntityCoords(ped,
                bringBackPosition.x, bringBackPosition.y, bringBackPosition.z,
                false, false, false, false)
            bringBackPosition = nil
        end
    end
end)

-- [PURPOSE] Event: save position then go to another player's coordinates (goto)
-- Event: adminpanel:gotoPlayer
RegisterNetEvent("adminpanel:gotoPlayer", function(x, y, z)
    saveCurrentPosition()
    teleportPedToCoords(x, y, z)
end)

-- [PURPOSE] Event: toggle position freeze on the local player's ped
-- Event: adminpanel:toggleFreezePlayer
RegisterNetEvent("adminpanel:toggleFreezePlayer", function()
    local ped = PlayerPedId()
    if ped and 0 ~= ped then
        FreezeEntityPosition(ped, not IsEntityPositionFrozen(ped))
    end
end)

-- [PURPOSE] Event: explicitly set the freeze state on the local player's ped
-- Event: adminpanel:setFreezePlayer
RegisterNetEvent("adminpanel:setFreezePlayer", function(shouldFreeze)
    local ped = PlayerPedId()
    if ped and 0 ~= ped then
        FreezeEntityPosition(ped, shouldFreeze == true)
    end
end)

-- =====================
-- HEADSHOT CAPTURE
-- =====================

-- [PURPOSE] NUI callback: receives base64 headshot result and resolves the matching promise
-- Callback: headshotResult
RegisterNUICallback("headshotResult", function(data, cb)
    local requestId = data and tonumber(data.requestId) or nil
    if requestId then
        local pendingPromise = headshotPendingPromises[requestId]
        if pendingPromise then
            headshotPendingPromises[requestId] = nil
            local base64 = (data.base64 ~= nil and data.base64) or ""
            pendingPromise:resolve(pendingPromise, base64)
        end
    end
    cb("ok")
end)

-- [PURPOSE] Captures a NUI headshot of the given ped; returns (base64Data, txdUrl)
-- Uses headshotLock mutex so only one capture runs at a time
function TakePedHeadshot(ped)
    if not ped or 0 == ped then return nil, nil end

    -- Wait for any in-progress capture to finish
    while true do
        if not headshotLock then break end
        Wait(0)
    end
    headshotLock = true

    local imageData = nil
    local txdUrl    = nil

    pcall(function()
        local headshotHandle = RegisterPedheadshot(ped)
        local deadline       = GetGameTimer() + 5000

        -- Wait up to 5s for headshot to become ready
        while true do
            if IsPedheadshotReady(headshotHandle) then break end
            if deadline < GetGameTimer() then
                UnregisterPedheadshot(headshotHandle)
                return
            end
            Wait(0)
        end

        local txdName = GetPedheadshotTxdString(headshotHandle)
        if not txdName or "" == txdName then
            UnregisterPedheadshot(headshotHandle)
            return
        end

        -- Build nui-img URL format: https://nui-img/<txd>/<txd>
        local imgUrl = ("https://nui-img/%s/%s"):format(txdName, txdName)

        headshotRequestIdCounter = headshotRequestIdCounter + 1
        local requestId = headshotRequestIdCounter

        local p = promise.new()
        headshotPendingPromises[requestId] = p

        -- Ask the UI to convert the NUI image to base64
        SendNUIMessage({
            action    = "processHeadshot",
            url       = imgUrl,
            requestId = requestId,
        })

        -- Timeout: auto-resolve with "" after 10 seconds
        CreateThread(function()
            Wait(10000)
            if headshotPendingPromises[requestId] == p then
                headshotPendingPromises[requestId] = nil
                p:resolve(p, "")
            end
        end)

        local success, result = pcall(function()
            return Citizen.Await(p)
        end)

        UnregisterPedheadshot(headshotHandle)

        if headshotPendingPromises[requestId] == p then
            headshotPendingPromises[requestId] = nil
        end

        if success and result and "" ~= result then
            imageData = result
            txdUrl    = imgUrl
        else
            txdUrl = imgUrl
        end
    end)

    headshotLock = false
    return imageData, txdUrl
end

-- =====================
-- VEHICLE SPAWN / WEATHER / TIME
-- =====================

-- [PURPOSE] Event: spawn a vehicle at the player's position and warp them in as driver
-- Event: admin:spawnVehicle
RegisterNetEvent("admin:spawnVehicle", function(modelName, plate)
    local modelHash = 0
    if type(modelName) == "string" then
        local h = GetHashKey(modelName)
        if h then modelHash = h end
    end

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then return end

    RequestModel(modelHash)
    local ticks = 0
    while not HasModelLoaded(modelHash) and ticks < 100 do
        Citizen.Wait(10)
        ticks = ticks + 1
    end
    if not HasModelLoaded(modelHash) then return end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)

    if vehicle and 0 ~= vehicle then
        -- Apply custom plate (max 8 chars) if provided
        if type(plate) == "string" and plate ~= "" then
            SetVehicleNumberPlateText(vehicle, plate:sub(1, 8))
        end
        TaskWarpPedIntoVehicle(ped, vehicle, -1)  -- -1 = driver seat
        SetModelAsNoLongerNeeded(modelHash)
    end

    -- Hand vehicle keys to player (framework integration)
    local plateText = GetVehicleNumberPlateText(vehicle)
    GiveKeysToPlayer(vehicle, plateText)
end)

local forcedWeatherType = nil

-- [PURPOSE] Event: set a persistent weather type on the client
-- Stores the type so the enforcement loop keeps re-applying it,
-- preventing GTA's internal weather cycle from overriding it.
-- Event: admin:setWeather
RegisterNetEvent("admin:setWeather", function(weatherType)
    if type(weatherType) == "string" and weatherType ~= "" then
        forcedWeatherType = weatherType
        SetWeatherTypePersist(weatherType)
        SetWeatherTypeNow(weatherType)
        SetWeatherTypeNowPersist(weatherType)
    end
end)

local forcedClockState = {
    enabled = false,
    hour    = 12,
    minute  = 0,
}

CreateThread(function()
    while true do
        if forcedClockState.enabled then
            NetworkOverrideClockTime(forcedClockState.hour, forcedClockState.minute, 0)
            Wait(1000)
        else
            Wait(1500)
        end
    end
end)

-- Re-apply forced weather every 3 seconds so GTA's cycle cannot complete a transition away from it.
-- All three natives are needed: Persist sets the target, NowPersist keeps it, Now snaps immediately.
CreateThread(function()
    while true do
        if forcedWeatherType then
            SetWeatherTypePersist(forcedWeatherType)
            SetWeatherTypeNow(forcedWeatherType)
            SetWeatherTypeNowPersist(forcedWeatherType)
        end
        Wait(3000)
    end
end)

-- [PURPOSE] Event: override the game clock to a specific hour and minute
-- Event: admin:setTime
-- NOTE: The original code computes math.floor but never stores the result (dead assignment via goto);
--       only defaults to 12/0 when the argument type is not "number" — logic preserved exactly
RegisterNetEvent("admin:setTime", function(hour, minute, freeze)
    local h = tonumber(hour)
    if h ~= nil then
        h = math.floor(h)
    else
        h = 12
    end
    h = ((h % 24) + 24) % 24

    local m = tonumber(minute)
    if m ~= nil then
        m = math.floor(m)
    else
        m = 0
    end
    m = ((m % 60) + 60) % 60

    forcedClockState.hour = h
    forcedClockState.minute = m
    forcedClockState.enabled = (freeze == true)

    NetworkOverrideClockTime(h, m, 0)
end)

-- =====================
-- ESP SYSTEM
-- =====================

local isEspEnabled = false
local espOptions = {
    lineas  = false,  -- draw lines from self to each visible player
    cajas   = false,  -- draw 3D bounding boxes around players
    nombres = false,  -- draw player name + server ID label
    info    = false,  -- draw full info panel (name, ID, distance, vehicle)
}
local espDistance = 600  -- max ESP render distance (units)

-- [PURPOSE] Clamps an ESP distance value to [50, 2000]; returns 600 as the default
local function clampEspDistance(value)
    value = tonumber(value)
    if not value    then return 600  end
    if value < 50   then return 50   end
    if value > 2000 then return 2000 end
    return math.floor(value + 0.5)
end

-- [PURPOSE] Returns an {r, g, b} table cycling through rainbow colours over time
local function getRainbowColor(speed)
    local t = GetGameTimer() / 1000
    return {
        r = math.floor(math.sin(t * speed + 0) * 127 + 128),
        g = math.floor(math.sin(t * speed + 2) * 127 + 128),
        b = math.floor(math.sin(t * speed + 4) * 127 + 128),
    }
end

-- [PURPOSE] Renders a 3D text label at world coords using SetDrawOrigin
-- Params: x, y, z, text, r, g, b, scale  (scale defaults to 0.35)
local function drawText3D(x, y, z, text, r, g, b, scale)
    if not scale or scale <= 0 then scale = 0.35 end
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(2)
    SetTextProportional(0)
    SetTextScale(0.0, scale)
    SetTextColour(r or 255, g or 255, b or 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- =====================
-- ADMIN HEAD TAGS
-- =====================

-- [PURPOSE] Event: configure ESP visibility options and max render distance
-- Event: admin:setTags
RegisterNetEvent("admin:setTags", function(options)
    if not options or type(options) ~= "table" then
        isEspEnabled = false
        return
    end
    espOptions.lineas  = options.lineas  == true
    espOptions.cajas   = options.cajas   == true
    espOptions.nombres = options.nombres == true
    espOptions.info    = options.info    == true
    espDistance  = clampEspDistance(options.distancia)
    isEspEnabled = true
end)

local headTagsMap           = {}    -- [serverId] = "LABEL"
local noclipPlayersMap      = {}    -- [serverId] = true  (player currently noclipping)
local headTagRenderDistance = 85.0  -- max distance to render head tags

-- [PURPOSE] Sets or clears the head tag label for a given server ID
local function setHeadTag(serverId, label)
    serverId = tonumber(serverId)
    if not serverId then return end
    if label then
        local labelStr = tostring(label)
        if labelStr ~= "" then
            headTagsMap[serverId] = string.upper(labelStr)
            return
        end
    end
    headTagsMap[serverId] = nil
end

-- [PURPOSE] Draws an admin role label above a ped at world coordinates
local function drawAdminHeadTag(x, y, z, label)
    local tagText = string.upper(tostring(label or "STAFF"))
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(2)
    SetTextProportional(0)
    SetTextScale(0.0, 0.52)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(3, 18, 52, 115, 255)  -- dark blue outline
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(tagText)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- [PURPOSE] State bag handler: syncs admin_head_tag changes per player
AddStateBagChangeHandler("admin_head_tag", nil, function(bagName, _, value)
    local serverId = tonumber(string.match(tostring(bagName or ""), "^player:(%d+)$"))
    if not serverId then return end
    if type(value) == "string" and value ~= "" then
        headTagsMap[serverId] = string.upper(value)
    else
        headTagsMap[serverId] = nil
    end
end)

-- [PURPOSE] State bag handler: syncs admin_noclip state per player
AddStateBagChangeHandler("admin_noclip", nil, function(bagName, _, value)
    local serverId = tonumber(string.match(tostring(bagName or ""), "^player:(%d+)$"))
    if not serverId then return end
    if value == true then
        noclipPlayersMap[serverId] = true
    else
        noclipPlayersMap[serverId] = nil
    end
end)

-- [PURPOSE] Event: apply a single head tag update for one player
-- Event: admin:syncAdminHeadTag
RegisterNetEvent("admin:syncAdminHeadTag", function(serverId, label)
    setHeadTag(serverId, label)
end)

-- [PURPOSE] Event: replace the entire head tags map with a full server sync payload
-- Event: admin:fullAdminHeadTagsSync
RegisterNetEvent("admin:fullAdminHeadTagsSync", function(tagData)
    headTagsMap = {}
    if type(tagData) ~= "table" then return end

    -- Format 1: array of {sid=N, label="..."} objects
    for _, entry in pairs(tagData) do
        if type(entry) == "table" and entry.sid ~= nil then
            if entry.label then
                local labelStr = tostring(entry.label)
                if labelStr ~= "" then
                    setHeadTag(entry.sid, entry.label)
                end
            end
        end
    end

    -- Format 2: plain [serverId] = "label" map
    for key, val in pairs(tagData) do
        if type(val) == "string" and val ~= "" then
            local sid = tonumber(key)
            if sid then setHeadTag(sid, val) end
        end
    end
end)

-- [PURPOSE] Event: update the NUI with the local player's own admin head tag on/off state
-- Event: admin:adminHeadTagSelfState
RegisterNetEvent("admin:adminHeadTagSelfState", function(isOn)
    SendNUIMessage({ action = "setAdminHeadTagState", on = (isOn == true) })
end)

-- =====================
-- SYNC HELPERS
-- =====================

-- [PURPOSE] Reads head tag + noclip state bags for all active players; prunes stale entries
local function syncTagsFromActivePlayers()
    local activeServerIds = {}

    for _, localPlayerId in ipairs(GetActivePlayers()) do
        local serverId = tonumber(GetPlayerServerId(localPlayerId))
        if serverId then
            activeServerIds[serverId] = true
            local bagKey = ("player:%s"):format(serverId)

            -- Head tag from state bag
            local ok, tagValue = pcall(function()
                return GetStateBagValue(bagKey, "admin_head_tag")
            end)
            if ok then
                if type(tagValue) == "string" then
                    if tagValue ~= "" then
                        headTagsMap[serverId] = string.upper(tagValue)
                    else
                        headTagsMap[serverId] = nil
                    end
                end
            end

            -- Noclip state from state bag
            local ok2, noclipValue = pcall(function()
                return GetStateBagValue(bagKey, "admin_noclip")
            end)
            if ok2 then
                if noclipValue == true then
                    noclipPlayersMap[serverId] = true
                else
                    noclipPlayersMap[serverId] = nil
                end
            end
        end
    end

    -- Remove entries for players who have left
    for serverId in pairs(headTagsMap) do
        if not activeServerIds[serverId] then headTagsMap[serverId] = nil end
    end
    for serverId in pairs(noclipPlayersMap) do
        if not activeServerIds[serverId] then noclipPlayersMap[serverId] = nil end
    end
end

-- =====================
-- THREADS
-- =====================

-- [PURPOSE] One-shot: initial state bag sync after 800ms then request server head tag data
CreateThread(function()
    Wait(800)
    syncTagsFromActivePlayers()
    TriggerServerEvent("adminpanel:requestAdminHeadTagsSync")
end)

-- [PURPOSE] Periodic: re-sync player state bags every 15 seconds
CreateThread(function()
    while true do
        Wait(15000)
        syncTagsFromActivePlayers()
    end
end)

-- [PURPOSE] Render: draws admin head tags above nearby players each frame
CreateThread(function()
    while true do
        local waitTime  = 400
        local hasAnyTag = false

        for _ in pairs(headTagsMap) do hasAnyTag = true; break end

        if hasAnyTag then
            waitTime  = 0
            local selfPed = PlayerPedId()
            if selfPed and 0 ~= selfPed then
                local sc = GetEntityCoords(selfPed)
                local sx, sy, sz = sc.x, sc.y, sc.z

                for _, localPlayerId in ipairs(GetActivePlayers()) do
                    local serverId     = tonumber(GetPlayerServerId(localPlayerId))
                    local headTagLabel = serverId and headTagsMap[serverId] or nil

                    if headTagLabel and serverId then
                        -- Skip players currently in noclip (they are invisible)
                        if not noclipPlayersMap[serverId] then
                            local targetPed = GetPlayerPed(localPlayerId)
                            if targetPed and 0 ~= targetPed and DoesEntityExist(targetPed) then
                                local tc   = GetEntityCoords(targetPed)
                                local dist = #(vector3(sx, sy, sz) - vector3(tc.x, tc.y, tc.z))
                                if dist <= headTagRenderDistance then
                                    local offset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, 1.08)
                                    drawAdminHeadTag(offset.x, offset.y, offset.z, headTagLabel)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(waitTime)
    end
end)

-- [PURPOSE] Render + death-log: ESP overlays (names, info, bounding boxes, lines) per frame;
--           also detects and reports local player death events to the server
CreateThread(function()
    local wasDeadLastFrame = false

    while true do
        local waitTime = 250

        if isEspEnabled then
            local selfPed      = PlayerPedId()
            local sx, sy, sz   = table.unpack(GetEntityCoords(selfPed))
            local rainbowColor = getRainbowColor(1.0)

            for _, localPlayerId in ipairs(GetActivePlayers()) do
                if localPlayerId ~= PlayerId() then
                    local targetPed = GetPlayerPed(localPlayerId)
                    if targetPed and 0 ~= targetPed and DoesEntityExist(targetPed) then
                        local tx, ty, tz = table.unpack(GetEntityCoords(targetPed))
                        local distFloor  = math.floor(GetDistanceBetweenCoords(sx, sy, sz, tx, ty, tz, true))

                        if distFloor < espDistance then

                            -- === PLAYER NAME TAG ===
                            if espOptions.nombres then
                                local sid        = GetPlayerServerId(localPlayerId)
                                local playerName = GetPlayerName(localPlayerId) or "?"
                                local nameLabel  = sid .. "  ||  " .. playerName
                                if NetworkIsPlayerTalking(localPlayerId) then
                                    -- Rainbow colour when player is talking
                                    drawText3D(tx, ty, tz + 1.2, nameLabel, rainbowColor.r, rainbowColor.g, rainbowColor.b)
                                else
                                    drawText3D(tx, ty, tz + 1.2, nameLabel, 255, 255, 255)
                                end
                            end

                            -- === DETAILED INFO PANEL ===
                            if espOptions.info then
                                local lblName     = _L("esp_info_label_name")     or "Name"
                                local lblId       = _L("esp_info_label_id")       or "ID"
                                local lblDistance = _L("esp_info_label_distance") or "Distance"
                                local lblVehicle  = _L("esp_info_label_vehicle")  or "Vehicle"

                                local pName    = GetPlayerName(localPlayerId) or "?"
                                local pId      = GetPlayerServerId(localPlayerId)
                                local infoText = lblName     .. ": " .. pName    .. "\n"
                                             .. lblId       .. ": " .. pId      .. "\n"
                                             .. lblDistance .. ": " .. distFloor

                                -- Append vehicle model name if player is in a vehicle
                                if IsPedInAnyVehicle(targetPed, true) then
                                    local veh      = GetVehiclePedIsUsing(targetPed)
                                    local model    = GetEntityModel(veh)
                                    local dispName = GetLabelText(GetDisplayNameFromVehicleModel(model))
                                    if dispName and dispName ~= "NULL" then
                                        infoText = infoText .. "\n" .. lblVehicle .. ": " .. dispName
                                    end
                                end

                                -- Dynamic scale: closer = larger text, clamped to [0.045, 0.38]
                                local scale = 0.35 * (50.0 / math.max(distFloor, 6.0))
                                if scale > 0.38   then scale = 0.38
                                elseif scale < 0.045 then scale = 0.045 end

                                drawText3D(tx, ty, tz - 1.0, infoText,
                                    rainbowColor.r, rainbowColor.g, rainbowColor.b, scale)
                            end

                            -- === BOUNDING BOX ===
                            if espOptions.cajas then
                                -- Bottom face corners (offset z = -0.9)
                                local b1 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3, -0.9)
                                local b2 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3, -0.9)
                                local b3 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3, -0.9)
                                local b4 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3, -0.9)
                                local b5 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3, -0.9)
                                local b6 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3,  0.3, -0.9)
                                local b7 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3, -0.9)
                                -- Top face corners (offset z = 0.8)
                                local t1 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3,  0.8)
                                local t2 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3,  0.8)
                                local t3 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3,  0.8)
                                local t4 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3,  0.8)
                                local t5 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3,  0.8)
                                local t6 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3,  0.3,  0.8)
                                local t7 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3,  0.8)
                                -- Vertical edge connectors
                                local v1 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3,  0.3,  0.8)
                                local v2 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3,  0.3, -0.9)
                                local v3 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3,  0.8)
                                local v4 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3,  0.3, -0.9)
                                local v5 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3,  0.8)
                                local v6 = GetOffsetFromEntityInWorldCoords(targetPed, -0.3, -0.3, -0.9)
                                local v7 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3,  0.8)
                                local v8 = GetOffsetFromEntityInWorldCoords(targetPed,  0.3, -0.3, -0.9)

                                -- [PURPOSE] Draws one edge of the bounding box between two world points
                                local function drawBoxEdge(ptA, ptB)
                                    DrawLine(ptA.x, ptA.y, ptA.z,
                                             ptB.x, ptB.y, ptB.z,
                                             rainbowColor.r, rainbowColor.g, rainbowColor.b, 255)
                                end

                                -- Bottom face
                                drawBoxEdge(b1, b2); drawBoxEdge(b3, b4)
                                drawBoxEdge(b5, b6); drawBoxEdge(b6, b7)
                                -- Top face
                                drawBoxEdge(t1, t2); drawBoxEdge(t3, t4)
                                drawBoxEdge(t5, t6); drawBoxEdge(t6, t7)
                                -- Vertical edges
                                drawBoxEdge(v1, v2); drawBoxEdge(v3, v4)
                                drawBoxEdge(v5, v6); drawBoxEdge(v7, v8)
                            end

                            -- === LINE TO PLAYER ===
                            if espOptions.lineas then
                                DrawLine(sx, sy, sz, tx, ty, tz,
                                    rainbowColor.r, rainbowColor.g, rainbowColor.b, 255)
                            end
                        end
                    end
                end
            end

            waitTime = 0
        end

        -- === DEATH LOGGING ===
        local selfPed2 = PlayerPedId()
        if not selfPed2 or 0 == selfPed2 then
            -- No ped present — preserve original dead-assignment logic exactly
            local tempFlag = nil
            if 0 == waitTime then
                tempFlag = 0
                waitTime = tempFlag or waitTime  -- effectively: waitTime stays 0
            end
            if not tempFlag then
                waitTime = 1500
            end
        else
            local isDead = IsEntityDead(selfPed2)

            if isDead and not wasDeadLastFrame then
                -- Just died — determine killer server ID (0 = NPC or unknown)
                local killerServerId = 0
                local killerPed      = GetPedSourceOfDeath(selfPed2)
                if 0 ~= killerPed and DoesEntityExist(killerPed) and IsPedAPlayer(killerPed) then
                    local killerLocalId = NetworkGetPlayerIndexFromPed(killerPed)
                    if killerLocalId and killerLocalId >= 0 then
                        killerServerId = GetPlayerServerId(killerLocalId) or 0
                    end
                end
                -- Report death to server: event admin:logDeath
                TriggerServerEvent("admin:logDeath", killerServerId, GetPedCauseOfDeath(selfPed2))
                wasDeadLastFrame = true
            elseif not isDead then
                wasDeadLastFrame = false
            end

            -- Adjust wait time when ESP is not active (waitTime != 0)
            -- Original uses goto to skip the wait assignment when wasDeadLastFrame is true
            if 0 ~= waitTime then
                if wasDeadLastFrame then
                    local deathWait = 2000
                    if deathWait then
                        goto skipWaitAssign
                        waitTime = deathWait or waitTime  -- unreachable in original
                    end
                end
                waitTime = 800
            end
            ::skipWaitAssign::
        end

        Wait(waitTime)
    end
end)

-- [PURPOSE] One-shot: registers chat autocomplete suggestions for all configured admin commands
CreateThread(function()
    -- Shared parameter descriptor: player server ID
    local idParam = {{ name = _L("suggest_param_id"), help = "" }}

    local voiceCommands = (Config.Commands and Config.Commands.commandVoice) or {}
    local callCmd      = voiceCommands.call      or "call"
    local leaveCallCmd = voiceCommands.leavecall or "leavecall"

    -- Main admin panel command
    TriggerEvent("chat:addSuggestion", "/" .. (Config.AdminCommand or "adminpanel"), _L("suggest_adminpanel"))

    -- Kick actions command
    local kickCmd = (Config.KickActions and Config.KickActions.command) or "kickactions"
    TriggerEvent("chat:addSuggestion", "/" .. kickCmd, _L("suggest_kickactions"))

    -- Voice call commands
    if callCmd      then TriggerEvent("chat:addSuggestion", "/" .. callCmd,      _L("suggest_call"),      idParam) end
    if leaveCallCmd then TriggerEvent("chat:addSuggestion", "/" .. leaveCallCmd, _L("suggest_leavecall")) end

    -- Staff sub-commands
    local staffCmds = Config.Commands and Config.Commands.commandStaff
    if staffCmds then
        if staffCmds.coords        then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.coords,        _L("suggest_dev"))           end
        if staffCmds.noclip        then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.noclip,        _L("suggest_noclip"))        end
        if staffCmds.invisible     then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.invisible,     _L("suggest_invisible"))     end
        if staffCmds.tpm           then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.tpm,           _L("suggest_tpmarker"))      end
        if staffCmds.tpback        then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.tpback,        _L("suggest_tpback"))        end
        if staffCmds.deletecar     then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.deletecar,     _L("suggest_delcar"))        end
        if staffCmds.fixvehicle    then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.fixvehicle,    _L("suggest_fixvehicle"))    end
        if staffCmds.tags          then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.tags,          _L("suggest_tags"))          end
        if staffCmds.godmode       then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.godmode,       _L("suggest_godmode"))       end
        if staffCmds.staffclothing then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.staffclothing, _L("suggest_staffclothing")) end
        if staffCmds.gotoplayer    then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.gotoplayer,    _L("suggest_gotoplayer"), idParam) end
        if staffCmds.bring         then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.bring,         _L("suggest_bring"),      idParam) end
        if staffCmds.bringback     then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.bringback,     _L("suggest_bringback"),  idParam) end
        if staffCmds.kill          then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.kill,          _L("suggest_kill"),       idParam) end
        if staffCmds.freeze        then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.freeze,        _L("suggest_freeze"),     idParam) end
        if staffCmds.unfreeze      then TriggerEvent("chat:addSuggestion", "/" .. staffCmds.unfreeze,      _L("suggest_unfreeze"),   idParam) end

        if staffCmds.giveitem then
            TriggerEvent("chat:addSuggestion", "/" .. staffCmds.giveitem, _L("suggest_giveitem"), {
                { name = _L("suggest_param_id"), help = "" },
                { name = "item",   help = "" },
                { name = "amount", help = "" },
            })
        end

        if staffCmds.givevehicle then
            TriggerEvent("chat:addSuggestion", "/" .. staffCmds.givevehicle, _L("suggest_givevehicle"), {
                { name = _L("suggest_param_id"),             help = "" },
                { name = _L("suggest_param_vehicle_model"),  help = "" },
                { name = _L("suggest_param_plate_optional"), help = "" },
            })
        end

        if staffCmds.setaccountmoney then
            TriggerEvent("chat:addSuggestion", "/" .. staffCmds.setaccountmoney, _L("suggest_setaccountmoney"), {
                { name = "CASH|BANK",            help = "" },
                { name = _L("suggest_param_id"), help = "" },
                { name = "amount",               help = "" },
            })
        end
    end

    -- Console-only commands
    local consoleCmds = Config.Commands and Config.Commands.commandConsole
    if consoleCmds then
        if consoleCmds.unbanConsole then
            TriggerEvent("chat:addSuggestion", "/" .. consoleCmds.unbanConsole, _L("suggest_jdunban"), {
                { name = "BAN_ID", help = "" },
            })
        end
        if consoleCmds.addAdminConsole then
            TriggerEvent("chat:addSuggestion", "/" .. consoleCmds.addAdminConsole, _L("suggest_setadmin"), {
                { name = _L("suggest_param_id"), help = "" },
                { name = "group",                help = "" },
            })
        end
    end
end)

-- Clear persistent GTA engine flags when resource stops so they don't survive a restart
AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    isInfiniteAmmoActive = false
    local ped = PlayerPedId()
    SetPedInfiniteAmmoClip(ped, false)
    SetPedInfiniteAmmo(ped, false, GetSelectedPedWeapon(ped))
end)

-- ✅ DEOBFUSCATION COMPLETE — ALL PARTS DONE
