"""Publish native captures plus an orbit viewer of exact Godot GLB exports."""
from pathlib import Path
from generated_storage import model_directory
import hashlib, json, shutil, struct
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-one-arcade-four-operations'
RUN=R/'ada_run/architecture_variations'
B=R/'commons/artifacts/architecture_variations'
WEB=R.parent/'ada_encyclopedia/public/research/architecture-variations'
THREE=R.parent/'ada_encyclopedia/node_modules/three'
receipt=json.loads((RUN/'report.json').read_text());assert len(receipt['checks'])==35 and not receipt['failed']
for p in [O/'museum',O/'validation',O/'source',WEB/'models',WEB/'vendor/controls',WEB/'vendor/loaders',WEB/'vendor/utils']:p.mkdir(parents=True,exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'museum'/p.name)
models={}
for p in model_directory(RUN).glob('*.glb'):
    raw=p.read_bytes();assert struct.unpack('<4sII',raw[:12])==(b'glTF',2,len(raw))
    length,kind=struct.unpack('<II',raw[12:20]);assert kind==0x4e4f534a
    doc=json.loads(raw[20:20+length]);assert doc['meshes'] and doc['nodes']
    models[p.name]={'sha256':hashlib.sha256(raw).hexdigest(),'meshes':len(doc['meshes']),'bytes':len(raw)}
    shutil.copy2(p,WEB/'models'/p.name)
for p in B.iterdir():
    if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'source'/p.name)
for name in ['report.json','native.log']:shutil.copy2(RUN/name,O/'validation'/name)
for source,dest in [('build/three.module.js','three.module.js'),('build/three.core.js','three.core.js'),('examples/jsm/controls/OrbitControls.js','controls/OrbitControls.js'),('examples/jsm/loaders/GLTFLoader.js','loaders/GLTFLoader.js'),('examples/jsm/utils/BufferGeometryUtils.js','utils/BufferGeometryUtils.js'),('examples/jsm/utils/SkeletonUtils.js','utils/SkeletonUtils.js'),('LICENSE','LICENSE')]:shutil.copy2(THREE/source,WEB/'vendor'/dest)
shutil.copy2(R/'tools/architecture_variations_viewer.html',WEB/'index.html')
model_manifest={'producer':'Godot 4.6 GLTFDocument; geometry is exported from the tested artifact, not reconstructed in JavaScript','models':models,'three_version':json.loads((THREE/'package.json').read_text())['version']}
(WEB/'manifest.json').write_text(json.dumps(model_manifest,indent=2)+'\n',encoding='utf-8')
report='''# One arcade, four operations

The previous corridor becomes a curved court, a hinged curl, a repeated field and a stretched canopy. All four studies reuse its actual bay constructor. A fixed miniature keeps the original visible.

**[Open the interactive 3D viewer](/research/architecture-variations/index.html#stretch)** â€” orbit, zoom, compare viewpoints and inspect the wireframe. The browser displays actual geometry exported from Godot; use the Godot scene for live parameters and grabbing.

![The roof becomes a canopy in the Godot courtyard.](museum/stretch-ground.png)

## 00 / The familiar assembly

Twelve upright bays repeat the original floor, columns, roof, rails and pink guide. The miniature beside the console retains eight bays at one quarter scale. The active object has a 4â€“24 bay control.

![The source and fixed reference.](museum/source.png)

## 01 / A curved court

A longitudinal position becomes an angle. Height stays unchanged. Width affects the circumference, so this is a deformation, not a chain of rigid rotated boxes. At the default eighteen bays, an ordinary passage nearly closes around a courtyard.

![The curved court seen from above eye level.](museum/curve.png)

<details><summary>Stand inside the curve</summary>

![The curved arcade at eye level.](museum/curve-inside.png)

</details>

## 02 / A moving centre

Here the bays remain rigid. Their shared hinge is near the roof, and the floors separate as the chain turns. Move the pink point down: the angles remain unchanged, but the whole assembly takes another position. At some settings roofs intersect. A valid joint transformation is not evidence of a habitable route.

![Rigid bays fold around high hinges.](museum/hinge.png)

<details><summary>The same angles with floor hinges</summary>

![Moving the centres changes the arrangement.](museum/hinge-floor.png)

</details>

## 03 / The repeated field

Eighteen bays, three rows, two tiers: 108 copies sharing one mesh. A single local decision becomes a large spatial order. CHANGE adds rows and tiers; BAYS changes the longitudinal count. This finite array does not simulate an infinite world.

![A bounded field of 108 bays.](museum/field.png)

<details><summary>The field at ground level</summary>

![Repetition viewed from below.](museum/field-ground.png)

</details>

## 04 / The stretched roof

A weighted displacement pulls the sampled roof and upper columns. Influence falls to zero away from the attachment and at ground level. Floor contact positions stay fixed while the upper assembly becomes a canopy. It retains its triangle count; it is not simulated fabric, damage, or a reconstructed game-engine fault.

![One attachment creates a canopy.](museum/stretch.png)

This is the strongest connection to the supplied game screenshots: a surface that exceeds its intended dimensions starts to suggest another architectural use. The source remains recognisable inside the strange result.

## In your hands

![Native dials, rectangular buttons and the shared pink grab point.](museum/console.png)

Run `res://commons/artifacts/architecture_variations/preview.tscn` with F6 in the Ada project. The standalone courtyard uses the existing desktop player. Aim/click presets, drag CHANGE or BAYS, and drag the pink point for Hinge or Stretch. Keys 1â€“5 select studies; left/right change strength; up/down change count; R restores Source. The same handle supports XRTools grip when used with an XR rig; this standalone preview spawns the desktop player.

## What this suggests for the research

These are our experiments in relation to the references, not reconstructions of their works. Borromini helps us look at geometric enclosure; Hadid and Gehry at deliberate formal invention and its realisation; Daniel Brown at exploring generative worlds; Superstudio at the reach of a repeated order. Escher opens a separate question about orientation that these four studies do not yet implement. Bacon and Bellmer make the body and its supporting or manipulating frame part of the inquiry.

- [Borromini / San Carlino](https://sancarlino.ch/espacios/the-church/)
- [Zaha Hadid / MAXXI](https://www.maxxi.art/wp-content/uploads/2017/06/MAXXI_ZahaHadid_PR.pdf)
- [Gehry / Guggenheim Bilbao construction](https://www.guggenheim-bilbao.eus/en/the-building/the-construction)
- [Daniel Brown / generative architecture](https://danielbrowns.com/)
- [Superstudio / The Continuous Monument](https://www.moma.org/collection/works/936)
- [Escher / Relativity](https://escherinhetpaleis.nl/en/about-escher/masterpieces/relativity)
- [Bacon / curator discussion of Invisible Rooms](https://www.sothebys.com/en/articles/francis-bacon-invisible-rooms-oliver-barker-in-conversation-with-dr-ina-conzen)
- [Bellmer / The Doll](https://www.moma.org/collection/works/43944)

## Room and evidence

![The research courtyard from above.](museum/above.png)

**35 native checks pass.** These cover curve radius and height, hinge coincidence, rigid lengths, repetition, bounded deformation, unchanged ground points, triangle count, preserved source/reference, exact reset, native dials, real desktop button rays, supplied XRTools controller poses and six native GLB exports. [Receipt](validation/report.json) Â· [Engine log](validation/native.log) Â· [Run instructions](source/README.md).

The changing architecture has no colliders: the fixed courtyard floor supplies walking support. These are visual research models, not structurally validated or climbable buildings. No physical headset or Quest performance run was performed. The log retains existing project UID and Jolt warnings. This is a separate museum-style research courtyard; no spine placement, canonical tutorial or final text has been changed.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#efeee5;color:#26343a;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1300px;margin:auto;padding:32px 50px}header{font:13px Arial;letter-spacing:.14em;text-transform:uppercase;border-bottom:1px solid #bdc5bd}h1{font-size:clamp(42px,6vw,76px);font-weight:400;line-height:1.05}h2{font:22px Arial;margin-top:65px}p,li{max-width:850px}img{display:block;width:100%;border:1px solid #bdc5bd;margin:25px 0}a{color:#a14472}summary{cursor:pointer;font-family:Arial;font-size:15px}details{margin:25px 0}code{font:.82em Consolas,monospace;overflow-wrap:anywhere}footer{font:14px Arial;border-top:1px solid #bdc5bd}@media(max-width:750px){header,main,footer{padding:22px}}'''
(O/'index.html').write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One arcade, four operations</title><style>{style}</style></head><body><header>Endless Museum / spatial studies / 9 October 2026</header><main>{markdown.markdown(report,extensions=["extra"])}</main><footer>Endless Museum Â· always another room</footer></body></html>',encoding='utf-8')
hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [*B.glob('*.gd'),*B.glob('*.tscn'),R/'tools/probes/architecture_variations.gd',R/'commons/artifacts/architecture_spine/architecture_spine.gd',R/'commons/artifacts/camera_glitch_study/glitch_console.gd',R/'algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_handle.gd']}
(O/'validation/source-hashes.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'viewer':str(WEB/'index.html'),'models':len(models),'checks':35}))
from museum_placement_status import decorate
decorate(O,'architecture_variations','architecture_variations.json')
