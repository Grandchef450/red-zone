--[[
    REDZONE SURVIVAL — weapons.lua
    Réorganisé le 29 août 2026

    Les 108 armes sont INCHANGÉES : mêmes noms, mêmes poids,
    mêmes munitions, même durabilité. Seul leur ORDRE change,
    et un champ `rzTier` est ajouté à chacune.

    À QUOI SERT rzTier
    C'est une étiquette lisible par n'importe quel script :

        for name, data in pairs(exports.ox_inventory:Items()) do
            if data.rzTier == 'event' then ... end
        end

    Ton futur script d'airdrop pourra donc tirer au hasard
    dans le palier « event » sans qu'on ait à maintenir une
    deuxième liste ailleurs. ox_inventory ignore les champs
    qu'il ne connaît pas : aucun risque.
]]

return {
	Weapons = {

		-- ═══════════════════════════════════════════════════════
		--  CORPS À CORPS
		--
		-- Disponibles partout. Les équivalents craftables de ton tableau
		-- (couteau de survie, hache, lance) sont des items séparés :
		-- ceux-ci sont les armes trouvées, pas fabriquées.
		-- ═══════════════════════════════════════════════════════

		['WEAPON_BAT'] = {
			label = 'Bat',
			weight = 1134,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_BATTLEAXE'] = {
			label = 'Battle Axe',
			weight = 6500,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_BOTTLE'] = {
			label = 'Bottle',
			weight = 350,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_CROWBAR'] = {
			label = 'Crowbar',
			weight = 2500,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_DAGGER'] = {
			label = 'Dagger',
			weight = 800,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_GOLFCLUB'] = {
			label = 'Golf Club',
			weight = 330,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_HAMMER'] = {
			label = 'Hammer',
			weight = 1200,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_HATCHET'] = {
			label = 'Hatchet',
			weight = 1000,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_KNIFE'] = {
			label = 'Knife',
			weight = 300,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_KNUCKLE'] = {
			label = 'Knuckle Dusters',
			weight = 300,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_MACHETE'] = {
			label = 'Machete',
			weight = 1000,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_NIGHTSTICK'] = {
			label = 'Nightstick',
			weight = 1000,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_POOLCUE'] = {
			label = 'Pool Cue',
			weight = 146,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_STONE_HATCHET'] = {
			label = 'Stone Hatchet',
			weight = 800,
			durability = 0.1,
			rzTier = 'melee',
		},

		['WEAPON_SWITCHBLADE'] = {
			label = 'Switchblade',
			weight = 300,
			durability = 0.1,
			anim = { 'anim@melee@switchblade@holster', 'unholster', 200, 'anim@melee@switchblade@holster', 'holster', 600 },
			rzTier = 'melee',
		},

		['WEAPON_WRENCH'] = {
			label = 'Wrench',
			weight = 2500,
			durability = 0.1,
			rzTier = 'melee',
		},



		-- ═══════════════════════════════════════════════════════
		--  HACHES CRAFTABLES  —  armes blanches de l'arbre de craft
		--
		--  Le nom de l'item ne change PAS : les recettes continuent
		--  de produire « hache_survie ». Le champ `model` pointe vers
		--  le hash de l'arme, déclarée dans custom_weapons_pack.
		--
		--  ⚠️  Ces quatre entrées doivent être RETIRÉES de items.lua,
		--  sinon items.lua les écrase au chargement et elles
		--  redeviennent de simples objets inertes.
		-- ═══════════════════════════════════════════════════════

		['hache_survie'] = {
			label = 'Hache de survie',
			weight = 1500,
			durability = 0.12,
			model = 'WEAPON_HACHE_SURVIE',
			rzTier = 'melee',
			client = {
				image = 'hache_survie.png',
			},
		},

		['hache_acier'] = {
			label = 'Hache en acier',
			weight = 1600,
			durability = 0.08,
			model = 'WEAPON_HACHE_ACIER',
			rzTier = 'melee',
			client = {
				image = 'hache_acier.png',
			},
		},

		['hache_aluminium'] = {
			label = 'Hache en aluminium',
			weight = 1300,
			durability = 0.06,
			model = 'WEAPON_HACHE_ALUMINIUM',
			rzTier = 'melee',
			client = {
				image = 'hache_aluminium.png',
			},
		},

		['hache_inox'] = {
			label = 'Hache en inox',
			weight = 1700,
			durability = 0.04,
			model = 'WEAPON_HACHE_INOX',
			rzTier = 'melee',
			client = {
				image = 'hache_inox.png',
			},
		},


		-- ─── ARMES DE CONTACT BRICOLÉES ────────────────────────
		--  Les deux battes utilisent des modèles que je n'ai pas pu
		--  voir : si le disque de scie et le barbelé sont inversés,
		--  échange les valeurs `model` dans le pack d'armes.

		['batte_barbelee'] = {
			label = 'Batte barbelée',
			weight = 2200,
			durability = 0.09,
			model = 'WEAPON_BATTE_BARBELEE',
			rzTier = 'melee',
			client = {
				image = 'batte_barbelee.png',
			},
		},

		['batte_scie'] = {
			label = 'Batte à disque de scie',
			weight = 2500,
			durability = 0.07,
			model = 'WEAPON_BATTE_SCIE',
			rzTier = 'melee',
			client = {
				image = 'batte_scie.png',
			},
		},

		-- ─── ARMES DE POING ────────────────────────────────────
		--  Toutes utilisent le modèle vanilla w_me_knuckle : elles
		--  se ressemblent donc à l'écran. Seuls les dégâts, le poids
		--  et la durabilité les distinguent.

		['poing_americain'] = {
			label = 'Poing américain',
			weight = 400,
			durability = 0.10,
			model = 'WEAPON_POING_AMERICAIN',
			rzTier = 'melee',
			client = {
				image = 'poing_americain.png',
			},
		},

		['gant_fer'] = {
			label = 'Gants ferrés',
			weight = 700,
			durability = 0.08,
			model = 'WEAPON_GANT_FER',
			rzTier = 'melee',
			client = {
				image = 'gant_fer.png',
			},
		},

		['gant_aluminium'] = {
			label = 'Gants en aluminium',
			weight = 500,
			durability = 0.06,
			model = 'WEAPON_GANT_ALUMINIUM',
			rzTier = 'melee',
			client = {
				image = 'gant_aluminium.png',
			},
		},

		['gant_inox'] = {
			label = 'Gants en inox',
			weight = 800,
			durability = 0.04,
			model = 'WEAPON_GANT_INOX',
			rzTier = 'melee',
			client = {
				image = 'gant_inox.png',
			},
		},


		-- ─── KATANAS ───────────────────────────────────────────
		--  Les dix frappent EXACTEMENT pareil : 80 de dégâts,
		--  soit le double d'une machette. Ce qui les sépare, ce
		--  sont le POIDS et la DURABILITÉ.
		--
		--  Le carbone est le plus léger et le plus endurant ;
		--  l'or est lourd et se marque vite. Un joueur choisit
		--  donc sa lame selon ce qu'il porte déjà et selon la
		--  durée de sa sortie, pas selon sa puissance.
		--
		--  ⚠️  Les dix partagent DEUX modèles de machette, en
		--  alternance : ils forment cinq paires identiques à
		--  l'écran. Aucun modèle de katana n'existe ni dans ton
		--  archive ni dans GTA.
		-- ═══════════════════════════════════════════════════════

		['katana_survie'] = {
			label = 'Katana de fortune',
			weight = 1200,
			durability = 0.16,
			model = 'WEAPON_KATANA_SURVIE',
			rzTier = 'melee',
			client = {
				image = 'katana_survie.png',
			},
		},

		['katana_cuivre'] = {
			label = 'Katana en cuivre',
			weight = 1600,
			durability = 0.12,
			model = 'WEAPON_KATANA_CUIVRE',
			rzTier = 'melee',
			client = {
				image = 'katana_cuivre.png',
			},
		},

		['katana_acier'] = {
			label = 'Katana en acier',
			weight = 1400,
			durability = 0.08,
			model = 'WEAPON_KATANA_ACIER',
			rzTier = 'melee',
			client = {
				image = 'katana_acier.png',
			},
		},

		['katana_aluminium'] = {
			label = 'Katana en aluminium',
			weight = 1000,
			durability = 0.1,
			model = 'WEAPON_KATANA_ALUMINIUM',
			rzTier = 'melee',
			client = {
				image = 'katana_aluminium.png',
			},
		},

		['katana_magnesium'] = {
			label = 'Katana en magnésium',
			weight = 1050,
			durability = 0.08,
			model = 'WEAPON_KATANA_MAGNESIUM',
			rzTier = 'melee',
			client = {
				image = 'katana_magnesium.png',
			},
		},

		['katana_ceramique'] = {
			label = 'Katana en céramique',
			weight = 1100,
			durability = 0.07,
			model = 'WEAPON_KATANA_CERAMIQUE',
			rzTier = 'melee',
			client = {
				image = 'katana_ceramique.png',
			},
		},

		['katana_inox'] = {
			label = 'Katana en inox',
			weight = 1450,
			durability = 0.045,
			model = 'WEAPON_KATANA_INOX',
			rzTier = 'melee',
			client = {
				image = 'katana_inox.png',
			},
		},

		['katana_carbone'] = {
			label = 'Katana en carbone',
			weight = 900,
			durability = 0.04,
			model = 'WEAPON_KATANA_CARBONE',
			rzTier = 'melee',
			client = {
				image = 'katana_carbone.png',
			},
		},

		['katana_argent'] = {
			label = 'Katana en argent',
			weight = 1650,
			durability = 0.06,
			model = 'WEAPON_KATANA_ARGENT',
			rzTier = 'melee',
			client = {
				image = 'katana_argent.png',
			},
		},

		['katana_or'] = {
			label = 'Katana en or',
			weight = 1900,
			durability = 0.06,
			model = 'WEAPON_KATANA_OR',
			rzTier = 'melee',
			client = {
				image = 'katana_or.png',
			},
		},

		-- ─── COUTEAUX CSGO ─────────────────────────────────────
		--  Neuf lames converties de REMPLACEMENT en ADDON.
		--
		--  Dans l'archive d'origine, les neuf portaient le même
		--  nom de fichier — w_me_knife_01, le couteau vanilla.
		--  Elles s'écrasaient mutuellement : impossible d'en
		--  installer plus d'une. Et Shadow dagger visait
		--  w_me_knuckle, ce qui aurait transformé tes quatre
		--  armes de poing en dague.
		--
		--  Dégâts uniformes à 45 : au-dessus d'une machette
		--  vanilla (40), loin sous un katana (80). Ce sont des
		--  lames de prestige — leur valeur tient à la rareté,
		--  pas à la puissance.
		-- ═══════════════════════════════════════════════════════

		['couteau_bayonet'] = {
			label = 'Baïonnette',
			weight = 700,
			durability = 0.06,
			model = 'WEAPON_COUTEAU_BAYONET',
			rzTier = 'event',
			client = {
				image = 'couteau_bayonet.png',
			},
		},

		['couteau_papillon'] = {
			label = 'Couteau papillon',
			weight = 450,
			durability = 0.07,
			model = 'WEAPON_COUTEAU_PAPILLON',
			rzTier = 'event',
			client = {
				image = 'couteau_papillon.png',
			},
		},

		['couteau_flip'] = {
			label = 'Couteau à cran',
			weight = 420,
			durability = 0.08,
			model = 'WEAPON_COUTEAU_FLIP',
			rzTier = 'event',
			client = {
				image = 'couteau_flip.png',
			},
		},

		['couteau_gut'] = {
			label = 'Couteau à dépecer',
			weight = 500,
			durability = 0.07,
			model = 'WEAPON_COUTEAU_GUT',
			rzTier = 'event',
			client = {
				image = 'couteau_gut.png',
			},
		},

		['couteau_huntsman'] = {
			label = 'Couteau de chasse',
			weight = 650,
			durability = 0.05,
			model = 'WEAPON_COUTEAU_HUNTSMAN',
			rzTier = 'event',
			client = {
				image = 'couteau_huntsman.png',
			},
		},

		['couteau_karambit'] = {
			label = 'Karambit',
			weight = 400,
			durability = 0.07,
			model = 'WEAPON_COUTEAU_KARAMBIT',
			rzTier = 'event',
			client = {
				image = 'couteau_karambit.png',
			},
		},

		['dague_ombre'] = {
			label = 'Dagues de l\'ombre',
			weight = 550,
			durability = 0.06,
			model = 'WEAPON_DAGUE_OMBRE',
			rzTier = 'event',
			client = {
				image = 'dague_ombre.png',
			},
		},

		['couteau_ct'] = {
			label = 'Couteau tactique',
			weight = 600,
			durability = 0.06,
			model = 'WEAPON_COUTEAU_CT',
			rzTier = 'event',
			client = {
				image = 'couteau_ct.png',
			},
		},

		['couteau_t'] = {
			label = 'Couteau de rue',
			weight = 580,
			durability = 0.09,
			model = 'WEAPON_COUTEAU_T',
			rzTier = 'event',
			client = {
				image = 'couteau_t.png',
			},
		},
		-- ═══════════════════════════════════════════════════════
		--  OUTILS
		--
		-- Pas des armes de combat. Aucune raison de les rationner.
		-- ═══════════════════════════════════════════════════════

		['WEAPON_FLASHLIGHT'] = {
			label = 'Flashlight',
			weight = 125,
			durability = 0.1,
			rzTier = 'outil',
		},

		['WEAPON_FIREEXTINGUISHER'] = {
			label = 'Fire Extinguisher',
			weight = 8616,
            durability = 0.006,
			rzTier = 'outil',
		},

		['WEAPON_PETROLCAN'] = {
			label = 'Jerry Can',
			weight = 4000,
			rzTier = 'outil',
		},

		['WEAPON_HAZARDCAN'] = {
			label = 'Hazard Can',
			weight = 12000,
			rzTier = 'outil',
		},

		['WEAPON_FERTILIZERCAN'] = {
			label = 'Fertilizer Can',
			weight = 12000,
			rzTier = 'outil',
		},

		['WEAPON_METALDETECTOR'] = {
			label = 'Metal Detector',
			weight = 1200,
			rzTier = 'outil',
		},

		['WEAPON_FLARE'] = {
			label = 'Flare',
			weight = 250,
			throwable = true,
			rzTier = 'outil',
		},

		['WEAPON_FLAREGUN'] = {
			label = 'Flare Gun',
			weight = 1000,
			durability = 0.5,
			ammoname = 'ammo-flare',
			rzTier = 'outil',
		},


		-- ═══════════════════════════════════════════════════════
		--  VILLE  —  trouvable, troquable, lootable en zone urbaine
		--
		-- Armes de poing, petits fusils à pompe et automatiques d'époque.
		-- La Gusenberg EST la Thompson de la guerre.
		-- 
		-- C'est ce palier que doivent contenir tes tables de loot
		-- urbaines, tes épaves et tes peds troqueurs.
		-- ═══════════════════════════════════════════════════════

		['WEAPON_PISTOL'] = {
			label = 'Pistol',
			weight = 1130,
			durability = 0.1,
			ammoname = 'ammo-9',
			rzTier = 'ville',
		},

		['WEAPON_COMBATPISTOL'] = {
			label = 'Combat Pistol',
			weight = 785,
			durability = 0.2,
			ammoname = 'ammo-9',
			rzTier = 'ville',
		},

		['WEAPON_SNSPISTOL'] = {
			label = 'SNS Pistol',
			weight = 465,
			durability = 0.1,
			ammoname = 'ammo-45',
			rzTier = 'ville',
		},

		['WEAPON_VINTAGEPISTOL'] = {
			label = 'Vintage Pistol',
			weight = 700,
			durability = 0.1,
			ammoname = 'ammo-9',
			rzTier = 'ville',
		},

		['WEAPON_CERAMICPISTOL'] = {
			label = 'Ceramic Pistol',
			weight = 800,
			durability = 0.2,
			ammoname = 'ammo-9',
			rzTier = 'ville',
		},

		['WEAPON_HEAVYPISTOL'] = {
			label = 'Heavy Pistol',
			weight = 1100,
			durability = 0.2,
			ammoname = 'ammo-45',
			rzTier = 'ville',
		},

		['WEAPON_PISTOL50'] = {
			label = 'Pistol .50',
			weight = 2000,
			durability = 0.1,
			ammoname = 'ammo-50',
			rzTier = 'ville',
		},

		['WEAPON_REVOLVER'] = {
			label = 'Revolver',
			weight = 2260,
			durability = 0.1,
			ammoname = 'ammo-44',
			rzTier = 'ville',
		},

		['WEAPON_DOUBLEACTION'] = {
			label = 'Double Action Revolver',
			weight = 940,
			durability = 0.2,
			ammoname = 'ammo-38',
			rzTier = 'ville',
		},

		['WEAPON_NAVYREVOLVER'] = {
			label = 'Navy Revolver',
			weight = 4000,
			durability = 0.2,
			ammoname = 'ammo-44',
			rzTier = 'ville',
		},

		['WEAPON_MARKSMANPISTOL'] = {
			label = 'Marksman Pistol',
			weight = 1588,
			durability = 0.5,
			ammoname = 'ammo-22',
			rzTier = 'ville',
		},

		['WEAPON_MUSKET'] = {
			label = 'Musket',
			weight = 4500,
			durability = 0.5,
			ammoname = 'ammo-musket',
			rzTier = 'ville',
		},

		['WEAPON_SAWNOFFSHOTGUN'] = {
			label = 'Sawn Off Shotgun',
			weight = 2380,
			durability = 0.1,
			ammoname = 'ammo-shotgun',
			rzTier = 'ville',
		},

		['WEAPON_DBSHOTGUN'] = {
			label = 'Double Barrel Shotgun',
			weight = 3175,
			durability = 0.4,
			ammoname = 'ammo-shotgun',
			rzTier = 'ville',
		},

		['WEAPON_PUMPSHOTGUN'] = {
			label = 'Pump Shotgun',
			weight = 3400,
			durability = 0.1,
			ammoname = 'ammo-shotgun',
			rzTier = 'ville',
		},

		['WEAPON_GUSENBERG'] = {
			label = 'Gusenberg',
			weight = 4900,
			durability = 0.04,
			ammoname = 'ammo-45',
			rzTier = 'ville',
		},

		['WEAPON_MICROSMG'] = {
			label = 'Micro SMG',
			weight = 3000,
			durability = 0.1,
			ammoname = 'ammo-45',
			rzTier = 'ville',
		},

		['WEAPON_MACHINEPISTOL'] = {
			label = 'Machine Pistol',
			weight = 1400,
			durability = 0.05,
			ammoname = 'ammo-9',
			rzTier = 'ville',
		},

		['WEAPON_MOLOTOV'] = {
			label = 'Molotov',
			weight = 1800,
			throwable = true,
			rzTier = 'ville',
		},

		['WEAPON_PIPEBOMB'] = {
			label = 'Pipe Bomb',
			weight = 1800,
			throwable = true,
			rzTier = 'ville',
		},

		['WEAPON_SMOKEGRENADE'] = {
			label = 'Smoke Grenade',
			weight = 600,
			throwable = true,
			rzTier = 'ville',
		},

		['WEAPON_STUNGUN'] = {
			label = 'Tazer',
			weight = 227,
			durability = 0.1,
			rzTier = 'ville',
		},


		-- ═══════════════════════════════════════════════════════
		--  EVENT ET AIRDROP  —  ne jamais mettre en ville
		--
		-- Tout l'armement moderne. Ces armes n'ont AUCUNE raison
		-- d'apparaître dans une épave ou chez un marchand : elles se
		-- gagnent, et c'est ce qui fait leur prix.
		-- ═══════════════════════════════════════════════════════

		['WEAPON_ASSAULTRIFLE'] = {
			label = 'Assault Rifle',
			weight = 4500,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},

		['WEAPON_ASSAULTRIFLE_MK2'] = {
			label = 'Assault Rifle MK2',
			weight = 2950,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},

		['WEAPON_CARBINERIFLE'] = {
			label = 'Carbine Rifle',
			weight = 3100,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_CARBINERIFLE_MK2'] = {
			label = 'Carbine Rifle MK2',
			weight = 3000,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_ADVANCEDRIFLE'] = {
			label = 'Advanced Rifle',
			weight = 3100,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_SPECIALCARBINE'] = {
			label = 'Special Carbine',
			weight = 3000,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_SPECIALCARBINE_MK2'] = {
			label = 'Special Carbine MK2',
			weight = 3370,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_BULLPUPRIFLE'] = {
			label = 'Bullpup Rifle',
			weight = 2900,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_BULLPUPRIFLE_MK2'] = {
			label = 'Bullpup Rifle MK2',
			weight = 2900,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_COMPACTRIFLE'] = {
			label = 'Compact Rifle',
			weight = 3600,
			durability = 0.05,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},

		['WEAPON_MILITARYRIFLE'] = {
			label = 'Military Rifle',
			weight = 3600,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_HEAVYRIFLE'] = {
			label = 'Heavy Rifle',
			weight = 3300,
			durability = 0.2,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_BATTLERIFLE'] = {
			label = 'Battle Rifle',
			weight = 3300,
			durability = 0.03,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},

		['WEAPON_TACTICALRIFLE'] = {
			label = 'Tactical Rifle',
			weight = 3400,
			durability = 0.03,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_SMG'] = {
			label = 'SMG',
			weight = 3084,
			durability = 0.8,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_SMG_MK2'] = {
			label = 'SMG Mk2',
			weight = 2700,
			durability = 0.05,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_ASSAULTSMG'] = {
			label = 'Assault SMG',
			weight = 2900,
			durability = 0.05,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_COMBATPDW'] = {
			label = 'Combat PDW',
			weight = 2300,
			durability = 0.1,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_MINISMG'] = {
			label = 'Mini SMG',
			weight = 1270,
			durability = 0.05,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_TECPISTOL'] = {
			label = 'Tactical SMG',
			weight = 1500,
			durability = 0.075,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_APPISTOL'] = {
			label = 'AP Pistol',
			weight = 1400,
			durability = 0.1,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_GADGETPISTOL'] = {
			label = 'Perico Pistol',
			weight = 1750,
			durability = 0.1,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_PISTOLXM3'] = {
			label = 'WM 29 Pistol',
			weight = 969,
			durability = 0.2,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_PISTOL_MK2'] = {
			label = 'Pistol MK2',
			weight = 1000,
			durability = 0.5,
			ammoname = 'ammo-9',
			rzTier = 'event',
		},

		['WEAPON_SNSPISTOL_MK2'] = {
			label = 'SNS Pistol MK2',
			weight = 465,
			durability = 0.1,
			ammoname = 'ammo-45',
			rzTier = 'event',
		},

		['WEAPON_REVOLVER_MK2'] = {
			label = 'Revolver MK2',
			weight = 2600,
			durability = 0.1,
			ammoname = 'ammo-44',
			rzTier = 'event',
		},

		['WEAPON_COMBATSHOTGUN'] = {
			label = 'Combat Shotgun',
			weight = 4400,
			durability = 0.2,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_HEAVYSHOTGUN'] = {
			label = 'Heavy Shotgun',
			weight = 3600,
			durability = 0.1,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_ASSAULTSHOTGUN'] = {
			label = 'Assault Shotgun',
			weight = 5200,
			durability = 0.05,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_BULLPUPSHOTGUN'] = {
			label = 'Bullpup Shotgun',
			weight = 3100,
			durability = 0.2,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_PUMPSHOTGUN_MK2'] = {
			label = 'Pump Shotgun MK2',
			weight = 3200,
			durability = 0.1,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_AUTOSHOTGUN'] = {
			label = 'Sweeper Shotgun',
			weight = 4400,
			durability = 0.05,
			ammoname = 'ammo-shotgun',
			rzTier = 'event',
		},

		['WEAPON_SNIPERRIFLE'] = {
			label = 'Sniper Rifle',
			weight = 5000,
			durability = 0.5,
			ammoname = 'ammo-sniper',
			rzTier = 'event',
		},

		['WEAPON_MARKSMANRIFLE'] = {
			label = 'Marksman Rifle',
			weight = 7500,
			durability = 0.4,
			ammoname = 'ammo-sniper',
			rzTier = 'event',
		},

		['WEAPON_MARKSMANRIFLE_MK2'] = {
			label = 'Marksman Rifle MK2',
			weight = 4000,
			durability = 0.4,
			ammoname = 'ammo-sniper',
			rzTier = 'event',
		},

		['WEAPON_PRECISIONRIFLE'] = {
			label = 'Precision Rifle',
			weight = 4800,
			durability = 0.4,
			ammoname = 'ammo-sniper',
			rzTier = 'event',
		},

		['WEAPON_HEAVYSNIPER'] = {
			label = 'Heavy Sniper',
			weight = 12700,
			durability = 0.5,
			ammoname = 'ammo-heavysniper',
			rzTier = 'event',
		},

		['WEAPON_HEAVYSNIPER_MK2'] = {
			label = 'Heavy Sniper MK2',
			weight = 14000,
			durability = 0.5,
			ammoname = 'ammo-heavysniper',
			rzTier = 'event',
		},

		['WEAPON_GRENADE'] = {
			label = 'Grenade',
			weight = 400,
			throwable = true,
			rzTier = 'event',
		},

		['WEAPON_STICKYBOMB'] = {
			label = 'Sticky Bomb',
			weight = 1000,
			throwable = true,
			rzTier = 'event',
		},

		['WEAPON_PROXMINE'] = {
			label = 'Proximity Mine',
			weight = 2500,
			throwable = true,
			rzTier = 'event',
		},

		['WEAPON_MG'] = {
			label = 'Machine Gun',
			weight = 9000,
			durability = 0.02,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},

		['WEAPON_COMBATMG'] = {
			label = 'Combat MG',
			weight = 7500,
			durability = 0.02,
			ammoname = 'ammo-rifle',
			rzTier = 'event',
		},

		['WEAPON_COMBATMG_MK2'] = {
			label = 'Combat MG MK2',
			weight = 8000,
			durability = 0.02,
			ammoname = 'ammo-rifle2',
			rzTier = 'event',
		},


		-- ═══════════════════════════════════════════════════════
		--  RETIRÉES DU SERVEUR
		--
		-- Lance-roquettes, miniguns, armes laser, boules de neige.
		-- Hors thème ou hors échelle. Elles restent déclarées pour
		-- qu'un admin puisse les invoquer, mais ne doivent figurer
		-- dans AUCUNE table de loot.
		-- ═══════════════════════════════════════════════════════

		['WEAPON_RPG'] = {
			label = 'RPG',
			weight = 5000,
			durability = 0.3,
			ammoname = 'ammo-rocket',
			rzTier = 'interdit',
		},

		['WEAPON_HOMINGLAUNCHER'] = {
			label = 'Homing Launcher',
			weight = 10000,
			durability = 0.6,
			ammoname = 'ammo-rocket',
			rzTier = 'interdit',
		},

		['WEAPON_GRENADELAUNCHER'] = {
			label = 'Grenade Launcher',
			weight = 6500,
			durability = 0.05,
			ammoname = 'ammo-grenade',
			rzTier = 'interdit',
		},

		['WEAPON_COMPACTLAUNCHER'] = {
			label = 'Compact Grenade Launcher',
			weight = 2500,
			durability = 0.05,
			ammoname = 'ammo-grenade',
			rzTier = 'interdit',
		},

		['WEAPON_MINIGUN'] = {
			label = 'Minigun',
			weight = 38500,
			durability = 0.1,
			ammoname = 'ammo-rifle2',
			rzTier = 'interdit',
		},

		['WEAPON_RAILGUN'] = {
			label = 'Railgun',
			weight = 3570,
			durability = 0.5,
			ammoname = 'ammo-railgun',
			rzTier = 'interdit',
		},

		['WEAPON_RAILGUNXM3'] = {
			label = 'Railgun XM3',
			weight = 3570,
			durability = 0.5,
			ammoname = 'ammo-railgun',
			rzTier = 'interdit',
		},

		['WEAPON_EMPLAUNCHER'] = {
			label = 'Compact EMP Launcher',
			weight = 2750,
			durability = 0.2,
			ammoname = 'ammo-emp',
			rzTier = 'interdit',
		},

		['WEAPON_RAYCARBINE'] = {
			label = 'Unholy Hellbringer',
			weight = 3620,
			durability = 0.2,
			ammoname = 'ammo-laser',
			rzTier = 'interdit',
		},

		['WEAPON_RAYPISTOL'] = {
			label = 'Up-n-Atomizer',
			weight = 1540,
			durability = 0.5,
			rzTier = 'interdit',
		},

		['WEAPON_RAYMINIGUN'] = {
			label = 'Widowmaker',
			weight = 7000,
			durability = 0.1,
			ammoname = 'ammo-laser',
			rzTier = 'interdit',
		},

		['WEAPON_SNOWLAUNCHER'] = {
			label = 'Snowball Launcher',
			weight = 1000,
			durability = 0.03,
			ammoname = 'WEAPON_SNOWBALL',
			rzTier = 'interdit',
		},

		['WEAPON_SNOWBALL'] = {
			label = 'Snow Ball',
			weight = 5,
			throwable = true,
			rzTier = 'interdit',
		},

		['WEAPON_BALL'] = {
			label = 'Ball',
			weight = 149,
			throwable = true,
			rzTier = 'interdit',
		},

		['WEAPON_FIREWORK'] = {
			label = 'Firework Launcher',
			weight = 1000,
			durability = 0.5,
			ammoname = 'ammo-firework',
			rzTier = 'interdit',
		},

		['WEAPON_CANDYCANE'] = {
			label = 'Candy Cane',
			weight = 85,
			durability = 0.1,
			rzTier = 'interdit',
		},

		['WEAPON_BZGAS'] = {
			label = 'BZ Gas',
			weight = 600,
			throwable = true,
			rzTier = 'interdit',
		},

		['WEAPON_TEARGAS'] = {
			label = 'Tear Gas',
			weight = 600,
			throwable = true,
			rzTier = 'interdit',
		},

	},
	Components = {
		['at_flashlight'] = {
			label = 'Tactical Flashlight',
			weight = 120,
			type = 'flashlight',
			client = {
				component = {
					`COMPONENT_AT_AR_FLSH`,
					`COMPONENT_AT_AR_FLSH_REH`,
					`COMPONENT_AT_PI_FLSH`,
					`COMPONENT_AT_PI_FLSH_02`,
					`COMPONENT_AT_PI_FLSH_03`,
				},
				usetime = 2500
			}
		},

		['at_suppressor_light'] = {
			label = 'Suppressor',
			weight = 280,
			type = 'muzzle',
			client = {
                image = 'at_suppressor.png',
				component = {
					`COMPONENT_AT_PI_SUPP`,
					`COMPONENT_AT_PI_SUPP_02`,
					`COMPONENT_CERAMICPISTOL_SUPP`,
					`COMPONENT_PISTOLXM3_SUPP`
				},
				usetime = 2500
			}
		},

		['at_suppressor_heavy'] = {
			label = 'Tactical Suppressor',
			weight = 280,
			type = 'muzzle',
			client = {
                image = 'at_suppressor.png',
				component = {
					`COMPONENT_AT_AR_SUPP`,
					`COMPONENT_AT_AR_SUPP_02`,
					`COMPONENT_AT_SR_SUPP`,
					`COMPONENT_AT_SR_SUPP_03`,
				},
				usetime = 2500
			}
		},

		['at_grip'] = {
			label = 'Grip',
			type = 'grip',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_AR_AFGRIP`,
					`COMPONENT_AT_AR_AFGRIP_02`
				},
				usetime = 2500
			}
		},

		['at_barrel'] = {
			label = 'Heavy Barrel',
			type = 'barrel',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_AR_BARREL_02`,
					`COMPONENT_AT_BP_BARREL_02`,
					`COMPONENT_AT_CR_BARREL_02`,
					`COMPONENT_AT_MG_BARREL_02`,
					`COMPONENT_AT_MRFL_BARREL_02`,
					`COMPONENT_AT_SB_BARREL_02`,
					`COMPONENT_AT_SC_BARREL_02`,
					`COMPONENT_AT_SR_BARREL_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_pistol'] = {
			label = 'Extended Pistol Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended.png',
				component = {
					`COMPONENT_APPISTOL_CLIP_02`,
					`COMPONENT_CERAMICPISTOL_CLIP_02`,
					`COMPONENT_COMBATPISTOL_CLIP_02`,
					`COMPONENT_HEAVYPISTOL_CLIP_02`,
					`COMPONENT_PISTOL_CLIP_02`,
					`COMPONENT_PISTOL_MK2_CLIP_02`,
					`COMPONENT_PISTOL50_CLIP_02`,
					`COMPONENT_SNSPISTOL_CLIP_02`,
					`COMPONENT_SNSPISTOL_MK2_CLIP_02`,
					`COMPONENT_VINTAGEPISTOL_CLIP_02`,
                    `COMPONENT_TECPISTOL_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_smg'] = {
			label = 'Extended SMG Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended.png',
				component = {
					`COMPONENT_ASSAULTSMG_CLIP_02`,
					`COMPONENT_COMBATPDW_CLIP_02`,
					`COMPONENT_MACHINEPISTOL_CLIP_02`,
					`COMPONENT_MICROSMG_CLIP_02`,
					`COMPONENT_MINISMG_CLIP_02`,
					`COMPONENT_SMG_CLIP_02`,
					`COMPONENT_SMG_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_shotgun'] = {
			label = 'Extended Shotgun Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_ASSAULTSHOTGUN_CLIP_02`,
					`COMPONENT_HEAVYSHOTGUN_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_rifle'] = {
			label = 'Extended Rifle Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_ADVANCEDRIFLE_CLIP_02`,
					`COMPONENT_ASSAULTRIFLE_CLIP_02`,
					`COMPONENT_ASSAULTRIFLE_MK2_CLIP_02`,
					`COMPONENT_BULLPUPRIFLE_CLIP_02`,
					`COMPONENT_BULLPUPRIFLE_MK2_CLIP_02`,
					`COMPONENT_CARBINERIFLE_CLIP_02`,
					`COMPONENT_CARBINERIFLE_MK2_CLIP_02`,
					`COMPONENT_COMPACTRIFLE_CLIP_02`,
					`COMPONENT_HEAVYRIFLE_CLIP_02`,
					`COMPONENT_MILITARYRIFLE_CLIP_02`,
					`COMPONENT_SPECIALCARBINE_CLIP_02`,
					`COMPONENT_SPECIALCARBINE_MK2_CLIP_02`,
					`COMPONENT_TACTICALRIFLE_CLIP_02`,
					`COMPONENT_BATTLERIFLE_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_mg'] = {
			label = 'Extended MG Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_GUSENBERG_CLIP_02`,
					`COMPONENT_MG_CLIP_02`,
					`COMPONENT_COMBATMG_CLIP_02`,
					`COMPONENT_COMBATMG_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_extended_sniper'] = {
			label = 'Extended Sniper Clip',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_extended2.png',
				component = {
					`COMPONENT_HEAVYSNIPER_MK2_CLIP_02`,
					`COMPONENT_MARKSMANRIFLE_CLIP_02`,
					`COMPONENT_MARKSMANRIFLE_MK2_CLIP_02`,
				},
				usetime = 2500
			}
		},

		['at_clip_drum_smg'] = {
			label = 'SMG Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_COMBATPDW_CLIP_03`,
					`COMPONENT_MACHINEPISTOL_CLIP_03`,
					`COMPONENT_SMG_CLIP_03`,
				},
				usetime = 2500
			}
		},

		['at_clip_drum_shotgun'] = {
			label = 'Shotgun Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_HEAVYSHOTGUN_CLIP_03`
				},
				usetime = 2500
			}
		},

		['at_clip_drum_rifle'] = {
			label = 'Rifle Drum',
			type = 'magazine',
			weight = 280,
			client = {
                image = 'at_clip_drum.png',
				component = {
					`COMPONENT_ASSAULTRIFLE_CLIP_03`,
					`COMPONENT_COMPACTRIFLE_CLIP_03`,
					`COMPONENT_CARBINERIFLE_CLIP_03`,
					`COMPONENT_SPECIALCARBINE_CLIP_03`,
				},
				usetime = 2500
			}
		},

		['at_compensator'] = {
			label = 'Compensator',
			type = 'muzzle',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_PI_COMP`,
					`COMPONENT_AT_PI_COMP_02`,
					`COMPONENT_AT_PI_COMP_03`
				},
				usetime = 2500
			}
		},

		['at_scope_macro'] = {
			label = 'Macro Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MACRO`,
					`COMPONENT_AT_SCOPE_MACRO_02`,
					`COMPONENT_AT_SCOPE_MACRO_MK2`,
					`COMPONENT_AT_SCOPE_MACRO_02_MK2`,
					`COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_small'] = {
			label = 'Small Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_SMALL`,
					`COMPONENT_AT_SCOPE_SMALL_02`,
					`COMPONENT_AT_SCOPE_SMALL_MK2`,
					`COMPONENT_AT_SCOPE_SMALL_SMG_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_medium'] = {
			label = 'Medium Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MEDIUM`,
					`COMPONENT_AT_SCOPE_MEDIUM_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_large'] = {
			label = 'Large Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_LARGE_MK2`
				},
				usetime = 2500
			}
		},

		['at_scope_advanced'] = {
			label = 'Advanced Scope',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_MAX`
				},
				usetime = 2500
			}
		},

		['at_scope_nv'] = {
			label = 'NV Scope',
			type = 'sight',
			weight = 420,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_NV`
				},
				usetime = 2500
			}
		},

		['at_scope_thermal'] = {
			label = 'Thermal Scope',
			type = 'sight',
			weight = 420,
			client = {
				component = {
					`COMPONENT_AT_SCOPE_THERMAL`
				},
				usetime = 2500
			}
		},

		['at_scope_holo'] = {
			label = 'Holographic Sight',
			type = 'sight',
			weight = 280,
			client = {
				component = {
					`COMPONENT_AT_PI_RAIL`,
					`COMPONENT_AT_PI_RAIL_02`,
					`COMPONENT_AT_SIGHTS`,
					`COMPONENT_AT_SIGHTS_SMG`
				},
				usetime = 2500
			}
		},

		['at_muzzle_flat'] = {
			label = 'Flat Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_01`
				},
				usetime = 2500
			}
		},

		['at_muzzle_tactical'] = {
			label = 'Tactical Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_02`
				},
				usetime = 2500
			}
		},

		['at_muzzle_fat'] = {
			label = 'Fat Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_03`
				},
				usetime = 2500
			}
		},

		['at_muzzle_precision'] = {
			label = 'Precision Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_04`
				},
				usetime = 2500
			}
		},

		['at_muzzle_heavy'] = {
			label = 'Heavy Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_05`
				},
				usetime = 2500
			}
		},

		['at_muzzle_slanted'] = {
			label = 'Slanted Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_06`
				},
				usetime = 2500
			}
		},

		['at_muzzle_split'] = {
			label = 'Split Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_07`
				},
				usetime = 2500
			}
		},

		['at_muzzle_squared'] = {
			label = 'Squared Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_08`
				},
				usetime = 2500
			}
		},

		['at_muzzle_bell'] = {
			label = 'Bell Muzzle',
			type = 'muzzle',
			weight = 80,
			client = {
				component = {
					`COMPONENT_AT_MUZZLE_09`
				},
				usetime = 2500
			}
		},

		['at_skin_luxe'] = {
			label = 'Luxury Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_VARMOD_LUXE`,
					`COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER`,
					`COMPONENT_CARBINERIFLE_VARMOD_LUXE`,
					`COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER`,
					`COMPONENT_MARKSMANRIFLE_VARMOD_LUXE`,
					`COMPONENT_MG_VARMOD_LOWRIDER`,
					`COMPONENT_MICROSMG_VARMOD_LUXE`,
					`COMPONENT_PISTOL_VARMOD_LUXE`,
					`COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER`,
					`COMPONENT_SMG_VARMOD_LUXE`
				},
				usetime = 2500
			}
		},

		['at_skin_wood'] = {
			label = 'Wood Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_HEAVYPISTOL_VARMOD_LUXE`,
					`COMPONENT_SNIPERRIFLE_VARMOD_LUXE`,
					`COMPONENT_SNSPISTOL_VARMOD_LOWRIDER`
				},
				usetime = 2500
			}
		},

		['at_skin_metal'] = {
			label = 'Metal Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE`,
					`COMPONENT_APPISTOL_VARMOD_LUXE`,
					`COMPONENT_BULLPUPRIFLE_VARMOD_LOW`,
					`COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE`,
					`COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER`
				},
				usetime = 2500
			}
		},

		['at_skin_pearl'] = {
			label = 'Pearl Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_PISTOL50_VARMOD_LUXE`
				},
				usetime = 2500
			}
		},

		['at_skin_ballas'] = {
			label = 'Ballas Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_BALLAS`
				},
				usetime = 2500
			}
		},

		['at_skin_diamond'] = {
			label = 'Diamond Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_DIAMOND`
				},
				usetime = 2500
			}
		},

		['at_skin_dollar'] = {
			label = 'Dollar Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_DOLLAR`
				},
				usetime = 2500
			}
		},

		['at_skin_hate'] = {
			label = 'Hate Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_HATE`
				},
				usetime = 2500
			}
		},

		['at_skin_king'] = {
			label = 'King Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_KING`
				},
				usetime = 2500
			}
		},

		['at_skin_love'] = {
			label = 'Love Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_LOVE`
				},
				usetime = 2500
			}
		},

		['at_skin_pimp'] = {
			label = 'Pimp Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_PIMP`
				},
				usetime = 2500
			}
		},

		['at_skin_player'] = {
			label = 'Player Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_PLAYER`
				},
				usetime = 2500
			}
		},

		['at_skin_vagos'] = {
			label = 'Vagos Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_KNUCKLE_VARMOD_VAGOS`
				},
				usetime = 2500
			}
		},

		['at_skin_blagueurs'] = {
			label = 'Blagueurs Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3`
				},
				usetime = 2500
			}
		},

		['at_skin_splatter'] = {
			label = 'Splatter Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_01`
				},
				usetime = 2500
			}
		},

		['at_skin_bulletholes'] = {
			label = 'Bullet Holes Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_02`
				},
				usetime = 2500
			}
		},

		['at_skin_burgershot'] = {
			label = 'Burger Shot Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_03`
				},
				usetime = 2500
			}
		},

		['at_skin_cluckinbell'] = {
			label = 'Cluckin Bell Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_04`
				},
				usetime = 2500
			}
		},

		['at_skin_fatalincursion'] = {
			label = 'Fatal Incursion Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_05`
				},
				usetime = 2500
			}
		},

		['at_skin_luchalibre'] = {
			label = 'Lucha Libre Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_06`
				},
				usetime = 2500
			}
		},

		['at_skin_trippy'] = {
			label = 'Trippy Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_07`
				},
				usetime = 2500
			}
		},

		['at_skin_tiedye'] = {
			label = 'Tie-Dye Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_08`
				},
				usetime = 2500
			}
		},

		['at_skin_wall'] = {
			label = 'Wall Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_BAT_VARMOD_XM3_09`
				},
				usetime = 2500
			}
		},

		['at_skin_vip'] = {
			label = 'VIP Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_REVOLVER_VARMOD_BOSS`,
					`COMPONENT_SWITCHBLADE_VARMOD_VAR1`
				},
				usetime = 2500
			}
		},

		['at_skin_bodyguard'] = {
			label = 'Bodyguard Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_REVOLVER_VARMOD_GOON`,
					`COMPONENT_SWITCHBLADE_VARMOD_VAR2`
				},
				usetime = 2500
			}
		},

		['at_skin_festive'] = {
			label = 'Festive Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_RAYPISTOL_VARMOD_XMAS18`
				},
				usetime = 2500
			}
		},

		['at_skin_security'] = {
			label = 'Security Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_APPISTOL_VARMOD_SECURITY`,
					`COMPONENT_MICROSMG_VARMOD_SECURITY`,
				},
				usetime = 2500
			}
		},

		['at_skin_camo'] = {
			label = 'Camo Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO`,
					`COMPONENT_COMBATMG_MK2_CAMO`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO`,
					`COMPONENT_PISTOL_MK2_CAMO`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO`,
					`COMPONENT_REVOLVER_MK2_CAMO`,
					`COMPONENT_SMG_MK2_CAMO`,
					`COMPONENT_SNSPISTOL_MK2_CAMO`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO`,
				},
				usetime = 2500
			}
		},

		['at_skin_brushstroke'] = {
			label = 'Brushstroke Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_02`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_02`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_02`,
					`COMPONENT_COMBATMG_MK2_CAMO_02`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_02`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_02`,
					`COMPONENT_PISTOL_MK2_CAMO_02`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_02`,
					`COMPONENT_REVOLVER_MK2_CAMO_02`,
					`COMPONENT_SMG_MK2_CAMO_02`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_02`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_02`,
				},
				usetime = 2500
			}
		},

		['at_skin_woodland'] = {
			label = 'Woodland Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_03`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_03`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_03`,
					`COMPONENT_COMBATMG_MK2_CAMO_03`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_03`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_03`,
					`COMPONENT_PISTOL_MK2_CAMO_03`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_03`,
					`COMPONENT_REVOLVER_MK2_CAMO_03`,
					`COMPONENT_SMG_MK2_CAMO_03`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_03`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_03`,
				},
				usetime = 2500
			}
		},

		['at_skin_skull'] = {
			label = 'Skull Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_04`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_04`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_04`,
					`COMPONENT_COMBATMG_MK2_CAMO_04`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_04`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_04`,
					`COMPONENT_PISTOL_MK2_CAMO_04`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_04`,
					`COMPONENT_REVOLVER_MK2_CAMO_04`,
					`COMPONENT_SMG_MK2_CAMO_04`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_04`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_04`,
				},
				usetime = 2500
			}
		},

		['at_skin_sessanta'] = {
			label = 'Sessanta Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_05`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_05`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_05`,
					`COMPONENT_COMBATMG_MK2_CAMO_05`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_05`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_05`,
					`COMPONENT_PISTOL_MK2_CAMO_05`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_05`,
					`COMPONENT_REVOLVER_MK2_CAMO_05`,
					`COMPONENT_SMG_MK2_CAMO_05`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_05`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_05`,
				},
				usetime = 2500
			}
		},

		['at_skin_perseus'] = {
			label = 'Perseus Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_06`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_06`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_06`,
					`COMPONENT_COMBATMG_MK2_CAMO_06`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_06`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_06`,
					`COMPONENT_PISTOL_MK2_CAMO_06`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_06`,
					`COMPONENT_REVOLVER_MK2_CAMO_06`,
					`COMPONENT_SMG_MK2_CAMO_06`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_06`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_06`,
				},
				usetime = 2500
			}
		},

		['at_skin_leopard'] = {
			label = 'Leopard Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_07`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_07`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_07`,
					`COMPONENT_COMBATMG_MK2_CAMO_07`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_07`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_07`,
					`COMPONENT_PISTOL_MK2_CAMO_07`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_07`,
					`COMPONENT_REVOLVER_MK2_CAMO_07`,
					`COMPONENT_SMG_MK2_CAMO_07`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_07`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_07`,
				},
				usetime = 2500
			}
		},

		['at_skin_zebra'] = {
			label = 'Zebra Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_08`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_08`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_08`,
					`COMPONENT_COMBATMG_MK2_CAMO_08`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_08`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_08`,
					`COMPONENT_PISTOL_MK2_CAMO_08`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_08`,
					`COMPONENT_REVOLVER_MK2_CAMO_08`,
					`COMPONENT_SMG_MK2_CAMO_08`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_08`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_08`,
				},
				usetime = 2500
			}
		},

		['at_skin_geometric'] = {
			label = 'Geometric Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_09`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_09`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_09`,
					`COMPONENT_COMBATMG_MK2_CAMO_09`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_09`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_09`,
					`COMPONENT_PISTOL_MK2_CAMO_09`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_09`,
					`COMPONENT_REVOLVER_MK2_CAMO_09`,
					`COMPONENT_SMG_MK2_CAMO_09`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_09`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_09`,
				},
				usetime = 2500
			}
		},

		['at_skin_boom'] = {
			label = 'Boom Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_10`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_10`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_10`,
					`COMPONENT_COMBATMG_MK2_CAMO_10`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_10`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_10`,
					`COMPONENT_PISTOL_MK2_CAMO_10`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_10`,
					`COMPONENT_REVOLVER_MK2_CAMO_10`,
					`COMPONENT_SMG_MK2_CAMO_10`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_10`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_10`,
				},
				usetime = 2500
			}
		},

		['at_skin_patriotic'] = {
			label = 'Patriotic Weapon Kit',
			type = 'skin',
			weight = 50,
			client = {
				component = {
					`COMPONENT_ASSAULTRIFLE_MK2_CAMO_IND_01`,
					`COMPONENT_BULLPUPRIFLE_MK2_CAMO_IND_01`,
					`COMPONENT_CARBINERIFLE_MK2_CAMO_IND_01`,
					`COMPONENT_COMBATMG_MK2_CAMO_IND_01`,
					`COMPONENT_HEAVYSNIPER_MK2_CAMO_IND_01`,
					`COMPONENT_MARKSMANRIFLE_MK2_CAMO_IND_01`,
					`COMPONENT_PISTOL_MK2_CAMO_IND_01`,
					`COMPONENT_PUMPSHOTGUN_MK2_CAMO_IND_01`,
					`COMPONENT_REVOLVER_MK2_CAMO_IND_01`,
					`COMPONENT_SMG_MK2_CAMO_IND_01`,
					`COMPONENT_SNSPISTOL_MK2_CAMO_IND_01`,
					`COMPONENT_SPECIALCARBINE_MK2_CAMO_IND_01`,
				},
				usetime = 2500
			}
		},
	},

	Ammo = {
		['ammo-22'] = {
			label = '.22 Long Rifle',
			weight = 3,
		},

		['ammo-38'] = {
			label = '.38 LC',
			weight = 15,
		},

		['ammo-44'] = {
			label = '.44 Magnum',
			weight = 16,
		},

		['ammo-45'] = {
			label = '.45 ACP',
			weight = 15,
		},

		['ammo-50'] = {
			label = '.50 AE',
			weight = 45,
		},

		['ammo-9'] = {
			label = '9mm',
			weight = 7,
		},

		['ammo-firework'] = {
			label = 'Firework',
			weight = 200,
		},

		['ammo-flare'] = {
			label = 'Flare round',
			weight = 38,
		},

		['ammo-grenade'] = {
			label = '40mm Explosive',
			weight = 400,
		},

		['ammo-heavysniper'] = {
			label = '.50 BMG',
			weight = 51,
		},

		['ammo-laser'] = {
			label = 'Laser charge',
			weight = 1,
		},

		['ammo-musket'] = {
			label = '.50 Ball',
			weight = 38,
		},

		['ammo-railgun'] = {
			label = 'Railgun charge',
			weight = 150,
		},

		['ammo-rifle'] = {
			label = '5.56x45',
			weight = 4,
		},

		['ammo-rifle2'] = {
			label = '7.62x39',
			weight = 8,
		},

		['ammo-rocket'] = {
			label = 'Rocket',
			weight = 500,
		},

		['ammo-shotgun'] = {
			label = '12 Gauge',
			weight = 38,
		},

		['ammo-sniper'] = {
			label = '7.62x51',
			weight = 9,
		},

		['ammo-emp'] = {
			label = 'EMP round',
			weight = 400,
		},
	}
}
