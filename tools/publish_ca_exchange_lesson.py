"""Publish the focused hall, two complete texts and native evidence."""
from pathlib import Path
import ast,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers'
M=R/'commons/maps/CA_SoftRules'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text());assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
(M/'images').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
shutil.copy2(O/'museum/seed-crossing.png',M/'images/exchange-seed.png');shutil.copy2(M/'images/exchange-seed.png',O/'images/exchange-seed.png')
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
report=f'''# What a neighbour offers

The carried point plants a seed in two fields. Both receive the same intervention. One field exchanges with its neighbours; the other begins with that operation removed. A small difference at one address becomes a visible difference across the walls.

## Changes per track

- **Tutorial:** three complete files: a small field class, its museum display/input script, and the unchanged PointBody. Move from counting healthy neighbours to adding their differences. Store U and V at each address. Keep the reaction supplied and named, isolate exchange, and predict the first update before watching it spread. The independent edit puts a seed at a wrapping corner.
- **Reflection:** keep the encounter with reception, dispersal and a room wearing an image. Three code blocks become prose. Add the point's changed role: the sphere that supplied proximity on the bridge can now choose where to plant. Its consequence belongs to the connection we give it.
- **Interaction:** add a small black point beside the existing desk. Hold it near either tabletop and trigger to replace the same 3 × 3 patch in both fields. Moving alone does nothing; triggering advances no time. Release parks it. Existing fixed INJECT, body crossing and all eight desk controls remain.
- **Space:** keep the paired tables, curved walls and clockmaker where they were. Level the rear gallery, remove its partitions, fit the four secondary works around the onward passage and keep all six authored works. Place portals on the thresholds and remove the extra generic gate.
- **Plan:** update this hall's paragraph, prerequisites, transfer and evidence. Its review decision remains draft. No sequence reorder.

## One new relation

The previous hall counted neighbours above a threshold. Here each neighbour contributes how much its concentration differs from the centre. A uniform neighbourhood contributes zero. The cells also react locally through the same supplied Gray–Scott terms.

At W = (12,15), just outside the starting square, the first update gives A **U = .92, V = .02**. With exchange off, B remains **U = 1, V = 0**. Its reaction cannot create a first V at that unseeded site because its U × V × V product is zero. Enabling exchange in both and replaying restores agreement.

The point places the same new patch into both current histories. That does not erase the differences already produced elsewhere. Changing VIEW reads another array; COAT toggles the large display. Neither operation changes the stored state. The fixed museum floor still supports the visitor.

## What the learner receives

`field.gd` owns U,V, a periodic address conversion, the four-axial difference sum, supplied reaction and synchronous updates. `exchange.gd` creates two instances, their displays, table support, labels and held-point input. `point_body.gd` is byte-identical to the previous lesson. No required child is hidden behind a scene reference.

The compact reconstruction belongs in the existing Day Zero museum host. It uses two flat upright panels instead of rebuilding the installation's curved walls. Its keyboard operates the clock, view and exchange; the point's VR trigger plants the seed. The installed exhibit retains the nearby VR desk. These are explicit differences in the reconstruction, not unimplemented controls described as complete.

## Room arrangement

The front comparison stays intact. The rear contains the lattice-gas pump at source (12,18), sphere at (3,22), crack study at (3,18) and falling-rule study at (12,22). The sphere is lifted 1.1 m; the crack study fits at .35 scale and 1.2 m height; the falling-rule study fits at .3 scale and 2.6 m height. Its optional host-lighting setting disables the standalone sun/camera; its cellular and falling-body logic is unchanged.

The level route passes between the field walls, around the clockmaker table and through the rear gallery. All six authored artifacts are confirmed in the runtime inventory. Incidental sculptures are reserved out of this circulation area. Secondary works remain exploratory encounters rather than extra requirements in this tutorial.

## Evidence and limits

**{n} learner checks and {q} museum checks pass in native Godot 4.6.** The three code blocks are extracted from `tutorial.md`, checked against the maintained files, and executed. Both exchange modes match every installed U,V value after every step through 2,400 updates each: 4,800 comparisons, maximum difference **0**.

Checks cover uniform and edge neighbourhoods, separate state, reverse evaluation, bounds, native textures and support, supplied XRTools pickup/action/release, keyboard controls and the observation cap. The independent corner edit produces the predicted nine wrapped addresses, and V first reaches an adjacent unseeded site only with exchange. Deliberately omitting the centre subtraction or writing into the read state breaks the expected answer and is detected.

Installed checks cover the selected hand seed, fixed body seed, remaining on the mark, replay while occupied and leaving/re-entering; view and coating preserve state. Four routes have **{samples} samples** of layer-1 capsule clearance and level floor. Both portal approaches are supported. Camera checks are included in the museum total.

The original `live_field.gd` solver, `walk_seed.gd` receiver and `rd_artifact.gd` wrapper are byte-identical to the baseline. Final runs contain no SCRIPT ERROR or Parse Error. Existing unrelated engine warnings remain. The learner model is temporarily mounted only for its photograph.

No physical headset, Quest performance, full portal transfer, independent student acceptance or full secondary-interaction audit is claimed. Some secondary labels still draw through the primary wall surfaces; existing blank wall frames remain. Secondary animations differ between capture moments. The above-room views make circulation legible; they do not certify the whole room as finished.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Complete tutorial](tutorial.html) · [Complete reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact field.gd](printed/field.gd) · [exchange.gd](printed/exchange.gd) · [point_body.gd](printed/point_body.gd)
- [Learner assertions](checks.json) · [Museum assertions and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-exchange-review.zip)

Next: **CA_AgentsCircuits**. Its current encounter compares a cellular row history with recursive copying. Inspect that material first; the historical hall name and old Wireworld tutorial fragment are not a reliable guide to its teaching focus.
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_SoftRules: carriedPoint->chosen3x3seed,bothindependentfields;triggernoSTEP;releasepark. 32²U,V;4axialdifference=sumNeighbours-4centre;periodic;suppliedGrayScottF.037K.060Du.16Dv.08dt1;clamp;old->new. W492oneStepA(.92,.02),B(1,0). VIEW/COATnotstate. Transfercorner(0,0)->9wrappedsites;outwardVonlyexchange. Fullfield+display+samePointBody;DayZerohost;compactkeyboardclock/VRseed,installedVRdesk+bodycrossing. Solver/receiver/wrapperunchanged. Sixworksretained;rearlevel;fit4secondary;thresholdportals. {n}printed+{q}museumchecks,{samples}routesamples;4800updatesexactparity;2faultsdetected. Noheadset/student/fullportaltransfer. NextactualCA_AgentsCircuits=procedurecomparison,rowhistory/recursivecopies.\n',encoding='utf-8')
tree=ast.parse((R/'tools/publish_ca_history_lesson.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in node.targets))
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-exchange-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>One hall, two complete texts. Native museum evidence. Next: CA_AgentsCircuits.</footer></body></html>',encoding='utf-8')
body='<p class="lead">The same seed. The same reaction. What changes when a neighbour can offer a difference?</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/point-seed.png','Inside the installed museum: the carried point plants a matched patch. Both walls display the same intervention before their rules diverge. Native XRTools supplied pose, not a headset capture.')
body+='<section id="layout"><h2>Keep the comparison; open the passage</h2><p>Entrance at the top. The front tables, curved walls and clockmaker retain their positions.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'+photo('before/museum/overhead.png','Before: rear partitions and floor interruption constrict the onward gallery; the secondary rule array extends beyond it.')+'</div><div class="after">'+photo('museum/overhead.png','After: rear floor levelled and four secondary works spaced around the route. All six authored works retained.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, raised oblique.')+photo('museum/raised-oblique.png','After, same raised camera. The primary comparison remains in place.')+'</div></section>'
body+='<div class="pair">'+photo('before/museum/rear-gallery.png','Before, visitor height in the rear passage.')+photo('museum/rear-gallery.png','After, from the same camera: sphere and falling-rule study flank the onward portal.')+'</div>'
body+=photo('museum/entry.png','Entering the paired-field study. The point and existing eight-button console sit beside the comparison.')
body+='<div class="pair">'+photo('museum/exchange.png','After 100 updates from the original beginning. A exchanges; B only reacts locally.')+photo('museum/seed-crossing.png','After a supplied body crosses at tick 100, then 100 further updates. The inserted patch has mostly dispersed or faded; the earlier field history continues.')+'</div>'
body+='<h2>The complete printed example, inside the museum</h2>'+photo('museum/printed-study.png','Exact three-file learner model, temporarily mounted for its photograph. Two independent fields, each sharing a texture between a table and an upright panel. A and B are labelled.')
body+=md(report.split('\n',2)[2]);page('index.html','What a neighbour offers',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · What a neighbour offers',t);page('final.html','Reflection · What can a cell receive?',f)
page('parallel.html','One intervention, two readings','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
for before,path in [('exchange_study.gd','commons/artifacts/rd_artifact/exchange_study.gd'),('exchange_hand.gd','commons/artifacts/rd_artifact/exchange_hand.gd')]:
 old=(O/'before'/before).read_text(encoding='utf-8') if (O/'before'/before).exists() else ''
 diff.extend(difflib.unified_diff(old.splitlines(True),(R/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+before,tofile=path))
path='algorithms/stringalgorithms/recursiveemergence/rule_30_110/Rule30110Gravity.gd';new=(R/path).read_text(encoding='utf-8');marker='func apply_grid_config(config: Dictionary) -> void:'
old=new.split(marker)[0]+marker+'\n\tpass\n'
diff.extend(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Rule30110Gravity.gd',tofile=path))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
readme=f'CA_SoftRules only. Open index.html, or read tutorial.md/final.md separately. Day Zero Endless Museum host with Godot XR Tools required. printed/ has three complete learner files. {n} learner and {q} scoped museum checks pass. verification/ contains probes and runner to run from the AdaResearch repository, not this extracted ZIP. No physical headset or independent student acceptance.\n'
with zipfile.ZipFile(O/'ca-exchange-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/field.gd','printed/exchange.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/exchange-seed.png']:
  if name.endswith('.html'):z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-exchange-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-exchange-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png','rear-gallery.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 for name in ['test_ca_exchange_lesson.py','probes/ca_exchange_lesson.gd','probes/ca_exchange_room.gd']:z.write(R/'tools'/name,'verification/'+Path(name).name)
 z.writestr('README.md',readme)
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
assert not missing,missing
for name in ['live_field.gd','walk_seed.gd','rd_artifact.gd']:assert (O/'before'/name).read_bytes()==(R/'commons/artifacts/rd_artifact'/name).read_bytes(),name
assert '```' not in (M/'final.md').read_text(encoding='utf-8')
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
for name,block in zip(['field.gd','exchange.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-exchange-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target.startswith(('http:','https:')) or target in z.namelist(),(name,ref)
plan=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))
assert next(r for r in plan['plans'] if r['map']=='CA_SoftRules')==json.loads((O/'after/plan-row.json').read_text())
names=[v.split(':')[0] for row in json.loads((M/'map_data.json').read_text())['layers']['interactables'] for v in row if v.strip()]
assert len(names)==6 and all(name in [x['key'] for x in room['observations']['inventory']] for name in names)
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_solver_receiver_wrapper_unchanged':True,'staged_plan_current':True,'all_six_authored_works_loaded':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True,'zip_mb':round((O/'ca-exchange-review.zip').stat().st_size/1024**2,1)}))
