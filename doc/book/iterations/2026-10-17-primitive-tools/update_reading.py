from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
MAPS=ROOT/'commons/maps'
def read(p):return p.read_text(encoding='utf-8-sig')
def write(p,t):p.write_text(t.strip()+'\n',encoding='utf-8')
def replace(p,a,b):
 t=read(p)
 assert a in t,(p,a[:80])
 write(p,t.replace(a,b))

p=MAPS/'Point_Trace/final.md'
old=read(p)
notes='\n\n'.join(line for line in old.splitlines() if line.startswith(('[^point-trace-sampling]:','[^point-trace-quantisation]:','[^point-trace-carry]:')))
notes=notes.replace('A drawing pen must','A spatial bead must').replace("The whiteboard's image","The glass wall's image")
write(p,'''# Duration and Residue

Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.

A segment keeps two ends and a rule for joining them. Move either end and the between recomputes. It cannot tell us whether a hand stopped halfway, circled back, or hurried through. Those differences need somewhere to be recorded.

## A surface gives the pen somewhere to meet

<!-- @glass_paint_wall -->

A clear pane stands in a dark frame. Four pens and an eraser lie along its shelf. Through the empty surface, the rest of the room remains visible.

The pen meets the glass and a mark appears. Lift it, cross a little space, then touch down again. The hand travelled across the gap. The picture leaves it clear.

The drawing admits contacts close to the pane and inside its edges. Moving away ends the stroke; the next contact begins another. The glass gives this interruption a place we can understand with our hands. A pen has something to press towards, and a surface from which to lift.

Walking around the frame, we can see the mark from the other side. The line has changed its relation to the room behind it. Its place on the glass has stayed the same. The eraser clears the ink back to transparency.

Here the record is an image on a surface. A curved stroke can suggest depth while remaining on the pane. Further into the room, the coloured points ask what happens when the movement itself occupies depth.

## Hold the point

<!-- @draw_dot -->

Three small beads wait above their readouts. There is no barrel to orient and no nib searching for contact. Holding a bead and moving it leaves a line through open space. The recorder follows the bead's centre.

A loop can turn towards us, pass above the hand, and return on another level. Released, it stays available to walk around. The tool rests while the drawing occupies the room.

Beside each bead, a count sits above rows of coordinates. The list is the record:

```gdscript
var point_count = _trail_points.size()
```

Each retained position has three coordinates. The program connects it to the next with a straight segment. A curve is assembled from these small connections; between two retained positions, the hand may have taken another way.[^point-trace-sampling]

Holding still need not add a row. The recorder waits for at least five millimetres of movement before considering another position. A long pause can leave the same list as a brief one. Time passed through the gesture without acquiring a place in this record.

## Give the same bend another grain

The pink, green and violet beads use ten-, forty- and eighty-millimetre grids. Each accepted position is rounded to the nearest address on its grid. Several small movements can arrive at the same saved address. The recorder omits immediately repeated addresses; returning after another position can still make a new entry.[^point-trace-quantisation]

A small bend may survive in the pink trace and flatten in the violet one. Repeating the gesture with another hand movement changes two things at once: the recorder and the gesture. The sampling monitor follows one held movement before the bead's rounding, then compares several spacings applied to its own record. The hand does not have to repeat itself exactly.

The grain can also help a drawing. There is room to wander while an address holds, then a threshold across which the line gains a corner. A spacing that hides a flourish can make a return easier to recognise. The instrument offers both losses and possibilities; we need a particular drawing to judge them.

The lines joining the positions may cross the lattice diagonally. Rounding the corners does not require the path between them to follow the grid's edges. Sampling decides what enters the list. Joining decides what appears between its entries.

## After the hand lets go

<!-- @trace_ball_ramp -->

Beyond the bead stations, a black ball rests above a sloping plank. Released near the top, it continues down. A thin black line stays behind it.

The point has acquired weight. The hand chose a release; gravity, slope and contact carry the movement further. The recorder follows the ball's centre, so its path hangs a radius above the surface on which it rolls.

We can walk alongside the line while the ball settles in the tray. The slope has entered the drawing. Moving the ball back and releasing it elsewhere begins another trace. How much of the drawing was made in the choice of where to let go?

The three encounters have given movement different terms of admission. Contact leaves ink on glass. Holding a bead keeps positions through space. Releasing a ball lets a physical calculation continue the path. A line alone would not tell us which of these happened.

## Carry a bend

<!-- @ -->

Returning to a bead, we can leave a drawing for the next hall. Releasing it sends a copy of its retained positions to the running game's archive. At least two positions are needed. The image on the glass and the ball's path remain here.[^point-trace-carry]

This copy preserves the positions exactly. It does not preserve how long the hand paused or how the movement felt. The session archive survives the change of hall; it is not a disk save for a later launch.

The next room can give those positions another centre and size. A bend made at arm's length may become something we approach with the whole body. The movement has passed, but its record has acquired a use that was not settled when it was made.

In the next room, look for the bend. It may have grown.

'''+notes)

replace(MAPS/'Point_Trace/tutorial.md',
 'The Trace hall offers pens and a ball whose movement leaves a line. Our small program follows the centre of the same pickable point we have already built.',
 'The Trace hall begins with pens meeting a transparent glass surface. Farther on, held beads leave spatial traces, followed by a ball released down a ramp. Our small program follows the centre of the same pickable point we have already built.')
with (MAPS/'Point_Trace/tutorial.md').open('a',encoding='utf-8') as f:f.write('''
## Compare with the installed encounter

The glass pen records contact on a plane. The spatial bead records its centre while held; it does not snap to the nearby glass. Make a loop, pause, move out of its plane, and release. Inspect which positions were kept and which segments were inferred between them. Repeat at a coarser spacing, then use the sampling monitor to compare several spacings applied to the same retained gesture.

The museum's beads publish to the in-memory `TraceData` archive when released. Grid reads that copy during the same running session. This lesson's `TraceArchive` is a separate, deliberately small implementation: it saves `user://ada_student_trace.scn` and can reload it after a restart. Do not assume that the museum's glass image or ball path is included in either transfer.

For independent reconstruction, build the lesson's point, position list and adjacent segments first. Verify that a stationary pause adds no segment and that a saved trace reloads with the same positions. Only then add a grid spacing or a surface-contact condition. Each should change one recording rule that can be observed.
''')

p=MAPS/'Point_Line_Grid/final.md'
t=read(p)
anchor='Pink gives the drawing another centre and size. Green rounds those displayed positions onto a new grid. The panel still lists the original positions: the program can give a record another appearance without rewriting what it received.[^point-grid-replay]'
assert anchor in t
t=t.replace(anchor,anchor+'''

Select a row on the panel. Its number appears beside the corresponding pink point, with a green marker at the address to which it snaps. The short connection between them gives the displacement a visible length. POINT − and POINT + let us follow neighbouring entries; selecting a visible point brings its row into view.

Two rows may lead to the same green address. Their numbers remain different. The record knows which visit we selected even where the grid gives both visits one place. Turning a page leaves that selection intact; NEXT TRACE moves to another retained drawing.
''')
t=t.replace('drawing pens','spatial beads').replace('coloured pens','coloured beads')
write(p,t)
with (MAPS/'Point_Line_Grid/tutorial.md').open('a',encoding='utf-8') as f:f.write('''
## Follow one source entry through the two representations

In the installed hall, select a coordinate row or a visible point on the pink trace. Its numbered pink marker and green snapped marker identify the same source entry. POINT − / POINT + advances that entry; the page controls only change which rows are shown. NEXT TRACE changes the retained drawing. These controls use the museum's session archive; the small program above uses the student's saved scene file.

To reconstruct this correspondence, store a selected integer index into the original position list. Read that entry for the pink marker and apply the same rounding function used by the green copy for its second marker. Apply each display's placement after calculating its coordinates. Keep the index even if two different entries round to the same address; looking up an entry by its rounded position would lose that distinction.

Check with two nearby source positions that round to one cell, and with a path that revisits an earlier position. Selecting either entry must keep its own row identity. A page turn must not silently select a different point. This is an extension to build after the saved drawing and its green copy work.
''')

p=MAPS/'Point_Animatedcube/final.md';t=read(p);end=t.index('<!-- @polyhedron_nets_cube -->')
write(p,'''# Cube Assembly from Primitives

We have been inside boxes since the first room. Now two wait together on a low table. Their corners occupy the same positions within each form. Across one front face, the amber diagonals run in opposite directions.

<!-- @paired_cube_diagonals -->

At first both faces are flat. Nothing needs to fold along either line. Holding the pink corner on A, we move it a little out of the face's plane. The corresponding corner on B follows by the same amount. The remaining corners stay fixed.

The surfaces no longer agree.

On A, one triangular patch can stay flat while its neighbour tilts. On B, the two patches meet along a diagonal that reaches the moving corner. The same changed positions have produced different surfaces. A choice that seemed incidental when the square was flat has become visible as a crease.[^animatedcube-triangulation]

The difference lives in two short lists. A uses:

```text
[4, 5, 7]   [5, 6, 7]
```

B uses:

```text
[4, 5, 6]   [4, 6, 7]
```

The numbers name corners. Each triple tells the renderer which three positions make a triangle. A's patches share the edge from five to seven; B's share four to six. The diagonal is a relation between entries, not another point hidden inside the square.

We can move around the table and look along each face. The colour difference between its patches helps locate the fold, but the surface itself has changed. Both forms retain eight corners and the same outer edge connections. Equal lengths, right angles and flat faces need not survive the movement.[^animatedcube-boundary]

RESTORE returns both sets of corners to their beginning. The disagreement disappears into two flat squares. Moving the same corner again brings it back. This is a small experiment: one displacement, two choices of triangulation, a consequence we can inspect from more than one side.

REPLAY reveals the corners, edges and patches in sequence around the current positions. It keeps a deformation we have made. Restoration and repetition therefore begin again in different senses. The source geometry already exists before the reveal; the animation stages when its pieces become visible.

FREE / ONE opens the remaining handles on A. B continues to follow its positions. This admits other forms, including crossings and collapsed triangles. The connections can stay valid as lists while the resulting object becomes difficult to call a solid. A retained recipe does not guarantee a good geometric embedding.

<!-- @cube_lines -->

The outline cube and the diagonal plate remain nearby as optional comparisons. With no filled faces, a few edges are enough for us to recognise the box. With the plate, we can inspect one triangle pair without the other sides obscuring it. These are different amounts of evidence for something familiar.

<!-- @cube_diagonal_plate -->

The paired experiment has made a corner movement consequential. Beyond the opening, the folding net offers another way for a flat arrangement to become a box. This time the square faces keep their shapes.

'''+t[end:])
replace(MAPS/'Point_Animatedcube/final.md','In the builder, you moved a corner and bent a square into two differently tilted triangles.','At the paired cubes, the same corner movement bent the front faces along different diagonals.')
replace(MAPS/'Point_Animatedcube/tutorial.md',
 'Build one cube, then a second with the other diagonal on its front side.',
 'The installed pair moves corresponding corners together while retaining opposite front diagonals. Build one cube, then a second with the other diagonal on its front side.')
with (MAPS/'Point_Animatedcube/tutorial.md').open('a',encoding='utf-8') as f:f.write('''
## Reconstruct the controlled comparison

Begin with the two unchanged cubes above. Move local entry `points[6]` forward by the same 0.25 metres on **both** instances, then call `show_faces(points, faces)` on each. Keep the other seven entries unchanged. The cube with diagonal 5–7 leaves that diagonal at its original depth; diagonal 4–6 has one displaced end. At the projected centre of the original front square, the two surfaces now differ in depth by 0.125 metres.

Return both arrays to their original positions and redraw. The front faces should become flat again. This reproduces the museum's first comparison without its pickup and presentation systems. Its REPLAY control only reveals the current construction; RESTORE resets the positions. FREE / ONE permits additional corner changes, after the one-corner comparison has a baseline.
''')

p=MAPS/'Primitives_Melencolia/final.md';t=read(p)
start=t.index('Follow the raised connection');end=t.index('The stone has six pentagonal faces')
t=t[:start]+'''Follow the raised connection to the next platform. The large stone stands to the left. On the right, a small skull rests on a block. The sleeping dog, sphere, ladder, scales, hourglass and scattered tools remain around it. A smaller winged figure still bends over its tablet.[^durer]

This is an Ada variation on the engraving. The skull takes the place of the main seated figure; it is our substitution, not a claim about what Dürer drew. The short label marks that change.

The skull has openings where a face would have looked back. Beside the smooth sphere and cut stone, its hollows give us another kind of form to follow. The geometric objects have kept their definitions. Their company has changed.

We might call the wish carried from the court *geometric desire*: that a form could let us see further, or give us somewhere else to stand. Here the tools remain while the body that held them has been replaced by an object. A correct construction can outlast a particular use. It does not choose the next one.

Walk sideways. The stone conceals the smaller figure, then allows it to appear again. Our arrangement gives depth to an engraving; its hidden surfaces were not supplied by the printed image. They are decisions in this model. The skull makes one of those decisions explicit enough to contest.

![The current Ada variation: a skull on the right, the stone, smaller figure and tools retained.](/book-review/doc/book/iterations/2026-10-17-primitive-tools/native/Primitives_Melencolia/tableau.png)

*The installed variation. The main seated figure has been replaced; the smaller figure and surrounding instruments remain. The depth and substitution belong to Ada's interpretation.*

'''+t[end:]
t=t.replace('Keep that question beside the seated figure.','Keep that question beside the skull and the tools.')
t=t.replace('Two things are true at once here, and the room will not choose between them, because she did not.','Two questions remain together: what our constructions can do, and why we want to stay with them after their construction is understood.')
t=t.replace('this chapter ends inside it, sitting down, tools in hand.','this chapter ends among its tools, with their next use still unsettled.')
t=t.replace("AdaResearch follows the principal objects and their image relationships in a stylised sculptural arrangement.","AdaResearch adapts the principal objects and their image relationships in a stylised sculptural arrangement. The current variation replaces the main seated figure with a skull; this substitution is not in the source engraving.")
write(p,t)
replace(MAPS/'Primitives_Melencolia/tutorial.md',
 "Dürer's objects gather in the museum's Melencolia hall.",
 "The museum's Melencolia hall adapts Dürer's objects and now substitutes a skull for the main seated figure. The smaller winged figure, tools and solids remain. This is a labelled Ada variation, rather than an exact reconstruction of the engraving.")

write(MAPS/'Point_Trace/summary.md','''# Point Trace — a surface, a point, a release

The room now has a 24 × 24-cell floor with an open central route. Entry is at (12,0), exit at (12,23). Source coordinates name cells, not measurements of visitor reach.

1. Pens meet a transparent glass wall at (7,5). Contact paints; lifting breaks the stroke. Marks are visible from both sides; the eraser restores transparency.
2. Three held beads at (4,11), (6,11), (8,11) leave spatial traces at 10/40/80 mm resolution. They follow their centres and ignore nearby drawing planes. The sampling monitor at (2,10) compares different spacings on the retained gesture.
3. The ball ramp at (18,14) lets a released point continue under physics. Its local trace stays in this hall.
4. Telemetry, the science screen and the trace film occupy the rear. The spatial beads' released position lists travel through the session archive to Point_Line_Grid.

Pens belong on the glass; a held point gives the spatial trace its tool. Both are retained. There is no short-memory amber dot, writing desk or head-projection study placed in this version. Those studies remain available in source/history.

The records are sampled positions or a painted image, not the entire gesture. The museum archive is in memory; the tutorial's independent archive adds a disk save. Their persistence must not be conflated.
''')
write(MAPS/'Point_Animatedcube/summary.md','''# Point Animatedcube — same corners, different surfaces

The 27 × 36-cell room begins with one paired instrument at (13,6), facing the entrance. Both cubes share their corner changes; their front faces retain opposite diagonals. Initially only A's pink corner can be moved. RESTORE resets positions, REPLAY reveals the current geometry, and FREE / ONE permits other A corners to move. B follows.

The main sequence is paired cubes → folding net at (13,16) → prefab library at (5,24) → conveyor at (20,25). A broad opening at row 11 connects the first comparison to the working room. Entry (13,0), exit (13,35).

The outline, diagonal plate, corner film, shadow, phosphor, crates, glove box, sphere field and pyramid family remain optional encounters. Their questions need not all become prerequisites for the main experiment. All original artifact types remain except the two independently controlled builders, which are replaced by the linked pair.

Moving corner 6 forward by 0.25 m on both cubes leaves the same corner arrays but a 0.125 m difference between front-surface depths at the original square's projected centre. This supplied check validates the geometry; a visitor's ability to discover and describe that difference still needs a headset encounter.
''')
replace(MAPS/'Primitives_Melencolia/summary.md','stone left, seated figure right, child and dog between','stone left, skull on a block at right, smaller figure and dog between')
replace(MAPS/'Primitives_Melencolia/summary.md','Its invented depth can be inspected by walking around it.','The skull is a labelled Ada substitution for the main seated figure. Its invented depth can be inspected by walking around it.')

# Replace stale inventories with the exact authored placements; no global regeneration.
registry={}
for file in (ROOT/'commons/artifacts/registry').glob('*.json'):
 try:
  data=json.loads(read(file)).get('artifacts',{})
  if isinstance(data,dict):registry.update(data)
 except (ValueError,AttributeError):pass
for name in ['Point_Trace','Point_Line_Grid','Point_Animatedcube','Primitives_Melencolia']:
 d=json.loads(read(MAPS/name/'map_data.json'));rows=[]
 for z,row in enumerate(d['layers']['interactables']):
  for x,token in enumerate(row):
   if not str(token).strip():continue
   key=re.split('[:#]',token)[0];meta=registry.get(key,{})
   rows.append(f'| ({x}, {z}) | {meta.get("name",key)} | `{token}` |')
 write(MAPS/name/'artifacts.md',f'# {name} — installed artifacts\n\nUpdated 17 October 2026 from this map’s authored placements. These are source cells; room and final encounter order is described in summary.md.\n\n| Cell | Artifact | Placement |\n| --- | --- | --- |\n'+'\n'.join(rows))
print('Updated four readings, tutorial extensions and scoped inventories.')
