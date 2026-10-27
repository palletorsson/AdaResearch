"""Publish reviewed native photographs and explicit receipts for three new studies."""
from pathlib import Path
import json, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/friction-studies'
NATIVE = ROOT / 'ada_run/matter-reference'
REVIEW = ROOT / 'doc/ports/2026-10-25-friction-studies'
GALLERY = ROOT / 'doc/book/iterations/2026-10-25-friction-studies'
read = lambda p: json.loads(p.read_text(encoding='utf-8'))
receipts = {
    'physics': NATIVE / 'friction-studies-checks.json',
    'player': NATIVE / 'friction-main-checks.json',
    'capture': NATIVE / 'friction-capture-checks.json',
    'save': OUT / 'save-checks.json',
    'export': OUT / 'export.json',
    'editor': OUT / 'editor-checks.json',
}
reports = {key: read(path) for key, path in receipts.items()}
assert all(report['passed'] for report in reports.values())
REVIEW.mkdir(parents=True, exist_ok=True)
GALLERY.mkdir(parents=True, exist_ok=True)
for name in ['friction-layout', 'friction-ramp', 'friction-coast', 'friction-pull',
             'friction-main-ramp', 'friction-main-coast', 'friction-main-pull']:
    shutil.copy2(NATIVE / (name + '.png'), GALLERY / (name + '.png'))
for key, path in receipts.items():
    shutil.copy2(path, REVIEW / (key + '-checks.json'))

cards = [
    ('ramp', 'Let Go', 'Change the angle or contact surface. Does the same cube stay or slide? The catch stop keeps the normal downhill take on the plank.',
     'A 12° take stayed within 1 mm; a 34° take slid about 1.99 m.'),
    ('coast', 'Keep Going', 'Two equal cubes, one identical push each. Smooth plywood and rough grit make the difference visible in their stopping distances.',
     'The rotated negative-floor fixture travelled about 1.24 m on smooth wood and 0.11 m on grit.'),
    ('pull', 'Almost Enough', 'A suspended cube pulls across the edge of shaft A. Add weight, release and see when contact gives way.',
     'A 0.20 kg weight held; 1.20 kg pulled the 2 kg cube about 1.95 m and descended about 2.09 m.'),
]
articles = ''.join(f'''<article id="{kind}"><p class="eyebrow">{index:02d} / CONTACT AND MOVEMENT</p>
<h2>{title}</h2><p>{description}</p><a href="friction-{kind}.png"><img src="friction-{kind}.png" alt="Native Godot inspection view of {title}"></a>
<p>{result}</p><details><summary>See the actual desktop player view</summary><img loading="lazy" src="friction-main-{kind}.png" alt="Actual main-floor desktop view of {title}"></details></article>'''
    for index, (kind, title, description, result) in enumerate(cards, 1))
html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Friction studies — three new examples</title><style>
*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#241f28;font:16px/1.55 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:40px 24px}h1{font-size:clamp(38px,6vw,76px);line-height:1.02;max-width:950px}h2{font-size:32px;margin:12px 0}a{color:#7e2150;text-underline-offset:3px}p{max-width:850px}img{display:block;width:100%;height:auto}figure{margin:30px 0}figcaption,.eyebrow{font-size:13px}.studies{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,500px),1fr));gap:32px}article{border-top:3px solid #e45391;padding-top:14px}details{margin:20px 0}summary{cursor:pointer;padding-bottom:12px}.note{border-left:4px solid #bd3a77;background:#e8dce2;padding:14px 20px}
</style><main><p class="eyebrow">NEW NATIVE STUDIES / FLOOR 46 / KINETIC FORCES</p>
<h1>Let go.<br>See what keeps moving.</h1><p>Three new examples after Almost and Just. Change one condition, release the body, wait for the actual result. Each station keeps the last three takes while it is loaded.</p>
<p><a href="/lab-editor?mode=void&floor=46">Open floor 46 in the live editor ↗</a> · <a href="/book-review/doc/book/iterations/2026-10-25-almost-and-just/index.html">Back to Almost and Just ↗</a></p>
<p class="note">Jolt gravity and contact move the cubes. Almost Enough uses an explicitly elastic cable and an ideal massless roller; it is not a native pulley joint. These are new studies, beyond the original 15-example collection.</p>
<figure><img src="friction-layout.png" alt="Single-storey inspection view of main floor 46 with all five original exhibits and three new friction studies"><figcaption>One-storey inspection view: the five original exhibits remain. The pull rig uses shaft A; the other two stations stand on the west and east slabs. Approach walking was checked with the actual player.</figcaption></figure>
<section class="studies">''' + articles + '''</section>
<p>Boards, supports, cubes, controls, witnesses and cable/roller assemblies remain separately editable. Arbitrary rearrangements can break the calibrated experiment. Runtime dial changes and take history are encounter-local; saved editor arrangements are shared by desktop and VR.</p>
<p>Physics comparisons, desktop mouse controls, synthetic XR controls, pickup/reset, walking, native model exports and editor move/rotate/copy/save validation passed. Physical headset testing remains. Inspection photographs hide neighbouring floors; the expandable player views come from the actual game.</p>''' + ('''<figure><img loading="lazy" src="friction-editor.jpg" alt="Saved main floor 46 in the live editor with Almost Enough selected and actual native geometry loaded"><figcaption>The saved floor in the live editor. Select the work area to move it as a whole, or select an individual member to edit the arrangement.</figcaption></figure>''' if (GALLERY / 'friction-editor.jpg').exists() else '') + '''</main></html>'''
(GALLERY / 'index.html').write_text(html, encoding='utf-8')
counts = {key: len(report.get('checks', [])) for key, report in reports.items()}
status = dict(completed=True, floor=46, new_studies=3, original_artifacts_preserved=5,
              independent_editor_members=reports['editor']['parts'], mesh_count=reports['editor']['meshes'],
              check_counts=counts, physical_headset_tested=False,
              gallery='/book-review/doc/book/iterations/2026-10-25-friction-studies/index.html')
(REVIEW / 'STATUS.json').write_text(json.dumps(status, indent=2) + '\n', encoding='utf-8')
(REVIEW / 'REVIEW.md').write_text(f'''# Three new friction studies

Completed on main floor 46 / Kinetic Forces. This is new native content beyond the original 15 ZIP examples. All five existing floor-46 artifacts and all other floors were retained.

## What the player can do

- Let Go: adjust the angle/contact surface, release a cube and measure stick versus slide.
- Keep Going: compare actual stopping distances after identical 2.4 Ns impulses on two 2 kg cubes, with plywood versus rough grit.
- Almost Enough: adjust hanging mass/contact friction, then release a real suspended weight over shaft A.
- Pick up and place the cubes; reset releases an actual held body and restores the authored member positions. Three recent takes persist only while this encounter is loaded.

## Evidence

- {counts['physics']} physical checks: actual low/high contact contrasts at negative height and a rotated assembly, native weight descent, reset and edited part preservation.
- {counts['player']} actual main-floor player checks: desktop mouse, synthetic XR trigger/grip, pickup/reset, route walking and measured contact/cable readings.
- {reports['editor']['parts']} independently editable members; {reports['editor']['meshes']} actual exported meshes. Every member moves/rotates; copied witnesses pass the production save validator without saving test edits.
- Production revision-guarded layout save and desktop/VR mirror agree. Export refreshed floor 46 only, preserving other model floors.
- Native screenshots inspected separately from test assertions. Overview/detail inspection views hide neighbouring floors; player views use the actual game.

## Physical model and limits

Jolt integrates rigid bodies and contact friction. There are no success pose animations or output velocity nudges after release (Keep Going's one initial impulse is explicit). Planar guides keep cubes within each demonstration plane. Almost Enough uses a unilateral spring/damper cable: stiffness 400 N/m, damping 8 Ns/m, no compressive force while slack, ideal massless roller. It is not a native pulley joint or a simulation of rope material/inertia. The weight guide permits vertical movement and prevents lateral drift.

Let Go has a physical downhill catch; its reading stops if a hand-placed cube leaves the plank rather than projecting a later fall into a false slide distance. Reset uses static freeze mode so restoring a carried cube does not sweep it into another collision. Parameter-dependent rebuilds are deferred until after button signal dispatch and retain explicit editor member overrides.

Original physics warnings about solver bias and Compatibility-renderer headset blur remain; no artifact script/runtime errors were accepted. Synthetic XR is not physical-headset acceptance. Arbitrary editor rearrangements can break the calibrated contact/cable geometry. This is an additive installation, not a full curation of the five older exhibits. No chapter/final.md rewrites.

Gallery: http://localhost:3003{status['gallery']}
Editor: http://localhost:3003/lab-editor?mode=void&floor=46
''', encoding='utf-8')
print(json.dumps(status))
