/* =============================================
   RZ JOB CREATOR  —  app.js  v1.0
   Generateur de config jobs (standalone, JSON)
   ============================================= */
'use strict';

const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName() : 'rz_jobcreator';

function nui(action, data = {}) {
    return fetch(`https://${RESOURCE_NAME}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

// ---------- Toast ----------
const toastEl = document.getElementById('toast');
let toastTimer;
function toast(msg, type = '') {
    toastEl.textContent = msg;
    toastEl.className = `toast show ${type}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2500);
}

// ---------- Etat ----------
let jobs        = {};      // tous les jobs (cote serveur)
let currentName = null;    // nom interne du job edite
let currentJob  = null;    // objet en cours d'edition
let blipSprites = [];
let blipColors  = [];

const appEl    = document.getElementById('app');
const emptyEl  = document.getElementById('empty-state');
const innerEl  = document.getElementById('editor-inner');

// ---------- Modele vide ----------
function emptyJob() {
    return { label: '', grades: [], vehicleSpawns: [], blips: [], stashes: [], wardrobes: [], boss: null };
}

// Convertit la map grades du serveur -> tableau ordonne
function gradesMapToArray(map) {
    if (Array.isArray(map)) return map;
    if (!map || typeof map !== 'object') return [];
    return Object.keys(map)
        .sort((a, b) => Number(a) - Number(b))
        .map(k => ({
            name:   map[k].name   || 'Grade',
            salary: map[k].salary || 0,
            isBoss: map[k].isBoss === true,
        }));
}
// Tableau -> map { "0": {...}, "1": {...} }
function gradesArrayToMap(arr) {
    const m = {};
    arr.forEach((g, i) => { m[String(i)] = { name: g.name, salary: Number(g.salary) || 0, isBoss: !!g.isBoss }; });
    return m;
}

// =============================================
//  LISTE DES JOBS (sidebar)
// =============================================
const jobListEl = document.getElementById('job-list');

function renderJobList() {
    jobListEl.innerHTML = '';
    const names = Object.keys(jobs).sort();
    names.forEach(name => {
        const div = document.createElement('div');
        div.className = 'job-item' + (name === currentName ? ' active' : '');
        div.innerHTML = `<div class="ji-label">${jobs[name].label || name}</div><div class="ji-name">${name}</div>`;
        div.addEventListener('click', () => selectJob(name));
        jobListEl.appendChild(div);
    });
}

function selectJob(name) {
    currentName = name;
    const src = jobs[name] || {};
    currentJob = {
        label:         src.label || '',
        grades:        gradesMapToArray(src.grades),
        vehicleSpawns: Array.isArray(src.vehicleSpawns) ? JSON.parse(JSON.stringify(src.vehicleSpawns)) : [],
        blips:         Array.isArray(src.blips)         ? JSON.parse(JSON.stringify(src.blips))         : [],
        stashes:       Array.isArray(src.stashes)       ? JSON.parse(JSON.stringify(src.stashes))       : [],
        wardrobes:     Array.isArray(src.wardrobes)     ? JSON.parse(JSON.stringify(src.wardrobes))     : [],
        boss:          src.boss ? JSON.parse(JSON.stringify(src.boss)) : null,
    };
    document.getElementById('job-name').value = name;
    document.getElementById('job-name').disabled = true; // on ne renomme pas une cle existante
    showEditor();
}

function newJob() {
    currentName = null;
    currentJob = emptyJob();
    document.getElementById('job-name').value = '';
    document.getElementById('job-name').disabled = false;
    showEditor();
    renderJobList();
    document.getElementById('job-name').focus();
}

function showEditor() {
    emptyEl.classList.add('hidden');
    innerEl.classList.remove('hidden');
    document.getElementById('job-label').value = currentJob.label || '';
    renderAll();
    renderJobList();
}

// =============================================
//  CAPTURE DE POSITION
// =============================================
async function capture() {
    const c = await nui('getCoords');
    if (!c) { toast('Position indisponible', 'err'); return null; }
    return c;
}
function fmtCoords(c) {
    if (!c) return '—';
    const h = (c.h !== undefined) ? ` (${c.h}°)` : '';
    return `${c.x}, ${c.y}, ${c.z}${h}`;
}

// =============================================
//  RENDU DES SECTIONS
// =============================================
function renderAll() {
    renderGrades();
    renderVehicles();
    renderBlips();
    renderBoss();
    renderStashes();
    renderWardrobes();
}

// helper : bouton supprimer
function delBtn(onClick) {
    const b = document.createElement('button');
    b.className = 'del'; b.textContent = '×';
    b.addEventListener('click', onClick);
    return b;
}

// ---- Grades ----
function renderGrades() {
    const wrap = document.getElementById('list-grades');
    wrap.innerHTML = '';
    currentJob.grades.forEach((g, i) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
            <span class="tag">Grade ${i}</span>
            <input type="text" class="grow" value="${g.name ?? ''}" placeholder="Nom du grade">
            <input type="number" style="width:90px" value="${g.salary ?? 0}" placeholder="Salaire">
            <label class="chk"><input type="checkbox" ${g.isBoss ? 'checked' : ''}> Patron</label>
        `;
        const [nameI, salI] = row.querySelectorAll('input[type="text"], input[type="number"]');
        const chk = row.querySelector('input[type="checkbox"]');
        nameI.addEventListener('input', e => g.name = e.target.value);
        salI.addEventListener('input', e => g.salary = Number(e.target.value) || 0);
        chk.addEventListener('change', e => g.isBoss = e.target.checked);
        row.appendChild(delBtn(() => { currentJob.grades.splice(i, 1); renderGrades(); }));
        wrap.appendChild(row);
    });
}

// ---- Vehicules ----
function renderVehicles() {
    const wrap = document.getElementById('list-vehicles');
    wrap.innerHTML = '';
    currentJob.vehicleSpawns.forEach((s, i) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
            <input type="text" class="grow" value="${s.label ?? ''}" placeholder="Nom du spawn">
            <span class="coords">${fmtCoords(s.coords)}</span>
            <input type="text" class="grow" value="${(s.vehicles || []).join(', ')}" placeholder="modeles: police, police2">
        `;
        const [labelI, vehI] = row.querySelectorAll('input[type="text"]');
        labelI.addEventListener('input', e => s.label = e.target.value);
        vehI.addEventListener('input', e => s.vehicles = e.target.value.split(',').map(v => v.trim()).filter(Boolean));
        row.appendChild(delBtn(() => { currentJob.vehicleSpawns.splice(i, 1); renderVehicles(); }));
        wrap.appendChild(row);
    });
}

// ---- Blips ----
function spriteOptions(sel) {
    return blipSprites.map(s => `<option value="${s.id}" ${s.id === sel ? 'selected' : ''}>${s.label} (${s.id})</option>`).join('');
}
function colorOptions(sel) {
    return blipColors.map(c => `<option value="${c.id}" ${c.id === sel ? 'selected' : ''}>${c.label} (${c.id})</option>`).join('');
}
function renderBlips() {
    const wrap = document.getElementById('list-blips');
    wrap.innerHTML = '';
    currentJob.blips.forEach((b, i) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
            <input type="text" class="grow" value="${b.label ?? ''}" placeholder="Nom du blip">
            <span class="coords">${fmtCoords(b.coords)}</span>
            <select title="Sprite">${spriteOptions(b.sprite)}</select>
            <select title="Couleur">${colorOptions(b.color)}</select>
            <input type="number" step="0.1" style="width:64px" value="${b.scale ?? 0.8}" title="Échelle">
        `;
        const labelI = row.querySelector('input[type="text"]');
        const [spriteS, colorS] = row.querySelectorAll('select');
        const scaleI = row.querySelector('input[type="number"]');
        labelI.addEventListener('input', e => b.label = e.target.value);
        spriteS.addEventListener('change', e => b.sprite = Number(e.target.value));
        colorS.addEventListener('change', e => b.color = Number(e.target.value));
        scaleI.addEventListener('input', e => b.scale = Number(e.target.value) || 0.8);
        row.appendChild(delBtn(() => { currentJob.blips.splice(i, 1); renderBlips(); }));
        wrap.appendChild(row);
    });
}

// ---- Boss (point unique) ----
function renderBoss() {
    const wrap = document.getElementById('list-boss');
    wrap.innerHTML = '';
    if (!currentJob.boss) return;
    const b = currentJob.boss;
    const row = document.createElement('div');
    row.className = 'row';
    row.innerHTML = `
        <input type="text" class="grow" value="${b.label ?? 'Boss'}" placeholder="Libellé">
        <span class="coords">${fmtCoords(b.coords)}</span>
    `;
    row.querySelector('input').addEventListener('input', e => b.label = e.target.value);
    row.appendChild(delBtn(() => { currentJob.boss = null; renderBoss(); }));
    wrap.appendChild(row);
}

// ---- Stash ----
function renderStashes() {
    const wrap = document.getElementById('list-stashes');
    wrap.innerHTML = '';
    currentJob.stashes.forEach((s, i) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
            <input type="text" class="grow" value="${s.label ?? ''}" placeholder="Nom du coffre">
            <span class="coords">${fmtCoords(s.coords)}</span>
            <input type="number" style="width:70px" value="${s.slots ?? 50}" title="Slots">
            <input type="number" style="width:90px" value="${s.weight ?? 100000}" title="Poids max (g)">
        `;
        const labelI = row.querySelector('input[type="text"]');
        const [slotsI, weightI] = row.querySelectorAll('input[type="number"]');
        labelI.addEventListener('input', e => s.label = e.target.value);
        slotsI.addEventListener('input', e => s.slots = Number(e.target.value) || 0);
        weightI.addEventListener('input', e => s.weight = Number(e.target.value) || 0);
        row.appendChild(delBtn(() => { currentJob.stashes.splice(i, 1); renderStashes(); }));
        wrap.appendChild(row);
    });
}

// ---- Vestiaire ----
function renderWardrobes() {
    const wrap = document.getElementById('list-wardrobes');
    wrap.innerHTML = '';
    currentJob.wardrobes.forEach((w, i) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
            <input type="text" class="grow" value="${w.label ?? ''}" placeholder="Nom du vestiaire">
            <span class="coords">${fmtCoords(w.coords)}</span>
        `;
        row.querySelector('input').addEventListener('input', e => w.label = e.target.value);
        row.appendChild(delBtn(() => { currentJob.wardrobes.splice(i, 1); renderWardrobes(); }));
        wrap.appendChild(row);
    });
}

// =============================================
//  AJOUTS (boutons + data-add)
// =============================================
document.querySelectorAll('.add-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
        if (!currentJob) return;
        const type = btn.dataset.add;

        if (type === 'grade') {
            currentJob.grades.push({ name: 'Grade ' + currentJob.grades.length, salary: 0, isBoss: false });
            renderGrades();
            return;
        }

        // Les autres capturent la position du joueur
        const c = await capture();
        if (!c) return;

        switch (type) {
            case 'vehicle':
                currentJob.vehicleSpawns.push({ label: 'Spawn', coords: c, vehicles: [] });
                renderVehicles(); break;
            case 'blip':
                currentJob.blips.push({ label: 'Blip', coords: c, sprite: 1, color: 0, scale: 0.8 });
                renderBlips(); break;
            case 'stash':
                currentJob.stashes.push({ label: 'Coffre', coords: c, slots: 50, weight: 100000 });
                renderStashes(); break;
            case 'wardrobe':
                currentJob.wardrobes.push({ label: 'Vestiaire', coords: c });
                renderWardrobes(); break;
            case 'boss':
                currentJob.boss = { label: 'Boss', coords: c };
                renderBoss(); break;
        }
        toast('Position capturée', 'ok');
    });
});

// =============================================
//  ENREGISTRER / EXPORTER / SUPPRIMER / APERCU
// =============================================
function buildPayloadJob() {
    return {
        label:         document.getElementById('job-label').value || '',
        grades:        gradesArrayToMap(currentJob.grades),
        vehicleSpawns: currentJob.vehicleSpawns,
        blips:         currentJob.blips,
        stashes:       currentJob.stashes,
        wardrobes:     currentJob.wardrobes,
        boss:          currentJob.boss,
    };
}

document.getElementById('btn-save').addEventListener('click', async () => {
    if (!currentJob) return;
    const name = (document.getElementById('job-name').value || '').trim().toLowerCase();
    if (!/^[a-z0-9_]+$/.test(name)) { toast('Nom interne invalide (a-z, 0-9, _)', 'err'); return; }
    currentJob.label = document.getElementById('job-label').value || '';
    const res = await nui('save', { name, job: buildPayloadJob() });
    if (res && res.ok) currentName = name;
});

document.getElementById('btn-delete').addEventListener('click', async () => {
    if (!currentName) { toast('Ce job n\'est pas encore enregistré', 'err'); return; }
    await nui('delete', { name: currentName });
});

document.getElementById('btn-export').addEventListener('click', () => {
    if (!currentJob) return;
    const name = (document.getElementById('job-name').value || 'job').trim().toLowerCase() || 'job';
    const out = {}; out[name] = buildPayloadJob();
    document.getElementById('export-name').textContent = name;
    document.getElementById('export-text').value = JSON.stringify(out, null, 4);
    document.getElementById('export-overlay').classList.remove('hidden');
});
document.getElementById('export-close').addEventListener('click', () =>
    document.getElementById('export-overlay').classList.add('hidden'));
document.getElementById('export-copy').addEventListener('click', async () => {
    const txt = document.getElementById('export-text');
    try { await navigator.clipboard.writeText(txt.value); toast('Copié', 'ok'); }
    catch (e) { txt.focus(); txt.select(); try { document.execCommand('copy'); toast('Copié', 'ok'); } catch (e2) { toast('Copie impossible', 'err'); } }
});

document.getElementById('btn-preview').addEventListener('click', () => {
    if (!currentJob) return;
    nui('previewBlips', { blips: currentJob.blips });
    toast(`${currentJob.blips.length} blip(s) affiché(s) sur la map`, 'ok');
});

// Boutons globaux
document.getElementById('new-job').addEventListener('click', newJob);
document.getElementById('close-btn').addEventListener('click', () => { nui('close'); appEl.classList.add('hidden'); });
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !appEl.classList.contains('hidden')) { nui('close'); appEl.classList.add('hidden'); }
});

// =============================================
//  MESSAGES LUA -> UI
// =============================================
window.addEventListener('message', e => {
    const d = e.data;
    switch (d.action) {
        case 'open':
            if (d.resource) { /* RESOURCE_NAME deja resolu via GetParentResourceName */ }
            blipSprites = d.blipSprites || [];
            blipColors  = d.blipColors  || [];
            appEl.classList.remove('hidden');
            // reset vue
            currentName = null; currentJob = null;
            emptyEl.classList.remove('hidden');
            innerEl.classList.add('hidden');
            document.getElementById('export-overlay').classList.add('hidden');
            break;

        case 'jobsList':
            jobs = d.jobs || {};
            renderJobList();
            break;

        case 'saved':
            toast(`Job "${d.name}" enregistré`, 'ok');
            break;

        case 'deleted':
            toast(`Job "${d.name}" supprimé`, '');
            if (currentName === d.name) {
                currentName = null; currentJob = null;
                emptyEl.classList.remove('hidden');
                innerEl.classList.add('hidden');
            }
            break;

        case 'error':
            toast(d.msg || 'Erreur', 'err');
            break;

        case 'close':
            appEl.classList.add('hidden');
            break;
    }
});
