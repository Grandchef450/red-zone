-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — RÉGLAGES DU LOOT DES ÉPAVES
--
--  Ces tables rendent la table de butin modifiable EN JEU depuis le
--  menu admin. Le config.lua de rz_epaves ne sert plus que de valeurs
--  par défaut, utilisées au tout premier démarrage pour amorcer la
--  base. Ensuite, c'est la base qui fait foi.
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
--  RÉGLAGES GÉNÉRAUX
--  Table clé/valeur : plus souple qu'une colonne par option, et on
--  peut ajouter un réglage sans toucher au schéma.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_epave_settings` (
    `setting`     VARCHAR(48)  NOT NULL,
    `value`       VARCHAR(64)  NOT NULL,
    `updated_by`  VARCHAR(64)  DEFAULT NULL,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  TABLE DE BUTIN
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_epave_loot` (
    `item`        VARCHAR(64)  NOT NULL,
    `min_count`   INT          NOT NULL DEFAULT 1,
    `max_count`   INT          NOT NULL DEFAULT 1,

    -- Probabilité en %, appliquée APRÈS le tirage de l'item.
    -- Une chance de 70 ne veut donc pas dire 70 % de trouver l'item :
    -- il faut d'abord qu'il sorte du tirage.
    `chance`      TINYINT      NOT NULL DEFAULT 50,

    `enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
    `updated_by`  VARCHAR(64)  DEFAULT NULL,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`item`),
    KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL DES MODIFICATIONS
--
--  L'équilibrage se fait à plusieurs mains et sur plusieurs
--  semaines. Sans trace, personne ne saura pourquoi la ferraille
--  est passée de 4 à 12 un mardi soir.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_epave_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admin`       VARCHAR(64)  DEFAULT NULL,
    `action`      VARCHAR(32)  NOT NULL,
    `detail`      JSON         DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Table de butin actuelle, du plus courant au plus rare
-- SELECT item, min_count, max_count, chance FROM rz_epave_loot
-- WHERE enabled = 1 ORDER BY chance DESC;

-- Qui a touché à quoi cette semaine
-- SELECT admin, action, detail, created_at FROM rz_epave_logs
-- WHERE created_at > NOW() - INTERVAL 7 DAY ORDER BY created_at DESC;
