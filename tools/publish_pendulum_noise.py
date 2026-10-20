"""Publish native images, exact printed source and scoped assertions for G1."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-pendulum-a-recorded-push';A=R/'commons/artifacts/pendulum_noise';M=R/'commons/maps/Vectors_Act4b_Oscillation';run=R/'ada_run/encounter_pilot/Vectors_Act4b_Oscillation'
core=json.loads((O/'checks.json').read_text(encoding='utf-8'));room=json.loads((run/'report.json').read_text(encoding='utf-8'))
assert core['passed'] and not room['failures'];assert len(core['checks'])==43 and len(room['checks'])==21
for p in [O/'core-engine.log',run/'engine.log']:
 s=p.read_text(encoding='utf-8');assert 'SCRIPT ERROR' not in s and 'Parse Error' not in s,p
(O/'museum').mkdir(exist_ok=True);(O/'code').mkdir(exist_ok=True)
for p in run.glob('*.png'):shutil.copy2(p,O/'museum'/p.name)
for n in ['report.json','engine.log','source_manifest.json']:shutil.copy2(run/n,O/'museum'/n)
sources=[A/'pendulum_pair.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'angle_point.gd',A/'PendulumNoise.gd',A/'PendulumNoise.tscn']
blocks=re.findall(r'```(?:gdscript|ini)\n(.*?)\n```',(A/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==len(sources)
for block,p in zip(blocks,sources):
 assert block.rstrip()==p.read_text(encoding='utf-8').rstrip(),p
 shutil.copy2(p,O/'code'/p.name)
for src,dest in [(A/'tutorial.md',O/'tutorial.md'),(A/'README.md',O/'README.md'),(M/'tutorial.md',O/'hall-tutorial.md'),(M/'final.md',O/'hall-final.md')]:shutil.copy2(src,dest)
before=json.loads((O/'before/map_data.json').read_text(encoding='utf-8'));now=json.loads((M/'map_data.json').read_text(encoding='utf-8'))
for layer in ['structure','utilities']:assert before['layers'][layer]==now['layers'][layer]
def placements(d):return {(x,z):str(t).strip() for z,row in enumerate(d['layers']['interactables']) for x,t in enumerate(row) if str(t).strip()}
old=placements(before);new=placements(now);assert all(new[k]==v for k,v in old.items())
assert len(new)==len(old)+1 and new[(8,20)]=='pendulum_noise:90#pin:1#plinth:0'
diff=''
for n in ['map_data.json','tutorial.md','final.md']:
 diff+=''.join(difflib.unified_diff((O/'before'/n).read_text(encoding='utf-8').splitlines(True),(M/n).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+n,tofile='after/'+n))
(O/'changes.diff').write_text(diff,encoding='utf-8')
report=f'''# The same release / a recorded push

9 October 2026 · G1 implemented in the existing Forces oscillation hall.

## What changed

One optional comparison at cell[8,20],rotation90°, between the spring row and swings. The inherited PointBody sphere becomes a constrained release handle. Its rod remains1.1m long during pickup. OFF/ON changes the external force while matching damping; SAME INPUT changes B's damping while matching force. Parameter changes reset the pair; REPLAY reuses the stored input. Two sliders and five buttons remain together.

This is an explicit angular point-mass model, extending the equation already used by the museum's pendulum. It is not a Jolt joint or contact solver. Existing engine-driven springs and swings remain in the same hall. Five earlier works and the hall infrastructure token retain their positions; architecture, utilities and spine order remain unchanged. The installer rederived only this hall's plan row.

## Evidence

{len(core['checks'])} native model/scene/control assertions pass. {len(room['checks'])} installed-museum assertions pass, including capture-camera checks. The room probe operates all five controls through the real desktop pointer, pulls the actual inherited point through XRTools with supplied controller poses, verifies its rod and out-of-plane constraint, releases with an intentionally large supplied throw speed, and checks both sliders. The model discards the throw speed as declared. {room['observations']['route_samples']} floor/capsule samples clear the comparison approach and east bypass (radius0.28m,height1.7m,masks1|4). This is not a full portal journey or physical headset assessment.

Known-case checks cover zero force, matched input and drag, independent acceleration calculations, replay equality, force cutoff, bound601 snapshots, terminal tolerance, opposite release and finite extreme-control cases across three seeds. The small-angle first zero crossing is0.522083s, compared with a quarter-period reference0.526263s. The undamped small-angle case has maximum relative energy discrepancy1.2593% over20s. Finite-step mechanics remains an approximation.

Default OFF/ON peak angles:34.38° and42.47°. Neither satisfies the terminal settling criterion within20s. Under the same force record, B with drag1.2kg/s satisfies it at5.05s; A at0.35kg/s does not within20s. These are sample-specific results, not a monotonic law for damping.

## What remains open

No physical headset, Quest benchmark or independent student. The playback and hand controls were exercised through native software poses. There is no adaptation, fuzzy inference or feedback controller. No failure rate is estimated. Rendered arrows show the external force only. The plots disclose their clipping limits; the state and measurements are not clipped.

The first core run completed its assertions but crashed during immediate teardown of the manually driven rig, before producing a receipt. Its log is preserved as first-core-engine.log. The harness now stops child handle processing and waits across physics/process boundaries before freeing the rig; subsequent runs exit cleanly. That repair does not establish the cause of an engine-level access violation. Existing UID/Jolt diagnostics and the hall's already-overwide30m layout ruling remain; final logs contain no SCRIPT ERROR or Parse Error.

## Text and handoff

The canonical hall tutorial receives a short optional study linking the complete five-file companion: model, inherited point, constrained point, full apparatus and scene wrapper. All five printed code blocks match tested source. final.md receives three paragraphs on a push ending while its consequence continues, matched input and the authored settling criterion. The primary spring lesson remains intact.

G0 and G1 are built; G2, an agent with an imperfect observation, remains next in the plan. The six original P packages remain proposals. Browser rendering of this report was not tested; native museum images and static link/package checks are separate evidence.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f1eee8;color:#222d37;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1420px;margin:auto;padding:32px}h1{font-size:clamp(36px,5vw,68px);line-height:1.05}h2{margin-top:2.1em}p,li{max-width:85ch}nav{display:flex;gap:22px;flex-wrap:wrap;font:15px/1.6 system-ui}a{color:#275f6a}img{max-width:100%;height:auto}figure{margin:24px 0}figcaption{font:14px/1.55 system-ui;color:#50606a}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.badge{background:#e0e7df;padding:18px;font:16px/1.6 system-ui}pre{background:#1d2c35;color:#f6eddc;padding:20px;overflow:auto;font:13px/1.55 Consolas}code{font-size:.86em}summary{cursor:pointer}footer{border-top:1px solid #b0bcc0}@media(max-width:800px){.pair{display:block}header,main,footer{padding:20px}}'''
nav='<nav><a href="index.html">Museum</a><a href="tutorial.html">Full tutorial</a><a href="reflection.html">Reflection</a><a href="report.html">Evidence</a><a href="pendulum-noise-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes','toc'])
def page(n,title,body):
 (O/n).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · G1 · 9 OCTOBER 2026</p><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Native Godot4.6 museum captures. Supplied desktop/XR control poses; physical headset and learner checks remain open.</footer></body></html>',encoding='utf-8')
def fig(src,text):return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(text)}" loading="lazy"></a><figcaption>{html.escape(text)}</figcaption></figure>'
body='<p>Pull one familiar point. Release a pair. Keep the starting state and input record so a changed response can be examined.</p><div class="badge">43 native core checks ·21 museum checks ·176 supported route samples · existing Forces hall</div>'
body+=fig('museum/in-motion.png','The comparison frozen at one model second for inspection. Only B receives the recorded external force; the rose arrow shows its direction and size.')
body+='<h2>Two different questions</h2><div class="pair">'+fig('museum/comparison.png','OFF/ON: the same release and drag; B receives the recorded push.')+fig('museum/same-input.png','SAME INPUT: both receive the same push; B has more drag. Its settling result is5.05s within the defined window.')+'</div>'
body+=fig('museum/off-on-record.png','The input ends at4s; the angle history continues to20s. Gold is the saved input, blue and rose the responses. Drawing limits are labelled.')
body+='<h2>A place among the existing swings</h2><div class="pair">'+fig('before/raised.png','Before: a passage between the spring row and the swings.')+fig('museum/raised.png','After: a side comparison in that passage. Earlier artifacts retain their positions.')+'</div>'
body+='<details><summary>Before/after overhead views and nearby controls</summary><div class="pair">'+fig('before/overhead.png','Before, full hall from above.')+fig('museum/overhead.png','After, full hall from above.')+'</div>'+fig('museum/controls.png','Two sliders and five buttons; the point itself sets the release.')+'</details>'
body+='<h2>Carry into the next experiment</h2>'+md('The [tutorial](tutorial.html) prints the full tested implementation. The [reflection](reflection.html) stays with the push and its continuing consequence. The [evidence report](report.html) distinguishes model checks, actual museum controls, and the headset work still open. The next proposed return puts noise into an agent’s observation, where an incorrect reading can change a decision.')
page('index.html','The same release / a recorded push',body)
page('tutorial.html','Keep the release; change the push',md((O/'tutorial.md').read_text(encoding='utf-8')))
page('reflection.html','After the push',md((O/'reflection.md').read_text(encoding='utf-8')))
page('report.html','What was built and checked',md(report)+'<p><a href="checks.json">Core assertions</a> · <a href="museum/report.json">Museum assertions</a> · <a href="changes.diff">Text/map changes</a></p>')
manifest={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources+[A/'tutorial.md',M/'map_data.json',M/'tutorial.md',M/'final.md',R/'tools/probes/pendulum_noise_test.gd',R/'tools/probes/pendulum_noise_room.gd']}
(O/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
with zipfile.ZipFile(O/'pendulum-noise-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for n in ['index.html','tutorial.html','reflection.html','report.html','REPORT.md','README.md','tutorial.md','reflection.md','hall-tutorial.md','hall-final.md','checks.json','core-engine.log','first-core-engine.log','source-manifest.json','changes.diff','placement.json']:z.write(O/n,n)
 for folder in ['code','museum']:
  for p in (O/folder).iterdir():z.write(p,p.relative_to(O))
 for n in ['raised.png','overhead.png']:z.write(O/'before'/n,'before/'+n)
 z.writestr('HOST.md','This code runs within the existing AdaResearch Godot4.6 project. ControlConsole, XR Tools, museum/player/camera and declared source paths are supplied dependencies. This ZIP is a review, not a standalone project export. Source/host paths are stated in tutorial.md.\n')
links=0
for p in O.glob('*.html'):
 for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if target.startswith(('http:','https:')):continue
  name=target.partition('#')[0];assert (p.parent/name).exists(),(p.name,target);links+=1
with zipfile.ZipFile(O/'pendulum-noise-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','reflection.html','report.html']:
  for target in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   if target.startswith(('http:','https:')) or target.endswith('.zip'):continue
   assert target.partition('#')[0] in z.namelist(),target
(O/'validation.json').write_text(json.dumps({'printed_source_parity':5,'core_checks':43,'museum_checks':21,'local_links':links,'zip_valid':True,'zip_html_targets_valid':True,'original_placements_retained':len(old),'structure_utilities_unchanged':True,'browser_render_tested':False},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'links':links,'zip_bytes':(O/'pendulum-noise-review.zip').stat().st_size}))
