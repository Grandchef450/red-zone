-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
Config = {}

Config.checkForUpdates = true -- Check for updates?

Config.OneBagInInventory = true -- Allow only one bag in inventory?
-- Default/fallback backpack settings
Config.DefaultBackpack = {
    slots = 8, -- default number of slots
    weight = 10000 -- default total weight
}

-- Per-style backpack definitions (3 levels)
-- id: numeric level
-- name: display name
-- slots: number of inventory slots provided by this backpack
-- weight: total weight allowance for the stash (in whatever units your server uses)
-- capacity: custom numeric capacity convenience value (used by server logic)
-- model: prop hash used by the client to attach the prop
Config.BackpackStyles = {
    small = {
        id = 1,
        name = 'Small',
        slots = 8,
        weight = 10000,
        capacity = 20,
        model = `p_michael_backpack_s`
    },
    medium = {
        id = 2,
        name = 'Medium',
        slots = 16,
        weight = 20000,
        capacity = 40,
        model = `p_michael_backpack_s`
    },
    large = {
        id = 3,
        name = 'Large',
        slots = 32,
        weight = 40000,
        capacity = 80,
        model = `p_michael_backpack_s`
    }
}

-- PIN rules for backpacks
Config.Pin = {
    min = 4, -- minimum number of digits
    max = 10, -- maximum number of digits
    required = false -- whether a PIN is required when creating a backpack
}

Strings = { -- Notification strings
    action_incomplete = 'Action Incomplete',
    one_backpack_only = 'You can only have 1x backpack!',
    backpack_in_backpack = 'You can\'t place a backpack within another!',
    pin_invalid = 'Le PIN doit contenir uniquement des chiffres (4-10 caractères)',
    pin_incorrect = 'Code PIN incorrect',
    backpack_created = 'Backpack créé avec succès'
}
