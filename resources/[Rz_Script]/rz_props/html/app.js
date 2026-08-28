/* =============================================
   RZ PROPS  —  app.js  v1.0
   ============================================= */
'use strict';

const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName() : 'rz_props';

function nui(action, data = {}) {
    return fetch(`https://${RESOURCE_NAME}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

const appEl   = document.getElementById('app');
const listEl  = document.getElementById('list');
const countEl = document.getElementById('count');
const presetEl= document.getElementById('preset');
const modelEl = document.getElementById('model');
const nameEl  = document.getElementById('name');
const toastEl = document.getElementById('toast');

let toastTimer;
function toast(msg, type = '') {
    toastEl.textContent = msg;
    toastEl.className = `toast show ${type}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2400);
}

// ---- Presets ----
function fillPresets(presets) {
    presetEl.innerHTML = '<option value="">— Preset —</option>';
    (presets || []).forEach(p => {
        const o = document.createElement('option');
        o.value = p.model; o.textContent = p.label;
        presetEl.appendChild(o);
    });
}
presetEl.addEventListener('change', () => {
    if (presetEl.value) modelEl.value = presetEl.value;
});

// ---- Liste des props ----
function renderList(props) {
    listEl.innerHTML = '';
    props = props || [];
    countEl.textContent = `Props posés (${props.length})`;
    props.forEach(p => {
        const div = document.createElement('div');
        div.className = 'item';
        div.innerHTML = `
            <div class="top">
                <input class="name-input" value="${(p.label || '').replace(/"/g, '&quot;')}">
            </div>
            <div class="meta">${p.model} — ${p.x.toFixed(1)}, ${p.y.toFixed(1)}, ${p.z.toFixed(1)} (${Math.round(p.h)}°)</div>
            <div class="acts">
                <button class="save">Renommer</button>
                <button class="tp">TP</button>
                <button class="del">Suppr.</button>
            </div>
        `;
        const input = div.querySelector('.name-input');
        div.querySelector('.save').addEventListener('click', () => {
            const label = input.value.trim();
            if (!label) { toast('Nom vide', 'err'); return; }
            nui('rename', { id: p.id, label });
            toast('Renommé', 'ok');
        });
        div.querySelector('.tp').addEventListener('click', () => nui('teleport', { id: p.id }));
        div.querySelector('.del').addEventListener('click', () => {
            nui('delete', { id: p.id });
            toast('Supprimé');
        });
        listEl.appendChild(div);
    });
}

// ---- Placer ----
document.getElementById('place').addEventListener('click', async () => {
    const model = (modelEl.value || '').trim();
    if (!model) { toast('Entre un modèle de prop', 'err'); return; }
    const label = nameEl.value.trim() || 'Prop';
    const res = await nui('startPlace', { model, label });
    if (res && res.ok) {
        nameEl.value = '';
        // l'UI va se cacher (message 'hide') puis revenir (message 'show')
    } else {
        toast('Impossible de démarrer le placement', 'err');
    }
});

document.getElementById('close').addEventListener('click', () => { nui('close'); appEl.classList.add('hidden'); });
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !appEl.classList.contains('hidden') && !appEl.classList.contains('dim')) {
        nui('close'); appEl.classList.add('hidden');
    }
});

// ---- Messages Lua -> UI ----
window.addEventListener('message', e => {
    const d = e.data;
    switch (d.action) {
        case 'open':
            fillPresets(d.presets);
            renderList(d.props);
            appEl.classList.remove('hidden', 'dim');
            break;
        case 'list':
            renderList(d.props);
            break;
        case 'hide':       // pendant le placement en jeu
            appEl.classList.add('dim');
            break;
        case 'show':       // placement terminé
            appEl.classList.remove('dim');
            if (d.props) renderList(d.props);
            break;
        case 'error':
            toast(d.msg || 'Erreur', 'err');
            break;
        case 'close':
            appEl.classList.add('hidden');
            break;
    }
});
