-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — APPARITION ET DÉSENCLAVEMENT
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
--  ZONES INTERDITES
--
--  Endroits où un joueur ne doit JAMAIS apparaître : un MLO qui fait
--  planter, un décor mal collisionné, une zone en travaux.
--
--  Sans ce mécanisme, un joueur déconnecté au mauvais endroit plante
--  à chaque tentative de connexion — et ne peut plus jamais revenir
--  sur son personnage.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_spawn_blacklist` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label`     VARCHAR(96)  NOT NULL,

    `x`         FLOAT        NOT NULL,
    `y`         FLOAT        NOT NULL,
    `z`         FLOAT        NOT NULL,
    `radius`    FLOAT        NOT NULL DEFAULT 25,

    `added_by`  VARCHAR(80)  DEFAULT NULL,
    `added_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL
--
--  Sert surtout à repérer les endroits qui coincent : si trois
--  joueurs se désenclavent au même endroit dans la semaine, c'est
--  qu'il y a un vrai problème de décor à corriger.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_spawn_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`    VARCHAR(80)  DEFAULT NULL,
    `name`       VARCHAR(96)  DEFAULT NULL,

    -- unstuck | teleport
    `action`     VARCHAR(24)  NOT NULL,
    `detail`     JSON         DEFAULT NULL,

    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_date` (`created_at`),
    KEY `idx_action` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  LA REQUÊTE QUI VAUT LE DÉTOUR
--
--  Elle regroupe les désenclavements par zone de 100 mètres. Un
--  point qui revient souvent n'est pas un joueur maladroit : c'est
--  un décor à corriger, ou une zone à mettre en liste noire.
--
--  SELECT
--      ROUND(JSON_EXTRACT(detail, '$.x') / 100) * 100 AS zone_x,
--      ROUND(JSON_EXTRACT(detail, '$.y') / 100) * 100 AS zone_y,
--      COUNT(*) AS incidents
--  FROM rz_spawn_logs
--  WHERE action = 'unstuck'
--    AND created_at > NOW() - INTERVAL 30 DAY
--  GROUP BY zone_x, zone_y
--  HAVING incidents >= 3
--  ORDER BY incidents DESC;
-- ═══════════════════════════════════════════════════════════════════
