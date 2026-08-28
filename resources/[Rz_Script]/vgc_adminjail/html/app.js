/* =============================================
   VGC ADMIN JAIL — app.js
   Deux modes dans la même NUI :
   • Panneau admin (avec focus)
   • Overlay du joueur emprisonné (sans focus)
   ============================================= */
'use strict';

const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'vgc_adminjail';

function nui(action, data = {}) {
    return fetch(`https://${RESOURCE_NAME}/${action}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

const panelEl   = document.getElementById('panel');
const overlayEl = document.getElementById('jail-overlay');
const audioEl   = document.getElementById('jail-audio');

// ── Toast ─────────────────────────────────────────────────
const toastEl = document.getElementById('toast');
let toastTimer;
function toast(msg, type = 'ok') {
    toastEl.textContent = msg;
    toastEl.className   = `toast show ${type}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2600);
}

function fmt(sec) {
    sec = Math.max(0, Math.round(sec));
    return `${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, '0')}`;
}

// ═══════════════════════════════════════════════════════════
//  PANNEAU ADMIN
// ═══════════════════════════════════════════════════════════

let panelData = null;
let myPos     = null;

const selPlayer   = document.getElementById('j-player');
const selLocation = document.getElementById('j-location');
const selPreset   = document.getElementById('j-music-preset');
const customBox   = document.getElementById('j-custom-coords');

function renderPanel() {
    if (!panelData) return;
    const d = panelData;

    document.getElementById('p-max').textContent = 'max ' + fmt(d.maxSeconds);
    const dur = document.getElementById('j-duration');
    dur.max = d.maxSeconds;

    // Joueurs (exclut ceux déjà en prison)
    selPlayer.innerHTML = '';
    (d.players || []).forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.serverId;
        opt.textContent = `[${p.serverId}] ${p.name}` + (p.jailed ? ' — ⛓ déjà en prison' : '');
        opt.disabled = p.jailed;
        selPlayer.appendChild(opt);
    });
    if (!selPlayer.children.length) {
        selPlayer.innerHTML = '<option disabled selected>Aucun joueur en ligne</option>';
    }

    // Lieux : presets + ma position + custom
    selLocation.innerHTML = '';
    (d.locations || []).forEach((l, i) => {
        const opt = document.createElement('option');
        opt.value = 'preset:' + i;
        opt.textContent = l.label;
        selLocation.appendChild(opt);
    });
    const optMe = document.createElement('option');
    optMe.value = 'me';
    optMe.textContent = '📍 Ma position actuelle';
    selLocation.appendChild(optMe);
    const optCustom = document.createElement('option');
    optCustom.value = 'custom';
    optCustom.textContent = '⌨ Coordonnées custom…';
    selLocation.appendChild(optCustom);

    // Presets musique
    selPreset.innerHTML = '';
    (d.musicPresets || []).forEach((m, i) => {
        const opt = document.createElement('option');
        opt.value = i;
        opt.textContent = m.label;
        selPreset.appendChild(opt);
    });

    document.getElementById('j-volume').value = d.defVolume ?? 0.6;
    document.getElementById('j-vol-label').textContent = Math.round((d.defVolume ?? 0.6) * 100) + '%';
    dur.value = d.defSeconds ?? 120;
    document.getElementById('j-dur-label').textContent = fmt(dur.value);

    renderActive();
}

function renderActive() {
    const list = document.getElementById('j-active-list');
    list.innerHTML = '';
    const jails = (panelData && panelData.jails) || [];
    if (!jails.length) {
        list.innerHTML = '<div class="j-empty">Aucune peine en cours.</div>';
        return;
    }
    jails.forEach(j => {
        const row = document.createElement('div');
        row.className = 'j-row';
        row.innerHTML = `
            <div class="j-info">
                <div class="j-name">${j.name} ${j.online ? '' : '<span class="j-off">(déco)</span>'}</div>
                <div class="j-meta">reste <b>${fmt(j.remaining)}</b> · par ${j.byName}${j.reason ? ' · ' + j.reason : ''}</div>
            </div>
            <button class="btn-red">Libérer</button>
        `;
        row.querySelector('.btn-red').addEventListener('click', () => {
            nui('unjail', { license: j.license });
        });
        list.appendChild(row);
    });
}

// ── Interactions ──────────────────────────────────────────

selLocation.addEventListener('change', () => {
    customBox.classList.toggle('hidden', selLocation.value !== 'custom');
});

selPreset.addEventListener('change', () => {
    const m = panelData.musicPresets[parseInt(selPreset.value)];
    if (m) document.getElementById('j-music-url').value = m.url || '';
});

document.getElementById('j-duration').addEventListener('input', e => {
    document.getElementById('j-dur-label').textContent = fmt(e.target.value);
});
document.getElementById('j-volume').addEventListener('input', e => {
    document.getElementById('j-vol-label').textContent = Math.round(e.target.value * 100) + '%';
});

document.getElementById('btn-refresh').addEventListener('click', () => nui('refresh'));
document.getElementById('p-close').addEventListener('click', () => {
    nui('closePanel');
    panelEl.classList.add('hidden');
});

document.getElementById('btn-jail').addEventListener('click', () => {
    const targetId = parseInt(selPlayer.value);
    if (isNaN(targetId)) { toast('Choisis un joueur', 'err'); return; }

    // Coordonnées selon le mode choisi
    let coords = null;
    const loc = selLocation.value;
    if (loc === 'me') {
        coords = myPos;
    } else if (loc === 'custom') {
        coords = {
            x: parseFloat(document.getElementById('j-x').value),
            y: parseFloat(document.getElementById('j-y').value),
            z: parseFloat(document.getElementById('j-z').value),
            heading: 0,
        };
        if ([coords.x, coords.y, coords.z].some(isNaN)) {
            toast('Coordonnées custom incomplètes', 'err');
            return;
        }
    } else if (loc.startsWith('preset:')) {
        const l = panelData.locations[parseInt(loc.slice(7))];
        coords = { x: l.x, y: l.y, z: l.z, heading: l.heading || 0 };
    }
    if (!coords) { toast('Choisis un lieu', 'err'); return; }

    const url = document.getElementById('j-music-url').value.trim();
    const payload = {
        targetId,
        seconds: parseInt(document.getElementById('j-duration').value),
        coords,
        reason: document.getElementById('j-reason').value.trim(),
        music: url ? { url, volume: parseFloat(document.getElementById('j-volume').value) } : null,
    };
    nui('jail', payload);
    toast('Envoi…', 'ok');
});

// ═══════════════════════════════════════════════════════════
//  OVERLAY JOUEUR EMPRISONNÉ
// ═══════════════════════════════════════════════════════════

let jailTimer   = null;
let jailEndsAt  = 0;
let jailTotal   = 0;

function startJailOverlay(seconds, reason, music) {
    jailTotal  = seconds;
    jailEndsAt = Date.now() + seconds * 1000;

    document.getElementById('jo-reason').textContent = reason || '';
    overlayEl.classList.remove('hidden');

    // Musique en boucle
    if (music && music.url) {
        audioEl.src    = music.url;
        audioEl.volume = Math.min(1, Math.max(0, music.volume ?? 0.6));
        audioEl.play().catch(() => {
            console.log('[vgc_adminjail] lecture audio refusée (URL invalide ?)');
        });
    }

    clearInterval(jailTimer);
    jailTimer = setInterval(() => {
        const remain = (jailEndsAt - Date.now()) / 1000;
        document.getElementById('jo-time').textContent = fmt(remain);
        const pct = Math.max(0, Math.min(100, (remain / jailTotal) * 100));
        document.getElementById('jo-fill').style.width = pct + '%';
        if (remain <= 0) clearInterval(jailTimer);
        // (la libération réelle vient TOUJOURS du serveur)
    }, 250);
}

function stopJailOverlay() {
    clearInterval(jailTimer);
    overlayEl.classList.add('hidden');
    audioEl.pause();
    audioEl.removeAttribute('src');
    audioEl.load();
}

let leashTimer = null;
function flashLeash() {
    const el = document.getElementById('jo-leash');
    el.classList.remove('hidden');
    clearTimeout(leashTimer);
    leashTimer = setTimeout(() => el.classList.add('hidden'), 2000);
}

// ═══════════════════════════════════════════════════════════
//  MESSAGES LUA → UI
// ═══════════════════════════════════════════════════════════

window.addEventListener('message', e => {
    const d = e.data;
    switch (d.action) {

        // ── Panneau admin ──
        case 'openPanel':
            panelData = d.data || {};
            myPos     = panelData.myPos || null;
            panelEl.classList.remove('hidden');
            renderPanel();
            break;

        case 'panelData':
            panelData = d.data || {};
            myPos     = panelData.myPos || myPos;
            renderPanel();
            break;

        case 'closePanel':
            panelEl.classList.add('hidden');
            break;

        // ── Joueur emprisonné ──
        case 'jailStart':
            startJailOverlay(d.seconds || 0, d.reason, d.music);
            break;

        case 'jailLeash':
            flashLeash();
            break;

        case 'jailEnd':
            stopJailOverlay();
            break;
    }
});

// ESC ferme le panneau (jamais l'overlay du prisonnier)
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !panelEl.classList.contains('hidden')) {
        nui('closePanel');
        panelEl.classList.add('hidden');
    }
});
