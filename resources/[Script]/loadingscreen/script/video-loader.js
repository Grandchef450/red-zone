/* ═══════════════════════════════════════════════════════════════════

     REDZONE — CONSTRUCTION DE LA VIDÉO DE FOND

     Ce fichier lit VIDEO_CONFIG et fabrique l'élément adapté.
     Tu n'as normalement aucune raison de le modifier : tout se règle
     dans video-config.js.

   ═══════════════════════════════════════════════════════════════════ */

(function () {
    'use strict';

    const conteneur = document.querySelector('.video-background');
    if (!conteneur || typeof VIDEO_CONFIG === 'undefined') return;

    const cfg = VIDEO_CONFIG;

    /* Le zoom s'applique aux deux modes. Un recadrage léger masque
       les bandes noires quand les proportions de la vidéo ne
       correspondent pas exactement à l'écran du joueur. */
    function appliquerZoom(el) {
        if (cfg.zoom && cfg.zoom !== 1.0) {
            el.style.transform = 'translate(-50%, -50%) scale(' + cfg.zoom + ')';
        }
    }


    /* ─── MODE LOCAL ───────────────────────────────────────────── */
    function monterLocal() {
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

        video.src = cfg.local.fichier;

        /* Si la lecture automatique est refusée malgré tout, on
           réessaie manuellement. Ça arrive sur certaines versions du
           navigateur intégré à FiveM. */
        video.addEventListener('canplay', function () {
            const tentative = video.play();

            if (tentative && tentative.catch) {
                tentative.catch(function () {
                    video.muted = true;
                    video.play().catch(function () {});
                });
            }
        });

        /* Un fichier introuvable ou illisible bascule sur YouTube :
           mieux vaut une vidéo distante qu'un écran noir. */
        video.addEventListener('error', function () {
            console.error('[loadingscreen] vidéo locale illisible : ' + cfg.local.fichier);
            conteneur.innerHTML = '';
            monterYoutube();
        });

        appliquerZoom(video);
        conteneur.appendChild(video);
    }


    /* ─── MODE YOUTUBE ─────────────────────────────────────────── */
    function monterYoutube() {
        const y = cfg.youtube;
        if (!y || !y.id) return;

        const params = [
            'autoplay=1',
            'mute=1',
            'controls=0',
            'showinfo=0',
            'rel=0',                    /* pas de suggestions à la fin */
            'modestbranding=1',
            'iv_load_policy=3',         /* pas d'annotations */
            'disablekb=1',
            'playsinline=1',
            'loop=1',
            'playlist=' + y.id,         /* indispensable : sans lui,
                                           loop=1 ne boucle pas */
            'vq=' + (y.qualite || 'hd1080'),
        ];

        if (y.debut && y.debut > 0) params.push('start=' + y.debut);

        const iframe = document.createElement('iframe');

        iframe.src = 'https://www.youtube.com/embed/' + y.id + '?' + params.join('&');
        iframe.frameBorder = '0';
        iframe.allow = 'autoplay; encrypted-media';
        iframe.setAttribute('allowfullscreen', '');

        /* Une iframe YouTube garde ses proportions 16:9 et laisse des
           bandes noires si on la dimensionne à 100%. On la surdimensionne
           pour qu'elle déborde et couvre tout l'écran. */
        iframe.style.cssText =
            'position:absolute;top:50%;left:50%;' +
            'width:100vw;height:56.25vw;' +          /* 16:9 sur la largeur */
            'min-width:177.77vh;min-height:100vh;' + /* 16:9 sur la hauteur */
            'transform:translate(-50%,-50%) scale(' + (cfg.zoom || 1.0) + ');' +
            'pointer-events:none;border:0;';

        conteneur.appendChild(iframe);
    }


    /* ─── CHOIX DU MODE ────────────────────────────────────────── */
    switch (cfg.mode) {
        case 'local':
            monterLocal();
            break;

        case 'youtube':
            monterYoutube();
            break;

        case 'aucune':
            break;

        default:
            console.warn('[loadingscreen] mode inconnu : ' + cfg.mode);
            monterLocal();
    }
})();
