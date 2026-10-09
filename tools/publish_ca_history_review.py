from pathlib import Path
import json,shutil,html,difflib,zipfile,re,hashlib
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-history-three-bodies';M=R/'commons/maps/CA_GameOfLife'
a=json.loads((O/'checks.json').read_text(encoding='utf-8'));b=json.loads((O/'museum/report.json').read_text(encoding='utf-8'));assert a['passed'] and b['passed']
for name in ['ca_bridge.gd','history_study.gd']:assert (O/'before'/name).read_bytes()==(R/'algorithms/cellularautomata/ca_bridge'/name).read_bytes()
(O/'before/images').mkdir(exist_ok=True)
if not (O/'before/images/walking-history.png').exists():shutil.copy2(M/'images/walking-history.png',O/'before/images/walking-history.png')
shutil.copy2(O/'museum/walking-history.png',M/'images/walking-history.png')
(O/'images').mkdir(exist_ok=True);shutil.copy2(M/'images/walking-history.png',O/'images/walking-history.png')
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
samples=sum(v['samples'] for v in b['observations']['routes'].values())
report=f'''# A history, three bodies

CA_GameOfLife returns to Rule 30 from the opening hall. The new subject is retained history: one record becomes desk image, collision tiles and a wall lattice. This historical map ID is not a claim that the primary artifact runs Conway's Life. CA_BeyondBinary follows with that subject.

## The lesson

Carry the familiar PointBody and old-to-next row rule. Save independent snapshots, separate site from generation, and give one record two views with different collision responsibilities. The learner builds a compact horizontal/vertical pair in the existing museum; the held point selects an old row and its trigger appends a generation. The full construction and unchanged PointBody are printed in tutorial.md. The museum's existing walking reader remains unchanged.

The transfer task changes the seed to two sites, predicts its six descendants, then flips the vertical mapping while retaining the same state. Reading an earlier generation does not reverse the calculation.

## The space

All six authored artifacts remain. The rear partition and tiered strips become level circulation around the laboratory. The orb and column study move clear of its rear wall. Incidental sculptures are excluded from this narrow circuit. The front basin, its lower floor, ramps and three coordinated history views remain. Entry and exit now use central thresholds with supported approaches.

The main reflection keeps its argument about a gap as image or support, the desire for ornament, and a past that survives our return. Two implementation excerpts become prose. The change from the previous 3D state volume back to the earlier Rule 30 row is explicit.

## Native evidence

**{len(a['checks'])} construction checks and {len(b['checks'])} museum checks pass.** The former execute exactly the two printed files: eight Rule 30 cases, eight seeded 24-row histories against the installed solver, independent snapshots, a rejected aliasing fault, both learner variations, collision rays, rendered slots and actual XRTools pickup/action/release with supplied poses. The museum checks exercise its existing three-way walking selection, return through history, RUN versus ROW, replay, altered seed, 24-row limit and occupied-versus-empty floor. Five routes have {samples} floor and 0.56 m wide / 1.7 m tall capsule samples on collision layer 1. Museum counts include camera checks.

The first room probe put the approach too close to the console and tested a gap above the entry ramp. Moving the test approach back 0.3 m and testing the basin away from the ramp resolved those three probe failures. Final logs have no SCRIPT ERROR or Parse Error. The installed Rule 30 and history scripts are byte-unchanged from this turn's baseline.

This does not certify a tracked headset, Quest performance, whole portal transfer, all collision layers or a human learner. Rear lab signage reads backwards from its outside window; it remains a separate presentation issue. Existing bright lighting also remains. The printed study capture is a temporary museum mounting, not another permanently installed artifact.

## Files

- [Tutorial left / reflection right](parallel.html)
- [Tutorial](tutorial.html) · [Reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Printed code](printed/history.gd) · [Carried point](printed/point_body.gd)
- [Construction assertions](checks.json) · [Museum assertions](museum/report.json)
- [Scoped changes](changes.diff) · [Review ZIP](ca-history-review.zip)
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
style='''body{margin:0;background:#f4f0e9;color:#202d31;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1440px;margin:auto;padding:32px}h1{font-size:clamp(36px,6vw,72px);line-height:1.05}h2{margin-top:2em}nav,figcaption,small{font:14px/1.5 system-ui}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#38666b}p,li{max-width:82ch}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}article{min-width:0}figure{margin:20px 0}img{width:100%;display:block}figcaption{padding:8px 0}pre{background:#203134;color:#fff;padding:20px;overflow:auto;font:13px/1.5 Consolas;tab-size:4}code{font-size:.82em}pre code{font-size:inherit}@media(max-width:820px){.pair{display:block}}'''
nav='<nav><a href="index.html">Hall</a><a href="index.html#layout">Above</a><a href="parallel.html">Facing texts</a><a href="ca-history-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption)}"><figcaption>{caption}</figcaption></figure>'
def page(name,title,body):(O/name).write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{style}</style><header><small>ENDLESS MUSEUM / CA / 8 OCTOBER 2026</small><h1>{title}</h1>{nav}</header><main>{body}</main><footer>Native Godot evidence; no tracked-headset or independent learner claim.</footer></html>',encoding='utf-8')
body=photo('museum/walking-history.png','Inside the hall: gold selects one generation across tiles and lattice. Walking backwards preserves later rows.')
body+='<section id="layout"><h2>Give the rear gallery a route</h2><div class="pair">'+photo('before/museum/overhead.png','Before: side partition, raised strips and gaps constrain the rear works.')+photo('museum/overhead.png','After: level circulation; orb and columns clear of the lab; front basin retained.')+'</div><div class="pair">'+photo('before/museum/raised-oblique.png','Before, raised oblique.')+photo('museum/raised-oblique.png','After, identical camera; no walls hidden.')+'</div></section>'
body+='<div class="pair">'+photo('museum/rear-gallery.png','Rear works, now separated. The back of the lab sign is still visible.')+photo('museum/printed-study.png','Exact printed learner construction temporarily mounted inside the museum.')+'</div>'+md(report)
page('index.html','A history, three bodies',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · Keep a generation',t);page('final.html','Reflection · A history you can inhabit',f)
page('parallel.html','One hall, two readings','<div class="pair"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
with zipfile.ZipFile(O/'ca-history-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['REPORT.md','tutorial.md','final.md','checks.json','museum/report.json','printed/history.gd','printed/point_body.gd','images/walking-history.png']:z.write(O/name,name)
 z.writestr('README.md','CA_GameOfLife: retained Rule 30 history, not Conway Life. Run printed scripts inside the existing Day Zero museum host. Separate tutorial/reflection. No physical headset or human learner test.\n')
links=0
for p in O.glob('*.html'):
 for link in re.findall(r'(?:src|href)="([^"]+)"',p.read_text(encoding='utf-8')):
  if link.startswith(('http:','https:')):continue
  links+=1;target=link.split('#')[0];assert (p.parent/target).exists(),link
with zipfile.ZipFile(O/'ca-history-review.zip') as z:assert z.testzip() is None
(O/'publication-checks.json').write_text(json.dumps({'links_valid':links,'zip_valid':True,'production_solver_and_history_unchanged':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print('Published history hall:',len(a['checks']),len(b['checks']),samples,'route samples;',links,'links')
