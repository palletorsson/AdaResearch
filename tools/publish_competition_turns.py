from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-competition-the-next-turn';M=R/'commons/maps/LSystems_Competition';RUN=R/'ada_run/encounter_pilot/LSystems_Competition'
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
protected=['algorithms/lsystems/Ecosystem/ForestCompetition.gd','commons/maps/LSystems_Competition/map_data.json','commons/maps/sequences/lsystems.json']
for name in protected:assert sha(R/name)==before[name]
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Competition')
row.update(object='Two familiar branching sentences and one shared field, advanced with the carried PointBody.',
change='Consume from the current shared grid before testing whether rewriting is permitted. Preserve before/after snapshots; compare the same start under opposite schedules.',
dependsOn=['LSystems_Grammars_And_Curves','LSystems_Architecture','CA_ExpandingSpace'],
reuses='Byte-unchanged PointBody, line renderer and Curves grammar/reader. Grid addresses, dictionaries, loops, conditionals and deep copies.',
given='Prepared museum floor, camera, player and XRTools. Five complete files are printed. Fixed 5x5 sampling patches isolate the first-round resource operation; full installed forest remains a companion.',
later='Crown-dependent sampling, diameter growth, health, diffusion and automatic seasons remain in the installed forest. No ecological equilibrium claim or implicit transfer across halls.',
checks=[f'{n} native printed-program checks; eight first-round comparisons with production; full root-position variant executed; snapshot-alias and gate-order faults rejected.',f'{q} native museum checks including nine camera checks, six actual pointer-button effects, XRTools supplied poses and {samples} supported route samples.'],
transfer='Change B root from (10,10) to (14,10), predict disjoint patches and equal first-round uptake2.25 under either order. Run the complete modified program.',
carry='An intact rule may meet a world already changed by another instruction. Resource consumption and visible growth require separate records.',
next='LSystems_Living: inspect the genetic sculptor, make a reproducible design record and distinguish parameter changes from unlimited authoring.',
notes='Competition primary reconstructed; draft decision retained. Only museum addition is the familiar held point beside the existing console. Forest kernel, map and sequence unchanged. First pair matches production; later fixed-area history intentionally differs. Author-led native tests, no independent student or physical headset.',
summary='Keep the known branching rule and reader. Let two stems request resources from overlapping squares of one grid, recording the field before and after each attempt. Reverse the first turn from the same start; compare allocation. In winter, consumption continues while rewriting waits. The carried point triggers one turn. Build the complete fixed-area study; move one root until the patches no longer overlap and explain why the first-round allocation becomes equal. Carry the distinction between an instruction and the situation that permits its execution into Living.')
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!='LSystems_Competition')
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Competition/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

The full tutorial prints soil.gd and competition.gd plus byte-unchanged grammar.gd, point_body.gd and line_skin.gd from Grammars and Curves. Rewriting is still parallel within each sentence; resource requests are sequential between trees. The reader retains its vertical plane,25° turns and0.32m strides. Five-by-five patches use roots(9,10)/(10,10),15% withdrawal and starting value0.6. Deep before/after field copies preserve evidence; history is bounded to80 attempts, generation to3, symbols to4096.

The reduction fixes the sampling radius at2 and omits allometry, health, diffusion and automatic seasons. Eight first-round events match installed consumption, field state, rewritten sentences and generations across both orders and spring/winter. A third spring event intentionally diverges as the installed crown expands its patch. Rendering is deliberately different: familiar fixed-size cylinder branches, without the production forest's allometric enlargement. No identical later-history claim.

The executed student edit moves B's address to(14,10). The patches cease to overlap; both first requests take2.25 under either schedule. Checks detect aliased snapshot storage and a winter gate incorrectly placed before consumption. The generation cap remains before consumption. Three existing helpers are byte-identical to the prior hall.

Production CompetitionHand adds that PointBody beside the six-control desk, at local(.88,1.14,2). Held trigger delegates one STEP to the unchanged forest kernel. Motion alone does not take a turn; release parks. Existing maps, three authored works, five-strategy forest and sequence order remain unchanged.

{n} printed-program checks and {q} native museum checks pass, including nine capture-camera checks, six pointer-control state changes, XRTools with supplied poses and {samples} supported outer-route samples. Four baseline and nine after images show the actual hall. The printed study is photographed temporarily at the original host with the original primary hidden, then removed. Hiding its parent for that image also hides the original forest, console and flush covers visually; the covers retain collision. It is not a second installed artifact.

The first museum assertion run incorrectly looked for a 'pressed' return field absent from the desktop driver's API, rejecting all six buttons despite subsequent state tests passing. The corrected probe records pointer hits and each actual effect; the rejected receipt is retained. No production change was needed for that test-harness mistake. Final native logs have no SCRIPT ERROR/Parse Error; pre-existing UID diagnostics remain.

Tests are author-led, not independent ghost-student, physical headset, Quest timing or full portal traversal evidence. Baseline/after overheads show a clear pair at the front and original collection behind it. Small/distant original-forest labels remain a readability follow-up. Review: doc/book/iterations/2026-10-09-competition-the-next-turn/index.html. Five of eight L-systems halls reconstructed; Living next.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
 a=(O/'before/commons/maps/LSystems_Competition'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
 write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# The next turn inherits the change

Competition now has a complete, tested tutorial inside the Endless Museum. The existing room already makes its central experiment clear: two identical instructions take turns on overlapping patches of soil. The first changes what the second can receive.

## What changed

| Part | Before | Now |
|---|---|---|
|Tutorial|Seven actions to inspect; proposed subject labels|Five complete runnable files, focused explanations, retained state and an executed student variation|
|Museum interaction|Six nearby buttons|The same buttons plus the familiar point: hold and trigger one turn|
|Reflection|Strong account with implementation excerpts|The same argument, expressed in prose; exact code lives in the tutorial|
|Room|Controlled pair in front, original forest behind|Same arrangement and three authored works; added point plinth beside the console|

The tutorial carries the point, cylinder and grammar reader from Curves unchanged. It adds a shared grid and a schedule. The before/after snapshots make a quiet event inspectable: winter can prevent branching without preventing consumption.

## The teaching boundary

The small program holds sampling areas fixed. The installed forest also changes crown size, diameter and health. Their first pair of resource requests agrees; subsequent histories can diverge. That boundary is stated in the tutorial and tested, rather than concealed behind a claim that a short example reconstructs every feature.

The student moves the second root five cells from the first. The overlapping patches become separate patches. First-round uptake becomes2.250 for each tree, in either order. The grammar stays unchanged. This tests the student's ability to change the relation, not merely reproduce the demonstration.

## Evidence

- **{n} native printed-code checks**, including eight first-round comparisons with the actual forest, the full edited program, conserved consumption accounting, bounded records, conditional rewriting, and two deliberately faulty implementations.
- **{q} native museum checks**, including nine captures, all six pointer-button effects, held-point pickup/action/release, winter consumption, separate SOIL time, the generation cap, valid portal records and {samples} supported outer-route samples.
- Four baseline and nine after images, exact tutorial-code extraction, inherited-file equality, local-link and ZIP validation.

The first museum test read a nonexistent driver return field and therefore reported six button failures. The repaired probe checks the actual state changes as well as pointer hits. Both receipts remain available. This was a test-harness error, not evidence that the controls needed replacing.

The forest kernel, map and sequence order are unchanged. These are author-led tests with supplied controller poses; they do not establish independent learner understanding, headset comfort or Quest performance. The overhead view preserves the two-room-length progression; distant labels and small original-forest geometry still need human readability judgment. No broader spatial redesign was necessary in this pass.

## Carry onward

An instruction can remain intact while its opportunity to act changes. Keep the instruction, the schedule and the changed field distinct. Living is next: which changes can a design record and its controls actually request?

Five of eight L-systems halls have received this reconstruction pass.
'''
report=report.replace('uptake becomes2.250','uptake becomes 2.250')
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-architecture-a-place-to-pass/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s):
 rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 05 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="competition-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led tests · physical headset and independent student review remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={name:(O/(name+'.md')).read_text(encoding='utf-8') for name in ['tutorial','final']}
for name,s in texts.items():write(O/(name+'.html'),page(name,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Competition — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for name in ['tutorial','final']:
 changes+='<h2>'+name+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/LSystems_Competition'/(name+'.md')).read_text(encoding='utf-8'))+'</article><article>'+md(texts[name])+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>The next turn<br>inherits the change.</h1><p class="lead">Same instructions. Shared soil. A different place in the order.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum checks · 8 first-round comparisons with the forest</p>'
body+=fig('assets/two-turns.png','Inside Competition after two turns: both rules have rewritten once, but uptake differs. Amber took 2.250; blue took 1.980.')
body+='<div class="pair">'+fig('before-captures/opening.png','Before: the controlled pair and its six-button console already occupy the front of the hall.')+fig('assets/opening.png','After: the same arrangement, with the carried point beside the console. No map or forest-kernel change.')+'</div>'
body+=fig('assets/hand.png','The familiar point adds one action: while held, press its trigger to give one tree a turn. Moving the point alone does not consume soil.')
body+='<div class="pair">'+fig('assets/soil.png','The outlines locate overlapping sampling squares. They show the actual roots, distinct from the separated branch displays.')+fig('assets/winter.png','Winter keeps the stems while their shared field changes. The tutorial preserves before/after records for that operation.')+'</div>'
body+=fig('assets/grown.png','The installed pair after reaching its three-generation budget. Further turns do not consume. This stopping condition differs from winter.')
body+='<div class="pair">'+fig('before-captures/above.png','Before, from above: a front comparison and the retained forest behind it, with routes on both sides.')+fig('assets/above.png','After, from above: the point sits beside the existing desk; all three authored works and the onward passage remain.')+'</div>'
body+=fig('assets/forest.png','The original five-strategy forest remains a companion. Its soil, seasons, estimated crowns and health add processes beyond the focused tutorial.')
body+=fig('assets/student.png','The exact printed study running temporarily at the same museum host. The original primary is hidden for this view and restored afterwards. The simpler cylinder branches keep Curves’ fixed stride; resource agreement is tested separately from appearance.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('The next turn inherits the change',body))
for name in ['competition_turns_before.gd','competition_turns_lesson.gd','competition_turns_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
shutil.copyfile(R/'tools/test_competition_turns.py',O/'probes/test_competition_turns.py')
for name in ['competition_lesson.gd','competition_hand.gd']:shutil.copyfile(R/'commons/artifacts/competition_lesson'/name,O/'after'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{name:sha(R/name) for name in protected},'checks':[n,q],'production_comparisons':8,'route_samples':samples})
write(O/'README.txt','Open index.html for native museum views; parallel.html puts tutorial left/reflection right. printed/ is the exact tested five-file program. variation/ is the executed root-position edit; alias/ and winter_first/ are deliberate faults. Requires the prepared Endless Museum project with XRTools, floor and player. Not an empty-project starter. Production dynamics and the fixed-area study agree for the initial pair, not every later state. Physical headset and independent student review remain open.\n')
archive=O/'competition-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="competition-review.zip"',b'href="README.txt"')
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
assert len(rendered)==5
for name,s in zip(['soil.gd','competition.gd','grammar.gd','point_body.gd','line_skin.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode('utf-8'))
   for v in parser.links:
    if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_references':refs,'rendered_code_matches':5,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
