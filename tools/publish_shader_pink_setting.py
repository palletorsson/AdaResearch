"""Publish the fifth shader setting from its actual museum run."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT/'ada_run/encounter_pilot/Shader_12_PinkExtravaganza/composition'
OUT = ROOT/'doc/book/iterations/2026-10-10-pink-in-the-museum'
report = json.loads((RUN/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = json.loads((OUT/'before/map_data.json').read_text(encoding='utf-8-sig'))
now = json.loads((ROOT/'commons/maps/Shader_12_PinkExtravaganza/map_data.json').read_text(encoding='utf-8-sig'))
for z,row in enumerate(before['layers']['interactables']):
    for x,token in enumerate(row):
        if token.strip(): assert now['layers']['interactables'][z][x] == token
for z in range(16,37):
    assert now['layers']['structure'][z][:21] == before['layers']['structure'][z]
for name in ['final.md','tutorial.md']:
    assert (ROOT/f'commons/maps/Shader_12_PinkExtravaganza/{name}').read_bytes() == (OUT/'before'/name).read_bytes()
log = (RUN/'engine.log').read_text(encoding='utf-8-sig')
assert 'SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log
assert 'blocked authored entry' not in log and 'blocked t exit' not in log

views = [
    ('stage','The room can be otherwise','Pink Extravaganza gains a composition stage inside the existing museum. The sphere, cube and sofa share one material; curtains, pearl chairs and dream water give them another setting. All views on this page are native Godot captures.'),
    ('console','One nearby bench','DOTS mixes in the repeated circle. RIM adds a view-dependent edge. GLOW adds emission. PALE and LAYERED select material recipes; SETTING switches the surroundings independently. RESET restores the layered theatre.'),
    ('pale-studio','1 / Pale, in the studio','The familiar bodies keep their geometry. This recipe has no dots, rim emission or pigment emission; its pale ground and roughness still respond to the lamps.'),
    ('layered-studio','2 / Compose the material','The circle mask from Shaping repeats at room coordinates. A rim catches the curved sphere and the sofa’s changing orientation; pigment emission contributes another layer. This comparison changes the material while keeping the studio setting.'),
    ('layered-theatre','3 / Change the setting','The material, meshes, placements and stage lamps are retained from the preceding view. SETTING adds the suspended surroundings and changes the backdrop. Scenery has shadow casting and GI disabled; the surrounding museum still supplies its normal environment.'),
    ('above','Water overhead','The existing dream-water shader hangs 5.65 m above the floor, with its front face turned downward. It uses three sine waves, moving noise, transparency and emission. It has no fluid state, water collision or screen refraction.'),
    ('chair','A familiar chair, displaced','The existing chair prefab carries the Crushed Pearl material inside a suspended ring. Foil-covered folds stand behind it. Their geometry is authored; this is not a cloth simulation.'),
    ('sofa','The sofa returns','The sofa from the preceding material room becomes a receiver for the composed rule. Its source has no UVs, so the supplied three-plane projection from Patterns provides coordinates. That adapter is infrastructure for the focused composition lesson.'),
    ('overview','A bay beside the existing collection','The hall widens to 39 m while retaining its 37 m depth. The three previous artifacts keep their authored cells. The later plural-body room retains its original structural cells. A broad connection links the old collection to the new stage.'),
    ('collection','The earlier extravaganza remains','Candy, pearl, oil, the large pink sphere and the original floor-water sheet remain in their existing installation. Its animation and material calculations are unchanged. The new stage provides controls for one smaller, explainable recipe.'),
    ('plural-body','A body in the plural remains beyond','The six-limbed, three-headed study keeps its existing room and placement. It remains a separate encounter. Composition does not require turning every museum artifact into another reconstruction exercise.'),
]
sources = [
    'commons/maps/Shader_12_PinkExtravaganza/map_data.json',
    'commons/artifacts/registry/shader_composition_stage.json',
    'commons/artifacts/shader_composition_stage/shader_composition_stage.gd',
    'commons/artifacts/shader_composition_stage/shader_composition_stage.tscn',
    'commons/artifacts/shader_composition_stage/recipe.gdshader',
    'algorithms/shaders/book_of_shaders/queer_water.gdshader',
    'algorithms/shaders/queer_collection_2/crushed_pearl.gdshader',
    'commons/resourses/shaders/foil_paper.gdshader',
    'commons/primitives/sofa/sofa.tscn',
    'commons/primitives/chair/chair_modern.tscn',
    'tools/configure_shader_pink_setting.py',
    'tools/probes/shader_pink_museum.gd',
]
manifest = {'hall':'Shader_12_PinkExtravaganza','checks_passed':len(report['checks']),
            'scope':report['scope'],'original_artifact_cells_preserved':True,
            'later_room_structural_cells_preserved':True,'entry_marker_moved':[7,1],
            'final_and_tutorial_unchanged':True,'source_sha256':{},'image_sha256':{}}
for rel in sources:
    dst=OUT/'source'/rel; dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(ROOT/rel,dst)
    manifest['source_sha256'][rel]=hashlib.sha256(dst.read_bytes()).hexdigest()
for stem,_,_ in views:
    shutil.copy2(RUN/f'{stem}.png',OUT/f'{stem}.png')
    manifest['image_sha256'][f'{stem}.png']=hashlib.sha256((OUT/f'{stem}.png').read_bytes()).hexdigest()
for name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(RUN/name,OUT/name)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')

def esc(v):return html.escape(str(v),quote=True)
style=re.search(r'<style>.*?</style>',(ROOT/'doc/book/iterations/2026-10-10-shaping-in-the-museum/index.html').read_text(encoding='utf-8'),re.S).group()
figures=''.join(f'<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — native museum view" {"loading=lazy" if i else ""}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>' for i,(stem,title,caption) in enumerate(views))
checks=''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
links=''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
(OUT/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pink Extravaganza inside Endless Museum</title>{style}
<header><div class="eyebrow">Endless Museum · Shaders / hall 5 · 10 October 2026</div><h1>The room can be otherwise.</h1><p>Compose familiar operations on familiar objects. Then keep the material and change what surrounds it.</p><nav><a href="#stage">The room</a><a href="#console">Controls</a><a href="#pale-studio">Three comparisons</a><a href="#above">Water overhead</a><a href="#overview">Above the room</a><a href="#evidence">Evidence</a><a href="../2026-10-10-water-in-the-museum/index.html">Previous hall</a></nav></header>
{figures}
<section class="facts"><div><h2>What returns</h2><p>Circle mask, repetition, normal/view rim and emission. The sphere, cube and sofa are familiar receivers. The wider collection supplies pearl, foil and dream water.</p></div><div><h2>What this lesson can teach</h2><p>Compose a material from operations whose contributions can still be isolated. Remove a layer, predict what disappears, restore it. Then retain the recipe while changing its setting.</p></div><div><h2>What travels onward</h2><p>The primary recipe has no clock or retained history. The overhead water is animated from TIME. Reaction–Diffusion can next make the distinction between animated appearance and a system that stores and updates a state.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">{len(report['checks'])} native checks passed</span><h2 style="margin-top:22px">What was tested</h2><p>The actual museum loads this hall through its registry and map. Tests exercise the physical slider and button receivers; check retained geometry, primary material values and stage lamps; and read rendered GPU pixels for the mask, rim and emission. Floor support and standing clearance are sampled every quarter metre from the entrance through the new bay and around the composition.</p><p>The old corner entrance was blocked. Its marker now sits at (7,1), with a three-cell opening. Both authored portal positions are accepted without fallback. The exit still leads toward Reaction–Diffusion; travel into that next hall was not exercised. A publishing check confirms that every original artifact cell and all original structural cells in the later room remain.</p><p>Godot 4.6, compatibility renderer, XR disabled. Eleven inspection-camera views; the overview is elevated. The player costume is disabled only for capture. Headset interaction, VR performance and learner reconstruction remain untested. The existing default-audio-bus UID error and renderer-feature warnings remain in the log; this run has no script or shader errors.</p><p>This is a setting pass. tutorial.md still contains the earlier short plural-body exercise, and final.md still opens with the old five-object installation. Both are preserved. The next writing pass should introduce the composition bay without losing the reflection’s distinction between emission and incident light. The editable brief records that work.</p><p><a href="report.json">Checks</a> · <a href="engine.log">Engine log</a> · <a href="manifest.json">Source and image hashes</a> · <a href="source_manifest.json">Museum harness manifest</a> · <a href="SETTING.md">Editable brief</a></p><details><summary>Native checks</summary><ol>{checks}</ol></details><details><summary>Sources and before state</summary><ul>{links}</ul><p><a href="before/map_data.json">Before: map</a> · <a href="before/final.md">Preserved reflection</a> · <a href="before/tutorial.md">Preserved tutorial</a></p></details><details><summary>Reproduce</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_12_PinkExtravaganza --sequence shaders --probe tools/probes/shader_pink_museum.gd --render --no-bridges --output-tag composition</code></p></details></div></section><footer>Actual Endless Museum captures. Next setting: Reaction–Diffusion.</footer></html>''',encoding='utf-8')
(OUT/'SETTING.md').write_text('''# Pink — compose, then change the surround

Carry: circle mask → repetition → normal/view rim → emission; same sphere/cube/sofa. Primary: one shared recipe, independent DOTS/RIM/GLOW, PALE/LAYERED/RESET. SETTING changes backdrop and suspended scenery; retains primary material, meshes, transforms and stage lamps. No clock in primary recipe. Supplied room-coordinate three-plane projection handles the sofa’s missing UVs. PALE also changes ground/roughness; individual sliders preserve that choice. Compare individual contributions before preset combinations.

Space: 39×37 m hall. New stage at (27,8), yaw180; nearby bench. Existing modern chairs wear Crushed Pearl inside suspended rings; authored folds wear foil; existing dream water forms a ceiling at y5.65. Scenery has no shadow casting/GI contribution. Water has TIME animation/transparency, no fluid state/refraction/collider or corrected normals. Primary bodies retain fixed collision. Original three artifact cells and later room structure retained. Entrance marker moves from blocked corner to (7,1); opening x6–8. Exit cell retained, label corrected to Reaction–Diffusion.

Evidence: actual museum run, input-receiver assertions, GPU mask/rim/emission checks, quarter-metre supported standing route, valid authored portals; eleven native captures. Compatibility, XR disabled. No headset/performance/learner reconstruction/onward-travel claim. GPU emission probe uses a visible pigment to avoid near-black contrast ambiguity. Default audio-bus UID issue remains unrelated.

Text follow-up: tutorial.md exists but is a short proposed-focus/plural-body edit, not this reconstruction. final.md exists, unchanged, describes earlier collection. Focus the tutorial on composing three known operations with one complete minimal runnable shader; supply the room/projection/control adapter; test the printed program separately. Keep plural-body as an optional return. Preserve reflection’s emission-versus-lamp question, critique of claimed defaults and uncertainty around bodily readings. Place old “No desks” opening specifically in the earlier collection; introduce the adjacent controlled composition bay. Do not infer queer meaning from a pink palette alone. Next spatial pass: Reaction–Diffusion; establish actual retained state before claiming memory.
''',encoding='utf-8')
print(json.dumps({'page':str(OUT/'index.html'),'images':len(views),'checks':len(report['checks'])}))
