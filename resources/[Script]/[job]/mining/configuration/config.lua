-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

Config = {}

Config.checkForUpdates = true -- Check for Updates?
Config.oldESX = false -- Does not apply to qb users (If set to true, won't check if player can carry item)

Config.axe = {
    prop = `prop_tool_pickaxe`, --Default: `prop_tool_pickaxe`
    breakChance = 3 -- When failing to mine rock, this is the percentage of a chance that your pickaxe will 'break'
}

-- ═══════════════════════════════════════════════════════════════
--  MINERAIS REDZONE
--
--  Les cinq items d'origine (emerald, diamond, copper, iron, steel)
--  n'existaient pas dans ox_inventory. Ils sont remplacés par les
--  minerais du tableau de craft, ceux-là mêmes qui alimentent la
--  fonderie et donc toute la chaîne de deuxième catégorie.
--
--  La difficulté suit la rareté : plus le minerai est précieux dans
--  l'arbre de craft, plus l'extraction demande de précision.
--
--  `price` n'est utilisé QUE si la revente au PNJ est activée. Sur
--  RedZone l'intérêt du minerai est de le fondre, pas de le vendre.
-- ═══════════════════════════════════════════════════════════════
Config.rocks = {
    -- Rares : ce sont eux qui donnent les lingots précieux
    { item = 'minerai_or',        label = "Minerai d'or",        price = {190, 220}, difficulty = {'medium', 'medium', 'hard'} },
    { item = 'minerai_argent',    label = "Minerai d'argent",    price = {170, 200}, difficulty = {'medium', 'medium', 'easy'} },

    -- Intermédiaires : entrent dans les alliages et les munitions
    { item = 'minerai_graphite',  label = 'Minerai de graphite', price = {150, 180}, difficulty = {'medium', 'medium'} },
    { item = 'minerai_silicium',  label = 'Minerai de silicium', price = {140, 170}, difficulty = {'medium', 'medium'} },
    { item = 'minerai_magnesium', label = 'Minerai de magnésium',price = {130, 160}, difficulty = {'medium', 'easy'} },
    { item = 'minerai_soufre',    label = 'Minerai de soufre',   price = {120, 150}, difficulty = {'medium', 'easy'} },

    -- Courants : la base de la fonderie
    { item = 'minerai_cuivre',    label = 'Minerai de cuivre',   price = {110, 140}, difficulty = {'medium', 'easy'} },
    { item = 'minerai_aluminium', label = "Minerai d'aluminium", price = {90, 120},  difficulty = {'easy', 'easy'} },
    { item = 'minerai_fer',       label = 'Minerai de fer',      price = {70, 100},  difficulty = {'easy', 'easy'} },
    { item = 'minerai_charbon',   label = 'Minerai de charbon',  price = {50, 80},   difficulty = {'easy', 'easy'} },

    -- Très courants : ramassés en volume
    { item = 'pierre_silex',      label = 'Pierre de silex',     price = {40, 60},   difficulty = {'easy', 'easy'} },
    { item = 'sable',             label = 'Sable',               price = {30, 50},   difficulty = {'easy'} },
}


Config.miningAreas = {
    vec3(2977.45, 2741.62, 44.62), -- vec3 of locations for mining stones
    vec3(2982.64, 2750.89, 42.99),
    vec3(2994.92, 2750.43, 44.04),
    vec3(2958.21, 2725.44, 50.16),
    vec3(2946.3, 2725.36, 47.94),
    vec3(3004.01, 2763.27, 43.56),
    vec3(3001.79, 2791.01, 44.82)
}

Config.sellShop = {
    enabled = false, -- Enable spot to sell the things mined?
    coords = vec3(122.1, 6405.69, 31.36-0.9), -- Location of buyer
    heading = 314.65, -- Heading of ped
    ped = 'cs_joeminuteman' -- Ped name here
}

RegisterNetEvent('wasabi_mining:notify')
AddEventHandler('wasabi_mining:notify', function(title, message, msgType)	
    -- Place notification system info here, ex: exports['mythic_notify']:SendAlert('inform', message)
    if not msgType then
        lib.notify({
            title = title,
            description = message,
            type = 'inform'
        })
    else
        lib.notify({
            title = title,
            description = message,
            type = msgType
        })
    end
end)
