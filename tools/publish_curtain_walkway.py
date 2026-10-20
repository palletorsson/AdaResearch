"""Publish actual museum captures and scoped evidence for the curtain walkway."""
from pathlib import Path
import hashlib
import html
import json
import shutil
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-curtains-a-colour-walk'
RUN = ROOT / 'ada_run/encounter_pilot/SoftBodies_Carusell/curtain-walkway'
REGRESSION = ROOT / 'ada_run/encounter_pilot/SoftBodies_Cloth_Physics/curtain-fit-regression'


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    result = read_json(RUN / 'report.json')
    regression = read_json(REGRESSION / 'report.json')
    assert result['passed'] and regression['passed']
    assert any(c['name'] == 'All curtain checks completed' and c['passed'] for c in result['checks'])
    for folder in [RUN, REGRESSION]:
        log = (folder / 'engine.log').read_text(encoding='utf-8', errors='replace')
        assert not any(s in log for s in ['SCRIPT ERROR', 'Parse Error', 'without a physics space'])

    (OUT / 'assets').mkdir(exist_ok=True)
    (OUT / 'evidence').mkdir(exist_ok=True)
    for name in ['above', 'walkway', 'entrance', 'different-hems', 'rear-fit', 'parting']:
        shutil.copy2(RUN / f'{name}.png', OUT / 'assets' / f'{name}.png')
    previous = ROOT / 'doc/book/iterations/2026-10-09-carousel-the-support-moves/assets'
    for name in ['above', 'fixed-curtain']:
        shutil.copy2(previous / f'{name}.png', OUT / 'assets' / f'before-{name}.png')
    for source, prefix in [(RUN, 'walkway'), (REGRESSION, 'cloth-regression')]:
        for name in ['report.json', 'engine.log', 'source_manifest.json']:
            shutil.copy2(source / name, OUT / 'evidence' / f'{prefix}-{name}')

    before = read_json(OUT / 'before/hashes.json')
    for file in ['tutorial.md', 'final.md', 'technical.md']:
        key = f'commons/maps/SoftBodies_Carusell/{file}'
        assert hashlib.sha256((ROOT / key).read_bytes()).hexdigest() == before[key]
    plan = read_json(ROOT / 'commons/data/museum/em_plan.json')
    row = next(r for r in plan['plans'] if r['map'] == 'SoftBodies_Carusell')
    m = read_json(ROOT / 'commons/maps/SoftBodies_Carusell/map_data.json')
    selected = [a for a in row['artifacts'] if a['token'] == 'cloth_straps' and a.get('config', {}).get('walkway')]
    assert len(selected) == 5
    for a in selected:
        x, z = a['cell']
        token = m['layers']['interactables'][z][x]
        for k, v in a['config'].items():
            assert f'{k}:{str(v).lower()}' in token
    (OUT / 'evidence/placement.json').write_text(json.dumps(selected, indent=2), encoding='utf-8')
    sources = ['algorithms/softbodies/cloth_straps/cloth_straps.gd',
               'algorithms/softbodies/cloth_straps/cloth_straps.tscn',
               'algorithms/softbodies/cloth_straps/README.md',
               'commons/maps/SoftBodies_Carusell/map_data.json',
               'tools/probes/curtain_walkway.gd']
    hashes = {}
    for file in sources:
        src = ROOT / file
        dest = OUT / 'sources' / file
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        hashes[file] = hashlib.sha256(src.read_bytes()).hexdigest()
    (OUT / 'evidence/source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')

    n, q = len(result['checks']), len(regression['checks'])
    obs = result['observations']
    summary = f'''# Curtains — a colour walk

Five soft curtains now form a procession beside the carousel in Endless Museum.
The original rear doorway is retained and its cloth also fits its frame.

- Coral: a full top edge, free lower cloth.
- Rose: two pinned top corners per strip.
- Violet: one top corner, alternating left and right.
- Blue: alternating long and short strips.
- Mint: short central strips form an opening.

Each gate has ten strips, a dark frame, readable captions on both sides and a flat
colour runner. The first full-length curtain is three metres high. The top pins
meet the crossbar underside; side posts leave two centimetres of clearance.
Length variation changes the hem, while all top attachments stay on the beam.

The old artifact duplicated a scaled live SoftBody3D template. It now constructs
each mesh at its intended rest size. Existing lesson subdivision settings and
controls are preserved. Support-only changes keep the same simulated bodies.

{n} native walkway checks and {q} existing Cloth Physics checks passed. A finite
colliding capsule crossed all five gates, finishing at map z={obs['capsule_end'][2]:.2f}.
Cloth moved during contact; the largest measured attachment error after passage
was {obs['maximum_anchor_error']:.6f} metres. The earlier lesson still supports its
real pointer controls, corner selection, release, rebuild and carried PointBody.
These are supplied native physics/input tests, not a headset or Quest benchmark.

No new script errors or missing-physics-space errors occurred. The logs retain an
unrelated pre-existing unrecognized UID warning. Tutorial, final and technical
texts remain byte-identical; this is an installed museum variation around the
existing moving-support lesson. The current map and museum-plan placements match.

Replay: `python tools/run_encounter_probe.py SoftBodies_Carusell --sequence softbodies
--render --no-bridges --output-tag curtain-walkway --probe tools/probes/curtain_walkway.gd`
'''
    (OUT / 'REPORT.md').write_text(summary, encoding='utf-8')
    css = '''*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#29232e;font:18px/1.6 system-ui,sans-serif}main{max-width:1300px;margin:auto;padding:44px 30px 90px}header{max-width:780px;margin-bottom:34px}h1{font-size:clamp(36px,5vw,68px);line-height:1.08;letter-spacing:-.045em;margin:14px 0}h2{font-size:28px;margin:50px 0 18px}p{max-width:850px}small,.eyebrow{font-size:13px;letter-spacing:.1em;text-transform:uppercase}img{display:block;width:100%;height:auto;border-radius:5px}figure{margin:0}figcaption{padding:12px 0 28px;font-size:15px;color:#655968}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}ul{padding-left:22px}a{color:#752955}table{border-collapse:collapse;width:100%;margin:24px 0}td,th{text-align:left;border-bottom:1px solid #cec4cc;padding:10px}th{font-size:13px;text-transform:uppercase}.receipt{border-top:3px solid #ae6195;margin-top:45px;padding-top:12px}@media(max-width:700px){.pair{grid-template-columns:1fr}main{padding:24px 16px}}'''
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Curtains — a colour walk</title><style>{css}</style><main>
<header><div class="eyebrow">Endless Museum · Carusell · 9 October 2026</div><h1>Curtains.<br>A colour walk.</h1><p>Five thresholds, five ways of hanging. Pass through the colour; feel what each attachment allows.</p></header>
<figure><img src="assets/walkway.png" alt="Five coloured curtains installed in the carousel hall"><figcaption>Actual museum capture. The procession occupies the side of the court, with a route around it.</figcaption></figure>
<table><tr><th>Colour</th><th>Attachment or hem</th><th>What changes</th></tr>
<tr><td>Coral</td><td>Top edge</td><td>The whole upper edge stays fixed.</td></tr><tr><td>Rose</td><td>Two corners</td><td>The upper edge can bow between its ends.</td></tr><tr><td>Violet</td><td>One corner</td><td>Alternate strips pivot from opposite sides.</td></tr><tr><td>Blue</td><td>Long / short</td><td>The same support carries two lengths.</td></tr><tr><td>Mint</td><td>An opening</td><td>A shorter centre leaves space for the body.</td></tr></table>
<figure><img src="assets/different-hems.png" alt="Alternating and arch-shaped cloth hems"><figcaption>One shared beam height; different edges below it. These are live soft bodies, not animated flat panels.</figcaption></figure>
<h2>The frame and the cloth agree</h2><div class="pair"><figure><img src="assets/before-fixed-curtain.png" alt="Old mismatched cloth protruding beyond its frame"><figcaption>Before: the duplicated template did not fit its doorway.</figcaption></figure><figure><img src="assets/rear-fit.png" alt="The retained rear curtain fitted within its frame"><figcaption>After: the retained rear doorway. Top pins meet the beam; side edges fit between the posts.</figcaption></figure></div>
<h2>Inside the passage</h2><div class="pair"><figure><img src="assets/entrance.png" alt="Approaching the first curtain at eye height"><figcaption>At eye height: walk into the first curtain.</figcaption></figure><figure><img src="assets/parting.png" alt="Cloth displaced by a colliding test body"><figcaption>Native contact test: the capsule is invisible in this capture; its collider displaces the fabric.</figcaption></figure></div>
<h2>The room from above</h2><div class="pair"><figure><img src="assets/before-above.png" alt="Earlier arrangement from above"><figcaption>Before: one isolated curtain in the front court.</figcaption></figure><figure><img src="assets/above.png" alt="Five curtains arranged beside the carousel from above"><figcaption>After: a continuous colour walk beside the moving-support exhibit.</figcaption></figure></div>
<section class="receipt"><h2>What was checked</h2><p><strong>{n} walkway checks + {q} Cloth Physics checks passed.</strong> A colliding capsule passed all five curtains; fabric moved and pinned tops held. Existing release, rebuild, corner selection and learner PointBody interactions still pass.</p><p>Captured in the running museum with Jolt. Physical headset comfort and Quest performance still need a visit. The lesson texts and their learner code have not been rewritten.</p><p><a href="REPORT.md">Report</a> · <a href="evidence/walkway-report.json">Walkway checks</a> · <a href="evidence/cloth-regression-report.json">Earlier lesson checks</a> · <a href="evidence/placement.json">Placements</a></p></section></main></html>'''
    (OUT / 'index.html').write_text(page, encoding='utf-8')

    class Links(HTMLParser):
        def handle_starttag(self, tag, attrs):
            for key, value in attrs:
                if key in ['src', 'href'] and value:
                    assert (OUT / value).is_file(), value

    Links().feed(page)
    print(f'Published {OUT}; {n} + {q} checks; all local links exist; book texts unchanged.')


if __name__ == '__main__':
    main()
