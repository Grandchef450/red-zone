fx_version 'cerulean'
game 'gta5'

name 'custom_weapons_pack'
description 'RedZone Survival — armes blanches craftables'
author 'Grandchefstream'
version '2.0.0'

--[[
    CORRIGÉ LE 29 AOÛT 2026

    Le manifeste d'origine déclarait WEAPONINFO_FILE pour un fichier
    de structures et WEAPONINFO_FILE_PATCH pour un fichier vide.
    Les deux étaient inversés, et aucun dossier stream n'existait :
    le pack ne pouvait rien ajouter au jeu.

    L'ordre des data_file compte : les archétypes doivent être
    déclarés AVANT les infos d'arme, sinon GTA cherche un modèle
    qu'il ne connaît pas encore.
]]

files {
    'data/weaponarchetypes.meta',
    'data/weaponanimations.meta',
    'data/weaponcomponents.meta',
    'data/weapons.meta',
}

data_file 'WEAPON_METADATA_FILE'      'data/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE'    'data/weaponanimations.meta'
data_file 'WEAPONCOMPONENTSINFO_FILE' 'data/weaponcomponents.meta'
data_file 'WEAPONINFO_FILE_PATCH'     'data/weapons.meta'
