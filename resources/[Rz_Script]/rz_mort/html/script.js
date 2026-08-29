/* ═══════════════════════════════════════════════════════════════
   RedZone — écran d'agonie

   Le Lua envoie l'état et les secondes restantes ; ce fichier
   dessine. Aucune touche n'est lue ici : les commandes du joueur
   restent gérées en Lua, ce qui évite d'avoir à capturer le focus
   souris et de bloquer le jeu.
   ═══════════════════════════════════════════════════════════════ */

const el = {
    screen: document.getElementById('screen'),
    state:  document.getElementById('state'),
    timer:  document.getElementById('timer'),
    hint:   document.getElementById('hint'),
};

function fmt(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
}

function showDowned(d) {
    el.screen.classList.remove('recover');
    el.screen.classList.add('on', 'slow');
    el.state.textContent = 'TU ES À TERRE';
    update(d);
}

function showRecovery(d) {
    el.screen.classList.add('on', 'recover');
    el.screen.classList.remove('critical', 'slow');
    el.state.textContent = 'INJECTION REÇUE';
    el.timer.textContent = fmt(d.left);
    el.hint.innerHTML = 'Reste immobile, le produit fait effet';
}

function update(d) {
    el.timer.textContent = fmt(d.left);

    // Le cœur ralentit à mesure que le temps s'épuise : de 2,5 s
    // par cycle au début à 5 s quand la fin approche.
    const ratio = Math.max(0, Math.min(1, d.left / d.total));
    el.screen.style.setProperty('--beat', (2.5 + (1 - ratio) * 2.5).toFixed(2) + 's');

    el.screen.classList.toggle('critical', d.left <= 30);

    let hint = '<b>G</b> appeler à l\'aide';
    if (d.canGiveUp) hint += '     <b>RETOUR ARRIÈRE</b> abandonner';
    el.hint.innerHTML = hint;
}

function hide() {
    el.screen.classList.remove('on', 'recover', 'critical', 'slow');
}

window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'downed':   showDowned(d);   break;
        case 'update':   update(d);       break;
        case 'recovery': showRecovery(d); break;
        case 'hide':     hide();          break;
    }
});
