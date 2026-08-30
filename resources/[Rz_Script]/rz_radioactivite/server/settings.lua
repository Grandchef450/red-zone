--[[
    rz_radioactivite / server/settings.lua

    Tous les réglages de la ressource, modifiables en jeu.

    POURQUOI EN BASE PLUTÔT QU'EN FICHIER
    Un équilibrage se fait par petites touches, souvent le soir
    après une session de test. Devoir éditer un fichier et
    redémarrer à chaque essai décourage l'ajustement — et on finit
    par garder des valeurs qu'on sait mauvaises.

    Le config.lua ne sert plus que de valeurs par défaut, utilisées
    au tout premier démarrage pour amorcer la base.
]]

-- Les réglages vivants. Chaque entrée liste son chemin dans Config,
-- son type, et ses bornes — c'est ce qui permet au menu de se
-- construire tout seul et au serveur de refuser une valeur absurde.
SETTINGS = {
    -- ─── DÉGÂTS ────────────────────────────────────────────────
    { key = 'damageAmount',    label = 'Dégâts par intervalle',
      path = { 'Damage', 'amount' },       type = 'number',
      min = 0.01, max = 50, step = 0.25, group = 'degats',
      note = 'Points de santé retirés à chaque passage' },

    { key = 'damageInterval',  label = 'Intervalle (secondes)',
      path = { 'Damage', 'intervalMs' },   type = 'seconds',
      min = 5, max = 300, step = 5, group = 'degats',
      note = 'Toutes les combien de secondes les dégâts tombent' },

    { key = 'damageFloor',     label = 'Plancher de santé',
      path = { 'Damage', 'floor' },        type = 'number',
      min = 0, max = 150, step = 5, group = 'degats',
      note = '0 pour autoriser la mort par radiation' },

    { key = 'escalateEnabled', label = 'Dégâts progressifs',
      path = { 'Damage', 'escalate', 'enabled' }, type = 'boolean',
      group = 'degats',
      note = 'Les dégâts augmentent avec la durée d\'exposition' },

    { key = 'escalateRamp',    label = 'Palier de montée (minutes)',
      path = { 'Damage', 'escalate', 'rampMinutes' }, type = 'number',
      min = 1, max = 120, step = 1, group = 'degats',
      note = 'Après ce délai, les dégâts sont multipliés' },

    { key = 'escalateFactor',  label = 'Multiplicateur',
      path = { 'Damage', 'escalate', 'factor' }, type = 'number',
      min = 1.0, max = 20.0, step = 0.5, group = 'degats',
      note = 'De combien les dégâts sont multipliés à chaque palier' },

    { key = 'escalateMax',     label = 'Multiplicateur maximum',
      path = { 'Damage', 'escalate', 'maxMultiplier' }, type = 'number',
      min = 1.0, max = 100.0, step = 1.0, group = 'degats',
      note = 'Plafond, pour éviter la mort instantanée' },

    -- ─── MASQUES ───────────────────────────────────────────────
    { key = 'maskCharges',     label = 'Charges par masque',
      path = { 'MaskCharges' },            type = 'number',
      min = 1, max = 20, step = 1, group = 'masques',
      note = 'Nombre d\'activations avant qu\'un masque soit usé' },

    { key = 'maskSimple',      label = 'Masque simple (minutes)',
      path = { 'Masks', 'masque_simple', 'minutes' }, type = 'number',
      min = 1, max = 240, step = 5, group = 'masques' },

    { key = 'maskChimique',    label = 'Masque chimique (minutes)',
      path = { 'Masks', 'masque_chimique', 'minutes' }, type = 'number',
      min = 1, max = 240, step = 5, group = 'masques' },

    { key = 'maskCartouche',   label = 'Masque à cartouche (minutes)',
      path = { 'Masks', 'masque_cartouche', 'minutes' }, type = 'number',
      min = 1, max = 240, step = 5, group = 'masques' },

    { key = 'maskDouble',      label = 'Double cartouche (minutes)',
      path = { 'Masks', 'masque_double_cartouche', 'minutes' }, type = 'number',
      min = 1, max = 480, step = 5, group = 'masques' },

    -- ─── CYCLE ─────────────────────────────────────────────────
    { key = 'dormantMin',      label = 'Accalmie minimum (minutes)',
      path = { 'Cycle', 'dormantMin' },    type = 'number',
      min = 1, max = 480, step = 5, group = 'cycle' },

    { key = 'dormantMax',      label = 'Accalmie maximum (minutes)',
      path = { 'Cycle', 'dormantMax' },    type = 'number',
      min = 1, max = 480, step = 5, group = 'cycle' },

    { key = 'warningSeconds',  label = 'Délai après annonce (secondes)',
      path = { 'Cycle', 'warningSeconds' }, type = 'number',
      min = 0, max = 900, step = 15, group = 'cycle',
      note = 'Temps entre l\'annonce pager et l\'arrivée du nuage' },

    { key = 'maxActive',       label = 'Durée max d\'un nuage (minutes)',
      path = { 'Cycle', 'maxActiveMinutes' }, type = 'number',
      min = 5, max = 480, step = 5, group = 'cycle' },

    -- ─── AVERTISSEMENTS ────────────────────────────────────────
    { key = 'warnEnabled',     label = 'Avertissements activés',
      path = { 'Warnings', 'enabled' },    type = 'boolean', group = 'alertes' },

    { key = 'warnDistance',    label = 'Distance d\'approche',
      path = { 'Warnings', 'approachDistance' }, type = 'number',
      min = 50, max = 2000, step = 50, group = 'alertes',
      note = 'À quelle distance du nuage on est prévenu' },

    { key = 'warnCooldown',    label = 'Délai entre deux alertes (s)',
      path = { 'Warnings', 'cooldown' },   type = 'number',
      min = 10, max = 900, step = 10, group = 'alertes' },

    { key = 'maskLow',         label = 'Alerte filtre bas (secondes)',
      path = { 'Warnings', 'maskLowSeconds' }, type = 'number',
      min = 10, max = 600, step = 10, group = 'alertes',
      note = 'Prévenir quand il reste ce temps de protection' },

    -- ─── RENDU ─────────────────────────────────────────────────
    { key = 'darkness',        label = 'Assombrissement',
      path = { 'Visual', 'darkness' },     type = 'number',
      min = 0.0, max = 1.0, step = 0.05, group = 'visuel',
      note = '0 = aucun, 1 = noir complet' },

    { key = 'redVeil',         label = 'Intensité du rouge',
      path = { 'Visual', 'redVeil' },      type = 'number',
      min = 0.0, max = 1.0, step = 0.05, group = 'visuel' },

    { key = 'timecycleStr',    label = 'Force du filtre',
      path = { 'Visual', 'timecycleStrength' }, type = 'number',
      min = 0.0, max = 1.0, step = 0.05, group = 'visuel' },

    { key = 'fadeDistance',    label = 'Fondu à la bordure',
      path = { 'Visual', 'fadeDistance' }, type = 'number',
      min = 0, max = 500, step = 10, group = 'visuel',
      note = 'Distance sur laquelle l\'effet monte en entrant' },

    { key = 'grain',           label = 'Grain de compteur',
      path = { 'Visual', 'grain' },        type = 'boolean', group = 'visuel' },

    { key = 'blipEnabled',     label = 'Blip sur la carte',
      path = { 'Visual', 'blip', 'enabled' }, type = 'boolean', group = 'visuel' },

    -- ─── VOLUME ────────────────────────────────────────────────
    { key = 'minZ',            label = 'Plancher de la zone',
      path = { 'Zone', 'minZ' },           type = 'number',
      min = -1000, max = 500, step = 50, group = 'volume' },

    { key = 'maxZ',            label = 'Plafond de la zone',
      path = { 'Zone', 'maxZ' },           type = 'number',
      min = 0, max = 3000, step = 100, group = 'volume',
      note = 'Doit dépasser les toits, sinon on s\'y réfugie' },
}

GROUPS = {
    { key = 'degats',  label = 'Dégâts',          icon = 'fa-heart-crack' },
    { key = 'masques', label = 'Masques',         icon = 'fa-mask-face' },
    { key = 'cycle',   label = 'Rythme du cycle', icon = 'fa-clock-rotate-left' },
    { key = 'alertes', label = 'Avertissements',  icon = 'fa-triangle-exclamation' },
    { key = 'visuel',  label = 'Rendu visuel',    icon = 'fa-eye' },
    { key = 'volume',  label = 'Volume de la zone', icon = 'fa-cube' },
}


local function dbg(...)
    if Config.Debug then print('^3[rz_radiation]^7', ...) end
end


---Lit une valeur dans Config en suivant son chemin.
local function readPath(path)
    local node = Config
    for _, key in ipairs(path) do
        if type(node) ~= 'table' then return nil end
        node = node[key]
    end
    return node
end


---Écrit une valeur dans Config en suivant son chemin.
local function writePath(path, value)
    local node = Config

    for i = 1, #path - 1 do
        if type(node[path[i]]) ~= 'table' then return false end
        node = node[path[i]]
    end

    node[path[#path]] = value
    return true
end


---Définition d'un réglage par sa clé.
local function findSetting(key)
    for _, s in ipairs(SETTINGS) do
        if s.key == key then return s end
    end
    return nil
end


-- ═══════════════════════════════════════════════════════════════════
--  LECTURE ET ÉCRITURE
-- ═══════════════════════════════════════════════════════════════════

---Applique une valeur, en la bornant.
---@return any la valeur réellement appliquée
function ApplySetting(key, raw)
    local def = findSetting(key)
    if not def then return nil end

    local value

    if def.type == 'boolean' then
        value = raw == true or raw == 1 or raw == '1' or raw == 'true'

    elseif def.type == 'seconds' then
        -- Stocké en millisecondes dans Config, présenté en secondes
        local n = tonumber(raw) or 30
        n = math.max(def.min, math.min(def.max, n))
        value = math.floor(n * 1000)

    else
        local n = tonumber(raw)
        if not n then return nil end
        value = math.max(def.min, math.min(def.max, n))
    end

    writePath(def.path, value)
    return value
end


---Valeur actuelle, dans l'unité présentée à l'admin.
function ReadSetting(key)
    local def = findSetting(key)
    if not def then return nil end

    local raw = readPath(def.path)

    if def.type == 'seconds' then
        return math.floor((tonumber(raw) or 0) / 1000)
    end

    return raw
end


---Charge les réglages depuis la base.
function LoadSettings()
    local rows = MySQL.query.await(
        'SELECT setting, value FROM rz_radiation_settings') or {}

    local n = 0

    for _, r in ipairs(rows) do
        if ApplySetting(r.setting, r.value) ~= nil then
            n = n + 1
        end
    end

    dbg(('%d réglage(s) chargé(s) depuis la base'):format(n))
    return n
end


---Enregistre un réglage et l'applique tout de suite.
---@return boolean ok, string message
function SaveSetting(source, key, raw)
    local def = findSetting(key)
    if not def then return false, 'Réglage inconnu.' end

    local applied = ApplySetting(key, raw)
    if applied == nil then return false, 'Valeur invalide.' end

    local stored = def.type == 'seconds' and tostring(math.floor(applied / 1000))
        or tostring(applied)

    MySQL.prepare.await([[
        INSERT INTO rz_radiation_settings (setting, value, updated_by)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)
    ]], { key, stored, source and GetPlayerIdentifierByType(source, 'license') or nil })

    if source then
        MySQL.prepare('INSERT INTO rz_radiation_logs (admin, action, detail) VALUES (?, ?, ?)', {
            GetPlayerIdentifierByType(source, 'license'), 'setting',
            json.encode({ key = key, value = stored })
        })
    end

    dbg(('%s = %s'):format(key, stored))

    return true, ('%s : %s'):format(def.label, stored)
end


---Remet un groupe entier à ses valeurs d'origine.
function ResetGroup(source, group)
    local n = 0

    for _, def in ipairs(SETTINGS) do
        if def.group == group then
            MySQL.prepare.await(
                'DELETE FROM rz_radiation_settings WHERE setting = ?', { def.key })
            n = n + 1
        end
    end

    -- Le config.lua d'origine n'étant plus en mémoire, il faut
    -- recharger la ressource pour retrouver ses valeurs.
    return n
end


-- ═══════════════════════════════════════════════════════════════════
--  DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(1500)

    local n = LoadSettings()

    if n > 0 then
        print(('^2[rz_radiation]^7 %d réglage(s) restauré(s) depuis la base'):format(n))
    end
end)
