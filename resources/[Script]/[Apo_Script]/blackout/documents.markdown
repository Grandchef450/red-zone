# Hate-Blackout Documentation

## Introduction

Hate-Blackout is a FiveM resource that allows server administrators to control the electricity in specific zones of the map. This creates dynamic gameplay experiences where certain areas can be plunged into darkness, adding immersion and challenges for players.

The resource uses PolyZone for area definitions and is fully compatible with both QBCore and ESX frameworks.

## Features

- Control electricity in custom-defined zones
- Compatible with QBCore and ESX frameworks
- Admin commands to toggle electricity in specific zones
- Seamless player synchronization
- Multi-language support (English and Turkish included)
- Performance optimized with minimal resource usage

## Installation

1. Ensure you have the PolyZone resource installed on your server
2. Download the Hate-Blackout resource
3. Place the `hate-blackout` folder in your server's resources directory
4. Add `ensure hate-blackout` to your server.cfg file
5. Configure the zones in the config.lua file
6. Restart your server

## Configuration

The `config.lua` file contains all configurable options for the script:

### Framework Selection

```lua
Config.Framework = 'qb' -- 'qb' for QBCore, 'esx' for ESX
```

### Power Zones

Define custom areas where electricity can be controlled:

```lua
Config.PowerZones = {
    ['safezone'] = {
        name = "Safe Zone",  -- Display name for the zone
        points = {
            vector3(1035.64, 3532.76, 34.07),
            vector3(1154.41, 3536.11, 34.97),
            vector3(1150.2, 3324.92, 43.57),
            vector3(1006.13, 3306.16, 39.69)
        },
        minZ = 0.0,         -- Minimum Z height of the zone
        maxZ = 100.0,       -- Maximum Z height of the zone
        hasElectricity = true  -- Initial electricity state
    },
    -- Add more zones as needed
}
```

### Command Configuration

```lua
Config.CommandName = "electricity" -- Command to control electricity
Config.AdminOnly = true -- Set to true if only admins can use the command
```

### Language Settings

```lua
Config.Language = 'fr' -- Default language: 'en' for English, 'tr' for Turkish
```

## Usage

### Admin Commands

Control electricity in zones using the command:

```
/electricity [zone] [state]
```

- `[zone]`: The zone identifier as defined in Config.PowerZones
- `[state]`: 
  - For English: "on" or "off"
  - For Turkish: "ac" or "kapat"

Example:
```
/electricity safezone off  -- Turns off electricity in the safezone
/electricity prison on     -- Turns on electricity in the prison zone
```

## Troubleshooting

If you encounter issues with the script:

1. Ensure you have PolyZone installed and working properly
2. Verify your framework is correctly set in the config
3. Check the server console for any error messages
4. Make sure your zone definitions have valid coordinates

## Support

For additional support, please contact the developer through the provided channels.
