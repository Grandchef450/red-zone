Config = {}

Config.progressPerCatch = 0.05 -- The progress per one fish caught

---@class Fish
---@field price integer | { min: integer, max: integer }
---@field chance integer Percentage chance
---@field skillcheck SkillCheckDifficulity }

---@type table<string, Fish>
-- ═══════════════════════════════════════════════════════════════
--  POISSONS REDZONE
--
--  Les dix espèces d'origine (anchovy, grouper, piranha, tuna...)
--  n'existaient pas dans ox_inventory. On garde les QUATRE qui sont
--  déjà dans items.lua et qui alimentent la chaîne de cuisson :
--  cuisson simple puis plats avancés.
--
--  Un poisson pêché sort CRU. C'est le BBQ qui le transforme, et
--  c'est là que se trouve la vraie valeur — pas dans la revente.
-- ═══════════════════════════════════════════════════════════════
Config.fish = {
    ['filet_truite_cru']  = { price = { min = 50, max = 100 },  chance = 35, skillcheck = { 'easy', 'medium' } },
    ['filet_morue_cru']   = { price = { min = 150, max = 200 }, chance = 30, skillcheck = { 'easy', 'medium' } },
    ['pave_saumon_cru']   = { price = { min = 200, max = 250 }, chance = 20, skillcheck = { 'easy', 'medium', 'medium' } },
    ['steak_requin_cru']  = { price = { min = 900, max = 1200 },chance = 3,  skillcheck = { 'easy', 'medium', 'hard' } },
}

---@class FishingRod
---@field name string
---@field price integer
---@field minLevel integer The minimal level
---@field breakChance integer Percentage chance

---@type FishingRod[]
-- Les trois cannes existent déjà dans items.lua et sont craftables
-- en phases 2, 3 et 4. La progression du script suit donc celle de
-- l'arbre de craft, sans qu'on ait rien à inventer.
Config.fishingRods = {
    { name = 'canne_peche',              price = 1000, minLevel = 1, breakChance = 20 },
    { name = 'canne_peche_carbone',      price = 2500, minLevel = 2, breakChance = 10 },
    { name = 'canne_peche_fibre_verre',  price = 5000, minLevel = 3, breakChance = 1 },
}

---@class FishingBait
---@field name string
---@field price integer
---@field minLevel integer The minimal level
---@field waitDivisor number The total wait time gets divided by this value

---@type FishingBait[]
-- ⚠️  Ces deux items n'existent PAS encore dans ox_inventory.
--     Le bloc à coller dans data/items.lua est fourni à part.
Config.baits = {
    { name = 'ver_de_terre',    price = 5,  minLevel = 1, waitDivisor = 1.0 },
    { name = 'appat_artificiel',price = 50, minLevel = 2, waitDivisor = 3.0 },
}

---@class FishingZone
---@field locations vector3[] One of these gets picked at random
---@field radius number
---@field minLevel integer
---@field waitTime { min: integer, max: integer }
---@field includeOutside boolean Whether you can also catch fish from Config.outside
---@field blip BlipData?
---@field message { enter: string, exit: string }?
---@field fishList string[]

---@type FishingZone[]
Config.fishingZones = {
    {
        blip = {
            name = 'Coral Reef',
            sprite = 317,
            color = 24,
            scale = 0.6
        },
        locations = {
            vector3(-1774.0654, -1796.2740, 0.0),
            vector3(2482.8589, -2575.6780, 0.0)
        },
        radius = 250.0,
        minLevel = 1,
        waitTime = { min = 5, max = 10 },
        includeOutside = true,
        message = { enter = 'You have entered a coral reef.', exit = 'You have left the coral reef.' },
        fishList = { 'pave_saumon_cru' }
    },
    {
        blip = {
            name = 'Deep Waters',
            sprite = 317,
            color = 29,
            scale = 0.6
        },
        locations = {
            vector3(-4941.7964, -2411.9146, 0.0),
        },
        radius = 1000.0,
        minLevel = 3,
        waitTime = { min = 20, max = 40 },
        includeOutside = false,
        message = { enter = 'You have entered deep waters.', exit = 'You have left deep waters.' },
        fishList = { 'filet_morue_cru', 'steak_requin_cru' }
    },
    {
        blip = {
            name = 'Swamp',
            sprite = 317,
            color = 56,
            scale = 0.6
        },
        locations = {
            vector3(-2188.1182, 2596.9348, 0.0),
        },
        radius = 200.0,
        minLevel = 2,
        waitTime = { min = 10, max = 20 },
        includeOutside = true,
        message = { enter = 'You have entered a swamp.', exit = 'You have left the swamp.' },
        fishList = { 'filet_truite_cru' }
    },
}

-- Outside of all zones
Config.outside = {
    waitTime = { min = 10, max = 25 },

    ---@type string[]
    fishList = { 'filet_truite_cru', 'filet_morue_cru', 'pave_saumon_cru' }
}

Config.ped = {
    model = `s_m_m_cntrybar_01`,
    buyAccount = 'money',
    sellAccount = 'money',
    blip = {
        name = 'SeaTrade Corporation',
        sprite = 356,
        color = 74,
        scale = 0.75
    },

    ---@type vector4[]
    locations = {
        vector4(-2081.3831, 2614.3223, 3.0840, 112.7910),
        vector4(-1492.3639, -939.2579, 10.2140, 144.0305)
    }
}

Config.renting = {
    model = `s_m_m_dockwork_01`, -- The ped model
    account = 'money',
    boats = {
        { model = `speeder`, price = 500, image = 'https://i.postimg.cc/mDSqWj4P/164px-Speeder.webp' },
        { model = `dinghy`, price = 750, image = 'https://i.postimg.cc/ZKzjZgj0/164px-Dinghy2.webp'  },
        { model = `tug`, price = 1250, image = 'https://i.postimg.cc/jq7vpKHG/164px-Tug.webp' }
    },
    blip = {
        name = 'Boat Rental',
        sprite = 410,
        color = 74,
        scale = 0.75
    },
    returnDivider = 5, -- Players can return it and get some cash back
    returnRadius = 30.0, -- The save radius

    ---@type { coords: vector4, spawn: vector4 }[]
    locations = {
        { coords = vector4(-1434.4818, -1512.2745, 2.1486, 25.8666), spawn = vector4(-1494.4496, -1537.6943, 2.3942, 115.6015) }
    }
}