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
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_survie'] = {
		label = 'Attelle de survie',
		weight = 300,
		close = true,
		client = {
			image = 'attelle_survie.png',
			export = 'rz_soins.useSoin',
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
			image = 'medbag.png',
			export = 'rz_soins.useSoin',
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

	-- ─── SOINS ─────────────────────────────────────────────
	-- Effets (points de vie, durées) : définis dans rz_soins, pas ici.
	['pansement_bob'] = {
		label = 'Pansement Bob',
		weight = 10,
		close = true,
		description = 'Petit pansement décoré. Pour les égratignures.',
		client = {
			image = 'pansement_bob.png',
			export = 'rz_soins.useSoin',
		},
	},
	['pansement_dora'] = {
		label = 'Pansement Dora',
		weight = 10,
		close = true,
		description = 'Petit pansement décoré. Pour les égratignures.',
		client = {
			image = 'pansement_dora.png',
			export = 'rz_soins.useSoin',
		},
	},
	['pansement_hello'] = {
		label = 'Pansement Hello Kitty',
		weight = 10,
		close = true,
		description = 'Petit pansement décoré. Pour les égratignures.',
		client = {
			image = 'pansement_hello.png',
			export = 'rz_soins.useSoin',
		},
	},
	['pansement_flash'] = {
		label = 'Pansement Flash',
		weight = 10,
		close = true,
		description = 'Petit pansement décoré. Pour les égratignures.',
		client = {
			image = 'pansement_flash.png',
			export = 'rz_soins.useSoin',
		},
	},
	['bandage'] = {
		label = 'Bandage',
		weight = 50,
		close = true,
		description = 'Bande de gaze. Arrête un saignement léger.',
		client = {
			image = 'bandage.png',
			export = 'rz_soins.useSoin',
		},
	},
	['boite_bandages'] = {
		label = 'Boîte de 10 bandages',
		weight = 500,
		close = true,
		description = 'Se déballe en 10 bandages.',
		client = {
			image = 'boite_bandages.png',
			export = 'rz_soins.useDeballage',
		},
	},
	['kit_medical'] = {
		label = 'Kit médical',
		weight = 600,
		close = true,
		description = 'Trousse complète. Soigne des blessures sérieuses.',
		client = {
			image = 'medikit.png',
			export = 'rz_soins.useSoin',
		},
	},
	['kit_medical_avance'] = {
		label = 'Kit médical avancé',
		weight = 600,
		close = true,
		description = 'Matériel de terrain. Remet quelqu\'un sur pied.',
		client = {
			image = 'advancedkit.png',
			export = 'rz_soins.useSoin',
		},
	},
	['boite_medical_20'] = {
		label = 'Boîte médicale (20)',
		weight = 1500,
		stack = false,
		durability = true,
		description = 'Rangement pour 20 objets médicaux.',
		client = {
			image = 'boite_medical_20.png',
		},
	},
	['kit_perfusion'] = {
		label = 'Kit de perfusion',
		weight = 600,
		close = true,
		description = 'Tuyau, aiguille, poche : la base d\'une perfusion.',
		client = {
			image = 'kit_perfusion.png',
		},
	},
	['kit_perfusion_saline'] = {
		label = 'Perfusion saline',
		weight = 600,
		close = true,
		description = 'Réhydrate et stabilise.',
		client = {
			image = 'kit_perfusion_saline.png',
			export = 'rz_soins.useSoin',
		},
	},
	['kit_perfusion_sanguine'] = {
		label = 'Perfusion sanguine',
		weight = 600,
		close = true,
		description = 'Transfusion. Pour les grosses pertes de sang.',
		client = {
			image = 'kit_perfusion_sanguine.png',
			export = 'rz_soins.useSoin',
		},
	},
	['tuyau_perfusion'] = {
		label = 'Tuyau de perfusion',
		weight = 100,
		description = 'Composant de kit de perfusion.',
		client = {
			image = 'tuyau_perfusion.png',
		},
	},
	['serum_salin'] = {
		label = 'Sérum salin',
		weight = 400,
		close = true,
		description = 'Solution saline stérile.',
		client = {
			image = 'serum_salin.png',
			export = 'rz_soins.useSoin',
		},
	},
	['serum_salin_survie'] = {
		label = 'Sérum salin de survie',
		weight = 300,
		close = true,
		description = 'Version de fortune, moins efficace.',
		client = {
			image = 'serum_salin_survie.png',
			export = 'rz_soins.useSoin',
		},
	},
	['poche_sang'] = {
		label = 'Poche de sang',
		weight = 500,
		description = 'Sang conservé. Indispensable à la transfusion.',
		client = {
			image = 'poche_sang.png',
		},
	},
	['fiole_morphine'] = {
		label = 'Fiole de morphine',
		weight = 100,
		description = 'Concentré. À charger dans une seringue.',
		client = {
			image = 'fiole_morphine.png',
		},
	},
	['seringue_morphine'] = {
		label = 'Seringue de morphine',
		weight = 120,
		close = true,
		description = 'Coupe la douleur, redonne des forces.',
		client = {
			image = 'seringue_morphine.png',
			export = 'rz_soins.useSoin',
		},
	},
	['antidouleur'] = {
		label = 'Antidouleur',
		weight = 50,
		close = true,
		description = 'Comprimés. Soulage, ne soigne pas vraiment.',
		client = {
			image = 'antidouleur.png',
			export = 'rz_soins.useSoin',
		},
	},
	['sirop_medicinal'] = {
		label = 'Sirop médicinal',
		weight = 300,
		close = true,
		description = 'Contre la toux et la fièvre.',
		client = {
			image = 'sirop_medicinal.png',
			export = 'rz_soins.useSoin',
		},
	},
	['xanax'] = {
		label = 'Xanax',
		weight = 50,
		close = true,
		description = 'Calme les nerfs. À ne pas mélanger.',
		client = {
			image = 'xanax.png',
			export = 'rz_soins.useSoin',
		},
	},
	['adrenaline'] = {
		label = 'Adrénaline',
		weight = 100,
		description = 'Ampoule brute. Sert à fabriquer un épipen.',
		client = {
			image = 'adrenaline.png',
		},
	},
	['heparine'] = {
		label = 'Héparine',
		weight = 100,
		close = true,
		description = 'Anticoagulant. Utile en cas d\'hémorragie interne.',
		client = {
			image = 'heparine.png',
			export = 'rz_soins.useSoin',
		},
	},
	['pistolet_injecteur'] = {
		label = 'Pistolet injecteur',
		weight = 600,
		stack = false,
		durability = true,
		description = 'Injecte une ampoule sans seringue.',
		client = {
			image = 'pistolet_injecteur.png',
		},
	},
	['defibrillateur'] = {
		label = 'Défibrillateur',
		weight = 3000,
		stack = false,
		durability = true,
		description = 'Relance un cœur arrêté. Lourd et précieux.',
		client = {
			image = 'defibrillateur.png',
		},
	},
	['aiguille'] = {
		label = 'Aiguille',
		weight = 20,
		description = 'Aiguille simple. Couture ou bricolage.',
		client = {
			image = 'aiguille.png',
		},
	},
	['aiguille_medicale'] = {
		label = 'Aiguille médicale',
		weight = 30,
		description = 'Stérile. Pour seringues et perfusions.',
		client = {
			image = 'aiguille_medicale.png',
		},
	},
	['aiguille_suture'] = {
		label = 'Aiguille à suture',
		weight = 30,
		close = true,
		description = 'Referme une plaie ouverte.',
		client = {
			image = 'aiguille_suture.png',
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_bras'] = {
		label = 'Attelle de bras',
		weight = 400,
		close = true,
		description = 'Immobilise un bras cassé.',
		client = {
			image = 'attelle_bras.png',
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_jambe'] = {
		label = 'Attelle de jambe',
		weight = 600,
		close = true,
		description = 'Immobilise une jambe cassée.',
		client = {
			image = 'attelle_jambe.png',
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_doigts'] = {
		label = 'Attelle de doigts',
		weight = 100,
		close = true,
		description = 'Pour les doigts cassés ou foulés.',
		client = {
			image = 'attelle_doigts.png',
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_poignet'] = {
		label = 'Attelle de poignet',
		weight = 200,
		close = true,
		description = 'Maintient un poignet abîmé.',
		client = {
			image = 'attelle_poignet.png',
			export = 'rz_soins.useSoin',
		},
	},
	['attelle_pression'] = {
		label = 'Attelle à pression',
		weight = 500,
		close = true,
		description = 'Attelle gonflable, s\'adapte à n\'importe quel membre.',
		client = {
			image = 'attelle_pression.png',
			export = 'rz_soins.useSoin',
		},
	},
	['collier_cervical'] = {
		label = 'Collier cervical',
		weight = 400,
		close = true,
		description = 'Maintient la nuque après un choc.',
		client = {
			image = 'collier_cervical.png',
			export = 'rz_soins.useSoin',
		},
	},
	['genouillere'] = {
		label = 'Genouillère',
		weight = 300,
		close = true,
		description = 'Soutient un genou abîmé.',
		client = {
			image = 'genouillere.png',
			export = 'rz_soins.useSoin',
		},
	},
	['cheviliere'] = {
		label = 'Chevillère',
		weight = 200,
		close = true,
		description = 'Soutient une cheville tordue.',
		client = {
			image = 'cheviliere.png',
			export = 'rz_soins.useSoin',
		},
	},
	['couverture_survie'] = {
		label = 'Couverture de survie',
		weight = 150,
		close = true,
		description = 'Contre le froid et l\'état de choc.',
		client = {
			image = 'couverture_survie.png',
			export = 'rz_soins.useSoin',
		},
	},

	-- ─── VIRUS ─────────────────────────────────────────────
	-- Effets (infection, contagion, antidotes) : définis dans rz_soins.
	['virus'] = {
		label = 'Échantillon de virus',
		weight = 100,
		description = 'Fiole scellée. Ne pas ouvrir.',
		client = {
			image = 'virus.png',
		},
	},
	['virus_t'] = {
		label = 'Virus T',
		weight = 100,
		description = 'Souche T. Extrêmement contagieuse.',
		client = {
			image = 'virus_t.png',
		},
	},
	['virus_t_injection'] = {
		label = 'Injection de virus T',
		weight = 120,
		close = true,
		description = 'Seringue chargée de souche T.',
		client = {
			image = 'virus_t_injection.png',
			export = 'rz_soins.useVirus',
		},
	},
	['virus_t_nemesis'] = {
		label = 'Virus T — Némésis',
		weight = 100,
		description = 'Variante Némésis de la souche T.',
		client = {
			image = 'virus_t_nemesis.png',
		},
	},
	['virus_t_veronica'] = {
		label = 'Virus T — Veronica',
		weight = 100,
		description = 'Variante Veronica de la souche T.',
		client = {
			image = 'virus_t_veronica.png',
		},
	},
	['virus_n_injection'] = {
		label = 'Injection de virus N',
		weight = 120,
		close = true,
		description = 'Seringue chargée de souche N.',
		client = {
			image = 'virus_n_injection.png',
			export = 'rz_soins.useVirus',
		},
	},
	['virus_v_injection'] = {
		label = 'Injection de virus V',
		weight = 120,
		close = true,
		description = 'Seringue chargée de souche V.',
		client = {
			image = 'virus_v_injection.png',
			export = 'rz_soins.useVirus',
		},
	},
	['antivirus_t'] = {
		label = 'Antivirus T',
		weight = 100,
		close = true,
		description = 'Antidote à la souche T. Une dose.',
		client = {
			image = 'antivirus_t.png',
		},
	},
	['antivirus_t_injection'] = {
		label = 'Injection d\'antivirus T',
		weight = 120,
		close = true,
		description = 'Antidote injectable, effet immédiat.',
		client = {
			image = 'antivirus_t_injection.png',
			export = 'rz_soins.useVirus',
		},
	},

	-- ─── SOINS (SUITE) ─────────────────────────────────────
	['creme_brulure'] = {
		label = 'Crème contre les brûlures',
		weight = 150,
		close = true,
		description = 'Apaise et referme les brûlures.',
		client = {
			image = 'burncream.png',
			export = 'rz_soins.useSoin',
		},
	},
	['poche_glace'] = {
		label = 'Poche de glace',
		weight = 300,
		close = true,
		description = 'Fait dégonfler les coups et les entorses.',
		client = {
			image = 'icepack.png',
			export = 'rz_soins.useSoin',
		},
	},
	['kit_suture'] = {
		label = 'Kit de suture',
		weight = 400,
		close = true,
		description = 'Aiguille, fil et pince : referme les grandes plaies.',
		client = {
			image = 'suturekit.png',
			export = 'rz_soins.useSoin',
		},
	},
	['pince_epiler'] = {
		label = 'Pince à épiler',
		weight = 40,
		close = true,
		description = 'Pour retirer une balle ou un éclat.',
		client = {
			image = 'tweezers.png',
			export = 'rz_soins.useSoin',
		},
	},
	['defibrillateur_portable'] = {
		label = 'Défibrillateur portable',
		weight = 1500,
		stack = false,
		durability = true,
		description = 'Version compacte. Moins de charges, mais tient dans un sac.',
		client = {
			image = 'defib.png',
		},
	},
	['brancard'] = {
		label = 'Brancard',
		weight = 6000,
		stack = false,
		description = 'Pour transporter un blessé. Encombrant.',
		client = {
			image = 'stretcher.png',
		},
	},

	-- ─── MÉDICAMENTS ───────────────────────────────────────
	-- Bonus temporaires, pas de soin. À la fin de l'effet : retour à
	-- la normale, moins 35 % de faim et de soif. Effets dans rz_soins.
	['percocet_5'] = {
		label = 'Percocet 5 mg',
		weight = 5,
		close = true,
		description = 'Petit comprimé. Le souffle ne manque plus, un moment.',
		client = {
			image = 'perc5.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['percocet_10'] = {
		label = 'Percocet 10 mg',
		weight = 5,
		close = true,
		description = 'Souffle et jambes, un moment.',
		client = {
			image = 'perc10.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['percocet_30'] = {
		label = 'Percocet 30 mg',
		weight = 5,
		close = true,
		description = 'Dose forte. Le corps oublie la fatigue, puis la facture arrive.',
		client = {
			image = 'perc30.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['vicodin_5'] = {
		label = 'Vicodin 5 mg',
		weight = 5,
		close = true,
		description = 'On encaisse un peu plus, un moment.',
		client = {
			image = 'vic5.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['vicodin_10'] = {
		label = 'Vicodin 10 mg',
		weight = 5,
		close = true,
		description = 'On encaisse nettement plus, un moment.',
		client = {
			image = 'vic10.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['morphine_15'] = {
		label = 'Morphine 15 mg',
		weight = 5,
		close = true,
		description = 'Comprimé. Le corps se blinde, un moment.',
		client = {
			image = 'morphine15.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['morphine_30'] = {
		label = 'Morphine 30 mg',
		weight = 5,
		close = true,
		description = 'Comprimé fort. Presque invulnérable, puis vidé.',
		client = {
			image = 'morphine30.png',
			export = 'rz_soins.useMedicament',
		},
	},
	['sedatif'] = {
		label = 'Sédatif',
		weight = 120,
		close = true,
		description = 'Seringue. On ne sent plus les coups, un moment.',
		client = {
			image = 'sedative.png',
			export = 'rz_soins.useMedicament',
		},
	},

	-- ─── DROGUE : CULTURE ──────────────────────────────────
	['graine_cannabis'] = {
		label = 'Graine de cannabis',
		weight = 10,
		description = 'À planter dans un pot.',
		client = {
			image = 'weed_seed.png',
		},
	},
	['pot_culture'] = {
		label = 'Pot de culture',
		weight = 1500,
		stack = false,
		description = 'Terre et pot. Il manque la graine.',
		client = {
			image = 'weed_pot.png',
		},
	},
	['engrais'] = {
		label = 'Engrais',
		weight = 300,
		description = 'Accélère la pousse.',
		client = {
			image = 'fertilizer.png',
		},
	},
	['arrosoir_culture'] = {
		label = 'Arrosoir de culture',
		weight = 1200,
		stack = false,
		description = 'Pour les plants, pas pour le potager.',
		client = {
			image = 'water_can.png',
		},
	},
	['truelle'] = {
		label = 'Truelle',
		weight = 600,
		stack = false,
		description = 'Pour planter et récolter.',
		client = {
			image = 'trowel.png',
		},
	},
	['lampe_culture'] = {
		label = 'Lampe de culture',
		weight = 2500,
		stack = false,
		description = 'Lumière de croissance.',
		client = {
			image = 'light1.png',
		},
	},
	['lampe_culture_pro'] = {
		label = 'Lampe de culture pro',
		weight = 3000,
		stack = false,
		description = 'Lumière de floraison.',
		client = {
			image = 'light2.png',
		},
	},
	['tete_cannabis'] = {
		label = 'Tête de cannabis',
		weight = 50,
		description = 'Récolte brute, à nettoyer.',
		client = {
			image = 'weed_bud.png',
		},
	},
	['tete_cannabis_nettoyee'] = {
		label = 'Tête de cannabis nettoyée',
		weight = 40,
		description = 'Prête à rouler ou à ensacher.',
		client = {
			image = 'clean_weed_bud.png',
		},
	},
	['feuille_sechee'] = {
		label = 'Feuille séchée',
		weight = 30,
		description = 'Feuille quelconque, pour couper.',
		client = {
			image = 'generic_leaf.png',
		},
	},
	['feuilles_rouler'] = {
		label = 'Feuilles à rouler',
		weight = 20,
		description = 'Pour les joints.',
		client = {
			image = 'weed_papers.png',
		},
	},
	['papier_buvard'] = {
		label = 'Papier buvard illustré',
		weight = 20,
		description = 'Support des buvards de LSD.',
		client = {
			image = 'art_papers.png',
		},
	},
	['graines_pavot'] = {
		label = 'Graines de pavot',
		weight = 10,
		description = 'À planter.',
		client = {
			image = 'poppy_seeds.png',
		},
	},
	['plant_pavot'] = {
		label = 'Plant de pavot',
		weight = 200,
		description = 'À inciser pour l\'opium.',
		client = {
			image = 'poppy_plant.png',
		},
	},
	['graine_coca'] = {
		label = 'Graine de coca',
		weight = 10,
		description = 'À planter.',
		client = {
			image = 'coke_seed.png',
		},
	},
	['feuille_coca'] = {
		label = 'Feuille de coca',
		weight = 40,
		description = 'Base de la pâte.',
		client = {
			image = 'coke_leaf.png',
		},
	},
	['ergot_seigle'] = {
		label = 'Ergot de seigle',
		weight = 40,
		description = 'Champignon parasite. Base du LSD.',
		client = {
			image = 'ergot_fungus.png',
		},
	},
	['poudre_champignon'] = {
		label = 'Poudre de champignon',
		weight = 60,
		description = 'Champignons séchés et broyés.',
		client = {
			image = 'mushroom_powder.png',
		},
	},

	-- ─── DROGUE : CHIMIE ET OUTILS ─────────────────────────
	['ammoniaque'] = {
		label = 'Ammoniaque',
		weight = 500,
		description = 'Corrosif. Ne pas respirer.',
		client = {
			image = 'ammonia.png',
		},
	},
	['anesthesiant'] = {
		label = 'Anesthésiant',
		weight = 300,
		description = 'Base de la kétamine.',
		client = {
			image = 'anesthetic.png',
		},
	},
	['solution_aniline'] = {
		label = 'Solution d\'aniline',
		weight = 400,
		description = 'Réactif de synthèse.',
		client = {
			image = 'aniline_solution.png',
		},
	},
	['bicarbonate'] = {
		label = 'Bicarbonate de soude',
		weight = 200,
		description = 'Pour cuire le crack.',
		client = {
			image = 'baking_soda.png',
		},
	},
	['produit_npp'] = {
		label = 'Produit NPP',
		weight = 400,
		description = 'Précurseur du fentanyl.',
		client = {
			image = 'npp_chemical.png',
		},
	},
	['huile_safrole'] = {
		label = 'Huile de safrole',
		weight = 400,
		description = 'Précurseur de la MDMA.',
		client = {
			image = 'safrole_oil.png',
		},
	},
	['benzoate_sodium'] = {
		label = 'Benzoate de sodium',
		weight = 300,
		description = 'Réactif de purification.',
		client = {
			image = 'sodium_benzoate.png',
		},
	},
	['table_chimie'] = {
		label = 'Table de chimie',
		weight = 8000,
		stack = false,
		description = 'Verrerie et brûleur. Se pose.',
		client = {
			image = 'chem_table.png',
		},
	},
	['table_coke'] = {
		label = 'Table à cocaïne',
		weight = 8000,
		stack = false,
		description = 'Pour raffiner et presser. Se pose.',
		client = {
			image = 'coke_table.png',
		},
	},
	['table_meth'] = {
		label = 'Table à meth',
		weight = 8000,
		stack = false,
		description = 'Pour cuisiner. Se pose.',
		client = {
			image = 'meth_table.png',
		},
	},
	['table_conditionnement'] = {
		label = 'Table de conditionnement',
		weight = 6000,
		stack = false,
		description = 'Pour ensacher et rouler. Se pose.',
		client = {
			image = 'weed_table.png',
		},
	},
	['plateau_meth'] = {
		label = 'Plateau de meth',
		weight = 800,
		description = 'Cristaux en cours de séchage.',
		client = {
			image = 'meth_tray.png',
		},
	},
	['sachet_plastique'] = {
		label = 'Sachet plastique',
		weight = 5,
		description = 'Pour conditionner.',
		client = {
			image = 'plastic_bag.png',
		},
	},
	['seringue_vide'] = {
		label = 'Seringue vide',
		weight = 40,
		description = 'À charger.',
		client = {
			image = 'syringe.png',
		},
	},
	['pipe'] = {
		label = 'Pipe',
		weight = 200,
		stack = false,
		durability = true,
		description = 'Pour fumer l\'opium. S\'use.',
		client = {
			image = 'pipe.png',
		},
	},
	['pipe_crack'] = {
		label = 'Pipe à crack',
		weight = 150,
		stack = false,
		durability = true,
		description = 'Verre noirci. S\'use.',
		client = {
			image = 'crack_pipe.png',
		},
	},
	['telephone_jetable'] = {
		label = 'Téléphone jetable',
		weight = 150,
		stack = false,
		description = 'Pour les contacts qu\'on ne garde pas.',
		client = {
			image = 'burner_phone.png',
		},
	},
	['pepites_chocolat'] = {
		label = 'Pépites de chocolat',
		weight = 100,
		description = 'Pour les cookies et le chocolat aux champignons.',
		client = {
			image = 'chocolate_chips.png',
		},
	},
	['pate_cookie'] = {
		label = 'Pâte à cookie',
		weight = 200,
		description = 'Crue. À enrichir.',
		client = {
			image = 'cookie_dough.png',
		},
	},
	['lsd_liquide'] = {
		label = 'LSD liquide',
		weight = 50,
		description = 'Une goutte par buvard.',
		client = {
			image = 'lsd_liquid.png',
		},
	},
	['cristaux_mdma'] = {
		label = 'Cristaux de MDMA',
		weight = 60,
		description = 'À presser en comprimés.',
		client = {
			image = 'ecstasy_crystals.png',
		},
	},
	['pate_coca'] = {
		label = 'Pâte de coca',
		weight = 150,
		description = 'Étape intermédiaire.',
		client = {
			image = 'coke_paste.png',
		},
	},
	['cocaine_pure'] = {
		label = 'Cocaïne pure',
		weight = 100,
		description = 'Poudre non conditionnée.',
		client = {
			image = 'coke.png',
		},
	},
	['brique_cocaine'] = {
		label = 'Brique de cocaïne',
		weight = 1000,
		description = 'Un kilo pressé. Se découpe en sachets.',
		client = {
			image = 'coke_brick.png',
		},
	},
	['poupee_chargee'] = {
		label = 'Poupée chargée',
		weight = 900,
		description = 'Une poupée, et ce qu\'elle cache.',
		client = {
			image = 'coke_doll.png',
		},
	},
	['caillou_crack'] = {
		label = 'Caillou de crack',
		weight = 60,
		description = 'Non conditionné.',
		client = {
			image = 'crack.png',
		},
	},
	['heroine_pure'] = {
		label = 'Héroïne pure',
		weight = 100,
		description = 'Poudre non conditionnée.',
		client = {
			image = 'heroin.png',
		},
	},
	['fentanyl_pur'] = {
		label = 'Fentanyl pur',
		weight = 100,
		description = 'Quelques grains suffisent.',
		client = {
			image = 'fentanyl.png',
		},
	},
	['ketamine_pure'] = {
		label = 'Kétamine pure',
		weight = 100,
		description = 'Poudre non conditionnée.',
		client = {
			image = 'ketamine.png',
		},
	},

	-- ─── DROGUE : PRODUITS FINAUX (consommables) ───────────
	-- Bonus cumulables, puis gueule de bois jusqu'à une saline. Effets dans rz_soins.
	['joint'] = {
		label = 'Joint',
		weight = 10,
		close = true,
		description = 'Roulé serré. Détend, un bon moment.',
		client = {
			image = 'weed_joint.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['cookie_cannabis'] = {
		label = 'Cookie au cannabis',
		weight = 80,
		close = true,
		description = 'Ça monte lentement, ça dure.',
		client = {
			image = 'weed_cookie.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_weed'] = {
		label = 'Sachet de weed',
		weight = 60,
		close = true,
		description = 'Se vend, se fume.',
		client = {
			image = 'weed_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_cocaine'] = {
		label = 'Sachet de cocaïne',
		weight = 60,
		close = true,
		description = 'Se vend, se sniffe.',
		client = {
			image = 'coke_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_crack'] = {
		label = 'Sachet de crack',
		weight = 60,
		close = true,
		description = 'Se fume à la pipe à crack.',
		client = {
			image = 'crack_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['seringue_crack'] = {
		label = 'Seringue de crack',
		weight = 120,
		close = true,
		description = 'Directement dans le sang.',
		client = {
			image = 'crack_syringe.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_heroine'] = {
		label = 'Sachet d\'héroïne',
		weight = 60,
		close = true,
		description = 'Se vend, se sniffe.',
		client = {
			image = 'heroin_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['seringue_heroine'] = {
		label = 'Seringue d\'héroïne',
		weight = 120,
		close = true,
		description = 'La plus forte, la plus longue.',
		client = {
			image = 'heroin_syringe.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_fentanyl'] = {
		label = 'Sachet de fentanyl',
		weight = 60,
		close = true,
		description = 'On ne sent plus rien du tout.',
		client = {
			image = 'fentanyl_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['sachet_ketamine'] = {
		label = 'Sachet de kétamine',
		weight = 60,
		close = true,
		description = 'Le corps devient lointain.',
		client = {
			image = 'ketamine_bag.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['seringue_meth'] = {
		label = 'Seringue de meth',
		weight = 120,
		close = true,
		description = 'Le cœur s\'emballe.',
		client = {
			image = 'meth_syringe.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['ecstasy'] = {
		label = 'Comprimé d\'ecstasy',
		weight = 5,
		close = true,
		description = 'Petite pilule pressée.',
		client = {
			image = 'ecstasy_pill.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['buvard_lsd'] = {
		label = 'Buvard de LSD',
		weight = 5,
		close = true,
		description = 'Un carré de papier.',
		client = {
			image = 'lsd.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['champignons'] = {
		label = 'Champignons hallucinogènes',
		weight = 40,
		close = true,
		description = 'Se mangent frais.',
		client = {
			image = 'mushrooms.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['chocolat_champignons'] = {
		label = 'Chocolat aux champignons',
		weight = 80,
		close = true,
		description = 'Plus doux, plus long.',
		client = {
			image = 'mushroom_chocolate.png',
			export = 'rz_soins.useDrogue',
		},
	},
	['opium'] = {
		label = 'Opium',
		weight = 60,
		close = true,
		description = 'Se fume à la pipe.',
		client = {
			image = 'opium.png',
			export = 'rz_soins.useDrogue',
		},
	},

	-- ─── CHASSE (ars_hunting) ──────────────────────────────
	-- La viande vient des items existants : viande_cerf_crue à la
	-- récolte, steak_cerf au feu de camp.
	['traqueur_animal'] = {
		label = 'Traqueur d\'animaux',
		weight = 200,
		stack = false,
		allowArmed = true,
		description = 'Repère l\'animal le plus proche pendant une minute.',
		client = {
			image = 'traqueur_animal.png',
		},
	},
	['feu_de_camp'] = {
		label = 'Feu de camp',
		weight = 1500,
		stack = false,
		allowArmed = true,
		description = 'Se pose au sol. Pour cuire la viande. Se reprend.',
		client = {
			image = 'feu_de_camp.png',
		},
	},
	['appat_chasse'] = {
		label = 'Appât de chasse',
		weight = 100,
		allowArmed = true,
		description = 'Attire l\'animal le plus proche pendant deux minutes.',
		client = {
			image = 'appat_chasse.png',
		},
	},
	['peau_cerf_abimee'] = {
		label = 'Peau de cerf abîmée',
		weight = 200,
		description = 'Trouée, tachée. Vaut trois fois rien.',
		client = {
			image = 'peau_cerf_abimee.png',
		},
	},
	['peau_cerf_usee'] = {
		label = 'Peau de cerf usée',
		weight = 200,
		description = 'Passable.',
		client = {
			image = 'peau_cerf_usee.png',
		},
	},
	['peau_cerf_correcte'] = {
		label = 'Peau de cerf correcte',
		weight = 200,
		description = 'Souple, quelques défauts.',
		client = {
			image = 'peau_cerf_correcte.png',
		},
	},
	['peau_cerf_belle'] = {
		label = 'Belle peau de cerf',
		weight = 200,
		description = 'Propre, entière.',
		client = {
			image = 'peau_cerf_belle.png',
		},
	},
	['peau_cerf_parfaite'] = {
		label = 'Peau de cerf parfaite',
		weight = 200,
		description = 'Sans une marque. Rare.',
		client = {
			image = 'peau_cerf_parfaite.png',
		},
	},
	['bois_de_cerf'] = {
		label = 'Bois de cerf',
		weight = 600,
		description = 'Trophée, ou matière première.',
		client = {
			image = 'bois_de_cerf.png',
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
			export = 'rz_boombox.useBoombox',
		},
	},
}
