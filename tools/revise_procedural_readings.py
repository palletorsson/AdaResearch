"""Apply reviewed prose revisions once; preserve every printed learner program."""
from pathlib import Path
import hashlib, json, re, difflib
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-procedural-generation-revised'
baseline=json.loads((O/'before.json').read_text())
order=json.loads((R/'commons/maps/sequences/proceduralgeneration.json').read_text())['sequences']['proceduralgeneration']['maps']
def read(key,kind):
 p=R/'commons/maps'/key/(kind+'.md')
 assert hashlib.sha256(p.read_bytes()).hexdigest()==baseline[p.relative_to(R).as_posix()],('already edited',p)
 return p.read_text(encoding='utf-8')
def replace(text,old,new):
 assert text.count(old)==1,old[:100]
 return text.replace(old,new)

prompts=[
 'Keep the six candidate descriptions. Change the target before changing any genes. Compare which ID leads, then name a feature the score does not read. A held leader is a separate witness; ranking alone does not save your preferred candidate.',
 'Keep the request field. Change which sites can answer, then compare a fork with the held strand. Name what the witness keeps: positions and parent links, not a resumable field and policy.',
 'Keep the eight targets and step length. Change whether a parent may act again. Compare records as well as distinct positions; the held specimen preserves a form and its selected targets, not the whole simulation.',
 'Keep occupancy and the source plane. Change one permitted neighbour relation. Compare reached addresses at the same generation. Restarting the fixed seed repeats an input; it is not an archive of every earlier state.',
 'Keep the nine carving centres, including the repeated entry. Change headroom. Compare the empty cells and the event history separately: the finished void does not record how often a cell was cleared.',
 'Keep the captured local centres. Change the marked extent and compare occupied cells and exposed faces. Name the information that neither sample contains, including the cubes\' rotations.',
 'Keep the held array. Change whether reflection includes its centre axes. Compare corresponding addresses before comparing totals. Decide explicitly whether to commit the result as the next held input.'
]
revisions=[]
for i,key in enumerate(order):
 old=read(key,'tutorial');new=old
 if i==0:
  anchor='## Begin with the existing six'
  intro='''## A practice for the next seven halls

L-systems separated a description from the reader that made it visible. Here we ask what further operations allow: which body is selected, which site can answer, which cells connect, and what a reconstructed surface keeps. In each hall, preserve an input or witness, change a declared decision and compare the consequence. Say what was retained; a geometric specimen, a repeated seed and a saved simulation are different things. The tutorial rebuilds one selected operation inside the existing museum.

'''
  new=replace(new,anchor,intro+anchor)
 if key=='PG_Space_Colonization':
  anchor='### A position remembers its parent'
  walk='''### Follow one site's decision

Begin with the three-request opening and one root. Read one generation in this order:

1. `eligible()` supplies the sites allowed to answer. Here there is only the root.
2. In `decision()`, each request chooses its nearest eligible site inside the influence radius. All three choose that root. With several sites, they need not choose the same one.
3. The root receives three unit directions. Their sideways components cancel. The remaining sum points upward.
4. `step()` normalizes that sum and multiplies it by 0.5. It records one child at (0, 0.5, 0), with parent index 0, then appends it after this generation's decisions.

The two normalizations have different jobs: equalise each request's contribution, then give the resulting step its direction before assigning a length. Find those two lines in the complete code below. Predict this one child before using a larger field.

'''
  new=replace(new,anchor,walk+anchor)
 if key=='PG_Sculpted_Forms':
  anchor='<!-- student-code:sample.gd -->'
  walk='''### Follow one centre to one face

Use one fixed cube at local (0, 1, 0), with spacing 0.5, as a small example of the same pipeline. Read these stages before assembling the full three-cube surface:

| Stage | Value or decision |
|---|---|
| Capture | `to_local()` gives the centre (0, 1, 0) in the construction frame |
| Anchor | Subtract one body edge: the grid origin is (−1, 0, −1) |
| Address | `floor((centre − origin) / 0.5)` gives (2, 2, 2) |
| Occupy | Extent 2 marks addresses 0 through 4 on every axis |
| Expose | At cell (4, 2, 2), neighbour (5, 2, 2) is absent, so its +x face is emitted |
| Assemble | That face lies at local x = 1.25; four corners become two triangles |

The central cell's six neighbours are present, so it contributes no surface face. A single marked neighbourhood contains 125 cells but exposes only its boundary. The three-cube program follows the same stages, with overlapping addresses stored once. These exact local values explain the rule; the later transform discussion explains why captured floating-point values near an address boundary can produce different counts.

'''
  new=replace(new,anchor,walk+anchor)
 # Put the comparison instruction before source attribution, after the lesson's carry.
 source_index=new.rfind('\nSource:')
 if source_index<0: source_index=len(new.rstrip())
 new=new[:source_index].rstrip()+'\n\n## Keep, change, compare\n\n'+prompts[i]+'\n'+new[source_index:]
 p=R/'commons/maps'/key/'tutorial.md';p.write_bytes(new.encode('utf-8'))
 revisions.append((p,old,new))

key='PG_Genetic_Evolution';old=read(key,'final')
new='''# What does the score notice?

<!-- @GeneticProgramming -->

Six boxes wait beyond the desk. One is pink. Before asking why it has been picked, choose a body you would want to keep. Perhaps the small one leaves more room around it. Perhaps you want the largest, though you have no use for it yet. Remember your reason.

Each candidate has a genome: a list of primitive names and parameters. A builder reads it to make the body; an evaluator reads it to produce a number. The family in Shape Grammars was built without ranking. Here a second reader helps decide which descriptions continue. What would it need to know about the choice you just made?

HOLD places the numerical leader on a side plinth. It cannot yet keep whichever candidate you preferred. Your other choice must remain in memory. Change the target and another box becomes pink. The descriptions and generation remain the same; the ranking changes. The held box waits where you left it. What has happened to its claim to be best?

The score rewards proximity to the current target. It says nothing about why you wanted a small body, or what you might someday do with the large one. We can understand this criterion without agreeing that it measures what we value.

Add a ring to the leader. Look through its opening, then back at the score. A conspicuous part has appeared. The number has not moved.

The builder knows how to draw a torus; the estimator has no case for one. Even the parts it counts require scrutiny: its box estimate includes a factor of eight that the unit-box renderer does not, and overlapping parts are added without subtracting their overlaps. The displayed number is a proxy. The ring's omission is a defect we can name and repair. Holding it visible lets us locate the disagreement between the two readers.

Advance a generation and look for that ring. An elite copy can carry it forward although it earned no points. Survival does not tell us that every surviving feature was rewarded. The held witness remains separate from this changing population. It gives us something to compare, without preserving every event that led here.

Beyond the study, the side ramp takes you onto a raised structure. The museum supplies the collision that carries your body; the generated candidates supply none. The nearby cased screen is not a live reader of their scores. A convincing arrangement can suggest connections that have never been made in code.

To select for inhabitation we would have to construct and test that relation: an opening, a surface, a particular body attempting passage. What would your earlier choice ask us to add—a measurement, another representation, or permission to keep something without justifying it to the score?

Carry that question into Space Colonization. The target there becomes a distribution of points. Before changing the form, we will change which growing sites may answer them.

<!-- @ -->
'''
p=R/'commons/maps'/key/'final.md';p.write_bytes(new.encode('utf-8'));revisions.append((p,old,new))

key='PG_Space_Colonization';old=read(key,'final')
footnote=old[old.index('[^runions]:'):].rstrip()
image=re.search(r'!\[[^\]]*\]\([^\n]+\)',old)[0]
new='''# Which points get a say?

<!-- @space_colonization_algorithm -->

Three pink points wait above a small root. Two sit apart at the same height; the third is higher, between them. Follow a line from the root towards each point. Which way would you go if all three asked at once?

Thin threads show the requests. Gold stubs give each direction the same length; the white segment proposes a step. Let it happen. The root has moved nowhere. It has acquired a child above it. Neither side point has been reached. Something useful happened between their demands.

In the last room, an evaluator compared whole bodies with a target number. Here the target is a distribution of positions. These attraction points exert no simulated force. They are coordinates consulted while adding segments. Their name must not do the explanatory work of the operation.

A distant request gets no greater weight merely because it is farther away. Each assigned request contributes a unit direction. Here the sideways demands cancel, and the remaining direction is upwards. The next child takes a short step along it. The construction rods then show the next decision, so the drawing is already looking ahead.

IMAGE

*The opening decision, drawn from the study's own coordinates. The tutorial follows the two normalizations and the resulting half-metre step.*

Change to the uneven field of eight points and follow the strand. A reached point becomes small and dark. It leaves the active calculation but stays visible: the encounter keeps a trace of what mattered.

Under TIPS, an end can produce one successor, which replaces it among the eligible sites. From this single root it makes a strand. A crooked silhouette may suggest a tree without having made a fork. This is a restriction of our study, not the whole space-colonization model from which it takes attraction points and a kill distance.[^runions]

Keep a specimen, then change the policy to NETWORK. The same field and root return. Watch for an earlier site that produces another child. Each request chooses its nearest eligible site; the requests assigned there combine their directions. Older sites can now answer again. Changing that permission makes a fork possible.

The smaller held strand stays beside the growing construction. Compare one fork before their overall outlines. The witness preserves geometry, not a complete simulation ready to resume. NETWORK is also a name with limits: each new node has one parent. The result is still a rooted tree, without loops joining its existing branches.

The larger canopy has its own authored arrangement. Calling the result organic does not remove that authorship. More requests do not promise more branches, and some may remain when the program reaches its budget. A computational limit is not a tree's natural maturity.

Walk around the specimen and onto the rear deck. The museum supports you. The drawn branches do not. A parent relation, a visible connection and a surface that carries a body must each be built; their resemblance cannot supply the missing work.

Keep the distinction as you enter Branching Growth. There a site will choose one nearest invitation instead of combining several assigned requests. Before admiring another tree, find that smaller change.

<!-- @ -->

FOOTNOTE
'''.replace('IMAGE',image).replace('FOOTNOTE',footnote)
p=R/'commons/maps'/key/'final.md';p.write_bytes(new.encode('utf-8'));revisions.append((p,old,new))

rows=[]
for p,old,new in revisions:
 assert re.findall(r'```gdscript\n(.*?)\n```',old,re.S)==re.findall(r'```gdscript\n(.*?)\n```',new,re.S),p
 if p.name=='final.md':
  for pattern in [r'<!--\s*@([^>]*?)-->',r'!\[[^\]]*\]\(([^)]+)\)',r'^\[\^([^\]]+)\]: (.*)$']:
   assert re.findall(pattern,old,re.M)==re.findall(pattern,new,re.M),(p,pattern)
 relative=p.relative_to(R).as_posix()
 rows.append({'source':relative,'before_sha256':baseline[relative],'after_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'words_before':len(old.split()),'words_after':len(new.split())})
 diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+relative,tofile=relative))
 target=O/'diffs'/p.parent.name/(p.name+'.diff');target.parent.mkdir(parents=True,exist_ok=True);target.write_text(diff,encoding='utf-8')
(O/'editorial-checks.json').write_text(json.dumps({'passed':True,'sources':rows,'all_code_unchanged':True,'reflection_markers_images_footnotes_preserved':True},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'edited':len(rows),'reflections':[(r['words_before'],r['words_after']) for r in rows if r['source'].endswith('final.md')]}))
