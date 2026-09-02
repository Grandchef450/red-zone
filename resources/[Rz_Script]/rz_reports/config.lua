Config = {}

-- Touche d'ouverture du panneau (joueur ET staff)
Config.OpenKey = 'F10'

Config.Debug = true

-- ACE qui donne l'acces staff (voir/traiter les reports)
--
-- Droit dédié, plutôt que rz.staff : rz.staff est réutilisé par une
-- dizaine d'autres vérifications sans rapport (rz_epaves, rz_spawn,
-- etc.), donc pas question que rz_perms le manipule pour n'activer
-- ou désactiver QUE ce bouton-ci. rz_perms l'accorde par grade
-- (onglet Équipe → Permissions du menu) et le réapplique à chaque
-- démarrage — voir rz_perms/rz_grade_tools.sql.
Config.StaffAce = 'rz.reports.view'

-- Categories proposees au joueur
Config.Categories = { 'Bug', 'Joueur', 'Question', 'Autre' }

-- Necessite OneSync active pour le "TP au joueur" (GetEntityCoords serveur)
