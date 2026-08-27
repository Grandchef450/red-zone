-- ═══════════════════════════════════════════════════════════════════
--  REDZONE SURVIVAL — Installation complète de la base de données
--  Généré le 27 août 2026
--
--  Ce fichier réunit les trois scripts dans le bon ordre.
--  Un seul import à faire : phpMyAdmin > Importer > ce fichier.
--
--  Il est SANS DANGER de le rejouer : tout est en CREATE TABLE
--  IF NOT EXISTS. Seuls les ALTER TABLE échoueront si les colonnes
--  existent déjà — c'est normal et sans conséquence.
-- ═══════════════════════════════════════════════════════════════════


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


-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — ADDENDUM : paiement partiel en capsules
--
--  Mécanique : au craft, si le joueur n'a pas tous les matériaux,
--  il peut payer les manquants en capsules.
--  Coût = quantité manquante × valeur_item × Config.CapsuleMultiplier
--
--  ⚠️  Le multiplicateur (2.5 recommandé) est ce qui empêche les
--  capsules de tuer le farming. Payer doit TOUJOURS coûter plus
--  cher que ramasser.
-- ═══════════════════════════════════════════════════════════════════


-- ─── 1. Valeur de chaque item en capsules ──────────────────────────
CREATE TABLE IF NOT EXISTS `rz_item_values` (
    `item`          VARCHAR(64)  NOT NULL,
    `capsule_value` INT          NOT NULL DEFAULT 0,  -- 0 = non substituable
    PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ─── 2. Options de substitution par recette ────────────────────────
ALTER TABLE `rz_craft_recipes`
    ADD COLUMN `allow_capsules` TINYINT(1) NOT NULL DEFAULT 1
        COMMENT 'Autorise le paiement des manquants en capsules',
    ADD COLUMN `max_capsule_ratio` TINYINT NOT NULL DEFAULT 50
        COMMENT 'Part max du coût payable en capsules (en %). 0 = interdit, 100 = tout';

-- Exemple : sur les recettes de phase 5, on veut du vrai farming.
-- UPDATE rz_craft_recipes SET max_capsule_ratio = 0 WHERE category = 'munitions' AND required_level > 40;


-- ─── 3. Valeurs initiales ──────────────────────────────────────────
-- Ces chiffres sont un POINT DE DÉPART, pas un équilibrage final.
-- Ajuste-les après tes premiers tests en jeu.

INSERT INTO `rz_item_values` (`item`, `capsule_value`) VALUES
    -- Départ
    ('sac_survie_12', 10),
    ('couteau_suisse', 10),
    ('lampe_poche', 10),
    ('batterie', 10),
    ('ration_mre', 10),
    -- Récupération
    ('ferraille', 5),
    ('carton', 5),
    ('plastique', 5),
    ('caoutchouc', 5),
    ('ruban_adhesif', 5),
    ('fil_fer', 5),
    ('ficelle', 5),
    ('tissu_use', 5),
    ('tube_cuivre', 5),
    ('verre', 5),
    ('collier_argent', 5),
    ('fil_nylon', 5),
    ('bracelet_or', 5),
    ('batterie_usee', 5),
    ('ressort', 5),
    ('morceau_bois', 5),
    ('bouteille_eau_sale', 5),
    ('chaussette_blanche', 5),
    ('roche_eau', 5),
    ('sable', 5),
    ('cafe_colombien_sachet', 5),
    ('cafe_moulu_sachet', 5),
    ('cle_molette', 5),
    ('tuyau_caoutchouc', 5),
    ('tuyau_plastique', 5),
    ('colle_construction', 5),
    ('elastique', 5),
    ('sel', 5),
    ('aiguille_crochet', 5),
    ('cle_cric', 5),
    -- Chasse
    ('viande_cerf_crue', 15),
    ('viande_lapin_crue', 15),
    ('filet_truite_cru', 15),
    ('steak_requin_cru', 15),
    ('pave_saumon_cru', 15),
    ('viande_cougar_crue', 15),
    ('viande_boeuf_crue', 15),
    ('filet_morue_cru', 15),
    ('gras_animal', 15),
    -- Cuisson
    ('steak_cerf', 25),
    ('cuisse_lapin', 25),
    ('filet_truite', 25),
    ('steak_requin', 25),
    ('pave_saumon', 25),
    ('cote_cougar', 25),
    ('steak_boeuf', 25),
    ('filet_morue', 25),
    ('huile_reparation', 25),
    ('viande_boeuf_sechee', 25),
    ('viande_cougar_sechee', 25),
    ('poisson_seche', 25),
    -- Plats avancés
    ('civet_cerf', 60),
    ('lapin_moutarde', 60),
    ('boeuf_carottes', 60),
    ('truite_meuniere', 60),
    ('morue_biere', 60),
    ('requin_poche', 60),
    ('papillote_saumon', 60),
    ('cote_cougar_grillee', 60),
    -- Boissons
    ('cafe_torrefie', 20),
    ('cafe_infuse', 20),
    ('eau_purifiee', 20),
    -- Minerais
    ('minerai_fer', 12),
    ('minerai_aluminium', 12),
    ('minerai_cuivre', 12),
    ('minerai_charbon', 12),
    ('minerai_soufre', 12),
    ('minerai_magnesium', 12),
    ('pierre_silex', 12),
    ('minerai_graphite', 12),
    ('minerai_silicium', 12),
    ('minerai_or', 12),
    ('minerai_argent', 12),
    -- Fonderie
    ('lingot_fer', 30),
    ('lingot_aluminium', 30),
    ('lingot_cuivre', 30),
    ('charbon', 30),
    ('poudre_soufre', 30),
    ('lingot_magnesium', 30),
    ('carbone', 30),
    ('lingot_inox', 30),
    ('brique_ceramique', 30),
    ('verre_concasse', 30),
    ('plastique_concasse', 30),
    ('lingot_or', 30),
    ('lingot_argent', 30),
    -- Transformation
    ('tube_fer', 45),
    ('tube_aluminium', 45),
    ('tube_inox', 45),
    ('tube_carbone', 45),
    ('barre_magnesium', 45),
    ('fluorocarbone', 45),
    ('plaque_fer', 45),
    ('plaque_aluminium', 45),
    ('plaque_cuivre', 45),
    ('plaque_inox', 45),
    ('plaque_verre', 45),
    ('plaque_plastique', 45),
    ('poudre_magnesium', 45),
    ('poudre_carbone', 45),
    ('poudre_inox', 45),
    ('poudre_silice', 45),
    ('poudre_aluminium', 45),
    ('poudre_diamant', 45),
    ('fil_cuivre', 45),
    ('piece_or', 45),
    ('piece_argent', 45),
    -- Craft phase 1
    ('sac_survie_32', 80),
    ('allumettes', 80),
    ('allumeur_survie', 80),
    ('rechargeur_batterie', 80),
    ('bandage_survie', 80),
    ('attelle_survie', 80),
    ('cartouche_9mm_cuivre', 80),
    ('cartouche_9mm_acier', 80),
    ('cartouche_9mm_alu', 80),
    ('poudre_noire', 80),
    ('corde_survie', 80),
    ('fil_peche', 80),
    ('chaudron_acier', 80),
    ('couteau_survie', 80),
    ('lance_survie', 80),
    ('hache_survie', 80),
    ('aiguisoir_survie', 80),
    ('purificateur_eau_survie', 80),
    ('filtre_tous_usages', 80),
    ('detonateur_9mm', 80),
    ('detonateur_45acp', 80),
    ('bbq_survie', 80),
    ('jerrican', 80),
    ('pioche_minage', 80),
    ('outils_jardinage', 80),
    ('arrosoir_metal', 80),
    ('cric_auto', 80),
    -- Craft phase 2
    ('sac_survie_64', 150),
    ('chaudron_cuivre', 150),
    ('couteau_acier', 150),
    ('lance_acier', 150),
    ('canne_peche', 150),
    ('hache_acier', 150),
    ('aiguisoir_avance', 150),
    ('purificateur_eau_avance', 150),
    ('balle_9mm_acier', 150),
    ('balle_9mm_cuivre', 150),
    ('balle_9mm_alu', 150),
    ('presse_rechargement', 150),
    ('cartouche_45_acier', 150),
    ('cartouche_45_cuivre', 150),
    ('cartouche_45_alu', 150),
    ('cartouche_45_inox', 150),
    ('cartouche_45_carbone', 150),
    ('bbq_avance', 150),
    ('chargeur_9mm_16', 150),
    ('chargeur_45acp_16', 150),
    -- Craft phase 3
    ('sac_survie_72', 300),
    ('chaudron_fonte', 300),
    ('couteau_aluminium', 300),
    ('lance_aluminium', 300),
    ('hache_aluminium', 300),
    ('canne_peche_carbone', 300),
    ('balle_45_acier', 300),
    ('balle_45_cuivre', 300),
    ('balle_45_alu', 300),
    ('balle_45_inox', 300),
    ('balle_45_carbone', 300),
    ('cellule_photovoltaique', 300),
    ('panneau_photovoltaique', 300),
    ('rechargeur_photovoltaique', 300),
    ('batterie_stockage', 300),
    ('siphon_manuel', 300),
    ('chargeur_45acp_15', 300),
    ('chargeur_45acp_20', 300),
    ('chargeur_45acp_camembert_20', 300),
    -- Craft phase 4
    ('sac_survie_104', 600),
    ('chaudron_fonte_electrique', 600),
    ('plaque_kevlar', 600),
    ('gilet_tactique_survie', 600),
    ('couteau_inox', 600),
    ('hache_inox', 600),
    ('canne_peche_fibre_verre', 600),
    ('trousse_premiers_soins', 600),
    ('imprimerie_pieces_or', 600),
    ('imprimerie_pieces_argent', 600),
    ('batterie_stockage_reutilisable', 600),
    ('siphon_automatique', 600),
    -- Craft phase 5
    ('sac_survie_134', 1200),
    ('plaque_kevlar_avancee', 1200),
    ('gilet_tactique_survie_avance', 1200),
    ('kit_reparation_auto', 1200),
    ('kit_reparation_arme_blanche', 1200),
    ('kit_reparation_arme_feu', 1200),
    ('kit_reparation_arme_auto', 1200),
    ('grenade_fumigene', 1200),
    ('grenade_fragmentation', 1200),
    -- Coffres (craft)
    ('coffre_securite_12h', 2000),
    ('coffre_securite_24h', 2000),
    ('coffre_securite_72h', 2000),
    ('coffre_securite_96h', 2000),
    ('coffre_securite_120h', 2000),
    ('coffre_securite_144h', 2000),
    ('coffre_securite_168h', 2000),
    -- Coffres (boutique)
    ('coffre_boutique_32_7j', 0),
    ('coffre_boutique_64_14j', 0),
    ('coffre_boutique_72_21j', 0),
    ('coffre_boutique_104_28j', 0),
    ('coffre_boutique_134_35j', 0);


-- ─── 4. Vérification ───────────────────────────────────────────────
-- Items déclarés dans items.lua mais sans valeur : la requête doit
-- ne rien renvoyer. Si elle renvoie quelque chose, ces items ne
-- pourront pas être payés en capsules.
-- SELECT i.item FROM rz_craft_ingredients i
-- LEFT JOIN rz_item_values v ON v.item = i.item
-- WHERE v.item IS NULL;


-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — ADDENDUM : sessions de craft et boîte aux lettres
--
--  À importer APRÈS rz_craft_schema.sql et rz_craft_capsules.sql
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
--  SESSIONS DE CRAFT EN COURS
--
--  Persistées en base et PAS seulement en mémoire. C'est ce qui
--  permet de survivre à un crash serveur : au redémarrage, toute
--  session encore 'en_cours' est reprise ou remboursée.
--
--  Les matériaux ne sont PAS retirés de l'inventaire au lancement.
--  Ils sont réservés (verrouillés par le hook ox_inventory) et
--  la colonne `reserved_items` sert de mémoire de ce verrou.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_sessions` (
    `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `charid`          INT UNSIGNED NOT NULL,
    `recipe_id`       INT UNSIGNED NOT NULL,
    `table_id`        INT UNSIGNED NOT NULL,

    `quantity`        INT       NOT NULL DEFAULT 1,

    -- Ce qui est verrouillé : [{"item":"ferraille","qty":10}, ...]
    `reserved_items`  JSON      NOT NULL,

    -- Capsules déjà prélevées pour les matériaux manquants et le lot.
    -- Elles sont prises AU LANCEMENT (contrairement aux matériaux),
    -- sinon le joueur pourrait les dépenser ailleurs pendant le craft.
    `capsules_paid`   INT       NOT NULL DEFAULT 0,

    `started_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ends_at`         TIMESTAMP NOT NULL,

    `status`          ENUM('en_cours','termine','annule','interrompu')
                      NOT NULL DEFAULT 'en_cours',

    PRIMARY KEY (`id`),
    KEY `idx_char_status` (`charid`, `status`),
    KEY `idx_status_ends` (`status`, `ends_at`),
    CONSTRAINT `fk_sess_recipe` FOREIGN KEY (`recipe_id`)
        REFERENCES `rz_craft_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  BOÎTE AUX LETTRES
--
--  Un colis = une ligne. Le contenu est du JSON parce qu'il n'a
--  aucune raison d'être requêté item par item : on le lit en bloc,
--  on le rend au joueur, on le marque récupéré.
--
--  Ne sert PAS qu'au craft : réutilisable pour les compensations
--  staff, les remboursements de bug, les récompenses d'événement.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mailbox` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `charid`        INT UNSIGNED NOT NULL,

    `label`         VARCHAR(96)  NOT NULL,   -- « Craft interrompu — Plaque de kevlar »
    `reason`        ENUM('craft_annule','craft_crash','craft_deconnexion',
                         'compensation','evenement','autre')
                    NOT NULL DEFAULT 'autre',

    -- [{"item":"ferraille","qty":10},{"item":"capsule","qty":250}]
    `contents`      JSON         NOT NULL,

    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `claimed_at`    TIMESTAMP    NULL DEFAULT NULL,

    -- Trace : qui a généré ce colis (NULL = automatique)
    `created_by`    VARCHAR(64)  DEFAULT NULL,

    PRIMARY KEY (`id`),
    KEY `idx_char_unclaimed` (`charid`, `claimed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  POINTS DE RETRAIT
--
--  Où le joueur récupère ses colis. Une ligne par emplacement,
--  éditable depuis le menu admin comme les tables de craft.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mailbox_points` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label`         VARCHAR(64)  NOT NULL DEFAULT 'Boîte aux lettres',

    `x`             FLOAT        NOT NULL,
    `y`             FLOAT        NOT NULL,
    `z`             FLOAT        NOT NULL,
    `heading`       FLOAT        NOT NULL DEFAULT 0.0,

    -- Le point de retrait est un PED, pas une boîte : un survivant
    -- qui garde les colis. Le prop reste optionnel, pour le décor.
    `ped_model`     VARCHAR(64)  NOT NULL DEFAULT 'a_m_m_hillbilly_01',
    `scenario`      VARCHAR(64)  DEFAULT 'WORLD_HUMAN_CLIPBOARD',
    `ped_frozen`    TINYINT(1)   NOT NULL DEFAULT 1,

    `prop_model`    VARCHAR(64)  DEFAULT NULL,
    `blip_sprite`   SMALLINT     DEFAULT 480,
    `blip_color`    TINYINT      DEFAULT 5,

    `safezone_id`   VARCHAR(32)  DEFAULT NULL,

    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES DE MAINTENANCE
-- ═══════════════════════════════════════════════════════════════════

-- Au démarrage du serveur : récupérer les sessions orphelines.
-- Le script les transforme en colis puis les marque 'interrompu'.
-- SELECT * FROM rz_craft_sessions WHERE status = 'en_cours';

-- Colis en attente pour un joueur.
-- SELECT id, label, contents, created_at FROM rz_mailbox
-- WHERE charid = ? AND claimed_at IS NULL ORDER BY created_at;

-- Les colis n'expirent pas. La ligne est SUPPRIMÉE au retrait,
-- ce qui empêche la table de gonfler. La trace reste dans rz_craft_logs.

-- Combien de crafts interrompus cette semaine ? (santé du serveur)
-- SELECT status, COUNT(*) FROM rz_craft_sessions
-- WHERE started_at > NOW() - INTERVAL 7 DAY GROUP BY status;
