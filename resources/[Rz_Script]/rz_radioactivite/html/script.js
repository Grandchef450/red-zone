/* ═══════════════════════════════════════════════════════════════
   RedZone — pilotage de la surimpression contaminée

   Le Lua envoie l'intensité (0 au bord de la zone, 1 au cœur) et
   ce fichier ajuste l'opacité des couches. Rien d'autre.
   ═══════════════════════════════════════════════════════════════ */

const el = {
    root:  document.getElementById('rad'),
    dark:  document.getElementById('dark'),
    veil:  document.getElementById('veil'),
    vig:   document.getElementById('vig'),
    grain: document.getElementById('grain'),
};

let cfg = { darkness: 0.45, redVeil: 0.35, grain: true };
let pulseTimer = null;

function apply(intensity) {
    // Plancher à 0.35 : même au bord, l'effet doit être perceptible,
    // sinon le joueur ne comprend pas qu'il vient d'entrer.
    const i = 0.35 + Math.max(0, Math.min(1, intensity)) * 0.65;

    el.dark.style.opacity  = (cfg.darkness * i).toFixed(3);
    el.veil.style.opacity  = (cfg.redVeil * i).toFixed(3);
    el.vig.style.opacity   = i.toFixed(3);
    el.grain.style.opacity = cfg.grain ? (0.09 * i).toFixed(3) : 0;
}

window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'show':
            cfg.darkness = d.darkness ?? cfg.darkness;
            cfg.redVeil  = d.redVeil  ?? cfg.redVeil;
            cfg.grain    = d.grain !== false;
            apply(d.intensity ?? 0);
            el.root.classList.add('on');
            break;

        case 'hide':
            el.root.classList.remove('on', 'masked');
            break;

        case 'intensity':
            apply(d.value ?? 0);
            break;

        case 'pulse':
            el.root.classList.remove('pulse');
            void el.root.offsetWidth;   // relance l'animation
            el.root.classList.add('pulse');

            clearTimeout(pulseTimer);
            pulseTimer = setTimeout(() => el.root.classList.remove('pulse'), 600);
            break;

        case 'mask':
            el.root.classList.toggle('masked', !!d.on);
            break;
    }
});
