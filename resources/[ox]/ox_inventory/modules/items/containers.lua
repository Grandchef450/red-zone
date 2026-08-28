local containers = {}

---@class ItemContainerProperties
---@field slots number
---@field maxWeight number
---@field whitelist? table<string, true> | string[]
---@field blacklist? table<string, true> | string[]

local function arrayToSet(tbl)
	local size = #tbl
	local set = table.create(0, size)

	for i = 1, size do
		set[tbl[i]] = true
	end

	return set
end

---Registers items with itemName as containers (i.e. backpacks, wallets).
---@param itemName string
---@param properties ItemContainerProperties
---@todo Rework containers for flexibility, improved data structure; then export this method.
local function setContainerProperties(itemName, properties)
	local blacklist, whitelist = properties.blacklist, properties.whitelist

	if blacklist then
		local tableType = table.type(blacklist)

		if tableType == 'array' then
			blacklist = arrayToSet(blacklist)
		elseif tableType ~= 'hash' then
			TypeError('blacklist', 'table', type(blacklist))
		end
	end

	if whitelist then
		local tableType = table.type(whitelist)

		if tableType == 'array' then
			whitelist = arrayToSet(whitelist)
		elseif tableType ~= 'hash' then
			TypeError('whitelist', 'table', type(whitelist))
		end
	end

	containers[itemName] = {
		size = { properties.slots, properties.maxWeight },
		blacklist = blacklist,
		whitelist = whitelist,
	}
end

-- ═══════════════════════════════════════════════════════════════
--  REDZONE SURVIVAL — Conteneurs
--
--  Les exemples d'origine (paperbag, pizzabox) ont été retirés :
--  leurs items n'existent plus dans items.lua.
--
--  Un item déclaré ici s'ouvre en faisant « Utiliser » dessus dans
--  l'inventaire. Aucune autre configuration n'est nécessaire.
-- ═══════════════════════════════════════════════════════════════

-- ─── SACS À DOS ───────────────────────────────────────────────
-- maxWeight est en GRAMMES. Règle appliquée : 1 slot ≈ 1,5 kg,
-- soit la même densité que la capacité du joueur (120 kg pour
-- environ 80 slots utiles).
setContainerProperties('sac_survie_12',  { slots = 12,  maxWeight = 18000  })
setContainerProperties('sac_survie_32',  { slots = 32,  maxWeight = 48000  })
setContainerProperties('sac_survie_64',  { slots = 64,  maxWeight = 96000  })
setContainerProperties('sac_survie_72',  { slots = 72,  maxWeight = 108000 })
setContainerProperties('sac_survie_104', { slots = 104, maxWeight = 156000 })
setContainerProperties('sac_survie_134', { slots = 134, maxWeight = 201000 })


-- ─── COFFRES DE SÉCURITÉ ──────────────────────────────────────
--
--  Règles voulues pour RedZone :
--    • 128 slots pour tous, craft comme boutique
--    • aucune limite de poids à l'intérieur
--    • le coffre lui-même pèse 0 (défini dans items.lua)
--
--  Le poids « illimité » est en pratique un plafond si haut qu'il
--  ne sera jamais atteint : 100 tonnes. ox_inventory attend un
--  nombre, pas une absence de valeur.
--
--  La durée de validité (12h à 168h, 7 à 35 jours) n'est PAS gérée
--  ici : ox_inventory ne connaît pas la notion d'expiration. Elle
--  sera portée par rz_craft, avec le passage en lecture seule que
--  tu as demandé.

local COFFRE_SLOTS  = 128
local COFFRE_WEIGHT = 100000000   -- 100 t : jamais atteint

local coffres = {
    -- Craftables
    'coffre_securite_12h',
    'coffre_securite_24h',
    'coffre_securite_72h',
    'coffre_securite_96h',
    'coffre_securite_120h',
    'coffre_securite_144h',
    'coffre_securite_168h',

    -- Boutique
    'coffre_boutique_32_7j',
    'coffre_boutique_64_14j',
    'coffre_boutique_72_21j',
    'coffre_boutique_104_28j',
    'coffre_boutique_134_35j',
}

for _, itemName in ipairs(coffres) do
    setContainerProperties(itemName, {
        slots     = COFFRE_SLOTS,
        maxWeight = COFFRE_WEIGHT,
    })
end

return containers
