/* ═══════════════════════════════════════════════════════════════════

     REDZONE — CONSTRUCTION DE LA VIDÉO DE FOND

     Ce fichier lit VIDEO_CONFIG et monte la balise <video>. Tu n'as
     normalement aucune raison de le modifier : tout se règle dans
     video-config.js.

   ═══════════════════════════════════════════════════════════════════ */

(function () {
    'use strict';

    const conteneur = document.querySelector('.video-background');
    if (!conteneur || typeof VIDEO_CONFIG === 'undefined') return;

    const cfg = VIDEO_CONFIG;
    if (!cfg.activee) return;

    const video = document.createElement('video');

    video.autoplay = true;
    video.loop = true;
    video.playsInline = true;
    video.preload = 'auto';

    /* muted DOIT être posé avant la source : les navigateurs
       décident d'autoriser ou non le démarrage automatique au
       moment où la source est attachée. */
    video.muted = true;
    video.defaultMuted = true;

    video.src = cfg.fichier;

    /* Le zoom masque d'éventuelles bandes noires si les proportions
       de la vidéo ne correspondent pas exactement à l'écran. */
    if (cfg.zoom && cfg.zoom !== 1.0) {
        video.style.transform = 'translate(-50%, -50%) scale(' + cfg.zoom + ')';
    }

    /* Si la lecture automatique est refusée malgré tout, on réessaie
       manuellement. Ça arrive sur certaines versions du navigateur
       intégré à FiveM. */
    video.addEventListener('canplay', function () {
        const tentative = video.play();

        if (tentative && tentative.catch) {
            tentative.catch(function () {
                video.muted = true;
                video.play().catch(function () {});
            });
        }
    });

    /* Fichier introuvable, codec non supporté, ou index en fin de
       fichier (MP4 non « web optimized ») : on le dit clairement en
       console plutôt que de laisser un fond noir sans explication. */
    video.addEventListener('error', function () {
        console.error(
            '[loadingscreen] vidéo illisible : ' + cfg.fichier +
            ' — vérifie qu\'elle est déclarée dans fxmanifest.lua ' +
            'et qu\'elle est encodée « web optimized » (voir video-config.js).'
        );
    });

    conteneur.appendChild(video);
})();
