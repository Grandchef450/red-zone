Config = {}

Config.Debug = false

-- ═══════════════════════════════════════════════════════════════════
--  PERMISSION
--
--  Un seul droit : ce menu ne fait qu'une chose (inspecter un
--  inventaire), pas de niveau intermédiaire à distinguer.
--
--  ⚠️  Ce n'est pas une simple consultation. Ouvrir l'inventaire d'un
--  joueur EN LIGNE ouvre la même vue à deux panneaux que looter un
--  corps : tu peux y déposer ou en retirer des objets. À réserver à
--  ceux en qui tu as confiance pour ça — réglable grade par grade
--  depuis F5 → Équipe → Permissions du menu.
-- ═══════════════════════════════════════════════════════════════════
Config.Ace = 'rz.invcheck'

function Config.HasAce(source)
    return IsPlayerAceAllowed(source, Config.Ace)
end

--[[
    server.cfg :
        add_ace group.developpeur rz.invcheck allow

    Admin / Modérateur / Support : gérés depuis le panneau du
    fondateur (F5 → Équipe → Permissions du menu), pas ici.
]]


-- ═══════════════════════════════════════════════════════════════════
--  RECHERCHE
-- ═══════════════════════════════════════════════════════════════════

-- Nombre maximum de résultats affichés pour une recherche par nom.
-- Au-delà, demande d'affiner : une liste de cinquante joueurs n'aide
-- personne à trouver le bon.
Config.MaxResults = 20
