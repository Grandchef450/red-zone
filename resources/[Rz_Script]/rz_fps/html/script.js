/* ═══════════════════════════════════════════════════════════════
   RedZone — réglages graphiques

   JavaScript natif, sans jQuery : l'ancien menu en dépendait pour
   afficher quatre boutons.
   ═══════════════════════════════════════════════════════════════ */

const el = {
    counter: document.getElementById('counter'),
    fps:     document.getElementById('fps'),
    menu:    document.getElementById('menu'),
    list:    document.getElementById('profiles'),
    toggle:  document.getElementById('counterToggle'),
    live:    document.getElementById('live'),
    close:   document.getElementById('close'),
    auto:    document.getElementById('auto'),
    detect:  document.getElementById('detect'),
    dText:   document.getElementById('detectText'),
    dSub:    document.getElementById('detectSub'),
};

const RES = 'rz_fps';

function post(name, data) {
    return fetch('https://' + RES + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(function () {});
}

function buildProfiles(profiles, active) {
    el.list.innerHTML = '';

    profiles.forEach(function (p) {
        const div = document.createElement('div');
        div.className = 'profile' + (p.key === active ? ' active' : '');
        div.dataset.key = p.key;
        div.innerHTML =
            '<span class="name">' + p.label + '</span>' +
            '<span class="desc">' + p.note + '</span>' +
            (p.hint ? '<span class="hint">' + p.hint + '</span>' : '');

        div.addEventListener('click', function () {
            el.list.querySelectorAll('.profile').forEach(function (n) {
                n.classList.remove('active');
            });
            div.classList.add('active');
            post('setProfile', { key: p.key });
        });

        el.list.appendChild(div);
    });
}

function setFps(value, good, warn) {
    el.fps.textContent = value;
    el.live.textContent = value + ' FPS';

    el.fps.classList.toggle('warn', value < good && value >= warn);
    el.fps.classList.toggle('bad', value < warn);
}

function closeMenu() {
    el.menu.classList.remove('on');
    post('close');
}

el.close.addEventListener('click', closeMenu);

el.auto.addEventListener('click', function () {
    el.auto.disabled = true;
    el.detect.classList.add('on');
    el.detect.classList.remove('done');
    el.dText.textContent = 'Préparation...';
    el.dSub.textContent = '';
    post('autoDetect');
});

el.toggle.addEventListener('change', function () {
    post('setCounter', { show: el.toggle.checked });
    el.counter.classList.toggle('on', el.toggle.checked);
});

document.addEventListener('keyup', function (e) {
    if (e.key === 'Escape' && el.menu.classList.contains('on')) closeMenu();
});

window.addEventListener('message', function (event) {
    const d = event.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'open':
            buildProfiles(d.profiles, d.current);
            el.toggle.checked = !!d.counter;
            setFps(d.fps || 0, 50, 30);
            el.menu.classList.add('on');
            break;

        case 'close':
            el.menu.classList.remove('on');
            break;

        case 'fps':
            setFps(d.value, d.good, d.warn);
            break;

        case 'counter':
            el.counter.className = 'counter'
                + (d.show ? ' on' : '')
                + (d.position ? ' pos-' + d.position : '');
            break;

        case 'detecting':
            if (d.phase === 'warmup') {
                el.dText.textContent = 'Préparation...';
                el.dSub.textContent = 'Démarrage dans ' + d.left + ' s';
            } else {
                el.dText.textContent = 'Mesure en cours';
                el.dSub.textContent = d.left + ' s restantes'
                    + (d.current ? '  ·  ' + d.current + ' FPS' : '');
            }
            break;

        case 'detected':
            el.detect.classList.add('done');
            el.dText.textContent = d.average + ' FPS en moyenne';
            el.dSub.textContent = 'Profil appliqué : ' + d.label;
            el.auto.disabled = false;

            el.list.querySelectorAll('.profile').forEach(function (n) {
                const match = n.dataset.key === d.recommended;
                n.classList.toggle('active', match);
                n.classList.toggle('recommended', match);
            });
            break;

        case 'profile':
            el.list.querySelectorAll('.profile').forEach(function (n) {
                n.classList.toggle('active', n.dataset.key === d.key);
            });
            break;
    }
});
