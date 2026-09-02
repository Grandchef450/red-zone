/* ═══════════════════════════════════════════════════════════════════

     REDZONE — VIDÉO DE FOND DE L'ÉCRAN DE CHARGEMENT

     Uniquement en local, volontairement : un fichier hébergé sur le
     serveur ne dépend d'aucune connexion externe au moment précis où
     le joueur charge — pas de pare-feu, pas de blocage régional, pas
     de vidéo supprimée un jour sans prévenir. C'est le mode le plus
     fiable pour un écran de chargement, qui ne dure que quelques
     secondes.

   ═══════════════════════════════════════════════════════════════════ */

const VIDEO_CONFIG = {

    /* false = fond noir, sans vidéo. Utile pour couper rapidement la
       vidéo sans avoir à supprimer le fichier. */
    activee: true,

    /* ─────────────────────────────────────────────────────────────
       CHANGER DE VIDÉO

       1. Dépose le nouveau fichier dans video/ (MP4, codec H.264).
       2. Change `fichier` ci-dessous pour son nom exact.
       3. Déclare-le dans fxmanifest.lua, dans la liste `files` —
          un fichier non déclaré là n'est pas servi au client,
          c'est la cause n°1 d'un écran de chargement noir.

       ⚠️  L'INDEX DU FICHIER DOIT ÊTRE AU DÉBUT (« web optimized »).

       Un MP4 non optimisé place son index (le bloc « moov ») à la
       fin. Le navigateur doit alors télécharger le fichier ENTIER
       avant d'afficher la première image — sur un écran de
       chargement de quelques secondes, la vidéo n'apparaît jamais.
       C'est exactement ce qui rendait intro_zombie.mp4 invisible
       avant le correctif du 1er septembre 2026.

       Dans HandBrake, coche « Web Optimized » (onglet Summary).
       Avec ffmpeg : `ffmpeg -i source.mp4 -c copy -movflags +faststart sortie.mp4`
       ───────────────────────────────────────────────────────────── */
    fichier: 'video/intro_zombie.mp4',


    /* ─── SON ─────────────────────────────────────────────────────
       Toujours coupé : la musique vient de song/Apocalypse2.mp3, et
       les deux se superposeraient. C'est aussi une contrainte
       technique — les navigateurs refusent le démarrage automatique
       d'une vidéo avec du son.
       ───────────────────────────────────────────────────────────── */

    zoom: 1.0,        /* 1.0 = ajusté. 1.15 recadre légèrement pour
                         masquer d'éventuelles bandes noires. */
};
