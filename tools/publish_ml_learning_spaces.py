"""Publish actual museum renders and scoped checks for the separate learning bay."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-learning-spaces-in-the-map'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Perception/learning_spaces'


def receipt(path):
    data = json.loads(path.read_text(encoding='utf-8'))
    assert data.get('passed', True) and not data['failures'], path
    assert data['checks'] and all(c['passed'] for c in data['checks']), path
    return data


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    museum = receipt(RUN / 'report.json')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    for name in ['overview', 'passage', 'dance', 'learning', 'phrase']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN.parent / 'spaces_before/before.png', OUT / 'before.png')
    suites = [('vogue-a-phrase-of-your-own', 'dance'), ('teach-a-sphere', 'pose'),
              ('teach-a-sphere-phrase', 'phrase'), ('sphere-check-your-intention', 'check')]
    total = 0
    for folder, label in suites:
        path = ROOT / f'doc/book/iterations/2026-10-11-{folder}/tests.json'
        total += len(receipt(path)['checks'])
        shutil.copy2(path, OUT / f'{label}-tests.json')
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR:' not in log
    (OUT / 'museum-diagnostics.json').write_text(json.dumps([s for s in log.splitlines() if s.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    sources = ['commons/maps/ML_Perception/map_data.json', 'commons/data/museum/em_plan.json',
               'commons/artifacts/vogue_timeline/vogue_timeline.gd',
               'commons/artifacts/vogue_timeline/movement_learning.gd',
               'tools/probes/ml_learning_spaces.gd', 'tools/build_vogue_timeline.py',
               'tools/publish_ml_learning_spaces.py']
    (OUT / 'source-register.json').write_text(json.dumps({p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}, indent=2), encoding='utf-8')
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A space for each encounter · Endless Museum</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#111722;color:#edeff4;font:18px/1.65 system-ui,sans-serif}}main{{max-width:1240px;margin:auto;padding:42px 24px 80px}}h1{{font-size:clamp(40px,6vw,78px);line-height:1.08;letter-spacing:-.04em}}h2{{margin-top:2em}}.lead{{font-size:25px;max-width:950px}}.kicker,a{{color:#9cd8eb}}.kicker{{text-transform:uppercase;letter-spacing:.12em;font-size:13px}}figure{{margin:32px 0}}img{{width:100%;display:block;border-radius:6px}}figcaption{{font-size:14px;color:#bbc3d0;margin-top:9px}}.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}.box{{padding:24px;background:#1d2735;border:1px solid #3c4b60}}.box h2{{margin-top:0}}code{{font-size:.85em}}@media(max-width:760px){{.grid{{grid-template-columns:1fr}}}}</style></head><body><main>
<p class="kicker">Endless Museum · ML_Perception · 11 October 2026</p><h1>A space for each encounter</h1>
<p class="lead">The dance and the sphere-learning station have their own bays in the actual museum map. A wall separates their movement areas; a wide passage connects them.</p>
<figure><img src="overview.png" alt="Overhead Godot render of the dance floor and separate sphere teaching bay"><figcaption>Actual museum render. Dance on the left; teaching on the right. The route runs around the end of the partition.</figcaption></figure>
<div class="grid"><section class="box"><h2>Dance</h2><p>The familiar 32-beat phrase keeps its open floor, airborne hand paths and nearby controls. The learning console no longer stands beside the dancer.</p></section><section class="box"><h2>Teach a sphere</h2><p>The gold-edged bay holds one sphere, its controls and display. Move from poses to height, timed phrases and checking your intention here. The lessons share the same object.</p></section></div>
<h2>Before and after</h2><div class="grid"><figure><img src="before.png" alt="Before: teaching console crowds the left side of the dance floor"><figcaption>Before: the teaching board and console overlap the dance setting.</figcaption></figure><figure><img src="passage.png" alt="After: partition separates dance from learning in the same map"><figcaption>After: separate approaches, linked by a three-metre passage.</figcaption></figure></div>
<h2>At the teaching station</h2><figure><img src="learning.png" alt="Player-height view of the sphere teaching board in its own museum bay"><figcaption>Enter the TEACH / TEST / REVISE bay. The controls remain close to the sphere; the floor gives room to step back for a take.</figcaption></figure>
<figure><img src="phrase.png" alt="Two-hand phrase controls and sphere display in the new bay"><figcaption>The same station in PHRASE mode. Instructions wrap within the main board so the adjacent sphere display does not hide them.</figcaption></figure>
<h2>The dance keeps its floor</h2><figure><img src="dance.png" alt="Dance floor without the learning station crowding it"><figcaption>Reference paths and dance controls remain together in their original bay.</figcaption></figure>
<h2>Checked in Godot</h2><p><strong>{len(museum['checks'])} museum checks and {total} lesson checks passed.</strong> The museum probe checks floor support, a standing-body collision shape, three lanes through the passage, the partition, lesson switching and preservation of the sphere and learner objects.</p>
<p>A supplied XR head and two controller poses also exercise the real capture button in the new bay. A complete pose is recorded in head-relative coordinates, even though the player is outside the dance's proximity range. This is a synthetic runtime test. Headset comfort and controller reach still need your play test.</p>
<p>The move preserves the earlier perception exhibits and the sphere's datasets and save paths. The map is now 24 × 10 cells; the two activity anchors are about 8.25 metres apart. The existing audio UID, Jolt and older museum diagnostics are recorded below; these checks do not establish an error-free whole project.</p>
<p><a href="museum-tests.json">Museum checks</a> · <a href="dance-tests.json">Dance</a> · <a href="pose-tests.json">Pose</a> · <a href="phrase-tests.json">Phrase</a> · <a href="check-tests.json">Intention checks</a> · <a href="museum-diagnostics.json">Diagnostics</a> · <a href="source-register.json">Source hashes</a></p>
<p><a href="../2026-10-11-sphere-check-your-intention/index.html">The carried lesson: check your intention</a></p>
</main></body></html>'''
    (OUT/'index.html').write_text(page, encoding='utf-8')
    print(f'Published: {len(museum["checks"])} museum + {total} lesson checks. {OUT}')


if __name__ == '__main__':
    main()
