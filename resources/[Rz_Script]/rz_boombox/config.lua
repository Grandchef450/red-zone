Config = {}

Config.Debug = false

-- Doit correspondre à l'item défini dans ox_inventory/data/items.lua
Config.Item = 'boombox'

Config.PropModel = 'prop_boombox_01a'

-- Distance de pose max depuis la caméra (raycast)
Config.PlaceDistance = 10.0

-- Portée d'interaction ox_target une fois posée
Config.TargetDistance = 2.5

-- Portée d'écoute et volume par défaut (xsound)
Config.SoundDistance = 20.0
Config.SoundVolume = 0.6

-- Clé de Config.Webhooks dans rz_logs pour journaliser les lectures.
-- nil = pas de log Discord. Il faut d'abord ajouter une entrée
-- correspondante dans resources/[Rz_Script]/rz_logs/config.lua.
Config.LogCategory = nil
