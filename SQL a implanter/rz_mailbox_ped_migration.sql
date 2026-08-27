-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — MIGRATION : la boîte aux lettres devient un ped
--
--  À exécuter APRÈS rz_INSTALL_COMPLET.sql.
--  Si tu n'as pas encore importé, utilise plutôt le fichier complet
--  mis à jour — cette migration ne sert qu'à rattraper une base
--  déjà en place.
-- ═══════════════════════════════════════════════════════════════════


-- ─── Nouvelles colonnes ────────────────────────────────────────────
ALTER TABLE `rz_mailbox_points`
    ADD COLUMN `ped_model` VARCHAR(64) NOT NULL DEFAULT 'a_m_m_hillbilly_01'
        COMMENT 'Modèle du ped qui garde les colis'
        AFTER `heading`,
    ADD COLUMN `scenario` VARCHAR(64) DEFAULT 'WORLD_HUMAN_CLIPBOARD'
        COMMENT 'Animation jouée en boucle par le ped',
    ADD COLUMN `ped_frozen` TINYINT(1) NOT NULL DEFAULT 1
        COMMENT 'Ped figé et invulnérable (recommandé)';


-- ─── prop_model devient optionnel ──────────────────────────────────
--  On le garde : un décor à côté du ped (caisse, table, comptoir)
--  reste utile. NULL = aucun prop, seulement le ped.
ALTER TABLE `rz_mailbox_points`
    MODIFY COLUMN `prop_model` VARCHAR(64) DEFAULT NULL
        COMMENT 'Prop décoratif optionnel, NULL = ped seul';


-- ─── Les points déjà créés passent au ped ──────────────────────────
UPDATE `rz_mailbox_points`
SET `prop_model` = NULL
WHERE `prop_model` = 'prop_postbox_01a';


-- ─── Blip par défaut plus cohérent ─────────────────────────────────
--  480 = icône « personnage », plus lisible qu'une enveloppe pour
--  un PNJ. À ajuster librement.
ALTER TABLE `rz_mailbox_points`
    MODIFY COLUMN `blip_sprite` SMALLINT DEFAULT 480;


-- ═══════════════════════════════════════════════════════════════════
--  EXEMPLE
-- ═══════════════════════════════════════════════════════════════════

-- INSERT INTO rz_mailbox_points
--     (label, x, y, z, heading, ped_model, scenario, blip_sprite, blip_color, safezone_id)
-- VALUES
--     ('Le Facteur — Sandy', 1701.50, 2590.00, 45.56, 90.0,
--      'a_m_m_hillbilly_01', 'WORLD_HUMAN_CLIPBOARD', 480, 5, 'safezone_sandy');


-- Quelques modèles qui collent au thème post-apo :
--   a_m_m_hillbilly_01     survivant rural
--   a_m_m_hillbilly_02     survivant rural, variante
--   s_m_m_dockwork_01      docker, allure ouvrière
--   a_m_m_tramp_01         vagabond
--   s_m_y_dealer_01        marchand
--   a_m_m_prolhost_01      tenancier

-- Scénarios utiles :
--   WORLD_HUMAN_CLIPBOARD       consulte un registre  ← conseillé
--   WORLD_HUMAN_AA_COFFEE       boit un café
--   WORLD_HUMAN_GUARD_STAND     monte la garde
--   WORLD_HUMAN_SMOKING         fume
--   WORLD_HUMAN_LEANING         adossé à un mur
