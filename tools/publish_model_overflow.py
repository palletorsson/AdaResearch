"""Publish the tested model study; screenshots are native Godot captures."""
from pathlib import Path
import hashlib,json,shutil,struct
import markdown
from museum_placement_status import inspect
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-the-model-calls-itself'
RUN=R/'ada_run/model_overflow'
B=R/'commons/artifacts/model_overflow'
WEB=R.parent/'ada_encyclopedia/public/research/model-overflow'
THREE=R.parent/'ada_encyclopedia/node_modules/three'
receipt=json.loads((RUN/'report.json').read_text())
assert len(receipt['checks'])>=43 and not receipt['failed']
log=(RUN/'native.log').read_text(encoding='utf-8',errors='replace')
assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
for p in [O/'museum',O/'validation',O/'source',WEB/'models',WEB/'vendor/controls',WEB/'vendor/loaders',WEB/'vendor/utils']:p.mkdir(parents=True,exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'museum'/p.name)
models={}
for p in RUN.glob('*.glb'):
    raw=p.read_bytes();assert struct.unpack('<4sII',raw[:12])==(b'glTF',2,len(raw))
    n,t=struct.unpack('<II',raw[12:20]);assert t==0x4e4f534a
    document=json.loads(raw[20:20+n]);assert document['meshes']
    models[p.name]={'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'meshes':len(document['meshes'])}
    shutil.copy2(p,WEB/'models'/p.name)
for p in B.iterdir():
    if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'source'/p.name)
for p in ['report.json','native.log']:shutil.copy2(RUN/p,O/'validation'/p)
for source,dest in [('build/three.module.js','three.module.js'),('build/three.core.js','three.core.js'),('examples/jsm/controls/OrbitControls.js','controls/OrbitControls.js'),('examples/jsm/loaders/GLTFLoader.js','loaders/GLTFLoader.js'),('examples/jsm/utils/BufferGeometryUtils.js','utils/BufferGeometryUtils.js'),('examples/jsm/utils/SkeletonUtils.js','utils/SkeletonUtils.js'),('LICENSE','LICENSE')]:shutil.copy2(THREE/source,WEB/'vendor'/dest)
shutil.copy2(R/'tools/model_overflow_viewer.html',WEB/'index.html')
(WEB/'manifest.json').write_text(json.dumps({'producer':'Native Godot 4.6 GLTFDocument exports. Browser orbits saved states; it does not run the generator.','models':models},indent=2),encoding='utf-8')
placement=inspect('model_overflow','model_overflow.json');assert not placement['placements']
(O/'museum-placement.json').write_text(json.dumps(placement,indent=2),encoding='utf-8')
report='''# The model calls itself

**PREVIEW ONLY · built in Godot · no museum map or route placement.** This is one new controllable artifact with three model-level fault studies. The room in the images is a separate research preview, using the existing Ada desktop player and interaction controls.

**[Explore the native models in 3D](/research/model-overflow/index.html#calls)** — orbit, zoom, compare saved states, and reveal the triangle edges. Use the Godot scene for live stepping and capacity changes.

![Twenty admitted calls; the next bay is shown pink and refused.](museum/calls.png)

The earlier architectural bay becomes a procedure that does not know when to return. Each child inherits another turn, translation and small increase in scale. The result curls out of reach. Beside it, a stack of pink plates counts the pending frames. The ordinary bay remains on its plinth.

## Three failures, three different models

| Study | Operation | What changes in the model | What stops it |
|---|---|---|---|
| Calls without a base case | Each simulated call requests a child before returning | A chain of inherited transforms builds a rising curl | The next frame is refused at the selected capacity |
| Forgotten restore | Save a transform, make a sibling, omit restoration | Each sibling inherits all the previous transformations | Sixteen requested siblings, or the selected frame limit |
| Wrapped vertex writes | A second model reuses the first model's vertex addresses | Old faces stretch between newly written and retained positions | A fixed 228-slot buffer; at most 224 overwritten slots |

The first is a bounded model of call-stack exhaustion. The second is a transform-stack leak. The third is deliberate address aliasing. They can inform the same visual research, but they are not three names for the same software fault.

## 01 / A call that never returns

![Six pending calls.](museum/calls-six.png)

![Twelve pending calls.](museum/calls-twelve.png)

Start with six frames. Press STEP or PLAY. At capacity 20, twenty bays are admitted. Call 21 is refused before it can be appended; its pink bay is an explanatory preview of the rejected request. Raising CAPACITY admits more calls. Reset clears the process.

The generator stores its simulated frames in an ordinary array and runs a bounded loop. It does not recurse until Godot crashes. A real call-stack overflow commonly interrupts execution; the retained sculpture here is an explicit artistic choice. Missing base cases and excessively deep calls are documented causes of stack exhaustion. [MDN explanation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Too_much_recursion).

![The growing assembly at eye level.](museum/calls-ground.png)

The question for this room is precise: **what should remain when the next operation cannot be admitted?** We keep the work already made, expose the refusal, and leave the source recoverable.

## 02 / A building forgets where to return

![Correct sibling arrangement.](museum/source.png)

![The same sixteen operations with restoration omitted.](museum/leak.png)

SOURCE places sixteen independent bays around one centre. LEAK saves a transform but fails to restore it before making the next sibling. Scale and rotation accumulate; intended neighbours become an overlapping, displaced group. No random values are added. The first bay agrees with the control; disagreement begins at the second.

This offers a different version of the earlier moving-pivot experiment. The changed shape comes from the bookkeeping of the construction. Returning is part of making a form.

## 03 / New data, old faces

![The tower before its addresses are reused.](museum/unwritten.png)

![Eighty-four overwritten positions pull the old skin across the gap.](museum/wrap.png)

A simpler tower makes the data relationship visible: nineteen rings of twelve stored positions, joined by 432 triangles. A second construction starts writing at logical address 228. The explicit rule `address % 228` sends it back to the first slot. The old triangles still refer to those addresses. Some corners now belong to one construction, others to another, and the mesh becomes a bridge between them.

All accesses stay inside the array. The source record is kept separately. This models address reuse, not genuine memory corruption; changing stored positions while keeping indices explains the visible deformation. Godot's indexed mesh arrays supply that position/index relationship. [Godot ArrayMesh documentation](https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html).

![The rewritten skin viewed from the floor.](museum/wrap-ground.png)

The useful connection to the game glitches is material: a face still joins its designated corners even when their new positions make the resulting surface unreasonable. It is not evidence that any supplied game screenshot had this exact cause.

## Operate the study

![The native controls.](museum/console.png)

Run `res://commons/artifacts/model_overflow/preview.tscn` with F6. SOURCE gives the corrected sibling arrangement. CALLS, LEAK and WRAP select the studies. STEPS scrubs the operation; STEP advances once; PLAY / HOLD advances every 0.35 seconds. CAPACITY controls pending frames in CALLS and LEAK only; WRAP keeps 228 vertex slots. RESET restores the current study to its beginning. Arrow keys adjust steps/capacity; 1–4 select modes; Space plays; Enter steps; R resets.

The first two studies call the actual earlier bay constructor. The third introduces the simpler tower skin so its vertex addresses can be followed. The fixed miniature is the earlier bay, not a miniature of the tower. The model surfaces have no colliders; the fixed preview courtyard supports walking.

## Placement and evidence

![The preview courtyard from above.](museum/above.png)

**43 native checks pass.** The run verifies capacity before append, preservation after refusal, inherited transforms, the first divergent sibling, valid triangle indices, partial buffer writes, finite model coordinates, unchanged source data, exact reset, native dial values, play/hold, real desktop pointer presses and eight GLB exports. The screenshots are rendered by Godot, including eye-level and elevated views.

[Test receipt](validation/report.json) · [Engine log](validation/native.log) · [Reproduction and scope](source/README.md) · [Placement record](museum-placement.json)

An initial capture run caught a primitive-mesh vertex-count API error. It was corrected and the complete run passed again. Existing project UID/Jolt/shutdown warnings remain. No native stack exhaustion, physics collapse, physical headset test or Quest performance claim is made.

No canonical tutorial, final text, map or sequence order changed. A possible later encounter sits between recursive construction and the existing glitch studies: make a form, accumulate its pending work, reach a limit, then decide what to preserve. That is a placement proposal, not an installation.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#eeece3;color:#28363a;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1280px;margin:auto;padding:30px 46px}header{font:13px Arial;letter-spacing:.12em;border-bottom:1px solid #b9c0b9}h1{font-size:clamp(40px,6vw,76px);line-height:1.1;font-weight:400}h2{font:24px Arial;margin-top:60px}p,li{max-width:900px}img{width:100%;display:block;margin:28px 0;border:1px solid #b9c0b9}a{color:#97486e}table{width:100%;border-collapse:collapse;font:15px/1.55 Arial}td,th{padding:16px;text-align:left;vertical-align:top;border-bottom:1px solid #bbc2ba}th{background:#ddd6c5}code{font:.82em Consolas,monospace;overflow-wrap:anywhere}footer{font:14px Arial;border-top:1px solid #b9c0b9}@media(max-width:700px){header,main,footer{padding:22px}table{display:block;overflow-x:auto}}'''
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The model calls itself</title><style>'+style+'</style></head><body><header>ENDLESS MUSEUM / MODEL STUDIES / 9 OCTOBER 2026</header><main>'+markdown.markdown(report,extensions=['extra'])+'</main><footer>Endless Museum · always another room</footer></body></html>',encoding='utf-8')
sources=[*B.glob('*.gd'),*B.glob('*.tscn'),R/'tools/probes/model_overflow.gd',R/'commons/artifacts/architecture_spine/architecture_spine.gd',R/'commons/artifacts/architecture_variations/architecture_variations.gd',R/'commons/artifacts/camera_glitch_study/glitch_console.gd']
(O/'validation/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'viewer':str(WEB/'index.html'),'checks':len(receipt['checks']),'models':len(models),'placement':placement['status']}))
