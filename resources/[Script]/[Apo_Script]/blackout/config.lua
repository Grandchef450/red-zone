Config = {}

Config.Framework = 'qb' -- 'qb' for QBCore, 'esx' for ESX

Config.PowerZones = {
    -- Örnek polyzone tanımları
    ['safezone'] = {
        name = "Zone Sécuritaire",
        points = {
            vector3(1035.64, 3532.76, 34.07),
            vector3(1154.41, 3536.11, 34.97),
            vector3(1150.2, 3324.92, 43.57),
            vector3(1006.13, 3306.16, 39.69)
        },
        minZ = 0.0,
        maxZ = 100.0,
        hasElectricity = true
    },
    ['prison'] = {
        name = "Prison",
        points = {
            vector3(1870.78, 2325.7, 56.18),
            vector3(1561.15, 2294.2, 71.91),
            vector3(1394.08, 2667.14, 41.85),
            vector3(1831.05, 2916.41, 45.75),
            vector3(2026.0, 2688.39, 50.49)
        },
        minZ = 0.0,
        maxZ = 200.0,
        hasElectricity = true
    },
    -- Daha fazla bölge eklenebilir
}

Config.CommandName = "electricity" -- Command to control electricity
Config.AdminOnly = true -- Set to true if only admins can use the command

Config.Language = 'fr' -- Default language: 'en' for English, 'tr' for Turkish

Config.Locales = {
    ['en'] = {
        ['zone_not_found'] = 'Zone not found!',
        ['electricity_on'] = 'Electricity turned ON for %s.',
        ['electricity_off'] = 'Electricity turned OFF for %s.',
        ['invalid_command'] = 'Invalid command! Usage: /%s [zone] [on/off]',
        ['command_help'] = 'Control electricity in zones',
        ['zone_param'] = 'Zone name',
        ['state_param'] = 'on/off'
    },
    ['tr'] = {
        ['zone_not_found'] = 'Böyle bir bölge bulunamadı!',
        ['electricity_on'] = '%s bölgesinin elektriği açıldı.',
        ['electricity_off'] = '%s bölgesinin elektriği kapatıldı.',
        ['invalid_command'] = 'Geçersiz komut! Kullanım: /%s [bölge] [ac/kapat]',
        ['command_help'] = 'Bölgelerin elektriğini kontrol et',
        ['zone_param'] = 'Bölge adı',
        ['state_param'] = 'ac/kapat'
    },
    ['fr'] = {
        ['zone_not_found'] = 'Zone introuvable !',
        ['electricity_on'] = 'Électricité activée pour %s.',
        ['electricity_off'] = 'Électricité désactivée pour %s.',
        ['invalid_command'] = 'Commande invalide ! Utilisation : /%s [zone] [on/off]',
        ['command_help'] = 'Contrôler l’électricité dans les zones',
        ['zone_param'] = 'Nom de la zone',
        ['state_param'] = 'on/off'
    }
}