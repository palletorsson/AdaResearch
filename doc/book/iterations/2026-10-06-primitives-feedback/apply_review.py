"""Apply a bounded prose review; preserve every executable learner-code block."""
from pathlib import Path
import json, re, shutil, hashlib

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PREVIOUS=HERE.parent/'2026-10-06-primitives-tutorial-lineage'
GRID=HERE.parent/'2026-10-06-trace-saved-to-grid'
HALLS=['Point_Line_Grid','Point_Triangle_Context','Primitives_Ignorance','Primitives_Godot','Primitives_Profiles','Primitives_Portals','Primitives_Melencolia']

def put(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(s,encoding='utf-8')

def backup(p):
    destination=HERE/'before'/p.relative_to(ROOT)
    destination.parent.mkdir(parents=True,exist_ok=True)
    if not destination.exists():shutil.copyfile(p,destination)

def replace(p,before,after):
    text=p.read_text(encoding='utf-8')
    assert text.count(before)==1,(str(p),before[:80])
    backup(p);put(p,text.replace(before,after,1))

def tutorial(hall,before,after):
    replace(ROOT/'commons/maps'/hall/'tutorial.md',before,after)
    if hall!='Point_Line_Grid':replace(PREVIOUS/'write_lessons.py',before,after)

def final(hall,before,after):
    replace(ROOT/'commons/maps'/hall/'final.md',before,after)

for hall in HALLS:
    for name in ['tutorial.md','final.md','map_data.json']:backup(ROOT/'commons/maps'/hall/name)
for rel in ['doc/book/course/execution-plan/authorized-revisions.json','doc/book/course/hall-cards/lineage-opening.json','doc/book/course/hall-cards/final-summaries-opening.json','doc/book/course/storyboards/opening.json']:
    backup(ROOT/rel)
for p in [PREVIOUS/'verification.json',PREVIOUS/'publish.py',PREVIOUS/'write_lessons.py',GRID/'publish.py',GRID/'build.py']:
    backup(p)
for folder in [*[(PREVIOUS/h) for h in HALLS if h!='Point_Line_Grid'],GRID/'trace',GRID/'grid']:
    for name in ['report-runtime.json','ghost-report.json','contract.json','next-input.json','tutorial.md']:
        p=folder/name
        if p.exists():backup(p)

tutorial('Point_Line_Grid','- Source positions and grid addresses','- One record, different representations\n- Source positions and grid addresses')
tutorial('Point_Line_Grid',
 'The pink sculpture is your saved work: the same retained positions and the same segment geometry. We do not build another point or ask for another gesture. Its data gives us a second question: what changes when those positions receive grid addresses?',
 'The pink sculpture is your saved work: the same retained positions and the same segment geometry. We do not build another point or ask for another gesture. **One record can support different representations.** Here we derive grid addresses from it and change a separate green copy.\n\nTrace stored selected samples of movement, not the whole continuous gesture. Its ordered array, visible segments and rounded addresses each let us do different work. Keeping the source means another interpretation can begin without pretending that rounding recovered everything the hand did.')
final('Point_Line_Grid',
 "Pink gives the drawing another centre and size. Green rounds those displayed positions onto a new grid. The panel still lists the original positions: the program can give a record another appearance without rewriting what it received.[^point-grid-replay]",
 "Pink gives the drawing another centre and size. Green rounds those displayed positions onto a new grid. The panel still lists the original positions: the program can give a record another appearance without rewriting what it received.[^point-grid-replay]\n\nBoth versions came from your hand; neither contains the whole movement. One bend has become several things we can return to. Keeping them beside one another lets us see what the new rule changed, and leaves the earlier record available for a use we have not chosen yet.")

tutorial('Point_Triangle_Context',
 'The saved record still uses the drawing station\'s local metres. Grid\'s rounded copy did not replace it. This lesson reads the original archive and creates three temporary PointBody handles at selected entries. It does not save their later edits back to the drawing.',
 'The saved record still uses the drawing station\'s local metres. Grid\'s rounded copy did not replace it. This lesson reads the original archive and creates three temporary PointBody handles at selected entries. It does not save their later edits back to the drawing.\n\nLines already connected two positions. The new step is to store a connection as a recipe that refers to entries in a position list. Three Vector3 values alone do not instruct Godot to draw a face. We choose which entries belong together and in which order; the same stored position can later belong to several faces.')
final('Point_Triangle_Context',
 'A boundary and a face have arrived through different actions. Connecting three points closes a loop. Asking the renderer to make a triangle gives it a surface to show. The positions do not contain that instruction. We added it.',
 'A boundary and a face have arrived through different actions. Connecting these three points closes a loop. Asking the renderer to make a triangle gives it a surface to show. We have chosen that these corners belong together, in this order. Their positions did not make that commitment for us.')

tutorial('Primitives_Ignorance',
 'You already have arrays, loops and a face renderer. The new step is to give a repeated construction a name and an input. We supply the eight face triples so that the lesson stays with generating positions.',
 'In Cube, you wrote the corner positions into a list. Here you write a rule that returns a list for each radius you give it. Arrays, loops and the face renderer return; a named function makes their work reusable. We supply the eight face triples so that the lesson stays with generating positions.\n\nYou can still work out every coordinate. What changes is where you make the decision: choose the rule and its input, then inspect the positions they produce. Later generators can produce more than you would want to place one point at a time.')
final('Primitives_Ignorance',
 'The vertices remain finite and countable. We can still inspect or move them individually. What changes is the scale at which we choose to work: a hand places a corner; a rule places a family of corners in relation. Increasing the count lets the same rule do more work without asking us to make every placement again. Its regularity comes with that power. Which differences can we make through the rule, and which require us to return to a particular point?',
 'The vertices remain finite and countable. A hand places a corner; a rule places a family of corners in relation. We choose a procedure, let it make the placements, then return to what appeared. Knowing the rule gives us another way to know the form, while its particular surface still asks to be looked at. Which differences can we make through the rule, and which require us to return to a particular point?')

old_subjects=['Extending PointBody','A mesh resource and its parameters','Held and released states','Elapsed-time steps and lower bounds']
new_subjects=['Resolution as a construction parameter','Rings and radial segments','Visible construction and collision','Independent mesh resources']
p=ROOT/'commons/maps/Primitives_Godot/tutorial.md'
replace(p,'\n'.join('- '+s for s in old_subjects),'\n'.join('- '+s for s in new_subjects))
replace(PREVIOUS/'write_lessons.py',repr(old_subjects).replace(', ',','),repr(new_subjects).replace(', ',','))
tutorial('Primitives_Godot',
 'The museum\'s primitive library shows other engine shapes. Our tutorial stays with one familiar body, gaining a new behaviour. This is the object that can acquire further abilities in later sequences.',
 'The lesson is **resolution as a parameter of construction**: the same named sphere can have several finite meshes. Change rings while keeping radial segments fixed, then reverse that comparison. Keep radius and the spherical collider unchanged.\n\nPickup returns from Coordinates. PointBody and the class extension return from earlier lessons; the short held-time controller is supplied support for this comparison. Its complete code and explanation remain below, but reconstructing the timer is not the new learning goal. The museum\'s wider primitive library is available to explore.')
tutorial('Primitives_Godot',
 'First hold only the left sphere. Then make a variant that decrements rings but leaves radial segments unchanged; make a second variant that changes only radial segments. Predict and compare the visible results. Release halfway through an interval, wait, and resume: the change should follow held time, not time spent looking at it.',
 'First hold only the left sphere. Make a variant that decrements rings but leaves radial segments unchanged; make a second variant that changes only radial segments. Predict and compare the visible results. Identify what stayed the same: radius, collider and the untouched neighbour.\n\nAs a separate check of the supplied controller, release halfway through an interval, wait, and resume. Its change should follow held time, not time spent looking at the sphere.')

tutorial('Primitives_Profiles',
 'Columns gave a generated cross-section a sequence of placements. Now the font supplies the cross-section, and we choose the placements. Font extraction, triangulation and boundary stitching are explicitly supplied work, not concepts you are expected to reconstruct in this lesson.',
 'The lesson is **a section carried along a route**. Return first to the familiar column: at each height, its radius list chose the size of a ring. Imagine keeping those rings the same size and placing them along a straight route. Now substitute the supplied O outline for the ring. The section tells us what is carried; the route tells us where it goes.\n\nStart with the same O and width throughout. Change only the sideways travel, OFFSET. The font record, placement formula and surface builder are supplied support. Font extraction, triangulation, holes and general path orientation are not additional tasks to solve here.')
tutorial('Primitives_Profiles',
 'Set OFFSET to zero; then give it the opposite sign. Keep the O and WIDTH unchanged. Predict the direction of the passage and verify that the opening survives. Next try C and explain why an open contour changes what you would call the resulting space. Some glyphs have disconnected components; one character need not make one connected solid.',
 'Set OFFSET to zero; then give it the opposite sign. Keep the O, WIDTH and DEPTH unchanged. Predict the direction of travel and verify that the opening survives. Point to what belongs to the unchanged section and what came from its route.\n\nOnce that distinction is clear, try C with the same route. Its gap connects the hollow to the outside; the material outline itself still has a closed boundary. Some glyphs have disconnected components, so one character need not make one connected solid.')

tutorial('Primitives_Portals',
 'This does not calculate every digit of pi or prove a limit. Both the circle reference and the sampled coordinates use finite precision. It makes the choice of an adequate approximation inspectable.',
 'This does not calculate every digit of pi or prove a limit. Both the circle reference and the sampled coordinates use finite precision. It makes the choice of an adequate approximation inspectable.\n\nThe circle sampler returns from Columns. Its sine and cosine calls are printed support; deriving them is a later investigation. Here, use the sampled positions to choose and test a stopping rule. You can understand the condition for stopping before explaining every operation that supplied the points.')

capstone='''## After the chapter: an arrangement without a recipe

Choose a different arrangement in a clear part of your working museum hall. Use the earlier files as references, but write your own small main script. This is an independent challenge; there is no new construction hidden in a supplied answer.

- Generate a list of at least five positions with a rule you can explain. Keep an unchanged source list and modify an independently owned copy.
- Reuse PointBody and FaceBody. Choose three non-collinear entries from the list and connect them as a face.
- Show two spheres of equal radius with different resolutions, using the construction already studied in Godot Primitives.
- Decide their spacing and arrangement. Keep the known collider behaviour; making a new walkable structure is outside this task.

Show the arrangement to someone who has not seen your script. Locate the stored values, the variable referring to each body, and the indices establishing the face. Explain what the generator decided, what resolution changed, what you preserved, and one aesthetic choice that no calculation required.

Run your script and check that changing the copy leaves the source intact, that the selected face has area, and that each sphere keeps its own mesh. Then change one choice and predict the result before running again. Successful execution is evidence about the program; explaining and transferring the choices gives evidence about what you learned.

'''
tutorial('Primitives_Melencolia',
 'Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.',
 capstone+'Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.')
final('Primitives_Melencolia',
 'Imagine one cube placed outside the cross. Its construction would be unchanged; its relation to the court would be different. You do not need to build every possibility before leaving this one.',
 'Imagine one cube placed outside the cross. Its construction would be unchanged; its relation to the court would be different. What you know now gives you several ways to make it. None chooses its place for you. You do not need to build every possibility before leaving this one.')

integrity={}
for hall in HALLS:
    current=ROOT/'commons/maps'/hall/'tutorial.md'
    old=(HERE/'before'/current.relative_to(ROOT)).read_text(encoding='utf-8')
    new=current.read_text(encoding='utf-8')
    blocks=lambda s:re.findall(r'```[^\n]*\n[\s\S]*?^```',s,re.M)
    assert blocks(old)==blocks(new),hall
    integrity[hall]={'printed_code_unchanged':True,'blocks':len(blocks(new)),'tutorial_sha256':hashlib.sha256(current.read_bytes()).hexdigest()}
    target=GRID/'grid/tutorial.md' if hall=='Point_Line_Grid' else PREVIOUS/hall/'tutorial.md'
    shutil.copyfile(current,target)
    assert (ROOT/'commons/maps'/hall/'map_data.json').read_bytes()==(HERE/'before/commons/maps'/hall/'map_data.json').read_bytes()
put(HERE/'prose-integrity.json',json.dumps(integrity,indent=2)+'\n')
print('Edited seven tutorials and four reflective texts; all printed executable code unchanged.')
