-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — GRADES DU STAFF
--
--  Alternative à la synchronisation Discord : les grades vivent en
--  base et s'attribuent depuis le menu F5. Aucun jeton, aucune
--  dépendance externe, rien à protéger d'autre que ta base.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `rz_staff` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Licence FiveM, AVEC le préfixe : license:a1b2c3...
    -- C'est l'identifiant le plus stable : il survit au changement
    -- de pseudo, de Steam et de Discord.
    `license`     VARCHAR(80)  NOT NULL,

    -- Pseudo au moment de l'attribution. Purement indicatif : sert
    -- à retrouver quelqu'un dans la liste sans lire des licences.
    `name`        VARCHAR(96)  DEFAULT NULL,

    -- Clé d'un grade de Config.Grades
    `grade`       VARCHAR(32)  NOT NULL,

    -- Qui a accordé, et pourquoi
    `granted_by`  VARCHAR(80)  DEFAULT NULL,
    `note`        VARCHAR(255) DEFAULT NULL,

    `granted_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_license` (`license`),
    KEY `idx_grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  JOURNAL DES CHANGEMENTS
--
--  Un grade retiré sans trace, c'est une dispute assurée trois
--  semaines plus tard. Chaque mouvement laisse une ligne.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `rz_staff_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`     VARCHAR(80)  NOT NULL,
    `name`        VARCHAR(96)  DEFAULT NULL,
    `action`      ENUM('accorde','modifie','retire') NOT NULL,
    `old_grade`   VARCHAR(32)  DEFAULT NULL,
    `new_grade`   VARCHAR(32)  DEFAULT NULL,
    `by_license`  VARCHAR(80)  DEFAULT NULL,
    `by_name`     VARCHAR(96)  DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_license` (`license`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  PREMIER FONDATEUR
--
--  Il faut bien commencer quelque part : sans au moins un
--  développeur en base, personne ne peut ouvrir le menu des grades.
--
--  Récupère ta licence en te connectant puis en tapant `status` en
--  console serveur, décommente et remplace.
-- ═══════════════════════════════════════════════════════════════════

-- INSERT INTO rz_staff (license, name, grade, note)
-- VALUES ('license:TA_LICENCE_ICI', 'Grandchef', 'developpeur', 'Fondateur');


-- ═══════════════════════════════════════════════════════════════════
--  REQUÊTES UTILES
-- ═══════════════════════════════════════════════════════════════════

-- L'équipe actuelle
-- SELECT name, grade, granted_at FROM rz_staff ORDER BY grade, name;

-- Qui a accordé quoi ce mois-ci
-- SELECT by_name, action, name, new_grade, created_at
-- FROM rz_staff_logs
-- WHERE created_at > NOW() - INTERVAL 30 DAY
-- ORDER BY created_at DESC;
