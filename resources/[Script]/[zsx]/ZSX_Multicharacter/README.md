# BEFORE
Make sure to follow those steps before joining up to the server. Otherwise you will face issues if you won't install resource correctly!

## Documentation
We also got online documentation available at https://zsx-development.gitbook.io/docs/multicharacter/installation

## Installation

### ESX
- Remove esx_multicharacter from `/resources/[core]` folder
- Put ZSX_Multicharacter in /resources folder
- Set `Config.Multichar = true` in: 
    - `es_extended/shared/config/main.lua` if you are on the ESX 1.12 and above
    - `es_extended/config.lua` if you're belove ESX 1.12
- Go to server.cfg file or CFG editor if you're on txAdmin
- Add `ensure ZSX_Multicharacter` beneath `ensure [core]`
### QBCore
- Remove qb-multicharacter from `/resources/[qb]` folder
- Put ZSX_Multicharacter in /resources folder
- Go to server.cfg file or CFG editor if you're on txAdmin
- Add `ensure ZSX_Multicharacter` beneath `ensure [qb]`
### QBOX
- Headover to the `resources/[qbx]/qbx-core/config/client.lua` and set at line 8:
    ```
        useExternalCharacters = true,
    ```
- Put ZSX_Multicharacter in /resources folder
- Add `ensure ZSX_Multicharacter` beneath `ensure [qbx]`

## Configurating

- Set your desired slot amount before joining up the server in `ZSX_Multicharacter/shared/config.lua` by setting variable, in that example we will set slots to 3:
    ```
        Config.Characters.Free = 3
    ```
- Set your appearance resource in `ZSX_Multicharacter/shared/config.lua` by setting variable, in that example we will set to illenium-appearance:
    ```
        Config.ForceAppereance = "illenium-appearance"
    ```
All our compatibility list is available here: https://zsx-development.gitbook.io/docs/multicharacter/installation/setting-up-the-appearance

Rest of the configuration is available here: https://zsx-development.gitbook.io/docs/multicharacter/installation/
Our discord: https://discord.gg/zsx
