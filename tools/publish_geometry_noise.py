"""Publish actual museum images and scoped tutorial/code/test evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-geometry-noise-test'
A=R/'commons/artifacts/geometry_noise'
M=R/'commons/maps/Random_Noise_Types'
run=R/'ada_run/encounter_pilot/Random_Noise_Types'
museum=json.loads((run/'report.json').read_text(encoding='utf-8'))
core=json.loads((O/'checks.json').read_text(encoding='utf-8'))
assert core['passed'] and museum['passed']
for p in [run/'engine.log',O/'core-engine.log']:
 assert not re.search(r'SCRIPT ERROR|Parse Error',p.read_text(encoding='utf-8'))
after=O/'museum';after.mkdir(exist_ok=True)
for n in ['overhead.png','raised.png','comparison.png','strong.png','eye-height.png','controls.png','bay.png','report.json','engine.log']:
 shutil.copy2(run/n,after/n)
code=O/'code';code.mkdir(exist_ok=True)
names=['surface_sample.gd','GeometryNoiseTest.gd','GeometryNoiseTest.tscn']
for n in names:shutil.copy2(A/n,code/n)
for src,dest in [(A/'tutorial.md',O/'tutorial.md'),(A/'README.md',O/'README.md'),(M/'tutorial.md',O/'hall-tutorial.md'),(M/'final.md',O/'hall-final.md')]:shutil.copy2(src,dest)
printed=re.findall(r'```(?:gdscript|ini)\n(.*?)\n```',(A/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(printed)==3
for body,n in zip(printed,names):assert body.rstrip()==(A/n).read_text(encoding='utf-8').rstrip(),n
before=json.loads((O/'before/map_data.json').read_text(encoding='utf-8'))
now=json.loads((M/'map_data.json').read_text(encoding='utf-8'))
assert before['layers']['structure']==now['layers']['structure']
assert before['layers']['utilities']==now['layers']['utilities']
def placements(d):return {(x,z):str(t).strip() for z,row in enumerate(d['layers']['interactables']) for x,t in enumerate(row) if str(t).strip()}
old_works=placements(before);new_works=placements(now)
assert all(new_works[k]==v for k,v in old_works.items())
assert len(new_works)==len(old_works)+1 and new_works[(3,11)].startswith('geometry_noise:90')
reflection=(M/'final.md').read_text(encoding='utf-8').split('<!-- @geometry_noise -->\n\n')[1].split('We can leave this hall')[0].strip()
(O/'reflection.md').write_text('# The same connections\n\n'+reflection+'\n',encoding='utf-8')
metrics=core['observations']['default']
report=f'''# The Uncertain Surface — museum prototype

9 October 2026. Installed in Random_Noise_Types, Noise sequence. One Gaussian displacement experiment; no general fuzzy-computer implementation.

## Built

Two 2m surfaces, 289 shared logical positions per copy, 512 indexed triangles each. The same pale material and matching lights. Frozen local Gaussian sample, scaled by strength; next seed, zero, reset and edge overlay. Labels expose sigma, measured RMS, maximum and centroid drift; population RMS remains separate. The experimental surfaces have no collision. Only supports and ordinary controls collide. Meshes update on parameter changes, not idle frames. In-memory receipt ring holds64 events.

Source plane, index list and saved offsets are independent. No clipping or centroid correction disguises the distribution. Indexed normals are recomputed after displacement. Fixed topology does not establish an intersection-free embedding or meaningful navigation.

## Measured

Seed1847 / strength0.18 / sigma0.045m: measured RMS {metrics['rms_m']:.8f}m; maximum {metrics['maximum_m']:.8f}m; centroid drift {metrics['centroid_drift_m']:.8f}m. Population RMS {metrics['population_rms_m']:.8f}m is a reference, not the measured sample.

{len(core['checks'])} native core/scene assertions pass. {len(museum['checks'])} museum assertions pass, including capture-camera checks. The latter operates four buttons through the existing desktop pointer rig, supplies real XRTools pickup/movement/release poses to the slider, and checks {museum['observations']['route_samples']} floor/capsule samples on the approach and eastern bypass. Capsule radius0.28m/height1.7m, physics masks1|4. Rebuild timing is recorded in the receipts; it is not an FPS or Quest benchmark.

## Placement and review

The comparison occupies cell[3,11], rotated90degrees toward the west wall. All five earlier authored artifacts retain their cells and tokens. Structure, utilities and sequence order unchanged by this addition. Only this hall's generated plan row was rederived.

The first position overlapped the temporal-weather apparatus's foreground. Native inspection revealed its controller extends5.65m before its central token. The final bay separates the controls, improves the readout and keeps the eastern route. The existing weather sign still appears at the edge of the view; neighbouring works were not removed for the close photographs. Overhead images hide neighbouring halls/player for framing, not this hall's walls.

## Evidence limits and diagnostics

No physical headset, Quest performance, independent student or adaptation experiment tested. Existing authored entry is blocked and the museum uses its prior safe-spawn fallback; this predates the new artifact and remains unresolved. Existing UID/Jolt warnings remain. The final logs contain no SCRIPT ERROR or Parse Error.

The first core probe compared a packed GPU normal with an excessively tight zero-component tolerance; a0.0001 vector-distance check accommodates mesh normal packing. No normal algorithm change was needed. First interaction probe used the wrong handle child path; corrected to HandleOrigin/InteractableHandle. The first two placements and failed probe logs are retained as diagnostics. All final assertions pass.

## Text and continuation

The map tutorial gains a short optional study with a link to the complete three-file companion; its earlier lesson is retained. final.md gains a separate three-paragraph reflection on what survives displacement. The entire opening has not been rewritten or assessed as a complete learner chapter.

The uncertainty plan now records G0 and twelve possible injection sites. Pendulum(G1), navigator(G2), fuzzy inference and deliberate failure-threshold tests remain proposals. Next geometric experiment must name a criterion before calling a result a glitch.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
diff=''
for n in ['map_data.json','tutorial.md','final.md']:
 diff+=''.join(difflib.unified_diff((O/'before'/n).read_text(encoding='utf-8').splitlines(True),(M/n).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+n,tofile='after/'+n))
(O/'changes.diff').write_text(diff,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f3efe6;color:#202934;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1400px;margin:auto;padding:34px}h1{font-size:clamp(38px,5vw,70px);line-height:1.06}h2{margin-top:2em}p,li{max-width:84ch}nav{display:flex;gap:22px;flex-wrap:wrap;font:15px/1.6 system-ui}a{color:#365e79}img{max-width:100%;height:auto}figure{margin:24px 0}figcaption{font:14px/1.5 system-ui;color:#4d5964;padding:8px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.badge{background:#dce6df;padding:16px;font:16px/1.6 system-ui}pre{background:#1f2933;color:#f4edde;padding:20px;overflow:auto;font:13px/1.6 Consolas,monospace}code{font-size:.86em}table{border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid #bbc3ca;text-align:left}summary{cursor:pointer;font:17px/1.6 system-ui}footer{border-top:1px solid #aab8be}@media(max-width:800px){.pair{display:block}header,main,footer{padding:20px}}'''
nav='<nav><a href="index.html">Museum</a><a href="tutorial.html">Complete tutorial</a><a href="reflection.html">Reflection</a><a href="report.html">Evidence and limits</a><a href="geometry-noise-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes','toc'])
def page(n,title,body):
 (O/n).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · 9 OCTOBER 2026</p><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Native Godot 4.6 captures. Desktop/supplied XR poses; physical headset and learner assessment remain open.</footer></body></html>',encoding='utf-8')
def fig(src,caption):return f'<figure><a href="{src}"><img src="{src}" loading="lazy" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'
body='<p>Keep the connections. Move the positions. Change one saved Gaussian sample’s strength and compare it with the original.</p><div class="badge">28 core/scene checks · 16 museum checks · native room images · existing Noise opening</div>'
body+=fig('museum/comparison.png','The installed comparison, seen from a slightly raised view inside the hall. Seed1847; strength0.18. The adjacent temporal-weather work remains visible.')
body+='<h2>One sample, another strength</h2><div class="pair">'+fig('museum/eye-height.png','Visitor-height view: the two surfaces and reachable controls.')+fig('museum/strong.png','Strength0.70. Same saved offsets and index list; greater amplitude, not a new draw.')+'</div>'
body+='<h2>The hall from above</h2><div class="pair">'+fig('before/overhead.png','Before: sampling displays lead into the temporal walls.')+fig('museum/overhead.png','After: the surface comparison occupies a west-side bay; existing works and architecture remain.')+'</div>'
body+='<details><summary>Raised room views and controls</summary><div class="pair">'+fig('before/raised.png','Before: raised overview.')+fig('museum/raised.png','After: raised overview.')+'</div>'+fig('museum/controls.png','Four nearby actions and one held slider; no walk to a distant control panel.')+'</details>'
body+='<h2>What the numbers mean</h2>'+md('Sigma is **4.5cm per axis**. The measured RMS is **7.76cm**, the largest displacement **16.40cm**, and centroid drift **1.49mm**. Population RMS is a separate theoretical reference. A changed shape is not automatically a failed one.\n\nThe [tutorial](tutorial.html) prints the full three-file implementation. The [reflection](reflection.html) asks which property we expected to survive. The [report](report.html) records the failed placements, test scopes and remaining limitations.')
page('index.html','The Uncertain Surface',body)
page('tutorial.html','Keep the connections; move the positions',md((O/'tutorial.md').read_text(encoding='utf-8')))
page('reflection.html','The same connections',md(reflection))
page('report.html','What was built and checked',md(report)+'<p><a href="checks.json">Core assertions</a> · <a href="museum/report.json">Museum assertions</a> · <a href="changes.diff">Scoped text/map changes</a></p>')
manifest={}
for p in [*(A/n for n in names),A/'tutorial.md',M/'map_data.json',M/'tutorial.md',M/'final.md',R/'tools/probes/geometry_noise_test.gd',R/'tools/probes/geometry_noise_room.gd']:
 manifest[p.relative_to(R).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(O/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
with zipfile.ZipFile(O/'geometry-noise-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for n in ['index.html','tutorial.html','reflection.html','report.html','REPORT.md','README.md','tutorial.md','reflection.md','hall-tutorial.md','hall-final.md','checks.json','source-manifest.json','changes.diff','placement.json']:
  z.write(O/n,n)
 for p in code.iterdir():z.write(p,p.relative_to(O))
 for p in after.iterdir():z.write(p,p.relative_to(O))
 for n in ['overhead.png','raised.png']:z.write(O/'before'/n,'before/'+n)
 z.writestr('HOST.md','Run code in the existing AdaResearch Godot4.6 museum project with its ControlConsole and XRTools. This review is not a standalone project export. HTML report navigation and captures are included. Full hall Markdown retains repository-relative links.\n')
links=0
for p in O.glob('*.html'):
 for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if target.startswith(('http:','https:')):continue
  name=target.partition('#')[0]
  assert (p.parent/name).exists(),(p.name,target)
  links+=1
with zipfile.ZipFile(O/'geometry-noise-review.zip') as z:assert z.testzip() is None
(O/'validation.json').write_text(json.dumps({'printed_source_parity':3,'core_assertions':len(core['checks']),'museum_assertions':len(museum['checks']),'local_links':links,'zip_valid':True,'earlier_artifacts_retained':len(old_works),'structure_utilities_unchanged':True},indent=2),encoding='utf-8')
print(json.dumps({'report':str(O/'index.html'),'links':links,'zip_bytes':(O/'geometry-noise-review.zip').stat().st_size}))
