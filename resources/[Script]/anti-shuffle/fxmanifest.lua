--[[
    CORRIGÉ — RedZone, 30 août 2026

    Ce manifeste déclarait « @WolfShield/WolfShield.lua » en
    shared_script, à la toute première ligne.

    WolfShield a été retiré du serveur : un seul anticheat suffit,
    et deux qui tournent ensemble finissent par se signaler
    mutuellement comme suspects.

    Une référence vers une ressource absente fait échouer le
    chargement AVANT même que le script ne s'exécute — d'où le
    « Failed to load script @WolfShield/WolfShield.lua » qui
    revenait trois fois à chaque démarrage.

    ElectronAC reste le seul anticheat du serveur.
]]

fx_version 'cerulean'
games { 'gta5' }

--	details
author 'omgugly'
description 'prevent passenger shuffling to driver seat unless holding left-shift'
version '1.1'

--	files
client_script 'client/client_main.lua'
server_script 'server/server_main.lua'
shared_script 'config.lua'
