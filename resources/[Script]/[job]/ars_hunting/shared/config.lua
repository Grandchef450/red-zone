lib.locale()

Config = {}
Config.Debug = false
Config.Target ="ox_target"           -- only supporting ox_target and qb-target | nil to disable targeting
Config.SpawnDelay = 1             -- seconds [how much time it should take between spawning animals]
Config.DeleteEntityRadius = 300.0 -- will delete animal if your 400 meters away from them

Config.TrackerItem = "traqueur_animal"
Config.TrackingDuration = 60      -- seconds
Config.DelayBetweenTracks = 120   -- seconds
Config.TrackingFailureChance = 20 -- [1 - 100]

Config.AimBlock = {
    enable = true,
    global = true,     -- false if you want to have aimblock only in hunting zones
    weaponsToBlock = { -- weapons that are disabled to shoot at players
        `weapon_musket`,
        -- `WEAPON_HEAVYSNIPER`,
    }
}
Config.HuntMaster = {
    enable = false,
    coords = vector4(1738.0, 3709.0, 33.1, 15.0), -- adapte les coords
    model = "s_m_m_ammucountry",
    vehicleSpawn = vector4(1740.0, 3705.0, 33.1, 15.0), -- adapte
    vehicleDeposit = vector3(1742.0, 3700.0, 33.1),     -- adapte
    blip = {
        enable = true,
        name = "Hunt Master",
        type = 141,
        scale = 0.8,
        color = 2,
    },
}


Config.BaitItem = "appat_chasse"
Config.BaitAttractionDistance = 100.0 -- in 200 radius it will atract an animal
Config.BaitTimeLimit = 2              -- minutes

Config.ImagesPath = "nui://ars_hunting/_icons/"


-- _____                           __  _
-- / ____|                         / _| (_)
-- | |      __ _  _ __ ___   _ __  | |_  _  _ __  ___
-- | |     / _` || '_ ` _ \ | '_ \ |  _|| || '__|/ _ \
-- | |____| (_| || | | | | || |_) || |  | || |  |  __/
-- \_____|\__,_||_| |_| |_|| .__/ |_|  |_||_|   \___|
--                         | |
--                         |_|

Config.Campfire = {
    enable = true,
    campfireItem = "feu_de_camp",
    items = {
        {
            label = "Steak de cerf",
            give = "steak_cerf",
            cookTime = 5, -- seconds
            require = {
                {
                    label = "Viande de cerf crue",
                    quantity = 1,
                    item = "viande_cerf_crue",
                },
            }
        },
        -- {
        --     label = "Cooked meat",
        --     give = "cooked_meat",
        --     cookTime = 5, -- seconds
        --     require = {
        --         {
        --             label = "Raw Meat",
        --             quantity = 1,
        --             item = "raw_meat",
        --         },
        --     }
        -- },
    }
}

-- _    _                _    _                  ______
-- | |  | |              | |  (_)                |___  /
-- | |__| | _   _  _ __  | |_  _  _ __    __ _      / /  ___   _ __    ___  ___
-- |  __  || | | || '_ \ | __|| || '_ \  / _` |    / /  / _ \ | '_ \  / _ \/ __|
-- | |  | || |_| || | | || |_ | || | | || (_| |   / /__| (_) || | | ||  __/\__ \
-- |_|  |_| \__,_||_| |_| \__||_||_| |_| \__, |  /_____|\___/ |_| |_| \___||___/
--                                        __/ |
--                                       |___/

Config.HuntingZones = {
    ["CHILIAD_MOUNTAINS"] = {
        coords = vec3(1125.88, 4622.2, 80.08),
        radius = 200.0,
        maxSpawns = 1,                                                  -- max animals spawned at one time
        allowedWeapons = { "weapon_musket", "weapon_knife" }, -- nil if you want to allow every weapon
        zone_radius = {
            enable = true,
            color = 1,
            opacity = 128,
        },
        blip = {
            enable = true,
            name = 'Hunting Zone',
            type = 141,
            scale = 1.0,
            color = 0,
        },
        animals = {
            {
                model = "a_c_deer",
                chance = 80, -- chance of spawning
                harvestTime = 5,
                harvestWeapons = { "weapon_knife" },
                blip = {
                    enable = true,
                    name = 'Deer',
                    type = 119,
                    scale = 0.8,
                    color = 1,
                },
                marker = {
                    enable = true,
                    color = { r = 196, g = 136, b = 77, a = 150 }
                },
                items = {
                    skins = {
                        {
                            item = "peau_cerf_abimee",
                            chance = 70,
                            maxQuantity = 1,
                        },
                        {
                            item = "peau_cerf_usee",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "peau_cerf_correcte",
                            chance = 30,
                            maxQuantity = 1,
                        },
                        {
                            item = "peau_cerf_belle",
                            chance = 25,
                            maxQuantity = 1,
                        },
                        {
                            item = "peau_cerf_parfaite",
                            chance = 5,
                            maxQuantity = 1,
                        },
                    },
                    meat = {
                        {
                            item = "viande_cerf_crue",
                            chance = 100,
                            maxQuantity = 4,
                        },
                    },
                    extra = { -- rare items
                        {
                            item = "bois_de_cerf",
                            chance = 30,
                            maxQuantity = 1,
                        },
                    }

                }
            },
            -- {
            --     model = "a_c_deer",
            --     chance = 80, -- chance of spawning
            --     harvestTime = 5,
            --     harvestWeapons = { "WEAPON_DAGGER" },
            --     blip = {
            --         enable = true,
            --         name = 'Deer',
            --         type = 8,
            --         scale = 0.8,
            --         color = 1,
            --     },
            --     marker = {
            --         enable = true,
            --         color = { r = 196, g = 136, b = 77, a = 150 }
            --     },
            --     items = {
            --         skins = {
            --             {
            --                 item = "skin_deer_ruined",
            --                 chance = 70,
            --                 maxQuantity = 1,
            --             },
            --             {
            --                 item = "skin_deer_low",
            --                 chance = 50,
            --                 maxQuantity = 1,
            --             },
            --             {
            --                 item = "skin_deer_medium",
            --                 chance = 30,
            --                 maxQuantity = 1,
            --             },
            --             {
            --                 item = "skin_deer_good",
            --                 chance = 25,
            --                 maxQuantity = 1,
            --             },
            --             {
            --                 item = "skin_deer_perfect",
            --                 chance = 5,
            --                 maxQuantity = 1,
            --             },
            --         },
            --         meat = {
            --             {
            --                 item = "raw_meat",
            --                 chance = 100,
            --                 maxQuantity = 10,
            --             },
            --             -- {
            --             --     item = "raw_meat",
            --             --     chance = 100,
            --             --     maxQuantity = 10,
            --             -- },
            --         },
            --         extra = { -- rare items
            --             {
            --                 item = "deer_horn",
            --                 chance = 30,
            --                 maxQuantity = 1,
            --             },
            --             -- {
            --             --     item = "deer_horn",
            --             --     chance = 30,
            --             --     maxQuantity = 1,
            --             -- },
            --         }

            --     }
            -- },
        }
    },
    -- ["CHILIAD_MOUNTAINS2"] = {
    --     coords = vec3(1125.88, 4622.2, 80.08),
    --     radius = 200.0,
    --     maxSpawns = 5,                                                  -- max animals spawned at one time
    --     allowedWeapons = { "WEAPON_HEAVYSNIPER_MK2", "WEAPON_DAGGER" }, -- nil if you want to allow every weapon
    --     blip = {
    --         enable = true,
    --         color = 1,
    --         opacity = 128,
    --     },
    --     animals = {
    --         {
    --             model = "a_c_deer",
    --             chance = 80, -- chance of spawning
    --             harvestTime = 5,
    --             harvestWeapons = { "WEAPON_DAGGER" },
    --             blip = {
    --                 enable = true,
    --                 name = 'Deer',
    --                 type = 8,
    --                 scale = 0.8,
    --                 color = 1,
    --             },
    --             marker = {
    --                 enable = true,
    --                 color = { r = 196, g = 136, b = 77, a = 150 }
    --             },
    --             items = {
    --                 skins = {
    --                     {
    --                         item = "skin_deer_ruined",
    --                         chance = 70,
    --                         maxQuantity = 1,
    --                     },
    --                     {
    --                         item = "skin_deer_low",
    --                         chance = 50,
    --                         maxQuantity = 1,
    --                     },
    --                     {
    --                         item = "skin_deer_medium",
    --                         chance = 30,
    --                         maxQuantity = 1,
    --                     },
    --                     {
    --                         item = "skin_deer_good",
    --                         chance = 25,
    --                         maxQuantity = 1,
    --                     },
    --                     {
    --                         item = "skin_deer_perfect",
    --                         chance = 5,
    --                         maxQuantity = 1,
    --                     },
    --                 },
    --                 meat = {
    --                     {
    --                         item = "raw_meat",
    --                         chance = 100,
    --                         maxQuantity = 10,
    --                     },
    --                     -- {
    --                     --     item = "raw_meat",
    --                     --     chance = 100,
    --                     --     maxQuantity = 10,
    --                     -- },
    --                 },
    --                 extra = { -- rare items
    --                     {
    --                         item = "deer_horn",
    --                         chance = 30,
    --                         maxQuantity = 1,
    --                     },
    --                     -- {
    --                     --     item = "deer_horn",
    --                     --     chance = 30,
    --                     --     maxQuantity = 1,
    --                     -- },
    --                 }

    --             }
    --         },
    --         -- {
    --         --     model = "a_c_deer",
    --         --     chance = 80, -- chance of spawning
    --         --     harvestTime = 5,
    --         --     harvestWeapons = { "WEAPON_DAGGER" },
    --         --     blip = {
    --         --         enable = true,
    --         --         name = 'Deer',
    --         --         type = 8,
    --         --         scale = 0.8,
    --         --         color = 1,
    --         --     },
    --         --     marker = {
    --         --         enable = true,
    --         --         color = { r = 196, g = 136, b = 77, a = 150 }
    --         --     },
    --         --     items = {
    --         --         skins = {
    --         --             {
    --         --                 item = "skin_deer_ruined",
    --         --                 chance = 70,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --             {
    --         --                 item = "skin_deer_low",
    --         --                 chance = 50,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --             {
    --         --                 item = "skin_deer_medium",
    --         --                 chance = 30,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --             {
    --         --                 item = "skin_deer_good",
    --         --                 chance = 25,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --             {
    --         --                 item = "skin_deer_perfect",
    --         --                 chance = 5,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --         },
    --         --         meat = {
    --         --             {
    --         --                 item = "raw_meat",
    --         --                 chance = 100,
    --         --                 maxQuantity = 10,
    --         --             },
    --         --             -- {
    --         --             --     item = "raw_meat",
    --         --             --     chance = 100,
    --         --             --     maxQuantity = 10,
    --         --             -- },
    --         --         },
    --         --         extra = { -- rare items
    --         --             {
    --         --                 item = "deer_horn",
    --         --                 chance = 30,
    --         --                 maxQuantity = 1,
    --         --             },
    --         --             -- {
    --         --             --     item = "deer_horn",
    --         --             --     chance = 30,
    --         --             --     maxQuantity = 1,
    --         --             -- },
    --         --         }

    --         --     }
    --         -- },
    --     }
    -- },

}

-- _____  _
-- / ____|| |
-- | (___  | |__    ___   _ __   ___
-- \___ \ | '_ \  / _ \ | '_ \ / __|
-- ____) || | | || (_) || |_) |\__ \
-- |_____/ |_| |_| \___/ | .__/ |___/
--                      | |
--                      |_|

Config.Shops = {
    ["HuntGear Store"] = {
        coords = vector4(1737.9392, 3709.2678, 33.1367, 15.5537),
        ped = {
            enable = Config.Target and true or true, -- false the last bool to dont use ped
            model = "s_m_m_ammucountry"
        },
        blip = {
            enable = true,
            type = 59,
            scale = 0.7,
            color = 5,
        },
        useDrawText = true,
        items = {
            sell = {
                {
                    item = "peau_cerf_abimee",
                    price = 250,
                    label = "Peau de cerf abîmée"
                },
                {
                    item = "peau_cerf_usee",
                    price = 500,
                    label = "Peau de cerf usée"
                },
                {
                    item = "peau_cerf_correcte",
                    price = 700,
                    label = "Peau de cerf correcte"
                },
                {
                    item = "peau_cerf_belle",
                    price = 1200,
                    label = "Belle peau de cerf"
                },
                {
                    item = "peau_cerf_parfaite",
                    price = 2250,
                    label = "Peau de cerf parfaite"
                },
                {
                    item = "bois_de_cerf",
                    price = 400,
                    label = "Bois de cerf"
                },
            },
            buy = {
                {
                    item = "appat_chasse",
                    label = "Appât de chasse",
                    price = 250,
                },
                {
                    item = "feu_de_camp",
                    label = "Feu de camp",
                    price = 750,
                },
                {
                    item = "traqueur_animal",
                    label = "Traqueur d'animaux",
                    price = 245,
                },
                {
                    item = "weapon_musket",
                    label = "Mousquet",
                    price = 300,
                },
                {
                    item = "weapon_knife",
                    label = "couteau",
                    price = 300,
                },
                {
                    item = "ammo-musket",
                    label = "Balles de mousquet",
                    price = 3,
                },
            }

        }
    },
        }
    -- ["HuntGear Store2"] = {
    --     coords = vector4(967.6, -2121.12, 30.48, 86.84),
    --     ped = {
    --         enable = Config.Target and true or true, -- false the last bool to dont use ped
    --         model = "s_m_m_ammucountry"
    --     },
    --     blip = {
    --         enable = true,
    --         type = 59,
    --         scale = 0.7,
    --         color = 5,
    --     },
    --     useDrawText = true,
    --     items = {
    --         sell = {
    --             {
    --                 item = "skin_deer_ruined",
    --                 price = 250,
    --                 label = "Tattered Deer Pelt"

    --             },
    --             {
    --                 item = "skin_deer_low",
    --                 price = 500,
    --                 label = "Worn Deer Pelt"

    --             },
    --             {
    --                 item = "skin_deer_medium",
    --                 price = 700,
    --                 label = "Supple Deer Pelt"


    --             },
    --             {
    --                 item = "skin_deer_good",
    --                 price = 1200,
    --                 label = "Prime Deer Pelt"

    --             },
    --             {
    --                 item = "skin_deer_perfect",
    --                 price = 2250,
    --                 label = "Flawless Deer Pelt"


    --             },
    --         },
    --         buy = {
    --             {
    --                 item = "huntingbait",
    --                 label = "hunting Bait",
    --                 price = 250,
    --             },
    --             {
    --                 item = "campfire",
    --                 label = "Campfire",
    --                 price = 750,
    --             },
    --             {
    --                 item = "animal_tracker",
    --                 label = "Animal Tracker",
    --                 price = 10050,
    --             },
    --         }

    
