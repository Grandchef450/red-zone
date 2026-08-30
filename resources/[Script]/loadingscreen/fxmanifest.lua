fx_version 'cerulean'
games { 'gta5' }

author 'GrandchefStream'
description 'RedZone Survival — écran de chargement'
version '1.1.0'

--[[
    MODIFIÉ LE 30 AOÛT 2026

    La vidéo de fond n'est plus une iframe YouTube mais un fichier
    local : video/fond.mp4

    ⚠️  UN FICHIER NON DÉCLARÉ DANS `files` N'EST PAS SERVI AU
    CLIENT. C'est la cause n°1 d'un écran de chargement noir : le
    fichier est bien sur le serveur, mais FiveM refuse de l'envoyer
    parce qu'il ne figure pas dans cette liste.
]]

loadscreen 'index.html'
loadscreen_manual_shutdown 'yes'
loadscreen_cursor 'yes'

client_script 'client.lua'
server_script 'server.lua'

files {
    'index.html',
    'css/style.css',
    'script/main.js',

    -- ─── VIDÉO DE FOND ─────────────────────────────────────────
    -- Le son de ce fichier n'est jamais joué : la balise video est
    -- en `muted`. C'est song/Apocalypse2.mp3 qu'on entend.
    'video/intro_zombie.mp4',

    -- ─── MUSIQUE ───────────────────────────────────────────────
    'song/Apocalypse2.mp3',

    -- ─── LOGOS ─────────────────────────────────────────────────
    'logo/logo.png',
    'logo/logo2.png',
    'logo/Grandchef_logo.png',

    -- ─── INTERFACE ─────────────────────────────────────────────
    'img/ARROW_DOWN.png',
    'img/ARROW_UP.png',
    'img/Discord.png',
    'img/person1.png',
    'img/person2.png',
    'img/person3.png',
    'img/person4.png',
    'img/person5.png',
    'img/Site.png',
    'img/SPACE.png',
    'img/Tiktok.png',
}
