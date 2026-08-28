-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — COFFRES DE SÉCURITÉ
--
--  Cette table est un JOURNAL, pas la source de vérité. La
--  protection réelle vit dans les métadonnées de l'item ox_inventory
--  (propriétaire + date d'expiration), qui suivent le coffre partout
--  où il va. La table sert à retrouver qui a reçu quoi, et quand.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `rz_secure_chests` (
    `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Identifiant du conteneur généré par ox_inventory. C'est lui qui
    -- relie cette ligne au coffre réel, quel que soit son porteur.
    `container_id`     VARCHAR(64)  DEFAULT NULL,
    `item_name`        VARCHAR(64)  NOT NULL,

    -- Le propriétaire lié. Un coffre remis reste attaché à ce
    -- citizenid même s'il change de mains.
    `owner_citizenid`  VARCHAR(50)  NOT NULL,
    `owner_name`       VARCHAR(96)  DEFAULT NULL,

    -- Qui l'a remis (licence du staff)
    `granted_by`       VARCHAR(64)  DEFAULT NULL,
    `granted_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    `expires_at`       TIMESTAMP    NOT NULL,
    `duration_hours`   INT          NOT NULL,

    `status`           ENUM('actif','expire','revoque')
                       NOT NULL DEFAULT 'actif',

    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_citizenid`, `status`),
    KEY `idx_container` (`container_id`),
    KEY `idx_expires` (`expires_at`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- Coffres encore protégés, du plus proche de l'expiration au plus loin
-- SELECT owner_name, item_name, expires_at,
--        TIMESTAMPDIFF(HOUR, NOW(), expires_at) AS heures_restantes
-- FROM rz_secure_chests
-- WHERE status = 'actif' AND expires_at > NOW()
-- ORDER BY expires_at ASC;

-- Un joueur réclame un coffre qu'il dit avoir acheté : voici son historique
-- SELECT * FROM rz_secure_chests
-- WHERE owner_citizenid = 'ABC12345'
-- ORDER BY granted_at DESC;

-- Combien de coffres remis par membre du staff ce mois-ci
-- SELECT granted_by, COUNT(*) AS remis
-- FROM rz_secure_chests
-- WHERE granted_at > NOW() - INTERVAL 30 DAY
-- GROUP BY granted_by
-- ORDER BY remis DESC;
