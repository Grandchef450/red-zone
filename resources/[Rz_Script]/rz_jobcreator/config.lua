Config = {}

-- Touche d'ouverture (modifiable in-game dans Parametres > Raccourcis)
Config.OpenKey = 'F7'

-- Logs console
Config.Debug = true

-- Si true, seul un joueur avec l'ACE "rz.jobcreator" peut creer/sauver/supprimer.
-- En dev : false. En prod : true + add_ace group.admin rz.jobcreator allow
Config.AdminOnly = false

-- Presets de sprites de blips courants (l'utilisateur peut taper n'importe quel ID)
Config.BlipSprites = {
    { id = 1,   label = "Defaut" },
    { id = 60,  label = "Garage" },
    { id = 56,  label = "Badge police" },
    { id = 61,  label = "Ambulance" },
    { id = 198, label = "Mecano" },
    { id = 478, label = "Vetements" },
    { id = 52,  label = "Coffre/Banque" },
    { id = 357, label = "Batiment" },
}

-- Presets de couleurs de blips (ID GTA)
Config.BlipColors = {
    { id = 0,  label = "Blanc" },
    { id = 1,  label = "Rouge" },
    { id = 2,  label = "Vert" },
    { id = 3,  label = "Bleu" },
    { id = 5,  label = "Jaune" },
    { id = 38, label = "Bleu fonce" },
    { id = 47, label = "Violet" },
    { id = 29, label = "Mauve police" },
}
