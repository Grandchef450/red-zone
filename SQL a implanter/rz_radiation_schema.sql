-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — ZONE RADIOACTIVE
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `rz_radiation_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admin`       VARCHAR(64)  DEFAULT NULL,
    `action`      VARCHAR(32)  NOT NULL,
    `detail`      JSON         DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  RÉGLAGES MODIFIABLES EN JEU
--
--  Table clé/valeur : plus souple qu'une colonne par option, et on
--  ajoute un réglage sans toucher au schéma.
--
--  Le config.lua ne sert plus que de valeurs par défaut, utilisées
--  au premier démarrage pour amorcer la base. Ensuite c'est la base
--  qui fait foi, et le menu admin la modifie à chaud.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_radiation_settings` (
    `setting`     VARCHAR(48)  NOT NULL,
    `value`       VARCHAR(64)  NOT NULL,
    `updated_by`  VARCHAR(64)  DEFAULT NULL,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Tous les réglages actuels
-- SELECT setting, value, updated_at FROM rz_radiation_settings
-- ORDER BY setting;

-- Qui a touché à quoi cette semaine
-- SELECT admin, action, detail, created_at FROM rz_radiation_logs
-- WHERE created_at > NOW() - INTERVAL 7 DAY
-- ORDER BY created_at DESC;
