"""Read the current colour-to-form-finding route and combine it with editorial proposals.

Writes only doc/research/possible-bodies outputs. Does not edit maps, roles or prose.
Run from any directory: python tools/build_possible_bodies_guide.py
"""
from pathlib import Path
import csv
import hashlib
import html
import json
import re
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
SEQUENCES = ['color', 'tiling', 'change', 'forces', 'formfinding']
NAMES = dict(zip(SEQUENCES, ['Colour', 'Patterns', 'Change', 'Forces', 'Form Finding']))
THREADS = {
    'formfinding': 'A local search gains constraints and connected bodies; inspect the measure and the rule that accepts a form.',
    'color': 'A value becomes appearance in relation to light, neighbours, surfaces and bodies.',
    'tiling': 'Make a motif, repeat it, give it different bodies, perform it, inspect its shader, and wear a saved fabric.',
    'change': 'A configuration gains a history: measure variation, accumulate contributions and inspect paths.',
    'forces': 'Directions and rates participate in interactions that constrain or enable bodily movement.',
}
sources = {}

def read(rel):
    raw = (ROOT / rel).read_bytes()
    sources[rel] = hashlib.sha256(raw).hexdigest()
    return raw.decode('utf-8-sig')

def unique(items):
    return list(dict.fromkeys(items))

def token(raw):
    return str(raw).split('#')[0].split(':')[0].strip()

def main():
    proposals = {r['map']: r for r in csv.DictReader(read('doc/research/possible-bodies/curation.tsv').splitlines(), delimiter='\t')}
    verification = json.loads(read('doc/research/possible-bodies/verification.json'))
    roles = json.loads(read('commons/data/artifact_roles.json'))
    effective = json.loads(read('commons/data/museum_order_effective.json'))
    seq_docs = {s: json.loads(read(f'commons/maps/sequences/{s}.json'))['sequences'][s] for s in SEQUENCES}
    halls = [h for h in effective['halls'] if h['sequence'] in SEQUENCES]
    assert set(proposals) == {h['name'] for h in halls}, 'Route changed: update the curation sheet before rebuilding.'
    rows = []
    for h in halls:
        name, seq = h['name'], h['sequence']
        p = proposals[name]
        md = json.loads(read(f'commons/maps/{name}/map_data.json'))
        placed = unique(token(v) for layer in ['interactables', 'utilities'] for row in md.get('layers', {}).get(layer, []) for v in row if token(v) not in ['', '0'])
        final_path = f'commons/maps/{name}/final.md'
        final = read(final_path) if (ROOT / final_path).exists() else ''
        raw_anchors = re.findall(r'<!--\s*@([^>]*?)-->', final)
        anchors = unique(a.strip() for a in raw_anchors if a.strip() and not a.strip().startswith('sub:'))
        primary = [k for k, v in roles['roles'].get(name, {}).items() if v == 'primary']
        leads = [t.strip() for t in p['leads'].split(',')]
        assert all(t in placed for t in leads), f'Proposed lead not placed: {name}'
        flags = []
        if not final.strip(): flags.append('text')
        if not primary or (final.strip() and set(anchors) != set(primary)): flags.append('roles')
        if name.startswith('Ribbon_'): flags.append('curation')
        evidence = verification.get(name, {})
        evidence_current = bool(evidence) and all(
            hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest
            for path, digest in evidence.get('source_sha256', {}).items())
        runtime = (evidence['date'] + ': ' + evidence['summary']) if evidence_current else (
            'Recorded verification is stale: source changed; repeat the comparison.' if evidence else 'Not recorded in this guide.')
        rows.append({**p, 'sequence': seq, 'source': h.get('source'), 'in_sequence_list': name in seq_docs[seq]['maps'],
                     'runtime_verification': runtime, 'verification_current': evidence_current,
                     'verification_report': evidence.get('report') if evidence_current else None,
                     'verification_capture': evidence.get('capture') if evidence_current else None,
                     'verification_comparisons': evidence.get('comparisons', []) if evidence_current else [],
                     'leads': leads, 'primary': primary, 'book_anchors': anchors, 'book_words': len(final.split()),
                     'placed_tokens': placed, 'flags': flags, 'book_unplaced': [a for a in anchors if token(a) not in placed],
                     'primary_unplaced': [a for a in primary if token(a) not in placed]})
    summary = {'halls': len(rows), 'with_final': sum(r['book_words'] > 0 for r in rows),
               'missing_final': sum('text' in r['flags'] for r in rows),
               'role_reviews': sum('roles' in r['flags'] for r in rows),
               'ribbon_halls': sum('curation' in r['flags'] for r in rows)}
    legacy = {s: [g['map'] for g in seq_docs[s].get('artifact_groups', []) if g.get('map') not in seq_docs[s]['maps']] for s in SEQUENCES}
    data = {'generated_at': datetime.now(timezone.utc).isoformat(), 'scope': SEQUENCES, 'summary': summary,
            'basis': 'Effective museum order + sequence lists + map placements + explicit roles + final.md anchors. Runtime evidence is recorded separately per room, with source fingerprints; source coverage alone does not establish runtime or headset readiness.',
            'sequence_threads': THREADS, 'legacy_groups_outside_sequence': legacy, 'maps': rows, 'source_sha256': sources}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'audit.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    write_html(data)
    write_markdown(data)
    print(json.dumps(summary))

def write_markdown(data):
    lines = ['# What bodies are possible? Colour to Form Finding', '', data['basis'], '',
             'This is an editorial working guide. Proposed leads do not change current primary assignments. Text presence is not a quality score.', '',
             'Descent opens Form Finding with 36 desktop checks and a two-start comparison; see descent-landscape.html. Next: Catenary. Force as Place closes Forces with a local acceleration field and real desktop carry/landing, 45 checks; see force-as-place.html. Next: Form Finding. The Arena now pairs a scoped crab encounter with collision carts, 45 desktop checks; see arena-relations.html. Legs now pairs a physical support experiment with a procedural walker; 37 desktop checks, see legs-support.html. Gravity now has fixed-source and mutual-body experiments with 51 desktop checks; see gravity-relations.html. Restoring Forces and Balance now has an integrated spring, separate from the later Wavefunctions chapter; see restoring-forces.html. Kinetic Forces now compares physical drag, signed nominal work and prescribed circular motion; see kinetic-forces.html. Fields and Motion now compares velocity assignment with acceleration accumulation in one spatial rule; see field-receivers.html. Motion now has a full-scale force-controlled body and a friction threshold comparison; see motion-chamber.html. Launch now has full-scale paired flights around central controls; see launch-chamber.html. Linked subtraction and projection now use one live gap in Vectors_Act2_VectorArithmetic; see vector-gap-projection.html. VFM_02_Operations now has one shared sum feeding a wall plan and a carriage, with cancellation and two routes; see vector-addition.html. The first vector wall and four Change idea markers are implemented; see vectors-forces-plan.html. New after Oscillation: Change_Choreography, with twenty phase-controlled light rods and a physical conveyor backlog. See timing-machines.html. The introductory Change sequence retains its two halls: rate, accumulation and net change in Change_Intro, followed by shared field instructions and paths in Flow_Field. All 23 distinct Change artifacts remain. See change-two-halls.html for the book, layouts and desktop evidence. Headset walkthroughs and secondary exhibit review remain open.', '']
    for seq in SEQUENCES:
        lines += [f'## {NAMES[seq]}', '', THREADS[seq], '']
        for r in (r for r in data['maps'] if r['sequence'] == seq):
            lines += [f"### {r['map']}", '', r['question'], '', f"- Layer: {r['layer']}",
                      f"- Proposed lead encounter: {', '.join(r['leads'])}", f"- Carry forward: {r['carry']}",
                      f"- Next action: {r['next']}", f"- Evidence to close it: {r['proof']}",
                      f"- Reusable method: {r['method']}", f"- Current primaries: {', '.join(r['primary']) or 'unassigned'}",
                      f"- Current book: {r['book_words']} words; anchors: {', '.join(r['book_anchors']) or 'none'}",
                      f"- Runtime evidence: {r['runtime_verification']}", '']
    lines += ['## Reading the audit', '', 'The effective order contains four Change ribbons absent from change.json maps. Seven ribbons in this scope need editorial decisions. The live summary above records the remaining halls without final.md. Sub: markers are excluded from artifact comparisons. A differing book/primary set is a review flag, not automatic permission to remove text or promote every object.', '',
              'Keep a controlled comparison together, including all seven walkers in Legs. Test duplicate placements for changed configuration, scale, interaction and teaching purpose before consolidating. Do not infer continuous morphing from shared code or field metadata.', '',
              'Regenerate: python tools/build_possible_bodies_guide.py. The script validates coverage and proposed-token placement, reads fresh source facts and writes this guide, audit.json and index.html. Edit curation.tsv to revise editorial proposals; the game is not changed by generation.', '']
    (OUT / 'working-guide.md').write_text('\n'.join(lines), encoding='utf-8')

def write_html(data):
    e = html.escape
    parts = ['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>What bodies are possible? · Working guide</title>
<style>
:root{color-scheme:light;--paper:#f4f0e8;--ink:#242727;--muted:#62645e;--red:#9b2449}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:36px 28px 80px}a{color:var(--red);text-underline-offset:3px}h1{font:clamp(38px,6vw,70px)/1.06 Georgia,serif;max-width:850px;margin:30px 0 20px}h2{font:32px/1.2 Georgia,serif}h3{font-size:20px}.eyebrow{letter-spacing:.12em;text-transform:uppercase;font-size:12px;color:var(--muted)}.intro{max-width:800px;font-size:21px}.note{color:var(--muted);font-size:14px}.stats,.threads{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:26px 0}.stat,.thread{padding:18px;border:1px solid #d0cbc1;border-radius:8px}.stat strong{display:block;font:36px Georgia,serif}.thread strong{display:block;margin-bottom:6px}.next{border-left:5px solid var(--red);padding:12px 22px;background:#fffaf5;margin:26px 0}.filters{display:flex;gap:12px;flex-wrap:wrap;margin:28px 0 10px}.filters label{font-size:13px;display:flex;flex-direction:column;gap:4px}input,select{font:inherit;border:1px solid #aaa59b;background:white;border-radius:4px;padding:9px;min-width:170px}details.hall{background:#fffcf7;border:1px solid #d0cbc1;border-radius:8px;margin:14px 0;overflow:hidden}summary{cursor:pointer;padding:18px 22px}summary strong{font-size:18px;overflow-wrap:anywhere}summary .question{display:block;margin:8px 0;color:#454841}.body{padding:0 22px 22px}.badge{display:inline-block;font:12px system-ui;margin:3px 5px 0 0;border:1px solid #cfc3c0;border-radius:12px;padding:4px 8px}.flags{color:var(--red)}.columns{display:grid;grid-template-columns:1fr 1fr;gap:24px}.body p{margin:12px 0}.body b{font-weight:650}code{font-size:13px;overflow-wrap:anywhere}ul{padding-left:22px}.evidence{border-top:1px solid #ddd3c6;margin-top:20px;padding-top:12px;font-size:14px}details.evidence summary{padding:5px 0}.links{display:flex;gap:20px;flex-wrap:wrap}.hidden{display:none!important}.principle{font:25px/1.4 Georgia,serif;max-width:850px}.queue{columns:2;column-gap:40px}.queue li{break-inside:avoid;padding:4px 0}@media(max-width:700px){main{padding:24px 16px}.stats,.threads,.columns{grid-template-columns:1fr 1fr}.columns{grid-template-columns:1fr;gap:0}.queue{columns:1}.intro{font-size:18px}}@media print{.filters,.links{display:none}.body{display:block!important}details{break-inside:avoid}.hidden{display:block!important}}
</style><main><nav><a href="/blog/2026-09-10-what-bodies-are-possible">Read the research post</a> · <a href="/museum-progress?sequence=color">Museum Progress</a></nav>
<p class="eyebrow">Ada Research · editorial working guide · 10 September 2026</p><h1>What bodies are possible?</h1><p class="intro">Follow a value into an appearance, a motif into an environment, a changing quantity into a history, a force into a condition of inhabiting the world, and a local search into questions about possible shapes.</p>
<p class="note">Source snapshot, not a live completion dashboard. Each card separates current evidence from proposed curation. Text presence does not establish teaching quality, runtime behaviour or headset readiness.</p>''']
    s = data['summary']
    parts.append('<div class="stats">'+''.join(f'<div class="stat"><strong>{n}</strong>{label}</div>' for n,label in [(s['halls'],'halls on the effective route'),(s['with_final'],'have final.md text'),(s['missing_final'],'need a book decision'),(s['role_reviews'],'need primary/book review')])+'</div>')
    parts.append('<div class="threads">'+''.join(f'<a class="thread" href="#sequence-{seq}"><strong>{NAMES[seq]}</strong>{e(THREADS[seq])}</a>' for seq in SEQUENCES)+'</div>')
    parts.append('''<p class="principle">For every hall: what can exist with the current toolbox; what does the new principle enable; where else can we apply it; and what can leave with us?</p>
<div class="next"><p><a href="sine-contact.html"><b>What a wave can hold.</b></a> Sine Space now has a physical contact tray, a clear forecourt and two book encounters: tray, then corridor.</p><p><a href="landscape-thread.html"><b>What leaves? What remains?</b></a> The original landscape experiment now has a four-tray physical prototype and a concrete return through Waves, Randomness, Noise and machine learning. Museum placement is the next step.</p><p><b>Now entering Form Finding.</b> <a href="descent-landscape.html">Where does downhill take you?</a> One controlled primary, five retained comparisons, 36 desktop checks. Two starts reach unequal valleys under the same stopping rule.</p><p><b>Next: Catenary.</b> Inspect what is held fixed, how the cable is updated and which controls the visitor actually has. Later halls are listed as working questions; their scenes still need review.</p><p>Revisit <a href="force-as-place.html">Force as Place</a>, <a href="arena-relations.html">the Arena</a>, <a href="gravity-relations.html">Gravity</a>, <a href="timing-machines.html">timing machines</a>, <a href="change-two-halls.html">Change</a> or <a href="patterns-plan.html">the Patterns plan</a>. Headset walkthroughs remain open.</p></div>
<p><b>Keep an encounter primary when the visitor needs it to discover, test or challenge the room's principle.</b> One object can do this; a pair can expose a difference; a whole controlled series can be one encounter. Legs keeps seven walkers. Supporting artifacts remain available. A book/role mismatch prompts an editorial decision, not automatic deletion.</p>
<p><b>Resolve the handoffs before claiming one continuous lesson.</b> This guide reads the effective museum route. Form Finding adds six working encounters; source presence and proposed leads remain distinct from runtime evidence.</p>
<ol class="queue"><li>Visit Descent with a learner: predict a step, compare starts, explain each stopping state.</li><li>Inspect Catenary supports, length and load; choose a controlled primary comparison.</li><li>Review the five later Form Finding halls against their actual update rules.</li><li>Complete tracked-hand and headset visits across the developed route when equipment is available.</li></ol>
<div class="filters"><label>Sequence<select id="sequence"><option value="">All sequences</option><option value="color">Colour</option><option value="tiling">Patterns</option><option value="change">Change</option><option value="forces">Forces</option><option value="formfinding">Form Finding</option></select></label><label>Work to find<select id="work"><option value="">All work</option><option value="text">No final.md</option><option value="roles">Primary/book review</option><option value="curation">Ribbon curation</option></select></label><label>Search map, object or method<input id="search" type="search" placeholder="Try: shader, player, history"></label></div><p id="count" class="note" role="status" aria-live="polite"></p>''')
    for seq in SEQUENCES:
        parts.append(f'<section class="sequence" id="sequence-{seq}" data-sequence="{seq}"><h2>{NAMES[seq]}</h2>')
        for r in [r for r in data['maps'] if r['sequence']==seq]:
            name=r['map']; search=' '.join(str(v) for v in r.values()).lower()
            flags={'text':'No final.md','roles':'Primary/book review','curation':'Ribbon curation'}
            parts.append(f'<details class="hall" id="{name}" data-sequence="{seq}" data-flags="{e(" ".join(r["flags"]))}" data-search="{e(search,quote=True)}"><summary><strong>{name}</strong><span class="question">{e(r["question"])}</span><span class="badge">{e(r["layer"])}</span><span class="badge">{r["book_words"]} book words</span>'+''.join(f'<span class="badge flags">{flags[f]}</span>' for f in r['flags'])+'</summary><div class="body">')
            parts.append(f'<p><b>Proposed lead encounter:</b> <code>{e(", ".join(r["leads"]))}</code></p><p><b>Carry forward:</b> {e(r["carry"])}</p><div class="columns"><p><b>Next action</b><br>{e(r["next"])}</p><p><b>Evidence to close it</b><br>{e(r["proof"])}</p></div><p><b>Reusable method:</b> {e(r["method"])}</p>')
            parts.append(f'<p class="links"><a href="/necklace/thread?map={name}">Room and artifacts</a><a href="/necklace/thread?map={name}&amp;role=primary">Current primary view</a><a href="/museum-progress?sequence={seq}&amp;room={name}">Museum Progress</a></p>')
            parts.append(f'<p><b>Recorded runtime evidence:</b> {e(r["runtime_verification"])}</p>')
            if r['verification_current']:
                parts.append(f'<p><a href="{e(r["verification_report"],quote=True)}">Read the check report</a></p><figure><img src="{e(r["verification_capture"],quote=True)}" alt="{e(name)} encounter in the actual museum" loading="lazy" style="width:100%;height:auto"><figcaption class="note">Desktop museum capture; see the dated report for camera and test conditions. Headset view untested.</figcaption></figure>')
            if r['verification_comparisons']:
                parts.append('<details class="evidence"><summary>Compare the other views</summary>')
                for view in r['verification_comparisons']:
                    parts.append(f'<figure><img src="{e(view["file"],quote=True)}" alt="{e(view["caption"],quote=True)}" loading="lazy" style="width:100%;height:auto"><figcaption>{e(view["caption"])}</figcaption></figure>')
                parts.append('</details>')
            parts.append(f'<details class="evidence"><summary>Recorded source evidence</summary><p>Current primary: <code>{e(", ".join(r["primary"]) or "unassigned")}</code></p><p>Book anchors: <code>{e(", ".join(r["book_anchors"]) or "none")}</code></p><p>Placed tokens: <code>{e(", ".join(r["placed_tokens"]))}</code></p><p>On sequence maps list: {r["in_sequence_list"]}. Effective source: {e(str(r["source"]))}.</p></details></div></details>')
        parts.append('</section>')
    parts.append('''<p class="note">Rebuild from the research repository with <code>python tools/build_possible_bodies_guide.py</code>. Edit <code>doc/research/possible-bodies/curation.tsv</code> for proposals. The build refuses incomplete route coverage or an unplaced proposed lead. Source hashes make the snapshot traceable.</p><p><a href="audit.json">Download source audit</a> · <a href="working-guide.md">Read the Markdown guide</a></p></main>
<script>
const cards=[...document.querySelectorAll('.hall')], seq=document.querySelector('#sequence'),work=document.querySelector('#work'),search=document.querySelector('#search');
function filter(){let n=0;for(const card of cards){const visible=(!seq.value||card.dataset.sequence===seq.value)&&(!work.value||card.dataset.flags.split(' ').includes(work.value))&&card.dataset.search.includes(search.value.toLowerCase());card.classList.toggle('hidden',!visible);if(visible)n++;}for(const section of document.querySelectorAll('section.sequence'))section.classList.toggle('hidden',![...section.querySelectorAll('.hall')].some(c=>!c.classList.contains('hidden')));document.querySelector('#count').textContent=n+' of '+cards.length+' halls shown';}
for(const el of [seq,work,search])el.addEventListener('input',filter);
function reveal(){const target=document.getElementById(decodeURIComponent(location.hash.slice(1)));if(!target)return;if(target.classList.contains('hall')){seq.value='';work.value='';search.value='';filter();target.open=true;target.scrollIntoView();}else if(target.classList.contains('sequence')){seq.value=target.dataset.sequence;work.value='';search.value='';filter();target.scrollIntoView();}}
window.addEventListener('hashchange',reveal);filter();reveal();window.addEventListener('beforeprint',()=>cards.forEach(c=>c.open=true));
</script></html>''')
    (OUT / 'index.html').write_text('\n'.join(parts), encoding='utf-8')

if __name__ == '__main__':
    main()
