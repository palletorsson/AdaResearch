from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-living-a-design-kept';M=R/'commons/maps/LSystems_Living';RUN=R/'ada_run/encounter_pilot/LSystems_Living'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text());before=json.loads((O/'before/hashes.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log',RUN/'engine.log']:assert not any(t in p.read_text(encoding='utf-8',errors='replace') for t in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']);q=len(room['checks']);samples=room['observations']['route_samples']
for folder in ['assets','museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
protected=['commons/artifacts/genetic_tree_sculptor/genetic_tree_sculptor.gd','algorithms/nature_system/morphology/tree_morphology.gd','commons/maps/LSystems_Living/map_data.json','commons/maps/sequences/lsystems.json']
for name in protected:assert sha(R/name)==before[name]
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Living')
row.update(object='The carried PointBody edits a design record; an editing tree, held witness and placed specimen show which changes survive.',
 change='Convert raw Depth, Forks and Angle into bounded counts and a generated sentence. Keep independent recipes and reconstruct their bodies after later edits.',
 dependsOn=['LSystems_Grammars_And_Curves','LSystems_Competition'],
 reuses='PointBody and line renderer unchanged; parallel rewrite unchanged with an explicitly larger budget. Dictionaries, ranges, rounding, saved turtle state and deep copies.',
 given='Prepared Endless Museum floor, camera, player and XRTools. Four complete files printed. The bare three-gene builder is fully shown; tapered bark, leaves and other genes remain in the installed companion.',
 later='No evolutionary search, disk save or automatic cross-hall transport. The installed PLANT also exports DNA for a separate catalyst consumer; the study retains local recipes only.',
 checks=[f'{n} native checks of exact printed code;108 parameter/sentence comparisons with TreeMorphology; complete 45-degree student edit executed; alias and floor-instead-of-round faults rejected.',f'{q} native museum checks including eight camera checks, all six pointer-button effects, supplied XRTools poses, exact geometry at the 4.8/5.0 threshold, independent specimens and {samples} supported route samples.'],
 transfer='Change only START.angle from 30 to 45. Predict an unchanged sentence/count and changed endpoints. Hold it, edit again and reconstruct from the held recipe.',
 carry='A raw value, a compiled instruction and a displayed body are distinct. Keeping a design means preserving a record independently of later edits.',
 next='LSystems_Shape_Grammars: return to the cube; select faces and expose inset/extrusion operations as another kind of design rule.',
 notes='Living reconstructed; draft decision retained. Added familiar hand point to existing console; source generator, morphology, map and sequence unchanged. Three-gene study matches sampled production parameters/sentences, not full bark/leaf appearance. Author-led tests, no independent student or physical headset.',
 summary='Begin with the existing sculptor and HOLD its opening tree. Change Depth from 4.0 through 4.8: the record changes while the compiled tree stays the same. At 5.0 a generation appears. Reconstruct the conversion and the bare three-gene builder in four complete files, using the familiar point to edit and retain a design. Change Angle without changing the sentence. Keep independent held and planted recipes while editing continues; execute a 45-degree starting design and reconstruct its witness. Carry the distinction between requested change, available instructions and the body that was actually drawn.')
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!='LSystems_Living')
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
assert row['decision']==prior['lessons'][next(i for i,x in enumerate(prior['lessons']) if x['id']=='LSystems_Living')]['decision']
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Living/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Four complete files: design.gd, living.gd and byte-unchanged PointBody/line_skin from Competition. The parallel rewrite is unchanged; its explicitly larger 32,768-symbol budget permits the bounded recipe before a separate 200-command reader cap. The source's opposite-branch subset uses three raw genes: Depth 2..10, Forks 1..8, Angle 15..90. Depth halves then rounds/clamps 2..5; Forks rounds/clamps 2..5. F produces S and bracketed branches; S produces FF. The full bare 3D reader includes roll, saved frame/length, 1.2m initial steps and .68 length taper. No tropism, leaf/root/twist generator or tapered bark is implied by this reduction. Its reader accepts internally generated sentences, not arbitrary unvalidated input.

The familiar black point changes the selected gene across 40 horizontal detents; first pickup latches the current position without editing. Trigger keeps a recipe. Keyboard G/arrows/H/P/R gives the same study operations. Independent editing/held/planted dictionaries rebuild all visible specimens. Those records live only in the running scene. The original artifact instead retains geometry plus DNA and PLANT also exports an independent Engine metadata resource for another consumer. The tutorial states this boundary.

Production addition: LivingHand at the existing console's front rail, local y1.18, z2.55, across .8m. It delegates to set_gene_normalized and HOLD, retaining the source's.3s debounce and flush-before-keep. All eight original genes, six buttons, six authored works and both portals remain. Core sculptor, TreeMorphology, map and sequence hashes match the captured baseline.

{n} native printed-program checks pass: 108 production parameter/full-sentence comparisons, threshold 4.8/5.0, snapshot independence, bounded commands, exact turtle examples, supplied XRTools poses under a translated/rotated host. The full student change START.angle 30->45 executes and changes endpoints without changing its sentence. Aliased snapshots and flooring instead of rounding are deliberately detected. These checks do not establish full production mesh equality across the whole parameter space.

{q} native museum checks pass, including eight capture-camera checks, six desktop pointer effects, supplied hand pickup/movement/action/release, identical source geometry below the threshold and changed geometry at 5.0, kept specimens/export independent of later edits, 365 supported outer-route samples and valid entry/exit records. The first room probe grabbed immediately after RESET, before the next physics tick had parked the point, and therefore supplied no actual movement. Its three rejected assertions and probe are preserved; waiting for the parked state fixes the test, without changing production logic. A rear camera initially faced the dividing wall; the final capture moves inside the existing rear room.

Four baseline and eight final native images are supplied. The learner program is photographed temporarily at the source host, with the original primary hidden and restored afterwards; its plinths/console disappear visually but retain collision. The diagram keeps the source display heights and is not a second installed artifact. The front comparison and side bypass are clear. Rear terrain dominates the small companion works, paper panels appear blank in this capture, and elevated fixtures obscure parts of the oblique view. Retained scene nodes do not establish visual acceptance of that older collection; it needs a separate visibility pass. Native logs retain pre-existing UID/renderer diagnostics but no SCRIPT ERROR/Parse Error. No physical-headset, Quest-performance, full-portal-traversal or independent ghost-student claim.

Review: doc/book/iterations/2026-10-09-living-a-design-kept/index.html. Six of eight L-systems halls reconstructed; Shape Grammars next.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
 a=(O/'before/commons/maps/LSystems_Living'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
 write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# Living — a design kept

Living now connects the controls of the existing sculptor to a complete runnable tutorial. Its subject is a precise gap: changing a number does not always change an instruction, and changing an instruction does not guarantee that the whole result will be drawn.

## What the student encounters

Keep the opening tree. Depth moves from4.0 to4.8 while the displayed tree agrees with its witness. At 5.0, another generation appears. Change Angle instead: the directions change while the sentence stays fixed. These are two different relations behind similar controls.

HOLD and PLANT keep earlier designs for comparison. Later edits change only the editing record. RESET restores that record without erasing the witnesses. The point carried from earlier halls now becomes an editing instrument: move it sideways, then press its held trigger to keep the design.

|Part|Before|Now|
|---|---|---|
|Tutorial|Guide to inspecting the existing controls|Four complete files, explained conversion and snapshots, executed student edit|
|Interaction|Six compact buttons and eight original sliders|Same controls plus the familiar hand point at the front rail|
|Reflection|Argument about available and unavailable changes|Preserved argument, added hand encounter, implementation excerpts expressed in prose|
|Arrangement|Editing/held plinths, planting pad, older collection behind|Same arrangement, six authored works and clear outer routes|

## What the small program carries

The point and line renderer are unchanged. The rewriting function also returns unchanged, with a stated increase in its symbol budget. The new builder shows how three raw inputs generate a rule and a body. It uses the source's opposite-branch recipe, a saved3D frame and fixed length taper. The familiar cylinders give branches their visible thickness.

The program includes the full builder. It leaves the source's bark, leaves, roots, twist and other controls in the museum companion. Its local kept recipes do not imply saving to disk or carrying a planted tree through a portal. The installed export has a separate catalyst consumer.

The student changes only the initial Angle from 30 to 45 degrees. The complete edited program runs: its sentence and counts stay equal, its endpoints change. A later edit leaves the kept recipe able to reconstruct the earlier body.

## Evidence and limits

- **{n} native printed-program checks**; **108 sampled production comparisons** of counts, angle and full sentences.
- **{q} native museum checks**, including eight camera checks, all six desktop button effects, supplied XRTools poses, source-geometry threshold, independent kept bodies and DNA, valid portal records and **{samples} supported outer-route samples**.
- Four before and eight after images; full code extracted from the tutorial, inherited-source equality, local-link checks and a validated review ZIP.

The first hand probe ran too quickly after RESET: it grabbed before the point had parked, then supplied the same position again. Three assertions correctly failed. The corrected test waits for that state before moving the hand. The rejected receipt is retained alongside the accepted one.

These are author-led tests with supplied input, not an independent student's assessment or physical-headset validation. The native overhead view shows the working comparison, retained rear room and side routes. The older rear room is less successful visually: its terrain overwhelms the small companions, and the paper panels appear blank in this capture. All six artifact nodes remain, but that is not a visibility pass for every companion. The underlying sculptor, morphology, map and sequence order are unchanged.

## What travels onward

Keep the raw value, the compiled instruction and the displayed body distinct. A witness needs its own record. A desired change with no control names an operation we have not made available yet.

Next is **Shape Grammars**: the cube returns, and face operations become the material of the rule. **Six of eight L-systems halls** have now received this reconstruction pass.
'''
for a,b in [('from4.0','from 4.0'),('to4.8','to 4.8'),('At 5.0','At 5.0'),('saved3D','saved 3D'),('from 30 to 45','from 30 to 45')]:report=report.replace(a,b)
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-competition-the-next-turn/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s):
 rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 06 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="living-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led tests · physical headset and independent student review remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={name:(O/(name+'.md')).read_text(encoding='utf-8') for name in ['tutorial','final']}
for name,s in texts.items():write(O/(name+'.html'),page(name,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Living — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for name in ['tutorial','final']:
 changes+='<h2>'+name+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/LSystems_Living'/(name+'.md')).read_text(encoding='utf-8'))+'</article><article>'+md(texts[name])+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>A design<br>kept.</h1><p class="lead">The value moves. The tree waits. Then one more step changes the rule.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum checks · 108 parameter/sentence comparisons</p>'
body+=fig('assets/below.png','Inside Living: Depth is 4.800. The editable body still agrees with the held witness at 4.000. Both compile to two generations.')
body+='<div class="pair">'+fig('before-captures/opening.png','Before: the existing editing and held plinths, compact desk and original eight-slider rack.')+fig('assets/opening.png','After: the familiar black point returns on a front rail. The two specimen positions and original controls remain.')+'</div>'
body+=fig('assets/hand.png','Move the held point sideways to edit the selected gene. Its trigger holds the current design; release parks the point at that value.')
body+=fig('assets/threshold.png','Depth reaches 5.000. The editing body on the left adds a generation while its witness keeps the earlier form.')
body+=fig('assets/planted.png','PLANT keeps a third specimen on the floor pad. Subsequent edits and RESET leave its captured geometry and record unchanged.')
body+='<div class="pair">'+fig('before-captures/above.png','Before, from above: a comparison in front, a separate older collection behind, and routes along both sides.')+fig('assets/above.png','After, from above: the point rail stays with the desk. All six authored artifacts remain; the outer routes and onward opening pass the probe.')+'</div>'
body+=fig('assets/collection.png','Rear-room limitation: the terrain dominates, the coral is small, and the paper panels appear blank in this capture. The six artifact nodes are retained, but the companions need a separate visibility pass.')
body+=fig('assets/student.png','The exact printed learner program running temporarily at the same museum host. The original primary is hidden for this image and restored afterwards. Thin cylinders reconstruct the bare design; the original console and plinths are not part of this small program.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Living — a design kept',body))
for name in ['living_design_before.gd','living_design_lesson.gd','living_design_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
shutil.copyfile(R/'tools/test_living_design.py',O/'probes/test_living_design.py')
for name in ['living_lesson.gd','living_hand.gd']:shutil.copyfile(R/'commons/artifacts/genetic_tree_sculptor'/name,O/'after'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{name:sha(R/name) for name in protected},'checks':[n,q],'production_comparisons':108,'route_samples':samples})
write(O/'README.txt','Open index.html for native museum views; parallel.html puts tutorial left/reflection right. printed/ is the exact tested four-file program. variation/ is the executed 45-degree edit; alias/ and wrong_round/ are deliberate faults. Requires the prepared Endless Museum project with XRTools, floor and player. Not an empty-project starter. Three-gene counts/sentences agree with sampled source settings; the cylinders are a reduced presentation without bark, roots or leaves. Physical headset and independent student review remain open.\n')
archive=O/'living-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="living-review.zip"',b'href="README.txt"')
   z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ['href','src'] and v:self.links.append(v)
refs=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(p.read_text(encoding='utf-8'))
 for value in parser.links:
  if value.startswith(('http:','https:','#','data:')):continue
  assert (p.parent/value.split('#')[0]).exists(),(p,value)
  refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==4
for name,s in zip(['design.gd','living.gd','point_body.gd','line_skin.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode('utf-8'))
   for v in parser.links:
    if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_references':refs,'rendered_code_matches':4,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
