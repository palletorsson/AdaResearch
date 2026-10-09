"""Publish one complete lesson with native museum evidence and a portable review."""
from pathlib import Path
import ast,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-the-surface-includes-you'
M=R/'commons/maps/CA_ExpandingSpace'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(r['samples'] for r in room['observations']['routes'].values())
(O/'images').mkdir(exist_ok=True);(M/'images').mkdir(exist_ok=True)
shutil.copy2(O/'museum/depleted.png',M/'images/presence-depleted.png')
shutil.copy2(M/'images/presence-depleted.png',O/'images/presence-depleted.png')
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
report=f'''# The surface includes you

The point gains another role. In the previous room it carried STEP; here its held position becomes an input. The floor and wall still share one field, but losing support and losing the capacity to help a neighbour happen at different thresholds.

## Changes per track

- **Tutorial:** complete `presence.gd` and the unchanged PointBody. Build a 5 × 16 fractional field, use a three-dimensional point position, and separate colour, support and recovery. The later three-cell comparison returns to SYNC versus SCAN. The student predicts a height change, then edits one starting value from .495 to .49.
- **Reflection:** preserve the encounter with a surface that responds to your presence. Add the carried point's new role. Move three implementation blocks into prose so the reflection can keep its own pace.
- **Interaction:** a small black point sits beside the desk. Hold it near a cell and trigger: this selects HAND and steps once. Release parks the point and withdraws the input; subsequent steps can recover through healthy neighbours. VISITOR, PROBE and NONE remain available.
- **Room:** preserve the bridge, frieze, basin and ramps. Level the rear gallery and space all six secondary works around the onward passage. Fit the chair, crossway and tree at 0.12, 0.25 and 0.35 scale; lift the crossway 0.8 m as a small relief. All seven authored works remain. Remove the extra entrance gate and place portals on the thresholds. The embedded chair uses the museum's lighting.
- **Plan:** update only this hall's paragraph, prerequisites, transfer task and evidence. Its review decision remains draft.

## The teaching line

The opening created a next row. The second hall gave state a duration. The third kept a history and used it in different bodies. The fourth separated a travelling pattern from a fixed address and its lamp. **Now a position outside the cells can alter their next state.**

The tabletop lesson uses the same transition law as the installed bridge. Its view is one-fifth scale, so the code explicitly converts the point's world position back to simulation units. Its input is the held point's centre. The large bridge can instead read the visitor's body origin. Neither mode measures weight. The miniature has a lower tray; the walkable installation has a basin and recovery ramps.

The strongest distinction is tangible: health 0.3 still supplies support, but contributes nothing to neighbour recovery. A value greater than 0.5 contributes; below 0.2 support ends. The wall shares each floor tile's material while keeping a solid backing. One number can have several different consequences.

## Evidence

**{n} learner checks and {q} museum checks pass in native Godot 4.6.** The learner blocks are extracted from `tutorial.md`, matched byte-for-byte with the maintained files, and executed. Tests cover the radius including height, axial neighbours and boundary, strict thresholds, clamping, independent buffers and update order. Across inputs and schedules, 160 updates match the installed solver. The .49 transfer works; deliberately ignoring height or accidentally scanning in SYNC produces the wrong result and is detected.

Native checks also cover material sharing, physical support, actual XRTools pickup/action/release with supplied controller poses, keyboard controls and the 30-second cap. In the museum, equal PROBE and HAND coordinates yield equal fields. A supplied CharacterBody loses support, lands in the basin and climbs the exit ramp. Four routes have **{samples} samples** of layer-1 capsule clearance and level floor. Portal approaches pass. Camera checks are included in the museum total.

The first parity fixture omitted the installed study-coordinate flag; it was corrected. The first museum run caught a duplicate chair configuration function and a path through the console foot. The function now uses the existing hook and the route goes around the desk. Those failed receipts remain in the review directory. Final successful logs contain no SCRIPT ERROR or Parse Error. Existing engine warnings remain.

The bridge solver is byte-identical to this pass's baseline. No physical headset, Quest performance, complete portal transfer, independent student assessment or secondary-artifact interaction audit is claimed. The native views retain existing blank wall frames. Secondary animations are captured at different moments. The learner model is mounted temporarily for its photograph, not added as another permanent exhibit.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Complete tutorial](tutorial.html) · [Complete reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact presence.gd](printed/presence.gd) · [carried point_body.gd](printed/point_body.gd)
- [Learner assertions](checks.json) · [Museum assertions and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-presence-review.zip)

Next: **CA_SoftRules**—what can a neighbourhood offer beyond a count above a threshold?
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_ExpandingSpace: samePointBody STEP->positioninput. 5x16 floatdictionary; bounded4axial; 3Ddistance<1.35 decays.04 else .01/healthyNeighbour> .5. Support>=.2 independentappearance. Table.2 mapsbacktosimunits. SYNC/SCAN3cell; transferW.495->.49 failshealthythreshold at.5. Full2filetutorial; finalprose. InstalledHANDfourthsource;heldtriggerselects+steps;releaseparks/noinput. Solverunchanged. Basin+rampspreserved;7workskept;rearlevel;chair.12/crossway.25+.8m/tree.35;hostlightchair;thresholdportals. {n}printed+{q}museum checks;{samples}routesamples;suppliedbodyfalls/climbs. Noheadset/student/fullportaltransfer. NextCA_SoftRules.\n',encoding='utf-8')
tree=ast.parse((R/'tools/publish_ca_history_lesson.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in node.targets))
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-presence-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>One hall, two complete texts. Native museum evidence. Next: CA_SoftRules.</footer></body></html>',encoding='utf-8')
body='<p class="lead">The surface can show you a value, carry you, and help its neighbour. Those are three different permissions.</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/depleted.png','Inside the museum after 21 nearby PROBE steps: W is still visible, but its tile no longer supplies collision support. Its corresponding wall panel changes too.')
body+='''<section id="layout"><h2>Give the room a clear passage</h2><p>Entrance at the top. The primary basin stays in place; the rear works move within the hall.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'''+photo('before/museum/overhead.png','Before: rear partition, floor interruptions and an oversized crossway continuing beyond the exit wall.')+'</div><div class="after">'+photo('museum/overhead.png','After: all seven authored works retained. Secondary works fit the rear gallery; the central route remains open.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, raised oblique.')+photo('museum/raised-oblique.png','After, from the same camera. Room walls remain visible; the chair now uses the museum lighting.')+'</div></section>'
body+='<div class="pair">'+photo('before/museum/entry.png','Before: the additional entrance gate obstructed this visitor-height view.')+photo('museum/entry.png','After: the same view opens directly onto the study, its controls and the route onward.')+'</div>'
body+=photo('museum/carried-input.png','HAND: the same carried PointBody now supplies a position as well as STEP. Native XRTools test with a supplied controller pose.')
body+=photo('museum/rear-gallery.png','The onward route at visitor height. The tree and crossway fit within the room; the secondary encounters remain available for separate review.')
body+='<h2>The complete learner code in the museum</h2>'+photo('museum/printed-study.png','Temporary mounting of the exact printed files. One-fifth-scale table and wall share a fractional field; the lower tray receives anything the tiles cease to support.')
body+=md(report.split('\n',2)[2]);page('index.html','The surface includes you',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · The surface includes you',t)
page('final.html','Reflection · The surface includes you',f)
page('parallel.html','One input, two readings','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
for before,path in [('proximity_study.gd','algorithms/cellularautomata/living_architecture/proximity_study.gd'),('proximity_hand.gd','algorithms/cellularautomata/living_architecture/proximity_hand.gd'),('chair_main.gd','algorithms/cellularautomata/CAchairtests/Main.gd')]:
 old=(O/'before'/before).read_text(encoding='utf-8') if (O/'before'/before).exists() else ''
 diff.extend(difflib.unified_diff(old.splitlines(True),(R/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+before,tofile=path))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
readme=f'CA_ExpandingSpace only. Open index.html, or read tutorial.md and final.md separately. Existing Day Zero museum host with Godot XR Tools required. printed/ contains both complete learner files. {n} exact-code and {q} scoped museum checks pass. verification/ contains the native probes and extraction runner; run these from the AdaResearch repository, not this extracted ZIP. No physical headset or independent student acceptance.\n'
with zipfile.ZipFile(O/'ca-presence-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/presence.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/presence-depleted.png']:
  if name.endswith('.html'):z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-presence-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-presence-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png','entry.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 for name in ['test_ca_proximity_lesson.py','probes/ca_proximity_lesson.gd','probes/ca_proximity_room.gd']:z.write(R/'tools'/name,'verification/'+Path(name).name)
 z.writestr('README.md',readme)
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
assert not missing,missing
assert (O/'before/decaying_bridge.gd').read_bytes()==(R/'algorithms/cellularautomata/living_architecture/decaying_bridge.gd').read_bytes()
assert '```' not in (M/'final.md').read_text(encoding='utf-8')
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
for name,block in zip(['presence.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-presence-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target.startswith(('http:','https:')) or target in z.namelist(),(name,ref)
plan=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))
assert next(r for r in plan['plans'] if r['map']=='CA_ExpandingSpace')==json.loads((O/'after/plan-row.json').read_text())
names=[v.split(':')[0] for row in json.loads((M/'map_data.json').read_text())['layers']['interactables'] for v in row if v.strip()]
assert len(names)==7
assert all(name in [x['key'] for x in room['observations']['inventory']] for name in names)
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_solver_unchanged':True,'staged_plan_current':True,'all_seven_authored_works_loaded':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True}))
