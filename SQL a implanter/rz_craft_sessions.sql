-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — ADDENDUM : sessions de craft et boîte aux lettres
--
--  À importer APRÈS rz_craft_schema.sql et rz_craft_capsules.sql
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
--  SESSIONS DE CRAFT EN COURS
--
--  Persistées en base et PAS seulement en mémoire. C'est ce qui
--  permet de survivre à un crash serveur : au redémarrage, toute
--  session encore 'en_cours' est reprise ou remboursée.
--
--  Les matériaux ne sont PAS retirés de l'inventaire au lancement.
--  Ils sont réservés (verrouillés par le hook ox_inventory) et
--  la colonne `reserved_items` sert de mémoire de ce verrou.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_craft_sessions` (
    `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `charid`          INT UNSIGNED NOT NULL,
    `recipe_id`       INT UNSIGNED NOT NULL,
    `table_id`        INT UNSIGNED NOT NULL,

    `quantity`        INT       NOT NULL DEFAULT 1,

    -- Ce qui est verrouillé : [{"item":"ferraille","qty":10}, ...]
    `reserved_items`  JSON      NOT NULL,

    -- Capsules déjà prélevées pour les matériaux manquants et le lot.
    -- Elles sont prises AU LANCEMENT (contrairement aux matériaux),
    -- sinon le joueur pourrait les dépenser ailleurs pendant le craft.
    `capsules_paid`   INT       NOT NULL DEFAULT 0,

    `started_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ends_at`         TIMESTAMP NOT NULL,

    `status`          ENUM('en_cours','termine','annule','interrompu')
                      NOT NULL DEFAULT 'en_cours',

    PRIMARY KEY (`id`),
    KEY `idx_char_status` (`charid`, `status`),
    KEY `idx_status_ends` (`status`, `ends_at`),
    CONSTRAINT `fk_sess_recipe` FOREIGN KEY (`recipe_id`)
        REFERENCES `rz_craft_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  BOÎTE AUX LETTRES
--
--  Un colis = une ligne. Le contenu est du JSON parce qu'il n'a
--  aucune raison d'être requêté item par item : on le lit en bloc,
--  on le rend au joueur, on le marque récupéré.
--
--  Ne sert PAS qu'au craft : réutilisable pour les compensations
--  staff, les remboursements de bug, les récompenses d'événement.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mailbox` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `charid`        INT UNSIGNED NOT NULL,

    `label`         VARCHAR(96)  NOT NULL,   -- « Craft interrompu — Plaque de kevlar »
    `reason`        ENUM('craft_annule','craft_crash','craft_deconnexion',
                         'compensation','evenement','autre')
                    NOT NULL DEFAULT 'autre',

    -- [{"item":"ferraille","qty":10},{"item":"capsule","qty":250}]
    `contents`      JSON         NOT NULL,

    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `claimed_at`    TIMESTAMP    NULL DEFAULT NULL,

    -- NULL = jamais. Sinon, colis purgé après cette date.
    `expires_at`    TIMESTAMP    NULL DEFAULT NULL,

    -- Trace : qui a généré ce colis (NULL = automatique)
    `created_by`    VARCHAR(64)  DEFAULT NULL,

    PRIMARY KEY (`id`),
    KEY `idx_char_unclaimed` (`charid`, `claimed_at`),
    KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  POINTS DE RETRAIT
--
--  Où le joueur récupère ses colis. Une ligne par emplacement,
--  éditable depuis le menu admin comme les tables de craft.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_mailbox_points` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label`         VARCHAR(64)  NOT NULL DEFAULT 'Boîte aux lettres',

    `x`             FLOAT        NOT NULL,
    `y`             FLOAT        NOT NULL,
    `z`             FLOAT        NOT NULL,
    `heading`       FLOAT        NOT NULL DEFAULT 0.0,

    `prop_model`    VARCHAR(64)  DEFAULT 'prop_postbox_01a',
    `blip_sprite`   SMALLINT     DEFAULT 478,
    `blip_color`    TINYINT      DEFAULT 5,

    `safezone_id`   VARCHAR(32)  DEFAULT NULL,

    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES DE MAINTENANCE
-- ═══════════════════════════════════════════════════════════════════

-- Au démarrage du serveur : récupérer les sessions orphelines.
-- Le script les transforme en colis puis les marque 'interrompu'.
-- SELECT * FROM rz_craft_sessions WHERE status = 'en_cours';

-- Colis en attente pour un joueur.
-- SELECT id, label, contents, created_at FROM rz_mailbox
-- WHERE charid = ? AND claimed_at IS NULL ORDER BY created_at;

-- Purge des colis expirés (à passer en tâche planifiée).
-- DELETE FROM rz_mailbox
-- WHERE expires_at IS NOT NULL AND expires_at < NOW() AND claimed_at IS NULL;

-- Combien de crafts interrompus cette semaine ? (santé du serveur)
-- SELECT status, COUNT(*) FROM rz_craft_sessions
-- WHERE started_at > NOW() - INTERVAL 7 DAY GROUP BY status;
