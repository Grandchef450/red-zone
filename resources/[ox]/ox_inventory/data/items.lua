-- ═══════════════════════════════════════════════════════════════
--  REDZONE SURVIVAL — data/items.lua
--  Généré depuis le tableau « items et crafting RedZone Survival »
--
--  RÈGLE : l'identifiant (entre crochets) est la CLÉ EN BASE.
--  Ne jamais le modifier une fois des joueurs en jeu — les items
--  de leur inventaire deviendraient introuvables.
--  Le 'label' peut être changé librement, il n'est qu'affiché.
--
--  AUCUNE PÉREMPTION : pas un seul item n'a de champ 'degrade'.
--  Rien ne pourrit, rien n'expire. C'est volontaire.
--
--  POIDS : tout item empilable pèse au maximum 600 g. Avec une
--  capacité joueur de 120 000 g (setr inventory:weight 120000),
--  cela garantit au moins 200 unités de n'importe quel matériau.
-- ═══════════════════════════════════════════════════════════════

return {

	-- ─── DÉPART ────────────────────────────────────────
	['couteau_suisse'] = {
		label = 'Couteau suisse',
		weight = 200,
		stack = false,
		client = {
			image = 'couteau_suisse.png',
		},
	},
	['lampe_poche'] = {
		label = 'Lampe de poche',
		weight = 400,
		stack = false,
		client = {
			image = 'lampe_poche.png',
		},
	},
	['batterie'] = {
		label = 'Batterie',
		weight = 250,
		client = {
			image = 'batterie.png',
		},
	},
	['capsule'] = {
		label = 'Capsule',
		weight = 5,
		client = {
			image = 'capsule.png',
		},
	},
	['ration_mre'] = {
		label = 'Ration MRE',
		weight = 600,
		close = true,
		client = {
			image = 'ration_mre.png',
		},
	},

	-- ─── RÉCUPÉRATION ──────────────────────────────────
	['ferraille'] = {
		label = 'Ferraille',
		weight = 300,
		client = {
			image = 'ferraille.png',
		},
	},
	['carton'] = {
		label = 'Carton',
		weight = 100,
		client = {
			image = 'carton.png',
		},
	},
	['plastique'] = {
		label = 'Plastique',
		weight = 120,
		client = {
			image = 'plastique.png',
		},
	},
	['caoutchouc'] = {
		label = 'Caoutchouc',
		weight = 180,
		client = {
			image = 'caoutchouc.png',
		},
	},
	['ruban_adhesif'] = {
		label = 'Ruban adhésif',
		weight = 120,
		client = {
			image = 'ruban_adhesif.png',
		},
	},
	['fil_fer'] = {
		label = 'Fil de fer',
		weight = 150,
		client = {
			image = 'fil_fer.png',
		},
	},
	['ficelle'] = {
		label = 'Ficelle',
		weight = 60,
		client = {
			image = 'ficelle.png',
		},
	},
	['tissu_use'] = {
		label = 'Bout de tissu usé',
		weight = 80,
		client = {
			image = 'tissu_use.png',
		},
	},
	['tube_cuivre'] = {
		label = 'Tube de cuivre',
		weight = 250,
		client = {
			image = 'tube_cuivre.png',
		},
	},
	['verre'] = {
		label = 'Verre',
		weight = 200,
		client = {
			image = 'verre.png',
		},
	},
	['collier_argent'] = {
		label = 'Collier en argent',
		weight = 120,
		client = {
			image = 'collier_argent.png',
		},
	},
	['fil_nylon'] = {
		label = 'Fil de nylon',
		weight = 50,
		client = {
			image = 'fil_nylon.png',
		},
	},
	['bracelet_or'] = {
		label = 'Bracelet en or',
		weight = 150,
		client = {
			image = 'bracelet_or.png',
		},
	},
	['batterie_usee'] = {
		label = 'Batterie usée',
		weight = 250,
		client = {
			image = 'batterie_usee.png',
		},
	},
	['ressort'] = {
		label = 'Ressort',
		weight = 90,
		client = {
			image = 'ressort.png',
		},
	},
	['morceau_bois'] = {
		label = 'Morceau de bois',
		weight = 250,
		client = {
			image = 'morceau_bois.png',
		},
	},
	['bouteille_eau_sale'] = {
		label = 'Bouteille d\'eau sale',
		weight = 550,
		client = {
			image = 'bouteille_eau_sale.png',
		},
	},
	['chaussette_blanche'] = {
		label = 'Chaussette blanche',
		weight = 50,
		client = {
			image = 'chaussette_blanche.png',
		},
	},
	['roche_eau'] = {
		label = 'Roche d\'eau',
		weight = 400,
		client = {
			image = 'roche_eau.png',
		},
	},
	['sable'] = {
		label = 'Sable',
		weight = 300,
		client = {
			image = 'sable.png',
		},
	},
	['cafe_colombien_sachet'] = {
		label = 'Café colombien (sachet)',
		weight = 120,
		client = {
			image = 'cafe_colombien_sachet.png',
		},
	},
	['cafe_moulu_sachet'] = {
		label = 'Café moulu (sachet)',
		weight = 120,
		client = {
			image = 'cafe_moulu_sachet.png',
		},
	},
	['cle_molette'] = {
		label = 'Clé à molette',
		weight = 700,
		stack = false,
		client = {
			image = 'cle_molette.png',
		},
	},
	['tuyau_caoutchouc'] = {
		label = 'Tuyau en caoutchouc',
		weight = 350,
		client = {
			image = 'tuyau_caoutchouc.png',
		},
	},
	['tuyau_plastique'] = {
		label = 'Tuyau en plastique',
		weight = 300,
		client = {
			image = 'tuyau_plastique.png',
		},
	},
	['colle_construction'] = {
		label = 'Colle de construction',
		weight = 200,
		client = {
			image = 'colle_construction.png',
		},
	},
	['elastique'] = {
		label = 'Élastique',
		weight = 30,
		client = {
			image = 'elastique.png',
		},
	},
	['sel'] = {
		label = 'Sel',
		weight = 100,
		client = {
			image = 'sel.png',
		},
	},
	['aiguille_crochet'] = {
		label = 'Aiguille en crochet',
		weight = 40,
		client = {
			image = 'aiguille_crochet.png',
		},
	},
	['cle_cric'] = {
		label = 'Clé pour cric',
		weight = 500,
		stack = false,
		client = {
			image = 'cle_cric.png',
		},
	},

	-- ─── CHASSE ────────────────────────────────────────
	['viande_cerf_crue'] = {
		label = 'Viande de cerf crue',
		weight = 600,
		client = {
			image = 'viande_cerf_crue.png',
		},
	},
	['viande_lapin_crue'] = {
		label = 'Viande de lapin crue',
		weight = 400,
		client = {
			image = 'viande_lapin_crue.png',
		},
	},
	['filet_truite_cru'] = {
		label = 'Filet de truite cru',
		weight = 350,
		client = {
			image = 'filet_truite_cru.png',
		},
	},
	['steak_requin_cru'] = {
		label = 'Steak de requin cru',
		weight = 600,
		client = {
			image = 'steak_requin_cru.png',
		},
	},
	['pave_saumon_cru'] = {
		label = 'Pavé de saumon cru',
		weight = 400,
		client = {
			image = 'pave_saumon_cru.png',
		},
	},
	['viande_cougar_crue'] = {
		label = 'Viande de cougar crue',
		weight = 600,
		client = {
			image = 'viande_cougar_crue.png',
		},
	},
	['viande_boeuf_crue'] = {
		label = 'Viande de bœuf crue',
		weight = 600,
		client = {
			image = 'viande_boeuf_crue.png',
		},
	},
	['filet_morue_cru'] = {
		label = 'Filet de morue cru',
		weight = 380,
		client = {
			image = 'filet_morue_cru.png',
		},
	},
	['gras_animal'] = {
		label = 'Gras animal',
		weight = 300,
		client = {
			image = 'gras_animal.png',
		},
	},

	-- ─── CUISSON ───────────────────────────────────────
	['steak_cerf'] = {
		label = 'Steak de cerf',
		weight = 600,
		close = true,
		client = {
			image = 'steak_cerf.png',
		},
	},
	['cuisse_lapin'] = {
		label = 'Cuisse de lapin',
		weight = 350,
		close = true,
		client = {
			image = 'cuisse_lapin.png',
		},
	},
	['filet_truite'] = {
		label = 'Filet de truite',
		weight = 300,
		close = true,
		client = {
			image = 'filet_truite.png',
		},
	},
	['steak_requin'] = {
		label = 'Steak de requin',
		weight = 600,
		close = true,
		client = {
			image = 'steak_requin.png',
		},
	},
	['pave_saumon'] = {
		label = 'Pavé de saumon',
		weight = 350,
		close = true,
		client = {
			image = 'pave_saumon.png',
		},
	},
	['cote_cougar'] = {
		label = 'Côte de cougar',
		weight = 600,
		close = true,
		client = {
			image = 'cote_cougar.png',
		},
	},
	['steak_boeuf'] = {
		label = 'Steak de bœuf',
		weight = 600,
		close = true,
		client = {
			image = 'steak_boeuf.png',
		},
	},
	['filet_morue'] = {
		label = 'Filet de morue',
		weight = 330,
		close = true,
		client = {
			image = 'filet_morue.png',
		},
	},
	['huile_reparation'] = {
		label = 'Huile de réparation',
		weight = 400,
		client = {
			image = 'huile_reparation.png',
		},
	},
	['viande_boeuf_sechee'] = {
		label = 'Viande de bœuf séchée',
		weight = 300,
		close = true,
		client = {
			image = 'viande_boeuf_sechee.png',
		},
	},
	['viande_cougar_sechee'] = {
		label = 'Viande de cougar séchée',
		weight = 280,
		close = true,
		client = {
			image = 'viande_cougar_sechee.png',
		},
	},
	['poisson_seche'] = {
		label = 'Poisson séché',
		weight = 200,
		close = true,
		client = {
			image = 'poisson_seche.png',
		},
	},

	-- ─── PLATS AVANCÉS ─────────────────────────────────
	['civet_cerf'] = {
		label = 'Civet de cerf',
		weight = 600,
		close = true,
		client = {
			image = 'civet_cerf.png',
		},
	},
	['lapin_moutarde'] = {
		label = 'Lapin à la moutarde',
		weight = 500,
		close = true,
		client = {
			image = 'lapin_moutarde.png',
		},
	},
	['boeuf_carottes'] = {
		label = 'Bœuf aux carottes',
		weight = 600,
		close = true,
		client = {
			image = 'boeuf_carottes.png',
		},
	},
	['truite_meuniere'] = {
		label = 'Truite meunière',
		weight = 420,
		close = true,
		client = {
			image = 'truite_meuniere.png',
		},
	},
	['morue_biere'] = {
		label = 'Morue à la bière',
		weight = 450,
		close = true,
		client = {
			image = 'morue_biere.png',
		},
	},
	['requin_poche'] = {
		label = 'Requin poché',
		weight = 600,
		close = true,
		client = {
			image = 'requin_poche.png',
		},
	},
	['papillote_saumon'] = {
		label = 'Papillote de saumon',
		weight = 480,
		close = true,
		client = {
			image = 'papillote_saumon.png',
		},
	},
	['cote_cougar_grillee'] = {
		label = 'Côte de cougar grillée',
		weight = 600,
		close = true,
		client = {
			image = 'cote_cougar_grillee.png',
		},
	},

	-- ─── BOISSONS ──────────────────────────────────────
	['cafe_torrefie'] = {
		label = 'Café torréfié',
		weight = 150,
		client = {
			image = 'cafe_torrefie.png',
		},
	},
	['cafe_infuse'] = {
		label = 'Café infusé',
		weight = 400,
		close = true,
		client = {
			image = 'cafe_infuse.png',
		},
	},
	['eau_purifiee'] = {
		label = 'Eau purifiée',
		weight = 550,
		close = true,
		client = {
			image = 'eau_purifiee.png',
		},
	},

	-- ─── MINERAIS ──────────────────────────────────────
	['minerai_fer'] = {
		label = 'Minerai de fer',
		weight = 600,
		client = {
			image = 'minerai_fer.png',
		},
	},
	['minerai_aluminium'] = {
		label = 'Minerai d\'aluminium',
		weight = 600,
		client = {
			image = 'minerai_aluminium.png',
		},
	},
	['minerai_cuivre'] = {
		label = 'Minerai de cuivre',
		weight = 600,
		client = {
			image = 'minerai_cuivre.png',
		},
	},
	['minerai_charbon'] = {
		label = 'Minerai de charbon',
		weight = 500,
		client = {
			image = 'minerai_charbon.png',
		},
	},
	['minerai_soufre'] = {
		label = 'Minerai de soufre',
		weight = 450,
		client = {
			image = 'minerai_soufre.png',
		},
	},
	['minerai_magnesium'] = {
		label = 'Minerai de magnésium',
		weight = 550,
		client = {
			image = 'minerai_magnesium.png',
		},
	},
	['pierre_silex'] = {
		label = 'Pierre de silex',
		weight = 300,
		client = {
			image = 'pierre_silex.png',
		},
	},
	['minerai_graphite'] = {
		label = 'Minerai de graphite',
		weight = 500,
		client = {
			image = 'minerai_graphite.png',
		},
	},
	['minerai_silicium'] = {
		label = 'Minerai de silicium',
		weight = 500,
		client = {
			image = 'minerai_silicium.png',
		},
	},
	['minerai_or'] = {
		label = 'Minerai d\'or',
		weight = 600,
		client = {
			image = 'minerai_or.png',
		},
	},
	['minerai_argent'] = {
		label = 'Minerai d\'argent',
		weight = 600,
		client = {
			image = 'minerai_argent.png',
		},
	},

	-- ─── FONDERIE ──────────────────────────────────────
	['lingot_fer'] = {
		label = 'Lingot de fer',
		weight = 600,
		client = {
			image = 'lingot_fer.png',
		},
	},
	['lingot_aluminium'] = {
		label = 'Lingot d\'aluminium',
		weight = 600,
		client = {
			image = 'lingot_aluminium.png',
		},
	},
	['lingot_cuivre'] = {
		label = 'Lingot de cuivre',
		weight = 600,
		client = {
			image = 'lingot_cuivre.png',
		},
	},
	['charbon'] = {
		label = 'Charbon',
		weight = 400,
		client = {
			image = 'charbon.png',
		},
	},
	['poudre_soufre'] = {
		label = 'Poudre de soufre',
		weight = 200,
		client = {
			image = 'poudre_soufre.png',
		},
	},
	['lingot_magnesium'] = {
		label = 'Lingot de magnésium',
		weight = 600,
		client = {
			image = 'lingot_magnesium.png',
		},
	},
	['carbone'] = {
		label = 'Carbone',
		weight = 300,
		client = {
			image = 'carbone.png',
		},
	},
	['lingot_inox'] = {
		label = 'Lingot d\'inox',
		weight = 600,
		client = {
			image = 'lingot_inox.png',
		},
	},
	['brique_ceramique'] = {
		label = 'Brique de céramique',
		weight = 600,
		client = {
			image = 'brique_ceramique.png',
		},
	},
	['verre_concasse'] = {
		label = 'Verre concassé',
		weight = 250,
		client = {
			image = 'verre_concasse.png',
		},
	},
	['plastique_concasse'] = {
		label = 'Plastique concassé',
		weight = 150,
		client = {
			image = 'plastique_concasse.png',
		},
	},
	['lingot_or'] = {
		label = 'Lingot d\'or',
		weight = 600,
		client = {
			image = 'lingot_or.png',
		},
	},
	['lingot_argent'] = {
		label = 'Lingot d\'argent',
		weight = 600,
		client = {
			image = 'lingot_argent.png',
		},
	},

	-- ─── TRANSFORMATION ────────────────────────────────
	['tube_fer'] = {
		label = 'Tube de fer',
		weight = 400,
		client = {
			image = 'tube_fer.png',
		},
	},
	['tube_aluminium'] = {
		label = 'Tube d\'aluminium',
		weight = 280,
		client = {
			image = 'tube_aluminium.png',
		},
	},
	['tube_inox'] = {
		label = 'Tube d\'inox',
		weight = 420,
		client = {
			image = 'tube_inox.png',
		},
	},
	['tube_carbone'] = {
		label = 'Tube de carbone',
		weight = 200,
		client = {
			image = 'tube_carbone.png',
		},
	},
	['barre_magnesium'] = {
		label = 'Barre de magnésium',
		weight = 350,
		client = {
			image = 'barre_magnesium.png',
		},
	},
	['fluorocarbone'] = {
		label = 'Fluorocarbone',
		weight = 180,
		client = {
			image = 'fluorocarbone.png',
		},
	},
	['plaque_fer'] = {
		label = 'Plaque de fer',
		weight = 600,
		client = {
			image = 'plaque_fer.png',
		},
	},
	['plaque_aluminium'] = {
		label = 'Plaque d\'aluminium',
		weight = 400,
		client = {
			image = 'plaque_aluminium.png',
		},
	},
	['plaque_cuivre'] = {
		label = 'Plaque de cuivre',
		weight = 550,
		client = {
			image = 'plaque_cuivre.png',
		},
	},
	['plaque_inox'] = {
		label = 'Plaque d\'inox',
		weight = 600,
		client = {
			image = 'plaque_inox.png',
		},
	},
	['plaque_verre'] = {
		label = 'Plaque de verre',
		weight = 500,
		client = {
			image = 'plaque_verre.png',
		},
	},
	['plaque_plastique'] = {
		label = 'Plaque de plastique',
		weight = 300,
		client = {
			image = 'plaque_plastique.png',
		},
	},
	['poudre_magnesium'] = {
		label = 'Poudre de magnésium',
		weight = 150,
		client = {
			image = 'poudre_magnesium.png',
		},
	},
	['poudre_carbone'] = {
		label = 'Poudre de carbone',
		weight = 140,
		client = {
			image = 'poudre_carbone.png',
		},
	},
	['poudre_inox'] = {
		label = 'Poudre d\'inox',
		weight = 160,
		client = {
			image = 'poudre_inox.png',
		},
	},
	['poudre_silice'] = {
		label = 'Poudre de silice',
		weight = 130,
		client = {
			image = 'poudre_silice.png',
		},
	},
	['poudre_aluminium'] = {
		label = 'Poudre d\'aluminium',
		weight = 120,
		client = {
			image = 'poudre_aluminium.png',
		},
	},
	['poudre_diamant'] = {
		label = 'Poudre de diamant',
		weight = 100,
		client = {
			image = 'poudre_diamant.png',
		},
	},
	['fil_cuivre'] = {
		label = 'Fil de cuivre',
		weight = 140,
		client = {
			image = 'fil_cuivre.png',
		},
	},
	['piece_or'] = {
		label = 'Pièce d\'or',
		weight = 50,
		client = {
			image = 'piece_or.png',
		},
	},
	['piece_argent'] = {
		label = 'Pièce d\'argent',
		weight = 45,
		client = {
			image = 'piece_argent.png',
		},
	},

	-- ─── CRAFT PHASE 1 ─────────────────────────────────
	['allumettes'] = {
		label = 'Allumettes',
		weight = 50,
		client = {
			image = 'allumettes.png',
		},
	},
	['allumeur_survie'] = {
		label = 'Allumeur de survie',
		weight = 150,
		stack = false,
		client = {
			image = 'allumeur_survie.png',
		},
	},
	['rechargeur_batterie'] = {
		label = 'Rechargeur de batterie',
		weight = 800,
		stack = false,
		client = {
			image = 'rechargeur_batterie.png',
		},
	},
	['bandage_survie'] = {
		label = 'Bandage de survie',
		weight = 100,
		close = true,
		client = {
			image = 'bandage_survie.png',
		},
	},
	['attelle_survie'] = {
		label = 'Attelle de survie',
		weight = 300,
		close = true,
		client = {
			image = 'attelle_survie.png',
		},
	},
	['cartouche_9mm_cuivre'] = {
		label = 'Cartouche 9mm (cuivre)',
		weight = 8,
		client = {
			image = 'cartouche_9mm_cuivre.png',
		},
	},
	['cartouche_9mm_acier'] = {
		label = 'Cartouche 9mm (acier)',
		weight = 8,
		client = {
			image = 'cartouche_9mm_acier.png',
		},
	},
	['cartouche_9mm_alu'] = {
		label = 'Cartouche 9mm (aluminium)',
		weight = 6,
		client = {
			image = 'cartouche_9mm_alu.png',
		},
	},
	['poudre_noire'] = {
		label = 'Poudre noire',
		weight = 150,
		client = {
			image = 'poudre_noire.png',
		},
	},
	['corde_survie'] = {
		label = 'Corde de survie',
		weight = 500,
		client = {
			image = 'corde_survie.png',
		},
	},
	['fil_peche'] = {
		label = 'Fil de pêche',
		weight = 60,
		client = {
			image = 'fil_peche.png',
		},
	},
	['chaudron_acier'] = {
		label = 'Chaudron en acier',
		weight = 2500,
		stack = false,
		client = {
			image = 'chaudron_acier.png',
		},
	},
	['couteau_survie'] = {
		label = 'Couteau de survie',
		weight = 300,
		stack = false,
		client = {
			image = 'couteau_survie.png',
		},
	},
	['lance_survie'] = {
		label = 'Lance de survie',
		weight = 1200,
		stack = false,
		client = {
			image = 'lance_survie.png',
		},
	},
	['aiguisoir_survie'] = {
		label = 'Aiguisoir de survie',
		weight = 400,
		stack = false,
		client = {
			image = 'aiguisoir_survie.png',
		},
	},
	['purificateur_eau_survie'] = {
		label = 'Purificateur d\'eau de survie',
		weight = 800,
		stack = false,
		client = {
			image = 'purificateur_eau_survie.png',
		},
	},
	['filtre_tous_usages'] = {
		label = 'Filtre tous usages',
		weight = 200,
		client = {
			image = 'filtre_tous_usages.png',
		},
	},
	['detonateur_9mm'] = {
		label = 'Détonateur 9mm',
		weight = 10,
		client = {
			image = 'detonateur_9mm.png',
		},
	},
	['detonateur_45acp'] = {
		label = 'Détonateur .45 ACP',
		weight = 12,
		client = {
			image = 'detonateur_45acp.png',
		},
	},
	['bbq_survie'] = {
		label = 'BBQ de survie',
		weight = 4000,
		stack = false,
		client = {
			image = 'bbq_survie.png',
		},
	},
	['jerrican'] = {
		label = 'Jerrican',
		weight = 1500,
		stack = false,
		client = {
			image = 'jerrican.png',
		},
	},
	['pioche_minage'] = {
		label = 'Pioche de minage',
		weight = 2200,
		stack = false,
		client = {
			image = 'pioche_minage.png',
		},
	},
	['outils_jardinage'] = {
		label = 'Outils de jardinage',
		weight = 1000,
		stack = false,
		client = {
			image = 'outils_jardinage.png',
		},
	},
	['arrosoir_metal'] = {
		label = 'Arrosoir en métal',
		weight = 900,
		stack = false,
		client = {
			image = 'arrosoir_metal.png',
		},
	},
	['cric_auto'] = {
		label = 'Cric d\'auto',
		weight = 3000,
		stack = false,
		client = {
			image = 'cric_auto.png',
		},
	},

	-- ─── CRAFT PHASE 2 ─────────────────────────────────
	['chaudron_cuivre'] = {
		label = 'Chaudron en cuivre',
		weight = 2600,
		stack = false,
		client = {
			image = 'chaudron_cuivre.png',
		},
	},
	['couteau_acier'] = {
		label = 'Couteau en acier',
		weight = 320,
		stack = false,
		client = {
			image = 'couteau_acier.png',
		},
	},
	['lance_acier'] = {
		label = 'Lance en acier',
		weight = 1300,
		stack = false,
		client = {
			image = 'lance_acier.png',
		},
	},
	['canne_peche'] = {
		label = 'Canne à pêche',
		weight = 1000,
		stack = false,
		client = {
			image = 'canne_peche.png',
		},
	},
	['aiguisoir_avance'] = {
		label = 'Aiguisoir avancé',
		weight = 450,
		stack = false,
		client = {
			image = 'aiguisoir_avance.png',
		},
	},
	['purificateur_eau_avance'] = {
		label = 'Purificateur d\'eau avancé',
		weight = 900,
		stack = false,
		client = {
			image = 'purificateur_eau_avance.png',
		},
	},
	['balle_9mm_acier'] = {
		label = 'Balle 9mm (acier)',
		weight = 12,
		client = {
			image = 'balle_9mm_acier.png',
		},
	},
	['balle_9mm_cuivre'] = {
		label = 'Balle 9mm (cuivre)',
		weight = 12,
		client = {
			image = 'balle_9mm_cuivre.png',
		},
	},
	['balle_9mm_alu'] = {
		label = 'Balle 9mm (aluminium)',
		weight = 10,
		client = {
			image = 'balle_9mm_alu.png',
		},
	},
	['presse_rechargement'] = {
		label = 'Presse de rechargement',
		weight = 5000,
		stack = false,
		client = {
			image = 'presse_rechargement.png',
		},
	},
	['cartouche_45_acier'] = {
		label = 'Cartouche .45 (acier)',
		weight = 10,
		client = {
			image = 'cartouche_45_acier.png',
		},
	},
	['cartouche_45_cuivre'] = {
		label = 'Cartouche .45 (cuivre)',
		weight = 10,
		client = {
			image = 'cartouche_45_cuivre.png',
		},
	},
	['cartouche_45_alu'] = {
		label = 'Cartouche .45 (aluminium)',
		weight = 8,
		client = {
			image = 'cartouche_45_alu.png',
		},
	},
	['cartouche_45_inox'] = {
		label = 'Cartouche .45 (inox)',
		weight = 11,
		client = {
			image = 'cartouche_45_inox.png',
		},
	},
	['cartouche_45_carbone'] = {
		label = 'Cartouche .45 (carbone)',
		weight = 7,
		client = {
			image = 'cartouche_45_carbone.png',
		},
	},
	['bbq_avance'] = {
		label = 'BBQ avancé',
		weight = 4500,
		stack = false,
		client = {
			image = 'bbq_avance.png',
		},
	},
	['chargeur_9mm_16'] = {
		label = 'Chargeur 9mm x16 universel',
		weight = 400,
		stack = false,
		client = {
			image = 'chargeur_9mm_16.png',
		},
	},
	['chargeur_45acp_16'] = {
		label = 'Chargeur .45 ACP x16 universel',
		weight = 450,
		stack = false,
		client = {
			image = 'chargeur_45acp_16.png',
		},
	},

	-- ─── CRAFT PHASE 3 ─────────────────────────────────
	['chaudron_fonte'] = {
		label = 'Chaudron en fonte',
		weight = 3500,
		stack = false,
		client = {
			image = 'chaudron_fonte.png',
		},
	},
	['couteau_aluminium'] = {
		label = 'Couteau en aluminium',
		weight = 250,
		stack = false,
		client = {
			image = 'couteau_aluminium.png',
		},
	},
	['lance_aluminium'] = {
		label = 'Lance en aluminium',
		weight = 1000,
		stack = false,
		client = {
			image = 'lance_aluminium.png',
		},
	},
	['canne_peche_carbone'] = {
		label = 'Canne à pêche en carbone',
		weight = 700,
		stack = false,
		client = {
			image = 'canne_peche_carbone.png',
		},
	},
	['balle_45_acier'] = {
		label = 'Balle .45 ACP (acier)',
		weight = 15,
		client = {
			image = 'balle_45_acier.png',
		},
	},
	['balle_45_cuivre'] = {
		label = 'Balle .45 ACP (cuivre)',
		weight = 15,
		client = {
			image = 'balle_45_cuivre.png',
		},
	},
	['balle_45_alu'] = {
		label = 'Balle .45 ACP (aluminium)',
		weight = 12,
		client = {
			image = 'balle_45_alu.png',
		},
	},
	['balle_45_inox'] = {
		label = 'Balle .45 ACP (inox)',
		weight = 16,
		client = {
			image = 'balle_45_inox.png',
		},
	},
	['balle_45_carbone'] = {
		label = 'Balle .45 ACP (carbone)',
		weight = 10,
		client = {
			image = 'balle_45_carbone.png',
		},
	},
	['cellule_photovoltaique'] = {
		label = 'Cellule photovoltaïque',
		weight = 300,
		client = {
			image = 'cellule_photovoltaique.png',
		},
	},
	['panneau_photovoltaique'] = {
		label = 'Panneau photovoltaïque',
		weight = 4000,
		stack = false,
		client = {
			image = 'panneau_photovoltaique.png',
		},
	},
	['rechargeur_photovoltaique'] = {
		label = 'Rechargeur photovoltaïque',
		weight = 1200,
		stack = false,
		client = {
			image = 'rechargeur_photovoltaique.png',
		},
	},
	['batterie_stockage'] = {
		label = 'Batterie de stockage',
		weight = 3000,
		stack = false,
		client = {
			image = 'batterie_stockage.png',
		},
	},
	['siphon_manuel'] = {
		label = 'Siphon manuel',
		weight = 800,
		stack = false,
		client = {
			image = 'siphon_manuel.png',
		},
	},
	['chargeur_45acp_15'] = {
		label = 'Chargeur .45 ACP x15',
		weight = 420,
		stack = false,
		client = {
			image = 'chargeur_45acp_15.png',
		},
	},
	['chargeur_45acp_20'] = {
		label = 'Chargeur .45 ACP x20',
		weight = 500,
		stack = false,
		client = {
			image = 'chargeur_45acp_20.png',
		},
	},
	['chargeur_45acp_camembert_20'] = {
		label = 'Chargeur camembert .45 ACP x20',
		weight = 650,
		stack = false,
		client = {
			image = 'chargeur_45acp_camembert_20.png',
		},
	},

	-- ─── CRAFT PHASE 4 ─────────────────────────────────
	['chaudron_fonte_electrique'] = {
		label = 'Chaudron en fonte électrique',
		weight = 5000,
		stack = false,
		client = {
			image = 'chaudron_fonte_electrique.png',
		},
	},
	['plaque_kevlar'] = {
		label = 'Plaque de kevlar',
		weight = 600,
		client = {
			image = 'plaque_kevlar.png',
		},
	},
	['gilet_tactique_survie'] = {
		label = 'Gilet tactique de survie',
		weight = 3500,
		stack = false,
		client = {
			image = 'gilet_tactique_survie.png',
		},
	},
	['couteau_inox'] = {
		label = 'Couteau en inox',
		weight = 330,
		stack = false,
		client = {
			image = 'couteau_inox.png',
		},
	},
	['canne_peche_fibre_verre'] = {
		label = 'Canne à pêche en fibre de verre',
		weight = 800,
		stack = false,
		client = {
			image = 'canne_peche_fibre_verre.png',
		},
	},
	['trousse_premiers_soins'] = {
		label = 'Trousse de premiers soins',
		weight = 600,
		close = true,
		client = {
			image = 'trousse_premiers_soins.png',
		},
	},
	['imprimerie_pieces_or'] = {
		label = 'Imprimerie pour pièces d\'or',
		weight = 6000,
		stack = false,
		client = {
			image = 'imprimerie_pieces_or.png',
		},
	},
	['imprimerie_pieces_argent'] = {
		label = 'Imprimerie pour pièces d\'argent',
		weight = 6000,
		stack = false,
		client = {
			image = 'imprimerie_pieces_argent.png',
		},
	},
	['batterie_stockage_reutilisable'] = {
		label = 'Batterie de stockage réutilisable',
		weight = 3200,
		stack = false,
		client = {
			image = 'batterie_stockage_reutilisable.png',
		},
	},
	['siphon_automatique'] = {
		label = 'Siphon automatique',
		weight = 1100,
		stack = false,
		client = {
			image = 'siphon_automatique.png',
		},
	},

	-- ─── CRAFT PHASE 5 ─────────────────────────────────
	['plaque_kevlar_avancee'] = {
		label = 'Plaque de kevlar avancée',
		weight = 600,
		client = {
			image = 'plaque_kevlar_avancee.png',
		},
	},
	['gilet_tactique_survie_avance'] = {
		label = 'Gilet tactique de survie avancé',
		weight = 3800,
		stack = false,
		client = {
			image = 'gilet_tactique_survie_avance.png',
		},
	},
	['kit_reparation_auto'] = {
		label = 'Kit de réparation auto',
		weight = 600,
		close = true,
		client = {
			image = 'kit_reparation_auto.png',
		},
	},
	['kit_reparation_arme_blanche'] = {
		label = 'Kit de réparation arme blanche',
		weight = 600,
		close = true,
		client = {
			image = 'kit_reparation_arme_blanche.png',
		},
	},
	['kit_reparation_arme_feu'] = {
		label = 'Kit de réparation arme à feu',
		weight = 600,
		close = true,
		client = {
			image = 'kit_reparation_arme_feu.png',
		},
	},
	['kit_reparation_arme_auto'] = {
		label = 'Kit de réparation arme automatique',
		weight = 600,
		close = true,
		client = {
			image = 'kit_reparation_arme_auto.png',
		},
	},
	['grenade_fumigene'] = {
		label = 'Grenade fumigène',
		weight = 500,
		stack = false,
		client = {
			image = 'grenade_fumigene.png',
		},
	},
	['grenade_fragmentation'] = {
		label = 'Grenade à fragmentation',
		weight = 550,
		stack = false,
		client = {
			image = 'grenade_fragmentation.png',
		},
	},

	-- ─── SACS À DOS ────────────────────────────────────
	['sac_survie_12'] = {
		label = 'Sac à dos de survie (12)',
		weight = 1200,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_de_suivie_12P.png',
		},
	},
	['sac_cafe_20'] = {
		label = 'Sac de café (20)',
		weight = 1400,
		stack = false,
		durability = true,
		client = {
			image = 'sac_de_cafe_20p.png',
		},
	},
	['sac_survie_24'] = {
		label = 'Petit sac à dos (24)',
		weight = 1600,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_petit_24P.png',
		},
	},
	['sac_survie_32'] = {
		label = 'Sac à dos moyen (32)',
		weight = 2000,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_moyen_32P.png',
		},
	},
	['sac_medical_50'] = {
		label = 'Sac médical (50)',
		weight = 2300,
		stack = false,
		durability = true,
		client = {
			image = 'sac_medical_50p.png',
		},
	},
	['sac_survie_64'] = {
		label = 'Sac à dos moyen (64)',
		weight = 2600,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_moyen_64P.png',
		},
	},
	['sac_survie_72'] = {
		label = 'Sac à dos très grand (72)',
		weight = 3000,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_tres_grand_72P.png',
		},
	},
	['sac_survie_104'] = {
		label = 'Sac de randonneur survie (104)',
		weight = 3600,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_Randonneur_survie_104P.png',
		},
	},
	['sac_survie_134'] = {
		label = 'Sac de randonneur petit (134)',
		weight = 4200,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_Randonneur_petit_134P.png',
		},
	},
	['sac_survie_158'] = {
		label = 'Sac de randonneur moyen (158)',
		weight = 4600,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_Randonneur_moyen_158P.png',
		},
	},
	['sac_survie_172'] = {
		label = 'Sac de randonneur grand (172)',
		weight = 5000,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_Randonneur_grand_172P.png',
		},
	},
	['sac_survie_200'] = {
		label = 'Sac de randonneur très grand (200)',
		weight = 5600,
		stack = false,
		durability = true,
		client = {
			image = 'Sac_a_dos_Randonneurs_tres_grand_200P.png',
		},
	},

	-- ─── COFFRES (CRAFT) ───────────────────────────────
	['coffre_securite_12h'] = {
		label = 'Coffre de sécurité 12h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_12h.png',
		},
	},
	['coffre_securite_24h'] = {
		label = 'Coffre de sécurité 24h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_24h.png',
		},
	},
	['coffre_securite_72h'] = {
		label = 'Coffre de sécurité 72h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_72h.png',
		},
	},
	['coffre_securite_96h'] = {
		label = 'Coffre de sécurité 96h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_96h.png',
		},
	},
	['coffre_securite_120h'] = {
		label = 'Coffre de sécurité 120h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_120h.png',
		},
	},
	['coffre_securite_144h'] = {
		label = 'Coffre de sécurité 144h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_144h.png',
		},
	},
	['coffre_securite_168h'] = {
		label = 'Coffre de sécurité 168h',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_securite_168h.png',
		},
	},

	-- ─── COFFRES (BOUTIQUE) ────────────────────────────
	['coffre_boutique_32_7j'] = {
		label = 'Coffre de sécurité 32 slots — 7 jours',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_boutique_32_7j.png',
		},
	},
	['coffre_boutique_64_14j'] = {
		label = 'Coffre de sécurité 64 slots — 14 jours',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_boutique_64_14j.png',
		},
	},
	['coffre_boutique_72_21j'] = {
		label = 'Coffre de sécurité 72 slots — 21 jours',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_boutique_72_21j.png',
		},
	},
	['coffre_boutique_104_28j'] = {
		label = 'Coffre de sécurité 104 slots — 28 jours',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_boutique_104_28j.png',
		},
	},
	['coffre_boutique_134_35j'] = {
		label = 'Coffre de sécurité 134 slots — 35 jours',
		weight = 0,
		stack = false,
		client = {
			image = 'coffre_boutique_134_35j.png',
		},
	},

	-- ─── COMMUNICATION ─────────────────────────────────────
	['pager'] = {
		label = 'Pager',
		weight = 180,
		stack = false,
		description = 'Émetteur-récepteur de messages courts. Choisis une fréquence : tous ceux qui l\'écoutent te liront.',
		client = {
			image = 'radio.png',
		},
	},

	-- ─── PROTECTION RADIOLOGIQUE ───────────────────────────
	['cartouche_filtre'] = {
		label = 'Cartouche de filtre',
		weight = 250,
		description = 'Charbon actif comprimé. Ne sert qu\'à fabriquer des masques.',
		client = {
			image = 'cartouche_filtre.png',
		},
	},
	['masque_simple'] = {
		label = 'Masque simple',
		weight = 400,
		stack = false,
		durability = true,
		description = '15 minutes de protection par charge. 5 charges.',
		client = {
			image = 'masque_simple.png',
		},
	},
	['masque_chimique'] = {
		label = 'Masque chimique',
		weight = 600,
		stack = false,
		durability = true,
		description = '30 minutes de protection par charge. 5 charges.',
		client = {
			image = 'masque_chimique.png',
		},
	},
	['masque_cartouche'] = {
		label = 'Masque à cartouche',
		weight = 800,
		stack = false,
		durability = true,
		description = '45 minutes de protection par charge. 5 charges.',
		client = {
			image = 'masque_cartouche.png',
		},
	},
	['masque_double_cartouche'] = {
		label = 'Masque à double cartouche',
		weight = 1000,
		stack = false,
		durability = true,
		description = '1 heure de protection par charge. 5 charges.',
		client = {
			image = 'masque_double_cartouche.png',
		},
	},

	-- ─── SECOURS ───────────────────────────────────────────
	['epipen'] = {
		label = 'Épipen',
		weight = 120,
		stack = true,
		close = true,
		description = 'Injection d\'adrénaline. Le seul objet capable de ramener quelqu\'un à terre — mais il ne rend presque rien.',
		client = {
			image = 'epinefrine.png',
		},
	},

	-- ─── PÊCHE ─────────────────────────────────────────────
	['ver_de_terre'] = {
		label = 'Ver de terre',
		weight = 15,
		description = 'Appât de base. Se ramasse en creusant la terre humide.',
		client = {
			image = 'ver_de_terre.png',
		},
	},
	['appat_artificiel'] = {
		label = 'Appât artificiel',
		weight = 40,
		description = 'Leurre en plastique et fil de nylon. Trois fois plus efficace qu\'un ver.',
		client = {
			image = 'appat_artificiel.png',
		},
	},

	-- ─── LOISIRS ───────────────────────────────────────────
	['boombox'] = {
		label = 'Boombox',
		weight = 3500,
		stack = false,
		close = true,
		description = 'Radiocassette de récupération. Se pose au sol et joue ce qu\'on lui donne.',
		client = {
			image = 'radio.png',
		},
	},
}
