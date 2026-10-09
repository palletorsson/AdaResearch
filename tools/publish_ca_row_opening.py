"""Portable opening-hall review: native pictures, complete texts and test receipts."""
from pathlib import Path
import difflib,hashlib,html,json,os,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-row-with-neighbours'
M=R/'commons/maps/CA_Introduction'
E=lambda s:html.escape(str(s),quote=True)
style='''*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#242b2a;font:19px/1.6 Georgia,serif}header,main,footer{max-width:1320px;margin:auto;padding:35px}header{padding-top:70px}h1{font-size:clamp(38px,6vw,76px);line-height:1.02;max-width:920px}h2{margin-top:2em;line-height:1.2}h3{line-height:1.25}nav,.eyebrow,figcaption,.badge,button{font:14px/1.6 system-ui,sans-serif}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#246c4f;text-underline-offset:3px}.eyebrow{letter-spacing:.15em;text-transform:uppercase}p,li{max-width:76ch}.lead{font-size:25px;max-width:900px}.badge{display:inline-block;background:#dceada;padding:8px 13px;border-radius:3px}figure{margin:20px 0}img{display:block;width:100%;height:auto;border:1px solid #b9c1b6}figcaption{padding:10px 0;color:#4d5651}.pair,.parallel{display:grid;grid-template-columns:1fr 1fr;gap:30px}.parallel article{min-width:0;padding:25px;background:#fffcf6;border-top:4px solid #568c68}pre{background:#172821;color:#eef4e8;padding:20px;overflow:auto;font:13px/1.55 Consolas,monospace;tab-size:4}code{font-size:.82em}pre code{font-size:inherit}table{border-collapse:collapse;display:block;overflow:auto}td,th{border-bottom:1px solid #c4cbbf;padding:9px;text-align:left}blockquote{border-left:4px solid #568c68;padding-left:20px}details{margin:25px 0}footer{border-top:1px solid #ccd2c6}@media(max-width:850px){.pair,.parallel{display:block}header,main,footer{padding:23px}.parallel article{padding:14px}}@media print{nav{display:none}body{font-size:11pt}pre{white-space:pre-wrap;font-size:8pt;background:#fff;color:#111}.parallel{display:block}}'''
nav='<nav><a href="index.html">Museum report</a><a href="index.html#layout">Hall from above</a><a href="parallel.html">Tutorial left · reflection right</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="ca-opening-review.zip">Review ZIP</a><a href="../../../blog/2026-10-08-what-a-rule-keeps/index.html">Fractals blog</a></nav>'
def md(raw):
 return markdown.markdown(raw,extensions=['fenced_code','tables','footnotes'])
def chapter(name):
 raw=(M/name).read_text(encoding='utf-8')
 def image_path(m):
  target=M/m.group(2)
  return f'![{m.group(1)}]({Path(os.path.relpath(target,O)).as_posix()})'
 raw=re.sub(r'!\[([^\]]*)\]\((images/[^)]+)\)',image_path,raw)
 return md(raw)
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{E(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{E(title)}</h1>{nav}</header><main>{body}</main><footer>Opening hall only. Native Godot captures; no physical headset or human learner test.</footer></body></html>',encoding='utf-8')
def photo(name,caption):
 return f'<figure><img src="museum/{name}.png" alt="{E(caption)}"><figcaption>{E(caption)}</figcaption></figure>'

checks=json.loads((O/'checks.json').read_text(encoding='utf-8'))
museum=json.loads((O/'museum/report.json').read_text(encoding='utf-8'))
assert checks['passed'] and museum['passed']
n=len(checks['checks']); m=len(museum['checks'])
report=f'''# A row with neighbours

The first Cellular Automata hall now has a complete reconstruction and a hand reader on the existing explorer. The familiar point selects an address; a trigger advances the same installed machine. The board and overhead ring share its retained history.

## What changed

- **Tutorial:** one binary row, three ordered inputs, eight readable answers, a separate next row, wrapped boundaries and copied history. Both complete scripts are printed. Predict two adjacent seeds, reverse traversal and inspect a boundary seed.
- **Museum:** a black PointBody and a short selection rail beside the existing controls. Move sideways to inspect; trigger to STEP; release to park. The explorer's rule engine, seed controls and overhead receiver remain the owners of its state. This addition is limited to its existing `room:ring` configuration.
- **Reflection:** keeps the rug, network and question of what a neighbourhood permits. Three implementation blocks become prose; the new reader appears in the opening encounter.
- **Plan:** only CA_Introduction's row is updated. Its existing decision status is retained. No hall reordered; this is not a rewrite of all eight lessons.

## Where the lineage goes

Trace retained positions. Grid gave them addresses. Here an address holds a state, and its neighbours help choose the next one. The student's contribution is an update rule and a testable account of what stays the same when the traversal changes. The point is a reader, not a seed painter.

CA comes before Fractals in the existing spine. Returning to it after the Fractals work is our editing order; the lesson does not require the future Fractals chapter. The point construction, arrays and indexed operations come from earlier halls.

Next is **CA_ElementaryRules**, whose current central artifact uses a three-dimensional neighbourhood and empty, active and fading states. Its existing title is not a reason to repeat the eight-answer row lesson. We will follow what actually changes in the artifact.

## Evidence and limits

**{n} construction checks and {m} museum checks pass in Godot 4.6.** The construction test extracts the exact two printed scripts. It compares forty generations and retained histories with the installed explorer under Rules 90 and 30, checks wrap and independent copies, runs a reverse-traversal variant, and rejects an in-place mutation. Actual XRTools pickup/release uses supplied controller poses in a rotated frame. Native captures show the installed reader and the separately mounted learner construction.

The first rendering assertion incorrectly used headless MultiMesh colour readback. It returned black. The final run uses the real renderer and a colour-storage tolerance of roughly one 8-bit step. The first museum harness also referred to XRTools before its settings autoload existed; that harness reference was removed. A direct one-off desktop pose assignment did not move the reader reliably in the museum test. The final museum run uses the actual XRTools pickup driver with sustained controller poses. Desktop hooks pass the construction test; full desktop interaction in the hall remains a separate usability check. Earlier attempts are retained, not counted as passes. No learner-code repair was required.

Existing project warnings (including an unresolved UID and Jolt's ignored custom solver bias) remain in the logs. The successful runs contain no SCRIPT ERROR or Parse Error. This is evidence for the stated calculations and supplied interactions, not a physical-headset, Quest-performance or human-learning result. The independent exercises have teacher-authored tests; no fresh ghost student has yet taken this CA lesson.

## Files to review

- [Tutorial](tutorial.html) · [Reflection](final.html) · [Facing texts](parallel.html)
- [Exact printed code](printed/row.gd) · [carried point](printed/point_body.gd)
- [Construction assertions](checks.json) · [museum assertions](museum/report.json)
- [Construction log](engine.log) · [museum log](museum/engine.log)
- [Before tutorial](before/tutorial.md) · [before reflection](before/final.md)
- [Review ZIP](ca-opening-review.zip)
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
(O/'SUMMARY.md').write_text('CA_Introduction: PointBody reads row; trigger→existing step. Explicit 8-answer Rule90; old→next; wrap32; copyhistory24. Two complete printed scripts. Check: two seeds, reversed traversal, boundary seed. Rug/network remain reflective encounters. No reorder. Next: 3D empty/active/fading in CA_ElementaryRules. '+f'Native {n}+{m} scoped checks; no fresh ghost/headset test.\n',encoding='utf-8')
body='<p class="lead">The point returns as a reader. A row gets a next state. Its past becomes something we can walk underneath.</p>'+f'<span class="badge">{n} construction + {m} museum checks passed</span>'
body+=photo('after','Installed explorer, Rule 90 after sixteen updates. The new black point selects a cell; the existing table, controls and overhead history remain.')
if (O/'layout/section.html').exists():
 body+=(O/'layout/section.html').read_text(encoding='utf-8')
body+='<section id="reading">'+md(report.split('\n',2)[2])+'</section>'
body+='<h2>One addition, the same state</h2><div class="pair">'+photo('before','Before the addition: same camera and Rule 90 generation, with the new reader hidden for comparison.')+photo('after','After: hand reader and selection rail in front of the existing controls.')+'</div>'
body+='<h2>The boundary becomes a ring</h2>'+photo('ring','Inside the actual CA_Introduction hall. The overhead bands receive stored rows from the same explorer; their height records time.')
body+='<h2>Change the answers, keep the beginning</h2><div class="pair">'+photo('after','Rule 90, one central seed, sixteen updates.')+photo('rule-30','Rule 30, the same central seed and sixteen updates. Only the eight answers change.')+'</div>'
body+='<h2>The exact printed reconstruction</h2>'+photo('printed-study','Temporary mounting of the exact printed learner script in this museum hall. It constructs its own boxes, point, marks and readout; the installed explorer is hidden only for this capture.')
page('index.html','A row with neighbours',body)
page('tutorial.html','Tutorial · A row with neighbours',chapter('tutorial.md'))
page('final.html','Reflection · What will the next row do?',chapter('final.md'))
page('parallel.html','One hall, two kinds of reading','<div class="parallel"><article>'+chapter('tutorial.md')+'</article><article>'+chapter('final.md')+'</article></div>')
for name in ['tutorial.md','final.md']: shutil.copy2(M/name,O/name)
diff=[]
for name in ['tutorial.md','final.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'text-changes.diff').write_text(''.join(diff),encoding='utf-8')
with zipfile.ZipFile(O/'ca-opening-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['tutorial.md','final.md','REPORT.md','SUMMARY.md','checks.json','museum/report.json','printed/row.gd','printed/point_body.gd']:
  z.write(O/name,name)
 z.write(M/'images/neighbour-ring.png','images/neighbour-ring.png')
 z.writestr('README.md','Opening CA hall only. Read tutorial.md and final.md as separate tracks. The museum supplies player/camera/light/XR Tools; printed/ contains both complete learner scripts. Tests are scoped reconstruction evidence, not an independent student review.\n')
hashes={}
for p in [M/'tutorial.md',M/'final.md',R/'commons/artifacts/ca_rule_explorer/hand_point.gd',R/'commons/artifacts/ca_rule_explorer/point_body.gd',R/'commons/artifacts/ca_rule_explorer/neighbour_study.gd']:
 hashes[p.relative_to(R).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
missing=[];count=0
for p in O.glob('*.html'):
 for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if target.startswith(('http','#','mailto:')): continue
  count+=1
  if not (p.parent/target.split('#')[0]).exists(): missing.append(str(p.name)+': '+target)
assert not missing,missing
with zipfile.ZipFile(O/'ca-opening-review.zip') as z: assert z.testzip() is None
(O/'publication-checks.json').write_text(json.dumps({'local_references_checked':count,'missing':missing,'zip_integrity':True,'source_hashes':hashes,'visual_review':'Native images inspected; no browser preview attempted.'},indent=2),encoding='utf-8')
print(json.dumps({'local_links':count,'source_hashes':len(hashes),'tutorial_checks':n,'museum_checks':m}))
