--[[
    rz_boombox / server/main.lua

    Remplace wasabi_boombox (config.lua et dossier client/ disparus du
    disque, cf. le SCRIPT ERROR relevé le 2026-09-02). Même principe :
    poser une radio, y jouer un lien, sons favoris sauvegardés par
    joueur — écrit pour la stack réellement utilisée sur ce serveur
    (qbx_core + ox_inventory), pas pour l'ESX/qb-core d'origine.

    Les radios posées ne sont pas persistées en base, comme les
    caisses de rz_airdrop : une liste en mémoire suffit, et un
    redémarrage du serveur les fait de toute façon disparaître du
    monde côté client.
]]

local boomboxes = {}   -- [id] = { x, y, z, heading, citizenid }
local nextId = 0


local function dbg(...)
    if Config.Debug then print('^3[rz_boombox]^7', ...) end
end


CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rz_boombox_songs` (
            `citizenid` VARCHAR(64) NOT NULL,
            `label`     VARCHAR(50) NOT NULL,
            `link`      VARCHAR(255) NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)


---citizenid Qbox d'une source.
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end


-- ═══════════════════════════════════════════════════════════════════
--  POSE / RANGEMENT
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_boombox:confirmPlace', function(coords, heading)
    local src = source

    nextId = nextId + 1
    local id = nextId

    boomboxes[id] = {
        x = coords.x, y = coords.y, z = coords.z,
        heading = heading,
        citizenid = getCitizenId(src),
    }

    TriggerClientEvent('rz_boombox:spawn', -1, {
        id = id, x = coords.x, y = coords.y, z = coords.z, heading = heading,
    })

    dbg(('boombox %d posée par %s'):format(id, GetPlayerName(src) or '?'))
end)


RegisterNetEvent('rz_boombox:cancelPlace', function()
    exports.ox_inventory:AddItem(source, Config.Item, 1)
end)


RegisterNetEvent('rz_boombox:pickup', function(id)
    local src = source
    if not boomboxes[id] then return end

    boomboxes[id] = nil
    exports.ox_inventory:AddItem(src, Config.Item, 1)
    TriggerClientEvent('rz_boombox:remove', -1, id)

    dbg(('boombox %d rangée par %s'):format(id, GetPlayerName(src) or '?'))
end)


-- ═══════════════════════════════════════════════════════════════════
--  LECTURE
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('rz_boombox:play', function(id, url)
    local src = source
    if not boomboxes[id] then return end
    if type(url) ~= 'string' or url == '' or #url > 255 then return end

    TriggerClientEvent('rz_boombox:playSound', -1, id, url)

    if Config.LogCategory and GetResourceState('rz_logs') == 'started' then
        pcall(function()
            exports.rz_logs:Log(Config.LogCategory, {
                title       = 'Son joué',
                description = ('**%s** a lancé un son sur la boombox #%d\n%s')
                    :format(GetPlayerName(src) or '?', id, url),
                source      = src,
            })
        end)
    end
end)


RegisterNetEvent('rz_boombox:stop', function(id)
    if not boomboxes[id] then return end
    TriggerClientEvent('rz_boombox:stopSound', -1, id)
end)


-- ═══════════════════════════════════════════════════════════════════
--  SONS SAUVEGARDÉS
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_boombox:getSavedSongs', function(source)
    local citizenid = getCitizenId(source)
    if not citizenid then return {} end

    return MySQL.query.await(
        'SELECT label, link FROM rz_boombox_songs WHERE citizenid = ?', { citizenid }
    ) or {}
end)


RegisterNetEvent('rz_boombox:saveSong', function(label, link)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    if type(label) ~= 'string' or type(link) ~= 'string' then return end

    MySQL.insert(
        'INSERT INTO rz_boombox_songs (citizenid, label, link) VALUES (?, ?, ?)',
        { citizenid, label:sub(1, 50), link:sub(1, 255) }
    )
end)


-- ═══════════════════════════════════════════════════════════════════
--  SYNCHRONISATION À LA CONNEXION
-- ═══════════════════════════════════════════════════════════════════

lib.callback.register('rz_boombox:getBoomboxes', function()
    local list = {}
    for id, b in pairs(boomboxes) do
        list[#list + 1] = { id = id, x = b.x, y = b.y, z = b.z, heading = b.heading }
    end
    return list
end)
