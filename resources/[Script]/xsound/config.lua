config = {}

-- How much ofter the player position is updated ?
config.RefreshTime = 300

-- default sound format for interact
config.interact_sound_file = "ogg"

-- is emulator enabled ?
config.interact_sound_enable = false

-- how much close player has to be to the sound before starting updating position ?
config.distanceBeforeUpdatingPos = 40

-- Message list
config.Messages = {
    ["streamer_on"]  = "Mode streamer activé. Vous n'entendrez plus aucune musique/son.",
    ["streamer_off"] = "Mode streamer désactivé. Vous entendrez à nouveau la musique jouée par les autres joueurs.",

    ["no_permission"] = "Vous n'avez pas la permission d'utiliser cette commande !",
}

-- Addon list
-- True/False enabled/disabled
config.AddonList = {
    crewPhone = false,
}