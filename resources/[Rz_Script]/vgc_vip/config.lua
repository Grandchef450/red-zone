Config = {}

-- Touche/commande d'ouverture de la tablette VIP (tout le monde peut
-- l'ouvrir pour VOIR la boutique ; les avantages sont verrouilles par grade)
Config.OpenKey = 'F4'

Config.Debug = true

-- Compte utilise pour l'achat des grades VIP ('bank' ou 'cash')
Config.PayAccount = 'bank'

-- true : upgrader vers un grade superieur coute la DIFFERENCE de prix.
-- false : plein tarif a chaque grade.
Config.UpgradePayDifference = true

-- Event de reanimation de ton ambulancejob
Config.ReviveEvent = 'hospital:client:Revive'

-- Coordonnees de l'hopital (pour l'achat "Reanimation a l'hopital immediate")
Config.Hospital = { x = 310.02, y = -592.15, z = 43.28, heading = 70.0 }

-- Fichier de persistance (dossier de la ressource, pas de DB)
Config.VipFile = 'vip.json'

-- =========================================================
--  LES 7 GRADES VIP — MODIFIE LES PRIX ICI ($ en banque)
--  freeReviveHours : reanimation gratuite instantanee toutes les X h (grades 1-3)
--  craft = { max, lockHours }  : stock max de kits ; une fois les `max`
--            utilises, crafting bloque pendant lockHours (grades 4-6)
--  craft = { quota, windowHours } : grade 7 — peut crafter jusqu'a
--            `quota` kits par fenetre de windowHours
--  pedSlots : nombre de peds que le joueur peut choisir
--  img : URL https d'une image de fond de carte (optionnel, sinon degrade)
-- =========================================================
Config.Tiers = {
    { id = 1, label = 'VIP Classique',  price = 50000,
      color1 = '#64748b', color2 = '#94a3b8', emoji = '⭐',
      pedSlots = 0, freeReviveHours = 12,
      tagline = 'L\'essentiel pour commencer' },

    { id = 2, label = 'VIP Familiale',  price = 100000,
      color1 = '#0ea5e9', color2 = '#38bdf8', emoji = '💙',
      pedSlots = 1, freeReviveHours = 6,
      tagline = 'Ton premier ped exclusif' },

    { id = 3, label = 'VIP Gold',       price = 200000,
      color1 = '#ca8a04', color2 = '#fbbf24', emoji = '🏆',
      pedSlots = 2, freeReviveHours = 3, badge = 'POPULAIRE',
      tagline = 'Le choix des habitués' },

    { id = 4, label = 'VIP Diamant',    price = 350000,
      color1 = '#0891b2', color2 = '#67e8f9', emoji = '💎',
      pedSlots = 3, craft = { max = 3, lockHours = 12 },
      tagline = 'Craft tes réanimations' },

    { id = 5, label = 'VIP Prestige',   price = 500000,
      color1 = '#7c3aed', color2 = '#c084fc', emoji = '👑',
      pedSlots = 3, craft = { max = 3, lockHours = 6 },
      tagline = 'Moins d\'attente, plus de jeu' },

    { id = 6, label = 'VIP Ultimate',   price = 750000,
      color1 = '#dc2626', color2 = '#fb7185', emoji = '🔥',
      pedSlots = 3, craft = { max = 3, lockHours = 3 }, badge = 'MEILLEURE VALEUR',
      tagline = 'La puissance sans compromis' },

    { id = 7, label = 'VIP Infinie',    price = 1000000,
      color1 = '#0f172a', color2 = '#818cf8', emoji = '♾️',
      pedSlots = 3, craft = { quota = 5, windowHours = 12 },
      tagline = '5 réanimations par 12 h. Point.' },
}

-- =========================================================
--  CATALOGUE DE PEDS
--  price = 0 : inclus avec un slot du grade
--  price > 0 : ped premium, paye en $ EN PLUS du slot
--  Ajoute autant de peds que tu veux (modeles GTA/addon)
-- =========================================================
Config.Peds = {
    { model = 'a_m_y_hipster_01',      label = 'Hipster',            price = 0, emoji = '🧔' },
    { model = 'a_m_y_business_01',     label = 'Homme d\'affaires',  price = 0, emoji = '💼' },
    { model = 'a_f_y_business_02',     label = 'Femme d\'affaires',  price = 0, emoji = '👩‍💼' },
    { model = 'g_m_y_ballaeast_01',    label = 'Balla',              price = 0, emoji = '🟣' },
    { model = 's_m_y_xmech_02',        label = 'Mécano',             price = 0, emoji = '🔧' },
    { model = 'a_m_y_beach_01',        label = 'Beach boy',          price = 0, emoji = '🏖️' },
    { model = 'ig_bankman',            label = 'Banquier',           price = 25000, emoji = '🏦' },
    { model = 'u_m_y_juggernaut_01',   label = 'Juggernaut',         price = 50000, emoji = '🦾' },
    { model = 'a_c_husky',             label = 'Husky',              price = 75000, emoji = '🐕' },
}

-- Comment restaurer le ped d'origine (bouton "Ped d'origine" du vestiaire).
-- Si tu utilises illenium-appearance, laisse tel quel.
Config.ReloadSkin = { resource = 'illenium-appearance', event = 'illenium-appearance:client:reloadSkin' }

-- =========================================================
--  MATERIAUX (items QBCore — doivent exister dans qb-core/shared/items.lua)
-- =========================================================
Config.Materials = {
    { item = 'metalscrap', label = 'Métal',      emoji = '🔩' },
    { item = 'plastic',    label = 'Plastique',  emoji = '🧴' },
    { item = 'steel',      label = 'Acier',      emoji = '⚙️' },
    { item = 'copper',     label = 'Cuivre',     emoji = '🟠' },
}

-- Cout en materiaux pour CRAFTER un kit de reanimation (grades 4-7)
Config.ReviveKitCost = { metalscrap = 5, plastic = 5, steel = 3, copper = 2 }

-- =========================================================
--  POINTS DE FARM EN VILLE
--  duration en ms ; min/max = quantite recue
-- =========================================================
Config.FarmSpots = {
    { label = 'Casse (métal)',      material = 'metalscrap', x = -449.51, y = -1693.36, z = 18.75, min = 1, max = 3, duration = 6000 },
    { label = 'Décharge (plastique)', material = 'plastic',  x = -348.43, y = -1569.42, z = 25.23, min = 1, max = 3, duration = 6000 },
    { label = 'Chantier (acier)',   material = 'steel',      x = -141.86, y = -947.30,  z = 29.09, min = 1, max = 2, duration = 8000 },
    { label = 'Entrepôt (cuivre)',  material = 'copper',     x = 894.85,  y = -2110.13, z = 30.55, min = 1, max = 2, duration = 8000 },
}
Config.FarmMarker = { r = 76, g = 141, b = 255, a = 120 }
Config.FarmCooldown = 5 -- secondes entre deux recoltes (anti-macro, verifie serveur)

-- =========================================================
--  BOUTIQUE MATERIAUX — MODIFIE LES COUTS ICI
--  give.type : 'item' (QBCore item/arme) ou 'revive_hospital'
--  cost : { itemMateriau = quantite }
--  Calibres : plus le calibre est gros, plus c'est cher.
-- =========================================================
Config.MaterialShop = {
    -- ── Soins ──
    { id = 'revive_hosp', label = 'Réanimation hôpital immédiate', emoji = '🏥', cat = 'Soins',
      give = { type = 'revive_hospital' },
      cost = { metalscrap = 8, plastic = 8, steel = 5, copper = 4 } },
    { id = 'bandage', label = 'Bandages (x5)', emoji = '🩹', cat = 'Soins',
      give = { type = 'item', name = 'bandage', amount = 5 },
      cost = { plastic = 3, metalscrap = 1 } },

    -- ── Kits ──
    { id = 'kit_arme', label = 'Kit de réparation d\'arme', emoji = '🔫', cat = 'Kits',
      give = { type = 'item', name = 'weapon_repairkit', amount = 1 },
      cost = { metalscrap = 6, steel = 4, copper = 2 } },
    { id = 'kit_veh', label = 'Kit de réparation véhicule', emoji = '🚗', cat = 'Kits',
      give = { type = 'item', name = 'repairkit', amount = 1 },
      cost = { metalscrap = 5, steel = 3, plastic = 2 } },

    -- ── Munitions (cout croissant avec le calibre) ──
    { id = 'ammo_pistol', label = 'Balles 9mm (x30)', emoji = '•', cat = 'Munitions',
      give = { type = 'item', name = 'pistol_ammo', amount = 30 },
      cost = { metalscrap = 2, copper = 1 } },
    { id = 'ammo_smg', label = 'Balles SMG (x30)', emoji = '••', cat = 'Munitions',
      give = { type = 'item', name = 'smg_ammo', amount = 30 },
      cost = { metalscrap = 3, copper = 2 } },
    { id = 'ammo_shotgun', label = 'Cartouches calibre 12 (x20)', emoji = '🔴', cat = 'Munitions',
      give = { type = 'item', name = 'shotgun_ammo', amount = 20 },
      cost = { metalscrap = 4, steel = 2, copper = 2 } },
    { id = 'ammo_rifle', label = 'Balles 5.56 (x30)', emoji = '▮', cat = 'Munitions',
      give = { type = 'item', name = 'rifle_ammo', amount = 30 },
      cost = { metalscrap = 5, steel = 3, copper = 3 } },
    { id = 'ammo_sniper', label = 'Balles sniper (x10)', emoji = '▯', cat = 'Munitions',
      give = { type = 'item', name = 'sniper_ammo', amount = 10 },
      cost = { metalscrap = 7, steel = 5, copper = 4 } },

    -- ── Armes (cout croissant avec le calibre) ──
    { id = 'w_pistol', label = 'Pistolet', emoji = '🔫', cat = 'Armes',
      give = { type = 'item', name = 'weapon_pistol', amount = 1 },
      cost = { metalscrap = 10, steel = 6, plastic = 4, copper = 3 } },
    { id = 'w_smg', label = 'SMG', emoji = '🔫', cat = 'Armes',
      give = { type = 'item', name = 'weapon_smg', amount = 1 },
      cost = { metalscrap = 16, steel = 10, plastic = 6, copper = 5 } },
    { id = 'w_shotgun', label = 'Fusil à pompe', emoji = '🔫', cat = 'Armes',
      give = { type = 'item', name = 'weapon_pumpshotgun', amount = 1 },
      cost = { metalscrap = 20, steel = 14, plastic = 6, copper = 6 } },
    { id = 'w_rifle', label = 'Carabine d\'assaut', emoji = '🔫', cat = 'Armes',
      give = { type = 'item', name = 'weapon_carbinerifle', amount = 1 },
      cost = { metalscrap = 28, steel = 20, plastic = 10, copper = 10 } },
}
