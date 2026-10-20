"""Publish native doorway evidence; refresh only this museum hall's snapshots."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-a-doorway-reads-your-approach'
RUN = R / 'ada_run/encounter_pilot/Shader_05_Patterns/fuzzy-doorway'
KEY = 'shaders|shader 05 patterns'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def write(p, data):
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def backup(p):
    target = O / 'before' / p.relative_to(R)
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)


def main():
    receipt = read(RUN / 'report.json')
    assert receipt['passed'] and all(c['passed'] for c in receipt['checks'])
    log = (RUN / 'engine.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    for name in ['museum', 'validation', 'source']:
        (O / name).mkdir(parents=True, exist_ok=True)
    for p in RUN.glob('doorway-*.png'):
        shutil.copy2(p, O / 'museum' / p.name)
    for name in ['report.json', 'engine.log', 'source_manifest.json']:
        shutil.copy2(RUN / name, O / 'validation' / name)
    source_dir = R / 'commons/artifacts/fuzzy_doorway'
    for p in source_dir.iterdir():
        if p.suffix in ['.gd', '.tscn', '.md']:
            shutil.copy2(p, O / 'source' / p.name)
    sources = [*source_dir.glob('*.gd'), *source_dir.glob('*.tscn'),
               R / 'commons/artifacts/registry/fuzzy_doorway.json',
               R / 'commons/maps/Shader_05_Patterns/map_data.json',
               R / 'tools/probes/fuzzy_doorway_museum.gd']
    write(O / 'validation/source-hashes.json', {
        p.relative_to(R).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
    plan = next(p for p in read(R / 'commons/data/museum/em_plan.json')['plans']
                if p.get('map') == 'Shader_05_Patterns' and p.get('sequence') == 'shaders')
    assert any(a['token'].split(':')[0] == 'fuzzy_doorway' for a in plan['artifacts'])
    write(O / 'validation/placement.json', {
        'map': 'Shader_05_Patterns', 'sequence': 'shaders', 'cell': [8, 53],
        'rotation': 180, 'artifacts': plan['artifacts'],
        'scope': 'Actual museum placement; live instance and passage tested.'})
    row = read(RUN / 'em_layout_walk.json')['halls'][KEY]
    for rel in ['ada_run/em_layout_walk.json', 'commons/data/museum/em_layout_walk.json']:
        p = R / rel
        if p.exists():
            backup(p)
            data = read(p)
            data['halls'][KEY] = row
            write(p, data)
    p = R / 'commons/data/long_museum.json'
    backup(p)
    data = read(p)
    segment = next(s for s in data['segments'] if s['name'] == 'Shader_05_Patterns')
    old_count = len(segment['artifacts'])
    segment['artifacts'] = [
        {'x': a['cell'][0], 'z': a['cell'][1], 'token': a['token'], 'rot': a.get('rotation', 0)}
        for a in plan['artifacts']]
    delta = len(segment['artifacts']) - old_count
    data['totals']['artifacts'] += delta
    next(c for c in data['chapters'] if c['sequence'] == 'shaders')['artifacts'] += delta
    p.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')

    count = len(receipt['checks'])
    samples = receipt['observations']['doorway_route_samples']
    report = f'''# A doorway reads your approach

**Installed in Godot's Endless Museum → Shaders → Patterns.** After the sphere with overlapping fields, the next object responds to your own movement. Fourteen ribs open outward as you approach slowly and curl inward as you approach quickly. You can walk through either state.

![Slow approach: ribs open outward](museum/doorway-slow.png)

## From the hand to the body

The sphere asks where an object belongs. The doorway asks how a visitor is approaching. It measures distance and approach speed, gives each a degree, and combines three rules: near-and-slow opens, near-and-fast curls, far rests. At intermediate values, both responses contribute.

This adds a second input to the earlier field study and makes the visitor part of the experiment. The form changes while you approach it; stopping changes the reading again.

## The rule is a choice

Press **SWAP RULES** and the same fast input opens the ribs. Slow movement now curls them. Nothing about speed itself required the original response. Someone assigned it.

The doorway measures motion, not character, intent or identity. Its apparent welcome or hesitation comes from our choice of thresholds and transformations. Making the response gradual does not make that choice disappear.

![Fast approach with the original assignment](museum/doorway-fast.png)
![The same fast input after swapping the rules](museum/doorway-fast-reversed.png)

## Use the installation

Walk up, stop, pass through and return. **REACH** changes how close counts as near; **PACE** changes how speed is graded. The nearby console has native rectangular buttons and grip dials. The board opposite shows the three rule strengths.

**LIVE** follows the actual museum body on desktop or the active XR head. **DEMO SLOW / FAST** let you inspect a response while standing still. They supply fixed, labelled inputs at 1 metre, at 0.15 or 2.6 metres per second. **RESET** restores the default rules and LIVE input.

![Native controls beside the entrance](museum/doorway-console.png)
![Visible rule strengths](museum/doorway-rules.png)

The comparison photos use those declared demonstration inputs. They are saved Godot captures, not a live browser simulation. Separate tests drive the actual museum body through the LIVE response.

## Inside the hall

The new installation sits at map cell [8,53], behind the sphere at [8,40], in the existing rear gallery. Seven earlier artifacts and the onward passage remain. Fixed supports stay outside the walking lane; the changing ribs have no collision. The floor stays still.

![Inside the opening, looking toward the next passage](museum/doorway-inside.png)
![Sphere and doorway in the existing museum](museum/doorway-sequence.png)
![Actual arrangement from above](museum/doorway-above.png)

## What was verified

**{count}/{count} native Godot checks passed.** This includes the 97 earlier model/sphere checks, explicit fuzzy arithmetic, source and topology retention, sampled geometry bounds, motion sensing, teleport discontinuities, native pointer buttons, and simulated XR input and dial grips. The actual museum CharacterBody crossed the doorway using its collision solver at scripted velocities. {samples} supported capsule samples checked the route from the sphere to the controls, through the doorway and onward.

These are desktop Godot runtime tests with synthetic XR poses. Physical headset use, Quest performance and independent student learning have not been tested. Existing unrelated UID, registry and renderer warnings remain in the log; there were no script or parse errors in the successful run.

The artifact retains one source and 3,696 vertex entries. Rule inference and the small visual response delay are separate operations. [Read the exact method and controls](source/README.md).

[Test receipt](validation/report.json) · [Engine log](validation/engine.log) · [Placement](validation/placement.json) · [Godot implementation](source/fuzzy_doorway.gd) · [Museum entry scene](source/museum.tscn)

This continuation adds one research artifact. The canonical tutorial and reflective texts, and the spine order, remain as they were.
'''
    (O / 'REPORT.md').write_text(report, encoding='utf-8')
    options = [('rest', 'Rest'), ('slow', 'Slow approach'), ('fast', 'Fast approach'),
               ('fast-reversed', 'Fast / swapped rules')]
    buttons = ''.join(f'<button data-shot="{key}" aria-pressed="{str(i == 1).lower()}">{title}</button>'
                      for i, (key, title) in enumerate(options))
    viewer = ('<section class="viewer"><p class="eyebrow">Compare saved native Godot views · same camera</p>'
              '<div class="buttons">' + buttons + '</div>'
              '<img id="comparison" src="museum/doorway-slow.png" alt="Slow approach: ribs open outward">'
              '<p id="view-label">Slow approach</p></section>')
    body = markdown.markdown(report, extensions=['extra'])
    body = body.replace('<h2>The rule is a choice</h2>', viewer + '<h2>The rule is a choice</h2>')
    css = '''*{box-sizing:border-box}body{margin:0;background:#ecebe3;color:#21383e;font:19px/1.65 Georgia,serif}
main,header,footer{max-width:1240px;margin:auto;padding:28px 32px}header,footer,.eyebrow{font:13px/1.5 Arial;letter-spacing:.08em}
header{border-bottom:1px solid #a7b9b0}h1{font-size:clamp(34px,6vw,68px);line-height:1.1}h2{font:28px Arial;margin-top:52px}
p{max-width:960px}img{display:block;width:100%;margin:24px 0;border-radius:4px}a{color:#863859}
button{font:15px Arial;cursor:pointer;padding:12px 17px;border:1px solid #99ada6;background:#f9f6ec;border-radius:4px;color:#21383e}
button[aria-pressed=true]{background:#21383e;color:#fff}.buttons{display:flex;flex-wrap:wrap;gap:8px}.viewer{padding:20px;background:#dbe2dc;margin:44px 0}
#view-label{font:15px Arial}code{overflow-wrap:anywhere}@media(max-width:600px){main,header,footer{padding:22px 16px}}'''
    js = '''document.querySelectorAll('[data-shot]').forEach(b=>b.addEventListener('click',()=>{
document.querySelectorAll('[data-shot]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));
const image=document.getElementById('comparison');image.src='museum/doorway-'+b.dataset.shot+'.png';image.alt=b.textContent;
document.getElementById('view-label').textContent=b.textContent;}));'''
    (O / 'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1"><title>A doorway reads your approach</title>'
        '<style>' + css + '</style></head><body><header>ENDLESS MUSEUM / INSTALLED IN GODOT / 9 OCTOBER 2026</header>'
        '<main>' + body + '</main><footer>always another room</footer><script>' + js + '</script></body></html>', encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"', (O / 'index.html').read_text(encoding='utf-8')):
        if not ref.startswith(('http', '#')):
            assert (O / ref).is_file(), ref
    print(json.dumps({'checks': count, 'route_samples': samples, 'report': str(O / 'index.html')}))


if __name__ == '__main__':
    main()
