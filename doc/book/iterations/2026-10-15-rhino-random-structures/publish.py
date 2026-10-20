from pathlib import Path
import hashlib,html,json,zipfile,shutil
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'commons/artifacts/random_structure_studies'
report=json.loads((HERE/'verification.json').read_text(encoding='utf8'))
assert report['passed']
shutil.copy2(SOURCE/'README.md',HERE/'implementation.md')
registry=ROOT/'commons/artifacts/registry/random_structures.json'
entries=json.loads(registry.read_text(encoding='utf8'))['artifacts']
for token,entry in entries.items():
    assert (ROOT/entry['scene'].removeprefix('res://')).is_file()
    assert entry['lookup_name']==token and entry['map_ready']
files=[p for p in SOURCE.iterdir() if p.suffix in ['.gd','.tscn','.md']]+[registry]
(HERE/'manifest.json').write_text(json.dumps({'files':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'checks':len(report['checks']),'scope':'Collection preview; no existing map placement'},indent=2),encoding='utf8')
with zipfile.ZipFile(HERE/'godot-random-structures.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in files: archive.write(p,p.relative_to(ROOT).as_posix())
items={
 'columns':('A field of columns','The bases keep their grid addresses. Two retained draws per cylinder can change height, radius or both. A dense skyline comes from decisions about dimensions, not from scattering the addresses.'),
 'spheres':('A field lifted into space','One hundred spheres keep their horizontal addresses and radius. Random height turns their overlapping surfaces into a raised field. The geometry remains individual spheres.'),
 'lattice':('Connections between levels','Four levels keep 196 node addresses. The pictured pair shares 534 selected pipes; range changes the upper-node positions. A separate probability control changes the connections while keeping positions fixed.'),
 'tree':('One branch becomes three','A trunk divides into three, nine and twenty-seven tips. Forty branches keep their parent-child relations while seeded offsets change where they arrive. Thickness follows depth.')}
data=json.dumps(items)
cards=''.join(f'<details name="study" {"open" if key=="columns" else ""}><summary>{title}</summary><img src="{key}.png" alt="{title}: zero and full geometric variation"><p>{desc}</p></details>' for key,(title,desc) in items.items())
style='''*{box-sizing:border-box}body{margin:0;background:#14242c;color:#e5eee9;font:18px/1.6 system-ui}main{max-width:1450px;margin:auto;padding:30px}h1{font-size:42px;line-height:1.15;margin:18px 0}h2{font-size:27px}a{color:#9bdad8}nav{display:flex;flex-wrap:wrap;gap:20px;font-size:15px}.intro{max-width:980px}summary{padding:13px 25px;border:1px solid #69888d;background:#29404a;color:#fff;font-size:17px;cursor:pointer}summary:hover{background:#3c5e68}img{width:100%;height:auto;border:1px solid #536974}.small{font-size:15px;color:#b7cbc7}code{background:#263a42;padding:3px 6px;font-size:15px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:35px}@media(max-width:850px){.grid{grid-template-columns:1fr}main{padding:18px}h1{font-size:32px}}'''
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random structures — Rhino to Godot</title><style>{style}</style><main><nav><a href="README.md">Trial and provenance</a><a href="verification.json">58 native checks</a><a href="godot-random-structures.zip">Godot files for the Ada project</a><a href="implementation.md">Controls and translation guide</a></nav><div class="intro"><p class="small">ADA RESEARCH · COLLECTION TRIAL · 15 OCTOBER 2026</p><h1>What can a random number build?</h1><p>Four Godot studies from the supplied Rhino examples. The left object has zero geometric variation; the right applies full range to the same retained draws. The structure's rule stays available for inspection.</p></div>{cards}<p class="small">These are native Godot captures. The live preview has range, seed, target/connection, KEEP and REPLAY controls, plus orbit and zoom.</p><div class="grid"><section><h2>Open the live study</h2><p>In the Ada Research Godot project, open <code>commons/artifacts/random_structure_studies/preview.tscn</code> and press F6. The archive contains the new files and registry entries; it uses Ada's existing interaction components.</p><p>The four studies are registered separately for placement. They have not been added to an existing hall.</p></section><section><h2>Keep the outcome; change the question</h2><p>Changing range reuses the retained draws. SEED +1 obtains a different deterministic draw record. KEEP saves the raw draws and settings; REPLAY reopens them. For the cylinders, TARGET separates height from radius. For the lattice, LINKS separates connectivity from displacement.</p><p class="small">58 checks pass, including saved reconstruction, all pipe endpoints and grid-boundary rules. Physical headset and learner trials remain open.</p></section></div></main></html>'''
(HERE/'index.html').write_text(page,encoding='utf8')
print('Published',HERE/'index.html')
