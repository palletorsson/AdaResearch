"""Publish one controlled-comparison lesson and native museum evidence."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_02'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_02'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-ribbon02-review.zip')
def md(s):
 for n in ['contrast-neighbours-museum.png','contrast-equal-museum.png']:s=s.replace('/book-images/figures/tiling/'+n,'images/'+n)
 return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def write(n,s):(O/n).write_text(s,encoding='utf8')
def sync_plan(tests,native):
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
 row=next(x for x in data['lessons'] if x['id']=='Ribbon_Patterns_02')
 def fmt(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 old=fmt(row);assert raw.count(old)==1
 row.update(object='Carried PointBody and source selector; two target bodies and connector deliberately share one material.',
 change='Select one source colour for both targets; change surrounds independently with SWAP/EQUAL and reveal a same-colour connector. Use the installed plane/curve to investigate physical spacing and supplied shading.',
 dependsOn=['Ribbon_Patterns_01','Pattern_Temple','Color_Flashlight'],
 reuses='Wrapped source lookup, palette, grid and PointBody unchanged. Temple ownership returns: share a material when equality should persist; keep surrounds independent.',
 given='Three unchanged helpers and museum host. New small complete comparison entry; source stays fixed during interaction. Installed carrier meshes and directional shader are supplied, not a new shader-writing requirement.',
 later='Numerical equality is testable; perceived equality is not prescribed. Installed targets are grey; learner starts navy and transfer changes zero to grey. Equal surface width differs from projected width. Open half-cylinder is not a seam or spectral-metamerism test. LIGHT SIDE is a shader input, not the museum sun.',
 checks=[f"{tests['checks']} native Godot assertions:26 exact printed and26 independent grey/mint edit; eight runnable faults caught by behavioral assertions.",f"{len(native['checks'])} native museum checks: actual pointer controls on both stations, source/geometry preservation, equal surface span, clear approaches, synthetic XRTools grip/actions/release and independent edit. No physical-headset or student-understanding claim."],
 transfer='Change palette zero to grey and source[1][2] to existing mint index2. Predict both targets/connector, EQUAL following selection, SWAP retained while equal, unchanged source and25 reference poses. Separately predict spacing and shading at installed carriers.',
 carry='Controlled comparison: changed condition, fixed values, observed result. Share and copy according to intended ownership; distinguish appearance from assigned data.',
 next='Ribbon_Patterns_03: inspect the actual shader/fabric studio; carry source, material sharing and UV-versus-physical-spacing distinctions.',
 notes='9 October: initial four-file tutorial adds a small runnable context comparison to the earlier observational plan. No new shader authorship or dot-product prerequisite. Most final.md preserved; shader excerpt becomes prose. Production code/map/technical/order unchanged. Native screenshots from close to carrier console avoid the neighbouring carousel.',
 summary='Keep the point, palette and six-entry source. Select a reference cell and assign its colour to two targets through one shared material; exchange independently owned surrounds, match them to the target, and show a same-colour connector. Predict which values stay fixed and report your own visual comparison. Make a grey/mint variation, then use the installed plane and half-cylinder to separate surface spacing, projected width and supplied shading. Carry a controlled comparison method into the shader studio.')
 new=raw.replace(old,fmt(row),1);parsed=json.loads(new)
 assert [x for x in data['lessons'] if x['id']!='Ribbon_Patterns_02']==[x for x in parsed['lessons'] if x['id']!='Ribbon_Patterns_02']
 assert p.read_text(encoding='utf8')==raw;p.write_text(new,encoding='utf8')
 write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
 write('plan-entry.diff',''.join(difflib.unified_diff((O/'before/plan-entry.json').read_text(encoding='utf8').splitlines(True),(O/'plan-entry.json').read_text(encoding='utf8').splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')))
def main():
 tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
 run=R/'ada_run/encounter_pilot/Ribbon_Patterns_02/equal-values';native=json.loads((run/'report.json').read_text())
 assert tests['all_passed'] and faults['all_rejected'] and native['passed']
 assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
 (O/'museum').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
 for p in run.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,O/'museum'/p.name)
 for n in ['contrast-neighbours-museum.png','contrast-equal-museum.png']:shutil.copy2(R/'doc/book/figures/tiling'/n,O/'images'/n)
 prediction=json.loads((O/'prediction.json').read_text());assert sha(M/'tutorial.md')==prediction['source_sha256']
 tracks={};diffs=[]
 for name in ['tutorial','final']:
  text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
  write(name+'.html',page('Ribbon Patterns 02 / '+name,md(text)))
  before=(O/'before'/(name+'.md')).read_text(encoding='utf8') if name=='final' else ''
  delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=('before/' if before else 'absent/')+name+'.md',tofile='after/'+name+'.md'))
  write(name+'.diff',delta);diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
 for n,code in blocks.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n' and sha(O/'learner/printed'/n)==prediction['files'][n]
 carried=json.loads((O/'carried-files.json').read_text())
 for n,p in carried.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
 for n in ['map_data.json','technical.md']:assert (M/n).read_bytes()==(O/'before'/n).read_bytes()
 old=(O/'before/final.md').read_text(encoding='utf8')
 assert re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',tracks['final'])
 assert old.split('This small shader multiplies')[0]==tracks['final'].split('The supplied shader compares')[0]
 assert old.split('Try **REPEAT SIZE**')[1]==tracks['final'].split('Try **REPEAT SIZE**')[1]
 assert '```' not in tracks['final']
 sync_plan(tests,native)
 sources=[M/n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+[R/'algorithms/color/carrier_comparison.gd',R/'algorithms/color/carrier_comparison.gdshader',R/'commons/maps/sequences/tiling.json',*[R/p for p in carried.values()]]
 write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
 intro='<p class="meta kicker">Endless Museum / Tiling 08</p><p><a href="../Ribbon_Patterns_01/parallel.html">Previous: Ribbon Patterns 01</a> · Next: Ribbon Patterns 03</p>'
 write('parallel.html',page('Ribbon Patterns 02 / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
 write('changes.html',page('Ribbon Patterns 02 / changes','<h1>Keep the value</h1><p>Initial tutorial: a small context comparison, with the curved carrier retained as a supplied experiment. The existing reflection is preserved apart from converting its shader excerpt and explanation to prose.</p>'+''.join(diffs)))
 report=f'''# Keep the value

Tiling · Ribbon Patterns 02 · 9 October 2026 · eighth of nine halls

**Two bodies keep one colour while their surroundings change.**

## What this lesson adds

The previous lesson separated a stored volume from its visible slice. Here we hold an assigned colour fixed and change the conditions around it. The carried point selects a value from the same six-entry source through the same five-by-five reference grid. Two targets and a connector deliberately share one material; the surrounds have separate materials. The question of copying or sharing from Temple returns with another purpose.

The earlier plan called for an observational companion. This revision keeps that limited subject and adds a small complete comparison program, so the student can reconstruct one interaction. It does not require writing a shader or calculating the curved mesh. Those remain supplied in the installed exhibit, where the student makes separate predictions about repeat spacing and shading.

The independent edit changes palette zero to grey and the last source entry to mint. Both targets must still agree; EQUAL must follow the selected colour; SWAP must leave the source and targets alone. The exercise asks for an observation, not a prescribed perceptual response.

## Before and after

| Track | Before | This revision |
| --- | --- | --- |
| Tutorial | No canonical tutorial; technical description and planned comparisons. | Complete four-file program, three unchanged helpers, explicit museum host, material ownership, predictions and an independent edit. |
| Reflection | Strong context/carrier encounters, including a shader excerpt. | Encounters, questions, images, anchors and ending retained. The shader excerpt and explanation become prose. |
| Museum | Both existing stations and their controls. | No production, placement or route changes. The learner is temporarily placed between the stations for testing and captures. |

The installed targets begin grey. The carried learner begins navy. The grey independent edit makes that difference explicit. At the installed curved display, four metres of arc is not four metres of projected width. Its LIGHT SIDE is a shader direction, not a moving sun; its registry name is not evidence of spectral metamerism.

## Evidence

- **{tests['checks']} Godot assertions passed:** 26 on the exact printed program and 26 on the grey/mint variation.
- **{len(faults['results'])} executable faults caught:** shared surrounds, detached target or connector, missing refresh, wrong coordinate frame, exchanged lookup axes, a fixed grey EQUAL state and ignored SWAP.
- **{len(native['checks'])} native museum checks passed:** real pointer actions at both stations, retained source/geometry, measured surface span, three clear supported approaches, actual XR Tools with simulated grip/actions/release, and the independent edit.

Code tests passed on their first run. The first distant carrier screenshot was blocked by the neighbouring carousel. The final camera moved close to the console; the diagnostic image is retained separately. Both native runs passed. Existing UID/registry/renderer warnings remain; there were no lesson script errors. These tests establish program behaviour, not a learner's understanding or a physical headset experience. Quest performance remains untested.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Changes](changes.html) · [Code results](tests.json) · [Fault results](mutations.json) · [Museum receipt](museum/report.json) · [Review ZIP](tiling-ribbon02-review.zip)

The [editable plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_02&view=summaries) and [Tiling route](../plan.html) now record eight completed draft revisions. Next: **Ribbon Patterns 03**, the shader and fabric studio.
'''
 write('REPORT.md',report)
 pictures=[('installed-context','Installed comparison: both targets are assigned the same grey.'),('installed-equal','Equal surrounds and a connector; no target value changed.'),('installed-flat','The installed plane and curve share a texture.'),('installed-spacing','Eight repeats across four metres of surface; GRID marks repeat boundaries.'),('installed-shaded-left','A supplied directional shading model, with its direction to the left.'),('installed-shaded-right','The direction moves right; source pixels and geometry remain.'),('student-source','The carried source selects a value for both learner targets.'),('student-connected','One shared pink material reaches both targets and the connector.'),('student-equal','EQUAL uses the selected pink for both surrounds.'),('student-grey-edit','The independent grey/mint edit runs in the same museum host.')]
 figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in pictures)
 write('index.html',page('Ribbon Patterns 02 / keep the value',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
 route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
 line=next(l for l in route.splitlines() if l.startswith('| Ribbon Patterns 02 |') or l.startswith('| [Ribbon Patterns 02]'))
 route=route.replace(line,'| [Ribbon Patterns 02](Ribbon_Patterns_02/parallel.html) | Two targets share one material; change their surrounds while retaining the selected source colour. Compare physical spacing and supplied shading on the installed carriers. | Complete eighth revision; full printed comparison, grey/mint edit, fault tests and native museum evidence. No new shader authorship. |')
 line=next(l for l in route.splitlines() if l.startswith('| Ribbon Patterns 03 |'))
 route=route.replace(line,line.replace('Reflective text exists; canonical tutorial absent.','Next: inspect the actual shader/fabric studio. Reflective text exists; canonical tutorial absent.'))
 start=route.find('Seven Tiling lessons are complete')
 if start<0:start=route.find('Eight Tiling lessons are complete')
 assert start>=0
 route=route[:start]+'''Eight Tiling lessons are complete in this pass: [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html), [Array Patterns](Array_Patterns/index.html), [Symmetry Seventeen](Symmetry_Seventeen/index.html), [Pattern Temple](Pattern_Temple/index.html), [Ribbon Patterns 01](Ribbon_Patterns_01/index.html) and [Ribbon Patterns 02](Ribbon_Patterns_02/index.html). Open the [editable project plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_02&view=summaries). All retain draft status; Ribbon Patterns 03 remains pending reconstruction or initial writing.
'''
 route_path.write_text(route,encoding='utf8');route_html=page('Tiling / nine-hall route',md(route))
 for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-ribbon02-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Ribbon_Patterns_02/'+n+'"')
 (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
 write('README.md','''# Ribbon Patterns 02 review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots; HTML uses bundled images. learner/printed contains four exact printed files. learner/grey_mint changes palette zero and one source value. Other learner folders deliberately contain faults. The existing Endless Museum and XR Tools are required.

Run: python tools/test_tiling_ribbon02.py
Native: python tools/run_encounter_probe.py Ribbon_Patterns_02 --sequence tiling --render --no-bridges --probe tools/probes/tiling_ribbon02_room.gd --output-tag equal-values --spec doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_02/spec-student.json

The learner is temporarily at installed context-local(6.8,0,3), not a permanent production artifact. Three supported approaches checked. Native and simulated-XR results do not establish perception, student understanding or physical headset comfort. Reproduce scripts retain repository-relative assumptions. No production code, map, technical.md or sequence order changed.
''')
 dest=O/'reproduce';dest.mkdir(exist_ok=True)
 for n in ['tools/revise_tiling_ribbon02.py','tools/test_tiling_ribbon02.py','tools/publish_tiling_ribbon02.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_ribbon02_student.gd','tools/probes/tiling_ribbon02_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
 with zipfile.ZipFile(O/'tiling-ribbon02-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Ribbon_Patterns_02/'+p.relative_to(O).as_posix())
  for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
 print('Published',O/'index.html')
if __name__=='__main__':main()
