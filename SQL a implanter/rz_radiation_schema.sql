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
