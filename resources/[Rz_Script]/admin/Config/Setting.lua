Config = {}

Config.Framework = 'auto'  -- 'esx', 'qb', 'auto' or 'standalone'

Config.Notify = {
    Notification = 'ox_lib' -- 'ox_lib'  // 'esx_framework' // 'qb-core'
}

--[[  
Configure your language using the following:
    'es' -> Spanish
    'en' -> English
    'fr' -> French
    'de' -> German
    'it' -> Italian
    'pt' -> Portuguese
]]
Config.Locale = 'fr' 

Config.ServerName = ''

Config.AdminCommand = 'adminpanel' -- Command to open the admin panel

Config.AmbulanceSystem = 'auto'  -- 'auto', 'esx_ambulancejob', 'qb-ambulancejob', 'wasabi_ambulance', 'wasabi_ambulance_v2' , 'osp_ambulance' , 'ars_ambulancejob' , 'p_ambulancejob' , 'qs-medical-creator', 'sky_ambulancejob' or 'standalone'
Config.HousingSystem = 'auto'  -- 'auto', 'vms_housing', 'qs-housing', 'bcs_housing', qb-houses, esx_property, 'origen_housing', 'brutal_housing', rtx_housing'
Config.ClothingSystem = 'auto'  -- 'auto', 'tgiann-clothing', qb-clothing, esx_skin, 'illenium-appearance', 'qs-appearance', 'origen_clothing', 'rcore_clothing', 'fivem-appearance'
Config.InventorySystem = 'auto'  -- 'auto', 'core_inventory', 'qs-inventory', 'ox_inventory', 'ak47_inventory', 'inventory (chezza inventory)', 'tgiann-inventory', 'origen_inventory', 'jaksam_inventory', 'codem-inventory', 'qb-inventory'
Config.GarageSystem = 'auto'  -- 'auto', 'vms_garagesv2', 'qb-garage', 'esx_garage', 'origen_garage', 'qs-advancedgarage', 'jg-advancedgarages', 'okokGarage', 'op-garages', 'cd_garage', 'lunar_garage'
Config.GangSystem = 'auto'  -- 'auto', 'jc_organizaciones', 'op-crime', 'av_gangs'

Config.KickActions = { -- Command and key to open the quick actions menu
    command = 'kickactions',
    key = 'F6',
}

Config.StaffClothing = { -- Staff clothing configuration
    [1] = { drawable = 0, texture = 0 }, -- Mask
    [3] = { drawable = 15, texture = 0 },  -- Arms
    [4] = { drawable = 14, texture = 0 },  -- Legs / Pants
    [5] = { drawable = 0, texture = 0 },  -- Backpack
    [6] = { drawable = 5, texture = 0 },   -- Shoes
    [7] = { drawable = 0, texture = 0 },   -- Accessories
    [8] = { drawable = 15, texture = 0 },  -- T-shirt
    [9] = { drawable = 0, texture = 0 },   -- Bulletproof vest
    [10] = { drawable = 0, texture = 0 },  -- Decals
    [11] = { drawable = 15, texture = 0 },  -- Jacket / Tops
}

Config.DefaultUsers = { -- Username and password that are given to an administrator by default
    user = "Admin",
    password = "123456"
}

Config.Commands = { -- Commands that exist in the script that can be used
    commandConsole = {
        unbanConsole = "jdunban",
        addAdminConsole = "setadmin",
    },
    commandVoice = {
        call = "call", -- [/call ID] | To enter a private voice channel between the administrator and the player (only you will hear each other)
        leavecall = "leavecall", -- /leavecall | It's very important to leave the call when you're finished.
    },
    commandStaff = {
        coords = "dev",
        noclip = "noclip",
        invisible = "invisible",
        tpm = 'tpmarker',
        tpback = "tpback",
        deletecar = "delcar",
        fixvehicle = "fixvehicle",
        tags = "tags",
        godmode = "godmode",
        staffclothing = "staffclothing",
        gotoplayer = false,
        bring = false,
        bringback = false,
        giveitem = false,
        givevehicle = "givevehicle",
        setaccountmoney = false,
        kill = false,
        freeze = false,
        unfreeze = false
    }  
}

Config.Statistics = {
    Jobs = {
        police = { "police", "sheriff", "lspd", "bcso" },
        ems = { "ambulance", "ems", "hospital", "doctor" },
        mechanic = { "mechanic", "bennys", "tuner" },
        taxi = { "taxi", "drive" }
    },
    ResourceAlertCount = 150
}

Config.Debug = false --  Do not change this value
