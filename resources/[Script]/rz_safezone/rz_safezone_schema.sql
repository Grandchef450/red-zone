-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — SAFE ZONES
--
--  Zones polygonales avec plancher et plafond. Le polygone est
--  stocké en JSON : on le lit en bloc au démarrage, jamais point
--  par point, donc aucune raison de le normaliser en table.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `rz_safezones` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Identifiant texte, utilisé par les autres scripts
    -- (rz_craft.safezone_id, script de zombies…)
    `zone_key`      VARCHAR(32)  NOT NULL,
    `label`         VARCHAR(64)  NOT NULL,

    -- Polygone : [{"x":123.4,"y":567.8}, ...] dans l'ordre du tracé.
    -- Minimum 3 points.
    `points`        JSON         NOT NULL,

    -- Volume vertical. Le plafond doit passer AU-DESSUS des toits :
    -- un joueur sous le plafond est DANS la zone, donc désarmé.
    -- S'il est au-dessus, il est dehors et ses tirs seront annulés
    -- à l'arrivée — protection efficace, mais moins propre.
    `min_z`         FLOAT        NOT NULL DEFAULT -50.0,
    `max_z`         FLOAT        NOT NULL DEFAULT 200.0,

    -- ─── ZONE TAMPON ────────────────────────────────────────────
    -- Anneau extérieur, en mètres. Les dégâts entre joueurs y sont
    -- aussi annulés. C'est LA réponse au camping de sortie : un
    -- joueur qui quitte la ville n'est pas abattu à trois mètres
    -- de la frontière.
    `buffer_meters` FLOAT        NOT NULL DEFAULT 25.0,

    -- ─── RÈGLES ─────────────────────────────────────────────────
    `block_damage`      TINYINT(1) NOT NULL DEFAULT 1,  -- annule tous les dégâts
    `block_weapons`     TINYINT(1) NOT NULL DEFAULT 1,  -- rengaine et empêche de sortir une arme
    `block_melee`       TINYINT(1) NOT NULL DEFAULT 1,  -- empêche les coups
    `block_projectiles` TINYINT(1) NOT NULL DEFAULT 1,  -- détruit ce qui vient de l'extérieur
    `block_vehicles`    TINYINT(1) NOT NULL DEFAULT 0,  -- interdit les véhicules
    `block_runover`     TINYINT(1) NOT NULL DEFAULT 1,  -- empêche les écrasements
    `despawn_zombies`   TINYINT(1) NOT NULL DEFAULT 1,  -- vide la zone de zombies

    -- ─── AFFICHAGE ──────────────────────────────────────────────
    `enter_message` VARCHAR(96)  NOT NULL DEFAULT 'Vous êtes en zone sûre',
    `exit_message`  VARCHAR(96)  NOT NULL DEFAULT 'Vous quittez la zone sûre',
    `blip_enabled`  TINYINT(1)   NOT NULL DEFAULT 1,
    `blip_color`    TINYINT      NOT NULL DEFAULT 2,
    `blip_alpha`    TINYINT      NOT NULL DEFAULT 128,

    `enabled`       TINYINT(1)   NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(64)  DEFAULT NULL,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_zone_key` (`zone_key`),
    KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL DES TENTATIVES
--
--  Chaque dégât bloqué est tracé. C'est ce qui permet de repérer
--  celui qui passe ses soirées à tirer dans la safe zone « pour
--  voir » — et de le sanctionner sur des faits.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_safezone_blocks` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `zone_key`    VARCHAR(32)  NOT NULL,
    `attacker`    VARCHAR(64)  DEFAULT NULL,   -- identifiant licence
    `victim`      VARCHAR(64)  DEFAULT NULL,
    `kind`        ENUM('arme','explosion','vehicule','melee') NOT NULL,
    `weapon`      VARCHAR(48)  DEFAULT NULL,
    `from_inside` TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_attacker` (`attacker`, `created_at`),
    KEY `idx_zone` (`zone_key`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Les joueurs qui insistent le plus (candidats au bannissement)
-- SELECT attacker, COUNT(*) AS tentatives
-- FROM rz_safezone_blocks
-- WHERE created_at > NOW() - INTERVAL 7 DAY
-- GROUP BY attacker
-- ORDER BY tentatives DESC
-- LIMIT 20;

-- Les zones les plus attaquées (peut-être mal délimitées)
-- SELECT zone_key, kind, COUNT(*) AS n
-- FROM rz_safezone_blocks
-- WHERE created_at > NOW() - INTERVAL 7 DAY
-- GROUP BY zone_key, kind
-- ORDER BY n DESC;
