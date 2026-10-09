"""Build the Fable handoff from explicit proposals and a fresh source snapshot.

Only writes doc/research/waves-chance-noise. Never edits game content or roles.
"""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import html
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/waves-chance-noise'
SEQUENCES = ['wavefunctions', 'randomness', 'noise']
HASHES = {}


def read(rel):
    raw = (ROOT / rel).read_bytes()
    HASHES[str(rel).replace('\\', '/')] = hashlib.sha256(raw).hexdigest()
    return raw.decode('utf-8-sig')


def js(rel):
    return json.loads(read(rel))


def token(raw):
    return str(raw).split('#')[0].split(':')[0].strip()


def resources(scene):
    """Direct scene resources: entry points, not a claim of full dependency tracing."""
    path = scene.removeprefix('res://')
    if not path or not (ROOT / path).is_file():
        return []
    text = read(path)
    paths = re.findall(r'path="res://([^"\n]+\.(?:gd|gdshader|tscn))"', text)
    return list(dict.fromkeys(paths))


def audit():
    roles = js('commons/data/artifact_roles.json')['roles']
    effective = js('commons/data/museum_order_effective.json')
    authored = js('commons/data/map_authored.json')
    museum_plan = js('ada_run/em_plan.json')
    read('commons/maps/curriculum_spine.json')
    read('commons/artifacts/the_same_cloud/the_same_cloud.gd')
    sequence_docs = {s: js(f'commons/maps/sequences/{s}.json')['sequences'][s] for s in SEQUENCES}
    registry = {}
    for path in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8-sig'))
        for key, value in data.get('artifacts', {}).items():
            if isinstance(value, dict):
                registry.setdefault(key, []).append((path.relative_to(ROOT).as_posix(), value))
    rows = []
    for seq in SEQUENCES:
        active = [h['name'] for h in effective['halls'] if h['sequence'] == seq]
        planned = [r['map'] for r in museum_plan['plans'] if r.get('sequence') == seq]
        assert active == authored[seq] == planned, f'Route sources disagree for {seq}; reconcile before rebuilding.'
        names = list(dict.fromkeys(sequence_docs[seq]['maps'] + active))
        for name in names:
            rel = f'commons/maps/{name}'
            data = js(f'{rel}/map_data.json')
            placements = [{'token': token(value), 'cell': [x, z], 'raw': str(value)}
                          for z, row in enumerate(data.get('layers', {}).get('interactables', []))
                          for x, value in enumerate(row) if token(value) not in ['', '0']]
            primary = [k for k, v in roles.get(name, {}).items() if v == 'primary']
            texts = {}
            for kind in ['final', 'technical', 'critical', 'tutorial', 'summary', 'intent', 'blurb']:
                if (ROOT / rel / f'{kind}.md').exists():
                    texts[kind] = read(f'{rel}/{kind}.md')
            final = texts.get('final', '')
            anchors = list(dict.fromkeys(a.strip() for a in re.findall(r'<!--\s*@([^>]*?)-->', final)
                                         if a.strip() and not a.strip().startswith('sub:')))
            entries = {}
            for t in dict.fromkeys([p['token'] for p in placements] + primary):
                matches = registry.get(t, [])
                entries[t] = []
                for reg_path, value in matches:
                    read(reg_path)
                    scene = value.get('scene', '')
                    deps = resources(scene)
                    for dep in deps:
                        if (ROOT / dep).exists():
                            read(dep)
                    entries[t].append({'registry': reg_path, 'scene': scene,
                                       'scene_exists': bool(scene) and (ROOT / scene.removeprefix('res://')).is_file(),
                                       'map_ready': value.get('map_ready'), 'direct_resources': deps})
            placed = {p['token'] for p in placements}
            rows.append({'map': name, 'sequence': seq, 'active_index': active.index(name) + 1 if name in active else None,
                         'authored_index': sequence_docs[seq]['maps'].index(name) + 1 if name in sequence_docs[seq]['maps'] else None,
                         'museum_authored': name in authored.get(seq, []),
                         'dimensions': data.get('map_info', {}).get('dimensions'), 'placements': placements,
                         'primary': primary, 'book_anchors': anchors, 'book_words': len(final.split()),
                         'role_book_match': set(primary) == set(anchors),
                         'unplaced_primary': [t for t in primary if t not in placed],
                         'unplaced_book': [t for t in anchors if token(t) not in placed],
                         'documents': list(texts), 'artifacts': entries})
    return {'generated_at': datetime.now(timezone.utc).isoformat(),
            'basis': 'Source audit only. Active means present in the effective museum index; it does not certify a live, reachable installation.',
            'summary': {'maps': len(rows), 'active': sum(r['active_index'] is not None for r in rows),
                        'with_final': sum(r['book_words'] > 0 for r in rows),
                        'primary_book_mismatches': sum(not r['role_book_match'] for r in rows)},
            'maps': rows, 'source_sha256': HASHES}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    data = audit()
    if (OUT / 'plan.json').exists():
        render(data, js('doc/research/waves-chance-noise/plan.json'))
    (OUT / 'audit.json').write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps(data['summary']))


def render(data, plan):
    assert {r['map'] for r in data['maps']} == {p['map'] for p in plan['maps']}, 'Plan must cover the whole audited scope.'
    assert len(plan['maps']) == len({p['map'] for p in plan['maps']}), 'Duplicate map plan.'
    facts = {r['map']: r for r in data['maps']}
    plans = {p['map']: p for p in plan['maps']}
    required = ['question', 'body', 'lead', 'findings', 'build', 'book', 'code', 'evidence', 'latitude', 'reuse', 'batch']
    (OUT / 'maps').mkdir(exist_ok=True)
    combined = ['# Waves, Randomness and Noise: every map', '',
                'Read [HANDOFF.md](HANDOFF.md) first. Each room\'s status distinguishes planned work from reviewed encounters.', '',
                'Active means on the current museum route. Extensions receive full plans but are not added to that route by this document.', '']
    for s in plan['sequences']:
        combined += [f"## {s['title']}", '', s['thread'], '', s['necessity'], '', s['route'], '']
        for fact in (r for r in data['maps'] if r['sequence'] == s['sequence']):
            p = plans[fact['map']]
            assert all(p.get(k) for k in required), f"Incomplete card: {p['map']}"
            assert len(p['build']) >= 3 and len(p['book']) >= 4 and len(p['evidence']) >= 3
            placed = {r['token'] for r in fact['placements']}
            assert set(p['lead']) <= placed, f"Unplaced proposed lead: {p['map']}"
            body = card_markdown(p, fact)
            (OUT / 'maps' / (p['map'] + '.md')).write_text(body, encoding='utf-8')
            # Preserve the hierarchy when collecting standalone cards.
            combined_body = body.replace('(../HANDOFF.md)', '(HANDOFF.md)').replace('(../all-maps.md)', '(all-maps.md)')
            combined.append(re.sub(r'(?m)^(#+) ', r'\1## ', combined_body))
    (OUT / 'all-maps.md').write_text('\n'.join(combined), encoding='utf-8')
    (OUT / 'index.html').write_text(page_html(data, plan), encoding='utf-8')


def status(fact):
    return f"Active hall {fact['active_index']} in {fact['sequence']}" if fact['active_index'] else 'Authored extension — outside the current museum route'


def source_paths(fact):
    result = []
    for t in fact['primary']:
        for entry in fact['artifacts'].get(t, []):
            result += [entry['scene']] + entry['direct_resources']
    return list(dict.fromkeys(result))


def card_markdown(p, f):
    n = p['map']
    progress = p.get('status', 'Implementation pending')
    lines = [f'# {n}', '', f"**{status(f)}. Batch: {p['batch']}. {progress}.**", '',
             '[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)', '',
             f"## {p['question']}", '', f"Body/layer: {p['body']}", '',
             f"Proposed primary encounter: {', '.join('`'+t+'`' for t in p['lead'])}.", '',
             '## Starting evidence', '', p['findings'], '',
             f"Current map dimensions: {f['dimensions']}. Current final: {f['book_words']} words.", '',
             f"Current primaries: {', '.join(f['primary'])}. Book anchors: {', '.join(f['book_anchors'])}.", '',
             'Source agreement is not proof of runtime reachability or lesson quality.', '',
             '## Build the encounter', '']
    if p.get('review_url'):
        lines[4:4] = [f"[Current review, images and listening]({p['review_url']})", '']
    lines += [f'{i}. {v}' for i, v in enumerate(p['build'], 1)]
    lines += ['', '## Revise final.md', '']
    lines += [f'{i}. {v}' for i, v in enumerate(p['book'], 1)]
    lines += ['', '**Code to trace and quote after implementation:** ' + p['code'], '',
              '## Evidence to return', '']
    lines += ['- '+v for v in p['evidence']]
    lines += ['', 'Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.', '',
              '## Room for a better solution', '', p['latitude'], '',
              '**Reusable method:** ' + p['reuse'], '', '## Open and inspect', '',
              f'- Map: `commons/maps/{n}/map_data.json`',
              f'- Book and supporting texts: `commons/maps/{n}/`',
              f'- [Primary view](http://localhost:3003/necklace/thread?map={n}&role=primary)',
              f'- [Museum Progress](http://localhost:3003/museum-progress?sequence={f["sequence"]}&room={n})']
    lines += ['- `'+v+'`' for v in source_paths(f)]
    lines += ['', 'Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.', '']
    return '\n'.join(lines)


def page_html(data, plan):
    e = html.escape
    facts = {r['map']: r for r in data['maps']}
    parts = ['''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Returning, choosing, inhabiting · Ada Research</title>
<style>
:root{color-scheme:light;--paper:#f4f0e8;--ink:#24272b;--muted:#62636a;--accent:#8b2855;--line:#d8cfc7}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:34px 30px 80px}a{color:var(--accent);text-underline-offset:3px}h1{font:clamp(40px,6vw,76px)/1.04 Georgia,serif;max-width:960px;margin:30px 0}h2{font:32px/1.2 Georgia,serif;margin-top:34px}h3{font-size:18px;margin-top:24px}p{max-width:940px}.eyebrow{font-size:12px;letter-spacing:.13em;text-transform:uppercase;color:var(--muted)}.intro{font-size:22px;max-width:850px}.muted{color:var(--muted);font-size:14px}.stats,.threads,.pilots{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:26px 0}.stat,.thread,.pilot{border:1px solid var(--line);padding:20px;border-radius:8px;background:#fffcf5}.stat strong{font:38px Georgia,serif;display:block}.thread strong,.pilot strong{display:block;margin-bottom:8px}.callout{border-left:5px solid var(--accent);padding:14px 24px;background:#fffaf5}.links{display:flex;gap:14px 24px;flex-wrap:wrap}.filters{display:flex;gap:16px;flex-wrap:wrap;position:sticky;top:0;padding:15px 0;background:var(--paper);z-index:2;border-bottom:1px solid var(--line)}label{font-size:13px;display:flex;flex-direction:column;gap:4px}input,select{font:16px system-ui;padding:10px;border:1px solid #aaa1a3;border-radius:4px;background:#fff;min-width:175px}input{min-width:270px}details.hall{border:1px solid var(--line);background:#fffdf8;border-radius:8px;margin:16px 0;scroll-margin-top:120px}summary{padding:20px 24px;cursor:pointer}summary strong{font-size:19px;overflow-wrap:anywhere}summary .question{display:block;margin:8px 0;font:23px/1.35 Georgia,serif}.badge{font-size:12px;border:1px solid var(--line);border-radius:16px;padding:3px 10px;display:inline-block;margin:4px 8px 0 0}.pilot-tag{border-color:var(--accent);color:var(--accent)}.body{padding:0 24px 24px}.body li{margin:9px 0}.body h3{color:#3f424d}.columns{display:grid;grid-template-columns:1fr 1fr;gap:30px}.freedom{background:#f3f0fa;border-left:3px solid #85648a;padding:12px 18px}.facts{border-top:1px solid var(--line);margin-top:24px;padding-top:12px}.facts summary{padding:8px 0}code{font-size:13px;overflow-wrap:anywhere}.hidden{display:none!important}.source-list{font-size:14px}.plan-label{color:var(--accent);font-weight:650}@media(max-width:750px){main{padding:24px 16px 50px}.stats,.threads,.pilots,.columns{grid-template-columns:1fr}.stats{grid-template-columns:repeat(3,1fr);gap:8px}.stat{padding:12px;font-size:12px}.stat strong{font-size:30px}.filters{position:static}input{min-width:200px}summary,.body{padding-left:16px;padding-right:16px}.intro{font-size:19px}}@media print{.filters{display:none}.hidden{display:block!important}.body{display:block}details{break-inside:avoid}.columns{display:block}}
</style></head><body><main>
<nav class="links"><a href="/research/possible-bodies/index.html">Colour to Forces working guide</a><a href="/museum-progress?sequence=wavefunctions">Museum Progress</a></nav>
<p class="eyebrow">Ada Research · instruction plan for Fable 5.1 · 10 September 2026</p>
<h1>Returning, choosing,<br>inhabiting.</h1>
<p class="intro">What bodies become possible when a movement can repeat, a procedure can choose, and variation can depend on where we look?</p>
<p class="plan-label">Random Entropy reviewed: keep the encounter; correct reference bars and readability.</p>
<p class="callout"><b>Structure prerequisite:</b> interior height-2 cells now form one-metre platforms; boundary cells remain museum walls. All six active wave halls passed the geometry probe. <a href="recovery.html">Read the recovery report and see the rooms</a>.</p>
<p class="callout"><b>Extended structure recovery:</b> the same distinction is corrected in 17 Randomness, Noise and Cellular Automata maps. Source and before/after access checks pass; physical museum checks remain pending. <a href="structure-recovery.html">Compare the old grids and corrected museum interpretation</a>.</p>
<p class="callout"><b>Whole-spine audit:</b> 202 maps checked, 62 further maps corrected, and the newer partitions in nine rebuilt galleries preserved as requested. Real grid arenas are a separate construction case. <a href="spine-recovery.html">Follow the spine recovery and preservation decisions</a>.</p>
<p>This is a source-grounded handoff. Each room has a question, a build task, a plan for its book passage and a comparison that can show whether it works. Fable has room to choose the form of the encounter.</p>
''']
    parts.append('<div class="stats">'+''.join(f'<div class="stat"><strong>{v}</strong>{k}</div>' for v,k in [(data['summary']['maps'],'individual map plans'),(data['summary']['active'],'active museum halls'),(data['summary']['with_final'],'existing final.md texts to revise')])+'</div>')
    parts.append('<p class="muted">The other 16 authored maps receive extension plans. This guide does not insert them into the museum. All current primary/book sets agree in the source audit; that does not establish runtime quality. Fable supplied runtime reports for three pilots and W1. Intro pickup/release was skipped; Random needs a clear view of its primary. Actual desktop input and headset acceptance remain partial.</p>')
    parts.append('<div class="links"><a href="book-voice.html">Book voice: read the six revised chapters</a><a href="BOOK_VOICE.md">Writing brief</a><a href="w1-review.html">W1 review and next checks</a><a href="CURRENT_TASK.md">Current Claude assignment: visual improvements</a><a href="NEXT_BATCH.md">Earlier W1 brief</a><a href="HANDOFF.md">Shared instructions for Fable</a><a href="all-maps.md">Download all 35 map plans</a><a href="README.md">Scope and working order</a><a href="REVIEW_TEMPLATE.md">Handback template</a><a href="audit.json">Source audit</a><a href="plan.json">Editable plan data</a></div>')
    parts.append('<div class="threads">')
    for s in plan['sequences']:
        parts.append(f'<a class="thread" href="#sequence-{s["sequence"]}"><strong>{e(s["title"])}</strong>{e(s["thread"])}</a>')
    parts.append('</div><div class="callout" id="next-batch"><b>Inside twelve rooms · 12 September.</b><p>Fresh museum views ground a room-by-room improvement pass: visible experiments, readable controls and clear operating positions. Preserve completed Entropy repairs and fold the Mushrooms observations into current work.</p><p><a href="visual-review.html">See the images and requests</a> · <a href="CURRENT_TASK.md">Current Claude assignment</a>.</p></div><div class="pilots">')
    for p in (r for r in plan['maps'] if r['batch'] == 'PILOT'):
        parts.append(f'<a class="pilot" href="#{p["map"]}"><strong>{e(p["map"])}</strong>{e(p["question"])}</a>')
    parts.append('''</div><p><b>The book rhythm:</b> question → do → observe → explain with actual code → test the limit → carry something forward. Keep the existing passages that work. Let the code name a discovery after the reader has had a chance to make it.</p>
<p><b>Fable's latitude:</b> materials, proportions, casing, arrangement and surprises are open. Keep the experiment specific. A better lead artifact is welcome when its placement, primary role, book anchor and evidence are revised together.</p>
<div class="filters"><label>Sequence<select id="seq"><option value="">All sequences</option><option value="wavefunctions">Wavefunctions</option><option value="randomness">Randomness</option><option value="noise">Noise</option></select></label><label>Workset<select id="work"><option value="">All 35 maps</option><option value="active">Active museum route</option><option value="extension">Authored extensions</option><option value="pilot">Three pilots</option></select></label><label>Find a question, artifact or method<input id="search" type="search" placeholder="Try: seed, collision, garment"></label></div><p id="count" class="muted" role="status" aria-live="polite"></p>''')
    for s in plan['sequences']:
        parts.append(f'<section class="sequence" id="sequence-{s["sequence"]}" data-seq="{s["sequence"]}"><h2>{e(s["title"])}</h2><p>{e(s["necessity"])}</p><p class="muted">{e(s["handoff"])}</p><p class="muted">{e(s["route"])}</p>')
        for p in (r for r in plan['maps'] if facts[r['map']]['sequence'] == s['sequence']):
            f = facts[p['map']]; n = p['map']
            work = ('active' if f['active_index'] else 'extension') + (' pilot' if p['batch'] == 'PILOT' else '')
            search = e(json.dumps(p, ensure_ascii=False).lower(), quote=True)
            progress = e(p.get('status', 'Implementation pending'))
            parts.append(f'<details class="hall" id="{n}" data-seq="{s["sequence"]}" data-work="{work}" data-search="{search}"><summary><strong>{n}</strong><span class="question">{e(p["question"])}</span><span class="badge">{e(status(f))}</span><span class="badge">{progress}</span>' + ('<span class="badge pilot-tag">Pilot</span>' if p['batch'] == 'PILOT' else '') + '</summary><div class="body">')
            parts.append(f'<p><b>Body / layer:</b> {e(p["body"])}</p><p><b>Proposed primary encounter:</b> <code>{e(", ".join(p["lead"]))}</code></p><p><b>Starting evidence:</b> {e(p["findings"])}</p><div class="columns"><div><h3>Build the encounter</h3><ol>')
            parts += ['<li>'+e(v)+'</li>' for v in p['build']]
            parts.append('</ol></div><div><h3>Revise final.md</h3><ol>')
            parts += ['<li>'+e(v)+'</li>' for v in p['book']]
            parts.append('</ol></div></div>')
            parts.append(f'<p><b>Code to trace:</b> {e(p["code"])}</p><h3>Evidence to return</h3><ul>')
            parts += ['<li>'+e(v)+'</li>' for v in p['evidence']]
            parts.append(f'</ul><p class="freedom"><b>Room for a better solution</b><br>{e(p["latitude"])}</p><p><b>Reusable method:</b> {e(p["reuse"])}</p>')
            if p.get('review_url'):
                parts.append(f'<p><a href="{e(p["review_url"])}">Current review, images and listening</a></p>')
            parts.append(f'<p class="links"><a href="maps/{n}.md">This instruction card</a><a href="/necklace/thread?map={n}&amp;role=primary">Current primary view</a><a href="/museum-progress?sequence={s["sequence"]}&amp;room={n}">Museum Progress</a></p>')
            parts.append(f'<details class="facts"><summary>Current source facts and code entry points</summary><p class="muted">{f["book_words"]} book words. Primaries: {e(", ".join(f["primary"]))}. Book anchors: {e(", ".join(f["book_anchors"]))}. Dimensions: {e(str(f["dimensions"]))}. Source agreement does not certify runtime behaviour.</p><ul class="source-list">')
            parts += ['<li><code>'+e(v)+'</code></li>' for v in source_paths(f)]
            parts.append('</ul><p class="muted">Inspect actual scene overrides and inherited resources. An exported setting is not necessarily a visitor control.</p></details></div></details>')
        parts.append('</section>')
    parts.append(f'<p class="muted">Source snapshot generated {e(data["generated_at"])}. Rebuild with <code>python tools/build_waves_chance_noise_plan.py</code>. The generator changes this plan directory only. The separate Nails/Rainbow workstream remains outside Fable\'s scope.</p></main>')
    parts.append('''<script>
const cards=[...document.querySelectorAll('.hall')],seq=document.querySelector('#seq'),work=document.querySelector('#work'),search=document.querySelector('#search');
function filter(){let n=0;const q=search.value.trim().toLowerCase();for(const c of cards){const show=(!seq.value||c.dataset.seq===seq.value)&&(!work.value||c.dataset.work.split(' ').includes(work.value))&&(!q||c.dataset.search.includes(q));c.classList.toggle('hidden',!show);if(show)n++;}for(const s of document.querySelectorAll('.sequence'))s.classList.toggle('hidden',![...s.querySelectorAll('.hall')].some(c=>!c.classList.contains('hidden')));document.querySelector('#count').textContent=n+' of '+cards.length+' map plans shown';}
for(const el of [seq,work,search])el.addEventListener('input',filter);
function reveal(){const id=decodeURIComponent(location.hash.slice(1)),target=document.getElementById(id);if(!target)return;seq.value='';work.value='';search.value='';filter();if(target.classList.contains('hall'))target.open=true;requestAnimationFrame(()=>target.scrollIntoView({block:'start'}));}
window.addEventListener('hashchange',reveal);window.addEventListener('beforeprint',()=>cards.forEach(c=>c.open=true));filter();reveal();
</script></body></html>''')
    return ''.join(parts)


if __name__ == '__main__':
    main()
