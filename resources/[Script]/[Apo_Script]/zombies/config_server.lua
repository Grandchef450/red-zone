-------------------------------------- FIVECORE --------------------------------------
-- Thank you very much for being a Fivecore customer, we really appreciate it, if you
-- have any doubts please consult the documentation or contact us through our discord.
-- Documentation: https://fivecore.gitbook.io/
-- Discord: https://discord.gg/GU6DqpcHYx
--------------------------------------------------------------------------------------

Config = {
    Safezones = { -- Safezones where zombies can't spawn ( you can manage safezones in runtime with exports )
        -- {
        --     id = 'safezone1', -- Safezone ID
        --     coords = vector3(1698.28, 2586.14, 51.25), -- Safezone coords
        --     radius = 250.0, -- Safezone radius
        --     createBlip = false, -- Create a blip on the map (true/false)
        --     blipLabel = 'Safe Zone', -- Blip label if createBlip is true
        --     despawnZombies = false -- Despawn zombies that enter the safezone (true/false)
        -- },
    },

    Hordezones = { -- Zones with HordeMode enabled by default
        -- {
        --     id = 'hordezone1', -- Hordezone ID
        --     coords = vector3(0.0, 0.0, 0.0), -- Hordezone coords
        --     radius = 200.0, -- Hordezone radius
        --     density = 100,  -- How many zombies will spawn around the player
        --     createBlip = true,  -- Create a blip on the map (true/false)
        --     blipLabel = 'Horde',  -- Blip label if createBlip is true
        -- }
    },

    DamagesChances = { -- Chances of zombie hitting the player with weak, medium or strong attack (in %)
        ['weak'] = 50,
        ['medium'] = 35,
        ['strong'] = 15
    },

    ChanceBreakVehicleWindowOnAttack = 20, -- Chance to break the vehicle window (0 to 100%) when a zombie attacks it, if the vehicle window is broken the zombie will attack the player inside the vehicle

    HordeMode = {
        [1] = { -- Horde Mode 1: Light
            density = 30, -- How many zombies will spawn around the player
            radius = 60 -- Radius that zombies around the player will instantly target the player
        },
        [2] = { -- Horde Mode 2: Medium
            density = 50,
            radius = 80
        },
        [3] = { -- Horde Mode 3: Heavy
            density = 80,
            radius = 100,
        }
    },

    DiedZombieDespawnTime = 300, -- Time in seconds to despawn a dead zombie

    BoostDensityByTime = { -- Change the zombies density by time of the day (in game time)
        startHour = 0, -- Start hour to increase the zombies density 
        duration = 5, -- How many hours the zombies density will be increased after the startHour
        densityMultiplier = 2.0 -- Multiplier to increase the zombies density while in the specified time
    },

    DisableZombiesWhenNotBoosting = false, -- Disable zombies when the density is not boosted (true/false)
    DisableAnimalsWhenNotBoosting = false, -- Disable animals when the density is not boosted (true/false)

    Zombies = {
        ['male_infected'] = {
            label = 'Infected Man', -- Zombie name
            model = 'common_male', -- Random male ped from ZombiesCommonPeds config
            walk = 'clipset@anim@ingame@move_m@zombie@core', -- Walk style (this specific walk requires game build 3258 or newer)
            walkSpeed = 2.0, -- 1.0: slow, 2.0: normal, 3.0: fast
            health = 300, -- Spawn health
            armor = 0, -- Spawn armor
            headshot = true, -- Die with headshot
            damage = {['weak'] = 8, ['medium'] = 12, ['strong'] = 18}, -- Strength of attacks
            attackDelay = 2000, -- Waiting time between each attack
            alertDistance = 8, -- Default distance to see a player
            attackDistance = 1.2, -- Distance the zombie needs to be from the player to be able to carry out an attack
            spawnChance = 80, -- Chance of spawning this zombie over all other zombies,
        },

        ['female_infected'] = {
            label = 'Infected Woman',
            model = 'common_female',
            walk = 'clipset@anim@ingame@move_m@zombie@core',
            walkSpeed = 2.0, -- 1.0: slow, 2.0: normal, 3.0: fast
            health = 300,
            armor = 0,
            headshot = true,
            damage = {['weak'] = 8, ['medium'] = 12, ['strong'] = 18},
            attackDelay = 2000,
            alertDistance = 8,
            attackDistance = 1.2,
            spawnChance = 80
        },

        ['male_cop_infected'] = {
            label = 'Infected Cop',
            model = 's_m_y_cop_01',
            walk = 'move_characters@jimmy@slow@',
            walkSpeed = 3.0, -- 1.0: slow, 2.0: normal, 3.0: fast
            health = 450,
            armor = 0,
            headshot = true,
            damage = {['weak'] = 12, ['medium'] = 18, ['strong'] = 24},
            attackDelay = 2000,
            alertDistance = 8,
            attackDistance = 1.2,
            spawnChance = 10
        },

        ['male_prisoner_infected'] = {
            label = 'Infected Prisoner',
            model = 'csb_rashcosvki',
            walk = 'move_characters@jimmy@slow@',
            walkSpeed = 3.0, -- 1.0: slow, 2.0: normal, 3.0: fast
            health = 500,
            armor = 0,
            headshot = true,
            damage = {['weak'] = 12, ['medium'] = 18, ['strong'] = 24},
            attackDelay = 2000,
            alertDistance = 8,
            attackDistance = 1.2,
            spawnChance = 10
        },

        ['male_patient_infected'] = {
            label = 'Infected Patient',
            model = 'u_m_y_corpse_01',
            walk = 'move_characters@jimmy@slow@',
            walkSpeed = 3.0, -- 1.0: slow, 2.0: normal, 3.0: fast
            health = 600,
            armor = 0,
            headshot = true,
            damage = {['weak'] = 12, ['medium'] = 18, ['strong'] = 24},
            attackDelay = 2000,
            alertDistance = 8,
            attackDistance = 1.2,
            spawnChance = 10
        },

        -- ['example_boss'] = { -- Boss example
        --     boss = true,
        --     label = 'Example Boss',
        --     model = 'a_m_o_salton_01',
        --     walk = 'move_characters@jimmy@slow@',
        --     walkSpeed = 5.0,
        --     health = 25000,
        --     armor = 0,
        --     headshot = false,
        --     damage = {['weak'] = 38, ['medium'] = 49, ['strong'] = 63},
        --     attackDelay = 1000,
        --     alertDistance = 16,
        --     attackDistance = 1.2,
        --     spawnChance = -1, -- Don't spawn in world, only use fixed spawns
        --     fixedSpawns = { -- Coords to spawn zombie and respawn time (in minutes)
        --         {   coords = vector3(1182.15, -3041.92, 33.7),
        --             stayNearSpawnRadius = 60,
        --             respawnTime = 25,
        --             debug = true
        --         },
        --     },
        --     blip = { -- Create blip on ped (https://docs.fivem.net/docs/game-references/blips/)
        --         sprite = 429,
        --         color = 1,
        --         scale = 1.0,
        --     },
        --     showHealthBar = true,
        --     specials = {
        --         toxic = true, -- Create toxic gas around the zombie
        --     },
        --     proofs = {
        --         bullet = true,
        --         fire = true,
        --         explosion = true,
        --         collision = true,
        --         melee = true,
        --         shock = true
        --     }
        -- },

        -- Animals
        ['boar'] = {
            isAnimal = true,
            label = 'Infected Boar', -- Zombie name
            model = 'a_c_boar',
            alertDistance = 15,
            agressive = true,
            health = 300, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['deer'] = {
            isAnimal = true,
            label = 'Infected Deer', -- Zombie name
            model = 'a_c_deer',
            alertDistance = 15,
            health = 300, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['pig'] = {
            isAnimal = true,
            label = 'Infected Pig', -- Zombie name
            model = 'a_c_pig',
            alertDistance = 15,
            health = 200, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['cow'] = {
            isAnimal = true,
            label = 'Infected Cow', -- Zombie name
            model = 'a_c_cow',
            alertDistance = 15,
            health = 300, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['chicken'] = {
            isAnimal = true,
            label = 'Infected Chicken', -- Zombie name
            model = 'a_c_hen',
            alertDistance = 15,
            health = 300, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['coyote'] = {
            isAnimal = true,
            label = 'Infected Coyote', -- Zombie name
            model = 'a_c_coyote',
            alertDistance = 15,
            health = 300, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },

        ['rabbit'] = {
            isAnimal = true,
            label = 'Infected Rabbit', -- Zombie name
            model = 'a_c_rabbit_01',
            alertDistance = 15,
            health = 200, -- Spawn health
            spawnChance = 1, -- Chance of spawning this zombie over all other zombies
        },
    },

    DefaultWeaponNoise = 30, -- Use this radius if the weapon is not in the list below
    SilencedWeaponNoiseReductionPercentage = 50, -- Reduce the noise radius when shooting with a silenced weapon (in %)
    WeaponsNoise = { -- Radius to attract zombies when shooting with these weapons
        -- Handguns
        [`weapon_pistol`] = 50,
        [`weapon_pistol_mk2`] = 50,
        [`weapon_combatpistol`] = 50,
        [`weapon_appistol`] = 50,
        [`weapon_stungun`] = 0,
        [`weapon_pistol50`] = 60,
        [`weapon_snspistol`] = 50,
        [`weapon_snspistol_mk2`] = 50,
        [`weapon_heavypistol`] = 50,
        [`weapon_vintagepistol`] = 50,
        [`weapon_flaregun`] = 0,
        [`weapon_marksmanpistol`] = 50,
        [`weapon_revolver`] = 70,
        [`weapon_revolver_mk2`] = 75,
        [`weapon_doubleaction`] = 70,
        [`weapon_raypistol`] = 30,
        [`weapon_ceramicpistol`] = 50,
        [`weapon_navyrevolver`] = 70,
        [`weapon_gadgetpistol`] = 50,
        [`weapon_stungun_mp`] = 0,
        [`weapon_pistolxm3`] = 50,

        -- Submachine Guns
        [`weapon_microsmg`] = 80,
        [`weapon_smg`] = 80,
        [`weapon_smg_mk2`] = 85,
        [`weapon_assaultsmg`] = 80,
        [`weapon_combatpdw`] = 80,
        [`weapon_machinepistol`] = 80,
        [`weapon_minismg`] = 80,
        [`weapon_raycarbine`] = 80,
        [`weapon_tecpistol`] = 80,

        -- Shotguns
        [`weapon_pumpshotgun`] = 70,
        [`weapon_pumpshotgun_mk2`] = 70,
        [`weapon_sawnoffshotgun`] = 70,
        [`weapon_assaultshotgun`] = 70,
        [`weapon_bullpupshotgun`] = 70,
        [`weapon_musket`] = 80,
        [`weapon_heavyshotgun`] = 70,
        [`weapon_dbshotgun`] = 70,
        [`weapon_autoshotgun`] = 70,
        [`weapon_combatshotgun`] = 70,

        -- Assault Rifles
        [`weapon_assaultrifle`] = 70,
        [`weapon_assaultrifle_mk2`] = 75,
        [`weapon_carbinerifle`] = 70,
        [`weapon_carbinerifle_mk2`] = 70,
        [`weapon_advancedrifle`] = 70,
        [`weapon_specialcarbine`] = 70,
        [`weapon_specialcarbine_mk2`] = 70,
        [`weapon_bullpuprifle`] = 70,
        [`weapon_bullpuprifle_mk2`] = 70,
        [`weapon_compactrifle`] = 70,
        [`weapon_militaryrifle`] = 70,
        [`weapon_heavyrifle`] = 70,
        [`weapon_tacticalrifle`] = 70,

        -- Light Machine Guns
        [`weapon_mg`] = 80,
        [`weapon_combatmg`] = 80,
        [`weapon_combatmg_mk2`] = 80,
        [`weapon_gusenberg`] = 80,

        -- Sniper Rifles
        [`weapon_sniperrifle`] = 90,
        [`weapon_heavysniper`] = 90,
        [`weapon_heavysniper_mk2`] = 90,
        [`weapon_marksmanrifle`] = 90,
        [`weapon_marksmanrifle_mk2`] = 90,
        [`weapon_precisionrifle`] = 90,

        -- Heavy Weapons
        [`weapon_rpg`] = 60,
        [`weapon_grenadelauncher`] = 60,
        [`weapon_grenadelauncher_smoke`] = 60,
        [`weapon_minigun`] = 60,
        [`weapon_firework`] = 60,
        [`weapon_railgun`] = 60,
        [`weapon_hominglauncher`] = 60,
        [`weapon_compactlauncher`] = 60,
        [`weapon_rayminigun`] = 60,
        [`weapon_emplauncher`] = 60,
        [`weapon_railgunxm3`] = 60
    },

    VehiclesNoise = { -- Radius to attract zombies when driving these vehicles categories
        [0] = 50, -- Compacts  
        [1] = 50, -- Sedans  
        [2] = 60, -- SUVs  
        [3] = 50, -- Coupes
        [4] = 55, -- Muscle
        [5] = 50, -- Sports Classics
        [6] = 50, -- Sports
        [7] = 50, -- Super
        [8] = 30, -- Motorcycles
        [9] = 50, -- Off-road
        [10] = 50, -- Industrial
        [11] = 50, -- Utility
        [12] = 50, -- Vans
        [13] = 0, -- Cycles
        [14] = 40, -- Boats
        [15] = 90, -- Helicopters
        [16] = 90, -- Planes
        [17] = 50, -- Service
        [18] = 50, -- Emergency
        [19] = 50, -- Military
        [20] = 50, -- Commercial
        [21] = 50, -- Trains
        [22] = 50, -- Open Wheel
    },
    OverrideVehicleNoise = { -- Override the default noise radius for specific vehicles models
        -- [`zentorno`] = 60, -- Example
    },

    ZombiesCommonPeds = { -- Peds used for zombie with model defined as 'common_male' or 'common_female'
        common_male = {
            'a_m_m_afriamer_01', 'a_m_m_beach_01', 'a_m_m_bevhills_01', 'a_m_m_bevhills_02', 'a_m_m_business_01', 'a_m_m_eastsa_01', 'a_m_m_eastsa_02', 'a_m_m_farmer_01', 'a_m_m_fatlatin_01', 'a_m_m_genfat_01', 'a_m_m_genfat_02', 'a_m_m_hillbilly_01', 'a_m_m_hillbilly_02', 'a_m_m_indian_01', 'a_m_m_ktown_01', 'a_m_m_malibu_01', 'a_m_m_mexcntry_01', 'a_m_m_mexlabor_01', 'a_m_m_og_boss_01', 'a_m_m_paparazzi_01', 'a_m_m_polynesian_01', 'a_m_m_prolhost_01', 'a_m_m_rurmeth_01', 'a_m_m_salton_01', 'a_m_m_salton_02', 'a_m_m_salton_03', 'a_m_m_salton_04', 'a_m_m_skater_01', 'a_m_m_skidrow_01', 'a_m_m_socenlat_01', 'a_m_m_soucent_01', 'a_m_m_soucent_02', 'a_m_m_soucent_03', 'a_m_m_soucent_04', 'a_m_m_stlat_02', 'a_m_m_tennis_01', 'a_m_m_tourist_01', 'a_m_m_tramp_01', 'a_m_m_trampbeac_01', 'a_m_o_acult_01', 'a_m_o_acult_02', 'a_m_o_beach_01', 'a_m_o_genstreet_01', 'a_m_o_ktown_01', 'a_m_o_salton_01', 'a_m_o_soucent_01', 'a_m_o_soucent_02', 'a_m_o_soucent_03', 'a_m_o_tramp_01', 'a_m_y_acult_01', 'a_m_y_acult_02', 'a_m_y_beach_01', 'a_m_y_beach_02', 'a_m_y_beach_03', 'a_m_y_beachvesp_01', 'a_m_y_beachvesp_02', 'a_m_y_bevhills_01', 'a_m_y_bevhills_02', 'a_m_y_breakdance_01', 'a_m_y_busicas_01', 'a_m_y_business_01', 'a_m_y_business_02', 'a_m_y_business_03', 'a_m_y_clubcust_01', 'a_m_y_cyclist_01', 'a_m_y_dhill_01', 'a_m_y_downtown_01', 'a_m_y_eastsa_01', 'a_m_y_eastsa_02', 'a_m_y_epsilon_01', 'a_m_y_epsilon_02', 'a_m_y_gay_01', 'a_m_y_gay_02', 'a_m_y_genstreet_01', 'a_m_y_genstreet_02', 'a_m_y_golfer_01', 'a_m_y_hasjew_01', 'a_m_y_hiker_01', 'a_m_y_hippy_01', 'a_m_y_hipster_01', 'a_m_y_hipster_02', 'a_m_y_hipster_03', 'a_m_y_indian_01', 'a_m_y_jetski_01', 'a_m_y_juggalo_01', 'a_m_y_ktown_01', 'a_m_y_ktown_02', 'a_m_y_latino_01', 'a_m_y_methhead_01', 'a_m_y_mexthug_01', 'a_m_y_musclbeac_02', 'a_m_y_polynesian_01', 'a_m_y_roadcyc_01', 'a_m_y_runner_01', 'a_m_y_runner_02', 'a_m_y_salton_01', 'a_m_y_skater_01', 'a_m_y_skater_02', 'a_m_y_soucent_01', 'a_m_y_soucent_02', 'a_m_y_soucent_03', 'a_m_y_soucent_04', 'a_m_y_stbla_01', 'a_m_y_stbla_02', 'a_m_y_stlat_01', 'a_m_y_stwhi_01', 'a_m_y_sunbathe_01', 'a_m_y_surfer_01', 'a_m_y_vindouche_01', 'a_m_y_vinewood_01', 'a_m_y_vinewood_02', 'a_m_y_vinewood_03', 'a_m_y_vinewood_04', 'a_m_m_mlcrisis_01', 'a_m_y_gencaspat_01', 'a_m_y_smartcaspat_01'
        },
        common_female = {
            'a_f_m_bevhills_01', 'a_f_m_bevhills_02', 'a_f_m_business_02', 'a_f_m_downtown_01', 'a_f_m_eastsa_01', 'a_f_m_eastsa_02', 'a_f_m_fatbla_01', 'a_f_m_fatcult_01', 'a_f_m_fatwhite_01', 'a_f_m_ktown_01', 'a_f_m_ktown_02', 'a_f_m_prolhost_01', 'a_f_m_salton_01', 'a_f_m_skidrow_01', 'a_f_m_soucent_01', 'a_f_m_soucent_02', 'a_f_m_soucentmc_01', 'a_f_m_tourist_01', 'a_f_m_tramp_01', 'a_f_m_trampbeac_01', 'a_f_o_genstreet_01', 'a_f_o_indian_01', 'a_f_o_ktown_01', 'a_f_o_salton_01', 'a_f_o_soucent_01', 'a_f_o_soucent_02', 'a_f_y_beach_01', 'a_f_y_bevhills_01', 'a_f_y_bevhills_02', 'a_f_y_bevhills_03', 'a_f_y_bevhills_04', 'a_f_y_business_01', 'a_f_y_business_02', 'a_f_y_business_03', 'a_f_y_business_04', 'a_f_y_clubcust_01', 'a_f_y_clubcust_02', 'a_f_y_clubcust_03', 'a_f_y_eastsa_01', 'a_f_y_eastsa_02', 'a_f_y_eastsa_03', 'a_f_y_epsilon_01', 'a_f_y_femaleagent', 'a_f_y_fitness_01', 'a_f_y_fitness_02', 'a_f_y_genhot_01', 'a_f_y_golfer_01', 'a_f_y_hiker_01', 'a_f_y_hippie_01', 'a_f_y_hipster_01', 'a_f_y_hipster_02', 'a_f_y_hipster_03', 'a_f_y_hipster_04', 'a_f_y_indian_01', 'a_f_y_juggalo_01', 'a_f_y_runner_01', 'a_f_y_rurmeth_01', 'a_f_y_scdressy_01', 'a_f_y_skater_01', 'a_f_y_soucent_01', 'a_f_y_soucent_02', 'a_f_y_soucent_03', 'a_f_y_tennis_01', 'a_f_y_topless_01', 'a_f_y_tourist_01', 'a_f_y_tourist_02', 'a_f_y_vinewood_01', 'a_f_y_vinewood_02', 'a_f_y_vinewood_03', 'a_f_y_vinewood_04', 'a_f_y_yoga_01', 'a_f_y_gencaspat_01', 'a_f_y_smartcaspat_01'
        }
    },

    AttackAnimation = {"melee@unarmed@streamed_core_fps", "ground_attack_on_spot_var_a", 48}, -- Animation dictionary, animation name and flag

    hasZGODPermission = function(source) -- Permission to use the /zgod command to become invisible to zombies
        return IsPlayerAceAllowed(source, 'command')
    end,

    hasSetHordePermission = function(source) -- Permission to use the /sethorde command to set the horde mode for a specific player
        return IsPlayerAceAllowed(source, 'command')
    end,

    -- OverrideZonesDensity = 25, -- Override the density for all zones
    Zones = { -- Zombies spawn density for each zone (density is how much zombies is around a player)
        ['AIRP'] = {max = 150, density = 15}, -- Los Santos International Airport 
        ['ALAMO'] = {max = 150, density = 10}, -- Alamo Sea
        ['ALTA'] = {max = 124, density = 15}, -- Alta
        ['ARMYB'] = {max = 150, density = 45}, -- Fort Zancudo
        ['BANHAMC'] = {max = 57, density = 15}, -- Banham Canyon Dr  
        ['BANNING'] = {max = 150, density = 15}, -- Banning  
        ['BAYTRE'] = {max = 63, density = 15},
        ['BEACH'] = {max = 150, density = 15}, -- Vespucci Beach 
        ['BHAMCA'] = {max = 150, density = 15}, -- Banham Canyon  
        ['BRADP'] = {max = 109, density = 15}, -- Braddock Pass  
        ['BRADT'] = {max = 10, density = 15}, -- Braddock Tunnel  
        ['BURTON'] = {max = 150, density = 25}, -- Burton 
        ['CALAFB'] = {max = 8, density = 15}, -- Calafia Bridge  
        ['CANNY'] = {max = 150, density = 15}, -- Raton Canyon  
        ['CCREAK'] = {max = 139, density = 15}, -- Cassidy Creek  
        ['CHAMH'] = {max = 78, density = 15}, --  Chamberlain Hills  
        ['CHIL'] = {max = 150, density = 15}, -- Vinewood Hills  
        ['CHU'] = {max = 150, density = 15}, -- Chumash  
        ['CMSW'] = {max = 150, density = 0}, -- Chiliad Mountain State Wilderness
        ['CYPRE'] = {max = 150, density = 25}, -- Cypress Flats
        ['DAVIS'] = {max = 150, density = 25}, -- Davis 
        ['DELBE'] = {max = 150, density = 15}, -- Del Perro Beach  
        ['DELPE'] = {max = 150, density = 15}, -- Del Perro  
        ['DELSOL'] = {max = 150, density = 15}, -- La Puerta  
        ['DESRT'] = {max = 150, density = 10}, -- Grand Senora Desert  
        ['DOWNT'] = {max = 62, density = 15}, -- Downtown
        ['DTVINE'] = {max = 150, density = 25}, -- Downtown Vinewood
        ['EAST_V'] = {max = 150, density = 15}, -- East Vinewood
        ['EBURO'] = {max = 150, density = 25}, -- El Burro Heights  
        ['ELGORL'] = {max = 17, density = 15}, -- El Gordo Lighthouse
        ['ELYSIAN'] = {max = 150, density = 15}, -- Elysian Island
        ['GALFISH'] = {max = 15, density = 15}, -- Galilee
        ['GALLI'] = {max = 150, density = 15},
        ['GOLF'] = {max = 141, density = 15}, -- GWC and Golfing Society 
        ['GRAPES'] = {max = 150, density = 5}, -- Grapeseed  
        ['GREATC'] = {max = 150, density = 15}, -- Great Chaparral 
        ['HARMO'] = {max = 122, density = 15}, -- Harmony  
        ['HAWICK'] = {max = 114, density = 15}, -- Hawick  
        ['HORS'] = {max = 120, density = 15}, -- Vinewood Racetrack  
        ['HUMLAB'] = {max = 150, density = 20}, -- Humane Labs and Research 
        ['JAIL'] = {max = 121, density = 25}, -- Bolingbroke Penitentiary 
        ['KOREAT'] = {max = 150, density = 20}, -- Little Seoul 
        ['LACT'] = {max = 150, density = 15}, -- Land Act Reservoir  
        ['LAGO'] = {max = 150, density = 15}, -- Lago Zancudo  
        ['LDAM'] = {max = 9, density = 15}, -- Land Act Dam
        ['LEGSQU'] = {max = 17, density = 20}, -- Legion Square  
        ['LMESA'] = {max = 150, density = 15}, -- La Mesa
        ['LOSPUER'] = {max = 150, density = 15}, -- La Puerta
        ['MIRR'] = {max = 150, density = 20}, -- Mirror Park
        ['MORN'] = {max = 64, density = 20}, -- Morningwood
        ['MOVIE'] = {max = 39, density = 15}, -- Richards Majestic 
        ['MTCHIL'] = {max = 150, density = 15}, -- Mount Chiliad 
        ['MTGORDO'] = {max = 150, density = 15}, -- Mount Gordo
        ['MTJOSE'] = {max = 150, density = 15}, -- Mount Josiah
        ['MURRI'] = {max = 150, density = 15}, -- Murrieta Heights
        ['NCHU'] = {max = 150, density = 15}, -- North Chumash
        ['NOOSE'] = {max = 35, density = 15}, -- N.O.O.S.E  
        ['OCEANA'] = {max = 0, density = 0}, -- Pacific Ocean
        ['OBSERV'] = {max = 28, density = 15},
        ['PALCOV'] = {max = 150, density = 0}, -- Paleto Cove
        ['PALETO'] = {max = 150, density = 25}, -- Paleto Bay
        ['PALFOR'] = {max = 150, density = 3}, -- Paleto Forest
        ['PALHIGH'] = {max = 150, density = 15}, -- Palomino Highlands
        ['PALMPOW'] = {max = 145, density = 15}, -- Palmer-Taylor Power Station
        ['PBLUFF'] = {max = 150, density = 15}, -- Pacific Bluffs
        ['PBOX'] = {max = 282, density = 30}, -- Pillbox Hill
        ['PROCOB'] = {max = 89, density = 15}, -- Procopio Beach
        ['RANCHO'] = {max = 150, density = 15}, -- Rancho
        ['RGLEN'] = {max = 20, density = 30}, -- Richman Glen
        ['RICHM'] = {max = 150, density = 15}, -- Richman
        ['ROCKF'] = {max = 150, density = 25}, -- Rockford Hills
        ['RTRAK'] = {max = 150, density = 15}, -- Redwood Lights Track
        ['SANAND'] = {max = 0, density = 15}, -- San Andreas
        ['SANCHIA'] = {max = 150, density = 15}, -- San Chianski Mountain Range
        ['SANDY'] = {max = 150, density = 15}, -- Sandy Shores
        ['SKID'] = {max = 71, density = 30}, -- Mission Row
        ['SLAB'] = {max = 20, density = 9}, -- Stab City
        ['STAD'] = {max = 94, density = 15}, -- Maze Bank Arena
        ['STRAW'] = {max = 150, density = 15}, -- Strawberry
        ['TATAMO'] = {max = 150, density = 15}, -- Tataviam Mountains
        ['TERMINA'] =  {max = 150, density = 15}, -- Terminal
        ['TEXTI'] = {max = 55, density = 15}, -- Textile City
        ['TONGVAH'] = {max = 150, density = 15}, -- Tongva Hills
        ['TONGVAV'] = {max = 150, density = 15}, -- Tongva Valley
        ['VCANA'] = {max = 194, density = 15}, -- Vespucci Canals
        ['VESP'] = {max = 18, density = 15}, -- Vespucci
        ['VINE'] = {max = 37, density = 25}, -- Vinewood
        ['WINDF'] = {max = 150, density = 6}, -- Ron Alternates Wind Farm
        ['WVINE'] = {max = 150, density = 30}, -- West Vinewood
        ['ZANCUDO'] = {max = 150, density = 15}, -- Zancudo River
        ['ZP_ORT'] = {max = 1, density = 15}, -- Port of South Los Santos
        ['ZQ_UAR'] = {max = 150, density = 0}, -- Davis Quartz
        ['PROL'] = {max = 150, density = 15},
        ['ISHEIST']= {max = 0, density = 0},
        ['UNDEFINED'] = {max = 15, density = 15} -- USED WHEN THE PLAYER CURRENT ZONE IS NOT DEFINED IN THIS LIST
    }
}