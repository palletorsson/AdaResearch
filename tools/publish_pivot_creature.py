"""Preserve the procedural creature review and its native Godot evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-move-the-centre'
BODY = ROOT / 'algorithms/randomness/proceduralrandomness/geometrybased/omoss'
RUN = ROOT / 'ada_run/pivot_body'
for folder in ('museum', 'validation', 'source'):
    (OUT / folder).mkdir(parents=True, exist_ok=True)
for path in RUN.glob('*.png'):
    shutil.copy2(path, OUT / 'museum' / path.name)
for name in ('report.json', 'native.log', 'preview.log', 'smoke.log'):
    shutil.copy2(RUN / name, OUT / 'validation' / name)
for path in BODY.iterdir():
    if path.suffix in ('.gd', '.tscn', '.md'):
        shutil.copy2(path, OUT / 'source' / path.name)
for name in ('pivot_body.gd', 'pivot_preview.gd', 'pivot_smoke.gd'):
    shutil.copy2(ROOT / 'tools/probes' / name, OUT / 'source' / name)
registry = json.loads((ROOT / 'commons/artifacts/registry/randomness.json').read_text(encoding='utf-8'))
entry = registry['artifacts']['omoss']
(OUT / 'source/registry-entry.json').write_text(json.dumps(entry, indent=2) + '\n', encoding='utf-8')
shutil.copy2(ROOT / 'commons/artifacts/dressing_rooms/omoss.json', OUT / 'source/dressing-room.json')
receipt = json.loads((RUN / 'report.json').read_text())
assert len(receipt['checks']) == 28 and not receipt['failed']
assert all(check['passed'] for check in receipt['checks'])

report = '''# Move the centre

A six-limbed creature replaces the old abstract cluster in the `omoss` artifact. Its three eyes, tail, skeleton and skin are generated in Godot. The body is an experiment prompted by the user's Albert Omoss reference, not a reconstruction of his method.

## Try it

Grab the pink sphere beside the console. It moves the creature's centre of rotation and scale through a bounded proxy. ROTATION and SCALE act on the whole body; LIMBS changes the local bone poses. RUN animates the same body, BONES reveals the hierarchy through translucent skin, CENTRE returns the pivot, and RESET restores the original pose and stops motion.

Open `algorithms/randomness/proceduralrandomness/geometrybased/omoss/preview.tscn` and press F6 for the separate review room with the project's desktop player. The production artifact remains in `Ribbon_Randomness_02`, a non-spine authoring gallery. Its placement was raised one metre because the old floor blocked the console. No tutorial or reflective sequence was rewritten.

## What changes when the centre moves?

Moving a whole-body pivot changes the path of an intact body. Changing a bone's local rotation, scale and centre deforms the weighted skin. The exhibit separates these operations so the distortion can be inspected and reset. Its mesh is generated once; later frames change the poses, not the original vertex buffer.

There are 25 bones, 3,344 vertices and 6,400 triangles. Inverse bind transforms and vertex weights connect the mesh to Skeleton3D. The torso and limb roots overlap; this is not a watertight single surface. This version uses skeletal animation. A physics ragdoll, joint forces and creature collision are not implemented.

## Images and evidence

The clean comparison images are native Godot captures of the same production artifact inside its optional review room. Ecosystem modulation is disabled for those captures. Gallery images show the existing, still crowded authoring space. Neither set is an AI-generated concept image.

All 28 checks pass in Godot 4.6: registry loading, bind transforms, weights, rest shape, pivot invariance, local deformation, unchanged source mesh, reset, controls, desktop pointer targeting/buttons and simulated XRTools pickup, movement and release. Headset interaction and Quest performance have not been tested. The logs retain unrelated startup UID/audio warnings and a Jolt solver-bias warning; these checks do not certify the entire gallery or project.

The native receipt and logs are in `validation/`. Exact artifact and probe snapshots are in `source/`, with SHA-256 hashes in `source/manifest.json`. The live implementation and registry remain the editable sources.
'''
(OUT / 'REPORT.md').write_text(report, encoding='utf-8')

views = [
    ('Moved centre', 'preview-creature.png', 'The same procedural body, with displaced centre and local limb deformation.'),
    ('Rest pose', 'preview-rest.png', 'RESET restores the generated rest body and stops its clock.'),
    ('Bones', 'preview-bones.png', '25 real bones beneath the weighted skin; the pink point marks the displaced centre.'),
    ('Controls', 'preview-console.png', 'Three dials and four nearby buttons. The pink grab point controls the pivot.'),
    ('From above', 'preview-overhead.png', 'The optional review room leaves space around the body and its reachable controls.'),
    ('Existing gallery', 'gallery.png', 'The artifact is also loaded through the real registry in Ribbon_Randomness_02. Neighbouring exhibits remain.'),
]
buttons = ''.join(f'<button type="button" data-view="{i}" aria-pressed="{str(i == 0).lower()}">{html.escape(label)}</button>' for i,(label,_,_) in enumerate(views))
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Move the centre — Endless Museum</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f3efe7;color:#1d292e;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1300px;margin:auto;padding:30px}header{padding-top:48px}h1{font-size:clamp(42px,7vw,88px);line-height:1.03;margin:.4em 0}h2{line-height:1.2;margin-top:2em}p{max-width:78ch}.eyebrow,nav,figcaption,button,.stats{font:14px/1.5 system-ui}.eyebrow{letter-spacing:.1em;text-transform:uppercase}a{color:#923754;text-underline-offset:4px}nav{display:flex;gap:22px;flex-wrap:wrap}figure{margin:24px 0}img{display:block;width:100%;height:auto}figcaption{padding:9px 0;color:#536268}.controls{display:flex;gap:8px;flex-wrap:wrap}button{cursor:pointer;background:transparent;border:1px solid #758082;padding:10px 18px;color:inherit}button[aria-pressed=true]{background:#202e33;color:#fff}button:focus-visible{outline:3px solid #ea64a1;outline-offset:3px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.stats{display:flex;gap:24px;flex-wrap:wrap;padding:18px 0;border-block:1px solid #c5c8c0}code{font:.82em Consolas,monospace;overflow-wrap:anywhere}footer{border-top:1px solid #c5c8c0}details{border-top:1px solid #c5c8c0;padding:18px 0}summary{cursor:pointer}@media(max-width:720px){header,main,footer{padding:20px}.pair{display:block}}</style></head><body>
<header><div class="eyebrow">Endless Museum / procedural body / 9 October 2026</div><h1>Move the centre.</h1><p>A body with six limbs, three eyes and several possible centres. Generated entirely in Godot, then moved through its bones.</p><nav><a href="#try">Try the artifact</a><a href="#evidence">Native tests</a><a href="REPORT.md">Report</a><a href="source/README.md">Source guide</a></nav></header>
<main><div class="controls" role="group" aria-label="Museum views">BUTTONS</div>
<figure><a id="full-image" href="museum/preview-creature.png"><img id="museum-image" src="museum/preview-creature.png" alt="Procedural six-limbed creature above a dark circular stage, with a pink grab point and three control dials." width="1800" height="1200"></a><figcaption id="caption">The same procedural body, with displaced centre and local limb deformation.</figcaption></figure>
<p class="stats"><span>25 bones</span><span>3,344 vertices</span><span>6,400 triangles</span><span>28 / 28 native checks pass</span></p>
<h2 id="try">A centre you can move</h2><p>Grab the pink sphere. It is a reachable proxy for the centre inside the creature. Turn <strong>ROTATION</strong> or <strong>SCALE</strong> to see the whole body move around it. Increase <strong>LIMBS</strong> to change the local bone poses and deform the skin.</p><p><strong>RUN</strong> animates it; <strong>BONES</strong> exposes the hierarchy; <strong>CENTRE</strong> returns the pivot. <strong>RESET</strong> restores the generated rest body and stops movement. The controls sit together beside the grab point.</p>
<p>For the separate review room, open <code>algorithms/randomness/proceduralrandomness/geometrybased/omoss/preview.tscn</code> in Godot and press F6. The same production artifact remains in <strong>Ribbon_Randomness_02</strong>, outside the curriculum spine. Its placement was raised one metre to keep the console above the old floor.</p>
<h2>One body, two kinds of change</h2><div class="pair"><figure><img src="museum/preview-rest.png" alt="Generated rest pose." loading="lazy"><figcaption>Whole-body rotation retains this local shape.</figcaption></figure><figure><img src="museum/preview-bones.png" alt="Bones visible through a deformed translucent skin." loading="lazy"><figcaption>Local bone transforms change how the skin is distributed.</figcaption></figure></div>
<p>The mesh is generated once. Vertex weights and inverse bind transforms connect it to a real <code>Skeleton3D</code>; later frames change the bone poses. Moving a centre changes the consequences of rotation and scale. The controls make that choice visible.</p><p>This experiment follows the question raised by your Albert Omoss reference. It does not claim to reconstruct his algorithm. Our creature uses skeletal animation: physics ragdoll release, joint forces and skin collision are not implemented. The limb roots overlap the torso; the mesh is not a watertight unified surface.</p>
<h2 id="evidence">What was tested</h2><p><strong>All 28 checks pass in Godot 4.6.</strong> They cover registry loading, bone weights and bind transforms, rest geometry, the fixed pivot, actual skin deformation, unchanged source vertices, reset, dial routing, real desktop pointer targeting and button input, and simulated XRTools grip, movement and release.</p><p>The photographs are native Godot captures. The clean room is a separate preview using the production artifact, with ecosystem modulation disabled for consistent lighting. The gallery view retains its existing neighbours. A physical headset and Quest performance remain untested.</p>
<details><summary>Receipts and limitations</summary><p><a href="validation/report.json">28-check receipt</a> · <a href="validation/native.log">Gallery test log</a> · <a href="validation/preview.log">Preview capture log</a> · <a href="source/manifest.json">Source hashes</a></p><p>Logs retain unrelated startup UID/audio warnings and a Jolt solver-bias warning. This is a focused artifact test, not certification of the whole gallery. Original source snapshots from before the remake are retained in this report directory.</p></details>
</main><footer>Endless Museum · always another room</footer><script>
const views=VIEWS;const buttons=[...document.querySelectorAll('[data-view]')];function selectView(i){const [label,file,caption]=views[i];document.getElementById('museum-image').src='museum/'+file;document.getElementById('museum-image').alt=caption;document.getElementById('full-image').href='museum/'+file;document.getElementById('caption').textContent=caption;buttons.forEach((b,n)=>b.setAttribute('aria-pressed',String(n===i)));}buttons.forEach((b)=>b.addEventListener('click',()=>selectView(Number(b.dataset.view))));
</script></body></html>'''
page = page.replace('BUTTONS', buttons).replace('VIEWS', json.dumps(views))
# The book-review host can disable scripts. Native disclosures keep all views usable.
page = page.replace('<div class="controls" role="group" aria-label="Museum views">' + buttons + '</div>', '')
start = page.index('<script>')
end = page.index('</script>', start) + len('</script>')
page = page[:start] + page[end:]
disclosures = ''.join(f'<details><summary>{html.escape(label)}</summary><figure><a href="museum/{file}"><img src="museum/{file}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure></details>' for label,file,caption in views[1:])
page = page.replace('<p class="stats">', disclosures + '<p class="stats">')
(OUT / 'index.html').write_text(page, encoding='utf-8')
manifest = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((OUT / 'source').iterdir()) if p.is_file() and p.name != 'manifest.json'}
(OUT / 'source/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(f'Published {OUT}; {len(manifest)} source files; 28 passing checks.')
from museum_placement_status import decorate
decorate(OUT,'omoss','randomness.json')
