Config = {}

-- Touche/commande d'ouverture du panneau admin (aussi lançable depuis vgc_admintablet)
Config.OpenKey = 'F11'

Config.Debug = true

-- =========================================================
--  PERMISSIONS (memes cles CFX que vgc_admintablet)
--  1) Le serveur lit automatiquement admins.json de la
--     ressource vgc_admintablet (si demarree) → tous tes
--     admins de la tablette F3 ont acces au jail.
--  2) ExtraAllowed : identifiants supplementaires — mets-y
--     tes FONDATEURS (ils ne sont pas dans admins.json).
-- =========================================================
Config.AdminTabletResource = 'vgc_admintablet'
Config.ExtraAllowed = {
    'license:REMPLACE_MOI_PAR_TON_LICENSE', -- fondateur
}

-- =========================================================
--  DUREE
-- =========================================================
Config.MaxSeconds     = 300   -- 5 minutes MAXIMUM (borne dure, revalidee serveur)
Config.DefaultSeconds = 120

-- =========================================================
--  POINT DE SORTIE — la ou TOUT LE MONDE arrive en ville.
--  Le joueur libere est TP ici (et pas a sa position d'origine).
-- =========================================================
Config.ReleasePoint = { x = -278.8850, y = -964.4562, z = 31.2597, heading = 87.4857 }

-- =========================================================
--  LIEUX DE PRISON PREDEFINIS
--  L'admin peut aussi choisir "Ma position actuelle" ou taper
--  des coordonnees custom directement dans l'UI.
-- =========================================================
Config.JailLocations = {
    { label = 'Cellule Mission Row',     x = 459.51,   y = -998.90,  z = 24.91,  heading = 90.0  },
    { label = 'Prison de Bolingbroke',   x = 1680.02,  y = 2513.71,  z = 45.56,  heading = 120.0 },
    { label = 'Toit Maze Bank',          x = -75.44,   y = -818.87,  z = 326.17, heading = 0.0   },
    { label = 'Mont Chiliad (sommet)',   x = 501.77,   y = 5604.85,  z = 797.91, heading = 0.0   },
    { label = 'Île déserte (au large)',  x = 4959.9,   y = -5175.5,  z = 2.5,    heading = 0.0   },
}

-- =========================================================
--  MUSIQUE
--  URL DIRECTE vers un fichier audio (.mp3 / .ogg) — les liens
--  YouTube/Spotify ne fonctionnent PAS dans une NUI.
--  Heberge tes mp3 sur ton serveur web / Discord CDN / etc.
-- =========================================================
Config.MusicPresets = {
    { label = 'Aucune musique', url = '' },
    -- Exemples a remplacer par tes propres liens :
    -- { label = 'Baby Shark (boucle)', url = 'https://tonserveur.com/musiques/babyshark.mp3' },
    -- { label = 'Ascenseur',           url = 'https://tonserveur.com/musiques/elevator.mp3' },
}
Config.DefaultVolume = 0.6   -- 0.0 → 1.0

-- =========================================================
--  LAISSE (anti-fuite)
--  Si le joueur s'eloigne de plus de LeashRadius metres du
--  point de prison, il y est re-teleporte.
-- =========================================================
Config.LeashEnabled = true
Config.LeashRadius  = 25.0

-- Fichier de persistance : un joueur qui se deconnecte pour
-- echapper au jail reprend sa peine a la reconnexion.
Config.JailsFile = 'jails.json'
