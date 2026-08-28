/* =============================================
   RZ VIP — app.js
   Rendu 100 % piloté par l'état envoyé du serveur.
   ============================================= */
'use strict';

const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName() : 'rz_vip';

function nui(action, data = {}) {
    return fetch(`https://${RESOURCE_NAME}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

const appEl = document.getElementById('app');

// ── Toast ─────────────────────────────────────────────────
const toastEl = document.getElementById('toast');
let toastTimer;
function toast(msg, type = 'ok') {
    toastEl.textContent = msg;
    toastEl.className = `toast show ${type}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2800);
}

// ── Helpers ───────────────────────────────────────────────
const fmt$  = n => (n || 0).toLocaleString('fr-CA') + ' $';
function fmtDur(sec) {
    sec = Math.max(0, Math.round(sec));
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
    if (h > 0) return `${h}h${String(m).padStart(2, '0')}`;
    if (m > 0) return `${m} min`;
    return `${sec} s`;
}

// ── État ──────────────────────────────────────────────────
let S = null; // state complet du serveur

function tierById(id) { return (S.tiers || []).find(t => t.id === id) || null; }
function matDef(item) { return (S.matDefs || []).find(m => m.item === item); }

// Description des avantages d'un palier (pour cartes + comparaison)
function perkList(t) {
    const perks = ['👔 Vestiaire — change de ped n\'importe où'];
    if (t.pedSlots > 0) perks.push(`🎭 Choix de ${t.pedSlots} ped${t.pedSlots > 1 ? 's' : ''}`);
    if (t.freeReviveHours) perks.push(`💉 Réanimation instantanée / ${t.freeReviveHours} h`);
    if (t.craft) {
        if (t.craft.quota) perks.push(`⚗️ ${t.craft.quota} réanimations craftables / ${t.craft.windowHours} h`);
        else perks.push(`⚗️ Réanimations craftables (stock ${t.craft.max}, verrou ${t.craft.lockHours} h après épuisement)`);
    }
    return perks;
}

// ═══════════════════════════════════════════════════════════
//  ONGLETS
// ═══════════════════════════════════════════════════════════

document.getElementById('h-nav').addEventListener('click', e => {
    const btn = e.target.closest('.hn-btn');
    if (!btn) return;
    document.querySelectorAll('.hn-btn').forEach(b => b.classList.toggle('active', b === btn));
    document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.id === 'tab-' + btn.dataset.tab));
});

// ═══════════════════════════════════════════════════════════
//  BOUTIQUE VIP
// ═══════════════════════════════════════════════════════════

function renderStore() {
    const wrap = document.getElementById('tab-store');
    const cur = tierById(S.tier);

    let html = `
        <div class="hero">
            <div class="hero-title">DEVIENS <span>VIP</span></div>
            <div class="hero-sub">${cur
                ? `Tu es <b style="color:${cur.color2}">${cur.label}</b> — compare avec les grades supérieurs`
                : 'Choisis ton grade et débloque tes avantages immédiatement'}</div>
        </div>
        <div class="tier-grid">`;

    (S.tiers || []).forEach(t => {
        const owned    = S.tier === t.id;
        const lower    = S.tier > t.id;
        const isUp     = S.tier > 0 && t.id > S.tier;
        let price      = t.price;
        if (isUp && S.upgradeDiff && cur) price = Math.max(0, t.price - cur.price);

        const bg = t.img
            ? `background-image:linear-gradient(160deg, ${t.color1}dd, ${t.color2}55), url('${t.img}');background-size:cover;background-position:center;`
            : `background-image:linear-gradient(160deg, ${t.color1}, ${t.color2}44);`;

        html += `
        <div class="tier-card ${owned ? 'owned' : ''} ${lower ? 'lower' : ''}" style="${bg}">
            ${t.badge ? `<div class="tc-badge">${t.badge}</div>` : ''}
            ${owned ? '<div class="tc-owned">✓ TON GRADE</div>' : ''}
            <div class="tc-emoji">${t.emoji || '✦'}</div>
            <div class="tc-name">${t.label}</div>
            <div class="tc-tagline">${t.tagline || ''}</div>
            <ul class="tc-perks">${perkList(t).map(p => `<li>${p}</li>`).join('')}</ul>
            <div class="tc-bottom">
                <div class="tc-price">${owned ? '—' : fmt$(price)}${isUp && S.upgradeDiff ? '<span class="tc-diff">upgrade</span>' : ''}</div>
                <button class="tc-buy" data-id="${t.id}" ${owned || lower ? 'disabled' : ''}>
                    ${owned ? 'Actif' : lower ? 'Inférieur' : isUp ? '⬆ Upgrader' : 'Acheter'}
                </button>
            </div>
        </div>`;
    });
    html += '</div>';

    wrap.innerHTML = html;
    wrap.querySelectorAll('.tc-buy:not([disabled])').forEach(btn => {
        btn.addEventListener('click', () => {
            const t = tierById(parseInt(btn.dataset.id));
            if (confirm(`Acheter ${t.label} ?\nLe montant sera débité de ton compte ${S.payAccount}.`)) {
                nui('buyTier', { id: t.id });
            }
        });
    });
}

// ═══════════════════════════════════════════════════════════
//  MES PEDS (choix des slots)
// ═══════════════════════════════════════════════════════════

function renderPeds() {
    const wrap = document.getElementById('tab-peds');
    const slots = S.pedSlots || 0;
    const owned = S.ownedPeds || [];

    if (slots === 0) {
        wrap.innerHTML = `<div class="locked">
            <div class="locked-icon">🔒</div>
            <div class="locked-title">Choix de ped verrouillé</div>
            <div class="locked-sub">Disponible à partir du grade <b>VIP Familiale</b> — passe par la Boutique VIP</div>
        </div>`;
        return;
    }

    let html = `
        <div class="section-head">
            <div class="sh-title">TES SLOTS DE PED <span class="sh-count">${owned.length} / ${slots}</span></div>
            <div class="sh-sub">Choisis tes peds ci-dessous — ils rejoignent ton vestiaire pour toujours</div>
        </div>
        <div class="ped-grid">`;

    (S.peds || []).forEach(p => {
        const isOwned = owned.includes(p.model);
        const full = owned.length >= slots;
        html += `
        <div class="ped-card ${isOwned ? 'owned' : ''}">
            <div class="pc-emoji">${p.emoji || '🎭'}</div>
            <div class="pc-name">${p.label}</div>
            <div class="pc-model">${p.model}</div>
            ${p.price > 0 ? `<div class="pc-premium">PREMIUM · ${fmt$(p.price)}</div>` : '<div class="pc-included">Inclus avec ton grade</div>'}
            <button class="pc-btn" data-model="${p.model}" ${isOwned || full ? 'disabled' : ''}>
                ${isOwned ? '✓ Possédé' : full ? 'Slots pleins' : p.price > 0 ? `Acheter · ${fmt$(p.price)}` : '+ Choisir'}
            </button>
        </div>`;
    });
    html += '</div>';
    wrap.innerHTML = html;

    wrap.querySelectorAll('.pc-btn:not([disabled])').forEach(btn => {
        btn.addEventListener('click', () => nui('choosePed', { model: btn.dataset.model }));
    });
}

// ═══════════════════════════════════════════════════════════
//  VESTIAIRE (appliquer un ped n'importe où)
// ═══════════════════════════════════════════════════════════

function renderWardrobe() {
    const wrap = document.getElementById('tab-wardrobe');

    if (S.tier === 0) {
        wrap.innerHTML = `<div class="locked">
            <div class="locked-icon">🔒</div>
            <div class="locked-title">Vestiaire réservé aux VIP</div>
            <div class="locked-sub">Tous les grades VIP incluent le vestiaire — commence avec <b>VIP Classique</b></div>
        </div>`;
        return;
    }

    const owned = S.ownedPeds || [];
    let html = `
        <div class="section-head">
            <div class="sh-title">VESTIAIRE</div>
            <div class="sh-sub">Change de ped n'importe où, n'importe quand</div>
        </div>
        <div class="ped-grid">
            <div class="ped-card">
                <div class="pc-emoji">🧍</div>
                <div class="pc-name">Ped d'origine</div>
                <div class="pc-model">retour à ton skin</div>
                <button class="pc-btn" id="btn-reset-ped">↩ Restaurer</button>
            </div>`;

    owned.forEach(model => {
        const p = (S.peds || []).find(x => x.model === model) || { label: model, emoji: '🎭' };
        html += `
        <div class="ped-card">
            <div class="pc-emoji">${p.emoji || '🎭'}</div>
            <div class="pc-name">${p.label}</div>
            <div class="pc-model">${model}</div>
            <button class="pc-btn apply" data-model="${model}">👔 Enfiler</button>
        </div>`;
    });
    html += '</div>';
    if (!owned.length) {
        html += '<div class="sh-sub" style="margin-top:14px">Tu n\'as pas encore choisi de ped — va dans l\'onglet <b>Mes Peds</b>.</div>';
    }
    wrap.innerHTML = html;

    wrap.querySelectorAll('.pc-btn.apply').forEach(btn => {
        btn.addEventListener('click', () => nui('applyPed', { model: btn.dataset.model }));
    });
    const reset = document.getElementById('btn-reset-ped');
    if (reset) reset.addEventListener('click', () => { nui('resetPed'); toast('Ped d\'origine restauré', 'ok'); });
}

// ═══════════════════════════════════════════════════════════
//  RÉANIMATION
// ═══════════════════════════════════════════════════════════

function costHtml(cost) {
    return Object.entries(cost || {}).map(([item, qty]) => {
        const d = matDef(item) || { label: item, emoji: '▪' };
        const have = (S.materials || {})[item] || 0;
        const ok = have >= qty;
        return `<span class="cost ${ok ? 'ok' : 'ko'}">${d.emoji} ${qty} ${d.label} <i>(${have})</i></span>`;
    }).join('');
}

function renderRevive() {
    const wrap = document.getElementById('tab-revive');
    const r = S.revive || { mode: 'none' };

    if (r.mode === 'none') {
        wrap.innerHTML = `<div class="locked">
            <div class="locked-icon">💉</div>
            <div class="locked-title">Réanimations réservées aux VIP</div>
            <div class="locked-sub">Chaque grade a son propre système — regarde la Boutique VIP</div>
        </div>`;
        return;
    }

    let html = `<div class="section-head"><div class="sh-title">RÉANIMATION INSTANTANÉE</div></div>`;

    if (r.mode === 'free') {
        const ready = r.readyIn <= 0;
        html += `
        <div class="rev-card">
            <div class="rev-big">${ready ? '✅ DISPONIBLE' : '⏳ ' + fmtDur(r.readyIn)}</div>
            <div class="rev-sub">Réanimation gratuite toutes les <b>${r.cooldownHours} h</b> (grade ${tierById(S.tier)?.label || ''})</div>
            <button class="rev-btn" id="btn-free-revive" ${ready ? '' : 'disabled'}>💉 Me réanimer maintenant</button>
        </div>`;
    } else {
        const locked = r.mode === 'craft' && r.lockRemain > 0;
        html += `
        <div class="rev-card">
            <div class="rev-big">🧪 ${r.kits} / ${r.max} kit(s) en stock</div>
            ${r.mode === 'craft'
                ? `<div class="rev-sub">Une fois tes ${r.max} kits utilisés, crafting verrouillé <b>${r.lockHours} h</b>${locked ? ` — déverrouillage dans <b>${fmtDur(r.lockRemain)}</b>` : ''}</div>`
                : `<div class="rev-sub">Quota : <b>${r.quotaLeft}</b> craft(s) restant(s) sur cette fenêtre de ${r.windowHours} h${r.windowResetIn > 0 ? ` — reset dans <b>${fmtDur(r.windowResetIn)}</b>` : ''}</div>`}
            <div class="rev-cost">Coût du craft : ${costHtml(r.craftCost)}</div>
            <div class="rev-actions">
                <button class="rev-btn secondary" id="btn-craft" ${locked || r.kits >= r.max || (r.mode === 'quota' && r.quotaLeft <= 0) ? 'disabled' : ''}>⚗️ Crafter un kit</button>
                <button class="rev-btn" id="btn-use-kit" ${r.kits > 0 ? '' : 'disabled'}>💉 Utiliser un kit</button>
            </div>
        </div>`;
    }

    wrap.innerHTML = html;
    const free = document.getElementById('btn-free-revive');
    if (free) free.addEventListener('click', () => nui('useFreeRevive'));
    const craft = document.getElementById('btn-craft');
    if (craft) craft.addEventListener('click', () => nui('craftKit'));
    const use = document.getElementById('btn-use-kit');
    if (use) use.addEventListener('click', () => nui('useKit'));
}

// ═══════════════════════════════════════════════════════════
//  BOUTIQUE MATÉRIAUX
// ═══════════════════════════════════════════════════════════

function renderShop() {
    const wrap = document.getElementById('tab-shop');

    // Bandeau des matériaux possédés + rappel des points de farm
    let html = `<div class="mat-bar">`;
    (S.matDefs || []).forEach(m => {
        html += `<div class="mat-chip">${m.emoji} <b>${(S.materials || {})[m.item] || 0}</b> ${m.label}</div>`;
    });
    html += `</div>
        <div class="sh-sub" style="margin-bottom:14px">Farm tes matériaux en ville : ${(S.farmSpots || []).map(f => f.label).join(' · ')}</div>`;

    // Groupé par catégorie
    const cats = [...new Set((S.shop || []).map(s => s.cat))];
    cats.forEach(cat => {
        html += `<div class="cat-title">${cat.toUpperCase()}</div><div class="shop-grid">`;
        (S.shop || []).filter(s => s.cat === cat).forEach(s => {
            const affordable = Object.entries(s.cost).every(([item, qty]) => ((S.materials || {})[item] || 0) >= qty);
            html += `
            <div class="shop-card">
                <div class="sp-top"><span class="sp-emoji">${s.emoji}</span><span class="sp-name">${s.label}</span></div>
                <div class="sp-cost">${costHtml(s.cost)}</div>
                <button class="sp-btn" data-id="${s.id}" ${affordable ? '' : 'disabled'}>
                    ${affordable ? '🛒 Acheter' : 'Matériaux insuffisants'}
                </button>
            </div>`;
        });
        html += '</div>';
    });

    wrap.innerHTML = html;
    wrap.querySelectorAll('.sp-btn:not([disabled])').forEach(btn => {
        btn.addEventListener('click', () => nui('buyShopItem', { id: btn.dataset.id }));
    });
}

// ═══════════════════════════════════════════════════════════
//  RENDU GLOBAL
// ═══════════════════════════════════════════════════════════

function renderAll() {
    if (!S) return;
    const cur = tierById(S.tier);
    const ht = document.getElementById('h-tier');
    ht.textContent = cur ? `${cur.emoji} ${cur.label}` : 'Aucun VIP';
    ht.style.color = cur ? cur.color2 : '';
    document.getElementById('h-money').textContent = fmt$(S.money);

    renderStore();
    renderPeds();
    renderWardrobe();
    renderRevive();
    renderShop();
}

// ═══════════════════════════════════════════════════════════
//  MESSAGES LUA → UI
// ═══════════════════════════════════════════════════════════

window.addEventListener('message', e => {
    const d = e.data;
    switch (d.action) {
        case 'open':
            S = d.state;
            appEl.classList.remove('hidden');
            renderAll();
            break;
        case 'state':
            S = d.state;
            renderAll();
            break;
        case 'result': {
            const r = d.data || {};
            toast(r.msg || (r.ok ? 'OK' : 'Erreur'), r.ok ? 'ok' : 'err');
            break;
        }
        case 'close':
            appEl.classList.add('hidden');
            break;
    }
});

document.getElementById('btn-close').addEventListener('click', () => {
    nui('close');
    appEl.classList.add('hidden');
});
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !appEl.classList.contains('hidden')) {
        nui('close');
        appEl.classList.add('hidden');
    }
});
