"""Publish the authorized PG editorial and room revisions with dated evidence."""
from pathlib import Path
import copy
import hashlib
import html
import json
import re
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-procedural-generation-revised'
C = R / 'doc/book/iterations/2026-10-09-procedural-generation-complete-readings'
KEYS = ['PG_Branching_Growth', 'PG_Percolation_Network', 'PG_Caves_Mazes',
        'PG_Sculpted_Forms', 'PG_Mirrored_Patterns']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode('utf-8'))


def dump(path, value):
    write(path, json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def map_semantics(value):
    # Empty string and a single space both mean no interactable. The intermediate
    # desk move left five whitespace-only cells; they have no scene consequence.
    result = copy.deepcopy(value)
    result['layers']['interactables'] = [
        ['' if isinstance(token, str) and not token.strip() else token for token in line]
        for line in result['layers']['interactables']]
    return result


baseline = json.loads((O / 'before.json').read_text())
editorial = json.loads((O / 'editorial-checks.json').read_text())
placements = json.loads((O / 'placements.json').read_text())
walkthrough = json.loads((O / 'walkthrough-checks.json').read_text())
latest = json.loads((C / 'latest-run.json').read_text())
assert latest['passed'] and latest['complete'] and walkthrough['passed']
for item in editorial['sources']:
    assert sha(R / item['source']) == item['after_sha256']
    assert sha(O / 'before' / item['source']) == item['before_sha256'] == baseline[item['source']]

plan_path = 'commons/data/museum/em_plan.json'
old_plan = json.loads((O / 'before' / plan_path).read_text())
new_plan = json.loads((R / plan_path).read_text())
rooms = []
current_sources = {}
for key in KEYS:
    relative = f'commons/maps/{key}/map_data.json'
    expected = json.loads((O / 'before' / relative).read_text())
    row = copy.deepcopy(next(p for p in old_plan['plans'] if p.get('map') == key))
    changes = [c for c in placements['changes'] if c['map'] == key]
    for c in changes:
        x, z = c['from']; nx, nz = c['to']
        token = expected['layers']['interactables'][z][x]
        assert token.startswith(c['token'])
        assert not expected['layers']['interactables'][nz][nx].strip()
        expected['layers']['interactables'][z][x] = ' '
        expected['layers']['interactables'][nz][nx] = 'dome:0:0:0.55' if c['token'] == 'dome' else token
        a = next(a for a in row['artifacts'] if a['token'] == c['token'])
        a['cell'] = c['to'].copy(); a['tile_cell'] = c['to'].copy(); a['ruled']['cell'] = c['to'].copy()
        if 'scale' in c: a['scale'] = c['scale']
    assert map_semantics(json.loads((R / relative).read_text())) == map_semantics(expected), ('unexpected map change', key)
    actual_row = next(p for p in new_plan['plans'] if p.get('map') == key)
    assert actual_row == row, ('unexpected plan row change', key)
    current_sources[relative] = sha(R / relative)
    reports = {}
    for phase in ['before', 'after']:
        source = R / 'ada_run/encounter_pilot' / key / ('review-' + phase)
        report = json.loads((source / 'report.json').read_text())
        manifest = json.loads((source / 'source_manifest.json').read_text())
        assert report['passed'] and all(c['passed'] for c in report['checks']), (key, phase)
        assert manifest['sources'][relative] == (baseline[relative] if phase == 'before' else sha(R / relative))
        if phase == 'after':
            assert manifest['no_bridges']
            obs = report['observations']
            assert not obs['entry'].get('invalid', False) and not obs['exit'].get('invalid', False)
            assert obs['route']['clear'] and not obs['route']['unsupported']
            assert not re.search(r'^SCRIPT ERROR:|Parse Error:', (source / 'engine.log').read_text(errors='replace'), re.M)
        target = O / 'museum' / key / phase
        target.mkdir(parents=True, exist_ok=True)
        for name in ['report.json', 'source_manifest.json', 'engine.log', 'stdout.log', 'spec.json']:
            shutil.copyfile(source / name, target / name)
        stems = ['entrance', 'above'] + (['dome'] if key == 'PG_Sculpted_Forms' else []) + (['desk'] if phase == 'after' else [])
        for stem in stems:
            shutil.copyfile(source / (stem + '.png'), target / (stem + '.png'))
        reports[phase] = report
    if key == 'PG_Sculpted_Forms':
        assert reports['after']['observations']['dome']['contained']
    rooms.append({'map': key, 'changes': changes, 'before_checks': len(reports['before']['checks']),
                  'after_checks': len(reports['after']['checks']),
                  'route_samples': reports['after']['observations']['route']['samples'],
                  'observations': reports['after']['observations'], 'plan_row': actual_row})

before_count = sum(r['before_checks'] for r in rooms)
after_count = sum(r['after_checks'] for r in rooms)
assert (before_count, after_count) == (32, 66)
spatial = {'passed': True, 'sources': current_sources, 'rooms': rooms,
           'before_diagnostic_checks': before_count, 'after_checks': after_count,
           'only_declared_map_and_plan_changes': True,
           'empty_interactable_whitespace_normalized_for_comparison': True,
           'scope': 'Five native halls: actual entrance and exit records, sampled standing-capsule route with floor support, supplied desktop entry movement and real pointer action at each relocated desk. Four dome states retained. No full portal traversal or physical headset test.',
           'capture_note': 'Matched camera positions, FOV and exposure. After captures disable command bridges and dynamic NatureRenderer; before captures used the live environment. Lighting and unrelated moving objects are not a controlled comparison.'}
dump(O / 'spatial-validation.json', spatial)

report = '''# Procedural Generation — the revisions

The seven-hall route stays: **Evaluate → Guide → Branch → Connect → Carve → Sample → Copy**. The revision makes its shared practice explicit: keep an input or witness, change one rule, compare the result, and name what the representation does not retain.

## What changed in the writing

- **All seven tutorials:** a short “Keep, change, compare” passage identifies the retained material, the available decision and an observable difference. Evolution introduces this practice as the continuation of L-systems' description and reader.
- **Space Colonization:** follow one site's decision through eligibility, request assignment, combined direction and a fixed-length step. New children wait until the next generation to answer.
- **Sculpted Forms:** follow a single centre through a local coordinate, cell address, occupied neighbourhood and exposed face. The small worked example produces 125 occupied cells; its selected +x face lies at x = 1.25. A native test checks these values against the printed code.
- **The first two reflections:** remove repeated control instructions while retaining the encounters and their limits. Evolution is now 494 words, down from 788; Colonization is 590, down from 937. Their computational qualifications, markers and reference remain.

All 22 printed learner files are unchanged. The additions explain the existing constructions; they introduce no hidden helper, new generator or new required artifact.

## What changed in the museum

The five workshops from Branching Growth onward stood on their authored arrival routes. Each is now five metres to the left and two metres farther into its hall, with a clear standing position in front of its controls. The actual entrance and exit records are valid. The tested route starts at the arrival marker, rather than beside the obstruction.

The Sculpted Forms dome moved one metre sideways and one metre farther in. Its local instance is uniformly scaled to 0.55. Its 11 × 11 metre stock footprint fits inside the room, with a passage beside it. Its blank, core, section and cast states still work. The Boolean construction and the student's sampling program are unchanged.

## Evidence

- **200 current learner checks pass** across the seven complete printed programs, their guided edits, faulty controls and supplied XRTools poses.
- **7 new checks pass** for the centre-to-face walkthrough.
- **66 new room checks pass** across the five repaired halls. These include entrance and exit validation, sampled capsule clearance with floor support, actual supplied desktop movement from the entrance, pointer operation of the relocated desk, camera checks and the dome's four states.
- **32 before checks** reproduce the original obstructions and oversized footprint. These are diagnostic confirmations, not successful passage tests.

The room images below are native Godot captures. Before and after share cameras, FOV and exposure. After captures disable live command bridges and the dynamic environmental controller; lighting and moving exhibits can therefore differ. Compare placements and clearance, not illumination. One earlier capture was interrupted by an external scene-reload command; its log is retained, and the isolated captures were rerun.

These are author-led checks. They do not establish independent learner understanding, a complete portal-to-portal walk, physical-headset comfort or Quest performance. The earlier 231 museum checks remain dated hall evidence in the complete review edition.
'''
write(O / 'REPORT.md', report)
for relative in ['tools/probes/pg_review_passages.gd', 'tools/probes/pg_review_walkthrough.gd',
                 'tools/probes/transformation_encounters.gd', 'tools/run_encounter_probe.py']:
    shutil.copyfile(R / relative, O / Path(relative).name)
write(O / 'RUN.md', '''# Re-run the checks

In the prepared AdaResearch project, run `python -X utf8 tools/test_procedural_sequence.py` for all seven printed programs. The latest timestamped run is included in the complete review edition.

For each repaired hall, run:

```text
python -X utf8 tools/run_encounter_probe.py PG_Sculpted_Forms --sequence proceduralgeneration --render --output-tag review-after --probe tools/probes/pg_review_passages.gd --spec doc/book/iterations/2026-10-09-procedural-generation-revised/after-spec.json --no-bridges
```

Replace the hall name with Branching Growth, Percolation Network, Caves/Mazes or Mirrored Patterns' PG folder name as appropriate. This replaces that output tag's receipts; use another tag to preserve this run. The runner expects the existing project, XRTools and local Godot executable. `--no-bridges` isolates the process from live commands and disables NatureRenderer's dynamic environmental controller; it does not change a project setting.

The standalone new prose example uses `tools/probes/pg_review_walkthrough.gd` through Godot's `--headless --path <prepared-project> --script` option. Its receipt is `walkthrough-checks.json`.

The archived before views document the prior layout. Re-running with the current map will not reproduce them. Do not restore the entire old museum plan over concurrent project work.
''')

css = '''*{box-sizing:border-box}body{margin:0;background:#efede7;color:#25282b;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1480px;margin:auto;padding:28px 4vw}h1{font-size:clamp(2.4rem,5vw,4.6rem);line-height:1.1;font-weight:500}h2{line-height:1.2}nav,.meta,figcaption{font:14px/1.5 system-ui}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#365f71}.reading{max-width:940px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:12px 0}img{width:100%;height:auto}figcaption{padding:8px 0;color:#515853}section{padding:32px 0;border-top:1px solid #bdbcb5}summary{cursor:pointer;font:16px/1.5 system-ui;padding:10px;background:#e2e0d8}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:13px/1.5 Consolas,monospace;background:#faf9f4;padding:20px}.badge{font:16px/1.5 system-ui;padding:16px;background:#dae1da}@media(max-width:800px){.pair{grid-template-columns:1fr}}'''
parts = ['<div class="reading">', markdown.markdown(report), '</div>',
         '<p class="badge">200 learner + 7 walkthrough + 66 room checks pass. Before/after geometry below.</p>']
for room in rooms:
    key = room['map']; title = key.removeprefix('PG_').replace('_', ' ')
    parts.append(f'<section id="{key}"><h2>{html.escape(title)}</h2><p class="meta">{room["after_checks"]} after checks · {room["route_samples"]} route samples · <a href="museum/{key}/after/report.json">Native receipt</a></p>')
    for stem, label in [('entrance', 'From the entrance'), ('above', 'From above')] + ([('dome', 'The dome footprint')] if key == 'PG_Sculpted_Forms' else []):
        parts.append(f'<h3>{label}</h3><div class="pair">')
        for phase in ['before', 'after']:
            caption = f'{phase.title()} — {title}, {label.lower()}.'
            parts.append(f'<figure><a href="museum/{key}/{phase}/{stem}.png"><img loading="lazy" src="museum/{key}/{phase}/{stem}.png" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>')
        parts.append('</div>')
    parts.append(f'<details><summary>Control approach and source changes</summary><img loading="lazy" src="museum/{key}/after/desk.png" alt="Accessible workshop controls in {title}"><pre>{html.escape(json.dumps(room["changes"], indent=2))}</pre></details></section>')
parts.append('<section><h2>Exact writing changes</h2>')
for item in editorial['sources']:
    p = Path(item['source']); diff = f'diffs/{p.parent.name}/{p.name}.diff'
    parts.append(f'<details><summary>{p.parent.name} · {p.name}</summary><pre>{html.escape((O / diff).read_text(encoding="utf-8"))}</pre></details>')
parts.append('</section>')
nav = '<nav><a href="../2026-10-09-procedural-generation-complete-readings/parallel.html">Full facing texts</a><a href="../2026-10-09-procedural-generation-complete-readings/procedural-generation-review.zip">Complete review ZIP</a><a href="REPORT.md">Report</a><a href="RUN.md">Re-run</a><a href="spatial-validation.json">Room evidence</a></nav>'
write(O / 'index.html', '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Procedural Generation — revised</title><style>' + css + '</style><header><p class="meta">Endless Museum · 9 October 2026</p>' + nav + '</header><main>' + ''.join(parts) + '</main><footer>Native museum captures. Author-led tests; physical-headset testing remains open.</footer></html>')
dump(O / 'validation.json', {'passed': True, 'editorial_sources': 9, 'printed_code_unchanged': True,
    'fresh_learner_checks': 200, 'fresh_run': latest['directory'], 'walkthrough_checks': 7,
    'native_after_checks': after_count, 'native_before_diagnostics': before_count,
    'only_declared_placement_changes': True, 'new_physical_headset_test': False})
print(json.dumps({'report': str(O / 'index.html'), 'after_checks': after_count}))
