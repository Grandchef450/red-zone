--[[
    ElectronAC reste verrouillé sur une autre IP et ne démarre pas
    (ensure ElectronAC est commenté dans server.cfg). Une ressource
    qui référence encore ses fichiers via @ElectronAC/... échoue au
    chargement avec elle — PolyZone ne démarrait donc jamais, ce qui
    coupait blackout au passage (il en dépend, cf. server.cfg).

    Décommente les deux lignes le jour où ElectronAC fonctionne.
]]

-- server_script '@ElectronAC/src/include/server.lua'
-- client_script '@ElectronAC/src/include/client.lua'




games {'gta5'}

fx_version 'cerulean'

description 'Define zones of different shapes and test whether a point is inside or outside of the zone'
version '2.6.2'

client_scripts {
  'client.lua',
  'BoxZone.lua',
  'EntityZone.lua',
  'CircleZone.lua',
  'ComboZone.lua',
  'creation/client/*.lua'
}

server_scripts {
  'creation/server/*.lua',
  'server.lua'
}
