--[[
    DEOBFUSCATED LUA CODE
    Original obfuscated variables: 16 (L0_1 through L15_1, plus inner scopes)
    Total lines processed: 100% - every line manually processed
    Deobfuscation date: 2026-04-10
    Description: FiveM framework bridge/detection script for "Dev Admin"
                 Handles ESX/QBCore detection and prints system info on startup.
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Upvalue declarations (formerly: L0_1 through L15_1 at file scope)
-- These are used as shared upvalues across the file's closures.
-- ─────────────────────────────────────────────────────────────────────────────
local garageList, housingList, clothingList, inventoryList, ambulanceList, gangList
local detectFramework, debugPrint

-- ─────────────────────────────────────────────────────────────────────────────
-- debugPrint(message)
-- Prints a [DEBUG] prefixed message to the console if Config.Debug is enabled.
-- ─────────────────────────────────────────────────────────────────────────────
function debugPrint(...)
    if Config.Debug then
        print("[DEBUG]", ...)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- detectFramework()
-- Detects the active FiveM framework by checking Config.Framework first,
-- then falling back to checking active resource states.
-- Returns: "esx", "qb", or "standalone"
-- ─────────────────────────────────────────────────────────────────────────────
function detectFramework()
    local frameworkConfig = string.lower(Config.Framework or "auto")

    -- If explicitly set to a known framework, return it directly
    if frameworkConfig == "esx" or frameworkConfig == "qb" or frameworkConfig == "standalone" then
        return frameworkConfig
    end

    -- Auto-detect: check if es_extended is running
    if GetResourceState("es_extended") == "started" then
        return "esx"
    end

    -- Auto-detect: check if qb-core is running
    if GetResourceState("qb-core") == "started" then
        return "qb"
    end

    -- Auto-detect: check if qbx_core is running
    if GetResourceState("qbx_core") == "started" then
        return "qb"
    end

    -- Fallback to standalone
    return "standalone"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Run framework detection and store result back into Config
-- ─────────────────────────────────────────────────────────────────────────────
Config.Framework = detectFramework()

-- ─────────────────────────────────────────────────────────────────────────────
-- Initialize framework shared object (ESX or QBCore)
-- ─────────────────────────────────────────────────────────────────────────────
if Config.Framework == "esx" then
    ESX = exports.es_extended:getSharedObject()
elseif Config.Framework == "qb" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Server-side only block (IsDuplicityVersion returns true on server)
-- ─────────────────────────────────────────────────────────────────────────────
if IsDuplicityVersion() then

    -- ── Supported garage resource names ──────────────────────────────────────
    garageList = {
        "vms_garagesv2",
        "jg-advancedgarages",
        "qs-advancedgarages",
        "okokGarage",
        "op-garages",
        "origen_garages",
        "qb-garages",
        "esx_garage",
    }

    -- ── Supported housing resource names ─────────────────────────────────────
    housingList = {
        "ps-housing",
        "vms_housing",
        "qs-housing",
        "bcs_housing",
        "qb-houses",
        "esx_property",
        "origen_housing",
        "brutal_housing",
        "rtx_housing",
    }

    -- ── Supported clothing resource names ────────────────────────────────────
    clothingList = {
        "tgiann-clothing",
        "illenium-appearance",
        "fivem-appearance",
        "qs-appearance",
        "qb-clothing",
        "esx_skin",
        "origen_clothing",
        "rcore_clothing",
    }

    -- ── Supported inventory resource names ───────────────────────────────────
    inventoryList = {
        "core_inventory",
        "qs-inventory",
        "ox_inventory",
        "ak47_inventory",
        "ak47_qb_inventory",
        "inventory",
        "tgiann-inventory",
        "origen_inventory",
        "jaksam_inventory",
        "codem-inventory",
        "qb-inventory",
        "esx_inventory",
    }

    -- ── Supported ambulance/medical resource names ────────────────────────────
    ambulanceList = {
        "sky_ambulancejob",
        "wasabi_ambulance_v2",
        "wasabi_ambulance",
        "ars_ambulancejob",
        "osp_ambulance",
        "p_ambulancejob",
        "qs-medical-creator",
        "esx_ambulancejob",
        "qb-ambulancejob",
        "qbx_ambulancejob",
    }

    -- ── Supported gang resource names ─────────────────────────────────────────
    gangList = {
        "jc_organizaciones",
        "op-crime",
        "av_gangs",
    }

    -- ─────────────────────────────────────────────────────────────────────────
    -- findActiveResource(resourceNameList)
    -- Iterates a list of resource names and returns the first one that is
    -- currently in the "started" state, or nil if none are active.
    -- ─────────────────────────────────────────────────────────────────────────
    local function findActiveResource(resourceNameList)
        for _, resourceName in ipairs(resourceNameList) do
            if GetResourceState(resourceName) == "started" then
                return resourceName
            end
        end
        return nil
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Startup thread: waits 1500ms then prints system information to console
    -- ─────────────────────────────────────────────────────────────────────────
    CreateThread(function()
        Wait(1500)

        -- Determine current resource name and version
        local currentResourceName = GetCurrentResourceName()
        local resourceVersion = GetResourceMetadata(currentResourceName, "Version", 0)
        if not resourceVersion then
            resourceVersion = GetResourceMetadata(currentResourceName, "version", 0)
            if not resourceVersion then
                resourceVersion = "1.0.0"
            end
        end

        -- Resolve framework display value
        local frameworkDisplay
        if Config and Config.Framework then
            frameworkDisplay = Config.Framework
        else
            frameworkDisplay = "unknown"
        end

        -- Resolve notification system display value
        local notifyDisplay
        if Config and Config.Notify and Config.Notify.Notification then
            notifyDisplay = Config.Notify.Notification
        else
            notifyDisplay = "ox_lib"
        end

        -- Resolve garage system display value
        local garageDisplay
        if Config and Config.GarageSystem then
            if Config.GarageSystem == "auto" then
                garageDisplay = findActiveResource(garageList)
                if not garageDisplay then
                    garageDisplay = "─"
                end
            else
                garageDisplay = Config.GarageSystem
            end
        else
            garageDisplay = "─"
        end

        -- Resolve housing system display value
        local housingDisplay
        if Config and Config.HousingSystem then
            if Config.HousingSystem == "auto" then
                housingDisplay = findActiveResource(housingList)
                if not housingDisplay then
                    housingDisplay = "─"
                end
            else
                housingDisplay = Config.HousingSystem
            end
        else
            housingDisplay = "─"
        end

        -- Resolve clothing system display value
        local clothingDisplay
        if Config and Config.ClothingSystem then
            if Config.ClothingSystem == "auto" then
                clothingDisplay = findActiveResource(clothingList)
                if not clothingDisplay then
                    clothingDisplay = "─"
                end
            else
                clothingDisplay = Config.ClothingSystem
            end
        else
            clothingDisplay = "─"
        end

        -- Resolve inventory system display value
        local inventoryDisplay
        if Config and Config.InventorySystem then
            if Config.InventorySystem == "auto" then
                inventoryDisplay = findActiveResource(inventoryList)
                if not inventoryDisplay then
                    inventoryDisplay = "─"
                end
            else
                inventoryDisplay = Config.InventorySystem
            end
        else
            inventoryDisplay = "─"
        end

        -- Resolve ambulance system display value
        local ambulanceDisplay
        if Config and Config.AmbulanceSystem then
            if Config.AmbulanceSystem == "auto" then
                ambulanceDisplay = findActiveResource(ambulanceList)
                if not ambulanceDisplay then
                    ambulanceDisplay = "─"
                end
            else
                ambulanceDisplay = Config.AmbulanceSystem
            end
        else
            ambulanceDisplay = "─"
        end

        -- Resolve gang system display value
        local gangDisplay
        if Config and Config.GangSystem then
            if Config.GangSystem == "auto" then
                gangDisplay = findActiveResource(gangList)
                if not gangDisplay then
                    gangDisplay = "─"
                end
            else
                gangDisplay = Config.GangSystem
            end
        else
            gangDisplay = "─"
        end

        -- ── Print startup banner to server console ────────────────────────────
        print("^2========================================^7")
        print("^2   Dev Admin^7 V" .. tostring(resourceVersion))
        print("^2========================================^7")
        print("^3 Framework:^7 " .. tostring(frameworkDisplay))
        print("^3 Notify:^7 "    .. tostring(notifyDisplay))
        print("^3 Ambulance:^7 " .. tostring(ambulanceDisplay))
        print("^3 Housing:^7 "   .. tostring(housingDisplay))
        print("^3 Clothing:^7 "  .. tostring(clothingDisplay))
        print("^3 Inventory:^7 " .. tostring(inventoryDisplay))
        print("^3 Garage:^7 "    .. tostring(garageDisplay))
        print("^3 Gang:^7 "      .. tostring(gangDisplay))
        print("^2========================================^7")
    end)

end -- end IsDuplicityVersion() server-only block