-- ═══════════════════════════════════════════════════════════════════
--  REDZONE SURVIVAL — Schéma du système de craft et de troc
--
--  À importer dans ta base `grandchef` (phpMyAdmin > Importer,
--  ou via HeidiSQL / la console txAdmin).
--
--  Principe : tout est chargé EN MÉMOIRE au démarrage de la ressource.
--  La base ne sert qu'à la persistance et à l'édition admin.
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
--  1. LES TABLES DE CRAFT (points physiques dans le monde)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_tables` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label`          VARCHAR(64)  NOT NULL,           -- « Établi de Sandy Shores »
    `tier`           TINYINT      NOT NULL DEFAULT 1, -- 1 = base (toutes safe zones), 2+ = avancé

    -- Position
    `x`              FLOAT        NOT NULL,
    `y`              FLOAT        NOT NULL,
    `z`              FLOAT        NOT NULL,
    `heading`        FLOAT        NOT NULL DEFAULT 0.0,

    -- Apparence : NULL = pas de prop spawné (on utilise un objet déjà sur la map)
    `prop_model`     VARCHAR(64)  DEFAULT NULL,       -- ex. 'prop_toolchest_01'

    -- Blip sur la carte : NULL = table cachée, à découvrir
    `blip_sprite`    SMALLINT     DEFAULT NULL,
    `blip_color`     TINYINT      DEFAULT NULL,

    -- Sécurité : une table en safe zone n'est pas attaquable
    `in_safezone`    TINYINT(1)   NOT NULL DEFAULT 1,
    `safezone_id`    VARCHAR(32)  DEFAULT NULL,       -- doit matcher l'ID dans zombies/config_server.lua

    `created_by`     VARCHAR(64)  DEFAULT NULL,       -- identifiant de l'admin créateur
    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_tier` (`tier`),
    KEY `idx_safezone` (`safezone_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  2. LES RECETTES
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_recipes` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Ce que la recette produit
    `output_item`    VARCHAR(64)  NOT NULL,           -- ex. 'couteau_survie'
    `output_qty`     INT          NOT NULL DEFAULT 1,

    -- Progression
    `category`       VARCHAR(32)  NOT NULL,           -- 'cuisine','metallurgie','munitions','equipement','medical'
    `required_level` INT          NOT NULL DEFAULT 0, -- niveau minimum DANS cette catégorie
    `xp_gain`        INT          NOT NULL DEFAULT 10,-- XP gagnée à chaque craft réussi

    `craft_time`     INT          NOT NULL DEFAULT 5000, -- durée en ms (barre de progression)
    `enabled`        TINYINT(1)   NOT NULL DEFAULT 1,

    PRIMARY KEY (`id`),
    KEY `idx_category_level` (`category`, `required_level`),
    KEY `idx_output` (`output_item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  3. LES INGRÉDIENTS
--
--  Une ligne par ingrédient, PAS un blob JSON. C'est volontaire :
--  avec 212 items tu voudras constamment savoir « qu'est-ce qui
--  consomme de la ferraille ? » pour équilibrer. Avec du JSON,
--  cette question est impossible à poser en SQL.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_ingredients` (
    `recipe_id`      INT UNSIGNED NOT NULL,
    `item`           VARCHAR(64)  NOT NULL,
    `qty`            INT          NOT NULL DEFAULT 1,

    PRIMARY KEY (`recipe_id`, `item`),
    KEY `idx_item` (`item`),
    CONSTRAINT `fk_ing_recipe` FOREIGN KEY (`recipe_id`)
        REFERENCES `rz_craft_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  4. QUELLE RECETTE SUR QUELLE TABLE
--
--  C'est ici que se joue ta mécanique : la même recette peut être
--  sur toutes les tables de base, ou sur une seule table planquée
--  en pleine zone infestée.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_table_recipes` (
    `table_id`       INT UNSIGNED NOT NULL,
    `recipe_id`      INT UNSIGNED NOT NULL,

    PRIMARY KEY (`table_id`, `recipe_id`),
    CONSTRAINT `fk_tr_table`  FOREIGN KEY (`table_id`)
        REFERENCES `rz_craft_tables`(`id`)  ON DELETE CASCADE,
    CONSTRAINT `fk_tr_recipe` FOREIGN KEY (`recipe_id`)
        REFERENCES `rz_craft_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  5. LES PEDS TROQUEURS
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_traders` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label`          VARCHAR(64)  NOT NULL,           -- « Marchand de Sandy »
    `ped_model`      VARCHAR(64)  NOT NULL DEFAULT 'a_m_m_hillbilly_01',

    `x`              FLOAT        NOT NULL,
    `y`              FLOAT        NOT NULL,
    `z`              FLOAT        NOT NULL,
    `heading`        FLOAT        NOT NULL DEFAULT 0.0,

    `scenario`       VARCHAR(64)  DEFAULT NULL,       -- ex. 'WORLD_HUMAN_AA_COFFEE'
    `blip_sprite`    SMALLINT     DEFAULT NULL,
    `blip_color`     TINYINT      DEFAULT NULL,

    -- Lien optionnel vers une table de craft : sert à les placer ensemble
    `craft_table_id` INT UNSIGNED DEFAULT NULL,

    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    CONSTRAINT `fk_trader_table` FOREIGN KEY (`craft_table_id`)
        REFERENCES `rz_craft_tables`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  6. LES OFFRES DES PEDS
--
--  Trois modes couverts par la même table :
--   • VENTE   : le ped donne give_item contre price_capsules
--   • ACHAT   : le ped prend want_item et donne price_capsules
--   • TROC    : le ped échange want_item contre give_item (0 capsule)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_trader_offers` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `trader_id`      INT UNSIGNED NOT NULL,
    `offer_type`     ENUM('vente','achat','troc') NOT NULL DEFAULT 'vente',

    `give_item`      VARCHAR(64)  DEFAULT NULL,       -- ce que le joueur REÇOIT
    `give_qty`       INT          NOT NULL DEFAULT 1,

    `want_item`      VARCHAR(64)  DEFAULT NULL,       -- ce que le joueur DONNE
    `want_qty`       INT          NOT NULL DEFAULT 1,

    `price_capsules` INT          NOT NULL DEFAULT 0,

    -- Stock : -1 = illimité. Sinon décrémenté à chaque achat.
    `stock`          INT          NOT NULL DEFAULT -1,
    `stock_max`      INT          NOT NULL DEFAULT -1,
    `restock_hours`  INT          NOT NULL DEFAULT 24,
    `last_restock`   TIMESTAMP    NULL DEFAULT NULL,

    `required_level` INT          NOT NULL DEFAULT 0,
    `enabled`        TINYINT(1)   NOT NULL DEFAULT 1,

    PRIMARY KEY (`id`),
    KEY `idx_trader` (`trader_id`),
    CONSTRAINT `fk_offer_trader` FOREIGN KEY (`trader_id`)
        REFERENCES `rz_traders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  7. LA PROGRESSION DES JOUEURS
--
--  Une ligne par joueur ET par catégorie. Un boucher hors pair
--  peut être nul en munitions — c'est ce qui pousse au commerce
--  entre joueurs, et donc à faire vivre les peds troqueurs.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_player_crafting` (
    `charid`         INT UNSIGNED NOT NULL,           -- ox_core : characters.charId
    `category`       VARCHAR(32)  NOT NULL,
    `level`          INT          NOT NULL DEFAULT 0,
    `xp`             INT          NOT NULL DEFAULT 0,
    `total_crafted`  INT          NOT NULL DEFAULT 0,

    PRIMARY KEY (`charid`, `category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  8. JOURNAL D'AUDIT
--
--  Indispensable dès qu'il y a de l'argent réel dans la boucle.
--  Le jour où un joueur affirme avoir perdu son stuff, tu sauras.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_logs` (
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `charid`         INT UNSIGNED NOT NULL,
    `action`         VARCHAR(32)  NOT NULL,           -- 'craft','trade_buy','trade_sell','admin_edit'
    `detail`         JSON         DEFAULT NULL,
    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_char_date` (`charid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES POUR L'ÉQUILIBRAGE
-- ═══════════════════════════════════════════════════════════════════

-- « Qu'est-ce qui consomme de la ferraille, et en quelle quantité ? »
-- SELECT r.output_item, i.qty
-- FROM rz_craft_ingredients i
-- JOIN rz_craft_recipes r ON r.id = i.recipe_id
-- WHERE i.item = 'ferraille'
-- ORDER BY i.qty DESC;

-- « Quels items ne sont produits par AUCUNE recette ? » (trous de progression)
-- SELECT DISTINCT i.item
-- FROM rz_craft_ingredients i
-- LEFT JOIN rz_craft_recipes r ON r.output_item = i.item
-- WHERE r.id IS NULL;
