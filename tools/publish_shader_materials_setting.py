"""Publish native museum evidence for the third shader setting."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/Shader_11_QueerRubber/parlour'
OUT = ROOT / 'doc/book/iterations/2026-10-10-materials-in-the-museum'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = json.loads((OUT / 'before/map_data.json').read_text(encoding='utf-8-sig'))
now = json.loads((ROOT / 'commons/maps/Shader_11_QueerRubber/map_data.json').read_text(encoding='utf-8-sig'))
for layer in ['interactables', 'utilities']:
    for z, row in enumerate(before['layers'][layer]):
        for x, token in enumerate(row):
            assert now['layers'][layer][z][x] == token, (layer,x,z)
assert (ROOT / 'commons/maps/Shader_11_QueerRubber/final.md').read_bytes() == (OUT / 'before/final.md').read_bytes()

views = [
    ('parlour', 'A material enters a furnished room', 'The same shader covers the sphere, cube and existing sofa, chair and vase prefabs. The comparison starts with fixed bodies and lights. These images come from the actual Queer Materials hall in Endless Museum.'),
    ('console', 'One nearby bench', 'ROUGH changes the base roughness. RIM controls the small STUDY shader. PLASTIC, VELVET and OIL select existing project materials; RIM is unavailable in those modes. RESET restores the initial study and both amounts.'),
    ('rim-off', 'Hold the eye and remove the rim', 'The familiar sphere and cube retain their geometry. At zero rim amount, this study returns only its lit dark surface.'),
    ('rim-on', 'Return the rim', 'Same camera, bodies and lights; rim amount is now 1.5. The curved silhouette brightens gradually. A flat cube face has a different response because its normal stays constant across that face, while view direction varies across it.'),
    ('plastic', 'Plastic', 'The existing Pop Plastic shader reaches the furniture too. Its gloss and coloured edge are surface calculations. The bodies retain their shape and collision.'),
    ('velvet', 'Velvet', 'The existing shader adds a grain and sheen that suggest softness. No fibres, cushions or cloth mechanics are being simulated. The sofa source has no UVs, so its texture variation is limited; its normal/view response still works.'),
    ('oil', 'Oil', 'The existing Oil Slick Latex shader combines a dark body with a changing rainbow. TIME remains active in this preset. Its unassigned noise sampler reads white, so this is a clean animated rim rather than simulated flowing oil.'),
    ('furnished', 'The comparison reaches familiar things', 'Standing farther inside the room reveals how a single material reads across an angular sofa, a curved vase and the two geometric specimens. The imported sofa is oriented upright here; the source prefab is unchanged.'),
    ('overview', 'Space to walk around the response', 'An elevated view of the new side room. The old three exhibits retain their authored cells, with the original plan’s eight piers made explicit in the map. The entry gate uses the boundary doorway so it no longer cuts across this bay.'),
]
sources = [
    'commons/maps/Shader_11_QueerRubber/map_data.json',
    'commons/artifacts/shader_material_parlour/rim_study.gdshader',
    'commons/artifacts/shader_material_parlour/shader_material_parlour.gd',
    'commons/artifacts/shader_material_parlour/shader_material_parlour.tscn',
    'commons/artifacts/registry/shader_material_parlour.json',
    'algorithms/shaders/book_of_shaders/shader_11_queerrubber.gd',
    'algorithms/shaders/queer_materials/pop_plastic.gdshader',
    'algorithms/shaders/queer_materials/fur_velvet.gdshader',
    'algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader',
    'commons/primitives/sofa/sofa.gd',
    'commons/primitives/sofa/sofa.tscn',
    'commons/primitives/chair/chair_modern.gd',
    'commons/primitives/chair/chair_modern.tscn',
    'commons/primitives/design_classics/aalto_vase.gd',
    'commons/primitives/design_classics/aalto_vase.tscn',
    'tools/probes/shader_materials_museum.gd',
]
manifest = {'hall':'Shader_11_QueerRubber', 'checks_passed':len(report['checks']),
            'scope':report['scope'], 'prior_artifact_and_utility_cells_preserved':True,
            'final_manuscript_unchanged':True, 'source_sha256':{}, 'image_sha256':{}}
for rel in sources:
    dst=OUT/'source'/rel; dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/rel,dst)
    manifest['source_sha256'][rel]=hashlib.sha256(dst.read_bytes()).hexdigest()
for name,_,_ in views:
    shutil.copy2(RUN/f'{name}.png',OUT/f'{name}.png')
    manifest['image_sha256'][f'{name}.png']=hashlib.sha256((OUT/f'{name}.png').read_bytes()).hexdigest()
for name in ['report.json','source_manifest.json','engine.log']:
    shutil.copy2(RUN/name,OUT/name)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')

def esc(v): return html.escape(str(v),quote=True)

first=ROOT/'doc/book/iterations/2026-10-10-shaping-in-the-museum/index.html'
style=re.search(r'<style>.*?</style>',first.read_text(encoding='utf-8'),re.S).group()
figures=''.join(f'<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — native museum capture" {"loading=lazy" if i else ""}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>' for i,(stem,title,caption) in enumerate(views))
checks=''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
links=''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Queer Materials inside Endless Museum</title>{style}
<header><div class="eyebrow">Endless Museum · Shaders / hall 3 · 10 October 2026</div><h1>A body acquires a surface.</h1><p>Shaping drew a boundary. Patterns repeated its lookup through a room. Here the same familiar bodies answer to the eye: a sphere, cube and furnished setting carry one material together.</p><nav><a href="#parlour">The room</a><a href="#console">Controls</a><a href="#rim-off">Rim comparison</a><a href="#plastic">Collection</a><a href="#evidence">Evidence</a><a href="../2026-10-10-patterns-in-the-museum/index.html">Previous hall</a></nav></header>
{figures}
<section class="facts"><div><h2>One primary operation</h2><p>Compare surface normal with view direction. Raise one minus their clamped dot product to the third power, then use it for emission. The same rule has different appearances on curved and flat bodies.</p></div><div><h2>The setting supports it</h2><p>The small study has roughness and rim controls. The existing collection supplies further material encounters. Sofa, chair and vase come from project prefabs; their cameras and global environments do not take over the museum.</p></div><div><h2>Carried onward</h2><p>Changing the surface can change what a rigid object seems to be. Appearance, geometry and collision remain distinct. The next setting is water and layered noise in FBM.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">{len(report['checks'])} native checks passed</span><h2 style="margin-top:22px">What the run establishes</h2><p>Godot 4.6 loads the actual map and registered installation. Physical slider and button receivers update the shader parameters and material assignments. Tests retain the meshes, transforms and local lights across all presets. GPU pixel readback checks a brightening curved edge, an unchanged front-facing centre, and the response of a flat surface turned toward a grazing angle.</p><p>The connection from the old room and the new specimen loop are sampled every quarter metre for floor and standing clearance. The first render exposed a generated entrance wall across the new room: gate_depth_rows is now zero, placing the gate in the boundary doorway. The route goes around the furniture and pedestals.</p><p>This run uses the compatibility renderer with XR disabled. Physical headset input, passage into the next hall and learner reconstruction remain untested. The existing unresolved default-audio-bus UID appears in the log; the final run has no script or shader errors.</p><p>This is a spatial pass. The reflective manuscript remains unchanged; its opening claim that there are no adjustable desks will need a focused update when we write this hall’s tutorial. No tutorial.md currently exists in this map folder. The primary reconstruction remains the small normal/view study, with furniture supplied as context.</p><p><a href="report.json">Checks</a> · <a href="engine.log">Engine log</a> · <a href="manifest.json">Source and image hashes</a> · <a href="source_manifest.json">Museum harness manifest</a> · <a href="SETTING.md">Editable setting brief</a></p><details><summary>Native checks</summary><ol>{checks}</ol></details><details><summary>Sources and before state</summary><ul>{links}</ul><p><a href="before/map_data.json">Before: map</a> · <a href="before/final.md">Unchanged reflection</a></p></details><details><summary>Reproduce</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_11_QueerRubber --sequence shaders --probe tools/probes/shader_materials_museum.gd --render --no-bridges --output-tag parlour</code></p></details></div></section><footer>Nine native Godot views. The overview is elevated; the other cameras are at standing eye height.</footer></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'SETTING.md').write_text('''# Queer Materials — setting brief

Carry: sphere/cube, normal, colour, supplied shader material. Core: normal/view dot → rim emission; compare sphere/cube without changing geometry. Controls: roughness, rim, reset. Context: existing sofa/chair/vase under the same material; Plastic/Velvet/Oil are supporting presets. RIM belongs only to STUDY. Oil retains TIME animation and white noise fallback. Velvet does not simulate fibres; sofa UVs absent. Mesh/collision remain rigid. Next: FBM and water.

Map: new east bay, prior three artifact and utility cells preserved; eight piers from prior plan now explicit; boundary gate. See report.json for current native evidence. Headset/learner validation open.

Text follow-up: existing final.md still describes the old nonadjustable display. Preserve its reflection, qualify that opening, then connect the new comparison. tutorial.md is absent in this map folder. Do not present this spatial test as a tested printed tutorial.
''',encoding='utf-8')
print(json.dumps({'page':str(OUT/'index.html'),'images':len(views),'checks':len(report['checks'])}))
