-- ============================================================
-- admin | Server/SMain.lua  — Full Reconstruction
-- Covers every RegisterNetEvent, lib.callback, and command
-- referenced from Client, NUI (app.js / groups.js / map.js),
-- Editable/Server/SMain.lua, and Config.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- State tables
-- ──────────────────────────────────────────────────────────────
local AdminSessions    = {}  -- [src] = { id, username, group, license, loginTime, headTagOn }
local PendingCredChange = {} -- [src] = { group } -- player prompted to replace the default credentials
local AdminGroups      = {}  -- [name] = { perms={}, color="" }
local TerminalViewers  = {}  -- [src] = true
local ScreenViewers    = {}  -- [viewerSrc] = targetSrc
local VoiceCallCh      = {}  -- [src] = channelId
local nextCallChannel  = 100
local ConsoleBuffer    = ""
local GlobalTimeState  = { hour = 12, minute = 0, freeze = false }
local GlobalWeather    = nil

-- ──────────────────────────────────────────────────────────────
-- Identifier helpers
-- ──────────────────────────────────────────────────────────────
local function GetLicense(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("license:") then return id end
    end
    return nil
end

local function GetDiscord(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("discord:") then return id end
    end
    return nil
end

local function GetSteam(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("steam:") then return id end
    end
    return nil
end

local function GetPlayerIp(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("ip:") then return id end
    end
    return nil
end

local function GetAllIds(src)
    local t = {}
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        t[#t + 1] = GetPlayerIdentifier(src, i)
    end
    return t
end

-- ──────────────────────────────────────────────────────────────
-- Session helpers
-- ──────────────────────────────────────────────────────────────
local function IsAdmin(src)
    return AdminSessions[src] ~= nil
end

local function GetAdminGroup(src)
    return AdminSessions[src] and AdminSessions[src].group or nil
end

local function GetAdminLabel(src)
    if AdminSessions[src] then return AdminSessions[src].username end
    return GetPlayerName(src) or tostring(src)
end

-- True if the given admin row still uses the configured default credentials.
-- Compared case-insensitively so it matches however the admin typed them
-- (the login query itself is case-insensitive under the default DB collation).
local function IsDefaultAccount(row)
    if not row then return false end
    local defUser = (Config.DefaultUsers and Config.DefaultUsers.user) or "Admin"
    local defPass = (Config.DefaultUsers and Config.DefaultUsers.password) or "123456"
    local u = tostring(row.username or ""):lower()
    local p = tostring(row.password or ""):lower()
    return u == tostring(defUser):lower() and p == tostring(defPass):lower()
end

-- hasAllowedGroup is used by Editable/Server/SMain.lua revive handler
function hasAllowedGroup(src)
    return IsAdmin(src)
end

local function HasPerm(src, perm)
    local grp = GetAdminGroup(src)
    if not grp then return false end
    local gdata = AdminGroups[grp]
    if not gdata then return false end
    local p = gdata.perms
    if p == true or (type(p) == "table" and (p["*"] or p[perm])) then return true end
    return false
end

local UiPermissionKeys = {
    "dashboard", "players", "map", "logs", "groups", "bans", "terminal", "comandos", "kick_action_menu", "reportes", "estadisticas",
    "info_admin", "announcements", "noclip", "server_time", "godmode", "invisibility", "staff_clothing", "tag_player", "admin_tag", "delete_vehicle", "fix_vehicle",
    "bring", "goto", "freeze", "viewScreen", "spectate", "capture", "skin", "job", "return", "items", "notes", "gang", "revive", "money", "admin", "kill",
    "clearinv", "ck", "instancia", "spawnvehicle", "add_player_vehicle", "delete_player_vehicle", "ban", "kick", "bans_unban", "bans_modify",
    "terminal_restart", "terminal_stop", "terminal_console", "log_server_join", "log_server_leave", "log_chat", "log_deaths", "log_kills", "log_explosions",
    "log_permissions", "log_admin_actions", "log_bans", "log_unbans", "log_tx_admin", "reportes_control_panel", "reportes_all_reports", "reportes_staff_chat",
    "tpm", "copy_coords", "tune_vehicle", "infiniteammo",
    -- Legacy aliases still used in some client checks.
    "invisible", "deletecar"
}

local PermKeyAliases = {
    invisible       = "invisibility",
    deletecar       = "delete_vehicle",
    deletevehicle   = "delete_vehicle",
    fixvehicle      = "fix_vehicle",
    servertime      = "server_time",
    staffclothing   = "staff_clothing",
    copycoords      = "copy_coords",
    tunevehicle     = "tune_vehicle",
    viewscreen      = "viewScreen",
    logadminactions = "log_admin_actions",
}

local function BuildClientPerms(rawPerms)
    if rawPerms == true then
        local allPerms = { ["*"] = true }
        for i = 1, #UiPermissionKeys do
            allPerms[UiPermissionKeys[i]] = true
        end
        return allPerms
    end
    if type(rawPerms) ~= "table" then return {} end

    local perms = {}
    for key, value in pairs(rawPerms) do
        perms[key] = value
        if type(key) == "string" then
            local alias = PermKeyAliases[key] or PermKeyAliases[key:lower()]
            if alias then
                perms[alias] = value
            end
        end
    end

    local hasWildcard = rawPerms["*"] == true or rawPerms["*"] == 1 or rawPerms["*"] == "1"
    if hasWildcard then
        for i = 1, #UiPermissionKeys do
            perms[UiPermissionKeys[i]] = true
        end
    end

    return perms
end

local function OpenAdminPanel(src, isNewLogin, sectionPerms, adminUsername)
    TriggerClientEvent(
        "adminpanel:open",
        src,
        isNewLogin == true,
        Config.ServerName or "Server",
        sectionPerms or {},
        {},
        {},
        adminUsername
    )
end

-- ──────────────────────────────────────────────────────────────
-- Discord webhook logger
-- ──────────────────────────────────────────────────────────────
local function SendWebhook(webhook, title, description, color)
    if not webhook or webhook == "" or webhook == "YOUR_WEBHOOK" then return end
    PerformHttpRequest(webhook, function() end, "POST", json.encode({
        embeds = {{
            title = tostring(title or ""),
            description = tostring(description or ""),
            color = color or 3447003,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }), { ["Content-Type"] = "application/json" })
end

-- ──────────────────────────────────────────────────────────────
-- Logging helper (DB + Discord)
-- ──────────────────────────────────────────────────────────────
function LogAdminAction(src, action, targetId, targetName, extraInfo)
    -- Discord log
    if Config.Logs and Config.Logs.admin_actions and Config.Logs.admin_actions.enable then
        local cfg = Config.Logs.admin_actions
        if cfg[action] ~= false then
            local webhook = Config.DiscordLogs and Config.DiscordLogs.admin_actions or ""
            local adminName = GetAdminLabel(src)
            local license   = GetLicense(src) or "N/A"
            local discord   = GetDiscord(src) or "N/A"
            local desc = string.format(
                "**Admin:** %s\n**License:** %s\n**Discord:** %s\n**Action:** %s",
                adminName, license, discord, action
            )
            if targetId then desc = desc .. "\n**Target:** " .. tostring(targetId) end
            if targetName then desc = desc .. " (" .. tostring(targetName) .. ")" end
            if extraInfo and extraInfo ~= "" then desc = desc .. "\n" .. tostring(extraInfo) end
            SendWebhook(webhook, "Admin Action: " .. action, desc, 16776960)
        end
    end
    -- DB log
    pcall(function()
        MySQL.insert.await(
            "INSERT INTO jc_logs (type, source, target, description) VALUES (?,?,?,?)",
            { action, tostring(src), tostring(targetId or ""), tostring(extraInfo or "") }
        )
    end)
end

-- ──────────────────────────────────────────────────────────────
-- MySQL helpers
-- ──────────────────────────────────────────────────────────────
local function DbQuery(q, p)
    local r = {}
    pcall(function() r = MySQL.query.await(q, p or {}) or {} end)
    return r
end

local function DbUpdate(q, p)
    pcall(function() MySQL.update.await(q, p or {}) end)
end

local function DbInsert(q, p)
    local id = nil
    pcall(function() id = MySQL.insert.await(q, p or {}) end)
    return id
end

-- ──────────────────────────────────────────────────────────────
-- Table initialisation
-- ──────────────────────────────────────────────────────────────
local function InitTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `admins` (
        `id`           INT NOT NULL AUTO_INCREMENT,
        `license`      VARCHAR(120) NOT NULL DEFAULT '',
        `username`     VARCHAR(100) NOT NULL DEFAULT 'Admin',
        `password`     VARCHAR(255) NOT NULL DEFAULT '123456',
        `group`        VARCHAR(100) NOT NULL DEFAULT 'admin',
        `avatar`       TEXT,
        `settings`     MEDIUMTEXT,
        `head_tag`     VARCHAR(100) DEFAULT NULL,
        `session_time` INT NOT NULL DEFAULT 0,
        `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `license` (`license`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jc_bans` (
        `id`          INT NOT NULL AUTO_INCREMENT,
        `license`     VARCHAR(255) NOT NULL DEFAULT '',
        `identifiers` TEXT,
        `player_name` VARCHAR(255) DEFAULT NULL,
        `reason`      TEXT,
        `banned_by`   VARCHAR(255) DEFAULT NULL,
        `permanent`   TINYINT(1) NOT NULL DEFAULT 1,
        `expires_at`  BIGINT DEFAULT NULL,
        `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jc_notes` (
        `id`         INT NOT NULL AUTO_INCREMENT,
        `target`     VARCHAR(255) NOT NULL DEFAULT '',
        `author`     VARCHAR(255) DEFAULT NULL,
        `text`       TEXT,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `target` (`target`(191))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jc_logs` (
        `id`          INT NOT NULL AUTO_INCREMENT,
        `type`        VARCHAR(100) DEFAULT NULL,
        `source`      VARCHAR(255) DEFAULT NULL,
        `target`      VARCHAR(255) DEFAULT NULL,
        `description` TEXT,
        `timestamp`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jc_groups` (
        `id`    INT NOT NULL AUTO_INCREMENT,
        `name`  VARCHAR(100) NOT NULL,
        `perms` MEDIUMTEXT,
        `color` VARCHAR(50) DEFAULT '#ffffff',
        PRIMARY KEY (`id`),
        UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jc_stats` (
        `date`    DATE NOT NULL,
        `players` INT NOT NULL DEFAULT 0,
        `bans`    INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`date`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `admin_daily` (
        `id`       INT NOT NULL AUTO_INCREMENT,
        `admin_id` INT NOT NULL,
        `date`     DATE NOT NULL,
        `seconds`  INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `admin_date` (`admin_id`, `date`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end

-- ──────────────────────────────────────────────────────────────
-- Load groups
-- ──────────────────────────────────────────────────────────────
local function LoadGroups()
    local rows = DbQuery("SELECT name, perms, color FROM jc_groups")
    for _, row in ipairs(rows) do
        local perms = {}
        if row.perms and row.perms ~= "" then
            local ok, d = pcall(json.decode, row.perms)
            if ok and type(d) == "table" then perms = d end
        end
        AdminGroups[row.name] = { perms = perms, color = row.color or "#ffffff" }
    end
    -- Ensure default admin group
    if not AdminGroups["admin"] then
        AdminGroups["admin"] = { perms = { ["*"] = true }, color = "#ff0000" }
        pcall(function()
            MySQL.insert.await(
                "INSERT IGNORE INTO jc_groups (name, perms, color) VALUES (?,?,?)",
                { "admin", json.encode({ ["*"] = true }), "#ff0000" }
            )
        end)
    end
end

-- ──────────────────────────────────────────────────────────────
-- Startup
-- ──────────────────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(name)
    if GetCurrentResourceName() ~= name then return end
    Wait(600)
    pcall(InitTables)
    Wait(300)
    pcall(LoadGroups)
    -- Seed default user if table is empty
    pcall(function()
        local rows = MySQL.query.await("SELECT id FROM admins LIMIT 1")
        if not rows or #rows == 0 then
            local u = (Config.DefaultUsers and Config.DefaultUsers.user) or "Admin"
            local p = (Config.DefaultUsers and Config.DefaultUsers.password) or "123456"
            MySQL.insert.await(
                "INSERT IGNORE INTO admins (license, username, password, `group`) VALUES (?,?,?,?)",
                { "license:setup_placeholder", u, p, "admin" }
            )
        end
    end)
    print("^2[admin]^7 Server ready.")
end)

-- ──────────────────────────────────────────────────────────────
-- Player drop
-- ──────────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function(reason)
    local src = source
    if AdminSessions[src] then
        local elapsed = os.time() - (AdminSessions[src].loginTime or os.time())
        local adminId = AdminSessions[src].id
        pcall(function()
            MySQL.update.await(
                "UPDATE admins SET session_time = session_time + ? WHERE id = ?",
                { elapsed, adminId }
            )
        end)
        pcall(function()
            local today = os.date("!%Y-%m-%d")
            MySQL.query.await([[
                INSERT INTO admin_daily (admin_id, date, seconds) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE seconds = seconds + ?
            ]], { adminId, today, elapsed, elapsed })
        end)
        -- Log leave
        if Config.Logs and Config.Logs.leaves then
            local wh = Config.DiscordLogs and Config.DiscordLogs.leaves or ""
            SendWebhook(wh, "Player Disconnected",
                string.format("**Name:** %s\n**Reason:** %s", GetPlayerName(src) or tostring(src), reason or "Unknown"),
                15158332)
        end
    end
    AdminSessions[src]    = nil
    PendingCredChange[src] = nil
    TerminalViewers[src]  = nil
    ScreenViewers[src]    = nil
    VoiceCallCh[src]      = nil
    -- Notify open panels
    for adminSrc in pairs(AdminSessions) do
        TriggerClientEvent("adminpanel:playerDropped", adminSrc, src)
    end
end)

-- ──────────────────────────────────────────────────────────────
-- Ban check on connect
-- ──────────────────────────────────────────────────────────────
AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    local license = GetLicense(src)
    local ip      = GetPlayerIp(src)
    local serverName = Config.ServerName or "the server"

    -- Identifier requirements
    if Config.ConnectRequirements then
        local missing = {}
        if Config.ConnectRequirements.license and not license then missing[#missing+1] = "License" end
        if Config.ConnectRequirements.steam    and not GetSteam(src)   then missing[#missing+1] = "Steam" end
        if Config.ConnectRequirements.discord  and not GetDiscord(src) then missing[#missing+1] = "Discord" end
        if Config.ConnectRequirements.ip       and not ip              then missing[#missing+1] = "IP" end
        if #missing > 0 then
            local wh = Config.LogsSecurity or ""
            SendWebhook(wh, "Connection requirements not met",
                string.format("**Player:** %s\n**Missing:** %s", playerName, table.concat(missing, ", ")),
                15158332)
            deferrals.done("Connection requirements not met: " .. table.concat(missing, ", "))
            return
        end
    end

    -- AntiVPN
    if Config.AntiVPN and Config.AntiVPN.enable and ip then
        local ipAddr = ip:gsub("ip:", "")
        local whitelisted = false
        if Config.AntiVPN.whitelist then
            for _, w in ipairs(Config.AntiVPN.whitelist) do
                if w == ipAddr then whitelisted = true break end
            end
        end
        if not whitelisted then
            -- Simple VPN check could go here; skipped to avoid blocking legit players
        end
    end

    -- Ban check
    if license then
        local ok, rows = pcall(function()
            return MySQL.query.await("SELECT * FROM jc_bans WHERE license = ?", { license })
        end)
        if ok and rows then
            for _, ban in ipairs(rows) do
                local now = os.time()
                if ban.permanent == 1 or not ban.expires_at then
                    local wh = Config.LogsSecurity or ""
                    SendWebhook(wh, "Banned player attempting to connect",
                        string.format("**Player:** %s\n**License:** %s\n**Reason:** %s", playerName, license, ban.reason or "N/A"),
                        15158332)
                    deferrals.done(string.format(
                        "You are banned from %s.\nReason: %s\nBan ID: #%s\nAdmin: %s",
                        serverName, ban.reason or "N/A", ban.id, ban.banned_by or "N/A"
                    ))
                    return
                elseif tonumber(ban.expires_at) and tonumber(ban.expires_at) > now then
                    local remaining = math.max(0, math.floor((tonumber(ban.expires_at) - now) / 3600))
                    deferrals.done(string.format(
                        "You are temporarily banned from %s.\nReason: %s\nTime remaining: %d hour(s)\nBan ID: #%s",
                        serverName, ban.reason or "N/A", remaining, ban.id
                    ))
                    return
                end
            end
        end
    end

    -- Log join
    if Config.Logs and Config.Logs.joins then
        local wh = Config.DiscordLogs and Config.DiscordLogs.joins or ""
        SendWebhook(wh, "Player Connected",
            string.format("**Name:** %s\n**License:** %s\n**IP:** %s", playerName, license or "N/A", ip or "N/A"),
            3066993)
    end

    deferrals.done()
end)

-- ──────────────────────────────────────────────────────────────
-- LOGIN
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:login", function(username, password, remember)
    local src = source
    if not username or username == "" or not password or password == "" then return end

    local license = GetLicense(src)
    if not license then
        TriggerClientEvent("adminpanel:loginFailed", src)
        return
    end

    local rows = DbQuery("SELECT * FROM admins WHERE username = ? AND password = ?", { username, password })
    if not rows or #rows == 0 then
        TriggerClientEvent("adminpanel:loginFailed", src)
        return
    end
    -- Prefer the account already bound to this player's license. This matters when
    -- several admins share the default credentials: each keeps their own personal row.
    local adminRow = rows[1]
    for _, r in ipairs(rows) do
        if r.license == license then adminRow = r break end
    end

    -- Force credential change if this account still uses the default credentials.
    -- The shared default account is left untouched so every admin can onboard from it;
    -- their personal account is created in setNewCredentials, keyed to their license.
    if IsDefaultAccount(adminRow) then
        PendingCredChange[src] = { group = adminRow.group or "admin" }
        TriggerClientEvent("adminpanel:openMustChangeCredentials", src, Config.ServerName or "Server")
        return
    end

    -- Update license binding
    DbUpdate("UPDATE admins SET license = ? WHERE id = ?", { license, adminRow.id })

    local grp = adminRow.group or "admin"
    AdminSessions[src] = {
        id        = adminRow.id,
        username  = adminRow.username,
        group     = grp,
        license   = license,
        loginTime = os.time(),
        headTagOn = false,
    }

    TriggerClientEvent("adminpanel:loginSuccess", src)

    local groupData    = AdminGroups[grp] or { perms = {}, color = "#ffffff" }
    local sectionPerms = BuildClientPerms(groupData.perms)
    OpenAdminPanel(src, true, sectionPerms, adminRow.username)

    -- Permissions log
    if Config.Logs and Config.Logs.permissions then
        local wh = Config.DiscordLogs and Config.DiscordLogs.permissions or ""
        SendWebhook(wh, "Admin Logged In",
            string.format("**Admin:** %s\n**Group:** %s\n**License:** %s", adminRow.username, grp, license),
            3066993)
    end
end)

-- ──────────────────────────────────────────────────────────────
-- SET NEW CREDENTIALS (first-login flow)
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:setNewCredentials", function(newUsername, newPassword)
    local src = source
    if not newUsername or newUsername == "" or not newPassword or newPassword == "" then
        TriggerClientEvent("adminpanel:setNewCredentialsResult", src, false, "error")
        return
    end

    -- Only honored right after the forced default-credential prompt.
    local pending = PendingCredChange[src]
    if not pending then
        TriggerClientEvent("adminpanel:setNewCredentialsResult", src, false, "error")
        return
    end

    local license = GetLicense(src)
    if not license then
        TriggerClientEvent("adminpanel:setNewCredentialsResult", src, false, "error")
        return
    end

    -- Reject if the new username is taken by a different account.
    local taken = DbQuery("SELECT id FROM admins WHERE username = ? AND license != ?", { newUsername, license })
    if taken and #taken > 0 then
        TriggerClientEvent("adminpanel:setNewCredentialsResult", src, false, "taken")
        return
    end

    -- Create (or update) this admin's personal account, inheriting the default
    -- account's group. The shared default account is left intact so other admins
    -- can still onboard from it. license is the UNIQUE key, so this is an upsert.
    DbUpdate([[INSERT INTO admins (license, username, password, `group`)
               VALUES (?,?,?,?)
               ON DUPLICATE KEY UPDATE username = VALUES(username), password = VALUES(password), `group` = VALUES(`group`)]],
        { license, newUsername, newPassword, pending.group or "admin" })

    PendingCredChange[src] = nil
    TriggerClientEvent("adminpanel:setNewCredentialsResult", src, true, "")
end)

-- ──────────────────────────────────────────────────────────────
-- LOGOUT
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:logout", function()
    local src = source
    if AdminSessions[src] then
        local elapsed = os.time() - (AdminSessions[src].loginTime or os.time())
        local adminId = AdminSessions[src].id
        DbUpdate("UPDATE admins SET session_time = session_time + ? WHERE id = ?", { elapsed, adminId })
        pcall(function()
            local today = os.date("!%Y-%m-%d")
            MySQL.query.await([[
                INSERT INTO admin_daily (admin_id, date, seconds) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE seconds = seconds + ?
            ]], { adminId, today, elapsed, elapsed })
        end)
    end
    AdminSessions[src] = nil
    PendingCredChange[src] = nil
end)

-- ──────────────────────────────────────────────────────────────
-- OPEN PANEL COMMAND
-- ──────────────────────────────────────────────────────────────
local adminCmd = (Config.AdminCommand and Config.AdminCommand ~= "") and Config.AdminCommand or "adminpanel"
RegisterCommand(adminCmd, function(src)
    if src == 0 then return end
    if not IsAdmin(src) then
        OpenAdminPanel(src, false, {}, nil)
        return
    end
    local grp       = GetAdminGroup(src)
    local groupData = AdminGroups[grp] or { perms = {}, color = "#ffffff" }
    OpenAdminPanel(src, true, BuildClientPerms(groupData.perms), AdminSessions[src].username)
end, false)

-- ──────────────────────────────────────────────────────────────
-- QUICK ACTIONS
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:requestQuickActions", function()
    local src = source
    if not IsAdmin(src) then return end
    local grp       = GetAdminGroup(src)
    local groupData = AdminGroups[grp] or { perms = {}, color = "#ffffff" }
    TriggerClientEvent("adminpanel:openKickActions", src, BuildClientPerms(groupData.perms))
end)

RegisterNetEvent("adminpanel:kickActionsClosed", function() end)

-- ──────────────────────────────────────────────────────────────
-- PERMISSION CALLBACK
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:hasCommandPerm", function(src, perm)
    if not IsAdmin(src) then return false end
    if not perm or perm == "" then return true end
    return HasPerm(src, perm) or HasPerm(src, "*")
end)

lib.callback.register("adminpanel:isPlayerAdmin", function(src)
    return IsAdmin(src)
end)

-- ──────────────────────────────────────────────────────────────
-- PLAYER LIST
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getPlayersList", function(src)
    if not IsAdmin(src) then return { online = {}, offline = {} } end
    local online = {}
    for _, pidStr in ipairs(GetPlayers()) do
        local pid  = tonumber(pidStr)
        local xP   = GetPlayer(pid)
        local name = GetPlayerName(pid) or tostring(pid)
        local lic  = GetLicense(pid) or ""
        local disc = GetDiscord(pid) or ""
        local ping = GetPlayerPing(pid) or 0
        local job, org = "", ""
        if xP then
            if Config.Framework == "esx" then
                job = (xP.job and xP.job.name) or ""
            elseif Config.Framework == "qb" then
                local pd = xP.PlayerData
                job = (pd and pd.job and pd.job.name) or ""
                local g = pd and pd.gang
                org = (g and g.name and g.name ~= "none" and g.name) or ""
            end
        end
        local coords = nil
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)
            coords = { x = c.x, y = c.y, z = c.z }
        end
        online[#online + 1] = {
            id       = pid,
            name     = name,
            license  = lic,
            discord  = disc,
            ping     = ping,
            job      = job,
            org      = org,
            coords   = coords,
            isAdmin  = IsAdmin(pid),
            online   = true,
        }
    end
    -- Build a set of online licenses to exclude from offline list
    local onlineLicenses = {}
    for _, p in ipairs(online) do
        if p.license and p.license ~= "" then onlineLicenses[p.license] = true end
    end
    local offline = {}
    local ok2, offRows = pcall(function()
        if Config.Framework == "esx" then
            return MySQL.query.await("SELECT identifier, firstname, lastname FROM users ORDER BY id DESC LIMIT 60")
        elseif Config.Framework == "qb" then
            return MySQL.query.await("SELECT license, charinfo FROM players ORDER BY id DESC LIMIT 60")
        end
        return {}
    end)
    if ok2 and offRows then
        for _, row in ipairs(offRows) do
            local lic2, name2 = "", "Unknown"
            if Config.Framework == "esx" then
                lic2 = row.identifier or ""
                name2 = ((row.firstname or "") .. " " .. (row.lastname or "")):match("^%s*(.-)%s*$")
            elseif Config.Framework == "qb" then
                lic2 = row.license or ""
                if row.charinfo then
                    local ok3, ci = pcall(json.decode, row.charinfo)
                    if ok3 and ci then
                        name2 = ((ci.firstname or "") .. " " .. (ci.lastname or "")):match("^%s*(.-)%s*$")
                    end
                end
            end
            if lic2 ~= "" and not onlineLicenses[lic2] and name2 ~= "" then
                offline[#offline + 1] = { name = name2, identifier = lic2, online = false }
            end
        end
    end
    return { online = online, offline = offline }
end)

-- ──────────────────────────────────────────────────────────────
-- PLAYER DETAILS (online)
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getPlayerDetails", function(src, targetId)
    if not IsAdmin(src) then return {} end
    targetId = tonumber(targetId)
    if not targetId then return {} end
    local xP   = GetPlayer(targetId)
    local name = GetPlayerName(targetId) or "Unknown"
    local lic  = GetLicense(targetId) or ""
    local disc = GetDiscord(targetId) or ""
    local steam = GetSteam(targetId) or ""
    local ping = GetPlayerPing(targetId) or 0
    local ids  = GetAllIds(targetId)
    local fn, ln, job, jg, money, bank, org, playerGroup = "N/A", "N/A", "Unemployed", "—", 0, 0, "None", ""
    if xP then
        fn = GetFrameworkPlayerFirstname(xP) or "N/A"
        ln = GetFrameworkPlayerLastname(xP) or "N/A"
        if Config.Framework == "esx" then
            local jobObj = xP.job
            job   = (jobObj and jobObj.name) or "Unemployed"
            jg    = (jobObj and tostring(jobObj.grade)) or "—"
            money = (xP.getMoney and xP.getMoney()) or 0
            local bAcc = xP.getAccount and xP.getAccount("bank")
            bank  = (bAcc and bAcc.money) or 0
            playerGroup = (xP.group and tostring(xP.group)) or ""
        elseif Config.Framework == "qb" then
            local pd = xP.PlayerData
            job   = (pd and pd.job and pd.job.name) or "Unemployed"
            jg    = (pd and pd.job and tostring(pd.job.grade and pd.job.grade.level)) or "—"
            local acc = pd and pd.money
            money = (acc and acc.cash) or 0
            bank  = (acc and acc.bank) or 0
            org   = GetPlayerOrganization(targetId)
            playerGroup = (pd and pd.group and pd.group ~= "" and tostring(pd.group))
                        or (pd and pd.metadata and pd.metadata.group and tostring(pd.metadata.group))
                        or ""
        end
    end
    -- Most reliable source: check our own admins table by license
    if lic ~= "" then
        local adminRow = DbQuery("SELECT `group` FROM admins WHERE license = ? LIMIT 1", { lic })
        if adminRow and adminRow[1] and adminRow[1].group and adminRow[1].group ~= "" then
            playerGroup = tostring(adminRow[1].group)
        end
    end
    local vehicles  = {}
    local ok, vl = pcall(GetPlayerVehicles, targetId)
    if ok and vl then vehicles = vl end
    local properties = {}
    local ok2, pl = pcall(GetPlayerProperties, targetId)
    if ok2 and pl then properties = pl end
    return {
        id           = targetId,
        name         = name,
        firstname    = fn,
        lastname     = ln,
        job          = job,
        job_grade    = jg,
        organization = org,
        money        = money,
        bank         = bank,
        license      = lic,
        discord      = disc,
        steam        = steam,
        ping         = ping,
        identifiers  = ids,
        vehicles     = vehicles,
        properties   = properties,
        isAdmin      = IsAdmin(targetId),
        group        = playerGroup,
    }
end)

-- ──────────────────────────────────────────────────────────────
-- PLAYER DETAILS (offline)
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getOfflinePlayerDetails", function(src, identifier)
    if not IsAdmin(src) then return {} end
    if not identifier or identifier == "" then return {} end
    local res = { identifier = identifier, firstname = "N/A", lastname = "N/A",
                  job = "Unemployed", job_grade = "—", organization = "None",
                  money = 0, bank = 0 }
    if Config.Framework == "esx" then
        local rows = DbQuery("SELECT firstname, lastname, accounts, job FROM users WHERE identifier = ? LIMIT 1", { identifier })
        if rows and #rows > 0 then
            local r = rows[1]
            res.firstname = r.firstname or "N/A"
            res.lastname  = r.lastname  or "N/A"
            res.job       = r.job       or "Unemployed"
            if r.accounts then
                local ok, acc = pcall(json.decode, r.accounts)
                if ok and type(acc) == "table" then
                    for _, a in ipairs(acc) do
                        if a.name == "money" then res.money = a.money or 0 end
                        if a.name == "bank"  then res.bank  = a.money or 0 end
                    end
                end
            end
        end
    elseif Config.Framework == "qb" then
        local rows = DbQuery("SELECT charinfo, job, gang, money FROM players WHERE license = ? LIMIT 1", { identifier })
        if rows and #rows > 0 then
            local r = rows[1]
            if r.charinfo then
                local ok, ci = pcall(json.decode, r.charinfo)
                if ok and type(ci) == "table" then
                    res.firstname = ci.firstname or "N/A"
                    res.lastname  = ci.lastname  or "N/A"
                end
            end
            res.job = r.job or "Unemployed"
            if r.money then
                local ok, m = pcall(json.decode, r.money)
                if ok and type(m) == "table" then
                    res.money = m.cash or 0
                    res.bank  = m.bank or 0
                end
            end
        end
    end
    local ok, vl = pcall(GetPlayerVehiclesByIdentifier, identifier)
    if ok and vl then res.vehicles = vl end
    local ok2, pl = pcall(GetPlayerPropertiesByIdentifier, identifier)
    if ok2 and pl then res.properties = pl end
    return res
end)

-- ──────────────────────────────────────────────────────────────
-- MAP PLAYERS
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getMapPlayers", function(src)
    if not IsAdmin(src) then return {} end
    local players = {}
    for _, pidStr in ipairs(GetPlayers()) do
        local pid = tonumber(pidStr)
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)
            players[#players + 1] = {
                id      = pid,
                name    = GetPlayerName(pid) or tostring(pid),
                x       = c.x,
                y       = c.y,
                z       = c.z,
                ping    = GetPlayerPing(pid),
                isAdmin = IsAdmin(pid),
            }
        end
    end
    return players
end)

-- ──────────────────────────────────────────────────────────────
-- MAP ACTIONS (bring / goto / freeze / return)
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:mapAction", function(action, targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    if action == "bring" then
        local myPed = GetPlayerPed(src)
        local c = GetEntityCoords(myPed)
        TriggerClientEvent("adminpanel:bringPlayer", targetId, c.x, c.y + 1.5, c.z)
        LogAdminAction(src, "bring", targetId, GetPlayerName(targetId))
    elseif action == "goto" then
        local tPed = GetPlayerPed(targetId)
        local c = GetEntityCoords(tPed)
        TriggerClientEvent("adminpanel:gotoPlayer", src, c.x, c.y, c.z)
        LogAdminAction(src, "tp", targetId, GetPlayerName(targetId))
    elseif action == "freeze" then
        TriggerClientEvent("adminpanel:setFreezePlayer", targetId, true)
        LogAdminAction(src, "freeze", targetId, GetPlayerName(targetId))
    elseif action == "return" then
        TriggerClientEvent("adminpanel:sendBackPlayer", targetId)
        LogAdminAction(src, "return_player", targetId, GetPlayerName(targetId))
    end
end)

-- ──────────────────────────────────────────────────────────────
-- KILL
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:killPlayer", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    TriggerClientEvent("admin:kill", targetId)
    LogAdminAction(src, "kill", targetId, GetPlayerName(targetId))
end)

-- ──────────────────────────────────────────────────────────────
-- REVIVE  (main handler — Editable/Server/SMain also has one for
--           ambulance system routing; both coexist fine)
-- ──────────────────────────────────────────────────────────────
-- NOTE: The Editable/Server/SMain.lua registers adminpanel:revivePlayer
-- using the ambulance system router. We do NOT re-register here to avoid
-- duplicate handler conflicts. That file is loaded as shared_script before
-- Server/*.lua, so its handler takes priority. We only expose the helper.

-- ──────────────────────────────────────────────────────────────
-- KICK
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:kickPlayer", function(targetId, reason)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    reason = tostring(reason or "Kicked by admin")
    DropPlayer(targetId, reason)
    LogAdminAction(src, "kick", targetId, GetPlayerName(targetId), "Reason: " .. reason)
end)

-- ──────────────────────────────────────────────────────────────
-- BAN (online player)
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:banPlayer", function(targetId, reason, permanent, expiresAt)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    local license    = GetLicense(targetId) or ""
    local playerName = GetPlayerName(targetId) or "Unknown"
    local bannedBy   = GetAdminLabel(src)
    local isPerm     = (permanent == true or not expiresAt) and 1 or 0
    local expTs      = (isPerm == 0 and expiresAt) and tonumber(expiresAt) or nil
    local allIds     = json.encode(GetAllIds(targetId))
    DbInsert("INSERT INTO jc_bans (license, identifiers, player_name, reason, banned_by, permanent, expires_at) VALUES (?,?,?,?,?,?,?)",
        { license, allIds, playerName, reason or "", bannedBy, isPerm, expTs })
    DropPlayer(targetId, "Banned from " .. (Config.ServerName or "server") .. ". Reason: " .. (reason or ""))
    LogAdminAction(src, "ban", targetId, playerName, "Reason: " .. (reason or "N/A"))
    SendWebhook(Config.DiscordLogs and Config.DiscordLogs.bans or "", "Player Banned",
        string.format("**Player:** %s\n**License:** %s\n**Reason:** %s\n**Admin:** %s\n**Permanent:** %s",
            playerName, license, reason or "N/A", bannedBy, isPerm == 1 and "Yes" or "No"), 15158332)
end)

-- ──────────────────────────────────────────────────────────────
-- BAN (offline player)
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:banOffline", function(identifiers, reason, permanent, expiresAt)
    local src = source
    if not IsAdmin(src) then return end
    local bannedBy = GetAdminLabel(src)
    local isPerm   = (permanent == true or not expiresAt) and 1 or 0
    local expTs    = (isPerm == 0 and expiresAt) and tonumber(expiresAt) or nil
    local license, playerName, allIdsStr = "", "Offline Player", ""
    if type(identifiers) == "table" then
        license    = identifiers.license or ""
        playerName = identifiers.player_name or "Offline Player"
        allIdsStr  = json.encode(identifiers)
    elseif type(identifiers) == "string" then
        license    = identifiers
        allIdsStr  = identifiers
    end
    DbInsert("INSERT INTO jc_bans (license, identifiers, player_name, reason, banned_by, permanent, expires_at) VALUES (?,?,?,?,?,?,?)",
        { license, allIdsStr, playerName, reason or "", bannedBy, isPerm, expTs })
    LogAdminAction(src, "ban", nil, playerName, "Offline ban | License: " .. license)
end)

-- ──────────────────────────────────────────────────────────────
-- UNBAN
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:unban", function(banId)
    local src = source
    if not IsAdmin(src) then return end
    banId = tonumber(banId)
    if not banId then return end
    DbUpdate("DELETE FROM jc_bans WHERE id = ?", { banId })
    LogAdminAction(src, "unban", nil, nil, "Ban ID: " .. tostring(banId))
    SendWebhook(Config.DiscordLogs and Config.DiscordLogs.unbans or "", "Player Unbanned",
        string.format("**Admin:** %s\n**Ban ID:** #%s", GetAdminLabel(src), banId), 3066993)
end)

RegisterNetEvent("adminpanel:updateBan", function(banId, reason, permanent, expiresAt)
    local src = source
    if not IsAdmin(src) then return end
    banId = tonumber(banId)
    if not banId then return end
    local isPerm = (permanent == true or not expiresAt) and 1 or 0
    local expTs  = (isPerm == 0 and expiresAt) and tonumber(expiresAt) or nil
    DbUpdate("UPDATE jc_bans SET reason = ?, permanent = ?, expires_at = ? WHERE id = ?",
        { reason or "", isPerm, expTs, banId })
end)

lib.callback.register("adminpanel:getBansList", function(src)
    if not IsAdmin(src) then return {} end
    return DbQuery("SELECT * FROM jc_bans ORDER BY created_at DESC LIMIT 300")
end)

-- Console unban
RegisterCommand(
    (Config.Commands and Config.Commands.commandConsole and Config.Commands.commandConsole.unbanConsole) or "jdunban",
    function(src, args)
        if src ~= 0 then return end
        local banId = tonumber(args[1])
        if not banId then print("[admin] Usage: jdunban <banId>") return end
        DbUpdate("DELETE FROM jc_bans WHERE id = ?", { banId })
        print("[admin] Ban #" .. banId .. " removed.")
    end, true)

-- Console setadmin
RegisterCommand(
    (Config.Commands and Config.Commands.commandConsole and Config.Commands.commandConsole.addAdminConsole) or "setadmin",
    function(src, args)
        if src ~= 0 then return end
        local pid = tonumber(args[1])
        local grp = args[2] or "admin"
        if not pid then print("[admin] Usage: setadmin <playerId> <group>") return end
        local lic = GetLicense(pid)
        if not lic then print("[admin] Player not found.") return end
        DbInsert("INSERT INTO admins (license, username, password, `group`) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE `group` = ?",
            { lic, GetPlayerName(pid) or "Admin", "changeme", grp, grp })
        print("[admin] Player " .. pid .. " set to group: " .. grp)
    end, true)

-- ──────────────────────────────────────────────────────────────
-- ANNOUNCEMENT
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:sendAnnouncement", function(text)
    local src = source
    if not IsAdmin(src) then return end
    if not text or text == "" then return end
    TriggerClientEvent("adminpanel:showAnnouncement", -1, text)
    LogAdminAction(src, "announcement", nil, nil, "Message: " .. text)
end)

-- ──────────────────────────────────────────────────────────────
-- TIME / WEATHER
-- ──────────────────────────────────────────────────────────────

local forcedWeather = nil

RegisterNetEvent("admin:changeTime", function(hour, freeze, showNotification, weather)
    local src = source
    if not IsAdmin(src) then return end
    hour = math.floor(tonumber(hour) or 12)
    hour = ((hour % 24) + 24) % 24
    freeze = (freeze == true)

    GlobalTimeState.hour = hour
    GlobalTimeState.minute = 0
    GlobalTimeState.freeze = freeze

    -- Push time to all clients via native NetworkOverrideClockTime loop.
    TriggerClientEvent("admin:setTime", -1, hour, 0, freeze)

    if type(weather) == "string" and weather ~= "" then
        GlobalWeather = weather
        forcedWeather = weather
        TriggerClientEvent("admin:setWeather", -1, weather)
    end

    local extraInfo = ("Hour: %d | Freeze: %s"):format(hour, tostring(freeze))
    if GlobalWeather then
        extraInfo = extraInfo .. " | Weather: " .. tostring(GlobalWeather)
    end
    LogAdminAction(src, "server_time", nil, nil, extraInfo)
end)

AddEventHandler("playerJoining", function()
    local src = source
    CreateThread(function()
        Wait(3000)
        TriggerClientEvent("admin:setTime", src, GlobalTimeState.hour, 0, GlobalTimeState.freeze)
        if forcedWeather then
            TriggerClientEvent("admin:setWeather", src, forcedWeather)
        end
    end)
end)

-- ──────────────────────────────────────────────────────────────
-- SPECTATE
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:requestSpectate", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    local tPed   = GetPlayerPed(targetId)
    local netId  = NetworkGetNetworkIdFromEntity(tPed)
    local c      = GetEntityCoords(tPed)
    local tName  = GetPlayerName(targetId) or tostring(targetId)
    local xP     = GetPlayer(targetId)
    local job    = ""
    if xP then
        if Config.Framework == "esx" then
            job = (xP.job and xP.job.name) or ""
        elseif Config.Framework == "qb" then
            job = (xP.PlayerData and xP.PlayerData.job and xP.PlayerData.job.name) or ""
        end
    end
    TriggerClientEvent("adminpanel:requestSpectate", src, netId, targetId,
        { x = c.x, y = c.y, z = c.z },
        { name = tName, job = job, group = GetAdminGroup(targetId) })
    LogAdminAction(src, "spectate", targetId, tName)
end)

RegisterNetEvent("adminpanel:cancelSpectate", function()
    TriggerClientEvent("adminpanel:cancelSpectate", source)
end)

-- ──────────────────────────────────────────────────────────────
-- SCREEN VIEW
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:requestViewScreen", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    ScreenViewers[src] = targetId
    TriggerClientEvent("adminpanel:startSendingScreen", targetId, src, nil)
    TriggerClientEvent("adminpanel:openScreenViewer", src, targetId, GetPlayerName(targetId) or tostring(targetId))
    LogAdminAction(src, "take_capture", targetId, GetPlayerName(targetId))
end)

RegisterNetEvent("adminpanel:stopViewScreen", function()
    local src = source
    local tgt = ScreenViewers[src]
    if tgt then
        TriggerClientEvent("adminpanel:stopSendingScreen", tgt)
        ScreenViewers[src] = nil
    end
end)

local SCREEN_CHUNK_SIZE = 16000
RegisterNetEvent("adminpanel:sendScreenFrame", function(frameData)
    local src = source
    if type(frameData) ~= "string" or #frameData == 0 then return end
    for viewerSrc, tgt in pairs(ScreenViewers) do
        if tgt == src then
            local len = #frameData
            if len <= SCREEN_CHUNK_SIZE then
                TriggerClientEvent("adminpanel:screenFrame", viewerSrc, frameData)
            else
                local totalChunks = math.ceil(len / SCREEN_CHUNK_SIZE)
                for i = 0, totalChunks - 1 do
                    local startPos = i * SCREEN_CHUNK_SIZE + 1
                    local endPos   = math.min(startPos + SCREEN_CHUNK_SIZE - 1, len)
                    TriggerClientEvent("adminpanel:screenFrameChunk", viewerSrc, i, totalChunks, string.sub(frameData, startPos, endPos))
                end
            end
        end
    end
end)

RegisterNetEvent("adminpanel:sendScreenshotLog", function(url)
    local src = source
    if not IsAdmin(src) then return end
    local wh = Config.DiscordLogs and Config.DiscordLogs.take_capture or ""
    SendWebhook(wh, "Screenshot Captured",
        string.format("**Admin:** %s\n[View](%s)", GetAdminLabel(src), url), 3447003)
end)

-- ──────────────────────────────────────────────────────────────
-- SKIN
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:openSkinForPlayer", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    TriggerClientEvent("admin:openSkin", targetId)
    LogAdminAction(src, "change_skin", targetId, GetPlayerName(targetId))
end)

-- ──────────────────────────────────────────────────────────────
-- FREEZE
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:setFreezePlayer", function(targetId, state)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    TriggerClientEvent("adminpanel:setFreezePlayer", targetId, state)
    LogAdminAction(src, "freeze", targetId, GetPlayerName(targetId), "State: " .. tostring(state))
end)

-- ──────────────────────────────────────────────────────────────
-- MONEY
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:manageMoney", function(targetId, action, moneyType, amount)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    amount   = tonumber(amount) or 0
    if not targetId or amount < 1 then return end
    if     action == "give"   then SetPlayerMoney(targetId, moneyType, amount)
    elseif action == "remove" then RemovePlayerMoney(targetId, moneyType, amount)
    elseif action == "set"    then SetPlayerMoneyTo(targetId, moneyType, amount)
    end
    LogAdminAction(src, "manage_money", targetId, GetPlayerName(targetId),
        string.format("Action: %s | Type: %s | Amount: %d", action, moneyType, amount))
end)

RegisterNetEvent("adminpanel:manageMoneyOffline", function(identifier, action, moneyType, amount)
    local src = source
    if not IsAdmin(src) then return end
    amount = tonumber(amount) or 0
    if amount < 1 then return end
    if Config.Framework == "esx" then
        local col = (moneyType == "bank") and "bank" or "cash"
        if action == "give" then
            DbUpdate("UPDATE users SET " .. col .. " = " .. col .. " + ? WHERE identifier = ?", { amount, identifier })
        elseif action == "remove" then
            DbUpdate("UPDATE users SET " .. col .. " = GREATEST(" .. col .. " - ?, 0) WHERE identifier = ?", { amount, identifier })
        elseif action == "set" then
            DbUpdate("UPDATE users SET " .. col .. " = ? WHERE identifier = ?", { amount, identifier })
        end
    elseif Config.Framework == "qb" then
        local rows = DbQuery("SELECT money FROM players WHERE license = ? LIMIT 1", { identifier })
        if rows and #rows > 0 then
            local ok, m = pcall(json.decode, rows[1].money or "{}")
            if ok and type(m) == "table" then
                local mt = (moneyType == "bank") and "bank" or "cash"
                if     action == "give"   then m[mt] = (m[mt] or 0) + amount
                elseif action == "remove" then m[mt] = math.max((m[mt] or 0) - amount, 0)
                elseif action == "set"    then m[mt] = amount
                end
                DbUpdate("UPDATE players SET money = ? WHERE license = ?", { json.encode(m), identifier })
            end
        end
    end
    LogAdminAction(src, "manage_money", nil, identifier, "Offline | " .. action)
end)

-- ──────────────────────────────────────────────────────────────
-- ITEMS / INVENTORY
-- ──────────────────────────────────────────────────────────────

local _inventoryResourceMap = {
    ["ox_inventory"]     = "ox_inventory",
    ["qs-inventory"]     = "qs-inventory",
    ["core_inventory"]   = "core_inventory",
    ["ak47_inventory"]   = "ak47_inventory",
    ["ak47_qb_inventory"]= "ak47_qb_inventory",
    ["tgiann-inventory"] = "tgiann-inventory",
    ["origen_inventory"] = "origen_inventory",
    ["jaksam_inventory"] = "jaksam_inventory",
    ["codem-inventory"]  = "codem-inventory",
    ["qb-inventory"]     = "qb-inventory",
    ["esx_inventory"]    = "esx_inventory",
    ["inventory"]        = "inventory",
}
local _resolvedInv = nil
local function ResolveInventory()
    if _resolvedInv then return _resolvedInv end
    local cfg = Config.InventorySystem or "auto"
    if cfg ~= "auto" then _resolvedInv = cfg; return _resolvedInv end
    for name, _ in pairs(_inventoryResourceMap) do
        if GetResourceState(name) == "started" then
            _resolvedInv = name
            return _resolvedInv
        end
    end
    _resolvedInv = "auto"
    return _resolvedInv
end

lib.callback.register("adminpanel:getItemsList", function(src)
    if not IsAdmin(src) then return {} end
    local items = {}
    local inv = ResolveInventory()

    -- ox_inventory: use Items() export
    if inv == "ox_inventory" or inv == "auto" then
        local ok, res = pcall(function() return exports.ox_inventory:Items() end)
        if ok and type(res) == "table" then
            for name, data in pairs(res) do
                items[#items + 1] = { name = name, label = (type(data) == "table" and data.label) or name }
            end
            table.sort(items, function(a, b) return a.label < b.label end)
            return items
        end
    end

    -- qs-inventory: use GetItemList export
    if inv == "qs-inventory" then
        local ok, res = pcall(function() return exports["qs-inventory"]:GetItemList() end)
        if ok and type(res) == "table" then
            for name, data in pairs(res) do
                items[#items + 1] = { name = name, label = (type(data) == "table" and data.label) or name }
            end
            table.sort(items, function(a, b) return a.label < b.label end)
            return items
        end
    end

    -- QB shared items
    if Config.Framework == "qb" and QBCore and QBCore.Shared and type(QBCore.Shared.Items) == "table" then
        for name, data in pairs(QBCore.Shared.Items) do
            if type(data) == "table" then
                items[#items + 1] = { name = name, label = data.label or name }
            end
        end
        if #items > 0 then
            table.sort(items, function(a, b) return a.label < b.label end)
            return items
        end
    end

    -- Fallback: query DB items table (ESX and others)
    local rows = DbQuery("SELECT name, label FROM items ORDER BY label LIMIT 1000")
    for _, r in ipairs(rows) do
        items[#items + 1] = { name = r.name, label = r.label or r.name }
    end
    return items
end)

RegisterNetEvent("adminpanel:giveItemsToPlayer", function(targetId, items)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId or type(items) ~= "table" then return end
    local inv = ResolveInventory()
    for _, item in ipairs(items) do
        local itemName = item.name or item.itemName or item.item
        local count    = tonumber(item.count or item.amount) or 1
        if itemName and count > 0 then
            pcall(function()
                if inv == "ox_inventory" then
                    exports.ox_inventory:AddItem(targetId, itemName, count)
                elseif inv == "qs-inventory" then
                    exports["qs-inventory"]:AddItem(targetId, itemName, count)
                elseif inv == "core_inventory" then
                    exports["core_inventory"]:addItem(targetId, itemName, count)
                elseif Config.Framework == "esx" then
                    local xP = GetPlayer(targetId)
                    if xP and xP.addInventoryItem then xP.addInventoryItem(itemName, count) end
                elseif Config.Framework == "qb" then
                    local xP = GetPlayer(targetId)
                    if xP and xP.Functions then xP.Functions.AddItem(itemName, count) end
                end
            end)
        end
    end
    LogAdminAction(src, "giveitems", targetId, GetPlayerName(targetId))
end)

RegisterNetEvent("adminpanel:removeItemFromPlayer", function(targetId, itemName, amount, slot)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    amount   = tonumber(amount) or 1
    if not targetId or not itemName then return end
    local inv = ResolveInventory()
    pcall(function()
        if inv == "ox_inventory" then
            exports.ox_inventory:RemoveItem(targetId, itemName, amount, slot)
        elseif inv == "qs-inventory" then
            exports["qs-inventory"]:RemoveItem(targetId, itemName, amount)
        elseif Config.Framework == "esx" then
            local xP = GetPlayer(targetId)
            if xP and xP.removeInventoryItem then xP.removeInventoryItem(itemName, amount) end
        elseif Config.Framework == "qb" then
            local xP = GetPlayer(targetId)
            if xP and xP.Functions then xP.Functions.RemoveItem(itemName, amount) end
        end
    end)
end)

lib.callback.register("adminpanel:getPlayerInventory", function(src, targetId)
    if not IsAdmin(src) then return {} end
    targetId = tonumber(targetId)
    if not targetId then return {} end
    local inv   = ResolveInventory()
    local items = {}
    pcall(function()
        if inv == "ox_inventory" then
            local raw = exports.ox_inventory:GetInventory(targetId) or {}
            -- GetInventory may return { items = {[slot]={...}}, ... } or a flat items table
            local slotsTable = (type(raw.items) == "table") and raw.items or raw
            for _, slot in pairs(slotsTable) do
                if type(slot) == "table" and slot.name and (slot.count or slot.amount or 0) > 0 then
                    items[#items + 1] = { name = slot.name, label = slot.label or slot.name,
                                          count = slot.count or slot.amount, slot = slot.slot }
                end
            end
        elseif inv == "qs-inventory" then
            local raw = exports["qs-inventory"]:GetPlayerInventory(targetId) or {}
            local slotsTable = (type(raw.items) == "table") and raw.items or raw
            for _, slot in pairs(slotsTable) do
                if type(slot) == "table" and slot.name and (slot.amount or 0) > 0 then
                    items[#items + 1] = { name = slot.name, label = slot.info and slot.info.label or slot.name,
                                          count = slot.amount, slot = slot.slot }
                end
            end
        elseif Config.Framework == "esx" then
            local xP = GetPlayer(targetId)
            if xP and xP.inventory then
                for _, item in ipairs(xP.inventory) do
                    if item.count and item.count > 0 then
                        items[#items + 1] = { name = item.name, label = item.label or item.name, count = item.count }
                    end
                end
            end
        elseif Config.Framework == "qb" then
            local xP = GetPlayer(targetId)
            if xP and xP.PlayerData and xP.PlayerData.items then
                for _, item in pairs(xP.PlayerData.items) do
                    if item and (item.amount or 0) > 0 then
                        items[#items + 1] = { name = item.name, label = item.label or item.name,
                                              count = item.amount, slot = item.slot }
                    end
                end
            end
        end
    end)
    return items
end)

RegisterNetEvent("adminpanel:clearInventory", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    local inv = ResolveInventory()
    pcall(function()
        if inv == "ox_inventory" then
            exports.ox_inventory:ClearInventory(targetId)
        elseif inv == "qs-inventory" then
            exports["qs-inventory"]:ClearInventory(targetId)
        elseif Config.Framework == "esx" then
            local xP = GetPlayer(targetId)
            if xP and xP.clearInventory then xP.clearInventory() end
        elseif Config.Framework == "qb" then
            local xP = GetPlayer(targetId)
            if xP and xP.Functions then xP.Functions.ClearInventory() end
        end
    end)
    LogAdminAction(src, "clean_inventory", targetId, GetPlayerName(targetId))
end)

-- ──────────────────────────────────────────────────────────────
-- JOBS / GANGS
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getJobsList", function(src)
    if not IsAdmin(src) then return {} end
    local jobs = {}
    if Config.Framework == "esx" then
        local rows = DbQuery("SELECT j.name, j.label, jg.grade, jg.name as gname FROM jobs j LEFT JOIN job_grades jg ON j.name = jg.job_name ORDER BY j.name, jg.grade")
        local byJob = {}
        for _, r in ipairs(rows) do
            if not byJob[r.name] then
                byJob[r.name] = { name = r.name, label = r.label or r.name, grades = {} }
            end
            if r.grade ~= nil then
                byJob[r.name].grades[#byJob[r.name].grades + 1] = { grade = r.grade, label = r.gname or tostring(r.grade) }
            end
        end
        for _, v in pairs(byJob) do jobs[#jobs + 1] = v end
    elseif Config.Framework == "qb" and QBCore and QBCore.Shared and type(QBCore.Shared.Jobs) == "table" then
        for jobName, jobData in pairs(QBCore.Shared.Jobs) do
            if type(jobData) == "table" then
                local grades = {}
                if type(jobData.grades) == "table" then
                    for gKey, gInfo in pairs(jobData.grades) do
                        local gNum   = tonumber(gKey) or gKey
                        local glabel = (type(gInfo) == "table" and (gInfo.name or gInfo.label)) or tostring(gKey)
                        grades[#grades + 1] = { grade = gNum, label = tostring(glabel) }
                    end
                    table.sort(grades, function(a, b) return (tonumber(a.grade) or 0) < (tonumber(b.grade) or 0) end)
                end
                jobs[#jobs + 1] = { name = jobName, label = jobData.label or jobName, grades = grades }
            end
        end
    end
    table.sort(jobs, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
    return jobs
end)

lib.callback.register("adminpanel:getGangsList", function(src)
    if not IsAdmin(src) then return {} end
    return GetAllGangs()
end)

RegisterNetEvent("adminpanel:assignJob", function(targetId, jobName, grade)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    SetPlayerJob(targetId, jobName, grade)
    LogAdminAction(src, "assign_job", targetId, GetPlayerName(targetId),
        string.format("Job: %s | Grade: %s", jobName, tostring(grade)))
end)

RegisterNetEvent("adminpanel:assignGang", function(targetId, gangName, grade)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    ApplyGangToPlayer(targetId, gangName, grade)
    LogAdminAction(src, "assign_gangs", targetId, GetPlayerName(targetId),
        string.format("Gang: %s | Grade: %s", gangName, tostring(grade)))
end)

-- ──────────────────────────────────────────────────────────────
-- VEHICLES
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getPlayerVehicles", function(src, targetId)
    if not IsAdmin(src) then return {} end
    targetId = tonumber(targetId)
    if not targetId then return {} end
    local ok, vl = pcall(GetPlayerVehicles, targetId)
    return (ok and vl) or {}
end)

RegisterNetEvent("adminpanel:spawnVehicleToPlayer", function(targetId, model, plate)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    TriggerClientEvent("admin:spawnVehicle", targetId, model, plate)
    LogAdminAction(src, "spawn_vehicle", targetId, GetPlayerName(targetId), "Model: " .. tostring(model))
end)

lib.callback.register("adminpanel:addVehicleToPlayerGarage", function(src, targetId, model, plate)
    if not IsAdmin(src) then return false end
    targetId = tonumber(targetId)
    if not targetId then return false end
    local ok, result = pcall(AddVehicleToPlayerGarage, targetId, model, plate)
    if ok and result then
        LogAdminAction(src, "add_vehicle", targetId, GetPlayerName(targetId), "Model: " .. tostring(model))
    end
    return ok and result or false
end)

RegisterNetEvent("adminpanel:deletePlayerVehicle", function(targetId, plate)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not plate then return end
    local xP = GetPlayer(targetId)
    if Config.Framework == "esx" then
        local id = xP and GetIdentifier(xP) or GetLicense(targetId) or ""
        DbUpdate("DELETE FROM owned_vehicles WHERE owner = ? AND plate = ?", { id, plate })
    elseif Config.Framework == "qb" then
        local cid = (xP and xP.PlayerData and xP.PlayerData.citizenid) or ""
        DbUpdate("DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ?", { cid, plate })
    end
    LogAdminAction(src, "remove_vehicle", targetId, GetPlayerName(targetId), "Plate: " .. plate)
end)

RegisterNetEvent("adminpanel:deletePlayerVehicleOffline", function(identifier, plate)
    local src = source
    if not IsAdmin(src) then return end
    if not identifier or not plate then return end
    if Config.Framework == "esx" then
        DbUpdate("DELETE FROM owned_vehicles WHERE owner = ? AND plate = ?", { identifier, plate })
    elseif Config.Framework == "qb" then
        DbUpdate("DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ?", { identifier, plate })
    end
    LogAdminAction(src, "remove_vehicle", nil, identifier, "Plate: " .. plate .. " (offline)")
end)

RegisterNetEvent("admin:deleteEntityByNetId", function(netId)
    local src = source
    if not IsAdmin(src) then return end
    netId = tonumber(netId)
    if not netId then return end
    TriggerClientEvent("admin:clientDeleteEntityByNetId", -1, netId)
    LogAdminAction(src, "delete_vehicle", nil, nil, "NetId: " .. netId)
end)

-- ──────────────────────────────────────────────────────────────
-- CK (Character Kill)
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:ckPalyer", function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    CharacterCK(targetId)
    LogAdminAction(src, "ck_player", targetId, GetPlayerName(targetId))
end)

RegisterNetEvent("adminpanel:ckPlayerOffline", function(identifier)
    local src = source
    if not IsAdmin(src) then return end
    CharacterCKOffline(identifier)
    LogAdminAction(src, "ck_player", nil, identifier, "Offline CK")
end)

-- ──────────────────────────────────────────────────────────────
-- INSTANCE / ROUTING BUCKET
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:setPlayerInstance", function(targetId, bucket)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    bucket   = tonumber(bucket) or 0
    if not targetId then return end
    SetPlayerRoutingBucket(targetId, bucket)
    LogAdminAction(src, "instancia", targetId, GetPlayerName(targetId), "Bucket: " .. bucket)
end)

-- ──────────────────────────────────────────────────────────────
-- ADMIN HEAD TAG
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:toggleAdminHeadTag", function()
    local src = source
    if not IsAdmin(src) then return end
    local session = AdminSessions[src]
    if not session then return end
    session.headTagOn = not session.headTagOn
    local tagLabel = session.headTagOn and session.username or ""
    Player(src).state:set("admin_head_tag", tagLabel, true)
    TriggerClientEvent("admin:adminHeadTagSelfState", src, session.headTagOn)
    -- Sync change to all admins
    for adminSrc in pairs(AdminSessions) do
        TriggerClientEvent("admin:syncAdminHeadTag", adminSrc, src, session.headTagOn and session.username or nil)
    end
    LogAdminAction(src, "tag_player", nil, nil, "State: " .. tostring(session.headTagOn))
end)

RegisterNetEvent("adminpanel:setAdminTagNoclip", function(state)
    Player(source).state:set("admin_noclip", state == true, true)
end)

RegisterNetEvent("adminpanel:requestAdminHeadTagsSync", function()
    local src = source
    local tags = {}
    for adminSrc, session in pairs(AdminSessions) do
        if session.headTagOn then
            tags[#tags + 1] = { sid = adminSrc, label = session.username or "STAFF" }
        end
    end
    TriggerClientEvent("admin:fullAdminHeadTagsSync", src, tags)
end)

lib.callback.register("adminpanel:getAdminHeadTagSelfState", function(src)
    return AdminSessions[src] and AdminSessions[src].headTagOn or false
end)

-- ──────────────────────────────────────────────────────────────
-- ACTIVE STAFF / DASHBOARD
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getActiveStaff", function(src)
    if not IsAdmin(src) then
        return { staff = {}, onlineCount = 0, onlinePlayers = 0, totalPlayers = 0, totalBans = 0 }
    end
    local staff = {}
    for adminSrc, session in pairs(AdminSessions) do
        staff[#staff + 1] = {
            id          = session.id,   -- DB primary key (used by requestAdminDetail)
            srcId       = adminSrc,     -- live server source ID (used by logout)
            name        = GetPlayerName(adminSrc) or session.username or tostring(adminSrc),
            username    = session.username,
            group       = session.group,
            onlineSince = session.loginTime,
        }
    end
    local onlinePlayers = #GetPlayers()
    local totalBans = 0
    pcall(function()
        local rows = MySQL.query.await("SELECT COUNT(*) AS cnt FROM jc_bans")
        if rows and rows[1] then totalBans = rows[1].cnt or 0 end
    end)
    return {
        staff         = staff,
        onlineCount   = #staff,
        onlinePlayers = onlinePlayers,
        totalPlayers  = onlinePlayers,
        totalBans     = totalBans,
    }
end)

lib.callback.register("adminpanel:getDashboardMonthlyActivity", function(src)
    if not IsAdmin(src) then return {} end
    return DbQuery("SELECT date, players, bans FROM jc_stats ORDER BY date DESC LIMIT 30")
end)

-- ──────────────────────────────────────────────────────────────
-- STATISTICS
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getStatisticsData", function(src)
    if not IsAdmin(src) then return {} end
    local data = { onlinePlayers = #GetPlayers(), totalBans = 0, totalAdmins = 0, economyTotal = 0, topMoney = {}, jobsOnline = {} }
    pcall(function()
        local r = MySQL.query.await("SELECT COUNT(*) AS cnt FROM jc_bans")
        if r and r[1] then data.totalBans = r[1].cnt or 0 end
    end)
    pcall(function()
        local r = MySQL.query.await("SELECT COUNT(*) AS cnt FROM admins")
        if r and r[1] then data.totalAdmins = r[1].cnt or 0 end
    end)
    -- Economy totals
    if Config.Framework == "qb" then
        pcall(function()
            local r = MySQL.query.await("SELECT SUM(COALESCE(JSON_EXTRACT(money,'$.cash'),0) + COALESCE(JSON_EXTRACT(money,'$.bank'),0)) AS total FROM players WHERE money IS NOT NULL")
            if r and r[1] and r[1].total then data.economyTotal = tonumber(r[1].total) or 0 end
        end)
        pcall(function()
            local top = MySQL.query.await("SELECT charinfo, money FROM players WHERE money IS NOT NULL ORDER BY (COALESCE(JSON_EXTRACT(money,'$.cash'),0) + COALESCE(JSON_EXTRACT(money,'$.bank'),0)) DESC LIMIT 5")
            if top then
                for _, row in ipairs(top) do
                    local name = "Unknown"
                    local ok1, ci = pcall(json.decode, row.charinfo or "{}")
                    if ok1 and type(ci) == "table" then
                        name = ((ci.firstname or "") .. " " .. (ci.lastname or "")):match("^%s*(.-)%s*$")
                        if name == "" then name = "Unknown" end
                    end
                    local ok2, m = pcall(json.decode, row.money or "{}")
                    local total = (ok2 and type(m) == "table") and ((m.cash or 0) + (m.bank or 0)) or 0
                    data.topMoney[#data.topMoney + 1] = { name = name, total = total }
                end
            end
        end)
    elseif Config.Framework == "esx" then
        pcall(function()
            local r = MySQL.query.await("SELECT SUM(money) AS total FROM users")
            if r and r[1] then data.economyTotal = tonumber(r[1].total) or 0 end
        end)
        pcall(function()
            local top = MySQL.query.await("SELECT firstname, lastname, money FROM users ORDER BY money DESC LIMIT 5")
            if top then
                for _, row in ipairs(top) do
                    local name = ((row.firstname or "") .. " " .. (row.lastname or "")):match("^%s*(.-)%s*$")
                    data.topMoney[#data.topMoney + 1] = { name = name ~= "" and name or "Unknown", total = tonumber(row.money) or 0 }
                end
            end
        end)
    end
    -- Job counts (online)
    local jobsOnline = {}
    if Config.Statistics and Config.Statistics.Jobs then
        for catName, jobNames in pairs(Config.Statistics.Jobs) do
            local count = 0
            for _, jn in ipairs(GetPlayers()) do
                local pid = tonumber(jn)
                local xP  = GetPlayer(pid)
                local job = ""
                if Config.Framework == "esx" and xP then
                    job = (xP.job and xP.job.name) or ""
                elseif Config.Framework == "qb" and xP and xP.PlayerData then
                    job = (xP.PlayerData.job and xP.PlayerData.job.name) or ""
                end
                for _, jName in ipairs(jobNames) do
                    if job == jName then count = count + 1 break end
                end
            end
            jobsOnline[catName:lower()] = count
        end
    end
    data.jobsOnline = jobsOnline
    -- Resources
    local numRes = GetNumResources()
    data.resourceCount = numRes
    local alertThreshold = (Config.Statistics and Config.Statistics.ResourceAlertCount) or 150
    data.resourceAlert = numRes > alertThreshold
    local resList = {}
    for i = 0, numRes - 1 do
        local rn = GetResourceByFindIndex(i)
        if rn then
            resList[#resList + 1] = { name = rn, state = GetResourceState(rn) }
        end
    end
    data.resources = resList
    -- Reports integration
    local reportsStats = GetReportsStatsForStatistics()
    if reportsStats then data.reportsStats = reportsStats end
    return data
end)

lib.callback.register("adminpanel:getPlayerStatsHistory", function(src, days)
    if not IsAdmin(src) then return {} end
    days = tonumber(days) or 7
    return DbQuery(("SELECT date, players FROM jc_stats ORDER BY date DESC LIMIT %d"):format(days))
end)

-- ──────────────────────────────────────────────────────────────
-- LOGS (panel view)
-- ──────────────────────────────────────────────────────────────
local LogTypeAliases = {
    deaths     = "death",
    kills      = "kill",
    explosions = "explosion",
    bans       = "ban",
    unbans     = "unban",
}

local CorePanelLogTypes = {
    server_join   = true,
    server_leave  = true,
    chat          = true,
    death         = true,
    kill          = true,
    explosion     = true,
    permissions   = true,
    ban           = true,
    unban         = true,
    tx_admin      = true,
    admin_actions = true,
}

local function ParseAdminActionInfo(description)
    local info = {}
    if type(description) ~= "string" or description == "" then
        return info
    end

    info.message = description

    local hour = description:match("Hour:%s*(%-?%d+)")
    if hour then info.hour = tonumber(hour) end

    local freezeRaw = description:match("Freeze:%s*(%a+)")
    if freezeRaw then
        freezeRaw = freezeRaw:lower()
        info.freeze = (freezeRaw == "true" or freezeRaw == "1" or freezeRaw == "yes")
    end

    local weather = description:match("Weather:%s*([%w_]+)")
    if weather and weather ~= "" then info.weather = weather end

    local reason = description:match("Reason:%s*(.+)")
    if reason and reason ~= "" then info.reason = reason end

    return info
end

local function NormalizeLogRow(row)
    local rawType = tostring(row.type or ""):lower()
    local createdAt = row.timestamp or row.created_at
    local sourceTxt = tostring(row.source or "")
    local targetTxt = tostring(row.target or "")
    local descTxt = tostring(row.description or "")

    local normalizedType = rawType
    local info = {}

    if rawType == "death" or rawType == "kill" then
        if descTxt ~= "" then info.cause_of_death = descTxt end
        if targetTxt ~= "" then info.killer_name = targetTxt end
    elseif rawType == "ban" then
        if sourceTxt ~= "" then info.admin_name = sourceTxt end
        if targetTxt ~= "" then info.banned_player_name = targetTxt end
        if descTxt ~= "" then info.reason = descTxt end
    elseif rawType == "unban" then
        if sourceTxt ~= "" then info.admin_name = sourceTxt end
        if targetTxt ~= "" then info.unbanned_player_name = targetTxt end
        if descTxt ~= "" then info.reason = descTxt end
    elseif rawType == "tx_admin" then
        if descTxt ~= "" then info.message = descTxt end
    elseif rawType == "admin_actions" then
        info = ParseAdminActionInfo(descTxt)
        if info.action == nil then info.action = "unknown" end
    elseif CorePanelLogTypes[rawType] then
        if descTxt ~= "" then info.message = descTxt end
    else
        normalizedType = "admin_actions"
        info = ParseAdminActionInfo(descTxt)
        info.action = rawType
        if sourceTxt ~= "" then info.admin_name = sourceTxt end
        if targetTxt ~= "" then info.target_name = targetTxt end
    end

    return {
        id          = row.id,
        log_type    = normalizedType,
        created_at  = createdAt,
        info        = info,
        identifiers = {},
    }
end

lib.callback.register("adminpanel:getLogsList", function(src, logType, search)
    if not IsAdmin(src) then return { logs = {}, displayFields = {} } end

    local wantedType = tostring(logType or "all"):lower()
    wantedType = LogTypeAliases[wantedType] or wantedType

    local searchText = tostring(search or ""):lower()
    local rows = DbQuery("SELECT * FROM jc_logs ORDER BY timestamp DESC LIMIT 1200")
    local logs = {}

    for _, row in ipairs(rows) do
        local normalized = NormalizeLogRow(row)
        local typeOk = (wantedType == "all" or normalized.log_type == wantedType)

        local searchOk = true
        if searchText ~= "" then
            local haystack = table.concat({
                tostring(row.type or ""):lower(),
                tostring(row.source or ""):lower(),
                tostring(row.target or ""):lower(),
                tostring(row.description or ""):lower(),
            }, " ")
            searchOk = haystack:find(searchText, 1, true) ~= nil
        end

        if typeOk and searchOk then
            logs[#logs + 1] = normalized
            if #logs >= 300 then
                break
            end
        end
    end

    return {
        logs = logs,
        displayFields = {},
    }
end)

RegisterNetEvent("adminpanel:logAdminActionFromClient", function(action)
    local src = source
    if not IsAdmin(src) then return end
    LogAdminAction(src, action)
end)

RegisterNetEvent("admin:logDeath", function(killerServerId, weaponHash)
    local src = source
    if not Config.Logs or not Config.Logs.deaths then return end
    local vName  = GetPlayerName(src) or tostring(src)
    local kName  = (killerServerId and killerServerId ~= 0 and GetPlayerName(killerServerId)) or "Environment"
    SendWebhook(Config.DiscordLogs and Config.DiscordLogs.deaths or "", "Player Death",
        string.format("**Victim:** %s\n**Killer:** %s\n**Weapon:** %s", vName, kName, tostring(weaponHash)),
        15158332)
    pcall(function()
        MySQL.insert.await("INSERT INTO jc_logs (type, source, target, description) VALUES (?,?,?,?)",
            { "death", tostring(src), tostring(killerServerId or 0), "Weapon: " .. tostring(weaponHash) })
    end)
end)

-- Chat log hook
AddEventHandler("chatMessage", function(src, authorName, text)
    if not Config.Logs or not Config.Logs.chat_logs then return end
    local wh = Config.DiscordLogs and Config.DiscordLogs.chat_logs or ""
    SendWebhook(wh, "Chat",
        string.format("**[%s] %s:** %s", src, authorName or GetPlayerName(src) or tostring(src), text),
        3447003)
end)

-- ──────────────────────────────────────────────────────────────
-- GROUPS
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getGroups", function(src)
    if not IsAdmin(src) then return {} end
    local groups = {}
    for name, data in pairs(AdminGroups) do
        groups[#groups + 1] = {
            name = name,
            grupo = name,
            perms = data.perms,
            color = data.color or "#ffffff"
        }
    end
    return groups
end)

lib.callback.register("adminpanel:changeAdminGroupByLicense", function(src, license, newGroup)
    if not IsAdmin(src) then return false end
    if not license or not newGroup or newGroup == "" then return false end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET `group` = ? WHERE license = ?", { newGroup, license })
    end)
    if ok then
        -- Update in-memory session if this admin is online
        for adminSrc, session in pairs(AdminSessions) do
            if session.license == license then
                AdminSessions[adminSrc].group = newGroup
                break
            end
        end
        LogAdminAction(src, "assign_admin", nil, nil, "Group changed to: " .. newGroup .. " for license: " .. license)
    end
    return ok
end)

RegisterNetEvent("adminpanel:createGroup", function(groupName, perms, color)
    local src = source
    if not IsAdmin(src) then return end
    if not groupName or groupName == "" then return end
    local permsJson = (type(perms) == "table" and json.encode(perms)) or "{}"
    local ok, err = pcall(function()
        MySQL.insert.await("INSERT INTO jc_groups (name, perms, color) VALUES (?,?,?)",
            { groupName, permsJson, color or "#ffffff" })
    end)
    if ok then AdminGroups[groupName] = { perms = perms or {}, color = color or "#ffffff" } end
    TriggerClientEvent("adminpanel:createGroupResult", src, ok, ok and "" or tostring(err))
end)

RegisterNetEvent("adminpanel:updateGroup", function(groupName, permsJson, color)
    local src = source
    if not IsAdmin(src) then return end
    if not groupName or groupName == "" then return end
    local ok = pcall(function()
        MySQL.update.await("UPDATE jc_groups SET perms = ?, color = ? WHERE name = ?",
            { permsJson or "{}", color or "#ffffff", groupName })
    end)
    if ok then
        local perms = {}
        local dok, d = pcall(json.decode, permsJson or "{}")
        if dok and type(d) == "table" then perms = d end
        AdminGroups[groupName] = { perms = perms, color = color or "#ffffff" }
    end
    TriggerClientEvent("adminpanel:updateGroupResult", src, ok)
end)

RegisterNetEvent("adminpanel:deleteGroup", function(groupName)
    local src = source
    if not IsAdmin(src) then return end
    if not groupName or groupName == "" then return end
    local ok = pcall(function()
        MySQL.update.await("DELETE FROM jc_groups WHERE name = ?", { groupName })
    end)
    if ok then AdminGroups[groupName] = nil end
    TriggerClientEvent("adminpanel:deleteGroupResult", src, ok)
end)

RegisterNetEvent("adminpanel:assignAdminGroup", function(targetId, groupName)
    local src = source
    if not IsAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId then return end
    local lic = GetLicense(targetId)
    if not lic then return end
    local ok = pcall(function()
        -- Check if this player is already in admins
        local existing = MySQL.query.await("SELECT id FROM admins WHERE license = ? LIMIT 1", { lic })
        if existing and #existing > 0 then
            MySQL.update.await("UPDATE admins SET `group` = ? WHERE license = ?", { groupName, lic })
        else
            -- Insert new admin record with the assigned group (no username/password yet)
            MySQL.insert.await("INSERT INTO admins (license, `group`) VALUES (?, ?)", { lic, groupName })
        end
    end)
    if ok then
        -- Update in-memory session if the target admin is currently logged in
        if AdminSessions[targetId] then
            AdminSessions[targetId].group = groupName
        end
        LogAdminAction(src, "assign_admin", targetId, GetPlayerName(targetId), "Group: " .. groupName)
    end
    TriggerClientEvent("adminpanel:assignAdminGroupResult", src, ok, targetId, groupName)
end)

-- ──────────────────────────────────────────────────────────────
-- PROFILE / SETTINGS
-- ──────────────────────────────────────────────────────────────
lib.callback.register("adminpanel:getProfile", function(src)
    if not IsAdmin(src) then return {} end
    local session = AdminSessions[src]
    if not session then return {} end
    local rows = DbQuery("SELECT * FROM admins WHERE id = ? LIMIT 1", { session.id })
    if not rows or #rows == 0 then return {} end
    local row = rows[1]
    local settings = {}
    if row.settings and row.settings ~= "" then
        local ok, s = pcall(json.decode, row.settings)
        if ok and type(s) == "table" then settings = s end
    end
    row.password = nil  -- never expose
    row.settings = settings
    return row
end)

RegisterNetEvent("adminpanel:saveSettings", function(settings)
    local src = source
    if not IsAdmin(src) then return end
    local session = AdminSessions[src]
    if not session then return end
    local encoded = (type(settings) == "table" and json.encode(settings)) or "{}"
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET settings = ? WHERE id = ?", { encoded, session.id })
    end)
    TriggerClientEvent("adminpanel:saveSettingsResult", src, ok)
end)

RegisterNetEvent("adminpanel:saveAvatar", function(avatarUrl)
    local src = source
    if not IsAdmin(src) then return end
    local session = AdminSessions[src]
    if not session then return end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET avatar = ? WHERE id = ?", { avatarUrl or "", session.id })
    end)
    TriggerClientEvent("adminpanel:saveAvatarResult", src, ok)
end)

RegisterNetEvent("adminpanel:changePassword", function(currentPassword, newPassword)
    local src = source
    if not IsAdmin(src) then return end
    local session = AdminSessions[src]
    if not session then return end
    if session.username == "admin" then
        TriggerClientEvent("adminpanel:changePasswordResult", src, false, "protected")
        return
    end
    local rows = DbQuery("SELECT id FROM admins WHERE id = ? AND password = ?", { session.id, currentPassword })
    if not rows or #rows == 0 then
        TriggerClientEvent("adminpanel:changePasswordResult", src, false)
        return
    end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET password = ? WHERE id = ?", { newPassword, session.id })
    end)
    TriggerClientEvent("adminpanel:changePasswordResult", src, ok)
    if ok then LogAdminAction(src, "change_password") end
end)

lib.callback.register("adminpanel:getAdminDetail", function(src, staffId)
    if not IsAdmin(src) then return {} end
    staffId = tonumber(staffId)
    if not staffId then return {} end
    local rows = DbQuery("SELECT id, license, username, `group`, avatar, session_time, created_at, password FROM admins WHERE id = ? LIMIT 1", { staffId })
    local row = (rows and rows[1]) or {}
    row.password = (row.password and row.password ~= "") and "*****" or nil
    row.totalAdminSeconds = tonumber(row.session_time) or 0
    -- Attach live data if this admin is currently online
    if row.license then
        for adminSrc, session in pairs(AdminSessions) do
            if session.license == row.license then
                row.srcId = adminSrc
                row.name = GetPlayerName(adminSrc) or ""
                row.connectedSeconds = os.time() - (session.loginTime or os.time())
                row.totalAdminSeconds = row.totalAdminSeconds + row.connectedSeconds
                break
            end
        end
    end
    -- Daily usage chart (last 14 days)
    pcall(function()
        local daily = DbQuery([[
            SELECT date, seconds FROM admin_daily
            WHERE admin_id = ? ORDER BY date DESC LIMIT 14
        ]], { staffId })
        if daily and #daily > 0 then
            row.dailyStats = {}
            for _, d in ipairs(daily) do
                row.dailyStats[#row.dailyStats + 1] = { day = tostring(d.date), seconds = tonumber(d.seconds) or 0 }
            end
        end
    end)
    return row
end)

RegisterNetEvent("adminpanel:changeAdminPassword", function(license, newPassword)
    local src = source
    if not IsAdmin(src) then return end
    if not license or not newPassword then return end
    local target = DbQuery("SELECT username FROM admins WHERE license = ? LIMIT 1", { license })
    if target and target[1] and target[1].username == "admin" then
        TriggerClientEvent("adminpanel:changeAdminPasswordResult", src, false, license)
        return
    end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET password = ? WHERE license = ?", { newPassword, license })
    end)
    TriggerClientEvent("adminpanel:changeAdminPasswordResult", src, ok, license)
end)

RegisterNetEvent("adminpanel:changeAdminUser", function(license, newUser)
    local src = source
    if not IsAdmin(src) then return end
    if not license or not newUser or newUser == "" then return end
    local target = DbQuery("SELECT username FROM admins WHERE license = ? LIMIT 1", { license })
    if target and target[1] and target[1].username == "admin" then
        TriggerClientEvent("adminpanel:changeAdminUserResult", src, false, license, newUser)
        return
    end
    if newUser == "admin" then
        TriggerClientEvent("adminpanel:changeAdminUserResult", src, false, license, newUser)
        return
    end
    -- Reject if username is already taken by a different account
    local taken = DbQuery("SELECT id FROM admins WHERE username = ? AND license != ?", { newUser, license })
    if taken and #taken > 0 then
        TriggerClientEvent("adminpanel:changeAdminUserResult", src, false, license, newUser)
        return
    end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET username = ? WHERE license = ?", { newUser, license })
    end)
    TriggerClientEvent("adminpanel:changeAdminUserResult", src, ok, license, newUser)
end)

RegisterNetEvent("adminpanel:resetAdminTimeStats", function(license)
    local src = source
    if not IsAdmin(src) then return end
    if not license then return end
    local ok = pcall(function()
        MySQL.update.await("UPDATE admins SET session_time = 0 WHERE license = ?", { license })
    end)
    TriggerClientEvent("adminpanel:resetAdminTimeStatsResult", src, ok)
    if ok then LogAdminAction(src, "reset_admin_time", nil, license) end
end)

RegisterNetEvent("adminpanel:logoutAdminStaffSession", function(targetPlayerId)
    local src = source
    if not IsAdmin(src) then return end
    targetPlayerId = tonumber(targetPlayerId)
    if not targetPlayerId or targetPlayerId <= 0 then return end
    TriggerClientEvent("adminpanel:forceAdminPanelCloseAndLogout", targetPlayerId)
    AdminSessions[targetPlayerId] = nil
end)

-- ──────────────────────────────────────────────────────────────
-- NOTES
-- ──────────────────────────────────────────────────────────────
local function ResolveNoteTarget(rawTarget)
    local num = tonumber(rawTarget)
    if num then
        local lic = GetLicense(num)
        if lic then return lic end
    end
    return tostring(rawTarget)
end

lib.callback.register("adminpanel:getPlayerNotes", function(src, targetId)
    if not IsAdmin(src) then return {} end
    targetId = tonumber(targetId)
    if not targetId then return {} end
    local target = GetLicense(targetId) or tostring(targetId)
    return DbQuery("SELECT * FROM jc_notes WHERE target = ? ORDER BY created_at DESC", { target })
end)

lib.callback.register("adminpanel:getOfflinePlayerNotes", function(src, identifier)
    if not IsAdmin(src) then return {} end
    if not identifier then return {} end
    return DbQuery("SELECT * FROM jc_notes WHERE target = ? ORDER BY created_at DESC", { identifier })
end)

local function PushNoteUpdate(target)
    local rows = DbQuery("SELECT * FROM jc_notes WHERE target = ? ORDER BY created_at DESC", { target })
    for adminSrc in pairs(AdminSessions) do
        TriggerClientEvent("adminpanel:playerNotesUpdated", adminSrc, target, rows)
    end
end

RegisterNetEvent("adminpanel:addPlayerNote", function(targetOrId, text)
    local src = source
    if not IsAdmin(src) then return end
    if not targetOrId or not text or text == "" then return end
    local target = ResolveNoteTarget(targetOrId)
    local author = GetAdminLabel(src)
    DbInsert("INSERT INTO jc_notes (target, author, text) VALUES (?,?,?)", { target, author, text })
    PushNoteUpdate(target)
    LogAdminAction(src, "player_notes", nil, target)
end)

RegisterNetEvent("adminpanel:deletePlayerNote", function(targetOrId, noteId)
    local src = source
    if not IsAdmin(src) then return end
    local target = ResolveNoteTarget(targetOrId)
    if noteId then
        DbUpdate("DELETE FROM jc_notes WHERE id = ? AND target = ?", { noteId, target })
    end
    PushNoteUpdate(target)
    LogAdminAction(src, "player_notes_delete", nil, target, "Note ID: " .. tostring(noteId))
end)

-- ──────────────────────────────────────────────────────────────
-- TERMINAL
-- ──────────────────────────────────────────────────────────────
RegisterNetEvent("adminpanel:registerTerminalViewer", function()
    local src = source
    if not IsAdmin(src) then return end
    TerminalViewers[src] = true
    TriggerClientEvent("adminpanel:updateConsoleBuffer", src, ConsoleBuffer)
end)

RegisterNetEvent("adminpanel:unregisterTerminalViewer", function()
    TerminalViewers[source] = nil
end)

RegisterNetEvent("adminpanel:getTerminalResources", function()
    local src = source
    if not IsAdmin(src) then return end
    local resources = {}
    for i = 0, GetNumResources() - 1 do
        local n = GetResourceByFindIndex(i)
        resources[#resources + 1] = { name = n, state = GetResourceState(n) }
    end
    TriggerClientEvent("adminpanel:receiveTerminalResources", src, resources)
end)

RegisterNetEvent("adminpanel:executeTerminalCommand", function(command)
    local src = source
    if not IsAdmin(src) then return end
    if not command or command == "" then return end
    ExecuteCommand(command)
    local entry = string.format("[%s] > %s", GetAdminLabel(src), command)
    ConsoleBuffer = ConsoleBuffer .. "\n" .. entry
    if #ConsoleBuffer > 50000 then ConsoleBuffer = ConsoleBuffer:sub(-50000) end
    for vSrc in pairs(TerminalViewers) do
        TriggerClientEvent("adminpanel:addTerminalLog", vSrc, { type = "command", text = entry })
    end
end)

RegisterNetEvent("adminpanel:restartTerminalResource", function(resourceName)
    local src = source
    if not IsAdmin(src) then return end
    if not resourceName or resourceName == "" then return end
    StopResource(resourceName)
    Wait(500)
    StartResource(resourceName)
    LogAdminAction(src, "resource_restart", nil, nil, resourceName)
end)

RegisterNetEvent("adminpanel:startTerminalResource", function(resourceName)
    local src = source
    if not IsAdmin(src) then return end
    if not resourceName or resourceName == "" then return end
    StartResource(resourceName)
end)

RegisterNetEvent("adminpanel:stopTerminalResource", function(resourceName)
    local src = source
    if not IsAdmin(src) then return end
    if not resourceName or resourceName == "" then return end
    StopResource(resourceName)
end)

-- ──────────────────────────────────────────────────────────────
-- VOICE CALLS (pma-voice)
-- ──────────────────────────────────────────────────────────────
local voiceCmd    = (Config.Commands and Config.Commands.commandVoice and Config.Commands.commandVoice.call)      or "call"
local leavecmdV   = (Config.Commands and Config.Commands.commandVoice and Config.Commands.commandVoice.leavecall) or "leavecall"

RegisterCommand(voiceCmd, function(src, args)
    if not IsAdmin(src) then return end
    local targetId = tonumber(args[1])
    if not targetId then return end
    if VoiceCallCh[src] then
        NotifyPlayer(src, "You are already in a call. Use /" .. leavecmdV .. " first.", "error")
        return
    end
    nextCallChannel = nextCallChannel + 1
    VoiceCallCh[src]       = nextCallChannel
    VoiceCallCh[targetId]  = nextCallChannel
    TriggerClientEvent("admin:joinVoiceCall", src,       nextCallChannel)
    TriggerClientEvent("admin:joinVoiceCall", targetId,  nextCallChannel)
end, false)

RegisterCommand(leavecmdV, function(src)
    local ch = VoiceCallCh[src]
    if not ch then return end
    for pid, c in pairs(VoiceCallCh) do
        if c == ch then
            TriggerClientEvent("admin:leaveVoiceCall", pid)
            VoiceCallCh[pid] = nil
        end
    end
end, false)

-- ──────────────────────────────────────────────────────────────
-- STAFF SHORTCUT COMMANDS
-- ──────────────────────────────────────────────────────────────
local function RegisterStaffCmd(cfgKey, handler)
    local cmds = Config.Commands and Config.Commands.commandStaff
    local cmd  = cmds and cmds[cfgKey]
    if not cmd or cmd == false or cmd == "" then return end
    RegisterCommand(cmd, function(src, args)
        if not IsAdmin(src) then return end
        handler(src, args)
    end, false)
end

RegisterStaffCmd("coords",        function(src) TriggerClientEvent("admin:openCoordsUI", src) end)
RegisterStaffCmd("noclip",        function(src) TriggerClientEvent("admin:noclipplayer", src) end)
RegisterStaffCmd("invisible",     function(src) TriggerClientEvent("admin:toggleInvisible", src) end)
RegisterStaffCmd("tpm",           function(src) TriggerClientEvent("admin:teleportToMarker", src) end)
RegisterStaffCmd("tpback",        function(src) TriggerClientEvent("admin:teleportBack", src) end)
RegisterStaffCmd("deletecar",     function(src) TriggerClientEvent("admin:deleteVehicle", src) end)
RegisterStaffCmd("fixvehicle",    function(src) TriggerClientEvent("admin:fixVehicle", src) end)
RegisterStaffCmd("tags",          function(src) TriggerClientEvent("adminpanel:toggleTags", src) end)
RegisterStaffCmd("godmode",       function(src) TriggerClientEvent("admin:toggleGodmode", src) end)
RegisterStaffCmd("staffclothing", function(src) TriggerClientEvent("adminpanel:toggleStaffClothing", src) end)

RegisterStaffCmd("gotoplayer", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    local ped = GetPlayerPed(tid)
    if not ped or ped == 0 then return end
    local c = GetEntityCoords(ped)
    TriggerClientEvent("adminpanel:gotoPlayer", src, c.x, c.y, c.z)
    LogAdminAction(src, "tp", tid, GetPlayerName(tid))
end)

RegisterStaffCmd("bring", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    local myPed = GetPlayerPed(src)
    local c = GetEntityCoords(myPed)
    TriggerClientEvent("adminpanel:bringPlayer", tid, c.x, c.y + 1.5, c.z)
    LogAdminAction(src, "bring", tid, GetPlayerName(tid))
end)

RegisterStaffCmd("bringback", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    TriggerClientEvent("adminpanel:sendBackPlayer", tid)
end)

RegisterStaffCmd("kill", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    TriggerClientEvent("admin:kill", tid)
    LogAdminAction(src, "kill", tid, GetPlayerName(tid))
end)

RegisterStaffCmd("freeze", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    TriggerClientEvent("adminpanel:setFreezePlayer", tid, true)
    LogAdminAction(src, "freeze", tid, GetPlayerName(tid))
end)

RegisterStaffCmd("unfreeze", function(src, args)
    local tid = tonumber(args[1])
    if not tid then return end
    TriggerClientEvent("adminpanel:setFreezePlayer", tid, false)
end)

RegisterStaffCmd("givevehicle", function(src, args)
    local tid   = tonumber(args[1])
    local model = args[2]
    local plate = args[3]
    if not tid or not model then return end
    TriggerClientEvent("admin:spawnVehicle", tid, model, plate)
    LogAdminAction(src, "spawn_vehicle", tid, GetPlayerName(tid), "Model: " .. model)
end)

RegisterStaffCmd("giveitem", function(src, args)
    local tid    = tonumber(args[1])
    local item   = args[2]
    local amount = tonumber(args[3]) or 1
    if not tid or not item then return end
    local items = { { name = item, count = amount } }
    TriggerEvent("adminpanel:giveItemsToPlayer", tid, items)
end)

RegisterStaffCmd("setaccountmoney", function(src, args)
    local mtype  = (args[1] or "CASH"):upper() == "BANK" and "bank" or "cash"
    local tid    = tonumber(args[2])
    local amount = tonumber(args[3]) or 0
    if not tid or amount < 0 then return end
    SetPlayerMoneyTo(tid, mtype, amount)
    LogAdminAction(src, "manage_money", tid, GetPlayerName(tid), mtype .. " = " .. amount)
end)

-- ──────────────────────────────────────────────────────────────
-- TXADMIN event hook
-- ──────────────────────────────────────────────────────────────
AddEventHandler("txAdmin:events:playerActionTaken", function(data)
    if not Config.Logs or not Config.Logs.txadmin or not Config.Logs.txadmin.enable then return end
    local wh = Config.DiscordLogs and Config.DiscordLogs.txadmin or ""
    if not wh or wh == "" or wh == "YOUR_WEBHOOK" then return end
    local t    = data and data.type or "unknown"
    local admin = data and (data.author or data.admin) or "txAdmin"
    local target = data and (data.player_name or data.target or "") or ""
    local reason = data and data.reason or ""
    SendWebhook(wh, "TxAdmin: " .. t,
        string.format("**Admin:** %s\n**Target:** %s\n**Reason:** %s", admin, target, reason), 10181046)
end)

-- ──────────────────────────────────────────────────────────────
-- RESOURCE LOG hook
-- ──────────────────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(name)
    if name == GetCurrentResourceName() then return end
    if not Config.Logs or not Config.Logs.resource_logs then return end
    local wh = Config.DiscordLogs and Config.DiscordLogs.resource_logs or ""
    SendWebhook(wh, "Resource Started", "**Resource:** " .. tostring(name), 3066993)
end)

AddEventHandler("onResourceStop", function(name)
    if name == GetCurrentResourceName() then return end
    if not Config.Logs or not Config.Logs.resource_logs then return end
    local wh = Config.DiscordLogs and Config.DiscordLogs.resource_logs or ""
    SendWebhook(wh, "Resource Stopped", "**Resource:** " .. tostring(name), 15158332)
end)

-- ──────────────────────────────────────────────────────────────
-- DAILY STATS TRACKER
-- ──────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(300000) -- every 5 minutes
        local today = os.date("!%Y-%m-%d")
        local count = #GetPlayers()
        pcall(function()
            MySQL.query.await([[
                INSERT INTO jc_stats (date, players) VALUES (?, ?)
                ON DUPLICATE KEY UPDATE players = GREATEST(players, ?)
            ]], { today, count, count })
        end)
    end
end)
