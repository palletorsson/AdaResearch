"""Publish complete texts, native room comparisons and scoped test receipts."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-history-three-bodies'
M=R/'commons/maps/CA_GameOfLife'
code=json.loads((O/'checks.json').read_text(encoding='utf-8'))
room=json.loads((O/'museum/report.json').read_text(encoding='utf-8'))
assert code['passed'] and room['passed']
for filename,capture in [('walking-history.png','walking-history.png'),('history-learner.png','printed-study.png')]:
 (O/'before/images').mkdir(exist_ok=True)
 if (M/'images'/filename).exists() and not (O/'before/images'/filename).exists():shutil.copy2(M/'images'/filename,O/'before/images'/filename)
 (M/'images').mkdir(exist_ok=True)
 shutil.copy2(O/'museum'/capture,M/'images'/filename)
(O/'images').mkdir(exist_ok=True)
for name in ['walking-history.png','history-learner.png']:shutil.copy2(M/'images'/name,O/'images'/name)
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
report=f'''# A history, three bodies

One saved generation can be an image, ornament or support. This hall makes the difference walkable. The tutorial reconstructs the operation at hand scale; the reflection follows what changes when we ask a pattern to carry a body.

## What this hall adds

The CA opening taught an old-to-next row update. The second hall expanded state and neighbourhood into a three-state volume. **Here we return to Rule 30 to keep its history.** Site and generation become separate indices. A recorded state is independent of the current row. Reading backwards does not reverse the calculation.

The historical map ID remains CA_GameOfLife. Its primary exhibit is Rule 30, not Conway's Life. The next hall, CA_BeyondBinary, supplies that two-dimensional present. The rear columns and other secondary works remain part of the museum's wider field.

## Changes per track

- **Tutorial:** full `history.gd` and unchanged `point_body.gd`, inside the existing museum host. Copy independent snapshots; map the same record to horizontal collision tiles and a visual upright screen. Held point reads a row; trigger appends. Predict a two-site seed, then reverse only the wall mapping.
- **Reflection:** preserve the argument about returning, gaps and support. Replace two implementation excerpts with prose. Clarify the return from the previous volume to Rule 30, and the difference between walking selection and the manual ROW button, which pauses RUN.
- **Hall:** retain all six authored works and the front basin. Level the rear gallery, remove its long inner partition and raised strips, widen the east passage, and move the orb and columns clear of the lab. Reserve incidental sculpture out of the circulation. Put entry/exit on the thresholds, with the generic extra gate disabled for this map.
- **Plan:** update only this lesson's summary, dependencies, transfer task and evidence. Its review decision remains draft.

## Two scales, one operation

The installed work has three receivers: desk record, basin tiles and standing lattice. A visitor's body selects a generation. The learner study has two receivers and the carried PointBody selects a generation. It prints all its geometry and interaction code, while the museum supplies the previously established camera, light, player and XR Tools. It is not a standalone blank-project lesson or a miniature walkable floor.

The exact printed study is temporarily mounted in the museum for its screenshot. It is not another permanently installed artifact. The first capture placed it against the basin, which confused the two patterns; the final view uses a plain rear wall. The complete files are included beside the text.

## Evidence and limits

**{n} learner checks and {q} museum checks pass in Godot 4.6.** The learner checks extract the exact printed blocks. They cover all eight Rule 30 cases, eight seeded histories through 24 generations against the installed solver, independent snapshots, deliberate aliasing failure, the two-site and flipped-view exercises, all 360 visibility/support slots, native collision rays, and actual XRTools pickup/action/release with supplied poses.

The museum checks cover all three walking witnesses, preserved rows and support, unrecorded/out-of-bay selection, both player group conventions, RUN versus ROW, replay/seed/capacity, surface and lower-floor rays. Five routes include **{samples} samples** of level floor and clearance for a 0.56 m wide, 1.7 m tall capsule on collision layer 1. Entry and exit approaches pass. Camera-retention checks are included in the museum count.

The first route ended inside the sloping desk; its corrected endpoint stops at the approach. The first lower-floor ray hit an end ramp; the corrected ray samples the basin interior. Earlier diagnostic receipts are retained. Successful runs contain no SCRIPT ERROR or Parse Error. Existing project warnings remain.

These checks do not establish tracked headset comfort, Quest performance, all-layer dynamic traversal, complete portal transfer or a human student's understanding. The retained rear works have not each received a new interaction audit. The lab sign faces its interior and reads backwards through the rear glass. The current lighting is bright, especially in overhead views; it has not been retuned for these captures. The installed Rule 30 solver and history study are unchanged from the baseline.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Whole tutorial](tutorial.html) · [Whole reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact history code](printed/history.gd) · [carried PointBody](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner engine log](engine.log) · [Museum engine log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-history-review.zip)
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_GameOfLife: return Rule30 after3statevolume. Keep24chronological boolrow snapshots;site vs generation;two learner receivers(surface+collision/verticalvisual). PointBody localZ reads;trigger appends;latest separate from selected;replayclear. Installed3views/bodyreader unchanged. Sixworkskept;rearleveled;eastpassageopen;orb+columnsclearoflab;thresholdportals. Fulltutorial+finalprose. {n}exactcode+{q}museumchecks/{samples}routesamples;noheadset/ghost/portaltransfer. NextCA_BeyondBinary:2Dpresent B3/S23.\n',encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f3f0e9;color:#223334;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1440px;margin:auto;padding:36px}header{padding-top:62px}h1{font-size:clamp(40px,6vw,76px);line-height:1.05;max-width:980px}h2{margin-top:2em;line-height:1.2}nav,figcaption,.eyebrow,.badge,.switch label{font:14px/1.55 system-ui,sans-serif}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#37676a;text-underline-offset:3px}.eyebrow{text-transform:uppercase;letter-spacing:.12em}.lead{font-size:26px;max-width:830px}p,li{max-width:80ch}.badge{display:inline-block;background:#dce9e2;padding:8px 14px}figure{margin:24px 0}img{width:100%;height:auto;display:block;border:1px solid #c7cbc5}figcaption{padding:9px 0;color:#526260}.pair,.parallel{display:grid;grid-template-columns:1fr 1fr;gap:24px}.parallel article{min-width:0;padding:24px;background:#fffdf6;border-top:4px solid #b2cec4}.parallel article:last-child{border-color:#c9adba}.parallel h1{font-size:34px}pre{background:#1d2b2e;color:#f8f1df;padding:18px;overflow:auto;font:13px/1.55 Consolas,monospace;tab-size:4}code{font-size:.83em}pre code{font-size:inherit}table{border-collapse:collapse}th,td{padding:8px;border-bottom:1px solid #becac4;text-align:left}.switch input{margin:0 6px 0 18px}.switch label{cursor:pointer}.switch .after{display:none}#after:checked~.after{display:block}#after:checked~.before{display:none}.switch figure img{max-height:1050px;object-fit:contain;background:#d8dbd6}footer{border-top:1px solid #c5cec8}@media(max-width:850px){.pair,.parallel{display:block}header,main,footer{padding:22px}.parallel article{padding:16px}}@media print{nav,.switch input,.switch label{display:none}body{font-size:11pt}pre{white-space:pre-wrap;background:white;color:#111;font-size:8pt}.parallel{display:block}}'''
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-history-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Native museum evidence. One hall, two complete texts. Next: CA_BeyondBinary.</footer></body></html>',encoding='utf-8')
body='<p class="lead">Keep the past. Walk back through it. The process has not run backwards.</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/walking-history.png','Inside the museum: gold selects generation five in the tiles, lattice and desk. The later rows remain.')
body+='''<section id="layout"><h2>A route around the record</h2><p>The entrance is at the top. The basin remains; the lower half opens around the laboratory and its east door.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'''+photo('before/museum/overhead.png','Before: long rear partition, raised strips and pits. Orb overlaps the laboratory footprint.')+'</div><div class="after">'+photo('museum/overhead.png','After: level rear gallery, east circulation and separated orb/columns. All six authored works remain.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, from above and to one side.')+photo('museum/raised-oblique.png','After, from the identical camera. No walls or roofs removed for this view.')+'</div></section>'
body+='<h2>Read, then walk</h2><div class="pair">'+photo('museum/entry.png','The installed desk is unchanged: a finite record, six controls and one selected row.')+photo('museum/rear-gallery.png','The secondary works now stand clear of the lab. Its sign faces the interior.')+'</div>'
body+='<h2>The exact code, running in the museum</h2>'+photo('museum/printed-study.png','Temporary mounting of the complete learner files. PointBody reads one saved generation across two arrangements.')
body+=md(report.split('\n',2)[2]);page('index.html','A history, three bodies',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · Keep a generation',t);page('final.html','Reflection · A history you can inhabit',f)
page('parallel.html','One history, two readings','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
with zipfile.ZipFile(O/'ca-history-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/history.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/walking-history.png','images/history-learner.png']:
  if name.endswith('.html'):
   z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-history-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-history-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 z.writestr('README.md','CA_GameOfLife only. Open index.html or read tutorial.md and final.md separately. Existing Day Zero museum host required; printed/ includes both complete learner files. Exact code and scoped native tests pass; no physical headset or independent student acceptance.\n')
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8')
assert not missing,missing
for name in ['ca_bridge.gd','history_study.gd']:assert (O/'before'/name).read_bytes()==(R/'algorithms/cellularautomata/ca_bridge'/name).read_bytes()
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
for name,block in zip(['history.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-history-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target in z.namelist(),(name,ref)
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_solver_and_study_unchanged':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True}))
