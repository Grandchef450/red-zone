-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — TABLES DES PETITS MÉTIERS
--
--  Seul gfx-lumberjack a besoin de tables dédiées. wasabi_mining et
--  lunar_fishing stockent leur progression dans les métadonnées du
--  personnage, gérées par Qbox : rien à créer pour eux.
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
--  BÛCHERON — fiche du joueur
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `gfx_lumberjack` (
    `id`             INT(11)      NOT NULL AUTO_INCREMENT,
    `citizenid`      VARCHAR(50)  DEFAULT NULL,
    `lumberjackName` VARCHAR(50)  DEFAULT NULL,
    `cuttingTrees`   INT(11)      DEFAULT 0,
    `level`          INT(11)      DEFAULT 0,
    `total_money`    INT(11)      DEFAULT 0,
    `profile_photo`  VARCHAR(250) DEFAULT '',

    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;


-- ───────────────────────────────────────────────────────────────────
--  BÛCHERON — contrats entre joueurs
--
--  Un joueur commande de l'abattage, un autre l'exécute et les deux
--  touchent leur part. Avec la conversion en bois, ça devient un
--  vrai outil d'organisation entre clans.
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `gfx_lumberjack_contract` (
    `id`             INT(11)      NOT NULL AUTO_INCREMENT,
    `citizenid`      VARCHAR(50)  DEFAULT NULL,
    `contractOwner`  VARCHAR(50)  DEFAULT NULL,
    `treeCount`      VARCHAR(50)  DEFAULT NULL,
    `percent`        INT(11)      DEFAULT 0,
    `numberOfUses`   INT(11)      DEFAULT 0,
    `profile_photo`  VARCHAR(250) DEFAULT '',

    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;


-- ═══════════════════════════════════════════════════════════════════
--  NOTE
--
--  La colonne `total_money` est conservée telle quelle : le script
--  s'en sert pour son classement interne. Elle compte désormais des
--  points de rendement, plus des dollars — aucun joueur ne la voit.
-- ═══════════════════════════════════════════════════════════════════
