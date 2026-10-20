"""Publish the measured G2 comparison; package full code and honest scope."""
from pathlib import Path
import json,re,shutil,hashlib,html,zipfile,difflib,ast
import markdown
R=Path(__file__).resolve().parents[1]; O=R/'doc/book/iterations/2026-10-09-navigator-an-imperfect-observation'
A=R/'commons/artifacts/navigator_noise'; M=R/'commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM'; run=R/'ada_run/encounter_pilot'/M.name
core=json.loads((O/'checks.json').read_text(encoding='utf-8')); native=json.loads((run/'report.json').read_text(encoding='utf-8')); printed=json.loads((O/'printed-validation.json').read_text(encoding='utf-8'))
assert core['passed'] and native['passed'] and printed['runs'][0]['exit']==0
sources=[A/'navigation_pair.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'start_point.gd',A/'NavigatorNoise.gd',A/'NavigatorNoise.tscn']
for p in sources:assert hashlib.sha256(p.read_bytes()).hexdigest()==printed['source_hashes'][p.relative_to(R).as_posix()],p
(O/'code').mkdir(exist_ok=True);(O/'museum').mkdir(exist_ok=True)
for p in sources:shutil.copy2(p,O/'code'/p.name)
for p in run.iterdir():
 if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,O/'museum'/p.name)
shutil.copy2(A/'tutorial.md',O/'tutorial.md')
for n in ['tutorial.md','final.md']:shutil.copy2(M/n,O/('hall-'+n))
before=json.loads((O/'before/map_data.json').read_bytes());after=json.loads((M/'map_data.json').read_bytes())
assert before['layers']['structure']==after['layers']['structure'] and before['layers']['utilities']==after['layers']['utilities']
old=[]
for z,row in enumerate(before['layers']['interactables']):
 for x,token in enumerate(row):
  if token.strip():assert after['layers']['interactables'][z][x]==token;old.append(token)
assert sum('navigator_noise' in c for row in after['layers']['interactables'] for c in row)==1
diff=[]
for n in ['map_data.json','tutorial.md','final.md']:
 left=(O/'before'/n).read_text(encoding='utf-8');right=(M/n).read_text(encoding='utf-8')
 if n.endswith('.json'):left=json.dumps(json.loads(left),indent=2)+'\n';right=json.dumps(json.loads(right),indent=2)+'\n'
 diff.extend(difflib.unified_diff(left.splitlines(True),right.splitlines(True),fromfile='before/'+n,tofile='after/'+n))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
(O/'saved-inputs.json').write_text(json.dumps(core['observations']['saved_inputs'],indent=2),encoding='utf-8')
(O/'seed-comparisons.json').write_text(json.dumps(core['observations']['batch'],indent=2),encoding='utf-8')
report=f'''# G2 — An imperfect observation

Built inside **SwarmIntelligence_Agent_Based_Modeling_ABM**, source cell(3,8),rotation180°. One comparison added; all{len(old)} earlier artifact tokens, wall cells and utilities retained. Only this generated museum-plan row was rederived. The existing colony remains primary. The new point is the earlier sphere class with a constrained release/display extension.

## What runs

Both points know the goal and detour. One receives accurate clearance, the other a held Gaussian error or a missing reading. Noise and missing modes are separate. STOP returns zero; HOLD repeats the last velocity command without advancing a waypoint. Same initial pose, speed, course and clock. Analytic swept disc contact and an explicit centre-boundary course test stop at the first encountered boundary. Terminal outcomes are GOAL, CONTACT, LEFT COURSE and TIMEOUT. No navmesh, learned policy, real sensor raycast or Jolt contact claim.

This isolates one question from the room's agents: what does a decision receive? It does not claim that an earlier incomplete ABM tutorial already teaches this complete navigator. The optional companion supplies its whole small policy and identifies its known geometry and authored route. Projection into two vertically displaced displays is visual placement, not another simulation condition.

## Measured examples

| Conditions, seed1847 | Accurate A | Intervened B |
|---|---|---|
| Noise σ0.5m | Goal6.65s;3.959m path | Goal6.80s;4.026m path |
| Missing fraction0.65; HOLD | Goal6.65s | Contact3.65s |
| Same missing record; STOP | Goal6.65s | Goal19.15s |

The target deadline is20s. A successful trace can differ from the reference and can be shorter. Ten consecutive seeds1847–1856 were run at the stated default noise strength and dropout/HOLD settings; [all20 paired results](seed-comparisons.json) are retained. These are fixtures, not a population failure estimate. [Seed1847 input arrays](saved-inputs.json) preserve the actual40Gaussian and40uniform draws, with engine version; a seed alone is not a cross-version archive.

## Verification

- **{len(core['checks'])} native core/scene assertions pass.** Matched-input equality, changed release, missing-versus-zero, threshold decisions, swept crossings, first contact, course exit, replay, random-stream isolation, retained history, clock and real control signals.
- **The five printed files were freshly extracted and run inside the declared host.** Only their resource paths were relocated. The same40checks pass; this is author-led executable reconstruction, not a blind ghost student.
- **Two actual mutations were rejected:** missing-as-zero and endpoint-only contact. Their altered programs and failed receipts are included. A failing mutation is expected evidence, not a passing lesson.
- **{len(native['checks'])} native museum checks pass**, including supplied XRTools pickup/motion/release, the held strength slider, desktop pointer actions on six buttons, two-point display agreement and{native['observations']['route_samples']} supported capsule samples from entry to controls. Capture-camera assertions are included in that21, not counted as learner tests.
- Native before/after overhead, raised and comparison images were inspected. No wall was hidden to make the display appear unobstructed. Neighbouring halls and the player avatar are hidden only by the camera harness.

The first core harness exited with an engine access violation during lifecycle cleanup and used an overstrict float comparison; the failed logs are retained. Waiting for initialization before manual manipulation, approximate radius comparison and stopping child processing before staged cleanup produced clean runs. The crash's engine-level cause is not established.

The first front-bay placement was rejected because a pillar hid the comparison; its probe route also crossed its console. The study moved to the open end of the hall; all earlier works stayed. A subsequent capture exposed the upper frozen point needing the same late-physics display projection as the lower point, which now both use. Readouts were raised and the console lowered for visibility. A neighbouring colony display still occupies part of the wider sightline; the close comparison is photographed from in front of it.

Existing UID and two ViewportTexture diagnostics occur in both the before and final museum logs. Accepted new-code runs have no SCRIPT ERROR or Parse Error. These focused receipts do not certify the whole hall as error-free. Physical headset reach/readability, Quest performance, independent student comprehension and a complete portal journey remain open. Browser rendering was not tested; static links and ZIP integrity were checked separately.

## The two texts

The full [tutorial](tutorial.html) teaches true state → observation → decision, using five complete files. The [reflection](reflection.html) follows what it means for an old command to continue when a reading disappears. Both are linked or added in the canonical hall texts. Original text is preserved; the full hall tutorial still contains older fragments awaiting its own reconstruction.

G0geometry,G1pendulum,G2observation are now built optional returns. The six original P packages remain proposed. The original next implementation is P1, one throw under different integration steps; it should begin with its own source and space inspection.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
(O/'README.md').write_text('''# G2 review

Open index.html. Tutorial and reflection are separate complete reading files; hall-tutorial.md and hall-final.md preserve full canonical context. code/ contains the five printed source files. reconstruction/ retains extracted and deliberately faulty variants. Native logs, before/after captures, source hashes and saved inputs are included.

Runs inside the existing AdaResearch Godot4.6 project: player/camera/lighting, XR Tools and ControlConsole are supplied. This review ZIP is not a standalone exported game. Repository paths in the source/Markdown are intentional. Tested reconstruction paths in the mutation folders refer to temporary ada_run locations; use code/ and the tutorial for installation. Physical headset and independent learner tests remain open.
''',encoding='utf-8')
tree=ast.parse((R/'tools/publish_pendulum_noise.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in n.targets))
nav='<nav><a href="index.html">Museum</a><a href="tutorial.html">Full tutorial</a><a href="reflection.html">Reflection</a><a href="report.html">Evidence</a><a href="navigator-noise-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables'])
def page(n,title,body):
 (O/n).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · G2 · 9 OCTOBER 2026</p><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Existing museum / native Godot images / physical headset and independent student checks open</footer></body></html>',encoding='utf-8')
def fig(src,caption):return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
body='<p>The obstacle stays still. What changes is the distance the point receives—and the action it takes when no distance arrives.</p><div class="badge">40 native core checks ·40 checks on reconstructed printed code ·2 rejected mutations ·21 museum checks</div>'
body+=fig('museum/missing-hold.png','Same missing record, HOLD: B continues its earlier command into contact. A completes the known detour.')
body+='<h2>One absence, two responses</h2><div class="pair">'+fig('museum/missing-hold.png','HOLD: contact after3.65 simulated seconds.')+fig('museum/missing-stop.png','STOP: reaches the goal after19.15s, inside the20s deadline.')+'</div>'
body+=fig('museum/noise-paths.png','Range error instead of dropout. Both arrive, with different paths. A difference from the reference is not automatically failure.')
body+='<h2>Inside the existing hall</h2><div class="pair">'+fig('before/overhead.png','Before: existing agent and colony works, from above.')+fig('museum/overhead.png','After: one comparison at the open end. Wall and utility cells are unchanged.')+'</div>'
body+='<details><summary>Raised views, controls and the rejected placement</summary><div class="pair">'+fig('before/raised.png','Before, raised view.')+fig('museum/raised.png','After, same raised view.')+'</div>'+fig('museum/controls.png','One physical slider and six adjacent buttons; the lower sphere sets both starting heights.')+fig('first-placement/comparison.png','Rejected front-bay placement: the pillar obscured the display. This photograph remains as evidence of the correction.')+'</details>'
body+='<h2>Read or reconstruct</h2><p><a href="tutorial.html">Full tutorial and working code</a> · <a href="reflection.html">What reaches the point</a> · <a href="report.html">Measurements and limits</a></p>'
page('index.html','An imperfect observation',body);page('tutorial.html','The obstacle, the reading, the command',md((O/'tutorial.md').read_text(encoding='utf-8')));page('reflection.html','What reaches the point',md((O/'reflection.md').read_text(encoding='utf-8')));page('report.html','What was built and checked',md(report)+'<p><a href="checks.json">Core receipt</a> · <a href="printed-validation.json">Printed reconstruction</a> · <a href="museum/report.json">Museum receipt</a> · <a href="changes.diff">Canonical changes</a></p>')
manifest={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources+[A/'tutorial.md',M/'map_data.json',M/'tutorial.md',M/'final.md',R/'tools/probes/navigator_noise_test.gd',R/'tools/probes/navigator_noise_room.gd']}
(O/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
with zipfile.ZipFile(O/'navigator-noise-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix!='.zip' and p.name!='validation.json':z.write(p,p.relative_to(O))
links=0
for p in O.glob('*.html'):
 for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if target.startswith(('http:','https:')):continue
  assert (p.parent/target.partition('#')[0]).exists(),(p,target);links+=1
with zipfile.ZipFile(O/'navigator-noise-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','reflection.html','report.html']:
  for target in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   if target.startswith(('http:','https:')) or target.endswith('.zip'):continue
   assert target.partition('#')[0] in z.namelist(),target
validation={'printed_files':5,'core_checks':len(core['checks']),'printed_checks':printed['runs'][0]['checks'],'mutants_rejected':2,'museum_checks':len(native['checks']),'route_samples':native['observations']['route_samples'],'local_links':links,'zip_valid':True,'original_placements_retained':len(old),'structure_utilities_unchanged':True,'browser_render_tested':False}
(O/'validation.json').write_text(json.dumps(validation,indent=2),encoding='utf-8')
print(json.dumps(validation));print('ZIP bytes', (O/'navigator-noise-review.zip').stat().st_size)
