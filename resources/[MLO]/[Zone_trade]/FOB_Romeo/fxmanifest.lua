fx_version 'cerulean'
game 'gta5'
author 'OS Mapping'

this_is_a_map 'yes'

-- Nettoyé le 2026-09-03 : files{} racine, STREAMING_FILE_TABLE et SCENARIO_INFO_FILE retirés ; ITYP via stream/.
-- Les fichiers de stream/ sont diffusés automatiquement, inutile
-- de les lister dans files{}.

data_file 'DLC_ITYP_REQUEST' 'stream/**.ytyp'
