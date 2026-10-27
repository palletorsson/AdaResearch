"""Publish the tested model study; screenshots are native Godot captures."""
from pathlib import Path
from generated_storage import model_directory
import hashlib,json,shutil,struct
import markdown
from museum_placement_status import inspect
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-when-parts-stop-agreeing'
RUN=R/'ada_run/model_disagreement'
B=R/'commons/artifacts/model_disagreement'
WEB=R.parent/'ada_encyclopedia/public/research/model-disagreement'
THREE=R.parent/'ada_encyclopedia/node_modules/three'
receipt=json.loads((RUN/'report.json').read_text())
assert len(receipt['checks'])>=42 and not receipt['failed']
log=(RUN/'native.log').read_text(encoding='utf-8',errors='replace')
assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
for p in [O/'museum',O/'validation',O/'source',WEB/'models',WEB/'vendor/controls',WEB/'vendor/loaders',WEB/'vendor/utils']:p.mkdir(parents=True,exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'museum'/p.name)
models={}
for p in model_directory(RUN).glob('*.glb'):
    raw=p.read_bytes();assert struct.unpack('<4sII',raw[:12])==(b'glTF',2,len(raw))
    n,t=struct.unpack('<II',raw[12:20]);assert t==0x4e4f534a
    document=json.loads(raw[20:20+n]);assert document['meshes']
    models[p.name]={'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'meshes':len(document['meshes'])}
    shutil.copy2(p,WEB/'models'/p.name)
for p in B.iterdir():
    if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'source'/p.name)
for p in ['report.json','native.log']:shutil.copy2(RUN/p,O/'validation'/p)
for source,dest in [('build/three.module.js','three.module.js'),('build/three.core.js','three.core.js'),('examples/jsm/controls/OrbitControls.js','controls/OrbitControls.js'),('examples/jsm/loaders/GLTFLoader.js','loaders/GLTFLoader.js'),('examples/jsm/utils/BufferGeometryUtils.js','utils/BufferGeometryUtils.js'),('examples/jsm/utils/SkeletonUtils.js','utils/SkeletonUtils.js'),('LICENSE','LICENSE')]:shutil.copy2(THREE/source,WEB/'vendor'/dest)
shutil.copy2(R/'tools/model_disagreement_viewer.html',WEB/'index.html')
(WEB/'manifest.json').write_text(json.dumps({'producer':'Native Godot 4.6 GLTFDocument exports. Browser orbits saved states; it does not run the generator.','models':models},indent=2),encoding='utf-8')
placement=inspect('model_disagreement','model_disagreement.json')
(O/'museum-placement.json').write_text(json.dumps(placement,indent=2),encoding='utf-8')
report=(O/'REPORT.md').read_text(encoding='utf-8')
if placement['main_route']:
    report='> **Installation update:** This study now runs inside the Endless Museum, in Shaders / Patterns. [See the actual hall and native checks](../2026-10-09-glitch-inside-the-museum/index.html). The original research report below documents the earlier standalone experiment.\n\n'+report
style='''*{box-sizing:border-box}body{margin:0;background:#eeece3;color:#28363a;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1280px;margin:auto;padding:30px 46px}header{font:13px Arial;letter-spacing:.12em;border-bottom:1px solid #b9c0b9}h1{font-size:clamp(40px,6vw,76px);line-height:1.1;font-weight:400}h2{font:24px Arial;margin-top:60px}p,li{max-width:900px}img{width:100%;display:block;margin:28px 0;border:1px solid #b9c0b9}a{color:#97486e}table{width:100%;border-collapse:collapse;font:15px/1.55 Arial}td,th{padding:16px;text-align:left;vertical-align:top;border-bottom:1px solid #bbc2ba}th{background:#ddd6c5}code{font:.82em Consolas,monospace;overflow-wrap:anywhere}footer{font:14px Arial;border-top:1px solid #b9c0b9}@media(max-width:700px){header,main,footer{padding:22px}table{display:block;overflow-x:auto}}'''
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>When parts stop agreeing</title><style>'+style+'</style></head><body><header>ENDLESS MUSEUM / MODEL STUDIES / 9 OCTOBER 2026</header><main>'+markdown.markdown(report,extensions=['extra'])+'</main><footer>Endless Museum Â· always another room</footer></body></html>',encoding='utf-8')
sources=[*B.glob('*.gd'),*B.glob('*.tscn'),R/'tools/probes/model_disagreement.gd',R/'commons/artifacts/model_overflow/model_overflow.gd',R/'commons/artifacts/architecture_spine/architecture_spine.gd',R/'commons/artifacts/architecture_variations/architecture_variations.gd',R/'commons/artifacts/camera_glitch_study/glitch_console.gd']
(O/'validation/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'viewer':str(WEB/'index.html'),'checks':len(receipt['checks']),'models':len(models),'placement':placement['status']}))
