fx_version 'cerulean'
game 'gta5'
description 'rpemotes-reborn'
version '2.0.3'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

provide "rpemotes"

dependencies {
    '/server:6683',
    '/onesync'
}

files {
    'conditionalanims.meta',
    'header.png',
    'locales/*.lua'
}

-- Unlocks idle Animations from GTA:O when using motorcycles, dirt bikes, etc
data_file 'CONDITIONAL_ANIMS_FILE' 'conditionalanims.meta'

shared_scripts {
    'types.lua',
    'locale.lua',
    'config.lua',
    'shared/ModelCompat.lua',
}

server_scripts {
    'server/Server.lua',
    'server/Updates.lua',
    'server/emojis.lua',
    'server/GroupEmote.lua'
}

client_scripts {
    'NativeUI.lua',
    'client/Utils.lua',
    'client/Bridge.lua',
    'client/AnimationList.lua',
    'client/AnimationListCustom.lua',
    'client/Binoculars.lua',
    'client/Crouch.lua',
    'client/Emote.lua',
    'client/GroupEmote.lua',
    'client/EmoteMenu.lua',
    'client/Expressions.lua',
    'client/Handsup.lua',
    'client/Keybinds.lua',
    'client/Favorites.lua',
    'client/NewsCam.lua',
    'client/NoIdleCam.lua',
    'client/Pointing.lua',
    'client/PTFX.lua',
    'client/Ragdoll.lua',
    'client/Syncing.lua',
    'client/Walk.lua',
    'client/Placement.lua',
    'client/emojis.lua',
}

-- ⚠️  CORRECTIF COMPATIBILITÉ — 1er septembre 2026
--
-- Les 17 chemins ci-dessous pointaient à plat sur stream/xxx.ytyp,
-- mais les fichiers vivent en réalité un niveau plus bas, dans
-- stream/[Props]/<Pack>/xxx.ytyp. `data_file` exige le chemin EXACT
-- (contrairement au streaming des .ydr/.ytd, que FiveM détecte tout
-- seul quelle que soit leur profondeur) : un chemin faux échoue en
-- silence, sans erreur en console. Résultat concret avant correctif :
-- l'animation d'une emote se jouait, mais l'accessoire associé
-- (milkshake, pizza, sucette, gâteau, briquet, planche, etc.)
-- n'apparaissait jamais, faute d'archétype enregistré.
data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/rpemotesreborn/rpemotesreborn_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Brummiee/brummie_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_camp_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/CandyApple/apple_1.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KayKayMods/kaykaymods_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/KnjghPizzaSlices/knjgh_pizzas.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/NattyLollipops/natty_props_lollipops.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/UltraRingCase/ultra_ringcase.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PataMods/pata_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/vedere/vedere_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/PNWParksFan/pnwsigns.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/EP/pprp_icefishing.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/Scully/scully_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/samnick_prop_lighter01.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/BzzziProps/bzzz_murderpack.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/[Props]/protestsigns_fh/prop_protestsign_fh.ytyp'
