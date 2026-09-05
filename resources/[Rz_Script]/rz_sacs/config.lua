Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  USURE DES SACS À DOS
--
--  Un sac s'use UNIQUEMENT à l'ouverture. Ni le temps qui passe, ni
--  le fait de le porter, ni ce qu'on met dedans ne l'abîment.
--
--  BASE DE CALCUL — un joueur assidu :
--      5 h de jeu par jour × 20 ouvertures par heure = 100 / jour
--
--  La colonne `opens` ci-dessous est donc directement lisible en
--  jours : 300 ouvertures = 3 jours d'un joueur qui joue beaucoup.
--
--  La progression n'est PAS linéaire, et c'est volontaire : le 200P
--  dure 23 fois plus longtemps que le 12P alors qu'il ne contient
--  que 16 fois plus. Sans cela, un joueur calculerait qu'il vaut
--  mieux enchaîner les petits sacs, et le craft de phase 5 ne
--  servirait à rien.
-- ═══════════════════════════════════════════════════════════════════
Config.Bags = {
    --  item                slots  ouvertures   ≈ jours
    sac_survie_12  = { slots = 12,  opens = 300  },  --  3
    sac_cafe_20    = { slots = 20,  opens = 400  },  --  4
    sac_survie_24  = { slots = 24,  opens = 500  },  --  5
    sac_survie_32  = { slots = 32,  opens = 800  },  --  8
    boite_medical_20 = { slots = 20, opens = 600 },  --  6  (boîte médicale, rz_soins)
    sac_medical_50 = { slots = 50,  opens = 1000 },  -- 10
    sac_survie_64  = { slots = 64,  opens = 1200 },  -- 12
    sac_survie_72  = { slots = 72,  opens = 1800 },  -- 18
    sac_survie_104 = { slots = 104, opens = 2500 },  -- 25
    sac_survie_134 = { slots = 134, opens = 3500 },  -- 35
    sac_survie_158 = { slots = 158, opens = 4500 },  -- 45
    sac_survie_172 = { slots = 172, opens = 5500 },  -- 55
    sac_survie_200 = { slots = 200, opens = 7000 },  -- 70
}


-- ═══════════════════════════════════════════════════════════════════
--  COMPORTEMENT
-- ═══════════════════════════════════════════════════════════════════
Config.Wear = {
    -- Délai minimum entre deux usures, en secondes. Empêche qu'un
    -- double-clic ou une fermeture accidentelle compte deux fois.
    -- Ne protège PAS contre le spam volontaire : ouvrir cent fois
    -- son sac doit bel et bien l'user cent fois.
    cooldown = 2,

    -- Seuils d'avertissement, en pourcentage
    warnAt        = 25,
    criticalAt    = 10,

    -- Ce qui arrive à 0 %
    --   'tear'  : le sac se déchire, son contenu tombe aux pieds du
    --             joueur dans un sac au sol. Le sac est détruit.
    --   'lock'  : le sac devient inouvrable jusqu'à réparation.
    --             ⚠️ Piège le contenu à l'intérieur.
    onBroken = 'tear',
}


-- ═══════════════════════════════════════════════════════════════════
--  RÉPARATION
--
--  Un sac se répare avant d'atteindre 0 %. Les matériaux sont ceux
--  que le joueur farme déjà — pas besoin d'un item dédié.
--
--  La réparation ne remet PAS à 100 % : chaque passage laisse des
--  traces. Un sac réparé trois fois plafonne à 70 %, ce qui pousse
--  à en crafter un neuf plutôt qu'à recoudre indéfiniment.
-- ═══════════════════════════════════════════════════════════════════
Config.Repair = {
    enabled = true,

    -- Coût en matériaux, proportionnel aux slots du sac.
    -- Quantité = math.ceil(slots / divisor), minimum 1.
    materials = {
        { item = 'tissu_use',        divisor = 16 },
        { item = 'ficelle',          divisor = 24 },
        { item = 'aiguille_crochet', divisor = 64 },
    },

    -- Plafond de durabilité perdu à chaque réparation
    capLossPerRepair = 10,

    -- En dessous de ce plafond, le sac n'est plus réparable
    minCap = 40,

    -- Restaure jusqu'au plafond en vigueur
    restoreToCap = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Ce sac est-il géré par le système d'usure ?
---@param itemName string
---@return table|nil
function Config.GetBag(itemName)
    return itemName and Config.Bags[itemName] or nil
end

---Perte de durabilité par ouverture, en points de pourcentage.
---@param itemName string
---@return number
function Config.GetWearPerOpen(itemName)
    local bag = Config.GetBag(itemName)
    if not bag or bag.opens <= 0 then return 0 end
    return 100 / bag.opens
end
