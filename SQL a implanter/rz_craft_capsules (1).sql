-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — ADDENDUM : paiement partiel en capsules
--
--  Mécanique : au craft, si le joueur n'a pas tous les matériaux,
--  il peut payer les manquants en capsules.
--  Coût = quantité manquante × valeur_item × Config.CapsuleMultiplier
--
--  ⚠️  Le multiplicateur (2.5 recommandé) est ce qui empêche les
--  capsules de tuer le farming. Payer doit TOUJOURS coûter plus
--  cher que ramasser.
-- ═══════════════════════════════════════════════════════════════════


-- ─── 1. Valeur de chaque item en capsules ──────────────────────────
CREATE TABLE IF NOT EXISTS `rz_item_values` (
    `item`          VARCHAR(64)  NOT NULL,
    `capsule_value` INT          NOT NULL DEFAULT 0,  -- 0 = non substituable
    PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ─── 2. Options de substitution par recette ────────────────────────
ALTER TABLE `rz_craft_recipes`
    ADD COLUMN `allow_capsules` TINYINT(1) NOT NULL DEFAULT 1
        COMMENT 'Autorise le paiement des manquants en capsules',
    ADD COLUMN `max_capsule_ratio` TINYINT NOT NULL DEFAULT 50
        COMMENT 'Part max du coût payable en capsules (en %). 0 = interdit, 100 = tout';

-- Exemple : sur les recettes de phase 5, on veut du vrai farming.
-- UPDATE rz_craft_recipes SET max_capsule_ratio = 0 WHERE category = 'munitions' AND required_level > 40;


-- ─── 3. Valeurs initiales ──────────────────────────────────────────
-- Ces chiffres sont un POINT DE DÉPART, pas un équilibrage final.
-- Ajuste-les après tes premiers tests en jeu.

INSERT INTO `rz_item_values` (`item`, `capsule_value`) VALUES
    -- Départ
    ('sac_survie_12', 10),
    ('couteau_suisse', 10),
    ('lampe_poche', 10),
    ('batterie', 10),
    ('ration_mre', 10),
    -- Récupération
    ('ferraille', 5),
    ('carton', 5),
    ('plastique', 5),
    ('caoutchouc', 5),
    ('ruban_adhesif', 5),
    ('fil_fer', 5),
    ('ficelle', 5),
    ('tissu_use', 5),
    ('tube_cuivre', 5),
    ('verre', 5),
    ('collier_argent', 5),
    ('fil_nylon', 5),
    ('bracelet_or', 5),
    ('batterie_usee', 5),
    ('ressort', 5),
    ('morceau_bois', 5),
    ('bouteille_eau_sale', 5),
    ('chaussette_blanche', 5),
    ('roche_eau', 5),
    ('sable', 5),
    ('cafe_colombien_sachet', 5),
    ('cafe_moulu_sachet', 5),
    ('cle_molette', 5),
    ('tuyau_caoutchouc', 5),
    ('tuyau_plastique', 5),
    ('colle_construction', 5),
    ('elastique', 5),
    ('sel', 5),
    ('aiguille_crochet', 5),
    ('cle_cric', 5),
    -- Chasse
    ('viande_cerf_crue', 15),
    ('viande_lapin_crue', 15),
    ('filet_truite_cru', 15),
    ('steak_requin_cru', 15),
    ('pave_saumon_cru', 15),
    ('viande_cougar_crue', 15),
    ('viande_boeuf_crue', 15),
    ('filet_morue_cru', 15),
    ('gras_animal', 15),
    -- Cuisson
    ('steak_cerf', 25),
    ('cuisse_lapin', 25),
    ('filet_truite', 25),
    ('steak_requin', 25),
    ('pave_saumon', 25),
    ('cote_cougar', 25),
    ('steak_boeuf', 25),
    ('filet_morue', 25),
    ('huile_reparation', 25),
    ('viande_boeuf_sechee', 25),
    ('viande_cougar_sechee', 25),
    ('poisson_seche', 25),
    -- Plats avancés
    ('civet_cerf', 60),
    ('lapin_moutarde', 60),
    ('boeuf_carottes', 60),
    ('truite_meuniere', 60),
    ('morue_biere', 60),
    ('requin_poche', 60),
    ('papillote_saumon', 60),
    ('cote_cougar_grillee', 60),
    -- Boissons
    ('cafe_torrefie', 20),
    ('cafe_infuse', 20),
    ('eau_purifiee', 20),
    -- Minerais
    ('minerai_fer', 12),
    ('minerai_aluminium', 12),
    ('minerai_cuivre', 12),
    ('minerai_charbon', 12),
    ('minerai_soufre', 12),
    ('minerai_magnesium', 12),
    ('pierre_silex', 12),
    ('minerai_graphite', 12),
    ('minerai_silicium', 12),
    ('minerai_or', 12),
    ('minerai_argent', 12),
    -- Fonderie
    ('lingot_fer', 30),
    ('lingot_aluminium', 30),
    ('lingot_cuivre', 30),
    ('charbon', 30),
    ('poudre_soufre', 30),
    ('lingot_magnesium', 30),
    ('carbone', 30),
    ('lingot_inox', 30),
    ('brique_ceramique', 30),
    ('verre_concasse', 30),
    ('plastique_concasse', 30),
    ('lingot_or', 30),
    ('lingot_argent', 30),
    -- Transformation
    ('tube_fer', 45),
    ('tube_aluminium', 45),
    ('tube_inox', 45),
    ('tube_carbone', 45),
    ('barre_magnesium', 45),
    ('fluorocarbone', 45),
    ('plaque_fer', 45),
    ('plaque_aluminium', 45),
    ('plaque_cuivre', 45),
    ('plaque_inox', 45),
    ('plaque_verre', 45),
    ('plaque_plastique', 45),
    ('poudre_magnesium', 45),
    ('poudre_carbone', 45),
    ('poudre_inox', 45),
    ('poudre_silice', 45),
    ('poudre_aluminium', 45),
    ('poudre_diamant', 45),
    ('fil_cuivre', 45),
    ('piece_or', 45),
    ('piece_argent', 45),
    -- Craft phase 1
    ('sac_survie_32', 80),
    ('allumettes', 80),
    ('allumeur_survie', 80),
    ('rechargeur_batterie', 80),
    ('bandage_survie', 80),
    ('attelle_survie', 80),
    ('cartouche_9mm_cuivre', 80),
    ('cartouche_9mm_acier', 80),
    ('cartouche_9mm_alu', 80),
    ('poudre_noire', 80),
    ('corde_survie', 80),
    ('fil_peche', 80),
    ('chaudron_acier', 80),
    ('couteau_survie', 80),
    ('lance_survie', 80),
    ('hache_survie', 80),
    ('aiguisoir_survie', 80),
    ('purificateur_eau_survie', 80),
    ('filtre_tous_usages', 80),
    ('detonateur_9mm', 80),
    ('detonateur_45acp', 80),
    ('bbq_survie', 80),
    ('jerrican', 80),
    ('pioche_minage', 80),
    ('outils_jardinage', 80),
    ('arrosoir_metal', 80),
    ('cric_auto', 80),
    -- Craft phase 2
    ('sac_survie_64', 150),
    ('chaudron_cuivre', 150),
    ('couteau_acier', 150),
    ('lance_acier', 150),
    ('canne_peche', 150),
    ('hache_acier', 150),
    ('aiguisoir_avance', 150),
    ('purificateur_eau_avance', 150),
    ('balle_9mm_acier', 150),
    ('balle_9mm_cuivre', 150),
    ('balle_9mm_alu', 150),
    ('presse_rechargement', 150),
    ('cartouche_45_acier', 150),
    ('cartouche_45_cuivre', 150),
    ('cartouche_45_alu', 150),
    ('cartouche_45_inox', 150),
    ('cartouche_45_carbone', 150),
    ('bbq_avance', 150),
    ('chargeur_9mm_16', 150),
    ('chargeur_45acp_16', 150),
    -- Craft phase 3
    ('sac_survie_72', 300),
    ('chaudron_fonte', 300),
    ('couteau_aluminium', 300),
    ('lance_aluminium', 300),
    ('hache_aluminium', 300),
    ('canne_peche_carbone', 300),
    ('balle_45_acier', 300),
    ('balle_45_cuivre', 300),
    ('balle_45_alu', 300),
    ('balle_45_inox', 300),
    ('balle_45_carbone', 300),
    ('cellule_photovoltaique', 300),
    ('panneau_photovoltaique', 300),
    ('rechargeur_photovoltaique', 300),
    ('batterie_stockage', 300),
    ('siphon_manuel', 300),
    ('chargeur_45acp_15', 300),
    ('chargeur_45acp_20', 300),
    ('chargeur_45acp_camembert_20', 300),
    -- Craft phase 4
    ('sac_survie_104', 600),
    ('chaudron_fonte_electrique', 600),
    ('plaque_kevlar', 600),
    ('gilet_tactique_survie', 600),
    ('couteau_inox', 600),
    ('hache_inox', 600),
    ('canne_peche_fibre_verre', 600),
    ('trousse_premiers_soins', 600),
    ('imprimerie_pieces_or', 600),
    ('imprimerie_pieces_argent', 600),
    ('batterie_stockage_reutilisable', 600),
    ('siphon_automatique', 600),
    -- Craft phase 5
    ('sac_survie_134', 1200),
    ('plaque_kevlar_avancee', 1200),
    ('gilet_tactique_survie_avance', 1200),
    ('kit_reparation_auto', 1200),
    ('kit_reparation_arme_blanche', 1200),
    ('kit_reparation_arme_feu', 1200),
    ('kit_reparation_arme_auto', 1200),
    ('grenade_fumigene', 1200),
    ('grenade_fragmentation', 1200),
    -- Coffres (craft)
    ('coffre_securite_12h', 2000),
    ('coffre_securite_24h', 2000),
    ('coffre_securite_72h', 2000),
    ('coffre_securite_96h', 2000),
    ('coffre_securite_120h', 2000),
    ('coffre_securite_144h', 2000),
    ('coffre_securite_168h', 2000),
    -- Coffres (boutique)
    ('coffre_boutique_32_7j', 0),
    ('coffre_boutique_64_14j', 0),
    ('coffre_boutique_72_21j', 0),
    ('coffre_boutique_104_28j', 0),
    ('coffre_boutique_134_35j', 0);


-- ─── 4. Vérification ───────────────────────────────────────────────
-- Items déclarés dans items.lua mais sans valeur : la requête doit
-- ne rien renvoyer. Si elle renvoie quelque chose, ces items ne
-- pourront pas être payés en capsules.
-- SELECT i.item FROM rz_craft_ingredients i
-- LEFT JOIN rz_item_values v ON v.item = i.item
-- WHERE v.item IS NULL;
