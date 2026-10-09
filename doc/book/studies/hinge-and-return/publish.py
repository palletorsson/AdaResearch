"""Publish native captures, separate texts, exact sources and a compact playable kit."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import shutil
import zipfile
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'doc/book/iterations/2026-10-01-clark-a-pose-left'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((HERE/'captures/results.json').read_text())
assert report['passed'] and len(report['checks']) == 29
for p in (HERE/'captures').glob('*'):
    if p.suffix in ('.png','.json'):
        shutil.copy2(p,OUT/p.name)
for name in ['ENCOUNTER.md','MAKING.md','RESEARCH.md','LINEAGE.md','README.md','score.gd','source-hashes.json','capture.gd']:
    shutil.copy2(HERE/name,OUT/name)

def md(name):
    return markdown.markdown((HERE/name).read_text(encoding='utf-8'),extensions=['fenced_code','tables','footnotes'])

CSS='''
:root{--bg:#f4f0e9;--ink:#252723;--muted:#5d615b;--line:#ccc6bb;--rose:#ae3457}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.6 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:45px 30px 90px}
a{color:inherit;text-underline-offset:4px}a:hover{color:var(--rose)}header{max-width:880px;margin:30px 0 50px}.eyebrow{text-transform:uppercase;letter-spacing:.14em;font-size:12px;font-weight:700}h1{font-size:clamp(52px,7.5vw,96px);letter-spacing:-.065em;line-height:1;margin:25px 0}h2{font-size:32px;letter-spacing:-.04em;line-height:1.2}h3{font-size:22px;line-height:1.3}.lead{font-size:24px;line-height:1.5;max-width:750px}
nav,.actions{display:flex;gap:15px;flex-wrap:wrap;margin:25px 0}nav a,.actions a{font-size:14px;padding:8px 14px;border:1px solid var(--line);text-decoration:none}.primary{background:var(--ink);color:var(--bg)}section{margin-top:64px;border-top:1px solid var(--line);padding-top:32px;scroll-margin-top:25px}.prose{max-width:750px}.reading{font:23px/1.75 Georgia,serif}.reading h1{font-size:42px;letter-spacing:-.035em}.reading .footnote{font:14px/1.6 system-ui,sans-serif;margin-top:40px}.small,figcaption{color:var(--muted);font-size:14px}.note{border-left:3px solid var(--rose);padding:3px 0 3px 20px;max-width:800px}.cols{display:grid;grid-template-columns:1fr 1fr;gap:24px}.card{border:1px solid var(--line);padding:24px}.card h3{margin-top:0}
figure{margin:20px 0}figure img{display:block;width:100%;height:auto}figcaption{padding-top:12px;max-width:850px}.switch{margin-top:22px}.switch input{position:absolute;width:1px;height:1px;clip-path:inset(50%)}.switch .options{display:flex;gap:8px;flex-wrap:wrap}.options label{padding:9px 15px;border:1px solid var(--line);cursor:pointer;font-size:14px}.switch figure{display:none}.switch input:focus-visible~.options{outline:2px solid var(--rose)}
#pose-start:checked~.options label[for=pose-start],#pose-left:checked~.options label[for=pose-left],#pose-return:checked~.options label[for=pose-return],#path-a:checked~.options label[for=path-a],#path-b:checked~.options label[for=path-b]{background:var(--ink);color:var(--bg)}
#pose-start:checked~.start,#pose-left:checked~.left,#pose-return:checked~.returned,#path-a:checked~.path-a,#path-b:checked~.path-b{display:block}
pre{background:#e8e2d7;padding:22px;white-space:pre-wrap;font:14px/1.65 Consolas,monospace;overflow-wrap:anywhere}code{font-size:.87em}table{border-collapse:collapse;font-size:14px}th,td{border-bottom:1px solid var(--line);padding:12px;text-align:left;vertical-align:top}details{border-top:1px solid var(--line);padding:18px 0}summary{cursor:pointer;font-weight:600}.making h1,.research h1,.lineage h1{font-size:38px;letter-spacing:-.04em;line-height:1.15}.making h2,.research h2{font-size:25px;margin-top:34px}.research{max-width:800px}.wide-scroll{overflow-x:auto}
@media(max-width:760px){main{padding:25px 18px 70px}.cols{grid-template-columns:1fr}.reading{font-size:20px}.lead{font-size:21px}pre{font-size:12px}}
'''

def figure(file,caption,cl=''):
    return f'<figure class="{cl}"><a href="{file}"><img src="{file}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

b=['<header><p class="eyebrow">Ada / one work, followed / 1 October 2026</p><h1>A pose left.</h1>',
   '<p class="lead">A hinge makes room for a change. A release rule decides whether it may remain.</p>',
   '<p>A working study after Lygia Clark’s <em>Bichos</em>, starting with the existing hinged-plate artifact and following what its code actually permits.</p>',
   '<nav><a href="#room">The study</a><a href="#reading">Read</a><a href="#paths">Same pose, another path</a><a href="#making">Make</a><a href="#research">Research notebook</a></nav></header>',
   figure('arrival.png','Actual Godot capture of our original six-plate study. The rose plate is selected. The support and starting configuration are authored choices.'),
   '<div class="actions"><a class="primary" href="hinge-and-return.zip">Download the Godot study</a><a href="score.gd">The editable score</a><a href="results.json">29 native checks</a></div>',
   '<p class="small">Desktop companion, Godot 4.6. A prepared viewer and specimen are supplied. The main museum has not been rearranged.</p>',
   '<section id="room"><h2>One object. Two release rules.</h2><div class="prose"><p>Turn the selected plate and let go. With <b>Leave it</b>, its angle remains. With <b>Return it</b>, the same object moves back to the starting angles. The difference is a policy we can locate in the code.</p>',
   '<p>These are three recorded states from the same camera. Use the Godot kit for live manipulation.</p></div>',
   '<div class="switch"><input type="radio" name="pose" id="pose-start" checked><input type="radio" name="pose" id="pose-left"><input type="radio" name="pose" id="pose-return">',
   '<div class="options"><label for="pose-start">On arrival</label><label for="pose-left">Left by the visitor</label><label for="pose-return">Returned by the rule</label></div>',
   figure('arrival.png','The chosen starting angles. The initial-pose search selects a configuration; it is not a privileged shape of Clark’s work.','start'),
   figure('left.png','Joint one has moved to 50°. Its descendants travel with it. The other local joint angles remain unchanged.','left'),
   figure('returned.png','The imposed return restores the same angle vector. Our test confirms all six plate transforms return to their starting values.','returned'),'</div>',
   '<div class="note"><b>The distinction matters.</b> These are kinematic plates. Their stored angles remain without a gravity or friction calculation. The fixed base cannot be lifted, and editing a hinge does not reject intersections.</div></section>',
   '<section id="reading"><p class="eyebrow">Draft encounter / read without the code</p><div class="reading prose">',md('ENCOUNTER.md'),'</div></section>',
   '<section id="paths"><h2>The shape forgets a path.</h2><div class="prose"><p>The old artifact description claimed that reversing the order of two joint adjustments must give a different final shape. The native test contradicted it. For this hierarchy, identical final local angles produce identical final plate transforms.</p>',
   '<p>The corner trace reveals what the final pose leaves out. Joint 1 then joint 2, and joint 2 then joint 1, take different paths through the room. Both end at the same angles: 50° and 30°. Other joints keep their starting values.</p></div>',
   '<div class="switch"><input type="radio" name="path" id="path-a" checked><input type="radio" name="path" id="path-b"><div class="options"><label for="path-a">Parent, then child</label><label for="path-b">Child, then parent</label></div>',
   figure('parent-then-child.png','Joint 1, then joint 2. The rose line records successive world positions of the same corner. Camera, final angles and selected plate are held fixed.','path-a'),
   figure('child-then-parent.png','Joint 2, then joint 1. A different path reaches the same corner position and plate configuration.','path-b'),'</div>',
   '<p class="note">This brings <b>Point Trace</b> back into <b>Rotation</b>. A record of movement can distinguish experiences whose final shapes are identical.</p></section>',
   '<section id="making"><p class="eyebrow">Making / a different reading mode</p><div class="making prose">',md('MAKING.md'),
   '<details><summary>The full editable score — used by this study</summary><pre><code>',html.escape((HERE/'score.gd').read_text()),'</code></pre></details></div>',
   figure('controls.png','The working desktop controls. Move a plate directly or choose a joint and slider; release applies the chosen policy.'),'</section>',
   '<section id="lineage"><div class="lineage">',md('LINEAGE.md'),'</div></section>',
   '<section id="research"><p class="eyebrow">Research notebook / source, code, observation, revision</p><div class="research">',md('RESEARCH.md'),'</div></section>',
   '<section><h2>What changed in the project</h2><div class="cols"><div class="card"><h3>The existing artifact</h3><p>Corrected the desktop pointer angle sign. Revised unsupported claims about a transformation group and adjustment order. The caption now states the actual behaviour: “no automatic return”.</p></div>',
   '<div class="card"><h3>The companion</h3><p>Added two release policies, a corner trace, desktop controls, native evidence, a short encounter and a focused making exercise. The specimen’s production code is copied exactly; the neutral display finish and room are supplied by the study.</p></div></div>',
   '<div class="actions"><a href="changes.diff">Exact artifact changes</a><a href="RESEARCH.md">Research notes</a><a href="source-hashes.json">Specimen provenance</a><a href="results.json">Native evidence</a><a href="pointer-before.log">The failing pointer test before correction</a><a href="/book-review/doc/book/iterations/2026-10-01-artist-capacity/index.html#profile-hinge">Back to the capacity atlas</a></div>',
   '<p class="small">The kit ran without the XR addon. No headset, installed-hall, student or physical-material trial is claimed. The next investigation is a free assembly with weight and contact, beginning with two plates.</p></section>']

(OUT/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A pose left — after Lygia Clark / Ada</title><style>'+CSS+'</style><body><main>'+''.join(b)+'</main></body></html>',encoding='utf-8')

# Keep a narrow diff against the exact working files read at the start of this task.
parts=[]
for name,source in [('bicho_hinge.gd','commons/artifacts/bicho_hinge/bicho_hinge.gd'),('bicho_hinge.json','commons/artifacts/registry/bicho_hinge.json')]:
    parts.extend(difflib.unified_diff((OUT/'before'/name).read_text(encoding='utf-8').splitlines(True),(ROOT/source).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+source,tofile='after/'+source))
(OUT/'changes.diff').write_text(''.join(parts),encoding='utf-8')

with zipfile.ZipFile(OUT/'hinge-and-return.zip','w',zipfile.ZIP_DEFLATED) as bundle:
    for p in sorted(HERE.rglob('*')):
        if not p.is_file() or any(s in p.relative_to(HERE).parts for s in ['.godot','captures','__pycache__']):
            continue
        if p.suffix in ['.log','.uid'] or p.name in ['capture-output.log']:
            continue
        bundle.write(p,'hinge-and-return/'+p.relative_to(HERE).as_posix())
output_hashes={p.relative_to(OUT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.iterdir() if p.is_file() and p.name!='publication-hashes.json'}
(OUT/'publication-hashes.json').write_text(json.dumps(output_hashes,indent=2)+'\n',encoding='utf-8')
print(f'Published {len(report["checks"])} native checks, {len(report["captures"])} views and the playable kit to {OUT}')
