Config = {}

-- Touche d'ouverture du panneau (joueur ET staff)
Config.OpenKey = 'F10'

Config.Debug = true

-- ACE qui donne l'acces staff (voir/traiter les reports)
-- En prod : add_ace group.admin vgc.staff allow
Config.StaffAce = 'vgc.staff'

-- Categories proposees au joueur
Config.Categories = { 'Bug', 'Joueur', 'Question', 'Autre' }

-- Necessite OneSync active pour le "TP au joueur" (GetEntityCoords serveur)
