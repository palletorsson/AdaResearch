"""Publish the complete Life lesson, native spatial review and scoped evidence."""
from pathlib import Path
import ast,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-pattern-visits'
M=R/'commons/maps/CA_BeyondBinary'
code=json.loads((O/'checks.json').read_text(encoding='utf-8'))
room=json.loads((O/'museum/report.json').read_text(encoding='utf-8'))
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
(O/'before/images').mkdir(exist_ok=True);(M/'images').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
for filename,capture in [('life-floor.png','address-lit.png'),('life-learner.png','printed-study.png')]:
 if (M/'images'/filename).exists() and not (O/'before/images'/filename).exists():shutil.copy2(M/'images'/filename,O/'before/images'/filename)
 shutil.copy2(O/'museum'/capture,M/'images'/filename);shutil.copy2(M/'images'/filename,O/'images'/filename)
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
report=f'''# A pattern visits an address

The previous hall kept a history. Here both grid axes belong to one present. A glider seems to travel; the cells stay in place. One selected address can light a lamp without receiving any influence back from it.

## Changes per track

- **Tutorial:** complete `life.gd` plus the unchanged PointBody file. Count eight neighbours, apply B3/S23 synchronously, draw fixed cells and connect one address to one lamp. Build a blinker, predict its phases, then move only the lamp's binding. All geometry is visible in the code; the existing museum supplies Day Zero's player, camera, light and XR Tools.
- **Reflection:** retain the encounter with pattern, place, withdrawal and support. Remove implementation blocks. Clarify that Conway's reported design aims were not a theorem forbidding unbounded growth. The observing body still does not enter this rule; that transition belongs to the next hall.
- **Interaction:** the familiar black point now carries STEP beside the large floor. Pick it up, walk to an address and use the trigger. Release parks it by the console. Its location does not change a cell. This addition applies only to `floor:walk` address-study placements.
- **Room:** level the rear gallery and remove its short partition. Scale the mould and growth studies to fit; move the dark sphere and screen away from crowding. Keep all six authored works, including the existing hexagonal table. Reserve incidental sculpture out of circulation and put entry/exit on the thresholds.
- **Plan:** update this hall's summary, dependencies, transfer task and evidence. Other lesson rows and this lesson's draft decision are preserved.

## The teaching line

The opening taught an old-to-next row. The next room gave state a duration in a volume. The third kept independent generations and used them as image, ornament and support. **This fourth hall asks what we follow when we recognise a moving figure.** It introduces Conway's two-dimensional present and an explicit output connection.

The learner study is deliberately smaller than the installation: one lamp and manual steps at a table, rather than three lamps, RUN, TRACE and preset controls around a 9.6 m floor. Both use a 24 × 24 wrapped grid, the same starting glider and the same transition law. The complete learner files were mounted temporarily inside the museum for their photograph; no extra permanent table was added.

The independent exercise changes the beginning to a three-cell blinker. The centre lamp stays lit while the line alternates. Moving the binding to an end address makes the lamp alternate, with no change to the automaton. This checks whether the student can separate a rule from a use of its answer.

## Evidence and limits

**{n} exact-code checks and {q} museum checks pass in native Godot 4.6.** The printed blocks are extracted, matched byte-for-byte to the maintained files, then executed. Checks cover all eighteen rule cases, all eight neighbour offsets, wrapping, fresh buffers, reverse iteration, 48 glider steps and eight other beginnings against the installed solver. They also cover the independent blinker/address exercises, two deliberately broken rule variants, rendered colours, fixed transforms, collision support and actual XRTools pickup/action/release with supplied poses.

The museum checks cover carried STEP, LINK without cell changes or false onset counts, TRACE restoration in both views, the blinker and meeting, RUN/limit, and a supplied body supported at address A before, during and after occupancy. Five routes contain **{samples} samples** of level floor and clearance for a 0.56 m wide, 1.7 m high capsule on layer 1. Portal approaches pass. Camera-retention checks are included in the museum total.

The first learner probe used an incorrect production property name; the corrected harness passed. The first route samples touched the console and readout stem. The final path stops at the reachable console approach and goes around the furniture. Earlier diagnostic logs are retained. Final successful runs contain no SCRIPT ERROR or Parse Error; existing project warnings remain.

The Life solver and lamp receiver are unchanged from this pass's baseline. The hand control reuses the existing STEP. Secondary works were repositioned, not given a new interaction audit. Native captures retain the current lighting and blank wall frames. These results do not establish tracked-headset comfort, Quest performance, full portal transfer, every collision layer, or an independent student's understanding.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Whole tutorial](tutorial.html) · [Whole reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact life.gd](printed/life.gd) · [unchanged point_body.gd](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner engine log](engine.log) · [Museum engine log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-life-review.zip)
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_BeyondBinary:2Dpresent24x24 B3/S23;8neighbours exclude centre;freshbuffer+periodicwrap. SamePointBody carriesSTEP,nohandstateinput. FixedA->lamp;LINKoutputonly. Glider4steps(+1,+1);blinkertransfer;otheraddresslampalternates. Full2filetutorial/finalprose. Rearlevel;6workskept,mould.4,growth.35+lift,orb/screenmoved;thresholdportals. {n}exactcode+{q}museumchecks;{samples}routesamples;noheadset/student/portaltransfer. Solver+receiverunchanged. NextCA_ExpandingSpace:proximityinput.\n',encoding='utf-8')
# Reuse the preceding report's visual language without executing its publisher.
tree=ast.parse((R/'tools/publish_ca_history_lesson.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in node.targets))
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-life-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>One hall, two complete texts. Native museum evidence. Next: CA_ExpandingSpace.</footer></body></html>',encoding='utf-8')
body='<p class="lead">The pattern travels. The address stays. Something in the room answers.</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/entry.png','Inside the existing museum: carry the black point beside the console to STEP while you follow an address on the floor.')
body+='''<section id="layout"><h2>Give the rear works room</h2><p>The entrance is at the top. The main floor experiment keeps its place; the rear passage opens around the secondary works.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'''+photo('before/museum/overhead.png','Before: raised strips, pits and a short rear partition. The growth study extends beyond the rear wall.')+'</div><div class="after">'+photo('museum/overhead.png','After: level gallery and clear onward route. Mould and growth studies fit within the hall; all six authored works remain.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, from above and to one side.')+photo('museum/raised-oblique.png','After, from the same camera. No room walls were removed for the capture.')+'</div></section>'
body+='<h2>A place keeps holding you</h2><div class="pair">'+photo('museum/address-lit.png','Generation eight: A receives occupancy and its lamp lights. The underlying floor remains solid.')+photo('museum/carried-step.png','The installed PointBody held beside the floor, using actual XRTools with a supplied controller pose.')+'</div>'
body+=photo('museum/rear-gallery.png','At visitor height: the dark sphere, scaled growth study and retained hexagonal table, with a route onward.')
body+='<h2>The complete code, inside the museum</h2>'+photo('museum/printed-study.png','Temporary mounting of the exact printed learner files at generation eight. One fixed address drives one lamp; the point carries STEP.')
body+=md(report.split('\n',2)[2]);page('index.html','A pattern visits an address',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · A pattern visits an address',t)
page('final.html','Reflection · A pattern visits an address',f)
page('parallel.html','One present, two readings','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
for name in ['address_study.gd','life_hand.gd']:
 old=(O/'before'/name).read_text(encoding='utf-8') if (O/'before'/name).exists() else ''
 diff.extend(difflib.unified_diff(old.splitlines(True),(R/'commons/artifacts/game_of_life_petri'/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
with zipfile.ZipFile(O/'ca-life-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/life.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/life-floor.png']:
  if name.endswith('.html'):
   z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-life-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-life-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 z.writestr('README.md','CA_BeyondBinary only. Open index.html or read tutorial.md and final.md separately. Existing Day Zero museum host required; printed/ includes both complete learner files. 29 exact-code and 38 scoped museum checks pass. No physical headset or independent student acceptance.\n')
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
assert not missing,missing
for name in ['game_of_life_petri.gd','life_address_receiver.gd']:assert (O/'before'/name).read_bytes()==(R/'commons/artifacts/game_of_life_petri'/name).read_bytes()
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
for name,block in zip(['life.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-life-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target.startswith(('http:','https:')) or target in z.namelist(),(name,ref)
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_solver_and_receiver_unchanged':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True}))
