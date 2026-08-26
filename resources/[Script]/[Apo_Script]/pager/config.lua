Config = {}
Config.MaxFrequency = 999
Config.MinFrequency = 100
Config.MaxNicknameLength = 15
Config.MinNicknameLength = 3
Config.MaxMessageLength = 50 -- Maksimum mesaj uzunluğu

Config.NotificationDuration = 3000 -- ms
Config.PagerBottomOffset = 20 -- px

-- Framework Configuration
Config.Framework = "qbcore" -- Options: "standalone", "esx", "qbcore"

-- Item Configuration
Config.RequireItem = true -- Set to false if you don't want to require an item to use the pager
Config.ItemName = "pepper" -- The name of the item in the database

-- Animation Configuration
Config.PhoneModel = "prop_npc_phone_02" -- Phone prop model to use
Config.AnimDict = "cellphone@" -- Animation dictionary
Config.AnimName = "cellphone_text_read_base" -- Animation name

-- Localization
Config.Locale = {
    ["no_pager"] = "Aucun pager détecté.",
    ["message_too_long"] = "ERREUR : MESSAGE TROP LONG. LIMITE : %d CARACTÈRES.",
    ["set_nickname_first"] = "ERREUR : VEUILLEZ DÉFINIR UN PSEUDO AVANT. COMMANDE : /NICK <NOM>",
    ["set_frequency_first"] = "ERREUR : VEUILLEZ DÉFINIR UNE FRÉQUENCE AVANT. COMMANDE : /FREQ <100-999>",
    ["frequency_set"] = "FRÉQUENCE CONFIGURÉE SUR : %d",
    ["nickname_set"] = "PSEUDO CONFIGURÉ SUR : %s",
    ["nickname_length"] = "LE PSEUDO DOIT CONTENIR ENTRE %d ET %d CARACTÈRES.",
    ["nickname_set_chat"] = "Pseudo configuré : %s",
    ["invalid_frequency"] = "FRÉQUENCE NON VALIDE. VALEURS AUTORISÉES : %d-%d"

}

-- UI Localization
Config.UI = {
    ["title"] = "PAGER v1.0",
    ["placeholder_message"] = "Saisir un message...",
    ["placeholder_freq"] = "Saisir une fréquence (100-999)",
    ["placeholder_nick"] = "Saisir un pseudo",
    ["button_send"] = "ENVOYER",
    ["button_freq"] = "DÉFINIR FRÉQUENCE",
    ["button_nick"] = "DÉFINIR PSEUDO",
    ["close"] = "FERMER"

}