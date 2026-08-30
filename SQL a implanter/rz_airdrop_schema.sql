-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — LARGAGES AÉRIENS
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
--  CAISSES
--
--  Historique plus que sauvegarde : les caisses ne vivent que trente
--  minutes et ne survivent pas à un redémarrage. Cette table sert à
--  savoir qui a ramassé quoi, et à mesurer si le butin est équilibré.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_airdrop_crates` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `crate_id`   VARCHAR(64)  NOT NULL,

    -- commun | peu_commun | rare | tres_rare
    `tier`       VARCHAR(24)  NOT NULL,

    `x`          FLOAT        NOT NULL,
    `y`          FLOAT        NOT NULL,

    -- Contenu tiré au largage, avant tout ramassage
    `items`      JSON         DEFAULT NULL,

    `dropped_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP    NOT NULL,

    -- Renseignés à la première ouverture
    `opened_at`  TIMESTAMP    NULL DEFAULT NULL,
    `opened_by`  VARCHAR(80)  DEFAULT NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_crate` (`crate_id`),
    KEY `idx_tier` (`tier`),
    KEY `idx_dropped` (`dropped_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  ACTIONS DU STAFF
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_airdrop_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admin`      VARCHAR(80)  DEFAULT NULL,
    `action`     VARCHAR(32)  NOT NULL,
    `detail`     JSON         DEFAULT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
--
--  Ces deux-là valent le détour : elles disent si ton largage est
--  bien calibré.
-- ═══════════════════════════════════════════════════════════════════

-- Combien de caisses ne sont JAMAIS ramassées ?
-- Un taux élevé signifie que trente minutes ne suffisent pas, ou que
-- les zones de largage sont trop éloignées des joueurs.
--
-- SELECT tier,
--        COUNT(*) AS larguees,
--        SUM(opened_at IS NOT NULL) AS ramassees,
--        ROUND(100 * SUM(opened_at IS NOT NULL) / COUNT(*)) AS taux
-- FROM rz_airdrop_crates
-- WHERE dropped_at > NOW() - INTERVAL 7 DAY
-- GROUP BY tier;

-- Combien de temps met-on à ouvrir une caisse après son largage ?
-- En dessous de cinq minutes, c'est impossible : le verrou tient.
--
-- SELECT tier,
--        AVG(TIMESTAMPDIFF(SECOND, dropped_at, opened_at)) AS secondes
-- FROM rz_airdrop_crates
-- WHERE opened_at IS NOT NULL
-- GROUP BY tier;
