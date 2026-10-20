from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
MAP=ROOT/'commons/maps/Primitives_Polythedra'
p=MAP/'final.md';s=p.read_text(encoding='utf-8')
start=s.index('At the top the two routes meet')
end=s.index('<!-- @concrete_barrier -->',start)
s=s[:start]+'''At the top the two routes meet on one level surface spanning the hall. There is room to cross between them. Something ahead repeats the profile that first made us turn away.

<!-- @wedge_column -->

Six of the standing prisms have been made smaller and turned onto their sides. Two triangular sections meet along their bases to make a diamond; three pairs rise into a column. The lavender faces widen and narrow again. A small sideways movement reveals their depth, and what seemed a continuous outline separates into joined surfaces.

The arrangement recalls Brâncuși through repetition and the passage between support and sculpture. Here the repeated unit is the hall's own prism. It was a barrier below; on the platform it gathers attention around its silhouette. Its surfaces remain solid. The work can still interrupt a route, even while the route gives us different views of it.

These joints are fixed in the program. The narrow contacts are a sculptural construction, not evidence that the column has found a physical balance. That distinction leaves a further experiment available: what supports would the same arrangement need if its pieces were released to gravity?

<!-- @wedge_mouse_model -->

Nearby, the room's question has become small enough to handle. A brown wedge has ears and a tail. It waits on a low plinth beside lavender obstacles, a little incline and a raised surface. Across a gap, a yellow wedge is marked as cheese.

The platform is made from two identical wedges. One is turned over against the other, bringing their sloping faces together and leaving a level face above. Another wedge keeps its slope exposed as the approach. The parts share one construction; their orientation decides which surface becomes available.

A small joystick lets us steer the mouse. Pushing towards a standing wedge meets an obstruction; turning aside finds another approach. At the incline the brown body rises onto the paired surface. JUMP sends it forward in the last steered direction, with gravity drawing the arc down towards the cheese. There is no automatic route. The arrangement offers possibilities, and steering has to find them.

We can lift a piece, turn it, leave it in another position, and try again. A gap can remain where the mouse needs support. A surface that carried it can become a wall. HOME brings only the mouse back; RESTORE returns the whole model. The cheese also falls if its support is removed. The distinction between obstacle and passage is now something the hand can revise.

Below, our walk went around the wedges and up their slopes. On the platform, their repetition became sculpture. On the plinth, a related triangular form becomes obstacle, support, body and destination. The geometry does not contain these uses in advance. Placement, scale and another body's capacities make them possible together.

A broad ramp at the far edge returns us to the floor towards the enclosure beyond.

'''+s[end:]
p.write_text(s,encoding='utf-8')
p=MAP/'tutorial.md';s=p.read_text(encoding='utf-8')
s=s.replace('The sequence is obstruction, detour, support and ascent. The basin and rock side room follow the descent.','The sequence is obstruction, detour, support and ascent, then sculpture and a small rearrangeable model. The basin and rock side room follow the descent.')
section='''## The wedge becomes sculpture, then a small experiment

`wedge_column` at (6.5, 32) stands on the platform. It instantiates six copies of the existing `prism_block.tscn`, scales each uniformly to 0.65, and turns paired copies by ±90 degrees about Z. Their original bases meet; three pairs form a 1.95 m column. The mesh and collision come from the same scene as the standing blockers. The joints are static. This is a configured sculpture, not a simulated balancing result.

`wedge_mouse_model` at (13, 32) places a 2.8 × 1.0 m plinth on the platform. Its top is 0.82 m above the platform. Seven grabbable construction wedges share exactly the same six vertices and convex collision geometry: 0.22 m width, 0.24 m rise, 0.48 m run. These are right-triangular wedges, related to the stock `wp` profile. The symmetric `prism_block` used in the sculpture has a different triangular profile; rotating it alone would not change that profile.

Build just a pair first. Keep one wedge upright; turn the second by 180 degrees about Z after orienting both along X. Raise the second by 0.24 m. Their sloping faces now meet to form a rectangular platform. Put a third identical wedge alongside with its sloping face exposed: it becomes the approach.

Then give a small body a capsule collider, gravity, and steering from a returning joystick. The player directs the brown wedge mouse; there are no automatic targets. `CharacterBody3D.move_and_slide()` resolves contact with the current surfaces. JUMP launches a ballistic arc in the last steered direction, so a desktop user can release the stick and click the jump control. Returning the stick to centre stops walking.

**Experiment loop:**

1. Grip or pointer-drag the stick. Steer straight into a standing wedge, then around it. Find the incline and climb.
2. Stop near the platform edge, face the cheese, and press JUMP. Releasing the joystick stops walking; the jump retains the last direction.
3. Move only the approach wedge. HOME resets the mouse while preserving the arrangement. Try the same steering again.
4. Restore, then move the landing pair. Compare a low landing with an obstruction before ascent. The cheese is a physical body and falls when unsupported.
5. Turn the pieces and reconstruct a supported course. In VR, grab and rotate; on desktop, Q/E roll and R/F tilt while held. Construction pieces stay where released.
6. RESTORE returns the seven wedges, mouse and cheese. The layout is held for the current scene only; there is no disk save or claim of physics replay.

The front joystick supports hand gripping and pointer dragging. JUMP, HOME and RESTORE use hand pokes or ray clicks. Holding a construction piece centres steering and prevents jumping while it is held. The platform crossing and both access ramps remain outside the display footprints.

'''
s=s.replace('## Learning elements',section+'## Learning elements',1);p.write_text(s,encoding='utf-8')
p=MAP/'technical.md';s=p.read_text(encoding='utf-8')
section='''## Sculpture and plinth model on the landing

`wedge_column:0:0#offset:0.5,0,0#plinth:0#pin:1` at (6,32) places the sculpture centre at (6.5,32). Six instances of `prism_block.tscn` retain their source mesh, material and static concave collider. Each is uniformly scaled to 0.65. Pairs rotate ±90° about Z and meet at their bases; three paired modules produce a 1.30 m wide × 0.65 m deep × 1.95 m high column. Point-contact stacking is authored and fixed, not a rigid-body equilibrium test.

`wedge_mouse_model:0:0#plinth:0#pin:1` at (13,32) builds a 2.8 × 1.0 × 0.82 m plinth. The displayed model extends upward from the actual structure-2 surface. The front edge at z=31.5 leaves the existing z=31 crossing clear.

Seven `Piece` bodies reuse one right-triangular vertex set (width 0.22, rise 0.24, run 0.48 m). Two stand as blockers, one exposes a climbing face, two form the platform and two form the far landing. The 0.22 m gap lies between the platform's right end x=0.56 and the far landing's left end x=0.78 in model coordinates. The mouse and cheese share the triangular vocabulary at other dimensions. Grabbable pieces freeze on release, as the earlier triangle table does.

The player steers a CharacterBody3D using `joystick_zero.tscn`. There are no authored route targets in production. Its floor_max_angle is 50°, floor snapping is 0.025 m, gravity is 3 m/s², walking speed is 0.32 m/s, and jump launch speed is 1.10 m/s upward and 0.72 m/s horizontally. JUMP requires grounded contact and retains the last steering direction during flight. It can be attempted anywhere on the course. The miniature uses slowed physics for legibility, not dynamically scaled real-mouse mechanics. Construction convex margins are 1 mm: the default 4 cm rounding distorted the low ramp contact at this scale. The cheese is a gravity-enabled pickable body, so removing its support also changes its position.

HOME restores only the mouse and centres the stick. RESTORE restores all seven construction transforms, the mouse and the cheese. Neither writes a saved layout to disk. Holding a construction piece centres the stick and prevents jumping. The joystick returns to neutral on release and keeps avatar movement controls separate. Buttons use the existing poke/ray paths.

'''
s=s.replace('## Signs and retaining profiles',section+'## Signs and retaining profiles',1);p.write_text(s,encoding='utf-8')
p=MAP/'summary.md';s=p.read_text(encoding='utf-8')
s=s.replace('6. **A floored basin','6. **Sculpture on the platform (6.5,32).** Six copies of the same standing prism turn into three diamond modules. Walk around the fixed column and compare silhouette, depth and obstruction.\n7. **Wedge mouse on a plinth (13,32).** Seven identical small construction wedges can be moved and turned. They make blockers, an incline, a platform and a landing. The player steers a brown wedge mouse with a returning joystick and jumps towards the cheese. Wedges can be rearranged between attempts.\n8. **A floored basin').replace('7. **Rock side room','9. **Rock side room')
s=s.replace('The wedge-grid-route trial checks the latest crossing and preserves native captures.','The wedge-sculpture-model trial checks the crossing with both additions and the miniature\'s successful and interrupted courses.')
p.write_text(s,encoding='utf-8')
p=MAP/'intent.md';p.write_text('''# Blocking, climbing, sculpture

The wedge acquires capacities through arrangement and through the body that meets it. Five standing prisms first refuse the direct route. The same walk then climbs the inclined faces of the side wp ramps. On the shared platform, six copies of the standing prism form a column, borrowing repetition and the relation between sculpture and support from the Brâncuși-like proposal.

The room and final follow this order: alignment; corner and open surface; central blockers; climbing; sculpture; small wedge-mouse model; descent; basin; rock room. The sculpture and model sit at the back of the platform, leaving its crossing clear. The three-metre side passages remain.

The model makes configuration available to the hand. One small right-triangular unit becomes obstacle, complementary platform half, or inclined approach. A brown wedge mouse and yellow cheese wedge add body and destination. The player steers the mouse and initiates its jumps; real contact and gravity make changes consequential. A route can fail. Turning a wedge does not magically produce a working route.

The guiding question is what makes a solid a barrier, route or sculpture, and when it is more than one. Native tests can establish contact, access, reset and differences after a move. Whether the comparison becomes perceptible or interesting belongs to a visitor trial. Fixed sculptural joints and the miniature's movement rules are part of the apparatus and must remain explicit.
''',encoding='utf-8')
p=MAP/'artifacts.md';s=p.read_text(encoding='utf-8')
s+='''\n## Platform additions — 17 October 2026\n\n| Artifact | Anchor (x,z) | Placement |\n| --- | --- | --- |\n| wedge_column | (6,32), offset (+0.5,0,0) | Six original prism scenes; 1.95 m column on structure 2 |\n| wedge_mouse_model | (13,32) | Own 0.82 m plinth; seven movable construction wedges, mouse, cheese; joystick / JUMP / HOME / RESTORE |\n\nThese follow wedge_palace and precede the basin in the room and final.\n''';p.write_text(s,encoding='utf-8')
print('Final, tutorial, technical, summary, intent and inventory follow blocking / climbing / sculpture / model.')
