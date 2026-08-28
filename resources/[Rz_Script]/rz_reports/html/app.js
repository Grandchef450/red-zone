/* =============================================
   RZ REPORTS — app.js v1.0
   ============================================= */
'use strict';
const RESOURCE_NAME = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'rz_reports';
function nui(a, d = {}) {
    return fetch(`https://${RESOURCE_NAME}/${a}`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(d) }).then(r=>r.json()).catch(()=>null);
}

const appEl=document.getElementById('app'), toastEl=document.getElementById('toast');
let toastTimer;
function toast(msg,type=''){toastEl.textContent=msg;toastEl.className=`toast show ${type}`;clearTimeout(toastTimer);toastTimer=setTimeout(()=>toastEl.classList.remove('show'),2600);}

let amStaff=false, reports=[], currentId=null, filter='all';

const newReportEl=document.getElementById('new-report');
const filtersEl=document.getElementById('filters');
const listEl=document.getElementById('list');
const detailEmpty=document.getElementById('detail-empty');
const detailEl=document.getElementById('detail');
const threadEl=document.getElementById('thread');

// ---- Role UI ----
function applyRole(){
    const badge=document.getElementById('role-badge');
    if(amStaff){ badge.textContent='STAFF'; badge.className='badge staff';
        newReportEl.classList.add('hidden'); filtersEl.classList.remove('hidden');
    } else { badge.textContent='JOUEUR'; badge.className='badge';
        newReportEl.classList.remove('hidden'); filtersEl.classList.add('hidden');
    }
}

// ---- Liste ----
function statusLabel(s){return s==='open'?'Ouvert':s==='claimed'?'Pris en charge':'Fermé';}
function renderList(){
    listEl.innerHTML='';
    let arr=reports.slice().sort((a,b)=>b.id-a.id);
    if(amStaff && filter!=='all') arr=arr.filter(r=>r.status===filter);
    arr.forEach(r=>{
        const last=r.messages&&r.messages.length?r.messages[r.messages.length-1].text:'';
        const div=document.createElement('div');
        div.className=`r-item ${r.status}`+(r.id===currentId?' active':'');
        div.innerHTML=`<div class="ri-top"><span>#${r.id} ${amStaff?r.name:''}</span><span class="ri-cat">${r.category}</span></div>
                       <div class="ri-prev">${last}</div>`;
        div.addEventListener('click',()=>selectReport(r.id));
        listEl.appendChild(div);
    });
}

// ---- Detail ----
function selectReport(id){ currentId=id; renderDetail(); renderList(); }
function renderDetail(){
    const r=reports.find(x=>x.id===currentId);
    if(!r){ detailEl.classList.add('hidden'); detailEmpty.classList.remove('hidden'); return; }
    detailEmpty.classList.add('hidden'); detailEl.classList.remove('hidden');
    document.getElementById('d-title').textContent=`#${r.id} — ${r.category}`;
    document.getElementById('d-sub').textContent=
        `${r.name} · ${statusLabel(r.status)}`+(r.claimedBy?` · pris par ${r.claimedBy}`:'');
    // actions
    const act=document.getElementById('d-actions'); act.innerHTML='';
    if(amStaff){
        if(r.status!=='closed'){
            if(r.status==='open'){ const b=document.createElement('button'); b.className='claim'; b.textContent='Prendre'; b.onclick=()=>nui('claim',{id:r.id}); act.appendChild(b); }
            const tp=document.createElement('button'); tp.className='tp'; tp.textContent='TP'; tp.onclick=()=>nui('goto',{id:r.id}); act.appendChild(tp);
            const cl=document.createElement('button'); cl.className='close-r'; cl.textContent='Fermer'; cl.onclick=()=>nui('closeReport',{id:r.id}); act.appendChild(cl);
        }
        const del=document.createElement('button'); del.className='del'; del.textContent='Suppr.'; del.onclick=()=>{nui('deleteReport',{id:r.id});currentId=null;renderDetail();}; act.appendChild(del);
    }
    // thread
    threadEl.innerHTML='';
    (r.messages||[]).forEach(m=>{
        const div=document.createElement('div'); div.className=`msg ${m.from}`;
        div.innerHTML=`<div class="m-name">${m.name||(m.from==='staff'?'Staff':'Joueur')}</div>${m.text}`;
        threadEl.appendChild(div);
    });
    threadEl.scrollTop=threadEl.scrollHeight;
    // reply bar : desactivee si fermé
    document.getElementById('reply-input').disabled = (r.status==='closed');
    document.getElementById('reply-send').disabled = (r.status==='closed');
}

// ---- Envois ----
document.getElementById('nr-send').addEventListener('click',()=>{
    const msg=document.getElementById('nr-msg').value.trim();
    if(msg.length<2){toast('Message trop court','err');return;}
    nui('submit',{category:document.getElementById('nr-cat').value, message:msg});
    document.getElementById('nr-msg').value='';
    toast('Report envoyé','ok');
});
function sendReply(){
    const r=reports.find(x=>x.id===currentId); if(!r) return;
    const input=document.getElementById('reply-input');
    const text=input.value.trim(); if(!text) return;
    if(amStaff) nui('message',{id:r.id,text}); else nui('reply',{id:r.id,text});
    input.value='';
}
document.getElementById('reply-send').addEventListener('click',sendReply);
document.getElementById('reply-input').addEventListener('keydown',e=>{if(e.key==='Enter')sendReply();});

document.querySelectorAll('.f-btn').forEach(b=>b.addEventListener('click',()=>{
    document.querySelectorAll('.f-btn').forEach(x=>x.classList.remove('active'));
    b.classList.add('active'); filter=b.dataset.f; renderList();
}));

document.getElementById('close').addEventListener('click',()=>{nui('close');appEl.classList.add('hidden');});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!appEl.classList.contains('hidden')){nui('close');appEl.classList.add('hidden');}});

// ---- Messages Lua ----
window.addEventListener('message',e=>{
    const d=e.data;
    switch(d.action){
        case 'open':
            amStaff=!!d.staff;
            const cat=document.getElementById('nr-cat');
            cat.innerHTML=(d.categories||['Autre']).map(c=>`<option>${c}</option>`).join('');
            currentId=null; reports=[];
            applyRole(); renderList(); renderDetail();
            appEl.classList.remove('hidden');
            break;
        case 'role': amStaff=!!d.staff; applyRole(); renderList(); break;
        case 'staffList': reports=d.reports||[]; renderList(); renderDetail(); break;
        case 'myReports': reports=d.reports||[]; renderList(); renderDetail(); break;
        case 'reportUpdated': {
            const r=d.report; const i=reports.findIndex(x=>x.id===r.id);
            if(i>=0) reports[i]=r; else reports.push(r);
            renderList(); if(currentId===r.id) renderDetail();
            break;
        }
        case 'toast': toast(d.msg||'',d.kind||''); break;
        case 'close': appEl.classList.add('hidden'); break;
    }
});
