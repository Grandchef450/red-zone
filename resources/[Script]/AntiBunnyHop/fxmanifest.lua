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

fx_version 'bodacious'
game 'gta5'

client_script {
    'client.lua'
}
