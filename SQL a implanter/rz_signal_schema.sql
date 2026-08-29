-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — SIGNAUX D'URGENCE
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
--  JOURNAL DES DIFFUSIONS
--
--  Sert autant à l'audit qu'à l'équilibrage : si une alerte n'atteint
--  que trois joueurs sur quarante, c'est que la couverture réseau est
--  mal découpée, pas que le message est mauvais.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_signal_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    `priority`    VARCHAR(16)  NOT NULL DEFAULT 'info',
    `sender`      VARCHAR(64)  DEFAULT NULL,
    `message`     VARCHAR(255) NOT NULL,

    -- NULL = diffusé partout
    `zone`        VARCHAR(48)  DEFAULT NULL,

    `recipients`  INT          NOT NULL DEFAULT 0,

    -- Licence de l'admin, uniquement pour les annonces manuelles
    `admin`       VARCHAR(64)  DEFAULT NULL,

    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_date` (`created_at`),
    KEY `idx_priority` (`priority`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  HISTORIQUE DU RÉSEAU
--
--  Chaque coupure et chaque rétablissement laisse une trace. Quand un
--  joueur affirmera qu'il n'a jamais reçu l'annonce, tu sauras si sa
--  zone était réellement coupée à ce moment-là.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_signal_network` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `zone_key`    VARCHAR(48)  NOT NULL,
    `powered`     TINYINT(1)   NOT NULL,
    `changed_by`  VARCHAR(64)  DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_zone_date` (`zone_key`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Portée réelle des annonces : combien de joueurs les reçoivent ?
-- SELECT priority, AVG(recipients) AS moyenne, COUNT(*) AS diffusions
-- FROM rz_signal_logs
-- WHERE created_at > NOW() - INTERVAL 7 DAY
-- GROUP BY priority;

-- Temps passé dans le noir, par zone, cette semaine
-- SELECT zone_key, COUNT(*) AS bascules
-- FROM rz_signal_network
-- WHERE created_at > NOW() - INTERVAL 7 DAY
-- GROUP BY zone_key ORDER BY bascules DESC;
