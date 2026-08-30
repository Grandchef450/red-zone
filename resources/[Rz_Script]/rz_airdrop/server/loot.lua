--[[
    rz_airdrop / server/loot.lua

    Contenu des caisses.

    DEUX RÈGLES STRUCTURANTES

    1. DIX OBJETS MAXIMUM par largage, toutes caisses confondues.
       Sans ce plafond, quatre caisses généreuses inonderaient le
       serveur d'équipement en une soirée et videraient l'arbre de
       craft de son intérêt.

    2. LES RESSOURCES NE COMPTENT PAS dans ce plafond. Elles
       alimentent le craft au lieu de le remplacer : en recevoir
       beaucoup ne déséquilibre rien.
]]

local function dbg(...)
    if Config.Debug then print('^3[rz_airdrop]^7', ...) end
end


-- ═══════════════════════════════════════════════════════════════════
--  TABLES DE BUTIN
--
--  Deux catégories bien distinctes :
--
--    RESSOURCES  matières premières et composants. Non plafonnées.
--    OBJETS      outils, équipement, soins. Comptés dans les dix.
-- ═══════════════════════════════════════════════════════════════════

local RESOURCES = {
    -- { item, min, max, chance %, paliers autorisés }
    commun = {
        { 'ferraille',          3, 8,  80 },
        { 'plastique',          3, 8,  75 },
        { 'tissu_use',          2, 6,  70 },
        { 'fil_fer',            2, 5,  65 },
        { 'carton',             2, 6,  60 },
        { 'morceau_bois',       2, 6,  60 },
        { 'caoutchouc',         2, 4,  55 },
        { 'verre',              1, 4,  50 },
        { 'ressort',            1, 4,  45 },
        { 'elastique',          1, 3,  40 },
    },
    peu_commun = {
        { 'lingot_fer',         1, 3,  55 },
        { 'lingot_aluminium',   1, 3,  50 },
        { 'plaque_fer',         1, 2,  45 },
        { 'tube_cuivre',        1, 3,  45 },
        { 'batterie_usee',      1, 2,  40 },
        { 'colle_construction', 1, 2,  35 },
        { 'ruban_adhesif',      1, 3,  40 },
        { 'poudre_noire',       1, 3,  30 },
        { 'fil_cuivre',         1, 3,  40 },
    },
    rare = {
        { 'lingot_cuivre',      1, 3,  50 },
        { 'lingot_inox',        1, 2,  35 },
        { 'plaque_aluminium',   1, 2,  40 },
        { 'cartouche_filtre',   1, 2,  35 },
        { 'poudre_diamant',     1, 1,  20 },
        { 'lingot_argent',      1, 2,  25 },
    },
    tres_rare = {
        { 'lingot_or',          1, 2,  30 },
        { 'plaque_inox',        1, 2,  25 },
        { 'plaque_kevlar',      1, 1,  20 },
        { 'poudre_diamant',     1, 3,  35 },
        { 'lingot_inox',        1, 3,  40 },
    },
}


local OBJECTS = {
    commun = {
        { 'bandage_survie',     1, 2, 60 },
        { 'bouteille_eau_sale', 1, 3, 55 },
        { 'allumettes',         1, 1, 45 },
        { 'ficelle',            1, 2, 40 },
    },
    peu_commun = {
        { 'trousse_premiers_soins', 1, 1, 45 },
        { 'attelle_survie',     1, 1, 40 },
        { 'epipen',             1, 1, 30 },
        { 'canne_peche',        1, 1, 20 },
        { 'sac_survie_24',      1, 1, 15 },
    },
    rare = {
        { 'epipen',             1, 2, 45 },
        { 'masque_simple',      1, 1, 35 },
        { 'masque_chimique',    1, 1, 25 },
        { 'sac_survie_64',      1, 1, 20 },
        { 'canne_peche_carbone',1, 1, 15 },
        { 'cle_molette',        1, 1, 25 },
    },
    tres_rare = {
        { 'masque_cartouche',   1, 1, 40 },
        { 'masque_double_cartouche', 1, 1, 25 },
        { 'sac_survie_104',     1, 1, 25 },
        { 'sac_survie_134',     1, 1, 12 },
        { 'epipen',             2, 3, 50 },
        { 'coffre_securite_24h',1, 1,  8 },
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  ARMES BLANCHES
--
--  Le filtre s'appuie sur le champ rzTier de weapons.lua : seules
--  les armes marquées « melee » peuvent sortir d'un largage. Aucune
--  arme à feu, quelle que soit la rareté de la caisse.
-- ═══════════════════════════════════════════════════════════════════

local meleeCache = nil

---Liste des armes blanches larguables, mise en cache.
local function meleeWeapons()
    if meleeCache then return meleeCache end

    meleeCache = {}

    local blocked = {}
    for _, name in ipairs(Config.Weapons.blacklist or {}) do
        blocked[name] = true
    end

    for name, data in pairs(exports.ox_inventory:Items()) do
        if data.rzTier == Config.Weapons.allowedTier and not blocked[name] then
            meleeCache[#meleeCache + 1] = name
        end
    end

    table.sort(meleeCache)

    dbg(('%d arme(s) blanche(s) larguable(s)'):format(#meleeCache))

    return meleeCache
end


---Une arme blanche au hasard, ou nil.
local function rollWeapon(tierKey)
    if not Config.Weapons.enabled then return nil end

    local chance = Config.Weapons.chance[tierKey] or 0
    if math.random(1, 100) > chance then return nil end

    local list = meleeWeapons()
    if #list == 0 then return nil end

    return list[math.random(1, #list)]
end


-- ═══════════════════════════════════════════════════════════════════
--  TIRAGE
-- ═══════════════════════════════════════════════════════════════════

---Tire dans une table, sans remise.
---@param pool table
---@param draws number
---@return table  { { item, count }, ... }
local function rollFrom(pool, draws)
    if not pool or #pool == 0 then return {} end

    local picked, out = {}, {}

    for _ = 1, draws do
        if #out >= #pool then break end

        local index, tries = nil, 0

        repeat
            index = math.random(1, #pool)
            tries = tries + 1
        until not picked[index] or tries > 20

        if not picked[index] then
            picked[index] = true

            local entry = pool[index]
            if math.random(1, 100) <= (entry[4] or 50) then
                local count = math.random(entry[2], entry[3])
                if count > 0 then
                    out[#out + 1] = { item = entry[1], count = count }
                end
            end
        end
    end

    return out
end


---Contenu d'une caisse.
---@param tierIndex number   1 à 4, rareté croissante
---@param budget number      objets encore disponibles sur les dix
---@return table contents, number used
function RollCrate(tierIndex, budget)
    local tier = Config.TierAt(tierIndex)
    local contents = {}

    -- ─── RESSOURCES : jamais plafonnées ────────────────────────
    -- Une caisse de rareté N pioche dans SA table et dans toutes
    -- celles en dessous : le butin reste varié, la progression
    -- vient de ce qui s'y ajoute.
    local pool = {}

    for i = 1, tierIndex do
        local key = Config.TierAt(i).key
        for _, entry in ipairs(RESOURCES[key] or {}) do
            pool[#pool + 1] = entry
        end
    end

    local rolls = math.random(tier.resourceRolls.min, tier.resourceRolls.max)
    for _, r in ipairs(rollFrom(pool, rolls)) do
        contents[#contents + 1] = r
    end

    -- ─── OBJETS : comptés dans le plafond global ───────────────
    local used = 0
    local allowed = math.min(tier.items, budget)

    if allowed > 0 then
        local objPool = {}

        for i = 1, tierIndex do
            local key = Config.TierAt(i).key
            for _, entry in ipairs(OBJECTS[key] or {}) do
                objPool[#objPool + 1] = entry
            end
        end

        for _, r in ipairs(rollFrom(objPool, allowed)) do
            contents[#contents + 1] = r
            used = used + 1
            if used >= allowed then break end
        end
    end

    -- ─── ARME BLANCHE ──────────────────────────────────────────
    -- Elle compte aussi dans le plafond : une arme est un objet
    -- complet, pas une ressource.
    if used < allowed or budget > used then
        local weapon = rollWeapon(tier.key)

        if weapon and (budget - used) > 0 then
            contents[#contents + 1] = { item = weapon, count = 1 }
            used = used + 1
        end
    end

    dbg(('caisse %s : %d pile(s), %d objet(s) sur le budget')
        :format(tier.key, #contents, used))

    return contents, used
end


---Contenu complet d'un largage, plafond global appliqué.
---@return table  liste de { tier, contents }
function RollDrop()
    local crates = {}
    local budget = Config.MaxItemsPerDrop

    for i = 1, Config.Drop.crates do
        -- Les caisses sont ordonnées de la plus commune à la plus
        -- rare : c'est ce qui fait durer l'événement, puisque
        -- partir dès la première c'est manquer le vrai butin.
        local tierIndex = math.min(i, #Config.Tiers)

        local contents, used = RollCrate(tierIndex, budget)
        budget = math.max(0, budget - used)

        crates[#crates + 1] = {
            tier     = tierIndex,
            contents = contents,
        }
    end

    dbg(('largage : %d caisse(s), %d objet(s) sur %d')
        :format(#crates, Config.MaxItemsPerDrop - budget, Config.MaxItemsPerDrop))

    return crates
end


---Vide le cache des armes. Utile après un restart d'ox_inventory.
exports('ClearWeaponCache', function() meleeCache = nil end)
