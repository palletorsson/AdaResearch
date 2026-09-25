"""Build a source-checked editorial purpose study for the ten Primitives halls.

This is a local reading, not a model classification or a claim about author intent.
The manuscript, scene scripts and map configurations are never edited.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
SNAPSHOT = ROOT / 'doc/reports/primitives-purpose-2026-09-21/annotations-2026-09-23-melencolia-one-arrangement.json'
OUTPUT = ROOT / 'doc/research/possible-bodies/primitives-purpose.html'

def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def file_sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def checked_path(value):
    path = (ROOT / value).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError('Invalid evidence file: ' + str(value))
    return path

def build_audit():
    order = read_json(ROOT / 'commons/maps/sequences/primitives.json')['sequences']['primitives']['maps']
    snapshot = read_json(SNAPSHOT)
    sources = {s['map']: s for s in snapshot['sources']}
    maps = {}
    fingerprints = {}
    for name in ['early', 'middle', 'late']:
        part = read_json(REPORT / (name + '.json'))
        if part.get('kind') != 'paragraph-purpose-audit':
            raise ValueError('Unexpected audit kind')
        for hall in part['maps']:
            if hall['map'] in maps:
                raise ValueError('Duplicate hall: ' + hall['map'])
            maps[hall['map']] = hall
    if set(maps) != set(order):
        raise ValueError('Audit halls do not match active sequence')
    total = 0
    for name in order:
        hall, source = maps[name], sources[name]
        manuscript = checked_path(source['path'])
        if file_sha(manuscript) != source['sha256'] or hall['source_sha256'] != source['sha256']:
            raise ValueError('Stale manuscript: ' + name)
        expected = {b['id']: b for b in source['blocks'] if b['kind'] in ['paragraph', 'footnote']}
        notes = {p['block_id']: p for p in hall['paragraphs']}
        if len(notes) != len(hall['paragraphs']) or notes.keys() != expected.keys():
            raise ValueError('Paragraph coverage differs: ' + name)
        evidence = {e['id']: e for e in hall['evidence']}
        if len(evidence) != len(hall['evidence']):
            raise ValueError('Duplicate evidence ID: ' + name)
        listed = set(hall['corpus_read'])
        required = {str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT / 'commons/maps' / name).glob('*.md')}
        if not required.issubset(listed):
            raise ValueError('Missing corpus reading inventory: ' + name + ': ' + repr(required-listed))
        for path in listed:
            resolved = checked_path(path)
            fingerprints[path] = file_sha(resolved)
        for e in evidence.values():
            resolved = checked_path(e['path'])
            lines = resolved.read_text(encoding='utf-8-sig').splitlines()
            start, end = e['start_line'], e['end_line']
            if isinstance(start, bool) or not isinstance(start, int) or not isinstance(end, int) or not 1 <= start <= end <= len(lines):
                raise ValueError('Invalid evidence lines: ' + name + '/' + e['id'])
            context = '\n'.join(lines[start-1:end])
            if not e['excerpt'].strip() or e['excerpt'] not in context:
                raise ValueError('Evidence excerpt mismatch: ' + name + '/' + e['id'])
            fingerprints[e['path']] = file_sha(resolved)
            e['source_sha256'] = fingerprints[e['path']]
            e['context'] = context if len(context) <= 2800 else e['excerpt']
        for note in notes.values():
            if note['block_sha256'] != expected[note['block_id']]['sha256']:
                raise ValueError('Stale paragraph: ' + name)
            if note['assessment'] not in ['grounded', 'interpretive', 'review']:
                raise ValueError('Unknown assessment: ' + name)
            for field in ['purpose', 'artifact_anchor', 'reader_move', 'why_here', 'without']:
                if not isinstance(note[field], str) or not note[field].strip():
                    raise ValueError('Missing purpose field: ' + name + '/' + field)
            if not set(note['evidence_ids']).issubset(evidence):
                raise ValueError('Missing paragraph evidence: ' + name)
        for action in hall['actions']:
            if action['target'] not in ['text', 'artifact', 'staging', 'corpus', 'review']:
                raise ValueError('Unknown action target')
            if not set(action['evidence_ids']).issubset(evidence) or not set(action['block_ids']).issubset(expected):
                raise ValueError('Missing action reference: ' + name)
        hall['blocks'] = source['blocks']
        hall['path'] = source['path']
        total += len(notes)
    return {
        'kind': 'primitives-paragraph-purpose-study',
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'method': 'Provisional editorial readings checked against local texts, map configuration and implementation. Connections show correspondence, not proven historical derivation or author intention. Runtime experience still needs a walk-through.',
        'sequence': 'primitives',
        'arc': 'Position becomes connection, sampled movement, an address, a surface and a solid. The room then turns its own building blocks into questions: what can be repeated, what escapes that repetition, and what happens when construction cannot finish the investigation?',
        'total_paragraphs': total,
        'source_fingerprints': fingerprints,
        'maps': [maps[name] for name in order]
    }

def render_report(audit, output=OUTPUT):
    payload = json.dumps(audit, ensure_ascii=False, allow_nan=False, separators=(',', ':'))
    payload = payload.replace('&', '\\u0026').replace('<', '\\u003c').replace('>', '\\u003e').replace('\u2028', '\\u2028').replace('\u2029', '\\u2029')
    page = PAGE.replace('__PURPOSE_DATA__', payload)
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    Path(output).write_text(page, encoding='utf-8')

PAGE = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives · Why this paragraph?</title>
<style>
:root{font:15px system-ui,sans-serif;color:#eae4d5;background:#181b19;--muted:#aeb6aa;--line:#3c463e;--gold:#e8ba79;--grounded:#82beb0;--interpretive:#bba3d4;--review:#e6b16f}*{box-sizing:border-box}body{margin:0}button,select,input{font:inherit;color:inherit;background:#272e29;border:1px solid #465146;border-radius:7px;padding:8px 11px}button{cursor:pointer}button:hover,button[aria-current=true],button[aria-pressed=true]{border-color:var(--gold);background:#333a30}button:disabled{opacity:.4;cursor:default}a{color:var(--gold);text-underline-offset:3px}button:focus-visible,a:focus-visible,select:focus-visible,input:focus-visible,summary:focus-visible{outline:2px solid var(--gold);outline-offset:3px}h1,h2,h3{font-family:Georgia,serif;font-weight:400}h1{font-size:38px;margin:6px 0 12px;letter-spacing:-1px}h2{font-size:29px;margin:8px 0}h3{font-size:23px;margin:15px 0}p{line-height:1.65}.wrap{max-width:1440px;padding:28px 38px 70px;margin:auto}.top{display:flex;justify-content:space-between;gap:20px;align-items:start}.eyebrow{text-transform:uppercase;letter-spacing:.16em;font-size:11px;color:var(--gold)}.lead{color:var(--muted);margin:0;max-width:760px;font-size:14px}.toplinks{display:flex;gap:14px;flex-wrap:wrap;font-size:12px}.method{border-bottom:1px solid var(--line);padding:14px 0;margin:8px 0 16px;color:var(--muted);font-size:12px}.method summary{cursor:pointer;color:#d8c5a5}.method p{max-width:900px}.legend{display:flex;gap:16px;flex-wrap:wrap}.legend span::before{content:'';display:inline-block;width:8px;height:8px;margin-right:6px;border-radius:50%;background:var(--tone)}.halls{display:flex;gap:7px;overflow:auto;padding-bottom:10px;scrollbar-width:thin}.halls button{flex-shrink:0;font-size:12px;text-align:left;max-width:190px}.halls small{display:block;color:var(--muted);font-size:10px;margin-top:4px}.controls{display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap;margin:12px 0 22px}.switch{display:flex;gap:5px}.switch button{font-size:12px}.filters{display:flex;align-items:center;gap:9px;flex-wrap:wrap}.filters label{font-size:11px;color:var(--muted)}.filters input{max-width:230px;min-width:0;font-size:12px}.filters select{font-size:12px}.hall-head{display:grid;grid-template-columns:1fr 350px;gap:30px;border-top:1px solid var(--line);border-bottom:1px solid var(--line);padding:19px 0;margin-bottom:18px}.hall-head p{margin:8px 0;color:var(--muted);font-size:13px}.hall-head .question{font:21px/1.5 Georgia,serif;color:#f0e3cb;margin:10px 0}.hall-head .next{background:#232a25;border:1px solid var(--line);border-radius:9px;padding:14px}.next h3{font:13px system-ui;margin:7px 0;line-height:1.5}.next p{font-size:12px}.next button{font-size:11px}.meta{font-size:11px;color:var(--muted)}.stats{display:flex;flex-wrap:wrap;gap:14px;margin:14px 0;font-size:11px;color:var(--muted)}.strip{display:flex;gap:3px;height:9px;margin:14px 0}.strip button{flex:1;min-width:2px;padding:0;border:0;border-radius:2px;background:var(--tone)}.reading{max-width:1200px;margin:auto}.passage{display:grid;grid-template-columns:minmax(0,1fr) 350px;gap:38px;margin:0 0 24px;scroll-margin-top:22px}.text{min-width:0;border-left:3px solid var(--tone,var(--line));padding:5px 17px}.prose{font:18px/1.85 Georgia,serif;white-space:pre-wrap;overflow-wrap:anywhere;color:#eee4d1;margin:4px 0}.line{font:10px system-ui;color:#8e9a8e;margin-bottom:7px}.prose code{font:14px ui-monospace,monospace;background:#2d362d;border-radius:4px;padding:2px 4px}.prose sup{font:10px system-ui;line-height:0;margin-left:3px}.prose strong{color:#fff0d7}.structural{display:block;margin:15px 0;max-width:790px}.structural pre{background:#111714;border:1px solid var(--line);border-radius:8px;overflow:auto;padding:18px;font:13px/1.7 ui-monospace,monospace;white-space:pre-wrap}.structural h3{margin-left:20px}.footnote .prose{font-size:15px;color:#c0c5b8}.note{padding:6px 0 12px;border-bottom:1px solid var(--line);font-size:12px}.note p{margin:5px 0}.note .purpose{font-size:14px;line-height:1.6;color:#eddbba}.kicker{text-transform:uppercase;letter-spacing:.08em;font-size:9px;color:var(--muted);margin:10px 0 3px}.badge{display:inline-block;font-size:10px;border:1px solid var(--tone);color:var(--tone);border-radius:4px;padding:2px 6px;margin-bottom:8px}.note details{margin-top:10px;color:#c7cebf}.note summary{font-size:11px;cursor:pointer;color:var(--gold)}.refs{display:flex;flex-direction:column;gap:5px;margin-top:8px}.refs button{text-align:left;font-size:11px;overflow-wrap:anywhere}.opportunity{border-left:2px solid var(--review);padding-left:10px;color:#e4c9a1;margin-top:12px!important}.empty{padding:30px;border:1px dashed var(--line);color:var(--muted)}.action-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:15px}.action{padding:20px;background:#222a24;border:1px solid var(--line);border-radius:10px;min-width:0}.action h3{font-size:21px}.action p{font-size:13px;color:#c3cbbd}.action .passage-links{display:flex;gap:6px;flex-wrap:wrap;margin:12px 0}.action button{font-size:11px}.actions-intro{max-width:780px;color:var(--muted);font-size:14px}.footer{border-top:1px solid var(--line);padding-top:18px;margin-top:28px;font-size:11px;color:var(--muted);display:flex;justify-content:space-between;gap:15px;align-items:center}.footer button{font-size:11px}dialog{background:#1e2720;color:var(--ink);border:1px solid #657363;border-radius:12px;max-width:850px;width:calc(100vw - 30px);max-height:85vh;padding:24px;overflow:auto;color:#eae4d5}dialog::backdrop{background:#050906cc}dialog .dialog-head{display:flex;justify-content:space-between;gap:15px;align-items:start}dialog h2{font-size:24px;overflow-wrap:anywhere}dialog p{font-size:13px;color:#c2cabc}dialog pre{font:12px/1.8 ui-monospace,monospace;white-space:pre-wrap;overflow-wrap:anywhere;padding:16px;background:#111714;border-radius:6px}dialog .hash{font-size:10px;overflow-wrap:anywhere;color:#8d9d8f}[hidden]{display:none!important}body[data-view=plain] .passage{grid-template-columns:minmax(0,790px)}body[data-view=plain] .text{border-left-color:transparent}body[data-view=plain] .reading{max-width:850px}.flow{max-width:850px;font:18px/1.7 Georgia,serif;color:#d6d8c9}
@media(max-width:1000px){.wrap{padding:24px}.hall-head{grid-template-columns:1fr 290px}.passage{grid-template-columns:minmax(0,1fr) 290px;gap:22px}.prose{font-size:17px}}@media(max-width:740px){.wrap{padding:20px 15px 40px}.top{display:block}.toplinks{margin-top:15px}h1{font-size:32px}.hall-head{display:block}.hall-head .next{margin-top:16px}.passage{grid-template-columns:minmax(0,1fr);gap:9px;margin-bottom:35px}.note{margin-left:20px;border-left:1px solid var(--line);padding-left:13px}.prose{font-size:17px}.controls{align-items:start}.filters{width:100%}.filters input{flex:1;max-width:none}.footer{display:block}.footer button{margin-top:10px}.action-grid{grid-template-columns:minmax(0,1fr)}}
</style></head><body data-view="reading"><main class="wrap">
<div class="top"><div><div class="eyebrow">Ada Research / Primitives / Editorial study</div><h1>Why this paragraph?</h1><p class="lead">Read the passage, meet its artifact, follow its sources. Then decide where the next improvement belongs.</p></div><nav class="toplinks"><a href="/research/possible-bodies/book-registers.html">Language registers ↗</a><a href="/book?map=Point_One&section=final">Open the book ↗</a></nav></div>
<details class="method"><summary id="coverage"></summary><p id="method"></p><div class="legend"><span style="--tone:var(--grounded)">Material relation supported in files</span><span style="--tone:var(--interpretive)">Interpretive / connective work</span><span style="--tone:var(--review)">Relationship to examine</span></div><p>These colours identify kinds of editorial attention, not quality scores. A pause, a pleasure, or an unresolved question can be the reason a paragraph belongs. Sources are local project evidence; historical claims have not been independently re-researched in this pass.</p></details>
<nav class="halls" id="halls" aria-label="Primitives halls in sequence"></nav>
<div class="controls"><div class="switch" role="group" aria-label="View"><button id="reading" aria-pressed="true">Text + purpose</button><button id="plain" aria-pressed="false">Plain text</button><button id="actions" aria-pressed="false">Next improvements</button></div><div class="filters"><label for="filter">Show</label><select id="filter"><option value="all">All passages</option><option value="review">Relationships to examine</option><option value="grounded">Materially grounded</option><option value="interpretive">Interpretive passages</option></select><input id="search" type="search" aria-label="Search text and notes" placeholder="Find a word or idea"></div></div>
<div id="hall-head"></div><section id="reader" class="reading" aria-label="Book text and proposed paragraph purpose"></section><section id="action-view" hidden></section>
<footer class="footer"><span>Source text and artifacts are unchanged. Notes are proposed editorial readings, with inspectable evidence.</span><button id="download">Download this study (JSON)</button></footer>
</main><dialog id="evidence"><div class="dialog-head"><h2 id="evidence-title"></h2><button id="close-evidence" aria-label="Close evidence">Close</button></div><p id="evidence-note"></p><p id="evidence-path"></p><pre id="evidence-context"></pre><div class="hash" id="evidence-hash"></div></dialog>
<script id="purpose-data" type="application/json">__PURPOSE_DATA__</script><script>
(()=>{'use strict';
const data=JSON.parse(document.getElementById('purpose-data').textContent),$=id=>document.getElementById(id),maps=data.maps,params=new URLSearchParams(location.search),labels={grounded:'Materially grounded',interpretive:'Interpretive passage',review:'Examine this relation'};
let hall=maps.find(m=>m.map===params.get('map'))||maps[0],view=['plain','actions'].includes(params.get('view'))?params.get('view'):'reading';
const el=(tag,cls,text)=>{const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=String(text);return n;};
const pretty=s=>String(s).replaceAll('_',' '),isProse=b=>['paragraph','footnote'].includes(b.kind),notes=m=>new Map(m.paragraphs.map(p=>[p.block_id,p])),anchor=(m,b)=>'p-'+m.map+'-'+b.id;
const footnotes=m=>{const out=new Map();for(const b of m.blocks){if(b.kind==='footnote'){const match=String(b.source_text||'').match(/^\[\^([^\]]+)\]:/);if(match)out.set(match[1],{number:out.size+1,id:anchor(m,b)});}}return out;};
function inline(parent,text,m,depth=0){if(depth>6){parent.append(document.createTextNode(text));return;}const pattern=/`([^`]+)`|\[\^([^\]]+)\]|\[([^\]\n]+)\]\(((?:https?:\/\/|\/(?!\/))[^\s)]+)\)|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*\n]+)\*|~~([^~\n]+)~~/g;let hit,last=0;while((hit=pattern.exec(text))){parent.append(document.createTextNode(text.slice(last,hit.index)));if(hit[1]!==undefined)parent.append(el('code','',hit[1]));else if(hit[2]!==undefined){const f=footnotes(m).get(hit[2]);if(f){const sup=el('sup'),a=el('a','',f.number);a.href='#'+f.id;a.title='Footnote '+f.number;a.addEventListener('click',e=>{e.preventDefault();$('filter').value='all';$('search').value='';render();document.getElementById(f.id)?.scrollIntoView({block:'center'});});sup.append(a);parent.append(sup);}else parent.append(document.createTextNode(hit[0]));}else if(hit[3]!==undefined){const a=el('a');a.href=hit[4];a.rel='noopener noreferrer';inline(a,hit[3],m,depth+1);parent.append(a);}else{const n=el(hit[8]!==undefined?'del':hit[5]!==undefined||hit[6]!==undefined?'strong':'em');inline(n,hit[8]??hit[5]??hit[6]??hit[7],m,depth+1);parent.append(n);}last=pattern.lastIndex;}parent.append(document.createTextNode(text.slice(last)));}
function prose(m,b){const picture=String(b.source_text||'').match(/^!\[([^\]]*)\]\((\/book-review\/[^\s)]+)\)$/);if(picture){const f=el('figure','prose'),a=el('a'),img=el('img');a.href=picture[2];img.src=picture[2];img.alt=picture[1];img.loading='lazy';img.style.cssText='display:block;width:100%;height:auto';a.append(img);f.append(a);f.style.margin='4px 0';return f;}const n=el(b.kind==='code'?'pre':b.kind==='heading'?'h3':'p',isProse(b)?'prose':'');let text=String(b.text??'');if(b.kind==='code'){n.textContent=text;return n;}if(b.kind==='footnote'){const match=String(b.source_text||'').match(/^\[\^([^\]]+)\]:\s*/);if(match){const f=footnotes(m).get(match[1]);if(f)n.append(el('span','',f.number+'. '));if(text.startsWith(match[0]))text=text.slice(match[0].length);}}inline(n,text,m);return n;}
function openEvidence(m,id){const e=m.evidence.find(e=>e.id===id);if(!e)return;$('evidence-title').textContent=pretty(e.kind)+' evidence';$('evidence-note').textContent=e.note||'Related source passage. This supports an editorial connection, not a claim about the author’s intention.';$('evidence-path').textContent=e.path+' · lines '+e.start_line+'–'+e.end_line;$('evidence-context').textContent=e.context;$('evidence-hash').textContent='Source fingerprint: '+e.source_sha256;$('evidence').showModal();}
function refs(m,ids){const box=el('div','refs');for(const id of ids){const e=m.evidence.find(e=>e.id===id);if(!e)continue;const b=el('button','',e.kind+' · '+e.path.split('/').slice(-2).join('/')+' · L'+e.start_line);b.addEventListener('click',()=>openEvidence(m,id));box.append(b);}return box;}
function field(parent,name,text){parent.append(el('div','kicker',name),el('p','',text));}
function go(m,id=null){hall=m;view='reading';$('filter').value='all';$('search').value='';render();if(id)document.getElementById(anchor(m,{id}))?.scrollIntoView({block:'center'});else $('hall-head').scrollIntoView({block:'start'});}
function actionCard(m,a){const c=el('article','action');c.append(el('div','eyebrow',pretty(m.map)+' / '+a.target),el('h3','',a.title),el('p','',a.reason));const links=el('div','passage-links');for(const id of a.block_ids){const b=m.blocks.find(b=>b.id===id);if(b){const link=el('button','','Read L'+b.start_line);link.addEventListener('click',()=>go(m,id));links.append(link);}}c.append(links,refs(m,a.evidence_ids));return c;}
function renderActions(){const box=$('action-view');box.replaceChildren();box.append(el('h2','','Where to work next'),el('p','flow',data.arc),el('p','actions-intro','These are revision candidates across the ten halls. Each points back to passages and source evidence. Read the relationship before deciding whether to change the text, an artifact, its staging, or an older source document.'));const cards=el('div','action-grid');for(const m of maps)for(const a of m.actions)cards.append(actionCard(m,a));box.append(cards);}
function renderHead(){const box=$('hall-head');box.replaceChildren();const h=el('header','hall-head'),left=el('div'),right=el('aside','next');left.append(el('div','eyebrow','Hall '+(maps.indexOf(hall)+1)+' of '+maps.length),el('h2','',pretty(hall.map)),el('p','question',hall.core_question),el('p','',hall.arc));const link=el('a','meta','Read this hall in the book ↗');link.href='/book?map='+encodeURIComponent(hall.map)+'&section=final';left.append(link,document.createTextNode(' · '));const roomLink=el('a','meta','See this room’s artifacts ↗');roomLink.href='/necklace/thread?map='+encodeURIComponent(hall.map)+'&role=primary';left.append(roomLink);const inventory=el('details','meta');inventory.style.marginTop='10px';inventory.append(el('summary','','Corpus read · '+hall.corpus_read.length+' files'));inventory.append(el('p','',hall.corpus_read.map(p=>p.split('/').pop()).join(' · ')));left.append(inventory);const stats=el('div','stats');for(const s of ['grounded','interpretive','review'])stats.append(el('span','',hall.paragraphs.filter(p=>p.assessment===s).length+' '+({grounded:'grounded in files',interpretive:'interpretive / connective',review:'to examine'})[s]));left.append(stats);const strip=el('nav','strip');strip.setAttribute('aria-label','Jump to a paragraph');for(const p of hall.paragraphs){const b=hall.blocks.find(b=>b.id===p.block_id),tile=el('button');tile.style.setProperty('--tone','var(--'+p.assessment+')');tile.title='L'+b.start_line+': '+p.purpose;tile.setAttribute('aria-label',tile.title);tile.addEventListener('click',()=>go(hall,p.block_id));strip.append(tile);}left.append(strip);if(hall.actions.length){const a=hall.actions[0];right.append(el('div','eyebrow','First revision candidate · '+a.target),el('h3','',a.title),el('p','',a.reason));const more=el('button','','See improvements across Primitives');more.addEventListener('click',()=>{view='actions';render();});right.append(more);}h.append(left,right);box.append(h);}
function matches(b,p){const filter=$('filter').value,q=$('search').value.trim().toLocaleLowerCase();if(!isProse(b))return filter==='all'&&!q;if(filter!=='all'&&p.assessment!==filter)return false;return !q||[b.text,p.purpose,p.artifact_anchor,p.reader_move,p.why_here,p.opportunity].join(' ').toLocaleLowerCase().includes(q);}
function renderReader(){const box=$('reader');box.replaceChildren();const byId=notes(hall);let shown=0;for(const b of hall.blocks){const p=byId.get(b.id);if(!matches(b,p))continue;shown++;const row=el('article','passage'+(!isProse(b)?' structural':'')+(b.kind==='footnote'?' footnote':''));row.id=anchor(hall,b);if(p)row.style.setProperty('--tone','var(--'+p.assessment+')');const text=el('div','text');text.append(el('div','line','L'+b.start_line+(b.end_line!==b.start_line?'–'+b.end_line:'')),prose(hall,b));row.append(text);if(p&&view!=='plain'){const aside=el('aside','note');aside.setAttribute('aria-label','Proposed editorial purpose');aside.append(el('span','badge',labels[p.assessment]),el('div','kicker','Proposed purpose'),el('p','purpose',p.purpose));field(aside,'Artifact / spatial anchor',p.artifact_anchor);const d=el('details');d.append(el('summary','','Reader · sources · what could improve'));field(d,'Reader’s movement',p.reader_move);field(d,'Why here',p.why_here);field(d,'Without this passage',p.without);if(p.opportunity)d.append(el('p','opportunity',p.opportunity));d.append(refs(hall,p.evidence_ids));if(!p.evidence_ids.length)d.append(el('p','meta','No direct source correspondence assigned; this note describes a reading function.'));aside.append(d);row.append(aside);}box.append(row);}if(!shown)box.append(el('div','empty','No passages match this filter. Choose All passages or clear the search.'));}
function render(){document.body.dataset.view=view;for(const v of ['reading','plain','actions'])$(v).setAttribute('aria-pressed',String(v===view));$('filter').disabled=view==='actions';$('search').disabled=view==='actions';$('hall-head').hidden=view==='actions';$('reader').hidden=view==='actions';$('action-view').hidden=view!=='actions';$('halls').replaceChildren();for(const m of maps){const b=el('button','',pretty(m.map));b.setAttribute('aria-current',String(m===hall));b.append(el('small','',m.paragraphs.length+' passages'));b.addEventListener('click',()=>go(m));$('halls').append(b);}if(view==='actions')renderActions();else{renderHead();renderReader();}const u=new URL(location.href);u.searchParams.set('map',hall.map);u.searchParams.set('view',view);history.replaceState(null,'',u);}
$('coverage').textContent=maps.length+' halls · '+data.total_paragraphs+' paragraph readings · '+Object.keys(data.source_fingerprints).length+' checked source files · About this study';$('method').textContent=data.method;
for(const v of ['reading','plain','actions'])$(v).addEventListener('click',()=>{view=v;render();});$('filter').addEventListener('change',render);let timer;$('search').addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(render,140);});$('close-evidence').addEventListener('click',()=>$('evidence').close());$('download').addEventListener('click',()=>{const u=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'})),a=el('a');a.href=u;a.download='primitives-paragraph-purpose.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),1000);});render();
})();</script></body></html>
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=OUTPUT)
    args = parser.parse_args()
    audit = build_audit()
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / 'audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    render_report(audit, args.out)
    print('Validated', len(audit['maps']), 'halls,', audit['total_paragraphs'], 'paragraph readings and', len(audit['source_fingerprints']), 'source files.')
