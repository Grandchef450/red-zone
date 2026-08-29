-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — MORT, AGONIE ET SACS MORTUAIRES
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
--  SACS AU SOL
--
--  Persistés pour qu'un simple `restart rz_mort` ne fasse pas
--  disparaître le stuff des joueurs. Ils sont purgés au-delà de
--  24 heures, ce qui correspond au reboot quotidien du serveur.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mort_bags` (
    `bag_id`           VARCHAR(64)  NOT NULL,
    `owner_citizenid`  VARCHAR(50)  NOT NULL,
    `owner_name`       VARCHAR(96)  DEFAULT NULL,

    `x`                FLOAT        NOT NULL,
    `y`                FLOAT        NOT NULL,
    `z`                FLOAT        NOT NULL,

    -- Jusqu'à cette date, seul le propriétaire peut l'ouvrir
    `lock_until`       TIMESTAMP    NOT NULL,
    `created_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`bag_id`),
    KEY `idx_owner` (`owner_citizenid`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL
--
--  Sert surtout à l'arbitrage : quand un joueur affirmera avoir été
--  tué injustement ou avoir perdu son stuff sans raison, tu auras la
--  position, l'heure et le sac correspondant.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mort_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid`   VARCHAR(50)  DEFAULT NULL,
    `action`      VARCHAR(24)  NOT NULL,     -- death | revive
    `detail`      JSON         DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_char_date` (`citizenid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Qui meurt le plus cette semaine ?
-- SELECT citizenid, COUNT(*) AS morts FROM rz_mort_logs
-- WHERE action = 'death' AND created_at > NOW() - INTERVAL 7 DAY
-- GROUP BY citizenid ORDER BY morts DESC LIMIT 20;

-- Combien de réanimations pour combien de morts ?
-- SELECT action, COUNT(*) FROM rz_mort_logs
-- WHERE created_at > NOW() - INTERVAL 7 DAY GROUP BY action;

-- Sacs encore au sol, du plus ancien au plus récent
-- SELECT owner_name, x, y, z, created_at FROM rz_mort_bags
-- ORDER BY created_at ASC;
