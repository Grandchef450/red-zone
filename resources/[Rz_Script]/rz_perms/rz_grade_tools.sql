-- rz_perms / rz_grade_tools.sql
--
-- Permissions du menu F5, par grade, éditables en jeu par le
-- fondateur (onglet Équipe → Permissions du menu). Une fois cette
-- table importée, elle devient la source de vérité pour les
-- permissions listées dans Config.Tools / Config.ManagedPerms :
-- rz_perms les réapplique par-dessus les add_ace de server.cfg à
-- chaque démarrage.
--
-- Le développeur n'apparaît jamais ici : il garde tout, toujours.
--
-- ─── LE DÉCOUPAGE ──────────────────────────────────────────────────
-- Repris du découpage déjà écrit plus bas dans server.cfg :
--   CONSTRUIRE  façonne le serveur (établis, recettes, zones, jobs,
--               props)                              → admin
--   ARBITRER    règle des situations entre joueurs (réanimer,
--               prison, annonces, inventaires, reports) → modérateur
--   DÉPANNER    répare ce qui a mal tourné (colis, coffres, VIP,
--               reports)                             → support
--
-- Loot épaves et Zone radioactive restent hors de ce découpage : ce
-- sont des leviers d'équilibrage économique, pas des outils de
-- gestion — volontairement gardés au seul développeur, sauf Zone
-- radioactive ouverte à l'admin à la demande explicite du fondateur.
--
-- Équipe n'apparaît nulle part ici : accorder des grades reste
-- réservé au développeur (rz_perms.manage), non éditable depuis ce
-- panneau.
CREATE TABLE IF NOT EXISTS rz_grade_tools (
    grade      VARCHAR(32)  NOT NULL,
    tool_id    VARCHAR(32)  NOT NULL,
    enabled    TINYINT(1)   NOT NULL DEFAULT 1,
    updated_by VARCHAR(80)  NULL,
    updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (grade, tool_id)
);

INSERT INTO rz_grade_tools (grade, tool_id, enabled) VALUES
    ('admin', 'rz-staff',     0),
    ('admin', 'rz-craft',     1),
    ('admin', 'rz-safezones', 1),
    ('admin', 'rz-coffres',   1),
    ('admin', 'rz-epaves',    0),
    ('admin', 'rz-signal',    1),
    ('admin', 'rz-airdrop',   1),
    ('admin', 'rz-radiation', 1),
    ('admin', 'rz-mort',      1),
    ('admin', 'rz-props',     1),
    ('admin', 'rz-jobs',      1),
    ('admin', 'rz-jail',      1),
    ('admin', 'rz-reports',   1),
    ('admin', 'rz-vip',       1),
    ('admin', 'rz-invcheck',  1),

    ('moderateur', 'rz-staff',     0),
    ('moderateur', 'rz-craft',     0),   -- édite des recettes : construction, pas arbitrage
    ('moderateur', 'rz-safezones', 0),   -- idem
    ('moderateur', 'rz-coffres',   0),
    ('moderateur', 'rz-epaves',    0),
    ('moderateur', 'rz-signal',    1),   -- rz.signal.network jamais inclus, cf. Config.ManagedPerms
    ('moderateur', 'rz-airdrop',   0),
    ('moderateur', 'rz-radiation', 0),
    ('moderateur', 'rz-mort',      1),   -- réanimer un joueur bloqué : arbitrage courant
    ('moderateur', 'rz-props',     0),
    ('moderateur', 'rz-jobs',      0),
    ('moderateur', 'rz-jail',      1),
    ('moderateur', 'rz-reports',   1),
    ('moderateur', 'rz-vip',       0),
    ('moderateur', 'rz-invcheck',  1),   -- vérifier un inventaire pour anti-triche : arbitrage

    ('support', 'rz-staff',     0),
    ('support', 'rz-craft',     0),
    ('support', 'rz-safezones', 0),
    ('support', 'rz-coffres',   1),   -- remise après achat Discord : dépannage classique
    ('support', 'rz-epaves',    0),
    ('support', 'rz-signal',    0),
    ('support', 'rz-airdrop',   0),
    ('support', 'rz-radiation', 0),
    ('support', 'rz-mort',      0),
    ('support', 'rz-props',     0),
    ('support', 'rz-jobs',      0),
    ('support', 'rz-jail',      0),
    ('support', 'rz-reports',   1),
    ('support', 'rz-vip',       1),
    ('support', 'rz-invcheck',  0)
ON DUPLICATE KEY UPDATE
    enabled = VALUES(enabled);
