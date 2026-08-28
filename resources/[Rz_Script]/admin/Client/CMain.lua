-- ============================================================
-- GLOBAL STATE VARIABLES
-- ============================================================

local isMenuOpen         = false   -- Whether the admin panel NUI is currently open
local isLoggedIn         = false   -- Whether the admin is authenticated
local serverName         = "Servidor" -- Display name of the server shown in the panel
local isKickActionsOpen  = false   -- Whether the quick-action (kick actions) panel is open
local inputBlockTimer    = 0       -- Timestamp until which input is blocked (ms)
local isCoordsUIOpen     = false   -- Whether the coordinates UI overlay is visible
local isStaffClothingOn  = false   -- Whether staff clothing is currently applied
local isTagsOn           = false   -- Whether admin nametags are currently enabled
local awaitingKeybind    = nil     -- Action name currently awaiting a key assignment, or nil

local voiceProximityOverrideActive = false  -- Whether pma-voice proximity has been overridden
local originalMumbleProximity      = nil    -- Stored original MumbleSetTalkerProximity value

-- Spectate state table
local spectateState = {}
spectateState.toggled   = false  -- Whether spectate mode is active
spectateState.target    = 0      -- Server ID of the target being spectated
spectateState.targetPed = 0      -- Network ID of the target ped

local preSpectateCoords  = nil   -- Coordinates saved before spectating so we can return
local screenChunksBuffer = {}    -- Buffer for chunked screen capture frame data
local screenTotalChunks  = 0     -- Expected total number of screen chunks

-- Saved keybind values per action (loaded from KVP storage)
local keybindSavedValues = {}
keybindSavedValues.noclip      = nil
keybindSavedValues.invisibility = nil
keybindSavedValues.tpm         = nil
keybindSavedValues.deletecar   = nil

local playerDetailRequestSeq = 0  -- Sequence counter for player-detail requests (prevents stale responses)

-- Camera mode state
local isCameraMode       = false  -- Whether free-cam mode is active
local isEntityLaserMode  = false  -- Whether entity-laser selection mode is active

-- ============================================================
-- KEY NAME DISPLAY MAP
-- Maps JS KeyboardEvent.code values -> human-readable display strings
-- ============================================================
local keyNameMap = {}
keyNameMap.KeyA     = "a"      ; keyNameMap.KeyB = "b"      ; keyNameMap.KeyC = "c"
keyNameMap.KeyD     = "d"      ; keyNameMap.KeyE = "e"      ; keyNameMap.KeyF = "f"
keyNameMap.KeyG     = "g"      ; keyNameMap.KeyH = "h"      ; keyNameMap.KeyI = "i"
keyNameMap.KeyJ     = "j"      ; keyNameMap.KeyK = "k"      ; keyNameMap.KeyL = "l"
keyNameMap.KeyM     = "m"      ; keyNameMap.KeyN = "n"      ; keyNameMap.KeyO = "o"
keyNameMap.KeyP     = "p"      ; keyNameMap.KeyQ = "q"      ; keyNameMap.KeyR = "r"
keyNameMap.KeyS     = "s"      ; keyNameMap.KeyT = "t"      ; keyNameMap.KeyU = "u"
keyNameMap.KeyV     = "v"      ; keyNameMap.KeyW = "w"      ; keyNameMap.KeyX = "x"
keyNameMap.KeyY     = "y"      ; keyNameMap.KeyZ = "z"
keyNameMap.F1       = "F1"     ; keyNameMap.F2  = "F2"      ; keyNameMap.F3  = "F3"
keyNameMap.F4       = "F4"     ; keyNameMap.F5  = "F5"      ; keyNameMap.F6  = "F6"
keyNameMap.F7       = "F7"     ; keyNameMap.F8  = "F8"      ; keyNameMap.F9  = "F9"
keyNameMap.F10      = "F10"    ; keyNameMap.F11 = "F11"     ; keyNameMap.F12 = "F12"
keyNameMap.Space    = "SPACE"
keyNameMap.Insert   = "INSERT"
keyNameMap.Delete   = "DELETE"
keyNameMap.Home     = "HOME"
keyNameMap.End      = "END"
keyNameMap.PageUp   = "PAGEUP"
keyNameMap.PageDown = "PAGEDOWN"
keyNameMap.Minus    = "MINUS"
keyNameMap.Equal    = "EQUALS"
keyNameMap.Digit0   = "0"      ; keyNameMap.Digit1 = "1"     ; keyNameMap.Digit2 = "2"
keyNameMap.Digit3   = "3"      ; keyNameMap.Digit4 = "4"     ; keyNameMap.Digit5 = "5"
keyNameMap.Digit6   = "6"      ; keyNameMap.Digit7 = "7"     ; keyNameMap.Digit8 = "8"
keyNameMap.Digit9   = "9"

-- Registered key mapping command names (prevents double-registration)
local registeredKeyMappings = {}

-- List of action names that can have keybinds assigned
local bindableActions = {}
local ACTION_NOCLIP      = "noclip"
local ACTION_INVISIBILITY = "invisibility"
local ACTION_TPM         = "tpm"
local ACTION_DELETECAR   = "deletecar"
bindableActions[1] = ACTION_NOCLIP
bindableActions[2] = ACTION_INVISIBILITY
bindableActions[3] = ACTION_TPM
bindableActions[4] = ACTION_DELETECAR

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

--- Blocks all input actions for a given number of milliseconds.
--- Prevents accidental input immediately after opening/closing panels.
---@param delay number|nil Milliseconds to block (default 450)
local function blockInput(delay)
    local now     = GetGameTimer()
    local ms      = tonumber(delay)
    if not ms then ms = 450 end
    local until_t = now + ms
    if until_t > inputBlockTimer then
        inputBlockTimer = until_t
    end
end

--- Returns true if the admin panel can be opened right now.
--- Blocks opening when: kick-actions open, coords UI open, camera/laser active, or NUI already focused.
---@return boolean
local function canOpenMenu()
    if isKickActionsOpen then return false end
    if isCoordsUIOpen    then return false end
    if isCameraMode or isEntityLaserMode then return false end

    -- If NUI is focused and the panel is open, block re-opening
    local nuiFocused = IsNuiFocused and IsNuiFocused()
    if nuiFocused == true then
        -- Check that it's the panel holding focus (not another element)
        local blockByPanel = (not isKickActionsOpen) and (not isCoordsUIOpen)
        if blockByPanel then return false end
    end

    return true
end

--- Returns true if camera mode OR entity laser mode is currently active.
---@return boolean
local function isCameraOrLaserActive()
    return isCameraMode == true or isEntityLaserMode == true
end

--- Shows a notification telling the admin they cannot open this while camera/laser is active.
local function notifyBlockedByCameraLaser()
    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_open_blocked_title") or "Action blocked",
            description = _L("notify_open_blocked_camera_laser_desc")
                          or "Close camera mode and entity laser mode before opening this command.",
            type        = "error",
        })
    end
end

--- Converts a raw key code into a display string.
--- Single-character codes are uppercased; longer strings (F1, SPACE…) are returned as-is.
---@param key string Raw key code
---@return string|nil
local function formatKeyDisplay(key)
    if not key or key == "" then return nil end
    if #key == 1 then
        return key:upper()
    end
    return key
end

-- ============================================================
-- PERMISSION CHECK & ACTION TRIGGER
-- ============================================================

--- Checks server-side permission for an action, then triggers a local event if allowed.
---@param action string Permission identifier to check
---@param eventName string Local event to trigger on success
local function checkPermAndTrigger(action, eventName)
    lib.callback("adminpanel:hasCommandPerm", false, function(hasPerms)
        if hasPerms == true then
            TriggerEvent(eventName)
        end
    end, action)
end

--- Triggers the corresponding permission check and local event for a bindable action.
---@param action string One of: "noclip", "invisibility", "tpm", "deletecar"
local function triggerBindableAction(action)
    if action == "noclip" then
        checkPermAndTrigger("noclip",     "admin:noclipplayer")
    elseif action == "invisibility" then
        checkPermAndTrigger("invisibility",  "admin:toggleInvisible")
    elseif action == "tpm" then
        checkPermAndTrigger("tpm",        "admin:teleportToMarker")
    elseif action == "deletecar" then
        checkPermAndTrigger("delete_vehicle",  "admin:deleteVehicle")
    end
end

-- ============================================================
-- KEYBIND REGISTRATION
-- ============================================================

--- Registers (or re-registers) a key mapping for a bindable action.
--- Creates a command "jc_bind_{action}_{key}" and maps it to a keyboard key.
--- The command handler validates the stored KVP before firing the action,
--- so if the binding was later changed the old command does nothing.
---@param action string Bindable action name
---@param key    string Key code to bind (e.g. "F5", "g")
local function registerKeybind(action, key)
    local cmdName = "jc_bind_" .. action .. "_" .. key

    -- If the command was already registered, just re-map the key
    if registeredKeyMappings[cmdName] then
        RegisterKeyMapping(cmdName, "Admin: " .. action:upper(), "keyboard", key)
        return
    end

    -- Register the command with a handler that validates the stored KVP
    RegisterCommand(cmdName, function()
        local storedKey = GetResourceKvpString("adminpanel_bind_" .. action)
        if storedKey ~= key then return end  -- Binding has changed; ignore
        triggerBindableAction(action)
    end, false)

    registeredKeyMappings[cmdName] = true
    RegisterKeyMapping(cmdName, "Admin: " .. action:upper(), "keyboard", key)
end

-- On resource start: restore any keybinds previously saved in KVP storage
for _, actionName in ipairs(bindableActions) do
    local savedKey = GetResourceKvpString("adminpanel_bind_" .. actionName)
    if savedKey and savedKey ~= "" then
        registerKeybind(actionName, savedKey)
    end
end

-- ============================================================
-- MAIN INPUT-DISABLE THREAD
-- Runs every frame while the panel or kick-actions UI is open,
-- or while input is soft-blocked (inputBlockTimer).
-- Disables common gameplay controls to prevent exploits/interruptions.
-- ============================================================
CreateThread(function()
    while true do
        local now           = GetGameTimer()
        local inputBlocked  = now < inputBlockTimer
        local kickActionsUp = isKickActionsOpen
        local menuUp        = isMenuOpen

        if kickActionsUp or menuUp or inputBlocked then
            -- Keep NUI in focus while kick-actions panel is showing
            if kickActionsUp then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(true)
            end

            -- Prevent the pause menu from opening
            DisableFrontendThisFrame()
            if IsPauseMenuActive() then
                SetPauseMenuActive(false)
            end

            -- Disable look/move controls unless menu is open (allow looking during input block)
            if not menuUp then
                DisableControlAction(0, 1, true)   -- LookLeftRight
                DisableControlAction(0, 2, true)   -- LookUpDown
            end

            -- Common action disables
            DisableControlAction(0, 24,  true)  -- Attack
            DisableControlAction(0, 25,  true)  -- Aim
            DisableControlAction(0, 68,  true)  -- VehicleExit
            DisableControlAction(0, 69,  true)  -- VehicleHandbrake
            DisableControlAction(0, 70,  true)  -- VehicleDuck
            DisableControlAction(0, 91,  true)  -- VehicleAccelerate (mouse wheel up)
            DisableControlAction(0, 92,  true)  -- VehicleBrake (mouse wheel down)
            DisableControlAction(0, 114, true)  -- VehicleGunLeft
            DisableControlAction(0, 257, true)  -- Attack2
            DisableControlAction(0, 331, true)  -- Melee attack
            DisableControlAction(0, 347, true)  -- Context
            DisableControlAction(0, 199, true)  -- FrontendPause
            DisableControlAction(0, 200, true)  -- FrontendPauseAlternate
            DisableControlAction(0, 201, true)  -- FrontendCancel
            DisableControlAction(0, 177, true)  -- NextCamera
            DisableControlAction(0, 322, true)  -- PhoneSelect
            DisableControlAction(0, 244, true)  -- Sprint

            -- Extra: also disable jump while kick-actions open
            if kickActionsUp then
                DisableControlAction(0, 245, true) -- Jump
            end

            Wait(0)
        else
            Wait(500)  -- Panel closed; poll at low frequency to save CPU
        end
    end
end)

-- ============================================================
-- KICK ACTIONS COMMAND + KEY BINDING
-- ============================================================

-- Register the kick-actions command (default: "kickactions", overridable in Config)
local kickActionsCmd = Config.KickActions and Config.KickActions.command or "kickactions"

RegisterCommand(kickActionsCmd, function()
    if isCameraOrLaserActive() then
        notifyBlockedByCameraLaser()
        return
    end
    if not canOpenMenu() then return end
    TriggerServerEvent("adminpanel:requestQuickActions")
end, false)

-- Optional keybind for the kick-actions command
if Config.KickActions and Config.KickActions.key then
    RegisterKeyMapping(
        kickActionsCmd,
        "Open Kick Actions",
        "keyboard",
        Config.KickActions.key
    )
end

-- ============================================================
-- NET EVENT: Show Announcement Notification
-- Server → Client: display a text announcement in the NUI
-- ============================================================
RegisterNetEvent("adminpanel:showAnnouncement")
AddEventHandler("adminpanel:showAnnouncement", function(text)
    if type(text) ~= "string" or text == "" then return end
    SendNUIMessage({ action = "showAnnouncementNotification", text = text })
end)

-- ============================================================
-- NET EVENT: Open Kick Actions Panel
-- Server → Client: open the quick-actions/kick-actions NUI panel
-- ============================================================
RegisterNetEvent("adminpanel:openKickActions")
AddEventHandler("adminpanel:openKickActions", function(sectionPerms)
    if isCameraOrLaserActive() then
        notifyBlockedByCameraLaser()
        return
    end

    isKickActionsOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    -- Build current keybind display map for the UI
    local currentBinds = {}
    for _, actionName in ipairs(bindableActions) do
        local savedKey = GetResourceKvpString("adminpanel_bind_" .. actionName)
        if savedKey and savedKey ~= "" then
            currentBinds[actionName] = formatKeyDisplay(savedKey)
        end
    end

    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}
    local allLocales   = {}
    if Locales then for lang, tbl in pairs(Locales) do allLocales[lang] = tbl end end

    SendNUIMessage({
        action       = "openKickActions",
        binds        = currentBinds,
        sectionPerms = sectionPerms or {},
        locale       = locale,
        translations = translations,
        allLocales   = allLocales,
    })

    -- Sync toggle states into the NUI
    SendNUIMessage({ action = "setStaffClothingState", on = isStaffClothingOn })
    TriggerEvent("admin:requestGodmodeState")
    TriggerEvent("admin:requestNoclipState")
    TriggerEvent("admin:requestInvisibilityState")
    TriggerEvent("admin:requestInfiniteAmmoState")
end)

-- ============================================================
-- NET EVENTS: Toggle State Sync (Server → Client → NUI)
-- ============================================================

RegisterNetEvent("adminpanel:godmodeStateChanged")
AddEventHandler("adminpanel:godmodeStateChanged", function(on)
    SendNUIMessage({ action = "setGodmodeState", on = on })
end)

RegisterNetEvent("adminpanel:noclipStateChanged")
AddEventHandler("adminpanel:noclipStateChanged", function(on)
    SendNUIMessage({ action = "setNoclipState", on = on })
end)

RegisterNetEvent("adminpanel:invisibilityStateChanged")
AddEventHandler("adminpanel:invisibilityStateChanged", function(on)
    SendNUIMessage({ action = "setInvisibilityState", on = on })
end)

-- ============================================================
-- NET EVENT: Toggle Staff Clothing (Server → Client)
-- ============================================================
RegisterNetEvent("adminpanel:toggleStaffClothing")
AddEventHandler("adminpanel:toggleStaffClothing", function()
    isStaffClothingOn = not isStaffClothingOn
    SendNUIMessage({ action = "setStaffClothingState", on = isStaffClothingOn })
    if isStaffClothingOn then
        TriggerEvent("admin:staffClothingApply")
    else
        TriggerEvent("admin:staffClothingRemove")
    end
end)

-- ============================================================
-- NET EVENT: Toggle Admin Tags (Server → Client)
-- ============================================================
RegisterNetEvent("adminpanel:toggleTags")
AddEventHandler("adminpanel:toggleTags", function()
    isTagsOn = not isTagsOn
    if isTagsOn then
        TriggerServerEvent("adminpanel:logAdminActionFromClient", "tag_player")
        lib.callback("adminpanel:getProfile", false, function(profile)
            local settings = (profile and profile.settings) or {}
            local tags     = settings.tags or {}
            TriggerEvent("admin:setTags", tags)
            SendNUIMessage({ action = "setTagsState", on = true })
        end)
    else
        TriggerEvent("admin:setTags", nil)
        SendNUIMessage({ action = "setTagsState", on = false })
    end
end)

-- ============================================================
-- NUI CALLBACK: requestOpenKickActions
-- NUI wants to close the panel and open kick-actions instead
-- ============================================================
RegisterNUICallback("requestOpenKickActions", function(data, cb)
    if isCameraOrLaserActive() then
        notifyBlockedByCameraLaser()
        cb("ok")
        return
    end

    isMenuOpen = false
    blockInput(550)
    SetNuiFocus(false, false)
    TriggerServerEvent("adminpanel:requestQuickActions")
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: closeKickActions
-- NUI requests closing the kick-actions panel
-- ============================================================
RegisterNUICallback("closeKickActions", function(data, cb)
    awaitingKeybind = nil
    blockInput(550)
    SendNUIMessage({ action = "closeKickActions" })
    TriggerServerEvent("adminpanel:kickActionsClosed")
    cb("ok")

    -- Defer the focus release one frame so NUI has time to close
    CreateThread(function()
        Wait(0)
        isKickActionsOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
end)

-- ============================================================
-- KEYBIND NUI CALLBACKS
-- ============================================================

--- Returns true if the given action name is in the bindableActions list.
---@param action string
---@return boolean
local function isBindableAction(action)
    for _, v in ipairs(bindableActions) do
        if v == action then return true end
    end
    return false
end

-- NUI → Client: begin listening for a key press to assign to an action
RegisterNUICallback("startWaitingForKey", function(data, cb)
    local action = (type(data) == "table") and data.action or nil
    if action and isBindableAction(action) then
        awaitingKeybind = action
    end
    cb("ok")
end)

-- NUI → Client: cancel listening for a key press
RegisterNUICallback("cancelWaitingForKey", function(data, cb)
    awaitingKeybind = nil
    cb("ok")
end)

-- NUI → Client: save a new keybind for an action
RegisterNUICallback("updateKeybind", function(data, cb)
    local action = (type(data) == "table") and data.action or nil
    local key    = (type(data) == "table") and data.key    or nil
    local silent = (type(data) == "table") and data.silent or false

    -- Validate
    if not (action and key) or not isBindableAction(action) then
        cb("ok")
        return
    end

    -- Look up the normalised key string from the key name map
    local normKey = keyNameMap[key]
    if normKey then
        awaitingKeybind = nil

        -- If another action already uses this key, clear it first
        for _, otherAction in ipairs(bindableActions) do
            if otherAction ~= action then
                local otherKey = GetResourceKvpString("adminpanel_bind_" .. otherAction)
                if otherKey and otherKey ~= "" then
                    if otherKey:lower() == normKey:lower() then
                        -- Clear the conflicting bind
                        keybindSavedValues[otherAction] = nil
                        SetResourceKvp("adminpanel_bind_" .. otherAction, "")
                        SendNUIMessage({
                            action     = "keybindSet",
                            bindAction = otherAction,
                            keyDisplay = "-",
                        })
                    end
                end
            end
        end

        -- Save and register the new bind
        keybindSavedValues[action] = normKey
        SetResourceKvp("adminpanel_bind_" .. action, normKey)
        registerKeybind(action, normKey)
        SendNUIMessage({
            action     = "keybindSet",
            bindAction = action,
            keyDisplay = formatKeyDisplay(normKey),
        })
    end

    -- Show success notification unless silenced
    if not silent then
        lib.notify({
            title       = _L("notify_keybind_title"),
            description = _L("notify_keybind_desc"),
            type        = "success",
        })
    end

    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: quickAction
-- Handles all quick-action buttons inside the kick-actions panel
-- ============================================================
RegisterNUICallback("quickAction", function(data, cb)
    local action = (type(data) == "table") and data.action or nil

    if action == "announcements" then
        SendNUIMessage({ action = "openAnnouncementsModal" })

    elseif action == "noclip" then
        checkPermAndTrigger("noclip", "admin:noclipplayer")

    elseif action == "godmode" then
        TriggerEvent("admin:toggleGodmode")

    elseif action == "revive" then
        TriggerServerEvent("adminpanel:revivePlayer", GetPlayerServerId(PlayerId()))

    elseif action == "invisibility" then
        checkPermAndTrigger("invisibility", "admin:toggleInvisible")

    elseif action == "servertime" then
        SendNUIMessage({ action = "openServerTimeModal" })

    elseif action == "staffclothing" then
        isStaffClothingOn = not isStaffClothingOn
        SendNUIMessage({ action = "setStaffClothingState", on = isStaffClothingOn })
        if isStaffClothingOn then
            TriggerEvent("admin:staffClothingApply")
        else
            TriggerEvent("admin:staffClothingRemove")
        end

    elseif action == "tags" then
        isTagsOn = not isTagsOn
        if isTagsOn then
            TriggerServerEvent("adminpanel:logAdminActionFromClient", "tag_player")
            lib.callback("adminpanel:getProfile", false, function(profile)
                local settings = (profile and profile.settings) or {}
                local tags     = settings.tags or {}
                TriggerEvent("admin:setTags", tags)
                SendNUIMessage({ action = "setTagsState", on = true })
            end)
        else
            TriggerEvent("admin:setTags", nil)
            SendNUIMessage({ action = "setTagsState", on = false })
        end

    elseif action == "admintag" then
        TriggerServerEvent("adminpanel:toggleAdminHeadTag")
        CreateThread(function()
            Wait(250)
            TriggerServerEvent("adminpanel:requestAdminHeadTagsSync")
        end)

    elseif action == "tpm" then
        checkPermAndTrigger("tpm", "admin:teleportToMarker")

    elseif action == "copycoords" then
        local ped     = PlayerPedId()
        local cx, cy, cz = table.unpack(GetEntityCoords(ped, true))
        local heading = GetEntityHeading(ped)
        local coordStr = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", cx, cy, cz, heading)
        SendNUIMessage({ action = "copyToClipboard", text = coordStr })
        if lib and lib.notify then
            lib.notify({
                title       = _L("notify_coords_title"),
                description = _L("notify_coords_desc"),
                type        = "success",
            })
        end

    elseif action == "fixvehicle" then
        TriggerEvent("admin:fixVehicle")

    elseif action == "deletevehicle" then
        checkPermAndTrigger("delete_vehicle", "admin:deleteVehicle")

    elseif action == "tunevehicle" then
        TuneVehicle()

    elseif action == "infiniteammo" then
        TriggerEvent("admin:toggleInfiniteAmmo")

    elseif action == "givecarkeys" then
        TriggerEvent("admin:giveCarKeys")
    end

    cb("ok")
end)

-- ============================================================
-- openAdminPanel(sectionPerms, optionalSections, commandStaffPerms, adminUsername, showWelcome)
-- Sends the "open" NUI message that renders the full admin panel.
-- Also syncs all toggle states and requests dashboard data.
-- ============================================================
local wasJustLoggedIn = false  -- Tracks whether the welcome splash should appear

local function openAdminPanel(sectionPerms, optionalSections, commandStaffPerms, adminUsername, showWelcome)
    -- Resolve locale and translation table
    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}
    -- Send all available locales so the NUI can switch languages client-side
    local allLocales = {}
    if Locales then
        for lang, tbl in pairs(Locales) do
            allLocales[lang] = tbl
        end
    end

    SendNUIMessage({
        action           = "open",
        sectionPerms     = sectionPerms     or {},
        optionalSections = optionalSections or {},
        commandStaffPerms= commandStaffPerms or {},
        locale           = locale,
        translations     = translations,
        allLocales       = allLocales,
        adminUsername    = adminUsername,
        showWelcome      = (showWelcome == true),
    })

    -- Sync current toggle states
    SendNUIMessage({ action = "setStaffClothingState", on = isStaffClothingOn })
    SendNUIMessage({ action = "setTagsState",          on = isTagsOn })

    -- Sync admin head-tag state
    lib.callback("adminpanel:getAdminHeadTagSelfState", false, function(isOn)
        SendNUIMessage({ action = "setAdminHeadTagState", on = (isOn == true) })
    end)

    -- Sync godmode / noclip / invisibility states
    TriggerEvent("admin:requestGodmodeState")
    TriggerEvent("admin:requestNoclipState")
    TriggerEvent("admin:requestInvisibilityState")
    TriggerEvent("admin:requestInfiniteAmmoState")

    -- Populate the staff dashboard widget
    lib.callback("adminpanel:getActiveStaff", false, function(result)
        if not result then result = {} end
        SendNUIMessage({
            action       = "setStaffDash",
            staff        = result.staff        or {},
            onlineCount  = result.onlineCount  or 0,
            onlinePlayers= result.onlinePlayers or {},
            totalPlayers = result.totalPlayers  or 0,
            totalBans    = result.totalBans     or 0,
        })
    end)

    -- Populate monthly activity chart on the dashboard
    lib.callback("adminpanel:getDashboardMonthlyActivity", false, function(data)
        SendNUIMessage({ action = "setDashboardMonthlyChart", data = data or {} })
    end)
end

-- ============================================================
-- NET EVENT: loginSuccess  (Server → Client)
-- Server confirms credentials; sets isLoggedIn flag
-- ============================================================
RegisterNetEvent("adminpanel:loginSuccess")
AddEventHandler("adminpanel:loginSuccess", function()
    isLoggedIn     = true
    wasJustLoggedIn = true
end)

-- ============================================================
-- NET EVENT: open  (Server → Client)
-- Server tells the client to open the admin panel (post-auth)
-- ============================================================
RegisterNetEvent("adminpanel:open")
AddEventHandler("adminpanel:open", function(isNewLogin, newServerName, sectionPerms, optionalSections, commandStaffPerms, adminUsername)
    if isCameraOrLaserActive() then
        notifyBlockedByCameraLaser()
        return
    end

    if newServerName then serverName = newServerName end

    SetNuiFocus(true, true)

    if isLoggedIn or isNewLogin == true then
        -- Admin is authenticated: open the full panel
        if isNewLogin then isLoggedIn = true end
        isMenuOpen = true

        local showWelcome = wasJustLoggedIn
        wasJustLoggedIn = false

        openAdminPanel(
            sectionPerms      or {},
            optionalSections  or {},
            commandStaffPerms or {},
            adminUsername,
            showWelcome
        )
    else
        -- Not logged in: show the login screen instead
        if isMenuOpen then return end  -- Already showing something
        isMenuOpen = true

        local locale       = (Config and Config.Locale) or "en"
        local translations = (Locales and (Locales[locale] or Locales.en)) or {}
        local allLocales = {}
        if Locales then for lang, tbl in pairs(Locales) do allLocales[lang] = tbl end end

        SendNUIMessage({
            action      = "openLogin",
            serverName  = serverName,
            locale      = locale,
            translations= translations,
            allLocales  = allLocales,
        })
    end
end)

-- ============================================================
-- NET EVENT: loginFailed  (Server → Client)
-- ============================================================
RegisterNetEvent("adminpanel:loginFailed")
AddEventHandler("adminpanel:loginFailed", function()
    SendNUIMessage({ action = "loginFailed" })
end)

-- ============================================================
-- NET EVENT: openMustChangeCredentials  (Server → Client)
-- Forces the admin to set a new username/password before continuing
-- ============================================================
RegisterNetEvent("adminpanel:openMustChangeCredentials")
AddEventHandler("adminpanel:openMustChangeCredentials", function(newServerName)
    if newServerName then serverName = newServerName end

    isMenuOpen = true
    SetNuiFocus(true, true)

    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}
    local allLocales = {}
    if Locales then for lang, tbl in pairs(Locales) do allLocales[lang] = tbl end end

    SendNUIMessage({
        action      = "openMustChangeCredentials",
        serverName  = serverName,
        locale      = locale,
        translations= translations,
        allLocales  = allLocales,
    })
end)

-- ============================================================
-- NUI CALLBACK: setNewCredentials
-- Admin submits their forced first-login credentials
-- ============================================================
RegisterNUICallback("setNewCredentials", function(data, cb)
    local newUsername = (type(data) == "table" and data.newUsername) or ""
    local newPassword = (type(data) == "table" and data.newPassword) or ""
    TriggerServerEvent("adminpanel:setNewCredentials", newUsername, newPassword)
    cb(true)
end)

-- ============================================================
-- NET EVENT: setNewCredentialsResult  (Server → Client → NUI)
-- ============================================================
RegisterNetEvent("adminpanel:setNewCredentialsResult")
AddEventHandler("adminpanel:setNewCredentialsResult", function(success, reason)
    SendNUIMessage({
        action  = "setNewCredentialsResult",
        success = (success == true),
        reason  = reason or "",
    })
end)

-- ============================================================
-- NUI CALLBACK: login
-- Admin submits username/password on the login screen
-- ============================================================
RegisterNUICallback("login", function(data, cb)
    local remember = (data.remember == 1)
    TriggerServerEvent("adminpanel:login",
        data.user     or "",
        data.password or "",
        remember
    )
    cb(true)
end)

-- ============================================================
-- NUI CALLBACK: logout
-- Admin clicks "Logout"; reverts to login screen
-- ============================================================
RegisterNUICallback("logout", function(data, cb)
    TriggerServerEvent("adminpanel:logout")
    isLoggedIn = false

    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}
    local allLocales = {}
    if Locales then for lang, tbl in pairs(Locales) do allLocales[lang] = tbl end end

    SendNUIMessage({
        action      = "openLogin",
        serverName  = serverName,
        locale      = locale,
        translations= translations,
        allLocales  = allLocales,
    })
    cb(true)
end)

-- ============================================================
-- stopSpectate()
-- Exits spectate mode: disables NetworkSetInSpectatorMode,
-- restores local ped visibility/collision/invincibility,
-- teleports back to pre-spectate coords.
-- ============================================================
local function stopSpectate()
    if not spectateState.toggled then return end

    -- Exit GTA's built-in spectator mode
    if NetworkIsInSpectatorMode() then
        local targetEntity = NetworkGetEntityFromNetworkId(spectateState.targetPed)
        if DoesEntityExist(targetEntity) then
            NetworkSetInSpectatorMode(false, targetEntity)
        end
    end

    -- Restore local ped
    local localPed = PlayerPedId()
    SetEntityVisible(localPed, true, 0)
    SetEntityCollision(localPed, true, true)
    SetEntityInvincible(localPed, false)

    -- Reset spectate state
    spectateState = { toggled = false, target = 0, targetPed = 0 }

    -- Teleport back to where we were before spectating
    if preSpectateCoords then
        RequestCollisionAtCoord(preSpectateCoords.x, preSpectateCoords.y, preSpectateCoords.z)
        SetEntityCoords(localPed,
            preSpectateCoords.x,
            preSpectateCoords.y,
            preSpectateCoords.z,
            false, false, false, true
        )
        FreezeEntityPosition(localPed, false)
        preSpectateCoords = nil
    end

    SendNUIMessage({ action = "spectateStopped" })

    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_spectate_exit_title"),
            description = _L("notify_spectate_exit_desc"),
            type        = "inform",
        })
    end
end

-- ============================================================
-- NET EVENT: requestSpectate  (Server → Client)
-- Server tells the client to begin spectating a target ped
-- ============================================================
RegisterNetEvent("adminpanel:requestSpectate")
AddEventHandler("adminpanel:requestSpectate", function(targetNetId, targetServerId, targetCoords, targetInfo)
    -- Save our current position so we can return after spectating
    preSpectateCoords = GetEntityCoords(PlayerPedId())

    -- Teleport near the target if coords were provided
    if targetCoords and targetCoords.x then
        SetEntityCoords(PlayerPedId(),
            targetCoords.x,
            targetCoords.y,
            targetCoords.z + 5.0,
            false, false, false, true
        )
    end

    -- Activate spectate state
    spectateState = {
        toggled   = true,
        target    = targetServerId,
        targetPed = targetNetId,
    }

    -- Hide local ped from others
    local localPed = PlayerPedId()
    SetEntityVisible(localPed, false, 0)
    SetEntityCollision(localPed, false, false)
    SetEntityInvincible(localPed, true)

    -- Close the panel
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeForSpectate" })

    -- Tell the NUI spectate has started (for the HUD overlay)
    SendNUIMessage({
        action = "spectateStarted",
        name   = (targetInfo and targetInfo.name)  or nil,
        id     = targetServerId,
        job    = (targetInfo and targetInfo.job)   or nil,
        group  = (targetInfo and targetInfo.group) or nil,
    })
end)

-- ============================================================
-- NET EVENT: cancelSpectate  (Server → Client)
-- Server orders the client to exit spectate mode
-- ============================================================
RegisterNetEvent("adminpanel:cancelSpectate")
AddEventHandler("adminpanel:cancelSpectate", function()
    stopSpectate()
end)

-- ============================================================
-- NUI CALLBACK: cancelSpectate
-- Admin presses the "Stop Spectating" button in the NUI
-- ============================================================
RegisterNUICallback("cancelSpectate", function(data, cb)
    stopSpectate()
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: close
-- Admin closes the full admin panel. Also exits spectate if
-- active and closes kick-actions if it was open.
-- ============================================================
RegisterNUICallback("close", function(data, cb)
    isMenuOpen = false
    stopSpectate()

    if isKickActionsOpen then
        SendNUIMessage({ action = "closeKickActions" })
        isKickActionsOpen = false
        SetNuiFocusKeepInput(false)
    end

    SetNuiFocus(false, false)
    cb(true)
end)

-- ============================================================
-- formatCoordsTable(x, y, z, heading)
-- Returns a table of coordinate strings in multiple formats
-- for the Coords UI overlay.
---@param x       number
---@param y       number
---@param z       number
---@param heading number|nil
---@return table {lua, normal, vector3, vector4}
-- ============================================================
local function formatCoordsTable(x, y, z, heading)
    local sx = string.format("%.2f", x)
    local sy = string.format("%.2f", y)
    local sz = string.format("%.2f", z)
    local sh = heading and string.format("%.2f", heading) or "0.00"
    return {
        lua     = string.format("x = %s, y = %s, z = %s", sx, sy, sz),
        normal  = string.format("%s, %s, %s", sx, sy, sz),
        vector3 = string.format("vector3(%s, %s, %s)", sx, sy, sz),
        vector4 = string.format("vector4(%s, %s, %s, %s)", sx, sy, sz, sh),
    }
end

-- ============================================================
-- CAMERA MODE STATE
-- ============================================================
local isLaserLineActive  = false          -- Whether the coords UI "laser line" is drawn
local cameraHandle       = nil            -- Scripted camera handle (nil when not in use)
local cameraPosition     = vector3(0,0,0) -- Free-cam world position
local cameraRotation     = vector3(0,0,0) -- Free-cam rotation (Euler degrees)
local pressedKeys        = {}             -- Map of currently held keys (from NUI)
local shiftPressed       = false          -- Whether Shift is held (speed multiplier)
local cameraInfoMode     = 1             -- Camera HUD display mode (1-3, cycles)

-- Camera movement speed tiers: slow / normal / fast
local cameraSpeeds = { 0.25, 0.7, 1.8 }

-- Controls that toggle camera HUD info (LookLeft/PhoneSelect)
local cameraToggleKeys = { 200, 322 }

-- Controls that exit camera mode (MoveUpDown / PrevWeapon / NextWeapon / NextCamera)
local cameraExitKeys = { 178, 194, 261, 177 }

-- Control that cycles camera info mode display (Sprint = 244)
local cameraModeToggleKey = 244

-- ============================================================
-- eulerToDirectionVector(rotation)
-- Converts Euler rotation {x, y, z} (degrees) to a normalised
-- direction vector (dx, dy, dz).
-- ============================================================
local function eulerToDirectionVector(rotation)
    local rx  = math.rad(rotation.x)
    local rz  = math.rad(rotation.z)
    local dx  = -math.sin(rz) * math.cos(rx)
    local dy  =  math.cos(rz) * math.cos(rx)
    local dz  =  math.sin(rx)
    local len =  math.sqrt(dx*dx + dy*dy + dz*dz)
    if len > 0 then dx, dy, dz = dx/len, dy/len, dz/len end
    return dx, dy, dz
end

-- Returns the normalised direction vector of the gameplay camera,
-- computed from the camera's relative heading and pitch.
local function getCameraDirectionVector()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch   = GetGameplayCamRelativePitch()
    local dx  = -math.sin(heading * math.pi / 180.0)
    local dy  =  math.cos(heading * math.pi / 180.0)
    local dz  =  math.sin(pitch   * math.pi / 180.0)
    local len =  math.sqrt(dx*dx + dy*dy + dz*dz)
    if len ~= 0 then dx, dy, dz = dx/len, dy/len, dz/len end
    return dx, dy, dz
end

-- ============================================================
-- exitCameraMode()
-- Tears down the scripted camera and reopens the Coords UI
-- at the camera's last known position.
-- ============================================================
local function exitCameraMode()
    if not isCameraMode then return end
    isCameraMode = false
    pressedKeys  = {}
    shiftPressed = false
    SendNUIMessage({ action = "showCameraInfo", show = false })

    if cameraHandle and DoesCamExist(cameraHandle) then
        RenderScriptCams(false, false, 0)
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end

    -- Reopen Coords UI at the last camera position/heading
    local cx, cy, cz = cameraPosition.x, cameraPosition.y, cameraPosition.z
    local displayH   = cameraRotation and math.floor((cameraRotation.z + 360) % 360) or 0

    isCoordsUIOpen = true
    SetNuiFocus(true, true)

    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}

    SendNUIMessage({
        action       = "openCoordsUI",
        coords       = formatCoordsTable(cx, cy, cz, displayH),
        laserOn      = isLaserLineActive,
        cameraOn     = false,
        locale       = locale,
        translations = translations,
    })
end

-- ============================================================
-- ENTITY LASER STATE
-- ============================================================
local hoveredEntity        = nil  -- Entity under the laser crosshair (or nil)
local entityLaserSelectKey = 191  -- Control: Enter  → select/delete entity
local entityLaserExitKey   = 194  -- Control: Backspace → exit laser mode

-- ============================================================
-- getEntityTypeName(typeId)  →  "Ped" | "Vehicle" | "Object" | "Unknown"
-- ============================================================
local function getEntityTypeName(typeId)
    if     typeId == 1 then return "Ped"
    elseif typeId == 2 then return "Vehicle"
    elseif typeId == 3 then return "Object"
    else                    return "Unknown"
    end
end

-- ============================================================
-- rotationToDirection(rotation)
-- Converts an Euler rotation table {x,y,z} (degrees) to a
-- direction vector table using standard GTA math.
-- ============================================================
local function rotationToDirection(rotation)
    local r = { x = math.pi/180*rotation.x, y = math.pi/180*rotation.y, z = math.pi/180*rotation.z }
    return {
        x = -math.sin(r.z) * math.abs(math.cos(r.x)),
        y =  math.cos(r.z) * math.abs(math.cos(r.x)),
        z =  math.sin(r.x),
    }
end

-- ============================================================
-- getCameraRaycastHit(distance)
-- Fires a ray from the gameplay camera and returns shape-test results.
---@param distance number Ray length in units
---@return number hitStatus, table hitCoords, number hitEntity
-- ============================================================
local function getCameraRaycastHit(distance)
    local cr1, cr2, cr3 = GetGameplayCamRot()
    local cp1, cp2, cp3 = GetGameplayCamCoord()

    -- Normalise rotation (handle vector3 or multi-return)
    local rot, pos = {}, {}
    if type(cr1) == "number" then
        rot = { x = cr1 or 0, y = cr2 or 0, z = cr3 or 0 }
    else
        rot = { x = (cr1.x or 0), y = (cr1.y or 0), z = (cr1.z or 0) }
    end
    if type(cp1) == "number" then
        pos = { x = cp1 or 0, y = cp2 or 0, z = cp3 or 0 }
    else
        pos = { x = (cp1.x or 0), y = (cp1.y or 0), z = (cp1.z or 0) }
    end

    local dir    = rotationToDirection(rot)
    local endPos = { x = pos.x + dir.x*distance, y = pos.y + dir.y*distance, z = pos.z + dir.z*distance }

    local rayHandle              = StartShapeTestRay(pos.x, pos.y, pos.z, endPos.x, endPos.y, endPos.z, -1, PlayerPedId(), 0)
    local hitStatus, _, hitCoords, hitEntity = GetShapeTestResult(rayHandle)
    return hitStatus, hitCoords, hitEntity
end

-- ============================================================
-- DrawEntityBoundingBox(entity, color)
-- Draws a 12-edge oriented wireframe box around an entity.
-- Exported globally so other resources may call it.
---@param entity number  Entity handle
---@param color  table   {r, g, b, a}
-- ============================================================
local function DrawEntityBoundingBox(entity, color)
    local model          = GetEntityModel(entity)
    local minDim, maxDim = GetModelDimensions(model)
    local fwd, right, up, worldPos = GetEntityMatrix(entity)

    -- Half-extents
    local hx = 0.5 * (maxDim.x - minDim.x)
    local hy = 0.5 * (maxDim.y - minDim.y)
    local hz = 0.5 * (maxDim.z - minDim.z)

    -- +Y ground-centre corner (front-bottom)
    local fc = {}
    fc.x = worldPos.x + hy*fwd.x + hx*right.x + hz*up.x
    fc.y = worldPos.y + hy*fwd.y + hx*right.y + hz*up.y
    fc.z = 0
    local _, gz = GetGroundZFor_3dCoord(fc.x, fc.y, 1000.0, 0)
    fc.z = gz + 2*hz

    -- -Y ground-opposite corner (back-bottom)
    local oc = {}
    oc.x = worldPos.x - hy*fwd.x - hx*right.x - hz*up.x
    oc.y = worldPos.y - hy*fwd.y - hx*right.y - hz*up.y
    oc.z = 0
    local _, gz2 = GetGroundZFor_3dCoord(fc.x, fc.y, 1000.0, 0)
    oc.z = gz2

    -- 8 corners computed from the ground centres and axis vectors
    -- a = oc shifted +fwd*2y   (front-bottom near)
    local a = { x=oc.x+2*hy*fwd.x,   y=oc.y+2*hy*fwd.y,   z=oc.z+2*hy*fwd.z   }
    -- b = a + up*2z             (front-top near)
    local b = { x=a.x+2*hz*up.x,      y=a.y+2*hz*up.y,      z=a.z+2*hz*up.z      }
    -- c = oc + up*2z            (back-top near)
    local c = { x=oc.x+2*hz*up.x,     y=oc.y+2*hz*up.y,     z=oc.z+2*hz*up.z     }
    -- d = fc - fwd*2y           (back-bottom far)
    local d = { x=fc.x-2*hy*fwd.x,    y=fc.y-2*hy*fwd.y,    z=fc.z-2*hy*fwd.z    }
    -- e = d - up*2z             (back-bottom far low)
    local e = { x=d.x-2*hz*up.x,      y=d.y-2*hz*up.y,      z=d.z-2*hz*up.z      }
    -- f = fc - up*2z            (front-bottom far low)
    local f = { x=fc.x-2*hz*up.x,     y=fc.y-2*hz*up.y,     z=fc.z-2*hz*up.z     }

    local r, g, bl, al = color.r, color.g, color.b, color.a

    -- Bottom face
    DrawLine(oc.x,oc.y,oc.z, a.x,a.y,a.z, r,g,bl,al)
    DrawLine(oc.x,oc.y,oc.z, c.x,c.y,c.z, r,g,bl,al)
    DrawLine(a.x,a.y,a.z,    b.x,b.y,b.z, r,g,bl,al)
    DrawLine(b.x,b.y,b.z,    c.x,c.y,c.z, r,g,bl,al)
    -- Top face
    DrawLine(fc.x,fc.y,fc.z, d.x,d.y,d.z, r,g,bl,al)
    DrawLine(fc.x,fc.y,fc.z, f.x,f.y,f.z, r,g,bl,al)
    DrawLine(d.x,d.y,d.z,    e.x,e.y,e.z, r,g,bl,al)
    DrawLine(e.x,e.y,e.z,    f.x,f.y,f.z, r,g,bl,al)
    -- Vertical edges
    DrawLine(oc.x,oc.y,oc.z, e.x,e.y,e.z, r,g,bl,al)
    DrawLine(a.x,a.y,a.z,    f.x,f.y,f.z, r,g,bl,al)
    DrawLine(b.x,b.y,b.z,    fc.x,fc.y,fc.z, r,g,bl,al)
    DrawLine(c.x,c.y,c.z,    d.x,d.y,d.z, r,g,bl,al)
end

-- Export as a global so other scripts can call DrawEntityBoundingBox(entity, color)
DrawEntityBoundingBox = DrawEntityBoundingBox

-- ============================================================
-- NUI CALLBACK: entityLaserStart
-- Activates entity-laser selection mode. Closes Coords UI if open.
-- ============================================================
RegisterNUICallback("entityLaserStart", function(data, cb)
    if isCoordsUIOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeCoordsUI" })
    end
    isEntityLaserMode = true
    hoveredEntity     = nil
    SendNUIMessage({ action = "entityLaserShow", show = true })
    if lib and lib.notify then
        lib.notify({
            title       = _L("notify_entity_laser_hint_title"),
            description = _L("notify_entity_laser_hint_desc"),
            type        = "inform",
        })
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: entityLaserExit
-- Deactivates entity-laser mode
-- ============================================================
RegisterNUICallback("entityLaserExit", function(data, cb)
    isEntityLaserMode = false
    hoveredEntity     = nil
    SendNUIMessage({ action = "entityLaserShow", show = false })
    cb("ok")
end)

-- ============================================================
-- NET EVENT: clientDeleteEntityByNetId  (Server → Client)
-- Deletes an entity by its network ID on this client
-- ============================================================
RegisterNetEvent("admin:clientDeleteEntityByNetId")
AddEventHandler("admin:clientDeleteEntityByNetId", function(netId)
    if not netId or netId < 1 then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end)

-- ============================================================
-- forceAdminPanelCloseAndLogout()
-- Emergency close: exits all modes, logs out, closes all UI.
-- Called by server via net event when session is terminated.
-- ============================================================
local function forceAdminPanelCloseAndLogout()
    -- Exit entity laser
    if isEntityLaserMode then
        isEntityLaserMode = false
        hoveredEntity     = nil
        SendNUIMessage({ action = "entityLaserShow", show = false })
    end

    -- Exit camera / coords UI
    if isCoordsUIOpen or isCameraMode then
        if isCameraMode then
            isCameraMode = false
            pressedKeys  = {}
            shiftPressed = false
            SendNUIMessage({ action = "showCameraInfo", show = false })
            if cameraHandle and DoesCamExist(cameraHandle) then
                RenderScriptCams(false, false, 0)
                DestroyCam(cameraHandle, false)
                cameraHandle = nil
            end
        end
        isLaserLineActive = false
        isCoordsUIOpen    = false
        SendNUIMessage({ action = "closeCoordsUI" })
    end

    -- Log out and close panel
    isMenuOpen = false
    isLoggedIn = false
    stopSpectate()

    if isKickActionsOpen then
        SendNUIMessage({ action = "closeKickActions" })
        isKickActionsOpen = false
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({ action = "close" })
    CreateThread(function()
        Wait(120)
        SetNuiFocus(false, false)
    end)
end

RegisterNetEvent("adminpanel:forceAdminPanelCloseAndLogout")
AddEventHandler("adminpanel:forceAdminPanelCloseAndLogout", forceAdminPanelCloseAndLogout)

-- ============================================================
-- MAIN GAME LOOP THREAD
-- Per-frame logic for entity laser, laser line, camera, spectate.
-- ============================================================
CreateThread(function()
    local CAM_SENSITIVITY = 4.0

    -- Colours for laser line / entity highlight
    local LL_R, LL_G, LL_B     = 35,  70,  145  -- Entity-laser beam (blue)
    local LE_R, LE_G, LE_B     = 200, 200, 200  -- No-hit beam (grey)

    while true do

        -- ======================================================
        -- ENTITY LASER MODE
        -- ======================================================
        if isEntityLaserMode then
            local pedPos                    = GetEntityCoords(PlayerPedId())
            local hitStatus, hitCoords, hitEntity = getCameraRaycastHit(1000.0)

            local isValid = hitStatus and hitEntity and hitEntity ~= 0
                         and (IsEntityAVehicle(hitEntity)
                              or IsEntityAPed(hitEntity)
                              or IsEntityAnObject(hitEntity))

            if isValid then
                local eType, eModel, eHP, eMaxHP, eNetId = 0, 0, 0, 1000, 0
                local ok = pcall(function()
                    eType   = GetEntityType(hitEntity)
                    eModel  = GetEntityModel(hitEntity)
                    if eType == 1 or eType == 2 then
                        eHP    = GetEntityHealth(hitEntity)
                        eMaxHP = GetEntityMaxHealth(hitEntity)
                        if eMaxHP < 1 then eMaxHP = 200 end
                    else
                        eHP = 1000 ; eMaxHP = 1000
                    end
                    eNetId = NetworkGetNetworkIdFromEntity(hitEntity)
                end)

                if ok then
                    hoveredEntity = hitEntity
                    local dist    = #(pedPos - vector3(hitCoords.x, hitCoords.y, hitCoords.z))
                    local netStr  = (eNetId and eNetId ~= 0) and tostring(eNetId) or "Local"

                    SendNUIMessage({
                        action    = "entityLaserUpdate",
                        show      = true,
                        hasEntity = true,
                        entityType= getEntityTypeName(eType),
                        hash      = tostring(eModel),
                        health    = eHP,
                        maxHealth = eMaxHP,
                        entityId  = hitEntity,
                        netId     = netStr,
                        dist      = string.format("%.2fm", dist),
                    })

                    -- Draw laser beam and bounding box
                    DrawLine(pedPos.x, pedPos.y, pedPos.z, hitCoords.x, hitCoords.y, hitCoords.z,
                             LL_R, LL_G, LL_B, 255)
                    DrawEntityBoundingBox(hitEntity, { r=LL_R, g=LL_G, b=LL_B, a=255 })
                else
                    hoveredEntity = nil
                    SendNUIMessage({ action="entityLaserUpdate", show=true, hasEntity=false, dist="" })
                end
            else
                hoveredEntity = nil
                -- Draw grey beam toward surface even when no entity hit
                if hitCoords and hitCoords.x and hitCoords.y and hitCoords.z
                   and hitCoords.x ~= 0.0 and hitCoords.y ~= 0.0 then
                    DrawLine(pedPos.x, pedPos.y, pedPos.z, hitCoords.x, hitCoords.y, hitCoords.z,
                             LE_R, LE_G, LE_B, 220)
                end
                SendNUIMessage({ action="entityLaserUpdate", show=true, hasEntity=false, dist="" })
            end

            -- BACKSPACE → exit laser, open coords UI
            if IsControlJustPressed(0, entityLaserExitKey) then
                isEntityLaserMode = false
                hoveredEntity     = nil
                SendNUIMessage({ action = "entityLaserShow", show = false })

                local ped          = PlayerPedId()
                local px,py,pz     = table.unpack(GetEntityCoords(ped, true))
                local ph           = GetEntityHeading(ped)
                isCoordsUIOpen     = true
                SetNuiFocus(true, true)
                local locale       = (Config and Config.Locale) or "en"
                local translations = (Locales and (Locales[locale] or Locales.en)) or {}
                SendNUIMessage({
                    action="openCoordsUI", coords=formatCoordsTable(px,py,pz,ph),
                    laserOn=isLaserLineActive, cameraOn=isCameraMode,
                    locale=locale, translations=translations,
                })

            -- ENTER → delete hovered entity
            elseif IsControlJustPressed(0, entityLaserSelectKey) then
                if hoveredEntity and DoesEntityExist(hoveredEntity) then
                    if NetworkGetEntityIsNetworked(hoveredEntity) then
                        TriggerServerEvent("admin:deleteEntityByNetId",
                            NetworkGetNetworkIdFromEntity(hoveredEntity))
                    else
                        SetEntityAsMissionEntity(hoveredEntity, true, true)
                        DeleteEntity(hoveredEntity)
                    end
                    hoveredEntity = nil
                    if lib and lib.notify then
                        lib.notify({
                            title       = _L("notify_entity_laser_entity_deleted_title"),
                            description = _L("notify_entity_laser_entity_deleted_desc"),
                            type        = "success",
                        })
                    end
                end
            end

            Wait(0)

        -- ======================================================
        -- LASER LINE MODE (coords UI with laser toggled on)
        -- ======================================================
        elseif isLaserLineActive then
            local ped             = PlayerPedId()
            local cx, cy, cz      = table.unpack(GetGameplayCamCoord())
            local dx, dy, dz      = getCameraDirectionVector()
            local ex, ey, ez      = cx+dx*1000, cy+dy*1000, cz+dz*1000

            local ray = StartShapeTestRay(cx, cy, cz, ex, ey, ez, -1, ped, 0)
            local _, hitPos, _ = GetShapeTestResult(ray)

            if hitPos and hitPos.x and hitPos.y and hitPos.z then
                DrawLine(cx, cy, cz, hitPos.x, hitPos.y, hitPos.z, 255, 0, 0, 255)
            else
                DrawLine(cx, cy, cz, ex, ey, ez, 255, 0, 0, 255)
            end

            Wait(0)

        -- ======================================================
        -- FREE-CAM MODE
        -- ======================================================
        elseif isCameraMode then
            if cameraHandle then
                -- Block conflicting gameplay controls
                DisableControlAction(0, 32, true)   -- MoveUpDown
                DisableControlAction(0, 33, true)   -- MoveLeftRight
                DisableControlAction(0, 34, true)   -- Sprint
                DisableControlAction(0, 35, true)   -- Jump
                DisableControlAction(0, 44, true)   -- Cover
                DisableControlAction(0, 38, true)   -- Enter
                DisableControlAction(0, 22, true)   -- Jump (alt)
                for _, c in ipairs(cameraToggleKeys) do DisableControlAction(0, c, true) end
                for _, c in ipairs(cameraExitKeys)   do DisableControlAction(0, c, true) end

                -- Check exit
                local doExit = false
                for _, c in ipairs(cameraToggleKeys) do
                    if IsDisabledControlJustPressed(0, c) then doExit = true; break end
                end
                for _, c in ipairs(cameraExitKeys) do
                    if IsDisabledControlJustPressed(0, c) then doExit = true; break end
                end

                if doExit then
                    exitCameraMode()
                else
                    -- Cycle info mode with Sprint key
                    if IsDisabledControlJustPressed(0, cameraModeToggleKey) then
                        cameraInfoMode = (cameraInfoMode % 3) + 1
                        SendNUIMessage({ action = "cameraInfoSetMode", mode = cameraInfoMode })
                    end

                    -- Movement speed (Shift multiplies by 6)
                    local speed     = cameraSpeeds[cameraInfoMode] or 0.7
                    local fast      = shiftPressed or IsControlPressed(0, 21)
                    local moveSpeed = speed * (fast and 6 or 1)

                    local fdx, fdy, fdz = eulerToDirectionVector(cameraRotation)

                    if pressedKeys.KeyW then
                        cameraPosition = cameraPosition + vector3(fdx*moveSpeed, fdy*moveSpeed, fdz*moveSpeed)
                    end
                    if pressedKeys.KeyS then
                        cameraPosition = cameraPosition - vector3(fdx*moveSpeed, fdy*moveSpeed, fdz*moveSpeed)
                    end
                    if pressedKeys.KeyQ then
                        cameraPosition = cameraPosition + vector3(0, 0, moveSpeed)
                    end
                    if pressedKeys.KeyE then
                        cameraPosition = cameraPosition - vector3(0, 0, moveSpeed)
                    end

                    -- Mouse look
                    local mouseX = GetDisabledControlNormal(0, 1)
                    local mouseY = GetDisabledControlNormal(0, 2)
                    local newX   = math.max(-89.0, math.min(89.0, cameraRotation.x - mouseY * CAM_SENSITIVITY))
                    local newZ   = cameraRotation.z - mouseX * CAM_SENSITIVITY
                    cameraRotation = vector3(newX, cameraRotation.y, newZ)

                    SetCamCoord(cameraHandle, cameraPosition.x, cameraPosition.y, cameraPosition.z)
                    SetCamRot(cameraHandle, cameraRotation.x, cameraRotation.y, cameraRotation.z, 2)
                end
            end
            Wait(0)

        -- ======================================================
        -- SPECTATE MODE
        -- ======================================================
        elseif spectateState.toggled then
            local targetEntity = NetworkGetEntityFromNetworkId(spectateState.targetPed)
            if DoesEntityExist(targetEntity) then
                local localPed = PlayerPedId()
                SetEntityVisible(localPed, false, 0)
                SetEntityCollision(localPed, false, false)
                SetEntityInvincible(localPed, true)

                if not NetworkIsInSpectatorMode() then
                    RequestCollisionAtCoord(GetEntityCoords(targetEntity))
                    NetworkSetInSpectatorMode(true, targetEntity)
                end
                Wait(0)
            else
                Wait(500)
            end

        else
            Wait(500)  -- All modes off — low frequency poll
        end
    end
end)

-- ============================================================
-- NET EVENT: openCoordsUI  (Local event from admin:openCoordsUI)
-- Opens the coordinate viewer at the player's current position
-- ============================================================
RegisterNetEvent("admin:openCoordsUI")
AddEventHandler("admin:openCoordsUI", function()
    if isCameraOrLaserActive() then
        notifyBlockedByCameraLaser()
        return
    end

    local ped          = PlayerPedId()
    local px, py, pz   = table.unpack(GetEntityCoords(ped, true))
    local ph           = GetEntityHeading(ped)
    local coordsTable  = formatCoordsTable(px, py, pz, ph)

    isCoordsUIOpen = true
    SetNuiFocus(true, true)

    local locale       = (Config and Config.Locale) or "en"
    local translations = (Locales and (Locales[locale] or Locales.en)) or {}

    SendNUIMessage({
        action       = "openCoordsUI",
        coords       = coordsTable,
        laserOn      = isLaserLineActive,
        cameraOn     = isCameraMode,
        locale       = locale,
        translations = translations,
    })
end)

-- ============================================================
-- NUI CALLBACK: cameraKeyState
-- Receives key down/up events from the NUI while camera mode is
-- active. Tracks pressedKeys and handles special keys.
-- ============================================================
RegisterNUICallback("cameraKeyState", function(data, cb)
    if data and data.key then
        local k = tostring(data.key)
        pressedKeys[k] = data.pressed and true or nil

        if k == "ShiftLeft" or k == "ShiftRight" then
            shiftPressed = data.pressed
        end

        if data.pressed and (k == "Delete" or k == "Escape") then
            exitCameraMode()
        elseif data.pressed and k == "KeyM" and isCameraMode then
            cameraInfoMode = (cameraInfoMode % 3) + 1
            SendNUIMessage({ action = "cameraInfoSetMode", mode = cameraInfoMode })
        end
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: closeCoordsUI
-- Closes the coords overlay and tears down camera if active
-- ============================================================
RegisterNUICallback("closeCoordsUI", function(data, cb)
    if isCameraMode then
        isCameraMode = false
        pressedKeys  = {}
        shiftPressed = false
        SendNUIMessage({ action = "showCameraInfo", show = false })
        if cameraHandle and DoesCamExist(cameraHandle) then
            RenderScriptCams(false, false, 0)
            DestroyCam(cameraHandle, false)
            cameraHandle = nil
        end
    end
    isLaserLineActive = false
    isCoordsUIOpen    = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeCoordsUI" })
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: coordsUiToggleLaser
-- Toggles the laser line on/off within the Coords UI
-- ============================================================
RegisterNUICallback("coordsUiToggleLaser", function(data, cb)
    isLaserLineActive = not isLaserLineActive
    SendNUIMessage({ action = "coordsUiSetLaser", on = isLaserLineActive })
    cb({ ok = true, on = isLaserLineActive })
end)

-- ============================================================
-- NUI CALLBACK: coordsUiToggleCamera
-- Toggles free-cam mode on/off from the Coords UI
-- ============================================================
RegisterNUICallback("coordsUiToggleCamera", function(data, cb)
    isCameraMode = not isCameraMode

    if isCameraMode then
        -- Entering camera mode
        pressedKeys = {}
        SendNUIMessage({ action = "closeCoordsUI" })
        isCoordsUIOpen = false
        SetNuiFocus(true, false)  -- Keep NUI active for key events, no cursor
        SendNUIMessage({ action = "showCameraInfo", show = true, mode = cameraInfoMode })

        -- Snap to gameplay cam position/rotation
        local rr1, rr2, rr3 = GetGameplayCamRot(2)
        local rc1, rc2, rc3 = GetGameplayCamCoord()

        -- Normalise multi-return or vector3 into plain numbers
        local function toNums3(a, b, c)
            if type(a) == "number" then return a or 0, b or 0, c or 0
            else return (a.x or 0), (a.y or 0), (a.z or 0) end
        end
        local rx, ry, rz = toNums3(rr1, rr2, rr3)
        local cx, cy, cz = toNums3(rc1, rc2, rc3)

        cameraPosition = vector3(cx, cy, cz)
        cameraRotation = vector3(rx, ry, rz)

        cameraHandle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(cameraHandle, cx, cy, cz)
        SetCamRot(cameraHandle, rx, ry, rz, 2)
        RenderScriptCams(true, false, 0)
        SetCamActive(cameraHandle, true)
    else
        -- Exiting camera mode
        pressedKeys  = {}
        shiftPressed = false
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "showCameraInfo", show = false })
        if cameraHandle and DoesCamExist(cameraHandle) then
            RenderScriptCams(false, false, 0)
            DestroyCam(cameraHandle, false)
            cameraHandle = nil
        end
    end

    SendNUIMessage({ action = "coordsUiSetCamera", on = isCameraMode })
    cb({ ok = true, on = isCameraMode })
end)

-- ============================================================
-- NUI CALLBACK: changeTime
-- Admin changes server time / weather
-- ============================================================
RegisterNUICallback("changeTime", function(data, cb)
    if data and type(data.hour) == "number" then
        TriggerServerEvent("admin:changeTime",
            data.hour,
            data.freeze           or false,
            data.showNotification or false,
            data.weather          or nil
        )
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: playersRequestList
-- Fetches online + offline player list from server
-- ============================================================
RegisterNUICallback("playersRequestList", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getPlayersList", false, function(result)
        SendNUIMessage({
            action  = "setPlayersList",
            online  = (result and result.online)  or {},
            offline = (result and result.offline) or {},
        })
    end)
end)

-- ============================================================
-- getVehicleDisplayName(modelHashOrName)
-- Returns a title-cased display name for a vehicle model.
-- Returns nil for unknown models.
---@param modelHashOrName number|string
---@return string|nil
-- ============================================================
local function getVehicleDisplayName(modelHashOrName)
    if not modelHashOrName then return nil end
    local hash = modelHashOrName
    if type(hash) ~= "number" then
        hash = GetHashKey(tostring(hash))
    end
    if not hash or hash == 0 then return nil end
    local name = GetDisplayNameFromVehicleModel(hash)
    if not name or name == "" then return nil end
    if name:upper() == "CARNOTFOUND" then return nil end
    return name:sub(1,1):upper() .. name:sub(2):lower()
end

-- ============================================================
-- NUI CALLBACK: requestPlayerDetails
-- Fetches player detail data from the server and sends it to the NUI.
-- Supports both online players (by server ID) and offline players
-- (by identifier string). Uses playerDetailRequestSeq to discard
-- stale responses when a newer request was made.
-- ============================================================
RegisterNUICallback("requestPlayerDetails", function(data, cb)
    local playerId         = (type(data) == "table") and data.playerId or nil
    local playerIdNum      = (playerId ~= nil and playerId ~= "") and tonumber(playerId) or nil
    local offlineId        = (type(data) == "table") and data.offlineIdentifier or nil
    local uiNonce          = 0

    -- Trim whitespace from offlineIdentifier
    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+", ""):gsub("%s+$", "")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    -- Read uiNonce (prevents stale responses from being shown)
    if type(data) == "table" and data.uiNonce ~= nil then
        uiNonce = tonumber(data.uiNonce) or 0
    end

    if (not playerIdNum or playerIdNum == 0) and not offlineIdTrimmed then
        cb("ok")
        return
    end

    -- Increment the global sequence counter so earlier in-flight callbacks are ignored
    playerDetailRequestSeq = playerDetailRequestSeq + 1
    local mySeq = playerDetailRequestSeq

    -- Helper: enriches vehicle list with display names
    local function enrichVehicles(result)
        if result.vehicles and #result.vehicles > 0 then
            for i = 1, #result.vehicles do
                local v     = result.vehicles[i]
                local model = v.model or v.name
                local dname = getVehicleDisplayName(model)
                if dname and dname ~= "" and dname:upper() ~= "CARNOTFOUND" then
                    v.name = dname
                end
            end
        end
    end

    if offlineIdTrimmed then
        -- Offline player path
        lib.callback("adminpanel:getOfflinePlayerDetails", false, function(result)
            if mySeq ~= playerDetailRequestSeq then return end  -- Stale
            result = result or {}
            if result.firstname   == nil then result.firstname   = "N/A"        end
            if result.lastname    == nil then result.lastname    = "N/A"        end
            if result.job         == nil then result.job         = "Unemployed" end
            if result.job_grade   == nil then result.job_grade   = "\226\128\148" end
            if result.organization== nil then result.organization= "None"       end
            if result.money       == nil then result.money       = 0            end
            if result.bank        == nil then result.bank        = 0            end
            enrichVehicles(result)
            SendNUIMessage({ action="openPlayerDetail", player=result, detailReqSeq=mySeq, uiNonce=uiNonce })
        end, offlineIdTrimmed)
        cb("ok")
        return
    end

    -- Online player path
    lib.callback("adminpanel:getPlayerDetails", false, function(result)
        if mySeq ~= playerDetailRequestSeq then return end  -- Stale
        result = result or {}
        if result.firstname   == nil then result.firstname   = "N/A"        end
        if result.lastname    == nil then result.lastname    = "N/A"        end
        if result.job         == nil then result.job         = "Unemployed" end
        if result.job_grade   == nil then result.job_grade   = "\226\128\148" end
        if result.organization== nil then result.organization= "None"       end
        if result.money       == nil then result.money       = 0            end
        if result.bank        == nil then result.bank        = 0            end
        enrichVehicles(result)
        SendNUIMessage({ action="openPlayerDetail", player=result, detailReqSeq=mySeq, uiNonce=uiNonce })

        -- Fetch headshot: register → wait ready → send URL while handle alive → free after 3s
        CreateThread(function()
            Wait(200)
            local serverIdNum = math.floor(tonumber(playerIdNum) or 0)
            if serverIdNum == 0 then return end
            for attempt = 1, 10 do
                if mySeq ~= playerDetailRequestSeq then return end
                local localPlayer = GetPlayerFromServerId(serverIdNum)
                if localPlayer == nil or localPlayer < 0 or GetPlayerServerId(localPlayer) ~= serverIdNum then
                    Wait(1000)
                else
                    local ped = GetPlayerPed(localPlayer)
                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                        local handle = RegisterPedheadshot(ped)
                        if handle and handle ~= 0 then
                            local deadline = GetGameTimer() + 5000
                            while not IsPedheadshotReady(handle) do
                                if GetGameTimer() > deadline then break end
                                Wait(0)
                            end
                            if IsPedheadshotReady(handle) then
                                local txd = GetPedheadshotTxdString(handle)
                                if txd and txd ~= "" then
                                    if mySeq == playerDetailRequestSeq then
                                        local imgUrl = ("https://nui-img/%s/%s"):format(txd, txd)
                                        -- Send URL BEFORE unregistering so the texture is still alive when NUI renders it
                                        SendNUIMessage({ action="setPlayerDetailHeadshot", url=imgUrl, forPlayerId=serverIdNum, detailReqSeq=mySeq, uiNonce=uiNonce })
                                        Wait(3000) -- keep handle alive long enough for browser to load it
                                    end
                                    UnregisterPedheadshot(handle)
                                    return
                                end
                            end
                            UnregisterPedheadshot(handle)
                        end
                    end
                    Wait(1000)
                end
            end
        end)
    end, playerIdNum)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: deletePlayerVehicle
-- Removes a specific vehicle (by plate) from a player's garage.
-- Supports both online (by server ID) and offline (by identifier).
-- ============================================================
RegisterNUICallback("deletePlayerVehicle", function(data, cb)
    local playerId       = (type(data) == "table") and data.playerId or nil
    local plate          = (type(data) == "table") and data.plate    or nil
    local offlineId      = (type(data) == "table") and data.offlineIdentifier or nil

    -- Trim offlineIdentifier
    local offlineIdTrimmed = ""
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+",""):gsub("%s+$","")
    end

    -- Require a valid plate
    if not plate or tostring(plate) == "" then cb("ok"); return end

    if offlineIdTrimmed ~= "" then
        TriggerServerEvent("adminpanel:deletePlayerVehicleOffline", offlineIdTrimmed, tostring(plate))
    elseif playerId then
        TriggerServerEvent("adminpanel:deletePlayerVehicle", tonumber(playerId) or playerId, tostring(plate))
    else
        cb("ok")
        return
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: playerDetailAction
-- Handles all action buttons inside the player detail panel
-- (spectate, capture, bring, goto, freeze, return, skin,
--  kill, clearinv, instancia, kick, revive, ck).
-- "kick", "spawnvehicle", "money", "items", "job" are handled
-- elsewhere (server-side modal or separate NUI callbacks).
-- ============================================================
RegisterNUICallback("playerDetailAction", function(data, cb)
    local action     = (type(data) == "table") and data.action or nil
    local playerId   = (type(data) == "table") and data.playerId or nil
    local offlineId  = (type(data) == "table") and data.offlineIdentifier or nil

    local offlineIdTrimmed = ""
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+",""):gsub("%s+$","")
    end

    -- "ck" only needs an offline ID; other actions need an online player ID too
    local ckOfflineOnly = (action == "ck") and (offlineIdTrimmed ~= "")
    if not action or (not playerId and not ckOfflineOnly) then
        cb("ok"); return
    end

    if action == "spectate" then
        isMenuOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeForSpectate" })
        TriggerServerEvent("adminpanel:requestSpectate", playerId)

    elseif action == "capture" then
        TriggerServerEvent("adminpanel:requestViewScreen", playerId)

    elseif action == "bring" or action == "goto" or action == "freeze" or action == "return" then
        TriggerServerEvent("adminpanel:mapAction", action, tonumber(playerId) or playerId)

    elseif action == "skin" then
        TriggerServerEvent("adminpanel:openSkinForPlayer", playerId)

    elseif action == "kill" then
        TriggerServerEvent("adminpanel:killPlayer", playerId)

    elseif action == "clearinv" then
        TriggerServerEvent("adminpanel:clearInventory", playerId)

    elseif action == "instancia" then
        local bucket = (type(data) == "table") and tonumber(data.bucket) or 0
        if bucket == nil or bucket < 0 then bucket = 0 end
        TriggerServerEvent("adminpanel:setPlayerInstance", tonumber(playerId) or playerId, bucket)

    elseif action == "kick" then
        return  -- Handled by a separate kick modal NUI callback

    elseif action == "revive" then
        TriggerServerEvent("adminpanel:revivePlayer", playerId)

    elseif action == "ck" then
        -- Character kill (CK) — online or offline
        local targetId = (type(data) == "table") and data.offlineIdentifier or nil
        if type(targetId) == "string" then
            local trimmed = targetId:gsub("^%s+",""):gsub("%s+$","")
            if trimmed ~= "" then
                TriggerServerEvent("adminpanel:ckPlayerOffline", trimmed)
            else
                TriggerServerEvent("adminpanel:ckPalyer", playerId)  -- typo preserved from original
            end
        else
            TriggerServerEvent("adminpanel:ckPalyer", playerId)
        end

    elseif action == "spawnvehicle" or action == "money"
        or action == "items" or action == "job" then
        return  -- These open sub-modals handled by separate NUI callbacks
    end

    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: requestJobsList
-- Fetches all jobs from the server for the "Assign Job" modal
-- ============================================================
RegisterNUICallback("requestJobsList", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getJobsList", false, function(jobs)
        SendNUIMessage({ action = "setAssignJobList", jobs = jobs or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: requestGangsList
-- Fetches all gangs from the server for the "Assign Gang" modal
-- ============================================================
RegisterNUICallback("requestGangsList", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getGangsList", false, function(gangs)
        SendNUIMessage({ action = "setAssignGangList", gangs = gangs or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: requestGroupsForAssignAdmin
-- Fetches all admin groups for the "Assign Admin" modal
-- ============================================================
RegisterNUICallback("requestGroupsForAssignAdmin", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getGroups", false, function(groups)
        SendNUIMessage({ action = "setAssignAdminList", groups = groups or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: submitAssignAdmin
-- Assigns an admin group to an online player
-- ============================================================
RegisterNUICallback("submitAssignAdmin", function(data, cb)
    local playerId   = (type(data) == "table") and data.playerId   or nil
    local groupName  = (type(data) == "table") and data.groupName  or ""
    if not (playerId and groupName) or groupName == "" then cb("ok"); return end
    TriggerServerEvent("adminpanel:assignAdminGroup", playerId, groupName)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: changeAdminGroupByLicense
-- Changes an admin's group using their license (works for online/offline admins)
-- ============================================================
RegisterNUICallback("changeAdminGroupByLicense", function(data, cb)
    if type(data) ~= "table" or not data.license or not data.newGroup or data.newGroup == "" then
        cb({ ok = false })
        return
    end
    lib.callback("adminpanel:changeAdminGroupByLicense", false, function(ok)
        cb({ ok = ok == true })
    end, data.license, data.newGroup)
end)

-- ============================================================
-- NUI CALLBACK: groupsGetList
-- Returns all groups to the Groups page UI
-- ============================================================
RegisterNUICallback("groupsGetList", function(data, cb)
    lib.callback("adminpanel:getGroups", false, function(groups)
        cb(groups or {})
    end)
end)

-- ============================================================
-- NUI CALLBACK: groupsCreate
-- Creates a new admin group
-- ============================================================
RegisterNUICallback("groupsCreate", function(data, cb)
    cb("ok")
    if type(data) ~= "table" or not data.grupo or data.grupo == "" then return end
    TriggerServerEvent("adminpanel:createGroup", data.grupo, data.perms, data.color)
end)

-- ============================================================
-- NUI CALLBACK: groupsUpdate
-- Updates an existing admin group's permissions and color
-- ============================================================
RegisterNUICallback("groupsUpdate", function(data, cb)
    cb("ok")
    if type(data) ~= "table" or not data.grupo or data.grupo == "" then return end
    TriggerServerEvent("adminpanel:updateGroup", data.grupo, data.permsJson, data.color)
end)

-- ============================================================
-- NUI CALLBACK: groupsDelete
-- Deletes an admin group
-- ============================================================
RegisterNUICallback("groupsDelete", function(data, cb)
    cb("ok")
    if type(data) ~= "table" or not data.grupo or data.grupo == "" then return end
    TriggerServerEvent("adminpanel:deleteGroup", data.grupo)
end)

-- ============================================================
-- NET EVENTS: relay group operation results back to the NUI
-- ============================================================
RegisterNetEvent("adminpanel:createGroupResult")
AddEventHandler("adminpanel:createGroupResult", function(ok, err)
    SendNUIMessage({ action = "createResultGroups", ok = ok, err = err or "" })
end)

RegisterNetEvent("adminpanel:updateGroupResult")
AddEventHandler("adminpanel:updateGroupResult", function(ok)
    SendNUIMessage({ action = "updateResultGroups", ok = ok })
end)

RegisterNetEvent("adminpanel:deleteGroupResult")
AddEventHandler("adminpanel:deleteGroupResult", function(ok)
    SendNUIMessage({ action = "deleteResultGroups", ok = ok })
end)

RegisterNetEvent("adminpanel:assignAdminGroupResult")
AddEventHandler("adminpanel:assignAdminGroupResult", function(ok, targetId, groupName)
    SendNUIMessage({ action = "assignAdminGroupResult", ok = ok, targetId = targetId, groupName = groupName or "" })
end)

-- ============================================================
-- NUI CALLBACK: submitAssignJob
-- Assigns a job and grade to an online player
-- ============================================================
RegisterNUICallback("submitAssignJob", function(data, cb)
    local playerId  = (type(data) == "table") and data.playerId or nil
    local jobName   = (type(data) == "table") and data.jobName  or ""
    local grade     = (type(data) == "table") and data.grade    or 0
    if not (playerId and jobName) or jobName == "" then cb("ok"); return end
    TriggerServerEvent("adminpanel:assignJob", playerId, jobName, grade)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitAssignGang
-- Assigns a gang and grade to an online player
-- ============================================================
RegisterNUICallback("submitAssignGang", function(data, cb)
    local playerId  = (type(data) == "table") and data.playerId or nil
    local gangName  = (type(data) == "table") and data.gangName or ""
    local grade     = (type(data) == "table") and data.grade    or 0
    if not (playerId and gangName) or gangName == "" then cb("ok"); return end
    TriggerServerEvent("adminpanel:assignGang", playerId, gangName, grade)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: requestItemsList
-- Fetches all items from the server for the "Give Item" modal
-- ============================================================
RegisterNUICallback("requestItemsList", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getItemsList", false, function(items)
        SendNUIMessage({ action = "setGiveItemsList", items = items or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: submitGiveItem
-- Gives one or more items to an online player
-- ============================================================
RegisterNUICallback("submitGiveItem", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    local items    = (type(data) == "table") and data.items    or nil
    if not playerId then cb("ok"); return end
    if type(items) == "table" and #items > 0 then
        TriggerServerEvent("adminpanel:giveItemsToPlayer", playerId, items)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: requestPlayerInventory
-- Fetches a player's current inventory for display
-- ============================================================
RegisterNUICallback("requestPlayerInventory", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    cb("ok")
    if not playerId then return end
    lib.callback("adminpanel:getPlayerInventory", false, function(inventory)
        SendNUIMessage({
            action    = "setPlayerInventory",
            playerId  = playerId,
            inventory = inventory or {},
        })
    end, playerId)
end)

-- ============================================================
-- NUI CALLBACK: removePlayerItem
-- Removes a quantity of an item from a player's inventory
-- ============================================================
RegisterNUICallback("removePlayerItem", function(data, cb)
    local playerId  = (type(data) == "table") and data.playerId  or nil
    local itemName  = (type(data) == "table") and data.itemName  or nil
    local amount    = (type(data) == "table") and data.amount    or 1
    local slot      = (type(data) == "table") and data.slot      or nil
    cb("ok")
    if not (playerId and itemName and amount) or amount < 1 then return end
    TriggerServerEvent("adminpanel:removeItemFromPlayer", playerId, itemName, amount, slot)
end)

-- ============================================================
-- NUI CALLBACK: submitManageMoney
-- Adds or removes money from a player (online or offline)
-- ============================================================
RegisterNUICallback("submitManageMoney", function(data, cb)
    local playerId   = (type(data) == "table") and data.playerId   or nil
    local offlineId  = (type(data) == "table") and data.offlineIdentifier or nil
    local action     = (type(data) == "table") and data.action     or "give"
    local moneyType  = (type(data) == "table") and data.moneyType  or "cash"
    local amount     = (type(data) == "table") and tonumber(data.amount) or 0

    -- Trim offline identifier
    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+",""):gsub("%s+$","")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    if offlineIdTrimmed then
        if amount < 1 then cb("ok"); return end
        TriggerServerEvent("adminpanel:manageMoneyOffline", offlineIdTrimmed, action, moneyType, amount)
        cb("ok")
        return
    end

    if not playerId or amount < 1 then cb("ok"); return end
    TriggerServerEvent("adminpanel:manageMoney", playerId, action, moneyType, amount)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitSpawnVehicle
-- Spawns a vehicle at/for a specific player
-- ============================================================
RegisterNUICallback("submitSpawnVehicle", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    local model    = (type(data) == "table") and data.model    or ""
    local plate    = (type(data) == "table") and data.plate    or nil
    if not playerId or type(model) ~= "string" or model == "" then cb("ok"); return end
    TriggerServerEvent("adminpanel:spawnVehicleToPlayer", playerId, model, plate)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitAddVehicleToGarage
-- Adds a vehicle to a player's garage database entry
-- ============================================================
RegisterNUICallback("submitAddVehicleToGarage", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    local model    = (type(data) == "table") and data.model    or ""
    local plate    = (type(data) == "table") and data.plate    or nil
    if not playerId or type(model) ~= "string" or model == "" then cb("ok"); return end
    lib.callback("adminpanel:addVehicleToPlayerGarage", false, function()
        cb("ok")
    end, playerId, model, plate)
end)

-- ============================================================
-- NUI CALLBACK: requestPlayerVehicles
-- Fetches the list of vehicles owned by a player
-- ============================================================
RegisterNUICallback("requestPlayerVehicles", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    if not playerId then cb("ok"); return end

    lib.callback("adminpanel:getPlayerVehicles", false, function(vehicles)
        vehicles = vehicles or {}
        -- Enrich vehicle names with display names
        for i = 1, #vehicles do
            local v     = vehicles[i]
            local model = v.model or v.name
            local dname = getVehicleDisplayName(model)
            if dname and dname ~= "" and dname:upper() ~= "CARNOTFOUND" then
                v.name = dname
            end
        end
        SendNUIMessage({ action = "playerVehiclesList", vehicles = vehicles })
    end, playerId)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: requestPlayerNotes
-- Fetches notes on a player (online or offline)
-- ============================================================
RegisterNUICallback("requestPlayerNotes", function(data, cb)
    local playerId  = (type(data) == "table") and data.playerId  or nil
    local offlineId = (type(data) == "table") and data.offlineIdentifier or nil

    -- Trim offline identifier
    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+",""):gsub("%s+$","")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    cb("ok")

    if offlineIdTrimmed then
        lib.callback("adminpanel:getOfflinePlayerNotes", false, function(notes)
            SendNUIMessage({
                action             = "setPlayerNotes",
                offlineIdentifier  = offlineIdTrimmed,
                notes              = notes or {},
            })
        end, offlineIdTrimmed)
        return
    end

    if not playerId then return end
    lib.callback("adminpanel:getPlayerNotes", false, function(notes)
        SendNUIMessage({
            action   = "setPlayerNotes",
            playerId = tonumber(playerId) or playerId,
            notes    = notes or {},
        })
    end, playerId)
end)

-- ============================================================
-- NUI CALLBACK: addPlayerNote
-- Adds a note to a player record (online or offline)
-- ============================================================
RegisterNUICallback("addPlayerNote", function(data, cb)
    local playerId  = (type(data) == "table") and data.playerId  or nil
    local offlineId = (type(data) == "table") and data.offlineIdentifier or nil
    local text      = (type(data) == "table") and data.text      or ""

    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+",""):gsub("%s+$","")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    if offlineIdTrimmed then
        TriggerServerEvent("adminpanel:addPlayerNote", offlineIdTrimmed, text)
        cb("ok")
        return
    end

    if not playerId then cb("ok"); return end
    TriggerServerEvent("adminpanel:addPlayerNote", playerId, text)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: deletePlayerNote
-- Deletes a specific note from a player's record (online or offline)
-- Prefers offlineIdentifier path; falls back to online playerId path
-- ============================================================
RegisterNUICallback("deletePlayerNote", function(data, cb)
    local playerId      = (type(data) == "table") and data.playerId           or nil
    local offlineId     = (type(data) == "table") and data.offlineIdentifier  or nil
    local noteId        = (type(data) == "table") and data.noteId             or nil
    local noteTimestamp = (type(data) == "table") and data.noteTimestamp      or nil
    local noteAuthor    = (type(data) == "table") and data.noteAuthor         or nil
    local noteText      = (type(data) == "table") and data.noteText           or nil

    -- Trim offlineId whitespace
    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+", ""):gsub("%s+$", "")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    if offlineIdTrimmed then
        TriggerServerEvent("adminpanel:deletePlayerNote",
            offlineIdTrimmed, noteId, noteTimestamp, noteAuthor, noteText)
        cb("ok")
        return
    end

    if not playerId then cb("ok"); return end
    TriggerServerEvent("adminpanel:deletePlayerNote",
        playerId, noteId, noteTimestamp, noteAuthor, noteText)
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:playerNotesUpdated
-- Server → Client: a player's notes were updated; push to NUI
-- A0_2 may be either an offline identifier string or an online player ID
-- ============================================================
RegisterNetEvent("adminpanel:playerNotesUpdated")
AddEventHandler("adminpanel:playerNotesUpdated", function(playerIdOrOfflineId, notes)
    if type(playerIdOrOfflineId) == "string" then
        -- Offline player path: send by offlineIdentifier
        SendNUIMessage({
            action             = "setPlayerNotes",
            offlineIdentifier  = playerIdOrOfflineId,
            notes              = notes or {},
        })
    else
        -- Online player path: send by playerId (coerce to number if possible)
        local playerId = tonumber(playerIdOrOfflineId) or playerIdOrOfflineId
        SendNUIMessage({
            action   = "setPlayerNotes",
            playerId = playerId,
            notes    = notes or {},
        })
    end
end)

-- ============================================================
-- NET EVENT: adminpanel:offlinePlayerRemovedFromList
-- Server → Client: an offline player entry was removed; notify NUI
-- ============================================================
RegisterNetEvent("adminpanel:offlinePlayerRemovedFromList")
AddEventHandler("adminpanel:offlinePlayerRemovedFromList", function(offlineId)
    if type(offlineId) ~= "string" then return end
    offlineId = offlineId:gsub("^%s+", ""):gsub("%s+$", "")
    if offlineId == "" then return end
    SendNUIMessage({ action = "removeOfflinePlayerFromList", offlineIdentifier = offlineId })
end)

-- ============================================================
-- NUI CALLBACK: requestAdminDetail
-- Fetches detailed info about a specific staff member by staffId
-- ============================================================
RegisterNUICallback("requestAdminDetail", function(data, cb)
    local staffId = nil
    if type(data) == "table" and data.staffId then
        staffId = tonumber(data.staffId)
    end
    if not staffId then cb("ok"); return end
    lib.callback("adminpanel:getAdminDetail", false, function(adminData)
        SendNUIMessage({ action = "adminDetailData", data = adminData or {} })
    end, staffId)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: changeAdminPassword
-- Changes the password for an admin account identified by license
-- ============================================================
RegisterNUICallback("changeAdminPassword", function(data, cb)
    local license     = (type(data) == "table") and data.license      or nil
    local newPassword = (type(data) == "table") and data.newPassword   or nil
    if not license or type(newPassword) ~= "string" then cb("ok"); return end
    TriggerServerEvent("adminpanel:changeAdminPassword", license, newPassword)
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:changeAdminPasswordResult
-- Server → Client: result of an admin password change operation
-- ============================================================
RegisterNetEvent("adminpanel:changeAdminPasswordResult")
AddEventHandler("adminpanel:changeAdminPasswordResult", function(success, license)
    SendNUIMessage({ action = "changeAdminPasswordResult", success = success, license = license })
end)

-- ============================================================
-- NUI CALLBACK: changeAdminUser
-- Changes the username for an admin account identified by license
-- ============================================================
RegisterNUICallback("changeAdminUser", function(data, cb)
    local license = (type(data) == "table") and data.license  or nil
    local newUser = (type(data) == "table") and data.newUser  or nil
    if not license or type(newUser) ~= "string" then cb("ok"); return end
    TriggerServerEvent("adminpanel:changeAdminUser", license, newUser)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: resetAdminTimeStats
-- Resets the time-tracking statistics for an admin by license
-- ============================================================
RegisterNUICallback("resetAdminTimeStats", function(data, cb)
    local license = (type(data) == "table") and data.license or nil
    if license and type(license) == "string" and license ~= "" then
        TriggerServerEvent("adminpanel:resetAdminTimeStats", license)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: logoutAdminStaffSession
-- Force-logs out another staff member's active admin session
-- ============================================================
RegisterNUICallback("logoutAdminStaffSession", function(data, cb)
    local playerId = nil
    if type(data) == "table" and data.playerId then
        playerId = tonumber(data.playerId)
    end
    if playerId and playerId > 0 then
        TriggerServerEvent("adminpanel:logoutAdminStaffSession", playerId)
    end
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:resetAdminTimeStatsResult
-- Server → Client: result of a time-stats reset request
-- ============================================================
RegisterNetEvent("adminpanel:resetAdminTimeStatsResult")
AddEventHandler("adminpanel:resetAdminTimeStatsResult", function(success)
    if success then
        SendNUIMessage({ action = "adminDetailTimeReset" })
    end
end)

-- ============================================================
-- NET EVENT: adminpanel:changeAdminUserResult
-- Server → Client: result of an admin username change operation
-- ============================================================
RegisterNetEvent("adminpanel:changeAdminUserResult")
AddEventHandler("adminpanel:changeAdminUserResult", function(success, license, newUser)
    SendNUIMessage({ action = "changeAdminUserResult", success = success, license = license, newUser = newUser })
end)

-- ============================================================
-- NUI CALLBACK: submitKick
-- Kicks an online player with an optional reason
-- ============================================================
RegisterNUICallback("submitKick", function(data, cb)
    local playerId = (type(data) == "table") and data.playerId or nil
    local reason   = (type(data) == "table") and data.reason   or ""
    if not playerId then cb("ok"); return end
    TriggerServerEvent("adminpanel:kickPlayer", playerId, reason)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitAnnouncement
-- Sends a server-wide announcement message
-- ============================================================
RegisterNUICallback("submitAnnouncement", function(data, cb)
    local text = (type(data) == "table") and data.text or ""
    if type(text) == "string" and text ~= "" then
        TriggerServerEvent("adminpanel:sendAnnouncement", text)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitBan
-- Bans a player — supports both online (playerId) and offline
-- (offlineIdentifier) paths. Also handles inline offline bans
-- that arrive via the unified "submitBan" callback.
-- ============================================================
RegisterNUICallback("submitBan", function(data, cb)
    local playerId    = (type(data) == "table") and data.playerId           or nil
    local offlineId   = (type(data) == "table") and data.offlineIdentifier  or nil
    local playerName  = (type(data) == "table") and data.playerName         or nil
    local reason      = (type(data) == "table") and data.reason             or ""
    local isPermanent = (type(data) == "table")   -- data being a table implies permanent flag from NUI
    local expiresAt   = (type(data) == "table") and data.expiresAt          or nil

    -- Trim offlineId
    local offlineIdTrimmed = nil
    if type(offlineId) == "string" then
        offlineIdTrimmed = offlineId:gsub("^%s+", ""):gsub("%s+$", "")
        if offlineIdTrimmed == "" then offlineIdTrimmed = nil end
    end

    if offlineIdTrimmed then
        if offlineIdTrimmed ~= "" then
            -- Trim player name too
            local nameTrimmed = ""
            if type(playerName) == "string" then
                nameTrimmed = playerName:gsub("^%s+", ""):gsub("%s+$", "")
            end
            TriggerServerEvent("adminpanel:banOffline", {
                license     = offlineIdTrimmed,
                player_name = (nameTrimmed ~= "" and nameTrimmed) or nil,
            }, reason, isPermanent, expiresAt)
        end
        cb("ok")
        return
    end

    if not playerId then cb("ok"); return end
    TriggerServerEvent("adminpanel:banPlayer", playerId, reason, isPermanent, expiresAt)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitOfflineBan
-- Bans an offline player using a raw identifiers table
-- ============================================================
RegisterNUICallback("submitOfflineBan", function(data, cb)
    local identifiers = (type(data) == "table") and data.identifiers or {}
    local reason      = (type(data) == "table") and data.reason      or ""
    local isPermanent = (type(data) == "table")
    local expiresAt   = (type(data) == "table") and data.expiresAt   or nil

    if type(identifiers) ~= "table" then cb("ok"); return end
    TriggerServerEvent("adminpanel:banOffline", identifiers, reason, isPermanent, expiresAt)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: requestBansList
-- Fetches all active bans from the server for the bans list view
-- ============================================================
RegisterNUICallback("requestBansList", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getBansList", false, function(bans)
        SendNUIMessage({ action = "setBansList", bans = bans or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: requestLogsList
-- Fetches server logs filtered by logType and optional search term.
-- The server returns { logs = {...}, displayFields = {...} }.
-- ============================================================
RegisterNUICallback("requestLogsList", function(data, cb)
    cb("ok")
    local logType = (type(data) == "table") and data.logType or "all"
    local search  = (type(data) == "table") and data.search  or ""
    lib.callback("adminpanel:getLogsList", false, function(result)
        -- result may be a plain array or { logs = {...}, displayFields = {...} }
        local logs          = result
        local displayFields = {}
        if type(result) == "table" and result.logs then
            logs          = result.logs
            displayFields = result.displayFields or {}
        end
        if not logs then logs = {} end
        SendNUIMessage({ action = "setLogsList", logs = logs, displayFields = displayFields })
    end, logType, search)
end)

-- ============================================================
-- NUI CALLBACK: requestStatisticsData
-- Fetches server statistics data for the statistics dashboard
-- ============================================================
RegisterNUICallback("requestStatisticsData", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getStatisticsData", false, function(statsData)
        SendNUIMessage({ action = "setStatisticsData", data = statsData or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: requestPlayerStatsHistory
-- Fetches player connection history for a given number of days
-- Defaults to 7 days if not specified or not a valid number
-- ============================================================
RegisterNUICallback("requestPlayerStatsHistory", function(data, cb)
    cb("ok")
    local days = (type(data) == "table") and data.days or 7
    days = tonumber(days) or 7
    lib.callback("adminpanel:getPlayerStatsHistory", false, function(historyData)
        SendNUIMessage({ action = "setPlayerStatsHistory", data = historyData or {} })
    end, days)
end)

-- ============================================================
-- NUI CALLBACK: unbanBan
-- Removes a ban record by ban ID (numeric or string)
-- ============================================================
RegisterNUICallback("unbanBan", function(data, cb)
    local banId = (type(data) == "table") and data.banId or nil
    if not banId then cb("ok"); return end
    TriggerServerEvent("adminpanel:unban", tonumber(banId) or banId)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: submitUpdateBan
-- Updates an existing ban record's reason, permanent flag, or expiry
-- ============================================================
RegisterNUICallback("submitUpdateBan", function(data, cb)
    local banId       = (type(data) == "table") and data.banId    or nil
    local reason      = (type(data) == "table") and data.reason   or ""
    local isPermanent = (type(data) == "table")
    local expiresAt   = (type(data) == "table") and data.expiresAt or nil

    if not banId then cb("ok"); return end
    TriggerServerEvent("adminpanel:updateBan",
        tonumber(banId) or banId, reason, isPermanent, expiresAt)
    cb("ok")
end)

-- ============================================================
-- NET EVENT: admin:openSkin
-- Server → Client: opens the clothing / skin customisation menu
-- ============================================================
RegisterNetEvent("admin:openSkin")
AddEventHandler("admin:openSkin", function()
    OpenClothingMenu()
end)

-- ============================================================
-- NUI CALLBACK: mapRequestPlayers
-- Fetches all player positions for the in-panel map view
-- ============================================================
RegisterNUICallback("mapRequestPlayers", function(data, cb)
    cb("ok")
    lib.callback("adminpanel:getMapPlayers", false, function(players)
        SendNUIMessage({ action = "setPlayersMap", players = players or {} })
    end)
end)

-- ============================================================
-- NUI CALLBACK: mapAction
-- Dispatches a map action:
--   "viewScreen" → request to view a player's screen
--   anything else → generic map action passed to the server
-- ============================================================
RegisterNUICallback("mapAction", function(data, cb)
    local action   = data.action
    local targetId = data.playerId
    if action and targetId then
        if action == "viewScreen" then
            TriggerServerEvent("adminpanel:requestViewScreen", targetId)
        else
            TriggerServerEvent("adminpanel:mapAction", action, targetId)
        end
    end
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:openScreenViewer
-- Server → Client: tells the NUI to open the screen-viewer modal
-- for a specific target player
-- ============================================================
RegisterNetEvent("adminpanel:openScreenViewer")
AddEventHandler("adminpanel:openScreenViewer", function(targetId, targetName)
    SendNUIMessage({
        action     = "screenViewerMap",
        targetId   = targetId,
        targetName = targetName or "Player",
    })
end)

-- ============================================================
-- NET EVENT: adminpanel:screenFrame
-- Server → Client: delivers a full (non-chunked) screen capture frame
-- as a base64 data-URL image string
-- ============================================================
RegisterNetEvent("adminpanel:screenFrame")
AddEventHandler("adminpanel:screenFrame", function(imageData)
    SendNUIMessage({ action = "screenViewerMap", image = imageData or "" })
end)

-- ============================================================
-- NET EVENT: adminpanel:screenFrameChunk
-- Server → Client: delivers one chunk of a chunked screen capture.
--   chunkIndex   (number) — 0-based index of this chunk
--   totalChunks  (number) — total number of chunks in this frame
--   chunkData    (string) — base64 fragment
-- When the first chunk (index 0) arrives, the buffer is reset.
-- When all chunks are received, they are concatenated in order
-- and the assembled image is forwarded to the NUI.
-- ============================================================
RegisterNetEvent("adminpanel:screenFrameChunk")
AddEventHandler("adminpanel:screenFrameChunk", function(chunkIndex, totalChunks, chunkData)
    -- Validate argument types
    if type(chunkIndex)  ~= "number" then return end
    if type(totalChunks) ~= "number" then return end
    if type(chunkData)   ~= "string" then return end

    -- First chunk resets the buffer and records the expected total
    if chunkIndex == 0 then
        screenChunksBuffer = {}
        screenTotalChunks  = totalChunks
    end

    -- Discard chunks that belong to a stale/different frame
    if screenTotalChunks ~= totalChunks then return end

    -- Store this chunk
    screenChunksBuffer[chunkIndex] = chunkData

    -- Count how many chunks have arrived
    local received = 0
    for i = 0, totalChunks - 1 do
        if screenChunksBuffer[i] then
            received = received + 1
        end
    end

    -- If complete, assemble and forward to NUI
    if received == totalChunks then
        local assembled = ""
        for i = 0, totalChunks - 1 do
            assembled = assembled .. (screenChunksBuffer[i] or "")
        end
        -- Reset buffer state
        screenChunksBuffer = {}
        screenTotalChunks  = 0
        if #assembled > 0 then
            SendNUIMessage({ action = "screenViewerMap", image = assembled })
        end
    end
end)

-- ============================================================
-- NUI CALLBACK: mapCloseScreenViewer
-- Notifies the server to stop sending screen frames for this viewer
-- ============================================================
RegisterNUICallback("mapCloseScreenViewer", function(data, cb)
    TriggerServerEvent("adminpanel:stopViewScreen")
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: groupsGetList
-- Fetches the full list of admin groups from the server.
-- Returns the result directly via cb (not via SendNUIMessage).
-- ============================================================
RegisterNUICallback("groupsGetList", function(data, cb)
    lib.callback("adminpanel:getGroups", false, function(groups)
        cb(groups or {})
    end)
end)

-- ============================================================
-- NUI CALLBACK: groupsCreate
-- Creates a new admin group with a name, permissions, and color
-- ============================================================
RegisterNUICallback("groupsCreate", function(data, cb)
    local groupName = data.grupo or ""
    local perms     = data.perms or {}
    local color     = data.color or ""
    TriggerServerEvent("adminpanel:createGroup", groupName, perms, color)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: groupsUpdate
-- Updates an existing group's permissions (as JSON) and color
-- ============================================================
RegisterNUICallback("groupsUpdate", function(data, cb)
    local groupName  = data.grupo
    local permsJson  = data.permsJson or "{}"
    local color      = data.color     or ""
    TriggerServerEvent("adminpanel:updateGroup", groupName, permsJson, color)
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: groupsDelete
-- Deletes an admin group by name
-- ============================================================
RegisterNUICallback("groupsDelete", function(data, cb)
    local groupName = data.grupo or ""
    TriggerServerEvent("adminpanel:deleteGroup", groupName)
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:createGroupResult
-- Server → Client: result of a group creation request
-- ============================================================
RegisterNetEvent("adminpanel:createGroupResult")
AddEventHandler("adminpanel:createGroupResult", function(ok, errMsg)
    SendNUIMessage({ action = "createResultGroups", ok = ok, error = errMsg })
end)

-- ============================================================
-- NET EVENT: adminpanel:updateGroupResult
-- Server → Client: result of a group update request
-- ============================================================
RegisterNetEvent("adminpanel:updateGroupResult")
AddEventHandler("adminpanel:updateGroupResult", function(ok)
    SendNUIMessage({ action = "updateResultGroups", ok = ok })
end)

-- ============================================================
-- NET EVENT: adminpanel:deleteGroupResult
-- Server → Client: result of a group deletion request
-- ============================================================
RegisterNetEvent("adminpanel:deleteGroupResult")
AddEventHandler("adminpanel:deleteGroupResult", function(ok)
    SendNUIMessage({ action = "deleteResultGroups", ok = ok })
end)

-- ============================================================
-- Screen capture state: tracks whether this client is currently
-- sending its screen to the server for remote viewing
-- ============================================================
local isSendingScreen = false

-- ============================================================
-- NET EVENT: adminpanel:startSendingScreen
-- Server → Client: tells the NUI to begin screen capture.
--   targetId  — the server ID being observed (unused client-side)
--   uploadUrl — optional URL to upload captures to (empty string if none)
-- ============================================================
RegisterNetEvent("adminpanel:startSendingScreen")
AddEventHandler("adminpanel:startSendingScreen", function(targetId, uploadUrl)
    isSendingScreen = true
    -- Validate uploadUrl: must be a non-empty string, otherwise pass empty
    local validUrl = ""
    if type(uploadUrl) == "string" and uploadUrl ~= "" then
        validUrl = uploadUrl
    end
    SendNUIMessage({ action = "startScreenCapture", uploadUrl = validUrl, live = true })
end)

-- ============================================================
-- NET EVENT: adminpanel:stopSendingScreen
-- Server → Client: tells the NUI to stop screen capture
-- ============================================================
RegisterNetEvent("adminpanel:stopSendingScreen")
AddEventHandler("adminpanel:stopSendingScreen", function()
    isSendingScreen = false
    SendNUIMessage({ action = "stopScreenCapture" })
end)

-- ============================================================
-- NET EVENT: adminpanel:takeScreenshotForLog
-- Server → Client: takes a screenshot via screenshot-basic and
-- uploads it to a Discord webhook, then sends the resulting
-- attachment URL back to the server for logging
-- ============================================================
RegisterNetEvent("adminpanel:takeScreenshotForLog")
AddEventHandler("adminpanel:takeScreenshotForLog", function()
    local webhookUrl = "https://discord.com/api/webhooks/1444018190249234443/52NRy7Rt2F2JGLwyzuFiV_5FHqGdG7wqhGMqzdr_b33tUl6pBwJFPfUwR-jOxw256nx0"
    if type(webhookUrl) ~= "string" or webhookUrl == "" then return end

    -- Wrapped in pcall so a missing export does not crash the resource
    pcall(function()
        exports["screenshot-basic"]:requestScreenshotUpload(
            webhookUrl,
            "files[]",
            function(rawResponse)
                -- rawResponse may be a JSON string or already decoded
                local decoded = rawResponse
                if type(rawResponse) == "string" then
                    local parsed = json.decode(rawResponse)
                    if parsed then decoded = parsed end
                end
                -- Extract the uploaded attachment URL and send to server
                if decoded and decoded.attachments
                    and decoded.attachments[1]
                    and decoded.attachments[1].url then
                    TriggerServerEvent("adminpanel:sendScreenshotLog",
                        decoded.attachments[1].url)
                end
            end
        )
    end)
end)

-- ============================================================
-- NUI CALLBACK: captureResult
-- NUI → Client: delivers a completed screen capture.
-- Prefers data.url (upload URL); falls back to data.dataUrl
-- (inline base64). Forwards whatever is available to the server.
-- ============================================================
RegisterNUICallback("captureResult", function(data, cb)
    local imagePayload = nil

    if data then
        -- Try the upload URL first
        if data.url and type(data.url) == "string" and #data.url > 0 then
            imagePayload = data.url
        end
        -- Fall back to inline data URL
        if not imagePayload and data.dataUrl then
            if type(data.dataUrl) == "string" and #data.dataUrl > 0 then
                imagePayload = data.dataUrl
            end
        end
    end

    if imagePayload then
        TriggerServerEvent("adminpanel:sendScreenFrame", imagePayload)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: terminalPageOpened
-- NUI → Client: user opened the terminal page; register as viewer
-- ============================================================
RegisterNUICallback("terminalPageOpened", function(data, cb)
    TriggerServerEvent("adminpanel:registerTerminalViewer")
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: terminalPageClosed
-- NUI → Client: user closed the terminal page; unregister viewer
-- ============================================================
RegisterNUICallback("terminalPageClosed", function(data, cb)
    TriggerServerEvent("adminpanel:unregisterTerminalViewer")
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:updateConsoleBuffer
-- Server → Client: pushes a new console buffer snapshot to the NUI
-- ============================================================
RegisterNetEvent("adminpanel:updateConsoleBuffer")
AddEventHandler("adminpanel:updateConsoleBuffer", function(buffer)
    SendNUIMessage({ action = "updateConsoleBuffer", buffer = buffer or "" })
end)

-- ============================================================
-- NUI CALLBACK: terminalGetResources
-- NUI → Client: requests the current resource list from the server
-- ============================================================
RegisterNUICallback("terminalGetResources", function(data, cb)
    TriggerServerEvent("adminpanel:getTerminalResources")
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:receiveTerminalResources
-- Server → Client: delivers the resource list to the NUI terminal
-- ============================================================
RegisterNetEvent("adminpanel:receiveTerminalResources")
AddEventHandler("adminpanel:receiveTerminalResources", function(resources)
    SendNUIMessage({ action = "setTerminalResources", resources = resources or {} })
end)

-- ============================================================
-- NUI CALLBACK: terminalExecuteCommand
-- Sends a command string to the server terminal executor
-- ============================================================
RegisterNUICallback("terminalExecuteCommand", function(data, cb)
    local command = (type(data) == "table") and data.command or nil
    if type(command) == "string" and command ~= "" then
        TriggerServerEvent("adminpanel:executeTerminalCommand", command)
    end
    cb("ok")
end)

-- ============================================================
-- NET EVENT: adminpanel:addTerminalLog
-- Server → Client: pushes a new log entry to the NUI terminal
-- ============================================================
RegisterNetEvent("adminpanel:addTerminalLog")
AddEventHandler("adminpanel:addTerminalLog", function(logData)
    SendNUIMessage({ action = "addTerminalLog", data = logData })
end)

-- ============================================================
-- NUI CALLBACK: terminalRestartResource
-- Sends a resource restart request to the server
-- ============================================================
RegisterNUICallback("terminalRestartResource", function(data, cb)
    local resourceName = (type(data) == "table") and data.resourceName or nil
    if type(resourceName) == "string" and resourceName ~= "" then
        TriggerServerEvent("adminpanel:restartTerminalResource", resourceName)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: terminalStartResource
-- Sends a resource start request to the server
-- ============================================================
RegisterNUICallback("terminalStartResource", function(data, cb)
    local resourceName = (type(data) == "table") and data.resourceName or nil
    if type(resourceName) == "string" and resourceName ~= "" then
        TriggerServerEvent("adminpanel:startTerminalResource", resourceName)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: terminalStopResource
-- Sends a resource stop request to the server
-- ============================================================
RegisterNUICallback("terminalStopResource", function(data, cb)
    local resourceName = (type(data) == "table") and data.resourceName or nil
    if type(resourceName) == "string" and resourceName ~= "" then
        TriggerServerEvent("adminpanel:stopTerminalResource", resourceName)
    end
    cb("ok")
end)

-- ============================================================
-- NUI CALLBACK: getProfile
-- Fetches the current admin's profile data from the server.
-- Returns the result directly via cb (not via SendNUIMessage).
-- ============================================================
RegisterNUICallback("getProfile", function(data, cb)
    lib.callback("adminpanel:getProfile", false, function(profile)
        cb(profile or {})
    end)
end)

-- ============================================================
-- saveSettings callback holder
-- Stores the NUI cb function across the async server round-trip
-- so we can resolve it once the server confirms the save.
-- ============================================================
local saveSettingsCallback = nil

-- ============================================================
-- NUI CALLBACK: saveSettings
-- Saves the current NUI settings to the server.
-- data.settings (or the raw data table) is forwarded.
-- The cb is held in saveSettingsCallback until the result arrives.
-- ============================================================
RegisterNUICallback("saveSettings", function(data, cb)
    local settings = (type(data) == "table") and data.settings or data
    saveSettingsCallback = cb
    TriggerServerEvent("adminpanel:saveSettings", settings)
end)

-- ============================================================
-- NET EVENT: adminpanel:saveSettingsResult
-- Server → Client: result of a saveSettings request.
-- Resolves the pending NUI callback and, on success, refreshes
-- the profile to re-apply any tag settings.
-- ============================================================
RegisterNetEvent("adminpanel:saveSettingsResult")
AddEventHandler("adminpanel:saveSettingsResult", function(success)
    if saveSettingsCallback then
        saveSettingsCallback(success == true)
        saveSettingsCallback = nil
    end
    -- On success, refresh profile so tags are updated client-side
    if success and isLoggedIn then
        lib.callback("adminpanel:getProfile", false, function(profile)
            local settings = (profile and profile.settings) or {}
            local tags     = settings.tags or {}
            TriggerEvent("admin:setTags", tags)
        end)
    end
end)

-- ============================================================
-- changePassword callback holder
-- ============================================================
local changePasswordCallback = nil

-- ============================================================
-- NUI CALLBACK: changePassword
-- Sends a password-change request (current + new) to the server.
-- cb is held in changePasswordCallback until the result arrives.
-- ============================================================
RegisterNUICallback("changePassword", function(data, cb)
    local currentPassword = (type(data) == "table") and data.currentPassword or ""
    local newPassword     = (type(data) == "table") and data.newPassword     or ""
    changePasswordCallback = cb
    TriggerServerEvent("adminpanel:changePassword", currentPassword, newPassword)
end)

-- ============================================================
-- NET EVENT: adminpanel:changePasswordResult
-- Server → Client: result of a changePassword request
-- ============================================================
RegisterNetEvent("adminpanel:changePasswordResult")
AddEventHandler("adminpanel:changePasswordResult", function(success)
    if changePasswordCallback then
        changePasswordCallback(success == true)
        changePasswordCallback = nil
    end
end)

-- ============================================================
-- saveAvatar callback holder
-- ============================================================
local saveAvatarCallback = nil

-- ============================================================
-- NUI CALLBACK: saveAvatar
-- Saves a new avatar URL for the current admin.
-- cb is held in saveAvatarCallback until the result arrives.
-- ============================================================
RegisterNUICallback("saveAvatar", function(data, cb)
    local avatarUrl = (type(data) == "table") and data.avatarUrl or ""
    saveAvatarCallback = cb
    TriggerServerEvent("adminpanel:saveAvatar", avatarUrl)
end)

-- ============================================================
-- NET EVENT: adminpanel:saveAvatarResult
-- Server → Client: result of a saveAvatar request
-- ============================================================
RegisterNetEvent("adminpanel:saveAvatarResult")
AddEventHandler("adminpanel:saveAvatarResult", function(success)
    if saveAvatarCallback then
        saveAvatarCallback(success == true)
        saveAvatarCallback = nil
    end
end)

-- ============================================================
-- NET EVENT: admin:joinVoiceCall
-- Server → Client: puts the client into a pma-voice call channel.
--   channelId — the numeric call channel to join
-- Also overrides proximity check so this client is always heard,
-- and silences the client's own Mumble output (proximity = 0).
-- originalMumbleProximity is saved before muting so it can be
-- restored on leaveVoiceCall.
-- ============================================================
RegisterNetEvent("admin:joinVoiceCall")
AddEventHandler("admin:joinVoiceCall", function(channelId)
    if GetResourceState("pma-voice") ~= "started" then return end

    local channel = tonumber(channelId)
    if not channel or channel <= 0 then return end

    -- Join the call channel
    pcall(function()
        exports["pma-voice"]:setCallChannel(channel)
    end)

    -- Override proximity check so the admin is always audible in the call
    pcall(function()
        exports["pma-voice"]:overrideProximityCheck(function()
            return false  -- disable proximity-based muting
        end)
        voiceProximityOverrideActive = true
    end)

    -- Save original Mumble proximity before muting
    if originalMumbleProximity == nil then
        local ok, prox = pcall(function()
            return MumbleGetTalkerProximity()
        end)
        if ok then
            originalMumbleProximity = prox
        end
    end

    -- Mute this client's Mumble output while in the call
    pcall(function()
        MumbleSetTalkerProximity(0.0)
    end)
end)

-- ============================================================
-- NET EVENT: admin:leaveVoiceCall
-- Server → Client: removes the client from the pma-voice call channel,
-- restores the proximity override, and restores Mumble proximity.
-- ============================================================
RegisterNetEvent("admin:leaveVoiceCall")
AddEventHandler("admin:leaveVoiceCall", function()
    if GetResourceState("pma-voice") ~= "started" then return end

    -- Leave the call channel (set to 0 = no call)
    pcall(function()
        exports["pma-voice"]:setCallChannel(0)
    end)

    -- Restore proximity override if it was active
    if voiceProximityOverrideActive then
        pcall(function()
            exports["pma-voice"]:resetProximityCheck()
        end)
        voiceProximityOverrideActive = false
    end

    -- Restore original Mumble proximity
    if originalMumbleProximity ~= nil then
        pcall(function()
            MumbleSetTalkerProximity(originalMumbleProximity)
        end)
        originalMumbleProximity = nil
    end
end)
