Config = {}

Config.Debug = false


-- ═══════════════════════════════════════════════════════════════════
--  LES WEBHOOKS
--
--  Un webhook par salon. Colle l'URL complète, celle qui commence
--  par https://discord.com/api/webhooks/
--
--  ⚠️  UN WEBHOOK EST UN SECRET. Quiconque l'obtient peut écrire
--  dans ton salon. Ce fichier ne doit JAMAIS partir sur GitHub :
--  ajoute-le à ton .gitignore.
--
--  Laisse une valeur vide pour désactiver une catégorie : ses
--  messages seront simplement ignorés, sans erreur.
--
--  Plusieurs catégories peuvent partager le même webhook si tu
--  préfères moins de salons.
-- ═══════════════════════════════════════════════════════════════════
Config.Webhooks = {
    mort        = 'https://discord.com/api/webhooks/1543406211872063488/xU8sj_sl0A2mBodwErTEpxbQS0-UcqQhKcXAmpjlXmZ_xdcAwQo-CJ3JLpoPiS0sjgWg',   -- morts, agonies, réanimations
    inventaire  = 'https://discord.com/api/webhooks/1543406494954029107/va9r9uxDpIkmbs1toYZVHAYRRw2TLlKqgnOJ3W9rPwSrf0CLNoI9nTCVNCni6eGoPcuQ',   -- ajouts, retraits, transferts d'items
    craft       = 'https://discord.com/api/webhooks/1543407516606800024/AL9ihyzZiBLgPzDJRRZTRa7zoIbPJhfhoLXj8fYzihpir15ppxRiTNSp_4rHoCcSsFXW',   -- fabrications, boîte aux lettres
    coffres     = 'https://discord.com/api/webhooks/1543406350032179310/4JkZdn-J43r_ZR33WUn587ccr5RQs3nv42p4mG52XRCmQa3Vz2vjwezHbd4qDzitYva4',   -- coffres de sécurité remis et ouverts
    giveweeapon = 'https://discord.com/api/webhooks/1543407205515010119/QWmqUhnAvzz8kWtgjrfsza4U5kG7mVfqFoRQ5M5_f9uccTBc3a0RSGzGfFQyw9TKj_xU',   -- actions du staff, /giveitem, sanctions
    giveitems   = 'https://discord.com/api/webhooks/1543406867730931792/WLSkuYLBjXLeT1-qao9m2JEC23MivS-6cSIDMA1bw0Vp0-Wr6dFPpf-lvvoNF9Ohz8dt',   -- arrivées et départs
    weapon     = 'https://discord.com/api/webhooks/1543407913295552562/L62kmWjxDkvmVWZRWse8LAsPk6KifujwnpMIUI-dw1gQlPFXCdSMG6DaiZUMXCE1ZoR8',   -- tirs bloqués en safe zone, comportements douteux
    loot       = 'https://discord.com/api/webhooks/1543407457144147998/AzWm5wnjof6GdUtXP5b54o-Eux6QglQMBqF4ITZeQcJXsOvi1dj1dOtA5UvHxvn5a-i7',   -- blackout, réseau, zone radioactive
    Crash     = 'https://discord.com/api/webhooks/1543407298599460884/yJDlPmj3La2iIHJUWWwyXbAK7O1ru95b8C9IA7W_5v6KjH5i5KakxiryEPi0XlueQpGY',   -- pannes du serveur, échecs de webhook
    Airdrop     = 'https://discord.com/api/webhooks/1543676799664525413/XZ3XEqmkaOk3tc1udvdwLjVtxx6NSd4uioZhZ4zwkkidiog7BwFnDQlKrTIuhUL0tFGD',   -- ouverture de caisse et loots, échecs de webhook
}


-- ═══════════════════════════════════════════════════════════════════
--  APPARENCE
-- ═══════════════════════════════════════════════════════════════════
Config.Appearance = {
    username = 'RedZone',
    avatar   = 'https://i.postimg.cc/5y60YptB/redzone-rond-logo.png',

    -- Pied de page de chaque message
    footer = 'RedZone Survival',

    -- Couleur par catégorie, en décimal
    colors = {
        mort        = 15548997,   -- rouge
        inventaire  = 3447003,    -- bleu
        craft       = 3066993,    -- vert
        coffres     = 15844367,   -- or
        admin       = 10181046,   -- violet
        connexions  = 9807270,    -- gris
        suspect     = 15105570,   -- orange
        monde       = 1752220,    -- cyan
        erreurs     = 10038562,   -- bordeaux
        defaut      = 5793266,
    },
}


-- ═══════════════════════════════════════════════════════════════════
--  DÉBIT
--
--  Discord accepte 5 requêtes par 2 secondes et par webhook, et
--  30 par minute. Un serveur actif produit bien plus d'événements
--  que ça : sans file d'attente, les messages seraient rejetés en
--  silence et tu perdrais des logs sans le savoir.
--
--  On regroupe donc jusqu'à 10 messages par envoi — le maximum
--  qu'accepte Discord — et on espace les envois.
-- ═══════════════════════════════════════════════════════════════════
Config.Rate = {
    -- Millisecondes entre deux envois pour un même webhook
    interval = 2500,

    -- Nombre d'embeds regroupés par envoi (maximum Discord : 10)
    batchSize = 10,

    -- Taille maximale de la file par catégorie. Au-delà, les plus
    -- anciens messages sont abandonnés pour éviter que la mémoire
    -- du serveur ne gonfle indéfiniment.
    maxQueue = 300,

    -- Tentatives en cas d'échec réseau
    retries = 2,
}


-- ═══════════════════════════════════════════════════════════════════
--  FILTRAGE DES LOGS D'INVENTAIRE
--
--  C'est LE réglage à surveiller. ox_inventory génère un événement
--  à chaque mouvement d'item : sans filtre, un serveur de trente
--  joueurs noierait ton salon en quelques minutes et tu ne verrais
--  plus rien d'important.
-- ═══════════════════════════════════════════════════════════════════
Config.Inventory = {
    -- Journaliser les déplacements d'un slot à l'autre DANS le même
    -- inventaire. Presque toujours du bruit : le joueur range.
    logInternalMoves = false,

    -- Journaliser les transferts entre inventaires (don à un joueur,
    -- dépôt dans un coffre, ramassage au sol). Là c'est utile.
    logTransfers = true,

    -- Journaliser les ajouts et retraits faits par un SCRIPT.
    -- C'est ce qui capture les /giveitem du staff.
    logScriptChanges = true,

    -- Items à ne jamais journaliser : trop fréquents pour apporter
    -- quoi que ce soit.
    ignoreItems = {
        'water', 'bread', 'sprunk',
    },

    -- Ne journaliser que les mouvements d'au moins N unités.
    -- 1 = tout journaliser.
    minCount = 1,
}


-- ═══════════════════════════════════════════════════════════════════
--  CONNEXIONS
-- ═══════════════════════════════════════════════════════════════════
Config.Connections = {
    enabled = true,

    -- Inclure les identifiants dans le message. Pratique pour la
    -- modération, mais ce sont des données personnelles : le salon
    -- doit être réservé au staff.
    showIdentifiers = true,
}


-- ═══════════════════════════════════════════════════════════════════
--  OUTILS
-- ═══════════════════════════════════════════════════════════════════

---Cette catégorie est-elle active ?
---@param category string
---@return boolean
function Config.IsEnabled(category)
    local url = Config.Webhooks[category]
    return url ~= nil and url ~= ''
end

---Couleur d'une catégorie.
function Config.ColorOf(category)
    return Config.Appearance.colors[category] or Config.Appearance.colors.defaut
end

---Cet item doit-il être ignoré ?
function Config.IsIgnoredItem(name)
    if not name then return false end
    for _, ignored in ipairs(Config.Inventory.ignoreItems) do
        if ignored == name then return true end
    end
    return false
end
