-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — APPARITION ET SAUVETAGE
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
--  ZONES QUI FONT PLANTER
--
--  Un endroit qui crashe est un piège invisible : le joueur y
--  retourne — souvent parce que son personnage y a été sauvegardé —
--  replante, et finit par croire que le serveur est cassé.
--
--  Il ne peut même pas le signaler : il est éjecté avant.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_crash_zones` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,

    `x`           FLOAT        NOT NULL,
    `y`           FLOAT        NOT NULL,
    `z`           FLOAT        NOT NULL,
    `radius`      FLOAT        NOT NULL DEFAULT 50,

    -- Affiché aux joueurs qui s'en approchent
    `label`       VARCHAR(64)  NOT NULL,

    -- Note interne : ce qui plante exactement. Utile dans six mois.
    `note`        VARCHAR(255) DEFAULT NULL,

    `enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
    `created_by`  VARCHAR(80)  DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL DES SAUVETAGES
--
--  Sa vraie valeur est statistique : plusieurs déblocages au même
--  endroit trahissent un décor défectueux. C'est ce qui permet de
--  repérer un piège avant qu'il ne fasse fuir du monde.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_spawn_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Renseigné uniquement pour une action du staff
    `admin`       VARCHAR(80)  DEFAULT NULL,
    `target`      VARCHAR(80)  DEFAULT NULL,

    -- unstuck | rescue | bring
    `action`      VARCHAR(24)  NOT NULL,
    `detail`      JSON         DEFAULT NULL,

    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_action_date` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  LA REQUÊTE QUI VAUT LE DÉTOUR
--
--  Elle regroupe les déblocages par tranche de 50 mètres. Un endroit
--  qui revient souvent est un décor à corriger — ou une zone à
--  marquer comme instable.
--
--  SELECT
--      ROUND(JSON_EXTRACT(detail, '$.fromX') / 50) * 50 AS zone_x,
--      ROUND(JSON_EXTRACT(detail, '$.fromY') / 50) * 50 AS zone_y,
--      COUNT(*) AS deblocages
--  FROM rz_spawn_logs
--  WHERE action = 'unstuck'
--    AND created_at > NOW() - INTERVAL 30 DAY
--  GROUP BY zone_x, zone_y
--  HAVING deblocages >= 3
--  ORDER BY deblocages DESC;
-- ═══════════════════════════════════════════════════════════════════
