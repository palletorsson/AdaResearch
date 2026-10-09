"""Rebuild the artist/operation crosswalk from curated judgements and live repository evidence.

This audits sources and direct spine tokens; it does not execute Godot or certify teaching.
Run from anywhere: python doc/book/artist-capacity/build.py
"""
from __future__ import annotations

from collections import Counter, defaultdict
from hashlib import sha256
from html import escape as esc
import json
from pathlib import Path
import re
from urllib.parse import quote

from curation import PROFILES, ROWS, STATUS, EVIDENCE_OVERRIDES, PRIORITY

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
REVIEW = ROOT / 'doc/book/iterations/2026-10-01-artist-capacity'
DATE = '2026-10-02'
INPUTS = {}


def rel(p):
    return Path(p).relative_to(ROOT).as_posix()


def read(p):
    p = Path(p)
    raw = p.read_bytes()
    INPUTS[rel(p)] = sha256(raw).hexdigest()
    return raw.decode('utf-8-sig')


def data(p):
    return json.loads(read(p))


def save(p, obj):
    Path(p).write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def url(path):
    return '/book-review/' + quote(str(path), safe='/')


def link(path, label):
    return f'<a href="{url(path)}">{esc(label)}</a>'


def local_resource(value, owner):
    if value.startswith('res://'):
        return ROOT / value[6:]
    if '://' in value:
        return None
    return (owner.parent / value).resolve()


def script_sources(scene, depth=0, seen=None):
    """Follow declared scene resources, not arbitrary executable code."""
    seen = set() if seen is None else seen
    if scene in seen or depth > 5:
        return []
    seen.add(scene)
    found = []
    for resource in re.findall(r'\[ext_resource[^\]]*path="([^"]+)"[^\]]*\]', read(scene)):
        p = local_resource(resource, scene)
        if p is None or not p.exists():
            continue
        if p.suffix == '.gd':
            found.append(rel(p))
        elif p.suffix == '.tscn':
            found.extend(script_sources(p, depth + 1, seen))
    return list(dict.fromkeys(found))


def cells(value, address=()):
    if isinstance(value, str):
        yield address, value
    elif isinstance(value, list):
        for i, item in enumerate(value):
            yield from cells(item, address + (i,))
    elif isinstance(value, dict):
        for k, item in value.items():
            yield from cells(item, address + (k,))


def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    (REVIEW / 'sources').mkdir(exist_ok=True)
    source = data(HERE / 'source-index.json')
    read(HERE / 'SOURCE-INDEX.txt')
    read(HERE / 'curation.py')
    read(HERE / 'build.py')
    read(ROOT / 'commons/artifacts/kitbash_station/kitbash_station.tscn')
    original = {(x['category']['id'], x['artist']): x for x in source}
    assert len(source) == len(original) == 100
    rows = [line.split('|') for line in ROWS.splitlines()]
    assert all(len(row) == 6 for row in rows)
    assert len(rows) == len({(r[0], r[1]) for r in rows}) == 100
    assert set(original) == {(r[0], r[1]) for r in rows}, 'Artist/category mismatch'

    registry = defaultdict(list)
    for p in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
        doc = data(p)
        for key, entry in doc.get('artifacts', {}).items():
            if isinstance(entry, dict):
                registry[key].append(dict(registry=rel(p), **entry))
    selected = sorted({key for p in PROFILES.values() for key in p['artifacts']})
    assert all(k in registry for k in selected)

    sequences = {}
    sequence_files = {}
    for p in sorted((ROOT / 'commons/maps/sequences').glob('*.json')):
        records = data(p).get('sequences', {})
        if not isinstance(records, dict):  # Generated catalogue, not sequence definitions.
            continue
        for key, value in records.items():
            sequences[key] = value
            sequence_files[key] = rel(p)
    spine = data(ROOT / 'commons/maps/curriculum_spine.json')['spine']['sequences']
    spine.sort(key=lambda s: s['order'])
    order = {s['name']: s['order'] for s in spine}
    order['preparation'] = 0
    placements = defaultdict(list)
    maps_scanned = []
    for seq in spine:
        name = seq['name']
        assert name in sequences, name
        for map_name in sequences[name].get('maps', []):
            assert isinstance(map_name, str), map_name
            path = ROOT / 'commons/maps' / map_name / 'map_data.json'
            m = data(path)
            maps_scanned.append(dict(sequence=name, map=map_name, path=rel(path)))
            for address, token in cells(m.get('layers', {}).get('interactables', [])):
                key = token.strip().split('#', 1)[0].split(':', 1)[0]
                if key in selected:
                    placements[key].append(dict(sequence=name, map=map_name, path=rel(path),
                                                address=list(address), token=token))

    ladder = data(ROOT / 'doc/book/tutorial-lineage/curriculum.json')
    nodes = {n['id']: n for n in ladder['nodes']}

    def closure(ids, visiting=None):
        visiting = set() if visiting is None else set(visiting)
        result = set()
        for key in ids:
            assert key in nodes, key
            assert key not in visiting, 'Capability cycle: ' + key
            result.add(key)
            result.update(closure(nodes[key].get('requires', []), visiting | {key}))
        return result

    profiles = {}
    for key, p in PROFILES.items():
        required = closure(p['capabilities'])
        stages = {nodes[n]['sequence'] for n in required}
        assert all(s in order for s in stages), stages - order.keys()
        gate = max(stages, key=order.get)
        profiles[key] = dict(p, prerequisite_closure=sorted(required),
                             build_gate_sequence=gate, build_gate_order=order[gate],
                             gate_basis='Declared capability requirements and their transitive prerequisites. '
                                        'This is a proposed making gate, not a runtime or learner certification.')

    artifacts = {}
    all_sources = {}
    anchor_hints = {
        'bicho_hinge': 'func _build_hinge', 'facade_room_cast': 'func _interior',
        'fold_wall': 'func _build_stages', 'found_object_assembler': 'func _seat',
        'head_trace_projection': 'func _accept_position', 'molnar_cube_study': 'func frame_pose',
        'super_drag_mirror': 'func update_reflection', 'ecosystem_simulation': 'func balance_ecosystem',
        'soundboxes': 'func _on_button_triggered',
        'gravity_well': 'func _physics_process', 'rhizomatic_structure': 'func generate',
        'generative_adversarial_networks_gans_vr': 'func _process',
        'noise_terrain': 'func create_terrain_collision',
    }
    for key in selected:
        entries = registry[key]
        scenes = sorted({e['scene'] for e in entries})
        assert len(scenes) == 1, f'Ambiguous scene for {key}: {scenes}'
        scene = ROOT / scenes[0].removeprefix('res://')
        assert scene.exists(), scene
        scripts = script_sources(scene)
        evidence = []
        # Main script, or an explicit implementing source when the scene is only an apparatus.
        if scripts and key != 'agnes_martin_grid_painting':
            path = scripts[0]
            text = read(ROOT / path)
            hint = anchor_hints.get(key, 'func ')
            if hint not in text:
                hint = 'func '
            assert hint in text, path
            evidence.append((path, hint))
        evidence.extend(EVIDENCE_OVERRIDES.get(key, []))
        assert evidence, f'No implementation evidence: {key}'
        traced = []
        for path, marker in evidence:
            text = read(ROOT / path)
            assert marker in text, (path, marker)
            line = next(i for i, t in enumerate(text.splitlines(), 1) if marker in t)
            slug = re.sub(r'[^a-zA-Z0-9_.-]', '_', path) + '.html'
            all_sources[path] = (slug, text)
            traced.append(dict(path=path, line=line, marker=marker,
                               sha256=INPUTS[path], snapshot='sources/' + slug))
        artifacts[key] = dict(id=key, name=entries[0].get('name', key), scene=rel(scene),
                              registries=[e['registry'] for e in entries],
                              duplicate_note='Two registry definitions share the same scene; metadata may differ.' if len(entries) > 1 else None,
                              declared_map_ready=[e.get('map_ready') for e in entries],
                              declared_include_in_map_data=[e.get('include_in_map_data') for e in entries],
                              direct_spine_placements=placements[key], evidence=traced,
                              evidence_level='source inspected; no fresh runtime test in this audit')

    matches = []
    for cat, artist, profile_ids, status, proposal, remainder in rows:
        ids = profile_ids.split()
        assert all(p in profiles for p in ids)
        assert status in STATUS
        matches.append(dict(original[(cat, artist)], profiles=ids, judgement=status,
                            smallest_next_study=proposal, critical_remainder=remainder,
                            artifacts=list(dict.fromkeys(a for p in ids for a in profiles[p]['artifacts']))))

    counts = dict(Counter(m['judgement'] for m in matches))
    installed = sum(bool(a['direct_spine_placements']) for a in artifacts.values())
    meta = dict(date=DATE, scope='Source-audited planning atlas; no game or spine edits.',
                entries=len(matches), distinct_artist_labels=len({m['artist'] for m in matches}),
                categories=len({m['category']['id'] for m in matches}), profiles=len(profiles),
                candidate_artifacts=len(artifacts), candidate_artifacts_with_direct_spine_tokens=installed,
                maps_scanned=len(maps_scanned), sequences_scanned=len(spine), judgements=counts,
                artist_evidence='Descriptions and search URLs supplied by the user; not independently verified art history.',
                placement_scope='Exact registry key in layers.interactables in current active-spine map_data.json files. '
                                'No direct token does not exclude generated, nested, branch or dynamic placement.',
                readiness_scope='Capability gates use the declared ladder, whose nodes currently have proposed status. '
                                'They do not prove a finished tutorial, student competence or artifact runtime health.')
    save(HERE / 'matches.json', dict(meta=meta, matches=matches))
    save(HERE / 'artifact-capacities.json', dict(meta=meta, profiles=profiles, artifacts=artifacts,
                                               capability_nodes=nodes, scanned_maps=maps_scanned))

    # One compact but complete human-readable export, using normal relative Markdown links.
    md = ['# Artist operations × existing capacity', '',
          'Capacity belongs to a specific operation, not to an artist’s whole practice.', '',
          f'{len(matches)} entries · 99 distinct artist labels · 12 categories · {len(profiles)} operation families · {len(artifacts)} candidate artifacts.', '',
          'Artist descriptions are supplied prompts. Judgements are editorial matches checked against repository sources. '
          'No fresh Godot runtime tests were performed. No map or spine order was changed.', '',
          '## How to use this', '',
          'Choose an encounter → name what remains fixed → change one relation → observe a consequence → identify the borrowed apparatus '
          'and the student’s required capabilities → retain the question the mechanism cannot answer.', '',
          'Full artifact source links, actual direct spine placements and prerequisite gates are in '
          '[the review atlas](../iterations/2026-10-01-artist-capacity/index.html) and [artifact-capacities.json](artifact-capacities.json).', '']
    for key, (label, definition) in STATUS.items():
        md += [f'- **{label}: {counts[key]}.** {definition}']
    for cat in dict.fromkeys(m['category']['id'] for m in matches):
        group = [m for m in matches if m['category']['id'] == cat]
        md += ['', '## ' + group[0]['category']['title'].title(), '']
        for m in group:
            md += [f"### {m['artist']} — {STATUS[m['judgement']][0]}", '',
                   f"Supplied operation: {m['provided_operation']}", '',
                   'Candidates: ' + ', '.join(f'`{a}`' for a in m['artifacts']) + '.', '',
                   'Capabilities: ' + '; '.join(' → '.join(profiles[p]['capabilities']) +
                        ' (making gate: ' + profiles[p]['build_gate_sequence'] + ')' for p in m['profiles']) + '.', '',
                   '**Next study:** ' + m['smallest_next_study'], '',
                   '**Keep in view:** ' + m['critical_remainder'], '']
    (HERE / 'MATCHES.md').write_text('\n'.join(md) + '\n', encoding='utf-8')

    render(meta, matches, profiles, artifacts, nodes, all_sources)
    save(HERE / 'source-hashes.json', dict(date=DATE, inputs=INPUTS,
         meaning='Byte hashes at atlas generation. A changed input requires rebuilding and reviewing the editorial match.'))
    print(json.dumps(meta, ensure_ascii=False, indent=2))


CSS = '''
:root{--paper:#f4f1eb;--ink:#202124;--muted:#575955;--line:#c8c6c0;--pink:#f15183;--green:#356447;--blue:#315d88}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.58 system-ui,sans-serif}
main{max-width:1240px;margin:auto;padding:48px 32px 100px}a{color:inherit;text-underline-offset:3px}a:hover{color:#a3184e}
header{max-width:900px;margin:18px 0 40px}.eyebrow{font-size:12px;letter-spacing:.13em;text-transform:uppercase;font-weight:700}
h1{font-size:clamp(38px,6vw,78px);letter-spacing:-.06em;line-height:1.02;max-width:850px;margin:26px 0}h2{font-size:30px;letter-spacing:-.035em;margin:0 0 20px}h3{font-size:21px;line-height:1.25}
.lead{font-size:23px;line-height:1.45;max-width:820px}.quiet,.meta,small{color:var(--muted)}.meta{font-size:13px}.band{border-top:1px solid var(--line);padding:32px 0;margin-top:34px}
.metrics{display:grid;grid-template-columns:repeat(4,1fr);border-block:1px solid var(--ink);margin:34px 0}.metric{padding:18px 14px 18px 0}.metric b{font-size:38px;display:block;letter-spacing:-.06em}.metric span{font-size:13px}
.columns{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:25px}.cards{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px}.card{padding:22px;border:1px solid var(--line);background:#fff9}.card h3{margin-top:4px}.card p:last-child{margin-bottom:0}
.flow{display:flex;flex-wrap:wrap;gap:7px;align-items:center}.flow span{background:#fff;padding:8px 12px;border:1px solid var(--line);font-size:14px}.flow i{font-style:normal;color:var(--pink)}
.pill{display:inline-block;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.045em;padding:4px 8px;background:#e0e2e0;color:#333;border-radius:3px}
.pill.reuse{background:#dce9de;color:#214c30}.pill.compose{background:#dbe6f3;color:#254564}.pill.develop{background:#f5deca;color:#704321}.pill.research{background:#eadfea;color:#624963}
nav{display:flex;flex-wrap:wrap;gap:9px;margin:20px 0}nav a{padding:5px 10px;border:1px solid var(--line);font-size:13px;text-decoration:none}
details{border-top:1px solid var(--line);padding:15px 0}summary{cursor:pointer}summary:hover{color:#9a1a49}summary .artist{font-weight:650;font-size:19px;margin-right:12px}.operation{display:block;font-size:14px;color:var(--muted);margin:8px 0 0 20px}
.entry-body{padding:4px 20px 18px;max-width:960px}.entry-body p{margin:14px 0}.links{display:flex;gap:8px;flex-wrap:wrap}.links a{font-size:13px;padding:3px 8px;border:1px solid var(--line);text-decoration:none;overflow-wrap:anywhere}
.category{padding-top:34px;scroll-margin-top:25px}.category h3{font-size:25px}.category h3 small{font-size:12px;letter-spacing:.08em}.categories{margin-top:22px}
table{border-collapse:collapse;width:100%;font-size:14px}th,td{border-bottom:1px solid var(--line);padding:12px;text-align:left;vertical-align:top}th{font-size:12px;text-transform:uppercase;letter-spacing:.04em}.table-wrap{overflow-x:auto}
code{font-size:.87em;overflow-wrap:anywhere}pre{white-space:pre-wrap;background:#e8e4dc;padding:18px;font-size:14px}figure{margin:0}figure img{width:100%;display:block;aspect-ratio:16/10;object-fit:cover}figcaption{font-size:13px;color:var(--muted);padding-top:10px}
.filters{display:flex;flex-wrap:wrap;gap:7px;margin:16px 0}.filters label{border:1px solid var(--line);padding:7px 12px;cursor:pointer;font-size:13px}.filter-input{position:absolute;width:1px;height:1px;clip-path:inset(50%)}
.filter-input:focus-visible~.filters{outline:2px solid var(--pink)}
#all:checked~.filters label[for=all],#reuse:checked~.filters label[for=reuse],#compose:checked~.filters label[for=compose],#develop:checked~.filters label[for=develop],#research:checked~.filters label[for=research]{background:var(--ink);color:white}
#reuse:checked~.categories .entry:not(.reuse),#compose:checked~.categories .entry:not(.compose),#develop:checked~.categories .entry:not(.develop),#research:checked~.categories .entry:not(.research){display:none}
.source-line{display:block;scroll-margin-top:20px}.source-line:target{background:#ffd3e0}.source-line a{color:#777;text-decoration:none;display:inline-block;width:5em;user-select:none}body.source main{max-width:none}body.source pre{font:13px/1.6 Consolas,monospace;white-space:pre-wrap}
.note{border-left:3px solid var(--pink);padding:4px 0 4px 20px;margin:25px 0}
@media(max-width:780px){main{padding:25px 18px 60px}.cards,.columns{grid-template-columns:1fr}.metrics{grid-template-columns:repeat(2,1fr)}.lead{font-size:20px}th,td{padding:8px}}
@media print{.filters,nav{display:none}main{max-width:none}details{break-inside:avoid}a{text-decoration:none}}
'''


def shell(title, body, css=CSS, extra=''):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' + \
        '<title>' + esc(title) + '</title><style>' + css + '</style><body ' + extra + '><main>' + body + '</main></body></html>'


def render(meta, matches, profiles, artifacts, nodes, all_sources):
    b = [f'<header><p class="eyebrow">Ada / research atlas / {DATE}</p><h1>What can these<br>artifacts carry?</h1>',
         '<p class="lead">An artist names a field of questions. An artifact offers particular operations. '
         'The useful match is where a question can become something we can change, observe and make.</p>',
         '<p>Capacity belongs to a specific operation, not to an artist’s whole practice.</p></header>',
         '<div class="note"><b>Recent studies are now installed.</b> Sixteen application studies have entered thirteen existing halls. '
         '<a href="/book-review/doc/book/iterations/2026-10-02-studies-in-the-spine/index.html">See their museum captures, current readings and first source edits.</a> '
         'The broader 100-entry atlas below remains a research plan; installation of a particular study does not complete an artist’s whole field of operations.</div>',
         '<div class="metrics">']
    for n, label in [(100,'reference entries / 99 artist labels'),(24,'operation families'),(meta['candidate_artifacts'],'source-inspected candidates'),
                     (meta['candidate_artifacts_with_direct_spine_tokens'],'candidates with direct spine tokens')]:
        b.append(f'<div class="metric"><b>{n}</b><span>{esc(label)}</span></div>')
    b += ['</div><nav><a href="#start">Six useful next studies</a><a href="#atlas">All 100 matches</a>'
          '<a href="#capacity">The making ladder</a><a href="#evidence">Source & placement evidence</a>'
          '<a href="#limits">Where the names overpromise</a></nav>',
          '<div class="note"><b>This is a source audit and a work plan.</b> It does not add rooms or reorder the spine. '
          'No fresh Godot runtime tests were performed. The artist descriptions are supplied prompts; exact works, scores '
          'and art-historical identifications still need their own sources.</div>',
          '<section class="band"><h2>Three capacities, held apart</h2><div class="cards">',
          '<div class="card"><h3>The project can</h3><p>Point to an implementing scene, script and operation. '
          'Then distinguish a direct map placement from a registered or standalone component.</p></div>',
          '<div class="card"><h3>The student can</h3><p>Carry a specific operation from earlier work. '
          'The ladder records prerequisites and borrowed apparatus; it does not certify a completed tutorial.</p></div>',
          '<div class="card"><h3>The encounter asks</h3><p>Give the operation a reason to matter: a body, a history, '
          'a choice, an exclusion or a material consequence that the parameter alone cannot supply.</p></div></div>',
          '<p class="flow"><span>question</span><i>→</i><span>operation</span><i>→</i><span>one changed relation</span>'
          '<i>→</i><span>observed consequence</span><i>→</i><span>something the student can make</span></p></section>',
          '<section id="start" class="band"><h2>Six useful next studies</h2><div class="cards">']
    for pid, title, artist, action, test in PRIORITY:
        b += [f'<article class="card"><p class="eyebrow">{esc(artist)}</p><h3>{esc(title)}</h3>'
              f'<p>{esc(action)}</p><p><b>Observation:</b> {esc(test)}</p><a href="#profile-{pid}">Capacity and making gate ↗</a></article>']
    b += ['</div></section>', '<section class="band"><h2>Three capacities you can already see</h2><div class="cards">']
    for folder, filename, caption in [
        ('2026-10-01-signal-room','inside.png','Signal room: a native standalone study. A whole room displays the same retained array.'),
        ('2026-10-01-five-reference-rooms','suspension-before.png','Suspension: a native standalone study. Positions persist while generated fragments vary.'),
        ('2026-10-01-office-open-colour','arrival-glass.png','Open colour: production-museum arrangement. A route passes between coloured sheets.')]:
        path = ROOT / 'doc/book/iterations' / folder / filename
        # Only real captures that exist; no invented image or placeholder.
        if path.exists():
            b.append(f'<figure><a href="{url(rel(path))}"><img loading="lazy" src="{url(rel(path))}" alt="{esc(caption)}"></a><figcaption>{esc(caption)} '
                     f'{link(f"doc/book/iterations/{folder}/index.html", "Earlier report ↗")}</figcaption></figure>')
    b += ['</div><p class="meta">Earlier captures, retained as illustrations. Their earlier tests do not certify every candidate in this atlas.</p></section>',
          '<section id="atlas" class="band"><h2>All 100 matches</h2><p>Choose a status, then open an artist. '
          'Browser Find searches the full text. Proposed studies are original translations, not reconstructions of the referenced works.</p>']
    for key in ['all', *STATUS]:
        b.append(f'<input class="filter-input" type="radio" name="judgement" id="{key}" {"checked" if key == "all" else ""}>')
    b.append('<div class="filters" aria-label="Filter matches by judgement"><label for="all">All · 100</label>')
    for key, (label, definition) in STATUS.items():
        b.append(f'<label for="{key}">{esc(label)} · {meta["judgements"][key]}</label>')
    b += ['</div><details><summary>What these judgements mean</summary>']
    for key, (label, definition) in STATUS.items():
        b.append(f'<p><span class="pill {key}">{esc(label)}</span> {esc(definition)}</p>')
    b += ['<p>“Define the encounter” is not a lower grade. It means there is no honest automatic conversion from the reference to an algorithm.</p></details><nav>']
    cats = list(dict.fromkeys(m['category']['id'] for m in matches))
    for cat in cats:
        title = next(m['category']['title'] for m in matches if m['category']['id'] == cat)
        b.append(f'<a href="#cat-{cat}">{cat} · {esc(title.split(" / ")[0].title())}</a>')
    b.append('</nav><div class="categories">')
    for cat in cats:
        group = [m for m in matches if m['category']['id'] == cat]
        b.append(f'<section class="category" id="cat-{cat}"><h3><small>{cat}</small><br>{esc(group[0]["category"]["title"].title())}</h3>')
        for m in group:
            b += [f'<details class="entry {m["judgement"]}" id="{m["id"]}"><summary><span class="artist">{esc(m["artist"])}</span>'
                  f'<span class="pill {m["judgement"]}">{esc(STATUS[m["judgement"]][0])}</span>'
                  f'<span class="operation">{esc(m["provided_operation"])}</span></summary><div class="entry-body">',
                  '<p class="links">' + ''.join(f'<a href="#profile-{p}">{esc(profiles[p]["title"])}</a>' for p in m['profiles']) + '</p>',
                  '<p><b>Existing candidates</b></p><p class="links">' + ''.join(f'<a href="#artifact-{a}">{esc(a)}</a>' for a in m['artifacts']) + '</p>',
                  f'<p><b>Next study.</b> {esc(m["smallest_next_study"])}</p>',
                  f'<p><b>Keep in view.</b> {esc(m["critical_remainder"])}</p>',
                  f'<p class="meta"><a href="{esc(m["provided_image_search"], quote=True)}" target="_blank" rel="noopener">Supplied image search ↗</a> · '
                  'a research lead, not a verified work attribution</p></div></details>']
        b.append('</section>')
    b += ['</div></section><section id="capacity" class="band"><h2>The making ladder</h2>',
          '<p><b>An encounter may appear before its construction lesson.</b> The making gate below is the latest prerequisite '
          'in the declared capability graph. Borrowed components let a student act earlier; rebuilding those components needs more. '
          'The ladder’s nodes are currently marked proposed, so this is a planning guide, not a claim that all tutorials are finished.</p>',
          '<p><a href="/tutorial-lineage">Open the project’s full capability ladder ↗</a></p>']
    for key, p in profiles.items():
        b += [f'<details id="profile-{key}"><summary><span class="artist">{esc(p["title"])}</span>'
              f'<span class="meta">Making gate: {esc(p["build_gate_sequence"])}</span></summary><div class="entry-body">',
              f'<p><b>Existing operation.</b> {esc(p["operation"])}</p><p><b>Limit.</b> {esc(p["limit"])}</p>',
              f'<p><b>Proposed encounter home.</b> {esc(p["proposed_home"])}</p><p><b>Carry these capabilities.</b></p><ul>']
        for n in p['capabilities']:
            node = nodes[n]
            b.append(f'<li><a href="/tutorial-lineage#node={n}">{esc(node["label"])}</a> — {esc(node["make"])}</li>')
        b += ['</ul>', f'<p><b>Observable test.</b> {esc(p["probe"])}</p>',
              '<p class="links">' + ''.join(f'<a href="#artifact-{a}">{esc(a)}</a>' for a in p['artifacts']) + '</p>',
              '<details><summary>Transitive prerequisite IDs</summary><p><code>' + ', '.join(p['prerequisite_closure']) + '</code></p></details></div></details>']
        if key == 'hinge':
            b.append('<p class="note">Follow-up study: <a href="/book-review/doc/book/iterations/2026-10-01-clark-a-pose-left/index.html">A pose left, after Clark</a>. '
                     '29 native desktop checks; a corrected pointer direction, release comparison and two paths to the same pose. XR and physical contact remain separate work.</p>')
    b += ['</section><section id="evidence" class="band"><h2>What exists, and where</h2>',
          f'<p>Checked {meta["maps_scanned"]} map references in {meta["sequences_scanned"]} active spine sequences. '
          f'{meta["candidate_artifacts_with_direct_spine_tokens"]} of the {meta["candidate_artifacts"]} candidates have direct placement tokens there. '
          'A registry entry or declared sequence does not establish installation. Generated, nested, branch and dynamic placements are outside this direct-token scan.</p>']
    for key, a in artifacts.items():
        ps = a['direct_spine_placements']
        loc = ', '.join(dict.fromkeys(p['map'] for p in ps)) if ps else 'No direct active-spine token found'
        b += [f'<details id="artifact-{key}"><summary><span class="artist">{esc(key)}</span><span class="operation">{esc(loc)}</span></summary><div class="entry-body">',
              '<p>' + link(a['scene'], 'Scene') + ' · ' + ' · '.join(link(r, 'Registry') for r in a['registries']) + '</p>']
        if a['duplicate_note']:
            b.append('<p class="note">' + esc(a['duplicate_note']) + '</p>')
        for e in a['evidence']:
            b.append(f'<p><a href="{e["snapshot"]}#L{e["line"]}">{esc(e["path"])}:{e["line"]}</a>'
                     f'<br><span class="meta">{esc(e["marker"])} · SHA-256 {e["sha256"][:16]}…</span></p>')
        if ps:
            b.append('<div class="table-wrap"><table><tr><th>Sequence / map</th><th>Row, column (zero based)</th><th>Actual token</th></tr>')
            for place in ps:
                b.append(f'<tr><td>{esc(place["sequence"])}<br>{link(place["path"], place["map"])}</td>'
                         f'<td>{esc(str(place["address"]))}</td><td><code>{esc(place["token"])}</code></td></tr>')
            b.append('</table></div>')
        else:
            b.append('<p>Registered candidate or companion. Check the scene and fit it to an actual room before describing it as installed.</p>')
        b += ['<p class="meta">Source evidence only in this pass. Behaviour, controls, collision and performance need a focused runtime test before a new installation.</p></div></details>']
    b += ['</section><section id="limits" class="band"><h2>Where the names overpromise</h2><div class="columns">']
    for title, text in [
        ('Kitbash station', 'The registered kitbash_station scene contains only an empty Node3D. The found_object_assembler has actual pickup and placement code; it is the useful starting point.'),
        ('Mirror', 'A metallic surface is not proof of a reflected camera view. super_drag_mirror implements a planar camera and frustum; the generic mirror prop does not.'),
        ('Fold wall', 'Its staged vertex formula can show a fold. It cannot establish that a sheet settled under gravity. Use a cloth solver when forces are the question.'),
        ('GAN room', 'The inspected display animates roles and illustrative loss values. It does not train or run a model. Dataset, inference and provenance work are separate capabilities.')]:
        b.append(f'<article class="card"><h3>{title}</h3><p>{esc(text)}</p></article>')
    b += ['</div><p class="note"><b>Audio needs the same distinction.</b> SoundBox has a real spatial playback path via SoundBank. '
          'The separate timeline captures samples but has no captured-audio replay; its function named FFT averages time-domain samples. '
          '<a href="#profile-sound">See the audio capacity and missing work ↗</a></p></section><section class="band"><h2>Keep this usable</h2><p>Pick one row, keep one variable fixed, '
          'change one relation, and record what happened. Add only the artifact needed to make that relation perceptible. '
          'Then write the short encounter and its making exercise as distinct texts.</p>',
          '<p class="links">' + link('doc/book/artist-capacity/MATCHES.md', 'All matches · Markdown') +
          link('doc/book/artist-capacity/matches.json', 'Matches · JSON') +
          link('doc/book/artist-capacity/artifact-capacities.json', 'Capacity & placement evidence · JSON') +
          link('doc/book/artist-capacity/SOURCE-INDEX.txt', 'Your original index') +
          link('doc/book/artist-capacity/source-hashes.json', 'Source hashes') + '</p>',
          '<p class="meta">100 entries retain Dan Graham in two supplied categories. No artists were silently deduplicated. '
          'Rebuilt from the working checkout on 2 October 2026. Rebuild after registry, scene, ladder or map changes; revisit the editorial judgements when the evidence changes.</p></section>']
    (REVIEW / 'index.html').write_text(shell('Artist operations × existing capacity — Ada', ''.join(b)), encoding='utf-8')
    for path, (slug, text) in all_sources.items():
        lines = ''.join(f'<span class="source-line" id="L{i}"><a href="#L{i}">{i:4}</a>{esc(t)}</span>'
                        for i, t in enumerate(text.splitlines(), 1))
        body = f'<p><a href="../index.html#evidence">← Atlas</a> · {link(path,"Live source")}</p><h2>{esc(path)}</h2>' + \
            f'<p class="meta">Source snapshot {DATE} · SHA-256 {INPUTS[path]}</p><pre>{lines}</pre>'
        (REVIEW / 'sources' / slug).write_text(shell(path, body, extra='class="source"'), encoding='utf-8')


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    main()
