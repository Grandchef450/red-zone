Config = {}

-- Affiche les traces dans la console serveur/client
Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  DURÉE DE CRAFT
--
--  Courbe en S : lente au départ, accélère au milieu, s'approche du
--  plafond sans jamais l'atteindre. Fonctionne pour des niveaux
--  illimités — tu peux ajouter des recettes de niveau 500 sans
--  jamais dépasser les 5 minutes.
--
--  durée = min + (max - min) × niv^power / (niv^power + halfway^power)
-- ═══════════════════════════════════════════════════════════════════
Config.CraftTime = {
    min     = 5000,     -- ms — durée au niveau 0
    max     = 300000,   -- ms — plafond asymptotique (5 min)
    halfway = 80,       -- niveau où la durée vaut la moitié (2 min 30)
    power   = 2,        -- raideur : 1 = doux, 2 = équilibré, 3 = brutal
}

---Durée d'un craft unitaire pour un niveau de recette donné.
---@param level number
---@return number ms
function Config.GetCraftTime(level)
    if level <= 0 then return Config.CraftTime.min end

    local p  = Config.CraftTime.power
    local nv = level ^ p
    local hw = Config.CraftTime.halfway ^ p

    return math.floor(
        Config.CraftTime.min
        + (Config.CraftTime.max - Config.CraftTime.min) * (nv / (nv + hw))
    )
end


-- ═══════════════════════════════════════════════════════════════════
--  CRAFT EN LOT
-- ═══════════════════════════════════════════════════════════════════
Config.Batch = {
    free      = 5,      -- quantité craftable sans frais supplémentaires
    max       = 20,     -- plafond absolu par cycle (anti-abus serveur)
    timeStep  = 0.15,   -- +15 % de durée par item au-delà du 1er
    surcharge = 1.0,    -- multiplicateur du prix capsules au-delà du 5e
}

---Durée totale d'un lot.
---@param level number
---@param quantity number
---@return number ms
function Config.GetBatchTime(level, quantity)
    local unit = Config.GetCraftTime(level)
    return math.floor(unit * (1 + Config.Batch.timeStep * (quantity - 1)))
end


-- ═══════════════════════════════════════════════════════════════════
--  CAPSULES
--
--  Les capsules ne remplacent pas le farming : elles comblent ce qui
--  manque. Le multiplicateur garantit que payer coûte TOUJOURS plus
--  cher que ramasser. Ne descends jamais sous 1.5.
-- ═══════════════════════════════════════════════════════════════════
Config.Capsules = {
    item       = 'capsule',
    multiplier = 2.5,   -- coût = manquant × valeur_item × multiplier
}


-- ═══════════════════════════════════════════════════════════════════
--  ZONE DE CRAFT
--
--  Le joueur doit rester près de l'établi. La tolérance et le délai
--  de grâce absorbent les bousculades et les décalages d'animation
--  sans permettre de s'éloigner pour de bon.
-- ═══════════════════════════════════════════════════════════════════
Config.CraftZone = {
    radius        = 2.0,    -- rayon officiel annoncé au joueur
    tolerance     = 3.0,    -- distance au-delà de laquelle le compte à rebours démarre
    graceSeconds  = 5,      -- secondes hors zone avant annulation
    checkInterval = 1000,   -- ms entre deux vérifications serveur
}


-- ═══════════════════════════════════════════════════════════════════
--  PROGRESSION
-- ═══════════════════════════════════════════════════════════════════
Config.Categories = {
    'cuisine',
    'metallurgie',
    'munitions',
    'equipement',
    'medical',
}

Config.Progression = {
    -- XP nécessaire pour passer du niveau N au niveau N+1
    -- base × (niveau + 1) ^ curve
    base  = 100,
    curve = 1.4,
}

---XP totale requise pour atteindre un niveau.
---@param level number
---@return number
function Config.GetXpForLevel(level)
    if level <= 0 then return 0 end
    local total = 0
    for i = 0, level - 1 do
        total = total + math.floor(Config.Progression.base * ((i + 1) ^ Config.Progression.curve))
    end
    return total
end

---Niveau atteint avec une XP donnée.
---@param xp number
---@return number level
function Config.GetLevelFromXp(xp)
    local level = 0
    while xp >= Config.GetXpForLevel(level + 1) do
        level = level + 1
        if level > 9999 then break end -- garde-fou
    end
    return level
end


-- ═══════════════════════════════════════════════════════════════════
--  BOÎTE AUX LETTRES
-- ═══════════════════════════════════════════════════════════════════
Config.Mailbox = {
    -- Un colis ne contient jamais de matériaux : ceux-ci restent
    -- dans l'inventaire pendant tout le craft. Seules les capsules
    -- déjà prélevées sont remboursées.
    maxParcelsShown = 50,
    pedModel        = 'a_m_m_hillbilly_01',
    scenario        = 'WORLD_HUMAN_CLIPBOARD',
}


-- ═══════════════════════════════════════════════════════════════════
--  PERMISSIONS ADMIN
--
--  À déclarer dans ton server.cfg :
--    add_ace group.admin rz_craft.admin allow
--    add_principal identifier.license:xxxxx group.admin
-- ═══════════════════════════════════════════════════════════════════
Config.AdminAce = 'rz_craft.admin'
