/* ═══════════════════════════════════════════════════════════════════

     REDZONE — CHOIX DE LA VIDÉO DE FOND

     Un seul réglage à changer, juste en dessous.

   ═══════════════════════════════════════════════════════════════════ */

const VIDEO_CONFIG = {

    /* ─────────────────────────────────────────────────────────────
       LE MODE

         'local'    fichier hébergé sur ton serveur
         'youtube'  vidéo YouTube en fond
         'aucune'   fond noir, sans vidéo
       ───────────────────────────────────────────────────────────── */
    mode: 'local',


    /* ─── MODE LOCAL ──────────────────────────────────────────────

       Le fichier doit être déclaré dans fxmanifest.lua, sinon FiveM
       ne le sert pas au client — c'est la cause n°1 d'écran noir.

       ⚠️  L'INDEX DU FICHIER DOIT ÊTRE AU DÉBUT.

       Un MP4 non optimisé place son index (le bloc « moov ») à la
       fin. Le navigateur doit alors télécharger le fichier ENTIER
       avant d'afficher la première image — sur un écran de
       chargement de trente secondes, la vidéo n'apparaît jamais.

       Dans HandBrake, coche « Web Optimized » (onglet Summary).
       C'est ce seul réglage qui débloque tout.
       ───────────────────────────────────────────────────────────── */
    local: {
        fichier: 'video/intro_zombie.mp4',
    },


    /* ─── MODE YOUTUBE ────────────────────────────────────────────

       Colle simplement l'identifiant de la vidéo, pas l'URL entière.

         https://www.youtube.com/watch?v=dQw4w9WgXcQ
                                        └──── ceci ────┘

       AVANTAGES     rien à héberger, aucune bande passante consommée,
                     démarrage immédiat, qualité adaptative
       INCONVÉNIENTS dépend d'une connexion externe, la vidéo peut
                     être supprimée ou passer en privé
       ───────────────────────────────────────────────────────────── */
    youtube: {
        id: '_nzMxd_rOuw',

        /* Qualité demandée : 'hd1080', 'hd720', 'large' (480p).
           YouTube reste libre de baisser si la connexion ne suit
           pas — ce paramètre est une préférence, pas une garantie. */
        qualite: 'hd720',

        /* Seconde de départ. Utile pour sauter une introduction. */
        debut: 0,
    },


    /* ─── COMMUN AUX DEUX MODES ───────────────────────────────────

       Le son reste TOUJOURS coupé : la musique vient de
       song/Apocalypse2.mp3, et les deux se superposeraient.

       C'est aussi une contrainte technique — les navigateurs
       refusent le démarrage automatique d'une vidéo avec du son.
       ───────────────────────────────────────────────────────────── */
    zoom: 1.0,        /* 1.0 = ajusté. 1.15 recadre légèrement pour
                         masquer d'éventuelles bandes noires. */
};
