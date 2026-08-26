Config.LogsSecurity = 'YOUR_WEBHOOK' -- Webhooks for Discord security logs

Config.ConnectRequirements = { -- This option requires you to have the identifiers linked in order to access the server
    ip = true,
    steam = false,
    discord = false,
    license = true,
    xbl = false
}

Config.UpdateBanIdentifiersOnConnect = true -- This is a security option against bans so that players cannot bypass the ban

Config.AntiVPN = { -- Anti-VPN to prevent players from changing their IP address while banned
    enable = true,
    whitelist = {
        '192.23.32.22',
        '162.63.52.85',
    }
}