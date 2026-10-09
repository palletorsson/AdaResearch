"""Native museum views and two complete texts for the second CA hall."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-state-that-lingers'
M=R/'commons/maps/CA_ElementaryRules'
code=json.loads((O/'checks.json').read_text(encoding='utf-8'))
room=json.loads((O/'museum/report.json').read_text(encoding='utf-8'))
assert code['passed'] and room['passed']
for filename,capture in [('lingering-cell.png','fading.png'),('available-address.png','empty.png')]:
 (O/'before/images').mkdir(exist_ok=True)
 if not (O/'before/images'/filename).exists():shutil.copy2(M/'images'/filename,O/'before/images'/filename)
 shutil.copy2(O/'museum'/capture,M/'images'/filename)
(O/'images').mkdir(exist_ok=True)
for p in (M/'images').glob('*.png'):shutil.copy2(p,O/'images'/p.name)
for n in ['tutorial.md','final.md']:shutil.copy2(M/n,O/n)
n=len(code['checks']);q=len(room['checks']);ms=room['observations']['single_step_ms']
samples=sum(v['samples'] for v in room['observations']['routes'].values())
report=f'''# A state that lingers

The second Cellular Automata hall now teaches a precise difference: an address can be occupied without contributing to its neighbours' active count. The familiar point carries the step control; one gold frame keeps the observation at the same cell.

## The progression

**A row with neighbours → a volume with three states → a history laid out in space.**

The previous lesson supplied old/next arrays, indexed state and a rule. Here a Boolean becomes empty/active/fading, an address gains three coordinates, and the neighbourhood reaches all 26 surrounding positions. We count only active cells. A fading cell must empty before a later generation can consider birth. CA_GameOfLife is next; its lesson has not been rewritten in this pass.

## Changes in this hall

- **Tutorial:** a complete 7 × 7 × 7 construction, its unchanged PointBody file, the 81-case transition contract, synchronous updates and empty boundaries. A twelve-cell seed makes the beginning inspectable. The independent task is to predict two adjacent cells through two updates.
- **Museum:** a black pickable sphere beside the console carries STEP wherever the visitor stands. The enlarged neighbourhood now reports its generation, central state and active-neighbour count. Both use the existing solver. Its rule, seed and 50 × 50 × 50 calculation are unchanged.
- **Space:** the far gallery is level, replacing its disconnected pits and raised blocks. The opening under the volume remains. Both authored artifacts remain. Entry and exit use the central thresholds; the generic extra gate is disabled for this hall.
- **Reflection:** the existing argument stays with presence, participation, fading and the drawing's omissions. Two implementation blocks become prose. The held point and level far gallery are described. Full code belongs in the tutorial.
- **Plan:** only CA_ElementaryRules changes. The review decision remains draft; the other lessons keep their current decisions and content.

## Two constructions, one rule

The learner study and the installed work are deliberately distinguished. The small study uses twelve stated cells and draws every occupied cell. The museum uses seed 23090 in a larger volume and hides fully enclosed cells when rendering. They need not have the same shape to implement the same transition.

In the museum, address (26, 22, 24) begins active with eleven active neighbours. It becomes fading with seven, then empty with five. The middle count would allow birth at an empty address, but the current state is fading. The first branch matters.

## Evidence

**{n} construction checks and {q} native museum checks pass in Godot 4.6.** Construction checks extract the exact two code blocks printed in tutorial.md and compare them with the maintained files. The carried PointBody is byte-identical to the previous hall's version. The table is checked for all three states and all 27 possible counts. Eight deterministic mixed-state seeds, each advanced eight times, agree with the installed solver. Reverse traversal agrees; deliberately counting fading cells and allowing premature rebirth are rejected. The independent two-cell exercise, state-preserving draw, rendered states and actual XRTools pickup/action/release with supplied poses also pass.

The museum check runs the actual 50-cubed installation. It checks the shared trigger, caption, replay, VIEW and release. Four routes include {samples} samples of level floor and clearance for a 0.56 m wide, 1.7 m tall capsule on collision layer 1. Authored entry and exit approaches are valid. Camera-retention checks are included in the museum count; these are not {q} separate teaching assertions.

The first native learner screenshot put its small construction against the dense installed volume. That made the two hard to distinguish. The final capture mounts the same printed code in the cleared side of the far gallery, with a quieter background. It is a temporary test mounting, not an added permanent artifact. A small backing plate makes the installed hand instruction clearer. Earlier captures are retained in diagnostics.

## Remaining limits

The installed full-volume step measured **{ms:.1f} ms** in this desktop run. The existing solver is still too expensive for a smooth single VR frame; this pass does not solve that performance problem. Its observation clock starts held. The small learner study should not be mistaken for proof of the large artifact's performance.

Supplied controller poses and sampled routes are not a physical headset, Quest, complete portal-transfer or human-learning test. No independent ghost student has taken this lesson yet. Existing project warnings remain in the logs; the successful runs have no SCRIPT ERROR or Parse Error.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Complete tutorial](tutorial.html) · [Complete reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact volume script](printed/volume.gd) · [carried point](printed/point_body.gd)
- [Construction checks](checks.json) · [Museum checks and route samples](museum/report.json)
- [Construction log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-states-review.zip)
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_ElementaryRules: carry PointBody as STEP; one fixed gold address. bool row→3-state volume;26 active-only neighbours;old→next;empty shell. Full7³ learner seed12;existing50³seed23090 unchanged. Active11→fading7→empty5. Tutorial fullcode;final prose. Far gallerylevel;centralpit+2worksretained;thresholdportals. {n}construction+{q}museum checks;{samples}route samples;{ms:.1f}ms fullstep unresolved. Noheadset/ghost test. NextCA_GameOfLife spatialhistory.\n',encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#222b2b;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1480px;margin:auto;padding:36px}header{padding-top:65px}h1{font-size:clamp(40px,6vw,76px);line-height:1.06;max-width:920px}h2{margin-top:2em;line-height:1.2}nav,.eyebrow,figcaption,.badge{font:14px/1.6 system-ui,sans-serif}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#345e62;text-underline-offset:3px}.eyebrow{letter-spacing:.12em;text-transform:uppercase}.lead{font-size:26px;max-width:850px}p,li{max-width:80ch}.badge{display:inline-block;padding:8px 14px;background:#e5d7dd}figure{margin:20px 0}img{display:block;width:100%;height:auto;border:1px solid #c9c8c1}figcaption{padding:8px 0;color:#505b5a}.pair,.parallel{display:grid;grid-template-columns:1fr 1fr;gap:26px}.parallel article{min-width:0;background:#fffcf7;padding:26px;border-top:4px solid #b06c94}pre{background:#1c2b2c;color:#f5f1e9;padding:18px;overflow:auto;font:13px/1.55 Consolas,monospace;tab-size:4}code{font-size:.82em}pre code{font-size:inherit}table{border-collapse:collapse;display:block;overflow:auto}th,td{padding:8px;border-bottom:1px solid #bbc8c4;text-align:left}footer{border-top:1px solid #c9c8c1}.triplet{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}@media(max-width:850px){.pair,.parallel,.triplet{display:block}header,main,footer{padding:22px}.parallel article{padding:16px}}@media print{nav{display:none}body{font-size:11pt}pre{white-space:pre-wrap;color:#111;background:white;font-size:8pt}.parallel{display:block}}'''
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">From above</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-states-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Native Godot captures. One hall; complete tutorial and separate reflection. No physical headset or independent learner test.</footer></body></html>',encoding='utf-8')
body='<p class="lead">It is still visible. It no longer counts as active. Before it can begin again, it must become empty.</p>'+f'<span class="badge">{n} construction + {q} museum checks passed</span>'
body+=photo('museum/entry.png','Inside the actual hall: the existing volume, enlarged neighbourhood and new held step control.')
body+='<section id="layout"><h2>Make room to follow the change</h2><div class="pair">'+photo('before/museum/overhead.png','Before: the central volume and neighbourhood are clear, but the far gallery is broken into pits and raised blocks.')+photo('museum/overhead.png','After: a continuous floor around the retained central opening. Entrance is at the top, exit at the bottom. Both authored works remain.')+'</div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, from above and to one side. No walls have been hidden.')+photo('museum/raised-oblique.png','After, with the same camera. The far gallery becomes usable space, and the central opening stays part of the encounter.')+'</div></section>'
body+='<h2>Follow one address through three generations</h2><div class="triplet">'+photo('museum/neighbours.png','Generation 0: active; eleven active neighbours.')+photo('museum/fading.png','Generation 1: fading; seven active neighbours. Visibility does not imply participation.')+photo('museum/empty.png','Generation 2: empty; five active neighbours. The gold address remains.')+'</div>'
body+='<h2>Build a smaller version in the museum</h2><div class="pair">'+photo('museum/printed-study.png','The exact printed construction, temporarily mounted in the cleared gallery. Twelve stated cells; no hidden scene meshes.')+photo('museum/printed-fading.png','The same construction after one update. This small seed is distinct from the museum’s larger seeded volume.')+'</div>'
body+=md(report.split('\n',2)[2]);page('index.html','A state that lingers',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · A state that lingers',t);page('final.html','Reflection · A cell with a past',f)
page('parallel.html','One hall, two readings','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
for name in ['structure_study.gd','neighbour_room.gd']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(R/'algorithms/cellularautomata/cellular_automata_3d'/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
with zipfile.ZipFile(O/'ca-states-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['tutorial.md','final.md','REPORT.md','SUMMARY.md','checks.json','museum/report.json','printed/volume.gd','printed/point_body.gd','images/lingering-cell.png','images/available-address.png']:
  z.write(O/name,name)
 z.writestr('README.md','CA_ElementaryRules only. Read tutorial.md and final.md as separate tracks. The museum supplies the Day Zero host. printed/ contains the complete learner scripts. Evidence is scoped native testing, not independent learner or headset certification.\n')
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');targetpath=p.parent/target if target else p
  if not targetpath.exists():missing.append(str(p.name)+': '+ref)
  elif anchor and targetpath.suffix=='.html':assert f'id="{anchor}"' in targetpath.read_text(encoding='utf-8')
assert not missing,missing
assert (O/'before/CellularAutomata3D_Flexible.gd').read_bytes()==(R/'algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd').read_bytes()
with zipfile.ZipFile(O/'ca-states-review.zip') as z:assert z.testzip() is None
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'production_solver_unchanged':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True}))
