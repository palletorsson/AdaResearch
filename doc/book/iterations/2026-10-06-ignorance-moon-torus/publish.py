from pathlib import Path
import difflib
import hashlib
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Primitives_Ignorance'
report = json.loads((RUN / 'report.json').read_text())
assert report['passed'] and not report['failures']
for name in ['moon-court', 'moon-court-coarse', 'shadow-fine', 'shadow-control',
             'shadow-four-rings', 'torus-four-by-four']:
    shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
for name in ['report.json', 'source_manifest.json', 'stdout.log']:
    shutil.copy2(RUN / name, OUT / name)

paths = [
    'commons/artifacts/ignorance_gallery/moon_torus.gd',
    'commons/artifacts/ignorance_gallery/form_in_hand.gd',
    'commons/maps/Primitives_Ignorance/map_data.json',
    'commons/maps/Primitives_Ignorance/final.md',
    'commons/artifacts/registry/commons_artifacts.json',
    'tools/probes/ignorance_moon_torus.gd',
]
(OUT / 'changed-source-hashes.json').write_text(json.dumps({
    p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths
}, indent=2), encoding='utf-8')
diffs = []
for p in paths:
    before = OUT / 'before' / p
    diffs.extend(difflib.unified_diff(
        before.read_text(encoding='utf-8').splitlines(True) if before.exists() else [],
        (ROOT / p).read_text(encoding='utf-8').splitlines(True),
        fromfile='before/' + p, tofile=p))
(OUT / 'scoped.diff').write_text(''.join(diffs), encoding='utf-8')
count = len(report['checks'])
notes = f'''# A form above, a shadow below

The last space of Primitives Ignorance is an open moon court. A charcoal torus hangs horizontally with its centre five metres above the existing floor. Its outer diameter is five metres; its inner and outer radii are 1.4 and 2.5 metres. The museum's existing directional moon casts the actual mesh shadow. No painted shadow or second moon is added.

Rings descend from 48 to 4 with tube segments held at 24. Segments then descend to 4 with rings held at 4. Both recover in the same order. One count changes at a time, with a 1.5-second interval and a 42-second cycle. Size, position and orientation remain fixed. The wall readout shows both counts. Geometry is rebuilt only when a count changes.

The final station's local roof, floor overlay and fill lights were removed. The map opts out of the global ceiling; the first two galleries retain their own roofs. The original hanging catalyst moves to the side, with its bracket and cable. Its pickup, simplification, shooting and return behaviour is preserved. The two rings/segments specimens remain on white plinths beside the shadow field. Room structure, exits and map placements stay the same.

## Text

final.md adds a short encounter with the torus and its shadow, then turns to the nearby point. The tutorial remains unchanged: this is a museum encounter with a construction already being explored, not a new required programming subject.

## Evidence

{count} native Godot checks passed, including every resolution state, fixed radii/height/orientation, real moon/shadow settings, animation timing and the earlier catalyst's interaction regression checks. Trigger events are supplied by the probe. These results do not establish headset comfort or Quest performance.

All images were captured inside the actual Endless Museum. Fine/coarse comparison images use the same camera and frozen moon phase. In ordinary play the museum's moon continues moving. A separate control disables only the torus shadow caster: 432,560 floor-region pixels darken by more than 8 RGB levels when it is enabled. Changing only rings changes 228,235 floor-region pixels above that threshold. See shadow-check.json for the bounded comparison. This confirms a rendered shadow, not a performance benchmark.

One pre-existing unknown resource UID warning remains in the engine log. No new script error was observed.

Run again: `python -X utf8 tools/run_encounter_probe.py Primitives_Ignorance --sequence primitives --render --probe tools/probes/ignorance_moon_torus.gd`
'''
(OUT / 'REPORT.md').write_text(notes, encoding='utf-8')

def figure(src, caption):
    return f'<figure><a href="{src}"><img loading="lazy" src="{src}" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A form above, a shadow below</title><style>
*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#20201e;font-family:Georgia,serif;line-height:1.6}header,main,footer{max-width:1380px;margin:auto;padding:38px 5vw}header{padding-bottom:0}h1{font-size:clamp(38px,6vw,82px);font-weight:400;line-height:1.04;margin:18px 0}h2{font-size:32px;font-weight:400;margin:46px 0 12px}.eyebrow,nav,figcaption,small{font:13px/1.6 system-ui,sans-serif}.eyebrow{letter-spacing:.14em;text-transform:uppercase}p{max-width:790px;font-size:19px}a{color:inherit}nav{display:flex;gap:24px;flex-wrap:wrap;margin:25px 0}figure{margin:16px 0}img{display:block;width:100%;border:1px solid #c9c4b8}figcaption{padding:9px 0;color:#59574f}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.steps{border-block:1px solid #aaa393;padding:18px 0;font:16px/1.8 system-ui}blockquote{font-size:25px;border-left:2px solid #565347;padding:10px 24px;margin:36px 0;max-width:900px}details{font:14px/1.7 system-ui;margin:30px 0}footer{font:14px/1.7 system-ui;border-top:1px solid #c0b9a9}@media(max-width:700px){.pair{grid-template-columns:1fr}header,main,footer{padding:24px}p{font-size:18px}}
</style><header><div class="eyebrow">Endless Museum · Primitives Ignorance · 6 October 2026</div><h1>A form above,<br>a shadow below.</h1><p>The final bay opens to the night. A torus hangs five metres above the floor, and its changing construction reaches the ground as moonlight and shadow.</p><nav><a href="#museum">The moon court</a><a href="#shadow">Changing divisions</a><a href="#before">Before / after</a><a href="#reading">The text</a><a href="#checks">Evidence</a></nav></header><main id="museum">'''
page += figure('moon-court.png', 'The actual last bay: a suspended torus, its moonlit shadow, and the small catalyst point to the left.')
page += '<div class="steps"><b>5 m above the floor.</b> Rings 48 → 4. Segments 24 → 4. One count at a time, then back again.</div><h2 id="shadow">The shadow acquires corners.</h2><p>The torus keeps its size and orientation. Changing its divisions changes what the moon projects onto the floor. You can stand within the opening and look up at the same relation overhead.</p><div class="pair">'
page += figure('shadow-fine.png', '48 rings / 24 segments · a rounded shadow.')
page += figure('shadow-four-rings.png', '4 rings / 24 segments · only the ring count changed.')
page += '</div>' + figure('moon-court-coarse.png', '4 rings / 4 segments · the same room and camera, with both counts now at their minimum.')
page += '<h2 id="before">Room for the shadow.</h2><div class="pair">'
page += figure('before/last-bay.png', 'Before · the covered final station. Earlier camera position.')
page += figure('moon-court.png', 'After · the open court. The catalyst and two comparison specimens move to the sides.') + '</div>'
page += '<h2 id="reading">A decision reaches the floor.</h2><blockquote>The last bay opens to the night. A torus hangs five metres above the floor, with sky visible through its centre. Its rings and segments change one count at a time. Watch the shadow: a rounded opening acquires corners without anything touching the ground. The moon carries a decision made overhead to the place where you stand.</blockquote><p>This passage is now in the reflective text. The existing tutorial keeps its focus.</p>'
page += f'<h2 id="checks">{count} native checks passed.</h2><p>The changing mesh, fixed height, real shadow settings and nearby catalyst were checked in Godot. Render comparisons confirm that disabling the torus shadow caster removes the floor shadow. Headset feel and Quest performance still need a VR playtest.</p><details><summary>Show the shadow control</summary>'
page += figure('shadow-control.png', 'Same camera and moon phase; only the torus shadow caster is disabled.') + '</details><details><summary>Read the native checks</summary><ul>'
page += ''.join('<li>' + html.escape(c['name']) + '</li>' for c in report['checks'])
page += '</ul></details><p><a href="REPORT.md">Implementation notes</a> · <a href="report.json">Native results</a> · <a href="shadow-check.json">Shadow comparison</a></p></main><footer>Images rendered from the real Endless Museum. The museum’s moving moon is frozen only for these matched comparison captures.</footer></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {OUT}; {count} checks.')
