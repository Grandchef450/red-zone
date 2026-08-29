/* ═══════════════════════════════════════════════════════════════
   RedZone — affichage des signaux d'urgence

   Le Lua envoie un message, ce fichier l'affiche puis le masque.
   Aucune logique de jeu ici : tout est décidé côté serveur.
   ═══════════════════════════════════════════════════════════════ */

const el = {
    root:    document.getElementById('signal'),
    frame:   document.querySelector('.frame'),
    label:   document.getElementById('label'),
    time:    document.getElementById('time'),
    message: document.getElementById('message'),
    sender:  document.getElementById('sender'),
    bar:     document.getElementById('bar'),
};

let hideTimer = null;
let last = null;   // dernier signal, pour la commande /dernier

function show(data) {
    last = data;

    clearTimeout(hideTimer);

    const accent = data.color || '#4ade80';
    el.root.style.setProperty('--accent', accent);
    el.frame.style.setProperty('--accent', accent);

    el.label.textContent = data.label || 'SIGNAL';
    el.time.textContent = data.time || '';
    el.message.textContent = data.message || '';
    el.sender.textContent = data.sender ? ('— ' + data.sender) : '';

    // Relance l'animation de la barre : sans ce reset, un second
    // message n'en déclencherait pas une nouvelle.
    el.bar.classList.remove('running');
    void el.bar.offsetWidth;
    el.bar.style.animationDuration = (data.duration || 10000) + 'ms';
    el.bar.classList.add('running');

    el.frame.classList.remove('flicker');
    void el.frame.offsetWidth;
    el.frame.classList.add('flicker');

    el.root.classList.add('visible');

    hideTimer = setTimeout(hide, data.duration || 10000);
}

function hide() {
    el.root.classList.remove('visible');
    clearTimeout(hideTimer);
}

window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || !d.action) return;

    if (d.action === 'signal') {
        show(d);
    } else if (d.action === 'replay') {
        if (last) {
            show(Object.assign({}, last, { duration: 8000 }));
        }
    } else if (d.action === 'hide') {
        hide();
    }
});
