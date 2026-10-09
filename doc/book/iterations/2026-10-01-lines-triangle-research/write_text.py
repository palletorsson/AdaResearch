from pathlib import Path
import re, json, difflib

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Point_Triangle_Context'
original=(OUT/'before/commons/maps/Point_Triangle_Context/final.md').read_text(encoding='utf-8')
notes='\n'.join(line for line in original.splitlines() if line.startswith('[^'))
main='''# Closing a boundary, adding a face

Three edges meet. You can still see the room between them.

<!-- @triangle_line_puzzle -->

Bring the loose lines to the three waiting corners. Fit the last edge and look through the triangle. Closing it has not covered anything.

Press **SHOW / HIDE FILL**. A translucent patch appears between the same corners. Press again. The edges stay; the patch goes.

A boundary and a face have arrived through different actions. Connecting three points closes a loop. Asking the renderer to make a triangle gives it a surface to show. The positions do not contain that instruction. We added it.

<!-- @triangle_construction_plate -->

The wall plate holds the distinction still: three points, three connected edges, a face.

![The same three corners shown as points, a connected boundary and a filled triangle.](/book-review/doc/book/figures/Point_Triangle_Context/triangle-construction.png)

We built this plate while writing the chapter. The book needed an image; the room gained another object to approach. This illustration is a Godot view of that same construction. A sentence can ask for something to try, and making it can change the sentence.

<!-- @draw_triangle_faces -->

At the small drawing station, a triangle waits with black corners and an off-white face. If you released a drawing in Trace, your own bend waits here instead, still open. Its journey has changed it: six positions kept, its span reduced to arm's reach, its height flattened. The machine has prepared your drawing for a method that expects a plane. What did that preparation leave behind?[^point-triangle-carry]

Move the drawing point near the first corner to close that carried loop. For the simpler comparison, **RESTORE TRIANGLE** replaces the current drawing with three editable corners.

<!-- @triangle_live_twin -->

Look up. The small drawing has a twin in the middle of the hall. Move a corner and watch the same change arrive more than three times larger. Your hand can reach the small figure; your body can walk around the other.

Leave the corners where they are. Walk towards the side of the large face. Its breadth narrows until the black edges almost meet in your view. Step back and the surface opens again. You have changed where you look from, without moving a single corner.[^point-triangle-winding]

Now return to the small drawing. Bring its upper corner down onto the line between the other two and release it. The large figure flattens too. This time walking around cannot recover the missing area. Three positions remain, but they lie along one line. Lift the corner away and a face opens between them again.

From one view, these two events can look alike. In one, the face waits for another viewpoint. In the other, we must change what we made.

<!-- @draw_triangle_faces -->

Press **SHOW / HIDE FILL** while the triangle is open in your view. Both copies lose their faces together; the corners and edges remain. Hiding a surface has left its geometry available for a return. The large fill also lets you walk through it while it is visible. What covers your view need not stop your body.

We have been calling all of these a triangle. A boundary, a rendered face, a figure seen edge-on, three corners with no area: keeping their differences lets us do more with the name.

The tool will accept longer outlines too. Draw a six-corner L, close it, then release the handles and press **SHIFT START**. The corners stay where they were. The fill can reach across the notch you left open.[^point-triangle-construction]

Every triangle in this method shares the first corner. Choosing another beginning changes the fan. Its rule has kept working while failing to keep your intended interior. The counter still reports four triangles; counting them does not tell us whether they belong there.

We can choose a suitable start, ask for a different filling method, or keep the unexpected wing as the beginning of another work.[^point-triangle-triangulation] The mistake needs an explanation, but its explanation need not decide what we want from it.

<!-- @quad_line_puzzle -->

At the far end, four edges offer another empty boundary.

<!-- @quad -->

Nearby, the quad adds two triangular faces along a diagonal. Lift a corner away from that diagonal: one face follows while the other stays. Move an end of the shared edge and both change. A shape that looked like one square has given us two surfaces that can tilt apart.

Next, faces meet at a corner. What must we add to enclose a volume?
'''
(MAP/'final.md').write_text(main+'\n'+notes+'\n',encoding='utf-8')

(MAP/'intent.md').write_text('''Concept: A closed boundary, a visible face, its projection and its collision are separate operations. Begin with an encounter, then change one condition.

Sequence: Grid supplies repeatable addresses; this hall adds a face; Polyhedra asks for enclosure.

Primary route: triangle_line_puzzle → construction plate → draw_triangle_faces with triangle_live_twin → quad boundary and split quad. The first closure is presented as ringed lines facing the approach. The creator and its controls face the arriving visitor. Eight placements remain in the 13 × 30 hall. Folded strip and pink triangle remain as return visits; nine other placements are parked with their exact tokens in the dated research bundle.

First investigation: Hold the three corners fixed and walk towards an edge-on view. Then hold the viewpoint fixed and move the third corner onto the baseline. Distinguish projected disappearance from loss of area. The reference corners now obey the editor's own world snap grid; RESTORE TRIANGLE replaces the current drawing, guarded while the pen or a corner is held. A carried trace still arrives open; it is never automatically replaced.

Further investigation: A fixed six-corner L with a shifted starting index can produce an overspilling first-vertex fan. Retain this critical comparison as a return, with the recipe in the tutorial/technical companion. We have not added a different triangulator or an entropy measure.

Writing: The main chapter follows changes one can see and try. Setup recipes and full fan construction belong beside it. The same triangle can have different appearances without becoming a different stored object; a counted face can also have zero area.

Research record: doc/book/iterations/2026-10-01-lines-triangle-research/index.html. Native matched-camera images, supplied-hand pickup/release and capsule route checks. Physical headset reach and learner comprehension remain untested. Baseline placement and text files are preserved there.
''',encoding='utf-8')

d=json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
roles={'triangle_line_puzzle':'Close edges; fill remains a separate action.','triangle_construction_plate':'The book and room share one points/boundary/face illustration.','draw_triangle_faces':'Edit the small drawing; compare filling and start order.','triangle_live_twin':'The same drawing enlarged; walk around or through its visual face.','quad':'Two triangular faces, one shared diagonal.','quad_line_puzzle':'Four connected edges without a face.','pink_triangle':'A historical sign whose meanings cannot be deduced from geometry.','folded_strip':'A return to shared edges and folding.'}
inventory=['# Triangle — current encounters','','Eight placements. Coordinates are zero-based source-grid (column, row).','','| Artifact | Position | Work |','| --- | --- | --- |']
for y,row in enumerate(d['layers']['interactables']):
 for x,t in enumerate(row):
  if not str(t).strip():continue
  key=t.split(':')[0].split('#')[0];inventory.append(f'| `{key}` | ({x}, {y}) | {roles[key]} |')
inventory+=['','The hall retains its 13 × 30 footprint. Widened openings give access to both sides of the central face. The former portal basin is continuous floor. Authored placements override old necklace stamps; the obsolete museum grid has been brought into agreement with the structure.','', 'Nine parked placements, their positions and reasons remain in [the research record](../../../doc/book/iterations/2026-10-01-lines-triangle-research/parked-placements.json). Their source artifacts are not deleted. The old inventory is preserved in the same bundle.']
(MAP/'artifacts.md').write_text('\n'.join(inventory)+'\n',encoding='utf-8')
(MAP/'summary.md').write_text('''# A boundary, a face, a view

Close three edges, add a visible face, then work on one drawing at two scales. Walk around the large triangle without moving its corners; return to the small version and bring the third point onto the other two. An edge-on view and a zero-area figure can resemble one another while requiring different actions to recover a face.

The eight-artifact hall makes this the first route. The fan's overspill, the folded strip and the pink triangle remain further investigations. At the exit, the empty quad boundary and two-face quad prepare for faces meeting in Polyhedra.

[Current placements](artifacts.md), [encounter](final.md), [making](tutorial.md), [source details](technical.md), [research and native images](../../../doc/book/iterations/2026-10-01-lines-triangle-research/index.html).
''',encoding='utf-8')

# Keep the detailed making route; insert the new comparison before its longer L exercise.
p=MAP/'tutorial.md';s=p.read_text(encoding='utf-8')
insert='''## A face, then a view of it

Begin with the small triangle and its large twin. Move one corner and release it; both copies retain that change. Walk towards the side of the large copy without touching the small one. Its projected width narrows while its three positions stay fixed.

Return to the small copy. Bring the top corner onto the line between the other two, then release. The starter corners use the same ten-centimetre world grid as your drop, so the baseline is reachable. A collinear triangle has zero area even though the tool still retains three points and counts one logical triangle. Move the corner away to recover a face. SHOW / HIDE FILL changes visibility without removing the points. RESTORE TRIANGLE replaces the current drawing with the starting three corners; release every held point or pen before using it.

These are three different changes: viewpoint, vertex position and visibility. Use one at a time before extending the outline below.

'''
s=s.replace('## Keep the outline, change its start',insert+'## Keep the outline, change its start')
p.write_text(s,encoding='utf-8')

# Existing detailed references remain readable as prior research, with explicit current status.
p=MAP/'technical.md';s=p.read_text(encoding='utf-8')
p.write_text('''> Current hall update — 1 October 2026. Eight placements; see [the current inventory](artifacts.md). The live twin now supplies RESTORE TRIANGLE, refuses reset during a held edit, and constructs reference points using the editor's world snapping function. Zero-area triangles retain their logical count and black boundary but submit no face in the large twin. The existing first-vertex fan, carried-outline path and SHIFT START remain. Earlier source analysis below predates this arrangement.

'''+s,encoding='utf-8')
p=MAP/'encounter-reference.md';s=p.read_text(encoding='utf-8')
p.write_text('''# Current research pass — 1 October 2026

The first route now distinguishes closure, fill, projected disappearance and actual loss of area. The shared drawing remains central. Eight placed encounters replace the earlier seventeen-placement arrangement; exact retired tokens and the earlier manuscripts remain in [the research bundle](../../../doc/book/iterations/2026-10-01-lines-triangle-research/index.html). The trials and limitations are recorded there. The fan comparison below is preserved as prior evidence and a further investigation, not a prerequisite for the first route.

---

'''+s,encoding='utf-8')
p=MAP/'detours.md';s=p.read_text(encoding='utf-8')
s=s.replace('The following works remain in the room.','The folded strip, quad, quad puzzle and pink triangle remain in the room. The other entries below document parked studies whose sources remain available; consult the current inventory before looking for them in the hall.')
p.write_text(s,encoding='utf-8')

print('Main text words',len(original.split()),'->',len((main+'\n'+notes).split()))
