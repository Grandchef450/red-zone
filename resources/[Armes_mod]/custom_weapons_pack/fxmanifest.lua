fx_version 'cerulean'
game 'gta5'

name 'custom_weapons_pack'
description 'RedZone Survival — armes blanches craftables'
author 'Grandchefstream'
version '2.1.0'

--[[
    CORRIGÉ LE 30 AOÛT 2026 — PLANTAGE AU CHARGEMENT

    ─── CE QUI PLANTAIT ───────────────────────────────────────────

    « An exception occurred during loading of
      custom_weapons_pack/data/weaponarch… in data file mounter »

    Mon weaponarchetypes.meta utilisait une structure INVENTÉE :
    des balises <ModelName> en majuscules avec trois champs, alors
    que GTA attend <modelName> en minuscules et une dizaine de
    champs obligatoires — txdName, lodDist, flags, et d'autres.

    Le lecteur de fichiers de données lisait donc des octets qu'il
    n'attendait pas, et le jeu se fermait.

    ─── LA CORRECTION ─────────────────────────────────────────────

    Le fichier est RETIRÉ. Il n'est pas indispensable : GTA résout
    le modèle d'une arme par le hash de son nom, déclaré dans la
    balise <Model> de weapons.meta. Le .ydr du dossier stream est
    trouvé par ce nom.

    weaponarchetypes.meta ne sert qu'à préciser la distance
    d'affichage et les relations de textures — deux réglages fins
    dont on peut se passer.

    ⚠️  SI UNE ARME APPARAÎT SANS TEXTURE en jeu, c'est là qu'il
    faudra revenir, avec une structure vérifiée sur un pack qui
    fonctionne. Mais ne réintroduis pas ce fichier « au cas où » :
    un format approximatif fait planter tout le monde au démarrage.
]]

files {
    'data/weaponanimations.meta',
    'data/weaponcomponents.meta',
    'data/weapons.meta',
}

data_file 'WEAPON_ANIMATIONS_FILE'    'data/weaponanimations.meta'
data_file 'WEAPONCOMPONENTSINFO_FILE' 'data/weaponcomponents.meta'
data_file 'WEAPONINFO_FILE_PATCH'     'data/weapons.meta'
