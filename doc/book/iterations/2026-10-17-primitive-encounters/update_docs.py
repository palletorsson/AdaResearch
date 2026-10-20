from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
def original(name,file):return (HERE/f'before/commons/maps/{name}/{file}').read_text(encoding='utf-8-sig')
def save(name,file,text):(ROOT/f'commons/maps/{name}/{file}').write_text(text,encoding='utf-8')

old=original('Point_Lines','final.md')
measurement=old[old.index('<!-- @line_black_box -->'):old.index('Through the side passage:')]
body=old[old.index('<!-- @redline -->'):old.index('<!-- @anamorphic_cross -->')]
body=body.replace('Across the glass cover of a shallow basin, a black stripe: **WALK THIS LINE.** The glass supports your crossing.','Across the floor beyond the passage, a black stripe: **WALK THIS LINE.** There is room to follow it or step aside.')
body=body.replace('The earlier connection opened a barrier. This line opens nothing.','The earlier queue redirected our walking. This painted line changes no collision boundary.')
body=body.replace('The mark reaches the wall. It turns upwards and continues across the plaster. You can follow it with your eyes. Your next step meets the wall\'s collision boundary.','The mark climbs a solid column, crosses its top and comes down again. We can follow it with our eyes. Continuing along the floor means departing from the instruction and going around the column.')
end=old[old.index('<!-- @ -->'):]
opening='''# Lines, Networks, Measure

<!-- @pairing_point_field -->

Twelve small points wait at hand height. Bring one near another and release it. A line appears between them. Move either end away: the line follows. Other points remain available. A pair can become a chain, a branching arrangement, a shape whose next connection has not yet been chosen.

Two distinct positions determine a straight line; the visible segment keeps only the part between them. Here proximity initiates the connection. It does not require the endpoints to remain close. The hand has made a relation that outlasts the gesture.

No barrier falls when the points join. Making a segment and opening a passage would require two different instructions. For now we can attend to what this one instruction makes available: a connection whose length and direction can change.

The corridor opens. A black enclosure stands ahead, with space to walk around it and doorways through which to enter. Inside, one relation acquires a number.

'''
queue='''<!-- @do_not_cross_barrier -->

Beyond the black room, ten tape barriers form five alternating rows. **DO NOT CROSS** repeats while the path changes sides. The endpoints have become posts; the connecting line has a collision boundary underneath it. The nearest destination remains visible, but ordinary walking must take the longer route.

This arrangement resembles a check-in queue. Its turns do not measure our journey. They prescribe it. A line we could lengthen by moving one point has become a fixture that lengthens our own movement.

<!-- @anamorphic_cross -->

The queue delivers us to a narrow passage: **× + × + × +**. Crossing an X reduces health. There is no parallel walking route around this passage.

<!-- @health_cross -->

The following plus restores some health, breaking into a scatter of light. Hurt, recovery, hurt, recovery. Two crossed lines now address a variable in the moving body. The difference is not contained in their resemblance to familiar signs: the room has assigned each a different operation.

On the far side the space widens. The remaining line studies can be approached in several ways. After being directed, we have room to compare a painted instruction with a physical obstruction, a measure with a trace, a relation with the position from which it is seen.

'''
save('Point_Lines','final.md',opening+measurement+queue+body+end)

save('Primitives_Polythedra','final.md','''# A surface becomes something to stand on

<!-- @align_tetrahedron -->

The first solid is almost familiar. Three points keep a triangular base; a pink point pulls the remaining faces sideways. A small ring marks another possible position. We take the point, bring it to the ring, and release it.

The faces settle into a regular tetrahedron. Then the whole object falls.

Four triangular faces enclose a region, but enclosure alone did not cause that fall. The alignment completed a condition in the program. That condition created a rigid body, gave it a convex collision shape, and let gravity act. The surface we were adjusting has acquired another kind of consequence. It can now be lifted from the floor and turned in a hand.

The unfinished object was already tetrahedral in its connectivity: four non-coplanar positions joined by four triangular faces. The target restores particular proportions. It does not prove that every other tetrahedron is wrong. The ring names the construction this instrument accepts.

<!-- @align_wedge -->

In the next chamber, a wedge waits with one vertex displaced. There are six positions now. Two triangular ends are joined by three faces. Moving the loose corner changes the agreement between those faces; releasing it at the ring restores the triangular prism and gives this object gravity too.

We can compare the two objects in the hand. The tetrahedron closes with four triangles. The wedge extends a triangular profile along a length. They are both closed, yet their surfaces offer different ways to rest against the floor.

<!-- @corner_tetrahedron -->

Beyond the next doorway, the tetrahedron has grown into the corner of the room. Three of its edges follow the floor and the meeting walls. A fourth face cuts across the recess, pink against the surrounding surfaces.

From a distance it can look as though the corner has been removed. Approaching it reveals the opposite: a solid has been added. The old recess is occupied, and the walking body must turn sooner. The small construction has become part of the space in which another body moves.

<!-- @grab_trihedron -->

Nearby, an open trihedral model leaves one face undrawn. We can turn it and look through that opening. Its physics uses a convex hull of the same vertices, which closes across the missing face. Looking open and admitting another body remain different decisions. The boundary plate makes the otherwise invisible closing face visible.

<!-- @pyramid_edit -->

The movable apex offers a further comparison. Here a vertex remains available for adjustment. Changing one position turns several faces at once. In the first two encounters a prescribed alignment ended the construction; this one lets the alteration continue.

<!-- @wedge_palace -->

Ahead, two broad wedges approach the same raised platform from opposite sides. Their rise and run are equal. Each low edge meets the floor, and each upper edge meets the platform. We can take either approach.

The slope redirects forward movement upwards. Nothing has been added to the meaning of a triangle, but the size, orientation and collision surface have made its inclined face capable of supporting this body. The geometry once held in a hand is now beneath our feet.

At the top the view changes. The other approach remains visible across the platform, and a third wedge descends on the far side. The route supplies a comparison: up from either side, across, then down towards the enclosure beyond. A seam that catches a foot would matter as much as a correctly calculated slope. This construction has to work at its joins.

<!-- @concrete_barrier -->

Striped barriers surround the next basin. Their wedge-like profiles extend along its edges. The floor continues inside the enclosure; it is not an opening into empty space. A small chain of diamond forms occupies its centre.

The earlier incline offered an approach. These profiles delimit one. Related surfaces can carry us upwards or turn us away, depending on their orientation, scale and placement. Their use appears in relation to the body trying to pass.

<!-- @rock_spawner -->

A doorway to the side leads to the rock enclosure. Thirty generated rocks fall within its walls. Their positions settle through contact; gaps remain between their irregular surfaces. The box has its own floor and an approach outside the retaining walls.

<!-- @rock_scanner -->

Nearby, a cyan plane moves up and down. It marks a changing height; this version does not yet draw the corresponding cross-section on a screen. That distinction leaves another construction to make: how could a record of what meets this plane describe the pile differently from its outside surface?

Returning to the main hall, the platform still has two approaches. The corner still redirects the walk. The solids were introduced as constructions to complete, but they have become decisions about access, support and passage. The next map takes up the cube; this room stays with the tetrahedron and wedge long enough for their differences to be used.
''')

t=original('Point_Triangle_Context','final.md')
t=t.replace('Next, faces meet at a corner. What must we add to enclose a volume?','''<!-- @triangle_assembly_table -->

At the last table, twelve small triangular pieces lie flat in two rows. We can lift a face, turn it, and leave it beside another. These pieces stay where released. A pyramid can be assembled without pretending that its loose faces would stand there under gravity.

An edge can be shared by two faces without both remaining flat. Leaving one side open gives a view into what the assembly is beginning to enclose. Another arrangement may remain a canopy or a broken surface. There is no required final shape on this table.

Next, a completed solid will fall. What changes when this arrangement acquires a physical body?''')
save('Point_Triangle_Context','final.md',t)

additions={
'Point_One':'''## Current room comparison — 17 October 2026

The second and third points have no small podiums. Their centres and visible radii agree. Walk through the visible-only point, then approach the solid point along the same line. Only the third sphere has a collision shape. The empty first marker and the large final pedestal remain. Do not infer point collision from a supporting plinth.
''',
'Point_Lines':'''## Current room extension — 17 October 2026

The opening is now `pairing_point_field`: twelve 4.5 cm-radius points sharing one local SnapConnectionManager. Release a point within 28 cm of another to create a segment. Moving either endpoint updates the segment; other points remain available for further connections. The field has no connection to barrier destruction.

Reconstruct the relation before adding consequences: two positions, one rendered segment, a proximity test on release. Then add a third point and compare a chain with a closed triangle. The production manager can recognise closed shapes; that is an extension beyond drawing the first segment.

The black measurement enclosure follows in a larger room. Ten tape barriers then direct walking through the ×/+ passage. Other examples follow it. Distinguish a drawn segment, a collision boundary and a health-changing area: none follows automatically from the others.

Implementation: `commons/artifacts/primitive_encounters/pairing_field.gd` and `corridor_point.gd`. Desktop right-click picks up/releases; VR uses the existing XR pickup driver. The underlying graph and rendering remain in `commons/primitives/snappoint/`.
''',
'Point_Triangle_Context':'''## Assembly extension — 17 October 2026

The final table supplies twelve thin triangular prisms with 46 cm edges. Their thickness and convex pickup volumes make them manipulable; the mathematical triangle still has no thickness. Grip and turn them in VR. On desktop, right-click carries/releases, Q/E rolls and R/F tilts the held piece in 15-degree steps.

Pieces remain frozen where released. Compare four faces arranged as a tetrahedral pyramid with an open arrangement using the same stock. This is a construction model, not evidence that unsupported faces would remain stable under gravity. No target shape is enforced.

Build one triangular piece from the existing three positions, add a second parallel face 24 mm away, join the edges, then add a convex pickup volume. Duplicate only after one piece can be lifted, rotated and released. The installed example is `commons/artifacts/primitive_encounters/triangle_table.gd`.
''',
'Primitives_Polythedra':'''## From alignment to a physical body — 17 October 2026

The room now begins with `align_tetrahedron`, followed by `align_wedge`. Release the pink vertex within 12 cm of the ring. A distant release leaves the construction editable; a near release creates the completed rigid body and enables gravity. It can then be picked up and released again. Re-enter the hall for a fresh construction trial.

The tetrahedron already has tetrahedral connectivity before completion. The target restores the particular regular form authored here. For the wedge it restores the triangular prism. Acceptance tests a position, not every possible valid solid.

First reconstruct just the tetrahedron's four positions and faces, as below. Keep that surface separate from the interaction that accepts a target and the physics body created afterwards. The production implementation is `commons/artifacts/primitive_encounters/align_solid.gd`; `geometry.gd` supplies outward normals and matching convex geometry.

The later corner and platform change the scale of the question. Walk both symmetric slopes: each rises 0.9 m over 3 m. Check the low edge, the join to the platform, and the descent on the far side. The striped basin beyond has a solid floor. The rock box and scanner occupy a side room. Cube investigations begin in the next map.
'''}
for name,addition in additions.items():
 t=original(name,'tutorial.md')
 # Keep existing runnable lesson intact and distinguish its scope from room interaction.
 first,rest=t.split('\n',1)
 save(name,'tutorial.md',first+'\n\n'+addition+'\n'+rest.lstrip())

for name in additions:
 d=json.loads((ROOT/f'commons/maps/{name}/map_data.json').read_text(encoding='utf-8-sig'))
 text=f'# {name} — current artifact placements\n\nUpdated 17 October 2026. Coordinates are source map cells (x, z); the museum plan is derived from these same placements.\n\n| Cell | Artifact / configuration |\n| --- | --- |\n'
 for z,row in enumerate(d['layers']['interactables']):
  for x,c in enumerate(row):
   if str(c).strip():text+=f'| ({x}, {z}) | `{c}` |\n'
 save(name,'artifacts.md',text)
print('Current map prose, tutorial extensions and inventories reconciled.')
