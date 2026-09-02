fx_version 'cerulean'
games { 'gta5' }

author 'GrandchefStream'
description 'RedZone Survival — écran de chargement'
version '1.1.0'

--[[
    VIDÉO DE FOND — LOCAL UNIQUEMENT

    L'option YouTube a été retirée du code le 1er septembre 2026
    (script/video-loader.js ne sait plus construire d'iframe) : un
    écran de chargement ne doit dépendre d'aucune connexion externe
    au moment précis où le joueur charge. Tout se règle désormais
    dans script/video-config.js — un seul fichier vidéo, en local.

    Le fichier livré (video/intro_zombie.mp4) a aussi été corrigé ce
    jour-là : son index (« moov ») était en fin de fichier au lieu du
    début, ce qui obligeait le navigateur à tout télécharger avant de
    pouvoir démarrer la lecture — invisible sur un écran de quelques
    secondes. Voir video-config.js pour ne pas reproduire l'erreur en
    déposant une nouvelle vidéo.

    ⚠️  UN FICHIER NON DÉCLARÉ DANS `files` N'EST PAS SERVI AU
    CLIENT. C'est la cause n°1 d'un écran de chargement noir : le
    fichier est bien sur le serveur, mais FiveM refuse de l'envoyer
    parce qu'il ne figure pas dans cette liste.
]]

loadscreen 'index.html'
loadscreen_cursor 'yes'

--[[
    ⚠️  « loadscreen_manual_shutdown » A ÉTÉ RETIRÉ — 30 août 2026

    Cette directive dit à FiveM de NE JAMAIS fermer l'écran de
    lui-même : c'est au script de le faire. Elle a du sens quand un
    multicharacter prend le relais, mais elle devient un piège quand
    personne n'appelle la fermeture.

    Ce qui se passait ici :

      • le loadingscreen attendait « playerSpawned », émis par
        spawnmanager — désactivé depuis la migration vers Qbox

      • ZSX devait prendre le relais via HandlePreWarmup(), mais
        cette fonction n'est APPELÉE NULLE PART dans le code
        déchiffré, et la variable CreatedUIFrame qu'elle attend
        n'est jamais mise à true

      • ZSX_UI et ZSX_UIV2 ne sont pas installés : l'interface de
        sélection ne peut pas se construire

    Résultat : personne ne fermait l'écran, et le joueur restait
    enfermé indéfiniment avec la musique en fond.

    Sans cette directive, FiveM ferme l'écran automatiquement dès
    que la session est prête. On perd la transition douce vers le
    multicharacter, mais on entre en jeu — ce qui vaut mieux.

    À remettre le jour où ZSX_UI sera installé et fonctionnel.
]]

client_script 'client.lua'
server_script 'server.lua'

files {
    'index.html',
    'css/style.css',
    -- ─── VIDÉO ─────────────────────────────────────────────────
    -- video-config.js contient le fichier et le réglage activee.
    -- video-loader.js construit la balise <video> correspondante.
    'script/video-config.js',
    'script/video-loader.js',

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
